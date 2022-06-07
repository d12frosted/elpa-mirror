;;; ox-haunt.el --- Haunt-flavored HTML backend for the Org export engine -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Jakob L. Kreuze

;; Author: Jakob L. Kreuze <zerodaysfordays@sdf.lonestar.org>
;; Version: 0.1
;; Package-Version: 20220602.143
;; Package-Commit: 4d585c51d5701b4d43c02db78c7032658cae47fd
;; Package-Requires: ((emacs "24.3") (org "9.0"))
;; Keywords: convenience hypermedia wp
;; URL: https://git.sr.ht/~jakob/ox-haunt

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

;; This library implements an HTML back-end for the Org generic
;; exporter, producing output appropriate for Haunt's `html-reader'.

;;; Code:

(require 'ox)
(require 'ox-html)

(org-export-define-derived-backend 'haunt 'html
  :menu-entry
  '(?s "Export to Haunt"
       ((?H "As Haunt buffer" ox-haunt-export-as-html)
        (?h "As Haunt file" ox-haunt-export-to-html)
        (?o "As Haunt file and open"
            (lambda (a s v b)
              (if a (ox-haunt-export-to-html t s v b)
                (org-open-file (ox-haunt-export-to-html nil s v b)))))
        (?A "All subtrees as Haunt file" ox-haunt-export-all-subtrees-to-html)))
  :translate-alist
  '((link . ox-haunt-link)
    (template . ox-haunt-template))
  :options-alist
  '((:tags "TAGS" nil nil)
    (:haunt-metadata "HAUNT_METADATA" nil nil)
    (:haunt-base-dir "HAUNT_BASE_DIR" nil ox-haunt-base-dir)
    (:haunt-images-dir "HAUNT_IMAGES_DIR" nil ox-haunt-images-dir)))

(defgroup org-export-haunt nil
  "Options for exporting Org mode files to Haunt HTML."
  :tag "Org Export Haunt"
  :group 'org-export)

(defcustom ox-haunt-base-dir nil
  "The default path to write output files to.
This can be specified on a per-file basis with the 'HAUNT_BASE_DIR' keyword."
  :type 'string)

;; Notably, this excludes :haunt-metadata, which we handle separately.
(defcustom ox-haunt-recognized-metadata '(:title :date :tags)
  "A list of keywords to include in the Haunt metadata section."
  :type '(list symbol))

(defcustom ox-haunt-images-dir "/images/"
  "The default path to copy images to.
This can be specified on a per-file basis with the 'HAUNT_IMAGES_DIR' keyword."
  :type 'string)

(defun ox-haunt--check-base-dir (dest-path)
  "Raise an error if DEST-PATH does not name a valid directory."
  (unless dest-path
    (user-error "It is mandatory to set the HAUNT_BASE_DIR property"))
  (unless (file-directory-p dest-path)
    (user-error "The HAUNT_BASE_DIR property must name a directory")))

(defun ox-haunt-link (link desc info)
  "Transcode a LINK object from Org to HTML.
DESC is the description part of the link, or the empty string.
INFO is the current state of the export process, as a plist."
  (let* ((orig-path (org-element-property :path link))
         (filename (file-name-nondirectory orig-path))
         (dest-path (plist-get info :haunt-base-dir))
         (images-path (plist-get info :haunt-images-dir)))
    (when (string= "file" (org-element-property :type link))
      (ox-haunt--check-base-dir dest-path)
      (copy-file orig-path (concat dest-path images-path filename) t)
      (org-element-put-property link :path (concat ".." images-path filename)))
    (org-html-link link desc info)))

(defun ox-haunt--keyword-as-string (info keyword)
  "Obtain the value of KEYWORD as a plaintext string.
INFO is the current state of the export process, as a plist."
  (org-export-data-with-backend (plist-get info keyword) 'ascii info))

(defun ox-haunt--get-valid-subtree ()
  "Return the org element for a valid Haunt post subtree.
The condition to check validity is that the EXPORT_FILE_NAME
property is defined for the subtree element."
  (catch 'break
    (let ((level))
      (while :infinite
	(let ((entry (org-element-at-point))
	      (file-name (org-entry-get (point) "EXPORT_FILE_NAME")))
	  (when file-name
	    (throw 'break entry)))
	(setq level (org-up-heading-safe))
	(unless level
	  (throw 'break nil))))))

(defun ox-haunt--format-subtree-tags (tags)
  "Given a string of tags in ':tag:...:' form return them
formatted as 'tag, ..., tag'."
  (when tags
    (string-join (split-string tags ":" t) ", ")))

(defun ox-haunt--format-subtree-date (date)
  "Given a string with an inactive org-mode timestamp return it
formatted as expected by haunt."
  (when date
    (let ((date-list (split-string (string-trim date "\\[" "\\]"))))
      (concat (first date-list) " "
	      (third date-list)))))

(defun ox-haunt--get-valid-subtree-metadata ()
  "With point on a subtree return the metadata of it or it's
first valid parent as a plist."
  (when (ox-haunt--get-valid-subtree)
   (let ((title (org-entry-get (point) "ITEM"))
	 (tags (ox-haunt--format-subtree-tags
		(org-entry-get (point) "TAGS")))
	 (date (ox-haunt--format-subtree-date
		(or (org-entry-get (point) "CLOSED")
		    (org-entry-get (point) "SCHEDULED"))))
	 (todo-state (org-entry-get (point) "TODO")))
     `(:title ,title :tags ,tags :date ,date :todo-state ,todo-state))))

(defun ox-haunt-template (contents info)
  "Return complete document string after HTML conversion.
CONTENTS is the Org file's contents rendered as HTML.
INFO is the current state of the export process, as a plist."
  (concat
   ;; Output the Haunt metadata section.
   (with-temp-buffer
     (dolist (keyword ox-haunt-recognized-metadata)
       (when (plist-get info keyword)
         (insert (format "%s: %s\n"
                         (substring (symbol-name keyword) 1)
                         (ox-haunt--keyword-as-string info keyword)))))
     ;; Handle :haunt-metadata, which we deliberately exclude from
     ;; `ox-haunt-recognized-metadata'.
     (when (plist-get info :haunt-metadata)
       (dolist (p (read (ox-haunt--keyword-as-string info :haunt-metadata)))
         (insert (format "%s: %s\n" (car p) (cdr p)))))
     (buffer-string))
   "---\n"
   ;; Output the article contents.
   contents))

;;;###autoload
(defun ox-haunt-export-as-html
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a Haunt post buffer.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Export is done in a buffer named \"*Org Haunt Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (let* ((info (org-combine-plists
                (org-export--get-export-attributes
                 'haunt subtreep visible-only)
                (org-export--get-buffer-attributes)
                (org-export-get-environment 'haunt subtreep)))
         (dest-path (plist-get info :haunt-base-dir))
	     (subtree-metadata (when subtreep
			                 (ox-haunt--get-valid-subtree-metadata))))
    (cond
     ((and subtreep (not subtree-metadata))
      (message "This is not a valid subtree to export."))
     ((and subtreep (not (string-equal
			              (plist-get subtree-metadata :todo-state)
			              "DONE")))
      (message "The post is not marked as DONE, so it won't export"))
     (t (org-export-to-buffer 'haunt "*Org Haunt Export*"
	      async subtreep visible-only body-only
          ;; Necessary to propagate a buffer-local value for `ox-haunt-base-dir'.
	      (append `(:haunt-base-dir ,dest-path) subtree-metadata ext-plist)
	      (lambda () (set-auto-mode t)))))))

;;;###autoload
(defun ox-haunt-export-to-html
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a Haunt post file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Return output file's name."
  (interactive)
  (let* ((info (org-combine-plists
                (org-export--get-export-attributes
                 'haunt subtreep visible-only)
                (org-export--get-buffer-attributes)
                (org-export-get-environment 'haunt subtreep)))
         (dest-path (plist-get info :haunt-base-dir))
	     (images-path (plist-get info :haunt-images-dir))
	     (subtree-metadata (when subtreep
			                 (ox-haunt--get-valid-subtree-metadata))))
    (ox-haunt--check-base-dir dest-path)
    (cond
     ((and subtreep (not subtree-metadata))
      (message "This is not a valid subtree to export."))
     ((and subtreep (not (string-equal
			              (plist-get subtree-metadata :todo-state)
			              "DONE")))
      (message "The post is not marked as DONE, so it won't export"))
     (t (let* ((extension (concat "." (or (plist-get ext-plist :html-extension)
					                      org-html-extension
					                      "html")))
               (file (org-export-output-file-name extension subtreep))
               (file (concat dest-path "/posts/" file))
               (org-export-coding-system org-html-coding-system))
	      (org-export-to-file 'haunt file
            async subtreep visible-only body-only
            ;; Necessary to propagate a buffer-local value for `ox-haunt-base-dir'.
            (append `(:haunt-base-dir ,dest-path)
		            `(:haunt-images-dir ,images-path)
		            subtree-metadata ext-plist)))))))

;;;###autoload
(defun ox-haunt-export-all-subtrees-to-html (&optional async visible-only body-only ext-plist)
  "Export all valid subtrees in current buffer to Haunt post
  files."
  (org-map-entries
   (lambda () (ox-haunt-export-to-html async t visible-only body-only ext-plist))
   "EXPORT_FILE_NAME<>\"\""))

(provide 'ox-haunt)
;;; ox-haunt.el ends here
