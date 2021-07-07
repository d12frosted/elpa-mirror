;;; shelltest-mode.el --- Major mode for shelltestrunner

;; Copyright (C) 2014 Dustin Fechner

;; Author: Dustin Fechner <dfe@rtrn.io>
;; URL: https://github.com/rtrn/shelltest-mode
;; Package-Version: 20180501.141
;; Package-Commit: 5fea8c9394380e822971a171905b6b5ab9be812d
;; Version: 1.1
;; Created: 21 Dec 2014
;; Keywords: languages

;;; License:

;; Permission to use, copy, modify, and distribute this software for any
;; purpose with or without fee is hereby granted, provided that the above
;; copyright notice and this permission notice appear in all copies.
;;
;; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
;; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
;; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
;; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
;; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
;; OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

;;; Commentary:

;; Major mode for shelltestrunner (http://joyful.com/shelltestrunner).
;;
;; Besides syntax highlighting, a few useful functions for dealing with
;; test files are provided:
;;
;; To quickly open test files use `shelltest-find'.  To execute tests use
;; `shelltest-run' and `shelltest-run-all'.  These functions work from
;; all modes and can be bound to keys for convenience.
;;
;; To find out how to customize (among other things) the location of the
;; test files, refer to the documentation of the relevant functions.

;;; Code:

;; customizable variables
(defgroup shelltest-mode nil
  "Major mode for shelltestrunner."
  :group 'languages
  :link '(emacs-library-link :tag "Lisp File" "shelltest-mode.el"))

(defcustom shelltest-other-window t
  "If given a non-nil value, `shelltest-find' uses another window."
  :type 'boolean
  :group 'shelltest-mode)

(defcustom shelltest-command "shelltest --execdir"
  "The command that `shelltest-run' and `shelltest-run-all' execute."
  :type 'string
  :group 'shelltest-mode)

(defcustom shelltest-directory "./tests/"
  "The directory in which the test files are located.

Note that this should end with a directory separator."
  :type 'string
  :group 'shelltest-mode)

;; interactive functions
;;;###autoload
(defun shelltest-find ()
  "Edit the test file that corresponds to the currently edited file.

The opened file is file.test in `shelltest-directory', where \`file\'
is the name of the currently edited file with its extension removed.
If `shelltest-other-window' is non-nil, open the file in another window."
  (interactive)
  (let ((test (format "%s%s.test"
                      shelltest-directory
                      (file-name-base (buffer-file-name)))))
    (if shelltest-other-window
        (find-file-other-window test)
      (find-file test))))

;;;###autoload
(defun shelltest-run ()
  "Run the test file associated with the currently edited file.

The command to be run is determined by `shelltest-command'.  Its argument
is `shelltest-directory' with file.test appended, where \`file\' is the name
of the currently edited file with its extension removed."
  (interactive)
  (let ((compilation-buffer-name-function 'shelltest--buffer-name))
    (compile (shelltest--command-line
              (format "%s%s.test"
                      shelltest-directory
                      (file-name-base (buffer-file-name)))))))

;;;###autoload
(defun shelltest-run-all ()
  "Run all test files.

The command to be run is determined by `shelltest-command'.  Its argument
is `shelltest-directory'."
  (interactive)
  (let ((compilation-buffer-name-function 'shelltest--buffer-name))
    (compile (shelltest--command-line shelltest-directory))))

;; helper variables and functions
(defconst shelltest--keywords
  '(("^>>>=" . font-lock-keyword-face)
    ("^\\(>>>2\\|>>>\\|<<<\\)$" (1 font-lock-keyword-face)
     ("." (shelltest--end-of-string) nil (0 font-lock-string-face)))
    ("^\\(>>>2\\|>>>\\)[^=\n].*" (1 font-lock-keyword-face)
     ("." (shelltest--end-of-string) nil (0 font-lock-string-face)))
    ("^#.*" . font-lock-comment-face)))

(defun shelltest--end-of-string ()
  (save-excursion
    (while (not (or (eobp)
                    (looking-at-p ">>>=\\|>>>2\\|>>>\\|<<<")))
      (forward-line))
    (point)))

(defun shelltest--command-line (file)
  (format "%s %s"
          shelltest-command
          (shell-quote-argument (expand-file-name file))))

(defun shelltest--buffer-name (arg)
  "*shelltest*")

;; mode definition
;;;###autoload
(define-derived-mode shelltest-mode prog-mode "Shelltest"
  "Major mode for shelltestrunner.

See URL `http://joyful.com/shelltestrunner'."
  (setq font-lock-multiline t)
  (font-lock-add-keywords nil shelltest--keywords)
  (set (make-local-variable 'compilation-buffer-name-function)
       'shelltest--buffer-name)
  (set (make-local-variable 'compile-command)
       (shelltest--command-line (buffer-file-name)))
  (set (make-local-variable 'shelltest-directory)
       (file-name-directory (buffer-file-name))))

(provide 'shelltest-mode)

;;; shelltest-mode.el ends here
