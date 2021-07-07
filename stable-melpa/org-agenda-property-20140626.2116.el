;;; org-agenda-property.el --- Display org properties in the agenda buffer.

;; Copyright (C) 2013 Artur Malabarba <bruce.connor.am@gmail.com>

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>
;; URL: http://github.com/Bruce-Connor/org-agenda-property
;; Package-Version: 20140626.2116
;; Package-Commit: 3b469f3e93de0036547f3631cd0366d53f7584c8
;; Version: 1.3.2
;; Package-Requires: ((emacs "24.2"))
;; Keywords: calendar 
;; Separator: -
;; ShortName: org-agenda-property

;;; Commentary:

;; org-agenda-property is a package which displays the properties of
;; an org item beside (or below) the item's title in the agenda
;; buffer. Customize the variable `org-agenda-property-list' to add
;; which properties you which to show.

;;; Instructions:

;; INSTALLATION

;;	If you installed from Melpa, you shouldn't need to do anything
;;	else. Just customize `org-agenda-property-list' and call your
;;	agenda buffer (tipically `org-agenda-list') to see the magic.

;;      If you installed manually, just make sure it's in your
;;      load-path and call
;;		(require 'org-agenda-property)

;; Variables
;; 
;; 	All variables can be edited by running
;; 	`org-agenda-property-customize' (seriously, chech it out, they
;; 	are just a few :-)). The documentations are mostly self
;; 	explanatory, I list here only the most important two.

;;	`org-agenda-property-list'
;;              This should be a list of all properties you want
;;              displayed in the buffer. Default is "LOCATION".

;; 	`org-agenda-property-position'
;; 		This is where you want the properties to be displayed
;; 		(besides the title or below the title?).

;;; License:

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 

;;; Change Log:
;; 1.3.1 - 20130707 - Fixed some mentions to the wrong package.
;; 1.3 - 20130522 - Fixed bug.
;; 1.2 - 20130521 - Renamed function. More robust hook.
;; 1.1 - 20130521 - Fixed some Warnings.
;; 1.1 - 20130521 - Added requirements.
;; 1 - 20130521 - Released.

;;; Code:

(require 'org-agenda)

(defconst org-agenda-property-version "1.3.2"
  "Version string of the `org-agenda-property' package.")
(defconst org-agenda-property-version-int 6
  "Integer version number of the `org-agenda-property' package (for comparing versions).")

(defun org-agenda-property-bug-report ()
  "Opens github issues page in a web browser.
Please send me any bugs you find, and please inclue your emacs and your package versions."
  (interactive)
  (browse-url "https://github.com/Bruce-Connor/org-agenda-property/issues/new")
  (message "Your org-agenda-property-version is: %s, and your emacs version is: %s.\nPlease include this in your report!"
           org-agenda-property-version emacs-version))

(defun org-agenda-property-customize ()
  "Open the customization menu the `org-agenda-property' group."
  (interactive)
  (customize-group 'org-agenda-property t))

(defcustom org-agenda-property-list '("LOCATION")
  "List of properties to be displayed in the agenda buffer."
  :type '(list string)
   :group 'org-agenda-property)

(defcustom org-agenda-property-separator "|"
  "The separator used when several properties are found."
  :type 'string
   :group 'org-agenda-property)

(defcustom org-agenda-property-column 60
  "Minimum column in which to insert in-line locations in agenda view."
  :type 'integer
   :group 'org-mode-property)

(defcustom org-agenda-property-position 'where-it-fits
  "Where the properties will be placed in the agenda buffer.

'same-line means in the same line as the item it belongs to,
starting at `org-agenda-property-column'. 'next-line means on the
next-line. 'where-it-fits means 'same-line if it fits in the
window, otherwise 'next-line."
  :type 'symbol
   :group 'org-agenda-property)

(defface org-agenda-property-face
  '((t :inherit font-lock-comment-face ))
  "Face used for the properties string."
  :group 'org-agenda-property)

;;;###autoload
(defun org-agenda-property-add-properties ()
  "Append locations to agenda view.
Uses `org-agenda-locations-column'."
  (goto-char (point-min))
  (while (not (eobp))
    (forward-line 1)
    ;; Only do anything if this is a line with an item
    (when (org-get-at-bol 'org-marker)
      ;; Move past the file name.
      (search-forward-regexp " +" (line-end-position) t 2)
      ;; Move to the title.
      (if (looking-at "\\(.[0-9]:[0-9][0-9][^ ][^ ][^ ][^ ][^ ][^ ]\\|Sched\.[0-9]+x:\\)")
          (search-forward-regexp " +" (line-end-position) t 1)
        (if (looking-at "In *[0-9]+ *[a-z]\.:")
            (search-forward-regexp " +" (line-end-position) t 3)))
      ;; Get properties and insert.
      (let* ((this-marker (org-get-at-bol 'org-marker))
             (loc (org-agenda-property-create-string this-marker))
             (col (+ (current-column) (if (looking-at "Scheduled:") 11 -1)))
             (prop (text-properties-at (point)))
             indentedLocation)
        ;; If this item doesn't containi any of the properties, loc will be nil.
        (when loc
          (end-of-line)
          ;; Decide where to put the properties string.
          (if (or (eq org-agenda-property-position 'next-line)
                  (and (eq org-agenda-property-position 'where-it-fits)
                       (> (+ 3 (max org-agenda-property-column (current-column)) (length loc)) (window-width))))
              (progn
                (setq indentedLocation (concat "\n" (make-string col ?\ ) loc)) 
                (set-text-properties 0 (length indentedLocation) prop indentedLocation)
                (add-text-properties 0 (length indentedLocation) '(face font-lock-comment-face) indentedLocation)
                (insert indentedLocation))
            (setq loc (concat (make-string (max 0 (- org-agenda-property-column (current-column))) ?\ ) loc))
            (set-text-properties 0 (length loc) prop loc)
            (add-text-properties 0 (length loc) '(face font-lock-comment-face) loc)
            (insert loc)))))))

(defun org-agenda-property-create-string (marker)
  "Creates a string of properties to be inserted in the agenda buffer."
  (let ((out " [")
        (first t))
    (dolist (cur org-agenda-property-list)
      (let ((prop (org-entry-get marker cur 'selective)))
        (when prop
          (setq out (if first (concat out prop)
                      (concat out org-agenda-property-separator prop)))
          (setq first nil))))
    (if first nil
      (concat out "]"))))

;;;###autoload
(eval-after-load 'org-agenda
  '(if (boundp 'org-agenda-finalize-hook)
       (add-hook 'org-agenda-finalize-hook 'org-agenda-property-add-properties)
     (add-hook 'org-finalize-agenda-hook 'org-agenda-property-add-properties)))

;;;###autoload
(if (boundp 'org-agenda-finalize-hook)
    (add-hook 'org-agenda-finalize-hook 'org-agenda-property-add-properties)
  (when (boundp 'org-finalize-agenda-hook)
    (add-hook 'org-finalize-agenda-hook 'org-agenda-property-add-properties)))

(provide 'org-agenda-property)
;;; org-agenda-property.el ends here
