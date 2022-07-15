;;; flycheck-hledger.el --- Flycheck module to check hledger journals  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Url: https://github.com/DamienCassou/flycheck-hledger/
;; Package-Version: 20220715.1115
;; Package-Commit: c360025b8433abc4da89b0bfcc7ed1ff27004c64
;; Package-requires: ((emacs "27.1") (flycheck "31"))
;; Version: 0.3.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package is a flycheck [1] checker for hledger files [2].
;;
;; [1] https://www.flycheck.org/en/latest/
;; [2] https://hledger.org/

;;; Code:

(require 'flycheck)

(flycheck-def-option-var flycheck-hledger-strict nil hledger
  "Whether to enable strict mode.

See URL https://hledger.org/hledger.html#strict-mode"
  :type 'boolean)

(flycheck-def-option-var flycheck-hledger-checks nil hledger
  "List of additional checks to run.

Checks include: accounts, commodities, ordereddates, payees and
uniqueleafnames. More information at URL
https://hledger.org/hledger.html#check."
  :type '(repeat string))

(defun flycheck-hledger--enabled-p ()
  "Return non-nil if flycheck-hledger should be enabled in the current buffer."
  (or
   ;; Either the user is using `hledger-mode':
   (derived-mode-p 'hledger-mode)
   ;; or the user is using `ledger-mode' with the binary path pointing
   ;; to "hledger":
   (and (bound-and-true-p ledger-binary-path)
        (string-suffix-p "hledger" ledger-binary-path))))

(flycheck-define-checker hledger
  "A checker for errors in hledger journals, optionally with --strict checking and/or extra checks supported by the check command."
  :modes (ledger-mode hledger-mode)
  ;; Activate the checker only if ledger-binary-path ends with "hledger":
  :predicate flycheck-hledger--enabled-p
  :command ("hledger" "-f" source-inplace "--auto" "check"
            (option-flag "--strict" flycheck-hledger-strict)
            (eval flycheck-hledger-checks))
  :error-filter (lambda (errors) (flycheck-sanitize-errors (flycheck-fill-empty-line-numbers errors)))
  :error-parser flycheck-parse-with-patterns
  :error-patterns
  (
   ;; hledger error messages are becoming more consistent, but still require a number of patterns.
   ;; We try to support hledger 1.26 and newer.
   ;; The typical format is a standard first line with possible error type, filename and line/column number(s),
   ;; several lines of highlighted excerpt, and one or more lines of explanation.
   ;; See https://github.com/simonmichael/hledger/tree/master/hledger/test/errors for examples.

   ;; hledger 1.26

   ;; hledger 1.26 assertions (:LINE:COL)
   (error
    bol "hledger: Error: balance assertion: " (file-name (minimal-match (one-or-more (not ":")))) ":" line ":" column "\n"
    (message (one-or-more bol (zero-or-more nonl) "\n")))

   ;; hledger 1.26 balancedwithautoconversion, balancednoautoconversion (:LINE-LINE)
   (error
    bol "hledger: Error: " (file-name (minimal-match (one-or-more (not ":")))) ":" line "-" end-line "\n"
    (message (one-or-more bol (zero-or-more nonl) "\n")))

   ;; hledger 1.26+

   ;; hledger 1.26+ error with LINE-LINE:
   (error
    bol "hledger: Error: " (file-name (minimal-match (one-or-more (not ":")))) ":" line "-" end-line ":\n" ; first line
    (one-or-more bol (any space digit) (zero-or-more nonl) "\n")                                           ; excerpt lines
    (message (one-or-more bol (zero-or-more nonl) "\n")))                                                  ; message lines

   ;; hledger 1.26+ error with LINE:COL-COL:
   (error
    bol "hledger: Error: " (file-name (minimal-match (one-or-more (not ":")))) ":" line ":" column "-" end-column ":\n"
    (one-or-more bol (any space digit) (zero-or-more nonl) "\n")
    (message (one-or-more bol (zero-or-more nonl) "\n")))

   ;; hledger 1.26+ error with LINE:COL:
   (error
    bol "hledger: Error: " (file-name (minimal-match (one-or-more (not ":")))) ":" line ":" column ":\n"
    (one-or-more bol (any space digit) (zero-or-more nonl) "\n")
    (message (one-or-more bol (zero-or-more nonl) "\n")))

   ;; hledger 1.26+ error with LINE:
   (error
    bol "hledger: Error: " (file-name (minimal-match (one-or-more (not ":")))) ":" line ":\n"
    (one-or-more bol (any space digit) (zero-or-more nonl) "\n")
    (message (one-or-more bol (zero-or-more nonl) "\n")))))

(add-to-list 'flycheck-checkers 'hledger)

(provide 'flycheck-hledger)
;;; flycheck-hledger.el ends here

;;; LocalWords:  flycheck-hledger
