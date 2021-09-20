;;; gnus-recent.el --- Article breadcrumbs for Gnus -*- lexical-binding: t -*-

;; Copyright (C) 2018-2021 Kevin Brubeck Unhammer

;; Author: Kevin Brubeck Unhammer <unhammer@fsfe.org>
;; Version: 0.4.0
;; Package-Version: 20210920.902
;; Package-Commit: dfa0e687601e78d6be82530413cb00edb1a39889
;; URL: https://github.com/unhammer/gnus-recent
;; Package-Requires: ((emacs "25.3.2"))
;; Keywords: convenience, mail

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Avoid having to open Gnus and find the right group just to get back to
;;; that e-mail you were reading.

;;; To use, require and bind whatever keys you prefer to the
;;; interactive functions:
;;;
;;; (use-package gnus-recent
;;;   :after gnus
;;;   :bind (("<f3>" . gnus-recent)
;;;          :map gnus-summary-mode-map ("l" . gnus-recent-goto-previous)
;;;          :map gnus-group-mode-map ("C-c L" . gnus-recent-goto-previous)))

;;; Code:

(require 'gnus-sum)
(unless (require 'org-gnus nil 'noerror)
  (require 'ol-gnus))                   ; for org-gnus-follow-link

(defvar gnus-recent--articles-list nil
  "The list of articles read in this Emacs session.")

(defvar gnus-recent--showing-recent nil
  ;; TODO: isn't there some way of showing the calling function?
  "Internal variable; true iff we're currently showing a recent article.")

(defgroup gnus-recent nil
  "Options for gnus-recent."
  :tag "gnus-recent"
  :group 'gnus)

(defcustom gnus-recent-track-sent t
  "Should we track sent emails as well?"
  :group 'gnus-recent
  :type 'boolean)

(defcustom gnus-recent-include-unsent nil
  "Should we include open, unsent draft buffers as well?"
  :group 'gnus-recent
  :type 'boolean)

(defun gnus-recent--date-format (date)
  "Convert the DATE to 'YYYY-MM-D HH:MM:SS a' format."
  (condition-case ()
      (format-time-string "%F %T %a" (gnus-date-get-time date))
    (error "")))

(defun gnus-recent--get-article-data ()
  "Get the article data used for `gnus-recent' based on `gnus-summary-article-header'."
  (unless gnus-recent--showing-recent
    (let* ((article-number (gnus-summary-article-number))
           (article-header (gnus-summary-article-header article-number)))
      (list (gnus-recent--pretty-article article-header)
            (mail-header-id article-header)
            gnus-newsgroup-name
            (mail-header-from article-header)
            (cdr (assoc 'To (mail-header-extra article-header)))
            (mail-header-subject article-header)))))

(defun gnus-recent--pretty-article (article-header)
  "Format ARTICLE-HEADER for prompting the user."
  (format "%s: %s \t%s"
          (propertize (gnus-recent--name-from-address (mail-header-from article-header))
                      'face
                      'bold)
          (mail-header-subject article-header)
          (propertize (gnus-recent--date-format (mail-header-date article-header))
                      'face
                      'gnus-recent-date-face)))

(defun gnus-recent--pretty-unsent ()
  "Format headers of unsent mail (current buffer) for prompting the user."
  (concat (propertize (buffer-name)
                      'face
                      'bold)
          (when-let ((to (message-fetch-field "to")))
            (format " to %s" to))
          (when-let ((subject (message-fetch-field "subject")))
            (format ": %s" subject))))

(defun gnus-recent--get-sent-data (message-id group from to subject date)
  "Get the article data used for `gnus-recent' for a sent message.
Arguments MESSAGE-ID FROM SUBJECT DATE as in `make-full-mail-header',
GROUP is the newsgroup-name, TO is recipient."
  (unless gnus-recent--showing-recent
    (list (gnus-recent--pretty-article
           (make-full-mail-header nil subject from date message-id))
          message-id
          group
          from
          to
          subject)))

(defun gnus-recent--name-from-address (adr)
  "Get the name (not e-mail) portion of e-mail ADR."
  (replace-regexp-in-string
   "\\([^<]*\\) <\\(.*\\)>"
   "\\1"
   (replace-regexp-in-string
    "\"\\([^\"]*\\)\" <\\(.*\\)>"
    "\\1"
    adr)))

(defmacro gnus-recent--add-to-front (lst elt)
  "Add ELT to the front of LST, ensuring it's only once in the list.
The comparison is done with `equal'."
  `(setq ,lst (cons ,elt
                    (remove ,elt ,lst))))

(defun gnus-recent--track (article-data)
  "Store message described by ARTICLE-DATA in the recent article list.
For tracking of Backend moves (B-m) see `gnus-recent--track-move-article'."
  (when article-data
    (gnus-recent--add-to-front gnus-recent--articles-list
                               article-data))
  (setq gnus-recent--showing-recent nil))

(defun gnus-recent--track-article ()
  "Store this article in the recent article list.
For tracking of Backend moves (B-m) see `gnus-recent--track-move-article'."
  (gnus-recent--track (gnus-recent--get-article-data)))

(defun gnus-recent--track-move-article (action _article _from-group to-group _select-method)
  "Track backend move (B-m) of articles.
When ACTION is 'move, will change the group to TO-GROUP for the
article data in `gnus-recent--articles-list', but only if the
moved article was already tracked.  For use by
`gnus-summary-article-move-hook'."
  (when (eq action 'move)
    (gnus-recent--update (gnus-recent--get-article-data) to-group)))

(defun gnus-recent--track-delete-article (action _article _from-group &rest _rest)
  "Track interactive user deletion of articles.
Remove the article data in `gnus-recent--articles-list'.  ACTION
should be 'delete.
For use by `gnus-summary-article-delete-hook'."
  (when (eq action 'delete)
    (gnus-recent-forget (gnus-recent--get-article-data))))

(defun gnus-recent--track-expire-article (action _article _from-group to-group _select-method)
  "Track when articles expire.
Handle the article data in `gnus-recent--articles-list',
according to the expiry ACTION.  TO-GROUP should have the value of
the expiry-target group if set.
For use by `gnus-summary-article-expire-hook'."
  (when (eq action 'delete)
    (let ((article-data (gnus-recent--get-article-data)))
      (when (member article-data gnus-recent--articles-list)
          (if to-group                  ; article moves to the expiry-target group
              (gnus-recent--update article-data to-group)
            (gnus-recent-forget article-data)))))) ; article is deleted

;; Activate the hooks  (should be named -functions)
;; Note: except for the 1st, the other hooks run using run-hook-with-args
(add-hook 'gnus-article-prepare-hook        'gnus-recent--track-article)
(add-hook 'gnus-summary-article-move-hook   'gnus-recent--track-move-article)
(add-hook 'gnus-summary-article-delete-hook 'gnus-recent--track-delete-article)
(add-hook 'gnus-summary-article-expire-hook 'gnus-recent--track-expire-article)

;; Track sent mail:
(defvar-local gnus-recent--latest-gcc nil
  "The value of the Gcc header as seen on sending, or nil.")

(defun gnus-recent--track-gcc-on-send ()
  "Use as `message-send-hook' to take note of the Gcc field.
Gcc is removed on send, so need to store it for tracking.  If
there are several Gcc fields, we use the first one."
  (setq-local gnus-recent--latest-gcc (mail-fetch-field "gcc")))

(defun gnus-recent--track-sent-message ()
  "Use as `message-send-hook' to track this message in `gnus-recent'."
  (when-let ((group (string-trim gnus-recent--latest-gcc ; is quoted if it has spaces
                                 "\"" "\""))
             (message-id (mail-fetch-field "Message-ID")))
    (gnus-recent--track (gnus-recent--get-sent-data
                         message-id
                         group
                         (mail-fetch-field "From")
                         (mail-fetch-field "To")
                         (mail-fetch-field "Subject")
                         (mail-fetch-field "Date")))))

(add-hook 'message-send-hook #'gnus-recent--track-gcc-on-send)
(add-hook 'message-sent-hook #'gnus-recent--track-sent-message)


;; Unsent messages:
(defun gnus-recent--message-buffers ()
  "Return a list of active message buffers.
Like `message-buffers', but actually return buffers, not just names."
  (remove nil
          (mapcar (lambda (buffer)
                    (with-current-buffer buffer
	              (when (and (derived-mode-p 'message-mode)
		                 (null message-sent-message-via))
	                buffer)))
                  (buffer-list t))))

(defun gnus-recent--unsent-articles-list ()
  "Return a formatted list of active message buffers for complection.
The format is like `gnus-recent--articles-list', except first
element is the symbol 'unsent and the second is the buffer."
  (mapcar (lambda (b)
            (with-current-buffer b
              (list (gnus-recent--pretty-unsent)
                    'unsent             ; messageid
                    b                   ; group
                    (message-fetch-field "from")
                    (message-fetch-field "to")
                    (message-fetch-field "subject"))))
          (gnus-recent--message-buffers)))


(defmacro gnus-recent--shift (lst)
  "Put the first element of LST last, then return that element."
  `(let ((top (pop ,lst)))
     (setq ,lst (nconc ,lst (list top)) )
     top))

(defun gnus-recent-goto-previous (&optional no-retry)
  "Go to the top of the recent article list.
Unless NO-RETRY, we try going further back if the top of the
article list is the article we're currently looking at."
  (interactive)
  (let ((gnus-recent--showing-recent t))
    (if (not gnus-recent--articles-list)
        (message "No recent article to show")
      (gnus-recent--action
       (gnus-recent--shift gnus-recent--articles-list)
       (lambda (message-id group _from _to _subject)
         (if (and (not no-retry)
                  (equal (current-buffer) gnus-summary-buffer)
                  (equal message-id (mail-header-id (gnus-summary-article-header))))
             (gnus-recent-goto-previous 'no-retry)
           (gnus-summary-read-group group 1) ; have to show at least one old one
           (gnus-summary-refer-article message-id)))))))

(defun gnus-recent--action (recent func)
  "Find `message-id' and group arguments from RECENT, call FUNC on them.
Warn if RECENT can't be deconstructed as expected."
  (pcase recent
    (`(,_ . (,message-id ,group ,from ,to ,subject . ,_))
     (funcall func message-id group from to subject))
    (_
     (message "Couldn't parse recent message: %S" recent))))

(declare-function org-gnus-follow-link "ol-gnus" (&optional group article))
(defun gnus-recent (recent)
  "Open RECENT gnus article using `org-gnus'."
  (interactive (list (gnus-recent--completing-read)))
  (gnus-recent--action
   recent
   (lambda (message-id group _from _to _subject)
     (let ((gnus-recent--showing-recent t))
       (if (eq message-id 'unsent)
           (switch-to-buffer group)
         (org-gnus-follow-link group message-id))))))

(defalias 'gnus-recent--open-article 'gnus-recent)

(defun gnus-recent--create-org-link (recent)
  "Return an `org-mode' link to RECENT Gnus article."
  (gnus-recent--action
   recent
   (lambda (message-id group from to subject)
     (if (eq message-id 'unsent)
         (error "Not implemented for unsent buffers!")
       (let* ((fromto
               (gnus-recent--name-from-address
                (if (and from
                         to
                         (boundp 'org-from-is-user-regexp)
                         org-from-is-user-regexp
                         (string-match org-from-is-user-regexp from))
                    (concat "to " to)
                  (concat "from " from)))))
         (format "[[gnus:%s#%s][Email %s: %s]]"
                 group
                 (replace-regexp-in-string "^<\\|>$" "" message-id)
                 (replace-regexp-in-string "[][]" "" fromto)
                 (replace-regexp-in-string "[][]" "" subject)))))))

(defun gnus-recent-kill-new-org-link (recent)
  "Add to the `kill-ring' an `org-mode' link to RECENT Gnus article."
  (interactive (list (gnus-recent--completing-read)))
  (kill-new (gnus-recent--create-org-link recent))
  (message "Added org-link to kill-ring"))

(defun gnus-recent-insert-org-link (recent)
  "Insert an `org-mode' link to RECENT Gnus article."
  (interactive (list (gnus-recent--completing-read)))
  (insert (gnus-recent--create-org-link recent)))

(defun gnus-recent--update (recent to-group)
  "Update RECENT Gnus article in `gnus-recent--articles-list'.
The Gnus article has moved to group TO-GROUP."
  (cl-nsubstitute (list (cl-first recent) (cl-second recent) to-group)
                  recent
                  gnus-recent--articles-list
                  :test 'equal :count 1))

(defun gnus-recent-forget (recent &optional print-msg)
  "Remove RECENT Gnus article from `gnus-recent--articles-list'.
When PRINT-MSG is non-nil, show a message about it."
  (interactive (list (gnus-recent--completing-read)))
  (setq gnus-recent--articles-list
        (cl-delete recent gnus-recent--articles-list :test 'equal :count 1))
  (when print-msg
    (message "Removed %s from gnus-recent articles" (car recent))))

(defun gnus-recent-forget-all (&rest _recent)
  "Clear the gnus-recent articles list."
  (interactive)
  (setq gnus-recent--articles-list nil)
  (message "Cleared all gnus-recent article entries"))

(defvar gnus-recent--actions
  (let ((map (make-sparse-keymap)))
    (define-key map "l" #'gnus-recent-insert-org-link)
    (define-key map "c" #'gnus-recent-kill-new-org-link)
    (define-key map "k" #'gnus-recent-forget)
    (define-key map "K" #'gnus-recent-forget-all)
    map))

(defun gnus-recent-embark-minibuffer-hook ()
  "Use as `minibuffer-setup-hook' if using Embark."
  (when (eq this-command 'gnus-recent)
    (setq-local embark-overriding-keymap gnus-recent--actions)))

(defun gnus-recent--completing-read ()
  "Pick an article using `completing-read'."
  (let* ((selectrum-should-sort-p nil)
         (options (append (when gnus-recent-include-unsent
                            (gnus-recent--unsent-articles-list))
                          gnus-recent--articles-list)))
    (when-let ((match (completing-read "Recent article: "
                                       options
                                       nil
                                       'require-match)))
      (assoc match options))))


(provide 'gnus-recent)
;;; gnus-recent.el ends here
