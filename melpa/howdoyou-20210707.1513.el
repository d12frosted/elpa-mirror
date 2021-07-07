;;; howdoyou.el --- A stackoverflow and its sisters' sites reader   -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Thanh Vuong

;; Author: Thanh Vuong <thanhvg@gmail.com>
;; URL: https://github.com/thanhvg/howdoyou/
;; Package-Version: 20210707.1513
;; Package-Commit: 4943a4ef8d242952ade64903a05c13094de2fbf0
;; Package-Requires: ((emacs "25.1") (promise "1.1") (request "0.3.0") (org "9.2"))
;; Version: 0.2.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This package is inspired by python howdoi (https://github.com/gleitz/howdoi)
;; and howdoi Emacs package (https://github.com/lockie/emacs-howdoi and
;; https://github.com/atykhonov/emacs-howdoi). it searches your query all across
;; stackoverflow and its sisters' sites. They are: stackoverflow.com,
;; stackexchange.com, superuser.com, serverfault.com and askubuntu.com. The
;; result is then showed in an `org-mode' buffer. For each result, the question
;; and three answers were showed, but they are collapsed by default except the
;; first answer. As this package uses Google to get the links, for each query
;; there will be a dozen of links, the fist link will be used, users can go
;; through these links. The author believes that when searching for solutions it
;; is important for users to read both questions and answers, so no "quick look"
;; features such as code only view or code completion are provided.

;;; Dependencies
;; `promise' and `request' are required.
;; user must have `org-mode' 9.2 or later installed also.

;;; Commands
;; howdoyou-query:                   prompt for query and do search
;; howdoyou-next-link:               go to next link
;; howdoyou-previous-link:           go to previous link
;; howdoyou-go-back-to-first-link:   go back to first link
;; howdoyou-reload-link:             reload link

;;; Customization
;; howdoyou-use-curl:                default is true if curl is available
;; howdoyou-number-of-answers:       maximal number of answers to show, default is 3
;; howdoyou-switch-to-answer-buffer: switch to answer buffer if non nil, default is nil

;;; Changelog
;; 2021-07-06:
;; - adapt to new SO change: trim score text
;; 2020-10-02:
;; - update with change from google
;; - impove test
;; - bump version
;; 2020-08-27:
;; - bump version
;; - adapt to recent change by SO: css class from "post-text" to "s-prose"
;; 2020-08-28:
;; - adapt to recent change by SO: css class from "post-text" to "s-prose"

;;; Code:
(require 'promise)
(require 'dom)
(require 'cl-lib)
(require 'request)
(require 'shr)
(require 'org)
(require 'subr-x)
(require 'url)
(require 'font-lock)

;; public variables
(defgroup howdoyou nil
  "Search and read stackoverflow and sisters's sites."
  :group 'extensions
  :group 'convenience
  :version "25.1"
  :link '(emacs-commentary-link "howdoyou.el"))

(defcustom howdoyou-use-curl (if (executable-find request-curl)
                                 t
                               nil)
  "Use curl instead of buggy `url-retrieve'."
  :type 'boolean
  :group 'howdoyou)

(defcustom howdoyou-number-of-answers 3
  "Number of maximal answers to show."
  :type 'number
  :group 'howdoyou)


(defcustom howdoyou-max-history 20
  "Number of maximal query history."
  :type 'number
  :group 'howdoyou)

(defcustom howdoyou-switch-to-answer-buffer nil
  "If non-nil answer-buffer will be selected."
  :type 'boolean
  :group 'howdoyou)

;; private variables
(defvar howdoyou--current-link-index 0
  "Current index of link.")

(defvar howdoyou--links nil
  "List of so links from google search.")

(defvar howdoyou--query-history '()
  "List of query history")

(defvar howdoyou--current-lang nil
  "Guested language.")

(defvar howdoyou--current-user-agent 0
  "Index to be rotated.")

(defvar howdoyou--google-link-class "^yuRUbf$"
  "css class name of dom node that has <a href></a> node as a child.")

;; (setq howdoyou--google-link-class "^yuRUbf$")

(define-minor-mode howdoyou-mode
  "Minor mode for howdoyou.

\\{howdoyou-mode-map}
"
  :lighter " HDY"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-M-<left>") #'howdoyou-previous-link)
            (define-key map (kbd "C-M-<right>") #'howdoyou-next-link)
            map))

;; idea from https://github.com/gleitz/howdoi
(defvar howdoyou--user-agents
  '( "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36")
  "List of user agent to make Google happy.")


;; (setq howdoyou--user-agents
;;   '( "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36"))

;; functions
(defun howdoyou--extract-links-from-class (dom class)
  "Extract links inside r class from DOM."
  (let ((my-nodes (dom-by-class dom class)))
    (mapcar (lambda (a-node)
              (dom-attr (dom-child-by-tag a-node 'a) 'href))
            my-nodes)))

(defun howdoyou--extract-links-from-google (dom)
  "Produce links from google search dom.
DOM is a dom object of the google search, returns a list of links"
  (howdoyou--extract-links-from-class dom howdoyou--google-link-class))

(defun howdoyou--curl-promise-dom (url)
  "Promise (url . dom) from URL with curl."
  (promise-new
   (lambda (resolve reject)
     ;; shadow reject-curl-options to have user agent
     (let ((request-curl-options `(,(format "-A %s" (howdoyou--get-user-agent)))))
       (request url
         :parser (lambda () (progn (decode-coding-region (point-min) (point-max) 'utf-8)
                                   (libxml-parse-html-region (point-min) (point-max))))
         :error (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
                               (funcall reject  error-thrown)))
         :success (cl-function (lambda (&key data &allow-other-keys)
                                 (funcall resolve (cons url data)))))))))

(defun howdoyou--url-promise-dom (url)
  "Promise a cons (URL . dom).
URL is a link string. Download the url and parse it to a DOM object"
  ;; (message "%s" url)
  (promise-new
   (lambda (resolve reject)
     (let ((url-user-agent (howdoyou--get-user-agent)))
       (url-retrieve url
                     (lambda (status)
                       (if (plist-get status :error)
                           (funcall reject (plist-get status :error))
                         (condition-case ex
                             (with-current-buffer (current-buffer)
                               (if (not (url-http-parse-headers))
                                   (funcall reject (buffer-string))
                                 (funcall resolve (cons url (libxml-parse-html-region (point-min) (point-max))))))
                           (error (funcall reject ex))))))))))

(defun howdoyou--promise-dom (url)
  "Promise a cons (URL . dom).
URL is a link string. Download the url and parse it to a DOM object"
  (if howdoyou-use-curl (howdoyou--curl-promise-dom url)
    (howdoyou--url-promise-dom url)))

(defun howdoyou--get-user-agent ()
  "Rotate user agent from `howdoyou--user-agents'."
  (let ((user-agent (nth howdoyou--current-user-agent howdoyou--user-agents)))
    (setq howdoyou--current-user-agent (if (>= howdoyou--current-user-agent
                                               (1- (length howdoyou--user-agents)))
                                           0
                                         (1+ howdoyou--current-user-agent)))
    user-agent))

(defun howdoyou--get-buffer ()
  "Get *How Do You* buffer."
  (get-buffer-create "*How Do You*"))

(defun howdoyou--print-waiting-message (&optional msg &rest args)
  "Print MSG message and prepare window for howdoyou buffer."
  (let ((my-buffer (howdoyou--get-buffer)))
    (unless (equal (window-buffer) my-buffer)
      ;; (switch-to-buffer-other-window my-buffer))
      (if howdoyou-switch-to-answer-buffer
          (select-window
           (display-buffer my-buffer
                           '(display-buffer-use-some-window (inhibit-same-window
                                                             . t))))
        (display-buffer my-buffer
                        '(display-buffer-use-some-window (inhibit-same-window
                                                          . t)))))
    (with-current-buffer my-buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (if msg
                    (apply #'format msg args)
                  "Searching...")))
      (read-only-mode 1)
      (unless howdoyou-mode
        (howdoyou-mode 1)))))

(defun howdoyou-promise-answer (query)
  "Process QUERY and print answers to *How Do You* buffer."
  (howdoyou--print-waiting-message)
  (let ((url "https://www.google.com/search")
        (args (concat "?q="
                      (url-hexify-string query)
                      (url-hexify-string " ")
                      (url-hexify-string "site:stackoverflow.com OR ")
                      (url-hexify-string "site:stackexchange.com OR ")
                      (url-hexify-string "site:superuser.com OR ")
                      (url-hexify-string "site:serverfault.com OR ")
                      (url-hexify-string "site:askubuntu.com")
                      "&hl=en")))
    (promise-chain (howdoyou--promise-dom (concat url args))
      (then (lambda (result)
              (howdoyou--extract-links-from-google (cdr result))))
      (then (lambda (links)
              (setq howdoyou--links links)
              (setq howdoyou--current-link-index 0)
              (if howdoyou--links
                  (howdoyou-n-link 0)
                ;; TODO print this error to howdoyou buffer
                (message "howdoyou-promise-answer: No results \"%s\"" query))))
      (catch (lambda (reason)
               (message "catch error in promise answer: %s" reason))))))

(defun howdoyou--get-so-tags (dom)
  "Extract list of tags from stackoverflow DOM."
  (let ((tag-doms (dom-by-class (dom-by-class dom "^post-taglist")
                                "^post-tag$")))
    (mapcar #'dom-text tag-doms)))


(defun howdoyou--get-answer-and-time-from-nodes (nodes)
  "From answer NODES produce list of (answer. time)."
  (cons (dom-by-class nodes "s-prose")
        (mapconcat (lambda (it) (substring (dom-attr it 'title) 0 10))
                   (dom-by-class nodes "relativetime")
                   " / ")))

(defun howdoyou--promise-so-answer (result)
  "Produce answer-list  from stackoverflow response.
RESULT is a (url . dom).
Return (url title question answers scores tags)"
  (let* ((answer-nodes (dom-by-class (cdr result) "answercell"))
         (question-dom (car (dom-by-id (cdr result) "^question$")))
         (title (car (dom-by-class (cdr result) "question-hyperlink")))
         (number-of-answers (if (> (length answer-nodes) howdoyou-number-of-answers)
                                howdoyou-number-of-answers
                              (length answer-nodes)))
         (tags (howdoyou--get-so-tags (cdr result)))
         (score-nodes (dom-by-class (cdr result) "js-vote-count")))
    (list (car result)
          (dom-text title)
          (dom-by-class question-dom "s-prose")
          (mapcar #'howdoyou--get-answer-and-time-from-nodes
                  (seq-take answer-nodes number-of-answers))
          (mapcar (lambda (it) (string-trim (dom-text it)))
                  (seq-take score-nodes (1+ number-of-answers)))
          tags)))

(defun howdoyou--print-answer (answer-list)
  "Print ANSWER-LIST to *How Do You* buffer."
  (let* ((my-buffer (howdoyou--get-buffer))
         (url (car answer-list))
         (title (nth 1 answer-list))
         (question (nth 2 answer-list))
         (answers (nth 3 answer-list)) ;; list of (answer . time)
         (scores (nth 4 answer-list))
         (question-score (car scores))
         (answer-scores (cdr scores))
         (tags (nth 5 answer-list))
         (first-run t) ;; flag for special treatment of first answer
         (lang (car tags))) ;; first tag is usually the language
    (setq howdoyou--current-lang lang)
    (with-current-buffer my-buffer
      (read-only-mode -1)
      (erase-buffer)
      (insert "#+STARTUP: overview\n#+TITLE: " title "\n")
      (insert url) ;; url
      (insert (format "\n* Question (%s)" question-score))
      (howdoyou--print-dom question)
      (insert "\nTags: ")
      (dolist (tag tags)
        (insert tag)
        (insert " "))
      (cl-mapcar (lambda (a s)
                   (insert (format "\n* Answer (%s) (%s)" s (cdr a)))
                   (when first-run
                     (insert "\n:PROPERTIES:\n:VISIBILITY: all\n:END:\n")
                     (setq first-run nil))
                   (howdoyou--print-dom (car a)))
                 answers
                 answer-scores)
      (delete-trailing-whitespace)
      (howdoyou--print-history)
      (if (equal major-mode 'org-mode)
          (org-set-startup-visibility)
        (org-mode)
        (setq-local org-hide-emphasis-markers t)
        ;; need this on spacemacs if org-mode never loaded anywhere
        (font-lock-flush))
      (visual-line-mode)
      (unless howdoyou-mode
        (howdoyou-mode 1))
      (goto-char (point-min)))))

(defun howdoyou--print-node (dom)
  "Print the DOM."
  ;; shadow some `shr' parameters
  (let ((shr-bullet "- ") ;; instead of *
        ;; no more line breaks
        (shr-width 0)
        ;; because we use fixed width anyway, save some computations
        (shr-use-fonts nil))
    (shr-insert-document dom)))

(defun howdoyou--pre-class-name-to-lang (class-name)
  "Return language name from CLASS-NAME.
CLASS-NAME has lang-name => name.
CLASS-NAME has default => `howdoyou--current-lang'.
CLASS-NAME has nothing => empty string"
  (cond
   ((not (stringp class-name)) "")
   ((string-match "lang-\\b\\(.+?\\)\\b" class-name)
    (match-string 1 class-name))
   (t howdoyou--current-lang)))

(defun howdoyou--it-to-it (it)
  "Map node to node.
IT is an element in the DOM tree. Map to different IT when it is
a, img or pre. Otherwise just copy"
  (cond
   ((and (listp it)
         (listp (cdr it))) ;; check for list but not cons
    (cond
     ((equal (car it) 'h2)
      (concat "** " (dom-texts it)))
     ((equal (car it) 'blockquote)
      `(blockquote nil "#+begin_quote" ,(mapcar #'howdoyou--it-to-it it) "#+end_quote"))
     ((equal (car it) 'code)
      (concat "~" (dom-texts it) "~"))
     ((equal (car it) 'strong)
      (concat "*" (dom-texts it) "*"))
     ((memq (car it) '(em i))
      (concat "/" (dom-texts it) "/"))
     ((memq (car it) '(s del))
      (concat "+" (dom-texts it) "+"))
     ((and (equal (car it) 'a)
           (not (dom-by-tag it 'img))) ;; bail out if img
      (org-link-make-string (dom-attr it 'href) (dom-texts it)))
     ;; ((and (equal (dom-tag it) 'div)
     ;;       (equal (dom-attr it 'class) "snippet"))
     ;;  (mapcar #'howdoyou--it-to-it (dom-by-tag it 'pre)))
     ((equal (car it) 'pre)
      `(pre nil "#+begin_example "
            ,howdoyou--current-lang "\n" ,@(nthcdr 2 it)
            ,(if (dom-attr it 'class)
                 "\n#+end_example"
               "#+end_example")))
     ;; (append `(pre nil "#+begin_example " ,howdoyou--current-lang "\n") (nthcdr 2 it) '("#+end_example")))
     (t (mapcar #'howdoyou--it-to-it it))))
   (t it)))

(defun howdoyou--print-dom (dom)
  "Map new dom from DOM and print it."
  (howdoyou--print-node (mapcar #'howdoyou--it-to-it dom)))

(defun howdoyou--update-history (query)
  "Add QUERY to `howdoyou--query-history'."
  (setq howdoyou--query-history
        (seq-take (add-to-list 'howdoyou--query-history query)
                  howdoyou-max-history)))

(defun howdoyou--print-history ()
  "Print `howdoyou--query-history'."
  (insert "\n* History\n")
  (dolist (query howdoyou--query-history)
    (insert (format "[[elisp:(howdoyou-promise-answer \"%s\")][%s]]\n"
                    query
                    query))))

;;;###autoload
(defun howdoyou-query (query)
  "Prompt for QUERY and search for answer.
Pop up *How Do You* buffer to show the answer."
  (interactive "sQuery: ")
  (message "_") ;; prevent suggest-key-bindings from usurping minibuffer
  (howdoyou--update-history query)
  (howdoyou-promise-answer query))

(defun howdoyou-n-link (n)
  "Jump N steps in `howdoyou--links' and request and print the answer."
  (let ((cand (+ n howdoyou--current-link-index))
        (total (length howdoyou--links)))
    (when (zerop total)
      (error "howdoyou-n-link: No current links"))
    (cond ((< cand 0)
           (setq cand 0)
           (message "howdoyou-n-link: at first link %s of %s" (1+ cand) total))
          ((>= cand total)
           (setq cand (1- total))
           (message "howdoyou-n-link: at final link %s of %s" (1+ cand) total)))
    (when (or (zerop n) (/= cand howdoyou--current-link-index))
      (let ((link (nth cand howdoyou--links)))
        (howdoyou--print-waiting-message "Loading %s of %s..." (1+ cand) total)
        (promise-chain (howdoyou--promise-dom link)
          (then #'howdoyou--promise-so-answer)
          (then #'howdoyou--print-answer)
          (then (lambda (_result)
                  (setq howdoyou--current-link-index cand)))
          (catch (lambda (reason)
                   (message "catch error in n-link: %s %s" reason link)
                   (unless (zerop n)
                     (let ((one-past
                            (min (1- total)
                                 (max 0 (funcall (if (< n 0) #'1- #'1+) n)))))
                       (when (/= one-past cand)
                         (howdoyou-n-link one-past)))))))))))

(defun howdoyou-read-so-link (link)
  "Read stackoverflow LINK in buffer."
  (promise-chain (howdoyou--promise-dom link)
    (then #'howdoyou--promise-so-answer)
    (then #'howdoyou--print-answer)
    (catch (lambda (reason)
             (message "catch error in so-link: %s" reason)))))

(defun howdoyou-clear-history ()
  "Clear `howdoyou--query-history'."
  (setq howdoyou--query-history '()))

;;;###autoload
(defun howdoyou-next-link ()
  "Go to next link stored in google search."
  (interactive)
  (howdoyou-n-link 1))

;;;###autoload
(defun howdoyou-previous-link ()
  "Go to previous link stored in google search."
  (interactive)
  (howdoyou-n-link -1))

;;;###autoload
(defun howdoyou-reload-link ()
  "Reload current link in google search."
  (interactive)
  (howdoyou-n-link 0))

;;;###autoload
(defun howdoyou-go-back-to-first-link ()
  "Reload current link in google search."
  (interactive)
  (howdoyou-n-link (- howdoyou--current-link-index)))

(provide 'howdoyou)
;;; howdoyou.el ends here
