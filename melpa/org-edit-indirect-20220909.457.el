;;; org-edit-indirect.el --- Edit anything, not just source blocks -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Ag Ibragimomv
;;
;; Author: Ag Ibragimomv <https://github.com/agzam>
;; Maintainer: Ag Ibragimomv <agzam.ibragimov@gmail.com>
;; Created: May, 2021
;; Version: 1.1.0
;; Package-Version: 20220909.457
;; Package-Commit: 62894ac7b8b85eb03766f66072b0be10ffb6898e
;; Keywords: convenience extensions outlines
;; Homepage: https://github.com/agzam/org-edit-indirect.el
;; Package-Requires: ((emacs "27") (edit-indirect "0.1.10") (org "9.0"))
;;
;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Extension for `(org-edit-special)` that includes things that are not covered, like
;; quote, verse, and comment blocks
;;
;;; Usage:
;;
;; After installing the package, add the following hook:
;;
;; (add-hook 'org-mode-hook #'org-edit-indirect-mode)
;;
;;; Code:

(require 'edit-indirect)
(require 'org-element)

(defun org-edit-indirect-generic-block (org-element)
  "Edit ORG-ELEMENT with `edit-indirect-region'."
  (interactive)
  (let* ((el-type (org-element-type (org-element-context org-element)))
         (parent (org-element-property :parent org-element))
         (beg (pcase el-type
                ((or `quote-block `verse-block `comment-block `plain-list 'drawer 'paragraph 'headline)
                 (org-element-property :contents-begin org-element))
                (_ (org-element-property :begin (or parent org-element)))))
         (end (pcase el-type
                ((or `quote-block `verse-block `comment-block `plain-list 'drawer 'paragraph 'headline)
                 (org-element-property :contents-end org-element))
                (_ (org-element-property :end (or parent org-element))))))
    (edit-indirect-region beg end :display)))

(defun org-edit-indirect-special+ (&optional arg)
  "Call a special editor for the element at point.

This extends `org-edit-special' to edit blocks that it doesn't
support.

ARG is passed to `org-edit-special'."
  (interactive "P")
  (let* ((element (org-element-at-point))
         (context (org-element-context element)))
    (pcase (org-element-type context)
      ((or `quote-block `verse-block `comment-block
           `paragraph `headline `property-drawer
           `plain-list `item 'drawer 'link)
       (org-edit-indirect-generic-block element))
      (_ (org-edit-special arg)))))

(defun org-edit-indirect--before-commit ()
  "Prevent edit-indirect from chewing up EOF.

Without this, edit-indirect would chew up the EOF, causing
#+end_quote to be appended to the previous line, breaking the
structure of the block.

This is added to `edit-indirect-before-commit-hook' by
`org-edit-indirect-mode'."
  (when (edit-indirect-buffer-indirect-p)
    (goto-char (point-max))
    (forward-char -1)
    (when (not (looking-at "$"))
      (goto-char (point-max))
      (newline))))

;;;###autoload
(define-minor-mode org-edit-indirect-mode
  "Edit any Org block with \\<org-mode-map>\\[org-edit-special]."
  :global nil
  :lighter ""
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map
              [remap org-edit-special] #'org-edit-indirect-special+)
            map)
  (if org-edit-indirect-mode
      (progn
        (add-hook 'edit-indirect-before-commit-hook #'org-edit-indirect--before-commit nil t)
        (add-hook 'edit-indirect-after-creation-hook #'outline-show-all nil t))
    (remove-hook 'edit-indirect-before-commit-hook #'org-edit-indirect--before-commit t)
    (remove-hook 'edit-indirect-after-creation-hook #'outline-show-all t)))


(provide 'org-edit-indirect)

;;; org-edit-indirect.el ends here
