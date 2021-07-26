;;; face-shift.el --- Shift the colour of certain faces -*- lexical-binding: t -*-

;; Author: Philip Kaludercic <philipk@posteo.net>
;; Version: 0.2.0
;; Package-Version: 20210725.2146
;; Package-Commit: 14dce79fc42116c49eb4c8a4ab7ca3c4bd7cbf6f
;; Keywords: faces
;; Package-Requires: ((emacs "24.1"))
;; URL: https://git.sr.ht/~pkal/face-shift

;; This file is NOT part of Emacs.
;;
;; This file is in the public domain, to the extent possible under law,
;; published under the CC0 1.0 Universal license.
;;
;; For a full copy of the CC0 license see
;; https://creativecommons.org/publicdomain/zero/1.0/legalcode

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
