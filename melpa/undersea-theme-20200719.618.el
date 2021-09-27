;;; undersea-theme.el --- Theme styled after undersea imagery  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Shen, Jen-Chieh
;; Created date 2020-07-16 00:16:27

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Theme styled after undersea imagery.
;; Keyword: theme sea
;; Package-Version: 20200719.618
;; Package-X-Original-Version: 0.3
;; Package-Requires: ((emacs "24.3"))
;; Package-Commit: fa821425572cc75fbc7b990c800d4659dd893a4e
;; URL: https://github.com/jcs-elpa/undersea-theme

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
;; Theme styled after undersea imagery.
;;

;;; Code:

(deftheme undersea "Theme describe UnderSea.")

(let ((class '((class color) (min-colors 89)))
      (fg1 "#E7E7E7")
      (bg1 "#2C444D")
      (builtin "#00FFFF")
      (keyword "#6DD8E3")
      (const "#D9C0A3")
      (comment "#38C77B")
      (func "#FFFFFF")
      (str "#B3D200")
      (type "#B2B2EC")
      (var "#FFFFFF")
      (prep "#8D9B99")
      (ln-color-fg "#95BBB5")
      (ln-color-bg "#255162"))
  (custom-theme-set-faces
   'undersea
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
(defun undersea-theme ()
  "Theme styled after undersea imagery."
  (interactive)
  (load-theme 'undersea t))

(provide-theme 'undersea)

(provide 'undersea-theme)
;;; undersea-theme.el ends here
