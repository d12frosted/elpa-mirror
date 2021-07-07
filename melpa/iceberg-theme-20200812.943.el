;;; iceberg-theme.el --- Well-designed, eye-friendly, dark blue color scheme  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.0.1
;; Package-Version: 20200812.943
;; Package-Commit: 183b41eae07d94d4a8f299306078410bddc41d34
;; Keywords: convenience
;; Package-Requires: ((emacs "26.1") (solarized-theme "1.3"))
;; URL: https://github.com/conao3/iceberg-theme.el

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Well-designed, eye-friendly, dark blue color scheme.

;; Sample configure

;;   (leaf iceberg-theme
;;     :ensure t
;;     :config
;;     (iceberg-theme-create-theme-file)
;;     (load-theme 'solarized-iceberg-dark t))


;;; Code:

(require 'solarized-theme)

(defgroup iceberg-theme nil
  "Well-designed, eye-friendly, dark blue color scheme."
  :prefix "iceberg-theme-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/iceberg-theme.el"))

;;;###autoload
(defun iceberg-theme-create-theme-file ()
  "Create iceberg-theme color theme using solarized API.

Solarized pallete.

brightest                                   darkest
base03 base02 base01 base00 base0 base1 base2 base3

yellow orange red magenta violet blue cyan green"
  (solarized-create-theme-file-with-palette 'dark 'solarized-iceberg-dark
    '("#161821" "#c6c8d1" "#e2a478" "#e27878" "#e27878" "#a093c7" "#b4be82" "#84a0c6" "#89b8c2" "#84a0c6")
    '((custom-theme-set-faces
       theme-name
       `(default ((,class (:foreground ,base3 :background ,base03))))
       `(vertical-border ((,class (:foreground ,base03))))
       `(mode-line ((,class (:foreground ,base2 :background ,base02))))
       `(mode-line-inactive ((,class (:foreground ,base0 :background ,base03))))

       `(font-lock-comment-delimiter-face ((,class (:foreground "#6b7089"))))
       `(font-lock-comment-face ((,class (:foreground "#6b7089"))))
       `(font-lock-preprocessor-face ((,class (:foreground ,green)))) ; yellow
       `(font-lock-type-face ((,class (:foreground ,cyan)))) ; yellow
       `(font-lock-builtin-face ((,class (:foreground ,green)))) ; base0

       `(diff-function ((,class (:foreground ,violet-1fg))))
       `(diff-header ((,class (:foreground ,green))))
       `(diff-hunk-header ((,class (:foreground ,green))))
       `(diff-file-header ((,class (:background ,base03 :foreground ,green))))
       `(diff-added ((,class (:background ,violet-1bg :foreground ,violet-1fg))))
       `(diff-indicator-added ((t (:foreground ,violet))))
       `(markdown-header-face ((,class (:foreground ,yellow))))
       `(markdown-header-rule-face ((,class (:foreground ,green))))
       `(markdown-markup-face ((,class (:inherit default))))
       `(markdown-url-face ((,class (:foreground ,magenta))))
       `(markdown-link-face ((,class (:foreground ,green :underline t))))
       `(markdown-inline-code-face ((,class (:foreground ,cyan))))
       `(markdown-pre-face ((,class (:foreground ,cyan))))
       `(sh-quoted-exec ((,class (:foreground ,violet))))
       `(haskell-type-face ((,class (:inherit default))))
       `(haskell-constructor-face ((,class (:inherit default))))
       `(haskell-operator-face ((,class (:foreground ,green))))
       `(haskell-definition-face ((,class (:inherit default))))
       `(web-mode-block-delimiter-face ((,class (:inherit default))))
       `(web-mode-html-attr-value-face ((,class (:foreground ,cyan))))
       `(web-mode-mode-type-face ((,class (:inherit default))))
       `(web-mode-function-call-face ((,class (:inherit default))))
       `(web-mode-keyword-face ((,class (:foreground ,green))))
       `(web-mode-constant-face ((,class (:foreground ,cyan))))
       `(web-mode-variable-name-face ((,class (:foreground ,cyan))))
       `(web-mode-html-tag-bracket-face ((,class (:foreground ,green))))
       `(org-verbatim ((,class (:foreground ,cyan))))
       `(php-php-tag ((,class (:inherit default))))
       `(php-constant ((,class (:inherit default))))
       `(php-paamayim-nekudotayim ((,class (:foreground ,green))))
       `(php-object-op ((,class (:foreground ,cyan))))
       `(php-variable-name ((,class (:foreground ,cyan))))
       `(php-variable-sigil ((,class (:foreground ,cyan))))))))

;;;###autoload
(define-obsolete-function-alias 'iceberg-theme-create-theme 'iceberg-theme-create-theme-file)

(provide 'iceberg-theme)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; iceberg-theme.el ends here
