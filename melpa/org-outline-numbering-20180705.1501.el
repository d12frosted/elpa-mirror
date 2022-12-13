;;; org-outline-numbering.el --- Show outline numbering as overlays in org-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2018

;; Author: Anders Johansson
;; Maintainer: Anders Johansson
;; Created: 2018-02-16
;; Modified: 2018-07-05
;; Version: 0.1
;; URL: https://gitlab.com/andersjohansson/org-outline-numbering
;; Package-Requires: ((emacs "24") (org "8.3") (cl-lib "0.6") (ov "1.0.6"))
;; Keywords: wp, convenience

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

;; This package defines a minor mode that displays an outline
;; numbering as overlays on Org mode headlines. The numbering matches
;; how it would appear when exporting the org file.

;; Activating ‘org-outline-numbering-mode’ displays the numbers and
;; deactivating it clears them. There is no facility for auto-updating
;; but the numbering can be recalculated by calling
;; ‘org-outline-numbering-display’ and cleared by calling
;; ‘org-outline-numbering-clear’.

;; By default trees that are commented, archived, tagged noexport or
;; other similar things that would exclude them from org export don’t
;; get a number to keep consistency with exports. If additional tags
;; are to be excluded from numbering they can be added to
;; ‘org-outline-numbering-ignored-tags’.

;;
;; Adapted from code posted by John Kitchin at:
;; https://emacs.stackexchange.com/a/32422

;;; Code:
(require 'ox)
(require 'cl-lib)
(require 'ov)

(defgroup org-outline-numbering nil
  "Options for the org-outline-numbering library."
  :group 'org)

(defcustom org-outline-numbering-ignored-tags '()
  "List of extra tags for which subtrees will be not be given numbers.
There is no need to add the tags from ‘org-export-exlude-tags’,
the ARCHIVE tag or similar here, since the default export
settings which excludes these are used"
  :type '(repeat string))

(defcustom org-outline-numbering-respect-narrowing nil
  "When non-nil, numbering starts in narrowed buffer.
When nil, parses the entire buffer for consistent numbering."
  :type 'boolean)

(defface org-outline-numbering-face '((t :inherit default))
  "Face for displaying outline numbers in ‘org-mode’")

;;;###autoload
(define-minor-mode org-outline-numbering-mode
  "Minor mode to number ‘org-mode’ headings."
  :init-value nil
  (if org-outline-numbering-mode
      (org-outline-numbering-display)
    (org-outline-numbering-clear)))

;;;###autoload
(defun org-outline-numbering-display ()
  "Put numbered overlays on ‘org-mode’ headings."
  (interactive)
  (save-restriction
    (unless org-outline-numbering-respect-narrowing (widen))
    (cl-loop for (p lv) in
             (let* ((info (org-combine-plists
                           (org-export--get-export-attributes)
		                   (org-export--get-buffer-attributes)
                           (org-export-get-environment)
                           '(:section-numbers t)))
                    (info (plist-put info :exclude-tags
                                     (append
                                      (plist-get info :exclude-tags)
                                      org-outline-numbering-ignored-tags)))
                    (tree (org-element-parse-buffer))
                    numberlist)
               (org-export--prune-tree tree info)
               (setq numberlist
                     (org-export--collect-headline-numbering tree info))
               (cl-loop for hl in numberlist
                        collect (cons
                                 (org-element-property :begin (car hl))
                                 (list (cdr hl)))))
             do
             (let ((ov (make-overlay p (+ (length lv) p))))
               (overlay-put ov 'display
                            (concat (mapconcat 'number-to-string lv ".") ". "))
               (overlay-put ov 'numbered-heading t)
               (overlay-put ov 'face 'org-outline-numbering-face)))))

;;;###autoload
(defun org-outline-numbering-clear ()
  "Clear outline numbering overlays in widened buffer."
  (interactive)
  (save-restriction
    (widen)
    (ov-clear 'numbered-heading)))

(provide 'org-outline-numbering)
;;; org-outline-numbering.el ends here
