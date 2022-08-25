;;; xwiki-mode.el --- Major mode for xwiki-formatted text -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Ackerley Tng

;; Author: Ackerley Tng <ackerleytng@gmail.com>
;; Maintainer: Ackerley Tng <ackerleytng@gmail.com>
;; Created: Oct 15, 2021
;; Version: 0.0.1
;; Package-Version: 20211112.511
;; Package-Commit: 8b6f2caead8ec804e8d7d37d87eb3b46aa96b6e8
;; Package-Requires: ((emacs "27.1"))
;; Keywords: languages, convenience, tools
;; URL: https://github.com/ackerleytng/xwiki-mode

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.

;; You should have received a copy of the GNU General Public License along with
;; this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; See README.md for details

;;; Code:

(require 'cl-lib)
(require 'font-lock)

;;; Table management functions =================================================

(defconst xwiki-table-line-regex
  (rx line-start ?|))

(defun xwiki-table-at-point-p ()
  "Return non-nil when point is in a table."
  (save-excursion
    (beginning-of-line)
    (looking-at-p xwiki-table-line-regex)))

(defun xwiki-table-begin ()
  "Find the beginning of the table and return its position.
This function assumes point is on a table."
  (save-excursion
    ;; Keep going up until we're out of the table
    (while (and (not (bobp))
                (xwiki-table-at-point-p))
      (forward-line -1))
    ;; Go one line down so that we're on the first character of the table (|)
    (unless (or (eobp)
                (xwiki-table-at-point-p))
      (forward-line 1))
    (point)))

(defun xwiki-table-end ()
  "Find the end of the table and return its position.
The end of the table is the first character of the next line, just outside the
table.  This function assumes point is on a table."
  (save-excursion
    ;; Keep going down until we're out of the table
    (while (and (not (eobp))
                (xwiki-table-at-point-p))
      (forward-line 1))
    (point)))

(defun xwiki--pad-cell-content (cell-content)
  "Return a trimmed and padded CELL-CONTENT, ready for length measurement."
  (let* ((is-header (string-prefix-p "=" cell-content))
         (actual-content (if is-header (substring cell-content 1) cell-content))
         (trimmed (string-trim actual-content))
         (padded (concat " " trimmed " ")))
    (if is-header (concat "=" padded) padded)))

(defun xwiki--pad-cell-to-length (cell-content desired)
  "Right-pads CELL-CONTENT to length DESIRED.
Assumes that desired >= length of cell-content."
  (let ((padding-length (- desired (length cell-content))))
    (concat cell-content (make-string padding-length ?\s))))

(defun xwiki--align-table (table)
  "Aligns a string, formatted as a TABLE.
Assumes that every row has an equal number of cells"
  (let* ((lines (seq-filter (lambda (s) (> (length s) 0)) (split-string table "\n")))
         (cells-raw (mapcar (lambda (l) (split-string l "|")) lines))
         (cells (mapcar (lambda (l) (mapcar #'xwiki--pad-cell-content l))
                        cells-raw))
         (cell-lengths (mapcar (lambda (l) (mapcar #'length l)) cells))
         (column-maximums (apply #'cl-mapcar #'max cell-lengths))
         (new-rows (mapcar
                    (lambda (l)
                      (string-trim
                       (string-join
                        (cl-mapcar #'xwiki--pad-cell-to-length l column-maximums)
                        "|")))
                    cells)))
    (concat (string-join new-rows "\n") "\n")))

(defun xwiki--table-equalize-column-count (table)
  "Add columns so that all rows of a TABLE has the same number of columns."
  (let* ((lines (seq-filter (lambda (s) (> (length s) 0)) (split-string (string-trim-right table) "\n")))
         (num-cols (mapcar (lambda (l) (cl-count ?| l)) lines))
         (max-num-cols (apply #'max num-cols))
         (new-lines (cl-mapcar (lambda (l cols) (concat l (make-string (- max-num-cols cols) ?|)))
                               lines num-cols)))
    (concat (string-join new-lines "\n") "\n")))

(defun xwiki--table-get-column ()
  "Return column index of point.  Assumes that point is in a table."
  (let ((beginning-to-point (buffer-substring-no-properties (line-beginning-position) (point))))
    (cl-count ?| beginning-to-point)))

(defun xwiki--table-goto-column (n)
  "Move cursor to the Nth column.  Assumes that point is in a table."
  (beginning-of-line)
  (when (> n 0)
    (while (and (> n 0) (not (search-forward "|" (point-at-eol) t n)))
      (cl-decf n)))
  (when (looking-at " ")
    (forward-char)))

(defmacro xwiki--with-gensyms (symbols &rest body)
  "Generate symbols for use in a macro.
SYMBOLS is an unquoted list of symbols, and BODY is where the generated symbols
are used.  with-gensyms that is specifically for use with xwiki."
  (declare (debug (sexp body)) (indent 1))
  `(let ,(mapcar (lambda (s)
                   `(,s (make-symbol (concat "--" (symbol-name ',s)))))
                 symbols)
     ,@body))

(defmacro xwiki-table-save-cell (&rest body)
  "Save cell at point, execute BODY and restore cell.
This function assumes point is on a table."
  (declare (debug (body)))
  (xwiki--with-gensyms (line column)
    `(let ((,line (copy-marker (line-beginning-position)))
           (,column (xwiki--table-get-column)))
       (unwind-protect
           (progn ,@body)
         (goto-char ,line)
         (xwiki--table-goto-column ,column)
         (set-marker ,line nil)))))

(defun xwiki-table-align ()
  "Re-aligns and cleans up table.  Assumes point is in a table."
  (interactive)
  (let* ((begin (xwiki-table-begin))
         (end (xwiki-table-end))
         (table (buffer-substring-no-properties begin end))
         (equalized (xwiki--table-equalize-column-count table))
         (aligned (xwiki--align-table equalized))
         (table-lines (seq-filter (lambda (l) (> (length l) 0)) (split-string table "\n")))
         (aligned-table-lines (split-string aligned "\n")))
    (xwiki-table-save-cell
     (goto-char begin)
     (while table-lines
       (let ((old (pop table-lines))
             (new (pop aligned-table-lines)))
         (if (string= old new)
             (forward-line)
           (insert new "\n")
           (delete-region (point) (line-beginning-position 2))))))))

(defun xwiki-table-blank-line (line)
  "Remove all text in LINE, which is a row in a table."
  (replace-regexp-in-string (rx (not "|")) " " line))

(defun xwiki-table-insert-row (&optional arg)
  "Insert a new row above the row at point into the table.
With optional argument ARG, insert below the current row."
  (interactive "P")
  (unless (xwiki-table-at-point-p)
    (user-error "Not at a table"))
  (let* ((line (buffer-substring
                (line-beginning-position) (line-end-position)))
         (new (xwiki-table-blank-line line)))
    (beginning-of-line (if arg 2 1))
    (unless (bolp) (insert "\n"))
    (insert-before-markers new "\n")
    (beginning-of-line 0)
    (re-search-forward "| ?" (line-end-position) t)))

(defun xwiki-table-next-row ()
  "Go to the next row (same column) in the table.
Create new table lines if required."
  (interactive)
  (unless (xwiki-table-at-point-p)
    (user-error "Not at a table"))
  (if (or (looking-at "[ \t]*$")
          (save-excursion (skip-chars-backward " \t") (bolp)))
      (newline)
    (xwiki-table-align)
    (let ((col (xwiki--table-get-column)))
      (beginning-of-line 2)
      (if (not (xwiki-table-at-point-p))
          (progn
            (beginning-of-line 0)
            (xwiki-table-insert-row 'below)))
      (xwiki--table-goto-column col)
      (skip-chars-backward "^|\n\r")
      (when (looking-at " ") (forward-char 1)))))

(defun xwiki--table-normalize-position-in-cell ()
  "Normalize position in cell by navigating to just after the first space."
  (cond ((looking-at-p " ") (forward-char))
        ((looking-at-p "\n") (insert " "))
        ((looking-at-p (rx (or "=" "|")))
         (progn (forward-char) (xwiki--table-normalize-position-in-cell)))))

(defun xwiki-table-forward-cell ()
  "Go to the next cell in the table.
Create new table lines if required."
  (interactive)
  (unless (xwiki-table-at-point-p)
    (user-error "Not at a table"))
  (xwiki-table-align)
  (xwiki--table-normalize-position-in-cell)
  (let ((end (xwiki-table-end)))
    (if (search-forward "|" end t)
        (xwiki--table-normalize-position-in-cell)
      (xwiki-table-insert-row 'below))))

(defun xwiki-table-backward-cell ()
  "Go to the previous cell in the table."
  (interactive)
  (unless (xwiki-table-at-point-p)
    (user-error "Not at a table"))
  (xwiki-table-align)
  (xwiki--table-normalize-position-in-cell)
  (let ((beginning (xwiki-table-begin)))
    (re-search-backward (rx (and "|" (minimal-match (one-or-more anything)) "|")) beginning t))
  (xwiki--table-normalize-position-in-cell))

;;; xwiki faces ================================================================

(defgroup xwiki-faces nil
  "Faces used in `xwiki-mode'."
  :group 'xwiki
  :group 'faces)

(defface xwiki-markup-face
  '((t (:inherit shadow :slant normal :weight normal)))
  "Face for markup elements."
  :group 'xwiki-faces)

(defface xwiki-bold-face
  '((t (:inherit bold)))
  "Face for bold text."
  :group 'xwiki-faces)

(defface xwiki-underline-face
  '((t (:inherit underline)))
  "Face for underlined text."
  :group 'xwiki-faces)

(defface xwiki-strike-through-face
  '((t (:strike-through t)))
  "Face for strike-through text."
  :group 'xwiki-faces)

(defface xwiki-italic-face
  '((t (:inherit italic)))
  "Face for italic text."
  :group 'xwiki-faces)

(defface xwiki-code-face
  '((t (:inherit fixed-pitch)))
  "Face for code or monospace text."
  :group 'xwiki-faces)

(defface xwiki-inline-code-face
  '((t (:inherit (xwiki-code-face font-lock-constant-face))))
  "Face for inline code."
  :group 'xwiki-faces)

(defface xwiki-superscript-face
  '((t (:height 0.8)))
  "Face for superscript code."
  :group 'xwiki-faces)

(defface xwiki-subscript-face
  '((t (:height 0.8)))
  "Face for subscript code."
  :group 'xwiki-faces)

(defface xwiki-list-face
  '((t (:inherit xwiki-markup-face)))
  "Face for markup elements."
  :group 'xwiki-faces)

(defface xwiki-definition-list-face
  '((t (:inherit xwiki-markup-face)))
  "Face for markup elements."
  :group 'xwiki-faces)

(defface xwiki-horizontal-line-face
  '((t (:inherit xwiki-markup-face)))
  "Face for markup elements."
  :group 'xwiki-faces)

(defface xwiki-header-face
  '((t (:inherit (variable-pitch font-lock-builtin-face bold))))
  "Base face for headers."
  :group 'xwiki-faces)

(defface xwiki-header-face-1
  '((t (:inherit xwiki-header-face
                 :height 2.0)))
  "Face for header 1."
  :group 'xwiki-faces)

(defface xwiki-header-face-2
  '((t (:inherit xwiki-header-face
                 :height 1.7)))
  "Face for header 2."
  :group 'xwiki-faces)

(defface xwiki-header-face-3
  '((t (:inherit xwiki-header-face
                 :height 1.4)))
  "Face for header 3."
  :group 'xwiki-faces)

(defface xwiki-header-face-4
  '((t (:inherit xwiki-header-face
                 :height 1.1)))
  "Face for header 4."
  :group 'xwiki-faces)

(defface xwiki-header-face-5
  '((t (:inherit xwiki-header-face
                 :height 1.0)))
  "Face for header 5."
  :group 'xwiki-faces)

(defface xwiki-header-face-6
  '((t (:inherit xwiki-header-face
                 :height 1.0)))
  "Face for header 6."
  :group 'xwiki-faces)

(defface xwiki-newline-face
  '((t (:inherit xwiki-markup-face)))
  "Face for newline."
  :group 'xwiki-faces)

(defface xwiki-link-face
  '((t (:inherit link)))
  "Face for links."
  :group 'xwiki-faces)

(defface xwiki-parameter-face
  '((t (:inherit font-lock-type-face)))
  "Face for parameters."
  :group 'xwiki-faces)

(defface xwiki-quotation-face
  '((t (:inherit xwiki-markup-face)))
  "Face for quotations."
  :group 'xwiki-faces)

(defface xwiki-macro-face
  '((t (:inherit font-lock-preprocessor-face)))
  "Face for macro markers."
  :group 'xwiki-faces)

(defface xwiki-table-marker-face
  '((t (:inherit xwiki-markup-face)))
  "Face for table markers."
  :group 'xwiki-faces)

;;; Font lock regexes ==========================================================

(defconst xwiki-regex-bold
  (rx (group "**")
      (group (minimal-match (zero-or-more anything)))
      (group "**")))

(defconst xwiki-regex-underline
  (rx (group "__")
      (group (minimal-match (zero-or-more anything)))
      (group "__")))

(defconst xwiki-regex-italic
  (rx (not ":")
      (group "//")
      (group (minimal-match (zero-or-more anything)))
      (group "//")))

(defconst xwiki-regex-strike-through
  (rx (group "--")
      (group (minimal-match (zero-or-more not-newline)))
      (group "--")))

(defconst xwiki-regex-monospace
  (rx (group "##")
      (group (minimal-match (zero-or-more anything)))
      (group "##")))

(defconst xwiki-regex-superscript
  (rx (group "^^")
      (group (minimal-match (zero-or-more anything)))
      (group "^^")))

(defconst xwiki-regex-subscript
  (rx (group ",,")
      (group (minimal-match (zero-or-more anything)))
      (group ",,")))

(defconst xwiki-regex-list
  (rx (and line-start
           (group (or (and (1+ "1") (0+ "*")  ".")
                      (1+ "*")))
           space)))

(defconst xwiki-regex-definition-list
  (rx (and line-start
           (group (0+ ":")  (or ";" ":"))
           space)))

(defconst xwiki-regex-horizontal-line
  (rx (and line-start
           (group (repeat 4 ?-))
           (0+ space)
           line-end)))

(defconst xwiki-regex-header-1
  (rx (and line-start
           (group (repeat 1 ?=)
                  (not ?=)
                  (zero-or-more not-newline)
                  (repeat 1 ?=))
           (zero-or-more space)
           line-end)))

(defconst xwiki-regex-header-2
  (rx (and line-start
           (group (repeat 2 ?=)
                  (not ?=)
                  (zero-or-more not-newline)
                  (repeat 2 ?=))
           (zero-or-more space)
           line-end)))

(defconst xwiki-regex-header-3
  (rx (and line-start
           (group (repeat 3 ?=)
                  (not ?=)
                  (zero-or-more not-newline)
                  (repeat 3 ?=))
           (zero-or-more space)
           line-end)))

(defconst xwiki-regex-header-4
  (rx (and line-start
           (group (repeat 4 ?=)
                  (not ?=)
                  (zero-or-more not-newline)
                  (repeat 4 ?=))
           (zero-or-more space)
           line-end)))

(defconst xwiki-regex-header-5
  (rx (and line-start
           (group (repeat 5 ?=)
                  (not ?=)
                  (zero-or-more not-newline)
                  (repeat 5 ?=))
           (zero-or-more space)
           line-end)))

(defconst xwiki-regex-header-6
  (rx (and line-start
           (group (repeat 6 ?=)
                  (not ?=)
                  (zero-or-more not-newline)
                  (repeat 6 ?=))
           (zero-or-more space)
           line-end)))

(defconst xwiki-regex-newline
  (rx (group "\\")))

(defconst xwiki-regex-anchor-link
  (rx (and (group "[[")
           (minimal-match (zero-or-more not-newline))
           (group "]]"))))

(defconst xwiki-regex-parameter
  (rx (and (group "(%")
           (group (minimal-match (zero-or-more not-newline)))
           (group "%)"))))

(defconst xwiki-regex-quotation
  (rx (and line-start
           (group (0+ ">"))
           space)))

(defconst xwiki-regex-group-start
  (rx "((("))

(defconst xwiki-regex-group-end
  (rx ")))"))

(defconst xwiki-regex-macro
  (rx (group "{{" (optional ?/))
      (group (minimal-match (one-or-more not-newline)))
      (group (optional ?/) "}}")))

(defconst xwiki-regex-table-marker
  (rx (and (or (not "|") line-start) (group "|" (optional ?=)) (not "|"))))

;;; Font lock keywords =========================================================

(defvar xwiki-mode-font-lock-keywords
  `((,xwiki-regex-header-1 . ((1 'xwiki-header-face-1)))
    (,xwiki-regex-header-2 . ((1 'xwiki-header-face-2)))
    (,xwiki-regex-header-3 . ((1 'xwiki-header-face-3)))
    (,xwiki-regex-header-4 . ((1 'xwiki-header-face-4)))
    (,xwiki-regex-header-5 . ((1 'xwiki-header-face-5)))
    (,xwiki-regex-header-6 . ((1 'xwiki-header-face-6)))
    (,xwiki-regex-horizontal-line . ((1 'xwiki-horizontal-line-face)))
    (,xwiki-regex-bold . ((1 'xwiki-markup-face)
                          (2 'xwiki-bold-face)
                          (3 'xwiki-markup-face)))
    (,xwiki-regex-italic . ((1 'xwiki-markup-face)
                            (2 'xwiki-italic-face)
                            (3 'xwiki-markup-face)))
    (,xwiki-regex-strike-through . ((1 'xwiki-markup-face)
                                    (2 'xwiki-strike-through-face)
                                    (3 'xwiki-markup-face)))
    (,xwiki-regex-monospace . ((1 'xwiki-markup-face)
                               (2 'xwiki-inline-code-face)
                               (3 'xwiki-markup-face)))
    (,xwiki-regex-underline . ((1 'xwiki-markup-face)
                               (2 'xwiki-underline-face)
                               (3 'xwiki-markup-face)))
    (,xwiki-regex-subscript . ((1 'xwiki-markup-face)
                               (2 'xwiki-subscript-face)
                               (3 'xwiki-markup-face)))
    (,xwiki-regex-superscript . ((1 'xwiki-markup-face)
                                 (2 '(face xwiki-superscript-face display (raise 0.3)))
                                 (3 'xwiki-markup-face)))
    (,xwiki-regex-list . ((1 'xwiki-list-face)))
    (,xwiki-regex-definition-list . ((1 'xwiki-definition-list-face)))
    (,xwiki-regex-newline . ((1 'xwiki-newline-face)))
    (,xwiki-regex-anchor-link
     (1 'xwiki-markup-face)
     (2 'xwiki-markup-face)
     (,(rx (and "[["
                (group (minimal-match (one-or-more not-newline)))
                (group (or ">>" "||" "]]"))))
      (re-search-backward (rx "[[")) nil
      (1 'xwiki-link-face) (2 'xwiki-markup-face)))
    (,xwiki-regex-parameter . ((0 'xwiki-parameter-face)))
    (,xwiki-regex-quotation . ((1 'xwiki-quotation-face)))
    (,xwiki-regex-group-start . ((0 'xwiki-markup-face)))
    (,xwiki-regex-group-end . ((0 'xwiki-markup-face)))
    (,xwiki-regex-macro . ((1 'xwiki-markup-face)
                           (2 'xwiki-macro-face)
                           (3 'xwiki-markup-face)))
    (,xwiki-regex-table-marker . ((1 'xwiki-table-marker-face)))))

;;; Key mappings and functions =================================================

(defun xwiki-enter-key ()
  "Handle RET depending on the context."
  (interactive)
  (cond
   ((xwiki-table-at-point-p)
    (call-interactively #'xwiki-table-next-row))
   (t (newline))))

(defun xwiki-tab-key ()
  "Handle TAB depending on the context."
  (interactive)
  (message "tab")
  (cond
   ((xwiki-table-at-point-p)
    (call-interactively #'xwiki-table-forward-cell))
   (t (indent-for-tab-command))))

(defun xwiki-shift-tab-key ()
  "Handle SHIFT-TAB depending on the context."
  (interactive)
  (message "shift-tab")
  (when (xwiki-table-at-point-p)
    (call-interactively #'xwiki-table-backward-cell)))

(defvar xwiki-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'xwiki-enter-key)
    (define-key map (kbd "TAB") 'xwiki-tab-key)
    (define-key map (kbd "<backtab>") 'xwiki-shift-tab-key)
    map)
  "Keymap for Xwiki major mode.")

;;; Declaring derived mode =====================================================

(eval-when-compile
  (defconst xwiki-syntax-propertize-rules
    (syntax-propertize-precompile-rules
     ("\\({\\){{" (1 "< b"))
     ("}}\\(}\\)" (1 "> b")))))

;;;###autoload
(add-to-list 'auto-mode-alist
             '("\\.xwiki$" . xwiki-mode))

;;;###autoload
(define-derived-mode xwiki-mode text-mode "XWiki"
  "Major mode for editing XWiki files."

  (setq-local comment-start "{{{")
  (setq-local comment-end "}}}")

  (setq-local syntax-propertize-function (syntax-propertize-rules xwiki-syntax-propertize-rules))

  (setq-local font-lock-defaults '(xwiki-mode-font-lock-keywords)))

;; AWESOME blogposts/references on writing a major mode
;; https://fuco1.github.io/2017-06-01-The-absolute-awesomeness-of-anchored-font-lock-matchers.html
;; https://futureboy.us/frinktools/emacs/frink-mode.el

(provide 'xwiki-mode)
;;; xwiki-mode.el ends here
