;;; shades-of-purple-theme.el --- A theme with bold shades of purple

;; Copyright (C) 2021 by Arturo Vergara
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Author: Arturo Vergara <hello@dead.computer>
;; URL: https://github.com/arturovm/shades-of-purple-emacs
;; Package-Version: 20210506.1448
;; Package-Commit: 951b5901ff90ca86f18a39936fc84e2481a2c8b3
;; Version: 0.1.0

;;; Commentary:
;; Ported from the original by github.com/ahmadawais

;;; Code:
(deftheme shades-of-purple
  "A theme with bold shades of purple")

(custom-theme-set-faces
 'shades-of-purple
 ;; basics
 '(default      ((t (:background "#2D2B55" :foreground "#FFFFFF"))))
 '(cursor       ((t (:background "#FAD000"))))
 '(escape-glyph ((t (:foreground "#9EFFFF"))))
 '(highlight    ((t (:background "#7E46DF"))))
 '(region       ((t (:background "#B362FF" :foreground "#FFEE80"))))
 ;; ui elements
 '(line-number              ((t (:background "#28284E" :foreground "#A599E9"))))
 '(line-number-current-line ((t (:inherit line-number :foreground "#FAEFA5"))))
 '(fringe                   ((t (:inherit line-number))))
 '(hl-line                  ((t (:background "#1F1F41"))))
 '(link                     ((t (:foreground "#9EFFFF"))))
 '(success                  ((t (:foreground "#3AD900" :weight bold))))
 '(warning                  ((t (:foreground "#FAD000" :weight bold))))
 '(error                    ((t (:foreground "#EC3A37" :weight bold))))
 '(next-error               ((t (:inherit error :weight normal))))
 '(shadow                   ((t (:foreground "#494685"))))
 ;; mode-line and minibuffer
 '(mode-line          ((t (:background "#1E1E3F" :foreground "#FFFFFF"))))
 '(mode-line-inactive ((t (:background "#494685" :foreground "#CCCCCC" :weight light))))
 '(minibuffer-prompt  ((t (:foreground "#FAD000"))))
 '(show-paren-match   ((t (:inherit highlight :foreground "#FFEE80"))))
 ;; font lock
 '(font-lock-keyword-face           ((t (:foreground "#FF9D00"))))
 '(font-lock-constant-face          ((t (:foreground "#FF628C"))))
 '(font-lock-string-face            ((t (:foreground "#A5FF90"))))
 '(font-lock-type-face              ((t (:foreground "#FAD000"))))
 '(font-lock-variable-name-face     ((t (:foreground "#9EFFFF"))))
 '(font-lock-function-name-face     ((t (:foreground "#FAD000"))))
 '(font-lock-builtin-face           ((t (:foreground "#FAD000"))))
 '(font-lock-comment-face           ((t (:foreground "#B362FF" :slant italic))))
 '(font-lock-comment-delimiter-face ((t (:inherit font-lock-comment-face))))
 ;; search and replace
 '(isearch        ((t (:background "#FF7300" :foreground "#2D2B55"))))
 '(lazy-highlight ((t (:inherit isearch :background "#FFFF03"))))
 '(match          ((t (:inherit isearch))))
 ;; rainbow delimiters
 '(rainbow-delimiters-depth-1-face ((t (:inherit font-lock-constant-face))))
 '(rainbow-delimiters-depth-2-face ((t (:inherit font-lock-comment-face :slant normal))))
 '(rainbow-delimiters-depth-3-face ((t (:inherit font-lock-string-face))))
 '(rainbow-delimiters-depth-4-face ((t (:inherit font-lock-variable-name-face))))
 '(rainbow-delimiters-depth-5-face ((t (:inherit font-lock-constant-face))))
 '(rainbow-delimiters-depth-6-face ((t (:inherit font-lock-comment-face :slant normal))))
 '(rainbow-delimiters-depth-7-face ((t (:inherit font-lock-string-face))))
 '(rainbow-delimiters-depth-8-face ((t (:inherit font-lock-variable-name-face))))
 '(rainbow-delimiters-depth-9-face ((t (:inherit font-lock-constant-face))))
 ;; ido
 '(ido-subdir     ((t (:foreground "#FFEE80"))))
 '(ido-only-match ((t (:foreground "#FAEFA5"))))
 ;; flycheck
 '(flycheck-warning ((t (:underline (:color "#FAD000" :style wave)))))
 '(flycheck-info    ((t (:underline (:color "#A599E9" :style wave)))))
 '(flycheck-error   ((t (:underline (:color "#EC3A37" :style wave)))))
 ;; idris
 '(idris-identifier-face ((t (:inherit font-lock-variable-name-face))))
 '(idris-operator-face   ((t (:inherit font-lock-keyword-face))))
 ;; tuareg
 '(tuareg-font-lock-governing-face   ((t (:foreground "#FB94FF"))))
 '(tuareg-font-lock-constructor-face ((t (:inherit font-lock-type-face)))))


;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'shades-of-purple)
(provide 'shades-of-purple-theme)
;;; shades-of-purple-theme.el ends here
