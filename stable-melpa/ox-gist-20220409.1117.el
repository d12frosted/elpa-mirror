;;; ox-gist.el --- Org mode exporter for GitHub gists

;; Copyright (C) 2022 Puneeth Chaganti

;; Author: Puneeth Chaganti <punchagan+emacs@muse-amuse.in>
;; Created: 2022 March 08
;; Version: 0.3
;; Package-Version: 20220409.1117
;; Package-Commit: 331aef87fb83a40fc3213cb8f5733d00d6581985
;; Package-Requires: ((emacs "26.1") (gist "1.4.0") (s "1.12.0"))
;; Keywords: org, lisp, gist, github
;; URL: https://github.com/punchagan/org2gist/

;; This file is not part of GNU Emacs.

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

;; Often, I find myself wanting to share a subtree from my notes file,
;; publicly.  It is convenient to use gists for this, since GitHub renders the
;; org syntax correctly.  This package makes it easy to do that.

;;; Usage:

;; Once you install and load the package, you can use the `org-export-dispatch'
;; function (usually bound to `C-c C-e') to "export" a buffer or a subtree to a
;; GitHub gist.  The org export menu provides options to export as a public or
;; private gist, and to open the gist in a browser after publishing it.

;;; Code:

(require 'gist)
(require 's)
(require 'org)
(require 'ox-org)

(defun org-gist-export--get-export-options (subtreep)
  "Find GIST_ID for a buffer or subtree based on SUBTREEP.

When getting the export options while exporting a subtree, we try
to look for any parent subtrees which may have defined the
GIST_ID export option."
  (when subtreep
    (let ((gist-id (org-entry-get-with-inheritance "EXPORT_GIST_ID")))
      (and gist-id
           (and (goto-char (org-find-property "EXPORT_GIST_ID" gist-id))
                ;; org-export--get-subtree-options gives parent value if on subtree headline
                (forward-line 1)))))
  (if subtreep
      (org-export--get-subtree-options 'gist)
    (org-export--get-inbuffer-options 'gist)))

(defun org-gist-export-dwim (&optional public async subtreep visible-only body-only ext-plist)
  "Post or update current org buffer or subtree as a gist.

If PUBLIC is non-nil, the gist is posted as a public gist.
NOTE: The argument only works for new gists.  It doesn't toggle
the public/private status when editing gists.

If SUBTREEP is non-nil, the current subtree is exported as a
Gist.  If a parent of the current subtree has a GIST_ID property
set, the parent subtree is exported.  This is done to prevent
accidentally re-exporting parts of an already published Gist,
when trying to update it.  To publish, the subtree separately,
remove the parent's GIST_ID temporarily and publish.  Once
published, the sub-subtree will be updated correctly.

ASYNC, VISIBLE-ONLY, BODY-ONLY, EXT-PLIST are simply passed onto
the `org-org-export-as-org' function."

  (save-window-excursion
    (save-excursion
      (let* ((export-options (org-gist-export--get-export-options subtreep))
             (gist-id (plist-get export-options :gist_id))
             (title (or (org-no-properties (car (plist-get export-options :title)))
                        (file-name-nondirectory (buffer-file-name))))
             (filename (format "%s.org" (s-dashed-words title)))
             (content-buffer (current-buffer))
             (switch-to-buffer-preserve-window-point t)
             (export-buffer (org-org-export-as-org async subtreep visible-only body-only ext-plist))
             gist)
        (if (null gist-id)
            (cl-letf (((symbol-function 'gist-ask-for-description-maybe) (lambda () title)))
              (rename-buffer filename)
              (gist-region (point-min) (point-max) (null public))
              (switch-to-buffer content-buffer)
              (let ((gist-id (car (last (split-string (current-kill 0 t) "/")))))
                (if subtreep
                    (org-set-property "EXPORT_GIST_ID" gist-id)
                  (goto-char (point-min))
                  (insert (format "#+GIST_ID: %s\n" gist-id)))))
          (gist-fetch gist-id)
          (replace-buffer-contents export-buffer)
          (gist-mode-edit-buffer filename)
          (setq gist (gist-list-db-get-gist gist-id))
          (kill-new (slot-value gist 'html-url))
          ;; Edit description, if required
          (unless (string= title (slot-value gist 'description))
            (let ((api (gist-get-api t))
                  (g (clone gist
                            :files nil
                            :description title)))
              (gh-gist-edit api g))))
        (kill-buffer export-buffer)
        (let ((url (car kill-ring)))
          (message "Gist URL: %s (copied to clipboard)" (car kill-ring))
          url)))))

(org-export-define-derived-backend 'gist 'org
  :menu-entry
  '(?G "Export to GitHub gist"
       ((?g "Private gist"
            (lambda (a s v b)
              (org-gist-export-to-gist nil nil a s v b)))
        (?G "Public gist"
            (lambda (a s v b)
                (org-gist-export-to-gist 'public nil a s v b)))
        (?o "Create & open private gist"
            (lambda (a s v b)
                (org-gist-export-to-gist nil 'open a s v b)))
        (?O "Create & open public gist"
            (lambda (a s v b)
                (org-gist-export-to-gist 'public 'open a s v b)))))
  :options-alist '((:gist_id "GIST_ID" nil nil t)))

(defun org-gist-export-to-gist (&optional public open async subtreep visible-only body-only ext-plist)
  "Export to gist.

SUBTREEP exports only the subtree.
If PUBLIC is non-nil, the export creates a public gist.
If OPEN is non-nil the gist is opened in a browser.

ASYNC, VISIBLE-ONLY, BODY-ONLY, EXT-PLIST are simply passed onto
the `org-org-export-as-org' function."
  (let ((url
         (org-gist-export-dwim public async subtreep visible-only body-only ext-plist)))
    (when open (browse-url url))))

(provide 'ox-gist)
;;; ox-gist.el ends here
