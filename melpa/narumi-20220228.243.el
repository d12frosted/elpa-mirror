;;; narumi.el --- A dashboard that displays a ramdom sampled image -*- lexical-binding: t -*-

;; Copyright (C) 2022 Nakamura, Ryotaro <nakamura.ryotaro.kzs@gmail.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/nryotaro/narumi
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

;; narumi is a major mode that shows a dashboard.  It shows randomly
;; sampled image in a directory e.g. using sway, bookmarks, and recent
;; files.  You can change the wallpaper to the image on the dashboard.
;; Since it is a dashboard, you can go to the entries of bookmarks and
;; recent files by clicking them.

;;; Code:
(require 'bookmark)
(require 'recentf)
(require 'seq)

(defgroup narumi nil
  "Yet another splash screen."
  :prefix "narumi-"
  :group 'narumi)

(defcustom narumi-buffer-name
  "*narumi*"
  "The buffer name of narumi."
  :type 'string)

(defcustom narumi-image-directory
  "~/Pictures"
  "A directory where images are."
  :type 'string)

(defcustom narumi-wallpaper-cmd
  'narumi--sway-bg
  "Sets the background as the image at the file path."
  :type 'function)

(defcustom narumi-display-image
  t
  "Display an image if the variable is bound to not nil."
  :type 'boolean)

(defun narumi-display-on-startup
    ()
  "Display narumi on startup."
  (add-hook 'emacs-startup-hook
	    #'narumi--display))

(defun narumi--sway-bg (wallpaper-path)
  "Use the image at WALLPAPER-PATH as the wallpaper.
This works for sway users."
  (concat "swaymsg output \"*\" bg \""
	  (shell-quote-argument wallpaper-path)
	  "\" fill"))

(defun narumi--set-wallpaper ()
  "Set a image as the wallpaper."
  (interactive)
  (let* ((text-properties (text-properties-at (point)))
	 (wallpaper-path (nth (+ 1
				 (seq-position text-properties
					       'image-path))
			      text-properties)))
    (call-process-shell-command
     (concat
      (apply narumi-wallpaper-cmd
	     (list wallpaper-path))
      "&")
     nil
     0)))

(defun narumi--display ()
  "Display the buffer of narumi on the current window."
  (interactive)
  (let ((buffer-name narumi-buffer-name))
    (get-buffer-create buffer-name)
    (with-current-buffer buffer-name
      (narumi))
    (set-window-buffer (selected-window)
		       buffer-name)
    (switch-to-buffer narumi-buffer-name)))

(defun narumi--calc-scale
    (image-width image-height width height max-height-ratio)
  "Calculate an appropriate scale of a image.
Take width(IMAGE-WIDTH) and height(IMAGE-HEIGHT) of an image,
WIDTH and HEIGHT of area for narumi and MAX-HEIGHT-RATIO
to calculate the scale that let image be in
WIDTH x (HEIGHT * MAX-HEIGHT-RATIO) area.
the range of MAX-HEIGHT-RATIO is (0 1), the sizes are in pixel."
  (let ((height-bound (* height max-height-ratio))
	(width-bound (* 0.9 width)))
    (if (<= image-width width-bound)
	(if (<= image-height height-bound)
	    1.0
	  (/ height-bound image-height))
      (if (<= image-height height-bound)
	  ;; width-bound < image-width
	(/ width-bound image-width)
	(min (/ height-bound image-height)
	     (/ width-bound image-width))))))

(defun narumi--update-image-scale (image new-scale)
  "Update the value of IMAGE with NEW-SCALE.
Take IMAGE returned by `create-image',
returning the new object with (:scale NEW-SCALE)."
  (let* ((scale-tag-pos (seq-position image :scale)))
    (if scale-tag-pos
	(seq-map-indexed (lambda (item i)
		     (if (= i (+ 1 scale-tag-pos))
			 new-scale
		       item))
		   image)
      (append image (list :scale new-scale)))))

(defun narumi--create-center-image (file-path)
  "Create an image at FILE-PATH that `insert-image' can accept.
The returned object can contain the margin attribute."
  (let* ((image (create-image (expand-file-name file-path)))
	 (image-width (car (image-size image t)))
	 (image-height (cdr (image-size image t)))
	 (new-scale (narumi--calc-scale image-width
					image-height
					(window-pixel-width)
					(frame-pixel-height)
					0.4))
	 (resized-image (narumi--update-image-scale
			 image
			 new-scale))
	 (resized-width (car (image-size resized-image t)))
	 (window-width (window-body-width nil t))
	 (width-margin (if (<= window-width resized-width)
			   0
			 (/ (- window-width resized-width)
			    2))))
    (append resized-image (list :margin
				(cons width-margin 10)))))


(defun narumi--find-image-files ()
  "Return image jpeg or png image files in `narumi-image-directory'."
  (seq-filter (lambda (entry)
		(let ((len (length entry)))
		  (if (<= 4 len)
		      (let ((jpeg (substring entry -4))
			    (ext (substring entry -3)))
			(or (equal "jpeg" jpeg)
			    (equal "png" ext)
			    (equal "jpg" ext))))))
	      (directory-files narumi-image-directory)))

(defun narumi--put-image ()
  "Insert an image into the buffer."
  (let* ((images (narumi--find-image-files))
	 (image (expand-file-name (nth (random
					(length images))
				       images)
				  narumi-image-directory))
	 (map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'narumi--set-wallpaper)
    (insert-image (narumi--create-center-image image))
    (newline)
    (insert (propertize "Set the image as the wallpaper."
			'face
			'button
			'image-path
			image
			'keymap
			map))
    (insert "\n")
    (newline)))

(defun narumi--jump-entry ()
  "Open a file that the cursor is on."
  (interactive)
  (let ((text-properties (text-properties-at (point))))
	(if text-properties
	    (find-file (nth (+ 1 (seq-position
				  text-properties
				  'entry-value))
			    text-properties)))))

(defun narumi--insert-entry (title path)
  "Insert a TITLE that is linked to PATH."
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'narumi--jump-entry)
    (insert "  ◯ ")
    (insert (propertize title
			'face
			'button
			'entry-value
			path
			'keymap
			map))
    ;; (newline) can append '_' to the paths.
    (insert "\n")))

(defun narumi--list-bookmarks ()
  "Return the paths of the bookmarks."
  (with-current-buffer (get-buffer-create
			bookmark-bmenu-buffer)
    (list-bookmarks))
  (mapcar (lambda (x)
	  (cdr (assoc 'filename (cdr x))))
	  bookmark-alist))

(defun narumi--insert-title (title)
  "Add a headline TITLE."
  (add-text-properties 0
		       (length title)
		       '(face bookmark-menu-heading
			      display
			      (height 1.2))
		       title)
  (insert title))

(defun narumi--refresh ()
  "Refresh the buffer."
  (interactive)
  (recentf-mode t)
  (setq buffer-read-only nil)
  (erase-buffer)
  (goto-char (point-min))
  (if narumi-display-image
      (narumi--put-image))
  (narumi--insert-title "Bookmarks")
  (newline)
  (dolist (bookmark-path (narumi--list-bookmarks))
    (narumi--insert-entry bookmark-path bookmark-path))
  (newline)
  (narumi--insert-title "Recent files")
  (newline)
  (dolist (recent-file recentf-list)
    (narumi--insert-entry recent-file recent-file))
  (goto-char (point-min))
  (forward-line 1)
  (setq buffer-read-only t))

(define-derived-mode narumi
  special-mode "narumi"
  "Display the links to locations you may visit."
  (define-key narumi-map "r" #'narumi--refresh)
  (narumi--refresh))

(provide 'narumi)
;;; narumi.el ends here
