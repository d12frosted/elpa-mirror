;;; himalaya.el --- Interface for the himalaya email client  -*- lexical-binding: t -*-

;; Copyright (C) 2021 Dante Catalfamo

;; Author: Dante Catalfamo
;; Version: 0.1
;; Package-Version: 20221007.1816
;; Package-Commit: 1735b55e4dd60c63fe3900e959655f1f8b961590
;; Package-Requires: ((emacs "27.1"))
;; URL: https://github.com/dantecatalfamo/himalaya-emacs

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

;; TODO: See `tablist-put-mark' as reference for tagging messages.
;; `package-menu-mark-install' and `package-menu-execute' are also good.
;; TODO: Himalaya query support

(require 'subr-x)
(require 'mailheader)
(require 'message)

(defgroup himalaya nil
  "Options related to the himalaya mail client."
  :group 'mail)

(defcustom himalaya-executable "himalaya"
  "Name or location of the himalaya executable."
  :type 'text
  :group 'himalaya)

(defcustom himalaya-message-order nil
  "Order of how messages are displayed on each page of the mailbox."
  :type '(radio (const :tag "Ascending (oldest first)" t)
                (const :tag "Descending (newest first)" nil))
  :group 'himalaya)

(defcustom himalaya-default-account nil
  "Default account for himalaya, overrides the himalaya config."
  :type '(choice (const :tag "None" nil)
                 (text :tag "String"))
  :group 'himalaya)

(defcustom himalaya-default-mailbox nil
  "Default mailbox for himalaya, overrides the himalaya config."
  :type '(choice (const :tag "None" nil)
                (text :tag "String"))
  :group 'himalaya)

(defcustom himalaya-page-size 100
  "The number of emails to return per mailbox page."
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
  "Font face for unseen message symbol."
  :type 'face
  :group 'himalaya)

(defcustom himalaya-flagged-face font-lock-warning-face
  "Font face for flagged message symbol."
  :type 'face
  :group 'himalaya)

(defcustom himalaya-headers-face font-lock-constant-face
  "Font face for headers when reading a message."
  :type 'face
  :group 'himalaya)

(defcustom himalaya-unseen-symbol "●"
  "Symbol to display in the flags column when a message hasn't been read yet."
  :type 'text
  :group 'himalaya)

(defcustom himalaya-answered-symbol "↵"
  "Symbol to display in the flags column when a message has been replied to."
  :type 'text
  :group 'himalaya)

(defcustom himalaya-flagged-symbol "⚑"
  "Symbol to display in the flags column when a message has been flagged."
  :type 'text
  :group 'himalaya)

(defcustom himalaya-subject-width 70
  "Width of the subject column in the message list."
  :type 'number
  :group 'himalaya)

(defcustom himalaya-from-width 30
  "Width of the from column in the message list."
  :type 'number
  :group 'himalaya)


(defvar-local himalaya-mailbox nil
  "The current mailbox.")

(defvar-local himalaya-account nil
  "The current account.")

(defvar-local himalaya-uid nil
  "The current message uid.")

(defvar-local himalaya-subject nil
  "The current message subject.")

(defvar-local himalaya-page 1
  "The current mailbox page.")

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
    ;; Remove { "response": [...] } wrapper
    (cadr (json-parse-string (himalaya--run args)
                             :object-type 'plist
                             :array-type 'list))))

(defun himalaya--extract-headers (message)
  "Extract email headers from MESSAGE."
  (with-temp-buffer
    (insert message)
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
    ;; We do a little hacking
    (setq-local message-send-mail-real-function 'himalaya-send-buffer)))

(defun himalaya--mailbox-list (&optional account)
  "Return a list of mailboxes for ACCOUNT.
If ACCOUNT is nil, the default account is used."
  (himalaya--run-json (when account (list "-a" account)) "mailboxes"))

(defun himalaya--mailbox-list-names (&optional account)
  "Return a list of mailbox names for ACCOUNT.
If ACCOUNT is nil, the default account is used."
  (mapcar (lambda (mbox) (plist-get mbox :name))
          (himalaya--mailbox-list account)))

(defun himalaya--message-list (&optional account mailbox page)
  "Return a list of emails from ACCOUNT in MAILBOX.
Paginate using PAGE of PAGE-SIZE.
If ACCOUNT, MAILBOX, or PAGE are nil, the default values are used."
  (himalaya--run-json (when account (list "-a" account))
                      (when mailbox (list "-m" mailbox))
                      "list"
                      (when page (list "-p" (format "%s" page)))
                      (when himalaya-page-size (list "-s" (prin1-to-string himalaya-page-size)))))

(defun himalaya--message-read (uid &optional account mailbox raw html)
  "Return the contents of message with UID from MAILBOX on ACCOUNT.
If ACCOUNT or MAILBOX are nil, use the defaults. If RAW is
non-nil, return the raw contents of the email including headers.
If HTML is non-nil, return the HTML version of the email,
otherwise return the plain text version."
  (himalaya--run-json (when account (list "-a" account))
		      (when mailbox (list "-m" mailbox))
		      "read"
		      (format "%s" uid) ; Ensure uid is a string
		      (when raw "-r")
		      (when html (list "-t" "html"))
		      (list "-h" "from" "to" "cc" "bcc" "subject" "date")))

(defun himalaya--message-copy (uid target &optional account mailbox)
  "Copy message with UID from MAILBOX to TARGET mailbox on ACCOUNT.
If ACCOUNT or MAILBOX are nil, use the defaults."
  (himalaya--run-json (when account (list "-a" account))
                      (when mailbox (list "-m" mailbox))
                      "copy"
                      (format "%s" uid)
                      target))

(defun himalaya--message-move (uid target &optional account mailbox)
  "Move message with UID from MAILBOX to TARGET mailbox on ACCOUNT.
If ACCOUNT or MAILBOX are nil, use the defaults."
  (himalaya--run-json (when account (list "-a" account))
                      (when mailbox (list "-m" mailbox))
                      "move"
                      (format "%s" uid)
                      target))

(defun himalaya--message-delete (uids &optional account mailbox)
  "Delete messages with UIDS from MAILBOX on ACCOUNT.
If ACCOUNT or MAILBOX are nil, use the defaults.
UIDS is a list of numbers."
  (himalaya--run-json (when account (list "-a" account))
                      (when mailbox (list "-m" mailbox))
                      "delete"
                      (mapconcat (lambda (uid) (format "%s" uid)) uids ",")))

(defun himalaya--message-attachments (uid &optional account mailbox)
  "Download attachments from message with UID.
If ACCOUNT or MAILBOX are nil, use the defaults."
  (himalaya--run-json (when account (list "-a" account))
                      (when mailbox (list "-m" mailbox))
                      "attachments"
                      (format "%s" uid)))

(defun himalaya--template-new (&optional account)
  "Return a template for a new message from ACCOUNT."
  (himalaya--run-json (when account (list "-a" account))
                      "template"
                      "new"))

(defun himalaya--template-reply (uid &optional account mailbox reply-all)
  "Return a reply template for message with UID from MAILBOX on ACCOUNT.
If ACCOUNT or MAILBOX are nil, use the defaults.
If REPLY-ALL is non-nil, the template will be generated as a reply all message."
  (himalaya--run-json (when account (list "-a" account))
                      (when mailbox (list "-m" mailbox))
                      "template"
                      "reply"
                      (when reply-all "--all")
                      (format "%s" uid)))

(defun himalaya--template-forward (uid &optional account mailbox)
  "Return a forward template for message with UID from MAILBOX on ACCOUNT.
If ACCOUNT or MAILBOX are nil, use the defaults."
  (himalaya--run-json (when account (list "-a" account))
                      (when mailbox (list "-m" mailbox))
                      "template"
                      "forward"
                      (format "%s" uid)))

;; TODO: Connect this to a key
(defun himalaya--save (message &optional account mailbox)
  "Save MESSAGE to MAILBOX on ACCOUNT.
If ACCOUNT or MAILBOX are nil, the defaults are used."
  (himalaya--run-stdin message
                       (when account (list "-a" account))
                       (when mailbox (list "-m" mailbox))
                       "save"))

(defun himalaya--send (message &optional account)
  "Send MESSAGE using ACCOUNT."
  (himalaya--run-stdin message
                       (when account (list "-a" account))
                       "send"))

(defun himalaya-send-buffer (&rest _)
  "Send the current buffer as an email through himalaya.
Processes the buffer to replace \n with \r\n and removes `mail-header-separator'."
  (interactive)
  (let* ((buf-string (substring-no-properties (buffer-string)))
         (no-sep (replace-regexp-in-string mail-header-separator "" buf-string))
         (email (replace-regexp-in-string "\r?\n" "\r\n" no-sep)))
    (himalaya--send email himalaya-account)))

(defun himalaya--message-flag-symbols (flags)
  "Generate a display string for FLAGS."
  (concat
   (if (member "Seen" flags) " " (propertize himalaya-unseen-symbol 'face himalaya-unseen-face))
   (if (member "Answered" flags) himalaya-answered-symbol " ")
   (if (member "Flagged" flags) (propertize himalaya-flagged-symbol 'face himalaya-flagged-face) " ")))

(defun himalaya--message-list-build-table ()
  "Construct the message list table."
  (let ((messages (himalaya--message-list himalaya-account himalaya-mailbox himalaya-page))
        entries)
    (dolist (message messages entries)
      (push (list (plist-get message :id)
                  (vector
                   (propertize (prin1-to-string (plist-get message :id)) 'face himalaya-id-face)
                   (himalaya--message-flag-symbols (plist-get message :flags))
                   (plist-get message :subject)
                   (propertize (plist-get message :sender) 'face himalaya-sender-face)
                   (propertize (plist-get message :date) 'face himalaya-date-face)))
            entries))
    (if himalaya-message-order
        entries
      (nreverse entries))))

;;;###autoload
(defun himalaya-message-list (&optional account mailbox page)
  "List messages in MAILBOX on ACCOUNT."
  (interactive)
  (setq account (or account himalaya-default-account))
  (setq mailbox (or mailbox himalaya-default-mailbox))
  (switch-to-buffer (concat "*Himalaya Mailbox"
                            (when (or account mailbox) ": ")
                            account
                            (and account mailbox "/")
                            mailbox
                            "*"))

  (himalaya-message-list-mode)
  (setq himalaya-mailbox mailbox)
  (setq himalaya-account account)
  (setq himalaya-page (or page himalaya-page))
  (setq mode-line-process (format " [Page %s]" himalaya-page))
  (revert-buffer))

;;;###autoload
(defalias 'himalaya #'himalaya-message-list)

(defun himalaya-switch-mailbox (mailbox)
  "Switch to MAILBOX on the current email account."
  (interactive (list (completing-read "Mailbox: " (himalaya--mailbox-list-names himalaya-account))))
  (himalaya-message-list himalaya-account mailbox))

(defun himalaya-message-read (uid &optional account mailbox)
  "Display message UID from MAILBOX on ACCOUNT.
If ACCOUNT or MAILBOX are nil, use the defaults."
  (let* ((message (replace-regexp-in-string "" "" (himalaya--message-read uid account mailbox)))
         (headers (himalaya--extract-headers message)))
    (switch-to-buffer (format "*%s*" (alist-get 'subject headers)))
    (erase-buffer)
    (insert message)
    (set-buffer-modified-p nil)
    (himalaya-message-read-mode)
    (goto-char (point-min))
    (setq buffer-read-only t)
    (setq himalaya-account account)
    (setq himalaya-mailbox mailbox)
    (setq himalaya-uid uid)
    (setq himalaya-subject (alist-get 'subject headers))))

(defun himalaya-message-read-raw (uid &optional account mailbox)
  "Display raw message UID from MAILBOX on ACCOUNT.
If ACCOUNT or MAILBOX are nil, use the defaults."
  (let* ((message-raw (replace-regexp-in-string "" "" (himalaya--message-read uid account mailbox 'raw)))
         (headers (himalaya--extract-headers message-raw)))
    (switch-to-buffer (format "*Raw: %s*" (alist-get 'subject headers)))
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert message-raw)
      (set-buffer-modified-p nil))
    (himalaya-message-read-raw-mode)
    (setq himalaya-account account)
    (setq himalaya-mailbox mailbox)
    (setq himalaya-uid uid)))

(defun himalaya-message-read-switch-raw ()
  "Read a raw version of the current message."
  (interactive)
  (let ((buf (current-buffer)))
    (himalaya-message-read-raw himalaya-uid himalaya-account himalaya-mailbox)
    (kill-buffer buf)))

(defun himalaya-message-read-switch-plain ()
  "Read a plain version of the current message."
  (interactive)
  (let ((buf (current-buffer)))
    (himalaya-message-read himalaya-uid himalaya-account himalaya-mailbox)
    (kill-buffer buf)))

(defun himalaya-message-read-download-attachments ()
  "Download any attachments on the current email."
  (interactive)
  (message (himalaya--message-attachments himalaya-uid himalaya-account himalaya-mailbox)))

(defun himalaya-message-read-reply (&optional reply-all)
  "Open a new buffer with a reply template to the current message.
If called with \\[universal-argument], message will be REPLY-ALL."
  (interactive "P")
  (let ((template (himalaya--template-reply himalaya-uid himalaya-account himalaya-mailbox reply-all)))
    (switch-to-buffer (generate-new-buffer (format "*Reply: %s*" himalaya-subject)))
    (insert template)
    (himalaya--prepare-email-write-buffer (current-buffer))))

(defun himalaya-message-read-forward ()
  "Open a new buffer with a forward template to the current message."
  (interactive)
  (let ((template (himalaya--template-forward himalaya-uid himalaya-account himalaya-mailbox)))
    (switch-to-buffer (generate-new-buffer (format "*Forward: %s*" himalaya-subject)))
    (insert template)
    (himalaya--prepare-email-write-buffer (current-buffer))))

(defun himalaya-message-write ()
  "Open a new bugger for writing a message."
  (interactive)
  (let ((template (himalaya--template-new himalaya-account)))
    (switch-to-buffer (generate-new-buffer "*Himalaya New Message*"))
    (insert template))
  (himalaya--prepare-email-write-buffer (current-buffer)))

(defun himalaya-message-reply (&optional reply-all)
  "Reply to the message at point.
If called with \\[universal-argument], message will be REPLY-ALL."
  (interactive "P")
  (let* ((message (tabulated-list-get-entry))
         (uid (substring-no-properties (elt message 0)))
         (subject (substring-no-properties (elt message 2))))
    (setq himalaya-uid uid)
    (setq himalaya-subject subject)
    (himalaya-message-read-reply reply-all)))

(defun himalaya-message-forward ()
  "Forward the message at point."
  (interactive)
  (let* ((message (tabulated-list-get-entry))
         (uid (substring-no-properties (elt message 0)))
         (subject (substring-no-properties (elt message 2))))
    (setq himalaya-uid uid)
    (setq himalaya-subject subject)
    (himalaya-message-read-forward)))

(defun himalaya-message-select ()
  "Read the message at point."
  (interactive)
  (let* ((message (tabulated-list-get-entry))
         (uid (substring-no-properties (elt message 0))))
    (himalaya-message-read uid himalaya-account himalaya-mailbox)))

(defun himalaya-message-copy (target)
  "Copy the message at point to TARGET mailbox."
  (interactive (list (completing-read "Copy to mailbox: " (himalaya--mailbox-list-names himalaya-account))))
  (let* ((message (tabulated-list-get-entry))
         (uid (substring-no-properties (elt message 0))))
    (message "%s" (himalaya--message-copy uid target himalaya-account himalaya-mailbox))))

(defun himalaya-message-move (target)
  "Move the message at point to TARGET mailbox."
  (interactive (list (completing-read "Move to mailbox: " (himalaya--mailbox-list-names himalaya-account))))
  (let* ((message (tabulated-list-get-entry))
         (uid (substring-no-properties (elt message 0))))
    (message "%s" (himalaya--message-move uid target himalaya-account himalaya-mailbox))
    (revert-buffer)))

(defun himalaya-message-delete ()
  "Delete the message at point."
  (interactive)
  (let* ((message (tabulated-list-get-entry))
         (uid (substring-no-properties (elt message 0)))
         (subject (substring-no-properties (elt message 2))))
    (when (y-or-n-p (format "Delete message \"%s\"? " subject))
      (himalaya--message-delete (list uid))
      (revert-buffer))))

(defun himalaya-forward-page ()
  "Go to the next page of the current mailbox."
  (interactive)
  (himalaya-message-list himalaya-account himalaya-mailbox (1+ himalaya-page)))

(defun himalaya-backward-page ()
  "Go to the previous page of the current mailbox."
  (interactive)
  (himalaya-message-list himalaya-account himalaya-mailbox (max 1 (1- himalaya-page))))

(defun himalaya-jump-to-page (page)
  "Jump to PAGE of current mailbox."
  (interactive "nJump to page: ")
  (himalaya-message-list himalaya-account himalaya-mailbox (max 1 page)))

(defun himalaya-next-message ()
  "Go to the next message."
  (interactive)
  (condition-case nil
      (himalaya-message-read (prin1-to-string (1+ (string-to-number himalaya-uid)))
                             himalaya-account
                             himalaya-mailbox)
    (t (user-error "At end of mailbox"))))

(defun himalaya-previous-message ()
  "Go to the previous message."
  (interactive)
  (when (string= himalaya-uid "1")
    (user-error "At beginning of mailbox"))
  (himalaya-message-read (prin1-to-string (max 1 (1- (string-to-number himalaya-uid))))
                         himalaya-account
                         himalaya-mailbox))

(defvar himalaya-message-list-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "m") #'himalaya-switch-mailbox)
    (define-key map (kbd "RET") #'himalaya-message-select)
    (define-key map (kbd "f") #'himalaya-forward-page)
    (define-key map (kbd "b") #'himalaya-backward-page)
    (define-key map (kbd "j") #'himalaya-jump-to-page)
    (define-key map (kbd "C") #'himalaya-message-copy)
    (define-key map (kbd "M") #'himalaya-message-move)
    (define-key map (kbd "D") #'himalaya-message-delete)
    (define-key map (kbd "w") #'himalaya-message-write)
    (define-key map (kbd "R") #'himalaya-message-reply)
    (define-key map (kbd "F") #'himalaya-message-forward)
    map))

(define-derived-mode himalaya-message-list-mode tabulated-list-mode "Himylaya-Messages"
  "Himylaya email client message list mode."
  (setq tabulated-list-format (vector
                               '("ID" 5 nil :right-align t)
                               '("Flags" 6 nil)
                               (list "Subject" himalaya-subject-width nil)
                               (list "Sender" himalaya-from-width nil)
                               '("Date" 19 nil)))
  (setq tabulated-list-sort-key nil)
  (setq tabulated-list-entries #'himalaya--message-list-build-table)
  (setq tabulated-list-padding 1)
  (tabulated-list-init-header)
  (hl-line-mode))

(defvar himalaya-message-read-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "a") #'himalaya-message-read-download-attachments)
    (define-key map (kbd "R") #'himalaya-message-read-switch-raw)
    (define-key map (kbd "r") #'himalaya-message-read-reply)
    (define-key map (kbd "f") #'himalaya-message-read-forward)
    (define-key map (kbd "q") #'kill-current-buffer)
    (define-key map (kbd "n") #'himalaya-next-message)
    (define-key map (kbd "p") #'himalaya-previous-message)
    map))

(define-derived-mode himalaya-message-read-mode message-mode "Himalaya-Read"
  "Himalaya email client message reading mode.")

(defvar himalaya-message-read-raw-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "a") #'himalaya-message-read-download-attachments)
    (define-key map (kbd "R") #'himalaya-message-read-switch-plain)
    (define-key map (kbd "r") #'himalaya-message-read-reply)
    (define-key map (kbd "f") #'himalaya-message-read-forward)
    (define-key map (kbd "q") #'kill-current-buffer)
    (define-key map (kbd "n") #'himalaya-next-message)
    (define-key map (kbd "p") #'himalaya-previous-message)
    map))

(define-derived-mode himalaya-message-read-raw-mode message-mode "Himalaya-Read-Raw"
  "Himalaya email client raw message mode.")

(provide 'himalaya)
;;; himalaya.el ends here
