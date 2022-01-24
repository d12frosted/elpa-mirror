;;; pretty-speedbar.el --- Make speedbar pretty -*- lexical-binding: t -*-
;; Copyright (C) 2022 Kristle Chester, all rights reserved.
;; Author: Kristle Chester <kcyarn7@gmail.com>
;; Maintainer: Kristle Chester <kcyarn7@gmail.com>
;; Created: 2019-11-18
;; Version: 0.2
;; Package-Version: 20220124.16
;; Package-Commit: ea3daaf6a526a1ad4ae385066c99fd9643da7f94
;; Last-Updated: 2022-01-17
;; URL: https://github.com/kcyarn/pretty-speedbar
;; Package-Requires: ((emacs "27.1"))
;; Keywords: file, tags, tools
;; Compatibility:
;; License: GPL-3.0-or-later
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
;; Pretty Speedbar defaults to Font Awesome 5 Free Solid, which must be
;; installed from the otf available from Font Awesome's GitHub repository --
;; https://github.com/FortAwesome/Font-Awesome.
;; To use svg icons, you must first run pretty-speedbar-generate.  This
;; creates static icon files in the pretty-speedbar-icons-dir.  Alternatively,
;; icons may be created by hand in the pretty-speedbar-icons-dir.
;; To customize the folder colors, set a hex color for
;; pretty-speedbar-icon-folder-fill and pretty-speedbar-icon-folder-stroke.
;; To customize the non-folder icons, set a hex color for
;; pretty-speedbar-icon-fill and pretty-speedbar-icon-stroke.
;; To customize checks and locks, set a hex color for
;; pretty-speedbar-about-fill and pretty-speedbar-about-stroke.
;; To customize the plus and minus signs used on both the folder and
;; non-folder icons, set pretty-speedbar-signs-fill.
;; To alter the icon size, set pretty--speedbar-icon-size.   This sets the
;; folder and non-folder icon height in pixels.  Icon width and the about
;; icons (check and lock icons) are calculated based on this value.
;; Changing the icon font requires changing the unicode setting for each icon.
;; Please see the 'Icon Reference' section in the readme file for complete
;; table of these variables matched to their unicodes and the output image.
;;; Code:

(require 'speedbar)
(require 'svg)

(defconst pretty-speedbar-icons-dir
  (expand-file-name (concat user-emacs-directory "pretty-speedbar-icons/"))
  "Store pretty-speedbar-icons in the pretty-speedbar-icons folder.
This is located in the user's default Emacs directory.")

(defgroup pretty-speedbar nil
  "Group for pretty-speedbar."
  :group 'pretty-speedbar
  :prefix "pretty-speedbar-")

(defcustom pretty-speedbar-font "Font Awesome 5 Free Solid"
  "Set the default icon font To Font Awesome 5 Free Solid.
This is obtainable as an otf from github."
  :type '(string)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-icon-size 20
  "Set default size in pixels and applies to both width and height."
  :type '(integer)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-icon-fill "#DCDCDC"
  "Set default non-folder fill color as hex."
  :type '(string)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-icon-stroke "#000000"
  "Set default non-folder stroke color as hex."
  :type '(string)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-icon-folder-fill "#353839"
  "Set default folder fill color as hex."
  :type '(string)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-icon-folder-stroke "#333333"
  "Set default folder stroke color as hex."
  :type '(string)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-about-fill "#FF0000"
  "Set default non-folder fill color as hex."
  :type '(string)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-about-stroke "#222222"
  "Set default non-folder stroke color as hex."
  :type '(string)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-signs-fill "#555555"
  "Set default fill color for plus and minus signs added to select icons."
  :type '(string)
  :group 'pretty-speedbar)

;;; Set the icon unicode and if it's folder.

(defcustom pretty-speedbar-lock '("\uf023")
  "Lock icon from FontAwesome used by `pretty-lock'."
  :type '(list string)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-tag '("\uf02b" nil)
  "Tag from FontAwesome used by `pretty-tag'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-tags '("\uf02c" nil)
  "Tags (plural) from FontAwesome.
See `pretty-tags-plus' and `pretty-tags-minus'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-info '("\uf05a" nil)
  "Info-circle from FontAwesome used by `pretty-info'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-mail '("\uf0e0" nil)
  "Envelope from FontAwesome used by `pretty-mail'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-book '("\uf02d" nil)
  "Book from FontAwesome used by `pretty-book'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-box-closed '("\uf466" nil)
  "Box from FontAwesome used by `pretty-box-closed'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-box-open '("\uf49e" nil)
  "Box-open from FontAwesome used by `pretty-box-open'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-folder '("\uf07b" t)
  "Folder from FontAwesome used by `pretty-folder'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-folder-open '("\uf07c" t)
  "Folder-open from FontAwesome used by `pretty-folder-open'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-page '("\uf15c" nil)
  "File-alt from FontAwesome used by `pretty-page'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-blank-page '("\uf15b" nil)
  "File from FontAwesome used by `pretty-page-plus' and `pretty-page-minus'."
  :type '(list string boolean)
  :group 'pretty-speedbar)

(defcustom pretty-speedbar-check '("\uf00c")
  "Check from FontAwesome used by `pretty-check'."
  :type '(list string)
  :group 'pretty-speedbar)

(defun pretty-speedbar-about-svg (this-name this-list)
  "Create smaller informative icons, including checkmarks and locks.
THIS-NAME refers to the name used both for the svg and ezimage.
THIS-LIST draws from the icon's defcustom or a setq."

  (let ((this-icon (car this-list))
	(this-size (* 0.7 pretty-speedbar-icon-size)))
    (let ((this-svg (svg-create this-size this-size :viewBox "0 0 512 512")))
      (svg-text this-svg this-icon
	    :font-size "470px" ;;; changed from 507
	    :stroke pretty-speedbar-about-stroke
	    :fill pretty-speedbar-about-fill
	    :font-family  (format "\'%s\'" pretty-speedbar-font)
	    :x "50%"
	    :y "450" ;;; changed from 90%
	   ;; :dominant-baseline "middle"
	    :text-anchor "middle"
	    :rendering "optimizeLegibility"
	    :stroke-width 5)
    (with-temp-file (expand-file-name (concat this-name ".svg") pretty-speedbar-icons-dir)
    (set-buffer-multibyte nil)
    (svg-print this-svg)))))

(defun pretty-speedbar-svg (this-name this-list &optional this-sign)
  "Function to create individual icon svgs.
THIS-NAME is the icon's filename.
THIS-LIST being the individual icon's variable.
THIS-SIGN will create a plus or minus sign, if desired."
  (let ((pretty-speedbar-icon-width (/ pretty-speedbar-icon-size 0.8643))
	(this-icon (car this-list))
	(is-folder (nth 1 this-list))
	(this-pretty-icon-fill pretty-speedbar-icon-fill)
	(this-pretty-icon-stroke pretty-speedbar-icon-stroke))
    (let ((this-svg (svg-create pretty-speedbar-icon-width  pretty-speedbar-icon-size :viewBox "0 0 512 512")))
      (if is-folder
	(progn
	(setq this-pretty-icon-fill pretty-speedbar-icon-folder-fill)
	(setq this-pretty-icon-stroke pretty-speedbar-icon-folder-stroke)))
      (svg-text this-svg this-icon
	    :font-size "470px" ;;; changed from 507
	    :stroke this-pretty-icon-stroke
	    :fill  this-pretty-icon-fill
	    :font-family  (format "\'%s\'" pretty-speedbar-font)
	    :x "50%"
	    :y "450"
	    :text-anchor "middle"
	    :rendering "optimizeLegibility"
	    :stroke-width 5)
      (if (equal this-sign "plus")
	  (progn
	    (svg-rectangle this-svg 224.62 270 64 204.8
		       :rx 12.8
		       :ry 12.8
		       :fill  pretty-speedbar-signs-fill
		       :fill-rule "evenodd"
		       :rendering "optimizeLegibility")
	    (svg-rectangle this-svg -398 157.2 64 204.8
		       :transform "rotate(-90)"
		       :rx 12.8
		       :ry 12.8
		       :fill  pretty-speedbar-signs-fill
		       :fill-rule "evenodd"
		       :rendering "optimizeLegibility")))
      (if (equal this-sign "minus")
	  (svg-rectangle this-svg -398 157.2 64 204.8
		 :transform "rotate(-90)"
		 :rx 12.8
		 :ry 12.8
		 :fill  pretty-speedbar-signs-fill
		 :fill-rule "evenodd"
		 :rendering "optimizeLegibility"))
      (with-temp-file (expand-file-name (concat this-name ".svg") pretty-speedbar-icons-dir)
	(set-buffer-multibyte nil)
	(svg-print this-svg)))))

(defun pretty-speedbar-make-dir ()
  "Create the pretty-speedbar-icons directory."
  (unless (file-exists-p pretty-speedbar-icons-dir)
    (make-directory pretty-speedbar-icons-dir t)))

(defun pretty-speedbar-generate()
  "Generate the icon svg images."
  (interactive)
  (pretty-speedbar-make-dir)
  ;;; Create informative icons to the right of the file.
  (pretty-speedbar-about-svg "pretty-check" pretty-speedbar-check)
  (pretty-speedbar-about-svg "pretty-lock" pretty-speedbar-lock)
  ;;; Create file tree icons.
  (pretty-speedbar-svg "pretty-tag" pretty-speedbar-tag)
  (pretty-speedbar-svg "pretty-tags-plus" pretty-speedbar-tags "plus")
   (pretty-speedbar-svg "pretty-tags-minus" pretty-speedbar-tags "minus")
  (pretty-speedbar-svg "pretty-info" pretty-speedbar-info)
  (pretty-speedbar-svg "pretty-mail" pretty-speedbar-mail)
  (pretty-speedbar-svg "pretty-book" pretty-speedbar-book)
  (pretty-speedbar-svg "pretty-box-closed" pretty-speedbar-box-closed "plus")
  (pretty-speedbar-svg "pretty-box-open" pretty-speedbar-box-open "minus")
  (pretty-speedbar-svg "pretty-page-plus" pretty-speedbar-blank-page "plus")
  (pretty-speedbar-svg "pretty-page-minus" pretty-speedbar-blank-page "minus")
  (pretty-speedbar-svg "pretty-folder" pretty-speedbar-folder)
  (pretty-speedbar-svg "pretty-folder-open" pretty-speedbar-folder-open)
  (pretty-speedbar-svg "pretty-page" pretty-speedbar-page))

;;; manually using pretty-page works. Now change it to variables.

(defmacro pretty-speedbar-ezimage (this-name)
  "Macro for defezimage with THIS-NAME matching icon's name."
  `(defezimage ,(intern (format "%s" this-name)) ((:type svg :file ,(expand-file-name (format "%s.svg" this-name)  (expand-file-name (concat user-emacs-directory "pretty-speedbar-icons/"))) :ascent center)) "Documentation string replace."))

;; Manually add the correct documentation for each ezimage. Passing it to the defmacro itself causes compilation errors.
(pretty-speedbar-ezimage "pretty-check")
(put 'pretty-check 'function-documentation "Replacement for ezimage-checkout, which marks files checked out of a vc.")

(pretty-speedbar-ezimage "pretty-lock")
(put 'pretty-lock 'function-documentation "Replacement for ezimage-lock, which is described as a read only or private.")

(pretty-speedbar-ezimage "pretty-tag")
(put 'pretty-tag 'function-documentation "Replacement for ezimage-tag, which is used for the table of contents.")

(pretty-speedbar-ezimage "pretty-tags-plus")
(put 'pretty-tags-plus 'function-documentation "Replacement for ezimage-tag-gt, which is described as closed tags.")

(pretty-speedbar-ezimage "pretty-tags-minus")
(put 'pretty-tags-minus 'function-documentation "Replacement for ezimage-tag-v, which is described as open tags.")

(pretty-speedbar-ezimage "pretty-info")
(put 'pretty-info 'function-documentation "Replacement for ezimage-info.")

(pretty-speedbar-ezimage "pretty-lock")
(put 'pretty-lock 'function-documentation "Replacement for ezimage-lock, which is used for read only and private.")

(pretty-speedbar-ezimage "pretty-mail")
(put 'pretty-mail 'function-documentation "Replacement for ezimage-mail.")

(pretty-speedbar-ezimage "pretty-book")
(put 'pretty-book 'function-documentation "Replacement for ezimage-document-tag, which means documentation available.")

(pretty-speedbar-ezimage "pretty-box-closed")
(put 'pretty-box-closed 'function-documentation "Replacement for ezimage-box-plus.  Used by the table of contents.")

(pretty-speedbar-ezimage "pretty-box-open")
(put 'pretty-box-open 'function-documentation "Replacement for ezimage-box-minus, which refers to an open box.")

(pretty-speedbar-ezimage "pretty-folder")
(put 'pretty-folder 'function-documentation "Replacement for ezimage-directory-plus and ezimage-directory.")

(pretty-speedbar-ezimage "pretty-folder-open")
(put 'pretty-folder-open 'function-documentation "Replacement for ezimage-directory-minus.")

(pretty-speedbar-ezimage "pretty-page")
(put 'pretty-page 'function-documentation "Replacement for ezimage-page.")

(pretty-speedbar-ezimage "pretty-page-plus")
(put 'pretty-page-plus 'function-documentation "Replacement for ezimage-page-plus.")

(pretty-speedbar-ezimage "pretty-page-minus")
(put 'pretty-page-minus 'function-documentation "Replacement for ezimage-plus-minus.")

;;;###autoload
(setq speedbar-expand-image-button-alist
      '(("<+>" . pretty-folder)
    ("<->" . pretty-folder-open)
    ("< >" . pretty-folder)
    ("[+]" . pretty-page-plus)
    ("[-]" . pretty-page-minus)
    ("[?]" . pretty-page)
    ("[ ]" . pretty-page)
    ("{+}" . pretty-box-closed)
    ("{-}" . pretty-box-open)
    ("<M>" . pretty-mail)
    ("<d>" . pretty-book)
    ("<i>" . pretty-info)
    (" =>" . pretty-tag)
    (" +>" . pretty-tags-plus)
    (" ->" . pretty-tags-minus)
    (">"   . pretty-tag)
    ("@"   . pretty-tag)
    ("  @" . pretty-tag)
    ("*"   . pretty-check)
    ("%"   . pretty-lock)))


(provide 'pretty-speedbar)
;;; pretty-speedbar.el ends here
