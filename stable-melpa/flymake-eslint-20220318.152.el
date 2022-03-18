;;; flymake-eslint.el --- A Flymake backend for Javascript using eslint -*- lexical-binding: t; -*-

;;; Version: 1.6.0
;; Package-Version: 20220318.152
;; Package-Commit: bfcf28259c7d774b259a6ed122f1f0936a5b96b9

;;; Author: Dan Orzechowski
;;; Contributor: Terje Larsen

;;; URL: https://github.com/orzechowskid/flymake-eslint

;;; Package-Requires: ((emacs "26.0"))

;;; Commentary:
;; A backend for Flymake which uses eslint.  Enable it with `M-x flymake-eslint-enable [RET]'.
;; Alternately, configure a mode-hook for your Javascript major mode of choice:
;;
;; (add-hook 'some-js-major-mode-hook
;;   (lambda () (flymake-eslint-enable))
;;
;; A handful of configurable options can be found in the `flymake-eslint' customization group: view and modify them with the command `M-x customize-group [RET] flymake-eslint [RET]'.

;;; License: MIT

;;; Code:


;; our own customization group


(defgroup flymake-eslint nil
  "Flymake checker for Javascript using eslint"
  :group 'programming
  :prefix "flymake-eslint-")


;; useful variables


(defcustom flymake-eslint-executable-name "eslint"
  "Name of executable to run when checker is called.  Must be present in variable `exec-path'."
  :type 'string
  :group 'flymake-eslint)

(defcustom flymake-eslint-executable-args nil
  "Extra arguments to pass to eslint."
  :type '(choice string (repeat string))
  :group 'flymake-eslint)

(defcustom flymake-eslint-show-rule-name t
  "Set to t to append rule name to end of warning or error message, nil otherwise."
  :type 'boolean
  :group 'flymake-eslint)

(defcustom flymake-eslint-defer-binary-check nil
  "Set to t to bypass the initial check which ensures eslint is present.

Useful when the value of variable `exec-path' is set dynamically and the location of eslint might not be known ahead of time."
  :type 'boolean
  :group 'flymake-eslint)


;; useful buffer-local variables


(defcustom flymake-eslint-project-root nil
  "Buffer-local.  Set to a filesystem path to use that path as the current working directory of the linting process."
  :type 'string
  :group 'flymake-eslint)


;; internal variables


(defvar flymake-eslint--message-regex "^[[:space:]]*\\([0-9]+\\):\\([0-9]+\\)[[:space:]]+\\(warning\\|error\\)[[:space:]]+\\(.+?\\)[[:space:]]\\{2,\\}\\(.*\\)$"
  "Internal variable.
Regular expression definition to match eslint messages.")

(defvar-local flymake-eslint--process nil
  "Internal variable.
Handle to the linter process for the current buffer.")


;; internal functions


(defun flymake-eslint--executable-args ()
  "Return a list of strings for additional arguments to pass to `flymake-eslint-executable-name'.
Return `flymake-eslint-executable-args' if it is a list and a
list containing `flymake-eslint-executable-args' if it isn't."
  (if (listp flymake-eslint-executable-args)
      flymake-eslint-executable-args
    (list flymake-eslint-executable-args)))

(defun flymake-eslint--ensure-binary-exists ()
  "Internal function.
Throw an error and tell REPORT-FN to disable itself if `flymake-eslint-executable-name' can't be found on variable `exec-path'"
  (unless (executable-find flymake-eslint-executable-name)
    (error (message "can't find '%s' in exec-path - try M-x set-variable flymake-eslint-executable-name maybe?" flymake-eslint-executable-name))))

(defun flymake-eslint--report (eslint-stdout-buffer source-buffer)
  "Internal function.
Create Flymake diag messages from contents of ESLINT-STDOUT-BUFFER, to be reported against SOURCE-BUFFER.  Returns a list of results"
  (with-current-buffer eslint-stdout-buffer
    ;; start at the top and check each line for an eslint message
    (goto-char (point-min))
    (if (looking-at-p "Error:")
        (let ((diag (flymake-make-diagnostic source-buffer (point-min) (point-max) :error (thing-at-point 'line t))))
          ;; ehhhhh point-min and point-max here are of the eslint output buffer
          ;; containing the error message, not source-buffer
          (list diag))
      (let ((results '()))
        (while (not (eobp))
          (when (looking-at flymake-eslint--message-regex)
            (let* ((row (string-to-number (match-string 1)))
                   (column (string-to-number (match-string 2)))
                   (type (match-string 3))
                   (msg (match-string 4))
                   (lint-rule (match-string 5))
	           (msg-text (if flymake-eslint-show-rule-name
                                 (format "%s: %s [%s]" type msg lint-rule)
                               (format "%s: %s" type msg)))
                   (type-symbol (if (string-equal "warning" type) :warning :error))
                   (src-pos (flymake-diag-region source-buffer row column)))
              ;; new Flymake diag message
              (push (flymake-make-diagnostic source-buffer
                                             (car src-pos)
                                             ;; buffer might have changed size
                                             (min (buffer-size source-buffer) (cdr src-pos))
                                             type-symbol
                                             msg-text
                                             (list :rule-name lint-rule))
                    results)))
          (forward-line 1))
        results))))

;; heavily based on the example found at
;; https://www.gnu.org/software/emacs/manual/html_node/flymake/An-annotated-example-backend.html
(defun flymake-eslint--create-process (source-buffer callback)
  "Internal function.
Create linter process for SOURCE-BUFFER which invokes CALLBACK once linter is finished.  CALLBACK is passed one argument, which is a buffer containing stdout from linter."
  (when (process-live-p flymake-eslint--process)
    (kill-process flymake-eslint--process))
  (let ((default-directory (or flymake-eslint-project-root default-directory)))
    (setq flymake-eslint--process
          (make-process
           :name "flymake-eslint"
           :connection-type 'pipe
           :noquery t
           :buffer (generate-new-buffer " *flymake-eslint*")
           :command `(,flymake-eslint-executable-name "--no-color" "--no-ignore" "--stdin" "--stdin-filename" ,(buffer-file-name source-buffer) ,@(flymake-eslint--executable-args))
           :sentinel (lambda (proc &rest ignored)
                       ;; do stuff upon child process termination
                       (when (and (eq 'exit (process-status proc))
                                  ;; make sure we're not using a deleted buffer
                                  (buffer-live-p source-buffer)
                                  ;; make sure we're using the latest lint process
                                  (with-current-buffer source-buffer (eq proc flymake-eslint--process)))
                         ;; read from eslint output then destroy temp buffer when done
                         (let ((proc-buffer (process-buffer proc)))
                           (funcall callback proc-buffer)
                           (kill-buffer proc-buffer))))))))

(defun flymake-eslint--check-and-report (source-buffer flymake-report-fn)
  "Internal function.
Run eslint against SOURCE-BUFFER and use FLYMAKE-REPORT-FN to report results."
  (if flymake-eslint-defer-binary-check
      (flymake-eslint--ensure-binary-exists))
  (flymake-eslint--create-process
   source-buffer
   (lambda (eslint-stdout)
     (funcall flymake-report-fn (flymake-eslint--report eslint-stdout source-buffer))))
  (with-current-buffer source-buffer
    (process-send-string flymake-eslint--process (buffer-string))
    (process-send-eof flymake-eslint--process)))

(defun flymake-eslint--checker (flymake-report-fn &rest ignored)
  "Internal function.
Run eslint on the current buffer, and report results using FLYMAKE-REPORT-FN.  All other parameters are currently IGNORED."
  (flymake-eslint--check-and-report (current-buffer) flymake-report-fn))


;; module entry point


;;;###autoload
(defun flymake-eslint-enable ()
  "Enable Flymake and add flymake-eslint as a buffer-local Flymake backend."
  (interactive)
  (if (not flymake-eslint-defer-binary-check)
      (flymake-eslint--ensure-binary-exists))
  (make-local-variable 'flymake-eslint-project-root)
  (flymake-mode t)
  (add-hook 'flymake-diagnostic-functions 'flymake-eslint--checker nil t))


(provide 'flymake-eslint)


;;; flymake-eslint.el ends here
