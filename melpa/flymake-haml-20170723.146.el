;;; flymake-haml.el --- A flymake handler for haml files

;; Copyright (c) 2011-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; URL: https://github.com/purcell/flymake-haml
;; Package-Commit: 22a81e8484734552d461e7ae7305664dc244447e
;; Package-Version: 20170723.146
;; Package-X-Original-Version: 0
;; Package-Requires: ((flymake-easy "0.1"))

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
;;   (require 'flymake-haml)
;;   (add-hook 'haml-mode-hook 'flymake-haml-load)
;;
;; `sass-mode' is a derived mode of 'haml-mode', so
;; `flymake-haml-load' is a no-op unless the current major mode is
;; `haml-mode'.
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

(defconst flymake-haml-err-line-patterns '(("^Syntax error on line \\([0-9]+\\): \\(.*\\)$" nil 1 nil 2)))

;; Invoke utilities with '-c' to get syntax checking
(defun flymake-haml-command (filename)
  "Construct a command that flymake can use to check haml source."
  (list "haml" "-c" filename))

;;;###autoload
(defun flymake-haml-load ()
  "Configure flymake mode to check the current buffer's haml syntax.

This function is designed to be called in `haml-mode-hook'; it
does not alter flymake's global configuration, so function
`flymake-mode' alone will not suffice."
  (interactive)
  (when (eq 'haml-mode major-mode)
    (flymake-easy-load 'flymake-haml-command
                       flymake-haml-err-line-patterns
                       'tempdir
                       "haml")))


(provide 'flymake-haml)
;;; flymake-haml.el ends here
