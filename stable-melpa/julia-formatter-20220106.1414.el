;;; julia-formatter.el --- Use JuliaFormatter.jl for julia code  -*- lexical-binding: t; -*-

;; Copyright © 2020  Felipe Lema

;; Author: Felipe Lema <felipe.lema@mortemale.org>
;; Keywords: convenience, tools
;; Package-Version: 20220106.1414
;; Package-Commit: a17490fbf8902fc11827651f567924edb22f81cb
;; Package-Requires: ((emacs "27.1"))
;; URL: https://codeberg.org/FelipeLema/julia-formatter.el
;; Version: 0.2
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

(declare-function aggressive-indent-mode "aggressive-indent" t t)

(defgroup julia-formatter nil "JuliaFormatter.jl group."
  :group 'tools)

(defcustom julia-formatter-setup-for-save
  t
  "When non-nil, format before save when julia-formatter-mode is activated."
  :type 'boolean)

(defvar julia-formatter--server-process-connection
  nil
  "Connection to running server to query for formatter process.

I recommend using JuliaFormatter.jl as a global service because the service has
slow startup and quick response.")

(defun julia-formatter--ensure-server ()
  "Make sure the formatter service is running.

If it's up and running, do nothing."
  (let ((default-directory ;; run at the basename of this script file
         (file-name-as-directory
          (file-name-directory
           (or
            (locate-library "julia-formatter")
            ;; https://stackoverflow.com/a/1344894
            (symbol-file 'julia-formatter--ensure-server))))))
    (unless (and julia-formatter--server-process-connection
                 (jsonrpc-running-p julia-formatter--server-process-connection))
      (setq julia-formatter--server-process-connection
            (make-instance
             'jsonrpc-process-connection
             :name "julia formatter server"
             :on-shutdown (lambda (_conn)
                            (message "Julia formatter disconnected"))
             :process (lambda ()
                        (make-process
                         :name "julia formatter server"
                         :command (list "julia"
                                        "--project=."
                                        "formatter_service.jl")
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
  (julia-formatter--ensure-server)
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
                                          (split-string  "\n" nil)
                                          (vconcat)))
                          :current_line relative-current-line)))
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
  (julia-formatter--ensure-server)
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
  "Format the whole buffer"
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
  (julia-formatter--ensure-server)
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
  (when (boundp 'aggressive-indent-modes-to-prefer-defun)
    (add-hook 'aggressive-indent-modes-to-prefer-defun 'julia-mode))
  (if julia-formatter-mode
      (add-hook 'before-save-hook #'julia-formatter-format-buffer nil t)
    (remove-hook 'before-save-hook #'julia-formatter-format-buffer t)))

(provide 'julia-formatter)
;;; julia-formatter.el ends here
