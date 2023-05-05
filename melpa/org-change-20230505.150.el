;;; org-change.el --- Annotate changes in org-mode files -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Stefano Ghirlanda

;; Version: 0.1
;; Package-Version: 20230505.150
;; Package-Commit: 45898a67701ade93f310db8e5820b8bfc4a28846
;; Package-Requires: ((emacs "26.1") (org "9.3"))
;; URL: https://github.com/drghirlanda/org-change
;; Keywords: wp, convenience

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

;; This package provides a minor mode for annotating changes in org-mode
;; files, by defining a new type of link, the change: link.  Using the
;; functions org-change-add, org-change-delete, and
;; org-change-replace, you can mark text as constitution an addiion,
;; deletion, or replacement to the text.  These functions are bound by
;; default to C-` a, C-` d, and C-` r. Functions org-change-accept and
;; org-change-reject can be used to replace the change: link with the
;; new and old text, respectively.  These are bound to C-` o and C-` x.
;;
;; To change key bindings and other settings, run M-x customize-group
;; RET org-change.  When exporting to LaTeX, changes are rendered using
;; the "changes" package.  See the package URL for more documentation.

;;; Code:

(require 'org)
(require 'ox)
(require 'font-lock)

(defvar org-change--deleted-marker "((DELETED))"
  "Placeholder for deleted text.")

(defun org-change--get-region ()
  "Return content of active region or nil."
  (when (use-region-p)
    (buffer-substring-no-properties
     (region-beginning)
     (region-end))))

(defun org-change--mark-change (old-text new-text)
  "Delete region and insert change link with OLD-TEXT and NEW-TEXT."
  (when (use-region-p)
    (delete-region (region-beginning) (region-end)))
  (insert (format "[[change:%s][%s]]" old-text new-text)))

(defun org-change-replace ()
  "Mark active region as old text and prompt new text."
  (interactive "")
  (let ((old-text (org-change--get-region)))
    (if (equal old-text nil)
	(user-error "Select text to be replaced")
      (org-change--mark-change
       old-text
       (read-string "New text: ")))))

(defun org-change-delete ()
  "Mark active region as old text."
  (interactive "")
  (let ((old-text (org-change--get-region)))
    (if (equal old-text nil)
	(user-error "Select text to be deleted")
      (org-change--mark-change old-text org-change--deleted-marker))))

(defun org-change-add ()
  "Mark the active region as new text.
If there is no active region, ask for new text."
  (interactive "")
  (org-change--mark-change
   ""
   (or (org-change--get-region)
       (read-string "New text: "))))

(defun org-change--accept-or-reject (accept)
  "Accept (ACCEPT is t) or reject (ACCEPT is nil) change at point.
If there is no change at point, accept or reject all changes in
the active region."
  (let* ((link-regexp "\\[\\[change:\\(.*?\\)\\]\\[\\(.*?\\)\\]\\]")
	 (link-position (org-in-regexp link-regexp 10)))
    (if link-position
	(let ((old-text (match-string-no-properties 1))
	      ;; to get new-text we discard comments:
	      (new-text (replace-regexp-in-string
			 "\\*\\*.+\\*\\*$" ""
			 (match-string-no-properties 2)))
	      (beg (car link-position))
	      (end (cdr link-position)))
	  (delete-region beg end)
	  (if accept
	      (unless(equal new-text org-change--deleted-marker)
		(insert new-text))
	    (insert old-text)))
      (when (use-region-p)
	(save-excursion
	  (save-restriction
	    (goto-char (region-beginning))
	    (while (re-search-forward link-regexp nil t)
	      (let ((beg (match-beginning 0)))
		(goto-char beg)
		(org-change--accept-or-reject accept)
		;; go to beg because buffer has changed and match-end
		;; is not reliable:
		(goto-char beg)))))))))

(defun org-change-accept ()
  "Accept change at point."
  (interactive "")
  (org-change--accept-or-reject t))

(defun org-change-reject ()
  "Reject change at point."
  (interactive "")
  (org-change--accept-or-reject nil))

;;; Export mechanism

(defun org-change--export-latex (old-text new-text comment)
  "Export a change link to Latex.
OLD-TEXT, NEW-TEXT, and COMMENT are the elements of the change
link."
  (let ((comment (if (equal comment "") "" (format "[comment=%s]" comment))))
    (cond ((equal old-text "")
	   (format "\\added%s{%s}" comment new-text))
	  ((equal new-text org-change--deleted-marker)
	   (format "\\deleted%s{%s}" comment old-text))
	  (t
	   (format "\\replaced%s{%s}{%s}" comment new-text old-text)))))

(defun org-change--make-span (class text)
  "Return string <span class=\"CLASS\">TEXT</span> for HTML export."
    (if (equal text "")
	""
      (format "<span class=\"%s\">%s</span>" class text)))

(defun org-change--export-html (old-text new-text comment)
  "Export a change link to HTML.
OLD-TEXT, NEW-TEXT, and COMMENT are the elemtns of the change
link."
  (cond ((equal old-text "")
	 (org-change--make-span
	  "org-change-added"
	  (concat new-text (org-change--make-span
			    "org-change-comment"
			    comment))))
	((equal new-text org-change--deleted-marker)
	 (org-change--make-span
	  "org-change-deleted"
	  (concat old-text (org-change--make-span
			    "org-change-comment" comment))))
	(t
	 (concat
	  (org-change--make-span
	   "org-change-added"
	   (concat new-text (org-change--make-span
			     "org-change-comment" comment)))
	  (org-change--make-span "org-change-deleted" old-text)))))

(defvar org-change--exporters
  '((latex . org-change--export-latex)
    (html . org-change--export-html))
  "List of exporters known to Org Change.")

(defun org-change-add-export-backend (backend exporter)
  "Add export backend to Org Change.
The EXPORTER function must take arguments old-text, new-text, and
comment, and return a string appropriate to BACKEND."
  (add-to-list 'org-change--exporters (cons backend exporter)))

(defvar org-change-final
  nil
  "If nil, include changes when exporting, otherwise include only new text.")

(defun org-change-export-link (old new backend _)
  "Export a change link to a BACKEND.
This function operates within the standard `org-mode' link export,
but OLD and NEW replace link and description."
  (if (or (not old) (not new))
      (user-error "Malformed change: link with:\nold text = %s\nnew-text: %s" old new))
  (let* ((test (string-match "\\(.*\\)\\*\\*\\(.+\\)\\*\\*$" new))
	 (new-text (if test (match-string 1 new) new))
	 (comment (if test (match-string 2 new) "")))
    (if org-change-final
	(if (equal new-text org-change--deleted-marker) "" new-text)
      (let ((exporter (alist-get
		       backend
		       org-change--exporters
		       nil
		       nil
		       'org-export-derived-backend-p)))
	(if exporter
	    (funcall exporter old new-text comment)
	  (user-error "Change links not supported in %s export" backend))))))
  
(defun org-change-filter-final-output (text backend _)
  "Add the Latex package changes.sty to the Latex preamble.
TEXT is the whole document and BACKEND is checked for being
'latex or derived from 'latex."
  (when (and (org-export-derived-backend-p backend 'latex)
	     (not org-change-final))
    (replace-regexp-in-string
     "\\\\begin{document}"
     (concat
      "\\\\usepackage"
      (when (boundp 'org-change-latex-options) org-change-latex-options)
      "{changes}\n\\\\begin{document}")
     text)))

(add-to-list 'org-export-filter-final-output-functions #'org-change-filter-final-output)

;; Customizations and minor mode definitions

(defgroup org-change nil
  "Customization options for Org Change."
  :group 'org)

(defcustom org-change-add-key (kbd "C-` a")
  "Keybinding for `org-change-add'."
  :type 'key-sequence
  :group 'org-change)

(defcustom org-change-delete-key (kbd "C-` d")
  "Keybinding for `org-change-delete'."
  :type 'key-sequence
  :group 'org-change)

(defcustom org-change-replace-key (kbd "C-` r")
  "Keybinding for `org-change-replace'."
  :type 'key-sequence
  :group 'org-change)

(defcustom org-change-accept-key (kbd "C-` k")
  "Keybinding for `org-change-accept'."
  :type 'key-sequence
  :group 'org-change)

(defcustom org-change-reject-key (kbd "C-` x")
  "Keybinding for `org-change-reject'."
  :type 'key-sequence
  :group 'org-change)

(defface org-change-link-face
  '((t (:background "lavender blush" :underline nil)))
  "Face for Org Change links."
  :group 'org-change)

(defcustom org-change-face 'org-change-link-face
  "Face for Org Change links."
  :type 'face
  :group 'org-change)

(defvar org-change
  "Mode variable and function prefix for org-change")

(defun org-change--fontify ()
  "Fontify change links.
Called automatically when Org Change starts."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "\\[\\[change:[^]]*?\\]\\[[^]]*?\\]\\]" nil t)
      (let ((beg (match-beginning 0))
	    (end (match-end 0)))
	(message "Fontifying change links (%d%%)" (* 100 (/ (float end) (point-max))))
	(font-lock-fontify-region beg end)
	(goto-char end))))
  (message ""))
      
(define-minor-mode org-change-mode
  "Minor mode for annotating changes in `org-mode' files."
  :lighter " Chg"
  :group 'org-change
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map org-change-add-key #'org-change-add)
            (define-key map org-change-delete-key #'org-change-delete)
            (define-key map org-change-replace-key #'org-change-replace)
            (define-key map org-change-accept-key #'org-change-accept)
            (define-key map org-change-reject-key #'org-change-reject)
            map)
  (when org-change
    (org-link-set-parameters
     "change"
     :follow #'org-change-open-link
     :export #'org-change-export-link
     :store #'org-change-store-link
     :face 'org-change-link-face)
    (org-change--fontify)))

(defun org-change-open-link (_path _)
  "Open a change link.  Currently does nothing."
  (message "Opening a change link currently does nothing"))

(defun org-change-store-link ()
  "Store a change link.  Currently does nothing."
  (message "Storing a change link currently does nothing"))

(provide 'org-change)

;;; org-change.el ends here
