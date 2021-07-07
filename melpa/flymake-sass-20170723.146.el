;;; flymake-sass.el --- Flymake handler for sass and scss files

;; Copyright (c) 2014-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; URL: https://github.com/purcell/flymake-sass
;; Package-Commit: 2de28148e92deb93bff3d55fe14e7c67ac476056
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
;;
;; Usage:
;;   (require 'flymake-sass)
;;   (add-hook 'sass-mode-hook 'flymake-sass-load)
;;   (add-hook 'scss-mode-hook 'flymake-sass-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

(defconst flymake-sass-err-line-patterns
  '(("^Syntax error on line \\([0-9]+\\): \\(.*\\)$" nil 1 nil 2)
    ("^WARNING on line \\([0-9]+\\) of .*?:\r?\n\\(.*\\)$" nil 1 nil 2)
    ("^Syntax error: \\(.*\\)\r?\n        on line \\([0-9]+\\) of .*?$" nil 2 nil 1) ;; Older sass versions
    ))

;; Invoke utilities with '-c' to get syntax checking
(defun flymake-sass-command (filename)
  "Construct a command that flymake can use to check sass source."
  (append '("sass" "-c")
          (when (eq 'scss-mode major-mode)
            (cons "--scss" scss-sass-options))
          (list filename)))

;;;###autoload
(defun flymake-sass-load ()
  "Configure flymake mode to check the current buffer's sass syntax."
  (interactive)
  (flymake-easy-load 'flymake-sass-command
                     flymake-sass-err-line-patterns
                     'tempdir
                     "rb"))


(provide 'flymake-sass)
;;; flymake-sass.el ends here
