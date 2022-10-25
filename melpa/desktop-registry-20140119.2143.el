;;; desktop-registry.el --- Keep a central registry of desktop files -*- lexical-binding: t -*-

;; Copyright (C) 2013, 2014  Tom Willemse

;; Author: Tom Willemse <tom@ryuslash.org>
;; Keywords: convenience
;; Version: 1.2.0
;; URL: http://projects.ryuslash.org/desktop-registry/

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

;; This module provides functions and a global minor mode that lets
;; you track a central registry of desktop files.  This is useful when
;; you use desktop files as project files and want to be able to
;; easily switch between them.

;;; Installation

;; This module is available both on Marmalade and MELPA, so if you
;; have either of those set-up it should be as easy as `M-x
;; install-package RET desktop-registry RET'.

;;; Usage

;; To start using it you need to have a desktop loaded in Emacs, you
;; can then use `desktop-registry-add-current-desktop' to register
;; it.  If you don't have a desktop loaded, you can use
;; `desktop-registry-add-directory' to add a directory containing an
;; Emacs desktop.  It is also possible to use
;; `desktop-registry-auto-register' to have desktops registered
;; automatically upon saving them.

;; After some desktops have been registered you can switch between
;; them by using `desktop-registry-change-desktop'.  This will close
;; the current desktop (without saving) and open the selected one.

;; If it happens that you have accumulated quite a few desktops and
;; you would like to have an overview of them and perform some
;; management tasks, `desktop-registry-list-desktops' will show a list
;; of the registered desktops, along with an indicator if they still
;; exist on the filesystem.

;;; Configuration

;; Apart from the functions to add, remove and rename desktops, and
;; the desktop list, it is also possible to use Emacs' customize
;; interface to change, remove or add desktops in/from/to the registry
;; with the `desktop-registry-registry' user option.

;; There is also the `desktop-registry-list-switch-buffer-function'
;; user option that lets you choose which function to use to show the
;; buffer when calling `desktop-registry-list-desktops'.  By default
;; this is `switch-to-buffer-other-window'.

;;; Code:

(require 'desktop)

(defgroup desktop-registry nil
  "Customization group for desktop-registry."
  :group 'desktop
  :prefix 'desktop-registry)

(defcustom desktop-registry-registry nil
  "The main registry of desktop files.

Almost all of the important functions work on this variable.  As
such it can be edited using these functions, either directly or
from the desktop list, or using the Emacs customize interface."
  :group 'desktop-registry
  :type '(repeat (cons string directory)))

(defcustom desktop-registry-list-switch-buffer-function
  #'switch-to-buffer-other-window
  "The function to use to switch to the desktop list buffer.

When `desktop-registry-list-desktops' is called, it uses the
value of this option to switch to the buffer.  By default it uses
`switch-to-buffer-other-window', but functions like
`switch-to-buffer' or `switch-to-buffer-other-frame' are also
examples of valid functions."
  :group 'desktop-registry
  :type 'function)

(defvar desktop-registry-list-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map "o" #'desktop-registry-change-desktop)
    (define-key map "R" #'desktop-registry-rename-desktop)
    (define-key map "d" #'desktop-registry-remove-desktop)
    (define-key map "a" #'desktop-registry-add-directory)
    (define-key map "A" #'desktop-registry-add-current-desktop)
    map))

(defvar dreg--history nil
  "History variable for `desktop-registry'.")

(defun dreg--canonicalize-dir (dir)
  "Canonicalize DIR for use."
  (directory-file-name (expand-file-name dir)))

(defun dreg--desktop-in-row ()
  "If `desktop-registry-list-mode' is active, return the current rowid."
  (and (eql major-mode 'desktop-registry-list-mode)
       (tabulated-list-get-id)))

(defun dreg--completing-read (&optional prompt default-current)
  "Ask the user to pick a desktop directory.

PROMPT specifies the prompt to use when asking, which defaults to
\"Desktop: \". DEFAULT-CURRENT specifies whether to use the
current desktop as default value."
  (let ((prompt (or prompt "Desktop: "))
        (default (and default-current
                      (desktop-registry-current-desktop))))
    (completing-read prompt desktop-registry-registry nil nil nil
                     'dreg--history default)))

(defun dreg--get-desktop-name (&optional prompt default-current)
  "Get the name of a desktop.

This is done by either looking at the desktop name at point, in
case `desktop-registry-list-mode' is active, or asks the user to
provide a name with completion.  The parameters PROMPT and
DEFAULT-CURRENT are passed directly to `dreg--completing-read'
when no desktop is found at point."
  (or (dreg--desktop-in-row)
      (dreg--completing-read prompt default-current)))

(defun dreg--prepare-row (data)
  "Format a row of DATA for `tabulated-list-entries'."
  (let* ((name (car data))
         (dir (cdr data))
         (existsp (and (file-exists-p dir)
                       (file-directory-p dir))))
    (list name (vector name (if existsp "yes" "no") dir))))

(defun dreg--refresh-list ()
  "Fill `tabulated-list-entries' with registered desktops."
  (setq tabulated-list-entries
        (mapcar #'dreg--prepare-row desktop-registry-registry)))

;;;###autoload
(defun desktop-registry-current-desktop (&optional default)
  "Get the name of the currently loaded desktop.

Returns DEFAULT when the variable `desktop-dirname' is nil, which
means there is no desktop currently loaded."
  (if desktop-dirname
      (let ((canonical (dreg--canonicalize-dir desktop-dirname)))
        (car (cl-find-if (lambda (d) (equal (cdr d) canonical))
                         desktop-registry-registry)))
    default))

;;;###autoload
(defun desktop-registry-add-directory (dir &optional name)
  "Add DIR to the desktop registry, possibly using NAME.

If this command is called interactively, the location for DIR is
requested of the user, and if the universal argument (`C-u') was
used before calling this command a name will also be requested
for this directory.  This is useful when the directory name is
not the project name or when it would result in duplicate entries
in `desktop-registry-registry'."
  (interactive (list (read-directory-name "Directory: ")
                     (if (equal current-prefix-arg '(4))
                         (read-string "Name: "))))
  (let* ((clean-dir (dreg--canonicalize-dir dir))
         (label (or name (file-name-nondirectory clean-dir))))
    (cond
     ((cl-find clean-dir desktop-registry-registry
               :key 'cdr :test 'equal)
      (message "Directory %s already registered" clean-dir))
     ((cl-find label desktop-registry-registry :key 'car :test 'equal)
      (error "Name %s already used" label))
     (t (customize-save-variable
         'desktop-registry-registry
         (cons (cons label clean-dir) desktop-registry-registry))))))

;;;###autoload
(defun desktop-registry-add-current-desktop (&optional name)
  "Add the currently opened desktop file to `desktop-registry-registry'.

If NAME is specified use that as the name for the registry entry.

If this command is called interactively and the universal
argument (`C-u') was used before calling this command the name
will be requested of the user.  This is useful when the directory
name is not the project name or when it would result in duplicate
entries in `desktop-registry-registry'."
  (interactive (list (if (equal current-prefix-arg '(4))
                         (read-string "Name: "))))
  (unless desktop-dirname
    (error "No desktop loaded"))
  (desktop-registry-add-directory desktop-dirname name))

;;;###autoload
(defun desktop-registry-remove-desktop (desktop)
  "Remove DESKTOP from the desktop registry.

If this command is called interactively DESKTOP will be inferred
from the location of the cursor when viewing the desktop list, or
will be asked of the user (with completion) when the desktop list
is not currently shown."
  (interactive (list (dreg--get-desktop-name "Remove: " t)))
  (let ((spec (assoc desktop desktop-registry-registry)))
    (if spec
        (customize-save-variable
         'desktop-registry-registry
         (delete spec desktop-registry-registry))
      (error "Unknown desktop: %s" desktop))))

;;;###autoload
(defun desktop-registry-rename-desktop (old new)
  "Rename desktop OLD to NEW.

If this command is called interactively OLD will be inferred from
the location of the cursor when viewing the desktop list, or will
be asked of the user (with completion) when the desktop list is
not currently shown.  NEW is always asked of the user."
  (interactive (list (dreg--get-desktop-name "Rename: " t)
                     (read-string "to: ")))
  (let ((spec (assoc old desktop-registry-registry)))
    (if (not spec)
        (error "Unknown desktop: %s" old)
      (setf (car spec) new)
      (customize-save-variable 'desktop-registry-registry
                               desktop-registry-registry))))

;;;###autoload
(defun desktop-registry-change-desktop (name)
  "Change to the desktop named NAME.

If this command is called interactively NAME will be inferred
from the location of the cursor when viewing the desktop list, or
will be asked of the user (with completion) when the desktop list
is not currently shown.

This function just calls `desktop-change-dir' with the directory
attached to NAME."
  (interactive (list (dreg--get-desktop-name "Switch to: ")))
  (desktop-change-dir (cdr (assoc name desktop-registry-registry))))

;;;###autoload
(define-minor-mode desktop-registry-auto-register
  "Automatically add saved desktops to the registry.

Enabling this global minor mode will add
`desktop-registry-add-current-desktop' as a hook to
`desktop-save-hook'."
  :global t
  (if desktop-registry-auto-register
      (add-hook 'desktop-save-hook
                'desktop-registry-add-current-desktop)
    (remove-hook 'desktop-save-hook
                 'desktop-registry-add-current-desktop)))

(define-derived-mode desktop-registry-list-mode tabulated-list-mode
  "Desktop Registry"
  "Major mode for listing registered desktops.

\\<desktop-registry-list-mode-map>
\\{desktop-registry-list-mode-map}"
  (setq tabulated-list-format [("Label" 30 t)
                               ("Exists" 6 nil)
                               ("Location" 0 t)]
        tabulated-list-sort-key '("Label"))
  (add-hook 'tabulated-list-revert-hook #'dreg--refresh-list nil :local)
  (tabulated-list-init-header))

;;;###autoload
(defun desktop-registry-list-desktops ()
  "Display a list of registered desktops.

Most functions that are available as interactive commands
elsewhere are also specialized to work here.  For example:
`desktop-registry-change-desktop' will open the desktop under the
user's cursor when called from this list.

The way the buffer is shown can be customized by specifying a
function to use in
`desktop-registry-list-switch-buffer-function'."
  (interactive)
  (let ((buffer (get-buffer-create "*Desktop Registry*")))
    (with-current-buffer buffer
      (desktop-registry-list-mode)
      (dreg--refresh-list)
      (tabulated-list-print))
    (funcall desktop-registry-list-switch-buffer-function buffer))
  nil)

(provide 'desktop-registry)
;;; desktop-registry.el ends here
