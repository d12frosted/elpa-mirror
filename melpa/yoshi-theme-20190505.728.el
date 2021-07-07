;;; yoshi-theme.el --- Theme named after my cat

;; Copyright (C) 2012, 2013, 2014, 2015  Tom Willemsen

;; Author: Tom Willemse <tom@ryuslash.org>
;; Keywords: faces
;; Package-Version: 20190505.728
;; Package-Commit: 70365870ff823b954aa85972217d8f116c45d939
;; Version: 6.2.0
;; URL: http://projects.ryuslash.org/yoshi-theme/

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

;; Just a theme named after my cat.  He doesn't actually look like
;; this.

;;; Code:

(require 'color)

(deftheme yoshi
  "Created 2012-09-24")

(let ((bgdefault   "#111414") (fgdefault   "#bfbfbf")
      (bgbright    "#3d3d3d") (fgbright    "#ededed")
      (bgdim       "#222222") (fgdim       "#969696")
      (bgred       "#3f1a1a") (fgred       "#a85454")
      (bgorange    "#3f321f") (fgorange    "#a88654")
      (bgyellow    "#343922") (fgyellow    "#8d995c")
      (bggreen     "#263f1f") (fggreen     "#65a854")
      (bgturquoise "#1f3f2c") (fgturquoise "#54a875")
      (bgcyan      "#1f3f3f") (fgcyan      "#54a8a8")
      (bgblue      "#1f2c3f") (fgblue      "#5476a8")
      (bgpurple    "#2f2a3f") (fgpurple    "#7d71a8")
      (bgmagenta   "#381f3f") (fgmagenta   "#9754a8")
      (bgpink      "#3f1f32") (fgpink      "#a85487"))
  (custom-theme-set-faces
   'yoshi

   ;;; General
   `(default ((t (:background ,bgdefault :foreground ,fgdefault))))
   `(cursor ((t (:background ,fgdim))))
   `(error ((t (:foreground ,fgred :weight bold))))
   `(font-lock-builtin-face ((t (:foreground ,fgcyan))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,fgdim :inherit unspecified))))
   `(font-lock-comment-face ((t (:foreground ,fgpink))))
   `(font-lock-constant-face ((t (:foreground ,fgred))))
   `(font-lock-doc-face ((t (:foreground ,fggreen :inherit unspecified))))
   `(font-lock-function-name-face ((t (:foreground ,fgblue))))
   `(font-lock-keyword-face ((t (:foreground ,fgorange))))
   `(font-lock-negation-char-face ((t (:foreground ,fgred))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,fgred))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,fgpink))))
   `(font-lock-string-face ((t (:foreground ,fgturquoise))))
   `(font-lock-type-face ((t (:foreground ,fgpurple))))
   `(font-lock-variable-name-face ((t (:foreground ,fgyellow))))
   `(font-lock-warning-face ((t (:foreground ,fgorange :inherit unspecified :weight bold))))
   `(fringe ((t (:background unspecified :inherit default))))
   `(header-line ((t (:background ,bgblue :foreground ,fgbright :box (:color ,bgblue :line-width 5 :style nil)))))
   `(highlight ((t (:background ,bgcyan))))
   `(italic ((t (:slant italic))))
   `(link ((t (:foreground ,fgorange :underline t))))
   `(link-visited ((t (:foreground ,fgmagenta :underline t))))
   `(minibuffer-prompt ((t (:foreground ,fgblue))))
   `(mode-line ((t (:background ,bgblue :foreground ,fgbright :box (:color ,bgblue :line-width 5 :style nil)))))
   `(mode-line-buffer-id ((t (:foreground ,fggreen :weight bold))))
   `(mode-line-inactive ((t (:weight normal :background ,bgbright :foreground ,fgdefault :box (:color ,bgbright :line-width 5 :style nil) :inherit unspecified))))
   `(region ((t (:background ,bgblue))))
   `(shadow ((t (:foreground ,fgdim))))
   `(success ((t (:foreground ,fggreen :weight bold))))
   `(trailing-whitespace ((t (:background ,fgred))))
   `(warning ((t (:foreground ,fgorange :weight unspecified))))

   ;;; Circe
   `(circe-highlight-nick-face ((t (:foreground ,fgred :weight bold))))
   `(circe-server-face ((t (:foreground ,fgdim))))
   `(lui-button-face ((t (:foreground unspecified :underline unspecified :inherit button))))
   `(lui-time-stamp-face ((t (:foreground ,fggreen :weight unspecified))))

   ;;; Company
   `(company-preview ((t (:background unspecified :foreground ,fgdim))))
   `(company-preview-common ((t (:foreground ,bgcyan :inherit unspecified :weight bold))))
   `(company-scrollbar-bg ((t (:background ,bgdim))))
   `(company-scrollbar-fg ((t (:background ,bgbright))))
   `(company-tooltip ((t (:foreground ,fgdefault :background ,bgdim))))
   `(company-tooltip-annotation ((t (:foreground ,fgblue))))
   `(company-tooltip-common ((t (:foreground ,fgcyan))))
   `(company-tooltip-search ((t (:background ,bgyellow :inherit unspecified))))
   `(company-tooltip-search-selection ((t (:background ,bgyellow :inherit unspecified))))
   `(company-tooltip-selection ((t (:background ,bgblue))))

   ;;; Compilation
   `(compilation-info ((t (:foreground ,fgblue :inherit unspecified))))

   ;;; CSS
   `(css-property ((t (:foreground ,fgorange))))
   `(css-proprietary-property ((t (:foreground ,fgred :inherit unspecified :slant italic))))
   `(css-selector ((t (:foreground ,fgblue))))

   ;;; Diff
   `(diff-added ((t (:background ,bggreen :inherit unspecified))))
   `(diff-changed ((t (:background ,bgorange))))
   `(diff-file-header ((t (:foreground ,fgbright :background unspecified :weight bold))))
   `(diff-function ((t (:inherit unspecified :foreground ,fgorange))))
   `(diff-header ((t (:background ,bgbright))))
   `(diff-hl-change ((t (:foreground ,bgyellow :background unspecified :inherit diff-changed))))
   `(diff-hl-delete ((t (:foreground ,bgred :inherit diff-removed))))
   `(diff-hl-insert ((t (:foreground ,bggreen :inherit diff-added))))
   `(diff-hunk-header ((t (:inherit unspecified :weight bold :foreground ,fgyellow :underline t))))
   `(diff-indicator-added ((t (:foreground ,fggreen :weight bold :inherit unspecified))))
   `(diff-indicator-changed ((t (:foreground ,fgyellow :weight bold :inherit unspecified ))))
   `(diff-indicator-removed ((t (:foreground ,fgred :weight bold :inherit unspecified))))
   `(diff-refine-added ((t (:foreground ,fggreen :background unspecified :inherit unspecified))))
   `(diff-refine-change ((t (:foreground ,fgyellow :background unspecified))))
   `(diff-refine-removed ((t (:foreground ,fgred :background unspecified :inherit unspecified))))
   `(diff-removed ((t (:background ,bgred :inherit unspecified))))

   ;;; Dired
   `(dired-flagged ((t (:inherit region))))
   `(dired-header ((t (:foreground ,fgturquoise :weight bold :inherit unspecified))))
   `(dired-mark ((t (:foreground ,fgpink :inherit unspecified))))
   `(dired-marked ((t (:background ,bgpink :inherit unspecified))))

   ;;; Ediff
   `(ediff-current-diff-A ((t (:inherit diff-removed))))
   `(ediff-current-diff-B ((t (:inherit diff-added))))
   `(ediff-current-diff-C ((t (:inherit diff-changed))))
   `(ediff-fine-diff-A ((t (:inherit diff-refine-removed))))
   `(ediff-fine-diff-B ((t (:inherit diff-refine-added))))
   `(ediff-fine-diff-C ((t (:inherit diff-refine-change))))

   ;;; ERC
   `(erc-button ((t (:weight unspecified :inherit button))))
   `(erc-current-nick-face ((t (:foreground ,fgred :weight bold))))
   `(erc-input-face ((t (:inherit shadow))))
   `(erc-my-nick-face ((t (:inherit erc-current-nick-face))))
   `(erc-notice-face ((t (:foreground ,fgblue :weight normal))))
   `(erc-prompt-face ((t (:foreground ,fgbright :weight bold))))
   `(erc-timestamp-face ((t (:foreground ,fgdim :weight normal))))

   ;;; ERT
   `(ert-test-result-expected ((t (:background unspecified :foreground ,fggreen))))
   `(ert-test-result-unexpected ((t (:background unspecified :foreground ,fgred))))

   ;;; Eshell
   `(eshell-fringe-status-failure ((t (:foreground ,fgred))))
   `(eshell-fringe-status-success ((t (:foreground ,fggreen))))
   `(eshell-ls-archive ((t (:foreground ,fgpink :weight unspecified))))
   `(eshell-ls-backup ((t (:foreground ,fgorange))))
   `(eshell-ls-clutter ((t (:foreground ,fgdim :weight unspecified))))
   `(eshell-ls-directory ((t (:foreground ,fgblue :weight unspecified))))
   `(eshell-ls-executable ((t (:foreground ,fggreen :weight unspecified))))
   `(eshell-ls-missing ((t (:foreground ,fgred :weight bold))))
   `(eshell-ls-product ((t (:foreground ,fgpurple))))
   `(eshell-ls-readonly ((t (:foreground ,fgmagenta))))
   `(eshell-ls-special ((t (:foreground ,fgturquoise))))
   `(eshell-ls-symlink ((t (:foreground ,fgcyan :weight unspecified))))
   `(eshell-ls-unreadable ((t (:foreground ,fgred))))
   `(eshell-prompt ((t (:foreground ,fgbright :weight unspecified))))

   ;;; Flycheck
   `(flycheck-error ((t (:inherit unspecified :underline (:color ,fgred :style wave)))))
   `(flycheck-warning ((t (:inherit unspecified :underline (:color ,fgorange :style wave)))))

   ;;; Flycheck inline
   `(flycheck-inline-error ((t (:inherit unspecified :foreground ,fgred :height 0.8))))
   `(flycheck-inline-info ((t (:inherit unspecified :foreground ,fgblue :height 0.8))))
   `(flycheck-inline-warning ((t (:inherit unspecified :foreground ,fgorange :height 0.8))))

   ;;; Flymake
   `(flymake-errline ((t (:background unspecified :underline (:color ,fgred :style wave)))))
   `(flymake-infoline ((t (:background unspecified :underline (:color ,fgblue :style wave)))))
   `(flymake-warnline ((t (:background unspecified :underline (:color ,fgorange :style wave)))))

   ;;; Flyspell
   `(flyspell-duplicate ((t (:inherit unspecified :underline (:color ,fgorange :style wave)))))
   `(flyspell-incorrect ((t (:inherit unspecified :underline (:color ,fgred :style wave)))))

   ;;; Gnus
   `(gnus-button ((t (:weight bold))))
   `(gnus-cite-1 ((t (:foreground ,fgred))))
   `(gnus-cite-10 ((t (:foreground ,fgpink))))
   `(gnus-cite-11 ((t (:foreground ,fgbright))))
   `(gnus-cite-2 ((t (:foreground ,fgorange))))
   `(gnus-cite-3 ((t (:foreground ,fgyellow))))
   `(gnus-cite-4 ((t (:foreground ,fggreen))))
   `(gnus-cite-5 ((t (:foreground ,fgturquoise))))
   `(gnus-cite-6 ((t (:foreground ,fgcyan))))
   `(gnus-cite-7 ((t (:foreground ,fgblue))))
   `(gnus-cite-8 ((t (:foreground ,fgpurple))))
   `(gnus-cite-9 ((t (:foreground ,fgmagenta))))
   `(gnus-group-mail-3 ((t (:foreground ,fgcyan :weight bold))))
   `(gnus-group-mail-3-empty ((t (:foreground ,fgcyan))))
   `(gnus-group-news-3 ((t (:foreground ,fgred :weight bold))))
   `(gnus-group-news-3-empty ((t (:foreground ,fgred))))
   `(gnus-header-content ((t (:foreground ,fgdim :slant italic))))
   `(gnus-header-from ((t (:weight bold))))
   `(gnus-header-name ((t (:foreground ,fgblue :weight bold))))
   `(gnus-header-newsgroups ((t (:foreground ,fgbright :weight bold))))
   `(gnus-header-subject ((t (:foreground ,fgyellow))))
   `(gnus-signature ((t (:foreground ,fgdim :slant italic))))
   `(gnus-splash ((t (:foreground ,fgdefault))))
   `(gnus-summary-cancelled ((t (:foreground ,fgdim :background unspecified :strike-through t))))
   `(gnus-summary-high-ancient ((t (:inherit gnus-summary-normal-ancient :weight bold))))
   `(gnus-summary-high-read ((t (:inherit gnus-summary-normal-read :weight bold))))
   `(gnus-summary-high-ticked ((t (:inherit gnus-summary-normal-ticked :weight bold))))
   `(gnus-summary-high-unread ((t (:foreground ,fgpink))))
   `(gnus-summary-low-ancient ((t (:inherit gnus-summary-normal-ancient :slant italic))))
   `(gnus-summary-low-read ((t (:inherit gnus-summary-normal-read :slant italic))))
   `(gnus-summary-low-ticked ((t (:inherit gnus-summary-normal-ticked :slant italic))))
   `(gnus-summary-low-unread ((t (:inherit gnus-summary-normal-unread :slant italic))))
   `(gnus-summary-normal-ancient ((t (:foreground ,fgcyan))))
   `(gnus-summary-normal-read ((t (:foreground ,fgdim))))
   `(gnus-summary-normal-ticked ((t (:foreground ,fgturquoise))))
   `(gnus-summary-normal-unread ((t (:foreground ,fgdefault))))
   `(gnus-summary-selected ((t (:background ,bgblue :weight bold))))

   ;;; Helm
   `(helm-M-x-key ((t (:underline unspecified :foreground ,fgpink :weight bold))))
   `(helm-buffer-directory ((t (:background unspecified :foreground ,fgblue))))
   `(helm-buffer-file ((t (:inherit default))))
   `(helm-buffer-not-saved ((t (:foreground ,fgcyan))))
   `(helm-buffer-process ((t (:foreground ,fggreen))))
   `(helm-buffer-size ((t (:foreground ,fgorange))))
   `(helm-ff-directory ((t (:foreground ,fgblue :background unspecified))))
   `(helm-ff-dotted-directory ((t (:foreground unspecified :background unspecified :inherit helm-ff-directory))))
   `(helm-ff-executable ((t (:foreground ,fggreen))))
   `(helm-ff-file ((t (:inherit default))))
   `(helm-ff-invalid-symlink ((t (:foreground ,fgred :background unspecified))))
   `(helm-ff-symlink ((t (:foreground ,fgcyan))))
   `(helm-match ((t (:foreground ,fgbright :weight bold))))
   `(helm-selection ((t (:distant-foreground unspecified :background ,bgblue))))
   `(helm-source-header ((t (:font-family unspecified :height 1.1 :weight bold :foreground ,fgturquoise :background unspecified))))

   ;;; Highlight 80+
   `(highlight-80+ ((t (:underline (:color ,fgred :style wave) :background unspecified))))

   ;;; Highlight numbers
   `(highlight-numbers-number ((t (:foreground ,fgcyan :inherit unspecified))))

   ;;; Highlight indent
   `(hl-indent-block-face-1 ((t (:background ,bgred))))
   `(hl-indent-block-face-2 ((t (:background ,bgpink))))
   `(hl-indent-block-face-3 ((t (:background ,bgorange))))
   `(hl-indent-block-face-4 ((t (:background ,bgyellow))))
   `(hl-indent-block-face-5 ((t (:background ,bggreen))))
   `(hl-indent-block-face-6 ((t (:background ,bgturquoise))))
   `(hl-indent-face ((t (:inherit unspecified :background ,bgdim))))

   ;;; Highlight indent guides
   `(highlight-indent-guides-character-face ((t (:inherit unspecified :foreground ,bgbright))))

   ;;; Hydra
   `(hydra-face-amaranth ((t (:foreground ,fgorange :weight bold))))
   `(hydra-face-blue ((t (:foreground ,fgblue :weight bold))))
   `(hydra-face-pink ((t (:foreground ,fgpink :weight bold))))
   `(hydra-face-red ((t (:foreground ,fgred :weight bold))))
   `(hydra-face-teal ((t (:foreground ,fgcyan :weight bold))))

   ;;; Identica
   `(identica-stripe-face ((t (:background ,bgbright))))
   `(identica-uri-face ((t (:foreground ,fgorange :underline t))))
   `(identica-username-face ((t (:foreground ,fgblue :weight bold :underline unspecified))))

   ;;; Ido
   `(ido-subdir ((t (:foreground ,fgred))))

   ;;; Isearch
   `(isearch ((t (:background ,bgyellow :foreground unspecified))))
   `(isearch-fail ((t (:background ,bgred))))

   ;;; Ivy
   `(ivy-current-match ((t (:background ,bgblue :foreground ,fgdefault))))
   `(ivy-minibuffer-match-face-1 ((t (:background unspecified :underline t))))
   `(ivy-minibuffer-match-face-2 ((t (:background unspecified :weight bold))))
   `(ivy-minibuffer-match-face-3 ((t (:background unspecified :weight bold))))
   `(ivy-minibuffer-match-face-4 ((t (:background unspecified :weight bold))))

   ;;; Jabber
   `(jabber-activity-face ((t (:foreground ,fgred :weight unspecified))))
   `(jabber-activity-personal-face ((t (:foreground ,fgblue :weight unspecified))))
   `(jabber-chat-error ((t (:foreground ,fgred :weight bold))))
   `(jabber-chat-prompt-foreign ((t (:foreground ,fgred :slant italic))))
   `(jabber-chat-prompt-local ((t (:foreground ,fgblue :slant italic))))
   `(jabber-chat-prompt-system ((t (:foreground ,fggreen :slant italic))))
   `(jabber-rare-time-face ((t (:foreground ,fgdefault :underline t))))
   `(jabber-roster-user-away ((t (:foreground ,fggreen :slant italic))))
   `(jabber-roster-user-chatty ((t (:foreground ,fgpink))))
   `(jabber-roster-user-dnd ((t (:foreground ,fgred :weight unspecified :slant unspecified))))
   `(jabber-roster-user-error ((t (:foreground ,fgred :slant unspecified :weight bold))))
   `(jabber-roster-user-offline ((t (:foreground ,fgdim :slant italic))))
   `(jabber-roster-user-online ((t (:foreground ,fgblue))))
   `(jabber-roster-user-xa ((t (:foreground ,fgmagenta))))

   ;;; JS2 mode
   `(js2-error ((t (:foreground unspecified :inherit error))))
   `(js2-external-variable ((t (:foreground ,fgmagenta))))
   `(js2-function-call ((t (:inherit font-lock-function-name-face))))
   `(js2-function-param ((t (:foreground unspecified :inherit font-lock-variable-name-face))))
   `(js2-object-property ((t (:inherit font-lock-variable-name-face))))
   `(js2-warning ((t (:underline unspecified :inherit font-lock-warning-face))))

   ;;; Magit
   `(magit-bisect-bad ((t (:foreground ,fgred))))
   `(magit-bisect-good ((t (:foreground ,fggreen))))
   `(magit-bisect-skip ((t (:foreground ,fgdim))))
   `(magit-blame-date ((t (:foreground ,fgpink :inherit magit-blame-heading))))
   `(magit-blame-hash ((t (:foreground ,fgmagenta :inherit magit-blame-heading))))
   `(magit-blame-header ((t (:foreground ,fggreen :background ,bgdim :weight bold :inherit unspecified))))
   `(magit-blame-heading ((t (:foreground ,fgdefault :background ,bgbright))))
   `(magit-blame-name ((t (:foreground ,fgturquoise :inherit magit-blame-heading))))
   `(magit-blame-summary ((t (:foreground ,fggreen :inherit magit-blame-heading))))
   `(magit-branch ((t (:foreground ,fgpink :weight bold :inherit unspecified))))
   `(magit-branch-current ((t (:foreground ,fgdefault :background ,bgblue :box (:color ,bgblue :line-width 2 :style nil) :inherit unspecified))))
   `(magit-branch-local ((t (:foreground ,fgdefault :background ,bgmagenta :box (:color ,bgmagenta :line-width 2 :style nil)))))
   `(magit-branch-remote ((t (:foreground ,fgdefault :background ,bggreen :box (:color ,bggreen :line-width 2 :style nil)))))
   `(magit-diff-added ((t (:foreground unspecified :background unspecified :inherit diff-added))))
   `(magit-diff-added-highlight ((t (:foreground unspecified :background unspecified :inherit magit-diff-added))))
   `(magit-diff-context ((t (:foreground unspecified :inherit shadow))))
   `(magit-diff-context-highlight ((t (:foreground unspecified :background ,bgdim :inherit magit-diff-context))))
   `(magit-diff-file-heading ((t (:foreground unspecified :underline unspecified :inherit diff-file-header))))
   `(magit-diff-removed ((t (:foreground unspecified :background unspecified :inherit diff-removed))))
   `(magit-diff-removed-highlight ((t (:foreground unspecified :background unspecified :inherit magit-diff-removed))))
   `(magit-item-highlight ((t (:slant italic  :inherit unspecified))))
   `(magit-log-head-label-default ((t (:foreground ,fgdefault :background ,bgcyan :box (:color ,bgcyan :line-width 2 :style nil)))))
   `(magit-log-head-label-head ((t (:foreground ,fgdefault :background ,bgblue :box (:color ,bgblue :line-width 2 :style nil)))))
   `(magit-log-head-label-local ((t (:foreground ,fgdefault :background ,bgmagenta :box (:color ,bgmagenta :line-width 2 :style nil)))))
   `(magit-log-head-label-remote ((t (:foreground ,fgdefault :background ,bggreen :box (:color ,bggreen :line-width 2 :style nil)))))
   `(magit-log-head-label-tags ((t (:foreground ,fgdefault :background ,bgorange :box (:color ,bgorange :line-width 2 :style nil)))))
   `(magit-log-sha1 ((t (:foreground ,fgdefault :background ,bgblue :box (:color ,bgblue :line-width 2 :style nil)))))
   `(magit-process-ng ((t (:foreground ,fgred :inherit unspecified))))
   `(magit-process-ok ((t (:foreground ,fggreen :inherit unspecified))))
   `(magit-section-heading ((t (:foreground ,fgturquoise :weight unspecified :height 1.3))))
   `(magit-section-highlight ((t (:background unspecified :slant italic))))
   `(magit-section-title ((t (:foreground ,fgturquoise :inherit unspecified :height 1.8))))

   ;;; Makefile
   `(makefile-space ((t (:background ,bgpink))))

   ;;; Markdown
   `(markdown-header-face-1 ((t (:foreground ,fggreen :inherit unspecified))))
   `(markdown-header-face-2 ((t (:foreground ,fgcyan :inherit unspecified))))
   `(markdown-header-face-3 ((t (:foreground ,fgred :inherit unspecified))))
   `(markdown-header-face-4 ((t (:foreground ,fgblue :inherit unspecified))))
   `(markdown-header-face-5 ((t (:foreground ,fgyellow :inherit unspecified))))
   `(markdown-header-face-6 ((t (:foreground ,fgpurple :inherit unspecified))))

   ;;; Message mode
   `(message-header-cc ((t (:foreground ,fgdim))))
   `(message-header-name ((t (:inherit gnus-header-name))))
   `(message-header-newsgroups ((t (:foreground ,fgdim :weight bold))))
   `(message-header-other ((t (:inherit gnus-header-content))))
   `(message-header-subject ((t (:inherit gnus-header-subject))))
   `(message-header-to ((t (:foreground ,fgdim :weight bold))))
   `(message-header-xheader ((t (:foreground ,fgdim :slant italic))))
   `(message-mml ((t (:foreground ,fggreen))))
   `(message-separator ((t (:foreground ,fgblue))))

   ;;; Org
   `(org-agenda-calendar-sexp ((t (:foreground ,fgyellow))))
   `(org-agenda-current-time ((t (:foreground ,fgorange :weight bold))))
   `(org-agenda-date ((t (:foreground ,bgcyan))))
   `(org-agenda-date-today ((t (:foreground ,fgcyan :slant italic))))
   `(org-agenda-date-weekend ((t (:foreground ,fgcyan))))
   `(org-agenda-done ((t (:foreground ,fgorange))))
   `(org-agenda-structure ((t (:foreground ,fgblue))))
   `(org-block-background ((t (:background ,bgdim))))
   `(org-block-begin-line ((t (:foreground ,fgdefault :slant unspecified :underline ,fgdim))))
   `(org-block-end-line ((t (:foreground ,fgdefault :slant unspecified :overline ,fgdim))))
   `(org-checkbox-statistics-done ((t (:foreground ,bgcyan))))
   `(org-checkbox-statistics-todo ((t (:foreground ,fgcyan))))
   `(org-date ((t (:foreground ,fgpink :underline unspecified))))
   `(org-document-title ((t (:foreground ,fgorange :height 1.5))))
   `(org-headline-done ((t (:foreground ,fgdim))))
   `(org-level-1 ((t (:foreground ,fggreen :underline t :height 1.2))))
   `(org-level-2 ((t (:foreground ,fgcyan :weight bold :height 1.1))))
   `(org-level-3 ((t (:foreground ,fgred :slant italic))))
   `(org-level-4 ((t (:foreground ,fgblue))))
   `(org-level-5 ((t (:foreground ,fgyellow))))
   `(org-level-6 ((t (:foreground ,fgpurple))))
   `(org-level-7 ((t (:foreground ,fgturquoise))))
   `(org-level-8 ((t (:foreground ,fgorange))))
   `(org-scheduled ((t (:foreground ,fgdim))))
   `(org-scheduled-previously ((t (:weight bold))))
   `(org-scheduled-today ((t (:foreground ,fgdefault))))
   `(org-time-grid ((t (:foreground ,fgorange))))

   ;;; Outline
   `(outline-1 ((t (:inherit org-level-1))))
   `(outline-2 ((t (:inherit org-level-2))))
   `(outline-3 ((t (:inherit org-level-3))))
   `(outline-4 ((t (:inherit org-level-4))))
   `(outline-5 ((t (:inherit org-level-5))))
   `(outline-6 ((t (:inherit org-level-6))))
   `(outline-7 ((t (:inherit org-level-7))))
   `(outline-8 ((t (:inherit org-level-8))))

   ;;; Package
   `(package-status-avail-obso ((t (:foreground ,bggreen))))
   `(package-status-available ((t (:foreground ,fggreen))))
   `(package-status-dependency ((t (:foreground ,fgdim))))
   `(package-status-installed ((t (:foreground ,fgdefault))))

   ;;; Pretty-print ^L highlight
   `(pp^L-highlight ((t (:box unspecified :foreground ,fgbright))))

   ;;; Rainbow delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,fgred))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,fgorange))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,fgyellow))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,fggreen))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,fgturquoise))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,fgcyan))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,fgblue))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground ,fgpurple))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground ,fgmagenta))))
   `(rainbow-delimiters-unmatched-face ((t (:background ,bgred :foreground unspecified))))

   ;;; Rebase mode
   `(rebase-mode-description-face ((t (:foreground ,fgbright))))

   ;;; reStructuredText
   `(rst-level-1 ((t (:background unspecified))))
   `(rst-level-2 ((t (:background unspecified))))
   `(rst-level-3 ((t (:background unspecified))))
   `(rst-level-4 ((t (:background unspecified))))
   `(rst-level-5 ((t (:background unspecified))))
   `(rst-level-6 ((t (:background unspecified))))

   ;;; Sh
   `(sh-escaped-newline ((t (:foreground ,fgpurple :inherit unspecified :weight bold))))
   `(sh-heredoc ((t (:foreground ,fggreen))))
   `(sh-quoted-exec ((t (:foreground ,fgpink))))

   ;;; Show paren
   `(show-paren-match ((t (:inverse-video t))))
   `(show-paren-mismatch ((t (:background unspecified :foreground ,fgred))))

   ;;; Slime
   `(slime-repl-input-face ((t (:foreground ,fgbright))))
   `(slime-repl-inputed-output-face ((t (:foreground ,fgbright))))
   `(slime-repl-output-face ((t (:foreground ,fgdefault))))
   `(slime-repl-prompt-face ((t (:foreground ,fgblue))))

   ;;; Smerge
   `(smerge-base ((t (:background ,bggreen))))
   `(smerge-markers ((t (:background ,bgbright))))
   `(smerge-mine ((t (:background ,bgblue))))
   `(smerge-other ((t (:background ,bgred))))
   `(smerge-refined-added ((t (:inherit diff-refine-added))))
   `(smerge-refined-change ((t (:inherit diff-refine-change))))
   `(smerge-refined-removed ((t (:inherit diff-refine-removed))))

   ;;; Term
   `(term-color-black ((t (:background ,bgdefault :foreground ,fgbright))))
   `(term-color-blue ((t (:background ,bgblue :foreground ,fgblue))))
   `(term-color-cyan ((t (:background ,bgcyan :foreground ,fgcyan))))
   `(term-color-green ((t (:background ,bggreen :foreground ,fggreen))))
   `(term-color-magenta ((t (:background ,bgmagenta :foreground ,fgmagenta))))
   `(term-color-red ((t (:background ,bgred :foreground ,fgred))))
   `(term-color-white ((t (:background ,bgbright :foreground ,fgdefault))))
   `(term-color-yellow ((t (:background ,bgyellow :foreground ,fgyellow))))

   ;;; Texinfo
   `(texinfo-heading ((t (:foreground ,fgpink :inherit unspecified :height 1.3))))

   ;;; Which function mode
   `(which-func ((t (:foreground ,fgblue))))

   ;;; Whitespace mode
   `(whitespace-empty ((t (:background ,bgcyan :foreground ,fgdefault))))
   `(whitespace-hspace ((t (:background ,bgbright :foreground ,fgbright))))
   `(whitespace-indentation ((t (:background ,bgyellow :foreground unspecified))))
   `(whitespace-line ((t (:background ,bgred :foreground unspecified))))
   `(whitespace-newline ((t (:foreground ,fgpink))))
   `(whitespace-space ((t (:background unspecified :foreground ,fgpink))))
   `(whitespace-space-after-tab ((t (:background ,bgorange :foreground unspecified))))
   `(whitespace-space-before-tab ((t (:background ,bgorange :foreground unspecified))))
   `(whitespace-tab ((t (:background unspecified :underline ,bgbright))))
   `(whitespace-trailing ((t (:background ,bgorange :foreground unspecified))))

   ;;; Widget
   `(widget-button ((t (:inherit button))))
   `(widget-button-pressed ((t (:inherit widget-button :weight bold))))
   `(widget-documentation ((t (:inherit font-lock-doc-face))))
   `(widget-field ((t (:background ,bgblue :box (:color ,bgblue :line-width 2)))))

   ;;; rpm-spec-mode
   `(rpm-spec-tag-face ((t (:foreground ,fgblue))))
   `(rpm-spec-obsolete-tag-face ((t (:background ,bgred))))
   `(rpm-spec-macro-face ((t (:foreground ,fgyellow))))
   `(rpm-spec-var-face ((t (:foreground ,fgcyan))))
   `(rpm-spec-doc-face ((t (:foreground ,fgmagenta))))
   `(rpm-spec-dir-face ((t (:foreground ,fgturquoise))))
   `(rpm-spec-package-face ((t (:foreground ,fgred))))
   `(rpm-spec-ghost-face ((t (:foreground ,fgred))))
   `(rpm-spec-section-face ((t (:foreground ,fgyellow :underline t))))

   ;;; Window dividers
   `(window-divider ((t (:foreground ,bgbright))))
   `(window-divider-first-pixel ((t (:foreground unspecified :inherit window-divider))))
   `(window-divider-last-pixel ((t (:foreground unspecified :inherit window-divider))))
   )

  (custom-theme-set-variables
   'yoshi
   `(ansi-color-names-vector [,bgdim ,fgred ,fggreen ,fgyellow
                              ,fgblue ,fgmagenta ,fgcyan ,fgdim])
   `(fci-rule-color ,bgred)
   '(org-fontify-whole-heading-line t)
   '(window-divider-mode t)
   '(window-divider-default-right-width 1)))

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'yoshi)
;;; yoshi-theme.el ends here
