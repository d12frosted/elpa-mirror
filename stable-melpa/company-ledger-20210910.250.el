;;; company-ledger.el --- Fuzzy auto-completion for Ledger & friends -*- lexical-binding: t -*-

;; Copyright (C) 2018-2020 Debanjum Singh Solanky

;; Author: Debanjum Singh Solanky <debanjum AT gmail DOT com>
;; Description: Fuzzy auto-completion for ledger & friends
;; Keywords: abbrev, matching, auto-complete, beancount, ledger, company
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.3") (company "0.8.0"))
;; URL: https://github.com/debanjum/company-ledger

;; This file is NOT part of GNU Emacs.

;;; License

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; `company-mode' backend for `ledger-mode', `beancount-mode' and
;; similar plain-text accounting modes. Provides fuzzy completion
;; for transactions, prices and other date prefixed entries.
;; See Readme for detailed setup and usage description.
;;
;; Detailed Description
;; --------------------
;; - Provides auto-completion based on words on current line
;; - The words on the current line can be partial and in any order
;; - The candidate entities are reverse sorted by location in file
;; - Candidates are paragraphs starting with YYYY[-/]MM[-/]DD
;;
;; Minimal Setup
;; -------------
;; (with-eval-after-load 'company
;;   (add-to-list 'company-backends 'company-ledger))
;;
;; Use-Package Setup
;; -----------------
;; (use-package company-ledger
;;   :ensure company
;;   :init
;;   (with-eval-after-load 'company
;;     (add-to-list 'company-backends 'company-ledger)))

;;; Code:

(require 'cl-lib)
(require 'company)

(defconst company-ledger-date-regexp "^[0-9]\\{4\\}[-/][0-9]\\{2\\}[-/][0-9]\\{2\\}"
  "A regular expression to match lines beginning with dates.")

(defconst company-ledger-empty-line-regexp "^[ \t]*$"
  "A regular expression to match empty lines.")

(defun company-ledger--regexp-filter (regexp list)
  "Use REGEXP to filter LIST of strings."
  (let (new)
    (dolist (string list)
      (when (string-match regexp string)
        (setq new (cons string new))))
    new))

(defun company-ledger--get-all-postings ()
  "Get all paragraphs in buffer starting with dates."
  (company-ledger--regexp-filter
   company-ledger-date-regexp
   (mapcar (lambda (s) (substring s 1))
           (split-string (buffer-string) company-ledger-empty-line-regexp t))))

(defun company-ledger--fuzzy-word-match (prefix candidate)
  "Return non-nil if each (partial) word in PREFIX is also in CANDIDATE."
  (eq nil
      (memq nil
            (mapcar
             (lambda (pre) (string-match-p (regexp-quote pre) candidate))
             (split-string prefix)))))

(defun company-ledger--next-line-empty-p ()
  "Return non-nil if next line empty else false."
  (save-excursion
    (beginning-of-line)
    (forward-line 1)
    (or (looking-at company-ledger-empty-line-regexp)
        (eolp)
        (eobp))))

;;;###autoload
(defun company-ledger (command &optional arg &rest ignored)
  "Fuzzy company back-end for ledger, beancount and other ledger-like modes.
Provide completion info based on COMMAND and ARG.  IGNORED, not used."
  (interactive (list 'interactive))
  (pcase command
    (`interactive (company-begin-backend 'company-ledger))

    (`prefix (and (or (eq major-mode 'beancount-mode)
                     (derived-mode-p 'ledger-mode))
                 (company-ledger--next-line-empty-p)
                (thing-at-point 'line t)))

    (`candidates
     (cl-remove-if-not
      (lambda (c) (company-ledger--fuzzy-word-match arg c))
      (company-ledger--get-all-postings)))

    (`sorted t)))

(provide 'company-ledger)
;;; company-ledger.el ends here
