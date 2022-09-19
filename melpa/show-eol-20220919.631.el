;;; show-eol.el --- Show end of line symbol in buffer  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Shen, Jen-Chieh
;; Created date 2019-04-28 22:34:40

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/jcs-elpa/show-eol
;; Package-Version: 20220919.631
;; Package-Commit: ad3aa8f4fa0d1b20f8526536f0ac35386f521372
;; Version: 0.0.5
;; Package-Requires: ((emacs "24.4"))
;; Keywords: convenience end eol line

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Show end of line symbol in buffer.
;;

;;; Code:

(eval-when-compile (require 'whitespace))

(defgroup show-eol nil
  "Show end of line symbol in buffer."
  :prefix "show-eol-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/show-eol"))

(defcustom show-eol-lf-mark "LF"
  "Mark symbol for LF."
  :type 'string
  :group 'show-eol)

(defcustom show-eol-crlf-mark "CRLF"
  "Mark symbol for CRLF."
  :type 'string
  :group 'show-eol)

(defcustom show-eol-cr-mark "CR"
  "Mark symbol for CR."
  :type 'string
  :group 'show-eol)

;;; Entry

(defun show-eol-enable ()
  "Enable `show-eol-select' in current buffer."
  (add-hook 'after-save-hook 'show-eol-after-save-hook nil t)
  (setq-local whitespace-display-mappings (mapcar #'copy-sequence whitespace-display-mappings))
  (advice-add 'set-buffer-file-coding-system :after #'show-eol--set-buffer-file-coding-system--advice-after)
  (show-eol-update-eol-marks))

(defun show-eol-disable ()
  "Disable `show-eol-mode' in current buffer."
  (remove-hook 'after-save-hook 'show-eol-after-save-hook t)
  (kill-local-variable 'whitespace-display-mappings)
  (advice-remove 'set-buffer-file-coding-system #'show-eol--set-buffer-file-coding-system--advice-after)
  (whitespace-newline-mode -1))

;;;###autoload
(define-minor-mode show-eol-mode
  "Minor mode `show-eol-mode'."
  :lighter " ShowEOL"
  :group show-eol
  (require 'whitespace)
  (if show-eol-mode (show-eol-enable) (show-eol-disable)))

(defun show-eol-turn-on-show-eol-mode ()
  "Turn on the `shift-select-mode'."
  (show-eol-mode 1))

;;;###autoload
(define-globalized-minor-mode global-show-eol-mode
  show-eol-mode show-eol-turn-on-show-eol-mode
  :require 'show-eol)

;;; Core

;;;###autoload
(defun show-eol-get-current-system ()
  "Return the current system name."
  (let ((bf-cs (symbol-name buffer-file-coding-system)))
    (cond ((string-match-p "dos" bf-cs) 'dos)
          ((string-match-p "mac" bf-cs) 'mac)
          ((string-match-p "unix" bf-cs) 'unix)
          (t 'unix))))

;;;###autoload
(defun show-eol-get-eol-mark-by-system ()
  "Return the EOL mark string by system type."
  (let ((sys (show-eol-get-current-system)))
    (cond ((eq sys 'dos) show-eol-crlf-mark)
          ((eq sys 'mac) show-eol-cr-mark)
          ((eq sys 'unix) show-eol-lf-mark)
          (t (user-error "[WARNING] Unknown system type")))))

(defun show-eol-find-mark-in-list (mk-sym)
  "Return the MK-SYM index in the `whitespace-display-mappings' list."
  (let ((index 0) (mark-name nil) (nl-mark-index -1))
    (dolist (entry whitespace-display-mappings)
      (setq mark-name (car entry))
      (when (eq mk-sym mark-name) (setq nl-mark-index index))
      (setq index (1+ index)))
    nl-mark-index))

(defun show-eol-set-mark-with-string (mk-sym mk-str)
  "Set the new mark, MK-SYM by using string, MK-STR."
  (let* ((sys-mark (vconcat mk-str))
         (nl-mark-index (show-eol-find-mark-in-list mk-sym))
         (nl-mark-code-point-address (caddr (nth nl-mark-index whitespace-display-mappings)))
         (nl-mark-code-point-nl-elt (aref nl-mark-code-point-address (1- (length nl-mark-code-point-address))))
         (new-nl-mark-vec (vconcat sys-mark (make-vector 1 nl-mark-code-point-nl-elt))))
    (setf (caddr (nth nl-mark-index whitespace-display-mappings)) new-nl-mark-vec)))

(defun show-eol-update-eol-marks ()
  "Update the EOL mark once."
  (show-eol-set-mark-with-string 'newline-mark (show-eol-get-eol-mark-by-system))
  ;; Calling this resets the whitespace glyphs to always be correct.
  (whitespace-newline-mode 1))

(defun show-eol-after-save-hook ()
  "Show EOL after save hook."
  (show-eol-update-eol-marks))

(defun show-eol--set-buffer-file-coding-system--advice-after (&rest _)
  "Advice execute after `set-buffer-file-coding-system' function is called."
  (when show-eol-mode (show-eol-update-eol-marks)))

(provide 'show-eol)
;;; show-eol.el ends here
