;;; gotest.el --- Launch GO unit tests

;; Author: Nicolas Lamirault <nicolas.lamirault@gmail.com>
;; URL: https://github.com/nlamirault/gotest.el
;; Package-Version: 20210221.1905
;; Package-Commit: 9b1dc4eba1b22d751cb2f0a12e29912e010fac60
;; Version: 0.14.0
;; Keywords: languages, go, tests

;; Package-Requires: ((emacs "24.3") (s "1.11.0") (f "0.19.0") (go-mode "1.5.0"))

;; Copyright (C) 2014, 2015, 2016, 2017 Nicolas Lamirault <nicolas.lamirault@gmail.com>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.

;;; Commentary:

;;; Code:

(require 'compile)

(require 's)
(require 'f)
(require 'cl-lib)
(require 'go-mode)


(defgroup gotest nil
  "GoTest utility"
  :group 'go)

(defcustom go-test-verbose nil
  "Display debugging information during test execution."
  :type 'boolean
  :group 'gotest)

(defcustom go-test-gb-command "gb"
  "The 'gb' command.
A project based build tool for the Go programming language.
See https://getgb.io."
  :type 'string
  :group 'gotest)

(defvar-local go-test-args nil
  "Arguments to pass to go test.
  This variable is buffer-local, set using .dir-locals.el for example.")

(defvar-local go-run-args nil
  "Arguments to pass to go run.
  This variable is buffer-local, set using .dir-locals.el for example.")

(defvar go-test-history nil
  "History list for go test command arguments.")

(defvar go-run-history nil
  "History list for go run command arguments.")


;; Faces
;; -----------

(defface go-test--ok-face
  '((t (:foreground "#00ff00")))
  "Ok face"
  :group 'go-test)

(defface go-test--error-face
  '((t (:foreground "#FF0000")))
  "Error face"
  :group 'go-test)

(defface go-test--warning-face
  '((t (:foreground "#eeee00")))
  "Warning face"
  :group 'go-test)

(defface go-test--pointer-face
  '((t (:foreground "#ff00ff")))
  "Pointer face"
  :group 'go-test)

(defface go-test--standard-face
  '((t (:foreground "#ffa500")))
  "Standard face"
  :group 'go-test)



;; go-test mode
;; -----------------


(defvar go-test-mode-map
  (nconc (make-sparse-keymap) compilation-mode-map)
  "Keymap for Go test major mode.")

(defvar go-test-last-command nil
  "Command used last for repeating.")

(defvar go-test-additional-arguments-function nil
  "Function that can be used to programatically add arguments.

The function will receive the suite and test name as
arguments in that order.")


(defconst go-test-font-lock-keywords
  '(("error\\:" . 'go-test--error-face)
    ("testing: warning:.*" . 'go-test--warning-face)
    ("^\s*\\^\\~*\s*$" . 'go-test--pointer-face)
    ("^\s*Compilation.*" . 'go-test--standard-face)
    ("^\s*gb test.*" . 'go-test--standard-face)
    ("^\s*go test.*" . 'go-test--standard-face)
    ("^\s*Updating.*" . 'go-test--standard-face)
    (".*undefined.*" . 'go-test--warning-face)
    ("^\s*FATAL.*" . 'go-test--error-face)
    ("^\s*FAIL.*" . 'go-test--error-face)
    ("^\s*--- FATAL.*" . 'go-test--error-face)
    ("^\s*--- FAIL:.*" . 'go-test--error-face)
    ("^\s*=== RUN.*" . 'go-test--ok-face)
    ("^\s*--- PASS.*" . 'go-test--ok-face)
    ("^\s*PASS.*" . 'go-test--ok-face)
    ("^\s*ok.*" . 'go-test--ok-face)
    )
  "Minimal highlighting expressions for go-test mode.")

(define-derived-mode go-test-mode compilation-mode "Go-Test."
  "Major mode for the Go-Test compilation buffer."
  (use-local-map go-test-mode-map)
  (setq major-mode 'go-test-mode)
  (setq mode-name "Go-Test")
  (setq-local truncate-lines t)
  ;;(run-hooks 'go-test-mode-hook)
  (font-lock-add-keywords nil go-test-font-lock-keywords))

(defun go-test--compilation-name (mode-name)
  "Name of the go test.  MODE-NAME is unused."
  "*Go Test*")

(defun go-test--finished-sentinel (process event)
  "Execute after PROCESS return and EVENT is 'finished'."
  (compilation-sentinel process event)
  (when (equal event "finished\n")
    (message "Go Test finished.")))


(defvar go-test--current-test-cache nil
  "Store the suite and test of the last execution.")


(defvar go-test-regexp-prefix
  "^[[:space:]]*func[[:space:]]\\(([^()]*?)\\)?[[:space:]]*\\("
  "The prefix of the go-test regular expression.")

(defvar go-test-regexp-suffix
  "[[:alpha:][:digit:]_]*\\)("
  "The suffix of the go-test regular expression.")


(defvar go-test-compilation-error-regexp-alist-alist
  '((go-test-testing . ("^\t\\([[:alnum:]-_/.]+\\.go\\):\\([0-9]+\\): .*$" 1 2)) ;; stdlib package testing
    (go-test-testify . ("^\tLocation:\t\\([[:alnum:]-_/.]+\\.go\\):\\([0-9]+\\)$" 1 2)) ;; testify package assert
    (go-test-gopanic . ("^\t\\([[:alnum:]-_/.]+\\.go\\):\\([0-9]+\\) \\+0x\\(?:[0-9a-f]+\\)" 1 2)) ;; panic()
    (go-test-compile . ("^\\([[:alnum:]-_/.]+\\.go\\):\\([0-9]+\\):\\(?:\\([0-9]+\\):\\)? .*$" 1 2 3)) ;; go compiler
    (go-test-linkage . ("^\\([[:alnum:]-_/.]+\\.go\\):\\([0-9]+\\): undefined: .*$" 1 2))) ;; go linker
  "Alist of values for `go-test-compilation-error-regexp-alist'.
See also: `compilation-error-regexp-alist-alist'.")

(defcustom go-test-compilation-error-regexp-alist
  '(go-test-testing
    go-test-testify
    go-test-gopanic
    go-test-compile
    go-test-linkage)
  "Alist that specifies how to match errors in go test output.
The default set of regexps should only match the output of the
standard `go' tool, which includes compile, link, stacktrace (panic)
and package testing.  There is support for matching error output
from other packages, such as `testify'.

Only file names ending in `.go' will be matched by default.

Instead of an alist element, you can use a symbol, which is
looked up in `go-testcompilation-error-regexp-alist-alist'.

See also: `compilation-error-regexp-alist'."
  :type '(repeat (choice (symbol :tag "Predefined symbol")
                         (sexp :tag "Error specification")))
  :group 'gotest)


;; Commands
;; -----------


(defun go-test--get-program (args &optional env)
  "Return the command to launch unit test.
`ARGS' corresponds to go command line arguments.
When `ENV' concatenate before command."
  (if env
      (s-concat env " " go-command " test " args)
    (s-concat go-command " test " args)))


(defun go-test--gb-get-program (args)
  "Return the command to launch unit test using GB..
`ARGS' corresponds to go command line arguments."
  (s-concat go-test-gb-command " test " args))


(defun go-test--get-arguments (defaults history)
  "Get optional arguments for go test or go run.
DEFAULTS will be used when there is no prefix argument.
When a prefix argument of '- is given, use the most recent HISTORY item.
When single prefix argument is given, prompt for arguments using HISTORY.
When double prefix argument is given, run command in compilation buffer with
`comint-mode' enabled.
When triple prefix argument is given, prompt for arguments using HISTORY and
run command in compilation buffer `comint-mode' enabled.
When a numeric prefix argument is provided, it is used as the -count flag."
  (pcase current-prefix-arg
    (`nil defaults)
    ((pred integerp) (s-concat (format "-count=%d " current-prefix-arg) defaults))
    ((or `- `(16)) (car (symbol-value history)))
    ((or `(4) `(64)) (let* ((name (nth 1 (s-split "-" (symbol-name history))))
                            (prompt (s-concat "go " name " args: ")))
                       (read-shell-command prompt defaults history)))))


(defun go-test--get-root-directory()
  "Return the root directory to run tests."
  (let ((filename (buffer-file-name)))
    (when filename
      (file-truename (or (locate-dominating-file filename "Makefile")
                         "./")))))


(defun go-test--get-current-buffer ()
  "Return the test buffer for the current `buffer-file-name'.
If `buffer-file-name' ends with `_test.go', `current-buffer' is returned.
Otherwise, `ff-other-file-name' is used to find the test buffer.
For example, if the current buffer is `foo.go', the buffer for
`foo_test.go' is returned."
  (if (string-match "_test\.go$" buffer-file-name)
      (current-buffer)
    (let ((ff-always-try-to-create nil)
	  (filename (ff-other-file-name)))
      (when filename
	(find-file-noselect filename)))))


(defun go-test--get-current-data (prefix)
  "Return the current data: test, example or benchmark.
`PREFIX' defines token to place cursor."
  (let ((start (point))
        name)
    (save-excursion
      (end-of-line)
      (unless (and
               (search-backward-regexp
                (s-concat "^[[:space:]]*func[[:space:]]*" prefix) nil t)
               (save-excursion (go-end-of-defun) (< start (point))))
        (error "Unable to find data"))
      (save-excursion
        (search-forward prefix)
        (setq name (thing-at-point 'symbol t))))
    name))

(defun go-test--get-current-test-info ()
  "Return the current test and suite name."
  (save-excursion
    (end-of-line)
    (if (search-backward-regexp
         (format "%s\\(Test\\|Example\\)%s" go-test-regexp-prefix go-test-regexp-suffix)
         nil t)
        (let ((suite-match (match-string-no-properties 1))
              (test-match (match-string-no-properties 2)))
          (list
           (go-test--get-suite-name-from-match-string suite-match) test-match))
      (error "Unable to find a test"))))

(defun go-test--get-suite-name-from-match-string (the-match-string)
  (if (> (length the-match-string) 0)
      (progn (string-match "([^()]*?\\*\\([^()]*?\\))" the-match-string)
             (s-trim (match-string-no-properties 1 the-match-string)))
    ""))

(defun go-test--get-current-test ()
  "Return the current test name."
  (cadr (go-test--get-current-test-info)))

(defun go-test--get-current-benchmark ()
  "Return the current benchmark name."
  (go-test--get-current-data "Benchmark"))


(defun go-test--get-current-example ()
  "Return the current example name."
  (go-test--get-current-data "Example"))


(defun go-test--get-current-file-data (prefix)
  "Generate regexp to match test, benchmark or example the current buffer.
`PREFIX' defines token to place cursor."
  (let ((buffer (go-test--get-current-buffer)))
    (when buffer
      (with-current-buffer buffer
	(save-excursion
	  (goto-char (point-min))
	  (when (string-match "\.go$" buffer-file-name)
            (let ((regex
                   (s-concat "^[[:space:]]*func[[:space:]]*\\(" prefix "[^(]+\\)"))
                  result)
	      (while
                  (re-search-forward regex nil t)
		(let ((data (buffer-substring-no-properties
                             (match-beginning 1) (match-end 1))))
                  (setq result (append result (list data)))))
	      (mapconcat 'identity result "|"))))))))


(defun go-test--get-current-file-tests ()
  "Generate regexp to match test in the current buffer."
  (go-test--get-current-file-data "Test"))


(defun go-test--get-current-file-benchmarks ()
  "Generate regexp to match benchmark in the current buffer."
  (go-test--get-current-file-data "Benchmark"))


(defun go-test--get-current-file-examples ()
  "Generate regexp to match example in the current buffer."
  (go-test--get-current-file-data "Example"))


(defun go-test--get-current-file-testing-data ()
  "Regex with unit test and|or examples."
  (let ((tests (go-test--get-current-file-tests))
        (examples (go-test--get-current-file-examples)))
    (cond ((and (> (length tests) 0)
                (> (length examples) 0))
           (s-concat tests "|" examples))
          ((= (length tests) 0)
           examples)
          ((= (length examples) 0)
           tests))))


(defun go-test--arguments (args)
  "Make the go test command argurments using `ARGS'."
  (let ((opts args))
    (when go-test-args
      (setq opts (s-concat go-test-args " " opts)))
    (when go-test-verbose
      (setq opts (s-concat "-v " opts)))
    (go-test--get-arguments opts 'go-test-history)))


;; (defun go-test-compilation-hook (p)
;;   "Add compilation hooks."
;;   (set (make-local-variable 'compilation-error-regexp-alist-alist)
;;        go-test-compilation-error-regexp-alist-alist)
;;   (set (make-local-variable 'compilation-error-regexp-alist)
;;        go-test-compilation-error-regexp-alist))


;; (defun go-test-run (args)
;;   (add-hook 'compilation-start-hook 'go-test-compilation-hook)
;;   (compile (go-test--get-program (go-test--arguments args)))
;;   (remove-hook 'compilation-start-hook 'go-test-compilation-hook))

(defun go-test--go-test (args &optional env)
  "Start the go test command using `ARGS'."
  (let ((buffer "*Go Test*")) ; (concat "*go-test " args "*")))
    (go-test--cleanup buffer)
    (compilation-start (go-test--get-program (go-test--arguments args) env)
                       'go-test-mode
                       'go-test--compilation-name)
    (with-current-buffer "*Go Test*"
      (rename-buffer buffer))
    (set-process-sentinel (get-buffer-process buffer) 'go-test--finished-sentinel)))

(defun go-test--go-run-get-program (args)
  "Return the command to launch go run.
`ARGS' corresponds to go command line arguments."
  (s-concat go-command " run " args))

(defun go-test--go-run-arguments ()
  "Arguments for go run."
  (let ((opts (if go-run-args
                  (s-concat (shell-quote-argument (buffer-file-name)) " " go-run-args)
                (shell-quote-argument (buffer-file-name)))))
    (go-test--get-arguments opts 'go-run-history)))


;; (defun gb-test-run (args)
;;   "Test using GB.
;; `ARGS' corresponds to command line arguments."
;;   (add-hook 'compilation-start-hook 'go-test-compilation-hook)
;;   (compile (go-test--gb-get-program args))
;;   (remove-hook 'compilation-start-hook 'go-test-compilation-hook))


(defun go-test--is-gb-project ()
  "Check if project use GB or not."
  (let* ((go-test-gb-command (executable-find go-test-gb-command))
         (default-directory (if go-test-gb-command (go-test--get-root-directory))))
    (and go-test-gb-command
         default-directory
         (f-dir? "src")
         (f-exists? "vendor/manifest"))))

(defun go-test--cleanup (buffer)
  "Clean up the old go-test process BUFFER when a similar process is run."
  (when (get-buffer buffer)
    (when (get-buffer-process (get-buffer buffer))
      (delete-process buffer))
    (with-current-buffer buffer
      (setq buffer-read-only nil)
      (erase-buffer))))

(defun go-test--gb-start (args)
  "Start the GB test command using `ARGS'."
  (let ((buffer "*Go Test*")) ;(concat "*go-test " args "*")))
    (go-test--cleanup buffer)
    (compilation-start (go-test--gb-get-program (go-test--arguments args))
                       'go-test-mode
                       'go-test--compilation-name)
    (with-current-buffer "*Go Test*"
      (rename-buffer buffer))
    (set-process-sentinel (get-buffer-process buffer) 'go-test--finished-sentinel)))


(defun go-test--gb-find-package ()
  "Find package of current-file."
  (let* ((dir (s-concat (go-test--get-root-directory) "src/"))
         (filename (buffer-file-name))
         (pkg (f-filename filename)))
    (s-replace-all (list (cons dir "") (cons pkg "")) filename)))

; API
;; ----


;; Unit tests
;; ----------------------

;;;###autoload
(defun go-test-current-test-cache ()
  "Repeat the previous current test execution."
  (interactive)
  (go-test-current-test 'last))

;;;###autoload
(defun go-test-current-test (&optional last)
  "Launch go test on the current test."
  (interactive)
  (unless (string-equal (symbol-name last) "last")
    (setq go-test--current-test-cache (go-test--get-current-test-info)))
  (when go-test--current-test-cache
    (cl-destructuring-bind (test-suite test-name) go-test--current-test-cache
      (let ((test-flag (if (> (length test-suite) 0) "-testify.m " "-run "))
            (additional-arguments (if go-test-additional-arguments-function
                                      (funcall go-test-additional-arguments-function
                                               test-suite test-name) "")))
        (when test-name
          (if (go-test--is-gb-project)
              (go-test--gb-start (s-concat "-test.v=true -test.run=" test-name "\\$ ."))
            (go-test--go-test (s-concat test-flag test-name "\\$ . " additional-arguments))))))))


;;;###autoload
(defun go-test-current-file ()
  "Launch go test on the current buffer file."
  (interactive)
  (let ((data (go-test--get-current-file-testing-data)))
    (if (go-test--is-gb-project)
        (go-test--gb-start (s-concat "-test.v=true -test.run='" data "'"))
      (go-test--go-test (s-concat "-run='" data "' .")))))


;;;###autoload
(defun go-test-current-project ()
  "Launch go test on the current project."
  (interactive)
  (if (go-test--is-gb-project)
      (go-test--gb-start "all -test.v=true")
    (let ((packages (cl-remove-if (lambda (s) (s-contains? "/vendor/" s))
                                  (s-split "\n"
                                           (shell-command-to-string "go list ./...")))))
      (go-test--go-test (s-join " " packages)))))



;; Benchmarks
;; ----------------------


;;;###autoload
(defun go-test-current-benchmark ()
  "Launch go benchmark on current benchmark."
  (interactive)
  (let ((benchmark-name (go-test--get-current-benchmark)))
    (when benchmark-name
      (go-test--go-test (s-concat "-run ^NOTHING -bench " benchmark-name "\\$")))))


;;;###autoload
(defun go-test-current-file-benchmarks ()
  "Launch go benchmark on current file benchmarks."
  (interactive)
  (let ((benchmarks (go-test--get-current-file-benchmarks)))
    (go-test--go-test (s-concat "-run ^NOTHING -bench '" benchmarks "'"))))


;;;###autoload
(defun go-test-current-project-benchmarks ()
  "Launch go benchmark on current project."
  (interactive)
  (go-test--go-test (s-concat "-run ^NOTHING -bench .")))


;; Coverage
;; -------------


;;;###autoload
(defun go-test-current-coverage ()
  "Launch go test coverage on the current project."
  (interactive)
  (if (go-test--is-gb-project)
      (let* ((package (go-test--gb-find-package))
             (root-dir (go-test--get-root-directory))
             (gopath (s-concat "env GOPATH=" root-dir ":" root-dir "vendor")))
        (go-test--go-test (s-concat "-cover " package) gopath))
    (let ((args (s-concat
                 "--coverprofile="
                 (expand-file-name
                  (read-file-name "Coverage file" nil "cover.out")) " ./.")))
      (go-test--go-test args))))


;;;###autoload
(defun go-run (&optional args)
  "Launch go run on current buffer file."
  (interactive)
  ;;(add-hook 'compilation-start-hook 'go-test-compilation-hook)
  (compile (go-test--go-run-get-program (go-test--go-run-arguments))
           (pcase current-prefix-arg
             ((or `(16) `(64)) t)))
  ;;(remove-hook 'compilation-start-hook 'go-test-compilation-hook))
  )



(provide 'gotest)
;;; gotest.el ends here
