;;; flymake-php.el --- A flymake handler for php-mode files

;; Copyright (c) 2011-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; URL: https://github.com/purcell/flymake-php
;; Package-Commit: c045d01e002ba5e09b05f40e25bf5068d02126bc
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
;;   (require 'flymake-php)
;;   (add-hook 'php-mode-hook 'flymake-php-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:
(require 'flymake-easy)

(defconst flymake-php-err-line-patterns
  '(("\\(?:Parse\\|Fatal\\|syntax\\) error[:,] \\(.*\\) in \\(.*\\) on line \\([0-9]+\\)" 2 3 nil 1)))

(defvar flymake-php-executable "php"
  "The php executable to use for syntax checking.")

(defun flymake-php-command (filename)
  "Construct a command that flymake can use to check php source in FILENAME."
  (list flymake-php-executable "-l" "-f" filename))

;;;###autoload
(defun flymake-php-load ()
  "Configure flymake mode to check the current buffer's php syntax."
  (interactive)
  (flymake-easy-load 'flymake-php-command
                     flymake-php-err-line-patterns
                     'tempdir
                     "php"))


(provide 'flymake-php)
;;; flymake-php.el ends here
