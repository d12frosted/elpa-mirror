;;; gf.el --- Major mode for editing GF code -*-coding: utf-8;-*-

;; Copyright (C) 2005, 2006, 2007  Johan Bockgård
;; Time-stamp: <2007-06-16 11:57:48 bojohan>

;; Author: Johan Bockgård <bojohan+mail@dd.chalmers.se>
;; Maintainer: bruno cuconato <bcclaro+emacs@gmail.com>
;; URL: https://github.com/GrammaticalFramework/gf-emacs-mode
;; Package-Version: 20181028.1542
;; Package-Commit: 30b3127f229e0db522c7752f6957ca01b2ea2821
;; Version: 1.1.2
;; Package-Requires: ((s "1.0") (ht "2.0"))
;; Keywords: languages

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Major mode for editing GF code, with support for running a GF
;; shell.

;;; History:

;; 2006-10-30:
;;   	 let a = b
;;   	     c = d ...
;;   	 in ...
;;   indentation now works (most of the time).

;;; Code:

(require 'ht)
(require 's)
(require 'comint)
(require 'pcomplete)

(defgroup gf nil
  "Support for GF (Grammatical Framework)"
  :group 'languages
  :link  '(url-link "http://grammaticalframework.org/"))

(defvar gf-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-l")  'gf-load-file)
    (define-key map (kbd "C-c C-b")  'gf-display-inf-buffer)
    (define-key map (kbd "C-c C-.") 'gf-doc-display)
    (define-key map (kbd "C-c C-s")  'gf-run-inf-shell)
    (define-key map (kbd "DEL") 'backward-delete-char-untabify)
    map)
  "Keymap for `gf-mode'.")

;; Taken from haskell-mode
(defvar gf-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\   " "  table)
    (modify-syntax-entry ?\t  " "  table)
    (modify-syntax-entry ?\"  "\"" table)
    (modify-syntax-entry ?\'  "\'" table)
    (modify-syntax-entry ?_   "w"  table)
    (modify-syntax-entry ?\(  "()" table)
    (modify-syntax-entry ?\)  ")(" table)
    (modify-syntax-entry ?\[  "(]" table)
    (modify-syntax-entry ?\]  ")[" table)

    (cond ((featurep 'xemacs)
	   ;; I don't know whether this is equivalent to the below
	   ;; (modulo nesting).  -- fx
	   (modify-syntax-entry ?{  "(}5" table)
	   (modify-syntax-entry ?}  "){8" table)
	   (modify-syntax-entry ?-  "_ 1267" table))
	  (t
	   ;; The following get comment syntax right, similarly to C++
	   ;; In Emacs 21, the `n' indicates that they nest.
	   ;; The `b' annotation is actually ignored because it's only
	   ;; meaningful on the second char of a comment-starter, so
	   ;; on Emacs 20 and before we get wrong results.  --Stef
	   (modify-syntax-entry ?\{  "(}1nb" table)
	   (modify-syntax-entry ?\}  "){4nb" table)
	   (modify-syntax-entry ?-  "_ 123" table)))
    (modify-syntax-entry ?\n ">" table)

    (let (i lim)
      (map-char-table
       (lambda (k v)
	 (when (equal v '(1))
	   ;; The current Emacs 22 codebase can pass either a char
	   ;; or a char range.
	   (if (consp k)
	       (setq i (car k)
		     lim (cdr k))
	     (setq i k
		   lim k))
	   (while (<= i lim)
	     (when (> i 127)
	       (modify-syntax-entry i "_" table))
	     (setq i (1+ i)))))
       (standard-syntax-table)))

    (modify-syntax-entry ?\` "$`" table)
    (modify-syntax-entry ?\\ "\\" table)
    (mapc (lambda (x)
	      (modify-syntax-entry x "_" table))
	    ;; Some of these are actually OK by default.
	    "!#$%&*+./:=?@^|~")
    (unless (featurep 'mule)
      ;; Non-ASCII syntax should be OK, at least in Emacs.
      (mapc (lambda (x)
		(modify-syntax-entry x "_" table))
	      (concat "¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿"
		      "×÷"))
      (mapc (lambda (x)
		(modify-syntax-entry x "w" table))
	      (concat "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ"
		      "ØÙÚÛÜÝÞß"
		      "àáâãäåæçèéêëìíîïðñòóôõö"
		      "øùúûüýþÿ")))
    table)
  "Syntax table used in GF mode.")

;; Lin         PType     Str        Strs       Tok        Type
;; abstract    case      cat        concrete   data       def
;; flags       fn        fun        grammar    in         include
;; incomplete  instance  interface  let        lin        lincat
;; lindef      lintype   of         open       oper       out
;; package     param     pattern    pre        printname  resource
;; reuse       strs      table      tokenizer  transfer   union
;; var         variants  where      with
;;   ; = { } ( ) : -> ** , [ ] - . | % ? < > @ ! * \ => ++ + _ $ /

;; Judgements
(defvar gf--top-level-keywords
  '("cat" "fun" "lincat" "lintype" "lin" "pattern"
    "oper" "def" "param" "flags" "linref" "lindef" "printname"
    "data" "transfer"))

(defvar gf--module-keywords
  '("abstract" "concrete" "resource" "instance" "interface" "incomplete"))

(defvar gf--keywords
  (append '("of" "let" "include" "open" "in" "where"
	    "with" "case" "incomplete" "table"
	    "variants" "pre" "strs" "overload")
	  gf--top-level-keywords
	  gf--module-keywords))

(defvar gf--top-level-keyword-regexp
  (regexp-opt gf--top-level-keywords 'words))

(defvar gf--keyword-regexp
  (regexp-opt gf--keywords 'words))

(defvar gf--identifier-regexp
  "[[:alpha:]][[:alnum:]'_]*"
  "Regexp for GF identifiers.")

(defvar gf--font-lock-keywords
  (let ((sym "\\(\\s_\\|\\\\\\)+")
	;; (keyw gf--keyword-regexp)
	(mod (concat (regexp-opt gf--module-keywords 'words)
		     "\\s-\\(\\w+\\)"))
	(pface '(if (boundp 'font-lock-preprocessor-face)
		    font-lock-preprocessor-face
		  font-lock-builtin-face)))
    `(;; Module
      (,mod (1 font-lock-keyword-face)
	    (2 font-lock-type-face))
      ;; Keywords
      (,(lambda (end)
	  (let (parse-sexp-lookup-properties)
	    (re-search-forward gf--keyword-regexp end t)))
       . font-lock-keyword-face)
      ;; Operators
      (,sym  . font-lock-variable-name-face)
      ;; Pragmas
      ("^--\\(#.*\\)" (1 ,pface prepend))
      ("--\\(#\\s-*\\(notpresent\\|prob\\).*\\)" (1 ,pface prepend))
      ;; GFDoc
      ("^--[0-9]+\\s-*\\(.*\\)" (1 'underline prepend))
      ("^--\\([*!.]\\)"         (1 'underline prepend))
      (,(lambda (end)
	  (let (found)
	    (while
		(and (setq found (re-search-forward
				  "\\$.*?\\$"
				  end t))
		     (not (eq (get-text-property (match-beginning 0) 'face)
			      'font-lock-comment-face))))
	    found))
       (0 (if (face-italic-p 'font-lock-comment-face)
	      '((:slant normal))
	    '((:slant italic)))
	  prepend))))
  "Keyword highlighting specification for `gf-mode'.")

(defcustom gf-let-brace-style t
  "The let...in style to use for indentaton.

A value of t means unbraced (new) style:


     let x = a;
         y = b; in ...

A value of nil means braced (old) style

     let { x = a;
           y = b; } in ...

Anything else means try to guess."
  :type '(choice (const :tag "Unbraced"  t)
		 (const :tag "Braced"    nil)
		 (const :tag "Heuristic" 'heuristic))
  :group 'gf)

;; let x = let a = f;
;;             b = g;
;;       in b;
;;     y = d;
;;   in h
(defun gf--match-let-in (let/in end)
  "Indentation rule for let-in form.
LET/IN is which keyword to search for ('let or 'in), and END is the bound for the search."
  (when gf-let-brace-style
    (if (eq 'let let/in)
	(and (re-search-forward "\\<le\\(t\\)\\>" end t)
	     (or (eq t gf-let-brace-style)
		 (save-excursion
		   (skip-syntax-forward " ")
		   (not (eq ?\{ (char-after))))))
      (and (re-search-forward "\\<\\(i\\)n\\>" end t)
	   (or (eq t gf-let-brace-style)
	       (save-excursion
		 (backward-char 2)
		 (skip-syntax-backward " ")
		 (not (eq ?\} (char-before)))))))))

(defvar gf--font-lock-syntactic-keywords
  `(;; let ...
    (,(lambda (end) (gf--match-let-in 'let end))
     1 "(")
    ;; ... in
    (,(lambda (end) (gf--match-let-in 'in end))
     1 ")")))

(defcustom gf-show-type-annotations t
  "GF-mode will show the types of opers and lins if value is t."
  :type 'boolean
  :group 'gf)

;;;###autoload
(define-derived-mode gf-mode prog-mode "GF"
  "A major mode for editing GF files."
  ;; change it all to setq-local?
  (set (make-local-variable 'comment-start) "-- ")
  (set (make-local-variable 'comment-start-skip) "[-{]-[ \t]*")
  (set (make-local-variable 'font-lock-defaults)
       '(gf--font-lock-keywords
	 nil nil nil nil
	 (font-lock-syntactic-keywords . gf--font-lock-syntactic-keywords)))
  (set (make-local-variable 'indent-line-function) 'gf-indent-line)
  (set (make-local-variable 'beginning-of-defun-function)
       'gf--beginning-of-section)
  (set (make-local-variable 'end-of-defun-function)
       'gf--end-of-section))

;;; Documentation
(defvar gf--oper-docs-ht
  nil
  "Hashtable whose keys are oper names and values are oper types.")

(defun gf-doc-display ()
  "Display the type declaration of the oper/lin at point.
The function uses the GF shell command show_operations
internally, so its output should be no different from theirs.
The command is called once and then cached.  It is rerun every
time you open or save a GF file."
  (interactive)
  (if gf--oper-docs-ht
      (let ((identifier (symbol-at-point)))
        (when (and gf-show-type-annotations
                   identifier ; whitespace?
                   (setq identifier (symbol-name identifier)) ; sym -> str
                   (string-match gf--identifier-regexp identifier) ; GF identifier?
                   (not (gf--in-comment-p)) ; not comment?
                   (not (string-match gf--keyword-regexp identifier))) ; not keyword?
          (message "%s"
                   (s-collapse-whitespace
                    (or (ht-get gf--oper-docs-ht identifier nil)
                        "Identifier is not a known oper/lin. (Try saving the module if you made changes. If that doesn't work, check if the module is imported without errors.)")))))
    (progn (when (and gf-show-type-annotations gf--oper-docs-ht)
             (add-hook 'after-save-hook 'gf--get-opers-docs nil t))
           (gf--get-opers-docs)
           (gf-doc-display))))

(defun gf--get-opers-docs ()
  "Build hashtable with oper names as keys and oper type declarations as values.
Uses GF show_operations command internally, parses output, and builds hashtable."
  (let* ((command (format "echo -e 'i -retain %s\nshow_operations' | gf --run" buffer-file-name))
         (output-str (shell-command-to-string command))
         (h (gf--parse-show-opers-to-ht output-str)))
    (setq gf--oper-docs-ht h)))

(defun gf--parse-show-opers-to-ht (str)
  "Parse show_operations GF shell command to hashtable.
STR is the output string from the command."
  (let (curr-oper
        (ls (s-slice-at (format "^%s : " gf--identifier-regexp) str))
        (h (ht-create #'equal))
        (add-to-ht (lambda (h v)
                     (ht-set! h
                              (car (s-match gf--identifier-regexp v))
                              v))))
    (dolist (l ls h)
      (funcall add-to-ht h l))))

;;; Indentation
(defcustom gf-indent-basic-offset 2
  "Number of columns to indent in GF mode."
  :type 'integer
  :group 'gf)

(defcustom gf-indent-judgment-offset 2
  "Column where judement should be indented to."
  :type 'integer
  :group 'gf)

(defun gf-indent-line ()
  "Indent current line of GF code."
  (interactive)
  (save-excursion
    (font-lock-fontify-syntactic-keywords-region
     (point-at-bol) (point-at-bol)))
  (let* ((case-fold-search nil)
	 (parse-sexp-lookup-properties t)
	 (parse-sexp-ignore-comments t)
	 (savep (> (current-column) (current-indentation)))
	 (indent (condition-case err
		     (max (gf--calculate-indentation) 0)
		   (error (message "%s" err) 0))))
    (if savep
	(save-excursion (indent-line-to indent))
      (indent-line-to indent))))

(defun gf--beginning-of-section ()
  "Move to the beginning of section, and return point.
Section begins at top-level declaration (cat, fun, lin, etc)."
  (when (re-search-backward
	 (concat "^\\s-*" gf--top-level-keyword-regexp)
	 nil 'move)
    (goto-char (match-beginning 0)))
  (point))

(defun gf--end-of-section ()
  "Move point to end of section, and return point.
Section ends at top-level declaration (cat, fun, lin, etc) or eof."
  ;; [ ] function doesn't seem to be doing what it should
  (gf--forward-comment)
  (when (looking-at gf--top-level-keyword-regexp)
    (goto-char (match-end 0)))
  (when (re-search-forward
	 (concat "^\\s-*" gf--top-level-keyword-regexp)
	 (condition-case nil
	     (1- (scan-lists (point) 1 1))
	   (error nil))
	 'move)
    (goto-char (match-beginning 0)))
  (gf--backward-comment)
  (point))

(defun gf--beginning-of-sequence (&optional keep-going limit)
  (or limit (let ((com-start (gf--in-comment-p)))
	      (when com-start
		(save-excursion
		  (goto-char com-start)
		  (skip-chars-forward "{")
		  (skip-chars-forward "-")
		  (setq limit (point))))))
  (let* ((str "[;]")
	 (found-it nil)
	 (pps   (gf--ppss))
	 (depth (or (nth 0 pps) 0))
	 (bol   (point-at-bol))
	 (lim   (max (or limit (point-min))
		     (if (nth 1 pps)
			 (1+ (nth 1 pps))
		       (save-excursion
			 (gf--beginning-of-section)
			 (when (looking-at
				(concat "\\s-*" gf--top-level-keyword-regexp))
			   (goto-char (match-end 0))
			   (gf--forward-comment))
			 (point))))))
    (while (and (> (point) lim)
		(setq found-it (re-search-backward str lim 'move))
		(let ((pps (gf--ppss)))
		  (or (/= depth (nth 0 pps))
		      (nth 3 pps)
		      (nth 4 pps)))))
    (when found-it
      (when keep-going
	(setq lim (max lim bol))
	(while (and (> (point) lim)
		    (setq found-it (re-search-backward str lim 'move))
		    ;;(/= depth (nth 0 (gf--ppss)))
		    )))
      (when found-it (forward-char)))))

(defun gf--in-comment-p ()
  "Return non-nil if point is at comment."
  (let ((pps (gf--ppss)))
    (and (nth 4 pps) (nth 8 pps))))

(defun gf--forward-comment ()
  "Move past comment."
  ;; [ ] doesn't seem to work
  (forward-comment (buffer-size)))

(defun gf--backward-comment ()
  "Move back to previous comment."
  ;; [ ] idem
  (forward-comment (- (buffer-size))))

(defun gf--ppss ()
  (parse-partial-sexp
   (save-excursion (gf--beginning-of-section))
   (point)))


(if (fboundp 'syntax-after)
    (defalias 'gf--syntax-after 'syntax-after)
  (defun gf--syntax-after (pos)
    "Return the raw syntax of the char after POS.
If POS is outside the buffer's accessible portion, return nil."
    (unless (or (< pos (point-min)) (>= pos (point-max)))
      (let ((st (if parse-sexp-lookup-properties
		    (get-char-property pos 'syntax-table))))
	(if (consp st) st
	  (aref (or st (syntax-table)) (char-after pos)))))))

(if (fboundp 'syntax-class)
    (defalias 'gf--syntax-class 'syntax-class)
  (defun gf--syntax-class (syntax)
    "Return the syntax class part of the syntax descriptor SYNTAX.
If SYNTAX is nil, return nil."
    (and syntax (logand (car syntax) 65535))))

(defun gf--calculate-indentation ()
  "Return the column to which the current line should be indented."
  (save-excursion
    (forward-line 0)
    (skip-chars-forward " \t")
    (cond
     ;; judgement
     ((looking-at gf--top-level-keyword-regexp)
      gf-indent-judgment-offset)
     ((and gf-let-brace-style
	   (looking-at "in\\>"))
      (if (condition-case nil
	      (progn (backward-up-list)
		     nil)
	    (error t))
	  gf-indent-basic-offset
	(gf--beginning-of-sequence)
	(if (= (point) (point-min))
	    0
	  (gf--forward-comment)
	  (+ gf-indent-basic-offset (current-column)))))
     ((looking-at "[]})]")
      (backward-up-list)
      (gf--beginning-of-sequence)
      (if (= (point) (point-min))
	  0
	(gf--forward-comment)
	(+ gf-indent-basic-offset (current-column))))
     ;; heading
     ((looking-at "---")
      (gf--beginning-of-sequence)
      (if (= (point) (point-min))
	  0
	gf-indent-judgment-offset))
     (t
      (let ((opoint (point)))
	(gf--backward-comment)
	(cond
	  ((eq  ?\; (char-before))
	   ;; ?\,
	   (backward-char)
	   (gf--beginning-of-sequence t)
	   (gf--forward-comment)
	   (current-column))
	  ((eq 4 (gf--syntax-class (gf--syntax-after (1- (point)))))
	   (backward-char)
	   ;; alt. (gf--beginning-of-sequence nil nil)
	   (gf--beginning-of-sequence nil (point-at-bol))
	   (gf--forward-comment)
	   ;; alt. (+ (* 2 gf-indent-basic-offset) (current-column)))
	   (+ gf-indent-basic-offset (current-column)))
	  (t
	   (gf--beginning-of-sequence)
	   (let ((head (= (point) (point-min))))
	     (gf--forward-comment)
	     (cond
	      ((> opoint (point)) (+ gf-indent-basic-offset (current-column)))
	      ;; i.e. opoint == (point)
	      (head 0)
	      (t    (gf--beginning-of-section)
		    (skip-chars-forward " \t")
		    (+ gf-indent-basic-offset (current-column))))))))))))

;;;
;; Inferior GF Mode
(defcustom gf-program-name "gf"
  "Name of GF shell invoked by `gf-run-inf-shell'."
  :type 'file
  :group 'gf)

(defcustom gf-program-args
  nil
  "Arguments passed to GF by `gf-run-inf-shell'."
  :group 'gf)

(defcustom gf-process-buffer-name
  "*gf*"
  "Name of buffer where inferior GF shell is run."
  :group 'gf)

(defvar gf--process)

(defun gf-load-file ()
  "Load current file in GF shell."
  (interactive)
  (save-buffer)
  (gf-start)
  (comint-send-string gf--process (format "import %s\n" buffer-file-name))
  (gf--clear-lang-cache)
  (gf-display-inf-buffer))

(defun gf-display-inf-buffer ()
  "Display inferior GF buffer."
  (interactive)
  (and (get-buffer gf-process-buffer-name)
       (display-buffer gf-process-buffer-name)))

(define-derived-mode inf-gf-mode comint-mode "Inf-GF"
  (gf--setup-pcomplete))

(define-key inf-gf-mode-map "\t" 'gf-complete)

;;;###autoload
(defun gf-run-inf-shell ()
  "Run an inferior GF process."
  (interactive)
  (gf-start)
  (pop-to-buffer gf-process-buffer-name))

(defun gf-start ()
  "Start GF process if not already up."
  (unless (comint-check-proc gf-process-buffer-name)
    (with-current-buffer
	(apply 'make-comint-in-buffer
	       "gf" gf-process-buffer-name gf-program-name
	       nil gf-program-args)
      (setq gf--process (get-buffer-process (current-buffer)))
      (set-buffer-process-coding-system 'utf-8-unix 'utf-8-unix)
      (inf-gf-mode))))

(put 'pcomplete-here 'edebug-form-spec t)

(defun gf--setup-pcomplete ()
  (set (make-local-variable 'comint-prompt-regexp) "^[^>\n]*> *")
  (set (make-local-variable 'pcomplete-ignore-case) nil)
  (set (make-local-variable 'pcomplete-use-paring)  t)
  (set (make-local-variable 'pcomplete-suffix-list) '(?/ ?=))
  (set (make-local-variable 'pcomplete-parse-arguments-function)
       'gf--parse-arguments)
  (set (make-local-variable 'pcomplete-command-completion-function)
       'gf--complete-command)
  (set (make-local-variable 'pcomplete-default-completion-function)
       'gf--default-completion-function)
  (add-hook 'comint-input-filter-functions
	    'gf--watch-for-loading
	    nil t))

(defun gf--watch-for-loading (string)
  (when (string-match (concat "\\(\\`\\||\\;;\\)\\s-*"
			      (regexp-opt '("i" "e" "rl") 'words))
		      string)
    (gf--clear-lang-cache)))

(defun gf--parse-arguments ()
  "Parse whitespace separated arguments in the current region."
  (let ((begin (save-excursion
		 (if (re-search-backward "|\\|;;" (point-at-bol) t)
		     (match-end 0)
		   (comint-bol nil)
		   (point))))
	(end (point))
	begins args)
    (save-excursion
      (goto-char begin)
      (while (< (point) end)
	(skip-chars-forward " \t\n")
	(setq begins (cons (point) begins))
	(let ((skip t))
	  (while skip
	    (skip-chars-forward "^ \t\n")
	    (if (eq (char-before) ?\\)
		(skip-chars-forward " \t\n")
	      (setq skip nil))))
	(setq args (cons (buffer-substring-no-properties
			  (car begins) (point))
			 args)))
      (cons (reverse args) (reverse begins)))))

(defun gf-complete ()
  "TAB complete GF command."
  (interactive)
  (pcomplete))

(defun gf--default-completion-function ()
  (pcomplete-here (pcomplete-entries)))

(defun gf--complete-command ()
  (pcomplete-here (gf--complete-commands)))

(defun gf--complete-commands () gf--short-command-names)

(defvar gf--short-command-names
  '("!" "?" "ai" "aw" "ca" "cc" "dc" "dg" "dt" "e" "eb" "eh" "gr" "gt" "h" "i" "l" "lc" "ma" "mq" "p" "pg" "ph" "ps" "pt" "q" "r" "rf" "rt" "sd" "se" "so" "sp" "ss" "tq" "tt" "ut" "vd" "vp" "vt"))

(defvar gf--long-command-names
  '("system_command" "system_pipe" "abstract_info" "align_words" "clitic_analyse" "compute_concrete" "define_command" "dependency_graph" "define_tree" "empty" "example_based" "execute_history" "generate_random" "generate_trees" "help" "import" "linearize" "linearize_chunks" "morpho_analyse" "morpho_quiz" "parse" "print_grammar" "print_history" "put_string" "put_tree" "quit" "reload" "read_file" "rank_trees" "show_dependencies" "set_encoding" "show_operations" "system_pipe" "show_source" "translation_quiz" "to_trie" "unicode_table" "visualize_dependency" "visualize_parse" "visualize_tree" "write_file"))

(defun gf--complete-options (options flags &optional flags-extra-table
				    extra-completions)
  (let ((-options (mapcar (lambda (s) (concat "-" s)) options))
	(-flags= (mapcar (lambda (s) (concat "-" s "=")) flags)))
    ;; do-while
    (while (progn
	     (cond
	      ((pcomplete-match "\\`-\\(\\w+\\)=\\(.*\\)" 0)
	       (pcomplete-here
		(let ((opt (cdr (assoc (car (member
					     (pcomplete-match-string 1 0)
					     flags))
				       (append flags-extra-table
					       gf--flags-table)))))
		  (if (functionp opt)
		      (funcall opt)
		    opt))
		(pcomplete-match-string 2 0)))
	      (t (pcomplete-here
		  (append
		   (if (functionp extra-completions)
		       (funcall extra-completions)
		     extra-completions)
		   -options -flags=))))
	     (pcomplete-match "\\`-" 1)))))

(defun gf--collect-results (command process function)
  "Run COMMAND through PROCESS and apply FUNCTION to output buffer.
Point is after command (if echoed), or at beginning of buffer."
  (let ((output-buffer "*gf-tmp*")
	results)
    (save-excursion
      (set-buffer (get-buffer-create output-buffer))
      (erase-buffer)
      (comint-redirect-send-command-to-process
       command output-buffer process nil t)
      ;; Wait for the process to complete
      (set-buffer (process-buffer process))
      (while (null comint-redirect-completed)
	(accept-process-output nil 1))
      ;; Collect the output
      (set-buffer output-buffer)
      (goto-char (point-min))
      ;; Skip past the command, if it was echoed
      (and (looking-at command) (forward-line))
      (funcall function))))

;;
;; Command Completion

;; note: pcomplete demands this naming scheme.
(defun pcomplete/inf-gf-mode/ai ())

(defun pcomplete/inf-gf-mode/aw ()
  (gf--complete-options
   '("giza")
   '("format" "lang" "view")))

(defun pcomplete/inf-gf-mode/ca ()
  (gf--complete-options
   '("raw")
   '("clitics" "lang")))

(defun pcomplete/inf-gf-mode/cc ()
  (gf--complete-options
   '("all" "list" "one" "table" "unqual" "trace")
   '())
  (throw 'pcompleted nil))

(defun pcomplete/inf-gf-mode/dc ())

(defun pcomplete/inf-gf-mode/dg ()
  (gf--complete-options '() '("only")))

(defun pcomplete/inf-gf-mode/dt ())

(defun pcomplete/inf-gf-mode/e ())

(defun pcomplete/inf-gf-mode/eb ()
  (gf--complete-options '("api") '("file" "lang" "probs")))

(defun pcomplete/inf-gf-mode/eh ()
  (pcomplete-here (pcomplete-entries)))

(defun pcomplete/inf-gf-mode/gr ()
  (gf--complete-options '() '("cat" "lang" "number" "depth" "probs"))
  (throw 'pcompleted nil))

(defun pcomplete/inf-gf-mode/gt ()
  (gf--complete-options '() '("cat" "depth" "lang" "number")))

(defun pcomplete/inf-gf-mode/h ()
  (gf--complete-options '("changes" "coding" "full" "license" "t2t") '()))

(defun pcomplete/inf-gf-mode/i ()
  (gf--complete-options
   '("v" "src" "retain")
   '("probs")
   nil
   #'pcomplete--entries))

(defun pcomplete/inf-gf-mode/l ()
  (gf--complete-options
   '("all" "bracket" "groups" "list" "multi" "table" "tabtreebank" "treebank" "bind" "chars" "from_amharic" "from_ancientgreek" "from_arabic" "from_cp1251" "from_devanagari" "from_greek" "from_hebrew" "from_nepali" "from_persian" "from_sanskrit" "from_sindhi" "from_telugu" "from_thai" "from_urdu" "from_utf8" "lexcode" "lexgreek" "lexgreek2" "lexmixed" "lextext" "to_amharic" "to_ancientgreek" "to_arabic" "to_cp1251" "to_devanagari" "to_greek" "to_hebrew" "to_html" "to_nepali" "to_persian" "to_sanskrit" "to_sindhi" "to_telugu" "to_thai" "to_urdu" "to_utf8" "unchars" "unlexcode" "unlexgreek" "unlexmixed" "unlextext" "unwords" "words" )
   '("lang" "unlexer"))
  (throw 'pcompleted nil))

(defun pcomplete/inf-gf-mode/lc ()
  (gf--complete-options '("treebank" "bind" "chars" "from_amharic" "from_ancientgreek" "from_arabic" "from_cp1251" "from_devanagari" "from_greek" "from_hebrew" "from_nepali" "from_persian" "from_sanskrit" "from_sindhi" "from_telugu" "from_thai" "from_urdu" "from_utf8" "lexcode" "lexgreek" "lexgreek2" "lexmixed" "lextext" "to_amharic" "to_ancientgreek" "to_arabic" "to_cp1251" "to_devanagari" "to_greek" "to_hebrew" "to_html" "to_nepali" "to_persian" "to_sanskrit" "to_sindhi" "to_telugu" "to_thai" "to_urdu" "to_utf8" "unchars" "unlexcode" "unlexgreek" "unlexmixed" "unlextext" "unwords" "words") '("lang")))

(defun pcomplete/inf-gf-mode/ma ()
  (gf--complete-options '("known" "missing") '("lang")))

(defun pcomplete/inf-gf-mode/mq ()
  (gf--complete-options '() '("lang" "cat" "number" "probs")))

(defun pcomplete/inf-gf-mode/p ()
  (gf--complete-options
   '("bracket")
   '("cat" "lang" "openclass" "depth"))
  (throw 'pcompleted nil))

(defun pcomplete/inf-gf-mode/pg ()
  (gf--complete-options
   '("cats" "fullform" "funs" "langs" "lexc" "missing" "opt" "pgf" "words")
   '("file" "lang" "printer")))

(defun pcomplete/inf-gf-mode/ph ())

(defun pcomplete/inf-gf-mode/ps ()
  (gf--complete-options
   '("lines" "bind" "chars" "from_amharic" "from_ancientgreek" "from_arabic" "from_cp1251" "from_devanagari" "from_greek" "from_hebrew" "from_nepali" "from_persian" "from_sanskrit" "from_sindhi" "from_telugu" "from_thai" "from_urdu" "from_utf8" "lexcode" "lexgreek" "lexgreek2" "lexmixed" "lextext" "to_amharic" "to_ancientgreek" "to_arabic" "to_cp1251" "to_devanagari" "to_greek" "to_hebrew" "to_html" "to_nepali" "to_persian" "to_sanskrit" "to_sindhi" "to_telugu" "to_thai" "to_urdu" "to_utf8" "unchars" "unlexcode" "unlexgreek" "unlexmixed" "unlextext" "unwords")
   '("env" "from" "to")))

(defun pcomplete/inf-gf-mode/pt ()
  (gf--complete-options
   '("compute" "largest" "nub" "smallest" "subtrees" "funs") '
   ("number")))

(defun pcomplete/inf-gf-mode/q ())

(defun pcomplete/inf-gf-mode/r ())

(defun pcomplete/inf-gf-mode/rf ()
  (gf--complete-options '("lines" "tree") '("file") nil #'pcomplete-entries))

(defun pcomplete/inf-gf-mode/rt ()
  (gf--complete-options '("v") '("probs") nil))

(defun pcomplete/inf-gf-mode/sd ()
  (gf--complete-options '("size") '() nil #'pcomplete-entries))

(defun pcomplete/inf-gf-mode/se ())

(defun pcomplete/inf-gf-mode/so ()
  (gf--complete-options '("raw")
                        '("grep"))
  (throw 'pcompleted nil))

(defun pcomplete/inf-gf-mode/sp ()
  (gf--complete-options '() '("command")))

(defun pcomplete/inf-gf-mode/ss ()
  (gf--complete-options '("detailedsize" "save" "size" "strip" )
                        '()
  (throw 'pcompleted nil)))

(defun pcomplete/inf-gf-mode/tq ()
  (gf--complete-options '() '("from" "to" "cat" "number" "probs"))
  (pcomplete-here (gf--complete-lang))
  (pcomplete-here (gf--complete-lang)))

(defun pcomplete/inf-gf-mode/tt ()
  (gf--complete-options '() '())
  (throw 'pcompleted nil))

(defun pcomplete/inf-gf-mode/ut ()
  (gf--complete-options
   '("amharic" "ancientgreek" "arabic" "devanagari" "greek" "hebrew" "nepali" "persian" "sanskrit" "sindhi" "telugu" "thai")
   '()))

(defun pcomplete/inf-gf-mode/vd ()
  (gf--complete-options '("v" "conll2latex") '("abslabels" "cnclabels" "file" "format" "output" "view" "lang" )))

(defun pcomplete/inf-gf-mode/vp ()
  (gf--complete-options
   '("showcat" "nocat" "showdep" "showfun" "nofun" "showleaves" "noleaves")
   '("lang" "file" "format" "view" "nodefont" "leaffont" "nodecolor" "leafcolor" "nodeedgestyle" "leafedgestyle")))

(defun pcomplete/inf-gf-mode/vt ()
  (gf--complete-options '("api" "mk" "nofun" "nocat") '("format" "view")))

(defun pcomplete/inf-gf-mode/wf ()
  (gf--complete-options '("append") '("file")
                        nil
                        (pcomplete-entries)))

;; -- Flags. The availability of flags is defined separately for each command.
(defvar gf--flag-filter-options
  '("identity" "erase" "take100" "length" "text" "code"))

;; -lang, grammar used when executing a grammar-dependent command.
;;        The default is the last-imported grammar.

(defvar gf--lang-cache
  'empty)

(defun gf--clear-lang-cache ()
  (setq gf--lang-cache 'empty))

(defvar gf--flag-lang-options
  'gf--complete-lang)

(defun gf--complete-lang ()
  (if (listp gf--lang-cache)
      gf--lang-cache
    (setq gf--lang-cache
	  (gf--collect-results
	   "pl" gf--process
	   (lambda ()
	     ;; we're at point-min
	     (let (result)
	       (while (re-search-forward "\\S-+" (point-at-eol) t)
		 (push (match-string 0) result))
	       result))))))

(defvar gf--flag-lexer-options
  '("words" "literals" "vars" "chars" "code" "codevars"
    "text" "codelit" "textlit" "codeC"))

(defvar gf--flag-optimize-options
  '("share" "parametrize" "values" "all" "none"))

;; [] pretty sure this doesn't exist anymore
(defvar gf--flag-parser-options
  '("chart" "bottomup" "topdown" "old"))

(defvar gf--flag-printer-options
  '("bnf" "ebnf" "fa" "gsl" "haskell" "java" "js" "jsgf" "pgf_pretty" "prolog" "python" "regexp" "slf" "srgs_abnf" "srgs_abnf_nonrec" "srgs_xml" "srgs_xml_nonrec" "vxml"))

(defvar gf--flag-transform-options
  '("identity" "compute" "typecheck" "solve" "context" "delete"))

(defvar gf--flag-unlexer-options
  '("unwords" "text" "code" "textlit" "codelit" "concat" "bind"))

;; [] add file here?
(defvar gf--flags-table
  `(("filter"    . ,gf--flag-filter-options)
    ("lang"      . ,gf--flag-lang-options)
    ("lexer"	 . ,gf--flag-lexer-options)
    ("optimize"  . ,gf--flag-optimize-options)
    ("parser"    . ,gf--flag-parser-options)
    ("printer"   . ,gf--flag-printer-options)
    ("transform" . ,gf--flag-transform-options)
    ("unlexer"   . ,gf--flag-unlexer-options)))

;;;###autoload
(progn (add-to-list 'auto-mode-alist '("\\.gf\\(\\|e\\|r\\|cm?\\)\\'" . gf-mode))
       (add-to-list 'auto-mode-alist '("\\.cf\\'" . gf-mode))
       (add-to-list 'auto-mode-alist '("\\.ebnf\\'" . gf-mode)))

(provide 'gf)

;;; gf.el ends here
