;;; flycheck-hledger.el --- Flycheck module to check hledger journals  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Url: https://github.com/DamienCassou/flycheck-hledger/
;; Package-Version: 20220321.724
;; Package-Commit: c01321665e65233897f359e32d8f9a1a8563eff3
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
  "A checker for hledger journals, showing unmatched balances and failed checks."
  :modes (ledger-mode hledger-mode)
  ;; Activate the checker only if ledger-binary-path ends with "hledger":
  :predicate flycheck-hledger--enabled-p
  :command ("hledger"
            "-f" source-inplace
            "--auto"
            "check"
            (option-flag "--strict" flycheck-hledger-strict)
            (eval flycheck-hledger-checks))
  ;; hledger error messages are quite inconsistent, requiring a filter and multiple patterns.
  :error-filter (lambda (errors) (flycheck-sanitize-errors (flycheck-fill-empty-line-numbers errors)))
  :error-parser flycheck-parse-with-patterns
  :error-patterns
  (
   ;; Unbalanced transaction:
   (error line-start "hledger: " (file-name) ":" line "-" end-line "\n"
          (message (zero-or-more line-start (zero-or-more not-newline) "\n")) "\n")
   ;; Failing balance assertion:
   (error line-start "hledger: balance assertion: " (file-name) ":" line ":" column "\n"
          "transaction:\n"
          (message (zero-or-more line-start (zero-or-more not-newline) "\n")) "\n")
   ;; Invalid regular expression:
   (error line-start "hledger: " (message "this regular expression" (zero-or-more not-newline)) "\n")
   ;; Undeclared account:
   (error line-start "hledger: " (message) "\n"
          "in transaction at: " (file-name) ":" line "-" end-line "\n")
   ;; Undeclared commodity:
   (error line-start "hledger: " (message) "\n"  ; hledger: prefix
          "at: " (file-name) ":" line "-" end-line "\n")
   ;; Undeclared payee:
   (error line-start "Error: " (message) "\n"  ; Error: prefix
          "at: " (file-name) ":" line "-" end-line "\n")

   ;; Unordered dates:
   (error line-start "Error: " (message) "\n"
          "at " (file-name) ":" line "-" end-line ":\n"  ; at without colon, end-of-line colon
          (zero-or-more line-start (zero-or-more not-newline) "\n"))  ; necessary to also match trailing text ? seems so in this case

   ;; Non-unique account leaf names:
   (error line-start "Error: account leaf names are not unique\n"
          (message (zero-or-more not-newline) "\n")
	  "seen in \"" (zero-or-more (not "\"")) "\" in transaction at: " (file-name) ":" line "-" end-line "\n")
   ;; Parse errors, invalid dates:
   (error line-start "hledger: " (file-name) ":" line ":" column ":\n"
          (message (zero-or-more line-start (zero-or-more not-newline) "\n")) "\n")))

(add-to-list 'flycheck-checkers 'hledger)

(provide 'flycheck-hledger)
;;; flycheck-hledger.el ends here

;;; LocalWords:  flycheck-hledger
