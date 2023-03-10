;;; alan-mode.el --- Major mode for editing Alan files -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Kjerner

;; Author: Paul van Dam <pvandam@kjerner.com>
;; Maintainer: Paul van Dam <pvandam@kjerner.com>
;; Version: 1.0.0
;; Created: 13 October 2017
;; URL: https://github.com/Kjerner/AlanForEmacs
;; Homepage: https://alan-platform.com/
;; Keywords: alan, languages
;; Package-Requires: ((flycheck "32") (emacs "25.1") (s "1.12"))

;; MIT License

;; Copyright (c) 2019 Kjerner

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
;; A major mode for editing Alan files.

(require 'flycheck)
(require 'timer)
(require 'xref)
(require 's)
(require 'seq)

;;; Code:

(add-to-list 'auto-mode-alist '("\\.alan\\'" . alan-mode))

(defgroup alan nil
  "Alan mode."
  :prefix "alan-"
  :group 'tools)

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

(defcustom alan-log-level "warning"
  "The log level used by the `alan-compiler' or the `alan-script'.
Its value should be one of 'error' 'info' 'quiet' 'warning'."
  :group 'alan
  :type '(string)
  :risky t)

(defcustom alan-compiler-project-root "."
  "The relative path from current buffer file to Alan project root.
This sets the -C option."
  :type '(string)
  :safe 'stringp
  :local t)

(defcustom alan-script "alan"
  "The alan build script file."
  :group 'alan
  :type '(string))

(defcustom alan-language-definition nil
  "The Alan language to use.

Setting this will try to use the `alan-compiler' instead of the
`alan-script'. If the path is relative it will try to resolve it
against the `alan-project-root'."
  :group 'alan
  :type '(string)
  :safe 'stringp
  :local t)

(defcustom alan-on-phrase-added-hook nil
  "A hook that is run after successfully adding a phrase to phrases.alan.

Used by `alan-views-add-to-phrases'."
  :type 'hook
  :group 'alan)

(defcustom alan-on-phrase-removed-hook nil
  "A hook that is run after successfully removing a phrase from phrases.alan.

Used by `alan-views-remove-from-phrases'."
  :type 'hook
  :group 'alan)

(defconst alan-add-line-in-braces-rule
  '(?\n . (lambda () (when (and (derived-mode-p 'alan-mode)
					 (looking-back "\\s(\\s-*\n\\s-*") (looking-at-p "\\s)"))
			'after-stay)))
  "A rule that can be added to `electric-layout-rules'.

It can be added locally by adding it to the alan-hook:
\(set (make-variable-buffer-local 'electric-layout-rules) (list alan-add-line-in-braces-rule))")

;;; Alan mode

(defvar-local alan-mode-font-lock-keywords
  '((("'\\([^'\n\\]\\|\\(\\\\'\\)\\|\\\\\\\)*'" . font-lock-variable-name-face)
	 ("^\\s-*///.*$" 0 'font-lock-doc-face t))
	nil nil nil nil
	(font-lock-syntactic-face-function . alan-font-lock-syntactic-face-function))
  "Highlighting for alan mode")

(defvar alan-mode-syntax-table
  (let ((alan-mode-syntax-table (make-syntax-table)))
    (modify-syntax-entry ?* ". 23b" alan-mode-syntax-table)
	(modify-syntax-entry ?/ ". 124" alan-mode-syntax-table)
	(modify-syntax-entry ?\n ">" alan-mode-syntax-table)
	(modify-syntax-entry ?' "\"" alan-mode-syntax-table)
	(modify-syntax-entry ?{ "_" alan-mode-syntax-table)
	(modify-syntax-entry ?} "_" alan-mode-syntax-table)
	(modify-syntax-entry ?\] "_" alan-mode-syntax-table)
	(modify-syntax-entry ?\[ "_" alan-mode-syntax-table)
	alan-mode-syntax-table)
  "Syntax table for ‘alan-mode’.")

(defvar alan-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c'" 'alan-edit-documentation)
    map))

;;;###autoload
(define-derived-mode alan-mode prog-mode "Alan"
  "Major mode for editing Alan files."
  :syntax-table alan-mode-syntax-table
  :group 'alan
  (setq comment-start "//")
  (setq comment-end "")
  (setq block-comment-start "/*")
  (setq block-comment-end "*/")
  (setq font-lock-defaults alan-mode-font-lock-keywords)
  (add-hook 'xref-backend-functions #'alan--xref-backend nil t)
  (set (make-local-variable 'indent-line-function) 'alan-mode-indent-line)
  (add-hook 'post-command-hook (alan-throttle 0.5 #'alan-update-header)  nil t)
  (add-hook 'xref-after-jump-hook #'alan-update-header nil t)
  (setq header-line-format ""))

(defvar alan-parent-regexp "\\s-*\\('\\([^'\n\\]\\|\\(\\\\'\\)\\|\\\\\\\)*'\\)")

(defmacro alan-define-mode (name &optional docstring &rest body)
  "Define NAME as an Alan major mode.

The mode derives from the generic `alan-mode'.

BODY can define keyword aguments.
:file-pattern
	The file pattern to associate with the major mode. If none is provided it
	will associate it with NAME.alan.
:keywords
	A list of cons cells where the first is a regexp or a list of keywords
	and the second element is the font-face.
:language
	The path to the Alan language definition. Its value is set in
	`alan-language-definition'.
:build-dir
	The relative build directory of the `alan-compiler'. This sets the buffer
	local variable `alan-compiler-project-root.'
:pairs
	A list of cons cells that match open and close parameters.
:propertize-rules
	A list of rules used by `syntax-propertize-rules' When set will set the
	propertize function for this mode.
:pretty-print
	When non nil enables pretty printing when 'alan-language and 'pretty-printer
	are set.

The rest of the BODY is evaluated in the body of the derived-mode.
Optional argument DOCSTRING for the major mode."

  (declare
   (doc-string 2)
   (indent 2))

  (when (and docstring (not (stringp docstring))) ;; From `define-derived-mode'.
    (push docstring body)
    (setq docstring nil))

  (let* ((mode-name (intern (concat "alan-" (symbol-name name) "-mode")))
		 (language-name ;; name based on language naming convention.
		  (s-chop-suffix "-mode" (s-chop-prefix "alan-" (symbol-name name))))
		 (file-pattern ;; the naming convention for the file pattern is to use underscores.
		  (concat (s-replace "-" "_" language-name) "\\.alan\\'"))
		 (syntax-table-name (intern (concat (symbol-name name) "-syntax-table")))
		 (keymap-name (intern (concat (symbol-name name) "-map")))
		 (keywords)
		 (language)
		 (build-dir)
		 (pairs '())
		 (propertize-rules)
		 (pretty-print))

	;; Process the keyword args.
    (while (keywordp (car body))
      (pcase (pop body)
		(`:file-pattern (setq file-pattern (pop body)))
		(`:keywords (setq keywords (pop body)))
		(`:language (setq language (pop body)))
		(`:pairs (setq pairs (pop body)))
		(`:build-dir (setq build-dir (pop body)))
		(`:propertize-rules (setq propertize-rules (pop body)))
		(`:pretty-print (setq pretty-print (pop body)))
		(_ (pop body))))

	(when keywords
	  (setq keywords (mapcar (lambda (keyword-entry)
							   (if (listp (car keyword-entry))
								   (cons (regexp-opt (car keyword-entry)) (cdr keyword-entry))
								 keyword-entry)
							   ) keywords)))

	`(progn
	   (add-to-list 'auto-mode-alist '(,file-pattern . ,name))
	   (flycheck-add-mode 'alan ',name)

	   (defvar ,syntax-table-name
		 (make-syntax-table alan-mode-syntax-table)
		 ,(concat "Syntax table for ‘" (symbol-name name)  "’."))

	   (defvar ,keymap-name
		 (let ((map (make-sparse-keymap)))
		   (set-keymap-parent map alan-mode-map)
		   map))

	   (define-derived-mode ,name alan-mode ,language-name
		 ,docstring
		 :group 'alan
		 :after-hook (alan-setup-build-system)
		 ,(when language
			`(progn
			   (setq alan-language-definition ,language)))
		 ,(when build-dir
			`(progn
			   (setq alan-compiler-project-root ,build-dir)))
		 ,(when keywords
			`(progn
			   (font-lock-add-keywords nil ',keywords "at end")))
		 ,@(mapcar
			(lambda (pair)
			  `(progn
				 (modify-syntax-entry ,(string-to-char (car pair)) ,(concat "(" (cdr pair)) ,syntax-table-name)
				 (modify-syntax-entry ,(string-to-char (cdr pair)) ,(concat ")" (car pair)) ,syntax-table-name)))
			pairs)
		 ,(when propertize-rules
			`(progn
			   (set (make-local-variable 'syntax-propertize-function) (syntax-propertize-rules ,@propertize-rules))))
		 ,(when pretty-print
			`(progn
			   (setq alan-pretty-print t)))
		 ,@body))))

;;; Xref backend

(defun alan-guess-type ()
  "Return the type assuming point is at the end of an identifier.
Types usually have the form of : or -> followed by a single
word. E.g. '-> stategroup'."
  (progn (save-mark-and-excursion
		   (save-match-data
			 (if (looking-at "\\s-?\\(?:->\\|:\\)\\s-?\\(\\w+\\)")
				 (match-string 1)
			   "")))))

(defun alan-boundry-of-identifier-at-point ()
  "Return the beginning and end of an alan identifier or nil if point is not on an identifier."
  (let ((text-properties (nth 1 (text-properties-at (point)))))
	(when (or (and (listp text-properties)
				   (member font-lock-variable-name-face text-properties))
			  (eq font-lock-variable-name-face text-properties))
	  (save-excursion
		(when-let* ((beginning (nth 8 (syntax-ppss)))
				   (end (progn (goto-char beginning) (forward-sexp) (point))))
		  (cons beginning end))))))
(put 'identifier 'bounds-of-thing-at-point 'alan-boundry-of-identifier-at-point)
(defun alan-thing-at-point ()
  "Find alan variable at point."
  (let ((boundary-pair (bounds-of-thing-at-point 'identifier)))
    (if boundary-pair
        (buffer-substring-no-properties
         (car boundary-pair) (cdr boundary-pair)))))
(put 'identifier 'thing-at-point 'alan-thing-at-point)

(defun alan--xref-backend () 'alan)

(defvar alan--xref-format
  (let ((str "%s%s :%d%s"))
	;; Notice that %s counts as 1 character.
    (put-text-property 0 1 'face 'font-lock-variable-name-face str)
    (put-text-property 1 2 'face 'font-lock-function-name-face str)
    str)
  "The string format for an xref including font locking.")

(defun alan--xref-make-xref (symbol type buffer symbol-position path)
  (xref-make (format alan--xref-format symbol
					 (if (s-blank? type) "" (s-prepend " " (substring-no-properties type)))
					 (line-number-at-pos symbol-position)
					 (if (s-blank? path) "" (s-prepend " " (substring-no-properties path))))
			 (xref-make-buffer-location buffer symbol-position)))

(defun alan--projectile-project-root ()
  "Find the project root of a buffer if projectile is available.
Return `default-directory' if the buffer is not in a project or
projectile is not available."
  (if (featurep 'projectile)
	(let ((projectile-require-project-root nil))
	  (projectile-project-root))
	default-directory))

(defun alan--xref-find-definitions (symbol)
  "Find all definitions matching SYMBOL."
  (let ((xrefs '())
		(chopped-symbol (s-chop-prefix "'" (s-chop-suffix "'" symbol)))
		(project-scope-limit (and
							  alan-xref-limit-to-project-scope
							  (alan--projectile-project-root))))
	(dolist (buffer (buffer-list))
	  (with-current-buffer buffer
		(when (and (derived-mode-p 'alan-mode)
				   (or (null project-scope-limit)
					   (string= project-scope-limit (alan--projectile-project-root))))
		  (save-excursion
			(save-restriction
			  (widen)
			  (goto-char (point-min))
			  (while (re-search-forward "^\\s-*\\('\\([^'\n\\]\\|\\(\\\\'\\)\\|\\\\\\\)*'\\)" nil t)
				(when (string= (match-string 1) symbol)
				  (push (alan--xref-make-xref symbol (alan-guess-type) buffer (match-beginning 1) (alan-path)) xrefs))))))))
	(when (string-match-p "\\.alan'\\'" symbol)
	  (dolist (alan-file (split-string (shell-command-to-string (concat "find " alan-compiler-project-root " -type f -name \"*.alan\"")) "\n" t))
		(when (s-equals-p chopped-symbol (file-name-nondirectory alan-file))
		  (push (xref-make alan-file (xref-make-file-location alan-file 1 0)) xrefs))))
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
        (while (re-search-forward "^\\s-*\\('\\([^'\n\\]\\|\\(\\\\'\\)\\|\\\\\\\)*'\\)" nil t)
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
			(start-line-number (line-number-at-pos)))
		(while (and (not (bobp))
					(> start-indent 0)
					(or (not (looking-at "\\s-*'\\([^'\n\\]\\|\\(\\\\'\\)\\|\\\\\\\)*'"))
						(looking-at line-to-ignore-regex)
						(> (current-indentation) curr-indent)
						(<= start-indent (current-indentation))))
		  (forward-line -1)
		  (unless  (looking-at line-to-ignore-regex)
			(setq curr-indent (min curr-indent (current-indentation)))))
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

(defmacro alan--save-hs-overlays (&rest body)
  "Expand all `hideshow' overlays do BODY and then restore the invsible property"
  `(if (bound-and-true-p hs-minor-mode)
	   (let ((overlays (overlays-in (point-min) (point-max)))
			 (hs-overlays (list)))
		 (dolist  (ov overlays)
		   (when (overlay-get ov 'hs)
			 (add-to-list 'hs-overlays ov)
			 (overlay-put ov 'invisible nil)))
		 ,@body
		 (dolist  (ov hs-overlays)
		   (overlay-put ov 'invisible 'hs)))
	 (progn ,@body)))

(defun alan-path ()
  "Gives the location as a path of where you are in a file.
E.g. 'views' . 'queries' . 'context' . 'candidates' . 'of'"
  (let ((path-list '())
		has-parent)
	(save-excursion
	  (alan--save-hs-overlays
	   (while (setq has-parent (alan--has-parent))
		 (goto-char has-parent)
		 (setq path-list (cons (match-string 1) path-list)))))
	(if path-list
		(mapconcat 'identity path-list ".")
	  "")))

(defun alan--single-block (line)
  "Check if a line is a single block.
A single block is a line that starts with an open paren and end
with a closing paren on the same line. LINE steps a number of
lines forward or backward."
  (save-excursion
	(forward-line line)
	(back-to-indentation)
	(and (looking-at "\\s(")
		 (eq (line-number-at-pos)
			 (progn (forward-sexp) (line-number-at-pos)))
		 (looking-back "\\s)$" 2))))

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
		(when (alan--single-block 0)
		  (if (alan--single-block -1)
			  (setq new-indent previous-line-indentation)
			(setq new-indent (min
							  (if previous-line-indentation (+ previous-line-indentation tab-width) tab-width )
							  (+ new-indent tab-width)))))))
	(when new-indent
	  (indent-line-to new-indent))))

(defun alan-font-lock-syntactic-face-function (state)
  "Don't fontify single quoted strings.
STATE is the result of the function `parse-partial-sexp'."
  (if (nth 3 state)
      (let ((startpos (nth 8 state)))
        (if (eq (char-after startpos) ?')
            ;; This is not a string, but an identifier.
            nil
		  font-lock-string-face))
    font-lock-comment-face))

(defun alan-update-header ()
  "Set the `header-line-format' to `alan-path'."
  (setq header-line-format (format " %s  " (alan-path)))
  (force-mode-line-update))

(defun alan-throttle (secs function)
  "Return the FUNCTION throttled in SECS."
  (let ((executing nil)
				(buffer-to-update (current-buffer))
				(local-secs secs)
				(local-function function))
	(lambda ()
	  (unless executing
		(setq executing t)
		(funcall local-function)
		(run-with-timer
		 local-secs nil
		 (lambda ()
		   (with-current-buffer buffer-to-update
			 (funcall local-function)
			 (setq executing nil))))))))

;;; Flycheck

(defun alan-flycheck-error-filter (error-list)
  "Flycheck error filter for the Alan comopiler.
Exclude '/dev/null' and errors from all buffers but the current buffer from `ERROR-LIST'."
  (seq-remove (lambda (error)
				(or (string= (flycheck-error-filename error) "/dev/null")
					(not (string= (flycheck-error-filename error) (buffer-file-name)))))
			  error-list))

(defvar-local alan--flycheck-language-definition nil
  "The real path to the language definition if `alan-language-definition' can be resolved.")

(progn
  (when (not (getenv "ALAN_COMPILER_FORMAT"))
	(setenv "ALAN_COMPILER_FORMAT" "emacs"))
  (when (not (getenv "ALAN_COMPILER_LOG"))
	(setenv "ALAN_COMPILER_LOG" alan-log-level)))

(flycheck-define-checker alan
  "An Alan syntax checker."
  :command ("alan"
			(eval (if (null alan--flycheck-language-definition)
					  '("build")
					`(,alan--flycheck-language-definition "-C" ,alan-compiler-project-root "/dev/null"))))
  :error-patterns
  ((error line-start (file-name) ":" line ":" column ": error:" (zero-or-one " " (one-or-more digit) ":" (one-or-more digit))
		  ;; Messages start with a white space after the error.
		  (message (zero-or-more not-newline)
				   (zero-or-more "\n " (zero-or-more not-newline)))
		  line-end)
   (warning line-start (file-name) ":" line ":" column ": warning:" (zero-or-one " " (one-or-more digit) ":" (one-or-more digit))
			(message (zero-or-more not-newline)
					 (zero-or-more "\n " (zero-or-more not-newline)))
			line-end))
  :error-filter alan-flycheck-error-filter
  :modes (alan-mode)) ;; all other modes are added using the `alan-define-mode' macro.
(add-to-list 'flycheck-checkers 'alan)

;;; Project root and build system

(defvar-local alan-project-root nil
  "The project root set by function `alan-project-root'.")
(defun alan-project-root ()
  "Project root folder.

Determined based on the presence of a project.json or versions.json file.

If `alan-language-definition' is set prefer to use the
project.json over versions.json."
  (or
   alan-project-root
   (setq alan-project-root
		 (expand-file-name
		  (or (let ((project-files ["versions.json" "project.json"]))
				(seq-find
				 #'stringp
				 (seq-map (lambda (project-file)
							(locate-dominating-file default-directory project-file))
						  ;; Prefer to use project.json if `alan-language-definition' is set.
						  (if alan-language-definition (seq-reverse project-files) project-files))))
			  (progn
				(message  "Couldn't locate project root folder with a versions.json or project.json file. Using' %s' as project root." default-directory)
				default-directory))))))

(defun alan-file-executable (file)
  "Check if FILE is executable and return FILE."
  (when (file-executable-p file) file))

(defun alan-find-alan-script ()
  "Try to find the alan script in the dominating directory starting from the function `alan-project-root'.
Return nil if the script can not be found."
  (when-let ((alan-project-script
			  (locate-dominating-file
			   (alan-project-root)
			   (lambda (name)
				 (let ((alan-script-candidate (concat name "alan")))
				   (and (file-executable-p alan-script-candidate)
						(not (file-directory-p alan-script-candidate))))))))
	(expand-file-name (concat alan-project-script "alan"))))

(defun alan--file-exists (name)
  "Return the file NAME if it exists."
  (when (file-exists-p name) name))

(defvar-local alan-pretty-printer nil
  "When not empty, the pretty printer executable of the current language.")

(defvar-local alan-pretty-print nil
  "When non nill try to pretty print the current file.")

(defun alan-setup-build-system ()
  "Setup Flycheck and the `compile-command'."
  (if (buffer-file-name)
	  (let ((alan-project-script (or (alan-find-alan-script)
									 (executable-find alan-script)))
			(alan-project-compiler (cond ((alan-file-executable (concat (alan-project-root) "dependencies/dev/internals/alan/tools/compiler-project")))
										 ((alan-file-executable (concat (alan-project-root) ".alan/dataenv/platform/project-compiler/tools/compiler-project")))
										 ((alan-file-executable (concat (alan-project-root) ".alan/devenv/platform/project-compiler/tools/compiler-project")))))
			(alan--pretty-printer (cond ((alan-file-executable (concat (alan-project-root) "dependencies/dev/internals/alan/tools/pretty-printer")))
										((alan-file-executable (concat (alan-project-root) ".alan/dataenv/platform/project-compiler/tools/pretty-printer")))
										((alan-file-executable (concat (alan-project-root) ".alan/devenv/platform/project-compiler/tools/pretty-printer")))))
			(alan-project-language (when alan-language-definition
									 (or (when (file-name-absolute-p alan-language-definition) alan-language-definition)
										 (concat (alan-project-root) alan-language-definition)))))
		(setq-local compilation-error-screen-columns nil)
		(cond
		 ((and alan-project-compiler alan-language-definition)
		  (setq-local flycheck-alan-executable alan-project-compiler)
		  (setq-local alan--flycheck-language-definition alan-project-language)
		  (setq-local compile-command
					  (concat alan-project-compiler " " alan-project-language " -C " alan-compiler-project-root " /dev/null "))
		  (setq alan-pretty-printer (concat alan--pretty-printer " " alan-project-language "  --allow-unresolved -C " alan-compiler-project-root
											" --file '" (buffer-file-name) "' -- " (alan--file-path-to-relative-project-path (buffer-file-name)))))
		 (alan-project-script
		  (setq-local flycheck-alan-executable alan-project-script))
		 (t (message "No alan compiler or script found.")))
		(when alan-project-script
		  (setq-local compile-command (concat alan-project-script " build"))))))

(defun alan--file-path-to-relative-project-path (file)
  "Convert the FILE name to a relative project path.
As used in the project compiler."
  (s-join " " (cl-mapcar (lambda (s) (s-wrap s "'" ) ) (s-split "/" (file-relative-name file  alan-compiler-project-root)))))

;;; Modes

(defvar alan-imenu-generic-expression
  ;; Patterns to identify alan definitions
  '(("dictionary" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* dictionary" 1)
	("state group" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* stategroup" 1)
	("component" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* component" 1)
	("text" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* text" 1)
	("number" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* number" 1)
	("matrix" "^\\s-+'\\(\\(?:\\sw\\|\\s-+\\)*\\)'\\s-+->\\s-* \\(?:dense\\|sparse\\)matrix" 1)))

;;;###autoload (autoload 'alan-schema-mode "alan-mode")
(alan-define-mode alan-schema-mode
	"Major mode for editing Alan schema files."
  :language "dependencies/dev/internals/alan/language"
  :build-dir "../.."
  :pairs (("{" . "}") ("(" . ")"))
  :pretty-print t
  :keywords ((":\\s-+\\(stategroup\\|component\\|group\\|dictionary\\|densematrix\\|sparsematrix\\|reference\\|integer\\|natural\\|text\\)\\(\\s-+\\|$\\)" 1 font-lock-type-face)
			 (("deprecated") . font-lock-warning-face)
			 (("apply" "identical-variant-switch" "key-switch" "narrowest"
			    "narrows" "non-empty" "parity-switch" "product" "sign-switch"
			    "struct-switch" "sum" "switch" "variant-switch" "widening"
			    "widens" "widest"
			   ) . font-lock-function-name-face)
			 (("!"  "!root" "$" "$^" "&" "(" ")" "," "-" "->" "."  ".&" ":" "::"
			   "=" "=>" ">" ">>" ">key" "?"  "?>" "@" "@usage" "@usage-ignore"
			   "@usage-propagate" "@warn" "[" "[]" "]" "^" "acyclic-graph"
			   "apply" "as" "combinator" "component" "component-types"
			   "compound" "context" "defines" "deprecated" "dictionary" "even"
			   "external" "group" "identical" "identical-variant-switch" "in"
			   "inferred" "integer" "is" "key-switch" "libraries" "narrowest"
			   "narrows" "negative" "non" "non-empty" "none" "odd" "on"
			   "ordered-graph" "parametric" "parity-switch" "plural" "positive"
			   "primitive" "product" "reference" "required" "root" "self" "set"
			   "sibling" "sign-switch" "singular" "stategroup" "struct"
			   "struct-switch" "sum" "switch" "text" "using" "variant"
			   "variant-switch" "when" "where" "widening" "widens" "widest"
			   "zero" "{" "|" "||" "}") . font-lock-builtin-face)))

(defun alan-grammar-update-keyword ()
  "Update the keywords section based on all used keywords in this grammar file."
  (interactive)
  (save-excursion
	(save-restriction
	  (widen)
	  (goto-char (point-min))
	  (let* ((keyword-point (re-search-forward "^keywords$"))
			(root-point-start (progn (re-search-forward "^root\\( {\\)?$") (match-beginning 0)))
			(keywords-with-annotations (mapcar #'cdr (s-match-strings-all
										"\\('[^']*'\\)\s-*\\(@.*\\)\n"
										(buffer-substring-no-properties keyword-point root-point-start))))
			(alan-keywords (list)))
		(while (re-search-forward "\\[\\(\\s-?,?'[^'\n]+'\\s-?,?\\)+\\(?:@.*\\)?\\]" nil t)
		  (let ((keyword-group (match-string 0))
				(search-start 0))
			(while (string-match "'[^']+'" keyword-group search-start)
			  (when (null (nth 4 (syntax-ppss))) ;; Check if the match is not inside a comment
				(push (match-string 0 keyword-group) alan-keywords))
			  (setq search-start (match-end 0)))))
		(delete-region (+ 1 keyword-point) root-point-start)
		(goto-char (+ 1 keyword-point))
		(dolist (keyword (sort (delete-dups alan-keywords) 'string<))
		  (let ((keyword-annotation (assoc keyword keywords-with-annotations)))
			(insert (concat "\t" keyword
							(when keyword-annotation
							  (concat " " (nth 1 keyword-annotation)))
							"\n"))))
		(insert "\n\n")))))

;;;###autoload (autoload 'alan-grammar-mode "alan-mode")
(alan-define-mode alan-grammar-mode
	"Major mode for editing Alan grammar files."
  :language "dependencies/dev/internals/alan/language"
  :build-dir "../.."
  :pretty-print t
  :pairs (("[" . "]") ("{" . "}") ("(" . ")"))
  :keywords (
			 ("\\s-+\\(reference\\|stategroup\\|component\\|dictionary\\|group\\|integer\\|natural\\|text\\)\\(\\s-+\\|$\\)" 1 font-lock-type-face)
			 (( "@block" "@break" "@break?"  "@list" "@list?"  "@order:" "@pad"
			   "@raw" "@section" "@tabular" "@trim" "@trim-left" "@trim-none"
			   "@trim-right" ) . font-lock-keyword-face)
			 (("(" ")" "," "."  ":" "=" "@block" "@break" "@break?"  "@list"
			   "@list?"  "@order:" "@pad" "@raw" "@section" "@tabular" "@trim" "@trim-left"
			   "@trim-none" "@trim-right" "[" "]" "canonical" "component" "component-rules"
			   "dictionary" "dynamic-order" "external" "first" "grammar" "group" "indent"
			   "integer" "keywords" "last" "no" "node" "node-switch" "nodes" "none"
			   "predecessor" "reference" "root" "set" "stategroup" "static" "successor" "text"
			   "{" "|" "}"
			   ) . font-lock-builtin-face)))

(defun alan-template-yank ()
  "Yank but wrap as template."
  (interactive)
  (let ((string-to-yank (current-kill 0 t)))
	(insert (mapconcat 'identity
					   (mapcar (lambda (s)
								 (format "\"%s\" ;" (replace-regexp-in-string "\"" "\\\\\"" s)))
							   (split-string string-to-yank "\n"))
					   "\n"))))

;;;###autoload (autoload 'alan-template-mode "alan-mode")
(alan-define-mode alan-template-mode
	"Major mode for editing Alan template files."
  :pairs (("[" . "]") ("(" . ")"))
  :file-pattern "templates/.*\\.alan\\'"
  :build-dir "../../../"
  :language "dependencies/dev/internals/alan-to-text-transformation/language")

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
			(push (match-string 1) numerical-types)))
		numerical-types))))

;;;###autoload (autoload 'alan-application-mode "alan-mode")
(alan-define-mode alan-application-mode
	"Major mode for editing Alan application model files."
  :pairs (("{" . "}"))
  :pretty-print t
  :language ".alan/devenv/platform/if-types/model/language"
  :keywords (
			 ("\\(:\\|:=\\)\\s-+\\(stategroup\\|component\\|group\\|file\\|collection\\|command\\|reference-set\\|number\\|text\\)\\(\\s-+\\|$\\)" 2 font-lock-type-face)
			 (("today" "now" "zero" "true" "false" "node" "none") . font-lock-constant-face)
			 (("@ascending:" "@breakout" "@date" "@date-time" "@default:"
			 "@descending:" "@description:" "@desired" "@dormant" "@duration:"
			 "@factor:" "@hidden" "@icon:" "@identifying" "@label:"
			 "@linked-node-mapping" "@max:" "@metadata" "@min:" "@multi-line"
			 "@name" "@ordered:" "@small" "@sticky" "@style:" "@validate:"
			 "@verified" "@visible") . font-lock-keyword-face)
			 (("abs" "add" "ceil" "compare" "concat" "count" "create" "delete"
			 "diff" "division" "ensure" "execute" "flatten" "floor" "inverse"
			 "join" "product" "remainder" "subtract" "sum" "switch" "update"
			 "walk") . font-lock-function-name-face)
			 (("$" "$^" "&" "(" ")" "*" "+" "," "-" "-<" "->" "." ".&" "/" ":"
			   "<" "<=" "<>" "=" "==" "=>" ">" ">=" "?"  "@" "@^" "@ascending:"
			   "@breakout" "@color" "@date" "@date-time" "@default:"
			   "@descending:" "@description:" "@desired" "@dormant:"
			   "@duration:" "@emphasis" "@hidden" "@icon:" "@identifying"
			   "@label" "@max:" "@metadata" "@min:" "@multi-line" "@name:"
			   "@numerical-type:" "@show:" "@small" "@style:" "@transition:"
			   "@validate:" "@verified" "[" "[]" "]" "^" "abs" "accent" "action"
			   "active:" "acyclic-graph" "add" "anonymous" "as" "auto-increment"
			   "background" "bind" "branch" "brand" "can-create:" "can-delete:"
			   "can-execute:" "can-read:" "can-update:" "ceil" "collection"
			   "command" "compare" "component" "concat" "count" "create"
			   "creation-time" "current" "decimals:" "delete" "diff" "division"
			   "downstream" "dynamic:" "empty" "ensure" "error" "execute"
			   "external" "external-authentication:" "file" "flatten" "floor"
			   "foreground" "from" "group" "guid" "has-todo:" "hide" "hours"
			   "identities:" "identity-initializer:" "ignore" "in" "interactive"
			   "interface" "interfaces" "inverse" "is" "join" "key" "label:"
			   "life-time" "link" "max" "min" "minutes" "mutation-time" "node"
			   "nodes" "none" "now" "number" "numerical-types" "ontimeout"
			   "ordered-graph" "pad" "parameter" "password-initializer:"
			   "password-status:" "password:" "positive" "product"
			   "reference-set" "remainder" "reset:" "resolvable" "root"
			   "seconds" "self" "show" "sibling" "space" "stategroup" "std"
			   "sticky" "subtract" "success" "sum" "switch" "text"
			   "time-in-seconds" "timer" "to-color" "to-text" "today" "union"
			   "update" "user" "user-initializer:" "users" "walk" "warning"
			   "where" "with" "{" "|" "||" "}" "~>") . font-lock-builtin-face)))

;;;###autoload (autoload 'alan-widget-mode "alan-mode")
(alan-define-mode alan-widget-mode
	"Major mode for editing Alan widget files."
  :file-pattern "widgets/.*\\.alan\\'"
  :pairs (("{" . "}") ("[" . "]"))
  :pretty-print t
  :language ".alan/devenv/system-types/webclient/language"
  :build-dir "../"
  :keywords ((("#" "$" "(" ")" "*" "," "->" "."  ".key" ":" "::" "=" "==" "=>"
			  ">" ">>" "?"  "@" "@persist" "[" "]" "^" "any" "argument"
			  "ascending" "binding" "by" "collection" "configuration" "context"
			  "control" "current" "default:" "define" "descending" "empty"
			  "engine" "entry" "false" "file" "format" "ignore" "index" "inline"
			  "instruction" "interval:" "lazy" "let" "list" "markup" "match"
			  "number" "on" "phrase" "root" "session" "set" "sort" "state"
			  "stategroup" "static" "switch" "text" "time" "to" "transform"
			  "true" "unconstrained" "view" "widget" "window" "{" "|" "}" )
			  . font-lock-builtin-face))
  :propertize-rules (("\\.\\(}\\)" (1 "_"))))

;;;###autoload (autoload 'alan-views-mode "alan-mode")
(alan-define-mode alan-views-mode
	"Major mode for editing Alan views files."
  :pairs (("{" . "}") ("[" . "]"))
  :file-pattern "views/.*\\.alan\\'"
  :propertize-rules (("/?%\\(}\\)" (1 "_")))
  :pretty-print t
  :language ".alan/devenv/system-types/webclient/language"
  :build-dir "../"
  :keywords ((( "$" "%" "%^" "%}" "*" "+" "+^" "-" "->" "."  ".>" ".^" "/%}" "/>"
				":>" "<" "<<" "<=" "=" "==" ">" ">=" ">>" "?"  "?^" "@" "as"
				"candidates" "collection" "command" "disabled" "enabled" "entity"
				"file" "filter" "from" "group" "id" "inline" "key" "limit" "link"
				"matrix" "node" "none" "now" "number" "of" "on" "open" "path"
				"query" "reference" "refresh" "role" "root" "selected"
				"stategroup" "subscribe" "text" "using" "view" "window")
			  . font-lock-builtin-face)))

;;;###autoload (autoload 'alan-add-to-phrases "alan-mode")
(defun alan-add-to-phrases()
  "Add the identifier at point to the phrases file.

Run the hook `alan-on-phrase-added-hook' on success. You can use
this to refresh the buffer for example `flycheck-buffer'."
  (interactive)
  (when-let ((identifier (or (thing-at-point 'identifier)
							 (save-excursion
							   ;; errors are reported starting at the quote of
							   ;; an identifier.  but thing at point starts
							   ;; after the quote. So try to see if the
							   ;; identifier is after the quote.
							   (when (looking-at "'")
								 (forward-char)
								 (thing-at-point 'identifier)))))
			   (phrases-directory (locate-dominating-file default-directory "phrases.alan"))
			   (phrases-buffer (find-file-noselect (concat phrases-directory "phrases.alan"))))
	(when
		(with-current-buffer phrases-buffer
		  (goto-char (point-min))
		  (unless (search-forward identifier nil t)
			(goto-char (point-max))
			(unless (looking-back (regexp-quote identifier) nil)
			  (insert identifier)
			  (save-buffer)
			  (bury-buffer)
			  (mapc
			   (lambda (translation-buffer-name)
				 (let ((translation-buffer (find-file-noselect (concat phrases-directory "/translations/" translation-buffer-name))))
				   (with-current-buffer translation-buffer
					 (goto-char (point-max))
					 (insert identifier ": " (s-replace "'" "\"" identifier))
					 (save-buffer)
					 (bury-buffer translation-buffer))))
			   (directory-files (concat phrases-directory "/translations/") nil "\.alan$" t))
			  t)))
	  (run-hooks 'alan-on-phrase-added-hook))))

;;;###autoload (autoload 'alan-add-to-phrases "alan-mode")
(defun alan-remove-from-phrases()
  "Remove the identifier at point from the phrases file.

Run the hook `alan-on-phrase-removed-hook' on success. You can use
this to refresh the buffer for example `flycheck-buffer'."
  (interactive)
  (when-let ((identifier (or (thing-at-point 'identifier)
							 (save-excursion
							   ;; errors are reported starting at the quote of
							   ;; an identifier.  but thing at point starts
							   ;; after the quote. So try to see if the
							   ;; identifier is after the quote.
							   (when (looking-at "'")
								 (forward-char)
								 (thing-at-point 'identifier)))))
			 (phrases-directory (file-name-directory buffer-file-name))
			 (phrases-buffer (find-file-noselect (concat phrases-directory "phrases.alan"))))
	(kill-whole-line)
	(save-buffer)
	(mapc
	 (lambda (translation-buffer-name)
	   (let ((translation-buffer (find-file-noselect (concat phrases-directory "/translations/" translation-buffer-name))))
		 (with-current-buffer translation-buffer
		   (goto-char (point-min))
		   (when (search-forward identifier nil t)
			 (kill-whole-line)
			 (save-buffer)
			 (bury-buffer translation-buffer)))))
	 (directory-files (concat phrases-directory "/translations/") nil "\.alan$" t))
	(run-hooks 'alan-on-phrase-removed-hook)))

;;;###autoload (autoload 'alan-wiring-mode "alan-mode")
(alan-define-mode alan-wiring-mode
	"Major mode for editing Alan wiring files."
  :keywords ((("interfaces:" "external-systems:" "systems:" "provides:"
			   "consumes:" "provided-connections:" "from" "external" "internal"
			   "(" ")" "."  "=" "message" "custom")
			  . font-lock-builtin-face)))

;;;###autoload (autoload 'alan-deployment-mode "alan-mode")
(alan-define-mode alan-deployment-mode
	"Major mode for editing Alan deployment files."
  :language ".alan/devenv/platform/project-build-environment/language"
  :keywords ((("external-systems:" "instance-data:" "system-options:"
			   "provided-connections:" ":" "."  "from" "local" "remote" "stack"
			   "system" "migrate" "timezone" "interface" "message" "custom"
			   "socket" "schedule" "at" "never" "every" "day" "hour" "Monday"
			   "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday" )
			  . font-lock-builtin-face)))

;;;###autoload (autoload 'alan-mapping-mode "alan-mode")
(alan-define-mode alan-mapping-mode
	"Major mode for editing Alan mapping files."
  :keywords ((("#" "%" "(" ")" "+" "."  "/" ":" ":=" "=" "=>" ">" "?"  "@" "|"
			   "causal" "collection" "command" "do" "file" "group" "integer"
			   "interfaces" "log" "natural" "number" "on" "reference-set"
			   "roles" "root" "stategroup" "switch" "text" "with")
			  . font-lock-builtin-face)))

;;;###autoload (autoload 'alan-migration-mode "alan-mode")
(alan-define-mode alan-migration-mode
	:pretty-print t
	:keywords ((":\\s-+\\(stategroup\\|group\\|collection\\|number\\|text\\|file\\)" 1 font-lock-type-face)
			   (("-" "->" "," ":" ":(" "?"  "?^" "?^(" "."  ".(" ".^" ".^("
				".key" "(" ")" "{" "}" "@" "*" "/" "&&" "#" "%" "%(" "%^" "%^("
				"+" "+(" "+^" "+^(" "<!"  "<" "=" "==" "=>" ">" ">(" ">key"
				">key(" "|" "as" "collection" "conversion" "convert" "enrich"
				"entry" "extension" "failure" "false" "file" "find" "group" "in"
				"instance" "mapping" "match" "natural" "number" "numerical"
				"panic" "regexp" "root" "shared" "stategroup" "success" "sum"
				"switch" "text" "to-number" "to-text" "to" "token" "true" "type"
				) . font-lock-builtin-face)))

;;;###autoload (autoload 'alan-settings-mode "alan-mode")
(alan-define-mode alan-settings-mode
	:pairs (("{" . "}") ("[" . "]")))

;;;###autoload (autoload 'alan-control-mode "alan-mode")
(alan-define-mode alan-control-mode
	:pretty-print t
	:pairs (("{" . "}")))

;;;###autoload (autoload 'alan-interface-mode "alan-mode")
(alan-define-mode alan-interface-mode
	:keywords ((":\\s-+\\(stategroup\\|group\\|collection\\|number\\|text\\|command\\|file\\)" 1 font-lock-type-face))
	:pretty-print t
	:pairs (("{" . "}")))

;;;###autoload (autoload 'alan-translations-mode "alan-mode")
(alan-define-mode alan-translations-mode
	:file-pattern "translations/.*\\.alan\\'")

;;;###autoload (autoload 'alan-phrases-mode "alan-mode")
(alan-define-mode alan-phrases-mode)

;; Alan documentation mode

(defun alan--documentation-p()
  "Checks if point is on documentation."
  (save-mark-and-excursion
	(move-beginning-of-line 1)
	(looking-at "^\\s-*///")))

(defun alan-mark-documentation ()
  "Set the selected region to the current documentation block."
  (interactive)
  (when (alan--documentation-p)
	(save-restriction
	  (widen)
	  (let ((doc-point-begin (move-beginning-of-line 1)))
	  (while (and (not (bobp))
				  (save-mark-and-excursion
					(next-line -1)
					(alan--documentation-p)))
		(move-beginning-of-line 0))
	  (setq doc-point-begin (point))
	  (while (and (not (eobp))
				 (save-mark-and-excursion
				   (next-line 1)
				   (alan--documentation-p)))
		(move-end-of-line 2))
	  (move-end-of-line 1)
	  (push-mark nil t t)
	  (goto-char doc-point-begin)))))

(defun alan-edit-documentation ()
  "Edit the documentation of an Alan file."
  (interactive)
  (when (alan--documentation-p)
	(save-mark-and-excursion
	  (let* ((this-buffer (current-buffer))
			 (curr-line (line-number-at-pos))
			 (curr-col (current-column))
			 (documentation-content
			  (progn
				(alan-mark-documentation)
				(mapconcat 'identity
						   (mapcar (lambda (s)
									 (replace-regexp-in-string "^\\s-*///\\s-?" "" s))
								   (split-string (buffer-substring (region-beginning) (region-end)) "\n"))
						   "\n")))
			 (beginning-of-documentation (point))
			 (doc-indentation (or (progn (looking-at "^\\(\\s-*\\)///") (match-string 1)) ""))
			 (begin-of-documentation-offset (save-excursion (goto-char (match-end 0)) (current-column)))
			 (new-line (+ 1 (- curr-line (line-number-at-pos))))
			 (new-col (max 0 (- curr-col begin-of-documentation-offset 1))))
		(switch-to-buffer-other-window (s-concat "Alan doc [" (buffer-name) "]"))
		(funcall alan-documentation-major-mode)
		(alan-documentation-mode 1)
		(setq alan-documentation-update
			  (lambda (updated-documentation)
				(let ((new-alan-documentation
					   (mapconcat 'identity
								  (mapcar (lambda (s)
											(concat doc-indentation "/// " s))
										  (split-string updated-documentation "\n"))
								  "\n")))
				  (with-current-buffer this-buffer
					(save-mark-and-excursion
					  (goto-char beginning-of-documentation)
					  (alan-mark-documentation)
					  (delete-active-region)
					  (insert new-alan-documentation)
					  (deactivate-mark))))))
		(mark-whole-buffer)
		(delete-active-region)
		(insert documentation-content)
		(goto-line new-line)
		(move-to-column new-col)
		(deactivate-mark)))))

(defvar-local alan-documentation-update
  nil
  "A callback function for the `alan-documentation-mode' to update
the documentation block.")

(defvar alan-documentation-major-mode
  #'markdown-mode
  "The major mode to use when editing Alan documentation.")

(defun alan-documentation-sync-buffer ()
  "Synchronise the content of the documentation buffer with the source Alan file."
  (interactive)
  (when alan-documentation-update (funcall alan-documentation-update (buffer-string))))

(defun alan-documentation-exit ()
  "Kill the dedicated documentation buffer and update the source
buffer."
  (interactive)
  (alan-documentation-sync-buffer)
  (alan-documentation-abort))

(defun alan-documentation-abort ()
  "Close the documentation buffer without saving."
  (interactive)
  (quit-window t))

(defvar alan-documentation-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c'" 'alan-documentation-exit)
	(define-key map "\C-c\C-k" 'alan-documentation-abort)
	(define-key map "\C-x\C-s" 'alan-documentation-sync-buffer)
    map))

(defface alan-documentation-link '((t :inherit link))
  "Face for links.")

(defconst alan-documentation-include-link-regex
  "<<INCLUDE-ALAN\\[\\(.*\\)]>>")

(defun alan-documentation-include-link-p ()
  "Return non nul when `point' is a an alan link"
  (thing-at-point-looking-at alan-documentation-include-link-regex))

(defun alan-documentation-follow-include-link-at-point ()
  "Follow Alan documentation links."
  (interactive)
  (when-let ((alan-file (and
						 (alan-documentation-include-link-p)
					(match-string-no-properties 1))))
	(if (file-exists-p alan-file )
		(find-file alan-file)
	  (user-error "File not found %s" alan-file))))

(define-minor-mode alan-documentation-mode
  "Minor mode for editing Alan documentation buffers."
  :interactive nil
  (font-lock-add-keywords nil '(("<<INCLUDE-ALAN\\[\\(.*\\)]>>" 1 'alan-documentation-link t)))
  (hack-dir-local-variables-non-file-buffer))

(provide 'alan-mode)

;;; alan-mode.el ends here
