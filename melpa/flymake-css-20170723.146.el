;;; flymake-css.el --- Flymake support for css using csslint

;; Copyright (c) 2011-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; Homepage: https://github.com/purcell/flymake-css
;; Package-Version: 20170723.146
;; Package-X-Original-Version: 0
;; Package-Requires: ((flymake-easy "0.1"))
;; Package-Commit: de090163ba289910ceeb61b13368ce42d0f2dfd8

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
;;   (require 'flymake-css)
;;   (add-hook 'css-mode-hook 'flymake-css-load)
;;
;; Beware that csslint is quite slow, so there can be a significant lag
;; between editing and the highlighting of resulting errors.
;;
;; Like the author's many other flymake-*.el extensions, this code is
;; designed to configure flymake in a buffer-local fashion, which
;; avoids the dual pitfalls of 1) inflating the global list of
;; `flymake-err-line-patterns' and 2) being required to specify the
;; matching filename extensions (e.g. "*.css") redundantly.
;;
;; Based mainly on the author's flymake-jslint.el, and using the
;; error regex from Arne Jørgensen's similar flymake-csslint.el.
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

(require 'flymake-easy)

;;; Code:

(defgroup flymake-css nil
  "Flymake checking of CSS using csslint"
  :group 'programming
  :prefix "flymake-css-")

;;;###autoload
(defcustom flymake-css-lint-command "csslint"
  "Name (and optionally full path) of csslint executable."
  :type 'string :group 'flymake-css)

(defvar flymake-css-err-line-patterns
  '(("^\\(.*\\): line \\([[:digit:]]+\\), col \\([[:digit:]]+\\), \\(.+\\)$" 1 2 3 4)))

(defun flymake-css-command (filename)
  "Construct a command that flymake can use to check css source."
  (list flymake-css-lint-command "--format=compact" filename))


;;;###autoload
(defun flymake-css-load ()
  "Configure flymake mode to check the current buffer's css syntax."
  (interactive)
  (when (eq major-mode 'css-mode)
    ;; Don't activate in derived modes, e.g. less-css-mode
    (flymake-easy-load 'flymake-css-command
                       flymake-css-err-line-patterns
                       'tempdir
                       "css")))


(provide 'flymake-css)
;;; flymake-css.el ends here
