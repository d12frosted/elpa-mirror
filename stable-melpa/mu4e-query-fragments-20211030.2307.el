;;; mu4e-query-fragments.el --- mu4e query fragments extension  -*- lexical-binding: t -*-

;; Author: Yuri D'Elia <wavexx@thregr.org>
;; Version: 1.0
;; Package-Version: 20211030.2307
;; Package-Commit: 8d93ede3772353e2dbc307de03e06e37ea6a0b6c
;; URL: https://gitlab.com/wavexx/mu4e-query-fragments.el
;; Package-Requires: ((emacs "24.4"))
;; Keywords: mu4e, mail, convenience

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; `mu4e-query-fragments' allows to define query snippets ("fragments")
;; that can be used in regular `mu4e' searches or bookmarks. Fragments
;; can be used to define complex filters to apply in existing searches,
;; or supplant bookmarks entirely. Fragments compose properly with
;; regular mu4e/xapian operators, and can be arbitrarily nested.
;;
;; `mu4e-query-fragments' can also append a default filter to new
;; queries, using `mu4e-query-fragments-append'. Default filters are
;; very often useful to exclude junk messages from regular queries.
;;
;; To use `mu4e-query-fragments', use the following:
;;
;; (require 'mu4e-query-fragments)
;; (setq mu4e-query-fragments-list
;;   '(("%junk" . "maildir:/Junk OR subject:SPAM")
;;     ("%hidden" . "flag:trashed OR %junk")))
;; (setq mu4e-query-fragments-append "NOT %hidden")
;;
;; The terms %junk and %hidden can subsequently be used anywhere in
;; mu4e. See the documentation of `mu4e-query-fragments-list' for more
;; details.
;;
;; Fragments are *not* shown expanded in order to keep the modeline
;; short. To test an expansion, use `mu4e-query-fragments-expand'.

;;; Code:

(require 'mu4e)

(defgroup mu4e-query-fragments nil
  "Query fragments extension"
  :group 'mu4e)

;;;###autoload
(defcustom mu4e-query-fragments-list nil
  "Define query fragments available in `mu4e' searches and bookmarks.
List of (FRAGMENT . EXPANSION), where FRAGMENT is the string to be
substituted and EXPANSION is the query string to be expanded.

FRAGMENT should be an unique text symbol that doesn't conflict with the
regular mu4e/xapian search syntax or previous fragments. EXPANSION is
expanded as (EXPANSION), composing properly with boolean operators and
can contain fragments in itself.

Example:

\(setq mu4e-query-fragments-list
   '((\"%junk\" . \"maildir:/Junk OR subject:SPAM\")
     (\"%hidden\" . \"flag:trashed OR %junk\")))"
  :type '(alist :key-type (string :tag "Fragment")
		:value-type (string :tag "Expansion")))

;;;###autoload
(defcustom mu4e-query-fragments-append nil
  "Query fragment appended to new searches by `mu4e-query-fragments-search'."
  :type '(choice (const nil) (string)))

(defun mu4e-query-fragments--expand-1 (frags str)
  (if (null frags) str
    (with-syntax-table (standard-syntax-table)
      (let ((case-fold-search nil))
	(replace-regexp-in-string
	 (regexp-opt (mapcar 'car frags) 'symbol)
	 (lambda (it) (cdr (assoc it frags)))
	 str t t)))))

;;;###autoload
(defun mu4e-query-fragments-expand (query)
  "Expand fragments defined in `mu4e-query-fragments-list' in QUERY."
  (interactive "MQuery: ")
  (let (tmp (frags (mapcar (lambda (entry)
			     (cons (car entry) (concat "(" (cdr entry) ")")))
			   mu4e-query-fragments-list)))
    ;; expand recursively until nothing is substituted
    (while (not (string-equal
		 (setq tmp (mu4e-query-fragments--expand-1 frags query))
		 query))
      (setq query tmp)))
  ;; cleanup whitespace and newlines
  (setq query (replace-regexp-in-string "[[:space:]\n]+" " " query))
  ;; show the expansion if interactive
  (when (called-interactively-p 'interactive)
    (message "%s" query))
  query)

(defun mu4e-query-fragments--proc-find-query-expand (args)
  (let ((query (car args))
	(rest (cdr args)))
    (cons (mu4e-query-fragments-expand query) rest)))

;; support mu4e versions older than 1.7
(advice-add (if (fboundp 'mu4e--server-find) 'mu4e--server-find 'mu4e~proc-find)
	    :filter-args 'mu4e-query-fragments--proc-find-query-expand)


(defun mu4e-query-fragments-search (&optional arg)
  "Search for EXPR and switch to the output buffer for the results.
Like `mu4e-headers-search', but appends `mu4e-query-fragments-append' at
the end of the query if called without a prefix argument."
  (interactive "P")
  (if (or (not (null arg)) (null mu4e-query-fragments-append))
      (mu4e-headers-search)
    (let ((expr (read-string "Search for: " nil 'mu4e~headers-search-hist)))
      (mu4e-headers-search (concat expr " " mu4e-query-fragments-append)))))

(if (boundp 'mu4e-search-minor-mode-map)
    (define-key mu4e-search-minor-mode-map (kbd "s") 'mu4e-query-fragments-search)
  ;; support mu4e versions older than 1.7
  (define-key mu4e-headers-mode-map (kbd "s") 'mu4e-query-fragments-search)
  (define-key mu4e-main-mode-map (kbd "s") 'mu4e-query-fragments-search))

(provide 'mu4e-query-fragments)

;;; mu4e-query-fragments.el ends here
