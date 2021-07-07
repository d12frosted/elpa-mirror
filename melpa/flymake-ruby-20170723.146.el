;;; flymake-ruby.el --- A flymake handler for ruby-mode files

;; Copyright (c) 2011-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; URL: https://github.com/purcell/flymake-ruby
;; Package-Commit: 6c320c6fb686c5223bf975cc35178ad6b195e073
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
;;   (require 'flymake-ruby)
;;   (add-hook 'ruby-mode-hook 'flymake-ruby-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

(defconst flymake-ruby-err-line-patterns
  '(("^\\(.*\.rb\\):\\([0-9]+\\): \\(.*\\)$" 1 2 nil 3)))

(defvar flymake-ruby-executable "ruby"
  "The ruby executable to use for syntax checking.")

;; Invoke ruby with '-c' to get syntax checking
(defun flymake-ruby-command (filename)
  "Construct a command that flymake can use to check ruby source in FILENAME."
  (list flymake-ruby-executable "-w" "-c" filename))

;;;###autoload
(defun flymake-ruby-load ()
  "Configure flymake mode to check the current buffer's ruby syntax."
  (interactive)
  (flymake-easy-load 'flymake-ruby-command
                     flymake-ruby-err-line-patterns
                     'tempdir
                     "rb"))

(provide 'flymake-ruby)
;;; flymake-ruby.el ends here
