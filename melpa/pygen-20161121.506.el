;;; pygen.el --- Python code generation using Elpy and Python-mode.

;; Copyright (C) 2016 Jack Crawley

;; Author: Jack Crawley <http://www.github.com/jackcrawley>
;; Keywords: python, code generation
;; Package-Version: 20161121.506
;; Package-Commit: 9019ff44ba49d7295b1476530feab91fdadb084b
;; Version: 0.2.7
;; Package-Requires: ((elpy "1.12.0") (python-mode "6.2.2") (dash "2.13.0"))
;; URL: https://github.com/JackCrawley/pygen/

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

;; Pygen is a package that allows the user to automatically generate
;; Python code.  This allows programmers to code first, and worry
;; about the functions they are calling later.

;; A description is available here, but the readme has more
;; information. You can view it at
;; http://www.github.com/jackcrawley/pygen


;; It provides the following code generation commands.  For animated
;; examples of each command in action, see the GitHub page.

;; Generating Classes & Functions
;; ------------------------------

;; `pygen-generate-class' - Generate a python class from the reference
;; under point.

;; `pygen-generate-function' - Generate a python function from the
;; reference under point.

;; `pygen-generate-static-function' - Generate a static python
;; function from the reference under point.

;; Generating Variables
;; --------------------

;; `pygen-extract-variable' - Extract the current region into a
;; variable.

;; `pygen-make-keyword-argument' - Adds a keyword argument to the
;; current function.

;; `pygen-make-sequence-argument' - Adds a sequence argument to the
;; current function.

;; Automatic Decorators
;; --------------------

;; `pygen-add-decorator-to-function' - Adds a decorator in front of
;; the current function.

;; `pygen-make-static' - Turns the current function into a static
;; function.  WARNING: Not currently functional.

;; Modifying the "self" keyword:
;; -----------------------------

;; `pygen-selfify-symbol' - Puts the word 'self.' in front of the
;; current symbol.

;; `pygen-toggle-selfify-symbol' - Toggles the word 'self' in front of
;; the current symbol.

;; `pygen-unselfify-symbol' - Removes the word 'self.' from the
;; current symbol (if it exists).

;; Dynamic Boilerplate Code Generation
;; -----------------------------------

;; `pygen-insert-super' - Inserts a proper call to the current method
;; in the superclass.


;; Pygen leverages `elpy' and `python-mode'.  That's the package
;; called `python-mode', not just the mode.  As of Emacs 24.5.1,
;; `python-mode' is not the default Python mode but a separate
;; package.  The default package is called `python'.

;; Pygen won't work with a Python setup unless `python-mode' is
;; installed.  However, it can work with a setup that doesn't include
;; Elpy.  You just need to tell it how to navigate to function and
;; class definitions.  By default, this is handled by the command
;; `elpy-goto-definition' to navigate to definitions and the command
;; `pop-tag-mark'.  If you use a different system to navigate through
;; python code, you can set the variables
;; `pygen-navigate-to-definition-command' and `pygen-go-back-command'
;; to different functions.

;;; Code:


(require 'elpy)
(require 'python-mode)
(require 'dash)


(defgroup pygen nil
  "Tools for automatically generating Python code."
  :group 'python-mode
  :prefix "pygen-")


(defconst pygen-version "0.2.7")


(defcustom pygen-mode-hook nil
  "Hook run when `pygen-mode' is enabled."
  :type 'hook
  :group 'pygen)


(defcustom pygen-navigate-to-definition-command 'elpy-goto-definition
  "Command to use to navigate to function and class definitions."
  :type 'symbol
  :group 'pygen)


;; Commented out. Not a necessary command at the moment.
;; (defcustom pygen-go-back-command 'pop-tag-mark
;;   "Command to navigate back to previous positions.

;; After `pygen-navigate-to-definition-command' is called, this
;; command is called to navigate back to the previous position."
;;   :type 'symbol
;;   :group 'pygen)


(defvar pygen-re-top-level-class-or-def-definition
  "^\\(class\\|def\\)[ \t\n\\\\]+[A-Za-z0-9_*]+"
  "Regular expression for finding a class or def definition.

Only searches for definitions at the top level.  If a definition
is indented, it won't be matched.")


(defun pygen-in-string-p ()
  "Checks if the point is currently in a string.

Substitute for the `in-string-p' function, which is depreciated."
  (nth 3 (syntax-ppss)))


(defun pygen-verify-environment ()
  "Verify that pygen has the required environments installed."
  ;; TODO: Verify all python-mode functions are available.
  ;; `python-mode' does not need to be active, the functions just need
  ;; to be usable.
  (if pygen-navigate-to-definition-command
	  (if (fboundp pygen-navigate-to-definition-command)
		  (progn 
			(when (eq pygen-navigate-to-definition-command 'elpy-goto-definition)
			  ;; TODO: Verify Elpy is installed
			  (unless elpy-mode
				(error "Error: Elpy is specified as the navigation tool but `elpy-mode' is not active.")))
			(when (eq pygen-navigate-to-definition-command 'py-find-definition)
			  (error "Error: `py-find-definition' not currently useable as a navigation command.")
			  ;; TODO: once `py-find-definition' is confirmed as working,
			  ;; allow it as an option.
			  ;; (unless python-mode
			  ;; 	(error "Error: Python-Mode is specified as the navigation tool but `python-mode' is not active."))
			  ))
		(error (concat "Error: the navigation function `"
					   (symbol-name pygen-navigate-to-definition-command)
					   "' is not bound.")))
	(error "No navigation command set.")))


(defun pygen-verify-expression (&optional bounds)
  "Verify the point is on an expression."
  ;; Get parameters not provided
  (unless bounds
	(setq bounds (pygen-get-expression-bounds)))
  ;; TODO: verify the current expression
  t)


(defun pygen-get-expression-bounds ()
  "Get the bounds of the function under point."
  ;; TODO: Expand this function so it can select any expression style,
  ;; for example:
  ;;     my_function (argument_one, argument_two)
  ;;     my_function "this is the argument"
  ;; Currently, functions like this won't work.  
  (save-excursion
	;; `python-mode' has a bug where a partial expression can't be
	;; selected if the point is on the first character of the
	;; expression. This compensates by moving one character right in
	;; that situation.
	(when (looking-back "[^A-Za-z0-9._*]")
	  (right-char))
	;; Now select the partial expression.
	(py-partial-expression)
	(cons (region-beginning) (region-end))))


(defun pygen-has-parent (&optional bounds verified)
  "Check whether this expression has a parent."
  ;; Get input parameters if not provided
  (unless bounds
	(setq bounds (pygen-get-expression-bounds)))
  (unless verified
	(setq verified (pygen-verify-expression)))
  ;; Now check whether this expression has a parent.
  (save-excursion
	(goto-char (car bounds))
	(and
	 ;; There is enough room for a parent
	 (> (point) 2)
	 ;; The preceding 2 characters match the regular expression for a parent
	 (string-match "[A-Za-z0-9_]\\." (buffer-substring (- (point) 2) (point))))))


(defun pygen-navigate-to-definition-in-module ()
  "Attempts to navigate to the definition of the class under
point in the current module."
  (let ((start-position (point))
		(name-to-find (thing-at-point 'symbol))
		(lowest-indent nil)
		(current-definition-position nil))
	(goto-char (point-min))
	;; TODO: Extract this regexp into a variable
	;; (class/def at any level)
	(while (and (re-search-forward (concat "^[ \t]*\\(class\\|def\\)[ \t\n][ \t\n\\\\]*"
										   name-to-find)
								   nil t)
				(not (in-string-p)))
	  (if lowest-indent
		  (let (indentation-length (py-indentation-of-statement))
			(when (> lowest-indent indentation-length)
			  (setq lowest-indent indentation-length)
			  (setq current-definition-position (point))))
		(setq lowest-indent (py-count-indentation))
		(setq current-definition-position (point))))
	(if current-definition-position
		(progn 
		  (goto-char current-definition-position)
		  (re-search-backward name-to-find nil t))
	  (goto-char start-position)
	  (error "No definition in current module"))))


(defun pygen-goto-expression-parent (&optional bounds verified)
  "Go to the parent of this expression."
  ;; Get input parameters if not provided
  (unless bounds
	(setq bounds (pygen-get-expression-bounds)))
  (unless verified
	(setq verified (pygen-verify-expression)))
  ;; Now go to the parent of this expression
  (let ((left-bound (car bounds)))
	(goto-char left-bound)
	;; If preceding character is a dot
	(if (pygen-has-parent)
		(progn
		  ;; Navigate to parent
		  ;; TODO: Move back to function after this
		  (left-char 2)
		  (let (error-variable)
			(condition-case error-variable
				(funcall pygen-navigate-to-definition-command)
			  (error
			   ;; If Elpy could not find the parent
			   (if (string-match "No definition found" (error-message-string error-variable))
				   ;; Attempt to use the pygen local method to
				   ;; navigate to this parent.  If this doesn't work
				   ;; either, throw an error saying the parent can't
				   ;; be found.
				   (let (error-variable-2)
					 (condition-case error-variable-2
						 (pygen-navigate-to-definition-in-module)
					   (error
						;; If a local method did not exist, throw an
						;; error.  Otherwise a miscellaneous error has
						;; been caught - so re-throw it.
						(if (string-match "No definition in current module"
										  (error-message-string error-variable-2))
							(progn
							  (message "Pygen could not navigate to the parent of this expression.")
							  (error "The parent of this expression could not be found."))
						  error-variable-2))))
				 ;; Otherwise a miscellaneous error was thrown.
				 (message "Pygen could not navigate to the parent of this expression.")
				 (message (concat "Miscellaneous error. Perhaps try calling the "
								  "same command again. Original error below."))
				 error-variable)))))
	  ;; Throw an error if we arent looking at something with a parent
	  (error "Expression does not have a parent. Cannot navigate to parent expression."))))


(defun pygen-get-expression-name (&optional bounds verified)
  "Get the name of the function within `BOUNDS'."
  ;; Get input parameters if not provided
  (unless bounds
	(setq bounds (pygen-get-expression-bounds)))
  (unless verified
	(setq verified (pygen-verify-expression)))
  ;; Now get the expression name
  (let ((full-expression (buffer-substring-no-properties (car bounds) (cdr bounds))))
	(with-temp-buffer
	  (insert full-expression)
	  (goto-char 1)
	  ;; If the expression has arguments, select up to where the name
	  ;; ends. Otherwise, select the entire name.
	  (if (re-search-forward "[^A-Za-z0-9_]" nil t)
		  (buffer-substring-no-properties 1 (1- (point)))
		full-expression))))


(defun pygen-get-expression-arguments-string (&optional bounds verified)
  "Get the arguments for the current expression as a string.

Does not include parentheses.  Only gets the argument inside the
parentheses."
  ;; Get input parameters if not provided
  (unless bounds
	(setq bounds (pygen-get-expression-bounds)))
  (unless verified
	(setq verified (pygen-verify-expression)))
  ;; Now get the expression arguments as a string
  (let ((full-expression (buffer-substring-no-properties (car bounds) (cdr bounds))))
	(with-temp-buffer
	  (insert full-expression)
	  (goto-char 1)
	  ;; If the expression has arguments (within the partial expression)
	  (if (re-search-forward "(" nil t)
		  (buffer-substring-no-properties (point)
										  (1- (point-max)))
		nil))))


(defun pygen-parse-single-argument (argument)
  "Parse a single `ARGUMENT' from raw form into a meaningful keyword.

If no keyword is defined, a dummy argument will be returned
instead of the form `\"_\"'.

If the `argument' is malformed, this function will do its best to
extract some kind of meaningful argument."
  (with-temp-buffer
	(insert " ")
	(insert argument)
	(insert " ")
	(goto-char 1)
	;; Search for the first symbol - this should be the argument.
	;; TODO: extract this regular expression into a variable
	(if (re-search-forward "\\([A-Za-z0-9_*]+\\)[^A-Za-z0-9_*]" nil t)
		(-if-let (keyword (match-string-no-properties 1))
			(progn
			  (if (string= keyword "")
				  "_"
				keyword))
		  "_")
	  nil)))


(defun pygen-get-expression-arguments (&optional bounds verified)
  "Get the list of arguments for the current expression.

Arguments are returned as a list of names."
  ;; Get input parameters if not provided
  (unless bounds
	(setq bounds (pygen-get-expression-bounds)))
  (unless verified
	(setq verified (pygen-verify-expression)))
  ;; Now get expression arguments
  (save-excursion
	(let ((arguments-string (pygen-get-expression-arguments-string bounds verified))
		  (arguments '()))
	  (if arguments-string
		  (with-temp-buffer
			(insert arguments-string)
			(goto-char 1)
			;; Clean up nested s-expressions (dicts, strings, nested
			;; function calls, etc.). This makes things a lot easier
			;; to parse, as it removes nested symbols that might be
			;; mistaken for arguments.
			(save-excursion
			  (while (re-search-forward "[([{\"]" nil t)
				(left-char 1)
				(let ((current-start (point)))
				  (forward-sexp)
				  (delete-region current-start (point))
				  (insert "_"))))
			;; Now repeatedly try to find arguments.  First search for
			;; comma separated arguments, then take the remaining
			;; string as the last argument.
			(while (re-search-forward (rx (group (0+ (not (any ","))))
										  ",")
									  nil t)
			  (-when-let (parsed-argument (pygen-parse-single-argument
										   (match-string-no-properties 1)))
				(push parsed-argument arguments)))
			(let* ((last-argument (buffer-substring-no-properties (point) (point-max)))
				   (parsed-argument (pygen-parse-single-argument last-argument)))
			  (when parsed-argument
				(push parsed-argument arguments)))
			(when arguments
			  (reverse arguments)))
		nil))))


(defun pygen-chomp-whitespace (str)
  "Chomp leading and tailing whitespace from STR."
  (replace-regexp-in-string (rx (or (: bos (* (any " \t\n")))
									(: (* (any " \t\n")) eos)))
							""
							str))


(defun pygen-extract-function-arguments-from-string (arguments-string)
  "Extract a list of arguments from the arguments section of a
function definition.

WARNING: Does not work with star arguments."
  (let ((arguments '())
		(individual-arguments-strings '()))
	(with-temp-buffer
	  (insert arguments-string)
	  (message "")
	  (goto-char 1)
	  (let ((last-position (point)))
		(while (search-forward "," nil t)
		  (unless (pygen-in-string-p)
			(push (buffer-substring-no-properties last-position (- (point) 1)) individual-arguments-strings)
			(setq last-position (point))))
		(when (re-search-forward "[A-Za-z0-9_*]" nil t)
		  (setq last-position (- (point) 1))
		  (push (buffer-substring-no-properties last-position (point-max)) individual-arguments-strings))))
	(while individual-arguments-strings
	  (with-temp-buffer
		(let (start-position
			  end-position)
		  (insert " ")
		  (insert (pop individual-arguments-strings))
		  (insert " ")
		  (goto-char 1)
		  ;; First get argument, then get default value.
		  (let (argument)
			(if (re-search-forward "[A-Za-z0-9_*]" nil t)
				(progn
				  (left-char)
				  (setq start-position (point))
				  (if (re-search-forward "[^A-Za-z0-9_*]" nil t)
					  (setq argument
							(buffer-substring-no-properties start-position (- (point) 1)))
					(error "Error: malformed function definition. Comma was found with no argument before it.")))
			  (error "Error: malformed function definition. Comma was found with no argument before it."))
			(left-char)
			(let ((value (if (search-forward "=" nil t)
							 (progn
							   (pygen-chomp-whitespace (buffer-substring-no-properties (point) (point-max))))
						   nil)))
			  (push (cons argument value) arguments))))))
	arguments))


(defun pygen-get-def-arguments (&optional in-function)
  "Get a list of arguments in the current defun.
Returns a list of (`argument' . `default-value') pairs.
Arguments with no default value have a default value of nil.

`IN-FUNCTION' specifies whether a check has already been
performed to see whether the point is in a function.  This check
can take time, so it's optimal to only do it once."
  (save-excursion
	(let (arguments-string)
	  (unless in-function
		(unless (pygen-def-at-point)
		  (error "Error: not currently in a def.")))
	  (py-beginning-of-def-or-class)
	  (search-forward "(")
	  (left-char)
	  (let ((start-position (1+ (point))))
		;; TODO: Replace this with a more durable navigation function
		;; `forward-sexp' isn't going to work if the definition of an
		;; s-expression changes.
		(forward-sexp)
		(let* ((end-position (1- (point)))
			   (arguments-string
				(buffer-substring-no-properties start-position end-position)))
		  (pygen-extract-function-arguments-from-string arguments-string))))))


(defun pygen-def-at-point ()
  "Check whether the point is currently in a def."
  (save-excursion
	(let ((start-point (point))
		  (region-was-active (region-active-p))
		  error-marking-def)
	  (condition-case nil
		  (py-mark-def)
		(wrong-type-argument (goto-char start-point)
							 (setq error-marking-def t)))
	  (if (and (<= (region-beginning) start-point)
			   (>= (region-end) start-point)
			   (not (= start-point (mark)))
			   (not error-marking-def))
		  (progn
			(pop-mark)
			;; (goto-char start-point)
			;; (when region-was-active
			;;   (activate-mark))
			t)
		(pop-mark)
		;; (goto-char start-point)
		;; (when region-was-active
		;; 	(activate-mark))
		nil))))


(defun pygen-class-at-point ()
  "Check whether the point is currently in a class."
  (save-excursion
	(let ((start-point (point))
		  (region-was-active (region-active-p))
		  error-marking-class)
	  (condition-case nil
		  (py-mark-class)
		(wrong-type-argument (goto-char start-point)
							 (setq error-marking-class t)))
	  (if (and (<= (region-beginning) start-point)
			   (>= (region-end) start-point)
			   (not (= start-point (mark)))
			   (not error-marking-class))
		  (progn
			(pop-mark)
			;; (goto-char start-point)
			;; (when region-was-active
			;;   (activate-mark))
			t)
		(pop-mark)
		;; (goto-char start-point)
		;; (when region-was-active
		;;   (activate-mark))
		nil))))


(defun pygen-argument-already-exists (argument &optional in-function)
  "Whether an `ARGUMENT' already exists in the current function.

Returns t if the argument already exists in the current
function's definition.

`IN-FUNCTION' specifies whether a check has already been
performed to see whether the point is in a function.  This check
can take time, so it's optimal to only do it once.

`ARGUMENT' is the argument to check for."
  (unless in-function
	(setq in-function (pygen-def-at-point)))
  (let ((argument-exists nil)
		(arguments-list (pygen-get-def-arguments)))
	(mapc (lambda (existing-argument)
			(when (string= (downcase argument) (downcase (car existing-argument)))
			  (setq argument-exists t)))
		  arguments-list)
	argument-exists))


(defun pygen-add-keyword-argument-internal (argument)
  "Add a keyword argument to the current function's definition."
  (unless (pygen-def-at-point)
	(error "Error: not currently in a def."))
  (when (pygen-argument-already-exists argument t)
	(error "Error: the argument `%s' already already exists in the function definition."
		   argument))
  
  (py-beginning-of-def-or-class)
  (search-forward "(")
  (let ((start-position (point))
		end-position)
	(left-char)
	(forward-sexp)
	(setq end-position (- (point) 1))
	;; "self" is a special keyword that should always be inserted at
	;; the start of the definition.
	(if (string= (downcase argument) "self")
		(progn
		  (goto-char start-position)
		  (if (re-search-forward "[A-Za-z0-9_*]" end-position t)
			  (progn
				(left-char)
				(insert "self, "))
			(insert "self")))
	  ;; Note that in Python, a star indicates a termination of the
	  ;; positional argument rule. We can use this.
	  
	  ;; Check if any star arguments exist
	  (goto-char end-position)
	  (let ((star-args-present nil)
			first-star-argument) 
		(while (search-backward "*" start-position t)
		  (unless (pygen-in-string-p)
			(setq star-args-present t)
			(setq first-star-argument (point))))
		;; If another argument already exists, argument must be inserted
		;; with a comma. Otherwise, just insert it.
		(if star-args-present
			(progn
			  (goto-char first-star-argument)
			  (if (search-backward "," start-position t)
				  (progn
					(right-char)
					(insert (concat " " argument "=,"))
					(left-char))
				(insert (concat argument "=, "))
				(left-char 2)))
		  (goto-char end-position)
		  (if (re-search-backward "[^ \t\n\\\\]" start-position t)
			  (progn
				(right-char)
				(insert (concat ", " argument "=")))
			(insert argument "=")))))))


(defun pygen-add-sequence-argument-internal (argument)
  "Add a sequence argument to the current functions definition." 
  (unless (pygen-def-at-point)
	(error "Error: not currently in a def."))
  (when (pygen-argument-already-exists argument)
	(error "Error: the argument `%s' already already exists in the function definition."
		   argument))
  (py-beginning-of-def-or-class)
  (search-forward "(")
  (let ((start-position (point))
		end-position)
	(left-char)
	(forward-sexp)
	(setq end-position (- (point) 1))
	
	;; "self" is a special keyword that should always be inserted at
	;; the start of the definition.
	(if (string= (downcase argument) "self")
		(progn
		  (goto-char start-position)
		  (if (re-search-forward "[A-Za-z0-9_*]" end-position t)
			  (progn
				(left-char)
				(insert "self, "))
			(insert "self")))  
	  (goto-char start-position)
	  ;; If keyword arguments exist, place after sequence arguments, but
	  ;; before the first keyword argument.
	  (if (search-forward "=" end-position t)
		  (progn
			;; Keyword argument exists, so:
			;; We will be just after the first equals sign, so search
			;; backwards for the keyword being assigned to with that
			;; equals sign. Then, jump to the beginning of that keyword.
			(if (and (re-search-backward "[A-Za-z0-9_*]" start-position t)
					 (re-search-backward "[^A-Za-z0-9_*]" (- start-position 1) t))
				(progn
				  (right-char)
				  (insert (concat argument ", ")))
			  ;; If these searches yield strange results, it means the
			  ;; function is malformed. Inform the user, but try to
			  ;; insert the argument anyway.
			  (message "Warning: malformed function. Attempting to add argument as best can be done.")
			  (insert argument)))
		;; Keyword arguments don't exist, so check for star arguments
		;; next.
		(goto-char end-position)
		(let ((star-args-present nil)
			  first-star-argument)
		  (while (search-backward "*" start-position t)
			(unless (pygen-in-string-p)
			  (setq star-args-present t)
			  (setq first-star-argument (point))))
		  (if star-args-present
			  (progn
				(goto-char first-star-argument)
				(insert (concat argument ", ")))
			(goto-char start-position)
			;; If other arguments exist, a comma must be added.
			(if (re-search-forward "[A-Za-z0-9_*]" end-position t)
				(progn
				  ;; TODO: If star args, put before them.
				  (goto-char end-position)
				  (insert (concat ", " argument)))
			  (insert argument))))))))


(defun pygen-expression-exists (&optional bounds verified)
  "Check if the current expression already exists."
  ;; Get input parameters if not provided
  (unless bounds
	(setq bounds (pygen-get-expression-bounds)))
  (unless verified
	(setq verified (pygen-verify-expression)))
  ;; Now check if the function exists
  ;; TODO: Optimise this. Find a faster method of checking if it exists.
  ;;       Perhaps if flycheck is open, use that?
  ;; TODO: Local expression exists checking
  (save-excursion
	(let ((expression-exists nil))
	  (goto-char (car bounds))
	  (let ((start-position (point))
			(start-buffer (current-buffer)))
		(condition-case error-variable
			(progn 
			  (funcall pygen-navigate-to-definition-command)
			  (setq expression-exists t)
			  (condition-case nil
				  (tags-loop-continue)
				(error
				 (message "Warning: could not return to previous position. Manually reverting.")
				 (switch-to-buffer start-buffer)
				 (goto-char start-position))))
		  (error
		   (message "Pygen could not navigate to the parent of this expression.")
		   (if (not (string-match "No definition found" (error-message-string error-variable)))
			   (progn
				 (message (concat "Miscellaneous error. Perhaps try "
								  "calling the same command again. "
								  "Original error:"))
				 error-variable)
			 nil))))
	  expression-exists)))


(defun pygen-is-parent-self (&optional bounds verified has-parent)
  "Check if the immediate parent of this expression is 'self'."
  ;; Get input parameters if not provided
  (unless bounds
	(setq bounds (pygen-get-expression-bounds)))
  (unless verified
	(setq verified (pygen-verify-expression)))
  (unless has-parent
	(setq has-parent (pygen-has-parent)))
  ;; Now check if the parent is self
  (save-excursion
	(if has-parent
		(progn
		  (goto-char (car bounds))
		  (left-char)
		  (let ((end-position (point)))
			(py-backward-partial-expression)
			(if (string= (buffer-substring-no-properties (point) end-position)
						 "self")
				t
			  nil)))
	  nil)))


(defun pygen-create-new-function-in-module (arguments &optional function-name decorators)
  "Create a new function in the current module.

Creates the function at the top level of the module, immediately
after all imports.

`decorators' is an optional list of decorators to place before
  the function, as strings."
  (push-mark nil t)
  ;; First get the cursor in position, then insert the function.
  (goto-char (point-min))
  
  ;; If def exists, place before def
  ;; If class exists, place before class
  ;; Otherwise, navigate after imports and place in front of the first statement.
  (let* ((first-class-or-def-position (save-excursion
										(if (re-search-forward
											 pygen-re-top-level-class-or-def-definition nil t)
											(progn
											  (py-beginning-of-def-or-class)
											  (point))
										  nil)))
		 (after-imports-position
		  (save-excursion
			(while (re-search-forward
					"import *[A-Za-z_][A-Za-z_0-9].*\\|^from +[A-Za-z_][A-Za-z_0-9.]+ +import .*" nil t)
			  ;; HACK: The above import searching regexp is dumb.  It stops
			  ;;       once it enters a bracketed import.  This is a way of
			  ;;       getting it to carry on, however it looks fragile to
			  ;;       me.
			  (when (looking-back "(")
				(search-forward ")")))
			(point)))
		 (first-expression-position (save-excursion
									  (goto-char after-imports-position)
									  (py-forward-expression)
									  (py-beginning-of-expression)
									  (if (< (point) after-imports-position)
										  nil
										(point)))))
	(cond (first-class-or-def-position
		   (goto-char first-class-or-def-position))
		  (first-expression-position
		   (goto-char first-expression-position))
		  (t
		   (goto-char (point-max)))))
  
  ;; Now the cursor is in position, the function can be created.
  (unless function-name
	(setq function-name (read-string "Enter function name: ")))
  (beginning-of-line)
  (let ((start-position (point)))
	(insert "\n\n\n")
	(goto-char start-position))
  (while decorators
	(insert (pop decorators))
	(insert "\n"))
  (insert (concat "def " function-name "("))
  (while arguments
	(let ((argument (pop arguments)))
	  (if arguments
		  (insert (concat argument ", "))
		(insert argument))))
  (insert "):")
  (py-newline-and-indent)
  (let ((end-position (point)))
	;; (insert "pass")
	(goto-char end-position)))


(defun pygen-create-new-class-in-module (arguments &optional class-name)
  "Create a new function in the current module.

Creates the function at the top level of the module, immediately
after all imports."
  (push-mark nil t)
  ;; First get the cursor in position, then insert the function.
  (goto-char (point-min))
  
  ;; If def exists, place before def
  ;; If class exists, place before class
  ;; Otherwise, navigate after imports and place in front of the first statement.
  (let* ((first-class-or-def-position (save-excursion
										(if (re-search-forward
											 pygen-re-top-level-class-or-def-definition nil t)
											(progn
											  (py-beginning-of-def-or-class)
											  (point))
										  nil)))
		 (after-imports-position
		  (save-excursion
			(while (re-search-forward
					"import *[A-Za-z_][A-Za-z_0-9].*\\|^from +[A-Za-z_][A-Za-z_0-9.]+ +import .*" nil t)
			  ;; HACK: The above import searching regexp is dumb.  It stops
			  ;;       once it enters a bracketed import.  This is a way of
			  ;;       getting it to carry on, however it looks fragile to
			  ;;       me.
			  (when (looking-back "(")
				(search-forward ")")))
			(point)))
		 (first-expression-position (save-excursion
									  (goto-char after-imports-position)
									  (py-forward-expression)
									  (py-beginning-of-expression)
									  (if (< (point) after-imports-position)
										  nil
										(point)))))
	(cond (first-class-or-def-position
		   (goto-char first-class-or-def-position))
		  (first-expression-position
		   (goto-char first-expression-position))
		  (t
		   (goto-char (point-max)))))
  ;; Now the cursor is in position, the function can be created.
  (let (start-position
		end-position)
	(unless class-name
	  (setq class-name (read-string "Enter class name: ")))
	(beginning-of-line)
	(setq start-position (point))
	(insert "\n\n\n")
	(goto-char start-position)
	(insert (concat "class " class-name "("))
	(push-mark nil t)
	(insert "):")
	(py-newline-and-indent)
	(insert (concat "def __init__(self"))
	(if arguments
		(insert ", "))
	(while arguments
	  (let ((argument (pop arguments)))
		(if arguments
			(insert (concat argument ", "))
		  (insert argument))))
	(insert "):")
	(py-newline-and-indent)
	(setq end-position (point))
	;; (insert "pass")
	(goto-char end-position)))


(defun pygen-create-new-function-in-class (arguments &optional function-name decorators)
  "Create a new function in the current class.

`ARGUMENTS' - the arguments the function should take, as a list
of (NAME . DEFAULT-VALUE) pairs. Give a DEFAULT-VALUE of nil to
create an argument with no default value.

`FUNCTION-NAME' - the name of the function.  If this is not
provided, the user will be prompted for a name.

`DECORATORS' - a list of decorator strings to add before the
function.  Leave this as nil if no decorators should be added."
  (push-mark nil t)
  (py-beginning-of-class)
  (let* ((indentation-end (point))
		 (indentation-start (save-excursion
							  (beginning-of-line)
							  (point)))
		 (indentation-string (buffer-substring-no-properties
							  indentation-start indentation-end)))
	(py-end-of-class)
	(insert "\n\n")

	;; Now insert decorators
	(let ((static-function nil))
	  (while decorators
		(let ((current-decorator (pop decorators)))
		  (insert indentation-string)
		  (insert current-decorator)
		  (py-mark-line)
		  (py-shift-indent-right)
		  (pop-to-mark-command)
		  (when (string= current-decorator "@staticmethod")
			(setq static-function t))
		  (insert "\n")))
	  ;; Insert function itself
	  (insert indentation-string)
	  (unless function-name
		(setq function-name (read-string "Enter function name: ")))
	  (insert (concat "def " function-name "("))
	  ;; For member functions, insert the "self" argument
	  (unless static-function
		(insert "self")
		(when arguments
		  (insert ", "))))
	;; Now insert each argument
	(while arguments
	  (let ((argument (pop arguments)))
		(if arguments
			(insert (concat argument ", "))
		  (insert argument))))
	(insert "):")
	;; HACK: `py-shift-indent-right' will indent any following lines
	;; as well.  Wrapping the current line with the region before
	;; indenting fixes this. 
	(py-mark-line)
	(py-shift-indent-right)
	(pop-to-mark-command)
	(py-newline-and-indent)

	(let ((end-position (point)))
	  ;; Insert dummy function contents. Easier to just leave this
	  ;; out.
	  ;; (insert "pass")
	  (goto-char end-position))))


(defun pygen-create-new-class-in-class (arguments &optional class-name)
  "Create a new function in the current class.

`ARGUMENTS' should be a list of argument names.  
`CLASS-NAME' is an optional name.  If it isn't provided, the user
will be prompted for a name."
  (push-mark nil t)
  (py-beginning-of-class)
  (let* ((indentation-end (point))
		 (indentation-start (save-excursion
							  (beginning-of-line)
							  (point)))
		 (indentation-string (buffer-substring-no-properties
							  indentation-start indentation-end)))
	(goto-char indentation-end)
	(py-end-of-class)
	(insert "\n\n")
	(insert indentation-string)
	(unless class-name
	  (setq class-name (read-string "Enter class name: ")))
	(insert (concat "class " class-name "():"))
	(py-shift-class-right)
	(py-newline-and-indent)
	(insert "def __init__(")
	(insert "self")
	(when arguments
	  (insert ", "))
	(while arguments
	  (let ((argument (pop arguments)))
		(if arguments
			(insert (concat argument ", "))
		  (insert argument))))
	(insert "):")
	(py-newline-and-indent)
	(let ((end-position (point)))
	  ;; Insert dummy init function contents. Easier to just leave
	  ;; this out.
	  ;; (insert "pass")
	  (goto-char end-position))))


(defun pygen-extract-variable-internal (start-position end-position)
  "Extract the code within a given region into a variable."
  (let ((variable-name (read-string "Variable name: "))
		variable-value
		new-position
		statement-start
		indentation-string)
	(when (or (string= variable-name "")
			  (not variable-name))
	  (error "Error: variable name cannot be empty."))
	(let ((variable-value (buffer-substring-no-properties start-position
														  end-position)))
	  (goto-char end-position)
	  (save-excursion
		(delete-region start-position end-position)
		(insert variable-name)
		(let ((new-position (point)))
		  (py-beginning-of-statement)
		  (let ((statement-start (point)))
			(beginning-of-line)
			(let ((indentation-string (buffer-substring-no-properties
									   (point) statement-start)))
			  (insert "\n")
			  (forward-line -1)
			  (insert indentation-string)))
		  (insert (concat variable-name " = " variable-value))
		  (goto-char new-position))
		(right-char (length variable-name))
		(message (concat "Variable `" variable-name "' generated."))))))


(defun pygen-extract-variable-from-region ()
  "Extracts a variable from the current region."
  ;; TODO: verify that the current region is valid
  (let ((start-position (region-beginning))
		(end-position (region-end)))
	(pygen-extract-variable-internal start-position end-position)))


(defun pygen-bounds-of-thing-at-point ()
  "Get bounds of the Python thing at point.

Only works for things that are symbols."
  ;; TODO: get the bounds of the current thing at point
  (error "Function `pygen-bounds-of-thing-at-point' is not yet implemented."))


(defun pygen-add-decorator-to-function (&optional decorator)
  "Add a `DECORATOR' in front of the current function.

If function is called interactively, prompts for a decorator. 

If no decorator has been provided, prompts for a decorator."
  (interactive)
  (unless (pygen-def-at-point)
	(error "Error: not currently in a function"))
  (unless decorator
	(setq decorator (read-string "Enter decorator: " "@"))
	(when (string= decorator "")
	  (error "Error: decorator cannot be empty.")))
  (save-excursion
	(py-beginning-of-def-or-class)
	(let ((def-start (point)))
	  (beginning-of-line)
	  (let ((indentation-string (buffer-substring-no-properties
								 (point) def-start)))
		(insert "\n")
		(forward-line -1)
		(insert indentation-string)
		(insert decorator)))))


(defun pygen-remove-argument (argument)
  "Remove an `ARGUMENT' from the current function's definition.

This function can only be called from within a function
definition.  It will throw an error otherwise."
  (error "Error: method not yet implemented.")
  ;; TODO: This check is performed twice if interactive frontend is called.
  ;; TODO: Allow this command to work with classes as well as functions
  (unless (pygen-def-at-point)
	(error "Error: no def found at point."))
  (when (pygen-argument-already-exists argument)
	(py-beginning-of-def-or-class)
	;; TODO: Ensure this (and other instances of the same search)
	;; don't go past the end of the function.
	(search-forward "(")
	(while (re-search-forward "[A-Za-z0-9_*]")
	  )
	)
  )


(defun pygen-generate-function ()
  "Generate a python function from the reference under point."
  (interactive)
  (let ((bounds (pygen-get-expression-bounds)))
	;; Ensure it's a valid function signature
	(pygen-verify-expression bounds)
	(when (pygen-expression-exists)
	  (user-error "Error: this name already exists. Navigate to its definition to find out where."))
	
	;; Get function parts (name, args, is-method)
	(let* ((function-name (pygen-get-expression-name bounds t))
		   (arguments (pygen-get-expression-arguments bounds t))
		   (has-parent (pygen-has-parent bounds t))
		   (parent-is-self (if has-parent
							   (pygen-is-parent-self bounds t has-parent)
							 nil)))
	  (message "Generating function, please wait...")
	  (if has-parent
		  ;; If the immediate parent is the "self" keyword
		  (if parent-is-self
			  (progn
				(pygen-create-new-function-in-class arguments function-name))
			(pygen-goto-expression-parent)
			;; Is the parent a class or a module? Each requires
			;; different handling.
			(message "Still generating function, please wait...")
			(redisplay)
			(if (pygen-class-at-point)
				(pygen-create-new-function-in-class arguments function-name)
			  (pygen-create-new-function-in-module arguments function-name)))
		;; Otherwise create in current module.
		(pygen-create-new-function-in-module arguments function-name))
	  (message "Function generated."))))


(defun pygen-generate-static-function ()
  "Generate a static python function from the reference under point.

Must be currently inside a class to do this."
  (interactive)
  ;; FIXME: Generates static functions for the current class as
  ;;        module functions.
  ;; FIXME: Inserts the empty string as the name if invoked when
  ;;        point is at the start of a symbol.
  ;; TODO: extract this code into its own class.
  (let ((bounds (pygen-get-expression-bounds)))
	;; Ensure it's a valid function signature
	(pygen-verify-expression bounds)
	(when (pygen-expression-exists)
	  (user-error "Error: this name already exists. Navigate to its definition to find out where."))
	;; Get function parts (name, args, has-parent)
	(let* ((has-parent (pygen-has-parent bounds t))
		   (function-name (pygen-get-expression-name bounds t))
		   (arguments (pygen-get-expression-arguments bounds t))
		   (parent-is-self (if has-parent
							   (pygen-is-parent-self bounds t has-parent)
							 nil)))	
	  ;; (unless has-parent
	  ;;   (error "Error: cannot understand where to create this function. Does the expression specify a parent?"))

	  (message "Generating function, please wait...")
	  (if has-parent
		  ;; If the immediate parent is the "self" keyword
		  (if parent-is-self
			  (progn
				(pygen-create-new-function-in-class arguments function-name '("@staticmethod")))
			(pygen-goto-expression-parent)
			;; Is the parent a class or a module? Each requires
			;; different handling.
			(message "Still generating function, please wait...")
			(redisplay)
			(if (pygen-class-at-point)
				(pygen-create-new-function-in-class arguments function-name '("@staticmethod"))
			  (pygen-create-new-function-in-module arguments function-name)))
		;; Otherwise create in current module.
		(pygen-create-new-function-in-module arguments function-name))
	  (message "Function generated."))))


(defun pygen-generate-class ()
  "Generat a python class from the reference under point."
  (interactive)
  ;; TODO: Generate a python class from a reference
  (let ((bounds (pygen-get-expression-bounds)))
	(pygen-verify-expression bounds)
	;; Ensure it's a valid function signature
	(when (pygen-expression-exists)
	  (user-error "Error: this name already exists. Navigate to its definition to find out where."))
	(let* ((class-name (pygen-get-expression-name bounds t))
		   (arguments (pygen-get-expression-arguments bounds t)) 
		   (has-parent (pygen-has-parent bounds t))
		   (parent-is-self (if has-parent
							   (pygen-is-parent-self bounds t has-parent)
							 nil)))
	  (message "Generating class, please wait...")
	  (if has-parent
		  ;; If the immediate parent is the "self" keyword
		  (if parent-is-self
			  (progn
				(pygen-create-new-class-in-class arguments class-name))
			(pygen-goto-expression-parent)
			(message "Still generating class, please wait...")
			(redisplay)
			;; Is the parent a class or a module? Each requires
			;; different handling.
			(if (pygen-class-at-point)
				(pygen-create-new-class-in-class arguments class-name)
			  (pygen-create-new-class-in-module arguments class-name)))
		;; Otherwise create in current module.
		(pygen-create-new-class-in-module arguments class-name))
	  (message "Class generated."))))


(defun pygen-extract-variable ()
  "Generate a python variable from a reference."
  (interactive)
  
  (if (region-active-p)
	  (progn 
		(pygen-extract-variable-from-region))
	(error "Error: region must be active to extract it into a variable.")
	;; Not implemented yet.  Control will not flow to here.
	(let* ((boundaries (pygen-bounds-of-thing-at-point))
		   (start-position (car boundaries))
		   (end-position (cdr boundaries)))
	  ;; TODO: Implement dynamic extraction of variables.
	  (pygen-extract-variable-internal start-position end-position))))


(defun pygen-make-keyword-argument ()
  "Add the variable under point as a keyword argument.

The variable under point will be added as a sequence argument to
the definition of the current function.  By sequence argument, I
mean the argument has a default value.  This command can only be
called from within a function.

This function is intelligent.  It will attempt to insert the
argument after existing keyword arguments end before star
arguments, to have minimal impact on existing calls to this
function."
  (interactive)
  (let ((variable-name (thing-at-point 'symbol)))
	(unless variable-name
	  (user-error "No variable under point."))
	(pygen-add-keyword-argument-internal variable-name))
  (message "Keyword argument created. Input default value."))


(defun pygen-make-sequence-argument ()
  "Add the variable under point as a sequence argument.

The variable under point will be added as a sequence argument to
the definition of the current function.  By sequence argument, I
mean an argument that has no default value.  This command can
only be called from within a function.

This function is intelligent.  It will attempt to insert the
argument after existing arguments but before keyword arguments,
to have minimal impact on existing calls to this function."
  (interactive)
  (let ((variable-name (thing-at-point 'symbol)))
	(unless variable-name
	  (user-error "No variable under point."))
	(save-excursion
	  (pygen-add-sequence-argument-internal variable-name)))
  (message "Sequence argument created."))


(defun pygen-insert-super ()
  "Insert a proper call to the superclass.

This is basically just a wrapper for `py-insert-super'"
  (interactive)
  (py-insert-super))


(defun pygen-make-static ()
  "Turn the current function into a static function."
  (interactive)
  (pygen-add-decorator-to-function "@staticmethod")
  (when (pygen-argument-already-exists "self")
	(pygen-remove-argument "self")))


(defun pygen-selfify-symbol ()
  "Puts the word 'self.' in front of the current symbol."
  (interactive)
  (save-excursion
	(unless (symbol-at-point)
	  (error "No symbol could be found at point."))
	(unless (pygen-class-at-point)
	  (error "Not currently in a class."))
	(when (string= (symbol-at-point) "self")
	  (error "'self' keyword already present."))
	(goto-char (car (pygen-get-expression-bounds)))
	(when (looking-back "self\.[A-Za-z0-9._*]*")
	  (error "Keyword 'self.' already attached to this symbol."))
	(re-search-backward "[^A-Za-z0-9._*]")
	(right-char)
	(insert "self.")
	t))


(defun pygen-unselfify-symbol ()
  "Remove the word 'self.' from the current symbol (if it exists)."
  (interactive)
  (save-excursion
	(unless (symbol-at-point)
	  (error "No symbol could be found at point."))
	(if (string= (symbol-at-point) "self")
		(let ((bounds (bounds-of-thing-at-point 'symbol)))
		  (goto-char (car bounds))
		  (delete-region (car bounds) (cdr bounds))
		  (when (looking-at "\.")
			(delete-char 1)))
	  (goto-char (car (pygen-get-expression-bounds)))
	  (if (looking-back "self\.[A-Za-z0-9._*]*")
		  (progn
			(search-backward "self.")
			(delete-char (length "self.")))
		(error "The keyword 'self.' could not be found")
		nil))))


(defun pygen-toggle-selfify-symbol ()
  "Toggle the word 'self' in front of the current symbol."
  (interactive)
  (save-excursion
	(unless (symbol-at-point)
	  (error "No symbol could be found at point."))
	(goto-char (car (pygen-get-expression-bounds)))
	(if (or (looking-back "self\.[A-Za-z0-9._*]*")
			(string= (symbol-at-point) "self"))
		(pygen-unselfify-symbol)
	  (pygen-selfify-symbol))))


(defvar pygen-mode-map (make-sparse-keymap)
  "Keymap for pygen.")
(set-keymap-parent pygen-mode-map python-mode-map)


;; This is the precursor to a possible Hydra. Need to figure out a bit
;; better how Hydras work before I can implement this fluidly.

;; (define-key pygen-mode-map (kbd "C-c g g")
;;   (defhydra pygen-menu
;; 	()
;; 	"Pygen"
;; 	("c" pygen-generate-class "Generate class")
;; 	("f" pygen-generate-function "Generate function")
;; 	("s" pygen-generate-static-function "Generate static function")
;; 	("v" pygen-extract-variable "Extract variable")
;; 	("k" pygen-make-keyword-argument "Add keyword argument")
;; 	("a" pygen-make-sequence-argument "Add sequence argument")
;; 	("." pygen-toggle-selfify-symbol "Toggle self")
;; 	;; ("m" pygen-make-static "Make function static")
;; 	("@" pygen-add-decorator-to-function "Add decorator")
;; 	("u" pygen-insert-super "Insert call to super")))

(define-key pygen-mode-map (kbd "C-c g @") 'pygen-add-decorator-to-function)
(define-key pygen-mode-map (kbd "C-c g v") 'pygen-extract-variable)
(define-key pygen-mode-map (kbd "C-c g c") 'pygen-generate-class)
(define-key pygen-mode-map (kbd "C-c g f") 'pygen-generate-function)
(define-key pygen-mode-map (kbd "C-c g s") 'pygen-generate-static-function)
(define-key pygen-mode-map (kbd "C-c g u") 'pygen-insert-super)
(define-key pygen-mode-map (kbd "C-c g k") 'pygen-make-keyword-argument)
(define-key pygen-mode-map (kbd "C-c g a") 'pygen-make-sequence-argument)
;; (define-key pygen-mode-map (kbd "C-c g m") 'pygen-make-static)
;; Toggling of the ".self" keyword is the only ".self" command that is
;; bound.
;; (define-key pygen-mode-map (kbd "") 'pygen-selfify-symbol)
;; (define-key pygen-mode-map (kbd "") 'pygen-unselfify-symbol)
(define-key pygen-mode-map (kbd "C-c g .") 'pygen-toggle-selfify-symbol)


;;;###autoload
(define-minor-mode pygen-mode
  "Minor mode that allows python code-generation commands to be used.

These commands are outlined in the main file, as well as in the
GitHub repo for this project."
  :group 'pygen
  :keymap pygen-mode-map
  :lighter ""
  (when pygen-mode
	(run-hooks pygen-mode-hook)))


;; TODO: generating constants

;; TODO: pygen-make-star-argument

;; TODO: Make all these commands fully compatible with star arguments
;; (*args, **kwargs).

;; TODO: Auto-generation of star args from arguments named "args" and
;; "kwargs".
;; https://pythontips.com/2013/08/04/args-and-kwargs-in-python-explained/

;; TODO: Possibly have a verification function when pygen commands are
;; called to ensure the required packages are installed?

;; TODO: Add Hydra

;; TODO: Work out if default python-mode follow command can be
;; used. `py-find-definition'

;; TODO: Use YASnippets for generated code if the user has YASnippet
;; installed.

;; TODO: Raise an error if a function/class already exists.

;; TODO: If the user regenerates a function/class that already exists,
;; prompt them to ask whether they want the signature modified.
;; Warnings should be more explicit if non-keyword arguments are
;; added, removed or changed.

;; TODO: Use the Elpy navigation function if it is bound and Elpy is
;; active. Otherwise, if it's possible to use the default
;; `py-find-definition' then use that.

;; TODO: Automatic inference of whether the user wants a static or a
;; member function.

;; FIXME: Can't generate function if it looks like the following:
;;     variable = MyClass(function_name)
;; Instead, it just creates a function called MyClass.
;; This is because of how `py-partial-statement' is implemented.

;; FIXME: Can't always cope with bracketed imports, e.g:
;;     `from X import (...)'
;; I only ran into this error once and I didn't record the conditions
;; for it. Keep this here for now unless the error doesn't pop up
;; again.

;; FIXME: Generating a static function when the parent is "self"
;; should throw an error. Also need to update the gif animation that
;; does just this.

;; FIXME: Allow generating member functions in the local module using
;; instances of a class, rather than the "self" keyword. May be
;; complicated to implement as it requires certain amount of lexical
;; understanding.

;; FIXME: Possibly when adding the "self." prefix, keep the cursor in
;; position on the original symbol. Sometimes it moves it to the left
;; side of the "self." at the moment.


(provide 'pygen)
;;; pygen.el ends here
