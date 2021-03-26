;;; flymake-json.el --- A flymake handler for json using jsonlint

;; Copyright (c) 2013-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; Homepage: https://github.com/purcell/flymake-json
;; Package-Version: 20180511.911
;; Package-X-Original-Version: 0
;; Package-Requires: ((flymake-easy "0.1"))
;; Package-Commit: 03b4e5e7ad11938781257a783e717ab95fe65952

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

;; This package requires the "jsonlint" program, which can be installed using npm:
;;
;;    npm install jsonlint -g
;;
;; Usage:
;;
;;   (require 'flymake-json)
;;
;; Then, if you're using `json-mode':
;;
;;   (add-hook 'json-mode-hook 'flymake-json-load)
;;
;; or, if you use `js-mode' for json:
;;
;;   (add-hook 'js-mode-hook 'flymake-json-maybe-load)
;;
;; otherwise:
;;
;;   (add-hook 'find-file-hook 'flymake-json-maybe-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

(defconst flymake-json-err-line-patterns
  '(("^\\(.+\\)\: line \\([0-9]+\\), col \\([0-9]+\\), \\(.+\\)$" nil 2 3 4)))

(defun flymake-json-command (filename)
  "Construct a command that flymake can use to check json source in FILENAME."
  (list "jsonlint" "-c" "-q" filename))


;;;###autoload
(defun flymake-json-load ()
  "Configure flymake mode to check the current buffer's javascript syntax."
  (interactive)
  (flymake-easy-load 'flymake-json-command
                     flymake-json-err-line-patterns
                     'tempdir
                     "json"))

;;;###autoload
(defun flymake-json-maybe-load ()
  "Call `flymake-json-load' if this file appears to be json."
  (interactive)
  (if (and buffer-file-name
           (string= "json" (file-name-extension buffer-file-name)))
      (flymake-json-load)))


(provide 'flymake-json)
;;; flymake-json.el ends here
