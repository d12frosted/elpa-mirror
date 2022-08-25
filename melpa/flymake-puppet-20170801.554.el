;;; flymake-puppet.el --- Flymake handler using puppet-lint

;; Copyright 2013 Ben Prew

;; Author: Ben Prew
;; URL: https://github.com/benprew/flymake-puppet
;; Package-Version: 20170801.554
;; Package-Commit: 9579e5c736cb890195464fabf51df113313de88d
;; Version: 1.0.0
;; Package-Requires: ((flymake-easy "0.9"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package implements a flymake handler for syntax-checking
;; puppet using puppet-lint.

;;; Code:

(require 'flymake-easy)

(defconst flymake-puppet-err-line-patterns
  '(("\\(.*line \\([0-9]+\\).*\\)" nil 2 nil 1)
    ("\\(.*.rb:[0-9]+.*\\)" nil nil nil 1)))

(defvar flymake-puppet-executable "puppet-lint"
  "The executable to use for puppet-lint")

(defvar flymake-puppet-options nil "Puppet-lint options")

(defun flymake-puppet-command (filename)
  "Construct a command that flymake can use to check puppet source."
  (append (list flymake-puppet-executable) flymake-puppet-options
          (list filename)))

;;;###autoload
(defun flymake-puppet-load ()
  "Configure flymake mode to check the current buffer's puppet syntax."
  (interactive)
  (flymake-easy-load 'flymake-puppet-command
                     flymake-puppet-err-line-patterns
                     'tempdir
                     "pp"))

(provide 'flymake-puppet)

;;; flymake-puppet.el ends here
