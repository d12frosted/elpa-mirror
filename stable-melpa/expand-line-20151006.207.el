;;; expand-line.el --- Expand selection by line

;; Copyright (C) 2015 Zhang Kai Yu

;; Author: Kai Yu <yeannylam@gmail.com>
;; Keywords:
;; Package-Version: 20151006.207
;; Package-Commit: 75a5d0241f35dd0748ab8ecb4ff16891535be372

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

;; This package is similar to expand region,
;; but expand selection by line.

;;; Code:

(defvar expand-line-saved-position nil
  "The position before line expanding.")

(defun expand-line-save-point ()
  "Save current point."
  (setq expand-line-saved-position (point)))

(defun expand-line-restore-point ()
  "Restore point before expanding line."
  (goto-char expand-line-saved-position))

;;;###autoload
(defun expand-line-mark-line ()
  "Mark current line. After mark current line, use `expand-line' to expand."
  (interactive)
  (expand-line-save-point)
  (push-mark (point))
  (push-mark (line-beginning-position) nil t)
  (goto-char (line-end-position))
  (if (char-after) (forward-char))
  (expand-line-mode 1))

(defun expand-line-expand-previous-line (arg)
  "Expand to previous line."
  (interactive "p")
  (if (> (point) (mark))
      (exchange-point-and-mark))
  (move-beginning-of-line (- 1 arg)))

(defun expand-line-expand-next-line (arg)
  "Expand to next line."
  (interactive "p")
  (if (< (point) (mark))
      (exchange-point-and-mark))
  (move-end-of-line arg)
  (if (char-after) (forward-char)))

(defun expand-line-contract-next-line (arg)
  "Contract to next line."
  (interactive "p")
  (if (< (point) (mark))
      (exchange-point-and-mark))
  (move-end-of-line (- arg))
  (if (char-after) (forward-char)))

(defun expand-line-contract-previous-line (arg)
  "Contract to previous line."
  (interactive "p")
  (if (> (point) (mark))
      (exchange-point-and-mark))
  (move-beginning-of-line (+ arg 1)))

(defun expand-line-leave-point-in-place ()
  "Just like `keyboard-quit' and deactivate region. But leave
cursor in place."
  (interactive)
  (deactivate-mark)
  (expand-line-mode -1))

(defadvice keyboard-quit (before expand-line-restore-point activate)
  (if expand-line-mode
      (progn
        (expand-line-restore-point)
        (expand-line-mode -1))))

;; On and off

;;;###autoload
(defun turn-on-expand-line-mode ()
  "Turn on `expand-line-mode'."
  (interactive)
  (if mark-active
      (progn
        (expand-line-save-point)
        (expand-line-mode 1))
    (expand-line-mark-line)))

(defun turn-off-expand-line-mode ()
  "Turn off `expand-line-mode'."
  (interactive)
  (expand-line-mode -1))

;; Keymap

(defvar expand-line-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-p") 'expand-line-expand-previous-line)
    (define-key map (kbd "C-n") 'expand-line-expand-next-line)
    (define-key map (kbd "M-n") 'expand-line-contract-previous-line)
    (define-key map (kbd "M-p") 'expand-line-contract-next-line)
    (define-key map (kbd "M-g") 'expand-line-leave-point-in-place)
    map)
  "Keymap for expand-line mode.")

;; Mode

;;;###autoload
(define-minor-mode expand-line-mode
  "Mode for easy expand line when expand line is activated."
  :keymap expand-line-mode-map
  :lighter " EL"
  (if expand-line-mode
      (add-hook 'deactivate-mark-hook 'turn-off-expand-line-mode)
    (remove-hook 'deactivate-mark-hook 'turn-off-expand-line-mode)))

(provide 'expand-line)
;;; expand-line.el ends here
