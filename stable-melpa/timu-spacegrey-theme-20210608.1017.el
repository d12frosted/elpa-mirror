;;; timu-spacegrey-theme.el --- Color theme inspired by the Spacegray theme in Sublime Text  -*- lexical-binding:t -*-

;; Copyright (C) 2021 Aimé Bertrand

;; Author: Aimé Bertrand <aime.bertrand@macowners.club>
;; Maintainer: Aimé Bertrand <aime.bertrand@macowners.club>
;; Created: 06 Jun 2021
;; Keywords: faces themes
;; Package-Version: 20210608.1017
;; Package-Commit: 9035384809a5ad50d72792ca303234a08eec20a8
;; Version: 1.2
;; Package-Requires: ((emacs "27.1"))
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
;; I. Used Doom themes for boilerplate for modes & packages.
;;
;; II. Installation
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

;;; Code:

(deftheme timu-spacegrey
  "Custom theme inspired by the spacegray theme in Sublime Text.
Sourced other themes to get information about font faces for packages.")


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
      (darkcyan "#5699af")

      (highlight "#d08770")
      (vertical-bar "#2b303b")
      (selection "#4f5b66")
      (builtin "#d08770")
      (comments "#65737e")
      (doc-comments "#65737e")
      (constants "#d08770")
      (functions "#8fa1b3")
      (keywords "#b48ead")
      (methods "#8fa1b3")
      (operators "#c0c5ce")
      (type "#ecbe7b")
      (strings "#a3be8c")
      (variables "#bf616a")
      (numbers "#d08770")
      (region "#4f5b66")
      (error "#bf616a")
      (warning "#ecbe7b")
      (success "#a3be8c")
      (vc-modified "#d08770")
      (vc-added "#a3be8c")
      (vc-deleted "#bf616a"))

  (custom-theme-set-faces
   'timu-spacegrey

;;; Custom faces
;;;; Default faces
   `(bold ((,class (:weight bold :foreground ,spacegrey8))))
   `(italic ((,class (:slant  italic))))
   `(bold-italic ((,class (:inherit (bold italic)))))
   `(default ((,class (:background ,bg :foreground ,fg))))
   `(fringe ((,class (:inherit default :foreground ,spacegrey4))))
   `(region ((,class (:background ,region :foreground nil :distant-foreground ,bg :extend t))))
   `(highlight ((,class (:background ,highlight  :foreground ,spacegrey0 :distant-foreground ,spacegrey8))))
   `(cursor ((,class (:background ,highlight))))
   `(shadow ((,class (:foreground ,spacegrey5))))
   `(minibuffer-prompt ((,class (:foreground ,highlight))))
   `(tooltip ((,class (:background ,spacegrey3 :foreground ,fg))))
   `(secondary-selection ((,class (:background ,grey :extend t))))
   `(lazy-highlight ((,class (:background ,darkblue  :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
   `(match ((,class (:foreground ,green :background ,spacegrey0 :weight bold))))
   `(trailing-whitespace ((,class (:background ,red))))
   `(nobreak-space ((,class (:inherit default :underline nil))))
   `(vertical-border ((,class (:background ,vertical-bar :foreground ,vertical-bar))))
   `(link ((,class (:foreground ,highlight :underline t :weight bold))))
   `(error ((,class (:foreground ,error))))
   `(warning ((,class (:foreground ,warning))))
   `(success ((,class (:foreground ,success))))

;;;; font-lock
   `(font-lock-builtin-face ((,class (:foreground ,builtin))))
   `(font-lock-comment-face ((,class (:foreground ,comments))))
   `(font-lock-comment-delimiter-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-doc-face ((,class (:inherit font-lock-comment-face :foreground ,doc-comments))))
   `(font-lock-constant-face ((,class (:foreground ,constants))))
   `(font-lock-function-name-face ((,class (:foreground ,functions))))
   `(font-lock-keyword-face ((,class (:foreground ,keywords))))
   `(font-lock-string-face ((,class (:foreground ,strings))))
   `(font-lock-type-face ((,class (:foreground ,type))))
   `(font-lock-variable-name-face ((,class (:foreground ,variables))))
   `(font-lock-warning-face ((,class (:inherit warning))))
   `(font-lock-negation-char-face ((,class (:inherit bold :foreground ,operators))))
   `(font-lock-preprocessor-face ((,class (:inherit bold :foreground ,operators))))
   `(font-lock-preprocessor-char-face ((,class (:inherit bold :foreground ,operators))))
   `(font-lock-regexp-grouping-backslash ((,class (:inherit bold :foreground ,operators))))
   `(font-lock-regexp-grouping-construct ((,class (:inherit bold :foreground ,operators))))

;;;; mode-line & header-line
   `(mode-line ((,class (:background ,bg-other :foreground ,fg :distant-foreground ,bg))))
   `(mode-line-inactive ((,class (:background ,bg-other :foreground ,comments :distant-foreground ,bg-other))))
   `(mode-line-emphasis ((,class (:foreground ,highlight :distant-foreground ,bg))))
   `(mode-line-highlight ((,class (:inherit highlight :distant-foreground ,bg))))
   `(mode-line-buffer-id ((,class (:weight bold))))
   `(header-line ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))

;;;; tab-line & tab-bar
   `(tab-line ((,class (:background ,bg-other :foreground ,bg-other))))
   `(tab-line-tab ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))
   `(tab-line-tab-current ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-highlight ((,class (:inherit tab-line-tab))))
   `(tab-line-close-highlight ((,class (:foreground ,highlight))))
   `(tab-bar ((,class (:inherit tab-line))))
   `(tab-bar-tab ((,class (:inherit tab-line-tab))))
   `(tab-bar-tab-inactive ((,class (:inherit tab-line-tab-inactive))))

;;;; Line numbers
   `(line-number ((,class (:inherit default :foreground ,spacegrey5 :weight normal))))
   `(line-number-current-line ((,class (:inherit (hl-line default) :foreground ,fg :weight normal))))

;;; Package faces
;;;; agda-mode
   `(agda2-highlight-keyword-face ((,class (:inherit font-lock-keyword-face))))
   `(agda2-highlight-string-face ((,class (:inherit font-lock-string-face))))
   `(agda2-highlight-number-face ((,class (:inherit font-lock-string-face))))
   `(agda2-highlight-symbol-face ((,class (:inherit font-lock-variable-name-face))))
   `(agda2-highlight-primitive-type-face ((,class (:inherit font-lock-type-face))))
   `(agda2-highlight-bound-variable-face ((,class (:inherit font-lock-variable-name-face))))
   `(agda2-highlight-inductive-constructor-face ((,class (:inherit font-lock-type-face))))
   `(agda2-highlight-coinductive-constructor-face ((,class (:inherit font-lock-type-face))))
   `(agda2-highlight-datatype-face ((,class (:inherit font-lock-type-face))))
   `(agda2-highlight-field-face ((,class (:inherit font-lock-type-face))))
   `(agda2-highlight-function-face ((,class (:inherit font-lock-function-name-face))))
   `(agda2-highlight-module-face ((,class (:inherit font-lock-variable-name-face))))
   `(agda2-highlight-postulate-face ((,class (:inherit font-lock-type-face))))
   `(agda2-highlight-primitive-face ((,class (:inherit font-lock-type-face))))
   `(agda2-highlight-macro-face ((,class (:inherit font-lock-function-name-face))))
   `(agda2-highlight-record-face ((,class (:inherit font-lock-type-face))))
   `(agda2-highlight-error-face ((,class (:inherit font-lock-warning-face))))
   `(agda2-highlight-dotted-face ((,class (:inherit font-lock-variable-name-face))))
   `(agda2-highlight-unsolved-meta-face ((,class (:inherit font-lock-warning-face))))
   `(agda2-highlight-unsolved-constraint-face ((,class (:inherit font-lock-warning-face))))
   `(agda2-highlight-termination-problem-face ((,class (:inherit font-lock-warning-face))))
   `(agda2-highlight-positivity-problem-face ((,class (:inherit font-lock-warning-face))))
   `(agda2-highlight-incomplete-pattern-face ((,class (:inherit font-lock-warning-face))))
   `(agda2-highlight-typechecks-face ((,class (:inherit font-lock-warning-face))))

;;;; auctex
   `(font-latex-bold-face ((,class (:inherit bold))))
   `(font-latex-italic-face ((,class (:inherit italic))))
   `(font-latex-math-face ((,class (:foreground ,blue))))
   `(font-latex-sectioning-0-face ((,class (:foreground ,blue :weight ultra-bold))))
   `(font-latex-sectioning-1-face ((,class (:foreground ,purple :weight semi-bold))))
   `(font-latex-sectioning-2-face ((,class (:foreground ,magenta :weight semi-bold))))
   `(font-latex-sectioning-3-face ((,class (:foreground ,blue :weight semi-bold))))
   `(font-latex-sectioning-4-face ((,class (:foreground ,purple :weight semi-bold))))
   `(font-latex-sectioning-5-face ((,class (:foreground ,magenta :weight semi-bold))))
   `(font-latex-script-char-face ((,class (:foreground ,darkblue))))
   `(font-latex-string-face ((,class (:inherit font-lock-string-face))))
   `(font-latex-warning-face ((,class (:inherit font-lock-warning-face))))
   `(font-latex-verbatim-face ((,class (:inherit fixed-pitch :foreground ,magenta :slant italic))))
   `(TeX-error-description-error ((,class (:inherit error :weight bold))))
   `(TeX-error-description-warning ((,class (:inherit warning :weight bold))))
   `(TeX-error-description-tex-said ((,class (:inherit success :weight bold))))

;;;; alert
   `(alert-high-face ((,class (:inherit bold :foreground ,warning))))
   `(alert-low-face ((,class (:foreground ,grey))))
   `(alert-moderate-face ((,class (:inherit bold :foreground ,fg-other))))
   `(alert-trivial-face ((,class (:foreground ,doc-comments))))
   `(alert-urgent-face ((,class (:inherit bold :foreground ,error))))

;;;; all-the-icons
   `(all-the-icons-blue ((,class (:foreground ,blue))))
   `(all-the-icons-blue-alt ((,class (:foreground ,teal))))
   `(all-the-icons-cyan ((,class (:foreground ,cyan))))
   `(all-the-icons-cyan-alt ((,class (:foreground ,cyan))))
   `(all-the-icons-dblue ((,class (:foreground ,darkblue))))
   `(all-the-icons-dcyan ((,class (:foreground ,darkcyan))))
   `(all-the-icons-dgreen ((,class (:foreground ,green))))
   `(all-the-icons-dmaroon ((,class (:foreground ,purple))))
   `(all-the-icons-dorange ((,class (:foreground ,orange))))
   `(all-the-icons-dmagenta ((,class (:foreground ,red))))
   `(all-the-icons-dpurple ((,class (:foreground ,magenta))))
   `(all-the-icons-dred ((,class (:foreground ,red))))
   `(all-the-icons-dsilver ((,class (:foreground ,grey))))
   `(all-the-icons-dyellow ((,class (:foreground ,yellow))))
   `(all-the-icons-green ((,class (:foreground ,green))))
   `(all-the-icons-lblue ((,class (:foreground ,blue))))
   `(all-the-icons-lcyan ((,class (:foreground ,cyan))))
   `(all-the-icons-lgreen ((,class (:foreground ,green))))
   `(all-the-icons-lmaroon ((,class (:foreground ,purple))))
   `(all-the-icons-lorange ((,class (:foreground ,orange))))
   `(all-the-icons-lmagenta ((,class (:foreground ,red))))
   `(all-the-icons-lpurple ((,class (:foreground ,magenta))))
   `(all-the-icons-lred ((,class (:foreground ,red))))
   `(all-the-icons-lsilver ((,class (:foreground ,grey))))
   `(all-the-icons-lyellow ((,class (:foreground ,yellow))))
   `(all-the-icons-maroon ((,class (:foreground ,purple))))
   `(all-the-icons-orange ((,class (:foreground ,orange))))
   `(all-the-icons-magenta ((,class (:foreground ,red))))
   `(all-the-icons-purple ((,class (:foreground ,magenta))))
   `(all-the-icons-purple-alt ((,class (:foreground ,magenta))))
   `(all-the-icons-red ((,class (:foreground ,red))))
   `(all-the-icons-red-alt ((,class (:foreground ,red))))
   `(all-the-icons-silver ((,class (:foreground ,grey))))
   `(all-the-icons-yellow ((,class (:foreground ,yellow))))

;;;; annotate
   `(annotate-annotation ((,class (:background ,highlight :foreground ,doc-comments))))
   `(annotate-annotation-secondary ((,class (:background ,green :foreground ,doc-comments))))
   `(annotate-highlight ((,class (:background ,highlight :underline ,highlight))))
   `(annotate-highlight-secondary ((,class (:background ,green :underline ,green))))

;;;; anzu
   `(anzu-replace-highlight ((,class (:background ,spacegrey0 :foreground ,red :weight bold :strike-through t))))
   `(anzu-replace-to ((,class (:background ,spacegrey0 :foreground ,green :weight bold))))

;;;; avy
   `(avy-background-face ((,class (:foreground ,comments))))
   `(avy-lead-face ((,class (:background ,highlight :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(avy-lead-face-0 ((,class (:inherit avy-lead-face :background ,highlight))))
   `(avy-lead-face-1 ((,class (:inherit avy-lead-face :background ,highlight))))
   `(avy-lead-face-2 ((,class (:inherit avy-lead-face :background ,highlight))))

;;;; bookmark+
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
   `(bmkp-local-file-without-region ((,class (:foreground ,comments))))
   `(bmkp-man ((,class (:foreground ,magenta))))
   `(bmkp-no-jump ((,class (:foreground ,comments))))
   `(bmkp-no-local ((,class (:foreground ,yellow))))
   `(bmkp-non-file ((,class (:foreground ,green))))
   `(bmkp-remote-file ((,class (:foreground ,orange))))
   `(bmkp-sequence ((,class (:foreground ,blue))))
   `(bmkp-su-or-sudo ((,class (:foreground ,red))))
   `(bmkp-t-mark ((,class (:foreground ,magenta))))
   `(bmkp-url ((,class (:foreground ,blue :underline t))))
   `(bmkp-variable-list ((,class (:foreground ,green))))

;;;; calfw
   `(cfw:face-title ((,class (:foreground ,blue :weight bold :height 2.0 :inherit variable-pitch))))
   `(cfw:face-header ((,class (:foreground ,blue :weight bold))))
   `(cfw:face-sunday ((,class (:foreground ,red :weight bold))))
   `(cfw:face-saturday ((,class (:foreground ,red :weight bold))))
   `(cfw:face-holiday ((,class (:foreground nil :background ,bg-other :weight bold))))
   `(cfw:face-grid ((,class (:foreground ,vertical-bar))))
   `(cfw:face-periods ((,class (:foreground ,yellow))))
   `(cfw:face-toolbar ((,class (:foreground nil :background nil))))
   `(cfw:face-toolbar-button-off ((,class (:foreground ,spacegrey6 :weight bold :inherit variable-pitch))))
   `(cfw:face-toolbar-button-on ((,class (:foreground ,blue :weight bold :inherit variable-pitch))))
   `(cfw:face-default-content ((,class (:foreground ,fg))))
   `(cfw:face-day-title ((,class (:foreground ,fg :weight bold))))
   `(cfw:face-today-title ((,class (:foreground ,bg :background ,blue :weight bold))))
   `(cfw:face-default-day ((,class (:weight bold))))
   `(cfw:face-today ((,class (:foreground nil :background nil :weight bold))))
   `(cfw:face-annotation ((,class (:foreground ,magenta))))
   `(cfw:face-disable ((,class (:foreground ,grey))))
   `(cfw:face-select ((,class (:background ,region))))

;;;; centaur-tabs
   `(centaur-tabs-default ((,class (:inherit tab-bar))))
   `(centaur-tabs-selected ((,class (:inherit tab-bar-tab))))
   `(centaur-tabs-unselected ((,class (:inherit tab-bar-tab-inactive))))
   `(centaur-tabs-selected-modified ((,class (:background ,bg :foreground ,teal))))
   `(centaur-tabs-unselected-modified ((,class (:background ,bg-other :foreground ,teal))))
   `(centaur-tabs-active-bar-face ((,class (:background ,highlight))))
   `(centaur-tabs-modified-marker-selected ((,class (:foreground ,highlight :inherit centaur-tabs-selected))))
   `(centaur-tabs-modified-marker-unselected ((,class (:foreground ,highlight :inherit centaur-tabs-unselected))))

;;;; company
   `(company-tooltip ((,class (:inherit tooltip))))
   `(company-tooltip-common ((,class (:foreground ,highlight :distant-foreground ,spacegrey0 :weight bold))))
   `(company-tooltip-search ((,class (:background ,highlight :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(company-tooltip-search-selection ((,class (:background ,selection))))
   `(company-tooltip-selection ((,class (:background ,selection :weight bold))))
   `(company-tooltip-mouse ((,class (:background ,purple :foreground ,bg :distant-foreground ,fg))))
   `(company-tooltip-annotation ((,class (:foreground ,magenta :distant-foreground ,bg))))
   `(company-scrollbar-bg ((,class (:inherit tooltip))))
   `(company-scrollbar-fg ((,class (:background ,highlight))))
   `(company-preview ((,class (:foreground ,comments))))
   `(company-preview-common ((,class (:background ,spacegrey3 :foreground ,highlight))))
   `(company-preview-search ((,class (:inherit company-tooltip-search))))
   `(company-template-field ((,class (:inherit match))))

;;;; company-box
   `(company-box-candidate ((,class (:foreground ,fg))))

;;;; circe
   `(circe-fool ((,class (:foreground ,doc-comments))))
   `(circe-highlight-nick-face ((,class (:weight bold :foreground ,constants))))
   `(circe-prompt-face ((,class (:weight bold :foreground ,highlight))))
   `(circe-server-face ((,class (:foreground ,comments))))
   `(circe-my-message-face ((,class (:weight bold))))

;;;; cperl
   `(cperl-array-face ((,class (:weight bold :inherit font-lock-variable-name-face))))
   `(cperl-hash-face ((,class (:weight bold :slant italic :inherit font-lock-variable-name-face))))
   `(cperl-nonoverridable-face ((,class (:inherit font-lock-builtin-face))))

;;;; compilation
   `(compilation-column-number ((,class (:inherit font-lock-comment-face))))
   `(compilation-line-number ((,class (:foreground ,highlight))))
   `(compilation-error ((,class (:inherit error :weight bold))))
   `(compilation-warning ((,class (:inherit warning :slant italic))))
   `(compilation-info ((,class (:inherit success))))
   `(compilation-mode-line-exit ((,class (:inherit compilation-info))))
   `(compilation-mode-line-fail ((,class (:inherit compilation-error))))

;;;; custom
   `(custom-button ((,class (:foreground ,blue :background ,bg :box (:line-width 1 :style none)))))
   `(custom-button-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 1 :style none)))))
   `(custom-button-pressed-unraised ((,class (:foreground ,bg :background ,magenta :box (:line-width 1 :style none)))))
   `(custom-button-pressed ((,class (:foreground ,bg :background ,blue :box (:line-width 1 :style none)))))
   `(custom-button-mouse ((,class (:foreground ,bg :background ,blue :box (:line-width 1 :style none)))))
   `(custom-variable-button ((,class (:foreground ,green :underline t))))
   `(custom-saved ((,class (:foreground ,green :background ,green :bold bold))))
   `(custom-comment ((,class (:foreground ,fg :background ,region))))
   `(custom-comment-tag ((,class (:foreground ,grey))))
   `(custom-modified ((,class (:foreground ,blue :background ,blue))))
   `(custom-variable-tag ((,class (:foreground ,purple))))
   `(custom-visibility ((,class (:foreground ,blue :underline nil))))
   `(custom-group-subtitle ((,class (:foreground ,red))))
   `(custom-group-tag ((,class (:foreground ,magenta))))
   `(custom-group-tag-1 ((,class (:foreground ,blue))))
   `(custom-set ((,class (:foreground ,yellow :background ,bg))))
   `(custom-themed ((,class (:foreground ,yellow :background ,bg))))
   `(custom-invalid ((,class (:foreground ,red :background ,red))))
   `(custom-variable-obsolete ((,class (:foreground ,grey :background ,bg))))
   `(custom-state ((,class (:foreground ,green :background ,green))))
   `(custom-changed ((,class (:foreground ,blue :background ,bg))))

;;;; diff-hl
   `(diff-hl-change ((,class (:foreground ,vc-modified :background ,vc-modified))))
   `(diff-hl-delete ((,class (:foreground ,vc-deleted :background ,vc-deleted))))
   `(diff-hl-insert ((,class (:foreground ,vc-added :background ,vc-added))))

;;;; diff-mode
   ;;`(diff-added ((,class (:inherit hl-line :foreground ,green))))
   ;;`(diff-changed ((,class (:foreground ,magenta))))
   ;;`(diff-context ((,class (:foreground ,fg))))
   ;;`(diff-removed ((,class (:foreground ,red :background ,spacegrey3))))
   ;;`(diff-header ((,class (:foreground ,cyan :background nil))))
   ;;`(diff-file-header ((,class (:foreground blue :background nil))))
   ;;`(diff-hunk-header ((,class (:foreground magenta))))
   ;;`(diff-refine-added ((,class (:inherit ,diff-added :inverse-video t))))
   ;;`(diff-refine-changed ((,class (:inherit ,diff-changed :inverse-video t))))
   ;;`(diff-refine-removed ((,class (:inherit ,diff-removed :inverse-video t))))

;;;; dired
   `(dired-directory ((,class (:foreground ,darkcyan))))
   `(dired-ignored ((,class (:foreground ,comments))))
   `(dired-flagged ((,class (:foreground ,red))))
   `(dired-header ((,class (:foreground ,blue :weight bold))))
   `(dired-mark ((,class (:foreground ,orange :weight bold))))
   `(dired-marked ((,class (:foreground ,cyan :weight bold :inverse-video t))))
   `(dired-perm-write ((,class (:foreground ,red :underline t))))
   `(dired-symlink ((,class (:foreground ,magenta :weight bold))))
   `(dired-warning ((,class (:foreground ,warning))))

;;;; dired+
   `(diredp-file-name ((,class (:foreground ,spacegrey8))))
   `(diredp-dir-name ((,class (:foreground ,spacegrey8 :weight bold))))
   `(diredp-ignored-file-name ((,class (:foreground ,spacegrey5))))
   `(diredp-compressed-file-suffix ((,class (:foreground ,spacegrey5))))
   `(diredp-symlink ((,class (:foreground ,magenta))))
   `(diredp-dir-heading ((,class (:foreground ,blue :weight bold))))
   `(diredp-file-suffix ((,class (:foreground ,magenta))))
   `(diredp-read-priv ((,class (:foreground ,purple))))
   `(diredp-write-priv ((,class (:foreground ,green))))
   `(diredp-exec-priv ((,class (:foreground ,yellow))))
   `(diredp-rare-priv ((,class (:foreground ,red :weight bold))))
   `(diredp-dir-priv ((,class (:foreground ,blue :weight bold))))
   `(diredp-no-priv ((,class (:foreground ,spacegrey5))))
   `(diredp-number ((,class (:foreground ,purple))))
   `(diredp-date-time ((,class (:foreground ,blue))))

;;;; dired-k
   `(dired-k-modified ((,class (:foreground ,vc-modified :weight bold))))
   `(dired-k-commited ((,class (:foreground ,green :weight bold))))
   `(dired-k-added ((,class (:foreground ,vc-added :weight bold))))
   `(dired-k-untracked ((,class (:foreground ,teal :weight bold))))
   `(dired-k-ignored ((,class (:foreground ,spacegrey5 :weight bold))))
   `(dired-k-directory ((,class (:foreground ,blue :weight bold))))

;;;; dired-subtree
   `(dired-subtree-depth-1-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-2-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-3-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-4-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-5-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-6-face ((,class (:background ,bg-other))))

;;;; diredfl
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
   `(diredfl-ignored-file-name ((,class (:foreground ,comments))))
   `(diredfl-link-priv ((,class (:foreground ,magenta))))
   `(diredfl-no-priv ((,class (:foreground ,fg))))
   `(diredfl-number ((,class (:foreground ,orange))))
   `(diredfl-other-priv ((,class (:foreground ,purple))))
   `(diredfl-rare-priv ((,class (:foreground ,fg))))
   `(diredfl-read-priv ((,class (:foreground ,yellow))))
   `(diredfl-symlink ((,class (:foreground ,magenta))))
   `(diredfl-tagged-autofile-name ((,class (:foreground ,spacegrey5))))
   `(diredfl-write-priv ((,class (:foreground ,red))))

;;;; doom-modeline
   `(doom-modeline-eldoc-bar ((,class (:background ,green))))
   `(doom-modeline-bar-inactive ((,class (:background nil))))

;;;; ediff
   `(ediff-fine-diff-A ((,class (:background ,bg :weight bold :extend t))))
   `(ediff-fine-diff-B ((,class (:inherit ediff-fine-diff-A))))
   `(ediff-fine-diff-C ((,class (:inherit ediff-fine-diff-A))))
   `(ediff-current-diff-A ((,class (:background ,selection :extend t))))
   `(ediff-current-diff-B ((,class (:inherit ediff-current-diff-A))))
   `(ediff-current-diff-C ((,class (:inherit ediff-current-diff-A))))
   `(ediff-even-diff-A ((,class (:inherit hl-line))))
   `(ediff-even-diff-B ((,class (:inherit ediff-even-diff-A))))
   `(ediff-even-diff-C ((,class (:inherit ediff-even-diff-A))))
   `(ediff-odd-diff-A ((,class (:inherit ediff-even-diff-A))))
   `(ediff-odd-diff-B ((,class (:inherit ediff-odd-diff-A))))
   `(ediff-odd-diff-C ((,class (:inherit ediff-odd-diff-A))))

;;;; elfeed
   `(elfeed-log-debug-level-face ((,class (:foreground ,comments))))
   `(elfeed-log-error-level-face ((,class (:inherit error))))
   `(elfeed-log-info-level-face ((,class (:inherit success))))
   `(elfeed-log-warn-level-face ((,class (:inherit warning))))
   `(elfeed-search-date-face ((,class (:foreground ,magenta))))
   `(elfeed-search-feed-face ((,class (:foreground ,blue))))
   `(elfeed-search-tag-face ((,class (:foreground ,comments))))
   `(elfeed-search-title-face ((,class (:foreground ,comments))))
   `(elfeed-search-filter-face ((,class (:foreground ,magenta))))
   `(elfeed-search-unread-count-face ((,class (:foreground ,yellow))))
   `(elfeed-search-unread-title-face ((,class (:foreground ,fg :weight bold))))

;;;; elixir-mode
   `(elixir-atom-face ((,class (:foreground ,cyan))))
   `(elixir-attribute-face ((,class (:foreground ,magenta))))

;;;; elscreen
   `(elscreen-tab-background-face ((,class (:background ,bg))))
   `(elscreen-tab-control-face ((,class (:background ,bg :foreground ,bg))))
   `(elscreen-tab-current-screen-face ((,class (:background ,bg-other :foreground ,fg))))
   `(elscreen-tab-other-screen-face ((,class (:background ,bg :foreground ,fg-other))))

;;;; enh-ruby-mode
   `(enh-ruby-heredoc-delimiter-face ((,class (:inherit font-lock-string-face))))
   `(enh-ruby-op-face ((,class (:foreground ,operators))))
   `(enh-ruby-regexp-delimiter-face ((,class (:inherit enh-ruby-regexp-face))))
   `(enh-ruby-regexp-face ((,class (:foreground ,constants))))
   `(enh-ruby-string-delimiter-face ((,class (:inherit font-lock-string-face))))
   `(erm-syn-errline ((,class (:underline (:style wave :color ,error)))))
   `(erm-syn-warnline ((,class (:underline (:style wave :color ,warning)))))

;;;; erc
   `(erc-button ((,class (:weight bold :underline t))))
   `(erc-default-face ((,class (:inherit default))))
   `(erc-action-face  ((,class (:weight bold))))
   `(erc-command-indicator-face ((,class (:weight bold))))
   `(erc-direct-msg-face ((,class (:foreground ,purple))))
   `(erc-error-face ((,class (:inherit error))))
   `(erc-header-line ((,class (:background ,bg-other :foreground ,highlight))))
   `(erc-input-face ((,class (:foreground ,green))))
   `(erc-current-nick-face ((,class (:foreground ,green :weight bold))))
   `(erc-timestamp-face ((,class (:foreground ,blue :weight bold))))
   `(erc-nick-default-face ((,class (:weight bold))))
   `(erc-nick-msg-face ((,class (:foreground ,purple))))
   `(erc-nick-prefix-face ((,class (:inherit erc-nick-default-face))))
   `(erc-my-nick-face ((,class (:foreground ,green :weight bold))))
   `(erc-my-nick-prefix-face ((,class (:inherit erc-my-nick-face))))
   `(erc-notice-face ((,class (:foreground ,comments))))
   `(erc-prompt-face ((,class (:foreground ,highlight :weight bold))))

;;;; eshell
   `(eshell-prompt ((,class (:foreground ,highlight :weight bold))))
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

;;;; evil
   `(evil-ex-info ((,class (:foreground ,error :slant italic))))
   `(evil-ex-search ((,class (:background ,highlight :foreground ,spacegrey0 :weight bold))))
   `(evil-ex-substitute-matches ((,class (:background ,spacegrey0 :foreground ,red :weight bold :strike-through t))))
   `(evil-ex-substitute-replacement ((,class (:background ,spacegrey0 :foreground ,green :weight bold))))
   `(evil-search-highlight-persist-highlight-face ((,class (:inherit lazy-highlight))))

;;;; evil-mc
   `(evil-mc-cursor-default-face ((,class (:background ,purple :foreground ,spacegrey0 :inverse-video nil))))
   `(evil-mc-region-face ((,class (:inherit region))))
   `(evil-mc-cursor-bar-face ((,class (:height 1 :background ,purple :foreground ,spacegrey0))))
   `(evil-mc-cursor-hbar-face ((,class (:underline (:color ,highlight)))))

;;;; evil-snipe
   `(evil-snipe-first-match-face ((,class (:foreground ,highlight :background ,darkblue :weight bold))))
   `(evil-snipe-matches-face ((,class (:foreground ,highlight :underline t :weight bold))))

;;;; evil-googles
   `(evil-goggles-default-face ((,class (:inherit region))))

;;;; flycheck
   `(flycheck-error ((,class (:underline (:style wave :color ,red)))))
   `(flycheck-warning ((,class (:underline (:style wave :color ,yellow)))))
   `(flycheck-info ((,class (:underline (:style wave :color ,green)))))
   `(flycheck-fringe-error ((,class (:inherit fringe :foreground ,error))))
   `(flycheck-fringe-warning ((,class (:inherit fringe :foreground ,warning))))
   `(flycheck-fringe-info ((,class (:inherit fringe :foreground ,success))))

;;;; flycheck-posframe
   `(flycheck-posframe-face ((,class (:inherit default))))
   `(flycheck-posframe-background-face ((,class (:background ,bg-other))))
   `(flycheck-posframe-error-face ((,class (:inherit flycheck-posframe-face :foreground ,error))))
   `(flycheck-posframe-info-face ((,class (:inherit flycheck-posframe-face :foreground ,fg))))
   `(flycheck-posframe-warning-face ((,class (:inherit flycheck-posframe-face :foreground ,warning))))

;;;; flymake
   `(flymake-error ((,class (:underline (:style wave :color ,red)))))
   `(flymake-note ((,class (:underline (:style wave :color ,green)))))
   `(flymake-warning ((,class (:underline (:style wave :color ,orange)))))

;;;; flyspell
   `(flyspell-incorrect ((,class (:underline (:style wave :color ,error) :inherit unspecified))))
   `(flyspell-duplicate ((,class (:underline (:style wave :color ,warning) :inherit unspecified))))

;;;; flx-ido
   `(flx-highlight-face ((,class (:weight bold :foreground ,yellow :underline nil))))

;;;; git-commit
   `(git-commit-summary ((,class (:foreground ,darkcyan))))
   `(git-commit-overlong-summary ((,class (:inherit error :background ,spacegrey0 :slant italic :weight bold))))
   `(git-commit-nonempty-second-line ((,class (:inherit git-commit-overlong-summary))))
   `(git-commit-keyword ((,class (:foreground ,cyan :slant italic))))
   `(git-commit-pseudo-header ((,class (:foreground ,doc-comments :slant italic))))
   `(git-commit-known-pseudo-header ((,class (:foreground ,doc-comments :weight bold :slant italic))))
   `(git-commit-comment-branch-local ((,class (:foreground ,purple))))
   `(git-commit-comment-branch-remote ((,class (:foreground ,green))))
   `(git-commit-comment-detached ((,class (:foreground ,orange))))
   `(git-commit-comment-heading ((,class (:foreground ,keywords))))
   `(git-commit-comment-file ((,class (:foreground ,magenta))))
   `(git-commit-comment-action)

;;;; git-gutter
   `(git-gutter:modified ((,class (:inherit fringe :foreground ,cyan))))
   `(git-gutter:added ((,class (:inherit fringe :foreground ,vc-added))))
   `(git-gutter:deleted ((,class (:inherit fringe :foreground ,vc-deleted))))

;;;; git-gutter+
   `(git-gutter+-modified ((,class (:inherit fringe :foreground ,cyan :background nil))))
   `(git-gutter+-added ((,class (:inherit fringe :foreground ,vc-added :background nil))))
   `(git-gutter+-deleted ((,class (:inherit fringe :foreground ,vc-deleted :background nil))))

;;;; git-gutter-fringe
   `(git-gutter-fr:modified ((,class (:inherit git-gutter:modified))))
   `(git-gutter-fr:added ((,class (:inherit git-gutter:added))))
   `(git-gutter-fr:deleted ((,class (:inherit git-gutter:deleted))))

;;;; gnus
   `(gnus-group-mail-1 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-2 ((,class (:inherit gnus-group-mail-1))))
   `(gnus-group-mail-3 ((,class (:inherit gnus-group-mail-1))))
   `(gnus-group-mail-1-empty ((,class (:foreground ,spacegrey5))))
   `(gnus-group-mail-2-empty ((,class (:inherit gnus-group-mail-1-empty))))
   `(gnus-group-mail-3-empty ((,class (:inherit gnus-group-mail-1-empty))))
   `(gnus-group-news-1 ((,class (:inherit gnus-group-mail-1))))
   `(gnus-group-news-2 ((,class (:inherit gnus-group-news-1))))
   `(gnus-group-news-3 ((,class (:inherit gnus-group-news-1))))
   `(gnus-group-news-4 ((,class (:inherit gnus-group-news-1))))
   `(gnus-group-news-5 ((,class (:inherit gnus-group-news-1))))
   `(gnus-group-news-6 ((,class (:inherit gnus-group-news-1))))
   `(gnus-group-news-1-empty ((,class (:inherit gnus-group-mail-1-empty))))
   `(gnus-group-news-2-empty ((,class (:inherit gnus-group-news-1-empty))))
   `(gnus-group-news-3-empty ((,class (:inherit gnus-group-news-1-empty))))
   `(gnus-group-news-4-empty ((,class (:inherit gnus-group-news-1-empty))))
   `(gnus-group-news-5-empty ((,class (:inherit gnus-group-news-1-empty))))
   `(gnus-group-news-6-empty ((,class (:inherit gnus-group-news-1-empty))))
   `(gnus-group-mail-low ((,class (:inherit gnus-group-mail-1 :weight normal))))
   `(gnus-group-mail-low-empty ((,class (:inherit gnus-group-mail-1-empty))))
   `(gnus-group-news-low ((,class (:inherit gnus-group-mail-1 :foreground ,spacegrey5))))
   `(gnus-group-news-low-empty ((,class (:inherit gnus-group-news-low :weight normal))))
   `(gnus-header-content ((,class (:inherit message-header-other))))
   `(gnus-header-from ((,class (:inherit message-header-other))))
   `(gnus-header-name ((,class (:inherit message-header-name))))
   `(gnus-header-newsgroups ((,class (:inherit message-header-other))))
   `(gnus-header-subject ((,class (:inherit message-header-subject))))
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
   `(gnus-signature ((,class (:foreground ,yellow))))
   `(gnus-x-face ((,class (:background ,spacegrey5 :foreground ,fg))))

;;;; goggles
   `(goggles-changed ((,class (:inherit region))))
   `(goggles-removed ((,class (:background ,red :extend t))))
   `(goggles-added   ((,class (:background ,green))))

;;;; helm
   `(helm-selection ((,class (:inherit bold :background ,selection :extend t :distant-foreground ,highlight))))
   `(helm-match ((,class (:inherit bold :foreground ,highlight :distant-foreground ,spacegrey8))))
   `(helm-source-header ((,class (:background ,spacegrey2 :foreground ,keywords :weight bold))))
   `(helm-swoop-target-line-face ((,class (:foreground ,highlight :inverse-video t))))
   `(helm-visible-mark ((,class (:inherit (bold highlight)))))
   `(helm-moccur-buffer ((,class (:inherit link))))
   `(helm-ff-file ((,class (:foreground ,fg))))
   `(helm-ff-prefix ((,class (:foreground ,keywords))))
   `(helm-ff-dotted-directory ((,class (:foreground ,grey))))
   `(helm-ff-directory ((,class (:foreground ,variables))))
   `(helm-ff-executable ((,class (:foreground ,spacegrey8 :inherit italic))))
   `(helm-grep-match ((,class (:foreground ,highlight :distant-foreground ,red))))
   `(helm-grep-file ((,class (:foreground ,methods))))
   `(helm-grep-lineno ((,class (:foreground ,spacegrey5))))
   `(helm-grep-finish ((,class (:foreground ,green))))
   `(helm-swoop-target-line-face ((,class (:foreground ,highlight :inverse-video t))))
   `(helm-swoop-target-line-block-face ((,class (:foreground ,yellow))))
   `(helm-swoop-target-word-face ((,class (:foreground ,green :inherit bold))))
   `(helm-swoop-target-number-face ((,class (:foreground ,spacegrey5))))

;;;; helpful
   `(helpful-heading ((,class (:weight bold :height 1.2))))

;;;; hi-lock
   `(hi-yellow ((,class (:background ,yellow))))
   `(hi-magenta ((,class (:background ,purple))))
   `(hi-red-b ((,class (:foreground ,red :weight bold))))
   `(hi-green ((,class (:background ,green))))
   `(hi-green-b ((,class (:foreground ,green :weight bold))))
   `(hi-blue ((,class (:background ,blue))))
   `(hi-blue-b ((,class (:foreground ,blue :weight bold))))

;;;; highlight-numbers-mode
   `(highlight-numbers-number ((,class (:inherit bold :foreground ,numbers))))

;;;; highlight-indentation-mode
   `(highlight-indentation-face ((,class (:inherit hl-line))))
   `(highlight-indentation-current-column-face ((,class (:background ,spacegrey1))))
   `(highlight-indentation-guides-odd-face ((,class (:inherit highlight-indentation-face))))
   `(highlight-indentation-guides-even-face ((,class (:inherit highlight-indentation-face))))

;;;; highlight-quoted-mode
   `(highlight-quoted-symbol ((,class (:foreground ,type))))
   `(highlight-quoted-quote  ((,class (:foreground ,operators))))

;;;; highlight-symbol
   `(highlight-symbol-face ((,class (:background ,region :distant-foreground ,fg-other))))

;;;; highlight-thing
   `(highlight-thing ((,class (:background ,region :distant-foreground ,fg-other))))

;;;; hl-fill-column-face
   `(hl-fill-column-face ((,class (:inherit (hl-line shadow)))))

;;;; hl-line (built-in)
   `(hl-line ((,class (:background ,bg-other :extend t))))

;;;; hl-todo
   `(hl-todo ((,class (:foreground ,red :weight bold))))

;;;; hlinum
   `(linum-highlight-face ((,class (:foreground ,fg :distant-foreground nil :weight normal))))

;;;; hydra
   `(hydra-face-red ((,class (:foreground ,red :weight bold))))
   `(hydra-face-blue ((,class (:foreground ,blue :weight bold))))
   `(hydra-face-amaranth ((,class (:foreground ,purple :weight bold))))
   `(hydra-face-magenta ((,class (:foreground ,magenta :weight bold))))
   `(hydra-face-teal ((,class (:foreground ,teal :weight bold))))

;;;; iedit
   `(iedit-occurrence ((,class (:foreground ,purple :weight bold :inverse-video t))))
   `(iedit-read-only-occurrence ((,class (:inherit region))))

;;;; ido
   `(ido-first-match ((,class (:foreground ,orange))))
   `(ido-indicator ((,class (:foreground ,red :background ,bg))))
   `(ido-only-match ((,class (:foreground ,green))))
   `(ido-subdir ((,class (:foreground ,magenta))))
   `(ido-virtual ((,class (:foreground ,comments))))

;;;; imenu-list
   ;; `(imenu-list-entry-face)
   `(imenu-list-entry-face-0 ((,class (:foreground ,highlight))))
   `(imenu-list-entry-subalist-face-0 ((,class (:inherit imenu-list-entry-face-0 :weight bold))))
   `(imenu-list-entry-face-1 ((,class (:foreground ,green))))
   `(imenu-list-entry-subalist-face-1 ((,class (:inherit imenu-list-entry-face-1 :weight bold))))
   `(imenu-list-entry-face-2 ((,class (:foreground ,yellow))))
   `(imenu-list-entry-subalist-face-2 ((,class (:inherit imenu-list-entry-face-2 :weight bold))))

;;;; indent-guide
   `(indent-guide-face ((,class (:inherit highlight-indentation-face))))

;;;; isearch
   `(isearch ((,class (:inherit lazy-highlight :weight bold))))
   `(isearch-fail ((,class (:background ,error :foreground ,spacegrey0 :weight bold))))

;;;; ivy
   `(ivy-current-match ((,class (:background ,region :distant-foreground nil :extend t))))
   `(ivy-minibuffer-match-face-1 ((,class (:background nil :foreground ,grey :weight light))))
   `(ivy-minibuffer-match-face-2 ((,class (:inherit ivy-minibuffer-match-face-1 :foreground ,purple :background ,spacegrey1 :weight semi-bold))))
   `(ivy-minibuffer-match-face-3 ((,class (:inherit ivy-minibuffer-match-face-2 :foreground ,green :weight semi-bold))))
   `(ivy-minibuffer-match-face-4 ((,class (:inherit ivy-minibuffer-match-face-2 :foreground ,yellow :weight semi-bold))))
   `(ivy-minibuffer-match-highlight ((,class (:foreground ,magenta))))
   `(ivy-highlight-face ((,class (:foreground ,magenta))))
   `(ivy-confirm-face ((,class (:foreground ,success))))
   `(ivy-match-required-face ((,class (:foreground ,error))))
   `(ivy-virtual ((,class (:inherit italic :foreground ,doc-comments))))
   `(ivy-modified-buffer ((,class (:inherit bold :foreground ,vc-modified))))

;;;; ivy-posframe
   `(ivy-posframe ((,class (:background ,bg-other))))
   `(ivy-posframe-border ((,class (:inherit internal-border))))

;;;; selectrum
   `(selectrum-current-candidate ((,class (:background ,region :distant-foreground nil :extend t))))

;;;; jabber
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

;;;; jdee
   `(jdee-font-lock-number-face ((,class (:foreground ,numbers))))
   `(jdee-font-lock-operator-face ((,class (:foreground ,operators))))
   `(jdee-font-lock-constant-face ((,class (:inherit font-lock-constant-face))))
   `(jdee-font-lock-constructor-face ((,class (:foreground ,methods))))
   `(jdee-font-lock-public-face ((,class (:inherit font-lock-keyword-face))))
   `(jdee-font-lock-protected-face ((,class (:inherit font-lock-keyword-face))))
   `(jdee-font-lock-private-face ((,class (:inherit font-lock-keyword-face))))
   `(jdee-font-lock-modifier-face ((,class (:inherit font-lock-type-face))))
   `(jdee-font-lock-doc-tag-face ((,class (:foreground ,magenta))))
   `(jdee-font-lock-italic-face ((,class (:inherit italic))))
   `(jdee-font-lock-bold-face ((,class (:inherit bold))))
   `(jdee-font-lock-link-face ((,class (:foreground ,blue :italic nil :underline t))))

;;;; js2-mode
   `(js2-function-param ((,class (:foreground ,variables))))
   `(js2-function-call ((,class (:foreground ,functions))))
   `(js2-object-property ((,class (:foreground ,magenta))))
   `(js2-jsdoc-tag ((,class (:foreground ,doc-comments))))
   `(js2-external-variable ((,class (:foreground ,operators))))

;;;; keycast
   `(keycast-command ((,class (:inherit mode-line-emphasis))))
   `(keycast-key ((,class (:inherit (bold mode-line-highlight)))))

;;;; ledger-mode
   `(ledger-font-posting-date-face ((,class (:foreground ,blue))))
   `(ledger-font-posting-amount-face ((,class (:foreground ,yellow))))
   `(ledger-font-posting-account-face ((,class (:foreground ,spacegrey8))))
   `(ledger-font-payee-cleared-face ((,class (:foreground ,magenta :weight bold))))
   `(ledger-font-payee-uncleared-face ((,class (:foreground ,spacegrey5  :weight bold))))
   `(ledger-font-xact-highlight-face ((,class (:background ,spacegrey0))))

;;;; linum
   `(linum ((,class (:inherit line-number))))

;;;; linum-relative
   `(linum-relative-current-face ((,class (:inherit line-number-current-line))))

;;;; lui
   `(lui-time-stamp-face ((,class (:foreground ,magenta))))
   `(lui-highlight-face ((,class (:foreground ,highlight))))
   `(lui-button-face ((,class (:foreground ,builtin :underline t))))

;;;; magit
   `(magit-bisect-bad ((,class (:foreground ,red))))
   `(magit-bisect-good ((,class (:foreground ,green))))
   `(magit-bisect-skip ((,class (:foreground ,orange))))
   `(magit-blame-date ((,class (:foreground ,red))))
   `(magit-blame-heading ((,class (:foreground ,orange :background ,spacegrey3 :extend t))))
   `(magit-branch-current ((,class (:foreground ,red))))
   `(magit-branch-local ((,class (:foreground ,red))))
   `(magit-branch-remote ((,class (:foreground ,green))))
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
   `(magit-diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
   `(magit-diff-removed-highlight ((,class (:foreground ,bg :background ,red :weight bold :extend t))))
   `(magit-diff-lines-heading ((,class (:foreground ,yellow :background ,red :extend t :extend t))))
   `(magit-diffstat-added ((,class (:foreground ,green))))
   `(magit-diffstat-removed ((,class (:foreground ,red))))
   `(magit-dimmed ((,class (:foreground ,comments))))
   `(magit-hash ((,class (:foreground ,blue))))
   `(magit-header-line ((,class (:background ,darkblue :foreground ,spacegrey8 :weight bold :box (:line-width 3 :color ,darkblue)))))
   `(magit-log-author ((,class (:foreground ,orange))))
   `(magit-log-date ((,class (:foreground ,blue))))
   `(magit-log-graph ((,class (:foreground ,comments))))
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
   `(magit-refname ((,class (:foreground ,comments))))
   `(magit-section-heading ((,class (:foreground ,darkcyan :weight bold :extend t))))
   `(magit-section-heading-selection ((,class (:foreground ,orange :weight bold :extend t))))
   `(magit-section-highlight ((,class (:inherit hl-line))))
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
   `(magit-filename ((,class (:foreground ,magenta))))
   `(magit-section-secondary-heading ((,class (:foreground ,magenta :weight bold :extend t))))

;;;; mu4e
   `(mu4e-header-key-face ((,class (:foreground ,darkcyan))))
   `(mu4e-highlight-face ((,class (:foreground ,bg :background ,orange))))
   `(mu4e-title-face ((,class (:foreground ,magenta))))
   `(mu4e-header-title-face ((,class (:foreground ,magenta))))
   `(mu4e-replied-face ((,class (:foreground ,darkcyan))))

;;;; make-mode
   `(makefile-targets ((,class (:foreground ,blue))))

;;;; man
   `(Man-overstrike ((,class (:inherit bold :foreground ,operators))))
   `(Man-underline ((,class (:inherit underline :foreground ,keywords))))

;;;; markdown-mode
   `(markdown-header-face ((,class (:inherit bold :foreground ,highlight))))
   `(markdown-header-delimiter-face ((,class (:inherit markdown-header-face))))
   `(markdown-metadata-key-face ((,class (:foreground ,red))))
   `(markdown-list-face ((,class (:foreground ,red))))
   `(markdown-link-face ((,class (:foreground ,highlight))))
   `(markdown-url-face ((,class (:foreground ,purple :weight normal))))
   `(markdown-italic-face ((,class (:inherit italic :foreground ,magenta))))
   `(markdown-bold-face ((,class (:inherit bold :foreground ,orange))))
   `(markdown-markup-face ((,class (:foreground ,operators))))
   `(markdown-blockquote-face ((,class (:inherit italic :foreground ,doc-comments))))
   `(markdown-pre-face ((,class (:foreground ,strings))))
   `(markdown-code-face ((,class (:background ,spacegrey3 :extend t))))
   `(markdown-reference-face ((,class (:foreground ,doc-comments))))
   `(markdown-inline-code-face ((,class (:inherit (markdown-code-face markdown-pre-face) :extend nil))))
   `(markdown-html-attr-name-face ((,class (:inherit font-lock-variable-name-face))))
   `(markdown-html-attr-value-face ((,class (:inherit font-lock-string-face))))
   `(markdown-html-entity-face ((,class (:inherit font-lock-variable-name-face))))
   `(markdown-html-tag-delimiter-face ((,class (:inherit markdown-markup-face))))
   `(markdown-html-tag-name-face ((,class (:inherit font-lock-keyword-face))))

;;;; message
   `(message-header-name ((,class (:foreground ,green))))
   `(message-header-subject ((,class (:foreground ,highlight :weight bold))))
   `(message-header-to ((,class (:foreground ,highlight :weight bold))))
   `(message-header-cc ((,class (:inherit 'message-header-to :foreground ,highlight))))
   `(message-header-other ((,class (:foreground ,magenta))))
   `(message-header-newsgroups ((,class (:foreground ,yellow))))
   `(message-header-xheader ((,class (:foreground ,doc-comments))))
   `(message-separator ((,class (:foreground ,comments))))
   `(message-mml ((,class (:foreground ,comments :slant italic))))
   `(message-cited-text ((,class (:foreground ,purple))))

;;;; mic-paren
   `(paren-face-match ((,class (:foreground ,red :background ,spacegrey0 :weight ultra-bold))))
   `(paren-face-mismatch ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))
   `(paren-face-no-match ((,class (:inherit paren-face-mismatch :weight ultra-bold))))

;;;; minimap
   `(minimap-current-line-face ((,class (:background ,selection))))
   `(minimap-active-region-background ((,class (:background ,vertical-bar))))

;;;; mmm-mode
   `(mmm-init-submode-face ((,class (:background ,red))))
   `(mmm-cleanup-submode-face ((,class (:background ,yellow))))
   `(mmm-declaration-submode-face ((,class (:background ,cyan))))
   `(mmm-comment-submode-face ((,class (:background ,blue))))
   `(mmm-output-submode-face ((,class (:background ,magenta))))
   `(mmm-special-submode-face ((,class (:background ,green))))
   `(mmm-code-submode-face ((,class (:background ,bg-other))))
   `(mmm-default-submode-face ((,class (:background nil))))

;;;; multiple cursors
   `(mc/cursor-face ((,class (:inherit cursor))))

;;;; nav-flash
   `(nav-flash-face ((,class (:background ,selection :foreground ,spacegrey8 :weight bold))))

;;;; neotree
   `(neo-root-dir-face ((,class (:foreground ,strings :background ,bg :box (:line-width 4 :color ,bg)))))
   `(neo-file-link-face ((,class (:foreground ,fg))))
   `(neo-dir-link-face ((,class (:foreground ,highlight))))
   `(neo-expand-btn-face ((,class (:foreground ,highlight))))
   `(neo-vc-edited-face ((,class (:foreground ,yellow))))
   `(neo-vc-added-face ((,class (:foreground ,green))))
   `(neo-vc-removed-face ((,class (:foreground ,red :strike-through t))))
   `(neo-vc-conflict-face ((,class (:foreground ,purple :weight bold))))
   `(neo-vc-ignored-face ((,class (:foreground ,comments))))

;;;; nlinum
   `(nlinum-current-line ((,class (:inherit line-number-current-line))))

;;;; nlinum-hl
   `(nlinum-hl-face ((,class (:inherit line-number-current-line))))

;;;; nlinum-relative
   `(nlinum-relative-current-face ((,class (:inherit line-number-current-line))))

;;;; notmuch
   `(notmuch-message-summary-face ((,class (:foreground ,grey :background nil))))
   `(notmuch-search-count ((,class (:foreground ,comments))))
   `(notmuch-search-date ((,class (:foreground ,numbers))))
   `(notmuch-search-flagged-face ((,class (:foreground ,red))))
   `(notmuch-search-matching-authors ((,class (:foreground blue))))
   `(notmuch-search-non-matching-authors ((,class (:foreground fg))))
   `(notmuch-search-subject ((,class (:foreground ,fg))))
   `(notmuch-search-unread-face ((,class (:weight bold))))
   `(notmuch-tag-added ((,class (:foreground ,green :weight normal))))
   `(notmuch-tag-deleted ((,class (:foreground ,red :weight normal))))
   `(notmuch-tag-face ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tag-flagged ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tag-unread ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tree-match-author-face ((,class (:foreground ,blue :weight bold))))
   `(notmuch-tree-match-date-face ((,class (:foreground ,numbers :weight bold))))
   `(notmuch-tree-match-face ((,class (:foreground ,fg))))
   `(notmuch-tree-match-subject-face ((,class (:foreground ,fg))))
   `(notmuch-tree-match-tag-face ((,class (:foreground ,yellow))))
   `(notmuch-tree-match-tree-face ((,class (:foreground ,comments))))
   `(notmuch-tree-no-match-author-face ((,class (:foreground ,blue))))
   `(notmuch-tree-no-match-date-face ((,class (:foreground ,numbers))))
   `(notmuch-tree-no-match-face ((,class (:foreground ,spacegrey5))))
   `(notmuch-tree-no-match-subject-face ((,class (:foreground ,spacegrey5))))
   `(notmuch-tree-no-match-tag-face ((,class (:foreground ,yellow))))
   `(notmuch-tree-no-match-tree-face ((,class (:foreground ,yellow))))
   `(notmuch-wash-cited-text ((,class (:foreground ,spacegrey4))))
   `(notmuch-wash-toggle-button ((,class (:foreground ,fg))))

;;;; lsp-mode
   `(lsp-face-highlight-textual ((,class (:background ,darkblue :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
   `(lsp-face-highlight-read ((,class (:background ,darkblue :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
   `(lsp-face-highlight-write ((,class (:background ,darkblue :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
   `(lsp-ui-doc-background ((,class (:inherit tooltip))))
   `(lsp-ui-peek-filename ((,class (:inherit mode-line-buffer-id))))
   `(lsp-ui-peek-header ((,class (:foreground ,fg :background ,bg :bold bold))))
   `(lsp-ui-peek-selection ((,class (:foreground ,bg :background ,blue :bold bold))))
   `(lsp-ui-peek-list ((,class (:background ,bg))))
   `(lsp-ui-peek-peek ((,class (:background ,bg))))
   `(lsp-ui-peek-highlight ((,class (:inherit lsp-ui-peek-header :background ,region :foreground ,bg :box t))))
   `(lsp-ui-peek-line-number ((,class (:foreground ,success))))
   `(lsp-ui-sideline-code-action ((,class (:foreground ,highlight))))
   `(lsp-ui-sideline-current-symbol ((,class (:inherit ,highlight))))
   `(lsp-ui-sideline-symbol-info ((,class (:foreground ,comments :background ,bg-other :extend t))))
   `(lsp-headerline-breadcrumb-separator-face ((,class (:foreground ,fg-other))))

;;;; objed
   `(objed-mode-line ((,class (:inherit warning :weight bold))))
   `(objed-hl ((,class (:inherit region :background ,region))))

;;;; org-mode
   `(org-archived ((,class (:foreground ,doc-comments))))
   `(org-block ((,class (:foreground ,spacegrey8 :background ,bg-org :extend t))))
   `(org-block-background ((,class (:background ,bg-org :extend t))))
   `(org-block-begin-line ((,class (:foreground ,comments :slant italic :background ,bg-org :extend t))))
   `(org-block-end-line ((,class (:inherit org-block-begin-line))))
   `(org-checkbox ((,class (:inherit org-todo))))
   `(org-checkbox-statistics-done ((,class (:inherit org-done))))
   `(org-checkbox-statistics-todo ((,class (:inherit org-todo))))
   `(org-code ((,class (:foreground ,green))))
   `(org-date ((,class (:foreground ,yellow))))
   `(org-default ((,class (:inherit variable-pitch))))
   `(org-document-info ((,class (:foreground ,builtin))))
   `(org-document-title ((,class (:foreground ,builtin :weight bold))))
   `(org-done ((,class (:inherit org-headline-done :bold inherit))))
   `(org-ellipsis ((,class (:underline nil :background nil :foreground ,grey))))
   `(org-footnote ((,class (:foreground ,orange))))
   `(org-formula ((,class (:foreground ,cyan))))
   `(org-headline-done ((,class (:foreground ,spacegrey5))))
   `(org-hide ((,class (:foreground ,bg))))
   `(solaire-org-hide-face ((,class (:inherit org-hide))))
   `(org-latex-and-related ((,class (:foreground ,spacegrey8 :weight bold))))
   `(org-link ((,class (:foreground ,darkcyan :underline t))))
   `(org-list-dt ((,class (:foreground ,highlight))))
   `(org-meta-line ((,class (:foreground ,doc-comments))))
   `(org-priority ((,class (:foreground ,red))))
   `(org-property-value ((,class (:foreground ,doc-comments))))
   `(org-quote ((,class (:background ,spacegrey3 :slant italic :extend t))))
   `(org-special-keyword ((,class (:foreground ,doc-comments))))
   `(org-table ((,class (:foreground ,magenta))))
   `(org-tag ((,class (:foreground ,doc-comments :weight normal))))
   `(org-todo ((,class (:foreground ,green :bold inherit))))
   `(org-verbatim ((,class (:foreground ,orange))))
   `(org-warning ((,class (:foreground ,warning))))
   `(org-level-1 ((,class (:foreground ,blue :weight ultra-bold))))
   `(org-level-2 ((,class (:foreground ,magenta :weight bold))))
   `(org-level-3 ((,class (:foreground ,darkcyan :weight bold))))
   `(org-level-4 ((,class (:foreground ,orange))))
   `(org-level-5 ((,class (:foreground ,green))))
   `(org-level-6 ((,class (:foreground ,teal))))
   `(org-level-7 ((,class (:foreground ,purple))))
   `(org-level-8 ((,class (:foreground ,fg))))

;;;; org-agenda
   `(org-agenda-done ((,class (:inherit org-done))))
   `(org-agenda-dimmed-todo-face ((,class (:foreground ,comments))))
   `(org-agenda-date ((,class (:foreground ,magenta :weight ultra-bold))))
   `(org-agenda-date-today ((,class (:foreground ,magenta :weight ultra-bold))))
   `(org-agenda-date-weekend ((,class (:foreground ,magenta :weight ultra-bold))))
   `(org-agenda-structure ((,class (:foreground ,fg :weight ultra-bold))))
   `(org-agenda-clocking ((,class (:background ,blue))))
   `(org-upcoming-deadline ((,class (:foreground ,fg))))
   `(org-upcoming-distant-deadline ((,class (:foreground ,fg))))
   `(org-scheduled ((,class (:foreground ,fg))))
   `(org-scheduled-today ((,class (:foreground ,spacegrey7))))
   `(org-scheduled-previously ((,class (:foreground ,spacegrey8))))
   `(org-time-grid ((,class (:foreground ,comments))))
   `(org-sexp-date ((,class (:foreground ,fg))))

;;;; org-habit
   `(org-habit-clear-face ((,class (:weight bold :background ,spacegrey4))))
   `(org-habit-clear-future-face ((,class (:weight bold :background ,spacegrey3))))
   `(org-habit-ready-face ((,class (:weight bold :background ,blue))))
   `(org-habit-ready-future-face ((,class (:weight bold :background ,blue))))
   `(org-habit-alert-face ((,class (:weight bold :background ,yellow))))
   `(org-habit-alert-future-face ((,class (:weight bold :background ,yellow))))
   `(org-habit-overdue-face ((,class (:weight bold :background ,red))))
   `(org-habit-overdue-future-face ((,class (:weight bold :background ,red))))

;;;; org-journal
   `(org-journal-highlight ((,class (:foreground ,highlight))))
   `(org-journal-calendar-entry-face ((,class (:foreground ,purple :slant italic))))
   `(org-journal-calendar-scheduled-face ((,class (:foreground ,red :slant italic))))

;;;; org-pomodoro
   `(org-pomodoro-mode-line ((,class (:foreground ,red))))
   `(org-pomodoro-mode-line-overtime ((,class (:foreground ,warning :weight bold))))

;;;; org-ref
   `(org-ref-acronym-face ((,class (:foreground ,magenta))))
   `(org-ref-cite-face ((,class (:foreground ,yellow :weight light :underline t))))
   `(org-ref-glossary-face ((,class (:foreground ,purple))))
   `(org-ref-label-face ((,class (:foreground ,blue))))
   `(org-ref-ref-face ((,class (:inherit link :foreground ,teal))))

;;;; outline
   `(outline-1 ((,class (:foreground ,blue :weight ultra-bold))))
   `(outline-2 ((,class (:foreground ,magenta :weight bold))))
   `(outline-3 ((,class (:foreground ,green :weight bold))))
   `(outline-4 ((,class (:foreground ,orange))))
   `(outline-5 ((,class (:foreground ,purple))))
   `(outline-6 ((,class (:foreground ,purple))))
   `(outline-7 ((,class (:foreground ,purple))))
   `(outline-8 ((,class (:foreground ,fg))))

;;;; parenface
   `(paren-face ((,class (:foreground ,comments))))

;;;; parinfer
   `(parinfer-pretty-parens:dim-paren-face ((,class (:foreground ,spacegrey5))))
   `(parinfer-smart-tab:indicator-face ((,class (:foreground ,spacegrey5))))

;;;; perspective
   `(persp-selected-face ((,class (:foreground ,blue :weight bold))))

;;;; persp-mode
   `(persp-face-lighter-default ((,class (:foreground ,highlight :weight bold))))
   `(persp-face-lighter-buffer-not-in-persp ((,class (:foreground ,doc-comments))))
   `(persp-face-lighter-nil-persp ((,class (:foreground ,comments))))

;;;; pkgbuild-mode
   `(pkgbuild-error-face ((,class (:underline (:style wave :color ,red)))))

;;;; popup
   `(popup-face ((,class (:inherit tooltip))))
   `(popup-tip-face ((,class (:inherit popup-face :foreground ,magenta :background ,spacegrey0))))
   `(popup-selection-face ((,class (:background ,selection))))

;;;; power
   `(powerline-active0 ((,class (:inherit mode-line :background ,bg))))
   `(powerline-active1 ((,class (:inherit mode-line :background ,bg))))
   `(powerline-active2 ((,class (:inherit mode-line :foreground ,spacegrey8 :background ,bg))))
   `(powerline-inactive0 ((,class (:inherit mode-line-inactive :background ,spacegrey2))))
   `(powerline-inactive1 ((,class (:inherit mode-line-inactive :background spacegrey2))))
   `(powerline-inactive2 ((,class (:inherit mode-line-inactive :background spacegrey2))))

;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((,class (:foreground ,blue))))
   `(rainbow-delimiters-depth-2-face ((,class (:foreground ,purple))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground ,green))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground ,orange))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground ,magenta))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground ,yellow))))
   `(rainbow-delimiters-depth-7-face ((,class (:foreground ,teal))))
   `(rainbow-delimiters-unmatched-face ((,class (:foreground ,red :weight bold :inverse-video t))))
   `(rainbow-delimiters-mismatched-face ((,class (:inherit rainbow-delimiters-unmatched-face))))

;;;; re-builder
   `(reb-match-0 ((,class (:foreground ,orange :inverse-video t))))
   `(reb-match-1 ((,class (:foreground ,purple :inverse-video t))))
   `(reb-match-2 ((,class (:foreground ,green :inverse-video t))))
   `(reb-match-3 ((,class (:foreground ,yellow :inverse-video t))))

;;;; rjsx-mode
   `(rjsx-tag ((,class (:foreground ,type))))
   `(rjsx-attr ((,class (:foreground ,functions))))

;;;; rpm-spec-mode
   `(rpm-spec-macro-face ((,class (:foreground ,yellow))))
   `(rpm-spec-var-face ((,class (:foreground ,magenta))))
   `(rpm-spec-tag-face ((,class (:foreground ,blue))))
   `(rpm-spec-obsolete-tag-face ((,class (:foreground ,red))))
   `(rpm-spec-package-face ((,class (:foreground ,orange))))
   `(rpm-spec-dir-face ((,class (:foreground ,green))))
   `(rpm-spec-doc-face ((,class (:foreground ,orange))))
   `(rpm-spec-ghost-face ((,class (:foreground ,comments))))
   `(rpm-spec-section-face ((,class (:foreground ,purple))))

;;;; rst
   `(rst-block ((,class (:inherit font-lock-constant-face))))
   `(rst-level-1 ((,class (:inherit rst-adornment :weight bold))))
   `(rst-level-2 ((,class (:inherit rst-adornment :weight bold))))
   `(rst-level-3 ((,class (:inherit rst-adornment :weight bold))))
   `(rst-level-4 ((,class (:inherit rst-adornment :weight bold))))
   `(rst-level-5 ((,class (:inherit rst-adornment :weight bold))))
   `(rst-level-6 ((,class (:inherit rst-adornment :weight bold))))

;;;; sh-script
   `(sh-heredoc ((,class (:inherit font-lock-string-face :weight normal))))
   `(sh-quoted-exec ((,class (:inherit font-lock-preprocessor-face))))

;;;; show-paren
   `(show-paren-match ((,class (:inherit paren-face-match))))
   `(show-paren-mismatch ((,class (:inherit paren-face-mismatch))))

;;;; smart-mode-line
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

;;;; smartparens
   `(sp-pair-overlay-face ((,class (:background ,region))))
   `(sp-show-pair-match-face ((,class (:inherit show-paren-match))))
   `(sp-show-pair-mismatch-face ((,class (:inherit show-paren-mismatch))))

;;;; smerge-tool
   `(smerge-lower ((,class (:background ,green))))
   `(smerge-upper ((,class (:background ,red))))
   `(smerge-base ((,class (:background ,blue))))
   `(smerge-markers ((,class (:background ,comments :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(smerge-refined-added ((,class (:inherit diff-added :inverse-video t))))
   `(smerge-refined-removed ((,class (:inherit diff-removed :inverse-video t))))
   `(smerge-mine ((,class (:inherit smerge-upper))))
   `(smerge-other ((,class (:inherit smerge-lower))))

;;;; solaire-mode
   `(solaire-default-face ((,class (:inherit default :background ,bg-other))))
   `(solaire-hl-line-face ((,class (:inherit hl-line :background ,bg :extend t))))
   `(solaire-mode-line-face ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))
   `(solaire-mode-line-inactive-face ((,class (:background ,bg-other :foreground ,fg-other :distant-foreground ,bg-other))))

;;;; spaceline
   `(spaceline-highlight-face ((,class (:background ,highlight))))
   `(spaceline-modified ((,class (:background ,vc-modified))))
   `(spaceline-unmodified ((,class (:background ,constants))))
   `(spaceline-python-venv ((,class (:foreground ,purple :distant-foreground ,magenta))))
   `(spaceline-flycheck-error ((,class (:inherit error :distant-background ,spacegrey0))))
   `(spaceline-flycheck-warning ((,class (:inherit warning :distant-background ,spacegrey0))))
   `(spaceline-flycheck-info ((,class (:inherit success :distant-background ,spacegrey0))))
   `(spaceline-evil-normal ((,class (:background ,blue))))
   `(spaceline-evil-insert ((,class (:background ,green))))
   `(spaceline-evil-emacs ((,class (:background ,cyan))))
   `(spaceline-evil-replace ((,class (:background ,orange))))
   `(spaceline-evil-visual ((,class (:background ,grey))))
   `(spaceline-evil-motion ((,class (:background ,purple))))

;;;; stripe-buffer
   `(stripe-highlight ((,class (:background ,spacegrey3))))

;;;; swiper
   `(swiper-line-face ((,class (:background ,blue :foreground ,spacegrey0))))
   `(swiper-match-face-1 ((,class (:inherit unspecified :background ,spacegrey0 :foreground ,spacegrey5))))
   `(swiper-match-face-2 ((,class (:inherit unspecified :background ,orange :foreground ,spacegrey0 :weight bold))))
   `(swiper-match-face-3 ((,class (:inherit unspecified :background ,purple :foreground ,spacegrey0 :weight bold))))
   `(swiper-match-face-4 ((,class (:inherit unspecified :background ,green :foreground ,spacegrey0 :weight bold))))

;;;; tabbar
   `(tabbar-default ((,class (:foreground ,bg :background ,bg :height 1.0))))
   `(tabbar-highlight ((,class (:foreground ,fg :background ,selection :distant-foreground ,bg))))
   `(tabbar-button ((,class (:foreground ,fg :background ,bg))))
   `(tabbar-button-highlight ((,class (:inherit tabbar-button :inverse-video t))))
   `(tabbar-modified ((,class (:inherit tabbar-default :foreground ,red :weight bold))))
   `(tabbar-unselected ((,class (:inherit tabbar-default :foreground ,spacegrey5))))
   `(tabbar-unselected-modified ((,class (:inherit tabbar-modified))))
   `(tabbar-selected ((,class (:inherit tabbar-default :weight bold :foreground ,fg :background ,bg-other))))
   `(tabbar-selected-modified ((,class (:inherit tabbar-selected :foreground ,green))))

;;;; telephone-line
   `(telephone-line-accent-active ((,class (:foreground ,fg :background ,spacegrey4))))
   `(telephone-line-accent-inactive ((,class (:foreground ,fg :background ,spacegrey2))))
   `(telephone-line-projectile ((,class (:foreground ,green))))
   `(telephone-line-evil ((,class (:foreground ,fg :weight bold))))
   `(telephone-line-evil-insert ((,class (:background ,green :weight bold))))
   `(telephone-line-evil-normal ((,class (:background ,red :weight bold))))
   `(telephone-line-evil-visual ((,class (:background ,orange :weight bold))))
   `(telephone-line-evil-replace ((,class (:background ,bg-other :weight bold))))
   `(telephone-line-evil-motion ((,class (:background ,blue :weight bold))))
   `(telephone-line-evil-operator ((,class (:background ,magenta :weight bold))))
   `(telephone-line-evil-emacs ((,class (:background ,purple :weight bold))))

;;;; term
   `(term ((,class (:foreground ,fg))))
   `(term-bold ((,class (:weight bold))))
   `(term-color-black ((,class (:background ,spacegrey0 :foreground ,spacegrey0))))
   `(term-color-red ((,class (:background ,red :foreground ,red))))
   `(term-color-green ((,class (:background ,green :foreground ,green))))
   `(term-color-yellow ((,class (:background ,yellow :foreground ,yellow))))
   `(term-color-blue ((,class (:background ,blue :foreground ,blue))))
   `(term-color-purple ((,class (:background ,purple :foreground ,purple))))
   `(term-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
   `(term-color-white ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))

;;;; tldr
   `(tldr-command-itself ((,class (:foreground ,bg :background ,green :weight semi-bold))))
   `(tldr-title ((,class (:foreground ,yellow :bold t :height 1.4))))
   `(tldr-description ((,class (:foreground ,fg :weight semi-bold))))
   `(tldr-introduction ((,class (:foreground ,blue :weight semi-bold))))
   `(tldr-code-block ((,class (:foreground ,green :background ,region :weight semi-bold))))
   `(tldr-command-argument ((,class (:foreground ,fg :background ,region))))

;;;; typescript-mode
   `(typescript-jsdoc-tag ((,class (:foreground ,doc-comments))))
   `(typescript-jsdoc-type ((,class (:foreground ,doc-comments))))
   `(typescript-jsdoc-value ((,class (:foreground ,doc-comments))))

;;;; treemacs
   `(treemacs-root-face ((,class (:inherit font-lock-string-face :weight bold :height 1.2))))
   `(treemacs-file-face ((,class (:foreground ,fg))))
   `(treemacs-directory-face ((,class (:foreground ,fg))))
   `(treemacs-tags-face ((,class (:foreground ,highlight))))
   `(treemacs-git-modified-face ((,class (:foreground ,magenta))))
   `(treemacs-git-added-face ((,class (:foreground ,green))))
   `(treemacs-git-conflict-face ((,class (:foreground ,red))))
   `(treemacs-git-untracked-face ((,class (:inherit font-lock-doc-face))))

;;;; undo-tree
   `(undo-tree-visualizer-default-face ((,class (:foreground ,spacegrey5))))
   `(undo-tree-visualizer-current-face ((,class (:foreground ,green :weight bold))))
   `(undo-tree-visualizer-unmodified-face ((,class (:foreground ,spacegrey5))))
   `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,blue))))
   `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow))))

;;;; vimish-fold
   `(vimish-fold-overlay ((,class (:inherit font-lock-comment-face :background ,spacegrey0 :weight light))))
   `(vimish-fold-fringe ((,class (:foreground ,purple))))

;;;; volatile-highlights
   `(vhl/default-face ((,class (:background ,grey))))

;;;; vterm
   `(vterm ((,class (:foreground ,fg))))
   `(vterm-color-default ((,class (:foreground ,fg))))
   `(vterm-color-black ((,class (:background ,spacegrey0 :foreground ,spacegrey0))))
   `(vterm-color-red ((,class (:background ,red :foreground ,red))))
   `(vterm-color-green ((,class (:background ,green :foreground ,green))))
   `(vterm-color-yellow ((,class (:background ,yellow :foreground ,yellow))))
   `(vterm-color-blue ((,class (:background ,blue :foreground ,blue))))
   `(vterm-color-purple ((,class (:background ,purple :foreground ,purple))))
   `(vterm-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
   `(vterm-color-white ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))

;;;; web-mode <modes:web-mode>
   `(web-mode-block-control-face ((,class (:foreground ,builtin))))
   `(web-mode-block-delimiter-face ((,class (:foreground ,builtin))))
   `(web-mode-css-property-name-face ((,class (:foreground ,type))))
   `(web-mode-doctype-face ((,class (:foreground ,comments))))
   `(web-mode-html-tag-face ((,class (:foreground ,methods))))
   `(web-mode-html-tag-bracket-face ((,class (:foreground ,methods))))
   `(web-mode-html-attr-name-face ((,class (:foreground ,type))))
   `(web-mode-html-attr-value-face ((,class (:foreground ,strings))))
   `(web-mode-html-entity-face ((,class (:foreground ,cyan :inherit italic))))
   `(web-mode-block-control-face ((,class (:foreground ,orange))))
   `(web-mode-html-tag-bracket-face ((,class (:foreground ,operators))))
   `(web-mode-json-key-face ((,class (:foreground ,strings))))
   `(web-mode-json-context-face ((,class (:foreground ,strings))))
   `(web-mode-keyword-face ((,class (:foreground ,keywords))))
   `(web-mode-string-face ((,class (:foreground ,strings))))
   `(web-mode-type-face ((,class (:foreground ,type))))

;;;; wgrep
   `(wgrep-face ((,class (:weight bold :foreground ,green :background ,spacegrey5))))
   `(wgrep-delete-face ((,class (:foreground ,spacegrey3 :background ,red))))
   `(wgrep-done-face ((,class (:foreground ,blue))))
   `(wgrep-file-face ((,class (:foreground ,comments))))
   `(wgrep-reject-face ((,class (:foreground ,red :weight bold))))

;;;; which-func
   `(which-func ((,class (:foreground ,blue))))

;;;; which-key
   `(which-key-key-face ((,class (:foreground ,green))))
   `(which-key-group-description-face ((,class (:foreground ,magenta))))
   `(which-key-command-description-face ((,class (:foreground ,blue))))
   `(which-key-local-map-description-face ((,class (:foreground ,purple))))

;;;; whitespace
   `(whitespace-empty ((,class (:background ,spacegrey3))))
   `(whitespace-space ((,class (:foreground ,spacegrey4))))
   `(whitespace-newline ((,class (:foreground ,spacegrey4))))
   `(whitespace-tab ((,class (:foreground ,spacegrey4 :background ,spacegrey3))))
   `(whitespace-indentation ((,class (:foreground ,spacegrey4 :background ,spacegrey3))))
   `(whitespace-trailing ((,class (:inherit trailing-whitespace))))
   `(whitespace-line ((,class (:background ,spacegrey0 :foreground ,red :weight bold))))

;;;; widget
   `(widget-button-pressed ((,class (:foreground ,red))))
   `(widget-documentation ((,class (:foreground ,green))))

;;;; window-divider
   `(window-divider ((,class (:inherit vertical-border))))
   `(window-divider-first-pixel ((,class (:inherit window-divider))))
   `(window-divider-last-pixel ((,class (:inherit window-divider))))

;;;; woman
   `(woman-bold ((,class (:inherit Man-overstrike))))
   `(woman-italic ((,class (:inherit Man-underline))))

;;;; workgroups2
   `(wg-current-workgroup-face ((,class (:foreground ,spacegrey0 :background ,highlight))))
   `(wg-other-workgroup-face ((,class (:foreground ,spacegrey5))))
   `(wg-divider-face ((,class (:foreground ,grey))))
   `(wg-brace-face ((,class (:foreground ,highlight))))

;;;; yasnippet
   `(yas-field-highlight-face ((,class (:inherit match))))

   (custom-theme-set-variables
    'timu-spacegrey
    `(ansi-color-names-vector [bg, red, green, teal, cyan, blue, yellow, fg]))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory
                (file-name-directory load-file-name))))

(provide-theme 'timu-spacegrey)

;;; timu-spacegrey-theme.el ends here
