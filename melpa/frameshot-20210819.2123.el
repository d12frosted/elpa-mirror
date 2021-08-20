;;; frameshot.el --- Take screenshots of a frame  -*- lexical-binding: t -*-

;; Copyright (C) 2018-2021  Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/frameshot

;; Package-Requires: ((emacs "25.3"))
;; Package-Version: 20210819.2123
;; Package-Commit: 029df561ef6572b1ab034490ac48d909d037ac1d

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a command for taking screenshots of an
;; individual frame.  It also support setting up the frame according
;; to simple predetermined rules.  Simple examples can be found at
;; https://github.com/tarsius/emacsair.me/tree/master/assets/readme.

;; This package optionally uses the `import' and `convert' binaries
;; from the `imagemagick' package.  By default `import' isn't used
;; to take screenshots but if you want to add a drop shadow, then
;; `convert' is required.

;;; Code:

(eval-when-compile (require 'subr-x))

(defgroup frameshot nil
  "Take screenshots of a frame."
  :group 'multimedia)

(defcustom frameshot-default-config nil
  "Default Frameshot configuration.
Use `frameshot-default-setup' to use this configuration.
See `frameshot-config' for information about the format."
  :group 'frameshot
  :type 'sexp)

(defcustom frameshot-config nil
  "Current Frameshot configuration.

The value has this form:

  ((name   . STRING)
   (output . DIRECTORY)
   (camera . FUNCTION)
   (height . PIXELS)
   (width  . PIXELS)
   (shadow . ((color   . COLOR-STRING)
              (opacity . PERCENTAGE)
              (sigma   . PIXELS)
              (x       . PIXELS)
              (y       . PIXELS))))

HEIGHT and WIDTH are integers.  SHADOW is optional, but if it is
non-nil, then COLOR, OPACITY and SIGMA have to be non-nil.  The
actual height of the frame is HEIGHT - SIGMA * 4, and the width
is WIDTH - SIGMA * 4.  Only after adding the drop shadow the
final image has the proportions specified by HEIGHT and WIDTH.

The value of this variable is typically set by passing an alist
that matches the above form to `frameshot-setup'.

WARNING: While this variable is defined as a customizable option,
you should never actually save your customizations.  You may
however, and that is why this is defined as an option, customize
and *set* (not save) the value for the current session."
  :group 'frameshot
  :type 'sexp)

(defcustom frameshot-camera-function 'frameshot-export-frame-png
  "The function used to take screenshots.
Called with one argument, the file name without a suffix.
Must return the file name, possibly after adding a suffix."
  :group 'frameshot
  :type '(choice (const frameshot-export-frame-png)
                 (const frameshot-export-frame-svg)
                 (const frameshot-imagemagick-import)
                 function))

(defvar frameshot-setup-hook nil
  "Hook run by `frameshot-setup'.
See the functions defined at the end of `frameshot.el' for
examples.")

(defvar frameshot-buffer nil)

;;;###autoload
(define-minor-mode frameshot-mode
  "Take screenshots of a frame."
  :global t
  :keymap '(([f6] . frameshot-setup)
            ([f7] . frameshot-clear)
            ([f8] . frameshot-take)))

;;;###autoload
(defun frameshot-setup (&optional config)
  "Setup the selected frame using CONFIG and call `frameshot-setup-hook'.

Set variable `frameshot-config' to CONFIG, resize the selected
frame according to CONFIG, and call `frameshot-setup-hook'.  If
CONFIG is nil, then use the value of `frameshot-config' instead.
See `frameshot-config' for the format of CONFIG.

Also run `frameshot-setup-hook' and `frameshot-clear'.

When called interactively, then reload the previously loaded
configuration if any."
  (interactive)
  (frameshot-mode 1)
  (setq frameshot-buffer (get-buffer-create " *frameshot*"))
  (run-hooks 'frameshot-setup-hook)
  (when config
    (setq frameshot-config config))
  (let-alist frameshot-config
    (let ((shadow (if .shadow.sigma (* 4 .shadow.sigma) 0))
          (frame (selected-frame)))
      (when .width
        (set-frame-width
         frame
         (- .width shadow
            (or  left-fringe-width (frame-parameter frame  'left-fringe))
            (or right-fringe-width (frame-parameter frame 'right-fringe)))
         nil t))
      (when .height
        (set-frame-height frame (- .height shadow) nil t))))
  (frameshot-clear))

;;;###autoload
(defun frameshot-default-setup ()
  "Setup the selected frame using `frame-default-config'."
  (interactive)
  (unless frameshot-default-config
    (user-error "`frameshot-default-config' is nil"))
  (frameshot-setup frameshot-default-config))

;;;###autoload
(defun frameshot-clear ()
  "Remove some artifacts, preparing to take a screenshot."
  (interactive)
  (force-mode-line-update t)
  (message ""))

;;;###autoload
(defun frameshot-take ()
  "Take a screenshot of the selected frame."
  (interactive)
  (let-alist frameshot-config
    (frameshot-imagemagick-convert
     (funcall (or .camera frameshot-camera-function)
              (expand-file-name
               (concat (and .name (concat .name "-"))
                       (format-time-string "%Y%m%d-%H:%M:%S"))
               .output)))))

(defun frameshot-export-frame-svg (file)
  "Use `x-export-frames' to take a svg screenshot."
  (setq file (concat file ".svg"))
  (with-temp-file file
    (insert (x-export-frames (selected-frame) 'svg)))
  file)

(defun frameshot-export-frame-png (file)
  "Use `x-export-frames' to take a png screenshot."
  (setq file (concat file ".png"))
  (with-temp-file file
    (insert (x-export-frames (selected-frame) 'png)))
  file)

(defun frameshot-imagemagick-import (file)
  "Use Imagemagick's `import' executable to take a png screenshot."
  (setq file (concat file ".png"))
  (frameshot--call-process "import" "-window"
                           (frame-parameter (selected-frame) 'outer-window-id)
                           file)
  file)

(defun frameshot-imagemagick-convert (file)
  "Use Imagemagick's `convert' executable to add a drop shadow.
The drop shadow details are taken from `frameshot-config'."
  (let-alist frameshot-config
    (when .shadow
      (frameshot--call-process
       "convert" file
       "(" "+clone" "-background" "black"
       "-shadow" (format "%sx%s+%s+%s"
                         .shadow.opacity
                         .shadow.sigma
                         (or .shadow.x 0)
                         (or .shadow.y 0))
       ")" "+swap" "-background" "transparent" "-layers" "merge" "+repage"
       file))))

(defun frameshot--call-process (program &rest args)
  (unless frameshot-buffer
    (setq frameshot-buffer (get-buffer-create " *frameshot*")))
  (with-current-buffer frameshot-buffer
    (goto-char (point-max))
    (insert "\n$ " (mapconcat #'identity (cons program args) " ") "\n"))
  (apply #'call-process program nil frameshot-buffer nil args))

;;; Hook functions

(defun frameshot-xdotool-focus ()
  "Focus the selected frame using `xdotool'."
  (frameshot--call-process "xdotool" "windowfocus" "--sync"
                           (frame-parameter (selected-frame) 'outer-window-id)))

(defun frameshot-i3wm-setup ()
  "Float the frame and remove decoration when using the `i3wm' window manager."
  (frameshot--call-process "i3-msg" "floating enable, border pixel 0"))

(declare-function fci-mode "fill-column-indicator" (&optional ARG))
(declare-function which-key-mode "which-key" (&optional ARG))

(defun frameshot-tarsius-setup ()
  "Setup the frame like the author of this package does.

I use my regular init file when taking screenshots, so I
have to undo a few visual features that I don't want to
appear in screenshots.  You can do the same, or you can
use \"emacs -Q\", but then you also have to take care of
loading the package that you want to demo."
  (when (fboundp 'global-display-fill-column-indicator-mode)
    (global-display-fill-column-indicator-mode -1))
  (when (fboundp 'which-key-mode)
    (which-key-mode -1))
  (blink-cursor-mode -1)
  (setq window-min-height 1)
  (setq indicate-buffer-boundaries nil)
  (setq visual-line-fringe-indicators '(nil nil))
  (remove-hook 'emacs-lisp-mode-hook  'fci-mode)
  (remove-hook 'git-commit-setup-hook 'fci-mode)
  (remove-hook 'prog-mode-hook 'indicate-buffer-boundaries-left))

;;; _
(provide 'frameshot)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; frameshot.el ends here
