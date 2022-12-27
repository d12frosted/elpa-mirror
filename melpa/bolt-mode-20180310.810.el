;;; bolt-mode.el --- Editing support for Bolt language  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Mikhail Pontus

;; Author: Mikhail Pontus <mpontus@gmail.com>
;; URL: https://github.com/mpontus/bolt-mode
;; Package-Version: 20180310.810
;; Package-Commit: 85a5a752bfbebb4aed884326c25db64c000e9934
;; Version: 0.1
;; Keywords: languages
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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides major mode for Bolt files with syntax highlighting and indentation support.

;;; Code:

(defconst bolt-mode-identifier-re "[a-zA-Z_$][a-zA-Z0-9]+")

(defvar bolt-mode-highlights
  (let ((keywords '("type" "path" "extends" "is" "this" "now" "true" "false"))
	(types '("String" "Number" "Boolean" "Object" "Any" "Null" "Map")))
    `((,(regexp-opt keywords 'words) . font-lock-keyword-face)
      (,(regexp-opt types 'words) . font-lock-type-face)
      ;; function calls
      (,(concat "\\<\\(" bolt-mode-identifier-re "\\)(") . (1 font-lock-function-name-face)))))

(defvar bolt-mode-syntax-table
  (let ((table (copy-syntax-table
		(standard-syntax-table))))
    (modify-syntax-entry ?/ ". 124" table)
    (modify-syntax-entry ?* ". 23b" table)
    (modify-syntax-entry ?\r "> " table)
    (modify-syntax-entry ?\n "> " table)
    table))

(defun bolt-mode-previous-nonblank-line ()
  "Move cursor to previous non-blank line."
  (goto-char (line-beginning-position))
  (skip-chars-backward "\r\n\s\t"))

(defun bolt-mode-find-unclosed-pair ()
  "Return non-nil value if unclosed pairs found on current line."
  (goto-char (line-beginning-position))
  (let (unclosed-pairs)
    (while (not (or (looking-at "\n")
		    (eobp)))
      (let ((char (following-char)))
	(cond
	 ((eq (char-syntax char) ?\()
	  ;; found opening pair
	  (push char unclosed-pairs))
	 ((and (eq (char-syntax char) ?\))
	       (eq (matching-paren char) (car unclosed-pairs)))
	  ;; found a match to most recent pair
	  (pop unclosed-pairs))))
      (forward-char))
    unclosed-pairs))

(defun bolt-mode-indent-line ()
  "Indent current line."
  (let (base-indent should-indent)
    (save-excursion
      (bolt-mode-previous-nonblank-line)
      (setq base-indent (current-indentation))
      (setq should-indent (bolt-mode-find-unclosed-pair)))
    (indent-line-to
     (if (save-excursion
	   (goto-char (line-beginning-position))
	   (skip-syntax-forward " " (line-end-position))
	   (eq (char-syntax (following-char)) ?\)))
	 ;; Dedent when current line starts with a closing pair
	 (if should-indent base-indent (- base-indent tab-width))
       (if should-indent
	   (+ base-indent tab-width)
	 base-indent)))))

;;;###autoload
(define-derived-mode bolt-mode fundamental-mode "Bolt"
  "Major mode for editing Bolt files"
  (set-syntax-table bolt-mode-syntax-table)
  (setq-local comment-start "//")
  (setq-local comment-use-syntax t)
  (setq font-lock-defaults '(bolt-mode-highlights))
  (setq indent-line-function #'bolt-mode-indent-line))

;;;###autoload
(add-to-list 'auto-mode-alist
             '("\\.bolt\\'" . bolt-mode))

(provide 'bolt-mode)
;;; bolt-mode.el ends here
