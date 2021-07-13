;;; yoshi-theme.el --- Theme named after my cat  -*- lexical-binding: t; -*-

;; Copyright (C) 2012, 2013, 2014, 2015, 2019, 2021  Tom Willemsen

;; Author: Tom Willemse <tom@ryuslash.org>
;; Keywords: faces
;; Package-Version: 20210713.455
;; Package-Commit: 06a6bcfc58d1f1cd8815c674c9fcbbf193bba0a9
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

(defun yoshi-theme-add-space-to-first-arg (args)
  "Return ARGS with the car modified to contain 2 spaces."
  (cons (format " %s " (car args)) (cdr args)))

(advice-add 'propertized-buffer-identification
            :filter-args #'yoshi-theme-add-space-to-first-arg)

(defun yoshi-theme--make-inline-box (border-color)
  "Return a list representing a box specification using BORDER-COLOR."
  (let ((line-width (if (> emacs-major-version 27)
                        '(5 . -1)
                      5)))
   `(:line-width ,line-width :color ,border-color)))

(let ((yoshi-0 "#222424")
      (yoshi-1 "#3f4242")
      (yoshi-2 "#5b6161")
      (yoshi-3 "#787f7f")
      (yoshi-4 "#848484")
      (yoshi-5 "#a2a2a2")
      (yoshi-6 "#bfbfbf")
      (bgred       "#3f1a1a") (fgred       "#a85454")
      (bgorange    "#3f321f") (fgorange    "#a87e54")
      (bgyellow    "#343922") (fgyellow    "#a8a854")
      (bggreen     "#263f1f") (fggreen     "#54a854")
      (bgturquoise "#1f3f2c") (fgturquoise "#54a87e")
      (bgcyan      "#1f3f3f") (fgcyan      "#54a8a8")
      (bgblue      "#1f2c3f") (fgblue      "#547ea8")
      (bgpurple    "#2f2a3f") (fgpurple    "#7d71a8")
      (bgmagenta   "#381f3f") (fgmagenta   "#a845a8")
      (bgpink      "#3f1f32") (fgpink      "#a8547e"))
  (custom-theme-set-faces
   'yoshi

   ;; General
   `(cursor ((t (:background ,yoshi-4))))
   `(default ((t (:background ,yoshi-0 :foreground ,yoshi-6))))
   `(error ((t (:foreground ,fgred :weight bold))))
   `(font-lock-builtin-face ((t (:foreground ,fgcyan))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,yoshi-4 :inherit unspecified))))
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
   `(header-line ((t (:inherit mode-line))))
   `(highlight ((t (:background ,bgcyan))))
   `(italic ((t (:slant italic))))
   `(link ((t (:foreground ,fgorange :underline t))))
   `(link-visited ((t (:foreground ,fgmagenta :underline t))))
   `(minibuffer-prompt ((t (:foreground ,fgblue))))
   `(mode-line ((t (:background ,yoshi-2 :foreground ,yoshi-6 :box (:color ,yoshi-2 :line-width 5 :style nil)))))
   `(mode-line-buffer-id ((t (:background ,fgred :foreground ,yoshi-6 :box (:color ,fgred :line-width 5 :style nil)))))
   `(mode-line-highlight ((t (:background ,yoshi-3 :foreground ,yoshi-6 :box (:color ,yoshi-3 :line-width 5 :style nil)))))
   `(mode-line-inactive ((t (:background ,yoshi-1 :foreground ,yoshi-5 :box (:color ,yoshi-1 :line-width 5 :style nil)))))
   `(region ((t (:background ,bgblue))))
   `(shadow ((t (:foreground ,yoshi-4))))
   `(success ((t (:foreground ,fggreen :weight bold))))
   `(trailing-whitespace ((t (:background ,fgred))))
   `(warning ((t (:foreground ,fgorange :weight unspecified))))

   ;; Cider
   `(cider-test-success-face ((t (:foreground ,fggreen :background unspecified :weight bold))))
   `(cider-test-failure-face ((t (:foreground ,fgred :background unspecified :weight bold))))

   ;; Circe
   `(circe-highlight-nick-face ((t (:foreground ,fgred :weight bold))))
   `(circe-server-face ((t (:foreground ,yoshi-4))))
   `(lui-button-face ((t (:foreground unspecified :underline unspecified :inherit button))))
   `(lui-time-stamp-face ((t (:foreground ,fggreen :weight unspecified))))

   ;; Company
   `(company-preview ((t (:background unspecified :foreground ,yoshi-4))))
   `(company-preview-common ((t (:foreground ,bgcyan :inherit unspecified :weight bold))))
   `(company-scrollbar-bg ((t (:background ,yoshi-1))))
   `(company-scrollbar-fg ((t (:background ,yoshi-2))))
   `(company-tooltip ((t (:foreground ,yoshi-6 :background ,yoshi-1))))
   `(company-tooltip-annotation ((t (:foreground ,fgblue))))
   `(company-tooltip-common ((t (:foreground ,fgcyan))))
   `(company-tooltip-search ((t (:background ,bgyellow :inherit unspecified))))
   `(company-tooltip-search-selection ((t (:background ,bgyellow :inherit unspecified))))
   `(company-tooltip-selection ((t (:background ,yoshi-2))))

   ;; Compilation
   `(compilation-info ((t (:foreground ,fgblue :inherit unspecified))))

   ;; CSS
   `(css-property ((t (:foreground ,fgorange))))
   `(css-proprietary-property ((t (:foreground ,fgred :inherit unspecified :slant italic))))
   `(css-selector ((t (:foreground ,fgblue))))

   ;; Diff
   `(diff-added ((t (:background ,bggreen :inherit unspecified))))
   `(diff-changed ((t (:background ,bgorange))))
   `(diff-file-header ((t (:foreground ,yoshi-5 :background unspecified :weight bold))))
   `(diff-function ((t (:inherit unspecified :foreground ,fgorange))))
   `(diff-header ((t (:background ,yoshi-1))))
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

   ;; Dired
   `(dired-flagged ((t (:inherit region))))
   `(dired-header ((t (:foreground ,fgturquoise :weight bold :inherit unspecified))))
   `(dired-mark ((t (:foreground ,fgpink :inherit unspecified))))
   `(dired-marked ((t (:background ,bgpink :inherit unspecified))))

   ;; Ediff
   `(ediff-current-diff-A ((t (:inherit diff-removed))))
   `(ediff-current-diff-B ((t (:inherit diff-added))))
   `(ediff-current-diff-C ((t (:inherit diff-changed))))
   `(ediff-even-diff-A ((t (:background ,bgyellow))))
   `(ediff-even-diff-B ((t (:background ,bgyellow))))
   `(ediff-fine-diff-A ((t (:inherit diff-refine-removed))))
   `(ediff-fine-diff-B ((t (:inherit diff-refine-added))))
   `(ediff-fine-diff-C ((t (:inherit diff-refine-change))))
   `(ediff-odd-diff-A ((t (:background ,bgyellow))))
   `(ediff-odd-diff-B ((t (:background ,bgyellow))))

   ;; ERC
   `(erc-button ((t (:weight unspecified :inherit button))))
   `(erc-current-nick-face ((t (:foreground ,fgred :weight bold))))
   `(erc-input-face ((t (:inherit shadow))))
   `(erc-my-nick-face ((t (:inherit erc-current-nick-face))))
   `(erc-notice-face ((t (:foreground ,fgblue :weight normal))))
   `(erc-prompt-face ((t (:foreground ,yoshi-5 :weight bold))))
   `(erc-timestamp-face ((t (:foreground ,yoshi-4 :weight normal))))

   ;; ERT
   `(ert-test-result-expected ((t (:background unspecified :foreground ,fggreen))))
   `(ert-test-result-unexpected ((t (:background unspecified :foreground ,fgred))))

   ;; Eshell
   `(eshell-fringe-status-failure ((t (:foreground ,fgred))))
   `(eshell-fringe-status-success ((t (:foreground ,fggreen))))
   `(eshell-ls-archive ((t (:foreground ,fgpink :weight unspecified))))
   `(eshell-ls-backup ((t (:foreground ,fgorange))))
   `(eshell-ls-clutter ((t (:foreground ,yoshi-4 :weight unspecified))))
   `(eshell-ls-directory ((t (:foreground ,fgblue :weight unspecified))))
   `(eshell-ls-executable ((t (:foreground ,fggreen :weight unspecified))))
   `(eshell-ls-missing ((t (:foreground ,fgred :weight bold))))
   `(eshell-ls-product ((t (:foreground ,fgpurple))))
   `(eshell-ls-readonly ((t (:foreground ,fgmagenta))))
   `(eshell-ls-special ((t (:foreground ,fgturquoise))))
   `(eshell-ls-symlink ((t (:foreground ,fgcyan :weight unspecified))))
   `(eshell-ls-unreadable ((t (:foreground ,fgred))))
   `(eshell-prompt ((t (:foreground ,yoshi-5 :weight unspecified))))

   `(fill-column-indicator ((t (:foreground ,yoshi-2 :inherit unspecified))))

   ;; Flycheck
   `(flycheck-error ((t (:inherit unspecified :underline (:color ,fgred :style wave)))))
   `(flycheck-warning ((t (:inherit unspecified :underline (:color ,fgorange :style wave)))))

   ;; Flycheck inline
   `(flycheck-inline-error ((t (:inherit unspecified :foreground ,fgred :height 0.8))))
   `(flycheck-inline-info ((t (:inherit unspecified :foreground ,fgblue :height 0.8))))
   `(flycheck-inline-warning ((t (:inherit unspecified :foreground ,fgorange :height 0.8))))

   ;; Flycheck posframe
   `(flycheck-posframe-background-face ((t (:background ,yoshi-1))))
   `(flycheck-posframe-border-face ((t (:background ,yoshi-1))))

   ;; Flymake
   `(flymake-errline ((t (:background unspecified :underline (:color ,fgred :style wave)))))
   `(flymake-infoline ((t (:background unspecified :underline (:color ,fgblue :style wave)))))
   `(flymake-warnline ((t (:background unspecified :underline (:color ,fgorange :style wave)))))

   ;; Flyspell
   `(flyspell-duplicate ((t (:inherit unspecified :underline (:color ,fgorange :style wave)))))
   `(flyspell-incorrect ((t (:inherit unspecified :underline (:color ,fgred :style wave)))))

   ;; Gnus
   `(gnus-button ((t (:weight bold))))
   `(gnus-cite-1 ((t (:foreground ,fgred))))
   `(gnus-cite-10 ((t (:foreground ,fgpink))))
   `(gnus-cite-11 ((t (:foreground ,yoshi-5))))
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
   `(gnus-header-content ((t (:foreground ,yoshi-4 :slant italic))))
   `(gnus-header-from ((t (:weight bold))))
   `(gnus-header-name ((t (:foreground ,fgblue :weight bold))))
   `(gnus-header-newsgroups ((t (:foreground ,yoshi-5 :weight bold))))
   `(gnus-header-subject ((t (:foreground ,fgyellow))))
   `(gnus-signature ((t (:foreground ,yoshi-4 :slant italic))))
   `(gnus-splash ((t (:foreground ,yoshi-6))))
   `(gnus-summary-cancelled ((t (:foreground ,yoshi-4 :background unspecified :strike-through t))))
   `(gnus-summary-high-ancient ((t (:inherit gnus-summary-normal-ancient :weight bold))))
   `(gnus-summary-high-read ((t (:inherit gnus-summary-normal-read :weight bold))))
   `(gnus-summary-high-ticked ((t (:inherit gnus-summary-normal-ticked :weight bold))))
   `(gnus-summary-high-unread ((t (:foreground ,fgpink))))
   `(gnus-summary-low-ancient ((t (:inherit gnus-summary-normal-ancient :slant italic))))
   `(gnus-summary-low-read ((t (:inherit gnus-summary-normal-read :slant italic))))
   `(gnus-summary-low-ticked ((t (:inherit gnus-summary-normal-ticked :slant italic))))
   `(gnus-summary-low-unread ((t (:inherit gnus-summary-normal-unread :slant italic))))
   `(gnus-summary-normal-ancient ((t (:foreground ,fgcyan))))
   `(gnus-summary-normal-read ((t (:foreground ,yoshi-4))))
   `(gnus-summary-normal-ticked ((t (:foreground ,fgturquoise))))
   `(gnus-summary-normal-unread ((t (:foreground ,yoshi-6))))
   `(gnus-summary-selected ((t (:background ,bgblue :weight bold))))

   ;; Helm
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
   `(helm-match ((t (:foreground ,yoshi-5 :weight bold))))
   `(helm-selection ((t (:distant-foreground unspecified :background ,bgblue))))
   `(helm-source-header ((t (:font-family unspecified :height 1.1 :weight bold :foreground ,fgturquoise :background unspecified))))

   ;; Highlight 80+
   `(highlight-80+ ((t (:underline (:color ,fgred :style wave) :background unspecified))))

   ;; Highlight numbers
   `(highlight-numbers-number ((t (:foreground ,fgcyan :inherit unspecified))))

   ;; Highlight indent
   `(hl-indent-block-face-1 ((t (:background ,bgred))))
   `(hl-indent-block-face-2 ((t (:background ,bgpink))))
   `(hl-indent-block-face-3 ((t (:background ,bgorange))))
   `(hl-indent-block-face-4 ((t (:background ,bgyellow))))
   `(hl-indent-block-face-5 ((t (:background ,bggreen))))
   `(hl-indent-block-face-6 ((t (:background ,bgturquoise))))
   `(hl-indent-face ((t (:inherit unspecified :background ,yoshi-3))))

   ;; Highlight indent guides
   `(highlight-indent-guides-character-face ((t (:inherit unspecified :foreground ,yoshi-3))))

   ;; Hydra
   `(hydra-face-amaranth ((t (:foreground ,fgorange :weight bold))))
   `(hydra-face-blue ((t (:foreground ,fgblue :weight bold))))
   `(hydra-face-pink ((t (:foreground ,fgpink :weight bold))))
   `(hydra-face-red ((t (:foreground ,fgred :weight bold))))
   `(hydra-face-teal ((t (:foreground ,fgcyan :weight bold))))

   ;; Identica
   `(identica-stripe-face ((t (:background ,yoshi-2))))
   `(identica-uri-face ((t (:foreground ,fgorange :underline t))))
   `(identica-username-face ((t (:foreground ,fgblue :weight bold :underline unspecified))))

   ;; Ido
   `(ido-subdir ((t (:foreground ,fgred))))

   ;; Isearch
   `(isearch ((t (:background ,bgyellow :foreground unspecified))))
   `(isearch-fail ((t (:background ,bgred))))

   ;; Ivy
   `(ivy-current-match ((t (:background ,yoshi-2 :foreground ,yoshi-6))))
   `(ivy-minibuffer-match-face-1 ((t (:background unspecified :underline t))))
   `(ivy-minibuffer-match-face-2 ((t (:background unspecified :weight bold))))
   `(ivy-minibuffer-match-face-3 ((t (:background unspecified :weight bold))))
   `(ivy-minibuffer-match-face-4 ((t (:background unspecified :weight bold))))
   `(ivy-posframe ((t (:background ,yoshi-1 :foreground ,yoshi-6 :inherit unspecified))))
   `(ivy-posframe-border ((t (:background ,yoshi-1 :inherit unspecified))))

   ;; Jabber
   `(jabber-activity-face ((t (:foreground ,fgred :weight unspecified))))
   `(jabber-activity-personal-face ((t (:foreground ,fgblue :weight unspecified))))
   `(jabber-chat-error ((t (:foreground ,fgred :weight bold))))
   `(jabber-chat-prompt-foreign ((t (:foreground ,fgred :slant italic))))
   `(jabber-chat-prompt-local ((t (:foreground ,fgblue :slant italic))))
   `(jabber-chat-prompt-system ((t (:foreground ,fggreen :slant italic))))
   `(jabber-rare-time-face ((t (:foreground ,yoshi-6 :underline t))))
   `(jabber-roster-user-away ((t (:foreground ,fggreen :slant italic))))
   `(jabber-roster-user-chatty ((t (:foreground ,fgpink))))
   `(jabber-roster-user-dnd ((t (:foreground ,fgred :weight unspecified :slant unspecified))))
   `(jabber-roster-user-error ((t (:foreground ,fgred :slant unspecified :weight bold))))
   `(jabber-roster-user-offline ((t (:foreground ,yoshi-4 :slant italic))))
   `(jabber-roster-user-online ((t (:foreground ,fgblue))))
   `(jabber-roster-user-xa ((t (:foreground ,fgmagenta))))

   ;; JS2 mode
   `(js2-error ((t (:foreground unspecified :inherit error))))
   `(js2-external-variable ((t (:foreground ,fgmagenta))))
   `(js2-function-call ((t (:inherit font-lock-function-name-face))))
   `(js2-function-param ((t (:foreground unspecified :inherit font-lock-variable-name-face))))
   `(js2-object-property ((t (:inherit font-lock-variable-name-face))))
   `(js2-warning ((t (:underline unspecified :inherit font-lock-warning-face))))

   ;; Magit
   `(magit-bisect-bad ((t (:foreground ,fgred))))
   `(magit-bisect-good ((t (:foreground ,fggreen))))
   `(magit-bisect-skip ((t (:foreground ,yoshi-4))))
   `(magit-blame-date ((t (:foreground ,fgpink :inherit magit-blame-heading))))
   `(magit-blame-hash ((t (:foreground ,fgmagenta :inherit magit-blame-heading))))
   `(magit-blame-header ((t (:foreground ,fggreen :background ,yoshi-1 :weight bold :inherit unspecified))))
   `(magit-blame-heading ((t (:foreground ,yoshi-6 :background ,yoshi-2))))
   `(magit-blame-name ((t (:foreground ,fgturquoise :inherit magit-blame-heading))))
   `(magit-blame-summary ((t (:foreground ,fggreen :inherit magit-blame-heading))))
   `(magit-branch ((t (:foreground ,fgpink :weight bold :inherit unspecified))))
   `(magit-branch-current ((t (:foreground ,yoshi-6 :background ,bgblue :box (:color ,bgblue :line-width 2 :style nil) :inherit unspecified))))
   `(magit-branch-local ((t (:foreground ,yoshi-6 :background ,bgmagenta :box (:color ,bgmagenta :line-width 2 :style nil)))))
   `(magit-branch-remote ((t (:foreground ,yoshi-6 :background ,bggreen :box (:color ,bggreen :line-width 2 :style nil)))))
   `(magit-diff-added ((t (:foreground unspecified :background unspecified :inherit diff-added))))
   `(magit-diff-added-highlight ((t (:foreground unspecified :background unspecified :inherit magit-diff-added))))
   `(magit-diff-context ((t (:foreground unspecified :inherit shadow))))
   `(magit-diff-context-highlight ((t (:foreground unspecified :background ,yoshi-1 :inherit magit-diff-context))))
   `(magit-diff-file-heading ((t (:foreground unspecified :underline unspecified :inherit diff-file-header))))
   `(magit-diff-removed ((t (:foreground unspecified :background unspecified :inherit diff-removed))))
   `(magit-diff-removed-highlight ((t (:foreground unspecified :background unspecified :inherit magit-diff-removed))))
   `(magit-item-highlight ((t (:slant italic  :inherit unspecified))))
   `(magit-log-head-label-default ((t (:foreground ,yoshi-6 :background ,bgcyan :box (:color ,bgcyan :line-width 2 :style nil)))))
   `(magit-log-head-label-head ((t (:foreground ,yoshi-6 :background ,bgblue :box (:color ,bgblue :line-width 2 :style nil)))))
   `(magit-log-head-label-local ((t (:foreground ,yoshi-6 :background ,bgmagenta :box (:color ,bgmagenta :line-width 2 :style nil)))))
   `(magit-log-head-label-remote ((t (:foreground ,yoshi-6 :background ,bggreen :box (:color ,bggreen :line-width 2 :style nil)))))
   `(magit-log-head-label-tags ((t (:foreground ,yoshi-6 :background ,bgorange :box (:color ,bgorange :line-width 2 :style nil)))))
   `(magit-log-sha1 ((t (:foreground ,yoshi-6 :background ,bgblue :box (:color ,bgblue :line-width 2 :style nil)))))
   `(magit-process-ng ((t (:foreground ,fgred :inherit unspecified))))
   `(magit-process-ok ((t (:foreground ,fggreen :inherit unspecified))))
   `(magit-section-heading ((t (:foreground ,fgturquoise :weight unspecified :height 1.3))))
   `(magit-section-highlight ((t (:background unspecified :slant italic))))
   `(magit-section-title ((t (:foreground ,fgturquoise :inherit unspecified :height 1.8))))

   ;; Makefile
   `(makefile-space ((t (:background ,bgpink))))

   ;; Markdown
   `(markdown-header-face-1 ((t (:foreground ,fggreen :inherit unspecified))))
   `(markdown-header-face-2 ((t (:foreground ,fgcyan :inherit unspecified))))
   `(markdown-header-face-3 ((t (:foreground ,fgred :inherit unspecified))))
   `(markdown-header-face-4 ((t (:foreground ,fgblue :inherit unspecified))))
   `(markdown-header-face-5 ((t (:foreground ,fgyellow :inherit unspecified))))
   `(markdown-header-face-6 ((t (:foreground ,fgpurple :inherit unspecified))))

   ;; Message mode
   `(message-header-cc ((t (:foreground ,yoshi-4))))
   `(message-header-name ((t (:inherit gnus-header-name))))
   `(message-header-newsgroups ((t (:foreground ,yoshi-4 :weight bold))))
   `(message-header-other ((t (:inherit gnus-header-content))))
   `(message-header-subject ((t (:inherit gnus-header-subject))))
   `(message-header-to ((t (:foreground ,yoshi-4 :weight bold))))
   `(message-header-xheader ((t (:foreground ,yoshi-4 :slant italic))))
   `(message-mml ((t (:foreground ,fggreen))))
   `(message-separator ((t (:foreground ,fgblue))))

   ;; Org
   `(org-agenda-calendar-sexp ((t (:foreground ,fgyellow))))
   `(org-agenda-current-time ((t (:foreground ,fgorange :weight bold))))
   `(org-agenda-date ((t (:foreground ,bgcyan))))
   `(org-agenda-date-today ((t (:foreground ,fgcyan :slant italic))))
   `(org-agenda-date-weekend ((t (:foreground ,fgcyan))))
   `(org-agenda-done ((t (:foreground ,fgorange))))
   `(org-agenda-structure ((t (:foreground ,fgblue))))
   `(org-block ((t (:foreground ,yoshi-6 :background ,yoshi-1 :inherit fixed-pitch))))
   `(org-block-background ((t (:background ,yoshi-1))))
   `(org-block-begin-line ((t (:foreground ,yoshi-4 :slant unspecified :background ,yoshi-2 :height 0.71))))
   `(org-block-end-line ((t (:foreground ,yoshi-4 :slant unspecified :background ,yoshi-1 :height 0.71))))
   `(org-checkbox-statistics-done ((t (:foreground ,bgcyan))))
   `(org-checkbox-statistics-todo ((t (:foreground ,fgcyan))))
   `(org-code ((t (:background ,yoshi-1 :box ,(yoshi-theme--make-inline-box yoshi-1) :inherit fixed-pitch))))
   `(org-date ((t (:foreground ,fgpink :underline unspecified))))
   `(org-document-info-keyword ((t (:foreground ,yoshi-4 :inherit fixed-pitch))))
   `(org-document-title ((t (:foreground ,fgorange :height 1.5))))
   `(org-headline-done ((t (:foreground ,yoshi-4))))
   `(org-level-1 ((t (:foreground ,fggreen :underline t :height 1.2))))
   `(org-level-2 ((t (:foreground ,fgcyan :weight bold :height 1.1))))
   `(org-level-3 ((t (:foreground ,fgred :slant italic))))
   `(org-level-4 ((t (:foreground ,fgblue))))
   `(org-level-5 ((t (:foreground ,fgyellow))))
   `(org-level-6 ((t (:foreground ,fgpurple))))
   `(org-level-7 ((t (:foreground ,fgturquoise))))
   `(org-level-8 ((t (:foreground ,fgorange))))
   `(org-meta-line ((t (:foreground ,yoshi-4 :inherit fixed-pitch))))
   `(org-scheduled ((t (:foreground ,yoshi-4))))
   `(org-scheduled-previously ((t (:weight bold))))
   `(org-scheduled-today ((t (:foreground ,yoshi-6))))
   `(org-time-grid ((t (:foreground ,fgorange))))
   `(org-verbatim ((t (:foreground ,fgcyan :inherit fixed-pitch))))

   ;; Outline
   `(outline-1 ((t (:inherit org-level-1))))
   `(outline-2 ((t (:inherit org-level-2))))
   `(outline-3 ((t (:inherit org-level-3))))
   `(outline-4 ((t (:inherit org-level-4))))
   `(outline-5 ((t (:inherit org-level-5))))
   `(outline-6 ((t (:inherit org-level-6))))
   `(outline-7 ((t (:inherit org-level-7))))
   `(outline-8 ((t (:inherit org-level-8))))

   ;; Package
   `(package-status-avail-obso ((t (:foreground ,bggreen))))
   `(package-status-available ((t (:foreground ,fggreen))))
   `(package-status-dependency ((t (:foreground ,yoshi-4))))
   `(package-status-installed ((t (:foreground ,yoshi-6))))

   ;; Pretty-print ^L highlight
   `(pp^L-highlight ((t (:box unspecified :foreground ,yoshi-5))))

   ;; Rainbow delimiters
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

   ;; Rebase mode
   `(rebase-mode-description-face ((t (:foreground ,yoshi-5))))

   ;; reStructuredText
   `(rst-level-1 ((t (:background unspecified))))
   `(rst-level-2 ((t (:background unspecified))))
   `(rst-level-3 ((t (:background unspecified))))
   `(rst-level-4 ((t (:background unspecified))))
   `(rst-level-5 ((t (:background unspecified))))
   `(rst-level-6 ((t (:background unspecified))))

   ;; Sh
   `(sh-escaped-newline ((t (:foreground ,fgpurple :inherit unspecified :weight bold))))
   `(sh-heredoc ((t (:foreground ,fggreen))))
   `(sh-quoted-exec ((t (:foreground ,fgpink))))

   ;; Show paren
   `(show-paren-match ((t (:inverse-video t))))
   `(show-paren-mismatch ((t (:background unspecified :foreground ,fgred))))

   ;; Slime
   `(slime-repl-input-face ((t (:foreground ,yoshi-5))))
   `(slime-repl-inputed-output-face ((t (:foreground ,yoshi-5))))
   `(slime-repl-output-face ((t (:foreground ,yoshi-6))))
   `(slime-repl-prompt-face ((t (:foreground ,fgblue))))

   ;; Smerge
   `(smerge-base ((t (:background ,bggreen))))
   `(smerge-markers ((t (:background ,yoshi-2))))
   `(smerge-mine ((t (:background ,bgblue))))
   `(smerge-other ((t (:background ,bgred))))
   `(smerge-refined-added ((t (:inherit diff-refine-added))))
   `(smerge-refined-change ((t (:inherit diff-refine-change))))
   `(smerge-refined-removed ((t (:inherit diff-refine-removed))))

   ;; Tab bar

   `(tab-bar ((t (:background ,yoshi-1 :foreground ,yoshi-5))))
   `(tab-bar-tab ((t (:background ,fgred :foreground ,yoshi-6 :box (:color ,fgred :line-width 5 :style nil)))))
   `(tab-bar-tab-inactive ((t (:background ,yoshi-2 :foreground ,yoshi-6 :box (:color ,yoshi-2 :line-width 5 :style nil)))))

   ;; Term
   `(term-color-black ((t (:background ,yoshi-0 :foreground ,yoshi-5))))
   `(term-color-blue ((t (:background ,bgblue :foreground ,fgblue))))
   `(term-color-cyan ((t (:background ,bgcyan :foreground ,fgcyan))))
   `(term-color-green ((t (:background ,bggreen :foreground ,fggreen))))
   `(term-color-magenta ((t (:background ,bgmagenta :foreground ,fgmagenta))))
   `(term-color-red ((t (:background ,bgred :foreground ,fgred))))
   `(term-color-white ((t (:background ,yoshi-2 :foreground ,yoshi-6))))
   `(term-color-yellow ((t (:background ,bgyellow :foreground ,fgyellow))))

   ;; Texinfo
   `(texinfo-heading ((t (:foreground ,fgpink :inherit unspecified :height 1.3))))

   ;; Which function mode
   `(which-func ((t (:foreground ,fgblue))))

   ;; Whitespace mode
   `(whitespace-empty ((t (:background ,bgcyan :foreground ,yoshi-6))))
   `(whitespace-hspace ((t (:background ,yoshi-2 :foreground ,yoshi-5))))
   `(whitespace-indentation ((t (:background ,bgyellow :foreground unspecified))))
   `(whitespace-line ((t (:background ,bgred :foreground unspecified))))
   `(whitespace-newline ((t (:foreground ,fgpink))))
   `(whitespace-space ((t (:background unspecified :foreground ,fgpink))))
   `(whitespace-space-after-tab ((t (:background ,bgorange :foreground unspecified))))
   `(whitespace-space-before-tab ((t (:background ,bgorange :foreground unspecified))))
   `(whitespace-tab ((t (:background unspecified :underline ,yoshi-2))))
   `(whitespace-trailing ((t (:background ,bgorange :foreground unspecified))))

   ;; Widget
   `(widget-button ((t (:inherit button))))
   `(widget-button-pressed ((t (:inherit widget-button :weight bold))))
   `(widget-documentation ((t (:inherit font-lock-doc-face))))
   `(widget-field ((t (:background ,bgblue :box (:color ,bgblue :line-width 2)))))

   ;; rpm-spec-mode
   `(rpm-spec-tag-face ((t (:foreground ,fgblue))))
   `(rpm-spec-obsolete-tag-face ((t (:background ,bgred))))
   `(rpm-spec-macro-face ((t (:foreground ,fgyellow))))
   `(rpm-spec-var-face ((t (:foreground ,fgcyan))))
   `(rpm-spec-doc-face ((t (:foreground ,fgmagenta))))
   `(rpm-spec-dir-face ((t (:foreground ,fgturquoise))))
   `(rpm-spec-package-face ((t (:foreground ,fgred))))
   `(rpm-spec-ghost-face ((t (:foreground ,fgred))))
   `(rpm-spec-section-face ((t (:foreground ,fgyellow :underline t))))

   ;; Window dividers
   `(window-divider ((t (:foreground ,yoshi-2))))
   `(window-divider-first-pixel ((t (:foreground unspecified :inherit window-divider))))
   `(window-divider-last-pixel ((t (:foreground unspecified :inherit window-divider))))
   )

  (custom-theme-set-variables
   'yoshi
   `(ansi-color-names-vector [,yoshi-1 ,fgred ,fggreen ,fgyellow
                                       ,fgblue ,fgmagenta ,fgcyan ,yoshi-4])
   `(fci-rule-color ,bgred)
   '(org-fontify-whole-block-delimiter-line t)
   '(org-fontify-whole-heading-line t)
   '(window-divider-mode t)
   '(window-divider-default-right-width 1)
   '(ivy-posframe-border-width 15)
   '(ivy-posframe-style 'frame-bottom-window-center)
   `(hydra-posframe-show-params
     '(:poshandler posframe-poshandler-frame-bottom-center
                   :internal-border-width 15
                   :internal-border-color ,yoshi-1
                   :background-color ,yoshi-1))
   '(flycheck-posframe-border-width 5)
   '(mode-line-buffer-identification (propertized-buffer-identification "%b"))))

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'yoshi)
;;; yoshi-theme.el ends here
