;;; julia-formatter.el --- Use JuliaFormatter.jl for julia code  -*- lexical-binding: t; -*-

;; Copyright © 2020  Felipe Lema

;; Author: Felipe Lema <felipe.lema@mortemale.org>
;; Keywords: convenience, tools
;; Package-Version: 20230525.1742
;; Package-Commit: 783df6cf8ef0db7adb4e81b86aa1e17992642493
;; Package-Requires: ((emacs "27.1") (session-async "0.0.4"))
;; URL: https://codeberg.org/FelipeLema/julia-formatter.el
;; Version: 0.3
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Leverage JuliaFormatter.jl to format julia code in Emacs.
;;
;; Provide formatting tools for live coding.  These tools are packed into a
;; service that can be called using JSON-RPC on stdin / stdout.  Exposing
;; JuliaFormatter.jl as a service because the compile time required to get the
;; result of that first format_text() call is considerable and it hinders the
;; coding process.
;;
;; The code that's being formatted must be self-contained (parseable, all if's
;; and while's with a corresponding end).  This is a requirement from
;; JuliaFormatter.jl since it needs to get the AST from the code.
;;
;; The simplest way to use JuliaFormatter.jl is by activating
;; `aggressive-indent-mode' and setting the proper functions
;; (yes, indentation functionality can be leveraged for live formatting))
;;
;; Like so:
;; ;; load this file after downloading this package (or installing with straight.el)
;; (require 'julia-formatter)
;; ;; load aggressive indent and setup appropiate variables
;; (julia-formatter-setup-hooks)
;;
;; See https://github.com/domluna/JuliaFormatter.jl

;; This package requires Emacs 27 because previous version of `replace-buffer-contents' is buggy
;; See https://debbugs.gnu.org/cgi/bugreport.cgi?bug=32237 & https://debbugs.gnu.org/cgi/bugreport.cgi?bug=32278


;;

;;; Code:
;;;
(require 'cl-lib)
(require 'pcase)
(require 'jsonrpc)
(require 'subr-x)
(require 'compile)
(require 'session-async)

(declare-function aggressive-indent-mode "aggressive-indent" t t)

(defgroup julia-formatter nil "JuliaFormatter.jl group."
  :group 'tools)

(defcustom julia-formatter-setup-for-save
  t
  "When non-nil, format before save when julia-formatter-mode is activated."
  :type 'boolean)

(defcustom julia-formatter-should-compile-julia-image
  'always-prompt
  "How to prompt the user for image compilation.

Image compilation is done to avoid the \"freezes Emacs on first formatting\"
problem, also known as \"the first plot problem\".
Compilation will take some minutes, so it's worth doing so in the long run."
  :type '(radio
          (const always-prompt)
          (const never-compile)
          (const always-compile)))

(defvar julia-formatter--server-process-connection
  nil
  "Connection to running server to query for formatter process.")

(defvar-local julia-formatter--config
  `not-fetched
  "Alist with formatter config for this buffer.

Taken from .JuliaFormatter.el.  Accepted values are:
        not-fetched     - should parse config file to save it.
        (fetching . ...) - currently parsing config file.
        ... - the actual alist with config")

(defun julia-formatter--get-config-for-buffer ()
  "Return alist representing config for this buffer.

Alist represents key-value pairs from .JuliaFormatter.toml.
Leverages `julia-formatter--config' to cache the config value."
  (setq-local julia-formatter--config
              (pcase julia-formatter--config
                (`not-fetched
                 (iter-next
                  (julia-formatter--parsed-toml-future)))
                (`(fetching . ,future)
                 (iter-next future))
                (config-alist
                 config-alist))))

(defsubst julia-formatter--package-directory ()
  "Return directory for `julia-formatter' package.

Useful for loading Julia scripts and such."
  (let ((this-package-directory
         (file-name-as-directory
          (file-name-directory
           (or
            (locate-library "julia-formatter")
            ;; https://stackoverflow.com/a/1344894
            (symbol-file 'julia-formatter-compile-image))))))
    (cl-assert this-package-directory)
    this-package-directory))


(defun julia-formatter--parsed-toml-future ()
  "Parse toml file in background process."
  (session-async-future
   `(lambda ()
      (require 'subr-x)
      (when-let* ((toml-file-directory
                   (locate-dominating-file ,default-directory ".JuliaFormatter.toml"))
                  (toml-file-path
                   (concat
                    (file-name-as-directory
                     (expand-file-name
                      toml-file-directory))
                    ".JuliaFormatter.toml"))
                  (default-directory ,(julia-formatter--package-directory)))
        ;; toml → json → alist
        (thread-first
          (format
           "julia --project=. --startup-file=no -e 'using Pkg.TOML: parsefile; using JSON; JSON.print(parsefile(\"%s\"))'"
           toml-file-path)
          (shell-command-to-string)
          (json-parse-string
           ;; matches `jsonrpc--json-encode'
           :false-object :json-false
           :null-object nil))))))

(defsubst julia-formatter--server-running-p ()
  "Return non-nil if server is running."
  (and julia-formatter--server-process-connection
       (jsonrpc-running-p julia-formatter--server-process-connection)))

(defsubst julia-formatter--shutdown-server-if-running ()
  "Shutdown server, but only if running.

If not running, do nothing."
  (when (julia-formatter--server-running-p)
    (jsonrpc-shutdown julia-formatter--server-process-connection)))

;;;###autoload
(defun julia-formatter-compile-image ()
  "Pull up a buffer to compile image.

Returns t."
  (interactive)
  (let* ((default-directory (julia-formatter--package-directory)))
    (switch-to-buffer-other-window
     (cl-flet ((_jcmd (args-as-string)
                      (format "julia --color=no --project=. --startup-file=no %s" args-as-string)))
       (compile (string-join
                 (list
                  (format "cd %s" default-directory)
                  "set -xv"
                  (_jcmd "-e 'using Pkg;Pkg.instantiate()'")
                  (_jcmd "--trace-compile=formatter_service_precompile.jl -e 'using JSON; using JuliaFormatter; using CSTParser; JSON.json(JSON.parse(\"{\\\"a\\\":[1,2]}\"));format_text(\"Channel()\"); CSTParser.parse(\"Channel()\")'")
                  (_jcmd "-e 'using PackageCompiler;PackageCompiler.create_sysimage([\"JSON\", \"JuliaFormatter\", \"CSTParser\"],sysimage_path=\"formatter_service_sysimage.so\", precompile_statements_file=\"formatter_service_precompile.jl\")'"))
                 " \\\n && "))))
    t))

(defun julia-formatter--should-use-image ()
  "Return non-nil if should run server with pre-compiled image."
  (if (let ((default-directory (julia-formatter--package-directory)))
        (file-exists-p "formatter_service_sysimage.so"))
      t
    ;; file does not exist... should it?
    (pcase julia-formatter-should-compile-julia-image
      (`always-prompt
       (when (y-or-n-p "Would you like to pre-compile Julia image (takes time, still recommended)?")
         (julia-formatter-compile-image)))
      (`never-compile
       nil)
      (`always-compile
       (julia-formatter-compile-image))
      (_ (error "Unexpected value for `julia-formatter-should-compile-julia-image'")))
    ;; return nil because image file does not exist (just yet)
    nil))

(defun julia-formatter--ensured-server ()
  "Make sure the formatter service is running.

If it's up and running, do nothing."
  (let ((default-directory (julia-formatter--package-directory)))
    (unless (julia-formatter--server-running-p)
      (setq julia-formatter--server-process-connection
            (make-instance
             'jsonrpc-process-connection
             :name "julia formatter server"
             :on-shutdown (lambda (_conn)
                            (message "Julia formatter disconnected"))
             :process (lambda ()
                        (make-process
                         :name "julia formatter server"
                         :command
                         (append
                          `("julia")
                          `("--project=." "--startup-file=no")
                          (when (julia-formatter--should-use-image)
                            `("--sysimage=formatter_service_sysimage.so"))
                          `("formatter_service.jl"))
                         :connection-type 'pipe
                         :coding 'utf-8-emacs-unix
                         :noquery t
                         :stderr (get-buffer-create
                                  "*julia formatter server stderr*"))))))))

;;;###autoload
(defun julia-formatter-format-region (begin end)
  "Format region delimited by BEGIN and END  using JuliaFormatter.jl.

Region must have self-contained code.  If not, the region won't be formatted and
will remain as-is."
  (let* ((text-to-be-formatted
          (buffer-substring-no-properties
           begin end))
         (relative-current-line ;; line number, but relative to BEGIN
          (1+
           (-
            (line-number-at-pos)
            (line-number-at-pos begin))))
         (response (jsonrpc-request
                    julia-formatter--server-process-connection
                    :format
                    (list :text
                          (save-match-data
                            (thread-first text-to-be-formatted
                                          (split-string "\n" nil)
                                          (vconcat)))
                          :current_line relative-current-line
                          :toml_config (julia-formatter--get-config-for-buffer))))
         (as-formatted (mapconcat #'identity response "\n")))
    ;; replace text
    (save-excursion
      (let ((formatting-buffer (current-buffer)))
        (with-temp-buffer
          (insert as-formatted)
          (let ((formatted-region-buffer (current-buffer)))
            (with-current-buffer formatting-buffer
              (save-restriction
                (narrow-to-region begin end)
                (replace-buffer-contents
                 formatted-region-buffer)))))))))

(defun julia-formatter--defun-range ()
  "Send buffer to service, gen [begin end] of surrounding defun."
  (let ((response (jsonrpc-request
                   julia-formatter--server-process-connection
                   :defun_range
                   (list :text
                         (save-match-data
                           (thread-first
                             (buffer-substring-no-properties
                              (point-min) (point-max))
                             (split-string "\n" nil)
                             (vconcat)))
                         :position (point)))))
    response))

;;;###autoload
(cl-defun julia-formatter-beginning-of-defun (&optional (arg 1))
  "Get beginning of surrounding debufn from `julia-formatter--defun-range'.

Move to the ARG -th beginning of defun."
  (pcase (julia-formatter--defun-range)
    (`[,begin ,_]
     (if  (or
           (< 1 arg)
           (<= (line-beginning-position) begin (line-end-position)));; already at begin-of-defun?
         (progn
           ;; move backwards
           (forward-line -1)
           (julia-formatter-beginning-of-defun
            (if (< 1 arg)
                (- arg 1)
              arg)))
       ;; this is the actual place I wont to jump to… go!
       (goto-char begin)))))

;;;###autoload
(cl-defun julia-formatter-end-of-defun (&optional
                                        (arg 1))
  "Get beginning of surrounding debufn from `julia-formatter--defun-range'.

See `end-of-defun-function' to understand values of ARG."
  (pcase (julia-formatter--defun-range)
    (`[,_ ,end]
     (if (or
          (< 1 arg)
          (<= (line-beginning-position) end (line-end-position))) ;; already at end-of-defun?
         (progn
           ;; move forward to next end-defun
           (forward-line 1)
           (julia-formatter-end-of-defun
            (if (< 1 arg)
                (- arg 1)
              arg)))
       ;; this is the actual place I wont to jump to… go!
       (goto-char end)))))

;;;###autoload
(defun julia-formatter-format-buffer ()
  "Format the whole buffer."
  (save-restriction
    (widen)
    (julia-formatter-format-region
     (point-min)
     (point-max))))

;;;###autoload
(define-minor-mode julia-formatter-mode
  "Setup buffer for formatting code using indenting functions.

See documentation on `indent-region-function' for different ways you can indent
current buffer (by line, by region, whole buffer ...)

When `julia-formatter-setup-for-save' is non-nil, will format buffer before
saving."
  :lighter " fmt.jl"

  (julia-formatter--ensured-server)

  (setq-local beginning-of-defun-function
              (if julia-formatter-mode
                  #'julia-formatter-beginning-of-defun
                (default-value beginning-of-defun-function)))
  (setq-local end-of-defun-function
              (if julia-formatter-mode
                  #'julia-formatter-end-of-defun
                (default-value end-of-defun-function)))
  (setq-local indent-region-function
              (if julia-formatter-mode
                  #'julia-formatter-format-region
                (default-value indent-region-function)))
  (setq-local julia-formatter--config
              `(fetching . ,(julia-formatter--parsed-toml-future)))
  (when (boundp 'aggressive-indent-modes-to-prefer-defun)
    (add-hook 'aggressive-indent-modes-to-prefer-defun 'julia-mode))
  (if julia-formatter-mode
      (add-hook 'before-save-hook #'julia-formatter-format-buffer nil t)
    (remove-hook 'before-save-hook #'julia-formatter-format-buffer t)))

(provide 'julia-formatter)
;;; julia-formatter.el ends here
