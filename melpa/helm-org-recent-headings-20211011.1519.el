;;; helm-org-recent-headings.el --- Helm source for org-recent-headings  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Adam Porter

;; Author: Adam Porter <adam@alphapapa.net>
;; Url: http://github.com/alphapapa/org-recent-headings
;; Package-Version: 20211011.1519
;; Package-Commit: 97418d581ea030f0718794e50b005e9bae44582e
;; Version: 0.2-pre
;; Package-Requires: ((emacs "26.1") (org "9.0.5") (dash "2.18.0") (helm "1.9.4") (org-recent-headings "0.2-pre") (s "1.12.0"))
;; Keywords: hypermedia, outlines, Org

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

;; This package provides a Helm source and command for org-recent-headings.

;;; Code:

;;;; Requirements

(require 'dash)

(require 'helm)
(require 'helm-lib)
(require 'helm-source)

(require 'org-recent-headings)

;;;; Variables

(defvar helm-org-recent-headings-map
  (let ((map (copy-keymap helm-map)))
    (define-key map (kbd "<C-return>") 'helm-org-recent-headings--show-entry-indirect-action)
    map)
  "Keymap for `helm-org-recent-headings-source'.")

(defvar helm-org-recent-headings-source
  (helm-build-sync-source " Recent Org headings"
    :candidates (lambda ()
                  (org-recent-headings--prepare-list)
                  org-recent-headings-list)
    :candidate-number-limit 'helm-org-recent-headings-candidate-number-limit
    :candidate-transformer 'helm-org-recent-headings--truncate-candidates
    ;; FIXME: If `helm-org-recent-headings-map' is changed after this `defvar' is
    ;; evaluated, the keymap used in the source is not changed, which is very confusing
    ;; for users (including myself).  Maybe we should build the source at runtime.
    :keymap helm-org-recent-headings-map
    :action (helm-make-actions
             "Show entry (default function)" 'org-recent-headings--show-entry-default
             "Show entry in real buffer" 'org-recent-headings--show-entry-direct
             "Show entry in indirect buffer" 'org-recent-headings--show-entry-indirect
             "Remove entry" 'helm-org-recent-headings-remove-entries
             "Bookmark heading" 'org-recent-headings--bookmark-entry))
  "Helm source for `org-recent-headings'.")

;;;; Customization

(defgroup helm-org-recent-headings nil
  "Options for `helm-org-recent-headings'."
  :group 'helm-org
  :group 'org-recent-headings)

(define-obsolete-variable-alias 'org-recent-headings-candidate-number-limit
  'helm-org-recent-headings-candidate-number-limit
  "0.2")

(defcustom helm-org-recent-headings-candidate-number-limit 10
  "Number of candidates to display in Helm source."
  :type 'integer)

;;;; Commands

(defun helm-org-recent-headings--show-entry-indirect-action ()
  "Action to call `org-recent-headings--show-entry-indirect' from Helm session keymap."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'org-recent-headings--show-entry-indirect)))

(defun helm-org-recent-headings ()
  "Choose from recent Org headings with Helm."
  (interactive)
  (helm :sources helm-org-recent-headings-source))

;;;; Functions

(defun helm-org-recent-headings--truncate-candidates (candidates)
  "Return CANDIDATES with their DISPLAY string truncated to frame width."
  ;; MAYBE: Can't we just truncate lines in the Helm buffer?
  (cl-loop with width = (- (frame-width) org-recent-headings-truncate-paths-by)
           for entry in candidates
           for display = (org-recent-headings-entry-display entry)
           ;; FIXME: Why using setf here instead of just collecting the result of s-truncate?
           collect (cons (setf display (s-truncate width display))
                         entry)))

(cl-defun helm-org-recent-headings-remove-entries (&rest _ignore)
  "Remove selected/marked candidates from recent headings list."
  (--each (helm-marked-candidates)
    (org-recent-headings--remove-entry it)))

;;;; Footer

(provide 'helm-org-recent-headings)

;;; helm-org-recent-headings.el ends here
