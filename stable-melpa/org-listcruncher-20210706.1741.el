;;; org-listcruncher.el --- Planning tool - Parse Org mode lists into table  -*- lexical-binding: t; -*-

;; Author: Derek Feichtinger <dfeich@gmail.com>
;; Keywords: convenience
;; Package-Version: 20210706.1741
;; Package-Commit: 075e0e6d36eb50406a608bc8a2f0dd359ec63938
;; Package-Requires: ((seq "2.3") (emacs "26.1"))
;; Homepage: https://github.com/dfeich/org-listcruncher
;; Version: 1.4

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;; org-listcruncher is a planning tool that allows the conversion of
;; an Org mode list to an Org table (a list of lists).  The table can
;; be used by other Org tables or Org code blocks for further
;; calculations.
;;
;; Example:
;;
;;   #+NAME: lstTest
;;   - item: item X modified by replacing values (amount: 15, recurrence: 1, end-year: 2020)
;;     - modification of item X (amount: 20)
;;     - another modification of item X (other: 500)
;;       - modification of the modification (other: 299)
;;   - illustrating inheritance (recurrence: 2, end-year: 2024)
;;     - item: item A. Some longer explanation that may run over
;;       multiple lines (amount: 10)
;;     - item: item B (amount: 20)
;;     - item: item C (amount: 30)
;;       - a modification to item C (amount: 25, recurrence: 3)
;;   - item: item Y modified by operations (amount: 50, recurrence: 4, end-year: 2026)
;;     - modification by an operation (amount: +50)
;;     - modification by an operation (amount: *1.5)
;;   - item: item Z entered in scientific format (amount: 1e3, recurrence: 3, end-year: 2025)
;;     - modification by an operation (amount: -1e2)
;; 
;;   We can use org-listcruncher to convert this list into a table
;; 
;;   #+NAME: src-example1
;;   #+BEGIN_SRC elisp :results value :var listname="lstTest" :exports both
;;     (org-listcruncher-to-table listname)
;;   #+END_SRC
;; 
;;   #+RESULTS: src-example1
;;   | description                         | other | amount | recurrence | end-year |
;;   |-------------------------------------+-------+--------+------------+----------|
;;   | item X modified by replacing values |   299 |     20 |          1 |     2020 |
;;   | item A                              |       |     10 |          2 |     2024 |
;;   | item B                              |       |     20 |          2 |     2024 |
;;   | item C                              |       |     25 |          3 |     2024 |
;;   | item Y modified by operations       |       |  150.0 |          4 |     2026 |
;;   | item Z entered in scientific format |       |  900.0 |          3 |     2025 |
;;
;;  The parsing and consolidation functions for producing the table can be modified by
;;  the user.  Please refer to the README and to the documentation strings of the
;;  functions.
;;; Code:
(require 'org)
(require 'cl-lib)
(require 'seq)

(defgroup org-listcruncher nil
  "Parses Org mode lists according to a parsing function and yields an org table structure."
  :group 'org)

(defcustom org-listcruncher-parse-fn #'org-listcruncher-parseitem-default
  "Function used for parsing list items.

The function receives a list item as its single argument.  It must
return a list (OUTP, DESCR, VARLST), where OUTP is a boolean
indicating whether this list item will become a table row, DESCR
is its description string appearing in the table, VARLST is the
list of key/value pairs corresponding to the column name /
values.  Simple example functions for this purpose can be generated
using the `org-listcruncher-mk-parseitem-default' generator
function."
  :group 'org-listcruncher
  :type 'function)

(defcustom org-listcruncher-consolidate-fn #'org-listcruncher-consolidate-default
  "Function for consolidating a sequence of values for a certain key.

The function must accept two arguments: KEY and LIST.  The KEY is
the key selecting the (KEY VALUE) pairs from the given LIST.  The
function must return a single value based on consolidating the
VALUEs from the given key-value pairs.  Refer to the default
function `org-listcruncher-consolidate-default'."
  :group 'org-listcruncher
  :type 'function )

;; TODO: make parentheses definitions a parameter
;;;###autoload
(cl-defun org-listcruncher-mk-parseitem-default (&key (tag "\\*?item:\\*?")
						      (endtag ".")
						      (bra "(")
						      (ket ")"))
  "List item default parsing function generator for org-listcruncher.

This generator can be used to produce a family of parsing
functions with similar structure. It returns a parsing function
that will take a list item line as its only argument.

The generated parsing functions all share the following features.
1. Whether a list item will become a table row is defined by a matching
   TAG at the beginning of the list item. Default is \"item:\" and allowing
   for org bold markers.
2. The row's description is defined by the string following the TAG up to
   a) a character contained in the ENDTAG argument or
   b) the opening parenthesis BRA used for beginning the key/value pairs.
   The default for ENDTAG is \".\".
3. The key/value pairs are separated by commas, and a key is separated from
   its value by a colon key1: val1, key2: val2. The default brackets are
   \"(\" and \")\".

The resulting function can be modified by the following keyword arguments:
- TAG REGEXP defines the REGEXP used for identifying whether a line will become
  a table row.
- ENDTAG STRING: Each character contained in that string will act as a
  terminator for the description of an item.
- The BRA and KET keywords can be used to define strings defining the opening
  and closing parentheses to be used for enclosing the key/value pairs
  The given strings will get regexp quoted."
  (lambda (line)
    (let (outp descr varstr varlst)
      ;; TODO: I should make the expression for the key:val list more restrictive
      (if (string-match
	   (concat
	    "^ *\\(" tag "\\)?" ;; tag
	    " *\\([^" endtag bra "]*\\)" ;; description terminated by endtag or bra
	    "[^" bra "]*" ;; ignore everything until a bracket expression begins
	    ;; key/val pairs
	    "\\\(" (regexp-quote  bra) "\\\(\\\(\\\([^:,)]+\\\):\\\([^,)]+\\\),?\\\)+\\\)"
	    (regexp-quote  ket) "\\\)?")
	   line)
	  (progn
	    (setq outp (if (match-string 1 line) t nil)
		  descr (replace-regexp-in-string " *$" "" (match-string 2 line))
		  varstr (match-string 4 line))))
      (when varstr
	(setq varlst
	      (cl-loop for elem in (split-string varstr ", *")
		       if (string-match "\\([^:]+\\): *\\(.*\\)" elem)
		       collect (list (match-string 1 elem)
                                     (match-string 2 elem)) into result
		       finally return result)))
      (list outp descr varlst))))


(defun org-listcruncher-parseitem-default (line)
  "List item default parsing function for org-listcruncher.

Parses the given list item LINE."
  (funcall (org-listcruncher-mk-parseitem-default) line))

(defun org-listcruncher--calc-orgtable (tbl)
  "Aligns and calculates table functions of the given org table.

The table given in TBL will be processed using the standard
org mode `org-table-align' and `org-table-recalculate' functions.
The resulting table is returned in a string."
  (with-temp-buffer
    (erase-buffer)
    (insert tbl)
    (goto-char (point-min))
    (org-mode)
    (while
        (search-forward-regexp org-table-any-line-regexp nil t)
      (org-table-align)
      (org-table-recalculate 'iterate)
      (goto-char (org-table-end)))
    (buffer-string)))

(defun org-listcruncher--sparse-to-table (sparselst &optional order)
  "Return list of all unique keys of the list of alists in SPARSELST.

If a list is provided in the ORDER argument, the table columns
will be ordered according to this list.  The list may contain only
a subset of the items.  The remaining columns will be added in the
original order."
  (let* ((keylst
	  ;; list of all unique keys of the list of alists in SPARSELST
	  (cl-loop for alst in sparselst
		   with reslst = nil
		   collect (mapcar (lambda (kvpair) (car kvpair))  alst) into reslst
		   finally return (seq-uniq (apply #'append  reslst))))
	 (orderedlst (append order
			     (cl-loop for elm in order
				      do (setq keylst (delete elm keylst))
				      finally return keylst)))
	 ;; for each key, find var values in each given row in sparselist
	 (rows
	  (cl-loop for alst in sparselst
		   with reslst = nil
		   collect (mapcar (lambda (key)
				     (apply org-listcruncher-consolidate-fn
                                            (list key alst)))
				   orderedlst) into reslst
		   finally return reslst)))
    (if rows
	(append `(,orderedlst) '(hline) rows)
      nil)))


;;;###autoload
(cl-defun org-listcruncher-to-table (listname
				     &key (parsefn org-listcruncher-parse-fn)
				     (order nil)
                                     (formula nil))
  "Return a table structure based on parsing the Org list with name LISTNAME.

Optional keyword arguments: The user may use the PARSEFN
FUNCTION argument to define another parsing function for the list
items.  The ORDER keyword takes a list containing column names as
its argument for defining the output table's desired columns
order. The list may contain only a subset of the items.  The
remaining columns will be added in the original order.

If FORMULA is non-nil the given Calc formula will be calculated
by org spreadsheet functions (what usually would follow the
#+TBLFM: in an org spreadsheet table). The result is no longer a
Lisp table structure but a string containing the fully formatted
table."
  (let* ((lst
	  (save-excursion
	    (goto-char (point-min))
	    (unless (search-forward-regexp (concat  "^[ \t]*#\\\+NAME: .*" listname) nil t)
	      (error "No list of this name found: %s" listname))
	    (forward-line 1)
	    (org-list-to-lisp)))
         (tbl
          (org-listcruncher--sparse-to-table
           (cadr (org-listcruncher--parselist lst parsefn nil nil))
           order)))
    (if formula
        (org-listcruncher--calc-orgtable
         (orgtbl-to-orgtbl (append tbl '(hline ("")))
                           `(:tend ,(concat "#+TBLFM: " formula))))
      tbl)))

(defun org-listcruncher--parselist (lst parsefn inheritvars resultlst)
  "Parse an org list into a table structure.

LST is a list as produced from `org-list-to-lisp'.  PARSEFN is the
parsing function for the list items.  INHERITVARS is an
association list of (varname value) pairs that constitute the
inherited variable values from the parent.  RESULTLST contains the
current result structure in form of a list of association
lists.  Each contained association list corresponds to a later
table row."
  (let ((ltype (car lst))
	(itemstructs (cdr lst))
	retvarlst)
    (setq retvarlst
	  (cl-loop for struct in itemstructs
		   with joinedsubvarlst = nil
		   do (let ((itemtext (car struct))
			    (sublist (cadr struct))
			    itemvarlst subtreevarlst outvarlst)
			;; parse this item
			(let* ((prsitem (apply parsefn `(,itemtext)))
			       (outp (car prsitem))
			       (descr (nth 1 prsitem))
			       (itemvarlst (nth 2 prsitem)))
			  ;; (princ (format "DEBUG: item [%s] varlst: %s\n" descr itemvarlst))
			  ;; if item has a sublist, recurse with this sublist and get varlst of this tree
			  (when sublist
			    (let ((parseresult (org-listcruncher--parselist sublist
									    parsefn
									    (append itemvarlst inheritvars)
									    resultlst)))
			      (setq subtreevarlst (car parseresult))
			      (setq resultlst (cadr parseresult)))
			    ;;(princ (format "DEBUG: received subtreevarlst %s\n" subtreevarlst))
			    )
			  ;; only prepare an output line if this item is flagged as an output item
			  (when outp
			    ;; the current item's description always is placed first in the list
			    (setq outvarlst (append `(("description" ,descr)) subtreevarlst itemvarlst inheritvars))
			    (setq resultlst (append resultlst (list outvarlst))))
			  ;; accumulate all item's varlists for returning to parent item
			  (setq joinedsubvarlst (append subtreevarlst itemvarlst joinedsubvarlst))))
		   ;; we return the consolidated varlst of this tree
		   finally return joinedsubvarlst))
    (list retvarlst resultlst)))

(defun org-listcruncher-consolidate-default (key lst)
  "Return consolidated value for KEY out of the list LST of key-value pairs.

The list is given in reverse order (stack), i.e. the newest item
is at the beginning.

Example list:\n '((\"key\" \"+=10\") (\"key\" \"50\") (\"otherkey\"
\"hello\"))

When calling the function on this list with the KEY
argument set to \"key\" it will return 60."
  (let* ((values (cl-loop for kv in lst
			  if (equal key (car kv))
			  collect (cadr kv) into reslst
			  finally return (nreverse reslst)))
	 (result (pop values)))
    (cl-loop for v in values
    	     if (string-match "^\\\([+/*]=?\\\|-=\\\)\\\([0-9.]+\\\(e[0-9+]\\\)?\\\)" v)
    	     do (progn
		  (when (eq (type-of result) 'string)
		    (setq result (string-to-number result)))
		  (setq result (apply (pcase (match-string 1 v)
					((or "+=" "+") '+)
					("-=" '-)
					((or "/=" "/") '/)
					((or "*=" "*") '*))
				      (list result
                                            (string-to-number (match-string 2 v))))))
	     else if (string-match "^\\(+\\|-\\)=\\(.*\\)" v)
             do (progn (when (or (integerp result) (floatp result))
                         (setq result (number-to-string result)))
                       (pcase (match-string 1 v)
                         ("+" (setq result (concat result " " (match-string 2 v))))
                         ("-" (setq result
                                    (mapconcat
                                     'identity
                                     (remove (match-string 2 v) (split-string result " "))
                                     " ")))))
             else
             do (setq result v))
    (or result "")))


;;;###autoload
(cl-defun org-listcruncher-get-field (listname row col &key (parsefn org-listcruncher-parse-fn))
  "Return field defined by ROW,COL from the table derived from LISTNAME.

The given list with LISTNAME is parsed by listcruncher to obtain a table.
The field is defined by the two strings for ROW and COL, where the ROW string
corresponds to the contents of the item's \"description\" column and the COL
string corresponds to the column's name."
  (let* ((tbl (org-listcruncher-to-table listname :parsefn parsefn))
	 (colnames (car tbl))
	 (colidx (cl-position col colnames :test #'equal)))
    (nth colidx (assoc row tbl))))

(provide 'org-listcruncher)
;;; org-listcruncher.el ends here
