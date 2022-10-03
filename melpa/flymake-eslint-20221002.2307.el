;;; flymake-eslint.el --- A Flymake backend for Javascript using eslint  -*- lexical-binding: t; -*-

;; Version: 1.6.0
;; Package-Version: 20221002.2307
;; Package-Commit: efbf9e1fcc6ba4959c4ad0435742c96099f4f96f
;; Author: Dan Orzechowski
;; Contributor: Terje Larsen
;; URL: https://github.com/orzechowskid/flymake-eslint
;; Package-Requires: ((emacs "26.1"))
;; Keywords: languages, tools

;;; Commentary:

;; A backend for Flymake which uses eslint.  Enable it with M-x
;; flymake-eslint-enable RET.  Alternately, configure a mode-hook for your
;; Javascript major mode of choice:

;; (add-hook 'some-js-major-mode-hook #'flymake-eslint-enable)

;; A handful of configurable options can be found in the flymake-eslint
;; customization group: view and modify them with the M-x customize-group RET
;; flymake-eslint RET.

;; License: MIT

;;; Code:

;;;; Requirements

(require 'cl-lib)

;;;; Customization

(defgroup flymake-eslint nil
  "Flymake checker for Javascript using eslint."
  :group 'programming
  :prefix "flymake-eslint-")

(defcustom flymake-eslint-executable-name "eslint"
  "Name of executable to run when checker is called.
Must be present in variable `exec-path'."
  :type 'string
  :group 'flymake-eslint)

(defcustom flymake-eslint-executable-args nil
  "Extra arguments to pass to eslint."
  :type '(choice string (repeat string))
  :group 'flymake-eslint)

(defcustom flymake-eslint-show-rule-name t
  "When non-nil show eslint rule name in flymake diagnostic."
  :type 'boolean
  :group 'flymake-eslint)

(defcustom flymake-eslint-defer-binary-check nil
  "Defer the eslint binary presence check.
When non-nil, the initial check, which ensures that eslint binary
is present, is disabled.  Instead, this check is performed during
backend execution.

Useful when the value of variable `exec-path' is set dynamically
and the location of eslint might not be known ahead of time."
  :type 'boolean
  :group 'flymake-eslint)

(defcustom flymake-eslint-project-root nil
  "Buffer-local.
Set to a filesystem path to use that path as the current working
directory of the linting process."
  :type 'string
  :group 'flymake-eslint)

;;;; Variables

(defvar flymake-eslint--message-regexp
  (rx bol (* space) (group (+ num)) ":" (group (+ num)) ; line:col
      (+ space) (group (or "error" "warning"))          ; type
      (+ space) (group (+? any))                        ; message
      (>= 2 space) (group (* any)) eol)                 ; rule name
  "Regexp to match eslint messages.")

(defvar-local flymake-eslint--process nil
  "Handle to the linter process for the current buffer.")

;;;; Functions

;;;;; Public

;;;###autoload
(defun flymake-eslint-enable ()
  "Enable Flymake and flymake-eslint.
Add this function to some js major mode hook."
  (interactive)
  (unless flymake-eslint-defer-binary-check
    (flymake-eslint--ensure-binary-exists))
  (make-local-variable 'flymake-eslint-project-root)
  (flymake-mode t)
  (add-hook 'flymake-diagnostic-functions 'flymake-eslint--checker nil t))

;;;;; Private

(defun flymake-eslint--executable-args ()
  "Get additional arguments for `flymake-eslint-executable-name'.
Return `flymake-eslint-executable-args' value and ensure that
this is a list."
  (if (listp flymake-eslint-executable-args)
      flymake-eslint-executable-args
    (list flymake-eslint-executable-args)))

(defun flymake-eslint--ensure-binary-exists ()
  "Ensure that `flymake-eslint-executable-name' exists.
Otherwise, throw an error and tell Flymake to disable this
backend if `flymake-eslint-executable-name' can't be found in
variable `exec-path'"
  (unless (executable-find flymake-eslint-executable-name)
    (let ((option 'flymake-eslint-executable-name))
      (error "Can't find \"%s\" in exec-path - try to configure `%s'"
             (symbol-value option) option))))

(defun flymake-eslint--report (eslint-stdout-buffer source-buffer)
  "Create Flymake diag messages from contents of ESLINT-STDOUT-BUFFER.
They are reported against SOURCE-BUFFER.  Return a list of
results."
  (with-current-buffer eslint-stdout-buffer
    ;; start at the top and check each line for an eslint message
    (goto-char (point-min))
    (if (looking-at-p "Error:")
        (pcase-let ((`(,beg . ,end) (with-current-buffer source-buffer
                                      (cons (point-min) (point-max))))
                    (msg (thing-at-point 'line t)))
          (list (flymake-make-diagnostic source-buffer beg end :error msg)))
      (cl-loop
       until (eobp)
       when (looking-at flymake-eslint--message-regexp)
       collect (let* ((row (string-to-number (match-string 1)))
                      (column (string-to-number (match-string 2)))
                      (type (match-string 3))
                      (msg (match-string 4))
                      (lint-rule (match-string 5))
                      (msg-text (concat (format "%s: %s" type msg)
                                        (when flymake-eslint-show-rule-name
                                          (format " [%s]" lint-rule))))
                      (type-symbol (pcase type ("warning" :warning) (_ :error)))
                      (src-pos (flymake-diag-region source-buffer row column)))
                 ;; new Flymake diag message
                 (flymake-make-diagnostic
                  source-buffer
                  (car src-pos)
                  ;; buffer might have changed size
                  (min (buffer-size source-buffer) (cdr src-pos))
                  type-symbol
                  msg-text
                  (list :rule-name lint-rule)))
       do (forward-line 1)))))

;; Heavily based on the example found at
;; https://www.gnu.org/software/emacs/manual/html_node/flymake/An-annotated-example-backend.html
(defun flymake-eslint--create-process (source-buffer callback)
  "Create linter process for SOURCE-BUFFER.
CALLBACK is invoked once linter has finished the execution.
CALLBACK accepts a buffer containing stdout from linter as its
argument."
  (when (process-live-p flymake-eslint--process)
    (kill-process flymake-eslint--process))
  (let ((default-directory (or flymake-eslint-project-root default-directory)))
    (setq flymake-eslint--process
          (make-process
           :name "flymake-eslint"
           :connection-type 'pipe
           :noquery t
           :buffer (generate-new-buffer " *flymake-eslint*")
           :command `(,flymake-eslint-executable-name
                      "--no-color" "--no-ignore" "--stdin" "--stdin-filename"
                      ,(buffer-file-name source-buffer)
                      ,@(flymake-eslint--executable-args))
           :sentinel
           (lambda (proc &rest ignored)
             ;; do stuff upon child process termination
             (when (and (eq 'exit (process-status proc))
                        ;; make sure we're not using a deleted buffer
                        (buffer-live-p source-buffer)
                        ;; make sure we're using the latest lint process
                        (eq proc (buffer-local-value 'flymake-eslint--process
                                                     source-buffer)))
               ;; read from eslint output then destroy temp buffer when done
               (let ((proc-buffer (process-buffer proc)))
                 (funcall callback proc-buffer)
                 (kill-buffer proc-buffer))))))))

(defun flymake-eslint--check-and-report (source-buffer report-fn)
  "Run eslint against SOURCE-BUFFER.
Use REPORT-FN to report results."
  (when flymake-eslint-defer-binary-check
    (flymake-eslint--ensure-binary-exists))
  (flymake-eslint--create-process
   source-buffer
   (lambda (eslint-stdout)
     (funcall report-fn (flymake-eslint--report eslint-stdout source-buffer))))
  (with-current-buffer source-buffer
    (process-send-string flymake-eslint--process (buffer-string))
    (process-send-eof flymake-eslint--process)))

(defun flymake-eslint--checker (report-fn &rest _ignored)
  "Run eslint on the current buffer.
Report results using REPORT-FN.  All other parameters are
currently ignored."
  (flymake-eslint--check-and-report (current-buffer) report-fn))

;;;; Footer

(provide 'flymake-eslint)

;;; flymake-eslint.el ends here
