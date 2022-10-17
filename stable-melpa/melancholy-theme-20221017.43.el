;;; melancholy-theme.el --- A dark theme that's pretty sad -*- lexical-binding: t; -

;; Copyright (C) 2022 Design & Web Limited

;; Author: @baaash <bleat@baaa.sh>
;; Maintainer: @baaash <bleat@baaa.sh>
;; Created: 30 August 2022

;; Version: 1.0.7
;; Package-Version: 20221017.43
;; Package-Commit: 42b89124dd400d81b81d871d853ed8f11abfe01c
;; SPDX-License-Identifier:  GPL-3.0
;; Package-requires: ((emacs "27.1"))

;; Keywords: faces, frames
;; URL: https://gitlab.com/baaash/melancholy-theme


;;; Commentary:
;; ========================================
;; A dark theme thats pretty sad really.  > Emacs 27.1
;;
;; Ensure the following fonts are installed before use:
;;
;;    - Impact_Label (https://www.fontsquirrel.com/fonts/download/impact-label)
;;    - texlive-fonts-extra
;;    - texlive-sourcecodepro.
;;    - fonts-purisa || thai-scalable-purisa-fonts
;;    - fonts-dancingscript
;;
;; ========================================


;;; Code:
;; ========================================

(deftheme melancholy
  "It's a dark theme thats pretty sad really." )

(let
    (
     (font-heading "ImpactLabel")
     (font-cursive "Dancingscript" )
     (font-default   "Purisa" )
     (font-mono "SourceCodePro" )
     (font-sans "OpenSansCondensed" )
     (my-fluff              "#FCDEEA" )
     (my-active             "#F92672" )
     (my-visited            "#999999" )
     (my-info               "#FFB728" )
     (my-highlight          "#96BF33" )
     (my-contrast           "#666666" )
     (my-deepcontrast       "#444444" )
     (my-hicontrast         "#DEDEDE" )
     (my-shadow             "#333333" )
     (my-pop                "#00B7FF" )
     (my-warning            "#FF6969" )
     (my-white              "#FFFFFF" ))

;; Theme Faces
  (custom-theme-set-faces
    'melancholy

    ;; default
    ;; ========================================

    `(default ((t (
                   :family ,font-default
                   :width normal
                   :weight regular
                   :slant normal
                   :foreground ,my-hicontrast
                   :background ,my-shadow
                   :underline nil
                   :overline nil
                   :strike-through nil
                   :box nil
                   :inverse-video nil
                   :stipple nil
                   :inherit nil ))))

    ;; window and frame settings
    ;; ========================================
    `(fringe ((t (:inherit default ))))
    `(header-line ((t (:foreground ,my-hicontrast :background ,my-shadow ))))
    `(hl-line ((t (:background ,my-contrast ))))
    `(menu-bar ((t (:foreground ,my-deepcontrast :background ,my-shadow ))))
    `(scroll-bar ((t (:foreground ,my-shadow :background ,my-visited ))))
    `(vertical-border ((t (:foreground ,my-contrast ))))

    ;; line numbers
    ;; ========================================
    `(linum ((t (:foreground ,my-deepcontrast ))))
    `(line-number ((t (:foreground ,my-deepcontrast ))))
    `(line-number-current-line ((t (:foreground ,my-highlight ))))

    ;; base settings
    ;; ========================================
    `(cursor ((t (:background ,my-hicontrast ))))
    `(region ((t (:background ,my-info :foreground ,my-shadow ))))
    `(query-replace ((t (:inherit isearch ))))
    `(match ((t (:background ,my-pop ))))
    `(highlight ((t (:foreground ,my-pop :background ,my-contrast ))))
    `(lazy-highlight ((t (:foreground ,my-shadow :background ,my-highlight ))))
    `(fixed-pitch ((t (:family ,font-mono ))))
    `(variable-pitch ((t (:family ,font-sans :height 99 :weight normal ))))
    `(bold ((t (:weight bold ))))
    `(italic ((t (:slant italic ))))
    `(bold-italic ((t (:weight bold :slant italic ))))
    `(shadow ((t (:background ,my-shadow ))))
    `(button ((t (:foreground ,my-active :underline (:color foreground-color :style line) ))))
    `(link ((t (:foreground ,my-active :underline t :weight bold ))))
    `(link-visited ((t ( :foreground ,my-visited ))))
    `(secondary-selection ((t (:background ,my-fluff ))))
    `(font-lock-builtin-face ((t (:foreground ,my-highlight ))))
    `(font-lock-comment-delimiter-face ((t (:foreground ,my-visited ))))
    `(font-lock-comment-face ((t (:foreground ,my-visited ))))
    `(font-lock-constant-face ((t (:foreground ,my-info ))))
    `(font-lock-doc-face ((t (:foreground ,my-info ))))
    `(font-lock-function-name-face ((t (:foreground ,my-pop ))))
    `(font-lock-keyword-face ((t (:family ,font-sans :height 1.4 :foreground ,my-active ))))
    `(font-lock-negation-char-face ((t (:foreground ,my-active ))))
    `(font-lock-preprocessor-face ((t (:foreground ,my-active ))))
    `(font-lock-regexp-grouping-backslash ((t (:foreground ,my-pop  ))))
    `(font-lock-regexp-grouping-construct ((t (:foreground ,my-pop  ))))
    `(font-lock-string-face ((t (:foreground ,my-visited :weight extra-light :slant italic ))))
    `(font-lock-type-face ((t (:foreground ,my-pop ))))
    `(font-lock-variable-name-face ((t (:foreground ,my-highlight ))))
    `(font-lock-warning-face ((t (:foreground ,my-warning ))))
    `(tooltip ((t (:foreground ,my-contrast :background ,my-info ))))
    `(trailing-whitespace ((t (:background ,my-warning ))))

    ;; parens / smart-parens
    ;; ========================================
    `(show-paren-match ((t (:background ,my-shadow :weight extra-bold :foreground ,my-pop  ))))
    `(show-paren-mismatch ((t (:background ,my-warning :weight extra-bold ))))
    `(sp-show-pair-match-face ((t (:background ,my-active :height 1.25 :weight extra-bold ))))
    `(sp-show-pair-mismatch-face ((t (:background ,my-warning :weight extra-bold ))))
    `(sp-pair-overlay-face ((t (:background ,my-contrast ))))

    ;; info/errors
    ;; ========================================
    `(success ((t (:foreground ,my-highlight ))))
    `(warning ((t (:foreground ,my-info ))))
    `(error ((t (:foreground ,my-warning :weight bold ))))
    `(next-error ((t (:inherit (region) ))))


    ;; all the icons
    ;; ========================================
    `(all-the-icons-dcyan ((t (:foreground ,my-pop ))))
    `(all-the-icons-dgreen ((t (:foreground ,my-highlight ))))
    `(all-the-icons-dpink ((t (:foreground ,my-active ))))

    ;; calendar
    ;; ========================================
    `(calendar-today ((t (:weight bold :foreground ,my-highlight ))))
    `(calendar-weekday-header ((t (:foreground ,my-info ))))
    `(calendar-weekend-header ((t (:foreground ,my-contrast ))))
    `(calendar-holiday-marker ((t (:foreground ,my-contrast ))))

    ;; dired
    ;; ========================================
    `(dired-faces ((t (:family ,font-mono ))))
    `(dired-header ((t (:family ,font-mono :foreground ,my-pop ))))
    `(dired-directory-face ((t (:family ,font-mono ))))

    ;; flycheck
    ;; ========================================
    `(flycheck-error ((t  (:colour ,my-active :style wave ))))

    ;; gnus
    ;; ========================================
    `(gnus-group-mail-3 ((t (:foreground ,my-highlight ))))
    `(gnus-group-mail-3-empty ((t (:foreground ,my-contrast ))))
    `(gnus-header-name ((t (:foreground ,my-active ))))
    `(gnus-header-from ((t (:foreground ,my-hicontrast ))))
    `(gnus-header-subject ((t (:foreground ,my-highlight ))))
    `(gnus-header-content ((t (:foreground ,my-visited ))))
    `(gnus-summary-normal-unread ((t (:foreground ,my-highlight ))))
    `(gnus-summary-normal-read ((t (:foreground ,my-highlight ))))
    `(gnus-summary-selected ((t (:foreground ,my-pop ))))

    ;; helm
    ;; ========================================
    `(helm-buffer ((t (:family ,font-mono ))))
    `(helm-buffers ((t (:family ,font-mono ))))
    `(helm-faces ((t (:family ,font-mono ))))

    `(helm-buffer-archive ((t (:foreground ,my-deepcontrast ))))
    `(helm-buffer-directory ((t (:foreground ,my-shadow :background ,my-hicontrast ))))
    `(helm-buffer-file ((t ( :foreground ,my-pop ))))
    `(helm-buffer-modified ((t (:foreground ,my-visited ))))
    `(helm-buffer-not-saved ((t (:foreground ,my-warning ))))
    `(helm-buffer-process ((t (:foreground ,my-contrast ))))
    `(helm-buffer-size ((t (:foreground ,my-info ))))
    `(helm-candidate-number ((t (:foreground ,my-shadow :background ,my-info ))))
    `(helm-candidate-number-suspended ((t (:foreground ,my-info :background , my-deepcontrast ))))
    `(helm-grep-match ((t (:foreground ,my-highlight ))))
    `(helm-header ((t ( :foreground ,my-white ))))
    `(helm-header-line-left-margin ((t (:background ,my-info :foreground ,my-shadow ))))
    `(helm-match ((t (:foreground ,my-visited :weight bold ))))
    `(helm-minibuffer-prompt ((t (:foreground ,my-pop)qq)))
    `(helm-no-file-buffer-modified ((t (:foreground ,my-info ))))
    `(helm-prefarg ((t (:foreground ,my-visited ))))
    `(helm-selection ((t (:foreground ,my-deepcontrast :background ,my-info ))))
    `(helm-separator ((t (:background ,my-deepcontrast ))))
    `(helm-source-header ((t (:family ,font-heading :height 1.9 :foreground ,my-contrast :underline t ))))
    `(helm-visible-mark ((t (:background ,my-visited ))))

    ;; heredocs
    ;;=========================================
    `(sh-heredoc ((t (:foreground ,my-pop ))))

    ;; isearch
    ;; ========================================
    `(isearch ((t (:foreground ,my-shadow :background ,my-highlight ))))
    `(isearch-fail ((t (:background ,my-pop ))))

    ;; magit
    ;; ========================================
    `(magit-section-highlight ((t (:foreground ,my-pop :background ,my-deepcontrast ))))
    `(magit-diff-added ((t (:foreground ,my-highlight :background ,my-deepcontrast ))))
    `(magit-diff-added-highlight ((t (:foreground ,my-highlight :background ,my-deepcontrast))))
    `(magit-diff-removed ((t (:foreground ,my-warning :background ,my-deepcontrast))))
    `(magit-diff-removed-highlight ((t (:foreground ,my-warning :background ,my-deepcontrast))))
    `(magit-diff-hunk-heading-highlight ((t (:foreground ,my-pop :background ,my-deepcontrast ))))

        ;; man
    ;; ========================================
    `(man-mode-hook ((t (:family ,font-mono))))
    `(man-follow ((t (:foreground ,my-active ))))
    `(man-overstrike ((t (:foreground ,my-pop ))))

    ;; minibuffer
    ;; ========================================
    `(minibuffer-prompt ((t (:weight bold :foreground ,my-pop ))))

    ;; org-mode
    ;; ========================================
    `(org-agenda-day-view ((t (:weight bold :foreground ,my-visited ))))
    `(org-agenda-date ((t (:foreground ,my-contrast ))))
    `(org-agenda-date-today ((t ( :background ,my-highlight :foreground ,my-deepcontrast :weight bold ))))
    `(org-agenda-date-weekend ((t (:foreground ,my-deepcontrast ))))
    `(org-agenda-done ((t (:slant italic :foreground ,my-contrast :strike-through t ))))
    `(org-agenda-structure ((t (:slant italic :foreground ,my-pop ))))
    `(org-imminent-deadline ((t (:foreground ,my-warning))))
    `(org-deadline-past-days ((t (:foreground ,my-warning ))))
    `(org-deadline-warning-days ((t (:foreground ,my-warning ))))
    `(org-upcoming-deadline ((t (:foreground ,my-visited :slant italic ))))
    `(org-priority ((t (:family ,font-mono :foreground ,my-visited :slant normal  ))))
    `(org-block-begin-line ((t (:foreground ,my-shadow :background ,my-contrast ))))
    `(org-block ((t (:foreground ,my-pop :background ,my-deepcontrast ))))
    `(org-block-end-line ((t (:foreground ,my-shadow :background ,my-contrast ))))
    `(org-date ((t (:foreground ,my-visited ))))
    `(org-document-info ((t :(:height 1.25 foreground ,my-visited ))))
    `(org-document-info-keyword ((t (:foreground ,my-contrast ))))
    `(org-document-title ((t (:family ,font-heading :foreground ,my-info :height 4.20 :weight extra-bold ))))
    `(org-done ((t (:foreground ,my-contrast :strike-through t ))))
    `(org-headline-done ((t (:foreground ,my-contrast :strike-through t ))))
    `(org-level-1 ((t :family ,font-sans :height 2.6 :weight bold )))
    `(org-level-2 ((t :family ,font-sans :foreground ,my-contrast :height 2.4 :weight bold :slant italic )))
    `(org-level-3 ((t :family ,font-sans :foreground ,my-active :height 1.8 :weight regular )))
    `(org-level-4 ((t :family ,font-sans :foreground ,my-contrast :height 1.6 :weight regular )))
    `(org-level-5 ((t :family ,font-sans :height 1.4  :weight regular )))
    `(org-level-6 ((t :family ,font-sans :height 1.2  :weight regular )))
    `(org-level-7 ((t :family ,font-sans :foreground ,my-contrast :height 1.1 :weight regular )))
   `(org-link ((t :foreground ,my-active :underline t )))
   `(org-scheduled ((t :foreground ,my-info )))
    `(org-scheduled-today ((t :foreground ,my-highlight )))
    `(org-src-block-faces ((t :family ,font-mono )))
    `(org-special-keyword ((t :family ,font-default :foreground ,my-contrast )))
    `(org-table ((t :family ,font-mono :foreground ,my-contrast )))
    `(org-tag ((t (:foreground ,my-active ))))
    `(org-todo ((t (:foreground ,my-info ))))

    ;; Speedbar
    ;; =======================================
    `(speedbar-directory-face ((t :family ,font-mono :foreground ,my-contrast t )))
    `(speedbar-file-face ((t (:family ,font-mono :foreground ,my-contrast ))))
    `(speedbar-selected-face ((t (:weight extra-bold :foreground ,my-highlight ))))
    `(speedbar-highlight-face ((t (:foreground ,my-active))))
    `(speedbar- ((t (:foreground ,my-active ))))
    `(speedbar-button-face ((t (:foreground ,my-pop ))))

    ;; Terminal
    ;; =========================================
    `(term-color-black ((t (:family ,font-mono :foreground ,my-shadow ))))
    `(term-color-blue ((t (:family ,font-mono :foreground ,my-pop ))))
    `(term-color-green ((t (:family ,font-mono :foreground ,my-highlight ))))
    `(term-color-magenta ((t (:family ,font-mono :foreground ,my-active ))))
    `(term-color-red ((t (::family ,font-mono foreground ,my-warning ))))
    `(term-color-white ((t (:family ,font-mono :foreground ,my-white ))))
    `(term-bold ((t (:foreground ,my-highlight )))))) ;; let ends here

(when load-file-name
  (add-to-list 'custom-theme-load-path
    (file-name-as-directory (file-name-directory load-file-name) )))

(provide-theme 'melancholy)

;;; melancholy-theme.el ends here
