;;; inspire.el --- an interface for inspirehep.net  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Simon Lin

;; Author: Simon Lin <n.sibetz@gmail.com>
;; URL: https://github.com/Simon-Lin/inspire.el
;; Package-Version: 20230514.1030
;; Package-Commit: 825bbd4e19046b0e61aa27a0f88b1daeaaebf1d0
;; Version: 0.0.1
;; Keywords: extensions, tex
;; Package-Requires: ((emacs "27.1"))
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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; inspire.el is an Emacs interface for literature and references searching
;; on the high energy article database inspirehep.net.

;; Common usage
;; ============

;; inspire.el provides two main entry functions for searching on inspirehep:
;; `inspire-literature-search` for literature lookup,
;; and `inspire-author-search` for author lookup.
;; inspire.el will then pop-up a list of records where one can browse and examine
;; detailed information for each record.
;; The SPIRES syntax (https://help.inspirehep.net/knowledge-base/inspire-paper-search)
;; is available for `inspire-literature-search` function.

;; In the record list, use `n` and `p` to navigate through the list.
;; Other useful commands and their default bindings:
;; `u` `inspire-open-url` : open the web page associated to the item
;; `d` `inspire-download-pdf` : download PDF from a selected source
;; `b` `inspire-export-bibtex-new-buffer` : export the bibTeX entry to a temporary buffer
;; `B` `inspire-export-bibtex-to-file` : export the bibtex entry to a .bib file
;; `e` `inspire-download-pdf-export-bibtex` : download PDF and export bibTeX info to a file
;; `a` `inspire-record-author-lookup` : look up for a author profile in current record
;; `r` `inspire-reference-search` : look up for references of the current record
;; `c` `inspire-citation-search` : look up for citations of the current record
;; `[` `inspire-previous-search`
;; `]` `inspire-next-search` : navigate through the search history
;; `q` `inspire-exit` : exit the record list

;; Some texts in the record or author information buffer are clickable and will preform
;; corresponding action when clicked upon.

;;; Code:

(require 'seq)
(require 'map)
(require 'json)
(require 'bibtex)
(require 'url-handlers)


;;; customization group

(defgroup inspire nil
  "Emacs interface for inspirehep.net."
  :prefix "inspire-"
  :group 'applications)

(defgroup inspire-fontification nil
  "Faces for the inspire mode."
  :group 'inspire)

(defgroup inspire-preferences nil
  "General preferences for the arxiv mode."
  :group 'inspire)

(defcustom inspire-use-variable-pitch t
  "Whether to use variable pitch fonts in `inspire-mode' buffers."
  :group 'inspire-preferences
  :type 'boolean)

(defcustom inspire-query-size 25
  "Number of entries per page when fetching from inspirehep API."
  :group 'inspire-preferences
  :type 'integer)

(defcustom inspire-pop-up-new-frame t
  "Whether inspire mode will try to create a new frame for searching results."
  :group 'inspire-preferences
  :type 'boolean)

(defcustom inspire-frame-alist '((name . "*inspirehep*") (width . 240) (height . 80))
  "The alist containing the property of inspire pop-up frame."
  :group 'inspire-preferences
  :type 'sexp)

(defcustom inspire-default-download-folder "~/Downloads/"
  "Default download folder to save PDF file."
  :group 'inspire-preferences
  :type 'string)

(defcustom inspire-master-bibliography-file "~/master.bib"
  "Default bibliography file `inspire-export-bibtex' exports to."
  :group 'inspire-preferences
  :type 'string)

(defcustom inspire-pdf-use-absolute-path nil
  "Whether to use relative path name when exporting bibtex entries."
  :group 'inspire-preferences
  :type 'boolean)

(defcustom inspire-pdf-open-function #'find-file-other-window
  "Default function to open PDF file downloaded."
  :group 'inspire-preferences
  :type 'function)

;; faces

(defvar inspire-title-face 'inspire-title-face)
(defface inspire-title-face
  '((t (:inherit font-lock-keyword-face :weight semi-bold)))
  "Face name for article titles in the inspire article list."
  :group 'inspire-fontification)

(defvar inspire-keyword-face 'inspire-keyword-face)
(defface inspire-keyword-face
  '((t (:inherit font-lock-constant-face)))
  "Face name for keywords in the inspire article list."
  :group 'inspire-fontification)

(defvar inspire-link-face 'inspire-link-face)
(defface inspire-link-face
  '((t (:inherit button)))
  "Face name for keywords in the inspire article list."
  :group 'inspire-fontification)

(defvar inspire-author-face 'inspire-author-face)
(defface inspire-author-face
  '((t (:inherit font-lock-type-face)))
  "Face name for authors in the inspire article list."
  :group 'inspire-fontification)

(defvar inspire-date-face 'inspire-date-face)
(defface inspire-date-face
  '((t (:inherit shadow)))
  "Face name for date in the inspire article list."
  :group 'inspire-fontification)

(defvar inspire-abstract-face 'inspire-abstract-face)
(defface inspire-abstract-face
  '((t (:inherit font-lock-string-face)))
  "Face name for abstract in the inspire abstract viewing window."
  :group 'inspire-fontification)

(defvar inspire-subfield-face 'inspire-subfield-face)
(defface inspire-subfield-face
  '((t (:inherit default)))
  "Face name for subfields (comments, subjects, etc.) in the inspire abstract viewing window."
  :group 'inspire-fontification)

(defvar inspire-abstract-math-face 'inspire-abstract-math-face)
(defface inspire-abstract-math-face
  '((t (:inherit font-lock-reference-face :family "Monospace")))
  "Face name for the latex content in abstract in the inspire abstract viewing window."
  :group 'inspire-fontification)

(defvar inspire-author-heading-face 'inspire-author-heading-face)
(defface inspire-author-heading-face
  '((t (:inherit default :weight semi-bold)))
  "Face name for the author names when searching and displaying author pages."
  :group 'inspire-fontification)

(defvar inspire-author-institute-face 'inspire-author-institute-face)
(defface inspire-author-institute-face
  '((t (:inherit font-lock-variable-name-face)))
  "Face name for the institutes when searching and displaying author pages."
  :group 'inspire-fontification)

(defvar inspire-arxiv-category-face 'inspire-arxiv-category-face)
(defface inspire-arxiv-category-face
  '((t (:inherit font-lock-constant-face)))
  "Face name for arxiv categories in the inspire window."
  :group 'inspire-fontification)


;;; variables

(defconst inspire-api-url "https://inspirehep.net/api/"
  "The url address for inspirehep API.")

(defvar inspire-query-string nil
  "The string used for inspire literature search.")

(defvar inspire-query-history nil
  "A list storing the past history of inspire searches.")

(defvar inspire-history-index 0
  "Index of currently displayed entry in `inspire-query-history'.")

(defvar inspire-query-total-hits nil
  "Total number of matching search results for inspire literature search.")

(defvar inspire-entry-list nil
  "Entry list of inspire literature.")

(defvar inspire-current-entry 0
  "Index of currently displayed record in `inspire-entry-list'.")

(defvar inspire-author-data nil
  "A alist containing the current inspire author information.")

(defvar inspire-highlight-overlay nil
  "Overlay for displaying the selected record in inspire record list.")

(defvar inspire-frame nil
  "Current frame used for displaying `inspire-mode' buffers.")

(defvar inspire-search-buffer nil
  "Current buffer for displaying inspire search results.")

(defvar inspire-search-window nil
  "Current window for displaying inspire search results.")

(defvar inspire-record-buffer nil
  "Current buffer for displaying inspire record information.")

(defvar inspire-record-window nil
  "Current window for displaying inspire record information.")

(defvar inspire-author-buffer nil
  "Current buffer for displaying inspire author information.")

(defvar inspire-author-window nil
  "Current window for displaying inspire author information.")


;;; mode definition

(defvar inspire-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "p") #'inspire-prev-entry)
    (define-key map (kbd "n") #'inspire-next-entry)
    (define-key map (kbd "RET") #'("Switch to record window."
				  . (lambda () (interactive) (select-window inspire-record-window))))
    (define-key map (kbd "u") #'inspire-open-url)
    (define-key map (kbd "SPC") #'inspire-select-entry)
    (define-key map (kbd "q") #'inspire-exit)
    (define-key map (kbd "d") #'inspire-download-pdf)
    (define-key map (kbd "B") #'inspire-export-bibtex-to-file)
    (define-key map (kbd "e") #'inspire-download-pdf-export-bibtex)
    (define-key map (kbd "b") #'inspire-export-bibtex-new-buffer)
    (define-key map (kbd "a") #'inspire-record-author-lookup)
    (define-key map (kbd "r") #'inspire-reference-search)
    (define-key map (kbd "c") #'inspire-citation-search)
    (define-key map (kbd "[") #'inspire-previous-search)
    (define-key map (kbd "]") #'inspire-next-search)
    map))

(defvar inspire-record-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'inspire-open-url)
    (define-key map (kbd "u") #'inspire-open-url)
    (define-key map (kbd "q") #'inspire-exit)
    (define-key map (kbd "d") #'inspire-download-pdf)
    (define-key map (kbd "B") #'inspire-export-bibtex-to-file)
    (define-key map (kbd "e") #'inspire-download-pdf-export-bibtex)
    (define-key map (kbd "b") #'inspire-export-bibtex-new-buffer)
    (define-key map (kbd "a") #'inspire-record-author-lookup)
    (define-key map (kbd "r") #'inspire-reference-search)
    (define-key map (kbd "c") #'inspire-citation-search)
    (define-key map (kbd "[") #'inspire-previous-search)
    (define-key map (kbd "]") #'inspire-next-search)
    map))

(defvar inspire-author-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'inspire-open-url)
    (define-key map (kbd "u") #'inspire-open-url)
    (define-key map (kbd "q") #'inspire-exit)
    (define-key map (kbd "[") #'inspire-previous-search)
    (define-key map (kbd "]") #'inspire-next-search)
    map))

(define-derived-mode inspire-mode special-mode "inspire"
  :group 'inspire
  :interactive nil
  (setq header-line-format '(:eval (inspire--headerline-format)))
  (setq inspire-highlight-overlay (make-overlay 1 1))
  (overlay-put inspire-highlight-overlay 'face '(:inherit highlight :extend t))
  (setq inspire-current-entry 0)
  (if inspire-use-variable-pitch
      (variable-pitch-mode 1)
    (variable-pitch-mode -1)))

(define-derived-mode inspire-record-mode special-mode "inspire-record"
  :group 'inspire
  :interactive nil
  (if inspire-use-variable-pitch
      (variable-pitch-mode 1)
    (variable-pitch-mode -1)))

(define-derived-mode inspire-author-mode special-mode "inspire-author"
  :group 'inspire
  :interactive nil
  (if inspire-use-variable-pitch
      (variable-pitch-mode 1)
    (variable-pitch-mode -1)))

(defun inspire--headerline-format ()
  "Update the header line of *inspire-search* buffer."
  (let* ((entry (format "%d/%d" (+ 1 inspire-current-entry) inspire-query-total-hits))
	 (info-width (- (window-total-width) (length entry) 2)))
    (list
     (list (- info-width)
	   (format " search results for \"%s\":" inspire-query-string)
	   (propertize " " 'display `(space :align-to ,info-width))
	   entry))))


;;; functions

;; entry functions

;;;###autoload
(defun inspire-literature-search (query-string)
  "Search for literature on inspirehep.net with QUERY-STRING.
List the results in a new buffer."
  (interactive "sSearch for literature on inspirehep: ")
  (if (string-match "^ *$" query-string)
      (message "Search condition cannot be blank.")
    (message "Fetching search results for literature/q=%s on inspirehep..." query-string)
    (if-let ((entry-temp (inspire-parse-literature
			   (format "%sliterature?sort=mostrecent&size=%s&q=%s"
				   inspire-api-url
				   inspire-query-size
				   query-string))))
	(progn
	  (setq inspire-entry-list entry-temp)
	  (setq inspire-query-string query-string)
	  (setq inspire-author-data nil)
	  (inspire--push-to-history)
	  (inspire--setup-windows)
	  (inspire-populate-page)
	  (inspire-populate-record)
	  (message "Found %s results." inspire-query-total-hits))
      (message "No matching search result."))))

;;;###autoload
(defun inspire-author-search (query-string)
  "Search for a particular author on inspirehep.net with QUERY-STRING.
List the author details and their publication in a new buffer."
  (interactive "sSearch for author on inspirehep: ")
  (if (string-match "^ *$" query-string)
      (message "Search condition cannot be blank.")
    (message "Fetching search results for author/q=%s on inspirehep..." query-string)
    (let* ((authors (inspire-parse-author (concat inspire-api-url "authors?sort=bestmatch&size=" (format "%s" inspire-query-size) "&q=" query-string)))
	   (candidates (seq-map #'inspire--author-format-completion-string authors))
	   (selected))
      (setq selected
	    (completing-read (format "Authors search result for \"%s\": " query-string)
			     (lambda (input pred action) ; custom table for ordering
			       (if (eq action 'metadata)
				   `(metadata . ((display-sort-function . ,#'identity)))
				 (complete-with-action action candidates input pred)))
			     nil t))
      (string-match "\t\\([\.A-Za-z0-9]+\\)$" selected)
      (setq inspire-author-data (seq-find
				 (lambda (x) (string-equal
					 (match-string-no-properties 1 selected)
					 (alist-get 'inspire-bai x)))
				 authors))
      (inspire--setup-windows)
      (inspire-populate-author-data)
      (redisplay)
      
      ;; search and display authored literature
      (message "Looking up literature authored by %s..." (alist-get 'name inspire-author-data))
      (setq inspire-query-string (format "a= %s" (alist-get 'inspire-bai inspire-author-data)))
      (setq inspire-entry-list
	    (inspire-parse-literature
	     (format "%sliterature?sort=mostrecent&size=%s&q=%s" inspire-api-url inspire-query-size inspire-query-string)))
      (inspire--push-to-history)
      (inspire-populate-page)
      (inspire-populate-record)
      (message "Found %s results." inspire-query-total-hits))))

;;;###autoload
(defun inspire-author-record (author-id)
  "Show the record of a particular author on inspirehep.
AUTHOR-ID has to be a 6 or 7-digit number which is the control number
 associated to the author. This function does not work with other
 ids, such as inspire BAI or ORCID."
  (interactive "sLook up author record on inspirehep (7-digit control number): ")
  (message "Fetching record author/%s on inspirehep..." author-id)
  (setq inspire-author-data (inspire-parse-author (format "%sauthors/%s" inspire-api-url author-id)))
  (inspire--setup-windows)
  (inspire-populate-author-data)
  (redisplay)
  
  ;; search and display authored literature
  (message "Looking up literature authored by %s..." (alist-get 'name inspire-author-data))
  (setq inspire-query-string (format "a= %s" (alist-get 'inspire-bai inspire-author-data)))
  (setq inspire-entry-list
	(inspire-parse-literature
	 (format "%sliterature?sort=mostrecent&size=%s&q=%s" inspire-api-url inspire-query-size inspire-query-string)))
  (inspire--push-to-history)
  (inspire-populate-page)
  (inspire-populate-record)
  (message "Found %s results." inspire-query-total-hits))

(defun inspire--author-format-completion-string (author-alist)
  "Format the entry for `completing-read' from AUTHOR-ALIST."
  (let ((name (alist-get 'name author-alist))
	(native (alist-get 'native-names author-alist))
	(key (alist-get 'inspire-bai author-alist))
	(pos (alist-get 'current-position author-alist))
	(cat (alist-get 'arxiv-categories author-alist)))
    (when native (setq name (format "%s (%s)" name native)))
    (setq name (propertize name 'face 'inspire-author-heading-face))
    (setq key  (propertize key 'face 'shadow))
    (setq pos (if pos
		  (propertize (format "(%s)" pos) 'face 'inspire-author-institute-face)
		""))
    (setq cat (if cat
		  (propertize cat 'face 'inspire-arxiv-category-face)
		""))
    (concat "  "
	    (truncate-string-to-width name 30 nil ?\s) "\t"
	    (truncate-string-to-width pos  70 nil ?\s) "\t"
	    (truncate-string-to-width cat  40 nil ?\s) "\t"
	    key)))

(defun inspire--setup-windows ()
  "Setup window and buffer configuration for `inspire-mode'."
  (when inspire-pop-up-new-frame
    (unless (frame-live-p inspire-frame)
      (setq inspire-frame
	    (make-frame inspire-frame-alist)))
    (select-frame inspire-frame))

  (unless (buffer-live-p inspire-record-buffer)
    (setq inspire-record-buffer (get-buffer-create "*inspire-record*"))
    (with-current-buffer inspire-record-buffer (inspire-record-mode)))
  (if (window-live-p inspire-record-window)
      (set-window-buffer inspire-record-window inspire-record-buffer)
    (setq inspire-record-window (display-buffer inspire-record-buffer t)))

  (unless (buffer-live-p inspire-search-buffer)
    (setq inspire-search-buffer (get-buffer-create "*inspire-search*"))
    (with-current-buffer inspire-search-buffer (inspire-mode)))
  (when (window-live-p inspire-search-window) (select-window inspire-search-window))
  
  (if inspire-author-data
      (progn
	(unless (buffer-live-p inspire-author-buffer)
	  (setq inspire-author-buffer (get-buffer-create "*inspire-author*"))
	  (with-current-buffer inspire-author-buffer (inspire-author-mode)))
	(unless (window-live-p inspire-author-window)
	  (setq inspire-author-window (get-buffer-window)))
	(set-window-dedicated-p inspire-author-window nil)
	(set-window-buffer inspire-author-window inspire-author-buffer)
	(when (or (not (window-live-p inspire-search-window)) (eq inspire-author-window inspire-search-window))
	  (setq inspire-search-window (split-window-vertically (round (* .5 (frame-height)))))))
    (when (window-live-p inspire-author-window)
      (quit-restore-window inspire-author-window))
    (unless (window-live-p inspire-search-window)
      (setq inspire-search-window (get-buffer-window))))

  (set-window-dedicated-p inspire-search-window nil)
  (set-window-buffer inspire-search-window inspire-search-buffer)
  
  (set-window-dedicated-p inspire-search-window t)
  (set-window-dedicated-p inspire-record-window t)
  (when (window-live-p inspire-author-window)
    (set-window-dedicated-p inspire-author-window t))
  
  (select-window inspire-search-window))


;; interactive functions

(defun inspire-next-entry (&optional arg)
  "Move to the next literature entry.
With ARG, move to the next nth entry."
  (interactive "p")
  (setq inspire-current-entry (+ inspire-current-entry arg))
  (let ((len (safe-length inspire-entry-list)))
    (when (> inspire-current-entry (1- len))
      (when (< len inspire-query-total-hits)
	(inspire-show-next-page)
	(setq len (safe-length inspire-entry-list)))
      (when (>= inspire-current-entry len)
	(setq inspire-current-entry (1- len))
	(message "end of search results")))
    (goto-char (point-min))
    (forward-line (* 4 inspire-current-entry))
    (move-overlay inspire-highlight-overlay
		  (point) (progn (beginning-of-line 5) (point)))
    (forward-line (- 4))
    (inspire-populate-record)
    (when (= inspire-current-entry (1- len)) ; pre-render next page when the last result is selected
      (redisplay t)
      (when (< len inspire-query-total-hits)
	(inspire-show-next-page)))))

(defun inspire-prev-entry (&optional arg)
  "Move to the previous literature entry.
With ARG, move to the previous nth entry."
  (interactive "p")
  (setq inspire-current-entry (- inspire-current-entry arg))
  (when (< inspire-current-entry 0)
    (setq inspire-current-entry 0)
    (message "beginning of search results"))
  (goto-char (point-min))
  (forward-line (* 4 inspire-current-entry))
  (move-overlay inspire-highlight-overlay
		(point) (progn (beginning-of-line 5) (point)))
  (forward-line (- 4))
  (inspire-populate-record))

(defun inspire-select-entry ()
  "Select the entry to which the cursor is pointing to."
  (interactive)
  (setq inspire-current-entry (/ (line-number-at-pos) 4))
  (goto-char (point-min))
  (forward-line (* 4 inspire-current-entry))
  (move-overlay inspire-highlight-overlay
		(point) (progn (beginning-of-line 5) (point)))
  (forward-line (- 4))
  (when (window-live-p inspire-record-window)
    (inspire-populate-record)))

(defun inspire-show-next-page ()
  "Perform one more query and fill the results into buffer.
\(according to `inspire-current-entry' and `inspire-entries-per-fetch')"
  (interactive)
  (let* ((page   (/ (1+ inspire-current-entry) inspire-query-size))
	 (lbound (1+ (* inspire-query-size page)))
	 (ubound (min (* inspire-query-size (1+ page)) inspire-query-total-hits)))
    (message "Fetching results %d-%d..." lbound ubound)
    (setq inspire-entry-list
	  (append inspire-entry-list
		  (inspire-parse-literature
		   (format "%sliterature?sort=mostrecent&size=%s&page=%s&q=%s"
			   inspire-api-url
			   inspire-query-size
			   (1+ page)
			   inspire-query-string))))
    (save-excursion
      (goto-char (point-max))
      (let ((buffer-read-only nil))
	(inspire--fill-page (1- lbound))))))

(defun inspire-open-url (&optional field)
  "Open the corresponding inspire web page according to FIELD.
FIELD can either be `author' or `record'.
If left nil, determine FIELD depending on the current window."
  (interactive)
  (unless field
    (let ((wind (selected-window)))
      (cond
       ((eq wind inspire-author-window)
	(setq field 'author))
       ((eq wind inspire-search-window)
	(setq field 'record))
       ((eq wind inspire-record-window)
	(setq field 'record)))))
  (pcase field
    ('author
     (browse-url (format "https://inspirehep.net/authors/%s" (alist-get 'control-number inspire-author-data))))
    ('record
     (browse-url (format "https://inspirehep.net/literature/%s" (alist-get 'inspire-id (nth inspire-current-entry inspire-entry-list)))))))

(defun inspire-reference-search (&optional confirm)
  "Look up all articles that the current record references.
If CONFIRM is nil, ask user for confirmation."
  (interactive)
  (let* ((entry (nth inspire-current-entry inspire-entry-list))
	 (id (alist-get 'inspire-id entry)))
    (when (or confirm (y-or-n-p "Look up articles this item refers to? "))
      (inspire-literature-search (format "citedby:recid:%s" id)))))

(defun inspire-citation-search (&optional confirm)
  "Look up all articles that cited the current record.
If CONFIRM is nil, ask user for confirmation."
  (interactive)
    (let* ((entry (nth inspire-current-entry inspire-entry-list))
	   (id (alist-get 'inspire-id entry)))
      (when (or confirm (y-or-n-p "Look up articles citing this item? "))
	(inspire-literature-search (format "refersto:recid:%s" id)))))

(defun inspire-record-author-lookup ()
  "Look up the profile of one of the author of the current record."
  (interactive)
  (let* ((entry (nth inspire-current-entry inspire-entry-list))
	 (authors_ (alist-get 'authors entry))
	 (select (completing-read "Look up author profile: "
				  (seq-map (lambda (x) (alist-get 'name x)) authors_)
				  nil t)))
    (if-let ((recid
	      (alist-get 'recid (seq-find (lambda (x) (equal select (alist-get 'name x))) authors_))))
	(inspire-author-record recid)
      (message "%s has no available record on inspirehep." select))))

(defun inspire-get-bibtex ()
  "Return bibtex information for the current entry."
  (interactive)
  (if-let ((url (alist-get 'bib-link (nth inspire-current-entry inspire-entry-list))))
      (with-temp-buffer
	(message "Retrieving bibTeX information from inspirehep...")
	(url-insert (url-retrieve-synchronously url t))
	(buffer-string))
    (message "No bibTeX information for this item.")
    nil))

(defun inspire-export-bibtex-to-file (&optional pdf-path)
  "Export bibtex information for current entry and append to a file.
The default location is set by `inspire-master-bibtex-file'.
With optional argument PDF-PATH, add a link to the local document location."
  (interactive)
  (let ((bib-file (read-file-name "export to bibliography file: "
				     (expand-file-name inspire-master-bibliography-file) nil 'confirm)))
    (with-temp-file bib-file
      (insert-file-contents bib-file)
      (goto-char (point-max))
      (when (not (looking-at "^")) (insert "\n"))
      (insert (inspire-get-bibtex))
      (when pdf-path
	(if inspire-pdf-use-absolute-path
	    (setq pdf-path (expand-file-name pdf-path))
	  (setq pdf-path (file-relative-name pdf-path (file-name-directory bib-file))))
	(backward-char 3)
	(insert (format ",\n    file = {:%s:pdf}" pdf-path))))
    (message "bibTeX entry written to %s." bib-file)))

(defun inspire-export-bibtex-new-buffer ()
  "Get bibtex information for current entry and display it in a temporary buffer."
  (interactive)
  (select-window inspire-record-window)
  (pop-to-buffer "*inspire-bibTeX*" '(display-buffer-below-selected))
  (insert (inspire-get-bibtex))
  (bibtex-mode)
  (bibtex-set-dialect 'BibTeX t))

(defun inspire-download-pdf (&optional pdf-path ask-if-open)
  "Download and save the PDF of the selected record to PDF-PATH.
If ASK-IF-OPEN is non-nil, ask the user whether to open the file in addition.
Return the path of downloaded PDF."
  (interactive)
  (if-let ((docs (alist-get 'files (nth inspire-current-entry inspire-entry-list))))
      (progn
	(let* ((selected) (url) (newfile))
	  (setq selected (completing-read "Download from source: "
					  (seq-map (lambda (x) (alist-get 'description x)) docs)
					  nil t))
	  (setq selected (seq-find (lambda (x) (equal (alist-get 'description x) selected)) docs))
	  (setq url (alist-get 'url selected))
	  (string-match "/\\([^/]+\\)$" url)
	  (setq newfile (match-string 1 url))
	  (unless pdf-path
	    (setq pdf-path (read-file-name "Save pdf as: "
					   inspire-default-download-folder
					   nil nil (concat newfile ".pdf"))))
	  (ignore-error 'file-already-exists
	    (setq newfile (url-copy-file url pdf-path 1)))
	  (if ask-if-open
	      (when (yes-or-no-p (format "%s saved. Open file? " pdf-path))
		(funcall inspire-pdf-open-function newfile))
	    (message "%s saved." pdf-path)
	    pdf-path)))
    (message "No available files for download.")))

(defun inspire-download-pdf-export-bibtex ()
  "Download the PDF and export the bibTeX for the current record."
  (interactive)
  (funcall #'inspire-export-bibtex-to-file (inspire-download-pdf)))

(defun inspire-exit ()
  "Quit `inspire-mode' and kill all related buffers."
  (interactive)
  (when (window-live-p inspire-author-window)
    (quit-restore-window inspire-author-window 'kill)
    (setq inspire-author-window nil))
  (when (window-live-p inspire-record-window)
    (quit-restore-window inspire-record-window 'kill)
    (setq inspire-record-window nil))
  (quit-restore-window inspire-search-window 'kill)
  (when inspire-record-buffer (kill-buffer inspire-record-buffer))
  (when inspire-author-buffer (kill-buffer inspire-author-buffer))
  (setq inspire-record-buffer nil
	inspire-author-buffer nil
	inspire-search-window nil
	inspire-frame nil)
  (setq inspire-author-data nil
	inspire-entry-list nil
	inspire-current-entry 0
	inspire-history-index 0
	inspire-query-history nil
	inspire-query-string nil
	inspire-query-total-hits nil))

(defun inspire-previous-search ()
  "Show the previous search results in history."
  (interactive)
  (if (>= (1+ inspire-history-index) (safe-length inspire-query-history) )
      (message "Beginning of search history.")
    (message "Previous search result")
    (setq inspire-history-index (1+ inspire-history-index))
    (inspire--load-from-history inspire-history-index)
    (inspire--setup-windows)
    (setq inspire-current-entry 0)
    (when inspire-author-data
      (inspire-populate-author-data))
    (inspire-populate-page)
    (inspire-populate-record)))

(defun inspire-next-search ()
  "Show the next search results in history."
  (interactive)
  (if (= 0 inspire-history-index)
      (message "End of search history.")
    (message "Next search result")
    (setq inspire-history-index (1- inspire-history-index))
    (inspire--load-from-history inspire-history-index)
    (inspire--setup-windows)
    (setq inspire-current-entry 0)
    (when inspire-author-data
      (inspire-populate-author-data))
    (inspire-populate-page)
    (inspire-populate-record)))

(defun inspire--push-to-history ()
  "Push current search results to `inspire-query-history'."
  (setq inspire-query-history (seq-drop inspire-query-history inspire-history-index))
  (push `((author-data . ,inspire-author-data)
	  (entry-list . ,inspire-entry-list)
	  (query-string . ,inspire-query-string)
	  (query-total-hits . ,inspire-query-total-hits))
	inspire-query-history)
  (setq inspire-history-index 0))

(defun inspire--load-from-history (index)
  "Set the search variables from `inspire-query-history'.
Which result to load is specified by INDEX."
  (let ((hist (nth index inspire-query-history)))
    (setq inspire-author-data  (alist-get 'author-data hist)
	  inspire-entry-list   (alist-get 'entry-list hist)
	  inspire-query-string (alist-get 'query-string hist)
	  inspire-query-total-hits (alist-get 'query-total-hits hist))))


;; formatting pages

(defun inspire--insert-with-face (str face &rest properties)
  "Wrapper function for inserting STR with FACE.
Additional PROPERTIES can also be specified."
  (insert (apply #'propertize `(,str font-lock-face ,face ,@properties))))

(defun inspire--insert-url (str url)
  "Wrapper function for inserting a web link with name STR and address URL."
  (insert-button str
		 'action (lambda (x) (browse-url (button-get x 'url)))
		 'face 'inspire-link-face
		 'mouse-face 'highlight
		 'follow-link t
		 'help-echo (format "Link: %s" url)
		 'url url))

(defun inspire-populate-record ()
  "Clear and refill the inspire record buffer with relevant data."
  (with-current-buffer inspire-record-buffer
    (let ((entry (nth inspire-current-entry inspire-entry-list)))
      (setq header-line-format (format " literature/%s" (alist-get 'inspire-id entry)))
      (let ((buffer-read-only nil))
	(erase-buffer)
	(inspire--fill-record entry))
      (goto-char (point-min)))))
  
(defun inspire-populate-page ()
  "Clear and refill the inspire search buffer with entries."
  (with-current-buffer inspire-search-buffer
    (let ((buffer-read-only nil))
      (erase-buffer)
      (inspire--fill-page)
      (move-overlay inspire-highlight-overlay
		    (point) (progn (beginning-of-line 5) (point))))
    (goto-char (point-min))
    (setq inspire-current-entry 0)))

(defun inspire-populate-author-data ()
  "Clear and refill the inspire author buffer with relevant data."
  (with-current-buffer inspire-author-buffer
    (setq header-line-format (format " author/%s" (alist-get 'control-number inspire-author-data)))
    (let ((buffer-read-only nil))
      (erase-buffer)
      (inspire--fill-author-data))
    (goto-char (point-min))))

(defun inspire--fill-page (&optional start-entry)
  "Format and insert the search results according to `inspire-entry-list'.
Default to start inserting from entry index 0.
With non-nil START-ENTRY, start from there instead."
  (seq-do-indexed
   (lambda (entry index)
     (unless (and start-entry (< index start-entry))
       (inspire--insert-with-face (format " %s\n " (alist-get 'title entry)) '(:inherit inspire-title-face :height 1.15))
       (if-let (collaborations (alist-get 'collaborations entry))  ; if there is collaborations then don't show authors list
	   (inspire--insert-with-face
	    (concat (mapconcat #'identity collaborations " and ") " collaboration") inspire-author-face)
	 (let ((names (mapcar (lambda (author) (alist-get 'name author)) (alist-get 'authors entry))))
	   (inspire--insert-with-face (mapconcat #'identity (seq-take names 5) ", ") inspire-author-face)
	   (when (> (length names) 5)
	     (inspire--insert-with-face " et al." inspire-author-face))))
       (inspire--insert-with-face (format "\n %s \n\n"(alist-get 'date entry)) inspire-date-face)))
   inspire-entry-list))

(defun inspire--fill-record (entry)
  "Format and insert the record data.
ENTRY is an alist containing all the relevant data for the record."
  
  ;; title and authors
  (inspire--insert-with-face (format "\n%s\n" (alist-get 'title entry)) '(:inherit inspire-title-face :height 1.3))
  (inspire--insert-with-face "\n" inspire-title-face)
  (if-let (collaborations (alist-get 'collaborations entry))  ; if there is collaborations then don't show authors list
      (progn
	(seq-doseq (coll collaborations)
	  (insert-button coll
			 'action (lambda (_) (inspire-literature-search (concat "collaboration:" coll)))
			 'face '(:inherit inspire-author-face :underline t :height 1.1)
			 'mouse-face 'highlight
			 'follow-link t
			 'help-echo (format "Look up: %s collaboration" coll))
	  (inspire--insert-with-face " and " inspire-author-face))
	(delete-char -5)
	(inspire--insert-with-face " collaboration" inspire-author-face))
    (seq-doseq (author (alist-get 'authors entry)) ; author list
      (if (alist-get 'recid author)
	  (insert-button (alist-get 'name author)
			 'action (lambda (_) (inspire-author-record (alist-get 'recid author)))
			 'face '(:inherit inspire-author-face :underline t :height 1.1)
			 'mouse-face 'highlight
			 'follow-link t
			 'help-echo (format "Look up profile: author/%s" (alist-get 'recid author)))
	(inspire--insert-with-face (alist-get 'name author) '(:inherit inspire-author-face :underline t :height 1.1)))
      (when (alist-get 'affiliation author)
	(inspire--insert-with-face
	 (format " (%s)" (mapconcat #'identity (alist-get 'affiliation author) ", "))
	 '(:inherit inspire-author-face :height 1.0)))
      (inspire--insert-with-face ", " inspire-author-face))
      (delete-char -2))
  (inspire--insert-with-face (format "\n%s\n\n" (alist-get 'date entry)) inspire-date-face)
  
  ;; pages and publication info
  (when-let (pages (alist-get 'number-of-pages entry))
    (inspire--insert-with-face (format "%s Pages\n" pages) inspire-subfield-face))
  (inspire--insert-with-face (format "Type: %s\n" (alist-get 'type entry)) inspire-subfield-face)
  (when-let (journals (alist-get 'journals entry))
    (inspire--insert-with-face (format "Published in: %s\n" (mapconcat #'identity journals ", ")) inspire-subfield-face))
  (when-let (conferences (alist-get 'conferences entry))
    (inspire--insert-with-face (format "Contribution to: %s\n" (mapconcat #'identity conferences ", ")) inspire-subfield-face))
  (when-let (eprint (alist-get 'eprint entry))
    (inspire--insert-with-face "e-print: " inspire-subfield-face)
    (inspire--insert-url (alist-get 'value eprint) (format "https://arxiv.org/abs/%s" (alist-get 'value eprint)))
    (inspire--insert-with-face (format " [%s]\n" (map-nested-elt eprint '(categories 0))) inspire-arxiv-category-face))
  (when-let (dois (alist-get 'dois entry))
    (inspire--insert-with-face "DOI: " inspire-subfield-face)
    (seq-doseq (doi dois)
      (inspire--insert-url doi (format "https://doi.org/%s" doi))
      (inspire--insert-with-face ", " inspire-subfield-face))
    (delete-char -2)
    (insert "\n"))
  (inspire--insert-with-face (format "Texkey: %s\n" (alist-get 'bib-key entry)) inspire-subfield-face)
  (insert "\n")

  ;; abstract & notes
  (when-let (abstract (alist-get 'abstract entry))
    (if-let (source (alist-get 'source abstract))
	(inspire--insert-with-face (format "Abstract: (%s)\n%s\n\n" source (alist-get 'value abstract)) inspire-abstract-face)
      (inspire--insert-with-face (format "Abstract:\n%s\n\n" (alist-get 'value abstract)) inspire-abstract-face)))
  (when-let (notes (alist-get 'note entry))
    (inspire--insert-with-face (format "Note: %s\n\n" notes) inspire-abstract-face))
  
  ;; citations & references
  (insert-button (format "%s References"  (alist-get 'reference-count entry))
		 'action (lambda (_) (inspire-reference-search t))
		 'face 'inspire-link-face
		 'mouse-face 'highlight
		 'follow-link t
		 'help-echo (format "Look up literature: citedby:recid:%s" (alist-get 'inspire-id entry)))
  (insert ",  ")
  (insert-button (format "%s Citations"  (alist-get 'citation-count entry))
		 'action (lambda (_) (inspire-citation-search t))
		 'face 'inspire-link-face
		 'mouse-face 'highlight
		 'follow-link t
		 'help-echo (format "Look up literature: refersto:recid:%s" (alist-get 'inspire-id entry))))

(defun inspire--fill-author-data ()
  "Format and insert the author data according to `inspire-author-data'."
    
  ;; name and current positions
  (inspire--insert-with-face (format "\n%s" (alist-get 'name inspire-author-data)) '(:inherit inspire-author-heading-face :height 1.2))
  (when-let ((alt-name (alist-get 'native-names inspire-author-data)))
    (inspire--insert-with-face (format " (%s)" alt-name) '(:inherit inspire-author-heading-face :height 1.2)))
  (insert "\n")
  (when-let ((current-pos (alist-get 'current-position inspire-author-data)))
    (inspire--insert-with-face (format "(%s)\n" current-pos) inspire-author-institute-face))
  (insert "\n")

  ;; arxiv categories, author id and advisor
  (when-let ((arxiv-cat (alist-get 'arxiv-categories inspire-author-data)))
    (inspire--insert-with-face arxiv-cat inspire-arxiv-category-face)
    (insert "\n"))
  (when-let ((proj (alist-get 'projects inspire-author-data)))
      (inspire--insert-with-face (format "\nExperiments: %s" proj) inspire-subfield-face))
  (inspire--insert-with-face "\nAuthor id: " inspire-subfield-face)
  (inspire--insert-url (alist-get 'inspire-bai inspire-author-data)
		      (format "https://inspirehep.net/authors/%s" (alist-get 'control-number inspire-author-data)))
  (when-let ((orcid (alist-get 'orcid inspire-author-data)))
    (inspire--insert-with-face "\nORCID: " inspire-subfield-face)
    (inspire--insert-url orcid (format "https://orcid.org/%s" orcid)))
  (when-let ((advisors (alist-get 'advisors inspire-author-data)))
    (seq-doseq (advisor advisors)
      (insert "\n")
      (pcase (alist-get 'type advisor)
	('"phd" (inspire--insert-with-face "PhD " inspire-subfield-face))
	('"master" (inspire--insert-with-face "Master " inspire-subfield-face))
	('"bachelor" (inspire--insert-with-face "Bachelor " inspire-subfield-face)))
      (inspire--insert-with-face "Advisor: " inspire-subfield-face)

      (if (alist-get 'recid advisor)
	  (insert-button (alist-get 'name advisor)
			 'action (lambda (_) (inspire-author-record (alist-get 'recid advisor)))
			 'face '(:inherit inspire-author-face :underline t)
			 'mouse-face 'highlight
			 'follow-link t
			 'help-echo (format "Look up profile: author/%s" (alist-get 'recid advisor)))
	(insert-button (alist-get 'name advisor)
		       'action (lambda (_) (inspire-author-search (alist-get 'name advisor)))
		       'face '(:inherit inspire-author-face :underline t)
		       'mouse-face 'highlight
		       'follow-link t
		       'help-echo (format "Search for author: %s" (alist-get 'name advisor))))))
      

  ;; email
  (when-let ((email (alist-get 'email inspire-author-data)))
    (inspire--insert-with-face "\nemail: " inspire-subfield-face)
    (inspire--insert-url email (format "mailto:%s" email)))
  (insert "\n")

  ;; education and employment history
  (when-let ((positions (alist-get 'positions inspire-author-data)))
    (seq-doseq (pos positions)
      (inspire--insert-with-face (format "\n\t• %s" (alist-get 'date pos)) 'default)
      (insert "\n\t  ")
      (when-let ((rank (alist-get 'rank pos)))
	(inspire--insert-with-face (format "%s, " (alist-get 'rank pos)) '(:inherit default :weight semi-bold)))
      (inspire--insert-with-face (format "%s\n" (alist-get 'institution pos)) 'inspire-author-institute-face)))

  ;; timestamp
  (inspire--insert-with-face (format "\nUpdated: %s" (alist-get 'timestamp inspire-author-data)) 'shadow))


;; parsing query results

(defun inspire-parse-literature (url)
  "Call inspirehep API at URL to search for literature.
Parse the returned results into a list of alists
containing literature information."
  (with-current-buffer (url-retrieve-synchronously url t)
    (set-buffer-multibyte t)
    (goto-char (point-min))
    (search-forward "\{")
    (backward-char)
    (let* ((root (alist-get 'hits (json-parse-buffer :object-type 'alist)))
	   (total (alist-get 'total root))
	   (hits (alist-get 'hits root))
	   (alist-entry) (alist-formed '()))
      
      (when-let ((code (alist-get 'status root))
		 (mess (alist-get 'message root)))
	(error "Error %s: %s" code mess))
      
      (seq-doseq (entry hits)
	(let ((metadata (alist-get 'metadata entry))
	      (title) (authors_) (collaborations) (date) (files) (journals) (conferences) (dois) (bib-link) (bib-key) (abstract) (eprint) (citation-count) (reference-count) (number-of-pages) (note) (type) (inspire-id))
	  (setq inspire-query-total-hits total)
	  (setq bib-link (map-nested-elt entry '(links bibtex)))
	  (setq bib-key (map-nested-elt metadata '(texkeys 0)))
	  (setq title (map-nested-elt metadata '(titles 0 title)))
	  (setq date (or (map-nested-elt metadata '(earliest_date))
			 (map-nested-elt metadata '(preprint_date))
			 (map-nested-elt metadata '(imprints 0 date))))
	  (setq abstract (map-nested-elt metadata '(abstracts 0)))
	  (setq dois (seq-uniq (seq-map (lambda (elem) (alist-get 'value elem)) (alist-get 'dois metadata))))
	  (setq eprint (map-nested-elt metadata '(arxiv_eprints 0)))
	  (setq citation-count (alist-get 'citation_count metadata))
	  (setq reference-count (seq-length (alist-get 'references metadata)))
	  (setq number-of-pages (alist-get 'number_of_pages metadata))
	  (setq inspire-id (alist-get 'id entry))
	  (setq collaborations (and (alist-get 'collaborations metadata)
				    (seq-map (lambda (elem) (alist-get 'value elem)) (alist-get 'collaborations metadata))))
	  (setq authors_ (seq-map
			 (lambda (elem) `((name . ,(inspire--reorder-name (alist-get 'full_name elem)))
				     (affiliation . ,(mapcar (lambda (aff) (alist-get 'value aff)) (alist-get 'affiliations elem)))
				     (recid . ,(alist-get 'recid elem))))
			 (alist-get 'authors metadata)))

	  (when-let (pubs (alist-get 'publication_info metadata))
	    (seq-doseq (pub pubs)
	      (cond ((alist-get 'journal_title pub)    ; journal
		     (let ((jtitle (alist-get 'journal_title pub))
			   (jyear (alist-get 'year pub))
			   (jvol (alist-get 'journal_volume pub))
			   (pstart (alist-get 'page_start pub))
			   (pend (alist-get 'page_end pub)))
		       (cond ((eval pend) (setq journals (cons (format "%s %s (%s) %s-%s" jtitle jvol jyear pstart pend) journals)))
			     ((eval pstart) (setq journals (cons (format "%s %s (%s) %s" jtitle jvol jyear pstart) journals)))
			     (t (setq journals (cons (format "%s %s (%s)" jtitle jvol jyear) journals))))))
		    ((alist-get 'cnum pub)    ; conference
		     (setq conferences (cons (format "%s" (alist-get 'cnum pub)) conferences))))))
	  (setq note (when-let (raw (map-nested-elt metadata '(public_notes 0 value)))
		       (replace-regexp-in-string "\n" "" raw))) ; strip off extra EOLs
	  (setq type (map-nested-elt metadata '(document_type 0)))
	  
	  (when eprint
	    (push `((url . ,(format "https://arxiv.org/pdf/%s" (alist-get 'value eprint)))
		    (description . "arXiv"))
		  files))
	  (when-let ((docs (alist-get 'documents metadata)))
	    (seq-doseq (doc docs)
	      (push `((url . ,(alist-get 'url doc))
		      (description . ,(or (alist-get 'description doc) "inspirehep")))
		    files)))
	  
	  (setq alist-entry `((title . ,title)
			      ,(cons 'authors authors_) ; for a clean package-lint
			      (collaborations . ,collaborations)
			      (date . ,date)
			      (journals . ,(nreverse journals))
			      (conferences . ,(nreverse conferences))
			      (dois . ,dois)
			      (bib-link . ,bib-link)
			      (bib-key . ,bib-key)
			      (abstract . ,abstract)
			      (note . ,note)
			      (eprint . ,eprint)
			      (citation-count . ,citation-count)
			      (reference-count . ,reference-count)
			      (number-of-pages . ,number-of-pages)
			      (type . ,type)
			      (inspire-id . ,inspire-id)
			      (files . ,files)))
	  (setq alist-formed (cons alist-entry alist-formed))))
      (reverse alist-formed))))

(defun inspire-parse-author (url)
  "Call inspirehep API at URL for an author query and parse the result.
If the url query is a single author record,
return an alist containing author info.
If the url query is a search for matched names,
return a list of alists with each entry formatted as above."
  (with-current-buffer (url-retrieve-synchronously url t)
    (set-buffer-multibyte t)
    (goto-char (point-min))
    (search-forward "\{")
    (backward-char)
    (let ((root (json-parse-buffer :object-type'alist)))
      (when-let ((code (alist-get 'status root))
		 (mess (alist-get 'message root)))
	(error "Error %s: %s" code mess))
      (if (assoc 'metadata root)
	  (inspire--parse-author-entry root) ; single author record
	(seq-map
	 (lambda (entry) (inspire--parse-author-entry entry)) ; multi-author query
	 (map-nested-elt root '(hits hits)))))))

(defun inspire--parse-author-entry (entry)
  "Parse ENTRY and return an alist containing author information."
  (let ((metadata (alist-get 'metadata entry))
	(ids) (inspire-bai) (orcid) (control-number) (name) (native-names) (advisors) (positions) (current-position) (arxiv-categories) (projects) (email) (timestamp))
    (setq ids (alist-get 'ids metadata))
    (setq inspire-bai (alist-get 'value (seq-find (lambda (x) (equal (alist-get 'schema x) "INSPIRE BAI")) ids)))
    (setq orcid (alist-get 'value (seq-find (lambda (x) (equal (alist-get 'schema x) "ORCID")) ids)))
    (setq control-number (alist-get 'control_number metadata))
    (setq name (or (map-nested-elt metadata '(name preferred_name))
		   (inspire--reorder-name (map-nested-elt metadata '(name value)))))
    (when-let ((nat (map-nested-elt metadata '(name native_names))))
      (setq native-names (mapconcat #'identity nat ", ")))
    (when-let ((advs (seq-filter (lambda (x) (not (eq (alist-get 'hidden x) t))) (alist-get 'advisors metadata))))
      (seq-do (lambda (adv)
		(let* ((type  (alist-get 'degree_type adv))
		       (name  (inspire--reorder-name (alist-get 'name adv)))
		       (recid (map-nested-elt adv '(record $ref))))
		  (when recid
		      (string-match "^https://inspirehep.net/api/authors/\\([0-9]+\\)$" recid)
		      (setq recid (match-string 1 recid)))
		  (push `((type . ,type) (name . ,name) (recid . ,recid)) advisors)))
	      advs)
      (setq advisors (nreverse advisors)))
    (when-let ((cat (alist-get 'arxiv_categories metadata)))
      (setq arxiv-categories (mapconcat (lambda (cat) (format "[%s]" cat)) cat " ")))
    (when-let ((projs (alist-get 'project_membership metadata)))
      (setq projects (mapconcat (lambda (proj) (alist-get 'name proj)) projs ", ")))
    (setq email (map-nested-elt metadata '(email_addresses 0 value)))
    (string-match "^\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\)" (alist-get 'updated entry))
    (setq timestamp (match-string 1 (alist-get 'updated entry)))
    (when-let ((pos-list (alist-get 'positions metadata)))
      (seq-do (lambda (pos)
		(let* ((rank    (alist-get 'rank pos))
		       (inst    (alist-get 'institution pos))
		       (start   (or (alist-get 'start_date pos)))
		       (end     (or (alist-get 'end_date pos) ""))
		       (current (alist-get 'current pos))
		       (hidden  (alist-get 'hidden pos)))
		  (unless (eq hidden t)
		    (if (eq current t)
			(progn
			  (push inst current-position)
			  (if start
			      (push `((rank . ,rank) (institution . ,inst) (date . ,(format "%s - present" start))) positions)
			    (push `((rank . ,rank) (institution . ,inst) (date . "present")) positions)))
		      (if start
			  (push `((rank . ,rank) (institution . ,inst) (date . ,(format "%s - %s" start end))) positions)
			(push `((rank . ,rank) (institution . ,inst) (date . ,(format "%s" end))) positions))))))
	      pos-list)
      (setq positions (nreverse positions))
      (setq current-position (and current-position (mapconcat #'identity (nreverse current-position) " and "))))
    
    `((inspire-bai . ,inspire-bai)
      (orcid . ,orcid)
      (control-number . ,control-number)
      (name . ,name)
      (native-names . ,native-names)
      (advisors . ,advisors)
      (arxiv-categories . ,arxiv-categories)
      (projects . ,projects)
      (email . ,email)
      (positions . ,positions)
      (current-position . ,current-position)
      (timestamp . ,timestamp))))

(defun inspire--reorder-name (full-name)
  "Helper function for translating the author names.
Recast string FULL-NAME from \"last_name, first_name\"
to \"first_name last_name\"."
  (if (string-match "^\\(.+\\), \\(.+\\)$" full-name)
      (concat (match-string 2 full-name) " " (match-string 1 full-name))
    full-name))

  
(provide 'inspire)
;;; inspire.el ends here
