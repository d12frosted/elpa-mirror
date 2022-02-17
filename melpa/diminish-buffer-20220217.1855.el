;;; diminish-buffer.el --- Diminish (hide) buffers from buffer-menu  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Shen, Jen-Chieh
;; Created date 2019-08-31 00:02:54

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Diminish (hide) buffers from buffer-menu.
;; Keyword: diminish hide buffer menu
;; Version: 0.2.0
;; Package-Version: 20220217.1855
;; Package-Commit: 672de7e1d022cb7da47a746ba508fe23f7bd6737
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
  (append
   '("[*]Buffer List[*]"
     "[*]Minibuf-[01][*]" "[*]Echo Area [01][*]"
     "[*]code-converting-work[*]" "[*]code-conversion-work[*]"
     "[*]tip[*]")
   '("[*]diff-hl[*]" "[*]helm"))
  "List of buffer name that you want to hide in the `buffer-menu'."
  :type 'list
  :group 'diminish-buffer)

(defcustom diminish-buffer-mode-list
  '()
  "List of buffer mode that you want to hide in the `buffer-menu'."
  :type 'list
  :group 'diminish-buffer)

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
  (or (diminish-buffer--contain-list-string-regex (buffer-name buffer) diminish-buffer-list)
      (diminish-buffer--contain-list-string-regex (with-current-buffer buffer major-mode) diminish-buffer-mode-list)))

(defun diminish-buffer--refresh-list (fnc &rest args)
  "Modified argument `buffer-list' before display the buffer menu.
Override FNC and ARGS."
  (let ((buffer-list (nth 0 args)))
    (unless buffer-list
      (setq buffer-list (buffer-list (if Buffer-menu-use-frame-buffer-list
                                         (selected-frame)))  ; see function `list-buffers--refresh'
            buffer-list (cl-remove-if #'diminish-buffer--filter buffer-list))  ; filter
      (pop args) (push buffer-list args)))  ; update
  (apply fnc args))

(defun diminish-buffer--refresh-buffer-menu ()
  "Refresh buffer menu at time when enabled/disabled."
  (save-window-excursion
    (let ((inhibit-message t) message-log-max)
      (buffer-menu) (tabulated-list-revert))
    (bury-buffer)))

(provide 'diminish-buffer)
;;; diminish-buffer.el ends here
