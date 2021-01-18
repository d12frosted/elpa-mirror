;;; flycheck-hledger.el --- Flycheck module to check hledger journals  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Url: https://github.com/DamienCassou/flycheck-hledger/
;; Package-Version: 20210118.724
;; Package-Commit: 92daa6032cbd34b8550426d78c03a5897397c6ba
;; Package-requires: ((emacs "27.1") (flycheck "31"))
;; Version: 0.2.0

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

(flycheck-define-checker hledger
  "A checker for hledger journals, showing unmatched balances and failed checks."
  :command ("hledger"
            "-f" source-inplace
            "--auto"
            "check"
            (option-flag "--strict" flycheck-hledger-strict)
            (eval flycheck-hledger-checks))
  ;; Activate the checker only if ledger-binary-path ends with "hledger":
  :predicate (lambda () (and (bound-and-true-p ledger-binary-path)
                        (string-suffix-p "hledger" (file-name-nondirectory ledger-binary-path))))
  ;; A dedicated filter is necessary because hledger reports some errors with no line number:
  :error-filter (lambda (errors) (flycheck-sanitize-errors (flycheck-fill-empty-line-numbers errors)))
  :error-patterns
  (;; Used for an unbalanced transaction:
   (error line-start "hledger: \"" (file-name) "\" (lines " line "-" end-line ")\n"
          (message (zero-or-more line-start (zero-or-more not-newline) "\n")) "\n")
   ;; Used for invalid balance assertion:
   (error line-start "hledger: balance assertion: \"" (file-name) "\" (line " line ", column " column ")\n"
          "transaction:\n"
          (message (zero-or-more line-start (zero-or-more not-newline) "\n")) "\n")
   ;; Used for invalid regular expression:
   (error line-start "hledger: " (message "this regular expression" (zero-or-more not-newline)) "\n")
   ;; Used for an undeclared payee:
   (error line-start "Error: " (message) "\n"
          "at: \"" (file-name) "\" (lines " line "-" end-line ")\n")
   ;; Used for unordered dates:
   (error line-start "Error: " (message) "\n"
          "at \"" (file-name) "\" (lines " line "-" end-line "):\n")
   ;; Used for duplicate leaf names:
   (error line-start "Error: " (message) "\n")
   ;; Used for an undeclared account:
   (error line-start "hledger: " (message) "\n"
          "in transaction at: \"" (file-name) "\" (lines " line "-" end-line ")\n")
   ;; Used for parse errors and invalid dates:
   (error line-start "hledger: " (file-name) ":" line ":" column ":\n"
          (message (zero-or-more line-start (zero-or-more not-newline) "\n")) "\n"))
  :error-parser flycheck-parse-with-patterns
  :modes (ledger-mode hledger-mode))

(add-to-list 'flycheck-checkers 'hledger)

(provide 'flycheck-hledger)
;;; flycheck-hledger.el ends here
