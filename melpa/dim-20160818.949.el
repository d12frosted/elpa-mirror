;;; dim.el --- Change mode-line names of major/minor modes  -*- lexical-binding: t -*-

;; Copyright © 2015, 2016 Alex Kost

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 24 Dec 2015
;; Version: 0.1
;; Package-Version: 20160818.949
;; Package-Commit: 5515f2e8657ef14adcc34aa5b05383a2684328ae
;; URL: https://github.com/alezost/dim.el
;; Keywords: convenience
;; Package-Requires: ((emacs "24.4"))

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

;; The purpose of this package is to "customize" the mode-line names of
;; major and minor modes.  An example of using:
;;
;; (when (require 'dim nil t)
;;   (dim-major-names
;;    '((emacs-lisp-mode    "EL")
;;      (lisp-mode          "CL")
;;      (Info-mode          "I")
;;      (help-mode          "H")))
;;   (dim-minor-names
;;    '((auto-fill-function " ↵")
;;      (isearch-mode       " 🔎")
;;      (whitespace-mode    " _"  whitespace)
;;      (paredit-mode       " ()" paredit)
;;      (eldoc-mode         ""    eldoc))))

;; Along with `dim-major-names' and `dim-minor-names', you can use
;; `dim-major-name' and `dim-minor-name' to change the names by one.

;; Many thanks to the author of
;; <http://www.emacswiki.org/emacs/delight.el> package, as the code of
;; this file is heavily based on it.

;; For more verbose description, see README at
;; <https://github.com/alezost/dim.el>.

;;; Code:

(defgroup dim nil
  "Change mode-line names of major and minor modes."
  :group 'convenience)

(defcustom dim-everywhere nil
  "If non-nil, just set `mode-name' to the 'dimmed' name.
If nil, try to be more clever to change the name only for the
mode-line.  Particularly, display the original `mode-name' in the
mode description (\\[describe-mode])."
  :type 'boolean
  :group 'dim)

(defvar dim-major-names nil
  "List of specifications for changing `mode-name'.
Each element of the list should be a list of arguments taken by
`dim-major-name' function.")

(defvar dim-inhibit-major-name nil
  "If non-nil, original mode names are used instead of names from
`dim-major-names' variable.")

(defun dim-get-major-name (mode)
  "Return MODE name from `dim-major-names' variable."
  (cadr (assq mode dim-major-names)))

(defun dim-set-major-name (&rest _)
  "Replace `mode-name' of the current major mode.
Use the appropriate name from `dim-major-names' variable.

This function ignores the arguments to make it suitable for using
in advices.  For example, if you changed `mode-name' of
`dired-mode', you'll be surprised that it returns to \"Dired\"
after exiting from `wdired-mode'.  This happens because \"Dired\"
string is hard-coded in `wdired-change-to-dired-mode'.  This can
be workaround-ed by using the following advice:

  (advice-add 'wdired-change-to-dired-mode :after #'dim-set-major-name)"
  (let ((new-name (dim-get-major-name major-mode)))
    (when new-name
      (setq mode-name
            (if dim-everywhere
                new-name
              `(dim-inhibit-major-name ,mode-name ,new-name))))))

(add-hook 'after-change-major-mode-hook 'dim-set-major-name)

(defun dim-inhibit-major-name (fun &rest args)
  "Apply FUN to ARGS with temporary disabled 'dimmed' major mode names.
This function is intended to be used as an 'around' advice for
FUN.  Such advice is needed for `format-mode-line' function, as
it allows to use the original `mode-name' value when it is
displayed in `describe-mode' help buffer."
  (let ((dim-inhibit-major-name t))
    (apply fun args)))

(advice-add 'format-mode-line :around #'dim-inhibit-major-name)

(defun dim-add-or-set (var name &rest values)
  "Add (NAME VALUES ...) element to the value of VAR.
If VAR already has NAME element, change its VALUES."
  (set var
       (cons (cons name values)
             (assq-delete-all name (symbol-value var)))))

;;;###autoload
(defun dim-major-name (mode new-name)
  "Set mode-line name of the major MODE to NEW-NAME.
The change will take effect next time the MODE will be enabled."
  (dim-add-or-set 'dim-major-names mode new-name))

;;;###autoload
(defun dim-major-names (specs)
  "Change names of major modes according to SPECS list.
Each element of the list should be a list of arguments taken by
`dim-major-name' function."
  (if (null dim-major-names)
      (setq dim-major-names specs)
    (dolist (spec specs)
      (apply #'dim-major-name spec))))

(defun dim--minor-name (mode new-name)
  "Subroutine of `dim-minor-name'."
  (if (not (boundp mode))
      (message "Unknown minor mode '%S'." mode)
    (dim-add-or-set 'minor-mode-alist mode new-name)))

;;;###autoload
(defun dim-minor-name (mode new-name &optional file)
  "Set mode-line name of the minor MODE to NEW-NAME.
FILE is a feature or file name where the MODE comes from.  If it
is specified, it is passed to `eval-after-load'.  If it is nil,
MODE name is changed immediately (if the MODE is available)."
  (if file
      (eval-after-load file
        `(dim--minor-name ',mode ',new-name))
    (dim--minor-name mode new-name)))

;;;###autoload
(defun dim-minor-names (specs)
  "Change names of minor modes according to SPECS list.
Each element of the list should be a list of arguments taken by
`dim-minor-name' function."
  (dolist (spec specs)
    (apply #'dim-minor-name spec)))

(provide 'dim)

;;; dim.el ends here
