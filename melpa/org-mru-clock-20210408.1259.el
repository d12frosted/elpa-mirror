;;; org-mru-clock.el --- Clock in/out of tasks with completion and persistent history -*- lexical-binding: t -*-

;; Copyright (C) 2016--2021 Kevin Brubeck Unhammer

;; Author: Kevin Brubeck Unhammer <unhammer@fsfe.org>
;; Version: 0.6.0
;; Package-Version: 20210408.1259
;; Package-Commit: 229461b92ff89fd96cd7730df9fd589a8b0ef949
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/unhammer/org-mru-clock
;; Keywords: convenience, calendar

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Do you often clock in to many different little tasks? Are you
;;; annoyed that you can't just clock in to one of your most recent
;;; tasks after restarting Emacs? This package replaces functions like
;;; `org-clock-select-task' and `org-clock-in-last' with functions
;;; `org-mru-clock-select-recent-task' and `org-mru-clock-in', which
;;; first ensure that `org-clock-history' is filled with your
;;; `org-mru-clock-how-many' most recent tasks, and let you pick from
;;; a list before clocking in.

;;; It also uses `completing-read-function' (overridable with
;;; `org-mru-clock-completing-read') on `org-mru-clock-in' to make
;;; clocking in even faster.

;;; To use, require and bind whatever keys you prefer to the
;;; interactive functions:
;;;
;;; (require 'org-mru-clock)
;;; (global-set-key (kbd "C-c C-x i") #'org-mru-clock-in)
;;; (global-set-key (kbd "C-c C-x C-j") #'org-mru-clock-select-recent-task)
;;;
;;; Maybe trade some initial slowness for more tasks cached:
;;;
;;; (setq org-mru-clock-how-many 100)
;;;
;;; But don't set it higher than the actual number of tasks; then
;;; it'll always try (and fail) to fill up the history cache!

;;; If you want to use ivy for `org-mru-clock-in':
;;;
;;; (setq org-mru-clock-completing-read #'ivy-completing-read)
;;;

;;; If you prefer `use-package', the above settings would be:
;;;
;;; (use-package org-mru-clock
;;;   :ensure t
;;;   :bind* (("C-c C-x i" . org-mru-clock-in)
;;;           ("C-c C-x C-j" . org-mru-clock-select-recent-task))
;;;   :init
;;;   (setq org-mru-clock-how-many 100
;;;         org-mru-clock-completing-read #'ivy-completing-read))

;;; You may also be interested in these general org-clock settings:
;;;
;;; (setq org-clock-persist t)
;;; (org-clock-persistence-insinuate)


;;; Code:

(require 'org-clock)
(require 'org-capture)
(require 'cl-lib)

(defgroup org-mru-clock nil
  "Options for org-mru-clock"
  :tag "org-mru-clock"
  :group 'org)

(defcustom org-mru-clock-how-many 20
  "Default number of clock entries to look up with `org-mru-clock'.
This can be a bit slow the first time due to deduplication, but
the interactive functions cache the clocks to
`org-clock-history', and don't look up clocks if that variable
has enough entries."
  :group 'org-mru-clock
  :type 'integer)

(defcustom org-mru-clock-completing-read completing-read-function
  "A `completing-read-function', but only used in `org-mru-clock' functions.
Popular choices include
`ivy-completing-read', `ido-completing-read', `selectrum-completing-read'
and `helm--completing-read-default' (don't use `helm-comp-read' –
it doesn't conform to the `completing-read' API)"
  :group 'org-mru-clock
  :type 'function)

(defcustom org-mru-clock-include-entry-at-point t
  "If point is at an org headline, include it as the top choice."
  :group 'org-mru-clock
  :type 'boolean)

(defcustom org-mru-clock-format-function #'substring-no-properties
  "Function to alter formatting of an entry in the clock-in list.
The function is called in the org buffer with point at the
relevant heading.  Set to `substring' to keep faces (and other
properties) from entries before showing them (showing entries
using the faces they had in the org file).  With the default
`substring-no-properties', use whatever faces the
`org-mru-clock-completing-read' function applies."
  :group 'org-mru-clock
  :type 'function)

(make-obsolete-variable 'org-mru-clock-keep-formatting
                        "use org-mru-clock-format-function instead"
                        "0.5.0")

(defcustom org-mru-clock-predicate nil
  "Function returning nil when the task at point should be excluded.
If it returns non-nil, the task may be included in the clock
history.  If this variable is nil, all previously clocked tasks
in `org-mru-clock-files' are included.

To include only TODO tasks, set it to `org-entry-is-todo-p'.  To
exclude DONE and ARCHIVED, set it to
`org-mru-clock-exclude-done-and-archived'.  Note that this can
affect speed, if you have large org files."
  :group 'org-mru-clock
  :type '(choice (const nil) function))

(defcustom org-mru-clock-files #'org-files-list
  "Function returning org files to look for tasks in.
You may want to set this to `org-agenda-files' to only include
agenda files, or you can use your own file filter."
  :group 'org-mru-clock
  :type 'function)

(defun org-mru-clock-exclude-done-and-archived ()
  "Example function for `org-mru-clock-predicate', excluding DONE and :ARCHIVE:."
  (not (or (org-entry-is-done-p)
           (member org-archive-tag (org-get-tags)))))

(defun org-mru-clock-take (n l)
  "Take N elements from list L."
  (let (ret)
    (while (and l (> n 0))
      (push (car l) ret)
      (cl-decf n)
      (setq l (cdr l)))
    (reverse ret)))

(defun org-mru-clock-heading-marker (marker)
  "Turn MARKER into a marker of the heading at that spot.
Used for uniquifying `org-mru-clock'."
  (when (marker-buffer marker)
    (with-current-buffer (org-base-buffer (marker-buffer marker))
      (save-excursion
        (save-restriction
          (widen)
          (ignore-errors
            (goto-char marker)
            (org-back-to-heading t)
            (let ((m (point-marker)))
              ;; in hash maps at least, #'equal doesn't work for
              ;; markers, so extract only what's relevant:
              (cons (marker-position m)
                    (marker-buffer m)))))))))

(defun org-mru-clock--find-clocks (file)
  "Search through the given FILE and find all open clocks."
  (let ((buf (or (get-file-buffer file)
                 (find-file-noselect file)))
        (org-clock-re (concat org-clock-string " \\(\\[.*?\\]\\)"))
        clocks)
    (with-current-buffer buf
      (org-with-wide-buffer
       (save-excursion
         (goto-char (point-min))
         (while (re-search-forward org-clock-re nil t)
           (when (org-mru-clock--predicate)
             (push (cons (copy-marker (match-end 1) t)
                         (org-time-string-to-time (match-string 1)))
                   clocks))))))
    clocks))

(defun org-mru-clock--predicate (&optional marker)
  "Call `org-mru-clock-predicate' if set, restoring point and match data.
Default to t if not set.  If MARKER, first go to the marker."
  (if (functionp org-mru-clock-predicate)
      (save-match-data
        (save-excursion
          (if marker
              (with-current-buffer (marker-buffer marker)
                (goto-char marker)
                (funcall org-mru-clock-predicate))
            (funcall org-mru-clock-predicate))))
    t))

(defun org-mru-clock-take-uniq (n l key test)
  "Take the N first elements from L, skipping duplicates.
Elements are duplicates if KEY of each element is equal under TEST."
  (let* ((seen (make-hash-table :test test :size n))
         ret
         (_was-trimmed (catch 'done
                         (dolist (e l)
                           (let ((k (funcall key e)))
                             (unless (gethash k seen)
                               (push e ret))
                             (puthash k e seen))
                           (when (>= (hash-table-count seen) n)
                             (throw 'done t))))))
    (reverse ret)))

(defun org-mru-clock (&optional n)
  "Find N most recently used clocks in `org-mru-clock-files'.
N defaults to `org-mru-clock-how-many'."
  (unless org-clock-resolving-clocks
    (let* ((org-clock-resolving-clocks t)
           (n (or n org-mru-clock-how-many))
           (clocks (cl-mapcan #'org-mru-clock--find-clocks (funcall org-mru-clock-files)))
           (sort-pred (lambda (a b) (time-less-p (cdr b)
                                            (cdr a))))
           (sorted (mapcar #'car (sort clocks sort-pred)))
           (uniq (org-mru-clock-take-uniq
                  n
                  sorted
                  #'org-mru-clock-heading-marker
                  #'equal)))
      (org-mru-clock-take n uniq))))

;;;###autoload
(defun org-mru-clock-to-history (&optional n)
  "Ensure `org-clock-history' filled with agenda tasks.
Optional argument N as in `org-mru-clock'."
  (interactive "P")
  (require 'cl-lib)
  (let ((n (cond ((and n (listp n)) (car n))
                 ((numberp n) n)
                 (t org-mru-clock-how-many)))
        (history (cl-remove-if-not (lambda (m) (and (marker-buffer m)
                                                    (org-mru-clock--predicate m)))
                               org-clock-history)))
    (setq org-clock-history (if (< (length history) n)
                                (org-mru-clock n)
                              history))))

(defun org-mru-clock-select-workaround-history ()
  "Workaround bug in `org-clock-select-task'.
That function reuses letters ?c ?i ?d for history, but they are
reserved for current/interrupted/default tasks.  So truncate
history so we only get values up until the letter ?b.  If the bug
gets fixed upstream, we could add a check for `org-version' here
to return the full history."
  (seq-take org-clock-history 43))

;;;###autoload
(defun org-mru-clock-select-recent-task (&optional n)
  "Select a task that was recently associated with clocking.
Like `org-clock-select-task', but ensures `org-clock-history' is
filled first.  Optional argument N as in `org-mru-clock'."
  (interactive "P")
  (org-mru-clock-to-history n)
  (let* ((org-clock-history (org-mru-clock-select-workaround-history))
         (m (org-clock-select-task "Select recent task: ")))
    (when m
      (switch-to-buffer (marker-buffer m))
      (goto-char (marker-position m))
      (org-up-element)
      (org-show-subtree))))

(defun org-mru-clock-format-entry ()
  "Return the parent heading string appended to the heading at point."
  (let* ((this (org-get-heading 'no-tags 'no-todo))
         (parent
          (save-excursion
            (org-up-heading-safe)
            (org-get-heading 'no-tags 'no-todo)))
         (parent-post (if parent
                          (format " (%s)" parent)
                        ""))
         (with-parent (concat this parent-post)))
    (funcall org-mru-clock-format-function with-parent)))

(defcustom org-mru-clock-capture-if-no-match nil
  "If non-nil, `org-capture' a new task on non-matching input.
If no task matches when doing `org-mru-clock-in', we may create a
new one if this is non-nil.  The value should be an ordered
association of regexes to a key from `org-capture-templates',
e.g.

 (setq org-mru-clock-capture-if-no-match '((\"^[0-9]+ \" . \"a\")
                                           (\".*\" . \"b\")))

will capture anything that starts with a number followed by space
with the \"a\" template, and anything else with the \"b\"
template.  The first matching regex is used.

If you only use the key \"a\" for tasks captured with
org-mru-clock, you may want to add it to
`org-capture-templates-contexts' with `org-mru-clock-capturing',
e.g.

 (setq org-capture-templates-contexts
       '((\"a\" (org-mru-clock-capturing)))"
  :group 'org-mru-clock
  :type '(alist :key-type string :value-type string))

(defvar org-mru-clock--capturing nil
  "This is true while we are capturing a new task.")

(defun org-mru-clock-capturing ()
  "Return non-nil iff we are capturing a new task.
For use as an `org-capture-templates-contexts' for the templates
in your `org-mru-clock-capture-if-no-match'."
  org-mru-clock--capturing)

(defun org-mru-clock--capture (initial)
  "Create a new task from the text entered.
Match INITIAL using `org-mru-clock-capture-if-no-match' and use
that as the %i capture text."
  (let (matched)
    (cl-loop for c
             in org-mru-clock-capture-if-no-match
             until matched
             do
             (when (string-match-p (car c) initial)
               (setq matched t)
               (let ((org-capture-initial initial)
                     (org-mru-clock--capturing t))
                 (org-capture nil (cdr c)))))
    (unless matched
      (error "`org-mru-clock--capture' called, but `org-mru-clock-capture-if-no-match' is nil"))))

(defun org-mru-clock--clock-in-on-marker (marker)
  "Go to MARKER and clock in to the task there.
May temporarily widen the buffer."
  (with-current-buffer
      (org-base-buffer (marker-buffer marker))
    (org-with-wide-buffer
     (goto-char (marker-position marker))
     (org-clock-in))))

(defun org-mru-clock--clock-in (task)
  "Clock into the TASK.

TASK is a cons of description and marker if existing, otherwise a
string."
  (pcase task
    ("" ;; No input, assume user wants to cancel
     nil)
    ((pred stringp)
     (org-mru-clock--capture task)
     ;; If we immediately finish, `org-capture-finalize' will store a
     ;; marker for us. Otherwise, the above puts us in the CAPTURE
     ;; buffer, so now we can simply clock in. If there was an error
     ;; in capturing, the below won't even execute.
     (if (org-capture-get :immediate-finish)
         (org-mru-clock--clock-in-on-marker org-capture-last-stored-marker)
       (org-clock-in)))
    (`(,h . ,m)
     (org-mru-clock--clock-in-on-marker m))
    (_
     (error (format "org-mru-clock--clock-in called with TASK of unexpected type: %S"
                    task)))))

(defun org-mru-clock-goto (task)
  "Go to buffer and position of the TASK (cons of description and marker)."
  (interactive (list (org-mru-clock--completing-read)))
  (let ((m (cdr task)))
    (switch-to-buffer (org-base-buffer (marker-buffer m)))
    (if (or (< m (point-min)) (> m (point-max))) (widen))
    (goto-char m)
    (org-show-entry)
    (org-back-to-heading t)
    (org-cycle-hide-drawers 'children)
    (org-reveal)))

(defun org-mru-clock-add-note (task)
  "Add a time-stamped note to TASK (cons of description and marker)."
  (interactive (list (org-mru-clock--completing-read)))
  (let* ((marker (cdr task))
	 (buffer (marker-buffer marker))
	 (pos (marker-position marker))
	 (inhibit-read-only t))
    (with-current-buffer buffer
      (widen)
      (goto-char pos)
      (org-show-context 'agenda)
      (org-add-note))))

(defun org-mru-clock-add-backlink (task)
  "Add a link back to current location to TASK (cons of description and marker)."
  (interactive (list (org-mru-clock--completing-read)))
  (let* ((link (org-store-link nil))
         (marker (cdr task))
	 (buffer (marker-buffer marker))
	 (pos (marker-position marker))
	 (inhibit-read-only t))
    (with-current-buffer buffer
      (widen)
      (goto-char pos)
      (org-show-context 'agenda)
      (org-end-of-meta-data 'full)
      (insert "\n")
      (backward-char 1)
      (indent-for-tab-command)
      (insert link)
      (message "Stored a link under %s" (car task)))))

(defun org-mru-clock-show-narrowed (task)
  "Show TASK (cons of description and marker) narrowed."
  (interactive (list (org-mru-clock--completing-read)))
  (let ((window (selected-window))
        (buffer (save-window-excursion
                  ;; TODO: &optional noselect in org-mru-clock-goto
                  ;; so we don't have to do this dance?
                  (org-mru-clock-goto task)
                  (current-buffer))))
    (pop-to-buffer buffer)
    (org-narrow-to-subtree)
    (select-window window)))

(eval-after-load 'ivy
  '(ivy-set-actions 'org-mru-clock-in
                    '(("g" org-mru-clock-goto "goto")
                      ("z" org-mru-clock-add-note "note")
                      ("SPC" org-mru-clock-show-narrowed "show")
                      ("l" org-mru-clock-add-backlink "link"))))

(defvar org-mru-clock--actions
  (let ((map (make-sparse-keymap)))
    (define-key map "g" #'org-mru-clock-goto)
    (define-key map "z" #'org-mru-clock-add-note)
    (define-key map " " #'org-mru-clock-show-narrowed)
    (define-key map "l" #'org-mru-clock-add-backlink)
    map))

(defun org-mru-clock-embark-minibuffer-hook ()
  "Add to `minibuffer-setup-hook' if using Embark."
  (when (eq this-command 'org-mru-clock-in)
    (setq-local embark-overriding-keymap org-mru-clock--actions)))

(eval-when-compile
  ;; Ensure we can dynamically let-bind this even when compiled with lexical-let
  (defvar selectrum-should-sort-p))

(defun org-mru-clock--completing-read ()
  "Pick a task using `org-mru-clock-completing-read'."
  (when (eq org-mru-clock-completing-read #'helm-comp-read)
    (error "Please set org-mru-clock-completing-read to helm--completing-read-default (helm-comp-read not supported)"))
  (let ((require-match (not org-mru-clock-capture-if-no-match))
        (collection (org-mru-clock--collection))
        ;; Ensure we keep our mru sort order:
        (selectrum-should-sort-p nil))
    (when-let ((choice (funcall org-mru-clock-completing-read
                               "Recent clocks: "
                               collection
                               nil ; PREDICATE
                               require-match)))
      (or (assoc choice collection)
          ;; for org-mru-clock-capture-if-no-match, return just the entered text:
          choice))))

(defun org-mru-clock--collection ()
  "Return a collection of recently used clocks for completing read.
Respects `org-mru-clock-include-entry-at-point'."
  (let* ((entry-at-point (org-mru-clock--collect-entry-at-point))
         (entry-at-point-keys (mapcar #'car entry-at-point)))
    ;; Possibly include entry-at-point, always keep it first, avoid duplicates:
    (append entry-at-point
            (cl-remove-if
             (lambda (k) (member k entry-at-point-keys))
             (org-mru-clock--collect-history org-clock-history)
             :key #'car))))

(defun org-mru-clock--collect-history (history)
  "Turn HISTORY into a collection usable for `completing-read'.
HISTORY is e.g. `org-clock-history'.  Outputs a list of pairs of
headline strings and markers.
Filters out markers not in `org-mru-clock-files'."
  (let ((files (funcall org-mru-clock-files))
        res)
    (dolist (i history)
      (let* ((buf (marker-buffer i))
             (file (buffer-file-name buf)))
        (when (cl-member file files :test #'file-equal-p)
          (with-current-buffer (org-base-buffer buf)
            (org-with-wide-buffer
             (ignore-errors
               (goto-char (marker-position i))
               (push (cons (org-mru-clock-format-entry) i) res)))))))
    (reverse res)))

(defun org-mru-clock--collect-entry-at-point ()
  "Make a \"collection\" of a single entry with the heading at point.
Return nil if we're not looking at an org heading. Works both for
regular org files and the agenda. Output format should be the
same as `org-mru-clock--collect-history'."
  (when org-mru-clock-include-entry-at-point
    (if (and (eq major-mode 'org-mode)
             (eq (car (org-element-at-point)) 'headline))
        (list (cons (org-mru-clock-format-entry) (point-marker)))
      ;; If in agenda, first follow link to org file:
      (when (eq major-mode 'org-agenda-mode)
        (let ((m (org-get-at-bol 'org-hd-marker)))
          (when m
            (with-current-buffer (org-base-buffer (marker-buffer m))
              (org-with-wide-buffer
               (goto-char (marker-position m))
               (org-mru-clock--collect-entry-at-point)))))))))

;;;###autoload
(defun org-mru-clock-in (&optional n)
  "Use completion to clock in to a task recently associated with clocking.
See `org-mru-clock-completing-read' for the completion function
used.  Optional argument N as in `org-mru-clock'.

If `org-mru-clock-capture-if-no-match' is non-nil, we may create
a new task from the text entered."
  (interactive "P")
  (org-mru-clock-to-history n)
  (let ((this-command #'org-mru-clock-in))
    (org-mru-clock--clock-in (org-mru-clock--completing-read))))

(provide 'org-mru-clock)
;;; org-mru-clock.el ends here
