;;; green-is-the-new-black-theme.el --- A cool and minimalist green blackened theme engine

;; Author: Fred Campos <fred.tecnologia@gmail.com>
;; Maintainer: Fred Campos <fred.tecnologia@gmail.com>
;; URL: https://github.com/fredcamps/green-is-the-new-black-emacs
;; Package-Version: 20210203.1511
;; Package-Commit: 09f6908064dd1854379a072d7cdd706959256299
;; Keywords: faces, themes
;; Version: 1.0.0

;; Copyright (c) 2017-2021 Fred Campos

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

;; This package provides a theme with minimalist blackened green colors.

;;; Code:

(deftheme green-is-the-new-black
  "Cool blackened green theme")

(let ((class '((class color) (min-colors 89)))
      (256color (eq (display-color-cells (selected-frame)) 256))
      (gitnb-black "#000000")
      (gitnb-heavy-grey "#1c1c1c")
      (gitnb-dark-grey "#2b2b30")
      (gitnb-grey "#898989")
      (gitnb-heavy-green "#005f00")
      (gitnb-dark-green "#218c23")
      (gitnb-green "#0ecc11")
      (gitnb-light-green "#8dcc78")
      (gitnb-bright-green "#46fc32")
      (gitnb-red "#f47a47")
      (gitnb-yellow "#e6fc20"))

  (custom-theme-set-faces
   'green-is-the-new-black
   `(default ((t (:background, gitnb-heavy-grey :foreground, gitnb-green))))
   `(cursor  ((t (:background, gitnb-dark-green :weight bold))))
   `(hl-line ((t (:background, gitnb-black :weight bold))))
   `(mode-line ((t (:box nil, :background, gitnb-black :foreground, gitnb-dark-green))))
   `(mode-line-inactive ((t (:inherit mode-line :background, gitnb-black :foreground, gitnb-grey :box nil))))
   `(fringe ((t (:background, gitnb-dark-grey))))
   `(region ((t (:background, gitnb-heavy-green :foreground, gitnb-light-green))))
   `(minibuffer-prompt ((t (:foreground, gitnb-green))))
   `(escape-glyph ((t (:foreground, gitnb-dark-green))))
   `(font-lock-builtin-face ((t (:foreground, gitnb-light-green))))
   `(font-lock-constant-face ((t (:foreground, gitnb-bright-green))))
   `(font-lock-comment-face ((t (:foreground, gitnb-grey))))
   `(font-lock-string-face ((t (:foreground, gitnb-grey))))
   `(font-lock-keyword-face ((t (:foreground, gitnb-bright-green :inherit bold))))
   `(font-lock-function-name-face ((t (:foreground, gitnb-yellow))))
   `(font-lock-type-face ((t (:foreground, gitnb-green :weight bold))))
   `(font-lock-doc-face ((t (:foreground, gitnb-grey))))
   `(font-lock-variable-name-face ((t (:foreground, gitnb-bright-green))))
   `(font-lock-regexp-grouping-backslash ((t (:inherit bold))))
   `(font-lock-regexp-grouping-construct ((t (:inherit bold))))
   `(font-lock-highlighting-faces ((t (:foreground, gitnb-light-green))))
   `(font-lock-negation-char-face ((t (:foreground, gitnb-bright-green :weight bold))))
   `(font-lock-warning-face ((t (:foreground, gitnb-yellow))))
   `(highlight ((t (:background, gitnb-dark-green :foreground, gitnb-bright-green :weight normal))))
   `(lazy-highlight ((t (:background, gitnb-heavy-green :foreground, gitnb-light-green))))
   `(tooltip ((t (:background, gitnb-grey :foreground, gitnb-black :inherit bold))))
   `(match ((t (:foreground, gitnb-grey :brackground, gitnb-black))))
   `(shadown ((t (:foreground, gitnb-dark-green))))
   `(secondary-selection ((t (:background, gitnb-dark-green :foreground, gitnb-grey))))
   `(link ((t (:foreground, gitnb-bright-green :underline, gitnb-bright-green :inherit bold))))
   `(link-visited ((t (:foreground, gitnb-green :underline, gitnb-green :inherit bold))))
   `(diff-added ((t (:background, gitnb-black :foreground, gitnb-green))))
   `(diff-changed ((t (:background, gitnb-black :foreground, gitnb-bright-green))))
   `(diff-removed ((t (:background, gitnb-black :foreground, gitnb-grey))))
   `(diff-context ((t (:inherit diff-changed))))
   `(diff-file-header ((t (:inherit diff-added))))
   `(diff-function ((t (:inherit diff-added))))
   `(diff-header ((t (:inherit diff-added))))
   `(diff-hunk-header ((t (:inherit diff-added))))
   `(diff-index ((t (:inherit diff-added))))
   `(diff-indicator-added ((t (:inherit diff-added))))
   `(diff-indicator-changed ((t (:inherit diff-changed))))
   `(diff-indicator-removed ((t (:inherit diff-removed))))
   `(diff-nonexistent ((t (:background, gitnb-black :foreground, gitnb-yellow))))
   `(diff-refine-added ((t (:inherit diff-added))))
   `(diff-refine-changed ((t (:inherit diff-changed))))
   `(diff-refine-removed ((t (:inherit diff-removed))))
   `(tool-bar ((t (:background, gitnb-black :foreground, gitnb-dark-green))))
   `(menu ((t (:background, gitnb-green :foreground, gitnb-black :box nil))))
   `(visible-bell ((t (:foreground, gitnb-black :background, gitnb-bright-green))))
   `(tty-menu-selected-face ((t  (:background, gitnb-bright-green :foreground, gitnb-black :weight bold))))
   `(tty-menu-enabled-face ((t  (:background, gitnb-green :foreground, gitnb-black))))
   `(tty-menu-disabled-face ((t  (:background, gitnb-grey :foreground, gitnb-black))))

   ;; -- plugins
   `(isearch ((t (:foreground, gitnb-bright-green :background, gitnb-dark-green ))))
   `(isearch-fail ((t (:foreground, gitnb-red :background, gitnb-black ))))

   `(ctbl:face-cell-select ((t (:foreground, gitnb-black :background, gitnb-green))))
   `(ctbl:face-row-select ((t (:foreground, gitnb-dark-green :background, gitnb-bright-green))))

   `(whitespace-empty ((t (:background nil :foreground , gitnb-light-green))))
   `(whitespace-indentation ((t (:background nil :foreground , gitnb-light-green))))
   `(whitespace-line ((t (:background nil :foreground , gitnb-light-green))))
   `(whitespace-newline ((t (:background nil :foreground , gitnb-light-green))))
   `(whitespace-space ((t (:background nil :foreground , gitnb-light-green))))
   `(whitespace-space-after-tab ((t (:background nil :foreground , gitnb-light-green))))
   `(whitespace-space-before-tab ((t (:background nil :foreground , gitnb-light-green))))
   `(whitespace-tab ((t (:background nil))))
   `(whitespace-trailing ((t class (:background , gitnb-light-green :foreground , gitnb-dark-green))))

   `(show-paren-match ((t (:foreground, gitnb-light-green :background, gitnb-black :weight bold))))
   `(show-paren-mismatch ((t (:foreground, gitnb-red :background, gitnb-black :weight bold))))

   `(ido-indicator ((t (:background, gitnb-dark-green :foreground, gitnb-black))))

   `(flycheck-error ((t (:underline, gitnb-red :foreground, gitnb-red))))
   `(flycheck-warning ((t (:underline, gitnb-yellow :foreground, gitnb-yellow))))
   `(flycheck-info ((t (:underline, gitnb-bright-green :foreground, gitnb-bright-green))))

   `(vertical-border ((t (:foreground, gitnb-green))))
   `(info ((t (:foreground, gitnb-bright-green))))
   `(warning ((t (:foreground, gitnb-yellow))))
   `(error ((t (:foreground, gitnb-red))))

   `(company-echo-common ((t (:foreground, gitnb-grey))))
   `(company-echo ((t (:inherit company-echo-common))))
   `(company-preview-common ((t (:background, gitnb-green :foreground, gitnb-black))))
   `(company-preview ((t (:inherit company-preview-common))))
   `(company-preview-search ((t (:inherit company-preview-common))))
   `(company-tooltip-selection ((t (:background, gitnb-light-green :foreground, gitnb-black))))
   `(company-scrollbar-bg ((t (:background, gitnb-green, :foreground, gitnb-black))))
   `(company-tooltip-common ((t (:foreground, gitnb-black :background, gitnb-dark-green))))
   `(company-tooltip-common-selection ((t (:foreground, gitnb-dark-grey :bold))))
   `(company-tooltip ((t (:background, gitnb-heavy-green))))
   `(company-tooltip-annotation ((t (:foreground, gitnb-bright-green))))
   `(company-tooltip-annotation-selection ((t (:foreground, gitnb-dark-green))))

   `(popup-menu-face ((t (:inherit company-tooltip))))
   `(popup-menu-selection-face ((t (:inherit company-tooltip-selection ))))
   `(popup-face ((t (:inherit popup-menu-face))))
   `(popup-isearch-match ((t (:background, gitnb-dark-green :foreground, gitnb-bright-green))))
   `(popup-tip-face ((t (:background, gitnb-bright-green :foreground, gitnb-black))))

   `(popup-menu-selection-face ((t (:inherit company-tooltip-selection))))
   `(popup-menu-mouse-face ((t (:inherit company-tooltip-selection))))
   `(popup-scroll-bar-background-face  ((t (:inherit company-scrollbar-bg))))

   `(column-enforce-face ((t (:foreground, gitnb-grey))))

   `(sml/vc ((t (:foreground, gitnb-bright-green))))
   `(sml/vc-edited ((t (:foreground, gitnb-bright-green :weight bold))))
   `(sml/battery ((t (:weight bold))))
   `(sml/projectile ((t (:foreground, gitnb-light-green ))))
   `(sml/filename ((t (:foreground, gitnb-green))))
   `(sml/read-only ((t (:foreground, gitnb-grey))))
   `(sml/position-percentage ((t (:foreground, gitnb-grey))))
   `(sml/prefix  ((t (:foreground, gitnb-light-green))))
   `(sml/process ((t (:foreground, gitnb-light-green))))

   `(doom-visual-bell ((t (:foreground, gitnb-black :background, gitnb-bright-green))))

   `(smerge-base ((t (:foreground, gitnb-bright-green :background, gitnb-dark-green))))
   `(smerge-markers ((t (:foreground, gitnb-bright-green :background, gitnb-dark-green))))
   `(smerge-mine ((t (:foreground, gitnb-bright-green :background, gitnb-dark-green))))
   `(smerge-other ((t (:foreground, gitnb-bright-green :background, gitnb-dark-green))))
   `(smerge-refined-changed ((t (:inherit diff-changed))))
   `(smerge-refined-removed ((t (:inherit diff-removed))))
   `(smerge-refined-added ((t (:inherit diff-added))))

   `(lsp-face-highlight-write ((t (:foreground, gitnb-black :background, gitnb-bright-green))))

   `(js2-external-variable ((t (:foreground, gitnb-yellow))))
   `(js2-private-function-call ((t (:foreground, gitnb-yellow))))
   `(js2-error ((t (:foreground, gitnb-red))))

   `(diff-hl-change ((t (:foreground, gitnb-heavy-grey :background, gitnb-yellow))))
   `(diff-hl-delete ((t (:foreground, gitnb-heavy-grey :background, gitnb-red))))
   `(diff-hl-insert ((t (:foreground, gitnb-heavy-green :background, gitnb-green))))

   `(which-func ((t (:foreground, gitnb-grey))))))


;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))


(provide-theme 'green-is-the-new-black)

;;; green-is-the-new-black-theme.el ends here
