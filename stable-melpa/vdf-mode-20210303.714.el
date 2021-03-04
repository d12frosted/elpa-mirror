;;; vdf-mode.el --- Major mode for editing Valve VDF files.  -*- lexical-binding: t; -*-

;; Copyright (C) 2019 plapadoo UG

;; Author: Philipp Middendorf
;; URL: https://github.com/plapadoo/vdf-mode
;; Package-Version: 20210303.714
;; Package-Commit: 0910d4f847e9c817eb8da5434b3879048ec4ac92
;; Version: 1.2
;; Package-Requires: ((emacs "24.3"))

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

;; Add mode for Valve's VDF file format.

;;; Code:

(defgroup vdf
  nil
  "Valve VDF mode for Emacs."
  :group 'languages
  :prefix "vdf-")

(defcustom vdf-indent-offset 1
  "Default indentation offset for VDF."
  :type 'integer)

(defvar vdf-mode-syntax-table
  (let ((syntax-table (make-syntax-table)))
    (modify-syntax-entry ?\/ ". 12b" syntax-table)
    (modify-syntax-entry ?\n "> b" syntax-table)
    (modify-syntax-entry ?{ "(}" syntax-table)
    (modify-syntax-entry ?} "){" syntax-table)
    (modify-syntax-entry ?\\ "." syntax-table)
    syntax-table) "Syntax table for `vdf-mode'.")

(defvar vdf-highlights
  '(("#include\\|#base" . font-lock-preprocessor-face)
    ("\"\\([^\"]+?\\)\"" . (1 font-lock-constant-face)))
  "Font lock table for `vdf-mode'.")

(defun vdf-count-backwards (needle pos-begin pos-end)
  "Count `NEEDLE' from `POS-BEGIN' to `POS-END' backwards."
  (save-excursion
    (let (opencount)
      (setq opencount 0)
      (goto-char pos-end)
      (while (and (> (point) pos-begin)
                  (search-backward needle pos-begin t))
        (setq opencount (1+ opencount)))
      opencount)))

(defun vdf-indent-line ()
  "Indent current line as VDF code."
  (let* ((open-count (vdf-count-backwards "{" (point-min) (line-beginning-position)))
         (close-count  (vdf-count-backwards "}" (point-min) (+ (point) 1)))
         (depth (* (- open-count close-count) vdf-indent-offset)))
  (if (<= (current-column) (current-indentation))
      (indent-line-to depth)
    (save-excursion (indent-line-to depth)))))

;;;###autoload
(define-derived-mode vdf-mode prog-mode "vdf"
  "major mode for editing Valve VDF files"
  (set (make-local-variable 'font-lock-defaults) '(vdf-highlights))
  (set-syntax-table vdf-mode-syntax-table)
  (setq-local comment-start "// ")
  (setq-local comment-start-skip "// *")
  (setq-local comment-end "")
  (set (make-local-variable 'indent-line-function) 'vdf-indent-line))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.vdf\\'" . vdf-mode))

(provide 'vdf-mode)
;;; vdf-mode.el ends here
