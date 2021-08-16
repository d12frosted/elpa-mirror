;;; go-gen-test.el --- Generate tests for go code with gotests    -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Sergey Kostyaev, all rights reserved.

;; Author: Sergey Kostyaev <feo.me@ya.ru>
;; Keywords: languages
;; Package-Version: 20210816.1215
;; Package-Commit: 35df36dcd555233ee1a618c0f6a58ce6db4154d9
;; Url: https://github.com/s-kostyaev/go-gen-test
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.3") (s "1.12"))

;; This program is free software; you can redistribute it and/or modify
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

;; This package is simple wrapper for https://github.com/cweill/gotests
;; You should install `gotests' for use it.

;;; Code:
(require 's)
(require 'simple)

(defgroup go-gen-test nil
  "Generating tests for golang functions options."
  :prefix "go-gen-test-"
  :group 'go)

(defcustom go-gen-test-default-functions "-exported"
  "Default functions which tests will be generated for."
  :group 'go-gen-test
  :type '(radio
          (const :tag "All" "-all")
          (const :tag "Exported only" "-exported")))

(defcustom go-gen-test-exclude nil
  "Don't generate test for functions that match regexp."
  :group 'go-gen-test
  :type '(repeat (choice regexp)))

(defcustom go-gen-test-enable-subtests t
  "Enable subtest generation."
  :group 'go-gen-test
  :type 'boolean)

(defcustom go-gen-test-executable "gotests"
  "Path to gotests executable."
  :group 'go-gen-test
  :type 'file)

(defcustom go-gen-test-open-function 'find-file-other-window
  "Open generated test function."
  :group 'go-gen-test
  :type '(radio
          (const :tag "Right here" 'find-file)
          (const :tag "In other window" 'find-file-other-window)
          (const :tag "In other frame" 'find-file-other-frame)))

(defcustom go-gen-test-use-testify nil
  "Use testify in generated tests."
  :group 'go-gen-test
  :type 'boolean)

(defconst go-gen-test-function-regexp "^func \\(([^()]*)\\)?\s*\\(\[A-Za-z0-9_]+\\)\s*\\(([^()]*)\\)"
  "Regexp for extract go functions from selected region.")

(defun go-gen-test-functions (start end)
  "Create list of go functions defined between START & END."
  (interactive "r")
  (save-match-data
    (goto-char start)
    (let ((functions nil))
      (while (search-forward-regexp go-gen-test-function-regexp end t)
        (push (match-string-no-properties 2) functions))
      functions)))

(defun go-gen-test-base-command ()
  "Base generating command."
  (format "%s%s%s%s -w"
          go-gen-test-executable
          (if go-gen-test-enable-subtests "" " -nosubtests")
	  (if go-gen-test-use-testify " -template testify" "")
          (if go-gen-test-exclude
              (format " -excl %s"(s-join "|" go-gen-test-exclude))
            "")))

;;;###autoload
(defun go-gen-test-dwim (&optional start end)
  "(go-gen-test-dwim &optional START END)
Generate tests for functions you want to.
If you call this function while region is active it extracts
functions defined between START and END and generate tests for it.
Else it generates tests for exported or all functions.
You can customize this behavior with `go-gen-test-default-functions'."
  (interactive "r")
  (save-buffer)
  (shell-command
   (if (use-region-p)
       (format "%s -only %s %s"
               (go-gen-test-base-command)
               (shell-quote-argument
                (s-join "|" (go-gen-test-functions start end)))
               (shell-quote-argument (buffer-file-name)))
     (format "%s %s %s"
             (go-gen-test-base-command)
             go-gen-test-default-functions
             (shell-quote-argument (buffer-file-name))))
   "*gotests*")
  (deactivate-mark)
  (if (s-suffix-p "_test.go" (buffer-file-name))
      (revert-buffer nil t)
    (funcall go-gen-test-open-function
             (format "%s_test.go" (file-name-base (buffer-file-name))))))

;;;###autoload
(defun go-gen-test-all ()
  "(go-gen-test-all)
Generate tests for all functions."
  (interactive)
  (save-buffer)
  (shell-command
   (format "%s -all %s"
           (go-gen-test-base-command)
           (shell-quote-argument (buffer-file-name)))
   "*gotests*")
  (if (s-suffix-p "_test.go" (buffer-file-name))
      (revert-buffer nil t)
    (funcall go-gen-test-open-function
             (format "%s_test.go" (file-name-base (buffer-file-name))))))

;;;###autoload
(defun go-gen-test-exported ()
  "(go-gen-test-exported)
Generate tests for all exported functions."
  (interactive)
  (save-buffer)
  (shell-command
   (format "%s -exported %s"
           (go-gen-test-base-command)
           (shell-quote-argument (buffer-file-name)))
   "*gotests*")
  (if (s-suffix-p "_test.go" (buffer-file-name))
      (revert-buffer nil t)
    (funcall go-gen-test-open-function
             (format "%s_test.go" (file-name-base (buffer-file-name))))))

(provide 'go-gen-test)
;;; go-gen-test.el ends here
