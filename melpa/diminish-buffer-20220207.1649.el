;;; diminish-buffer.el --- Diminish (hide) buffers from buffer-menu  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Shen, Jen-Chieh
;; Created date 2019-08-31 00:02:54

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Diminish (hide) buffers from buffer-menu.
;; Keyword: diminish hide buffer menu
;; Version: 0.1.1
;; Package-Version: 20220207.1649
;; Package-Commit: 4db1f5d7c9880833cfc499ebab0dc0b162b03029
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/jcs-elpa/diminish-buffer

;; This file is NOT part of GNU Emacs.

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
;;
;; Diminish (hide) buffers from buffer-menu.
;;

;;; Code:

(defgroup diminish-buffer nil
  "Diminish (hide) buffers from buffer-menu."
  :prefix "diminish-buffer-"
  :group 'convenience
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/diminish-buffer"))

(defcustom diminish-buffer-list '("[*]helm")
  "List of buffer name that you want to hide in the `buffer-menu'."
  :type 'list
  :group 'diminish-buffer)

(defcustom diminish-buffer-mode-list '()
  "List of buffer mode that you want to hide in the `buffer-menu'."
  :type 'list
  :group 'diminish-buffer)

;;
;; (@* "Util" )
;;

(defun diminish-buffer--is-contain-list-string-regexp (elt list)
  "Return non-nil if ELT is listed in LIST."
  (when (stringp elt) (cl-some (lambda (elm) (string-match-p elm elt)) list)))

;;
;; (@* "Entry" )
;;

(defun diminish-buffer--enable ()
  "Enable `diminish-buffer'."
  (advice-add 'buffer-menu :after #'diminish-buffer-clean)
  (advice-add 'tabulated-list-print :after #'diminish-buffer-clean)
  (diminish-buffer--refresh-buffer-menu)
  (diminish-buffer-clean))

(defun diminish-buffer--disable ()
  "Disable `diminish-buffer'."
  (advice-remove 'buffer-menu #'diminish-buffer-clean)
  (advice-remove 'tabulated-list-print #'diminish-buffer-clean)
  (diminish-buffer--refresh-buffer-menu))

;;;###autoload
(define-minor-mode diminish-buffer-mode
  "Minor mode 'diminish-buffer-mode'."
  :global t
  :require 'diminish-buffer
  :group 'diminish-buffer
  (if diminish-buffer-mode (diminish-buffer--enable) (diminish-buffer--disable)))

;;
;; (@* "Core" )
;;

(defmacro diminish-buffer-with-buffer-menu (&rest body)
  "Safe execute BODY inside `buffer-menu'."
  (declare (indent 0) (debug t))
  `(when diminish-buffer-mode
     (when (get-buffer "*Buffer List*")
       (with-current-buffer "*Buffer List*" ,@body))))

;;;###autoload
(defun diminish-buffer-clean (&rest _)
  "Do the diminish action for `buffer-menu'."
  (interactive)
  (diminish-buffer-with-buffer-menu
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (let ((buf-name (elt (tabulated-list-get-entry) 3))
              (buf-mode (elt (tabulated-list-get-entry) 5)))
          (if (or (diminish-buffer--is-contain-list-string-regexp buf-name diminish-buffer-list)
                  (diminish-buffer--is-contain-list-string-regexp buf-mode diminish-buffer-mode-list))
              (tabulated-list-delete-entry)
            (forward-line 1)))))))

(defun diminish-buffer--refresh-buffer-menu ()
  "Refresh buffer menu at time when enabled/disabled."
  (save-window-excursion
    (let ((inhibit-message t) message-log-max)
      (buffer-menu) (tabulated-list-revert))
    (bury-buffer)))

(provide 'diminish-buffer)
;;; diminish-buffer.el ends here
