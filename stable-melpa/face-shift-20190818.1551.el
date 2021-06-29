;;; face-shift.el --- Shift the colour of certain faces -*- lexical-binding: t -*-

;; Author: Philip K. <philip@warpmail.net>
;; Version: 0.1.0
;; Package-Version: 20190818.1551
;; Package-Commit: 8c62d7a27a0e3092942742362ed73e17e254e904
;; Keywords: faces
;; Package-Requires: ((emacs "24.4") (cl-lib "0.5"))
;; URL: https://git.sr.ht/~zge/face-shift

;; This file is NOT part of Emacs.
;;
;; This file is in the public domain, to the extent possible under law,
;; published under the CC0 1.0 Universal license.
;;
;; For a full copy of the CC0 license see
;; https://creativecommons.org/publicdomain/zero/1.0/legalcode

;;; Commentary:
;;
;; This library provides a (global) minor mode to shift the fore- and
;; background colours of all buffers towards a certain hue. Which hue
;; which major mode should take on is described in `face-shift-shifts'.

(require 'color)
(require 'face-remap)
(eval-when-compile (require 'subr-x))
(eval-when-compile (require 'cl-lib))

;;; Code:

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
    query-replace
    font-lock-regexp-grouping-construct
    font-lock-regexp-grouping-backslash
    font-lock-preprocessor-face
    font-lock-negation-char-face
    font-lock-warning-face
    font-lock-constant-face
    font-lock-type-face
    font-lock-variable-name-face
    font-lock-function-name-face
    font-lock-builtin-face
    font-lock-keyword-face
    font-lock-doc-face
    font-lock-string-face
    font-lock-comment-delimiter-face
    font-lock-comment-face)
  "Faces that command `face-shift-mode' should distort."
  :type '(list face))

(defcustom face-shift-shifts
  '((text-mode . "khaki")
    (prog-mode . "pale green")
    (dired-mode . "pale turquoise")
    (comint-mode . "wheat")
    (eshell-mode . "wheat"))
  "In what direction to shift what major mode and derivatives.

The first element of each element is a symbol representing the
major mode and all it's derivatives. If a buffer's major mode is
derived from this mode, it will use the string value to shift all
colours in `face-shift-faces' towards the colour in string. If
the colour name is invalid or doesn't exist, it will not apply
any shift.

See info node `(emacs) Colors' or `color-name-to-rgb' for more
information."
  :type '(alist :key-type face :value-type string))

(defvar-local face-shift--cookies nil
  "List of remapped faces in a single buffer.")

(defcustom face-shift-intensity 0.8
  "Relaxation factor when applying a colour-shift.

Positive values between [0;1] will lighten up the resulting shift
more (where 0 is the lightest), while values between [-∞;0] will
darken it (where 0 is the darkest).

Values beyond [-∞;1] are not supported.

See `face-shift--interpolate'."
  :type 'float)

(defun face-shift--interpolate (col-ref col-base)
  "Attempt to find median colour between `col-ref' and `col-base'."
  (cl-map 'list (lambda (ref base)
                  (if (> face-shift-intensity 0)
                      (- 1 (* (- 1 (* ref base)) face-shift-intensity))
                    (* (* ref base) (abs face-shift-intensity))))
          col-ref col-base))

(defun face-shift-setup (&optional buffer)
  "Shift colours in BUFFER according to `face-shift-shifts'.

If BUFFER is nil, use current buffer."
  (with-current-buffer (or buffer (current-buffer))
    (let* ((colour (cdr (cl-assoc-if #'derived-mode-p face-shift-shifts)))
           (col-rgb (and colour (color-name-to-rgb colour))))
      (when colour
        (dolist (face face-shift-faces)
          (dolist (prop '(:foreground :background))
            (let* ((attr (face-attribute face prop))
                   (rgb (and attr (color-name-to-rgb attr)))
                   (shift (and rgb (face-shift--interpolate col-rgb rgb)))
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
