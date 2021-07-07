;;; contextual-menubar.el --- display the menubar only on a graphical display -*- lexical-binding: t -*-

;; Copyright (C) 2017 by Aaron Jensen

;; Author: Aaron Jensen <aaronjensen@gmail.com>
;; URL: https://github.com/aaronjensen/contextual-menubar
;; Package-Version: 20180205.709
;; Package-Commit: f76f55232ac07df76ef9a334a0c527dfab97c40b
;; Version: 1.0.0

;;; Commentary:

;; This package displays the menubar if on a graphical display, but hides it if
;; in terminal. It works for multiple frames on the same server. To use it, add
;; this to your `init.el':

;;    (contextual-menubar-install)

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(defun contextual-menubar-show-or-hide-menubar (&optional frame)
  "Display the menubar in FRAME (default: selected frame) if on a graphical display, but hide it if in terminal."
  (interactive)
  (set-frame-parameter frame 'menu-bar-lines
                       (if (display-graphic-p frame)
                           1 0)))

(defun contextual-menubar-disable-menu-bar (oldfun &rest args)
  "Advice to agument `default-frame-alist' to have no menu-bar in OLDFUN.
ARGS are passed through unchanged."
  (let ((default-frame-alist `((menu-bar-lines . 0) . ,default-frame-alist)))
    (apply oldfun args)))

;;;###autoload
(defun contextual-menubar-install ()
  "Install `contextual-menubar-show-or-hide-menubar' to `after-make-frame-functions'.
Also advice server-create-tty-frame to create frame without menu-bar
initially."
  (with-eval-after-load 'server
    (advice-add 'server-create-tty-frame :around 'contextual-menubar-disable-menu-bar))
  (add-hook 'after-make-frame-functions 'contextual-menubar-show-or-hide-menubar))

(provide 'contextual-menubar)
;;; contextual-menubar.el ends here
