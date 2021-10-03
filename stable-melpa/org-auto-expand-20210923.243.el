;;; org-auto-expand.el --- Automatically expand certain headings  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Adam Porter

;; Author: Adam Porter <adam@alphapapa.net>
;; URL: https://github.com/alphapapa/org-auto-expand
;; Package-Version: 20210923.243
;; Package-Commit: edc27b155befab5626dcf6ceec7938126f7e31d4
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))
;; Keywords: convenience, outlines, org

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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package automatically expands certain headings in an Org file
;; depending on properties set, making it easy to always get the same
;; initial view when finding a file.

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'org)
(require 'subr-x)

;;;; Customization

(defgroup org-auto-expand nil
  "Automatically expand certain nodes upon finding an Org file."
  :group 'org
  :link '(url-link "https://github.com/alphapapa/org-auto-expand"))

(defcustom org-auto-expand-property "auto-expand"
  "Name of property holding auto-expand setting."
  :type 'string)

(defvar-local org-auto-expand-nodes nil
  "List defining how to expand outline nodes.
Should be set in a file- or dir-local variable.

Each element should be an alist, the key of which should be an
outline-path string, and the value of which corresponds to the
WHAT argument to the function `org-auto-expand-node'.")

;;;; Mode

;; We use a variable watcher to work around the fact that file-local variables
;; are not yet bound until after all of the local variables have been processed,
;; because that prevents them from being available in functions called by `eval'
;; lines, like `org-auto-expand'.  This seems both messy and elegant.

;; TODO: Figure out if there's an alternative to a variable watcher.

;;;###autoload
(define-minor-mode org-auto-expand-mode
  "Automatically expand certain headings when `org-mode' is activated."
  :global t
  (if org-auto-expand-mode
      (add-variable-watcher 'org-auto-expand-nodes #'org-auto-expand-watcher)
    (remove-variable-watcher 'org-auto-expand-nodes #'org-auto-expand-watcher)))

(defun org-auto-expand-watcher (_symbol newval operation where)
  "Call `org-auto-expand'.
When OPERATION is `set', call `org-auto-expand' in buffer WHERE
with `org-auto-expand-nodes' bound to NEWVAL."
  (when (and newval where (eq operation 'set))
    (with-current-buffer where
      (let ((org-auto-expand-nodes newval))
        (org-auto-expand)))))

;;;; Commands

;;;###autoload
(defun org-auto-expand (&optional startup)
  "Set current buffer's outline visibility accordingly.
If STARTUP is non-nil (interactively, with prefix), call
`org-set-startup-visibility' first."
  (interactive "P")
  (unless (derived-mode-p 'org-mode)
    (user-error "Not an Org buffer: %s" (current-buffer)))
  (when startup
    (org-set-startup-visibility))
  (when org-auto-expand-nodes
    (cl-loop for (olp . how) in org-auto-expand-nodes
             do (when-let ((pos (org-find-olp olp 'this-buffer)))
                  (org-with-point-at pos
                    (org-auto-expand-node how)))))
  (org-with-wide-buffer
   (goto-char (point-min))
   (let ((re (org-re-property org-auto-expand-property)))
     (while (re-search-forward re nil t)
       (save-excursion
         (org-back-to-heading)
         (org-auto-expand-node))))))

;;;; Functions

(cl-defun org-auto-expand-node (&optional (what (org-entry-get (point) org-auto-expand-property)))
  "Set current node's what according to WHAT.
If WHAT is nil, use value of `org-auto-expand-property' at node.

WHAT may be a string, or it may be a list of the following,
meaning to:

- `heading': Show just the heading.
- `body': Show the heading and its body, but not its children.
- `children': Show the heading's children, but not its body.
- A number N: Show child headings N levels deep.
- A symbol that `org-show-context' accepts as an argument.

If WHAT is a string, it is split on spaces and should be a list
of the choices above."
  (setf what (cl-typecase what
               (string (cl-loop for it in (split-string what nil 'omit-nulls (rx (1+ space)))
                                collect (if (> (string-to-number it) 0)
                                            (string-to-number it)
                                          (intern it))))
               (list what)
               (number (list what))
               (symbol (list what))))
  (dolist (thing what)
    (pcase thing
      ('heading (org-show-context 'minimal))
      ((or 'body)
       (org-show-context 'minimal)
       (org-cycle))
      ('children (org-show-children 1))
      ((pred numberp) (org-show-children thing))
      (else (org-show-context else)))))

;;;; Footer

(provide 'org-auto-expand)

;;; org-auto-expand.el ends here
