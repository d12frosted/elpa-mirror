;;; gtk-variant.el --- Set the GTK theme variant (titlebar color) -*- lexical-binding: t -*-

;; Author: Paul Oppenheimer
;; Maintainer: Paul Oppenheimer
;; Version: 1.0.3
;; Package-Version: 20200416.2136
;; Package-Commit: e0653e4a654b7800dc15f7e1a06a956b77d2aabe
;; Package-Requires: ((emacs "25.1"))
;; Homepage: https://github.com/bepvte/gtk-variant.el
;; Keywords: frames,  GTK, titlebar


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; This plugin uses the xprop command to set an X11 property that some window
;; managers use to set the GTK decorations. This allows for a dark titlebar,
;; which this plugin sets by default.
;; This plugin will stop working on wayland if Emacs ever moves to wayland.

;;; Usage:

;; (add-hook 'window-setup-hook #'gtk-variant-set-frame)
;; (add-hook 'after-make-frame-functions #'gtk-variant-set-frame)


;;; Code:
(defcustom gtk-variant 'dark
  "Initial GTK theme variant. Valid values are dark and light."
  :type '(radio (const dark)
                (const light))
  :set (lambda (_ val)
         (setq gtk-variant val)
         (gtk-variant-set-frame nil val))
  :initialize #'custom-initialize-default)

;;;###autoload
(defun gtk-variant-set-frame (&optional frame variant)
  "Set the GTK theme variant of frame FRAME to VARIANT.
With no arguments, sets the selected frame to the variable `gtk-variant'

Recommended usage:
\(add-hook 'window-setup-hook #'gtk-variant-set-frame)
\(add-hook 'after-make-frame-functions #'gtk-variant-set-frame)

\(fn &optional FRAME VARIANT)"
  (interactive
   (list nil (intern (completing-read "GTK Variant: " '(dark light) nil t))))
  (when (display-graphic-p (or frame (selected-frame)))
    (let ((variant (or variant gtk-variant)))
      (unless (memq variant '(dark light)) (error "Invalid variant: %s" variant))
      (call-process-shell-command
       (format "xprop -f _GTK_THEME_VARIANT 8u -set _GTK_THEME_VARIANT \"%s\" -id \"%s\""
               (shell-quote-argument (symbol-name variant))
               (shell-quote-argument (frame-parameter frame 'outer-window-id)))
       nil 0))))


(provide 'gtk-variant)

;;; gtk-variant.el ends here
