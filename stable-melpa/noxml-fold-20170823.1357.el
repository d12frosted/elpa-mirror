;;; noxml-fold.el --- Fold away XML things.

;; Copyright (C) 2014--2017 Patrick McAllister

;; Author: Patrick McAllister <pma@rdorte.org>
;; Keywords: xml, folding
;; Package-Version: 20170823.1357
;; Package-Commit: 46c7f6a008672213238a9f8d7a416ce80916aa62
;; URL: https://github.com/paddymcall/noxml-fold

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

;; This is an Emacs minor mode that tries to enable useful folding for
;; XML files, copying a lot from AUCTeX's tex-fold.el.  It presupposes
;; that nxml-mode is the major-mode.

;; The most useful entry points for users are `noxml-fold-dwim', and
;; `noxml-fold-region'.

;; Since this mode uses overlays, it does *not* scale: for very
;; long/deeply nested XML, you should only fold what's within view, or
;; make use of `narrow-to-region'.

;;; Code:

(require 'overlay)
(require 'nxml-mode)
;; some with provide statement in cl-extra
(if (and (<= emacs-major-version 24) (<= emacs-minor-version 4))
    (load "cl-extra")
    (require 'cl-extra))
(require 'easymenu)

;;; configuration, vars etc.

(defcustom noxml-fold-unfold-around-mark t
  "Unfold text around the mark, if active."
  :type 'boolean
  :group 'noxml-fold)

(defcustom noxml-fold-help-echo-max-length 70
  "Maximum length of help echo message for folded overlays.
Set it to zero in order to disable help echos."
  :type 'integer
  :group 'noxml-fold)

(defvar noxml-fold-open-spots nil)
(make-variable-buffer-local 'noxml-fold-open-spots)


;; TODO: bad solution this here. See info: (nxml-mode) Paragraphs
;; for a better way to do this (and integrate).  See also
;; nxml-mode.el::;;; Paragraphs.
(defcustom noxml-is-not-inline-regexp "^\\s-*<[^/]"
  "A regex for block elements.

If this matches, it's considered a block element.  See
`noxml-is-inline'."
  :type 'regexp
  :group 'noxml-fold)

(defcustom noxml-inline-elements nil
  "A list of element names that are always considered inline."
  :type '(repeat string)
  :group 'noxml-fold)

(defcustom noxml-block-elements nil
  "A list of element names that are always considered block elements."
  :type '(repeat string)
  :group 'noxml-fold)

(defvar noxml-overlay-priority-step 16
  "Numerical difference of priorities between nested overlays.
The step should be big enough to allow setting a priority for new
overlays between two existing ones.")

(defcustom noxml-fold-force-fontify t
  "Force the buffer to be fully fontified by folding it."
  :group 'noxml-fold
  :type 'boolean)

(defcustom noxml-fold-add-to-screen 5000
  "How many chars outside the screen to fold.

If you have a <paragraph>...</paragraph>, for example, that
stretches over 10.000 chars, and your screen shows around 4000
chars, and you are at the beginning of the <paragraph>, then it
will fold the whole thing for you only if
`noxml-fold-add-to-screen' is > 6000."
  :group 'noxml-fold
  :type 'integer)

(make-variable-buffer-local 'noxml-fold-add-to-screen)

(defface noxml-fold-tag-face
  '((((class color) (background light))
     (:inherit nxml-name))
    (((class color) (background dark))
     (:inherit nxml-name))
    (((class grayscale) (background light))
     (:inherit nxml-name))
    (((class grayscale) (background dark))
     (:inherit nxml-name))
    (t (:inherit nxml-name)))
  "Face for the display string of folded tags."
  :group 'noxml-fold)

(defface noxml-fold-folded-face
  '((((class color) (background light))
     (:inherit nxml-text))
    (((class color) (background dark))
     (:inherit nxml-text))
    (((class grayscale) (background light))
     (:inherit nxml-text))
    (((class grayscale) (background dark))
     (:inherit nxml-text))
    (t (:inherit nxml-text)))
  "Face for the display string of folded content."
  :group 'noxml-fold)

;; (defvar noxml-fold-folded-face 'noxml-fold-folded-face
;;   "Face for the display string of folded content.")

(defface noxml-fold-folded-italic-face
  '((((class color) (background light))
     (:inherit noxml-fold-folded-face
	       :slant italic))
    (((class color) (background dark))
     (:inherit noxml-fold-folded-face
	       :slant italic))
    (((class grayscale) (background light))
     (:inherit noxml-fold-folded-face
	       :slant italic))
    (((class grayscale) (background dark))
     (:inherit noxml-fold-folded-face
	       :slant italic))
    (t (:inherit noxml-fold-folded-face
	       :slant italic)))
  "Face for the display string of folded italic content."
  :group 'noxml-fold)

(defface noxml-fold-folded-bold-face
  '((((class color) (background light))
     (:inherit noxml-fold-folded-face
	       :weight bold))
    (((class color) (background dark))
     (:inherit noxml-fold-folded-face
	       :weight bold))
    (((class grayscale) (background light))
     (:inherit noxml-fold-folded-face
	       :weight bold))
    (((class grayscale) (background dark))
     (:inherit noxml-fold-folded-face
	       :weight bold))
    (t (:inherit noxml-fold-folded-face
	       :weight bold)))
  "Face for the display string of folded bold content."
  :group 'noxml-fold)

;; (defvar noxml-fold-folded-italic-face 'noxml-fold-folded-italic-face
;;   "Face for the display string of folded italic content.")

(defface noxml-fold-unfolded-face
  '((((class color) (background light))
     (:background "#f2f0fd"))
    (((class color) (background dark))
     (:background "#38405d"))
    (((class grayscale) (background light))
     (:background "LightGray"))
    (((class grayscale) (background dark))
     (:background "DimGray"))
    (t (:inverse-video t)))
  "Face for folded content when it is temporarily opened."
  :group 'noxml-fold)

;; (defvar noxml-fold-unfolded-face 'noxml-fold-unfolded-face
;;   "Face for folded content when it is temporarily opened.")


(defvar noxml-fold-ellipsis "..."
  "String used as display string for overlays instead of a zero-length string.")

(defcustom noxml-fold-auto nil
  "If non-nil, fold macros automatically.  Leave this at nil for the time being!!"
  :group 'noxml-fold
  :type 'boolean)

(defcustom noxml-fold-command-prefix "\C-c\C-o\C-f"
  "Prefix key to use for commands in noxml-fold mode.

The value of this variable is checked as part of loading
noxml-fold mode.  After that, changing the prefix key requires
manipulating keymaps.  

As a memory aid: the outline commands in `nxml-mode' start with
C-c C-o, and this minor mode adds a C-f for \"fold\"."
  :type 'string
  :group 'noxml-fold)

(defvar noxml-fold-key-bindings
  '(
    ("\C-o" . noxml-fold-dwim)
    ("\C-b" . noxml-fold-buffer)
    ("\C-r" . noxml-fold-region)
    ;; TODO
    ;; ("\C-m" . noxml-fold-macro)
    ;; ("\C-e" . noxml-fold-env)
    ("b"    . noxml-fold-clearout-buffer)
    ("r"    . noxml-fold-clearout-region)
    ("i"    . noxml-fold-clearout-item))
  "Keybindings for noxml-fold mode. 

This is just a list of '(KEY . BINDING) definitions.")

(defvar noxml-fold-keymap
  (let ((map (make-sparse-keymap)))
    (mapc (lambda (key)
	    (define-key map
	      (kbd (concat noxml-fold-command-prefix (car key)))
	      (cdr key)))
	  noxml-fold-key-bindings)
    map))

(defgroup noxml-fold nil
  "Fold xml elements."
  :group 'languages)

(defcustom noxml-fold-unspec-block-display-string "[bl]"
  "Display string for unspecified environments.
This string will be displayed if a single environment is being
hidden which is not specified in `noxml-fold-env-spec-list'."
  :type '(string)
  :group 'noxml-fold)

(defcustom noxml-fold-unspec-inline-display-string "[inl]"
  "Display string for unspecified macros.
This string will be displayed if a single macro is being hidden
which is not specified in `noxml-fold-macro-spec-list'."
  :type '(string)
  :group 'noxml-fold)

(defcustom noxml-fold-unspec-use-name t
  "If non-nil use the name of an unspecified item as display string.
Set it to nil if you want to use the values of the variables
`noxml-fold-unspec-block-display-string' or
`noxml-fold-unspec-inline-display-string' respectively as a display
string for any unspecified macro or environment."
  :type 'boolean
  :group 'noxml-fold)

(defcustom noxml-fold-spec-list '((("TEI" "http://www.tei-c.org/ns/1.0")
				   (("⚓"
				     ("anchor"))
				    ("⚡"
				     ("pb"))
				    ("ₗ"
				     ("lb"))
				    ("⚐"
				     ("note"))
				    ("ₓ"
				     ("gap"))
				    ("➶"
				     ("ref" "ptr"))
				    ("noxml-render-direct-children" nil)
				    (noxml-get-content
				     ("label" "hi" "q" "corr" "subst" "persName" "span" "lem" "rdg" "emph" "del" "unclear" "w" "add"))
				    (noxml-render-first-child
				     ("app"))))
				  (("book")
				   ((noxml-get-content
				     ("emphasis"))
				    (noxml-render-first-child
				     ("chapter")))))
  "A list defining what things to fold, and how.

The list should be an alist associating a group of folding
rules (given in the cdr) with identifiers (given in the car).

So the general structure should be something like this:

'(((\"http://www.tei-c.org/ns/1.0\" \"TEI\" \"tei\") .
   (folding rules for TEI docs))
  (\"http://docbook.org/ns/docbook\" \"book\" \"doc\") .
  (folding rules for docbook docs))

Useful values for identifying the right folding rules are the
namespace and the name of the root element.  Currently this will
work only for the default namespace.

The default configuration contains an example I use for TEI XML,
but should give a rough idea how it works.

The folding rules, stored in the cdr of each element, should be
as follows:

The first element of each item can be a string, an integer or a
function symbol.  The second element is a list of elements to fold.

If the first element is a string, it will be used as a display
replacement for the whole element.

If the first element is a function symbol, the function will be
called with all mandatory arguments of the macro and the result
of the function call will be used as a replacement for the macro.

Setting this variable does not take effect immediately.  Use
Customize or reset the mode."
  :type '(repeat
	  (group (repeat (string :tag "Namespace or root element"))
		 (repeat (group (choice (string :tag "Display String")
					(integer :tag "Number of argument" :value 1)
					(function :tag "Function to execute"))
				(repeat :tag "Element to match" (string))))))
  :group 'noxml-fold)

(defvar noxml-fold-spec-list-local nil
  "Things to fold for a given buffer. Set when mode is loaded.")

;;; utility functions

(defun noxml-find-default-namespace ()
  "Try to find the current document's default namespace."
  ;; (rng-match-possible-namespace-uris)
  (let (namespace)
    (save-excursion
      (xmltok-save
	(save-restriction
	  (widen)
	  (goto-char (point-min))
	  (while (and (xmltok-forward) (not (member xmltok-type '(start-tag empty-element)))) t)
	  (mapc
	   (lambda (x)
	     (when (string= "xmlns" (xmltok-attribute-local-name x))
	       (setq namespace (xmltok-attribute-value x))))
	   xmltok-namespace-attributes)
	  namespace)))))

(defun noxml-find-root-element ()
    "Get (local) name of the root element."
  (let ()
    (save-excursion
      (xmltok-save
	(save-restriction
	  (widen)
	  (goto-char (point-min))
	  (while (and (xmltok-forward) (not (member xmltok-type '(empty-element start-tag)))) t)
	  (xmltok-start-tag-local-name))))))

(defun noxml-find-folding-rules ()
  "Find the applicable folding rules in `noxml-fold-spec-list'.

Finds the folding rules in `noxml-fold-spec-list' by matching the
root element's default namespace, or, failing that, the root
element's local name."
  (let ()
    (unless (= (point-min) (point-max))
      (or
       (car (assoc-default
	     (noxml-find-default-namespace)
	     noxml-fold-spec-list
	     '(lambda (x y) (member y x))))
       (car (assoc-default
	     (noxml-find-root-element)
	     noxml-fold-spec-list
	     '(lambda (x y) (member y x))))))))


(defun noxml-fold-flatten-spec-list (&optional spec-list)
  "Flatten the SPEC-LIST for easy assoc access.

Usually called when the variable `noxml-fold-mode' is set up."
  (let ((spec-list (or spec-list (noxml-find-folding-rules)))
	flat-list)
    (dolist (set spec-list)
      (unless (eq (nth 1 set) nil)
	(dolist (item (nth 1 set))
	  (push (cons item (car set)) flat-list))))
    flat-list))

(defun noxml-element-attribute-get-value (name &optional as-string)
  "Find the value of the last parsed element's attribute NAME.

If NAME is a string, look for that attribute.

If NAME is a list of strings, look for all those attributes.

If NAME is anything else, return all attributes.

If attributes are found, return an alist of the elements, like
'((attname . value) (attname2 . value)).  If AS-STRING is not
nil, return the attributes and values as a string."
    (let ((atts (or xmltok-attributes xmltok-namespace-attributes))
	  result
	  (names (cond
		  ((stringp name) (list name))
		  ((listp name) (mapcar (lambda (x) (if (stringp x) x)) name))
		  (t t))))
      (while atts
	(let* ((attribute (car atts))
	       (name-start (xmltok-attribute-name-start attribute))
	       (att-name (buffer-substring-no-properties (xmltok-attribute-name-start attribute) (xmltok-attribute-name-end attribute)))
	       (att-value (buffer-substring-no-properties (xmltok-attribute-value-start attribute) (xmltok-attribute-value-end attribute))))
	  (when (or (eq t names) (member att-name names))
	    (push (cons att-name att-value) result))
	  (setq atts (cdr atts))))
      (if (and as-string result)
	  (let ((result-string ""))
	    (dolist (item result)
	      (setf result-string (format "@%s=\"%s\" | " (car item) (cdr item))))
	    (substring result-string 0 (- (length result-string) 3)))
	  result)))

(defun noxml-find-element-start (position)
  "Find start of the element around POSITION.

If point is in data, comment, or closing tag, returns position of
the opening tag.

If point is in empty element, returns start of that element.

See also:
http://www.dpawson.co.uk/relaxng/nxml/nxmlGeneral.html
`(nxml-beginning/end-of-element)'."
  (interactive "d")
  (save-excursion
    (xmltok-save
      (let((nxml-sexp-element-flag nil))
	(progn
	  (goto-char position) ;; go where we want
	  (goto-char	      ;; go to the end of the element
	   (if (looking-at "<")
	       (nxml-token-after)
	     (nxml-token-before)))
	  (nxml-token-before)
	  (cond
	   ((eq xmltok-type 'empty-element) t)
	   ((memq xmltok-type '(data space)) (progn (nxml-scan-element-backward (point) t) xmltok-start))
	   ((string-equal xmltok-type "start-tag") t) ;; already evaluated above
	   ((string-equal xmltok-type "end-tag") (progn (nxml-backward-element))) ;;	  
	   (t t)
	   )
	  (if (called-interactively-p 'interactive)
	      (message "The element starts at char: %d" xmltok-start)
	    xmltok-start))))))

(defun noxml-find-element-end (position)
  "Return the position of the element starting at POSITION."
  (save-excursion
    (let ((nxml-sexp-element-flag nil)
	  (start-element (noxml-find-element-start position))
	  end-of-end-tag
	  xmltok-start)
      (progn
	(setq end-of-end-tag (nxml-scan-element-forward start-element))
	end-of-end-tag))))

(defun noxml-fold-make-overlay (ov-start ov-end type display-string-spec priority)
  "Make a noxml-fold overlay extending from OV-START to OV-END.
TYPE is a symbol which is used to describe the content to hide
and may be 'inline for inline elements or 'block for block
elements.  DISPLAY-STRING-SPEC is the original specification of
the display string in the variable `noxml-fold-spec-list' and may
be a string or an integer.  PRIORITY sets the priority of the
item.

TODO: review info:nxml-mode#Paragraphs for a different (better?) solution."
  ;; Calculate priority before the overlay is instantiated.  We don't
  ;; want `noxml-overlay-prioritize' to pick up a non-prioritized one.
  (let* (;;(priority (noxml-overlay-prioritize ov-start ov-end type))
	(ov (make-overlay ov-start ov-end (current-buffer) t nil)))
    (overlay-put ov 'category 'noxml-fold)
    (overlay-put ov 'priority priority)
    (overlay-put ov 'evaporate t)
    (overlay-put ov 'noxml-fold-type type)
    (overlay-put ov 'noxml-fold-display-string-spec display-string-spec)
    ov))

(defun noxml-overlay-prioritize (start end &optional type)
  "Calculate a priority for an overlay from START to END.

The optional TYPE should be 'inline, otherwise we default to
'block.  The calculated priority is lower than the minimum of
priorities of surrounding overlays and higher than the maximum of
enclosed overlays."
  (save-excursion
    (let ((ov-depth 0)
	  (nxml-sexp-element-flag nil)
	  (factor noxml-overlay-priority-step)
	  (type (or type (if (progn (goto-char start) (nxml-token-after) (noxml-is-inline))
			     'inline
			   'block))))
      (when (eq type 'inline);; block always has 0, keeping it visible under all conditions
	(while (and (< (point-min) (point));; see http://www.emacswiki.org/emacs/NxmlMode#toc11 for this test
		    (condition-case nil
			;; returns nil also for highest level
			;; element, but error if outside its end
			;; tag; either way, stop scanning
			(let ((pos (point)))
			  (nxml-backward-up-element)
			  ;; if no error was signalled, return t if we moved, otherwise nil
			  (not (= pos (point))))
		      (error nil))
		    ;; stop at block level element
		    (noxml-is-inline))
	  (setq ov-depth (- ov-depth factor))))
      ov-depth)))

(defun noxml-make-overlay-invisible ()
  "Hides the element surrounding point."
  (interactive)
  (save-excursion
    (let* (;; let* creates args sequentially; earlier definitions available in later definitions
	   (element-start (noxml-find-element-start (point)))
	   (element-end (noxml-find-element-end (point)))
	   (text (filter-buffer-substring element-start element-end))
	   (element (concat (substring text 0 2) "../>"))
	   (noxmloverlay (make-overlay element-start element-end)))
      ;; here, we're at the end of the element
      (overlay-put noxmloverlay 'display element)
      (overlay-put noxmloverlay 'intangible ())
      (overlay-put noxmloverlay 'category 'noxml-fold))))

(defun noxml-render-first-child (position)
  "Render the first child of element at POSITION.

Useful for stuff like <app><lem>, or <choice><sic>."
  (let* (
	 (nxml-sexp-element-flag nil)
	 (start (noxml-find-element-start position))
	 (end (noxml-find-element-end start))
	 (content "[no content found]"))
    (save-excursion
      (progn
	(goto-char start)
	(nxml-forward-balanced-item);; to the end of elem1
	(nxml-forward-balanced-item);; either at end of elem2's opening tag, or at the end of elem1
	(if (= (point) end);; if at the end
	    (setq content (noxml-fold-get-element-name start));; elem1's empty, use its name
	  (nxml-backward-up-element);; go to the beginning of elem2
	  )
	(if (>= (point) end);; if the element has no content
	    (setq content (noxml-fold-get-element-name start));; use the element name
	  (while (< (point) end);; start walking forward
	    (cond ((looking-at "<[/!]");; are we at the start of an end tag or comment?
		   (nxml-forward-balanced-item));; then skip ahead and
						;; see what happens
						;; (we won't leave the
						;; context, because
						;; the while clause is
						;; still in effect)
		  (
		   (looking-at "<[a-zA-Z0-9]+");; the first element; we'll use its content
		   (progn
		     (setq content (noxml-get-content (point)));; that's all we wanted, so go to end
		     (goto-char end)))
		  (t (setq content "[no sub-element found]");; the default behaviour
		     ))
	    ))))
    content))

(defun noxml-render-direct-children (position)
  "Render element at POSITION, showing all its direct children.

Useful for stuff like <lg><l/><l/> etc."
  (let* (
	(start (noxml-find-element-start position))
	(end (noxml-find-element-end start))
	(nxml-sexp-element-flag nil)
	(content "[no content found]")
	name-of-child
	)
    (save-excursion
      (progn
	(goto-char start)
	(nxml-forward-balanced-item);; to the end of elem1
	(nxml-forward-balanced-item);; either at end of elem2's opening tag, or at the end of elem1
	(if (= (point) end);; if at the end
	    (setq content (noxml-fold-get-element-name start));; elem1's empty, use its name
	  (nxml-backward-up-element);; go to the beginning of elem2
	  )
	(if (>= (point) end);; if the element has no content
	    (setq content (noxml-fold-get-element-name start));; use the element name
	  (while (< (point) end);; start walking forward
	    (cond ((looking-at "<[/!]");; are we at the start of an end tag or comment?
		   (nxml-forward-balanced-item));; then skip ahead and
						;; see what happens
						;; (we won't leave the
						;; context, because
						;; the while clause is
						;; still in effect)
		  ((looking-at "<[a-zA-Z0-9]+");; an element; let's have a closer look
		   (progn
		     (if (not name-of-child);; if we haven't found a child yet
			 (progn (setq name-of-child (noxml-fold-get-element-name (point));; set its name
			   content (noxml-get-content (point)));; and use its content
				(nxml-forward-element);; and skip forward to start of next sibling
				(nxml-forward-balanced-item)
				(nxml-backward-up-element)
				)
		       (progn ;; if we've found a child already, check if the current element has the same name
			(if (string= name-of-child (noxml-fold-get-element-name (point)))
			    (progn ;; if its the same, append its value to content
			      (nxml-forward-balanced-item)
			      (setq content (concat content "\n" (filter-buffer-substring (point) (progn (nxml-forward-balanced-item) (point))))))
			  (nxml-forward-element);; not so interesting if it's not the same as the child
			   )
			))))
		  (t  ;; per default: take the text here along (could be a tail of some element)
		   (setq content (concat content (filter-buffer-substring (point) (progn (nxml-forward-balanced-item) (point)))))))))
	content ))))

(defun noxml-get-content (position)
  "Gets the content of the element in overlay at POSITION in buffer."
  (let* (
	(from-here (noxml-find-element-start position))
	(to-here (noxml-find-element-end from-here))
	(nxml-sexp-element-flag t)
	content)
    (save-excursion
      (goto-char to-here)
      (while (> (point) from-here)
	  (goto-char (progn (nxml-token-before) xmltok-start))
	  (cond
	   ;; if the element starts at the beginning of the region, and is empty
	   ((and (= xmltok-start from-here)
		 (eq xmltok-type 'empty-element))
	    (setq content (noxml-fold-get-element-name xmltok-start)));; return its name
	   ;; if this is the end tag of the whole element, just ignore
	   ((= (nxml-token-after) to-here) t)
	   ((memq xmltok-type '(end-tag empty-element));; so this is a child element: use its overlays as content
	      ;; (progn
	      ;;   (noxml-fold-item 'block);; fold the region of the subelement here
	      ;; )
	    (progn
	      (goto-char (noxml-find-element-start (point)))
	      (let ((overlays (overlays-at (point))))
		(dolist (overlay overlays)
		  (if (overlay-get overlay 'display)
		      (setq content (concat (substring-no-properties (overlay-get overlay 'display)) content )))
		  ))))
	   ((eq xmltok-type 'start-tag);; if we're on a start tag, ignore
	    t)
	   ((memq xmltok-type '(data space))
	    (setq content (concat (filter-buffer-substring xmltok-start (nxml-token-after)) content )))
	   (t t)))
	content)))

(defun noxml-fold-clearout-region (start end)
  "Permanently show all elements in region starting at START and ending at END."
  (interactive "r")
  (let ((overlays (overlays-in start end)))
    (noxml-fold-remove-overlays overlays)))

(defun noxml-fold-clearout-buffer ()
  "Permanently show all macros in the buffer."
  (interactive)
  (noxml-fold-clearout-region (point-min) (point-max)))

(defun noxml-fold-clearout-item ()
  "Remove all folds from the element on which point currently is located (and its children)."
  (interactive)
  (let ((overlays (overlays-in (noxml-find-element-start (point)) (noxml-find-element-end (point)))))
    (noxml-fold-remove-overlays overlays)))

(defun noxml-fold-remove-overlays (overlays)
  "Remove all overlays set by noxml-fold in OVERLAYS.

Return non-nil if a removal happened, nil otherwise.  See
`TeX-fold-remove-overlays'."
  (let (found)
    (while overlays
      (when (eq (overlay-get (car overlays) 'category) 'noxml-fold)
	(delete-overlay (car overlays))
	(setq found t))
      (setq overlays (cdr overlays)))
    found))

(defun noxml-fold-get-element-name (position)
  "Return the name of the element POSITION is in, or, if POSITION is on an opening tag, that tag's name."
  (let ((nxml-sexp-element-flag nil))
   (save-excursion
     (goto-char position)
     (if (looking-at "<[^/!]")
	 (nxml-forward-balanced-item))
     (progn
       (nxml-scan-element-backward (nxml-token-before) t)
       (goto-char xmltok-start)	;; xmltok-start is set by nxml-scan-element-backward
       (xmltok-start-tag-local-name)))))

(defun noxml-fold-visible (&optional around-screen)
  "Fold what's approximately on the current screen.

AROUND-SCREEN gives the number of chars outside the screen to
consider in folding.  Defaults to `noxml-fold-add-to-screen', and
falls back to 2000."
  (interactive
   (list (if current-prefix-arg (read-number "How many chars: ") noxml-fold-add-to-screen)))
  (let ((around-screen (or around-screen noxml-fold-add-to-screen 2000)))
    (noxml-fold-region (max (point-min) (- (window-start) around-screen)) (min (point-max) (+ (window-end) around-screen)))))

(defun noxml-fold-region (start end)
  "Fold all complete items in region from START to END."
  (interactive "r")
  (save-excursion
    (save-restriction
      (let ((from-here start)
	   (to-here end)
	   (current-relative-depth 0)
	   (nxml-sexp-element-flag nil)
	   whackTree;; where we store tag starts and ends
	   elementVals)
	(progn
	  (narrow-to-region from-here to-here)
	  (goto-char to-here)
	;; walk through the region backwards, folding every proper element
	  (while (and (> (point) from-here)
		      (progn
			(nxml-token-before);; check where we are
			xmltok-type));; xmltok-type is nil if there's no token before
	    (progn
	      (if (member xmltok-type  (list 'start-tag 'end-tag 'empty-element));; if interesting
		  (unless (not (or whackTree (eq xmltok-type 'end-tag) (eq xmltok-type 'empty-element)));; make sure start-tag is not the first that's added to the tree
		    (progn
		      (add-to-list 'whackTree (cons xmltok-start (point)));; remember the current tag's start and end point
		      (setq elementVals ;; we need this for folding below
			    (cond
			     ((equal xmltok-type 'start-tag) (cons (pop whackTree) (pop whackTree)
								   ;; cut out this element's start and end cons cell from the whackTree, that is, the first two elements.
								   ))
			     ((equal xmltok-type 'empty-element)
			      (pop whackTree)
			      )
			     ))
		      (if (member xmltok-type (list 'start-tag 'empty-element))
			  (if (noxml-is-inline)
			      (noxml-fold-item 'inline elementVals (* (- 0 (length whackTree)) noxml-overlay-priority-step))
			    (noxml-fold-item 'block elementVals (* (- 0 (length whackTree)) noxml-overlay-priority-step)))
			))))
	      (goto-char xmltok-start)
	      t)))))))

(defun noxml-is-inline ()
  "Find out if last scanned element is an inline element or not.

We simply check whether the start tag is preceded by only white
space or nothing to the start of the line (see
`noxml-is-not-inline-regexp' for the regex used).  You can
override this (schema independently!) by adding the element name
to `noxml-inline-elements' or `noxml-block-elements'."
  (save-excursion
    (let ((block-regexp (or noxml-is-not-inline-regexp "^\\s-*<[^/]"))
	  is-inline)
      (if (member (xmltok-start-tag-local-name) noxml-inline-elements)
	  t
	(if (member (xmltok-start-tag-local-name) noxml-block-elements)
	    nil
	  (if (and xmltok-start (not (eq xmltok-type ())))
	      (unless (eq xmltok-start (point-min))
		(progn
		  (goto-char (+ 2 xmltok-start))
		  (if (not (looking-back block-regexp  (- xmltok-start 50)))
		      t
		      ())))))))))

(defun noxml-fold-buffer ()
  "Hide all configured macros and environments in the current buffer.
The relevant macros are specified in the variable `noxml-fold-macro-spec-list'
and `noxml-fold-math-spec-list', and environments in `noxml-fold-env-spec-list'."
  (interactive)
  (noxml-fold-clearout-region (point-min) (point-max))
  (noxml-fold-region (point-min) (point-max)))


(defun noxml-fold-item (type positions &optional depth)
  "Hide an item of TYPE at .

TYPE specifies the type of item and can be one of the symbols
'inline or 'block, for inline and block elements respectively.

ELEMENTPOSITIONS specifies where the element starts and ends (or
start and end of opening and closing element of block elements).

DEPTH specifies the depth in the document tree (if not supplied,
we try to find out).  Return non-nil if an item was found and
folded, nil otherwise.  Based on `TeX-fold-item'."
  (save-excursion
    (let* ((item-start
	    (if (listp (car positions))
		(caar positions)
	      (car positions)))
	   (item-end (if (listp (cdr positions))
			 (cdr (cdr positions))
		       (cdr positions)))
	   (item-name (if (and xmltok-start (= item-start xmltok-start))
			  (xmltok-start-tag-qname)
			(save-excursion
			  (xmltok-save
			    (goto-char item-start)
			    (xmltok-forward)
			    (xmltok-start-tag-qname))))))
      (when item-start
	(let* (
	       ;; figure out what this item is called (setq item-name 'anchor)
	       ;; (item-end (noxml-find-element-end item-start))
	       (starts-and-ends ;; a list of the start and end of each thing that should be overlayed here
		(if (and (not (eq xmltok-type 'empty-element)) (eq type 'block))
		    (list
		     (cons item-start
			   (cdr (car positions)))
		     (cons
		      (car (cdr positions))
		      item-end))
		  (list (cons item-start item-end))))
	       (display-string-spec ;; what to show when folding
		(or
		 (cdr (assoc item-name noxml-fold-spec-list-local))
		 (if noxml-fold-unspec-use-name
			(concat "[" item-name "]")
		      (if (eq type 'block)
			  noxml-fold-unspec-block-display-string
			noxml-fold-unspec-inline-display-string))))
	       (ovs ;; set up a list of the overlays
		 (mapcar
		  (lambda (start-and-end)
		    (noxml-fold-make-overlay
		     (car start-and-end)
		     (cdr start-and-end)
		     type display-string-spec
		     (if depth
			 (* depth noxml-overlay-priority-step)
		       ;; recalculate overlay depth if not supplied
		       (noxml-overlay-prioritize (car start-and-end) (cdr start-and-end)))))
		  starts-and-ends)))
	  (noxml-fold-hide-item ovs))))))

(defun noxml-expression-start-end (position)
  "Find the start and end of an item at POSITION."
  (let ((nxml-sexp-element-flag nil))
    (save-excursion
      (let ((position position))
	(progn
	  (goto-char position)
	  (list (cons
		 position
		 (nxml-token-after))))))))

(defun noxml-fold-make-help-echo (start end)
  "Return a string to be used as the help echo of folded overlays.
The text between START and END will be used for this but cropped
to the length defined by `noxml-fold-help-echo-max-length'.  Line
breaks will be replaced by spaces.  This is also what gets shown when
the mouse is on the point."
  (let* ((spill (+ start noxml-fold-help-echo-max-length))
	 (lines (split-string (buffer-substring start (min end spill)) "\n"))
	 (result (pop lines)))
    (dolist (line lines)
      ;; Strip leading whitespace
      (when (string-match "^[ \t]+" line)
	(setq line (replace-match "" nil nil line)))
      ;; Strip trailing whitespace
      (when (string-match "[ \t]+$" line)
	(setq line (replace-match "" nil nil line)))
      (setq result (concat result " " line)))
    (when (> end spill) (setq result (concat result "...")))
    result))

(defun noxml-fold-partition-list (p l)
  "Use P to partition list L.

The function returns a `cons' cell where the `car' contains
elements of L for which P is true while the `cdr' contains the
other elements.  The ordering among elements is maintained."
  (let (car cdr)
    (dolist (x l)
      (if (funcall p x) (push x car) (push x cdr)))
    (cons (nreverse car) (nreverse cdr))))

;; this allows us to use a function instead of the simple invisible
;; property: we have to set invisible to this:
;; (put 'noxml-fold 'reveal-toggle-invisible 'noxml-fold-reveal-toggle-invisible)

(defun noxml-fold-show-item (ov)
  "Show a single element.
Remove the respective properties from the overlay OV."
  (overlay-put ov 'mouse-face nil)
  (if (featurep 'xemacs)
      (progn
	(set-extent-property ov 'end-glyph nil)
	(overlay-put ov 'invisible nil))
    (overlay-put ov 'display nil)
    (overlay-put ov 'help-echo nil)
    (when font-lock-mode
      (overlay-put ov 'face 'noxml-fold-unfolded-face))))

(defun noxml-fold-post-command ()
  "Take care to fold/unfold stuff as we move along."
  ;; `with-local-quit' is not supported in XEmacs.
  (condition-case nil
      (let ((inhibit-quit nil))
	(condition-case err
	    (let* ((spots (noxml-fold-partition-list
			   (lambda (x)
			     ;; We refresh any spot in the current
			     ;; window as well as any spots associated
			     ;; with a dead window or a window which
			     ;; does not show this buffer any more.
			     (or (eq (car x) (selected-window))
				 (not (window-live-p (car x)))
				 (not (eq (window-buffer (car x))
					  (current-buffer)))))
			   noxml-fold-open-spots))
		   (old-ols (mapcar 'cdr (car spots))))
	      (setq noxml-fold-open-spots (cdr spots))
	      (when (or (and (boundp 'disable-point-adjustment)
			     disable-point-adjustment)
			(and (boundp 'global-disable-point-adjustment)
			     global-disable-point-adjustment)
			;; See preview.el on how to make this configurable.
			(memq this-command
			      (list (key-binding [left]) (key-binding [right])
				    'backward-char 'forward-char
				    'mouse-set-point)))
		;; Open new overlays.
		(dolist (ol (nconc (when ;; we use either the overalays in the region
				       (and noxml-fold-unfold-around-mark
					      (boundp 'mark-active)
					      mark-active)
				     (overlays-at (mark)))
				   (overlays-at (point))));; or at the point
		  (when (eq (overlay-get ol 'category) 'noxml-fold)
		    (push (cons (selected-window) ol) noxml-fold-open-spots)
		    (setq old-ols (delq ol old-ols))
		    (noxml-fold-show-item ol))))
	      ;; Close old overlays.
	      (dolist (ol old-ols)
		(when (and (eq (current-buffer) (overlay-buffer ol))
			   (not (rassq ol noxml-fold-open-spots))
			   (or (not (featurep 'xemacs))
			       (and (featurep 'xemacs)
				    (not (extent-detached-p ol)))))
		  (if (and (>= (point) (overlay-start ol))
			   (<= (point) (overlay-end ol)))
		      ;; Still near the overlay: keep it open.
		      (push (cons (selected-window) ol) noxml-fold-open-spots)
		    ;; Really close it.
		    (noxml-fold-hide-item (list ol))))))
	  (error (message "noxml-fold: %s" err))))
    (quit (setq quit-flag t))))

(defun noxml-fold-hide-item (ovs)
  "Hide a single inline or block item in current overlay list OVS.

That means, put respective properties onto overlay.  Based on
`TeX-fold-hide-item'."
  (dolist (ov ovs)
    (let* ((nxml-sexp-element-flag nil)
	   (ov-start (overlay-start ov))
	   (ov-end (overlay-end ov))
	   (spec (overlay-get ov 'noxml-fold-display-string-spec))
	   (computed (cond ;; the specification spec can be either a string or a function
		      ((stringp spec)
		     ;;(noxml-fold-expand-spec spec ov-start ov-end);; yes, not really relevant for xml folding i think
		     spec)
		    ((functionp spec);; if we have a function to call here
		     (let ((arg ov-start) result)
		       (setq result (or (condition-case nil
					    (save-restriction
					      (apply spec arg nil));; the nil is necessary, last arg to apply is a list
					  ;; (noxml-render-first-child arg)
					  ;; (noxml-render-direct-children arg)
					  (error nil))
					(format "[Error: Content extraction function %s had a problem.]" spec)))
		       (nxml-token-before);; reset scan state
		       result;; show result
		       ))
		    (t "[Error: No content found]")))
	 (display-string (if (listp computed) (car computed) computed))
	 (face (when (listp computed) (cadr computed))))
    ;; Cater for zero-length display strings.
    (when (string= display-string "") (setq display-string noxml-fold-ellipsis))
    ;; Add a linebreak to the display string and adjust the overlay end
    ;; in case of an overfull line.
    (when (noxml-fold-overfull-p ov-start ov-end display-string)
      (setq display-string (concat display-string "\n"))
      (move-overlay ov ov-start (save-excursion
				  (goto-char ov-end)
				  (skip-chars-forward " \t")
				  (point))))
    (overlay-put ov 'mouse-face 'highlight)
    (overlay-put ov 'display display-string);; see info: File: elisp,  Node: Text Props and Strings,  Prev: Nonprinting Characters,  Up: String Type
    (if (featurep 'xemacs)
	(let ((glyph (make-glyph (if (listp display-string)
				     (car display-string)
				   display-string))))
	  ;; (overlay-put ov 'invisible t)
	  (overlay-put ov 'invisible 'noxml-fold)
	  (when font-lock-mode
	    (if face
		(set-glyph-property glyph 'face face)
	      (set-glyph-property glyph 'face 'noxml-fold-folded-face)))
	  (set-extent-property ov 'end-glyph glyph))
      (when font-lock-mode
	(overlay-put ov 'face (noxml-get-face ov)))
      (unless (zerop noxml-fold-help-echo-max-length)
	(overlay-put ov 'help-echo (noxml-fold-make-help-echo
				    (overlay-start ov) (overlay-end ov))))))))

(defun noxml-get-face (ov)
  "Get the face to use for overlay OV."
  (let ((ov-start (overlay-start ov))
	(ov-end (overlay-end ov)))
    (save-excursion
      (xmltok-save
	(goto-char ov-start)
	(xmltok-forward)
	(cond ((= ov-end (point)) 'noxml-fold-tag-face)
	      ((and (eq xmltok-type 'start-tag)
		    (member (xmltok-start-tag-local-name) '("hi" "emph")))
	       (cond ((member '("rend" . "bold")
			      (noxml-element-attribute-get-value t))
		      'noxml-fold-folded-bold-face)
		     (t 'noxml-fold-folded-italic-face)))
	      (t 'noxml-fold-folded-face))))))

(defun noxml-fold-dwim ()
  "Hide or show items according to the current context.
If there is folded content, unfold it.  If there is a marked
region, fold all configured content in this region.  If there is
no folded content but an inline  or block element, fold it."
  (interactive)
  (cond ((use-region-p)
	 (cond
	  ((noxml-fold-clearout-region (region-beginning) (region-end)) (message "Unfolded region."))
	  ((noxml-fold-region (region-beginning) (region-end)) (message "Folded element."))))
	((overlays-at (point)) (noxml-fold-clearout-item) (message "Unfolded item."))
	(t (progn
	     (noxml-fold-clearout-buffer)
	     (noxml-fold-visible)
	     (message "Folded window.")))))

;; (defun noxml-make-overlay-visible (position)
;;   (interactive "d");; interactive, with the point of the mark as an integer
;;   (let (
;; 	(noxmlov (make-overlay (noxml-find-element-start (point)) (noxml-find-element-end (point)) ))
;; 	)
;;     (overlay-put noxmlov 'invisible nil)
;;     ))

;; I think this is not very useful for xml-folding:
;; (defun noxml-fold-expand-spec (spec ov-start ov-end)
;;   "Expand instances of {<num>}, [<num>], <<num>>, and (<num>).
;; Replace them with the respective macro argument."
;;   (let ((spec-list (split-string spec "||"))
;; 	(delims '((?{ . ?}) (?[ . ?]) (?< . ?>) (?\( . ?\))))
;; 	index success)
;;     (catch 'success
;;       ;; Iterate over alternatives.
;;       (dolist (elt spec-list)
;; 	(setq spec elt
;; 	      index nil)
;; 	;; Find and expand every placeholder.
;; 	(while (and (string-match "\\([[{<]\\)\\([1-9]\\)\\([]}>]\\)" elt index)
;; 		    ;; Does the closing delim match the opening one?
;; 		    (string-equal
;; 		     (match-string 3 elt)
;; 		     (char-to-string
;; 		      (cdr (assq (string-to-char (match-string 1 elt))
;; 				 delims)))))
;; 	  (setq index (match-end 0))
;; 	  (let ((arg (car (save-match-data
;; 			    ;; Get the argument.
;; 			    (noxml-fold-macro-nth-arg
;; 			     (string-to-number (match-string 2 elt))
;; 			     ov-start ov-end
;; 			     (assoc (string-to-char (match-string 1 elt))
;; 				    delims))))))
;; 	    (when arg (setq success t))
;; 	    ;; Replace the placeholder in the string.
;; 	    (setq elt (replace-match (or arg noxml-fold-ellipsis) nil t elt)
;; 		  index (+ index (- (length elt) (length spec)))
;; 		  spec elt)))
;; 	(when success (throw 'success nil))))
;;     spec))

;; (defun noxml-fold-macro-nth-arg (n macro-start &optional macro-end delims)
;;   "Return a property list of the argument number N of a macro.
;; The start of the macro to examine is given by MACRO-START, its
;; end optionally by MACRO-END.  With DELIMS the type of delimiters
;; can be specified as a cons cell containing the opening char as
;; the car and the closing char as the cdr.  The chars have to have
;; opening and closing syntax as defined in
;; `TeX-search-syntax-table'.

;; The first item in the returned list is the string specified in
;; the argument, the second item may be a face if the argument
;; string was fontified.  In Emacs the string holds text properties
;; as well, so the second item is always nil.  In XEmacs the string
;; does not enclose any faces, so these are given in the second item
;; of the resulting list."
;;   (save-excursion
;;     (let* ((macro-end (or macro-end
;; 					  (noxml-find-element-end macro-start)))
;; 	   (open-char (if delims (car delims) ?<))
;; 	   (open-string (char-to-string open-char))
;; 	   (close-char (if delims (cdr delims) ?>))
;; 	   (close-string (char-to-string close-char))
;; 	   content-start content-end)
;;       (goto-char macro-start)
;;       (if (condition-case nil
;; 	      (progn
;; 		(while (> n 0)
;; 		  (skip-chars-forward (concat "^" open-string) macro-end)
;; 		  (when (= (point) macro-end)
;; 		    (error nil))
;; 		  (setq content-start (progn
;; 					(skip-chars-forward
;; 					 (concat open-string " \t"))
;; 					(point)))
;; 		  (noxml-find-element-end macro-start)
;; 		  (setq content-end (save-excursion
;; 				      (backward-char)
;; 				      (skip-chars-backward " \t")
;; 				      (point)))
;; 		  (setq n (1- n)))
;; 		t)
;; 	    (error nil))
;; 	  (list (noxml-fold-buffer-substring content-start content-end)
;; 		(when (and (featurep 'xemacs)
;; 			   (extent-at content-start))
;; 		  ;; A glyph in XEmacs does not seem to be able to hold more
;; 		  ;; than one face, so we just use the first one we get.
;; 		  (car (extent-property (extent-at content-start) 'face))))
;; 	nil))))

(defun noxml-fold-overfull-p (ov-start ov-end display-string)
  "Return t if an overfull line will result after adding an overlay.
The overlay extends from OV-START to OV-END and will display the
string DISPLAY-STRING."
  (and (not (featurep 'xemacs)) ; Linebreaks in glyphs don't
				; work in XEmacs anyway.
       (save-excursion
	 (goto-char ov-end)
	 (search-backward "\n" ov-start t))
       (not (string-match "\n" display-string))
       (> (+ (- ov-start
		(save-excursion
		  (goto-char ov-start)
		  (line-beginning-position)))
	     (length display-string)
	     (- (save-excursion
		  (goto-char ov-end)
		  (line-end-position))
		ov-end))
	  (current-fill-column))))
  
(defun noxml-fold-buffer-substring (start end)
  "Return the contents of buffer from START to END as a string.
Like `buffer-substring' but copy overlay display strings as well."
  ;; Swap values of `start' and `end' if necessary.
  (when (> start end) (let ((tmp start)) (setq start end end tmp)))
  (let ((overlays (overlays-in start end))
	result)
    ;; Get rid of overlays not under our control or not completely
    ;; inside the specified region.
    (dolist (ov overlays)
      (when (or (not (eq (overlay-get ov 'category) 'noxml-fold))
		(< (overlay-start ov) start)
		(> (overlay-end ov) end))
	(setq overlays (remove ov overlays))))
    (if (null overlays)
	(buffer-substring start end)
      ;; Sort list according to ascending starts.
      (setq overlays (sort (copy-sequence overlays)
			   (lambda (a b)
			     (< (overlay-start a) (overlay-start b)))))
      ;; Get the string from the start of the region up to the first overlay.
      (setq result (buffer-substring start (overlay-start (car overlays))))
      (let (ov)
	(while overlays
	  (setq ov (car overlays)
		overlays (cdr overlays))
	  ;; Add the display string of the overlay.
	  (setq result (concat result (overlay-get ov 'display)))
	  ;; Remove overlays contained in the current one.
	  (dolist (elt overlays)
	    (when (< (overlay-start elt) (overlay-end ov))
	      (setq overlays (remove elt overlays))))
	  ;; Add the string from the end of the current overlay up to
	  ;; the next overlay or the end of the specified region.
	  (setq result (concat result (buffer-substring (overlay-end ov)
							(if overlays
							    (overlay-start
							     (car overlays))
							  end))))))
      result)))


;; simple hide/show element things
(defun noxml-fold-hide-show-element (&optional interactive)
  "Show/hide the current element's content and children.

Will only trigger when cursor is on the \"<\" of a start tag, and
only when INTERACTIVE is non-nil."
  (interactive
   (list 'yepp))
  (save-match-data
    (when interactive
      (if (looking-at "<[^/]")
	  (noxml-fold-outline-flag-region (point))
	;; otherwise unbind, call, and then rebind key: really not
	;; an elegant solution
	(define-key noxml-fold-keymap (kbd "<tab>") nil)
	(call-interactively (key-binding "\t" :accept-default))
	(define-key noxml-fold-keymap (kbd "<tab>") 'noxml-fold-hide-show-element)))))

(defun noxml-fold-outline-flag-region (from &optional flag)
  "Hide or show element starting at FROM.

Optional FLAG should be either 'children, to show children, 'all,
to show everything, or, 'none to hide everything.

Whether to hide or show the thing is decided from the overlay-property.

Based on `outline-flag-region'."
  (let* ((nxml-sexp-element-flag t)
	 (to (save-excursion (nxml-forward-balanced-item) (point)))
	 (state (and
		 (overlays-at from)
		 (cl-some (lambda (x) (overlay-get x 'noxml-fold-hidden))
			  (overlays-at from))))
	 (flag (or flag
		   (cond ((eq state 'all) 'children)
			 ((eq state 'children) 'none)
			 (t 'all))))
	 (display-string (save-excursion
			   (xmltok-save
			     (xmltok-forward)
			     (cond ((member xmltok-type '(start-tag empty-element))
				    (format "<%s ... />" (xmltok-start-tag-local-name)))
				   (t "some-folded-thing"))))))
    (remove-overlays from to 'category 'noxml-fold)
    (cond
     ;; fold everything
     ((eq flag 'all)
      (let ((o (make-overlay from to)))
	(overlay-put o 'evaporate t)
	(overlay-put o 'display display-string)
	(overlay-put o 'noxml-fold-hidden 'all)
	(overlay-put o 'noxml-fold-display-string-spec display-string)
	(overlay-put o 'category 'noxml-fold)
	(when font-lock-mode
	  (overlay-put o 'face 'noxml-fold-folded-face))))
     ;; fold away children
     ((eq flag 'children)
      (let ((o (make-overlay from to)))
	(overlay-put o 'noxml-fold-hidden 'children)
	(overlay-put o 'category 'noxml-fold)
	(save-excursion
	  (save-restriction
	    (xmltok-save
	     (narrow-to-region from to)
	     (xmltok-forward)
	     ;; make sure we pass the first start tag
	     (when (eq xmltok-type 'start-tag)
	       ;; go to the next start tag
	       (while (and (xmltok-forward) (not (eq xmltok-type 'start-tag))) t)
	       (goto-char xmltok-start)
	       (noxml-fold-outline-flag-region (point) 'all)
	       (while (and
		       (condition-case nil (nxml-forward-single-balanced-item) (error nil))
		       (not (eobp)))
		 ;; make sure we're at the right position
		 (save-excursion
		   (while (and (not (eobp)) (xmltok-forward) (not (eq xmltok-type 'start-tag))) t))
		 (when (member xmltok-type '(start-tag empty-element))
		   (goto-char xmltok-start)
		   (noxml-fold-outline-flag-region (point) 'all))))))))))))



;; not strictly useful for folding
(defun noxml-where-am-i (&optional attributes)
  "Show current position as a path of elements.

If ATTRIBUTES is a list (e.g., '(xml:id xml:lang type)), the
returned path will contain the values for those attributes, when
applicable.

If ATTRIBUTES is not nil and not a list, show all attributes.

Follows a suggestion from
http://www.emacswiki.org/emacs/NxmlMode#toc11."
  (interactive
   (let (atts)
     (when current-prefix-arg
       (setq atts (split-string (read-string "List attributes to show, or leave empty to show all: " )))
       (list (or atts t)))))
  (let ((nxml-sexp-element-flag nil)
	path)
    (save-excursion
      (save-restriction
	(widen)
	(while (and (< (point-min) (point)) ;; Doesn't error if point is at beginning of buffer
		    (condition-case nil
			(progn
			  (nxml-backward-up-element) ; always returns nil
			  t)
		      (error nil)))
	  (setq path (cons (concat (xmltok-start-tag-local-name)
				   (format "%s" (or (noxml-element-attribute-get-value attributes 'as-string) "")))
			   path)))
	(if (called-interactively-p t)
	    (message "/%s" (mapconcat 'identity path "/"))
	  (format "/%s" (mapconcat 'identity path "/")))))))

;;; load everything as minor mode
;;;###autoload
(define-minor-mode noxml-fold-mode
  "Minor mode for hiding and revealing XML tags.

The main entry point is `noxml-fold-dwim', by default bound to
\"C-c C-o C-f C-o\".  To unfold everything, call
`noxml-fold-clearout-buffer', \"C-c C-o C-f b\" by default.

Keyboard shortcuts: 

\\{noxml-fold-keymap}

See `noxml-fold-key-bindings' and `noxml-fold-command-prefix' to
configure keyboard shortcuts.

Called interactively, with no prefix argument, toggle the mode.
With universal prefix ARG (or if ARG is nil) turn mode on.
With zero or negative ARG turn mode off."
  :init-value nil
  :lighter " noxml"
  :group 'noxml-fold
  :global nil
  :keymap noxml-fold-keymap  
  (if noxml-fold-mode ;; true on enabling the mode
      (progn
	(easy-menu-define noxml-fold-menu noxml-fold-keymap "noXML fold menu"
	  '("noXML"
	    ["Fold things" noxml-fold-dwim t]
	    ["Fold buffer" noxml-fold-buffer t]
	    "---"
	    ["Unfold all" noxml-fold-clearout-buffer t]
	    ["Unfold item" noxml-fold-clearout-item t]))
	(define-key noxml-fold-keymap (kbd "<tab>") 'noxml-fold-hide-show-element)
	;; (set 'nxml-sexp-element-flag nil);; functions depend on this!---> should *really* be bound in functions as needed
	(set (make-local-variable 'search-invisible) t)
	;; (setq-default noxml-fold-spec-list-internal nil)
	(add-hook 'post-command-hook 'noxml-fold-post-command t t)
	;; (add-hook 'noxml-fill-newline-hook 'noxml-fold-update-at-point nil t)
	(add-hook 'noxml-after-insert-macro-hook
		  (lambda ()
		    (when (and noxml-fold-mode noxml-fold-auto)
		      (save-excursion
			(backward-char)
			(or (noxml-fold-item 'inline (point))
			    (noxml-fold-item 'block (point)))))))
	(set (make-local-variable 'noxml-fold-spec-list-local)
	     (noxml-fold-flatten-spec-list (noxml-find-folding-rules))))
    (kill-local-variable 'search-invisible)
    (kill-local-variable 'noxml-fold-spec-list-internal)
    (remove-hook 'post-command-hook 'noxml-fold-post-command t)
    (noxml-fold-clearout-buffer)))

(provide 'noxml-fold)

;;; noxml-fold.el ends here
