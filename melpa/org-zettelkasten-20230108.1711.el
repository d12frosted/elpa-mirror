;;; org-zettelkasten.el --- A Zettelkasten mode leveraging Org  -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2023  Yann Herklotz
;;
;; Author: Yann Herklotz <yann@ymhg.org>
;; Maintainer: Yann Herklotz <yann@ymhg.org>
;; Keywords: files, hypermedia, Org, notes
;; Package-Version: 20230108.1711
;; Package-Commit: e13e1d870a9864f1e7f9cedfae5d9632c9554ae1
;; Homepage: https://sr.ht/~ymherklotz/org-zettelkasten
;; Package-Requires: ((emacs "25.1") (org "9.3"))

;; Version: 0.7.0

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; These functions allow for the use of the zettelkasten method in org-mode.
;;
;; It uses the CUSTOM_ID property to store a permanent ID to the note,
;; which are organised in the same fashion as the notes by Luhmann.

;;; Code:

(require 'org)

(defgroup org-zettelkasten nil
  "Helper to work with zettelkasten notes."
  :group 'applications)

(defcustom org-zettelkasten-directory (expand-file-name "~/org-zettelkasten")
  "Main zettelkasten directory."
  :type 'string
  :group 'org-zettelkasten)

(defcustom org-zettelkasten-mapping nil
  "Main zettelkasten directory."
  :type '(alist :key-type (natnum :tag "Value")
                :value-type (string :tag "File name"))
  :group 'org-zettelkasten)

(defcustom org-zettelkasten-prefix [(control ?c) ?y]
  "Prefix key to use for Zettelkasten commands in Zettelkasten minor mode.
The value of this variable is checked as part of loading Zettelkasten mode.
After that, changing the prefix key requires manipulating keymaps."
  :type 'key-sequence
  :group 'org-zettelkasten)

(defun org-zettelkasten-abs-file (file)
  "Return FILE name relative to `org-zettelkasten-directory'."
  (expand-file-name file org-zettelkasten-directory))

(defun org-zettelkasten-prefix (ident)
  "Return the prefix identifier for IDENT.

This function assumes that IDs will start with a number."
  (when (string-match "^\\([0-9]*\\)" ident)
    (string-to-number (match-string 1 ident))))

(defun org-zettelkasten-goto-id (id)
  "Go to an ID automatically."
  (interactive "sID: #")
  (let ((file (alist-get (org-zettelkasten-prefix id)
                         org-zettelkasten-mapping)))
    (org-link-open-from-string
     (concat "[[file:" (org-zettelkasten-abs-file file)
             "::#" id "]]"))))

(defun org-zettelkasten-incr-id (ident)
  "Simple function to increment any IDENT.

This might result in duplicate IDs though."
  (let* ((ident-list (append nil ident nil))
         (last-ident (last ident-list)))
    (setcar last-ident (+ (car last-ident) 1))
    (concat ident-list)))

(defun org-zettelkasten-incr-id-total (ident)
  "A better way to incement numerical IDENT.

This might still result in duplicate IDENTs for an IDENT that
ends with a letter."
  (if (string-match-p "\\(.*[a-z]\\)\\([0-9]+\\)$" ident)
      (progn
        (string-match "\\(.*[a-z]\\)\\([0-9]+\\)$" ident)
        (let ((pre (match-string 1 ident))
              (post (match-string 2 ident)))
          (concat pre (number-to-string (+ 1 (string-to-number post))))))
    (org-zettelkasten-incr-id ident)))

(defun org-zettelkasten-branch-id (ident)
  "Create a branch ID from IDENT."
  (if (string-match-p ".*[0-9]$" ident)
      (concat ident "a")
    (concat ident "1")))

(defun org-zettelkasten-org-zettelkasten-create (incr newheading)
  "Create a new heading according to INCR and NEWHEADING.

INCR: function to increment the ID by.
NEWHEADING: function used to create the heading and set the current
            POINT to it."
  (let* ((current-id (org-entry-get nil "CUSTOM_ID"))
         (next-id (funcall incr current-id)))
    (funcall newheading)
    (org-set-property "CUSTOM_ID" next-id)
    (org-set-property "EXPORT_DATE" (format-time-string (org-time-stamp-format t t)))))

(defun org-zettelkasten-create-next ()
  "Create a heading at the same level as the current one."
  (org-zettelkasten-org-zettelkasten-create
   #'org-zettelkasten-incr-id #'org-insert-heading-after-current))

(defun org-zettelkasten-create-branch ()
  "Create a branching heading at a level lower than the current."
  (org-zettelkasten-org-zettelkasten-create
   #'org-zettelkasten-branch-id
   (lambda ()
     (org-back-to-heading)
     (org-forward-heading-same-level 1 t)
     (org-insert-subheading ""))))

(defun org-zettelkasten-create-dwim ()
  "Create the right type of heading based on current position."
  (interactive)
  (let ((current-point (save-excursion
                         (org-back-to-heading)
                         (point)))
        (next-point (save-excursion
                      (org-forward-heading-same-level 1 t)
                      (point))))
    (if (= current-point next-point)
        (org-zettelkasten-create-next)
      (org-zettelkasten-create-branch))))

(defun org-zettelkasten-update-modified ()
  "Update the modified timestamp, which can be done on save."
  (org-set-property "modified" (format-time-string
                                (org-time-stamp-format t t))))

(defun org-zettelkasten-all-files ()
  "Return all files in the Zettelkasten with full path."
  (mapcar #'org-zettelkasten-abs-file
          (mapcar #'cdr org-zettelkasten-mapping)))

(defun org-zettelkasten-buffer ()
  "Check if the current buffer belongs to the Zettelkasten."
  (member (buffer-file-name) (org-zettelkasten-all-files)))

(defun org-zettelkasten-setup ()
  "Activate `zettelkasten-mode' with hooks.

This function only activates `zettelkasten-mode' in Org.  It also
adds `org-zettelkasten-update-modified' to buffer local
`before-save-hook'."
  (add-hook
   'org-mode-hook
   (lambda ()
     (when (org-zettelkasten-buffer)
       (add-hook 'before-save-hook
                 #'org-zettelkasten-update-modified
                 nil 'local)
       (org-zettelkasten-mode)))))

(defun org-zettelkasten-search-current-id ()
  "Search for references to ID in `org-zettelkasten-directory'."
  (interactive)
  (let ((current-id (org-entry-get nil "CUSTOM_ID")))
    (lgrep (concat "[:[]." current-id "]") "*.org" org-zettelkasten-directory)))

(defun org-zettelkasten-agenda-search-view ()
  "Search for text using Org agenda in Zettelkasten files."
  (interactive)
  (let ((org-agenda-files (org-zettelkasten-all-files)))
    (org-search-view)))

(defvar org-zettelkasten-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "n" #'org-zettelkasten-create-dwim)
    (define-key map (kbd "C-s") #'org-zettelkasten-search-current-id)
    (define-key map "s" #'org-zettelkasten-agenda-search-view)
    (define-key map (kbd "C-g") #'org-zettelkasten-goto-id)
    map))

(defvar org-zettelkasten-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map org-zettelkasten-prefix org-zettelkasten-mode-map)
    map)
  "Keymap used for binding footnote minor mode.")

;;;###autoload
(define-minor-mode org-zettelkasten-mode
  "Enable the keymaps to be used with zettelkasten."
  :lighter " ZK"
  :keymap org-zettelkasten-minor-mode-map)

(provide 'org-zettelkasten)

;;; org-zettelkasten.el ends here
