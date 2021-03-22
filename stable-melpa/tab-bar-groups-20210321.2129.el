;;; tab-bar-groups.el --- Tab groups for the tab bar -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Fritz Grabo

;; Author: Fritz Grabo <me@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/tab-bar-groups
;; Package-Version: 20210321.2129
;; Package-Commit: b83315c9a63ba2f6bbeaaa449a3b78b84a87ec1c
;; Version: 0.2
;; Package-Requires: ((emacs "27.1") (s "1.12.0"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; Tab groups for the tab bar.

;; This package provides convenient commands to create and work with
;; groups of tabs.

;;; Code:

(require 'seq)

(eval-when-compile (require 'subr-x))

(defgroup tab-bar-groups ()
  "Tab groups for the tab bar."
  :group 'tab-bar)

;; ---- Appearance

(defvar tab-bar-groups-appearances
  '("1" "2" "3" "4" "5" "6" "7" "8")
  "Pool of tab group appearances.")

(defvar tab-bar-groups-apply-group-appearance-to-tab-name-function
  #'tab-bar-groups-propertize-tab-name
  "Function to use to apply a tab's group appearance to its name.

This function is expected to take a TAB-NAME and its TAB as
arguments, and to return TAB-NAME with TAB's group appearance
applied.  Note that TAB-NAME might have had text properties worth
keeping applied to it elsewhere already.

If you provide your own implementation here, you're encouraged to
make it respect the user's settings in other variables related to
appearance (currently, `tab-bar-groups-show-group-name').")

(defvar tab-bar-groups-pick-group-appearance-function
  #'tab-bar-groups-pick-group-appearance
  "Function to use to pick a new tab group's initial appearance.")

(defvar tab-bar-groups-show-group-name
  'first
  "When to show the group name of a tab in its name.

When nil, never show the group name.
When 'first, show the group name only on the first tab of a group.
When 'all, show the group name on all tabs of a group.")

(let ((i 1))
  (dolist (color '("dark blue"
                   "dark red"
                   "dark green"
                   "dark orange"
                   "steel blue"
                   "medium violet red"
                   "dark cyan"
                   "saddle brown"))
    (eval (macroexpand `(defface ,(intern (format "tab-bar-groups-%i" i)) '((t :foreground ,color)) ,(format "Face to use for tab bar groups (%i)." i))))
    (eval (macroexpand `(defface ,(intern (format "tab-bar-groups-%i-group-name" i)) '((t :inverse-video t :foreground ,color)) ,(format "Face to use for tab bar group names (%i)." i))))
    (setq i (1+ i))))

(defun tab-bar-groups-propertize-tab-name (tab-name tab)
  "Propertize TAB-NAME for TAB."
  (if-let ((group-appearance (alist-get 'group-appearance tab)))
      (let ((group-name (concat (alist-get 'group-name tab)))
            (group-index (alist-get 'group-index tab)))
        (font-lock-prepend-text-property 0 (length tab-name) 'face (intern (concat "tab-bar-groups-" group-appearance)) tab-name)
        (font-lock-prepend-text-property 0 (length group-name) 'face (intern (concat "tab-bar-groups-" group-appearance "-group-name")) group-name)
        (concat
         (and (or (and (equal tab-bar-groups-show-group-name 'first) (equal 1 group-index))
                  (equal tab-bar-groups-show-group-name 'all))
              (format "%s " group-name))
         tab-name))
    tab-name))

(defun tab-bar-groups-pick-group-appearance ()
  "Pick next unused (or first, if they are all used) group appearance from `tab-bar-groups-appearances'."
  (let* ((used (tab-bar-groups-distinct-group-appearances))
         (unused (seq-remove (lambda (appearance) (member appearance used)) tab-bar-groups-appearances)))
    (seq-first (or unused (tab-bar-groups-distinct-group-appearances)))))

;; ---- Low-level plumbing and helpers

(defvar tab-bar-groups-custom-tab-properties
  '(group-name group-index group-appearance)
  "List of custom tab group related properties to preserve/copy in tabs.")

(defvar tab-bar-groups-tab-post-group-assignment-functions
  nil
  "List of functions to call after changing the group assignment of a tab.

The updated tab is supplied as an argument. Note that ejecting a
tab from its group (that is, changing its assignment to nil) will
also trigger this hook.")

(defun tab-bar-groups-current-tab ()
  "Retrieve original data about the current tab of the current frame."
  (assq 'current-tab (funcall tab-bar-tabs-function)))

(defun tab-bar-groups-store-tab-value (key value &optional tab)
  "Store VALUE for KEY in TAB."
  (let* ((tab (or tab (tab-bar-groups-current-tab)))
         (entry (assoc key tab)))
    (when (or (null entry)
              (not (equal value (cdr entry))))
      (if entry
          (setf (alist-get key tab) value)
        (nconc tab (list (cons key value))))
      (if (equal key 'group-name)
          (run-hook-with-args 'tab-bar-groups-tab-post-group-assignment-functions tab)))))

(defun tab-bar-groups--reindex-tabs ()
  "Re-assign group-index to all tabs in groups."
  (interactive)
  (dolist (group-tabs (mapcar #'cdr (tab-bar-groups-parse-groups)))
    (dotimes (i (length group-tabs))
      (let ((tab (elt group-tabs i)))
        (setf (alist-get 'group-index tab) (and (alist-get 'group-name tab) (1+ i)))))))

(defun tab-bar-groups--copy-custom-properties (source-tab &optional tab)
  "Copy custom, tab group related properties from SOURCE-TAB to TAB (or current tab)."
  (dolist (key tab-bar-groups-custom-tab-properties)
    (tab-bar-groups-store-tab-value key (alist-get key source-tab) tab)))

(defun tab-bar-groups-parse-groups ()
  "Retrieve an alist of tabs grouped by their group name.

Successive tabs that don't belong to a group are grouped under
intermitting nil keys.

For example, consider this list of tabs: groupA:foo, groupB:bar,
baz, qux, groupC:quux, quuz, groupB:corge, groupA:grault.

Calling this function would yield this result:

'((groupA (foo grault))
  (groupB (bar corge))
  (nil (baz qux))
  (groupC (grault))
  (nil (quuz)))"
  (let* ((tabs (frame-parameter (selected-frame) 'tabs))
         (result '()))
    (dolist (tab tabs)
      (let* ((group-name (alist-get 'group-name tab))
             (group-name (and group-name (intern group-name)))
             (unknown-named-group (and group-name (null (assq group-name result))))
             (in-unnamed-group (and (consp (car result)) (null (caar result)))))
        (when (or unknown-named-group (not (or group-name in-unnamed-group)))
          (push (cons group-name nil) result))
        (let ((group (assq group-name result)))
          (setcdr group (append (cdr group) (list tab))))))
    (reverse result)))

(defun tab-bar-groups-store-tab-group (name appearance &optional tab)
  "Store group NAME and APPEARANCE in TAB."
  (tab-bar-groups-store-tab-value 'group-name name tab)
  (tab-bar-groups-store-tab-value 'group-appearance appearance tab))

(defun tab-bar-groups-distinct-tab-values (key)
  "Retrieve a list of distinct values found for KEY in all tabs of the current frame."
  (seq-uniq (seq-filter #'identity (mapcar (lambda (tab) (alist-get key tab)) (funcall tab-bar-tabs-function)))))

(defun tab-bar-groups-distinct-group-names ()
  "A list of distinct group names of the current frame."
  (tab-bar-groups-distinct-tab-values 'group-name))

(defun tab-bar-groups-distinct-group-appearances ()
  "A list of distinct group appearances of the current frame."
  (tab-bar-groups-distinct-tab-values 'group-appearance))

;; ----- Commands

(defun tab-bar-groups-new-tab (&rest arg)
  "Create a new tab in the current group; ARG is used like in `tab-bar-new-tab'."
  (interactive)
  (let ((source-tab (tab-bar--current-tab)))
    (tab-bar-new-tab arg)
    (tab-bar-groups--copy-custom-properties source-tab)))

(defun tab-bar-groups-duplicate-tab (&optional arg)
  "Duplicate current tab in its group; ARG is used like in `tab-bar-new-tab'."
  (interactive)
  (let ((source-tab (tab-bar--current-tab))
        (tab-bar-new-tab-choice nil))
    (tab-bar-new-tab arg)
    (tab-bar-groups--copy-custom-properties source-tab)))

(defun tab-bar-groups-assign-group (&optional name appearance tab)
  "Assign group NAME and APPEARANCE to TAB (or the current tab).

If NAME is nil, interactively query the user.  If APPEARANCE is
nil, re-use the appearance of the group with NAME, if it already
exists (merge groups).  Otherwise, keep the current tab's
appearance, if it was the single tab of a group (same as
renaming).  Otherwise, pick the next unused appearance from the
list in `tab-bar-groups-appearances'."
  (interactive)
  (let* ((groups (tab-bar-groups-parse-groups))
         (tab (or tab (tab-bar-groups-current-tab)))
         (group-name (alist-get 'group-name tab))
         (group-appearance (alist-get 'group-appearance tab))
         (distinct-group-names (tab-bar-groups-distinct-group-names))
         (group-tabs (or (and group-name (alist-get (intern group-name) groups)) (list tab)))
         (name (or name (completing-read "Group name for tab: " distinct-group-names nil nil group-name)))
         (appearance (or
                      appearance
                      (and (member name distinct-group-names)
                           (alist-get 'group-appearance (seq-first (alist-get (intern name) groups))))
                      (and (eq (length group-tabs) 1) group-appearance)
                      (funcall tab-bar-groups-pick-group-appearance-function))))
    (tab-bar-groups-store-tab-group name appearance tab)))

(defun tab-bar-groups-rename-group (&optional name tab)
  "Rename the group of TAB (or the current tab) to NAME.

If NAME is nil, interactively query the user.  Re-use the
appearance of the group with NAME, if it already exists (merge
groups).  Otherwise, if the tab is in a group, keep its current
appearance.  Otherwise, pick the next unused appearance from the
list in `tab-bar-groups-appearances'."
  (interactive)
  (let* ((groups (tab-bar-groups-parse-groups))
         (tab (or tab (tab-bar-groups-current-tab)))
         (group-name (alist-get 'group-name tab))
         (group-appearance (alist-get 'group-appearance tab))
         (distinct-group-names (tab-bar-groups-distinct-group-names))
         (affected-tabs (or (and group-name (alist-get (intern group-name) groups)) (list tab)))
         (name (or name (completing-read "Group name for tab(s): " distinct-group-names nil nil group-name)))
         (appearance (or
                      (and (member name distinct-group-names)
                           (alist-get 'group-appearance (seq-first (alist-get (intern name) groups))))
                      group-appearance
                      (funcall tab-bar-groups-pick-group-appearance-function))))
    (dolist (tab affected-tabs)
      (tab-bar-groups-assign-group name appearance tab))))

(defun tab-bar-groups-eject-tab (&optional tab)
  "Eject TAB (or current tab) from its group."
  (interactive)
  (let ((tab (or tab (tab-bar-groups-current-tab))))
    (dolist (key tab-bar-groups-custom-tab-properties)
      (tab-bar-groups-store-tab-value key nil tab))))

(defun tab-bar-groups-close-group (&optional tab)
  "Close all tabs in the group of TAB (or the current tab)."
  (interactive)
  (when-let* ((group-name (alist-get 'group-name (or tab (tab-bar--current-tab))))
              (group-tabs (alist-get (intern group-name) (tab-bar-groups-parse-groups))))
    (dolist (tab group-tabs)
      (tab-bar-close-tab (1+ (seq-position (funcall tab-bar-tabs-function) tab #'equal)))))) ;; bug?

(defalias 'tab-bar-groups-close-tab-group 'tab-bar-groups-close-group)

(defun tab-bar-groups-regroup-tabs (&rest _args)
  "Re-order tabs so that all tabs of each group are next to each other.

Accepts, but ignores any arguments so it can be used as-is in the
`tab-bar-groups-tab-post-group-assignment-functions' abnormal
hook in order to keep tabs grouped at all times."
  (interactive)
  (let* ((tabs (apply #'append (seq-map #'cdr (tab-bar-groups-parse-groups)))))
    (dotimes (i (length tabs))
      (let ((tab (elt tabs i)))
        (tab-bar-move-tab-to (1+ i) (1+ (tab-bar--tab-index tab)))))))

;; ---- Wiring

(defvar tab-bar-groups-trigger-reindex-functions
  '(tab-bar-close-tab
    tab-bar-move-tab-to
    tab-bar-new-tab-to
    tab-bar-groups-new-tab
    tab-bar-groups-duplicate-tab
    tab-bar-groups-store-tab-group
    tab-bar-groups-eject-tab)
  "List of functions after which to reindex tabs.")

(defun tab-bar-groups--reindex-tabs-advice (result)
  "Reindex tabs, return RESULT."
  (tab-bar-groups--reindex-tabs)
  result)

(defun tab-bar-groups--tab-advice (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, then inject custom properties related to tab groups."
  (let ((result (apply orig-fun args))
        (tab (assq 'current-tab (frame-parameter (car args) 'tabs))))
    (dolist (key tab-bar-groups-custom-tab-properties)
      (nconc result (list (cons key (alist-get key tab)))))
    result))

(defun tab-bar-groups--current-tab-advice (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, then inject custom properties related to tab groups."
  (let ((result (apply orig-fun args))
        (tab (or (car args) (assq 'current-tab (frame-parameter (cadr args) 'tabs)))))
    (dolist (key tab-bar-groups-custom-tab-properties)
      (nconc result (list (cons key (alist-get key tab)))))
    result))

(defun tab-bar-groups--make-keymap-1-advice (result)
  "Apply group appearance to all tabs in RESULT."
  (let* ((tabs (funcall tab-bar-tabs-function))
         (i 1))
    (dolist (tab tabs)
      (let* ((tab-type (car tab))
             (entry-key (if (equal tab-type 'current-tab) 'current-tab (intern (format "tab-%i" i))))
             (entry (alist-get entry-key result))
             (tab-name (cadr entry)))
        (setf (cadr entry) (concat
                            ;; FIXME hack to force tab bar redisplay;
                            ;; `force-mode-line-update' seems to ignore
                            ;; updates without actual text changes?
                            (when (= i 1) (propertize (format "%i" (random)) 'invisible t))
                            (funcall tab-bar-groups-apply-group-appearance-to-tab-name-function tab-name tab)))
        (setq i (1+ i))))
    result))

;; --- Activation

(defun tab-bar-groups-activate ()
  "Activate tab bar groups."

  ;; Install advice.
  (advice-add #'tab-bar--tab :around #'tab-bar-groups--tab-advice)
  (advice-add #'tab-bar--current-tab :around #'tab-bar-groups--current-tab-advice)
  (advice-add #'tab-bar-make-keymap-1 :filter-return #'tab-bar-groups--make-keymap-1-advice)

  (dolist (f tab-bar-groups-trigger-reindex-functions)
    (advice-add f :filter-return #'tab-bar-groups--reindex-tabs-advice '((depth . 100))))

  ;; Prime pre-existing tabs with custom, tab group related properties.
  (dolist (tab (funcall tab-bar-tabs-function))
    (dolist (key tab-bar-groups-custom-tab-properties)
      (tab-bar-groups-store-tab-value key (alist-get key tab) tab))))

(defun tab-bar-groups-activate-for-tab-bar-echo-area ()
  "Activate tab bar groups for the `tab-bar-echo-area' package."
  (when (featurep 'tab-bar-echo-area)
    (when (boundp 'tab-bar-echo-area-process-tab-name-functions)
      (unless (member tab-bar-groups-apply-group-appearance-to-tab-name-function tab-bar-echo-area-process-tab-name-functions)
        (nconc tab-bar-echo-area-process-tab-name-functions (list tab-bar-groups-apply-group-appearance-to-tab-name-function))))

    (when (boundp 'tab-bar-echo-area-trigger-display-functions)
      (dolist (f '(tab-bar-groups-duplicate-tab
                   tab-bar-groups-new-tab
                   tab-bar-groups-assign-group
                   tab-bar-groups-eject-tab))
        (unless (member f tab-bar-echo-area-trigger-display-functions)
          (push f tab-bar-echo-area-trigger-display-functions))))

    (when (functionp 'tab-bar-echo-area-apply-display-tab-names-advice)
      (tab-bar-echo-area-apply-display-tab-names-advice))))

(provide 'tab-bar-groups)
;;; tab-bar-groups.el ends here
