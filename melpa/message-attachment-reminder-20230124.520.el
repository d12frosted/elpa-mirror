;;; message-attachment-reminder.el --- Remind if missing attachment         -*- lexical-binding: t; -*-

;; Copyright (c) 2020 Alex Murray

;; Author: Alex Murray <murray.alex@gmail.com>
;; Maintainer: Alex Murray <murray.alex@gmail.com>
;; URL: https://github.com/alexmurray/message-attachment-reminder
;; Package-Version: 20230124.520
;; Package-Commit: 975381d6e7c6771c462e73abd3398a4ed2a9b86b
;; Version: 0.2
;; Package-Requires: ((emacs "24.1"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Scans outgoing messages via `message-send-hook' to look for phrases
;; which indicate that an attachment is expected to be present but for
;; which no attachment has been inserted.

;; The phrases to look for can be customized via
;; `message-attachment-reminder-regexp', whilst the warning message shown
;; to the user can be changed via
;; `message-attachment-reminder-warning'.

;; Finally, by default quoted lines are not checked however this can be
;; changed by setting `message-attachment-reminder-exclude-quoted' to
;; `nil'.

;;;; Setup

;; (require 'message-attachment-reminder)

;;; Code:
(require 'message)

(defgroup message-attachment-reminder nil
  "Remind if missing attachments in when sending messages."
  :prefix "message-attachment-reminder-"
  :group 'message-mail
  :group 'message-send)

(defcustom message-attachment-reminder-regexp
  (regexp-opt '("attached is"
                "attached you will find"
                "attached you will see"
                "I have attached"
                "I've attached"
                "find attached"
                "in the attached"
                "see attached"
                "see attachment"
                "see the attachment"
                "see the attached"
                "enclosed is"
                "enclosed you will find"
                "enclosed you will see"
                "I have enclosed"
                "I've enclosed"
                "find enclosed"
                "see enclosed"
                "see the enclosed"
                "in the enclosed"))
  "Regular expression to match possible attachment reminder hints.
When found in the composed message and there are no attachments
present, will cause `message-attachment-reminder-warning' to be
displayed to the user."
  :type 'regexp
  :group 'message-attachment-reminder)

(defcustom message-attachment-reminder-warning
  "This message contains '%s' but has no attachment, send it anyway? "
  "Warning message displayed with matched hint to user on missing attachments."
  :type 'string
  :group 'message-attachment-reminder)

(defcustom message-attachment-reminder-exclude-quoted t
  "Whether to exclude checking quoted parts of message."
  :type 'bool
  :group 'message-attachment-reminder)

(defun message-attachment-reminder-attachment-present-p ()
  "Find if an attachment is present in the current message."
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (when (search-forward "<#part" nil t) t))))

(defun message-attachment-reminder-attachment-expected-p ()
  "Find if an attachment is expected in the current message, returning matched text."
  (save-excursion
    (save-restriction
        (widen)
        (message-goto-body)
        (let ((case-fold-search t)
              (hint))
          (while (and (null hint)
                      (re-search-forward message-attachment-reminder-regexp nil t)
                      (or (null message-attachment-reminder-exclude-quoted)
                          ;; only use if not quoted
                          (not (save-match-data
                                 (string-match (concat "^" message-cite-prefix-regexp)
                                               (buffer-substring (line-beginning-position) (line-end-position)))))))
            (setq hint (match-string 0)))
          hint))))

(defun message-attachment-reminder-warn-if-no-attachments ()
  "Warn user if message appears to have missing attachments."
  (let ((hint (message-attachment-reminder-attachment-expected-p)))
    (when (and hint
               (not (message-attachment-reminder-attachment-present-p)))
      (unless (y-or-n-p (format message-attachment-reminder-warning hint))
        (keyboard-quit)))))

(add-hook 'message-send-hook
          #'message-attachment-reminder-warn-if-no-attachments)

(provide 'message-attachment-reminder)
;;; message-attachment-reminder.el ends here
