;;; flymake-shell.el --- A flymake syntax-checker for shell scripts

;; Copyright (C) 2011-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; URL: https://github.com/purcell/flymake-shell
;; Package-Commit: a16cf453056b9849cc7c912bb127fb0b08fc6dab
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

;;   (require 'flymake-shell)
;;   (add-hook 'sh-set-shell-hook 'flymake-shell-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

(defconst flymake-shell-supported-shells '(bash zsh sh dash))

(defconst flymake-shell-err-line-pattern-re
  '(("^\\(.+\\): line \\([0-9]+\\): \\([^`].+\\)$" 1 2 nil 3) ; bash
    ("^\\(.+\\): ?\\([0-9]+\\): \\(.+\\)$" 1 2 nil 3)) ; zsh / dash
  "Regexp matching shell error messages.")

(defun flymake-shell-command (filename)
  "Construct a command that flymake can use to check shell source."
  (list (symbol-name sh-shell) "-n" filename))

;;;###autoload
(defun flymake-shell-load ()
  "Configure flymake mode to check the current buffer's shell-script syntax."
  (interactive)
  (unless (eq 'sh-mode major-mode)
    (error "Cannot enable flymake-shell in this major mode"))
  (if (memq sh-shell flymake-shell-supported-shells)
      (flymake-easy-load 'flymake-shell-command
                         flymake-shell-err-line-pattern-re
                         'tempdir
                         "sh")
    (message "Shell %s is not supported by flymake-shell" sh-shell)))


(provide 'flymake-shell)
;;; flymake-shell.el ends here
