;;; flymake-jslint.el --- A flymake handler for javascript using jslint

;; Copyright (c) 2011-2017 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; Homepage: https://github.com/purcell/flymake-jslint
;; Package-Version: 20170723.146
;; Package-X-Original-Version: 0
;; Package-Requires: ((flymake-easy "0.1"))
;; Package-Commit: 8edb82be605542b0ef62d38d818adcdde335eecb

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
;; References:
;;   http://www.emacswiki.org/cgi-bin/wiki/FlymakeJavaScript
;;   http://d.hatena.ne.jp/kazu-yamamoto/mobile?date=20071029
;;
;; Works with either "jslint" from jslint.com, or "jsl" from
;; javascriptlint.com.  The default is "jsl", if that executable is
;; found at load-time.  Otherwise, "jslint" is the default.  If you want
;; to use the non-default checker, you can customize the values of
;; `flymake-jslint-command' and `flymake-jslint-args' accordingly.
;;
;; Usage:
;;   (require 'flymake-jslint)
;;   (add-hook 'js-mode-hook 'flymake-jslint-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Code:

(require 'flymake-easy)

(defgroup flymake-jslint nil
  "Flymake checking of Javascript using jslint"
  :group 'programming
  :prefix "flymake-jslint-")

;;;###autoload
(defcustom flymake-jslint-detect-trailing-comma t
  "Whether or not to report warnings about trailing commas."
  :type 'boolean :group 'flymake-jslint)

;;;###autoload
(defcustom flymake-jslint-command
  (if (executable-find "jsl") "jsl" "jslint")
  "Name (and optionally full path) of jslint executable."
  :type 'string :group 'flymake-jslint)

;;;###autoload
(defcustom flymake-jslint-args
  (unless (string-equal "jsl" flymake-jslint-command)
    (mapcar
     'symbol-name
     '(--white --undef --nomen --regexp --plusplus --bitwise --newcap --sloppy --vars --eqeq)))
  "Command-line args for jslint executable."
  :type '(repeat string) :group 'flymake-jslint)

(defconst flymake-jslint-err-line-patterns
  '(("^ *#[0-9]+ \\(.*?\\)\n.*?// Line \\([0-9]+\\), Pos \\([0-9]+\\)$" nil 2 3 1)
    ;; jsl
    ("^\\(.+\\)\:\\([0-9]+\\)\: \\(SyntaxError\:.+\\)\:$" nil 2 nil 3)
    ("^\\(.+\\)(\\([0-9]+\\)): \\(SyntaxError:.+\\)$" nil 2 nil 3)
    ("^\\(.+\\)(\\([0-9]+\\)): \\(lint \\)?\\(warning:.+\\)$" nil 2 nil 4)))
(defconst flymake-jslint-trailing-comma-err-line-pattern
  '("^\\(.+\\)\:\\([0-9]+\\)\: strict \\(warning: trailing comma.+\\)\:$" nil 2 nil 3))

(defun flymake-jslint-command (filename)
  "Construct a command that flymake can use to check javascript source in FILENAME."
  (append
   (list flymake-jslint-command)
   flymake-jslint-args
   (unless (string-match "jslint" flymake-jslint-command)
     ;; jsl required option
     (list "-process"))
   (list filename)))

;;;###autoload
(defun flymake-jslint-load ()
  "Configure flymake mode to check the current buffer's javascript syntax."
  (interactive)
  (flymake-easy-load 'flymake-jslint-command
                     (append flymake-jslint-err-line-patterns
                             (when flymake-jslint-detect-trailing-comma
                               (list flymake-jslint-trailing-comma-err-line-pattern)))
                     'tempdir
                     "js"))


(provide 'flymake-jslint)
;;; flymake-jslint.el ends here
