;;; basic-mode.el --- major mode for editing BASIC code

;; Copyright (C) 2017-2021 Johan Dykstrom

;; Author: Johan Dykstrom
;; Created: Sep 2017
;; Version: 0.4.3
;; Package-Version: 20210316.1253
;; Package-Commit: eaa5f24d2fb303d9e5d7de2a28c7c18b01532ab6
;; Keywords: basic, languages
;; URL: https://github.com/dykstrom/basic-mode
;; Package-Requires: ((seq "2.20") (emacs "24.3"))

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
;; You can format the region, or the entire buffer, by typing C-c C-f.
;;
;; When line numbers are turned or, hitting the return key will insert
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
;; (autoload 'basic-mode "basic-mode" "Major mode for editing BASIC code." t)
;; (add-to-list 'auto-mode-alist '("\\.bas\\'" . basic-mode))

;; Configuration:

;; You can customize the indentation of code blocks, see variable
;; `basic-indent-offset'.  The default value is 4.
;;
;; Formatting is also affected by the customizable variables
;; `basic-delete-trailing-whitespace' and `delete-trailing-lines'
;; (from simple.el).
;;
;; You can also customize the number of columns to use for line
;; numbers, see variable `basic-line-number-cols'.  The default value
;; is 0, which means not using line numbers at all.
;;
;; The other line number features can be configured by customizing
;; the variables `basic-auto-number', `basic-renumber-increment' and
;; `basic-renumber-unnumbered-lines'.

;;; Change Log:

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
This number should include the single space between the line number and
the actual code.  Set this variable to 0 if you do not use line numbers."
  :type 'integer
  :group 'basic)

(defcustom basic-delete-trailing-whitespace 't
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

;; ----------------------------------------------------------------------------
;; Variables:
;; ----------------------------------------------------------------------------

(defconst basic-mode-version "0.4.3"
  "The current version of `basic-mode'.")

(defconst basic-increase-indent-keywords-bol
  (regexp-opt '("do" "for" "repeat" "sub" "while")
              'symbols)
  "Regexp string of keywords that increase indentation.
These keywords increase indentation when found at the
beginning of a line.")

(defconst basic-increase-indent-keywords-eol
  (regexp-opt '("else" "then")
              'symbols)
  "Regexp string of keywords that increase indentation.
These keywords increase indentation when found at the
end of a line.")

(defconst basic-decrease-indent-keywords-bol
  (regexp-opt '("else" "elseif" "endif" "end" "loop" "next" "until" "wend")
              'symbols)
  "Regexp string of keywords that decrease indentation.
These keywords decrease indentation when found at the
beginning of a line or after a statement separator (:).")

(defconst basic-comment-and-string-faces
  '(font-lock-comment-face font-lock-comment-delimiter-face font-lock-string-face)
  "List of font-lock faces used for comments and strings.")

(defconst basic-comment-regexp
  "\\_<rem\\_>.*\n"
  "Regexp string that matches a comment until the end of the line.")

(defconst basic-linenum-regexp
  "^[ \t]*\\([0-9]+\\)"
  "Regexp string of symbols to highlight as line numbers.")

(defconst basic-label-regexp
  "^[ \t]*\\([a-zA-Z][a-zA-Z0-9_.]*:\\)"
  "Regexp string of symbols to highlight as line numbers.")

(defconst basic-constant-regexp
  (regexp-opt '("false" "true")
              'symbols)
  "Regexp string of symbols to highlight as constants.")

(defconst basic-function-regexp
  (regexp-opt '("abs" "asc" "atn" "cdbl" "cint" "chr$" "command$" "cos" "exp"
                "fix" "instr" "int" "lcase$" "len" "left$" "log" "log10" "mid$"
                "pi" "right$" "rnd" "sgn" "sin" "sqr" "str$" "tab" "tan"
                "ucase$" "usr" "val")
              'symbols)
  "Regexp string of symbols to highlight as functions.")

(defconst basic-builtin-regexp
  (regexp-opt '("and" "cls" "data" "input" "let" "mat" "mod" "not" "or"
                "peek" "poke" "print" "read" "restore" "troff" "tron" "xor")
              'symbols)
  "Regexp string of symbols to highlight as builtins.")

(defconst basic-keyword-regexp
  (regexp-opt '("as" "call" "def" "defbol" "defdbl" "defint" "defsng" "defstr"
                "dim" "do" "else" "elseif" "end" "endif" "error" "exit" "fn"
                "for" "gosub" "goto" "if" "loop" "next" "on" "step" "repeat"
                "return" "sub" "then" "to" "until" "wend" "while")
              'symbols)
  "Regexp string of symbols to highlight as keywords.")

(defconst basic-type-regexp
  (regexp-opt '("boolean" "double" "integer" "single" "string")
              'symbols)
  "Regexp string of symbols to highlight as types.")

(defconst basic-font-lock-keywords
  (list (list basic-comment-regexp 0 'font-lock-comment-face)
        (list basic-linenum-regexp 0 'font-lock-constant-face)
        (list basic-label-regexp 0 'font-lock-constant-face)
        (list basic-constant-regexp 0 'font-lock-constant-face)
        (list basic-keyword-regexp 0 'font-lock-keyword-face)
        (list basic-type-regexp 0 'font-lock-type-face)
        (list basic-function-regexp 0 'font-lock-function-name-face)
        (list basic-builtin-regexp 0 'font-lock-builtin-face))
  "Describes how to syntax highlight keywords in `basic-mode' buffers.")

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
      (if (basic-match-symbol-at-point-p basic-increase-indent-keywords-eol)
          't
        ;; Keywords at the beginning of the line
        (beginning-of-line)
        (re-search-forward "[^0-9 \t\n]" (point-at-eol) t)
        (basic-match-symbol-at-point-p basic-increase-indent-keywords-bol)))))

(defun basic-decrease-indent-p ()
  "Return non-nil if indentation should be decreased.
Some keywords trigger un-indentation when found at the beginning
of a line or statement, see `basic-decrease-indent-keywords-bol'."
  (save-excursion
    (beginning-of-line)
    (re-search-forward "[^0-9 \t\n]" (point-at-eol) t)
    (or (basic-match-symbol-at-point-p basic-decrease-indent-keywords-bol)
        (let ((match nil))
          (basic-code-search-backward)
          (beginning-of-line)
          (while (and (not match)
                      (re-search-forward ":[ \t\n]*" (point-at-eol) t))
            (setq match (basic-match-symbol-at-point-p basic-decrease-indent-keywords-bol)))
          match))))

(defun basic-current-indent ()
  "Return the indent column of the current code line.
The columns allocated to the line number are ignored."
  (save-excursion
    (beginning-of-line)
    ;; Skip line number and spaces
    (skip-chars-forward "0-9 \t" (point-at-eol))
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
      (skip-chars-forward " \t" (point-at-eol))
      (skip-chars-forward "0-9" (point-at-eol))
      (and (looking-at "[ \t]")
           (= (point) (+ (point-at-bol) basic-line-number-cols -1))))))

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
    (skip-chars-forward " \t" (point-at-eol))
    (looking-at "[0-9]")))

(defun basic-remove-line-number ()
  "Remove and return the line number of the current line.
After calling this function, the current line will begin with the first
non-blank character after the line number."
  (if (not (basic-has-line-number-p))
      ""
    (beginning-of-line)
    (re-search-forward "\\([0-9]+\\)" (point-at-eol) t)
    (let ((line-number (match-string-no-properties 1)))
      (delete-region (point-at-bol) (match-end 1))
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
          (delete-char -1))
        ))))

;; ----------------------------------------------------------------------------
;; Line numbering:
;; ----------------------------------------------------------------------------

(defun basic-current-line-number ()
  "Return line number of current line, or nil if no line number."
  (save-excursion
    (when (basic-has-line-number-p)
      (beginning-of-line)
      (re-search-forward "\\([0-9]+\\)" (point-at-eol) t)
      (let ((line-number (match-string-no-properties 1)))
        (string-to-number line-number)))))

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
  (let* ((current-line-number (basic-current-line-number))
	 (next-line-number (save-excursion
			     (end-of-line)
			     (and (forward-word 1)
				  (basic-current-line-number))))
	 (new-line-number (and current-line-number
			       basic-auto-number
			       (+ current-line-number basic-auto-number))))
    (basic-indent-line)
    (newline)
    (when (and new-line-number
	       (not (zerop basic-line-number-cols)))
      (when (and next-line-number
		 (<= next-line-number
		     new-line-number))
	(setq new-line-number
	      (+ current-line-number
		 (truncate (- next-line-number current-line-number)
			   2)))
	(when (= new-line-number current-line-number)
	  (setq new-line-number (1+ new-line-number))))
      (insert (int-to-string new-line-number)))
    (basic-indent-line)))

(defun basic-find-jumps ()
  "Find all jump targets and the jump statements that jump to them.
This returns a hash with line numbers for keys.  The value of each entry
is a list containing markers to each jump point (the number following a
GOTO, GOSUB,etc.) that jumps to this line number."
  (let ((jump-targets (make-hash-table)))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "\\(go\\(sub\\|to\\)\\|then\\)[ \t]*" nil t)
	(while (looking-at "\\([0-9]+\\)\\(,[ \t]*\\)?")
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
  (interactive (list (let ((default (save-excursion
				      (goto-char (if (use-region-p)
						     (region-beginning)
						   (point-min)))
				      (or (basic-current-line-number)
					  basic-renumber-increment))))
		       (string-to-number (read-string
					  (format "Renumber, starting with (default %d): "
						  default)
					  nil nil
					  (int-to-string default))))
		     (string-to-number (read-string
					(format "Increment (default %d): "
						basic-renumber-increment)
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
      (maphash (lambda (target sources)
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
  "Return the xref backend used by basic-mode."
  'basic)

(defun basic-xref-make-xref (summary buffer point)
  "Return a buffer xref object with SUMMARY, BUFFER and POINT."
  (xref-make summary (xref-make-buffer-location buffer point)))

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql basic)))
  (basic-xref-identifier-at-point))

(defun basic-xref-identifier-at-point ()
  "Return the relevant BASIC identifier at point."
  (thing-at-point 'symbol t))

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
;; BASIC mode:
;; ----------------------------------------------------------------------------

(defvar basic-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-f" 'basic-format-code)
    (define-key map "\r" 'basic-newline-and-number)
    (define-key map "\C-c\C-r" 'basic-renumber)
    (define-key map "\:" 'basic-electric-colon)
    map)
  "Keymap used in ‘basic-mode'.")

(defvar basic-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_   "w   " table)
    (modify-syntax-entry ?\.  "w   " table)
    (modify-syntax-entry ?'   "<   " table)
    (modify-syntax-entry ?\n  ">   " table)
    (modify-syntax-entry ?\^m ">   " table)
    table)
  "Syntax table used while in ‘basic-mode'.")

;;;###autoload
(define-derived-mode basic-mode prog-mode "Basic"
  "Major mode for editing BASIC code.
Commands:
TAB indents for BASIC code. RET will insert a new line starting
with a fresh line number if line numbers are turned on.

To turn on line numbers, customize variables `basic-auto-number'
and `basic-line-number-cols'.

\\{basic-mode-map}"
  :group 'basic
  (add-hook 'xref-backend-functions #'basic-xref-backend nil t)
  (setq-local indent-line-function 'basic-indent-line)
  (setq-local comment-start "'")
  (setq-local font-lock-defaults '(basic-font-lock-keywords nil t))
  (unless font-lock-mode
    (font-lock-mode 1)))

;;;###autoload (add-to-list 'auto-mode-alist '("\\.bas\\'" . basic-mode))

;; ----------------------------------------------------------------------------

(provide 'basic-mode)

;;; basic-mode.el ends here
