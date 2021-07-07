;;; atcoder-tools.el --- An atcoder-tools client    -*- lexical-binding: t -*-

;; Copyright (c) 2019 Seong Yong-ju

;; Author: Seong Yong-ju <sei40kr@gmail.com>
;; Keywords: extensions, tools
;; Package-Version: 20200109.1236
;; Package-Commit: cfe61ed18ea9b3b1bfb6f9e7d80a47599680cd1f
;; URL: https://github.com/sei40kr/atcoder-tools
;; Package-Requires: ((emacs "26") (f "0.20") (s "1.12"))
;; Version: 0.5.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Test your solution for an AtCoder's task from Emacs.

;;; Code:

(require 'f)
(require 'json)
(require 's)

(defgroup atcoder-tools nil
  "atcoder-tools client"
  :prefix 'atcoder-tools-
  :group 'tools)

(defcustom atcoder-tools-c-compiler 'gcc
  "The compiler to use to compile C code. Possible values are `gcc' and `clang'."
  :type '(choice (const gcc)
                 (const clang)))

(defcustom atcoder-tools-c++-compiler 'gcc
  "The compiler to use to compile C++ code. Possible values are `gcc' and `clang'."
  :type '(choice (const gcc)
                 (const clang)))

(defcustom atcoder-tools-rust-use-rustup t
  "If non-nil, Rustup is used to compile Rust code."
  :type 'bool)


(defvar atcoder-tools--run-config-alist
  '(
    (c-gcc . ((cmd-templates . ("gcc -x c -std=gnu11 -o %e -lm -O2 %s" "atcoder-tools test -e %e -d %d"))
              (remove-exec . t)))
    (c-clang . ((cmd-templates . ("clang -x c -lm -O2 -o %e %s" "atcoder-tools test -e %e -d %d"))
                (remove-exec . t)))
    (c++-gcc . ((cmd-templates . ("g++ -std=gnu++1y -O2 -o %e %s"
                                  "atcoder-tools test -e %e -d %d"))
                (remove-exec . t)))
    (c++-clang . ((cmd-templates . ("clang++ -std=c++14 -stdlib=libc++ -O2 -o %e %s"
                                    "atcoder-tools test -e %e -d %d"))
                  (remove-exec . t)))
    (rust-rustc . ((cmd-templates . ("rustc -Oo %e %s" "env RUST_BACKTRACE=1 atcoder-tools test -e %e -d %d"))
                   (remove-exec . t)))
    (rust-rustup . ((cmd-templates . ("rustup run --install 1.15.1 rustc -Oo %e %s" "env RUST_BACKTRACE=1 atcoder-tools test -e %e -d %d"))
                    (remove-exec . t))))
  "Run configurations.")

(defun atcoder-tools--run-config-for-mode (mode)
  "Return an alist of run configuration for MODE."
  (alist-get
   (pcase mode
     ('c-mode (pcase atcoder-tools-c-compiler
                ('gcc 'c-gcc)
                ('clang 'c-clang)
                (_ (error "Invalid atcoder-tools-c-compiler value: %S"
                          atcoder-tools-c-compiler))))
     ('c++-mode (pcase atcoder-tools-c-compiler
                  ('gcc 'c++-gcc)
                  ('clang 'c++-clang)
                  (_ (error "Invalid atcoder-tools-c++-compiler value: %S"
                            atcoder-tools-c++-compiler))))
     ('rust-mode (if atcoder-tools-rust-use-rustup 'rust-rustup 'rust-rustc))
     (_ (error "No run configuration found for %S" mode)))
   atcoder-tools--run-config-alist))

(defun atcoder-tools--expand-cmd-templates (cmd-templates working-directory src-file-name exec-file-name)
  "Expand each command in CMD-TEMPLATES, a list of command templates.

%d in the template will be replaced with WORKING-DIRECTORY.
%s in the template will be replaced with SRC-FILE-NAME.
%e in the template will be replaced with EXEC-FILE-NAME."
  (mapcar #'(lambda (cmd-template)
              (s-replace-all `(("%d" . ,(shell-quote-argument working-directory))
                               ("%s" . ,(shell-quote-argument src-file-name))
                               ("%e" . ,(shell-quote-argument exec-file-name)))
                             cmd-template))
          cmd-templates))

(defun atcoder-tools--test (mode src-file-name)
  "Internally called by `atcoder-tools-test'.

MODE is the major mode of the solution buffer to test.
SRC-FILE-NAME is the name of the solution file."
  (let* ((run-config        (atcoder-tools--run-config-for-mode mode))
         (working-directory (f-dirname src-file-name))
         (exec-file-name    (file-name-sans-extension src-file-name))
         (cmd-templates     (alist-get 'cmd-templates run-config))
         (commands          (atcoder-tools--expand-cmd-templates
                             cmd-templates
                             working-directory
                             src-file-name
                             exec-file-name))
         (remove-exec       (alist-get 'remove-exec run-config nil)))
    (let ((comint-terminfo-terminal "ansi"))
      (compile (s-join " && " commands) t))
    (when remove-exec
      (delete-file exec-file-name nil))))

(defun atcoder-tools--open-problem (metadata-file-name)
  "Internally called by `atcoder-tools-open-problem'.

METADATA-FILE-NAME is the path to metadata.json generated by atcoder-tools."
  (let* ((metadata-alist (if (file-readable-p metadata-file-name)
                             (json-read-file metadata-file-name)
                           (error "Could not retrieve information from metadata.json")))
         (problem-alist (alist-get 'problem metadata-alist))
         (contest-id (alist-get 'contest_id (alist-get 'contest problem-alist)))
         (problem-id (alist-get 'problem_id problem-alist)))
    (browse-url (format "https://atcoder.jp/contests/%s/tasks/%s"
                        contest-id
                        problem-id))))

;;;###autoload
(defun atcoder-tools-test ()
  "Test your solution using atcoder-tools.

An executable of the solution will be built if needed."
  (interactive)
  (atcoder-tools--test major-mode buffer-file-name))

;;;###autoload
(defun atcoder-tools-open-problem ()
  "Open the AtCoder's task page of current buffer in a web browser."
  (interactive)
  (atcoder-tools--open-problem (f-join (file-name-directory buffer-file-name)
                                       "metadata.json")))

(provide 'atcoder-tools)

;;; atcoder-tools.el ends here
