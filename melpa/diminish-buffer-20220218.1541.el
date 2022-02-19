;;; diminish-buffer.el --- Diminish (hide) buffers from buffer-menu  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2022  Shen, Jen-Chieh
;; Created date 2019-08-31 00:02:54

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Diminish (hide) buffers from buffer-menu.
;; Keyword: diminish hide buffer menu
;; Version: 0.2.0
;; Package-Version: 20220218.1541
;; Package-Commit: f9b8dac19ccf0df06d29c0f9f2ac71b178ecd803
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

(require 'cl-lib)

(defgroup diminish-buffer nil
  "Diminish (hide) buffers from buffer-menu."
  :prefix "diminish-buffer-"
  :group 'convenience
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/diminish-buffer"))

(defcustom diminish-buffer-list
  '()
  "List of buffer name that you want to hide in the `buffer-menu'."
  :type 'list
  :group 'diminish-buffer)

(defcustom diminish-buffer-mode-list
  '()
  "List of buffer mode that you want to hide in the `buffer-menu'."
  :type 'list
  :group 'diminish-buffer)

(defconst diminish-buffer-menu-name "*Buffer List*"
  "Buffer name for *Buffer List*.")

;;
;; (@* "Util" )
;;

(defun diminish-buffer--contain-list-string-regex (elt list)
  "Return non-nil if ELT is listed in LIST."
  (let ((elt (format "%s" elt)))
    (cl-some (lambda (elm) (string-match-p elm elt)) list)))

;;
;; (@* "Entry" )
;;

(defun diminish-buffer--enable ()
  "Enable `diminish-buffer'."
  (advice-add 'list-buffers--refresh :around #'diminish-buffer--refresh-list)
  (diminish-buffer--refresh-buffer-menu))

(defun diminish-buffer--disable ()
  "Disable `diminish-buffer'."
  (advice-remove 'list-buffers--refresh #'diminish-buffer--refresh-list)
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

(defun diminish-buffer--filter (buffer)
  "Filter out the BUFFER."
  (with-current-buffer buffer
    (or (diminish-buffer--contain-list-string-regex (buffer-name) diminish-buffer-list)
        (diminish-buffer--contain-list-string-regex major-mode diminish-buffer-mode-list))))

;; XXX This is the default filter from Emacs itself; leave this feature as is it.
(defun diminish-buffer--default-filter (buffer)
  "Copy it from function `list-buffers--refresh'."
  (let ((buffer-menu-buffer (current-buffer))
        (show-non-file (not Buffer-menu-files-only)))
    (with-current-buffer buffer
      (let* ((name (buffer-name))
             (file buffer-file-name))
        (and (buffer-live-p buffer)
             (or (not (string= (substring name 0 1) " "))
                 file)
             (not (eq buffer buffer-menu-buffer))
             (or file show-non-file))))))

;;;###autoload
(defun diminish-buffer-default-list (&optional buffer-list)
  "Return the default BUFFER-LIST generated from `buffer-menu'."
  (unless buffer-list
    (setq buffer-list (buffer-list (if Buffer-menu-use-frame-buffer-list
                                       (selected-frame)))
          buffer-list (cl-remove-if-not #'diminish-buffer--default-filter buffer-list)))
  buffer-list)

;;;###autoload
(defun diminish-buffer-diminished-list (&optional buffer-list)
  "Return diminished BUFFER-LIST."
  (unless buffer-list
    (setq buffer-list (diminish-buffer-default-list buffer-list)
          buffer-list (cl-remove-if #'diminish-buffer--filter buffer-list)))  ; filter
  buffer-list)

(defun diminish-buffer--refresh-list (fnc &rest args)
  "Modified argument `buffer-list' before display the buffer menu.
Override FNC and ARGS."
  (let ((buffer-list (nth 0 args)))
    (unless buffer-list
      (setq buffer-list (diminish-buffer-diminished-list buffer-list))
      (pop args) (push buffer-list args)))  ; update
  (apply fnc args))

(defun diminish-buffer--refresh-buffer-menu ()
  "Refresh buffer menu at time when enabled/disabled."
  (save-window-excursion
    (let ((inhibit-message t) message-log-max)
      (when (get-buffer diminish-buffer-menu-name)
        (with-current-buffer diminish-buffer-menu-name (tabulated-list-revert))))
    (bury-buffer)))

(provide 'diminish-buffer)
;;; diminish-buffer.el ends here
