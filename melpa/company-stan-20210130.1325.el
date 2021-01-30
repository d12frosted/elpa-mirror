;;; company-stan.el --- A company-mode completion backend for stan -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Kazuki Yoshida

;; Author: Kazuki Yoshida <kazukiyoshida@mail.harvard.edu>
;; Maintainer: Kazuki Yoshida <kazukiyoshida@mail.harvard.edu>
;; URL: https://github.com/stan-dev/stan-mode/tree/master/company-stan
;; Package-Version: 20210130.1325
;; Package-Commit: 9bb858b9f1314dcf1a5df23e39f9af522098276b
;; Keywords: languages
;; Version: 10.2.1
;; Created: 2019-07-14
;; Package-Requires: ((emacs "24.3") (company "0.9.10") (stan-mode "10.2.1"))

;; This file is not part of GNU Emacs.

;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>

;;; Commentary:

;; company-mode support for `stan-mode'.
;; Completion keywords are obtained from `stan-mode'.
;;
;; Usage
;; The `company-stan-backend' needs to be added to `company-backends'.
;; This can be done globally or buffer locally (use here).
;;
;; A convenience function `company-stan-setup' can be added to the
;; mode-specific hook `stan-mode-hook'.
;; (add-hook 'stan-mode-hook #'company-stan-setup)
;;
;; With the `use-package', the following can be used:
;; (use-package company-stan
;;   :hook (stan-mode . company-stan-setup))
;;
;; If you already have a custom stan-mode setup function, you can add
;; the following to its body.
;; (add-to-list (make-local-variable 'company-backends)
;;              'company-stan-backend)
;;
;; References
;; Writing backends for the company-mode.
;;  https://github.com/company-mode/company-mode/wiki/Writing-backends
;;  http://sixty-north.com/blog/series/how-to-write-company-mode-backends.html
;; Definitions
;;  https://github.com/company-mode/company-mode/blob/master/company.el
;; Example in company-math.el
;;  https://github.com/vspinu/company-math/blob/master/company-math.el#L210


;;; Code:
(require 'company)
(require 'company-dabbrev-code)
(require 'stan-mode)
(require 'stan-keywords)


;;; User configuration options
;; https://www.gnu.org/software/emacs/manual/html_node/eintr/defcustom.html
(defgroup company-stan nil
  "Completion backend for stan code."
  :group 'company-stan)

(defcustom company-stan-fuzzy nil
  "Whether to use fuzzy matching in `company-stan'."
  :type 'boolean
  :group 'company-stan)


;;; Keyword list construction
(defun company-stan--propertize-list (lst category)
  "Propertize each element of a string list.

LST is the list of strings.
CATEGORY is a string assigned to property `:category'."
  (mapcar (lambda (s)
            (propertize s :category category))
          lst))

;; Construct a completion keyword list.
(defvar company-stan-keyword-list
  (append (company-stan--propertize-list
           stan-keywords--types-list "type")
          (company-stan--propertize-list
           stan-keywords--function-return-types-list "function return type")
          (company-stan--propertize-list
           stan-keywords--blocks-list "block")
          (company-stan--propertize-list
           stan-keywords--range-constraints-list "range constraint")
          (company-stan--propertize-list
           stan-keywords--keywords-list "keyword")
          (company-stan--propertize-list
           stan-keywords--functions-list "function")
          (company-stan--propertize-list
           stan-keywords--distribution-list "distribution")
          (company-stan--propertize-list
           stan-keywords--reserved-list "reserved"))
  "Completion keyword list for `stan-mode'.

The following lists defined in
 `stan-mode/stan-keywords.el'
are used with respective type property meta data.

 `stan-keywords--types-list'
 `stan-keywords--function-return-types-list'
 `stan-keywords--blocks-list'
 `stan-keywords--range-constraints-list'
 `stan-keywords--keywords-list'
 `stan-keywords--functions-list'
 `stan-keywords--distribution-list'
 `stan-keywords--reserved-list'

Note that `stan-deprecated-function-list' is not used.")


;;; Backend definition
;; http://sixty-north.com/blog/a-more-full-featured-company-mode-backend.html
(defun company-stan--fuzzy-match (prefix candidate)
  "Fuzzy matching function for `company-stan'.

PREFIX is the string entered.
CANDIDATE is the completion candidate to be compared."
  (cl-subsetp (string-to-list prefix)
              (string-to-list candidate)))

(defun company-stan--which-block ()
  "Detect which stan block point is in.

Returns block name in a string.
Returns nil if it is not in a stan block."
  (when (eq major-mode 'stan-mode)
    (c-guess-basic-syntax))
  nil)

(defun company-stan-backend-annotation (s)
  "Construct an annotation string from the :category property.

S is the string from which the property is extracted."
  (format " [%s]" (get-text-property 0 :category s)))

(defun company-stan-backend (command &optional arg &rest ignored)
  ;; The signature (command &optional arg &rest ignored) is mandated.
  "A company backend function for Stan.

COMMAND is either one of symbol `interactive',
symbol `prefix', symbol `candidates', and symbol
`annotation'.
ARG is the prefix string to be completed when called
with symbol `candidates'.  ARG is the string to extract
the property from when called with symbol `annotation'.

IGNORED is a placeholder to be ignored.

This backend only comes up with predefined keywords.
Group with other backends as necessary.
See the help for `company-backends'."
  ;;
  ;; Making it interactive allows interactive testing.
  (interactive (list 'interactive))
  ;; (cl-case EXPR (KEYLIST BODY...)...)
  ;; Eval EXPR and choose among clauses on that value.
  ;; Here we decide what to do based on COMMAND.
  ;; One of {interactive, prefix, candidates, annotation}
  (cl-case command
    ;; 1. interactive call
    ;; (company-begin-backend BACKEND &optional CALLBACK)
    ;; Start a completion at point using BACKEND.
    (interactive (company-begin-backend 'company-stan-backend))
    ;; 2. prefix command
    ;;  It should return the text that is to be completed.
    ;;  If it returns nil, this backend is not used.
    ;;  Here we need to verify the major mode.
    (prefix (and (eq major-mode 'stan-mode)
                 ;; Ensure not inside a comment.
                 ;; Parse-Partial-Sexp State at POS, defaulting to point.
                 ;; https://emacs.stackexchange.com/questions/14269/how-to-detect-if-the-point-is-within-a-comment-area
                 (not (nth 4 (syntax-ppss)))
                 ;; If point is at the end of a symbol, return it for completion.
                 ;; Otherwise, if point is not inside a symbol, return an empty string.
                 ;; This will give the prefix to be completed.
                 (company-grab-symbol)))
    ;; 3. candidates command
    ;;  This is where we actually generate a list of possible completions.
    ;;  When this is called arg holds the prefix string to be completed
    (candidates
     (cl-remove-if-not
      ;; Retain if matching
      (lambda (c)
        (if company-stan-fuzzy
            (company-stan--fuzzy-match arg c)
          (string-prefix-p arg c)))
      ;; from a long list of all stan object names.
      company-stan-keyword-list))
    ;; 4. annotation command
    (annotation (company-stan-backend-annotation arg))))


;;;###autoload
(defun company-stan-setup ()
  "Set up `company-stan-backend'.

Add `company-stan-backend' to `company-backends' buffer locally.

It is grouped with `company-dabbrev-code' because `company-stan-backend'
only performs completion based on predefined keywords in
`company-stan-keyword-list'.  See the help for `company-backends' for
details regarding grouped backends.

Add this function to the `stan-mode-hook'."
  ;;
  (add-to-list (make-local-variable 'company-backends)
               ;; Grouped
               '(company-stan-backend
                 company-dabbrev-code)))


(provide 'company-stan)

;;; company-stan.el ends here
