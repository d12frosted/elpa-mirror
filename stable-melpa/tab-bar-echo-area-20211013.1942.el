;;; tab-bar-echo-area.el --- Display tab names of the tab bar in the echo area -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Fritz Grabo

;; Author: Fritz Grabo <hello@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/tab-bar-echo-area
;; Package-Version: 20211013.1942
;; Package-Commit: d0d51ecbc5929eb7752b387c5bdfe4d879e78224
;; Version: 0.2
;; Package-Requires: ((emacs "27.1"))
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

;; Provides a global minor mode to temporarily display a list of
;; available tabs and tab groups (with the current tab and group
;; highlighted) in the echo area after tab-related commands.

;; This is intended to be used as an unobtrusive replacement for the
;; Emacs built-in display of the tab bar (that is, when you have
;; `tab-bar-show' set to nil).

;; The idea is to provide but a quick visual orientation aid to the
;; user after tab-related commands, and then get out of the way again.

;; I recommend using this together with the 'tab-bar-lost-commands'
;; package, which provides simple and convenient commands that help
;; with common tab bar use-cases regarding the creation, selection and
;; movement of tabs.

;; You might also want to check out the 'tab-bar-groups' package, which
;; backports a simplified version of Emacs 28 tab groups to Emacs 27 and
;; provides an integration with this package.

;;; Code:

(require 'seq)

(eval-when-compile (require 'subr-x))

(defgroup tab-bar-echo-area ()
  "Display tabs of the tab bar in the echo area."
  :group 'tab-bar)

(defface tab-bar-echo-area-tab
  '((t :inverse-video t))
  "Tab bar echo area face for selected tab.")

(defface tab-bar-echo-area-tab-inactive
  '((t))
  "Tab bar echo area face for non-selected tab.")

(defface tab-bar-echo-area-tab-ungrouped
  '((t :inherit shadow))
  "Tab bar echo area face for ungrouped tab when tab groups are used.")

(defface tab-bar-echo-area-tab-group-current
  '((t :inherit (underline bold)))
  "Tab bar echo area face for current group tab.")

(defface tab-bar-echo-area-tab-group-inactive
  '((t :inherit underline))
  "Tab bar echo area face for inactive group tab.")

(defvar tab-bar-echo-area-trigger-display-functions
  '(tab-bar-close-tab ;; Emacs 27 and higher
    tab-bar-move-tab-to
    tab-bar-new-tab-to
    tab-bar-rename-tab
    tab-bar-select-tab
    display-buffer-in-new-tab ;; Emacs 28 and higher
    tab-bar-change-tab-group)
  "List of functions after which to display tabs in the echo area.")

(defvar tab-bar-echo-area-style-tab-name-functions
  '(tab-bar-echo-area-remove-tab-name-properties
    tab-bar-echo-area-propertize-tab-name)
  "List of functions to call to style a tab's name for display.

Each function is expected to take NAME, TYPE, TAB, INDEX and
COUNT as arguments, and to return a copy of the name that was
further styled for display.

NAME is the partially styled tab's name as provided by the
previous function in the list.  In Emacs 27, TYPE is either 'tab
or 'current-tab.  In Emacs 28 and higher, it may also be 'group
or 'current-group.  TAB is the tab that the name belongs to.
INDEX is the index of the tab within the list of displayed tabs.
COUNT is the total number of displayed tabs.")

(defvar tab-bar-echo-area-format-tab-name-functions
  '(tab-bar-echo-area-format-tab-name-for-joining)
  "List of functions to call to format a styled tab name for display.

See `tab-bar-echo-area-style-tab-name-functions' for a list and
a description of the arguments passed into these functions.")

(defvar tab-bar-echo-area-format
  nil
  "Optional customization of `tab-bar-format' in the context of the echo area.

Note that `tab-bar-format' was introduced in Emacs 28 only.
Setting this will have no effect in Emacs 27.")

(defvar tab-bar-echo-area-display-tab-names-format-string
  "Tabs: %s"
  "Format string to use for rendering tab names in the echo area.

If the value is a string, use it as the format string.

If the value is a function, call it to generate the format string
to use.  The function is expected to take KEYMAP-ELEMENTS (the
keymap elements that will be displayed) as an argument.

The format string is expected to contain a single \"%s\", which
will be substituted with the list of fully processed tab names.")

;; --- Keymap handling

(defvar tab-bar-echo-area-make-keymap-function
  #'tab-bar-echo-area-make-keymap
  "Function to make the keymap used as the source of tabs to display.")

(defun tab-bar-echo-area-make-keymap ()
  "Make a keymap to use as the source of tabs to display."
  (let ((tab-bar-close-button-show nil)
        (tab-bar-tab-hints nil))
    (tab-bar-make-keymap)))

(defvar tab-bar-echo-area--keymap-element-type-regex
  "^\\(group\\|\\(?:current-\\)?tab\\)\\(?:-\\([[:digit:]]+\\)\\)?$"
  "Regex to detect relevant tab bar keymap elements by their type.

The Regex must provide at least two match groups.  The first
match group must match the actual type (without the index part)
of a relevant tab bar keymap element.  By default, that is 'tab
and 'current-tab in Emacs 27 and additionally, 'group in Emacs 28
and higher.  The second match group must match the index of the
element in the keymap, if any.  For example, a keymap element
with a type of 'tab-4 should match 'tab' and '4'.

Only match types of keymap elements that you want to be fed into
`tab-bar-echo-area-style-tab-name-functions' and
`tab-bar-echo-area-format-tab-name-functions'.")

(defun tab-bar-echo-area--keymap-element-type (keymap-element)
  "Extract the actual type of KEYMAP-ELEMENT.

Returns either 'tab or 'current-tab in Emacs 27 and additionally,
'group or 'current-group in Emacs 28 and higher."
  (when-let* ((raw-type-string (symbol-name (car keymap-element)))
              (type (and (string-match tab-bar-echo-area--keymap-element-type-regex raw-type-string)
                         (intern (match-string 1 raw-type-string))))
              (name (caddr keymap-element)))
    (if (and (eq type 'group)
             (string= name (alist-get 'group (tab-bar--current-tab))))
        'current-group
      type)))

(defun tab-bar-echo-area--keymap-element-tab (keymap-element)
  "Find the tab that KEYMAP-ELEMENT relates to.

In Emacs 28 and higher, for keymap elements that denote tab
groups (that is, keymap elements that have a type of 'group-*),
return the first tab in the group.

If the keymap element does not relate to a tab, return nil."
  (let ((raw-type (car keymap-element)))
    (if (eq raw-type 'current-tab)
        (tab-bar--current-tab)
      (let ((raw-type-string (symbol-name raw-type)))
        (string-match tab-bar-echo-area--keymap-element-type-regex raw-type-string)
        (if (member (match-string 1 raw-type-string) '("tab" "group"))
            (nth (1- (string-to-number (match-string 2 raw-type-string)))
                 (funcall tab-bar-tabs-function)))))))

;; --- Tab name processing

(defun tab-bar-echo-area-remove-tab-name-properties (name _type _tab _index _count)
  "Remove all text properties from NAME."
  (substring-no-properties name))

(defun tab-bar-echo-area-propertize-tab-name (name type tab _index _count)
  "Propertize NAME according to TYPE and TAB."
  (let* ((name (concat name))
         (face (cond ((eq type 'current-tab) 'tab-bar-echo-area-tab)
                     ((eq type 'tab) (if (alist-get 'group tab) 'tab-bar-echo-area-tab-inactive 'tab-bar-echo-area-tab-ungrouped))
                     ((eq type 'current-group) 'tab-bar-echo-area-tab-group-current)
                     ((eq type 'group) 'tab-bar-echo-area-tab-group-inactive))))
    (font-lock-append-text-property 0 (length name) 'face face name)
    name))

(defun tab-bar-echo-area-format-tab-name-for-joining (name type _tab index count)
  "Format NAME according to TYPE, INDEX and COUNT."
  (format (cond ((eq type 'current-group) "%s ")
                ((eq index (1- count)) "%s")
                (t "%s, "))
          name))

(defun tab-bar-echo-area--process-tab-name (name type tab index count)
  "Process NAME according to TYPE, TAB, INDEX, COUNT."
  (seq-reduce
   (lambda (name f) (funcall f name type tab index count))
   (append
    tab-bar-echo-area-style-tab-name-functions
    tab-bar-echo-area-format-tab-name-functions)
   name))

(defun tab-bar-echo-area--processed-tab-names (keymap-elements)
  "Generate a list of fully processed tab names for KEYMAP-ELEMENTS for display in the echo area."
  (let ((keymap-elements-count (length keymap-elements)))
    (seq-map-indexed (lambda (keymap-element index)
                       (funcall #'tab-bar-echo-area--process-tab-name
                                (caddr keymap-element) ;; name
                                (tab-bar-echo-area--keymap-element-type keymap-element) ;; type
                                (tab-bar-echo-area--keymap-element-tab keymap-element) ;; tab
                                index ;; index
                                keymap-elements-count)) ;; count
                     keymap-elements)))

;; --- Commands

;;;###autoload
(defun tab-bar-echo-area-display-tab-names ()
  "Display tab names in the echo area."
  (interactive)
  (let* ((tab-bar-format (or tab-bar-echo-area-format (and (boundp 'tab-bar-format) tab-bar-format)))
         (keymap (funcall tab-bar-echo-area-make-keymap-function))
         (keymap-elements (seq-filter #'tab-bar-echo-area--keymap-element-type (cdr keymap))))
    (if-let ((tab-names (tab-bar-echo-area--processed-tab-names keymap-elements))
             (format-string (cond ((functionp tab-bar-echo-area-display-tab-names-format-string)
                                   (funcall tab-bar-echo-area-display-tab-names-format-string keymap-elements))
                                  ((stringp tab-bar-echo-area-display-tab-names-format-string)
                                   tab-bar-echo-area-display-tab-names-format-string)
                                  (t "%s"))))
        (message format-string (string-join tab-names)))))

;;;###autoload
(defalias 'tab-bar-echo-area-print-tab-names 'tab-bar-echo-area-display-tab-names) ;; v0.1, deprecated

;;;###autoload
(defun tab-bar-echo-area-display-tab-name ()
  "Display the current tab's name in the echo area."
  (interactive)
  (let* ((keymap-element (assoc 'current-tab (cdr (funcall tab-bar-echo-area-make-keymap-function))))
         (name (funcall #'tab-bar-echo-area--process-tab-name
                        (caddr keymap-element) ;; name
                        (tab-bar-echo-area--keymap-element-type keymap-element) ;; type
                        (tab-bar-echo-area--keymap-element-tab keymap-element) ;; tab
                        0 ;; index
                        1))) ;; count
    (message "Current Tab: %s" name)))

;;;###autoload
(defalias 'tab-bar-echo-area-print-tab-name 'tab-bar-echo-area-display-tab-name) ;; v0.1, deprecated

;; --- Wiring

(defun tab-bar-echo-area-display-tab-names-advice (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, then display tab names in the echo area."
  (let ((result (apply orig-fun args)))
    (tab-bar-echo-area-display-tab-names)
    result))

;; --- Mode definition

;;;###autoload
(define-minor-mode tab-bar-echo-area-mode
  "Alternative to function `tab-bar-mode': display tab names in the echo area after tab bar-related functions."
  :group 'tab-bar
  :global t
  (tab-bar-echo-area-apply-display-tab-names-advice))

(defun tab-bar-echo-area-apply-display-tab-names-advice ()
  "Add or remove advice to display tab names according to variable `tab-bar-echo-area-mode'."
  (dolist (f tab-bar-echo-area-trigger-display-functions)
    (if tab-bar-echo-area-mode
        (advice-add f :around #'tab-bar-echo-area-display-tab-names-advice)
      (advice-remove f #'tab-bar-echo-area-display-tab-names-advice))))

(provide 'tab-bar-echo-area)
;;; tab-bar-echo-area.el ends here
