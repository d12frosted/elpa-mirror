;;; ewmctrl.el --- Use `wmctrl' to manage desktop windows via EWMH/NetWM.

;; Copyright (C) 2015-2017  Alexis <flexibeast@gmail.com>, Adam Plaice <plaice.adam@gmail.com>

;; Author: Alexis <flexibeast@gmail.com>
;;      Adam Plaice <plaice.adam@gmail.com>
;; Maintainer: Alexis <flexibeast@gmail.com>
;; Created: 2015-01-08
;; URL: https://github.com/flexibeast/ewmctrl
;; Keywords: desktop, windows, ewmh, netwm

;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;

;;; Commentary:

;; `ewmctrl' provides an Emacs interface to the `wmctrl' command-line window-management program.

;; ## Table of Contents

;; - [Installation](#installation)
;; - [Usage](#usage)
;; - [Issues](#issues)
;; - [License](#license)

;; ## Installation

;; Install [ewmctrl from MELPA](http://melpa.org/#/ewmctrl), or put `ewmctrl.el' in your load-path and do a `(require 'ewmctrl)'.

;; ## Usage

;; Create an `ewmctrl' buffer with `M-x ewmctrl'.

;; The default keybindings are:

;; ### Window actions

;; * RET - Switch to the selected desktop window (`ewmctrl-focus-window').

;; * D - Delete the selected desktop window (`ewmctrl-delete-window').

;; * I - Change the icon name of the selected desktop window (`ewmctrl-change-window-icon-name').

;; * m - Move the selected desktop window to a different desktop (`ewmctrl-move-window-to-other-desktop').

;; * M - Move the selected desktop window to the current desktop, raise it, and give it focus (`ewmctrl-move-window-to-current-desktop-and-focus').

;; * N - Change the name of the selected desktop window (`ewmctrl-change-window-name').

;; * r - Resize the selected desktop window by specifying dimensions in the minibuffer (`ewmctrl-resize-window'). Whilst in the minibuffer, use TAB and S-TAB to move within and between the width and height fields, and use C-RET to preview the currently specified dimensions.

;; * SPC [key] [action] - Select window specified by [key] and perform [action] on it, where [action] is an action keybinding. For example, SPC a RET will switch to the desktop window designated by 'a', whilst SPC c D will delete the desktop window designated by 'c'.

;; ### Filtering

;; * fc - Remove all filtering (`ewmctrl-filters-clear').

;; * fd - Add a filter by desktop number (`ewmctrl-filter-by-desktop-number').

;; * fD - Remove all filtering by desktop number (`ewmctrl-filter-desktop-number-clear').

;; * fn - Add a filter by window name (`ewmctrl-filter-by-name').

;; * fN - Remove all filtering by window name (`ewmctrl-filter-name-clear').

;; * fp - Add a filter by PID (`ewmctrl-filter-by-pid').

;; * fP - Remove all filtering by PID (`ewmctrl-filter-pid-clear').

;; ### Sorting

;; * Sd - Sort the list of desktop windows numerically by desktop number (`ewmctrl-sort-by-desktop-number').

;; * SD - Sort the list of desktop windows reverse-numerically by desktop number (`ewmctrl-sort-by-desktop-number-reversed').

;; * Sn - Sort the list of desktop windows lexicographically by name (`ewmctrl-sort-by-name').

;; * SN - Sort the list of desktop windows reverse-lexicographically by name (`ewmctrl-sort-by-name-reversed').

;; * Sp - Sort the list of desktop windows numerically by PID (`ewmctrl-sort-by-pid').

;; * SP - Sort the list of desktop windows reverse-numercially by PID (`ewmctrl-sort-by-pid-reversed').

;; ### General

;; * g - Refresh the list of desktop windows (`ewmctrl-refresh').

;; * n - Move point to next line (`next-line').

;; * p - Move point to previous line (`previous-line').

;; * ; - Toggle single-key-to-focus (`ewmctrl-toggle-single-key-to-focus'). When enabled, a desktop window can be focused simply by pressing the designated key for that window.

;; Customisation options are available via the `ewmctrl' customize-group.

;; ## Issues / bugs

;; Deletion of windows does not work in i3 4.8 and earlier due to [i3 bug #1396](http://bugs.i3wm.org/query/ticket/1396).

;; If you discover an issue or bug in `ewmctrl' not already noted:

;; * as a TODO item, or

;; * in [the project's "Issues" section on GitHub](https://github.com/flexibeast/ewmctrl/issues),

;; please create a new issue with as much detail as possible, including:

;; * which version of Emacs you're running on which operating system, and

;; * how you installed `ewmctrl'.

;; ## License

;; [GNU General Public License version 3](http://www.gnu.org/licenses/gpl.html), or (at your option) any later version.

;;; Code:


;; Customisable variables.

(defgroup ewmctrl nil
  "Emacs interface to `wmctrl'."
  :group 'external)

(defcustom ewmctrl-close-frame-on-focus-window nil
  "Whether to close the frame containing the *ewmctrl* buffer
after giving focus to a desktop window."
  :type 'boolean
  :group 'ewmctrl)

(defcustom ewmctrl-format-header "  Key  Desktop    PID  Name\n  ---  -------  -----  ----\n"
  "String to be used as the header for the window list."
  :type 'string
  :group 'ewmctrl)

(defcustom ewmctrl-format-fields-order '(win-key win-desktop win-pid win-name)
  "List of symbols describing which fields to display in the
window list, and in what order (leftmost-first).

Each symbol should be one of 'win-key, 'win-desktop, 'win-pid
or 'win-name.

Changing the value of this variable requires the value of
`ewmctrl-format-fields' to be set appropriately."
  :type '(repeat (choice (const :tag "win-key" win-key)
                         (const :tag "win-desktop" win-desktop)
                         (const :tag "win-pid" win-pid)
                         (const :tag "win-name" win-name)))
  :group 'ewmctrl)


(defcustom ewmctrl-format-fields "   %1s   %4s     %5s  %s\n"
  "String to be passed to `format' to lay out each entry in
the window list.

Changing the value of this variable requires the value of
`ewmctrl-format-fields-order' to be set appropriately."
  :type 'string
  :group 'ewmctrl)

(defcustom ewmctrl-include-sticky-windows nil
  "Whether to include sticky windows in window list."
  :type 'boolean
  :group 'ewmctrl)

(defcustom ewmctrl-post-action-hook '()
  "Functions to call after running an action on a desktop
window.

Each function is called with two arguments:

* KEY, the key designating the window being acted upon;

* CHAR, the numeric value of the keybind which called the action."
  :type '(repeat function)
  :group 'ewmctrl)

(defcustom ewmctrl-single-key-to-focus nil
  "Whether to, by default, enable functionality to focus a
window simply by pressing the designated key for that window.

This functionality can be toggled on and off via the ';' key."
  :type 'boolean
  :group 'ewmctrl)

(defcustom ewmctrl-sort-field 'name
  "Field on which to sort the list of desktop windows."
  :type '(list desktop-number desktop-number-reversed name name-reversed pid pid-reversed)
  :group 'ewmctrl)

(defcustom ewmctrl-wmctrl-path "/usr/bin/wmctrl"
  "Absolute path of `wmctrl' executable."
  :type '(file :must-match t)
  :group 'ewmctrl)


;; Internal variables.

(defvar ewmctrl-field-count 9
  "Number of fields output by `wmctrl' when run with the
switches specified by the value of the variable
`ewmctrl-wmctrl-switches'.")

(defvar ewmctrl-filters nil
  "Alist of filters to apply when displaying list of desktop
windows.

The alist consists of at most three entries, each of the form

(SYMBOL . LIST)

where SYMBOL is one of `desktop-number', `name' or `pid'. With
each symbol is associated a list of strings, each string being
a filter to apply on the field indicated by that symbol.")

(defvar ewmctrl-mode-map (make-sparse-keymap)
  "Keymap for `ewmctrl-mode'.")

(defvar ewmctrl-single-key-to-focus-map (make-sparse-keymap)
  "Keymap for `ewmctrl' single-key-to-focus functionality.")

(defvar ewmctrl-window-id-keybind-alist `(("0x00000000" . ,(string (decode-char 'unicode #xfffd))))
  "Alist of window IDs and the keybinds associated with them.

Initial value is a dummy value, using the Unicode 'REPLACEMENT
CHARACTER', to simplify the logic of the function
`ewmctrl--assign-key'.")

(defvar ewmctrl-wmctrl-switches "-lpG"
  "Switches to pass to `wmctrl' executable.

Modifying the value of this variable might require modification
of the variable `ewmctrl-field-count'.")


;; Internal functions.

(defun ewmctrl--assign-key (id)
  "Internal function to return a new key to refer to the
desktop window specified by ID."
  ;; Unicode ASCII a -> z == 0x0061 -> 0x007A
  (let ((current-char #x0061)
        (chosen-char nil))
    (while (and (not chosen-char)
                (< current-char #x007B))
      (if (rassoc (string (decode-char 'unicode current-char)) ewmctrl-window-id-keybind-alist)
          (setq current-char (1+ current-char))
        (progn
          (setq chosen-char (string (decode-char 'unicode current-char)))
          (define-key ewmctrl-mode-map
            (kbd (concat "SPC " chosen-char))
            (eval `(defun ,(intern (concat "ewmctrl-select-window-" chosen-char "-for-action")) ()
                     ,(concat "Select window '" chosen-char "' for an action.")
                     (interactive)
                     (ewmctrl--dispatch-action ,chosen-char))))
          (define-key ewmctrl-single-key-to-focus-map
            (kbd chosen-char)
            (eval `(defun ,(intern (concat "ewmctrl-focus-window-with-key-" chosen-char)) ()
                     ,(concat "Focus window '" chosen-char "' using '" chosen-char"' key.")
                     (interactive)
                     (ewmctrl--dispatch-action ,chosen-char)))))))
    chosen-char))

(defun ewmctrl--change-window-icon-name-by-id (id)
  "Internal function to change the icon name of the window
specified by ID."
  (let ((name (read-string "New window icon name: ")))
    (call-process-shell-command (concat ewmctrl-wmctrl-path " -i -r '" id "' -I '" name "'"))
    (ewmctrl-refresh)))

(defun ewmctrl--change-window-name-by-id (id)
  "Internal function to change the name of the window
specified by ID."
  (let ((name (read-string "New window name: ")))
    (call-process-shell-command (concat ewmctrl-wmctrl-path " -i -r '" id "' -N '" name "'"))
    (ewmctrl-refresh)))

(defun ewmctrl--close-window-by-id (id)
  "Internal function to close the window specified by ID."
  (if (yes-or-no-p (concat "Delete window '" (ewmctrl--get-window-property-via-id id 'title) "'? "))
      (progn
        (call-process-shell-command (concat ewmctrl-wmctrl-path " -i -c '" id "'"))
        (define-key ewmctrl-mode-map
          (kbd (concat "SPC " (cdr (assoc id ewmctrl-window-id-keybind-alist))))
          (lambda ()
            (interactive)))
        (define-key ewmctrl-single-key-to-focus-map
          (kbd (cdr (assoc id ewmctrl-window-id-keybind-alist)))
          (lambda ()
            (interactive)))
        (setq ewmctrl-window-id-keybind-alist (delq (assoc id ewmctrl-window-id-keybind-alist) ewmctrl-window-id-keybind-alist))
        (ewmctrl-refresh))))

(defun ewmctrl--dispatch-action (key)
  "Internal function to perform action on window specified
by KEY.

After the action is dispatched, the functions listed in
`ewmctrl-post-action-hook' are called."
  (if ewmctrl-single-key-to-focus
      (progn
        (ewmctrl-focus-window key)
        (dolist (f ewmctrl-post-action-hook)
          (funcall f key 13)))
    (let ((char (read-char nil t)))
      (cond
       ((= 13 char) ; RET
        (ewmctrl-focus-window key))
       ((= 68 char) ; D
        (ewmctrl-delete-window key))
       ((= 73 char) ; I
        (ewmctrl-change-window-icon-name key))
       ((= 77 char) ; M
        (ewmctrl-move-window-to-current-desktop-and-focus key))
       ((= 78 char) ; N
        (ewmctrl-change-window-name key))
       ((= 109 char) ; m
        (ewmctrl-move-window-to-other-desktop key))
       ((= 114 char) ; r
        (ewmctrl-resize-window key))
       (t
        (user-error (concat "ewmctrl--dispatch-action: don't know how to handle character " (number-to-string char)))))
      (dolist (f ewmctrl-post-action-hook)
        (funcall f key char)))))

(defun ewmctrl--filter-add (field filter)
  "Internal function to add FILTER on FIELD."
  (cond
   ((eq 'desktop-number field)
    (let ((current-filter (cdr (assoc 'desktop-number ewmctrl-filters))))
      (if current-filter
          (setcdr (assoc 'desktop-number ewmctrl-filters) (cons filter current-filter))
        (setq ewmctrl-filters (cons `(desktop-number . ,(list filter)) ewmctrl-filters)))))
   ((eq 'name field)
    (let ((current-filter (cdr (assoc 'name ewmctrl-filters))))
      (if current-filter
          (setcdr (assoc 'name ewmctrl-filters) (cons filter current-filter))
        (setq ewmctrl-filters (cons `(name . ,(list filter)) ewmctrl-filters)))))
   ((eq 'pid field)
    (let ((current-filter (cdr (assoc 'pid ewmctrl-filters))))
      (if current-filter
          (setcdr (assoc 'pid ewmctrl-filters) (cons filter current-filter))
        (setq ewmctrl-filters (cons `(pid . ,(list filter)) ewmctrl-filters)))))
   (t
    (error "ewmctrl-filter-add: received unknown value for FIELD"))))

(defun ewmctrl--focus-window-by-id (id)
  "Internal function to focus the desktop window specified
by ID."
  (call-process-shell-command (concat ewmctrl-wmctrl-path " -i -a '" id "'"))
  (if ewmctrl-close-frame-on-focus-window
      (delete-frame)))

(defun ewmctrl--get-window-property-via-id (id property)
  "Internal function to get PROPERTY of window specified
by ID."
  (let ((window-list (ewmctrl--list-windows))
        (property-value ""))
    (dolist (win window-list)
      (if (string= id (cdr (assoc 'window-id win)))
          (setq property-value (cdr (assoc property win)))))
    (if (string= "" property-value)
        (error (concat "ewmctrl--get-window-property-via-id: no window found for ID " id)))
    property-value))

(defun ewmctrl--list-windows ()
  "Internal function to get a list of desktop windows via `wmctrl'."
  (let ((bfr (generate-new-buffer " *ewmctrl-output*"))
        (fields-re (concat "^"
                           (mapconcat 'identity (make-list (1- ewmctrl-field-count) "\\(\\S-+\\)\\s-+") "")
                           "\\(.+\\)"))
        (windows-list '()))
    (call-process-shell-command (concat ewmctrl-wmctrl-path " " ewmctrl-wmctrl-switches) nil bfr)
    (with-current-buffer bfr
      (goto-char (point-min))
      (while (re-search-forward fields-re nil t)
        (let ((window-id (match-string 1))
              (desktop-number (match-string 2))
              (pid (match-string 3))
              (x-offset (match-string 4))
              (y-offset (match-string 5))
              (width (match-string 6))
              (height (match-string 7))
              (client-host (match-string 8))
              (title (match-string 9)))
          (setq windows-list
                (append windows-list
                        (list
                         `((window-id . ,window-id)
                           (desktop-number . ,desktop-number)
                           (pid . ,pid)
                           (x-offset . ,x-offset)
                           (y-offset . ,y-offset)
                           (width . ,width)
                           (height . ,height)
                           (client-host . ,client-host)
                           (title . ,title)))))
          (unless (assoc window-id ewmctrl-window-id-keybind-alist)
            (setq ewmctrl-window-id-keybind-alist
                  (append ewmctrl-window-id-keybind-alist
                          `((,window-id . ,(ewmctrl--assign-key window-id)))))))))
    (kill-buffer bfr)
    (cond
     ((eq 'desktop-number ewmctrl-sort-field)
      (sort windows-list #'(lambda (e1 e2)
                             (<
                              (string-to-number
                               (cdr (assoc 'desktop-number e1)))
                              (string-to-number
                               (cdr (assoc 'desktop-number e2)))))))
     ((eq 'desktop-number-reversed ewmctrl-sort-field)
      (sort windows-list #'(lambda (e1 e2)
                             (<
                              (string-to-number
                               (cdr (assoc 'desktop-number e2)))
                              (string-to-number
                               (cdr (assoc 'desktop-number e1)))))))
     ((eq 'name ewmctrl-sort-field)
      (sort windows-list #'(lambda (e1 e2)
                             (string<
                              (downcase (cdr (assoc 'title e1)))
                              (downcase (cdr (assoc 'title e2)))))))
     ((eq 'name-reversed ewmctrl-sort-field)
      (sort windows-list #'(lambda (e1 e2)
                             (string<
                              (downcase (cdr (assoc 'title e2)))
                              (downcase (cdr (assoc 'title e1)))))))
     ((eq 'pid ewmctrl-sort-field)
      (sort windows-list #'(lambda (e1 e2)
                             (string<
                              (cdr (assoc 'pid e1))
                              (cdr (assoc 'pid e2))))))
     ((eq 'pid-reversed ewmctrl-sort-field)
      (sort windows-list #'(lambda (e1 e2)
                             (string<
                              (cdr (assoc 'pid e2))
                              (cdr (assoc 'pid e1))))))
     (t
      windows-list))))

(defun ewmctrl--move-window-to-other-desktop-by-id (id)
  "Internal function to move the desktop window specified
by ID to a different desktop."
  (let ((desktop (read-string "Move window to desktop number: ")))
    (call-process-shell-command (concat ewmctrl-wmctrl-path " -i -r '" id "' -t '" desktop "'"))
    (ewmctrl-refresh)))

(defun ewmctrl--move-window-to-current-desktop-and-focus-by-id (id)
  "Internal function to move the desktop window specified
by ID to the current desktop, raise it, and give it focus."
  (call-process-shell-command (concat ewmctrl-wmctrl-path " -i -R '" id "'"))
  (ewmctrl-refresh))

(defun ewmctrl--resize-window-by-id (id)
  "Internal function to resize the desktop window specified
by ID."
  (let* ((inhibit-point-motion-hooks nil)
         (keymap (copy-keymap minibuffer-local-map))
         (prompt "Resize window to")
         (width-text " width ")
         (height-text " height ")
         (width (ewmctrl--get-window-property-via-id id 'width))
         (height (ewmctrl--get-window-property-via-id id 'height))
         (current-size
          (concat
           (propertize width-text 'face 'minibuffer-prompt 'read-only t)
           (propertize width 'read-only nil)
           (propertize height-text 'face 'minibuffer-prompt 'read-only t)
           (propertize height 'read-only nil))))
    (define-key keymap [tab]
      #'(lambda ()
          (interactive)
          (cond
           ((looking-at (concat "[0-9]+" height-text))
            (re-search-forward "[0-9]+"))
           ((looking-at height-text)
            (progn
              (re-search-forward "[0-9]")
              (re-search-backward "[0-9]")))
           ((looking-at "[0-9]+$")
            (re-search-forward "$")))))
    (define-key keymap [backtab]
      #'(lambda ()
          (interactive)
          (cond
           ((looking-at "$")
            (progn
              (re-search-backward (concat height-text "[0-9]+"))
              (re-search-forward height-text)))
           ((looking-at "[0-9]+$")
            (re-search-backward height-text))
           ((looking-at height-text)
            (progn
              (re-search-backward (concat width-text "[0-9]"))
              (re-search-forward width-text))))))
    (define-key keymap [C-return]
      #'(lambda ()
          (interactive)
          (let* ((text (buffer-string))
                 (width (progn
                          (string-match (concat width-text "\\([0-9]+\\)") text)
                          (match-string 1 text)))
                 (height (progn
                           (string-match (concat height-text "\\([0-9]+\\)$") text)
                           (match-string 1 text))))
            (call-process-shell-command (concat ewmctrl-wmctrl-path " -i -r '" id "' -e '0,-1,-1," width "," height "'"))
            (ewmctrl-refresh))))
    (define-key keymap [left]
      #'(lambda ()
          (interactive)
          (cond
           ((looking-back height-text)
            (left-char (length height-text)))
           ((not (looking-back width-text))
            (left-char)))))
    (define-key keymap [right]
      #'(lambda ()
          (interactive)
          (cond
           ((looking-at height-text)
            (right-char (length height-text)))
           ((not (looking-at "$"))
            (right-char)))))
    (define-key keymap (kbd "DEL")
      #'(lambda ()
          (interactive)
          (if (not (looking-back width-text))
              (delete-char -1))))
    (let* ((size (read-from-minibuffer prompt current-size keymap))
           (width (progn
                    (string-match "width \\([0-9]+\\)" size)
                    (match-string 1 size)))
           (height (progn
                     (string-match "height \\([0-9]+\\)$" size)
                     (match-string 1 size))))
      ;; man wmctrl(1) states:
      ;;
      ;; "The first value, g, is the gravity of the window, with 0
      ;;  being the most common value (the default value for the window)
      ;;  ...
      ;;  -1 in any position is interpreted to mean that the current
      ;;  geometry value should not be modified."
      (call-process-shell-command (concat ewmctrl-wmctrl-path " -i -r '" id "' -e '0,-1,-1," width "," height "'"))
      (ewmctrl-refresh))))


;; User-facing functions.

(defun ewmctrl-change-window-name (&optional key)
  "Change name of desktop window.

Without optional argument, change name of window whose title
matches the line at point.

With optional argument, change name of window in
`ewmctrl-window-id-keybind-alist' associated with KEY."
  (interactive)
  (if key
      (ewmctrl--change-window-name-by-id (car (rassoc key ewmctrl-window-id-keybind-alist)))
    (ewmctrl--change-window-name-by-id (get-text-property (point) 'window-id))))

(defun ewmctrl-change-window-icon-name (&optional key)
  "Change icon name of desktop window.

Without optional argument, change icon name of window whose
title matches the line at point.

With optional argument, change icon name of window in
`ewmctrl-window-id-keybind-alist' associated with KEY."
  (interactive)
  (if key
      (ewmctrl--change-window-icon-name-by-id (car (rassoc key ewmctrl-window-id-keybind-alist)))
    (ewmctrl--change-window-icon-name-by-id (get-text-property (point) 'window-id))))

(defun ewmctrl-delete-window (&optional key)
  "Delete specified desktop window.

Without optional argument, delete window whose title matches the
line at point.

With optional argument, delete window in
`ewmctrl-window-id-keybind-alist' associated with KEY."
  (interactive)
  (if key
      (ewmctrl--close-window-by-id (car (rassoc key ewmctrl-window-id-keybind-alist)))
    (ewmctrl--close-window-by-id (get-text-property (point) 'window-id))))

(defun ewmctrl-filter-by-desktop-number (filter)
  "Add a filter by desktop number."
  (interactive "sDesktop number: ")
  (ewmctrl--filter-add 'desktop-number filter)
  (ewmctrl-refresh))

(defun ewmctrl-filter-by-name (filter)
  "Add a filter by window name."
  (interactive "sWindow name: ")
  (ewmctrl--filter-add 'name filter)
  (ewmctrl-refresh))

(defun ewmctrl-filter-by-pid (filter)
  "Add a filter by PID."
  (interactive "sPID: ")
  (ewmctrl--filter-add 'pid filter)
  (ewmctrl-refresh))

(defun ewmctrl-filters-clear ()
  "Clear all filtering."
  (interactive)
  (setq ewmctrl-filters nil)
  (message "All filters cleared.")
  (ewmctrl-refresh))

(defun ewmctrl-filter-desktop-number-clear ()
  "Remove all filtering by desktop number."
  (interactive)
  (setq ewmctrl-filters (delq (assoc 'desktop-number ewmctrl-filters) ewmctrl-filters))
  (message "Desktop number filters cleared.")
  (ewmctrl-refresh))

(defun ewmctrl-filter-name-clear ()
  "Remove all filtering by window name."
  (interactive)
  (setq ewmctrl-filters (delq (assoc 'name ewmctrl-filters) ewmctrl-filters))
  (message "Name filters cleared.")
  (ewmctrl-refresh))

(defun ewmctrl-filter-pid-clear ()
  "Remove all filtering by PID."
  (interactive)
  (setq ewmctrl-filters (delq (assoc 'pid ewmctrl-filters) ewmctrl-filters))
  (message "PID filters cleared.")
  (ewmctrl-refresh))

(defun ewmctrl-focus-window (&optional key)
  "Give focus to specified desktop window.

Without optional argument, focus window whose title matches the
line at point.

With optional argument, focus window in
`ewmctrl-window-id-keybind-alist' associated with KEY."
  (interactive)
  (if key
      (ewmctrl--focus-window-by-id (car (rassoc key ewmctrl-window-id-keybind-alist)))
    (ewmctrl--focus-window-by-id (get-text-property (point) 'window-id))))

(defun ewmctrl-move-window-to-other-desktop (&optional key)
  "Move desktop window to a different desktop.

Without optional argument, move the window whose title matches the
line at point.

With optional argument, move the window in
`ewmctrl-window-id-keybind-alist' associated with KEY."
  (interactive)
  (if key
      (ewmctrl--move-window-to-other-desktop-by-id (car (rassoc key ewmctrl-window-id-keybind-alist)))
    (ewmctrl--move-window-to-other-desktop-by-id (get-text-property (point) 'window-id))))

(defun ewmctrl-move-window-to-current-desktop-and-focus (&optional key)
  "Move desktop window to current desktop, raise it and give
it focus.

Without optional argument, move the window whose title matches the
line at point.

With optional argument, move the window in
`ewmctrl-window-id-keybind-alist' associated with KEY."
  (interactive)
  (if key
      (ewmctrl--move-window-to-current-desktop-and-focus-by-id (car (rassoc key ewmctrl-window-id-keybind-alist)))
    (ewmctrl--move-window-to-current-desktop-and-focus-by-id (get-text-property (point) 'window-id))))

(defun ewmctrl-refresh ()
  "Refresh the contents of the *ewmctrl* buffer."
  (interactive)
  (with-current-buffer "*ewmctrl*"
    (let ((inhibit-read-only t)
          (window-list (ewmctrl--list-windows)))
      (erase-buffer)
      (insert (propertize ewmctrl-format-header 'face '(foreground-color . "ForestGreen")))
      (dolist (win window-list)
        (if (and (or ewmctrl-include-sticky-windows
                     (and (not ewmctrl-include-sticky-windows)
                          (not (string= "-1" (cdr (assoc 'desktop-number win))))))
                 (or (not ewmctrl-filters)
                     (and (if (assoc 'desktop-number ewmctrl-filters)
                              (member (cdr (assoc 'desktop-number win)) (cdr (assoc 'desktop-number ewmctrl-filters)))
                            t)
                          (if (assoc 'name ewmctrl-filters)
                              (let ((result nil))
                                (dolist (f (cdr (assoc 'name ewmctrl-filters)))
                                  (if (string-match f (cdr (assoc 'title win)))
                                      (setq result t)))
                                result)
                            t)
                          (if (assoc 'pid ewmctrl-filters)
                              (member (cdr (assoc 'pid win)) (cdr (assoc 'pid ewmctrl-filters)))
                            t))))
            (let ((win-key (cdr (assoc (cdr (assoc 'window-id win)) ewmctrl-window-id-keybind-alist)))
                  (win-desktop (cdr (assoc 'desktop-number win)))
                  (win-pid (cdr (assoc 'pid win)))
                  (win-name (cdr (assoc 'title win))))
              (insert (propertize (eval `(format ,ewmctrl-format-fields ,@ewmctrl-format-fields-order))
                                  'window-id (cdr (assoc 'window-id win))
                                  'title (cdr (assoc 'title win))
                                  'width (cdr (assoc 'width win))
                                  'height (cdr (assoc 'height win))))))))))

(defun ewmctrl-resize-window (&optional key)
  "Resize desktop window.

Without optional argument, resize the window whose title matches the
line at point.

With optional argument, resize the window in
`ewmctrl-window-id-keybind-alist' associated with KEY."
  (interactive)
  (if key
      (ewmctrl--resize-window-by-id (car (rassoc key ewmctrl-window-id-keybind-alist)))
    (ewmctrl--resize-window-by-id (get-text-property (point) 'window-id))))

(defun ewmctrl-sort-by-desktop-number ()
  "Sort list of desktop windows numerically on the desktop number
field."
  (interactive)
  (setq ewmctrl-sort-field 'desktop-number)
  (ewmctrl-refresh))

(defun ewmctrl-sort-by-desktop-number-reversed ()
  "Sort list of desktop windows reverse-numerically on the
desktop number field."
  (interactive)
  (setq ewmctrl-sort-field 'desktop-number-reversed)
  (ewmctrl-refresh))

(defun ewmctrl-sort-by-name ()
  "Sort list of desktop windows lexicographically on the name field."
  (interactive)
  (setq ewmctrl-sort-field 'name)
  (ewmctrl-refresh))

(defun ewmctrl-sort-by-name-reversed ()
  "Sort list of desktop windows reverse-lexicographically on the
name field."
  (interactive)
  (setq ewmctrl-sort-field 'name-reversed)
  (ewmctrl-refresh))

(defun ewmctrl-sort-by-pid ()
  "Sort list of desktop windows numerically on the PID field."
  (interactive)
  (setq ewmctrl-sort-field 'pid)
  (ewmctrl-refresh))

(defun ewmctrl-sort-by-pid-reversed ()
  "Sort list of desktop windows reverse-numerically on the
PID field."
  (interactive)
  (setq ewmctrl-sort-field 'pid-reversed)
  (ewmctrl-refresh))

(defun ewmctrl-toggle-single-key-to-focus ()
  "Toggle whether or not to focus a window simply by pressing
its designated key."
  (interactive)
  (setq ewmctrl-single-key-to-focus (not ewmctrl-single-key-to-focus))
  (if ewmctrl-single-key-to-focus
      (progn
        (setq-local overriding-local-map ewmctrl-single-key-to-focus-map)
        (message "Single key now focuses window."))
    (progn
      (setq-local overriding-local-map nil)
      (message "ewmctrl now using default keybindings."))))


(define-derived-mode ewmctrl-mode special-mode "ewmctrl"
  "Major mode for managing desktop windows via `wmctrl'."
  (read-only-mode)
  (define-key ewmctrl-mode-map (kbd "RET") 'ewmctrl-focus-window)
  (define-key ewmctrl-mode-map (kbd "D") 'ewmctrl-delete-window)
  (define-key ewmctrl-mode-map (kbd "g") 'ewmctrl-refresh)
  (define-key ewmctrl-mode-map (kbd "I") 'ewmctrl-change-window-icon-name)  
  (define-key ewmctrl-mode-map (kbd "fc") 'ewmctrl-filters-clear)
  (define-key ewmctrl-mode-map (kbd "fd") 'ewmctrl-filter-by-desktop-number)
  (define-key ewmctrl-mode-map (kbd "fD") 'ewmctrl-filter-desktop-number-clear)
  (define-key ewmctrl-mode-map (kbd "fn") 'ewmctrl-filter-by-name)
  (define-key ewmctrl-mode-map (kbd "fN") 'ewmctrl-filter-name-clear)
  (define-key ewmctrl-mode-map (kbd "fp") 'ewmctrl-filter-by-pid)
  (define-key ewmctrl-mode-map (kbd "fP") 'ewmctrl-filter-pid-clear)
  (define-key ewmctrl-mode-map (kbd "m") 'ewmctrl-move-window-to-other-desktop)
  (define-key ewmctrl-mode-map (kbd "M") 'ewmctrl-move-window-to-current-desktop-and-focus)
  (define-key ewmctrl-mode-map (kbd "n") 'next-line)
  (define-key ewmctrl-mode-map (kbd "N") 'ewmctrl-change-window-name)
  (define-key ewmctrl-mode-map (kbd "p") 'previous-line)
  (define-key ewmctrl-mode-map (kbd "r") 'ewmctrl-resize-window)
  (define-key ewmctrl-mode-map (kbd "Sd") 'ewmctrl-sort-by-desktop-number)
  (define-key ewmctrl-mode-map (kbd "SD") 'ewmctrl-sort-by-desktop-number-reversed)
  (define-key ewmctrl-mode-map (kbd "Sn") 'ewmctrl-sort-by-name)
  (define-key ewmctrl-mode-map (kbd "SN") 'ewmctrl-sort-by-name-reversed)
  (define-key ewmctrl-mode-map (kbd "Sp") 'ewmctrl-sort-by-pid)
  (define-key ewmctrl-mode-map (kbd "SP") 'ewmctrl-sort-by-pid-reversed)
  (define-key ewmctrl-mode-map (kbd ";") 'ewmctrl-toggle-single-key-to-focus)
  (define-key ewmctrl-single-key-to-focus-map (kbd ";") 'ewmctrl-toggle-single-key-to-focus))

;;;###autoload
(defun ewmctrl ()
  "Create and populate a new *ewmctrl* buffer."
  (interactive)
  (if (not (file-exists-p ewmctrl-wmctrl-path))
      (error "No `wmctrl' executable found at `ewmctrl-wmctrl-path'"))
  (let ((bfr (get-buffer-create "*ewmctrl*")))
    (ewmctrl-refresh)
    (switch-to-buffer bfr)
    (ewmctrl-mode)
    (when ewmctrl-single-key-to-focus
      (setq-local overriding-local-map ewmctrl-single-key-to-focus-map))))


;; --

(provide 'ewmctrl)

;;; ewmctrl.el ends here
