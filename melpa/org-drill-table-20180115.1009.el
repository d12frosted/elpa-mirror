;;; org-drill-table.el --- Generate drill cards from org tables

;; Copyright (C) 2014 Chris Barrett

;; Author: Chris Barrett <chris.d.barrett@me.com>
;; Package-Requires: ((s "1.7.0") (dash "2.2.0") (cl-lib "0.3") (org "8.2") (emacs "24.1"))
;; Version: 0.1.1

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Generate drill cards from org tables.

;; org-drill requires individual headlines with the "drill" tag; creating these
;; can be laborious and it is difficult to get an overview of your cards when
;; the buffer is folded.

;; This package provides a command, `org-drill-table-generate', that will
;; generate drill cards based on an org-mode table in the current subtree. The
;; cards will inserted under a new "Cards" heading in the current tree.

;; For example, given the following org headline,

;;    * Vocab
;;    |-----------+---------+----------------|
;;    | English   | Spanish | Example        |
;;    |-----------+---------+----------------|
;;    | Today     | Hoy     | Hoy es domingo |
;;    | Yesterday | Ayer    |                |
;;    | Tomorrow  | Mañana  |                |
;;    |-----------+---------+----------------|

;; invoking `org-drill-table-generate' will generate cards for each table row:

;;    * Vocab
;;    :PROPERTIES:
;;    :DRILL_HEADING:
;;    :DRILL_CARD_TYPE: twosided
;;    :DRILL_INSTRUCTIONS: Translate the following word.
;;    :END:
;;    |-----------+---------+----------------|
;;    | English   | Spanish | Example        |
;;    |-----------+---------+----------------|
;;    | Today     | Hoy     | Hoy es domingo |
;;    | Yesterday | Ayer    |                |
;;    | Tomorrow  | Mañana  |                |
;;    |-----------+---------+----------------|
;;    ** Cards
;;    *** Today                                                          :drill:
;;    :PROPERTIES:
;;    :DRILL_CARD_TYPE: twosided
;;    :END:
;;    Translate the following word.
;;    **** English
;;    Today
;;    **** Spanish
;;    Hoy
;;    **** Example
;;    Hoy es domingo
;;    *** Yesterday                                                      :drill:
;;    :PROPERTIES:
;;    :DRILL_CARD_TYPE: twosided
;;    :END:
;;    Translate the following word.
;;    **** English
;;    Yesterday
;;    **** Spanish
;;    Ayer
;;    *** Tomorrow                                                       :drill:
;;    :PROPERTIES:
;;    :DRILL_CARD_TYPE: twosided
;;    :END:
;;    Translate the following word.
;;    **** English
;;    Tomorrow
;;    **** Spanish
;;    Mañana
;;
;; Note that there are several things happening here:
;;   - Each column in the table is put on its own row if it's non-empty
;;   - Instead of using the DRILL_HEADING property as a generic heading, the first element of each row is used as the heading

;;
;; If instead of using the words from the first column as the headings, you want to use the same string for each heading,
;; (i.e. the old behavior) this can be done by specifying the DRILL_HEADING property
;;
;; `org-drill-table-generate' checks the existing list of cards so it does not
;; add duplicates.

;; This package provides an additional command, `org-drill-table-update', which
;; can be added to `org-ctrl-c-ctrl-c-hook'.

;;; Code:

(require 'dash)
(require 's)
(require 'cl-lib)
(require 'org)
(require 'org-drill nil t)

(defgroup org-drill-table nil
  "Generate drill cards from org tables."
  :group 'org
  :prefix "org-drill-table")

(defcustom org-drill-table-noexport-cards t
  "When non-nil, apply :noexport: tag to generated Cards."
  :group 'org-drill-table
  :type 'boolean)

;; -----------------------------------------------------------------------------

;; Silence byte-compiler warning.
(defvar org-drill-card-type-alist nil)


(cl-defstruct (OrgDrillCard
               (:constructor OrgDrillCard (heading type instructions subheadings)))
  "Defines a card to generate for use with org-drill.

  HEADING is the headline for the card.

  TYPE is a string, which should be one of the valid values of
  DRILL_CARD_TYPE.

  INSTRUCTIONS is a short string describing how to complete this
  card.

  SUBHEADINGS is an alist of (\"header\" . \"body\")."
  heading type instructions subheadings)

(defun org-drill-table--drill-table-rows ()
  "Extract the rows from the table at point.
Return a list of rows, where each row a cons of the column name
and the row value."
  (cl-destructuring-bind
      (header &rest body) (--remove (equal 'hline it) (org-table-to-lisp))
    (->> body
         (--map (-zip-with 'cons header it))
         (--map (-remove (lambda (x) (string= "" (cdr x))) it)))))

(defun org-drill-table--goto-table-in-subtree ()
  "Move to the first table in the current subtree."
  (let ((bound (save-excursion (outline-next-heading) (point))))
    (search-forward-regexp (rx bol "|") bound t)))

(defun org-drill-table--insert-card (card)
  "Insert an OrgDrillCard CARD into the current buffer."
  (insert (OrgDrillCard-heading card))
  (org-set-tags-to ":drill:")
  (goto-char (line-end-position))
  (newline)
  (org-set-property "DRILL_CARD_TYPE" (OrgDrillCard-type card))
  (insert (OrgDrillCard-instructions card))
  ;; Insert subheadings. Create a subheading for the first and use the same
  ;; heading level for the rest.
  (--each (-map-indexed 'cons (OrgDrillCard-subheadings card))
    (cl-destructuring-bind (idx header . value) it
      (if (zerop idx) (org-insert-subheading nil) (org-insert-heading))
      (insert header)
      (newline)
      (insert value))))

(defun org-drill-table--skip-props-and-schedule ()
  "Move past the properties and schedule of the current subtree."
  ;; Properties.
  (-when-let (bounds (org-get-property-block))
    (goto-char (cdr bounds))
    (forward-line))
  ;; Schedule.
  (when (s-matches? "SCHEDULED" (buffer-substring (line-beginning-position)
                                                  (line-end-position)))
    (forward-line))
  ;; Advance point if we're still on an org-heading. This is required because
  ;; if the sub-heading has no properties or scheduled, then point won't move
  (when (org-at-heading-p)
    (forward-line)))

(defun org-drill-table--subtree->card ()
  "Convert an individual drill card at point to an OrgDrillCard."
  (let ((heading (elt (org-heading-components) 4))
        (type (org-entry-get (point) "DRILL_CARD_TYPE")))
    (save-excursion
      (save-restriction
        (org-narrow-to-subtree)
        (org-drill-table--skip-props-and-schedule)

        ;; Instructions are the rest of the text up to the first child.
        (let ((instructions
               (s-trim
                (buffer-substring-no-properties
                 (point)
                 (save-excursion
                   (outline-next-heading)
                   (1- (point)))))))

          ;; Get an alist of headings to content.
          (let (acc)
            (while (outline-next-heading)
              (let ((hd (elt (org-heading-components) 4))
                    (content (save-restriction
                               (org-narrow-to-subtree)
                               (org-drill-table--skip-props-and-schedule)
                               (s-trim (buffer-substring-no-properties (point) (point-max))))))
                (setq acc (cons (cons hd content) acc))))

            (OrgDrillCard heading type instructions (nreverse acc))))))))

(defun org-drill-table--forward-heading-until-at-cards ()
  "Move forward by headings at this level until the Cards heading is found."
  (save-restriction
    (org-narrow-to-subtree)
    (unless (org-at-heading-p) (outline-next-heading))
    (let ((moved? t)
          (cards-heading-pos nil))
      (while (and moved? (not cards-heading-pos))
        (let ((before (point)))
          (org-forward-heading-same-level nil t)
          (setq moved? (/= before (point)))
          (when (s-matches? (rx bol (+ "*") (+ space) "Cards")
                            (buffer-substring (line-beginning-position)
                                              (line-end-position)))
            (setq cards-heading-pos (point)))))

      cards-heading-pos)))

(defun org-drill-table--goto-or-insert-cards-heading ()
  "Move to the Cards heading for the current subtree.
Create the heading if it does not exist."
  (save-restriction
    (org-narrow-to-subtree)
    (let ((subtrees? (save-excursion (outline-next-heading)))
          (found? (org-drill-table--forward-heading-until-at-cards)))
      (unless found?
        (goto-char (point-max))
        (if subtrees? (org-insert-heading) (org-insert-subheading nil))
        (insert "Cards")
        (when org-drill-table-noexport-cards
          (org-set-tags-to ":noexport:"))))
    (goto-char (line-end-position))))

(defun org-drill-table--existing-cards ()
  "Parse the Cards subtree for existing drill cards.
Return a list of OrgDrillCard."
  (save-excursion
    (when (org-drill-table--forward-heading-until-at-cards)
      (save-restriction
        (org-narrow-to-subtree)
        (let (acc)
          (while (outline-next-heading)
            (setq acc (cons (org-drill-table--subtree->card) acc)))
          (nreverse acc))))))

(defun org-drill-table--table->cards (heading type instructions)
  "Convert the drill-table tree at point to a list of OrgDrillCards. "
  (--map (OrgDrillCard
          (if (string= "" heading)
              (cdr (car it)) heading)
          type instructions it)
         (org-drill-table--drill-table-rows)))

(defun org-drill-table--get-or-read-prop (name read-fn)
  "Get the value of property NAME for the headline at point.
If the property is not set, read from the user using READ-FN."
  (or (org-entry-get (point) name)
      (let ((val (funcall read-fn)))
        (org-entry-put (point) name val)
        val)))

;;;###autoload
(defun org-drill-table-generate (heading type instructions)
  "Use a table at the current heading to generate org-drill cards.

HEADING is the title to use for each card.

TYPE is a string, of one of the card types in `org-drill-card-type-alist'.

INSTRUCTIONS is a string describing how to use the card."
  (interactive
   (list
    (org-drill-table--get-or-read-prop
     "DRILL_HEADING" (lambda () (read-string "Card heading: ")))
    (org-drill-table--get-or-read-prop
     "DRILL_CARD_TYPE"
     (lambda ()
       (completing-read "Type: "
                        (-keep 'car org-drill-card-type-alist)
                        nil
                        t
                        "twosided")))
    (org-drill-table--get-or-read-prop
     "DRILL_INSTRUCTIONS" (lambda () (read-string "Card instructions: ")))))

  (unless (org-at-table-p)
    (org-drill-table--goto-table-in-subtree))

  (let* ((cards (org-drill-table--table->cards heading type instructions))
         (existing (org-drill-table--existing-cards))
         (new-cards (-difference cards existing)))
    (save-excursion
      (org-drill-table--goto-or-insert-cards-heading)
      ;; Find only cards that have not been inserted.
      (--each (-map-indexed 'cons new-cards)
        ;; Insert each tree, retaining the current heading level.
        (cl-destructuring-bind (idx . card) it
          (org-insert-subheading nil)
          (unless (zerop idx)
            (org-promote-subtree)
            (org-promote-subtree))

          (org-drill-table--insert-card card))))

    (let ((len (length new-cards)))

      (if (zerop len)
          (when (called-interactively-p nil)
            (message "No new cards to insert"))
        (org-align-all-tags)
        (when (called-interactively-p nil)
          (message "Inserted %s new card%s"
                   len
                   (if (= 1 len) "" "s")))))))

;;;###autoload
(defun org-drill-table-update ()
  "Update an existing org drill table.
Suitable for adding to `org-ctrl-c-ctrl-c-hook'."
  (interactive "*")
  (when (and (org-at-table-p)
             (org-entry-get (point) "DRILL_HEADING"))
    (call-interactively 'org-drill-table-generate)))

;;;###autoload
(defun org-drill-table-update-all ()
  "Call `org-drill-table-update' on each table in the buffer."
  (interactive "*")
  (org-table-map-tables 'org-drill-table-update))

(provide 'org-drill-table)

;;; org-drill-table.el ends here
