;;; flycheck-deno.el --- Flycheck for deno-lint  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Shen, Jen-Chieh

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Maintainer: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/jcs-elpa/flycheck-deno
;; Package-Version: 20221222.1646
;; Package-Commit: ea7a5330535bdb25edb1c147f4d6d426abb1e097
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1") (flycheck "0.14"))
;; Keywords: lisp deno

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Flycheck for deno-lint.
;;

;;; Code:

(require 'seq)

(require 'flycheck)

(defgroup flycheck-deno nil
  "Flycheck for deno-lint."
  :prefix "flycheck-deno-"
  :group 'flycheck
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/flycheck-deno"))

(flycheck-def-args-var flycheck-deno-lint-args (deno-lint)
  :package-version '(flycheck-deno . "0.1.0"))

(defun flycheck-deno-parse-lint (output checker buffer)
  "Parse deno-lint errors from JSON OUTPUT.

CHECKER and BUFFER denoted the CHECKER that returned OUTPUT and
the BUFFER that was checked respectively."
  (let (errors)
    (seq-map (lambda (message)
               (dolist (data (cdr message))
                 (let-alist data
                   (push (flycheck-error-new-at
                          .range.start.line
                          (1+ .range.start.col)
                          (pcase (car message)
                            (`diagnostics 'warning)
                            (`errors 'error)
                            (_ 'warning))
                          .message
                          :id .code
                          :checker checker
                          :buffer buffer
                          :filename .filename
                          :end-line .range.end.line
                          :end-column (1+ .range.end.col))
                         errors))))
             (car (flycheck-parse-json output)))
    (nreverse errors)))

(flycheck-define-checker deno-lint
  "Checker for deno source files.

See `https://deno.land/manual@v1.29.1/tools/linter'."
  :command ("deno" "lint" "--json"
            (eval flycheck-deno-lint-args)
            source)
  :error-parser flycheck-deno-parse-lint
  :modes ( js-mode js2-mode js3-mode js-ts-mode
           typescript-mode typescript-ts-mode))

;;;###autoload
(defun flycheck-deno-setup ()
  "Setup flycheck-package."
  (interactive)
  (add-to-list 'flycheck-checkers 'deno-lint))

(provide 'flycheck-deno)
;;; flycheck-deno.el ends here
