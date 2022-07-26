;;; tiny-menu.el --- Display tiny menus. -*- lexical-binding: t -*-

;; Copyright (c) 2016 Aaron Bieber

;; Author: Aaron Bieber <aaron@aaronbieber.com>
;; Version: 1.0
;; Package-Version: 20220725.1748
;; Package-Commit: 17eacfd1d44cd4d5482d32eac63229230c3cd3fc
;; Package-Requires: ((emacs "24.4"))
;; Keywords: menu tools
;; URL: https://github.com/aaronbieber/tiny-menu.el

;;; Commentary:

;; Tiny Menu provides a simple mechanism for building one-line menus
;; of commands suitable for binding to keys.  For a full description
;; and examples of use, see the `README.md' file packaged along with
;; this program.

;;; License:

;; Tiny Menu is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your
;; option) any later version.
;;
;; Tiny Menu is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Tiny Menu.  If not, see http://www.gnu.org/licenses.

;;; Code:

(defface tiny-menu-heading-face
  '((t (:inherit 'font-lock-string-face)))
  "The menu heading shown in the selection menu for `tiny-menu'."
  :group 'tiny-menu)

(defvar tiny-menu-forever nil
  "If menu transitions are omitted, stay within the same menu until quit.")

(defvar tiny-menu-items
  '(())
  "An alist of menus.

The keys in the alist are simple strings used to reference the menu in
calls to `tiny-menu' and the values are lists with four elements: a
raw character to use as the selection key (such as `?a'), a string to
use in the menu display, a function to call when that item is
selected, and a new menu to display once the function has been run.

If the new menu is omitted, and `tiny-menu-forever' is non-nil, then
the default is to remain in the current menu.  If `tiny-menu-forever'
is nil, then omitting a new menu results in tiny-menu terminating
after execution.  The special value of \"quit\" indicates an
unconditional quit from tiny-menu, and the value \"root\" indicates an
unconditional transition to the menu of menus.  tiny-menu will report
an error for an invalid transition name.

The data structure should look like:

'((\"menu-name-1\" (\"menu-display-name\"
                     (?a \"First item\"
                         function-to-call-for-item-1
                         \"transition-menu\")
                     (?b \"Second item\"
                         function-to-call-for-item-2
                         \"transition-menu\")))
 ((\"menu-name-2\" (\"menu-display-name\"
                     (?z \"First item\"
                         function-to-call-for-item-1
                         \"transition-menu\")
                     (?x \"Second item\"
                         function-to-call-for-item-2
                         \"transition-menu\")))))")

(defun tiny-menu--lookup-transition (current-menu next-menu)
  "From CURRENT-MENU, extract the appropriate NEXT-MENU value.

Not all menus have a NEXT-MENU, in which case the resulting value may
be nil."
  (if (null next-menu)
      (when tiny-menu-forever current-menu)
    (cond
     ((string-equal "quit" next-menu) nil)
     ((string-equal "root" next-menu) (tiny-menu--menu-of-menus))
     (t (if (assoc next-menu tiny-menu-items)
            (cadr (assoc next-menu tiny-menu-items))
          (error (concat "The transition menu specified, \"%s\", is not a valid option, "
                         "check tiny-menu-items.") (or next-menu "N/A")))))))

(defun tiny-menu (&optional menu silent)
  "Display the items in MENU and run the selected item.

If MENU is not given, a dynamically generated menu of available menus
is displayed.
  
If SILENT is given, do not show the message \"Menu ended.\" when finished."
  (interactive)
  (if (< (length tiny-menu-items) 1)
      (message "Configure tiny-menu-items first.")
    (setq menu (tiny-menu--lookup-transition nil (or menu "root")))
    (while menu
      (let* ((title (car menu))
             (items (append (cadr menu)
                            '((?q "Quit" nil "quit"))))
             (prompt (concat (propertize (concat title ": ") 'face 'default)
                             (mapconcat (lambda (i)
                                          (concat
                                           (propertize (concat
                                                        "[" (char-to-string (nth 0 i)) "] ")
                                                       'face 'tiny-menu-heading-face)
                                           (nth 1 i)))
                                        items ", ")))
             (choices (mapcar (lambda (i) (nth 0 i)) items))
             (choice (assoc (read-char-choice prompt choices) items)))
        (when (functionp (nth 2 choice))
          (progn (message "")
                 (condition-case nil
                     (call-interactively (nth 2 choice))
                   ((wrong-type-argument)
                    (funcall (nth 2 choice))))))
        (setq menu (tiny-menu--lookup-transition menu (nth 3 choice)))))
    (unless (or silent
                (current-message))
      (message "Menu ended."))))

(defun tiny-menu--menu-of-menus ()
  "Build menu items for all configured menus.

This allows `tiny-menu' to display an interactive menu of all
configured menus if the caller does not specify a menu name
explicitly."
  (let ((menu-key-char 97))
    `("Menus" ,(mapcar (lambda (i)
                         (prog1
                             `(,menu-key-char ,(car (car (cdr i))) nil ,(car i))
                           (setq menu-key-char (1+ menu-key-char))))
                       tiny-menu-items))))

(defun tiny-menu-run-item (item)
  "Return a function suitable for binding to call the ITEM run menu.

This saves you the trouble of putting inline lambda functions in all
of the key binding declarations for your menus.  A key binding
declaration now looks like:

`(define-key some-map \"<key>\" (tiny-menu-item \"my-menu\"))'."
  (lambda ()
    (interactive)
    (tiny-menu item)))

(provide 'tiny-menu)
;;; tiny-menu.el ends here
