;;; environ.el --- API for environment variables and env files -*- lexical-binding: t; -*-

;; Author: Chris Clark <cfclrk@gmail.com>
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.1") (dash "2.17.0") (f "0.20.0") (s "1.12.0"))
;; URL: https://github.com/cfclrk/environ
;; Keywords: tools

;; This file is NOT part of GNU Emacs.

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

;; An Emacs package that provides some helpful functions for working with
;; environment variables and env files.

;; This package uses a bash subprocess to fully expand variables, which means
;; you can leverage the power of bash to define variables.

;; See the README.md in this package, which is visible at:
;; https://github.com/cfclrk/environ

;;; Code:

(require 'dash)
(require 'f)
(require 's)

;;; Options

(defgroup environ ()
  "Utilities to set and unset environment variables in Emacs."
  :group 'environment
  :prefix "environ-"
  :link '(url-link :tag "GitHub" "https://github.com/cfclrk/env"))

(defconst environ-project-dir
  (file-name-directory (if load-in-progress
                           load-file-name
                         (buffer-file-name)))
  "The directory where this project's source code is located.")

(defcustom environ-dir (expand-file-name "~/")
  "Directory to prompt for env files.
This varibale is only used by `environ-set-file' and `environ-unset-file'
when they are run interactively."
  :group 'env
  :type 'directory)

(defcustom environ-pre-eval-functions nil
  "A list of functions to run before shell evaluation.
Each function must accept a list of pairs and return an updated list of
pairs."
  :group 'env
  :type 'hook)

(defcustom environ-post-eval-functions
  '(environ-ignore-bash-vars)
  "A list of functions to run after shell evaluation.
Each function must accept a list of pairs and return an updated list of
pairs."
  :group 'env
  :type '(hook :options (environ-ignore-bash-vars)))

;;; Files

;;;###autoload
(defun environ-set-file (file-path)
  "Set environment variables defined in the file at FILE-PATH.
When used interactively, prompts for the file to load. The prompt begins in
`environ-dir'. When used from elisp, FILE-PATH can either be absolute or
relative to `default-directory'."
  (interactive (list (read-file-name "ENV file: " environ-dir)))
  (-> file-path
      f-read-text
      environ-set-str))

;;;###autoload
(defun environ-unset-file (file-path)
  "Unset the environment variables defined in FILE-PATH.
See the documentation for `environ-set-file'."
  (interactive (list (read-file-name "ENV file: " environ-dir)))
  (-> file-path
      f-read-text
      environ-unset-str))

;;; Strings

(defun environ-set-str (str)
  "Set environment variables defined by the given string STR.
Parse STR like an env file. STR is split into newline-delimited lines,
where each line is a key/value pair."
  (-> str
      environ--str-to-pairs
      environ-set-pairs))

(defun environ-unset-str (str)
  "Unset environment variables defined by string STR.
Parse STR like an env file. STR is split into newline-delimited pairs,
where each line is a key/value pair. The value of each pair is discarded,
as the environment variable will be unset regardless of its value."
  (-> str
      environ--str-to-pairs
      environ-unset-pairs))

;;; Pairs

(defun environ-get-pairs ()
  "Return all current environment variables as a list of pairs."
  (environ--lines-to-pairs process-environment))

(defun environ-set-pairs (pairs)
  "Set environment variables defined by the given PAIRS.
PAIRS is a list of pairs, where each pair is an environment
variable name and value."
  (-> pairs
      (environ--eval-and-diff)
      (-each #'environ--set-pair)))

(defun environ--set-pair (pair)
  "Set an environment variable PAIR."
  (let ((name (car pair))
        (val (car (cdr pair))))
    (setenv name val)))

(defun environ-unset-pairs (pairs)
  "Unset the environment variables defined in the given PAIRS.
PAIRS is a list of pairs, where each pair is an environment variable name
and value. The value in each pair doesn't matter; each environment variable
will be unset regardless of its value."
  (environ-unset-names (-map 'car pairs)))

;;; Names

(defun environ-get-names ()
  "Return a list of all current environment variable names."
  (--map
   (car (s-split "=" it))
   process-environment))

(defun environ-unset-names (names)
  "Unset environment variables with the given NAMES.
NAMES is a list of environment variable names which may or may not be
currently set. This function removes each name from `process-environment'
if it is set."
  (-each names #'environ-unset-name))

;;;###autoload
(defun environ-unset-name (name)
  "Unset the environment variable NAME.
Unset the given environment variable by removing it from
`process-environment' if it is there. Note that calling `setenv' with a
prefix argument can unset a variable by setting its value to nil, but the
variable remains in `process-environment'. This function completely removes
the variable from `process-environment'."
  (interactive (list (completing-read "" (environ-get-names))))
  (let* ((encoded-name (if (multibyte-string-p name)
                           (encode-coding-string name locale-coding-system t)
                         name))
         (index (-elem-index encoded-name (environ-get-names))))
    (if index
        (setq process-environment
              (-remove-at index process-environment))
      process-environment)))

;;;; Conversion functions

(defun environ--str-to-pairs (str)
  "Parse STR into a list of pairs."
  (-> str
      s-trim
      s-lines
      environ--lines-to-pairs))

(defun environ--lines-to-pairs (lines)
  "Return a list of pairs of LINES."
  (--map (s-split "=" it) lines))

;;; Post-eval functions

(defun environ-ignore-bash-vars (pairs)
  "Remove DISPLAY, PWD, SHLVL, and _ from PAIRS.
Bash initializes these environment varibales in every bash process. If any
of these are different in the bash subprocess, it's probably not something
you care about. This is the default post-eval function."
  (let ((ignored-vars '("DISPLAY" "PWD" "SHLVL" "_")))
    (-filter
     (lambda (pair) (not (member (car pair) ignored-vars)))
     pairs)))

;;;; Shell script evaluation

(defun environ--eval-and-diff (pairs)
  "Eval PAIRS and diff the result with the current environment.
This runs all pre-eval-functions and post-eval-functions."
  (let ((cur-pairs (environ--lines-to-pairs process-environment))
        (new-pairs (environ--eval-with-pre-post-functions pairs)))
    (-difference new-pairs cur-pairs)))

(defun environ--eval-with-pre-post-functions (pairs)
  "Eval PAIRS along with all pre-eval and post-eval functions."
  (->> pairs
       (funcall (apply #'-compose environ-pre-eval-functions))
       (environ--eval)
       (funcall (apply #'-compose environ-post-eval-functions))))

(defun environ--eval (pairs)
  "Eval PAIRS in a bash subprocess.
Return a list of pairs representing the resulting subprocess environment."
  (-> pairs
      environ--build-script
      environ--run-script
      environ--str-to-pairs))

(defun environ--build-script (pairs)
  "Turn PAIRS into a sh script.
TODO: handle integer values"
  (->> pairs
       (--map (s-join "=" it))
       (--map (s-prepend "export " it))
       (s-join "\n")
       (s-append "\nprintenv\n")))

(defun environ--run-script (script)
  "Run SCRIPT in a bash subprocess. Return stdout."
  (with-temp-buffer
    (call-process "bash"
                  nil t nil
                  shell-command-switch
                  script)
    (buffer-string)))

(provide 'environ)
;;; environ.el ends here
