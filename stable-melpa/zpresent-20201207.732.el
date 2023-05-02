;;; zpresent.el --- Simple presentation mode based on org files.  -*- lexical-binding: t; -*-

;; Version: 0.3
;; Package-Version: 20201207.732
;; Package-Commit: 341d1a4a91a8acff5be6b81f95695e17c79c5309
;; This file is not part of GNU Emacs.

;; Copyright 2015-2017 Zachary Kanfer <zkanfer@gmail.com>

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


;; Homepage: https://hg.sr.ht/~zck/zpresent

;; Package-Requires: ((emacs "25.1") (org-parser "0.4") (dash "2.12.0") (request "0.3.0"))

;; Keywords: comm


;;; Commentary:

;; This package enables presenting org files inside Emacs in a form
;; that's like "traditional" presentation software.

;; Its source repository is https://hg.sr.ht/~zck/zpresent .

;; A tutorial can be accessed by opening `tutorial.org`, then running
;; `M-x zpresent`.

;;; Code:

(define-derived-mode zpresent-mode special-mode "zpresent-mode"
  (define-key zpresent-mode-map (kbd "n") #'zpresent--next-slide)
  (define-key zpresent-mode-map (kbd "C-n") #'zpresent--next-slide)
  (define-key zpresent-mode-map (kbd "j") #'zpresent--next-slide)
  (define-key zpresent-mode-map (kbd "l") #'zpresent--next-slide)
  (define-key zpresent-mode-map (kbd "<right>") #'zpresent--next-slide)
  (define-key zpresent-mode-map (kbd "<down>") #'zpresent--next-slide)
  (define-key zpresent-mode-map (kbd "SPC") #'zpresent--next-slide)
  (define-key zpresent-mode-map (kbd "p") #'zpresent--previous-slide)
  (define-key zpresent-mode-map (kbd "h") #'zpresent--previous-slide)
  (define-key zpresent-mode-map (kbd "k") #'zpresent--previous-slide)
  (define-key zpresent-mode-map (kbd "C-p") #'zpresent--previous-slide)
  (define-key zpresent-mode-map (kbd "<left>") #'zpresent--previous-slide)
  (define-key zpresent-mode-map (kbd "<up>") #'zpresent--previous-slide)
  (define-key zpresent-mode-map (kbd "S-SPC") #'zpresent--previous-slide)
  (define-key zpresent-mode-map (kbd "<next>") #'zpresent--next-checkpoint-slide)
  (define-key zpresent-mode-map (kbd "N") #'zpresent--next-checkpoint-slide)
  (define-key zpresent-mode-map (kbd "<prior>") #'zpresent--previous-checkpoint-slide)
  (define-key zpresent-mode-map (kbd "P") #'zpresent--previous-checkpoint-slide)
  (define-key zpresent-mode-map (kbd "<home>") #'zpresent--first-slide)
  (define-key zpresent-mode-map (kbd "<end>") #'zpresent--last-slide)
  (define-key zpresent-mode-map (kbd "C-+") #'zpresent--increase-text-size)
  (define-key zpresent-mode-map (kbd "+") #'zpresent--increase-text-size)
  (define-key zpresent-mode-map (kbd "C-=") #'zpresent--increase-text-size)
  (define-key zpresent-mode-map (kbd "=") #'zpresent--increase-text-size)
  (define-key zpresent-mode-map (kbd "C--") #'zpresent--decrease-text-size)
  (define-key zpresent-mode-map (kbd "-") #'zpresent--decrease-text-size))


;;;; Requires:
(require 'org-parser)
(require 'subr-x)
(require 'cl-lib)
(require 'cl-macs)
(require 'dash)
(require 'pcase)
(require 'request)

;;;; Variables:
(defvar zpresent-slides nil
  "The slides for the current presentation.")

(defvar zpresent-source nil
  "The original org structure for the presentation.")

(defvar zpresent-images (make-hash-table :test #'equal)
  "The images for the presentation, as a hash table.  The keys are the location, and the values are the images.")

(defvar zpresent-position 0
  "The current slide position.")

(defconst zpresent-increase-multiplier 1.25
  "The amount to increase size when increasing size.")

(defconst zpresent-decrease-multiplier 0.8
  "The amount to decrease size when decreasing size.")

(defconst zpresent-long-title-cutoff 0.66
  "The fraction of the length of a line a title can be before it's considered long.")

(defvar zpresent-bullet "▸")

(defvar zpresent-fullscreen-on-zpresentation t
  "Whether to call #'toggle-frame-fullscreen upon starting a presentation.")

(defvar zpresent-delete-other-windows t
  "Whether to delete other windows when starting a presentation.")

(defvar zpresent-align-title 'left
  "How to align lines in the title.  Possible values are 'left, 'right, 'center.")

(defvar zpresent-default-background-color "#E0E0E0"
  "The default color placed over all fonts in the background.")

(defvar zpresent-buffer-name ""
  "The name of the buffer used to present in.")

;;;; Faces:

(defface zpresent-whole-screen-face `((t . (:background ,zpresent-default-background-color))) "Face that should be put over the whole screen.")
(defface zpresent-base '((t . (:height 4.0 :foreground "#000000"))) "The base face, so we can manage changing sizes only by changing this face." :group 'zpresent-faces)
(defface zpresent-h1 '((t . (:height 1.0 :inherit zpresent-base))) "Face for the title of a regular slide." :group 'zpresent-faces)
(defface zpresent-title-slide-title '((t . (:height 1.5 :inherit zpresent-base))) "Face for titles in a title slide." :group 'zpresent-faces)
(defface zpresent-body '((t . (:height 0.66 :inherit zpresent-base))) "Face for the body." :group 'zpresent-faces)

(defvar zpresent-whole-screen-overlay (make-overlay 0 0)
  "The overlay that's put over all the text in the screen.  Its purpose is to color the background color, and possibly other text properties too.")
(overlay-put zpresent-whole-screen-overlay 'face 'zpresent-whole-screen-face)

;;;; Actual code:
;;;###autoload
(defun zpresent ()
  "Present the current .org file."
  (interactive)

  (setq zpresent-source (org-parser-parse-buffer (current-buffer)))
  (setq zpresent-position 0)
  (setq zpresent-slides (zpresent--format (-filter #'hash-table-p (gethash :content zpresent-source))))

  (setq zpresent-images (make-hash-table :test #'equal))
  (zpresent--cache-images zpresent-slides)

  (setq zpresent-buffer-name (zpresent--presentation-buffer-name))

  (switch-to-buffer zpresent-buffer-name)
  (font-lock-mode 0)
  (zpresent-mode)

  (when zpresent-fullscreen-on-zpresentation
    (set-frame-parameter nil 'fullscreen 'fullboth))

  (when zpresent-delete-other-windows
    (delete-other-windows))

  (setq cursor-type nil)

  (visual-line-mode)

  (zpresent--redisplay))

(defun zpresent--presentation-buffer-name ()
  "Get the name of the presentation buffer."
  (format "zpresentation: %s" (file-name-base (buffer-file-name))))

(defun zpresent--format (structure-list)
  "Convert an STRUCTURE-LIST into a list of slides."
  (cl-mapcan #'zpresent--format-structure
             structure-list))

(defun zpresent--format-structure (structure)
  "Convert STRUCTURE into a list of slides."

  (cl-multiple-value-bind
      (slide-list last-slide) (zpresent--format-structure-helper structure
                                                                 (zpresent--make-top-level-slide structure)
                                                                 1)
    (if (member "slide"
                (gethash :tags
                         (zpresent--get-last-descendant structure)))
        slide-list
      (append slide-list (list last-slide)))))

(defun zpresent--format-structure-helper (structure slide-so-far level)
  "Convert STRUCTURE into a list of slides.

SLIDE-SO-FAR is the built-up slide to append text in the body to.

This method returns a list containing two elements: the first is the
list of slides, and the second is the last slide generated from all
the children of STRUCTURE.

STRUCTURE is at indentation level LEVEL."
  (let ((this-slide slide-so-far)
        (slides-list nil)
        (prior-siblings 0))
    (when (member "slide" (gethash :tags structure))
      (setq slides-list (append slides-list
                                (list (copy-hash-table this-slide))))
      (puthash :checkpoint
               nil
               this-slide))
    (dolist (cur-child (gethash :children structure))
      (let ((child-slide (zpresent--make-following-slide this-slide cur-child level prior-siblings structure)))
        (cl-multiple-value-bind
            (child-slide-list child-last-slide) (zpresent--format-structure-helper cur-child
                                                                                   child-slide
                                                                                   (1+ level))

          (setq slides-list
                (append slides-list
                        child-slide-list))
          (setq this-slide child-last-slide)))
      (cl-incf prior-siblings))
    (list slides-list this-slide)))

(defun zpresent--get-last-descendant (structure)
  "Get the last descendant of STRUCTURE.

This will recurse down, so it will return a grandchild, etc., as
necessary."
  (if (gethash :children structure)
      (zpresent--get-last-descendant (-last-item (gethash :children structure)))
    structure))

(defun zpresent--make-top-level-slide (structure)
  "Make a top level slide from STRUCTURE."
  (let ((slide (zpresent--make-slide (zpresent--extract-current-text structure)))
        (type (assoc "type" (gethash :properties structure))))
    (when type
      (puthash :type (zpresent--make-keyword (string-trim (cdr type))) slide))
    (puthash :properties (gethash :properties structure) slide)
    (when-let ((author (cdr (assoc "author" (gethash :properties structure)))))
      (puthash :author author slide))
    (when-let ((date (cdr (assoc "date" (gethash :properties structure)))))
      (puthash :date date slide))
    slide))

(defun zpresent--extract-current-text (structure)
  "Extracts the text that should go in the slide for STRUCTURE.

This returns a list of lines."
  (if (gethash :body structure)
      (append (list (gethash :text structure))
              (gethash :body structure))
    (list (gethash :text structure))))

(defun zpresent--make-body (structure level prior-siblings &optional parent-structure)
  "Make the body text for STRUCTURE (a single structure, not a list)
at indentation level LEVEL.

PRIOR-SIBLINGS is the number of structures before STRUCTURE with the
same parent.  This is used for ordered lists.

PARENT-STRUCTURE is the parent structure of STRUCTURE, if applicable.
It's used to inherit properties.

Body text is a list containing the text just for the headline,
ignoring any children, but handling multiline headlines.  Each item in
this list is a list of strings or structure items.

The result of this is a list, containing both text and hashes.  Hashes
indicate something other than plain text.  For example, an image."
  (cons (cons (format " %s%s "
                      (make-string (* (1- level) 2) ?\s)
                      (zpresent--format-bullet structure prior-siblings parent-structure))
              (gethash :text structure))
        (let ((body (gethash :body structure))
              (body-indentation (format "%s%s"
                                        (make-string (* level 2) ?\s)

                                        ;;bullets with asterisks are only one character
                                        ;;wide, unlike bullets with numbers.
                                        (if (equal ?* (gethash :bullet-type structure))
                                            " "
                                          ""))))
          (mapcar (lambda (body-line)
                    (cons body-indentation body-line))
                  body))))

(defun zpresent--get-bullet-type (structure parent-structure)
  "Get the type of bullet for STRUCTURE.

This will respect in order of precedence:
1. The 'bullet-type' property of STRUCTURE.
2. The 'child-bullet-type' property of PARENT-STRUCTURE, if provided.
3. The :bullet-type used for STRUCTURE in the original org file."
  (let ((bullet-property (or (assoc "bullet-type" (gethash :properties structure))
                             (when parent-structure
                               (assoc "child-bullet-type" (gethash :properties parent-structure))))))
    (pcase (cdr bullet-property)
      ("*" ?*)
      (")" ?\))
      ("." ?.)
      ("none" ?\s)
      (_ (gethash :bullet-type structure)))))

(defun zpresent--format-bullet (structure prior-siblings &optional parent-structure)
  "Format the bullet for STRUCTURE, not including whitespace before or after.

PRIOR-SIBLINGS is the number of structures before STRUCTURE with the
same parent.  This is used for ordered lists.

PARENT-STRUCTURE is the parent structure of STRUCTURE.  It's used to
inherit properties."
  (cl-case (zpresent--get-bullet-type structure parent-structure)
    (?* zpresent-bullet)
    (?\) (format "%d)" (1+ prior-siblings)))
    (?. (format "%d." (1+ prior-siblings)))
    (t "")))

(defun zpresent--make-slide (title &optional body)
  "Create the slide with title TITLE.

If BODY is present, add it as the body of the slide.  Otherwise, the
slide is created with an empty body."
  (let ((slide (make-hash-table)))
    (puthash :checkpoint t slide)
    (puthash :title title slide)
    (puthash :body (if body (list body) nil) slide)
    (puthash :properties '() slide)

    (puthash :type :normal slide)
    slide))

(defun zpresent--make-following-slide (slide structure level &optional prior-siblings parent-structure)
  "Extend SLIDE with the contents of STRUCTURE, at level LEVEL.

PRIOR-SIBLINGS is the number of structures at the same level before
STRUCTURE with the same PARENT-STRUCTURE."
  (let ((new-slide (copy-hash-table slide)))
    (puthash :body
             (append (gethash :body slide)
                     (zpresent--make-body structure level (or prior-siblings 0) parent-structure))
             new-slide)
    new-slide))

(defun zpresent--break-title-into-lines (title-list chars-in-line)
  "Break TITLE-LIST into a list of lines, each line shorter than CHARS-IN-LINE.

This will return a list of lists.  The sub-lists will contain a
mixture of strings and hashes, when there are formatted strings in
TITLE-LIST.

If a single word is longer than CHARS-IN-LINE, that entire word will
be on a sub-list all by itself."
  (when title-list
    (cl-multiple-value-bind (first-line rest-of-title-list)
        (zpresent--pull-single-title-line title-list chars-in-line)
      (cons first-line
            (zpresent--break-title-into-lines rest-of-title-list
                                              chars-in-line)))))


(defun zpresent--pull-single-title-line (title-list chars-in-line &optional strict-length)
  "Pull a single title line out of TITLE-LIST, a list of items.

A title line is a list of items from TITLE-LIST, or sub-items such
that the line is length CHARS-IN-LINE or less.

This method returns a list; the first item is the pulled line; the
second item is the remaining items in TITLE-LIST.

If STRICT-LENGTH is true, the line returned will be less than or equal
to CHARS-IN-LINE, even if the first word in TITLE-LIST is longer than
CHARS-IN-LINE.  In that case, the line will be empty.  If
STRICT-LENGTH is nil, this will return a list containing at least one
item, even if that single word is longer than CHARS-IN-LINE.

The only thing this should do that -helper doesn't is trim
whitespace from the first and last thing in the line."
  (cl-multiple-value-bind (this-line other-title-items)
      (zpresent--pull-single-title-line-helper (zpresent--trim-beginning-and-end-of-line title-list) chars-in-line strict-length)
    (list (zpresent--trim-beginning-and-end-of-line this-line)
          other-title-items)))

(defun zpresent--trim-beginning-and-end-of-line (title-line)
  "Trim whitespace from the beginning and end of TITLE-LINE."
  (cond ((not title-line)
         nil)
        ((equal 1 (length title-line))
         (list (zpresent--trim-item (cl-first title-line))))
        (t (cons (zpresent--trim-item-left (cl-first title-line))
                 (append (butlast (cl-rest title-line))
                         (list (zpresent--trim-item-right (cl-first (last title-line)))))))))

(defun zpresent--pull-single-title-line-helper (title-list chars-in-line &optional strict-length)
  "Helper for zpresent--pull-single-title-line.

Pull a single title line out of TITLE-LIST, a list of items.

A title line is a list of items from TITLE-LIST, or sub-items such
that the line is length CHARS-IN-LINE or less.

This method returns a list; the first item is the pulled line; the
second item is the remaining items in TITLE-LIST.

If STRICT-LENGTH is true, the line returned will be less than or equal
to CHARS-IN-LINE, even if the first word in TITLE-LIST is longer than
CHARS-IN-LINE.  In that case, the line will be empty.  If
STRICT-LENGTH is nil, this will return a list containing at least one
item, even if that single word is longer than CHARS-IN-LINE."
  (let ((title-list-with-combined-strings (zpresent--combine-consecutive-strings-in-list title-list)))
    (if (not title-list-with-combined-strings)
        (list nil nil)
      (if (>= (zpresent--item-length (cl-first title-list-with-combined-strings))
              chars-in-line)
          (cl-multiple-value-bind (before-break after-break)
              (zpresent--break-item (cl-first title-list-with-combined-strings) chars-in-line strict-length)
            (list (when before-break
                    (list before-break))
                  (if (and after-break
                           (> (zpresent--item-length after-break)
                              0))
                      (cons after-break (cdr title-list-with-combined-strings))
                    (cdr title-list-with-combined-strings))))
        (cl-multiple-value-bind (rest-of-line remaining-items)
            (zpresent--pull-single-title-line-helper (cdr title-list-with-combined-strings)
                                                     (- chars-in-line
                                                        (zpresent--item-length (cl-first title-list-with-combined-strings)))
                                                     t)
          (list (cons (cl-first title-list-with-combined-strings) rest-of-line)
                remaining-items))))))

(defun zpresent--trim-item (item)
  "Trim whitespace on both sides of ITEM."
  (zpresent--trim-item-left (zpresent--trim-item-right item)))

(defun zpresent--trim-item-left (item)
  "Trim whitespace on the left of ITEM."
  (cond ((stringp item)
         (string-trim-left item))
        ((hash-table-p item)
         (let ((copied-hash (copy-hash-table item)))
           (puthash :text
                    (string-trim-left (gethash :text item))
                    copied-hash)
           copied-hash))))

(defun zpresent--trim-item-right (item)
  "Trim whitespace on the right of ITEM."
  (cond ((stringp item)
         (string-trim-right item))
        ((hash-table-p item)
         (let ((copied-hash (copy-hash-table item)))
           (puthash :text
                    (string-trim-right (gethash :text item))
                    copied-hash)
           copied-hash))))

(defun zpresent--combine-consecutive-strings-in-list (list)
  "Return LIST, but with consecutive strings joined together."
  (cond ((< (length list)
            2)
         list)
        ((and (stringp (cl-first list))
              (stringp (cl-second list)))
         (zpresent--combine-consecutive-strings-in-list (cons (concat (cl-first list)
                                                                      (cl-second list))
                                                              (cdr (cdr list)))))
        (t (cons (cl-first list)
                 (zpresent--combine-consecutive-strings-in-list (cl-rest list))))))

(defun zpresent--break-item (item chars-in-line &optional strict-length)
  "Break ITEM at the last whitespace before or at CHARS-IN-LINE.

If the first word in ITEM is longer than CHARS-IN-LINE, and
STRICT-LENGTH is nil, this will break at the first whitespace after
CHARS-IN-LINE.  If STRICT-LENGTH is t, this will return nil for the
first part of the broken item.

This returns a list where the first item is the first part of the
broken item, and the second item is the rest of the item."
  (if (stringp item)
      (zpresent--split-once-at-space item chars-in-line strict-length)
    (cl-multiple-value-bind (pre-split post-split)
        (zpresent--split-once-at-space (gethash :text item)
                                       chars-in-line
                                       strict-length)
      (list (when pre-split (org-parser--make-link-hash (gethash :target item)
                                                        pre-split))
            (when post-split (org-parser--make-link-hash (gethash :target item)
                                                         post-split))))))

(defun zpresent--line-length (line-list)
  "Calculate the length of LINE-LIST.

LINE-LIST is a list of structure items -- either strings, or hashes
representing formatted text."
  (cond ((not line-list) 0)
        ((listp line-list)
         (+ (zpresent--item-length (car line-list))
            (zpresent--line-length (cdr line-list))))

        ;;zck calculate the length of a block properly.
        (t 0)))

(defun zpresent--item-length (item)
  "Calculate the length of ITEM, which is a string or a formatted text hash."
  (cond ((stringp item) (length item))
        ((zpresent--item-is-image item)
         0)
        ((and (hash-table-p item)
              (equal (gethash :type item)
                     :link))
         (length (gethash :text item)))
        (t (error "Can't get the length of %s" item))))

(defun zpresent--format-body (body-line)
  "Format BODY-LINE appropriately for the body."
  (propertize body-line
              'face
              'zpresent-body))

(defun zpresent--split-once-at-space (string max-length &optional strict-length)
  "Split STRING at the last space at MAX-LENGTH or earlier.

If the first word is of length MAX-LENGTH or greater, that word will
be on a line by itself, unless STRICT-LENGTH is t, in which case it'll
be nil.

This returns a list with the split string as the first item, and
the rest of the string as the second."
  (let ((trimmed-string (string-trim string)))
    (if (<= (length string)
            max-length)
        (list string nil)
      (let ((pos-to-split-at (or (cl-position ?\s string :from-end t :end (truncate (1+ max-length)))
                                 (and (not strict-length)
                                      (cl-position ?\s string)))))
        (cond (pos-to-split-at
               (list (string-trim-right (substring string 0 pos-to-split-at))
                     (string-trim-left (substring string pos-to-split-at))))
              (strict-length
               (list nil string))
              (t (list string nil)))))))

(defun zpresent--split-at-space (string max-length)
  "Split STRING at a space.  Each substring must be MAX-LENGTH or shorter.

If there's a single word of length MAX-LENGTH, that word will be on a line by itself."
  (if (<= (length string)
          max-length)
      (list (string-trim string))
    (let ((pos-to-split-at (cl-position ?\s string :from-end t :end max-length)))
      (if pos-to-split-at
          (cons (string-trim (substring string 0 pos-to-split-at))
                (zpresent--split-at-space (string-trim (substring string pos-to-split-at)) max-length))
        (cons (string-trim (substring string 0 max-length))
              (zpresent--split-at-space (string-trim (substring string max-length)) max-length))))))

(defun zpresent--first-slide ()
  "Move to the first slide."
  (interactive)
  (setq zpresent-position 0)
  (zpresent--slide (elt zpresent-slides zpresent-position)))

(defun zpresent--last-slide ()
  "Move to the last slide."
  (interactive)
  (setq zpresent-position (1- (length zpresent-slides)))
  (zpresent--slide (elt zpresent-slides zpresent-position)))

(defun zpresent--next-slide ()
  "Move to the next slide."
  (interactive)
  (when (< zpresent-position
           (1- (length zpresent-slides)))
    (cl-incf zpresent-position)
    (zpresent--slide (elt zpresent-slides zpresent-position))))

(defun zpresent--previous-slide ()
  "Move to the previous slide."
  (interactive)
  (when (> zpresent-position
           0)
    (cl-decf zpresent-position)
    (zpresent--slide (elt zpresent-slides zpresent-position))))

(defun zpresent--next-checkpoint-slide ()
  "Move to the next checkpoint slide.

A checkpoint slide is one with the attribute :checkpoint.  It's used,
for example, for the first slide of each top level org element."
  (interactive)
  (let ((checkpoint-position (cl-position-if (lambda (slide) (gethash :checkpoint slide))
                                             zpresent-slides
                                             :start (1+ zpresent-position))))
    (when checkpoint-position
      (setq zpresent-position checkpoint-position)
      (zpresent--slide (elt zpresent-slides checkpoint-position)))))

(defun zpresent--previous-checkpoint-slide ()
  "Move to the previous checkpoint slide.

A checkpoint slide is one with the attribute :checkpoint.  It's used,
for example, for the first slide of each top level org element."
  (interactive)
  (let ((checkpoint-position (cl-position-if (lambda (slide) (gethash :checkpoint slide))
                                             zpresent-slides
                                             :end zpresent-position
                                             :from-end t)))
    (when checkpoint-position
      (setq zpresent-position checkpoint-position)
      (zpresent--slide (elt zpresent-slides checkpoint-position)))))


(cl-defun zpresent--find-forwards (pred list &optional (starting-point 0))
  "Find the first element that PRED considers truthy in LIST at or after STARTING-POINT."
  (when-let (additional-places (-find-index pred
                                            (nthcdr starting-point list)))
    (+ starting-point additional-places)))

(cl-defun zpresent--find-backwards (pred list &optional (ending-point (length list)))
  "Find the last element that PRED considers truthy in LIST at or before ENDING-POINT."
  (-find-last-index pred
                    (cl-subseq list
                               0
                               (min (1+ ending-point) (length list)))))

(defun zpresent--slide (slide)
  "Present SLIDE."
  (cl-case (gethash :type slide)
    (:full-screen-image (zpresent--present-full-screen-image slide))
    (:title (zpresent--present-title-slide slide))
    (otherwise (zpresent--present-normal-slide slide)))
  (let ((inhibit-read-only t))
    (insert (propertize (make-string (window-total-height) ?\n)
                        'face 'zpresent-base)))
  (face-spec-set 'zpresent-whole-screen-face
                 ;;we don't get the new properties from the children!
                 `((t . (:background
                         ,(if-let ((background-color (assoc-default "background-color" (gethash :properties slide) #'equal)))
                              background-color
                            zpresent-default-background-color)))))
  (move-overlay zpresent-whole-screen-overlay
                (point-min)
                (point-max)
                (get-buffer zpresent-buffer-name))
  (goto-char (point-min)))

(defun zpresent--present-normal-slide (slide)
  "Present SLIDE as a normal (read: non-title) slide."
  (interactive)
  (switch-to-buffer zpresent-buffer-name)
  (buffer-disable-undo zpresent-buffer-name)
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert "\n")
    (when (gethash :title slide)
      (zpresent--insert-title (gethash :title slide) 'zpresent-h1)
      (insert "\n"))
    (zpresent--insert-body slide)))

(defun zpresent--present-title-slide (slide)
  "Present SLIDE as a title slide."
  (switch-to-buffer zpresent-buffer-name)
  (buffer-disable-undo zpresent-buffer-name)
  (let ((inhibit-read-only t)
        (title-lines (zpresent--get-lines-for-title (gethash :title slide) (window-max-chars-per-line nil 'zpresent-title-slide-title))))
    (erase-buffer)
    (insert (propertize (make-string (zpresent--newlines-for-vertical-centering (length title-lines)
                                                                                (zpresent--lines-in-window 'zpresent-title-slide-title))
                                     ?\n)
                        'face 'zpresent-title-slide-title))
    (zpresent--insert-title (gethash :title slide) 'zpresent-title-slide-title)
    (zpresent--insert-body slide)

    (when-let ((author-name (gethash :author slide)))
      (insert (propertize (format "\nby %s" (string-trim author-name))
                          'face
                          'zpresent-h1)))
    (when-let ((date (gethash :date slide)))
      (insert (propertize (format "\n%s" (string-trim date))
                          'face
                          'zpresent-h1)))))

(defun zpresent--present-full-screen-image (slide)
  "Present SLIDE as a full screen image."
  (switch-to-buffer zpresent-buffer-name)
  (buffer-disable-undo zpresent-buffer-name)
  (let ((inhibit-read-only t))
    (erase-buffer)
    (when-let ((image-location (assoc-default "image" (gethash :properties slide) #'equal))
               (image (zpresent--get-image-from-cache image-location 1)))
      (insert-image (append image (list :width (window-body-width nil t)
                                        :height (window-body-height nil t)))))))

(defun zpresent--lines-in-window (face &optional window)
  "Calculate how many lines of text with face FACE can fit in WINDOW."
  (truncate (window-body-height window t)
            (window-font-height window face)))

(defun zpresent--get-lines-for-title (title chars-in-line)
  "Gets the lines for TITLE, when presented in a line of length CHARS-IN-LINE.

This only differs from --break-title-into-lines in that it assumes a
title that already has more than one line has been broken up by the
user, so shouldn't be rearranged."
  (if (equal 1 (length title))
      (zpresent--break-title-into-lines (cl-first title)
                                        (* chars-in-line
                                           zpresent-long-title-cutoff))
    title))

(defun zpresent--newlines-for-vertical-centering (title-lines total-lines)
  "Calculate how many newlines must be inserted to vertically center a title of TITLE-LINES length in a window of TOTAL-LINES length."
  (max (truncate (- total-lines title-lines)
                 2)
       0))

(defun zpresent--insert-body (slide)
  "Insert the body of SLIDE into the buffer."
  (when (gethash :body slide)
    (dolist (body-item (gethash :body slide))
      ;;blocks here are represented as an improper list, with the car
      ;;being the indentation, and the cdr being the block itself.
      (if (listp (cdr body-item))
          (zpresent--insert-item body-item 'zpresent-body)

        ;; The body item is a block, so the car is the indentation,
        ;; and the cdr is the block.
        (zpresent--insert-item (cdr body-item) 'zpresent-body (car body-item)))
      (insert "\n"))))

(defun zpresent--insert-title (title face)
  "Insert TITLE into the buffer with face FACE."
  (let* ((chars-in-line (window-max-chars-per-line nil face))
         (title-lines (zpresent--get-lines-for-title title chars-in-line))
         (whitespace-for-title (zpresent--calculate-aligned-whitespace title-lines chars-in-line))
         (longest-line-length (apply #'max (mapcar #'zpresent--line-length title-lines))))
    (dolist (title-line title-lines)
      (let ((whitespace-for-this-line (cl-case zpresent-align-title
                                        ('left whitespace-for-title)
                                        ('center nil)
                                        ('right (concat whitespace-for-title
                                                        (make-string (- longest-line-length
                                                                        (zpresent--line-length title-line))
                                                                     ?\s))))))
        (zpresent--insert-title-line title-line face whitespace-for-this-line)))))

(defun zpresent--calculate-aligned-whitespace (title chars-in-line)
  "Return the whitespace for a TITLE.

TITLE is a list of rows, and is presented aligned in a row of
length CHARS-IN-LINE.."
  ;;Add one here so that we round away from zero. We want to have more whitespace on the left than the right side.
  ;;zck is this what's wanted?
  (make-string (truncate (max 0
                              (1+ (- chars-in-line
                                     (zpresent--find-longest-line-length title))))
                         2)
               ?\s))

(defun zpresent--find-longest-line-length (lines)
  "Find the length of the longest line in LINES."
  (apply #'max
         (mapcar #'zpresent--line-length
                 lines)))


(defun zpresent--insert-title-line (title-line face &optional precalculated-whitespace)
  "Insert TITLE-LINE into the buffer with face FACE.

If PRECALCULATED-WHITESPACE is provided, pad all the lines by that
amount.  Otherwise, center the title-line."
  (let ((leading-whitespace (or precalculated-whitespace (zpresent--whitespace-for-centered-title-line title-line face))))
    (if (listp title-line)
        (progn (insert (propertize leading-whitespace 'face face))
               (dolist (title-item title-line)
                 (zpresent--insert-item title-item face)))
      (zpresent--insert-item title-line face leading-whitespace)))
  (insert "\n"))


(defun zpresent--insert-item (item face &optional precalculated-whitespace)
  "Insert ITEM into the buffer with face FACE.

If PRECALCULATED-WHITESPACE is given, insert it at the beginning of
each line, with the same face."
  (cond ((stringp item)
         (insert (propertize item
                             'face
                             face)))
        ((listp item)
         (when precalculated-whitespace
           (insert (propertize precalculated-whitespace 'face face)))
         (dolist (inner-item item)
           (zpresent--insert-item inner-item face)))
        ((zpresent--item-is-image item)
         (zpresent--insert-image (gethash :target item)))
        ((hash-table-p item)
         (cl-case (gethash :type item)
           (:link (zpresent--insert-link item face))
           (:block (dolist (line (split-string (gethash :body item) "\n"))
                     (when precalculated-whitespace
                       (insert (propertize precalculated-whitespace 'face face)))
                     (insert (propertize line
                                         'face
                                         face))
                     (insert "\n")))))))

(defun zpresent--item-is-image (item)
  "T if ITEM is an image."
  (and (hash-table-p item)
       (equal :link
              (gethash :type item))
       (equal "zp-image"
              (gethash :text item))))

(defun zpresent--get-image-from-cache (image-location wait-if-not-found)
  "Get the image from IMAGE-LOCATION from the cache.

If it's not there, wait a maximum of WAIT-IF-NOT-FOUND seconds for the
image to come in.  This is intended for use when a download is in
progress."
  (if-let (image (gethash image-location zpresent-images))
      image
    (when (and wait-if-not-found
               (> wait-if-not-found 0))
      (sleep-for 0 100)
      (zpresent--get-image-from-cache image-location
                                      (- wait-if-not-found 0.1)))))

(defun zpresent--insert-image (image-location)
  "Insert IMAGE-LOCATION as an image."
  (when-let ((image (zpresent--get-image-from-cache image-location 1)))
    (insert-image image)))

(defun zpresent--get-image-data (image-location)
  "Get the image data for IMAGE-LOCATION."
  (if (string-prefix-p "file:" image-location)
      (create-image (expand-file-name (string-remove-prefix "file:" image-location)))))

(defun zpresent--cache-images (slides)
  "Read or download all images in SLIDES, and put them into a cache."
  (mapc #'zpresent--cache-images-helper
        slides))

(defun zpresent--cache-images-helper (slide)
  "Read or download all images in SLIDE, and put them into a cache."
  (when-let ((image-in-properties (assoc-default "image" (gethash :properties slide) #'equal)))
    (zpresent--fetch-and-cache-image image-in-properties))
  (dolist (line (append (gethash :title slide)
                        (gethash :body slide)))
    (when (and (listp line)

               ;;also check that this isn't a block. We should probably handle this better.
               (listp (cdr line)))
      (dolist (item line)
        (when (zpresent--item-is-image item)
          (zpresent--fetch-and-cache-image (gethash :target item)))))))

(defun zpresent--fetch-and-cache-image (location)
  "Cache the image from LOCATION in zpresent-images."
  (unless (gethash location zpresent-images)
    (if (string-prefix-p "file:" location)
        (zpresent--cache-image (create-image (expand-file-name (string-remove-prefix "file:" location)))
                               location)
      (request location
               :parser #'buffer-string
               :success (cl-function (lambda (&key data &allow-other-keys)
                                       (zpresent--cache-image (create-image (encode-coding-string data 'utf-8) nil t)
                                                              location)))))))

(defun zpresent--cache-image (image source-location)
  "Cache the IMAGE, which originated at SOURCE-LOCATION."
  (puthash source-location
           image
           zpresent-images))

(defun zpresent--whitespace-for-centered-title-line (title-line chars-in-line)
  "Get whitespace to center TITLE-LINE in a window of width CHARS-IN-LINE.

The whitespace calculation assumes no line will be split."
  (let* ((line-width (zpresent--line-length title-line))
         (chars-to-add (max 0
                            (truncate (- chars-in-line line-width)
                                      2))))
    (make-string chars-to-add ?\s)))

(defun zpresent--insert-link (link-hash face)
  "Insert LINK-HASH into the buffer, as a link, with face FACE.

If you want to insert an image, use '#'zpresent--insert-image'."
  (insert-button (propertize (gethash :text link-hash)
                             'face face)
                 'action `(lambda (button) (browse-url ,(gethash :target link-hash)))
                 'follow-link t))



(defun zpresent--increase-text-size ()
  "Make everything bigger."
  (interactive)
  (set-face-attribute 'zpresent-base
                      nil
                      :height
                      (* zpresent-increase-multiplier
                         (or (face-attribute 'zpresent-base :height)
                             1)))
  (zpresent--redisplay))

(defun zpresent--decrease-text-size ()
  "Make everything smaller."
  (interactive)
  (set-face-attribute 'zpresent-base
                      nil
                      :height
                      (* zpresent-decrease-multiplier
                         (or (face-attribute 'zpresent-base :height)
                             1)))
  (zpresent--redisplay))

(defun zpresent--redisplay ()
  "Redisplay the presentation at the current slide."
  (interactive)
  (zpresent--slide (elt zpresent-slides zpresent-position)))

;;the slide is stored as a hash. Key-value pairs are:
;; key: title
;; value: The title of the slide. If this is a string, automatically split it.
;;    If this is a list, assume it's been manually split by the user,
;;    so just use each line separately.
;; key: body
;; value: A list of the lines in the body of the slide.

(defun zpresent--test-presentation ()
  "Start a presentation with dummy data."
  (interactive)
  (setq zpresent-position 0)
  (setq zpresent-slides
        (list #s(hash-table data (title "one-line title" body ("body line 1" "body line 2")))
              #s(hash-table data (title ("title manually split" "onto three" "lines (this one is pretty gosh darn long, but it shouldn't be automatically split no matter how long it is.)")))
              #s(hash-table data (title "an automatically split really really really really really really really really really long title"))))

  (switch-to-buffer zpresent-buffer-name)
  (font-lock-mode 0)
  (zpresent-mode)

  (zpresent--redisplay))


(defun zpresent--hash-contains? (hash key)
  "Return t if HASH, a hash table, has KEY."
  (let ((unique-key (cl-gensym)))
    (not (equal (gethash key hash unique-key)
                unique-key))))


(defun zpresent--make-keyword (name)
  "Make a keyword from NAME.

Given \"pants\", returns a keyword that's equal to :pants."
  (intern (format ":%s" name)))


(provide 'zpresent)

;;; zpresent.el ends here
