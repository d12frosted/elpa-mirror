;;; todotxt.el --- A major mode for editing todo.txt files

;; Filename: todotxt.el

;; Description: A major mode for editing todo.txt files

;; Author: Rick Dillon <rpdillon@killring.org>
;; Copyright (C) 2011-2020 Rick Dillon

;; Created: 14 March 2011
;; Version: 0.2.5
;; Package-Version: 20220204.1903
;; Package-Commit: ddb25fb931b4bbc1af14c4c712d412af454794c4
;; URL: https://github.com/rpdillon/todotxt.el
;; Keywords: todo.txt, todotxt, todotxt.el
;; Compatibility: GNU Emacs 22 ~ 26
;;
;; This file is NOT part of GNU Emacs

;; License:
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;; Commentary:
;; This file provides a Emacs interface to the todo.txt file format
;; use by Gina Trapani's Todo.txt command-line tool
;; (http://todotxt.com/) and Android application
;; (https://github.com/ginatrapani/todo.txt-touch).  It aims to be
;; compatible with SimpleTask
;; (https://github.com/mpcjanssen/simpletask-android) but does not yet
;; have full support for all extensions.
;;
;; Setup:
;;  - Put todotxt.el somewhere on your Emacs path
;;  - Load todotxt using (require 'todotxt) in you .emacs (or other initialization) file
;;  - Customize the variable 'todotxt-file' with the location of your todo.txt file.
;;  - View the file with M-x todotxt
;;  - Bind 'todotxt' to some accelerator like C-c t: (global-set-key (kbd "C-c t") 'todotxt)
;;
;; Usage:
;;  - Navigate up and down with 'p' and 'n' (or 'k' and 'j')
;;  - Toggle completion of an item with 'c'
;;  - Add a new item with 'a'
;;  - Tag the current item with 't' (use tab completion as necessary)
;;  - Edit the current item with 'e'
;;  - Show only incomplete items with 'i'
;;  - Filter for any keyword or tag with '/'
;;  - Filter out any keyword or tag with '\'
;;  - Revert to the version on disk with 'g' (in case you edited it elsewhere)
;;
;; See 'readme.org' for more information.
;;
;; The vast majority of the behavior of this program is governed by
;; the todo.txt formatting rules.  The can be found on the GitHub page
;; for todo.txt-cli:
;;
;; https://github.com/ginatrapani/todo.txt-cli/wiki/The-Todo.txt-Format

(defgroup todotxt nil "Todotxt is an Emacs utility to manage todo.txt files.")
;; Variables that are available for customization

(defcustom todotxt-file (expand-file-name "~/todo.txt")
  "The location of your todo.txt file."
  :type 'string
  :require 'todotxt
  :group 'todotxt)

(defcustom todotxt-use-creation-dates  't
  "If non-nil, include creation dates for newly added items.
Defaults to 't."
  :type 'boolean
  :require 'todotxt
  :group 'todotxt)

(defcustom todotxt-save-after-change  't
  "If non-nil, the file is saved after any operation is
performed.  Defaults to 't."
  :type 'boolean
  :require 'todotxt
  :group 'todotxt)

(setq todotxt-tags-regexp "[+|@][[:graph:]]+") ; Used to find keywords for completion
(setq todotxt-projects-regexp "+[[:graph:]]+")
(setq todotxt-contexts-regexp "@[[:graph:]]+")
(setq todotxt-complete-regexp "^x .*?$")
(setq todotxt-priority-regexp "^(\\([A-Z]\\)) .*?$")
(setq todotxt-priority-a-regexp "^\\((A)\\) .*?$")
(setq todotxt-priority-b-regexp "^\\((B)\\) .*?$")
(setq todotxt-priority-c-regexp "^\\((C)\\) .*?$")
(setq todotxt-variable-regexp ":\\([^\s]+\\)")

(setq todotxt-active-filters '())

;; Font Lock and Faces
(defface todotxt-complete-face '(
  (t (:strike-through t)))
  "Todotxt face used for completed task."
  :group 'todotxt-highlighting-faces)

(defvar todotxt-complete-face 'todotxt-complete-face
  "Todotxt mode face used for completed task.")

(defface todotxt-priority-a-face '(
  (((class color) (background dark)) (:foreground "red"))
  (((class color) (background light)) (:foreground "red"))
  (t (:bold t)))
  "Todotxt mode face used for tasks with a priority of A."
  :group 'todotxt-highlighting-faces)

(defvar todotxt-priority-a-face 'todotxt-priority-a-face
  "Todotxt mode face used for tasks with a priority of A.")

(defface todotxt-priority-b-face '(
  (((class color) (background dark)) (:foreground "orange"))
  (((class color) (background light)) (:foreground "dark orange"))
  (t (:bold t)))
  "Todotxt mode face used for tasks with a priority of B."
  :group 'todotxt-highlighting-faces)

(defvar todotxt-priority-b-face 'todotxt-priority-b-face
  "Todotxt mode face used for tasks with a priority of B.")

(defface todotxt-priority-c-face '(
  (((class color) (background dark)) (:foreground "yellow"))
  (((class color) (background light)) (:foreground "gold"))
  (t (:bold t)))
  "Todotxt mode face used for tasks with a priority of C."
  :group 'todotxt-highlighting-faces)

(defvar todotxt-priority-c-face 'todotxt-priority-c-face
  "Todotxt mode face used for tasks with a priority of C.")

(setq todotxt-highlight-regexps
      `((,todotxt-projects-regexp   0 font-lock-variable-name-face t)
        (,todotxt-contexts-regexp   0 font-lock-keyword-face t)
        (,todotxt-complete-regexp   0 todotxt-complete-face t)
        (,todotxt-priority-a-regexp 1 todotxt-priority-a-face t)
        (,todotxt-priority-b-regexp 1 todotxt-priority-b-face t)
        (,todotxt-priority-c-regexp 1 todotxt-priority-c-face t)))

;; Setup a major mode for todotxt
;;;###autoload
(define-derived-mode todotxt-mode text-mode "todotxt"
  "Major mode for working with todo.txt files. \\{todotxt-mode-map}"
  (setq font-lock-defaults '(todotxt-highlight-regexps))
  (setq goal-column 0)
  (auto-revert-mode)
  (setq buffer-read-only t))

;; Setup key map
(define-key todotxt-mode-map (kbd "l")   'todotxt-unhide-all)      ; (L)ist
(define-key todotxt-mode-map (kbd "i")   'todotxt-show-incomplete) ; list (I)ncomplete
(define-key todotxt-mode-map (kbd "c")   'todotxt-complete-toggle) ; (C)omplete item
(define-key todotxt-mode-map (kbd "N")   'todotxt-nuke-item)       ; (N)uke item
(define-key todotxt-mode-map (kbd "a")   'todotxt-add-item)        ; (A)dd item
(define-key todotxt-mode-map (kbd "q")   'todotxt-bury)            ; (Q)uit
(define-key todotxt-mode-map (kbd "r")   'todotxt-add-priority)    ; Add p(r)iority
(define-key todotxt-mode-map (kbd "A")   'todotxt-archive)         ; (A)rchive completed items
(define-key todotxt-mode-map (kbd "e")   'todotxt-edit-item)       ; (E)dit item
(define-key todotxt-mode-map (kbd "t")   'todotxt-tag-item)        ; (T)ag item
(define-key todotxt-mode-map (kbd "d")   'todotxt-add-due-date)    ; (D)ue date
(define-key todotxt-mode-map (kbd "/")   'todotxt-filter-for)      ;
(define-key todotxt-mode-map (kbd "\\")  'todotxt-filter-out)      ;
(define-key todotxt-mode-map (kbd "g")   'todotxt-revert)          ; Revert the buffer
(define-key todotxt-mode-map (kbd "s")   'save-buffer)             ; (S)ave
(define-key todotxt-mode-map (kbd "u")   'todotxt-undo)            ; (U)ndo
(define-key todotxt-mode-map (kbd "n")   'next-line)               ; (N)ext
(define-key todotxt-mode-map (kbd "p")   'previous-line)           ; (P)revious
(define-key todotxt-mode-map (kbd "j")   'next-line)               ; Vi Binding
(define-key todotxt-mode-map (kbd "k")   'previous-line)           ; Vi Binding
(define-key todotxt-mode-map (kbd "?")   'describe-mode)           ; Help!
(define-key todotxt-mode-map (kbd "h")   'describe-mode)           ; Help!

;; Utility functions
(defun todotxt-current-line-re-match (re)
  "Test whether or not the current line contains text that
matches the provided regular expression"
  (let ((line-number (line-number-at-pos)))
    (save-excursion
      (beginning-of-line)
      (if (re-search-forward re nil 't)
          (equal line-number (line-number-at-pos))
        nil))))

(defun todotxt-current-line-match (s)
  "Test whether or not the current line contains text that
matches the provided string"
  (let ((line-number (line-number-at-pos)))
    (save-excursion
      (beginning-of-line)
      (if (search-forward s nil 't)
          (equal line-number (line-number-at-pos))
        nil))))

(defun todotxt-complete-p ()
  "Returns whether or not the current line is 'complete'. Used as
part of a redefined filter for showing incomplete items only"
  (todotxt-current-line-re-match todotxt-complete-regexp))

(defun todotxt-get-priority (str)
  "If the current item has a priority, return it as a string.
Otherwise, return nil."
  (let* ((idx (string-match todotxt-priority-regexp str)))
    (if idx
        (match-string-no-properties 1 str)
      nil)))

(defun todotxt-remove-overlays ()
  "Remove 'invisible overlay, without affecting other overlays."
  (remove-overlays (point-min) (point-max) 'invisible 't))

(defun todotxt-hide-line ()
  "Hides the current line, returns 't"
  (beginning-of-line)
  (let ((beg (point)))
    (forward-line)
    (let ((overlay (make-overlay beg (point))))
      (overlay-put overlay 'invisible 't))
    't))

(defun todotxt-line-empty-p ()
  "Returns whether or not the current line is empty."
  (save-excursion
    (beginning-of-line)
    (let ((b (point)))
      (end-of-line)
      (equal (point) b))))

(defun todotxt-jump-to-item (item)
  "Given the full text of an item, moves the point to the
beginning of the line containing that item."
  (todotxt-find-first-visible-char)
  (search-forward item)
  (beginning-of-line)
  (todotxt-find-first-visible-char))

(defun todotxt-find-first-visible-char ()
  "Move the point to the first visible character in the buffer."
  (goto-char (point-min))
  (todotxt-find-next-visible-char))

(defun todotxt-find-next-visible-char ()
  "Move the point to the next character in the buffer that does
not have an overlay applied to it.  This function exists to
address an odd bug in which the point can exist at (point-min)
even though it is invisible.  This usually needs to be called
after items are filtered in some way, but perhaps in other case
as well."
  (let ((pos (point)))
    (while (and (invisible-p pos) (< pos (point-max)))
      (setq pos (1+ pos)))
    (goto-char pos)))

(defun todotxt-filter (predicate)
  "Hides lines for which the provided predicate returns 't.  This
is our main filtering function that all others call to do their
work."
  (goto-char (point-min))
  (while (progn
           (if (and (not (todotxt-line-empty-p)) (funcall predicate))
               (todotxt-hide-line)
             (equal (forward-line) 0))))
  (todotxt-find-first-visible-char)
  (if (not (member predicate todotxt-active-filters))
      (setq todotxt-active-filters (cons predicate todotxt-active-filters))))

(defun todotxt-apply-active-filters ()
  (defun inner-loop (filters)
    (if (not (equal filters nil))
        (progn
          (todotxt-filter (car filters))
          (inner-loop (cdr filters)))))
  (inner-loop todotxt-active-filters)
  (todotxt-find-first-visible-char))

(defun todotxt-get-tag-completion-list-from-string (str)
  "Search the buffer for tags (strings beginning with either '@'
or '+') and return a list of them."
  (save-excursion
    (let ((completion-list '())
          (start-index 0))
      (while (string-match todotxt-tags-regexp str start-index)
        (let ((tag (match-string-no-properties 0 str)))
          (if (not (member tag completion-list))
              (progn
                (setq completion-list (cons tag completion-list))))
          (setq start-index (match-end 0))))
      completion-list)))

(defun todotxt-get-current-line-as-string ()
  "Return the text of the line in which the point currently
resides."
  (let* ((current-line (save-excursion
			 (beginning-of-line)
			 (todotxt-find-next-visible-char)
			 (let ((beg (point)))
			   (end-of-line)
			   (buffer-substring beg (point))))))
    (when (string= "" current-line)
      (error "The current line was resolved to be empty - this should not happen."))
    current-line))

(defun todotxt-sort-key-for-string (str)
  (let* ((due-date (or (todotxt-get-variable str "due") "9999-99-99"))
         (priority (or (todotxt-get-priority str) "a"))
         (key (concat due-date " " priority)))
    key))

(defun todotxt-get-due-priority-sort-key ()
  (let* ((line (todotxt-get-current-line-as-string)))
    (todotxt-sort-key-for-string line)))

(defun todotxt-prioritize (sort-key-fun)
  "Prioritize the list according to provided sort key function.
  The sort key function should return the key used to sort records."
  (todotxt-remove-overlays)
  (let ((nextrecfun 'forward-line)
        (endrecfun 'end-of-line))
    (let ((origin (point)))
      (goto-char (point-min))
      (setq inhibit-read-only 't)
      (sort-subr nil nextrecfun endrecfun sort-key-fun)
      (todotxt-apply-active-filters)
      (goto-char origin))
    (setq inhibit-read-only nil)))

(defun todotxt-get-formatted-date ()
  "Returns a string with the date formatted in standard todo.txt
format."
  (format-time-string "%Y-%m-%d"))

(defun todotxt-get-variable (str variable)
  "Reads the provided string for the specified variable"
  (let* ((var-regexp (concat variable todotxt-variable-regexp))
         (match-start (string-match var-regexp str))
         (data (match-data))
         (value-start (nth 2 data))
         (value-end (nth 3 data)))
    (if (or (eq match-start nil)
            (> match-start (length str)))
        nil
      (substring str value-start value-end))))

(defun todotxt-set-variable (str variable value)
  "Parses the provided string, setting the specified variable to
  the provided value, replacing the existing variable if
  necessary."
  (let* ((declaration (concat variable ":" value))
         (var-regexp (concat variable todotxt-variable-regexp))
         (var-start (string-match var-regexp str))
         (var-end (match-end 0)))
    (if (eq var-start nil)
        (concat str " " declaration)
      (let ((head (substring str 0 var-start))
            (tail (substring str var-end)))
        (concat head declaration tail)))))

(defun todotxt-delete-line ()
  "Delete whole current line up to newline."
  (beginning-of-line)
  (delete-region (point) (line-end-position)))

;;; externally visible functions
;;;###autoload
(defun todotxt ()
  "Open the todo.txt buffer.  If one already exists, bring it to
the front and focus it.  Otherwise, create one and load the data
from 'todotxt-file'."
  (interactive)
  (let* ((buf (find-file-noselect todotxt-file))
         (win (get-buffer-window buf 't)))
    (if (equal win nil)
        (progn
          (let* ((height (nth 3 (window-edges)))
            (nheight (- height (/ height 3)))
            (win (split-window (selected-window) nheight)))
          (select-window win)
          (switch-to-buffer buf)
          (todotxt-mode)
          (todotxt-prioritize 'todotxt-get-due-priority-sort-key)))
      (progn
        (select-window win)
        (select-frame-set-input-focus (selected-frame))))
    (todotxt-find-first-visible-char)))

(defun todotxt-revert ()
  "Revert the contents of the todotxt buffer."
  (interactive)
  (revert-buffer nil 't 't)
  (setq buffer-read-only 't))

(defun todotxt-undo ()
  "Undo the last changes to the buffer"
  (interactive)
  (setq inhibit-read-only 't)
  (undo)
  (setq inhibit-read-only 'nil))

(defun todotxt-show-incomplete ()
  "Filter out complete items from the todo list."
  (interactive)
  (todotxt-filter 'todotxt-complete-p))

(defun todotxt-nuke-item ()
  "Deletes the current item without passing Go or collecting
$200"
  (interactive)
  (setq inhibit-read-only 't)
  (beginning-of-line)
  ; So begins the dance to get the /real/ beginning of line
  ; TODO: if this is needed elsewhere, pull it up into a function
  (forward-char)
  (backward-char)
  (let ((beg (point)))
    (end-of-line)
    (forward-char)
    (delete-region beg (point)))
  (setq inhibit-read-only nil))

(defun todotxt-add-item (item)
  "Prompt for an item to add to the todo list and append it to
the file, saving afterwards."
  (interactive "sItem to add: ")
  (setq inhibit-read-only 't)
  (goto-char (point-max))
  (insert (concat
           (if todotxt-use-creation-dates
               (concat (todotxt-get-formatted-date) " "))
           item "\n"))
  (todotxt-prioritize 'todotxt-get-due-priority-sort-key)
  (if todotxt-save-after-change (save-buffer))
  (setq inhibit-read-only nil)
  (todotxt-jump-to-item item))

(defun todotxt-add-priority ()
  "Prompts for a priority from A-Z to be added to the current
item.  If the item already has a priority, it will be replaced.
If the supplied priority is lower case, it will be made upper
case.  If the input is the empty string, no priority will be
added, and if the item already has a priority, it will be
removed."
  (interactive)
  (let ((priority (read-from-minibuffer "Priority: ")))
    (if (or (and (string-match "[A-Z]" priority) (equal (length priority) 1))
            (equal priority ""))
      (save-excursion
        (setq inhibit-read-only 't)
        (if (todotxt-get-priority (todotxt-get-current-line-as-string))
            (progn
              (beginning-of-line)
              (delete-char 4)))
        (if (not (equal priority ""))
            (progn
              (beginning-of-line)
              (insert (concat "(" (upcase priority) ") "))
              (setq inhibit-read-only nil)))
        (todotxt-prioritize 'todotxt-get-due-priority-sort-key)
        (if todotxt-save-after-change (save-buffer)))
      (error "%s is not a valid priority.  Try a letter between A and Z." priority))))

(defun todotxt-edit-item ()
  (interactive)
  (save-excursion
    (let ((new-text (read-from-minibuffer "Edit: " (todotxt-get-current-line-as-string))))
      (setq inhibit-read-only 't)
      (todotxt-delete-line)
      (insert new-text)
      (todotxt-prioritize 'todotxt-get-due-priority-sort-key)
      (if todotxt-save-after-change (save-buffer))
      (setq inhibit-read-only nil))))

(defun todotxt-tag-item ()
  (interactive)
  (let* ((new-tag (completing-read "Tags: " (todotxt-get-tag-completion-list-from-string
                                             (concat (todotxt-archive-file-contents) (buffer-string)))))
         (new-text (concat (todotxt-get-current-line-as-string) " " new-tag)))
    (setq inhibit-read-only 't)
    (todotxt-delete-line)
    (insert new-text)
    (if todotxt-save-after-change (save-buffer))
    (setq inhibit-read-only nil)))

(defun todotxt-add-due-date ()
  (interactive)
  (require 'org)
  (let* ((current-line (todotxt-get-current-line-as-string))
        (current-date (todotxt-get-variable current-line "due"))
        (date (org-read-date))
        (new-line (todotxt-set-variable current-line "due" date)))
    (setq inhibit-read-only 't)
    (todotxt-delete-line)
    (insert new-line)
    (todotxt-prioritize 'todotxt-get-due-priority-sort-key)
    (if todotxt-save-after-change (save-buffer))
    (setq inhibit-read-only nil)))

(defun todotxt-transpose-lines (&optional backward)
  (todotxt-find-next-visible-char)
  (let* ((current-line-number (line-number-at-pos))
         (current-line-string (todotxt-get-current-line-as-string))
         (dest-line-number (save-excursion
                             (line-move-visual (if backward -1 1) t)
                             (todotxt-find-next-visible-char)
                             (line-number-at-pos)))
         (range (- dest-line-number current-line-number))
         (dest-line-string (buffer-substring (point-at-bol (1+ range)) (point-at-eol (1+ range)))))
    (when (and
           (not (zerop range))
           (not (equal current-line-string ""))
           (not (equal dest-line-string ""))
           (equal
            (todotxt-sort-key-for-string current-line-string)
            (todotxt-sort-key-for-string dest-line-string)))
      (beginning-of-line)
      (save-excursion
        (todotxt-remove-overlays)
        (forward-line)
        (setq inhibit-read-only t)
        (transpose-lines range)
        (setq inhibit-read-only nil)
        (todotxt-apply-active-filters))
      (todotxt-find-next-visible-char)
      (forward-line (if backward -1 1)))))

(defun todotxt-transpose-lines-up ()
  (interactive)
  (todotxt-transpose-lines t))

(defun todotxt-transpose-lines-down ()
  (interactive)
  (todotxt-transpose-lines))

(defun todotxt-archive-file-name ()
  (concat (file-name-directory todotxt-file) "/done.txt"))

(defun todotxt-archive-file-contents ()
  (let ((todo-buffer (current-buffer)))
    (save-current-buffer
      (set-buffer (find-file-noselect (todotxt-archive-file-name)))
      (buffer-string))))

(defun todotxt-archive ()
  (interactive)
  (save-excursion
    (todotxt-remove-overlays)
    (goto-char (point-min))
    (setq inhibit-read-only 't)
    (while (progn
             (if (and (not (todotxt-line-empty-p)) (todotxt-complete-p))
                 (progn
                   (beginning-of-line)
                   (let ((beg (point)))
                     (forward-line)
                     (append-to-file beg (point) (todotxt-archive-file-name)))
                     (previous-line)
                     (kill-line 1)
                   't)
               (equal (forward-line) 0))))
    (if todotxt-save-after-change (save-buffer))
    (todotxt-apply-active-filters)
    (setq inhibit-read-only nil)))

(defun todotxt-bury ()
  (interactive)
  (bury-buffer)
  (delete-window))

(defun todotxt-unhide-all ()
  (interactive)
  (todotxt-remove-overlays)
  (setq todotxt-active-filters '()))

(defun todotxt-filter-for (arg)
  "Filters the todo list for a specific tag or keyword.  Projects
and contexts should have their preceding '+' and '@' symbols,
respectively, if tab-completion is to be used."
  (interactive "p")
  (let* ((keyword (completing-read "Filter for tag or keyword: " (todotxt-get-tag-completion-list-from-string (buffer-string)))))
    (if (equal arg 4)
        (todotxt-unhide-all))
    (goto-char (point-min))
    ; The contortions are to work around the lack of closures
    (todotxt-filter (eval `(lambda () (not (todotxt-current-line-match ,keyword)))))))

; Should probably be combined with filter-for
; TODO: evaluate utility of filter-for unhide-all functionality as a
; possible place for this to go
(defun todotxt-filter-out (arg)
  (interactive "p")
  (let* ((keyword (completing-read "Filter out tag or keyword: " (todotxt-get-tag-completion-list-from-string (buffer-string)))))
    (save-excursion
      (if (equal arg 4)
          (todotxt-unhide-all))
      (goto-char (point-min))
      ; The contortions are to work around the lack of closures
      (todotxt-filter (eval `(lambda () (todotxt-current-line-match ,keyword)))))))

(defun todotxt-complete-toggle ()
  "Toggles the complete state for the item under the point. In
accordance with the spec, this also adds a completion date to
completed items, and removes it if the item is being change to a
'not completed' state."
  (interactive)
  (setq inhibit-read-only 't)
  (if (todotxt-complete-p)
      (progn
        (beginning-of-line)
        (delete-char 2)
        (save-excursion
          (if (re-search-forward
               "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"
               (+ (point) 11))
              (progn
                (beginning-of-line)
                (delete-char 11)))))
    (progn
      (beginning-of-line)
      ; This isn't in the spec, but the CLI version removes priorities
      ; upon completion.  It's problematic, because there's no good
      ; way to put them back if you toggle completion back to "not
      ; done".
      (if (todotxt-get-priority (todotxt-get-current-line-as-string))
              (delete-char 4))
      (insert (concat "x " (todotxt-get-formatted-date) " "))
      (beginning-of-line)))
  (todotxt-prioritize 'todotxt-get-due-priority-sort-key)
  (setq inhibit-read-only nil)
  (if todotxt-save-after-change (save-buffer)))

(provide 'todotxt)

;;; todotxt.el ends here
