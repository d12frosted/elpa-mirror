;;; exunit.el --- ExUnit test runner -*- lexical-binding: t -*-

;; Copyright (C) 2015 Anantha Kumaran.

;; Author: Anantha kumaran <ananthakumaran@gmail.com>
;; URL: http://github.com/ananthakumaran/exunit.el
;; Package-Version: 20210222.1453
;; Package-Commit: 5bb115f3270cfe29d36286da889f0ee5bba03cfd
;; Version: 0.1
;; Keywords: processes elixir exunit
;; Package-Requires: ((s "1.11.0") (emacs "24.3") (f "0.20.0"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides commands to run ExUnit tests.  The output is properly
;; syntax highlighted and stacktraces are navigatable

;;; Code:

(require 's)
(require 'f)
(require 'ansi-color)
(require 'compile)

;;; Private

(define-prefix-command 'exunit-mode-keymap)
(define-key exunit-mode-keymap (kbd "a") 'exunit-verify-all)
(define-key exunit-mode-keymap (kbd "s") 'exunit-verify-single)
(define-key exunit-mode-keymap (kbd "v") 'exunit-verify)
(define-key exunit-mode-keymap (kbd "d") 'exunit-debug)
(define-key exunit-mode-keymap (kbd "r") 'exunit-rerun)
(define-key exunit-mode-keymap (kbd "u") 'exunit-verify-all-in-umbrella)
(define-key exunit-mode-keymap (kbd "t") 'exunit-toggle-file-and-test)
(define-key exunit-mode-keymap (kbd "4 t") 'exunit-toggle-file-and-test-other-window)

(defcustom exunit-mix-test-default-options '()
  "List of options that gets passed to the mix test command."
  :type '(repeat string)
  :group 'exunit)

(defcustom exunit-environment '()
  "List of environment variables used when running mix test.
Each element should be a string of the form ENVVARNAME=VALUE."
  :type '(repeat (string :tag "ENVVARNAME=VALUE"))
  :group 'exunit)

(defcustom exunit-prefer-async-tests nil
  "Whether to generate async test modules."
  :type 'boolean
  :group 'exunit)

(defcustom exunit-key-command-prefix  (kbd "C-c ,")
  "The prefix for all exunit related key commands."
  :type 'string
  :group 'exunit)

(defvar exunit-last-directory nil
  "Directory the last mix test command ran in.")

(defvar exunit-last-arguments nil
  "Arguments passed to `exunit-do-compile' at the last invocation.")

(defvar-local exunit-project-root nil)

(defvar-local exunit-umbrella-project-root nil)

(defun exunit-project-root ()
  "Return the current project root.

This value is cached in a buffer local to avoid filesytem access
on every call."
  (or
   exunit-project-root
   (let ((root (locate-dominating-file default-directory "mix.exs")))
     (unless root
       (error "Couldn't locate project root folder.  Make sure the current file is inside a project"))
     (setq exunit-project-root (expand-file-name root)))))

(defun exunit-umbrella-project-root ()
  "Return the current umbrella root.

This value is cached in a buffer local to avoid filesytem access
on every call."
  (or
   exunit-umbrella-project-root
   (let ((root (locate-dominating-file default-directory "apps")))
     (unless root
       (error "Couldn't locate umbrella root folder.  Make sure the current file is inside a umbrella project"))
     (setq exunit-umbrella-project-root (expand-file-name root)))))

(defun exunit-project-name ()
  "Return the current project name."
  (file-name-nondirectory (directory-file-name (exunit-project-root))))

(defun exunit-dependency-filename (dep filename)
  "Convert FILENAME to absolute path.

DEP may be a local dependency or umbrella dependency or a
exception name.  This function checks for known constant values
and the presence of the file relative to dependency folder."
  (let ((project-name (exunit-project-name))
        (dep-file (f-join "deps" dep filename))
        (umbrella-app-file (f-join exunit-project-root ".." dep filename))
        (umbrella-dep-file (f-join exunit-project-root ".." ".." "deps" dep filename)))
    (cond
     ((member dep '("elixir" "stdlib")) filename)
     ((s-ends-with? "Error" dep) filename)
     ((string= dep project-name) filename)
     ((file-exists-p dep-file) dep-file)
     ((file-exists-p umbrella-app-file) umbrella-app-file)
     ((file-exists-p umbrella-dep-file) umbrella-dep-file)
     (t filename))))

(defun exunit-parse-error-filename (filename)
  "Parse FILENAME in stacktrace.

       (fdb) lib/fdb/transaction.ex:443: FDB.Transaction.set/4
       (fdb) lib/fdb/database.ex:129: FDB.Database.do_transact/2
       test/fdb/coder_test.exs:32: (test)

The filenames in stacktrace are of two formats, one with the
filename relative to project root, another with dependency name
and filename relative to the dependency."
  (let ((match (s-match "(\\([^)]*\\)) \\(.*\\)" filename)))
    (if match
        (exunit-dependency-filename (nth 1 match) (nth 2 match))
      filename)))

(defun exunit-test-filename ()
  (file-relative-name (buffer-file-name) (exunit-project-root)))

(defun exunit-test-filename-line-number ()
  (concat (exunit-test-filename) ":" (number-to-string (line-number-at-pos))))

(defun exunit-colorize-compilation-buffer ()
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region compilation-filter-start (point))))

(defvar exunit-compilation-error-regexp-alist-alist
  '((elixir-warning "warning: [^\n]*\n +\\([0-9A-Za-z@_./:-]+\\.exs?\\):\\([0-9]+\\)" 1 2 nil 1 1)
    (elixir-error " +\\(\\(?:([0-9A-Za-z_-]*) \\)?[0-9A-Za-z@_./:-]+\\.\\(?:ex\\|exs\\|erl\\)\\):\\([0-9]+\\):?" 1 2 nil 2 1)))
(defvar exunit-compilation-error-regexp-alist
  (mapcar 'car exunit-compilation-error-regexp-alist-alist))

(define-compilation-mode exunit-compilation-mode "ExUnit Compilation"
  "Compilation mode for ExUnit output."
  (setq compilation-parse-errors-filename-function #'exunit-parse-error-filename)
  (add-hook 'compilation-filter-hook 'exunit-colorize-compilation-buffer nil t))

(defun exunit-do-compile (args)
  "Run compile and save the ARGS for future invocation."
  (setq exunit-last-directory default-directory
        exunit-last-arguments args)

  (compile args 'exunit-compilation-mode))

(define-derived-mode exunit-iex-mode comint-mode "IEx"
  "ExUnit IEx comint mode."
  (setq-local comint-scroll-show-maximum-output nil)
  (compilation-shell-minor-mode)
  (add-hook 'compilation-filter-hook 'exunit-colorize-compilation-buffer nil t))

(defun exunit-do-comint (args)
  "Run command in comint mode."
  (pop-to-buffer (compile args 'exunit-iex-mode)))

(defun exunit-compile (args &optional directory)
  "Run mix test with the given ARGS."
  (let ((default-directory (or directory (exunit-project-root)))
        (compilation-environment exunit-environment)
        (args (if current-prefix-arg
                  (list (read-from-minibuffer "Args: " (s-join " " args) nil nil 'exunit-arguments))
                args)))
    (exunit-do-compile
     (s-join " " (append '("mix" "test") exunit-mix-test-default-options args)))))

(defun exunit-comint (args &optional directory)
  "Run mix test in iex shell with the given ARGS."
  (let ((default-directory (or directory (exunit-project-root)))
        (compilation-environment exunit-environment))
    (exunit-do-comint
     (s-join " " (append '("iex" "-S" "mix" "test" "--trace") exunit-mix-test-default-options args)))))

(defun exunit-test-file-p (file)
  "Return non-nil if FILE is an ExUnit test file."
  (string-match-p "_test\\.exs$" file))

(defun exunit-test-for-file (file)
  "Return the test file for FILE."
  (replace-regexp-in-string "^lib/\\(.*\\)\.ex$" "test/\\1_test.exs" file))

(defun exunit-file-for-test (test-file)
  "Return the file which is tested by TEST-FILE."
  (replace-regexp-in-string "^test/\\(.*\\)_test\.exs$" "lib/\\1.ex" test-file))

(defun exunit-open-test-file-for (file opener)
  "Visit the test file for FILE using OPENER.

If the file does not exist, prompt the user to create it."
  (let ((filename (concat (exunit-project-root)
                          (exunit-test-for-file file))))
    (if (file-exists-p filename)
        (funcall opener filename)
      (if (y-or-n-p "No test file found; create one now? ")
          (exunit-create-test-for-current-buffer filename opener)
        (message "No test file found")))))

(defun exunit-create-test-for-current-buffer (filename opener)
  "Create a test module as FILENAME and visit it using OPENER.

The module name given to the test module is determined from the name of the
first module defined in the current buffer."
  (let ((directory-name (file-name-directory filename))
        (module-name (concat (exunit-buffer-module-name (current-buffer))
                             "Test")))
    (unless (file-exists-p directory-name)
      (make-directory directory-name t))
    (exunit-insert-test-boilerplate (funcall opener filename) module-name)))

(defun exunit-buffer-module-name (buffer)
  "Determine the name of the first module defined in BUFFER."
  (save-excursion
    (with-current-buffer buffer
      (goto-char (point-min))
      (re-search-forward "defmodule\\s-+\\(.+?\\),?\\s-+do")
      (match-string 1))))

(defun exunit-insert-test-boilerplate (buffer module-name)
  "Insert ExUnit boilerplate for MODULE-NAME in BUFFER."
  (with-current-buffer buffer
    (insert (concat "defmodule " module-name " do\n"
                    "  use ExUnit.Case" (and exunit-prefer-async-tests ", async: true") "\n\n\n"
                    "end\n"))
    (goto-char (point-min))
    (beginning-of-line 4)
    (indent-according-to-mode)))

(defun exunit-open-file-for-test (test-file opener)
  "Visit the file which is tested by TEST-FILE using OPENER.

If the file does not exist, display an error message."
  (let ((filename (concat (exunit-project-root)
                          (exunit-file-for-test test-file))))
    (if (file-exists-p filename)
        (funcall opener filename)
      (error "No source file found"))))

;;; Public

;;;###autoload
(define-minor-mode exunit-mode
  "Minor mode for ExUnit test runner"
  :lighter " ExUnit" :keymap `((,exunit-key-command-prefix . exunit-mode-keymap)))

;;;###autoload
(defun exunit-rerun ()
  "Re-run the last test invocation."
  (interactive)
  (if (not exunit-last-directory)
      (error "No previous verification")
    (let ((default-directory exunit-last-directory))
      (exunit-do-compile exunit-last-arguments))))

;;;###autoload
(defun exunit-verify-all ()
  "Run all the tests in the current project."
  (interactive)
  (exunit-compile '()))

;;;###autoload
(defun exunit-verify-all-in-umbrella ()
  "Run all the tests in the current umbrella project."
  (interactive)
  (exunit-compile '() (exunit-umbrella-project-root)))

;;;###autoload
(defun exunit-verify-single ()
  "Run the test under the point."
  (interactive)
  (exunit-compile (list (exunit-test-filename-line-number))))

;;;###autoload
(defun exunit-debug ()
  "Run the test under the point in IEx shell.

This allows the usage of IEx.pry method for debugging."
  (interactive)
  (exunit-comint (list (exunit-test-filename-line-number))))

;;;###autoload
(defun exunit-verify ()
  "Run all the tests associated with the current buffer."
  (interactive)
  (let ((filename (exunit-test-filename)))
    (exunit-compile (list (if (exunit-test-file-p filename)
                              filename
                            (exunit-test-for-file filename))))))

;;;###autoload
(defun exunit-toggle-file-and-test ()
  "Toggle between a file and its tests in the current window."
  (interactive)
  (let ((file (exunit-test-filename)))
    (if (exunit-test-file-p file)
        (exunit-open-file-for-test file #'find-file)
      (exunit-open-test-file-for file #'find-file))))

;;;###autoload
(defun exunit-toggle-file-and-test-other-window ()
  "Toggle between a file and its tests in other window."
  (interactive)
  (let ((file (exunit-test-filename)))
    (if (exunit-test-file-p file)
        (exunit-open-file-for-test file #'find-file-other-window)
      (exunit-open-test-file-for file #'find-file-other-window))))

(provide 'exunit)

;;; exunit.el ends here
