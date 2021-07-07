;;; org-transform-tree-table.el --- Transform org-mode tree with properties to a table, and the other way around

;; Copyright © 2014 Johan Lindstrom
;;
;; Author: Johan Lindstrom <buzzwordninja not_this_bit@googlemail.com>
;; URL: https://github.com/jplindstrom/emacs-org-transform-tree-table
;; Package-Version: 20200413.1959
;; Package-Commit: d84e7fb87bf2d5fc2be252500de0cddf20facf4f
;; Version: 0.1.2
;; Package-Requires: ((dash "2.10.0") (s "1.3.0"))
;; Keywords: org-mode table org-table tree csv convert

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

;; This file is not part of GNU Emacs.

;;
;;; Commentary:
;;
;; Transform an org-mode outline and its properties to a table format
;; (org-table, CSV).

;; This makes it possible to have an outline with properties and work
;; with it in column view. Then you can transform the outline to a table
;; to share with others (export to CSV and open in Excel).

;; More about column view:

;; * http://orgmode.org/worg/org-tutorials/org-column-view-tutorial.html
;; * http://orgmode.org/manual/Column-view.html


;;; Usage
;; -----

;; ### From org tree to table

;;     ;; Org outline to an org table
;;     M-x org-transform-tree/org-table-buffer-from-outline

;;     ;; Org outline to CSV (or rather, tab-separated value)
;;     M-x org-transform-tree/csv-table-buffer-from-outline

;; If the region is active, convert that part of the
;; tree. Otherwise, if point is on an org heading, convert that
;; heading and its subtree. Otherwise convert the buffer.

;; In the resulting table, row one is the column titles. The rest of
;; the rows are property values.

;; Column one is the outline heading, and the rest are the
;; properties in the order they first appear in the buffer.

;; However, all special properties (e.g. 'COLUMNS', '*_ALL') are
;; placed after all the user properties (i.e. whatever properties
;; the user has added to capture information).

;; Special values that can't be represented in an org table are escaped:

;;     |                   ==> \vert{}
;;     first leading space ==> non-breaking space (C-x 8 SPC)


;; ### From table to org tree

;;     ;; From an org table to an org outline
;;     M-x org-transform-table/org-tree-buffer-from-org-table

;;     ;; From CSV (tab separated) to an org outline
;;     M-x org-transform-table/org-tree-buffer-from-csv

;; When converting from an org table, point must be on a table.

;; When converting CSV, convert the buffer.

;; Values escaped from any tree->table transformation are unescaped (see above)



;; Tiny example
;; ------------

;; This outline:

;;     * Pages
;;       :PROPERTIES:
;;       :COLUMNS:  %30ITEM %10Access %10Cost
;;       :END:
;;     ** Products
;;        :PROPERTIES:
;;        :Access:   All
;;        :END:
;;     *** Free Widget
;;         :PROPERTIES:
;;         :Access:   All
;;         :END:
;;     *** Paid Thingy
;;         :PROPERTIES:
;;         :Access:   Paid
;;         :Cost:     30
;;         :END:

;; Transforms into:

;;     | Heading         | Access | Cost | COLUMNS                   |
;;     | * Pages         |        |      | %30ITEM %10Access %10Cost |
;;     | ** Products     | All    |      |                           |
;;     | *** Free Widget | All    |      |                           |
;;     | *** Paid Thingy | Paid   |   30 |                           |

;; Note that the special property COLUMNS are out on the right, to be out
;; of the way when the table is being edited in e.g. Excel or Open
;; Office.

;; This also means the transformation is only 99% round-trip safe and the
;; first time you go back to a tree representation, you'll get more diffs
;; than subsequent ones.


;;; Installation
;; ------------

;; Install org-transform-tree-table using MELPA.

;; Or clone the repo into somewhere in the load-path.

;;     git clone https://github.com/jplindstrom/emacs-org-transform-tree-table.git

;; and initialize with:

;;    (require 'org-transform-tree-table)


;;; Changes
;; -------
;;
;; 2014-12-28 - 0.1.3
;;
;; * Transform text below headings
;;
;;
;; 2014-12-26 - 0.1.2
;;
;; * Bug fixes, doc fixes
;; * Toggle between tree and table
;;
;;
;; 2014-12-23 - 0.1.1
;;
;; * Initial release


;;; Contributors
;; ------------
;;
;; * Syohei YOSHIDA - https://github.com/syohex


;;; Code:



(require 'dash)
(require 's)



;; interactive defuns

;;;###autoload
(defun org-transform-tree/org-table-buffer-from-outline ()
  "Transform an org tree to an org-table and return a new buffer
with the table.

If the region is active, convert that part of the
tree. Otherwise, if point is on an org heading, convert that
heading and its subtree. Otherwise convert the buffer.

In the resulting table, row one is the column titles. The rest of
the rows are property values.

Column one is the outline heading, and the rest are the
properties in the order they first appear in the buffer.

However, all special properties (e.g. 'COLUMNS', '*_ALL') are
placed after all the user properties (i.e. whatever properties
the user has added to capture information)."
  (interactive)
  (ott/render-new-buffer-from-rows-cols
   "-table.org"
   (ott/org-tree/parse-rows-cols)
   'ott/org-table/render-rows-cols)
  )

;;;###autoload
(defun org-transform-tree/csv-buffer-from-outline ()
  "Transform an org tree to CSV format and return a new buffer
with the table.

Except it's not comma separated. It's tab separated because with
all (non) 'standard' ways to escape ',' in CSV files... let's not
even go there.

If the region is active, convert that part of the
tree. Otherwise, if point is on an org heading, convert that
heading and its subtree. Otherwise convert the buffer.

In the resulting table, row one is the column titles. The rest of
the rows are property values.

Column one is the outline heading, and the rest are the
properties in the order they first appear in the buffer.

However, all special properties (e.g. 'COLUMNS', '*_ALL') are
placed after all the user properties (i.e. whatever properties
the user has added to capture information)."
  (interactive)
  (ott/render-new-buffer-from-rows-cols
   ".csv"
   (ott/org-tree/parse-rows-cols)
   'ott/csv-table/render-rows-cols)
  )

;;;###autoload
(defun org-transform-table/org-tree-buffer-from-org-table ()
  "Transform the org-table at point to an org-mode outline and
return a new buffer with the new tree.

Raise an error if point isn't on an org-table."
  (interactive)
  (ott/render-new-buffer-from-rows-cols
   "-tree.org"
   (ott/org-table/parse-rows-cols)
   'ott/org-tree/render-rows-cols)
  )

;;;###autoload
(defun org-transform-table/org-tree-buffer-from-csv ()
  "Transform the buffer CSV table to an org-mode outline and
return a new buffer with the new tree."
  (interactive)
  (ott/render-new-buffer-from-rows-cols
   "-tree.csv"
   (ott/csv-table/parse-rows-cols)
   'ott/org-tree/render-rows-cols)
  )

;;;###autoload
(defun org-transform-tree-table/toggle ()
  "Toggle between an outline subtree and an org-table, depending
on what point is placed on."
  (interactive)
  (if (org-at-table-p)
      (ott/tree-table/replace-table-with-tree)
    (if (org-at-heading-p)
        (ott/tree-table/replace-tree-with-table)
      (error "Point isn't on an org heading or in an org table.")
      ))
  )



;; Main

(defun ott/render-new-buffer-from-rows-cols (type rows-cols render-fun)
  "Render ROWS-COLS to a table using RENDER-FUN and return a new
buffer with the table. Name the new buffer after the current
buffer file name and TYPE."
  (let* ((target-buffer
          (get-buffer-create (concat (buffer-name) type)) ;; Use the other one later
          ;; (create-file-buffer (concat (or (buffer-file-name) "new") type))
          ))
    (with-current-buffer target-buffer
      (funcall render-fun rows-cols))

    (switch-to-buffer target-buffer)
    (goto-char (point-min))

    target-buffer
    ))



;; render/parse org tree

(defun ott/org-tree/parse-rows-cols ()
  "Return a list of rows, with a list of columns from the org
tree.

Row one is the column titles.

Column one is the outline heading, and the rest are the
properties as they appear in the buffer.

However, all special properties (e.g. 'COLUMNS', '*_ALL') are
placed after all the user properties (i.e. whatever property
keys/values the user is edi property keys/values the user is
editing."
  (interactive)
  (save-excursion
    (let* (
           (ordered-property-keys
            (ott/org-tree/user-then-special-property-keys
             (ott/org-tree/unique-propery-keys-in-buffer-order)))

           (col-title-values (cons "Heading" ordered-property-keys))

           (row-col-data-values
            (ott/org-tree/row-col-property-values ordered-property-keys))
           )
      (cons
       col-title-values
       row-col-data-values)
      )
    )
  )

(defun ott/org-tree/render-rows-cols (rows-cols)
  "Insert an org-tree with the ROWS-COLS."
  (erase-buffer)
  (org-mode)
  (let* (
         (data-rows-cols (cdr rows-cols))
         (title-row (car rows-cols))
         ;; All but the first item, which is the Heading title col
         (property-title-cols (cdr title-row))
         )

    (dolist (row-cols data-rows-cols)
      (let* (
             (heading-col (car row-cols))
             (property-cols (cdr row-cols))
             )

        ;; Insert heading
        (insert (concat heading-col "\n"))

        ;; Set properties for the heading
        (--zip-with
         (when (and other (not (string= other "")))
           (org-entry-put nil it other)
           )
         property-title-cols
         property-cols)

        (outline-next-heading)
        )
      )
    )
  )

(defun ott/org-tree/row-col-property-values (property-keys)
  "Return list of rows with a list of columns that are property
values for the PROPERTY-KEYS for each tree heading."
  ;; There must be a simpler way to deal with the nested lists
  (let* ((sets-rows-cols
          (ott/org-tree/map-entries
           (lambda ()
             ;;;JPL: refactor
             (let* ((heading-row
                     (cons
                      (ott/org-tree/level-and-heading (org-heading-components)) ; Heading
                      (ott/org-tree/current-property-values-from-keys property-keys)
                      ))
                    (heading-text-rows (ott/org-tree/heading-text-rows property-keys))
                    )
               (cons heading-row heading-text-rows)
               ))))
         (rows-cols (-flatten-n 1 sets-rows-cols)))
    rows-cols
    )
  )

(defun ott/org-tree/heading-text-rows (property-keys)
  "Return rows for each of the current heading text lines, with
columns where the first column is the line text, and the
rest (one for each in property-keys) are nils.

If the heading text is empty, return an empty list."
  (let* ((heading-text (ott/org-tree/heading-text))
         (text-lines (org-split-string heading-text "\n"))
         (rows-cols
          (mapcar
           (lambda (text-line)
             (cons text-line (mapcar (lambda (x) nil) property-keys)))
           text-lines
           ))
         )
    (if (string= heading-text "")  ;; Special case for no text contents
        '()
        rows-cols)
    )
  )

(defun ott/org-tree/heading-text ()
  "Return the text contents of the current heading (the text
beneath the '* Heading' itself), or '' if there isn't one."
  (org-end-of-meta-data t)
  ;; include leading empty lines
  (while (looking-back "[\n ]+\n")
    (backward-char)
    (beginning-of-line))

  (let* ((beg (point))
         (end (if (org-at-heading-p)
                  (point)
                  (save-excursion (outline-next-heading) (point))))
         )
    (buffer-substring-no-properties beg end)
    )
  )

(defun ott/org-tree/active-scope ()
  "Return a scope modifier depending on whether the region is
active, or whether point is on a org heading, or not."
  (if (org-region-active-p) 'region
    (if (org-at-heading-p) 'tree
      nil))) ;; Entire buffer

(defun ott/org-tree/map-entries (fun)
  "Run org-map-entries with FUN in the active scope"
    (org-map-entries fun nil (ott/org-tree/active-scope)))

(defun ott/org-tree/level-and-heading (heading-components)
  "Return the *** level and the heading text of
ORG-HEADING-COMPONENTS"
  (let ((level (nth 1 heading-components))
        (heading-text (nth 4 heading-components)))
    (concat (make-string level ?*) " " heading-text)))

(defun ott/org-tree/current-property-values-from-keys (property-keys)
  "Return list of values (possibly nil) for each property in
PROPERTY-KEYS."
  (let* ((entry-properties (org-entry-properties nil 'standard)))
    (mapcar
     (lambda (key)
       (assoc-default key entry-properties))
     property-keys)))

(defun ott/org-tree/unique-propery-keys-in-buffer-order ()
  "Return list of all unique property keys used in drawers. They
are in the order they appear in the buffer."
  (let* ((entries-keys
          (ott/org-tree/map-entries
           (lambda () (mapcar 'car (org-entry-properties nil 'standard)))))
         (all-keys '())
         )
    (dolist (keys entries-keys)
      (dolist (key (reverse keys)) ;; org-entry-properties returns keys in wrong order
        (add-to-list 'all-keys key t)))

    ;; Not sure why this one appears here. Are there others?
    (-remove (lambda (x) (string= x "CATEGORY")) all-keys)
    )
  )

(defun ott/org-tree/user-then-special-property-keys (property-keys)
  "Return list with items in PROPERTY-KEYS, but where all column
properties are first and all special properties are at the end.

Column properties are properties the user would normally enter.

Special properties are things like 'COLUMNS' or 'Someting_ALL',
which are instructions for org-mode. They should typically go at
the end and not mix with the actual data."
  (-flatten (-separate 'ott/org-tree/is-col-property property-keys)))

(defun ott/org-tree/is-col-property (key)
  "Is KEY a column / user-data level property?"
  (if (string= key "COLUMNS") nil
    (if (string-match "._ALL$" key) nil
      t)))



;; render/parse org table

(defun ott/validate-parsed-rows-cols (rows-cols)
  (let* ((heading-row (car-safe rows-cols))
         (heading-row-col (car-safe heading-row))
         (data-row (cadr rows-cols))
         (data-row-col (car-safe data-row))
         )
    (when (not (string= heading-row-col "Heading"))
      (error "org-transform-tree-table error: First row/col isn't 'Heading'.
This table was probably not an org tree originally."))
    (when (not (string-match "^*\+ \+" (or data-row-col "")))
      (error "org-transform-tree-table error: Second row doesn't start with an org heading level '*'.
This table was probably not an org tree originally."))))

(defun ott/org-table/parse-rows-cols ()
  "Parse the org-table at point and return a list of rows with a
list of cols.

If there isn't an org-table at point, raise an error."
  (when (not (org-at-table-p)) (error "Not in an org table"))
  (let* ((beg (org-table-begin))
         (end (org-table-end))
         (table-text (buffer-substring-no-properties beg end))
         (lines (org-split-string table-text "[ \t]*\n[ \t]*"))
         ;; JPL: ignore horizontal lines
         (rows-cols
          (mapcar
           (lambda (line)
             (mapcar
              'ott/org-table/unescape-value
              (org-split-string (org-trim line) "\\s-*|\\s-*")))
           (--filter
            (not (string-match org-table-hline-regexp it))
            lines)))
         )
    (ott/validate-parsed-rows-cols rows-cols)
    rows-cols))

(defun ott/org-table/render-rows-cols (rows-cols)
  "Insert an org-table with the ROWS-COLS."
    (erase-buffer)
    (org-mode)
    (--each rows-cols
      (ott/org-table/insert-values-as-table-row it))
    (org-table-align)
  )

(defun ott/org-table/insert-values-as-table-row (col-values)
  "Insert escaped COL-VALUES using the org-table format."
  (insert "|")
  (dolist (value col-values)
    (insert (concat " " (ott/org-table/escape-value value) " |"))
    )
  (insert "\n")
  )

(defun ott/org-table/escape-value (value)
  "Return VALUE but suitable to put in a table value. Return an
empty string for nil values."
  (if value
      (replace-regexp-in-string "^ " " " ;; leading space to non-breaking-space
       (replace-regexp-in-string "|" "\\\\vert{}" value))
    ""))

(defun ott/org-table/unescape-value (value)
  "Return VALUE but suitable to use outside of a table value. Return an
empty string for nil values."
  (if value
      (replace-regexp-in-string
       "\\\\vert\\b" "|"
       (replace-regexp-in-string
        "\\\\vert{}" "|"
        (replace-regexp-in-string
         "^ " " " ;; Leading non-breaking-space to space
         value)))
    ""))



;; Render/parse CSV table (tab separated)

(defun ott/csv-table/parse-rows-cols ()
  "Parse the buffer CSV table (tab separated) and return a list
of rows with a list of cols."
  (let* (
         (table-text (buffer-substring-no-properties (point-min) (point-max)))
         (lines (org-split-string table-text "\n"))
         (rows-cols
          (mapcar
           (lambda (line)
             (org-split-string (org-trim line) "\t")
             )
           lines))
         )
    (ott/validate-parsed-rows-cols rows-cols)
    rows-cols))

(defun ott/csv-table/render-rows-cols (rows-cols)
  "Insert a CSV table with the ROWS-COLS."
    (erase-buffer)
    (--each rows-cols
      (ott/csv-table/insert-values-as-table-row it))
  )

(defun ott/csv-table/insert-values-as-table-row (col-values)
  "Insert escaped COL-VALUES using CSV format (tab separated)."
  (insert
   (s-join "\t" (mapcar 'ott/csv-table/escape-value col-values)))
  (insert "\n")
  )

(defun ott/csv-table/escape-value (value)
  "Return VALUE but suitable to put in a CSV file. Return an
empty string for nil values."
  (if value
      value
    ""))



;; Toggle subtree and table

(defun ott/tree-table/replace-table-with-tree ()
  "Replace the current org-table with an org tree."
  (let* (
         (beg (org-table-begin))
         (end (org-table-end))
         (current-buffer (current-buffer))
         (tree-buffer (org-transform-table/org-tree-buffer-from-org-table))
         )
    (switch-to-buffer current-buffer)
    (delete-region beg end)
    (insert (with-current-buffer tree-buffer (buffer-substring (point-min) (point-max))))
    (goto-char beg)
    (kill-buffer tree-buffer)
    )
  )

(defun ott/tree-table/replace-tree-with-table ()
  "Replace the current heading and its subtree with an org-table"
  (let* (
         (region (ott/org-subtree-region))
         (beg (car region))
         (end (cdr region))
         (current-buffer (current-buffer))
         (table-buffer (org-transform-tree/org-table-buffer-from-outline))
         )
    (switch-to-buffer current-buffer)
    (delete-region beg end)
    (insert (with-current-buffer table-buffer (buffer-substring (point-min) (- (point-max) 1))))
    (goto-char beg)
    (kill-buffer table-buffer)
    )
  )

(defun ott/org-subtree-region ()
  "Return cons with (beg . end) of the current subtree"
  (interactive)
  (save-excursion
    (save-match-data
      (org-with-limited-levels
       (cons
        (progn (org-back-to-heading t) (point))
        (progn (org-end-of-subtree t t)
               (if (and (org-at-heading-p) (not (eobp))) (backward-char 1))
               (point)))))))



;; Test

;; (ert-run-tests-interactively "^ott-")

;; (set-buffer "expected-org-table1--tree.org")
;; (org-transform-table/org-tree-buffer-from-org-table)

;; (set-buffer "table1.csv")
;; (org-transform-table/org-tree-buffer-from-csv)

;; (set-buffer "tree1.org")
;; (org-transform-tree/org-table-buffer-from-outline)

;; (set-buffer "tree1.org")
;; (org-transform-tree/csv-buffer-from-outline)




(provide 'org-transform-tree-table)

;;; org-transform-tree-table.el ends here
