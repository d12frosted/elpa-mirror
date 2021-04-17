;;; openfoam.el --- OpenFOAM files and directories  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Ralph Schleicher

;; Author: Ralph Schleicher <rs@ralph-schleicher.de>
;; Keywords: languages
;; Package-Version: 20210416.608
;; Package-Commit: 955d5118b50c1b67bf8aa4e92ff6ba35d7445c79
;; Version: 0.10.1
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/ralph-schleicher/emacs-openfoam

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General
;; Public License along with this program.  If not,
;; see <https://www.gnu.org/licenses/>.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; ┆ Open ∇             ┆ -*- mode: ∇; coding: utf-8; -*-
;; ┆      F ield        ┆
;; ┆      O peration    ┆
;; ┆      A nd          ┆
;; ┆      M anipulation ┆
;;
;; This package provides major modes for editing OpenFOAM data files
;; and C++ code.  There are also user commands for managing OpenFOAM
;; case directories.
;;
;; By default, verbatim text blocks in OpenFOAM data files are
;; indented like data which yields acceptable results for C++ code.
;; As an alternative, you can install the Polymode package from MELPA
;; stable.  Polymode provides multiple major mode support for editing
;; C++ code in verbatim text blocks.  OpenFOAM requires Polymode 0.2
;; or newer.  To actually enable Polymode, customize the variable
;; ‘openfoam-verbatim-text-mode’.
;;
;; If you think a ‘∇-mode’ command is a good idea so you can have a
;; fancy looking ‘mode’ variable in your OpenFOAM data files, then
;; just paste the following code into your Emacs initialization file:
;;
;;      (defalias '∇-mode #'openfoam-mode)
;;
;; OpenFOAM is cool and you should be too!

;;; Code:

(require 'cl-lib)
(require 'cc-mode)
(require 'package)
(require 'smie)
(require 'eldoc)
(require 'shell)

;; Declare functions loaded at run-time.
(declare-function define-polymode "ext:polymode" (mode &optional parent doc &rest body))
(declare-function define-hostmode "ext:polymode-core" (name &optional parent doc &rest key-args))
(declare-function define-innermode "ext:polymode-core" (name &optional parent doc &rest key-args))
(declare-function pm-base-buffer "ext:polymode-core" ())

(defgroup openfoam nil
  "OpenFOAM files and directories."
  :group 'languages
  :link '(emacs-commentary-link "openfoam.el")
  :prefix "openfoam-")

(defun openfoam-string-quote (string)
  "Quote all meta-characters in STRING."
  (with-temp-buffer
    (mapc (lambda (char)
	    (when (or (char-equal char ?\\)
		      (char-equal char ?\"))
	      (insert ?\\))
	    (insert char))
	  string)
    (buffer-substring-no-properties (point-min) (point-max))))

(defun openfoam-clamp (number min max)
  "Limit NUMBER to the closed interval [MIN, MAX]."
  (cond ((<= number min)
	 min)
	((>= number max)
	 max)
	(t
	 number)))

;;;; Indentation for Data Files

(defcustom openfoam-basic-offset 4
  "The indentation increment."
  :type 'integer
  :group 'openfoam)

(defsubst openfoam-skip-forward ()
  "Move forward across comments and whitespace characters.
Leave point where scanning stops."
  (forward-comment (point-max)))

(defsubst openfoam-skip-backward ()
  "Move backward across comments and whitespace characters.
Leave point where scanning stops."
  (forward-comment (- (point))))

(defun openfoam-after-block-p ()
  "Return non-nil if point is after the closing ‘}’ character of a dictionary.
The code assumes that point is not inside a string or comment."
  (and (eql (char-before) ?\})
       ;; Not closing a verbatim text.
       (not (eql (char-before (1- (point))) ?#))
       ;; Not closing a variable.
       (not (save-excursion
	      (ignore-errors
		(forward-list -1)
		(and (eql (char-before) ?$)
		     (eql (char-after) ?\{)))))
       t))

;; Primitive dictionary entries are terminated by a ‘;’ character but
;; this may conflict with ‘;’ in verbatim text.  However, verbatim
;; text is mainly used for C++ code and SMIE does a quite good job
;; here, too.  Thus, indenting verbatim text like dictionary entries
;; makes sense -- and it is the simplest solution.
(defconst openfoam-smie-end ";"
  "End statement token.")

(defconst openfoam-smie-grammar
  (smie-prec2->grammar
   (smie-bnf->prec2
    ;; These rules are required to recognize ‘#{’ and ‘#}’ as opening
    ;; token and closing token respectively.
    `((entries (entries ,openfoam-smie-end entries)
	       ("#{" entries "#}")))
    `((assoc ,openfoam-smie-end))))
  "Grammar table for SMIE.")

(defun openfoam-smie-rules (method arg)
  "Indentation rules for SMIE; see ‘smie-rules-function’.
Arguments METHOD and ARG are documented there, too."
  (pcase (cons method arg)
    ('(:elem . basic)
     openfoam-basic-offset)
    ('(:elem . arg)
     0)
    (`(:list-intro . ,(or openfoam-smie-end ""))
     t)
    (`(:after . ,(or "(" "["))
     (cons 'column (1+ (current-column))))
    ))

(defun openfoam-smie-forward-token ()
  "Move forward across the next token."
  (let ((start (point)))
    (openfoam-skip-forward)
    (cond ((eql (char-after) ?\;)
	   (forward-char 1)
	   openfoam-smie-end)
	  ((and (> (point) start)
		(save-excursion
		  (goto-char start)
		  (openfoam-after-block-p)))
	   openfoam-smie-end)
	  ((looking-at "#[{}]")
	   (goto-char (match-end 0))
	   (buffer-substring-no-properties
	    (match-beginning 0) (point)))
	  (t
	   (smie-default-forward-token)))))

(defun openfoam-smie-backward-token ()
  "Move backward across the previous token."
  (let ((start (point)))
    (openfoam-skip-backward)
    (cond ((eql (char-before) ?\;)
	   (forward-char -1)
	   openfoam-smie-end)
	  ((and (< (point) start)
		(openfoam-after-block-p))
	   openfoam-smie-end)
	  ((looking-back "#[{}]" (- (point) 2))
	   (goto-char (match-beginning 0))
	   (buffer-substring-no-properties
	    (point) (match-end 0)))
	  (t
	   (smie-default-backward-token)))))

;;;; C++ Code

(c-add-style "OpenFOAM"
	     `((c-basic-offset . 4)
	       (c-tab-always-indent . t)
	       (c-comment-only-line-offset . (0 . 0))
	       (c-indent-comments-syntactically-p . t)
	       (c-block-comments-indent-p nil)
	       (c-cleanup-list . (defun-close-semi list-close-comma scope-operator))
	       (c-backslash-column . 78)
	       ;; See ‘(c-set-stylevar-fallback 'c-offsets-alist ...)’
	       ;; in file ‘cc-vars.el’.
	       (c-offsets-alist
		(c . +)
		(topmost-intro . 0)
		(topmost-intro-cont . 0)
		(member-init-intro . +)
		(member-init-cont . 0)
		(inher-intro . 0)
		(inher-cont . +)
		(substatement . +)
		(substatement-open . 0)
		(case-label . +)
		(label . -)
		(comment-intro . 0)
		(arglist-intro . +)
		(arglist-cont . 0)
		(arglist-cont-nonempty . 0)
		(arglist-close . 0)
		(stream-op . 0)
		(cpp-macro . c-lineup-cpp-define)
		)))

(defcustom openfoam-c++-style "OpenFOAM"
  "Default indentation style for OpenFOAM C++ code.
A value of nil means to not change the indentation style.
Run the ‘c-set-style’ command to change the indentation style."
  :type '(choice (const :tag "Inherit" nil)
		 (string :tag "Style"))
  :group 'openfoam)

;;;###autoload
(define-derived-mode openfoam-c++-mode c++-mode "C++"
  "Major mode for editing OpenFOAM C++ code."
  :group 'openfoam
  :syntax-table nil
  :abbrev-table nil
  :after-hook (when (not (null openfoam-c++-style))
		(c-set-style openfoam-c++-style))
  ;; That's important.  Otherwise, Polymode doesn't get the indentation right.
  (setq indent-tabs-mode nil))

(defcustom openfoam-verbatim-text-mode nil
  "How to indent and fontify verbatim text blocks in OpenFOAM data files.
A value of ‘polymode’ means to use the Polymode package for editing
verbatim text in OpenFOAM C++ mode; ‘string’ means to treat verbatim
text as string constants; any other value means to treat verbatim text
as data."
  :type '(radio (const :tag "Data" nil)
		(const :tag "String" string)
		(const :tag "Polymode" polymode))
  :group 'openfoam)

(defvar openfoam-poly-c++-innermode)
(defvar openfoam-c++-minor-mode)
(declare-function openfoam-c++-minor-mode "openfoam" (arg))

;; https://polymode.github.io/
(defun openfoam-poly-setup ()
  "Attempt to setup Polymode."
  (unless (featurep 'polymode)
    (when (package-installed-p 'polymode)
      (require' polymode)))
  (when (featurep 'polymode)
    (unless (boundp 'openfoam-poly-c++-innermode)
      (define-innermode openfoam-poly-c++-innermode
	:mode 'openfoam-c++-mode
	:allow-nested nil
	:head-matcher "#{"
	:head-mode 'host
	:head-adjust-face nil
	:tail-matcher "#}"
	:tail-mode 'host
	:tail-adjust-face nil
	:body-indent-offset (lambda () openfoam-basic-offset)
	:adjust-face nil))
    (unless (boundp 'openfoam-c++-minor-mode)
      (define-polymode openfoam-c++-minor-mode nil
	"Minor mode for editing C++ code in OpenFOAM data file buffers."
	:hostmode nil
	:innermodes '(openfoam-poly-c++-innermode)
	:keymap (make-sparse-keymap)
	:lighter ""))
    'polymode))

;;;; Documentation

(defun openfoam-list-end (&optional start)
  "Return the end of the list beginning at START (defaults to point).
Value is the buffer position after the closing parenthesis, or nil
if there is no matching closing parenthesis."
  (ignore-errors
    (save-excursion
      (goto-char (or start (point)))
      (forward-list 1)
      (point))))

(defun openfoam-inside-dimension-set-p (&optional pos)
  "Return non-nil if POS (defaults to point) is inside a dimension set.
Actual return value is the buffer position of the opening ‘[’ character.
Use the ‘openfoam-list-end’ function to find the buffer position of the
closing ‘]’ character."
  (when (eq major-mode 'openfoam-mode)
    (let ((start (nth 1 (syntax-ppss (or pos (point))))))
      (when (eql (char-after start) ?\[)
	start))))

(defcustom openfoam-doc-dimension-set-elements 'unit-names
  "How to document the elements of a dimension set.
Value is either ‘unit-names’, ‘unit-symbols’, ‘dimension-names’,
‘dimension-symbols’, or a list of seven strings.  The symbol names
denote built-in documentation strings.  The list elements are used
to generate a user-defined documentation string."
  :type '(choice (const :tag "Unit names" unit-names)
		 (const :tag "Unit symbols" unit-symbols)
		 (const :tag "Dimension names" dimension-names)
		 (const :tag "Dimension symbols" dimension-symbols)
		 (list :tag "User-defined"
		       (string :tag "Mass"
			       :value "KILOGRAM")
		       (string :tag "Length"
			       :value "METRE")
		       (string :tag "Time"
			       :value "SECOND")
		       (string :tag "Thermodynamic temperature"
			       :value "KELVIN")
		       (string :tag "Amount of substance"
			       :value "MOLE")
		       (string :tag "Electric current"
			       :value "AMPERE")
		       (string :tag "Luminous intensity"
			       :value "CANDELA")))
  :group 'openfoam)

(defun openfoam-eldoc-compile-dimension-set (elements)
  "Compile the documentation string for a dimension set.
Argument ELEMENTS is a list of strings."
  (let ((arg 0) (start 1) end alist)
    (dolist (element elements)
      (setq end (+ start (length element)))
      (push (list arg start end) alist)
      (setq start (1+ end))
      (cl-incf arg))
    (list
     (concat "[" (mapconcat #'identity elements " ") "]")
     (nreverse alist))))

(defvar openfoam-eldoc-dimension-set-alist
  `((unit-names
     ,@(openfoam-eldoc-compile-dimension-set
	'("KILOGRAM" "METRE" "SECOND" "KELVIN" "MOLE" "AMPERE" "CANDELA")))
    (unit-symbols
     ,@(openfoam-eldoc-compile-dimension-set
	'("kg" "m" "s" "K" "mol" "A" "cd")))
    (dimension-names
     ,@(openfoam-eldoc-compile-dimension-set
	'("MASS" "LENGTH" "TIME" "THERMODYNAMIC-TEMPERATURE"
	  "AMOUNT-OF-SUBSTANCE" "ELECTRIC-CURRENT" "LUMINOUS-INTENSITY")))
    (dimension-symbols
     ,@(openfoam-eldoc-compile-dimension-set
	'("M" "L" "T" "Θ" "N" "I" "J"))))
  "Alist of documentation strings for a dimension set.
List elements are cons cells of the form ‘(KEY . (STRING ARG-ALIST))’
where KEY is equal to ‘openfoam-doc-dimension-set-elements’, STRING is
the ElDoc documentation string and ARG-ALIST is an alist of argument
descriptions.")

(defun openfoam-eldoc-dimension-set ()
  "Return the documentation string for a dimension set."
  (when-let ((start (openfoam-inside-dimension-set-p)))
    (let ((limit (point))
	  (arg 0)) ;argument index
      (save-excursion
	(goto-char (1+ start)) ;after the ‘[’
	(openfoam-skip-forward)
	(while (and (looking-at "[-+]?[0-9]+") ;integer
		    (goto-char (match-end 0))
		    (< (point) limit)
		    (let ((pos (point)))
		      (openfoam-skip-forward)
		      (< pos (point))) ;whitespace
		    (cl-incf arg))))
      (cl-multiple-value-bind (doc arg-alist)
	  (cl-values-list
	   (cl-rest
	    (cond ((assq openfoam-doc-dimension-set-elements
			 openfoam-eldoc-dimension-set-alist))
		  ((consp openfoam-doc-dimension-set-elements)
		   (let ((new (cons openfoam-doc-dimension-set-elements
				    (openfoam-eldoc-compile-dimension-set
				     openfoam-doc-dimension-set-elements))))
		     (push new openfoam-eldoc-dimension-set-alist)
		     new)))))
	(when (and doc arg-alist)
	  (set-text-properties 0 (length doc) () doc)
	  (when-let ((pos (cl-rest (assoc arg arg-alist #'eql))))
	    (put-text-property
	     (cl-first pos) (cl-second pos)
	     'face 'eldoc-highlight-function-argument
	     doc)))
	doc))))

(defun openfoam-eldoc-documentation-function ()
  "Value for ‘eldoc-documentation-function’."
  (openfoam-eldoc-dimension-set))

;;;; Major Mode

(defun openfoam-mode-p ()
  "Return non-nil if the current buffer's major mode is OpenFOAM mode."
  (eq (if (when (featurep 'polymode)
	    (symbol-value 'polymode-mode))
	  (with-current-buffer
	      (funcall #'pm-base-buffer)
	    major-mode)
	major-mode)
      'openfoam-mode))

(defcustom openfoam-mode-hook nil
  "Hook called by ‘openfoam-mode’."
  :type 'hook
  :group 'openfoam)

(defvar openfoam-mode-map nil
  "Keymap used in OpenFOAM mode buffers.")
(when (null openfoam-mode-map)
  (let ((map (make-sparse-keymap)))
    (setq openfoam-mode-map map)))

(easy-menu-define openfoam-mode-menu openfoam-mode-map
  "Menu for OpenFOAM mode buffers."
  '("OpenFOAM"
    ["Apply Template" openfoam-apply-data-file-template
     :help "Apply the OpenFOAM data file template to the current buffer"]
    ["Insert Header" openfoam-insert-data-file-header
     :help "Insert an OpenFOAM data file header into the current buffer"]
    ["Insert Dimension Set" openfoam-insert-dimension-set
     :help "Insert a dimension set at point"]
    "--"
    ["Run Shell..." openfoam-shell
     :help "Run an inferior shell in an OpenFOAM case directory"]))

(defvar openfoam-mode-syntax-table nil
  "Syntax table used in OpenFOAM mode buffers.")
(when (null openfoam-mode-syntax-table)
  (let ((syntax-table (make-syntax-table)))
    ;; String constants.
    (modify-syntax-entry ?\" "\"" syntax-table)
    (modify-syntax-entry ?\\ "\\" syntax-table)
    ;; Comments.  The primary comment style is a C++ line comment and
    ;; the secondary comment style is a C block comment.
    (modify-syntax-entry ?/  ". 124" syntax-table)
    (modify-syntax-entry ?*  ". 23b" syntax-table)
    (modify-syntax-entry ?\n ">"     syntax-table)
    (modify-syntax-entry ?\r ">"     syntax-table)
    ;; Dissimilar pairs.
    (modify-syntax-entry ?\( "()" syntax-table) ;list
    (modify-syntax-entry ?\) ")(" syntax-table)
    (modify-syntax-entry ?\[ "(]" syntax-table) ;dimension set
    (modify-syntax-entry ?\] ")[" syntax-table)
    (modify-syntax-entry ?\{ "(}" syntax-table) ;dictionary
    (modify-syntax-entry ?\} "){" syntax-table)
    ;; All other characters except whitespace, ‘/’ and ‘;’ can be used
    ;; in words (symbols).  However, the OpenFoam convention is to not
    ;; use this feature.  Thus, mark most of them as punctuation.
    (modify-syntax-entry ?!  "." syntax-table)
    (modify-syntax-entry ?#  "'" syntax-table) ;directive
    (modify-syntax-entry ?$  "'" syntax-table) ;macro
    (modify-syntax-entry ?%  "." syntax-table)
    (modify-syntax-entry ?&  "." syntax-table)
    (modify-syntax-entry ?\' "." syntax-table)
    (modify-syntax-entry ?+  "." syntax-table)
    (modify-syntax-entry ?,  "." syntax-table)
    (modify-syntax-entry ?-  "." syntax-table)
    (modify-syntax-entry ?.  "." syntax-table)
    (modify-syntax-entry ?:  "." syntax-table)
    (modify-syntax-entry ?\; "." syntax-table)
    (modify-syntax-entry ?<  "." syntax-table)
    (modify-syntax-entry ?=  "." syntax-table)
    (modify-syntax-entry ?>  "." syntax-table)
    (modify-syntax-entry ??  "." syntax-table)
    (modify-syntax-entry ?@  "." syntax-table)
    (modify-syntax-entry ?^  "." syntax-table)
    (modify-syntax-entry ?_  "." syntax-table)
    (modify-syntax-entry ?`  "." syntax-table)
    (modify-syntax-entry ?|  "." syntax-table)
    (modify-syntax-entry ?~  "." syntax-table)
    (setq openfoam-mode-syntax-table syntax-table)))

(defvar openfoam-mode-abbrev-table nil
  "Abbreviation table used in OpenFOAM mode buffers.")
(define-abbrev-table 'openfoam-mode-abbrev-table ())

(defvar openfoam-font-lock-keywords
  `(;; Keywords (function entries).
    ,(concat
      (regexp-opt '("#include"
		    "#includeIfPresent"
		    "#includeEtc"
		    "#includeFunc"
		    "#remove"
		    "#inputMode"
		    "#inputStyle"
		    "#neg"
		    "#calc"
		    "#codeStream"
		    "#if" "#ifeq" "#else" "#endif") t)
      "\\>")
    ;; Verbatim text.
    ,(regexp-opt '("#{" "#}"))
    ;; Macros.
    ("\\(\\$\\)\\(\\sw*\\(?:\\(?:\\.+\\|:\\)\\sw+\\)*\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-variable-name-face nil t)))
  "Default expressions to highlight in OpenFOAM mode buffers.")

;;;###autoload
(define-derived-mode openfoam-mode prog-mode "OpenFOAM"
  "Major mode for OpenFOAM data files."
  :group 'openfoam
  ;; C++ comment style.
  (setq-local comment-start "//"
	      comment-start-skip "\\(?://+\\|/\\*+\\)\\s *"
	      comment-end-skip nil
	      comment-end "")
  ;; Syntax properties.
  (setq-local openfoam-verbatim-text-mode
	      (cl-case (default-value 'openfoam-verbatim-text-mode)
		(polymode
		 (openfoam-poly-setup))
		(string
		 'string)))
  (when (eq openfoam-verbatim-text-mode 'string)
    (setq-local syntax-propertize-function
		(syntax-propertize-rules
		 ;; Verbatim text.
		 ("\\(#\\){"
		  (1 "|"))
		 ("#\\(}\\)"
		  (1 "|"))))
    (setq-local parse-sexp-lookup-properties t))
  ;; Syntax highlighting.
  (setq font-lock-defaults '(openfoam-font-lock-keywords))
  ;; Indentation.
  (setq indent-tabs-mode nil)
  (smie-setup openfoam-smie-grammar #'openfoam-smie-rules
	      :forward-token #'openfoam-smie-forward-token
	      :backward-token #'openfoam-smie-backward-token)
  ;; Documentation.
  (setq-local eldoc-documentation-function #'openfoam-eldoc-documentation-function
	      ;; Save space in the mode line.  Also avoid confusing
	      ;; the user if she reads ‘ElDoc’.
	      eldoc-minor-mode-string nil)
  (eldoc-mode 1)
  ;; Enable Polymode after setting up the host mode.
  (when (eq openfoam-verbatim-text-mode 'polymode)
    (funcall #'openfoam-c++-minor-mode 1))
  ())

;;;; Data Files

(defun openfoam-file-name-equal-p (file-name-1 file-name-2)
  "Return non-nil if FILE-NAME-1 and FILE-NAME-2 shall be considered equal."
  (if (memq system-type '(windows-nt ms-dos))
      (cl-equalp file-name-1 file-name-2)
    (string= file-name-1 file-name-2)))

(defcustom openfoam-data-file-template "\
//  =========                 |  -*- OpenFOAM -*-
//  \\\\      /  F ield         |
//   \\\\    /   O peration     |
//    \\\\  /    A nd           |
//     \\\\/     M anipulation  |
//
// Copyright (C) %Y %(or (getenv \"ORGANIZATION\") user-full-name (user-full-name))
//
// Author: %n <%m>

/// Code:

%|

/// %f ends here
"
  "Template for an OpenFOAM data file.
The following substitutions are made:

     %u  user login name
     %n  user full name
     %m  user mail address
     %h  host name, i.e. ‘system-name’ function
     %d  domain name, i.e. ‘mail-host-address’
     %p  buffer file name
     %f  buffer file name without directory
     %b  buffer file name without directory and file extension
     %Y  current year, i.e. ‘%Y’ time format
     %D  current date, i.e. ‘%Y-%m-%d’ time format
     %T  current time, i.e. ‘%H:%M:%S’ time format
     %L  current date and time, i.e. ‘%Y%m%dT%H%M%S’ time format
     %Z  universal date and time, i.e. ‘%Y%m%dT%H%M%SZ’ time format
     %(  value of Emacs Lisp expression
     %|  existing file contents
     %%  literal %

For date and time formats, a ‘*’ modifier after the ‘%’ means universal
date and time."
  :type '(choice (const :tag "None" nil)
		 (string :tag "Template"))
  :group 'openfoam)

(defcustom openfoam-apply-data-file-template-hook nil
  "Hook called by ‘openfoam-apply-data-file-template’."
  :type 'hook
  :group 'openfoam)

;;;###autoload
(defun openfoam-apply-data-file-template ()
  "Apply the OpenFOAM data file template to the current buffer.
See ‘openfoam-data-file-template’ for more information."
  (interactive)
  (barf-if-buffer-read-only)
  (when openfoam-data-file-template
    (let* ((now (current-time))
	   (path (buffer-file-name))
	   pos ;position of beginning of body
	   offs ;position of point in body
	   (body (save-restriction
		   (widen)
		   (let* ((start (save-excursion
				   (goto-char (point-min))
				   (skip-chars-forward " \t\n")
				   (point)))
			  (end (save-excursion
				 (goto-char (point-max))
				 (skip-chars-backward " \t\n" start)
				 (point))))
		     (setq offs (- (openfoam-clamp (point) start end) start))
		     (buffer-substring-no-properties start end))))
	   (templ (with-temp-buffer
		    (buffer-disable-undo)
		    ;; In case the user modifies some parameters, e.g.
		    ;; the mail address, depending on the major mode.
		    (openfoam-mode)
		    ;; Turn off syntax highlighting.
		    (when (fboundp 'font-lock-mode)
		      (font-lock-mode 0))
		    ;; Fill in template.
		    (erase-buffer)
		    (insert openfoam-data-file-template)
		    (let (len subst)
		      (goto-char (point-min))
		      (while (search-forward "%" nil t)
			(setq len 1) ;pattern length
			(setq subst (cl-case (char-after (point))
				      (?u (or user-login-name (user-login-name)))
				      (?n (or user-full-name (user-full-name)))
				      (?m user-mail-address)
				      (?h (system-name))
				      (?d mail-host-address)
				      (?p (or path ""))
				      (?f (if path (file-name-nondirectory path) ""))
				      (?b (if path (file-name-base path) ""))
				      (?Y (format-time-string "%Y" now))
				      (?D (format-time-string "%Y-%m-%d" now))
				      (?T (format-time-string "%H:%M:%S" now))
				      (?L (format-time-string "%Y%m%dT%H%M%S" now))
				      (?Z (format-time-string "%Y%m%dT%H%M%SZ" now t))
				      (?* (setq len 2)
					  (cl-case (char-after (1+ (point)))
					    (?Y (format-time-string "%Y" now t))
					    (?D (format-time-string "%Y-%m-%d" now t))
					    (?T (format-time-string "%H:%M:%S" now t))
					    (?L (format-time-string "%Y%m%dT%H%M%S" now t))
					    (?Z (format-time-string "%Y%m%dT%H%M%SZ" now t))
					    (t ;no match
					     (setq len 1)
					     nil)))
				      (?\( (let* ((start (point))
						  (object (read (current-buffer)))
						  (end (point))
						  (value (eval object)))
					     (goto-char start)
					     (setq len (- end start))
					     (when (stringp value)
					       value)))
				      (?| (when (null pos) ;first occurrence
					    (setq pos (1- (point))))
					  body)
				      (?% ?%)))
			(if (null subst)
			    ;; Skip pattern, but don't move beyond
			    ;; end of buffer.
			    (forward-char (min len (- (point-max) (point))))
			  ;; Replace pattern.
			  (delete-char -1)
			  (delete-char len)
			  (insert subst))))
		    ;; Reindent the whole buffer.
		    (indent-region (point-min) (point-max))
		    ;; Return filled in template.
		    (buffer-substring-no-properties (point-min) (point-max)))))
      ;; Replace buffer contents.
      (erase-buffer)
      (insert templ)
      ;; Restore point.
      (goto-char (if (null pos)
		     (point-min)
		   (+ pos offs))))
    ;; Turn on OpenFOAM mode.
    (openfoam-mode)
    ;; Provide a hook for further modifications.
    (run-hooks 'openfoam-apply-data-file-template-hook)))

(defcustom openfoam-insert-data-file-header-position-hook nil
  "Leave point where to insert the OpenFOAM data file header.
Hook called by ‘openfoam-insert-data-file-header’."
  :type 'hook
  :group 'openfoam)

(defcustom openfoam-insert-data-file-header-line-limit 100
  "Number of lines searched for inserting the OpenFOAM data file header.
A positive value means to search not more than that many lines at the
beginning of a file to find a suitable buffer position for the OpenFOAM
data file header.  A negative value counts from the end, zero means to
search the whole file."
  :type 'integer
  :group 'openfoam)

(defvar openfoam-insert-data-file-header-limit)

;;;###autoload
(defun openfoam-insert-data-file-header (&optional here)
  "Insert an OpenFOAM data file header into the current buffer.

With prefix argument HERE, insert the data file header at the current
line.  Otherwise, run ‘openfoam-insert-data-file-header-position-hook’
to find a suitable buffer position.  If no hook function is configured,
search for the ‘Code:’ special comment and insert the data file header
after it.  If ‘Code:’ is not found, insert the data file header before
the first dictionary entry.

While looking for a suitable buffer position, the special variable
‘openfoam-insert-data-file-header-limit’ is bound to the buffer position
specified by ‘openfoam-insert-data-file-header-line-limit’.  Whether or
not a hook function obeys this limit is undefined."
  (interactive "P")
  (barf-if-buffer-read-only)
  (unless (eq major-mode 'openfoam-mode)
    (openfoam-mode))
  (let* ((buffer-file-name (buffer-file-name))
	 (file-name (and buffer-file-name
			 (file-name-nondirectory buffer-file-name)))
	 (directory (and buffer-file-name
			 (file-name-directory buffer-file-name)))
	 (case-directory (and directory
			      (openfoam-case-directory directory)))
	 (location (and directory case-directory
			(directory-file-name
			 (file-relative-name directory case-directory)))))
    (let ((point (point-marker)))
      (if (not (null here))
	  (beginning-of-line)
	(goto-char (point-min))
	(let ((openfoam-insert-data-file-header-limit
	       (if (= openfoam-insert-data-file-header-line-limit 0)
		   (point-max)
		 (save-excursion
		   (when (< openfoam-insert-data-file-header-line-limit 0)
		     (goto-char (point-max)))
		   (forward-line openfoam-insert-data-file-header-line-limit)
		   (point)))))
	  (cond ((not (null openfoam-insert-data-file-header-position-hook))
		 (run-hooks 'openfoam-insert-data-file-header-position-hook))
		;; Search for the ‘Code:’ special comment.
		((let ((case-fold-search t))
		   (re-search-forward "^//+ *Code:$" openfoam-insert-data-file-header-limit t))
		 (unless (= (forward-line 1) 0)
		   (insert ?\n))
		 ;; Add an extra empty line.
		 (insert ?\n))
		;; Skip across initial comments, i.e. leave point at
		;; the beginning of the line after the last comment.
		((looking-at "/[/*]")
		 (openfoam-skip-forward)
		 (re-search-backward "[^[:blank:]\n]" nil t)
		 ;; The ‘forward-line’ function only returns non-zero
		 ;; if it can't move at all.
		 (end-of-line)
		 (unless (= (forward-line 1) 0)
		   (insert ?\n))
		 ;; Add an extra empty line.
		 (insert ?\n))
		;; Stay at beginning of file.
		(t))))
      (let ((start (point)))
	(insert "FoamFile\n"
		"{\n"
		"version 2.0;\n"
		"format ascii;\n"
		;; TODO: Attempt to infer the class from
		;; the file name or location.
		"class dictionary;\n"
		"object " (or file-name "unknown") ";\n"
		(if location
		    (concat "location \""
			    (openfoam-string-quote location)
			    "\";\n")
		  "")
		"}\n")
	(indent-region start (point)))
      ;; Restore point.
      (goto-char point)))
  ())

(defcustom openfoam-data-file-contents-alist ()
  "Alist of initial file contents for OpenFOAM data files.
List elements are cons cells of the form ‘(FILE-NAME . CONTENTS)’
where FILE-NAME is the relative file name in a case directory and
CONTENTS is the file contents."
  :type '(repeat (cons (string :tag "File name")
		       (string :tag "File contents")))
  :group 'openfoam)

(defun openfoam-add-to-data-file-contents-alist (file-name contents)
  "Add or update an element in ‘openfoam-data-file-contents-alist’.

First argument FILE-NAME is the relative file name in a case directory.
Second argument CONTENTS is the file contents."
  (let ((cell (assoc file-name openfoam-data-file-contents-alist #'openfoam-file-name-equal-p)))
    (if (not (null cell))
	(setcdr cell contents)
      (push (cons file-name contents) openfoam-data-file-contents-alist)))
  openfoam-data-file-contents-alist)

(put 'openfoam-add-to-data-file-contents-alist 'lisp-indent-function 1)

;;;###autoload
(defun openfoam-insert-dimension-set ()
  "Insert a dimension set at point.
Leave point before the opening ‘[’."
  (interactive)
  (save-excursion
    (insert "[0 0 0 0 0 0 0]")))

;;;; Case Directories

(defun openfoam-case-directory (file-name-or-directory)
  "Return the OpenFOAM case directory of FILE-NAME-OR-DIRECTORY, or nil."
  (let ((directory (file-name-directory file-name-or-directory)))
    (while (and directory (not (and (file-directory-p
				     (expand-file-name "constant" directory))
				    (file-directory-p
				     (expand-file-name "system" directory)))))
      (let ((up (file-name-directory (directory-file-name directory))))
	(setq directory (if (openfoam-file-name-equal-p up directory) nil up))))
    directory))

;;;###autoload
(defun openfoam-create-case-directory (directory)
  "Create an OpenFOAM case directory.

Argument DIRECTORY is the directory file name."
  (interactive "F")
  (let ((directory (file-name-as-directory directory)))
    (mkdir directory t)
    (cl-flet ((create-directory (name)
	        (let ((dir (expand-file-name name directory)))
		  (unless (file-directory-p dir)
		    (mkdir dir))))
	      (create-data-file (name)
	        (let ((file (expand-file-name name directory)))
		  (unless (file-exists-p file)
		    (with-temp-buffer
		      (set-visited-file-name file t)
		      (when-let ((contents (cdr (assoc name openfoam-data-file-contents-alist #'openfoam-file-name-equal-p))))
			(insert contents))
		      (goto-char (point-min))
		      (unless (re-search-forward "-\\*-" (save-excursion (end-of-line) (point)) t)
			(openfoam-apply-data-file-template))
		      (goto-char (point-min))
		      (openfoam-skip-forward)
		      (unless (looking-at "FoamFile\\>")
			(openfoam-insert-data-file-header))
		      (set-buffer-modified-p t)
		      (save-buffer 0))))))
      (create-directory "0")
      (create-directory "constant")
      (create-directory "constant/polyMesh")
      (create-directory "system")
      (create-data-file "system/controlDict")
      (create-data-file "system/fvSchemes")
      (create-data-file "system/fvSolution"))
    directory))

(defcustom openfoam-project-directory-alist ()
  "Alist of OpenFOAM project directories.
List elements are cons cells of the form ‘(KEY . DIRECTORY)’ where KEY
is a symbol or number and DIRECTORY is the associated OpenFOAM project
directory (a string).  See also ‘openfoam-default-project-directory’."
  :type '(alist :key-type (choice symbol number)
		:value-type directory)
  :group 'openfoam)

(defcustom openfoam-default-project-directory nil
  "The default OpenFOAM project directory.
Value is either a directory (a string) or the key for looking up a
project directory in ‘openfoam-project-directory-alist’."
  :type '(choice directory symbol number)
  :group 'openfoam)

(defun openfoam-default-project-directory (&optional must-match)
  "Return the default OpenFOAM project directory.
The project directory is looked up in the following order:

  1. The final value of ‘openfoam-default-project-directory’.
  2. The first element of ‘openfoam-project-directory-alist’.
  3. The value of the environment variable ‘WM_PROJECT_DIR’.

If optional argument MUST-MATCH is non-nil, only return an existing
directory.  Value is nil if no project directory can be found."
  (cl-flet ((p (object)
	      (and (stringp object)
		   (or (not must-match)
		       (file-directory-p object))
		   (file-name-as-directory object))))
    ;; The first match wins.
    (or (if (stringp openfoam-default-project-directory)
	    (p openfoam-default-project-directory)
	  (p (cdr (assoc openfoam-default-project-directory
			 openfoam-project-directory-alist #'eql))))
	(let (directory)
	  (dolist (cell openfoam-project-directory-alist)
	    (when-let ((found (and (null directory) (p (cdr cell)))))
	      (setq directory found)))
	  directory)
	(p (getenv "WM_PROJECT_DIR")))))

(defun openfoam-other-project-directory (file-name-or-directory &optional must-match no-keys)
  "Find an OpenFOAM project directory for FILE-NAME-OR-DIRECTORY.
The project directory is looked up in ‘openfoam-project-directory-alist’
in the following order:

  1. By comparing the project directory names without installation
     prefix.  Case is not significant.  For example, ‘~/openfoam-8’
     and ‘/opt/OpenFOAM-8’ are considered equal.
  2. By comparing the ‘openfoam-project-directory-alist’ keys with
     the version number part of the project.

If optional second argument MUST-MATCH is non-nil, only return an
existing directory.  If optional third argument NO-KEYS is non-nil,
omit the version number comparison.

Value is nil if no project directory can be found."
  (when openfoam-project-directory-alist
    (let ((project (file-name-nondirectory
		    (directory-file-name
		     file-name-or-directory)))
	  ;; The matching cons cell in ‘openfoam-project-directory-alist’.
	  (found nil))
      ;; Compare the project directory names.
      (dolist (cell openfoam-project-directory-alist)
	(when (and (not found)
		   (cl-equalp (file-name-nondirectory
			       (directory-file-name
				(cdr cell)))
			      project)
		   (or (not must-match)
		       (file-directory-p (cdr cell))))
	  (setq found cell)))
      ;; Try the version number only.
      (unless (or found no-keys)
	(let ((regexp (concat "[-_]"
			      (regexp-opt
			       (mapcar (lambda (cell)
					 (format "%s" (car cell)))
				       openfoam-project-directory-alist) t)
			      "\\'")))
	  (when (string-match regexp project)
	    (let ((val (ignore-errors
			 (read-from-string project (match-beginning 1)))))
	      (when (and val (= (cdr val) (length project)))
		(let* ((key (car val))
		       (cell (assoc key openfoam-project-directory-alist #'eql)))
		  (when (and cell (or (not must-match)
				      (file-directory-p (cdr cell))))
		    (setq found cell))))))))
      ;; Return value.
      (when found
	(file-name-as-directory (cdr found))))))

(defcustom openfoam-shell-save-project-directory 'ask
  "Whether or not to save the OpenFOAM project directory.
If non-nil, the ‘openfoam-shell’ command will save the selected OpenFOAM
project directory for a case directory in the file ‘.WM_PROJECT_DIR’ or
‘.OpenFOAM/WM_PROJECT_DIR’ for future use.  Special value ‘ask’ means
to ask the user before saving the project directory."
  :type '(choice (const :tag "Always" t)
		 (const :tag "Never" nil)
		 (const :tag "Ask" ask))
  :group 'openfoam)

(defun openfoam-shell-read-wm-project-dir (case-directory)
  "Read the OpenFOAM project directory for CASE-DIRECTORY."
  (when-let ((file-name (or (let ((file-name (expand-file-name
					      ".OpenFOAM/WM_PROJECT_DIR"
					      case-directory)))
			      (and (file-exists-p file-name) file-name))
			    (let ((file-name (expand-file-name
					      ".WM_PROJECT_DIR"
					      case-directory)))
			      (and (file-exists-p file-name) file-name)))))
    (with-temp-buffer
      (insert-file-contents file-name)
      (let* ((start (progn
		      (goto-char (point-min))
		      (if (looking-at "[ \t\n\r]+")
			  (match-end 0)
			(point))))
	     (end (progn
		    (goto-char (point-max))
		    (if (looking-back "[ \t\n\r]+" start t)
			(match-beginning 0)
		      (point)))))
	(when (< start end)
	  (buffer-substring-no-properties start end))))))

(defun openfoam-shell-write-wm-project-dir (case-directory project-directory)
  "Save the OpenFOAM project directory for CASE-DIRECTORY.
A newline character is appended to PROJECT-DIRECTORY."
  (let ((file-name (or (let ((file-name (expand-file-name
					 ".OpenFOAM/WM_PROJECT_DIR"
					 case-directory)))
			 (and (file-exists-p file-name) file-name))
		       (let ((file-name (expand-file-name
					 ".WM_PROJECT_DIR"
					 case-directory)))
			 (and (file-exists-p file-name) file-name))
		       ;; The file does not exist.  Create it in an
		       ;; existing directory.
		       (let ((dir (expand-file-name ".OpenFOAM" case-directory)))
			 (if (file-directory-p dir)
			     (expand-file-name "WM_PROJECT_DIR" dir)
			   (expand-file-name ".WM_PROJECT_DIR" case-directory))))))
    (with-temp-buffer
      (set-visited-file-name file-name t)
      (insert project-directory ?\n)
      (set-buffer-modified-p t)
      (save-buffer 0))
    (when-let ((buffer (get-file-buffer file-name)))
      (with-current-buffer buffer
	(revert-buffer t t t)))))

(defun openfoam-shell-wait-for-prompt ()
  "Wait for the shell prompt and leave point after it."
  (let* ((buffer (current-buffer))
	 (process (get-buffer-process buffer))
	 (last-output (process-mark process)))
    (save-excursion
      (goto-char last-output)
      ;; This is like ‘beginning-of-line’ but ignores
      ;; any text motion restrictions.
      (forward-line 0)
      (unless (looking-at shell-prompt-pattern)
	(accept-process-output process)))
    ;; Leave point after the shell prompt.
    (goto-char last-output)))

(defvar openfoam-shell-ignore-environment-regexp
  (regexp-opt '("OLDPWD" "PWD" "SHLVL" "_"))
  "Regular expression matching environment variables to be ignored.")

(defvar-local openfoam-shell ()
  "Local variable for the OpenFOAM shell.")

;;;###autoload
(defun openfoam-shell (case-directory project-directory)
  "Run a shell in CASE-DIRECTORY and initialize it for PROJECT-DIRECTORY.
With prefix argument, always ask the user to confirm the case directory
and project directory.

If the user option ‘openfoam-shell-save-project-directory’ is non-nil,
save the selected project directory inside the case directory so that
future invocations of ‘openfoam-shell’ can pick up the same project
directory again.

The inferior shell is invoked via the ‘shell’ command with the initial
working directory set to CASE-DIRECTORY.  After normal shell startup,
the OpenFOAM specific startup script ‘PROJECT-DIRECTORY/etc/bashrc’ or
‘PROJECT-DIRECTORY/etc/cshrc’ is read automatically.

The shell buffer has a name of the form ‘*PROJECT CASE-DIRECTORY*’ so
that you can run a separate shell for each case directory."
  (interactive
   (let (case-dir project-dir)
     ;; Attempt to determine the case directory.
     (setq case-dir (when-let ((file-name-or-directory
				(or buffer-file-name
				    default-directory)))
		      (openfoam-case-directory file-name-or-directory)))
     (when (or (null case-dir) current-prefix-arg)
       (setq case-dir (file-name-as-directory
		       (read-directory-name
			"OpenFOAM case directory: "
			(or case-dir
			    default-directory
			    (expand-file-name "~/"))
			nil t nil))))
     ;; Attempt to determine the project directory.
     (let ((saved-dir (when-let ((dir (openfoam-shell-read-wm-project-dir case-dir)))
			(file-name-as-directory dir))))
       ;; If SAVED-DIR is non-nil but does not exist, attempt to find
       ;; an alternative installation directory.  This may happen if a
       ;; project directory is moved or renamed or a case directory is
       ;; imported from another machine.
       (when (and saved-dir (not (file-directory-p saved-dir)))
	 (when-let ((other (openfoam-other-project-directory saved-dir t)))
	   ;; Replace SAVED-DIR.  TODO: Consider informing the user
	   ;; about the updated project directory.
	   (setq saved-dir other)))
       (if (or (null saved-dir) current-prefix-arg)
	   (progn
	     (setq project-dir (file-name-as-directory
				(read-directory-name
				 (format "OpenFOAM project directory for case directory ‘%s’: " case-dir)
				 (or saved-dir
				     (openfoam-default-project-directory t)
				     (expand-file-name "~/"))
				 nil t nil)))
	     (when (and (or (null saved-dir)
			    (not (openfoam-file-name-equal-p
				  project-dir saved-dir)))
			(if (eq openfoam-shell-save-project-directory 'ask)
			    (y-or-n-p "Save OpenFOAM project directory? ")
			  openfoam-shell-save-project-directory))
	       (openfoam-shell-write-wm-project-dir case-dir (directory-file-name project-dir))))
	 (setq project-dir saved-dir)))
     (list case-dir project-dir)))
  ;; Function body.
  (let* ((working-directory (file-name-as-directory
			     (or case-directory
				 default-directory
				 (expand-file-name "~"))))
	 (buffer-name (concat "*" (file-name-nondirectory
				   (directory-file-name
				    project-directory))
			      " " (directory-file-name
				   working-directory)
			      "*"))
	 (buffer (let ((default-directory working-directory))
		   (shell buffer-name))))
    (unless (local-variable-p 'openfoam-shell buffer)
      (with-current-buffer buffer
	(let ((cshp (or (string-equal shell--start-prog "csh")
			(string-equal shell--start-prog "tcsh"))))
	  ;; Load the OpenFOAM startup file.  This sets all the
	  ;; ‘FOAM_’ and ‘WM_’ environment variables and alters
	  ;; the program, library, and manual page search paths.
	  (let ((source (if cshp "source" "."))
		(startup (expand-file-name
			  (if cshp "etc/cshrc" "etc/bashrc")
			  project-directory)))
	    (when (file-readable-p startup)
	      (openfoam-shell-wait-for-prompt)
	      (insert source ?\s (comint-quote-filename startup))
	      (comint-send-input nil t)))
	  ;; Propagate the environment from the shell to Emacs so that
	  ;; environment variable completion works as expected.
	  (openfoam-shell-wait-for-prompt)
	  (let ((start (point))
		(end (progn
		       ;; TODO: Consider using the --zero option to
		       ;; cover the rare case of newline characters
		       ;; in values.
		       (insert "printenv")
		       (comint-send-input nil t)
		       (openfoam-shell-wait-for-prompt)
		       (point))))
	    (setq-local process-environment ())
	    (save-excursion
	      (goto-char start)
	      (forward-line 1)
	      (let ((ignore (concat "\\`" openfoam-shell-ignore-environment-regexp "="))
		    (case-fold-search nil))
		(while (re-search-forward "^[0-9A-Z_a-z]+=.*" nil t)
		  (let ((str (match-string-no-properties 0)))
		    (unless (string-match ignore str)
		      (push str process-environment))))))
	    ;; Kill output generated by ‘printenv’.
	    (comint-kill-region start end)
	    ;; Display beginning of buffer.
	    (recenter nil t))
	  ;; Propagate the program search path from the shell to Emacs
	  ;; so that command completion works as expected.
	  (let ((path (getenv "PATH"))
		(sep (regexp-quote path-separator)))
	    ;; Append ‘exec-directory’ to the program search path.
	    ;; This is an Emacs convention and comint mode expects
	    ;; it to be there.
	    (setq-local exec-path (nconc (split-string path sep t)
					 (list exec-directory))))
	  ;; Mark as initialized.
	  (setq openfoam-shell nil)
	  ())))))

(provide 'openfoam)


;; local variables:
;; byte-compile-warnings: (not make-local)
;; end:

;;; openfoam.el ends here
