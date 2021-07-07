;;; flymake-coffee.el --- A flymake handler for coffee script

;; Copyright (c) 2011-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; Homepage: https://github.com/purcell/flymake-coffee
;; Package-Version: 20170723.146
;; Package-X-Original-Version: 0
;; Package-Requires: ((flymake-easy "0.1"))
;; Package-Commit: dee295acf30820ed15fe0de17137d50bc27fc80c

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

;; Based in part on http://d.hatena.ne.jp/antipop/20110508/1304838383
;;
;; Usage:
;;   (require 'flymake-coffee)
;;   (add-hook 'coffee-mode-hook 'flymake-coffee-load)
;;
;; Executes "coffeelint" if available, otherwise "coffee".
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)
;; Doesn't strictly require coffee-mode, but will use 'coffee-command if set

(defgroup flymake-coffee nil
  "Flymake support for CoffeeScript"
  :prefix "flymake-coffee-"
  :group 'flymake)

(defcustom flymake-coffee-coffeelint-configuration-file nil
  "File that contains custom coffeelint configuration.
Must be a full path, so use `expand-file-name' if you want to use \"~\" etc."
  :type 'string
  :group 'flymake-coffee)

(defconst flymake-coffee-err-line-patterns
  '(;; coffee
    ("^SyntaxError: In \\([^,]+\\), \\(.+\\) on line \\([0-9]+\\)" 1 3 nil 2)
    ;; coffeelint
    ("SyntaxError: \\(.*\\) on line \\([0-9]+\\)" nil 2 nil 1)
    ("\\(.*?\\):\\([0-9]+\\):\\([0-9]+\\): \\(error\\): \\(.*\\)" 1 2 3 5)
    ("\\(.+\\),\\([0-9]+\\)\\(?:,[0-9]*\\)?,\\(\\(warn\\|error\\),.+\\)" 1 2 nil 3)))

(defun flymake-coffee-command (filename)
  "Construct a command that flymake can use to check coffeescript source."
  (if (executable-find "coffeelint")
      (append '("coffeelint")
              (when flymake-coffee-coffeelint-configuration-file
                (list "-f" flymake-coffee-coffeelint-configuration-file))
              (list "--csv" filename))
    (list (if (boundp 'coffee-command) coffee-command "coffee")
          filename)))

;;;###autoload
(defun flymake-coffee-load ()
  "Configure flymake mode to check the current buffer's coffeescript syntax."
  (interactive)
  (flymake-easy-load 'flymake-coffee-command
                     flymake-coffee-err-line-patterns
                     'tempdir
                     "coffee"))


(provide 'flymake-coffee)
;;; flymake-coffee.el ends here
