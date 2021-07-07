;;; ns-auto-titlebar.el --- Set the MacOS transparent titlebar to match theme  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; Keywords: frames
;; Package-Version: 20181022.2154
;; Package-Commit: 60273e764bf8d95abc40dd2fdc23af87ea9ee33b
;; Homepage: https://github.com/purcell/ns-auto-titlebar
;; Version: 0
;; Package-Requires: ((emacs "24.4"))

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

;; Provides a global minor mode, `ns-auto-titlebar-mode' which - when
;; enabled - keeps the "ns-appearance" frame parameter correctly set
;; in GUI frames so that it matches the currently-enabled theme,
;; whether it is light or dark.

;; For this package to work correctly, it is generally necessary that
;; the theme you use sets the `frame-background-mode' variable
;; appropriately.  This can be set manually if necessary, but see the
;; docs for that variable.

;; Usage:

;;     (when (eq system-type 'darwin) (ns-auto-titlebar-mode))

;; Note that it is safe to omit the "when" condition if you prefer.

;;; Code:

;;;###autoload
(define-minor-mode ns-auto-titlebar-mode
  "Set the MacOS transparent titlebar background automatically."
  :global t
  :lighter ""
  :require 'ns-auto-titlebar
  (when ns-auto-titlebar-mode
    (ns-auto-titlebar-set-all-frames)))

(defun ns-auto-titlebar-set-frame (frame &rest _)
  "Set ns-appearance frame parameter for FRAME to match its background-mode parameter."
  (when (and ns-auto-titlebar-mode
             (display-graphic-p frame))
    (let ((mode (frame-parameter frame 'background-mode)))
      (modify-frame-parameters frame `((ns-transparent-titlebar . t) (ns-appearance . ,mode))))))

(defun ns-auto-titlebar-set-all-frames (&rest _)
  "Set ns-appearance frame parameter for all frames to match their background-mode parameter."
  (when ns-auto-titlebar-mode
    (mapc 'ns-auto-titlebar-set-frame (frame-list))))

(add-hook 'after-init-hook 'ns-auto-titlebar-set-all-frames)
(add-hook 'after-make-frame-functions 'ns-auto-titlebar-set-frame)
(advice-add 'frame-set-background-mode :after 'ns-auto-titlebar-set-frame)


(provide 'ns-auto-titlebar)
;;; ns-auto-titlebar.el ends here
