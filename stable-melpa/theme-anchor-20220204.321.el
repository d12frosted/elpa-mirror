;;; theme-anchor.el --- Apply theme in current buffer only -*- lexical-binding: t -*-
 
;; Copyright (C) 2021-2022 Liāu, Kiong-Gē

;; ------------------------------------------------------------------------------
;; Author: Liāu, Kiong-Gē <gliao.tw@pm.me>
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Package-Requires: ((emacs "26"))
;; Package-Version: 20220204.321
;; Package-X-Original-Version: 20211224.2042
;; Package-Commit: aad9c0c0c888325cf6f9bb2310677d667b364f21
;; Keywords: extensions, lisp, theme
;; Homepage: https://github.com/GongYiLiao/theme-anchor
;; ------------------------------------------------------------------------------

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; Package-Commit: c6f715d4ccd30e83922e39cab856578ce19224bb
;; the Free Software Foundation, either X-Original-version 3 of the License, or
;; (at your option) any later version.
 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
 
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
 
;;; Commentary:

;; Using `face-remap's `face-remap-set-base function to set buffer-specific
;; custom theme.  Using `setq-local' to apply `theme-value's to current
;; buffer only

;;; Code:
(require 'cl-lib)  			;; for `cl-remove-if', `cl-map'
(require 'faces) 			;; for `face-spec-choose'
(require 'custom) 			;; for `load-theme'
(require 'face-remap) 			;; for `face-remap-add-relative'
(require 'org-macs) 			;; for `org-plist-delete'

(defcustom face-impute-alist nil
  "A associate list that specify how to apply theme to new faces.
According to themes applied to existing faces."
  :type '(alist :key-type symbol :value-type symbol)
  :group 'faces)

(defun theme-anchor-get-values (theme)
  "Extract all the theme-face values from THEME."
  ;; take only theme-face specs
  (mapcar (lambda (spc) `(,(nth 1 spc) ,(nth 3 spc)))
	  (cl-remove-if (lambda (spc) (not (eq (car spc) 'theme-value)))
			;; the theme's all the face/value specs
			(get theme 'theme-settings))))

(defun theme-anchor-set-values (theme)
  "Set buffer-local values using theme-values extracted from THEME.
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
  "Remove facse with nil foreground/background.
Arugment SPEC: a face plist to have nil bg/fg filtered out"
  (let ((spec-name (car spec))
	(face-plist (nth 1 spec)))
    (dolist (fc '(:foreground :background))
      (if (and (plist-member face-plist fc)
	       (not (plist-get face-plist fc)))
	  (setq face-plist (org-plist-delete face-plist fc))))
    (list spec-name face-plist)))

(defun theme-anchor-impute-faces ()
  "Impute themes into new faces based on existing faces."
  (if (and (boundp 'face-remapping-alist)
	   (boundp 'face-impute-alist))
      (let* ((face-remapping-alist-orig face-remapping-alist)
	     (face-remapping-keys-orig
	      (mapcar #'car face-remapping-alist-orig))
	     (face-impute-spc-valid
	      (seq-filter
	       (lambda (spc)
		 (let ((af (car spc))
		       (ef (cdr spc)))
		   (and (cl-find ef face-remapping-keys-orig)
			(not (cl-find af face-remapping-keys-orig)))))
	       face-impute-alist))
	     (face-impute-valid-alist
	      (if face-impute-spc-valid
		  (mapcar (lambda (spc)
			    (let ((k (car spc))
				  (v (alist-get (cdr spc)
						face-remapping-alist-orig)))
			      (cons k v)))
			  face-impute-spc-valid))))
	(setq-local face-remapping-alist
		    (append face-remapping-alist-orig face-impute-valid-alist)))))

(defun theme-anchor-buffer-local (theme)
  "Extract applicable face settings from THEME.
Argument THEME the theme to be applied in the mode hook .
It uses 'face-remap-set-base' to load that theme in a buffer local manner"
  ;; make sure the theme is available, copied from custom.el's load-theme
  ;; definition.
  (interactive
   (list (intern (completing-read "Load custom theme: "
				  (mapcar #'symbol-name
					  (custom-available-themes))))))
  (unless (custom-theme-name-valid-p theme)
    (error "Invalid theme name `%s'" theme))
  ;; prepare the theme for face-remap
  (if (load-theme theme t t)
      (progn
	;; set the theme-values as well
	(theme-anchor-set-values theme)
	(setq-local face-remapping-alist
		    (cl-remove nil
			       (mapcar (lambda (specs)
					 (theme-anchor-remove-nil-fgbg
					  (theme-anchor-spec-choose specs)))
				       (theme-anchor-get-faces theme))))
	(theme-anchor-impute-faces)
	(disable-theme theme)
	(force-mode-line-update))))

(defmacro theme-anchor-hook-gen (theme
				 &rest other-step)
  "Generate hook functions.
Argument THEME the theme to be applied in the mode hook.
Optional argument OTHER-STEP the additional steps to execute in the mode hook."
  `(lambda nil
     ;; face-remap current buffer with theme
     (theme-anchor-buffer-local ,theme)
     ;; other sides effect applicable to the current buffer
     ,@other-step))

(defun theme-anchor-face-attribute (face attribute &optional _frame _inherit buffer)
  "Return the value of FACE's ATTRIBUTE on FRAME or current buffer.
If the optional arguments FRAME and INHERIT are applicable to the
fallback function face-attribute-frame-local.
This function tries to extract `face-remapping-alist' from BUFFER,
if BUFFER is nil, `current-buffer' is used."
  ;; get if `face-remapping-alist' exists in buffer and has values
  (let ((buffer-faces (buffer-local-value
                           'face-remapping-alist
                           (or (and buffer (get-buffer buffer))
                               (current-buffer)))))
        ;; get face attribute from `face-remapping-alist'
        (and buffer-faces
             (plist-get (car (alist-get face buffer-faces))
                        attribute))))

(advice-add #'face-attribute :before-until #'theme-anchor-face-attribute)

(provide 'theme-anchor)
;;; theme-anchor.el ends here
