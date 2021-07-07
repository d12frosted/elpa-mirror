;;; flymake-python-pyflakes.el --- A flymake handler for python-mode files using pyflakes (or flake8)

;; Copyright (C) 2012-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; URL: https://github.com/purcell/flymake-python-pyflakes
;; Package-Commit: 1d65c26bf65a5dcbd29fcd967e2feb90e1e7a33d
;; Package-Version: 20170723.146
;; Package-X-Original-Version: 0
;; Package-Requires: ((flymake-easy "0.8"))

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

;; Usage:

;;   (require 'flymake-python-pyflakes)
;;   (add-hook 'python-mode-hook 'flymake-python-pyflakes-load)
;;
;; To use "flake8" instead of "pyflakes", add this line:

;;   (setq flymake-python-pyflakes-executable "flake8")
;;
;; You can pass extra arguments to the checker program by customizing
;; the variable `flymake-python-pyflakes-extra-arguments', or setting it
;; directly, e.g.

;;   (setq flymake-python-pyflakes-extra-arguments '("--ignore=W806"))
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

;; TODO: handle any file name
(defconst flymake-python-pyflakes-err-line-patterns
  '(("^\\(.*?\\.pyw?\\):\\([0-9]+\\): \\(.*\\)\r?\n" 1 2 nil 3)
    ;; flake8
    ("^\\(.*?\\.pyw?\\):\\([0-9]+\\):\\([0-9]+\\): \\(.*\\)\r?\n" 1 2 3 4)))

(defgroup flymake-python-pyflakes nil
  "Flymake support for Python via pyflakes or flake8"
  :group 'flymake
  :prefix "flymake-python-pyflakes-")

(defcustom flymake-python-pyflakes-executable "pyflakes"
  "Pyflakes executable to use for syntax checking."
  :type 'string
  :group 'flymake-python-pyflakes)

(defcustom flymake-python-pyflakes-extra-arguments nil
  "Pyflakes executable to use for syntax checking."
  :type '(repeat string)
  :group 'flymake-python-pyflakes)

(defcustom flymake-python-pyflakes-info-regex nil
  "Regexp used to match messages to be display as informational.
The flymake fork at https://github.com/illusori/emacs-flymake allows
the display of 'info' lines which are neither warnings or errors.
When that version of flymake is in use, this pattern determines
which messages will be displayed in that way."
  :type 'string
  :group 'flymake-python-pyflakes)

(defun flymake-python-pyflakes-command (filename)
  "Construct a command that flymake can use to syntax-check FILENAME."
  (append (list flymake-python-pyflakes-executable)
          flymake-python-pyflakes-extra-arguments
          (list filename)))

(defun flymake-python-pyflakes-warn-regex (executable)
  "Return a regex which identifies warnings output by EXECUTABLE."
  (if (string-match-p "pyflakes" executable)
      "\\(^redefinition\\|.*unused.*\\|used$\\)"
    "^\\([WFCN]\\|E[0-7]\\)"))


;;;###autoload
(defun flymake-python-pyflakes-load ()
  "Configure flymake mode to check the current buffer's python syntax using pyflakes."
  (interactive)
  (flymake-easy-load 'flymake-python-pyflakes-command
                     flymake-python-pyflakes-err-line-patterns
                     'tempdir
                     "py"
                     (flymake-python-pyflakes-warn-regex
                      flymake-python-pyflakes-executable)
                     flymake-python-pyflakes-info-regex))

(provide 'flymake-python-pyflakes)
;;; flymake-python-pyflakes.el ends here
