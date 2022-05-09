;;; timu-rouge-theme.el --- Color theme inspired by the Rouge Theme for VSCode -*- lexical-binding:t -*-

;; Copyright (C) 2021 Aimé Bertrand

;; Author: Aimé Bertrand <aime.bertrand@macowners.club>
;; Maintainer: Aimé Bertrand <aime.bertrand@macowners.club>
;; Created: 20 Oct 2021
;; Keywords: faces themes
;; Package-Version: 20220501.1753
;; Package-Commit: 935e4907f01fba2c7c2ecaab88eb7c4163955c3b
;; Version: 1.2
;; Package-Requires: ((emacs "27.1"))
;; Homepage: https://gitlab.com/aimebertrand/timu-rouge-theme

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
;; Sourced other themes to get information about font faces for packages.
;;
;; I. Installation
;;   A. Manual installation
;;     1. Download the `timu-rouge-theme.el' file and add it to your `custom-load-path'.
;;     2. In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (load-theme 'timu-rouge t)
;;
;;   B. From Melpa
;;     1. M-x package-instal <RET> timu-rouge-theme.el <RET>.
;;     2. In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (load-theme 'timu-rouge t)
;;
;;   C. With use-package
;;     In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (use-package timu-rouge-theme
;;         :ensure t
;;         :config
;;         (load-theme 'timu-rouge t))

;;; Code:

(defgroup timu-rouge-theme ()
  "Customise group for the \"Timu Rouge\" theme."
  :group 'faces
  :prefix "timu-rouge-")

(defface timu-rouge-default-face
  '((t nil))
  "Custom basic default `timu-rouge-theme' face."
  :group 'timu-rouge-theme)

(defface timu-rouge-bold-face
  '((t :weight bold))
  "Custom basic bold `timu-rouge-theme' face."
  :group 'timu-rouge-theme)

(defface timu-rouge-bold-face-italic
  '((t :weight bold :slant italic))
  "Custom basic bold-italic `timu-rouge-theme' face."
  :group 'timu-rouge-theme)

(defface timu-rouge-italic-face
  '((((supports :slant italic)) :slant italic)
    (t :slant italic))
  "Custom basic italic `timu-rouge-theme' face."
  :group 'timu-rouge-theme)

(defface timu-rouge-underline-face
  '((((supports :underline t)) :underline t)
    (t :underline t))
  "Custom basic underlined `timu-rouge-theme' face."
  :group 'timu-rouge-theme)

(defface timu-rouge-strike-through-face
  '((((supports :strike-through t)) :strike-through t)
    (t :strike-through t))
  "Custom basic strike-through `timu-rouge-theme' face."
  :group 'timu-rouge-theme)

(deftheme timu-rouge
  "Color theme inspired by the Rouge Theme for VSCode.
Sourced other themes to get information about font faces for packages.")

(let ((class '((class color) (min-colors 89)))
      (bg        "#172030")
      (bg-org    "#1f2a3f")
      (bg-other  "#172030")
      (rouge0    "#070a0e")
      (rouge1    "#0e131d")
      (rouge2    "#151d2b")
      (rouge3    "#1f2a3f")
      (rouge4    "#5d636e")
      (rouge5    "#64727d")
      (rouge6    "#b16e75")
      (rouge7    "#e8e9eb")
      (rouge8    "#f0f4fc")
      (fg        "#fafff6")
      (fg-other  "#a7acb9")

      (grey      "#64727d")
      (red       "#c6797e")
      (darkred   "#db6e8f")
      (orange    "#eabe9a")
      (green     "#a3b09a")
      (blue      "#6e94b9")
      (magenta   "#b18bb1")
      (teal      "#7ea9a9")
      (yellow    "#f7e3af")
      (darkblue  "#1e6378")
      (purple    "#5d80ae")
      (cyan      "#88c0d0")
      (darkcyan  "#507681")
      (black     "#000000")
      (white     "#ffffff"))

  (custom-theme-set-faces
   'timu-rouge

;;; Custom faces

;;;; timu-rouge-faces
   `(timu-rouge-default-face ((,class (:background ,bg :foreground ,fg))))
   `(timu-rouge-bold-face ((,class (:weight bold :foreground ,white))))
   `(timu-rouge-bold-face-italic ((,class (:weight bold :slant italic :foreground ,white))))
   `(timu-rouge-italic-face ((,class (:slant italic :foreground ,white))))
   `(timu-rouge-underline-face ((,class (:underline ,darkred))))
   `(timu-rouge-strike-through-face ((,class (:strike-through ,darkred))))

;;;; default faces
   `(bold ((,class (:weight bold))))
   `(bold-italic ((,class (:weight bold :slant italic))))
   `(bookmark-face ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(cursor ((,class (:background ,darkred))))
   `(default ((,class (:background ,bg :foreground ,fg))))
   `(error ((,class (:foreground ,red))))
   `(fringe ((,class (:foreground ,rouge4))))
   `(highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(italic ((,class (:slant  italic))))
   `(lazy-highlight ((,class (:background ,darkblue  :foreground ,rouge8 :distant-foreground ,rouge0 :weight bold))))
   `(link ((,class (:foreground ,red :underline t :weight bold))))
   `(match ((,class (:foreground ,green :background ,rouge0 :weight bold))))
   `(minibuffer-prompt ((,class (:foreground ,red))))
   `(nobreak-space ((,class (:background ,bg :foreground ,fg))))
   `(region ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
   `(secondary-selection ((,class (:background ,grey :extend t))))
   `(shadow ((,class (:foreground ,rouge5))))
   `(success ((,class (:foreground ,green))))
   `(tooltip ((,class (:background ,bg-other :foreground ,fg))))
   `(trailing-whitespace ((,class (:background ,red))))
   `(vertical-border ((,class (:background ,red :foreground ,red))))
   `(warning ((,class (:foreground ,yellow))))

;;;; font-lock
   `(font-lock-builtin-face ((,class (:foreground ,darkred))))
   `(font-lock-comment-delimiter-face ((,class (:foreground ,rouge5))))
   `(font-lock-comment-face ((,class (:foreground ,rouge5))))
   `(font-lock-constant-face ((,class (:foreground ,red))))
   `(font-lock-doc-face ((,class (:foreground ,rouge5))))
   `(font-lock-function-name-face ((,class (:foreground ,cyan))))
   `(font-lock-keyword-face ((,class (:foreground ,darkred))))
   `(font-lock-negation-char-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-preprocessor-char-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-preprocessor-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-regexp-grouping-backslash ((,class (:foreground ,fg :weight bold))))
   `(font-lock-regexp-grouping-construct ((,class (:foreground ,fg :weight bold))))
   `(font-lock-string-face ((,class (:foreground ,orange))))
   `(font-lock-type-face ((,class (:foreground ,yellow))))
   `(font-lock-variable-name-face ((,class (:foreground ,red))))
   `(font-lock-warning-face ((,class (:foreground ,yellow))))

;;;; ace-window
   `(aw-leading-char-face ((,class (:foreground ,red :height 500 :weight bold))))
   `(aw-background-face ((,class (:foreground ,rouge5))))

;;;; alert
   `(alert-high-face ((,class (:foreground ,yellow :weight bold))))
   `(alert-low-face ((,class (:foreground ,grey))))
   `(alert-moderate-face ((,class (:foreground ,fg-other :weight bold))))
   `(alert-trivial-face ((,class (:foreground ,rouge5))))
   `(alert-urgent-face ((,class (:foreground ,red :weight bold))))

;;;; all-the-icons
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

;;;; all-the-icons-dired
   `(all-the-icons-dired-dir-face ((,class (:foreground ,fg-other))))

;;;; all-the-icons-ivy-rich
   `(all-the-icons-ivy-rich-doc-face ((,class (:foreground ,blue))))
   `(all-the-icons-ivy-rich-path-face ((,class (:foreground ,blue))))
   `(all-the-icons-ivy-rich-size-face ((,class (:foreground ,blue))))
   `(all-the-icons-ivy-rich-time-face ((,class (:foreground ,blue))))

;;;; annotate
   `(annotate-annotation ((,class (:background ,red :foreground ,rouge5))))
   `(annotate-annotation-secondary ((,class (:background ,green :foreground ,rouge5))))
   `(annotate-highlight ((,class (:background ,red :underline ,red))))
   `(annotate-highlight-secondary ((,class (:background ,green :underline ,green))))

;;;; ansi
   `(ansi-color-black ((,class (:foreground ,rouge0))))
   `(ansi-color-blue ((,class (:foreground ,blue))))
   `(ansi-color-cyan ((,class (:foreground ,cyan))))
   `(ansi-color-green ((,class (:foreground ,green))))
   `(ansi-color-magenta ((,class (:foreground ,magenta))))
   `(ansi-color-purple ((,class (:foreground ,purple))))
   `(ansi-color-red ((,class (:foreground ,red))))
   `(ansi-color-white ((,class (:foreground ,rouge8))))
   `(ansi-color-yellow ((,class (:foreground ,yellow))))
   `(ansi-color-bright-black ((,class (:foreground ,rouge0))))
   `(ansi-color-bright-blue ((,class (:foreground ,blue))))
   `(ansi-color-bright-cyan ((,class (:foreground ,cyan))))
   `(ansi-color-bright-green ((,class (:foreground ,green))))
   `(ansi-color-bright-magenta ((,class (:foreground ,magenta))))
   `(ansi-color-bright-purple ((,class (:foreground ,purple))))
   `(ansi-color-bright-red ((,class (:foreground ,red))))
   `(ansi-color-bright-white ((,class (:foreground ,rouge8))))
   `(ansi-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; anzu
   `(anzu-replace-highlight ((,class (:background ,rouge0 :foreground ,red :weight bold :strike-through t))))
   `(anzu-replace-to ((,class (:background ,rouge0 :foreground ,green :weight bold))))

;;;; auctex
   `(TeX-error-description-error ((,class (:foreground ,red :weight bold))))
   `(TeX-error-description-tex-said ((,class (:foreground ,green :weight bold))))
   `(TeX-error-description-warning ((,class (:foreground ,yellow :weight bold))))
   `(font-latex-bold-face ((,class (:weight bold))))
   `(font-latex-italic-face ((,class (:slant italic))))
   `(font-latex-math-face ((,class (:foreground ,blue))))
   `(font-latex-script-char-face ((,class (:foreground ,darkblue))))
   `(font-latex-sectioning-0-face ((,class (:foreground ,blue :weight ultra-bold))))
   `(font-latex-sectioning-1-face ((,class (:foreground ,purple :weight semi-bold))))
   `(font-latex-sectioning-2-face ((,class (:foreground ,magenta :weight semi-bold))))
   `(font-latex-sectioning-3-face ((,class (:foreground ,blue :weight semi-bold))))
   `(font-latex-sectioning-4-face ((,class (:foreground ,purple :weight semi-bold))))
   `(font-latex-sectioning-5-face ((,class (:foreground ,magenta :weight semi-bold))))
   `(font-latex-string-face ((,class (:foreground ,orange))))
   `(font-latex-verbatim-face ((,class (:foreground ,magenta :slant italic))))
   `(font-latex-warning-face ((,class (:foreground ,yellow))))

;;;; avy
   `(avy-background-face ((,class (:foreground ,rouge5))))
   `(avy-lead-face ((,class (:background ,darkred :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(avy-lead-face-0 ((,class (:background ,darkred :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(avy-lead-face-1 ((,class (:background ,darkred :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(avy-lead-face-2 ((,class (:background ,darkred :foreground ,bg :distant-foreground ,fg :weight bold))))

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
   `(bmkp-gnus ((,class (:foreground ,red))))
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
   `(bmkp-local-file-without-region ((,class (:foreground ,rouge5))))
   `(bmkp-man ((,class (:foreground ,magenta))))
   `(bmkp-no-jump ((,class (:foreground ,rouge5))))
   `(bmkp-no-local ((,class (:foreground ,yellow))))
   `(bmkp-non-file ((,class (:foreground ,green))))
   `(bmkp-remote-file ((,class (:foreground ,red))))
   `(bmkp-sequence ((,class (:foreground ,blue))))
   `(bmkp-su-or-sudo ((,class (:foreground ,red))))
   `(bmkp-t-mark ((,class (:foreground ,magenta))))
   `(bmkp-url ((,class (:foreground ,blue :underline t))))
   `(bmkp-variable-list ((,class (:foreground ,green))))

;;;; calfw
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
   `(cfw:face-title ((,class (:foreground ,blue :weight bold :height 2.0))))
   `(cfw:face-today ((,class (:foreground nil :background nil :weight bold))))
   `(cfw:face-today-title ((,class (:foreground ,bg :background ,blue :weight bold))))
   `(cfw:face-toolbar ((,class (:foreground nil :background nil))))
   `(cfw:face-toolbar-button-off ((,class (:foreground ,rouge6 :weight bold))))
   `(cfw:face-toolbar-button-on ((,class (:foreground ,blue :weight bold))))

;;;; centaur-tabs
   `(centaur-tabs-active-bar-face ((,class (:background ,bg :foreground ,orange))))
   `(centaur-tabs-close-mouse-face ((,class (:foreground ,orange))))
   `(centaur-tabs-close-selected ((,class (:background ,bg :foreground ,fg))))
   `(centaur-tabs-close-unselected ((,class (:background ,bg-other :foreground ,grey))))
   `(centaur-tabs-default ((,class (:background ,bg-other :foreground ,fg))))
   `(centaur-tabs-modified-marker-selected ((,class (:background ,bg :foreground ,orange))))
   `(centaur-tabs-modified-marker-unselected ((,class (:background ,bg :foreground ,orange))))
   `(centaur-tabs-selected ((,class (:background ,bg :foreground ,fg))))
   `(centaur-tabs-selected-modified ((,class (:background ,bg :foreground ,red))))
   `(centaur-tabs-unselected ((,class (:background ,bg-other :foreground ,grey))))
   `(centaur-tabs-unselected-modified ((,class (:background ,bg-other :foreground ,red))))

;;;; circe
   `(circe-fool ((,class (:foreground ,rouge5))))
   `(circe-highlight-nick-face ((,class (:weight bold :foreground ,orange))))
   `(circe-my-message-face ((,class (:weight bold))))
   `(circe-prompt-face ((,class (:weight bold :foreground ,orange))))
   `(circe-server-face ((,class (:foreground ,rouge5))))

;;;; company
   `(company-preview ((,class (:foreground ,rouge5))))
   `(company-preview-common ((,class (:background ,rouge3 :foreground ,darkred))))
   `(company-preview-search ((,class (:background ,darkred :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(company-scrollbar-bg ((,class (:background ,bg-other :foreground ,fg))))
   `(company-scrollbar-fg ((,class (:background ,darkred))))
   `(company-template-field ((,class (:foreground ,green :background ,rouge0 :weight bold))))
   `(company-tooltip ((,class (:background ,bg-other :foreground ,fg))))
   `(company-tooltip-annotation ((,class (:foreground ,magenta :distant-foreground ,bg))))
   `(company-tooltip-common ((,class (:foreground ,darkred :distant-foreground ,rouge0 :weight bold))))
   `(company-tooltip-mouse ((,class (:background ,purple :foreground ,bg :distant-foreground ,fg))))
   `(company-tooltip-search ((,class (:background ,darkred :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(company-tooltip-search-selection ((,class (:background ,grey))))
   `(company-tooltip-selection ((,class (:background ,grey :weight bold))))

;;;; company-box
   `(company-box-candidate ((,class (:foreground ,fg))))

;;;; compilation
   `(compilation-column-number ((,class (:foreground ,rouge5))))
   `(compilation-error ((,class (:foreground ,red :weight bold))))
   `(compilation-info ((,class (:foreground ,green))))
   `(compilation-line-number ((,class (:foreground ,red))))
   `(compilation-mode-line-exit ((,class (:foreground ,green))))
   `(compilation-mode-line-fail ((,class (:foreground ,red :weight bold))))
   `(compilation-warning ((,class (:foreground ,yellow :slant italic))))

;;;; corfu
   `(corfu-bar ((,class (:background ,bg-other :foreground ,fg))))
   `(corfu-echo ((,class (:foreground ,red))))
   `(corfu-border ((,class (:background ,bg-other :foreground ,fg))))
   `(corfu-current ((,class (:foreground ,red :weight bold))))
   `(corfu-default ((,class (:background ,bg-other :foreground ,fg))))
   `(corfu-deprecated ((,class (:foreground ,orange))))
   `(corfu-annotations ((,class (:foreground ,magenta))))

;;;; counsel
   `(counsel-variable-documentation ((,class (:foreground ,blue))))

;;;; cperl
   `(cperl-array-face ((,class (:foreground ,red :weight bold))))
   `(cperl-hash-face ((,class (:foreground ,red :weight bold :slant italic))))
   `(cperl-nonoverridable-face ((,class (:foreground ,darkred))))

;;;; custom
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
   `(custom-link ((,class (:foreground ,darkred :underline t))))
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

;;; diff
   `(diff-added ((,class (:foreground ,bg :background ,green :extend t))))
   `(diff-indicator-added ((,class (:foreground ,bg :weight bold :background ,green :extend t))))
   `(diff-refine-added ((,class (:foreground ,bg :weight bold :background ,green :extend t))))
   `(diff-changed ((,class (:foreground ,bg :background ,yellow :extend t))))
   `(diff-indicator-changed ((,class (:foreground ,bg :weight bold :background ,yellow :extend t))))
   `(diff-refine-changed ((,class (:foreground ,bg :weight bold :background ,yellow :extend t))))
   `(diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
   `(diff-indicator-removed ((,class (:foreground ,bg :weight bold :background ,red :extend t))))
   `(diff-refine-removed ((,class (:foreground ,bg :weight bold :background ,red :extend t))))
   `(diff-header ((,class (:foreground ,darkcyan))))
   `(diff-file-header ((,class (:foreground ,orange :weight bold))))
   `(diff-hunk-header ((,class (:foreground ,bg :background ,magenta :extend t))))
   `(diff-function ((,class (:foreground ,bg :background ,magenta :extend t))))

;;;; diff-hl
   `(diff-hl-change ((,class (:foreground ,orange :background ,orange))))
   `(diff-hl-delete ((,class (:foreground ,red :background ,red))))
   `(diff-hl-insert ((,class (:foreground ,green :background ,green))))

;;;; dired
   `(dired-directory ((,class (:foreground ,darkcyan :underline ,darkcyan))))
   `(dired-flagged ((,class (:foreground ,red))))
   `(dired-header ((,class (:foreground ,darkred :weight bold :underline ,darkcyan))))
   `(dired-ignored ((,class (:foreground ,rouge5))))
   `(dired-mark ((,class (:foreground ,darkred :weight bold))))
   `(dired-marked ((,class (:foreground ,yellow :weight bold))))
   `(dired-perm-write ((,class (:foreground ,red :underline t))))
   `(dired-symlink ((,class (:foreground ,magenta))))
   `(dired-warning ((,class (:foreground ,yellow))))

;;;; dired-async
   `(dired-async-failures ((,class (:foreground ,red))))
   `(dired-async-message ((,class (:foreground ,darkred))))
   `(dired-async-mode-message ((,class (:foreground ,darkred))))

;;;; dired-filetype-face
   `(dired-filetype-common ((,class (:foreground ,fg))))
   `(dired-filetype-compress ((,class (:foreground ,yellow))))
   `(dired-filetype-document ((,class (:foreground ,darkred))))
   `(dired-filetype-execute ((,class (:foreground ,red))))
   `(dired-filetype-image ((,class (:foreground ,orange))))
   `(dired-filetype-js ((,class (:foreground ,yellow))))
   `(dired-filetype-link ((,class (:foreground ,magenta))))
   `(dired-filetype-music ((,class (:foreground ,magenta))))
   `(dired-filetype-omit ((,class (:foreground ,blue))))
   `(dired-filetype-plain ((,class (:foreground ,fg))))
   `(dired-filetype-program ((,class (:foreground ,red))))
   `(dired-filetype-source ((,class (:foreground ,green))))
   `(dired-filetype-video ((,class (:foreground ,magenta))))
   `(dired-filetype-xml ((,class (:foreground ,green))))

;;;; dired+
   `(diredp-compressed-file-suffix ((,class (:foreground ,rouge5))))
   `(diredp-date-time ((,class (:foreground ,blue))))
   `(diredp-dir-heading ((,class (:foreground ,blue :weight bold))))
   `(diredp-dir-name ((,class (:foreground ,rouge8 :weight bold))))
   `(diredp-dir-priv ((,class (:foreground ,blue :weight bold))))
   `(diredp-exec-priv ((,class (:foreground ,yellow))))
   `(diredp-file-name ((,class (:foreground ,rouge8))))
   `(diredp-file-suffix ((,class (:foreground ,magenta))))
   `(diredp-ignored-file-name ((,class (:foreground ,rouge5))))
   `(diredp-no-priv ((,class (:foreground ,rouge5))))
   `(diredp-number ((,class (:foreground ,purple))))
   `(diredp-rare-priv ((,class (:foreground ,red :weight bold))))
   `(diredp-read-priv ((,class (:foreground ,purple))))
   `(diredp-symlink ((,class (:foreground ,magenta))))
   `(diredp-write-priv ((,class (:foreground ,green))))

;;;; dired-k
   `(dired-k-added ((,class (:foreground ,green :weight bold))))
   `(dired-k-commited ((,class (:foreground ,green :weight bold))))
   `(dired-k-directory ((,class (:foreground ,blue :weight bold))))
   `(dired-k-ignored ((,class (:foreground ,rouge5 :weight bold))))
   `(dired-k-modified ((,class (:foreground , :weight bold))))
   `(dired-k-untracked ((,class (:foreground ,teal :weight bold))))

;;;; dired-subtree
   `(dired-subtree-depth-1-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-2-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-3-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-4-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-5-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-6-face ((,class (:background ,bg-other))))

;;;; diredfl
   `(diredfl-autofile-name ((,class (:foreground ,rouge4))))
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
   `(diredfl-ignored-file-name ((,class (:foreground ,rouge5))))
   `(diredfl-link-priv ((,class (:foreground ,magenta))))
   `(diredfl-no-priv ((,class (:foreground ,fg))))
   `(diredfl-number ((,class (:foreground ,orange))))
   `(diredfl-other-priv ((,class (:foreground ,purple))))
   `(diredfl-rare-priv ((,class (:foreground ,fg))))
   `(diredfl-read-priv ((,class (:foreground ,yellow))))
   `(diredfl-symlink ((,class (:foreground ,magenta))))
   `(diredfl-tagged-autofile-name ((,class (:foreground ,rouge5))))
   `(diredfl-write-priv ((,class (:foreground ,red))))

;;;; doom-modeline
   `(doom-modeline-bar-inactive ((,class (:background nil))))
   `(doom-modeline-eldoc-bar ((,class (:background ,green))))

;;;; ediff
   `(ediff-current-diff-A ((,class (:foreground ,bg :background ,red :extend t))))
   `(ediff-current-diff-B ((,class (:foreground ,bg :background ,green :extend t))))
   `(ediff-current-diff-C ((,class (:foreground ,bg :background ,yellow :extend t))))
   `(ediff-even-diff-A ((,class (:background ,bg-other :extend t))))
   `(ediff-even-diff-B ((,class (:background ,bg-other :extend t))))
   `(ediff-even-diff-C ((,class (:background ,bg-other :extend t))))
   `(ediff-fine-diff-A ((,class (:background ,red :weight bold :underline t :extend t))))
   `(ediff-fine-diff-B ((,class (:background ,green :weight bold :underline t :extend t))))
   `(ediff-fine-diff-C ((,class (:background ,yellow :weight bold :underline t :extend t))))
   `(ediff-odd-diff-A ((,class (:background ,bg-other :extend t))))
   `(ediff-odd-diff-B ((,class (:background ,bg-other :extend t))))
   `(ediff-odd-diff-C ((,class (:background ,bg-other :extend t))))

;;;; elfeed
   `(elfeed-log-debug-level-face ((,class (:foreground ,rouge5))))
   `(elfeed-log-error-level-face ((,class (:foreground ,red))))
   `(elfeed-log-info-level-face ((,class (:foreground ,green))))
   `(elfeed-log-warn-level-face ((,class (:foreground ,yellow))))
   `(elfeed-search-date-face ((,class (:foreground ,magenta))))
   `(elfeed-search-feed-face ((,class (:foreground ,blue))))
   `(elfeed-search-filter-face ((,class (:foreground ,magenta))))
   `(elfeed-search-tag-face ((,class (:foreground ,rouge5))))
   `(elfeed-search-title-face ((,class (:foreground ,rouge5))))
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
   `(enh-ruby-heredoc-delimiter-face ((,class (:foreground ,orange))))
   `(enh-ruby-op-face ((,class (:foreground ,fg))))
   `(enh-ruby-regexp-delimiter-face ((,class (:foreground ,orange))))
   `(enh-ruby-regexp-face ((,class (:foreground ,orange))))
   `(enh-ruby-string-delimiter-face ((,class (:foreground ,orange))))
   `(erm-syn-errline ((,class (:underline (:style wave :color ,red)))))
   `(erm-syn-warnline ((,class (:underline (:style wave :color ,yellow)))))

;;;; erc
   `(erc-action-face  ((,class (:weight bold))))
   `(erc-button ((,class (:weight bold :underline t))))
   `(erc-command-indicator-face ((,class (:weight bold))))
   `(erc-current-nick-face ((,class (:foreground ,green :weight bold))))
   `(erc-default-face ((,class (:background ,bg :foreground ,fg))))
   `(erc-direct-msg-face ((,class (:foreground ,purple))))
   `(erc-error-face ((,class (:foreground ,red))))
   `(erc-header-line ((,class (:background ,bg-other :foreground ,orange))))
   `(erc-input-face ((,class (:foreground ,green))))
   `(erc-my-nick-face ((,class (:foreground ,green :weight bold))))
   `(erc-my-nick-prefix-face ((,class (:foreground ,green :weight bold))))
   `(erc-nick-default-face ((,class (:weight bold))))
   `(erc-nick-msg-face ((,class (:foreground ,purple))))
   `(erc-nick-prefix-face ((,class (:background ,bg :foreground ,fg))))
   `(erc-notice-face ((,class (:foreground ,rouge5))))
   `(erc-prompt-face ((,class (:foreground ,orange :weight bold))))
   `(erc-timestamp-face ((,class (:foreground ,blue :weight bold))))

;;;; eshell
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
   `(eshell-ls-unreadable ((,class (:foreground ,rouge5))))
   `(eshell-prompt ((,class (:foreground ,darkred :weight bold))))

;;;; evil
   `(evil-ex-info ((,class (:foreground ,red :slant italic))))
   `(evil-ex-search ((,class (:background ,orange :foreground ,rouge0 :weight bold))))
   `(evil-ex-substitute-matches ((,class (:background ,rouge0 :foreground ,red :weight bold :strike-through t))))
   `(evil-ex-substitute-replacement ((,class (:background ,rouge0 :foreground ,green :weight bold))))
   `(evil-search-highlight-persist-highlight-face ((,class (:background ,darkblue  :foreground ,rouge8 :distant-foreground ,rouge0 :weight bold))))

;;;; evil-googles
   `(evil-goggles-default-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-mc
   `(evil-mc-cursor-bar-face ((,class (:height 1 :background ,purple :foreground ,rouge0))))
   `(evil-mc-cursor-default-face ((,class (:background ,purple :foreground ,rouge0 :inverse-video nil))))
   `(evil-mc-cursor-hbar-face ((,class (:underline (:color ,orange)))))
   `(evil-mc-region-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-snipe
   `(evil-snipe-first-match-face ((,class (:foreground ,red :background ,darkblue :weight bold))))
   `(evil-snipe-matches-face ((,class (:foreground ,red :underline t :weight bold))))

;;;; expenses
   `(expenses-face-date ((,class (:foreground ,red :weight bold))))
   `(expenses-face-expence ((,class (:foreground ,green :weight bold))))
   `(expenses-face-message ((,class (:foreground ,orange :weight bold))))

;;;; flx-ido
   `(flx-highlight-face ((,class (:weight bold :foreground ,yellow :underline nil))))

;;;; flycheck
   `(flycheck-error ((,class (:underline (:style wave :color ,red)))))
   `(flycheck-fringe-error ((,class (:foreground ,red))))
   `(flycheck-fringe-info ((,class (:foreground ,green))))
   `(flycheck-fringe-warning ((,class (:foreground ,yellow))))
   `(flycheck-info ((,class (:underline (:style wave :color ,green)))))
   `(flycheck-warning ((,class (:underline (:style wave :color ,yellow)))))

;;;; flycheck-posframe
   `(flycheck-posframe-background-face ((,class (:background ,bg-other))))
   `(flycheck-posframe-error-face ((,class (:foreground ,red))))
   `(flycheck-posframe-face ((,class (:background ,bg :foreground ,fg))))
   `(flycheck-posframe-info-face ((,class (:background ,bg :foreground ,fg))))
   `(flycheck-posframe-warning-face ((,class (:foreground ,yellow))))

;;;; flymake
   `(flymake-error ((,class (:underline (:style wave :color ,red)))))
   `(flymake-note ((,class (:underline (:style wave :color ,green)))))
   `(flymake-warning ((,class (:underline (:style wave :color ,orange)))))

;;;; flyspell
   `(flyspell-duplicate ((,class (:underline (:style wave :color ,yellow)))))
   `(flyspell-incorrect ((,class (:underline (:style wave :color ,red)))))

;;;; forge
   `(forge-topic-closed ((,class (:foreground ,rouge5 :strike-through t))))
   `(forge-topic-label ((,class (:box nil))))

;;;; git-commit
   `(git-commit-comment-branch-local ((,class (:foreground ,purple))))
   `(git-commit-comment-branch-remote ((,class (:foreground ,green))))
   `(git-commit-comment-detached ((,class (:foreground ,darkred))))
   `(git-commit-comment-file ((,class (:foreground ,magenta))))
   `(git-commit-comment-heading ((,class (:foreground ,magenta))))
   `(git-commit-keyword ((,class (:foreground ,cyan :slant italic))))
   `(git-commit-known-pseudo-header ((,class (:foreground ,rouge5 :weight bold :slant italic))))
   `(git-commit-nonempty-second-line ((,class (:foreground ,red))))
   `(git-commit-overlong-summary ((,class (:foreground ,red :slant italic :weight bold))))
   `(git-commit-pseudo-header ((,class (:foreground ,rouge5 :slant italic))))
   `(git-commit-summary ((,class (:foreground ,darkcyan))))

;;;; git-gutter
   `(git-gutter:added ((,class (:foreground ,green))))
   `(git-gutter:deleted ((,class (:foreground ,red))))
   `(git-gutter:modified ((,class (:foreground ,cyan))))

;;;; git-gutter+
   `(git-gutter+-added ((,class (:foreground ,green))))
   `(git-gutter+-deleted ((,class (:foreground ,red))))
   `(git-gutter+-modified ((,class (:foreground ,cyan))))

;;;; git-gutter-fringe
   `(git-gutter-fr:added ((,class (:foreground ,green))))
   `(git-gutter-fr:deleted ((,class (:foreground ,red))))
   `(git-gutter-fr:modified ((,class (:foreground ,cyan))))

;;;; gnus
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
   `(gnus-group-mail-1-empty ((,class (:foreground ,rouge5))))
   `(gnus-group-mail-2 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-2-empty ((,class (:foreground ,rouge5))))
   `(gnus-group-mail-3 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-3-empty ((,class (:foreground ,rouge5))))
   `(gnus-group-mail-low ((,class (:foreground ,fg))))
   `(gnus-group-mail-low-empty ((,class (:foreground ,rouge5))))
   `(gnus-group-news-1 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-1-empty ((,class (:foreground ,rouge5))))
   `(gnus-group-news-2 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-2-empty ((,class (:foreground ,rouge5))))
   `(gnus-group-news-3 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-3-empty ((,class (:foreground ,rouge5))))
   `(gnus-group-news-4 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-4-empty ((,class (:foreground ,rouge5))))
   `(gnus-group-news-5 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-5-empty ((,class (:foreground ,rouge5))))
   `(gnus-group-news-6 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-6-empty ((,class (:foreground ,rouge5))))
   `(gnus-group-news-low ((,class (:weight bold :foreground ,rouge5))))
   `(gnus-group-news-low-empty ((,class (:foreground ,fg))))
   `(gnus-header-content ((,class (:foreground ,magenta))))
   `(gnus-header-from ((,class (:foreground ,magenta))))
   `(gnus-header-name ((,class (:foreground ,green))))
   `(gnus-header-newsgroups ((,class (:foreground ,magenta))))
   `(gnus-header-subject ((,class (:foreground ,orange :weight bold))))
   `(gnus-signature ((,class (:foreground ,yellow))))
   `(gnus-summary-cancelled ((,class (:foreground ,red :strike-through t))))
   `(gnus-summary-high-ancient ((,class (:foreground ,rouge5 :slant italic))))
   `(gnus-summary-high-read ((,class (:foreground ,fg))))
   `(gnus-summary-high-ticked ((,class (:foreground ,purple))))
   `(gnus-summary-high-unread ((,class (:foreground ,green))))
   `(gnus-summary-low-ancient ((,class (:foreground ,rouge5 :slant italic))))
   `(gnus-summary-low-read ((,class (:foreground ,fg))))
   `(gnus-summary-low-ticked ((,class (:foreground ,purple))))
   `(gnus-summary-low-unread ((,class (:foreground ,green))))
   `(gnus-summary-normal-ancient ((,class (:foreground ,rouge5 :slant italic))))
   `(gnus-summary-normal-read ((,class (:foreground ,fg))))
   `(gnus-summary-normal-ticked ((,class (:foreground ,purple))))
   `(gnus-summary-normal-unread ((,class (:foreground ,green :weight bold))))
   `(gnus-summary-selected ((,class (:foreground ,blue :weight bold))))
   `(gnus-x-face ((,class (:background ,rouge5 :foreground ,fg))))

;;;; goggles
   `(goggles-added ((,class (:background ,green))))
   `(goggles-changed ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
   `(goggles-removed ((,class (:background ,red :extend t))))

;;;; header-line
   `(header-line ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))

;;;; helm
   `(helm-ff-directory ((,class (:foreground ,red))))
   `(helm-ff-dotted-directory ((,class (:foreground ,grey))))
   `(helm-ff-executable ((,class (:foreground ,rouge8 :slant italic))))
   `(helm-ff-file ((,class (:foreground ,fg))))
   `(helm-ff-prefix ((,class (:foreground ,magenta))))
   `(helm-grep-file ((,class (:foreground ,blue))))
   `(helm-grep-finish ((,class (:foreground ,green))))
   `(helm-grep-lineno ((,class (:foreground ,rouge5))))
   `(helm-grep-match ((,class (:foreground ,orange :distant-foreground ,red))))
   `(helm-match ((,class (:foreground ,orange :distant-foreground ,rouge8 :weight bold))))
   `(helm-moccur-buffer ((,class (:foreground ,red :underline t :weight bold))))
   `(helm-selection ((,class (:background ,grey :extend t :distant-foreground ,orange :weight bold))))
   `(helm-source-header ((,class (:background ,rouge2 :foreground ,magenta :weight bold))))
   `(helm-swoop-target-line-block-face ((,class (:foreground ,yellow))))
   `(helm-swoop-target-line-face ((,class (:foreground ,orange :inverse-video t))))
   `(helm-swoop-target-line-face ((,class (:foreground ,orange :inverse-video t))))
   `(helm-swoop-target-number-face ((,class (:foreground ,rouge5))))
   `(helm-swoop-target-word-face ((,class (:foreground ,green :weight bold))))
   `(helm-visible-mark ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))

;;;; helpful
   `(helpful-heading ((,class (:weight bold :height 1.2))))

;;;; hi-lock
   `(hi-blue ((,class (:background ,blue))))
   `(hi-blue-b ((,class (:foreground ,blue :weight bold))))
   `(hi-green ((,class (:background ,green))))
   `(hi-green-b ((,class (:foreground ,green :weight bold))))
   `(hi-magenta ((,class (:background ,purple))))
   `(hi-red-b ((,class (:foreground ,red :weight bold))))
   `(hi-yellow ((,class (:background ,yellow))))

;;;; highlight-indentation-mode
   `(highlight-indentation-current-column-face ((,class (:background ,rouge1))))
   `(highlight-indentation-face ((,class (:background ,rouge2 :extend t))))
   `(highlight-indentation-guides-even-face ((,class (:background ,rouge2 :extend t))))
   `(highlight-indentation-guides-odd-face ((,class (:background ,rouge2 :extend t))))

;;;; highlight-numbers-mode
   `(highlight-numbers-number ((,class (:foreground ,orange :weight bold))))

;;;; highlight-quoted-mode
   `(highlight-quoted-quote  ((,class (:foreground ,fg))))
   `(highlight-quoted-symbol ((,class (:foreground ,yellow))))

;;;; highlight-symbol
   `(highlight-symbol-face ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; highlight-thing
   `(highlight-thing ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; hl-fill-column-face
   `(hl-fill-column-face ((,class (:background ,rouge2 :extend t))))

;;;; hl-line (built-in)
   `(hl-line ((,class (:background ,rouge2 :extend t))))

;;;; hl-todo
   `(hl-todo ((,class (:foreground ,red :weight bold))))

;;;; hlinum
   `(linum-highlight-face ((,class (:foreground ,fg :distant-foreground nil :weight normal))))

;;;; hydra
   `(hydra-face-amaranth ((,class (:foreground ,purple :weight bold))))
   `(hydra-face-blue ((,class (:foreground ,blue :weight bold))))
   `(hydra-face-magenta ((,class (:foreground ,magenta :weight bold))))
   `(hydra-face-red ((,class (:foreground ,red :weight bold))))
   `(hydra-face-teal ((,class (:foreground ,teal :weight bold))))

;;;; ido
   `(ido-first-match ((,class (:foreground ,orange))))
   `(ido-indicator ((,class (:foreground ,red :background ,bg))))
   `(ido-only-match ((,class (:foreground ,green))))
   `(ido-subdir ((,class (:foreground ,magenta))))
   `(ido-virtual ((,class (:foreground ,rouge5))))

;;;; iedit
   `(iedit-occurrence ((,class (:foreground ,purple :weight bold :inverse-video t))))
   `(iedit-read-only-occurrence ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; imenu-list
   `(imenu-list-entry-face-0 ((,class (:foreground ,orange))))
   `(imenu-list-entry-face-1 ((,class (:foreground ,green))))
   `(imenu-list-entry-face-2 ((,class (:foreground ,yellow))))
   `(imenu-list-entry-subalist-face-0 ((,class (:foreground ,orange :weight bold))))
   `(imenu-list-entry-subalist-face-1 ((,class (:foreground ,green :weight bold))))
   `(imenu-list-entry-subalist-face-2 ((,class (:foreground ,yellow :weight bold))))

;;;; indent-guide
   `(indent-guide-face ((,class (:background ,rouge2 :extend t))))

;;;; isearch
   `(isearch ((,class (:background ,darkblue  :foreground ,rouge8 :distant-foreground ,rouge0 :weight bold))))
   `(isearch-fail ((,class (:background ,red :foreground ,rouge0 :weight bold))))

;;;; ivy
   `(ivy-confirm-face ((,class (:foreground ,green))))
   `(ivy-current-match ((,class (:background ,grey :distant-foreground nil :extend t))))
   `(ivy-highlight-face ((,class (:foreground ,magenta))))
   `(ivy-match-required-face ((,class (:foreground ,red))))
   `(ivy-minibuffer-match-face-1 ((,class (:background nil :foreground ,orange :weight bold :underline t))))
   `(ivy-minibuffer-match-face-2 ((,class (:foreground ,purple :background ,rouge1 :weight semi-bold))))
   `(ivy-minibuffer-match-face-3 ((,class (:foreground ,green :weight semi-bold))))
   `(ivy-minibuffer-match-face-4 ((,class (:foreground ,yellow :weight semi-bold))))
   `(ivy-minibuffer-match-highlight ((,class (:foreground ,magenta))))
   `(ivy-modified-buffer ((,class (:weight bold :foreground ,darkcyan))))
   `(ivy-virtual ((,class (:slant italic :foreground ,fg))))

;;;; ivy-posframe
   `(ivy-posframe ((,class (:background ,bg-other))))
   `(ivy-posframe-border ((,class (:background ,red))))

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
   `(jdee-font-lock-bold-face ((,class (:weight bold))))
   `(jdee-font-lock-constant-face ((,class (:foreground ,red))))
   `(jdee-font-lock-constructor-face ((,class (:foreground ,blue))))
   `(jdee-font-lock-doc-tag-face ((,class (:foreground ,magenta))))
   `(jdee-font-lock-italic-face ((,class (:slant italic))))
   `(jdee-font-lock-link-face ((,class (:foreground ,blue :underline t))))
   `(jdee-font-lock-modifier-face ((,class (:foreground ,yellow))))
   `(jdee-font-lock-number-face ((,class (:foreground ,orange))))
   `(jdee-font-lock-operator-face ((,class (:foreground ,fg))))
   `(jdee-font-lock-private-face ((,class (:foreground ,darkred))))
   `(jdee-font-lock-protected-face ((,class (:foreground ,darkred))))
   `(jdee-font-lock-public-face ((,class (:foreground ,darkred))))

;;;; js2-mode
   `(js2-external-variable ((,class (:foreground ,fg))))
   `(js2-function-call ((,class (:foreground ,blue))))
   `(js2-function-param ((,class (:foreground ,red))))
   `(js2-jsdoc-tag ((,class (:foreground ,rouge5))))
   `(js2-object-property ((,class (:foreground ,magenta))))

;;;; keycast
   `(keycast-command ((,class (:foreground ,red))))
   `(keycast-key ((,class (:foreground ,red :weight bold))))

;;;; ledger-mode
   `(ledger-font-payee-cleared-face ((,class (:foreground ,magenta :weight bold))))
   `(ledger-font-payee-uncleared-face ((,class (:foreground ,rouge5  :weight bold))))
   `(ledger-font-posting-account-face ((,class (:foreground ,rouge8))))
   `(ledger-font-posting-amount-face ((,class (:foreground ,yellow))))
   `(ledger-font-posting-date-face ((,class (:foreground ,blue))))
   `(ledger-font-xact-highlight-face ((,class (:background ,rouge0))))

;;;; line numbers
   `(line-number ((,class (:foreground ,rouge5))))
   `(line-number-current-line ((,class (:background ,rouge2 :foreground ,fg))))

;;;; linum
   `(linum ((,class (:foreground ,rouge5))))

;;;; linum-relative
   `(linum-relative-current-face ((,class (:background ,rouge2 :foreground ,fg))))

;;;; lsp-mode
   `(lsp-face-highlight-read ((,class (:background ,darkblue :foreground ,rouge8 :distant-foreground ,rouge0 :weight bold))))
   `(lsp-face-highlight-textual ((,class (:background ,darkblue :foreground ,rouge8 :distant-foreground ,rouge0 :weight bold))))
   `(lsp-face-highlight-write ((,class (:background ,darkblue :foreground ,rouge8 :distant-foreground ,rouge0 :weight bold))))
   `(lsp-headerline-breadcrumb-separator-face ((,class (:foreground ,fg-other))))
   `(lsp-ui-doc-background ((,class (:background ,bg-other :foreground ,fg))))
   `(lsp-ui-peek-filename ((,class (:weight bold))))
   `(lsp-ui-peek-header ((,class (:foreground ,fg :background ,bg :weight bold))))
   `(lsp-ui-peek-highlight ((,class (:background ,grey :foreground ,bg :box t))))
   `(lsp-ui-peek-line-number ((,class (:foreground ,green))))
   `(lsp-ui-peek-list ((,class (:background ,bg))))
   `(lsp-ui-peek-peek ((,class (:background ,bg))))
   `(lsp-ui-peek-selection ((,class (:foreground ,bg :background ,blue :bold bold))))
   `(lsp-ui-sideline-code-action ((,class (:foreground ,orange))))
   `(lsp-ui-sideline-current-symbol ((,class (:foreground ,orange))))
   `(lsp-ui-sideline-symbol-info ((,class (:foreground ,rouge5 :background ,bg-other :extend t))))

;;;; lui
   `(lui-button-face ((,class (:foreground ,orange :underline t))))
   `(lui-highlight-face ((,class (:foreground ,orange))))
   `(lui-time-stamp-face ((,class (:foreground ,magenta))))

;;;; magit
   `(magit-bisect-bad ((,class (:foreground ,red))))
   `(magit-bisect-good ((,class (:foreground ,green))))
   `(magit-bisect-skip ((,class (:foreground ,red))))
   `(magit-blame-date ((,class (:foreground ,red))))
   `(magit-blame-heading ((,class (:foreground ,darkred :background ,rouge3 :extend t))))
   `(magit-branch-current ((,class (:foreground ,red))))
   `(magit-branch-local ((,class (:foreground ,red))))
   `(magit-branch-remote ((,class (:foreground ,green))))
   `(magit-branch-remote-head ((,class (:foreground ,green))))
   `(magit-cherry-equivalent ((,class (:foreground ,magenta))))
   `(magit-cherry-unmatched ((,class (:foreground ,cyan))))
   `(magit-diff-added ((,class (:foreground ,bg  :background ,green :extend t))))
   `(magit-diff-added-highlight ((,class (:foreground ,bg :background ,green :weight bold :extend t))))
   `(magit-diff-base ((,class (:foreground ,darkred :background ,orange :extend t))))
   `(magit-diff-base-highlight ((,class (:foreground ,darkred :background ,orange :weight bold :extend t))))
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
   `(magit-dimmed ((,class (:foreground ,rouge5))))
   `(magit-filename ((,class (:foreground ,magenta))))
   `(magit-hash ((,class (:foreground ,blue))))
   `(magit-header-line ((,class (:background ,bg-other :foreground ,darkcyan :weight bold :box (:line-width 3 :color ,bg-other)))))
   `(magit-log-author ((,class (:foreground ,darkred))))
   `(magit-log-date ((,class (:foreground ,blue))))
   `(magit-log-graph ((,class (:foreground ,rouge5))))
   `(magit-process-ng ((,class (:foreground ,red))))
   `(magit-process-ok ((,class (:foreground ,green))))
   `(magit-reflog-amend ((,class (:foreground ,purple))))
   `(magit-reflog-checkout ((,class (:foreground ,blue))))
   `(magit-reflog-cherry-pick ((,class (:foreground ,green))))
   `(magit-reflog-commit ((,class (:foreground ,green))))
   `(magit-reflog-merge ((,class (:foreground ,green))))
   `(magit-reflog-other ((,class (:foreground ,cyan))))
   `(magit-reflog-rebase ((,class (:foreground ,purple))))
   `(magit-reflog-remote ((,class (:foreground ,cyan))))
   `(magit-reflog-reset ((,class (:foreground ,red))))
   `(magit-refname ((,class (:foreground ,rouge5))))
   `(magit-section-heading ((,class (:foreground ,darkcyan :weight bold :extend t))))
   `(magit-section-heading-selection ((,class (:foreground ,darkred :weight bold :extend t))))
   `(magit-section-highlight ((,class (:background ,rouge2 :extend t))))
   `(magit-section-secondary-heading ((,class (:foreground ,magenta :weight bold :extend t))))
   `(magit-sequence-drop ((,class (:foreground ,red))))
   `(magit-sequence-head ((,class (:foreground ,blue))))
   `(magit-sequence-part ((,class (:foreground ,darkred))))
   `(magit-sequence-stop ((,class (:foreground ,green))))
   `(magit-signature-bad ((,class (:foreground ,red))))
   `(magit-signature-error ((,class (:foreground ,red))))
   `(magit-signature-expired ((,class (:foreground ,darkred))))
   `(magit-signature-good ((,class (:foreground ,green))))
   `(magit-signature-revoked ((,class (:foreground ,purple))))
   `(magit-signature-untrusted ((,class (:foreground ,yellow))))
   `(magit-tag ((,class (:foreground ,yellow))))

;;;; make-mode
   `(makefile-targets ((,class (:foreground ,blue))))

;;;; marginalia
   `(marginalia-documentation ((,class (:foreground ,blue))))
   `(marginalia-file-name ((,class (:foreground ,blue))))

;;;; markdown-mode
   `(markdown-blockquote-face ((,class (:foreground ,rouge5 :slant italic))))
   `(markdown-bold-face ((,class (:foreground ,red :weight bold))))
   `(markdown-code-face ((,class (:background ,bg-org :extend t))))
   `(markdown-header-delimiter-face ((,class (:foreground ,red :weight bold))))
   `(markdown-header-face ((,class (:foreground ,red :weight bold))))
   `(markdown-html-attr-name-face ((,class (:foreground ,red))))
   `(markdown-html-attr-value-face ((,class (:foreground ,orange))))
   `(markdown-html-entity-face ((,class (:foreground ,red))))
   `(markdown-html-tag-delimiter-face ((,class (:foreground ,fg))))
   `(markdown-html-tag-name-face ((,class (:foreground ,darkred))))
   `(markdown-inline-code-face ((,class (:background ,bg-org :foreground ,green))))
   `(markdown-italic-face ((,class (:foreground ,magenta :slant italic))))
   `(markdown-link-face ((,class (:foreground ,red))))
   `(markdown-list-face ((,class (:foreground ,red))))
   `(markdown-markup-face ((,class (:foreground ,fg))))
   `(markdown-metadata-key-face ((,class (:foreground ,red))))
   `(markdown-pre-face ((,class (:background ,bg-org :foreground ,green))))
   `(markdown-reference-face ((,class (:foreground ,rouge5))))
   `(markdown-url-face ((,class (:foreground ,purple))))

;;;; message
   `(message-cited-text ((,class (:foreground ,purple))))
   `(message-header-cc ((,class (:foreground ,red :weight bold))))
   `(message-header-name ((,class (:foreground ,green))))
   `(message-header-newsgroups ((,class (:foreground ,yellow))))
   `(message-header-other ((,class (:foreground ,magenta))))
   `(message-header-subject ((,class (:foreground ,red :weight bold))))
   `(message-header-to ((,class (:foreground ,red :weight bold))))
   `(message-header-xheader ((,class (:foreground ,rouge5))))
   `(message-mml ((,class (:foreground ,rouge5 :slant italic))))
   `(message-separator ((,class (:foreground ,rouge5))))

;;;; mic-paren
   `(paren-face-match ((,class (:foreground ,red :background ,rouge0 :weight ultra-bold))))
   `(paren-face-mismatch ((,class (:foreground ,rouge0 :background ,red :weight ultra-bold))))
   `(paren-face-no-match ((,class (:foreground ,rouge0 :background ,red :weight ultra-bold))))

;;;; minimap
   `(minimap-active-region-background ((,class (:background ,bg))))
   `(minimap-current-line-face ((,class (:background ,grey))))

;;;; mmm-mode
   `(mmm-cleanup-submode-face ((,class (:background ,yellow))))
   `(mmm-code-submode-face ((,class (:background ,bg-other))))
   `(mmm-comment-submode-face ((,class (:background ,blue))))
   `(mmm-declaration-submode-face ((,class (:background ,cyan))))
   `(mmm-default-submode-face ((,class (:background nil))))
   `(mmm-init-submode-face ((,class (:background ,red))))
   `(mmm-output-submode-face ((,class (:background ,magenta))))
   `(mmm-special-submode-face ((,class (:background ,green))))

;;;; mode-line
   `(mode-line ((,class (:background ,rouge1 :foreground ,fg :distant-foreground ,bg))))
   `(mode-line-buffer-id ((,class (:weight bold))))
   `(mode-line-emphasis ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(mode-line-highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(mode-line-inactive ((,class (:background ,rouge2 :foreground ,rouge5 :distant-foreground ,bg-other))))

;;;; mu4e
   `(mu4e-forwarded-face ((,class (:foreground ,red))))
   `(mu4e-header-key-face ((,class (:foreground ,red))))
   `(mu4e-header-title-face ((,class (:foreground ,darkred))))
   `(mu4e-highlight-face ((,class (:foreground ,bg :background ,darkblue))))
   `(mu4e-replied-face ((,class (:foreground ,darkblue :weight bold))))
   `(mu4e-title-face ((,class (:foreground ,darkred))))
   `(mu4e-unread-face ((,class (:foreground ,darkred :weight bold))))

;;;; mu4e-column-faces
   `(mu4e-column-faces-date ((,class (:foreground ,rouge5))))
   `(mu4e-column-faces-flags ((,class (:foreground ,red))))
   `(mu4e-column-faces-to-from ((,class (:foreground ,darkcyan))))

;;;; mu4e-thread-folding
   `(mu4e-thread-folding-child-face ((,class (:extend t :background ,bg-org :underline nil))))
   `(mu4e-thread-folding-root-folded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))
   `(mu4e-thread-folding-root-unfolded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))

;;;; multiple cursors
   `(mc/cursor-face ((,class (:background ,darkred))))

;;;; nano-modeline
   `(nano-modeline-active-name ((,class (:foreground ,fg :weight bold))))
   `(nano-modeline-inactive-name ((,class (:foreground ,rouge5 :weight bold))))
   `(nano-modeline-active-primary ((,class (:foreground ,fg))))
   `(nano-modeline-inactive-primary ((,class (:foreground ,rouge5))))
   `(nano-modeline-active-secondary ((,class (:foreground ,orange :weight bold))))
   `(nano-modeline-inactive-secondary ((,class (:foreground ,rouge5 :weight bold))))
   `(nano-modeline-active-status-RO ((,class (:background ,red :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-RO ((,class (:background ,rouge5 :foreground ,bg :weight bold))))
   `(nano-modeline-active-status-RW ((,class (:background ,orange :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-RW ((,class (:background ,rouge5 :foreground ,bg :weight bold))))
   `(nano-modeline-active-status-** ((,class (:background ,red :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-** ((,class (:background ,rouge5 :foreground ,bg :weight bold))))

;;;; nav-flash
   `(nav-flash-face ((,class (:background ,grey :foreground ,rouge8 :weight bold))))

;;;; neotree
   `(neo-dir-link-face ((,class (:foreground ,orange))))
   `(neo-expand-btn-face ((,class (:foreground ,orange))))
   `(neo-file-link-face ((,class (:foreground ,fg))))
   `(neo-root-dir-face ((,class (:foreground ,green :background ,bg :box (:line-width 4 :color ,bg)))))
   `(neo-vc-added-face ((,class (:foreground ,green))))
   `(neo-vc-conflict-face ((,class (:foreground ,purple :weight bold))))
   `(neo-vc-edited-face ((,class (:foreground ,yellow))))
   `(neo-vc-ignored-face ((,class (:foreground ,rouge5))))
   `(neo-vc-removed-face ((,class (:foreground ,red :strike-through t))))

;;;; nlinum
   `(nlinum-current-line ((,class (:background ,rouge2 :foreground ,fg))))

;;;; nlinum-hl
   `(nlinum-hl-face ((,class (:background ,rouge2 :foreground ,fg))))

;;;; nlinum-relative
   `(nlinum-relative-current-face ((,class (:background ,rouge2 :foreground ,fg))))

;;;; notmuch
   `(notmuch-message-summary-face ((,class (:foreground ,grey :background nil))))
   `(notmuch-search-count ((,class (:foreground ,rouge5))))
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
   `(notmuch-tree-match-tree-face ((,class (:foreground ,rouge5))))
   `(notmuch-tree-no-match-author-face ((,class (:foreground ,blue))))
   `(notmuch-tree-no-match-date-face ((,class (:foreground ,orange))))
   `(notmuch-tree-no-match-face ((,class (:foreground ,rouge5))))
   `(notmuch-tree-no-match-subject-face ((,class (:foreground ,rouge5))))
   `(notmuch-tree-no-match-tag-face ((,class (:foreground ,yellow))))
   `(notmuch-tree-no-match-tree-face ((,class (:foreground ,yellow))))
   `(notmuch-wash-cited-text ((,class (:foreground ,rouge4))))
   `(notmuch-wash-toggle-button ((,class (:foreground ,fg))))

;;;; orderless
   `(orderless-match-face-0 ((,class (:foreground ,teal :weight bold :underline t))))
   `(orderless-match-face-1 ((,class (:foreground ,darkcyan :weight bold :underline t))))
   `(orderless-match-face-2 ((,class (:foreground ,cyan :weight bold :underline t))))
   `(orderless-match-face-3 ((,class (:foreground ,green :weight bold :underline t))))

;;;; objed
   `(objed-hl ((,class (:background ,grey :distant-foreground ,bg :extend t))))
   `(objed-mode-line ((,class (:foreground ,yellow :weight bold))))

;;;; org-agenda
   `(org-agenda-clocking ((,class (:background ,blue))))
   `(org-agenda-date ((,class (:foreground ,magenta :weight ultra-bold))))
   `(org-agenda-date-today ((,class (:foreground ,magenta :weight ultra-bold))))
   `(org-agenda-date-weekend ((,class (:foreground ,magenta :weight ultra-bold))))
   `(org-agenda-dimmed-todo-face ((,class (:foreground ,rouge5))))
   `(org-agenda-done ((,class (:foreground ,rouge5))))
   `(org-agenda-structure ((,class (:foreground ,fg :weight ultra-bold))))
   `(org-scheduled ((,class (:foreground ,fg))))
   `(org-scheduled-previously ((,class (:foreground ,rouge8))))
   `(org-scheduled-today ((,class (:foreground ,rouge7))))
   `(org-sexp-date ((,class (:foreground ,fg))))
   `(org-time-grid ((,class (:foreground ,rouge5))))
   `(org-upcoming-deadline ((,class (:foreground ,fg))))
   `(org-upcoming-distant-deadline ((,class (:foreground ,fg))))

;;;; org-habit
   `(org-habit-alert-face ((,class (:weight bold :background ,yellow))))
   `(org-habit-alert-future-face ((,class (:weight bold :background ,yellow))))
   `(org-habit-clear-face ((,class (:weight bold :background ,rouge4))))
   `(org-habit-clear-future-face ((,class (:weight bold :background ,rouge3))))
   `(org-habit-overdue-face ((,class (:weight bold :background ,red))))
   `(org-habit-overdue-future-face ((,class (:weight bold :background ,red))))
   `(org-habit-ready-face ((,class (:weight bold :background ,blue))))
   `(org-habit-ready-future-face ((,class (:weight bold :background ,blue))))

;;;; org-journal
   `(org-journal-calendar-entry-face ((,class (:foreground ,purple :slant italic))))
   `(org-journal-calendar-scheduled-face ((,class (:foreground ,red :slant italic))))
   `(org-journal-highlight ((,class (:foreground ,darkred))))

;;;; org-mode
   `(org-archived ((,class (:foreground ,rouge5))))
   `(org-block ((,class (:foreground ,rouge8 :background ,bg-org :extend t))))
   `(org-block-background ((,class (:background ,bg-org :extend t))))
   `(org-block-begin-line ((,class (:foreground ,rouge5 :slant italic :background ,bg-org :extend t))))
   `(org-block-end-line ((,class (:foreground ,rouge5 :slant italic :background ,bg-org :extend t))))
   `(org-checkbox ((,class (:foreground ,green :weight bold))))
   `(org-checkbox-statistics-done ((,class (:foreground ,rouge5 :weight bold))))
   `(org-checkbox-statistics-todo ((,class (:foreground ,green :weight bold))))
   `(org-code ((,class (:foreground ,orange))))
   `(org-date ((,class (:foreground ,yellow))))
   `(org-default ((,class (:background ,bg :foreground ,fg))))
   `(org-document-info ((,class (:foreground ,darkred))))
   `(org-document-title ((,class (:foreground ,darkred :weight bold))))
   `(org-done ((,class (:foreground ,rouge5 :weight bold))))
   `(org-ellipsis ((,class (:foreground ,grey))))
   `(org-footnote ((,class (:foreground ,darkred))))
   `(org-formula ((,class (:foreground ,cyan))))
   `(org-headline-done ((,class (:foreground ,rouge5))))
   `(org-hide ((,class (:foreground ,bg))))
   `(org-latex-and-related ((,class (:foreground ,rouge8 :weight bold))))
   `(org-level-1 ((,class (:foreground ,blue :weight ultra-bold))))
   `(org-level-2 ((,class (:foreground ,magenta :weight bold))))
   `(org-level-3 ((,class (:foreground ,darkcyan :weight bold))))
   `(org-level-4 ((,class (:foreground ,darkred))))
   `(org-level-5 ((,class (:foreground ,green))))
   `(org-level-6 ((,class (:foreground ,teal))))
   `(org-level-7 ((,class (:foreground ,purple))))
   `(org-level-8 ((,class (:foreground ,fg))))
   `(org-link ((,class (:foreground ,red :underline t))))
   `(org-list-dt ((,class (:foreground ,darkred))))
   `(org-meta-line ((,class (:foreground ,rouge5))))
   `(org-priority ((,class (:foreground ,red))))
   `(org-property-value ((,class (:foreground ,rouge5))))
   `(org-quote ((,class (:background ,rouge3 :slant italic :extend t))))
   `(org-special-keyword ((,class (:foreground ,rouge5))))
   `(org-table ((,class (:foreground ,red))))
   `(org-tag ((,class (:foreground ,rouge5 :weight normal))))
   `(org-todo ((,class (:foreground ,green :weight bold))))
   `(org-verbatim ((,class (:foreground ,darkred))))
   `(org-warning ((,class (:foreground ,yellow))))

;;;; org-pomodoro
   `(org-pomodoro-mode-line ((,class (:foreground ,red))))
   `(org-pomodoro-mode-line-overtime ((,class (:foreground ,yellow :weight bold))))

;;;; org-ref
   `(org-ref-acronym-face ((,class (:foreground ,magenta))))
   `(org-ref-cite-face ((,class (:foreground ,yellow :weight light :underline t))))
   `(org-ref-glossary-face ((,class (:foreground ,purple))))
   `(org-ref-label-face ((,class (:foreground ,blue))))
   `(org-ref-ref-face ((,class (:foreground ,red :underline t :weight bold))))

;;;; outline
   `(outline-1 ((,class (:foreground ,blue :weight ultra-bold))))
   `(outline-2 ((,class (:foreground ,magenta :weight bold))))
   `(outline-3 ((,class (:foreground ,green :weight bold))))
   `(outline-4 ((,class (:foreground ,darkred))))
   `(outline-5 ((,class (:foreground ,purple))))
   `(outline-6 ((,class (:foreground ,purple))))
   `(outline-7 ((,class (:foreground ,purple))))
   `(outline-8 ((,class (:foreground ,fg))))

;;;; parenface
   `(paren-face ((,class (:foreground ,rouge5))))

;;;; parinfer
   `(parinfer-pretty-parens:dim-paren-face ((,class (:foreground ,rouge5))))
   `(parinfer-smart-tab:indicator-face ((,class (:foreground ,rouge5))))

;;;; persp-mode
   `(persp-face-lighter-buffer-not-in-persp ((,class (:foreground ,rouge5))))
   `(persp-face-lighter-default ((,class (:foreground ,red :weight bold))))
   `(persp-face-lighter-nil-persp ((,class (:foreground ,rouge5))))

;;;; perspective
   `(persp-selected-face ((,class (:foreground ,blue :weight bold))))

;;;; pkgbuild-mode
   `(pkgbuild-error-face ((,class (:underline (:style wave :color ,red)))))

;;;; popup
   `(popup-face ((,class (:background ,bg-other :foreground ,fg))))
   `(popup-selection-face ((,class (:background ,grey))))
   `(popup-tip-face ((,class (:foreground ,magenta :background ,rouge0))))

;;;; powerline
   `(powerline-active0 ((,class (:background ,rouge1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-active1 ((,class (:background ,rouge1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-active2 ((,class (:background ,rouge1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-inactive0 ((,class (:background ,rouge2 :foreground ,rouge5 :distant-foreground ,bg-other))))
   `(powerline-inactive1 ((,class (:background ,rouge2 :foreground ,rouge5 :distant-foreground ,bg-other))))
   `(powerline-inactive2 ((,class (:background ,rouge2 :foreground ,rouge5 :distant-foreground ,bg-other))))

;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((,class (:foreground ,blue))))
   `(rainbow-delimiters-depth-2-face ((,class (:foreground ,purple))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground ,green))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground ,red))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground ,magenta))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground ,yellow))))
   `(rainbow-delimiters-depth-7-face ((,class (:foreground ,teal))))
   `(rainbow-delimiters-mismatched-face ((,class (:foreground ,red :weight bold :inverse-video t))))
   `(rainbow-delimiters-unmatched-face ((,class (:foreground ,red :weight bold :inverse-video t))))

;;;; re-builder
   `(reb-match-0 ((,class (:foreground ,red :inverse-video t))))
   `(reb-match-1 ((,class (:foreground ,purple :inverse-video t))))
   `(reb-match-2 ((,class (:foreground ,green :inverse-video t))))
   `(reb-match-3 ((,class (:foreground ,yellow :inverse-video t))))

;;;; rjsx-mode
   `(rjsx-attr ((,class (:foreground ,blue))))
   `(rjsx-tag ((,class (:foreground ,yellow))))

;;;; rpm-spec-mode
   `(rpm-spec-dir-face ((,class (:foreground ,green))))
   `(rpm-spec-doc-face ((,class (:foreground ,orange))))
   `(rpm-spec-ghost-face ((,class (:foreground ,rouge5))))
   `(rpm-spec-macro-face ((,class (:foreground ,yellow))))
   `(rpm-spec-obsolete-tag-face ((,class (:foreground ,red))))
   `(rpm-spec-package-face ((,class (:foreground ,orange))))
   `(rpm-spec-section-face ((,class (:foreground ,purple))))
   `(rpm-spec-tag-face ((,class (:foreground ,blue))))
   `(rpm-spec-var-face ((,class (:foreground ,magenta))))

;;;; rst
   `(rst-block ((,class (:foreground ,red))))
   `(rst-level-1 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-2 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-3 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-4 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-5 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-6 ((,class (:foreground ,magenta :weight bold))))

;;;; selectrum
   `(selectrum-current-candidate ((,class (:background ,grey :distant-foreground nil :extend t))))

;;;; sh-script
   `(sh-heredoc ((,class (:foreground ,orange))))
   `(sh-quoted-exec ((,class (:foreground ,fg :weight bold))))

;;;; show-paren
   `(show-paren-match ((,class (:foreground ,red :background ,rouge0 :weight ultra-bold))))
   `(show-paren-mismatch ((,class (:foreground ,rouge0 :background ,red :weight ultra-bold))))

;;;; smart-mode-line
   `(sml/charging ((,class (:foreground ,green))))
   `(sml/discharging ((,class (:foreground ,yellow :weight bold))))
   `(sml/filename ((,class (:foreground ,magenta :weight bold))))
   `(sml/git ((,class (:foreground ,blue))))
   `(sml/modified ((,class (:foreground ,cyan))))
   `(sml/outside-modified ((,class (:foreground ,cyan))))
   `(sml/process ((,class (:weight bold))))
   `(sml/read-only ((,class (:foreground ,cyan))))
   `(sml/sudo ((,class (:foreground ,red :weight bold))))
   `(sml/vc-edited ((,class (:foreground ,green))))

;;;; smartparens
   `(sp-pair-overlay-face ((,class (:background ,grey))))
   `(sp-show-pair-match-face ((,class (:foreground ,red :background ,rouge0 :weight ultra-bold))))
   `(sp-show-pair-mismatch-face ((,class (:foreground ,rouge0 :background ,red :weight ultra-bold))))

;;;; smerge-tool
   `(smerge-base ((,class (:background ,blue))))
   `(smerge-lower ((,class (:background ,green))))
   `(smerge-markers ((,class (:background ,rouge5 :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(smerge-mine ((,class (:background ,red))))
   `(smerge-other ((,class (:background ,green))))
   `(smerge-refined-added ((,class (:background ,green :inverse-video t))))
   `(smerge-refined-removed ((,class (:foreground ,red :inverse-video t))))
   `(smerge-upper ((,class (:background ,red))))

;;;; solaire-mode
   `(solaire-default-face ((,class (:background ,bg-other))))
   `(solaire-hl-line-face ((,class (:background ,rouge2 :extend t))))
   `(solaire-mode-line-face ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))
   `(solaire-mode-line-inactive-face ((,class (:background ,bg-other :foreground ,fg-other :distant-foreground ,bg-other))))
   `(solaire-org-hide-face ((,class (:foreground ,bg))))

;;;; spaceline
   `(spaceline-evil-emacs ((,class (:background ,cyan))))
   `(spaceline-evil-insert ((,class (:background ,green))))
   `(spaceline-evil-motion ((,class (:background ,purple))))
   `(spaceline-evil-normal ((,class (:background ,blue))))
   `(spaceline-evil-replace ((,class (:background ,red))))
   `(spaceline-evil-visual ((,class (:background ,grey))))
   `(spaceline-flycheck-error ((,class (:foreground ,red :distant-background ,rouge0))))
   `(spaceline-flycheck-info ((,class (:foreground ,green :distant-background ,rouge0))))
   `(spaceline-flycheck-warning ((,class (:foreground ,yellow :distant-background ,rouge0))))
   `(spaceline-highlight-face ((,class (:background ,red))))
   `(spaceline-modified ((,class (:background ,red))))
   `(spaceline-python-venv ((,class (:foreground ,purple :distant-foreground ,magenta))))
   `(spaceline-unmodified ((,class (:background ,red))))

;;;; stripe-buffer
   `(stripe-highlight ((,class (:background ,rouge3))))

;;;; swiper
   `(swiper-line-face ((,class (:background ,blue :foreground ,rouge0))))
   `(swiper-match-face-1 ((,class (:background ,rouge0 :foreground ,rouge5))))
   `(swiper-match-face-2 ((,class (:background ,orange :foreground ,rouge0 :weight bold))))
   `(swiper-match-face-3 ((,class (:background ,purple :foreground ,rouge0 :weight bold))))
   `(swiper-match-face-4 ((,class (:background ,green :foreground ,rouge0 :weight bold))))

;;;; tabbar
   `(tabbar-button ((,class (:foreground ,fg :background ,bg))))
   `(tabbar-button-highlight ((,class (:foreground ,fg :background ,bg :inverse-video t))))
   `(tabbar-default ((,class (:foreground ,bg :background ,bg :height 1.0))))
   `(tabbar-highlight ((,class (:foreground ,fg :background ,grey :distant-foreground ,bg))))
   `(tabbar-modified ((,class (:foreground ,red :weight bold))))
   `(tabbar-selected ((,class (:foreground ,fg :background ,bg-other :weight bold))))
   `(tabbar-selected-modified ((,class (:foreground ,green :background ,bg-other :weight bold))))
   `(tabbar-unselected ((,class (:foreground ,rouge5))))
   `(tabbar-unselected-modified ((,class (:foreground ,red :weight bold))))

;;;; tab-bar
   `(tab-bar ((,class (:background ,bg-other :foreground ,bg-other))))
   `(tab-bar-tab ((,class (:background ,bg :foreground ,fg))))
   `(tab-bar-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; tab-line
   `(tab-line ((,class (:background ,bg-other :foreground ,bg-other))))
   `(tab-line-close-highlight ((,class (:foreground ,red))))
   `(tab-line-highlight ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab-current ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; telephone-line
   `(telephone-line-accent-active ((,class (:foreground ,fg :background ,rouge4))))
   `(telephone-line-accent-inactive ((,class (:foreground ,fg :background ,rouge2))))
   `(telephone-line-evil ((,class (:foreground ,fg :weight bold))))
   `(telephone-line-evil-emacs ((,class (:background ,purple :weight bold))))
   `(telephone-line-evil-insert ((,class (:background ,green :weight bold))))
   `(telephone-line-evil-motion ((,class (:background ,blue :weight bold))))
   `(telephone-line-evil-normal ((,class (:background ,red :weight bold))))
   `(telephone-line-evil-operator ((,class (:background ,magenta :weight bold))))
   `(telephone-line-evil-replace ((,class (:background ,bg-other :weight bold))))
   `(telephone-line-evil-visual ((,class (:background ,red :weight bold))))
   `(telephone-line-projectile ((,class (:foreground ,green))))

;;;; term
   `(term ((,class (:foreground ,fg))))
   `(term-bold ((,class (:weight bold))))
   `(term-color-black ((,class (:background ,rouge0 :foreground ,rouge0))))
   `(term-color-blue ((,class (:background ,blue :foreground ,blue))))
   `(term-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
   `(term-color-green ((,class (:background ,green :foreground ,green))))
   `(term-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
   `(term-color-purple ((,class (:background ,purple :foreground ,purple))))
   `(term-color-red ((,class (:background ,red :foreground ,red))))
   `(term-color-white ((,class (:background ,rouge8 :foreground ,rouge8))))
   `(term-color-yellow ((,class (:background ,yellow :foreground ,yellow))))
   `(term-color-bright-black ((,class (:foreground ,rouge0))))
   `(term-color-bright-blue ((,class (:foreground ,blue))))
   `(term-color-bright-cyan ((,class (:foreground ,cyan))))
   `(term-color-bright-green ((,class (:foreground ,green))))
   `(term-color-bright-magenta ((,class (:foreground ,magenta))))
   `(term-color-bright-purple ((,class (:foreground ,purple))))
   `(term-color-bright-red ((,class (:foreground ,red))))
   `(term-color-bright-white ((,class (:foreground ,rouge8))))
   `(term-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; tldr
   `(tldr-code-block ((,class (:foreground ,green :background ,grey :weight semi-bold))))
   `(tldr-command-argument ((,class (:foreground ,fg :background ,grey))))
   `(tldr-command-itself ((,class (:foreground ,bg :background ,green :weight semi-bold))))
   `(tldr-description ((,class (:foreground ,fg :weight semi-bold))))
   `(tldr-introduction ((,class (:foreground ,blue :weight semi-bold))))
   `(tldr-title ((,class (:foreground ,yellow :bold t :height 1.4))))

;;;; treemacs
   `(treemacs-directory-face ((,class (:foreground ,fg))))
   `(treemacs-file-face ((,class (:foreground ,fg))))
   `(treemacs-git-added-face ((,class (:foreground ,green))))
   `(treemacs-git-conflict-face ((,class (:foreground ,red))))
   `(treemacs-git-modified-face ((,class (:foreground ,magenta))))
   `(treemacs-git-untracked-face ((,class (:foreground ,rouge5))))
   `(treemacs-root-face ((,class (:foreground ,orange :weight bold :height 1.2))))
   `(treemacs-tags-face ((,class (:foreground ,red))))

;;;; tree-sitter-hl
   `(tree-sitter-hl-face:function ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:function.call ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:function.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:function.special ((,class (:foreground ,fg :weight bold))))
   `(tree-sitter-hl-face:function.macro ((,class (:foreground ,fg :weight bold))))
   `(tree-sitter-hl-face:method ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:method.call ((,class (:foreground ,orange))))
   `(tree-sitter-hl-face:type ((,class (:foreground ,yellow))))
   `(tree-sitter-hl-face:type.parameter ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:type.argument ((,class (:foreground ,yellow))))
   `(tree-sitter-hl-face:type.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:type.super ((,class (:foreground ,yellow))))
   `(tree-sitter-hl-face:constructor ((,class (:foreground ,yellow))))
   `(tree-sitter-hl-face:variable ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:variable.parameter ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:variable.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:variable.special ((,class (:foreground ,yellow))))
   `(tree-sitter-hl-face:property ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:property.definition ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:comment ((,class (:foreground ,rouge5 :slant italic))))
   `(tree-sitter-hl-face:doc ((,class (:foreground ,rouge5 :slant italic))))
   `(tree-sitter-hl-face:string ((,class (:foreground ,green))))
   `(tree-sitter-hl-face:string.special ((,class (:foreground ,green :weight bold))))
   `(tree-sitter-hl-face:escape ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:embedded ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:keyword ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:operator ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:label ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:constant ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:constant.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:number ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:punctuation ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.bracket ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.delimiter ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.special ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:tag ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:attribute ((,class (:foreground ,fg))))

;;;; typescript-mode
   `(typescript-jsdoc-tag ((,class (:foreground ,rouge5))))
   `(typescript-jsdoc-type ((,class (:foreground ,rouge5))))
   `(typescript-jsdoc-value ((,class (:foreground ,rouge5))))

;;;; undo-tree
   `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,blue))))
   `(undo-tree-visualizer-current-face ((,class (:foreground ,green :weight bold))))
   `(undo-tree-visualizer-default-face ((,class (:foreground ,rouge5))))
   `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow))))
   `(undo-tree-visualizer-unmodified-face ((,class (:foreground ,rouge5))))

;;;; vimish-fold
   `(vimish-fold-fringe ((,class (:foreground ,purple))))
   `(vimish-fold-overlay ((,class (:foreground ,rouge5 :background ,rouge0 :weight light))))

;;;; volatile-highlights
   `(vhl/default-face ((,class (:background ,grey))))

;;;; vterm
   `(vterm ((,class (:foreground ,fg))))
   `(vterm-color-black ((,class (:background ,rouge0 :foreground ,rouge0))))
   `(vterm-color-blue ((,class (:background ,blue :foreground ,blue))))
   `(vterm-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
   `(vterm-color-default ((,class (:foreground ,fg))))
   `(vterm-color-green ((,class (:background ,green :foreground ,green))))
   `(vterm-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
   `(vterm-color-purple ((,class (:background ,purple :foreground ,purple))))
   `(vterm-color-red ((,class (:background ,red :foreground ,red))))
   `(vterm-color-white ((,class (:background ,rouge8 :foreground ,rouge8))))
   `(vterm-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

;;;; web-mode
   `(web-mode-block-control-face ((,class (:foreground ,red))))
   `(web-mode-block-control-face ((,class (:foreground ,red))))
   `(web-mode-block-delimiter-face ((,class (:foreground ,red))))
   `(web-mode-css-property-name-face ((,class (:foreground ,yellow))))
   `(web-mode-doctype-face ((,class (:foreground ,rouge5))))
   `(web-mode-html-attr-name-face ((,class (:foreground ,yellow))))
   `(web-mode-html-attr-value-face ((,class (:foreground ,green))))
   `(web-mode-html-entity-face ((,class (:foreground ,cyan :slant italic))))
   `(web-mode-html-tag-bracket-face ((,class (:foreground ,blue))))
   `(web-mode-html-tag-bracket-face ((,class (:foreground ,fg))))
   `(web-mode-html-tag-face ((,class (:foreground ,blue))))
   `(web-mode-json-context-face ((,class (:foreground ,green))))
   `(web-mode-json-key-face ((,class (:foreground ,green))))
   `(web-mode-keyword-face ((,class (:foreground ,magenta))))
   `(web-mode-string-face ((,class (:foreground ,green))))
   `(web-mode-type-face ((,class (:foreground ,yellow))))

;;;; wgrep
   `(wgrep-delete-face ((,class (:foreground ,rouge3 :background ,red))))
   `(wgrep-done-face ((,class (:foreground ,blue))))
   `(wgrep-face ((,class (:weight bold :foreground ,green :background ,rouge5))))
   `(wgrep-file-face ((,class (:foreground ,rouge5))))
   `(wgrep-reject-face ((,class (:foreground ,red :weight bold))))

;;;; which-func
   `(which-func ((,class (:foreground ,blue))))

;;;; which-key
   `(which-key-command-description-face ((,class (:foreground ,blue))))
   `(which-key-group-description-face ((,class (:foreground ,magenta))))
   `(which-key-key-face ((,class (:foreground ,green))))
   `(which-key-local-map-description-face ((,class (:foreground ,purple))))

;;;; whitespace
   `(whitespace-empty ((,class (:background ,rouge3))))
   `(whitespace-indentation ((,class (:foreground ,rouge4 :background ,rouge3))))
   `(whitespace-line ((,class (:background ,rouge0 :foreground ,red :weight bold))))
   `(whitespace-newline ((,class (:foreground ,rouge4))))
   `(whitespace-space ((,class (:foreground ,rouge4))))
   `(whitespace-tab ((,class (:foreground ,rouge4 :background ,rouge3))))
   `(whitespace-trailing ((,class (:background ,red))))

;;;; widget
   `(widget-button ((,class (:foreground ,fg :weight bold))))
   `(widget-button-pressed ((,class (:foreground ,red))))
   `(widget-documentation ((,class (:foreground ,green))))
   `(widget-field ((,class (:foreground ,fg :background ,rouge0 :extend nil))))
   `(widget-inactive ((,class (:foreground ,grey :background ,bg-other))))
   `(widget-single-line-field ((,class (:foreground ,fg :background ,rouge0))))

;;;; window-divider
   `(window-divider ((,class (:background ,red :foreground ,red))))
   `(window-divider-first-pixel ((,class (:background ,red :foreground ,red))))
   `(window-divider-last-pixel ((,class (:background ,red :foreground ,red))))

;;;; woman
   `(woman-bold ((,class (:foreground ,fg :weight bold))))
   `(woman-italic ((,class (:foreground ,magenta :underline ,magenta))))

;;;; workgroups2
   `(wg-brace-face ((,class (:foreground ,red))))
   `(wg-current-workgroup-face ((,class (:foreground ,rouge0 :background ,red))))
   `(wg-divider-face ((,class (:foreground ,grey))))
   `(wg-other-workgroup-face ((,class (:foreground ,rouge5))))

;;;; yasnippet
   `(yas-field-highlight-face ((,class (:foreground ,green :background ,rouge0 :weight bold))))

;;;; ytel
   `(ytel-video-published-face ((,class (:foreground ,magenta))))
   `(ytel-channel-name-face ((,class (:foreground ,orange))))
   `(ytel-video-length-face ((,class (:foreground ,blue))))
   `(ytel-video-view-face ((,class (:foreground ,darkcyan))))

   (custom-theme-set-variables
    'timu-rouge
    `(ansi-color-names-vector [bg, red, green, teal, cyan, blue, yellow, fg]))))


;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory
                (file-name-directory load-file-name))))

(provide-theme 'timu-rouge)

;;; timu-rouge-theme.el ends here
