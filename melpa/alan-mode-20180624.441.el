;;; alan-mode.el --- Major mode for editing M-industries Alan files

;; Copyright (C) 2018 M-industries

;; Author: Paul van Dam <pvandam@m-industries.com>
;; Maintainer: Paul van Dam <pvandam@m-industries.com>
;; Version: 1.0.0
;; Package-Version: 20180624.441
;; Package-Commit: 0089e7c874c6d35e55be6ecd479ada2b97688a1f
;; Created: 13 October 2017
;; URL: https://github.com/M-industries/AlanForEmacs
;; Homepage: https://alan-platform.com/
;; Keywords: alan, languages
;; Package-Requires: ((flycheck "32") (emacs "25.1"))

;; MIT License

;; Copyright (c) 2017 M-industries

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.


;; This file is not part of GNU Emacs.

;;; Commentary:
;; A major mode for editing M-industries Alan files.

(require 'flycheck)
(require 'timer)
(require 'xref)

;;; Code:

(add-to-list `auto-mode-alist '("\\.alan$" . alan-mode))

(defcustom alan-xref-limit-to-project-scope t
  "Limits symbol lookup to the open buffers in project scope.
Only available when projectile is loaded, because it is based on
the function `projectile-project-root'"
  :group 'alan
  :type '(boolean))

(defcustom alan-compiler "compiler-project"
  "The alan compiler.
This one is used when the variable `alan-project-root' cannot be
resolved to an existing directory."
  :group 'alan
  :type '(string))
(make-variable-buffer-local 'alan-compiler)

(defvar-local alan-mode-font-lock-keywords
  '((("'[^']*?'" . font-lock-variable-name-face))
	nil nil nil nil
	(font-lock-syntactic-face-function . alan-font-lock-syntactic-face-function))
  "Highlighting for alan mode")

(defvar alan-mode-syntax-table
  (let ((alan-mode-syntax-table (make-syntax-table)))
    (modify-syntax-entry ?* ". 23b" alan-mode-syntax-table)
	(modify-syntax-entry ?/ ". 124" alan-mode-syntax-table)
	(modify-syntax-entry ?\n ">" alan-mode-syntax-table)
	(modify-syntax-entry ?' "\"" alan-mode-syntax-table)
	(modify-syntax-entry ?{ "(}" alan-mode-syntax-table)
	(modify-syntax-entry ?} "){" alan-mode-syntax-table)
	alan-mode-syntax-table)
  "Syntax table for ‘alan-mode’.")

(defvar alan-parent-regexp "\\s-*\\('[^']*?'\\)")

(defun alan-boundry-of-identifier-at-point ()
  (let ((text-properties (nth 1 (text-properties-at (point)))))
	(when (or (and (listp text-properties)
				  (member font-lock-variable-name-face text-properties))
			 (eq font-lock-variable-name-face text-properties))
	  (save-excursion
		(let ((beginning (search-backward "'"))
			(end (search-forward "'" nil nil 2)))
		  (if (and beginning end)
			  (cons beginning end)))))))
(put 'identifier 'bounds-of-thing-at-point 'alan-boundry-of-identifier-at-point)
(defun alan-thing-at-point ()
  "Find alan variable at point."
  (let ((boundary-pair (bounds-of-thing-at-point 'identifier)))
         (if boundary-pair
             (buffer-substring-no-properties
              (car boundary-pair) (cdr boundary-pair)))))
(put 'identifier 'thing-at-point 'alan-thing-at-point)

;;; Xref backend

;; todo add view definitions
;; todo add widget definitions
;; todo add control definitions

(defun alan--xref-backend () 'alan)

(defvar alan--xref-format
  (let ((str "%s %s :%d"))
    (put-text-property 0 2 'face 'font-lock-variable-name-face str)
    (put-text-property 3 5 'face 'font-lock-function-name-face str)
    str))

(defun alan--xref-make-xref (symbol type buffer symbol-position)
  (xref-make (format alan--xref-format symbol type (line-number-at-pos symbol-position))
			 (xref-make-buffer-location buffer symbol-position)))

(defun alan--xref-find-definitions (symbol)
  "Find all definitions matching SYMBOL."
  (let ((xrefs)
		(project-scope-limit (and
							  (featurep 'projectile)
							  alan-xref-limit-to-project-scope
							  (projectile-project-root))))
	(dolist (buffer (buffer-list))
	  (with-current-buffer buffer
		(when (and (derived-mode-p 'alan-mode)
				   (or (null project-scope-limit)
					   (and (featurep 'projectile)
							(string= project-scope-limit (projectile-project-root)))))
		  (save-excursion
			(save-restriction
			  (widen)
			  (goto-char (point-min))
			  (while (re-search-forward "^\\s-*\\('[^']*?'\\)" nil t)
				(when (string= (match-string 1) symbol)
				  (add-to-list 'xrefs (alan--xref-make-xref symbol "" buffer (match-beginning 1)) t))))))))
	xrefs))

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql alan)))
  (alan-thing-at-point))

(cl-defmethod xref-backend-definitions ((_backend (eql alan)) symbol)
  (alan--xref-find-definitions symbol))

(cl-defmethod xref-backend-identifier-completion-table ((_backend (eql alan)))
  (let (words)
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-min))
        (while (re-search-forward "^\\s-*\\('[^']*?'\\)" nil t)
          (add-to-list 'words (match-string-no-properties 1)))
        (seq-uniq words)))))

;;; Alan functions

(defun alan--has-parent ()
  "Return point of parent or nil otherwise."
  (let ((line-to-ignore-regex "^\\s-*\\(//.*\\)?$"))
	(save-excursion
	  (move-beginning-of-line 1)
	  (while (and (not (bobp))
				  (looking-at line-to-ignore-regex))
		(forward-line -1))

	  (let ((start-indent (current-indentation))
			(curr-indent (current-indentation))
			(curr-point (point))
			(start-line-number (line-number-at-pos)))
		(defvar new-point)
		(while (and (not (bobp))
					(> start-indent 0)
					(or (not (looking-at "\\s-*'[^']*?'"))
						(looking-at line-to-ignore-regex)
						(> (current-indentation) curr-indent)
						(<= start-indent (current-indentation))))
		  (forward-line -1)
		  (unless  (looking-at line-to-ignore-regex)
			(setq curr-indent (min curr-indent (current-indentation))))
		  (setq new-point (point)))
		(if
			(and
			 (looking-at alan-parent-regexp)
			 (not (equal start-line-number (line-number-at-pos))))
			(match-beginning 1))))))

(defun alan-goto-parent ()
  "Goto the parent of this property."
  (interactive)
  (let ((parent-position (alan--has-parent)))
	(when (alan--has-parent)
		(push-mark (point) t)
		(goto-char parent-position))))

(defun alan-copy-path-to-clipboard ()
  "Copy the path as shown in the header of the buffer.
This uses the `alan-path' function to get its value."
  (interactive)
  (let ((path (alan-path)))
	(when path
	  (kill-new path))))

(defun alan-path ()
  "Gives the location as a path of where you are in a file.
E.g. 'views' . 'queries' . 'context' . 'candidates' . 'of'"
  (let ((path-list '())
		has-parent)
	(save-excursion
	  (while (setq has-parent (alan--has-parent))
		(goto-char has-parent)
		(add-to-list 'path-list (match-string 1))))
	(if (> (length path-list) 0)
		(mapconcat 'identity path-list " . ")
	  "")))

(defun alan-mode-indent-line ()
  "Indentation based on parens.
Not suitable for white space significant languages."
  (interactive)
  (let (new-indent)
	(save-excursion
	  (beginning-of-line)
	  (if (bobp)
		  ;;at the beginning indent to 0
		  (indent-line-to 0))
	  ;; take the current indentation of the enclosing expression
	  (let ((parent-position (nth 1 (syntax-ppss)))
			(previous-line-indentation
			 (and (not (bobp))
				  (save-excursion (forward-line -1) (current-indentation)))))
		(cond
		 (parent-position
		  (let ((parent-indent
				 (save-excursion
				   (goto-char parent-position)
				   (current-indentation))))
			(if (looking-at "\\s-*\\s)") ;; looking at closing paren.
				(setq new-indent parent-indent)
			  (setq new-indent ( + parent-indent tab-width)))))
		 (previous-line-indentation
		  (setq new-indent previous-line-indentation)))
		;; check for single block and add a level of indentation.
		(save-excursion
		  (back-to-indentation)
		  (if (and (looking-at "\\s(")
				   (eq (line-number-at-pos)
					   (progn (forward-sexp) (line-number-at-pos))))
			  (setq new-indent (min (if previous-line-indentation (+ previous-line-indentation tab-width) tab-width )
									(+ new-indent tab-width)))))))
	(when new-indent
	  (indent-line-to new-indent))))

(defun alan-font-lock-syntactic-face-function (state)
  "Don't fontify single quoted strings."
  (if (nth 3 state)
      (let ((startpos (nth 8 state)))
        (if (eq (char-after startpos) ?')
            ;; This is not a string, but an identifier.
            nil
		  font-lock-string-face))
    font-lock-comment-face))

(defvar-local alan--update-headline-timer nil)
(defun alan-update-header ()
  "Update the header line after 0.5 seconds of idle time."
  (when (timerp alan--update-headline-timer)
	(cancel-timer alan--update-headline-timer))
  (setq alan--update-headline-timer
		(run-with-idle-timer
		 0.5 nil
		 (lambda (buffer-to-update)
		   (with-current-buffer buffer-to-update
			 (setq header-line-format (format " %s  " (alan-path)))
			 (force-mode-line-update)))
		 (current-buffer))))

(define-derived-mode alan-mode prog-mode "Alan"
  "Major mode for editing m-industries alan files."
  :syntax-table alan-mode-syntax-table
  :group 'alan
  (setq comment-start "//")
  (setq comment-end "")
  (setq block-comment-start "/*")
  (setq block-comment-end "*/")
  (setq font-lock-defaults alan-mode-font-lock-keywords)
  (add-hook 'xref-backend-functions #'alan--xref-backend nil t)
  (set (make-local-variable 'indent-line-function) 'alan-mode-indent-line)
  (add-hook 'post-command-hook #'alan-update-header nil t)
  (setq header-line-format ""))

;;; Flycheck

(defun alan-flycheck-error-filter (error-list)
  (seq-remove (lambda (error)
				(or (string= (flycheck-error-filename error) "/dev/null")
					(not (string= (flycheck-error-filename error) (buffer-file-name)))))
			  error-list))

(defvar-local alan--flycheck-language-definition nil
  "The real path to the language definition if `alan-language-definition' can be resolved.")

(flycheck-define-checker alan
  "An Alan syntax checker."
  :command ("alan"
			(eval (if (null alan--flycheck-language-definition)
					'("validate" "emacs")
					`(,alan--flycheck-language-definition "--format" "emacs" "--log" "warning" "/dev/null"))))
  :error-patterns
  ((error line-start (file-name) ":" line ":" column ": error:"
		  ;; Messages start with a white space after the error.
		  (message (zero-or-more not-newline)
				   (zero-or-more "\n " (zero-or-more not-newline)))
		  line-end)
   (warning line-start (file-name) ":" line ":" column ": warning: " (one-or-more digit) ":" (one-or-more digit)
			(message (zero-or-more not-newline)
					 (zero-or-more "\n " (zero-or-more not-newline)))
			line-end))
  :error-filter alan-flycheck-error-filter
  :modes (alan-mode
		  alan-schema-mode
		  alan-grammar-mode
		  alan-template-mode
		  alan-application-mode
		  alan-widget-implementation-mode
		  alan-annotations-mode))
(add-to-list 'flycheck-checkers 'alan)

;;; Project root

(defvar-local alan-project-root nil)
(defvar-local alan-project-file "versions.json"
  "The project file to base the project root on. The language mode will set this to project.json.")
(defun alan-project-root ()
  "Project root folder determined based on the presence of a project.json or versions.json file."
  (or
   alan-project-root
   (setq alan-project-root
		 (expand-file-name
		  (or (locate-dominating-file default-directory alan-project-file)
			  (progn
				(message  "Couldn't locate project root folder with a %s file. Using' %s' as project root." alan-project-file default-directory)
				default-directory))))))

;;; Alan language mode

(defvar-local alan-language-definition nil)

(defun alan-setup-build-system ()
  (let ((alan-project-script (concat (alan-project-root) "/alan"))
		(alan-project-compiler (concat (alan-project-root) "dependencies/dev/internals/alan/tools/compiler-project"))
		(alan-project-language (concat (alan-project-root) alan-language-definition)))
	(set (make-local-variable 'compilation-error-screen-columns) nil)
	(cond
	 ((file-executable-p alan-project-script)
	  (setq flycheck-alan-executable alan-project-script)
	  (set (make-local-variable 'compile-command) (concat alan-project-script " build emacs ")))
	 ((file-executable-p alan-project-compiler)
	  (setq flycheck-alan-executable alan-project-compiler)
	  (setq alan--flycheck-language-definition alan-project-language)
	  (set (make-local-variable 'compile-command)
		   (concat alan-project-compiler " " alan-project-language " --format emacs --log warning /dev/null ")))
	 ((executable-find alan-script)
	  (setq flycheck-alan-executable alan-script)
	  (set (make-local-variable 'compile-command) (concat alan-script " build emacs ")))
	 (t (message "No alan compiler or script found.")))))

(define-derived-mode alan-language-mode alan-mode "language"
  "Major mode for editing m-industries language files."
  :after-hook (alan-setup-build-system)
  (setq alan-project-file "project.json")
  (setq alan-language-definition "dependencies/dev/internals/alan/language"))

;;; schema mode

(add-to-list `auto-mode-alist '("schema.alan" . alan-schema-mode))

(defvar alan-imenu-generic-expression
  ;; Patterns to identify alan definitions
  '(("dictionary" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* dictionary" 1)
	("state group" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* stategroup" 1)
	("component" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* component" 1)
	("text" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* text" 1)
	("number" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* number" 1)
	("matrix" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* \\(?:dense\\|sparse\\)matrix" 1)))

(defconst alan-schema-font-lock-keyword
  `(
	("->\\s-+\\(stategroup\\|component\\|group\\|dictionary\\|command\\|densematrix\\|sparsematrix\\|reference\\|number\\|text\\)\\(\\s-+\\|$\\)" 1 font-lock-type-face)
	(,(regexp-opt '( "component" "types" "external" "(" ")" "->" "plural"
					 "numerical" "integer" "natural" "root" "]" ":" "*" "?"  "~"
					 "+" "constrain" "acyclic" "ordered" "dictionary"
					 "densematrix" "sparsematrix" "$" "==" "!=" "group" "number"
					 "reference" "stategroup" "text" "."  "!"  "!&" "&" ".^"
					 "+^" "}" ">" "*&" "?^" ">>" "forward" "self" "{" "graph"
					 "usage" "implicit" "ignore" "experimental" "libraries"
					 "using")) . font-lock-builtin-face))
  "Highlight keywords for alan schema mode.")

(define-derived-mode alan-schema-mode alan-language-mode "schema"
  "Major mode for editing m-industries schema files."
  (modify-syntax-entry ?} "_" alan-schema-mode-syntax-table)
  (modify-syntax-entry ?{ "_" alan-schema-mode-syntax-table)
  (modify-syntax-entry ?\[ "_" alan-schema-mode-syntax-table)
  (modify-syntax-entry ?\] "_" alan-schema-mode-syntax-table)
  (font-lock-add-keywords nil alan-schema-font-lock-keyword "at end"))

;;; grammar mode

(add-to-list `auto-mode-alist '("grammar.alan" . alan-grammar-mode))

(defconst alan-grammar-font-lock-keyword
  `(
	(,(regexp-opt
	   '("rules" "root" "component" "indent" "keywords" "collection" "order"
		 "predecessors" "successors" "group" "(" ")" "number" "reference"
		 "stategroup" "has" "first" "last" "predecessor" "successor" "text" "["
		 "]" ","
		 )) . font-lock-builtin-face))
  "Highlight keywords for alan schema mode.")

(defun alan-grammar-update-keyword ()
	"Update the keywords section based on all used keywords in this grammar file."
	(interactive)
	(save-excursion
	  (save-restriction
		(widen)
		(goto-char (point-min))

		(let ((keyword-point (re-search-forward "^keywords$"))
			  (root-point (re-search-forward "^root$"))
			  (root-point-start (match-beginning 0)) ;; because the last search was for root
			  (alan-keywords (list)))
		  (while (re-search-forward "\\[\\(\\s-?'[^'
]+'\\s-?,?\\)+\\]" nil t) ;; there is a line end in the regex. Hence the weird break.
			(let ((keyword-group (match-string 0))
				  (search-start 0))
			  (while (string-match "'[^']+'" keyword-group search-start)
				(add-to-list 'alan-keywords (match-string 0 keyword-group))
				(setq search-start (match-end 0)))))
		  (delete-region (+ 1 keyword-point) root-point-start)
		  (goto-char (+ 1 keyword-point))
		  (insert (string-join (mapcar (lambda (k) (concat "\t" k)) (sort (delete-dups alan-keywords ) 'string<)) "
"))
		  (insert "
")
		  (insert "
")))))

(defun alan-grammar-mode-indent-line ()
  "Indentation based on parens and toggle indentation to min and max indentation possible."
  (interactive)
  (let
	  (new-indent)
 	(save-mark-and-excursion
	  (beginning-of-line)
	  (when (bobp) (indent-line-to 0)) ;;at the beginning indent at 0
	  (let* ((parent-position (nth 1 (syntax-ppss))) ;; take the current indentation of the enclosing expression
			 (parent-indent (if parent-position
								(save-excursion (goto-char parent-position) (current-indentation))
							  0))
			(current-indent (current-indentation))
			(previous-line-indentation (and
										(not (bobp))
										(save-excursion
										  (forward-line -1)
										  (current-indentation))))
			(min-indentation (if parent-position (+ parent-indent tab-width) 0))
			(max-indentation (+ previous-line-indentation tab-width)))
		(cond
		 ((and parent-position (looking-at "\\s-*\\s)"))
		  (setq new-indent parent-indent))
		 ((= current-indent min-indentation)
		  (setq new-indent max-indentation))
		 ((< current-indent min-indentation) ;; usually after a newline.
		  (setq new-indent (max previous-line-indentation min-indentation)))
		 ((> current-indent max-indentation)
		  (setq new-indent max-indentation))
		 ((<= current-indent max-indentation)
		  (setq new-indent (- current-indent tab-width))))))
 	(when new-indent
 	  (indent-line-to new-indent))))

(define-derived-mode alan-grammar-mode alan-language-mode "grammar"
  "Major mode for editing m-industries schema files."
  (modify-syntax-entry ?} "_" alan-grammar-mode-syntax-table)
  (modify-syntax-entry ?\[ "(]" alan-grammar-mode-syntax-table)
  (modify-syntax-entry ?\] ")[" alan-grammar-mode-syntax-table)
  (font-lock-add-keywords nil alan-grammar-font-lock-keyword "end")

  (electric-indent-local-mode -1)
  (local-set-key (kbd "RET") 'newline-and-indent)
  (set (make-local-variable 'indent-line-function) 'alan-grammar-mode-indent-line))

;;; template mode

(add-to-list `auto-mode-alist '("\\.template$" . alan-template-mode))

(defun alan-template-yank ()
  "Yank but wrap as template."
  (interactive)
  (let ((string-to-yank (current-kill 0 t)))
	(insert (mapconcat 'identity
					   (mapcar (lambda (s)
								 (format "\"%s\"" (replace-regexp-in-string "\"" "\\\\\"" s)))
					   (split-string string-to-yank "\n"))
			   "\n"))))

(define-derived-mode alan-template-mode alan-language-mode "template"
  "Major mode for editing m-industries template files."
  (modify-syntax-entry ?` "w")
  (modify-syntax-entry ?\[ "(]")
  (modify-syntax-entry ?\] ")[")
  (setq alan-language-definition (concat (alan-project-root) "dependencies/dev/internals/alan-to-text-transformation/language")))

;;; Application modes

(defcustom alan-script "alan"
  "The alan build script file."
  :group 'alan
  :type '(string))
(make-variable-buffer-local 'alan-script)

(define-derived-mode alan-project-mode alan-mode "alan project"
  "Abstract major mode for editing m-industries project files."
  :after-hook (alan-setup-build-system))

;;; application mode

(add-to-list `auto-mode-alist '("application.alan" . alan-application-mode))

(defun alan-list-nummerical-types ()
  "Return a list of all nummerical types."
  (save-mark-and-excursion
   (save-restriction
	 (widen)
	 (goto-char (point-max))
	 (let ((numerical-types-point (re-search-backward "^numerical-types"))
		   (numerical-types (list)))
	   (when numerical-types-point
		 (while (re-search-forward "^\\s-*'\\([^']*\\)'" nil t)
		   (add-to-list 'numerical-types (match-string 1))))
	   numerical-types))))

(defconst alan-application-font-lock-keyword
  `(
	("\\(:\\|:=\\)\\s-+\\(stategroup\\|component\\|group\\|file\\|dictionary\\|command\\|matrix\\|reference\\|natural\\|integer\\|text\\)\\(\\s-+\\|$\\)" 2 font-lock-type-face)
	(,(regexp-opt '("add" "branch" "ceil" "convert" "count" "division" "floor"
	"increment" "max" "min" "remainder" "subtract" "sum" "sumlist" "base" "diff" "product"))
	 . font-lock-function-name-face)
	(,(regexp-opt '("today" "now" "zero" "true" "false")) . font-lock-constant-face)
	(,(regexp-opt '("@%^" "@" "@?^" "@date" "@date-time" "@default:"
					"@description:" "@desired" "@dormant" "@duration:"
					"@factor:" "@guid" "@hidden" "@identifying"
					"@key-description:" "@label:" "@linked" "@max:" "@metadata"
					"@min:" "@multi-line" "@name" "@namespace" "@small"
					"@sticky" "@validate:" "@verified" "@visible" )) . font-lock-keyword-face)
	(,(regexp-opt '("#" "#reader" "#writer" "$" "$^" "%" "%^" "%}" "&#" "&" "("
					")" "*" "+" "+^" "," "-" "-<" "->" "." ".^" ".key" ".self"
					".}" "/" "10^" ":" ":=" "<" "<-" "<=" "=" "==" "=>" ">" ">="
					">key" "?" "?^" "@%^" "@" "@?^" "@date" "@date-time"
					"@default:" "@description:" "@desired" "@dormant"
					"@duration:" "@factor:" "@guid" "@hidden" "@identifying"
					"@key-description:" "@label:" "@linked" "@max:" "@metadata"
					"@min:" "@multi-line" "@name" "@namespace" "@small"
					"@sticky" "@validate:" "@verified" "@visible" "[" "]" "^"
					"acyclic-graph" "add" "and" "anonymous" "any" "as" "base"
					"ceil" "collection" "command" "component" "count" "create"
					"created" "creation-time" "delete" "dense" "deprecated"
					"dictionary" "diff" "division" "do" "dynamic" "entry"
					"external" "false" "file" "floor" "forward" "from" "group"
					"hours" "if" "ignore" "in" "increment" "integer" "interface"
					"invalidate" "inverse" "join" "life-time" "log" "mapping"
					"match" "match-branch" "matrix" "max" "min" "minutes"
					"mutation-time" "natural" "new" "node" "now" "number"
					"numerical-types" "on" "one" "ontimeout" "ordered-graph"
					"password" "product" "reference" "reference-set"
					"referencer" "remainder" "remove" "rename" "roles" "root"
					"seconds" "space" "sparse" "stategroup" "std" "subtract"
					"sum" "sumlist" "switch" "text" "timer" "today" "true"
					"union" "unsafe" "update" "users" "with" "workfor" "zero"
					"{" "|" "}" "~>" )) . font-lock-builtin-face))
  "Highlight keywords for alan application mode.")

(define-derived-mode alan-application-mode alan-project-mode "alan application"
  "Major mode for editing m-industries application model files."
  (font-lock-add-keywords nil alan-application-font-lock-keyword "at end")
  (modify-syntax-entry ?\] "_" alan-mode-syntax-table)
  (modify-syntax-entry ?\[ "_" alan-mode-syntax-table)
  (modify-syntax-entry ?{ "(}" alan-mode-syntax-table)
  (modify-syntax-entry ?} "){" alan-mode-syntax-table))

;;; widget implementation mode

(add-to-list `auto-mode-alist '("widgets/.*\\.ui\\.alan$" . alan-widget-implementation-mode))

(defconst alan-widget-implementation-font-lock-keyword
  `((,(regexp-opt '( "#" "$" "(" ")" "*" "," "->" "."  ".}"  ":" "::" "=>" ">"
					 ">>" "?"  "@" "[" "]" "^" "binding" "configuration"
					 "control" "current" "dictionary" "empty" "engine" "file"
					 "format" "inline" "instruction" "interval" "let" "list"
					 "markup" "number" "on" "set" "state" "stategroup" "static"
					 "switch" "text" "time" "to" "transform" "unconstrained"
					 "view" "widget" "window" "|" )) . font-lock-builtin-face))
  "Highlight keywords for alan widget-implementation mode.")

(define-derived-mode alan-widget-implementation-mode alan-project-mode "widget implementation"
  "Major mode for editing m-industries widget-implementation model files."
  (message "loading widget implementation mode")
  (font-lock-add-keywords nil alan-widget-implementation-font-lock-keyword "at end")
  (modify-syntax-entry ?} "_" alan-mode-syntax-table)
  (modify-syntax-entry ?{ "_" alan-mode-syntax-table)
  (modify-syntax-entry ?\[ "(]" alan-mode-syntax-table)
  (modify-syntax-entry ?\] ")[" alan-mode-syntax-table))

(provide 'alan-mode)

;;; alan-mode.el ends here
