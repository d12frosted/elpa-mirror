;;; flymake-hlint.el --- A flymake handler for haskell-mode files using hlint

;; Copyright (c) 2013-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; URL: https://github.com/purcell/flymake-hlint
;; Package-Commit: f910736b26784efc9a2fa29503f45c1f1dd0aa38
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
;;   (require 'flymake-hlint)
;;   (add-hook 'haskell-mode-hook 'flymake-hlint-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

(defconst flymake-hlint-err-line-patterns
  '(("^\\(.*\.hs\\):\\([0-9]+\\):\\([0-9]+\\): \\(.*\\(?:\n.+\\)+\\)" 1 2 3 4)))

(defvar flymake-hlint-executable "hlint"
  "The hlint executable to use for syntax checking.")

(defun flymake-hlint-command (filename)
  "Construct a command that flymake can use to check source in FILENAME with hlint."
  (list flymake-hlint-executable filename))

;;;###autoload
(defun flymake-hlint-load ()
  "Configure flymake mode to check the current buffer's hlint syntax."
  (interactive)
  (flymake-easy-load 'flymake-hlint-command
                     flymake-hlint-err-line-patterns
                     'inplace
                     "hs"))

(provide 'flymake-hlint)
;;; flymake-hlint.el ends here
