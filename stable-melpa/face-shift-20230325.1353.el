;;; face-shift.el --- Shift the colour of certain faces -*- lexical-binding: t -*-

;; Copyright (C) 2019, 2021, 2023  Free Software Foundation, Inc.

;; Author: Philip Kaludercic <philipk@posteo.net>
;; Version: 0.2.1
;; Package-Version: 20230325.1353
;; Package-Commit: 671e53fdef9ed3fdb9ee768216d05b90e3ce592a
;; Keywords: faces
;; Package-Requires: ((emacs "24.1"))
;; URL: https://git.sr.ht/~pkal/face-shift

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides a (global) minor mode to shift the fore- and
;; background colours of all buffers towards a certain hue.  Which hue
;; which major mode should take on is described in
;; `face-shift-shifts'.

;;; Code:

(require 'color)
(require 'face-remap)

(defgroup face-shift nil
  "Distort colour of certain faces."
  :group 'faces
  :prefix "face-shift-")

(defcustom face-shift-faces
  '(default
    cursor
    highlight
    region
    shadow
    secondary-selection
    isearch
    isearch-fail
    lazy-highlight
    match
    query-replace)
  "Faces that command `face-shift-mode' should distort."
  :type '(list face))

(defcustom face-shift-shifts
  '((text-mode . "linen")
    (help-mode . "lavender blush")
    (prog-mode . "honeydew")
    (dired-mode . "azure")
    (comint-mode . "light yellow")
    (eshell-mode . "light yellow"))
  "In what direction to shift what major mode and derivatives.

The first element of each element is a symbol representing the
major mode and all it's derivatives.  If a buffer's major mode is
derived from this mode, it will use the string value to shift all
colours in `face-shift-faces' towards the colour in string.  If
the colour name is invalid or doesn't exist, it will not apply
any shift.

See info node `(emacs) Colors' or `color-name-to-rgb' for more
information."
  :type '(alist :key-type face :value-type string))

(defcustom face-shift-shift-foreground nil
  "Non-nil means shift the forground color too."
  :type 'boolean)

(defvar face-shift--cookies nil
  "List of remapped faces in a single buffer.")
(make-variable-buffer-local 'face-shift--cookies)

(defcustom face-shift-intensity (/ (1+ (sqrt 5)) 2)
  "Relaxation factor when applying a colour-shift.

See `face-shift--interpolate'."
  :type 'number)

(defun face-shift--interpolate (col-ref col-base)
  "Attempt to find median colour between COL-REF and COL-BASE."
  (let (results)
    (while (and col-ref col-base)
      (let ((ref (pop col-ref))
            (base (pop col-base)))
        (push (if (> face-shift-intensity 0)
                  (- 1 (* (- 1 (* ref base)) face-shift-intensity))
                (* (* ref base) (abs face-shift-intensity)))
              results)))
    (nreverse results)))

(defun face-shift-setup (&optional buffer)
  "Shift colours in BUFFER according to `face-shift-shifts'.

If BUFFER is nil, use current buffer."
  (with-current-buffer (or buffer (current-buffer))
    (let ((colour (cdr (assoc (apply #'derived-mode-p
                                     (mapcar #'car face-shift-shifts))
                              face-shift-shifts))))
      (when colour
        (dolist (face face-shift-faces)
          (dolist (prop (if face-shift-shift-foreground
                            '(:background :foreground)
                          '(:background)))
            (let* ((attr (face-attribute face prop))
                   (rgb (and attr (color-name-to-rgb attr)))
                   (shift (and rgb (face-shift--interpolate
                                    (color-name-to-rgb colour)
                                    rgb)))
                   (new (and shift (apply #'color-rgb-to-hex shift))))
              (when new
                (push (face-remap-add-relative face `(,prop ,new))
                      face-shift--cookies)))))))))

(defun face-shift-clear (buffer)
  "Undo colour shifts in BUFFER by `face-shift-setup'."
  (with-current-buffer buffer
    (dolist (cookie face-shift--cookies)
      (face-remap-remove-relative cookie))
    (setq face-shift--cookies nil)))

;;;###autoload
(define-minor-mode face-shift-mode
  "Shift fore- and background colour towards a certain hue.

See `face-shift-shifts' and `face-shift-intensity' for more
information"
  :group 'face-shift
  :global t
  (if face-shift-mode
      (progn
        (mapc #'face-shift-setup (buffer-list))
        (add-hook 'after-change-major-mode-hook #'face-shift-setup))
    (mapc #'face-shift-clear (buffer-list))
    (remove-hook 'after-change-major-mode-hook #'face-shift-setup)))

(provide 'face-shift)

;;; face-shift.el ends here
