;;; calmer-forest-theme.el --- Darkish theme with green/orange tint

;; Copyright © 2003 Artur Hefczyc
;; Copyright © 2013 David Caldwell

;; Author: Artur Hefczyc, created 2003-04-18
;;         David Caldwell <david@porkrind.org>
;; URL: https://github.com/caldwell/calmer-forest-theme
;; Package-Version: 20130926.510
;; Package-Commit: 87ba7bae389084d13fe3bc34e0c923017eda6ba0
;; Version: 1.1

;; This program is free software; you can redistribute it and/or modify
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

;; A nice semi dark theme. The orange and green hues give it a distinctly
;; old-school flavor, referencing the green and amber terminals of ancient
;; computer lore.

;; This theme is based on the old color-theme.el theme "calm forest", by
;; Artur Hefczyc.

;;; Code:

(deftheme calmer-forest)

(custom-theme-set-faces 'calmer-forest
  '(default ((t (:stipple nil :background "gray12" :foreground "green" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :width normal))))
  '(Info-title-1-face ((t (:bold t :family "helv" :weight bold :height 1.728))) t)
  '(Info-title-2-face ((t (:bold t :family "helv" :weight bold :height 1.44))) t)
  '(Info-title-3-face ((t (:bold t :family "helv" :weight bold :height 1.2))) t)
  '(Info-title-4-face ((t (:bold t :family "helv" :weight bold :height 1.1))) t)
  '(bold ((t (:bold t :weight bold))))
  '(bold-italic ((t (:italic t :bold t :slant italic :weight bold))))
  '(border ((t (:background "black"))))
  '(comint-highlight-input ((t (:bold t :weight bold))))
  '(comint-highlight-prompt ((t (:foreground "cyan"))))
  '(cparen-around-andor-face ((t (:bold t :foreground "maroon" :weight bold))))
  '(cparen-around-begin-face ((t (:foreground "maroon"))))
  '(cparen-around-conditional-face ((t (:bold t :foreground "RoyalBlue" :weight bold))))
  '(cparen-around-define-face ((t (:bold t :foreground "Blue" :weight bold))))
  '(cparen-around-lambda-face ((t (:foreground "LightSeaGreen"))))
  '(cparen-around-letdo-face ((t (:bold t :foreground "LightSeaGreen" :weight bold))))
  '(cparen-around-quote-face ((t (:foreground "SaddleBrown"))))
  '(cparen-around-set!-face ((t (:foreground "OrangeRed"))))
  '(cparen-around-syntax-rules-face ((t (:foreground "Magenta"))))
  '(cparen-around-vector-face ((t (:foreground "chocolate"))))
  '(cparen-binding-face ((t (:foreground "ForestGreen"))))
  '(cparen-binding-list-face ((t (:bold t :foreground "ForestGreen" :weight bold))))
  '(cparen-conditional-clause-face ((t (:foreground "RoyalBlue"))))
  '(cparen-normal-paren-face ((t (:foreground "grey50"))))
  '(cperl-array-face ((t (:foreground "light blue"))))
  '(cperl-hash-face ((t (:foreground "pink"))))
  '(cursor ((t (:background "VioletRed" :foreground "white"))))
  '(custom-button-face ((t (:background "lightgrey" :foreground "black" :box (:line-width 2 :style released-button)))) t)
  '(custom-button-pressed-face ((t (:background "lightgrey" :foreground "black" :box (:line-width 2 :style pressed-button)))) t)
  '(custom-changed-face ((t (:background "blue" :foreground "white"))) t)
  '(custom-comment-face ((t (:background "dim gray"))) t)
  '(custom-comment-tag-face ((t (:foreground "gray80"))) t)
  '(custom-documentation-face ((t (nil))) t)
  '(custom-face-tag-face ((t (:bold t :family "helv" :weight bold :height 1.2))) t)
  '(custom-group-tag-face ((t (:bold t :foreground "light blue" :weight bold :height 1.2))) t)
  '(custom-group-tag-face-1 ((t (:bold t :family "helv" :foreground "pink" :weight bold :height 1.2))) t)
  '(custom-invalid-face ((t (:background "red" :foreground "yellow"))) t)
  '(custom-modified-face ((t (:background "blue" :foreground "white"))) t)
  '(custom-rogue-face ((t (:background "black" :foreground "pink"))) t)
  '(custom-saved-face ((t (:underline t))) t)
  '(custom-set-face ((t (:background "white" :foreground "blue"))) t)
  '(custom-state-face ((t (:foreground "lime green"))) t)
  '(custom-variable-button-face ((t (:bold t :underline t :weight bold))) t)
  '(custom-variable-tag-face ((t (:bold t :family "helv" :foreground "light blue" :weight bold :height 1.2))) t)
  '(diff-added ((t (:inherit diff-changed :foreground "#50ff50" :background nil))))
  '(diff-file-header ((t (:background "gray30"))))
  '(diff-function ((t (:background "gray40"))))
  '(diff-header ((t (:background "gray30" :foreground "white"))))
  '(diff-indicator-added ((t (:inherit diff-added :foreground "dark green"))))
  '(diff-indicator-removed ((t (:inherit diff-removed :foreground "dark red"))))
  '(diff-refine-added ((t (:inherit diff-refine-change :background "#2a302a"))))
  '(diff-refine-change ((t (:background "gray20"))))
  '(diff-refine-removed ((t (:inherit diff-refine-change :background "#402a2a"))))
  '(diff-removed ((t (:inherit diff-changed :foreground "#ff5050" :background nil))))
  '(eieio-custom-slot-tag-face ((t (:foreground "light blue"))))
  '(extra-whitespace-face ((t (:background "pale green"))))
  '(fixed-pitch ((t (:family "courier"))))
  '(font-latex-bold-face ((t (:bold t :foreground "OliveDrab" :weight bold))))
  '(font-latex-italic-face ((t (:italic t :foreground "OliveDrab" :slant italic))))
  '(font-latex-math-face ((t (:foreground "burlywood"))))
  '(font-latex-sedate-face ((t (:foreground "LightGray"))))
  '(font-latex-string-face ((t (:foreground "RosyBrown"))))
  '(font-latex-warning-face ((t (:bold t :foreground "Red" :weight bold))))
  '(font-lock-builtin-face ((t (:foreground "LightSteelBlue"))))
  '(font-lock-comment-delimiter-face ((t (:foreground "chocolate2"))))
  '(font-lock-comment-face ((t (:foreground "chocolate3"))))
  '(font-lock-constant-face ((t (:foreground "Aquamarine"))))
  '(font-lock-doc-face ((t (:foreground "LightSalmon"))))
  '(font-lock-function-name-face ((t (:foreground "LightSkyBlue"))))
  '(font-lock-keyword-face ((t (:foreground "Cyan"))))
  '(font-lock-negation-char-face ((t (:foreground "firebrick" :weight bold))))
  '(font-lock-preprocessor-face ((t (:inherit font-lock-builtin-face :foreground "red"))))
  '(font-lock-string-face ((t (:foreground "LightSalmon"))))
  '(font-lock-type-face ((t (:foreground "PaleGreen"))))
  '(font-lock-variable-name-face ((t (:foreground "LightGoldenrod"))))
  '(font-lock-warning-face ((t (:bold t :foreground "Pink" :weight bold))))
  '(fringe ((t (:background "grey10"))))
  '(header-line ((t (:box (:line-width -1 :style released-button) :background "grey20" :foreground "grey90" :box nil))))
  '(highlight ((t (:background "darkolivegreen"))))
  '(hours-interval-face ((t (:foreground "LightSteelBlue" :weight bold))))
  '(hours-invoice-face ((t (:foreground "LightGoldenrod" :weight bold))))
  '(info-header-node ((t (:italic t :bold t :weight bold :slant italic :foreground "white"))))
  '(info-header-xref ((t (:bold t :weight bold :foreground "cyan"))))
  '(info-menu-5 ((t (:foreground "red1"))) t)
  '(info-menu-header ((t (:bold t :family "helv" :weight bold))))
  '(info-node ((t (:italic t :bold t :foreground "white" :slant italic :weight bold))))
  '(info-xref ((t (:bold t :foreground "cyan" :weight bold))))
  '(isearch ((t (:background "palevioletred2" :foreground "brown4"))))
  '(italic ((t (:italic t :slant italic))))
  '(jde-bug-breakpoint-cursor ((t (:background "brown" :foreground "cyan"))))
  '(jde-db-active-breakpoint-face ((t (:background "red" :foreground "black"))))
  '(jde-db-requested-breakpoint-face ((t (:background "yellow" :foreground "black"))))
  '(jde-db-spec-breakpoint-face ((t (:background "green" :foreground "black"))))
  '(jde-java-font-lock-api-face ((t (:foreground "light goldenrod"))))
  '(jde-java-font-lock-bold-face ((t (:bold t :weight bold))))
  '(jde-java-font-lock-code-face ((t (nil))))
  '(jde-java-font-lock-constant-face ((t (:foreground "Aquamarine"))))
  '(jde-java-font-lock-doc-tag-face ((t (:foreground "light coral"))))
  '(jde-java-font-lock-italic-face ((t (:italic t :slant italic))))
  '(jde-java-font-lock-link-face ((t (:foreground "blue" :underline t :slant normal))))
  '(jde-java-font-lock-modifier-face ((t (:foreground "LightSteelBlue"))))
  '(jde-java-font-lock-number-face ((t (:foreground "LightSalmon"))))
  '(jde-java-font-lock-operator-face ((t (:foreground "medium blue"))))
  '(jde-java-font-lock-package-face ((t (:foreground "steelblue1"))))
  '(jde-java-font-lock-pre-face ((t (nil))))
  '(jde-java-font-lock-underline-face ((t (:underline t))))
  '(lazy-highlight ((t (:background "paleturquoise4"))))
  '(menu ((t (nil))))
  '(minibuffer-prompt ((t (:foreground "steelblue1"))))
  '(mode-line ((t (:background "gray37" :foreground "grey85" :overline "black" :height 1.2))))
  '(mode-line-buffer-id ((t (:weight bold :family "helvetica"))))
  '(mode-line-inactive ((t (:inherit mode-line :background "grey20" :foreground "grey40" :weight light))))
  '(mouse ((t (:background "yellow"))))
  '(region ((t (:background "blue3"))))
  '(scroll-bar ((t (nil))))
  '(secondary-selection ((t (:background "SkyBlue4"))))
  '(semantic-dirty-token-face ((t (:background "gray10"))))
  '(semantic-unmatched-syntax-face ((t (:underline "red"))))
  '(senator-intangible-face ((t (:foreground "gray75"))))
  '(senator-momentary-highlight-face ((t (:background "gray30"))))
  '(senator-read-only-face ((t (:background "#664444"))))
  '(show-paren-match ((t (:background "turquoise" :foreground "black"))))
  '(show-paren-mismatch ((t (:background "purple" :foreground "white"))))
  '(speedbar-button-face ((t (:foreground "green3"))))
  '(speedbar-directory-face ((t (:foreground "light blue"))))
  '(speedbar-file-face ((t (:foreground "cyan"))))
  '(speedbar-highlight-face ((t (:background "sea green"))))
  '(speedbar-selected-face ((t (:foreground "red" :underline t))))
  '(speedbar-separator-face ((t (:background "blue" :foreground "white" :overline "gray"))))
  '(speedbar-tag-face ((t (:foreground "yellow"))))
  '(tool-bar ((t (:background "grey75" :foreground "black" :box (:line-width 1 :style released-button)))))
  '(trailing-whitespace ((t (:background "grey35"))))
  '(underline ((t (:underline t))))
  '(variable-pitch ((t (:family "helv"))))
  '(widget-button ((t (:bold t :weight bold))))
  '(widget-button-pressed ((t (:foreground "red"))))
  '(widget-documentation ((t (:foreground "lime green"))))
  '(widget-field ((t (:background "dim gray"))))
  '(widget-inactive ((t (:foreground "light gray"))))
  '(widget-single-line-field ((t (:background "dim gray")))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'calmer-forest)

;;; calmer-forest-theme.el ends here
