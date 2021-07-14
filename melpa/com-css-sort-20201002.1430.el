;;; com-css-sort.el --- Common way of sorting the CSS attributes  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Shen, Jen-Chieh
;; Created date 2018-04-30 14:26:37

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Common way of sorting the CSS attributes.
;; Keyword: Common CSS Handy Sort Sorting
;; Version: 0.0.7
;; Package-Requires: ((emacs "25.1") (s "1.12.0"))
;; URL: https://github.com/jcs090218/com-css-sort

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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
;;
;; Common way of sorting the CSS attributes.
;;

;;; Code:

(require 'cl-lib)
(require 's)
(require 'subr-x)

(defgroup com-css-sort nil
  "Sort CSS attributes extension"
  :prefix "com-css-sort-"
  :group 'editing
  :link '(url-link :tag "Repository" "https://github.com/jcs090218/com-css-sort"))

(defcustom com-css-sort-sort-type 'type-sort
  "Type of sorting CSS attributes algorithm going to use to sort.
'type-sort : Sort by Type Group.
'alphabetic-sort : Sort by Alphabetic Order."
  :type '(choice (const :tag "type-sort" type-sort)
                 (const :tag "alphabetic-sort" alphabetic-sort))
  :group 'com-css-sort)

(defcustom com-css-sort-sort-file "sort-order.config"
  "File to read the order.
This file should place somewhere path are relative to the
version control path.
This wil replace `com-css-sort-default-attributes-order' if it can."
  :type 'string
  :group 'com-css-sort)

(defcustom com-css-sort-default-attributes-order
  '("display"
    "position"
    "top"
    "right"
    "bottom"
    "left"
    "float"
    "clear"
    "visibility"
    "opacity"
    "z-index"
    "margin"
    "margin-top"
    "margin-right"
    "margin-bottom"
    "margin-left"
    "outline"
    "border"
    "border-top"
    "border-right"
    "border-bottom"
    "border-left"
    "border-width"
    "border-top-width"
    "border-right-width"
    "border-bottom-width"
    "border-left-width"
    "border-style"
    "border-top-style"
    "border-right-style"
    "border-bottom-style"
    "border-left-style"
    "border-color"
    "border-top-color"
    "border-right-color"
    "border-bottom-color"
    "border-left-color"
    "background"
    "background-color"
    "background-image"
    "background-repeat"
    "background-position"
    "cursor"
    "padding"
    "padding-top"
    "padding-right"
    "padding-bottom"
    "padding-left"
    "width"
    "min-width"
    "max-width"
    "height"
    "min-height"
    "max-height"
    "overflow"
    "list-style"
    "caption-side"
    "table-layout"
    "border-collapse"
    "border-spacing"
    "empty-cells"
    "vertical-align"
    "text-align"
    "text-indent"
    "text-transform"
    "text-decoration"
    "line-height"
    "word-spacing"
    "letter-spacing"
    "white-space"
    "color"
    "font"
    "font-family"
    "font-size"
    "font-weight"
    "content"
    "quotes")
  "List of CSS attributes sort order by type."
  :type 'list
  :group 'com-css-sort)

;;; Util

(defun com-css-sort--goto-line (ln)
  "Goto LN line number."
  (goto-char (point-min)) (forward-line (1- ln)))

(defun com-css-sort--get-string-from-file (file-path)
  "Return FILE-PATH's file content."
  (with-temp-buffer
    (insert-file-contents file-path)
    (buffer-string)))

;;; Core

(defun com-css-sort--get-ccs-file-list ()
  "Get the `com-css-sort-sort-file' and turn it into list."
  (let ((sort-file-path (concat (cdr (project-current)) com-css-sort-sort-file))
        (attr-list '())
        (sort-file-content '()))
    (when (file-exists-p sort-file-path)
      ;; Get the file content as buffer.
      (setq sort-file-content (com-css-sort--get-string-from-file sort-file-path))
      ;; Split the file content buffer into list.
      (setq attr-list (split-string sort-file-content)))
    ;; Return the sort order list.
    attr-list))

(defun com-css-sort--back-to-indentation-or-beginning ()
  "Toggle between first character and beginning of line."
  (when (= (point) (progn (back-to-indentation) (point))) (beginning-of-line)))

(defun com-css-sort--get-current-line ()
  "Return the current line into string."
  (thing-at-point 'line t))

(defun com-css-sort--is-beginning-of-line-p ()
  "Is at the beginning of line?"
  (save-excursion
    (let ((current-point nil) (begin-line-point nil))
      (setq current-point (point))
      (beginning-of-line)
      (setq begin-line-point (point))
      (= begin-line-point current-point))))

(defun com-css-sort--goto-first-char-in-line ()
  "Goto beginning of line but ignore 'empty characters'(spaces/tabs)."
  (com-css-sort--back-to-indentation-or-beginning)
  (when (com-css-sort--is-beginning-of-line-p)
    (com-css-sort--back-to-indentation-or-beginning)))

(defun com-css-sort--current-line-empty-p ()
  "Current line empty, but accept spaces/tabs in there.  (not absolute)."
  (save-excursion
    (beginning-of-line)
    (looking-at "[[:space:]\t]*$")))

(defun com-css-sort--is-inside-comment-block-p ()
  "Check if current cursor point inside the comment block."
  (nth 4 (syntax-ppss)))

(defun com-css-sort--attribute-line ()
  "Check if current line the attribute line.
If non-nil, attribute line.
If nil, is not attribute line."
  ;; Check attribute line by simply searching key character ':' colon.
  (string-match-p ":" (com-css-sort--get-current-line)))

(defun com-css-sort--currnet-line-not-attribute-comment-line ()
  "Check if current line is a 'pure' comment line, not an attribute comment line."
  (save-excursion
    (com-css-sort--goto-first-char-in-line)
    (forward-char 2)
    (and
     ;; First check if is comment line.
     (com-css-sort--is-inside-comment-block-p)
     ;; Then check if current line attribute line.
     (not (com-css-sort--attribute-line)))))

(defun com-css-sort--get-sort-list-until-empty-or-comment-line ()
  "Get the list we want to sort.
Depends on if we meet a empty line or a comment line."
  (save-excursion
    (let ((line-list '()))
      (while (and (not (com-css-sort--current-line-empty-p))
                  (not (com-css-sort--currnet-line-not-attribute-comment-line)))
        (let ((current-line (com-css-sort--get-current-line)))
          (when (not (string-match "}" current-line))
            ;; Push the line into list.
            (push current-line line-list)))

        ;; Get next line of attribute.
        (forward-line 1))
      ;; Returns the list.
      line-list)))

(defun com-css-sort--next-blank-or-comment-line ()
  "Move to the next line containing nothing but whitespace or first character \
is a comment line."
  (forward-line 1)
  (while (and (not (com-css-sort--current-line-empty-p))
              (not (com-css-sort--currnet-line-not-attribute-comment-line)))
    (forward-line 1)))

(defun com-css-sort--next-non-blank-or-comment-line ()
  "Move to the next line that is exactly the code.
Not the comment or empty line."
  (forward-line 1)
  (while (and (or (com-css-sort--current-line-empty-p)
                  (com-css-sort--currnet-line-not-attribute-comment-line))
              (not (= (point) (point-max))))
    (forward-line 1)))

(defun com-css-sort--beginning-of-attribute-block (start)
  "Get the beginning of the attribute block from current point (START)."
  (goto-char start)
  (search-backward "{")
  (forward-line 1)
  (beginning-of-line)
  (point))

(defun com-css-sort--end-of-attribute-block (start)
  "Get the end of the attribute block from current point (START)."
  (goto-char start)
  (re-search-forward "[{}]")
  (forward-line -1)
  (end-of-line)
  (point))

(defun com-css-sort--insert-line-list (line-list)
  "Insert list of line, LINE-LIST."
  (save-excursion (dolist (line line-list) (insert line))))

(defun com-css-sort--swap-list-element (lst index-a index-b)
  "Swap the element by using two index.
LST : list of array to do swap action.
INDEX-A : a index of the element.
INDEX-B : b index of the element."
  (cl-rotatef (nth index-a lst) (nth index-b lst)))

(defun com-css-sort-sort-line-list-by-type-group (line-list)
  "Sort LINE-LIST into type group order."
  (let (;; List of index, corresponds to true value. (line)
        (index-list '())
        ;; Final return list.
        (return-line-list '())
        ;; List we are going to actually use it in our algorithm. This will determine
        ;; if we use the users file or use the default file.
        (real-sort-list (com-css-sort--get-ccs-file-list)))
    ;; If we could not find the user sort order config file.
    ;; We use default list then.
    (when (= 0 (length real-sort-list))
      (setq real-sort-list com-css-sort-default-attributes-order))

    (dolist (in-line line-list)
      (let ((index -1)
            (line-split-string '())
            (first-word-in-line "")
            (pure-attribute-line in-line))

        ;; Remove the possible comment, if the line is a commented attribute line.
        (setq pure-attribute-line (s-replace "/*" "" pure-attribute-line))
        (setq pure-attribute-line (s-replace "*/" "" pure-attribute-line))

        ;; Split the line to list.
        (setq line-split-string (split-string pure-attribute-line ":"))

        ;; Get the type which is usually the first word.
        (setq first-word-in-line (nth 0 line-split-string))

        ;; Trim the whitespaces or tabs.
        (setq first-word-in-line (string-trim first-word-in-line))

        (setq index (cl-position first-word-in-line real-sort-list :test 'string=))

        (if (numberp index)
            (progn
              ;; Add both index and line value to list. Treat this as a `pair'
              ;; data structure.
              (push index index-list)
              (push in-line return-line-list))
          (user-error "[WARNINGS] You try to sort an CSS attribute that does not in the sort list : %s" first-word-in-line))))

    ;; Bubble sort the elements.
    (let ((index-i 0) (flag t))
      (while (and (< index-i (- (length index-list) 1)) flag)
        (setq flag nil)
        (let ((index-j 0))
          (while (< index-j (- (- (length index-list) index-i) 1))
            (let* ((index-a index-j)
                   (index-b (1+ index-j))
                   (value-a (nth index-a index-list))
                   (value-b (nth index-b index-list)))
              (when (< value-b value-a)
                ;; Swap index.
                (com-css-sort--swap-list-element index-list index-b index-a)
                ;; Swap value with same index.
                ;; NOTE: we do this much is all because of this line of code.
                (com-css-sort--swap-list-element return-line-list index-b index-a)
                (setq flag t)))
            (setq index-j (1+ index-j))))
        (setq index-i (1+ index-i))))

    ;; Return the sorted list.
    return-line-list))

;;;###autoload
(defun com-css-sort-attributes-block (&optional no-back-to-line)
  "Sort CSS attributes in the block.
NO-BACK-TO-LINE : Do not go back to the original line."
  (interactive)
  (let ((start-ln (line-number-at-pos nil t)))
    (save-excursion
      (save-window-excursion
        ;; Ready to start sorting in the block.
        (let ((current (point))
              (start (com-css-sort--beginning-of-attribute-block (point)))
              (end (com-css-sort--end-of-attribute-block (point))))
          ;; Goto beginning of the attribute block.
          (goto-char start)

          (while (< (point) end)
            ;; Get the empty/comment block of line list for next use.
            (let ((line-list (com-css-sort--get-sort-list-until-empty-or-comment-line))
                  (end-region-point nil))
              ;; Get the current point again.
              (setq current (point))

              (when (>= (length line-list) 2)
                (save-excursion
                  (com-css-sort--next-blank-or-comment-line)

                  ;; Find the last point
                  (let ((record-point (point)))
                    (when (com-css-sort--current-line-empty-p)
                      (forward-line -1)
                      (if (string-match "}" (com-css-sort--get-current-line))
                          (beginning-of-line)
                        ;; Back to point if not true.
                        (goto-char record-point))))
                  (setq end-region-point (point)))

                ;; Delete region.
                (delete-region current end-region-point)

                ;; NOTE: Design your sort algorithms here depend on the type.
                (cl-case com-css-sort-sort-type
                  (type-sort  ; OPTION: Sort by Type Group.
                   (setq line-list (com-css-sort-sort-line-list-by-type-group line-list)))
                  (alphabetic-sort  ; OPTION: Sort by Alphabetic Order.
                   (setq line-list (sort line-list 'string<))))

                ;; Insert the lines.
                (com-css-sort--insert-line-list line-list)))

            ;; Goto next blank line or comment line.
            (com-css-sort--next-blank-or-comment-line)

            ;; Then goto next code line.
            (com-css-sort--next-non-blank-or-comment-line)))))

    (unless no-back-to-line
      (com-css-sort--goto-line start-ln)
      (end-of-line))))

;;;###autoload
(defun com-css-sort-attributes-document ()
  "Sort CSS attributes the whole documents."
  (interactive)
  (let ((start-ln (line-number-at-pos nil t)))
    (save-excursion
      (save-window-excursion
        (goto-char (point-min))
        (while (search-forward "}" nil t)
          (com-css-sort-attributes-block t)  ; Sort once.
          (com-css-sort--next-blank-or-comment-line))))
    ;; make sure go back to the starting line.
    (com-css-sort--goto-line start-ln)
    (end-of-line)))

(provide 'com-css-sort)
;;; com-css-sort.el ends here
