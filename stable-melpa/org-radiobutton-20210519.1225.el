;;; org-radiobutton.el --- Radiobutton for org-mode lists. -*- lexical-binding: t -*-

;; Copyright (C) 2018 Matúš Goljer

;; Author: Matúš Goljer <matus.goljer@gmail.com>
;; Maintainer: Matúš Goljer <matus.goljer@gmail.com>
;; Version: 0.0.1
;; Package-Version: 20210519.1225
;; Package-Commit: 4ba26bbd26102c45c234bc6ce9a8e9c655c6a0a2
;; Created: 10th March 2018
;; Package-requires: ((dash "2.13.0") (emacs "24"))
;; Keywords: outlines
;; URL: https://github.com/Fuco1/org-radiobutton

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Radiobuttons are groups of options where exactly one option has to
;; be selected at all times.

;; Org mode checkbox lists allow selecting from a list of candidates
;; but the user would have to manually ensure the radiobutton
;; property.

;; This package provides a convenient minor mode that will make sure
;; the property is satisfied for lists which are marked as radiobutton
;; lists.

;;; Code:

(require 'dash)
(require 'org-element)

(defgroup org-radiobutton ()
  "Radiobutton for org-mode lists."
  :group 'org-plain-lists)

(defun org-radiobutton--get-list-at-point (&optional point)
  "Get `org-element' representation of plain-list at POINT.

POINT defaults to current point."
  (setq point (or point (point)))
  (save-excursion
    (goto-char point)
    (let ((parent (org-element-context)))
      ;; first find the first list parent
      (while (and parent
                  (not (eq (org-element-type parent) 'plain-list)))
        (setq parent (org-element-property :parent parent)))
      ;; then we want to go to the containing top-level list so we
      ;; skip items and plain-lists until there's either no parent or
      ;; one of different type
      (while (and parent
                  (memq (org-element-type (org-element-property :parent parent))
                        (list 'plain-list 'item)))
        (setq parent (org-element-property :parent parent)))
      parent)))

(defun org-radiobutton--ensure-radio-property ()
  "Hook that ensures radiobutton property on a list.

The radiobutton property is the following two rules:

- some checkbox is always selected,
- only one checkbox is selected at a time."
  (let ((list (org-radiobutton--get-list-at-point)))
    (when (-contains? (org-element-property :attr_org list) ":radio")
      (save-excursion
        (--each (org-element-property :structure list)
          (goto-char (car it))
          (when (re-search-forward "\\[X\\]" (line-end-position) t)
            (replace-match "[ ]"))))
      (save-excursion
        (beginning-of-line)
        (when (re-search-forward "\\[ \\]" (line-end-position) t)
          (replace-match "[X]"))))))

(defun org-radiobutton--get-plain-list (name)
  "Get the org-element representation of a plain-list with NAME."
  (catch 'found
    (org-element-map (org-element-parse-buffer) 'plain-list
      (lambda (plain-list)
        (when (equal name (org-element-property :name plain-list))
          (throw 'found plain-list))))))

(defun org-radiobutton--get-checked-value (structure &optional with-description)
  "Return the value of the first checked item in an org list.

STRUCTURE is the `org-element' structure representation of a list.

If WITH-DESCRIPTION is non-nil also return the description part
of the item (the part at the beginning separated by ::)."
  (let ((selected (--first (equal (nth 4 it) "[X]") structure)))
    (save-match-data
      (let ((item (buffer-substring (car selected) (-last-item selected))))
        (string-match "\\[X\\] \\(.* :: \\)?\\(.*\\)$" item)
        (if with-description
            (concat (match-string 1 item) (match-string 2 item))
          (match-string 2 item))))))

(defun org-radiobutton-value (&optional name with-description)
  "Return the value of a radiobutton list with NAME.

If NAME is nil default to the list at point if there is any.

If WITH-DESCRIPTION is non-nil also return the description part
of the item (the part at the beginning separated by ::)."
  (-when-let (structure (org-element-property :structure
                          (if name (org-radiobutton--get-plain-list name)
                            (org-radiobutton--get-list-at-point))))
    (org-radiobutton--get-checked-value structure with-description)))

(defun org-radiobutton--read-radio-list (orig-fun element)
  (if (and (eq (org-element-type element) 'plain-list)
           (member ":radio" (org-element-property :attr_org element)))
      (org-radiobutton--get-checked-value (org-element-property :structure element))
    (funcall orig-fun element)))

(advice-add 'org-babel-read-element :around #'org-radiobutton--read-radio-list)

(defun org-radiobutton--enable ()
  "Enable checking of radiobutton property in current buffer."
  (add-hook 'org-checkbox-statistics-hook
            'org-radiobutton--ensure-radio-property
            nil 'local))

(defun org-radiobutton--disable ()
  "Disable checking of radiobutton property in current buffer."
  (remove-hook 'org-checkbox-statistics-hook
               'org-radiobutton--ensure-radio-property
               'local))

;;;###autoload
(define-minor-mode org-radiobutton-mode
  "Minor mode that ensures radiobutton property on radio lists.

A radio list is an org mode list with a :radio attribute.  To
specify the attribute use the #+attr_org: cookie above the list,
for example:

#+attr_org: :radio
#+name: service-to-query
- [X] staging
- [ ] production

Hitting C-c C-c on such a list will deselect the current
selection and select the one under the cursor.  This can be used
as input for other org source blocks, for example:

#+BEGIN_SRC elisp :var service=(org-radiobutton-value \"service-to-query\")
(format \"Will query the %s database\" service)
#+END_SRC

#+RESULTS:
: Will query the staging database"
  :init-value nil
  :group 'org-radiobutton
  (if org-radiobutton-mode
      (org-radiobutton--enable)
    (org-radiobutton--disable)))

;;;###autoload
(define-globalized-minor-mode global-org-radiobutton-mode
  org-radiobutton-mode turn-on-org-radiobutton-mode-if-desired
  :group 'org-radiobutton)

(defun turn-on-org-radiobutton-mode-if-desired ()
  (when (eq major-mode 'org-mode)
    (org-radiobutton-mode 1)))

(provide 'org-radiobutton)
;;; org-radiobutton.el ends here
