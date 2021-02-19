;;; jest.el --- helpers to run jest -*- lexical-binding: t; -*-
;; Author: Edmund Miller <edmund.a.miller@gmail.com>
;; URL:  https://github.com/emiller88/emacs-jest/
;; Package-Version: 20210219.1508
;; Package-Commit: 0fe875082e54bdbfe924808aa155b938ed90d401
;; Version: 0.1.0
;; Keywords: jest, javascript, testing
;; Package-Requires: ((emacs "24.4") (dash "2.18.0") (magit-popup "2.12.0") (projectile "0.14.0") (s "1.12.0") (js2-mode "20180301") (cl-lib "0.6.1"))

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides helpers to run jest.
;;
;; The main command is jest-popup, which will show a
;; dispatcher menu, making it easy to change various options and
;; switches, and then run jest using one of the actions.
;; - jest (run all tests)
;; - jest-file (current file)
;; - jest-file-dwim (‘do what i mean’ for current file)
;; - jest-last-failed (rerun previous failures)
;; - jest-repeat (repeat last invocation)
;;
;; A prefix argument causes the generated command line to be offered
;; for editing, and various customization options influence how some
;; of the commands work. See the README.org for detailed information.

;;; Code:
(require 'comint)
(require 'compile)
(require 'js2-mode)

(require 'dash)
(require 'magit-popup)
(require 'projectile)
(require 's)

(defgroup jest nil
  "jest integration"
  :group 'js
  :prefix "jest-")

(defcustom jest-confirm nil
  "Whether to edit the command in the minibuffer before execution.

By default, jest will be executed without showing a minibuffer prompt.
This can be changed on a case by case basis by using a prefix argument
\(\\[universal-argument]\) when invoking a command.

When t, this toggles the behaviour of the prefix argument."
  :group 'jest
  :type 'boolean)

(defcustom jest-executable "npm test --"
  "The name of the jest executable."
  :group 'jest
  :type 'string)

(defcustom jest-setup-hook nil
  "Hooks to run before a jest process starts."
  :group 'jest
  :type 'hook)

(defcustom jest-started-hook nil
  "Hooks to run after a jest process starts."
  :group 'jest
  :type 'hook)

(defcustom jest-finished-hook nil
  "Hooks to run after a jest process finishes."
  :group 'jest
  :type 'hook)

(defcustom jest-buffer-name "*jest*"
  "Name of the jest output buffer."
  :group 'jest
  :type 'string)

(defcustom jest-project-name-in-buffer-name t
  "Whether to include the project name in the buffer name.

This is useful when working on multiple projects simultaneously."
  :group 'jest
  :type 'boolean)

;; TODO Find JS cli debugger
(defcustom jest-pdb-track t
  "Whether to automatically track output when pdb is spawned.

This results in automatically opening source files during debugging."
  :group 'jest
  :type 'boolean)

(defcustom jest-strict-test-name-matching nil
  "Whether to require a strict match for the ‘test this function’ heuristic.

This influences the ‘test this function’ behaviour when editing a
non-test function, e.g. ‘foo()’.

When nil (the default), the current function name will be used as
a pattern to run the corresponding tests, which will match
‘test_foo()’ as well as ‘test_foo_xyz()’.

When non-nil only ‘test_foo()’ will match, and nothing else."
  :group 'jest
  :type 'boolean)

(defcustom jest-unsaved-buffers-behavior 'ask-all
  "Whether to ask whether unsaved buffers should be saved before running jest."
  :group 'jest
  :type '(choice (const :tag "Ask for all project buffers" ask-all)
                 (const :tag "Ask for current buffer" ask-current)
                 (const :tag "Save all project buffers" save-all)
                 (const :tag "Save current buffer" save-current)
                 (const :tag "Ignore" nil)))

(defvar jest--history nil
  "History for jest invocations.")

(defvar jest--project-last-command (make-hash-table :test 'equal)
  "Last executed command lines, per project.")

(defvar-local jest--current-command nil
  "Current command; used in jest-mode buffers.")

(fmakunbound 'jest-popup)
(makunbound 'jest-popup)

;;;###autoload (autoload 'jest-popup "jest" nil t)
(magit-define-popup jest-popup
  "Show popup for running jest."
  'jest
  :switches
  '((?b "bail" "--bail")
    (?c "colors" "--colors" t)
    (?C "coverage" "--coverage")
    (?d "run doctests" "--doctest-modules")
    (?D "debug jest config" "--debug")
    (?e "expand" "--expand")
    (?f "force exit" "--forceExit")
    (?l "last commit" "--lastCommit")
    ;; (?p "debug on error" "--pdb")
    (?o "only changed" "--onlyChanged")
    (?s "silent" "--silent")
    ;; (?s "do not capture output" "--capture=no")
    ;; (?t "do not cut tracebacks" "--full-trace")
    (?v "verbose" "--verbose")
    ;;--watch
    (?w "watch" "--watch")
    (?W "watch all" "--watchAll"))
  :options
  '((?c "config file" "--config=")
    (?k "only names matching expression" "-t")
    (?p "only files matching expression" "--testPathPattern ")
    (?P "only files not matching expression" "--testPathIgnorePatterns ")
    ;; (?m "only marks matching expression" "-m")
    (?o "output file" "--outputFile=")
    ;; (?t "traceback style" "--tb=" jest--choose-traceback-style)
    (?x "exit after N failures or errors" "--maxfail="))
  :actions
  '("Run tests"
    (?t "Test all" jest)
    (?x "Test last-failed" jest-last-failed)
    "Run tests for current context"
    (?f "Test file" jest-file-dwim)
    (?F "Test this file  " jest-file)
    (?d "Test function " jest-function)
    "Repeat tests"
    (?r "Repeat last test run" jest-repeat))
  :max-action-columns 2
  :default-action 'jest-repeat)

;;;###autoload
(defun jest (&optional args)
  "Run jest with ARGS.

With a prefix argument, allow editing."
  (interactive (list (jest-arguments)))
  (jest--run
   :args args
   :edit current-prefix-arg))

;;;###autoload
(defun jest-file (file &optional args)
  "Run jest on FILE, using ARGS.

Additional ARGS are passed along to jest.
With a prefix argument, allow editing."
  (interactive
   (list
    (buffer-file-name)
    (jest-arguments)))
  (jest--run
   :args args
   :file file
   :edit current-prefix-arg))

;;;###autoload
(defun jest-file-dwim (file &optional args)
  "Run jest on FILE, intelligently finding associated test modules.

When run interactively, this tries to work sensibly using
the current file.

Additional ARGS are passed along to jest.
With a prefix argument, allow editing."
  (interactive
   (list
    (buffer-file-name)
    (jest-arguments)))
  (jest-file (jest--sensible-test-file file) args))


;;;###autoload
(defun jest-function (file testname &optional args)
  "Run jest on the test function where pointer is located.

When pointer is not inside a test function jest is run on the whole file."
  (interactive
   (list (buffer-file-name) (jest--current-testname) (jest-arguments)))
  (jest--run
   :args args
   :file file
   :testname testname))


;;;###autoload
(defun jest-last-failed (&optional args)
  "Run jest, only executing previous test failures.

Additional ARGS are passed along to jest.
With a prefix argument, allow editing."
  (interactive (list (jest-arguments)))
  (jest--run
   :args (-snoc args "--last-failed")
   :edit current-prefix-arg))

;;;###autoload
(defun jest-repeat ()
  "Run jest with the same argument as the most recent invocation.

With a prefix ARG, allow editing."
  (interactive)
  (let ((command (gethash
                  (jest--project-root)
                  jest--project-last-command)))
    (when jest--current-command
      ;; existing jest-mode buffer; reuse command
      (setq command jest--current-command))
    (unless command
      (user-error "No previous jest run for this project"))
    (jest--run-command
     :command command
     :popup-arguments jest-arguments
     :edit current-prefix-arg)))


;; internal helpers

(fmakunbound 'jest-mode)
(makunbound 'jest-mode)

(define-derived-mode jest-mode
  comint-mode "jest"
  "Major mode for jest sessions (derived from comint-mode)."
  (make-variable-buffer-local 'comint-prompt-read-only)
  (setq-default comint-prompt-read-only nil)
  (compilation-setup t))

(cl-defun jest--run (&key args file testname edit)
  "Run jest for the given arguments."
  (let ((popup-arguments args))
    (setq args (jest--transform-arguments args))
    (when (and file (file-name-absolute-p file))
      (setq file (jest--relative-file-name file)))

    (when file
      (setq args (-snoc args (jest--shell-quote file))))
    (when testname
      (setq args (-snoc args "--testNamePattern" (jest--shell-quote testname))))

      (setq args (cons jest-executable args) command (s-join " " args))

      (jest--run-command
       :command command
       :popup-arguments popup-arguments
       :edit edit)))

(cl-defun jest--run-command (&key command popup-arguments edit)
  "Run a jest command line."
  (jest--maybe-save-buffers)
  (let* ((default-directory (jest--project-root)))
    (when jest-confirm
      (setq edit (not edit)))
    (when edit
      (setq command
            (read-from-minibuffer
             "Command: "
             command nil nil 'jest--history)))
    (add-to-history 'jest--history command)
    (setq jest--history (-uniq jest--history))
    (puthash (jest--project-root) command
             jest--project-last-command)
    (jest--run-as-comint
     :command command
     :popup-arguments popup-arguments)))

(cl-defun jest--run-as-comint (&key command popup-arguments)
  "Run a jest comint session for COMMAND."
  (let* ((buffer (jest--get-buffer))
         (process (get-buffer-process buffer)))
    (with-current-buffer buffer
      (when (comint-check-proc buffer)
        (unless (or compilation-always-kill
                    (yes-or-no-p "Kill running jest process?"))
          (user-error "Aborting; jest still running")))
      (when process
        (delete-process process))
      (erase-buffer)
      (unless (eq major-mode 'jest-mode)
        (jest-mode))
      (compilation-forget-errors)
      (insert (format "cwd: %s\ncmd: %s\n\n" default-directory command))
      (make-local-variable 'jest-arguments)
      (setq jest--current-command command
            jest-arguments popup-arguments)
      (run-hooks 'jest-setup-hook)
      (make-comint-in-buffer "jest" buffer "sh" nil "-c" command)
      (run-hooks 'jest-started-hook)
      (setq process (get-buffer-process buffer))
      (set-process-sentinel process #'jest--process-sentinel)
      (display-buffer buffer))))

(defun jest--shell-quote (s)
  "Quote S for use in a shell command. Like `shell-quote-argument', but prettier."
  (if (s-equals-p s (shell-quote-argument s))
      s
    (format "'%s'" (s-replace "'" "'\"'\"'" s))))

(defun jest--get-buffer ()
  "Get a create a suitable compilation buffer."
  (magit-with-pre-popup-buffer
    (if (eq major-mode 'jest-mode)
        (current-buffer)  ;; re-use buffer
      (let ((name jest-buffer-name))
        (when jest-project-name-in-buffer-name
          (setq name (format "%s<%s>" name (jest--project-name))))
        (get-buffer-create name)))))

(defun jest--process-sentinel (proc _state)
  "Process sentinel helper to run hooks after PROC finishes."
  (with-current-buffer (process-buffer proc)
    (run-hooks 'jest-finished-hook)))

(defun jest--transform-arguments (args)
  "Transform ARGS so that jest understands them."
  (-->
   args
   (jest--switch-to-option it "--color" "--color=yes" "--color=no")
   (jest--quote-string-option it "-k")
   (jest--quote-string-option it "-m")))

(defun jest--switch-to-option (args name on-replacement off-replacement)
  "Look in ARGS for switch NAME and turn it into option with a value.

When present ON-REPLACEMENT is substituted, else OFF-REPLACEMENT is appended."
  (if (-contains-p args name)
      (-replace name on-replacement args)
    (-snoc args off-replacement)))

(defun jest--quote-string-option (args option)
  "Quote all values in ARGS with the prefix OPTION as shell strings."
  (--map-when
   (s-prefix-p option it)
   (let ((s it))
     (--> s
          (substring it (length option))
          (s-trim it)
          (jest--shell-quote it)
          (format "%s %s" option it)))
   args))

(defun jest--choose-traceback-style (prompt _value)
  "Helper to choose a jest traceback style using PROMPT."
  (completing-read
   prompt '("long" "short" "line" "native" "no") nil t))


(defun jest--make-test-name (func)
  "Turn function name FUNC into a name (hopefully) matching its test name.

Example: ‘MyABCThingy.__repr__’ becomes ‘test_my_abc_thingy_repr’."
  (-->
   func
   (s-replace "." "_" it)
   (s-snake-case it)
   (s-replace-regexp "_\+" "_" it)
   (s-chop-suffix "_" it)
   (s-chop-prefix "_" it)
   (format "test_%s" it)))


;; file/directory helpers

(defun jest--project-name ()
  "Find the project name."
  (projectile-project-name))

(defun jest--project-root ()
  "Find the project root directory."
  (projectile-project-root))

(defun jest--relative-file-name (file)
  "Make FILE relative to the project root."
  ;; Note: setting default-directory gives different results
  ;; than providing a second argument to file-relative-name.
  (let ((default-directory (jest--project-root)))
    (file-relative-name file)))

(defun jest--test-file-p (file)
  "Tell whether FILE is a test file."
  (projectile-test-file-p file))

(defun jest--find-test-file (file)
  "Find a test file associated to FILE, if any."
  (let ((test-file (projectile-find-matching-test file)))
    (unless test-file
      (user-error "No test file found"))
    test-file))

(defun jest--sensible-test-file (file)
  "Return a sensible test file name for FILE."
  (if (jest--test-file-p file)
      (jest--relative-file-name file)
    (jest--find-test-file file)))

(defun jest--maybe-save-buffers ()
  "Maybe save modified buffers."
  (cond
   ((memq jest-unsaved-buffers-behavior '(ask-current save-current))
    ;; check only current buffer
    (when (and (buffer-modified-p)
               (or (eq jest-unsaved-buffers-behavior 'save-current)
                   (y-or-n-p
                    (format "Save modified buffer (%s)? " (buffer-name)))))
      (save-buffer)))
   ((memq jest-unsaved-buffers-behavior '(ask-all save-all))
    ;; check all project buffers
    (-when-let*
        ((buffers
          (projectile-buffers-with-file (projectile-project-buffers)))
         (modified-buffers
          (-filter 'buffer-modified-p buffers))
         (confirmed
          (or (eq jest-unsaved-buffers-behavior 'save-all)
              (y-or-n-p
               (format "Save modified project buffers (%d)? "
                       (length modified-buffers))))))
      (--each modified-buffers
        (with-current-buffer it
          (save-buffer)))))
   (t nil)))


;; functions to inspect/navigate the javascript source code
(defun jest--current-testname ()
  "Return the testname where pointer is located.

Testname is defined by enclosing ~describe~ calls and ~it~/~test~ calls."
  (let* ((calls (jest--list-named-calls-upwards))
         (testname ""))
    (dolist (call calls)
      ;; call is the node for the function, function name must be extracted
      ;; from its target node
      (let ((funcname (js2-name-node-name (js2-call-node-target call))))
        (when (member funcname '("it" "test" "describe"))
          (let ((funcparam (jest--function-first-param-string call)))
            (setq testname (format "%s %s" funcparam testname))))))
    (unless (string= testname "") (string-trim testname))))



(defun jest--list-named-calls-upwards ()
  "List functions call nodes where function has a name.

This goes from pointer position upwards."
  (save-excursion
    ;; enter the test function if the point is before it
    ;; separated only by whitespace, e.g.
    (skip-chars-forward "[:blank:]")
    (let* ((nodes ())
           (node (js2-node-at-point)))
      (while (not (js2-ast-root-p node))
        (when (js2-call-node-p node)
          (let ((target (js2-call-node-target node)))
            (when (js2-name-node-p target)
              (setq nodes (append nodes (list node))))))
        (setq node (js2-node-parent node)))
      nodes)))

(defun jest--function-first-param-string (node)
  "Get the first param from the function call"
  (let ((first-param (car (js2-call-node-args node))))
    (when (js2-string-node-p first-param)
      (js2-string-node-value first-param))))
;;

(defcustom jest-compile-command 'jest-popup
  "Command to run when compile and friends are called."
  :group 'jest
  :type 'function)

(defcustom jest-repeat-compile-command 'jest-repeat
  "Command to run when recompile and friends are called."
  :group 'jest
  :type 'function)

;;;###autoload
(define-minor-mode jest-minor-mode
  "Minor mode to run jest-mode commands for compile and friends."
  :lighter " Jest"
  :keymap (let ((jest-minor-mode-keymap (make-sparse-keymap)))
            (define-key jest-minor-mode-keymap [remap compile] jest-compile-command)
            (define-key jest-minor-mode-keymap [remap recompile] jest-repeat-compile-command)
            (define-key jest-minor-mode-keymap [remap projectile-test-project] jest-compile-command)
            (define-key jest-minor-mode-keymap (kbd "C-c ;") 'jest-file-dwim)
            jest-minor-mode-keymap))

(provide 'jest)
;;; jest.el ends here
