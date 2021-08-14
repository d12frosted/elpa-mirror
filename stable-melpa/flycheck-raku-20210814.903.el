;;; flycheck-raku.el --- Raku support in Flycheck -*- lexical-binding: t; -*-

;; Copyright (C) 2015 Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>
;; Copyright (C) 2020 Johnathon Weare <jrweare@gmail.com>
;; Copyright (C) 2021 Siavash Askari Nasr

;; Author: Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>
;;      Johnathon Weare <jrweare@gmail.com>
;;      Siavash Askari Nasr <siavash.askari.nasr@gmail.com>
;; original URL: https://github.com/hinrik/flycheck-perl6
;; URL: https://github.com/Raku/flycheck-raku
;; Package-Version: 20210814.903
;; Package-Commit: 50ac228e658a7f86efc298ee3ebd0b9706f083d0
;; Keywords: tools, convenience
;; Version: 0.6
;; Package-Requires: ((emacs "26.3") (flycheck "0.22"))

;; This file is not part of GNU Emacs.

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

;; Raku syntax checking support for Flycheck.

;; Runs "raku -c" on your code.  Currently does not report the exact
;; column number of the error, just the line number.

;;; Code:

(require 'flycheck)
(require 'project)

(defgroup flycheck-raku nil
  "Raku support for Flycheck."
  :prefix "flycheck-raku-"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/Raku/flycheck-raku"))

(flycheck-def-option-var flycheck-raku-include-path nil raku
  "A list of include directories for Raku (change this from raku to perl6 if on an old install).

The value of this variable is a list of strings, where each
string is a directory to add to the include path of Raku.
Relative paths are relative to the file being checked."
  :type '(repeat (directory :tag "Include directory"))
  :safe #'flycheck-string-list-p)

(flycheck-define-checker raku
  "A Raku syntax checker."
  :command ("raku" "-c"
            (option-list "-I" flycheck-raku-include-path)
            ;; Add project root to path
            (eval (let ((current-project (project-current)))
                    (if current-project
                        (let ((project-root (car (project-roots current-project))))
                          (list "-I" (expand-file-name project-root))))))
            source)
  :error-patterns (;; Multi-line compiler errors
                   (error line-start (minimal-match (1+ anything)) " Error while compiling " (file-name) (? "\r") "\n"
                          (message (minimal-match (1+ anything (? "\r") "\n")))
                          (minimal-match (0+ anything))  "at " (file-name) ":" line)
                   ;; Undeclared routine errors
                   (error line-start (minimal-match (1+ anything)) " Error while compiling " (file-name) (? "\r") "\n"
                          (? whitespace) (message (minimal-match (1+ anything)) "at line " line (minimal-match (0+ anything)) (? "\r") "\n"))
                   ;; Other compiler errors
                   (error line-start (minimal-match (1+ anything)) (? "\r") "\n"
                          (message (minimal-match (1+ anything))) (? "\r") "\nat " (file-name) ":" line)
                   ;; Potential difficulties
                   (error line-start (minimal-match (1+ anything)) "difficulties:" (? "\r") "\n"
                          (0+ whitespace) (message (minimal-match (1+ anything))) (? "\r") "\n"
                          (0+ whitespace) "at " (file-name) ":" line))
  :modes raku-mode)

(add-to-list 'flycheck-checkers 'raku)

(provide 'flycheck-raku)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; flycheck-raku.el ends here
