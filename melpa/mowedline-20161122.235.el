;;; mowedline.el --- elisp utilities for using mowedline

;; This file is part of mowedline.
;; Copyright (C) 2011-2016  John J. Foerch

;; Author: John Foerch <jjfoerch@earthlink.net>
;; Version: 0.7
;; Package-Version: 20161122.235
;; Package-Commit: 6121b7d4aacd18f7b24da226e61dbae054e50a7c
;; Date: 2016-11-21

;; mowedline is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; mowedline is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with mowedline.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides utilities for interacting with the status bar
;; program mowedline.
;;
;; - mowedline-update: performs a mowedline update for the given widget
;;       and value by dispatching to the function given by
;;       `mowedline-update-function' (default `mowedline-update/client').
;;
;; - mowedline-update/client: calls mowedline update via the
;;       mowedline-client program.
;;
;; - mowedline-update/dbus: calls mowedline update via dbus directly for
;;       the given widget and value.
;;
;; - mowedline-colorize: converts a propertied Emacs string into a string
;;       of mowedline markup, preserving foreground colors.
;;

;;; Code:

(require 'dbus)

(defvar mowedline-client "mowedline-client"
  "Name of the mowedline-client executable.")

(defun mowedline-update/client (widget value)
  "Call mowedline-client update for the given widget and value."
  (call-process
   mowedline-client nil 0 nil
   "update"
   (if (symbolp widget)
       (symbol-name widget)
     widget)
   value))

(defun mowedline-update/dbus (widget value)
  "Perform a mowedline update for the given widget and value
directly via dbus."
  (condition-case err
      (dbus-call-method
       :session "net.retroj.mowedline" "/net/retroj/mowedline"
       "net.retroj.mowedline" "update"
       :timeout 0
       (if (symbolp widget)
           (symbol-name widget)
         widget)
       value)
    (dbus-error
     (unless (string-match "call timed out"
                           (error-message-string err))
       (signal (car err) (cdr err))))))

(defvar mowedline-update-function 'mowedline-update/client)

(defun mowedline-update (widget value)
  "Perform a mowedline update for the given widget and value by
dispatching to the update function given by
`mowedline-update-function`."
  (funcall mowedline-update-function widget value))

(defun mowedline-clear (widget)
  "Clear the given widget."
  (mowedline-update widget ""))

(defun mowedline-string-break-by-property (str prop)
  (let ((len (length str))
        (p 0)
        q l)
    (while (setq q (next-single-property-change p prop str))
      (setq l (cons (substring str p q) l))
      (setq p q))
    (unless (= p len)
      (setq l (cons (substring str p len) l)))
    (nreverse l)))

(defun mowedline-colorize (str &optional trim)
  "Translate the string STR into a string representation of a
mowedline markup structure, with `color' groups that preserve the
foreground colors of the faces from the original string."
  (when trim
    (while (string-match "\\`\n+\\|^\\s-+\\|\\s-+$\\|\n+\\'"
                         str)
      (setq str (replace-match "" t t str))))
  (if (string= "" str)
      "()"
    (format
     "%S"
     (mapcar
      (lambda (x)
        (let ((face (get-text-property 0 'face x)))
          (if face
              `(color ,(face-foreground face)
                      ,(substring-no-properties x))
            x)))
      (mowedline-string-break-by-property str 'face)))))

(provide 'mowedline)
;;; mowedline.el ends here
