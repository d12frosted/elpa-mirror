;;; jest-test-mode.el --- Minor mode for running Node.js tests using jest -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Raymond Huang

;; Author: Raymond Huang <rymndhng@gmail.com>
;; Maintainer: Raymond Huang <rymndhng@gmail.com>
;; URL: https://github.com/rymndhng/jest-test-mode.el
;; Version: 0
;; Package-Requires: ((emacs "25.1"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This mode provides commands for running node tests using jest. The output is
;; shown in a separate buffer '*compilation*' in compilation mode. Backtraces
;; from failures and errors are marked and can be clicked to bring up the
;; relevant source file, where point is moved to the named line.
;;
;; The tests should be written with jest. File names are supposed to end in `.test.ts'
;;
;; Using the command `jest-test-run-at-point`, you can run test cases from the
;; current file.

;; Keybindings:
;;
;; C-c C-t n    - Runs the current buffer's file as an unit test or an rspec example.
;; C-c C-t p    - Runs all tests in the project
;; C-C C-t t    - Runs describe block at point
;; C-C C-t a    - Re-runs the last test command
;; C-c C-t d n  - With node debug enabled, runs the current buffer's file as an unit test or an rspec example.
;; C-C C-t d a  - With node debug enabled, re-runs the last test command
;; C-C C-t d t  - With node debug enabled, runs describe block at point


;;; Code:

;; Adds support for when-let
(eval-when-compile (require 'subr-x))

;; prevents warnings like
;; jest-test-mode.el:190:15:Warning: reference to free variable
;; ‘compilation-error-regexp-alist’
(require 'compile)

;; for seq-concatenate
(require 'seq)

(defgroup jest-test nil
  "Minor mode providing commands for running jest tests in Node.js."
  :group 'js)

(defcustom jest-test-options
  '("--color")
  "Pass extra command line options to jest when running tests."
  :initialize 'custom-initialize-default
  :type '(list)
  :group 'jest-test-mode)

(defcustom jest-test-npx-options
  '()
  "Pass extra command line arguments to npx when running tests."
  :initialize 'custom-initialize-default
  :type '(list)
  :group 'jest-test-mode)

(defcustom jest-test-command-string
  "npx %s jest %s %s"
  "The command by which jest is run.

Placeholders are:

1. npx options (`jest-test-npx-options')
2. Jest test options (`jest-test-options')
3. The file name"
  :initialize 'custom-initialize-default
  :type 'string
  :group 'jest-test-mode)

(defvar jest-test-last-test-command
  nil
  "The last test command ran with.")

(defvar jest-test-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-t p")   'jest-test-run-all-tests)
    (define-key map (kbd "C-c C-t C-p") 'jest-test-run-all-tests)
    (define-key map (kbd "C-c C-t n")   'jest-test-run)
    (define-key map (kbd "C-c C-t C-n") 'jest-test-run)
    (define-key map (kbd "C-c C-t a")   'jest-test-rerun-test)
    (define-key map (kbd "C-c C-t C-a") 'jest-test-rerun-test)
    (define-key map (kbd "C-c C-t t")   'jest-test-run-at-point)
    (define-key map (kbd "C-c C-t C-t") 'jest-test-run-at-point)
    (define-key map (kbd "C-c C-t d n") 'jest-test-debug)
    (define-key map (kbd "C-c C-t d a") 'jest-test-debug-rerun-test)
    (define-key map (kbd "C-c C-t d t") 'jest-test-debug-run-at-point)

    ;; (define-key map (kbd "C-c C-s")     'jest-test-toggle-implementation-and-test)
    map)
  "The keymap used in command `jest-test-mode' buffers.")

;;;###autoload
(define-minor-mode jest-test-mode
  "Toggle jest minor mode.
With no argument, this command toggles the mode. Non-null prefix
argument turns on the mode. Null prefix argument turns off the
mode"
  :init-value nil
  :lighter " Jest"
  :keymap 'jest-test-mode-map
  :group 'jest-test-mode)

(defmacro jest-test-from-project-directory (filename form)
  "Set to npm project root inferred from FILENAME.

Runs the provided FORM with `default-directory` bound."
  (declare (indent 1))
  `(let ((default-directory (or (jest-test-project-root ,filename)
                                default-directory)))
     ,form))

(defmacro jest-test-with-debug-flags (form)
  "Execute FORM with debugger flags set."
  (declare (indent 0))
  `(let ((jest-test-options (seq-concatenate 'list jest-test-options (list "--runInBand") ))
         (jest-test-npx-options (seq-concatenate 'list jest-test-npx-options (list "--node-arg" "inspect"))))
     ,form))

(defun jest-test-project-root (filename)
  "Find project folder containing a package.json containing FILENAME."
  (if (jest-test-npm-project-root-p filename)
      filename
    (and filename
         (not (string= "/" filename))
         (jest-test-project-root
          (file-name-directory
           (directory-file-name (file-name-directory filename)))))))

(defun jest-test-npm-project-root-p (directory)
  "Check if DIRECTORY contain a package.json file."
  (file-exists-p (concat (file-name-as-directory directory) "/package.json")))

(defun jest-test-find-file ()
  "Find the testfile to run. Assumed to be the current file."
  (buffer-file-name))

(defvar jest-test-not-found-message "No test among visible bufers")

;;;###autoload
(defun jest-test-run ()
  "Run the current buffer's file as a test."
  (interactive)
  (let ((filename (jest-test-find-file)))
    (if filename
        (jest-test-from-project-directory filename
          (jest-test-run-command (jest-test-command filename)))
      (message jest-test-not-found-message))))

(defun jest-test-run-all-tests ()
  "Run all test in the project."
  (interactive)
  (jest-test-from-project-directory (buffer-file-name)
    (jest-test-run-command (jest-test-command ""))))

(defun jest-test-rerun-test ()
  "Run the previously run test in the project."
  (interactive)
  (jest-test-from-project-directory (buffer-file-name)
    (jest-test-run-command jest-test-last-test-command)))

(defun jest-test-run-at-point ()
  "Run the enclosing it/test/describe block surrounding the current point."
  (interactive)
  (let ((filename (jest-test-find-file))
        (test (jest-test-unit-at-point)))
    (if (and filename test)
        (jest-test-from-project-directory filename
          (let ((jest-test-options (seq-concatenate 'list jest-test-options (list "-t" test))))
            (jest-test-run-command (jest-test-command filename))))
      (message jest-test-not-found-message))))

(defun jest-test-debug ()
  "Run the test with an inline debugger attached."
  (interactive)
  (jest-test-with-debug-flags
    (jest-test-run)))

(defun jest-test-debug-rerun-test ()
  "Run the test with an inline debugger attached."
  (interactive)
  (jest-test-with-debug-flags
    (jest-test-rerun-test)))

(defun jest-test-debug-run-at-point ()
  "Run the test with an inline debugger attached."
  (interactive)
  (jest-test-with-debug-flags
    (jest-test-run-at-point)))

(defvar jest-test-declaration-regex "^[ \\t]*\\(it\\|test\\|describe\\)\\(\\.\\(.*\\)\\)?(\\(.*\\),"
  "Regex for finding a test declaration in jest.

Match Group 1 contains the function name: it, test, describe
Match Group 4 contains the test name" )

(defun jest-test-unit-at-point ()
  "Find the enclosing name of the block.

Looks for  \'it\', \'test\' or \'describe\' from where the cursor is"
  (save-excursion
    ;; Moving the cursor to the end will allow matching the current line
    (move-end-of-line nil)
    (when (re-search-backward jest-test-declaration-regex nil t)
      (when-let ((name (match-string 4)))
        (substring name 1 -1)))))

(defun jest-test-update-last-test (command)
  "Update the last test COMMAND."
  (setq jest-test-last-test-command command))

(defun jest-test-run-command (command)
  "Run compilation COMMAND in NPM project root."
  (jest-test-update-last-test command)
  (let ((comint-scroll-to-bottom-on-input t)
        (comint-scroll-to-bottom-on-output t)
        (comint-process-echoes t))
    ;; TODO: figure out how to prevent <RET> from re-sending the old input
    ;; See https://stackoverflow.com/questions/51275228/avoid-accidental-execution-in-comint-mode
    (compilation-start command t)))

;;;###autoload
(defun jest-test-command (filename)
  "Format test arguments for FILENAME."
  (format jest-test-command-string
          (mapconcat #'shell-quote-argument jest-test-npx-options " ")
          (mapconcat #'shell-quote-argument jest-test-options " ")
          (if (string-empty-p filename)
              filename
            (file-relative-name filename (jest-test-project-root filename)))))

;;; compilation-mode support

;; Source: https://emacs.stackexchange.com/questions/27213/how-can-i-add-a-compilation-error-regex-for-node-js
;; Handle errors that match this:
;; at addSpecsToSuite (node_modules/jest-jasmine2/build/jasmine/Env.js:522:17)
(add-to-list 'compilation-error-regexp-alist 'jest)
(add-to-list 'compilation-error-regexp-alist-alist
             '(jest "at [^ ]+ (\\(.+?\\):\\([[:digit:]]+\\):\\([[:digit:]]+\\)" 1 2 3))

(defun jest-test-enable ()
  "Enable the jest test mode."
  (jest-test-mode 1))

(provide 'jest-test-mode)
;; Local Variables:
;; sentence-end-double-space: nil
;; checkdoc-spellcheck-documentation-flag: nil
;; End:
;;; jest-test-mode.el ends here
