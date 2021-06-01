;;; langtool-ignore-fonts.el --- Force langtool to ignore certain fonts  -*- lexical-binding: t -*-

;; Copyright (C) 2021 Christopher Lloyd

;; Author: Christopher Lloyd <cjl8zf@virginia.edu>
;; URL: https://github.com/cjl8zf/langtool-ignore-fonts
;; Package-Version: 20210526.2340
;; Package-Commit: c3291c85b733b9047653cbb1f525655394610bdb
;; Version: 0.3
;; Package-Requires: ((emacs "25.1") (langtool "2.2.1"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Force langtool to ignore certain fonts.

;;; Code:

(require 'cl-lib)

(defcustom langtool-ignore-fonts-major-mode-font-list
  '((latex-mode
     font-lock-comment-face
     font-latex-math-face
     font-latex-string-face))
  "Font faces that should be ignored by `langtool' in a given `major-mode'."
  :type 'sexp
  :group 'langtool)

(defcustom langtool-ignore-fonts nil
  "Font faces that `langtool' should ignore in current buffer.
This variable is buffer local so that the behavior of `langtool'
can be altered based on the current `major-mode'."
  :type 'sexp
  :group 'langtool
  :local 't)

(defun langtool-ignore-fonts--get-overlays ()
  "Find all of the `langtool' overlays.
This function assumes that `langtool-check' has already been run.
We first call 'font-lock-ensure to ensure that reigons outside of
accessible buffer have had font-lock applied."
  (font-lock-ensure)
  (seq-filter
   (lambda (ov) (overlay-get ov 'langtool-message))
   (overlays-in 0 (buffer-size))))

(defun langtool-ignore-fonts--overlay-matches-font-p (ov)
  "Check to see if the overlay OV region font is on our list of fonts."
  (or (langtool-ignore-fonts--pos-matches-font-p (overlay-start ov))
      (langtool-ignore-fonts--pos-matches-font-p (overlay-end ov))))

(defun langtool-ignore-fonts--pos-matches-font-p (pos)
  "Check to see if the character at POS has a font from the `langtool-ignore-fonts' list."
  (< 0 (length (cl-intersection langtool-ignore-fonts
				(langtool-ignore-fonts--treat-as-list (get-text-property pos 'face))))))

(defun langtool-ignore-fonts--treat-as-list (x)
  "If X is a single value wrap it as a singleton otherwise leave it alone."
  (if (listp x) x (list x)))

(defun langtool-ignore-fonts--get-matched-font-overlays ()
  "Get a list of all of the langtool-overlays that match the `langtool-ignore-fonts' list."
  (seq-filter #'langtool-ignore-fonts--overlay-matches-font-p (langtool-ignore-fonts--get-overlays)))

(defun langtool-ignore-fonts--delete-matched-overlays ()
  "Delete any langtool overlays that match the font list `langtool-ignore-fonts'."
  (mapc #'delete-overlay (langtool-ignore-fonts--get-matched-font-overlays)))

(defun langtool-ignore-fonts--delete-matched-overlays-advice (&rest _args)
  "Advise with ARGS to remove overlays matching `langtool-ignore-fonts'.
This function should be called after 'langtool--check-finish."
  (message "Removing langtool overlays matching 'langtool-ignore-fonts.")
  (mapc #'delete-overlay (langtool-ignore-fonts--get-matched-font-overlays))
  (message "Done removing overlays."))

(defun langtool-ignore-fonts--enable ()
  "Enable `langtool-ignore-fonts'.
Add advice to `langtool--check-finish' to remove fonts set with
`langtool-ignore-fonts-add'."
  (advice-add 'langtool--check-finish :after #'langtool-ignore-fonts--delete-matched-overlays-advice)
  (let ((major-mode-fonts (cdr (assoc major-mode langtool-ignore-fonts-major-mode-font-list))))
    (setq-local langtool-ignore-fonts major-mode-fonts)))

(defun langtool-ignore-fonts--disable ()
  "Disable `langtool-ignore-fonts'."
  (advice-remove 'langtool--check-finish #'langtool-ignore-fonts--delete-matched-overlays-advice))

;;;###autoload
(define-minor-mode langtool-ignore-fonts-minor-mode
  "Automically remove `langtool' overlays with font matching `langtool-ignore-fonts'"
  :lighter " LT:IF"
  (if langtool-ignore-fonts-minor-mode
      (langtool-ignore-fonts--enable)
    (langtool-ignore-fonts--disable)))

(defun langtool-ignore-fonts-add (mode fonts)
  "Add FONTS to the list of fonts to be ignored by `langtool' in MODE."
  (add-to-list 'langtool-ignore-fonts-major-mode-font-list (cons mode fonts)))

(provide 'langtool-ignore-fonts)

;;; langtool-ignore-fonts.el ends here
