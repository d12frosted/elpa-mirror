;;; modelica-mode.el --- Major mode for editing Modelica files

;; Copyright (C) 2022-      Rudolf Schlatte
;; Copyright (C) 2010-      Dietmar Winkler
;; Copyright (C) 1997--2001 Ruediger Franke
;; Copyright (C) 1997--2001 Free Software Foundation, Inc.

;; Original author:   Ruediger Franke <rfranke@users.sourceforge.net>
;; URL: https://github.com/modelica-tools/modelica-mode
;; Package-Version: 20230508.1020
;; Package-Commit: 7064a4abdae68fc074a85a2e7c159e067c44c0e1
;; Version: 2.0.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: languages, continuous system modeling

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

;; This package provides a fundamental Modelica mode.
;; It covers:
;;  - show / hide of annotations
;;      C-c C-s  show annotation of current statement
;;      C-c C-h  hide annotation of current statement
;;      C-c M-s  show all annotations
;;      C-c M-h  hide all annotations
;;
;;  - indentation of lines, e.g.
;;      TAB      indent current line
;;      C-M-\    indent current region
;;      C-j      indent current line, create a new line, indent it
;;               (like TAB ENTER TAB)
;;
;;  - automatic insertion of end statements
;;      C-c C-e  search backwards for the last unended begin of a code block,
;;               insert the according end-statement
;;
;;  - move commands which know about statements and statement blocks
;;      M-e      move to next beginning of a statement
;;      M-a      move to previous beginning of a statement
;;      M-n      move to next beginning of a statement block
;;      M-p      move to previous beginning of a statement block
;;      C-M-a    move to beginning of current statement block
;;      C-M-e    move to end of current statement block
;;
;;  - commands for writing comments treat documentation strings as well
;;      M-;      insert a comment for current statement (standard Emacs)
;;      M-"      insert a documentation string for current statement
;;      M-j      continue comment or documentation string on next line
;;
;;  - syntax highlighting using font-lock-mode
;;
;; Current limitations:
;;  - conditional expessions are only supported on right hand sides of
;;    equations; otherwise simple expressions are assumed
;;
;; Installation:
;; (1) Put the file
;;        modelica-mode.el
;;     to an Emacs Lisp directory, e.g. ~/elisp
;;
;; (2) Add the following lines to your ~/.emacs file
;;
;;  (add-to-list 'load-path "~/elisp")
;;  (autoload 'modelica-mode "modelica-mode" "Modelica Editing Mode" t)
;;  (add-to-list 'auto-mode-alist '("\\.mo\\'" . modelica-mode))
;;
;; (3) Activate the mode by loading a file with the extension ".mo"
;;     or by invoking
;;      M-x modelica-mode
;;
;; (4) Optionally byte-compile the Lisp code
;;
;; (5) Please send comments and suggestions to
;;     Ruediger Franke <rfranke@users.sourceforge.net>

(require 'newcomment)
(require 'easymenu)

;;; Code:

(defconst modelica-mode-version "2.0.0")

;;; customization
(defgroup modelica nil
  "Major mode for editing Modelica code."
  :group 'languages)

(defcustom modelica-mode-hook nil
  "Hook run after entering `modelica-mode'."
  :type 'hook
  :options (list 'hs-minor-mode)
  :group 'modelica)

(defcustom modelica-use-emacs-keybindings t
  "Choose whether to use Emacs standard or original keybindings.
If true, use keybindings similar to other programming modes.  If
false, use original `modelica-mode' keybindings; those override
some standard Emacs keybindings."
  :type 'boolean
  :safe t
  :group 'modelica)

(defcustom modelica-basic-offset 2
  "Basic offset for indentation in Modelica Mode."
  :type 'integer
  :safe 'integerp
  :group 'modelica)

(defcustom modelica-comment-offset 3
  "Offset for indentation in comments in Modelica Mode."
  :type 'integer
  :safe 'integerp
  :group 'modelica)

(defcustom modelica-statement-offset 2
  "Offset for indentation in statements in Modelica Mode."
  :type 'integer
  :safe 'integerp
  :group 'modelica)

;;; constants

(defconst modelica-class-modifier-keyword
  "\\(encapsulated\\|final\\|inner\\|outer\\|partial\\|re\\(declare\\|placeable\\)\\)[ \t\n\r]+"
  "*Keyword regexp optionally found before a class keyword.")

(defconst modelica-class-keyword
  "\\(block\\|c\\(lass\\|onnector\\)\\|function\\|model\\|package\\|record\\|type\\)[ \t\n\r]+"
  "*Keyword regexp preceding a Modelica class declaration or definition.")

;;; Interface to font-lock

(defvar modelica-font-lock-keywords nil
  "Keywords to highlight for Modelica.  See variable `font-lock-keywords'.")

(if modelica-font-lock-keywords
    ()
  (setq modelica-font-lock-keywords
	(list
	 (list (concat "\\<"
		       "\\(do\\|"
		       "\\(end[ \t\n]+\\(if\\|for\\|wh\\(en\\|ile\\)\\)\\)\\|"
		       ; (regexp-opt
		       ; '("import" "within" "extends"
		       ;   "for" "while" "in" "loop" "when"
		       ;   "if" "then" "else" "elseif" "elsewhen"
		       ;   "and" "not" "or"))
		       "and\\|e\\(lse\\(if\\|when\\)?\\|xtends\\)\\|for\\|"
		       "i\\(mport\\|[fn]\\)\\|loop\\|not\\|or\\|then\\|"
		       "w\\(h\\(en\\|ile\\)\\|ithin\\)"
		       "\\)\\>")
	       0 'font-lock-keyword-face)
	 (list (concat "\\<"
		       ;(regexp-opt
		       ; '("algorithm" "equation" "public" "protected") t)
		       "\\(algorithm\\|equation\\|p\\(rotected\\|ublic\\)\\)"
		       "\\>")
	       0 'font-lock-keyword-face)
	 (list (concat "\\<"
		       ;(regexp-opt
		       ; '("redeclare" "final" "partial" "replaceable"
		       ;   "inner" "outer" "encapsulated"
		       ;   "discrete" "parameter" "constant"
		       ;   "flow" "input" "output" "external"
		       ;   "block" "class" "connector" "function" "model"
		       ;   "package" "record" "type"
		       ;   "end") t)
		       "\\(block\\|c\\(lass\\|on\\(nector\\|stant\\)\\)\\|"
		       "discrete\\|e\\(n\\(capsulated\\|d\\)\\|xternal\\)\\|"
		       "f\\(inal\\|low\\|unction\\)\\|in\\(ner\\|put\\)\\|"
		       "model\\|out\\(er\\|put\\)\\|pa\\(ckage\\|r\\(ameter\\|"
		       "tial\\(\\)?\\)\\)\\|re\\(cord\\|declare\\|"
		       "placeable\\)\\|type\\)"
		       "\\>")
	       0 'font-lock-type-face)
	 (list (concat "\\<"
		       ;(regexp-opt
		       ; '("der" "analysisType" "initial" "terminal"
		       ;   "noEvent" "samle" "pre" "edge" "change"
		       ;   "reinit" "abs" "sign" "sqrt" "div" "mod"
		       ;   "rem" "ceil" "floor" "integer" "delay"
		       ;   "cardinality"
		       ;   "promote" "ndims" "size" "scalar" "vector" "matrix"
		       ;   "transpose" "outerProduct" "identity" "diagonal"
		       ;   "zeros" "ones" "fill" "linspace" "min" "max" "sum"
		       ;   "product" "symmetric" "cross" "skew"
		       ;) t)
		       "\\(a\\(bs\\|nalysisType\\)\\|c\\(ardinality\\|eil\\|"
		       "hange\\|ross\\)\\|d\\(e\\(lay\\|r\\)\\|i\\(agonal\\|"
		       "v\\)\\)\\|edge\\|f\\(ill\\|loor\\)\\|i\\(dentity\\|"
		       "n\\(itial\\|teger\\)\\)\\|linspace\\|m\\(a\\(trix\\|"
		       "x\\)\\|in\\|od\\)\\|n\\(dims\\|oEvent\\)\\|o\\(nes\\|"
		       "uterProduct\\)\\|pr\\(e\\|o\\(duct\\|mote\\)\\)\\|"
		       "re\\(init\\|m\\)\\|s\\(amle\\|calar\\|i\\(gn\\|"
		       "ze\\)\\|kew\\|qrt\\|um\\|ymmetric\\)\\|t\\(erminal\\|"
		       "ranspose\\)\\|vector\\|zeros\\)"
		       "\\>")
	       0 'font-lock-function-name-face)
	 (list (concat "\\<"
		       ;(regexp-opt
		       ; '("assert" "terminate") t)
		       "\\(assert\\|terminate\\)"
		       "\\>")
	       0 'font-lock-warning-face)
	 (list (concat "\\<"
		       ;(regexp-opt
		       ; '("annotation" "connect") t)
		       "\\(annotation\\|connect\\)"
		       "\\>")
	       0 (identity 'font-lock-builtin-face))
	 (list (concat "\\<"
		       ;(regexp-opt
		       ; '("false" "true") t)
		       "\\(false\\|true\\)"
		       "\\>")
	       0 (identity 'font-lock-constant-face))
	 (list (concat "\\<"
		       ;(regexp-opt
		       ; '("time") t)
		       "\\(time\\)"
		       "\\>")
	       0 'font-lock-variable-name-face))))

;;; The mode

(defvar modelica-mode-syntax-table nil
  "Syntax table used while in Modelica mode.")

(defvar modelica-mode-abbrev-table nil
  "Abbrev table used while in Modelica mode.")
(define-abbrev-table 'modelica-mode-abbrev-table ())

(if modelica-mode-syntax-table
    ()              ; Do not change the table if it is already set up.
  (setq modelica-mode-syntax-table (make-syntax-table))

  (modify-syntax-entry ?_ "w"       modelica-mode-syntax-table)
  (modify-syntax-entry ?. "w"       modelica-mode-syntax-table)
  (modify-syntax-entry ?/  ". 124b" modelica-mode-syntax-table)

  (modify-syntax-entry ?*  ". 23"   modelica-mode-syntax-table)
  (modify-syntax-entry ?\n "> b"    modelica-mode-syntax-table)
  (modify-syntax-entry ?\' "\""    modelica-mode-syntax-table))

(defvar modelica-original-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-j"     'modelica-newline-and-indent)
    (define-key map "\C-c\C-e" 'modelica-insert-end)
    (define-key map "\C-c\C-s" 'modelica-show-annotation)
    (define-key map "\C-c\C-a" 'modelica-hide-annotation)
    (define-key map "\es"      'modelica-show-all-annotations)
    (define-key map "\ea"      'modelica-hide-all-annotations)
    (define-key map "\C-c\C-c" 'comment-region)
    (define-key map "\e\""     'modelica-indent-for-docstring)
    (define-key map "\e;"      'modelica-indent-for-comment)
    (define-key map "\ej"      'modelica-indent-new-comment-line)
    (define-key map "\ef"      'modelica-forward-statement)
    (define-key map "\eb"      'modelica-backward-statement)
    (define-key map "\en"      'modelica-forward-block)
    (define-key map "\ep"      'modelica-backward-block)
    (define-key map "\ea"      'modelica-to-block-begin)
    (define-key map "\ee"      'modelica-to-block-end)
    map)
  "Original keymap for `modelica-mode'.
This keymap overrides some standard Emacs keybindings.")

(defvar modelica-new-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-j")     'modelica-newline-and-indent)
    (define-key map (kbd "C-c C-e") 'modelica-insert-end)
    (define-key map (kbd "C-c C-s") 'modelica-show-annotation)
    (define-key map (kbd "C-c C-a") 'modelica-hide-annotation)
    (define-key map (kbd "C-c M-s") 'modelica-show-all-annotations)
    (define-key map (kbd "C-c M-a") 'modelica-hide-all-annotations)
    (define-key map (kbd "C-c C-c") 'comment-region)
    (define-key map (kbd "M-\"")    'modelica-indent-for-docstring)
    (define-key map (kbd "M-;")     'modelica-indent-for-comment)
    (define-key map (kbd "M-j")     'modelica-indent-new-comment-line)
    (define-key map (kbd "M-a")     'modelica-backward-statement)
    (define-key map (kbd "M-e")     'modelica-forward-statement)
    (define-key map (kbd "M-n")     'modelica-forward-block)
    (define-key map (kbd "M-p")     'modelica-backward-block)
    (define-key map (kbd "C-M-a")   'modelica-to-block-begin)
    (define-key map (kbd "C-M-e")   'modelica-to-block-end)
    map)
  "New-style keymap for `modelica-mode'.
This keymap tries to adhere to Emacs keybindings conventions.")

(defvar modelica-mode-map
  (if modelica-use-emacs-keybindings
      modelica-new-mode-map
    modelica-original-mode-map)
  "Keymap for `modelica-mode'.")

(defvar modelica-mode-menu
  '("Modelica"
    ("Move to"
     [" - next statement"        modelica-forward-statement t]
     [" - previous statement"    modelica-backward-statement t]
     [" - start of code block"   modelica-to-block-begin t]
     [" - end of code block"     modelica-to-block-end t])
    [" - next code block"        modelica-forward-block t]
    [" - previous code block"    modelica-backward-block t]
    "-"
    ("Annotation"
     [" - show all"              modelica-show-all-annotations t]
     [" - hide all"              modelica-hide-all-annotations t])
     [" - show current"          modelica-show-annotation t]
     [" - hide current"          modelica-hide-annotation
      :keys "C-c C-h" :active t]
    "-"
    ("Indent"
     [" - for comment"           modelica-indent-for-comment t]
     [" - for docstring"         modelica-indent-for-docstring t]
     ["Newline and indent"       modelica-newline-and-indent
      :keys "C-j" :active t]
     ["New comment line"         modelica-indent-new-comment-line t])
    [" - line"                   indent-for-tab-command t]
    [" - region"                 indent-region (mark)]
    "-"
    ["Comment out region"        comment-region  (mark)]
    ["Uncomment region"          (comment-region (point) (mark) '(4))
     :keys "C-u C-c C-c" :active (mark)]
    "-"
    ["End code block"            modelica-insert-end t])
  "Menu for Modelica mode.")

(when (featurep 'hideshow)
  (unless (assoc 'modelica-mode hs-special-modes-alist) ;; one could also use `cl-pushnew'
      (push
       (list
	'modelica-mode
	(list
	 (concat "\\(?:" modelica-class-modifier-keyword "\\)?\\(?1:" modelica-class-keyword "\\)")
	 1)
	"\\_<end\\_>[[:blank:]][^[:blank:]]+[[:blank:]]*;"
	nil
	#'modelica-to-block-end)
       hs-special-modes-alist)))

;;;###autoload
(define-derived-mode modelica-mode prog-mode "Modelica"
  "Major mode for editing Modelica files."
  :group 'modelica
  :syntax-table modelica-mode-syntax-table
  :abbrev-table modelica-mode-abbrev-table
  ;; Allow switching between original and new keybindings just by setting
  ;; `modelica-use-emacs-keybindings' and reverting a modelica buffer
  (setq modelica-mode-map
        (if modelica-use-emacs-keybindings
            modelica-new-mode-map
          modelica-original-mode-map))
  (use-local-map modelica-mode-map)
  (setq-local indent-line-function #'modelica-indent-line)
  ;; comment syntax
  (setq-local comment-column 32
              comment-start "// "
              comment-start-skip "/\\*+ *\\|// *"
              comment-end ""
              comment-multi-line nil)
  ;; settings for font-lock-mode
  (setq-local font-lock-keywords modelica-font-lock-keywords)
  ;; font-lock-mode for newer GNU Emacs versions
  (setq-local font-lock-defaults '(modelica-font-lock-keywords nil nil))
  ;; hide/show annotations
  (setq-local line-move-ignore-invisible t)
  (add-to-invisibility-spec '(modelica-annotation . t))
  (modelica-hide-all-annotations)
  (easy-menu-define modelica-mode-menu-symbol
      modelica-mode-map
      "Menu for Modelica mode"
      modelica-mode-menu))

(defun modelica-indent-for-comment ()
  "Indent this line's comment to `comment-column', or insert an empty comment."
  (interactive)
  (indent-for-comment)
  (modelica-indent-line))

(defun modelica-indent-for-docstring ()
  "Indent this statement's documentation string to `comment-column'.
Insert an empty documentation string if necessary."
  (interactive)
  (let ((deleted "") save-point)
    ;; move behind current statement
    (skip-chars-forward " \t")
    (condition-case nil
	(progn
	  (modelica-forward-statement)
	  (forward-comment (- (point-max))))
      (error
       (progn
	 (end-of-line)
	 (skip-chars-backward " \t"))))
    ;; remove ending ";", if any, and store it in "deleted"
    (if (or (looking-at "[ \t\n]")
	    (eobp))
	(forward-char -1))
    (if (looking-at ";")
	(progn
	  (delete-char 1)
	  (setq deleted ";"))
      (forward-char 1))
    ;; move backwards to last non-blank
    (skip-chars-backward " \t")
    (if (or (looking-at "[ \t\n]")
	    (eobp))
	(forward-char -1))
    (if (looking-at "\"")
	;; indent docstring
	(progn
	  (forward-char 1)
	  (insert deleted)
	  (forward-char (- (1+ (length deleted))))
	  (modelica-within-string t)
	  (while (modelica-behind-string t))
	  (setq save-point (point))
	  (skip-chars-backward " \t")
	  (delete-region (point) save-point)
	  (indent-to (max comment-column (1+ (current-column))))
	  (forward-char 1))
      ;; insert new docstring
      (forward-char 1)
      (indent-to (max comment-column (1+ (current-column))))
      (insert "\"\"" deleted)
      (forward-char (- (1+ (length deleted))))))
  (modelica-indent-line))

(defun modelica-indent-new-comment-line ()
  "Indent new comment line for Modelica mode.
Same behavior as `indent-new-comment-line', but additionally
considers documentation strings."
  (interactive)
  (modelica-indent-line)
  (let (starter)
    (cond
     ;; treat documentation string
     ((modelica-within-string)
      (insert "\"\n\""))
     ;; adapt comment-multi-line and
     ;; call default indent-new-comment-line
     (t
      (setq starter (modelica-within-comment))
      (if (equal starter "/*")
	  (setq comment-multi-line t)
	(setq comment-multi-line nil))
      (indent-new-comment-line))))
  (modelica-indent-line))

(defun modelica-indent-line ()
  "Indentation for Modelica."
  (let ((pos (- (point-max) (point))) beg beg-anno end-anno)
    (beginning-of-line)
    (setq beg (point))
    ;; no indentation of invisible text (hidden annotations)
    (if (modelica-within-overlay 'invisible)
	()
      ;; no indentation if preceeding newline is quoted
      (if (and (> (point) 2)
	       (progn
		 (forward-char -2)
		 (looking-at "[\\]\n")))
	  (forward-char 2)
	;; else indent line
	(goto-char beg)
	(skip-chars-forward " \t")
	(let ((indent (modelica-calculate-indent)))
	  (if (= indent (current-column))
	      ;; nothing to be done
	      ()
	    (delete-region beg (point))
	    (indent-to indent)))))
    ;; return to the old position inside the line
    (if (> (- (point-max) pos) (point))
	(goto-char (- (point-max) pos)))))

(defun modelica-calculate-indent ()
  "Calculate indentation for current line.
Assumes point to be over the first non-blank of the line."
  (save-excursion
    (let ((case-fold-search nil)
	  offset (last-open nil) (save-point (point))
	  ref-point ref-column)
      (cond
       ;; multi-line comment has fixed indentation, relative to its start
       ((modelica-within-comment t)
	(setq ref-column (current-column))
	(goto-char save-point)
	(if (looking-at "\\*/")
	    ref-column
	  (+ ref-column modelica-comment-offset)))
       ;; concatenation of strings
       ((and (looking-at "\"")
	     (modelica-behind-string t))
	;; move point to the very first string constant
	;; in order to consider concatenation on the same line
	(while (modelica-behind-string t))
	(current-column))
       ;; continued single-line comment
       ((and (looking-at "//")
	     (forward-comment -1)
	     (looking-at "//"))
	(current-column))
       ;; default looks for last unended begin-like statement
       (t
	(goto-char save-point) ; needed after check for singele-line comments
	(setq offset modelica-basic-offset)
	;; goto left for labels, end's etc.
	(if (looking-at
	     (concat
	      ; ("algorithm" "elseif" "elsewhen" "end" "equation" "external"
	      ;  "in" "loop" "protected" "public")
	      "\\(algorithm\\|e\\(lse\\(if\\|when\\)\\|nd\\|quation\\|"
	      "xternal\\)\\|in\\|loop\\|p\\(rotected\\|ublic\\)\\)"
	      "\\>"))
	    (setq offset (- offset modelica-basic-offset)))
	(if (and
	     (looking-at
	      (concat
	       ; ("else" "then")
	       "\\(else\\|then\\)"
	       "\\>"))
	     (not (modelica-within-equation)))
	    (setq offset (- offset modelica-basic-offset)))
	(condition-case nil
	    (progn
	      (modelica-last-unended-begin t)
	      ;; correct offset
	      (if (looking-at "end\\>")
		  ;; found an 'end', means no basic offset
		  (setq offset (- offset modelica-basic-offset)))
	      ;; check indentation in statements
	      (setq ref-column (current-column))
	      (setq ref-point (point))
	      (goto-char save-point)
	      (modelica-statement-start ref-point)
	      (if (>= (point) save-point)
		  ;; indent relative to ref-point as new statement starts
		  (max 0 (+ ref-column offset))
		;; else add modelica-statement-offset
		;; provided that point is behind ref-point
		;; and point is not within a begin-like statement
		(if (and (> (point) ref-point)
			 (not (and (modelica-forward-begin)
				   (> (point) save-point))))
		    (setq offset (+ offset modelica-statement-offset)))
		(setq last-open
			(car (cdr (parse-partial-sexp (point) save-point))))
		(if (not last-open)
		    (max 0 (+ ref-column offset))
		  (goto-char last-open)
		  (+ 1 (current-column)))))
	  (error 0)))))))

(defun modelica-empty-line ()
  "Return t if current line is empty, else return nil."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t")
    (eolp)))

(defun modelica-within-comment (&optional move-point)
  "Return comment starter if point is within a comment, nil otherwise.
Optionally move point to the beginning of the comment if
MOVE-POINT is true."
  (when-let* ((syn (syntax-ppss))
	      ((nth 4 syn))
	      (start (nth 8 syn)))
    (when move-point
      (goto-char start))
    (buffer-substring-no-properties start (+ start 2))))

(defun modelica-within-single-line-comment (&optional move-point)
  "Return comment starter if point is within a single-line comment.
Return nil otherwise.  Optionally move point to the beginning of
the comment if MOVE-POINT is true."
  (let ((starter nil) (save-point (point)))
    ;; check single-line comment
    (condition-case nil
	(if (and (re-search-backward "//\\|\n")
		 (looking-at "//"))
	    (setq starter "//"))
      (error nil))
    (if (and starter move-point)
	(setq save-point (point)))
    (goto-char save-point)
    starter))

(defun modelica-within-string (&optional move-point)
  "Return t if point is within a string constant, nil otherwise.
Optionally move point to the starting double quote of the string
if MOVE-POINT is true."
  (if (and (boundp 'font-lock-mode) font-lock-mode)
      ;; use result of font-lock-mode to also cover multi-line strings
      (let (within-string)
	(setq within-string
	      (text-property-any (point) (min (+ (point) 1) (point-max))
				 'face 'font-lock-string-face))
	(if (and within-string move-point)
	    (let ((point-next
		   (text-property-not-all (point) (point-max)
					  'face 'font-lock-string-face)))
	      (goto-char point-next)
	      (backward-sexp)))
	within-string)
    (let ((within-string nil) (save-point (point)) (start-point nil))
      (condition-case nil
	  (while
	      (progn
		(re-search-backward "\\(^\\|[^\\]\\)[\"\n]")
		(looking-at "\\(^\\|.\\)\""))
	    (if (not (looking-at "^"))
		(forward-char 1))
	    (if within-string
		(setq within-string nil)
	      (setq within-string t)
	      (or start-point (setq start-point (point)))))
	(error nil))
      (if (and within-string move-point start-point)
	  (goto-char start-point)
	(goto-char save-point))
      within-string)))

(defun modelica-behind-string (&optional move-point)
  "Check for string concatenation.
Return t if only blanks are between point and the preceeding
string constant, nil otherwise.  Optionally move point to the
starting double quote of the preceeding string if MOVE-POINT is
true."
  (let ((behind-string nil)
	(save-point (point)))
    (if (and (> (point) 1)
	     (progn
	       (skip-chars-backward " \t\n")
	       (if (> (point) 1)
		   (forward-char -1))
	       (looking-at "\""))
	     (modelica-within-string move-point))
	(setq behind-string t))
    (if (or (not move-point)
	    (not behind-string))
	(goto-char save-point))
    behind-string))

(defun modelica-within-matrix-expression (&optional move-point)
  "Return t if an opening bracket is found backwards from point.
Return nil otherwise; optionally move point to the bracket if
MOVE-POINT is true."
  (let ((save-point (point)) (matrix-expression nil))
    (condition-case nil
	(progn
	  (while (progn
		   (re-search-backward "[\]\[]")
		   (modelica-within-comment t)))
	  (if (looking-at "[\[]")
	      (progn
		(setq matrix-expression t)
		(if move-point
		    (setq save-point (point))))))
      (error nil))
    (goto-char save-point)
    matrix-expression))

(defun modelica-within-equation (&optional move-point)
  "Return t if point is within right hand side of an equation, nil otherwise.
Optionally move point to the identifying '=' or ':=' if
MOVE-POINT is true."
  (let ((equation nil) (save-point (point)))
    (condition-case nil
	(progn
	  (while (progn
		   (re-search-backward
		    (concat "\\([^=]:?=[^=]\\)\\|;"))
		   (modelica-within-comment)))
	  (if (looking-at ";")
	      (setq equation nil)
	    (setq equation t)
	    (if (looking-at "[^:]=")
		(forward-char 1))
	    (if move-point
		(setq save-point (point)))))
      (error nil))
    (goto-char save-point)
    equation))

(defun modelica-statement-start (&optional ref-point)
  "Move point to the first character of the current statement.
The optional argument REF-POINT points to the last end or unended
begin."
  (let ((save-point (point)))
    (if ref-point
	()
      (condition-case nil
	  (modelica-last-unended-begin t)
	(error (goto-char (point-min))))
      (setq ref-point (point))
      (goto-char save-point))
    (while (progn
	     (re-search-backward
	      ;; ("]" ")" ";"
	      ;;  "algorithm" "equation" "external"
	      ;;  "else" "elseif" "elsewhen"
	      ;;  "loop" "protected" "public" "then")
	      (concat
	       "[\]\);]\\|"
	       "\\<"
	       "\\(algorithm\\|e\\(lse\\(if\\|when\\)?\\|quation\\|"
	       "xternal\\)\\|loop\\|p\\(rotected\\|ublic\\)\\|then\\)"
	       "\\>")
	      ref-point 'no-error)
	     (and
	      (> (point) ref-point)
	      (or (modelica-within-comment t)
		  (modelica-within-string)
		  (if (looking-at "[\]\)]")
		      (progn
			(forward-char 1)
			(forward-sexp -1)
			t))
		  (if (looking-at ";")
		      (modelica-within-matrix-expression t)
		    (modelica-within-equation t))))))
    (cond
     ((= (point) ref-point)
      ;; we arrived at last unended begin,
      ;; but might be looking for first statement of block
      (modelica-forward-begin)
      (forward-comment (- (buffer-size)))
      (if (> (point) save-point)
	  (goto-char ref-point)))
     ((looking-at ";")
      (forward-char 1))
     (t
      (forward-word 1)))
    (forward-comment (buffer-size))))

(defun modelica-short-class-definition ()
  "Return t if point is over a short class definition."
  (looking-at (concat
	       "\\(" modelica-class-modifier-keyword "\\)*"
	       modelica-class-keyword
	       "[A-Za-z_][0-9A-Za-z_]*[ \t\n\r]+=")))

(defun modelica-end-ident ()
  "Return t if last word is an 'end'."
  (save-excursion
    (forward-word -1)
    (looking-at "end\\>")))

(defun modelica-last-unended-begin (&optional indentation-only)
  "Position point at last unended begin.
Raise an error if nothing found.  If INDENTATION-ONLY is true,
position point at last begin or end."
  ;; find last unended begin-like keyword
  (let ((depth 1))
    (while (>= depth 1)
      (while (progn
	       (re-search-backward
		(concat
		 "\\<"
		 ; ("block" "class" "connector" "end"
		 ;  "for" "function" "if" "model" "package"
		 ;  "record" "type" "when" "while")
		 "\\(block\\|c\\(lass\\|onnector\\)\\|end\\|"
		 "f\\(or\\|unction\\)\\|if\\|model\\|package\\|"
		 "record\\|type\\|wh\\(en\\|ile\\)\\)"
		 "\\>"))
	       (or (modelica-within-comment t)
		   (modelica-short-class-definition)
		   (modelica-within-string)
		   (modelica-end-ident)
		   (and (looking-at "if") (modelica-within-equation t)))))
      (if (looking-at "end\\>")
	  (if indentation-only
	      (setq depth -1)
	    (setq depth (+ depth 1)))
	(setq depth (- depth 1))))
    ;; step backwards over class prefixes
    (if (>= depth 0)
	(let ((save-point (point)))
	  (while (progn
		   (forward-word -1)
		   (and
		    (looking-at modelica-class-modifier-keyword)
		    (not (modelica-within-comment))))
	    (setq save-point (point)))
	  (goto-char save-point)))))

(defun modelica-forward-begin ()
  "Move point forward over a begin-like statement.
Return block ident (string) or nil if not found.
   Point is assumed over the start of the begin-like statement upon call."
  (let ((ident nil) (save-point (point)) start-point)
    (cond
     ((looking-at "\\(for\\|while\\)\\>")
      (setq ident (buffer-substring (match-beginning 0) (match-end 0)))
      (while (progn
	       (re-search-forward "\\<loop\\>")
	       (modelica-within-comment))))
     ;;(regexp-opt '("if" "elseif" "when" "elsewhen"))
     ((looking-at "\\(else\\(if\\|when\\)\\|if\\|when\\)\\>")
      (setq ident (buffer-substring (match-beginning 0) (match-end 0)))
      (while (progn
	       (re-search-forward "\\<then\\>")
	       (modelica-within-comment))))
     ((looking-at
       (concat "\\(" modelica-class-modifier-keyword "\\)\\|"
	       "\\(" modelica-class-keyword "\\)"))
      ;; move over class modifiers
      (while (looking-at modelica-class-modifier-keyword)
	(forward-word 1)
	(forward-comment (buffer-size)))
      ;; check and move over class specifier
      (if (not (looking-at modelica-class-keyword))
	  (goto-char save-point)
	(forward-word 1)
	(forward-comment (buffer-size))
	;; move over class name and look it up
	(setq start-point (point))
	(re-search-forward "\\>")
	(setq ident (buffer-substring start-point (point)))
	(forward-comment (buffer-size))
	;; check short class definition
	(if (looking-at "=")
	    (progn
	      (setq ident nil)
	      (goto-char save-point))
	  ;; else move over documentation strings
	  (while (looking-at "\"")
	    (forward-char 1)
	    (if (looking-at "\"")
		(forward-char 1)
	      (re-search-forward "[^\\]\""))
	    (forward-comment (buffer-size)))))))
    (forward-comment (buffer-size))
    ident))

(defun modelica-newline-and-indent ()
  "Indent current line before calling `newline-and-indent'."
  (interactive)
  (modelica-indent-line)
  (newline-and-indent))

(defun modelica-insert-end ()
  "Insert end statement for current block."
  (interactive)
  (let ((case-fold-search nil)
	indentation (save-point (point)) (block-start nil) (end-ident ""))
    (save-excursion
      (condition-case nil
	  (modelica-last-unended-begin)
	(error (error "Couldn't find unended begin")))
      (setq indentation (current-column))
      (setq end-ident (modelica-forward-begin))
      (if (<= save-point (point))
	  (setq block-start t)))
    ;; insert newline or clear up an empty line
    (if (not (modelica-empty-line))
	(insert "\n")
      (setq save-point (point))
      (beginning-of-line)
      (delete-region (point) save-point))
    ;; insert proper end
    (indent-to indentation)
    (insert "end " end-ident ";")
    ;; step back if block just starts
    (if (not block-start)
	()
      (forward-line -1)
      (end-of-line))
    ;; insert newline
    (insert "\n")
    (modelica-indent-line)))

;; active regions, and auto-newline/hungry delete key
;; (copied from cc-mode.el)
(defun modelica-keep-region-active ()
  "Do whatever is necessary to keep the region active in XEmacs 19.
Ignore byte-compiler warnings you might see."
  (and (boundp 'zmacs-region-stays)
       (setq zmacs-region-stays t)))

(defun modelica-forward-statement ()
  "Move point to next beginning of a statement."
  (interactive)
  (modelica-keep-region-active)
  (let ((case-fold-search nil)
	(save-point (point))
	pos)
    (modelica-statement-start)
    (if (> (point) save-point)
	;; ready after skipping leading comment or blanks
	()
      ;; else move forward
      (setq save-point (point))
      (if (modelica-forward-begin)
	  ;; ready after moving over begin-like statement
	  ()
	;; move forward behind next ";" ending a statement
	(while
	    (progn
	      (re-search-forward ";" (point-max) t)
	      (or (modelica-within-comment)
		  (modelica-within-string)
		  (modelica-within-matrix-expression))))
	(forward-comment (point-max))
	(if (eobp)
	    (progn
	      (goto-char save-point)
	      (error "No next statement"))
	  ;; move backwards over possibly skipped statements
	  ;; without ending ";"
	  (setq pos (point))
	  (while (> (point) save-point)
	    (setq pos (point))
	    (forward-comment (- (point-max)))
	    (if (not (bobp))
		(forward-char -1))
	    (modelica-statement-start))
	  (goto-char pos))))))

(defun modelica-backward-statement ()
  "Move point to previous beginning of a statement."
  (interactive)
  (modelica-keep-region-active)
  (let ((case-fold-search nil) (save-point (point)))
    (modelica-statement-start)
    (if (< (point) save-point)
	;; ready after having moved to start of current statement
	()
      ;; else move backward
      (setq save-point (point))
      (forward-comment (- (point-max)))
      (if (not (bobp))
	  (forward-char -1))
      (modelica-statement-start)
      (if (= (point) save-point)
	  (error "No previous statement")))))

(defun modelica-forward-block (&optional arg)
  "Move point to next beginning of a block at the same nesting level.
If no next block found on the same level move a level higher.

If ARG is a positive integer move that many times.

If ARG is a negative integer move backwards instead.

In interactive calls, ARG is the numeric prefix argument."
  (interactive "p")
  (cond
   ((or (null (integerp arg)) (eq arg 1))
    (let ((save-point (point)))
      (condition-case nil
	  (progn
	    (modelica-to-block-begin)
	    (if (> (point) save-point)
		;; we moved already forward to a block begin
		()
	      (modelica-to-block-end)
	      (modelica-forward-statement)
	      (modelica-to-block-begin)
	      (if (< (point) save-point)
		  (modelica-forward-block))))
	;; in case of error and if we did move yet,
	;; move forward one statement
	(error (if (= (point) save-point)
		   (modelica-forward-statement))))))
   ((> arg 1)
    (dotimes (_i arg)
      (modelica-forward-block 1)))
   ((<= arg 0)
    (modelica-backward-block)
    (modelica-forward-block (1+ arg)))))

(defun modelica-backward-block ()
  "Move point to previous beginning of a block at the same nesting level.
If point is at the first block of the current level, move it a level higher."
  (interactive)
  (let ((save-point (point)))
    (condition-case nil
	(progn
	  (modelica-to-block-begin)
	  (if (< (point) save-point)
	      ;; we moved already backward to the beginning of a block
	      ()
	    (modelica-backward-statement)
	    (modelica-to-block-begin)))
      ;; in case of error and if we did not move yet,
      ;; move backward one statement
      ;; and move to beginning of that block if one ends there
      (error (progn
	       (if (= (point) save-point)
		   (progn
		     (modelica-backward-statement)
		     (if (looking-at "\\<end\\>")
			 (modelica-to-block-begin)))))))))

(defun modelica-to-block-begin ()
  "Move point to beginning of current statement block."
  (interactive)
  (modelica-keep-region-active)
  (let ((case-fold-search nil)
	(save-point (point)))
    (condition-case nil
	(progn
	  (modelica-statement-start)
	  (modelica-forward-begin)
	  (modelica-last-unended-begin))
      (error (progn
	       (goto-char save-point)
	       (error "No statement block"))))))

(defun modelica-forward-block-end ()
  "Skip block end and return its name.
Do not move point if it is not at a block end."
  (let ((pt (point))
	ret)
    (comment-forward most-positive-fixnum)
    (and
     (null (ppss-comment-or-string-start (syntax-ppss)))
     (looking-at "\\_<end\\_>")
     (progn
       (goto-char (match-end 0))
       (comment-forward most-positive-fixnum)
       (if (eq (char-after) ?\;)
	   (setq ret "")
	 (setq ret (buffer-substring-no-properties
		    (point)
		    (progn
		      (forward-sexp)
		      (point)))))
       (comment-forward most-positive-fixnum)
       (if (eq (char-after) ?\;)
	   (progn
	     (forward-char)
	     ret)
	 (goto-char pt)
	 (setq ret nil)))
     ret)))

(defun modelica-to-block-end (&rest _)
  "Move point to end of current statement block.

Make usable for `hs-forward-sexp-func' by ignoring any arguments."
  (interactive)
  (modelica-keep-region-active)
  (let ((case-fold-search nil)
	ident-stack
	ident
	(save-point (point)))
    (condition-case nil
	(progn
	  (modelica-statement-start)
	  (modelica-forward-begin)
	  (modelica-last-unended-begin)
	  (setq ident (modelica-forward-begin))
	  (unless ident
	    (throw 'error nil))
	  (setq ident-stack (list ident))
	  (while
	      (progn
		(comment-forward most-positive-fixnum)
		(cond
		 ((setq ident (modelica-forward-begin))
		  (push ident ident-stack)
		  t)
		 ((setq ident (modelica-forward-block-end))
		  (unless (string-equal ident (car ident-stack))
		    (throw 'error nil))
		  (pop ident-stack)
		  ident-stack)
		 (t
		  (modelica-forward-statement)
		  (null (eobp)))))))
      (error (progn
	       (goto-char save-point)
	       (error (if ident
			  (if ident-stack
			      (format "Begin-id \"%s\" does not match end-id \"%s\"" (car ident-stack) ident)
			    (format "Missing \"end %s\"" ident))
			"No statement block to end")))))))

;; snarfed from outline.el (outline-flag-region)
;; Comments about GNU Emacs 20.7 and XEmacs 21.1:
;; GNU Emacs:
;;  - ellipse ... is not displayed as we stop hiding before end of line
;;    (advantages of only hiding embraced annotation text are
;;     correct visible syntax and visible end of hidden text)
;; XEmacs:
;;  - isearch-open-invisible property does not work, i.e.
;;    hidden text is not shown if isearch finds it
;; General:
;;  - intangible property, to skip hidden text when moving by chars,
;;    does not work with XEmacs and does not fully work with GNU Emacs
;;    (e.g. C-a/C-e stop in hidden annotation, search/replace finds
;;     at most one occurence, reopen of externally modified files is strange)
;;  - read-only property, to avoid modifications of hidden text,
;;    does not work with GNU Emacs
;;  --> we don't set intangible or read-only property
(defun modelica-flag-region (from to flag)
  "Hide or show lines from FROM to TO, according to FLAG.
If FLAG is nil then text is shown, while if FLAG is t the text is hidden."
  (save-excursion
    (goto-char from)
    (modelica-discard-overlays from to 'modelica-annotation)
    (if flag
	(let ((o (make-overlay from to)))
	  (overlay-put o 'invisible 'modelica-annotation)
	  (overlay-put o 'isearch-open-invisible
		       'modelica-isearch-open-invisible)))))

;; snarfed from outline.el (outline-isearch-open-invisible)
(defun modelica-isearch-open-invisible (_overlay)
  "Helper Function for `modelica-flag-region'.
This function is set as an `outline-isearch-open-invisible'
property to the overlay that makes the outline invisible."
  ())

;; snarfed from outline.el (outline-discard-overlays)
(defun modelica-discard-overlays (beg end value)
  "Discard all VALUE overlays between BEG and END."
  (if (< end beg)
      (setq beg (prog1 end (setq end beg))))
  (save-excursion
    (let ((overlays (overlays-in beg end))
	  o)
      (while overlays
	(setq o (car overlays))
 	(if (eq (overlay-get o 'invisible) value)
	    (delete-overlay o))
	(setq overlays (cdr overlays))))))

;; test for overlay
(defun modelica-within-overlay (prop)
  "Overlay value when point is in an overlay with property PROP.
If point is not in such an overlay, return nil."
    (let ((overlays (overlays-at (point)))
	  (value nil)
	  o)
      (while (and overlays (not value))
	(setq o (car overlays))
	(setq value (overlay-get o prop))
	(setq overlays (cdr overlays)))
      value))

(defun modelica-hide-annotations (beg end)
  "Hide all annotations between BEG and END."
  (save-excursion
    (let (beg-hide end-hide)
      (goto-char beg)
      (while
	  (and (< (point) end)
	       (search-forward-regexp "\\<annotation[ \t\n]*\(" end t))
	(setq beg-hide (match-end 0))
	(backward-char)
	(forward-sexp)
	(setq end-hide (- (point) 1))
	(modelica-flag-region beg-hide end-hide t)))))

(defun modelica-show-annotations (beg end)
  "Show annotations from BEG to END."
  (modelica-flag-region beg end nil))

(defun modelica-hide-all-annotations ()
  "Hide all annotations."
  (interactive)
  (modelica-hide-annotations (point-min) (point-max)))

(defun modelica-hide-annotation ()
  "Hide annotation of current statement."
  (interactive)
  (save-excursion
    (let (beg end)
      ;; move to beginning of current statement
      (modelica-statement-start)
      (setq beg (point))
      ;; move to beginning of next statement
      (modelica-forward-statement)
      (setq end (point))
      ;; hide annotations from beg to end
      (modelica-hide-annotations beg end))))

(defun modelica-show-all-annotations ()
  "Show all annotations."
  (interactive)
  (modelica-show-annotations (point-min) (point-max)))

(defun modelica-show-annotation ()
  "Show annotation of current statement."
  (interactive)
  (save-excursion
    (let (beg end)
      ;; move to beginning of current statement
      (modelica-statement-start)
      (setq beg (point))
      ;; move to beginning of next statement
      (modelica-forward-statement)
      (setq end (point))
      ;; show annotations from beg to end
      (modelica-show-annotations beg end))))

;; Emacs by default assumes ".mo" as an extension for object files, similar to
;; ".o".  Assume that when the user loads modelica-mode, they want to remove
;; this behavior.
(setq completion-ignored-extensions
      (remove ".mo" completion-ignored-extensions))
(when (boundp 'dired-omit-extensions)   ; defined in dired-x
  (setq dired-omit-extensions
      (remove ".mo" dired-omit-extensions)))

(provide 'modelica-mode)

;;; modelica-mode.el ends here
