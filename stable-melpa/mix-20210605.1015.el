;;; mix.el --- Mix Major Mode. Build Elixir using Mix -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Ayrat Badykov

;; Permission is hereby granted, free of charge, to any person obtaining a copy of
;; this software and associated documentation files (the "Software"), to deal in
;; the Software without restriction, including without limitation the rights to
;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is furnished to do
;; so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;; Author: Ayrat Badykov <ayratin555@gmail.com>
;; URL: https://github.com/ayrat555/mix.el
;; Package-Version: 20210605.1015
;; Package-Commit: bfe61ed4e7dd8cfc0bb2603fbac3eb44b32438bf
;; Version  : 0.0.3
;; Keywords: tools
;; Package-Requires: ((emacs "25.1"))

;;; Commentary:

;; Add a hook to the mode that you're using with Elixir, for example, `elixir-mode`:
;;
;; (add-hook 'elixir-mode-hook 'mix-minor-mode)
;;

;;; C-c d e - mix-execute-task - List all available tasks and execute one of them.  It starts in the root of the umbrella app.  As a bonus, you'll get a documentation string because mix.el parses shell output of mix help directly.  Starts in the umbrella root directory.
;;; C-c d d e - mix-execute-task in an umbrella subproject - The same as mix-execute-task but allows you choose a subproject to execute a task in.
;;; C-c d t - mix-test - Run all test in the app.  It starts in the umbrella root directory.
;;; C-c d d t - mix-test in an umbrella subproject - The same as mix-test but allows you to choose a subproject to run tests in.
;;; C-c d o - mix-test-current-buffer - Run all tests in the current buffer.  It starts in the umbrella root directory.
;;; C-c d d o - mix-test-current-buffer in an umbrella subproject - The same as mix-test-current-buffer but runs tests directly from subproject directory.
;;; C-c d f - mix-test-current-test - Run the current test where pointer is located.  It starts in the umbrella root directory.
;;; C-c d d f - mix-test-current-test in an umbrella subproject - The same as mix-test-current-test but runs a test directly from subproject directory.
;;; C-c d l - mix-last-command - Execute the last mix command.
;;;
;;; Prefixes to modify commands before execution
;;; Add these prefixes before commands described in the previous section.
;;;
;;; C-u - Choose MIX_ENV env variable.
;;; C-u C-u - Add extra params for mix task.
;;; C-u C-u C-u - Choose MIX_ENV and add extra params.
;;;
;;; For example, to create a migration in a subproject you should press:
;;;
;;; C-u C-u C-c d d e:
;;;
;;; C-u C-u - to be prompted for migration name
;;; C-c d d e - to select a mix project and ecto.gen.migration task

;;; Code:

(require 'seq)
(require 'ansi-color)

(defgroup mix nil
  "Mix process group."
  :prefix "mix-"
  :group 'mix)

(defcustom mix-path-to-bin
  (or (executable-find "mix")
      "/usr/bin/mix")
  "Path to the mix executable."
  :type 'file
  :group 'mix)

(defcustom mix-start-in-umbrella
  t
  "Start mix command in the umbrella app root or use a subproject."
  :type 'boolean
  :group 'mix)

(defcustom mix-command-compile "compile"
  "Subcommand used by `mix-compile'."
  :type 'string
  :group 'mix)

(defcustom mix-command-test "test"
  "Subcommand used by `mix-test'."
  :type 'string
  :group 'mix)

(defcustom mix-envs '("dev" "prod" "test")
  "The list of mix envs to use as defaults."
  :type 'list
  :group 'mix)

(defcustom mix-default-env nil
  "The default mix env to run mix commands with.
It's used in prompt"
  :type '(string boolean)
  :group 'mix)

(defvar mix--last-command nil "Last mix command.")

(define-derived-mode mix-mode compilation-mode "Mix"
  "Major mode for the Mix buffer."
  (setq buffer-read-only t)
  (setq-local truncate-lines t)
  (add-hook 'compilation-filter-hook #'mix--output-filter))

(defun mix--project-root ()
  "Find the root of the current mix project."
  (let ((closest-path (or buffer-file-name default-directory)))
    (if (and mix-start-in-umbrella (string-match-p (regexp-quote "apps") closest-path))
        (let* ((potential-umbrella-root-parts (butlast (split-string closest-path "/apps/")))
               (potential-umbrella-root (mapconcat #'identity potential-umbrella-root-parts ""))
               (umbrella-app-root (mix--find-closest-mix-file-dir potential-umbrella-root)))
          (or umbrella-app-root (mix--find-closest-mix-file-dir closest-path)))
      (mix--find-closest-mix-file-dir closest-path))))

(defun mix--umbrella-apps ()
  "Find directories with subprojects in the current umbrella app."
  (let ((closest-path (locate-dominating-file default-directory "apps")))
    (if closest-path
        (let* ((potential-umbrella-apps-path (concat closest-path "/apps"))
               (potential-umbrella-apps (delete "." (delete ".." (directory-files potential-umbrella-apps-path))))
               (potential-umbrella-app-directories
                (mapcar
                 (lambda (dir-name) (cons dir-name (mix--find-closest-mix-file-dir (concat potential-umbrella-apps-path "/" dir-name))))
                 potential-umbrella-apps)))
          (seq-filter (lambda (name-path-pair)
                        (let ((path (cdr name-path-pair)))
                          path)) potential-umbrella-app-directories)))))

(defun mix--find-closest-mix-file-dir (path)
  "Find the closest mix file to the current buffer PATH."
    (let ((root (locate-dominating-file path "mix.exs")))
    (when root
      (file-truename root))))

(defun mix--all-available-tasks (project-root)
  "List all available mix tasks for project in PROJECT-ROOT."
  (let ((tasks (mix--fetch-all-mix-tasks project-root)))
    (mix--filter-and-format-mix-tasks tasks)))

(defun mix--fetch-all-mix-tasks (project-root)
  "Fetches list of raw mix tasks from shell for project in PROJECT-ROOT.
Use `mix--all-available-tasks` to fetch formatted and filetered tasks."
    (let* ((default-directory (or project-root default-directory))
         (cmd (concat (shell-quote-argument mix-path-to-bin) " help"))
         (tasks-string (shell-command-to-string cmd)))
      (split-string tasks-string "\n")))

(defun mix--filter-and-format-mix-tasks (tasks)
  "Filter `iex -S mix` and `mix` commands and format mix TASKS."
  (let* ((tasks-without-iex
          (seq-filter
           (lambda (task)
             (and
              (not (or
                   (string-match-p "iex -S mix" task)
                   (string-match-p "Runs the default task" task)))
              (string-match-p "#" task)))
           tasks)))
    (mapcar #'mix--remove-mix-prefix-from-task tasks-without-iex)))

(defun mix--remove-mix-prefix-from-task (task)
  "Remove the first `mix` word from TASK string."
  (let* ((parts (split-string task "mix[[:blank:]]"))
        (parts-without-first-mix (cdr parts)))
    (concat (mapconcat #'identity parts-without-first-mix " "))))

(defun mix--output-filter ()
  "Remove control characters from output."
  (let ((buffer-read-only nil))
    (ansi-color-apply-on-region (point-min) (point-max))))

(defun mix--start (name command project-root &optional prompt)
  "Start the mix process NAME with the mix command COMMAND from PROJECT-ROOT.
Returns the created process.
If PROMPT is non-nil, modifies the command.  See `mix--prompt`."
  (let* ((buffer (concat "*mix " name "*"))
         (path-to-bin (shell-quote-argument mix-path-to-bin))
         (base-cmd (if (string-match-p path-to-bin  command)
                       command
                     (concat path-to-bin " " command)))
         (cmd (mix--prompt base-cmd prompt))
         (default-directory (or project-root default-directory)))
    (save-some-buffers (not compilation-ask-about-save)
                       (lambda ()
                         (and project-root
                              buffer-file-name
                              (string-prefix-p project-root (file-truename buffer-file-name)))))
    (setq mix--last-command (list name cmd project-root))
    (compilation-start cmd 'mix-mode (lambda(_) buffer))
    (get-buffer-process buffer)))

(defun mix--env-prompt ()
  "Prompt for a mix environment variable."
  (completing-read "mix-environment: " mix-envs nil nil mix-default-env))

(defun mix--current-test-path (full-path)
  "Return relative test file according to FULL-PATH.
If FULL-PATH contains `test` directory in its path, the function
will return a path relative to the `test` directory, otherwise the original
path will be returned."
  (let* ((parts (split-string full-path "/test/"))
         (test-file (car (cdr parts))))
    (if test-file
        (concat "test/" test-file)
      full-path)))

(defun mix--umbrella-subproject-prompt ()
  "Prompt for a umbrella subproject."
  (let* ((umbrella-apps (mix--umbrella-apps))
         (selected-app (completing-read "project: " (mix--umbrella-apps)))
         (selected-pair (seq-find (lambda (pair) (equal (car pair) selected-app)) umbrella-apps)))
    (cdr selected-pair)))

(defun mix--additional-params (command)
  "Prompt for additional mix task COMMAND params."
  (read-string (concat "additional mix task params for `" command "`: ")))

(defun mix--prompt (command prefix)
  "Promp for additional params for mix task.
If PREFIX is equal to (4), prompt for mix MIX_ENV
and prepend it to COMMAND.  If PREFIX is equal to (16).
prompt for additional params for mix task and append them to COMMAND.
IF PREFIX is equal to (64), prompt both for MIX_ENV and additional params."
  (cond ((equal prefix '(4)) (concat "MIX_ENV=" (mix--env-prompt) " " command))
        ((equal prefix '(16)) (concat command " " (mix--additional-params command)))
        ((equal prefix '(64)) (concat "MIX_ENV=" (mix--env-prompt) " " command " " (mix--additional-params command)))
        (t command)))

;;;###autoload
(defun mix-compile (&optional prefix use-umbrella-subprojects)
  "Run the mix compile command.
If PREFIX is non-nil, prompt for additional params.  See `mix--prompt`
IF USE-UMBRELLA-SUBPROJECTS is t, prompt for umbrells subproject."
  (interactive "P")
  (let ((project-root (if use-umbrella-subprojects (mix--umbrella-subproject-prompt) (mix--project-root))))
    (mix--start "compile" mix-command-compile project-root prefix)))

;;;###autoload
(defun mix-test (&optional prefix use-umbrella-subprojects)
  "Run the mix test command.
If PREFIX is non-nil, prompt for additional params.  See `mix--prompt`
IF USE-UMBRELLA-SUBPROJECTS is t, prompt for umbrells subproject."
  (interactive "P")
  (let ((project-root (if use-umbrella-subprojects (mix--umbrella-subproject-prompt) (mix--project-root))))
    (mix--start "test" mix-command-test project-root prefix)))

;;;###autoload
(defun mix-test-current-buffer (&optional prefix use-umbrella-subprojects)
  "Run the mix test for the current buffer.
If PREFIX is non-nil, prompt for additional params.  See `mix--prompt`.
IF USE-UMBRELLA-SUBPROJECTS is t, excutes a test from a subproject
where a file is located, otherwise starts from the umbrella root."
  (interactive "P")
  (let* ((current-file-path (expand-file-name buffer-file-name))
         (relative-path (mix--current-test-path current-file-path))
         (project-root (if use-umbrella-subprojects (mix--find-closest-mix-file-dir current-file-path) (mix--project-root)))
         (test-command (concat mix-command-test " " relative-path)))
    (mix--start "test" test-command project-root prefix)))

;;;###autoload
(defun mix-test-current-test (&optional prefix use-umbrella-subprojects)
  "Run the mix test for the curret test.
If PREFIX is non-nil, prompt for additional params.  See `mix--prompt`.
IF USE-UMBRELLA-SUBPROJECTS is t, excutes a test from a subproject
where a test is located, otherwise starts from the umbrella root."
  (interactive "P")
  (let* ((current-buffer-line-number (number-to-string (line-number-at-pos)))
         (current-file-path (expand-file-name buffer-file-name))
         (relative-file-path (mix--current-test-path current-file-path))
         (project-root (if use-umbrella-subprojects (mix--find-closest-mix-file-dir current-file-path) (mix--project-root)))
         (test-command (concat mix-command-test " " relative-file-path ":" current-buffer-line-number)))
    (mix--start "test" test-command project-root prefix)))

;;;###autoload
(defun mix-execute-task (&optional prefix use-umbrella-subprojects)
  "Select and run mix task.
If PREFIX is non-nil, prompt for additional params.  See `mix--prompt`
IF USE-UMBRELLA-SUBPROJECTS is t, prompt for umbrells subproject to start a mix task from."
  (interactive "P")
  (let* ((project-root (if use-umbrella-subprojects (mix--umbrella-subproject-prompt) (mix--project-root)))
         (task-with-doc (completing-read "select mix task: " (mix--all-available-tasks project-root)))
         (task-with-doc-list (split-string task-with-doc "#" t split-string-default-separators))
         (task-without-doc-list (if (eq (length task-with-doc-list) 1) task-with-doc-list (butlast task-with-doc-list)))
         (task (mapconcat #'identity task-without-doc-list  "")))
    (mix--start "execute" task project-root prefix)))

;;;###autoload
(defun mix-last-command ()
  "Execute the last mix task."
  (interactive)
  (if mix--last-command
      (apply #'mix--start mix--last-command)
    (message "Last command is not found.")))

(defvar mix-minor-mode-command-map
  (let ((km (make-sparse-keymap)))
    (define-key km (kbd "e") 'mix-execute-task)
    (define-key km (kbd "d e") (lambda (prefix) (interactive "P") (mix-execute-task prefix t)))
    (define-key km (kbd "t") 'mix-test)
    (define-key km (kbd "d t") (lambda (prefix) (interactive "P") (mix-test prefix t)))
    (define-key km (kbd "o") 'mix-test-current-buffer)
    (define-key km (kbd "d o") (lambda (prefix) (interactive "P") (mix-test-current-buffer prefix t)))
    (define-key km (kbd "f") 'mix-test-current-test)
    (define-key km (kbd "d f") (lambda (prefix) (interactive "P") (mix-test-current-test prefix t)))
    (define-key km (kbd "q") 'mix-compile)
    (define-key km (kbd "d q") (lambda (prefix) (interactive "P") (mix-compile prefix t)))
    (define-key km (kbd "l") 'mix-last-command)
    km)
  "Mix-mode keymap after prefix.")
(fset 'mix-minor-mode-command-map mix-minor-mode-command-map)

(defvar mix-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c d") 'mix-minor-mode-command-map)
    map)
  "Mix-mode keymap.")

;;;###autoload
(define-minor-mode mix-minor-mode
  "Mix minor mode. Used to hold keybindings for mix-mode.
\\{mix-minor-mode-map}"
  nil " mix" mix-minor-mode-map)

(provide 'mix)
;;; mix.el ends here
