;;; org-view-mode.el --- Read-only viewer with less markup clutter in org mode files  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Arthur Miller

;; Author: Arthur Miller <arthur.miller@live.com>
;; Keywords: convenience, outlines, tools
;; Package-Version: 20220218.2106
;; Package-Commit: 88321917b095a8cbabfa8327c915bd46eb741750

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

;; Author: Arthur Miller
;; Version: 1.0.0
;; Keywords: tools convenience
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/amno1/org-view-mode

;;; Commentary:

;; A read-only viewer with reduced clutter and prettier rendering in org files.
;; To enter the view-mode run: `M-x org-view-mode'.  To turn it off run the same
;; command.  The mode tries very hard to not do any changes to the buffer and
;; the content.  However, it does use text properties for some effects, so at
;; least in theory, if you don't exit the viewer cleanly, via some of its exit
;; methods, it might happened that the view is not restored properly.  In that
;; case you may re-enter, and exit the viewer again, or re-open the file.

;;; Issues

;;; Code:
(require 'org)

;;; Options
(defgroup org-view nil
  "A minor read-only mode for viewing textual `org-mode' files."
  :prefix "org-view-"
  :group 'org)

(defcustom org-view-hide-tags t
  "Hide/show tags in org-headings."
  :type 'boolean
  :group 'org-view)

(defcustom org-view-hide-stars t
  "Hide/show leading stars in org-headings."
  :type 'boolean
  :group 'org-view)

(defcustom org-view-hide-keywords t
  "Hide/show org-markup keywords."
  :type 'boolean
  :group 'org-view)

(defcustom org-view-hide-agenda-keywords t
  "Hide/show DEADLINE and SCHEDULED keywords."
  :type 'boolean
  :group 'org-view)

(defcustom org-view-hide-properties t
  "Hide/show properties and property drawers."
  :type 'boolean
  :group 'org-view)

(defcustom org-view-hide-ellipses nil
  "Hide/show ellipses for hidden text."
  :type 'boolean
  :group 'org-view)

(defcustom org-view-prettify-toc t
  "Prettify table of contents when included."
  :type 'boolean
  :group 'org-view)

(defcustom org-view-prettify-credentials t
  "Prettify TITLE, AUTHOR and EMAIL when specified."
  :type 'boolean
  :group 'org-view)

(defcustom org-view-prettify-paragraphs t
  "Prettify quote, verse and centered paragraphs in org-buffers."
  :type 'boolean
  :group 'org-view)

(defcustom org-view-paragraph-indent "  "
  "Indentation string for paragraphs."
  :type 'string
  :group 'org-view)

(defcustom org-view-default-fill-column 80
  "Default size for `fill-column' in org-view mode.

This value is used only if `fill-column' has invalid size, such as <= 0 or nil."
  :type 'fixnum
  :group 'org-view)

(defcustom org-view-author-prefix "───"
  "String used to pretty-render author prefix in paragraphs."
  :type 'string
  :group 'org-view)

(defcustom org-view-verse-align 'left
  "Specify how verses will be aligned.

Alignement can be: left, right, middle or nil.  Nil value means to remove the
alignement.  The alignement is done relative to the longest line in the
paragrach.  If present, the author line is excluded."
  :type 'symbol
  :group 'org-view)

(defcustom org-view-quote-align 'left
  "Specify how quotes will be aligned.

This variable has same meaning for quotes as the alignement in
`org-view-verse-align'."
  :type 'symbol
  :group 'org-view)

(defcustom org-view-center-credentials t
  "Whether to align title and author in center or not.

Centering is done pixel wise relative to window width."
  :type 'boolean
  :group 'org-view)

(defgroup org-view-faces nil
  "Faces for org-view mode."
  :group 'org-view)

(defface org-view-author-face
  '((t :slant italic :weight bold))
  "Face to display author names in paragraphs."
  :group 'org-view-faces)

(defface org-view-verse-face
  '((t :slant italic))
  "Face to display verses in paragraphs."
  :group 'org-view-faces)

(defface org-view-quote-face
  '((t :slant italic))
  "Face to display quotes in paragraphs."
  :group 'org-view-faces)

;;; Implementation

(defvar org-view-mode-map
  (let ((map (make-sparse-keymap)))
        (define-key map (kbd "e") #'org-view-edit-on)
        (define-key map (kbd "E") #'org-view-edit-on)
        (define-key map (kbd "q") #'org-view-quit)
        (define-key map (kbd "Q") #'org-view-quit)
    map)
  "Keymap for ‘org-view-mode’.")

(defvar org-view-edit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "e") #'org-self-insert-command)
    (define-key map (kbd "E") #'org-self-insert-command)
    (define-key map (kbd "q") #'org-self-insert-command)
    (define-key map (kbd "Q") #'org-self-insert-command)
    (define-key map (kbd "C-x C-s") #'org-view-save-edit)
    (define-key map (kbd "C-x C-q") #'org-view-cancel-edit)
    map)
  "Keymap for ‘org-view-mode’ when performing quick-edit.")

(defvar org-view-stars-re "^[ \t]*\\*+"
  "Regex used to recognize leading stars in org-headings.")
(defvar org-view-credentials-re "[ \t]*#\\+\\(TITLE\\|AUTHOR\\|EMAIL\\):"
  "Regex used to update author and title lines.")
(defvar org-view-markup-re "^[ \t]*#\\+.*$"
  "Regex usex to hide markup.")
(defvar org-view-markup-with-agenda-re
  "^[ \t]*\\(#\\+\\|DEADLINE:\\|SCHEDULED:\\).*$"
  "Regex for markup with agenda keywords.")
(defvar-local org-view--old-point nil
  "Keep old point to restore it when quick edit is cancelled.")
(defvar-local org-view--old-content nil
  "Copy of buffer to restore it when quick edit is cancelled.")
(defvar-local org-view--old-read-only nil
  "Keep the original state of read-only value and restore it after org-view-exit.")
(defvar-local org-view--old-ellipses nil
  "Keep the original state of `selective-display' value.")

(defun org-view--toggle-features (&optional on)
  "Toggle each feature ON or off according to customize options."
  (if org-view-hide-tags
      (org-view--update-tags on))
  (if org-view-prettify-toc
      (org-view--update-toc on))
  (if org-view-hide-stars
      (org-view--update-stars on))
  (if org-view-hide-keywords
      (org-view--update-keywords on))
  (if org-view-hide-properties
      (org-view--update-properties on))
  (if org-view-prettify-paragraphs
      (org-view--update-paragraphs on))
  (if org-view-prettify-credentials
      (org-view--update-credentials on)))

(defun org-view--on ()
  "Properly enter `org-view-mode'."
  (add-hook 'change-major-mode-hook #'org-view--off nil t)
    (setq org-view--old-read-only buffer-read-only
          buffer-read-only t)
    (when org-view-hide-ellipses
      (unless buffer-display-table
        (setq buffer-display-table standard-display-table))
      (setq org-view--old-ellipses
            (display-table-slot buffer-display-table 'selective-display))
      (set-display-table-slot buffer-display-table
                              'selective-display (string-to-vector "")))
    (org-font-lock-ensure 1 (point-max))
    (org-view--toggle-features t))

(defun org-view--off ()
  "Properly exit `org-view-mode'."
  (remove-hook 'change-major-mode-hook #'org-view--off t)
  (setq buffer-read-only org-view--old-read-only)
  (if org-view-hide-ellipses
      (set-display-table-slot buffer-display-table
                              'selective-display
                              org-view--old-ellipses))
  (org-view--toggle-features))

(defun org-view--update-toc (visibility)
  "Set invisible property to VISIBILITY for properties in the current buffer."
  (org-with-wide-buffer
   (save-excursion
     (with-silent-modifications
       (goto-char (point-min))
       (when (re-search-forward "^:CONTENTS:" nil t)
         (put-text-property
          (match-end 0) (1- (match-end 0)) 'invisible visibility)
         (put-text-property
          (match-beginning 0) (1+ (match-beginning 0)) 'invisible visibility)
         (when (re-search-forward "^:END:")
         (put-text-property
            (if (> (match-beginning 0) 1)
                (1- (match-beginning 0))
              (match-beginning 0))
            (match-end 0) 'invisible visibility)))))))

(defun org-view--update-tags (visibility)
  "Update invisible property to VISIBILITxxxxx Y for tags in the current buffer."
  (save-excursion
    (goto-char (point-min))
    (with-silent-modifications
      (while (re-search-forward org-view-stars-re nil t)
        (goto-char (line-end-position))
        (when (re-search-backward org-tag-line-re (line-beginning-position) t)
            (put-text-property
             (match-beginning 1) (match-end 1) 'invisible visibility))
          (forward-line)))))

(defun org-view--update-keywords (visibility)
  "Set VISIBILITY for each line starting with a keyword from KEYWORDS list."
  (org-with-wide-buffer
   (save-excursion
     (with-silent-modifications
       (goto-char (point-min))
       (let ((hide-markup-re (if org-view-hide-agenda-keywords
                                     org-view-markup-with-agenda-re
                                   org-view-markup-re)))
         (while (re-search-forward hide-markup-re nil t)
           (goto-char (match-beginning 0))
           (unless (looking-at-p org-view-credentials-re)
             (put-text-property
              (if (> (match-beginning 0) 1)
                  (1- (match-beginning 0))
                (match-beginning 0))
              (match-end 0) 'invisible visibility))
           (goto-char (match-end 0))))))))

(defun org-view--update-properties (visibility)
  "Set invisible property to VISIBILITY for properties in the current buffer."
  (org-with-wide-buffer
   (save-excursion
     (with-silent-modifications
       (goto-char (point-min))
       (while (re-search-forward org-property-drawer-re nil t)
         (put-text-property
          (match-beginning 0) (match-end 0) 'invisible visibility))
       (goto-char (point-min))
       (while (re-search-forward "^[ \t]*#\\+PROPERTY:.*$" nil t)
         (let ((beg  (if (> (match-beginning 0) 1)
                         (1- (match-beginning 0))
                       (match-beginning 0)))
               (end (1+ (match-end 0))))
         (put-text-property beg end 'invisible visibility)))))))

(defun org-view--update-stars (visibility)
  "Update invisible property to VISIBILITY for markers in the current buffer."
  (org-with-wide-buffer
   (save-excursion
     (goto-char (point-min))
     (with-silent-modifications
       (while (re-search-forward org-view-stars-re nil t)
         (put-text-property
          (match-beginning 0) (match-end 0) 'invisible visibility))))))

(defun org-view--update-credentials (visibility)
  "Set invisible property to VISIBILITY for export settings."
  (org-with-wide-buffer
   (save-excursion
     (with-silent-modifications
       (goto-char (point-min))
       (while (re-search-forward org-view-credentials-re nil t)
         (put-text-property
          (match-beginning 0) (match-end 0) 'invisible visibility)
         (when org-view-center-credentials
           (let ((left (point))
                 (right (line-end-position))
                 (width (org-view--fill-column-pixel-width)))
             (when (re-search-forward "[ \t]+$" (line-end-position) t)
               (setq left (point))
               (put-text-property
                (match-beginning 0) (match-end 0) 'invisible visibility))
             (org-view--center-region left right width visibility)))
           (forward-line))))))

(defun org-view--fill-column-pixel-width ()
  "Return width for `fill-column' in pixels.

This methods works only in buffers with live windows.  This function is the only
instance where org-view modifies the content in original buffer - needed to
calculate pixel width of a full line of text.  The modification should not be
visible, but there is no guarantee, it really depends on Emacs rendering
algorithms.

Emacs 29 has function 'string-pixel-width' however it is not avialable in older
versions."
  (let ((window (or (get-buffer-window) (selected-window))))
    (when window
      (save-excursion
        (with-silent-modifications
          (let ((width (if (> fill-column 0)
                           fill-column
                         org-view-default-fill-column))
                pixel-width)
            (goto-char (point-max))
            (insert (make-string width ?\s))
            (goto-char (line-beginning-position))
            (setq pixel-width
                  (org-view--region-pixel-width
                   (line-beginning-position) (line-end-position)))
            (delete-region (line-beginning-position) (line-end-position))
            pixel-width))))))

(defun org-view--region-pixel-size (beg end)
  "Calculate pixel-size for a region between BEG and END points."
  (save-restriction
    (narrow-to-region beg end)
    (window-text-pixel-size
     (get-buffer-window (current-buffer)) beg end)))

(defun org-view--region-pixel-width (beg end)
  "Calculate width in pixels for a region between BEG and END points.

This should be cheaper than `string-pixel-width' introduced in recent Emacs
version (29.1), as well as accessible in older Emacs versions.  Limitation is
that it works only for completely visible buffer lines."
  (car (org-view--region-pixel-size beg end)))

(defun org-view--center-region (beg end line-width &optional center)
  "Render a line bounded by BEG and END centered in a window pixel wise.

LINE-WIDTH is the pixel width of the base line used to CENTER region against,
typically `fill-column' pixel width, and it assumes width from the left text
area border."
  (if center
      (let* ((width (org-view--region-pixel-width beg end))
             (spacer (/ (- line-width width) 2)))
        (overlay-put
         (make-overlay beg (1+ beg))
         'before-string (propertize " " 'display `(space :width (,spacer)))))
    (remove-overlays beg end)))

;;; Paragraphs
(defvar org-view-paragraph-beg-re
  "^[ \t]*#\\+BEGIN_\\(QUOTE\\|CENTER\\|VERSE\\)[ \t]*$")
(defvar org-view-paragraph-end-re
  "^[ \t]*#\\+END_\\(QUOTE\\|CENTER\\|VERSE\\)[ \t]*$")
(defvar org-view--verse-ov nil
  "Overlay to prettify display of text marked as verse.")
(defvar org-view--quote-ov nil
  "Overlay to prettify display of text marked as quotes.")
(defvar org-view--author-ov nil
  "Overlay to prettify display of the author when an author is present.")
(defvar org-view--author-prefix-ov nil
  "Overlay to prettify display of the author prefix when an author is present.")

(defun org-view--line-lengths (beg end)
  "Return longest line in region between BEG and END points."
  (save-excursion
    (let (positions left right)
      (goto-char beg)
      (while (< (point) end)
        (skip-chars-forward " \t")
        (setq left (point))
        (goto-char (line-end-position))
        (skip-chars-backward " \t")
        (setq right (point))
        (and left right (> (- right left) 0)
             (push (cons (- right left) (cons left right)) positions))
        (forward-line))
      positions)))

(defun org-view--align-paragraph (beg end align)
  "Align text in region with the longest line according to the ALIGN parameter.

BEG and END are start and end of the region.
ALIGN can be one of following: 'left, 'right, 'middle or nil.
Nil value means to remove the alignement."
  (save-excursion
    (let* ((lines (cl-sort (org-view--line-lengths beg end) #'> :key #'car))
           (longest (car lines))
           (lines (cdr lines))
           indent longest-pixel-width indent-pixel-width)
      (cond (align
             (goto-char (cadr longest))

             (cond ((eq align 'left)
                    (setq indent (buffer-substring-no-properties
                                  (line-beginning-position) (point)))
                    (dolist (line lines)
                      (goto-char (cadr line))
                      (put-text-property
                       (line-beginning-position) (point) 'invisible t)
                      (overlay-put
                       (make-overlay (line-beginning-position) (point))
                       'before-string indent)))

                   ((eq align 'right)
                    (dolist (line lines)
                      (setq
                       indent (org-view--region-pixel-width
                               (cadr longest)
                               (+ (cadr longest) (- (car longest) (car line)))))
                      (goto-char (cadr line))
                      (unless (= (char-before) ?\n)
                        (put-text-property
                         (line-beginning-position) (point) 'invisible t))
                      (unless (= (char-after (cddr line)) ?\n)
                        (put-text-property
                         (cddr line) (line-end-position) 'invisible t))
                      (overlay-put
                       (make-overlay (point) (1+ (point))) 'before-string
                       (propertize " " 'display `(space :width (,indent))))))

                   ((eq align 'middle)
                    (setq longest-pixel-width
                          (org-view--region-pixel-width
                           (cadr longest) (cddr longest))
                          indent-pixel-width
                          (org-view--region-pixel-width
                           (line-beginning-position) (point)))
                    (dolist (line lines)
                      (let* ((length (org-view--region-pixel-width
                                      (cadr line) (cddr line)))
                             (spacer (+ indent-pixel-width
                                        (/ (- longest-pixel-width length) 2))))
                        (goto-char (cadr line))
                        (unless (= (char-before) ?\n)
                          (put-text-property
                           (line-beginning-position) (point) 'invisible t))
                        (goto-char (line-beginning-position))
                        (overlay-put
                         (make-overlay (point) (1+ (point))) 'before-string
                         (propertize " " 'display `(space :width (,spacer)))))))))

             (t (remove-overlays beg end)
                (remove-text-properties beg end '(display t invisible t)))))))

(defun org-view--prettify-quote (beg end &optional prettify)
  "Prettify text in region between BEG and END as quotes.

PRETTIFY is a boolean flag meaning to add or remove the styling."
  (save-excursion
    (with-silent-modifications
      (if prettify
          (setq org-view--quote-ov (make-overlay beg end))
        (remove-overlays beg end))
      (goto-char beg)
      (if prettify
          (org-view--align-paragraph beg end org-view-quote-align))
      (while (< (point) end)
        (cond (prettify
               (overlay-put org-view--quote-ov 'face 'org-view-quote-face)
               (overlay-put (make-overlay (point) (1+ (point)))
                            'before-string org-view-paragraph-indent))
              (t (remove-overlays beg end)
                 (remove-text-properties beg end '(display t invisible t))))
        (forward-line)))))

(defun org-view--prettify-verse (beg end &optional prettify)
  "Prettify text in region between BEG and END as verses.

The author name should be separated by three dashes, '---' and put on a separate
line after the paragraph content.
PRETTIFY is a boolean flag meaning to add or remove the styling."
  (save-excursion
    (goto-char end)
    (when (search-backward "---" beg t)
      (setq end (line-beginning-position)))
    (cond (prettify
           (org-view--align-paragraph beg end org-view-verse-align)
           (overlay-put (make-overlay beg end) 'face 'org-view-verse-face))
          (t (remove-overlays beg end)
             (remove-text-properties beg end '(display t invisible t))))))

(defun org-view--prettify-center (beg end &optional pretty)
  "Render text in region between BEG and END as centered.

PRETTY is a boolean flag meaning to add or remove the centering.

Centering is done according to `fill-column', or current window width if
`fill-column' is nil.  This function is the only instance where org-view
modifies the content in original buffer in order to calculate pixel width of a
full line of text.  The modification should not be visible, but there is no
guarantee, it really depends on Emacs rendering algorithms."
  (save-excursion
    (with-silent-modifications
      (let ((width (org-view--fill-column-pixel-width))
            left right)
        (goto-char beg)
        (while (< (point) end)
          (when (re-search-forward "^[ \t]+" (line-end-position) t)
            (put-text-property
             (match-beginning 0) (match-end 0) 'invisible t))
          (setq left (point))
          (goto-char (line-end-position))
          (when (re-search-backward "[ \t]*$" (line-beginning-position) t)
            (put-text-property
             (match-beginning 0) (match-end 0) 'invisible t))
          (setq right (point))
          (org-view--center-region left right width pretty)
          (forward-line))))))

(defun org-view--prettify-author (beg end &optional pretty)
  "Render author of a quote or verse in custom face.

BEG and END are start and end of the region to be styled.
PRETTY is a boolean flag meaning to add or remove the styling.
Anything following three dashes to the end of line is recognized as author."
  (save-excursion
    (goto-char end)
    (when (search-backward "---" beg t)
      (put-text-property (point) (+ (point) 3) 'invisible pretty)
      (setq org-view--author-prefix-ov (make-overlay (point) (+ 3 (point)))
            org-view--author-ov (make-overlay (+ 3 (point)) (line-end-position)))
      (cond (pretty
             (overlay-put
              org-view--author-prefix-ov 'before-string org-view-author-prefix)
             (overlay-put org-view--author-ov 'face 'org-view-author-face))
            (t (remove-overlays (point) (line-end-position)))))))

(defun org-view--update-paragraphs (&optional pretty)
  "Prettify paragraphs and hide markers.

PRETTY is a boolean flag meaning to add or remove the styling."
  (org-with-wide-buffer
   (save-excursion
     (with-silent-modifications
       (goto-char (point-min))
       (let (beg end type)
         (while (re-search-forward org-view-paragraph-beg-re nil t)
           (put-text-property
            (1- (line-beginning-position)) (line-end-position) 'invisible pretty)
           (forward-line)
           (setq beg (point))
           (when (re-search-forward org-view-paragraph-end-re nil t)
             (put-text-property
              (1- (line-beginning-position)) (line-end-position) 'invisible pretty)
             (setq end (1- (line-beginning-position)))
             (save-excursion
                 (re-search-backward
                  "\\(QUOTE\\|VERSE\\|CENTER\\)" (line-beginning-position) t)
                 (setq type (match-string 0))
                 (cond
                  ((equal "QUOTE" type)
                   (org-view--prettify-quote beg end pretty))
                  ((equal "VERSE" type)
                   (org-view--prettify-verse beg end pretty))
                  ((equal "CENTER" type)
                   (org-view--prettify-center beg end pretty)))
                 (org-view--prettify-author beg end pretty)))))))))

;;; User commands

(defun org-view-quit ()
  "Exit `org-view-mode'."
  (interactive)
  (org-view-mode -1)
  (message "org-view mode disabled in current buffer"))

(defun org-view-save-edit ()
  "Save quick edits when in `org-view-mode'."
  (interactive)
  (save-buffer)
  (org-view-edit-off))

(defun org-view-cancel-edit ()
  "Cancel quick edits from `org-view-mode'."
  (interactive)
  (when (buffer-modified-p)
    (erase-buffer)
    (insert org-view--old-content)
    (org-view--on)
    (goto-char org-view--old-point)
    (set-buffer-modified-p nil)
    (setq buffer-undo-list nil)
    (message "Changes aborted"))
  (org-view-edit-off))

(defun org-view-edit-off ()
  "Exit org-view quick edit feature."
  (interactive)
  (when (bound-and-true-p org-view-mode)
    (setq inhibit-read-only nil
          overriding-local-map nil
          org-view--old-content nil)
    (org-view--toggle-features t) ;; part after edit ppint loses
                                  ;; org-view-overlays and text props
    (message "org-view quick edit disabled in current buffer")))

(defun org-view-edit-on ()
  "Enter org-view quick edit feature."
  (interactive)
  (when (bound-and-true-p org-view-mode)
    (setq inhibit-read-only t
          org-view--old-point (point)
          overriding-local-map org-view-edit-mode-map
          org-view--old-content (buffer-substring (point-min) (point-max)))
    (message "org-view edit mode enabled in current buffer")))

;;;###autoload
(define-minor-mode org-view-mode
  "Hide/show babel source code blocks on demand."
  :global nil :lighter " org-view" :keymap org-view-mode-map
  (unless (derived-mode-p 'org-mode)
    (error "Not in org-mode"))
  (if org-view-mode (org-view--on) (org-view--off)))

(provide 'org-view-mode)

;;; org-view-mode.el ends here
