;;; org-bookmark-heading.el --- Emacs bookmark support for Org mode  -*- lexical-binding: t; -*-

;; Author: Adam Porter <adam@alphapapa.net>
;; Version: 1.3
;; Package-Version: 20230517.1141
;; Package-Commit: 4e97fab8cf0307fc338df50efac103ed966c7914
;; Url: http://github.com/alphapapa/org-bookmark-heading
;; Package-Requires: ((emacs "24.4"))
;; Keywords: hypermedia, outlines

;;; Commentary:

;; This package provides Emacs bookmark support for Org mode.  You can
;; bookmark headings in Org mode files and jump to them using standard
;; Emacs bookmark commands.

;; It seems like this file should be named org-bookmark.el, but a
;; package by that name already exists in org-mode/contrib which lets
;; Org mode links point to Emacs bookmarks, sort-of the reverse of
;; this package.

;; It also seems like this should be built-in to Org mode...  ;)

;;; Installation

;; Require the package in your init file:

;; (require 'org-bookmark-heading)

;; Then you can customize `org-bookmark-jump-indirect' if you like.

;;; Usage

;; Use the standard Emacs bookmark commands, "C-x r m", etc.

;; If you use Helm, you can jump to Org mode bookmarks in an indirect
;; buffer by pressing "<C-return>" in the Helm buffer, or by choosing
;; the action from the list.

;; You can also customize the variable `org-bookmark-jump-indirect' to
;; make Org mode bookmarks always open in indirect buffers.

;;; Credits:

;;  Thanks to Steve Purcell for his advice on several improvements.

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

(require 'mode-local)
(require 'org)
(require 'bookmark)

(eval-when-compile
  ;; Support map pattern in pcase
  (require 'map))

;;;; Customization

(defgroup org-bookmark-heading nil
  "Bookmark headings in Org files."
  :group 'org
  :link '(url-link "http://github.com/alphapapa/org-bookmark-heading"))

(define-obsolete-variable-alias
  'org-bookmark-jump-indirect 'org-bookmark-heading-jump-indirect "1.2")

(defcustom org-bookmark-heading-jump-indirect nil
  "Jump to bookmarks in indirect buffers.
When enabled, always jump to bookmarked headings in indirect
buffers.  Otherwise, only use indirect buffers if the bookmark
was made in one."
  :type 'boolean)

(defcustom org-bookmark-heading-filename-fn #'org-bookmark-heading--display-path
  "Function that returns string to display representing bookmarked file's path.
It should take one argument, the path to the file."
  :type 'function)

(defcustom org-bookmark-heading-make-ids nil
  "Automatically make ID properties when bookmarking headings.
A bookmark will always include an entry's filename, outline path,
and ID, if one exists.  If this option is enabled, an ID will be
created for entries that don't already have one."
  :type '(choice (const :tag "Make ID if missing" t)
                 (const :tag "Make ID if missing and entry is within `org-directory'"
                        (lambda ()
                          (and (buffer-file-name)
                               (file-in-directory-p (buffer-file-name) org-directory))))
                 (const :tag "Use existing IDs, but don't make new ones" nil)
                 (function :tag "Custom predicate" :doc "Called with point at the heading, it should return non-nil if an ID should be created.  This may be useful to, e.g. only make IDs for entries within one's `org-directory'.")))

(defcustom org-bookmark-heading-after-jump-hook nil
  "Hook run after jumping to a heading.
Called with point on heading.  Can be used to, e.g. cycle visibility."
  :type 'hook)

;;;; Variables

(setq-mode-local org-mode bookmark-make-record-function 'org-bookmark-heading-make-record)

;;;; Functions

;;;###autoload
(defun org-bookmark-heading-make-record ()
  "Return bookmark record for current heading.
Sets ID property for heading if necessary."
  (let* ((filename (buffer-file-name (org-base-buffer (current-buffer))))
         (display-filename (funcall org-bookmark-heading-filename-fn filename))
         (heading (unless (org-before-first-heading-p)
                    (org-link-display-format (org-get-heading t t))))
         (name (concat display-filename (when heading
                                          (concat ":" heading))))
         (outline-path (when heading
                         (org-get-outline-path 'with-self)))
         (indirectp (when (buffer-base-buffer) t))
         id handler)
    (unless (and (boundp 'bookmark-name)
                 (or (string= bookmark-name (plist-get org-bookmark-names-plist :last-capture-marker))
                     (string= bookmark-name (plist-get org-bookmark-names-plist :last-capture))
                     (string= bookmark-name (plist-get org-bookmark-names-plist :last-refile))))
      ;; When `org-capture-mode' is active, and/or when a heading is
      ;; being refiled, do not create an org-id for the current
      ;; heading, and do not set the bookmark handler.  This is
      ;; because org-capture sets a bookmark for the last capture when
      ;; `org-capture-bookmark' is non-nil, and `org-refile' sets a
      ;; bookmark when a heading is refiled, and we don't want every
      ;; heading captured or refiled to get an org-id set by this
      ;; function, because not everyone wants to have property drawers
      ;; "polluting" every heading in their org files. `bookmark-name'
      ;; is set in `org-capture-bookmark-last-stored-position' and in
      ;; `org-refile', and it seems to be the way to detect whether
      ;; this is being called from a capture or a refile.
      (setf id (org-id-get (point) (pcase-exhaustive org-bookmark-heading-make-ids
                                     (`t t)
                                     (`nil nil)
                                     ((pred functionp) (funcall org-bookmark-heading-make-ids))))
            handler #'org-bookmark-heading-jump))
    (rassq-delete-all nil `(,name
                            (filename . ,filename)
                            (handler . ,handler)
                            ;; TODO: Let the context string be the "natural" one that a bookmark would normally use.
                            ;; (front-context-string . ,front-context-string)
                            (id . ,id)
                            (outline-path . ,outline-path)
                            (indirectp . ,indirectp)))))

(define-obsolete-function-alias
  'org-bookmark-make-record 'org-bookmark-heading-make-record "1.2")

(defun org-bookmark-heading--display-path (path)
  "Return display string for PATH.
Returns in format \"parent-directory/filename\"."
  ;; TODO: In Emacs 28.1, use `file-name-concat'.
  (concat (file-name-nondirectory (directory-file-name (file-name-directory path)))
          "/" (file-name-nondirectory path)))

;;;###autoload
(defun org-bookmark-heading-jump (bookmark)
  "Jump to `org-bookmark-heading' BOOKMARK.
BOOKMARK record should have fields `map', `outline-path', and
`id', (and, for compatibility, `front-context-string' is also
supported, in which case it should be an entry ID)."
  (cl-flet ((jump-to-id
             (id) (when-let ((id id)
                             (marker (org-id-find id 'markerp)))
                    (org-goto-marker-or-bmk marker)
                    (current-buffer)))
            (jump-to-olp (outline-path)
                         (when-let ((olp outline-path)
                                    (marker (org-find-olp outline-path 'this-buffer)))
                           (org-goto-marker-or-bmk marker)
                           (current-buffer))))
    (pcase-let* ((`(,_name . ,(map filename outline-path id front-context-string indirectp)) bookmark)
                 (id (or id
                         ;; For old bookmark records made before we
                         ;; saved the `id' key.
                         front-context-string))
                 (original-buffer (current-buffer))
                 (new-buffer))
      (when (or (and (or id outline-path)
                     ;; Bookmark has ID and/or outline path.
                     (or (jump-to-id id)
                         ;; ID not found: Open the file and look again.
                         (when-let ((buffer (when filename
                                              (or (org-find-base-buffer-visiting filename)
                                                  (and (file-exists-p filename)
                                                       (setf new-buffer t)
                                                       (find-file-noselect filename))))))
                           ;; Found file.
                           (progn
                             (setf new-buffer buffer)
                             (set-buffer buffer)
                             (or (jump-to-id id)
                                 ;; Still couldn't find ID: Try outline path.
                                 (jump-to-olp outline-path)
                                 (progn
                                   ;; ID not found: Cleanup buffer.
                                   (kill-buffer new-buffer)
                                   (error "Can't find bookmarked heading: %S" bookmark)))))))
                ;; Bookmark only has filename, not ID or outline path.
                (and filename
                     (find-file filename)))
        ;; Found heading or file.
        (when (and (or indirectp org-bookmark-heading-jump-indirect)
                   (or id outline-path))
          ;; Found heading (not just file): open in indirect buffer.
          (let ((org-indirect-buffer-display 'current-window))
            ;; We bind `org-indirect-buffer-display' to this because
            ;; this is the only value that makes sense for our purpose.
            (org-tree-to-indirect-buffer))
          (unless (equal original-buffer (car (window-prev-buffers)))
            ;; The selected bookmark was in a different buffer.  Put the
            ;; non-indirect buffer at the bottom of the prev-buffers list
            ;; so it won't be selected when the indirect buffer is killed.
            (set-window-prev-buffers nil (append (cdr (window-prev-buffers))
                                                 (list (car (window-prev-buffers))))))
          (run-hooks 'org-bookmark-heading-after-jump-hook))
        (unless (equal (file-truename (or (buffer-file-name (buffer-base-buffer))
                                          (buffer-file-name)))
                       (file-truename filename))
          ;; TODO: Automatically update the bookmark?
          ;; Warn that the node has moved to another file
          (message "Heading has moved to another file.  Consider updating bookmark: %S" bookmark))))))

;;;###autoload
(define-obsolete-function-alias
  'org-bookmark-jump 'org-bookmark-heading-jump "1.2")

;;;; Helm support

(with-eval-after-load 'helm-bookmark

  (defun helm-org-bookmark-heading-jump-indirect-action (bookmark)
    "Call `bookmark-jump' with `org-bookmark-heading-jump-indirect' set to t.

This function is necessary because `helm-exit-and-execute-action'
somehow loses the dynamic binding of `org-bookmark-heading-jump-indirect'.
This calls `bookmark-jump' with it set properly.  Maybe there's a
better way to do this, but Helm can be confusing, and this works."
    (let ((org-bookmark-heading-jump-indirect t))
      (bookmark-jump bookmark)))

  (defun helm-org-bookmark-heading-jump-indirect ()
    "Jump to bookmark in an indirect buffer."
    (interactive)
    (with-helm-alive-p
      (let ((bookmark (helm-get-selection)))
        (if (member (bookmark-get-handler bookmark) '(org-bookmark-heading-jump org-bookmark-jump))
            ;; Selected candidate is an org-mode bookmark
            (helm-exit-and-execute-action 'helm-org-bookmark-jump-indirect-action)
          (error "Not an org-mode bookmark")))))

  (unless (lookup-key helm-bookmark-map (kbd "<C-return>"))
    (define-key helm-bookmark-map (kbd "<C-return>") 'helm-org-bookmark-jump-indirect))
  (add-to-list 'helm-type-bookmark-actions
               '("Jump to org-mode bookmark in indirect buffer" . helm-org-bookmark-jump-indirect-action)
               t))

;;;; Footer

(provide 'org-bookmark-heading)

;;; org-bookmark-heading.el ends here
