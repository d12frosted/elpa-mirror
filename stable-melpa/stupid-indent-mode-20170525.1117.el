;;; stupid-indent-mode.el --- Plain stupid indentation minor mode

;; Copyright (C) 2013  Mihai Bazon

;; Author: Mihai Bazon <mihai.bazon@gmail.com>
;; Keywords:
;; Package-Version: 20170525.1117
;; Package-Commit: 3295e7de5e2cfddc3bf0e462e852bf58972f5d70

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

;; Dumb indentation mode is appropriate for editing buffers that Emacs
;; does not fully understand syntactically, such as HTML/PHP
;; (typically involving multiple languages with different indentation
;; rules in the same buffer).  The default indentation level is 2
;; (customize `stupid-indent-level').
;;
;; Key bindings:
;;
;; TAB       -- indent current line by the value of `stupid-indent-level'
;; S-TAB     -- outdent current line
;; C-c TAB   -- indent region
;; C-c S-TAB -- outdent region
;; RET       -- newline and indent
;; C-c C-TAB -- indent according to mode

;;; Code:

(defcustom stupid-indent-level 2
  "Indentation level for stupid-indent-mode")

(defun %stupid-force-indent-line ()
  (let (col)
    (save-excursion
     (back-to-indentation)
     (setq col (+ (current-column) stupid-indent-level))
     (indent-line-to col))
    (when (< (current-column) col)
      (back-to-indentation))))

(defun stupid-indent-line ()
  (interactive)
  (let ((bt (save-excursion
             (back-to-indentation)
             (current-column))))
    (cond
      ((< (current-column) bt)
       (back-to-indentation))
      ((looking-at "\\s-*\n")
       (let ((col (save-excursion
                   (previous-line)
                   (back-to-indentation)
                   (current-column))))
         (if (< (current-column) col)
             (indent-line-to col)
             (%stupid-force-indent-line))))
      (t
       (%stupid-force-indent-line)))))

(defun stupid-outdent-line ()
  (interactive)
  (let (col)
    (save-excursion
     (back-to-indentation)
     (setq col (- (current-column) stupid-indent-level))
     (when (>= col 0)
       (indent-line-to col)))))

(defun stupid-indent-region (start stop)
  (interactive "r")
  (setq stop (copy-marker stop))
  (goto-char start)
  (while (< (point) stop)
    (unless (and (bolp) (eolp))
      (%stupid-force-indent-line))
    (forward-line 1)))

(defun stupid-outdent-region (start stop)
  (interactive "r")
  (setq stop (copy-marker stop))
  (goto-char start)
  (while (< (point) stop)
    (unless (and (bolp) (eolp))
      (stupid-outdent-line))
    (forward-line 1)))

(defun stupid-indent ()
  (interactive)
  (if (use-region-p)
      (save-excursion
       (stupid-indent-region (region-beginning) (region-end))
       (setq deactivate-mark nil))
      (stupid-indent-line)))

(defun stupid-outdent ()
  (interactive)
  (if (use-region-p)
      (save-excursion
       (stupid-outdent-region (region-beginning) (region-end))
       (setq deactivate-mark nil))
      (stupid-outdent-line)))

(defun stupid-indent-newline ()
  (interactive)
  (when (< (point)
           (save-excursion
            (back-to-indentation)
            (point)))
    (back-to-indentation))
  (let ((col (save-excursion
              (back-to-indentation)
              (current-column))))
    (newline)
    (indent-to-column col)))

(define-minor-mode stupid-indent-mode
  "Stupid indent mode is just plain stupid."
  :init-value nil
  :lighter "/SI"
  :global nil
  :keymap `(
            (,(kbd "<tab>") . stupid-indent)
            (,(kbd "<backtab>") . stupid-outdent)
            (,(kbd "C-c <tab>") . stupid-indent-region)
            (,(kbd "C-c <backtab>") . stupid-outdent-region)
            (,(kbd "<return>") . stupid-indent-newline)
            (,(kbd "C-c C-<tab>") . indent-according-to-mode)
            )
  (when stupid-indent-mode
    (add-hook 'write-contents-functions
              'delete-trailing-whitespace)))

(provide 'stupid-indent-mode)
;;; stupid-indent-mode.el ends here
