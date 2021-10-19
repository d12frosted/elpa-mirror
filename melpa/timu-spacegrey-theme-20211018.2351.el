;;; timu-spacegrey-theme.el --- Color theme inspired by the Spacegray theme in Sublime Text  -*- lexical-binding:t -*-

;; Copyright (C) 2021 Aimé Bertrand

;; Author: Aimé Bertrand <aime.bertrand@macowners.club>
;; Maintainer: Aimé Bertrand <aime.bertrand@macowners.club>
;; Created: 06 Jun 2021
;; Keywords: faces themes
;; Package-Version: 20211018.2351
;; Package-Commit: 653923cd419616dc1486abb919581a99e6d32539
;; Version: 1.6
;; Package-Requires: ((emacs "25.1"))
;; Homepage: https://gitlab.com/aimebertrand/timu-spacegrey-theme

;; This file is not part of GNU Emacs.

;; The MIT License (MIT)
;;
;; Copyright (C) 2021 Aimé Bertrand
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
;; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
;; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:
;; Used Doom themes for boilerplate for modes & packages.
;;
;; I. Installation
;;   A. Manual installation
;;     1. Download the `timu-spacegrey-theme.el' file and add it to your `custom-load-path'.
;;     2. In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (load-theme 'timu-spacegrey t)
;;
;;   B. From Melpa
;;     1. M-x package-instal <RET> timu-spacegrey-theme.el <RET>.
;;     2. In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (load-theme 'timu-spacegrey t)
;;
;;   C. With use-package
;;     In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (use-package timu-spacegrey-theme
;;         :ensure t
;;         :config
;;         (load-theme 'timu-spacegrey t))
;;
;; II. Configuration
;;   There is a light version now included as well.
;;   By default the theme is `dark', to setup the `light' flavour
;;   add the following to your `~/.emacs.d/init.el' or `~/.emacs':
;;     (setq timu-spacegrey-flavour "light")

;;; Code:

(deftheme timu-spacegrey
  "Custom theme inspired by the spacegray theme in Sublime Text.
Sourced other themes to get information about font faces for packages.")

(defvar timu-spacegrey-flavour "dark"
  "Variable to control the variant of the theme.
Possinle values: `dark' or `light'.")

;;; DARK FLAVOUR
(when (equal timu-spacegrey-flavour "dark")
  (let ((class '((class color) (min-colors 89)))
        (bg "#2b303b")
        (bg-org "#282d37")
        (bg-other "#232830")
        (spacegrey0 "#1b2229")
        (spacegrey1 "#1c1f24")
        (spacegrey2 "#202328")
        (spacegrey3 "#2f3237")
        (spacegrey4 "#4f5b66")
        (spacegrey5 "#65737e")
        (spacegrey6 "#73797e")
        (spacegrey7 "#9ca0a4")
        (spacegrey8 "#dfdfdf")
        (fg "#c0c5ce")
        (fg-other "#c0c5ce")

        (grey "#4f5b66")
        (red "#bf616a")
        (orange "#d08770")
        (green "#a3be8c")
        (blue "#8fa1b3")
        (magenta "#b48ead")
        (teal "#4db5bd")
        (yellow "#ecbe7b")
        (darkblue "#2257a0")
        (purple "#c678dd")
        (cyan "#46d9ff")
        (darkcyan "#5699af"))

    (custom-theme-set-faces
     'timu-spacegrey

;;; Custom faces - dark

;;;; default faces - dark
     `(bold ((,class (:weight bold))))
     `(bold-italic ((,class (:inherit (bold italic)))))
     `(bookmark-face ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
     `(cursor ((,class (:background ,orange))))
     `(default ((,class (:background ,bg :foreground ,fg))))
     `(error ((,class (:foreground ,red))))
     `(fringe ((,class (:inherit default :foreground ,spacegrey4))))
     `(highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
     `(italic ((,class (:slant  italic))))
     `(lazy-highlight ((,class (:background ,darkblue  :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(link ((,class (:foreground ,orange :underline t :weight bold))))
     `(match ((,class (:foreground ,green :background ,spacegrey0 :weight bold))))
     `(minibuffer-prompt ((,class (:foreground ,orange))))
     `(nobreak-space ((,class (:inherit default :underline nil))))
     `(region ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
     `(secondary-selection ((,class (:background ,grey :extend t))))
     `(shadow ((,class (:foreground ,spacegrey5))))
     `(success ((,class (:foreground ,green))))
     `(tooltip ((,class (:background ,bg-other :foreground ,fg))))
     `(trailing-whitespace ((,class (:background ,red))))
     `(vertical-border ((,class (:background ,spacegrey4 :foreground ,spacegrey4))))
     `(warning ((,class (:foreground ,yellow))))

;;;; font-lock - dark
     `(font-lock-builtin-face ((,class (:foreground ,orange))))
     `(font-lock-comment-delimiter-face ((,class (:inherit font-lock-comment-face))))
     `(font-lock-comment-face ((,class (:foreground ,spacegrey5))))
     `(font-lock-constant-face ((,class (:foreground ,orange))))
     `(font-lock-doc-face ((,class (:inherit font-lock-comment-face :foreground ,spacegrey5))))
     `(font-lock-function-name-face ((,class (:foreground ,blue))))
     `(font-lock-keyword-face ((,class (:foreground ,magenta))))
     `(font-lock-negation-char-face ((,class (:inherit bold :foreground ,fg))))
     `(font-lock-preprocessor-char-face ((,class (:inherit bold :foreground ,fg))))
     `(font-lock-preprocessor-face ((,class (:inherit bold :foreground ,fg))))
     `(font-lock-regexp-grouping-backslash ((,class (:inherit bold :foreground ,fg))))
     `(font-lock-regexp-grouping-construct ((,class (:inherit bold :foreground ,fg))))
     `(font-lock-string-face ((,class (:foreground ,green))))
     `(font-lock-type-face ((,class (:foreground ,yellow))))
     `(font-lock-variable-name-face ((,class (:foreground ,red))))
     `(font-lock-warning-face ((,class (:inherit warning))))

;;;; ace-window - dark
     `(aw-leading-char-face ((,class (:foreground ,orange :height 500 :weight bold))))
     `(aw-background-face ((,class (:foreground ,spacegrey5))))

;;;; agda-mode - dark
     `(org-agenda-clocking ((,class (:background ,blue))))
     `(org-agenda-date ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-date-today ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-date-weekend ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-dimmed-todo-face ((,class (:foreground ,spacegrey5))))
     `(org-agenda-done ((,class (:inherit org-done))))
     `(org-agenda-structure ((,class (:foreground ,fg :weight ultra-bold))))
     `(org-scheduled ((,class (:foreground ,fg))))
     `(org-scheduled-previously ((,class (:foreground ,spacegrey8))))
     `(org-scheduled-today ((,class (:foreground ,spacegrey7))))
     `(org-sexp-date ((,class (:foreground ,fg))))
     `(org-time-grid ((,class (:foreground ,spacegrey5))))
     `(org-upcoming-deadline ((,class (:foreground ,fg))))
     `(org-upcoming-distant-deadline ((,class (:foreground ,fg))))

;;;; alert - dark
     `(alert-high-face ((,class (:inherit bold :foreground ,yellow))))
     `(alert-low-face ((,class (:foreground ,grey))))
     `(alert-moderate-face ((,class (:inherit bold :foreground ,fg-other))))
     `(alert-trivial-face ((,class (:foreground ,spacegrey5))))
     `(alert-urgent-face ((,class (:inherit bold :foreground ,red))))

;;;; all-the-icons - dark
     `(all-the-icons-blue ((,class (:foreground ,blue))))
     `(all-the-icons-blue-alt ((,class (:foreground ,teal))))
     `(all-the-icons-cyan ((,class (:foreground ,cyan))))
     `(all-the-icons-cyan-alt ((,class (:foreground ,cyan))))
     `(all-the-icons-dblue ((,class (:foreground ,darkblue))))
     `(all-the-icons-dcyan ((,class (:foreground ,darkcyan))))
     `(all-the-icons-dgreen ((,class (:foreground ,green))))
     `(all-the-icons-dmagenta ((,class (:foreground ,red))))
     `(all-the-icons-dmaroon ((,class (:foreground ,purple))))
     `(all-the-icons-dorange ((,class (:foreground ,orange))))
     `(all-the-icons-dpurple ((,class (:foreground ,magenta))))
     `(all-the-icons-dred ((,class (:foreground ,red))))
     `(all-the-icons-dsilver ((,class (:foreground ,grey))))
     `(all-the-icons-dyellow ((,class (:foreground ,yellow))))
     `(all-the-icons-green ((,class (:foreground ,green))))
     `(all-the-icons-lblue ((,class (:foreground ,blue))))
     `(all-the-icons-lcyan ((,class (:foreground ,cyan))))
     `(all-the-icons-lgreen ((,class (:foreground ,green))))
     `(all-the-icons-lmagenta ((,class (:foreground ,red))))
     `(all-the-icons-lmaroon ((,class (:foreground ,purple))))
     `(all-the-icons-lorange ((,class (:foreground ,orange))))
     `(all-the-icons-lpurple ((,class (:foreground ,magenta))))
     `(all-the-icons-lred ((,class (:foreground ,red))))
     `(all-the-icons-lsilver ((,class (:foreground ,grey))))
     `(all-the-icons-lyellow ((,class (:foreground ,yellow))))
     `(all-the-icons-magenta ((,class (:foreground ,red))))
     `(all-the-icons-maroon ((,class (:foreground ,purple))))
     `(all-the-icons-orange ((,class (:foreground ,orange))))
     `(all-the-icons-purple ((,class (:foreground ,magenta))))
     `(all-the-icons-purple-alt ((,class (:foreground ,magenta))))
     `(all-the-icons-red ((,class (:foreground ,red))))
     `(all-the-icons-red-alt ((,class (:foreground ,red))))
     `(all-the-icons-silver ((,class (:foreground ,grey))))
     `(all-the-icons-yellow ((,class (:foreground ,yellow))))

;;;; all-the-icons-dired - dark
     `(all-the-icons-dired-dir-face ((,class (:foreground ,fg-other))))

;;;; all-the-icons-ivy-rich - dark
     `(all-the-icons-ivy-rich-doc-face ((,class (:foreground ,blue))))
     `(all-the-icons-ivy-rich-path-face ((,class (:foreground ,blue))))
     `(all-the-icons-ivy-rich-size-face ((,class (:foreground ,blue))))
     `(all-the-icons-ivy-rich-time-face ((,class (:foreground ,blue))))

;;;; annotate - dark
     `(annotate-annotation ((,class (:background ,orange :foreground ,spacegrey5))))
     `(annotate-annotation-secondary ((,class (:background ,green :foreground ,spacegrey5))))
     `(annotate-highlight ((,class (:background ,orange :underline ,orange))))
     `(annotate-highlight-secondary ((,class (:background ,green :underline ,green))))

;;;; anzu - dark
     `(anzu-replace-highlight ((,class (:background ,spacegrey0 :foreground ,red :weight bold :strike-through t))))
     `(anzu-replace-to ((,class (:background ,spacegrey0 :foreground ,green :weight bold))))

;;;; auctex - dark
     `(TeX-error-description-error ((,class (:inherit error :weight bold))))
     `(TeX-error-description-tex-said ((,class (:inherit success :weight bold))))
     `(TeX-error-description-warning ((,class (:inherit warning :weight bold))))
     `(font-latex-bold-face ((,class (:inherit bold))))
     `(font-latex-italic-face ((,class (:inherit italic))))
     `(font-latex-math-face ((,class (:foreground ,blue))))
     `(font-latex-script-char-face ((,class (:foreground ,darkblue))))
     `(font-latex-sectioning-0-face ((,class (:foreground ,blue :weight ultra-bold))))
     `(font-latex-sectioning-1-face ((,class (:foreground ,purple :weight semi-bold))))
     `(font-latex-sectioning-2-face ((,class (:foreground ,magenta :weight semi-bold))))
     `(font-latex-sectioning-3-face ((,class (:foreground ,blue :weight semi-bold))))
     `(font-latex-sectioning-4-face ((,class (:foreground ,purple :weight semi-bold))))
     `(font-latex-sectioning-5-face ((,class (:foreground ,magenta :weight semi-bold))))
     `(font-latex-string-face ((,class (:inherit font-lock-string-face))))
     `(font-latex-verbatim-face ((,class (:inherit fixed-pitch :foreground ,magenta :slant italic))))
     `(font-latex-warning-face ((,class (:inherit font-lock-warning-face))))

;;;; avy - dark
     `(avy-background-face ((,class (:foreground ,spacegrey5))))
     `(avy-lead-face ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(avy-lead-face-0 ((,class (:inherit avy-lead-face :background ,orange))))
     `(avy-lead-face-1 ((,class (:inherit avy-lead-face :background ,orange))))
     `(avy-lead-face-2 ((,class (:inherit avy-lead-face :background ,orange))))

;;;; bookmark+ - dark
     `(bmkp-*-mark ((,class (:foreground ,bg :background ,yellow))))
     `(bmkp->-mark ((,class (:foreground ,yellow))))
     `(bmkp-D-mark ((,class (:foreground ,bg :background ,red))))
     `(bmkp-X-mark ((,class (:foreground ,red))))
     `(bmkp-a-mark ((,class (:background ,red))))
     `(bmkp-bad-bookmark ((,class (:foreground ,bg :background ,yellow))))
     `(bmkp-bookmark-file ((,class (:foreground ,magenta :background ,bg-other))))
     `(bmkp-bookmark-list ((,class (:background ,bg-other))))
     `(bmkp-buffer ((,class (:foreground ,blue))))
     `(bmkp-desktop ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-file-handler ((,class (:background ,red))))
     `(bmkp-function ((,class (:foreground ,green))))
     `(bmkp-gnus ((,class (:foreground ,orange))))
     `(bmkp-heading ((,class (:foreground ,yellow))))
     `(bmkp-info ((,class (:foreground ,cyan))))
     `(bmkp-light-autonamed ((,class (:foreground ,bg-other :background ,cyan))))
     `(bmkp-light-autonamed-region ((,class (:foreground ,bg-other :background ,red))))
     `(bmkp-light-fringe-autonamed ((,class (:foreground ,bg-other :background ,magenta))))
     `(bmkp-light-fringe-non-autonamed ((,class (:foreground ,bg-other :background ,green))))
     `(bmkp-light-mark ((,class (:foreground ,bg :background ,cyan))))
     `(bmkp-light-non-autonamed ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-light-non-autonamed-region ((,class (:foreground ,bg :background ,red))))
     `(bmkp-local-directory ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-local-file-with-region ((,class (:foreground ,yellow))))
     `(bmkp-local-file-without-region ((,class (:foreground ,spacegrey5))))
     `(bmkp-man ((,class (:foreground ,magenta))))
     `(bmkp-no-jump ((,class (:foreground ,spacegrey5))))
     `(bmkp-no-local ((,class (:foreground ,yellow))))
     `(bmkp-non-file ((,class (:foreground ,green))))
     `(bmkp-remote-file ((,class (:foreground ,orange))))
     `(bmkp-sequence ((,class (:foreground ,blue))))
     `(bmkp-su-or-sudo ((,class (:foreground ,red))))
     `(bmkp-t-mark ((,class (:foreground ,magenta))))
     `(bmkp-url ((,class (:foreground ,blue :underline t))))
     `(bmkp-variable-list ((,class (:foreground ,green))))

;;;; calfw - dark
     `(cfw:face-annotation ((,class (:foreground ,magenta))))
     `(cfw:face-day-title ((,class (:foreground ,fg :weight bold))))
     `(cfw:face-default-content ((,class (:foreground ,fg))))
     `(cfw:face-default-day ((,class (:weight bold))))
     `(cfw:face-disable ((,class (:foreground ,grey))))
     `(cfw:face-grid ((,class (:foreground ,bg))))
     `(cfw:face-header ((,class (:foreground ,blue :weight bold))))
     `(cfw:face-holiday ((,class (:foreground nil :background ,bg-other :weight bold))))
     `(cfw:face-periods ((,class (:foreground ,yellow))))
     `(cfw:face-saturday ((,class (:foreground ,red :weight bold))))
     `(cfw:face-select ((,class (:background ,grey))))
     `(cfw:face-sunday ((,class (:foreground ,red :weight bold))))
     `(cfw:face-title ((,class (:foreground ,blue :weight bold :height 2.0 :inherit variable-pitch))))
     `(cfw:face-today ((,class (:foreground nil :background nil :weight bold))))
     `(cfw:face-today-title ((,class (:foreground ,bg :background ,blue :weight bold))))
     `(cfw:face-toolbar ((,class (:foreground nil :background nil))))
     `(cfw:face-toolbar-button-off ((,class (:foreground ,spacegrey6 :weight bold :inherit variable-pitch))))
     `(cfw:face-toolbar-button-on ((,class (:foreground ,blue :weight bold :inherit variable-pitch))))

;;;; centaur-tabs - dark
     `(centaur-tabs-active-bar-face ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-close-mouse-face ((,class (:foreground ,orange))))
     `(centaur-tabs-close-selected ((,class (:inherit centaur-tabs-selected))))
     `(centaur-tabs-close-unselected ((,class (:inherit centaur-tabs-unselected))))
     `(centaur-tabs-default ((,class (:background ,bg-other :foreground ,fg))))
     `(centaur-tabs-modified-marker-selected ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-modified-marker-unselected ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-selected ((,class (:background ,bg :foreground ,fg))))
     `(centaur-tabs-selected-modified ((,class (:background ,bg :foreground ,red))))
     `(centaur-tabs-unselected ((,class (:background ,bg-other :foreground ,grey))))
     `(centaur-tabs-unselected-modified ((,class (:background ,bg-other :foreground ,red))))

;;;; circe - dark
     `(circe-fool ((,class (:foreground ,spacegrey5))))
     `(circe-highlight-nick-face ((,class (:weight bold :foreground ,orange))))
     `(circe-my-message-face ((,class (:weight bold))))
     `(circe-prompt-face ((,class (:weight bold :foreground ,orange))))
     `(circe-server-face ((,class (:foreground ,spacegrey5))))

;;;; company - dark
     `(company-preview ((,class (:foreground ,spacegrey5))))
     `(company-preview-common ((,class (:background ,spacegrey3 :foreground ,orange))))
     `(company-preview-search ((,class (:inherit company-tooltip-search))))
     `(company-scrollbar-bg ((,class (:inherit tooltip))))
     `(company-scrollbar-fg ((,class (:background ,orange))))
     `(company-template-field ((,class (:inherit match))))
     `(company-tooltip ((,class (:inherit tooltip))))
     `(company-tooltip-annotation ((,class (:foreground ,magenta :distant-foreground ,bg))))
     `(company-tooltip-common ((,class (:foreground ,orange :distant-foreground ,spacegrey0 :weight bold))))
     `(company-tooltip-mouse ((,class (:background ,purple :foreground ,bg :distant-foreground ,fg))))
     `(company-tooltip-search ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(company-tooltip-search-selection ((,class (:background ,grey))))
     `(company-tooltip-selection ((,class (:background ,grey :weight bold))))

;;;; company-box - dark
     `(company-box-candidate ((,class (:foreground ,fg))))

;;;; compilation - dark
     `(compilation-column-number ((,class (:inherit font-lock-comment-face))))
     `(compilation-error ((,class (:inherit error :weight bold))))
     `(compilation-info ((,class (:inherit success))))
     `(compilation-line-number ((,class (:foreground ,orange))))
     `(compilation-mode-line-exit ((,class (:inherit compilation-info))))
     `(compilation-mode-line-fail ((,class (:inherit compilation-error))))
     `(compilation-warning ((,class (:inherit warning :slant italic))))

;;;; counsel - dark
     `(counsel-variable-documentation ((,class (:foreground ,blue))))

;;;; cperl - dark
     `(cperl-array-face ((,class (:weight bold :inherit font-lock-variable-name-face))))
     `(cperl-hash-face ((,class (:weight bold :slant italic :inherit font-lock-variable-name-face))))
     `(cperl-nonoverridable-face ((,class (:inherit font-lock-builtin-face))))

;;;; custom - dark
     `(custom-button ((,class (:foreground ,fg :background ,bg-other :box (:line-width 3 :style released-button)))))
     `(custom-button-mouse ((,class (:foreground ,yellow :background ,bg-other :box (:line-width 3 :style released-button)))))
     `(custom-button-pressed ((,class (:foreground ,bg :background ,bg-other :box (:line-width 3 :style pressed-button)))))
     `(custom-button-pressed-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
     `(custom-button-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
     `(custom-changed ((,class (:foreground ,blue :background ,bg))))
     `(custom-comment ((,class (:foreground ,fg :background ,grey))))
     `(custom-comment-tag ((,class (:foreground ,grey))))
     `(custom-documentation ((,class (:foreground ,fg))))
     `(custom-face-tag ((,class (:foreground ,blue :weight bold))))
     `(custom-group-subtitle ((,class (:foreground ,magenta :weight bold))))
     `(custom-group-tag ((,class (:foreground ,magenta :weight bold))))
     `(custom-group-tag-1 ((,class (:foreground ,blue))))
     `(custom-invalid ((,class (:foreground ,red))))
     `(custom-link ((,class (:foreground ,orange :underline t))))
     `(custom-modified ((,class (:foreground ,blue))))
     `(custom-rogue ((,class (:foreground ,blue :box (:line-width 3 :style none)))))
     `(custom-saved ((,class (:foreground ,green :weight bold))))
     `(custom-set ((,class (:foreground ,yellow :background ,bg))))
     `(custom-state ((,class (:foreground ,green))))
     `(custom-themed ((,class (:foreground ,yellow :background ,bg))))
     `(custom-variable-button ((,class (:foreground ,green :underline t))))
     `(custom-variable-obsolete ((,class (:foreground ,grey :background ,bg))))
     `(custom-variable-tag ((,class (:foreground ,darkcyan :underline t :extend nil))))
     `(custom-visibility ((,class (:foreground ,yellow :height 0.8 :underline t))))

;;;; diff-hl - dark
     `(diff-hl-change ((,class (:foreground ,orange :background ,orange))))
     `(diff-hl-delete ((,class (:foreground ,red :background ,red))))
     `(diff-hl-insert ((,class (:foreground ,green :background ,green))))

;;;; dired - dark
     `(dired-directory ((,class (:foreground ,darkcyan))))
     `(dired-flagged ((,class (:foreground ,red))))
     `(dired-header ((,class (:foreground ,orange :weight bold :underline ,darkcyan))))
     `(dired-ignored ((,class (:foreground ,spacegrey5))))
     `(dired-mark ((,class (:foreground ,orange :weight bold))))
     `(dired-marked ((,class (:foreground ,yellow :weight bold))))
     `(dired-perm-write ((,class (:foreground ,red :underline t))))
     `(dired-symlink ((,class (:foreground ,magenta))))
     `(dired-warning ((,class (:foreground ,yellow))))

;;;; dired-async - dark
     `(dired-async-failures ((,class (:foreground ,red))))
     `(dired-async-message ((,class (:foreground ,orange))))
     `(dired-async-mode-message ((,class (:foreground ,orange))))

;;;; dired+ - dark
     `(diredp-compressed-file-suffix ((,class (:foreground ,spacegrey5))))
     `(diredp-date-time ((,class (:foreground ,blue))))
     `(diredp-dir-heading ((,class (:foreground ,blue :weight bold))))
     `(diredp-dir-name ((,class (:foreground ,spacegrey8 :weight bold))))
     `(diredp-dir-priv ((,class (:foreground ,blue :weight bold))))
     `(diredp-exec-priv ((,class (:foreground ,yellow))))
     `(diredp-file-name ((,class (:foreground ,spacegrey8))))
     `(diredp-file-suffix ((,class (:foreground ,magenta))))
     `(diredp-ignored-file-name ((,class (:foreground ,spacegrey5))))
     `(diredp-no-priv ((,class (:foreground ,spacegrey5))))
     `(diredp-number ((,class (:foreground ,purple))))
     `(diredp-rare-priv ((,class (:foreground ,red :weight bold))))
     `(diredp-read-priv ((,class (:foreground ,purple))))
     `(diredp-symlink ((,class (:foreground ,magenta))))
     `(diredp-write-priv ((,class (:foreground ,green))))

;;;; dired-k - dark
     `(dired-k-added ((,class (:foreground ,green :weight bold))))
     `(dired-k-commited ((,class (:foreground ,green :weight bold))))
     `(dired-k-directory ((,class (:foreground ,blue :weight bold))))
     `(dired-k-ignored ((,class (:foreground ,spacegrey5 :weight bold))))
     `(dired-k-modified ((,class (:foreground ,orange :weight bold))))
     `(dired-k-untracked ((,class (:foreground ,teal :weight bold))))

;;;; dired-subtree - dark
     `(dired-subtree-depth-1-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-2-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-3-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-4-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-5-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-6-face ((,class (:background ,bg-other))))

;;;; diredfl - dark
     `(diredfl-autofile-name ((,class (:foreground ,spacegrey4))))
     `(diredfl-compressed-file-name ((,class (:foreground ,orange))))
     `(diredfl-compressed-file-suffix ((,class (:foreground ,yellow))))
     `(diredfl-date-time ((,class (:foreground ,cyan :weight light))))
     `(diredfl-deletion ((,class (:foreground ,red :weight bold))))
     `(diredfl-deletion-file-name ((,class (:foreground ,red))))
     `(diredfl-dir-heading ((,class (:foreground ,blue :weight bold))))
     `(diredfl-dir-name ((,class (:foreground ,darkcyan))))
     `(diredfl-dir-priv ((,class (:foreground ,blue))))
     `(diredfl-exec-priv ((,class (:foreground ,red))))
     `(diredfl-executable-tag ((,class (:foreground ,red))))
     `(diredfl-file-name ((,class (:foreground ,fg))))
     `(diredfl-file-suffix ((,class (:foreground ,teal))))
     `(diredfl-flag-mark ((,class (:foreground ,yellow :background ,yellow :weight bold))))
     `(diredfl-flag-mark-line ((,class (:background ,yellow))))
     `(diredfl-ignored-file-name ((,class (:foreground ,spacegrey5))))
     `(diredfl-link-priv ((,class (:foreground ,magenta))))
     `(diredfl-no-priv ((,class (:foreground ,fg))))
     `(diredfl-number ((,class (:foreground ,orange))))
     `(diredfl-other-priv ((,class (:foreground ,purple))))
     `(diredfl-rare-priv ((,class (:foreground ,fg))))
     `(diredfl-read-priv ((,class (:foreground ,yellow))))
     `(diredfl-symlink ((,class (:foreground ,magenta))))
     `(diredfl-tagged-autofile-name ((,class (:foreground ,spacegrey5))))
     `(diredfl-write-priv ((,class (:foreground ,red))))

;;;; doom-modeline - dark
     `(doom-modeline-bar-inactive ((,class (:background nil))))
     `(doom-modeline-eldoc-bar ((,class (:background ,green))))

;;;; ediff - dark
     `(ediff-current-diff-A ((,class (:background ,grey :extend t))))
     `(ediff-current-diff-B ((,class (:inherit ediff-current-diff-A))))
     `(ediff-current-diff-C ((,class (:inherit ediff-current-diff-A))))
     `(ediff-even-diff-A ((,class (:inherit hl-line))))
     `(ediff-even-diff-B ((,class (:inherit ediff-even-diff-A))))
     `(ediff-even-diff-C ((,class (:inherit ediff-even-diff-A))))
     `(ediff-fine-diff-A ((,class (:background ,bg :weight bold :extend t))))
     `(ediff-fine-diff-B ((,class (:inherit ediff-fine-diff-A))))
     `(ediff-fine-diff-C ((,class (:inherit ediff-fine-diff-A))))
     `(ediff-odd-diff-A ((,class (:inherit ediff-even-diff-A))))
     `(ediff-odd-diff-B ((,class (:inherit ediff-odd-diff-A))))
     `(ediff-odd-diff-C ((,class (:inherit ediff-odd-diff-A))))

;;;; elfeed - dark
     `(elfeed-log-debug-level-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-log-error-level-face ((,class (:inherit error))))
     `(elfeed-log-info-level-face ((,class (:inherit success))))
     `(elfeed-log-warn-level-face ((,class (:inherit warning))))
     `(elfeed-search-date-face ((,class (:foreground ,magenta))))
     `(elfeed-search-feed-face ((,class (:foreground ,blue))))
     `(elfeed-search-filter-face ((,class (:foreground ,magenta))))
     `(elfeed-search-tag-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-search-title-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-search-unread-count-face ((,class (:foreground ,yellow))))
     `(elfeed-search-unread-title-face ((,class (:foreground ,fg :weight bold))))

;;;; elixir-mode - dark
     `(elixir-atom-face ((,class (:foreground ,cyan))))
     `(elixir-attribute-face ((,class (:foreground ,magenta))))

;;;; elscreen - dark
     `(elscreen-tab-background-face ((,class (:background ,bg))))
     `(elscreen-tab-control-face ((,class (:background ,bg :foreground ,bg))))
     `(elscreen-tab-current-screen-face ((,class (:background ,bg-other :foreground ,fg))))
     `(elscreen-tab-other-screen-face ((,class (:background ,bg :foreground ,fg-other))))

;;;; enh-ruby-mode - dark
     `(enh-ruby-heredoc-delimiter-face ((,class (:inherit font-lock-string-face))))
     `(enh-ruby-op-face ((,class (:foreground ,fg))))
     `(enh-ruby-regexp-delimiter-face ((,class (:inherit enh-ruby-regexp-face))))
     `(enh-ruby-regexp-face ((,class (:foreground ,orange))))
     `(enh-ruby-string-delimiter-face ((,class (:inherit font-lock-string-face))))
     `(erm-syn-errline ((,class (:underline (:style wave :color ,red)))))
     `(erm-syn-warnline ((,class (:underline (:style wave :color ,yellow)))))

;;;; erc - dark
     `(erc-action-face  ((,class (:weight bold))))
     `(erc-button ((,class (:weight bold :underline t))))
     `(erc-command-indicator-face ((,class (:weight bold))))
     `(erc-current-nick-face ((,class (:foreground ,green :weight bold))))
     `(erc-default-face ((,class (:inherit default))))
     `(erc-direct-msg-face ((,class (:foreground ,purple))))
     `(erc-error-face ((,class (:inherit error))))
     `(erc-header-line ((,class (:background ,bg-other :foreground ,orange))))
     `(erc-input-face ((,class (:foreground ,green))))
     `(erc-my-nick-face ((,class (:foreground ,green :weight bold))))
     `(erc-my-nick-prefix-face ((,class (:inherit erc-my-nick-face))))
     `(erc-nick-default-face ((,class (:weight bold))))
     `(erc-nick-msg-face ((,class (:foreground ,purple))))
     `(erc-nick-prefix-face ((,class (:inherit erc-nick-default-face))))
     `(erc-notice-face ((,class (:foreground ,spacegrey5))))
     `(erc-prompt-face ((,class (:foreground ,orange :weight bold))))
     `(erc-timestamp-face ((,class (:foreground ,blue :weight bold))))

;;;; eshell - dark
     `(eshell-ls-archive ((,class (:foreground ,purple))))
     `(eshell-ls-backup ((,class (:foreground ,yellow))))
     `(eshell-ls-clutter ((,class (:foreground ,red))))
     `(eshell-ls-directory ((,class (:foreground ,blue))))
     `(eshell-ls-executable ((,class (:foreground ,green))))
     `(eshell-ls-missing ((,class (:foreground ,red))))
     `(eshell-ls-product ((,class (:foreground ,orange))))
     `(eshell-ls-readonly ((,class (:foreground ,orange))))
     `(eshell-ls-special ((,class (:foreground ,magenta))))
     `(eshell-ls-symlink ((,class (:foreground ,cyan))))
     `(eshell-ls-unreadable ((,class (:foreground ,spacegrey5))))
     `(eshell-prompt ((,class (:foreground ,orange :weight bold))))

;;;; evil - dark
     `(evil-ex-info ((,class (:foreground ,red :slant italic))))
     `(evil-ex-search ((,class (:background ,orange :foreground ,spacegrey0 :weight bold))))
     `(evil-ex-substitute-matches ((,class (:background ,spacegrey0 :foreground ,red :weight bold :strike-through t))))
     `(evil-ex-substitute-replacement ((,class (:background ,spacegrey0 :foreground ,green :weight bold))))
     `(evil-search-highlight-persist-highlight-face ((,class (:inherit lazy-highlight))))

;;;; evil-googles - dark
     `(evil-goggles-default-face ((,class (:inherit region))))

;;;; evil-mc - dark
     `(evil-mc-cursor-bar-face ((,class (:height 1 :background ,purple :foreground ,spacegrey0))))
     `(evil-mc-cursor-default-face ((,class (:background ,purple :foreground ,spacegrey0 :inverse-video nil))))
     `(evil-mc-cursor-hbar-face ((,class (:underline (:color ,orange)))))
     `(evil-mc-region-face ((,class (:inherit region))))

;;;; evil-snipe - dark
     `(evil-snipe-first-match-face ((,class (:foreground ,orange :background ,darkblue :weight bold))))
     `(evil-snipe-matches-face ((,class (:foreground ,orange :underline t :weight bold))))

;;;; flx-ido - dark
     `(flx-highlight-face ((,class (:weight bold :foreground ,yellow :underline nil))))

;;;; flycheck - dark
     `(flycheck-error ((,class (:underline (:style wave :color ,red)))))
     `(flycheck-fringe-error ((,class (:inherit fringe :foreground ,red))))
     `(flycheck-fringe-info ((,class (:inherit fringe :foreground ,green))))
     `(flycheck-fringe-warning ((,class (:inherit fringe :foreground ,yellow))))
     `(flycheck-info ((,class (:underline (:style wave :color ,green)))))
     `(flycheck-warning ((,class (:underline (:style wave :color ,yellow)))))

;;;; flycheck-posframe - dark
     `(flycheck-posframe-background-face ((,class (:background ,bg-other))))
     `(flycheck-posframe-error-face ((,class (:inherit flycheck-posframe-face :foreground ,red))))
     `(flycheck-posframe-face ((,class (:inherit default))))
     `(flycheck-posframe-info-face ((,class (:inherit flycheck-posframe-face :foreground ,fg))))
     `(flycheck-posframe-warning-face ((,class (:inherit flycheck-posframe-face :foreground ,yellow))))

;;;; flymake - dark
     `(flymake-error ((,class (:underline (:style wave :color ,red)))))
     `(flymake-note ((,class (:underline (:style wave :color ,green)))))
     `(flymake-warning ((,class (:underline (:style wave :color ,orange)))))

;;;; flyspell - dark
     `(flyspell-duplicate ((,class (:underline (:style wave :color ,yellow) :inherit unspecified))))
     `(flyspell-incorrect ((,class (:underline (:style wave :color ,red) :inherit unspecified))))

;;;; forge - dark
     `(forge-topic-closed ((,class (:foreground ,spacegrey5 :strike-through t))))
     `(forge-topic-label ((,class (:box nil))))

;;;; git-commit - dark
     `(git-commit-comment-branch-local ((,class (:foreground ,purple))))
     `(git-commit-comment-branch-remote ((,class (:foreground ,green))))
     `(git-commit-comment-detached ((,class (:foreground ,orange))))
     `(git-commit-comment-file ((,class (:foreground ,magenta))))
     `(git-commit-comment-heading ((,class (:foreground ,magenta))))
     `(git-commit-keyword ((,class (:foreground ,cyan :slant italic))))
     `(git-commit-known-pseudo-header ((,class (:foreground ,spacegrey5 :weight bold :slant italic))))
     `(git-commit-nonempty-second-line ((,class (:foreground ,red))))
     `(git-commit-overlong-summary ((,class (:foreground ,red :slant italic :weight bold))))
     `(git-commit-pseudo-header ((,class (:foreground ,spacegrey5 :slant italic))))
     `(git-commit-summary ((,class (:foreground ,darkcyan))))

;;;; git-gutter - dark
     `(git-gutter:added ((,class (:inherit fringe :foreground ,green))))
     `(git-gutter:deleted ((,class (:inherit fringe :foreground ,red))))
     `(git-gutter:modified ((,class (:inherit fringe :foreground ,cyan))))

;;;; git-gutter+ - dark
     `(git-gutter+-added ((,class (:inherit fringe :foreground ,green :background nil))))
     `(git-gutter+-deleted ((,class (:inherit fringe :foreground ,red :background nil))))
     `(git-gutter+-modified ((,class (:inherit fringe :foreground ,cyan :background nil))))

;;;; git-gutter-fringe - dark
     `(git-gutter-fr:added ((,class (:inherit git-gutter:added))))
     `(git-gutter-fr:deleted ((,class (:inherit git-gutter:deleted))))
     `(git-gutter-fr:modified ((,class (:inherit git-gutter:modified))))

;;;; gnus - dark
     `(gnus-cite-1 ((,class (:foreground ,magenta))))
     `(gnus-cite-2 ((,class (:foreground ,magenta))))
     `(gnus-cite-3 ((,class (:foreground ,magenta))))
     `(gnus-cite-4 ((,class (:foreground ,green))))
     `(gnus-cite-5 ((,class (:foreground ,green))))
     `(gnus-cite-6 ((,class (:foreground ,green))))
     `(gnus-cite-7 ((,class (:foreground ,purple))))
     `(gnus-cite-8 ((,class (:foreground ,purple))))
     `(gnus-cite-9 ((,class (:foreground ,purple))))
     `(gnus-cite-10 ((,class (:foreground ,yellow))))
     `(gnus-cite-11 ((,class (:foreground ,yellow))))
     `(gnus-group-mail-1 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-mail-1-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-mail-2 ((,class (:inherit gnus-group-mail-1))))
     `(gnus-group-mail-2-empty ((,class (:inherit gnus-group-mail-1-empty))))
     `(gnus-group-mail-3 ((,class (:inherit gnus-group-mail-1))))
     `(gnus-group-mail-3-empty ((,class (:inherit gnus-group-mail-1-empty))))
     `(gnus-group-mail-low ((,class (:inherit gnus-group-mail-1 :weight normal))))
     `(gnus-group-mail-low-empty ((,class (:inherit gnus-group-mail-1-empty))))
     `(gnus-group-news-1 ((,class (:inherit gnus-group-mail-1))))
     `(gnus-group-news-1-empty ((,class (:inherit gnus-group-mail-1-empty))))
     `(gnus-group-news-2 ((,class (:inherit gnus-group-news-1))))
     `(gnus-group-news-2-empty ((,class (:inherit gnus-group-news-1-empty))))
     `(gnus-group-news-3 ((,class (:inherit gnus-group-news-1))))
     `(gnus-group-news-3-empty ((,class (:inherit gnus-group-news-1-empty))))
     `(gnus-group-news-4 ((,class (:inherit gnus-group-news-1))))
     `(gnus-group-news-4-empty ((,class (:inherit gnus-group-news-1-empty))))
     `(gnus-group-news-5 ((,class (:inherit gnus-group-news-1))))
     `(gnus-group-news-5-empty ((,class (:inherit gnus-group-news-1-empty))))
     `(gnus-group-news-6 ((,class (:inherit gnus-group-news-1))))
     `(gnus-group-news-6-empty ((,class (:inherit gnus-group-news-1-empty))))
     `(gnus-group-news-low ((,class (:inherit gnus-group-mail-1 :foreground ,spacegrey5))))
     `(gnus-group-news-low-empty ((,class (:inherit gnus-group-news-low :weight normal))))
     `(gnus-header-content ((,class (:inherit message-header-other))))
     `(gnus-header-from ((,class (:inherit message-header-other))))
     `(gnus-header-name ((,class (:inherit message-header-name))))
     `(gnus-header-newsgroups ((,class (:inherit message-header-other))))
     `(gnus-header-subject ((,class (:inherit message-header-subject))))
     `(gnus-signature ((,class (:foreground ,yellow))))
     `(gnus-summary-cancelled ((,class (:foreground ,red :strike-through t))))
     `(gnus-summary-high-ancient ((,class (:foreground ,spacegrey5 :inherit italic))))
     `(gnus-summary-high-read ((,class (:foreground ,fg))))
     `(gnus-summary-high-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-high-unread ((,class (:foreground ,green))))
     `(gnus-summary-low-ancient ((,class (:foreground ,spacegrey5 :inherit italic))))
     `(gnus-summary-low-read ((,class (:foreground ,fg))))
     `(gnus-summary-low-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-low-unread ((,class (:foreground ,green))))
     `(gnus-summary-normal-ancient ((,class (:foreground ,spacegrey5 :inherit italic))))
     `(gnus-summary-normal-read ((,class (:foreground ,fg))))
     `(gnus-summary-normal-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-normal-unread ((,class (:foreground ,green :inherit bold))))
     `(gnus-summary-selected ((,class (:foreground ,blue :weight bold))))
     `(gnus-x-face ((,class (:background ,spacegrey5 :foreground ,fg))))

;;;; goggles - dark
     `(goggles-added ((,class (:background ,green))))
     `(goggles-changed ((,class (:inherit region))))
     `(goggles-removed ((,class (:background ,red :extend t))))

;;;; header-line - dark
     `(header-line ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))

;;;; helm - dark
     `(helm-ff-directory ((,class (:foreground ,red))))
     `(helm-ff-dotted-directory ((,class (:foreground ,grey))))
     `(helm-ff-executable ((,class (:foreground ,spacegrey8 :inherit italic))))
     `(helm-ff-file ((,class (:foreground ,fg))))
     `(helm-ff-prefix ((,class (:foreground ,magenta))))
     `(helm-grep-file ((,class (:foreground ,blue))))
     `(helm-grep-finish ((,class (:foreground ,green))))
     `(helm-grep-lineno ((,class (:foreground ,spacegrey5))))
     `(helm-grep-match ((,class (:foreground ,orange :distant-foreground ,red))))
     `(helm-match ((,class (:inherit bold :foreground ,orange :distant-foreground ,spacegrey8))))
     `(helm-moccur-buffer ((,class (:inherit link))))
     `(helm-selection ((,class (:inherit bold :background ,grey :extend t :distant-foreground ,orange))))
     `(helm-source-header ((,class (:background ,spacegrey2 :foreground ,magenta :weight bold))))
     `(helm-swoop-target-line-block-face ((,class (:foreground ,yellow))))
     `(helm-swoop-target-line-face ((,class (:foreground ,orange :inverse-video t))))
     `(helm-swoop-target-line-face ((,class (:foreground ,orange :inverse-video t))))
     `(helm-swoop-target-number-face ((,class (:foreground ,spacegrey5))))
     `(helm-swoop-target-word-face ((,class (:foreground ,green :inherit bold))))
     `(helm-visible-mark ((,class (:inherit (bold highlight)))))

;;;; helpful - dark
     `(helpful-heading ((,class (:weight bold :height 1.2))))

;;;; hi-lock - dark
     `(hi-blue ((,class (:background ,blue))))
     `(hi-blue-b ((,class (:foreground ,blue :weight bold))))
     `(hi-green ((,class (:background ,green))))
     `(hi-green-b ((,class (:foreground ,green :weight bold))))
     `(hi-magenta ((,class (:background ,purple))))
     `(hi-red-b ((,class (:foreground ,red :weight bold))))
     `(hi-yellow ((,class (:background ,yellow))))

;;;; highlight-indentation-mode - dark
     `(highlight-indentation-current-column-face ((,class (:background ,spacegrey1))))
     `(highlight-indentation-face ((,class (:inherit hl-line))))
     `(highlight-indentation-guides-even-face ((,class (:inherit highlight-indentation-face))))
     `(highlight-indentation-guides-odd-face ((,class (:inherit highlight-indentation-face))))

;;;; highlight-numbers-mode - dark
     `(highlight-numbers-number ((,class (:inherit bold :foreground ,orange))))

;;;; highlight-quoted-mode - dark
     `(highlight-quoted-quote  ((,class (:foreground ,fg))))
     `(highlight-quoted-symbol ((,class (:foreground ,yellow))))

;;;; highlight-symbol - dark
     `(highlight-symbol-face ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; highlight-thing - dark
     `(highlight-thing ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; hl-fill-column-face - dark
     `(hl-fill-column-face ((,class (:inherit (hl-line shadow)))))

;;;; hl-line (built-in) - dark
     `(hl-line ((,class (:background ,bg-other :extend t))))

;;;; hl-todo - dark
     `(hl-todo ((,class (:foreground ,red :weight bold))))

;;;; hlinum - dark
     `(linum-highlight-face ((,class (:foreground ,fg :distant-foreground nil :weight normal))))

;;;; hydra - dark
     `(hydra-face-amaranth ((,class (:foreground ,purple :weight bold))))
     `(hydra-face-blue ((,class (:foreground ,blue :weight bold))))
     `(hydra-face-magenta ((,class (:foreground ,magenta :weight bold))))
     `(hydra-face-red ((,class (:foreground ,red :weight bold))))
     `(hydra-face-teal ((,class (:foreground ,teal :weight bold))))

;;;; ido - dark
     `(ido-first-match ((,class (:foreground ,orange))))
     `(ido-indicator ((,class (:foreground ,red :background ,bg))))
     `(ido-only-match ((,class (:foreground ,green))))
     `(ido-subdir ((,class (:foreground ,magenta))))
     `(ido-virtual ((,class (:foreground ,spacegrey5))))

;;;; iedit - dark
     `(iedit-occurrence ((,class (:foreground ,purple :weight bold :inverse-video t))))
     `(iedit-read-only-occurrence ((,class (:inherit region))))

;;;; imenu-list - dark
     `(imenu-list-entry-face-0 ((,class (:foreground ,orange))))
     `(imenu-list-entry-face-1 ((,class (:foreground ,green))))
     `(imenu-list-entry-face-2 ((,class (:foreground ,yellow))))
     `(imenu-list-entry-subalist-face-0 ((,class (:inherit imenu-list-entry-face-0 :weight bold))))
     `(imenu-list-entry-subalist-face-1 ((,class (:inherit imenu-list-entry-face-1 :weight bold))))
     `(imenu-list-entry-subalist-face-2 ((,class (:inherit imenu-list-entry-face-2 :weight bold))))

;;;; indent-guide - dark
     `(indent-guide-face ((,class (:inherit highlight-indentation-face))))

;;;; isearch - dark
     `(isearch ((,class (:inherit lazy-highlight :weight bold))))
     `(isearch-fail ((,class (:background ,red :foreground ,spacegrey0 :weight bold))))

;;;; ivy - dark
     `(ivy-confirm-face ((,class (:foreground ,green))))
     `(ivy-current-match ((,class (:background ,grey :distant-foreground nil :extend t))))
     `(ivy-highlight-face ((,class (:foreground ,magenta))))
     `(ivy-match-required-face ((,class (:foreground ,red))))
     `(ivy-minibuffer-match-face-1 ((,class (:background nil :foreground ,orange :weight bold :underline t))))
     `(ivy-minibuffer-match-face-2 ((,class (:inherit ivy-minibuffer-match-face-1 :foreground ,purple :background ,spacegrey1 :weight semi-bold))))
     `(ivy-minibuffer-match-face-3 ((,class (:inherit ivy-minibuffer-match-face-2 :foreground ,green :weight semi-bold))))
     `(ivy-minibuffer-match-face-4 ((,class (:inherit ivy-minibuffer-match-face-2 :foreground ,yellow :weight semi-bold))))
     `(ivy-minibuffer-match-highlight ((,class (:foreground ,magenta))))
     `(ivy-modified-buffer ((,class (:inherit bold :foreground ,darkcyan))))
     `(ivy-virtual ((,class (:inherit italic :foreground ,fg))))

;;;; ivy-posframe - dark
     `(ivy-posframe ((,class (:background ,bg-other))))
     `(ivy-posframe-border ((,class (:inherit internal-border))))

;;;; jabber - dark
     `(jabber-activity-face ((,class (:foreground ,red :weight bold))))
     `(jabber-activity-personal-face ((,class (:foreground ,blue :weight bold))))
     `(jabber-chat-error ((,class (:foreground ,red :weight bold))))
     `(jabber-chat-prompt-foreign ((,class (:foreground ,red :weight bold))))
     `(jabber-chat-prompt-local ((,class (:foreground ,blue :weight bold))))
     `(jabber-chat-prompt-system ((,class (:foreground ,green :weight bold))))
     `(jabber-chat-text-foreign ((,class (:foreground ,fg))))
     `(jabber-chat-text-local ((,class (:foreground ,fg))))
     `(jabber-rare-time-face ((,class (:foreground ,green))))
     `(jabber-roster-user-away ((,class (:foreground ,yellow))))
     `(jabber-roster-user-chatty ((,class (:foreground ,green :weight bold))))
     `(jabber-roster-user-dnd ((,class (:foreground ,red))))
     `(jabber-roster-user-error ((,class (:foreground ,red))))
     `(jabber-roster-user-offline ((,class (:foreground ,fg))))
     `(jabber-roster-user-online ((,class (:foreground ,green :weight bold))))
     `(jabber-roster-user-xa ((,class (:foreground ,cyan))))

;;;; jdee - dark
     `(jdee-font-lock-bold-face ((,class (:inherit bold))))
     `(jdee-font-lock-constant-face ((,class (:inherit font-lock-constant-face))))
     `(jdee-font-lock-constructor-face ((,class (:foreground ,blue))))
     `(jdee-font-lock-doc-tag-face ((,class (:foreground ,magenta))))
     `(jdee-font-lock-italic-face ((,class (:inherit italic))))
     `(jdee-font-lock-link-face ((,class (:foreground ,blue :italic nil :underline t))))
     `(jdee-font-lock-modifier-face ((,class (:inherit font-lock-type-face))))
     `(jdee-font-lock-number-face ((,class (:foreground ,orange))))
     `(jdee-font-lock-operator-face ((,class (:foreground ,fg))))
     `(jdee-font-lock-private-face ((,class (:inherit font-lock-keyword-face))))
     `(jdee-font-lock-protected-face ((,class (:inherit font-lock-keyword-face))))
     `(jdee-font-lock-public-face ((,class (:inherit font-lock-keyword-face))))

;;;; js2-mode - dark
     `(js2-external-variable ((,class (:foreground ,fg))))
     `(js2-function-call ((,class (:foreground ,blue))))
     `(js2-function-param ((,class (:foreground ,red))))
     `(js2-jsdoc-tag ((,class (:foreground ,spacegrey5))))
     `(js2-object-property ((,class (:foreground ,magenta))))

;;;; keycast - dark
     `(keycast-command ((,class (:inherit mode-line-emphasis))))
     `(keycast-key ((,class (:inherit (bold mode-line-highlight)))))

;;;; ledger-mode - dark
     `(ledger-font-payee-cleared-face ((,class (:foreground ,magenta :weight bold))))
     `(ledger-font-payee-uncleared-face ((,class (:foreground ,spacegrey5  :weight bold))))
     `(ledger-font-posting-account-face ((,class (:foreground ,spacegrey8))))
     `(ledger-font-posting-amount-face ((,class (:foreground ,yellow))))
     `(ledger-font-posting-date-face ((,class (:foreground ,blue))))
     `(ledger-font-xact-highlight-face ((,class (:background ,spacegrey0))))

;;;; line numbers - dark
     `(line-number ((,class (:inherit default :foreground ,spacegrey5 :weight normal))))
     `(line-number-current-line ((,class (:inherit (hl-line default) :foreground ,fg :weight normal))))

;;;; linum - dark
     `(linum ((,class (:inherit line-number))))

;;;; linum-relative - dark
     `(linum-relative-current-face ((,class (:inherit line-number-current-line))))

;;;; lsp-mode - dark
     `(lsp-face-highlight-read ((,class (:background ,darkblue :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(lsp-face-highlight-textual ((,class (:background ,darkblue :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(lsp-face-highlight-write ((,class (:background ,darkblue :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(lsp-headerline-breadcrumb-separator-face ((,class (:foreground ,fg-other))))
     `(lsp-ui-doc-background ((,class (:inherit tooltip))))
     `(lsp-ui-peek-filename ((,class (:inherit mode-line-buffer-id))))
     `(lsp-ui-peek-header ((,class (:foreground ,fg :background ,bg :bold bold))))
     `(lsp-ui-peek-highlight ((,class (:inherit lsp-ui-peek-header :background ,grey :foreground ,bg :box t))))
     `(lsp-ui-peek-line-number ((,class (:foreground ,green))))
     `(lsp-ui-peek-list ((,class (:background ,bg))))
     `(lsp-ui-peek-peek ((,class (:background ,bg))))
     `(lsp-ui-peek-selection ((,class (:foreground ,bg :background ,blue :bold bold))))
     `(lsp-ui-sideline-code-action ((,class (:foreground ,orange))))
     `(lsp-ui-sideline-current-symbol ((,class (:foreground ,orange))))
     `(lsp-ui-sideline-symbol-info ((,class (:foreground ,spacegrey5 :background ,bg-other :extend t))))

;;;; lui - dark
     `(lui-button-face ((,class (:foreground ,orange :underline t))))
     `(lui-highlight-face ((,class (:foreground ,orange))))
     `(lui-time-stamp-face ((,class (:foreground ,magenta))))

;;;; magit - dark
     `(magit-bisect-bad ((,class (:foreground ,red))))
     `(magit-bisect-good ((,class (:foreground ,green))))
     `(magit-bisect-skip ((,class (:foreground ,orange))))
     `(magit-blame-date ((,class (:foreground ,red))))
     `(magit-blame-heading ((,class (:foreground ,orange :background ,spacegrey3 :extend t))))
     `(magit-branch-current ((,class (:foreground ,red))))
     `(magit-branch-local ((,class (:foreground ,red))))
     `(magit-branch-remote ((,class (:foreground ,green))))
     `(magit-branch-remote-head ((,class (:foreground ,green))))
     `(magit-cherry-equivalent ((,class (:foreground ,magenta))))
     `(magit-cherry-unmatched ((,class (:foreground ,cyan))))
     `(magit-diff-added ((,class (:foreground ,bg  :background ,green :extend t))))
     `(magit-diff-added-highlight ((,class (:foreground ,bg :background ,green :weight bold :extend t))))
     `(magit-diff-base ((,class (:foreground ,orange :background ,orange :extend t))))
     `(magit-diff-base-highlight ((,class (:foreground ,orange :background ,orange :weight bold :extend t))))
     `(magit-diff-context ((,class (:foreground ,fg :background ,bg :extend t))))
     `(magit-diff-context-highlight ((,class (:foreground ,fg :background ,bg-other :extend t))))
     `(magit-diff-file-heading ((,class (:foreground ,fg :weight bold :extend t))))
     `(magit-diff-file-heading-selection ((,class (:foreground ,purple :background ,darkblue :weight bold :extend t))))
     `(magit-diff-hunk-heading ((,class (:foreground ,bg :background ,magenta :extend t))))
     `(magit-diff-hunk-heading-highlight ((,class (:foreground ,bg :background ,magenta :weight bold :extend t))))
     `(magit-diff-lines-heading ((,class (:foreground ,yellow :background ,red :extend t :extend t))))
     `(magit-diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
     `(magit-diff-removed-highlight ((,class (:foreground ,bg :background ,red :weight bold :extend t))))
     `(magit-diffstat-added ((,class (:foreground ,green))))
     `(magit-diffstat-removed ((,class (:foreground ,red))))
     `(magit-dimmed ((,class (:foreground ,spacegrey5))))
     `(magit-filename ((,class (:foreground ,magenta))))
     `(magit-hash ((,class (:foreground ,blue))))
     `(magit-header-line ((,class (:background ,bg-other :foreground ,darkcyan :weight bold :box (:line-width 3 :color ,bg-other)))))
     `(magit-log-author ((,class (:foreground ,orange))))
     `(magit-log-date ((,class (:foreground ,blue))))
     `(magit-log-graph ((,class (:foreground ,spacegrey5))))
     `(magit-process-ng ((,class (:inherit error))))
     `(magit-process-ok ((,class (:inherit success))))
     `(magit-reflog-amend ((,class (:foreground ,purple))))
     `(magit-reflog-checkout ((,class (:foreground ,blue))))
     `(magit-reflog-cherry-pick ((,class (:foreground ,green))))
     `(magit-reflog-commit ((,class (:foreground ,green))))
     `(magit-reflog-merge ((,class (:foreground ,green))))
     `(magit-reflog-other ((,class (:foreground ,cyan))))
     `(magit-reflog-rebase ((,class (:foreground ,purple))))
     `(magit-reflog-remote ((,class (:foreground ,cyan))))
     `(magit-reflog-reset ((,class (:inherit error))))
     `(magit-refname ((,class (:foreground ,spacegrey5))))
     `(magit-section-heading ((,class (:foreground ,darkcyan :weight bold :extend t))))
     `(magit-section-heading-selection ((,class (:foreground ,orange :weight bold :extend t))))
     `(magit-section-highlight ((,class (:inherit hl-line))))
     `(magit-section-secondary-heading ((,class (:foreground ,magenta :weight bold :extend t))))
     `(magit-sequence-drop ((,class (:foreground ,red))))
     `(magit-sequence-head ((,class (:foreground ,blue))))
     `(magit-sequence-part ((,class (:foreground ,orange))))
     `(magit-sequence-stop ((,class (:foreground ,green))))
     `(magit-signature-bad ((,class (:inherit error))))
     `(magit-signature-error ((,class (:inherit error))))
     `(magit-signature-expired ((,class (:foreground ,orange))))
     `(magit-signature-good ((,class (:inherit success))))
     `(magit-signature-revoked ((,class (:foreground ,purple))))
     `(magit-signature-untrusted ((,class (:foreground ,yellow))))
     `(magit-tag ((,class (:foreground ,yellow))))

;;;; make-mode - dark
     `(makefile-targets ((,class (:foreground ,blue))))

;;;; marginalia - dark
     `(marginalia-documentation ((,class (:foreground ,blue))))
     `(marginalia-file-name ((,class (:foreground ,blue))))

;;;; markdown-mode - dark
     `(markdown-blockquote-face ((,class (:inherit italic :foreground ,spacegrey5))))
     `(markdown-bold-face ((,class (:inherit bold :foreground ,orange))))
     `(markdown-code-face ((,class (:background ,bg-org :extend t))))
     `(markdown-header-delimiter-face ((,class (:inherit markdown-header-face))))
     `(markdown-header-face ((,class (:inherit bold :foreground ,orange))))
     `(markdown-html-attr-name-face ((,class (:inherit font-lock-variable-name-face))))
     `(markdown-html-attr-value-face ((,class (:inherit font-lock-string-face))))
     `(markdown-html-entity-face ((,class (:inherit font-lock-variable-name-face))))
     `(markdown-html-tag-delimiter-face ((,class (:inherit markdown-markup-face))))
     `(markdown-html-tag-name-face ((,class (:inherit font-lock-keyword-face))))
     `(markdown-inline-code-face ((,class (:inherit (markdown-code-face markdown-pre-face) :extend nil))))
     `(markdown-italic-face ((,class (:inherit italic :foreground ,magenta))))
     `(markdown-link-face ((,class (:foreground ,orange))))
     `(markdown-list-face ((,class (:foreground ,red))))
     `(markdown-markup-face ((,class (:foreground ,fg))))
     `(markdown-metadata-key-face ((,class (:foreground ,red))))
     `(markdown-pre-face ((,class (:background ,bg-org :foreground ,green))))
     `(markdown-reference-face ((,class (:foreground ,spacegrey5))))
     `(markdown-url-face ((,class (:foreground ,purple :weight normal))))

;;;; message - dark
     `(message-cited-text ((,class (:foreground ,purple))))
     `(message-header-cc ((,class (:inherit 'message-header-to :foreground ,orange))))
     `(message-header-name ((,class (:foreground ,green))))
     `(message-header-newsgroups ((,class (:foreground ,yellow))))
     `(message-header-other ((,class (:foreground ,magenta))))
     `(message-header-subject ((,class (:foreground ,orange :weight bold))))
     `(message-header-to ((,class (:foreground ,orange :weight bold))))
     `(message-header-xheader ((,class (:foreground ,spacegrey5))))
     `(message-mml ((,class (:foreground ,spacegrey5 :slant italic))))
     `(message-separator ((,class (:foreground ,spacegrey5))))

;;;; mic-paren - dark
     `(paren-face-match ((,class (:foreground ,red :background ,spacegrey0 :weight ultra-bold))))
     `(paren-face-mismatch ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))
     `(paren-face-no-match ((,class (:inherit paren-face-mismatch :weight ultra-bold))))

;;;; minimap - dark
     `(minimap-active-region-background ((,class (:background ,bg))))
     `(minimap-current-line-face ((,class (:background ,grey))))

;;;; mmm-mode - dark
     `(mmm-cleanup-submode-face ((,class (:background ,yellow))))
     `(mmm-code-submode-face ((,class (:background ,bg-other))))
     `(mmm-comment-submode-face ((,class (:background ,blue))))
     `(mmm-declaration-submode-face ((,class (:background ,cyan))))
     `(mmm-default-submode-face ((,class (:background nil))))
     `(mmm-init-submode-face ((,class (:background ,red))))
     `(mmm-output-submode-face ((,class (:background ,magenta))))
     `(mmm-special-submode-face ((,class (:background ,green))))

;;;; mode-line - dark
     `(mode-line ((,class (:background ,bg-other :foreground ,fg :distant-foreground ,bg))))
     `(mode-line-buffer-id ((,class (:weight bold))))
     `(mode-line-emphasis ((,class (:foreground ,orange :distant-foreground ,bg))))
     `(mode-line-highlight ((,class (:inherit highlight :distant-foreground ,bg))))
     `(mode-line-inactive ((,class (:background ,bg-other :foreground ,spacegrey5 :distant-foreground ,bg-other))))

;;;; mu4e - dark
     `(mu4e-forwarded-face ((,class (:foreground ,orange))))
     `(mu4e-header-key-face ((,class (:foreground ,darkcyan))))
     `(mu4e-header-title-face ((,class (:foreground ,magenta))))
     `(mu4e-highlight-face ((,class (:foreground ,bg :background ,orange))))
     `(mu4e-replied-face ((,class (:foreground ,darkcyan))))
     `(mu4e-title-face ((,class (:foreground ,magenta))))

;;;; mu4e-column-faces - dark
     `(mu4e-column-faces-date ((,class (:foreground ,blue))))
     `(mu4e-column-faces-to-from ((,class (:foreground ,green))))

;;;; mu4e-thread-folding - dark
     `(mu4e-thread-folding-child-face ((,class (:extend t :background ,bg-org :underline nil))))
     `(mu4e-thread-folding-root-folded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))
     `(mu4e-thread-folding-root-unfolded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))

;;;; multiple cursors - dark
     `(mc/cursor-face ((,class (:inherit cursor))))

;;;; nano-modeline - dark
     `(nano-modeline-active-name ((,class (:foreground ,fg :weight bold))))
     `(nano-modeline-inactive-name ((,class (:foreground ,spacegrey5 :weight bold))))
     `(nano-modeline-active-primary ((,class (:foreground ,fg))))
     `(nano-modeline-inactive-primary ((,class (:foreground ,spacegrey5))))
     `(nano-modeline-active-secondary ((,class (:foreground ,orange :weight bold))))
     `(nano-modeline-inactive-secondary ((,class (:foreground ,spacegrey5 :weight bold))))
     `(nano-modeline-active-status-RO ((,class (:background ,red :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-RO ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))
     `(nano-modeline-active-status-RW ((,class (:background ,orange :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-RW ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))
     `(nano-modeline-active-status-** ((,class (:background ,red :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-** ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))

;;;; nav-flash - dark
     `(nav-flash-face ((,class (:background ,grey :foreground ,spacegrey8 :weight bold))))

;;;; neotree - dark
     `(neo-dir-link-face ((,class (:foreground ,orange))))
     `(neo-expand-btn-face ((,class (:foreground ,orange))))
     `(neo-file-link-face ((,class (:foreground ,fg))))
     `(neo-root-dir-face ((,class (:foreground ,green :background ,bg :box (:line-width 4 :color ,bg)))))
     `(neo-vc-added-face ((,class (:foreground ,green))))
     `(neo-vc-conflict-face ((,class (:foreground ,purple :weight bold))))
     `(neo-vc-edited-face ((,class (:foreground ,yellow))))
     `(neo-vc-ignored-face ((,class (:foreground ,spacegrey5))))
     `(neo-vc-removed-face ((,class (:foreground ,red :strike-through t))))

;;;; nlinum - dark
     `(nlinum-current-line ((,class (:inherit line-number-current-line))))

;;;; nlinum-hl - dark
     `(nlinum-hl-face ((,class (:inherit line-number-current-line))))

;;;; nlinum-relative - dark
     `(nlinum-relative-current-face ((,class (:inherit line-number-current-line))))

;;;; notmuch - dark
     `(notmuch-message-summary-face ((,class (:foreground ,grey :background nil))))
     `(notmuch-search-count ((,class (:foreground ,spacegrey5))))
     `(notmuch-search-date ((,class (:foreground ,orange))))
     `(notmuch-search-flagged-face ((,class (:foreground ,red))))
     `(notmuch-search-matching-authors ((,class (:foreground ,blue))))
     `(notmuch-search-non-matching-authors ((,class (:foreground ,fg))))
     `(notmuch-search-subject ((,class (:foreground ,fg))))
     `(notmuch-search-unread-face ((,class (:weight bold))))
     `(notmuch-tag-added ((,class (:foreground ,green :weight normal))))
     `(notmuch-tag-deleted ((,class (:foreground ,red :weight normal))))
     `(notmuch-tag-face ((,class (:foreground ,yellow :weight normal))))
     `(notmuch-tag-flagged ((,class (:foreground ,yellow :weight normal))))
     `(notmuch-tag-unread ((,class (:foreground ,yellow :weight normal))))
     `(notmuch-tree-match-author-face ((,class (:foreground ,blue :weight bold))))
     `(notmuch-tree-match-date-face ((,class (:foreground ,orange :weight bold))))
     `(notmuch-tree-match-face ((,class (:foreground ,fg))))
     `(notmuch-tree-match-subject-face ((,class (:foreground ,fg))))
     `(notmuch-tree-match-tag-face ((,class (:foreground ,yellow))))
     `(notmuch-tree-match-tree-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-author-face ((,class (:foreground ,blue))))
     `(notmuch-tree-no-match-date-face ((,class (:foreground ,orange))))
     `(notmuch-tree-no-match-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-subject-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-tag-face ((,class (:foreground ,yellow))))
     `(notmuch-tree-no-match-tree-face ((,class (:foreground ,yellow))))
     `(notmuch-wash-cited-text ((,class (:foreground ,spacegrey4))))
     `(notmuch-wash-toggle-button ((,class (:foreground ,fg))))

;;;; orderless - dark
     `(orderless-match-face-0 ((,class (:foreground ,teal :weight bold :underline t))))
     `(orderless-match-face-1 ((,class (:foreground ,darkcyan :weight bold :underline t))))
     `(orderless-match-face-2 ((,class (:foreground ,cyan :weight bold :underline t))))
     `(orderless-match-face-3 ((,class (:foreground ,green :weight bold :underline t))))

;;;; objed - dark
     `(objed-hl ((,class (:inherit region :background ,grey))))
     `(objed-mode-line ((,class (:inherit warning :weight bold))))

;;;; org-agenda - dark
     `(org-agenda-clocking ((,class (:background ,blue))))
     `(org-agenda-date ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-date-today ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-date-weekend ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-dimmed-todo-face ((,class (:foreground ,spacegrey5))))
     `(org-agenda-done ((,class (:inherit org-done))))
     `(org-agenda-structure ((,class (:foreground ,fg :weight ultra-bold))))
     `(org-scheduled ((,class (:foreground ,fg))))
     `(org-scheduled-previously ((,class (:foreground ,spacegrey8))))
     `(org-scheduled-today ((,class (:foreground ,spacegrey7))))
     `(org-sexp-date ((,class (:foreground ,fg))))
     `(org-time-grid ((,class (:foreground ,spacegrey5))))
     `(org-upcoming-deadline ((,class (:foreground ,fg))))
     `(org-upcoming-distant-deadline ((,class (:foreground ,fg))))

;;;; org-habit - dark
     `(org-habit-alert-face ((,class (:weight bold :background ,yellow))))
     `(org-habit-alert-future-face ((,class (:weight bold :background ,yellow))))
     `(org-habit-clear-face ((,class (:weight bold :background ,spacegrey4))))
     `(org-habit-clear-future-face ((,class (:weight bold :background ,spacegrey3))))
     `(org-habit-overdue-face ((,class (:weight bold :background ,red))))
     `(org-habit-overdue-future-face ((,class (:weight bold :background ,red))))
     `(org-habit-ready-face ((,class (:weight bold :background ,blue))))
     `(org-habit-ready-future-face ((,class (:weight bold :background ,blue))))

;;;; org-journal - dark
     `(org-journal-calendar-entry-face ((,class (:foreground ,purple :slant italic))))
     `(org-journal-calendar-scheduled-face ((,class (:foreground ,red :slant italic))))
     `(org-journal-highlight ((,class (:foreground ,orange))))

;;;; org-mode - dark
     `(org-archived ((,class (:foreground ,spacegrey5))))
     `(org-block ((,class (:foreground ,spacegrey8 :background ,bg-org :extend t))))
     `(org-block-background ((,class (:background ,bg-org :extend t))))
     `(org-block-begin-line ((,class (:foreground ,spacegrey5 :slant italic :background ,bg-org :extend t))))
     `(org-block-end-line ((,class (:inherit org-block-begin-line))))
     `(org-checkbox ((,class (:inherit org-todo))))
     `(org-checkbox-statistics-done ((,class (:inherit org-done))))
     `(org-checkbox-statistics-todo ((,class (:inherit org-todo))))
     `(org-code ((,class (:foreground ,green))))
     `(org-date ((,class (:foreground ,yellow))))
     `(org-default ((,class (:inherit variable-pitch))))
     `(org-document-info ((,class (:foreground ,orange))))
     `(org-document-title ((,class (:foreground ,orange :weight bold))))
     `(org-done ((,class (:inherit org-headline-done :bold inherit))))
     `(org-ellipsis ((,class (:underline nil :background nil :foreground ,grey))))
     `(org-footnote ((,class (:foreground ,orange))))
     `(org-formula ((,class (:foreground ,cyan))))
     `(org-headline-done ((,class (:foreground ,spacegrey5))))
     `(org-hide ((,class (:foreground ,bg))))
     `(org-latex-and-related ((,class (:foreground ,spacegrey8 :weight bold))))
     `(org-level-1 ((,class (:foreground ,blue :weight ultra-bold))))
     `(org-level-2 ((,class (:foreground ,magenta :weight bold))))
     `(org-level-3 ((,class (:foreground ,darkcyan :weight bold))))
     `(org-level-4 ((,class (:foreground ,orange))))
     `(org-level-5 ((,class (:foreground ,green))))
     `(org-level-6 ((,class (:foreground ,teal))))
     `(org-level-7 ((,class (:foreground ,purple))))
     `(org-level-8 ((,class (:foreground ,fg))))
     `(org-link ((,class (:foreground ,darkcyan :underline t))))
     `(org-list-dt ((,class (:foreground ,orange))))
     `(org-meta-line ((,class (:foreground ,spacegrey5))))
     `(org-priority ((,class (:foreground ,red))))
     `(org-property-value ((,class (:foreground ,spacegrey5))))
     `(org-quote ((,class (:background ,spacegrey3 :slant italic :extend t))))
     `(org-special-keyword ((,class (:foreground ,spacegrey5))))
     `(org-table ((,class (:foreground ,magenta))))
     `(org-tag ((,class (:foreground ,spacegrey5 :weight normal))))
     `(org-todo ((,class (:foreground ,green :bold inherit))))
     `(org-verbatim ((,class (:foreground ,orange))))
     `(org-warning ((,class (:foreground ,yellow))))

;;;; org-pomodoro - dark
     `(org-pomodoro-mode-line ((,class (:foreground ,red))))
     `(org-pomodoro-mode-line-overtime ((,class (:foreground ,yellow :weight bold))))

;;;; org-ref - dark
     `(org-ref-acronym-face ((,class (:foreground ,magenta))))
     `(org-ref-cite-face ((,class (:foreground ,yellow :weight light :underline t))))
     `(org-ref-glossary-face ((,class (:foreground ,purple))))
     `(org-ref-label-face ((,class (:foreground ,blue))))
     `(org-ref-ref-face ((,class (:inherit link :foreground ,teal))))

;;;; outline - dark
     `(outline-1 ((,class (:foreground ,blue :weight ultra-bold))))
     `(outline-2 ((,class (:foreground ,magenta :weight bold))))
     `(outline-3 ((,class (:foreground ,green :weight bold))))
     `(outline-4 ((,class (:foreground ,orange))))
     `(outline-5 ((,class (:foreground ,purple))))
     `(outline-6 ((,class (:foreground ,purple))))
     `(outline-7 ((,class (:foreground ,purple))))
     `(outline-8 ((,class (:foreground ,fg))))

;;;; parenface - dark
     `(paren-face ((,class (:foreground ,spacegrey5))))

;;;; parinfer - dark
     `(parinfer-pretty-parens:dim-paren-face ((,class (:foreground ,spacegrey5))))
     `(parinfer-smart-tab:indicator-face ((,class (:foreground ,spacegrey5))))

;;;; persp-mode - dark
     `(persp-face-lighter-buffer-not-in-persp ((,class (:foreground ,spacegrey5))))
     `(persp-face-lighter-default ((,class (:foreground ,orange :weight bold))))
     `(persp-face-lighter-nil-persp ((,class (:foreground ,spacegrey5))))

;;;; perspective - dark
     `(persp-selected-face ((,class (:foreground ,blue :weight bold))))

;;;; pkgbuild-mode - dark
     `(pkgbuild-error-face ((,class (:underline (:style wave :color ,red)))))

;;;; popup - dark
     `(popup-face ((,class (:inherit tooltip))))
     `(popup-selection-face ((,class (:background ,grey))))
     `(popup-tip-face ((,class (:inherit popup-face :foreground ,magenta :background ,spacegrey0))))

;;;; powerline - dark
     `(powerline-active0 ((,class (:inherit mode-line :background ,bg))))
     `(powerline-active1 ((,class (:inherit mode-line :background ,bg))))
     `(powerline-active2 ((,class (:inherit mode-line :foreground ,spacegrey8 :background ,bg))))
     `(powerline-inactive0 ((,class (:inherit mode-line-inactive :background ,spacegrey2))))
     `(powerline-inactive1 ((,class (:inherit mode-line-inactive :background ,spacegrey2))))
     `(powerline-inactive2 ((,class (:inherit mode-line-inactive :background ,spacegrey2))))

;;;; rainbow-delimiters - dark
     `(rainbow-delimiters-depth-1-face ((,class (:foreground ,blue))))
     `(rainbow-delimiters-depth-2-face ((,class (:foreground ,purple))))
     `(rainbow-delimiters-depth-3-face ((,class (:foreground ,green))))
     `(rainbow-delimiters-depth-4-face ((,class (:foreground ,orange))))
     `(rainbow-delimiters-depth-5-face ((,class (:foreground ,magenta))))
     `(rainbow-delimiters-depth-6-face ((,class (:foreground ,yellow))))
     `(rainbow-delimiters-depth-7-face ((,class (:foreground ,teal))))
     `(rainbow-delimiters-mismatched-face ((,class (:inherit rainbow-delimiters-unmatched-face))))
     `(rainbow-delimiters-unmatched-face ((,class (:foreground ,red :weight bold :inverse-video t))))

;;;; re-builder - dark
     `(reb-match-0 ((,class (:foreground ,orange :inverse-video t))))
     `(reb-match-1 ((,class (:foreground ,purple :inverse-video t))))
     `(reb-match-2 ((,class (:foreground ,green :inverse-video t))))
     `(reb-match-3 ((,class (:foreground ,yellow :inverse-video t))))

;;;; rjsx-mode - dark
     `(rjsx-attr ((,class (:foreground ,blue))))
     `(rjsx-tag ((,class (:foreground ,yellow))))

;;;; rpm-spec-mode - dark
     `(rpm-spec-dir-face ((,class (:foreground ,green))))
     `(rpm-spec-doc-face ((,class (:foreground ,orange))))
     `(rpm-spec-ghost-face ((,class (:foreground ,spacegrey5))))
     `(rpm-spec-macro-face ((,class (:foreground ,yellow))))
     `(rpm-spec-obsolete-tag-face ((,class (:foreground ,red))))
     `(rpm-spec-package-face ((,class (:foreground ,orange))))
     `(rpm-spec-section-face ((,class (:foreground ,purple))))
     `(rpm-spec-tag-face ((,class (:foreground ,blue))))
     `(rpm-spec-var-face ((,class (:foreground ,magenta))))

;;;; rst - dark
     `(rst-block ((,class (:inherit font-lock-constant-face))))
     `(rst-level-1 ((,class (:inherit rst-adornment :weight bold))))
     `(rst-level-2 ((,class (:inherit rst-adornment :weight bold))))
     `(rst-level-3 ((,class (:inherit rst-adornment :weight bold))))
     `(rst-level-4 ((,class (:inherit rst-adornment :weight bold))))
     `(rst-level-5 ((,class (:inherit rst-adornment :weight bold))))
     `(rst-level-6 ((,class (:inherit rst-adornment :weight bold))))

;;;; selectrum - dark
     `(selectrum-current-candidate ((,class (:background ,grey :distant-foreground nil :extend t))))

;;;; sh-script - dark
     `(sh-heredoc ((,class (:inherit font-lock-string-face :weight normal))))
     `(sh-quoted-exec ((,class (:inherit font-lock-preprocessor-face))))

;;;; show-paren - dark
     `(show-paren-match ((,class (:inherit paren-face-match))))
     `(show-paren-mismatch ((,class (:inherit paren-face-mismatch))))

;;;; smart-mode-line - dark
     `(sml/charging ((,class (:foreground ,green))))
     `(sml/discharging ((,class (:foreground ,yellow :weight bold))))
     `(sml/filename ((,class (:foreground ,magenta :weight bold))))
     `(sml/git ((,class (:foreground ,blue))))
     `(sml/modified ((,class (:foreground ,cyan))))
     `(sml/outside-modified ((,class (:foreground ,cyan))))
     `(sml/process ((,class (:weight bold))))
     `(sml/read-only ((,class (:foreground ,cyan))))
     `(sml/sudo ((,class (:foreground ,orange :weight bold))))
     `(sml/vc-edited ((,class (:foreground ,green))))

;;;; smartparens - dark
     `(sp-pair-overlay-face ((,class (:background ,grey))))
     `(sp-show-pair-match-face ((,class (:inherit show-paren-match))))
     `(sp-show-pair-mismatch-face ((,class (:inherit show-paren-mismatch))))

;;;; smerge-tool - dark
     `(smerge-base ((,class (:background ,blue))))
     `(smerge-lower ((,class (:background ,green))))
     `(smerge-markers ((,class (:background ,spacegrey5 :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(smerge-mine ((,class (:inherit smerge-upper))))
     `(smerge-other ((,class (:inherit smerge-lower))))
     `(smerge-refined-added ((,class (:inherit diff-added :inverse-video t))))
     `(smerge-refined-removed ((,class (:inherit diff-removed :inverse-video t))))
     `(smerge-upper ((,class (:background ,red))))

;;;; solaire-mode - dark
     `(solaire-default-face ((,class (:inherit default :background ,bg-other))))
     `(solaire-hl-line-face ((,class (:inherit hl-line :background ,bg :extend t))))
     `(solaire-mode-line-face ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))
     `(solaire-mode-line-inactive-face ((,class (:background ,bg-other :foreground ,fg-other :distant-foreground ,bg-other))))
     `(solaire-org-hide-face ((,class (:inherit org-hide))))

;;;; spaceline - dark
     `(spaceline-evil-emacs ((,class (:background ,cyan))))
     `(spaceline-evil-insert ((,class (:background ,green))))
     `(spaceline-evil-motion ((,class (:background ,purple))))
     `(spaceline-evil-normal ((,class (:background ,blue))))
     `(spaceline-evil-replace ((,class (:background ,orange))))
     `(spaceline-evil-visual ((,class (:background ,grey))))
     `(spaceline-flycheck-error ((,class (:inherit error :distant-background ,spacegrey0))))
     `(spaceline-flycheck-info ((,class (:inherit success :distant-background ,spacegrey0))))
     `(spaceline-flycheck-warning ((,class (:inherit warning :distant-background ,spacegrey0))))
     `(spaceline-highlight-face ((,class (:background ,orange))))
     `(spaceline-modified ((,class (:background ,orange))))
     `(spaceline-python-venv ((,class (:foreground ,purple :distant-foreground ,magenta))))
     `(spaceline-unmodified ((,class (:background ,orange))))

;;;; stripe-buffer - dark
     `(stripe-highlight ((,class (:background ,spacegrey3))))

;;;; swiper - dark
     `(swiper-line-face ((,class (:background ,blue :foreground ,spacegrey0))))
     `(swiper-match-face-1 ((,class (:inherit unspecified :background ,spacegrey0 :foreground ,spacegrey5))))
     `(swiper-match-face-2 ((,class (:inherit unspecified :background ,orange :foreground ,spacegrey0 :weight bold))))
     `(swiper-match-face-3 ((,class (:inherit unspecified :background ,purple :foreground ,spacegrey0 :weight bold))))
     `(swiper-match-face-4 ((,class (:inherit unspecified :background ,green :foreground ,spacegrey0 :weight bold))))

;;;; tabbar - dark
     `(tabbar-button ((,class (:foreground ,fg :background ,bg))))
     `(tabbar-button-highlight ((,class (:inherit tabbar-button :inverse-video t))))
     `(tabbar-default ((,class (:foreground ,bg :background ,bg :height 1.0))))
     `(tabbar-highlight ((,class (:foreground ,fg :background ,grey :distant-foreground ,bg))))
     `(tabbar-modified ((,class (:inherit tabbar-default :foreground ,red :weight bold))))
     `(tabbar-selected ((,class (:inherit tabbar-default :weight bold :foreground ,fg :background ,bg-other))))
     `(tabbar-selected-modified ((,class (:inherit tabbar-selected :foreground ,green))))
     `(tabbar-unselected ((,class (:inherit tabbar-default :foreground ,spacegrey5))))
     `(tabbar-unselected-modified ((,class (:inherit tabbar-modified))))

;;;; tab-bar - dark
     `(tab-bar ((,class (:inherit tab-line))))
     `(tab-bar-tab ((,class (:inherit tab-line-tab))))
     `(tab-bar-tab-inactive ((,class (:inherit tab-line-tab-inactive))))

;;;; tab-line - dark
     `(tab-line ((,class (:background ,bg-other :foreground ,bg-other))))
     `(tab-line-close-highlight ((,class (:foreground ,orange))))
     `(tab-line-highlight ((,class (:inherit tab-line-tab))))
     `(tab-line-tab ((,class (:background ,bg :foreground ,fg))))
     `(tab-line-tab-current ((,class (:background ,bg :foreground ,fg))))
     `(tab-line-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; telephone-line - dark
     `(telephone-line-accent-active ((,class (:foreground ,fg :background ,spacegrey4))))
     `(telephone-line-accent-inactive ((,class (:foreground ,fg :background ,spacegrey2))))
     `(telephone-line-evil ((,class (:foreground ,fg :weight bold))))
     `(telephone-line-evil-emacs ((,class (:background ,purple :weight bold))))
     `(telephone-line-evil-insert ((,class (:background ,green :weight bold))))
     `(telephone-line-evil-motion ((,class (:background ,blue :weight bold))))
     `(telephone-line-evil-normal ((,class (:background ,red :weight bold))))
     `(telephone-line-evil-operator ((,class (:background ,magenta :weight bold))))
     `(telephone-line-evil-replace ((,class (:background ,bg-other :weight bold))))
     `(telephone-line-evil-visual ((,class (:background ,orange :weight bold))))
     `(telephone-line-projectile ((,class (:foreground ,green))))

;;;; term - dark
     `(term ((,class (:foreground ,fg))))
     `(term-bold ((,class (:weight bold))))
     `(term-color-black ((,class (:background ,spacegrey0 :foreground ,spacegrey0))))
     `(term-color-blue ((,class (:background ,blue :foreground ,blue))))
     `(term-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
     `(term-color-green ((,class (:background ,green :foreground ,green))))
     `(term-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
     `(term-color-purple ((,class (:background ,purple :foreground ,purple))))
     `(term-color-red ((,class (:background ,red :foreground ,red))))
     `(term-color-white ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))
     `(term-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

;;;; tldr - dark
     `(tldr-code-block ((,class (:foreground ,green :background ,grey :weight semi-bold))))
     `(tldr-command-argument ((,class (:foreground ,fg :background ,grey))))
     `(tldr-command-itself ((,class (:foreground ,bg :background ,green :weight semi-bold))))
     `(tldr-description ((,class (:foreground ,fg :weight semi-bold))))
     `(tldr-introduction ((,class (:foreground ,blue :weight semi-bold))))
     `(tldr-title ((,class (:foreground ,yellow :bold t :height 1.4))))

;;;; treemacs - dark
     `(treemacs-directory-face ((,class (:foreground ,fg))))
     `(treemacs-file-face ((,class (:foreground ,fg))))
     `(treemacs-git-added-face ((,class (:foreground ,green))))
     `(treemacs-git-conflict-face ((,class (:foreground ,red))))
     `(treemacs-git-modified-face ((,class (:foreground ,magenta))))
     `(treemacs-git-untracked-face ((,class (:inherit font-lock-doc-face))))
     `(treemacs-root-face ((,class (:inherit font-lock-string-face :weight bold :height 1.2))))
     `(treemacs-tags-face ((,class (:foreground ,orange))))

;;;; typescript-mode - dark
     `(typescript-jsdoc-tag ((,class (:foreground ,spacegrey5))))
     `(typescript-jsdoc-type ((,class (:foreground ,spacegrey5))))
     `(typescript-jsdoc-value ((,class (:foreground ,spacegrey5))))

;;;; undo-tree - dark
     `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,blue))))
     `(undo-tree-visualizer-current-face ((,class (:foreground ,green :weight bold))))
     `(undo-tree-visualizer-default-face ((,class (:foreground ,spacegrey5))))
     `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow))))
     `(undo-tree-visualizer-unmodified-face ((,class (:foreground ,spacegrey5))))

;;;; vimish-fold - dark
     `(vimish-fold-fringe ((,class (:foreground ,purple))))
     `(vimish-fold-overlay ((,class (:inherit font-lock-comment-face :background ,spacegrey0 :weight light))))

;;;; volatile-highlights - dark
     `(vhl/default-face ((,class (:background ,grey))))

;;;; vterm - dark
     `(vterm ((,class (:foreground ,fg))))
     `(vterm-color-black ((,class (:background ,spacegrey0 :foreground ,spacegrey0))))
     `(vterm-color-blue ((,class (:background ,blue :foreground ,blue))))
     `(vterm-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
     `(vterm-color-default ((,class (:foreground ,fg))))
     `(vterm-color-green ((,class (:background ,green :foreground ,green))))
     `(vterm-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
     `(vterm-color-purple ((,class (:background ,purple :foreground ,purple))))
     `(vterm-color-red ((,class (:background ,red :foreground ,red))))
     `(vterm-color-white ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))
     `(vterm-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

;;;; web-mode - dark
     `(web-mode-block-control-face ((,class (:foreground ,orange))))
     `(web-mode-block-control-face ((,class (:foreground ,orange))))
     `(web-mode-block-delimiter-face ((,class (:foreground ,orange))))
     `(web-mode-css-property-name-face ((,class (:foreground ,yellow))))
     `(web-mode-doctype-face ((,class (:foreground ,spacegrey5))))
     `(web-mode-html-attr-name-face ((,class (:foreground ,yellow))))
     `(web-mode-html-attr-value-face ((,class (:foreground ,green))))
     `(web-mode-html-entity-face ((,class (:foreground ,cyan :inherit italic))))
     `(web-mode-html-tag-bracket-face ((,class (:foreground ,blue))))
     `(web-mode-html-tag-bracket-face ((,class (:foreground ,fg))))
     `(web-mode-html-tag-face ((,class (:foreground ,blue))))
     `(web-mode-json-context-face ((,class (:foreground ,green))))
     `(web-mode-json-key-face ((,class (:foreground ,green))))
     `(web-mode-keyword-face ((,class (:foreground ,magenta))))
     `(web-mode-string-face ((,class (:foreground ,green))))
     `(web-mode-type-face ((,class (:foreground ,yellow))))

;;;; wgrep - dark
     `(wgrep-delete-face ((,class (:foreground ,spacegrey3 :background ,red))))
     `(wgrep-done-face ((,class (:foreground ,blue))))
     `(wgrep-face ((,class (:weight bold :foreground ,green :background ,spacegrey5))))
     `(wgrep-file-face ((,class (:foreground ,spacegrey5))))
     `(wgrep-reject-face ((,class (:foreground ,red :weight bold))))

;;;; which-func - dark
     `(which-func ((,class (:foreground ,blue))))

;;;; which-key - dark
     `(which-key-command-description-face ((,class (:foreground ,blue))))
     `(which-key-group-description-face ((,class (:foreground ,magenta))))
     `(which-key-key-face ((,class (:foreground ,green))))
     `(which-key-local-map-description-face ((,class (:foreground ,purple))))

;;;; whitespace - dark
     `(whitespace-empty ((,class (:background ,spacegrey3))))
     `(whitespace-indentation ((,class (:foreground ,spacegrey4 :background ,spacegrey3))))
     `(whitespace-line ((,class (:background ,spacegrey0 :foreground ,red :weight bold))))
     `(whitespace-newline ((,class (:foreground ,spacegrey4))))
     `(whitespace-space ((,class (:foreground ,spacegrey4))))
     `(whitespace-tab ((,class (:foreground ,spacegrey4 :background ,spacegrey3))))
     `(whitespace-trailing ((,class (:inherit trailing-whitespace))))

;;;; widget - dark
     `(widget-button ((,class (:foreground ,fg :weight bold))))
     `(widget-button-pressed ((,class (:foreground ,red))))
     `(widget-documentation ((,class (:foreground ,green))))
     `(widget-field ((,class (:foreground ,fg :background ,spacegrey0 :extend nil))))
     `(widget-inactive ((,class (:foreground ,grey :background ,bg-other))))
     `(widget-single-line-field ((,class (:foreground ,fg :background ,spacegrey0))))

;;;; window-divider - dark
     `(window-divider ((,class (:inherit vertical-border))))
     `(window-divider-first-pixel ((,class (:inherit window-divider))))
     `(window-divider-last-pixel ((,class (:inherit window-divider))))

;;;; woman - dark
     `(woman-bold ((,class (:inherit bold :foreground ,fg))))
     `(woman-italic ((,class (:inherit underline :foreground ,magenta))))

;;;; workgroups2 - dark
     `(wg-brace-face ((,class (:foreground ,orange))))
     `(wg-current-workgroup-face ((,class (:foreground ,spacegrey0 :background ,orange))))
     `(wg-divider-face ((,class (:foreground ,grey))))
     `(wg-other-workgroup-face ((,class (:foreground ,spacegrey5))))

;;;; yasnippet - dark
     `(yas-field-highlight-face ((,class (:inherit match))))

     (custom-theme-set-variables
      'timu-spacegrey
      `(ansi-color-names-vector [bg, red, green, teal, cyan, blue, yellow, fg])))))

;;; LIGHT FLAVOUR
(when (equal timu-spacegrey-flavour "light")
  (let ((class '((class color) (min-colors 89)))
        (bg "#ffffff")
        (bg-org "#fafafa")
        (bg-other "#dfdfdf")
        (spacegrey0 "#1b2229")
        (spacegrey1 "#1c1f24")
        (spacegrey2 "#202328")
        (spacegrey3 "#2f3237")
        (spacegrey4 "#4f5b66")
        (spacegrey5 "#65737e")
        (spacegrey6 "#73797e")
        (spacegrey7 "#9ca0a4")
        (spacegrey8 "#dfdfdf")
        (fg "#2b303b")
        (fg-other "#232830")

        (grey "#4f5b66")
        (red "#bf616a")
        (orange "#d08770")
        (green "#a3be8c")
        (blue "#8fa1b3")
        (magenta "#b48ead")
        (teal "#4db5bd")
        (yellow "#ecbe7b")
        (darkblue "#2257a0")
        (purple "#c678dd")
        (cyan "#46d9ff")
        (darkcyan "#5699af"))

    (custom-theme-set-faces
     'timu-spacegrey

;;; Custom faces - light

;;;; default faces - light
     `(bold ((,class (:weight bold))))
     `(bold-italic ((,class (:inherit (bold italic)))))
     `(bookmark-face ((,class (:foreground ,magenta  :weight bold :underline ,darkcyan))))
     `(cursor ((,class (:background ,orange))))
     `(default ((,class (:background ,bg :foreground ,fg))))
     `(error ((,class (:foreground ,red))))
     `(fringe ((,class (:inherit default :foreground ,spacegrey4))))
     `(highlight ((,class (:foreground ,magenta  :weight bold :underline ,darkcyan))))
     `(italic ((,class (:slant  italic))))
     `(lazy-highlight ((,class (:background ,darkblue  :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(link ((,class (:foreground ,orange :underline t :weight bold))))
     `(match ((,class (:foreground ,green :background ,spacegrey0 :weight bold))))
     `(minibuffer-prompt ((,class (:foreground ,orange))))
     `(nobreak-space ((,class (:inherit default :underline nil))))
     `(region ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
     `(secondary-selection ((,class (:background ,grey :extend t))))
     `(shadow ((,class (:foreground ,spacegrey5))))
     `(success ((,class (:foreground ,green))))
     `(tooltip ((,class (:background ,bg-other :foreground ,fg))))
     `(trailing-whitespace ((,class (:background ,red))))
     `(vertical-border ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))
     `(warning ((,class (:foreground ,yellow))))

;;;; font-lock - light
     `(font-lock-builtin-face ((,class (:foreground ,orange))))
     `(font-lock-comment-delimiter-face ((,class (:inherit font-lock-comment-face))))
     `(font-lock-comment-face ((,class (:foreground ,spacegrey5))))
     `(font-lock-constant-face ((,class (:foreground ,orange))))
     `(font-lock-doc-face ((,class (:inherit font-lock-comment-face :foreground ,spacegrey5))))
     `(font-lock-function-name-face ((,class (:foreground ,blue))))
     `(font-lock-keyword-face ((,class (:foreground ,magenta))))
     `(font-lock-negation-char-face ((,class (:inherit bold :foreground ,fg))))
     `(font-lock-preprocessor-char-face ((,class (:inherit bold :foreground ,fg))))
     `(font-lock-preprocessor-face ((,class (:inherit bold :foreground ,fg))))
     `(font-lock-regexp-grouping-backslash ((,class (:inherit bold :foreground ,fg))))
     `(font-lock-regexp-grouping-construct ((,class (:inherit bold :foreground ,fg))))
     `(font-lock-string-face ((,class (:foreground ,green))))
     `(font-lock-type-face ((,class (:foreground ,yellow))))
     `(font-lock-variable-name-face ((,class (:foreground ,red))))
     `(font-lock-warning-face ((,class (:inherit warning))))

;;;; ace-window - light
     `(aw-leading-char-face ((,class (:foreground ,orange :height 500 :weight bold))))
     `(aw-background-face ((,class (:foreground ,spacegrey5))))

;;;; agda-mode - light
     `(agda2-highlight-bound-variable-face ((,class (:inherit font-lock-variable-name-face))))
     `(agda2-highlight-coinductive-constructor-face ((,class (:inherit font-lock-type-face))))
     `(agda2-highlight-datatype-face ((,class (:inherit font-lock-type-face))))
     `(agda2-highlight-dotted-face ((,class (:inherit font-lock-variable-name-face))))
     `(agda2-highlight-error-face ((,class (:inherit font-lock-warning-face))))
     `(agda2-highlight-field-face ((,class (:inherit font-lock-type-face))))
     `(agda2-highlight-function-face ((,class (:inherit font-lock-function-name-face))))
     `(agda2-highlight-incomplete-pattern-face ((,class (:inherit font-lock-warning-face))))
     `(agda2-highlight-inductive-constructor-face ((,class (:inherit font-lock-type-face))))
     `(agda2-highlight-keyword-face ((,class (:inherit font-lock-keyword-face))))
     `(agda2-highlight-macro-face ((,class (:inherit font-lock-function-name-face))))
     `(agda2-highlight-module-face ((,class (:inherit font-lock-variable-name-face))))
     `(agda2-highlight-number-face ((,class (:inherit font-lock-string-face))))
     `(agda2-highlight-positivity-problem-face ((,class (:inherit font-lock-warning-face))))
     `(agda2-highlight-postulate-face ((,class (:inherit font-lock-type-face))))
     `(agda2-highlight-primitive-face ((,class (:inherit font-lock-type-face))))
     `(agda2-highlight-primitive-type-face ((,class (:inherit font-lock-type-face))))
     `(agda2-highlight-record-face ((,class (:inherit font-lock-type-face))))
     `(agda2-highlight-string-face ((,class (:inherit font-lock-string-face))))
     `(agda2-highlight-symbol-face ((,class (:inherit font-lock-variable-name-face))))
     `(agda2-highlight-termination-problem-face ((,class (:inherit font-lock-warning-face))))
     `(agda2-highlight-typechecks-face ((,class (:inherit font-lock-warning-face))))
     `(agda2-highlight-unsolved-constraint-face ((,class (:inherit font-lock-warning-face))))
     `(agda2-highlight-unsolved-meta-face ((,class (:inherit font-lock-warning-face))))

;;;; alert - light
     `(alert-high-face ((,class (:inherit bold :foreground ,yellow))))
     `(alert-low-face ((,class (:foreground ,grey))))
     `(alert-moderate-face ((,class (:inherit bold :foreground ,fg-other))))
     `(alert-trivial-face ((,class (:foreground ,spacegrey5))))
     `(alert-urgent-face ((,class (:inherit bold :foreground ,red))))

;;;; all-the-icons - light
     `(all-the-icons-blue ((,class (:foreground ,blue))))
     `(all-the-icons-blue-alt ((,class (:foreground ,teal))))
     `(all-the-icons-cyan ((,class (:foreground ,cyan))))
     `(all-the-icons-cyan-alt ((,class (:foreground ,cyan))))
     `(all-the-icons-dblue ((,class (:foreground ,darkblue))))
     `(all-the-icons-dcyan ((,class (:foreground ,darkcyan))))
     `(all-the-icons-dgreen ((,class (:foreground ,green))))
     `(all-the-icons-dmagenta ((,class (:foreground ,red))))
     `(all-the-icons-dmaroon ((,class (:foreground ,purple))))
     `(all-the-icons-dorange ((,class (:foreground ,orange))))
     `(all-the-icons-dpurple ((,class (:foreground ,magenta))))
     `(all-the-icons-dred ((,class (:foreground ,red))))
     `(all-the-icons-dsilver ((,class (:foreground ,grey))))
     `(all-the-icons-dyellow ((,class (:foreground ,yellow))))
     `(all-the-icons-green ((,class (:foreground ,green))))
     `(all-the-icons-lblue ((,class (:foreground ,blue))))
     `(all-the-icons-lcyan ((,class (:foreground ,cyan))))
     `(all-the-icons-lgreen ((,class (:foreground ,green))))
     `(all-the-icons-lmagenta ((,class (:foreground ,red))))
     `(all-the-icons-lmaroon ((,class (:foreground ,purple))))
     `(all-the-icons-lorange ((,class (:foreground ,orange))))
     `(all-the-icons-lpurple ((,class (:foreground ,magenta))))
     `(all-the-icons-lred ((,class (:foreground ,red))))
     `(all-the-icons-lsilver ((,class (:foreground ,grey))))
     `(all-the-icons-lyellow ((,class (:foreground ,yellow))))
     `(all-the-icons-magenta ((,class (:foreground ,red))))
     `(all-the-icons-maroon ((,class (:foreground ,purple))))
     `(all-the-icons-orange ((,class (:foreground ,orange))))
     `(all-the-icons-purple ((,class (:foreground ,magenta))))
     `(all-the-icons-purple-alt ((,class (:foreground ,magenta))))
     `(all-the-icons-red ((,class (:foreground ,red))))
     `(all-the-icons-red-alt ((,class (:foreground ,red))))
     `(all-the-icons-silver ((,class (:foreground ,grey))))
     `(all-the-icons-yellow ((,class (:foreground ,yellow))))

;;;; all-the-icons-dired - light
     `(all-the-icons-dired-dir-face ((,class (:foreground ,fg-other))))

;;;; all-the-icons-ivy-rich - light
     `(all-the-icons-ivy-rich-doc-face ((,class (:foreground ,blue))))
     `(all-the-icons-ivy-rich-path-face ((,class (:foreground ,blue))))
     `(all-the-icons-ivy-rich-size-face ((,class (:foreground ,blue))))
     `(all-the-icons-ivy-rich-time-face ((,class (:foreground ,blue))))

;;;; annotate - light
     `(annotate-annotation ((,class (:background ,orange :foreground ,spacegrey5))))
     `(annotate-annotation-secondary ((,class (:background ,green :foreground ,spacegrey5))))
     `(annotate-highlight ((,class (:background ,orange :underline ,orange))))
     `(annotate-highlight-secondary ((,class (:background ,green :underline ,green))))

;;;; anzu - light
     `(anzu-replace-highlight ((,class (:background ,spacegrey0 :foreground ,red :weight bold :strike-through t))))
     `(anzu-replace-to ((,class (:background ,spacegrey0 :foreground ,green :weight bold))))

;;;; auctex - light
     `(TeX-error-description-error ((,class (:inherit error :weight bold))))
     `(TeX-error-description-tex-said ((,class (:inherit success :weight bold))))
     `(TeX-error-description-warning ((,class (:inherit warning :weight bold))))
     `(font-latex-bold-face ((,class (:inherit bold))))
     `(font-latex-italic-face ((,class (:inherit italic))))
     `(font-latex-math-face ((,class (:foreground ,blue))))
     `(font-latex-script-char-face ((,class (:foreground ,darkblue))))
     `(font-latex-sectioning-0-face ((,class (:foreground ,blue :weight ultra-bold))))
     `(font-latex-sectioning-1-face ((,class (:foreground ,purple :weight semi-bold))))
     `(font-latex-sectioning-2-face ((,class (:foreground ,magenta :weight semi-bold))))
     `(font-latex-sectioning-3-face ((,class (:foreground ,blue :weight semi-bold))))
     `(font-latex-sectioning-4-face ((,class (:foreground ,purple :weight semi-bold))))
     `(font-latex-sectioning-5-face ((,class (:foreground ,magenta :weight semi-bold))))
     `(font-latex-string-face ((,class (:inherit font-lock-string-face))))
     `(font-latex-verbatim-face ((,class (:inherit fixed-pitch :foreground ,magenta :slant italic))))
     `(font-latex-warning-face ((,class (:inherit font-lock-warning-face))))

;;;; avy - light
     `(avy-background-face ((,class (:foreground ,spacegrey5))))
     `(avy-lead-face ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(avy-lead-face-0 ((,class (:inherit avy-lead-face :background ,orange))))
     `(avy-lead-face-1 ((,class (:inherit avy-lead-face :background ,orange))))
     `(avy-lead-face-2 ((,class (:inherit avy-lead-face :background ,orange))))

;;;; bookmark+ - light
     `(bmkp-*-mark ((,class (:foreground ,bg :background ,yellow))))
     `(bmkp->-mark ((,class (:foreground ,yellow))))
     `(bmkp-D-mark ((,class (:foreground ,bg :background ,red))))
     `(bmkp-X-mark ((,class (:foreground ,red))))
     `(bmkp-a-mark ((,class (:background ,red))))
     `(bmkp-bad-bookmark ((,class (:foreground ,bg :background ,yellow))))
     `(bmkp-bookmark-file ((,class (:foreground ,magenta :background ,bg-other))))
     `(bmkp-bookmark-list ((,class (:background ,bg-other))))
     `(bmkp-buffer ((,class (:foreground ,blue))))
     `(bmkp-desktop ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-file-handler ((,class (:background ,red))))
     `(bmkp-function ((,class (:foreground ,green))))
     `(bmkp-gnus ((,class (:foreground ,orange))))
     `(bmkp-heading ((,class (:foreground ,yellow))))
     `(bmkp-info ((,class (:foreground ,cyan))))
     `(bmkp-light-autonamed ((,class (:foreground ,bg-other :background ,cyan))))
     `(bmkp-light-autonamed-region ((,class (:foreground ,bg-other :background ,red))))
     `(bmkp-light-fringe-autonamed ((,class (:foreground ,bg-other :background ,magenta))))
     `(bmkp-light-fringe-non-autonamed ((,class (:foreground ,bg-other :background ,green))))
     `(bmkp-light-mark ((,class (:foreground ,bg :background ,cyan))))
     `(bmkp-light-non-autonamed ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-light-non-autonamed-region ((,class (:foreground ,bg :background ,red))))
     `(bmkp-local-directory ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-local-file-with-region ((,class (:foreground ,yellow))))
     `(bmkp-local-file-without-region ((,class (:foreground ,spacegrey5))))
     `(bmkp-man ((,class (:foreground ,magenta))))
     `(bmkp-no-jump ((,class (:foreground ,spacegrey5))))
     `(bmkp-no-local ((,class (:foreground ,yellow))))
     `(bmkp-non-file ((,class (:foreground ,green))))
     `(bmkp-remote-file ((,class (:foreground ,orange))))
     `(bmkp-sequence ((,class (:foreground ,blue))))
     `(bmkp-su-or-sudo ((,class (:foreground ,red))))
     `(bmkp-t-mark ((,class (:foreground ,magenta))))
     `(bmkp-url ((,class (:foreground ,blue :underline t))))
     `(bmkp-variable-list ((,class (:foreground ,green))))

;;;; calfw - light
     `(cfw:face-annotation ((,class (:foreground ,magenta))))
     `(cfw:face-day-title ((,class (:foreground ,fg :weight bold))))
     `(cfw:face-default-content ((,class (:foreground ,fg))))
     `(cfw:face-default-day ((,class (:weight bold))))
     `(cfw:face-disable ((,class (:foreground ,grey))))
     `(cfw:face-grid ((,class (:foreground ,bg))))
     `(cfw:face-header ((,class (:foreground ,blue :weight bold))))
     `(cfw:face-holiday ((,class (:foreground nil :background ,bg-other :weight bold))))
     `(cfw:face-periods ((,class (:foreground ,yellow))))
     `(cfw:face-saturday ((,class (:foreground ,red :weight bold))))
     `(cfw:face-select ((,class (:background ,grey))))
     `(cfw:face-sunday ((,class (:foreground ,red :weight bold))))
     `(cfw:face-title ((,class (:foreground ,blue :weight bold :height 2.0 :inherit variable-pitch))))
     `(cfw:face-today ((,class (:foreground nil :background nil :weight bold))))
     `(cfw:face-today-title ((,class (:foreground ,bg :background ,blue :weight bold))))
     `(cfw:face-toolbar ((,class (:foreground nil :background nil))))
     `(cfw:face-toolbar-button-off ((,class (:foreground ,spacegrey6 :weight bold :inherit variable-pitch))))
     `(cfw:face-toolbar-button-on ((,class (:foreground ,blue :weight bold :inherit variable-pitch))))

;;;; centaur-tabs - light
     `(centaur-tabs-active-bar-face ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-close-mouse-face ((,class (:foreground ,orange))))
     `(centaur-tabs-close-selected ((,class (:inherit centaur-tabs-selected))))
     `(centaur-tabs-close-unselected ((,class (:inherit centaur-tabs-unselected))))
     `(centaur-tabs-default ((,class (:background ,bg-other :foreground ,fg))))
     `(centaur-tabs-modified-marker-selected ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-modified-marker-unselected ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-selected ((,class (:background ,bg :foreground ,fg))))
     `(centaur-tabs-selected-modified ((,class (:background ,bg :foreground ,red))))
     `(centaur-tabs-unselected ((,class (:background ,bg-other :foreground ,grey))))
     `(centaur-tabs-unselected-modified ((,class (:background ,bg-other :foreground ,red))))

;;;; circe - light
     `(circe-fool ((,class (:foreground ,spacegrey5))))
     `(circe-highlight-nick-face ((,class (:weight bold :foreground ,orange))))
     `(circe-my-message-face ((,class (:weight bold))))
     `(circe-prompt-face ((,class (:weight bold :foreground ,orange))))
     `(circe-server-face ((,class (:foreground ,spacegrey5))))

;;;; company - light
     `(company-preview ((,class (:foreground ,spacegrey5))))
     `(company-preview-common ((,class (:background ,spacegrey3 :foreground ,orange))))
     `(company-preview-search ((,class (:inherit company-tooltip-search))))
     `(company-scrollbar-bg ((,class (:inherit tooltip))))
     `(company-scrollbar-fg ((,class (:background ,orange))))
     `(company-template-field ((,class (:inherit match))))
     `(company-tooltip ((,class (:inherit tooltip))))
     `(company-tooltip-annotation ((,class (:foreground ,magenta :distant-foreground ,bg))))
     `(company-tooltip-common ((,class (:foreground ,orange :distant-foreground ,spacegrey0 :weight bold))))
     `(company-tooltip-mouse ((,class (:background ,purple :foreground ,bg :distant-foreground ,fg))))
     `(company-tooltip-search ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(company-tooltip-search-selection ((,class (:background ,grey))))
     `(company-tooltip-selection ((,class (:background ,grey :weight bold))))

;;;; company-box - light
     `(company-box-candidate ((,class (:foreground ,fg))))

;;;; compilation - light
     `(compilation-column-number ((,class (:inherit font-lock-comment-face))))
     `(compilation-error ((,class (:inherit error :weight bold))))
     `(compilation-info ((,class (:inherit success))))
     `(compilation-line-number ((,class (:foreground ,orange))))
     `(compilation-mode-line-exit ((,class (:inherit compilation-info))))
     `(compilation-mode-line-fail ((,class (:inherit compilation-error))))
     `(compilation-warning ((,class (:inherit warning :slant italic))))

;;;; counsel - light
     `(counsel-variable-documentation ((,class (:foreground ,blue))))

;;;; cperl - light
     `(cperl-array-face ((,class (:weight bold :inherit font-lock-variable-name-face))))
     `(cperl-hash-face ((,class (:weight bold :slant italic :inherit font-lock-variable-name-face))))
     `(cperl-nonoverridable-face ((,class (:inherit font-lock-builtin-face))))

;;;; custom - light
     `(custom-button ((,class (:foreground ,fg :background ,bg-other :box (:line-width 3 :style released-button)))))
     `(custom-button-mouse ((,class (:foreground ,yellow :background ,bg-other :box (:line-width 3 :style released-button)))))
     `(custom-button-pressed ((,class (:foreground ,fg :background ,bg-other :box (:line-width 3 :style pressed-button)))))
     `(custom-button-pressed-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
     `(custom-button-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
     `(custom-changed ((,class (:foreground ,blue :background ,bg))))
     `(custom-comment ((,class (:foreground ,fg :background ,grey))))
     `(custom-comment-tag ((,class (:foreground ,grey))))
     `(custom-documentation ((,class (:foreground ,fg))))
     `(custom-face-tag ((,class (:foreground ,blue :weight bold)))) ; done
     `(custom-group-subtitle ((,class (:foreground ,red :weight bold))))
     `(custom-group-tag ((,class (:foreground ,red :weight bold)))) ; done
     `(custom-group-tag-1 ((,class (:foreground ,blue :weight bold))))
     `(custom-invalid ((,class (:foreground ,red))))
     `(custom-link ((,class (:foreground ,orange :underline t :weight bold)))) ; done
     `(custom-modified ((,class (:foreground ,blue))))
     `(custom-rogue ((,class (:foreground ,blue :box (:line-width 3 :style none)))))
     `(custom-saved ((,class (:foreground ,green :weight bold))))
     `(custom-set ((,class (:foreground ,yellow :background ,bg))))
     `(custom-state ((,class (:foreground ,green :weight bold))))
     `(custom-themed ((,class (:foreground ,yellow :background ,bg))))
     `(custom-variable-button ((,class (:foreground ,green :underline t))))
     `(custom-variable-obsolete ((,class (:foreground ,grey :background ,bg))))
     `(custom-variable-tag ((,class (:foreground ,darkcyan :weight bold))))
     `(custom-visibility ((,class (:foreground ,orange :height 0.8 :weight bold :underline t)))) ; done

;;;; diff-hl - light
     `(diff-hl-change ((,class (:foreground ,orange :background ,orange))))
     `(diff-hl-delete ((,class (:foreground ,red :background ,red))))
     `(diff-hl-insert ((,class (:foreground ,green :background ,green))))

;;;; dired - light
     `(dired-directory ((,class (:foreground ,darkcyan))))
     `(dired-flagged ((,class (:foreground ,red))))
     `(dired-header ((,class (:foreground ,orange :weight bold :underline ,darkcyan))))
     `(dired-ignored ((,class (:foreground ,spacegrey5))))
     `(dired-mark ((,class (:foreground ,orange :weight bold))))
     `(dired-marked ((,class (:foreground ,yellow :weight bold))))
     `(dired-perm-write ((,class (:foreground ,red :underline t))))
     `(dired-symlink ((,class (:foreground ,magenta))))
     `(dired-warning ((,class (:foreground ,yellow))))

;;;; dired-async - light
     `(dired-async-failures ((,class (:foreground ,red))))
     `(dired-async-message ((,class (:foreground ,orange))))
     `(dired-async-mode-message ((,class (:foreground ,orange))))

;;;; dired+ - light
     `(diredp-compressed-file-suffix ((,class (:foreground ,spacegrey5))))
     `(diredp-date-time ((,class (:foreground ,blue))))
     `(diredp-dir-heading ((,class (:foreground ,blue :weight bold))))
     `(diredp-dir-name ((,class (:foreground ,spacegrey8 :weight bold))))
     `(diredp-dir-priv ((,class (:foreground ,blue :weight bold))))
     `(diredp-exec-priv ((,class (:foreground ,yellow))))
     `(diredp-file-name ((,class (:foreground ,spacegrey8))))
     `(diredp-file-suffix ((,class (:foreground ,magenta))))
     `(diredp-ignored-file-name ((,class (:foreground ,spacegrey5))))
     `(diredp-no-priv ((,class (:foreground ,spacegrey5))))
     `(diredp-number ((,class (:foreground ,purple))))
     `(diredp-rare-priv ((,class (:foreground ,red :weight bold))))
     `(diredp-read-priv ((,class (:foreground ,purple))))
     `(diredp-symlink ((,class (:foreground ,magenta))))
     `(diredp-write-priv ((,class (:foreground ,green))))

;;;; dired-k - light
     `(dired-k-added ((,class (:foreground ,green :weight bold))))
     `(dired-k-commited ((,class (:foreground ,green :weight bold))))
     `(dired-k-directory ((,class (:foreground ,blue :weight bold))))
     `(dired-k-ignored ((,class (:foreground ,spacegrey5 :weight bold))))
     `(dired-k-modified ((,class (:foreground ,orange :weight bold))))
     `(dired-k-untracked ((,class (:foreground ,teal :weight bold))))

;;;; dired-subtree - light
     `(dired-subtree-depth-1-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-2-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-3-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-4-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-5-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-6-face ((,class (:background ,bg-other))))

;;;; diredfl - light
     `(diredfl-autofile-name ((,class (:foreground ,spacegrey4))))
     `(diredfl-compressed-file-name ((,class (:foreground ,orange))))
     `(diredfl-compressed-file-suffix ((,class (:foreground ,yellow))))
     `(diredfl-date-time ((,class (:foreground ,cyan :weight light))))
     `(diredfl-deletion ((,class (:foreground ,red :weight bold))))
     `(diredfl-deletion-file-name ((,class (:foreground ,red))))
     `(diredfl-dir-heading ((,class (:foreground ,blue :weight bold))))
     `(diredfl-dir-name ((,class (:foreground ,darkcyan))))
     `(diredfl-dir-priv ((,class (:foreground ,blue))))
     `(diredfl-exec-priv ((,class (:foreground ,red))))
     `(diredfl-executable-tag ((,class (:foreground ,red))))
     `(diredfl-file-name ((,class (:foreground ,fg))))
     `(diredfl-file-suffix ((,class (:foreground ,teal))))
     `(diredfl-flag-mark ((,class (:foreground ,yellow :background ,yellow :weight bold))))
     `(diredfl-flag-mark-line ((,class (:background ,yellow))))
     `(diredfl-ignored-file-name ((,class (:foreground ,spacegrey5))))
     `(diredfl-link-priv ((,class (:foreground ,magenta))))
     `(diredfl-no-priv ((,class (:foreground ,fg))))
     `(diredfl-number ((,class (:foreground ,orange))))
     `(diredfl-other-priv ((,class (:foreground ,purple))))
     `(diredfl-rare-priv ((,class (:foreground ,fg))))
     `(diredfl-read-priv ((,class (:foreground ,yellow))))
     `(diredfl-symlink ((,class (:foreground ,magenta))))
     `(diredfl-tagged-autofile-name ((,class (:foreground ,spacegrey5))))
     `(diredfl-write-priv ((,class (:foreground ,red))))

;;;; doom-modeline - light
     `(doom-modeline-bar-inactive ((,class (:background nil))))
     `(doom-modeline-eldoc-bar ((,class (:background ,green))))

;;;; ediff - light
     `(ediff-current-diff-A ((,class (:background ,grey :extend t))))
     `(ediff-current-diff-B ((,class (:inherit ediff-current-diff-A))))
     `(ediff-current-diff-C ((,class (:inherit ediff-current-diff-A))))
     `(ediff-even-diff-A ((,class (:inherit hl-line))))
     `(ediff-even-diff-B ((,class (:inherit ediff-even-diff-A))))
     `(ediff-even-diff-C ((,class (:inherit ediff-even-diff-A))))
     `(ediff-fine-diff-A ((,class (:background ,bg :weight bold :extend t))))
     `(ediff-fine-diff-B ((,class (:inherit ediff-fine-diff-A))))
     `(ediff-fine-diff-C ((,class (:inherit ediff-fine-diff-A))))
     `(ediff-odd-diff-A ((,class (:inherit ediff-even-diff-A))))
     `(ediff-odd-diff-B ((,class (:inherit ediff-odd-diff-A))))
     `(ediff-odd-diff-C ((,class (:inherit ediff-odd-diff-A))))

;;;; elfeed - light
     `(elfeed-log-debug-level-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-log-error-level-face ((,class (:inherit error))))
     `(elfeed-log-info-level-face ((,class (:inherit success))))
     `(elfeed-log-warn-level-face ((,class (:inherit warning))))
     `(elfeed-search-date-face ((,class (:foreground ,magenta))))
     `(elfeed-search-feed-face ((,class (:foreground ,blue))))
     `(elfeed-search-filter-face ((,class (:foreground ,magenta))))
     `(elfeed-search-tag-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-search-title-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-search-unread-count-face ((,class (:foreground ,yellow))))
     `(elfeed-search-unread-title-face ((,class (:foreground ,fg :weight bold))))

;;;; elixir-mode - light
     `(elixir-atom-face ((,class (:foreground ,cyan))))
     `(elixir-attribute-face ((,class (:foreground ,magenta))))

;;;; elscreen - light
     `(elscreen-tab-background-face ((,class (:background ,bg))))
     `(elscreen-tab-control-face ((,class (:background ,bg :foreground ,bg))))
     `(elscreen-tab-current-screen-face ((,class (:background ,bg-other :foreground ,fg))))
     `(elscreen-tab-other-screen-face ((,class (:background ,bg :foreground ,fg-other))))

;;;; enh-ruby-mode - light
     `(enh-ruby-heredoc-delimiter-face ((,class (:inherit font-lock-string-face))))
     `(enh-ruby-op-face ((,class (:foreground ,fg))))
     `(enh-ruby-regexp-delimiter-face ((,class (:inherit enh-ruby-regexp-face))))
     `(enh-ruby-regexp-face ((,class (:foreground ,orange))))
     `(enh-ruby-string-delimiter-face ((,class (:inherit font-lock-string-face))))
     `(erm-syn-errline ((,class (:underline (:style wave :color ,red)))))
     `(erm-syn-warnline ((,class (:underline (:style wave :color ,yellow)))))

;;;; erc - light
     `(erc-action-face  ((,class (:weight bold))))
     `(erc-button ((,class (:weight bold :underline t))))
     `(erc-command-indicator-face ((,class (:weight bold))))
     `(erc-current-nick-face ((,class (:foreground ,green :weight bold))))
     `(erc-default-face ((,class (:inherit default))))
     `(erc-direct-msg-face ((,class (:foreground ,purple))))
     `(erc-error-face ((,class (:inherit error))))
     `(erc-header-line ((,class (:background ,bg-other :foreground ,orange))))
     `(erc-input-face ((,class (:foreground ,green))))
     `(erc-my-nick-face ((,class (:foreground ,green :weight bold))))
     `(erc-my-nick-prefix-face ((,class (:inherit erc-my-nick-face))))
     `(erc-nick-default-face ((,class (:weight bold))))
     `(erc-nick-msg-face ((,class (:foreground ,purple))))
     `(erc-nick-prefix-face ((,class (:inherit erc-nick-default-face))))
     `(erc-notice-face ((,class (:foreground ,spacegrey5))))
     `(erc-prompt-face ((,class (:foreground ,orange :weight bold))))
     `(erc-timestamp-face ((,class (:foreground ,blue :weight bold))))

;;;; eshell - light
     `(eshell-ls-archive ((,class (:foreground ,purple))))
     `(eshell-ls-backup ((,class (:foreground ,yellow))))
     `(eshell-ls-clutter ((,class (:foreground ,red))))
     `(eshell-ls-directory ((,class (:foreground ,blue))))
     `(eshell-ls-executable ((,class (:foreground ,green))))
     `(eshell-ls-missing ((,class (:foreground ,red))))
     `(eshell-ls-product ((,class (:foreground ,orange))))
     `(eshell-ls-readonly ((,class (:foreground ,orange))))
     `(eshell-ls-special ((,class (:foreground ,magenta))))
     `(eshell-ls-symlink ((,class (:foreground ,cyan))))
     `(eshell-ls-unreadable ((,class (:foreground ,spacegrey5))))
     `(eshell-prompt ((,class (:foreground ,orange :weight bold))))

;;;; evil - light
     `(evil-ex-info ((,class (:foreground ,red :slant italic))))
     `(evil-ex-search ((,class (:background ,orange :foreground ,spacegrey0 :weight bold))))
     `(evil-ex-substitute-matches ((,class (:background ,spacegrey0 :foreground ,red :weight bold :strike-through t))))
     `(evil-ex-substitute-replacement ((,class (:background ,spacegrey0 :foreground ,green :weight bold))))
     `(evil-search-highlight-persist-highlight-face ((,class (:inherit lazy-highlight))))

;;;; evil-googles - light
     `(evil-goggles-default-face ((,class (:inherit region))))

;;;; evil-mc - light
     `(evil-mc-cursor-bar-face ((,class (:height 1 :background ,purple :foreground ,spacegrey0))))
     `(evil-mc-cursor-default-face ((,class (:background ,purple :foreground ,spacegrey0 :inverse-video nil))))
     `(evil-mc-cursor-hbar-face ((,class (:underline (:color ,orange)))))
     `(evil-mc-region-face ((,class (:inherit region))))

;;;; evil-snipe - light
     `(evil-snipe-first-match-face ((,class (:foreground ,orange :background ,darkblue :weight bold))))
     `(evil-snipe-matches-face ((,class (:foreground ,orange :underline t :weight bold))))

;;;; flx-ido - light
     `(flx-highlight-face ((,class (:weight bold :foreground ,yellow :underline nil))))

;;;; flycheck - light
     `(flycheck-error ((,class (:underline (:style wave :color ,red)))))
     `(flycheck-fringe-error ((,class (:inherit fringe :foreground ,red))))
     `(flycheck-fringe-info ((,class (:inherit fringe :foreground ,green))))
     `(flycheck-fringe-warning ((,class (:inherit fringe :foreground ,yellow))))
     `(flycheck-info ((,class (:underline (:style wave :color ,green)))))
     `(flycheck-warning ((,class (:underline (:style wave :color ,yellow)))))

;;;; flycheck-posframe - light
     `(flycheck-posframe-background-face ((,class (:background ,bg-other))))
     `(flycheck-posframe-error-face ((,class (:inherit flycheck-posframe-face :foreground ,red))))
     `(flycheck-posframe-face ((,class (:inherit default))))
     `(flycheck-posframe-info-face ((,class (:inherit flycheck-posframe-face :foreground ,fg))))
     `(flycheck-posframe-warning-face ((,class (:inherit flycheck-posframe-face :foreground ,yellow))))

;;;; flymake - light
     `(flymake-error ((,class (:underline (:style wave :color ,red)))))
     `(flymake-note ((,class (:underline (:style wave :color ,green)))))
     `(flymake-warning ((,class (:underline (:style wave :color ,orange)))))

;;;; flyspell - light
     `(flyspell-duplicate ((,class (:underline (:style wave :color ,yellow) :inherit unspecified))))
     `(flyspell-incorrect ((,class (:underline (:style wave :color ,red) :inherit unspecified))))

;;;; forge - light
     `(forge-topic-closed ((,class (:foreground ,spacegrey5 :strike-through t))))
     `(forge-topic-label ((,class (:box nil))))

;;;; git-commit - light
     `(git-commit-comment-branch-local ((,class (:foreground ,purple))))
     `(git-commit-comment-branch-remote ((,class (:foreground ,green))))
     `(git-commit-comment-detached ((,class (:foreground ,orange))))
     `(git-commit-comment-file ((,class (:foreground ,magenta))))
     `(git-commit-comment-heading ((,class (:foreground ,magenta))))
     `(git-commit-keyword ((,class (:foreground ,cyan :slant italic))))
     `(git-commit-known-pseudo-header ((,class (:foreground ,spacegrey5 :weight bold :slant italic))))
     `(git-commit-nonempty-second-line ((,class (:foreground ,red))))
     `(git-commit-overlong-summary ((,class (:foreground ,red :slant italic :weight bold))))
     `(git-commit-pseudo-header ((,class (:foreground ,spacegrey5 :slant italic))))
     `(git-commit-summary ((,class (:foreground ,darkcyan))))

;;;; git-gutter - light
     `(git-gutter:added ((,class (:inherit fringe :foreground ,green))))
     `(git-gutter:deleted ((,class (:inherit fringe :foreground ,red))))
     `(git-gutter:modified ((,class (:inherit fringe :foreground ,cyan))))

;;;; git-gutter+ - light
     `(git-gutter+-added ((,class (:inherit fringe :foreground ,green :background nil))))
     `(git-gutter+-deleted ((,class (:inherit fringe :foreground ,red :background nil))))
     `(git-gutter+-modified ((,class (:inherit fringe :foreground ,cyan :background nil))))

;;;; git-gutter-fringe - light
     `(git-gutter-fr:added ((,class (:inherit git-gutter:added))))
     `(git-gutter-fr:deleted ((,class (:inherit git-gutter:deleted))))
     `(git-gutter-fr:modified ((,class (:inherit git-gutter:modified))))

;;;; gnus - light
     `(gnus-cite-1 ((,class (:foreground ,magenta))))
     `(gnus-cite-2 ((,class (:foreground ,magenta))))
     `(gnus-cite-3 ((,class (:foreground ,magenta))))
     `(gnus-cite-4 ((,class (:foreground ,green))))
     `(gnus-cite-5 ((,class (:foreground ,green))))
     `(gnus-cite-6 ((,class (:foreground ,green))))
     `(gnus-cite-7 ((,class (:foreground ,purple))))
     `(gnus-cite-8 ((,class (:foreground ,purple))))
     `(gnus-cite-9 ((,class (:foreground ,purple))))
     `(gnus-cite-10 ((,class (:foreground ,yellow))))
     `(gnus-cite-11 ((,class (:foreground ,yellow))))
     `(gnus-group-mail-1 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-mail-1-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-mail-2 ((,class (:inherit gnus-group-mail-1))))
     `(gnus-group-mail-2-empty ((,class (:inherit gnus-group-mail-1-empty))))
     `(gnus-group-mail-3 ((,class (:inherit gnus-group-mail-1))))
     `(gnus-group-mail-3-empty ((,class (:inherit gnus-group-mail-1-empty))))
     `(gnus-group-mail-low ((,class (:inherit gnus-group-mail-1 :weight normal))))
     `(gnus-group-mail-low-empty ((,class (:inherit gnus-group-mail-1-empty))))
     `(gnus-group-news-1 ((,class (:inherit gnus-group-mail-1))))
     `(gnus-group-news-1-empty ((,class (:inherit gnus-group-mail-1-empty))))
     `(gnus-group-news-2 ((,class (:inherit gnus-group-news-1))))
     `(gnus-group-news-2-empty ((,class (:inherit gnus-group-news-1-empty))))
     `(gnus-group-news-3 ((,class (:inherit gnus-group-news-1))))
     `(gnus-group-news-3-empty ((,class (:inherit gnus-group-news-1-empty))))
     `(gnus-group-news-4 ((,class (:inherit gnus-group-news-1))))
     `(gnus-group-news-4-empty ((,class (:inherit gnus-group-news-1-empty))))
     `(gnus-group-news-5 ((,class (:inherit gnus-group-news-1))))
     `(gnus-group-news-5-empty ((,class (:inherit gnus-group-news-1-empty))))
     `(gnus-group-news-6 ((,class (:inherit gnus-group-news-1))))
     `(gnus-group-news-6-empty ((,class (:inherit gnus-group-news-1-empty))))
     `(gnus-group-news-low ((,class (:inherit gnus-group-mail-1 :foreground ,spacegrey5))))
     `(gnus-group-news-low-empty ((,class (:inherit gnus-group-news-low :weight normal))))
     `(gnus-header-content ((,class (:inherit message-header-other))))
     `(gnus-header-from ((,class (:inherit message-header-other))))
     `(gnus-header-name ((,class (:inherit message-header-name))))
     `(gnus-header-newsgroups ((,class (:inherit message-header-other))))
     `(gnus-header-subject ((,class (:inherit message-header-subject))))
     `(gnus-signature ((,class (:foreground ,yellow))))
     `(gnus-summary-cancelled ((,class (:foreground ,red :strike-through t))))
     `(gnus-summary-high-ancient ((,class (:foreground ,spacegrey5 :inherit italic))))
     `(gnus-summary-high-read ((,class (:foreground ,fg))))
     `(gnus-summary-high-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-high-unread ((,class (:foreground ,green))))
     `(gnus-summary-low-ancient ((,class (:foreground ,spacegrey5 :inherit italic))))
     `(gnus-summary-low-read ((,class (:foreground ,fg))))
     `(gnus-summary-low-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-low-unread ((,class (:foreground ,green))))
     `(gnus-summary-normal-ancient ((,class (:foreground ,spacegrey5 :inherit italic))))
     `(gnus-summary-normal-read ((,class (:foreground ,fg))))
     `(gnus-summary-normal-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-normal-unread ((,class (:foreground ,green :inherit bold))))
     `(gnus-summary-selected ((,class (:foreground ,blue :weight bold))))
     `(gnus-x-face ((,class (:background ,spacegrey5 :foreground ,fg))))

;;;; goggles - light
     `(goggles-added ((,class (:background ,green))))
     `(goggles-changed ((,class (:inherit region))))
     `(goggles-removed ((,class (:background ,red :extend t))))

;;;; header-line - light
     `(header-line ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))

;;;; helm - light
     `(helm-ff-directory ((,class (:foreground ,red))))
     `(helm-ff-dotted-directory ((,class (:foreground ,grey))))
     `(helm-ff-executable ((,class (:foreground ,spacegrey8 :inherit italic))))
     `(helm-ff-file ((,class (:foreground ,fg))))
     `(helm-ff-prefix ((,class (:foreground ,magenta))))
     `(helm-grep-file ((,class (:foreground ,blue))))
     `(helm-grep-finish ((,class (:foreground ,green))))
     `(helm-grep-lineno ((,class (:foreground ,spacegrey5))))
     `(helm-grep-match ((,class (:foreground ,orange :distant-foreground ,red))))
     `(helm-match ((,class (:inherit bold :foreground ,orange :distant-foreground ,spacegrey8))))
     `(helm-moccur-buffer ((,class (:inherit link))))
     `(helm-selection ((,class (:inherit bold :background ,grey :extend t :distant-foreground ,orange))))
     `(helm-source-header ((,class (:background ,spacegrey2 :foreground ,magenta :weight bold))))
     `(helm-swoop-target-line-block-face ((,class (:foreground ,yellow))))
     `(helm-swoop-target-line-face ((,class (:foreground ,orange :inverse-video t))))
     `(helm-swoop-target-line-face ((,class (:foreground ,orange :inverse-video t))))
     `(helm-swoop-target-number-face ((,class (:foreground ,spacegrey5))))
     `(helm-swoop-target-word-face ((,class (:foreground ,green :inherit bold))))
     `(helm-visible-mark ((,class (:inherit (bold highlight)))))

;;;; helpful - light
     `(helpful-heading ((,class (:weight bold :height 1.2))))

;;;; hi-lock - light
     `(hi-blue ((,class (:background ,blue))))
     `(hi-blue-b ((,class (:foreground ,blue :weight bold))))
     `(hi-green ((,class (:background ,green))))
     `(hi-green-b ((,class (:foreground ,green :weight bold))))
     `(hi-magenta ((,class (:background ,purple))))
     `(hi-red-b ((,class (:foreground ,red :weight bold))))
     `(hi-yellow ((,class (:background ,yellow))))

;;;; highlight-indentation-mode - light
     `(highlight-indentation-current-column-face ((,class (:background ,spacegrey1))))
     `(highlight-indentation-face ((,class (:inherit hl-line))))
     `(highlight-indentation-guides-even-face ((,class (:inherit highlight-indentation-face))))
     `(highlight-indentation-guides-odd-face ((,class (:inherit highlight-indentation-face))))

;;;; highlight-numbers-mode - light
     `(highlight-numbers-number ((,class (:inherit bold :foreground ,orange))))

;;;; highlight-quoted-mode - light
     `(highlight-quoted-symbol ((,class (:foreground ,yellow))))
     `(highlight-quoted-quote  ((,class (:foreground ,fg))))

;;;; highlight-symbol - light
     `(highlight-symbol-face ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; highlight-thing - light
     `(highlight-thing ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; hl-fill-column-face - light
     `(hl-fill-column-face ((,class (:inherit (hl-line shadow)))))

;;;; hl-line (built-in) - light
     `(hl-line ((,class (:background ,bg-other :extend t))))

;;;; hl-todo - light
     `(hl-todo ((,class (:foreground ,red :weight bold))))

;;;; hlinum - light
     `(linum-highlight-face ((,class (:foreground ,fg :distant-foreground nil :weight normal))))

;;;; hydra - light
     `(hydra-face-amaranth ((,class (:foreground ,purple :weight bold))))
     `(hydra-face-blue ((,class (:foreground ,blue :weight bold))))
     `(hydra-face-magenta ((,class (:foreground ,magenta :weight bold))))
     `(hydra-face-red ((,class (:foreground ,red :weight bold))))
     `(hydra-face-teal ((,class (:foreground ,teal :weight bold))))

;;;; ido - light
     `(ido-first-match ((,class (:foreground ,orange))))
     `(ido-indicator ((,class (:foreground ,red :background ,bg))))
     `(ido-only-match ((,class (:foreground ,green))))
     `(ido-subdir ((,class (:foreground ,magenta))))
     `(ido-virtual ((,class (:foreground ,spacegrey5))))

;;;; iedit - light
     `(iedit-occurrence ((,class (:foreground ,purple :weight bold :inverse-video t))))
     `(iedit-read-only-occurrence ((,class (:inherit region))))

;;;; imenu-list - light
     `(imenu-list-entry-face-0 ((,class (:foreground ,orange))))
     `(imenu-list-entry-face-1 ((,class (:foreground ,green))))
     `(imenu-list-entry-face-2 ((,class (:foreground ,yellow))))
     `(imenu-list-entry-subalist-face-0 ((,class (:inherit imenu-list-entry-face-0 :weight bold))))
     `(imenu-list-entry-subalist-face-1 ((,class (:inherit imenu-list-entry-face-1 :weight bold))))
     `(imenu-list-entry-subalist-face-2 ((,class (:inherit imenu-list-entry-face-2 :weight bold))))

;;;; indent-guide - light
     `(indent-guide-face ((,class (:inherit highlight-indentation-face))))

;;;; isearch - light
     `(isearch ((,class (:inherit lazy-highlight :weight bold))))
     `(isearch-fail ((,class (:background ,red :foreground ,spacegrey0 :weight bold))))

;;;; ivy - light
     `(ivy-confirm-face ((,class (:foreground ,green))))
     `(ivy-current-match ((,class (:background ,bg-other :distant-foreground nil :extend t))))
     `(ivy-highlight-face ((,class (:foreground ,magenta))))
     `(ivy-match-required-face ((,class (:foreground ,red))))
     `(ivy-minibuffer-match-face-1 ((,class (:background nil :foreground ,orange :weight bold :underline t))))
     `(ivy-minibuffer-match-face-2 ((,class (:inherit ivy-minibuffer-match-face-1 :foreground ,purple :background ,spacegrey1 :weight semi-bold))))
     `(ivy-minibuffer-match-face-3 ((,class (:inherit ivy-minibuffer-match-face-2 :foreground ,green :weight semi-bold))))
     `(ivy-minibuffer-match-face-4 ((,class (:inherit ivy-minibuffer-match-face-2 :foreground ,yellow :weight semi-bold))))
     `(ivy-minibuffer-match-highlight ((,class (:foreground ,magenta))))
     `(ivy-modified-buffer ((,class (:inherit bold :foreground ,darkcyan))))
     `(ivy-virtual ((,class (:inherit italic :foreground ,spacegrey5))))

;;;; ivy-posframe - light
     `(ivy-posframe ((,class (:background ,bg-other))))
     `(ivy-posframe-border ((,class (:inherit internal-border))))

;;;; jabber - light
     `(jabber-activity-face ((,class (:foreground ,red :weight bold))))
     `(jabber-activity-personal-face ((,class (:foreground ,blue :weight bold))))
     `(jabber-chat-error ((,class (:foreground ,red :weight bold))))
     `(jabber-chat-prompt-foreign ((,class (:foreground ,red :weight bold))))
     `(jabber-chat-prompt-local ((,class (:foreground ,blue :weight bold))))
     `(jabber-chat-prompt-system ((,class (:foreground ,green :weight bold))))
     `(jabber-chat-text-foreign ((,class (:foreground ,fg))))
     `(jabber-chat-text-local ((,class (:foreground ,fg))))
     `(jabber-rare-time-face ((,class (:foreground ,green))))
     `(jabber-roster-user-away ((,class (:foreground ,yellow))))
     `(jabber-roster-user-chatty ((,class (:foreground ,green :weight bold))))
     `(jabber-roster-user-dnd ((,class (:foreground ,red))))
     `(jabber-roster-user-error ((,class (:foreground ,red))))
     `(jabber-roster-user-offline ((,class (:foreground ,fg))))
     `(jabber-roster-user-online ((,class (:foreground ,green :weight bold))))
     `(jabber-roster-user-xa ((,class (:foreground ,cyan))))

;;;; jdee - light
     `(jdee-font-lock-bold-face ((,class (:inherit bold))))
     `(jdee-font-lock-constant-face ((,class (:inherit font-lock-constant-face))))
     `(jdee-font-lock-constructor-face ((,class (:foreground ,blue))))
     `(jdee-font-lock-doc-tag-face ((,class (:foreground ,magenta))))
     `(jdee-font-lock-italic-face ((,class (:inherit italic))))
     `(jdee-font-lock-link-face ((,class (:foreground ,blue :italic nil :underline t))))
     `(jdee-font-lock-modifier-face ((,class (:inherit font-lock-type-face))))
     `(jdee-font-lock-number-face ((,class (:foreground ,orange))))
     `(jdee-font-lock-operator-face ((,class (:foreground ,fg))))
     `(jdee-font-lock-private-face ((,class (:inherit font-lock-keyword-face))))
     `(jdee-font-lock-protected-face ((,class (:inherit font-lock-keyword-face))))
     `(jdee-font-lock-public-face ((,class (:inherit font-lock-keyword-face))))

;;;; js2-mode - light
     `(js2-external-variable ((,class (:foreground ,fg))))
     `(js2-function-call ((,class (:foreground ,blue))))
     `(js2-function-param ((,class (:foreground ,red))))
     `(js2-jsdoc-tag ((,class (:foreground ,spacegrey5))))
     `(js2-object-property ((,class (:foreground ,magenta))))

;;;; keycast - light
     `(keycast-command ((,class (:inherit mode-line-emphasis))))
     `(keycast-key ((,class (:inherit (bold mode-line-highlight)))))

;;;; ledger-mode - light
     `(ledger-font-payee-cleared-face ((,class (:foreground ,magenta :weight bold))))
     `(ledger-font-payee-uncleared-face ((,class (:foreground ,spacegrey5  :weight bold))))
     `(ledger-font-posting-account-face ((,class (:foreground ,spacegrey8))))
     `(ledger-font-posting-amount-face ((,class (:foreground ,yellow))))
     `(ledger-font-posting-date-face ((,class (:foreground ,blue))))
     `(ledger-font-xact-highlight-face ((,class (:background ,spacegrey0))))

;;;; line numbers - light
     `(line-number ((,class (:inherit default :foreground ,spacegrey5 :weight normal))))
     `(line-number-current-line ((,class (:inherit (hl-line default) :foreground ,fg :weight normal))))

;;;; linum - light
     `(linum ((,class (:inherit line-number))))

;;;; linum-relative - light
     `(linum-relative-current-face ((,class (:inherit line-number-current-line))))

;;;; lsp-mode - light
     `(lsp-face-highlight-read ((,class (:background ,darkblue :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(lsp-face-highlight-textual ((,class (:background ,darkblue :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(lsp-face-highlight-write ((,class (:background ,darkblue :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(lsp-headerline-breadcrumb-separator-face ((,class (:foreground ,fg-other))))
     `(lsp-ui-doc-background ((,class (:inherit tooltip))))
     `(lsp-ui-peek-filename ((,class (:inherit mode-line-buffer-id))))
     `(lsp-ui-peek-header ((,class (:foreground ,fg :background ,bg :bold bold))))
     `(lsp-ui-peek-highlight ((,class (:inherit lsp-ui-peek-header :background ,grey :foreground ,bg :box t))))
     `(lsp-ui-peek-line-number ((,class (:foreground ,green))))
     `(lsp-ui-peek-list ((,class (:background ,bg))))
     `(lsp-ui-peek-peek ((,class (:background ,bg))))
     `(lsp-ui-peek-selection ((,class (:foreground ,bg :background ,blue :bold bold))))
     `(lsp-ui-sideline-code-action ((,class (:foreground ,orange))))
     `(lsp-ui-sideline-current-symbol ((,class (:foreground ,orange))))
     `(lsp-ui-sideline-symbol-info ((,class (:foreground ,spacegrey5 :background ,bg-other :extend t))))

;;;; lui - light
     `(lui-button-face ((,class (:foreground ,orange :underline t))))
     `(lui-highlight-face ((,class (:foreground ,orange))))
     `(lui-time-stamp-face ((,class (:foreground ,magenta))))

;;;; magit - light
     `(magit-bisect-bad ((,class (:foreground ,red))))
     `(magit-bisect-good ((,class (:foreground ,green))))
     `(magit-bisect-skip ((,class (:foreground ,orange))))
     `(magit-blame-date ((,class (:foreground ,red))))
     `(magit-blame-heading ((,class (:foreground ,orange :background ,spacegrey3 :extend t))))
     `(magit-branch-current ((,class (:foreground ,red))))
     `(magit-branch-local ((,class (:foreground ,red))))
     `(magit-branch-remote ((,class (:foreground ,green))))
     `(magit-branch-remote-head ((,class (:foreground ,green))))
     `(magit-cherry-equivalent ((,class (:foreground ,magenta))))
     `(magit-cherry-unmatched ((,class (:foreground ,cyan))))
     `(magit-diff-added ((,class (:foreground ,bg  :background ,green :extend t))))
     `(magit-diff-added-highlight ((,class (:foreground ,bg :background ,green :weight bold :extend t))))
     `(magit-diff-base ((,class (:foreground ,orange :background ,orange :extend t))))
     `(magit-diff-base-highlight ((,class (:foreground ,orange :background ,orange :weight bold :extend t))))
     `(magit-diff-context ((,class (:foreground ,fg :background ,bg :extend t))))
     `(magit-diff-context-highlight ((,class (:foreground ,fg :background ,bg-other :extend t))))
     `(magit-diff-file-heading ((,class (:foreground ,fg :weight bold :extend t))))
     `(magit-diff-file-heading-selection ((,class (:foreground ,purple :background ,darkblue :weight bold :extend t))))
     `(magit-diff-hunk-heading ((,class (:foreground ,bg :background ,magenta :extend t))))
     `(magit-diff-hunk-heading-highlight ((,class (:foreground ,bg :background ,magenta :weight bold :extend t))))
     `(magit-diff-lines-heading ((,class (:foreground ,yellow :background ,red :extend t :extend t))))
     `(magit-diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
     `(magit-diff-removed-highlight ((,class (:foreground ,bg :background ,red :weight bold :extend t))))
     `(magit-diffstat-added ((,class (:foreground ,green))))
     `(magit-diffstat-removed ((,class (:foreground ,red))))
     `(magit-dimmed ((,class (:foreground ,spacegrey5))))
     `(magit-filename ((,class (:foreground ,magenta))))
     `(magit-hash ((,class (:foreground ,blue))))
     `(magit-header-line ((,class (:background ,bg-other :foreground ,darkcyan :weight bold :box (:line-width 3 :color ,bg-other)))))
     `(magit-log-author ((,class (:foreground ,orange))))
     `(magit-log-date ((,class (:foreground ,blue))))
     `(magit-log-graph ((,class (:foreground ,spacegrey5))))
     `(magit-process-ng ((,class (:inherit error))))
     `(magit-process-ok ((,class (:inherit success))))
     `(magit-reflog-amend ((,class (:foreground ,purple))))
     `(magit-reflog-checkout ((,class (:foreground ,blue))))
     `(magit-reflog-cherry-pick ((,class (:foreground ,green))))
     `(magit-reflog-commit ((,class (:foreground ,green))))
     `(magit-reflog-merge ((,class (:foreground ,green))))
     `(magit-reflog-other ((,class (:foreground ,cyan))))
     `(magit-reflog-rebase ((,class (:foreground ,purple))))
     `(magit-reflog-remote ((,class (:foreground ,cyan))))
     `(magit-reflog-reset ((,class (:inherit error))))
     `(magit-refname ((,class (:foreground ,spacegrey5))))
     `(magit-section-heading ((,class (:foreground ,darkcyan :weight bold :extend t))))
     `(magit-section-heading-selection ((,class (:foreground ,orange :weight bold :extend t))))
     `(magit-section-highlight ((,class (:inherit hl-line))))
     `(magit-section-secondary-heading ((,class (:foreground ,magenta :weight bold :extend t))))
     `(magit-sequence-drop ((,class (:foreground ,red))))
     `(magit-sequence-head ((,class (:foreground ,blue))))
     `(magit-sequence-part ((,class (:foreground ,orange))))
     `(magit-sequence-stop ((,class (:foreground ,green))))
     `(magit-signature-bad ((,class (:inherit error))))
     `(magit-signature-error ((,class (:inherit error))))
     `(magit-signature-expired ((,class (:foreground ,orange))))
     `(magit-signature-good ((,class (:inherit success))))
     `(magit-signature-revoked ((,class (:foreground ,purple))))
     `(magit-signature-untrusted ((,class (:foreground ,yellow))))
     `(magit-tag ((,class (:foreground ,yellow))))

;;;; make-mode - light
     `(makefile-targets ((,class (:foreground ,blue))))

;;;; marginalia - light
     `(marginalia-documentation ((,class (:foreground ,blue))))
     `(marginalia-file-name ((,class (:foreground ,blue))))

;;;; markdown-mode - light
     `(markdown-blockquote-face ((,class (:inherit italic :foreground ,spacegrey5))))
     `(markdown-bold-face ((,class (:inherit bold :foreground ,orange))))
     `(markdown-code-face ((,class (:background ,bg-org :extend t))))
     `(markdown-header-delimiter-face ((,class (:inherit markdown-header-face))))
     `(markdown-header-face ((,class (:inherit bold :foreground ,orange))))
     `(markdown-html-attr-name-face ((,class (:inherit font-lock-variable-name-face))))
     `(markdown-html-attr-value-face ((,class (:inherit font-lock-string-face))))
     `(markdown-html-entity-face ((,class (:inherit font-lock-variable-name-face))))
     `(markdown-html-tag-delimiter-face ((,class (:inherit markdown-markup-face))))
     `(markdown-html-tag-name-face ((,class (:inherit font-lock-keyword-face))))
     `(markdown-inline-code-face ((,class (:inherit (markdown-code-face markdown-pre-face) :extend nil))))
     `(markdown-italic-face ((,class (:inherit italic :foreground ,magenta))))
     `(markdown-link-face ((,class (:foreground ,orange))))
     `(markdown-list-face ((,class (:foreground ,red))))
     `(markdown-markup-face ((,class (:foreground ,fg))))
     `(markdown-metadata-key-face ((,class (:foreground ,red))))
     `(markdown-pre-face ((,class (:background ,bg-org :foreground ,green))))
     `(markdown-reference-face ((,class (:foreground ,spacegrey5))))
     `(markdown-url-face ((,class (:foreground ,purple :weight normal))))

;;;; message - light
     `(message-cited-text ((,class (:foreground ,purple))))
     `(message-header-cc ((,class (:inherit 'message-header-to :foreground ,orange))))
     `(message-header-name ((,class (:foreground ,green))))
     `(message-header-newsgroups ((,class (:foreground ,yellow))))
     `(message-header-other ((,class (:foreground ,magenta))))
     `(message-header-subject ((,class (:foreground ,orange :weight bold))))
     `(message-header-to ((,class (:foreground ,orange :weight bold))))
     `(message-header-xheader ((,class (:foreground ,spacegrey5))))
     `(message-mml ((,class (:foreground ,spacegrey5 :slant italic))))
     `(message-separator ((,class (:foreground ,spacegrey5))))

;;;; mic-paren - light
     `(paren-face-match ((,class (:foreground ,red :background ,spacegrey0 :weight ultra-bold))))
     `(paren-face-mismatch ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))
     `(paren-face-no-match ((,class (:inherit paren-face-mismatch :weight ultra-bold))))

;;;; minimap - light
     `(minimap-active-region-background ((,class (:background ,bg))))
     `(minimap-current-line-face ((,class (:background ,grey))))

;;;; mmm-mode - light
     `(mmm-cleanup-submode-face ((,class (:background ,yellow))))
     `(mmm-code-submode-face ((,class (:background ,bg-other))))
     `(mmm-comment-submode-face ((,class (:background ,blue))))
     `(mmm-declaration-submode-face ((,class (:background ,cyan))))
     `(mmm-default-submode-face ((,class (:background nil))))
     `(mmm-init-submode-face ((,class (:background ,red))))
     `(mmm-output-submode-face ((,class (:background ,magenta))))
     `(mmm-special-submode-face ((,class (:background ,green))))

;;;; mode-line - light
     `(mode-line ((,class (:background ,spacegrey8 :foreground ,fg :distant-foreground ,bg))))
     `(mode-line-buffer-id ((,class (:foreground ,fg :weight bold))))
     `(mode-line-emphasis ((,class (:foreground ,orange :distant-foreground ,bg))))
     `(mode-line-highlight ((,class (:inherit highlight :distant-foreground ,bg))))
     `(mode-line-inactive ((,class (:background ,spacegrey8 :foreground ,spacegrey5 :distant-foreground ,bg-other))))

;;;; mu4e - light
     `(mu4e-forwarded-face ((,class (:foreground ,orange))))
     `(mu4e-header-key-face ((,class (:foreground ,darkcyan))))
     `(mu4e-header-title-face ((,class (:foreground ,magenta))))
     `(mu4e-highlight-face ((,class (:foreground ,bg :background ,orange))))
     `(mu4e-replied-face ((,class (:foreground ,darkcyan))))
     `(mu4e-title-face ((,class (:foreground ,magenta))))

;;;; mu4e-column-faces - light
     `(mu4e-column-faces-date ((,class (:foreground ,blue))))
     `(mu4e-column-faces-to-from ((,class (:foreground ,green))))

;;;; mu4e-thread-folding - light
     `(mu4e-thread-folding-child-face ((,class (:extend t :background ,bg-org :underline nil))))
     `(mu4e-thread-folding-root-folded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))
     `(mu4e-thread-folding-root-unfolded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))

;;;; multiple cursors - light
     `(mc/cursor-face ((,class (:inherit cursor))))

;;;; nano-modeline - light
     `(nano-modeline-active-name ((,class (:foreground ,fg :weight bold))))
     `(nano-modeline-inactive-name ((,class (:foreground ,spacegrey5 :weight bold))))
     `(nano-modeline-active-primary ((,class (:foreground ,fg))))
     `(nano-modeline-inactive-primary ((,class (:foreground ,spacegrey5))))
     `(nano-modeline-active-secondary ((,class (:foreground ,darkcyan :weight bold))))
     `(nano-modeline-inactive-secondary ((,class (:foreground ,spacegrey5 :weight bold))))
     `(nano-modeline-active-status-RO ((,class (:background ,red :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-RO ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))
     `(nano-modeline-active-status-RW ((,class (:background ,darkcyan :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-RW ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))
     `(nano-modeline-active-status-** ((,class (:background ,red :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-** ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))

;;;; nav-flash - light
     `(nav-flash-face ((,class (:background ,grey :foreground ,spacegrey8 :weight bold))))

;;;; neotree - light
     `(neo-dir-link-face ((,class (:foreground ,orange))))
     `(neo-expand-btn-face ((,class (:foreground ,orange))))
     `(neo-file-link-face ((,class (:foreground ,fg))))
     `(neo-root-dir-face ((,class (:foreground ,green :background ,bg :box (:line-width 4 :color ,bg)))))
     `(neo-vc-added-face ((,class (:foreground ,green))))
     `(neo-vc-conflict-face ((,class (:foreground ,purple :weight bold))))
     `(neo-vc-edited-face ((,class (:foreground ,yellow))))
     `(neo-vc-ignored-face ((,class (:foreground ,spacegrey5))))
     `(neo-vc-removed-face ((,class (:foreground ,red :strike-through t))))

;;;; nlinum - light
     `(nlinum-current-line ((,class (:inherit line-number-current-line))))

;;;; nlinum-hl - light
     `(nlinum-hl-face ((,class (:inherit line-number-current-line))))

;;;; nlinum-relative - light
     `(nlinum-relative-current-face ((,class (:inherit line-number-current-line))))

;;;; notmuch - light
     `(notmuch-message-summary-face ((,class (:foreground ,grey :background nil))))
     `(notmuch-search-count ((,class (:foreground ,spacegrey5))))
     `(notmuch-search-date ((,class (:foreground ,orange))))
     `(notmuch-search-flagged-face ((,class (:foreground ,red))))
     `(notmuch-search-matching-authors ((,class (:foreground ,blue))))
     `(notmuch-search-non-matching-authors ((,class (:foreground ,fg))))
     `(notmuch-search-subject ((,class (:foreground ,fg))))
     `(notmuch-search-unread-face ((,class (:weight bold))))
     `(notmuch-tag-added ((,class (:foreground ,green :weight normal))))
     `(notmuch-tag-deleted ((,class (:foreground ,red :weight normal))))
     `(notmuch-tag-face ((,class (:foreground ,yellow :weight normal))))
     `(notmuch-tag-flagged ((,class (:foreground ,yellow :weight normal))))
     `(notmuch-tag-unread ((,class (:foreground ,yellow :weight normal))))
     `(notmuch-tree-match-author-face ((,class (:foreground ,blue :weight bold))))
     `(notmuch-tree-match-date-face ((,class (:foreground ,orange :weight bold))))
     `(notmuch-tree-match-face ((,class (:foreground ,fg))))
     `(notmuch-tree-match-subject-face ((,class (:foreground ,fg))))
     `(notmuch-tree-match-tag-face ((,class (:foreground ,yellow))))
     `(notmuch-tree-match-tree-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-author-face ((,class (:foreground ,blue))))
     `(notmuch-tree-no-match-date-face ((,class (:foreground ,orange))))
     `(notmuch-tree-no-match-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-subject-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-tag-face ((,class (:foreground ,yellow))))
     `(notmuch-tree-no-match-tree-face ((,class (:foreground ,yellow))))
     `(notmuch-wash-cited-text ((,class (:foreground ,spacegrey4))))
     `(notmuch-wash-toggle-button ((,class (:foreground ,fg))))

;;;; orderless - light
     `(orderless-match-face-0 ((,class (:foreground ,darkblue :weight bold :underline t))))
     `(orderless-match-face-1 ((,class (:foreground ,teal :weight bold :underline t))))
     `(orderless-match-face-2 ((,class (:foreground ,darkcyan :weight bold :underline t))))
     `(orderless-match-face-3 ((,class (:foreground ,cyan :weight bold :underline t))))

;;;; objed - light
     `(objed-hl ((,class (:inherit region :background ,grey))))
     `(objed-mode-line ((,class (:inherit warning :weight bold))))

;;;; org-agenda - light
     `(org-agenda-clocking ((,class (:background ,blue))))
     `(org-agenda-date ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-date-today ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-date-weekend ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-dimmed-todo-face ((,class (:foreground ,spacegrey5))))
     `(org-agenda-done ((,class (:inherit org-done))))
     `(org-agenda-structure ((,class (:foreground ,fg :weight ultra-bold))))
     `(org-scheduled ((,class (:foreground ,fg))))
     `(org-scheduled-previously ((,class (:foreground ,spacegrey8))))
     `(org-scheduled-today ((,class (:foreground ,spacegrey7))))
     `(org-sexp-date ((,class (:foreground ,fg))))
     `(org-time-grid ((,class (:foreground ,spacegrey5))))
     `(org-upcoming-deadline ((,class (:foreground ,fg))))
     `(org-upcoming-distant-deadline ((,class (:foreground ,fg))))

;;;; org-habit - light
     `(org-habit-alert-face ((,class (:weight bold :background ,yellow))))
     `(org-habit-alert-future-face ((,class (:weight bold :background ,yellow))))
     `(org-habit-clear-face ((,class (:weight bold :background ,spacegrey4))))
     `(org-habit-clear-future-face ((,class (:weight bold :background ,spacegrey3))))
     `(org-habit-overdue-face ((,class (:weight bold :background ,red))))
     `(org-habit-overdue-future-face ((,class (:weight bold :background ,red))))
     `(org-habit-ready-face ((,class (:weight bold :background ,blue))))
     `(org-habit-ready-future-face ((,class (:weight bold :background ,blue))))

;;;; org-journal - light
     `(org-journal-calendar-entry-face ((,class (:foreground ,purple :slant italic))))
     `(org-journal-calendar-scheduled-face ((,class (:foreground ,red :slant italic))))
     `(org-journal-highlight ((,class (:foreground ,orange))))

;;;; org-mode - light
     `(org-archived ((,class (:foreground ,spacegrey5))))
     `(org-block ((,class (:foreground ,fg :background ,bg-org :extend t))))
     `(org-block-background ((,class (:background ,bg-org :extend t))))
     `(org-block-begin-line ((,class (:foreground ,spacegrey5 :slant italic :background ,bg-org :extend t))))
     `(org-block-end-line ((,class (:inherit org-block-begin-line))))
     `(org-checkbox ((,class (:inherit org-todo))))
     `(org-checkbox-statistics-done ((,class (:inherit org-done))))
     `(org-checkbox-statistics-todo ((,class (:inherit org-todo))))
     `(org-code ((,class (:foreground ,green))))
     `(org-date ((,class (:foreground ,yellow))))
     `(org-default ((,class (:inherit variable-pitch))))
     `(org-document-info ((,class (:foreground ,orange))))
     `(org-document-title ((,class (:foreground ,orange :weight bold))))
     `(org-done ((,class (:inherit org-headline-done :bold inherit))))
     `(org-ellipsis ((,class (:underline nil :background nil :foreground ,grey))))
     `(org-footnote ((,class (:foreground ,orange))))
     `(org-formula ((,class (:foreground ,cyan))))
     `(org-headline-done ((,class (:foreground ,spacegrey5))))
     `(org-hide ((,class (:foreground ,bg))))
     `(org-latex-and-related ((,class (:foreground ,spacegrey8 :weight bold))))
     `(org-level-1 ((,class (:foreground ,blue :weight ultra-bold))))
     `(org-level-2 ((,class (:foreground ,magenta :weight bold))))
     `(org-level-3 ((,class (:foreground ,darkcyan :weight bold))))
     `(org-level-4 ((,class (:foreground ,orange))))
     `(org-level-5 ((,class (:foreground ,green))))
     `(org-level-6 ((,class (:foreground ,teal))))
     `(org-level-7 ((,class (:foreground ,purple))))
     `(org-level-8 ((,class (:foreground ,fg))))
     `(org-link ((,class (:foreground ,darkcyan :underline t))))
     `(org-list-dt ((,class (:foreground ,orange))))
     `(org-meta-line ((,class (:foreground ,spacegrey5))))
     `(org-priority ((,class (:foreground ,red))))
     `(org-property-value ((,class (:foreground ,spacegrey5))))
     `(org-quote ((,class (:background ,spacegrey3 :slant italic :extend t))))
     `(org-special-keyword ((,class (:foreground ,spacegrey5))))
     `(org-table ((,class (:foreground ,magenta))))
     `(org-tag ((,class (:foreground ,spacegrey5 :weight normal))))
     `(org-todo ((,class (:foreground ,green :bold inherit))))
     `(org-verbatim ((,class (:foreground ,orange))))
     `(org-warning ((,class (:foreground ,yellow))))

;;;; org-pomodoro - light
     `(org-pomodoro-mode-line ((,class (:foreground ,red))))
     `(org-pomodoro-mode-line-overtime ((,class (:foreground ,yellow :weight bold))))

;;;; org-ref - light
     `(org-ref-acronym-face ((,class (:foreground ,magenta))))
     `(org-ref-cite-face ((,class (:foreground ,yellow :weight light :underline t))))
     `(org-ref-glossary-face ((,class (:foreground ,purple))))
     `(org-ref-label-face ((,class (:foreground ,blue))))
     `(org-ref-ref-face ((,class (:inherit link :foreground ,teal))))

;;;; outline - light
     `(outline-1 ((,class (:foreground ,blue :weight ultra-bold))))
     `(outline-2 ((,class (:foreground ,magenta :weight bold))))
     `(outline-3 ((,class (:foreground ,green :weight bold))))
     `(outline-4 ((,class (:foreground ,orange))))
     `(outline-5 ((,class (:foreground ,purple))))
     `(outline-6 ((,class (:foreground ,purple))))
     `(outline-7 ((,class (:foreground ,purple))))
     `(outline-8 ((,class (:foreground ,fg))))

;;;; parenface - light
     `(paren-face ((,class (:foreground ,spacegrey5))))

;;;; parinfer - light
     `(parinfer-pretty-parens:dim-paren-face ((,class (:foreground ,spacegrey5))))
     `(parinfer-smart-tab:indicator-face ((,class (:foreground ,spacegrey5))))

;;;; persp-mode - light
     `(persp-face-lighter-buffer-not-in-persp ((,class (:foreground ,spacegrey5))))
     `(persp-face-lighter-default ((,class (:foreground ,orange :weight bold))))
     `(persp-face-lighter-nil-persp ((,class (:foreground ,spacegrey5))))

;;;; perspective - light
     `(persp-selected-face ((,class (:foreground ,blue :weight bold))))

;;;; pkgbuild-mode - light
     `(pkgbuild-error-face ((,class (:underline (:style wave :color ,red)))))

;;;; popup - light
     `(popup-face ((,class (:inherit tooltip))))
     `(popup-selection-face ((,class (:background ,grey))))
     `(popup-tip-face ((,class (:inherit popup-face :foreground ,magenta :background ,spacegrey0))))

;;;; powerline - light
     `(powerline-active0 ((,class (:inherit mode-line :background ,bg))))
     `(powerline-active1 ((,class (:inherit mode-line :background ,bg))))
     `(powerline-active2 ((,class (:inherit mode-line :foreground ,spacegrey8 :background ,bg))))
     `(powerline-inactive0 ((,class (:inherit mode-line-inactive :background ,spacegrey2))))
     `(powerline-inactive1 ((,class (:inherit mode-line-inactive :background ,spacegrey2))))
     `(powerline-inactive2 ((,class (:inherit mode-line-inactive :background ,spacegrey2))))

;;;; rainbow-delimiters - light
     `(rainbow-delimiters-depth-1-face ((,class (:foreground ,blue))))
     `(rainbow-delimiters-depth-2-face ((,class (:foreground ,purple))))
     `(rainbow-delimiters-depth-3-face ((,class (:foreground ,green))))
     `(rainbow-delimiters-depth-4-face ((,class (:foreground ,orange))))
     `(rainbow-delimiters-depth-5-face ((,class (:foreground ,magenta))))
     `(rainbow-delimiters-depth-6-face ((,class (:foreground ,yellow))))
     `(rainbow-delimiters-depth-7-face ((,class (:foreground ,teal))))
     `(rainbow-delimiters-mismatched-face ((,class (:inherit rainbow-delimiters-unmatched-face))))
     `(rainbow-delimiters-unmatched-face ((,class (:foreground ,red :weight bold :inverse-video t))))

;;;; re-builder - light
     `(reb-match-0 ((,class (:foreground ,orange :inverse-video t))))
     `(reb-match-1 ((,class (:foreground ,purple :inverse-video t))))
     `(reb-match-2 ((,class (:foreground ,green :inverse-video t))))
     `(reb-match-3 ((,class (:foreground ,yellow :inverse-video t))))

;;;; rjsx-mode - light
     `(rjsx-attr ((,class (:foreground ,blue))))
     `(rjsx-tag ((,class (:foreground ,yellow))))

;;;; rpm-spec-mode - light
     `(rpm-spec-dir-face ((,class (:foreground ,green))))
     `(rpm-spec-doc-face ((,class (:foreground ,orange))))
     `(rpm-spec-ghost-face ((,class (:foreground ,spacegrey5))))
     `(rpm-spec-macro-face ((,class (:foreground ,yellow))))
     `(rpm-spec-obsolete-tag-face ((,class (:foreground ,red))))
     `(rpm-spec-package-face ((,class (:foreground ,orange))))
     `(rpm-spec-section-face ((,class (:foreground ,purple))))
     `(rpm-spec-tag-face ((,class (:foreground ,blue))))
     `(rpm-spec-var-face ((,class (:foreground ,magenta))))

;;;; rst - light
     `(rst-block ((,class (:inherit font-lock-constant-face))))
     `(rst-level-1 ((,class (:inherit rst-adornment :weight bold))))
     `(rst-level-2 ((,class (:inherit rst-adornment :weight bold))))
     `(rst-level-3 ((,class (:inherit rst-adornment :weight bold))))
     `(rst-level-4 ((,class (:inherit rst-adornment :weight bold))))
     `(rst-level-5 ((,class (:inherit rst-adornment :weight bold))))
     `(rst-level-6 ((,class (:inherit rst-adornment :weight bold))))

;;;; selectrum - light
     `(selectrum-current-candidate ((,class (:background ,grey :distant-foreground nil :extend t))))

;;;; sh-script - light
     `(sh-heredoc ((,class (:inherit font-lock-string-face :weight normal))))
     `(sh-quoted-exec ((,class (:inherit font-lock-preprocessor-face))))

;;;; show-paren - light
     `(show-paren-match ((,class (:inherit paren-face-match))))
     `(show-paren-mismatch ((,class (:inherit paren-face-mismatch))))

;;;; smart-mode-line - light
     `(sml/charging ((,class (:foreground ,green))))
     `(sml/discharging ((,class (:foreground ,yellow :weight bold))))
     `(sml/filename ((,class (:foreground ,magenta :weight bold))))
     `(sml/git ((,class (:foreground ,blue))))
     `(sml/modified ((,class (:foreground ,cyan))))
     `(sml/outside-modified ((,class (:foreground ,cyan))))
     `(sml/process ((,class (:weight bold))))
     `(sml/read-only ((,class (:foreground ,cyan))))
     `(sml/sudo ((,class (:foreground ,orange :weight bold))))
     `(sml/vc-edited ((,class (:foreground ,green))))

;;;; smartparens - light
     `(sp-pair-overlay-face ((,class (:background ,grey))))
     `(sp-show-pair-match-face ((,class (:inherit show-paren-match))))
     `(sp-show-pair-mismatch-face ((,class (:inherit show-paren-mismatch))))

;;;; smerge-tool - light
     `(smerge-base ((,class (:background ,blue))))
     `(smerge-lower ((,class (:background ,green))))
     `(smerge-markers ((,class (:background ,spacegrey5 :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(smerge-mine ((,class (:inherit smerge-upper))))
     `(smerge-other ((,class (:inherit smerge-lower))))
     `(smerge-refined-added ((,class (:inherit diff-added :inverse-video t))))
     `(smerge-refined-removed ((,class (:inherit diff-removed :inverse-video t))))
     `(smerge-upper ((,class (:background ,red))))

;;;; solaire-mode - light
     `(solaire-default-face ((,class (:inherit default :background ,bg-other))))
     `(solaire-hl-line-face ((,class (:inherit hl-line :background ,bg :extend t))))
     `(solaire-mode-line-face ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))
     `(solaire-mode-line-inactive-face ((,class (:background ,bg-other :foreground ,fg-other :distant-foreground ,bg-other))))
     `(solaire-org-hide-face ((,class (:inherit org-hide))))

;;;; spaceline - light
     `(spaceline-evil-emacs ((,class (:background ,cyan))))
     `(spaceline-evil-insert ((,class (:background ,green))))
     `(spaceline-evil-motion ((,class (:background ,purple))))
     `(spaceline-evil-normal ((,class (:background ,blue))))
     `(spaceline-evil-replace ((,class (:background ,orange))))
     `(spaceline-evil-visual ((,class (:background ,grey))))
     `(spaceline-flycheck-error ((,class (:inherit error :distant-background ,spacegrey0))))
     `(spaceline-flycheck-info ((,class (:inherit success :distant-background ,spacegrey0))))
     `(spaceline-flycheck-warning ((,class (:inherit warning :distant-background ,spacegrey0))))
     `(spaceline-highlight-face ((,class (:background ,orange))))
     `(spaceline-modified ((,class (:background ,orange))))
     `(spaceline-python-venv ((,class (:foreground ,purple :distant-foreground ,magenta))))
     `(spaceline-unmodified ((,class (:background ,orange))))

;;;; stripe-buffer - light
     `(stripe-highlight ((,class (:background ,spacegrey3))))

;;;; swiper - light
     `(swiper-line-face ((,class (:background ,blue :foreground ,spacegrey0))))
     `(swiper-match-face-1 ((,class (:inherit unspecified :background ,spacegrey0 :foreground ,spacegrey5))))
     `(swiper-match-face-2 ((,class (:inherit unspecified :background ,orange :foreground ,spacegrey0 :weight bold))))
     `(swiper-match-face-3 ((,class (:inherit unspecified :background ,purple :foreground ,spacegrey0 :weight bold))))
     `(swiper-match-face-4 ((,class (:inherit unspecified :background ,green :foreground ,spacegrey0 :weight bold))))

;;;; tabbar - light
     `(tabbar-button ((,class (:foreground ,fg :background ,bg))))
     `(tabbar-button-highlight ((,class (:inherit tabbar-button :inverse-video t))))
     `(tabbar-default ((,class (:foreground ,bg :background ,bg :height 1.0))))
     `(tabbar-highlight ((,class (:foreground ,fg :background ,grey :distant-foreground ,bg))))
     `(tabbar-modified ((,class (:inherit tabbar-default :foreground ,red :weight bold))))
     `(tabbar-selected ((,class (:inherit tabbar-default :weight bold :foreground ,fg :background ,bg-other))))
     `(tabbar-selected-modified ((,class (:inherit tabbar-selected :foreground ,green))))
     `(tabbar-unselected ((,class (:inherit tabbar-default :foreground ,spacegrey5))))
     `(tabbar-unselected-modified ((,class (:inherit tabbar-modified))))

;;;; tab-bar - light
     `(tab-bar ((,class (:inherit tab-line))))
     `(tab-bar-tab ((,class (:inherit tab-line-tab))))
     `(tab-bar-tab-inactive ((,class (:inherit tab-line-tab-inactive))))

;;;; tab-line - light
     `(tab-line ((,class (:background ,bg-other :foreground ,bg-other))))
     `(tab-line-close-highlight ((,class (:foreground ,orange))))
     `(tab-line-highlight ((,class (:inherit tab-line-tab))))
     `(tab-line-tab ((,class (:background ,bg :foreground ,fg))))
     `(tab-line-tab-current ((,class (:background ,bg :foreground ,fg))))
     `(tab-line-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; telephone-line - light
     `(telephone-line-accent-active ((,class (:foreground ,fg :background ,spacegrey4))))
     `(telephone-line-accent-inactive ((,class (:foreground ,fg :background ,spacegrey2))))
     `(telephone-line-evil ((,class (:foreground ,fg :weight bold))))
     `(telephone-line-evil-emacs ((,class (:background ,purple :weight bold))))
     `(telephone-line-evil-insert ((,class (:background ,green :weight bold))))
     `(telephone-line-evil-motion ((,class (:background ,blue :weight bold))))
     `(telephone-line-evil-normal ((,class (:background ,red :weight bold))))
     `(telephone-line-evil-operator ((,class (:background ,magenta :weight bold))))
     `(telephone-line-evil-replace ((,class (:background ,bg-other :weight bold))))
     `(telephone-line-evil-visual ((,class (:background ,orange :weight bold))))
     `(telephone-line-projectile ((,class (:foreground ,green))))

;;;; term - light
     `(term ((,class (:foreground ,fg))))
     `(term-bold ((,class (:weight bold))))
     `(term-color-black ((,class (:background ,spacegrey0 :foreground ,spacegrey0))))
     `(term-color-blue ((,class (:background ,blue :foreground ,blue))))
     `(term-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
     `(term-color-green ((,class (:background ,green :foreground ,green))))
     `(term-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
     `(term-color-purple ((,class (:background ,purple :foreground ,purple))))
     `(term-color-red ((,class (:background ,red :foreground ,red))))
     `(term-color-white ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))
     `(term-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

;;;; tldr - light
     `(tldr-code-block ((,class (:foreground ,green :background ,grey :weight semi-bold))))
     `(tldr-command-argument ((,class (:foreground ,fg :background ,grey))))
     `(tldr-command-itself ((,class (:foreground ,bg :background ,green :weight semi-bold))))
     `(tldr-description ((,class (:foreground ,fg :weight semi-bold))))
     `(tldr-introduction ((,class (:foreground ,blue :weight semi-bold))))
     `(tldr-title ((,class (:foreground ,yellow :bold t :height 1.4))))

;;;; treemacs - light
     `(treemacs-directory-face ((,class (:foreground ,fg))))
     `(treemacs-file-face ((,class (:foreground ,fg))))
     `(treemacs-git-added-face ((,class (:foreground ,green))))
     `(treemacs-git-conflict-face ((,class (:foreground ,red))))
     `(treemacs-git-modified-face ((,class (:foreground ,magenta))))
     `(treemacs-git-untracked-face ((,class (:inherit font-lock-doc-face))))
     `(treemacs-root-face ((,class (:inherit font-lock-string-face :weight bold :height 1.2))))
     `(treemacs-tags-face ((,class (:foreground ,orange))))

;;;; typescript-mode - light
     `(typescript-jsdoc-tag ((,class (:foreground ,spacegrey5))))
     `(typescript-jsdoc-type ((,class (:foreground ,spacegrey5))))
     `(typescript-jsdoc-value ((,class (:foreground ,spacegrey5))))

;;;; undo-tree - light
     `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,blue))))
     `(undo-tree-visualizer-current-face ((,class (:foreground ,green :weight bold))))
     `(undo-tree-visualizer-default-face ((,class (:foreground ,spacegrey5))))
     `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow))))
     `(undo-tree-visualizer-unmodified-face ((,class (:foreground ,spacegrey5))))

;;;; vimish-fold - light
     `(vimish-fold-fringe ((,class (:foreground ,purple))))
     `(vimish-fold-overlay ((,class (:inherit font-lock-comment-face :background ,spacegrey0 :weight light))))

;;;; volatile-highlights - light
     `(vhl/default-face ((,class (:background ,grey))))

;;;; vterm - light
     `(vterm ((,class (:foreground ,fg))))
     `(vterm-color-black ((,class (:background ,spacegrey0 :foreground ,spacegrey0))))
     `(vterm-color-blue ((,class (:background ,blue :foreground ,blue))))
     `(vterm-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
     `(vterm-color-default ((,class (:foreground ,fg))))
     `(vterm-color-green ((,class (:background ,green :foreground ,green))))
     `(vterm-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
     `(vterm-color-purple ((,class (:background ,purple :foreground ,purple))))
     `(vterm-color-red ((,class (:background ,red :foreground ,red))))
     `(vterm-color-white ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))
     `(vterm-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

;;;; web-mode - light
     `(web-mode-block-control-face ((,class (:foreground ,orange))))
     `(web-mode-block-control-face ((,class (:foreground ,orange))))
     `(web-mode-block-delimiter-face ((,class (:foreground ,orange))))
     `(web-mode-css-property-name-face ((,class (:foreground ,yellow))))
     `(web-mode-doctype-face ((,class (:foreground ,spacegrey5))))
     `(web-mode-html-attr-name-face ((,class (:foreground ,yellow))))
     `(web-mode-html-attr-value-face ((,class (:foreground ,green))))
     `(web-mode-html-entity-face ((,class (:foreground ,cyan :inherit italic))))
     `(web-mode-html-tag-bracket-face ((,class (:foreground ,blue))))
     `(web-mode-html-tag-bracket-face ((,class (:foreground ,fg))))
     `(web-mode-html-tag-face ((,class (:foreground ,blue))))
     `(web-mode-json-context-face ((,class (:foreground ,green))))
     `(web-mode-json-key-face ((,class (:foreground ,green))))
     `(web-mode-keyword-face ((,class (:foreground ,magenta))))
     `(web-mode-string-face ((,class (:foreground ,green))))
     `(web-mode-type-face ((,class (:foreground ,yellow))))

;;;; wgrep - light
     `(wgrep-delete-face ((,class (:foreground ,spacegrey3 :background ,red))))
     `(wgrep-done-face ((,class (:foreground ,blue))))
     `(wgrep-face ((,class (:weight bold :foreground ,green :background ,spacegrey5))))
     `(wgrep-file-face ((,class (:foreground ,spacegrey5))))
     `(wgrep-reject-face ((,class (:foreground ,red :weight bold))))

;;;; which-func - light
     `(which-func ((,class (:foreground ,blue))))

;;;; which-key - light
     `(which-key-command-description-face ((,class (:foreground ,blue))))
     `(which-key-group-description-face ((,class (:foreground ,magenta))))
     `(which-key-key-face ((,class (:foreground ,green))))
     `(which-key-local-map-description-face ((,class (:foreground ,purple))))

;;;; whitespace - light
     `(whitespace-empty ((,class (:background ,spacegrey3))))
     `(whitespace-indentation ((,class (:foreground ,spacegrey4 :background ,spacegrey3))))
     `(whitespace-line ((,class (:background ,spacegrey0 :foreground ,red :weight bold))))
     `(whitespace-newline ((,class (:foreground ,spacegrey4))))
     `(whitespace-space ((,class (:foreground ,spacegrey4))))
     `(whitespace-tab ((,class (:foreground ,spacegrey4 :background ,spacegrey3))))
     `(whitespace-trailing ((,class (:inherit trailing-whitespace))))

;;;; widget - light
     `(widget-button ((,class (:foreground ,fg :weight bold))))
     `(widget-button-pressed ((,class (:foreground ,red))))
     `(widget-documentation ((,class (:foreground ,green))))
     `(widget-field ((,class (:foreground ,fg :background ,spacegrey8 :extend nil))))
     `(widget-inactive ((,class (:foreground ,grey :background ,bg-other))))
     `(widget-single-line-field ((,class (:foreground ,fg :background ,spacegrey8))))

;;;; window-divider - light
     `(window-divider ((,class (:inherit vertical-border))))
     `(window-divider-first-pixel ((,class (:inherit window-divider))))
     `(window-divider-last-pixel ((,class (:inherit window-divider))))

;;;; woman - light
     `(woman-bold ((,class (:inherit bold :foreground ,fg))))
     `(woman-italic ((,class (:inherit underline :foreground ,magenta))))

;;;; workgroups2 - light
     `(wg-brace-face ((,class (:foreground ,orange))))
     `(wg-current-workgroup-face ((,class (:foreground ,spacegrey0 :background ,orange))))
     `(wg-divider-face ((,class (:foreground ,grey))))
     `(wg-other-workgroup-face ((,class (:foreground ,spacegrey5))))

;;;; yasnippet - light
     `(yas-field-highlight-face ((,class (:inherit match))))

     (custom-theme-set-variables
      'timu-spacegrey
      `(ansi-color-names-vector [bg, red, green, teal, cyan, blue, yellow, fg])))))


;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory
                (file-name-directory load-file-name))))

(provide-theme 'timu-spacegrey)

;;; timu-spacegrey-theme.el ends here
