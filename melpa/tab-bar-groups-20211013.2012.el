;;; tab-bar-groups.el --- Tab groups for the tab bar -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Fritz Grabo

;; Author: Fritz Grabo <hello@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/tab-bar-groups
;; Package-Version: 20211013.2012
;; Package-Commit: a0389d87d2e793055dd74ae85b4593aa1d2720fd
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

;; This package provides the means to work with and to customize the
;; appearance of named groups of tabs in Emacs 27 and higher.

;;; Code:

(require 'seq)

(eval-when-compile (require 'subr-x))

(defgroup tab-bar-groups ()
  "Tab groups for the tab bar."
  :group 'tab-bar)

;; ---- Appearance

(defvar tab-bar-groups-appearances
  '(1 2 3 4 5 6 7 8)
  "Default tab group appearances (symbols, strings; will generate faces from this).")

(defvar tab-bar-groups-colors
  '("dark blue" "dark red" "dark green" "dark orange" "steel blue" "medium violet red" "dark cyan" "saddle brown")
  "Default tab group colors (to be used by faces that relate to group appearances).")

(defvar tab-bar-groups-style-tab-name-functions
  (if (member 'tab-bar-format-tabs-groups tab-bar-format)
      '(tab-bar-groups-propertize-tab-name)
    '(tab-bar-groups-add-group-prefix tab-bar-groups-propertize-tab-name))
  "List of functions to call to style a tab's name for display.

Each function is expected to take NAME, TYPE, TAB, INDEX and
COUNT as arguments, and to return a copy of the name that was
further styled for display.

NAME is the partially styled tab's name as provided by the
previous function in the list.  In Emacs 27, TYPE is either 'tab
or 'current-tab.  In Emacs 28 and higher, it may also be 'group
or 'current-group.  TAB is the tab that the name belongs to.
INDEX is the index of the tab within the list of displayed tabs.
COUNT is the total number of displayed tabs.

If you provide your own implementation here, you're encouraged to
make it respect the user's settings in other variables related to
group appearance (currently, `tab-bar-groups-show-group-name').")

(defvar tab-bar-groups-pick-group-appearance-function
  #'tab-bar-groups-pick-group-appearance
  "Function to pick a new tab group's initial appearance.

This function is expected to take GROUP-NAME and GROUP-TABS as
arguments and to return one of `tab-bar-groups-appearances'.")

(defun tab-bar-groups-pick-group-appearance (_group-name _group-tabs)
  "Pick next unused (or first, if they are all used) group appearance from `tab-bar-groups-appearances'."
  (let* ((used (tab-bar-groups-distinct-group-appearances))
         (unused (seq-remove (lambda (appearance) (member appearance used)) tab-bar-groups-appearances)))
    (seq-first (or unused (tab-bar-groups-distinct-group-appearances)))))

(defvar tab-bar-groups-show-group-name
  'first
  "When to show the group name of a tab in its name.

When nil, never show the group name.
When 'first, show the group name only on the first tab of a group.
When 'all, show the group name on all tabs of a group.

Note that this is applied by `tab-bar-groups-propertize-tab-name'
or other custom functions that choose to respect this setting
only.  It does not apply when tab bar groups are rendered via
'tab-bar-format-tabs-groups in `tab-bar-format'.")

;; --- Face definitions

(defface tab-bar-groups-tab-group-current
  '((t :inherit (underline bold)))
  "Tab bar groups face for current group tab.")

(defface tab-bar-groups-tab-group-inactive
  '((t :inherit underline))
  "Tab bar groups face for inactive group tab.")

(seq-do-indexed
 (lambda (appearance index)
   (let ((color (nth (mod index (length tab-bar-groups-colors)) tab-bar-groups-colors))
         (face (intern (format "tab-bar-groups-tab-%s" appearance))))
     (eval (macroexpand `(defface ,face
                           '((t :foreground ,color))
                           ,(format "Tab bar groups face for tabs (%s)." appearance))))))
 tab-bar-groups-appearances)

;; --- Keymap handling

(defvar tab-bar-groups--keymap-element-type-regex
  "^\\(group\\|\\(?:current-\\)?tab\\)\\(?:-\\([[:digit:]]+\\)\\)?$"
  "Regex to detect relevant tab bar keymap elements by their type.

The Regex must provide at least two match groups.  The first
match group must match the actual type (without the index part)
of a relevant tab bar keymap element.  By default, that is 'tab
and 'current-tab in Emacs 27 and additionally, 'group in Emacs
28.  The second match group must match the index of the element
in the keymap, if any.  For example, a keymap element with a type
of 'tab-4 should match 'tab' and '4'.

Only match types of keymap elements that you want to be fed into
`tab-bar-groups-style-tab-name-functions'.")

(defun tab-bar-groups--keymap-element-type (keymap-element)
  "Extract the actual type of KEYMAP-ELEMENT.

Returns either 'tab or 'current-tab in Emacs 27 and additionally,
'group or 'current-group in Emacs 28 and higher."
  (when-let* ((raw-type-string (symbol-name (car keymap-element)))
              (type (and (string-match tab-bar-groups--keymap-element-type-regex raw-type-string)
                         (intern (match-string 1 raw-type-string))))
              (name (caddr keymap-element)))
    (if (and (eq type 'group) (string= name (tab-bar-groups-tab-group-name)))
        'current-group
      type)))

(defun tab-bar-groups--keymap-element-tab (keymap-element)
  "Find the tab that KEYMAP-ELEMENT relates to.

In Emacs 28 and higher, for keymap elements that denote tab
groups (that is, keymap elements that have a type of 'group-*),
return the first tab in the group.

If the keymap element does not relate to a tab, return nil."
  (let ((raw-type (car keymap-element)))
    (if (eq raw-type 'current-tab)
        (tab-bar--current-tab)
      (let ((raw-type-string (symbol-name raw-type)))
        (string-match tab-bar-groups--keymap-element-type-regex raw-type-string)
        (nth (1- (string-to-number (match-string 2 raw-type-string)))
             (funcall tab-bar-tabs-function))))))

;; --- Tab name styling

(defun tab-bar-groups-propertize-tab-name (name type tab _index _count)
  "Propertize NAME according to TYPE and TAB."
  (let ((name (concat name)))
    (when-let ((face (cond ((eq type 'current-group) "tab-bar-groups-tab-group-current")
                           ((eq type 'group) "tab-bar-groups-tab-group-inactive"))))
      (font-lock-prepend-text-property 0 (length name) 'face face name))
    (when-let ((group-appearance (alist-get 'group-appearance tab)))
      (font-lock-prepend-text-property 0 (length name) 'face (intern (format "tab-bar-groups-tab-%s" group-appearance)) name))
    name))

(defun tab-bar-groups-add-group-prefix (name _type tab _index _count)
  "Prefix NAME with the group name of TAB."
  (when-let* ((group-index (alist-get 'group-index tab))
              (group-name (concat (tab-bar-groups-tab-group-name tab))))
    (let* ((current-group-p (string= group-name (tab-bar-groups-tab-group-name)))
           (face (intern (format "tab-bar-groups-tab-group-%s" (if current-group-p "current" "inactive")))))
      (when (or (and (equal tab-bar-groups-show-group-name 'first) (equal 1 group-index))
                (equal tab-bar-groups-show-group-name 'all))
        (font-lock-prepend-text-property 0 (length group-name) 'face face group-name)
        (setq name (concat group-name " " name)))))
  name)

;; ---- Low-level plumbing and helpers

(defvar tab-bar-groups-tab-post-change-group-functions
  nil
  "List of functions to call after changing the group of a tab.

Each function is expected to take the updated tab as an argument.

Note that ejecting a tab from its group (that is, changing its
group to nil) will also trigger this hook.")

(defun tab-bar-groups-current-tab ()
  "Retrieve original data about the current tab."
  (assq 'current-tab (funcall tab-bar-tabs-function)))

(defun tab-bar-groups-tab-group-name (&optional tab)
  "The group name of the given TAB (or the current tab)."
  (alist-get 'group (or tab (tab-bar-groups-current-tab))))

(defun tab-bar-groups-tab-group-p (&optional tab)
  "Whether the given TAB (or the current tab) belongs to a group."
  (stringp (tab-bar-groups-tab-group-name tab)))

(defun tab-bar-groups-group-tabs (&optional tab)
  "All tabs that belong to the same group as TAB (or the current tab).

Returns nil if the given tab does not belong to a group."
  (when-let ((group-name (tab-bar-groups-tab-group-name tab)))
    (alist-get (intern group-name) (tab-bar-groups-parse-groups))))

(defun tab-bar-groups-store-tab-value (key value &optional tab)
  "Set VALUE for KEY in TAB (or the current tab).  Return true if the tab was actually updated."
  (let* ((tab (or tab (tab-bar-groups-current-tab)))
         (entry (assoc key tab)))
    (when (or (null entry)
              (not (equal value (cdr entry))))
      (if entry
          (setf (alist-get key tab) value)
        (nconc tab (list (cons key value))))
      t)))

(defun tab-bar-groups-store-tab-group (group-name &optional tab)
  "Set GROUP-NAME in TAB (or the current tab).

If the group of the tab was actually updated, run the hooks in
`tab-bar-tab-post-change-group-functions' and, by proxy, in
`tab-bar-groups-tab-post-change-group-functions'.

Note that `tab-bar-tab-post-change-group-functions' is defined in
Emacs 28 and higher only.  For Emacs 27, it is backported when
`tab-bar-groups-activate' is called first."
  (let ((tab (or tab (tab-bar-groups-current-tab))))
    (when (tab-bar-groups-store-tab-value 'group group-name tab)
      (run-hook-with-args 'tab-bar-tab-post-change-group-functions tab)))) ;; from Emacs 28; created on activation in Emacs 27

(defun tab-bar-groups--reindex-tabs ()
  "Re-distribute group index to all tabs."
  (interactive)
  (seq-do (lambda (group-tabs)
            (seq-do-indexed (lambda (tab index)
                              (tab-bar-groups-store-tab-value 'group-index (and (tab-bar-groups-tab-group-name tab) (1+ index)) tab))
                            group-tabs))
          (mapcar #'cdr (tab-bar-groups-parse-groups))))

(defun tab-bar-groups--reassign-group-appearances ()
  "Re-distribute group appearance to all tabs."
  (interactive)
  (dolist (group-and-tabs (tab-bar-groups-parse-groups))
    (let* ((group (car group-and-tabs))
           (group-tabs (cdr group-and-tabs))
           (group-appearance (alist-get 'group-appearance (seq-find (lambda (tab) (alist-get 'group-appearance tab)) group-tabs)))
           (new-group-appearance (and group (or group-appearance (tab-bar-groups-pick-group-appearance (symbol-name group) group-tabs)))))
      (dolist (tab group-tabs)
        (setf (alist-get 'group-appearance tab) new-group-appearance)))))

(defun tab-bar-groups-parse-groups ()
  "Build an alist of tabs grouped by their group name.

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
      (let* ((group-name (tab-bar-groups-tab-group-name tab))
             (group (and group-name (intern group-name)))
             (new-named-group-p (and group (null (assq group result))))
             (in-nil-group-p (and (consp (car result)) (null (caar result))))
             (new-nil-group-p (not (or group in-nil-group-p))))
        (if (or new-named-group-p new-nil-group-p)
            (push (cons group (list tab)) result)
          (nconc (alist-get group result) (list tab)))))
    (reverse result)))

(defun tab-bar-groups-distinct-tab-values (key)
  "Retrieve a list of distinct values found for KEY in all tabs of the current frame."
  (seq-uniq (seq-map (lambda (tab) (alist-get key tab)) (funcall tab-bar-tabs-function))))

(defun tab-bar-groups-distinct-group-names ()
  "A list of distinct group names in all tabs of the current frame."
  (seq-filter #'identity (tab-bar-groups-distinct-tab-values 'group)))

(defun tab-bar-groups-distinct-group-appearances ()
  "A list of distinct group appearances in all tabs of the current frame."
  (seq-filter #'identity (tab-bar-groups-distinct-tab-values 'group-appearance)))

;; ----- Commands

(defun tab-bar-groups-new-tab (&optional arg)
  "Create a new tab in the current group; ARG is used like in `tab-bar-new-tab'.

In Emacs 28 and higher, adjust `tab-bar-new-tab-group' instead."
  (interactive)
  (let ((group-name (tab-bar-groups-tab-group-name)))
    (tab-bar-new-tab arg)
    (tab-bar-groups-store-tab-group group-name)))

(defun tab-bar-groups-duplicate-tab (&optional arg)
  "Duplicate current tab in its group; ARG is used like in `tab-bar-new-tab'.

In Emacs 28 and higher, use `tab-bar-duplicate-tab' instead."
  (interactive)
  (let ((group-name (tab-bar-groups-tab-group-name))
        (tab-bar-new-tab-choice nil))
    (tab-bar-new-tab arg)
    (tab-bar-groups-store-tab-group group-name)))

(defun tab-bar-groups-change-tab-group (group-name tab)
  "Change GROUP-NAME of TAB (or the current tab).

In Emacs 28 and higher, use `tab-bar-change-tab-group' instead."
  (interactive
   (list (completing-read "Group name for tab: " (tab-bar-groups-distinct-group-names) nil nil (tab-bar-groups-tab-group-name))
         (tab-bar-groups-current-tab)))
  (tab-bar-groups-store-tab-group (and (not (string-blank-p group-name)) group-name) tab))

(defalias 'tab-bar-groups-assign-group 'tab-bar-groups-change-tab-group)

(defvar tab-bar-groups-preserve-apparance-on-change-group nil
  "When non-nil, preserve a tab's group appearance when its group is changed.")

(defun tab-bar-groups-rename-group (group-name tab)
  "Rename the group of TAB (or the current tab) to GROUP-NAME.

Note that this changes the group's name in all tabs that belong
to that group.

If GROUP-NAME is nil, interactively query the user."
  (interactive
   (list (completing-read "Group name for tab(s): " (tab-bar-groups-distinct-group-names) nil nil (tab-bar-groups-tab-group-name))
         (tab-bar-groups-current-tab)))
  (let ((tab-bar-groups-preserve-apparance-on-change-group t))
    (dolist (tab (or (tab-bar-groups-group-tabs tab) (list tab)))
      (tab-bar-groups-store-tab-group group-name tab))))

(defun tab-bar-groups-eject-tab (tab)
  "Eject TAB (or current tab) from its group."
  (interactive (list (tab-bar-groups-current-tab)))
  (tab-bar-groups-store-tab-group nil tab))

(defun tab-bar-groups-close-group-tabs (tab)
  "Close all tabs of the group that TAB (or the current tab) belongs to.

In Emacs 28 and higher, use `tab-bar-close-group-tabs' instead."
  (interactive (list (tab-bar-groups-current-tab)))
  (dolist (tab (tab-bar-groups-group-tabs tab))
    (tab-bar-close-tab (1+ (seq-position (funcall tab-bar-tabs-function) tab #'equal)))))

(defalias 'tab-bar-groups-close-tab-group 'tab-bar-groups-close-group)
(defalias 'tab-bar-groups-close-group 'tab-bar-groups-close-group-tabs)

(defun tab-bar-groups-regroup-tabs (&rest _)
  "Re-order tabs so that all tabs of each group are next to each other.

Accepts, but ignores any arguments so it can be used as-is in the
`tab-bar-groups-tab-post-change-group-functions' abnormal
hook in order to keep tabs grouped at all times."
  (interactive)
  (let* ((tabs (apply #'append (seq-map #'cdr (tab-bar-groups-parse-groups)))))
    (dotimes (index (length tabs))
      (let ((tab (elt tabs index)))
        (tab-bar-move-tab-to (1+ index) (1+ (tab-bar--tab-index tab)))))))

;; ---- Wiring

(defvar tab-bar-groups-trigger-reindex-tabs-functions
  '(tab-bar-close-tab
    tab-bar-move-tab-to
    tab-bar-new-tab-to)
  "List of functions after which to re-distribute group index in all tabs.")

(defun tab-bar-groups--reindex-tabs-advice (result)
  "Re-distribute group index to all tabs, return RESULT."
  (tab-bar-groups--reindex-tabs)
  result)

(defvar tab-bar-groups-trigger-reassign-group-appearances-functions
  '(tab-bar-new-tab-to)
  "List of functions after which to re-distribute group appearance in all tabs.")

(defun tab-bar-groups--reassign-group-appearances-advice (result)
  "Re-distribute group appearance in all tabs, return RESULT."
  (tab-bar-groups--reassign-group-appearances)
  result)

(defun tab-bar-groups--tab-advice (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, then inject custom properties related to tab groups."
  (let ((result (apply orig-fun args))
        (tab (assq 'current-tab (frame-parameter (car args) 'tabs))))
    (dolist (key '(group group-index group-appearance))
      (unless (assoc key result)
        (nconc result (list (cons key (alist-get key tab))))))
    result))

(defun tab-bar-groups--current-tab-advice (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, then inject custom properties related to tab groups."
  (let ((result (apply orig-fun args))
        (tab (or (car args) (assq 'current-tab (frame-parameter (cadr args) 'tabs)))))
    (dolist (key '(group group-index group-appearance))
      (unless (assoc key result)
        (nconc result (list (cons key (alist-get key tab))))))
    result))

(defun tab-bar-groups--make-keymap-1-advice (keymap)
  "Apply group appearance to all tabs in KEYMAP."
  (let* ((keymap-elements (seq-filter #'tab-bar-groups--keymap-element-type (cdr keymap)))
         (keymap-elements-count (length keymap-elements)))
    (seq-map-indexed
     (lambda (keymap-element index)
       (setf (caddr keymap-element)
             (seq-reduce
              (lambda (name f)
                (funcall f
                         name ;; name
                         (tab-bar-groups--keymap-element-type keymap-element) ;; type
                         (tab-bar-groups--keymap-element-tab keymap-element) ;; tab
                         index ;; index
                         keymap-elements-count)) ;; count
              tab-bar-groups-style-tab-name-functions
              (caddr keymap-element))))
     keymap-elements))
  keymap)

(defun tab-bar-groups--post-change-group (tab)
  "Do some tab bar group related housekeeping after changing TAB's group."
  (unless tab-bar-groups-preserve-apparance-on-change-group
    (tab-bar-groups-store-tab-value 'group-appearance nil tab))
  (tab-bar-groups-store-tab-value 'group-index nil tab)
  (tab-bar-groups--reindex-tabs)
  (tab-bar-groups--reassign-group-appearances)
  (run-hook-with-args 'tab-bar-groups-tab-post-change-group-functions tab))

;; --- Activation

(defun tab-bar-groups-activate ()
  "Activate tab bar groups."

  ;; Install advice.
  (advice-add #'tab-bar--tab :around #'tab-bar-groups--tab-advice)
  (if (fboundp 'tab-bar--current-tab-make)
      (advice-add #'tab-bar--current-tab-make :around #'tab-bar-groups--current-tab-advice)
    (advice-add #'tab-bar--current-tab :around #'tab-bar-groups--current-tab-advice))
  (advice-add #'tab-bar-make-keymap-1 :filter-return #'tab-bar-groups--make-keymap-1-advice)

  (dolist (f tab-bar-groups-trigger-reindex-tabs-functions)
    (advice-add f :filter-return #'tab-bar-groups--reindex-tabs-advice '((depth . 100))))

  (dolist (f tab-bar-groups-trigger-reassign-group-appearances-functions)
    (advice-add f :filter-return #'tab-bar-groups--reassign-group-appearances-advice))

  ;; Prime pre-existing tabs with custom properties related to tab groups.
  (dolist (tab (funcall tab-bar-tabs-function))
    (dolist (key '(group group-index group-appearance))
      (tab-bar-groups-store-tab-value key (alist-get key tab) tab)))

  ;; Note that `tab-bar-tab-post-change-group-functions' is defined in
  ;; Emacs 28 and higher only.  For Emacs 27, it is kind of backported
  ;; here.
  (add-hook 'tab-bar-tab-post-change-group-functions #'tab-bar-groups--post-change-group))

;; --- Integration with tab-bar-echo-area.el

(defvar tab-bar-groups--original-tab-bar-echo-area-make-keymap-function nil)

(defun tab-bar-groups--make-keymap-for-tab-bar-echo-area ()
  "Make an unaltered keymap to use as the source of tabs to display."
  (let ((tab-bar-groups-style-tab-name-functions nil))
    (funcall tab-bar-groups--original-tab-bar-echo-area-make-keymap-function)))

(defun tab-bar-groups--style-tab-name-for-echo-area (name type tab index count)
  "Style NAME according to TYPE, TAB, INDEX, COUNT."
  (seq-reduce
   (lambda (name f) (funcall f name type tab index count))
   tab-bar-groups-style-tab-name-functions
   name))

(defun tab-bar-groups-activate-for-tab-bar-echo-area ()
  "Activate tab bar groups for the 'tab-bar-echo-area' package.

Requires version 0.3 of that package."
  (when (featurep 'tab-bar-echo-area)
    (add-hook 'tab-bar-echo-area-style-tab-name-functions #'tab-bar-groups--style-tab-name-for-echo-area 100)

    (dolist (f '(tab-bar-groups-new-tab
                 tab-bar-groups-duplicate-tab
                 tab-bar-groups-assign-group
                 tab-bar-groups-rename-group
                 tab-bar-groups-eject-tab
                 tab-bar-groups-close-group))
      (add-hook 'tab-bar-echo-area-trigger-display-functions f))

    (when (boundp 'tab-bar-echo-area-make-keymap-function)
      (setq tab-bar-groups--original-tab-bar-echo-area-make-keymap-function tab-bar-echo-area-make-keymap-function)
      (setq tab-bar-echo-area-make-keymap-function #'tab-bar-groups--make-keymap-for-tab-bar-echo-area))

    (when (functionp 'tab-bar-echo-area-apply-display-tab-names-advice)
      (tab-bar-echo-area-apply-display-tab-names-advice))))

;; --- Integration with project-mode-line-tag.el

(defun tab-bar-groups--style-project-mode-line-tag (project-tag)
  "Style PROJECT-TAG."
  (let ((project-tag (concat project-tag)))
    (when-let ((group-appearance (alist-get 'group-appearance (tab-bar-groups-current-tab))))
      (font-lock-prepend-text-property 0 (length project-tag) 'face (intern (format "tab-bar-groups-tab-%s" group-appearance)) project-tag))
    project-tag))

(defun tab-bar-groups-activate-for-project-mode-line-tag ()
  "Activate tab bar groups for the 'project-mode-line-tag' package."
  (when (featurep 'project-mode-line-tag)
    (add-hook 'project-mode-line-tag-style-functions #'tab-bar-groups--style-project-mode-line-tag 100)))

(provide 'tab-bar-groups)
;;; tab-bar-groups.el ends here
