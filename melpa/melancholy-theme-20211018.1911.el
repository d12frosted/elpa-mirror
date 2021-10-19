;;; package --- Summary: melancholy-theme.el --- A dark theme for dark minds -*- lexical-binding: t; -*-

;; Copyright (C) 2016 Sod Oscarfono

;; Author: Sod Oscarfono <sod@oscarfono.com>
;; URL: http://github.com/techquila/melancholy-theme
;; Package-Commit: 0401c849203f8f497c8a93c1700451de7ff0675a
;; Package-Version: 20211018.1911
;; Package-X-Original-Version: 20211019.1001
;; Version: 2.0

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
;; ========================================
;; A dark theme for dark minds.  > Emacs 24
;;
;; Theme should be considered WIP and is likely to change dramatically, and frequently.
;; That will make you sad.  Now you know why the name?
;; The idea is to get it right by 2020. :-)

;;; Code:
;; ========================================

(deftheme melancholy
  "A dark theme for dark minds")

(let ((my-active       "#F92672")
       (my-visited      "#999999")
       (my-info         "#FFB728")
       (my-highlight    "#96BF33")
       (my-contrast     "#666666")
       (my-deepcontrast "#444444")
       (my-hicontrast   "#DEDEDE")
       (my-shadow       "#333333")
       (my-pop          "#00B7FF")
       (my-warning      "#FF6969")
       (my-btw          "#8B4538")
       (my-white        "#FFFFFF")
      )

;;;; Theme Faces
  (custom-theme-set-faces
    'melancholy

    ;;;; default
    ;; ========================================
    `(default ((t (:inherit nil :stipple nil :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 99 :width normal :foundry "unknown" :family "Ubuntu Mono " :background ,my-shadow :foreground ,my-hicontrast ))))

    ;;;; window and frame settings
    ;; ========================================
    `(fringe ((t (:inherit default))))
    `(header-line ((t (:foreground ,my-hicontrast :background ,my-shadow))))
    `(vertical-border ((t (:foreground ,my-contrast))))
    `(scroll-bar ((t (:background ,my-visited :foreground ,my-shadow))))
    `(hl-line ((t (:background ,my-contrast))))

    ;; line numbers
    ;; ========================================
    `(linum ((t (:foreground ,my-deepcontrast))))
    `(line-number ((t (:foreground ,my-deepcontrast))))
    `(line-number-current-line ((t (:foreground ,my-highlight))))

    ;; base settings
    ;; ========================================
    `(cursor ((t (:background ,my-hicontrast))))
    `(region ((t (:background ,my-deepcontrast))))
    `(query-replace ((t (:inherit isearch))))
    `(match ((t (:background ,my-pop))))
    `(highlight ((t (:background ,my-active :foreground ,my-hicontrast ))))
    `(lazy-highlight ((t (:foreground ,my-shadow :background ,my-highlight))))
    `(fixed-pitch ((t (:family "Ubuntu Mono"))))
    `(variable-pitch ((t (normal :family "Ubuntu" :weight normal :height 99))))
    `(bold ((t (:weight bold))))
    `(italic ((t (:slant italic))))
    `(bold-italic ((t (:weight bold :slant italic))))
    `(shadow ((t (:background ,my-shadow))))
    `(button ((t (:underline (:color foreground-color :style line) :foreground ,my-active))))
    `(link ((t (:foreground ,my-active :underline t :weight bold))))
    `(link-visited ((t ( :foreground ,my-visited))))
    `(secondary-selection ((t (:background ,my-deepcontrast))))
    `(font-lock-builtin-face ((t (:foreground ,my-highlight))))
    `(font-lock-comment-delimiter-face ((t (:foreground ,my-visited))))
    `(font-lock-comment-face ((t (:foreground ,my-visited))))
    `(font-lock-constant-face ((t (:foreground "#DFAF8F"))))
    `(font-lock-doc-face ((t (:foreground ,my-info))))
    `(font-lock-function-name-face ((t (:foreground ,my-pop))))
    `(font-lock-keyword-face ((t (:foreground ,my-active :weight bold))))
    `(font-lock-negation-char-face ((t (:foreground "#F37DEE"))))
    `(font-lock-preprocessor-face ((t (:foreground ,my-active))))
    `(font-lock-regexp-grouping-backslash ((t (:foreground ,my-btw  ))))
    `(font-lock-regexp-grouping-construct ((t (:foreground ,my-btw  ))))
    `(font-lock-string-face ((t (:foreground "#F37DEE" :slant italic :weight extra-light))))
    `(font-lock-type-face ((t (:foreground ,my-pop))))
    `(font-lock-variable-name-face ((t (:foreground ,my-highlight))))
    `(font-lock-warning-face ((t (:foreground ,my-warning))))
    `(tooltip ((t (:foreground ,my-shadow :background "#EEE8AA")) (t (:inherit (variable-pitch)))))
    `(trailing-whitespace ((t (:background ,my-warning))))

    ;; parens / smart-parens
    ;; ========================================
    `(show-paren-match ((t (:background ,my-shadow :foreground ,my-pop :weight bold))))
    `(show-paren-mismatch ((t (:background ,my-warning :weight bold))))
    `(sp-show-pair-match-face ((t (:background ,my-shadow :weight bold))))
    `(sp-show-pair-mismatch-face ((t (:background ,my-warning :weight bold))))
    `(sp-pair-overlay-face ((t (:background ,my-contrast))))

    ;; info/errors
    ;; ========================================
    `(success ((t (:foreground ,my-highlight))))
    `(warning ((t (:foreground ,my-info))))
    `(error ((t (:foreground ,my-warning :weight bold))))
    `(next-error ((t (:inherit (region)))))

    ;; calendar
    ;; ========================================
    `(calendar-today ((t (:foreground ,my-highlight :weight bold))))
    `(calendar-weekday-header ((t (:foreground ,my-info))))
    `(calendar-weekend-header ((t (:foreground ,my-contrast))))
    `(calendar-holiday-marker ((t (:foreground ,my-contrast))))

    ;; dired
    ;; ========================================
    `(dired-header ((t (:foreground ,my-pop :background ,my-visited))))

    ;; flycheck
    `(flycheck-error ((t :underline (:colour ,my-active :style wave ))))

    ;; helm
    ;; ========================================
    `(helm-buffer-directory ((t (:foreground ,my-shadow :background ,my-hicontrast))))
    `(helm-grep-match ((t (:foreground ,my-highlight))))
    `(helm-header ((t ( :foreground ,my-white))))
    `(helm-source-header ((t (:foreground ,my-contrast :family "Ubuntu Condensed" :height 125 :weight bold :underline t) )))
    `(helm-selection ((t (:background ,my-pop :foreground "#161A1F"))))
    `(helm-separator ((t (:background ,my-deepcontrast))))

    `(isearch ((t (:background ,my-highlight :foreground ,my-shadow))))
    `(isearch-fail ((t (:background ,my-pop))))

    ;; magit
    `(magit-section-highlight ((t (:background ,my-deepcontrast))))

    ;; minibuffer
    ;; ========================================
    `(minibuffer-prompt ((t (:foreground ,my-pop :weight bold))))

    ;; org-mode
    ;; ========================================
    `(org-agenda-day-view ((t  :foreground ,my-visited :weight bold )))
    `(org-agenda-date ((t :foreground ,my-contrast )))
    `(org-agenda-date-today ((t (:foreground ,my-highlight :weight extra-bold))))
    `(org-agenda-date-weekend ((t (:foreground ,my-deepcontrast ))))
    `(org-agenda-done ((t (:foreground ,my-contrast :strike-through t))))
    `(org-block-begin-line ((t (:background ,my-contrast :foreground ,my-shadow))))
    `(org-block ((t (:background ,my-deepcontrast :foreground ,my-pop :box nil))))
    `(org-block-end-line ((t (:background ,my-contrast :foreground ,my-shadow))))
    `(org-date ((t (:foreground ,my-visited))))
    `(org-document-info ((t (:foreground ,my-pop :height 1.25 ))))
    `(org-document-title ((t (:foreground ,my-info :height 1.35 :weight extra-bold ))))
    `(org-done ((t (:foreground ,my-highlight :strike-through t))))
    `(org-headline-done ((t (:foreground ,my-contrast :strike-through t))))
    `(org-level-1 ((t  :height 1.125 :weight bold)))
    `(org-level-2 ((t  :foreground ,my-active )))
    `(org-level-3 ((t  :foreground ,my-info )))
    `(org-level-4 ((t  :foreground ,my-pop )))
    `(org-level-5 ((t  :foreground ,my-highlight )))
    `(org-level-6 ((t  :foreground ,my-contrast )))
    `(org-level-7 ((t  :foreground ,my-hicontrast )))
    `(org-link ((t (:foreground ,my-active :underline t ))))
    `(org-table ((t :family "Ubuntu Mono")))

    ;; Speedbar
    ;; =======================================
    `(speedbar-directory-face ((t :family "Ubuntu Mono" :foreground ,my-contrast t)))
    `(speedbar-file-face ((t :family "Ubuntu Mono" :foreground ,my-contrast )))
    `(speedbar-selected-face ((t  :foreground ,my-active :weight extra-bold )))
    `(speedbar-highlight-face ((t :foreground ,my-pop )))
    `(speedbar- ((t :foreground ,my-active )))
    `(speedbar-button-face ((t :foreground ,my-highlight )))



;; The End
  ;; =========================================

    ) ;; custom-theme-set-faces ends here
) ;; let ends here


;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
    (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'melancholy)
;;; melancholy-theme.el ends here
