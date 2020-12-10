;;; org-translate.el --- Org-based translation environment  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Free Software Foundation, Inc.

;; Version: 0.1.3
;; Package-Requires: ((emacs "25.1") (org "9.1"))

;; Author: Eric Abrahamsen <eric@ericabrahamsen.net>
;; Maintainer: Eric Abrahamsen <eric@ericabrahamsen.net>

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

;; This library contains the `org-translate-mode' minor mode to be
;; used on top of Org, providing translation-related functionality.
;; It is not a full-fledged CAT tool.  It essentially does two things:
;; manages segmentation correspondences between the source text and
;; the translation, and manages a glossary which can be used for
;; automatic term translation, displaying previous usages, etc.

;; Buffer setup:

;; The mode currently assumes a single file holding a single
;; translation project, with three separate top-level headings for
;; source text, translation, and glossary (other headings will be
;; ignored).  The three customization options
;; `ogt-default-source-locator', `ogt-default-translation-locator' and
;; `ogt-default-glossary-locator' can be used to tell the mode which
;; heading is which; by default it expects a buffer that looks like
;; this:

;; * Le Rouge et le Noir                                     :source:
;;   La petite ville de Verrières peut passer pour...

;; * The Red and the Black                              :translation:
;;   The small town of Verrieres may be regarded...

;; * Glossary
;; ** ville de Verrières

;; In other words, tags are used to find the source and translation
;; texts, while the glossary heading is just called "Glossary".  This
;; is also configurable on a per-project basis, using the
;; `ogt-translation-projects' option.

;; Segmentation

;; The first time you start this mode in a new translation project
;; buffer (after first setting up the three headings appropriately),
;; the mode will detect that the project has not yet been segmented,
;; and will offer to do so.  Segmentation involves inserting the value
;; of `ogt-segmentation-character' at intervals in the source text.
;; As you progress through the translation, you'll insert that same
;; character at corresponding places in the translation text, allowing
;; the minor mode to keep track of which segment corresponds to which,
;; and to keep the display of source and translation synchronized.

;; The option `ogt-segmentation-strategy' determines how the source
;; text is segmented.  Currently the options are to segment by
;; sentence, by paragraph, or by regular expression.  Note that, after
;; initial segmentation, the minor mode will leave the segmentation
;; characters alone, and you're free to insert, delete or move them as
;; needed.

;; As you reach the end of each translation segment, use "C-M-n"
;; (`ogt-new-segment') to insert a segmentation character and start a
;; new segment.  The character should be inserted at the _beginning_
;; of the new segment, not at the end of the last -- eg at the start
;; of a paragraph or sentence.

;; Use "C-M-f" and "C-M-b" to move forward and backward in the
;; translation text by segment.  This will allow the minor mode to
;; keep the corresponding source segment in view.  Alternately, move
;; point however you like in the translation text, then use "C-M-t" to
;; update the source view.

;; The glossary

;; This mode also maintains a glossary of translation terms for the
;; current project.  Currently it does this by keeping each term as a
;; subheading under the top-level glossary heading.  Each subheading
;; has an ID property, and this property is used to create links in
;; the source and translation text, pointing to the glossary item in
;; question.  The mode keeps tracks of the various ways you've
;; translated a term previously, and offers these for completion on
;; inserting a new translation.

;; To create a new glossary term, use "C-M-y".  If you've marked text
;; in the source buffer, this will become the new term, otherwise
;; you'll be prompted to enter the string.  This command will attempt
;; to turn all instances of this term in the source text into a link.

;; In the translation text, use "C-M-;"
;; (`ogt-insert-glossary-translation') to add a translation.  The mode
;; will attempt to guess which term you're adding, and suggest
;; previous translations for that term.  If you don't want it to
;; guess, use a prefix argument to be prompted.

;; Bookmarks

;; The functions `ogt-start-translating' and `ogt-stop-translating'
;; can be used to start and stop a translation session.  The first use
;; of the latter command will save the project in your bookmarks file,
;; after which `ogt-start-translating' will offer the project to work
;; on.

;; TODO:

;; - Generalize the code to work in text-mode as well as Org,
;;   using 2C-mode instead of Org subtrees.
;; - Support multi-file translation projects.
;; - Import/export TMX translation databases.
;; - Provide for other glossary backends: eieio-persistent, xml,
;;   sqlite, etc.
;; - Do this by allowing the glossary locator to point at a named Org
;;   table, or at a babel source block, allowing users to maintain
;;   the glossary outside of Org altogether.
;; - Provide integration with `org-clock': set a custom property on a
;;   TODO heading indicating that it represents a translation project.
;;   Clocking in both starts the clock, and sets up the translation
;;   buffers.  Something like that.

;;; Code:

(require 'bookmark)
(require 'ox)
(require 'org-id)

(defgroup org-translate nil
  "Customizations for the org-translate library."
  :group 'text)

(defcustom ogt-default-source-locator '(tag . "source")
  "Default method for locating the source-language subtree.
The value should be a cons of (TYPE . MATCHER), where TYPE is a
locator type, as a symbol, and MATCHER is a string or other
specification.  `org-translate-mode' will identify the subtree
representing the source-language text by locating the first
heading where MATCHER matches the TYPE of the heading's
data. Valid TYPEs are:

`tag': Match heading tags.
`id': Match the heading ID.
`property': Match an arbitrary other property.  MATCHER should be
            a further cons of two strings: the property name and
            value.
`heading': Match heading text.

Once the heading is located, it will be tracked by its ID
property."
  :type '(choice
	  (cons :tag "Tag" (const tag) string)
	  (cons :tag "ID" (const id) string)
	  (cons :tag "Property" (const property)
		(cons (string :tag "Property name")
		      (string :tag "Property value")))
	  (cons :tag "Heading text" (const heading) string)))

(defcustom ogt-default-translation-locator '(tag . "translation")
  "Default method for locating the translation subtree.
The value should be a cons of (TYPE . MATCHER), where TYPE is a
locator type, as a symbol, and MATCHER is a string or other
specification.  `org-translate-mode' will identify the subtree
representing the source-language text by locating the first
heading where MATCHER matches the TYPE of the heading's
data. Valid TYPEs are:

`tag': Match heading tags.
`ID': Match the heading ID.
`property': Match an arbitrary other property.  MATCHER should be
            a further cons of two strings: the property name and
            value.
`heading': Match heading text.

Once the heading is located, it will be tracked by its ID
property."
  :type '(choice
	  (cons :tag "Tag" (const tag) string)
	  (cons :tag "ID" (const id) string)
	  (cons :tag "Property" (const property)
		(cons (string :tag "Property name")
		      (string :tag "Property value")))
	  (cons :tag "Heading text" (const heading) string)))

(defcustom ogt-default-glossary-locator '(heading . "glossary")
  "Default method for locating the glossary subtree.
The value should be a cons of (TYPE . MATCHER), where TYPE is a
locator type, as a symbol, and MATCHER is a string or other
specification.  `org-translate-mode' will identify the subtree
representing the source-language text by locating the first
heading where MATCHER matches the TYPE of the heading's
data. Valid TYPEs are:

`tag': Match heading tags.
`ID': Match the heading ID.
`property': Match an arbitrary other property.  MATCHER should be
            a further cons of two strings: the property name and
            value.
`heading': Match heading text (case-insensitively).

Once the heading is located, it will be tracked by its ID
property."
  :type '(choice
	  (cons :tag "Tag" (const tag) string)
	  (cons :tag "ID" (const id) string)
	  (cons :tag "Property" (const property)
		(cons (string :tag "Property name")
		      (string :tag "Property value")))
	  (cons :tag "Heading text" (const heading) string)))

;; `org-block-regexp', `org-table-any-line-regexp',
;; `org-heading-regexp' `page-delimiter'... Hmm, maybe we should be
;; walking through using the org parser instead?
(defcustom ogt-default-segmentation-strategy 'sentence
  "Default strategy for segmenting source/target text.
Value can be one of symbols `sentence' or `paragraph', in which
case the buffer-local definitions of sentence and paragraph will
be used.  It can also be a regular expression.

Org headings, lists, tables, etc, as well as the value of
`page-delimiter', will always delimit segments."
  :type '(choice (const :tag "Sentence" sentence)
		 (const :tag "Paragraph" paragraph)
		 regexp))

(defcustom ogt-default-segmentation-character 29
  ;; INFORMATION SEPARATOR THREE, aka "group separator"
  "Default character used to delimit segments."
  :type 'character)

;(defface ogt-source-segment-face '())

(defcustom ogt-translation-projects nil
  "Alist of active translation projects.
Keys are identifying string for use in completion.  Values are
plists specifying options for that project.  Valid options are
:file, :seg-strategy, :seg-character, :source, :translation, and
:glossary.  The last three values can be specified as a string
ID, or as a \"locator\" as in, for instance,
`ogt-default-source-locator'."
  :type 'list)

(defvar-local ogt-source-heading nil
  "ID of the source-text heading in this file.")

(defvar-local ogt-translation-heading nil
  "ID of the translation heading in this file.")

(defvar-local ogt-glossary-heading nil
  "ID of the glossary heading in this file.")

(defvar-local ogt-segmentation-strategy nil
  "Segmentation strategy in this file.")

(defvar-local ogt-segmentation-character nil
  "Segmentation character in this file.")

(defvar-local ogt-this-project-name nil
  "String name of the current translation project, if any.
If `ogt-translation-projects' is not used, this will be nil.")

(defvar-local ogt-glossary-table nil
  "Hash table holding original<->translation relations.
Keys are glossary heading IDs.  Values are an alist holding
source terms and translation terms.")

(defvar-local ogt-source-window nil
  "Pointer to window on source text.")

(defvar-local ogt-translation-window nil
  "Pointer to window on translation text.")

(defvar-local ogt-probable-source-location nil
  "Marker at point's corresponding location in source text.
Called \"probable\" as it is placed heuristically, updated very
fragilely, and deleted and re-set with abandon.")

(defvar-local ogt-source-segment-overlay nil
  "Overlay on the current source segment.")

(defvar ogt-link-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "o") #'ogt-term-occur)
    (define-key map (kbd "d") #'ogt-term-display-translations)
    map)
  "Keymap active on \"trans:\" type Org links.")

(org-link-set-parameters
 "trans"
 :follow #'org-id-open
 :keymap ogt-link-keymap
 :export #'ogt-export-link)

(defun ogt-export-link (_path desc _backend)
  "Export a translation link.
By default, just remove it."
  desc)

(defvar org-translate-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-M-f") #'ogt-forward-segment)
    (define-key map (kbd "C-M-b") #'ogt-backward-segment)
    (define-key map (kbd "C-M-n") #'ogt-new-segment)
    (define-key map (kbd "C-M-t") #'ogt-update-source-location)
    (define-key map (kbd "C-M-y") #'ogt-new-glossary-term)
    (define-key map (kbd "C-M-;") #'ogt-insert-glossary-translation)
    map))

(define-minor-mode org-translate-mode
  "Minor mode for using an Org file as a translation project.

\\{org-translate-mode-map}"
  nil " Translate" nil
  (if (null org-translate-mode)
      (progn
	(setq ogt-source-heading nil
	      ogt-translation-heading nil
	      ogt-glossary-heading nil
	      ogt-segmentation-strategy nil
	      ogt-segmentation-character nil
	      ogt-glossary-table nil
	      ogt-probable-source-location nil)
	(when (overlayp ogt-source-segment-overlay)
	  (delete-overlay ogt-source-segment-overlay)))
    (unless (derived-mode-p 'org-mode)
      (user-error "Only applicable in Org files."))
    (let* ((this-project (or ogt-this-project-name
			     (when ogt-translation-projects
			       (let* ((f-name (buffer-file-name)))
				 (seq-find
				  (lambda (elt)
				    (file-equal-p
				     f-name (plist-get (cdr elt) :file)))
				  ogt-translation-projects)))))
	   (this-plist (when this-project
			 (alist-get this-project ogt-translation-projects))))
      (condition-case err
	  (setq ogt-source-heading (or (plist-get this-plist :source)
				       (ogt-locate-heading
					ogt-default-source-locator))
		ogt-translation-heading (or (plist-get this-plist :translation)
					    (ogt-locate-heading
					     ogt-default-translation-locator))
		ogt-glossary-heading (or (plist-get this-plist :glossary)
					 (ogt-locate-heading
					  ogt-default-glossary-locator))
		ogt-segmentation-strategy (or (plist-get this-plist :seg-strategy)
					      ogt-default-segmentation-strategy)
		ogt-segmentation-character (or (plist-get this-plist :seg-character)
					       ogt-default-segmentation-character)
		ogt-glossary-table (make-hash-table :size 500 :test #'equal)
		ogt-probable-source-location (make-marker)
		ogt-source-segment-overlay (make-overlay (point) (point)))
	(error (org-translate-mode -1)
	       (signal (car err) (cdr err))))
      (push #'ogt-export-remove-segmenters org-export-filter-body-functions)
      (overlay-put ogt-source-segment-overlay
		   'face 'highlight)
      ;; Doesn't actually delete it, just makes it "inactive" until we
      ;; know where to put it.
      (delete-overlay ogt-source-segment-overlay)
      (delete-other-windows)
      (org-show-all)
      (save-excursion
	(ogt-goto-heading 'source)
	(when (and (save-restriction
		     (org-narrow-to-subtree)
		     (null (re-search-forward
			    (string ogt-segmentation-character) nil t)))
		   (yes-or-no-p
		    "Project not yet segmented, segment now?"))
	  (ogt-segment-project))
	(dolist (location '(source translation))
	  (ogt-goto-heading location)
	  (save-restriction
	    (org-narrow-to-subtree)
	    (while (re-search-forward org-link-any-re
				      nil t)
	      (when (string-prefix-p "trans:" (match-string 2))
		(cl-pushnew (match-string-no-properties 3)
			    (alist-get location
				       (gethash
					(string-remove-prefix
					 "trans:"
					 (match-string-no-properties 2))
					ogt-glossary-table))
			    :test #'equal))))))
      ;; TODO: Provide more flexible window configuration.
      (setq ogt-translation-window (split-window-sensibly))
      (setq ogt-source-window (selected-window))
      (select-window ogt-translation-window)
      (ogt-goto-heading 'translation)
      ;; If we arrived via a bookmark, don't move point.
      (unless bookmark-current-bookmark
	(org-end-of-subtree))
      (ogt-prettify-segmenters)
      (ogt-update-source-location)
      (ogt-report-progress))))

(defun ogt-export-remove-segmenters (body-string _backend _plist)
  "Remove `ogt-segmentation-character' on export."
  ;; Is `org-export-filter-body-functions' the right filter to use?
  (replace-regexp-in-string
   (string ogt-segmentation-character) "" body-string))

(defun ogt-term-occur ()
  "Run `occur' for the glossary term at point.
Available on \"trans:\" type links that represent glossary
terms."
  (interactive)
  (let ((id (org-element-property :path (org-element-context))))
    ;; I thought I should use `org-occur', but that only seems to work
    ;; correctly in the sparse tree context.
    (occur (concat "trans:" id))))

(defun ogt-term-display-translations ()
  "Display original and translations for link under point."
  (interactive)
  (let ((bits (gethash
	       (org-element-property :path (org-element-context))
	       ogt-glossary-table)))
    (message
     (format
      (concat
       (mapconcat #'identity (alist-get 'source bits) ", ")
       " : "
       (mapconcat #'identity (alist-get 'translation bits) ", "))))))

(defun ogt-prettify-segmenters (&optional begin end)
  "Add a display face to all segmentation characters.
If BEGIN and END are given, prettify segmenters between those
locations."
  (save-excursion
    (let ((begin (or begin (point-min)))
	  (end (or end (point-max))))
      (goto-char begin)
      (while (re-search-forward
	      (string ogt-segmentation-character) end t)
	;; This marks the buffer as modified (on purpose).  Is that
	;; something we want to suppress?
	(put-text-property (1- (point)) (point)
			   ;; Any other useful thing we could do?  A
			   ;; keymap?
			   'display (string 9245))))))

(defun ogt-recenter-source ()
  "Recenter source location in the source window."
  (with-selected-window ogt-source-window
    (goto-char ogt-probable-source-location)
    (recenter)))

(defun ogt-update-source-location ()
  "Place location marker in source text.
Point must be in the translation tree for this to do anything.
Sets the marker `ogt-probable-source-location' to our best-guess
spot corresponding to where point is in the translation."
  (interactive)
  (let* ((start (point))
	 (trans-start
	  (progn (ogt-goto-heading 'translation) (point)))
	 (trans-end (progn (org-end-of-subtree) (point)))
	 (number-of-segments 0))
    (goto-char start)
    (unless (<= trans-start start trans-end)
      (user-error "Must be called from inside the translation text"))
    (while (re-search-backward (string ogt-segmentation-character)
			       trans-start t)
      (cl-incf number-of-segments))
    (with-selected-window ogt-source-window
      (ogt-goto-heading 'source)
      (save-restriction
	(org-narrow-to-subtree)
	(org-end-of-meta-data t)
	(unless (re-search-forward (string ogt-segmentation-character)
				   nil t number-of-segments)
	  t ;; Something is wrong!  Re-segment the whole buffer?
	  )
	(set-marker ogt-probable-source-location (point))
	(ogt-highlight-source-segment)
	(recenter)))
    (goto-char start)))

(defun ogt-report-progress ()
  "Report progress in the translation, as a percentage."
  (interactive)
  (let (report-start report-end)
    (save-excursion
      (save-selected-window
	(ogt-goto-heading 'source)
	(org-end-of-meta-data t)
	(setq report-start (point))
	(org-end-of-subtree)
	(setq report-end (point))))
    (message "You're %d%% done!"
	     (* (/ (float (- ogt-probable-source-location report-start))
		   (float (- report-end report-start)))
		100))))

(defun ogt-highlight-source-segment ()
  "Highlight the source segment the user is translating.
Finds the location of the `ogt-probable-source-location' marker,
and applies a highlight to the appropriate segment of text."
  (when (marker-position ogt-probable-source-location)
    (save-excursion
      (goto-char ogt-probable-source-location)
      ;; If we're right in front of a seg character, use the
      ;; following segment.
      (when (looking-at-p (string ogt-segmentation-character))
	(forward-char))
      (move-overlay
       ogt-source-segment-overlay
       (progn
	 (re-search-backward
	  (string ogt-segmentation-character)
	  nil t)
	 (forward-char)
	 (point))
       (progn
	 (or (and (re-search-forward
		   (regexp-opt
		    (list (string ogt-segmentation-character)
			  "\n\n"
			  org-heading-regexp))
		   nil t)
		  (progn
		    (backward-char)
		    (skip-syntax-backward "-")
		    (point)))
	     (point-max)))))))

(defun ogt-locate-heading (locator)
  "Return the ID of the heading found by LOCATOR, or nil.
Creates an ID if necessary."
  (save-excursion
    (goto-char (point-min))
    (let ((id (pcase locator
		(`(heading . ,text)
		 (catch 'found
		   (while (re-search-forward
			   org-complex-heading-regexp nil t)
		     (when (string-match-p text (match-string 4))
		       (throw 'found (org-id-get-create))))))
		(`(tag . ,tag-text)
		 (catch 'found
		   (while (re-search-forward org-tag-line-re nil t)
		     (when (string-match-p tag-text (match-string 2))
		       (throw 'found (org-id-get-create))))))
		(`(id . ,id-text)
		 (org-id-goto id-text)
		 id-text)
		(`(property (,prop . ,value))
		 (goto-char (org-find-property prop value))
		 (org-id-get-create)))))
      (or id
	  (error "Locator failed: %s" locator)))))

(defun ogt-goto-heading (head)
  (let ((id (pcase head
	      ('source ogt-source-heading)
	      ('translation ogt-translation-heading)
	      ('glossary ogt-glossary-heading)
	      (_ nil))))
    (when id
      (org-id-goto id))))

(defun ogt-segment-project ()
  "Do segmentation for the current file.
Automatic segmentation is only done for the source text;
segmentation in the translation is all manual.

Segmentation is done by inserting `ogt-segmentation-character' at
the beginning of each segment."
  (dolist (loc '(source translation))
    ;; Also attempt to segment the translation subtree -- the user
    ;; might have already started.
    (save-excursion
      (ogt-goto-heading loc)
      (save-restriction
	(org-narrow-to-subtree)
	(org-end-of-meta-data t)
	(let ((mover
	       ;; These "movers" should all leave point at the beginning
	       ;; of the _next_ thing.
	       (pcase ogt-segmentation-strategy
		 ('sentence
		  (lambda (_end)
		    (forward-sentence)
		    (skip-chars-forward "[:blank:]")))
		 ('paragraph (lambda (_end)
			       (org-forward-paragraph)))
		 ((pred stringp)
		  (lambda (end)
		    (re-search-forward
		     ogt-segmentation-strategy end t)))
		 (_ (user-error
		     "Invalid value of `ogt-segmentation-strategy'"))))
	      (end (make-marker))
	      current)
	  (while (< (point) (point-max))
	    (setq current (org-element-at-point))
	    (unless (eql (org-element-type current) 'headline)
	      (insert ogt-segmentation-character))
	    (move-marker end (org-element-property :contents-end current))
	    ;; TODO: Do segmentation in plain lists and tables.
	    (while (and (< (point) end)
			;; END can be after `point-max' in narrowed
			;; buffer.
			(< (point) (point-max)))
	      (cond
	       ((eql (org-element-type current) 'headline)
		(skip-chars-forward "[:blank:]\\*")
		(insert ogt-segmentation-character)
		(org-end-of-meta-data t)
		(move-marker end (point)))
	       ((null (eql (org-element-type current)
			   'paragraph))
		(goto-char end))
	       (t (ignore-errors (funcall mover end))))
	      (if (eolp) ;; No good if sentence happens to end at `eol'!
		  (goto-char end)
		(insert ogt-segmentation-character)))
	    (unless (ignore-errors (org-forward-element))
	      (goto-char (point-max)))))))))

;; Could also set this as `forward-sexp-function', then don't need the
;; backward version.
(defun ogt-forward-segment (arg)
  "Move ARG segments forward.
Or backward, if ARG is negative."
  (interactive "p")
  (re-search-forward (string ogt-segmentation-character) nil t arg)
  (if (marker-position ogt-probable-source-location)
      (with-selected-window ogt-source-window
	(goto-char ogt-probable-source-location)
	(re-search-forward (string ogt-segmentation-character)
			   nil t arg)
	(set-marker ogt-probable-source-location (point))
	(ogt-highlight-source-segment)
	(recenter))
    (ogt-update-source-location)))

(defun ogt-backward-segment (arg)
  (interactive "p")
  (ogt-forward-segment (- arg)))

(defun ogt-new-segment ()
  "Start a new translation segment.
Used in the translation text when a segment is complete, to start
the next one."
  (interactive)
  (insert ogt-segmentation-character)
  (ogt-prettify-segmenters (1- (point)) (point))
  (unless (eolp)
    (forward-char))
  (recenter 10)
  (if (marker-position ogt-probable-source-location)
      (with-selected-window ogt-source-window
	(goto-char ogt-probable-source-location)
	(re-search-forward (string ogt-segmentation-character)
			   nil t)
	(set-marker ogt-probable-source-location (point))
	(ogt-highlight-source-segment)
	(recenter 10))
    (ogt-update-source-location)))

(defun ogt-new-glossary-term (string)
  "Add STRING as an item in the glossary.
If the region is active, it will be used as STRING.  Otherwise,
prompt the user for STRING."
  (interactive
   (list (if (use-region-p)
	     (buffer-substring-no-properties
	      (region-beginning)
	      (region-end))
	   (read-string "Glossary term: "))))
  (save-excursion
    (ogt-goto-heading 'glossary)
    (if (org-goto-first-child)
	(org-insert-heading-respect-content)
      (end-of-line)
      (org-insert-subheading 1))
    (insert string)
    (let ((id (org-id-get-create))
	  ;; STRING might be broken across lines.  What do we do about
	  ;; Chinese, with no word separators?
	  (doctored (replace-regexp-in-string
		     "[[:blank:]]+" "[[:space:]\n]+"
		     string)))
      (ogt-goto-heading 'source)
      (save-restriction
	(org-narrow-to-subtree)
	(while (re-search-forward doctored nil t)
	  (replace-match (format "[[trans:%s][%s]]" id string))))
      (push string (alist-get 'source (gethash id ogt-glossary-table)))))
  (message "Added %s as a glossary term" string))

(defun ogt-insert-glossary-translation (prompt)
  "Insert a likely translation of the next glossary term.
Guesses the glossary term to insert based on how many terms have
already been translated in this segment.  Alternately, give a
prefix arg to be prompted for the term to enter."
  (interactive "P")
  (let* ((orig (when prompt
		 (completing-read
		  "Add translation of: "
		  (mapcan (lambda (v)
			    (copy-sequence (alist-get 'source v)))
			  (hash-table-values ogt-glossary-table))
		  nil t)))
	 (glossary-id (when orig
			(catch 'found
			  (maphash
			   (lambda (k v)
			     (when (member orig (alist-get 'source v))
			       (throw 'found k)))
			   ogt-glossary-table))))
	 glossary-translation this-translation)
    (ogt-update-source-location)
    ;; If we didn't prompt, attempt to guess which glossary term
    ;; should be translated next by counting how many we've already
    ;; done this segment.
    (unless (and orig glossary-id)
      (let ((terms-this-segment 1))
	(save-excursion
	  (while (re-search-backward
		  "\\[\\[trans:"
		  (save-excursion
		    (re-search-backward
		     (string ogt-segmentation-character) nil t)
		    (point))
		  t)
	    (cl-incf terms-this-segment)))
	(with-selected-window ogt-source-window
	  (goto-char ogt-probable-source-location)
	  (while (null (zerop terms-this-segment))
	    (re-search-forward org-link-any-re nil t)
	    (when (string-prefix-p "trans:" (match-string 2))
	      (cl-decf terms-this-segment)))
	  (setq orig (match-string-no-properties 3)
		glossary-id (string-remove-prefix
			     "trans:" (match-string 2))))))
    (setq glossary-translation
	  (alist-get 'translation
		     (gethash glossary-id ogt-glossary-table))
	  this-translation
	  (completing-read (format "Translation of %s: " orig)
			   glossary-translation))
    (cl-pushnew
     this-translation
     (alist-get 'translation
		(gethash glossary-id ogt-glossary-table))
     :test #'equal)
    (insert (format "[[trans:%s][%s]]" glossary-id this-translation))))

(defun ogt-stop-translating (project-name)
  "Stop translating for the current file, record position.
Saves a bookmark under PROJECT-NAME."
  (interactive
   (list (or bookmark-current-bookmark
	     (let ((f-name (file-name-nondirectory
			    (file-name-sans-extension
			     (buffer-file-name)))))
	      (read-string
	       (format-prompt "Save project as" f-name)
	       nil nil f-name)))))
  (let ((rec (bookmark-make-record)))
    (bookmark-prop-set rec 'translation t)
    (bookmark-store project-name (cdr rec) nil)
    (bookmark-save)
    (message "Position recorded and saved")))

(defun ogt-start-translating (bmk)
  "Start translating a bookmarked project.
Prompts for a bookmark, and sets up the windows."
  (interactive
   (list (progn (require 'bookmark)
		(bookmark-maybe-load-default-file)
		(assoc-string
		 (completing-read
		  "Translation project: "
		  ;; "Borrowed" from `bookmark-completing-read'.
		  (lambda (string pred action)
		    (if (eq action 'metadata)
			'(metadata (category . bookmark))
		      (complete-with-action
		       action
		       (seq-filter
			(lambda (bmk)
			  (bookmark-prop-get bmk 'translation))
			bookmark-alist)
		       string pred))))
		 bookmark-alist))))
  (bookmark-jump bmk)
  (when (derived-mode-p 'org-mode)
    (org-translate-mode)))

;;;; ChangeLog:

;; 2020-12-01  Stefan Monnier  <monnier@iro.umontreal.ca>
;; 
;; 	* .gitignore: New file
;; 
;; 2020-10-20  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Fix bum logic in finding the end of a segment
;; 
;; 	* packages/org-translate/org-translate.el
;; 	(ogt-highlight-source-segment): Searching consecutive regexps makes no
;; 	sense; need to make one big regexp.
;; 
;; 2020-10-15  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Improve segmentation of subtree headings, bump 0.1.2
;; 
;; 	* packages/org-translate/org-translate.el (ogt-segment-project): This 
;; 	was incorrectly inserting segmentation characters before heading stars.
;; 
;; 2020-10-15  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Do a better job of reporting errors at startup
;; 
;; 	* packages/org-translate/org-translate.el (org-translate-mode): If the 
;; 	mode fails to start because the buffer is not set up correctly, which is
;; 	highly likely, the user needs to know that.
;; 
;; 2020-10-15  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] New command ogt-term-display-translations
;; 
;; 	* packages/org-translate/org-translate.el
;; 	(ogt-term-display-translations): Bound in the translation link keymap,
;; 	for echoing the original and translation of the term link under point.
;; 
;; 2020-10-15  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Remove ogt-follow-link
;; 
;; 	* packages/org-translate/org-translate.el: Just use `org-id-open' 
;; 	directly.
;; 
;; 2020-09-23  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Fix bum link following, bump to 0.1.1
;; 
;; 	* packages/org-translate/org-translate.el (ogt-follow-link): Apparently
;; 	this takes a prefix arg, don't know how this passed basic testing.
;; 
;; 2020-09-21  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Release version 0.1
;; 
;; 	Thanks to Arthur Miller and Stefan Kangas for alpha testing.
;; 
;; 2020-09-19  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Add keymap for translation links, plus occur command
;; 
;; 	* packages/org-translate/org-translate.el (ogt-link-keymap): Keymap 
;; 	active on trans: type links.
;; 	(ogt-term-occur): Command to show all occurances of a translation term
;; 	in the buffer. Doesn't actually work (doesn't display anything) but
;; 	we'll figure that out.
;; 
;; 2020-09-19  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Fix bug in ogt-hightlight-source-segment
;; 
;; 	* packages/org-translate/org-translate.el
;; 	(ogt-highlight-source-segment): This returned the correct position, but
;; 	point actually needed to be after the segmentation character.
;; 
;; 2020-09-19  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Allow ogt-insert-glossary-translation to prompt
;; 
;; 	* packages/org-translate/org-translate.el
;; 	(ogt-insert-glossary-translation): With a prefix arg, prompt for a term
;; 	to insert, rather than guessing.
;; 
;; 2020-09-19  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Rename ogt-add-glossary-item: ogt-new-glossary-term
;; 
;; 	* packages/org-translate/org-translate.el (ogt-new-glossary-term): Fix 
;; 	bug in adding the very first glossary item. When finding other instances
;; 	of the term, anticipate them being split across lines.
;; 	(org-translate-mode-map): Provide binding for both adding new term, and
;; 	inserting translation.
;; 
;; 2020-09-19  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Be stricter at startup
;; 
;; 	* packages/org-translate/org-translate.el: Require 'org-id, first of 
;; 	all.
;; 	(ogt-locate-heading): Raise error if we can't find any of the necessary
;; 	headings.
;; 	(org-translate-mode): If anything errors, shut the mode off again.
;; 
;; 2020-09-19  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Improve documentation
;; 
;; 	* packages/org-translate/org-translate.el: Better initial walkthrough; 
;; 	add mode map to minor-mode docstring.
;; 
;; 2020-09-18  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Segment both source and translation trees
;; 
;; 	* packages/org-translate/org-translate.el (ogt-segment-project): The 
;; 	user might have already started with the translation.
;; 
;; 2020-09-18  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Require 'ox library
;; 
;; 	* packages/org-translate/org-translate.el: Needed to remove the 
;; 	segmentation characters on export.
;; 
;; 2020-09-18  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Remove extraneous Author header
;; 
;; 2020-09-17  Stefan Monnier  <monnier@iro.umontreal.ca>
;; 
;; 	* org-translate.el: Add missing author info
;; 
;; 2020-09-16  Eric Abrahamsen  <eric@ericabrahamsen.net>
;; 
;; 	[org-translate] Add version 0 of org-translate
;; 
;; 	* packages/org-translate/org-translate.el: New package.
;; 


(provide 'org-translate)
;;; org-translate.el ends here
