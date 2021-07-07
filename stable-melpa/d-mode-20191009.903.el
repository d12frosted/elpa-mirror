;;; d-mode.el --- D Programming Language major mode for (X)Emacs
;;;               Requires a cc-mode of version 5.30 or greater

;; Author:  William Baxter
;; Contributor:  Andrei Alexandrescu
;; Contributor:  Russel Winder
;; Maintainer:  Russel Winder <russel@winder.org.uk>
;;              Vladimir Panteleev <vladimir@thecybershadow.net>
;; Created:  March 2007
;; Version:  201908262243
;; Package-Version: 20191009.903
;; Package-Commit: cfd1d0869d51b7548b3fb738b2f2593c76533d44
;; Keywords:  D programming language emacs cc-mode
;; Package-Requires: ((emacs "24.3"))

;;;; NB Version number is date and time yyyymmddhhMM UTC.
;;;; A hook to update it automatically on save is available here:
;;;; https://gist.github.com/CyberShadow/28f60687c3bf83d32900cd6074c012cb

;; This file is not part of GNU Emacs.

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

;;----------------------------------------------------------------------------
;;; Code:

(require 'cc-mode)

;; Needed to prevent
;;   "Symbol's value as variable is void: compilation-error-regexp-alist-alist" errors
(require 'compile)

;; Work around Emacs (cc-mode) bug #18845
(eval-when-compile
  (when (and (= emacs-major-version 24) (>= emacs-minor-version 4))
    (require 'cl)))

;; The set-difference function is used from the Common Lisp extensions.
(require 'cl-lib)

;; Used to specify regular expressions in a sane way.
(require 'rx)

;; These are only required at compile time to get the sources for the
;; language constants.  (The cc-fonts require and the font-lock
;; related constants could additionally be put inside an
;; (eval-after-load "font-lock" ...) but then some trickery is
;; necessary to get them compiled.)
;; Comment out 'when-compile part for debugging
(eval-when-compile
  (require 'cc-langs)
  (require 'cc-fonts)
)

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
		   "[*(]"
		   "\\|"
		   (c-lang-const c-type-decl-prefix-key)
		   "\\)"
		   "\\([^=]\\|$\\)"))

;; D has fixed arrays
(c-lang-defconst c-opt-type-suffix-key
  d "\\(\\[[^]]*\\]\\|\\.\\.\\.\\)")

(c-lang-defconst c-identifier-ops
  ;; For recognizing "~this", ".foo", and "foo.bar.baz" as identifiers
  d '((prefix "~")(prefix ".")(left-assoc ".")))

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
  d (cl-set-difference (c-lang-const c-block-prefix-disallowed-chars)
		       '(?:)))

(defconst doxygen-font-lock-doc-comments
  (let ((symbol "[a-zA-Z0-9_]+")
	(header "^ \\* "))
    `((,(concat header "\\("     symbol "\\):[ \t]*$")
       1 ,c-doc-markup-face-name prepend nil)
      (,(concat                  symbol     "()")
       0 ,c-doc-markup-face-name prepend nil)
      (,(concat header "\\(" "@" symbol "\\):")
       1 ,c-doc-markup-face-name prepend nil)
      (,(concat "[#%@]" symbol)
       0 ,c-doc-markup-face-name prepend nil))
    ))

(defconst doxygen-font-lock-keywords
  `((,(lambda (limit)
	(c-font-lock-doc-comments "/\\+[+!]\\|/\\*[*!]\\|//[/!]" limit
	  doxygen-font-lock-doc-comments)))))


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
               "^[a-zA-z0-9.]*?@\\(.*?\\)(\\([0-9]+\\)):"
               1 2 nil 2))
(add-to-list 'compilation-error-regexp-alist 'd-exceptions)

;;----------------------------------------------------------------------------

;; Built-in basic types
(c-lang-defconst c-primitive-type-kwds
  d '("bool" "byte" "ubyte" "char" "delegate" "double" "float"
      "function" "int" "long" "short" "uint" "ulong" "ushort"
      "cent" "ucent" "real" "ireal" "idouble" "ifloat" "creal" "cfloat" "cdouble"
      "wchar" "dchar" "void" "string" "wstring" "dstring"))

;; Keywords that can prefix normal declarations of identifiers
(c-lang-defconst c-modifier-kwds
  d '("__gshared" "abstract" "deprecated" "extern"
      "final" "in" "out" "inout" "lazy" "mixin" "override" "private"
      "protected" "public" "ref" "scope" "shared" "static" "synchronized"
      "volatile" "__vector"))

(c-lang-defconst c-class-decl-kwds
  ;; Keywords introducing declarations where the following block (if any)
  ;; contains another declaration level that should be considered a class.
  d '("class" "struct" "union" "interface" "template"))

;; (c-lang-defconst c-brace-list-decl-kwds
;;   d '("enum"))

(c-lang-defconst c-type-modifier-kwds
  d '("__gshared" "inout" "lazy" "shared" "volatile"
      "invariant" "enum" "__vector"))

(c-lang-defconst c-type-prefix-kwds
  ;; Keywords where the following name - if any - is a type name, and
  ;; where the keyword together with the symbol works as a type in
  ;; declarations.  In this case, like "mixin foo!(x) bar;"
  d    '("mixin" "align"))

;;(c-lang-defconst c-other-block-decl-kwds
;;  ;; Keywords where the following block (if any) contains another
;;  ;; declaration level that should not be considered a class.
;;  ;; Each of these has associated offsets e.g.
;;  ;;   'with-open', 'with-close' and 'inwith'
;;  ;; that can be customized individually
;;  ;;   TODO: maybe also do this for 'static if' ?  in/out?
;;  ;;   TODO: figure out how to make this work properly
;;  d '("with" "version" "extern"))

(c-lang-defconst c-typedef-decl-kwds
 d (append (c-lang-const c-typedef-decl-kwds)
	    '("typedef" "alias")))

(c-lang-defconst c-decl-hangon-kwds
  d '("export"))

(c-lang-defconst c-protection-kwds
  ;; Access protection label keywords in classes.
  d '("deprecated" "static" "extern" "final" "synchronized" "override"
      "abstract" "scope" "inout" "shared" "__gshared"
      "private" "package" "protected" "public" "export"))

;;(c-lang-defconst c-postfix-decl-spec-kwds
;;  ;Keywords introducing extra declaration specifiers in the region
;;  ;between the header and the body (i.e. the "K&R-region") in
;;  ;declarations.
;;; This doesn't seem to have any effect.  They aren't exactly "K&R-regions".
;;  d '("in" "out" "body"))

(c-lang-defconst c-type-list-kwds
  d '("import"))

(c-lang-defconst c-ref-list-kwds
  d '("module"))

(c-lang-defconst c-colon-type-list-kwds
  ;; Keywords that may be followed (not necessarily directly) by a colon
  ;; and then a comma separated list of type identifiers.
  d  '("class" "enum" "interface"))

(c-lang-defconst c-paren-nontype-kwds
  ;;Keywords that may be followed by a parenthesis expression that doesn't
  ;; contain type identifiers.
  d '("version" "debug" "extern" "macro" "mixin"))

(c-lang-defconst c-paren-type-kwds
  ;; Keywords that may be followed by a parenthesis expression containing
  ;; type identifiers separated by arbitrary tokens.
  d  '("delete" "throw"))

(c-lang-defconst c-block-stmt-1-kwds
  ;; Statement keywords followed directly by a substatement.
  d '("do" "else" "finally" "try" "in" "out" "body"))

(c-lang-defconst c-block-stmt-2-kwds
  ;; Statement keywords followed by a paren sexp and then by a substatement.
  d '("for" "if" "switch" "while" "catch" "synchronized" "scope"
      "foreach" "foreach_reverse" "with" "unittest"))

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
  d '("module" "import"))

(c-lang-defconst c-other-kwds
  ;; Keywords not accounted for by any other `*-kwds' language constant.
  d '("__gshared" "__traits" "assert" "cast" "is" "nothrow" "pure" "ref"
      "sizeof" "typeid" "typeof"))


(defcustom d-font-lock-extra-types nil
  "*List of extra types (aside from the type keywords) to recognize in D mode.

Each list item should be a regexp matching a single identifier."
  :type '(repeat regexp)
  :group 'd-mode)

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
  t `(["Comment Out Region"     comment-region
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

(defconst d-imenu-method-name-pattern
  (rx
   ;; Whitespace
   bol
   (zero-or-more space)

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

   ;; Qualifiers
   (zero-or-more
    (one-or-more (any "a-z_@()C+"))
    (one-or-more space))

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
    (zero-or-more space))

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
     (while (let ((type (match-string 1)))
              (and pt type
                   (save-match-data
                     (string-match
		      (concat "\\<" (c-lang-const c-regular-keywords-regexp))
		      type))))
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
       line-start
       (zero-or-more (syntax whitespace))
       (zero-or-more
	(or "final" "abstract" "private" "package" "protected" "public" "export" "static")
	(one-or-more (syntax whitespace)))
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
       line-start
       (zero-or-more (syntax whitespace))
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
       line-start
       (zero-or-more (syntax whitespace))
       (zero-or-more
	(or "private" "package" "protected" "public" "export" "static")
	(one-or-more (syntax whitespace)))
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
       line-start
       (zero-or-more (syntax whitespace))
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
       line-start
       (zero-or-more (syntax whitespace))
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
       line-start
       "alias"
       (one-or-more (syntax whitespace))
       (submatch
	(one-or-more
	 (any ?_
	      (?0 . ?9)
	      (?A . ?Z)
	      (?a . ?z))))
       (zero-or-more (syntax whitespace))
       "=")
     1)
    ("*Aliases*"
     ,(rx
       line-start
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
  (if (not (string= major-mode "d-mode"))
      (apply orig-fun args)
    (progn
      (add-function :around (symbol-function 'looking-at)
                    #'d-special-case-looking-at)
      (unwind-protect
          (apply orig-fun args)
        (remove-function (symbol-function 'looking-at)
                         #'d-special-case-looking-at)))))

(when (version<= "24.4" emacs-version)
  (advice-add 'c-add-stmt-syntax :around #'d-around--c-add-stmt-syntax))

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
  (when (version<= "24.3" emacs-version)
    (setq-local
     syntax-propertize-function
     (syntax-propertize-rules
      ((rx
	"`"
	(minimal-match
	 (zero-or-more
	  (not (any "`\\"))))
	(minimal-match
	 (zero-or-more
	  (submatch "\\")
	  (minimal-match
	   (zero-or-more
	    (not (any "`\\"))))))
	"`")
       (1 ".")))))

  (c-common-init 'd-mode)
  (easy-menu-add d-menu)
  (c-run-mode-hooks 'c-mode-common-hook 'd-mode-hook)
  (c-update-modeline)
  (cc-imenu-init d-imenu-generic-expression))

;;----------------------------------------------------------------------------
;; "Hideous hacks" to support appropriate font-lock behaviour.
;;
;; * auto/const/immutable: If we leave them in c-modifier-kwds (like
;;   c++-mode) then in the form "auto var;" var will be highlighted in
;;   type name face. Moving auto/immutable to font-lock-add-keywords
;;   lets cc-mode seeing them as a type name, so the next symbol can
;;   be fontified as a variable.
;;
;; * public/protected/private appear both in c-modifier-kwds and in
;;   c-protection-kwds. This causes cc-mode to fail parsing the first
;;   declaration after an access level label (because cc-mode trys to
;;   parse them as modifier but will fail due to the colon). But
;;   unfortunately we cannot remove them from either c-modifier-kwds
;;   or c-protection-kwds. Removing them from the former causes valid
;;   syntax like "private int foo() {}" to fail. Removing them from
;;   the latter cause indentation of the access level labels to
;;   fail. The solution used here is to use font-lock-add-keywords to
;;   add back the syntax highlight.

(defconst d-var-decl-pattern "^[ \t]*\\(?:[_a-zA-Z0-9]+[ \t\n]+\\)*\\([_a-zA-Z0-9.!]+\\)\\(?:\\[[^]]*\\]\\|\\*\\)?[ \t\n]+\\([_a-zA-Z0-9]+\\)[ \t\n]*[;=]")
(defconst d-fun-decl-pattern "^[ \t]*\\(?:[_a-zA-Z0-9]+[ \t\n]+\\)*\\([_a-zA-Z0-9.!]+\\)\\(?:\\[[^]]*\\]\\|\\*\\)?[ \t\n]+\\([_a-zA-Z0-9]+\\)[ \t\n]*(")
(defmacro d-try-match-decl (regex)
  "Helper macro." ;; checkdoc-params: regex
  `(let ((pt))
     (setq pt (re-search-forward ,regex limit t))
     (while (let ((type (match-string 1)))
              (and pt type
                   (save-match-data
                     (string-match (c-lang-const c-regular-keywords-regexp) type))))
       (setq pt (re-search-forward ,regex limit t)))
     pt))
(defun d-match-var-decl (limit)
  "Helper function." ;; checkdoc-params: limit
  (d-try-match-decl d-var-decl-pattern))
(defun d-match-fun-decl (limit)
  "Helper function." ;; checkdoc-params: limit
  (d-try-match-decl d-fun-decl-pattern))
(defun d-match-auto (limit)
  "Helper function." ;; checkdoc-params: limit
  (c-syntactic-re-search-forward "\\<\\(auto\\|const\\|immutable\\)\\>" limit t))

(font-lock-add-keywords
 'd-mode
 '((d-match-auto 1 font-lock-keyword-face t)
   (d-match-var-decl (1 font-lock-type-face) (2 font-lock-variable-name-face))
   (d-match-fun-decl (1 font-lock-type-face) (2 font-lock-function-name-face)))
 t)

;;----------------------------------------------------------------------------
;;
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

(provide 'd-mode)

;;; d-mode.el ends here
