;;; fb2-reader.el --- Read FB2 and FB2.ZIP documents -*- lexical-binding: t; -*-
;; 184
;; Copyright (c) 2021 Dmitriy Pshonko <jumper047@gmail.com>

;; Author: Dmitriy Pshonko <jumper047@gmail.com>
;; URL: https://github.com/jumper047/fb2-reader
;; Package-Version: 20211214.954
;; Package-Commit: 9dcc0801a7dd302ee0620781ea17868895d3f082
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
;; - table of content in separate buffer
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
;;      :commands (fb2-reader-continue)
;;      :custom
;;      ;; This mode renders book with fixed width, adjust to your preferences.
;;      (fb2-reader-page-width 120)
;;      (fb2-reader-image-max-width 400)
;;      (fb2-reader-image-max-height 400))
;;
;; Usage:
;; Just open any fb2 book, or execute command =fb2-reader-continue=


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
  "Path to directory with saved places etc."
  :type 'directory
  :group 'fb2-reader)

(defcustom fb2-reader-cache-dir (expand-file-name "fb2-reader" user-emacs-directory)
  "Path to directory with cached books."
  :type 'directory
  :group 'fb2-reader)

(defcustom fb2-reader-title-in-headerline t
  "Show current chapter's title in headerline."
  :type 'boolean
  :group 'fb2-reader)

(defcustom fb2-reader-hide-cursor t
  "Enable `fb2-reader-no-cursor-mode' at mode's start."
  :type 'boolean
  :group 'fb2-reader)

(defcustom fb2-reader-restore-position t
  "Restore last viewed position on book's opening."
  :type 'boolean
  :group 'fb2-reader)

(defcustom fb2-reader-hide-nobreak t
  "Hide nobreak character in fb2-reader buffer."
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

(defcustom fb2-reader-max-in-cache 20
  "Maximum number of files stored in cache."
  :type 'integer
  :group 'fb2-reader)

(defcustom fb2-reader-toc-indent 2
  "Indentation for each level in outline buffer."
  :type 'integer
  :group 'fb2-reader)

(defcustom fb2-reader-splash-text nil
  "Custom text on loading splash screen.
If nil \"Loading, please wait\" translated to book's language
will be used. Enter your variant if you need something special."
  :type 'string
  :group 'fb2-reader)

(defface fb2-reader-splash
  '((t (:height 1.5 :inherit default)))
  "Face for splash screen text about book rendering"
  :group 'fb2-reader)

(defface fb2-reader-info-field
  '((t (:weight bold)))
  "Face for field name in book info buffer."
  :group 'fb2-reader)

(defface fb2-reader-info-category
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
 
(defvar fb2-reader-face-heights nil
  "Variable to put face heights on async rendering.
Variable should be setted only in async process.")

(defvar-local fb2-reader-file-name nil
  "Book's filename (replaces buffer-file-name).")

(defvar-local fb2-reader-link-pos nil
  "Last used link's position.")

(defvar-local fb2-reader-link-target-pos nil
  "Last used link's target.")

(defvar-local fb2-reader-header-line-toc nil
  "List of chapters for header line.")

(defvar-local fb2-reader-toc-fb2-buffer nil
  "In outline this var holds name of the fb2-reader buffer.")

(defvar-local fb2-reader-toc-fb2-window nil
  "In outline this var holds name of the fb2-reader window.")

(defvar-local fb2-reader-rendering-future nil
  "Rendering future for current buffer")

(defvar-local fb2-reader--link-is-visible-p nil
  "Keeps result of previous execution of `fb2-reader-visible-link-p'")

(defconst fb2-reader-header-line-format
  '(:eval (list (propertize " " 'display '((space :align-to 0)))
		(fb2-reader-header-line-text))))

(defvar display-line-numbers-mode)

;; Appearance settings
(defgroup fb2-reader-appearance nil
  "Variables controlling book's appearance.
Faces, indents, etc."
  :group 'fb2-reader)

(defvar fb2-reader-face-names
  '(fb2-reader-default
    fb2-reader-title
    fb2-reader-poem
    fb2-reader-cite
    fb2-reader-text-author)
  "List of names, should be injected into async processes.")

(defcustom fb2-reader-default-indent 0
  "Indent for plain text in document."
  :type 'int
  :group 'fb2-reader-appearance)

(defcustom fb2-reader-default-alignment 'full
  "Aligment for plain text in document."
  :type '(choice (const :tag "Full" full)
		 (const :tag "Left" left)
		 (const :tag "Right" right)
		 (const :tag "Center" center))
  :group 'fb2-reader-appearance)

(defface fb2-reader-default
  '((t (:inherit default)))
  "Default face for fb2-reader buffer."
  :group 'fb2-reader-appearance)

(defcustom fb2-reader-title-indent 2
  "Indent for plain text in document."
  :type 'int
  :group 'fb2-reader-appearance)

(defcustom fb2-reader-title-alignment 'full
  "Aligment for titles in document."
  :type '(choice (const :tag "Full" full)
		 (const :tag "Left" left)
		 (const :tag "Right" right)
		 (const :tag "Center" center))
  :group 'fb2-reader-appearance)

(defface fb2-reader-title
  '((t (:height 1.4 :inherit fb2-reader-default)))
  "Face for titles in fb2-reader buffer."
  :group 'fb2-reader-appearance)

(defcustom fb2-reader-poem-indent 0
  "Indent for plain text in document."
  :type 'int
  :group 'fb2-reader-appearance)

(defcustom fb2-reader-poem-alignment 'full
  "Aligment for poems in document."
  :type '(choice (const :tag "Full" full)
		 (const :tag "Left" left)
		 (const :tag "Right" right)
		 (const :tag "Center" center))
  :group 'fb2-reader-appearance)

(defface fb2-reader-poem
  '((t (:inherit fb2-reader-default)))
  "Face for poem tag in fb2-reader buffer."
  :group 'fb2-reader-appearance)

(defcustom fb2-reader-cite-indent 4
  "Indent for plain text in document."
  :type 'int
  :group 'fb2-reader-appearance)

(defcustom fb2-reader-cite-alignment 'full
  "Aligment for cites in document."
  :type '(choice (const :tag "Full" full)
		 (const :tag "Left" left)
		 (const :tag "Right" right)
		 (const :tag "Center" center))
  :group 'fb2-reader-appearance)

(defface fb2-reader-cite
  '((t (:inherit fb2-reader-default)))
  "Face for cite tag in fb2-reader buffer."
  :group 'fb2-reader-appearance)

(defcustom fb2-reader-header-line-indent 2
  "Indent for plain text in document."
  :type 'int
  :group 'fb2-reader-appearance)

(defcustom fb2-reader-header-line-alignment 'center
  "Aligment for titles in document."
  :type '(choice (const :tag "Left" left)
		 (const :tag "Right" right)
		 (const :tag "Center" center))
  :group 'fb2-reader-appearance)

(defface fb2-reader-header-line
  '((t (:height 1.4 :inherit header-line)))
  "Face for header line with current title."
  :group 'fb2-reader-appearance)

(defcustom fb2-reader-text-author-alignment 'right
  "Aligment for text author's name in document."
  :type '(choice (const :tag "Full" full)
		 (const :tag "Left" left)
		 (const :tag "Right" right)
		 (const :tag "Center" center))
  :group 'fb2-reader-appearance)

(defface fb2-reader-text-author
  '((t (:inherit fb2-reader-default)))
  "Face for cite tag in fb2-reader buffer."
  :group 'fb2-reader-appearance)

(defface fb2-reader-link
  '((t (:inherit link)))
  "Face for links in fb2-reader buffer."
  :group 'fb2-reader-appearance)
;; Fb2 parsing

(defun fb2-reader-parse (book item &optional tags face alignment indent)
  "Recursively parse ITEM and insert it into the buffer.
BOOK is whole xml tree (it is needed in case)"

  (or face (setq face '((:inherit fb2-reader-default))))
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
	     (fb2-reader--format-string book body tags face current-tag fb2-reader-text-author-alignment indent))
	    ((equal current-tag 'section)
	     (fb2-reader--parse-section book attributes body tags face current-tag))
	    ((equal current-tag 'poem)
	     (fb2-reader--parse-poem book body tags))
	    ((equal current-tag 'title)
	     (fb2-reader--parse-title book body tags))
	    ((equal current-tag 'cite)
	     (fb2-reader--parse-cite book body tags))
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
					face current-tag alignment indent))
	    ((equal current-tag 'strong)
	     (fb2-reader-parse book (cl-first body) tags (cons 'bold face)))
	    ((equal current-tag 'emphasis)
	     (fb2-reader-parse book (cl-first body) tags (cons 'italic face)))
	    ('t
	     (dolist (subitem body)
	       (fb2-reader-parse book subitem (cons current-tag tags) face)))))))

(defun fb2-reader-face-heights ()
  "Get alist with pairs of face names and their heights.
Order of elements should be persistent: it should be as in
`fb2-reader-face-names'. If variable with same name is not nil
it should happen only when function executed inside async process
return that variable, otherwise calculate heights."
  (if (null fb2-reader-face-heights)
      (let (face-heights)
	(dolist (name fb2-reader-face-names)
	  (push (cons name (fb2-reader-get-face-height name))
		face-heights))
	face-heights)
    fb2-reader-face-heights))

(defun fb2-reader-get-face-height (face)
  "Take font height from FACE. Face can be face or alist."
  (let ((height 1)
	height-curr)
    (if (listp face) (setq face (car (alist-get :inherit face))))
    (while (and face (not (equal face 'unspecified)))
      (setq height-curr (face-attribute face :height))
      (if (equal height-curr 'unspecified)
	  (setq height-curr 1.0))
      (setq height (* height(if (and (not (eq height-curr 1)) (integerp height-curr))
				(/ height-curr (face-attribute 'default :height))
			      height-curr))
	    face (face-attribute face :inherit)))
    height))

(defun fb2-reader-fc-for-face (face)
  "Calculate `fill-column' value for FACE.
Needed in case face sets width != 1.
FACE can be a face or list of face attributes.
In second case height of the face in :inherit alist will be
taken into account."
  (if (listp face) (setq face (car (alist-get :inherit face))))
  (let ((height (alist-get face (fb2-reader-face-heights))))
    ;; For some reason on width near 1.2 rendered page became little
    ;; widthier than it should be. 0.96 coefficient should solve it.
    ;; sorry for dirty hack:(
    (round (* 0.96 (/ fb2-reader-page-width height)))))

(defun fb2-reader--format-string (book body tags face curr-tag  alignment indent  &optional indent-first append-newline)
  "Format BODY according to FACE, ALIGNMENT and INDENT and insert it.
BOOK is whole book xml tree, TAGS - fb2 tags, CURR-TAG - current fb2 tag."
  (or indent-first (setq indent-first (if (eq alignment 'center) 0 2)))
  (or append-newline (setq append-newline 't))
  (let* ((point-start (point))
	 (indent (+ indent 1))
	 ;; 1 appended to indent because of unwanted behavior
	 ;; of fill-paragraph  function. If fill-prefix equals
	 ;; nil or "" fill-paragraph uses spaces at
	 ;; beginning of the string as fill-prefix. If fill
	 ;; prefix is not empty it works as expected.
	 (prefix (string-join (make-list indent " ")))
	 (prefix-first (string-join (make-list (+ indent indent-first) " ")))
	 (fill-column (- (fb2-reader-fc-for-face face) indent)))

    (insert (propertize prefix-first 'fb2-reader-tags tags))
    (dolist (subitem body)
      (fb2-reader-parse book subitem (cons curr-tag tags) face alignment indent))
    (if append-newline
	(insert (propertize "\n" 'fb2-reader-tags tags)))
    (setq fill-prefix prefix)
    (fill-region point-start (point) alignment)
    (if (and
	 (eq alignment 'center)
	 ;; Check below means face's height not equal 1
	 (not (equal fill-column fb2-reader-page-width)))
	(fb2-reader--recenter-region point-start (point)
   				     (alist-get (car (alist-get :inherit face)) (fb2-reader-face-heights))))))

(defun fb2-reader--center-prefix (linelen strlen height)
  "Calculate number of spaces needed to center string.
String to center has STRLEN symbols, every symbol has HEIGHT.
LINELEN is maximum line's length (page width)"
  (round (/ (- linelen (* strlen height)) 2)))

(defun fb2-reader--recenter-region (begin end height)
  "Recenter region from BEGIN to END.
HEIGHT is font's height (should be coefficient).
Every string's length in region should be less or equal fill column.
Because of strange `fill-region' behavior every line in region should
be recenered \(For some reason when `fill-region' invoked inside
fb2r-format-string,every space or tab added to line not inherit
:height property, and resulting line length became longer or shorter
than planned\)"
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
	  (setq prefix (fb2-reader--center-prefix fb2-reader-page-width (length linestr) height))
	  (move-beginning-of-line 1)
	  (kill-line)
	  (insert (s-repeat prefix " "))
	  (insert linestr))))))

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

(defun fb2-reader--parse-title (book body tags)
  "Parse and insert BODY (BOOK 's part) as title."

  (let* ((face '((:inherit fb2-reader-title)))
	 start
	 end)
    (when (> (line-number-at-pos) 1)	;don't insert separator if this is first title
      (insert "\n\n"))
    (setq start (point))
    (dolist (subitem body)
      (fb2-reader-parse book subitem (cons 'title tags) face
			fb2-reader-title-alignment
			fb2-reader-title-indent))
    (setq end (point))
    (insert "\n")
    (add-text-properties start end '(fb2-reader-title t))))

(defun fb2-reader--parse-cite (book body tags)
  "Parse BODY as cite and insert it.
BOOK is whole book xml tree, TAGS - fb2 tags."
  (let* ((indent fb2-reader-cite-indent)
	 (align fb2-reader-cite-alignment)
	 (face '((:inherit fb2-reader-cite))))
    (fb2-reader--insert-newline-maybe)
    (dolist (subitem body)
      (fb2-reader-parse book subitem (cons 'cite tags) face align indent))
    (fb2-reader--insert-newline-maybe)))

(defun fb2-reader--parse-poem (book body tags)
  "Parse BODY as poem and insert it.
BOOK is whole book xml tree, TAGS - fb2 tags."
  (dolist (subitem body)
    (let ((subtags (cons 'poem tags))
	  (subtag (cl-first subitem))
	  (face '((:inherit fb2-reader-poem))))
      (if (equal subtag 'stanza)
	  (fb2-reader--insert-newline-maybe))
      (fb2-reader-parse book subitem (cons subtag subtags) face
			fb2-reader-poem-alignment
			fb2-reader-poem-indent)))
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
BOOK is whole book's xml tree.  TAGS are list of fb2 tags."
  (when-let* ((id (replace-regexp-in-string "#" "" (cdr (car attributes))))
	      (binary (fb2-reader--find-binary book id))
	      (type-str (alist-get 'content-type (cl-second binary)))
	      (data-str (cl-third binary)))
    (list type-str data-str tags)))

(defun fb2-reader--insert-image (data type &optional tags use-prefix)
  "Generate image from DATA of type TYPE and insert it at point.

 Property fb2-reader-tags will be set to TAGS and appended
to placeholder.
 Center image if USE-PREFIX."

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
  "Parse ITEM and insert as fb2 metadata.
BOOK should contain whole book's xml tree."
  (let ((current-tag (cl-first item))
	;; (attributes (cl-second item))
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
	       (progn (insert (format "\n%s\n" (fb2-reader--format-symbol current-tag 'fb2-reader-info-category)))
		      (dolist (subitem body)
			(fb2-reader-parse-metadata book subitem)))
	     (insert (format "%s: %s\n" (fb2-reader--format-symbol current-tag 'fb2-reader-info-field) (if (stringp (car body)) (car body) " -"))))))))

(defun fb2-reader--format-symbol (symbol face)
  "Take SYMBOL, transform it it readable string and apply FACE."
  (let ((prop (cond ((equal face 'fb2-reader-info-field)
		     'fb2-reader-info-field)
		    ((equal face 'fb2-reader-info-category)
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
					   (cl-second (alist-get 'last-name fields)))))))
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

;; Splash screen

(defun fb2-reader-splash-text (item)
  "Insert splash screent text.
If no custom text, take text's language from ITEM."
  (if (not (null fb2-reader-splash-text))
      fb2-reader-splash-text
    (let ((lang (if (null item) "en" (cl-third item))))
      (fb2-reader-splash-text-for-lang lang))))

(defun fb2-reader-splash-text-for-lang (lang)
  "Get splash text depending on LANG."
  (cond
   ;; ((equal lang "ab")) ;; Abhazia
   ((equal lang "az")
    "Yüklənir Zəhmət olmasa gözləyin. ")
   ((equal lang "sq")
    "Duke u ngarkuar, ju lutem prisni.")
   ((equal lang "en")
    "Loading, please wait.")
   ((equal lang "hy")
    "Բեռնվում է, խնդրում ենք սպասել.")
   ((equal lang "be")
    "Ідзе загрузка, калі ласка, пачакайце.")
   ((equal lang "bg")
    "Зареждане, моля, изчакайте.")
   ((equal lang "hu")
    "Betöltés; kérem várjon.")
   ((equal lang "vi")
    "Tải vui lòng đợi.")
   ((equal lang "nl")
    "Laden even geduld aub.")
   ((equal lang "el")
    "Φορτώνει παρακαλώ περιμένετε.")
   ;; ((equal lang "he")
   ;; "טוען אנא המתן.")	    ;;Israel
   ((equal lang "es")
    "Cargando, por favor espere.")
   ((equal lang "it")
    "Caricamento in corso, attendere prego.")
   ((equal lang "kk")
    "Жүктелуде, күте тұрыңыз.")
   ((equal lang "ky")
    "Жүктөлүүдө, күтө туруңуз.")
   ((equal lang "zh")
    "加载请稍候")
   ((equal lang "ko")
    "로딩 중 기다려주세요.")
   ((equal lang "la")
    "Onerans, obsecro, expecta.")
   ((equal lang "lv")
    "Iekraušana, lūdzu, uzgaidiet.")
   ((equal lang "lt")
    "Pakraunama, palaukite.")
   ((equal lang "mk")
    "Се вчитува, Ве молиме почекајте.")
   ;; ((equal lang "mo"))    ;; Moldavia
   ((equal lang "mn")
    "Ачаалж байна, түр хүлээнэ үү.")
   ((equal lang "de")
    "Wird geladen, bitte warten.")
   ((equal lang "no")
    "Laster Vennligst vent.")
   ;; ((equal lang "fa")
   ;; "در حال بارگذاری لطفا صبر کنید.")    ;; Persian
   ((equal lang "pl")
    "Ładowanie, proszę czekać.")
   ((equal lang "pt")
    "Carregamento, aguarde, por favor.")
   ((equal lang "ru")
    "Загружается, пожалуйста, подождите.")
   ;; ((equal lang "sa"))    ;; Sanscrit
   ((equal lang "sk")
    "Načítava sa, počkajte, prosím.")
   ((equal lang "sl")
    "Načítava sa, počkajte, prosím.")
   ((equal lang "tg")
    "Бор карда мешавад, лутфан интизор шавед.")
   ((equal lang "tt")
    "Йөкләү, зинһар, көтегез.")
   ((equal lang "tr")
    "Yükleniyor lütfen bekleyin.")
   ((equal lang "uz")
    "Yuklanmoqda, kuting.")
   ((equal lang "uk")
    "Завантаження, будь ласка, зачекайте.")
   ;; ((equal lang "cy"))    ;; Wels
   ((equal lang "fi")
    "Ladataan, odota.")
   ((equal lang "fr")
    "Chargement, veuillez patienter.")
   ((equal lang "cs")
    "Načítá se, vyčkejte prosím.")
   ((equal lang "sv")
    "Laddar, vänligen vänta.")
   ((equal lang "eo")
    "Ŝarĝante, bonvolu atendi.")
   ((equal lang "ja")
    "読み込み中。。。待って下さい。")
   ((equal lang "et")
    "Laadimine, palun oodake.")
   (t
    "Loading, please wait.")))

(defun fb2-reader-splash-title (item)
  "Insert title taken from ITEM."
  (let ((title (cl-third item)))
    (insert (propertize title 'face 'fb2-reader-title))
    (newline)))

(defun fb2-reader-splash-cover (book item)
  "Insert cover for splash screen.
Take cover from BOOK according to data in ITEM."
  (let* ((attrs (cl-second (cl-third item)))
	 (imgdata (fb2-reader--extract-image-data book attrs))
	 (type-str (cl-first imgdata))
	 (data-str (cl-second imgdata)))
    (fb2-reader--insert-image data-str type-str nil t)
    (newline)))

(defun fb2-reader-splash-author (item)
  "Insert author's name, taken from ITEM."
  (let* ((fields (cddr item))
	 (name (s-join " " (-non-nil (list (cl-second (alist-get 'first-name fields))
					   (cl-second (alist-get 'middle-name fields))
					   (cl-second (alist-get 'nick fields))
					   (cl-second (alist-get 'last-name fields)))))))
    (when name
      (insert (propertize name 'face 'fb2-reader-title))
      (newline))))

(defun fb2-reader-splash-screen (book)
  "Insert loading screen for BOOK."
  (let ((fill-column fb2-reader-page-width)
	(title-item (fb2-reader--get-title book))
	(cover-item (fb2-reader--get-cover book))
	(name-item (fb2-reader--get-author book))
	(lang-item (fb2-reader--get-lang book))
	(start (point))
	(height (face-attribute 'fb2-reader-title :height))
	(splash-height (face-attribute 'fb2-reader-title :height)))
    (if name-item (fb2-reader-splash-author name-item))
    (if title-item (fb2-reader-splash-title title-item))
    (fb2-reader--recenter-region start (point) height)
    (if cover-item (fb2-reader-splash-cover book cover-item))
    (setq start (point))
    (insert (propertize (fb2-reader-splash-text lang-item)
			'face 'fb2-reader-splash))
    (fb2-reader--recenter-region start (point-max) splash-height)))

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

(defun fb2-reader--get-lang (book)
  "Get lang node from BOOK."
  (fb2-reader--find-subitem-recursively (cddr book) 'description 'title-info 'lang))

(defun fb2-reader--get-program (book)
  "Get program used to generate BOOK."
  (fb2-reader--find-subitem-recursively (cddr book) 'description 'document-info 'program-used))

(defun fb2-reader-render-html (book)
  "Render2 BOOK and insert it into the current buffer."

  (setq-local fill-column fb2-reader-page-width)
  (dolist (item (cdddr book))
    (fb2-reader-parse book item)))

(defun fb2-reader-render-xml (book)
  "Render2 BOOK and insert it into the current buffer."

  (setq-local fill-column fb2-reader-page-width)
  (dolist (body (fb2-reader--get-bodies book))
    (fb2-reader-parse book body)))

(defun fb2-reader-render-async (book render-fn callback)
  "Render BOOK asynchronously using RENDER-FN, launch CALLBACK with result."
  (async-start
   `(lambda ()
      ,(async-inject-variables "\\`\\(fb2-reader\\)-")
      ,(async-inject-variables "book")
      ,(async-inject-variables "render-fn")
      (setq fb2-reader-face-heights (quote ,(fb2-reader-face-heights)))
      (setq load-path (quote ,load-path))
      (require 'fb2-reader)
      (with-temp-buffer
	(funcall (quote ,render-fn) (quote ,book))
	(prin1-to-string (buffer-substring (point-min) (point-max)))))
   callback))

;; Utilities
(defun fb2-reader-assert-mode-p ()
  "Check is current buffer is suitable to run command and throw error otherwise."
  (unless (eq major-mode 'fb2-reader-mode)
    (user-error "Command suitable only for fb2-reader buffers")))

(defun fb2-reader-toc-assert-mode-p ()
  "Check is current buffer is suitable to run command and throw error otherwise."
  (unless (eq major-mode 'fb2-reader-toc-mode)
    (user-error "Command suitable only for fb2-reader-toc buffers")))

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

(defun fb2-reader-create-headerline-data ()
  "Create reversed TOC for headerline.
Each line in returned list consists of point, text prepared for
header line and text for echo."
  (save-excursion
    (goto-char (point-min))
    (let ((max-length (round (/ fb2-reader-page-width
				(face-attribute 'fb2-reader-header-line :height))))
	  start next-change plist displayed filler echo index)
      (while (not (eobp))
	(setq start (point)
	      next-change (or (next-single-property-change (point) 'fb2-reader-title)
			      (point-max))
	      plist (text-properties-at (point)))
	(when (plist-member plist 'fb2-reader-title)
	  (while (< (point) next-change)
	    (setq echo nil)
	    (forward-line 1)
	    (setq displayed (s-trim (s-collapse-whitespace (buffer-substring-no-properties start (point)))))
	    (if (>= (length displayed) max-length)
		(setq displayed (concat (s-left (- max-length 3) displayed) "...")
		      echo (buffer-substring-no-properties start next-change)))
	    
	    (setq filler (cond ((eq fb2-reader-header-line-alignment 'left)
				(s-repeat (1+ fb2-reader-header-line-indent) " "))
			       ((eq fb2-reader-header-line-alignment 'right)
				(s-repeat (round(- max-length
   						   (length displayed)) ) " "))
			       ((eq fb2-reader-header-line-alignment 'center)
				(s-repeat (round (/ (- max-length
						       (length displayed)) 2)) " ")))
		  displayed (concat filler
				    displayed))
	    (push (list (point)
			(propertize displayed
				    'face 'fb2-reader-header-line
				    'help-echo echo))
		  index)))
	(goto-char next-change))
      (reverse index))))

(defun fb2-reader-toc-bisect (toc pos)
  "Get TOC entry nearest to POS with bisect algorithm."
  (let* (;(first (caar toc))
	 (last (caar (last toc)))
	 (toc-length (length toc))
	 (mid (car (nth (/ toc-length 2) toc))))
    (if (<= toc-length 2)
	(if (> pos last)
	    (cadr toc)
	  (car toc))
      (if (< pos mid)
	  (fb2-reader-toc-bisect (butlast toc (1- (- toc-length (/ toc-length 2))))
				 pos)
	(fb2-reader-toc-bisect (seq-drop toc (/ toc-length 2)) pos)))))

(defun fb2-reader-header-line-text ()
  "Get text for header line."
  (concat  (if display-line-numbers-mode
	       (s-repeat (+ 2 (line-number-display-width)) " "))
	   (cl-second (fb2-reader-toc-bisect fb2-reader-header-line-toc (window-start)))))

(define-minor-mode fb2-reader-header-line-mode
  "Toggle header line with current chapter"
  :group 'fb2-reader
  :global nil
  (cond
   (fb2-reader-header-line-mode
    (setq fb2-reader-header-line-toc (fb2-reader-create-headerline-data)
	  header-line-format 'fb2-reader-header-line-format))
   (t
    (setq fb2-reader-header-line-toc nil
	  header-line-format nil))))

(defun fb2-reader-set-up-header-line ()
  "Set up header line in current buffer."

  (setf header-line-format 'fb2-reader-header-line-format))

;; Reading from settings

(defun fb2-reader-ensure-dir (dir)
  "Create DIR if necessary."
  (unless (f-exists-p dir)
    (make-directory dir)))

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

(defun fb2-reader--jump-chapter (n)
  "Jump N chapters back or forth, and recenter screen."
  (fb2-reader--jump-property n 'fb2-reader-title)
  (recenter 0)
  (if fb2-reader-header-line-mode
      (scroll-up 1)))

(defun fb2-reader-forward-chapter (&optional n)
  "Go N chapters forward."
  (interactive "p")
  (fb2-reader--jump-chapter n))

(defun fb2-reader-backward-chapter (&optional n)
  "Go N chapters backward."
  (interactive "p")
  (setq n (* n -1))
  (fb2-reader--jump-chapter n))

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

(defun fb2-reader-visible-link-p ()
  "Check if current window contain fb2 links."
  (let ((first-link (next-single-property-change (window-start)
						 'fb2-reader-target)))
    (and first-link (<= first-link (window-end)))))

(defun fb2-reader--jump-to-first-link ()
  "Jump to first visible link on screen.
Don't checking if link is actually visible,
assuming this was checked before."
  (goto-char (window-start))
  (unless (plist-member (text-properties-at (point)) 'fb2-reader-target)
    (fb2-reader--jump-link 1)))

(defun fb2-reader-check-links ()
  "Display cursor if link is visible and place the cursor on it."
  (unless (and (fb2-reader-visible-link-p) (member this-command '(fb2-reader-forward-visible-link-ncm
								  fb2-reader-backward-visible-link-ncm)))
    (setq-local cursor-type nil)))

(defun fb2-reader-forward-visible-link-ncm (&optional n)
  "Go N visible links forward, make cursor visible."
  (interactive "p")
  (when (fb2-reader-visible-link-p)
    (setq-local cursor-type 't)
    (unless (fb2-reader-forward-visible-link n)
      (fb2-reader--jump-to-first-link))))

(defun fb2-reader-backward-visible-link-ncm (&optional n)
  "Go N visible links backwarg, make cursor visible."
  (interactive "p")
  (when (fb2-reader-visible-link-p)
    (setq-local cursor-type  't)
    (unless (fb2-reader-backward-visible-link n)
      (fb2-reader--jump-to-first-link))))

(defvar fb2-reader-no-cursor-mode-map
  (let ((kmap (make-sparse-keymap)))
    (define-key kmap (kbd "C-n") (lambda () (interactive) (scroll-up 1)))
    (define-key kmap (kbd "C-p") (lambda () (interactive) (scroll-down 1)))
    (define-key kmap (kbd "<down>") (lambda () (interactive) (scroll-up 1)))
    (define-key kmap (kbd "<up>") (lambda () (interactive) (scroll-down 1)))
    (define-key kmap (kbd "n") 'fb2-reader-forward-visible-link-ncm)
    (define-key kmap (kbd "p") 'fb2-reader-backward-visible-link-ncm)
    kmap)
  "Keymap used for `fb2-reader-no-cursor-mode'.")

(define-minor-mode fb2-reader-no-cursor-mode
  "Hide cursor and rebind C-n and C-p to scroll window.

\\{fb2-reader-no-cursor-mode-map\}"
  :group 'fb2-reader
  :global nil
  (cond
   (fb2-reader-no-cursor-mode
    (setq cursor-type nil)
    (add-hook 'pre-command-hook 'fb2-reader-check-links nil 't))
   (t
    (setq cursor-type t)
    (remove-hook 'pre-command-hook 'fb2-reader-check-links 't))))

;; Caching

(defun fb2-reader-cache-index ()
  "Read cache index."
  (fb2-reader-load-file (f-join fb2-reader-cache-dir
				fb2-reader-index-filename)))

(defun fb2-reader-save-cache-index (file index)
  "Serialize given cache INDEX and save it to FILE."
  
  (with-temp-file file
    (set-buffer-file-coding-system 'utf-8)
    (insert ";; fb2-reader.el -- read fb2 books  ")
    (insert "file contains cache index, don't edit.\n")
    (insert (prin1-to-string index))
    (insert "\n")))

(defun fb2-reader-cache-avail-p (file &optional actual-only verbose)
  "Check if cache for FILE available.

If ACTUAL-ONLY return 't if cache is existed and actual and
current page width is the same as rendered one.

If VERBOSE display message explaining why result is negative.

Because of changed cache index entry format cache will be
treated as invalid if third element, page-width, is not
presented."
  
  (let ((idx-entry (alist-get file (fb2-reader-cache-index) nil nil 'equal))
	mess)
    (if idx-entry
	(let-alist idx-entry
	  (if actual-only
   	      (progn (setq mess (cond ((not (equal .mtime (file-attribute-modification-time
   							   (file-attributes file))))
   				       "File was changed since it was cached.")
   				      ((not (equal .pagewidth fb2-reader-page-width))
   				       "Page width changed since file was cached.")
   				      ((not (equal .faceheights (fb2-reader-face-heights)))
   		 		       "Face heights changed since file was cached.")))
		     (if (null mess) 't (if verbose (message mess)) nil))
   	    't)))))


(defun fb2-reader-get-cache (file)
  "Load cache for FILE if it exists."

  (when-let ((cache-file (alist-get 'cachename (alist-get file (fb2-reader-cache-index) nil nil 'equal))))
    (fb2-reader-load-file cache-file)))

(defun fb2-reader-add-to-cache (filename data)
  "Add to cache rendered DATA for FILENAME.

Replace already added data if presented."

  (fb2-reader-remove-from-cache filename)
  (let* ((idx-filename (f-join fb2-reader-cache-dir fb2-reader-index-filename))
	 (cache-filename (f-join fb2-reader-cache-dir
				 (fb2-reader-gen-cache-file-name filename)))
	 (index (fb2-reader-cache-index))
	 ;; cache entry is a list whose first element is
	 ;; filename and others are cons of key-value pairs
	 (index-entry (list
		       fb2-reader-file-name
		       (cons 'mtime (file-attribute-modification-time
				     (file-attributes fb2-reader-file-name)))
 		       (cons 'cachename cache-filename)
		       (cons 'pagewidth fb2-reader-page-width)
		       (cons 'faceheights (fb2-reader-face-heights)))))
    (with-temp-file cache-filename
      (set-buffer-file-coding-system 'utf-8)
      (insert ";; fb2-reader.el -- read fb2 books  ")
      (insert "file contains fb2-reader book cache, don't edit.\n")
      (insert "\n")
      (insert (prin1-to-string data)))
    (push index-entry index)
    (fb2-reader-save-cache-index idx-filename (-take fb2-reader-max-in-cache index))))


(defun fb2-reader-remove-from-cache (filename)
  "Remove FILENAME from cache."

  (when-let ((cache-file (alist-get 'cachename
				    (alist-get filename (fb2-reader-cache-index) nil nil 'equal)))
	     (index (fb2-reader-cache-index)))
    (f-delete cache-file)
    (setq index (remove filename index))
    (fb2-reader-save-cache-index
     (f-join fb2-reader-cache-dir fb2-reader-index-filename)
     index)))

(defun fb2-reader-restore-buffer (&optional buffer)
  "Restore BUFFER from cache.  Restore current if arg missed."

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

(defun fb2-reader--refresh-buffer ()
  "Rerender book in current buffer."
  (let ((book (fb2-reader-parse-file fb2-reader-file-name))
	(render-fn 'fb2-reader-render-xml)
	(buffer (current-buffer)))
    (unless book
      (setq book (fb2-reader-parse-file-as-html fb2-reader-file-name)
	    render-fn 'fb2-reader-render-html))
    (unless book (user-error "FB2 document corrupted"))
    (fb2-reader-save-pos buffer)
    (setq fb2-reader-rendering-future
	  (fb2-reader-render-async
	   book
	   render-fn
	   (lambda (result)
	     (with-current-buffer buffer
	       (fb2-reader-add-to-cache fb2-reader-file-name
					(read (concat "#" result)))
	       (fb2-reader-restore-buffer)
	       (if fb2-reader-title-in-headerline
		   (setq fb2-reader-header-line-toc (fb2-reader-create-headerline-data)))
	       (setq fb2-reader-rendering-future nil)
	       (message "Document %s reloaded" fb2-reader-file-name)))))))

(defun fb2-reader-refresh ()
  "Reread current book from disk, render and display it."
  (interactive)
  (unless (or (null fb2-reader-rendering-future)
	      (async-ready fb2-reader-rendering-future))
    (user-error "Wait until current rendering process finished"))
  (fb2-reader-assert-mode-p)
  (when (y-or-n-p "During refresh current position may change.  Proceed? ")
    (message "Refreshing book asynchronously.")
    (fb2-reader-assert-mode-p)
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

  (fb2-reader-load-file (f-join fb2-reader-settings-dir
				fb2-reader-position-filename)))

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

(defun fb2-reader-clean-up ()
  "Clean up things before fb2 buffer quit."
  (fb2-reader-save-pos)
  (let* ((info-buffer (get-buffer (fb2-reader-info-buffer-name)))
	 (info-window (if info-buffer (get-buffer-window info-buffer)))
	 (toc-buffer (get-buffer (fb2-reader-toc-buffer-name)))
	 (toc-window (if info-buffer (get-buffer-window toc-buffer))))
    (if info-window (quit-window 't info-window)
      (if info-buffer (kill-buffer info-buffer)))
    (if toc-window (quit-window 't toc-window)
      (if toc-buffer (kill-buffer toc-buffer)))))

(defun fb2-reader-restore-pos (&optional buffer)
  "Restore position in current buffer or BUFFER."

  (or buffer (setq buffer (current-buffer)))
  (let* ((filename (buffer-local-value 'fb2-reader-file-name buffer))
	 (pos (car (alist-get filename (fb2-reader-positions) nil nil 'equal))))
    (with-current-buffer buffer (goto-char (or pos (point-min))))))

;;;###autoload
(defun fb2-reader-continue ()
  "Continue reading last opened book."
  (interactive)
  (let ((positions (fb2-reader-positions))
	filename)
    (if (null positions)
	(user-error "Can't find saved book positions, you should open at least one"))
    (setq filename (caar positions))
    (if (not (f-exists-p filename))
	(user-error "Last opened book was moved or deleted"))
    (find-file filename)
    (if (not (eq major-mode 'fb2-reader-mode))
	(fb2-reader-mode))))

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

(defun fb2-reader--parse-html-buffer ()
  "Parse current buffer, return xml tree.
First time tries to parse with `libxml-parse-xml-region'.
If result returns nil tries again with `libxml-parse-html-region',
and cutting results to mimic parse-xml result (deleting outer
html and body))."
  (cl-third (cl-third (libxml-parse-html-region (point-min) (point-max)))))

(defun fb2-reader--parse-xml-buffer ()
  "Parse current buffer, return xml tree.
First time tries to parse with `libxml-parse-xml-region'.
If result returns nil tries again with `libxml-parse-html-region',
and cutting results to mimic parse-xml result (deleting outer
html and body))."
  (libxml-parse-xml-region (point-min) (point-max)))

(defun fb2-reader-parse-file (file)
  "Read and parse FB2 FILE, return xml tree.
This function tries to parse file with parse-xml first,
and switches to parse-html on failure."
  (with-temp-buffer
    (insert (fb2-reader-read-file file))
    (let ((tree (fb2-reader--parse-xml-buffer)))
      (or tree (fb2-reader--parse-html-buffer)))))

(defun fb2-reader-parse-file-as-xml (file)
  "Read and parse FB2 FILE as xml, return xml tree."
  (with-temp-buffer
    (insert (fb2-reader-read-file file))
    (fb2-reader--parse-xml-buffer)))

(defun fb2-reader-parse-file-as-html (file)
  "Read and parse FB2 FILE as html, return xml tree."
  ;; Html parser is fallback solution, so this error will indicate
  ;; something goes wrong.
  (message "Trying to parse FB2 as html.")
  (with-temp-buffer
    (insert (fb2-reader-read-file file))
    (fb2-reader--parse-html-buffer)))

(defun fb2-reader-show-xml ()
  "Open current book's raw xml."
  (interactive)
  (fb2-reader-assert-mode-p)
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

(defun fb2-reader-reopen-as-archive ()
  "Reopen current FB2.ZIP document as archive."
  (interactive)
  (fb2-reader-assert-mode-p)
  (unless (equal (f-ext fb2-reader-file-name) "zip")
    (user-error "Document is not a zip archive"))
  (with-current-buffer (find-file-literally fb2-reader-file-name)
    (archive-mode)))

;; TOC outline

(defun fb2-reader-create-toc-data (&optional fb2-buffer)
  "Get data needed for building toc from FB2-BUFFER."
  (unless fb2-buffer (setq fb2-buffer (current-buffer)))
  (with-current-buffer fb2-buffer
    (save-excursion
      (goto-char (point-min))
      (let (next-change plist index section-hack tags indent title)
	(while (not (eobp))
	  (setq next-change (or (next-single-property-change
				 (point) 'fb2-reader-title)
				(point-max))
		plist (text-properties-at (point)))
	  (when (plist-member plist 'fb2-reader-title)
	    (setq title (s-trim (s-collapse-whitespace
				 (buffer-substring-no-properties
				  (point) next-change)))
		  ;; This is kinda hack because in future I'll add fb-r-tags
		  ;; to spaces too, so I'll take this property from plist
		  section-hack (or (if (plist-member plist 'fb2-reader-tags)
				       (point))
				   (next-single-property-change (point)
								'fb2-reader-tags)
				   (point-max))
		  tags (get-text-property section-hack 'fb2-reader-tags)
		  indent (--count (equal it 'section) tags))
	    (push (list title (point) indent) index))
	  (goto-char next-change))
	(reverse index)))))

(defun fb2-reader-toc-insert-outline (toc-data)
  "Insert outline with  table of content from TOC-DATA."
  (dolist (toc-item toc-data)
    (let ((title (cl-first toc-item))
	  (point (cl-second toc-item))
	  (depth (cl-third toc-item)))
      ;; I found a book with title containing only newline
      ;; without a text. It broke button creation, so I'll
      ;; get rid of definitely wrong titles.
      (when (and (> (length title) 0))
	(insert-text-button
	 (concat
	  (make-string (* (max 0 (1- depth)) fb2-reader-toc-indent) ?\s)
	  title)
	 'type 'fb2-reader-toc
	 'fb2-reader-outline-pos point)
	(newline)))))

(defun fb2-reader-toc-display-link (&optional pos)
  "Go to target at POS in fb2-reader buffer, but don't switch to it."
  (interactive)
  (fb2-reader-toc-assert-mode-p)
  (unless pos (setq pos (point)))
  (let ((target (fb2-reader-toc-target-at-pos pos)))
    (unless target
      (user-error "There is no destination at point"))
    (with-selected-window (fb2-reader-toc-get-fb2-window t)
      (goto-char target)
      (recenter 0)
      (if fb2-reader-header-line-mode
	  (scroll-up 1)))))

(defun fb2-reader-toc-follow-link ()
  "Follow link under point in toc buffer."
  (interactive)
  (fb2-reader-toc-display-link)
  (select-window (fb2-reader-toc-get-fb2-window t)))

(defun fb2-reader-toc-follow-link-quit ()
  "Follow link under point in toc buffer and quit toc window."
  (interactive)
  (fb2-reader-toc-display-link)
  (fb2-reader-toc-quit))

(defun fb2-reader-toc-mouse-display-link (event)
  "Display link corresponding to the EVENT position."
  (interactive "@e")
  (fb2-reader-toc-display-link (posn-point (event-start event))))

(defun fb2-reader-toc-target-at-pos (&optional pos)
  "Get position from button at point or at POS."
  (unless pos (setq pos (point)))
  (let ((button (or (button-at pos)
                    (button-at (1- pos)))))
    (and button
         (button-get button
                     'fb2-reader-outline-pos))))

(defun fb2-reader-toc-goto-corresponding-line (fb2-pos)
  "Go to line corresponding to FB2-POS in toc buffer."
  (goto-char (point-min))
  (while (and (not (eobp))
	      (> fb2-pos (fb2-reader-toc-target-at-pos (point))))
    (forward-line 1))
  (forward-line -1))

(define-button-type 'fb2-reader-toc
  'face nil
  'keymap nil)

(defvar fb2-reader-toc-mode-map
  (let ((map (make-sparse-keymap)))
    (dotimes (i 10)
      (define-key map (vector (+ i ?0)) 'digit-argument))
    (define-key map "-" 'negative-argument)
    (define-key map (kbd "p") 'outline-previous-heading)
    (define-key map (kbd "n") 'outline-next-heading)
    (define-key map (kbd "b") 'outline-backward-same-level)
    (define-key map (kbd "d") 'hide-subtree)
    (define-key map (kbd "a") 'show-all)
    (define-key map (kbd "s") 'show-subtree)
    (define-key map (kbd "f") 'outline-forward-same-level)
    (define-key map (kbd "TAB") 'outline-toggle-children)
    (define-key map (kbd "RET") 'fb2-reader-toc-follow-link)
    (define-key map (kbd "M-RET") 'fb2-reader-toc-follow-link-quit)
    (define-key map (kbd "C-o") 'fb2-reader-toc-display-link)
    (define-key map (kbd "SPC") 'fb2-reader-toc-display-link)
    (define-key map [mouse-1] 'fb2-reader-toc-mouse-display-link)
    (define-key map (kbd "o") 'fb2-reader-toc-select-fb2-window)
    (define-key map (kbd "t") 'fb2-reader-toc-select-fb2-window)
    (define-key map (kbd "Q") 'fb2-reader-toc-quit-and-kill)
    (define-key map (kbd "q") 'quit-window)
    map)
  "Keymap used in `fb2-reader-toc-mode'.")


(define-derived-mode fb2-reader-toc-mode outline-mode "FB2 TOC"
  "Mode to display table of content of corresponding fb2-reader buffer.
\\{fb2-reader-toc-mode-map}"
  (setq-local outline-regexp "\\( *\\).")
  (setq-local outline-level
              (lambda nil (1+ (/ (length (match-string 1))
                                 fb2-reader-toc-indent))))
  (toggle-truncate-lines 1)
  (setq buffer-read-only t
	cursor-type nil)
  (hl-line-mode 1))

(defun fb2-reader-toc-buffer-name (&optional fb2-buffer)
  "Get toc buffer name for FB2-BUFFER."
  (unless fb2-buffer (setq fb2-buffer (current-buffer)))
  (format "*TOC: %s*" (buffer-name fb2-buffer)))

(defun fb2-reader-toc-get-fb2-window (&optional force)
  "Get fb2 window displaying corresponding buffer.
If FORCE display it if it is hidden."
  (let ((fb2-window (if (and (window-live-p fb2-reader-toc-fb2-window)
			     (eq fb2-reader-toc-fb2-buffer
				 (window-buffer fb2-reader-toc-fb2-window)))
			fb2-reader-toc-fb2-window
		      (or (get-buffer-window fb2-reader-toc-fb2-buffer)
			  (and (not (null force))
			       (display-buffer
				fb2-reader-toc-fb2-buffer
				'(nil (inhibit-same-window . t))))))))
    (setq fb2-reader-toc-fb2-window fb2-window)))

(defun fb2-reader-create-toc-buffer (&optional fb2-buffer)
  "Create toc buffer for FB2-BUFFER."
  (unless fb2-buffer (setq fb2-buffer (current-buffer)))
  (let* ((fb2-window (get-buffer-window fb2-buffer))
	 (fb2-toc (fb2-reader-create-toc-data))
	 (buffer (get-buffer-create (fb2-reader-toc-buffer-name))))
    ;; try to create toc data
    (with-current-buffer buffer
      (toggle-truncate-lines 1)
      (fb2-reader-toc-insert-outline fb2-toc)
      (fb2-reader-toc-mode)
      (setq fb2-reader-toc-fb2-buffer fb2-buffer
	    fb2-reader-toc-fb2-window fb2-window)
      (current-buffer))))

(defun fb2-reader-get-toc-buffer (&optional fb2-buffer)
  "Get existing toc buffer or create new one for FB2-BUFFER."
  (or fb2-buffer (setq fb2-buffer (current-buffer)))
  (let ((buffer (get-buffer (fb2-reader-toc-buffer-name fb2-buffer))))
    (or buffer (fb2-reader-create-toc-buffer fb2-buffer))))

(defun fb2-reader-toc-select-fb2-window (&optional force-display)
  "Select fb2 buffer corresponding to current toc.
Display window if it is hidden and FORCE-DISPLAY is 't"
  (interactive)
  (fb2-reader-toc-assert-mode-p)
  (let ((win (fb2-reader-toc-get-fb2-window force-display)))
    (if (window-live-p win)
	(select-window win))))

(defun fb2-reader-toc-quit (&optional kill)
  "Quit TOC window.  Kill it if KILL."
  (interactive "P")
  (fb2-reader-toc-assert-mode-p)
  (let ((win (selected-window)))
    (fb2-reader-toc-select-fb2-window t)
    (quit-window kill win)))

(defun fb2-reader-toc-quit-and-kill ()
  "Quit and kill TOC window."
  (interactive)
  (fb2-reader-toc-quit t))

(defun fb2-reader-show-toc ()
  "Show table of content."
  (interactive)
  (fb2-reader-assert-mode-p)
  (let ((toc-buffer (fb2-reader-get-toc-buffer))
	(fb2-pos (point)))
    (select-window (display-buffer toc-buffer))
    (fb2-reader-toc-goto-corresponding-line fb2-pos)))

;; Metadata buffer

(defun fb2-reader-show-info ()
  "Show current book's metadata."
  (interactive)
  (fb2-reader-assert-mode-p)
  (let* ((bname (fb2-reader-info-buffer-name))
	 (buffer-exist-p (get-buffer bname))
	 (buffer (get-buffer-create bname))
	 (book (fb2-reader-parse-file fb2-reader-file-name)))
    (unless book (user-error "FB2 document corrupted"))
    (switch-to-buffer buffer)
    (unless buffer-exist-p
      (dolist (item (cddr (fb2-reader--get-description book)))
	(fb2-reader-parse-metadata book item))
      (goto-char (point-min))
      (fb2-reader-info-mode)
      (if fb2-reader-hide-cursor
	  (fb2-reader-no-cursor-mode)))))

(defun fb2-reader-info-buffer-name (&optional fb2-buffer)
  "Get info buffer name for FB2-BUFFER."
  (unless fb2-buffer (setq fb2-buffer (current-buffer)))
  (format "*Info: %s*" fb2-buffer))

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
    (define-key map (kbd "c") 'fb2-reader-no-cursor-mode)
    (define-key map (kbd "q") 'quit-window)
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

;; display-line-numbers-mode workaround

(defun fb2-reader-enable-dlnm-workaround ()
  "Enable workaround for \"display-line-numbers-mode\"."
  (add-hook 'post-command-hook #'fb2-reader-mode-correct-page-width nil t)
  (fb2-reader-mode-correct-page-width))

(defun fb2-reader-disable-dlnm-workaround ()
  "Disable workaround for \"display-line-numbers-mode\"."
  (remove-hook 'post-command-hook #'fb2-reader-mode-correct-page-width t)
  (setq fill-column fb2-reader-page-width))

(defun fb2-reader-mode-correct-page-width ()
  "Adjust current page width to \"fb2-reader-page-width\".
Adjustance needed when display-line-numbers-mode activated
and overall width of the page exceeds defined width."
  (if display-line-numbers-mode
      (let ((target-width (+ 2 (line-number-display-width) fb2-reader-page-width)))
	(unless (eq fill-column target-width)
	  (setq fill-column target-width)
	  ;; To apply changes immediately:
	  (when visual-fill-column-mode
	    (visual-fill-column-adjust)
	    (redisplay 't))))
    (fb2-reader-disable-dlnm-workaround)))


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
    (define-key map (kbd "x") 'fb2-reader-reopen-as-archive)
    (define-key map (kbd "i") 'fb2-reader-show-info)
    (define-key map (kbd "t") 'fb2-reader-show-toc)
    (define-key map (kbd "o") 'fb2-reader-show-toc)
    (define-key map (kbd "j") 'imenu)
    (define-key map (kbd "c") 'fb2-reader-no-cursor-mode)
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
  (add-hook 'kill-buffer-hook #'fb2-reader-clean-up nil t)
  (add-hook 'quit-window-hook #'fb2-reader-save-pos nil t)
  ;; (add-hook 'change-major-mode-hook 'fb2-reader-save-curr-buffer nil t)
  (add-hook 'kill-emacs-hook #'fb2-reader-save-all-pos)
  (add-hook 'display-line-numbers-mode-hook #'fb2-reader-enable-dlnm-workaround nil t)
  (fb2-reader-ensure-dir fb2-reader-settings-dir)
  (fb2-reader-ensure-dir fb2-reader-cache-dir)
  (erase-buffer)
  (let ((bufname (buffer-name))
	book
	render-fn)
    ;; (push "~/Src/Linux/_my/fb2-reader" load-path)
    (if (fb2-reader-cache-avail-p fb2-reader-file-name 't)
	(fb2-reader-restore-buffer)
      (setq book (fb2-reader-parse-file-as-xml fb2-reader-file-name)
	    render-fn 'fb2-reader-render-xml)
      (unless book
	(setq book (fb2-reader-parse-file-as-html fb2-reader-file-name)
	      render-fn 'fb2-reader-render-html))
      (unless book (user-error "FB2 document corrupted"))
      (setq-local cursor-type nil)
      (fill-region (point-min) (point-max) 'center)
      (setq fb2-reader-rendering-future
	    (fb2-reader-render-async
	     book
	     render-fn
	     (lambda (result)
	       (with-current-buffer bufname
		 ;; For some reason propertized string returned from async process
		 ;; loses hash at it's beginning.
		 (fb2-reader-add-to-cache fb2-reader-file-name
					  (read (concat "#" result)))
		 (fb2-reader-restore-buffer)
		 (kill-local-variable 'cursor-type) ; can't remember why this string is here..
		 (if fb2-reader-title-in-headerline
		     (setq fb2-reader-header-line-toc (fb2-reader-create-headerline-data)))
		 (setq fb2-reader-rendering-future nil))))))

    (fb2-reader-imenu-setup)
    (if fb2-reader-hide-nobreak
	(setq-local nobreak-char-display nil))
    (if fb2-reader-title-in-headerline
	(fb2-reader-header-line-mode))
    (if fb2-reader-hide-cursor
	(fb2-reader-no-cursor-mode))
    (setq visual-fill-column-center-text 't
	  visual-fill-column-enable-sensible-window-split 't)
    (visual-fill-column-mode)
    (unless (or (null fb2-reader-rendering-future)
		(async-ready fb2-reader-rendering-future))
      (fb2-reader-splash-screen book))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.fb2\\(\\.zip\\)?\\'" . fb2-reader-mode))

(provide 'fb2-reader)

;;; fb2-reader.el ends here
