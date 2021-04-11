;;; fennel-mode.el --- A major-mode for editing Fennel code

;; Copyright © 2018 Phil Hagelberg and contributors

;; Author: Phil Hagelberg
;; URL: https://gitlab.com/technomancy/fennel-mode
;; Package-Version: 20210410.1942
;; Package-Commit: 59ab02344f569069b9899a3a5ffdca4a30093df4
;; Version: 0.2.0
;; Created: 2018-02-18
;; Package-Requires: ((emacs "25.1"))
;;
;; Keywords: languages, tools

;;; Commentary:

;; Provides font-lock, indentation, navigation, and repl for Fennel code.

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
(require 'lisp-mode)
(require 'inf-lisp)
(require 'xref)

(declare-function paredit-open-curly "ext:paredit")
(declare-function paredit-close-curly "ext:paredit")
(declare-function lua-mode "ext:lua-mode")

(defcustom fennel-mode-switch-to-repl-after-reload t
  "If the focus should switch to the repl after a module reload."
  :group 'fennel-mode
  :type 'boolean
  :package-version '(fennel-mode "0.10.0"))

(defcustom fennel-program "fennel --correlate --repl"
  "Command to run the fennel REPL"
  :group 'fennel-mode
  :type 'string
  :package-version '(fennel-mode "0.10.0"))

(make-variable-buffer-local
 (defvar fennel-repl--last-fennel-buffer nil))

;;;###autoload
(define-derived-mode fennel-repl-mode inferior-lisp-mode "Fennel REPL"
  "Major mode for Fennel REPL."
  (set (make-local-variable 'lisp-describe-sym-command) "(doc %s)\n")
  (set (make-local-variable 'inferior-lisp-prompt) ">> ")
  (set (make-local-variable 'lisp-arglist-command) fennel-arglist-command))

(define-key fennel-repl-mode-map (kbd "C-c C-z") 'fennel-repl)

(defvar fennel-repl--buffer "*Fennel REPL*")

(defun fennel-repl--start (&optional ask-for-command?)
  (if (not (comint-check-proc fennel-repl--buffer))
      (let* ((cmd (or (and ask-for-command? (read-from-minibuffer "Command: "))
                      fennel-program))
             (cmdlist (split-string fennel-program)))
        (set-buffer (apply #'make-comint "Fennel REPL" (car cmdlist) nil (cdr cmdlist)))
        (fennel-repl-mode)
        (setq inferior-lisp-buffer fennel-repl--buffer)))
  (get-buffer fennel-repl--buffer))

(defvar fennel-module-name nil
  "Buffer-local value for storing the current file's module name.")

(defvar fennel-arglist-command
  ;; TODO: not sure if there's currently a way to support this for both
  ;; built-ins and user-defined functions.
  "(eval-compiler (-> _SPECIALS.%s (fennel.metadata:get :fnl/arglist)
                      (table.concat \" \") print))\n")

(defvar fennel-mode-syntax-table
  (let ((table (copy-syntax-table lisp-mode-syntax-table)))
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    table))

(defvar fennel-keywords
  '("require-macros" "eval-compiler" "doc" "lua" "hashfn" "macro" "macros"
    "import-macros" "pick-args" "pick-values" "macroexpand" "macrodebug"
    "do" "values" "if" "when" "each" "for" "fn" "lambda" "λ" "partial" "while"
    "set" "global" "var" "local" "let" "tset" "set-forcibly!" "doto" "match"
    "or" "and" "true" "false" "nil" "not" "not=" "collect" "icollect"
    "." "+" ".." "^" "-" "*" "%" "/" ">" "<" ">=" "<=" "=" "#" "..." ":"
    "->" "->>" "-?>" "-?>>" "$" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    "rshift" "lshift" "bor" "band" "bnot" "bxor" "with-open"))

(defvar fennel-builtins
  '("_G" "_VERSION" "arg" "assert" "bit32" "collectgarbage" "coroutine" "debug"
    "dofile" "error" "getfenv" "getmetatable" "io" "ipairs" "length" "load"
    "loadfile" "loadstring" "math" "next" "os" "package" "pairs" "pcall"
    "print" "rawequal" "rawget" "rawlen" "rawset" "require" "select" "setfenv"
    "setmetatable" "string" "table" "tonumber" "tostring" "type" "unpack"
    "xpcall"))

(defvar fennel-local-fn-pattern
  (rx (syntax open-parenthesis)
      (or "fn" "lambda" "λ") (1+ space)
      (group (1+ (or (syntax word) (syntax symbol) "-" "_")))))

(defvar fennel-font-lock-keywords
  `((,fennel-local-fn-pattern 1 font-lock-variable-name-face)
    (,(rx (syntax open-parenthesis)
          (or "fn" "lambda" "λ") (1+ space)
          (group (and (not (any "["))
                      (1+ (or (syntax word) (syntax symbol))))))
     1 font-lock-variable-name-face)
    (,(regexp-opt fennel-keywords 'symbols) . font-lock-keyword-face)
    (,(regexp-opt fennel-builtins 'symbols) . font-lock-builtin-face)
    (,(rx (group ":" (1+ word))) 0 font-lock-builtin-face)
    (,(rx (group letter (0+ word) "." (1+ word))) 0 font-lock-type-face)))

(defun fennel-font-lock-setup ()
  "Setup font lock for keywords."
  (setq font-lock-defaults
        '(fennel-font-lock-keywords nil nil (("+-*/.<>=!?$%_&:" . "w")))))

(defvar calculate-lisp-indent-last-sexp)

(defun fennel-indent-function (indent-point state)
  "Simplified version of function `lisp-indent-function'.

INDENT-POINT is the position at which the line being indented begins.
Point is located at the point to indent under (for default indentation);
STATE is the `parse-partial-sexp' state for that position."
  (let ((normal-indent (current-column)))
    (goto-char (1+ (elt state 1)))
    (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
    (let* ((fn (buffer-substring (point) (progn (forward-sexp 1) (point))))
           (open-paren (elt state 1))
           (method (get (intern-soft fn) 'fennel-indent-function)))
      (cond ((member (char-after open-paren) '(?\[ ?\{))
             (goto-char open-paren)
             (1+ (current-column)))
            ((eq method 'defun)
             (lisp-indent-defform state indent-point))
            ((integerp method)
             (lisp-indent-specform method state indent-point normal-indent))
            (method
             (funcall method indent-point state))))))

;;;###autoload
(define-derived-mode fennel-mode lisp-mode "Fennel"
  "Major mode for editing Fennel code.

\\{fennel-mode-map}"
  ;; TODO: completion using inferior-lisp
  (add-to-list 'imenu-generic-expression `(nil ,fennel-local-fn-pattern 1))
  (make-local-variable 'fennel-module-name)
  (set (make-local-variable 'indent-tabs-mode) nil)
  (set (make-local-variable 'lisp-indent-function) 'fennel-indent-function)
  (set (make-local-variable 'inferior-lisp-program) fennel-program)
  (set (make-local-variable 'lisp-describe-sym-command) "(doc %s)\n")
  (set (make-local-variable 'inferior-lisp-load-command)
       ;; won't work if the fennel module name has changed but beats nothing
       "((. (require :fennel) :dofile) %s)")
  (set (make-local-variable 'lisp-arglist-command) fennel-arglist-command)
  (set-syntax-table fennel-mode-syntax-table)
  (fennel-font-lock-setup)
  ;; work around slime bug: https://gitlab.com/technomancy/fennel-mode/issues/3
  (when (fboundp 'slime-mode)
    (slime-mode -1))
  (add-hook 'paredit-mode-hook #'fennel-paredit-setup))

(defun fennel-paredit-setup ()
  "Setup paredit keys."
  (define-key fennel-mode-map "{" #'paredit-open-curly)
  (define-key fennel-mode-map "}" #'paredit-close-curly))

(defun fennel-get-module (ask? last-module)
  "Ask for the name of a module for the current file; return keyword.

If ASK? or LAST-MODULE were not supplied, asks for the name of a module."
  (let ((module (if (or ask? (not last-module))
                    (read-string "Module: " (or last-module (file-name-base nil)))
                  last-module)))
    (setq fennel-module-name module) ; remember for next time
    (intern (concat ":" module))))

(defun fennel-reload-form (module-keyword)
  "Return a string of the code to reload the MODULE-KEYWORD module."
  (format "%s\n" `(let [old (require ,module-keyword)
                            _ (tset package.loaded ,module-keyword nil)
                            (ok new) (pcall require ,module-keyword)
                            ;; keep the old module if reload failed
                            new (if (not ok) (do (print new) old) new)]
                    ;; if the module isn't a table then we can't make
                    ;; changes which affect already-loaded code, but if
                    ;; it is then we should splice new values into the
                    ;; existing table and remove values that are gone.
                    (when (and (= (type old) :table) (= (type new) :table))
                      (each [k v (pairs new)]
                            (tset old k v))
                      (each [k (pairs old)]
                            ;; the elisp reader is picky about where . can be
                            (when (= nil (,"." new k))
                              (tset old k nil)))
                      (tset package.loaded ,module-keyword old)))))

(defun fennel-reload (ask?)
  "Reload the module for the current file.

ASK? forces module name prompt.

Tries to reload in a way that makes it retroactively visible; if
the module returns a table, then existing references to the same
module will have their contents updated with the new
value.  Requires installing `fennel.searcher'.

Queries the user for a module name upon first run for a given
buffer, or when given a prefix arg."
  (interactive "P")
  (comint-check-source buffer-file-name)
  (let* ((module (fennel-get-module ask? fennel-module-name)))
    (when (and (file-exists-p (concat (file-name-base nil) ".lua"))
               (yes-or-no-p "Lua file for module exists; delete it first?"))
      (delete-file (concat (file-name-base nil) ".lua")))
    (comint-send-string (inferior-lisp-proc) (fennel-reload-form module)))
  (when fennel-mode-switch-to-repl-after-reload
    (switch-to-lisp t)))

(defun fennel-find-definition-go (location)
  "Go to the definition LOCATION."
  (when (string-match "^@\\(.+\\)!\\(.+\\)" location)
    (let ((file (match-string 1 location))
          (line (string-to-number (match-string 2 location))))
      (message "found file, line %s %s" file line)
      (when file (find-file file))
      (when line
        (goto-char (point-min))
        (forward-line (1- line))))))

(defun fennel-find-definition-for (identifier)
  "Find the definition of IDENTIFIER."
  (let ((tempfile (make-temp-file "fennel-find-")))
    (comint-send-string
     (inferior-lisp-proc)
     (format "%s\n"
             `(with-open [f (io.open ,(format "\"%s\"" tempfile) :w)]
                (match (-?> ,identifier (debug.getinfo))
                  {:what :Lua
                   : source : linedefined} (f:write source :! linedefined)))))
    (sit-for 0.1)
    (unwind-protect
        (when (file-exists-p tempfile)
          (with-temp-buffer
            (insert-file-contents tempfile)
            (delete-file tempfile)
            (buffer-substring-no-properties (point-min) (point-max)))))))

(defun fennel-find-definition (identifier)
  "Jump to the definition of the function IDENTIFIER at point.
This will only work when the reference to the function is in scope for the repl;
for instance if you have already entered (local foo (require :foo)) then foo.bar
can be resolved. It also requires line number correlation."
  (interactive (list (read-string "Find definition: ")))
  (xref-push-marker-stack (point-marker))
  (fennel-find-definition-go (fennel-find-definition-for identifier)))

(defvar fennel-module-history nil)
(defvar fennel-field-history nil)

(defun fennel-find-module-field (module fields-string)
  (let ((tempfile (make-temp-file "fennel-module-"))
        (fields (mapcar (apply-partially 'concat ":")
                        (split-string fields-string "\\."))))
    (comint-send-string
     (inferior-lisp-proc)
     (format "%s\n"
             `(with-open [f (io.open ,(format "\"%s\"" tempfile) :w)]
                (match (-?> (,"." (require ,(format "\"%s\"" module)) ,@fields)
                            (debug.getinfo))
                  {:what :Lua
                   : source : linedefined} (f:write source :! linedefined)))))
    (sit-for 0.1)
    (unwind-protect
        (when (file-exists-p tempfile)
          (with-temp-buffer
            (insert-file-contents tempfile)
            (delete-file tempfile)
            (buffer-substring-no-properties (point-min) (point-max)))))))

(defun fennel-find-module-definition ()
  (interactive)
  (let* ((module (read-from-minibuffer "Find in module: " nil nil nil
                                       'fennel-module-history
                                       (car fennel-module-history)))
         (fields (read-from-minibuffer "Find module field: " nil nil nil
                                       'fennel-field-history
                                       (car fennel-field-history))))
    (xref-push-marker-stack (point-marker))
    (fennel-find-definition-go (fennel-find-module-field module fields))))

(defun fennel-find-definition-pop ()
  "Return point to previous position in previous buffer."
  (interactive)
  (require 'etags)
  (let ((marker (xref-pop-marker-stack)))
    (switch-to-buffer (marker-buffer marker))
    (goto-char (marker-position marker))))

(defun fennel-view-compilation ()
  "Compile the current buffer and view the output."
  (interactive)
  (let ((compile-command (format "fennel --compile %s" (buffer-file-name))))
    (switch-to-buffer (format "*fennel %s*" (buffer-name)))
    (read-only-mode -1)
    (delete-region (point-min) (point-max))
    (insert (shell-command-to-string compile-command))
    (lua-mode)
    (read-only-mode)
    (goto-char (point-min))))

(defun fennel-repl (ask-for-command? &optional buffer)
  "Switch to the fennel repl buffer, or start a new one if needed.

If ASK-FOR-COMMAND? was supplied, asks for command to start the REPL.

Return this buffer."
  (interactive "P")
  (if (eq major-mode 'fennel-repl-mode)
      (when fennel-repl--last-fennel-buffer
        (switch-to-buffer-other-window fennel-repl--last-fennel-buffer))
    (let ((last-buf (or buffer (current-buffer)))
          (repl-buf (or (get-buffer fennel-repl--buffer)
                        (fennel-repl--start ask-for-command?))))
      (with-current-buffer repl-buf
        (setq fennel-repl--last-fennel-buffer last-buf))
      (pop-to-buffer repl-buf))))

(defun fennel-format ()
  "Run fnlfmt on the current buffer."
  (interactive)
  (shell-command-on-region (point-min) (point-max) "fnlfmt -" nil t))

(define-key fennel-mode-map (kbd "M-.") 'fennel-find-definition)
(define-key fennel-mode-map (kbd "M-,") 'fennel-find-definition-pop)
(define-key fennel-mode-map (kbd "M-'") 'fennel-find-module-definition)
(define-key fennel-mode-map (kbd "C-c C-k") 'fennel-reload)
(define-key fennel-mode-map (kbd "C-c C-l") 'fennel-view-compilation)
(define-key fennel-mode-map (kbd "C-c C-z") 'fennel-repl)
(define-key fennel-mode-map (kbd "C-c C-t") 'fennel-format)

(put 'lambda 'fennel-indent-function 'defun)
(put 'λ 'fennel-indent-function 'defun)
(put 'fn 'fennel-indent-function 'defun)
(put 'while 'fennel-indent-function 'defun)
(put 'do 'fennel-indent-function 0)
(put 'let 'fennel-indent-function 1)
(put 'when 'fennel-indent-function 1)
(put 'for 'fennel-indent-function 1)
(put 'each 'fennel-indent-function 1)
(put 'eval-compiler 'fennel-indent-function 'defun)
(put 'macro 'fennel-indent-function 'defun)
(put 'doto 'fennel-indent-function 1)
(put 'match 'fennel-indent-function 1)
(put 'with-open 'fennel-indent-function 1)
(put 'collect 'fennel-indent-function 1)
(put 'icollect 'fennel-indent-function 1)
(put 'pick-values 'fennel-indent-function 1)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.fnl\\'" . fennel-mode))

(provide 'fennel-mode)
;;; fennel-mode.el ends here
