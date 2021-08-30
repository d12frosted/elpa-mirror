;;; huecycle.el --- Idle color animation -*- lexical-binding: t; -*-

;; Copyright (c) 2021 Phillip O'Reggio
;;
;; Author: Phillip O'Reggio <https://github.com/pnor>
;; Maintainer: Phillip O'Reggio
;; Version: 1.0.0
;; Package-Version: 20210830.340
;; Package-Commit: a05e32351dcff3e61b5f15800556adfe1939c112
;; Package-Requires: ((emacs "27.1"))
;; Keywords: faces
;; Homepage: https://github.com/pnor/huecycle

;; This file is not part of GNU Emacs.

;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;

;;; Commentary:

;; `huecycle' provides idle color animation for any face, or groups of faces.
;; Try it out by setting the faces to huecycle:
;; `(huecycle-set-faces ((foreground . mode-line)))'
;; Then running `(huecycle)' start changing the color.

;;; Code:

(require 'cl-lib)
(require 'color)
(require 'face-remap)

(defgroup huecycle ()
  "Idle color animation for faces."
  :group 'display
  :prefix "huecycle-")

(defcustom huecycle-step-size 0.033333
  "Interval of time between color updates."
  :type '(float)
  :group 'huecycle)

(defcustom huecycle-cycle-duration 0
  "How long to huecycle for before stopping.
Any value <= 0 is treated as infinity."
  :type '(float)
  :group 'huecycle)

(defvar huecycle-buffers-to-huecycle-in (list #'current-buffer)
  "List of buffers that will be affected by `huecycle'.
Is a list of functions with no input that return a buffer. This allows the
 ability to specify static buffers that will always huecycle (using lambda that
 returns the buffer) and dynamic ways to get the buffer (having `current-buffer'
 to product the current buffer to huecycle).")

(defvar huecycle--interpolate-data '()
  "List of `huecycle-interpolate-datum'.")

(defvar-local huecycle--buffer-data '()
  "Buffer local list of interpolation data.")

(defvar huecycle--active-buffers '()
  "List of buffers that have `huecycle--buffer-data' initializes.
Buffers are arranged based on least recently used, where the first entry is most
recent and last least.")

(defvar huecycle--max-active-buffers 10
  "The max number of buffers in `huecycle--active-buffers'.
Each buffer will also have `huecycle--buffer-data'.")

(defvar huecycle--idle-timer nil
  "Idle timer used to start huecycle.")

(defvar huecycle--current-time 0
  "How long huecycle has been cycling for.")

(defvar huecycle--default-start-color "#888888"
  "Start color to use if a face has none, and no color is specified.")

(define-minor-mode huecycle-mode
  "Toggle Huecycle mode.
When Huecycle mode is enabled, faces specified by `huecycle--interpolate-data'
 will change color. The mode is disabled after `huecycle-cycle-duration' secs
 have elapsed or the user has inputted something."
  :lighter " Huecycle"
  nil)

(cl-defstruct (huecycle--color (:constructor huecycle--color-create)
                               (:copier nil))
  "Color struct with named slots for hue, saturation, and luminance."
  hue saturation luminance)

(cl-defstruct (huecycle--interp-datum
               (:constructor huecycle--interp-datum-create)
               (:copier huecycle--copy-interp-datum))
  "Struct holds all data and state for one color-interpolating face."
  (spec-faces-alist '() :documentation
                    "Association list of spec-faces pairs. Key is the SPEC that
affects which aspect of the face will change. Value is a list of the faces
affected. Spec should be `foreground', `background', or `distant-foreground'.")
  (default-start-color nil :documentation
    "Start color to use over the faces spec, as `huecycle--color'")
  (start-colors-alist '() :documentation
                      "alist of interpolated start colors. Key is spec and value
 is list of `huecycle--color'.")
  (end-colors-alist '() :documentation
                    "alist of interpolated end colors. Key is spec and value is
 list of `huecycle--color'.")
  (progress 0.0 :documentation
            "Current interpolation progress")
  (interp-func #'huecycle-interpolate-linear :documentation
               "Function used to interpolate values")
  (next-color-func #'huecycle-get-random-hsl-color :documentation
                   "Function used to determine next color")
  (color-list '() :documentation
              "List of `huecycle--color' used by next-color-func")
  (random-color-hue-range '(0.0 1.0) :documentation
                          "Range of hues that are randomly sampled in
 `huecycle-get-random-hsl-color'")
  (random-color-saturation-range '(0.5 1.0) :documentation
                                 "Range of saturation that are randomly sampled
in `huecycle-get-random-hsl-color'")
  (random-color-luminance-range '(0.2 0.3) :documentation
                                "Range of luminance that are randomly sampled in
`huecycle-get-random-hsl-color'")
  (color-list-index 0 :documentation
                    "Index used internally for next-color-func")
  (cookies nil :documentation
           "Cookies generated by `face-remap-add-relative'")
  (step-multiple 1.0 :documentation
                 "Multiplier on how much to modify speed of interpolation")
  (persist nil :documentation
           "If t, faces that were changed stay changed"))

(defun huecycle--init-interp-datum (spec-faces-alist &rest rest)
  "Helper function to create an `huecycle--interp-datum'.
Create an `huecycle--interp-datum' for the group specified by SPEC-FACES-ALIST.
Each item in SPEC-FACES-ALIST should have a spec as the key (should be
`foreground', `background', or `distant-foreground') and the value is either a
 singular face or list of affected faces. REST are (KEYWORD VALUE) where
  KEYWORDs include:
- `:interp-func': Interpolation function.
\(default: `huecycle-interpolate-linear')
- `:next-color-func': Function used to determine the next color to interpolate
 towards.
\(default: `huecycle-get-random-hsl-color')
- `:start-color': Color all faces in group will start interpolating from,
regardless of its color beforehand.
\(default: nil)
- `:color-list': List of `huecycle--color', used by `:next-color-func'. Should
  be passed in as hex strings, as this function maps them to `huecycle--color'.
\(default: Empty list)
- `:speed': Speed of interpolation.
\(default: 1.0)
- `:random-color-hue-range': range hue values are randomly chosen from (by
 `next-color-func'). Is a list of 2 elements where first <= second.
\(default: (0.0 1.0))
- `:random-color-saturation-range': range saturation values are randomly chosen
 from (by `next-color-func'). Is a list of 2 elements where first <= second.
\(default: (0.5 1.0))
- `:random-color-luminance-range': range luminance values are randomly chosen
 from (by `next-color-func'). Is a list of 2 elements where first <= second.
\(default: (0.2 0.3))
- `:persist' whether the colors changed do not reset.
\(default: nil)"
  (let ((interp-func (plist-get rest :interp-func))
        (next-color-func (plist-get rest :next-color-func))
        (start-color (plist-get rest :start-color))
        (color-list (plist-get rest :color-list))
        (step-multiple (plist-get rest :speed))
        (random-color-hue-range (plist-get rest :random-color-hue-range))
        (random-color-saturation-range
         (plist-get rest :random-color-saturation-range))
        (random-color-luminance-range
         (plist-get rest :random-color-luminance-range))
        (persist (plist-get rest :persist)))
    (huecycle--interp-datum-create
     :spec-faces-alist (let ((verified-spec-faces
                              (mapcar
                               (lambda (spec-faces)
                                 (huecycle--verify-spec-faces spec-faces))
                               spec-faces-alist)))
                         (huecycle--fix-spec-faces-faces-to-list
                          verified-spec-faces))
     :interp-func
     (if interp-func interp-func #'huecycle-interpolate-linear)
     :default-start-color
     (if start-color (huecycle--hex-to-hsl-color start-color) nil)
     :next-color-func
     (if next-color-func next-color-func #'huecycle-get-random-hsl-color)
     :color-list
     (if color-list (mapcar #'huecycle--hex-to-hsl-color color-list) '())
     :step-multiple
     (if step-multiple step-multiple 1.0)
     :random-color-hue-range
     (if random-color-hue-range random-color-hue-range '(0.0 1.0))
     :random-color-saturation-range
     (if random-color-saturation-range random-color-saturation-range '(0.5 1.0))
     :random-color-luminance-range
    (if random-color-luminance-range random-color-luminance-range '(0.2 0.3))
     :persist
     (if persist persist nil))))

(defun huecycle--fix-spec-faces-faces-to-list (spec-faces-alist)
  "Convert all elements of SPEC-FACES-ALIST so `cdr' return list of faces."
  (cl-loop for (spec . faces) in spec-faces-alist collect
           (if (listp faces) `(,spec . ,faces) `(,spec . ,(list faces)))))

(defun huecycle--verify-spec-faces (spec-faces)
  "Assert input, SPEC-FACES, of `huecycle--init-interp-datum' is valid.
Return spec-faces unchanged, or fails assertion if input is invalid."
  (let ((spec (car spec-faces))
        (faces (cdr spec-faces)))
    (cond
     ((listp faces)
      (dolist (face faces)
        (cl-assert (facep face) "FACE in faces isn't a valid face")))
     (t
      (cl-assert (facep faces) "FACES isn't valid face")))
    (cl-assert
     (or (eq spec 'foreground)
         (eq spec 'background)
         (eq spec 'distant-foreground))
     "spec needs to refer to a color"))
  spec-faces)

(defun huecycle--hex-to-rgb (hex)
  "Convert HEX, a hex string with 2 digits per component, to rgb tuple."
  (cl-assert (= (length hex) 7) "hex string should have 2 digits per component")
  (let (
        (red
         (/ (string-to-number (substring hex 1 3) 16) 255.0))
        (green
         (/ (string-to-number (substring hex 3 5) 16) 255.0))
        (blue
         (/ (string-to-number (substring hex 5 7) 16) 255.0)))
    (list red green blue)))

(defun huecycle--hex-to-hsl-color (color)
  "Convert COLOR, a hex string with 2 digits per component, to `huecycle--color'."
  (pcase (apply #'color-rgb-to-hsl (huecycle--hex-to-rgb color))
    (`(,hue ,sat ,lum)
     (huecycle--color-create :hue hue :saturation sat :luminance lum))
    (`(,_) (error "Could not parse color"))))

(defun huecycle--get-start-color (face spec)
  "Return current color of FACE based on SPEC.
If FACE's color is undefined, uses `huecycle--default-start-color'."
  (let* ((attribute
          (cond
           ((eq spec 'foreground) (face-attribute face :foreground))
           ((eq spec 'background) (face-attribute face :background))
           ((eq spec 'distant-foreground) (face-attribute face :distant-foreground))
           (t 'unspecified)))
         (attribute-color
          (if (eq attribute 'unspecified) huecycle--default-start-color attribute))
         (attribute-hex
          (if (and (>= (length attribute-color) 1)
                   (equal "#" (substring attribute-color 0 1)))
              attribute-color
            (apply (lambda (r g b) (color-rgb-to-hex r g b 2)) (color-name-to-rgb attribute-color))))
         (hsl (apply #'color-rgb-to-hsl (huecycle--hex-to-rgb attribute-hex))))
    (pcase hsl
      (`(,hue ,sat ,lum)
       (huecycle--color-create :hue hue :saturation sat :luminance lum))
      (`(,_) (error "Could not parse color")))))

(defun huecycle-get-random-hsl-color (interp-datum)
  "Return random `huecycle--color' using ranges from INTERP-DATUM."
  (let ((hue-range
         (huecycle--interp-datum-random-color-hue-range interp-datum))
        (sat-range
         (huecycle--interp-datum-random-color-saturation-range interp-datum))
        (lum-range
         (huecycle--interp-datum-random-color-luminance-range interp-datum)))
    (huecycle--color-create
     :hue
     (huecycle--get-random-float-from (nth 0 hue-range) (nth 1 hue-range))
     :saturation
     (huecycle--get-random-float-from (nth 0 sat-range) (nth 1 sat-range))
     :luminance
     (huecycle--get-random-float-from (nth 0 lum-range) (nth 1 lum-range)))))

(defun huecycle--get-random-float-from (lower upper)
  "Gets random float from in range [lower, upper].
LOWER and UPPER should be in range [0.0, 1.0]"
  (cl-assert (and (>= lower 0.0) (<= lower 1.0)) "lower is not in range [0, 1]")
  (cl-assert (and (>= upper 0.0) (<= upper 1.0)) "upper is not in range [0, 1]")
  (cl-assert (<= lower upper) "lower should be <= upper")
  (if (= lower upper)
      lower
    (let* ((high-number 10000000000)
           (lower-int (truncate (* lower high-number)))
           (upper-int (truncate (* upper high-number))))
      (/ (* 1.0 (+ lower-int (random (- upper-int lower-int)))) high-number))))

(defun huecycle-get-next-list-color (interp-datum)
  "Get the next color from INTERP-DATUM's color list."
  (let ((color-list
         (huecycle--interp-datum-color-list interp-datum))
        (color-list-index
         (huecycle--interp-datum-color-list-index interp-datum)))
    (unless (= (length color-list) 0)
      (let ((next-color
             (nth
              (huecycle--interp-datum-color-list-index interp-datum)
              color-list)))
        (setf (huecycle--interp-datum-color-list-index interp-datum)
              (mod (1+ color-list-index) (length color-list)))
        next-color))))

(defun huecycle-get-random-color-from-list (interp-datum)
  "Get random color from INTERP-DATUM's color list."
  (let ((color-list (huecycle--interp-datum-color-list interp-datum)))
    (if (= (length (huecycle--interp-datum-color-list interp-datum)) 0)
       nil
      (setf (huecycle--interp-datum-color-list-index interp-datum)
            (random (length color-list)))
      (nth (huecycle--interp-datum-color-list-index interp-datum) color-list))))

(defun huecycle--clamp (value low high)
  "Clamps VALUE between LOW and HIGH."
  (max (min value high) low))

(defun huecycle-interpolate-linear (progress start end)
  "Interpolate `huecycle-color's START and END linearly.
PROGRESS is a float in the range [0, 1], but providing a value outside of that
 will extrapolate new values. START and END are `huecycle--color'."
  (let ((new-hue
         (huecycle--clamp
          (+
           (* (- 1 progress) (huecycle--color-hue start))
           (* progress (huecycle--color-hue end)))
          0 1))
        (new-sat
         (huecycle--clamp
          (+
           (* (- 1 progress) (huecycle--color-saturation start))
           (* progress (huecycle--color-saturation end)))
          0 1))
        (new-lum
         (huecycle--clamp
          (+
           (* (- 1 progress) (huecycle--color-luminance start))
           (* progress (huecycle--color-luminance end)))
          0 1)))
    (huecycle--color-create
     :hue new-hue :saturation new-sat :luminance new-lum)))

(defun huecycle-interpolate-step (progress start end)
  "Interpolate `huecycle-color's START and END with a step function.
If PROGRESS < 0.5, returns START, else returns END."
  (if (< progress 0.5) start end))

(defun huecycle-interpolate-quadratic (progress start end)
  "Interpolate `huecycle-color's START and END using quadratic function.
PROGRESS is float in range [0, 1]."
  (huecycle-interpolate-linear (expt progress 2) start end))

(defun huecycle--hsl-color-to-hex (hsl-color)
  "Convert HSL-COLOR, a `huecycle--color', to hex string.
The hex string will have 2 digits for each component."
  (let ((rgb (color-hsl-to-rgb
              (huecycle--color-hue hsl-color)
              (huecycle--color-saturation hsl-color)
              (huecycle--color-luminance hsl-color))))
    (color-rgb-to-hex (nth 0 rgb) (nth 1 rgb) (nth 2 rgb) 2)))

(defun huecycle--update-progress (new-progress interp-datum)
  "Update INTERP-DATUM's progress.
Progress is updated by by adding NEW-PROGRESS multiplied by INTERP-DATUM's
multiple value."
  (let ((progress (huecycle--interp-datum-progress interp-datum))
        (multiple (huecycle--interp-datum-step-multiple interp-datum)))
    (setq progress (+ progress (* new-progress multiple)))
    (if (>= progress 1.0)
        (progn
          (setq progress 0.0)
          (huecycle--change-next-colors interp-datum)))
    (setf (huecycle--interp-datum-progress interp-datum) progress)))


(defun huecycle--reset-faces (interp-datum)
  "Remove all face modification for all faces in INTERP-DATUM."
  (let ((cookies (huecycle--interp-datum-cookies interp-datum)))
    (dolist (cookie cookies) (face-remap-remove-relative cookie))
    (setf (huecycle--interp-datum-cookies interp-datum) '())))

(defun huecycle--set-all-faces (interp-datum)
  "Apply all face-remaps for all faces in INTERP-DATUM."
  (let* ((spec-faces-alist
          (huecycle--interp-datum-spec-faces-alist interp-datum))
         (interp-func
          (huecycle--interp-datum-interp-func interp-datum))
         (start-colors-alist
          (huecycle--interp-datum-start-colors-alist interp-datum))
         (end-colors-alist
          (huecycle--interp-datum-end-colors-alist interp-datum))
         (progress
          (huecycle--interp-datum-progress interp-datum))
         ;; Apply all face remaps, and get the cookies
         (new-cookies
          (cl-loop for (spec . faces) in spec-faces-alist collect
                   (let* ((start-colors (cdr (assoc spec start-colors-alist)))
                          (end-colors (cdr (assoc spec end-colors-alist))))
                     (cl-mapcar
                      (lambda (face start end)
                        (huecycle--set-face
                         face spec interp-func start end progress))
                      faces start-colors end-colors))))
         (flat-cookies (apply #'append new-cookies)))
    (setf (huecycle--interp-datum-cookies interp-datum) flat-cookies)))

(defun huecycle--set-face (face spec interp-func start-color end-color progress)
  "Apply face-remap to proper aspect of FACE.
Uses FACE's SPEC using INTERP-FUNC to interpolate START-COLOR and END-COLOR at
PROGRESS, and recalculates FACE afterwards."
  (let* ((new-color
          (huecycle--hsl-color-to-hex
           (funcall interp-func progress start-color end-color)))
         (cookie (cond ((eq 'background spec)
                        (face-remap-add-relative face :background new-color))
                       ((eq 'foreground spec)
                        (face-remap-add-relative face :foreground new-color))
                       ((eq 'distant-foreground spec)
                        (face-remap-add-relative face :distant-foreground
                                                 new-color)))))
    cookie))

(defun huecycle--init-colors (interp-datum)
  "Initialize/Reset INTERP-DATUM by setting start and end colors.
Must be called before any other operations on the INTERP-DATUM. If
`interp-datum'  start-colors-alist is not the empty list and persist is t, skips
initializing it."
  (let* ((persist (huecycle--interp-datum-persist interp-datum))
         (before-start-colors-alist
          (huecycle--interp-datum-start-colors-alist interp-datum)))
    (if (and persist before-start-colors-alist)
        nil ;; If it is already initialized and we persist, we should skip init
      (let* ((next-color-func
              (huecycle--interp-datum-next-color-func interp-datum))
             (spec-faces-alist
              (huecycle--interp-datum-spec-faces-alist interp-datum))
             (default-start-color
               (huecycle--interp-datum-default-start-color interp-datum))
             (start-colors-alist
              (cl-loop for (spec . faces) in spec-faces-alist collect
                       (if default-start-color
                           `(,spec . ,(make-list
                                       (length faces) default-start-color))
                         `(,spec . ,(mapcar
                                     (lambda (face)
                                       (huecycle--get-start-color face spec))
                                     faces)))))
             (next-colors-alist
              (let ((next-color (funcall next-color-func interp-datum)))
                (cl-loop for (spec . faces) in spec-faces-alist collect
                         `(,spec . ,(make-list (length faces) next-color))))))
        (setf (huecycle--interp-datum-start-colors-alist interp-datum)
              start-colors-alist)
        (setf (huecycle--interp-datum-end-colors-alist interp-datum)
              next-colors-alist)
        (setf (huecycle--interp-datum-progress interp-datum)
              0.0)))))

(defun huecycle--change-next-colors (interp-datum)
  "Cycle INTERP-DATUM's start and end colors.
End colors become start colors, and the new end colors are determined by
`huecycle--interp-datum-next-color-func'."
  (let* ((end-colors-alist (huecycle--interp-datum-end-colors-alist interp-datum))
         (next-color-func (huecycle--interp-datum-next-color-func interp-datum))
         (spec-faces-alist (huecycle--interp-datum-spec-faces-alist interp-datum))
         (next-color (funcall next-color-func interp-datum))
         (next-colors-alist
          (cl-loop for (spec . faces) in spec-faces-alist
                   collect `(,spec .
                                   ,(make-list
                                     (length (cdr (assoc spec end-colors-alist)))
                                     next-color)))))
    (setf (huecycle--interp-datum-start-colors-alist interp-datum)
          end-colors-alist)
    (setf (huecycle--interp-datum-end-colors-alist interp-datum)
          next-colors-alist)))

;;;###autoload
(defun huecycle ()
  "Start huecycling faces."
  (interactive)
  (let ((buffer-list (mapcar #'funcall huecycle-buffers-to-huecycle-in)))
    (when huecycle--interpolate-data
      (huecycle-mode 1)
      (mapc #'huecycle--setup buffer-list)
      (while (and (not (huecycle--input-pending)) (not (huecycle--time-elapsed)))
        (sit-for huecycle-step-size)
        (huecycle--increment-time)
        (mapc #'huecycle--lerp-colors buffer-list))
      (huecycle--reset-time)
      (mapc #'huecycle--cleanup-faces buffer-list)
      (huecycle-mode 0))))

(defun huecycle--setup (buffer)
  "Setup variables and data in BUFFER for `huecycle--lerp-colors'.
Also sets up buffer local variable `huecycle--buffer-data'."
  (with-current-buffer buffer
    (huecycle--update-buffer-data)
    (mapc #'huecycle--init-colors huecycle--buffer-data)))

(defun huecycle--increment-time ()
  "Increment `huecycle--current-time' by `huecycle--step-size'."
  (setq huecycle--current-time (+ huecycle--current-time huecycle-step-size)))

(defun huecycle--reset-time ()
  "Reset `huecycle--current-time'."
  (setq huecycle--current-time 0))

(defun huecycle--lerp-colors (buffer)
  "Change face appearence in BUFFER for huecycle."
  (with-current-buffer buffer
    (dolist (datum huecycle--buffer-data)
      (huecycle--update-progress huecycle-step-size datum)
      (huecycle--reset-faces datum)
      (huecycle--set-all-faces datum))))

(defun huecycle--lerp-color-in-buffer ())

(defun huecycle--input-pending ()
  "Wrapper around `input-pending-p', to be changed for testing purposes."
  (input-pending-p))

(defun huecycle--cleanup-faces (buffer)
  "Clean up by resetting faces in BUFFER, respecting whether persist is t or nil."
  (with-current-buffer buffer
    (dolist (interp-datum huecycle--buffer-data)
      (if (not (huecycle--interp-datum-persist interp-datum))
          (huecycle--reset-faces interp-datum)))))

(defun huecycle--time-elapsed ()
  "Return t if huecycle has ran for more than `huecycle-cycle-duration' secs.
Always returns nil if `huecycle-cycle-duration' is <= 0."
  (and (> huecycle-cycle-duration 0)
       (> huecycle--current-time huecycle-cycle-duration)))

(defun huecycle--update-buffer-data ()
  "Update huecycle data with the current buffer."
  (if (not (huecycle--buffer-has-active-data (current-buffer)))
      (huecycle--initialize-buffer-data (current-buffer))
    (huecycle--update-recently-used-buffer (current-buffer))))

(defun huecycle--buffer-has-active-data (buffer)
  "Return t if current BUFFER has active interpolation data."
  (and huecycle--buffer-data (member buffer huecycle--active-buffers)))

(defun huecycle--initialize-buffer-data (buffer)
  "Initialize BUFFER with interpolation data, if it isn't already initialized."
  (if (not (huecycle--buffer-has-active-data buffer))
      (progn
        (setq huecycle--buffer-data
              (mapcar #'huecycle--copy-interp-datum huecycle--interpolate-data))
        (huecycle--add-buffer buffer))))

(defun huecycle--update-recently-used-buffer (buffer)
  "Update BUFFER so it is the most recently used in `huecycle--active-buffers'.
buffer most already be in `huecycle--active-buffers'."
  (let* ((old-length (length huecycle--active-buffers))
         (new-active-buffers (delq buffer huecycle--active-buffers))
         (new-length (length new-active-buffers)))
    (if (= old-length new-length)
        (error "%s is not in huecycle--active-buffers!" buffer)
      (push buffer huecycle--active-buffers))))

(defun huecycle--add-buffer (buffer)
  "Add BUFFER to `huecycle--active-buffers'.
If the length of `huecycle--active-buffers' exceeds
`huecycle--max-active-buffers', then a buffer is evicted."
  (push buffer huecycle--active-buffers)
  (if (> (length huecycle--active-buffers) huecycle--max-active-buffers)
      (huecycle--evict-buffers)))

(defun huecycle--evict-buffers ()
  "Evict buffers from `huecycle--active-buffers'.
Removes buffers from `huecycle--active-buffers' until length is less than
`huecycle--max-active-buffers'. Also handles deleting of the
`huecycle--buffer-data' for the deleted buffer."
  (let ((counter 0)
        (new-active-buffers '()))
    (cl-loop for buf in huecycle--active-buffers do
             (progn
               (setq counter (1+ counter))
               (if (> counter huecycle--max-active-buffers)
                   (progn
                     (huecycle--reset-all-faces-for-buffer buf)
                     (huecycle--erase-buffer-data buf))
                 (push buf new-active-buffers))))
    (setq huecycle--active-buffers (nreverse new-active-buffers))))

(defun huecycle--erase-buffer-data (buffer)
  "Erase interpolation data for BUFFER."
  (if (buffer-live-p buffer)
      (with-current-buffer buffer
        (kill-local-variable 'huecycle--buffer-data))))

;;;###autoload
(defun huecycle-stop-idle ()
  "Stop the colorization effect when idle."
  (interactive)
  (if huecycle--idle-timer
      (cancel-timer huecycle--idle-timer))
  (setq huecycle--idle-timer nil))

;;;###autoload
(defun huecycle-when-idle (secs)
  "Start huecycle affect after SECS seconds."
  (interactive "nHow long before huecycle-ing (seconds): ")
  "Starts the colorization effect. when idle for `secs' seconds"
  (huecycle-stop-idle)
  (if (>= secs 0)
      (setq huecycle--idle-timer (run-with-idle-timer secs t #'huecycle))))

;;;###autoload
(defun huecycle-set-cycle-duration (secs)
  "Specify how many SECS faces should huecycle for.
If secs >= 0, will huecycle for an infinite amount of time."
  (interactive "nHow long to huecycle for (seconds): ")
  (setq huecycle-cycle-duration secs))

;;;###autoload
(defun huecycle-reset-all-faces ()
  "Reset faces from huecycling in the current buffer."
  (interactive)
  (huecycle--reset-all-faces-for-buffer (current-buffer)))

(defun huecycle--reset-all-faces-for-buffer (buffer)
  "Reset faces from huecycling in BUFFER."
  (if (buffer-live-p buffer)
      (with-current-buffer buffer
        (mapc #'huecycle--reset-faces huecycle--buffer-data))))

;;;###autoload
(defun huecycle-reset-all-faces-on-all-buffers ()
  "Reset faces from huecycling across all buffers."
  (interactive)
  (mapc #'huecycle--reset-all-faces-for-buffer huecycle--active-buffers)
  (huecycle--erase-all-buffer-data))

(defun huecycle--erase-all-buffer-data ()
  "Erase `huecycle--buffer-data' for all buffers in `huecycle--active-buffers'.
Erases all buffer data and clears `huecycle--active-buffers'."
  (mapc #'huecycle--erase-buffer-data huecycle--active-buffers)
  (setq huecycle--active-buffers '()))

(defmacro huecycle-set-faces (&rest spec-faces-configs)
  "Set which spec-face groups should huecycle.
SPEC-FACES-CONFIGS should include alist entries of (spec . faces) that determine
 which faces change color, and then addition keyword options to configure how it
 changes color. For example:

\(huecycle-set-faces ((foreground . default)))

will make the default face's foreground change over time.
You can add multiple faces to a spec:

\(huecycle-set-faces ((foreground . (default highlight))))

Or add multiple specs to one group:

\(huecycle-set-faces
 ((foreground . (default highlight))
   (background . (link region))))

All faces in one group will sync up their color changes with each other.
You can specify multiple groups, each with their own configuration options:

```
\(huecycle-set-faces
 ((foreground . (org-document-info org-document-title))
  :color-list (\"#FF0000\" \"#00FF00\" \"#0000FF\")
  :next-color-func huecycle-get-next-list-color
  :persist t)
 ((distant-foreground . org-todo)
  :speed 15.0
  :random-color-hue-range (0.0 1.0)
  :random-color-saturation-range (0.0 1.0)
  :random-color-luminance-range (0.5 1.0))
 ((foreground . (org-table))
  (background . (org-table-header))
  :speed 5.0
  :start-color \"#888888\"))
'''

Note that you do not quote lists or functions.
Available options are:
- `:interp-func' Interpolation function
\(default: `huecycle-interpolate-linear').
- `:next-color-func' Function to determine next color to interpolate to
\(default: `huecycle-get-random-hsl-color').
- `:start-color' Color all faces will start with (overrides current spec color)
\(default: nil).
- `:color-list' List of colors that may be used by `:next-color-func'
\(default: Empty list).
Use `huecycle-get-next-list-color' and `huecycle-get-random-color-from-list' as
`:next-color-func', or write your own that uses this field.
- `:speed' Speed of interpolation (default: 1.0).
- `:random-color-hue-range' range hue values are randomly chosen from (by
`next-color-func'). Is a list of 2 elements where first <= second
\(default: (0.0 1.0)).
- `:random-color-saturation-range' range saturation values are randomly chosen
from (by `next-color-func'). Is a list of 2 elements where first <= second
\(default: (0.5 1.0)).
- `:random-color-luminance-range' range luminance values are randomly chosen
from (by `next-color-func'). Is a list of 2 elements where first <= second
\(default: (0.2 0.3)).
- `:persist' whether face should revert when huecycle ends
\(default: nil)."
  (let ((temp-func (make-symbol "conversion-function")))
    `(let ((,temp-func
            (lambda (config)
              (apply #'huecycle--init-interp-datum
                     (huecycle--convert-config-to-init-args config)))))
       (huecycle-reset-all-faces-on-all-buffers)
       (huecycle--erase-all-buffer-data)
       (setq huecycle--interpolate-data
             (mapcar ,temp-func ',spec-faces-configs)))))

(defun huecycle--convert-config-to-init-args (spec-faces-config)
  "Convert SPEC-FACES-CONFIG for use in `huecycle--init-interp-datum'.
For example, given a list:

\( (foreground . default) (background . highlight) :speed 10.0 )

Will convert the beginning to an alist, then retain rest of the keyword value
arguments:

\( ((foreground . default) (background . highlight)) :speed 10.0 )"
  (let ((alist '()) (rest-args '()) (building-alist t))
    (cl-loop for item in spec-faces-config do
             (if building-alist
                 (if (listp item)
                     (push item alist)
                   (progn
                     (setq building-alist nil)
                     (push item rest-args)))
               (push item rest-args)))
    (setq rest-args (nreverse rest-args))
    (push alist rest-args)
    rest-args))

(provide 'huecycle)

;;; huecycle.el ends here
