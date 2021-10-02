;;; org-zettelkasten.el --- Helper functions to use Zettelkasten in org-mode  -*- lexical-binding: t; -*-

;; Author: Yann Herklotz <yann@ymhg.org>
;; URL: https://github.com/ymherklotz/emacs-zettelkasten
;; Package-Version: 20211002.1132
;; Package-Commit: 4048bf9e1be7ab759696a9541eec8f435359bcf3
;; Version: 0.3.0
;; Package-Requires: ((emacs "24.3") (org "9.0"))
;; Keywords: files, hypermedia, Org, notes

;;; Commentary:

;; These functions allow for the use of the zettelkasten method in org-mode.
;;
;; It uses the CUSTOM_ID property to store a permanent ID to the note,
;; which are organised in the same fashion as the notes by Luhmann.

;;; License:

;; Copyright (C) 2020-2021  Yann Herklotz
;;
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

;;; Code:

(require 'org)

(defgroup org-zettelkasten nil
  "Helper to work with zettelkasten notes."
  :group 'applications)

(defcustom org-zettelkasten-directory (expand-file-name "~/org-zettelkasten")
  "Main zettelkasten directory."
  :type 'string
  :group 'org-zettelkasten)

(defcustom org-zettelkasten-prefix [(control ?c) ?y]
  "Prefix key to use for Zettelkasten commands in Zettelkasten minor mode.
The value of this variable is checked as part of loading Zettelkasten mode.
After that, changing the prefix key requires manipulating keymaps."
  :type 'key-sequence
  :group 'zettelkasten)

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
  "Creat a new heading according to INCR and NEWHEADING.

INCR: function to increment the ID by.
NEWHEADING: function used to create the heading and set the current
            POINT to it."
  (let* ((current-id (org-entry-get nil "CUSTOM_ID"))
         (next-id (funcall incr current-id)))
    (funcall newheading)
    (org-set-property "CUSTOM_ID" next-id)))

(defun org-zettelkasten-create-next ()
  "Create a heading at the same level as the current one."
  (org-zettelkasten-org-zettelkasten-create
   #'org-zettelkasten-incr-id #'org-insert-heading))

(defun org-zettelkasten-create-branch ()
  "Create a branching heading at a level lower than the current."
  (org-zettelkasten-org-zettelkasten-create
   #'org-zettelkasten-branch-id (lambda () (org-insert-subheading ""))))

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

(defvar org-zettelkasten-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "n" #'org-zettelkasten-create-dwim)
    map))

(defvar org-zettelkasten-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map org-zettelkasten-prefix org-zettelkasten-mode-map)
    map)
  "Keymap used for binding footnote minor mode.")

;;;###autoload
(define-minor-mode org-zettelkasten-mode
  "Enable the keymaps to be used with zettelkasten."
  :lighter " org-zettelkasten"
  :keymap org-zettelkasten-minor-mode-map)

(provide 'org-zettelkasten)
;;; org-zettelkasten.el ends here
