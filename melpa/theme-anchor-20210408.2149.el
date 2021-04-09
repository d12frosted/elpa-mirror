;;; theme-anchor.el --- Apply theme in current buffer only -*- lexical-binding: t -*-
 
;; Copyright (C) 2021 Liāu, Kiong-Gē

;; ------------------------------------------------------------------------------
;; Author: Liāu, Kiong-Gē <gongyi.liao@gmail.com>
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Package-Requires: ((emacs "26"))
;; Package-Version: 20210408.2149
;; Package-Commit: ec7f522ec25c7f8342dfd067b7d9f6862c828c93
;; Keywords: extensions, lisp, theme
;; Homepage: https://github.com/GongYiLiao/theme-anchor
;; ------------------------------------------------------------------------------

;; This program is free software: you can redistribute it and/or modify
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

;; Using `face-remap's `face-remap-set-base function to set buffer-specific
;; custom theme. Using `setq-local' to apply `theme-value's to current 
;; buffer only

;;; Code:
(require 'cl-lib)  			;; for `cl-remove-if', `cl-map'
(require 'faces) 			;; for `face-spec-choose'
(require 'custom) 			;; for `load-theme'
(require 'face-remap) 			;; for `face-remap-add-relative'
(require 'ansi-color)  			;; for `ansi-color-make-color-map'
(require 'org-macs) 			;; for `org-plist-delete'

(defun theme-anchor-get-values (theme)
  "Extract all the theme-face values from THEME."
  ;; take only theme-face specs
  (mapcar (lambda (spc) `(,(nth 1 spc) ,(nth 3 spc)))
	  (cl-remove-if (lambda (spc) (not (eq (car spc) 'theme-value)))
			;; the theme's all the face/value specs
			(get theme 'theme-settings))))

(defun theme-anchor-set-values (theme)
  "Set buffer-local values using theme-values extracted from THEME
Argument THEME: the theme to extract `theme-value's from"
  (dolist (val-spec (theme-anchor-get-values theme))
    (eval `(setq-local ,(car val-spec) ,(nth 1 val-spec)))))

(defun theme-anchor-get-faces (theme)
  "Extract all the theme-face values from THEME."
  ;; take only theme-face specs
  (cl-remove-if (lambda (spec) (not (eq (car spec) 'theme-face)))
		;; the theme's all the face/value specs
		(get theme 'theme-settings)))

(defun theme-anchor-spec-choose (face-spec)
  "Choose applicable face settings.
It uses the condition specified in a face spec and use 'face-spec-choose'
function from face-remap.el
Argument FACE-SPEC: the specs to be tested"
  ;; a face's all applicable specs, along with their applicable conditions
  (let ((face-spec-content (face-spec-choose (nth 3 face-spec))))
    (if face-spec-content
	(list (nth 1 face-spec) ;; the face name
	      ;; the applicable face spec chosen by 'face-spec-choose'
	      face-spec-content))))

(defun theme-anchor-remove-nil-fgbg (spec)
  "Remove face with nil foreground/background
Arugment face-plist: a face plist to have nil bg/fg filtered out"
  (let ((spec-name (car spec))
	(face-plist (nth 1 spec)))
    (dolist (fc '(:foreground :background))
      (if (and (plist-member face-plist fc)
	       (not (plist-get face-plist fc)))
	  (setq face-plist (org-plist-delete face-plist fc))))
    (list spec-name face-plist)))

(defun theme-anchor-buffer-local (theme)
  "Extract applicable face settings from THEME.
Argument THEME the theme to be applied in the mode hook .
It uses 'face-remap-set-base' to load that theme in a buffer local manner"
  ;; make sure the theme is available, copied from custom.el's load-theme
  ;; definition 
  (interactive
   (list (intern (completing-read "Load custom theme: "
				  (mapcar #'symbol-name
					  (custom-available-themes))))))
  (unless (custom-theme-name-valid-p theme)
    (error "Invalid theme name `%s'" theme))
  ;; prepare the theme for face-remap
  (load-theme theme t t)
  ;; set the theme-values as well 
  (theme-anchor-set-values theme) 
  ;; choose the most appropriate theme for the environment
  (setq-local face-remapping-alist 	;
	      (cl-remove nil
			 (mapcar (lambda (specs)
				   (theme-anchor-remove-nil-fgbg
				    (theme-anchor-spec-choose specs)))
				 (theme-anchor-get-faces theme))))
  (if (local-variable-p 'ansi-color-names-vector)
      (setq-local ansi-color-map (ansi-color-make-color-map)))
  (force-mode-line-update))

(defmacro theme-anchor-hook-gen (theme &rest other-step)
  "Generate hook functions.
Argument THEME the theme to be applied in the mode hook .
Optional argument OTHER-STEP the additional steps to execute in the mode hook."
  `(lambda nil
     ;; face-remap current buffer with theme
     (theme-anchor-buffer-local ,theme)
     ;; other sides effect applicable to the current buffer
     ,@other-step))

(provide 'theme-anchor)
;;; theme-anchor.el ends here
