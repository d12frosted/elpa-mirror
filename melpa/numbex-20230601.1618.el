;;; numbex.el --- Manage numbered examples -*- lexical-binding: t; -*-

;; Copyright (C) 2021, 2022, 2023 Enrico Flor

;; Author: Enrico Flor <enrico@eflor.net>
;; Maintainer: Enrico Flor <enrico@eflor.net>
;; URL: https://github.com/enricoflor/numbex
;; Package-Version: 20230601.1618
;; Package-Commit: b64f51388726363fc0d154219e2270c6b9c5ce19
;; Version: 0.5.1
;; Package-Requires: ((emacs "26.1"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; numbex.el provides a minor mode that manages numbered examples.
;; Its primary function is to take care for the user of the correct
;; sequential numbering of examples in the buffer.  It also
;; automatically makes sure that references to examples are up to date
;; with the change in the numbering.
;;
;; For explanation as to how to use numbex, check the readme.org file
;; at <https://github.com/enricoflor/numbex>.

;;; Code:

(require 'subr-x)
(require 'outline)

(defvar numbex-mode)

(defgroup numbex nil
  "Automatically number examples and references to them."
  :prefix "numbex-"
  :link '(url-link :tag "Website for numbex"
                   "https://github.com/enricoflor/numbex")
  :group 'convenience)

(defvar-local numbex--total-number-of-items 0
  "Total number of numbex-items in the buffer.")

(defvar-local numbex--automatic-refresh t
  "If t, evaluate 'numbex-refresh' on idle timer and with other commands.
Specifically, with 'numbex-toggle-visibility' and 'numbex-dwim'.  Even
if nil, 'numbex-refresh will be added to 'auto-save-hook' and
'before-save-hook'.")

(defvar-local numbex--hidden-labels t
  "If t, numbex items are hidden under a numerical text property.")

(defcustom numbex-highlight-unlabeled t
  "If t, items that are missing a label are highlighted.
Blank strings (containing only white space) do not count as a
label.  Unlabeled items have the appearance specified by
'font-lock-comment-face'."
  :type 'boolean
  :group 'numbex)

(defcustom numbex-highlight-duplicates t
  "If t, items that have a non unique label are highlighted.
A label is non unique if it not a blank string (it doesn't just
contain white space) and more than one example item in the buffer
use it as a label.  Items with non-unique labels have the
appearance specified by 'font-lock-warning-face'."
  :type 'boolean
  :group 'numbex)

;; There is some redundancy in some of these regexp but it is done for
;; consistency: the first capture group is always the type, the second
;; is always the label of the item.
(defconst numbex--item-re "{\\[\\([pnr]?ex\\):\\(.*?\\)\\]}"
  "Regexp that matches any numbex item (example or reference).")

(defconst numbex--example-re "{\\[\\(ex\\):\\(.*?\\)\\]}"
  "Regexp that matches any numbex example item.")

(defconst numbex--reference-re "{\\[\\([pnr]+ex\\):\\(.*?\\)\\]}"
  "Regexp that matches any numbex reference item.")

(defun numbex--item-at-point ()
  "Return position of the label of the item point is on and its type.
If point is on a numbex item, this function returns a cons cell
whose car is a cons cell with the buffer positions of the first
and last character of the label respectively, and its cdr is a
string corresponding to the type of the item.  Return nil if
point is not on a numbex item.

Thus, when point is on an item:
 - (caar (numbex--item-at-point)) is the beginning of the label
 - (cdar (numbex--item-at-point)) is the end of the label
 - (cdr (numbex--item-at-point)) is the type of the label"
  (let ((position (point)))
    (save-excursion
      (beginning-of-line)
      (catch 'found
        (while (re-search-forward numbex--item-re (line-end-position) t)
          (when (<= (match-beginning 0) position (match-end 0))
            (throw 'found
                   (cons (cons (match-beginning 2)
                               (match-end 2))
                         (buffer-substring-no-properties (match-beginning 1)
                                                         (match-end 1)))))
          nil)))))

;; These are the hash tables and list that are reset at every
;; evaluation of 'numbex--scan-buffer': they contain all the
;; information pertinent to the numbering and the referencing of
;; examples.
(defvar-local numbex--label-number nil
  "Hash table mapping labels of examples to the number assigned.")

(defvar-local numbex--label-line nil
  "Hash table mapping labels to context of the example.
The keys of the hash tables are non-empty labels and the values
are the line of the buffer that contains the corresponding
example.")

(defvar-local numbex--duplicates nil
  "List of non-empty labels that are not unique in the buffer.")

(defvar-local numbex--existing-labels nil
  "List of non-empty labels currently used in the buffer.")

;; An example is the best way to explain what this variable is for.
;; Suppose there are five examples in the buffer: three in the first
;; page, two in the second.  The value of this variable will be: ("1"
;; "2" "3" "1" "2")

;; When 'numbex--add-numbering' is evaluated, if 'numbex--relative' is
;; t, the examples will be numbered in loop by popping values out of
;; this list.
(defvar-local numbex--numbers-list nil
  "List of strings corresponding to the numbers in the buffer.
The first item in the list is the string that is displayed over
the first example item in the buffer (if 'numbex--hidden-labels'
is t), the second item is the string over the second example
item, and so on.")

(defcustom numbex-numbering-reset t
  "If nil, the numbering never restarts in the buffer.
If t, numbering restart at \"(1)\" at every regexp specified in
'numbex-numbering-reset-regexps'.  This variable is made
buffer-local its value can be toggled interactively with
'numbex-toggle-numbering-reset'."
  :type 'boolean
  :group 'numbex)

(make-variable-buffer-local 'numbex-numbering-reset)

(defcustom numbex-numbering-reset-regexps
  '("")
  "List of regexps at which numbering restarts.
If the buffer-local value of 'numbex-numbering-reset' is t,
numbering restarts at \"(1)\" at each of the regexp in this list.
The default value is the form-feed character (\"\f\" or \"\").

This variable is made buffer-local, and can be specified as a
file-local variable (for example, with
'add-file-local-variable')."
  :type '(list string)
  :group 'numbex)

(make-variable-buffer-local 'numbex-numbering-reset-regexps)

(defconst numbex--safe-number-items 1000
  "The largest number of numbex items in a buffer considered safe.
Numbex can deal with larger numbers than that, but in the
interest of performance the refresh on idle timer should be
disabled at a certain point.")

(defcustom numbex-delimiters '("(" . ")")
  "Opening and closing characters used around numbers.
Set two empty strings if you just want the number.

This variable is made buffer-local, and can be specified as a
file-local variable (for example, with
'add-file-local-variable')."
  :type '(cons string string)
  :group 'numbex)

(make-variable-buffer-local 'numbex-delimiters)

(defvar-local numbex--items-list nil
  "List of all items and reset regexps currently in the buffer.")

(defvar-local numbex--annotation-alist '()
  "Alist mapping labels to strings of number and context.")

(defun numbex--scan-buffer ()
  "Collect information relevant for numbex from the buffer.
Remove all whitespace from items.

The information is collected in a widened indirect buffer, so
that even if the current buffer is narrowed, numbex will behave
taking into consideration the entire buffer."
  ;; Recreate the two hash tables with the size of the last value of
  ;; 'numbex--existing-labels'
  (let* ((old-number-labels (length numbex--existing-labels))
         (narrowed (buffer-narrowed-p))
         (start-of-buffer (point-min))
         (point-in-narrowing nil)
         (labels '())
         (duplicates '())
         (numbers '())
         (items '())
         (annotation '())
         (counter 1)
         (delimiters
          ;; Check whether a file-local variable specifies a value for
          ;; 'numbex-numbering-reset-regexps'.  If it does, set that value.
          (if (assoc 'numbex-numbering-reset-regexps
                     file-local-variables-alist)
              (cdr (assoc 'numbex-numbering-reset-regexps
                          file-local-variables-alist))
            numbex-numbering-reset-regexps))
         ;; Construct a regexp that matches the disjunction of the
         ;; regexps in 'numbex-numbering-reset-regexps'.
         (delimiters-re (mapconcat 'identity delimiters "\\|"))
         (global-re (concat numbex--item-re "\\|" delimiters-re)))
    (setq numbex--label-line (make-hash-table :test 'equal
                                              :size old-number-labels)
          numbex--label-number (make-hash-table :test 'equal
                                                :size old-number-labels)
          numbex--total-number-of-items 0)
    (with-current-buffer (clone-indirect-buffer nil nil t)
      (widen)
      (goto-char (point-min))
      (while (re-search-forward global-re nil t)
        (push (match-string-no-properties 0) items)
        (if (save-match-data
              (string-match delimiters-re (match-string-no-properties 0)))
            ;; We hit a delimiter character: If
            ;; 'numbex-numbering-reset' is t, reset the counter to 1
            (when numbex-numbering-reset (setq counter 1))
          ;; We hit an item: first thing we do is removing whitespace.
          (let ((clean-label
                 (if (string-match "[[:space:]]"
                                   (match-string-no-properties 2)
                                   nil)
                     (replace-match
                      (replace-regexp-in-string "[[:space:]]" ""
                                                (match-string-no-properties 2))
                      t t nil 2)
                   (match-string-no-properties 2)))
                (type (match-string-no-properties 1)))
            (setq numbex--total-number-of-items
                  (1+ numbex--total-number-of-items))
            ;; If the item is an example, we have to fill up our hash
            ;; tables and lists, otherwise, we have nothing more to do
            ;; Before doing this, we might need to reset the counter
            ;; to 1 if the buffer was narrowed, we want relative
            ;; numbering, and the point now is after the original
            ;; (point-min), that is, it has entered the narrowed
            ;; portion of the buffer.  If all this is the case, reset
            ;; the counter and set 'point-in-narrowing' to t so that
            ;; it won't reset again at the next match.
            (when (equal type "ex")
              (when (and (not point-in-narrowing)
                         numbex-numbering-reset
                         narrowed
                         (> (point) start-of-buffer))
                (setq point-in-narrowing t
                      counter 1))
              ;; For convenience, let's store strings of the form
              ;; "(1)" instead of numbers like 1 in the lists, so we
              ;; won't have to bother convert it later when it's time
              ;; to put them as display text properties.
              (let ((n-string (concat (car numbex-delimiters)
                                      (number-to-string counter)
                                      (cdr numbex-delimiters))))
                (push n-string numbers)
                (unless (string-blank-p clean-label)
                  (when (and (member clean-label labels)
                             (not (member clean-label duplicates)))
                    ;; keep only one token for each type of duplicate
                    ;; label
                    (push clean-label duplicates))
                  (push clean-label labels))    ; only non-empty labels matter
                (puthash clean-label n-string numbex--label-number)
                (goto-char (match-end 0))
                ;; This will change match data: if there is a number
                ;; placeholder next to the item, it won't end up being
                ;; included in the line.
                (looking-at (concat (car numbex-delimiters)
                                    "[\\.]+"
                                    (cdr numbex-delimiters)))
                (puthash clean-label
                         (buffer-substring-no-properties (match-end 0)
                                                         (line-end-position))
                         numbex--label-line)
                (unless (string-blank-p clean-label)
                  (push
                   (cons clean-label
                         (concat n-string " "
                                 (buffer-substring-no-properties
                                  (match-end 0)
                                  (line-end-position))))
                   annotation)))
              ;; Before the next iteration, increment both counters
              (setq counter (1+ counter))))))
      (kill-buffer (current-buffer)))
    ;; Now we are out of the indirect buffer, and we can set the rest
    ;; of the buffer local variables with the values we obtained from
    ;; the loop.
    (setq numbex--numbers-list (nreverse numbers)
          numbex--duplicates duplicates
          numbex--existing-labels labels
          numbex--items-list items
          numbex--annotation-alist annotation)))

(defun numbex--highlight (lab type b e)
  "Add face text properties to substring between B and E.
Do so according to the values of 'numbex-highlight-duplicates'
and 'numbex-highglight-unlabeled'.  LAB is the label of the item
and TYPE its type."
  (cond ((and (member lab numbex--duplicates)
              numbex-highlight-duplicates)
         (add-text-properties b e '(font-lock-face 'font-lock-warning-face))
         (put-text-property b e 'rear-nonsticky t))
        ((and numbex-highlight-unlabeled
              (equal type "rex")
              (string-blank-p lab))
         (add-text-properties b e '(font-lock-face 'font-lock-comment-face))
         (put-text-property b e 'rear-nonsticky t))
        (t nil)))

(defun numbex--remove-numbering (&optional no-colors)
  "Remove all numbex text properties from the buffer.
Set 'numbex--hidden-labels' to nil.  If NO-COLORS is t, don't set
font-lock-faces.

Does not mark the buffer as modified."
  (with-silent-modifications
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward numbex--item-re nil t)
        (let ((b (match-beginning 0))
              (type (buffer-substring-no-properties (match-beginning 1)
                                                    (match-end 1)))
              (lab (buffer-substring-no-properties (match-beginning 2)
                                                   (match-end 2))))
          (when (looking-at (concat (car numbex-delimiters)
                                    "[\\.]+"
                                    (cdr numbex-delimiters)))
            (delete-region (match-beginning 0) (match-end 0)))
          (set-text-properties b (point) nil)
          (when (or (equal type "ex") (equal type "rex") (not no-colors))
            (numbex--highlight lab type b (point))))))
    (numbex--toggle-font-lock-keyword)
    (setq numbex--hidden-labels nil)))

(defun numbex--add-numbering ()
  "Number items in the buffer as text properties.
Set 'numbex-hidden-labels' to t.

Does not mark the buffer as modified."
  (with-silent-modifications
    (setq numbex--total-number-of-items 0)
    ;; First, let's number the examples.  If the buffer is narrowed
    ;; and 'numbex-numbering-reset' is t, we just need to number
    ;; the examples in the buffer.
    (with-current-buffer (clone-indirect-buffer nil nil t)
      (widen)
      (goto-char (point-min))
      (let ((previous-ex-n "(1)"))
        (while (re-search-forward numbex--item-re nil t)
          ;; Add to the total number first
          (setq numbex--total-number-of-items
                (1+ numbex--total-number-of-items))
          (let ((b (match-beginning 0))
                (e (match-end 0))
                (type (buffer-substring-no-properties (match-beginning 1)
                                                      (match-end 1)))
                (label (buffer-substring-no-properties (match-beginning 2)
                                                       (match-end 2))))
            (when (looking-at (concat (car numbex-delimiters)
                                      "[\\.]+"
                                      (cdr numbex-delimiters)))
              (delete-region (match-beginning 0) (match-end 0)))
            (set-text-properties b e nil)
            (cond ((equal type "ex")
                   ;; As number, take the current car of
                   ;; numbex--numbers-list:
                   (let ((num (pop numbex--numbers-list)))
                     (insert (replace-regexp-in-string "[[:digit:]]\\|\\?"
                                                       "." num))
                     (put-text-property b (point) 'display num)
                     (numbex--highlight label type b (point))
                     (setq previous-ex-n num)))
                  ;; If the item is {[rex:]}, without a label, give it
                  ;; the number of the closes example.  Otherwise, look
                  ;; up the hash table to find the number to give.  If
                  ;; no key corresponding to the label is found it means
                  ;; that the non-empty label is not being used by any
                  ;; example (yet), so the reference will appear as
                  ;; "(??)":
                  ((equal type "rex")
                   (let ((num (if (string-blank-p label)
                                  previous-ex-n
                                (gethash label
                                         numbex--label-number
                                         (concat (car numbex-delimiters)
                                                 "??"
                                                 (cdr numbex-delimiters))))))
                     (insert (replace-regexp-in-string "[[:digit:]]\\|\\?"
                                                       "." num))
                     (put-text-property b (point) 'display num)
                     (numbex--highlight label type b (point))))
                  ((equal type "pex")
                   (insert (replace-regexp-in-string "[[:digit:]]\\|\\?" "."
                                                     previous-ex-n))
                   (put-text-property b (point) 'display previous-ex-n))
                  ((equal type "nex")
                   (let ((num (if (car numbex--numbers-list)
                                  (car numbex--numbers-list)
                                (concat (car numbex-delimiters)
                                        "??"
                                        (cdr numbex-delimiters)))))
                     (insert (replace-regexp-in-string "[[:digit:]]\\|\\?"
                                                       "." num))
                     (put-text-property b (point) 'display num)))))))
      (kill-buffer (current-buffer)))
    (numbex--toggle-font-lock-keyword t)
    (setq numbex--hidden-labels t)))

(defun numbex-toggle-numbering-reset ()
  "Toggle value of 'numbex-numbering-reset' (buffer-local)."
  (interactive)
  (if numbex-numbering-reset
      (progn (setq numbex-numbering-reset nil)
             (message "Relative numbering deactivated"))
    (setq numbex-numbering-reset t)
    (message "Relative numbering activated")))

(defun numbex-toggle-visibility ()
  "Remove numbers if they are present, add them otherwise."
  (interactive)
  (when numbex--automatic-refresh
    (numbex-refresh))
  (if numbex--hidden-labels
      (numbex--remove-numbering)
    (numbex--add-numbering)))

(defun numbex--uniquify-string (s l)
  "Return modified S such that it is not a member of list L.
The suffix to be added is \"-NN\", where N is a digit."
  (let ((counter 1)
        (label s))
    (while (member label l)
      (let ((suffix (concat "--" (format "%s" counter))))
        (setq label (concat s suffix)
              counter (1+ counter))))
    label))

(defun numbex--prompt-with-duplicate-label (label)
  "Choose what to do if LABEL is in 'numbex--existing-labels'.
Allow the user to return a uniquified string by calling
'numbex--uniquify-string' on LABEL."
  (let ((choice (read-multiple-choice
                 (concat label
                         " is used already, are you sure?")
                 '((?y "yes") (?n "no") (?! "make label unique")))))
    (cond ((equal choice '(?y "yes")) label)
          ((equal choice '(?n "no")) nil)
          ((equal choice '(?! "make label unique"))
           (numbex--uniquify-string label numbex--existing-labels)))))

(defun numbex--annotation-function (label)
  "Return string mapped to LABEL in 'numbex--annotation-alist'."
  (let ((candidate (cdr (assoc label minibuffer-completion-table))))
    (when candidate
      (concat "  -- " candidate))))

(defun numbex-edit ()
  "If point is on a numbex item, let user edit its label."
  (interactive)
  (unless (numbex--item-at-point)
    (user-error "Not on a numbex item"))
  (save-excursion
    (let* ((item (numbex--item-at-point))
           (old-label
            (buffer-substring-no-properties (car (car item)) (cdr (car item))))
           (type (cdr item))
           (new-label
            (if (equal type "ex")
                (replace-regexp-in-string "[[:space:]]" ""
                 (read-string (format "New label [default \"%s\"]: "
                                      old-label)
                              old-label nil
                              old-label t))
              ;; If the item is a reference, provide completion with
              ;; the existing labels.
              (let ((completion-extra-properties
                     '(:annotation-function numbex--annotation-function)))
                (completing-read (format "Label [default \"%s\"]: " old-label)
                                 numbex--annotation-alist
                                 nil nil
                                 old-label nil
                                 old-label t))))
           (novel (not (member new-label numbex--existing-labels))))
      (if (and (equal type "ex") (not novel) (not (equal new-label old-label)))
          (let ((reaction (numbex--prompt-with-duplicate-label new-label)))
            (if (not reaction)
                (numbex-edit item)
              (goto-char (car (car item)))
              (delete-region (car (car item)) (cdr (car item)))
              (insert reaction)))
        (goto-char (car (car item)))
        (delete-region (car (car item)) (cdr (car item)))
        (insert new-label))
      (when (and (equal type "ex") novel (not (string-blank-p old-label)))
        (let ((rename (yes-or-no-p "Relabel all associated references?"))
              (target (concat "{\\[[r]?ex:\\(" old-label "\\)\\]}")))
          (when rename (goto-char (point-min))
                (while (search-forward-regexp target nil t)
                  (replace-match new-label t t nil 1)))))
      ;; If item at point is nex: or pex:, make it into a rex:,
      ;; otherwise the new label will be wiped out automatically.  It
      ;; does not make sense to edit pex: and nex: items manually.
      (when (or (equal type "nex")
                (equal type "pex"))
        (re-search-backward "{\\[[pn]+ex")
        (replace-match "{[rex" t)))))

(defun numbex-new-example ()
  "Insert a new example item.

Do nothing if point is currently on a numbex item."
  (interactive)
  (when (numbex--item-at-point)
    (user-error "Point is on an existing numbex item"))
  (let* ((label (read-string "Label: "
                             nil nil
                             nil t))
         (sanitized-label (replace-regexp-in-string "[[:space:]]" "" label)))
    (if (member sanitized-label numbex--existing-labels)
        (let ((reaction (numbex--prompt-with-duplicate-label sanitized-label)))
            (if (not reaction)
                (numbex-new-example)
              (insert "{[ex:" reaction "]}")))
      (insert "{[ex:" sanitized-label "]}"))))

(defun numbex-new-reference ()
  "Insert a new reference item.
Select from the existing labels with completion.

Do nothing if point is currently on a numbex item."
  (interactive)
  (when (numbex--item-at-point)
    (user-error "Point is on an existing numbex item"))
  (insert
   "{[rex:"
   (let ((completion-extra-properties
          '(:annotation-function numbex--annotation-function)))
     (completing-read "Label: "
                      numbex--annotation-alist))
   "]}"))

(defun numbex-new-reference-to-previous ()
  "Insert \"{[pex:]}\".

Do nothing if point is currently on a numbex item."
  (interactive)
  (when (numbex--item-at-point)
    (user-error "Point is on an existing numbex item"))
  (insert "{[pex:]}"))

(defun numbex-new-reference-to-next ()
  "Insert \"{[nex:]}\".

Do nothing if point is currently on a numbex item."
  (interactive)
  (when (numbex--item-at-point)
    (user-error "Point is on an existing numbex item"))
  (insert "{[nex:]}"))

(defun numbex-new-item ()
  "Insert a new numbex item.

+ \"e\" to insert a new example
+ \"r\" to insert a new reference
+ \"n\" to insert a reference to the next example
+ \"p\" to insert a reference to the previous example

Do nothing if point is currently on a numbex item."
  (interactive)
  (when (numbex--item-at-point)
    (user-error "Point is on an existing numbex item"))
  (let ((choice (read-multiple-choice "Insert new:"
                                      '((?e "example")
                                        (?r "reference")
                                        (?n "ref to next")
                                        (?p "ref to previous")))))
    (cond ((equal choice '(?e "example"))
           (numbex-new-example))
          ((equal choice '(?r "reference"))
           (numbex-new-reference))
          ((equal choice '(?n "ref to next"))
           (insert "{[nex:]}"))
          ((equal choice '(?p "ref to previous"))
           (insert "{[pex:]}")))
    (insert " ")))

(defun numbex-dwim ()
  "Insert a new item or edit the existing one at point."
  (interactive)
  (let ((hidden numbex--hidden-labels))
    (when hidden (numbex--remove-numbering))
    (if (numbex--item-at-point)
        (numbex-edit)
      (numbex-new-item))
    (when numbex--automatic-refresh (numbex-refresh t))
    (if hidden
        (numbex--add-numbering)
      (numbex--remove-numbering))))

(defun numbex-forward-example (&optional count)
  "Move point to next example item.
Optional prefix COUNT specifies how many examples forwards to jump
to.

Do nothing if there is no next example item in the accessible
portion of the buffer."
  (interactive "p")
  (let ((count (or count 1))
        (pos (if (equal (cdr (numbex--item-at-point)) "ex")
                 (caar (numbex--item-at-point))
               nil)))
    (if (eq count 0) (user-error nil)
      (funcall #'numbex--jump-to-example count pos))))

(defun numbex-backward-example (&optional count)
  "Move point to previous example item.
Always skip an example item that is on the same line as point.
Optional prefix COUNT specifies how many examples backwards to jump
to.

Do nothing if there is no previous example item in the accessible
portion of the buffer."
  (interactive "p")
  (let ((count (or count 1))
        (pos (if (equal (cdr (numbex--item-at-point)) "ex")
                 (caar (numbex--item-at-point))
               nil)))
    (if (eq count 0) (user-error nil)
      (funcall #'numbex--jump-to-example (- count (* 2 count)) pos))))

;; When moving to an example item that is hidden (e.g. under a folded
;; org-mode heading), the value of this variable is set to the buffer
;; position corresponding to the end of the example item (i.e. the end
;; of the matched string).  This way, if you move further down or up
;; in the buffer, the section that was opened just because you
;; searched for an example item into it will be hidden again.  Every
;; time a new movement "chain" is initiated this variable is reset to
;; nil.
(defvar-local numbex--previous-movement-invisible nil)

(defun numbex--jump-to-example (count pos)
  "Jump to n example items forward or backward, where n is COUNT.

POS is nil if point is not on a numbex example already, otherwise
it is the buffer position of the beginning of the label of the
example item at point."
  ;; First let's check that there are enough example items to jump to.
  (save-excursion
    ;; Go to the middle of the example item at point so that the search
    ;; can work in the first place.
    (when pos (goto-char pos))
    (unless (re-search-forward numbex--example-re nil t count)
      (let ((errormessage (cond ((< count -1)
                                 (format "No %s previous examples" count))
                                ((= count -1) "No previous example")
                                ((= count 1) "No next example")
                                ((> count 1)
                                 (format "No %s next examples" count)))))
        (setq numbex--previous-movement-invisible nil)
        (user-error errormessage))))
  (when pos (goto-char pos))
  (re-search-forward numbex--example-re nil t count)
  (let* ((target-beginning (match-beginning 0))
         (target-end (match-end 0))
         (chain (or (eq last-command 'numbex-forward-example)
                    (eq last-command 'numbex-backward-example))))
    ;; Don't bother making anything invisible if the previous command
    ;; was not a movement command.
    (unless chain (setq numbex--previous-movement-invisible nil))
    (when numbex--previous-movement-invisible
      ;; Go to the example you had jumped right before getting here
      ;; and close the subtree
      (goto-char numbex--previous-movement-invisible)
      (outline-hide-subtree))
    (goto-char target-beginning)
    ;; Now that you are back to the actual target, if it is invisible
    ;; open up the subtree and add this location to the record so that
    ;; it will be made invisible again if you move further up or down.
    (when (outline-invisible-p target-end)
      (setq numbex--previous-movement-invisible target-end)
      (outline-show-subtree))))

(defun numbex-list ()
  "Find items in the buffer through 'occur'.

+ \"a\" to return all items
+ \"e\" to return all example items
+ \"l\" to return all items with the same label of the one at point
+ \"d\" to return all items with a non unique label
+ \"u\" to return all items without a label"
  (interactive)
  (numbex--remove-numbering)
  (numbex-refresh t)
  (let* ((positions (car (numbex--item-at-point)))
         (label (if positions
                    (buffer-substring-no-properties (car positions)
                                                    (cdr positions))
                  ""))
         (reg (concat "{\\[[pnr]?ex:" label "\\]}"))
         (options '((?a "all")
                    (?e "examples")
                    (?r "references")
                    (?d "duplicates")
                    (?u "unlabeled")))
         (choice (if positions
                     (read-multiple-choice "Look for:"
                                           (cons '(?l "label at point")
                                                 options))
                   (read-multiple-choice "Look for:" options))))
    (cond ((equal choice '(?a "all"))
           (occur numbex--item-re))
          ((equal choice '(?e "examples"))
           (occur numbex--example-re))
          ((equal choice '(?r "references"))
           (occur numbex--reference-re))
          ((equal choice '(?l "label at point"))
           (occur reg))
          ((equal choice '(?d "duplicates"))
           (occur (regexp-opt
                   (nconc (mapcar (lambda (x) (concat "{[ex:"
                                                      x
                                                      "]}"))
                                  numbex--duplicates)
                          (mapcar (lambda (x) (concat "{[rex:"
                                                      x
                                                      "]}"))
                                  numbex--duplicates)))))
          ((equal choice '(?u "unlabeled"))
           (occur "{\\[[r]?ex:\s*\\]}"))))
  (numbex--add-numbering))

(defun numbex--echo-duplicates ()
  "Display existing non-unique labels in the echo area."
  (when numbex--duplicates
    (if (= (length numbex--duplicates) 1)
        (message (concat ""
                         "1 duplicate label found: "
                         (car numbex--duplicates)))
      (message (concat (format  "%s duplicate labels found: "
                                (length numbex--duplicates))
                       (mapconcat #'identity numbex--duplicates "  "))))))

(defvar-local numbex--buffer-hash nil
  "Store value of 'buffer-hash' buffer-locally.")

(defun numbex-refresh (&optional no-echo)
  "Scan the buffer and assign numbers.
If NO-ECHO is non-nil, do not warn about duplicates.  This is to
be added to 'numbex-mode-hook', 'auto-save-hook' and
'before-save-hook'.

Does not mark the buffer as modified."
  (interactive)
  (with-silent-modifications
    ;; Check whether a file-local variable specifies a value for
    ;; 'numbex-delimiters'.  If it does, set that value.
    (when (assoc 'numbex-delimiters file-local-variables-alist)
      (setq numbex-delimiters
            (cdr (assoc 'numbex-delimiters file-local-variables-alist))))
    (let ((hidden numbex--hidden-labels)
          (old-items-list numbex--items-list))
      (numbex--scan-buffer)
      ;; Now 'numbex--items-list' has been updated: do nothing if the
      ;; new value is the same as the old one.
      (unless (= (sxhash-equal old-items-list) (sxhash-equal numbex--items-list))
        (numbex--add-numbering)
        (unless hidden (numbex--remove-numbering))
        (unless no-echo (numbex--echo-duplicates))))
    ;; Update the value of numbex--buffer-hash
    (setq numbex--buffer-hash (buffer-hash))))

(defvar numbex--idle-timer nil)

(defun numbex--timed ()
  "Housekeeping function to be evaluated on 'numbex--idle-timer'.
If not in 'numbex-mode' or 'numbex--hidden-labels' is nil, do
nothing.  Otherwise, if point is on an item, display its label
and, if appropriate, the context of the referenced example in the
echo area.  If point is not on an item, evaluate
'numbex--scan-buffer' and 'numbex--add-numbering' so that the
appearance of the buffer is kept up to date as far as numbex is
concerned."
  (when (and numbex-mode numbex--hidden-labels)
    (let ((item (numbex--item-at-point))
          ;; Let's not fill *Messages* with useless stuff
          (message-log-max nil))
      (if item
          ;; Point is on an item: show the underlying label.  If the
          ;; item is a reference, show the context of the
          ;; corresponding example as well.
          (let* ((type (cdr item))
                 (label (buffer-substring-no-properties (car (car item))
                                                        (cdr (car item)))))
            (if (equal type "ex")
                (message label)
              (message (concat label ": "
                               (gethash label numbex--label-line " ")))))
        ;; Point is not on an item, just rescan the buffer and
        ;; renumber the items.  Do it only if this wouldn't cripple
        ;; everything.
        (unless (or (> numbex--total-number-of-items numbex--safe-number-items)
                    (not numbex--automatic-refresh)
                    ;; If (buffer-hash) is the same as the stored
                    ;; value, it means the buffer hasn't changed, so
                    ;; don't do anything!  The value of
                    ;; 'numbex--buffer-hash' is updated by
                    ;; 'numbex-refresh'
                    (equal (buffer-hash) numbex--buffer-hash))
          ;; Giving t as an argument prevents 'numbex-refresh' to
          ;; annoy the user with messages in the echo area about
          ;; duplicate labels.  They will only be shown if the
          ;; function is called interactively or when it is evaluated
          ;; on auto-save and before-save-hook.
          (numbex-refresh t))))))

(defun numbex-write-out-numbers (&optional choose-mode)
  "Replace items in current buffer with actual numbers in new buffer.
Visit the new buffer in another window.

If the region is active, the ouptut in the new buffer is
restricted to the marked portion of the current buffer.

If called with prefix argument CHOOSE-MODE, let the user choose
the major mode for the new buffer; otherwise, the new buffer will
be in the same major mode as the current buffer."
  (interactive "P")
  (numbex--scan-buffer)
  (numbex--add-numbering)
  (let* ((original-buffer (current-buffer))
         (maj-mode (if choose-mode
                       (intern (completing-read
                                "Major Mode: "
                                (mapcar 'cdr auto-mode-alist)
                                nil t "" nil nil "text-mode"))
                     major-mode))
         (beg-end (if (region-active-p)
                      (cons (region-beginning) (region-end))
                    (cons (point-min) (point-max))))
         (new-buffer-name (generate-new-buffer-name
                           (concat "nb-" (format "%s" original-buffer)))))
    (get-buffer-create new-buffer-name)
    (with-current-buffer new-buffer-name (funcall maj-mode))
    (insert-into-buffer new-buffer-name (car beg-end) (cdr beg-end))
    (with-current-buffer new-buffer-name
      (goto-char (point-min))
      (while (re-search-forward numbex--item-re nil t)
        (let* ((b (match-beginning 0))
               (e (match-end 0))
               (number (plist-get (text-properties-at (match-beginning 2))
                                  'display)))
          (goto-char b)
          (delete-region b e)
          (when (looking-at (concat (car numbex-delimiters)
                                    "[\\.\\?]+"
                                    (cdr numbex-delimiters)))
            (delete-region (match-beginning 0) (match-end 0)))
          (insert number))))
    (switch-to-buffer-other-window new-buffer-name)))

(defun numbex--count-and-ask ()
  "With too many items in the buffer, ask whether to automatically refresh.
\"Too many\" means more than 'numbex--safe-number-items'."
  (save-excursion
    (goto-char (point-min))
    (setq numbex--total-number-of-items 0)
    (while (re-search-forward numbex--item-re nil t)
      (setq numbex--total-number-of-items (1+ numbex--total-number-of-items)))
    (when (and (> numbex--total-number-of-items numbex--safe-number-items)
               numbex--automatic-refresh)
      (let* ((question
              (format "There are %s items in the buffer.
Do you want to disable automatic refresh?
(you can refresh yourself with 'numbex-refresh')?"
                      numbex--total-number-of-items))
             (choice (yes-or-no-p question)))
        (when choice (setq numbex--automatic-refresh nil))))))

(defun numbex--toggle-font-lock-keyword (&optional add)
  "Remove or add font-lock-keyword toggling invisibility of numbex items.
If the value of ADD is t, add the keyword, otherwise remove it.
Finally, refontify accessible portion of the buffer."
  (if add
      (font-lock-add-keywords
       nil '(("{\\[[pnr]?ex:\\(.*?\\)\\]}" 0
              '(face nil invisible t) append)))
    (font-lock-remove-keywords
     nil '(("{\\[[pnr]?ex:\\(.*?\\)\\]}" 0 '(face nil invisible t) append))))
  (save-excursion (font-lock-fontify-region (point-min) (point-max))))

(defvar numbex-command-map (make-sparse-keymap)
  "Keymap for 'numbex-mode' commands.")

;;;###autoload
(define-minor-mode numbex-mode
  "Automatically number examples and references to them."
  :init-value nil
  :global nil
  :lighter " nx"
  :group 'convenience
  (if numbex-mode
      ;; activating numbex-mode
      (progn
        (unless numbex--idle-timer
          (setq numbex--idle-timer (run-with-idle-timer 0.1 t #'numbex--timed)))
        (numbex--count-and-ask)
        ;; For the first time they are created, let the hash tables
        ;; have the default size of 65
        (setq numbex--label-line (make-hash-table :test 'equal)
              numbex--label-number (make-hash-table :test 'equal))
        (numbex--scan-buffer)
        (numbex--add-numbering)
        ;; Numbex needs font-lock
        (unless font-lock-mode
          (font-lock-mode 1))
        (font-lock-add-keywords
         nil '(("{\\[[pnr]?ex:\\(.*?\\)\\]}" 0 '(face nil invisible t) append)))
        (save-excursion (font-lock-fontify-region (point-min) (point-max)))
        (add-hook 'auto-save-hook #'numbex-refresh nil t)
        (add-hook 'before-save-hook #'numbex-refresh nil t))
    ;; leaving numbex-mode
    (cancel-timer numbex--idle-timer)
    (setq numbex--idle-timer nil)
    ;; Evaluate numbex--remove-numbering with the optional argument
    ;; no-colors non-nil so that there won't be any color left
    ;; regardless of the value of the variables
    ;; numbex-highlight-unlabeled and numbex-highlight-duplicates:
    (numbex--remove-numbering t)
    (font-lock-remove-keywords
     nil '(("{\\[[pnr]?ex:\\(.*?\\)\\]}" 0 '(face nil invisible t) append)))
    (save-excursion (font-lock-fontify-region (point-min) (point-max)))
    (remove-hook 'auto-save-hook #'numbex-refresh t)
    (remove-hook 'before-save-hook #'numbex-refresh t)))

(provide 'numbex)

;;; _
;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; numbex.el ends here
