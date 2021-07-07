;;; geiser-gauche.el -- Gauche Scheme's implementation of the geiser protocols
;; Package-Version: 20200717.758
;; Package-Commit: 362f1d1189c090ece8b94f6a51680f74b1ff40f9

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the Modified BSD License. You should
;; have received a copy of the license along with this program. If
;; not, see <http://www.xfree86.org/3.3.6/COPYRIGHT2.html#5>.


;;; Code:

(require 'geiser-connection)
(require 'geiser-syntax)
(require 'geiser-custom)
(require 'geiser-base)
(require 'geiser-eval)
(require 'geiser-edit)
(require 'geiser-log)
(require 'geiser)

(require 'compile)
(require 'info-look)

(eval-when-compile (require 'cl-lib))


;;; Customization:

(defgroup geiser-gauche nil
  "Customization for Geiser's Gauche Scheme flavour."
  :group 'geiser)

(geiser-custom--defcustom geiser-gauche-binary
    "gosh"
  "Name to use to call the Gauche Scheme executable when starting a REPL."
  :type '(choice string (repeat string))
  :group 'geiser-gauche)

(geiser-custom--defcustom geiser-gauche-extra-command-line-parameters '("-i")
  "Additional parameters to supply to the Gauche binary."
  :type '(repeat string)
  :group 'geiser-gauche)

(geiser-custom--defcustom geiser-gauche-case-sensitive-p t
  "Non-nil means keyword highlighting is case-sensitive."
  :type 'boolean
  :group 'geiser-gauche)

(geiser-custom--defcustom geiser-gauche-extra-keywords nil
  "Extra keywords highlighted in Gauche scheme buffers."
  :type '(repeat string)
  :group 'geiser-gauche)

(geiser-custom--defcustom geiser-gauche-manual-lookup-nodes
    '("gauche-refe")
  "List of info nodes that, when present, are used for manual lookups"
  :type '(repeat string)
  :group 'geiser-gauche)

(geiser-custom--defcustom geiser-gauche-manual-lookup-other-window-p t
  "Non-nil means pop up the Info buffer in another window."
  :type 'boolean
  :group 'geiser-gauche)

;;; REPL support:

(defun geiser-gauche--binary ()
  (if (listp geiser-gauche-binary)
      (car geiser-gauche-binary)
    geiser-gauche-binary))

(defun geiser-gauche--parameters ()
  "Return a list with all parameters needed to start Gauche Scheme."
  `(,@geiser-gauche-extra-command-line-parameters
    "-l" ,(expand-file-name "gauche/geiser.scm" geiser-scheme-dir)
    ,@(and (listp geiser-gauche-binary) (cdr geiser-gauche-binary))))

(defconst geiser-gauche--prompt-regexp "gosh\\(\\[[^(]+\\]\\)?> ") 


;;; Evaluation support:

(defun geiser-gauche--geiser-procedure (proc &rest args)
  ;; (with-current-buffer "*scratch*"
  ;;   (goto-char (point-max))
  ;;   (insert (format "\nGeiser PROC: %s, ARGS: %s \n" proc args)))
  (cl-case proc
    ;; Autodoc and symbol-location makes use of the {{cur-module}} cookie to
    ;; pass current module information
    ((autodoc symbol-location)
     (format "(eval '(geiser:%s %s {{cur-module}}) (find-module 'geiser))"
	     proc (mapconcat 'identity args " ")))
    ;; Eval and compile are (module) context sensitive
    ((eval compile)
     (let ((module (cond ((string-equal "'()" (car args))
			  "'()")
			 ((and (car args))
			  (concat "'" (car args)))
			 (t
			  "#f")))
	   (form (mapconcat 'identity (cdr args) " ")))
       ;; The {{cur-module}} cookie is replaced by the current module for
       ;; commands that need it
       (replace-regexp-in-string
	"{{cur-module}}"
	(if (string= module "'#f")
	    (format "'%s" (geiser-gauche--get-module))
	  module)
	(format "(eval '(geiser:eval %s '%s) (find-module 'geiser))" module form))))
    ;; The rest of the commands are all evaluated in the geiser module 
    (t
     (let ((form (mapconcat 'identity args " ")))
       (format "(eval '(geiser:%s %s) (find-module 'geiser))" proc form)))))

(defconst geiser-gauche--module-re
  "(define-module +\\([[:alnum:].-]+\\)")

(defun geiser-gauche--get-current-repl-module ()
  (substring 
   (geiser-eval--send/result
    '(list (list (quote result) (write-to-string (current-module)))))
   9 -1))

(defun geiser-gauche--get-module (&optional module)
  (cond ((null module)
         (save-excursion
           (geiser-syntax--pop-to-top)
           (if (or (re-search-backward geiser-gauche--module-re nil t)
                   (looking-at geiser-gauche--module-re)
                   (re-search-forward geiser-gauche--module-re nil t))
               (geiser-gauche--get-module (match-string-no-properties 1))
	     ;; Return the repl module as fallback
             (geiser-gauche--get-module
	      (geiser-gauche--get-current-repl-module)))))
	((symbolp module) module)
        ((listp module) module)
        ((stringp module)
         (condition-case nil
             (car (geiser-syntax--read-from-string module))
           (error :f)))
        (t :f)))

(defun geiser-gauche--enter-command (module)
  (format "(select-module %s)" module))

(defun geiser-gauche--import-command (module)
  (format "(import %s)" module))

(defun geiser-gauche--symbol-begin (module)
  (if module
      (max (save-excursion (beginning-of-line) (point))
           (save-excursion (skip-syntax-backward "^(>") (1- (point))))
    (save-excursion (skip-syntax-backward "^'-()>") (point))))

(defun geiser-gauche--exit-command () "(exit)")

(defconst geiser-gauche--binding-forms
  '("and-let" "and-let1" "let1" "if-let1" "rlet1" "receive" "fluid-let" "let-values"
    "^" "^a" "^b" "^c" "^d" "^e" "^f" "^g" "^h" "^i" "^j" "^k" "^l" "^m" "^n" "^o" "^p" "^q"
    "^r" "^s" "^t" "^v" "^x" "^y" "^z" "^w" "^_" "rec"))

(defconst geiser-gauche--binding-forms*
  '("and-let*" "let*-values" ))

(defconst geiser-gauche-builtin-keywords
  '("and-let"
    "and-let1"
    "assume"
    "cut"
    "cute"
    "define-constant"
    "define-enum"
    "define-in-module"
    "define-inline"
    "define-type"
    "dotimes"
    "dolist"
    "ecase"
    "fluid-let"
    "if-let1"
    "let1"
    "let-keywords"
    "let-optionals"
    "let-optionals*"
    "let-values"
    "receive"
    "rec"
    "rlet1"
    "select-module"
    "use"
    "with-input-from-pipe"
    "^" "^a" "^b" "^c" "^d" "^e" "^f" "^g" "^h" "^i" "^j" "^k" "^l" "^m" "^n" "^o" "^p" "^q"
    "^r" "^s" "^t" "^v" "^x" "^y" "^z" "^w" "^_"
    "with-error-handler"
    "with-error-to-port"
    "with-exception-handler"
    "with-exception-handler"
    "with-input-conversion"
    "with-input-from-file"
    "with-input-from-port"
    "with-input-from-process"
    "with-input-from-string"
    "with-iterator"
    "with-lock-file"
    "with-locking-mutex"
    "with-module"
    "with-output-conversion"
    "with-output-to-file"
    "with-output-to-port"
    "with-output-to-process"
    "with-output-to-string"
    "with-port-locking"
    "with-ports"
    "with-profiler"
    "with-random-data-seed"
    "with-signal-handlers"
    "with-string-io"
    "with-time-counter"))

(defun geiser-gauche--keywords ()
  (append
   (geiser-syntax--simple-keywords geiser-gauche-extra-keywords)
   (geiser-syntax--simple-keywords geiser-gauche-builtin-keywords)))

(geiser-syntax--scheme-indent
 (case-lambda: 0)
 (let1 1))


;;; REPL startup

(defconst geiser-gauche-minimum-version "0.9.9")

(defun geiser-gauche--version (binary)
  (cadr (read (cadr (process-lines "gosh" "-V")))))

(defun geiser-gauche--startup (remote)
  (let ((geiser-log-verbose-p t))
    (compilation-setup t)
    (geiser-eval--send/wait "(newline)")))


;;; Error display

(defun geiser-gauche--display-error (module key msg)
  (when key
    (insert key)
    (save-excursion
      (goto-char (point-min))
      (re-search-forward "report-error err #f")
      (kill-whole-line 2)))
  (when msg
    (insert msg))
  (if (and msg (string-match "\\(.+\\)$" msg)) (match-string 1 msg) key))


;;; Manual look up
;;; code adapted from the Guile implementation

(defun geiser-gauche--info-spec (&optional nodes)
  (let* ((nrx "^[       ]+-+ [^:]+:[    ]*")
         (drx "\\b")
         (res (when (Info-find-file "gauche-refe" t)
                `(("(gauche-refe)Function and Syntax Index" nil ,nrx ,drx)))))
    (dolist (node (or nodes geiser-gauche-manual-lookup-nodes) res)
      (when (Info-find-file node t)
        (mapc (lambda (idx)
                (add-to-list 'res
                             (list (format "(%s)%s" node idx) nil nrx drx)))
              '("Module Index" "Class Index" "Variable Index"))))))

(info-lookup-add-help :topic 'symbol :mode 'geiser-gauche-mode
                      :ignore-case nil
                      :regexp "[^()`',\"        \n]+"
                      :doc-spec (geiser-gauche--info-spec))

(defun geiser-gauche--manual-look-up (id mod)
  (let ((info-lookup-other-window-flag
         geiser-gauche-manual-lookup-other-window-p))
    (info-lookup-symbol (symbol-name id) 'geiser-gauche-mode))
  (when geiser-gauche-manual-lookup-other-window-p
    (switch-to-buffer-other-window "*info*"))
  (search-forward (format "%s" id) nil t))


;;; Guess whether buffer is Gauche

(defconst geiser-gauche--guess-re
  (regexp-opt '("gauche" "gosh")))

(defun geiser-gauche--guess ()
  (save-excursion
    (goto-char (point-min))
    (re-search-forward geiser-gauche--guess-re nil t)))


;;; Implementation definition:

(define-geiser-implementation gauche
  (unsupported-procedures '(callers callees generic-methods))
  (binary geiser-gauche--binary)
  (arglist geiser-gauche--parameters)
  (version-command geiser-gauche--version)
  (minimum-version geiser-gauche-minimum-version)
  (repl-startup geiser-gauche--startup)
  (prompt-regexp geiser-gauche--prompt-regexp)
  (debugger-prompt-regexp nil)
  ;; geiser-gauche--debugger-prompt-regexp
  ;; (enter-debugger geiser-gauche--enter-debugger)
  (marshall-procedure geiser-gauche--geiser-procedure)
  (find-module geiser-gauche--get-module)
  (enter-command geiser-gauche--enter-command)
  (exit-command geiser-gauche--exit-command)
  (import-command geiser-gauche--import-command)
  (find-symbol-begin geiser-gauche--symbol-begin)
  (display-error geiser-gauche--display-error)
  (binding-forms geiser-gauche--binding-forms)
  (binding-forms* geiser-gauche--binding-forms*)
  (external-help geiser-gauche--manual-look-up)
  (check-buffer geiser-gauche--guess)
  (keywords geiser-gauche--keywords)
  (case-sensitive geiser-gauche-case-sensitive-p))

(geiser-impl--add-to-alist 'regexp "\\.scm$" 'gauche t)

(add-to-list 'geiser-active-implementations 'gauche)

(provide 'geiser-gauche)

;;; geiser-gauche.el ends here
