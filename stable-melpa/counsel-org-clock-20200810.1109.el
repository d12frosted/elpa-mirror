;;; counsel-org-clock.el --- Counsel commands for org-clock -*- lexical-binding: t -*-

;; Copyright (C) 2018 by Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.2.2
;; Package-Version: 20200810.1109
;; Package-Commit: 6ba0f2ac7e4e5b8c1baec90296d9f24407d8d632
;; Package-Requires: ((emacs "25.1") (ivy "0.10.0") (dash "2.0"))
;; URL: https://github.com/akirak/counsel-org-clock

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides the following two commands via Ivy interface:
;;
;; - `counsel-org-clock-context' displays the currently clocked task as well as
;;   its ancestors and descendants.  If there is no currently running clock,
;;   this function behaves the same as `counsel-org-clock-history'.
;; - `counsel-org-clock-history' displays entries in `org-clock-history'
;;   variable.

;;; Code:
(require 'cl-lib)
(require 'ivy)
(require 'org-clock)
(require 'dash)

;;;; Custom variables
(defcustom counsel-org-clock-goto-fallback-function nil
  "Function called inside `counsel-org-clock-goto' when no clock is running.

When this function is set to non-nil, `counsel-org-clock-goto' calls
the function when no active clock is currently running.
Otherwise, the function lets you jump to the last active clock."
  :type 'function
  :group 'counsel-org-clock)

(defcustom counsel-org-clock-goto-number-command-alist
  nil
  "Alist of pairs of a numeric prefix and a command.

These commands are called when `counsel-org-clock-goto' is called
with a numeric prefix."
  :type `(alist :key-type integer
                :value-type function
                :options
                ,(number-sequence -1 9))
  :group 'counsel-org-clock)

;;;; Counsel commands

;;;###autoload
(defun counsel-org-clock-context (&optional marker arg)
  "Display the current org-clock, its ancestors, and its descendants via Ivy.

If an Org heading is given as MARKER, it displays the context
around the entry instead of the current clock.

If there is no clocking task, display the clock history using
`counsel-org-clock-history'.  If the function is called interactively,
the prefix argument ARG is passed to the function.  That is, it
restores the clock history from `org-agenda-files'."
  (interactive (list nil current-prefix-arg))
  (if (or (markerp marker) (org-clocking-p))
      (let ((marker (or marker org-clock-marker)))
        (counsel-org-clock--ivy-context marker
                                        (format "Headings in %s: "
                                                (file-name-nondirectory
                                                 (buffer-file-name (marker-buffer marker))))))
    (counsel-org-clock-history arg)))

(defun counsel-org-clock--ivy-context (marker prompt)
  "Display the context of an org heading pointed by MARKER with PROMPT via Ivy.

The ancestors of the heading, the heading, and its descendants are shown in this
order."
  (cl-destructuring-bind
      (selection candidates)
      (counsel-org-clock--get-marker-context marker)
    (ivy-read prompt
              candidates
              :caller 'counsel-org-clock-context
              :require-match t
              :preselect selection
              :action #'counsel-org-clock--run-context-action)))

(defun counsel-org-clock--get-marker-context (marker)
  "Get the context of MARKER.

The returned value is a list which consists of the following elements:

1. A string to be used as :preselect in ivy.
2. An alist of candidates to be used in ivy.

The result is used in `counsel-org-clock-context' when there is a clocking task."
  (with-current-buffer (org-base-buffer (marker-buffer marker))
    (org-with-wide-buffer
     (goto-char marker)
     (let ((current (counsel-org-clock--candidate-at-point))
           (ancestors (nreverse
                       (save-excursion
                         (cl-loop for cont = (org-up-heading-safe)
                                  while cont
                                  collect (counsel-org-clock--candidate-at-point)))))
           (descendants (cdr (org-map-entries
                              'counsel-org-clock--candidate-at-point
                              nil 'tree))))
       (list (car current)
             (append ancestors (list current) descendants))))))

;;;###autoload
(defun counsel-org-clock-history (&optional arg)
  "Display the history of org-clock via Ivy.

If prefix ARG is given, rebuild the history from `org-agenda-files'."
  (interactive "P")
  (when arg
    (counsel-org-clock-rebuild-history))
  (ivy-read "org-clock history: "
            (cl-remove-duplicates
             (cl-loop for marker in org-clock-history
                      when (markerp marker)
                      when (buffer-live-p (marker-buffer marker))
                      collect (ignore-errors
                                (with-current-buffer (org-base-buffer (marker-buffer marker))
                                  (org-with-wide-buffer
                                   (goto-char marker)
                                   (counsel-org-clock--candidate-path-at-point)))))
             :key #'cdr)
            :caller 'counsel-org-clock-history
            :require-match t
            :action #'counsel-org-clock--run-history-action))

;;;###autoload
(defun counsel-org-clock-goto (&optional arg)
  "Convenient replacement for `org-clock-goto'.

This function lets you navigate either to the current clock or through
the clock history.

Without a prefix argument ARG, this is basically the same as
`org-clock-goto'.  The difference from `org-clock-goto' is that it
calls `counsel-org-clock-goto-fallback-function' when it is set
and there is no active clock running.

With a numeric prefix argument, a command/function defined in
`counsel-org-clock-goto-number-command-alist' is called.

With a single universal prefix argument, this function calls
`counsel-org-clock-context'.

With two universal prefix arguments, this function calls
`counsel-org-clock-history', which lets you browse the clock
history.  With three universal prefix arguments, this function
rebuilds the clock history and lets you browse it."
  (interactive "P")
  (pcase arg
    ('nil (cond
           ((org-clocking-p) (org-clock-goto))
           ((functionp counsel-org-clock-goto-fallback-function) (funcall counsel-org-clock-goto-fallback-function))
           (t (org-clock-goto))))
    ((pred numberp) (counsel-org-clock--call-number-command arg))
    ('(4) (counsel-org-clock-context))
    ('(16) (counsel-org-clock-history))
    ('(64) (counsel-org-clock-history t))))

(defun counsel-org-clock--call-number-command (arg)
  "Call a command associated with a number ARG."
  (if-let (cmd (alist-get arg counsel-org-clock-goto-number-command-alist))
      (cl-etypecase cmd
        (command (call-interactively cmd))
        (function (funcall cmd)))
    (user-error "There is no entry for %d in counsel-org-clock-goto-number-command-alist"
                arg)))

;;;; Functions to format candidates

(defun counsel-org-clock--candidate-at-point ()
  "Build a candidate for Ivy."
  (cons (concat (make-string (nth 0 (org-heading-components)) ?\*)
                " "
                (org-get-heading))
        (point-marker)))

(defun counsel-org-clock--candidate-path-at-point ()
  "Build a candidate for Ivy containing the path."
  (cons (format "%s: %s%s"
                (file-name-nondirectory (buffer-file-name))
                (apply 'concat
                       (nreverse (save-excursion
                                   (cl-loop for cont = (org-up-heading-safe)
                                            while cont
                                            collect (concat (counsel-org-clock--get-heading-clean)
                                                            " > ")))))
                (org-get-heading))
        (save-excursion
          ;; Move the position to the beginning of the entry for checking duplicates
          (goto-char (org-entry-beginning-position))
          (point-marker))))

(defun counsel-org-clock--get-heading-clean ()
  "`org-get-heading' with options applied."
  (org-get-heading t t)
  ;; TODO: org-get-heading accepts only 0-2 arguments?
  ;; (if (version< (org-version) "9.1")
  ;;     (org-get-heading t t)
  ;;   ;; Third and fourth arguments have been supported since 9.1:
  ;;   ;; https://code.orgmode.org/bzg/org-mode/commit/53ee147f4537a051bfde366ea1459f059fdc13ef
  ;;   ;; https://github.com/emacs-china/org-mode/blob/6dc6eb3b029ec00c10e20dcfaa0b6e328bf36e03/etc/ORG-NEWS
  ;;   (org-get-heading t t t t))
  )

;;;; History
(defun counsel-org-clock--last-clock ()
  "Get the last clock time in the entry."
  (when (re-search-forward (concat "^[ \t]*" org-clock-string)
                           (save-excursion
                             ;; Jump to a position after the beginning of the entry
                             (end-of-line)
                             (re-search-forward org-heading-regexp nil 'noerror))
                           'noerror)
    (let ((src (thing-at-point 'line 'no-properties)))
      (when (string-match (org-re-timestamp 'inactive) src)
        (org-time-string-to-time (match-string 0 src))))))

(defun counsel-org-clock--get-history-entries (limit &optional include-archives)
  "Get org-clock-history entries from `org-agenda-files'.

Take LIMIT entries are retrieved from the files.

If INCLUDE-ARCHIVES is non-nil, archives are included in the scanning."
  (--> (org-map-entries (lambda ()
                          (let ((marker (point-marker))
                                (time (counsel-org-clock--last-clock)))
                            (when time
                              (cons time marker))))
                        nil
                        (if include-archives 'agenda-with-archives 'agenda))
       (cl-remove nil it)
       (cl-sort it #'time-less-p :key 'car)
       (nreverse it)
       (-take limit it)
       (mapcar #'cdr it)))

(defcustom counsel-org-clock-history-limit org-clock-history-length
  "The number of `org-clock-history' items to be rebuild."
  :group 'counsel-org-clock
  :type 'integer)

(defcustom counsel-org-clock-history-include-archives nil
  "If non-nil, include archive files when rebuilding the clock history."
  :group 'counsel-org-clock
  :type 'bool)

(defun counsel-org-clock-rebuild-history ()
  "Rebuild `org-clock-history' from `org-agenda-files'."
  (interactive)
  (message "Rebuilding org-clock-history...")
  (setq org-clock-history (counsel-org-clock--get-history-entries
                           counsel-org-clock-history-limit
                           counsel-org-clock-history-include-archives)))

;;;; Actions
;;;;; Macros to help you define actions

(defmacro counsel-org-clock--after-display (marker &rest form)
  "Jump to MARKER, display the context, and run FORM."
  (declare (indent 1))
  `(if (buffer-live-p (marker-buffer ,marker))
       (progn
         (pop-to-buffer (marker-buffer ,marker))
         (when (or (> ,marker (point-max)) (< ,marker (point-min)))
           (widen))
         (goto-char ,marker)
         (org-show-context)
         ,@form)
     (error "Cannot find location")))

(defmacro counsel-org-clock--candidate-display-action (&rest form)
  "Create an anonymous function to display a given candidate and run FORM.

Deprecated since 0.2."
  `(lambda (cand)
     (let ((marker (cdr cand)))
       (when (buffer-live-p (marker-buffer marker))
         (pop-to-buffer (marker-buffer marker))
         (when (or (> marker (point-max)) (< marker (point-min)))
           (widen))
         (goto-char marker)
         (org-show-context)
         ,@form))))

(defmacro counsel-org-clock--candidate-widen-action (&rest form)
  "Create an anonymous function to run FORM silently with a given candidate.

This is deprecated in 0.2. Use `counsel-org-clock--with-marker'."
  `(lambda (cand)
     (let ((marker (cdr cand)))
       (when (buffer-live-p (marker-buffer marker))
         (with-current-buffer (marker-buffer marker)
           (org-with-wide-buffer
            (goto-char marker)
            ,@form))))))

(defmacro counsel-org-clock--with-marker (marker &rest form)
  "Temporarily go to MARKER and run FORM."
  (declare (indent 1))
  `(if (buffer-live-p (marker-buffer ,marker))
       (with-current-buffer (org-base-buffer (marker-buffer ,marker))
         (org-with-wide-buffer
          (goto-char ,marker)
          ,@form))
     (error "Cannot find location")))

(defmacro counsel-org-clock--with-marker-interactively (marker &rest form)
  "Temporarily go to MARKER, run FORM, and restore the window configuration."
  (declare (indent 1))
  `(if (buffer-live-p (marker-buffer ,marker))
       (save-window-excursion
         (pop-to-buffer-same-window (marker-buffer ,marker))
         (delete-other-windows)
         (save-excursion
           (save-restriction
             (widen)
             (goto-char ,marker)
             (org-narrow-to-subtree)
             ,@form)))
     (error "Cannot find location")))

(defmacro counsel-org-clock--candidate-interactive-action (&rest form)
  "Create an anonymous function to run FORM in a temporary window.

Deprecated since 0.2."
  `(lambda (cand)
     (let ((marker (cdr cand)))
       (save-window-excursion
         (pop-to-buffer-same-window (marker-buffer marker))
         (delete-other-windows)
         (save-excursion
           (save-restriction
             (widen)
             (goto-char marker)
             (org-narrow-to-subtree)
             ,@form))))))

;;;;; Action functions
(defun counsel-org-clock-goto-action (cand)
  "Jump to the heading in counsel-org-clock.

CAND is a cons cell whose cdr is a marker to the entry.

This function is deprecated in 0.2."
  (org-goto-marker-or-bmk (cdr cand)))

(defun counsel-org-clock--clock-in-marker (marker)
  "Start a clock on the heading pointed by MARKER."
  (counsel-org-clock--with-marker marker
    (org-clock-in)))

(defun counsel-org-clock-clock-in-action (cand)
  "Clock in to the heading in counsel-org-clock.

CAND is a cons cell whose cdr is a marker to the entry.

This function is deprecated in 0.2."
  (let ((marker (cdr cand)))
    (if (buffer-live-p (marker-buffer marker))
        (with-current-buffer (marker-buffer marker)
          (org-with-wide-buffer
           (goto-char marker)
           (org-clock-in)))
      (error "Cannot find location"))))

(defun counsel-org-clock--clock-dwim-marker (marker)
  "Toggle the clocking status on the heading pointed by MARKER."
  (counsel-org-clock--with-marker marker
    (if (and (org-clocking-p)
             (eq (org-entry-beginning-position)
                 (with-current-buffer (marker-buffer org-clock-marker)
                   (save-excursion
                     (goto-char org-clock-marker)
                     (org-entry-beginning-position)))))
        (org-clock-out)
      (org-clock-in))))

(defun counsel-org-clock-clock-dwim-action (cand)
  "Toggle the clocking status on the heading in counsel-org-clock.

If the selected entry is currently clocked, clock out from it.
Otherwise, clock in it.

CAND is a cons cell whose cdr is a marker to the entry.

This function is deprecated in 0.2."
  (let ((marker (cdr cand)))
    (if (buffer-live-p (marker-buffer marker))
        (with-current-buffer (marker-buffer marker)
          (org-with-wide-buffer
           (goto-char marker)
           (if (and (org-clocking-p)
                    (eq (org-entry-beginning-position)
                        (with-current-buffer (marker-buffer org-clock-marker)
                          (save-excursion
                            (goto-char org-clock-marker)
                            (org-entry-beginning-position)))))
               (org-clock-out)
             (org-clock-in))))
      (error "Cannot find location"))))

(defun counsel-org-clock--narrow-marker (marker)
  "Narrow to the entry at MARKER."
  (counsel-org-clock--after-display marker
    (org-narrow-to-subtree)))

(defun counsel-org-clock--indirect-marker (marker)
  "Show the entry at MARKER in an indirect buffer."
  (counsel-org-clock--after-display marker
    (org-tree-to-indirect-buffer)))

(defun counsel-org-clock--store-link-marker (marker)
  "Store a link to the entry at MARKER."
  (counsel-org-clock--with-marker marker
    (call-interactively 'org-store-link)))

(defun counsel-org-clock--clock-out-marker (marker)
  "Clock out from the current clock if MARKER is clocked."
  (when (org-clocking-p)
    (counsel-org-clock--with-marker marker
      (let ((clock (with-current-buffer (marker-buffer org-clock-marker)
                     (save-excursion
                       (goto-char org-clock-marker)
                       (org-entry-beginning-position)))))
        (when (eq clock (org-entry-beginning-position))
          (org-clock-out))))))

(defun counsel-org-clock--todo-marker (marker)
  "Change the todo state of the entry at MARKER."
  (counsel-org-clock--with-marker-interactively marker
    (org-todo)))

(defun counsel-org-clock--set-tags-marker (marker)
  "Set tags on the entry at MARKER."
  (counsel-org-clock--with-marker-interactively marker
    (org-set-tags-command)))

(defun counsel-org-clock--set-property-marker (marker)
  "Set a property on the entry at MARKER."
  (counsel-org-clock--with-marker-interactively marker
    (call-interactively 'org-set-property)))

;;;;; Dispatching an action
(defconst counsel-org-clock-action-map
  '((goto . org-goto-marker-or-bmk)
    (clock-in . counsel-org-clock--clock-in-marker)
    (clock-dwim . counsel-org-clock--clock-dwim-marker)
    (clock-out . counsel-org-clock--clock-out-marker)
    (store-link . counsel-org-clock--store-link-marker)
    (narrow . counsel-org-clock--narrow-marker)
    (indirect . counsel-org-clock--indirect-marker)
    (todo . counsel-org-clock--todo-marker)
    (set-tags . counsel-org-clock--set-tags-marker)
    (set-property . counsel-org-clock--set-property-marker)
    ;; Deprecated options formerly available in `counsel-org-clock-default-action'
    (counsel-org-clock-goto-action . org-goto-marker-or-bmk)
    (counsel-org-clock-clock-in-action . counsel-org-clock--clock-in-marker)
    (counsel-org-clock-clock-dwim-action . counsel-org-clock--clock-dwim-marker))
  "Alist of actions supported in `counsel-org-clock--dispatch-action'.")

(defun counsel-org-clock--dispatch-action (action cand)
  "Dispatch ACTION on CAND.

ACTION is a symbol indicating an action or a function on a marker.

CAND is a cons cell whose cdr is a marker to an entry in an org buffer."
  (let ((marker (if (markerp (cdr cand))
                    (cdr cand)
                  (error "Invalid candidate: %s" (prin1-to-string cand)))))
    (funcall (or (cdr (assq action counsel-org-clock-action-map))
                 (cond
                  ((null action) #'org-goto-marker-or-bmk)
                  ((functionp action) action)
                  (t (error "Unsupported type of action: %s"
                            (prin1-to-string action)))))
             marker)))

;;;;; Default action

(define-widget 'counsel-org-clock-action-type 'lazy
  "An action in counsel-org-clock."
  :tag "Action"
  :type '(choice (const :tag "Default" nil)
                 (const :tag "Go to" goto)
                 (const :tag "Clock in" clock-in)
                 (const :tag "Toggle clock in/out" clock-dwim)
                 (const :tag "Clock out" clock-out)
                 (const :tag "Store a link" store-link)
                 (const :tag "Narrow to the entry" narrow)
                 (const :tag "Show in an indirect buffer" indirect)
                 (const :tag "Change the todo state" todo)
                 (const :tag "Set tags" set-tags)
                 (const :tag "Set a property" set-property)
                 function))

(defcustom counsel-org-clock-default-action
  'goto
  "Default action for commands in counsel-org-clock."
  :type 'counsel-org-clock-action-type
  :group 'counsel-org-clock
  :package-version "0.2")

(defun counsel-org-clock--run-context-action (cand)
  "The default action in `counsel-org-clock-context'.

CAND is a cons cell whose cdr is a marker to the heading.

See `counsel-org-clock-default-action'."
  ;; TODO: Allow the user to override the default action for the command
  (counsel-org-clock--dispatch-action counsel-org-clock-default-action
                                      cand))

(defun counsel-org-clock--run-history-action (cand)
  "The default action in `counsel-org-clock-history'.

CAND is a cons cell whose cdr is a marker to the heading.

See `counsel-org-clock-default-action'."
  ;; TODO: Allow the user to override the default action for the command
  (counsel-org-clock--dispatch-action counsel-org-clock-default-action
                                      cand))

;;;;; Alternative actions

(defcustom counsel-org-clock-actions
  '(("g" goto "Go to")
    ("n" narrow "Narrow to the entry")
    ("s" indirect "Show in indirect buffer")
    ("t" todo "Change the TODO state")
    ("q" set-tags "Set tags")
    ("p" set-property "Set a property")
    ("I" clock-in "Clock in")
    ("O" clock-out "Clock out (if current)")
    ("l" store-link "Store link"))
  "List of actions available in commands in counsel-org-clock.

These actions will be available in `counsel-org-clock-context' and
`counsel-org-clock-history' commands."
  :type '(repeat (list (string :tag "Key")
                       counsel-org-clock-action-type
                       (string :tag "Label")))
  :set (lambda (symbol value)
         (set-default symbol value)
         (let ((actions (cl-loop for (key action label) in value
                                 collect (list key
                                               `(lambda (cand)
                                                  (counsel-org-clock--dispatch-action
                                                   (quote ,action) cand))
                                               label))))
           (dolist (cmd '(counsel-org-clock-context
                          counsel-org-clock-history))
             (ivy-set-actions cmd actions))))
  :group 'counsel-org-clock
  :package-version "0.2")

(provide 'counsel-org-clock)
;;; counsel-org-clock.el ends here
