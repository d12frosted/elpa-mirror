;;; yabaki-theme.el --- Yabaki, the cast shadow -*- lexical-binding: t; -*-

;; Copyright (C) 2023 David Goudou

;; Author: David Goudou <david.goudou@gmail.com>
;; Version: 2.0.0
;; Package-Version: 20230327.630
;; Package-Commit: 5face6a1194b039e09fe19238aa5db05450d7df1
;; Package-Requires: ((emacs "27.1"))
;; Homepage: https://github.com/seamacs/yabaki-theme

;; This file is not part of GNU Emacs.

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
;; A dark, bright-coloured theme for GNU Emacs

;;; Code:

(deftheme yabaki "Yabaki, the cast shadow.")

(let* ((fg "#F5F5DC")
       (bg "#080808")
       (blue-0 "#5B9BD5")
       (blue-1 "#00B0F0")
       (blue-2 "#0066CC")
       (green-0 "#2ECC71")
       (green-1 "#3FBF79")
       (green-2 "#00A65A")
       (grey-0 "#BDC3C7")
       (grey-1 "#8B8B8B")
       (grey-2 "#6C757D")
       (orange-0 "#FFA07A")
       (orange-1 "#FF8C00")
       (purple-0 "#9B59B6")
       (pink-0 "#F48FB1")
       (red-0 "#E74C3C")
       (red-1 "#DC143C")
       (red-2 "#B22222")
       (red-3 "#8B0000")
       (yellow-0 "#F1C40F")
       (black-0 "#161616")
       (black-1 "#18181b")
       (black-2 "#101010"))

  (custom-theme-set-faces
   'yabaki
   `(default ((t (:foreground ,fg :background ,bg))))
   `(diredp-date-time ((t (:foreground ,fg))))
   `(dired-directory ((t (:foreground ,blue-0))))
   `(diredp-deletion ((t (:foreground ,red-0 :background ,bg))))
   `(diredp-dir-heading ((t (:foreground ,yellow-0 :background ,bg))))
   `(diredp-dir-name ((t (:foreground ,green-1 :background ,bg))))
   `(diredp-dir-priv ((t (:foreground ,green-1 :background ,bg))))
   `(diredp-exec-priv ((t (:foreground ,fg :background ,bg))))
   `(diredp-file-name ((t (:foreground ,fg))))
   `(diredp-file-suffix ((t (:foreground ,fg))))
   `(diredp-link-priv ((t (:foreground ,fg))))
   `(diredp-number ((t (:foreground ,fg))))
   `(diredp-no-priv ((t (:foreground ,fg :background ,bg))))
   `(diredp-rare-priv ((t (:foreground ,red-0 :background ,bg))))
   `(diredp-read-priv ((t (:foreground ,fg :background ,bg))))
   `(diredp-symlink ((t (:foreground ,red-3))))
   `(diredp-write-priv ((t (:foreground ,fg :background ,bg))))
   `(font-lock-builtin-face ((t (:foreground ,pink-0))))
   `(font-lock-comment-face ((t (:slant italic :foreground ,grey-0))))
   `(font-lock-constant-face ((t (:foreground ,orange-1))))
   `(font-lock-doc-face ((t (:foreground ,green-0))))
   `(font-lock-function-name-face ((t (:foreground ,fg))))
   `(font-lock-keyword-face ((t (:slant italic :foreground ,purple-0))))
   `(font-lock-preprocessor-face ((t (:foreground ,green-1))))
   `(font-lock-string-face ((t (:foreground ,green-0))))
   `(font-lock-type-face ((t (:foreground ,orange-0))))
   `(font-lock-variable-name-face ((t (:foreground ,fg))))
   `(font-lock-warning-face ((t (:foreground ,red-1))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,yellow-0 :bold t))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,red-0 :bold t))))
   `(fringe ((t (:foreground ,fg :background ,bg))))
   `(parenthesis ((t (:foreground ,grey-2))))
   `(header-line ((t (:foreground ,fg))))
   `(highlight ((t (:foreground ,pink-0))))
   `(highlight-indentation-face ((t (:background ,grey-1))))
   `(highlight-indentation-current-column-face ((t (:background ,grey-1))))
   `(hl-line ((t (:background ,black-0))))
   `(isearch ((t (:foreground ,fg :background ,red-1))))
   `(isearch-fail ((t (:background ,red-1))))
   `(lazy-highlight ((t (:foreground ,red-1 :background unspecified))))
   `(match ((t (:background ,red-1))))
   `(minibuffer-prompt ((t (:foreground ,fg))))
   `(mode-line ((t (:foreground ,fg :background ,black-2))))
   `(mode-line-inactive ((t (:foreground ,grey-1 :background ,black-2))))
   `(org-ellipsis ((t (:foreground ,blue-2 :underline nil))))
   `(org-block ((t (:background ,black-1))))
   `(org-block-begin-line ((t (:slant italic))))
   `(org-checkbox ((t (:foreground ,green-1))))
   `(org-date ((t (:foreground ,grey-0))))
   `(org-document-info-keyword ((t (:foreground ,yellow-0))))
   `(org-document-title ((t (:foreground ,yellow-0))))
   `(org-verbatim ((t (:foreground ,blue-0))))
   `(org-code ((t (:foreground ,purple-0))))
   `(org-done ((t (:foreground ,green-2))))
   `(org-level-1 ((t (:foreground ,pink-0))))
   `(org-level-2 ((t (:foreground ,yellow-0))))
   `(org-level-3 ((t (:foreground ,green-1))))
   `(org-level-4 ((t (:foreground ,orange-0))))
   `(org-level-5 ((t (:foreground ,red-2))))
   `(org-level-6 ((t (:foreground ,red-0))))
   `(org-level-7 ((t (:foreground ,blue-0))))
   `(org-level-8 ((t (:foreground ,pink-0))))
   `(org-link ((t (:foreground ,blue-0))))
   `(org-meta-line ((t (:foreground ,grey-0))))
   `(org-special-keyword ((t (:foreground ,purple-0))))
   `(org-todo ((t (:foreground ,red-3))))
   `(region ((t (:foreground ,fg :background ,black-2))))
   `(trailing-whitespace ((t (:background ,red-1))))
   `(vertical-border ((t (:foreground ,black-2 :foreground ,black-2))))
   `(warning ((t (:foreground ,orange-0))))
   `(whitespace-trailing ((t (:background ,red-1))))
   `(cursor ((t (:foreground unspecified :background ,red-2))))
   `(show-paren-match ((t (:underline t :foreground ,blue-1))))
   `(rcirc-prompt ((t (:foreground ,fg))))
   `(rcirc-server ((t (:slant italic :foreground ,grey-0))))
   `(rcirc-url ((t (:foreground ,blue-0))))
   `(rcirc-my-nick ((t (:foreground ,purple-0))))
   `(rcirc-nick-in-message ((t (:foreground ,purple-0))))
   `(rcirc-nick-in-message-full-line ((t (:foreground ,purple-0))))
   `(rcirc-other-nick ((t (:foreground ,blue-2))))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory (or load-file-name buffer-file-name)))))

(provide-theme 'yabaki)

;;; yabaki-theme.el ends here
