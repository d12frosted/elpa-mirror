;;; himalaya.el --- Interface for the himalaya email client  -*- lexical-binding: t -*-

;; Copyright (C) 2021 Dante Catalfamo
;; Copyright (C) 2022 soywod <clement.douin@posteo.net>

;; Author: Dante Catalfamo
;;      soywod <clement.douin@posteo.net>
;; Maintainer: Dante Catalfamo
;;      soywod <clement.douin@posteo.net>
;; Version: 0.3
;; Package-Version: 20230531.1417
;; Package-Commit: d1694b760508bc2c3c50945e837b92959c34df31
;; Package-Requires: ((emacs "27.1"))
;; URL: https://github.com/dantecatalfamo/himalaya-emacs
;; Keywords: mail comm

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
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
;; Interface for the himalaya email client
;; https://github.com/soywod/himalaya

;;; Code:

;; TODO: Himalaya query support (https://github.com/dantecatalfamo/himalaya-emacs/issues/4)

(require 'subr-x)
(require 'mailheader)
(require 'message)

(defgroup himalaya nil
  "Options related to the himalaya email client."
  :group 'mail)

(defcustom himalaya-executable "himalaya"
  "Name or location of the himalaya executable."
  :type 'text
  :group 'himalaya)

(defcustom himalaya-email-order nil
  "Order of how emails are displayed on each page of the folder."
  :type '(radio (const :tag "Ascending (oldest first)" t)
                (const :tag "Descending (newest first)" nil))
  :group 'himalaya)

(defcustom himalaya-default-account nil
  "Default account for himalaya, overrides the himalaya config."
  :type '(choice (const :tag "None" nil)
                 (text :tag "String"))
  :group 'himalaya)

(defcustom himalaya-default-folder nil
  "Default folder for himalaya, overrides the himalaya config."
  :type '(choice (const :tag "None" nil)
                 (text :tag "String"))
  :group 'himalaya)

(defcustom himalaya-page-size 100
  "The number of emails to return per folder page."
  :type 'number
  :group 'himalaya)

(defcustom himalaya-id-face font-lock-variable-name-face
  "Font face for himalaya email IDs."
  :type 'face
  :group 'himalaya)

(defcustom himalaya-sender-face font-lock-function-name-face
  "Font face for himalaya sender names."
  :type 'face
  :group 'himalaya)

(defcustom himalaya-date-face font-lock-constant-face
  "Font face for himalaya dates."
  :type 'face
  :group 'himalaya)

(defcustom himalaya-unseen-face font-lock-string-face
  "Font face for unseen email symbol."
  :type 'face
  :group 'himalaya)

(defcustom himalaya-flagged-face font-lock-warning-face
  "Font face for flagged email symbol."
  :type 'face
  :group 'himalaya)

(defcustom himalaya-deleted-face font-lock-keyword-face
  "Font face for deleted email symbol."
  :type 'face
  :group 'himalaya)

(defcustom himalaya-headers-face font-lock-constant-face
  "Font face for headers when reading an email."
  :type 'face
  :group 'himalaya)

(defcustom himalaya-unseen-symbol "●"
  "Symbol to display in the flags column when an email hasn't been
read yet."
  :type 'text
  :group 'himalaya)

(defcustom himalaya-answered-symbol "↵"
  "Symbol to display in the flags column when an email has been
replied to."
  :type 'text
  :group 'himalaya)

(defcustom himalaya-flagged-symbol "⚑"
  "Symbol to display in the flags column when an email has been
flagged."
  :type 'text
  :group 'himalaya)

(defcustom himalaya-deleted-symbol "✘"
  "Symbol to display in the flags column when an email has been
marked for deletion."
  :type 'text
  :group 'himalaya)

(defcustom himalaya-subject-width 70
  "Width of the subject column in the email list."
  :type 'number
  :group 'himalaya)

(defcustom himalaya-from-width 30
  "Width of the from column in the email list."
  :type 'number
  :group 'himalaya)


(defvar himalaya-id nil
  "The current email id.")

(defvar himalaya-reply nil
  "True if the current email is a reply.")

(defvar himalaya-folder nil
  "The current folder.")

(defvar himalaya-account nil
  "The current account.")


(defvar-local himalaya-marked-ids nil
  "The current marked email ids.")

(defvar-local himalaya-subject nil
  "The current email subject.")

(defvar-local himalaya-page 1
  "The current folder page.")

(defun himalaya--run (&rest args)
  "Run himalaya with ARGS.
Results are returned as a string. Signals a Lisp error and
displays the output on non-zero exit."
  (with-temp-buffer
    (let* ((args (flatten-list args))
           (ret (apply #'call-process himalaya-executable nil t nil args))
           (output (buffer-string)))
      (unless (eq ret 0)
        (with-current-buffer-window "*himalaya error*" nil nil
          (insert output))
        (error "Himalaya exited with a non-zero status"))
      output)))

(defun himalaya--run-stdin (input &rest args)
  "Run himalaya with ARGS, sending INPUT as stdin.
Results are returned as a string. Signals a Lisp error and
displays the output on non-zero exit."
  (with-temp-buffer
    (let* ((args (flatten-list args))
           (ret (apply #'call-process-region input nil himalaya-executable nil t nil args))
           (output (buffer-string)))
      (unless (eq ret 0)
        (with-current-buffer-window "*himalaya error*" nil nil
          (insert output))
        (error "Himalaya exited with a non-zero status"))
      output)))

(defun himalaya--run-json (&rest args)
  "Run himalaya with ARGS arguments.
The result is parsed as JSON and returned."
  (let ((args (append '("-o" "json") args)))
    (json-parse-string (himalaya--run args)
                       :object-type 'plist
                       :array-type 'list)))

(defun himalaya--extract-headers (email)
  "Extract email headers from EMAIL."
  (with-temp-buffer
    (insert email)
    (goto-char (point-min))
    (mail-header-extract-no-properties)))

(defun himalaya--prepare-email-write-buffer (buffer)
  "Setup BUFFER to be used to write an email.
Sets the mail function correctly, adds mail header, etc."
  (with-current-buffer buffer
    (goto-char (point-min))
    (search-forward "\n\n")
    (forward-line -1)
    (insert mail-header-separator)
    (forward-line)
    (message-mode)
    (set-buffer-modified-p nil)
    ;; We do a little hacking
    (setq-local message-send-mail-real-function 'himalaya-send-buffer)))

(defun himalaya--folder-list (&optional account)
  "Return a list of folders for ACCOUNT.
If ACCOUNT is nil, the default account is used."
  (himalaya--run-json (when account (list "-a" account)) "folders"))

(defun himalaya--folder-list-names (&optional account)
  "Return a list of folder names for ACCOUNT.
If ACCOUNT is nil, the default account is used."
  (message "Fetching folders…")
  (mapcar (lambda (folder) (plist-get folder :name))
          (himalaya--folder-list account)))

(defun himalaya--folder-expunge (&optional account folder)
  "Delete all emails marked for deletion in FOLDER on ACCOUNT."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "folder"
                      "expunge"))

(defun himalaya--email-list (&optional account folder page)
  "Return a list of emails from ACCOUNT in FOLDER.
Paginate using PAGE of PAGE-SIZE.
If ACCOUNT, FOLDER, or PAGE are nil, the default values are used."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "list"
                      (when page (list "-p" (format "%s" page)))
                      (when himalaya-page-size (list "-s" (prin1-to-string himalaya-page-size)))))

(defun himalaya--email-read (id &optional account folder raw html)
  "Return the contents of email with ID from FOLDER on ACCOUNT.
If ACCOUNT or FOLDER are nil, use the defaults. If RAW is
non-nil, return the raw contents of the email including headers.
If HTML is non-nil, return the HTML version of the email,
otherwise return the plain text version."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "read"
                      (format "%s" id) ; Ensure id is a string
                      (when raw "-r")
                      (when html (list "-t" "html"))
                      (list "-H" "From" "-H" "To" "-H" "Cc" "-H" "Bcc" "-H" "Subject" "-H" "Date")))

(defun himalaya--email-copy (target ids &optional account folder)
  "Copy email with ID from FOLDER to TARGET folder on ACCOUNT.
If ACCOUNT or FOLDER are nil, use the defaults."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "copy"
                      target
                      ids))

(defun himalaya--email-move (target ids &optional account folder)
  "Move email with ID from FOLDER to TARGET folder on ACCOUNT.
If ACCOUNT or FOLDER are nil, use the defaults."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "move"
                      target
                      ids))

(defun himalaya--email-delete (ids &optional account folder)
  "Delete emails with IDS from FOLDER on ACCOUNT.
If ACCOUNT or FOLDER are nil, use the defaults.
IDS is a list of numbers."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "delete"
                      ids))

(defun himalaya--email-attachments (ids &optional account folder)
  "Download attachments from email with ID.
If ACCOUNT or FOLDER are nil, use the defaults."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "attachments"
                      ids))

(defun himalaya--account-sync (&optional account folder)
  "Synchronize the given account.
If ACCOUNT is nil, use the defaults. If FOLDER is nil, sync all
the folders."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "accounts"
                      "sync"))

(defun himalaya--template-new (&optional account)
  "Return a template for a new email from ACCOUNT."
  (himalaya--run-json (when account (list "-a" account))
                      "template"
                      "new"))

(defun himalaya--template-reply (id &optional account folder reply-all)
  "Return a reply template for email with ID from FOLDER on ACCOUNT.
If ACCOUNT or FOLDER are nil, use the defaults.
If REPLY-ALL is non-nil, the template will be generated as a reply all email."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "template"
                      "reply"
                      (when reply-all "-A")
                      (format "%s" id)))

(defun himalaya--template-forward (id &optional account folder)
  "Return a forward template for email with ID from FOLDER on ACCOUNT.
If ACCOUNT or FOLDER are nil, use the defaults."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "template"
                      "forward"
                      (format "%s" id)))

;; TODO: Connect this to a key
(defun himalaya--save (email &optional account folder)
  "Save EMAIL to FOLDER on ACCOUNT.
If ACCOUNT or FOLDER are nil, the defaults are used."
  (himalaya--run-stdin email
                       (when account (list "-a" account))
                       (when folder (list "-f" folder))
                       "save"))

(defun himalaya--send (email &optional account)
  "Send EMAIL using ACCOUNT."
  (himalaya--run-stdin email
                       (when account (list "-a" account))
                       "send"))

(defun himalaya--add-flags (id flags &optional account folder)
  "Add FLAGS to email ID."
  (himalaya--run-json (when account (list "-a" account))
                      (when folder (list "-f" folder))
                      "flags"
                      "add"
                      id
                      "--"
                      flags))

(defun himalaya-send-buffer (&rest _)
  "Send the current buffer as an email through himalaya.
Processes the buffer to replace \n with \r\n and removes `mail-header-separator'."
  (interactive)
  (let* ((buf-string (substring-no-properties (buffer-string)))
         (no-sep (replace-regexp-in-string mail-header-separator "" buf-string))
         (email (replace-regexp-in-string "\r?\n" "\r\n" no-sep)))
    (himalaya--send email himalaya-account)
    (when himalaya-reply (himalaya--add-flags himalaya-id "Answered" himalaya-account himalaya-folder))))

(defun himalaya--email-flag-symbols (flags)
  "Generate a display string for FLAGS."
  (concat
   (if (member "Seen" flags) " " (propertize himalaya-unseen-symbol 'face himalaya-unseen-face))
   (if (member "Answered" flags) himalaya-answered-symbol " ")
   (if (member "Flagged" flags) (propertize himalaya-flagged-symbol 'face himalaya-flagged-face) " ")
   (if (member "Deleted" flags) (propertize himalaya-deleted-symbol 'face himalaya-deleted-face) " ")))

(defun himalaya--email-list-build-table ()
  "Construct the email list table."
  (when (consp current-prefix-arg)
    (setq himalaya-page 1)
    (goto-char (point-min)))
  (let ((emails (himalaya--email-list himalaya-account himalaya-folder himalaya-page)) entries)
    (dolist (email emails entries)
      (push (list (plist-get email :id)
                  (vector
                   (propertize (plist-get email :id) 'face himalaya-id-face)
                   (himalaya--email-flag-symbols (plist-get email :flags))
                   (plist-get email :subject)
                   (himalaya--email-list-build-table-sender-column email)
                   (propertize (plist-get email :date) 'face himalaya-date-face)))
            entries))
    (if himalaya-email-order
        entries
      (nreverse entries))))

(defun himalaya--email-list-build-table-sender-column (email)
  "Construct the sender"
  (let* ((from (plist-get email :from))
         (name (plist-get from :name))
         (addr (plist-get from :addr)))
    (propertize (if (eq name :null) addr name) 'face himalaya-sender-face)))

;;;###autoload
(defun himalaya-email-list (&optional account folder page)
  "List emails in FOLDER on ACCOUNT."
  (interactive)
  (setq account (or account himalaya-default-account))
  (setq folder (or folder himalaya-default-folder))
  (switch-to-buffer (concat "*Himalaya Folder"
                            (when (or account folder) ": ")
                            account
                            (and account folder "/")
                            folder
                            "*"))

  (himalaya-email-list-mode)
  (setq himalaya-folder folder)
  (setq himalaya-account account)
  (setq himalaya-page (or page himalaya-page))
  (setq mode-line-process (format " [Page %s]" himalaya-page))
  (revert-buffer))

(defun himalaya--save-face-property (beg end)
  ;; We need to distinguish ,,not set'' from ''no face''.
  (unless (and (text-property-not-all beg end 'face nil) (< beg end))
    (put-text-property beg (1+ beg) 'face 'default))
  (unless (text-property-not-all beg end 'himalaya-saved-face nil)
    (himalaya--copy-text-property beg end 'face 'himalaya-saved-face)))

(defun himalaya--restore-face-property (beg end)
  (when (text-property-not-all beg end 'himalaya-saved-face nil)
    (himalaya--copy-text-property beg end 'himalaya-saved-face 'face)))

(defun himalaya--copy-text-property (beg end from to)
  "Copy text property FROM to TO in region BEG to END."
  (let ((inhibit-read-only t))
    (save-excursion
      (while (< beg end)
        (goto-char beg)
        (put-text-property
         (point)
         (setq beg (next-single-property-change (point) from nil end))
         to
         (get-text-property (point) from))))))

;;;###autoload
(defalias 'himalaya #'himalaya-email-list)

(defun himalaya-mark-forward ()
  "Mark the email at point and move the cursor to the next line."
  (interactive)
  (save-excursion
    (let ((inhibit-read-only t))
      (add-to-list 'himalaya-marked-ids (tabulated-list-get-id))
      (tabulated-list-put-tag (string dired-marker-char))
      (himalaya--save-face-property (point-at-bol) (point-at-eol))
      (put-text-property (point-at-bol) (point-at-eol) 'face 'dired-marked)))
  (next-line)
  (goto-char (point-at-bol)))

(defun himalaya-unmark-backward ()
  "Unmark the email at point and move the cursor to the previous
line."
  (interactive)
  (previous-line)
  (goto-char (point-at-bol))
  (let ((inhibit-read-only t))
    (setq himalaya-marked-ids (remove (tabulated-list-get-id) himalaya-marked-ids))
    (tabulated-list-put-tag "")
    (himalaya--restore-face-property (point-at-bol) (point-at-eol))))

(defun himalaya-unmark-forward ()
  "Unmark the email at point and move the cursor to the next line."
  (interactive)
  (let ((inhibit-read-only t))
    (setq himalaya-marked-ids (remove (tabulated-list-get-id) himalaya-marked-ids))
    (tabulated-list-put-tag "")
    (himalaya--restore-face-property (point-at-bol) (point-at-eol)))
  (next-line)
  (goto-char (point-at-bol)))

(defun himalaya-unmark-all (&optional quiet)
  "Unmark all marked emails."
  (interactive)
  (when himalaya-marked-ids    
    (save-excursion
      (let ((inhibit-read-only t))
        (goto-char (point-min))
        (while (re-search-forward (format "^[%s]" (string dired-marker-char)) nil t)
          (himalaya--restore-face-property (point-at-bol) (point-at-eol)))
        (tabulated-list-clear-all-tags)))
    (unless quiet (message "%d marks removed" (length himalaya-marked-ids)))
    (setq himalaya-marked-ids nil)))

(defun himalaya-switch-folder (folder)
  "Switch to FOLDER on the current email account."
  (interactive (list (completing-read "Folder: " (himalaya--folder-list-names himalaya-account))))
  (himalaya-email-list himalaya-account folder))

(defun himalaya-email-read (id &optional account folder)
  "Display email ID from FOLDER on ACCOUNT.
If ACCOUNT or FOLDER are nil, use the defaults."
  (let* ((email (replace-regexp-in-string "" "" (himalaya--email-read id account folder)))
         (headers (himalaya--extract-headers email)))
    (switch-to-buffer (format "*%s*" (alist-get 'subject headers)))
    (erase-buffer)
    (insert email)
    (set-buffer-modified-p nil)
    (himalaya-email-read-mode)
    (goto-char (point-min))
    (setq buffer-read-only t)
    (setq himalaya-account account)
    (setq himalaya-folder folder)
    (setq himalaya-id id)
    (setq himalaya-subject (alist-get 'subject headers))))

(defun himalaya-email-read-raw (id &optional account folder)
  "Display raw email ID from FOLDER on ACCOUNT.
If ACCOUNT or FOLDER are nil, use the defaults."
  (let* ((email-raw (replace-regexp-in-string "" "" (himalaya--email-read id account folder 'raw)))
         (headers (himalaya--extract-headers email-raw)))
    (switch-to-buffer (format "*Raw: %s*" (alist-get 'subject headers)))
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert email-raw)
      (set-buffer-modified-p nil))
    (himalaya-email-read-raw-mode)
    (setq himalaya-account account)
    (setq himalaya-folder folder)
    (setq himalaya-id id)))

(defun himalaya-email-read-switch-raw ()
  "Read a raw version of the current email."
  (interactive)
  (let ((buf (current-buffer)))
    (himalaya-email-read-raw himalaya-id himalaya-account himalaya-folder)
    (kill-buffer buf)))

(defun himalaya-email-read-switch-plain ()
  "Read a plain version of the current email."
  (interactive)
  (let ((buf (current-buffer)))
    (himalaya-email-read himalaya-id himalaya-account himalaya-folder)
    (kill-buffer buf)))

(defun himalaya-email-read-download-attachments ()
  "Download all attachments of current email."
  (interactive)
  (message "Fetching attachments…")
  (message "%s" (himalaya--email-attachments (list himalaya-id) himalaya-account himalaya-folder)))

(defun himalaya-email-read-reply (&optional reply-all)
  "Open a new buffer with a reply template to the current email.
If called with \\[universal-argument], email will be REPLY-ALL."
  (interactive "P")
  (let ((template (himalaya--template-reply himalaya-id himalaya-account himalaya-folder reply-all)))
    (setq himalaya-reply t)
    (switch-to-buffer (generate-new-buffer (format "*Reply: %s*" himalaya-subject)))
    (insert template)
    (set-buffer-modified-p nil)
    (himalaya--prepare-email-write-buffer (current-buffer))))

(defun himalaya-email-read-forward ()
  "Open a new buffer with a forward template to the current email."
  (interactive)
  (let ((template (himalaya--template-forward himalaya-id himalaya-account himalaya-folder)))
    (setq himalaya-reply nil)
    (switch-to-buffer (generate-new-buffer (format "*Forward: %s*" himalaya-subject)))
    (insert template)
    (set-buffer-modified-p nil)
    (himalaya--prepare-email-write-buffer (current-buffer))))

(defun himalaya-email-write ()
  "Open a new bugger for writing an email."
  (interactive)
  (let ((template (himalaya--template-new himalaya-account)))
    (setq himalaya-reply nil)
    (switch-to-buffer (generate-new-buffer "*Himalaya New Email*"))
    (insert template)
    (set-buffer-modified-p nil)
    (himalaya--prepare-email-write-buffer (current-buffer))))

(defun himalaya-email-reply (&optional reply-all)
  "Reply to the email at point.
If called with \\[universal-argument], email will be REPLY-ALL."
  (interactive "P")
  (let* ((email (tabulated-list-get-entry))
         (id (substring-no-properties (elt email 0)))
         (subject (substring-no-properties (elt email 2))))
    (setq himalaya-id id)
    (setq himalaya-subject subject)
    (himalaya-email-read-reply reply-all)))

(defun himalaya-email-forward ()
  "Forward the email at point."
  (interactive)
  (let* ((email (tabulated-list-get-entry))
         (id (substring-no-properties (elt email 0)))
         (subject (substring-no-properties (elt email 2))))
    (setq himalaya-id id)
    (setq himalaya-subject subject)
    (himalaya-email-read-forward)))

(defun himalaya-account-sync (&optional sync-all)
  "Synchronize the current folder of the current account. If
called with \\[universal-argument], SYNC-ALL folders."
  (interactive "P")
  (message "Synchronizing account…")
  (message "%s" (himalaya--account-sync himalaya-account (if sync-all nil himalaya-folder)))
  (himalaya-email-list himalaya-account himalaya-folder himalaya-page))

(defun himalaya-email-select ()
  "Read the email at point."
  (interactive)
  (let* ((email (tabulated-list-get-entry))
         (id (substring-no-properties (elt email 0))))
    (himalaya-email-read id himalaya-account himalaya-folder)))

(defun himalaya-email-download-attachments ()
  "Download marked emails attachments (or the email at point if no
mark exist)."
  (interactive)
  (message "Fetching attachments…")
  (if (not himalaya-marked-ids)
      (message "%s" (himalaya--email-attachments (list (tabulated-list-get-id)) himalaya-account himalaya-folder))
    (message "%s" (himalaya--email-attachments himalaya-marked-ids himalaya-account himalaya-folder))
    (himalaya-unmark-all t)))

(defun himalaya-email-copy (target)
  "Copy marked emails (or the email at point if no mark exist) to
TARGET folder."
  (interactive (list (completing-read "Copy to folder: " (himalaya--folder-list-names himalaya-account))))
  (if (not himalaya-marked-ids)
      (message "%s" (himalaya--email-copy target (list (tabulated-list-get-id)) himalaya-account himalaya-folder))
    (message "%s" (himalaya--email-copy target himalaya-marked-ids himalaya-account himalaya-folder)))
  (himalaya-unmark-all t)
  (revert-buffer t t t))

(defun himalaya-email-move (target)
  "Move marked emails (or the email at point if no mark exist) to
TARGET folder."
  (interactive (list (completing-read "Move to folder: " (himalaya--folder-list-names himalaya-account))))
  (if (not himalaya-marked-ids)
      (message "%s" (himalaya--email-move target (list (tabulated-list-get-id)) himalaya-account himalaya-folder))
    (message "%s" (himalaya--email-move target himalaya-marked-ids himalaya-account himalaya-folder)))
  (himalaya-unmark-all t)
  (revert-buffer t t t))

(defun himalaya-email-delete ()
  "Delete marked emails (or the email at point if no mark
exist)."
  (interactive)
  (let* ((email (tabulated-list-get-entry))
         (id (tabulated-list-get-id))
         (subject (substring-no-properties (elt email 2))))
    (if himalaya-marked-ids
        (when (y-or-n-p (format "Delete emails %s? " (string-join himalaya-marked-ids ", ")))
          (message "%s" (himalaya--email-delete himalaya-marked-ids himalaya-account himalaya-folder))
          (himalaya-unmark-all t)
          (revert-buffer t t t))
      (when (y-or-n-p (format "Delete email %s? " subject))
        (message "%s" (himalaya--email-delete (list id) himalaya-account himalaya-folder))
        (himalaya-unmark-all t)
        (revert-buffer t t t)))))

(defun himalaya-folder-expunge ()
  "Delete all emails marked for deletion."
  (interactive)
  (when (y-or-n-p (format "Expunge folder %s? " himalaya-folder))
    (message "%s" (himalaya--folder-expunge himalaya-account himalaya-folder))
    (revert-buffer t t t)))

(defun himalaya-forward-page ()
  "Go to the next page of the current folder."
  (interactive)
  (himalaya-email-list himalaya-account himalaya-folder (1+ himalaya-page)))

(defun himalaya-backward-page ()
  "Go to the previous page of the current folder."
  (interactive)
  (himalaya-email-list himalaya-account himalaya-folder (max 1 (1- himalaya-page))))

(defun himalaya-jump-to-page (page)
  "Jump to PAGE of current folder."
  (interactive "nJump to page: ")
  (himalaya-email-list himalaya-account himalaya-folder (max 1 page)))

(defun himalaya-next-email ()
  "Go to the next email."
  (interactive)
  (condition-case nil
      (himalaya-email-read (prin1-to-string (1+ (string-to-number himalaya-id)))
                           himalaya-account
                           himalaya-folder)
    (t (user-error "At end of folder"))))

(defun himalaya-previous-email ()
  "Go to the previous email."
  (interactive)
  (when (string= himalaya-id "1")
    (user-error "At beginning of folder"))
  (himalaya-email-read (prin1-to-string (max 1 (1- (string-to-number himalaya-id))))
                       himalaya-account
                       himalaya-folder))

(defvar himalaya-email-list-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Marks
    (define-key map (kbd "DEL") #'himalaya-unmark-backward)
    (define-key map (kbd "u") #'himalaya-unmark-forward)
    (define-key map (kbd "U") #'himalaya-unmark-all)
    (define-key map (kbd "m") #'himalaya-mark-forward)
    
    (define-key map (kbd "C-c f") #'himalaya-switch-folder)
    (define-key map (kbd "RET") #'himalaya-email-select)
    (define-key map (kbd "f") #'himalaya-forward-page)
    (define-key map (kbd "b") #'himalaya-backward-page)
    (define-key map (kbd "j") #'himalaya-jump-to-page)
    (define-key map (kbd "a") #'himalaya-email-download-attachments)
    (define-key map (kbd "C") #'himalaya-email-copy)
    (define-key map (kbd "M") #'himalaya-email-move)
    (define-key map (kbd "D") #'himalaya-email-delete)
    (define-key map (kbd "w") #'himalaya-email-write)
    (define-key map (kbd "R") #'himalaya-email-reply)
    (define-key map (kbd "F") #'himalaya-email-forward)
    (define-key map (kbd "s") #'himalaya-account-sync)
    (define-key map (kbd "e") #'himalaya-folder-expunge)
    map))

(define-derived-mode himalaya-email-list-mode tabulated-list-mode "Himalaya-Emails"
  "Himalaya email client email list mode."
  (setq tabulated-list-format (vector
                               '("ID" 5 nil :right-align t)
                               '("Flags" 6 nil)
                               (list "Subject" himalaya-subject-width nil)
                               (list "From" himalaya-from-width nil)
                               '("Date" 19 nil)))
  (setq tabulated-list-sort-key nil)
  (setq tabulated-list-entries #'himalaya--email-list-build-table)
  (setq tabulated-list-padding 1)
  (tabulated-list-init-header)
  (hl-line-mode))

(defvar himalaya-email-read-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "a") #'himalaya-email-read-download-attachments)
    (define-key map (kbd "R") #'himalaya-email-read-switch-raw)
    (define-key map (kbd "r") #'himalaya-email-read-reply)
    (define-key map (kbd "f") #'himalaya-email-read-forward)
    (define-key map (kbd "q") #'kill-current-buffer)
    (define-key map (kbd "n") #'himalaya-next-email)
    (define-key map (kbd "p") #'himalaya-previous-email)
    map))

(define-derived-mode himalaya-email-read-mode message-mode "Himalaya-Read"
  "Himalaya email client email reading mode.")

(defvar himalaya-email-read-raw-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "a") #'himalaya-email-read-download-attachments)
    (define-key map (kbd "R") #'himalaya-email-read-switch-plain)
    (define-key map (kbd "r") #'himalaya-email-read-reply)
    (define-key map (kbd "f") #'himalaya-email-read-forward)
    (define-key map (kbd "q") #'kill-current-buffer)
    (define-key map (kbd "n") #'himalaya-next-email)
    (define-key map (kbd "p") #'himalaya-previous-email)
    map))

(define-derived-mode himalaya-email-read-raw-mode message-mode "Himalaya-Read-Raw"
  "Himalaya email client raw email mode.")

(provide 'himalaya)
;;; himalaya.el ends here
