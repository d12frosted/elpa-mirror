;;; dream-theme.el --- Maximalist Nordic/Zenburn-inspired color theme -*- lexical-binding:t -*-

;; Copyright (C) 2013-2021 Dirk-Jan C. Binnema

;; Author: Dirk-Jan C. Binnema <djcb@djcbsoftware.nl>
;; Created: 2013-01-27
;; Version: 1.0
;; Package-Version: 20210419.605
;; Package-Commit: 0c27f05544b90e41338f79ea923044b358a323c6
;; URL: https://github.com/djcb/dream-theme
;; Package-Requires: ((emacs "26.1"))
;; Keywords: faces, theme

;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Dark, clean theme for Emacs.  inspired by the zenburn, sinburn, Nord and similar
;; themes, but slowly diverging from them.


;;; Code:

(deftheme dream "The Dream Theme.")

;; colors based on Zenburn, Sinburn & Nord
;; https://github.com/arcticicestudio/nord

(let (; foreground
       (dt-fg            "#d8dee9")

       (dt-bg-1          "#21242b")
       ;(dt-bg-11         "#020e03")

       ;; backgrounds (from nordic / polar night)
       (dt-bg-2          "#181b1f")
       (dt-bg-7          "#282c34")
       (dt-bg-3          "#3b4252")
       (dt-bg-4          "#4b5262")
       (dt-bg-5          "#5c6373")

       ;; highlights from nordic / frost
       ;;(dt-bg-hl-1      "#8fbcbb")
       (dt-bg-hl-2      "#88c0d0")
       ;;(dt-bg-hl-3      "#81a1c1")
       ;;(dt-bg-hl-4      "#5e81ac")

       (dt-red          "#b1616a")
       (dt-orange       "#d68955")
       (dt-yellow       "#ebcb8b")
       (dt-green        "#a3be8c")
       (dt-cyan         "#93e0e3")

       (dt-blue-1       "#5e81ac")
       (dt-blue         "#81a1c1")
       (dt-magenta      "#dc8cc3"))

  (custom-theme-set-faces
    'dream
    ;; basics
    `(default ((t (:background ,dt-bg-1 :foreground ,dt-fg))))
    '(fixed-pitch ((t (:weight bold))))
    '(italic ((t (:slant italic))))
    '(underline ((t (:underline t))))
    `(fringe ((t (:background ,dt-bg-2))))
    `(header-line ((t (:box (:color ,dt-bg-1 :line-width 2)
                        :weight bold :foreground ,dt-blue-1
                        :background ,dt-bg-2))))
    `(highlight ((t (:weight bold :underline t :background nil
                      :foreground ,dt-orange))))
    `(hover-highlight ((t (:underline t :foreground nil
                            :background ,dt-green))))
    '(match ((t (:weight bold))))
    `(menu ((t (:background ,dt-bg-4))))
    `(mode-line ((t (:foreground nil :background ,dt-bg-2
                      :box (:color ,dt-bg-4 :line-width 2)))))
    `(mode-line-inactive ((t  (:inherit mode-line :foreground nil
                                :background ,dt-bg-3))))
    '(mouse ((t (:inherit dt-foreground))))
    '(paren ((t (:inherit dt-lowlight-1))))
    `(link ((t (:foreground ,dt-blue-1 :background nil :underline t))))
    `(help-argument-name ((t (:foreground ,dt-blue-1 :background nil
                               :weight bold))))
    `(border ((t (:background ,dt-bg-1))))
    `(button ((t (:foreground ,dt-yellow :background ,dt-blue-1
                   :weight bold :underline t))))
    `(cursor ((t (:background "White" :foreground ,dt-magenta))))
    `(minibuffer-prompt ((t (:foreground ,dt-red :weight bold :background
                              ,dt-bg-1))))
    `(region ((t (:foreground nil :background ,dt-bg-3))))
    `(scroll-bar ((t (:background ,dt-bg-4))))
    `(secondary-selection ((t (:foreground nil :background ,dt-bg-4))))
    `(tool-bar ((t (:background ,dt-bg-4))))
    `(whitespace-tab ((t (:background ,dt-bg-3))))
    `(whitespace-space ((t (:background ,dt-bg-2))))

    ;; ace
    `(ace-jump-face-foreground ((t (:foreground ,dt-blue :
                                     background ,dt-bg-4 :weight bold))))

    ;; avy
    `(avy-lead-face-0 ((t (:foreground ,dt-bg-4 :background
                            ,dt-yellow :weight bold :underline t))))
    `(avy-lead-face-1 ((t (:foreground ,dt-bg-4 :background
                            ,dt-yellow :weight bold :underline t))))
    `(avy-lead-face-2 ((t (:foreground ,dt-bg-4 :background ,dt-yellow
                            :weight bold :underline t))))
    `(avy-lead-face   ((t (:foreground ,dt-bg-4 :background ,dt-orange
                            :weight bold :underline t))))
    `(avy-background-face ((t (:foreground ,dt-cyan))))

    ;; company-mode
    `(company-tooltip ((t (:foreground ,dt-orange :background ,dt-bg-4))))
    `(company-tooltip-selection ((t (:foreground ,dt-green
                                      :weight bold :underline t
                                      :background ,dt-bg-4))))
    `(company-tooltip-search ((t (:foreground ,dt-orange :weight bold))))
    `(company-tooltip-mouse ((t (:foreground ,dt-green :weight bold))))
    `(company-tooltip-common ((t (:foreground ,dt-blue))))
    `(company-tooltip-common-selection ((t (:foreground ,dt-green))))
    `(company-tooltip-annotation ((t (:foreground ,dt-green :weight bold))))
    `(company-scrollbar-fg ((t (:foreground ,dt-orange :weight bold))))
    `(company-scrollbar-bg ((t (:foreground ,dt-green :weight bold))))
    `(company-preview ((t (:foreground ,dt-green :weight bold))))
    `(company-preview-common ((t (:foreground ,dt-green :weight bold))))
    `(company-preview-search ((t (:foreground ,dt-green :weight bold))))
        ;; hello
    ;; compilation
    `(compilation-warning ((t (:foreground ,dt-orange :weight bold))))
    `(compilation-info ((t (:foreground ,dt-green :weight bold))))

    ;; cua's rectangle mode
    `(cua-rectangle ((t (:background ,dt-blue-1))))


    ;; eno
    `(eno-hint-face ((t (:foreground ,dt-blue :background ,dt-bg-4
                          :weight bold))))

    ;; erc
    `(erc-action-face ((t (:foreground ,dt-red :slant italic))))
    '(erc-bold-face ((t (:weight bold))))
    `(erc-button ((t (:foreground ,dt-blue :background nil :underline t))))
    `(erc-current-nick-face ((t (:foreground ,dt-yellow))))
    '(erc-dangerous-host-face ((t (:inherit font-lock-warning))))
    '(erc-direct-msg-face ((t (:inherit erc-default))))
    '(erc-error-face ((t (:inherit font-lock-warning))))
    `(erc-fool-face ((t (:foreground ,dt-red))))
    '(erc-highlight-face ((t (:inherit highlight))))
    `(erc-keyword-face ((t (:foreground ,dt-red :weight bold))))
    `(erc-my-nick-face ((t (:foreground ,dt-red :weight bold))))
    `(erc-nick-default-face ((t (:foreground ,dt-blue))))
    `(erc-nick-msg-face ((t (:foreground ,dt-yellow))))
    `(erc-notice-face ((t (:foreground ,dt-green))))
    `(erc-pal-face ((t (:foreground ,dt-blue))))
    `(erc-prompt-face ((t (:weight bold :foreground ,dt-yellow))))
    `(erc-timestamp-face ((t (:foreground ,dt-green))))
    `(erc-input-face ((t (:foreground ,dt-yellow))))

    ;; flymake
    `(flymake-error ((t (:background ,dt-bg-4
                          :underline (:color ,dt-red :style wave)))))
    ;; flyspell
    ;; wavy underlines, emacs 24.3+
    `(flyspell-incorrect ((t (:foreground ,dt-yellow
                               :underline (:color ,dt-red :style wave)))))

    ;; font-locking (ie., syntax highlighting)
    `(font-lock-builtin-face ((t (:foreground ,dt-blue
                                   :slant italic :weight bold))))
    `(font-lock-comment-face    ((t (:foreground ,dt-bg-4 :slant italic))))
    `(font-lock-comment-delimiter-face ((t (:foreground ,dt-bg-4))))
    `(font-lock-constant-face   ((t (:foreground ,dt-green :weight bold))))
    `(font-lock-doc-face        ((t (:foreground ,dt-bg-4 :slant italic))))
    `(font-lock-doc-string-face ((t (:foreground ,dt-bg-4 :slant italic))))
    `(font-lock-function-name-face ((t (:foreground ,dt-green))))
    `(font-lock-keyword-face ((t (:foreground ,dt-red :weight bold))))
    `(font-lock-negation-char-face ((t (:foreground ,dt-green))))
    `(font-lock-preprocessor-face ((t (:foreground ,dt-magenta :weight bold
                                        :underline t))))
    `(font-lock-string-face ((t (:foreground ,dt-blue-1))))
    `(font-lock-type-face ((t (:foreground ,dt-blue-1))))
    `(font-lock-variable-name-face ((t (:foreground ,dt-yellow))))
    `(font-lock-warning-face ((t (:foreground ,dt-yellow :weight bold
                                   :slant normal :underline t))))
    `(font-lock-pseudo-keyword-face ((t (:foreground ,dt-red :weight bold))))
    `(font-lock-operator-face ((t (:foreground ,dt-blue-1))))

    `(git-gutter:modified ((t (:foreground ,dt-bg-1 :background ,dt-orange :weight bold))))
    `(git-gutter:added ((t (:foreground ,dt-bg-1 :background ,dt-green :weight bold))))
    `(git-gutter:deleted ((t (:foreground ,dt-bg-1 :background ,dt-red :weight bold))))

    `(gnus-cite-1  ((t (:foreground ,dt-blue-1))))
    `(gnus-cite-2  ((t (:foreground ,dt-green))))
    `(gnus-cite-3  ((t (:foreground ,dt-magenta))))
    `(gnus-cite-4  ((t (:foreground ,dt-blue))))
    `(gnus-cite-5  ((t (:foreground ,dt-orange))))
    `(gnus-cite-6  ((t (:foreground ,dt-blue-1))))
    `(gnus-cite-7  ((t (:foreground ,dt-green))))
    `(gnus-cite-8  ((t (:foreground ,dt-magenta))))
    `(gnus-cite-9  ((t (:foreground ,dt-blue))))
    `(gnus-cite-10 ((t (:foreground ,dt-orange))))
    `(gnus-header-name ((t (:foreground ,dt-blue :weight bold))))

    ;; helm
    `(helm-source-header ((t (:foreground ,dt-blue :background ,dt-bg-2))))
    `(helm-visible-mark ((t (:foreground ,dt-green  :background ,dt-bg-2))))
    `(helm-header ((t (:foreground ,dt-yellow  :background ,dt-bg-2))))
    `(helm-candidate-number ((t (:foreground ,dt-blue  :background ,dt-bg-2))))

    `(helm-selection ((t (:foreground ,dt-blue :underline t
                           :background ,dt-bg-1))))
    `(helm-separator ((t (:foreground ,dt-cyan :background ,dt-bg-2))))
    `(helm-action ((t (:foreground ,dt-blue :background ,dt-bg-2))))
    `(helm-prefarg ((t (:foreground ,dt-green :background ,dt-bg-2))))
    `(helm-match ((t (:foreground ,dt-orange :background ,dt-bg-2))))

    ;; highlight doxygen
    `(highlight-doxygen-comment ((t (:inherit font-lock-doc-face :background nil))))
    `(highlight-doxygen-code-block ((t (:inherit font-lock-doc-face :background nil))))

    ;; hlline
    `(hl-line ((t (:foreground nil :background ,dt-bg-7))))

    ;; info
    `(info-xref ((t (:foreground ,dt-yellow :weight bold))))
    '(info-xref-visited ((t (:inherit info-xref :weight normal))))
    '(info-header-xref ((t (:inherit info-xref))))
    `(info-menu-star ((t (:foreground ,dt-orange :weight normal))))
    `(info-menu-5 ((t (:inherit info-menu-star))))
    `(info-title-1 ((t (:foreground ,dt-blue :background nil
                         :weight bold :height 1.2))))
    `(info-title-2 ((t (:foreground ,dt-blue :background nil
                         :weight bold :height 1.1))))
    `(info-menu-header ((t (:weight normal :foreground ,dt-blue :height 1.2))))
    '(info-node ((t (:weight bold))))
    '(info-header-node ((t (:weight normal))))

    ;; isearch
    `(isearch ((t (:background ,dt-bg-hl-2 :underline t))))
    `(lazy-highlight ((t (:background ,dt-bg-hl-2))))

    ;; magit
    `(magit-section-title ((t (:foreground ,dt-red :height 1.1
                                :weight normal))))
    `(magit-item-highlight ((t (:foreground ,dt-blue
                                 :background ,dt-bg-1 :underline t))))
    `(magit-branch ((t (:foreground ,dt-green :background ,dt-bg-1 :box nil))))
    `(magit-log-sha1 ((t (:foreground ,dt-yellow
                           :background ,dt-bg-1 :box nil))))

    ;; message-mode
    `(message-cited-text-face ((t (:inherit font-lock-comment))))
    `(message-header-name-face ((t (:foregrond ,dt-blue :weight bold))))
    `(message-header-name ((t (:foregrond ,dt-blue :weight bold))))
    `(message-header-key-face ((t (:foregrond ,dt-green :weight bold))))
    `(message-header-other-face ((t (:foreground ,dt-green))))
    `(message-header-to-face ((t (:foreground ,dt-green))))
    `(message-header-from-face ((t (:foreground ,dt-green))))
    `(message-header-cc-face ((t (:foreground ,dt-green))))
    `(message-header-newsgroups-face ((t (:foreground ,dt-blue))))
    `(message-header-subject-face ((t (:foreground ,dt-red))))
    `(message-header-xheader-face ((t (:foreground ,dt-green))))
    `(message-mml-face ((t (:foreground ,dt-blue-1))))
    `(message-separator-face ((t (:foreground ,dt-green :background ,dt-bg-4))))


    ;; linum
    `(linum ((t (:foreground ,dt-green :background ,dt-bg-4
                  :height .65 :weight normal :slant normal :underline nil))))
    `(line-number ((t (:foreground ,dt-bg-5 :background ,dt-bg-1
                                   :height .75 :weight normal
                                   :slant normal :underline nil))))
    `(line-number-current-line ((t (:foreground ,dt-fg :background ,dt-bg-1
                                                :height .75 :weight bold
                                                :slant normal :underline t))))
    `(line-number-minor-tick ((t (:foreground ,dt-blue :background ,dt-bg-1
                                              :height .75 :weight normal
                                              :slant normal :underline nil))))
    `(line-number-major-tick ((t (:foreground ,dt-blue-1 :background ,dt-bg-1
                                              :height .75 :weight normal
                                              :slant normal :underline nil))))



    ;; one-keyq
    `(one-key-name ((t (:foreground ,dt-yellow))))
    `(one-key-keystroke ((t (:foreground ,dt-red))))
    `(one-key-prompt ((t (:foreground ,dt-green))))

    ;; org-mode
    `(org-code ((t (:foreground ,dt-blue-1))))

    ;; `(org-level-4 ((t (:inherit org-level-4 :height 1.1))))
    ;; `(org-level-3 ((t (:inherit org-level-3 :height 1.2))))
    ;; `(org-level-2 ((t (:inherit org-level-2 :height 1.3))))
    ;; `(org-level-1 ((t (:inherit org-level-1 :height 1.4))))
    ;; `(org-document-title ((t (:inherit org-document-title
    ;;                         :height 1.5 :underline nil))))

    ;; rainbow-delimiters
    `(rainbow-delimiters-depth-1-face  ((t (:foreground ,dt-cyan))))
    `(rainbow-delimiters-depth-2-face  ((t (:foreground ,dt-yellow))))
    `(rainbow-delimiters-depth-3-face  ((t (:foreground ,dt-blue-1))))
    `(rainbow-delimiters-depth-4-face  ((t (:foreground ,dt-red))))
    `(rainbow-delimiters-depth-5-face  ((t (:foreground ,dt-green))))
    `(rainbow-delimiters-depth-6-face  ((t (:foreground ,dt-blue-1))))
    `(rainbow-delimiters-depth-7-face  ((t (:foreground ,dt-orange))))
    `(rainbow-delimiters-depth-8-face  ((t (:foreground ,dt-magenta))))
    `(rainbow-delimiters-depth-9-face  ((t (:foreground ,dt-yellow))))
    `(rainbow-delimiters-depth-10-face ((t (:foreground ,dt-green))))
    `(rainbow-delimiters-depth-11-face ((t (:foreground ,dt-blue-1))))
    `(rainbow-delimiters-depth-12-face ((t (:foreground ,dt-red))))
    `(rainbow-delimiters-unmatched-face
       ((t (:foreground ,dt-red :background ,dt-yellow
             :weight bold))))

    ;; show-paren
    `(show-paren-mismatch ((t (:foreground ,dt-cyan :background ,dt-green
                                :weight bold :underline t))))
    `(show-paren-match ((t (:foreground ,nil :background ,dt-bg-1
                             :underline t :weight normal))))

    ;; sunrise commander
    `(sr-active-path-face ((t (:foreground ,dt-blue :background ,dt-bg-4
                                :height 1.0 :weight bold :underline t))))
    `(sr-passive-path-face ((t (:foreground ,dt-blue
                                 :height 1.0 :weight normal :underline t))))

    ;; swoop
    `(swoop-face-target-words ((t (:background ,dt-bg-4))))
    `(swoop-face-target-line ((t (:foreground ,dt-bg-4))))
    `(swoop-face-line-buffer-name ((t (:foreground ,dt-bg-4))))

    ;; which-function mode
    `(which-func ((t (:foreground ,dt-yellow))))

    ;; whitespace-mode
    ;; (whitespace-space       ((t (:background ,dt-bg-1))))
    `(whitespace-indentation   ((t (:background ,dt-bg-2))))
    `(whitespace-empty         ((t (:foreground ,dt-green :background ,dt-bg-1))))
    `(whitespace-trailing      ((t (:background ,dt-red))))

    ;; `(whitespace-tab         ((t (:background ,dt-bg-4))))
    ;; '(trailing-whitespace ((t (:inherit font-lock-warning))))
    ))

(provide-theme 'dream)
(provide 'dream-theme)
;;; dream-theme.el ends here
