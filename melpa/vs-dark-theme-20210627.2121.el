;;; vs-dark-theme.el --- Visual Studio IDE dark theme

;; Copyright (C) 2019-2021 , Jen-Chieh Shen

;; Author: Jen-Chieh Shen
;; URL: https://github.com/emacs-vs/vs-dark-theme
;; Package-Version: 20210627.2121
;; Package-Commit: fc9766b4d772df7006998f3d863e9469498cfdc3
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
;; Visual Studio IDE dark theme.
;;

;;; Code:

(deftheme vs-dark
  "Visual Studio IDE dark theme.")

(let ((class '((class color) (min-colors 89)))
      (fg1 "#D2D2D2")
      (bg1 "#1E1E1E")
      (builtin "#B0C4DE")
      (keyword "#17A0FB")
      (const "#38EFCA")
      (comment "#6B8E23")
      (func "#D2D2D2")
      (str "#D69D78")
      (type "#38EFCA")
      (var "#D2D2D2")
      (prep "#8D9B99")
      (ln-color-fg "#2B9181")
      (ln-color-bg "#252525"))
  (custom-theme-set-faces
   'vs-dark
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
(defun vs-dark-theme ()
  "Load Visual Studio dark theme."
  (interactive)
  (load-theme 'vs-dark t))

(provide-theme 'vs-dark)

(provide 'vs-dark-theme)
;;; vs-dark-theme.el ends here
