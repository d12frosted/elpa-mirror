;;; orgtbl-join.el --- Join columns from another Org Mode table -*- lexical-binding: t;-*-

;; Copyright (C) 2014-2023  Thierry Banel

;; Author: Thierry Banel tbanelwebmin at free dot fr
;; Contributors:
;; Version: 0.1
;; Package-Version: 20230124.1107
;; Package-Commit: 0ca816bc0bb316b91aad5725900a641eef1b9a9a
;; Keywords: data, extensions
;; Package-Requires: ((emacs "24.3"))
;; URL: https://github.com/tbanel/orgtbljoin/blob/master/README.org

;; orgtbl-join is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; orgtbl-join is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; A master table is enriched with columns coming from a reference
;; table.
;;
;; We want to enrich this table:
;; | type     | quty |
;; |----------+------|
;; | onion    |   70 |
;; | tomato   |  120 |
;; | eggplant |  300 |
;; | tofu     |  100 |
;;
;; We have a reference table:
;; | type     | Fiber | Sugar | Protein | Carb |
;; |----------+-------+-------+---------+------|
;; | eggplant |   2.5 |   3.2 |     0.8 |  8.6 |
;; | tomato   |   0.6 |   2.1 |     0.8 |  3.4 |
;; | onion    |   1.3 |   4.4 |     1.3 |  9.0 |
;; | egg      |     0 |  18.3 |    31.9 | 18.3 |
;; | rice     |   0.2 |     0 |     1.5 | 16.0 |
;; | bread    |   0.7 |   0.7 |     3.3 | 16.0 |
;; | orange   |   3.1 |  11.9 |     1.3 | 17.6 |
;; | banana   |   2.1 |   9.9 |     0.9 | 18.5 |
;; | tofu     |   0.7 |   0.5 |     6.6 |  1.4 |
;; | nut      |   2.6 |   1.3 |     4.9 |  7.2 |
;; | corn     |   4.7 |   1.8 |     2.8 | 21.3 |
;;
;; We get the resulting joined table:
;; | type     | quty | Fiber | Sugar | Protein | Carb |
;; |----------+------+-------+-------+---------+------|
;; | onion    |   70 |   1.3 |   4.4 |     1.3 |  9.0 |
;; | tomato   |  120 |   0.6 |   2.1 |     0.8 |  3.4 |
;; | eggplant |  300 |   2.5 |   3.2 |     0.8 |  8.6 |
;; | tofu     |  100 |   0.7 |   0.5 |     6.6 |  1.4 |
;;
;; Full documentation here:
;;   https://github.com/tbanel/orgtbljoin/blob/master/README.org

;;; Requires:
(require 'org)
(require 'org-table)
(eval-when-compile (require 'cl-lib))
(require 'rx)

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; creating long lists in the right order may be done
;; - by (nconc)  but behavior is quadratic
;; - by (cons) (nreverse)
;; a third way involves keeping track of the last cons of the growing list
;; a cons at the head of the list is used for housekeeping
;; the actual list is (cdr ls)

(defsubst orgtbl-join--list-create ()
  "Create an appendable list."
  (let ((x (cons nil nil)))
    (setcar x x)))

(defmacro orgtbl-join--list-append (ls value)
  "Append VALUE at the end of LS in O(1) time."
  `(setcar ,ls (setcdr (car ,ls) (cons ,value nil))))

(defmacro orgtbl-join--list-get (ls)
  "Return the regular Lisp list from LS."
  `(cdr ,ls))

(defmacro orgtbl-join--pop-simple (place)
  "Like (pop PLACE), but without returning (car PLACE)."
  `(setq ,place (cdr ,place)))

(defmacro orgtbl-join--pop-leading-hline (table)
  "Remove leading hlines from TABLE, if any."
  `(while (not (listp (car ,table)))
     (orgtbl-join--pop-simple ,table)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The function (org-table-to-lisp) have been greatly enhanced
;; in Org Mode version 9.4
;; To benefit from this speedup in older versions of Org Mode,
;; this function is copied here with a slightly different name
;; It has also undergone near 2x speedup

(defun orgtbl-join--table-to-lisp-post-9-4 (&optional txt)
  "Convert the table at point to a Lisp structure.

The structure will be a list.  Each item is either the symbol `hline'
for a horizontal separator line, or a list of field values as strings.
The table is taken from the parameter TXT, or from the buffer at point."
  (if txt
      (with-temp-buffer
	(buffer-disable-undo)
        (insert txt)
        (goto-char (point-min))
        (orgtbl-join--table-to-lisp-post-9-4))
    (save-excursion
      (goto-char (org-table-begin))
      (let ((inhibit-changing-match-data t)
	    table row p q)
        (while (progn (skip-chars-forward " \t") (looking-at "|"))
	  (forward-char)
	  (push
	   (if (looking-at "-")
	       'hline
	     (setq row nil)
	     (while (progn (skip-chars-forward " \t") (not (eolp)))
	       (setq q (point))
	       (skip-chars-forward "^|\n")
	       (setq p (if (eolp) (point) (1+ (point))))
	       (skip-chars-backward " \t" q)
	       (push (buffer-substring-no-properties q (point)) row)
	       (goto-char p))
	     (nreverse row))
	   table)
	  (forward-line))
	(nreverse table)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Here is a bunch of useful utilities,
;; generic enough to be detached from the orgtbl-join package.
;; For the time being, they are here.

(defun orgtbl-join--list-local-tables ()
  "Search for available tables in the current file."
  (interactive)
  (let ((tables))
    (save-excursion
      (goto-char (point-min))
      (while (let ((case-fold-search t))
	       (re-search-forward
		(rx bol
		    (* (any " \t")) "#+" (? "tbl") "name:"
		    (* (any " \t")) (group (* not-newline)))
		nil t))
	(push (match-string-no-properties 1) tables)))
    tables))

(defun orgtbl-join--get-distant-table (name-or-id)
  "Find a table in the current buffer named NAME-OR-ID.
Return it as a Lisp list of lists.
An horizontal line is translated as the special symbol `hline'."
  (unless (stringp name-or-id)
    (setq name-or-id (format "%s" name-or-id)))
  (let (buffer loc)
    (save-excursion
      (goto-char (point-min))
      (if (let ((case-fold-search t))
	    (re-search-forward
	     ;; This concat is automatically done by new versions of rx
	     ;; using "literal". This appeared on june 26, 2019
	     ;; For older versions of Emacs, we fallback to concat
	     (concat
	      (rx bol
		  (* (any " \t")) "#+" (? "tbl") "name:"
		  (* (any " \t")))
	      (regexp-quote name-or-id)
	      (rx (* (any " \t"))
		  eol))
	     nil t))
	  (setq buffer (current-buffer)
		loc (match-beginning 0))
	(let ((id-loc (org-id-find name-or-id 'marker)))
	  (unless (and id-loc (markerp id-loc))
	    (error "Can't find remote table \"%s\"" name-or-id))
	  (setq buffer (marker-buffer id-loc)
		loc (marker-position id-loc))
	  (move-marker id-loc nil))))
    (with-current-buffer buffer
      (save-excursion
	(goto-char loc)
	(forward-char 1)
	(unless (and (re-search-forward "^\\(\\*+ \\)\\|[ \t]*|" nil t)
		     (not (match-beginning 1)))
	  (user-error "Cannot find a table at NAME or ID %s" name-or-id))
	(orgtbl-join--table-to-lisp-post-9-4)))))

(defun orgtbl-join--split-string-with-quotes (string)
  "Like (split-string STRING), but with quote protection.
Single and double quotes protect space characters,
and also single quotes protect double quotes
and the other way around."
  (let ((l (length string))
	(start 0)
	(result (orgtbl-join--list-create)))
    (save-match-data
      (while (and (< start l)
		  (string-match
		   (rx
		    (* (any " \f\t\n\r\v"))
		    (group
		     (+ (or
			 (seq ?'  (* (not (any ?')))  ?' )
			 (seq ?\" (* (not (any ?\"))) ?\")
			 (not (any " '\""))))))
		   string start))
	(orgtbl-join--list-append result (match-string 1 string))
	(setq start (match-end 1))))
    (orgtbl-join--list-get result)))

(defun orgtbl-join--colname-to-int (colname table &optional err)
  "Convert the COLNAME into an integer.
COLNAME is a column name of TABLE.
The first column is numbered 1.
COLNAME may be:
- a dollar form, like $5 which is converted to 5
- an alphanumeric name which appears in the column header (if any)
- the special symbol `hline' which is converted into 0
If COLNAME is quoted (single or double quotes),
quotes are removed beforhand.
When COLNAME does not match any actual column,
an error is generated if ERR optional parameter is true
otherwise nil is returned."
  (if (symbolp colname)
      (setq colname (symbol-name colname)))
  (if (string-match
       (rx
	bol
	(or
	 (seq ?'  (group-n 1 (* (not (any ?' )))) ?' )
	 (seq ?\" (group-n 1 (* (not (any ?\")))) ?\"))
	eol)
       colname)
      (setq colname (match-string 1 colname)))
  ;; skip first hlines if any
  (orgtbl-join--pop-leading-hline table)
  (cond ((equal colname "")
	 (and err (user-error "Empty column name")))
	((equal colname "hline")
	 0)
	((string-match "^\\$\\([0-9]+\\)$" colname)
	 (let ((n (string-to-number (match-string 1 colname))))
	   (if (<= n (length (car table)))
	       n
	     (if err
		 (user-error "Column %s outside table" colname)))))
	(t
	 (or
	  (cl-loop
	   for h in (car table)
	   for i from 1
	   thereis (and (equal h colname) i))
	  (and
	   err
	   (user-error "Column %s not found in table" colname))))))

(defun orgtbl-join--insert-make-spaces (n spaces-cache)
  "Make a string of N spaces.
Caches results into SPACES-CACHE to avoid re-allocating
again and again the same string."
  (if (< n (length spaces-cache))
      (or (aref spaces-cache n)
	  (aset spaces-cache n (make-string n ? )))
    (make-string n ? )))

(defun orgtbl-join--insert-elisp-table (table)
  "Insert TABLE in current buffer at point.
TABLE is a list of lists of cells.  The list may contain the
special symbol 'hline to mean an horizontal line."
  (let* ((nbcols (cl-loop
		  for row in table
		  maximize (if (listp row) (length row) 0)))
	 (maxwidths  (make-list nbcols 1))
	 (numbers    (make-list nbcols 0))
	 (non-empty  (make-list nbcols 0))
	 (spaces-cache (make-vector 100 nil)))

    ;; compute maxwidths
    (cl-loop for row in table
	     do
	     (cl-loop for cell on row
		      for mx on maxwidths
		      for nu on numbers
		      for ne on non-empty
		      for cellnp = (car cell)
		      do (cond ((not cellnp)
				(setcar cell (setq cellnp "")))
		       	       ((not (stringp cellnp))
		      		(setcar cell (setq cellnp (format "%s" cellnp)))))
		      if (string-match-p org-table-number-regexp cellnp)
		      do (setcar nu (1+ (car nu)))
		      unless (equal cellnp "")
		      do (setcar ne (1+ (car ne)))
		      if (< (car mx) (string-width cellnp))
		      do (setcar mx (string-width cellnp))))

    ;; change meaning of numbers from quantity of cells with numbers
    ;; to flags saying whether alignment should be left (number alignment)
    (cl-loop for nu on numbers
	     for ne in non-empty
	     do
	     (setcar nu (< (car nu) (* org-table-number-fraction ne))))

    ;; inactivating jit-lock-after-change boosts performance a lot
    (cl-letf (((symbol-function 'jit-lock-after-change) (lambda (_a _b _c)) ))
      ;; insert well padded and aligned cells at current buffer position
      (cl-loop for row in table
	       do
	       ;; time optimization: surprisingly,
	       ;; (insert (concat a b c)) is faster than
	       ;; (insert a b c)
	       (insert
		(mapconcat
		 #'identity
		 (nconc
		  (if (listp row)
		      (cl-loop for cell in row
			       for mx in maxwidths
			       for nu in numbers
			       for pad = (- mx (string-width cell))
			       collect "| "
			       ;; no alignment
			       if (<= pad 0)
			       collect cell
			       ;; left alignment
			       else if nu
			       collect cell and
			       collect (orgtbl-join--insert-make-spaces pad spaces-cache)
			       ;; right alignment
			       else
			       collect (orgtbl-join--insert-make-spaces pad spaces-cache) and
			       collect cell
			       collect " ")
		    (cl-loop for bar = "|" then "+"
			     for mx in maxwidths
			     collect bar
			     collect (make-string (+ mx 2) ?-)))
		  (list "|\n"))
		 ""))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The Org Table Join package really begins here

(defun orgtbl-join--join-query-column (prompt table default)
  "Interactively query a column.
PROMPT is displayed to the user to explain what answer is expected.
TABLE is the Org Mode table from which a column will be choosen
by the user.  Its header is used for column names completion.  If
TABLE has no header, completion is done on generic column names:
$1, $2...
DEFAULT is a proposed column name."
  (orgtbl-join--pop-leading-hline table)
  (let ((completions
	 (if (memq 'hline table) ;; table has a header
	     (car table)
	   (cl-loop ;; table does not have a header
	    for _row in (car table)
	    for i from 1
	    collect (format "$%s" i)))))
    (completing-read
     prompt
     completions
     nil 'confirm
     (and (member default completions) default))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In-place mode

;;;###autoload
(defun orgtbl-join (&optional ref-table ref-column full)
  "Add material from a reference table to the current table.

Optional REF-TABLE is the name of a reference table, in the
current buffer, as given by a #+NAME: name-of-reference
tag above the table.  If not given, it is prompted interactively.

Optional REF-COLUMN is the name of a column in the reference
table, to be compared with the column the point in on.  If not
given, it is prompted interactively.

FULL if given is any of \"mas\" \"ref\" \"mas+ref\" \"none\"
which controls how to deal with rows that are on only one
of the master or reference tables.

Rows from the reference table are appended to rows of the current
table.  For each row of the current table, matching rows from the
reference table are searched and appended.  The matching is
performed by testing for equality of cells in the current column,
and a joining column in the reference table.

If a row in the current table matches several rows in the
reference table, then the current row is duplicated and each copy
is appended with a different reference row.

If no matching row is found in the reference table, then the
current row is kept, with empty cells appended to it."
  (interactive)
  (org-table-check-inside-data-field)
  (let ((col (org-table-current-column))
	(tbl (orgtbl-join--table-to-lisp-post-9-4))
	(pt (line-number-at-pos))
	(cn (- (point) (point-at-bol))))
    (unless ref-table
      (setq ref-table
	    (completing-read
	     "Reference table: "
	     (orgtbl-join--list-local-tables))))
    (setq ref-table (orgtbl-join--get-distant-table ref-table))
    (unless ref-column
      (setq ref-column
	    (orgtbl-join--join-query-column
	     "Reference column: "
	     ref-table
	     (if (memq 'hline tbl) (nth (1- col) (car tbl)) ""))))
    (unless full
      (setq full
	    (completing-read
	     "Which table should appear entirely? "
	     '("mas" "ref" "mas+ref" "none")
	     nil nil "mas")))
    (let ((b (org-table-begin))
	  (e (org-table-end)))
      (save-excursion
	(goto-char e)
	(orgtbl-join--insert-elisp-table
	 (orgtbl-join--create-table-joined
	  tbl
	  (format "$%s" col)
	  ref-table
	  ref-column
	  full
	  nil)))
      (delete-region b e))
    (goto-char (point-min))
    (forward-line (1- pt))
    (forward-char cn)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PULL & PUSH engine

(defun orgtbl-join--join-append-mas-ref-row (masrow refrow refcol)
  "Concatenate master and reference rows, skiping the reference column.
MASROW is a list of cells from the master table.  REFROW is a
list of cells from the reference table.  REFCOL is the position,
numbered from zero, of the column in REFROW that should not be
appended in the result, because it is already present in MASROW."
  (let ((result (orgtbl-join--list-create)))
    (cl-loop for cell in masrow
	     do (orgtbl-join--list-append result cell))
    (cl-loop for cell in refrow
	     for i from 0
	     unless (equal i refcol)
	     do (orgtbl-join--list-append result cell))
    (orgtbl-join--list-get result)))

(defun orgtbl-join--create-table-joined (mastable mascol reftable refcol full cols)
  "Join a master table with a reference table.
MASTABLE is the master table, as a list of lists of cells.
MASCOL is the name of the joining column in the master table.
REFTABLE is the reference table.
REFCOL is the name of the joining column in the reference table.
FULL is a flag to specify whether or not tables should be fully extracted
to the result:
if it contains \"mas\" then the master    table will appear entirely
if it contains \"ref\" then the reference table will appear entirely
if it contains both (like \"mas+ref\") then both table will appear
entirely.
COLS is the list of columns that must appear in the result
if COLS is nil, all columns appear in the result
Returns MASTABLE enriched with material from REFTABLE."
  (unless full (setq full "mas")) ;; default value is "mas"
  (unless (stringp full)
    (setq full (format "%s" full)))
  (let ((result (orgtbl-join--list-create))
	(width
	 (cl-loop for row in mastable
		  maximize (if (listp row) (length row) 0)))
	(refhead)
	(refbody)
	(refhash (make-hash-table :test 'equal)))
    ;; make master table rectangular if not all rows
    ;; share the same number of cells
    (cl-loop for row on mastable
	     if (listp (car row)) do
	     (let ((n (- width (length (car row)))))
	       (if (> n 0)
		   (setcar
		    row
		    (nconc (car row) (make-list n ""))))))
    ;; skip any hline at the top of both tables
    (while (eq (car mastable) 'hline)
      (orgtbl-join--list-append result 'hline)
      (orgtbl-join--pop-simple mastable))
    (orgtbl-join--pop-leading-hline reftable)
    ;; convert column-names to numbers
    (setq mascol (1- (orgtbl-join--colname-to-int mascol mastable t)))
    (setq refcol (1- (orgtbl-join--colname-to-int refcol reftable t)))
    ;; split header and body
    (setq refbody (memq 'hline reftable))
    (if (not refbody)
	(setq refbody reftable)
      (setq refhead reftable)
      ;; terminate header with nil
      (cl-loop for h on reftable
	       until (eq (cadr h) 'hline)
	       finally (setcdr h nil)))
    ;; convert reference table into fast-lookup hashtable
    ;; an entry in the hastable for a key KEY is:
    ;; (0 row1 row2 row3)
    ;; where row1, row2, row3 are rows in the reftable with the KEY column
    ;; the leading 0 will be how many times this particular
    ;; hashtable entry has been consumed
    (cl-loop for row in refbody
	     if (listp row) do
	     (let* ((key (nth refcol row))
		    (hashentry (gethash key refhash)))
	       (if hashentry
		   (nconc hashentry (list row))
		 (puthash key (list 0 row) refhash))))
    ;; iterate over master table header if any
    ;; and join it with reference table header if any
    (if (memq 'hline mastable)
	(while (listp (car mastable))
	  (orgtbl-join--list-append
	   result
	   (orgtbl-join--join-append-mas-ref-row
	    (car mastable)
	    (car refhead) ;; nil if refhead is nil
	    refcol))
	  (orgtbl-join--pop-simple mastable)
	  (if refhead (orgtbl-join--pop-simple refhead))))
    ;; create the joined table
    (cl-loop
     with full-mas = (string-match "mas" full)
     for masrow in mastable
     do
     (if (not (listp masrow))
	 (orgtbl-join--list-append result masrow)
       (let ((hashentry (gethash (nth mascol masrow) refhash)))
	 (if (not hashentry)
	     ;; if no ref-line matches, add the non-matching master-line anyway
	     (if full-mas (orgtbl-join--list-append result masrow ))
	   ;; if several ref-lines match, all of them are considered
	   (cl-loop
	    for refrow in (cdr hashentry)
	    do
	    (orgtbl-join--list-append
	     result
	     (orgtbl-join--join-append-mas-ref-row masrow refrow refcol)))
	   ;; ref-table rows were consumed, increment counter
	   (setcar hashentry (1+ (car hashentry)))))))
    ;; add rows from the ref-table not consumed
    (if (string-match "ref" full)
	(cl-loop
	 for refrow in refbody
	 if (listp refrow) do
	 (let ((hashentry (gethash (nth refcol refrow) refhash)))
	   (if (equal (car hashentry) 0)
	       (let ((fake-masrow (make-list width "")))
		 (setcar (nthcdr mascol fake-masrow)
			 (nth refcol (cadr hashentry)))
		 (orgtbl-join--list-append
		  result
		  (orgtbl-join--join-append-mas-ref-row
		   fake-masrow
		   refrow
		   refcol)))))
	 else do
	 (orgtbl-join--list-append result 'hline)))
    (setq result (orgtbl-join--list-get result))
    (if cols
	(orgtbl-join--join-rearrange-columns result cols))
    result))

(defun orgtbl-join--join-rearrange-columns (table cols)
  "Rearrange the joined TABLE to select columns.
COLS contains a user-specified list of columns as given
in the :cols parameter.  This function rearranges
TABLE so that it contains only COLS, in the same order."
  (if (stringp cols)
      (setq cols (orgtbl-join--split-string-with-quotes cols)))
  (setq cols
	(cl-loop
	 for c in cols
	 collect (1- (orgtbl-join--colname-to-int c table t))))
  (cl-loop
   for rrow on table
   for row = (car rrow)
   if (listp row)
   do (setcar
       rrow
       (cl-loop
	for c in cols
	collect (nth c row))))
  table)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUSH mode

;;;###autoload
(defun orgtbl-to-joined-table (table params)
  "Enrich the master TABLE with lines from a reference table.

PARAMS contains pairs of key-value with the following keys:

:ref-table   the reference table.
             Lines from the reference table will be added to the
             master table.

:mas-column  the master joining column.
             This column names one of the master table columns.

:ref-column  the reference joining column.
             This column names one of the reference table columns.

Columns names are either found in the header of the table, if the
table has a header, or a dollar form: $1, $2, and so on.

The destination must be specified somewhere in the
same file with a bloc like this:
#+BEGIN RECEIVE ORGTBL destination_table_name
#+END RECEIVE ORGTBL destination_table_name

Note:
 The name `orgtbl-to-joined-table' follows the Org Mode standard
 with functions like `orgtbl-to-csv', `orgtbl-to-html'..."
  (interactive)
  (let ((joined-table
	 (orgtbl-join--create-table-joined
	  table
	  (plist-get params :mas-column)
	  (orgtbl-join--get-distant-table (plist-get params :ref-table))
	  (plist-get params :ref-column)
	  (plist-get params :full)
	  (plist-get params :cols))))
    (with-temp-buffer
      (orgtbl-join--insert-elisp-table joined-table)
      (buffer-substring-no-properties (point-min) (1- (point-max))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PULL mode

;;;###autoload
(defun orgtbl-join-insert-dblock-join ()
  "Wizard to interactively insert a joined table as a dynamic block."
  (interactive)
  (let* ((localtables (orgtbl-join--list-local-tables))
	 (mastable
	  (completing-read
	   "Master table: "
	   localtables))
	 (mascol
	  (orgtbl-join--join-query-column
	   "Master joining column: "
	   (orgtbl-join--get-distant-table mastable)
	   ""))
	 (reftable
	  (completing-read
	   "Reference table: "
	   localtables))
	 (refcol
	  (orgtbl-join--join-query-column
	   "Reference joining column: "
	   (orgtbl-join--get-distant-table reftable)
	   mascol))
	 (full (completing-read
		"Which table should appear entirely? "
		'("mas" "ref" "mas+ref" "none")
		nil nil "mas")))
    (org-create-dblock
     (list :name "join"
	   :mas-table mastable :mas-column mascol
	   :ref-table reftable :ref-column refcol
	   :full full))
    (org-update-dblock)))

;;;###autoload
(defun org-dblock-write:join (params)
  "Create a joined table out of a master and a reference table.

PARAMS contains pairs of key-value with the following keys:

:mas-table   the master table.
             This table will be copied and enriched with material
             from the reference table.

:ref-table   the reference table.
             Lines from the reference table will be added to the
             master table.

:mas-column  the master joining column.
             This column names one of the master table columns.

:ref-column  the reference joining column.
             This column names one of the reference table columns.

Columns names are either found in the header of the table, if the
table has a header, or a dollar form: $1, $2, and so on.

The
#+BEGIN RECEIVE ORGTBL destination_table_name
#+END RECEIVE ORGTBL destination_table_name"
  (interactive)
  (let ((formula (plist-get params :formula))
	(content (plist-get params :content))
	(tblfm nil))
    (when (and content
	       (let ((case-fold-search t))
		 (string-match
		  (rx bos (* (any " \t")) (group "#+" (? "tbl") "name:" (* not-newline)))
		  content)))
      (insert (match-string 1 content) "\n"))
    (orgtbl-join--insert-elisp-table
     (orgtbl-join--create-table-joined
      (orgtbl-join--get-distant-table (plist-get params :mas-table))
      (plist-get params :mas-column)
      (orgtbl-join--get-distant-table (plist-get params :ref-table))
      (plist-get params :ref-column)
      (plist-get params :full)
      (plist-get params :cols)))
    (delete-char -1) ;; remove trailing \n which Org Mode will add again
    (when (and content
	       (let ((case-fold-search t))
		 (string-match "^[ \t]*\\(#\\+tblfm:.*\\)" content)))
      (setq tblfm (match-string 1 content)))
    (when (stringp formula)
      (if tblfm
	  (unless (string-match (rx-to-string formula) tblfm)
	    (setq tblfm (format "%s::%s" tblfm formula)))
	(setq tblfm (format "#+TBLFM: %s" formula))))
    (when tblfm
      (end-of-line)
      (insert "\n" tblfm)
      (forward-line -1)
      (let ((org-table-formula-create-columns t))
	(condition-case nil
	    (org-table-recalculate 'iterate)
	  (args-out-of-range nil))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; key bindings, menu, wizard

;;;###autoload
(defun orgtbl-join-setup-keybindings ()
  "Setup key binding and menu entry.
This function can be called in your .emacs.  It will add the
\\<org-tbl-menu> & \\[orgtbl-join] key binding for calling the
`orgtbl-join' wizard,
and a menu entry under Tbl > Column > Join with another table."

  (message "Function orgtbl-join-setup-keybindings is obsolete
as of [2023-01-21 Sat]. See:
https://github.com/tbanel/orgtbljoin/blob/master/README.org
or put this in your .emacs:
(use-package orgtbl-join
  :after (org)
  :bind (\"C-c j\" . orgtbl-join)
  :init
  (easy-menu-add-item
   org-tbl-menu '(\"Column\")
   [\"Join with another table\" orgtbl-join (org-at-table-p)]))")

  (declare (obsolete "Look at
https://github.com/tbanel/orgtbljoin/blob/master/README.org
for how to make the key binding and menu binding in .emacs"
                     "[2023-01-21 Sat]"))

  (eval-after-load 'org
    '(progn
       (org-defkey org-mode-map "\C-c\C-xj" 'orgtbl-join)
       (easy-menu-add-item
	org-tbl-menu '("Column")
	["Join with another table" orgtbl-join t]))))

;; Insert a dynamic bloc with the C-c C-x x dispatcher
;;;###autoload
(eval-after-load 'org
  '(when (fboundp 'org-dynamic-block-define)
     (org-dynamic-block-define "join" #'orgtbl-join-insert-dblock-join)))

(provide 'orgtbl-join)
;;; orgtbl-join.el ends here
