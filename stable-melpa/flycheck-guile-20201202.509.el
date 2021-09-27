;;; flycheck-guile.el --- A Flycheck checker for GNU Guile -*- lexical-binding: t -*-

;; Copyright (C) 2019  Ricardo Wurmus <rekado@elephly.net>
;; Copyright (C) 2020  Free Software Foundation, Inc

;; Author: Ricardo Wurmus <rekado@elephly.net>
;; Maintainer: Andrew Whatson <whatson@gmail.com>
;; Version: 0.1
;; URL: https://github.com/flatwhatson/flycheck-guile
;; Package-Requires: ((emacs "24.1") (flycheck "0.22") (geiser "0.11"))

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

;; GNU Guile syntax checking support for Flycheck.

;;; Code:

(require 'flycheck)

(defgroup flycheck-guile nil
  "GNU Guile support for Flycheck."
  :prefix "flycheck-guile-"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/flatwhatson/flycheck-guile"))

(defcustom flycheck-guile-warnings
  '(;"unsupported-warning"         ; warn about unknown warning types
    "unused-variable"             ; report unused variables
    ;"unused-toplevel"             ; report unused local top-level variables
    ;"shadowed-toplevel"           ; report shadowed top-level variables
    "unbound-variable"            ; report possibly unbound variables
    "macro-use-before-definition" ; report possibly mis-use of macros before they are defined
    "arity-mismatch"              ; report procedure arity mismatches (wrong number of arguments)
    "duplicate-case-datum"        ; report a duplicate datum in a case expression
    "bad-case-datum"              ; report a case datum that cannot be meaningfully compared using `eqv?'
    "format"                      ; report wrong number of arguments to `format'
    )
  "A list of warnings to enable for `guild compile'.

The value of this variable is a list of strings, where each
string names a supported warning type.

The list of supported warning types can be found by running
`guild compile -W help'."
  :type '(repeat string)
  :group 'flycheck-guile)

(flycheck-def-args-var flycheck-guile-args guile)

(flycheck-define-checker guile
  "A GNU Guile syntax checker using `guild compile'."
  :command ("guild" "compile" "-O0"
            (eval flycheck-guile-args)
            (option-list "-W" flycheck-guile-warnings)
            (option-list "-L" geiser-guile-load-path list expand-file-name)
            source)
  :predicate
  (lambda ()
    (and (boundp 'geiser-impl--implementation)
         (eq geiser-impl--implementation 'guile)))
  :verify
  (lambda (_checker)
    (let ((geiser-impl (bound-and-true-p geiser-impl--implementation)))
      (list
       (flycheck-verification-result-new
        :label "Geiser Implementation"
        :message (cond
                  ((eq geiser-impl 'guile) "Guile")
                  (geiser-impl (format "Other: %s" geiser-impl))
                  (t "Geiser not active"))
        :face (cond
               ((or (eq geiser-impl 'guile)) 'success)
               (t '(bold error)))))))
  :error-patterns
  ((warning
    line-start
    (file-name) ":" line ":" column ": warning:" (message) line-end)
   (error
    line-start
    "ice-9/boot-9.scm:" (+ digit) ":" (+ digit) ":" (+ (any space "\n"))
    "In procedure raise-exception:"                 (+ (any space "\n"))
    "In procedure " (id (+ (not (any ":")))) ":"    (+ (any space "\n"))
    (file-name) ":" line ":" column ":" (message (+? anything)) (* space) string-end)
   (error
    line-start
    "ice-9/boot-9.scm:" (+ digit) ":" (+ digit) ":" (+ (any space "\n"))
    "In procedure raise-exception:"                 (+ (any space "\n"))
    (id (+ (not (any ":")))) ":"                    (+ (any space "\n"))
    (file-name) ":" line ":" column ":" (message (+? anything)) (* space) string-end)
   (error
    line-start
    (file-name) ":" line ":" column ":"             (+ (any space "\n"))
    "In procedure raise-exception:"                 (+ (any space "\n"))
    (message (+? anything)) (* space) string-end)
   (error
    line-start
    (file-name) ":" line ":" column ":"             (+ (any space "\n"))
    (message (+? anything)) (* space) string-end))
  :modes (scheme-mode geiser-mode))

(add-to-list 'flycheck-checkers 'guile)

(provide 'flycheck-guile)
;;; flycheck-guile.el ends here
