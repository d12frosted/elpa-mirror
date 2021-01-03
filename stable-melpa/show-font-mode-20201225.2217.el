;;; show-font-mode.el --- Show font at point on mode line -*- lexical-binding: t -*-

;; Copyright (C) 2020 Melissa Boiko

;; Author: Melissa Boiko <melissa@namakajiri.net>
;; Keywords: faces, i18n, unicode, fonts, fontsets
;; Package-Version: 20201225.2217
;; Package-Commit: 8503be7966d3bd8316039b5f49d3c37c7b97d10c
;; Package-Requires: ((emacs "25.1"))
;; Version: 0.1
;; Homepage: https://github.com/melissaboiko/show-font-mode

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Affero General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU Affero General Public
;; License along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Display on modeline the low-level font picked by Emacs at point.
;;; Useful to debug issues with fontsets.
;;;
;;; The size of the font in pixels is shown before the font as
;;; width×height.  Notice that multiple monospace fonts won’t align
;;; unless they have the same width.  In custom-faces, you can fix
;;; this by adjusting the "height” property of the relevant face as a
;;; floating-point multiplier, until it matches the other fonts.
;;;
;;; This package also provides a colourful overlay to paint each font
;;; in the buffer in a different colour
;;; (‘show-font-mode-overlay’).  This feature is currently a bit
;;; buggy but it works to visualise font selection.  Use
;;; ‘show-font-mode-clear-overlay’ to undo.

;;; Code:

(defvar show-font-mode-palette-pan
  '("#ff1b8d" "#ff4b6a" "#ff7b47" "#ffaa23" "#ffda00" "#c6d040" "#8dc780" "#54bdbf" "#1bb3ff")
  "The pansexual flag, extended to a 9 steps palette.")

(defvar show-font-mode-palette-pan-lightbg
  '("#ffff1b1b8d8d" "#ffff4b4b6a6a" "#fa4455382bf0" "#ef4264a00000" "#e0a3715c0000" "#b1bf8b5e0000" "#58a7a0b94a80" "#25c99d3abce1" "#00009274fd7c")
  "The pansexual flag, extended to a 9 steps palette, darkened for light backgrounds.")

(defcustom show-font-mode-font-format-fn
  'show-font-mode-font-format
  "Function to format a font object for the mode-line."
  :type 'function :group 'show-font-mode)

(defcustom show-font-mode-palette-custom
  show-font-mode-palette-pan-lightbg ;; fetched by value to init it
  "Default palette for ‘show-font-mode-overlay’."
  :type '(repeat color)
  :group 'show-font-mode)

(defcustom show-font-mode-palette 'show-font-mode-palette-custom
  "The palette variable to highlight fonts on.

This is a symbol, the name of a variable with a list of
 colours (of any length).  ‘show-font-mode-palette-custom’ is
 provided for convenient customisation."
  :type 'variable
  :group 'show-font-mode)


(defvar show-font-mode--last-position ""
  "Keeps track of cursor position.")

(defvar show-font-mode--string ""
  "Keeps the current modeline output string.")

(defvar show-font-mode--known-fonts nil
  "Internal variable to keep track of fonts seen.")


;;;###autoload
(define-minor-mode show-font-mode
  "Toggle display of font at point in the mode line (show font mode).

With a prefix argument ARG, enable show-font-mode if ARG is
positive, and disable it otherwise.

If called from Lisp, enable the mode if ARG is omitted or nil."
  :global t
  (if show-font-mode
      (progn
        (setq show-font-mode--last-position (show-font-mode--get-position))
        (add-to-list 'mode-line-misc-info
                           '(show-font-mode show-font-mode--string))
        (add-hook 'post-command-hook 'show-font-mode--post-command 'append)
        (show-font-mode--post-command)) ;; kickstart it
    (remove-hook 'post-command-hook 'show-font-mode--post-command)))

(defun show-font-mode-font-format (font)
  "Format information from FONT (a font object) for the modeline."
  (if (not (fontp font))
      "--"
    (let* ((family (font-get font :family))
           (size (font-get font :size))
           ;; (s (font-get font :script))
           ;; (l (font-get font :lang))
           (query (query-font font))
           (height (elt query 3))
           (avgw (elt query 7)))

      (format "«%sx%spx %s:%s»"
              (if (equal avgw 0)
                  (elt query 6) ;; space width
                avgw)
              height
              family
              size))))

(defun show-font-mode-overlay ()
  "Add color overlay for each distinct font.

Uses ‘show-font-mode-palette’.  If you have more fonts than
colours, colours will repeat in a cycle.

Text additions are not updated currently, so it setups self to be
undone on any modification via ‘first-change-hook’.  You can
clear it manually with ‘show-font-mode-clear-overlay’."

  (interactive)
  (dolist (pos (number-sequence (point-min) (- (point-max) 1)))
    (show-font-mode--make-overlay-at pos))
  (add-hook 'first-change-hook
            'show-font-mode--overlay-clear-on-change
            nil 'local))


(defun show-font-mode-clear-overlay()
  "Remove overlays from ‘show-font-mode-overlay’."
  (interactive)
  (dolist (ov (overlays-in (point-min) (point-max)))
    (let ((cat (overlay-get ov 'category)))
      (when(eq cat 'show-font-mode))
      (delete-overlay ov))))

;; internal stuff follows


(defun show-font-mode--color-for (font)
  "Picks a color for the font family from FONT object."

  ;; TODO: allow custom hashing rather than just font family (pixel
  ;; width could be especially useful).

  (let* ((family (elt (query-font font) 0))
         (color (alist-get family show-font-mode--known-fonts nil nil 'equal)))
    (or color
        (let* ((pal (symbol-value show-font-mode-palette))
               (new-idx (length show-font-mode--known-fonts))

               (color
                (elt pal
                     (mod new-idx (length pal)))))
          (add-to-list 'show-font-mode--known-fonts
                       (cons family color)
                       'append)
          color))))


(defun show-font-mode--get-position ()
  "List of elements we track position of."
  (list (point) (current-buffer) (selected-window) (selected-frame)))


(defun show-font-mode--post-command ()
  "Run on ‘post-command-hook’ to update the font in modeline."

  ;; ‘font-at’ can’t handle the very last position
  (unless (or (window-minibuffer-p) (eq (point) (point-max)))
    (let ((pos (show-font-mode--get-position))
          (last show-font-mode--last-position))
      (when (or (not last) (not (equal pos last)))
        (show-font-mode--update-mode-line pos)
        (setq show-font-mode--last-position pos)
        (redisplay)))))


(defun show-font-mode--update-mode-line (pos)
  "Update the mode-line to font at position POS."
  (setq show-font-mode--string
        (funcall show-font-mode-font-format-fn
                 (font-at (car pos) (elt pos 2))))
  (force-mode-line-update)
  (redisplay))


(defun show-font-mode--make-overlay-at (pos)
  "Add font color overlay to character at position POS."
  (let ((o (make-overlay pos (+ pos 1))))
    (overlay-put o 'category 'show-font-mode)
    (overlay-put o 'face
                 (list
                  :foreground
                  (show-font-mode--color-for (font-at pos))))))


(defun show-font-mode--overlay-clear-on-change ()
  "Break overlay on touch via ‘first-change-hook’."
  (show-font-mode-clear-overlay)
  (remove-hook 'first-change-hook
               'show-font-mode--overlay-clear-on-change
               'local))


(provide 'show-font-mode)

;;; show-font-mode.el ends here
