;;; basic-mode.el --- Major mode for editing BASIC code  -*- lexical-binding: t -*-

;; Copyright (C) 2017-2023 Johan Dykstrom

;; Author: Johan Dykstrom
;; Created: Sep 2017
;; Version: 1.0.2
;; Package-Version: 20230114.1556
;; Package-Commit: 8b987cfa5b4ccf4822afa4eb2036f9f603fa5b1b
;; Keywords: basic, languages
;; URL: https://github.com/dykstrom/basic-mode
;; Package-Requires: ((seq "2.20") (emacs "25.1"))

;; This program is free software: you can redistribute it and/or modify
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

;; This package provides a major mode for editing BASIC code.  Features
;; include syntax highlighting and indentation, as well as support for
;; auto-numbering and renumering of code lines.
;;
;; The base mode provides basic functionality and is normally only used
;; to derive sub modes for different BASIC dialects, see for example
;; `basic-generic-mode'.  For a list of available sub modes, please see
;; https://github.com/dykstrom/basic-mode, or the end of the source code
;; file.
;;
;; By default, basic-mode will open BASIC files in the generic sub mode.
;; To change this, you can use a file variable, or associate BASIC files
;; with another sub mode in `auto-mode-alist'.
;;
;; You can format the region, or the entire buffer, by typing C-c C-f.
;;
;; When line numbers are turned on, hitting the return key will insert
;; a new line starting with a fresh line number.  Typing C-c C-r will
;; renumber all lines in the region, or the entire buffer, including
;; any jumps in the code.
;;
;; Type M-. to lookup the line number, label, or variable at point,
;; and type M-, to go back again.  See also function
;; `xref-find-definitions'.

;; Installation:

;; The recommended way to install basic-mode is from MELPA, please see
;; https://melpa.org.
;;
;; To install manually, place basic-mode.el in your load-path, and add
;; the following lines of code to your init file:
;;
;; (autoload 'basic-generic-mode "basic-mode" "Major mode for editing BASIC code." t)
;; (add-to-list 'auto-mode-alist '("\\.bas\\'" . basic-generic-mode))

;; Configuration:

;; You can customize the indentation of code blocks, see variable
;; `basic-indent-offset'.  The default value is 4.
;;
;; Formatting is also affected by the customizable variables
;; `basic-delete-trailing-whitespace' and `delete-trailing-lines'
;; (from simple.el).
;;
;; You can also customize the number of columns to allocate for
;; line numbers using the variable `basic-line-number-cols'. The
;; default value of 0 (no space reserved), is appropriate for
;; programs with no line numbers and for left aligned numbering.
;; Use a positive integer, such as 6, if you prefer right alignment.
;;
;; The other line number features can be configured by customizing
;; the variables `basic-auto-number', `basic-renumber-increment' and
;; `basic-renumber-unnumbered-lines'.
;;
;; Whether syntax highlighting requires separators between keywords can be
;; customized with variable `basic-syntax-highlighting-require-separator'.

;;; Change Log:

;;  1.0.2  2023-01-14  Fix compile warnings for Emacs 29.
;;  1.0.1  2023-01-07  Fix renumber and add extra keywords.
;;  1.0.0  2022-12-17  Add support for BASIC dialects using derived modes.
;;                     Thanks to hackerb9.
;;  0.6.2  2022-11-12  Renumber and goto line number without separators.
;;  0.6.1  2022-11-05  Fix syntax highlighting next to operators.
;;  0.6.0  2022-10-22  Syntax highlighting without separators.
;;  0.5.0  2022-10-15  Breaking a comment creates a new comment line.
;;  0.4.6  2022-09-17  Auto-numbering handles digits after point.
;;  0.4.5  2022-09-10  Fix docs and REM syntax.
;;                     Thanks to hackerb9.
;;  0.4.4  2022-08-23  Auto-numbering without line-number-cols.
;;  0.4.3  2021-03-16  Improved indentation with tabs.
;;                     Thanks to Jeff Spaulding.
;;  0.4.2  2018-09-19  Lookup of dimmed variables.
;;  0.4.1  2018-06-12  Highlighting, indentation and lookup of labels.
;;  0.4.0  2018-05-25  Added goto line number.
;;  0.3.3  2018-05-17  Fixed endless loop bug.
;;  0.3.2  2017-12-04  Indentation of one-line-loops.
;;  0.3.1  2017-11-25  Renumbering on-goto and bug fixes.
;;  0.3.0  2017-11-20  Auto-numbering and renumbering support.
;;                     Thanks to Peder O. Klingenberg.
;;  0.2.0  2017-10-27  Format region/buffer.
;;  0.1.3  2017-10-11  Even more syntax highlighting.
;;  0.1.2  2017-10-04  More syntax highlighting.
;;  0.1.1  2017-10-02  Fixed review comments and autoload problems.
;;  0.1.0  2017-09-28  Initial version.

;;; Code:

(require 'simple)
(require 'seq)

;; ----------------------------------------------------------------------------
;; Customization:
;; ----------------------------------------------------------------------------

(defgroup basic nil
  "Major mode for editing BASIC code."
  :link '(emacs-library-link :tag "Source File" "basic-mode.el")
  :group 'languages)

(defcustom basic-mode-hook nil
  "*Hook run when entering BASIC mode."
  :type 'hook
  :group 'basic)

(defcustom basic-indent-offset 4
  "*Specifies the indentation offset for `basic-indent-line'.
Statements inside a block are indented this number of columns."
  :type 'integer
  :group 'basic)

(defcustom basic-line-number-cols 0
  "*Specifies the number of columns to allocate to line numbers.
This number includes the single space between the line number and
the actual code. Leave this variable at 0 if you do not use line
numbers or if you prefer left aligned numbering. A positive value
adds sufficient padding to right align a line number and add a
space afterward. The value 6 is reasonable for older dialects of
BASIC which used at most five digits for line numbers."
  :type 'integer
  :group 'basic)

(defcustom basic-delete-trailing-whitespace t
  "*Delete trailing whitespace while formatting code."
  :type 'boolean
  :group 'basic)

(defcustom basic-auto-number nil
  "*Specifies auto-numbering increments.
If nil, auto-numbering is turned off.  If not nil, this should be an
integer defining the increment between line numbers, 10 is a traditional
choice."
  :type '(choice (const :tag "Off" nil)
         integer)
  :group 'basic)

(defcustom basic-renumber-increment 10
  "*Default auto-numbering increment."
  :type 'integer
  :group 'basic)

(defcustom basic-renumber-unnumbered-lines t
  "*If non-nil, lines without line numbers are also renumbered.
If nil, lines without line numbers are left alone.  Completely
empty lines are never numbered."
  :type 'boolean
  :group 'basic)

(defcustom basic-syntax-highlighting-require-separator t
  "*If non-nil, only keywords separated by symbols will be highlighted.
If nil, the default, keywords separated by numbers will also be highlighted."
  :type 'boolean
  :group 'basic)

;; ----------------------------------------------------------------------------
;; Variables:
;; ----------------------------------------------------------------------------

(defconst basic-mode-version "1.0.2"
  "The current version of `basic-mode'.")

(defvar-local basic-increase-indent-keywords-bol
  '("for")
  "List of keywords that increase indentation.
These keywords increase indentation when found at the
beginning of a line.")
(defvar-local basic-increase-indent-keywords-bol-regexp nil)

(defvar-local basic-increase-indent-keywords-eol
  '("else" "then")
  "List of keywords that increase indentation.
These keywords increase indentation when found at the
end of a line.")
(defvar-local basic-increase-indent-keywords-eol-regexp nil)

(defvar-local basic-decrease-indent-keywords-bol
  '("else" "end" "next")
  "List of keywords that decrease indentation.
These keywords decrease indentation when found at the
beginning of a line or after a statement separator (:).")
(defvar-local basic-decrease-indent-keywords-bol-regexp nil)

(defvar-local basic-comment-and-string-faces
  '(font-lock-comment-face font-lock-comment-delimiter-face font-lock-string-face)
  "List of font-lock faces used for comments and strings.")

(defvar-local basic-comment-regexp
  "\\_<rem\\_>.*\n"
  "Regexp string that matches a comment until the end of the line.")

(defvar-local basic-linenum-regexp
  "^[ \t]*\\([0-9]+\\)"
  "Regexp string of symbols to highlight as line numbers.")

(defvar-local basic-label-regexp
  "^[ \t]*\\([a-zA-Z][a-zA-Z0-9_.]*:\\)"
  "Regexp string of symbols to highlight as labels.")

(defvar-local basic-constants
  nil
  "List of symbols to highlight as constants.")

(defvar-local basic-functions
  '("abs" "asc" "atn" "chr$" "cos" "exp" "int" "len" "log"
    "pi" "rnd" "sgn" "sin" "sqr" "str$" "tab" "tan" "val")
  "List of symbols to highlight as functions.")

(defvar-local basic-builtins
  '("and" "cls" "data" "input" "let" "mod" "not" "or"
    "peek" "poke" "print" "read" "restore" "xor")
  "List of symbols to highlight as builtins.")

(defvar-local basic-keywords
  '("def fn" "dim" "else" "end" "error" "exit"
    "for" "gosub" "go sub" "goto" "go to" "if" "next"
    "on" "step" "randomize" "return" "then" "to")
  "List of symbols to highlight as keywords.")

(defvar-local basic-types
  nil
  "List of symbols to highlight as types.")

(defvar-local basic-font-lock-keywords
  nil
  "Describes how to syntax highlight keywords in `basic-mode' buffers.
This is initialized by `basic-mode-initialize' from lists that may be
modified in derived submodes.")

(defvar-local basic-font-lock-syntax
  '(("0123456789" . "."))
  "Syntax alist used to set the Font Lock syntax table.
This syntax table is used to highlight keywords adjacent to numbers,
e.g. GOTO10. See `basic-syntax-highlighting-require-separator'.")

;; ----------------------------------------------------------------------------
;; Indentation:
;; ----------------------------------------------------------------------------

(defun basic-indent-line ()
  "Indent the current line of code, see function `basic-calculate-indent'."
  (interactive)
  ;; If line needs indentation
  (when (or (not (basic-line-number-indented-correctly-p))
            (not (basic-code-indented-correctly-p)))
    ;; Set basic-line-number-cols to reflect the actual code
    (let* ((actual-line-number-cols
            (if (not (basic-has-line-number-p))
                0
              (let ((line-number (basic-current-line-number)))
                (1+ (length (number-to-string line-number))))))
           (basic-line-number-cols
            (max actual-line-number-cols basic-line-number-cols)))
      ;; Calculate new indentation
      (let* ((original-col (- (current-column) basic-line-number-cols))
             (original-indent-col (basic-current-indent))
             (calculated-indent-col (basic-calculate-indent)))
        (basic-indent-line-to calculated-indent-col)
        (move-to-column (+ calculated-indent-col
                           (max (- original-col original-indent-col) 0)
                           basic-line-number-cols))))))

(defun basic-calculate-indent ()
  "Calculate the indent for the current line of code.
The current line is indented like the previous line, unless inside a block.
Code inside a block is indented `basic-indent-offset' extra characters."
  (let ((previous-indent-col (basic-previous-indent))
        (increase-indent (basic-increase-indent-p))
        (decrease-indent (basic-decrease-indent-p))
        (label (basic-label-p)))
    (if label
        0
      (max 0 (+ previous-indent-col
                (if increase-indent basic-indent-offset 0)
                (if decrease-indent (- basic-indent-offset) 0))))))

(defun basic-label-p ()
  "Return non-nil if current line does start with a label."
  (save-excursion
    (goto-char (line-beginning-position))
    (looking-at basic-label-regexp)))

(defun basic-comment-or-string-p ()
  "Return non-nil if point is in a comment or string."
  (let ((faces (get-text-property (point) 'face)))
    (unless (listp faces)
      (setq faces (list faces)))
    (seq-some (lambda (x) (memq x faces)) basic-comment-and-string-faces)))

(defun basic-comment-p ()
  "Return non-nil if point is in a comment."
  (let ((comment-or-string (car (basic-comment-or-string-p))))
    (or (equal comment-or-string font-lock-comment-face)
        (equal comment-or-string font-lock-comment-delimiter-face))))

(defun basic-comment-lead ()
  "Return the comment lead of the comment at point.
If the point is not in a comment, return nil."
  (when (basic-comment-p)
    (save-excursion
      (while (and (not (bolp)) (basic-comment-p))
        (forward-char -1))
      (let ((case-fold-search t))
        (when (re-search-forward "'\\|rem" nil t)
          (match-string 0))))))

(defun basic-code-search-backward ()
  "Search backward from point for a line containing code."
  (beginning-of-line)
  (skip-chars-backward " \t\n")
  (while (and (not (bobp)) (or (basic-comment-or-string-p) (basic-label-p)))
    (skip-chars-backward " \t\n")
    (when (not (bobp))
      (forward-char -1))))

(defun basic-match-symbol-at-point-p (regexp)
  "Return non-nil if the symbol at point does match REGEXP."
  (let ((symbol (symbol-at-point))
        (case-fold-search t))
    (when symbol
      (string-match regexp (symbol-name symbol)))))

(defun basic-increase-indent-p ()
  "Return non-nil if indentation should be increased.
Some keywords trigger indentation when found at the end of a line,
while other keywords do it when found at the beginning of a line."
  (save-excursion
    (basic-code-search-backward)
    (unless (bobp)
      ;; Keywords at the end of the line
      (if (basic-match-symbol-at-point-p basic-increase-indent-keywords-eol-regexp)
          't
        ;; Keywords at the beginning of the line
        (beginning-of-line)
        (re-search-forward "[^0-9 \t\n]" (line-end-position) t)
        (basic-match-symbol-at-point-p basic-increase-indent-keywords-bol-regexp)))))

(defun basic-decrease-indent-p ()
  "Return non-nil if indentation should be decreased.
Some keywords trigger un-indentation when found at the beginning
of a line or statement, see `basic-decrease-indent-keywords-bol'."
  (save-excursion
    (beginning-of-line)
    (re-search-forward "[^0-9 \t\n]" (line-end-position) t)
    (or (basic-match-symbol-at-point-p basic-decrease-indent-keywords-bol-regexp)
        (let ((match nil))
          (basic-code-search-backward)
          (beginning-of-line)
          (while (and (not match)
                      (re-search-forward ":[ \t\n]*" (line-end-position) t))
            (setq match (basic-match-symbol-at-point-p basic-decrease-indent-keywords-bol-regexp)))
          match))))

(defun basic-current-indent ()
  "Return the indent column of the current code line.
The columns allocated to the line number are ignored."
  (save-excursion
    (beginning-of-line)
    ;; Skip line number and spaces
    (skip-chars-forward "0-9 \t" (line-end-position))
    (- (current-column) basic-line-number-cols)))

(defun basic-previous-indent ()
  "Return the indent column of the previous code line.
The columns allocated to the line number are ignored.
If the current line is the first line, then return 0."
  (save-excursion
    (basic-code-search-backward)
    (cond ((bobp) 0)
          (t (basic-current-indent)))))

(defun basic-line-number-indented-correctly-p ()
  "Return non-nil if line number is indented correctly.
If there is no line number, also return non-nil."
  (save-excursion
    (if (not (basic-has-line-number-p))
        t
      (beginning-of-line)
      (skip-chars-forward " \t" (line-end-position))
      (skip-chars-forward "0-9" (line-end-position))
      (and (looking-at "[ \t]")
           (= (point) (+ (line-beginning-position) basic-line-number-cols -1))))))

(defun basic-code-indented-correctly-p ()
  "Return non-nil if code is indented correctly."
  (save-excursion
    (let ((original-indent-col (basic-current-indent))
          (calculated-indent-col (basic-calculate-indent)))
      (= original-indent-col calculated-indent-col))))

(defun basic-has-line-number-p ()
  "Return non-nil if the current line has a line number."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t" (line-end-position))
    (looking-at "[0-9]")))

(defun basic-remove-line-number ()
  "Remove and return the line number of the current line.
After calling this function, the current line will begin with the first
non-blank character after the line number."
  (if (not (basic-has-line-number-p))
      ""
    (beginning-of-line)
    (re-search-forward "\\([0-9]+\\)" (line-end-position) t)
    (let ((line-number (match-string-no-properties 1)))
      (delete-region (line-beginning-position) (match-end 1))
      line-number)))

(defun basic-format-line-number (number)
  "Format NUMBER as a line number."
  (if (= basic-line-number-cols 0)
      number
    (format (concat "%" (number-to-string (- basic-line-number-cols 1)) "s ") number)))

(defun basic-indent-line-to (column)
  "Indent current line to COLUMN, also considering line numbers."
  ;; Remove line number
  (let* ((line-number (basic-remove-line-number))
         (formatted-number (basic-format-line-number line-number)))
    ;; Indent line
    (indent-line-to column)
    ;; Add line number again
    (beginning-of-line)
    (insert formatted-number)))

(defun basic-electric-colon ()
  "Insert a colon and re-indent line."
  (interactive)
  (insert ?\:)
  (when (not (basic-comment-or-string-p))
    (basic-indent-line)))

;; ----------------------------------------------------------------------------
;; Formatting:
;; ----------------------------------------------------------------------------

(defun basic-delete-trailing-whitespace-line ()
  "Delete any trailing whitespace on the current line."
  (beginning-of-line)
  (when (re-search-forward "\\s-*$" (line-end-position) t)
    (replace-match "")))

(defun basic-format-code ()
  "Format all lines in region, or entire buffer if region is not active.
Indent lines, and also remove any trailing whitespace if the
variable `basic-delete-trailing-whitespace' is non-nil.

If this command acts on the entire buffer it also deletes all
trailing lines at the end of the buffer if the variable
`delete-trailing-lines' is non-nil."
  (interactive)
  (let* ((entire-buffer (not (use-region-p)))
         (point-start (if (use-region-p) (region-beginning) (point-min)))
         (point-end (if (use-region-p) (region-end) (point-max)))
         (line-end (line-number-at-pos point-end)))

    (save-excursion
      ;; Don't format last line if region ends on first column
      (goto-char point-end)
      (when (= (current-column) 0)
        (setq line-end (1- line-end)))

      ;; Loop over all lines and format
      (goto-char point-start)
      (while (and (<= (line-number-at-pos) line-end) (not (eobp)))
        (basic-indent-line)
        (when basic-delete-trailing-whitespace
          (basic-delete-trailing-whitespace-line))
        (forward-line))

      ;; Delete trailing empty lines
      (when (and entire-buffer
                 delete-trailing-lines
                 (= (point-max) (1+ (buffer-size)))) ;; Really end of buffer?
        (goto-char (point-max))
        (backward-char)
        (while (eq (char-before) ?\n)
          (delete-char -1))))))

;; ----------------------------------------------------------------------------
;; Line numbering:
;; ----------------------------------------------------------------------------

(defun basic-current-line-number ()
  "Return line number of current line, or nil if no line number."
  (save-excursion
    (when (basic-has-line-number-p)
      (beginning-of-line)
      (re-search-forward "\\([0-9]+\\)" (line-end-position) t)
      (let ((line-number (match-string-no-properties 1)))
        (string-to-number line-number)))))

(defun basic-looking-at-line-number-p (line-number)
  "Return non-nil if text after point matches LINE-NUMBER."
  (and line-number
       (looking-at (concat "[ \t]*" (int-to-string line-number)))
       (looking-back "^[ \t]*" nil)))

(defun basic-newline-and-number ()
  "Insert a newline and indent to the proper level.
If the current line starts with a line number, and auto-numbering is
turned on (see `basic-auto-number'), insert the next automatic number
in the beginning of the line.

If opening a new line between two numbered lines, and the next
automatic number would be >= the line number of the existing next
line, we try to find a midpoint between the two existing lines
and use that as the next number.  If no more unused line numbers
are available between the existing lines, just increment by one,
even if that creates overlaps."
  (interactive)
  (let* ((current-column (current-column))
         (current-line-number (basic-current-line-number))
         (before-line-number (basic-looking-at-line-number-p current-line-number))
         (next-line-number (save-excursion
                             (end-of-line)
                             (and (forward-word 1)
                                  (basic-current-line-number))))
         (new-line-number (and current-line-number
                               basic-auto-number
                               (+ current-line-number basic-auto-number)))
         (comment-lead (basic-comment-lead)))
    (basic-indent-line)
    (newline)
    (when (and next-line-number
               new-line-number
               (<= next-line-number new-line-number))
      (setq new-line-number
            (+ current-line-number
               (truncate (- next-line-number current-line-number) 2)))
      (when (= new-line-number current-line-number)
        (setq new-line-number (1+ new-line-number))))
    (unless before-line-number
      (if new-line-number
          (insert (concat (int-to-string new-line-number) " ")))
      (if (and comment-lead
               (not (eolp))
               (not (looking-at comment-lead)))
          (insert (concat comment-lead " "))))
    (basic-indent-line)
    ;; If the point was before the line number we want it to stay there
    (if before-line-number
        (move-to-column current-column))))

(defvar basic-jump-identifiers
  (regexp-opt '("edit" "else"
                "erl =" "erl <>" "erl >=" "erl <=" "erl >" "erl <"
                "gosub" "go sub" "goto" "go to"
                "list" "llist" "restore" "resume" "return" "run" "then"))
  "Regexp that matches identifiers that identifies jumps in the code.")

(defun basic-find-jumps ()
  "Find all jump targets and the jump statements that jump to them.
This returns a hash with line numbers for keys.  The value of each entry
is a list containing markers to each jump point (the number following a
GOTO, GOSUB, etc.) that jumps to this line number."
  (let* ((jump-targets (make-hash-table))
         (separator (if basic-syntax-highlighting-require-separator "[ \t]+" "[ \t]*"))
         (regexp (concat basic-jump-identifiers separator)))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward regexp nil t)
        (while (looking-at "\\([0-9]+\\)\\([ \t]*[,-][ \t]*\\)?")
          (let* ((target-string (match-string-no-properties 1))
                 (target (string-to-number target-string))
                 (jmp-marker (copy-marker (+ (point) (length target-string)))))
            (unless (gethash target jump-targets)
              (puthash target nil jump-targets))
            (push jmp-marker (gethash target jump-targets))
            (forward-char (length (match-string 0)))))))
    jump-targets))

(defun basic-renumber (start increment)
  "Renumbers the lines of the buffer or region.
The new numbers begin with START and use INCREMENT between
line numbers.

START defaults to the line number at the start of buffer or
region.  If no line number is present there, it uses
`basic-renumber-increment' as a fallback starting point.

INCREMENT defaults to `basic-renumber-increment'.

Jumps in the code are updated with the new line numbers.

If the region is active, only lines within the region are
renumbered, but jumps into the region are updated to match the
new numbers even if the jumps are from outside the region.

No attempt is made to ensure unique line numbers within the
buffer if only the active region is renumbered.

If `basic-renumber-unnumbered-lines' is non-nil, all non-empty
lines will get numbers.  If it is nil, only lines that already
have numbers are included in the renumbering."
  (interactive
   (list (let ((default (save-excursion
                          (goto-char (if (use-region-p)
                                         (region-beginning)
                                       (point-min)))
                          (or (basic-current-line-number)
                              basic-renumber-increment))))
           (string-to-number (read-string
                              (format "Renumber, starting with (default %d): " default)
                              nil nil
                              (int-to-string default))))
         (string-to-number (read-string
                            (format "Increment (default %d): " basic-renumber-increment)
                            nil nil
                            (int-to-string basic-renumber-increment)))))
  (if (zerop basic-line-number-cols)
      (message "No room for numbers.  Please adjust `basic-line-number-cols'.")
    (let ((new-line-number start)
          (jump-list (basic-find-jumps))
          (point-start (if (use-region-p) (region-beginning) (point-min)))
          (point-end (if (use-region-p) (copy-marker (region-end)) (copy-marker (point-max)))))
      (save-excursion
        (goto-char point-start)
        (while (< (point) point-end)
          (unless (looking-at "^[ \t]*$")
            (let ((current-line-number (string-to-number (basic-remove-line-number))))
              (when (or basic-renumber-unnumbered-lines
                        (not (zerop current-line-number)))
                (let ((jump-locations (gethash current-line-number jump-list)))
                  (save-excursion
                    (dolist (p jump-locations)
                      (goto-char (marker-position p))
                      (set-marker p nil)
                      (backward-kill-word 1)
                      (insert (int-to-string new-line-number)))))
                (indent-line-to (basic-calculate-indent))
                (beginning-of-line)
                (insert (basic-format-line-number new-line-number))
                (setq new-line-number (+ new-line-number increment)))))
          (forward-line 1)))
      (set-marker point-end nil)
      (maphash (lambda (_target sources)
                 (dolist (m sources)
                   (when (marker-position m)
                     (set-marker m nil))))
               jump-list))))

;; ----------------------------------------------------------------------------
;; Xref backend:
;; ----------------------------------------------------------------------------

(declare-function xref-make "xref" (summary location))
(declare-function xref-make-buffer-location "xref" (buffer point))

(defun basic-xref-backend ()
  "Return the xref backend used by `basic-mode'."
  'basic)

(defun basic-xref-make-xref (summary buffer point)
  "Return a buffer xref object with SUMMARY, BUFFER and POINT."
  (xref-make summary (xref-make-buffer-location buffer point)))

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql basic)))
  (basic-xref-identifier-at-point))

(defun basic-xref-identifier-at-point ()
  "Return the relevant BASIC identifier at point."
  (if basic-syntax-highlighting-require-separator
      (thing-at-point 'symbol t)
    (let ((number (thing-at-point 'number t))
          (symbol (thing-at-point 'symbol t)))
      (if number
          (number-to-string number)
        symbol))))

(cl-defmethod xref-backend-definitions ((_backend (eql basic)) identifier)
  (basic-xref-find-definitions identifier))

(defun basic-xref-find-definitions (identifier)
  "Find definitions of IDENTIFIER.
Return a list of xref objects with the definitions found.
If no definitions can be found, return nil."
  (let (xrefs)
    (let ((line-number (basic-xref-find-line-number identifier))
          (label (basic-xref-find-label identifier))
          (variables (basic-xref-find-variable identifier)))
      (when line-number
        (push (basic-xref-make-xref (format "%s (line number)" identifier) (current-buffer) line-number) xrefs))
      (when label
        (push (basic-xref-make-xref (format "%s (label)" identifier) (current-buffer) label) xrefs))
      (cl-loop for variable in variables do
            (push (basic-xref-make-xref (format "%s (variable)" identifier) (current-buffer) variable) xrefs))
      xrefs)))

(defun basic-xref-find-line-number (line-number)
  "Return the buffer position where LINE-NUMBER is defined.
If LINE-NUMBER is not found, return nil."
  (save-excursion
    (when (string-match "[0-9]+" line-number)
      (goto-char (point-min))
      (when (re-search-forward (concat "^\\s-*\\(" line-number "\\)\\s-") nil t)
        (match-beginning 1)))))

(defun basic-xref-find-label (label)
  "Return the buffer position where LABEL is defined.
If LABEL is not found, return nil."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward (concat "^\\s-*\\(" label "\\):") nil t)
      (match-beginning 1))))

(defun basic-xref-find-variable (variable)
  "Return a list of buffer positions where VARIABLE is defined.
If VARIABLE is not found, return nil."
  (save-excursion
    (goto-char (point-min))
    (let (positions)
      (while (re-search-forward (concat "\\_<dim\\_>.*\\_<\\(" variable "\\)\\_>") nil t)
        (push (match-beginning 1) positions))
      positions)))

;; ----------------------------------------------------------------------------
;; Word boundaries (based on subword-mode):
;; ----------------------------------------------------------------------------

(defconst basic-find-word-boundary-function-table
  (let ((tab (make-char-table nil)))
    (set-char-table-range tab t #'basic-find-word-boundary)
    tab)
  "Char table of functions to search for the word boundary.
Assigned to `find-word-boundary-function-table' when
`basic-syntax-highlighting-require-separator' is nil; defers to
`basic-find-word-boundary'.")

(defconst basic-empty-char-table
  (make-char-table nil)
  "Char table of functions to search for the word boundary.
Assigned to `find-word-boundary-function-table' when
custom word boundry functionality is not active.")

(defvar basic-forward-function 'basic-forward-internal
  "Function to call for forward movement.")

(defvar basic-backward-function 'basic-backward-internal
  "Function to call for backward movement.")

(defvar basic-alpha-regexp
  "[[:alpha:]$_.]+"
  "Regexp used by `basic-forward-internal' and `basic-backward-internal'.")

(defvar basic-not-alpha-regexp
  "[^[:alpha:]$_.]+"
  "Regexp used by `basic-forward-internal' and `basic-backward-internal'.")

(defvar basic-digit-regexp
  "[[:digit:]]+"
  "Regexp used by `basic-forward-internal' and `basic-backward-internal'.")

(defvar basic-not-digit-regexp
  "[^[:digit:]]+"
  "Regexp used by `basic-forward-internal' and `basic-backward-internal'.")

(defun basic-find-word-boundary (pos limit)
  "Catch-all handler in `basic-find-word-boundary-function-table'.
POS is the buffer position where to start the search.
LIMIT is used to limit the search."
  (let ((find-word-boundary-function-table basic-empty-char-table))
    (save-match-data
      (save-excursion
        (save-restriction
          (goto-char pos)
          (if (< pos limit)
              (progn
                (narrow-to-region (point-min) limit)
                (funcall basic-forward-function))
            (narrow-to-region limit (point-max))
            (funcall basic-backward-function))
          (point))))))

(defun basic-forward-internal ()
  "Default implementation of forward movement."
  (if (and (looking-at basic-alpha-regexp)
           (save-excursion
             (re-search-forward basic-alpha-regexp nil t))
           (> (match-end 0) (point)))
      (goto-char (match-end 0))
    (if (and (looking-at basic-digit-regexp)
             (save-excursion
               (re-search-forward basic-digit-regexp nil t))
             (> (match-end 0) (point)))
        (goto-char (match-end 0)))))


(defun basic-backward-internal ()
  "Default implementation of backward movement."
  (if (and (looking-at basic-alpha-regexp)
           (save-excursion
             (re-search-backward basic-not-alpha-regexp nil t)
             (re-search-forward basic-alpha-regexp nil t))
           (< (match-beginning 0) (point)))
      (goto-char (match-beginning 0))
    (if (and (looking-at basic-digit-regexp)
             (save-excursion
               (re-search-backward basic-not-digit-regexp nil t)
               (re-search-forward basic-digit-regexp nil t))
             (< (match-beginning 0) (point)))
        (goto-char (match-beginning 0)))))

;; ----------------------------------------------------------------------------
;; BASIC mode:
;; ----------------------------------------------------------------------------

(defvar-local basic-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-f" 'basic-format-code)
    (define-key map "\r" 'basic-newline-and-number)
    (define-key map "\C-c\C-r" 'basic-renumber)
    (define-key map ":" 'basic-electric-colon)
    map)
  "Keymap used in ‘basic-mode'.")

(defvar-local basic-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry (cons ?* ?/) ".   " table)   ; Operators * + , - . /
    (modify-syntax-entry (cons ?< ?>) ".   " table)   ; Operators < = >
    (modify-syntax-entry ?'           "<   " table)   ; Comment starts with '
    (modify-syntax-entry ?\n          ">   " table)   ; Comment ends with newline
    (modify-syntax-entry ?\^m         ">   " table)   ;                or carriage return
    table)
  "Syntax table used while in ‘basic-mode'.")

;;;###autoload
(define-derived-mode basic-mode prog-mode "Basic"
  "Major mode for editing BASIC code.

The base mode provides basic functionality and is normally
only used to derive sub modes for different BASIC dialects,
see for example `basic-generic-mode'.

Commands:

\\[indent-for-tab-command] indents for BASIC code.

\\[newline] can automatically insert a fresh line number if
`basic-auto-number' is set.  Default is disabled.

Customization:

You can customize the indentation of code blocks, see variable
`basic-indent-offset'.  The default value is 4.

Formatting is also affected by the customizable variables
`basic-delete-trailing-whitespace' and `delete-trailing-lines'
\(from simple.el).

You can also customize the number of columns to allocate for line
numbers using the variable `basic-line-number-cols'. The default
value of 0, no space reserved, is appropriate for programs with
no line numbers and for left aligned numbering. Use a larger
value if you prefer right aligned numbers. Note that the value
includes the space after the line number, so 6 right aligns
5-digit numbers.

The other line number features can be configured by customizing
the variables `basic-auto-number', `basic-renumber-increment' and
`basic-renumber-unnumbered-lines'.

Whether syntax highlighting requires separators between keywords
can be customized with variable
`basic-syntax-highlighting-require-separator'.

\\{basic-mode-map}"
  :group 'basic
  (add-hook 'xref-backend-functions #'basic-xref-backend nil t)
  (setq-local indent-line-function 'basic-indent-line)
  (setq-local comment-start "REM")
  (setq-local syntax-propertize-function
              (syntax-propertize-rules ("\\(\\_<REM\\_>\\)" (1 "<"))))
  (basic-mode-initialize))

(defun basic-mode-initialize ()
  "Initializations for sub-modes of `basic-mode'.
This is called by `basic-mode' on startup and by its derived modes
after making customizations to font-lock keywords and syntax tables."
  (setq-local basic-increase-indent-keywords-bol-regexp
          (regexp-opt basic-increase-indent-keywords-bol 'symbols))
  (setq-local basic-increase-indent-keywords-eol-regexp
          (regexp-opt basic-increase-indent-keywords-eol 'symbols))
  (setq-local basic-decrease-indent-keywords-bol-regexp
          (regexp-opt basic-decrease-indent-keywords-bol 'symbols))

  (let ((basic-constant-regexp (regexp-opt basic-constants 'symbols))
        (basic-function-regexp (regexp-opt basic-functions 'symbols))
        (basic-builtin-regexp (regexp-opt basic-builtins 'symbols))
        (basic-keyword-regexp (regexp-opt basic-keywords 'symbols))
        (basic-type-regexp (regexp-opt basic-types 'symbols)))
    (setq-local basic-font-lock-keywords
                (list (list basic-comment-regexp 0 'font-lock-comment-face)
                      (list basic-linenum-regexp 0 'font-lock-constant-face)
                      (list basic-label-regexp 0 'font-lock-constant-face)
                      (list basic-constant-regexp 0 'font-lock-constant-face)
                      (list basic-keyword-regexp 0 'font-lock-keyword-face)
                      (list basic-type-regexp 0 'font-lock-type-face)
                      (list basic-function-regexp 0 'font-lock-function-name-face)
                      (list basic-builtin-regexp 0 'font-lock-builtin-face))))

  (if basic-syntax-highlighting-require-separator
      (progn
        (setq-local font-lock-defaults (list basic-font-lock-keywords nil t))
        (setq-local find-word-boundary-function-table basic-empty-char-table))
    (setq-local font-lock-defaults (list basic-font-lock-keywords nil t basic-font-lock-syntax))
    (setq-local find-word-boundary-function-table basic-find-word-boundary-function-table))
  (unless font-lock-mode
    (font-lock-mode 1)))

;; ----------------------------------------------------------------------------
;; Derived modes:
;; ----------------------------------------------------------------------------

;;;###autoload (add-to-list 'auto-mode-alist '("\\.bas\\'" . basic-generic-mode))

;;;###autoload
(define-derived-mode basic-generic-mode basic-qb45-mode "Basic[Generic]"
  "Generic BASIC programming mode.
This is the default mode that will be used if no sub mode is specified.
Derived from `basic-qb45-mode'.  For more information, see `basic-mode'."
  (basic-mode-initialize))

;;;###autoload
(define-derived-mode basic-trs80-mode basic-mode "Basic[TRS-80]"
  "Programming mode for BASIC on the TRS-80 Model I and III.
For the TRS-80 Model 100 BASIC and TRS-80 Color Computer BASIC,
please see `basic-m100-mode` and `basic-coco-mode`.
Derived from `basic-mode'."

  (setq basic-functions
        '("abs" "asc" "atn" "cdbl" "cint" "chr$" "cos" "csng"
          "erl" "err" "exp" "fix" "fre" "inkey$" "inp" "int"
          "left$" "len" "log" "mem" "mid$" "point" "pos"
          "reset" "right$" "set" "sgn" "sin" "sqr" "str$"
          "string$" "tab" "tan" "time$" "usr" "val" "varptr"))

  (setq basic-builtins
        '("?" "auto" "clear" "cload" "cload?" "cls"
          "data" "delete" "edit" "input" "input #" "let"
          "list" "llist" "lprint" "lprint tab" "lprint using"
          "new" "mod" "not" "or" "out" "peek" "poke"
          "print" "print tab" "print using"
          "read" "restore" "resume" "system" "troff" "tron"))

  (setq basic-keywords
        '("as" "call" "defdbl" "defint" "defsng" "defstr"
          "dim" "do" "else" "end" "error" "for"
          "gosub" "goto" "go to" "if" "next" "on"
          "step" "random" "return" "then" "to"))

  ;; Treat ? and # as part of identifier ("cload?" and "input #")
  (modify-syntax-entry ?? "w   " basic-mode-syntax-table)
  (modify-syntax-entry ?# "w   " basic-mode-syntax-table)

  (basic-mode-initialize))

;;;###autoload
(define-derived-mode basic-m100-mode basic-mode "Basic[M100]"
  "Programming mode for BASIC for the TRS-80 Model 100 computer.
Also works for the other Radio-Shack portable computers (the
Tandy 200 and Tandy 102), the Kyocera Kyotronic-85, and the
Olivetti M10. Additionally, although N82 BASIC is slightly
different, the NEC family of portables (PC-8201, PC-8201A, and
PC-8300) are also supported by this mode."

  ;; Notes:

  ;; * M100 BASIC arithmetic and conditional ops probably should not be
  ;;   highlighted at all. They are too common. They are:
  ;;   =, <, >, <=, >=, <>,     +, -, *, /,     \, ^

  ;; * M100 BASIC reserves DEF.* and RAND.*, although they appear to
  ;;   be stubs which do nothing. (Perhaps to allow for future
  ;;   extensions to implement "DEF FN" and "RANDOMIZE"?)

  ;; * The 'FOR' in 'OPEN "FILE" FOR OUTPUT AS #1' is highlighted the
  ;;   same as in FOR loop (a keyword). Should it be?

  ;; * Since FOR is highlighted as a keyword and INPUT as a builtin,
  ;;   it makes sense for now to make AS and NAME both keywords and
  ;;   OUTPUT a builtin just so the syntax highlighting looks right.
  ;;
  ;;        10 FOR T=1 TO 1000
  ;;		20 OPEN "FOO" FOR INPUT AS #1
  ;;		30 OPEN "BAR" FOR OUTPUT AS #2
  ;;		40 NAME "BAZ" AS "QUUX"

  ;; * TODO: strings with embedded spaces ("ON COM GOSUB") should use
  ;;   '\s+' for any amount of white space, but regexp-opt doesn't
  ;;   have a way to do that.

  (setq basic-functions
    '("abs" "asc" "atn" "cdbl" "chr$" "cint" "cos" "csng" "csrlin"
      "date$" "day$" "eof" "erl" "err" "exp" "fix" "fre" "himem"
      "inkey$" "inp" "input$" "instr" "int" "left$" "len" "log" "lpos"
      "maxfiles" "maxram" "mid$" "pos" "right$" "rnd" "sgn" "sin"
      "space$" "sqr" "str$" "string$" "tab" "tan" "time$" "val"
      "varptr"))

  (setq basic-builtins
    '("?" "and" "beep" "clear" "cload" "cload?" "cloadm" "close"
      "cls" "cont" "csave" "csavem" "data" "dski$" "dsko$" "edit"
      "eqv" "files" "imp" "input" "input #" "ipl" "key" "kill"
      "lcopy" "let" "line" "list" "llist" "load" "loadm" "lprint"
      "lprint tab" "lprint using" "menu" "merge" "mod" "motor"
      "name" "new" "not" "open" "or" "out" "output" "peek" "poke"
      "power" "preset" "print" "print @" "print tab" "print using"
      "pset" "read" "restore" "resume" "save" "savem" "screen" "sound"
      "xor"))

  (setq basic-keywords
    '("as" "call" "com" "defdbl" "defint" "defsng" "defstr" "dim"
      "else" "end" "error" "for" "go to" "gosub" "goto" "if" "mdm"
      "next" "off" "on" "on com gosub" "on error goto" "on key gosub"
      "on mdm gosub" "on time$" "random" "return" "run" "runm"
      "sound off" "sound on" "step" "stop" "then"
      "time$ on" "time$ off" "time$ stop" "to"))

  ;; The Model 100 Disk/Video Interface adds a few BASIC commands
  ;; (that actually already exist in the M100 ROM as reserved keywords!)
  ;; "LFILES", "DSKO$", "DSKI$", "LOC", "LOF"
  (setq basic-functions
    (append basic-functions '("loc" "lof")))
  (setq basic-builtins
    (append basic-builtins '("dski$" "dsko$" "lfiles" "width")))

  ;; NEC's N82 BASIC has slightly different keywords, gains some, loses some.
  ;; Change: loadm -> BLOAD, savem -> BSAVE, call -> EXEC, print @ -> LOCATE.
  ;; Gains: BLOAD?

  ;; Adds stubs for: CMD, COLOR, DSKF, FORMAT, STATUS, MAX
  ;; Loses: csavem, day$, def, himem, ipl, lcopy, maxram, mdm
  (setq basic-builtins
    (append basic-builtins '("bload" "bload?" "bsave" "cmd" "color" "dskf"
                 "exec" "format" "locate" "status" "max")))

  ;; NEC PC-8241A CRT adapter for the 8201A has an extended "CRT-BASIC".
  (setq basic-builtins
    (append basic-builtins '("cmd circle" "cmd paint" "color")))
  (setq basic-functions
    (append basic-functions '("status point")))

  ;; Treat ? and # as part of identifier ("cload?" and "input #")
  (modify-syntax-entry ?? "w   " basic-mode-syntax-table)
  (modify-syntax-entry ?# "w   " basic-mode-syntax-table)


  ;; Adapt to coding for a 40 column screen
  (setq-local comment-start "'")    ; Shorter than "REM"
  (setq-local comment-column 16)
  (setq-local fill-column 36)
  (setq-local display-fill-column-indicator-column 40)

  ;; Show an indicator of the Model 100's line width, if possible.
  (condition-case nil
      (display-fill-column-indicator-mode 1)
    (error nil))

  (basic-mode-initialize))


;;;###autoload
(define-derived-mode basic-zx81-mode basic-mode "Basic[ZX81]"
  "Programming mode for BASIC for ZX81 machines.
Derived from `basic-mode'."

  (setq basic-functions
        '("abs" "acs" "and" "asn" "at" "atn" "chr$" "code" "cos" "exp"
          "inkey$" "int" "len" "ln" "not" "or" "peek" "pi" "rnd" "sgn"
          "sin" "sqr" "str$" "tab" "tan" "usr" "val"))

  (setq basic-builtins '("clear" "cls" "copy" "fast" "input" "let"
                         "list" "llist" "load" "lprint" "new" "pause"
                         "plot" "poke" "print" "rand" "run" "save"
                         "scroll" "slow" "unplot"))

  (setq basic-keywords '("dim" "for" "gosub" "goto" "if" "next" "return"
                         "step" "stop" "to"))

  (setq basic-types nil)

  (setq basic-increase-indent-keywords-bol '("for"))
  (setq basic-increase-indent-keywords-eol nil)
  (setq basic-decrease-indent-keywords-bol '("next"))

  (basic-mode-initialize))

;;;###autoload
(define-derived-mode basic-spectrum-mode basic-zx81-mode "Basic[ZX Spectrum]"
  "Programming mode for BASIC for ZX Spectrum machines.
Derived from `basic-zx81-mode'."

  (setq basic-functions
        (append basic-functions '("attr" "bin" "in" "point" "screen$" "val$")))

  (setq basic-builtins
        (append basic-builtins '("beep" "border" "bright" "cat" "cat #"
                                 "circle" "close #" "data" "draw" "erase"
                                 "flash" "format" "ink" "input #" "inverse"
                                 "merge" "move" "open #" "out" "over"
                                 "paper" "print #" "randomize" "read"
                                 "restore" "verify")))
  (setq basic-builtins
        (seq-difference basic-builtins '("fast" "rand" "slow")))

  (setq basic-keywords
        (append basic-keywords '("def fn" "go sub" "go to")))

  ;; Treat # as part of identifier ("open #" etc)
  (modify-syntax-entry ?# "w   " basic-mode-syntax-table)

  (basic-mode-initialize))

;;;###autoload
(define-derived-mode basic-qb45-mode basic-mode "Basic[QB 4.5]"
  "Programming mode for Microsoft QuickBasic 4.5.
Derived from `basic-mode'."

  ;; Notes:

  ;; * DATE$, MID$, PEN, PLAY, SCREEN, SEEK, STRIG, TIMER, and TIME$
  ;;   are both functions and statements, and are only highlighted as
  ;;   one or the other.

  ;; * $DYNAMIC, $INCLUDE, and $STATIC meta commands are not highlighted
  ;;   because they must appear in a comment.

  ;; * LOCAL, and SIGNAL are reserved for future use.

  ;; * The 'FOR' in 'OPEN "FILE" FOR OUTPUT AS #1' is highlighted the
  ;;   same as in FOR loop (a keyword). Should it be?

  (setq basic-functions
        '("abs" "and" "asc" "atn" "cdbl" "chr$" "cint" "clng" "command$"
          "cos" "csng" "csrlin" "cvd" "cvdmbf" "cvi" "cvl" "cvs" "cvsmbf"
          "date$" "environ$" "eof" "eqv" "erdev" "erdev$" "erl" "err"
          "exp" "fileattr" "fix" "fre" "freefile" "hex$" "imp" "inkey$"
          "inp" "input$" "instr" "int" "ioctl$" "lbound" "lcase$" "left$"
          "len" "loc" "lof" "log" "lpos" "ltrim$" "mid$" "mkd$" "mkdmbf$"
          "mki$" "mkl$" "mks$" "mksmbf$" "mod" "not" "oct$" "or" "pmap"
          "point" "pos" "right$" "rnd" "rtrim$" "sadd" "setmem" "sgn"
          "sin" "space$" "spc" "sqr" "stick" "str$" "string$" "tab" "tan"
          "time$" "ubound" "ucase$" "val" "varptr" "varptr$" "varseg"
          "xor"))

  (setq basic-builtins
        '("absolute" "access" "alias" "append" "beep" "binary" "bload"
          "bsave" "byval" "cdecl" "chdir" "circle" "clear" "close"
          "cls" "color" "com" "const" "data" "draw" "environ" "erase"
          "error" "field" "files" "get" "input" "input #" "ioctl"
          "interrupt" "key" "kill" "let" "line" "list" "locate" "lock"
          "lprint" "lset" "mkdir" "name" "open" "out" "output" "paint"
          "palette" "pcopy" "peek" "pen" "play" "poke" "preset" "print"
          "print #" "pset" "put" "random" "randomize" "read" "reset"
          "restore" "rmdir" "rset" "run" "screen" "seek" "shared" "sound"
          "static" "strig" "swap" "timer" "uevent" "unlock" "using" "view"
          "wait" "width" "window" "write" "write #"))

  (setq basic-keywords
        '("as" "call" "calls" "case" "chain" "common" "declare" "def"
          "def seg" "defdbl" "defint" "deflng" "defsng" "defstr" "dim"
          "do" "else" "elseif" "end" "endif" "exit" "for" "fn" "function"
          "gosub" "goto" "if" "is" "loop" "next" "off" "on" "on com"
          "on error" "on key" "on pen" "on play" "on strig" "on timer"
          "on uevent" "option base" "redim" "resume" "return" "select"
          "shell" "sleep" "step" "stop" "sub" "system" "then" "to"
          "type" "until" "wend" "while"))

  (setq basic-types
        '("any" "double" "integer" "long" "single" "string"))

  (setq basic-increase-indent-keywords-bol
        '("case" "do" "for" "function" "repeat" "sub" "select" "while"))
  (setq basic-increase-indent-keywords-eol
        '("else" "then"))
  (setq basic-decrease-indent-keywords-bol
        '("case" "else" "elseif" "end" "loop" "next" "until" "wend"))

  ;; Shorter than "REM"
  (setq-local comment-start "'")

  ;; Treat . and # as part of identifier ("input #" etc)
  (modify-syntax-entry ?. "w   " basic-mode-syntax-table)
  (modify-syntax-entry ?# "w   " basic-mode-syntax-table)

  (basic-mode-initialize))

;; ----------------------------------------------------------------------------

(provide 'basic-mode)

;;; basic-mode.el ends here
