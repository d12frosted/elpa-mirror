;;; hl-block-mode.el --- highlighting nested blocks -*- lexical-binding: t -*-

;; Copyright (C) 2019  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-hl-block-mode
;; Package-Version: 20210617.1324
;; Package-Commit: 0ea43d320219ba4e6b7b1be36a5c1533ac3edb42
;; Version: 0.1
;; Package-Requires: ((emacs "26.0"))

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

;; Highlight blocks surrounding the cursor.

;;; Usage

;; (hl-block-mode)        ; activate in the current buffer
;; (global-hl-block-mode) ; activate globally for all buffers
;;
;; Currently only curly braces are supported (C-family languages).


;;; Code:

(require 'seq)

(defcustom hl-block-bracket ?{
  "Character to use as a starting bracket (defaults to '{').
Set to nil to use all brackets."
  :group 'hl-block-mode
  :type 'symbol)

(defcustom hl-block-delay 0.2
  "Idle time to wait before highlighting."
  :group 'hl-block-mode
  :type 'float)

(defcustom hl-block-color-tint "#040404"
  "Color to add/subtract from the background each scope step."
  :group 'hl-block-mode
  :type 'float)

(defcustom hl-block-mode-lighter ""
  "Lighter for hl-block-mode."
  :group 'hl-block-mode
  :type 'string)

(defun hl-block--syntax-prev-bracket (pt)
  "A version of `syntax-ppss' to match curly braces.
PT is typically the '(point)'."
  (let ((start (ignore-errors (elt (syntax-ppss pt) 1))))
    (when start
      (if (char-equal hl-block-bracket (char-after start))
        start
        (hl-block--syntax-prev-bracket (1- start))))))

(defun hl-block--find-all-ranges (pt)
  "Return a list of ranges starting from PT, outer-most to inner-most."
  (let*
    (
      (start
        ;; find brackets
        (if hl-block-bracket
          (hl-block--syntax-prev-bracket pt)
          (ignore-errors (elt (syntax-ppss pt) 1))))
      (end
        (when start
          (or (ignore-errors (scan-sexps start 1)) pt)))
      (range-prev
        (when start
          (hl-block--find-all-ranges start))))
    (when start
      (if range-prev
        (cons (list start end) range-prev)
        (list (list start end))))))

(defun hl-block--color-values-as-string (r g b)
  "Build a color from R G B.
Inverse of `color-values'."
  (format "#%02x%02x%02x" (ash r -8) (ash g -8) (ash b -8)))

(defvar-local hl-block-overlay nil)

(defun hl-block--overlay-clear ()
  "Clear all overlays."
  (mapc 'delete-overlay hl-block-overlay)
  (setq hl-block-overlay nil))

(defun hl-block--overlay-refresh ()
  "Update the overlays based on the cursor location."
  (hl-block--overlay-clear)
  (let ((block-list (save-excursion (hl-block--find-all-ranges (point)))))
    (when block-list
      (let*
        (
          (block-list
            (if (cdr block-list)
              (reverse block-list)
              (cons (list (point-min) (point-max)) block-list)))
          (start-prev (nth 0 (nth 0 block-list)))
          (end-prev (nth 1 (nth 0 block-list)))
          (block-list-len (length block-list))
          (bg-color (color-values (face-attribute 'default :background)))
          (bg-color-tint (color-values hl-block-color-tint))
          ;; Check dark background is light/dark.
          (do-highlight (> 98304 (apply '+ bg-color))))
        (seq-map-indexed
          (lambda (elem_range i)
            (let*
              (
                (i-tint (- block-list-len i))
                (start (nth 0 elem_range))
                (end (nth 1 elem_range))
                (elem-overlay-start (make-overlay start start-prev))
                (elem-overlay-end (make-overlay end-prev end))
                (bg-color-blend
                  (apply 'hl-block--color-values-as-string
                    (if do-highlight
                      (cl-mapcar `(lambda (a b) (+ a (* ,i-tint b))) bg-color bg-color-tint)
                      (cl-mapcar `(lambda (a b) (- a (* ,i-tint b))) bg-color bg-color-tint)))))
              (overlay-put elem-overlay-start 'face `(:background ,bg-color-blend :extend t))
              (overlay-put elem-overlay-end 'face `(:background ,bg-color-blend :extend t))
              (add-to-list 'hl-block-overlay elem-overlay-start)
              (add-to-list 'hl-block-overlay elem-overlay-end)
              (setq start-prev start)
              (setq end-prev end)))
          (cdr block-list))))))

;; Timer
(defvar hl-block--delay-timer nil)

(defun hl-block--overlay-refresh-from-timer ()
  "Ensure this mode has not been disabled before highlighting.
This can happen when switching buffers."
  (when hl-block-mode
    (hl-block--overlay-refresh)))

(defun hl-block--overlay-delay ()
  "Recalculate overlays using a delay (to avoid slow-down)."
  (when (timerp hl-block--delay-timer)
    (cancel-timer hl-block--delay-timer))
  (setq hl-block--delay-timer
    (run-with-idle-timer hl-block-delay t 'hl-block--overlay-refresh-from-timer)))

(defun hl-block-mode-enable ()
  "Turn on 'hl-block-mode' for the current buffer."
  (add-hook 'post-command-hook #'hl-block--overlay-delay nil t))

(defun hl-block-mode-disable ()
  "Turn off 'hl-block-mode' for the current buffer."
  (hl-block--overlay-clear)
  (when (timerp hl-block--delay-timer)
    (cancel-timer hl-block--delay-timer))
  (remove-hook 'post-command-hook #'hl-block--overlay-delay t))

(defun hl-block-mode-turn-on ()
  "Enable command `hl-block-mode'."
  (when (and (not (minibufferp)) (not hl-block-mode))
    (hl-block-mode 1)))

;;;###autoload
(define-minor-mode hl-block-mode
  "Highlight block under the cursor."
  :group 'hl-block-mode
  :global nil
  :lighter hl-block-mode-lighter

  (cond
    (hl-block-mode
      (jit-lock-unregister 'hl-block-mode-enable)
      (hl-block-mode-enable))
    (t
      (jit-lock-unregister 'hl-block-mode-enable)
      (hl-block-mode-disable))))

;;;###autoload
(define-globalized-minor-mode
  global-hl-block-mode

  hl-block-mode hl-block-mode-turn-on
  :group 'hl-block-mode)

(provide 'hl-block-mode)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; hl-block-mode.el ends here
