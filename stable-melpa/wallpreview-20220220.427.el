;;; wallpreview.el --- Set wallpapers with image-dired -*- lexical-binding: t -*-

;; Copyright (C) 2022 Nakamura, Ryotaro <nakamura.ryotaro.kzs@gmail.com>
;; Version: 1.0.1
;; Package-Version: 20220220.427
;; Package-Commit: b1b8f19ae82b344a9577cea7b883ad513ec52222
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/nryotaro/wallpreview

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.

;;; Commentary:

;; wallpreview-wallpaper-directory is the directory that contains wallpaper images.
;; wallpreview-wallpaper-cmd is the callback function that takes the path of an image,
;; and sets it as the wallpaper.
;; The default command is for sway users.

;;; Code:
(require 'image-dired)

(defgroup wallpreview nil
  "Set wallpapers with image-dired."
  :prefix "wallpreview-"
  :group 'wallpreview)

(defcustom wallpreview-wallpaper-cmd
  #'wallpreview--sway-bg
  "A function that take a file path, and change the wallpaper."
  :type 'function)

(defcustom wallpreview-wallpaper-directory
  "~/Pictures"
  "Wallpapers directory."
  :type 'directory)

(defcustom wallpreview-toggle-key
  "w"
  "Specify `wallpreview-toggle' key."
  :type 'key-sequence)

(defun wallpreview-open-wallpaper-directory
    ()
  "Open `wallpreview-wallpaper-directory' with `image-dired'."
  (interactive)
  (image-dired wallpreview-wallpaper-directory)
  (wallpreview-mode t))

(defun wallpreview--sway-bg (wallpaper-path)
  "Change the backgrounds to the content of WALLPAPER-PATH."
  (concat "swaymsg output \"*\" bg \""
	  (shell-quote-argument wallpaper-path)
	  "\" fill"))

(defun wallpreview--set-wallpaper (&optional arg)
  "Set a background as ARG.
If arg is nil, use the focused image."
  (interactive "fBackground image: ")
  (let ((wallpaper-path (or arg (image-dired-original-file-name))))
    (call-process-shell-command
     (concat (apply wallpreview-wallpaper-cmd (list wallpaper-path)) "&")
     nil 0)))

(defun wallpreview--set-wallpaper-after
    (&rest _)
  "A Callback function.
This function is an after advice for
image-dired-[forward, backward]-image, image-dired-[previous, next]-line."
  (wallpreview--set-wallpaper))

(defvar wallpreview--on nil
  "If the value is not nil, wallpreview is enabled.")

(defun wallpreview--enable ()
  "Turn on wallpreview."
  (dolist (target (list #'image-dired-forward-image
			#'image-dired-backward-image
			#'image-dired-previous-line
			#'image-dired-next-line))
    (advice-add target
		:after
		#'wallpreview--set-wallpaper-after))
  (setq wallpreview--on t)
  (message "wallpreview is on."))

(defun wallpreview--disable ()
  "Turn off wallpreview."
  (dolist (target (list #'image-dired-forward-image
			#'image-dired-backward-image
			#'image-dired-previous-line
			#'image-dired-next-line))
    (advice-remove target
		   #'wallpreview--set-wallpaper-after))
  (setq wallpreview--on nil)
  (message "wallpreview is off."))

(defun wallpreview--toggle
    ()
  "Toggle wallpreview."
  (interactive)
  (if wallpreview--on
      (wallpreview--disable)
    (wallpreview--enable)))

;;;###autoload
(define-minor-mode wallpreview-mode
  "Turn on wallpreview-mode."
  :init-value nil ; Initial value, nil for disabled
  :lighter " wallpreview"
  :global t
  (let ((map image-dired-thumbnail-mode-map)
	(key wallpreview-toggle-key))
    (if wallpreview-mode
	(progn
	  (define-key
	    map
	    key
	    #'wallpreview--toggle)
	  (wallpreview--enable))
      (progn
	(define-key
	  map
	  key
	  nil)
	(wallpreview--disable)))))

(provide 'wallpreview)
;;; wallpreview.el ends here
