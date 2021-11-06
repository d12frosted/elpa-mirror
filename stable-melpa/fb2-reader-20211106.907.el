;;; fb2-reader.el --- Read FB2 and FB2.ZIP documents -*- lexical-binding: t; -*-

;; Copyright (c) 2021 Dmitriy Pshonko <jumper047@gmail.com>

;; Author: Dmitriy Pshonko <jumper047@gmail.com>
;; URL: https://github.com/jumper047/fb2-reader
;; Package-Version: 20211106.907
;; Package-Commit: 678f4ec183c02031f7658a65d2ba442337fcb87e
;; Keywords: multimedia, ebook, fb2
;; Version: 0.1.0

;; Package-Requires: ((emacs "26.2") (f "0.17") (s "1.11.0") (dash "2.12.0") (visual-fill-column "2.2") (async "1.9.4"))


;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
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

;; fb2-reader.el provides a major mode for reading FB2 books.
;;
;; Features:
;; 
;; - read .fb2 and .fb2.zip files
;; - rich book formatting
;; - showing current title in header line
;; - internal links (select from keyboard, jumb back and forth)
;; - navigation (next/previous chapters, imenu support)
;; - restoring last read position
;; - displaying raw xml
;; - book info screen
;;
;; Coming soon:
;; 
;; - integration with https://github.com/jumper047/librera-sync
;; - rendering book in org-mode
;;
;; Installation:
;; Add these strings to your config:
;;
;;    (use-package fb2-reader
;;      :mode (("\\.fb2\\(.zip\\|\\)$" . fb2-reader-mode))
;;      :custom
;;      ;; This mode renders book with fixed width, adjust to your preferences.
;;      (fb2-reader-page-width 120)
;;      (fb2-reader-image-max-width 400)
;;      (fb2-reader-image-max-height 400))

;;; Code:

(require 'visual-fill-column)
(require 'subr-x)
(require 'cl-lib)
(require 'imenu)
(require 'dash)
(require 'f)
(require 's)
(require 'async)


(defcustom fb2-reader-settings-dir (expand-file-name "fb2-reader" user-emacs-directory)
  "Path to directory with cached books, saved places etc."
  :type 'directory
  :group 'fb2-reader)

(defcustom fb2-reader-title-in-headerline t
  "Show current chapter's title in headerline."
  :type 'boolean
  :group 'fb2-reader)

(defcustom fb2-reader-restore-position t
  "Restore last viewed position on book's opening."
  :type 'boolean
  :group 'fb2-reader)

(defcustom fb2-reader-page-width 120
  "Width of the rendered text."
  :type 'integer
  :group 'fb2-reader)

(defcustom fb2-reader-show-images 't
  "Show images."
  :type 'boolean
  :group 'fb2-reader)

(defcustom fb2-reader-image-max-width 400
  "Maximum width of the displayed image."
  :type 'integer
  :group 'fb2-reader)

(defcustom fb2-reader-image-max-height 400
  "Maximum height of the displayed image."
  :type 'integer
  :group 'fb2-reader)

(defcustom fb2-reader-title-height 1.4
  "Height of the title's font."
  :type 'float
  :group 'fb2-reader)

(defcustom fb2-reader-max-in-cache 20
  "Maximum number of files stored in cache."
  :type 'integer
  :group 'fb2-reader)

(defface fb2-reader-info-field-face
  '((t (:weight bold)))
  "Face for field name in book info buffer."
  :group 'fb2-reader)

(defface fb2-reader-info-category-face
  '((t (:weight bold :underline 't)))
  "Face for category name in book info buffer."
  :group 'fb2-reader)

(defvar fb2-reader-index-filename "index.el"
  "Filename for file containing meta information about cached books.")

(defvar fb2-reader-position-filename "positions.el"
  "Filename for file containing last positions in books.")

(defvar fb2-reader-link-map
  (let ((map (make-sparse-keymap)))
    (define-key map [follow-link] 'mouse-face)
    (define-key map "\r" 'fb2-reader-follow-link)
    (define-key map [mouse-2] 'fb2-reader-follow-link)
    map))

(defvar-local fb2-reader-file-name nil
  "Book's filename (replaces buffer-file-name).")

(defvar-local fb2-reader-link-pos nil
  "Last used link's position.")

(defvar-local fb2-reader-link-target-pos nil
  "Last used link's target.")

(defconst fb2-reader-header-line-format
  '(:eval (list (propertize " " 'display '((space :align-to 0)))
		(fb2-reader-current-chapter))))

;; Fb2 parsing

(defun fb2-reader-parse (book item &optional tags face alignment indent)
  "Recursively parse ITEM and insert it into the buffer.
BOOK is whole xml tree (it is needed in case)"

  (or face (setq face 'default))
  (or tags (setq tags '()))
  ;; (or alignment (setq alignment 'left))
  (or alignment (setq alignment 'full))
  (or indent (setq indent 0))
  (if (stringp item)
		 (insert (propertize (string-trim item)
				     'face face
				     'fb2-reader-tags tags))
    (let ((current-tag (cl-first item))
	  (attributes (cl-second item))
	  (body (cddr item)))

      (cond ((equal current-tag 'text-author)
	     (fb2-reader--format-string book body tags face current-tag 'right indent))
	    ((equal current-tag 'section)
	     (fb2-reader--parse-section book attributes body tags face current-tag))
	    ((equal current-tag 'poem)
	     (fb2-reader--parse-poem book body tags face current-tag))
	    ((equal current-tag 'title)
	     (fb2-reader--parse-title book body tags face current-tag))
	    ((equal current-tag 'cite)
	     (fb2-reader--parse-cite book body tags face current-tag))
	    ((equal current-tag 'empty-line)
	     (insert (propertize "\n" 'fb2-reader-tags (cons 'empty-line tags))))
	    ((equal current-tag 'image)
	     ;; Disabled due new async rendering function
	     ;; (fb2-reader--parse-image book attributes tags)
	     (fb2-reader--pickle-image book attributes tags))
	     
	    ((equal current-tag 'a)
	     (fb2-reader--parse-a-link book attributes body tags face current-tag))
	    ((equal current-tag 'p)
	     (fb2-reader--format-string book body tags
					 face current-tag alignment indent))
	    ((equal current-tag 'v)
	     (fb2-reader--format-string book body tags
					 face current-tag 'center indent))
	    ((equal current-tag 'strong)
	     (fb2-reader-parse book (cl-first body) tags (cons 'bold face)))
	    ((equal current-tag 'emphasis)
	     (fb2-reader-parse book (cl-first body) tags (cons 'italic face)))
	    ('t
	     (dolist (subitem body)
	       (fb2-reader-parse book subitem (cons current-tag tags) face)))))))

(defun fb2-reader--format-string (book body tags face curr-tag  alignment indent  &optional indent-first append-newline)
  "Format BODY according to FACE, ALIGNMENT and INDENT and insert it.
BOOK is whole book xml tree, TAGS - fb2 tags, CURR-TAG - current fb2 tag."
  (or indent-first (setq indent-first 2))
  (or append-newline (setq append-newline 't))
  (let* ((point-start (point))
	 (indent (+ indent 1))
	 ;; 1 appended to indent because of unwanted behavior
	 ;; of fill-paragraph  function. If fill-prefix equals
	 ;; nil or "" fill-paragraph uses spaces at
	 ;; beginning of the string as fill-prefix. If fill
	 ;; prefix is not empty it works as expected.
	 (prefix (string-join (make-list indent " ")))
	 (prefix-first (string-join (make-list (+ indent indent-first) " "))))

    (insert (propertize prefix-first 'fb2-reader-tags tags))
    (dolist (subitem body)
      (fb2-reader-parse book subitem (cons curr-tag tags) face alignment indent))
    (if append-newline
	(insert (propertize "\n" 'fb2-reader-tags tags)))
    (setq fill-prefix prefix)
    (fill-region point-start (point) alignment)))

(defun fb2-reader--insert-newline-maybe ()
  "Insert newline if there is no newline inserted before.
Exception for \"empty-line\" tag."

  (let (already-added)
    (save-excursion
      (backward-char)
      (setq already-added
	    (and (equal (char-before) 10)
		 (equal (char-after) 10))))
    (unless already-added
      (insert (propertize "\n" 'fb2-reader-tags '(empty-line-special))))))

(defun fb2-reader--parse-section (book attributes body tags face curr-tag)
  "Parse section, add fb2-reader-id text property if id found in ATTRIBUTES.
BOOK is whole book xml tree, TAGS - fb2 tags, CURR-TAG - current fb2 tag."
  (let ((start (point))
	(id (alist-get 'id attributes)))
    (dolist (subitem body)
      (fb2-reader-parse book subitem (cons curr-tag tags) face))
    (when id
      (add-text-properties start (point) (list 'fb2-reader-id (intern id))))))

(defun fb2-reader--parse-title (book body tags face curr-tag)
  "Parse and insert BODY (BOOK 's part) as title."

  (let* ((title-fill-column (round (/ fb2-reader-page-width fb2-reader-title-height)))
	 (title-face (cons (cons :height (list fb2-reader-title-height)) face))
	 (fill-column-backup fill-column)
	 start
	 end)

    (when (> (line-number-at-pos) 1)	;don't insert separator if this is first title
      (insert "\n\n"))
    (setq start (point))
    (setq-local fill-column title-fill-column)
    (dolist (subitem body)
      (fb2-reader-parse book subitem (cons curr-tag tags) title-face  'center 2))
    (setq-local fill-column fill-column-backup)
    ;; Because of strange fill-region behavior every line in region should be recenered
    ;; (For some reason when fill-region invoked inside fb2r-format-string,
    ;; every space or tab added to line not inherit :height property, and
    ;; resulting line length became longer or shorter than planned)
    (fb2-reader--recenter-region start (point) fb2-reader-title-height)
    (setq end (point))
    (insert "\n")
    (add-text-properties start end '(fb2-reader-title t))))


(defun fb2-reader--center-prefix (linelen strlen height)
  "Calculate number of spaces needed to center string.
String to center has STRLEN symbols, every symbol has HEIGHT.
LINELEN is maximum line's length (page width)"
   (round (/ (- linelen (* strlen height)) 2)))

(defun fb2-reader--recenter-region (begin end height)
  "Recenter region from BEGIN to END.
HEIGHT is font's height (should be coefficient).
Every string's length in region should be less or equal fill column."
  (let ((lines (number-sequence (line-number-at-pos begin)
				(line-number-at-pos end)))
	linestr prefix)
    (save-excursion
      (dolist (linenum lines)
	(goto-char (point-min))
	(forward-line (1- linenum))
	(setq linestr (s-trim (s-collapse-whitespace
				       (buffer-substring
					(point)
					(progn
					  (move-end-of-line 1) (point))))))
	(when (> (length linestr) 0)
	  (setq prefix (fb2-reader--center-prefix fill-column (length linestr) height))
	  (move-beginning-of-line 1)
	  (kill-line)
	  (insert (s-repeat prefix " "))
	  (insert linestr))))))
	
(defun fb2-reader--parse-cite (book body tags face current-tag)
  "Parse BODY as cite and insert it.
BOOK is whole book xml tree, TAGS - fb2 tags, CURR-TAG - current fb2 tag."
  (let* ((indent 4)
	 (fill-column-backup fill-column)
	 (new-fill-column (- fill-column indent)))
    (fb2-reader--insert-newline-maybe)
    (setq-local fill-column new-fill-column)
    (dolist (subitem body)
    (fb2-reader-parse book subitem (cons current-tag tags) face 'full indent))
    (setq-local fill-column fill-column-backup)
    (fb2-reader--insert-newline-maybe)))

(defun fb2-reader--parse-poem (book body tags face current-tag)
  "Parse BODY as poem and insert it.
BOOK is whole book xml tree, TAGS - fb2 tags, CURR-TAG - current fb2 tag."
  (dolist (subitem body)
    (let ((subtags (cons current-tag tags))
	  (subtag (cl-first subitem)))
      (if (equal subtag 'stanza)
	  (fb2-reader--insert-newline-maybe))
      (fb2-reader-parse book subitem (cons subtag subtags) face)))
  (insert (propertize "\n" 'fb2-reader-tags '('empty-line-special))))

(defun fb2-reader--pickle-image (book attributes tags)
  "Save all image-related info from BOOK ATTRIBUTES and TAGS to text property.

It should be rendered when propertized text will be inserted into buffer."
  (when-let* ((imgdata (fb2-reader--extract-image-data book attributes tags))
	      (type-str (cl-first imgdata))
	      (data-str (cl-second imgdata))
	      (tags (cl-third imgdata)))
    (insert (propertize " "
			'fb2-reader-image-type type-str
			'fb2-reader-image-data data-str
			'fb2-reader-tags tags))))

(defun fb2-reader--extract-image-data (book attributes &optional tags)
  "Parse image ATTRIBUTES and return image related data.
List of type string, binary data string, and tags will be returned.
BOOK is whole book's xml tree. TAGS are list of fb2 tags."
  (when-let* ((id (replace-regexp-in-string "#" "" (cdr (car attributes))))
	      (binary (fb2-reader--find-binary book id))
	      (type-str (alist-get 'content-type (cl-second binary)))
	      (data-str (cl-third binary)))
    (list type-str data-str tags)))

(defun fb2-reader--insert-image (data type &optional tags use-prefix)
  "Generate image from DATA of type TYPE and insert it at point.

 Property fb2-reader-tags will be set to TAGS and appended
to placeholder."

  ;; TODO: add alignment

  (when-let* ((type-char (alist-get type
				    '(("image/jpeg" . jpeg) ("image/png" . png))
				    nil nil 'equal))
	      (data-decoded (base64-decode-string data))
	      (img-raw (fb2-reader--create-image data-decoded type-char))
	      (size-raw (image-size img-raw 't))
	      (img-adj (fb2-reader--create-image data-decoded type-char
						 :max-width fb2-reader-image-max-width
						 :max-height fb2-reader-image-max-height))
	      (width-ch (car (image-size img-adj)))
	      (prefix-num (round (/ (- fb2-reader-page-width width-ch) 2)))
	      (prefix-str (string-join (make-list prefix-num " ")))
	      (fill-str (propertize " " 'fb2-reader-tags (cons 'image tags)
				    'fb2-reader-image-params size-raw)))
    (insert "\n")
    (if use-prefix
	(insert prefix-str))
    (insert-image img-adj fill-str)
    (insert "\n")))

(defun fb2-reader-restore-images (&optional buffer)
  "Find all images pickled in BUFFER and restore them."

  (interactive)
  (or buffer (setq buffer (current-buffer)))
  (with-current-buffer buffer
    (goto-char (point-min))
    (while (not (eobp))
      (let ((next-change (or (next-single-property-change (point) 'fb2-reader-image-data)
			     (point-max)))
	    (plist (text-properties-at (point)))
	    image-data
	    image-type
	    tags)
	(when (plist-member plist 'fb2-reader-image-data)
	  (setq image-data (plist-get plist 'fb2-reader-image-data)
		image-type (plist-get plist 'fb2-reader-image-type)
		tags (plist-get plist 'fb2-reader-tags))
	  (delete-char 1)
	  (fb2-reader--insert-image image-data image-type tags 't))
	(goto-char next-change)))))

(defun fb2-reader--find-binary (book id)
  "Find binary with ID in BOOK."

  (fb2-reader--find-subitem book 'binary 'id id))


;; In case I'll need seamlessly switch image backend to imagemagick or something
(defun fb2-reader--create-image (data type &rest props)
  "Create image of type TYPE from image DATA."

  (apply #'create-image data type 't props))


;; Parse metadata (everything inside description tag)

(defun fb2-reader-parse-metadata (book item)
  (let ((current-tag (cl-first item))
	(attributes (cl-second item))
	  (body (cddr item)))
    (cond ((member current-tag '(history annotation))
	   (fb2-reader--parse-rich-text item))
	  ((member current-tag '(author translator))
	   (fb2-reader--parse-person item))
	  ((equal current-tag 'sequence)
	   (fb2-reader--parse-sequence item))
	  ((equal current-tag 'coverpage)
	     (fb2-reader--parse-cover book item))
	    (t
	     (if  (> (length body) 1)
		 (progn (insert (format "\n%s\n" (fb2-reader--format-symbol current-tag 'fb2-reader-info-category-face)))
		   (dolist (subitem body)
			  (fb2-reader-parse-metadata book subitem)))
	       (insert (format "%s: %s\n" (fb2-reader--format-symbol current-tag 'fb2-reader-info-field-face) (if (stringp (car body)) (car body) " -"))))))))

(defun fb2-reader--format-symbol (symbol face)
  "Take SYMBOL, transform it it readable string and apply FACE."
  (let ((prop (cond ((equal face 'fb2-reader-info-field-face)
		     'fb2-reader-info-field)
		    ((equal face 'fb2-reader-info-category-face)
		     'fb2-reader-info-category))))
  (propertize (s-capitalize (s-replace "-" " " (symbol-name symbol)))
		   'face face prop t)))

(defun fb2-reader--parse-person (item)
  "Parse ITEM and insert as some person's data (author or translator).
FIELD-NAME is what shold be in left of : when name is printed."
  (let* ((fields (cddr item))
	 (name (s-join " " (-non-nil (list (cl-second (alist-get 'first-name fields))
					   (cl-second (alist-get 'middle-name fields))
					   (cl-second (alist-get 'nick fields))
					   (cl-second (alist-get 'last-name fields))))))
	 (name-fields '(first-name middle-name nick last-name)))
    (if name (insert (format "%s: %s\n" (fb2-reader--format-symbol (cl-first item) 'fb2-reader-info-field-face) name)))
    (dolist (field fields)
      (when (not (member (cl-first field) '(first-name middle-name nick last-name)))
	  (insert (format "  %s: %s\n" (fb2-reader--format-symbol (cl-first field) 'fb2-reader-info-field-face) (cl-third field)))))))

(defun fb2-reader--parse-rich-text (item)
"Parse ITEM as field with rich text inside."
  (let* ((field-name (s-capitalize (symbol-name (cl-first item))))
	(fname-length (length field-name))
	(start (point))
	end)
    (fb2-reader-parse nil item nil nil 'full (+ 2 fname-length))
    (setq end (point))
    (save-excursion
      (goto-char start)
      (insert (format "%s:" (propertize field-name 'face 'fb2-reader-info-field-face 'fb2-reader-info-field 't)))
      (while (<= (line-number-at-pos (point)) (line-number-at-pos end))
	(forward-line 1)
	(insert (s-repeat (1+ fname-length) " "))))))

(defun fb2-reader--parse-sequence (item)
  "Parse ITEM as sequence and insert it at point."
  (let* ((attributes (cl-second item))
	 (field-name (fb2-reader--format-symbol (cl-first item) 'fb2-reader-info-field-face))
	 (name (alist-get 'name attributes))
	 (number (alist-get 'number attributes)))
    (insert (format "%s: %s" field-name name))
    (if number (insert (format "(%s)" number)))
    (insert "\n")))

(defun fb2-reader--parse-cover (book item)
  "Get image attrs from ITEM, find image in BOOK and insert it."
  (let* ((attrs (cl-second (cl-third item)))
	 (imgdata (fb2-reader--extract-image-data book attrs))
	 (type-str (cl-first imgdata))
	 (data-str (cl-second imgdata))
	 (covername (fb2-reader--format-symbol (cl-first item) 'fb2-reader-info-field-face)))
  (insert (format "%s:\n" covername))
  (fb2-reader--insert-image data-str type-str)
  (insert "\n")))

;; Links

(defun fb2-reader--parse-a-link (book attributes body tags face curr-tag)
  "Parse and insert link described with ATTRIBUTES from BOOK."

  (let ((id (intern (replace-regexp-in-string "#" "" (cdr (car attributes)))))
	(start (point))
	(link-face (cons (cons :inherit (list 'link)) face)))
    (dolist (subitem body)
      (fb2-reader-parse book subitem (cons curr-tag tags) link-face))
    (add-text-properties start (point)
			 (list 'fb2-reader-target id
				'follow-link t
				 'keymap fb2-reader-link-map
				 'mouse-face 'highlight))))

(defun fb2-reader--get-target-pos (id)
  "Get target position for link with certain ID."
  (save-excursion
    (goto-char (point-min))
    
    (let (link-found next-change plist target-pos)
      (while (not (or link-found (eobp)))
	(setq next-change (or (next-single-property-change (point) 'fb2-reader-id)
			      (point-max))
	      plist (text-properties-at (point))
	      link-found (equal id (plist-get plist 'fb2-reader-id))
	      target-pos (point))
	(goto-char next-change))
      (if link-found target-pos))))
      

(defun fb2-reader-follow-link ()
  "Follow link under point."
  
  (interactive)
  (push-mark)
  (when-let* ((target-id (get-text-property (point) 'fb2-reader-target))
	      (position (fb2-reader--get-target-pos target-id)))
    (setq fb2-reader-link-pos (point))
    (goto-char position)
    (setq fb2-reader-link-target-pos (point))
    (recenter 0)))

(defun fb2-reader-link-back ()
  "Go to last used link's location."
  (interactive)
  (if fb2-reader-link-pos
      (goto-char fb2-reader-link-pos)
    (user-error "This is first element in history")))

(defun fb2-reader-link-forward ()
  "Go to last used link's location."
  (interactive)
  (if fb2-reader-link-pos
      (goto-char fb2-reader-link-target-pos)
    (user-error "This is last element in history")))

(defun fb2-reader--find-subitem (item tag &optional property value)
  "Find first ITEM 's child with TAG.

Founded item should have PROPERTY with certain VALUE,
if these parameters are set."
  (if (listp item)
      (catch 'subitem (progn (dolist (subitem item)
			(if (and
			     (listp subitem)
			     (equal (cl-first subitem) tag)
			     (or (not property)
				 (and (listp (cl-second subitem))
				      (equal value (alist-get property (cl-second subitem))))))
			    (throw 'subitem subitem)))
			     nil))))

(defun fb2-reader--find-subitem-recursively (item &rest tags)
  "Find ITEM 's subitem with first tag from TAGS, then subitem's subitem with second tag and so on."

  (let (curr-item)
    (setq curr-item item)
    (dolist (tag tags curr-item)
      (setq curr-item (fb2-reader--find-subitem curr-item tag)))))

(defun fb2-reader--get-bodies (book)
  "Get list of all bodies from the BOOK."

  (let (bodies)
    (dolist (item (cddr book))
      (if (equal (cl-first item) 'body)
	  (push item bodies)))
    (reverse bodies)))

(defun fb2-reader--get-description (book)
  "Get description node from BOOK."
  (fb2-reader--find-subitem-recursively (cddr book) 'description))

(defun fb2-reader--get-title (book)
  "Get title node from BOOK."

  (fb2-reader--find-subitem-recursively (cddr book) 'description 'title-info 'book-title))

(defun fb2-reader--get-author (book)
  "Get author node from BOOK."
  (fb2-reader--find-subitem-recursively (cddr book) 'description 'title-info 'author))

(defun fb2-reader--get-cover (book)
  "Get cover node from BOOK."
  (fb2-reader--find-subitem-recursively (cddr book) 'description 'title-info 'coverpage))

(defun fb2-reader--get-annotation (book)
  "Get annotation node from BOOK."
  (fb2-reader--find-subitem-recursively (cddr book) 'description 'title-info 'annotation))


(defun fb2-reader-render (book)
  "Render BOOK and insert it into the current buffer."

  (setq-local fill-column fb2-reader-page-width)
  (dolist (body (fb2-reader--get-bodies book))
    (fb2-reader-parse book body)))

(defun fb2-reader-render-async (book callback)
  "Render BOOK asynchronously, launch CALLBACK with result."
  (async-start
   `(lambda ()
      ,(async-inject-variables "\\`\\(fb2-reader\\)-")
      ,(async-inject-variables "book")
      (setq load-path (quote ,load-path))
      (require 'fb2-reader)
      (with-temp-buffer
	(fb2-reader-render (quote ,book))
	(prin1-to-string (buffer-substring (point-min) (point-max)))))
   callback))

;; Utilities
(defun fb2-reader--assert-mode-p ()
  "Check is current buffer is suitable to run command and throw error otherwise."
  (unless fb2-reader-file-name
    (user-error "Command suitable only for fb2-reader buffers")))

;; Imenu support

(defun fb2-reader-imenu-create-index ()
 "Create index for imenu."
 (goto-char (point-min))
  (let (next-change plist index)
  (while (not (eobp))
    (setq next-change (or (next-single-property-change (point) 'fb2-reader-title)
			  (point-max))
	  plist (text-properties-at (point)))
    (when (plist-member plist 'fb2-reader-title)
      (push (cons (s-replace "\n" " " (s-trim (s-collapse-whitespace
					       (buffer-substring-no-properties
						(point) next-change)))) (point))
	    index))
    (goto-char next-change))
  (reverse index)))

(defun fb2-reader-imenu-setup ()
  "Set apropriate \"imenu-create-index-function\"."
  (setq imenu-create-index-function 'fb2-reader-imenu-create-index))


;; Header line

(defun fb2-reader-current-chapter ()
  "Get current chapter's title."

  (save-excursion
    (goto-char (window-start))
    ;; step forward for one char because when cursor appends exactly on title's
    ;; border prev/next single property function skips current change
    (forward-char 1)
    (let ((start-point (point)) title-start title-end title-first-line-end titlestr)
      (setq title-end (funcall (if (plist-member (text-properties-at (point)) 'fb2-reader-title)
				   'next-single-property-change
				 'previous-single-property-change)
			       (point) 'fb2-reader-title)
	    title-start (previous-single-property-change title-end 'fb2-reader-title))

      ;; Go to previous title if we are on first line of title now
      (when (eq (line-number-at-pos start-point) (line-number-at-pos title-start)) ;
	(setq title-end (previous-single-property-change title-start 'fb2-reader-title)
	      title-start (previous-single-property-change title-end 'fb2-reader-title)))

      (when title-start (goto-char title-start)
	    (move-end-of-line 1)
	    (setq title-first-line-end (point)))

      (when (and title-start title-end)
	(setq titlestr
	      (s-collapse-whitespace (buffer-substring-no-properties title-start title-first-line-end)))
	(if (or (eq (line-number-at-pos title-start) (1- (line-number-at-pos title-end))) ;oneline title
		(eq 1 (- (line-number-at-pos start-point) (line-number-at-pos title-start)))) ;point on second line
	    (setq titlestr (propertize titlestr 'face (list (cons :height (list fb2-reader-title-height)))))
	  (setq titlestr (propertize (concat (s-left (- (length titlestr) 3) titlestr) "...")
				     'help-echo `(format "%s" ,(s-trim (buffer-substring-no-properties title-start title-end)))
				     'face (list (cons :height (list fb2-reader-title-height))))))

	(concat (s-repeat (fb2-reader--center-prefix fill-column (length titlestr) fb2-reader-title-height) " ")
		(propertize titlestr 'face (list (cons :height (list fb2-reader-title-height)))))))))


(defun fb2-reader-set-up-header-line ()
  "Set up header line in current buffer."

  (setf header-line-format 'fb2-reader-header-line-format))

;; Reading from settings

(defun fb2-reader-ensure-settingsdir ()
  "Create settings directory if necessary."
  (unless (f-exists-p fb2-reader-settings-dir)
    (make-directory fb2-reader-settings-dir)))

(defun fb2-reader-load-settings (loadfn filename)
  "Open .el file from settings with function LOADFN.

FILENAME located in settings directory. Returns nil if file not found.
LOADFN should receive only one argument - full path to file."
  (let ((fullpath (f-join fb2-reader-settings-dir
			  filename)))
    (if (f-exists-p fullpath)
	(funcall loadfn fullpath))))

(defun fb2-reader-load-file (file)
  "Load text from FILE as elisp."

  (if (f-exists-p file)
      (with-temp-buffer
	(insert-file-contents file)
	(goto-char (point-min))
	(read (current-buffer)))))


;; Navigation

(defun fb2-reader--jump-property (number propname)
  "Jump nth PROPNAME occurance in buffer.
NUMBER's sign determines search direction."
  (unless (eq number 0)	;do nothing if chapter is 0.
    (let* ((fwd (> number 0))
	   (obp (if fwd 'eobp 'bobp))
	   (point-end (if fwd 'point-max 'point-min))
	   (search-prop (if fwd 'next-single-property-change
			  'previous-single-property-change))
	   (step (if fwd 1 -1))
	   found)
      ;; Add one to step in case moving backward and initial position
      ;; not inside tag because first position in that case will be right
      ;; after tag which is inconvinient.
      (unless (plist-member (text-properties-at (point)) propname)
	   (setq number (if (not fwd) (1- number) number)))
      (while (and  (not (eq 0 number)) (not (funcall obp)))
	;; If we already inside title, skip it and go to next one
	(unless (plist-member (text-properties-at (point)) propname)
	  (setq found 't))
	(goto-char (or (funcall search-prop (point) propname)
		       (funcall point-end)))
	(if found (setq number (- number step)
			found nil))))))


(defun fb2-reader-forward-chapter (&optional n)
  "Go N chapters forward."
  (interactive "p")
  (fb2-reader--jump-property n 'fb2-reader-title)
  (recenter 0))

(defun fb2-reader-backward-chapter (&optional n)
  "Go N chapters backward."
  (interactive "p")
  (setq n (* n -1))
  (fb2-reader--jump-property n 'fb2-reader-title)
  (recenter 0))

(defun fb2-reader--jump-link (n)
  "Go N links forward."
  (let (target)
    (save-excursion
      (fb2-reader--jump-property n 'fb2-reader-target)
      (setq target (point)))
    (if (and (>= target (window-start)) (<= target (window-end)))
	(goto-char target))))

(defun fb2-reader-forward-visible-link (&optional n)
  "Go N visible links forward."
  (interactive "p")
  (fb2-reader--jump-link n))

(defun fb2-reader-backward-visible-link (&optional n)
  "Go N visible links backwarg."
  (interactive "p")
  (setq n (* n -1))
  (fb2-reader--jump-link n))

;; Caching

(defun fb2-reader-cache-index ()
  "Read cache index."

  (fb2-reader-load-settings 'fb2-reader-load-file
			    fb2-reader-index-filename))




(defun fb2-reader-save-cache-index (file index)
  "Serialize given cache INDEX and save it to FILE."
  
  (with-temp-file file
        (set-buffer-file-coding-system 'utf-8)
	(insert ";; fb2-reader.el -- read fb2 books  ")
	(insert "file contains cache index, don't edit.\n")
	(insert (prin1-to-string index))
	(insert "\n")))

(defun fb2-reader-cache-avail-p (file &optional actual-only)
  "Check if cache for FILE available.

If ACTUAL-ONLY return 't if cache is existed and actual."
  
  (when-let ((idx-entry (alist-get file (fb2-reader-cache-index) nil nil 'equal)))
    (if actual-only
	(equal (car idx-entry)
	       (file-attribute-modification-time
		(file-attributes file)))
      't)))


(defun fb2-reader-get-cache (file)
  "Load cache for FILE if it exists."

  (let ((cache-file (cl-second (alist-get file (fb2-reader-cache-index) nil nil 'equal))))
    (if (and cache-file (f-exists-p cache-file))
	(with-temp-buffer
	  (insert-file-contents cache-file)
	  (goto-char (point-min))
	  (read (current-buffer))))))

(defun fb2-reader-add-to-cache (filename data)
  "Add to cache rendered DATA for FILENAME.

Replace already added data if presented."

  (fb2-reader-remove-from-cache filename)
  (let ((idx-filename (f-join fb2-reader-settings-dir fb2-reader-index-filename))
	(cache-filename (f-join fb2-reader-settings-dir
				(fb2-reader-gen-cache-file-name filename)))
	(index (fb2-reader-cache-index)))
    (with-temp-file cache-filename
      (set-buffer-file-coding-system 'utf-8)
      (insert ";; fb2-reader.el -- read fb2 books  ")
      (insert "file contains fb2-reader book cache, don't edit.\n")
      (insert "\n")
      (insert (prin1-to-string data)))
    
    (push (list fb2-reader-file-name
		(file-attribute-modification-time
		 (file-attributes fb2-reader-file-name))
 		cache-filename)
	  index)
    (fb2-reader-save-cache-index idx-filename (-take fb2-reader-max-in-cache index))))


(defun fb2-reader-remove-from-cache (filename)
  "Remove FILENAME from cache."

  (when-let ((cache-file (cl-second
			  (alist-get filename (fb2-reader-cache-index) nil nil 'equal)))
	     (index (fb2-reader-cache-index)))
    (f-delete cache-file)
    (setq index (remove filename index))
    (fb2-reader-save-cache-index
     (f-join fb2-reader-settings-dir fb2-reader-index-filename)
     index)))

(defun fb2-reader-restore-buffer (&optional buffer)
  "Restore BUFFER from cache. Restore current if arg missed."

  (or buffer (setq buffer (current-buffer)))
  (when (fb2-reader-cache-avail-p
	 (buffer-local-value 'fb2-reader-file-name buffer) 't)
    (let ((inhibit-null-byte-detection t))
      (with-current-buffer buffer
  (setq buffer-read-only 't)
  (set-buffer-modified-p nil)
  (setq buffer-read-only nil)
  (erase-buffer)
  (set-buffer-file-coding-system 'utf-8)
  (insert (fb2-reader-get-cache fb2-reader-file-name))
  (if fb2-reader-show-images
      (fb2-reader-restore-images))
  (if fb2-reader-restore-position
      (fb2-reader-restore-pos)
    (goto-char (point-min)))
  (setq buffer-read-only nil)
  (set-buffer-modified-p nil)))))

(defun fb2-reader--refresh-buffer (&optional buffer)
  "Rerender book opened in BUFFER."
  (setq buffer (or buffer (current-buffer)))
  (let ((book (fb2-reader-parse-file
	       (buffer-local-value 'fb2-reader-file-name buffer))))
    (fb2-reader-save-pos buffer)
    (fb2-reader-render-async book
			     (lambda (result)
			       (with-current-buffer buffer
				 (fb2-reader-add-to-cache fb2-reader-file-name
							  (read (concat "#" result)))
				 (fb2-reader-restore-buffer)
				 (message "Document %s reloaded" fb2-reader-file-name))))))

(defun fb2-reader-refresh ()
  "Reread current book from disk, render and display it."
  (interactive)
  (fb2-reader--assert-mode-p)
  (when (y-or-n-p "During refresh current position may change. Proceed? ")
    (message "Refreshing book asynchronously.")
    (fb2-reader--assert-mode-p)
    (fb2-reader--refresh-buffer)))

(defun fb2-reader-gen-cache-file-name (filepath)
  "Generate file name for FILEPATH."

  (let ((fname (f-base filepath))
	(chars "abcdefghijklmnopqrstuvwxyz0123456789")
	(randstr "")
	randchar
	randnum)
    (while (< (length randstr) 7)
      (setq randnum (% (abs (random)) (length chars))
	    randchar (substring chars randnum (1+ randnum))
	    randstr (concat randstr randchar)))
    (format "%s%s.el" fname randstr)))


(defun fb2-reader-positions ()
  "Read file with saved positions and return alist."

  (fb2-reader-load-settings 'fb2-reader-load-file
			    fb2-reader-position-filename))

(defun fb2-reader-save-pos (&optional buffer)
  "Save current position in BUFFER."

  (or buffer (setq buffer (current-buffer)))
  (let ((pos-path (f-join fb2-reader-settings-dir
			  fb2-reader-position-filename))
	(filename (buffer-local-value 'fb2-reader-file-name buffer))
	(pos-entry (list fb2-reader-file-name (point))))
    (with-temp-file pos-path
      (insert (prin1-to-string
	       (cons pos-entry
		     (assoc-delete-all filename (fb2-reader-positions))))))))

(defun fb2-reader-save-all-pos ()
  "Save positions in all fb2-reader buffers."

  (dolist (buffer (buffer-list))
    (if (eq (buffer-local-value 'major-mode buffer) 'fb2-reader-mode)
	(fb2-reader-save-pos buffer))))

(defun fb2-reader-restore-pos (&optional buffer)
  "Restore position in current buffer or BUFFER."

  (or buffer (setq buffer (current-buffer)))
  (let* ((filename (buffer-local-value 'fb2-reader-file-name buffer))
	      (pos (car (alist-get filename (fb2-reader-positions) nil nil 'equal))))
    (with-current-buffer buffer (goto-char (or pos (point-min))))))


(defun fb2-reader-read-fb2-zip (file)
  "Read book from fb2.zip FILE.
Book name should be the same as archive except .zip extension."
  (let ((tmpdir (concat (make-temp-file
			 (concat (f-base file) "-")
			 'directory) (f-path-separator)))
	fb2-file parsed)
    (call-process "unzip" nil nil nil "-d" tmpdir file)
    (dolist (file (f-files tmpdir))
      (if (equal "fb2" (f-ext file))
	  (setq fb2-file file)))
    (if (not file)
	(user-error "Archive %s don't contain .fb2 file" file))
    (with-temp-buffer
      (insert-file-contents fb2-file)
      (setq parsed (buffer-string)))
    (f-delete tmpdir 't)
    parsed))

(defun fb2-reader-read-fb2 (file)
  "Read book from .fb2 FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(defun fb2-reader-read-file (file)
  "Read FB2 or FB2.ZIP FILE."
  (if (equal "zip" (f-ext file))
      (fb2-reader-read-fb2-zip file)
    (fb2-reader-read-fb2 file)))

(defun fb2-reader-parse-file (file)
  "Read and parse FB2 FILE, return xml tree."
  (with-temp-buffer
    (insert (fb2-reader-read-file file))
    (libxml-parse-xml-region (point-min) (point-max))))

(defun fb2-reader-show-xml ()
  "Open current book's raw xml."
  (interactive)
  (fb2-reader--assert-mode-p)
  (let* ((bname (format "*XML: %s*" (buffer-name)))
	 (fname fb2-reader-file-name)
	 (buffer-exist-p (get-buffer bname))
	 (buffer (get-buffer-create bname)))
    (switch-to-buffer buffer)
    (unless buffer-exist-p
      (insert (fb2-reader-read-file fname))
      (setq buffer-read-only 't)
      (xml-mode)
      (goto-char (point-min)))))


;; Metadata buffer

(defun fb2-reader-show-info ()
  "Show current book's metadata."
  (interactive)
  (fb2-reader--assert-mode-p)
  (let* ((bname (format "*Info: %s*" (buffer-name)))
	 (fname fb2-reader-file-name)
	 (buffer-exist-p (get-buffer bname))
	 (buffer (get-buffer-create bname))
	 (book (fb2-reader-parse-file fb2-reader-file-name)))
    (switch-to-buffer buffer)
    (unless buffer-exist-p
      (dolist (item (cddr (fb2-reader--get-description book)))
	(fb2-reader-parse-metadata book item))
      (goto-char (point-min))
      (fb2-reader-info-mode))))

(defun fb2-reader-info-backward-category (&optional n)
  "Go N categories backward."
  (interactive "p")
  (setq n (* n -1))
  (fb2-reader--jump-property n 'fb2-reader-info-category))

(defun fb2-reader-info-forward-category (&optional n)
  "Go N categories forward."
  (interactive "p")
  (fb2-reader--jump-property n 'fb2-reader-info-category))

(defun fb2-reader-info-backward-field (&optional n)
  "Go N fields backward."
  (interactive "p")
  (setq n (* n -1))
  (fb2-reader--jump-property n 'fb2-reader-info-field))

(defun fb2-reader-info-forward-field (&optional n)
  "Go N fields forward."
  (interactive "p")
  (fb2-reader--jump-property n 'fb2-reader-info-field))

(defvar fb2-reader-info-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n") 'fb2-reader-info-forward-field)
    (define-key map (kbd "p") 'fb2-reader-info-backward-field)
    (define-key map (kbd "N") 'fb2-reader-info-forward-category)
    (define-key map (kbd "P") 'fb2-reader-info-backward-category)
    map))

(define-derived-mode fb2-reader-info-mode special-mode "FB2 Info"
  "Major mode for reading FB2 metadata.
\\{fb2-reader-info-mode-map}"

  (setq buffer-read-only 't
	truncate-lines 1
	fill-column (round (* 1.5 fb2-reader-page-width))) ;Dirty hack - because width of annotation
					;block is something like page-width + "annotation" word,
					;and fill column should be more than it.
  (buffer-disable-undo))


(defvar fb2-reader-mode-map
  (let ((map (make-sparse-keymap)))
  (define-key map (kbd "n") 'fb2-reader-forward-visible-link)
  (define-key map (kbd "]") 'fb2-reader-forward-chapter)
  (define-key map (kbd "p") 'fb2-reader-backward-visible-link)
  (define-key map (kbd "[") 'fb2-reader-backward-chapter)
  (define-key map (kbd "l") 'fb2-reader-link-back)
  (define-key map (kbd "B") 'fb2-reader-link-back)
  (define-key map (kbd "r") 'fb2-reader-link-forward)
  (define-key map (kbd "N") 'fb2-reader-link-forward)
  (define-key map (kbd "g") 'fb2-reader-refresh)
  (define-key map (kbd "v") 'fb2-reader-show-xml)
  (define-key map (kbd "i") 'fb2-reader-show-info)
  (define-key map (kbd "j") 'imenu)
  map))


;;;###autoload
(define-derived-mode fb2-reader-mode special-mode "FB2"
  "Major mode for reading FB2 books.
\\{fb2-reader-mode-map}"

  (setq fb2-reader-file-name (buffer-file-name)
	buffer-read-only nil
	truncate-lines 1
	fill-column fb2-reader-page-width)
  (buffer-disable-undo)
  (set-visited-file-name nil t) ; disable autosaves and save questions
  (add-hook 'kill-buffer-hook #'fb2-reader-save-pos nil t)
  (add-hook 'quit-window-hook #'fb2-reader-save-pos nil t)
  ;; (add-hook 'change-major-mode-hook 'fb2-reader-save-curr-buffer nil t)
  (add-hook 'kill-emacs-hook #'fb2-reader-save-all-pos)
  (fb2-reader-ensure-settingsdir)
  (erase-buffer)
  (let ((bufname (buffer-name))
	book)
    ;; (push "~/Src/Linux/_my/fb2-reader" load-path)
    (if (fb2-reader-cache-avail-p fb2-reader-file-name 't)
	(fb2-reader-restore-buffer)
      (setq book (fb2-reader-parse-file fb2-reader-file-name))
      (setq-local cursor-type nil)
      (insert (propertize "Rendering in process, please wait." 'face (list (cons :height (list fb2-reader-title-height)))))
      (fill-region (point-min) (point-max) 'center)
      (fb2-reader-render-async book
			       (lambda (result)
				 (with-current-buffer bufname
				   ;; For some reason propertized string returned from async process
				   ;; loses hash at it's beginning.
				   (fb2-reader-add-to-cache fb2-reader-file-name
							    (read (concat "#" result)))
				   (fb2-reader-restore-buffer)
				   (kill-local-variable 'cursor-type)))))
    (fb2-reader-imenu-setup)
    (if fb2-reader-title-in-headerline
	(fb2-reader-set-up-header-line))
    (setq visual-fill-column-center-text 't)
    (visual-fill-column-mode)))

(provide 'fb2-reader)

;;; fb2-reader.el ends here
