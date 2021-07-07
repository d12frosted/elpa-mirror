;;; org-snooze.el --- Snooze your code, doc and feed -*- lexical-binding: t -*-

;; Copyright (C) 2018 Bill Xue <github.com/xueeinstein>
;; Author: Bill Xue
;; URL: https://github.com/xueeinstein/org-snooze.el
;; Package-Version: 20181229.1424
;; Package-Commit: 8799adc14a20f3489063d279ff69312de3180bf9
;; Created: 2018
;; Version: 0.1
;; Package-Requires: ((emacs "24.4"))
;; Keywords: extensions

;;; Commentary:

;; Inspired by Google Inbox, org-snooze.el lets you
;; snooze code, doc and feed, then alert at desired time.
;; This file is NOT part of GNU Emacs.

;;; Code:
(require 'org-agenda)
(require 'cl-lib)

(defgroup org-snooze nil
  "Extension to snooze your code, doc and feed."
  :group 'org)

(defcustom org-snooze-records-file
  (expand-file-name ".snooze.org" user-emacs-directory)
  "The org file where to store the snoozed items."
  :type 'string
  :group 'org-snooze
  :safe #'stringp)

(defvar org-snooze-records-file-title "Snoozed"
  "The title of org file which stores the snoozed items.")

(defvar org-snooze-search-link-max-length 100
  "The max length of a searchable org link that is parsed from a raw text line.")

;; ===================================
;; Implementation for `org-snooze'
;; ===================================

(defun org-snooze--strip-text-properties (txt)
  "Strip text TXT properties."
  (set-text-properties 0 (length txt) nil txt)
  txt)

(defun org-snooze--trim-special-chars (s)
  "Trim special characters in string S."
  (string-trim s "\\`[^a-zA-Z]+" "[^a-zA-Z]+\\'"))

(defun org-snooze--trim-state-chars (s)
  "Trim state characters in string S.
State characters are: TODO, DONE, NEXT, HOLD, WAITING."
  (let* ((state-list '("TODO" "DONE" "NEXT" "HOLD" "WAITING"))
         (pattern (regexp-opt (mapcar #'(lambda (x) (concat x " ")) state-list))))
    (save-match-data
      (if (string-match pattern s)
          (replace-match "" t t s)
        s))))

(defun org-snooze--parse-line-to-search (line)
  "Parse line content LINE to searchable text.
The length of return searchable link is less than `org-snooze-search-link-max-length'."
  (let* ((min-length (min (length line) org-snooze-search-link-max-length))
         (short-line (cl-subseq line 0 min-length)))
    (format "file:%s::%s" (buffer-file-name)
            (org-link-escape (org-snooze--trim-state-chars
                              (org-snooze--trim-special-chars short-line))))))

(defun org-snooze--refresh-agenda-appt ()
  "Refresh agenda list and appt."
  (org-agenda-list)
  (run-with-timer 2 nil 'org-agenda-redo)
  (org-agenda-to-appt)
  (org-agenda-quit))

(defun org-snooze--add-to-record-file (filename search-link alert-time)
  "Add new snoozed item to record file `org-snooze-records-file'.
The information of an item includes FILENAME, SEARCH-LINK and ALERT-TIME.
The function fist checks whether record file exists and creates one if needed."
  (with-temp-buffer
    (when (file-exists-p org-snooze-records-file)
      (insert-file-contents org-snooze-records-file))
    (org-mode)

    ;; insert title if not find
    (goto-char (point-min))
    (unless (re-search-forward (concat "^\\* " org-snooze-records-file-title) nil t)
      (beginning-of-line)
      (org-insert-heading)
      (insert org-snooze-records-file-title)
      (goto-char (point-min))
      (end-of-line))

    ;; insert new item as a subheading
    (org-insert-todo-subheading t)
    (insert (format "check snoozed %s" filename))
    (org-deadline "" alert-time)
    (insert (format " [[[%s][link]]]" search-link))
    (end-of-line)

    (write-region nil nil org-snooze-records-file)))

(defun org-snooze--elfeed-entry-id-to-search-link (id)
  "Convert elfeed entry ID to searchable org link."
  (format "elfeed:%s#%s" (car id) (cdr id)))

;;;###autoload
(defun org-snooze ()
  "Main function to snooze current line and pick time."
  (interactive)
  (let* ((this-file (buffer-file-name))
         (line (org-snooze--strip-text-properties (thing-at-point 'line)))
         (search (org-snooze--parse-line-to-search line))
         (time (org-read-date)) ;; TODO: support to select quick time, like "early tomorrow"
         (dir (file-name-directory org-snooze-records-file)))

    (unless (file-exists-p dir)
      (make-directory t))

    (when (and (not this-file) (equal major-mode 'elfeed-show-mode))
      ;; it is in elfeed-show buffer where `this-file' is nil
      (message "Log: %s" major-mode)
      (setq this-file (funcall 'elfeed-entry-title
                               (symbol-value 'elfeed-show-entry)))
      (setq search (org-snooze--elfeed-entry-id-to-search-link
                    (funcall 'elfeed-entry-id
                             (symbol-value 'elfeed-show-entry)))))

    (if this-file
        (progn
          ;; add to record file
          (org-snooze--add-to-record-file this-file search time)

          ;; add to agenda files
          (add-to-list 'org-agenda-files org-snooze-records-file)

          ;; update appt-time-msg-list
          (appt-activate 1)
          ;;; "idle" means record file is writen
          (run-with-idle-timer 2 nil 'org-snooze--refresh-agenda-appt)

          ;; notify success
          (message "Snoozed %s to %s" this-file time))
      (message "Current buffer is not supported by org-snooze"))))

;; ===================================
;; Implementation for `org-snooze-pop'
;; ===================================

(defun org-snooze--parse-record-file-ast ()
  "Parse the abstract syntax tree (AST) of the file `org-snooze-records-file'."
  (with-temp-buffer
    (insert-file-contents org-snooze-records-file)
    (org-mode)
    (org-element-parse-buffer)))

(defun org-snooze--parse-time-string (time-string)
  "Parse TIME-STRING to comparable float time."
  (let ((time (date-to-time time-string)))
    (float-time time)))

(defun org-snooze--parse-link (txt)
  "Parse link for TXT."
  (save-match-data
    (if (string-match "\\[[a-zA-Z].*\\]\\[link\\]" txt)
        (cl-subseq (match-string 0 txt) 1 -7))))

(defun org-snooze--get-pop-item-plist (ast)
  "Get information of pop item as plist through parsing AST.
Return a plist in form (:pos HEADLINE-POS :link ORG-LINK :time ALERT-TIME)."
  (let ((time-now (org-snooze--parse-time-string (current-time-string)))
        (most-recent-time 0.0)
        (headlines (cddr ast))
        (headline-id 0)
        (most-recent-id -1)
        (most-recent-item nil)
        (pos nil)
        (link nil)
        (alert-at nil))
    ;; loop to find correct `most-recent-time' and `most-recent-id'
    (dolist (h headlines)
      (when (string-equal (plist-get (cadr h) :todo-keyword) "TODO")
        (let* ((deadline (plist-get (cadr h) :deadline))
               (timestamp (plist-get deadline 'timestamp))
               (time-string (plist-get timestamp :raw-value))
               (time-float (org-snooze--parse-time-string time-string)))
          (if (and (< most-recent-time time-float)
                   (< time-float time-now))
              (progn
                (setq most-recent-time time-float)
                (setq most-recent-id headline-id)))))
      (setq headline-id (+ headline-id 1)))

    ;; get return values
    (when (>= most-recent-id 0)
      (setq most-recent-item (plist-get (nth most-recent-id headlines) 'headline))
      (setq pos (plist-get most-recent-item :begin))
      (setq link (org-snooze--parse-link
                  (plist-get most-recent-item :raw-value)))
      (setq alert-at (format-time-string
                      "%Y-%m-%d %T" (seconds-to-time most-recent-time))))
    (list :pos pos :link link :time alert-at)))

(defun org-snooze--disabled-org-add-log-setup (&optional a b c d e)
  "To disable `org-add-log-setup' with five args: A, B, C, D, E.
These five args respectively correspond to `org-add-log-setup'
five optional args."
  nil)

(defun org-snooze--mark-done (pos)
  "Mark org TODO headline at POS as DONE."
  (with-temp-buffer
    (when (file-exists-p org-snooze-records-file)
      (insert-file-contents org-snooze-records-file))
    (org-mode)
    (goto-char pos)
    (cl-letf (((symbol-function 'org-add-log-setup)
               #'org-snooze--disabled-org-add-log-setup))
      ;; disable executation of `org-add-log-note'
      (org-todo "DONE"))

    (write-region nil nil org-snooze-records-file)))

;;;###autoload
(defun org-snooze-pop ()
  "Main function to pop a snoozed item that Emacs agenda just send notification."
  (interactive)
  (let* ((ast (caddr (org-snooze--parse-record-file-ast)))
         (item-plist (org-snooze--get-pop-item-plist ast))
         (link (plist-get item-plist :link))
         (pos (plist-get item-plist :pos))
         (time (plist-get item-plist :time)))
    (if (not link)
        (message "Cannot find recently alerted snoozed item.")
      (progn
        (org-open-link-from-string link)
        (org-snooze--mark-done pos)
        (message "Pop snoozed item that alerted at %s" time)))))

(provide 'org-snooze)
;;; org-snooze.el ends here
