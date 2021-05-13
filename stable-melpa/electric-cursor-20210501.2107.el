;;; electric-cursor.el --- Change cursor automatically -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Case Duckworth
;; This file is NOT part of GNU Emacs.

;; Author: Case Duckworth <acdw@acdw.net>
;; License: ISC
;; SPDX-License-Identifier: ISC
;; Version: 0.1
;; Package-Version: 20210501.2107
;; Package-Commit: e20c6f6e85c020e472ef05b12af7a12bbae65dbf
;; Package-Requires: ((emacs "24.1"))
;; Keywords: cursor, files
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

(defvar electric-cursor-original-cursor nil
  "The original cursor type before `electric-cursor-mode'.")

;;;###autoload
(define-minor-mode electric-cursor-mode
  "Toggle `electric-cursor-mode'.

This global minor mode adds necessary hooks and functions to
change the cursor's shape, dependent on the modes defined in
`electric-cursor-alist'."
  :lighter " |_"
  :init-value nil
  :keymap nil
  :global t
  (if electric-cursor-mode
      (progn
        (setq electric-cursor-original-cursor cursor-type)
        (electric-cursor-set-cursor)
        (electric-cursor-add-hooks))
    (setq cursor-type electric-cursor-original-cursor)
    (unless (display-graphic-p)
      (send-string-to-terminal "\e[0 q"))
    (electric-cursor-remove-hooks)))

(defcustom electric-cursor-alist '((overwrite-mode . box))
  "The alist of modes and cursors for function `electric-cursor-mode'.

The CAR of each element is the mode, and the CONS is the `cursor-type'."
  :type '(alist
          :value-type (choice
                       (const :tag "Frame default" t)
                       (const :tag "Filled box" box)
                       (const :tag "Hollow cursor" hollow)
                       (const :tag "Vertical bar" bar)
                       (const :tag "Vertical bar with specified width"
                              (const bar) integer)
                       (const :tag "Horizontal bar" hbar)
                       (const :tag "Horizontal bar with specified width"
                              (const hbar) integer)
                       (const :tag "None" nil)))
  :group 'electric-cursor)

(defcustom electric-cursor-default-cursor 'bar
  "The cursor to use when no modes in `electric-cursor-alist' apply."
  :type '(choice
          (const :tag "Frame default" t)
          (const :tag "Filled box" box)
          (const :tag "Hollow cursor" hollow)
          (const :tag "Vertical bar" bar)
          (const :tag "Vertical bar with specified width"
                 (const bar) integer)
          (const :tag "Horizontal bar" hbar)
          (const :tag "Horizontal bar with specified width"
                 (const hbar) integer)
          (const :tag "None" nil))
  :group 'electric-cursor)

(defcustom electric-cursor-set-in-terminal t
  "Whether to set the cursor in a terminal."
  :type 'boolean
  :group 'electric-cursor)

(defun electric-cursor-set-cursor ()
  "Set the cursor according to `electric-cursor-alist'."
  (let ((electric-cursor-type
         (or (catch :found
               (dolist (spec electric-cursor-alist)
                 (when (symbol-value (car spec))
                   (throw :found (cdr spec)))))
             electric-cursor-default-cursor)))
    (cond ((display-graphic-p)
           (setq cursor-type electric-cursor-type))
          (electric-cursor-set-in-terminal
           (send-string-to-terminal
            (concat "\e["
                    (let ((n (pcase (or (car-safe electric-cursor-type)
                                        electric-cursor-type)
                               ('box 2)
                               ('bar 6)
                               ('hbar 4)
                               (_ 0))))
                      (number-to-string (if blink-cursor-mode
                                            (max (1- n) 0)
                                          n)))
                    " q"))))))

(defun electric-cursor-add-hooks ()
  "Add hooks to the modes defined in `electric-cursor-alist'."
  (dolist (spec electric-cursor-alist)
    (unless (eq (car spec) t)
      (let ((hook (intern (concat (symbol-name (car spec)) "-hook"))))
        (add-hook hook #'electric-cursor-set-cursor)))))

(defun electric-cursor-remove-hooks ()
  "Remove hooks from the modes defined in `electric-cursor-alist'."
  (dolist (spec electric-cursor-alist)
    (unless (eq (car spec) t)
      (let ((hook (intern (concat (symbol-name (car spec)) "-hook"))))
        (remove-hook hook #'electric-cursor-set-cursor)))))

(provide 'electric-cursor)

;;; electric-cursor.el ends here
