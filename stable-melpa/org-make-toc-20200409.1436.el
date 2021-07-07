;;; org-make-toc.el --- Automatic tables of contents for Org files  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Adam Porter

;; Author: Adam Porter <adam@alphapapa.net>
;; URL: http://github.com/alphapapa/org-make-toc
;; Package-Version: 20200409.1436
;; Package-Commit: 26fbd6a7e1e7f8e473fe3a5f74faec715c3a05aa
;; Version: 0.5
;; Package-Requires: ((emacs "26.1") (dash "2.12") (s "1.10.0") (org "9.0"))
;; Keywords: Org, convenience

;;; Commentary:

;; This package makes it easy to have one or more customizable tables of contents in Org files.
;; They can be updated manually, or automatically when the file is saved.  Links to headings are
;; created compatible with GitHub's Org renderer.

;;;; Installation

;; Install the packages `dash' and `s'.  Then put this file in your `load-path', and put this in
;; your init file:

;;   (require 'org-make-toc)

;;;; Usage

;; A document may have any number of tables of contents (TOCs), each of
;; which may list entries in a highly configurable way.  To make a basic
;; TOC, follow these steps:
;;
;; 1.  Choose a heading to contain a TOC and go to it.
;; 2.  Press `C-c C-x p' (`org-set-property'), add a `TOC' property, and
;;     set its value to `:include all'.
;; 3.  Run command `org-make-toc-insert' to insert the `:CONTENTS:' drawer,
;;     which will contain the TOC entries.
;; 4.  Run the command `org-make-toc' to update all TOCs in the document,
;;     or `org-make-toc-at-point' to update the TOC for the entry at point.
;;
;;
;; Example
;; ═══════
;;
;;   Here's a simple document containing a simple TOC:
;;
;;   ┌────
;;   │ * Heading
;;   │ :PROPERTIES:
;;   │ :TOC:      :include all
;;   │ :END:
;;   │
;;   │ This text appears before the TOC.
;;   │
;;   │ :CONTENTS:
;;   │ - [[#heading][Heading]]
;;   │   - [[#subheading][Subheading]]
;;   │ :END:
;;   │
;;   │ This text appears after it.
;;   │
;;   │ ** Subheading
;;   └────
;;
;;
;; Advanced
;; ════════
;;
;;   The `:TOC:' property is a property list which may set these keys and
;;   values.
;;
;;   These keys accept one setting, like `:include all':
;;
;;   ⁃ `:include' Which headings to include in the TOC.
;;     • `all' Include all headings in the document.
;;     • `descendants' Include the TOC's descendant headings.
;;     • `siblings' Include the TOC's sibling headings.
;;   ⁃ `:depth' A number >= 0 indicating a depth relative to this heading.
;;     Descendant headings at or above this relative depth are included in
;;     TOCs that include this heading.
;;
;;   These keys accept either one setting or a list of settings, like
;;   `:force depth' or `:force (depth ignore)':
;;
;;   ⁃ `:force' Heading-local settings to override when generating the TOC
;;     at this heading.
;;     • `depth' Override `:depth' settings.
;;     • `ignore' Override `:ignore' settings.
;;   ⁃ `:ignore' Which headings, relative to this heading, to exclude from
;;     TOCs.
;;     • `descendants' Exclude descendants of this heading.
;;     • `siblings' Exclude siblings of this heading.
;;     • `this' Exclude this heading (not its siblings or descendants).
;;   ⁃ `:local' Heading-local settings to ignore when generating TOCs at
;;     higher levels.
;;     • `depth' Ignore `:depth' settings.
;;
;;   See [example.org] for a comprehensive example of the features
;;   described above.
;;
;;
;; [example.org]
;; https://github.com/alphapapa/org-make-toc/blob/master/example.org
;;
;;
;; Automatically update on save
;; ════════════════════════════
;;
;;   To automatically update a file's TOC when the file is saved, use the
;;   command `add-file-local-variable' to add `org-make-toc' to the Org
;;   file's `before-save-hook'.
;;
;;   Or, you may activate it in all Org buffers like this:
;;
;;   ┌────
;;   │ (add-hook 'org-mode-hook #'org-make-toc-mode)
;;   └────

;;; License:

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

;;; Code:

(require 'cl-lib)
(require 'org)
(require 'rx)
(require 'seq)
(require 'subr-x)

(require 'dash)
(require 's)

;;;; Variables

(defgroup org-make-toc nil
  "Settings for `org-make-toc'."
  :group 'org
  :link '(url-link "http://github.com/alphapapa/org-make-toc"))

(defcustom org-make-toc-filename-prefix nil
  "Prefix links with filename before anchor tag."
  :type 'boolean
  :safe #'booleanp)

(defcustom org-make-toc-link-type-fn #'org-make-toc--link-entry-github
  "Type of links to make.
`org-element' entries are passed to this function, which returns
an Org link as a string, the target of which should be compatible
with the destination of the published file."
  :type '(choice (const :tag "GitHub-compatible" org-make-toc--link-entry-github)
                 (const :tag "Org-compatible" org-make-toc--link-entry-org)
                 (function :tag "Custom function")))

(defcustom org-make-toc-exclude-tags '("noexport")
  "Entries with any of these tags are excluded from TOCs."
  :type '(repeat string))

;;;; Commands

;;;###autoload
(defun org-make-toc ()
  "Make or update table of contents in current buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (cl-loop with made-toc
             for pos = (org-make-toc--next-toc-position)
             while pos
             do (progn
                  (goto-char pos)
                  (when (org-make-toc--update-toc-at-point)
                    (setq made-toc t)))
             finally do (unless made-toc
                          (message "org-make-toc: No TOC node found.")))))

;;;###autoload
(defun org-make-toc-at-point ()
  "Make or update table of contents at current entry."
  (interactive)
  (unless (org-make-toc--update-toc-at-point)
    (user-error "No TOC node found")))

;;;###autoload
(defun org-make-toc-insert ()
  "Insert \":CONTENTS:\" drawer at point."
  (interactive)
  (call-interactively #'org-make-toc-set)
  (org-insert-drawer nil "CONTENTS"))

;;;###autoload
(defun org-make-toc-set (properties)
  "Set TOC PROPERTIES of entry at point."
  (interactive (list (org-make-toc--complete-toc-properties)))
  (org-set-property "TOC" properties))

;;;; Functions

(defun org-make-toc--complete-toc-properties ()
  "Return TOC properties string read with completion."
  (cl-labels ((property (property)
                        (--> (org-entry-get (point) "TOC")
                             (concat "(" it ")") (read it)
                             (plist-get it property)
                             (if it
                                 (prin1-to-string it)
                               "")))
              (read-number (prompt &optional initial-input)
                           ;; The default `read-number' only accepts a number, and
                           ;; we need to allow the user to input nothing.  But
                           ;; using `read-string' with `string-to-number' returns
                           ;; 0 for the empty string, so we use this instead.
                           (let ((input (read-string prompt initial-input)))
                             (pcase input
                               ((rx bos (1+ digit) eos)
                                (string-to-number input))
                               ((rx bos (0+ blank) eos) "")
                               (_ (read-number prompt initial-input)))))
              (completing-read-description
               (prompt collection &optional predicate require-match
                       initial-input hist def inherit-input-method)
               (let ((choice (completing-read prompt collection predicate require-match
                                              initial-input hist def inherit-input-method)))
                 (alist-get choice collection nil nil #'equal)))
              ;; TODO: Version of `completing-read-multiple' that works like that.  Sigh.
              )
    (let ((props
           (list :include (completing-read-description
                           "Include entries: "
                           '(("None" . nil) ("All" . all) ("Descendants" . descendants)
                             ("Siblings" . siblings))
                           nil t (property :include))
                 :depth (read-number "Depth (number): " (property :depth))
                 :force (completing-read-multiple "Force (one or more): "
                                                  '(("nothing" . nil) ("depth" . depth)
                                                    ("ignore" . ignore))
                                                  nil t (property :force))
                 :ignore (completing-read-multiple "Ignore entries (one or more): "
                                                   '(("nothing" . nil) ("descendants" . descendants)
                                                     ("siblings" . siblings) ("this" . this))
                                                   nil t (property :ignore))
                 :local (completing-read-multiple "Tree-local settings (one or more): "
                                                  '(("nothing" . nil) ("depth" . depth))
                                                  nil t (property :force)))))
      (when (cl-loop for property in '(:include :depth :force :ignore :local)
                     thereis (pcase (plist-get props property)
                               ((or "" "nil" (\` nil)) nil)
                               (_ t)))
        ;; Only return a string if at least one property is set.
        (substring (format "%s" (cl-loop for (property value) on props by #'cddr
                                         unless (member value '("" "nil" nil))
                                         append (list property value)))
                   1 -1)))))

(defun org-make-toc--next-toc-position ()
  "Return position of next TOC, or nil."
  (save-excursion
    (when (and (re-search-forward (rx bol ":CONTENTS:" (0+ blank) eol) nil t)
               (save-excursion
                 (beginning-of-line)
                 (looking-at-p org-drawer-regexp)))
      (point))))

(defun org-make-toc--update-toc-at-point ()
  "Make or update table of contents at current entry."
  (when-let* ((toc-string (org-make-toc--toc-at-point)))
    (org-make-toc--replace-entry-contents toc-string)
    t))

(defun org-make-toc--toc-at-point ()
  "Return TOC tree for entry at point."
  (cl-labels ((descendants (&key depth force)
                           (when (and (or (null depth) (> depth 0))
                                      (children-p))
                             (save-excursion
                               (save-restriction
                                 (org-narrow-to-subtree)
                                 (outline-next-heading)
                                 (cl-loop collect (cons (entry :force force)
                                                        (unless (entry-match :ignore 'descendants)
                                                          (descendants :depth (or (unless (or (arg-has force 'depth)
                                                                                              (entry-match :local 'depth))
                                                                                    (entry-property :depth))
                                                                                  (when depth
                                                                                    (1- depth)))
                                                                       :force force)))
                                          while (next-sibling))))))
              (siblings (&key depth force)
                        (save-excursion
                          (save-restriction
                            (when (org-up-heading-safe)
                              (org-narrow-to-subtree)
                              (outline-next-heading)
                              (outline-next-heading))
                            (cl-loop collect (cons (entry :force force)
                                                   (unless (entry-match :ignore 'descendants)
                                                     (descendants :depth (or (unless (or (arg-has force 'depth)
                                                                                         (entry-match :local 'depth))
                                                                               (entry-property :depth))
                                                                             (when depth
                                                                               (1- depth)))
                                                                  :force force)))
                                     while (next-sibling)))))
              (children-p ()
                          (let ((level (org-current-level)))
                            (save-excursion
                              (when (outline-next-heading)
                                (> (org-current-level) level)))))
              (next-sibling ()
                            (let ((pos (point)))
                              (org-forward-heading-same-level 1 'invisible-ok)
                              (/= pos (point))))
              (arg-has (var val)
                       (or (equal var val)
                           (and (listp var)
                                (member val var))))
              (entry (&key force)
                     (unless (or (and (not (arg-has force 'ignore))
                                      (entry-match :ignore 'this))
                                 ;; TODO: Add configurable predicate list to exclude entries.
                                 (seq-intersection org-make-toc-exclude-tags (org-get-tags))
                                 ;; NOTE: The "COMMENT" keyword is not returned as the to-do keyword
                                 ;; by `org-heading-components', so it can't be tested as a keyword.
                                 (string-match-p (rx bos "COMMENT" (or blank eos))
                                                 (nth 4 (org-heading-components))))
                       (funcall org-make-toc-link-type-fn)))
              (entry-match (property value)
                           (when-let* ((found-value (entry-property property)))
                             (or (equal value found-value)
                                 (and (listp found-value) (member value found-value)))))
              (entry-property (property)
                              (plist-get (read (concat "(" (org-entry-get (point) "TOC") ")"))
                                         property)))
    (save-excursion
      (save-restriction
        (-let* (((&plist :include :depth :force force)
                 (read (concat "(" (org-entry-get (point) "TOC") ")")))
                (tree (pcase include
                        ;; Set bounds.
                        ('all (org-with-wide-buffer
                               (goto-char (point-min))
                               (when (org-before-first-heading-p)
                                 (outline-next-heading))
                               (siblings :depth (or (unless (arg-has force 'depth)
                                                      (entry-property :depth))
                                                    (when depth
                                                      (1- depth)))
                                         :force force)))
                        ('descendants (descendants :depth depth :force force))
                        ('siblings (siblings :depth depth :force force)))))
          (org-make-toc--tree-to-list tree))))))

(defun org-make-toc--tree-to-list (tree)
  "Return list string for TOC TREE."
  (cl-labels ((tree (tree depth)
                    (when (> (length tree) 0)
                      (when-let* ((entries (->> (append (when (car tree)
                                                          (list (concat (s-repeat depth "  ")
                                                                        "- " (car tree))))
                                                        (--map (tree it (1+ depth))
                                                               (cdr tree)))
                                                -non-nil -flatten)))
                        (s-join "\n" entries)))))
    (->> tree
         (--map (tree it 0))
         -flatten (s-join "\n"))))

(defun org-make-toc--link-entry-github ()
  "Return text for ENTRY converted to GitHub style link."
  (-when-let* ((title (nth 4 (org-heading-components)))
               (target (--> title
                            org-link-display-format
                            (downcase it)
                            (replace-regexp-in-string " " "-" it)
                            (replace-regexp-in-string "[^[:alnum:]_-]" "" it)))
               (filename (if org-make-toc-filename-prefix
                             (file-name-nondirectory (buffer-file-name))
                           "")))
    (org-make-link-string (concat filename "#" target)
                          (org-make-toc--visible-text title))))

(defun org-make-toc--link-entry-org ()
  "Return text for ENTRY converted to regular Org link."
  ;; FIXME: There must be a built-in function to do this, although it might be in `org-export'.
  (-when-let* ((title (nth 4 (org-heading-components)))
               (filename (if org-make-toc-filename-prefix
                             (concat "file:" (file-name-nondirectory (buffer-file-name)) "::")
                           "")))
    (org-make-link-string (concat filename title)
                          (org-make-toc--visible-text title))))

(defun org-make-toc--replace-entry-contents (contents)
  "Replace the contents of TOC in entry at point with CONTENTS.
Replaces contents of :CONTENTS: drawer."
  (save-excursion
    (org-back-to-heading 'invisible-ok)
    (let* ((end (org-entry-end-position))
           contents-beg contents-end)
      (when (and (re-search-forward (rx bol ":CONTENTS:" (0+ blank) eol) end t)
                 (save-excursion
                   (beginning-of-line)
                   (looking-at-p org-drawer-regexp)))
        ;; Set the end first, then search back and skip any ":TOC:" property line in the drawer.
        (setf contents-end (save-excursion
                             (when (re-search-forward (rx bol ":END:" (0+ blank) eol) end)
                               (match-beginning 0)))
              contents-beg (progn
                             (when (save-excursion
                                     (forward-line 1)
                                     (looking-at-p (rx bol ":TOC:" (0+ blank) (group (1+ nonl)))))
                               (forward-line 1))
                             (point-at-eol))
              contents (concat "\n" (string-trim contents) "\n")
              (buffer-substring contents-beg contents-end) contents)))))

(defun org-make-toc--visible-text (string)
  "Return only visible text in STRING after fontifying it like in Org-mode.

`org-fontify-like-in-org-mode' is a very, very slow function
because it creates a new temporary buffer and runs `org-mode' for
every string it fontifies.  This function reuses a single
invisible buffer and only runs `org-mode' when the buffer is
created."
  ;; MAYBE: Use `org-sort-remove-invisible' instead?  Not sure if it does exactly the same thing.
  (let ((buffer (get-buffer " *org-make-toc-fontification*")))
    (unless buffer
      (setq buffer (get-buffer-create " *org-make-toc-fontification*"))
      (with-current-buffer buffer
        (buffer-disable-undo)
        (org-mode)
        (setq-local org-hide-emphasis-markers t)))
    (with-current-buffer buffer
      (insert string)
      (font-lock-ensure)
      ;; This is more complicated than I would like, but the `org-find-invisible' and
      ;; `org-find-visible' functions don't seem to be appropriate to this task, so this works.
      (prog1
          (cl-flet ((visible-p () (not (get-char-property (point) 'invisible)))
                    (invisible-p () (get-char-property (point) 'invisible))
                    (forward-until (until)
                                   (cl-loop until (or (eobp) (funcall until))
                                            for pos = (next-single-property-change (point) 'invisible nil (point-max))
                                            while pos
                                            do (goto-char pos))
                                   (point))
                    (backward-until (until)
                                    (cl-loop until (or (eobp) (funcall until))
                                             for pos = (previous-single-property-change (point) 'invisible nil (point-max))
                                             while pos
                                             do (goto-char pos))
                                    (point)))
            (goto-char (point-min))
            (unless (visible-p)
              (forward-until #'visible-p))
            (setq string (cl-loop concat (buffer-substring (point) (forward-until #'invisible-p))
                                  until (eobp)
                                  do (forward-until #'visible-p))))
        (erase-buffer)))))

;;;; Mode

;;;###autoload
(define-minor-mode org-make-toc-mode
  "Add the `org-make-toc' command to the `before-save-hook' in the current Org buffer.
With prefix argument ARG, turn on if positive, otherwise off."
  :init-value nil
  (unless (derived-mode-p 'org-mode)
    (user-error "Not an Org buffer"))
  (funcall (if org-make-toc-mode #'add-hook #'remove-hook)
           'before-save-hook #'org-make-toc)
  (message (format "org-make-toc-mode %s."
                   (if org-make-toc-mode
                       "enabled"
                     "disabled"))))

;;;; Footer

(provide 'org-make-toc)

;;; org-make-toc.el ends here
