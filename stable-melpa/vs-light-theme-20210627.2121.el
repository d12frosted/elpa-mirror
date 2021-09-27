;;; vs-light-theme.el --- Visual Studio IDE light theme

;; Copyright (C) 2019-2021 , Jen-Chieh Shen

;; Author: Jen-Chieh Shen
;; URL: https://github.com/emacs-vs/vs-light-theme
;; Package-Version: 20210627.2121
;; Package-Commit: 1211f09ec83f3f375b2e38e4d704bd102bf3f6e3
;; Version: 0.2
;; Package-Requires: ((emacs "24.1"))
;; Created with emacs-theme-generator, https://github.com/mswift42/theme-creator.

;; This file is NOT part of GNU Emacs.

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
;;
;; Visual Studio IDE light theme.
;;

;;; Code:

(deftheme vs-light
  "Visual Studio IDE light theme.")

(let ((class '((class color) (min-colors 89)))
      (fg1 "#000000")
      (bg1 "#ffffff")
      (builtin "#B0C4DE")
      (keyword "#0000FF")
      (const   "#2B91AF")
      (comment "#6B8E23")
      (func    "#74534B")
      (str     "#B21515")
      (type    "#2B91AF")
      (var     "#000000")
      (prep "#8D9B99")
      (ln-color-fg "#2B91AF")
      (ln-color-bg "#EEEEEE"))
  (custom-theme-set-faces
   'vs-light
   `(default ((,class (:background ,bg1 :foreground ,fg1))))
   `(font-lock-builtin-face ((,class (:foreground ,builtin))))
   `(font-lock-comment-face ((,class (:foreground ,comment))))
   `(font-lock-negation-char-face ((,class (:foreground ,const))))
   `(font-lock-reference-face ((,class (:foreground ,const))))
   `(font-lock-constant-face ((,class (:foreground ,const))))
   `(font-lock-doc-face ((,class (:foreground ,comment))))
   `(font-lock-function-name-face ((,class (:foreground ,func))))
   `(font-lock-keyword-face ((,class (:foreground ,keyword))))
   `(font-lock-string-face ((,class (:foreground ,str))))
   `(font-lock-type-face ((,class (:foreground ,type ))))
   `(font-lock-variable-name-face ((,class (:foreground ,var))))
   `(font-lock-preprocessor-face ((,class (:foreground ,prep))))
   `(line-number ((,class (:background ,ln-color-bg , :foreground ,ln-color-fg))))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

;;;###autoload
(defun vs-light-theme ()
  "Load Visual Studio light theme."
  (interactive)
  (load-theme 'vs-light t))

(provide-theme 'vs-light)

(provide 'vs-light-theme)
;;; vs-light-theme.el ends here
