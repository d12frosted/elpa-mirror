;;; theme-anchor.el --- Apply theme in current buffer only -*- lexical-binding: t -*-
 
;; Copyright (C) 2021 Liāu, Kiong-Gē

;; ------------------------------------------------------------------------------
;; Author: Liāu, Kiong-Gē <gongyi.liao@gmail.com>
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Package-Requires: ((emacs "26"))
;; Package-Version: 20210326.1944
;; Package-Commit: 116aa810043c06ba8b29d5daad374d17c2cf78bd
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
(require 'cl-lib)  			;; for `cl-remove-if', `cl-remove', `cl-set-difference'
(require 'faces) 			;; for `face-spec-choose'
(require 'custom) 			;; for `load-theme'
(require 'face-remap) 			;; for `face-remap-set-base'
(require 'ansi-color)                   ;; for `ansi-color-make-color-map'

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
  (let ((val-specs (theme-anchor-get-values theme)))
    (cl-map nil (lambda (spc)
		  (eval `(setq-local ,(car spc) ,(nth 1 spc))))
	    val-specs)))

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
  (let ((face-spec-content (nth 3 face-spec)))
    (list (nth 1 face-spec) ;; the face name
	  ;; the applicable face spec chosen by 'face-spec-choose'
	  (face-spec-choose face-spec-content))))

;; (valid-specs (cl-remove nil (mapcar #'theme-anchor-spec-choose
;; 					     (theme-anchor-get-faces theme))))

(defun theme-anchor-spec-inherit (valid-specs)
  "Get specs using inherit proporties.
This is for those faces not specified in agiven theme but have their parent
faces in the theme. This function is designed for `theme-anchor-buffer-local'
and not supposed to use separately" 
  (let* ((valid-keys (mapcar #'car valid-specs))
	 ;; get name of faces those exists but not specified in theme
	 (face-stack (cl-set-difference (face-list) valid-keys))
	 ;; This filter check the following conditions 
	 ;; 1. the face's spec is derived through :inherit property
	 ;; 2. if #1 holds, check if the face this face inherit
	 ;;    from does exist in curent buffer's face-remapping-alist
	 (inherit-specs (mapcar (lambda (fc)
				  (let ((ihr (face-attribute fc :inherit nil t)))
				    (if (and ihr
					     (not (eq ihr 'unspecified))
					     (member ihr valid-keys))
					(list fc (car (alist-get ihr valid-specs))))))
				face-stack)))
    ;; clean up `nil's
    (cl-remove nil inherit-specs)))

(defun theme-anchor-buffer-local (theme)
  "Extract applicable face settings from THEME.
Argument THEME the theme to be applied in the mode hook .
It uses 'face-remap-set-base' to load that theme in a buffer local manner"
  ;; make sure the theme is available, copied from custom.el's load-theme
  ;; definition 
  (interactive
   (list
    (intern (completing-read "Load custom theme: "
                             (mapcar #'symbol-name
				     (custom-available-themes))))))
  (unless (custom-theme-name-valid-p theme)
    (error "Invalid theme name `%s'" theme))
  ;; prepare the theme for face-remap
  (load-theme theme t t)
  ;; set the theme-values as well 
  (theme-anchor-set-values theme)
  ;; choose the most appropriate theme for the environment 
  (let* ((valid-specs
	  (cl-remove 'nil ;; filter out non-applicable specs
		     (mapcar #'theme-anchor-spec-choose
			     ;; get the theme-face specs from the theme
			     (theme-anchor-get-faces theme))))
	 (inherit-specs (theme-anchor-spec-inherit valid-specs))
	 (valid-and-inherit-specs (append valid-specs inherit-specs)))
    ;; make sure the face is set as the buffer's based face by
    ;; 1. use face-remap-se-base face `nil' to make global face ignored
    ;; 2. apply the spec as the new base for the buffer 
    (cl-map nil (lambda (spec)
		  ;; attemp to cleanup base definition, seems not usefull 
		  ;; (face-remap-set-base (car spec) nil)
		  (apply #'face-remap-set-base spec))	;; anchor the spec as base 
	    ;; ignore faces without applicable specs
	    valid-and-inherit-specs)))

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
