;;; kanban.el --- Parse org-todo headlines to use org-tables as Kanban tables
;;
;; Copyright (C) 2012-2017  Arne Babenhauserheide <arne_bab@web.de>
;;           and 2013 stackeffect

;; Version: 0.2.1
;; Package-Version: 20170418.810
;; Package-Commit: fcf0173ce0144e59de97ba8a7808192620e5f8f4

;; Author: Arne Babenhauserheide <arne_bab@web.de>
;; Keywords: outlines, convenience

;; This file is NOT part of Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA
;;
;;; Commentary:

;; If you have not installed this from a package such as those on
;; Marmalade or MELPA, then save kanban.el to a directory in your
;; load-path and add
;;
;; (require 'kanban)
;;
;; to your Emacs start-up files.
;;
;; Usage:
;;
;; * Zero state Kanban: Directly displaying org-mode todo states as kanban board
;;
;; Use the functions kanban-headers and kanban-zero in TBLFM lines to
;; get your org-mode todo states as kanban table.  Update with C-c C-c
;; on the TBLFM line.
;;
;; Example:
;;
;; |   |   |   |
;; |---+---+---|
;; |   |   |   |
;; |   |   |   |
;; #+TBLFM: @1$1='(kanban-headers)::@2$1..@>$>='(kanban-zero @# $# "TAG" '(list-of-files))
;; 
;; "TAG" and the list of files are optional. To get all tags, use ""
;; or nil. To only show entries from the current file, use 'file
;; instead of '(list-of-files).
;;
;; * Stateful Kanban: Use org-mode to retrieve tasks, but track their state in the Kanban board
;;
;; |   |   |   |
;; |---+---+---|
;; |   |   |   |
;; |   |   |   |
;; #+TBLFM: @1$1='(kanban-headers)::@2$1..@>$1='(kanban-todo @# @2$2..@>$> "TAG" '(list-of-files))
;; "TAG" and the list of files are optional
;;
;; Faster Example with kanban-fill (fills fields into their starting
;; state but does not change them):
;;
;; |   |   |   |
;; |---+---+---|
;; |   |   |   |
;; |   |   |   |
;; #+TBLFM: @2='(kanban-fill "TAG" '(list-of-files))::@1$1='(kanban-headers $#)::
;; "TAG" and the list of files are optional
;;
;; More complex use cases are described in the file sample.org
;; 
;; TODO: kanban-todo sometimes inserts no tasks at all if there are multiple tasks in non-standard states.
;;
;; TODO: bold text in headlines breaks the parser (*bold*).
;; 
;; ChangeLog:
;;
;;  - tip:   cleanup of titles from remote files
;;  - 0.2.1: document usage of "" to get all tags and 'file
;;  - 0.2.0: Finally merge the much faster kanban-fill from stackeffect.
;;           I’m sorry that it took me 3 years to get there.
;;  - 0.1.7: strip keyword from link for org-version >= 9 and
;;           avoid stripping trailing "* .*" in lines
;;  - 0.1.6: defcustom instead of defvar
;;  - 0.1.5: Allow customizing the maximum column width with
;;           kanban-max-column-width
;;  - 0.1.4: Test version to see whether the marmalade upload works.
;; 
;;; Code:

(defcustom kanban-max-column-width 30
  "The maximum width of the columns in the KANBAN table.")

;; Get the defined todo-states from the current org-mode document.
;;;###autoload
(defun kanban-headers (&optional startcolumn)
  "Fill the headers of your table with your org-mode TODO
states. If the table is too narrow, the only the first n TODO
states will be shown, with n as the number of columns in your
table.

Only not already present TODO states will be filled into empty
fields starting from the current column. All columns left of
the current one are left untouched.

Optionally ignore fields in columns left of STARTCOLUMN"
  (let* ((ofc (org-table-get nil nil)) ; remember old field content
     (col (org-table-current-column)) ; and current column
     (startcolumn (or startcolumn col))
     (kwl org-todo-keywords-1)
     kw)
  (while (setq kw (pop kwl)) ; iterate over all TODO states
    (let ((matchcol 0) ; insert kw in this empty column
      (n startcolumn)
      field)
    (while (and matchcol (<= n org-table-current-ncol))
      (if (equal kw (setq field (org-table-get nil n)))
        (setq matchcol nil) ; kw already in column n
      (if (and (= 0 matchcol) (equal "" field))
        (setq matchcol n))) ; remember first empty column
      (setq n (+ 1 n)))
    (when (and matchcol (> matchcol 0))
      (if (= matchcol col) (setq ofc kw))
      (save-excursion
      (org-table-get-field matchcol kw)))))
  ofc))

(defun kanban--todo-links-function (srcfile)
  "Retrieve the current header as org-mode link."
  (let* ((file (buffer-file-name))
         (oe (org-element-at-point))
         (title (org-element-property :title oe))
         (link (org-element-property :CUSTOM_ID oe)))
;     (if (equal file srcfile) (setq file nil))
        ; yes, I can use the row variable. It bleeds over from the
        ; calling function.
    (if file
        (setq file (concat file "::")))
    ; find best target
    (cond
     (link
      (setq link (concat "#" link)))
     ((string-match org-target-regexp title)
      (setq link (match-string 1 title))
      (setq title nil))
     (file
      (setq link title)))
    ; clean up the title
    (when title
      ; first substitute links with their title
      (setq title (replace-regexp-in-string "\\[\\(\\[[^]]+\\]\\)?\\[\\([^]]+\\)\\]\\]" "\\2" title))
      ; then kill off special link relevant characters
      (setq title (replace-regexp-in-string "\\[" "{"
                          (replace-regexp-in-string "\\]" "}" title)))
           ; finally shorten the string to a maximum length of kanban-max-column-width chars
      (setq title (substring title 0 (min kanban-max-column-width (length title)))))
    ; clean up the link
    (when (string-match "[\][]" link)
      (setq link (substring link 1))
      (setq link (regexp-quote link))
      (setq link (replace-regexp-in-string "\\(\\\\\\[\\|]\\|/\\)" "." link))
      (setq link (concat "/\\*.*" link "/"))
      (if (not file) (setq file "file:::")))
    ; limit the length of items for very long paths without title
    (when (and (not title)
               (> (length file) kanban-max-column-width))
      (let* ((fulllink (concat file link))
             ; remove link type prefixes
             (ti (replace-regexp-in-string "^.*://" "" fulllink)))
        (setq title (concat (substring ti 0 (- (/ kanban-max-column-width 2) 2)) "..." (substring ti (- (length ti) (- (/ kanban-max-column-width 2) 1) ) (length ti))))))
    (concat "[[" file link (if title (concat "][" title)) "]]" )))

;; Get TODO of current column from field in row 1
(defun kanban--get-todo-of-current-col ()
  "Get TODO of current column from field in row 1 or nil if
row 1 does not contain a valid TODO"
  (let ((todo (org-table-get 1 nil)))
    (if (member todo org-todo-keywords-1) todo)))

;; Fill the kanban table with tasks with corresponding TODO states from org files
;;;###autoload
(defun kanban-zero (row column &optional match scope)
  "Zero-state Kanban board: This Kanban board just displays all
org-mode headers which have a TODO state in their respective TODO
state. Useful for getting a simple overview of your tasks.

Gets the ROW and COLUMN via TBLFM ($# and @#) and can get a string as MATCH to select only entries with a matching tag, as well as a list of org-mode files as the SCOPE to search for tasks."
  (let*
      ((todo (kanban--get-todo-of-current-col))
       (srcfile (buffer-file-name))
       (elem (and todo (nth (- row 2)
                            (delete nil (org-map-entries
                               '(kanban--todo-links-function srcfile)
                               ; select the TODO state via the matcher: just match the TODO.
                               (if match
                                   (concat match "+TODO=\"" todo "\"")
                                 (concat "+TODO=\"" todo "\""))
                               ; read all agenda files
                               (if scope
                                   scope
                                 'agenda)))))))
    (if (equal elem nil)
        ""
      elem)))

(defun kanban--normalize-whitespace (elem)
"Return ELEM with sequences of spaces reduced to 1 space"
(replace-regexp-in-string "\\W\\W+" " " elem))

(defun kanban--member-of-table (elem &optional skipcol)
"Check if ELEM is in some table field
ignoring all elements of column SKIPCOL.

If SKIPCOL is not set column 1 will be ignored."
(if (org-at-table-p)
  (let ((row 2)
      (skipcol (or skipcol 1))
      col result field)
    (while (and (not result) (<= row (length org-table-dlines)))
    (setq col (if (= 1 skipcol) 2 1))
    (while (and (not result) (<= col org-table-current-ncol))
      (setq field (org-table-get row col))
      (if (and field elem)
      (setq result (or result (equal (kanban--normalize-whitespace elem) (kanban--normalize-whitespace field)))))
      (setq col (1+ col))
      (if (= col skipcol) (setq col (1+ col))))
    (setq row (1+ row)))
    result)))

(defun kanban--max-row-or-hline ()
  "Determine data row just above next hline or last row of current table"
  (if (org-at-table-p)
      (let ((row (org-table-current-dline)))
        (while (and
                (< row (1- (length org-table-dlines)))
                (aref org-table-dlines row)
                (aref org-table-dlines (1+ row))
                (= (1+ (aref org-table-dlines row)) (aref org-table-dlines (1+ row))))
          (setq row (1+ row)))
        row)))

; Fill the first column with TODO items, except if they exist in other cels
;;;###autoload
(defun kanban-todo (row cels &optional match scope)
  "Kanban TODO item grabber. Fills the first column of the kanban
table with org-mode TODO entries, if they are not in another cell
of the table. This allows you to set the state manually and just
use org-mode to supply new TODO entries.

Gets the ROW and all other CELS via TBLFM ($# and @2$2..@>$>) and can get a string as MATCH to select only entries with a matching tag, as well as a list of org-mode files as the SCOPE to search for tasks."
 (let* ((srcfile (buffer-file-name))
        (elem (nth (- row 2) (delete nil
                                   (org-map-entries
                                    (lambda
                                      ()
                                      (let
                                          ((file (buffer-file-name))
                                           (line (filter-buffer-substring (point) (line-end-position)))
                                           (keyword (nth 0 org-todo-keywords-1)))
                                        (if (equal file srcfile) (setq file nil))
                                        (if file
                                            (setq file (concat file "::")))
                                        (let* ((cleanline (nth 1 (split-string line "* ")))
                                               (shortline (substring cleanline
                                                                     (+ (length keyword) 1)
                                                                     (min 40 (length cleanline))))
                                               (clean (if (member " " (split-string
                                                                       (substring shortline
                                                                                  (min 25 (length shortline)))
                                                                       ""))
                                                          (mapconcat 'identity
                                                                     (reverse (rest (reverse
                                                                                     (split-string shortline " "))))
                                                                     " ") shortline)))
                                          (concat "[[" file cleanline "][" clean "]]" ))))
                                    (if match
                                        (concat match "+TODO=\"" (nth 0 org-todo-keywords-1) "\"")
                                      (concat "+TODO=\"" (nth 0 org-todo-keywords-1) "\""))
                                    (if scope
                                        scope
                                      'agenda))))))
   (if
       (or (member elem (list cels)) (equal elem nil))
       " " ; the element exists in another table or is nil: Keep the cel empty
     elem))) ; otherwise use the element.


(defun kanban-fill (&optional match scope)
  "Kanban TODO item grabber. Fills the current row of the kanban
table with org-mode TODO entries, if they are not in another cell
of the table. This allows you to set the state manually and just
use org-mode to supply new TODO entries.

Can get a string as MATCH to select only entries with a matching tag, as well as a list of org-mode files as the SCOPE to search for tasks.

Only not already present TODO states will be filled into empty
fields starting from the current field. All fields above the current
one are left untouched."
  (let* ((ofc (org-table-get nil nil)) ; remember old field content
         (row (org-table-current-dline))
         (startrow row)
         (col (org-table-current-column)) ; and current column
         (srcfile (buffer-file-name))
         (todo (kanban--get-todo-of-current-col))
         (maxrow (kanban--max-row-or-hline))
         (elems (delete nil (org-map-entries
                             '(kanban--todo-links-function srcfile)
                                        ; select the TODO state via the matcher: just match the TODO.
                             (if match
                                 (concat match "+TODO=\"" todo "\"")
                               (concat "+TODO=\"" todo "\""))
                                        ; read all agenda files
                             (if scope
                                 scope
                               'agenda))))
         (elem t))
    (save-excursion
      (while (and elem (<= row maxrow))
        (setq elem (pop elems))
        (while (and elem (kanban--member-of-table elem 0)) 
          (setq elem (pop elems)))
        (while (and elem (<= row maxrow) (not (equal "" (org-table-get row col))))
          (if (= row maxrow)
              (setq elem nil) ; stop search
            (setq row (1+ row)))) ; skip non empty rows
        (when (and elem (equal "" (org-table-get row col)))
          (if (= row startrow) (setq ofc elem))
          (save-excursion
            (if (org-table-goto-line row)
                (org-table-get-field col elem))))))
    (org-table-goto-column col)
    ofc))

;; An example for auto-updating kanban tables from duply.han
;; I use the double-dash to mark this as "private" function
(defun kanban--update-function (&optional kanbanbufferregexp)
  (when (not (stringp kanbanbufferregexp))
      (setq kanbanbufferregexp "k[a-z]+kk.org"))
  (when (and (stringp buffer-file-name)
             (string-match kanbanbufferregexp buffer-file-name)) ;; match files such as kXXkk.org, kYYkk.org etc.
    (save-excursion
      (beginning-of-buffer)
      (while (search-forward "='(kanban-" nil t)
        (org-ctrl-c-ctrl-c)))))

; The following lines activate the auto-updating.

; (run-at-time "3 min" 180 '(lambda () (kanban--update-function)))
;; refreshes kanban table every 3 min after emacs startup.
; (add-hook 'find-file-hook 'kanban--update-function)

(provide 'kanban)
;;; kanban.el ends here
