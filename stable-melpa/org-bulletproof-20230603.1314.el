;;; org-bulletproof.el --- Automatic plain list bullet cycling -*- lexical-binding: t; -*-

;; Author: Pontus Andersson <pondersson@gmail.com>
;; Maintainer: Pontus Andersson <pondersson@gmail.com>
;; Homepage: https://github.com/pondersson/org-bulletproof
;; Version: 0.2
;; Package-Version: 20230603.1314
;; Package-Commit: a81c275e2e9d43ba98465df8b41adfd398184fda
;; Package-Requires: ((emacs "27.1"))
;; Keywords: outlines, convenience

;; This program is free software: you can redistribute it and/or modify
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

;; This package adds a minor mode that advices some of Org mode's plain list formatting
;; functions to enable automatic bullet cycling in indented plain lists.  The user only
;; has to choose between unordered and ordered bullets.
;;
;; See README.org in the package repository for more details.

;;; Code:

(require 'org)

(defgroup org-bulletproof nil
  "Automatic plain list bullet cycling."
  :link '(url-link :tag "Homepage" "https://github.com/pondersson/org-bulletproof")
  :link '(emacs-library-link :tag "Library Source" "org-bulletproof.el")
  :group 'org
  :prefix "org-bulletproof-")

(defcustom org-bulletproof-default-unordered-bullet "-"
  "The default bullet used in unordered sublists."
  :type '(choice (const "-") (const "+"))  ;; Avoid "*" as it conflicts with headings
  :group 'org-bulletproof)

(defcustom org-bulletproof-default-ordered-bullet "1)"
  "The default bullet used in ordered sublists."
  :type '(choice (const "1)") (const "1."))
  :group 'org-bulletproof)

(defconst org-bulletproof--cycle-alist
  '(("- " . "+ ")
    ("+ " . "* ")
    ("* " . "- ")
    ("1) " . "1. ")
    ("1. " . "1) "))
  "Alist of unordered and ordered bullet cycles.")

;;;###autoload
(define-minor-mode org-bulletproof-mode
  "Automatic plain list bullet cycling."
  :group 'org-bulletproof
  (when org-bulletproof-mode
    (advice-add #'org-cycle-list-bullet :filter-args #'org-bulletproof--filter)
    (advice-add #'org-list-struct-fix-bul :before #'org-bulletproof--force-bullets)))

;;;###autoload
(define-globalized-minor-mode global-org-bulletproof-mode
  org-bulletproof-mode org-bulletproof--on
  :group 'org-bulletproof)

(defun org-bulletproof--on ()
  "Enable `org-bulletproof-mode' in every Org buffer."
  (when (derived-mode-p #'org-mode)
    (org-bulletproof-mode +1)))

(defun org-bulletproof--filter (&optional which)
  "Toggle current plain list bullet between unordered and ordered.

Pass through the original WHICH argument when `org-bulletproof-mode' is nil."
  (if (and org-bulletproof-mode (org-at-item-p))
      (let* ((struct (org-list-struct))
             (item (org-list-get-item-begin))
             (bullet (org-list-get-bullet item struct))
             (bullet-type (org-bulletproof--get-type bullet))
             (cycled-which (if (equal bullet-type 'unordered)
                               org-bulletproof-default-ordered-bullet
                             org-bulletproof-default-unordered-bullet)))
        ;; Return a list because the `apply' call in the advice expects it
        (list cycled-which))
    which))

(defun org-bulletproof--force-bullets (struct prevs)
  "Force all list bullets according to set rules.

PREVS is the alist of previous items, as returned by
`org-list-prevs-alist'.  This function modifies STRUCT."
  (when org-bulletproof-mode
    ;; Forcing all bullets requires the changed sublist to be fully updated. Because this
    ;; runs before `org-list-struct-fix-bul', all Org mode has done so far is set the
    ;; first bullet of the changed sublist, so propagate that bullet.
    (org-bulletproof--propagate-first-sublist-bullet struct prevs)
    ;; Set each item's bullet according to its relationship with its parent
    (let ((parents (org-list-parents-alist struct)))
      (dolist (item (mapcar #'car struct))
        (org-bulletproof--force-bullet item struct parents)))))

(defun org-bulletproof--propagate-first-sublist-bullet (struct prevs)
  "Set all bullets in the current sublist equal to the first bullet.

PREVS is the alist of previous items, as returned by
`org-list-prevs-alist'.  This function modifies STRUCT."
  (save-excursion
    (beginning-of-line)
    (let* ((sublist-items (org-list-get-all-items (point) struct prevs))
           (first-item (car sublist-items))
           (first-bullet (org-list-get-bullet first-item struct)))
      (dolist (item sublist-items)
        (org-list-set-bullet item struct first-bullet)))))

(defun org-bulletproof--force-bullet (item struct parents)
  "Force ITEM's bullet based on its parent.

PARENTS is the alist of parent items, as returned by
`org-list-parents-alist'.  This function modifies STRUCT."
  (let* ((bullet (org-list-get-bullet item struct))
         (bullet-type (org-bulletproof--get-type bullet))
         (parent (org-list-get-parent item struct parents))
         (parent-bullet (org-list-get-bullet parent struct))
         (parent-bullet-type (when parent-bullet (org-bulletproof--get-type parent-bullet)))
         (forced-bullet
          (if (equal bullet-type parent-bullet-type)
              (cdr (assoc-string parent-bullet org-bulletproof--cycle-alist))
            (if (equal bullet-type 'unordered)
                org-bulletproof-default-unordered-bullet
              org-bulletproof-default-ordered-bullet))))
    (org-list-set-bullet item struct (org-list-bullet-string forced-bullet))))

(defun org-bulletproof--get-type (bullet)
  "Return the type of the BULLET string, either `unordered' or `ordered'."
  (if (string-match-p "[0-9]+" bullet) 'ordered 'unordered))

(provide 'org-bulletproof)

;;; org-bulletproof.el ends here
