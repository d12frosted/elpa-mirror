;;; org-inline-anim.el --- Inline playback of animated GIF/PNG for Org -*- lexical-binding: t -*-

;; Copyright (C) 2021 Shigeaki Nishina

;; Author: Shigeaki Nishina
;; Maintainer: Shigeaki Nishina
;; Created: October 24, 2021
;; URL: https://github.com/shg/org-inline-anim.el
;; Package-Version: 20211101.413
;; Package-Commit: 1808574ff04ed66b7382247f3f13815fae2a4929
;; Package-Requires: ((emacs "25.3") (org "9.4"))
;; Version: 0.2
;; Keywords: org, outlines, hypermedia, multimedia

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see https://www.gnu.org/licenses/.

;;; Commentary:

;; This package enables inline playback of animated GIF or PNG in Org
;; buffers.
;;
;; Usage:
;;
;; Download org-inline-anim.el and insall it using package.el.
;;
;;   (package-install-file "/path-to-download-dir/org-inline-anim.el")
;;
;; Enable this feature in an Org buffer with M-x org-inline-anim-mode.
;; Add the following line in your init file to automatically enable
;; the feature in newly opened Org buffers.
;;
;;   (add-hook 'org-mode-hook #'org-inline-anim-mode)
;;
;; Now you can play animated GIF or PNG images in Org.
;;
;; M-x org-inline-anim-animate (C-c C-x m) plays the animation once.
;; With a single prefix (C-u), it plays the animation in loop mode.
;; With a double prefix (C-u C-u), it shows the last frame and stops playback.
;; With a numeric arg 0 (C-u 0 or C-0), it shows the first frame and stops playback.

;;; Code:

(require 'org-element)

(defconst org-inline-anim-key (kbd "C-c C-x m"))

(defun org-inline-anim--first-image-overlay (overlays)
  "Return first image overlay in OVERLAYS that has display property."
  (let ((ov nil))
    (while (and overlays (not ov))
      (if (overlay-get (car overlays) 'display)
	  (setq ov (car overlays)))
      (setq overlays (cdr overlays)))
    ov))

(defun org-inline-anim--get-image-overlay-at-point ()
  "Return image overlay at point if there's an image overlay or nil if not."
  (org-inline-anim--first-image-overlay (overlays-at (point))))

(defun org-inline-anim--get-image-overlay-in-element (element)
  "Return image overlay in the org-element ELEMENT."
  (let* ((beg (org-element-property :contents-begin element))
	 (end (org-element-property :contents-end element))
	 (overlays (overlays-in beg end)))
    (org-inline-anim--first-image-overlay overlays)))

(defun org-inline-anim--get-image-overlay-in-result-of-this ()
  "Return image overlay of the result of the current source code block."
  (let ((result-block (org-babel-where-is-src-block-result)))
    (if result-block
	(save-excursion
	  (goto-char result-block)
	  (org-inline-anim--get-image-overlay-in-element (org-element-at-point))))))

(defun org-inline-anim-animate (&optional arg)
  "Animate graphics at point or in the result block of the current source block.

Without a prefix ARG, the animation is played once and stops.
With a single prefix arg, the animation loops.  With a double
prefix arg, the animation goes to the last frame and stops.
With a numeric prefix arg of 0, the animation goes to the first
frame and stops."
  (interactive "P")
  (save-excursion
    (let* ((ov (let ((element (org-element-at-point)))
		 (if (eq (org-element-type element) 'src-block)
		     (org-inline-anim--get-image-overlay-in-result-of-this)
		   (if (and (eq (org-element-type element) 'paragraph)
			    (org-element-property :results element))
		       (org-inline-anim--get-image-overlay-in-element element)
		     (org-inline-anim--get-image-overlay-at-point)))))
	   (disp (overlay-get ov 'display)))
      (let ((frames (image-multi-frame-p disp))
	    (prefix (prefix-numeric-value arg)))
	(if (and (listp frames) (numberp (cdr frames)))
	    (cond ((= prefix 4)
		   (image-animate disp 0 t))
		  ((= prefix 16)
		   (image-animate disp (1- (car frames)) 0))
		  ((= prefix 0)
		   (image-animate disp 0 0))
		  (t
		   (image-animate disp))))))))

;;;###autoload
(define-minor-mode org-inline-anim-mode
  "Inline playback of animated GIF/PNG for Org."
  nil "" nil
  (cond
   (org-inline-anim-mode
    (define-key org-mode-map org-inline-anim-key #'org-inline-anim-animate))
   (t
    (define-key org-mode-map org-inline-anim-key nil))))

(provide 'org-inline-anim)

;;; org-inline-anim.el ends here
