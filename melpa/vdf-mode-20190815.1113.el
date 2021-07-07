;;; vdf-mode.el --- Major mode for editing Valve VDF files.

;; Copyright (C) 2019 plapadoo UG

;; Author: Philipp Middendorf
;; URL: https://github.com/plapadoo/vdf-mode
;; Package-Version: 20190815.1113
;; Package-Commit: f474047a35a2779e4ebaf9166f3d54f359cf9f3c
;; Version: 1.0

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

;;; Code:

(defvar vdf-mode-syntax-table nil "Syntax table for `vdf-mode'.")

(setq vdf-mode-syntax-table
      (let ( (synTable (make-syntax-table)))
        (modify-syntax-entry ?\/ ". 12b" synTable)
        (modify-syntax-entry ?\n "> b" synTable)
        (modify-syntax-entry ?{ "(}" synTable)
        (modify-syntax-entry ?} "){" synTable)
        synTable))

(defvar vdf-highlights "Font lock table for `vdf-mode'.")

(setq vdf-highlights
      '(("#include\\|#base" . font-lock-preprocessor-face)
        ("\"\\([^\"]+?\\)\"" . (1 font-lock-constant-face))
        ))


(defun vdf-count (needle posBegin posEnd)
  "Count `NEEDLE' between `POSBEGIN' and `POSEND'."
  (save-excursion
    (let (opencount)
      (setq opencount 0)
      (while (and (> (point) posBegin)
                  (search-backward needle posBegin t))
        (setq opencount (1+ opencount)))
      opencount))
  )

(defun vdf-indent-line ()
  "Indent current line as VDF code."
  (save-excursion
    (beginning-of-line)
    (let ((opencount (vdf-count "{" (point-min) (point-max))))
      (save-excursion
        (end-of-line)
        (let* ((closecount (vdf-count "}" (point-min) (point-max)))
              (depth (- opencount closecount)))
          (indent-line-to (* depth 2)))))))
  
(define-derived-mode vdf-mode fundamental-mode "vdf"
  "major mode for editing Valve VDF files"
  (set (make-local-variable 'font-lock-defaults) '(vdf-highlights))
  (set-syntax-table vdf-mode-syntax-table)
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (set (make-local-variable 'indent-line-function) 'vdf-indent-line))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.vdf\\'" . vdf-mode))

(provide 'vdf-mode)
;;; vdf-mode.el ends here
