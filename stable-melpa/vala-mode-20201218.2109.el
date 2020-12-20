;;; vala-mode.el --- Vala mode derived mode

;; Author:     2005 Dylan R. E. Moonfire
;;	       2008 Étienne BERSAC
;; Maintainer: Étienne BERSAC <bersace03@laposte.net>
;; Modifier:   Kentaro NAKAZAWA <kentaro.nakazawa@nifty.com>
;; Created:    2008 May the 4th
;; Modified:   April 2011
;; Version:    0.1
;; Package-Version: 20201218.2109
;; Package-Commit: d696a8177e94c81ea557ad364a3b3dcc3abbc50f
;; Keywords:   vala languages oop

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;;    See http://live.gnome.org/Vala for details about Vala language.
;;
;;    This mode was based on Dylan Moonfire's csharp-mode.

;; This is a copy of the function in cc-mode which is used to handle
;; the eval-when-compile which is needed during other times.
(require 'cc-defs)
(defun c-filter-ops (ops opgroup-filter op-filter &optional xlate)
  ;; See cc-langs.el, a direct copy.
  (unless (listp (car-safe ops))
    (setq ops (list ops)))
  (cond ((eq opgroup-filter t)
	 (setq opgroup-filter (lambda (opgroup) t)))
	((not (functionp opgroup-filter))
	 (setq opgroup-filter `(lambda (opgroup)
				 (memq opgroup ',opgroup-filter)))))
  (cond ((eq op-filter t)
	 (setq op-filter (lambda (op) t)))
	((stringp op-filter)
	 (setq op-filter `(lambda (op)
			    (string-match ,op-filter op)))))
  (unless xlate
    (setq xlate 'identity))
  (c-with-syntax-table (c-lang-const c-mode-syntax-table)
    (cl-delete-duplicates
     (mapcan (lambda (opgroup)
	       (when (if (symbolp (car opgroup))
			 (when (funcall opgroup-filter (car opgroup))
			   (setq opgroup (cdr opgroup))
			   t)
		       t)
		 (mapcan (lambda (op)
			   (when (funcall op-filter op)
			     (let ((res (funcall xlate op)))
			       (if (listp res) res (list res)))))
			 opgroup)))
	     ops)
     :test 'equal)))

;; This inserts the bulk of the code.
(require 'cc-mode)

;; These are only required at compile time to get the sources for the
;; language constants.  (The cc-fonts require and the font-lock
;; related constants could additionally be put inside an
;; (eval-after-load "font-lock" ...) but then some trickery is
;; necessary to get them compiled.)
(eval-when-compile
  (let ((load-path
	 (if (and (boundp 'byte-compile-dest-file)
		  (stringp byte-compile-dest-file))
	     (cons (file-name-directory byte-compile-dest-file) load-path)
	   load-path)))
    (load "cc-mode" nil t)
    (load "cc-fonts" nil t)
    (load "cc-langs" nil t)))

(eval-and-compile
  ;; Make our mode known to the language constant system.  Use Java
  ;; mode as the fallback for the constants we don't change here.
  ;; This needs to be done also at compile time since the language
  ;; constants are evaluated then.
  (c-add-language 'vala-mode 'java-mode))

(c-lang-defconst c-identifier-ops
  ;; Vala has "." to concatenate identifiers but it's also used for
  ;; normal indexing.  There's special code in the Vala font lock
  ;; rules to fontify qualified identifiers based on the standard
  ;; naming conventions.  We still define "." here to make
  ;; `c-forward-name' move over as long names as possible which is
  ;; necessary to e.g. handle throws clauses correctly.
  vala '((left-assoc ".")))

;; This is a verbatim copy of the value from CC Mode 5.33.1 with "Java"
;; changed to "Vala", so it can be easily diffed again in future.
(c-lang-defconst c-basic-matchers-before
  "Font lock matchers for basic keywords, labels, references and various
other easily recognizable things that should be fontified before generic
casts and declarations are fontified.  Used on level 2 and higher."

  ;; Note: `c-font-lock-declarations' assumes that no matcher here
  ;; sets `font-lock-type-face' in languages where
  ;; `c-recognize-<>-arglists' is set.

  t `(;; Put a warning face on the opener of unclosed strings that
      ;; can't span lines and on the "terminating" newlines.  Later font
      ;; lock packages have a `font-lock-syntactic-face-function' for
      ;; this, but it doesn't give the control we want since any
      ;; fontification done inside the function will be
      ;; unconditionally overridden.
      ("\\s|" 0 font-lock-warning-face t nil)

      ;; Invalid single quotes.
      c-font-lock-invalid-single-quotes

      ;; Fontify C++ raw strings.
      ,@(when (c-major-mode-is 'c++-mode)
	  '(c-font-lock-raw-strings))

      ;; Fontify keyword constants.
      ,@(when (c-lang-const c-constant-kwds)
	  (let ((re (c-make-keywords-re nil (c-lang-const c-constant-kwds))))
	    (if (c-major-mode-is 'pike-mode)
		;; No symbol is a keyword after "->" in Pike.
		`((eval . (list ,(concat "\\(\\=.?\\|[^>]\\|[^-]>\\)"
					 "\\<\\(" re "\\)\\>")
				2 c-constant-face-name)))
	      `((eval . (list ,(concat "\\<\\(" re "\\)\\>")
			      1 c-constant-face-name))))))

      ;; Fontify all keywords except the primitive types.
      ,(if (c-major-mode-is 'pike-mode)
	   ;; No symbol is a keyword after "->" in Pike.
	   `(,(concat "\\(\\=.?\\|[^>]\\|[^-]>\\)"
		      "\\<" (c-lang-const c-regular-keywords-regexp))
	     2 font-lock-keyword-face)
	 `(,(concat "\\<" (c-lang-const c-regular-keywords-regexp))
	   1 font-lock-keyword-face))

      ;; Fontify leading identifiers in fully qualified names like
      ;; "foo::bar" in languages that supports such things.
      ,@(when (c-lang-const c-opt-identifier-concat-key)
	  (if (c-major-mode-is 'vala-mode)
	      ;; Vala needs special treatment since "." is used both to
	      ;; qualify names and in normal indexing.  Here we look for
	      ;; capital characters at the beginning of an identifier to
	      ;; recognize the class.  "*" is also recognized to cover
	      ;; wildcard import declarations.  All preceding dot separated
	      ;; identifiers are taken as package names and therefore
	      ;; fontified as references.
	      `(,(c-make-font-lock-search-function
		  ;; Search for class identifiers preceded by ".".  The
		  ;; anchored matcher takes it from there.
		  (concat (c-lang-const c-opt-identifier-concat-key)
			  (c-lang-const c-simple-ws) "*"
			  (concat "\\("
				  "[" c-upper "]"
				  "[" (c-lang-const c-symbol-chars) "]*"
				  "\\|"
				  "\\*"
				  "\\)"))
		  `((let (id-end)
		      (goto-char (1+ (match-beginning 0)))
		      (while (and (eq (char-before) ?.)
				  (progn
				    (backward-char)
				    (c-backward-syntactic-ws)
				    (setq id-end (point))
				    (< (skip-chars-backward
					,(c-lang-const c-symbol-chars))
				       0))
				  (not (get-text-property (point) 'face)))
			(c-put-font-lock-face (point) id-end
					      c-reference-face-name)
			(c-backward-syntactic-ws)))
		    nil
		    (goto-char (match-end 0)))))

	    `((,(byte-compile
		 ;; Must use a function here since we match longer than
		 ;; we want to move before doing a new search.  This is
		 ;; not necessary for XEmacs since it restarts the
		 ;; search from the end of the first highlighted
		 ;; submatch (something that causes problems in other
		 ;; places).
		 `(lambda (limit)
		    (while (re-search-forward
			    ,(concat "\\(\\<" ; 1
				     "\\(" (c-lang-const c-symbol-key) "\\)" ; 2
				     (c-lang-const c-simple-ws) "*"
				     (c-lang-const c-opt-identifier-concat-key)
				     (c-lang-const c-simple-ws) "*"
				     "\\)"
				     "\\("
				     (c-lang-const c-opt-after-id-concat-key)
				     "\\)")
			    limit t)
		      (unless (progn
				(goto-char (match-beginning 0))
				(c-skip-comments-and-strings limit))
			(or (get-text-property (match-beginning 2) 'face)
			    (c-put-font-lock-face (match-beginning 2)
						  (match-end 2)
						  c-reference-face-name))
			(goto-char (match-end 1))))))))))

      ;; Fontify the special declarations in Objective-C.
      ,@(when (c-major-mode-is 'objc-mode)
	  `(;; Fontify class names in the beginning of message expressions.
	    ,(c-make-font-lock-search-function
	      "\\["
	      '((c-fontify-types-and-refs ()
		  (c-forward-syntactic-ws limit)
		  (let ((start (point)))
		    ;; In this case we accept both primitive and known types.
		    (when (eq (c-forward-type) 'known)
		      (goto-char start)
		      (let ((c-promote-possible-types t))
			(c-forward-type))))
		  (if (> (point) limit) (goto-char limit)))))

	    ;; The @interface/@implementation/@protocol directives.
	    ,(c-make-font-lock-search-function
	      (concat "\\<"
		      (regexp-opt
		       '("@interface" "@implementation" "@protocol")
		       t)
		      "\\>")
	      '((c-fontify-types-and-refs
		    (;; The font-lock package in Emacs is known to clobber
		     ;; `parse-sexp-lookup-properties' (when it exists).
		     (parse-sexp-lookup-properties
		      (cc-eval-when-compile
			(boundp 'parse-sexp-lookup-properties))))
		  (c-forward-objc-directive)
		  nil)
		(goto-char (match-beginning 0))))))

      (eval . (list "\\(!\\)[^=]" 1 c-negation-char-face-name))
      ))

;; Vala type may be marked nullable and/or be array type
(c-lang-defconst c-opt-type-suffix-key
  vala "\\(\\[[ \t\n\r\f\v]*\\]\\|[?*]\\)")

;; Vala operators
(c-lang-defconst c-operators
  vala `((prefix "base")))

;; Vala directives
(c-lang-defconst c-opt-cpp-prefix
  vala "\\s *#\\s *")

;; Support multiline strings
;;
;; FIXME: This allows any string to be multiline. Currently, c-mode only
;; supports a single-character prefix to denote a multiline string, so the
;; real fix will be harder.
(c-lang-defconst c-multiline-string-start-char
  vala vala-multiline-strings)

;; Vala uses the following assignment operators
(c-lang-defconst c-assignment-operators
  vala '("=" "*=" "/=" "%=" "+=" "-=" ">>=" "<<="
	 "&=" "^=" "|=" "++" "--"))

;; This defines the primative types for Vala
(c-lang-defconst c-primitive-type-kwds
  vala '("void" "bool" "char" "uchar" "short" "ushort" "int" "uint" "long" "ulong"
	 "size_t" "ssize_t" "int8" "uint8" "int16" "uint16" "int32" "uint32" "int64" "uint64"
	 "unichar" "float" "double" "string"))

;; The keywords that define that the following is a type, such as a
;; class definition.
(c-lang-defconst c-type-prefix-kwds
  vala '("class" "interface" "struct" "enum" "signal"))

;; Type modifier keywords which can appear in front of a type.
(c-lang-defconst c-type-modifier-prefix-kwds
  vala '("const" "dynamic"))

;; Type modifier keywords. They appear anywhere in types, but modifiy
;; instead create one.
(c-lang-defconst c-type-modifier-kwds
  vala nil)

;; Structures that are similiar to classes.
(c-lang-defconst c-class-decl-kwds
  vala '("class" "interface"))

;; The various modifiers used for class and method descriptions.
(c-lang-defconst c-modifier-kwds
  vala '("public" "private" "const" "abstract"
	 "protected" "static" "virtual"
	 "override" "params" "internal" "async" "yield"))

;; Type modifiers that can be used other than in declarations.
(c-lang-defconst c-type-modifier-prefix-kwds
  vala '("ref" "out" "weak" "owned" "unowned"))

;; Define the keywords that can have something following after them.
(c-lang-defconst c-type-list-kwds
  vala '("struct" "class" "interface" "is" "as"
	 "delegate" "event" "set" "get" "value"
	 "callback" "signal" "var" "default"))

;; This allows the classes after the : in the class declaration to be
;; fontified. 
(c-lang-defconst c-typeless-decl-kwds
  vala '(":"))

;; Sets up the enum to handle the list properly
(c-lang-defconst c-brace-list-decl-kwds
  vala '("enum" "errordomain"))

;; We need to remove Java's package keyword
(c-lang-defconst c-ref-list-kwds
  vala '("using" "namespace" "construct"))

;; Keywords followed by a paren not containing type identifiers.
(c-lang-defconst c-paren-nontype-kwds
  vala '("requires" "ensures"))

;; Follow-on blocks that don't require a brace
(c-lang-defconst c-block-stmt-2-kwds
  vala '("for" "if" "switch" "while" "catch" "foreach" "lock" "unlock" "with"))

;; Statements that break out of braces
(c-lang-defconst c-simple-stmt-kwds
  vala '("return" "continue" "break" "throw"))

;; Statements that allow a label
(c-lang-defconst c-before-label-kwds
  vala nil)

;; Constant keywords
(c-lang-defconst c-constant-kwds
  vala '("true" "false" "null"))

;; Keywords that start "primary expressions."
(c-lang-defconst c-primary-expr-kwds
  vala '("this" "base" "result" "global"))

;; We need to treat namespace as an outer block to class indenting
;; works properly.
(c-lang-defconst c-other-block-decl-kwds
  vala '("namespace" "extern"))

;; We need to include the "in" for the foreach
(c-lang-defconst c-other-kwds
  vala '("in" "sizeof" "typeof"))

;; Add a "virtual semicolon" after attributes, so that indentation
;; afterwards is not broken. Copied from
;; https://github.com/josteink/csharp-mode/ commit bd881cd
(defun vala-at-vsemi-p (&optional pos)
  (if pos (goto-char pos))
  (and
   ;; Heuristics to find attributes
   (eq (char-before) ?\])
   (save-excursion
     (c-backward-sexp)
     (looking-at "\\["))
   (not (eq (char-after) ?\;))))

(c-lang-defconst c-at-vsemi-p-fn
  vala 'vala-at-vsemi-p)


(defconst vala-font-lock-keywords-1 (c-lang-const c-matchers-1 vala)
  "Minimal highlighting for Vala mode.")

(defconst vala-font-lock-keywords-2 (c-lang-const c-matchers-2 vala)
  "Fast normal highlighting for Vala mode.")

(defconst vala-font-lock-keywords-3 (c-lang-const c-matchers-3 vala)
  "Accurate normal highlighting for Vala mode.")

(defvar vala-font-lock-keywords vala-font-lock-keywords-3
  "Default expressions to highlight in Vala mode.")

(defvar vala-mode-syntax-table
  nil
  "Syntax table used in vala-mode buffers.")
(or vala-mode-syntax-table
    (setq vala-mode-syntax-table
	  (funcall (c-lang-const c-make-mode-syntax-table vala))))

(defvar vala-mode-abbrev-table nil
  "Abbreviation table used in vala-mode buffers.")
(c-define-abbrev-table 'vala-mode-abbrev-table
  ;; Keywords that if they occur first on a line
  ;; might alter the syntactic context, and which
  ;; therefore should trig reindentation when
  ;; they are completed.
  '(("else" "else" c-electric-continued-statement 0)
    ("while" "while" c-electric-continued-statement 0)
    ("catch" "catch" c-electric-continued-statement 0)
    ("finally" "finally" c-electric-continued-statement 0)))

(defvar vala-mode-map (let ((map (c-make-inherited-keymap)))
			;; Add bindings which are only useful for Vala
			map)
  "Keymap used in vala-mode buffers.")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.vala\\'" . vala-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.vapi\\'" . vala-mode))
;;;###autoload
(c-add-style "vala"
             '("linux"
               (c-comment-only-line-offset 0 . 0)
               (c-offsets-alist
                (func-decl-cont . ++))))

;; Custom variables
(defcustom vala-mode-hook nil
  "*Hook called by `vala-mode'."
  :type 'hook
  :group 'c)

(defcustom vala-multiline-strings nil
  "Whether to enable support for multiline strings.

It can conflict with some other Emacs functionality, such as the
automatic insertion of closing quotes `electric-pair-mode'."
  :type 'bool
  :group 'vala)


;;; The entry point into the mode
;;;###autoload
(defun vala-mode ()
  "Major mode for editing Vala code.
Based on CC Mode.

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `vala-mode-hook'.

Key bindings:
\\{vala-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (c-initialize-cc-mode t)
  (set-syntax-table vala-mode-syntax-table)
  (setq major-mode 'vala-mode
	mode-name "Vala"
	local-abbrev-table vala-mode-abbrev-table
	abbrev-mode t)
  (use-local-map c-mode-map)
  ;; `c-init-language-vars' is a macro that is expanded at compile
  ;; time to a large `setq' with all the language variables and their
  ;; customized values for our language.
  (c-init-language-vars vala-mode)
  ;; `c-common-init' initializes most of the components of a CC Mode
  ;; buffer, including setup of the mode menu, font-lock, etc.
  (c-common-init 'vala-mode)
  (unless (assoc 'vala-mode c-default-style)
    (add-to-list 'c-default-style '(vala-mode . "vala")))
  (setq indent-tabs-mode t)
  (setq c-basic-offset 4)
  (setq tab-width 4)
  (c-toggle-auto-newline -1)
  (c-toggle-hungry-state -1)
  (run-mode-hooks 'c-mode-common-hook
		  'vala-mode-hook)
  (c-update-modeline))

(provide 'vala-mode)

;;; vala-mode.el ends here
