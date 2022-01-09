;;; electric-cursor.el --- Change cursor automatically depending on mode -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Case Duckworth
;; This file is NOT part of GNU Emacs.

;; Author: Case Duckworth <acdw@acdw.net>
;; License: ISC
;; SPDX-License-Identifier: ISC
;; Version: 0.2
;; Package-Version: 20220108.2052
;; Package-Commit: 92f77b05fec80c5440a8b800b33345dabca13872
;; Package-Requires: ((emacs "25.1"))
;; Keywords: terminals, frames
;; URL: https://github.com/duckwork/electric-cursor

;;; Commentary:

;; This package provides a global minor mode, `electric-cursor-mode', which
;; automatically changes the cursor depending on the active mode(s).  The
;; precise modes and associated cursors can be customized with
;; `electric-cursor-alist', which maps modes with their respective cursors.
;; The default value of `electric-cursor-alist' maps `overwrite-mode' to 'block
;; and everything else to `bar'.

;;; Prior Art:

;; - https://github.com/ajsquared/bar-cursor/blob/master/bar-cursor.el

;;; Code:

(eval-when-compile
  (require 'cl-lib))

;;; Variables

(defvar electric-cursor--original-cursor nil
  "The cursor type before calling function `electric-cursor-mode'.")

;;; Customization options

(defgroup electric-cursor nil
  "Customizations for electric cursor functionality."
  :prefix "electric-cursor-"
  :group 'cursor)

(defcustom electric-cursor-alist '((overwrite-mode . box)
                                   (t . bar))
  "Alist of modes and cursors to apply to them.
The car of each of element is a mode or hook, and the cdr is the
`cursor-type', which see."
  :type '(alist :key-type (choice (function :tag "Mode")
                                  (hook :tag "Mode hook"))
                :value-type (get 'cursor-type 'custom-type)))

(defcustom electric-cursor-default-cursor (alist-get t electric-cursor-alist)
  "The cursor to use when no modes in `electric-cursor-alist' are active.
This option is deprecated in favor of using a t car in
`electric-cursor-alist'."
  :type (get 'cursor-type 'custom-type))

(defcustom electric-cursor-set-in-terminal t
  "Should function `electric-cursor-mode' attempt to set cursor in a terminal?"
  :type 'boolean)

;;; Internal functions

(defun electric-cursor--determine (&optional type)
  "Determine the cursor that should be in use.
When TYPE is supplied, use that; otherwise, find the type from
`electric-cursor-alist' or `electric-cursor-default-cursor'."
  (or type
      (cl-loop for (mode . cursor) in electric-cursor-alist
               if (or (eq mode t)
                      (and (boundp mode) (symbol-value mode)))
               return cursor)
      electric-cursor-default-cursor))

(defun electric-cursor--apply-to-hooks (fn)
  "Apply FN to the modes defined in `electric-cursor-alist'."
  (cl-loop for (mode-or-hook . _) in electric-cursor-alist
           do (cond ((eq mode-or-hook t) nil)
                    ((equal (substring (format "%s" mode-or-hook) -5) "-hook")
                     (funcall fn mode-or-hook #'electric-cursor-set-cursor))
                    (t (funcall fn (intern (format "%s-hook" mode-or-hook))
                                #'electric-cursor-set-cursor)))))

;;; Functions

(defun electric-cursor-set-terminal-cursor (&optional type)
  "Set the cursor in a terminal.
Set it to TYPE if provided; otherwise, determine the cursor with
`electric-cursor--determine'."
  (unless type (setq type (electric-cursor--determine)))
  (when (and electric-cursor-set-in-terminal
             (frame-parameter nil 'tty))
    (send-string-to-terminal
     (concat "\e["
             (let ((n (pcase (or (car-safe type) type)
                        ('box 2)
                        ('bar 6)
                        ('hbar 4)
                        (_ 0))))
               (number-to-string (if blink-cursor-mode
                                     (max (1- n) 0)
                                   n)))
             " q"))))

(defun electric-cursor-set-cursor (&optional type)
  "Set the cursor.
When TYPE is non-nil, set the cursor to that; otherwise,
determine the cursor with `electric-cursor--determine'."
  (let ((type (electric-cursor--determine type)))
    (setq cursor-type type)
    (electric-cursor-set-terminal-cursor type)))

(defun electric-cursor-add-hooks ()
  "Add `electric-cursor-set-cursor' to modes in `electric-cursor-alist'."
  (electric-cursor--apply-to-hooks #'add-hook))

(defun electric-cursor-remove-hooks ()
  "Remove `electric-cursor-set-cursor' to modes in `electric-cursor-alist'."
  (electric-cursor--apply-to-hooks #'remove-hook))

;;; Minor mode

;;;###autoload
(define-minor-mode electric-cursor-mode
  "Change the cursor automatically depending on mode.
This global minor mode adds the necessary hooks to modes defined
in `electric-cursor-alist' to change the cursor's shape when
entering and exiting those modes.  It also saves the cursor's
shape and restores it when exiting."
  :lighter " |_"
  :global t
  (if electric-cursor-mode
      (progn                            ; Enable
        (setq electric-cursor--original-cursor cursor-type)
        (electric-cursor-set-cursor)
        (electric-cursor-add-hooks))
    ;; Disable
    (electric-cursor-remove-hooks)
    (electric-cursor-set-cursor electric-cursor--original-cursor)))

(provide 'electric-cursor)
;;; electric-cursor.el ends here
