;;; flycheck-guile.el --- A Flycheck checker for GNU Guile -*- lexical-binding: t -*-

;; Copyright (C) 2019  Ricardo Wurmus <rekado@elephly.net>
;; Copyright (C) 2020, 2022, 2023  Free Software Foundation, Inc

;; Author: Ricardo Wurmus <rekado@elephly.net>
;; Maintainer: Andrew Whatson <whatson@tailcall.au>
;; Version: 0.5
;; Package-Version: 20230322.1348
;; Package-Commit: 16c869ec2212dfaeb98f31710667199e4d702515
;; URL: https://github.com/flatwhatson/flycheck-guile
;; Package-Requires: ((emacs "25.1") (flycheck "0.22") (geiser "0.20"))

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

(defvar geiser-guile-load-path)
(defvar geiser-repl-current-project-function)
(defvar geiser-repl-add-project-paths)

(defgroup flycheck-guile nil
  "GNU Guile support for Flycheck."
  :prefix "flycheck-guile-"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/flatwhatson/flycheck-guile"))

(defconst flycheck-guile--warning-specs
  ;; current warnings for GNU Guile 3.0.9-16-ge334e5958
  '(("unsupported-warning"         nil  "warn about unknown warning types")
    ("unused-variable"             nil  "report unused variables")
    ("unused-toplevel"             nil  "report unused local top-level variables")
    ("unused-module"               nil  "report unused modules")
    ("shadowed-toplevel"           nil  "report shadowed top-level variables")
    ("unbound-variable"            t    "report possibly unbound variables")
    ("macro-use-before-definition" t    "report possibly mis-use of macros before they are defined")
    ("use-before-definition"       t    "report uses of top-levels before they are defined")
    ("non-idempotent-definition"   t    "report names that can refer to imports on first load, but module definitions on second load")
    ("arity-mismatch"              t    "report procedure arity mismatches (wrong number of arguments)")
    ("duplicate-case-datum"        t    "report a duplicate datum in a case expression")
    ("bad-case-datum"              t    "report a case datum that cannot be meaningfully compared using `eqv?'")
    ("format"                      t    "report wrong number of arguments to `format'")))

(defcustom flycheck-guile-warnings
  ;; default warnings are marked T above
  (mapcar #'car (seq-filter #'cadr flycheck-guile--warning-specs))
  "A list of warnings to enable for `guild compile'.

The value of this variable is a list of strings, where each
string names a supported warning type.

The list of supported warning types can be found by running
`guild compile -W help'."
  :type (let* ((max-length
                (seq-max (mapcar (lambda (spec)
                                   (length (car spec)))
                                 flycheck-guile--warning-specs)))
               (options
                (mapcar (lambda (spec)
                          (let* ((name (car spec))
                                 (desc (caddr spec))
                                 (pad (make-string (- max-length (length name)) ?\s)))
                            `(const
                              :tag ,(format "%s%s ; %s" name pad desc)
                              ,name)))
                        flycheck-guile--warning-specs)))
          `(choice
            (list :tag "Level 0 (no warnings)" (const "0"))
            (list :tag "Level 1 (default)" (const "1"))
            (list :tag "Level 2" (const "2"))
            (list :tag "Level 3" (const "3"))
            (set :tag "Select warnings" ,@options)
            (repeat :tag "Specify warnings" string)))
  :group 'flycheck-guile)

(flycheck-def-args-var flycheck-guile-args guile)

(defun flycheck-guile--load-path-args ()
  "Build the load-path arguments for `guild compile'."
  (mapcan (lambda (p)
            (list "-L" p))
          (append (flycheck-guile--project-path)
                  geiser-guile-load-path)))

(defun flycheck-guile--project-path ()
  "Determine project paths from geiser configuration."
  ;; see `geiser-repl--set-up-load-path'
  (if-let ((geiser-repl-add-project-paths)
           (root (funcall geiser-repl-current-project-function)))
      (mapcar (lambda (p)
                (expand-file-name p root))
              (cond ((eq t geiser-repl-add-project-paths)
                     '("."))
                    ((listp geiser-repl-add-project-paths)
                     geiser-repl-add-project-paths)))
    nil))

(defun flycheck-guile--filter-errors (errors)
  "Fix up ERRORS before passing them to flycheck."
  (seq-do (lambda (err)
            ;; errors without a line are on line 0
            ;; see `flycheck-fill-empty-line-numbers'
            (unless (flycheck-error-line err)
              (setf (flycheck-error-line err) 0))
            ;; flycheck wants 1-based columns, guile gives 0-based
            ;; see `flycheck-increment-error-columns'
            (when (flycheck-error-column err)
              (cl-incf (flycheck-error-column err) 1))
            (when (flycheck-error-end-column err)
              (cl-incf (flycheck-error-end-column err) 1)))
          errors)
  errors)

(flycheck-define-checker guile
  "A GNU Guile syntax checker using `guild compile'."
  :command ("guild" "compile" "-O0"
            (eval flycheck-guile-args)
            (option-list "-W" flycheck-guile-warnings)
            (eval (flycheck-guile--load-path-args))
            source)
  :predicate
  (lambda ()
    (and (bound-and-true-p geiser-mode)
         (eq (bound-and-true-p geiser-impl--implementation)
             'guile)))
  :verify
  (lambda (_checker)
    (let ((geiser-impl (and (bound-and-true-p geiser-mode)
                            (bound-and-true-p geiser-impl--implementation))))
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
  :error-filter flycheck-guile--filter-errors
  :error-patterns
  ((warning
    line-start
    (file-name) ":" line ":" column ": warning:" (message) line-end)
   (warning
    line-start
    "<unknown-location>: warning:" (message) line-end)
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
    "ice-9/boot-9.scm:" (+ digit) ":" (+ digit) ":" (+ (any space "\n"))
    "In procedure raise-exception:"                 (+ (any space "\n"))
    (message (+? anything)) (* space) string-end)
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
