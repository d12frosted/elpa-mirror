;;; mu4e-jump-to-list.el --- mu4e jump-to-list extension  -*- lexical-binding: t -*-

;; Author: Yuri D'Elia <wavexx@thregr.org>
;; Version: 1.0
;; URL: https://gitlab.com/wavexx/mu4e-jump-to-list.el
;; Package-Requires: ((emacs "24.4") (cl-lib "0.5"))
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

;; `mu4e-jump-to-list' allows to select and view mailing lists
;; automatically using existing List-ID headers in your mu database.
;;
;; Just press "l" in the headers view and any mailing list you've
;; subscribed to will be automatically discovered and presented in
;; recency order. No setup or refiling necessary.
;;
;; `mu4e-jump-to-list' integrates with `mu4e-query-fragments' when
;; installed, allowing the use of query fragments in all filter
;; definitions.

;;; Code:

(require 'mu4e)
(require 'cl-lib)

(defgroup mu4e-jump-to-list nil
  "Jump-To-List extension"
  :group 'mu4e)

;;;###autoload
(defcustom mu4e-jump-to-list-kill-regexp nil
  "Remove unwanted listid's from `mu4e-jump-to-list' using regular expressions.
Filter all matching listid's from the completion list using a regular
expression, or a list of regular expressions."
  :type '(choice (const nil) (string) (list string)))

;;;###autoload
(defcustom mu4e-jump-to-list-prefilter "date:1y.."
  "Query filter for listing available listid.
The string should be a valid mu4e query to select messages eligible for
`mu4e-jump-to-list'."
  :type '(choice (const nil) (string)))

;;;###autoload
(defcustom mu4e-jump-to-list-filter "NOT flag:trashed"
  "Query filter used when jumping to a given listid.
The string should be a mu4e query filter to remove unwanted messages
from list views."
  :type '(choice (const nil) (string)))

;;;###autoload
(defcustom mu4e-jump-to-list-min-freq 3
  "Minimal number of messages for a listid to be shown in `mu4e-jump-to-list'."
  :type 'integer)

(defun mu4e-jump-to-list--query-expand (query)
  (if (featurep 'mu4e-query-fragments)
      (mu4e-query-fragments-expand query)
    query))

(defun mu4e-jump-to-list--query ()
  (let* ((query
	  (mu4e-jump-to-list--query-expand
	   (concat "flag:list AND (" mu4e-jump-to-list-prefilter ")")))
	 (quoted
	  ;; quote/retokenize for mu<1.0-alpha0
	  (replace-regexp-in-string "[^-0-9a-zA-Z_.:/@\sC]" "\\\\\\&" query))
	 (filter
	  ;; filter by frequency while preserving recency order
	  (format
	   (concat "| sed -e '/^$/d' | nl | sort -k2 | uniq -c -f1"
		   "| sort -n -k2 | awk '{ if($1 > %d) print $3 }'")
	   mu4e-jump-to-list-min-freq))
	 (command
	  (concat mu4e-mu-binary " find --nocolor -s date -z -f v " quoted filter)))
    (split-string (shell-command-to-string command) "\n" t)))

(defun mu4e-jump-to-list--kill-lists (lists)
  (if (null mu4e-jump-to-list-kill-regexp) lists
    (let ((regexp (if (listp mu4e-jump-to-list-kill-regexp)
		      (mapconcat (lambda (elt) (concat "\\(" elt "\\)"))
				 mu4e-jump-to-list-kill-regexp "\\|")
		    mu4e-jump-to-list-kill-regexp)))
      (cl-remove-if (lambda (elt) (string-match regexp elt))
		    lists))))

(defun mu4e-jump-to-list--nosort-list (collection)
  (lambda (string pred action)
    (if (eq action 'metadata)
        '(metadata (display-sort-function . identity))
      (complete-with-action action collection string pred))))

;; ivy-sort-functions-alist is still apparently necessary
;; https://github.com/abo-abo/swiper/issues/1611
(defvar ivy-sort-functions-alist)

(defun mu4e-jump-to-list--prompt ()
  (let* ((ivy-sort-functions-alist nil)
	 (lists (mu4e-jump-to-list--kill-lists
		 (mu4e-jump-to-list--query)))
	 (wrapped (if (eq mu4e-completing-read-function 'ido-completing-read)
		      ;; ido-completing-read doesn't support the full
		      ;; completing-read interface, but doesn't sort either
		      lists
		     (mu4e-jump-to-list--nosort-list lists))))
    (funcall mu4e-completing-read-function
	     "[mu4e] Jump to list: " wrapped)))

;;;###autoload
(defun mu4e-jump-to-list (&optional listid)
  "Jump interactively to an existing LISTID.
Prompt interactively for a listid to be displayed according to existing
List-ID headers in your mu database. The IDs are displayed in
recency order, with lists having newer messages first.

Lists eligible for selection can be restricted first using
`mu4e-jump-to-list-prefilter' and `mu4e-jump-to-list-kill-regexp'. Only
lists containing at least `mu4e-jump-to-list-min-freq' messages are
displayed. `mu4e-jump-to-list-filter' is finally used to limit messages
when a List-ID has been selected."
  (interactive
   (let ((listid (mu4e-jump-to-list--prompt)))
     (list listid)))
  (when listid
    (let ((search-func (if (fboundp 'mu4e-search) 'mu4e-search 'mu4e-headers-search)))
      (mu4e-mark-handle-when-leaving)
      (funcall search-func
	       (concat (format "list:\"%s\"" listid)
		       " " mu4e-jump-to-list-filter)))))

(if (boundp 'mu4e-search-minor-mode-map)
    (define-key mu4e-search-minor-mode-map (kbd "l") 'mu4e-jump-to-list)
  ;; support mu4e versions older than 1.7
  (define-key mu4e-headers-mode-map (kbd "l") 'mu4e-jump-to-list)
  (define-key mu4e-main-mode-map (kbd "l") 'mu4e-jump-to-list))

(provide 'mu4e-jump-to-list)

;;; mu4e-jump-to-list.el ends here
