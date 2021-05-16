;;; bazel.el --- Bazel support for Emacs -*- lexical-binding: t; -*-

;; URL: https://github.com/bazelbuild/emacs-bazel-mode
;; Package-Version: 20210516.1724
;; Package-Commit: 56113b72d2016e9827e84a579abc700884590074
;; Keywords: build tools, languages
;; Package-Requires: ((emacs "26.1"))
;; Version: 0

;; Copyright (C) 2018, 2021 Google LLC
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;      http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:

;; This package provides support for the Bazel build system.  See
;; https://bazel.build/ for background on Bazel.
;;
;; The package provides four major modes for editing Bazel-related files:
;; ‘bazel-build-mode’ for BUILD files, ‘bazel-workspace-mode’ for WORKSPACE
;; files, ‘bazelrc-mode’ for .bazelrc configuration files, and
;; ‘bazel-starlark-mode’ for extension files written in the Starlark language.
;; These modes also extend Imenu and ‘find-file-at-point’ to support
;; Bazel-specific syntax.
;;
;; If Buildifier is available, the ‘bazel-mode-flymake’ backend for Flymake
;; provides on-the-fly syntax checking for Bazel files.  You can also run
;; Buildifier manually using the ‘bazel-buildifier’ command to reformat a Bazel
;; file buffer.
;;
;; The Bazel modes integrate with Xref to provide basic functionality to jump to
;; the definition of Bazel targets.
;;
;; To simplify running Bazel commands, the package provides the commands
;; ‘bazel-build’, ‘bazel-test’, ‘bazel-coverage’ and ‘bazel-run’, which execute
;; the corresponding Bazel commands in a compilation mode buffer.  In a buffer
;; that visits a test file, you can also have Emacs try to detect and execute
;; the test at point using ‘bazel-test-at-point’.
;;
;; When editing a WORKSPACE file, you can use the command
;; ‘bazel-insert-http-archive’ to quickly insert an http_archive rule.
;;
;; You can customize some aspects of this package using the ‘bazel’
;; customization group.  If you set the user option ‘bazel-display-coverage’ to
;; a non-nil value and then run ‘bazel coverage’ (either using the ‘compile’ or
;; ‘bazel-coverage’ command), the package will display code coverage status in
;; buffers that visit instrumented files, using the faces ‘bazel-covered-line’
;; and ‘bazel-uncovered-line’ for covered and uncovered lines, respectively.

;;; Code:

(require 'cl-lib)
(require 'compile)
(require 'easymenu)
(require 'ffap)
(require 'imenu)
(require 'json)
(require 'project)
(require 'python)
(eval-when-compile (require 'subr-x))
(require 'testcover)
(require 'which-func)
(require 'xref)

;;;; Customization options

(defgroup bazel nil
  "Package for editing, building, and running code using Bazel."
  :link '(url-link "https://bazel.build")
  :link '(url-link "https://github.com/bazelbuild/emacs-bazel-mode")
  :group 'languages)

(define-obsolete-variable-alias 'bazel-build-bazel-command
  'bazel-command "2021-04-13")

(defcustom bazel-command '("bazel")
  "Command and arguments that should be used to invoke Bazel."
  :type '(repeat string)
  :risky t
  :group 'bazel)

(define-obsolete-variable-alias 'bazel-mode-buildifier-command
  'bazel-buildifier-command "2021-04-13")

(defcustom bazel-buildifier-command "buildifier"
  "Command to run Buildifier."
  :type 'string
  :risky t
  :group 'bazel
  :link '(url-link
          "https://github.com/bazelbuild/buildtools/tree/master/buildifier"))

(define-obsolete-variable-alias 'bazel-mode-buildifier-before-save
  'bazel-buildifier-before-save "2021-04-13")

(defcustom bazel-buildifier-before-save nil
  "Specifies whether to run Buildifier in `before-save-hook'."
  :type 'boolean
  :group 'bazel
  :link '(url-link
          "https://github.com/bazelbuild/buildtools/tree/master/buildifier")
  :risky t)

(defun bazel--initialize-test-at-point-functions (option value)
  "Initialize the option ‘bazel-test-at-point-functions’.
See Info node ‘(elisp) Variable Definitions’ for an explanation
of the OPTION and VALUE arguments."
  (cl-check-type option symbol)
  (dolist (function (eval value t))
    (add-hook option function 80)))

(defcustom bazel-test-at-point-functions '(which-function)
  "Abnormal hook to find a test case at point.
Each function in this hook should check whether it recognizes the
area around point as a test case, and return a string that can be
used as value for Bazel’s --test_filter option if so.  The
default value of this option includes ‘which-function’ at low
priority."
  :type 'hook
  :options '(which-function)
  :initialize #'bazel--initialize-test-at-point-functions
  :group 'bazel
  :link '(url-link
          "https://docs.bazel.build/user-manual.html#flag--test_filter")
  :link '(url-link "https://docs.bazel.build/test-encyclopedia.html")
  :risky t)

(defcustom bazel-display-coverage nil
  "Specifies whether to parse compilation buffers for coverage information.
If nil, don’t attempt to find coverage information in compilation
buffers.  If t, always search for coverage information, and
display the coverage status in buffers that visit covered files.
If ‘local’, only do so for local files."
  :type '(radio (const :tag "Never" nil)
                (const :tag "Always" t)
                (const :tag "Only for local files" local))
  :group 'bazel)

(defface bazel-covered-line '((default :extend t)
                              ;; Various shades of green.
                              (((background dark)) :background "#3D5C3A")
                              (t :background "#BEFFB8"))
  "Face for lines covered by unit tests."
  :group 'bazel)

(defface bazel-uncovered-line '((t :inherit testcover-nohits :extend t))
  "Face for lines not covered by unit tests."
  :group 'bazel)

;;;; Commands to run Buildifier.
(defvar-local bazel--buildifier-type nil
  "Type of the file that the current buffer visits.
This must be a symbol and a valid value for the Buildifier -type
flag.  See
https://github.com/bazelbuild/buildtools/blob/2.2.0/buildifier/utils/flags.go#L11.
If nil, don’t pass a -type flag to Buildifier.")

(eval-when-compile
  (defmacro bazel--with-temp-files (bindings &rest body)
    "Evaluate BINDINGS as in ‘let*’ and evaluate BODY.
Assume that each of the binding forms returns the name of a
temporary file.  After BODY finishes, delete the temporary files."
    (declare (debug let*) (indent 1))
    (if bindings
        (cl-destructuring-bind ((var val) . rest) bindings
          (cl-check-type var symbol)
          (let ((file (make-symbol "file")))
            `(let ((,file ,val))
               (unwind-protect
                   (let ((,var ,file))
                     (bazel--with-temp-files ,rest ,@body))
                 (delete-file ,file)))))
      (macroexp-progn body))))

(defun bazel-buildifier (&optional type)
  "Format current buffer using Buildifier.
If TYPE is nil, detect the file type from the current major mode
and visited filename, if available.  Otherwise, TYPE must be one
of the symbols ‘build’, ‘bzl’, or ‘workspace’, corresponding to
the file types documented at URL
‘https://github.com/bazelbuild/buildtools/tree/master/buildifier#usage’."
  (interactive "*")
  (cl-check-type type (member nil build bzl workspace))
  (let ((input-buffer (current-buffer))
        (directory default-directory)
        (input-file buffer-file-name)
        (buildifier-buffer (get-buffer-create "*buildifier*"))
        (type (or type bazel--buildifier-type)))
    ;; Run Buildifier on a file to support remote BUILD files.
    (bazel--with-temp-files ((buildifier-input-file
                              (make-nearby-temp-file "buildifier-input-"))
                             (buildifier-error-file
                              (make-nearby-temp-file "buildifier-error-")))
      (write-region (point-min) (point-max) buildifier-input-file nil :silent)
      (with-current-buffer buildifier-buffer
        (setq-local inhibit-read-only t)
        (erase-buffer)
        (cl-flet ((maybe-unquote (if (< emacs-major-version 28)
                                     #'file-name-unquote  ; Bug#48177
                                   #'identity)))
          (let* ((default-directory directory)
                 (temporary-file-directory
                  (maybe-unquote temporary-file-directory))
                 (return-code
                  (apply #'process-file
                         bazel-buildifier-command
                         (maybe-unquote buildifier-input-file)
                         `(t ,buildifier-error-file) nil
                         (bazel--buildifier-file-flags type input-file))))
            (if (eq return-code 0)
                (progn
                  (set-buffer input-buffer)
                  (replace-buffer-contents buildifier-buffer)
                  (kill-buffer buildifier-buffer))
              (with-temp-buffer-window buildifier-buffer nil nil
                (insert-file-contents buildifier-error-file)
                (compilation-minor-mode)))))))))

(define-obsolete-function-alias 'bazel-mode-buildifier
  #'bazel-buildifier "2021-04-13")

(defun bazel--buildifier-before-save-hook ()
  "Run buildifer in `before-save-hook'."
  (when bazel-buildifier-before-save
    (bazel-buildifier)))

;;;; ‘bazel-mode’ and child modes

(defconst bazel--magic-comment-regexp
  (rx (or "keep sorted"
          "do not sort"
          "@unused"
          "@unsorted-dict-items"
          "buildifier: leave-alone"
          (seq (or "buildifier" "buildozer") ": "
               "disable=" (+ (any "A-Za-z-")))))
  "Regular expression identifying magic comments known to Buildifier.

Many of these are documented at
URL `https://github.com/bazelbuild/buildtools/blob/master/WARNINGS.md'.

The magic comments \"keep sorted\", \"do not sort\", and
\"buildifier: leave-alone\" don't look to be documented, but are
mentioned in the Buildifier source code at URL
`https://git.io/JOuVL' and have tests.")

(defconst bazel-font-lock-keywords-1
  ;; Only include file directives.  See Info node ‘(elisp) Levels of Font Lock’.
  `((,(regexp-opt '("workspace") 'symbols) . 'font-lock-builtin-face)
    (,(regexp-opt '("load") 'symbols) . 'font-lock-keyword-face))
  "Value of ‘font-lock-keywords’ in ‘bazel-mode’ at font lock level 1.")

(defconst bazel-font-lock-keywords-2
  `(,@bazel-font-lock-keywords-1
    ;; Include keywords and constants.  Keywords for BUILD files are the same as
    ;; Starlark files.  Even if some of them are forbidden in BUILD files, they
    ;; should be highlighted.  See
    ;; https://github.com/bazelbuild/starlark/blob/master/spec.md.
    (,(regexp-opt '("and" "else" "for" "if" "in" "not" "or" "load"
                    "break" "continue" "def" "pass" "elif" "return")
                  'symbols)
     . 'font-lock-keyword-face)
    ;; Reserved keywords
    (,(regexp-opt '("as" "is" "assert" "lambda" "class" "nonlocal" "del" "raise"
                    "except" "try" "finally" "while" "from" "with" "global"
                    "yield" "import")
                  'symbols)
     . 'font-lock-keyword-face)
    ;; Constants
    (,(regexp-opt '("True" "False" "None")
                  'symbols)
     . 'font-lock-constant-face))
  "Value of ‘font-lock-keywords’ in ‘bazel-mode’ at font lock level 2.")

(defconst bazel-font-lock-keywords-3
  `(,@bazel-font-lock-keywords-2
    ;; Include builtin functions.  Some Starlark functions are exposed to BUILD
    ;; files as builtins.  For details see
    ;; https://github.com/bazelbuild/starlark/blob/master/spec.md.
    (,(regexp-opt '("exports_files" "glob" "licenses" "package"
                    "package_group" "select" "workspace")
                  'symbols)
     . 'font-lock-builtin-face)
    ;; Target names
    (bazel--find-target-name 2 'font-lock-variable-name-face prepend)
    ;; Magic comments
    (bazel--find-magic-comment 0 'font-lock-preprocessor-face prepend))
  "Value of ‘font-lock-keywords’ in ‘bazel-mode’ at font lock level 3.")

(defconst bazel-font-lock-keywords bazel-font-lock-keywords-1
  "Default value of ‘font-lock-keywords’ in ‘bazel-mode’.")

(defconst bazel-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; single line comment start
    (modify-syntax-entry ?# "<" table)
    ;; single line comment end
    (modify-syntax-entry ?\n ">" table)
    ;; strings using single quotes
    (modify-syntax-entry ?' "\"" table)
    table)
  "Syntax table for `bazel-mode'.")

(defvar bazel-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-b") #'bazel-build)
    (define-key map (kbd "C-c C-t") #'bazel-test)
    (define-key map (kbd "C-c C-c") #'bazel-coverage)
    (define-key map (kbd "C-c C-r") #'bazel-run)
    (define-key map (kbd "C-c C-f") #'bazel-buildifier)
    map)
  "Keymap for ‘bazel-mode’.")

(define-derived-mode bazel-mode prog-mode "Bazel"
  "Major mode for editing Bazel BUILD and WORKSPACE files.
This is the parent mode for the more specific modes
‘bazel-build-mode’, ‘bazel-workspace-mode’, and
‘bazel-starlark-mode’."
  ;; Almost all Starlark code in existence uses 4 spaces for indentation.
  ;; Buildifier also enforces this style.
  (setq-local tab-width 4)
  (setq-local indent-tabs-mode nil)
  ;; Take over some syntactic constructs from ‘python-mode’.
  (setq-local comment-start "# ")
  (setq-local comment-start-skip (rx (+ ?#) (* (syntax whitespace))))
  (setq-local comment-end "")
  (setq-local comment-use-syntax t)
  (setq-local parse-sexp-ignore-comments t)
  (setq-local forward-sexp-function #'python-nav-forward-sexp)
  (setq-local font-lock-defaults '((bazel-font-lock-keywords
                                    bazel-font-lock-keywords-1
                                    bazel-font-lock-keywords-2
                                    bazel-font-lock-keywords-3)))
  (setq-local syntax-propertize-function python-syntax-propertize-function)
  (setq-local indent-line-function #'python-indent-line-function)
  (setq-local indent-region-function #'python-indent-region)
  (setq-local electric-indent-inhibit t)
  ;; Treat magic comments as being separate paragraphs for filling.
  (setq-local paragraph-start
              (rx-to-string
               `(or (seq (* (syntax whitespace)) (regexp ,comment-start-skip)
                         (regexp ,bazel--magic-comment-regexp))
                    (regexp ,paragraph-start))
               :no-group))
  (setq-local add-log-current-defun-function #'bazel-mode-current-rule-name)
  (add-hook 'before-save-hook #'bazel--buildifier-before-save-hook nil :local)
  (add-hook 'flymake-diagnostic-functions #'bazel-mode-flymake nil :local)
  (add-hook 'xref-backend-functions #'bazel-mode-xref-backend nil :local)
  (add-hook 'completion-at-point-functions #'bazel-completion-at-point
            nil :local))

;;;###autoload
(define-derived-mode bazel-build-mode bazel-mode "Bazel BUILD"
  "Major mode for editing Bazel BUILD files."
  (setq bazel--buildifier-type 'build)
  ;; In BUILD files, we don’t have function definitions.  Instead, treat rules
  ;; (= Python statements) as functions.
  (setq-local beginning-of-defun-function #'python-nav-beginning-of-statement)
  (setq-local end-of-defun-function #'python-nav-end-of-statement)
  (setq-local imenu-create-index-function #'bazel-mode-create-index))

;;;###autoload
(add-to-list 'auto-mode-alist
             ;; https://docs.bazel.build/versions/3.0.0/build-ref.html#packages
             (cons (rx ?/ (or "BUILD" "BUILD.bazel") eos) #'bazel-build-mode))

;;;###autoload
(define-derived-mode bazel-workspace-mode bazel-mode "Bazel WORKSPACE"
  "Major mode for editing Bazel WORKSPACE files."
  (setq bazel--buildifier-type 'workspace)
  ;; In WORKSPACE files, we don’t have function definitions.  Instead, treat
  ;; rules (= Python statements) as functions.
  (setq-local beginning-of-defun-function #'python-nav-beginning-of-statement)
  (setq-local end-of-defun-function #'python-nav-end-of-statement)
  (setq-local imenu-create-index-function #'bazel-mode-create-index))

;;;###autoload
(add-to-list 'auto-mode-alist
             ;; https://docs.bazel.build/versions/3.0.0/build-ref.html#workspace
             (cons (rx ?/ (or "WORKSPACE" "WORKSPACE.bazel") eos)
                   #'bazel-workspace-mode))

;;;###autoload
(define-derived-mode bazel-starlark-mode bazel-mode "Starlark"
  "Major mode for editing Bazel Starlark files."
  (setq bazel--buildifier-type 'bzl)
  ;; In Starlark files, we do have Python-like function definitions, so use the
  ;; Python commands to navigate.
  (setq-local beginning-of-defun-function #'python-nav-beginning-of-defun)
  (setq-local end-of-defun-function #'python-nav-end-of-defun)
  (setq-local imenu-extract-index-name-function
              #'bazel-mode-extract-function-name))

;;;###autoload
(add-to-list 'auto-mode-alist
             ;; https://docs.bazel.build/versions/3.0.0/skylark/concepts.html#getting-started
             (cons (rx ?/ (+ nonl) ".bzl" eos) #'bazel-starlark-mode))

(define-skeleton bazel-insert-http-archive
  "Insert an “http_archive” statement at point.
See URL
‘https://docs.bazel.build/versions/master/repo/http.html#http_archive’
for a description of “http_archive”.  Interactively, prompt for
an archive URL.  Attempt to detect workspace name and prefix.
Also add the date when the archive was likely last modified as a
comment."
  "Archive download URL: "
  '(eval str t)  ; force prompt now
  '(setq v1 (bazel--download-http-archive str))  ; (name hash prefix time)
  "http_archive(" \n
  "name = \"" (or (nth 0 v1) '_) "\"," \n
  "sha256 = \"" (nth 1 v1) "\"," \n
  "strip_prefix = \"" (nth 2 v1) "\"," \n
  "urls = [" \n
  ?\" str "\",  # " (format-time-string "%F" (nth 3 v1) t) \n
  "]," > \n
  ?\) >)

(defun bazel--download-http-archive (url)
  "Download and interpret HTTP archive at URL.
Return a list (NAME SHA-256 PREFIX TIME) for
‘bazel-insert-http-archive’."
  (cl-check-type url string)
  (let* ((temp-dir (make-temp-file "bazel-http-archive-" :directory))
         (archive-file (expand-file-name (url-file-nondirectory url) temp-dir))
         (reporter (make-progress-reporter
                    (format-message "Downloading %s into %s..." url temp-dir)))
         (coding-system-for-read 'no-conversion)
         (coding-system-for-write 'no-conversion))
    (url-copy-file url archive-file)
    (progress-reporter-update reporter)
    (let* ((archive-dir
            ;; Prefer TRAMP’s archive support if available.
            (if (bound-and-true-p tramp-archive-enabled)
                (file-name-as-directory (file-name-unquote archive-file))
              ;; Fall back to extracting the archive locally.
              (let ((dir (expand-file-name "extract/" temp-dir)))
                (make-directory dir)
                (bazel--extract-archive archive-file dir)
                (progress-reporter-update reporter)
                dir)))
           (prefix-and-time
            ;; A prefix must be unique.
            (pcase (directory-files-and-attributes
                    archive-dir nil directory-files-no-dot-files-regexp)
              (`((,name t ,_ ,_ ,_ ,_ ,time . ,_))
               (progress-reporter-update reporter)
               (cons (file-name-as-directory name) time))
              ('nil (user-error "Empty archive"))
              (`(,_ . ,_) (user-error "No unique prefix in archive"))))
           (prefix (car prefix-and-time))
           (time (cdr prefix-and-time))
           (root-dir (expand-file-name prefix archive-dir))
           (name (when-let ((workspace (locate-file "WORKSPACE" (list root-dir)
                                                    '(".bazel" ""))))
                   (with-temp-buffer
                     (insert-file-contents workspace)
                     (bazel-workspace-mode)
                     (progress-reporter-update reporter)
                     (bazel--workspace-name))))
           (sha256 (with-temp-buffer
                     (insert-file-contents-literally archive-file)
                     (progress-reporter-update reporter)
                     (secure-hash 'sha256 (current-buffer)))))
      ;; We delete the temporary directory only when successful to make
      ;; debugging easier.
      (delete-directory temp-dir :recursive)
      (progress-reporter-done reporter)
      (list name sha256 prefix time))))

(defun bazel--extract-archive (file directory)
  ;; Prefer BSD tar if installed, as it supports more archive types.
  (let ((program (cl-some #'executable-find '("bsdtar" "tar"))))
    (unless program
      (user-error "Don’t know how to extract %s" file))
    (with-temp-buffer
      (let ((status (call-process program nil t nil
                                  "-x"
                                  "-f" (file-name-unquote file)
                                  "-C" (file-name-unquote directory))))
        (unless (eql status 0)
          (error "Program %s failed with status %s, output %s"
                 program status (buffer-string)))))))

(defun bazel--workspace-name ()
  "Return the name of the workspace.
The current buffer should contain the contents of a Bazel
WORKSPACE file.  Look around for a “workspace” statement and
return its name.  See URL
‘https://docs.bazel.build/versions/4.0.0/skylark/lib/globals.html#workspace’."
  (save-excursion
    (goto-char (point-min))
    (cl-block nil
      (while (progn (forward-comment (buffer-size))
                    (re-search-forward (rx symbol-start "workspace(") nil t))
        (forward-comment (buffer-size))
        (unless (or (eobp) (python-syntax-comment-or-string-p))
          (let ((begin (point))
                (end (progn (python-nav-end-of-statement) (point))))
            (goto-char begin)
            (while (progn (forward-comment (buffer-size))
                          (re-search-forward
                           (rx symbol-start "name" (* blank) ?= (* blank)
                               (group (any ?\" ?\'))
                               (group (+ (any "a-z" "A-Z" "0-9" ?_ ?- ?.)))
                               (backref 1))
                           end t))
              (let ((name (match-string-no-properties 2)))
                (unless (python-syntax-comment-or-string-p)
                  (cl-return name))))
            (goto-char end)))))))

;;;; ‘bazelrc-mode’

;;;###autoload
(define-derived-mode bazelrc-mode conf-space-mode "bazelrc"
  "Major mode for editing .bazelrc files.")

;;;###autoload
(add-to-list 'auto-mode-alist
             ;; https://docs.bazel.build/versions/3.0.0/guide.html#where-are-the-bazelrc-files
             (cons (rx ?/ (or "bazel.bazelrc" ".bazelrc") eos) #'bazelrc-mode))

(font-lock-add-keywords
 #'bazelrc-mode
 ;; https://docs.bazel.build/versions/3.0.0/guide.html#imports
 (list (rx symbol-start (or "import" "try-import") symbol-end)))

;;;; Menu item

(easy-menu-add-item
 menu-bar-tools-menu nil
 '("Bazel"
   ;; We enable the workspace commands unconditionally because checking whether
   ;; we’re in a Bazel workspace hits the filesystem and might be too slow.
   ["Build..." bazel-build]
   ["Compile current file" bazel-compile-current-file buffer-file-name]
   ["Test..." bazel-test]
   ["Test at point" bazel-test-at-point]
   ["Collect code coverage..." bazel-coverage]
   ["Run target..." bazel-run]
   ["Show consuming rule" bazel-show-consuming-rule]
   ["Format buffer with Buildifier" bazel-buildifier
    (derived-mode-p 'bazel-mode)]
   ["Insert http_archive statement..." bazel-insert-http-archive
    (derived-mode-p 'bazel-workspace-mode 'bazel-starlark-mode)])
 "Debugger (GDB)...")

;;;; Flymake support using Buildifier

(defvar-local bazel--flymake-process nil
  "Current Buildifier process for this buffer.
‘bazel-mode-flymake’ sets this variable to the most recent
Buildifier process for the current buffer.")

(defun bazel-mode-flymake (report-fn &rest _keys)
  "Flymake backend function for ‘bazel-mode’.
Use REPORT-FN to report linter warnings found by Buildifier.  See
https://github.com/bazelbuild/buildtools/blob/master/buildifier/README.md
for how to install Buildifier.  The function ‘bazel-mode’ adds
this function to ‘flymake-diagnostic-functions’.  See Info node
‘(Flymake) Backend functions’ for details about Flymake
backends."
  (cl-check-type report-fn function)
  (let ((process bazel--flymake-process))
    (when process
      ;; The order here is important: ‘delete-process’ will trigger the
      ;; sentinel, and then ‘bazel--flymake-process’ already has to be nil to
      ;; avoid an obsolete report.
      (setq bazel--flymake-process nil)
      (delete-process process)))
  (let* ((non-essential t)
         (command `(,bazel-buildifier-command
                    ,@(bazel--buildifier-file-flags bazel--buildifier-type
                                                    buffer-file-name)
                    "-mode=check" "-format=json" "-lint=warn"))
         (input-buffer (current-buffer))
         (output-buffer (generate-new-buffer
                         (format " *Buildifier output for %s*" (buffer-name))))
         (error-buffer (generate-new-buffer
                        (format " *Buildifier errors for %s*" (buffer-name))))
         (sentinel
          (lambda (process event)
            (let ((success (string-equal event "finished\n")))
              ;; First, make sure that the buffer to be linted is still alive.
              (when (buffer-live-p input-buffer)
                (with-current-buffer input-buffer
                  ;; Don’t report anything if a new process has already been
                  ;; started.
                  (when (eq bazel--flymake-process process)
                    ;; Report even in case of failure so that Flymake doesn’t
                    ;; treat the backend as continuously running.
                    (funcall report-fn
                             (and success
                                  (bazel--make-diagnostics output-buffer)))
                    (setq bazel--flymake-process nil))))
              (if success
                  (progn (kill-buffer output-buffer)
                         (kill-buffer error-buffer))
                (flymake-log :warning
                             (concat "Buildifier process failed; "
                                     "see buffers ‘%s’ and ‘%s’ for details")
                             output-buffer error-buffer)))))
         ;; We always start a local process, even if visiting a remote
         ;; filename.  If Buildifier is installed locally, the reports should
         ;; match well enough.  Starting a remote process via Tramp tends to be
         ;; way too slow to run interactively.
         (process (make-process :name (format "Buildifier for %s" (buffer-name))
                                :buffer output-buffer
                                :command command
                                :coding '(utf-8-unix . utf-8-unix)
                                :connection-type 'pipe
                                :noquery t
                                :sentinel sentinel
                                :stderr error-buffer)))
    (setq bazel--flymake-process process)
    (save-restriction
      (widen)
      (process-send-region process (point-min) (point-max)))
    (process-send-eof process)))

(defun bazel--buildifier-file-flags (type filename)
  "Return a list of -path and -type flags for Buildifier.
TYPE should be one of the possible values of
‘bazel--buildifier-type’.  Use TYPE and FILENAME to derive
appropriate flags, if possible.  Otherwise, return an empty
list."
  (cl-check-type type symbol)
  (cl-check-type filename (or string null))
  (append
   (and filename
        (when-let ((workspace (bazel--workspace-root filename)))
          (list (concat "-path=" (file-relative-name filename workspace)))))
   (and type (list (concat "-type=" (symbol-name type))))))

(defun bazel--make-diagnostics (output-buffer)
  "Return Flymake diagnostics for the Buildifier report in OUTPUT-BUFFER.
OUTPUT-BUFFER should contain a JSON report for the file visited
by the current buffer as described in
https://github.com/bazelbuild/buildtools/blob/master/buildifier/README.md#file-diagnostics-in-json.
All filenames in OUTPUT-BUFFER are ignored; all messages are
attached to the current buffer.  Return a list of Flymake
diagnostics; see Info node ‘(Flymake) Backend functions’ for
details."
  (cl-check-type output-buffer buffer-live)
  (cl-loop with case-fold-search = nil
           with report = (with-current-buffer output-buffer
                           (save-excursion
                             (save-restriction
                               (widen)
                               (goto-char (point-min))
                               ;; Skip over standard error messages if possible.
                               (when (re-search-forward (rx bol ?{) nil t)
                                 (backward-char)
                                 (bazel--json-parse-buffer)))))
           for file across (gethash "files" report)
           nconc (cl-loop for warning across (gethash "warnings" file)
                          collect (bazel--diagnostic-for-warning warning))))

(defun bazel--diagnostic-for-warning (warning)
  "Return a Flymake diagnostic for the Buildifier WARNING.
WARNING should be a hashtable containing a single warning, as
described in
https://github.com/bazelbuild/buildtools/blob/master/buildifier/README.md#file-diagnostics-in-json."
  (cl-check-type warning hash-table)
  (let* ((case-fold-search nil)
         (start (gethash "start" warning))
         (end (gethash "end" warning))
         ;; Note: Both line and column are one-based in the Buildifier output.
         (start-line (gethash "line" start))
         (start-column (1- (gethash "column" start)))
         (end-line (gethash "line" end))
         (end-column (1- (gethash "column" end)))
         (message (gethash "message" warning)))
    (when (and (= start-line end-line) (= start-column 0) (= end-column 1))
      ;; Heuristic: assume this means the entire line.  Buildifier emits this
      ;; e.g. for the module-docstring warning.  ‘bazel--line-column-pos’
      ;; ensures that we don’t cross line boundaries.
      (setq end-column (buffer-size)))
    (flymake-make-diagnostic
     (current-buffer)
     (bazel--line-column-pos start-line start-column)
     (bazel--line-column-pos end-line end-column)
     :warning
     (format-message "%s [%s] (%s)"
                     ;; We only take the first line of the message, otherwise
                     ;; it becomes too long and looks ugly.
                     (substring-no-properties message nil
                                              (string-match-p (rx ?\n) message))
                     (gethash "category" warning)
                     (gethash "url" warning)))))

;;;; XRef backend

;; This backend is optimized for speed, not correctness.  This means that we
;; use heuristics to find BUILD files and targets.  In particular, we assume
;; that if a target looks like it refers to a file and the file exists, it
;; actually refers to that file.

(defun bazel-mode-xref-backend ()
  "XRef backend function for ‘bazel-mode’.
This gets added to ‘xref-backend-functions’."
  (and (derived-mode-p 'bazel-mode)
       buffer-file-name
       ;; It only makes sense to find targets if we are in a workspace,
       ;; otherwise we don’t know how to resolve absolute labels.
       (bazel--workspace-root buffer-file-name)
       'bazel-mode))

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql bazel-mode)))
  "Return the Bazel label at point as an XRef identifier."
  ;; This only detects string literals representing labels.
  (let ((identifier (bazel--string-at-point)))
    (when identifier
      (cl-destructuring-bind (&whole valid-p &optional workspace package target)
          (bazel--parse-label identifier)
        (when valid-p
          ;; Save the current workspace directory as text property in case the
          ;; user switches directories between this call and selecting a
          ;; reference.  ‘xref-backend-definitions’ falls back to the current
          ;; workspace if the property isn’t present so that users can still
          ;; invoke ‘xref-find-definitions’ and enter a label manually.
          ;; Likewise, save the current package if possible by canonicalizing
          ;; the label.  We don’t care about valid but exotic labels here,
          ;; e.g., labels containing newlines or backslashes.
          (let* ((this-workspace
                  (and buffer-file-name
                       (bazel--workspace-root buffer-file-name)))
                 (package
                  (or package
                      (and buffer-file-name this-workspace
                           (bazel--package-name buffer-file-name
                                                this-workspace)))))
            (propertize (bazel--canonical workspace package target)
                        'bazel-mode-workspace this-workspace)))))))

(cl-defmethod xref-backend-definitions ((_backend (eql bazel-mode)) identifier)
  "Return locations where the Bazel target IDENTIFIER might be defined.
IDENTIFIER should be an XRef identifier returned by
‘xref-backend-identifier-at-point’ with the same backend."
  (cl-check-type identifier string)
  ;; Reparse the identifier so that users can invoke ‘xref-find-definitions’
  ;; and enter a label directly.
  (when-let ((parsed-label (bazel--parse-label identifier)))
    (cl-destructuring-bind (workspace package target) parsed-label
      (when-let* ((this-workspace
                   (or (get-text-property 0 'bazel-mode-workspace identifier)
                       (and buffer-file-name
                            (bazel--workspace-root buffer-file-name))))
                  (package
                   (or package
                       (and buffer-file-name
                            (bazel--package-name buffer-file-name
                                                 this-workspace))))
                  (location
                   (bazel--target-location
                    (bazel--external-workspace workspace this-workspace)
                    package target)))
        (list (xref-make (bazel--canonical workspace package target)
                         location))))))

(cl-defmethod xref-backend-identifier-completion-table
  ((_backend (eql bazel-mode)))
  "Return a completion table for Bazel targets."
  (when-let* ((file-name (or buffer-file-name default-directory))
              (root (bazel--workspace-root file-name))
              (package (bazel--package-name file-name root)))
    (bazel--target-completion-table root package nil)))

(defun bazel-show-consuming-rule ()
  "Find the definition of the rule consuming the current file.
The current buffer must visit a file, and the file must be in a
Bazel workspace.  Use ‘xref-show-definitions-function’ to display
the rule definition.  Right now, perform a best-effort attempt
for finding the consuming rule by a textual search in the BUILD
file."
  (interactive)
  (let* ((source-file (or buffer-file-name
                          (user-error "Buffer doesn’t visit a file")))
         (root (or (bazel--workspace-root source-file)
                   (user-error "File is not in a Bazel workspace")))
         (package (or (bazel--package-name source-file root)
                      (user-error "File is not in a Bazel package")))
         (directory (file-name-as-directory (expand-file-name package root)))
         (build-file (or (locate-file "BUILD" (list directory) '(".bazel" ""))
                         (user-error "No BUILD file found")))
         (relative-file (file-relative-name source-file directory))
         (case-fold-file (file-name-case-insensitive-p source-file))
         (rule
          (or (bazel--consuming-rule build-file relative-file case-fold-file)
              (user-error "No rule for file %s found" relative-file)))
         ;; We press ‘xref-find-definitions’ into service for finding and
         ;; showing the rule.  For that to work, our Xref backend must be found
         ;; unconditionally.
         (xref-backend-functions (list (lambda () 'bazel-mode))))
    (xref-find-definitions
     ;; Create a target identifier similar to what
     ;; ‘xref-backend-identifier-at-point’ returns.
     (propertize (bazel--canonical nil package rule)
                 'bazel-mode-workspace root))))

(defun bazel--consuming-rule (build-file source-file case-fold-file)
  "Return the name of the rule in BUILD-FILE that consumes SOURCE-FILE.
If CASE-FOLD-FILE is non-nil, ignore filename case when
searching."
  (cl-check-type build-file string)
  (cl-check-type source-file string)
  (cl-check-type case-fold-file boolean)
  ;; Prefer a buffer that’s already visiting BUILD-FILE.
  (if-let ((buffer (find-buffer-visiting build-file)))
      (with-current-buffer buffer
        (bazel--consuming-rule-1 source-file case-fold-file))
    (with-temp-buffer
      (insert-file-contents build-file)
      (bazel-build-mode)  ; for correct syntax tables
      (bazel--consuming-rule-1 source-file case-fold-file))))

(defun bazel--consuming-rule-1 (source-file case-fold-file)
  "Return the name of the rule that consumes SOURCE-FILE.
Search the current buffer for candidates.  If CASE-FOLD-FILE is
non-nil, ignore filename case when searching.  This is a helper
function for ‘bazel--consuming-rule’."
  (cl-check-type source-file string)
  (cl-check-type case-fold-file boolean)
  (let ((case-fold-search nil))
    (save-excursion
      ;; Don’t widen; if the rule isn’t found within the accessible portion of
      ;; the current buffer, that’s probably what the user wants.
      (goto-char (point-min))
      ;; We perform a simple textual search for rules with “srcs” attributes
      ;; that contain references to SOURCE-FILE.  That’s in no way exact, but
      ;; faster than invoking “bazel query”, and most BUILD files are regular
      ;; enough for this approach to give acceptable results.
      (cl-block nil
        (while (let ((case-fold-search case-fold-file))
                 (re-search-forward (rx-to-string `(seq (group (any ?\" ?\'))
                                                        (? ?:) ,source-file
                                                        (backref 1)))
                                    nil t))
          (let ((begin (match-beginning 0))
                (end (match-end 0)))
            (goto-char begin)
            (python-nav-up-list -1)
            (when (looking-back
                   (rx symbol-start "srcs" (* blank) ?= (* blank))
                   (line-beginning-position))
              (when-let ((rule-name (bazel-mode-current-rule-name)))
                (cl-return rule-name)))
            ;; Ensure we don’t loop forever if we ended up in a weird place.
            (goto-char end)))))))

(defun bazel--target-location (workspace package target)
  "Return an ‘xref-location’ for a Bazel target.
The target is in the workspace with root directory WORKSPACE and
the package PACKAGE.  Its local name is TARGET.  If no target was
found, return nil.  This function uses heuristics to find the
target; in particular, it assumes that a target that looks like a
valid file target is indeed a file target."
  (cl-check-type workspace string)
  (cl-check-type package string)
  (cl-check-type target string)
  (let* ((directory (expand-file-name package workspace))
         (filename (expand-file-name target directory)))
    (if (file-exists-p filename)
        ;; A label that likely refers to a source file.
        (bazel--file-location filename)
      ;; A label that likely refers to a rule.  Try to find the rule in the
      ;; BUILD file of the package.
      (let ((build-file (locate-file "BUILD" (list directory) '("" ".bazel"))))
        (when build-file
          (bazel--rule-location build-file target))))))

;;;; Completion support

(defun bazel-completion-at-point ()
  "Provide completion of Bazel target labels at point.
‘bazel-mode’ adds this function to
‘completion-at-point-functions’.
See Info node ‘(elisp) Completion in Buffers’ for context."
  ;; This function should be fast, so we perform the quick checks (reading
  ;; variables, syntax tables) first before hitting the filesystem to find the
  ;; workspace root.
  (when-let ((file-name buffer-file-name))
    (when (derived-mode-p 'bazel-mode)
      ;; We assume for now that labels always appear as strings.  That should
      ;; cover most cases (e.g. “deps” attributes), but not add large amounts of
      ;; false positives.
      (let ((state (syntax-ppss)))
        (when (nth 3 state)  ; in string
          (let ((start (1+ (nth 8 state))))  ; first character in string
            (save-excursion
              ;; Jump to the closing quotation mark.
              (parse-partial-sexp (point) (point-max) nil nil state
                                  'syntax-table)
              (let ((end (1- (point))))
                (when (>= end start)
                  (when-let* ((root (bazel--workspace-root buffer-file-name))
                              (package (bazel--package-name file-name root)))
                    (list start end (bazel--target-completion-table
                                     root package nil))))))))))))

(defun bazel--file-location (filename)
  "Return an ‘xref-location’ for the source file FILENAME."
  (cl-check-type filename string)
  ;; The location actually refers to the whole file.  Avoid jumping around
  ;; within the already-visited file by pretending the reference isn’t found so
  ;; that we return point.
  (bazel--xref-location filename (lambda ())))

(defun bazel--complete-files (prefix)
  "Return file names in the current directory starting with PREFIX.
Exclude files that are normally not Bazel targets, such as
directories and BUILD files."
  (cl-check-type prefix string)
  (let ((files ()))
    (dolist (filename (file-name-all-completions prefix default-directory))
      (and (not (directory-name-p filename))
           (not (member filename '("BUILD" "BUILD.bazel" "WORKSPACE")))
           (not (equal (file-name-extension filename) "BUILD"))
           (not (string-prefix-p "bazel-" filename))
           (file-regular-p filename)
           (push filename files)))
    (nreverse files)))

(defun bazel--rule-location (build-file name)
  "Return an ‘xref-location’ for a rule within a BUILD file.
The name of the BUILD file is BUILD-FILE, and NAME is the local
name of the rule.  If NAME doesn’t seem to exist in BUILD-FILE,
return a location referring to an arbitrary position within the
BUILD file."
  (cl-check-type build-file string)
  (cl-check-type name string)
  (bazel--xref-location build-file (lambda () (bazel--find-rule name))))

(defun bazel--find-rule (name)
  "Find the rule with the given NAME within the current buffer.
The current buffer should visit a BUILD file.  If there’s a rule
with the given NAME, return the location of the rule.  Otherwise,
return nil."
  (cl-check-type name string)
  (let ((case-fold-search nil))
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-min))
        ;; Heuristic: we search for a “name” attribute as it would show up
        ;; in typical BUILD files.  That’s not 100% correct, but doesn’t
        ;; rely on external processes and should work fine in common cases.
        (when (re-search-forward
               (rx-to-string
                `(seq bol (* blank) "name" (* blank) ?= (* blank)
                      (group (any ?\" ?')) (group ,name) (backref 1))
                :no-group)
               nil t)
          (match-beginning 2))))))

(eval-when-compile
  (defmacro bazel--with-file-buffer (existing filename &rest body)
    "Evaluate BODY in some buffer that contains the contents of FILENAME.
If there’s an existing buffer visiting FILENAME, use that and
bind EXISTING to t.  Otherwise, create a new temporary buffer,
insert the contents of FILENAME there, and bind EXISTING to nil.
In any case, return the value of the last BODY form."
    (declare (debug (symbolp form body)) (indent 2))
    (cl-check-type existing symbol)
    (macroexp-let2 nil filename filename
      (let ((function (make-symbol "function"))
            (buffer (make-symbol "buffer"))
            (arg (make-symbol "arg")))
        ;; Bind a temporary function to reduce code duplication in the
        ;; byte-compiled version.
        `(cl-flet ((,function (,arg) (let ((,existing ,arg)) ,@body)))
           (if-let ((,buffer (find-buffer-visiting ,filename)))
               (with-current-buffer ,buffer
                 (,function t))
             (with-temp-buffer
               (insert-file-contents ,filename)
               (,function nil))))))))

(defun bazel--xref-location (filename find-function)
  "Return an ‘xref-location’ for some entity within FILENAME.
FIND-FUNCTION should be a function taking zero arguments.  This
function calls FIND-FUNCTION in some buffer containing the
contents of FILENAME.  FIND-FUNCTION should then either return
nil (if the entity isn’t found) or the position of the entity
within the current buffer.  FIND-FUNCTION should not move point
or change the buffer state permanently."
  (cl-check-type filename string)
  (cl-check-type find-function function)
  ;; Prefer a buffer that already visits FILENAME.
  (bazel--with-file-buffer existing filename
    (let ((found (funcall find-function)))
      (if existing
          ;; If not found, use point to avoid jumping around in the buffer.
          (xref-make-buffer-location (current-buffer) (or found (point)))
        (goto-char (or found (point-min)))
        (xref-make-file-location filename
                                 (line-number-at-pos)
                                 (- (point) (line-beginning-position)))))))

(defun bazel--complete-rules (prefix)
  "Find all rules starting with the given PREFIX in the current buffer.
The current buffer should visit a BUILD file.  Return a list of
rule names that start with PREFIX."
  (cl-check-type prefix string)
  (when (derived-mode-p 'bazel-mode)
    (let ((case-fold-search nil)
          (rules ()))
      (save-excursion
        ;; We don’t widen here.  If the user has narrowed the buffer, it’s fair
        ;; to assume they only want completions within the narrowed portion.
        (goto-char (point-min))
        (while (re-search-forward
                (rx-to-string
                 `(seq bol (* blank) "name" (* blank) ?= (* blank)
                       (group (any ?\" ?'))
                       (group ,prefix (* (not (any ?\" ?' ?\n))))
                       (backref 1))
                 :no-group)
                nil t)
          (push (match-string-no-properties 2) rules)))
      (nreverse rules))))

;;;; ‘find-file-at-point’ support for ‘bazel-mode’

;; Since we match every filename, we want to come last.
(add-to-list 'ffap-alist (cons (rx anything) #'bazel-mode-ffap) :append)

(defun bazel-mode-ffap (filename)
  "Attempt to find FILENAME in all workspaces.
This gets added to ‘ffap-alist’."
  (cl-check-type filename string)
  (when-let* ((this-file (or buffer-file-name default-directory))
              (main-root (bazel--workspace-root this-file)))
    (let ((external-roots (bazel--external-workspace-roots main-root)))
      (locate-file filename (cons main-root external-roots)))))

;;;; ‘find-file-at-point’ support for ‘bazelrc-mode’

(add-to-list 'ffap-string-at-point-mode-alist
             ;; By default the percent sign isn’t included in the list of
             ;; allowed filename characters, so this would miss %workspace%
             ;; names.
             (list #'bazelrc-mode "-_/.%[:alnum:]" "" ""))

(add-to-list 'ffap-alist (cons #'bazelrc-mode #'bazelrc-ffap))

(defun bazelrc-ffap (name)
  "Function for ‘ffap-alist’ in ‘bazelrc-mode’.
Look for an imported file with the given NAME."
  (cl-check-type name string)
  ;; https://docs.bazel.build/versions/3.0.0/guide.html#imports
  (let ((case-fold-search nil))
    (pcase name
      ((rx bos "%workspace%" (+ ?/) (let rest (+ nonl)))
       (when buffer-file-name
         (when-let ((workspace (bazel--workspace-root buffer-file-name)))
           (let ((file-name (expand-file-name rest workspace)))
             (and (file-exists-p file-name) file-name))))))))

;;;; Compilation support

;; Add entries to ‘compilation-error-regexp-alist’.  Bazel errors are of the
;; form “SEVERITY: FILE:LINE:COLUMN: MESSAGE.”  We restrict the filename to the
;; most common characters to avoid matching too much.  In particular, Bazel
;; doesn’t allow spaces in filenames
;; (https://github.com/bazelbuild/bazel/issues/167), so we don’t have to look
;; for spaces here.  We generate the constant entries at compile time to make
;; loading a bit faster.
(let-when-compile
    ((entries
      (cl-loop
       for (name prefix type) in '((bazel-mode-debug "DEBUG" 0)
                                   (bazel-mode-info "INFO" 0)
                                   (bazel-mode-warning "WARNING" 1)
                                   (bazel-mode-error "ERROR" 2))
       for rx = (rx-to-string
                 `(seq bol ,prefix ": "
                       ;; This needs to at least match package names
                       ;; (https://docs.bazel.build/versions/4.0.0/build-ref.html#package-names-package-name).
                       ;; Bazel currently doesn’t allow spaces in filenames
                       ;; (https://github.com/bazelbuild/bazel/issues/167 and
                       ;; https://github.com/bazelbuild/bazel/issues/374), so we
                       ;; don’t include spaces here either.  We do allow
                       ;; non-ASCII alphanumeric characters, because they could
                       ;; be part of the workspace directory name.
                       (group (+ (any alnum ?/ ?- ?. ?_))
                              (or (seq "/BUILD" (? ".bazel"))
                                  (seq (+ (any alnum ?- ?. ?_)) ".bzl")))
                       ?: (group (+ digit)) ?: (group (+ digit)) ": ")
                 :no-group)
       collect (list name rx 1 2 3 type))))
  (dolist (entry (eval-when-compile entries))
    (add-to-list 'compilation-error-regexp-alist (car entry))
    (add-to-list 'compilation-error-regexp-alist-alist entry)))

(add-hook 'compilation-finish-functions #'bazel-finish-compilation)

(defun bazel-finish-compilation (buffer message)
  "Parse Bazel build output in BUFFER.
If the option ‘bazel-display-coverage’ is non-nil and there are
references to coverage results in BUFFER, attempt to display the
line coverage status in buffers that are visiting files with
coverage information.  MESSAGE is the status message for the
Bazel process exit; \"finished\\n\" if Bazel completed
successfully.  This function is suitable for
‘compilation-finish-functions’."
  (cl-check-type buffer buffer)
  (cl-check-type message string)
  (when (and bazel-display-coverage (buffer-live-p buffer)
             (string-equal message "finished\n"))
    (with-current-buffer buffer
      (let ((remote (file-remote-p default-directory))
            (files ()))
        (when (or (not remote) (eq bazel-display-coverage t))
          ;; First collect potential coverage files.  If there are none (typical
          ;; case), we don’t have to hit the filesystem.
          (save-excursion
            (save-restriction
              (goto-char (point-min))
              ;; Parse Bazel output.  It’s supposed to be stable and easy to
              ;; parse,
              ;; cf. https://docs.bazel.build/versions/4.0.0/guide.html#parsing-output.
              ;; We assume that coverage instrumentation files are always called
              ;; “coverage.dat”.
              (while (re-search-forward
                      (rx bol "  " (group ?/ (+ nonl) "/coverage.dat") eol)
                      nil t)
                (let ((file (match-string-no-properties 1)))
                  ;; The coverage files are external filenames, so quote them
                  ;; (to avoid clashes with filename handlers) and make them
                  ;; remote if necessary.
                  (push (concat remote (file-name-quote file)) files))))))
        (when files
          ;; Only continue if we’re in a Bazel workspace.
          (when-let ((root (bazel--workspace-root default-directory)))
            ;; COVERAGE maps buffers to hashtables that in turn map line numbers
            ;; to hit counts.  We first collect coverage information into this
            ;; hashtable to correctly deal with duplicate file sections.
            (let ((coverage (make-hash-table :test #'eq)))
              (dolist (file files)
                (with-temp-buffer
                  ;; Don’t bail out if the coverage file can’t be read.  Maybe
                  ;; it has already been garbage-collected.
                  (when (condition-case nil
                            (insert-file-contents file)
                          (file-missing nil))
                    (bazel--parse-coverage root coverage))))
              (maphash #'bazel--display-coverage coverage))))))))

(defun bazel--parse-coverage (root coverage)
  "Parse coverage information in the current buffer.
ROOT is the Bazel workspace root directory.  COVERAGE is a
hashtable that maps buffers to hashtables that in turn map line
numbers to hit counts.  The function walks over the coverage
information in the current buffer and fills in COVERAGE."
  ;; See the manual page of ‘geninfo’ for a description of the coverage format.
  (while (re-search-forward (rx bol "SF:" (group (+ nonl)) eol) nil t)
    (let ((begin (line-beginning-position 2))
          (file (expand-file-name (match-string-no-properties 1) root)))
      (when-let ((end (re-search-forward (rx bol "end_of_record" eol) nil t))
                 ;; Only collect coverage for files that are visited in some
                 ;; buffer.
                 (buffer (find-buffer-visiting file)))
        (goto-char begin)
        (while (re-search-forward (rx bol "DA:" (group (+ digit)) ?,
                                      (group (+ digit)) (? ?, (+ nonl)) eol)
                                  end t)
          (let ((line (cl-the natnum (string-to-number
                                      (match-string-no-properties 1))))
                (hits (cl-the natnum (string-to-number
                                      (match-string-no-properties 2))))
                ;; DATA maps line numbers to hit counts for the current file.
                (data (or (gethash buffer coverage)
                          (puthash buffer (make-hash-table :test #'eql)
                                   coverage))))
            (cl-incf (gethash line data 0) hits)))))))

(defun bazel--display-coverage (buffer coverage)
  "Add overlays for coverage information in BUFFER.
COVERAGE is a hashtable mapping line numbers to hit counts.
Remove existing coverage overlays first."
  (let ((pairs ())
        (runs ()))
    (maphash
     (lambda (line hits)
       (let ((face
              (if (cl-plusp hits) 'bazel-covered-line 'bazel-uncovered-line)))
         (push (cons line face) pairs)))
     coverage)
    (cl-callf sort pairs #'car-less-than-car)
    ;; The Emacs Lisp manual cautions that overlays don’t scale well; see Info
    ;; node ‘(elisp) Overlays’.  Therefore, we create as few overlays as
    ;; possible by grouping consecutive lines with identical coverage status
    ;; into runs.
    (while pairs
      (cl-loop with (i . f) = (car pairs)
               for tail on (cdr pairs)
               for (j . g) = (car tail)
               for k from (1+ i)  ; expected line number for the next element
               while (and (eq f g) (eql j k))  ; stop as soon as run ends
               finally (push (list f i (1- k)) runs) (setq pairs tail)))
    (cl-callf nreverse runs)
    (with-current-buffer buffer
      (save-excursion
        (save-restriction
          (widen)
          (goto-char (point-min))
          ;; See remark at the bottom of Info node ‘(elisp) Managing Overlays’.
          (overlay-recenter (point-max))
          ;; We first remove existing coverage overlays because they are likely
          ;; stale.
          (bazel-remove-coverage-display)
          (cl-loop for (face i j) in runs
                   ;; Choose overlay positions and stickiness so that inserting
                   ;; text before or after a run doesn’t appear to extend the
                   ;; covered region.
                   for o = (make-overlay (line-beginning-position i)
                                         (line-end-position j)
                                         buffer :front-advance)
                   do
                   ;; Add ‘category’ property to find the overlays later (see
                   ;; ‘bazel-remove-coverage-display’).
                   (overlay-put o 'category 'bazel-coverage)
                   (overlay-put o 'face face)))))))

(defun bazel-remove-coverage-display ()
  "Remove all Bazel coverage display in the current buffer.
If the current buffer is narrowed, only act on the accessible
portion."
  (interactive)
  (remove-overlays (point-min) (point-max) 'category 'bazel-coverage))

;; Default overlay properties.
(put 'bazel-coverage 'priority 10)
(put 'bazel-coverage 'evaporate t)

;;;; Imenu support

(defun bazel-mode-create-index ()
  "Return an Imenu index for the rules in the current buffer.
This function is useful as ‘imenu-create-index-function’ for
‘bazel-build-mode’ and ‘bazel-workspace-mode’.  See Info node
‘(elisp) Imenu’ for details."
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (let ((case-fold-search nil)
            (index ()))
        ;; Heuristic: We search for “name” attributes as they would show in
        ;; typical BUILD files.  That’s not 100% correct, but doesn’t rely on
        ;; external processes and should work fine in common cases.
        (while (re-search-forward
                ;; The target pattern isn’t the same as
                ;; https://docs.bazel.build/versions/3.1.0/build-ref.html#name
                ;; (we don’t allow quotation marks in target names), but should
                ;; be good enough here.
                (rx bol (* blank) "name" (* blank) ?= (* blank)
                    (group (any ?\" ?'))
                    (group (+ (any "a-z" "A-Z" "0-9"
                                   ?- "!%@^_` #$&()*+,;<=>?[]{|}~/.")))
                    (backref 1))
                nil t)
          (let ((name (match-string-no-properties 2))
                (pos (save-excursion
                       (python-nav-beginning-of-statement)
                       (if imenu-use-markers (point-marker) (point)))))
            (push (cons name pos) index)))
        (nreverse index)))))

(defun bazel-mode-current-rule-name ()
  "Return the name of the Bazel rule at point.
Return nil if not inside a Bazel rule."
  (let ((case-fold-search nil)
        (bound (save-excursion (python-nav-end-of-statement) (point))))
    (save-excursion
      (python-nav-beginning-of-statement)
      (when (re-search-forward
             ;; The target pattern isn’t the same as
             ;; https://docs.bazel.build/versions/3.1.0/build-ref.html#name (we
             ;; don’t allow quotation marks in target names), but should be good
             ;; enough here.
             (rx bol (* blank) "name" (* blank) ?= (* blank)
                 (group (any ?\" ?'))
                 (group (+ (any "a-z" "A-Z" "0-9"
                                ?- "!%@^_` #$&()*+,;<=>?[]{|}~/.")))
                 (backref 1))
             bound t)
        (match-string-no-properties 2)))))

(defun bazel-mode-extract-function-name ()
  "Return the name of the Starlark function at point.
Return nil if no name was found.  This function is useful as
‘imenu-extract-index-name-function’ for ‘bazel-starlark-mode’."
  (let ((case-fold-search nil))
    (and (looking-at python-nav-beginning-of-defun-regexp)
         (match-string-no-properties 1))))

;;;; Speedbar

(with-eval-after-load 'speedbar
  (speedbar-add-supported-extension (rx "BUILD" (? ".bazel"))))

(declare-function speedbar-add-supported-extension "speedbar" (extension))

;;;; Project integration

;; We add ourselves with relatively low priority because we don’t have an
;; optimized ‘project-files’ implementation.  Other project functions with
;; potentially optimized implementations should get a chance to run first.
(add-hook 'project-find-functions #'bazel-find-project 20)

(cl-defstruct bazel-workspace
  "Represents a Bazel workspace."
  (root nil
        :read-only t
        :type string
        :documentation "The workspace root directory."))

;; Inlining accessors would break clients that are compiled against a version
;; with an incompatible layout.  Normally we’d use the ‘:noinline’ structure
;; keyword in ‘cl-defstruct’, but we still support Emacs 26, which doesn’t know
;; about that keyword.  So we remove the compiler macros by hand for now.  Once
;; we drop support for Emacs 26, we should remove this hack in favor of
;; ‘:noinline’.
(dolist (symbol '(make-bazel-workspace
                  copy-bazel-workspace
                  bazel-workspace-p
                  bazel-workspace-root))
  (when-let ((cmacro (get symbol 'compiler-macro)))
    (put symbol 'compiler-macro nil)
    (when (symbolp cmacro) (fmakunbound cmacro))))

(defun bazel-find-project (directory)
  "Find a Bazel workspace for the given DIRECTORY.
Return nil if outside a Bazel workspace or a project instance for
the containing workspace.  This function is suitable for
‘project-find-functions’."
  (cl-check-type directory string)
  (when-let ((root (bazel--workspace-root directory)))
    (make-bazel-workspace :root root)))

(cl-defmethod project-roots ((project bazel-workspace))
  "Return the primary root directory of the Bazel workspace PROJECT."
  (list (bazel-workspace-root project)))

(cl-defmethod project-external-roots ((project bazel-workspace))
  "Return the external workspace roots of the Bazel workspace PROJECT."
  (bazel--external-workspace-roots (bazel-workspace-root project)))

;;;; Commands to build and run code using Bazel

(defun bazel-build (target)
  "Build a Bazel TARGET."
  (interactive (list (bazel--read-target-pattern "build")))
  (cl-check-type target string)
  (bazel--run-bazel-command "build" target))

(defun bazel-compile-current-file ()
  "Compile the file that the current buffer visits with Bazel."
  (interactive)
  (let* ((file-name (or buffer-file-name
                        (user-error "Buffer doesn’t visit a file")))
         ;; “bazel build --compile_one_dependency” accepts file names relative
         ;; to the current directory.
         (relative-name (file-relative-name file-name)))
    (bazel--compile "build" "--compile_one_dependency" "--" relative-name)))

(defun bazel-run (target)
  "Build and run a Bazel TARGET."
  (interactive (list (bazel--read-target-pattern "run")))
  (cl-check-type target string)
  (bazel--run-bazel-command "run" target))

(defun bazel-test (target)
  "Build and run a Bazel test TARGET."
  (interactive (list (bazel--read-target-pattern "test")))
  (cl-check-type target string)
  (bazel--run-bazel-command "test" target))

(defun bazel-test-at-point ()
  "Run the test case at point."
  (interactive)
  (let* ((source-file (or buffer-file-name
                          (user-error "Buffer doesn’t visit a file")))
         (root (or (bazel--workspace-root source-file)
                   (user-error "File is not in a Bazel workspace")))
         (package (or (bazel--package-name source-file root)
                      (user-error "File is not in a Bazel package")))
         (directory (file-name-as-directory (expand-file-name package root)))
         (build-file (or (locate-file "BUILD" (list directory) '(".bazel" ""))
                         (user-error "No BUILD file found")))
         (relative-file (file-relative-name source-file directory))
         (case-fold-file (file-name-case-insensitive-p source-file))
         (rule
          (or (bazel--consuming-rule build-file relative-file case-fold-file)
              (user-error "No rule for file %s found" relative-file)))
         (name
          (or (run-hook-with-args-until-success 'bazel-test-at-point-functions)
              (user-error "Point is not on a test case"))))
    (bazel--compile "test" (concat "--test_filter=" name) "--"
                    (bazel--canonical nil package rule))))

(defun bazel-coverage (target)
  "Run Bazel test TARGET with coverage instrumentation enabled."
  (interactive (list (bazel--read-target-pattern "coverage")))
  (cl-check-type target string)
  (bazel--run-bazel-command "coverage" target))

(defun bazel--run-bazel-command (command target-pattern)
  "Run Bazel tool with given COMMAND on the given TARGET_PATTERN.
COMMAND is a Bazel command such as \"build\" or \"run\"."
  (cl-check-type command string)
  (cl-check-type target-pattern string)
  (bazel--compile command "--" target-pattern))

(defun bazel--compile (&rest args)
  "Run Bazel in a Compilation buffer with the given ARGS."
  (compile (mapconcat #'shell-quote-argument (append bazel-command args) " ")))

(defun bazel--read-target-pattern (command)
  "Read a Bazel build target pattern from the minibuffer.
COMMAND is a Bazel command to be included in the minibuffer prompt."
  (cl-check-type command string)
  (let* ((file-name
          (or buffer-file-name default-directory
              (user-error "Buffer doesn’t visit a file or directory")))
         (workspace-root
          (or (bazel--workspace-root file-name)
              (user-error
               "Not in a Bazel workspace.  No WORKSPACE file found")))
         (package-name
          (or (bazel--package-name file-name workspace-root)
              (user-error "Not in a Bazel package.  No BUILD file found")))
         (prompt (combine-and-quote-strings
                  `(,@bazel-command "--" ,command "")))
         (table (bazel--target-completion-table workspace-root package-name
                                                :pattern)))
    (completing-read prompt table)))

;;;; Utility functions to work with Bazel workspaces

(defun bazel-util-workspace-root (file-name)
  "Find the root of the Bazel workspace containing FILE-NAME.
If FILE-NAME is not in a Bazel workspace, return nil.  Otherwise,
the return value is a directory name."
  (declare (obsolete "don’t use it, as it’s an internal function."
                     "2021-04-13"))
  (cl-check-type file-name string)
  (bazel--workspace-root file-name))

(defun bazel--workspace-root (file-name)
  "Find the root of the Bazel workspace containing FILE-NAME.
If FILE-NAME is not in a Bazel workspace, return nil.  Otherwise,
the return value is a directory name."
  (cl-check-type file-name string)
  (let ((result (locate-dominating-file file-name #'bazel--workspace-root-p)))
    (and result (file-name-as-directory result))))

(defun bazel--workspace-root-p (directory)
  "Return non-nil if DIRECTORY is a Bazel workspace root directory."
  (and (file-directory-p directory)
       (locate-file "WORKSPACE" (list directory) '(".bazel" ""))))

(defun bazel-util-package-name (file-name workspace-root)
  "Return the nearest Bazel package for FILE-NAME under WORKSPACE-ROOT.
If FILE-NAME is not in a Bazel package, return nil."
  (declare (obsolete "don’t use it, as it’s an internal function."
                     "2021-04-13"))
  (cl-check-type file-name string)
  (cl-check-type workspace-root string)
  (bazel--package-name file-name workspace-root))

(defun bazel--package-name (file-name workspace-root)
  "Return the nearest Bazel package for FILE-NAME under WORKSPACE-ROOT.
If FILE-NAME is not in a Bazel package, return nil."
  (cl-check-type file-name string)
  (cl-check-type workspace-root string)
  (when (< emacs-major-version 27)
    ;; Work around https://debbugs.gnu.org/cgi/bugreport.cgi?bug=29579.
    (cl-callf file-name-unquote file-name)
    (cl-callf file-name-unquote workspace-root))
  (let* ((parent (file-name-directory (directory-file-name workspace-root)))
         ;; Don’t search beyond workspace root.
         (locate-dominating-stop-dir-regexp
          (if parent
              (rx-to-string `(or (seq bos ,parent eos)
                                 (regexp ,locate-dominating-stop-dir-regexp))
                            :no-group)
            locate-dominating-stop-dir-regexp))
         (build-file-directory
          (locate-dominating-file file-name #'bazel--package-directory-p)))
    (cond ((not build-file-directory) nil)
          ((file-equal-p workspace-root build-file-directory) "")
          ((file-in-directory-p build-file-directory workspace-root)
           (let ((package-name
                  (file-relative-name build-file-directory workspace-root)))
             ;; Only return package-name if we can confirm it is the local
             ;; relative file name of a BUILD file.
             (and package-name
                  (not (file-remote-p package-name))
                  (not (file-name-absolute-p package-name))
                  (not (string-prefix-p "." package-name))
                  (directory-file-name package-name)))))))

(defun bazel--package-directory-p (directory)
  "Return non-nil if DIRECTORY is a Bazel package directory.
This doesn’t check whether DIRECTORY is within a Bazel workspace."
  (and (file-directory-p directory)
       (locate-file "BUILD" (list directory) '(".bazel" ""))))

(defun bazel--external-workspace (workspace-name this-workspace-root)
  "Return the workspace root of an external workspace.
WORKSPACE-NAME should be either a string naming an external
workspace, or nil to refer to the current workspace.
THIS-WORKSPACE-ROOT should be the name of the current workspace
root directory, as returned by ‘bazel--workspace-root’.  The
return value is a directory name."
  (cl-check-type workspace-name (or null string))
  (cl-check-type this-workspace-root string)
  (file-name-as-directory
   (if workspace-name
       ;; See https://docs.bazel.build/versions/2.0.0/output_directories.html
       ;; for some overview of the Bazel directory layout.  Empirically, the
       ;; directory ROOT/bazel-ROOT/external/WORKSPACE is a symlink to the
       ;; workspace root of the external workspace WORKSPACE.  Again, this is a
       ;; heuristic, and should work for the common case.  In particular, we
       ;; don’t want to shell out to “bazel info workspace” here, because that
       ;; might block indefinitely if another Bazel instance holds the lock.
       ;; We don’t check whether the directory exists, because it’s generated
       ;; and cached when needed.
       (expand-file-name workspace-name
                         (bazel--external-workspace-dir this-workspace-root))
     this-workspace-root)))

(defun bazel--external-workspace-dir (root)
  "Return a directory name for the parent directory of the external workspaces.
ROOT should be the main workspace root as returned by
‘bazel--workspace-root’."
  (cl-check-type root string)
  ;; See the commentary in ‘bazel--external-workspace’ for how to find external
  ;; workspaces.
  (expand-file-name
   (concat "bazel-" (file-name-nondirectory (directory-file-name root))
           "/external/" )
   root))

(defun bazel--external-workspace-roots (main-root)
  "Return the directory names of the external workspace roots.
MAIN-ROOT should be the main workspace root as returned by
‘bazel--workspace-root’."
  (let ((case-fold-search nil))
    (condition-case nil
        (directory-files
         (bazel--external-workspace-dir main-root)
         :full
         ;; https://docs.bazel.build/versions/4.0.0/skylark/lib/globals.html#parameters-36
         ;; claims that workspace names may only contain letters, numbers, and
         ;; underscores, but that’s wrong, since hyphens and dots are also
         ;; allowed.  See
         ;; https://github.com/bazelbuild/bazel/blob/bc9fc6144818528898336c0fbe4fe8b30ac25abb/src/main/java/com/google/devtools/build/lib/packages/WorkspaceGlobals.java#L52.
         (rx bos (any "A-Z" "a-z") (* (any ?- ?. ?_ "A-Z" "a-z")) eos))
      ;; If there’s no external workspace directory, don’t signal an error.
      (file-missing nil))))

(defun bazel--target-completion-table (root package pattern)
  "Return a completion table for Bazel targets and target patterns.
See URL
‘https://docs.bazel.build/versions/4.0.0/guide.html#specifying-targets-to-build’
for a description of target patterns.  ROOT is the workspace root
directory, and PACKAGE is the current package name.  Return a
completion table that can be passed to ‘completing-read’.  See
Info node ‘(elisp) Basic Completion’ for more information about
completion tables.  The completion is not exact and only includes
potential packages and rules.  If PATTERN is non-nil, complete
target patterns and skip files."
  (cl-check-type root string)
  (cl-check-type package string)
  ;; We return a completion function so that we don’t have to find all targets
  ;; eagerly.  See Info node ‘(elisp) Programmed Completion’.
  (lambda (string predicate action)
    (cl-check-type string string)
    (cl-check-type predicate (or function null))
    (let ((case-fold-search completion-ignore-case))
      ;; We dynamically generate and use a helper completion table based on the
      ;; provided prefix pattern.
      (complete-with-action
       action
       (bazel--target-completion-table-1 root package pattern string)
       string predicate))))

(defun bazel--target-completion-table-1 (root package pattern string)
  "Return a completion table completing STRING to a Bazel target or pattern.
ROOT is the workspace root directory, and PACKAGE is the current
package name.  If PATTERN is non-nil, complete target patterns
and skip files.  This is a helper function for
‘bazel--target-completion-table’."
  (cl-check-type root string)
  (cl-check-type package string)
  (cl-check-type string string)
  (pcase string
    ;; The following patterns should cover all potential target patterns from
    ;; https://docs.bazel.build/versions/4.0.0/guide.html#specifying-targets-to-build
    ;; as well as their prefixes.  We are a bit more lenient than necessary to
    ;; avoid convoluted regular expressions.
    (""
     ;; By default, offer targets and subpackages of the current package, as
     ;; well as “//” to anchor the pattern at the root of the current workspace,
     ;; since these are the most common patterns.  Also offer “@” to select
     ;; external workspaces.
     (completion-table-merge
      (bazel--target-completion-table-2 root nil package pattern :colon)
      ;; Relative subpackages are only allowed in target patterns.
      (when pattern
        (bazel--target-package-completion-table root nil package pattern))
      '("//" "@")))
    ((rx bos (let prefix ?@) (* (not (any ?: ?/))) eos)
     ;; Completion for external workspace names.
     (let ((root (bazel--external-workspace-dir root)))
       (bazel--completion-table-with-prefix prefix
         (bazel--target-workspace-completion-table
          (bazel--external-workspace-dir root)))))
    ((rx bos (let prefix (* (not (any ?:))) "/...:"))
     ;; Combination of package wildcard and target wildcard.
     (when pattern
       (bazel--completion-table-with-prefix prefix
         '("all" "all-targets" "*"))))
    ((rx bos (let prefix (? ?@ (+ (not (any ?: ?/))))) ?/ eos)
     ;; A single slash, optionally preceded by a workspace reference, can only
     ;; be completed to “//”.
     (bazel--completion-table-with-prefix prefix '("//")))
    ((rx bos
         ;; Can’t use ‘(? … (let …))’ due to Bug#44532.
         (opt ?@ (let workspace (+ (not (any ?: ?/))))) "//"
         eos)
     ;; In the workspace root, offer “:” to start completing rules, as well as
     ;; subpackages.
     (bazel--completion-table-with-prefix string
       (completion-table-merge
        '(":")
        (bazel--target-package-completion-table root workspace "" pattern))))
    ((rx bos (let prefix (* (not (any ?:))) ?/) "..." eos)
     ;; A package wildcard may optionally be followed by a target wildcard.
     (when pattern
       (bazel--completion-table-with-prefix prefix '("..." "...:"))))
    ((rx bos (let prefix (* (not (any ?:))) ?/) (** 1 2 ?.) eos)
     ;; “/.” in a package name can only be completed to a package wildcard.
     (when pattern
       (bazel--completion-table-with-prefix prefix '("..."))))
    ((rx bos
         ;; Can’t use ‘(? … (let …))’ due to Bug#44532.
         (opt ?@ (let workspace (+ (not (any ?: ?/))))) "//"
         (let package (+ (not (any ?:)))) ?/
         eos)
     ;; A full package name followed by a slash must be followed by a package
     ;; name or wildcard.
     (bazel--completion-table-with-prefix string
       (bazel--target-package-completion-table root workspace package pattern)))
    ((rx bos
         (let prefix
           ;; Can’t use ‘(? … (let …))’ due to Bug#44532.
           (opt ?@ (let workspace (+ (not (any ?: ?/))))) "//"
           (let package (* (not (any ?:))))
           ?:)
         (* (not (any ?:)))
         eos)
     ;; Absolute target label prefix, including the colon.  Must complete to a
     ;; target label.
     (bazel--completion-table-with-prefix prefix
       (bazel--target-completion-table-2 root workspace package pattern)))
    ((rx bos
         ;; Can’t use ‘(? … (let …))’ due to Bug#44532.
         (let prefix (opt ?@ (let workspace (+ (not (any ?: ?/))))) "//")
         (+ (not (any ?:)))
         eos)
     ;; Absolute package prefix, without colon.  Must complete to a package
     ;; name.
     (bazel--completion-table-with-prefix prefix
       (bazel--target-package-completion-table root workspace "" pattern)))
    ((rx bos (let prefix ?:) (* (not (any ?:))) eos)
     ;; Target pattern relative to the current package.
     (bazel--completion-table-with-prefix prefix
       (bazel--target-completion-table-2 root nil package pattern)))
    ((rx bos (+ (not (any ?:))) ?/ eos)
     ;; Subpackage or subdirectory of the current package followed by a slash.
     ;; Normally followed by another package name or wildcard, but can also be a
     ;; target name containing a slash.  The interpretation of this clause
     ;; differs between target patterns and labels in BUILD files.
     (if pattern
         (bazel--target-package-completion-table root nil package pattern)
       (bazel--target-completion-table-2 root nil package pattern)))
    ((rx bos
         (let prefix (let subpackage (+ (not (any ?:)))) ?:)
         (* (not (any ?:)))
         eos)
     ;; Target pattern in a subpackage of the current package.  Must be
     ;; followed by a target name or wildcard.
     (when pattern
       (let ((package (if (string-empty-p package)
                          subpackage
                        (concat package "/" subpackage))))
         (bazel--completion-table-with-prefix prefix
           (bazel--target-completion-table-2 root nil package pattern)))))
    ((rx bos (+ (not (any ?:))) eos)
     ;; Something else, could be either a target or a subpackage of the current
     ;; package.  Prefer targets.
     (completion-table-merge
      (bazel--target-completion-table-2 root nil package pattern :colon)
      (when pattern
        (bazel--target-package-completion-table root nil package pattern))))))

(defun bazel--target-workspace-completion-table (root)
  "Return a target completion table for external workspace names.
ROOT is the parent directory of the external workspaces as
returned by ‘bazel--external-workspace-dir’.  This is a helper
function for ‘bazel--target-completion-table’."
  (bazel--completion-table-with-terminator "/"
    (lambda (string predicate action)
      ;; Restrict completions to valid workspace names.
      (let ((completion-regexp-list
             (cons (rx bos (+ (any "A-Z" "a-z" "0-9" ?_ ?- ?.)) eos)
                   completion-regexp-list))
            (predicate
             (bazel--target-completion-directory-predicate predicate)))
        (condition-case nil
            (pcase action
              ('nil
               (file-name-completion string root predicate))
              ('t
               (cl-remove-if-not predicate
                                 (file-name-all-completions string root)))
              ;; We always return nil for the ‘lambda’ action because a
              ;; workspace prefix is never a complete target pattern.
              (`(boundaries . ,suffix)
               `(boundaries 0 . ,(string-match-p (rx (any ?/ ?:)) suffix))))
          (file-error nil))))))

(defun bazel--target-package-completion-table (root workspace package pattern)
  "Return a completion table for package patterns.
ROOT is the main workspace root, WORKSPACE is the external
workspace name or nil for the main workspace, and PACKAGE is the
current package.  If PATTERN is non-nil, complete target patterns
and include wildcards.  This is a helper function for
‘bazel--target-completion-table’."
  (cl-check-type root string)
  (cl-check-type workspace (or null string))
  (cl-check-type package string)
  (let* ((root (bazel--external-workspace workspace root))
         (directory (file-name-as-directory (expand-file-name package root))))
    (lambda (string predicate action)
      (let* ((slash (string-match-p (rx ?/ (* (not (any ?/))) eos) string))
             (parent (substring-no-properties string 0 (or slash 0)))
             (prefix (if slash (concat parent "/") ""))
             (parent-directory (file-name-as-directory
                                (expand-file-name parent directory)))
             (table (when (file-accessible-directory-p parent-directory)
                      ;; Merge actual package names and the “...” wildcard.
                      (bazel--completion-table-with-prefix prefix
                        (completion-table-merge
                         (bazel--target-package-completion-table-1
                          parent-directory)
                         (and pattern '("...")))))))
        (complete-with-action action table string predicate)))))

(defun bazel--target-package-completion-table-1 (directory)
  "Return a completion table for Bazel packages found in
DIRECTORY.  This is a helper function for
‘bazel--target-package-completion-table’."
  (cl-check-type directory string)
  (lambda (string predicate action)
    (let ((completion-regexp-list
           ;; Restrict completions to valid package names.
           (cons (rx bos (+ (any "A-Z" "a-z" "0-9" ?_ ?- ?.)) eos)
                 completion-regexp-list))
          (predicate
           (bazel--target-completion-directory-predicate predicate)))
      (condition-case nil
          ;; ‘file-name-completion’ and ‘file-name-all-completions’ always
          ;; return directories as directory names.  Since a directory name
          ;; isn’t a valid package name, and we don’t want to give the user the
          ;; impression that they can’t enter a colon, strip the trailing slash.
          (pcase action
            ('nil
             (when-let ((res (file-name-completion string directory predicate)))
               (bazel--remove-slash res)))
            ('t
             (cl-loop for cand in (file-name-all-completions string directory)
                      when (funcall predicate cand)
                      collect (bazel--remove-slash cand)))
            ('lambda
              ;; We complete target patterns, not packages!  In particular, a
              ;; valid target pattern can’t end in a slash.
              (and (not (string-empty-p string))
                   (not (directory-name-p string))
                   (file-accessible-directory-p
                    (expand-file-name string directory))
                   (funcall predicate directory)))
            (`(boundaries . ,suffix)
             `(boundaries 0 . ,(string-match-p (rx (any ?/ ?:)) suffix))))
        (file-error nil)))))

(defun bazel--target-completion-table-2
    (root workspace package pattern &optional colon)
  "Return a completion table for Bazel targets or target patterns.
ROOT is the main workspace root, WORKSPACE is the external
workspace name or nil for the main workspace, and PACKAGE is the
package name within the workspace.  If PATTERN is non-nil,
complete target patterns, include target wildcards like “:all”,
and skip files.  This is a helper function for
‘bazel--target-completion-table’."
  (cl-check-type root string)
  (cl-check-type workspace (or null string))
  (cl-check-type package string)
  (when-let ((build-file
              (bazel--locate-build-file
               (expand-file-name package
                                 (bazel--external-workspace workspace root)))))
    (let ((completion-regexp-list
           (cons (rx bos (+ (any "a-z" "A-Z" "0-9" ?-
                                 "!%@^_` \"#$&'()*-+,;<=>?[]{|}~/.")
                            eos))
                 completion-regexp-list)))
      (completion-table-merge
       (completion-table-with-cache
        (lambda (prefix)
          (cl-check-type prefix string)
          (append
           (if-let ((buffer (find-buffer-visiting build-file)))
               (with-current-buffer buffer
                 (bazel--complete-rules prefix))
             (with-temp-buffer
               (insert-file-contents build-file)
               ;; ‘bazel--complete-rules’ only works in ‘bazel-mode’.
               (bazel-build-mode)
               (bazel--complete-rules prefix)))
           (unless pattern
             ;; Include source files only if we’re not completing a target
             ;; pattern.  Building a source file makes no sense.
             (let ((default-directory (file-name-directory build-file)))
               (bazel--complete-files prefix)))))
        completion-ignore-case)
       ;; We only want to add the wildcards if this is indeed a package.  Do
       ;; this here so that we don’t have to check twice.
       (when pattern
         (if colon
             '(":all" ":all-targets" ":*")
           '("all" "all-targets" "*")))))))

(defun bazel--target-completion-directory-predicate (predicate)
  "Return a completion predicate useful for workspace and package completion.
Combine PREDICATE with a predicate that checks for valid
workspace and package names.  This is a helper function for
‘bazel--target-completion-table’."
  (cl-check-type predicate (or function null))
  (if predicate
      (lambda (candidate)
        (and (bazel--target-completion-directory-p candidate)
             (funcall predicate candidate)))
    #'bazel--target-completion-directory-p))

(defun bazel--target-completion-directory-p (string)
  "Return whether STRING is a valid workspace or package name.
Assume that STRING comes from ‘file-name-completion’ or
‘file-name-all-completions’.  This is a helper function for
‘bazel--target-completion-table’."
  ;; No thorough check here, since this is only used for completion.  Filename
  ;; completion always returns directory names for directories, so this
  ;; syntactic check suffices.  See the code for ‘completion-file-name-table’
  ;; for prior art.
  (and (directory-name-p string)
       (not (string-prefix-p "." string))))

(defun bazel--locate-build-file (directory)
  "Return the file name of the Bazel BUILD file in DIRECTORY.
Return nil if DIRECTORY is not a Bazel package (i.e., doesn’t
contain a BUILD file).  Assume that DIRECTORY is within a Bazel
workspace.  DIRECTORY can be a directory name or directory file
name."
  (cl-check-type directory string)
  (locate-file "BUILD" (list directory) '(".bazel" "")))

(defun bazel--parse-label (label)
  "Parse Bazel label LABEL.
If LABEL isn’t syntactically valid, return nil.  Otherwise,
return a triple (WORKSPACE PACKAGE TARGET).  WORKSPACE is
nil (for the current workspace) or a string referring to some
external workspace.  PACKAGE is nil (for the current package) or
a package name string.  TARGET is a string referring to the local
name of LABEL.  See
https://docs.bazel.build/versions/2.0.0/build-ref.html#lexi for
the lexical syntax of labels."
  (cl-check-type label string)
  (let ((case-fold-search nil))
    (pcase (substring-no-properties label)
      ((rx bos
           (or
            ;; @workspace//package:target
            (seq "@" (let workspace (+ (not (any ?: ?/))))
                 "//" (let package (* (not (any ?:))))
                 ?: (let target (+ (not (any ?:)))))
            ;; @workspace//package
            (seq "@" (let workspace (+ (not (any ?: ?/))))
                 "//" (let package (+ (not (any ?:)))))
            ;; //package:target
            (seq "//" (let package (* (not (any ?:))))
                 ?: (let target (+ (not (any ?:)))))
            ;; //package
            (seq "//" (let package (+ (not (any ?:)))))
            ;; :target
            (seq ?: (let target (+ (not (any ?:)))))
            ;; target
            (seq (let target (not (any ?: ?/ ?@)) (* (not (any ?:))))))
           eos)
       (unless target (setq target (bazel--default-target package)))
       (and (or (null workspace)
                ;; https://docs.bazel.build/versions/4.0.0/skylark/lib/globals.html#parameters-36
                ;; claims that workspace names may only contain letters,
                ;; numbers, and underscores, but that’s wrong, since hyphens and
                ;; dots are also allowed.  See
                ;; https://github.com/bazelbuild/bazel/blob/bc9fc6144818528898336c0fbe4fe8b30ac25abb/src/main/java/com/google/devtools/build/lib/packages/WorkspaceGlobals.java#L52.
                (string-match-p
                 (rx bos (any "A-Z" "a-z") (* (any ?- ?. ?_ "A-Z" "a-z")) eos)
                 workspace))
            (or (null package) (string-empty-p package)
                ;; https://docs.bazel.build/versions/2.0.0/build-ref.html#package-names-package-name
                (string-match-p (rx bos
                                    (any "A-Z" "a-z" "0-9" ?- ?. ?_)
                                    (* (any "A-Z" "a-z" "0-9" ?/ ?- ?. ?_))
                                    eos)
                                package))
            ;; https://docs.bazel.build/versions/2.0.0/build-ref.html#name
            (string-match-p (rx bos
                                (+ (any "a-z" "A-Z" "0-9" ?-
                                        "!%@^_` \"#$&'()*+,;<=>?[]{|}~/."))
                                eos)
                            target)
            (list workspace package target))))))

(defun bazel--default-target (package)
  "Return the default target name for PACKAGE.
For a package “foo/bar”, “bar” is the default target."
  (cl-check-type package string)
  (let ((case-fold-search nil))
    (pcase-exhaustive package
      ((rx (or bos ?/) (let target (* (not (any ?/)))) eos)
       target))))

(defun bazel--canonical (workspace package target)
  "Return a canonical label.
WORKSPACE is either nil (referring to the current workspace) or
an external workspace name.  PACKAGE and TARGET should both be
strings.  Return either @WORKSPACE//PACKAGE:TARGET or
//PACKAGE:TARGET."
  (declare (side-effect-free t))
  (cl-check-type workspace (or null string))
  (cl-check-type package string)
  (cl-check-type target string)
  (concat (and workspace (concat "@" workspace)) "//" package ":" target))

(defun bazel--remove-slash (string)
  "Remove a final slash from STRING."
  (declare (side-effect-free t))
  (cl-check-type string string)
  ;; Don’t call ‘directory-file-name’ because that tries to invoke filename
  ;; handlers.
  (let ((i (1- (length string))))
    (if (and (natnump i) (eql (aref string i) ?/))
        (substring-no-properties string 0 i)
      string)))

(defun bazel--string-at-point ()
  "Return the string literal at point, or nil if not inside a string literal."
  (let ((state (syntax-ppss)))
    (when (nth 3 state)  ; in string
      (let ((start (1+ (nth 8 state))))  ; (nth 8 state) is the opening quote
        (save-excursion
          ;; Jump to the closing quotation mark.
          (parse-partial-sexp (point) (point-max) nil nil state 'syntax-table)
          (buffer-substring-no-properties start (1- (point))))))))

(defun bazel--find-target-name (bound)
  "Search for a target name from point to BOUND.
If a target name was found, return non-nil and set the match to
the match text.  The second match group matches the name."
  (cl-check-type bound natnum)
  (let ((case-fold-search nil))
    (and (re-search-forward
          (rx "name" (* blank) ?= (* blank)
              (group (any ?\" ?'))
              (group (+ (any "a-z" "A-Z" "0-9" ?-
                             "!%@^_` #$&()*+,;<=>?[]{|}~/.")))
              (backref 1))
          bound t)
         (let ((syntax (syntax-ppss)))
           (and (> (nth 0 syntax) 0) (null (nth 8 syntax)))))))

(defun bazel--find-magic-comment (bound)
  "Search for a magic comment from point to BOUND.
If a magic comment was found, return non-nil and set the match to
the comment text."
  (cl-check-type bound natnum)
  ;; Buildifier's magic comment detection appears to be case-insensitive, but
  ;; isn't documented as such.  Reference in the source: https://git.io/JO6FG.
  (let ((case-fold-search t))
    (with-case-table ascii-case-table
      (and (re-search-forward bazel--magic-comment-regexp bound t)
           (nth 4 (syntax-ppss))))))

(defun bazel--line-column-pos (line column)
  "Return buffer position in the current buffer for LINE and COLUMN.
Restrict LINE to the buffer size and COLUMN to the number of
characters in LINE.  COLUMN is measured in characters, not visual
columns."
  (cl-check-type line natnum)
  (cl-check-type column natnum)
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (forward-line (1- line))
      (min (line-end-position) (+ (point) column)))))

(defun bazel--completion-table-with-prefix (prefix table)
  "Return a completion table based on TABLE with the given PREFIX.
The returned completion table completes strings of the form
\(concat PREFIX STRING), if TABLE completes STRING."
  (declare (indent 1))  ; reduces horizontal whitespace
  (cl-check-type prefix string)
  (if (string-empty-p prefix)
      table  ; small optimization
    (completion-table-subvert
     ;; We’d like to pass TABLE here directly, but before Emacs 28,
     ;; ‘completion-table-subvert’ reports incorrect completion boundaries in
     ;; case TABLE has trivial boundaries, so we ensure that its underlying
     ;; table has nontrivial ones.
     (lambda (string predicate action)
       (pcase action
         (`(boundaries . ,suffix)
          `(boundaries . ,(completion-boundaries string table predicate
                                                 suffix)))
         (_ (complete-with-action action table string predicate))))
     prefix "")))

(defun bazel--completion-table-with-terminator (terminator table)
  "Return a completion table based on TABLE that appends TERMINATOR.
This is the same as ‘completion-table-with-terminator’, but
doesn’t require partial application."
  (declare (indent 1))  ; reduces horizontal whitespace
  (cl-check-type terminator string)
  (lambda (string predicate action)
    (completion-table-with-terminator terminator table
                                      string predicate action)))

(defalias 'bazel--json-parse-buffer
  (if (and (fboundp 'json-parse-buffer)
           ;; Work around Bug#48228.
           (or (not (eq system-type 'windows-nt))
               (and (fboundp 'json-serialize)
                    (stringp (ignore-errors (json-serialize nil))))))
      #'json-parse-buffer
    (lambda ()
      "Polyfill for ‘json-parse-buffer’."
      (let ((json-object-type 'hash-table)
            (json-array-type 'vector)
            (json-key-type 'string)
            (json-null :null)
            (json-false :false)
            (json-pre-element-read-function nil)
            (json-post-element-read-function nil))
        (json-read)))))

(provide 'bazel)
;;; bazel.el ends here
