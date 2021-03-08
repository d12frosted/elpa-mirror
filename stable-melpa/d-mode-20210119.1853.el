;;; d-mode.el --- D Programming Language major mode for (X)Emacs
;;;               Requires a cc-mode of version 5.30 or greater

;; Author:  William Baxter
;; Contributor:  Andrei Alexandrescu
;; Contributor:  Russel Winder
;; Maintainer:  Russel Winder <russel@winder.org.uk>
;;              Vladimir Panteleev <vladimir@thecybershadow.net>
;; Created:  March 2007
;; Version:  202003130913
;; Package-Version: 20210119.1853
;; Package-Commit: 199743df55c6bfce3cdb08405bd8519768c8dfa9
;; Keywords:  D programming language emacs cc-mode
;; Package-Requires: ((emacs "25.1"))

;;;; NB Version number is date and time yyyymmddhhMM UTC.
;;;; A hook to update it automatically on save is available here:
;;;; https://gist.github.com/CyberShadow/28f60687c3bf83d32900cd6074c012cb

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
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

;;; Usage:
;; Put these lines in your init file.
;;   (autoload 'd-mode "d-mode" "Major mode for editing D code." t)
;;   (add-to-list 'auto-mode-alist '("\\.d[i]?\\'" . d-mode))
;;
;; Alternatively you can load d-mode.el explicitly:
;;   (load "d-mode.el")
;;
;; cc-mode version 5.30 or greater is required.
;; You can check your cc-mode with the command M-x c-version.
;; You can get the latest version of cc-mode at http://cc-mode.sourceforge.net

;;; Commentary:
;;   This mode supports most of D's syntax, including nested /+ +/
;;   comments and backquote `string literals`.
;;
;;   This mode has been dubbed "2.0" because it is a complete rewrite
;;   from scratch.  The previous d-mode was based on cc-mode 5.28 or
;;   so.  This version is based on the cc-mode 5.30 derived mode
;;   example by Martin Stjernholm, 2002.

;;; Bugs:
;; Bug tracking is currently handled using the GitHub issue tracker at
;; https://github.com/Emacs-D-Mode-Maintainers/Emacs-D-Mode/issues

;;; Versions:
;;  This mode is available on MELPA which tracks the mainline Git repository on GitHub, so there is a
;;  rolling release system based on commits to the mainline. For those wanting releases, the repository is
;;  tagged from time to time and this creates an entry in MELPA Stable and a tarball on GitHub.

;;; Notes:

;;; TODO:
;;   Issues with this code are managed via the project issue management
;;   on GitHub: https://github.com/Emacs-D-Mode-Maintainers/Emacs-D-Mode/issues?state=open

;;; History:
;;   History is tracked in the Git repository rather than in this file.
;;   See https://github.com/Emacs-D-Mode-Maintainers/Emacs-D-Mode/commits/master

;;; Code:

;; ----------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Required packages ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ----------------------------------------------------------------------------

(require 'cc-mode)
(require 'cc-langs)

;; Needed to prevent
;;   "Symbol's value as variable is void: compilation-error-regexp-alist-alist" errors
(require 'compile)

;; Work around Emacs (cc-mode) bug #18845
(eval-when-compile
  (when (and (= emacs-major-version 24) (>= emacs-minor-version 4))
    (require 'cl)))

;; Used to specify regular expressions in a sane way.
(require 'rx)

;; These are only required at compile time to get the sources for the
;; language constants.  (The cc-fonts require and the font-lock
;; related constants could additionally be put inside an
;; (eval-after-load "font-lock" ...) but then some trickery is
;; necessary to get them compiled.)
;; Comment out 'when-compile part for debugging
(eval-when-compile
  (require 'cc-fonts))


;; ----------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; cc-mode configuration ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ----------------------------------------------------------------------------

(eval-and-compile
  ;; Make our mode known to the language constant system.  Use Java
  ;; mode as the fallback for the constants we don't change here.
  ;; This needs to be done also at compile time since the language
  ;; constants are evaluated then.
  (c-add-language 'd-mode 'java-mode))

;; muffle the warnings about using free variables and undefined
;; functions
(defvar c-syntactic-element)
(declare-function c-populate-syntax-table "cc-langs.el" (table))

;; D has pointers
(c-lang-defconst c-type-decl-prefix-key
  d (concat "\\("
		   "[*(~]"
		   "\\|"
		   (c-lang-const c-type-decl-prefix-key)
		   "\\)"
		   "\\([^=]\\|$\\)"))

(c-lang-defconst c-decl-start-re
  d "[[:alpha:]_@~.]")
  ;; d "[[:alpha:]_@]")

(c-lang-defconst d-decl-end-re
  d "[,;=(]")

;; D has fixed arrays
(c-lang-defconst c-opt-type-suffix-key
  d "\\(\\[[^]]*\\]\\|\\.\\.\\.\\|\\*\\)")

(c-lang-defconst c-decl-prefix-re
  d "\\([{}();:,=]+\\)")

(c-lang-defconst c-identifier-ops
  ;; For recognizing "~this", ".foo", and "foo.bar.baz" as identifiers
  d '((left-assoc ".")))

(c-lang-defconst c-after-id-concat-ops
  ;; Also for handling ~this
  d '("~"))

(c-lang-defconst c-string-escaped-newlines
  ;; Set to true to indicate the D handles backslash escaped newlines in strings
  d t)

(c-lang-defconst c-multiline-string-start-char
  ;; Set to true to indicate that D doesn't mind raw embedded newlines in strings
  d t)

(c-lang-defconst c-opt-cpp-prefix
  ;; Preprocessor directive recognizer.  D doesn't have cpp, but it has #line
  d "\\s *#\\s *")

(c-lang-defconst c-cpp-message-directives d nil)
(c-lang-defconst c-cpp-include-directives d nil)
(c-lang-defconst c-opt-cpp-macro-define d nil)
(c-lang-defconst c-cpp-expr-directives d nil)
(c-lang-defconst c-cpp-expr-functions d nil)

(c-lang-defconst c-assignment-operators
  ;; List of all assignment operators.
  d  '("=" "*=" "/=" "%=" "+=" "-=" ">>=" "<<=" ">>>=" "&=" "^=" "^^="
       "|=" "~="))

(c-lang-defconst c-other-op-syntax-tokens
  "List of the tokens made up of characters in the punctuation or
parenthesis syntax classes that have uses other than as expression
operators."
 d (append '("/+" "+/" "..." ".." "!" "*" "&")
	    (c-lang-const c-other-op-syntax-tokens)))

(c-lang-defconst c-block-comment-starter d "/*")
(c-lang-defconst c-block-comment-ender   d "*/")

(c-lang-defconst c-comment-start-regexp  d "/[*+/]")
(c-lang-defconst c-block-comment-start-regexp d "/[*+]")
(c-lang-defconst c-literal-start-regexp
  ;; Regexp to match the start of comments and string literals.
  d "/[*+/]\\|\"\\|`")

(c-lang-defconst c-block-prefix-disallowed-chars
  ;; Allow ':' for inherit list starters.
  d (c--set-difference (c-lang-const c-block-prefix-disallowed-chars)
		       '(?:)))

(c-lang-defconst c-post-protection-token
  d  ":")

;;----------------------------------------------------------------------------

;; Built-in basic types
(c-lang-defconst c-primitive-type-kwds
  d '("bool" "byte" "ubyte" "char" "delegate" "double" "float"
      "function" "int" "long" "short" "uint" "ulong" "ushort"
      "cent" "ucent" "real" "ireal" "idouble" "ifloat" "creal" "cfloat" "cdouble"
      "wchar" "dchar" "void" "string" "wstring" "dstring" "__vector"))

;; Keywords that can prefix normal declarations of identifiers.
;; Union of StorageClass, Attribute, and ParameterAttributes in D grammar.
;; References:
;; - https://dlang.org/spec/grammar.html#Attribute
;; - https://dlang.org/spec/declaration.html#StorageClass
;; - https://dlang.org/spec/grammar.html#ParameterAttributes
(c-lang-defconst c-modifier-kwds
  d '("__gshared" "abstract" "align" "auto" "const" "deprecated"
      "enum" "export" "extern" "final" "immutable" "in" "inout" "lazy"
      "nothrow" "out" "override" "package" "pragma" "private"
      "protected" "public" "pure" "ref" "return" "scope" "shared"
      "static" "synchronized"
      "@property" "@safe" "@trusted" "@system" "@nogc" "@disable"))

(c-lang-defconst c-class-decl-kwds
  ;; Keywords introducing declarations where the following block (if any)
  ;; contains another declaration level that should be considered a class.
  d '("class" "struct" "union" "interface" "template"))

;; (c-lang-defconst c-brace-list-decl-kwds
;;   d '("enum"))

(c-lang-defconst c-type-modifier-kwds
  d nil)

(c-lang-defconst c-type-prefix-kwds
  ;; Keywords where the following name - if any - is a type name, and
  ;; where the keyword together with the symbol works as a type in
  ;; declarations.  In this case, like "mixin foo!(x) bar;"
  d    '("mixin" "align"))

;; Remove "enum" from d-mode's value.
;; By default this c-typedef-decl-kwds includes c-brace-list-decl-kwds,
;; which is '("enum") by default.
;; Instead, parse enums manually (see d-font-lock-enum-body) to avoid
;; confusion with manifest constants.
(c-lang-defconst c-typedef-decl-kwds
  ;; Keywords introducing declarations where the identifier(s) being
  ;; declared are types.
 d (append (c-lang-const c-class-decl-kwds)
	   '("typedef" "alias")))

(c-lang-defconst c-decl-hangon-kwds
  d '("export"))

(c-lang-defconst c-protection-kwds
  ;; Access protection label keywords in classes.
  d '("deprecated" "static" "extern" "final" "synchronized" "override"
      "abstract" "scope"
      "private" "package" "protected" "public" "export"))

(c-lang-defconst c-postfix-spec-kwds
 ;Keywords introducing extra declaration specifiers in the region
 ;between the header and the body (i.e. the "K&R-region") in
 ;declarations.
 d '("if" "in" "out" "body"))

(c-lang-defconst c-recognize-knr-p
  d t)

(c-lang-defconst c-type-list-kwds
  d nil)

(c-lang-defconst c-ref-list-kwds
  d '("import" "module"))

(c-lang-defconst c-colon-type-list-kwds
  ;; Keywords that may be followed (not necessarily directly) by a colon
  ;; and then a comma separated list of type identifiers.
  d  '("class" "enum" "interface"))

(c-lang-defconst c-paren-nontype-kwds
  ;;Keywords that may be followed by a parenthesis expression that doesn't
  ;; contain type identifiers.
  d '("version" "debug" "extern" "pragma" "__traits" "scope"))

(c-lang-defconst d-type-modifier-kwds
  ;; D's type modifiers.
  d '("const" "immutable" "inout" "shared"))

(c-lang-defconst d-type-modifier-key
  ;; Regex of `d-type-modifier-kwds'.
  d (c-make-keywords-re t
      (c-lang-const d-type-modifier-kwds)))

(c-lang-defconst d-common-storage-class-kwds
  ;; D's storage classes (keywords that can prefix or entirely
  ;; substitute a type in a parameter or variable declaration).
  d `(;; Constness
      ,@(c-lang-const d-type-modifier-kwds)
      ;; Storage classes that apply to either parameters and declarations
      "scope"))

(c-lang-defconst d-decl-storage-class-kwds
  d `(;; Common keywords
      ,@(c-lang-const d-common-storage-class-kwds)
      ;; auto (no-effect placeholder)
      "auto"
      ;; Storage class
      "extern" "static" "__gshared"))

(c-lang-defconst d-param-storage-class-kwds
  d `(;; Common keywords
      ,@(c-lang-const d-common-storage-class-kwds)
      ;; Function parameters
      "in" "out" "ref" "lazy"))

(c-lang-defconst d-storage-class-kwds
  d (c--delete-duplicates (append (c-lang-const d-decl-storage-class-kwds)
				  (c-lang-const d-param-storage-class-kwds))
			  :test 'string-equal))

(c-lang-defconst c-paren-type-kwds
  ;; Keywords that may be followed by a parenthesis expression containing
  ;; type identifiers separated by arbitrary tokens.
  d (append (list "delete" "throw" "cast")
	    (c-lang-const d-type-modifier-kwds)))

;; D: Like `c-regular-keywords-regexp', but contains keywords which
;; cannot occur in a function type.  For Emacs 25 imenu.
(c-lang-defconst d-non-func-type-kwds-re
  d (concat "\\<"
	    (c-make-keywords-re t
	      (c--set-difference (c-lang-const c-keywords)
				 (append (c-lang-const c-primitive-type-kwds)
					 (c-lang-const d-decl-storage-class-kwds))
				 :test 'string-equal))))

;; D: Like `c-regular-keywords-regexp', but contains keywords which
;; cannot occur in a function name.  For Emacs 25 imenu.
(c-lang-defconst d-non-func-name-kwds-re
  d (concat "\\<"
	    (c-make-keywords-re t (c-lang-const c-keywords))))

(c-lang-defconst c-block-stmt-1-kwds
  ;; Statement keywords followed directly by a substatement.
  d '("do" "else" "finally" "try" "in" "body"))

(c-lang-defconst c-block-stmt-2-kwds
  ;; Statement keywords followed by a paren sexp and then by a substatement.
  d '("for" "if" "switch" "while" "catch" "synchronized" "scope" "version"
      "foreach" "foreach_reverse" "with" "out" "invariant" "unittest"))

(c-lang-defconst c-simple-stmt-kwds
  ;; Statement keywords followed by an expression or nothing.
  d '("break" "continue" "goto" "return" "throw"))

(c-lang-defconst c-paren-stmt-kwds
  ;; Statement keywords followed by a parenthesis expression that
  ;; nevertheless contains a list separated with ';' and not ','."
  d '("for" "foreach" "foreach_reverse"))

(c-lang-defconst c-asm-stmt-kwds
  ;; Statement keywords followed by an assembler expression.
  d '("asm"))

(c-lang-defconst c-label-kwds
  ;; Keywords introducing colon terminated labels in blocks.
  d '("case" "default"))

(c-lang-defconst c-before-label-kwds
  ;; Keywords that might be followed by a label identifier.
  d '("goto" "break" "continue"))

(c-lang-defconst c-constant-kwds
  ;; Keywords for constants.
  d '("null" "true" "false"))

(c-lang-defconst c-primary-expr-kwds
  ;; Keywords besides constants and operators that start primary expressions.
  d '("this" "super"))

(c-lang-defconst c-inexpr-class-kwds
  ;; Keywords that can start classes inside expressions.
  d nil)

(c-lang-defconst c-inexpr-brace-list-kwds
  ;; Keywords that can start brace list blocks inside expressions.
  d nil)

(c-lang-defconst c-other-decl-kwds
  d (c-lang-const d-storage-class-kwds))

(c-lang-defconst c-decl-start-kwds
  d '("debug" "else"))

(c-lang-defconst c-other-kwds
  ;; Keywords not accounted for by any other `*-kwds' language constant.
  d '("__gshared" "__traits" "assert" "cast" "in" "is" "nothrow" "pure" "ref"
      "sizeof" "typeid" "typeof"))


(c-lang-defconst c-recognize-post-brace-list-type-p
  ;; Set to t when we recognize a colon and then a type after an enum,
  ;; e.g., enum foo : int { A, B, C };"
  d t)

;; Enabled for java-mode, but we don't need it.
;; (We can't reuse this for D templates because this is hard-wired to
;; the < and > characters.)
(c-lang-defconst c-recognize-<>-arglists
  d nil)

;; ----------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; cc-mode patches ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ----------------------------------------------------------------------------

(defmacro d-make-keywords-re (adorn list)
  "Helper to precompute regular expressions for inline keyword lists." ;; checkdoc-params: (adorn list)
  (eval `(c-make-keywords-re ,adorn ,list 'd)))

(defmacro d--static-if (condition new-form &optional old-form)
  "If CONDITION is non-nil at compile time, evaluate NEW-FORM, otherwise OLD-FORM."
  (declare (indent 2))
  (if (eval condition)
      new-form
    old-form))

(defmacro d--if-version>= (min-version new-form &optional old-form)
  "Conditional compilation based on the current Emacs version.

Evaluate OLD-FORM if the Emacs version is older than MIN-VERSION,
  otherwise NEW-FORM."
  (declare (indent 2))
  `(d--static-if (version<= ,min-version emacs-version) ,new-form ,old-form))

;;----------------------------------------------------------------------------
;;; Workaround for special case of 'else static if' not being handled properly
(defun d-special-case-looking-at (orig-fun &rest args)
  ;; checkdoc-params: (orig-fun args)
  "Advice function for fixing cc-mode indentation in certain D constructs."
  (let ((rxp (car args)))
    (if (and (stringp rxp) (string= rxp "if\\>[^_]"))
        (or (apply orig-fun '("static\\>\\s-+if\\>[^_]"))
            (apply orig-fun '("version\\>[^_]"))
            (apply orig-fun '("debug\\>[^_]"))
            (apply orig-fun args))
      (apply orig-fun args))))

(defun d-around--c-add-stmt-syntax (orig-fun &rest args)
  ;; checkdoc-params: (orig-fun args)
  "Advice function for fixing cc-mode indentation in certain D constructs."
  (if (not (c-major-mode-is 'd-mode))
      (apply orig-fun args)
    (add-function :around (symbol-function 'looking-at)
		  #'d-special-case-looking-at)
    (unwind-protect
	(apply orig-fun args)
      (remove-function (symbol-function 'looking-at)
		       #'d-special-case-looking-at))))

(advice-add 'c-add-stmt-syntax :around #'d-around--c-add-stmt-syntax)

;;----------------------------------------------------------------------------

(defun d-forward-keyword-clause (match)
  "D version (complement) of `c-forward-keyword-clause'." ;; checkdoc-params: match

  (let ((kwd-sym (c-keyword-sym (match-string match))) safe-pos pos)

    (when kwd-sym
      (goto-char (match-end match))
      (c-forward-syntactic-ws)
      (setq safe-pos (point))

      (cond
       ;; module and import statements
       ((c-keyword-member kwd-sym 'c-ref-list-kwds)
	(while
	    (progn
	      (c-forward-syntactic-ws)
	      (setq safe-pos (point))
	      (cond
	       ((looking-at c-identifier-start)
		;; identifier
		(setq c-last-identifier-range nil)
		(forward-char)
		(c-end-of-current-token)
		(when c-record-type-identifiers
		  (c-record-ref-id (cons safe-pos (point))))
		t)
	       ;; . or , or = (keep fontifying)
	       ((memq (char-after) '(?. ?, ?=))
		(forward-char)
		t)
	       ;; ; or : or anything else weird
	       (t
		nil))))
	(goto-char safe-pos)
	t)
       ;; Special words after certain keywords
       ((and (c-keyword-member kwd-sym 'c-paren-nontype-kwds)
	     (eq (char-after) ?\())
	(forward-char)
	(c-forward-syntactic-ws)
	(c-forward-keyword-prefixed-id ref)
	(goto-char safe-pos)
	(c-forward-sexp)
	(c-forward-syntactic-ws)
	t)))))

;----------------------------------------------------------------------------

(defun d-forward-decl-or-cast-1 (preceding-token-end context last-cast-end)
  "D version of `c-forward-decl-or-cast-1'." ;; checkdoc-params: (preceding-token-end context last-cast-end)
  ;; (message "(d-forward-decl-or-cast-1 %S %S %S) @ %S" preceding-token-end context last-cast-end (point))

  ;; D: Restore our context, if any
  (when (memq context '(arglist decl))
    (save-excursion
      (c-backward-syntactic-ws)
      (when (> (point) (point-min))
	(setq context (or (c-get-char-property (1- (point)) 'd-context) context)))))

  ;; D: Handle conditional compilation.
  ;; The "debug" keyword, as well as the "else" keyword following a
  ;; "version" or "static if", can start a declaration even without a
  ;; { } block.
  ;; For this reason, these keywords are in `c-decl-start-kwds'.
  ;; However, `c-decl-start-kwds' are considered as part of the
  ;; declaration, so `c-forward-decl-or-cast-1' will be invoked with
  ;; point at the keyword.  Handle this case here.
  ;; Note that other cases (e.g. static if) are handled implicitly by
  ;; their requirement of a parenthesis (')' is in `c-decl-prefix-re').
  (while (looking-at (d-make-keywords-re t (c-lang-const c-decl-start-kwds d)))
    (goto-char (match-end 1))
    (c-forward-syntactic-ws))

  (let (maybe-auto enum decl-start type-start id-start make-top)

    (let (kind)
      (while (setq kind (d-forward-attribute-or-storage-class context))
	(setq maybe-auto t
	      enum (eq kind 'enum))
	;; Skip over "public:" and similar specifiers.
	;; For some reason cc-mode wants us to do it here.
	(when (looking-at ":")
	  (forward-char)
	  (c-forward-syntactic-ws))))

    (setq decl-start (point))

    ;; Discover what kind of enum declaration this is.
    ;; (t if this is an actual list of enumerated values)
    (setq enum
	  (and enum
	       (memq context '(top nil))
	       (save-excursion
		 (and
		  (d-forward-type)
		  (or (looking-at "[:{;]")
		      (and
		       (d-forward-identifier)
		       (progn
			 (c-forward-syntactic-ws)
			 (looking-at "[:{;]"))))))))

    (when
	;; The various kinds of declarations are handled here:
	(cond

	 ;; Aggregate declaration (class/struct ...)
	 ;; Handle enumerations here too.
	 ((and (memq context '(top nil))
	       (or enum
		   (looking-at (d-make-keywords-re t (c-lang-const c-class-decl-kwds d)))))

	  (unless enum
	    (goto-char (match-end 1))
	    (c-forward-syntactic-ws))
	  (setq type-start (point))
	  (setq id-start type-start)

	  (and
	   (d-forward-identifier)
	   (progn
	     (c-forward-syntactic-ws)
	     (looking-at "[:({;]"))))

	 ;; Mixin templates
	 ((and (memq context '(top nil))
	       (looking-at (d-make-keywords-re t '("mixin"))))
	  (goto-char (match-end 1))
	  (c-forward-syntactic-ws)
	  (and
	   (looking-at (d-make-keywords-re t '("template")))
	   (progn
	     (goto-char (match-end 1))
	     (c-forward-syntactic-ws)
	     (setq type-start (point))
	     (setq id-start type-start)
	     (d-forward-identifier))
	   (progn
	     (c-forward-syntactic-ws)
	     (looking-at "("))))

	 ;; Constructors/destructors
	 ((and (eq context 'top)
	       (looking-at (d-make-keywords-re t '("this" "~this"))))
	  (setq id-start decl-start)
	  (goto-char (match-end 1))
	  t)

	 ;; Alias declarations
	 ((and (memq context '(top nil))
	       (looking-at (d-make-keywords-re t '("alias"))))
	  (setq type-start decl-start)	; indicate declaration type for e.g. imenu
	  (goto-char (match-end 1))
	  (c-forward-syntactic-ws)
	  (setq id-start (point))
	  (d-forward-type) ; alias name or value
	  (cond
	   ;; New style (alias name = value)
	   ((memq (char-after) '(?= ?\())
	    t)
	   ;; Old style (alias value name)
	   ((looking-at c-symbol-key)
	    (setq id-start (point))
	    t)))

	 ;; Lambda literal
	 ((and (memq context '(top nil arglist))
	       (save-excursion
		 (and
		  (d-forward-identifier)
		  (progn
		    (c-forward-syntactic-ws)
		    (looking-at "=>")))))
	  (setq id-start decl-start)
	  t)

	 ;; Function / variable / constant declaration, i.e. an
	 ;; (optional) type followed by an identifier.
	 ((and (memq context '(top nil))
	       ;; Declaration type, or identifier for auto
	       ;; declarations.  Note that all identifiers
	       ;; are also valid types.
	       (d-forward-type))

	  (setq type-start decl-start)
	  (setq id-start (point))

	  (cond
	   ;; auto-declaration
	   ((and maybe-auto
		 (looking-at (c-lang-const d-decl-end-re)))
	    (setq id-start type-start)
	    (setq type-start nil)
	    t)
	   ;; regular declaration
	   ((and (d-forward-identifier)
		 (progn
		   (c-forward-syntactic-ws)
		   (looking-at (c-lang-const d-decl-end-re))))
	    t)))

	 ;; Function parameter list.
	 ;; Note: single (type-less) identifiers in parameter lists
	 ;; mean different things for function and lambda parameter
	 ;; lists.  For functions, they indicate the type of an
	 ;; anonymous parameter; for lambdas, they indicate the name
	 ;; of a parameter with an inferred type.
	 ((and (memq context '(decl varlist))
	       (d-forward-type))
	  (setq type-start decl-start)
	  (setq id-start (point))
	  (cond
	   ;; Type or name only
	   ((looking-at "[,=);]")
	    (when (eq context 'varlist)
	      (setq id-start type-start)
	      (setq type-start nil))
	    t)
	   ;; Parameter name
	   ((d-forward-identifier)
	    (c-forward-syntactic-ws)
	    (looking-at "[,=);]")))))

      ;; Valid declaration, process it.

      (when (and c-record-type-identifiers type-start)
	(let ((c-promote-possible-types t))
	  (save-excursion
	    (goto-char type-start)
	    (d-forward-type))))

      (when (and (memq context '(decl varlist))
		 (eq (char-after) ?,))
	;; As in c-forward-decl-or-cast-1:
	;; Make sure to propagate the `c-decl-arg-start' property to
	;; the next argument if it's set in this one, to cope with
	;; interactive refontification.
	(c-put-c-type-property (point) 'c-decl-arg-start)
	;; D: Also save whether we're in a varlist.
	(c-put-char-property (point) 'd-context context))

      (when (and (memq context '(top nil))
		 (eq (char-after) ?\())
	;; Move point past the parameter list (end of declaration) to
	;; communicate to cc-mode that the parens represent parameters,
	;; and not arguments.
	(c-forward-sexp)
	(c-forward-syntactic-ws)
	;; Template arguments?
	(when (eq (char-after) ?\()
	  (c-forward-sexp)
	  (c-forward-syntactic-ws)))

      (d--if-version>= "26.0"
	  (list id-start
		nil
		nil
		type-start
		(or (eq context 'top) make-top))
	(list id-start)))))


(defun d-around--c-forward-decl-or-cast-1 (orig-fun &rest args)
  ;; checkdoc-params: (orig-fun args)
  "Advice function for patching D support into cc-mode."
  (apply
   (if (c-major-mode-is 'd-mode)
       #'d-forward-decl-or-cast-1
     orig-fun)
   args))
(advice-add 'c-forward-decl-or-cast-1 :around #'d-around--c-forward-decl-or-cast-1)

;----------------------------------------------------------------------------

(defun d-forward-identifier ()
  "Advance point by one D identifier."
  (when (and (not (looking-at c-keywords-regexp))
	     (looking-at c-symbol-key))
    (goto-char (match-end 0))
    t))


(defun d-forward-attribute-or-storage-class (context)
  "Handle D attributes and storage classes in declarations.

Advance point and return non-nil if looking at something that may prefix a
declaration (or follow the argument list, in case of functions).

CONTEXT is as in `c-forward-decl-or-cast-1'."
  ;; Note that this includes UDAs.
  (let ((start (point))
	(kind t)
	match-index)
    (when
	(cond
	 ((looking-at (d-make-keywords-re t '("enum")))
	  (setq match-index 1
		kind 'enum))
	 ((looking-at (d-make-keywords-re t '("scope")))
	  (setq match-index 1
		kind 'scope))
	 ((and (eq context nil)
	       (looking-at (d-make-keywords-re t '("return"))))
	  nil)
	 ((looking-at (d-make-keywords-re t (c-lang-const d-type-modifier-kwds d)))
	  (setq match-index 1
		kind 'type-modifier))
	 ((looking-at (d-make-keywords-re t (c-lang-const c-modifier-kwds d)))
	  (setq match-index 1))
	 ((and (eq (char-after) ?@)
	       (looking-at c-symbol-key))
	  (setq match-index 0)))
      (goto-char (match-end match-index))
      (c-forward-syntactic-ws)
      ;; Skip parameters, such as:
      ;; - extern(C)
      ;; - deprecated("...")
      ;; - package(std)
      ;; - @SomeUDA(...)
      (if (looking-at "(")
	  ;; 1. Distinguish between "const x" and "const(x)".  In the
	  ;; former, "const" is an attribute, but in the latter it is
	  ;; part of a type.  This distinction is important when parsing
	  ;; constructs where a type is required; a greedy attribute
	  ;; match would leave only "(x)" which will not make sense.
	  ;; 2. Distinguish between scope variables (e.g. "scope x = new
	  ;; ...") and scope statements (e.g. "scope(exit) { ... }").
	  (if (memq kind '(type-modifier scope))
	      (progn
		(goto-char start)
		nil)
	    (c-go-list-forward)
	    (c-forward-syntactic-ws)
	    kind)
	kind))))

;;----------------------------------------------------------------------------

(defun d-around--c-get-fontification-context (orig-fun match-pos &rest args)
  ;; checkdoc-params: (orig-fun match-pos args)
  "Advice function for fixing cc-mode handling of D lambda parameter lists."
  (let ((res (apply orig-fun match-pos args))
	(type 'varlist))
    ;; (message "(c-get-fontification-context %S) @ %S -> %S" args (point) res)
    (when (and
	   (c-major-mode-is 'd-mode)
	   (memq (car res) '(nil arglist))
	   (save-excursion
	     (and
	      (progn
		(goto-char match-pos)
		(c-backward-syntactic-ws)
		(eq (char-before) ?\())
	      (progn
		(backward-char)
		(or
		 (save-excursion
		   (and
		    (c-backward-token-2)
		    (cond
		     ((looking-at (d-make-keywords-re t '("if" "while" "for" "switch"
							  "with" "synchronized")))
		      (setq type nil)
		      t)
		     ((looking-at (d-make-keywords-re t '("foreach" "foreach_reverse")))
		      t)
		     ((looking-at (d-make-keywords-re t '("catch")))
		      (setq type 'decl)
		      t))))
		 (condition-case nil
		     (progn
		       (c-forward-sexp)
		       (c-forward-syntactic-ws)
		       (while (d-forward-attribute-or-storage-class 'top))
		       (or
			(eq (char-after) ?\{)
			(looking-at "=>")))
		   (error nil)))))))

      (setq res (cons type t))
      ;; (message "   patching -> %S" res)
      )
    res))
(advice-add 'c-get-fontification-context :around #'d-around--c-get-fontification-context)

;;----------------------------------------------------------------------------
;; Borrowed from https://github.com/josteink/csharp-mode/blob/master/csharp-mode.el

(defmacro d--syntax-propertize-string (open close)
  (unless (eq (length close) 1)
    (error "`close' should be a single character"))
  (let ((syntax-punctuation (string-to-syntax "."))
	(skip-chars-pattern (concat "^" close "\\\\"))
	(close-char (elt close 0)))
    `(progn
       (goto-char beg)
       (while (search-forward ,open end t)
	 (let ((in-comment-or-string-p (save-excursion
					 (goto-char (match-beginning 0))
					 (or (nth 3 (syntax-ppss))
                                             (nth 4 (syntax-ppss))))))
           (when (not in-comment-or-string-p)
             (let (done)
               (while (and (not done) (< (point) end))
		 (skip-chars-forward ',skip-chars-pattern end)
		 (cond
		  ((eq (following-char) ?\\)
                   (put-text-property (point) (1+ (point))
                                      'syntax-table ',syntax-punctuation)
                   (forward-char 1))
		  ((eq (following-char) ',close-char)
                   (forward-char 1)
		   (setq done t)))))))))))

(defun d--syntax-propertize-function (beg end)
  "Apply syntax table properties to special constructs in region BEG to END.
Handles `...` and r\"...\" WYSIWYG string literals."
  (save-excursion
    (d--syntax-propertize-string "`" "`")
    (d--syntax-propertize-string "r\"" "\"")))

;;----------------------------------------------------------------------------

(defun d--on-func-identifier ()
  "Version of `c-on-identifier', but also match D constructors."

  (save-excursion
    (skip-syntax-backward "w_")

    ;; Check for a normal (non-keyword) identifier.
    (and (looking-at c-symbol-start)
	 (or
	  (looking-at (d-make-keywords-re t '("this" "~this")))
	  (not (looking-at c-keywords-regexp)))
	 (point))))

(defun d-in-knr-argdecl (&optional lim)
  "Modified version of `c-in-knr-argdecl' for d-mode." ;; checkdoc-params: lim
  (save-excursion
    ;; If we're in a macro, our search range is restricted to it.  Narrow to
    ;; the searchable range.
    (let* ((start (point))
	   before-lparen
	   after-rparen
	   (pp-count-out 20)	; Max number of paren/brace constructs before
				; we give up.
	   knr-start
	   c-last-identifier-range)

      (catch 'knr
	(while (> pp-count-out 0) ; go back one paren/bracket pair each time.
	  (setq pp-count-out (1- pp-count-out))
	  (c-syntactic-skip-backward "^)]}=;")
	  (cond ((eq (char-before) ?\))
		 (setq after-rparen (point)))
		((eq (char-before) ?\])
		 (setq after-rparen nil))
		(t ; either } (hit previous defun) or = or no more
					; parens/brackets.
		 (throw 'knr nil)))

	  (if after-rparen
	      ;; We're inside a paren.  Could it be our argument list....?
	      (if
		  (and
		   (progn
		     (goto-char after-rparen)
		     (unless (c-go-list-backward) (throw 'knr nil)) ;
		     ;; FIXME!!!  What about macros between the parens?  2007/01/20
		     (setq before-lparen (point)))

		   ;; It can't be the arg list if next token is ; or {
		   (progn (goto-char after-rparen)
			  (c-forward-syntactic-ws)
			  (not (memq (char-after) '(?\; ?\{ ?\=))))

		   ;; Is the thing preceding the list an identifier (the
		   ;; function name), or a macro expansion?
		   (progn
		     (goto-char before-lparen)
		     (eq (c-backward-token-2) 0)
		     (or (eq (d--on-func-identifier) (point))
			 (and (eq (char-after) ?\))
			      (c-go-up-list-backward)
			      (eq (c-backward-token-2) 0)
			      (eq (d--on-func-identifier) (point)))))

		   ;; Check that we're outside of the template arg list (D-specific).
		   (progn
		     (setq knr-start
			   (progn (goto-char after-rparen)
				  (c-forward-syntactic-ws)
				  (when (eq (char-after) ?\()
				    (c-go-list-forward)
				    (c-forward-syntactic-ws))
				  (point)))
		     (<= knr-start start))

		   ;; (... original c-in-knr-argdecl logic omitted here ...)
		   t)
		  ;; ...Yes.  We've identified the function's argument list.
		  (throw 'knr knr-start)
		;; ...No.  The current parens aren't the function's arg list.
		(goto-char before-lparen))

	    (or (c-go-list-backward)	; backwards over [ .... ]
		(throw 'knr nil))))))))

(defun d-around--c-in-knr-argdecl (orig-fun &rest args)
  ;; checkdoc-params: (orig-fun args)
  "Advice function for fixing cc-mode indentation in certain D constructs."
  (apply
   (if (c-major-mode-is 'd-mode)
       #'d-in-knr-argdecl
     orig-fun)
   args))

(advice-add 'c-in-knr-argdecl :around #'d-around--c-in-knr-argdecl)

;;----------------------------------------------------------------------------

(defun d-forward-type (&optional brace-block-too)
  "Modified version of `c-forward-type' for d-mode." ;; checkdoc-params: brace-block-too
  (let ((start (point)) pos res name-res id-start id-end id-range)

    (cond
     ;; D: "this" is not a type, even though it appears at the
     ;; beginning of a "function" (constructor) declaration.
     ((looking-at (d-make-keywords-re t '("this")))
      nil)

     ;; D: const/immutable/...(...)
     ((looking-at (c-lang-const d-type-modifier-key))
      (when
	  (and
	   ;; Followed by a ( ?
	   (progn
	     (goto-char (match-end 1))
	     (c-forward-syntactic-ws)
	     (looking-at "("))
	   ;; Followed by a type in the parens?
	   (progn
	     (forward-char)
	     (c-forward-syntactic-ws)
	     (d-forward-type))
	   ;; Followed by a closing ) ?
	   (progn
	     (c-forward-syntactic-ws)
	     (looking-at ")")))
	(forward-char)
	(c-forward-syntactic-ws)
	(setq res 'prefix)))

     ;; Identifier
     ((progn
	(setq pos nil)
	(when (looking-at "[.]")
	  (forward-char)
	  (c-forward-syntactic-ws))
	(if (looking-at c-identifier-start)
	    (save-excursion
	      (setq id-start (point)
		    name-res (c-forward-name))
	      (when name-res
		(setq id-end (point)
		      id-range c-last-identifier-range))))
	(and (cond ((looking-at c-primitive-type-key)
		    (setq res t))
		   ((c-with-syntax-table c-identifier-syntax-table
		      (looking-at c-known-type-key))
		    (setq res 'known)))
	     (or (not id-end)
		 (>= (save-excursion
		       (save-match-data
			 (goto-char (match-end 1))
			 (c-forward-syntactic-ws)
			 (setq pos (point))))
		     id-end)
		 (setq res nil))))
      ;; Looking at a primitive or known type identifier.  We've
      ;; checked for a name first so that we don't go here if the
      ;; known type match only is a prefix of another name.

      (setq id-end (match-end 1))

      (when (and c-record-type-identifiers
		 (or c-promote-possible-types (eq res t)))
	(c-record-type-id (cons (match-beginning 1) (match-end 1))))

      (unless (save-match-data (c-forward-keyword-clause 1))
        (if pos
            (goto-char pos)
          (goto-char (match-end 1))
          (c-forward-syntactic-ws))))

     (name-res
      (cond ((eq name-res t)
	     ;; A normal identifier.
	     (goto-char id-end)
	     (if (or res c-promote-possible-types)
		 (progn
		   (c-add-type id-start id-end)
		   (when (and c-record-type-identifiers id-range)
		     (c-record-type-id id-range))
		   (unless res
		     (setq res 'found)))
	       (setq res (if (c-check-type id-start id-end)
			     ;; It's an identifier that has been used as
			     ;; a type somewhere else.
			     'found
			   ;; It's an identifier that might be a type.
			   'maybe))))
	    (t
	     ;; Otherwise it's an operator identifier, which is not a type.
	     (goto-char start)
	     (setq res nil)))))

    (when res
      ;; D: Skip over template parameters, if any
      (when (looking-at "!")
	(forward-char)
	(c-forward-syntactic-ws)
	(c-forward-sexp)
	(c-forward-syntactic-ws))

      ;; D: Descend into scope names
      (when (looking-at "[.]")
	(unless (d-forward-type)
	  (setq res nil)))

      ;; Step over any type suffix operator.  Do not let the existence
      ;; of these alter the classification of the found type, since
      ;; these operators typically are allowed in normal expressions
      ;; too.
      (when c-opt-type-suffix-key	; e.g. "..."
	(while (looking-at c-opt-type-suffix-key)
	  (goto-char (match-end 1))
	  (c-forward-syntactic-ws)))

      (when (and c-record-found-types (memq res '(known found)) id-range)
	(setq c-record-found-types
	      (cons id-range c-record-found-types))))

    ;;(message "c-forward-type %s -> %s: %s" start (point) res)

    res))

(defun d-around--c-forward-type (orig-fun &rest args)
  ;; checkdoc-params: (orig-fun args)
  "Advice function for fixing fontification for D enums."
  (apply
   (if (c-major-mode-is 'd-mode)
       #'d-forward-type
     orig-fun)
   args))

(advice-add 'c-forward-type :around #'d-around--c-forward-type)

;;----------------------------------------------------------------------------

(c-lang-defconst d-flat-decl-maybe-block-kwds
  ;; Keywords which don't introduce a scope, and may or may not be
  ;; followed by a {...} block.
  d (append (c-lang-const c-modifier-kwds)
	    (list "else" ; for version / static if
		  "if" ; static if
		  "version")))
(c-lang-defconst d-flat-decl-maybe-block-re
  d (c-make-keywords-re t (c-lang-const d-flat-decl-maybe-block-kwds)))

(defun d-update-brace-stack (stack from to)
  "Modified version of `c-update-brace-stack' for d-mode." ;; checkdoc-params: (stack from to)
  (d--if-version>= "26.0"
      ;; Given a brace-stack which has the value STACK at position FROM, update it
      ;; to its value at position TO, where TO is after (or equal to) FROM.
      ;; Return a cons of either TO (if it is outside a literal) and this new
      ;; value, or of the next position after TO outside a literal and the new
      ;; value.
      (let (match kwd-sym (prev-match-pos 1)
		  (s (cdr stack))
		  (bound-<> (car stack)))
	(save-excursion
	  (cond
	   ((and bound-<> (<= to bound-<>))
	    (goto-char to))			; Nothing to do.
	   (bound-<>
	    (goto-char bound-<>)
	    (setq bound-<> nil))
	   (t (goto-char from)))
	  (while (and (< (point) to)
		      (c-syntactic-re-search-forward
		       (if (<= (car s) 0)
			   c-brace-stack-thing-key
			 c-brace-stack-no-semi-key)
		       to 'after-literal)
		      (> (point) prev-match-pos)) ; prevent infinite loop.
	    (setq prev-match-pos (point))
	    (setq match (match-string-no-properties 1)
		  kwd-sym (c-keyword-sym match))
	    (cond
	     ((and (equal match "{")
		   (progn (backward-char)
			  (prog1 (looking-at "\\s(")
			    (forward-char))))
	      (setq s (if s
			  ;; D: Constructs such as "version", "static if", or
			  ;; "extern(...)" may or may not enclose their declarations
			  ;; in a {...} block. For this reason, we can't blindly
			  ;; update the cc-mode brace stack when we see these keywords
			  ;; (otherwise, if they are not immediately succeeded by a
			  ;; {...} block, then the brace stack change will apply to
			  ;; the next encountered {...} block such as that of a
			  ;; function's).
			  (if (save-excursion
				(backward-char)
				(c-backward-syntactic-ws)
				(when (eq (char-before) ?\))
				  (c-backward-sexp)
				  (c-backward-syntactic-ws))
				(c-backward-token-2)
				(looking-at (c-lang-const d-flat-decl-maybe-block-re)))
			      ;; D: Keep the brace stack state from the parent
			      ;; context. I.e., the contents of a "static if" at the
			      ;; top level should remain top-level, but in a function,
			      ;; it should remain non-top-level.
			      (if (<= (car s) 1)
				  (cons 1 s)
				(cons (1+ (car s)) (cdr s)))
			    (cons (if (<= (car s) 0)
				      1
				    (1+ (car s)))
				  (cdr s)))
			(list 1))))
	     ((and (equal match "}")
		   (progn (backward-char)
			  (prog1 (looking-at "\\s)")
			    (forward-char))))
	      (setq s
		    (cond
		     ((and s (> (car s) 1))
		      (cons (1- (car s)) (cdr s)))
		     ((and (cdr s) (eq (car s) 1))
		      (cdr s))
		     (t s))))
	     ((and (equal match ":")
		   s
		   (eq (car s) 0))
	      (setq s (cons -1 (cdr s))))
	     ((and (equal match ",")
		   (eq (car s) -1)))	; at "," in "class foo : bar, ..."
	     ;; D: Ignore ")", which can be part of parameter lists
	     ((member match '(";" ","))
	      (when (and s (cdr s) (<= (car s) 0))
		(setq s (cdr s))))
	     ((c-keyword-member kwd-sym 'c-flat-decl-block-kwds)
	      (push 0 s))))
	  ;; The failing `c-syntactic-re-search-forward' may have left us in the
	  ;; middle of a token, which might be a significant token.  Fix this!
	  (c-beginning-of-current-token)
	  (cons (point)
		(cons bound-<> s))))
    (error "Unsupported Emacs version")))

(defun d-around--c-update-brace-stack (orig-fun &rest args)
  ;; checkdoc-params: (orig-fun args)
  "Advice function for fixing cc-mode handling of certain D constructs."
  (apply
   (if (c-major-mode-is 'd-mode)
       #'d-update-brace-stack
     orig-fun)
   args))

(d--if-version>= "26.0"
    (advice-add 'c-update-brace-stack :around #'d-around--c-update-brace-stack))

;; ----------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; compilation-mode support ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ----------------------------------------------------------------------------

;;; Patterns to recognize the compiler generated messages

(defun d-mode-add-dmd-message-pattern (expr level symbol)
  "Register DMD `compile' pattern for an error level.

EXPR is the `rx' message sub-expression indicating the error level LEVEL.
The expression is added to `compilation-error-regexp-alist' and
`compilation-error-regexp-alist-alist' as SYMBOL."
  (add-to-list
   'compilation-error-regexp-alist-alist
   `(,symbol
     ,(rx-to-string
      `(and
	line-start
	(group-n 1 (one-or-more any))		; File name
	"("
	(group-n 2 (one-or-more digit))		; Line number
	(zero-or-one
	 ","
	 (group-n 3 (one-or-more digit)))	; Column number
	"): "
	,expr
	(group-n 4 (one-or-more nonl))		; Message
	line-end))
     1 2 3 ,level 4))
  (add-to-list 'compilation-error-regexp-alist symbol))

(d-mode-add-dmd-message-pattern "Error: "          2 'dmd-error       )
(d-mode-add-dmd-message-pattern "Warning: "        1 'dmd-warning     )
(d-mode-add-dmd-message-pattern "Deprecation: "    1 'dmd-deprecation )
(d-mode-add-dmd-message-pattern '(one-or-more " ") 0 'dmd-continuation)

;; The following regexp recognizes messages generated by the D runtime for
;; unhandled exceptions (e.g. assert failures).

(add-to-list 'compilation-error-regexp-alist-alist
             '(d-exceptions
               "^[a-zA-Z0-9.]*?@\\(.*?\\)(\\([0-9]+\\)):"
               1 2 nil 2))
(add-to-list 'compilation-error-regexp-alist 'd-exceptions)


;; ----------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; imenu support ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ----------------------------------------------------------------------------

;; Old imenu implementation - regular expressions:

(eval-when-compile
  (defconst d--imenu-rx-def-start
    '(seq
      ;; Conditionals
      (zero-or-one
       "else"
       (zero-or-more space))
      (zero-or-one
       "version"
       (zero-or-more space)
       "("
       (zero-or-more space)
       (one-or-more (any "a-zA-Z0-9_"))
       (zero-or-more space)
       ")"
       (zero-or-more space))

      (zero-or-more
       (or
	word-start
	(or
	 ;; StorageClass
	 "deprecated"
	 "static"
	 "extern"
	 "abstract"
	 "final"
	 "override"
	 "synchronized"
	 "scope"
	 "nothrow"
	 "pure"
	 "ref"
	 (seq
	  (or
	   "extern"
	   "deprecated"
	   "package"
	   )
	  (zero-or-more space)
	  "("
	  (zero-or-more space)
	  (one-or-more (not (any "()")))
	  (zero-or-more space)
	  ")")

	 ;; VisibilityAttribute
	 "private"
	 "package"
	 "protected"
	 "public"
	 "export"
	 )

	;; AtAttribute
	(seq
	 "@"
	 (one-or-more (any "a-zA-Z0-9_"))
	 (zero-or-one
	  (zero-or-more space)
	  "("
	  (zero-or-more space)
	  (one-or-more (not (any "()")))
	  (zero-or-more space)
	  ")")))
       (zero-or-more space))

      )))

(defconst d-imenu-method-name-pattern
  (rx
   ;; Whitespace
   bol
   (zero-or-more space)

   (eval d--imenu-rx-def-start)

   ;; Type
   (group
    (one-or-more (any "a-zA-Z0-9_.*![]()")))
   (one-or-more space)

   ;; Function name
   (group
    (one-or-more (any "a-zA-Z0-9_")))
   (zero-or-more space)

   ;; Type arguments
   (zero-or-one
    "(" (zero-or-more (not (any ")"))) ")"
    (zero-or-more (any " \t\n")))

   ;; Arguments
   "("
   (zero-or-more (not (any "()")))
   (zero-or-more
    "("
    (zero-or-more (not (any "()")))
    ")"
    (zero-or-more (not (any "()"))))
   ")"
   (zero-or-more (any " \t\n"))

   ;; Pure/const etc.
   (zero-or-more
    (one-or-more (any "a-z@"))
    symbol-end
    (zero-or-more (any " \t\n")))

   (zero-or-more
    "//"
    (zero-or-more not-newline)
    (zero-or-more space))

   ;; ';' or 'if' or '{'
   (or
    ";"
    (and
     (zero-or-more (any " \t\n"))
     (or "if" "{")))
   ))

(defun d-imenu-method-index-function ()
  "Find D function declarations for imenu."
  (and
   (let ((pt))
     (setq pt (re-search-backward d-imenu-method-name-pattern nil t))
     ;; The method name regexp will match lines like
     ;; "return foo(x);" or "static if(x) {"
     ;; so we exclude type name 'static' or 'return' here
     (while (let ((type (match-string 1))
		  (name (match-string 2)))
              (and pt name
                   (save-match-data
		     (or
		      (string-match (c-lang-const d-non-func-type-kwds-re) type)
		      (string-match (c-lang-const d-non-func-name-kwds-re) name)))))
       (setq pt (re-search-backward d-imenu-method-name-pattern nil t)))
     pt)
   ;; Do not count invisible definitions.
   (let ((invis (invisible-p (point))))
     (or (not invis)
         (progn
           (while (and invis
                       (not (bobp)))
             (setq invis (not (re-search-backward
                               d-imenu-method-name-pattern nil 'move))))
           (not invis))))))

(defvar d-imenu-generic-expression
  `(("*Classes*"
     ,(rx
       bol
       (zero-or-more space)
       (eval d--imenu-rx-def-start)
       word-start
       "class"
       (one-or-more (syntax whitespace))
       (submatch
	(one-or-more
	 (any ?_
	      (?0 . ?9)
	      (?A . ?Z)
	      (?a . ?z)))))
     1)
    ("*Interfaces*"
     ,(rx
       bol
       (zero-or-more space)
       (eval d--imenu-rx-def-start)
       word-start
       "interface"
       (one-or-more (syntax whitespace))
       (submatch
	(one-or-more
	 (any ?_
	      (?0 . ?9)
	      (?A . ?Z)
	      (?a . ?z)))))
     1)
    ("*Structs*"
     ,(rx
       bol
       (zero-or-more space)
       (eval d--imenu-rx-def-start)
       word-start
       "struct"
       (one-or-more (syntax whitespace))
       (submatch
	(one-or-more
	 (any ?_
	      (?0 . ?9)
	      (?A . ?Z)
	      (?a . ?z)))))
     1)
    ("*Templates*"
     ,(rx
       bol
       (zero-or-more space)
       (eval d--imenu-rx-def-start)
       (zero-or-one
	"mixin"
	(one-or-more (syntax whitespace)))
       word-start
       "template"
       (one-or-more (syntax whitespace))
       (submatch
	(one-or-more
	 (any ?_
	      (?0 . ?9)
	      (?A . ?Z)
	      (?a . ?z)))))
     1)
    ("*Enums*"
     ,(rx
       bol
       (zero-or-more space)
       (eval d--imenu-rx-def-start)
       word-start
       "enum"
       (one-or-more (syntax whitespace))
       (submatch
	(one-or-more
	 (any ?_
	      (?0 . ?9)
	      (?A . ?Z)
	      (?a . ?z))))
       (zero-or-more (any " \t\n"))
       (or ":" "{"))
     1)
    ;; NB: We can't easily distinguish aliases declared outside
    ;; functions from local ones, so just search for those that are
    ;; declared at the beginning of lines.
    ("*Aliases*"
     ,(rx
       bol
       (eval d--imenu-rx-def-start)
       "alias"
       (one-or-more (syntax whitespace))
       (submatch
	(one-or-more
	 (any ?_
	      (?0 . ?9)
	      (?A . ?Z)
	      (?a . ?z))))
       (zero-or-more (syntax whitespace))
       (zero-or-one
        "("
        (zero-or-more (not (any "()")))
        ")"
        (zero-or-more (syntax whitespace)))
       "=")
     1)
    ("*Aliases*"
     ,(rx
       bol
       (eval d--imenu-rx-def-start)
       "alias"
       (one-or-more (syntax whitespace))
       (one-or-more
	(not (any ";")))
       (one-or-more (syntax whitespace))
       (submatch
	(one-or-more
	 (any ?_
	      (?0 . ?9)
	      (?A . ?Z)
	      (?a . ?z))))
       (zero-or-more (syntax whitespace))
       ";"
       (zero-or-more (syntax whitespace))
       (or
	eol
	"//"
	"/*")
       )
     1)
    (nil d-imenu-method-index-function 2)))

;;----------------------------------------------------------------------------
;; New imenu implementation - use cc-mode machinery:

(defun d-imenu-create-index-function ()
  "Create imenu entries for D-mode."
  (d--if-version>= "26.0"
      (progn
	(goto-char (point-min))
	(c-save-buffer-state
	    (d-spots last-spot (d-blocks (make-hash-table)))
	  (c-find-decl-spots
	   (point-max)
	   c-decl-start-re
	   (eval c-maybe-decl-faces)
	   (lambda (match-pos inside-macro toplev)
	     (when toplev
	       (let* ((got-context
		       (c-get-fontification-context
			match-pos nil toplev))
		      (context (car got-context))
		      (decl-or-cast
		       (when (eq context 'top)
			 (d-forward-decl-or-cast-1
			  match-pos
			  context
			  nil ; last-cast-end
			  ))))
		 (when (and decl-or-cast (not (eq (car decl-or-cast) last-spot)))
		   (let* ((decl-end (point))
			  (id-start (progn
				      (goto-char (car decl-or-cast))
				      (when (eq (char-after) ?=)
					(c-backward-syntactic-ws)
					(c-simple-skip-symbol-backward))
				      (point)))
			  (id-end (progn
				    (goto-char id-start)
				    (cond
				     ((d-forward-identifier)
				      (point))
				     ((looking-at (d-make-keywords-re t '("this" "~this")))
				      (match-end 1)))))
			  (name (when id-end
				  (buffer-substring-no-properties id-start id-end)))
			  (id-prev-token (progn
					   (goto-char id-start)
					   (c-backward-syntactic-ws)
					   (let ((end (point)))
					     (when (c-simple-skip-symbol-backward)
					       (buffer-substring-no-properties (point) end)))))
			  (type-start (cadddr decl-or-cast))
			  (type-token (and type-start
					   (progn
					     (goto-char type-start)
					     (looking-at c-symbol-key))
					   (match-string-no-properties 0)))
			  (type-prev-token (when type-start
					     (goto-char type-start)
					     (c-backward-syntactic-ws)
					     (let ((end (point)))
					       (when (c-simple-skip-symbol-backward)
						 (buffer-substring-no-properties (point) end)))))
			  (next-char (when id-end
				       (goto-char id-end)
				       (c-forward-syntactic-ws)
				       (char-after)))
			  (res (cond
				((null name)
				 nil)
				((equal id-prev-token "else")
				 nil) ; false positive after else
				((equal name "{")
				 nil) ; false positive with decl-start keyword and {...} group
				((equal id-prev-token "enum")
				 '("Enums" t))
				((equal id-prev-token "class")
				 '("Classes" t))
				((equal id-prev-token "struct")
				 '("Structs" t))
				((equal id-prev-token "template")
				 '("Templates" t))
				((equal id-prev-token "alias")
				 '("Aliases" nil))
				((equal type-token "alias")
				 '("Aliases" nil)) ; old-style alias
				((memq next-char '(?\; ?= ?,))
				 nil) ; '("variable" nil))
				((member name '("import" "if"))
				 nil) ; static import/if
				((memq next-char '(?\())
				 '(nil t)) ; function
				(t ; unknown
				 (list id-prev-token nil))))
			  (kind (car res))
			  (have-block (cadr res))
			  (paren-state (when res (c-parse-state)))
			  (outer-brace match-pos)
			  d-context
			  d-fqname)

		     (when res
		       (when paren-state
			 ;; Find brace with known context
			 (while (and outer-brace
				     (not d-context))
			   (setq outer-brace (c-most-enclosing-brace paren-state outer-brace))
			   (setq d-context (gethash outer-brace d-blocks))))

		       (setq d-fqname (if d-context (concat d-context "." name) name))

		       (when have-block
			 (goto-char decl-end)
			 (when (and (c-syntactic-re-search-forward "[{};]" nil t)
				    (eq (char-before) ?{))
			   (puthash (1- (point)) d-fqname d-blocks)))

		       (setq last-spot (car decl-or-cast)
			     d-spots
			     (cons
			      (if kind
				  (cons kind (list (cons d-fqname id-start)))
				(cons d-fqname id-start))
			      d-spots)))))))))
	  (nreverse d-spots)))
    (error "Unsupported Emacs version")))

;; ----------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; Major mode definition ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ----------------------------------------------------------------------------

(defcustom d-font-lock-extra-types nil
  "*List of extra types (aside from the type keywords) to recognize in D mode.

Each list item should be a regexp matching a single identifier."
  :type '(repeat regexp)
  :group 'd-mode)

(c-lang-defconst c-basic-matchers-after
  d (append
     ;; D keywords
     (list (c-make-font-lock-BO-decl-search-function
	    (concat "\\_<"
		    (c-make-keywords-re t (append (c-lang-const c-ref-list-kwds d)
						  (c-lang-const c-paren-nontype-kwds d))
					'd))
            '((c-fontify-types-and-refs ()
        	(d-forward-keyword-clause 1)
        	(if (> (point) limit) (goto-char limit))))))
     ;; cc-mode defaults
     (c-lang-const c-basic-matchers-after)))

(defconst d-font-lock-keywords-1 (c-lang-const c-matchers-1 d)
  "Minimal highlighting for D mode.")

(defconst d-font-lock-keywords-2 (c-lang-const c-matchers-2 d)
  "Fast normal highlighting for D mode.")

(defconst d-font-lock-keywords-3 (c-lang-const c-matchers-3 d)
  "Accurate normal highlighting for D mode.")

(defvar d-font-lock-keywords d-font-lock-keywords-3
  "Default expressions to highlight in D mode.")

(defun d-font-lock-keywords-2 ()
  "Function to get fast normal highlighting for D mode."
  (c-compose-keywords-list d-font-lock-keywords-2))
(defun d-font-lock-keywords-3 ()
  "Function to get accurate normal highlighting for D mode."
  (c-compose-keywords-list d-font-lock-keywords-3))
(defun d-font-lock-keywords ()
  "Function to get default expressions to highlight in D mode."
  (c-compose-keywords-list d-font-lock-keywords))

(defvar d-mode-syntax-table nil
  "Syntax table used in d-mode buffers.")
(or d-mode-syntax-table
    (setq d-mode-syntax-table
	 (let ((table (funcall (c-lang-const c-make-mode-syntax-table d))))
	   ;; Make it recognize D `backquote strings`
	   (modify-syntax-entry ?` "\"" table)

	   ;; Make it recognize D's nested /+ +/ comments
	   (modify-syntax-entry ?+  ". 23n"   table)
	   table)))

(defvar d-mode-abbrev-table nil
  "Abbreviation table used in d-mode buffers.")
(c-define-abbrev-table 'd-mode-abbrev-table
  ;; Use the abbrevs table to trigger indentation actions
  ;; on keywords that, if they occur first on a line, might alter the
  ;; syntactic context.
  ;; Syntax for abbrevs is:
  ;; ( pattern replacement command initial-count)
  '(("else" "else" c-electric-continued-statement 0)
    ("while" "while" c-electric-continued-statement 0)
    ("catch" "catch" c-electric-continued-statement 0)
    ("finally" "finally" c-electric-continued-statement 0)))

(defvar d-mode-map ()
  "Keymap used in d-mode buffers.")
(if d-mode-map
    nil
  (setq d-mode-map (c-make-inherited-keymap))
  ;; Add bindings which are only useful for D
  ;; (define-key d-mode-map "\C-c\C-e"  'd-cool-function)
  )

(c-lang-defconst c-mode-menu
  ;; The definition for the mode menu.  The menu title is prepended to
  ;; this before it's fed to `easy-menu-define'.
  d `(["Comment Out Region"     comment-region
       (c-fn-region-is-active-p)]
      ["Uncomment Region"       (comment-region (region-beginning)
						(region-end) '(4))
       (c-fn-region-is-active-p)]
      ["Indent Expression"      c-indent-exp
       (memq (char-after) '(?\( ?\[ ?\{))]
      ["Indent Line or Region"  c-indent-line-or-region t]
      ["Fill Comment Paragraph" c-fill-paragraph t]
      "----"
      ["Backward Statement"     c-beginning-of-statement t]
      ["Forward Statement"      c-end-of-statement t]
      "----"
      ("Toggle..."
       ["Syntactic indentation" c-toggle-syntactic-indentation
	:style toggle :selected c-syntactic-indentation]
       ["Electric mode"         c-toggle-electric-state
	:style toggle :selected c-electric-flag]
       ["Auto newline"          c-toggle-auto-newline
	:style toggle :selected c-auto-newline]
       ["Hungry delete"         c-toggle-hungry-state
	:style toggle :selected c-hungry-delete-key]
       ["Subword mode"          c-subword-mode
	:style toggle :selected (and (boundp 'c-subword-mode)
                                     c-subword-mode)])))

(easy-menu-define d-menu d-mode-map "D Mode Commands"
  (cons "D" (c-lang-const c-mode-menu d)))

;;----------------------------------------------------------------------------

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.d[i]?\\'" . d-mode))

;; Custom variables
;;;###autoload
(defcustom d-mode-hook nil
  "*Hook called by `d-mode'."
  :type 'hook
  :group 'c)

;;;###autoload
(define-derived-mode d-mode prog-mode "D"
  "Major mode for editing code written in the D Programming Language.

See http://dlang.org for more information about the D language.

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `d-mode-hook'.

Key bindings:
\\{d-mode-map}"
  (c-initialize-cc-mode t)
  (setq local-abbrev-table d-mode-abbrev-table
        abbrev-mode t)
  (use-local-map d-mode-map)
  (c-init-language-vars d-mode)
  (when (fboundp 'c-make-noise-macro-regexps)
    (c-make-noise-macro-regexps))

  ;; Generate a function that applies D-specific syntax properties.
  ;; Concretely, inside back-quoted string literals the backslash
  ;; character '\' is treated as a punctuation symbol.  See help for
  ;; syntax-propertize-rules function for more information.
  (setq-local
   syntax-propertize-function
   #'d--syntax-propertize-function)

  (c-common-init 'd-mode)
  (d--if-version>= "28"
      nil
    (easy-menu-add d-menu))
  (c-run-mode-hooks 'c-mode-common-hook 'd-mode-hook)
  (c-update-modeline)
  (d--if-version>= "26.0"
      (cc-imenu-init nil #'d-imenu-create-index-function)
    (cc-imenu-init d-imenu-generic-expression)))

;; ----------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Optional features ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ----------------------------------------------------------------------------

;; Support for "Adjusting Alignment Rules for UCFS-Chains in D",
;; cf. https://stackoverflow.com/questions/25797945/adjusting-alignment-rules-for-ucfs-chains-in-d
;;
;; The code here was originally created by Sergei Nosov
;; (https://stackoverflow.com/users/1969069/sergei-nosov) based on the c-lineup-cascaded-calls code, see
;; StackOverflow, and then amended by Nordlöw (https://stackoverflow.com/users/683710/nordl%C3%B6w) it
;; provides a function that people can make use of in their d-mode-hook thus:
;;
;; (add-hook 'd-mode-hook 'd-setup-cascaded-call-indentation)

(defun d-setup-cascaded-call-indentation ()
  "Set up `d-lineup-cascaded-calls'."
  (add-to-list 'c-offsets-alist '(arglist-cont-nonempty . d-lineup-cascaded-calls))
  (add-to-list 'c-offsets-alist '(statement-cont . d-lineup-cascaded-calls)))

(defun d-lineup-cascaded-calls (langelem)
  "D version of `c-lineup-cascaded-calls'.

This version accounts for optional parenthesis and compile-time
parameters in function calls." ;; checkdoc-params: langelem

  (if (and (eq (c-langelem-sym langelem) 'arglist-cont-nonempty)
           (not (eq (c-langelem-2nd-pos c-syntactic-element)
                    (c-most-enclosing-brace (c-parse-state)))))
      ;; The innermost open paren is not our one, so don't do
      ;; anything. This can occur for arglist-cont-nonempty with
      ;; nested arglist starts on the same line.
      nil

    (save-excursion
      (back-to-indentation)
      (let ((operator (and (looking-at "\\.")
                           (regexp-quote (match-string 0))))
            (stmt-start (c-langelem-pos langelem)) col)

        (when (and operator
                   (looking-at operator)
                   (or (and
                        (zerop (c-backward-token-2 1 t stmt-start))
                        (eq (char-after) ?\()
                        (zerop (c-backward-token-2 2 t stmt-start))
                        (looking-at operator))
                       (and
                        (zerop (c-backward-token-2 1 t stmt-start))
                        (looking-at operator))
                       (and
                        (zerop (c-backward-token-2 1 t stmt-start))
                        (looking-at operator))
                       )
                   )
          (setq col (current-column))

          (while (or (and
                      (zerop (c-backward-token-2 1 t stmt-start))
                      (eq (char-after) ?\()
                      (zerop (c-backward-token-2 2 t stmt-start))
                      (looking-at operator))
                     (and
                      (zerop (c-backward-token-2 1 t stmt-start))
                      (looking-at operator))
                     (and
                      (zerop (c-backward-token-2 1 t stmt-start))
                      (looking-at operator))
                     )
            (setq col (current-column)))

          (vector col))))))

;;----------------------------------------------------------------------------

(defun d-lineup-arglists (elem)
  "Line up runtime argument list with compile-time argument list.

Works with: func-decl-cont." ;; checkdoc-params: (elem)
  (save-excursion
    (beginning-of-line)
    (c-backward-syntactic-ws)
    (let ((c (char-before)))
      (cond
       ((eq c ?\))
	(c-go-list-backward)
	(vector (current-column)))
       (t
	"+")))))

;;----------------------------------------------------------------------------

(provide 'd-mode)

;;; d-mode.el ends here
