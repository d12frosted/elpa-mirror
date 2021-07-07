;;; mocha.el --- Run Mocha or Jasmine tests

;; Copyright (C) 2016 Al Scott <github.com/scottaj>
;; Author: Al Scott
;; URL: http://github.com/scottaj/mocha.el
;; Package-Version: 20160224.359
;; Package-Commit: 4ca9495d4b00b753f055152bd4256c07d7b208f4
;; Created: 2016
;; Version: 1.1
;; Keywords: javascript mocha jasmine
;; Package-Requires: ((js2-mode "20150909"))

;; This file is NOT part of GNU Emacs.
;;
;;; Commentary:
;;
;; This mode provides the ability to run Mocha or Jasmine tests from within Emacs

;;; Code:
(require 'compile)
(require 'js2-mode)

(defgroup mocha nil
  "Tools for running mocha tests."
  :group 'tools)

(defcustom mocha-which-node "node"
  "The path to the node executable to run."
  :type 'string
  :group 'mocha)

(defcustom mocha-command "mocha"
  "The path to the mocha command to run."
  :type 'string
  :group 'mocha)

(defcustom mocha-environment-variables nil
  "Environment variables to run mocha with."
  :type 'string
  :group 'mocha)

(defcustom mocha-options nil
  "Command line options to pass to mocha."
  :type 'string
  :group 'mocha)

(defcustom mocha-debug-port "5858"
  "The port number to debug mocha tests at."
  :type 'string
  :group 'mocha)

(defvar mocha-project-test-directory nil)

(defvar node-error-regexp
  "^[  ]+at \\(?:[^\(\n]+ \(\\)?\\([a-zA-Z\.0-9_/-]+\\):\\([0-9]+\\):\\([0-9]+\\)\)?$"
  "Regular expression to match NodeJS errors.
From http://benhollis.net/blog/2015/12/20/nodejs-stack-traces-in-emacs-compilation-mode/")

(defvar node-error-regexp-alist
  `((,node-error-regexp 1 2 3)))

(defun mocha-compilation-filter ()
  "Filter function for compilation output."
  (ansi-color-apply-on-region compilation-filter-start (point-max)))

(define-compilation-mode mocha-compilation-mode "Mocha"
  "Mocha compilation mode."
  (progn
    (set (make-local-variable 'compilation-error-regexp-alist) node-error-regexp-alist)
    (add-hook 'compilation-filter-hook 'mocha-compilation-filter nil t)
  ))

(defun mocha-find-project-root ()
  "Find the root of the project."
  (let ((root-files '(".git" ".hg" ".svn" "package.json")) (dir nil) (i 0))
    (while (not dir)
      (setq dir (locate-dominating-file default-directory (nth i root-files)))
      (setq i (+ i 1)))
    dir))

(defun mocha-generate-command (debug &optional mocha-file test)
  "The test command to run.

If DEBUG is true, then make this a debug command.

If MOCHA-FILE is specified run just that file otherwise run
MOCHA-PROJECT-TEST-DIRECTORY.

IF TEST is specified run mocha with a grep for just that test."
  (let ((path (or mocha-file mocha-project-test-directory))
        (target (if test (concat "--grep \"" test "\" ") ""))
        (node-command (concat mocha-which-node (if debug (concat " --debug=" mocha-debug-port) "")))
        (options (concat mocha-options (if debug " -t 21600000"))))
    (concat mocha-environment-variables " "
            node-command " "
            mocha-command " "
            options " "
            target
            path)))

(defun mocha-debug (&optional mocha-file test)
  "Debug mocha using realgud.

If MOCHA-FILE is specified run just that file otherwise run
MOCHA-PROJECT-TEST-DIRECTORY.

IF TEST is specified run mocha with a grep for just that test."
  (if (not (fboundp 'realgud:nodejs))
      (message "realgud is required to debug mocha")
    (save-some-buffers (not compilation-ask-about-save)
                     (when (boundp 'compilation-save-buffers-predicate)
                       compilation-save-buffers-predicate))

  (when (get-buffer "*mocha tests: debug*")
    (kill-buffer "*mocha tests: debug*"))
  (let ((test-command-to-run (mocha-generate-command t mocha-file test))
        (root-dir (mocha-find-project-root))
        (debug-command (concat mocha-which-node " debug localhost:" mocha-debug-port)))
    (with-current-buffer (get-buffer-create "*mocha tests: debug*")
      (setq default-directory root-dir)
      (compilation-start test-command-to-run 'mocha-compilation-mode (lambda (m) (buffer-name)))
      (realgud:nodejs debug-command)))))

(defun mocha-run (&optional mocha-file test)
  "Run mocha in a compilation buffer.

If MOCHA-FILE is specified run just that file otherwise run
MOCHA-PROJECT-TEST-DIRECTORY.

IF TEST is specified run mocha with a grep for just that test."
  (save-some-buffers (not compilation-ask-about-save)
                     (when (boundp 'compilation-save-buffers-predicate)
                       compilation-save-buffers-predicate))

  (when (get-buffer "*mocha tests*")
    (kill-buffer "*mocha tests*"))
  (let ((test-command-to-run (mocha-generate-command nil mocha-file test)) (root-dir (mocha-find-project-root)))
    (with-current-buffer (get-buffer-create "*mocha tests*")
      (setq default-directory root-dir)
      (compilation-start test-command-to-run 'mocha-compilation-mode (lambda (m) (buffer-name))))))

(defun mocha-walk-up-to-it (node)
  "Recursively walk up the ast from the js2-node NODE.

Stops when we find a call node named 'describe' or 'it' or reach the root.

If we find the name node we are looking for, return the first argument of the
 call node.

If we reach the root without finding what we are looking for return nil."
  (if (and (js2-node-p node) (not (js2-ast-root-p node)))
      (let ((calls '("describe" "it")))
        (if (and
             ;; If the node is an expression or statement
             (js2-expr-stmt-node-p node)
             ;; And the expression is a function calL
             (js2-call-node-p (js2-expr-stmt-node-expr node))
             ;; And the call target is a name node
             (js2-name-node-p (js2-call-node-target (js2-expr-stmt-node-expr node)))
             ;; And the name of the name node is what we are looking for
             (member (js2-name-node-name (js2-call-node-target (js2-expr-stmt-node-expr node))) calls))
            ;; Get the first argument, check it is a string and return its value
            (let ((first-arg (car (js2-call-node-args (js2-expr-stmt-node-expr node)))))
              (if (js2-string-node-p first-arg)
                  (js2-string-node-value first-arg)
                nil))
          (mocha-walk-up-to-it (js2-node-parent-stmt node))))
    nil))

(defun mocha-find-current-test ()
  "Try to find the innermost 'describe' or 'it' using js2-mode.

When a 'describe' or 'it' is found, return the first argument of that call.
If js2-mode is not enabled in the buffer, returns nil.
If there is no wrapping 'describe' or 'it' found, return nil."
  (if (string= major-mode "js2-mode")
      (let ((node (js2-node-at-point)))
        (mocha-walk-up-to-it node))
    (progn
      (message "js2-mode must be enabled to run test at point.")
      nil)))

;;;###autoload
(defun mocha-test-project ()
  "Test the current project."
  (interactive)
  (mocha-run))

;;;###autoload
(defun mocha-debug-project ()
  "Debug the current project."
  (interactive)
  (mocha-debug))

;;;###autoload
(defun mocha-test-file ()
  "Test the current file."
  (interactive)
  (mocha-run (buffer-file-name)))

;;;###autoload
(defun mocha-debug-file ()
  "Debug the current file."
  (interactive)
  (mocha-debug (buffer-file-name)))

;;;###autoload
(defun mocha-test-at-point ()
  "Test the current innermost 'it' or 'describe' or the file if none is found."
  (interactive)
  (let ((file (buffer-file-name)) (test-at-point (mocha-find-current-test)))
    (mocha-run file test-at-point)))

;;;###autoload
(defun mocha-debug-at-point ()
  "Debug the current innermost 'it' or 'describe' or the file if none is found."
  (interactive)
  (let ((file (buffer-file-name)) (test-at-point (mocha-find-current-test)))
    (mocha-debug file test-at-point)))

(provide 'mocha)
;;; mocha.el ends here
