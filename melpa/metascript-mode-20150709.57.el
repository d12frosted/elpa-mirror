;;; metascript-mode.el --- Major mode for the Metascript programming language

;; Copyright © 2014-2015 Rodrigo B. de Oliveira
;;
;; Authors: Rodrigo B. de Oliveira <rbo@acm.org>
;; URL: http://github.com/metascript/metascript-mode
;; Package-Version: 20150709.57
;; Package-Commit: edb361c7b0e5de231e5334a17b90652fb1df78f9
;; Keywords: languages metascript mjs
;; Version: 0.1
;; Package-Requires: ((emacs "24.3"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Major mode for the Metascript programming language.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(eval-when-compile (require 'cl))
(require 'rx)
(require 'flymake)
(require 'comint)

(defconst metascript-mode-version "0.1"
  "`metascript-mode' version number.")

(defgroup metascript nil
  "Support for the Metascript programming language."
  :group 'languages
  :prefix "metascript-"
  :link '(url-link :tag "Github" "https://github.com/metascript/metascript-mode")
  :link '(emacs-commentary-link :tag "Commentary" "metascript-mode"))

(defcustom metascript-indent-tabs-mode nil
  "Custom value for `indent-tabs-mode' when `metascript-mode' starts, default is nil."
  :type 'boolean
  :group 'metascript)

(defcustom metascript-indent-offset 2
  "Amount of offset per level of indentation."
  :type 'integer
  :group 'metascript)
(make-variable-buffer-local 'metascript-indent-offset)

(defcustom metascript-mode-hook nil
  "List of functions to be executed on entry to metascript-mode."
  :type 'hook
  :group 'metascript)

(defmacro defmjsface (name base description)
  "Defines a metascript-mode font-lock face named `NAME', inheriting from `BASE' described as `DESCRIPTION'."
  `(progn
     (defface ,name
       '((t (:inherit ,base)))
       ,description
       :group 'metascript)
     (defvar ,name ',name)))

(defmjsface metascript-control-flow-face font-lock-keyword-face
  "Highlight control flow.")

(defmjsface metascript-def-face font-lock-keyword-face
  "Highlight definitions.")

(defmjsface metascript-modifier-face font-lock-keyword-face
  "Highlight modifiers.")

(defmjsface metascript-builtin-face font-lock-builtin-face
  "Highlight builtins.")

(defmjsface metascript-constant-face font-lock-constant-face
  "Highlight constants.")

(defmjsface metascript-number-face font-lock-variable-name-face
  "Highlight numbers.")

(defmjsface metascript-type-name-face font-lock-type-face
  "Highlight types names.")

(defmjsface metascript-object-literal-key-face font-lock-variable-name-face
  "Highlight object literal keys.")

(defmjsface metascript-function-name-face font-lock-function-name-face
  "Highlight function names.")

(defmjsface metascript-variable-name-face font-lock-variable-name-face
  "Highlight variable names.")

(defmjsface metascript-placeholder-face font-lock-preprocessor-face
  "Highlight placeholders (symbols starting with a #)")

(defvar metascript-font-lock-keywords nil
  "Additional expressions to highlight in Metascript mode.")

(setq metascript-font-lock-keywords

      ;; Keywords
      `(,(rx symbol-start
             (or "new" "delete" "->")
             symbol-end)

        (,(rx symbol-start (or "var" "const" "fun")
              symbol-end) . metascript-def-face)

        (,(rx symbol-start (or "#meta" "#keep-meta")
              symbol-end) . metascript-modifier-face)

        (,(rx symbol-start (or "arguments" "require" "typeof" "instanceof" "parseInt" "parse-int")
              symbol-end) . metascript-builtin-face)

        (,(rx symbol-start (or "Object" "Array" "String"
                               "Function" "Number" "Math"
                               "Boolean" "Date" "JSON" "Error")
              symbol-end) . metascript-type-name-face)

        (,(rx symbol-start (or "true" "false" "null" "this" "undefined")
              symbol-end) . metascript-constant-face)

        (,(rx symbol-start (or "try" "catch" "finally" "throw"
			       "loop" "next!" "if" "else"
			       "return" "do" "do!"
			       "while" (seq "yield" (1+ space) symbol-start "from" symbol-end)
			       "yield")
              symbol-end) . metascript-control-flow-face)

        ;; functions
        (,(rx symbol-start (or "fun" (seq "#def" (1+ word)) "#keepmacro") (1+ space) (group (seq (1+ (or word ?_ ?- ?>)) (? (any "!?")))))
         (1 metascript-function-name-face))

        ;; variable names
        (,(rx symbol-start (or "var" "const" "#metaimport" "#external") (1+ space) (group (seq (1+ (or word ?_ ?- ?>)) (? (any "!?")))))
         (1 metascript-variable-name-face))

        ;; object literal keys
        (,(rx symbol-start (group (seq (1+ (or word ?_ ?- ?>)) (? (any "!?")))) ?:)
         (1 metascript-object-literal-key-face))

        ;; numbers
        (,(rx symbol-start (or (1+ digit) (seq "0x" (1+ hex-digit)))
              symbol-end) . metascript-number-face)

        ;; placeholders
        (,(rx symbol-start ?\# (1+ (or word ?_ ?- ?>))
              symbol-end) . metascript-placeholder-face)))


(defvar metascript-mode-syntax-table nil
  "Syntax table for Metascript files.")

(setq metascript-mode-syntax-table
      (let ((table (make-syntax-table)))
        ;; Give punctuation syntax to ASCII that normally has symbol
        ;; syntax or has word syntax and isn't a letter.
        (let ((symbol (string-to-syntax "_"))
              (sst (standard-syntax-table)))
          (dotimes (i 128)
            (unless (= i ?_)
              (if (equal symbol (aref sst i))
                  (modify-syntax-entry i "." table)))))
        (modify-syntax-entry ?$ "_" table)
        (modify-syntax-entry ?! "_" table)
        (modify-syntax-entry ?\? "_" table)
        (modify-syntax-entry ?\- "_" table)
        (modify-syntax-entry ?\> "_" table)
        (modify-syntax-entry ?% "." table)
        (modify-syntax-entry ?\; "<" table)
        (modify-syntax-entry ?\n ">" table)
        (modify-syntax-entry ?' "\"" table)
        (modify-syntax-entry ?\\ "\\" table)
        (modify-syntax-entry ?` "'" table)
        (modify-syntax-entry ?\# "_" table)
        table))

(defun metascript-indent-line ()
  "Indent current line of mjs code.
If the previous non empty line ends in any of `({[>=' indentation is increased,
otherwise it stays the same."
  (interactive)
  (let (indent)
    (save-excursion
      (beginning-of-line)
      (setq indent
            (if (and (re-search-backward (rx (not (any ?\n whitespace))))
                     (looking-at "[{(\[>=]"))
                (+ (current-indentation) metascript-indent-offset)
              (current-indentation))))
    (indent-to indent)))


; blocks as sexps (borrowed from HAML mode which borrowed it from Python mode which...)
(defun metascript-forward-through-whitespace (&optional backward)
  "Move the point forward through any whitespace.
The point will move forward at least one line, until it reaches
either the end of the buffer or a line with no whitespace.

If BACKWARD is non-nil, move the point backward instead."
  (let ((arg (if backward -1 1))
        (endp (if backward 'bobp 'eobp)))
    (loop do (forward-line arg)
          while (and (not (funcall endp))
                     (looking-at "^[ \t]*$")))))

(defun metascript-at-indent-p ()
  "Return non-nil if the point is before any text on the line."
  (let ((opoint (point)))
    (save-excursion
      (back-to-indentation)
      (>= (point) opoint))))

(defun metascript-forward-sexp (&optional arg)
  "Move forward across one nested expression.
With ARG, do it that many times.  Negative arg -N means move
backward across N balanced expressions.

A sexp in metascript is defined as a line of metascript code as well as any
lines nested beneath it."
  (interactive "p")
  (or arg (setq arg 1))
  (if (and (< arg 0) (not (metascript-at-indent-p)))
      (back-to-indentation)
    (while (/= arg 0)
      (let ((indent (current-indentation)))
        (loop do (metascript-forward-through-whitespace (< arg 0))
              while (and (not (eobp))
                         (not (bobp))
                         (> (current-indentation) indent)))
        (unless (eobp)
          (back-to-indentation))
        (setq arg (+ arg (if (> arg 0) -1 1)))))))

(defun metascript-mark-sexp ()
  "Mark the next metascript block."
  (interactive)
  (let ((forward-sexp-function 'metascript-forward-sexp))
    (mark-sexp)))

(defun metascript-backward-sexp (&optional arg)
  "Move backward across one nested expression.
With ARG, do it that many times.  Negative arg -N means move
forward across N balanced expressions.

A sexp in metascript is defined as a line of metascript code as well as any
lines nested beneath it."
  (interactive "p")
  (metascript-forward-sexp (if arg (- arg) -1)))

(defun metascript-buffer-package-root ()
  "Locates the npm package root of the current buffer."
  (locate-dominating-file (buffer-file-name) "package.json"))

(defun metascript-package-json (package-root)
  "Read `package.json' from `PACKAGE-ROOT'."
  (require 'json)
  (json-read-file (concat package-root "/package.json")))

(defun metascript-buffer-package-json ()
  "Return `package.json' content for current buffer package, if any."
  (let ((package-root (metascript-buffer-package-root)))
    (when package-root
      (metascript-package-json package-root))))

(defun metascript-package-name (package-root)
  "Return the package name as defined in the package.json file at `PACKAGE-ROOT'."
  (cdr (assoc 'name (metascript-package-json package-root))))

(defun metascript-run-tests ()
  "Run `npm test' on current package."
  (interactive)
  (let ((package (metascript-buffer-package-root)))
    (if package
        (let ((default-directory package)
              (package-name (metascript-package-name package)))
          (with-current-buffer
              (pop-to-buffer
               (make-comint (concat package-name " tests") "npm" nil "test"))
            (compilation-minor-mode)))
      (message "couldn't find package.json for %s" (buffer-name)))))

(add-to-list 'compilation-error-regexp-alist-alist
             '(metascript-stack-trace
               "at \\([^(\n]+?\\):\\([0-9]+\\):\\([0-9]+\\)"
               1 2 3))
(add-to-list 'compilation-error-regexp-alist 'metascript-stack-trace)

(add-to-list 'compilation-error-regexp-alist-alist
             '(metascript-stack-trace-with-function-name
               "at [^\n]*? (\\(.+?\\):\\([0-9]+\\):\\([0-9]+\\))"
               1 2 3))
(add-to-list 'compilation-error-regexp-alist 'metascript-stack-trace-with-function-name)


(defvar metascript-mode-map
  (let ((map (make-sparse-keymap "Metascript")))
    (define-key map (kbd "RET") 'newline-and-indent)
    (define-key map "\C-\M-f" 'metascript-forward-sexp)
    (define-key map "\C-\M-b" 'metascript-backward-sexp)
    (define-key map "\C-\M-x" 'metascript-repl-eval)
    (define-key map "\C-c," 'metascript-run-tests)
    (define-key map (kbd "C-M-SPC") 'metascript-mark-sexp)
    (define-key map "\C-c\M-j" 'metascript-repl)
    map))

;;;###autoload
(define-derived-mode metascript-mode prog-mode "MJS"
  "A major mode for editing Metascript source files."
  :syntax-table metascript-mode-syntax-table
  :group 'metascript
  (setq-local comment-start "; ")
  (setq-local font-lock-defaults '(metascript-font-lock-keywords))
  (setq-local indent-line-function 'metascript-indent-line))

(defun metascript-setup-buffer-locals ()
  "Setup buffer local variables for `metascript-mode'."
  (when (setq indent-tabs-mode metascript-indent-tabs-mode)
    (setq tab-width metascript-indent-offset)))

(add-hook 'metascript-mode-hook #'metascript-setup-buffer-locals)

(add-hook 'metascript-mode-hook 'rainbow-delimiters-mode)

;; flymake integration
(defun flymake-metascript-init ()
  "Setup temporary buffer to run `mjs check' on."
  (let* ((temp-file (flymake-init-create-temp-buffer-copy 'flymake-create-temp-inplace))
         (local-file (file-relative-name temp-file (file-name-directory buffer-file-name))))
    (list "mjs" (list "check" local-file))))

(setq flymake-allowed-file-name-masks
      (cons '(".+\\.mjs$"
              flymake-metascript-init
              flymake-simple-cleanup
              flymake-get-real-file-name)
            flymake-allowed-file-name-masks))

(setq flymake-err-line-patterns ; regexp file-idx line-idx col-idx (optional) text-idx(optional), match-end to end of string is error text
      (cons '("\\([^(]*\\)(\\([0-9]+\\),\\([0-9]+\\))\: \\(.+\\)"
              1 2 3 4)
            flymake-err-line-patterns))

(defcustom metascript-implies-flymake t
  "Wether metascript-mode should imply `flymake-mode', default is t."
  :type 'boolean
  :group 'metascript)

(defun metascript-assoc-in (alist keys)
  "Return the value in a nested `ALIST' structure, where `KEYS' is a sequence of keys or nil if value cannot be found."
  (when alist
    (let ((key (car keys))
          (keys (cdr keys)))
      (let ((value (assoc key alist)))
        (if keys
            (metascript-assoc-in (cdr value) keys)
          value)))))

(defun metascript-package-json-dev-dependency (name package-json)
  "Return the value of devDependencies / `NAME' from the nested alist `PACKAGE-JSON'."
  (metascript-assoc-in package-json `(devDependencies ,name)))

(defun metascript-check-available-p ()
  (let ((package-json (metascript-buffer-package-json)))
    (when package-json
      (metascript-package-json-dev-dependency 'metascript-check package-json))))

(defun metascript-flymake-setup ()
  "Setup `flymake-mode' on the current buffer if the `metascript-check' dependency is available."
  (and metascript-implies-flymake
       (metascript-check-available-p)
       (flymake-mode)))

(add-hook 'metascript-mode-hook #'metascript-flymake-setup)

; pretty symbol display

(defcustom metascript-pretty-symbol-display-enabled t
  "Wether metascript-mode should replace certain programming language symbols such as `fun' and `#->' by prettier ones such as `ƒ' and `𝝺', default is t."
  :type 'boolean
  :group 'metascript)

(defcustom metascript-pretty-lambda-parameter "Χ"
  "Pretty symbol for #it."
  :type 'string
  :group 'metascript)

(defmjsface metascript-pretty-lambda-parameter-face metascript-builtin-face
  "Pretty lambda parameter face")

(defun metascript-pretty-symbols-setup ()
  "Setup the display of pretty symbols when `metascript-pretty-symbol-display-enabled' is true."
  (when metascript-pretty-symbol-display-enabled
    (font-lock-add-keywords
     nil
     `(("\\_<\\(#->\\)\\_>"
	(0 (progn (compose-region (match-beginning 1)
				  (match-end 1)
				  "λ")
		  'metascript-def-face)))

       ("\\_<\\(fun\\)\\_>"
	(0 (progn (compose-region (match-beginning 1)
				  (match-end 1)
				  "ƒ")
		  'metascript-def-face)))

       ("\\_<\\(->\\)\\_>"
	(0 (progn (compose-region (match-beginning 1)
				  (match-end 1)
				  "→")
		  'metascript-def-face)))

       ("\s\\(!=\\)\s"
	(0 (progn (compose-region (match-beginning 1)
				  (match-end 1)
				  "≠")
		  nil)))

       ("\s\\(>=\\)\s"
	(0 (progn (compose-region (match-beginning 1)
				  (match-end 1)
				  "≥")
		  nil)))

       ("\s\\(<=\\)\s"
	(0 (progn (compose-region (match-beginning 1)
				  (match-end 1)
				  "≤")
		  nil)))

       ("\s\\(==\\)\s"
	(0 (progn (compose-region (match-beginning 1)
				  (match-end 1)
				  "≣")
		  nil)))

       ("\\_<\\(#it\\)\\_>"
	(0 (progn (compose-region (match-beginning 1)
				  (match-end 1)
				  metascript-pretty-lambda-parameter)
		  metascript-pretty-lambda-parameter-face)))))))

(add-hook 'metascript-mode-hook #'metascript-pretty-symbols-setup)

;; REPL

(defcustom inferior-metascript-repl-program "mjsish"
  "Path to mjs repl application."
  :type 'string
  :group 'metascript)

(defcustom inferior-metascript-repl-port 8484
  "Network port to start repl evaluation server."
  :type 'number
  :group 'metascript)

;;;###autoload
(defun metascript-repl ()
  "Launch or activate REPL."
  (interactive)
  (pop-to-buffer (metascript-repl-make-comint))
  (metascript-repl-mode))

(defun metascript-repl-make-comint ()
  (make-comint "metascript-repl" inferior-metascript-repl-program nil
               "--no-tty" "--port" (number-to-string inferior-metascript-repl-port)))

(defun metascript-repl-eval (&optional process)
  "Send active region to the REPL associated with `PROCESS'."
  (interactive)
  (let ((code (concat (metascript-chomp-end (metascript-region-string)) ";\n"))
        (repl (or process (metascript-repl-connection))))
    (comint-send-string repl code)))

(defun metascript-repl-connection ()
  (let ((conn (make-comint "mjs repl connection" (cons "localhost" inferior-metascript-repl-port))))
    (with-current-buffer conn
      (metascript-repl-connection-mode))
    conn))

(defun metascript-repl-connection-output (string)
  (message (first (split-string string "\n")))
  nil)

(define-derived-mode metascript-repl-connection-mode comint-mode "mjs repl connection"
  "Major mode for mjs repl connection"
  (add-hook 'comint-output-filter-functions #'metascript-repl-connection-output nil t))


(defun metascript-chomp-end (string)
  "Chomp trailing whitespace from `STRING'."
  (replace-regexp-in-string (rx (* (any " \t\n")) eos)
                            ""
                            string))

(defun metascript-region-string ()
  "Return active region substring."
  (buffer-substring (region-beginning) (region-end)))


(define-derived-mode metascript-repl-mode comint-mode "Metascript REPL"
  "Major mode for Metascript REPL"
  :syntax-table metascript-mode-syntax-table
  (setq-local font-lock-defaults '(nil nil t)))


;;;###autoload
(progn
  (add-to-list 'auto-mode-alist '("\\.mjs\\'" . metascript-mode)))

(provide 'metascript-mode)
;;; metascript-mode.el ends here
