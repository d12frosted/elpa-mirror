;;; cargo-mode.el --- Cargo Major Mode. Cargo is the Rust package manager -*- lexical-binding: t; -*-

;; MIT License
;;
;; Copyright (c) 2021 Ayrat Badykov
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
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
;; URL: https://github.com/ayrat555/cargo-mode
;; Package-Version: 20210605.1003
;; Package-Commit: b98ea60ddec30eac174012671ee09e125748a193
;; Version  : 0.0.1
;; Keywords: tools
;; Package-Requires: ((emacs "25.1"))

;;; Commentary:

;; Add a hook to the mode that you're using with Rust, for example, `rust-mode`:
;;
;; (add-hook 'rust-mode-hook 'cargo-minor-mode)
;;

;;; C-q e e - `cargo-execute-task` - List all available tasks and execute one of them.  As a bonus, you'll get a documentation string because `cargo-mode.el` parses shell output of `cargo --list` directly.
;;; C-q e t - `cargo-mode-test` - Run all tests in the project (`cargo test`).
;;; C-q e l - `cargo-mode-last-command` - Execute the last executed command.
;;; C-q e b - `cargo-mode-build` - Build the project (`cargo build`).
;;; C-q e o - `cargo-mode-test-current-buffer` - Run all tests in the current buffer.
;;; C-q e f - `cargo-mode-test-current-test` - Run the current test where pointer is located.
;;;
;;; Use `C-u` to add extra command line params before executing a command.

;;; Code:

(require 'subr-x)

(defcustom cargo-path-to-bin
  (or (executable-find "cargo")
      "~/.cargo/bin/cargo")
  "Path to the cargo executable."
  :type 'file
  :group 'cargo-mode)

(defcustom cargo-mode-command-test "test"
  "Subcommand used by `cargo-mode-test'."
  :type 'string
  :group 'cargo-mode)

(defcustom cargo-mode-command-build "build"
  "Subcommand used by `cargo-mode-build'."
  :type 'string
  :group 'cargo-mode)

(defconst cargo-mode-test-mod-regexp "^[[:space:]]*mod[[:space:]]+[[:word:][:multibyte:]_][[:word:][:multibyte:]_[:digit:]]*[[:space:]]*{")

(defconst cargo-mode-test-regexp "^[[:space:]]*fn[[:space:]]*"
  "Regex to find Rust unit test function.")

(defvar cargo-mode--last-command nil "Last cargo command.")

(define-derived-mode cargo-mode compilation-mode "Cargo"
  "Major mode for the Cargo buffer."
  (setq buffer-read-only t)
  (setq-local truncate-lines t))

(defun cargo-mode--fetch-cargo-tasks (project-root)
  "Fetch list of raw commands from shell for project in PROJECT-ROOT."
  (let* ((default-directory (or project-root default-directory))
         (cmd (concat (shell-quote-argument cargo-path-to-bin) " --list"))
         (tasks-string (shell-command-to-string cmd))
         (tasks (butlast (cdr (split-string tasks-string "\n")))))
    (delete-dups tasks)))

(defun cargo-mode--available-tasks (project-root)
  "List all available tasks in PROJECT-ROOT."
  (let* ((raw_tasks (cargo-mode--fetch-cargo-tasks project-root))
         (commands (mapcar #'cargo-mode--split-command raw_tasks)))
    (cargo-mode--format-commands commands)))

(defun cargo-mode--format-commands (commands)
  "Format and concat all COMMANDS."
  (let ((max-length (cargo-mode--max-command-length (car commands) (cdr commands))))
    (mapcar
     (lambda (command) (cargo-mode--concat-command-and-doc command max-length))
     commands)))

(defun cargo-mode--concat-command-and-doc (command-with-doc max-command-length)
  "Concat the COMMAND-WITH-DOC with calcutated.
Space between them is based on MAX-COMMAND-LENGTH."
  (let* ((command (car command-with-doc))
        (doc (cdr command-with-doc))
        (command-length (length command))
        (whitespaces-number (- (+ max-command-length 1) command-length))
        (whitespaces-string (make-string whitespaces-number ?\s)))
    (concat command whitespaces-string "# " doc)))

(defun cargo-mode--split-command (raw-command)
  "Split command and doc string in RAW-COMMAND."
  (let* ((command-words (split-string raw-command))
         (command (car command-words))
         (doc-words (cdr command-words))
         (doc (concat (mapconcat #'identity doc-words " "))))
    (cons command doc)))

(defun cargo-mode--max-command-length (first-arg more-args)
  "Recursively find the longest command.
The current element is FIRST-ARG, remaining args are MORE-ARGS."
  (if more-args
      (let ((max-rest (cargo-mode--max-command-length (car more-args) (cdr more-args)))
            (first-arg-length (length (car first-arg))))
	(if (> first-arg-length max-rest)
	    first-arg-length
	  max-rest))
    (length (car first-arg))))

(defun cargo-mode--start (name command project-root &optional prompt)
  "Start the `cargo-mode` process with NAME and return the created process.
Cargo command is COMMAND.
The command is  started from directory PROJECT-ROOT.
If PROMPT is non-nil, modifies the command."
  (let* ((buffer (concat "*cargo-mode " name "*"))
         (path-to-bin (shell-quote-argument cargo-path-to-bin))
         (base-cmd (if (string-match-p path-to-bin command)
                  command
                  (concat path-to-bin " " command)))
         (cmd (cargo-mode--maybe-add-additional-params base-cmd prompt))
         (default-directory (or project-root default-directory)))
    (save-some-buffers (not compilation-ask-about-save)
                       (lambda ()
                         (and project-root
                              buffer-file-name
                              (string-prefix-p project-root (file-truename buffer-file-name)))))
    (setq cargo-mode--last-command (list name cmd project-root))
    (compilation-start cmd 'cargo-mode (lambda(_) buffer))
    (get-buffer-process buffer)))

(defun cargo-mode--project-directory ()
  "Find the project directory."
  (let ((closest-path (or buffer-file-name default-directory)))
    (locate-dominating-file closest-path "Cargo.toml")))

(defun cargo-mode--current-mod ()
  "Return the current mod."
  (save-excursion
    (when (search-backward-regexp cargo-mode-test-mod-regexp nil t)
      (let* ((line (buffer-substring-no-properties (line-beginning-position)
                                                   (line-end-position)))
             (line (string-trim-left line))
             (lines (split-string line " \\|{"))
             (mod (cadr lines)))
        mod))))

(defun cargo-mode--defun-at-point-p ()
  "Find fn at point."
  (string-match cargo-mode-test-regexp
                (buffer-substring-no-properties (line-beginning-position)
                                                (line-end-position))))

(defun cargo-mode--current-test ()
  "Return the current test."
  (save-excursion
    (unless (cargo-mode--defun-at-point-p)
      (cond ((fboundp 'rust-beginning-of-defun)
	     (rust-beginning-of-defun))
	    ((fboundp 'rustic-beginning-of-defun)
	     (rustic-beginning-of-defun))
	    (t (user-error "%s needs either rust-mode or rustic-mode"
			   this-command))))
    (beginning-of-line)
    (search-forward "fn ")
    (let* ((line (buffer-substring-no-properties (point)
                                                 (line-end-position)))
           (lines (split-string line "("))
           (function-name (car lines)))
      function-name)))

(defun cargo-mode--current-test-fullname ()
  "Return the current test's fullname."
  (let ((mod-name (cargo-mode--current-mod)))
    (if mod-name
        (concat mod-name
                "::"
                (cargo-mode--current-test))
      (cargo-mode--current-test))))

(defun cargo-mode--maybe-add-additional-params (command prefix)
  "Prompt for additional cargo command COMMAND params.
If PREFIX is nil, it does nothing"
  (if prefix
      (let  ((params (read-string (concat "additional cargo command params for `" command "`: "))))
        (concat command " " params))
    command))

;;;###autoload
(defun cargo-mode-execute-task (&optional prefix)
  "Select and execute cargo task.
If PREFIX is non-nil, prompt for additional params."
  (interactive "P")
  (let* ((project-root (cargo-mode--project-directory))
         (available-commands (cargo-mode--available-tasks project-root))
         (selected-command (completing-read "select cargo command: " available-commands))
         (command-without-doc (car (split-string selected-command))))
    (cargo-mode--start "execute" command-without-doc project-root prefix)))

;;;###autoload
(defun cargo-mode-test (&optional prefix)
  "Run the `cargo test` command.
If PREFIX is non-nil, prompt for additional params."
  (interactive "P")
  (let ((project-root (cargo-mode--project-directory)))
    (cargo-mode--start "test" cargo-mode-command-test project-root prefix)))

;;;###autoload
(defun cargo-mode-build (&optional prefix)
  "Run the `cargo build` command.
If PREFIX is non-nil, prompt for additional params."
  (interactive "P")
  (let ((project-root (cargo-mode--project-directory)))
    (cargo-mode--start "execute" cargo-mode-command-build project-root prefix)))

;;;###autoload
(defun cargo-mode-test-current-buffer (&optional prefix)
  "Run the cargo test for the current buffer.
If PREFIX is non-nil, prompt for additional params."
  (interactive "P")
  (let* ((project-root (cargo-mode--project-directory))
        (current-mod (print (cargo-mode--current-mod)))
        (command (concat cargo-mode-command-test " "  current-mod)))
    (cargo-mode--start "test" command project-root prefix)))

;;;###autoload
(defun cargo-mode-test-current-test (&optional prefix)
  "Run the Cargo test command for the current test.
If PREFIX is non-nil, prompt for additional params."
  (interactive "P")
  (let* ((project-root (cargo-mode--project-directory))
         (test-name (cargo-mode--current-test-fullname))
         (command (concat cargo-mode-command-test " " test-name)))
    (cargo-mode--start "test" command project-root prefix)))

;;;###autoload
(defun cargo-mode-last-command ()
  "Execute the last `cargo-mode` task."
  (interactive)
  (if cargo-mode--last-command
      (apply #'cargo-mode--start cargo-mode--last-command)
    (message "Last command is not found.")))

(defvar cargo-mode-command-map
  (let ((km (make-sparse-keymap)))
    (define-key km (kbd "b") 'cargo-mode-build)
    (define-key km (kbd "e") 'cargo-mode-execute-task)
    (define-key km (kbd "l") 'cargo-mode-last-command)
    (define-key km (kbd "t") 'cargo-mode-test)
    (define-key km (kbd "o") 'cargo-mode-test-current-buffer)
    (define-key km (kbd "f") 'cargo-mode-test-current-test)
    km)
  "Cargo-mode keymap after prefix.")
(fset 'cargo-mode-command-map cargo-mode-command-map)

(defvar cargo-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-q e") 'cargo-mode-command-map)
    map)
  "Cargo-map keymap.")

;;;###autoload
(define-minor-mode cargo-minor-mode
  "Cargo minor mode. Used to hold keybindings for cargo-mode.
\\{cargo-minor-mode-map}"
  nil " cargo" cargo-minor-mode-map)

(provide 'cargo-mode)
;;; cargo-mode.el ends here
