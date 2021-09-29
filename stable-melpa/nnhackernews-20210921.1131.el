;;; nnhackernews.el --- Gnus backend for Hacker News  -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2019 The Authors of nnhackernews.el

;; Authors: dickmao <github id: dickmao>
;; Version: 0.1.0
;; Package-Version: 20210921.1131
;; Package-Commit: 4e584d4da81c400de145dbb7a58e63819cbaf340
;; Keywords: news
;; URL: https://github.com/dickmao/nnhackernews
;; Package-Requires: ((emacs "25.2") (request "0.3.3") (dash "2.18.1") (anaphora "1.0.4"))

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with nnhackernews.el.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A Gnus backend for Hacker News.

;;; Code:

(eval-when-compile (require 'cl-lib)
                   (cl-assert (fboundp 'libxml-parse-html-region) nil
                              "nnhackernews requires emacs built with libxml support"))

(require 'nnoo)
(require 'gnus)
(require 'gnus-start)
(require 'gnus-art)
(require 'gnus-sum)
(require 'gnus-msg)
(require 'gnus-cite)
(require 'gnus-srvr)
(require 'gnus-cache)
(require 'gnus-bcklg)
(require 'gnus-score)
(require 'mm-url)
(require 'cl-lib)
(require 'json)
(require 'subr-x)
(require 'request)
(require 'dash)
(require 'anaphora)
(require 'url-http)

(nnoo-declare nnhackernews)

(defconst nnhackernews-hacker-news-url "https://news.ycombinator.com")
(defconst nnhackernews--group-ask "ask")
(defconst nnhackernews--group-show "show")
(defconst nnhackernews--group-job "job")
(defconst nnhackernews--group-stories "news")

(defgroup nnhackernews nil "A Gnus backend for Hacker News."
  :group 'gnus)

(defcustom nnhackernews-render-story t
  "If non-nil, follow link upon `gnus-summary-select-article'.

Otherwise, just display link."
  :type 'boolean
  :group 'nnhackernews)

(defcustom nnhackernews-localhost "127.0.0.1"
  "Some users keep their browser in a separate domain.

Do not set this to \"localhost\" as a numeric IP is required for the oauth
handshake."
  :type 'string
  :group 'nnhackernews)

(defcustom nnhackernews-purge-threshold 30000
  "When number of headers exceeds this, call `nnhackernews-purge'."
  :type 'integer
  :group 'nnhackernews)

(defcustom nnhackernews-max-items-per-scan 100
  "Maximum items to fetch from firebase each refresh cycle."
  :type 'integer
  :group 'nnhackernews)

(defcustom nnhackernews-refractory-ms 2200
  "In June 2021, hackernews started throttling responses."
  :type 'integer
  :group 'nnhackernews)

(defcustom nnhackernews-max-render-bytes 300e3
  "`quoted-printable-encode-region' bogs when javascript spyware overdoes it."
  :type 'integer
  :group 'nnhackernews)

(defvoo nnhackernews-status-string "")

(defvar nnhackernews-avoid-rescoring nil
  "This semaphore avoids unnecessary scoring.
The unnecessary run results from `nndraft-update-unread-articles'
calling `gnus-group-get-new-news-this-group'.")

(defvar nnhackernews--mutex-display-article
  (when (fboundp 'make-mutex)
    (make-mutex "nnhackernews--mutex-display-article"))
  "Scoring in `gnus-after-getting-new-news-hook' emits 'Selecting deleted buffer'.")

(defvar nnhackernews--last-item nil "Keep track of where we are.")

(defvar nnhackernews--debug-request-items nil "Keep track of ids to re-request for testing.")

(defvar nnhackernews--last-scan-time (- (truncate (float-time)) 100)
  "Don't scan more than once every few seconds.")

(defmacro nnhackernews--callback (result &optional callback)
  "Set RESULT to return value of CALLBACK."
  `(cl-function (lambda (&rest args &key data &allow-other-keys)
                  (setq ,result (if ,callback
                                    (apply ,callback args)
                                  data)))))

(defun nnhackernews-alist-get (key alist &optional default remove testfn)
  "Replicated library function for emacs-25.

Same argument meanings for KEY ALIST DEFAULT REMOVE and TESTFN."
  (ignore remove)
  (let ((x (if (not testfn)
               (assq key alist)
             (assoc key alist))))
    (if x (cdr x) default)))

(gv-define-expander nnhackernews-alist-get
  (lambda (do key alist &optional default remove testfn)
    (macroexp-let2 macroexp-copyable-p k key
      (gv-letplace (getter setter) alist
        (macroexp-let2 nil p `(if (and ,testfn (not (eq ,testfn 'eq)))
                                  (assoc ,k ,getter)
                                (assq ,k ,getter))
          (funcall do (if (null default) `(cdr ,p)
                        `(if ,p (cdr ,p) ,default))
                   (lambda (v)
                     (macroexp-let2 nil v v
                       (let ((set-exp
                              `(if ,p (setcdr ,p ,v)
                                 ,(funcall setter
                                           `(cons (setq ,p (cons ,k ,v))
                                                  ,getter)))))
                         `(progn
                            ,(cond
                             ((null remove) set-exp)
                             ((or (eql v default)
                                  (and (eq (car-safe v) 'quote)
                                       (eq (car-safe default) 'quote)
                                       (eql (cadr v) (cadr default))))
                              `(if ,p ,(funcall setter `(delq ,p ,getter))))
                             (t
                              `(cond
                                ((not (eql ,default ,v)) ,set-exp)
                                (,p ,(funcall setter
                                              `(delq ,p ,getter))))))
                            ,v))))))))))

(defsubst nnhackernews--gethash (string hashtable &optional dflt)
  "Get corresponding value of STRING from HASHTABLE, or DFLT if undefined.

Starting in emacs-src commit c1b63af, Gnus moved from obarrays to normal hashtables."
  (if (fboundp 'gnus-gethash)
      (let ((sym (intern-soft string hashtable)))
        (if (or (null sym) (not (boundp sym))) dflt (symbol-value sym)))
    (gethash string hashtable dflt)))

(defsubst nnhackernews--replace-hash (string func hashtable)
  "Set value of STRING to FUNC applied to existing STRING value in HASHTABLE.

Starting in emacs-src commit c1b63af, Gnus moved from obarrays to normal hashtables."
  (let* ((capture (nnhackernews--gethash string hashtable))
         (replace-with (funcall func capture)))
    (if (fboundp 'gnus-sethash)
       (set (intern string hashtable) replace-with)
      (puthash string replace-with hashtable))))

(defmacro nnhackernews--remhash (string hashtable)
  "Remove STRING from HASHTABLE.

Starting in emacs-src commit c1b63af, Gnus moved from obarrays to normal hashtables."
  `(,(if (fboundp 'gnus-sethash)
         'unintern
       'remhash)
    ,(if (fboundp 'gnus-sethash)
         (cons 'intern (list string hashtable))
       string)
     ,hashtable))

(defmacro nnhackernews--sethash (string value hashtable)
  "Set corresponding value of STRING to VALUE in HASHTABLE.

Starting in emacs-src commit c1b63af, Gnus moved from obarrays to normal hashtables."
  `(,(if (fboundp 'gnus-sethash)
         'gnus-sethash
       'puthash)
    ,string ,value ,hashtable))

(defmacro nnhackernews--maphash (func table)
  "Map FUNC taking key and value over TABLE, return nil.

Starting in emacs-src commit c1b63af, Gnus moved from obarrays to normal hashtables."
  (declare (indent nil))
  `(,(if (fboundp 'gnus-gethash-safe)
         'mapatoms
       'maphash)
    ,(if (fboundp 'gnus-gethash-safe)
         `(lambda (k) (funcall
                       (apply-partially
                        ,func
                        (symbol-name k) (funcall (function gnus-gethash-safe) k ,table))))
       func)
    ,table))

(defvar nnhackernews-summary-voting-map
  (let ((map (make-sparse-keymap)))
    map)
  "Voting map.")

(defvar nnhackernews-summary-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "r" #'gnus-summary-followup)
    (define-prefix-command 'nnhackernews-summary-voting-map)
    (define-key map "R" 'nnhackernews-summary-voting-map)
    (define-key nnhackernews-summary-voting-map "0" #'nnhackernews-novote)
    (define-key nnhackernews-summary-voting-map "-" #'nnhackernews-downvote)
    (define-key nnhackernews-summary-voting-map "=" #'nnhackernews-upvote)
    (define-key nnhackernews-summary-voting-map "+" #'nnhackernews-upvote)
    map))

(defvar nnhackernews-article-mode-map
  (copy-keymap nnhackernews-summary-mode-map)) ;; how does Gnus do this?

(define-minor-mode nnhackernews-article-mode
  "Disallow `gnus-article-reply-with-original'.

\\{gnus-article-mode-map}"
  :lighter " HN"
  :keymap nnhackernews-article-mode-map)

(define-minor-mode nnhackernews-summary-mode
  "Disallow \"reply\" commands in `gnus-summary-mode-map'.

\\{nnhackernews-summary-mode-map}"
  :lighter " HN"
  :keymap nnhackernews-summary-mode-map)

(defsubst nnhackernews-novote ()
  "Retract vote."
  (interactive)
  (nnhackernews-vote-current-article 0))

(defsubst nnhackernews-downvote ()
  "Downvote the article in current buffer."
  (interactive)
  (nnhackernews-vote-current-article -1))

(defsubst nnhackernews-upvote ()
  "Upvote the article in current buffer."
  (interactive)
  (nnhackernews-vote-current-article 1))

(defvar nnhackernews--seq-map-indexed
  (if (fboundp 'seq-map-indexed)
      #'seq-map-indexed
    (lambda (function sequence)
      (let ((index 0))
        (seq-map (lambda (elt)
                   (prog1
                       (funcall function elt index)
                     (setq index (1+ index))))
                 sequence)))))

(defmacro nnhackernews--normalize-server ()
  "Disallow \"server\" from being empty string, which is unsettling.
Normalize it to \"nnhackernews-default\"."
  `(let ((canonical "nnhackernews-default"))
    (when (equal server "")
      (setq server nil))
    (unless server
      (setq server canonical))
    (unless (string= server canonical)
      (error "`nnhackernews--normalize-server': multiple servers unsupported!"))))

(defvar nnhackernews-score-files nil "For `nnhackernews--ensure-score-file'.")

(defvar nnhackernews-location-hashtb (gnus-make-hashtable)
  "Id -> ( group . index ).")

(defvar nnhackernews-root-hashtb (gnus-make-hashtable)
  "Id -> possibly ancient header.")

(defvar nnhackernews-headers-alist nil
  "Group -> headers.  This is an alist.  Hashtable mysteriously slow.")

(defvar nnhackernews-refs-hashtb (gnus-make-hashtable)
  "Who replied to whom (global over all entries).")

(defvar nnhackernews-authors-hashtb (gnus-make-hashtable)
  "For fast lookup of parent-author (global over all entries).")

(defun nnhackernews-get-headers (group)
  "List headers from GROUP."
  (cl-second (assoc group nnhackernews-headers-alist)))

(defun nnhackernews-find-header (id &optional noquery)
  "Retrieve property list of ID.

If NOQUERY, return nil and avoid querying if not extant."
  (if-let ((location (nnhackernews--gethash id nnhackernews-location-hashtb)))
      (cl-destructuring-bind (group . index) location
        (nnhackernews--get-header (1+ index) group))
    (unless noquery
      (nnhackernews--request-item id))))

(defun nnhackernews-refs-for (id)
  "Return ancestors sorted oldest to youngest as list for ID."
  (cl-loop with get-root-plst = #'ignore
           for prev-id = id then cur-id
           for cur-id =
           (let ((cached (nnhackernews--gethash prev-id
                                                nnhackernews-refs-hashtb
                                                'NULL)))
             (if (eq cached 'NULL)
                 (let ((plst (nnhackernews--request-item prev-id)))
                   (nnhackernews-add-entry nnhackernews-refs-hashtb
                                           plst :parent)
                   (setq get-root-plst (lambda () plst))
                   (plist-get plst :parent))
               (setq get-root-plst (apply-partially #'nnhackernews-find-header prev-id t))
               cached))
           until (null cur-id)
           collect cur-id into rresult
           finally return
	   (let ((result (nreverse rresult))
                 (root-plst (funcall get-root-plst)))
             (when (and result
                        (string= (plist-get root-plst :id) (car result)))
               (nnhackernews--sethash (car result) root-plst
                                      nnhackernews-root-hashtb))
             result)))

(defun nnhackernews--retrieve-root (header)
  "Retrieve and cache property list HEADER root."
  (if-let ((root-id (car (nnhackernews-refs-for (plist-get header :id)))))
      (nnhackernews--gethash root-id nnhackernews-root-hashtb)
    header))

(defun nnhackernews--group-for (header)
  "Classify HEADER as one of ask, show, or news based on title."
  (let* ((root-plst (nnhackernews--retrieve-root header))
         (title (or (plist-get header :link_title) ""))
         (type (or (plist-get root-plst :type) "")))
    ;; string-match-p like all elisp searching is case-insensitive
    (cond ((string= type "job") nnhackernews--group-job)
          ((string-match-p "^\\(Launch\\|Show\\) HN" title) nnhackernews--group-show)
          ((string-match-p "^\\(Ask\\|Tell\\) HN" title) nnhackernews--group-ask)
          (t nnhackernews--group-stories))))

(defsubst nnhackernews--get-user-cookie ()
  "Extract Hacker News login from cookies."
  (let* ((site (url-host (url-generic-parse-url nnhackernews-hacker-news-url))))
    (cdr (assoc-string
          "user"
          (cl-loop with result
                   for securep in '(t nil)
                   do (setq result
                            (request-cookie-alist site "/" securep))
                   until result
                   finally return result)))))

(defun nnhackernews--domify (html)
  "Parse HTML into dom."
  (with-temp-buffer
    (insert html)
    (if (fboundp 'libxml-parse-html-region)
        (libxml-parse-html-region (point-min) (point-max))
      (error "`nnhackernews--domify': need libxml-parse-html-region"))))

(cl-defun nnhackernews--request-login-success (&key data &allow-other-keys)
  "Validate login depending on what DATA say.

After some time, logging in via browser recaptcha might be necessary.
Remember `string-match-p' is always case-insensitive as is all elisp pattern matching."
  (when (and (stringp data)
             (string-match-p (regexp-quote "validation required") data))
    (display-warning
     'nnhackernews
     (concat "Recaptcha required.  Please login via browser and try again."))
    (error "Recaptcha required"))
  data)

(defun nnhackernews--request-login (url &optional hidden)
  "Store a cookie from URL with HIDDEN plist."
  (let* (result
         (auth-source-do-cache nil)
         (auth-source-save-behavior 'ask)
         (auth-source-creation-prompts '((user . "news.ycombinator.com user: ")
                                         (secret . "Password for %u: ")))
         (found (car (auth-source-search :max 1 :host "news.ycombinator.com" :require
                                         '(:user :secret) :create t))))
    (nnhackernews--request
     "nnhackernews--request-login"
     url
     :backend 'curl
     :data (append
            (cl-loop for (k v) on hidden by (function cddr)
                     collect (cons (cl-subseq (symbol-name k) 1) v))
            `(("acct" . ,(plist-get found :user))
              ("pw" . ,(let ((secret (plist-get found :secret)))
                         (if (functionp secret)
                             (funcall secret)
                           secret)))))
     :success (nnhackernews--callback result #'nnhackernews--request-login-success))
    result))

(defmacro nnhackernews--extract-hidden (dom hidden)
  "Extract hidden tag-value pairs from DOM into plist HIDDEN."
  `(-tree-map-nodes
    (lambda (x)
      (and (listp x)
           (eq (car x) 'input)
           (string= "hidden" (alist-get 'type (cl-second x)))
           (not (string= "creating" (alist-get 'name (cl-second x))))))
    (lambda (x)
      (let ((keyname (intern (concat ":" (alist-get 'name (cl-second x))))))
        (unless (plist-get ,hidden keyname)
          (!cons (alist-get 'value (cl-second x)) ,hidden)
          (!cons keyname ,hidden))))
    ,dom))

(cl-defun nnhackernews--request-hidden-success (&key data response &allow-other-keys)
  "Based on DATA and RESPONSE, we may need to login first.  Return :fnid and :fnop."
  (let* ((dom (nnhackernews--domify data))
         (form (car (alist-get 'form (alist-get 'body dom))))
         (url (request-response-url response))
         (path (car (url-path-and-query (url-generic-parse-url url))))
         (login-p (aif (alist-get 'action form) (cl-search it path)))
         hidden)
    (nnhackernews--extract-hidden dom hidden)
    (when login-p
      (setq dom (nnhackernews--domify (nnhackernews--request-login url hidden)))
      (nnhackernews--extract-hidden dom hidden))
    hidden))

(defun nnhackernews--request-hidden (url)
  "Get the hidden fields (e.g., FNID, FNOP, HMAC) from URL."
  (let (result)
    (nnhackernews--request
     "nnhackernews--request-hidden"
     url
     :backend 'curl
     :success (nnhackernews--callback result #'nnhackernews--request-hidden-success))
    result))

(defsubst nnhackernews--who-am-i ()
  "Get my Hacker News username."
  (let ((user-cookie (nnhackernews--get-user-cookie)))
    (unless user-cookie
      (nnhackernews--request-login (format "%s/login" nnhackernews-hacker-news-url))
      (setq user-cookie (nnhackernews--get-user-cookie)))
    (if (stringp user-cookie)
        (car (split-string user-cookie "&"))
      (gnus-message 3 "nnhackernews--who-am-i: failed to get user-cookie")
      "error")))

(defsubst nnhackernews--append-header (plst &optional group)
  "Update data structures for PLST \"header\".

If GROUP classification omitted, figure it out."
  (let ((id (plist-get plst :id))
	(group (or group (nnhackernews--group-for plst))))
    (nnhackernews--sethash id
                           (cons group (length (nnhackernews-get-headers group)))
                           nnhackernews-location-hashtb)
    (setf (nnhackernews-alist-get group nnhackernews-headers-alist nil nil #'equal)
          (list (nconc (nnhackernews-get-headers group) (list plst))))
    plst))

(nnoo-define-basics nnhackernews)

(defun nnhackernews-vote-current-article (vote)
  "VOTE is +1, -1, 0."
  (unless gnus-newsgroup-name (error "No current newgroup"))
  (if-let ((article-number (or (with-current-buffer gnus-article-buffer
                                 (cdr gnus-article-current))
                               (with-current-buffer gnus-summary-buffer
                                 (gnus-summary-article-number)))))
      (let* ((header (nnhackernews--get-header
		      article-number
                      (gnus-group-real-name gnus-newsgroup-name)))
             (orig-score (format "%s" (plist-get header :score)))
             (new-score (if (zerop vote) orig-score
                          (concat orig-score " "
                                  (if (> vote 0) "+" "")
                                  (format "%s" vote)))))
        (save-excursion
          (save-window-excursion
            (with-current-buffer gnus-summary-buffer
              (if (eq (gnus-summary-article-number) (cdr gnus-article-current))
                  (if (nnhackernews--request-vote (plist-get header :id) vote)
                      (with-current-buffer gnus-article-buffer
                        (let ((inhibit-read-only t))
                          (nnheader-replace-header "Score" new-score)))
                    (gnus-message 5 "nnhackernews-vote-current-article: failed for %s"
                                  (plist-get header :id)))
                (message "Open the article before voting."))))))
    (error "No current article")))

(defsubst nnhackernews--gate (&optional group)
  "Apply our minor modes only when the following conditions hold for GROUP."
  (unless group
    (setq group gnus-newsgroup-name))
  (and (stringp group)
       (listp (gnus-group-method group))
       (eq 'nnhackernews (car (gnus-group-method group)))))

(defsubst nnhackernews--message-gate ()
  "In `message-mode', `gnus-newsgroup-name' could be anything."
  (nnhackernews--gate (car-safe gnus-message-group-art)))

(deffoo nnhackernews-request-close ()
  (nnhackernews-close-server)
  t)

(deffoo nnhackernews-request-type (_group &optional _article)
  'news)

(deffoo nnhackernews-server-opened (&optional server)
  (nnhackernews--normalize-server)
  nnhackernews--last-item)

(deffoo nnhackernews-status-message (&optional server)
  (nnhackernews--normalize-server)
  "")

(deffoo nnhackernews-open-server (_server &optional _defs)
  t)

(deffoo nnhackernews-close-group (_group &optional server)
  (nnhackernews--normalize-server)
  t)

(defmacro nnhackernews--with-group (group &rest body)
  "Disambiguate GROUP if it's empty and execute BODY."
  (declare (debug (form &rest form))
           (indent defun))
  `(let* ((group (or ,group (gnus-group-real-name gnus-newsgroup-name)))
          (gnus-newsgroup-name (gnus-group-full-name group "nnhackernews:")))
     ,@body))

(defun nnhackernews--get-header (article-number &optional group)
  "Get header indexed ARTICLE-NUMBER for GROUP."
  (nnhackernews--with-group group
    (elt (nnhackernews-get-headers group) (1- article-number))))

(defun nnhackernews--get-body (header &optional server)
  "Get full text of submission or comment HEADER at SERVER."
  (nnhackernews--normalize-server)
  (if-let ((url (plist-get header :url)))
      (format "<div><p><a href=\"%s\">%s</a></div>" url url)
    (or (plist-get header :text)
        (plist-get (nnhackernews--request-item (plist-get header :id)) :text)
        "")))

(defun nnhackernews--massage (body)
  "Precede each quoted line of BODY broken by `shr-fill-line' with '>'."
  (with-temp-buffer
    (insert body)
    (mm-url-decode-entities)
    (cl-loop initially (goto-char (point-min))
             until (and (null (re-search-forward "\\(^>\\( .*?\\)\\)<p>" nil t))
                        (null (re-search-forward "\\(<p>\\s-*>\\( .*?\\)\\)<p>" nil t)))
             do (let* ((start (match-beginning 1))
                       (end (match-end 1))
                       (matched (match-string 2)))
                  (perform-replace
                   ".*"
                   (concat "<p>\n"
                           (with-temp-buffer
                             (insert matched)
                             (fill-region (point-min) (point-max))
                             (insert
                              (prog1
                                  (cl-subseq (replace-regexp-in-string
                                              "\n" "<br>\n> " (concat "\n" (buffer-string)))
                                             5)
                                (erase-buffer)))
                             (buffer-string))
                           "\n")
                   nil t nil nil nil start end)))
    (buffer-string)))

(defsubst nnhackernews--citation-wrap (author body)
  "Cite AUTHOR using `gnus-message-cite-prefix-regexp' before displaying BODY.

Originally written by Paul Issartel."
  (with-temp-buffer
    (insert body)
    (mm-url-remove-markup)
    (mm-url-decode-entities)
    (fill-region (point-min) (point-max))
    (let* ((trimmed-1 (replace-regexp-in-string "\\(\\s-\\|\n\\)+$" "" (buffer-string)))
           (trimmed (replace-regexp-in-string "^\\(\\s-\\|\n\\)+" "" trimmed-1)))
      (concat author " wrote:<p>\n"
              "<pre>\n"
              (cl-subseq (replace-regexp-in-string "\n" "\n> " (concat "\n" trimmed)) 1)
              "\n</pre><p>"))))

(defun nnhackernews-add-entry (hashtb e field)
  "Add to HASHTB the pair consisting of entry E's name to its FIELD."
  (nnhackernews--sethash (plist-get e :id) (plist-get e field) hashtb))

(defun nnhackernews--summary-exit (group)
  "Call `gnus-summary-exit' for GROUP without the rescoring mess."
  (remove-function (symbol-function 'gnus-summary-exit)
                   (symbol-function 'nnhackernews--score-pending))
  (unwind-protect
      (let ((summary-buffer-name (gnus-summary-buffer-name group)))
        (with-current-buffer summary-buffer-name
          (gnus-summary-exit t t)
          (gnus-kill-buffer gnus-article-buffer)
          (gnus-kill-buffer gnus-original-article-buffer))
        (gnus-kill-buffer (get-buffer summary-buffer-name)))
    (add-function :after (symbol-function 'gnus-summary-exit)
                  (symbol-function 'nnhackernews--score-pending))))

(defsubst nnhackernews--ensure-score-files (group)
  "File I/O remains a perennial problem for score files for GROUP."
  (if-let ((files (alist-get (intern group) nnhackernews-score-files)))
      (condition-case nil
        (progn
          (dolist (file files t)
            (gnus-score-load-score-alist file)))
        (error nil))
    t))

(defmacro nnhackernews--with-mutex (mtx &rest body)
  "If capable of threading, lock with MTX and execute BODY."
  (declare (indent 1))
  (if (fboundp 'with-mutex)
      `(with-mutex ,mtx ,@body)
    `(progn ,@body)))

(defun nnhackernews--daring-scoring (group)
  "Dare to score GROUP without the benefit of `gnus-summary-read-group'."
  (with-temp-buffer
    ;; Withhold judgment of setqs, mimicking `gnus-summary-setup-buffer'
    (setq gnus-newsgroup-name group) ;; now defvar-local, right?
    (set-default 'gnus-newsgroup-name gnus-newsgroup-name)
    (gnus-summary-mode)
    (gnus-update-format-specifications 'summary 'summary-mode 'summary-dummy)
    (gnus-update-summary-mark-positions)
    (gnus-summary-set-local-parameters gnus-newsgroup-name)
    (let ((gnus-single-article-buffer t))
      ;; employ a hack that messes with *Article*, not an article I'm reading
      (gnus-select-newsgroup group nil nil))
    ;; Save the active value in effect when the group was entered.
    (setq gnus-newsgroup-active
	  (copy-tree (gnus-active gnus-newsgroup-name)))
    (setq gnus-newsgroup-highest (cdr gnus-newsgroup-active))
    (gnus-run-hooks 'gnus-select-group-hook)
    (gnus-possibly-score-headers)
    (gnus-summary-prepare) ;; this actually updates unreads... can't blame a 20yo
    (gnus-run-hooks 'gnus-apply-kill-hook)
    (setq gnus-newsgroup-prepared t)
    (gnus-run-hooks 'gnus-summary-prepared-hook)
    (gnus-group-update-group group nil t)
    (gnus-score-adaptive)
    (gnus-score-save)
    (gnus-run-hooks 'gnus-exit-group-hook)
    (gnus-summary-update-info)
    (gnus-run-hooks 'gnus-summary-prepare-exit-hook)
    (gnus-close-group group)
    (gnus-run-hooks 'gnus-summary-exit-hook)
    (when (equal gnus-article-buffer (default-value 'gnus-article-buffer))
      ;; can't be killing an article I was reading!
      (gnus-kill-buffer gnus-article-buffer)
      (gnus-kill-buffer gnus-original-article-buffer))))

(defun nnhackernews--rescore (group force)
  "Unforced rescore of GROUP when merely `gnus-summary-exit'.
FORCE in wake of `gnus-after-getting-new-news-hook'."
  (when (nnhackernews--gate group)
    (cl-loop repeat 5
             for ensured = (nnhackernews--ensure-score-files group)
             until ensured
             do (sleep-for 0 300)
             finally (unless ensured
                       (gnus-message 2 "nnhackernews--rescore: Bad score files %s!"
                                     (alist-get (intern group)
                                                nnhackernews-score-files))))
    (let* ((num-headers (length (nnhackernews-get-headers
                                 (gnus-group-real-name group))))
           (marks (gnus-info-marks (gnus-get-info group)))
           (seen (or (cdr-safe (--max-by (> (or (cdr-safe it) 0) (or (cdr-safe other) 0))
                                         (alist-get 'seen marks)))
                     0)))
      (unless (zerop seen)
        (when (or force (> num-headers seen))
          (save-window-excursion
            (let (gnus-auto-select-subject
                  gnus-summary-next-group-on-exit
                  (unread (length (gnus-list-of-unread-articles group)))
                  (gnus-large-newsgroup 10000))
              (if (zerop unread)
                  (gnus-message 7 "nnhackernews--rescore: skipping %s no unread"
                                group)
		;; Q: Why `gnus-summary-read-group'?
		;; A: `gnus-score-headers' message-clone-locals `gnus-summary-buffer'
                ;; Problem: Fights with main thread UI since it calls
                ;; `gnus-configure-windows',
                (nnhackernews--with-mutex nnhackernews--mutex-display-article
                  (if (> (gnus-continuum-version) 5.13)
                      (nnhackernews--daring-scoring group)
                    (gnus-summary-read-group group nil t)
                    (nnhackernews--summary-exit group)))))))))))

(defalias 'nnhackernews--score-pending
  (lambda (&rest _args)
    (awhen (gnus-group-name-at-point)
      (nnhackernews--rescore it nil))))

(defun nnhackernews-extant-summary-buffer (group)
  "Return main thread's summary buffer for GROUP if extant."
  (let* ((args (when (and (boundp 'gnus-threaded-get-unread-articles)
                          gnus-threaded-get-unread-articles)
                 '(t)))
         (name (apply #'gnus-summary-buffer-name group args)))
    (gnus-buffer-live-p name)))

(defun nnhackernews--score-unread (group)
  "Filter unread messages for GROUP now.

Otherwise *Group* buffer annoyingly overrepresents unread."
  (when (or (gnus-native-method-p '(nnhackernews ""))
            (gnus-secondary-method-p '(nnhackernews "")))
    (nnhackernews--with-group group
      (when (and (not (nnhackernews-extant-summary-buffer gnus-newsgroup-name))
		 (not nnhackernews-avoid-rescoring))
        (nnhackernews--rescore gnus-newsgroup-name t)))))

(defun nnhackernews--mark-scored-as-read (group)
  "Reflect the scoring results now.

If root article (story) is scored in GROUP, that means we've already
read it.  This function seems redundant with `nnhackernews--score-unread'
but might be faster on startup?  See 15195cc."
  (nnhackernews--with-group group
    (let ((preface (format "nnhackernews--mark-scored-as-read: %s not rescoring " group))
          (extant (nnhackernews-extant-summary-buffer gnus-newsgroup-name))
          (unread (gnus-group-unread gnus-newsgroup-name)))
      (cond ((or (not (numberp unread)) (<= unread 0))
             (gnus-message 7 (concat preface "(unread %s)") unread))
            ((and extant (buffer-local-value 'gnus-newsgroup-prepared extant))
             ;; reflect the extant logic in `gnus-summary-setup-buffer'
             (gnus-message 7 (concat preface "(extant %s)") (buffer-name extant)))
            (t
             (save-excursion
               (let (gnus-auto-select-subject
                     (gnus-large-newsgroup 10000))
                 (gnus-summary-read-group gnus-newsgroup-name nil t)
                 (with-current-buffer (gnus-summary-buffer-name gnus-newsgroup-name)
                   (dolist (datum gnus-newsgroup-data)
                     (-when-let* ((article (gnus-data-number datum))
                                  (plst (nnhackernews--get-header article))
                                  (scored-story-p (and (plist-get plst :title)
                                                       (> (gnus-summary-article-score article) 0))))
                       (gnus-message 7 "nnhackernews--mark-scored-as-read: %s (%s %s)"
                                     (plist-get plst :title) group article)
                       (gnus-summary-mark-as-read article))))
                 (nnhackernews--summary-exit gnus-newsgroup-name))))))))

(deffoo nnhackernews-request-group-scan (group &optional server info)
  "\\[gnus-group-get-new-news-this-group] calls this."
  (nnhackernews--normalize-server)
  (nnhackernews--with-group group
    (gnus-message 5 "nnhackernews-request-group-scan: scanning %s..." group)
    (gnus-activate-group gnus-newsgroup-name t)
    (gnus-get-unread-articles-in-group
     (or info (gnus-get-info gnus-newsgroup-name))
     (gnus-active (gnus-info-group info)))
    (gnus-message 5 "nnhackernews-request-group-scan: scanning %s...done" group)
    (nnhackernews--score-unread group))
  t)

(defun nnhackernews--checksum ()
  "Ensure header tallies agree.

The two hashtables being reconciled are `nnhackernews-location-hashtb' and
`nnhackernews-headers-alist'."
  (let ((counts (gnus-make-hashtable)))
    (nnhackernews--maphash
     (lambda (_id group-index)
       (nnhackernews--replace-hash (car group-index) (lambda (v) (1+ (or v 0)))
                                   counts))
     nnhackernews-location-hashtb)

    (mapc
     (lambda (pair)
       (cl-destructuring-bind (group headers) pair
	 (cl-assert (= (nnhackernews--gethash group counts 0)
		       (length headers))
		    nil
		    "nnhackernews--checksum: %s, %s != %s"
		    group (nnhackernews--gethash group counts 0)
		    (length headers))))
     nnhackernews-headers-alist)

    (let (result)
      (nnhackernews--maphash
       (lambda (group count)
         (push (cons group count) result))
       counts)
      result)))

;; gnus-group-select-group
;;   gnus-group-read-group
;;     gnus-summary-read-group
;;       gnus-summary-read-group-1
;;         gnus-summary-setup-buffer
;;           sets gnus-newsgroup-name
;;         gnus-select-newsgroup
;;           gnus-request-group
;;             nnhackernews-request-group
(deffoo nnhackernews-request-group (group &optional server _fast info)
  (nnhackernews--normalize-server)
    (nnhackernews--with-group group
      (let* ((info (or info (gnus-get-info gnus-newsgroup-name)))
             (headers (nnhackernews-get-headers group))
             (first-header (1+ (or (-find-index #'identity headers) 0)))
             (last-header (length headers))
             (num-headers (if (> first-header last-header) 0
                            (1+ (- last-header first-header))))
             (status (format "211 %d %d %d %s"
                             num-headers first-header last-header group)))
        (gnus-message 7 "nnhackernews-request-group: %s" status)
        (nnheader-insert "%s\n" status)
        (when info
          (gnus-info-set-marks
           info
           (append (assq-delete-all 'seen (gnus-info-marks info))
                   (list `(seen (1 . ,num-headers))))
           t)
          (gnus-info-set-method info (gnus-group-method gnus-newsgroup-name) t)
          (gnus-set-info gnus-newsgroup-name info)))
      t))

(defsubst nnhackernews--json-read ()
  "Copied from ein:json-read() by tkf."
  (goto-char (point-max))
  (backward-sexp)
  (let ((json-object-type 'plist)
        (json-array-type 'list))
    (json-read)))

(defun nnhackernews--request-max-item ()
  "Retrieve the max-item from which all read-unread accounting stems."
  (let (max-item)
    (nnhackernews--request
     "nnhackernews--request-max-item"
     "https://hacker-news.firebaseio.com/v0/maxitem.json"
     :parser 'nnhackernews--json-read
     :success (nnhackernews--callback max-item))
    max-item))

(defun nnhackernews--request-newstories ()
  "Return list of id's which we know to be stories (as opposed to comments)."
  (let (stories)
    (nnhackernews--request
     "nnhackernews--request-newstories"
     "https://hacker-news.firebaseio.com/v0/newstories.json"
     :success (nnhackernews--callback
               stories
               (cl-function
                (lambda (&key data &allow-other-keys)
                  ;; manual recommended listify appends nil
                  (append
                   (eval (car (read-from-string (subst-char-in-string ?, ?\  data))))
                   nil)))))
    stories))

(cl-defun nnhackernews--request (caller url
                                 &rest attributes
                                 &key parser (backend 'url-retrieve) (timeout 10)
                                 &allow-other-keys)
  "Prefix errors with CALLER executing synchronous request to URL.

Request shall contain ATTRIBUTES, one of which is PARSER of the response, if provided (shall default to verbatim dump of response, if not).  BACKEND can be curl (defaults to `url-retrieve')."
  (unless parser
    (setq attributes (append attributes (list :parser #'buffer-string))))
  (setq attributes
        (cl-loop for (k v) on attributes by (function cddr)
                 unless (eq k :backend)
                 collect k and collect v))
  (let ((request-backend backend))
    (apply #'request url
           :sync t
           :timeout timeout
           :error (apply-partially #'nnhackernews--request-error caller)
           attributes)))

(cl-defun nnhackernews--request-vote-success (item vote &key data &allow-other-keys)
  "If necessary, login first, then locate ITEM VOTE link in DATA (will depend on VOTE sign)."
  (let* ((dom (nnhackernews--domify data))
         (before (format "%s_%s" (if (> vote 0) "up" "un") item))
         (after (format "%s_%s" (if (<= vote 0) "up" "un") item))
         before-found result)
    (-tree-map-nodes
     (lambda (x)
       (and (listp x)
            (eq (car x) 'a)
            (let ((id (alist-get 'id (cl-second x))))
              (or (string= before id) (string= after id)))))
     (lambda (x)
       (let ((id (alist-get 'id (cl-second x)))
             (href (alist-get 'href (cl-second x))))
         (cond ((string= before id)
                (setq before-found (concat (file-name-as-directory nnhackernews-hacker-news-url) href)))
               ((string= after id) (setq result t)))))
     dom)
    (when before-found
      (nnhackernews--request
       "nnhackernews--request-vote-success"
       before-found
       :backend 'curl
       :success (nnhackernews--callback
                 result
                 (cl-function
                  (lambda (&key data response &allow-other-keys)
                    (let* ((dom (nnhackernews--domify data))
                           (form (alist-get 'form (alist-get 'body dom)))
                           (url (request-response-url response))
                           hidden)
                      (nnhackernews--extract-hidden dom hidden)
                      (when (string= "vote" (alist-get 'action (car form)))
                        (setq dom (nnhackernews--domify
                                   (nnhackernews--request-login url hidden))))
                      (let (result0)
                        (-tree-map-nodes
                         (lambda (x)
                           (and (listp x)
                                (eq (car x) 'a)
                                (string= after (alist-get 'id (cl-second x)))))
                         (lambda (_x) (setq result0 t))
                         dom)
                        result0)))))))
    result))

(defun nnhackernews--request-vote (item vote)
  "Tally for ITEM the VOTE."
  (let (result)
    (nnhackernews--request
     "nnhackernews--request-vote"
     (format "%s/item?id=%s" nnhackernews-hacker-news-url item)
     :backend 'curl
     :success (nnhackernews--callback
               result
               (apply-partially #'nnhackernews--request-vote-success item vote)))
    result))

(defsubst nnhackernews--enforce-curl ()
  "Curl must exist."
  (unless (executable-find "curl")
    (error "`nnhackernews--enforce-curl': the 'curl' program was not found")))

(defun nnhackernews--request-reply (url text hidden)
  "Reply URL with TEXT using HIDDEN credentials."
  (nnhackernews--enforce-curl)
  (let (result)
    (nnhackernews--request
     "nnhackernews--request-reply"
     url
     :backend 'curl
     :data (append (cl-loop for (k v) on hidden by (function cddr)
                            collect (cons (cl-subseq (symbol-name k) 1) v))
                   `(("text" . ,text)))
     :success (nnhackernews--callback result))
    result))

(defun nnhackernews--request-edit (_item _body)
  "Replace body of ITEM with BODY."
  ;; (let (result)
  ;;   (nnhackernews--request
  ;;    "nnhackernews--request-edit"
  ;;    (format "%s/delete-confirm?%s"
  ;;            nnhackernews-hacker-news-url
  ;;            (url-build-query-string
  ;;             (cons `(id ,item)
  ;;                   (when root `((goto ,(format "item?id=%s" root)))))))
  ;;    :backend 'curl
  ;;    :success (nnhackernews--callback result #'nnhackernews--request-delete-success))
  ;;   result)
  )

(defun nnhackernews--request-delete (item &optional root)
  "Cancel ITEM at root ROOT."
  (let (result)
    (nnhackernews--request
     "nnhackernews--request-delete"
     (format "%s/delete-confirm?%s"
             nnhackernews-hacker-news-url
             (url-build-query-string
              (cons `(id ,item)
                    (when root `((goto ,(format "item?id=%s" root)))))))
     :backend 'curl
     :success (nnhackernews--callback result #'nnhackernews--request-delete-success))
    result))

(cl-defun nnhackernews--request-error (caller
                                       &key response symbol-status error-thrown
                                       &allow-other-keys
                                       &aux (response-status
                                             (request-response-status-code response)))
  "Refer to CALLER when reporting a submit error.

Also report http code of RESPONSE, which is distinct from SYMBOL-STATUS, and ERROR-THROWN.  The http code is stored in RESPONSE-STATUS."
  (gnus-message 3 "%s %s: http status %s, %s" caller symbol-status response-status
                (error-message-string error-thrown)))

(cl-defun nnhackernews--request-submit-success
    (caller posturl postdata retry &key data response &allow-other-keys)
  "If necessary, login, then \"goto\" fields take us to target.

And if accused of being a bot, retry with CALLER, POSTURL, POSTDATA
\(and toggle RETRY).  Use DATA and RESPONSE to determine if we need to login again."
  (let* ((dom (nnhackernews--domify data))
         (form (car (alist-get 'form (alist-get 'body dom))))
         (url (request-response-url response))
         (path (car (url-path-and-query (url-generic-parse-url url))))
         (login-p (aif (alist-get 'action form) (cl-search it path)))
         (result data))
    (when login-p
      (let (hidden)
        (nnhackernews--extract-hidden dom hidden)
        (setq result (nnhackernews--request-login url hidden))))
    (-tree-map-nodes
     (lambda (x)
       (and (listp x)
            (eq (car x) 'td)
            (stringp (cl-third x))
            (string-match-p (regexp-quote "try again") (cl-third x))))
     (lambda (_x)
       (if retry
           (let (hidden)
             (nnhackernews--extract-hidden dom hidden)
             (setq result (nnhackernews--request-submit caller posturl postdata hidden nil)))
         (setq result nil)
         (setq nnhackernews-status-string "Retried and failed")))
     dom)
    result))

(defun nnhackernews--request-submit (caller posturl postdata hidden retry)
  "Submit from CALLER to POSTURL the POSTDATA with HIDDEN credentials.

Bool RETRY is non-nil on first attempt.
Factor out commonality between text and link submit."
  (nnhackernews--enforce-curl)
  (let (result)
    (nnhackernews--request
     caller
     posturl
     :backend 'curl
     :data (append (cl-loop for (k v) on hidden by (function cddr)
                            collect (cons (cl-subseq (symbol-name k) 1) v))
                   postdata)
     :success (nnhackernews--callback
               result
               (apply-partially #'nnhackernews--request-submit-success
                                caller posturl postdata retry)))
    result))

(defsubst nnhackernews--request-submit-link (url title link hidden)
  "Submit to URL the TITLE with LINK and HIDDEN credentials."
  (nnhackernews--request-submit "nnhackernews--request-submit-link"
                                url
                                `(("title" . ,title) ("url" . ,link) ("text" . ""))
                                hidden t))

(defsubst nnhackernews--request-submit-text (url title text hidden)
  "Submit to URL the TITLE with TEXT and HIDDEN credentials."
  (nnhackernews--request-submit "nnhackernews--request-submit-text"
                                url
                                `(("title" . ,title) ("url" . "") ("text" . ,text))
                                hidden t))

(defun nnhackernews--request-item (id)
  "Retrieve ID as a property list."
  (push id nnhackernews--debug-request-items)
  (let ((utf-decoder (lambda (x)
                       (decode-coding-string (with-temp-buffer
                                               (set-buffer-multibyte nil)
                                               (insert x)
                                               (buffer-string))
                                             'utf-8)))
        plst)
    (add-function :filter-return (symbol-function 'json-read-string) utf-decoder)
    (unwind-protect
	(nnhackernews--request
	 "nnhackernews--request-item"
	 (format "https://hacker-news.firebaseio.com/v0/item/%s.json" id)
	 :parser 'nnhackernews--json-read
	 :success (nnhackernews--callback plst))
      (remove-function (symbol-function 'json-read-string) utf-decoder))
    (when-let ((id (plist-get plst :id)))
      (when (numberp id)
        (setq plst (plist-put plst :id (number-to-string id))))
      (-when-let* ((parent (plist-get plst :parent))
                   (is-number (numberp parent)))
        (setq plst (plist-put plst :parent (number-to-string parent))))
      (unless (plist-get plst :score)
        (setq plst (plist-put plst :score 0)))
      plst)))

(defun nnhackernews--select-items (start-item max-item all-stories)
  "Return a list of items to retrieve between START-ITEM and MAX-ITEM.

Since we are constrained by `nnhackernews-max-items-per-scan', we prioritize
ALL-STORIES and may throw away comments, etc."
  (mapcar
   #'number-to-string
   (if (> (1+ (- max-item start-item)) nnhackernews-max-items-per-scan)
       (let* ((stories (seq-take-while (lambda (x) (>= x start-item))
                                       all-stories))
              (excess (- nnhackernews-max-items-per-scan (length stories))))
         (if (<= excess 0)
             (nreverse (cl-subseq stories 0 nnhackernews-max-items-per-scan))
           (cl-loop with excess-count = 0
                    with j = 0
                    for i from max-item downto start-item by 1
                    until (or (>= excess-count excess) (>= j (length stories)))
                    if (= i (elt stories j))
                    do (cl-incf j)
                    else
                    do (cl-incf excess-count)
                    end
                    collect i into result
                    finally return (nreverse (append result (nthcdr j stories)
                                                     (cl-loop for k from 0 below
                                                              (- excess excess-count) by 1
                                                              collect (- i k)))))))
     (cl-loop for i from start-item to max-item by 1
              collect i))))

(defun nnhackernews--incoming (&optional static-max-item static-newstories)
  "Drink from the firehose.

Optionally provide STATIC-MAX-ITEM and STATIC-NEWSTORIES to prevent querying out."
  (interactive)
  (setq nnhackernews--debug-request-items nil)
  (unless nnhackernews--last-item
    (mapc (lambda (group)
            (-when-let* ((full-name (gnus-group-full-name group "nnhackernews:"))
                         (info (gnus-get-info full-name)))
              (setf (gnus-info-read info) nil)
              (gnus-set-info full-name info)))
          `(,nnhackernews--group-ask
            ,nnhackernews--group-show
            ,nnhackernews--group-job
            ,nnhackernews--group-stories)))
  (let ((max-item (or static-max-item (nnhackernews--request-max-item))))
    (if (and nnhackernews--last-item (<= max-item nnhackernews--last-item))
        (gnus-message 7 "nnhackernews--incoming: max %s <= last %s"
                      max-item nnhackernews--last-item)
      (let* ((stories (or static-newstories (nnhackernews--request-newstories)))
             (earliest-story (nth (1- (min nnhackernews-max-items-per-scan
                                           (length stories)))
                                  stories))
             (start-item (if nnhackernews--last-item
                             (1+ nnhackernews--last-item)
                           (min earliest-story
                                (- max-item nnhackernews-max-items-per-scan))))
             (counts (gnus-make-hashtable))
             (items (nnhackernews--select-items start-item max-item stories)))
        (dolist (item items)
          (-when-let* ((plst (nnhackernews--request-item item))
                       (not-deleted (not (plist-get plst :deleted)))
                       (type (plist-get plst :type)))
            (nnhackernews-add-entry nnhackernews-refs-hashtb plst :parent)
            (nnhackernews-add-entry nnhackernews-authors-hashtb plst :by)
            (nnhackernews--replace-hash type (lambda (x) (1+ (or x 0))) counts)
            (setq plst (plist-put plst :link_title
                                  (or (plist-get
                                       (nnhackernews--retrieve-root plst)
                                       :title)
                                      "")))
            (cl-case (intern type)
              (job (nnhackernews--append-header plst nnhackernews--group-job))
              ((story comment) (nnhackernews--append-header plst))
              (otherwise (gnus-message 5 "nnhackernews-incoming: ignoring type %s" type)))))
        (setq nnhackernews--last-item max-item)
        (gnus-message
         5 (concat "nnhackernews--incoming: "
                   (format "%d requests, " (length nnhackernews--debug-request-items))
                   (let ((result ""))
                     (nnhackernews--maphash
                      (lambda (key value)
                        (setq result (concat result (format "%s +%s " key value))))
                      counts)
                     result)))))))

(deffoo nnhackernews-request-scan (&optional group server)
  (nnhackernews--normalize-server)
  (when group
    (if (> 2 (- (truncate (float-time)) nnhackernews--last-scan-time))
        (gnus-message 7 "nnhackernews-request-scan: last scanned at %s"
                      (current-time-string nnhackernews--last-scan-time))
      (nnhackernews--with-group group
        (cl-destructuring-bind (seconds num-gc seconds-gc)
            (benchmark-run (nnhackernews--incoming))
          (setq nnhackernews--last-scan-time (truncate (float-time)))
          (gnus-message 5 (concat "nnhackernews-request-scan: Took %s seconds,"
                                  " with %s gc runs taking %s seconds")
                        seconds num-gc seconds-gc))))))

(defsubst nnhackernews--make-message-id (id)
  "Construct a valid Gnus message id from ID."
  (format "<%s@ycombinator.com>" id))

(defsubst nnhackernews--make-references (id)
  "Construct a space delimited string of message ancestors of ID."
  (mapconcat (lambda (ref) (nnhackernews--make-message-id ref))
             (nnhackernews-refs-for id) " "))

(defun nnhackernews--make-header (article-number &optional group)
  "Construct full headers of articled indexed ARTICLE-NUMBER in GROUP."
  (let* ((header (nnhackernews--get-header article-number group))
         (score (plist-get header :score))
         (num-comments (plist-get header :num_comments)))
    (make-full-mail-header
     article-number
     (replace-regexp-in-string "\\S-+ HN: " ""
                               (or (plist-get header :title)
                                   (plist-get header :link_title)))
     (plist-get header :by)
     (format-time-string "%a, %d %h %Y %T %z (%Z)" (plist-get header :time))
     (nnhackernews--make-message-id (plist-get header :id))
     (nnhackernews--make-references (plist-get header :id))
     0 0 nil
     (append `((X-Hackernews-Name . ,(plist-get header :id)))
             `((X-Hackernews-ID . ,(plist-get header :id)))
             `((X-Hackernews-Permalink . ,(format "%s/item?id=%s" nnhackernews-hacker-news-url (plist-get header :id))))
             (and (integerp score)
                  `((X-Hackernews-Score . ,(number-to-string score))))
             (and (integerp num-comments)
                  `((X-Hackernews-Comments . ,(number-to-string num-comments))))))))

(deffoo nnhackernews-request-article (article-number &optional group server buffer)
  (nnhackernews--normalize-server)
  (unless buffer (setq buffer nntp-server-buffer))
  (nnhackernews--with-group group
    (with-current-buffer buffer
      (erase-buffer)
      (let* ((header (nnhackernews--get-header article-number group))
             (mail-header (nnhackernews--make-header article-number))
             (score (cdr (assq 'X-Hackernews-Score (mail-header-extra mail-header))))
             (permalink (cdr (assq 'X-Hackernews-Permalink (mail-header-extra mail-header))))
             (body (nnhackernews--massage (nnhackernews--get-body header server))))
        (when body
          (insert
           "Newsgroups: " group "\n"
           "Subject: " (mail-header-subject mail-header)  "\n"
           "From: " (or (mail-header-from mail-header) "nobody") "\n"
           "Date: " (mail-header-date mail-header) "\n"
           "Message-ID: " (mail-header-id mail-header) "\n"
           "References: " (mail-header-references mail-header) "\n"
           "Archived-at: " permalink "\n"
           "Score: " score "\n"
           "\n")
          (mml-insert-multipart "alternative")
          (mml-insert-tag 'part 'type "text/html"
                          'disposition "inline"
                          'charset "utf-8")
          (save-excursion (mml-insert-tag '/part))
          (-when-let*
              ((parent (plist-get header :parent))
               (parent-author
                (or (nnhackernews--gethash parent nnhackernews-authors-hashtb)
                    "Someone"))
               (parent-body (nnhackernews--get-body
                             (nnhackernews-find-header parent) server)))
            (insert (nnhackernews--citation-wrap parent-author parent-body)))
          (aif (and nnhackernews-render-story (plist-get header :url))
              (condition-case err
                  (nnhackernews--request
                   "nnhackernews-request-article" it
                   :success (cl-function
                             (lambda (&key data &allow-other-keys)
                               (if (> (length data) nnhackernews-max-render-bytes)
                                   (insert body)
                                 (insert data)))))
                (error (gnus-message 5 "nnhackernews-request-article: %s"
                                     (error-message-string err))
                       (insert body)))
            (insert body))
          (insert "\n")
          (if (mml-validate)

              (message-encode-message-body)
            (gnus-message 2 "nnhackernews-request-article: Invalid mml:\n%s"
                          (buffer-string)))
          (cons group article-number))))))

(defsubst nnhackernews--shift-ranges (delta ranges)
  "Shift back by DELTA the elements of RANGES, removing any negative entries."
  (cl-remove-if-not (lambda (e)
                      (cond ((numberp e) (> e 0))
                            (t (> (cdr e) 0))))
                    (mapcar (lambda (e)
                              (cond ((numberp e) (- e delta))
                                    (t `(,(max 1 (- (car e) delta)) .
                                         ,(- (cdr e) delta)))))
                            ranges)))

(defun nnhackernews-purge ()
  "The size of `nnhackernews-refs-hashtb' is not the problem!"
  (interactive)
  (nnhackernews--with-group "news"
    (let* ((headers (nnhackernews-get-headers group))
           (delta (truncate (* 0.5 (length headers))))
           (info (gnus-get-info gnus-newsgroup-name))
           (remaining (nthcdr delta headers))
           (newsrc-read-ranges (gnus-info-read info))
           (newsrc-mark-ranges (gnus-info-marks info))
           (newsrc-read-ranges-shifted
            (nnhackernews--shift-ranges delta newsrc-read-ranges))
           (newsrc-mark-ranges-shifted
            (mapcar (lambda (what-ranges)
                      (cl-case (car what-ranges)
                        ('seen `(seen (1 . ,(length remaining))))
                        (t (cons (car what-ranges)
                                 (nnhackernews--shift-ranges delta (cdr what-ranges))))))
                    newsrc-mark-ranges)))
      (dolist (id (mapcar (lambda (header) (plist-get header :id))
                          (cl-subseq headers 0 delta)))
        (nnhackernews--remhash id nnhackernews-refs-hashtb)
        (nnhackernews--remhash id nnhackernews-location-hashtb)
        (nnhackernews--remhash id nnhackernews-authors-hashtb))
      (setf (gnus-info-read info) newsrc-read-ranges-shifted)
      (gnus-set-active gnus-newsgroup-name (cons 1 (length remaining)))
      (gnus-info-set-marks info newsrc-mark-ranges-shifted)
      (gnus-set-info gnus-newsgroup-name info)
      (setf (nnhackernews-alist-get group nnhackernews-headers-alist nil nil #'equal)
            (list remaining)))))

(deffoo nnhackernews-retrieve-headers (article-numbers &optional group server _fetch-old)
  (nnhackernews--normalize-server)
  (nnhackernews--with-group group
    (with-current-buffer nntp-server-buffer
      (erase-buffer)
      (dolist (i article-numbers)
        (nnheader-insert-nov (nnhackernews--make-header i group)))
      'nov)))

(deffoo nnhackernews-close-server (&optional server _defs)
  (nnhackernews--normalize-server)
  t)

(deffoo nnhackernews-request-list (&optional server)
  (nnhackernews--normalize-server)
  (with-current-buffer nntp-server-buffer
    (erase-buffer)
    (mapc (lambda (group)
            (let* ((full-name (gnus-group-full-name group `("nnhackernews" ,(or server ""))))
		   (level (gnus-group-level full-name)))
	      (gnus-activate-group full-name t)
	      (when (> level gnus-level-zombie)
		;; Can't know if first time or gnus-level-killed group.
		(gnus-group-unsubscribe-group full-name gnus-level-default-subscribed t))
	      (when (<= level gnus-level-subscribed)
		(insert (format "%s %d 1 y\n" group
				(length (nnhackernews-get-headers group)))))))
          `(,nnhackernews--group-ask
            ,nnhackernews--group-show
            ,nnhackernews--group-job
            ,nnhackernews--group-stories)))
  t)

(deffoo nnhackernews-request-newgroups (_date &optional server)
  (nnhackernews--normalize-server)
  (with-current-buffer nntp-server-buffer
    (erase-buffer)
    (mapc (lambda (group)
            (insert (format "%S 0 1 y\n" group)))
          `(,nnhackernews--group-ask
            ,nnhackernews--group-show
            ,nnhackernews--group-job
            ,nnhackernews--group-stories))
    t))

(defun nnhackernews-sentinel (process event)
  "Wipe headers state when PROCESS dies from EVENT."
  (unless (string= "open" (substring event 0 4))
    (gnus-message 2 "nnhackernews-sentinel: process %s %s"
                  (car (process-command process))
                  (replace-regexp-in-string "\n$" "" event))
    (setq nnhackernews-location-hashtb (gnus-make-hashtable))
    (gnus-backlog-shutdown)))

(defun nnhackernews--message-user (server beg end _prev-len)
  "Message SERVER related alert with `buffer-substring' from BEG to END."
  (let ((string (buffer-substring beg end))
        (magic "::user::"))
    (when (string-prefix-p magic string)
      (message "%s: %s" server (substring string (length magic))))))

(cl-defun nnhackernews--request-delete-success (&key data &allow-other-keys)
  "Delete with extreme prejudice the hidden items in DATA."
  (let* ((dom (nnhackernews--domify data))
         hidden)
    (nnhackernews--extract-hidden dom hidden)
    (let (result)
      (nnhackernews--request
       "nnhackernews--request-delete-success"
       (format "%s/xdelete" nnhackernews-hacker-news-url)
       :backend 'curl
       :data (append (cl-loop for (k v) on hidden by (function cddr)
                              collect (cons (cl-subseq (symbol-name k) 1) v))
                     '(("d" . "Yes")))
       :success (nnhackernews--callback result))
      result)))

(defsubst nnhackernews--extract-unique (message-id)
  "Get unique from <unique@fqdn> in MESSAGE-ID."
  (when (string-match "\\(<[^>]+>\\)" message-id)
    (car (split-string
          (replace-regexp-in-string
           "[<>]" "" (match-string 1 message-id)) "@"))))

(defsubst nnhackernews--request-post-reply-url (headers)
  "Return hexified reply url from HEADERS."
  (let ((references (mail-header-references headers))
        (immediate (nnhackernews--extract-unique
                    (mail-header-message-id headers))))
    (if references
        (let ((root (nnhackernews--extract-unique
                     (car (split-string references " ")))))
          (format "%s/reply?%s"
                  nnhackernews-hacker-news-url
                  (url-build-query-string
                   `((id ,immediate) (goto ,(format "item?id=%s#%s"
                                                    root
                                                    immediate))))))
      (format "%s/comment?%s"
              nnhackernews-hacker-news-url
              (url-build-query-string
                   `((id ,immediate) (goto ,(format "item?id=%s"
                                                    immediate))))))))

(defmacro nnhackernews--set-status-string (dom)
  "Set `nnhackernews-status-string' to DOM remarks for benefit of `nnheader-report'."
  `(let ((body (alist-get 'body ,dom))
         remarks)
     (-tree-map-nodes
      (lambda (x)
        (and (listp x)
             (eq (car x) 'td)
             (stringp (cl-third x))))
      (lambda (x) (!cons (cl-third x) remarks))
      body)
     (setq nnhackernews-status-string
           (mapconcat #'string-trim remarks " "))))

;; C-c C-c from followup buffer
;; message-send-and-exit
;; message-send
;; message-send-method-alist=message-send-news-function=message-send-news
;; gnus-request-post
;; nnhackernews-request-post
(deffoo nnhackernews-request-post (&optional server)
  (nnhackernews--normalize-server)
  (let ((url (aif message-reply-headers
                 (nnhackernews--request-post-reply-url it)
               (format "%s/submit" nnhackernews-hacker-news-url))))
    (let ((ret t)
          (title (or (message-fetch-field "Subject") (error "No Subject field")))
          (link (message-fetch-field "Link"))
          (reply-p message-reply-headers)
          (edit-item (aif (message-fetch-field "Supersedes")
                         (nnhackernews--extract-unique it)))
          (cancel-item (aif (message-fetch-field "Control")
                           (nnhackernews--extract-unique it)))
          (body
           (save-excursion
             (save-restriction
               (message-goto-body)
               (narrow-to-region (point) (point-max))
               (buffer-string)))))
      (cond (cancel-item
             (let* ((header (nnhackernews-find-header cancel-item))
                    (result (nnhackernews--request-delete
                             cancel-item
                             (and (null (plist-get header :title))
                                  (plist-get (nnhackernews--retrieve-root header) :id))))
                    (dom (nnhackernews--domify result)))
               (cl-destructuring-bind (tag params &rest args) dom
                 (setq ret (and (eq tag 'html)
                                (string= (alist-get 'op params) "item")))
                 (unless ret (nnhackernews--set-status-string dom)))))
            (edit-item
             (let* ((result (nnhackernews--request-edit edit-item body))
                    (dom (nnhackernews--domify result)))
               (cl-destructuring-bind (tag params &rest args) dom
                 (setq ret (and (eq tag 'html)
                                (string= (alist-get 'op params) "item")))
                 (unless ret (nnhackernews--set-status-string dom)))))
            (reply-p
             (-if-let* ((hidden (nnhackernews--request-hidden url))
                        (path (car (url-path-and-query (url-generic-parse-url url))))
                        (url (replace-regexp-in-string path "/comment" url))
                        (result (progn (sleep-for 0 nnhackernews-refractory-ms)
                                       (nnhackernews--request-reply url body hidden)))
                        (dom (nnhackernews--domify result)))
                 (cl-destructuring-bind (tag params &rest args) dom
                   (setq ret (and (eq tag 'html)
                                  (string= (alist-get 'op params) "item")))
                   (unless ret (nnhackernews--set-status-string dom)))
               (gnus-message 3 "nnhackernews-request-post: null reply from %s"
                             url)))
            (link
             (let* ((hidden (nnhackernews--request-hidden url))
                    (parsed-url (url-generic-parse-url link))
                    (host (url-host parsed-url))
                    (path (car (url-path-and-query (url-generic-parse-url url))))
                    (url (replace-regexp-in-string path "/r" url)))
               (if (and (stringp host) (not (zerop (length host))))
                   (setq ret (progn
                               (sleep-for 0 nnhackernews-refractory-ms)
                               (nnhackernews--request-submit-link url title link hidden)))
                 (gnus-message 3 "nnhackernews-request-post: invalid url \"%s\"" link)
                 (setq ret nil))))
            (t
             (let* ((hidden (nnhackernews--request-hidden url))
                    (path (car (url-path-and-query (url-generic-parse-url url))))
                    (url (replace-regexp-in-string path "/r" url)))
               (sleep-for 0 nnhackernews-refractory-ms)
               (setq ret (nnhackernews--request-submit-text url title body hidden)))))
      ret)))

(defun nnhackernews--browse-story (&rest _args)
  "What happens when I click on hackernews Subject."
  (-when-let* ((group-article gnus-article-current)
               (url (plist-get (nnhackernews--retrieve-root
                                (nnhackernews--get-header
                                 (cdr group-article)
                                 (gnus-group-real-name (car group-article))))
                           :url)))
    (browse-url url)))

(defun nnhackernews--header-button-alist ()
  "Construct a buffer-local `gnus-header-button-alist' for nnhackernews."
  (let* ((result (copy-alist gnus-header-button-alist))
         (references-value (assoc-default "References" result
                                          (lambda (x y) (string-match-p y x))))
         (references-key (car (rassq references-value result))))
    (setq result (cl-delete "^Subject:" result :test (lambda (x y) (cl-search x (car y)))))
    (setq result (cl-delete references-key result :test (lambda (x y) (cl-search x (car y)))))
    (push (append '("^\\(Message-I[Dd]\\|^In-Reply-To\\):") references-value) result)
    (push '("^Subject:" ": *\\(.+\\)$" 1 (>= gnus-button-browse-level 0)
            nnhackernews--browse-story 1)
          result)
    result))

(defsubst nnhackernews--fallback-link ()
  "Cannot render story."
  (let* ((header (nnhackernews--get-header
                  (cdr gnus-article-current)
                  (gnus-group-real-name (car gnus-article-current))))
         (body (nnhackernews--massage (nnhackernews--get-body header))))
    (with-current-buffer gnus-original-article-buffer
      (article-goto-body)
      (delete-region (point) (point-max))
      (insert body))))

(defalias 'nnhackernews--display-article
  (lambda (article &optional all-headers _header)
    (nnhackernews--with-mutex nnhackernews--mutex-display-article
      (condition-case err
          (gnus-article-prepare article all-headers)
        (error
         (if nnhackernews-render-story
             (progn
               (gnus-message 7 "nnhackernews--display-article: '%s' (falling back...)"
                             (error-message-string err))
               (nnhackernews--fallback-link)
               (gnus-article-prepare article all-headers))
           (error (error-message-string err)))))))
  "In case of shr failures, dump original link.")

(defsubst nnhackernews--dense-time (time)
  "Convert TIME to a floating point number.

Written by John Wiegley (https://github.com/jwiegley/dot-emacs)."
  (+ (* (car time) 65536.0)
     (cadr time)
     (/ (or (car (cdr (cdr time))) 0) 1000000.0)))

(defalias 'nnhackernews--format-time-elapsed
  (lambda (header)
    (condition-case nil
        (let ((date (mail-header-date header)))
          (if (> (length date) 0)
              (let*
                  ((then (nnhackernews--dense-time
                          (apply #'encode-time (parse-time-string date))))
                   (now (nnhackernews--dense-time (current-time)))
                   (diff (- now then))
                   (str
                    (cond
                     ((>= diff (* 86400.0 7.0 52.0))
                      (if (>= diff (* 86400.0 7.0 52.0 10.0))
                          (format "%3dY" (floor (/ diff (* 86400.0 7.0 52.0))))
                        (format "%3.1fY" (/ diff (* 86400.0 7.0 52.0)))))
                     ((>= diff (* 86400.0 30.0))
                      (if (>= diff (* 86400.0 30.0 10.0))
                          (format "%3dM" (floor (/ diff (* 86400.0 30.0))))
                        (format "%3.1fM" (/ diff (* 86400.0 30.0)))))
                     ((>= diff (* 86400.0 7.0))
                      (if (>= diff (* 86400.0 7.0 10.0))
                          (format "%3dw" (floor (/ diff (* 86400.0 7.0))))
                        (format "%3.1fw" (/ diff (* 86400.0 7.0)))))
                     ((>= diff 86400.0)
                      (if (>= diff (* 86400.0 10.0))
                          (format "%3dd" (floor (/ diff 86400.0)))
                        (format "%3.1fd" (/ diff 86400.0))))
                     ((>= diff 3600.0)
                      (if (>= diff (* 3600.0 10.0))
                          (format "%3dh" (floor (/ diff 3600.0)))
                        (format "%3.1fh" (/ diff 3600.0))))
                     ((>= diff 60.0)
                      (if (>= diff (* 60.0 10.0))
                          (format "%3dm" (floor (/ diff 60.0)))
                        (format "%3.1fm" (/ diff 60.0))))
                     (t
                      (format "%3ds" (floor diff)))))
                   (stripped
                    (replace-regexp-in-string "\\.0" "" str)))
                (concat (cond
                         ((= 2 (length stripped)) "  ")
                         ((= 3 (length stripped)) " ")
                         (t ""))
                        stripped))))
      ;; print some spaces and pretend nothing happened.
      (error "    ")))
  "Return time elapsed since HEADER was sent.

Written by John Wiegley (https://github.com/jwiegley/dot-emacs).")

;; Evade package-lint!
(fset 'gnus-user-format-function-S
      (symbol-function 'nnhackernews--format-time-elapsed))

(defun nnhackernews-sort-scored-then-responses (t1 t2)
  "Scored first.  Then whichever of T1 or T2 has more responses.
Modified `gnus-thread-sort-by-score'."
  (let* ((h1 (gnus-thread-header t1))
         (h2 (gnus-thread-header t2))
         (s1 (or (cdr (assq (mail-header-number h1)
		            gnus-newsgroup-scored))
                 gnus-summary-default-score 0))
         (s2 (or (cdr (assq (mail-header-number h2)
		            gnus-newsgroup-scored))
                 gnus-summary-default-score 0)))
    (cond ((and (> s1 gnus-summary-default-high-score)
                (<= s2 gnus-summary-default-high-score))
           t)
          ((and (> s2 gnus-summary-default-high-score)
                (<= s1 gnus-summary-default-high-score))
           nil)
          (t (> (gnus-summary-number-of-articles-in-thread t1)
                (gnus-summary-number-of-articles-in-thread t2))))))

(defun nnhackernews-sort-by-number-of-articles-in-thread (t1 t2)
  "Whichever of T1 or T2 has more responses."
  (> (gnus-summary-number-of-articles-in-thread t1)
     (gnus-summary-number-of-articles-in-thread t2)))

(defun nnhackernews-gather-threads-by-references (threads)
  "Gather THREADS by root reference, and don't be incomprehensible or buggy.
The built-in `gnus-gather-threads-by-references' is both."
  (cl-flet ((special-case
	     (thread)
	     (let ((header (cl-first thread)))
	       (if (stringp header)
		   thread
		 (list (mail-header-subject header) thread))))
	    (has-refs
	     (thread)
	     (let ((header (cl-first thread)))
               (gnus-split-references (mail-header-references header)))))
    (let ((threads-by-ref (gnus-make-hashtable))
	  (separated (-separate #'has-refs threads))
	  result)
      (dolist (thread (cl-second separated))
	(let* ((header (cl-first thread))
	       (id (mail-header-id header))
	       (thread-special (special-case thread)))
	  (push thread-special result)
	  (nnhackernews--sethash id thread-special threads-by-ref)))
      (dolist (thread (cl-first separated))
	(let* ((header (cl-first thread))
	       (refs (gnus-split-references (mail-header-references header)))
	       (ref-thread (cl-some (lambda (ref)
				      (nnhackernews--gethash ref threads-by-ref))
				    refs)))
	  (if ref-thread
	      (setcdr ref-thread (nconc (cdr ref-thread) (list thread)))
	    (setq ref-thread (special-case thread))
	    (push ref-thread result)
	    (nnhackernews--sethash (car refs) ref-thread threads-by-ref))))
      (nreverse result))))

(defun nnhackernews-gather-then-sort (threads)
  "Gather THREADS by root, then sort.
Gnus, for whatever reason, first sorts threads then collates, thus breaking
the initial sort.  Circumvent this stupidity."
  (let ((gnus-thread-sort-functions
         (list 'nnhackernews-sort-scored-then-responses)))
    (gnus-sort-threads
     (nnhackernews-gather-threads-by-references threads))))

(let ((custom-defaults
       ;; For now, revert any user overrides that I can't predict.
       (mapcar (lambda (x)
                 (let* ((var (cl-first x))
                        (sv (get var 'standard-value)))
                   (when (eq var 'gnus-default-adaptive-score-alist)
                     (setq sv (list `(quote
                                      ,(mapcar (lambda (entry)
                                                 (cons (car entry)
                                                       (assq-delete-all 'from (cdr entry))))
                                               (eval (car sv)))))))
                   (cons var sv)))
               (seq-filter (lambda (x) (eq 'custom-variable (cl-second x)))
                           (append (get 'gnus-score-adapt 'custom-group)
                                   (get 'gnus-score-default 'custom-group))))))
  (add-to-list 'gnus-parameters `("^nnhackernews"
                                  ,@custom-defaults
                                  (gnus-summary-make-false-root 'adopt)
                                  (gnus-cite-hide-absolute 5)
                                  (gnus-cite-hide-percentage 0)
                                  (gnus-cited-lines-visible '(2 . 2))
                                  (gnus-use-cache nil)
                                  (gnus-use-adaptive-scoring (quote (line)))
                                  ;; (total-expire . t)
                                  (gnus-newsgroup-adaptive t)
                                  (gnus-simplify-subject-functions (quote (gnus-simplify-subject-fuzzy)))

                                  (gnus-summary-line-format "%3t%U%R%uS %I%(%*%-10,10f  %s%)\n")
                                  (gnus-auto-extend-newsgroup nil)
                                  (gnus-add-timestamp-to-message t)
                                  (gnus-thread-sort-functions (quote (ignore)))
                                  (gnus-summary-thread-gathering-function
                                   (quote nnhackernews-gather-then-sort))
                                  (gnus-subthread-sort-functions (quote (gnus-thread-sort-by-number)))
                                  (gnus-summary-display-article-function
                                   (quote ,(symbol-function 'nnhackernews--display-article)))
                                  (gnus-header-button-alist
                                   (quote ,(nnhackernews--header-button-alist)))
                                  (gnus-visible-headers ,(concat gnus-visible-headers "\\|^Score:")))))

(nnoo-define-skeleton nnhackernews)

(defun nnhackernews-article-mode-activate ()
  "Augment the `gnus-article-mode-map' conditionally."
  (when (nnhackernews--gate)
    (nnhackernews-article-mode)))

(deffoo nnhackernews-request-expire-articles (articles &optional group server _force)
  "Never gets called sinced I turned off total . expire.
Preserving indices so `nnhackernews-find-header' still works."
  (nnhackernews--normalize-server)
  (nnhackernews--with-group group
    (dolist (art articles)
      (let ((i (1- art))
            (headers (nnhackernews-get-headers group)))
        (if (zerop i)
            (setcar headers nil)
          (setcdr (nthcdr (1- i) headers) (cons nil (nthcdr (1+ i) headers))))))
    (nnhackernews--checksum)
    nil))

(defun nnhackernews-summary-mode-activate ()
  "Shadow some bindings in `gnus-summary-mode-map' conditionally."
  (when (nnhackernews--gate)
    (nnhackernews-summary-mode)))

;; I believe I did try buffer-localizing hooks, and it wasn't sufficient
(add-hook 'gnus-article-mode-hook #'nnhackernews-article-mode-activate)
(add-hook 'gnus-summary-mode-hook #'nnhackernews-summary-mode-activate)
(add-hook 'gnus-message-setup-hook
          (lambda ()
            (when (nnhackernews--message-gate)
              (message-replace-header
               "From"
               (concat (nnhackernews--who-am-i) "@ycombinator.com")))))

;; Avoid having to select the GROUP to make the unread number go down.
(add-hook 'gnus-after-getting-new-news-hook
	  (lambda ()
            (when (> (length (nnhackernews-get-headers "news"))
                     nnhackernews-purge-threshold)
              (nnhackernews-purge))
            (mapc (lambda (group)
                    (nnhackernews--score-unread group))
                  `(,nnhackernews--group-ask
                    ,nnhackernews--group-show
                    ,nnhackernews--group-job
                    ,nnhackernews--group-stories))))

;; Without this, I get Y's the first time around.  See 15195cc.
(add-hook 'gnus-started-hook
          (lambda () (mapc (lambda (group)
                             (nnhackernews--mark-scored-as-read group))
                           `(,nnhackernews--group-ask
                             ,nnhackernews--group-show
                             ,nnhackernews--group-job
                             ,nnhackernews--group-stories)))
          t)

;; "Can't figure out hook that can remove itself (quine conundrum)"
(add-function :around (symbol-function 'gnus-summary-exit)
              (lambda (f &rest args)
                (let ((gnus-summary-next-group-on-exit
                       (unless (nnhackernews--gate)
                         gnus-summary-next-group-on-exit)))
                  (apply f args))))

(add-function :after (symbol-function 'gnus-summary-exit)
              (symbol-function 'nnhackernews--score-pending))

(add-function :before (symbol-function 'gnus-score-save)
              (lambda (&rest _)
                (when (nnhackernews--gate)
                  (setq nnhackernews-score-files
                        (assq-delete-all (intern gnus-newsgroup-name)
                                         nnhackernews-score-files)))))

;; `gnus-newsgroup-p' requires valid method post-mail to return t
(add-to-list 'gnus-valid-select-methods '("nnhackernews" post-mail) t)

(add-function
 :around (symbol-function 'message-supersede)
 (lambda (f &rest args)
   (cond ((nnhackernews--message-gate)
          (add-function :override
                        (symbol-function 'mml-insert-mml-markup)
                        #'ignore)
          (unwind-protect
              (prog1 (apply f args)
                (remove-function (symbol-function 'mml-insert-mml-markup) #'ignore)
                (save-excursion
                  (save-restriction
                    (message-replace-header
                     "From"
                     (concat (nnhackernews--who-am-i) "@ycombinator.com"))
                    (message-goto-body)
                    (narrow-to-region (point) (point-max))
                    (goto-char (point-max))
                    (mm-inline-text-html nil)
                    (delete-region (point-min) (point)))))
            (remove-function (symbol-function 'mml-insert-mml-markup) #'ignore)))
         (t (apply f args)))))

(add-function
 :around (symbol-function 'message-send-news)
 (lambda (f &rest args)
   (cond ((nnhackernews--message-gate)
          (let* ((dont-ask (lambda (prompt)
                             (when (cl-search "mpty article" prompt) t)))
                 (link-p (message-fetch-field "Link"))
                 (message-shoot-gnksa-feet (if link-p t message-shoot-gnksa-feet)))
            (when link-p
              (add-function :before-until (symbol-function 'y-or-n-p) dont-ask))
            (unwind-protect (apply f args)
              (remove-function (symbol-function 'y-or-n-p) dont-ask))))
         (t (apply f args)))))

(add-function
 :around (symbol-function 'gnus-summary-post-news)
 (lambda (f &rest args)
   (cond ((nnhackernews--gate)
          (let* ((nnhackernews-post-type (read-char-choice "[l]ink / [t]ext: " '(?l ?t)))
                 (link-header (apply-partially #'message-add-header "Link: https://"))
                 (add-link-header (apply-partially #'add-hook
                                                   'message-header-setup-hook
                                                   link-header))
                 (remove-link-header (apply-partially #'remove-hook
                                                      'message-header-setup-hook
                                                      link-header)))
            (cl-case nnhackernews-post-type
              (?l (funcall add-link-header)))
            (condition-case err
                (progn
                  (apply f args)
                  (funcall remove-link-header))
              (error (funcall remove-link-header)
                     (error (error-message-string err))))))
         (t (apply f args)))))

(add-function
 :filter-return (symbol-function 'message-make-fqdn)
 (lambda (val)
   (if (and (nnhackernews--message-gate)
            (cl-search "--so-tickle-me" val))
       "ycombinator.com" val)))

(add-function
 :around (symbol-function 'message-is-yours-p)
 (lambda (f &rest args)
   (let ((concat-func (lambda (f &rest args)
                        (let ((fetched (apply f args)))
                          (if (string= (car args) "from")
                              (concat fetched "@ycombinator.com")
                            fetched)))))
     (when (nnhackernews--message-gate)
       (add-function :around
                     (symbol-function 'message-fetch-field)
                     concat-func))
     (unwind-protect
         (apply f args)
       (remove-function (symbol-function 'message-fetch-field) concat-func)))))

(let ((protect (lambda (caller)
                 (add-function
                  :around (symbol-function caller)
                  (lambda (f &rest args)
                    (cond ((nnhackernews--gate)
                           (condition-case err
                               (apply f args)
                             (error (gnus-message 7 "%s: %s"
                                                  caller
                                                  (error-message-string err)))))
                          (t (apply f args))))))))
  (funcall protect 'url-http-generic-filter)
  (funcall protect 'url-http-end-of-document-sentinel))

;; Make the scoring entries Markovian
(add-function
 :around (symbol-function 'gnus-summary-score-entry)
 (lambda (f header match &rest args)
   (cond ((nnhackernews--gate)
          (cl-flet ((my-delete-all ;; assoc-delete-all for emacs-25
                     (key alist)
                     (progn
                       (while (and (consp (car alist))
	                           (equal (caar alist) key))
                         (setq alist (cdr alist)))
                       (let ((tail alist) tail-cdr)
                         (while (setq tail-cdr (cdr tail))
                           (if (and (consp (car tail-cdr))
	                            (equal (caar tail-cdr) key))
	                       (setcdr tail (cdr tail-cdr))
	                     (setq tail tail-cdr))))
                       alist)))
            (let* ((match (downcase match))
                   (new-touched
                    (let ((gnus-score-alist (copy-alist '((touched nil)))))
                      ;; gnus-summary-score-entry modifies gnus-score-alist
                      (cons (apply f header match args)
                            (cl-some #'identity (gnus-score-get 'touched)))))
                   (new (car new-touched))
                   (touched (cdr new-touched)))
              (when (and touched new)
                (let ((old (gnus-score-get header)))
                  (mapc (lambda (what) (setq old (my-delete-all what old)))
                        (list match
                              (gnus-simplify-subject-re match)
                              (gnus-simplify-subject-fuzzy match)))
                  (gnus-score-set header (cons new old) nil t)
                  (gnus-score-set 'touched '(t))))
              new)))
         (t (apply f header match args)))))

;; the let'ing to nil of `gnus-summary-display-article-function'
;; in `gnus-summary-select-article' dates back to antiquity.
(add-function
 :around (symbol-function 'gnus-summary-display-article)
 (lambda (f &rest args)
   (cond ((nnhackernews--gate)
          (let ((gnus-summary-display-article-function
                 (symbol-function 'nnhackernews--display-article)))
            (apply f args)))
         (t (apply f args)))))

(add-function
 :around (symbol-function 'gnus-group-get-new-news-this-group)
 (lambda (f &rest args)
   "Semaphore down `nnhackernews-avoid-rescoring'."
   (let ((nnhackernews-avoid-rescoring t))
     (apply f args))))

;; disallow caching as firebase might change the article numbering?
(setq gnus-uncacheable-groups
      (aif gnus-uncacheable-groups
          (format "\\(%s\\)\\|\\(^nnhackernews\\)" it)
        "^nnhackernews"))

;; I would use custom-set-variables, but that mucks with the user's .emacs.
;; I suspect I did try putting this in `gnus-parameters' but out-of-band.
(let ((update-score-files
       (lambda (file)
	 (when (nnhackernews--gate)
	   (unless (member file (alist-get (intern gnus-newsgroup-name)
					   nnhackernews-score-files))
	     (push file (alist-get (intern gnus-newsgroup-name)
				   nnhackernews-score-files)))))))
  (if gnus-score-after-write-file-function
      (add-function :after gnus-score-after-write-file-function update-score-files)
    (setq gnus-score-after-write-file-function update-score-files)))

;; (push '((and (eq (car gnus-current-select-method) 'nnhackernews)
;;              (eq mark gnus-unread-mark)
;;              (not (string-match-p
;;                    "^Re: " (gnus-summary-article-subject))))
;;         . gnus-summary-high-unread)
;;       gnus-summary-highlight)

(provide 'nnhackernews)

;;; nnhackernews.el ends here
