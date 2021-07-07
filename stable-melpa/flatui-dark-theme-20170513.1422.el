;;; flatui-dark-theme.el --- Dark color theme with colors from https://flatuicolors.com/

;; Copyright 2017, Andrew Phillips

;; Author: Andrew Phillips <theasp@gmail.com>
;; Keywords: color theme dark flatui faces
;; Package-Version: 20170513.1422
;; Package-Commit: 5b959a9f743f891e4660b1b432086417947872ea
;; URL: https://github.com/theasp/flatui-dark-theme
;; Package-Requires: ((emacs "24"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Dark color theme with flatui colors from https://flatuicolors.com/.
;; The theme structure has been borrowed from grandshell-theme, which
;; borrowed it from color-theme-sanityinc-solarized.

;; URLs:
;; grandshell-theme: https://github.com/steckerhalter/grandshell-theme
;; color-theme-sanityinc-solarized: https://github.com/purcell/color-theme-sanityinc-solarized
;; 

;;; Requirements:

;; Emacs 24.

;;; Code:

(deftheme flatui-dark "Dark color theme with colors from https://flatuicolors.com/")

(let ((class '((class color) (min-colors 89)))
      (turquoise-bright "#1abc9c")
      (turquoise-dark "#16a085")
      (green-bright "#2ecc71")
      (green-dark "#27ae60")
      (blue-bright "#3498db")
      (blue-dark "#2980b9")
      (magenta-bright "#9b59b6")
      (magenta-dark "#8e44ad")
      (grey-blue-bright "#34495e")
      (grey-blue-dark "#2c3e50")
      (yellow-bright "#f1c40f")
      (yellow-dark "#f39c12")
      (orange-bright "#e67e22")
      (orange-dark "#d35400")
      (red-bright "#e74c3c")
      (red-dark "#c0392b")
      (grey-bright2 "#ecf0f1")
      (grey-bright1 "#bdc3c7")
      (grey-dark1 "#95a5a6")
      (grey-dark2 "#7f8c8d")
      (black "#000")
      (white "#fff"))

  (custom-theme-set-faces
   'flatui-dark

   ;; standard faces
   `(default ((,class (:foreground ,grey-bright1 :background ,black))))
   `(bold ((,class (:weight bold))))
   `(italic ((,class (:slant italic))))
   `(bold-italic ((,class (:slant italic :weight bold))))
   `(underline ((,class (:underline t))))
   `(shadow ((,class (:foreground ,grey-bright1))))
   `(link ((,class (:foreground ,turquoise-bright :underline t))))

   `(highlight ((,class (:inverse-video nil :background ,grey-blue-dark))))
   `(isearch ((,class (:foreground ,yellow-bright :background ,black :inverse-video t))))
   `(isearch-fail ((,class (:background ,black :inherit font-lock-warning-face :inverse-video t))))
   `(match ((,class (:foreground ,yellow-dark :background ,black :inverse-video t))))
   `(lazy-highlight ((,class (:foreground ,yellow-dark :background ,black :inverse-video t))))
   `(region ((,class (:inverse-video t))))
   `(secondary-selection ((,class (:background ,grey-blue-dark))))
   `(trailing-whitespace ((,class (:background ,red-dark :underline nil))))

   `(mode-line ((t (:foreground ,black :background ,grey-bright1))))
   `(mode-line-inactive ((t (:foreground ,grey-blue-dark :background ,grey-dark2 :weight light :box nil :inherit (mode-line )))))
   `(mode-line-buffer-id ((t (:foreground ,black))))
   `(mode-line-emphasis ((,class (:foreground ,magenta-bright))))
   `(which-func ((,class (:foreground ,blue-dark :background nil :weight bold))))

   `(header-line ((,class (:inherit mode-line :foreground ,magenta-bright :background nil))))
   `(minibuffer-prompt ((,class (:foreground ,grey-bright2))))
   `(fringe ((,class (:background ,grey-blue-dark))))
   `(cursor ((,class (:background ,grey-dark1 :foreground ,black))))
   `(border ((,class (:background ,grey-blue-dark))))
   `(widget-button ((,class (:underline t))))
   `(widget-field ((,class (:background ,grey-blue-dark :box (:line-width 1 :color ,grey-bright1)))))

   `(success ((,class (:foreground ,green-dark))))
   `(warning ((,class (:foreground ,yellow-dark))))
   `(error ((,class (:foreground ,red-dark))))

   `(show-paren-match ((,class (:inverse-video t :weight bold))))
   `(show-paren-mismatch ((,class (:background ,black :inherit font-lock-warning-face :inverse-video t))))

   `(custom-variable-tag ((,class (:foreground ,blue-dark))))
   `(custom-group-tag ((,class (:foreground ,blue-dark))))
   `(custom-state-tag ((,class (:foreground ,green-dark))))

   ;; general font lock faces
   `(font-lock-builtin-face ((,class (:foreground ,orange-bright))))
   `(font-lock-comment-delimiter-face ((,class (:foreground ,yellow-bright :inherit 'fixed-pitch))))
   `(font-lock-comment-face ((,class (:foreground ,yellow-bright :inherit 'fixed-pitch :slant italic))))
   `(font-lock-constant-face ((,class (:foreground ,turquoise-bright))))
   `(font-lock-doc-face ((,class (:foreground ,orange-bright))))
   `(font-lock-doc-string-face ((,class (:foreground ,yellow-bright))))
   `(font-lock-function-name-face ((,class (:foreground ,blue-bright))))
   `(font-lock-keyword-face ((,class (:foreground ,magenta-bright))))
   `(font-lock-negation-char-face ((,class (:foreground ,green-dark))))
   `(font-lock-preprocessor-face ((,class (:foreground ,magenta-dark))))
   `(font-lock-regexp-grouping-backslash ((,class (:foreground ,magenta-dark))))
   `(font-lock-regexp-grouping-construct ((,class (:foreground ,magenta-bright))))
   `(font-lock-string-face ((,class (:foreground ,yellow-bright))))
   `(font-lock-type-face ((,class (:foreground ,blue-dark))))
   `(font-lock-variable-name-face ((,class (:foreground ,yellow-bright))))
   `(font-lock-warning-face ((,class (:weight bold :foreground ,red-dark))))

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; mode specific faces

   ;; asorted faces
   `(csv-separator-face ((,class (:foreground ,yellow-bright))))
   `(border-glyph ((,class (nil))))
   `(gui-element ((,class (:background ,grey-blue-dark :foreground ,grey-bright1))))
   `(hl-sexp-face ((,class (:background ,grey-blue-dark))))
   `(highlight-80+ ((,class (:background ,grey-blue-dark))))
   `(rng-error-face ((,class (:underline ,red-dark))))
   `(py-builtins-face ((,class (:foreground ,yellow-dark :weight normal))))

   ;; auto-complete
   `(ac-completion-face ((,class (:foreground ,grey-bright2, :underline t))))
   `(ac-candidate-face ((,class (:background ,magenta-dark :foreground ,grey-bright2))))
   `(ac-selection-face ((,class (:background ,magenta-bright :foreground ,magenta-dark))))
   `(ac-yasnippet-candidate-face ((,class (:background ,orange-dark :foreground ,magenta-dark))))
   `(ac-yasnippet-selection-face ((,class (:background ,orange-bright :foreground ,magenta-dark))))

   ;; auto-dim-other-buffers
   `(auto-dim-other-buffers-face ((,class (:background "#0c0c0c"))))

   ;; clojure
   `(clojure-test-failure-face ((,class (:background nil :inherit flymake-warnline))))
   `(clojure-test-error-face ((,class (:background nil :inherit flymake-errline))))
   `(clojure-test-success-face ((,class (:background nil :foreground nil :underline ,green-dark))))
   `(clojure-keyword ((,class (:foreground ,yellow-bright))))
   `(clojure-parens ((,class (:foreground ,grey-bright2))))
   `(clojure-braces ((,class (:foreground ,green-dark))))
   `(clojure-brackets ((,class (:foreground ,yellow-bright))))
   `(clojure-double-quote ((,class (:foreground ,magenta-dark :background nil))))
   `(clojure-special ((,class (:foreground ,blue-dark))))
   `(clojure-java-call ((,class (:foreground ,magenta-bright))))

   ;; company
   `(company-preview ((,class (:foreground ,grey-bright2))))
   `(company-preview-common ((,class (:foreground ,grey-bright2 :underline t))))
   `(company-preview-search ((,class (:foreground ,magenta-dark :background ,yellow-bright))))
   `(company-tooltip ((,class (:background ,yellow-bright  :foreground "#000"))))
   `(company-tooltip-common ((,class (:inherit company-tooltip :foreground "#000"))))
   `(company-tooltip-common-selection ((,class (:inherit company-tooltip-selection))))
   `(company-tooltip-selection ((,class (:inherit company-tooltip-selection :background ,yellow-dark :weight bold))))
   `(company-scrollbar-bg ((,class (:background ,yellow-bright))))
   `(company-scrollbar-fg ((,class (:background ,yellow-dark))))

   ;; compilation
   `(compilation-column-number ((,class (:foreground ,yellow-bright))))
   `(compilation-line-number ((,class (:foreground ,yellow-bright))))
   `(compilation-message-face ((,class (:foreground ,blue-dark))))
   `(compilation-mode-line-exit ((,class (:foreground ,green-dark))))
   `(compilation-mode-line-fail ((,class (:foreground ,red-dark))))
   `(compilation-mode-line-run ((,class (:foreground ,blue-dark))))
   `(compilation-info ((,class (:foreground ,turquoise-bright))))

   ;; diff
   `(diff-added ((,class (:foreground ,green-dark))))
   `(diff-changed ((,class (:foreground ,magenta-bright))))
   `(diff-removed ((,class (:foreground ,yellow-dark))))
   `(diff-header ((,class (:foreground ,magenta-dark :background nil))))
   `(diff-file-header ((,class (:foreground ,blue-dark :background nil))))
   `(diff-hunk-header ((,class (:foreground ,magenta-bright))))
   `(diff-refine-removed ((,class (:inherit magit-diff-removed-highlight :foreground ,red-bright))))
   `(diff-refine-added ((,class (:inherit magit-diff-added-highlight :foreground ,blue-bright))))

   ;; diff-hl
   `(diff-hl-change ((,class (:foreground ,blue-dark :background ,blue-dark))))
   `(diff-hl-delete ((,class (:foreground ,orange-bright :background ,orange-dark))))
   `(diff-hl-insert ((,class (:foreground ,green-dark :background ,green-dark))))

   ;; dired+
   `(diredp-compressed-file-suffix ((,class (:foreground ,yellow-dark))))
   `(diredp-date-time ((,class (:foreground ,yellow-bright))))
   `(diredp-deletion ((,class (:foreground ,red-bright :weight bold :slant italic))))
   `(diredp-deletion-file-name ((,class (:foreground ,red-bright :underline t))))
   `(diredp-dir-heading ((,class (:foreground ,orange-bright :underline t :weight bold))))
   `(diredp-dir-priv ((,class (:foreground ,magenta-bright :background nil))))
   `(diredp-exec-priv ((,class (:foreground ,green-bright :background nil))))
   `(diredp-executable-tag ((,class (:foreground ,green-bright :background nil))))
   `(diredp-file-name ((,class (:foreground ,grey-bright1))))
   `(diredp-file-suffix ((,class (:foreground ,magenta-dark))))
   `(diredp-flag-mark ((,class (:foreground ,red-bright :weight bold))))
   `(diredp-flag-mark-line ((,class (:inherit highlight))))
   `(diredp-ignored-file-name ((,class (:foreground ,grey-dark1))))
   `(diredp-link-priv ((,class (:background nil :foreground ,orange-bright))))
   `(diredp-mode-line-flagged ((,class (:foreground ,yellow-dark))))
   `(diredp-mode-line-marked ((,class (:foreground ,magenta-bright))))
   `(diredp-no-priv ((,class (:foreground ,grey-dark1 :background nil))))
   `(diredp-number ((,class (:foreground ,yellow-dark))))
   `(diredp-other-priv ((,class (:background nil :foreground ,yellow-dark))))
   `(diredp-rare-priv ((,class (:foreground ,red-dark :background nil))))
   `(diredp-read-priv ((,class (:foreground ,blue-dark :background nil))))
   `(diredp-symlink ((,class (:foreground ,orange-bright))))
   `(diredp-write-priv ((,class (:foreground ,magenta-bright :background nil))))

   ;; ediff
   `(ediff-even-diff-A ((,class (:foreground nil :background nil :inverse-video t))))
   `(ediff-even-diff-B ((,class (:foreground nil :background nil :inverse-video t))))
   `(ediff-odd-diff-A  ((,class (:foreground ,grey-dark1 :background nil :inverse-video t))))
   `(ediff-odd-diff-B  ((,class (:foreground ,grey-dark1 :background nil :inverse-video t))))

   ;; eldoc
   `(eldoc-highlight-function-argument ((,class (:foreground ,green-dark :weight bold))))

   ;; erb
   `(erb-delim-face ((,class (:background ,grey-blue-dark))))
   `(erb-exec-face ((,class (:background ,grey-blue-dark :weight bold))))
   `(erb-exec-delim-face ((,class (:background ,grey-blue-dark))))
   `(erb-out-face ((,class (:background ,grey-blue-dark :weight bold))))
   `(erb-out-delim-face ((,class (:background ,grey-blue-dark))))
   `(erb-comment-face ((,class (:background ,grey-blue-dark :weight bold :slant italic))))
   `(erb-comment-delim-face ((,class (:background ,grey-blue-dark))))

   ;; erc
   `(erc-direct-msg-face ((,class (:foreground ,yellow-bright))))
   `(erc-error-face ((,class (:foreground ,red-dark))))
   `(erc-header-face ((,class (:foreground ,grey-bright2 :background ,grey-blue-dark))))
   `(erc-input-face ((,class (:foreground ,yellow-bright))))
   `(erc-current-nick-face ((,class (:foreground ,blue-dark :weight bold))))
   `(erc-my-nick-face ((,class (:foreground ,blue-dark))))
   `(erc-nick-default-face ((,class (:weight normal :foreground ,magenta-bright))))
   `(erc-nick-msg-face ((,class (:weight normal :foreground ,yellow-bright))))
   `(erc-notice-face ((,class (:foreground ,grey-dark2))))
   `(erc-pal-face ((,class (:foreground ,yellow-dark))))
   `(erc-prompt-face ((,class (:foreground ,blue-dark))))
   `(erc-timestamp-face ((,class (:foreground ,magenta-dark))))
   `(erc-keyword-face ((,class (:foreground ,green-dark))))

   ;; eshell
   `(eshell-ls-archive ((,class (:foreground ,magenta-dark :weight normal))))
   `(eshell-ls-backup ((,class (:foreground ,yellow-bright))))
   `(eshell-ls-clutter ((,class (:foreground ,yellow-dark :weight normal))))
   `(eshell-ls-directory ((,class (:foreground ,blue-dark :weight normal))))
   `(eshell-ls-executable ((,class (:foreground ,red-dark :weight normal))))
   `(eshell-ls-missing ((,class (:foreground ,magenta-bright :weight normal))))
   `(eshell-ls-product ((,class (:foreground ,yellow-bright))))
   `(eshell-ls-readonly ((,class (:foreground ,grey-dark2))))
   `(eshell-ls-special ((,class (:foreground ,green-dark :weight normal))))
   `(eshell-ls-symlink ((,class (:foreground ,magenta-bright :weight normal))))
   `(eshell-ls-unreadable ((,class (:foreground ,grey-bright1))))
   `(eshell-prompt ((,class (:foreground ,green-dark :weight normal))))

   ;; eval-sexp-fu
   `(eval-sexp-fu-flash ((,class (:background ,magenta-dark))))

   ;; fic-mode
   `(font-lock-fic-face ((,class (:background ,red-dark :foreground ,red-dark :weight bold))))

   ;; flycheck
   `(flycheck-error-face ((t (:foreground ,red-dark :background ,red-dark :weight bold))))
   `(flycheck-error ((,class (:underline (:color ,red-dark)))))
   `(flycheck-warning ((,class (:underline (:color ,yellow-dark)))))

   ;; flymake
   `(flymake-warnline ((,class (:underline ,yellow-dark :background ,black))))
   `(flymake-errline ((,class (:underline ,red-dark :background ,black))))

   ;; git-commit
   `(git-commit-summary ((,class (:foreground ,grey-bright1))))

   ;; git-gutter
   `(git-gutter:modified ((,class (:foreground ,magenta-bright :weight bold))))
   `(git-gutter:added ((,class (:foreground ,green-dark :weight bold))))
   `(git-gutter:deleted ((,class (:foreground ,red-dark :weight bold))))
   `(git-gutter:unchanged ((,class (:background ,yellow-bright))))

   ;; git-gutter-fringe
   `(git-gutter-fr:modified ((,class (:foreground ,magenta-bright :weight bold))))
   `(git-gutter-fr:added ((,class (:foreground ,green-dark :weight bold))))
   `(git-gutter-fr:deleted ((,class (:foreground ,red-dark :weight bold))))

   ;; gnus
   `(gnus-cite-1 ((,class (:inherit outline-1 :foreground nil))))
   `(gnus-cite-2 ((,class (:inherit outline-2 :foreground nil))))
   `(gnus-cite-3 ((,class (:inherit outline-3 :foreground nil))))
   `(gnus-cite-4 ((,class (:inherit outline-4 :foreground nil))))
   `(gnus-cite-5 ((,class (:inherit outline-5 :foreground nil))))
   `(gnus-cite-6 ((,class (:inherit outline-6 :foreground nil))))
   `(gnus-cite-7 ((,class (:inherit outline-7 :foreground nil))))
   `(gnus-cite-8 ((,class (:inherit outline-8 :foreground nil))))
   `(gnus-header-content ((,class (:inherit message-header-other))))
   `(gnus-header-subject ((,class (:inherit message-header-subject))))
   `(gnus-header-from ((,class (:inherit message-header-other-face :weight bold :foreground ,yellow-dark))))
   `(gnus-header-name ((,class (:inherit message-header-name))))
   `(gnus-button ((,class (:inherit link :foreground nil))))
   `(gnus-signature ((,class (:inherit font-lock-comment-face))))
   `(gnus-summary-normal-unread ((,class (:foreground ,grey-bright2 :weight normal))))
   `(gnus-summary-normal-read ((,class (:foreground ,grey-bright1 :weight normal))))
   `(gnus-summary-normal-ancient ((,class (:foreground ,magenta-dark :weight normal))))
   `(gnus-summary-normal-ticked ((,class (:foreground ,yellow-dark :weight normal))))
   `(gnus-summary-low-unread ((,class (:foreground ,grey-dark1 :weight normal))))
   `(gnus-summary-low-read ((,class (:foreground ,grey-dark2 :weight normal))))
   `(gnus-summary-low-ancient ((,class (:foreground ,grey-dark2 :weight normal))))
   `(gnus-summary-high-unread ((,class (:foreground ,yellow-bright :weight normal))))
   `(gnus-summary-high-read ((,class (:foreground ,green-dark :weight normal))))
   `(gnus-summary-high-ancient ((,class (:foreground ,green-dark :weight normal))))
   `(gnus-summary-high-ticked ((,class (:foreground ,yellow-dark :weight normal))))
   `(gnus-summary-cancelled ((,class (:foreground ,red-dark :background nil :weight normal))))
   `(gnus-group-mail-low ((,class (:foreground ,grey-dark2))))
   `(gnus-group-mail-low-empty ((,class (:foreground ,grey-dark2))))
   `(gnus-group-mail-1 ((,class (:foreground nil :weight normal :inherit outline-1))))
   `(gnus-group-mail-2 ((,class (:foreground nil :weight normal :inherit outline-2))))
   `(gnus-group-mail-3 ((,class (:foreground nil :weight normal :inherit outline-3))))
   `(gnus-group-mail-4 ((,class (:foreground nil :weight normal :inherit outline-4))))
   `(gnus-group-mail-5 ((,class (:foreground nil :weight normal :inherit outline-5))))
   `(gnus-group-mail-6 ((,class (:foreground nil :weight normal :inherit outline-6))))
   `(gnus-group-mail-1-empty ((,class (:inherit gnus-group-mail-1 :foreground ,grey-dark1))))
   `(gnus-group-mail-2-empty ((,class (:inherit gnus-group-mail-2 :foreground ,grey-dark1))))
   `(gnus-group-mail-3-empty ((,class (:inherit gnus-group-mail-3 :foreground ,grey-dark1))))
   `(gnus-group-mail-4-empty ((,class (:inherit gnus-group-mail-4 :foreground ,grey-dark1))))
   `(gnus-group-mail-5-empty ((,class (:inherit gnus-group-mail-5 :foreground ,grey-dark1))))
   `(gnus-group-mail-6-empty ((,class (:inherit gnus-group-mail-6 :foreground ,grey-dark1))))
   `(gnus-group-news-1 ((,class (:foreground nil :weight normal :inherit outline-5))))
   `(gnus-group-news-2 ((,class (:foreground nil :weight normal :inherit outline-6))))
   `(gnus-group-news-3 ((,class (:foreground nil :weight normal :inherit outline-7))))
   `(gnus-group-news-4 ((,class (:foreground nil :weight normal :inherit outline-8))))
   `(gnus-group-news-5 ((,class (:foreground nil :weight normal :inherit outline-1))))
   `(gnus-group-news-6 ((,class (:foreground nil :weight normal :inherit outline-2))))
   `(gnus-group-news-1-empty ((,class (:inherit gnus-group-news-1 :foreground ,grey-dark1))))
   `(gnus-group-news-2-empty ((,class (:inherit gnus-group-news-2 :foreground ,grey-dark1))))
   `(gnus-group-news-3-empty ((,class (:inherit gnus-group-news-3 :foreground ,grey-dark1))))
   `(gnus-group-news-4-empty ((,class (:inherit gnus-group-news-4 :foreground ,grey-dark1))))
   `(gnus-group-news-5-empty ((,class (:inherit gnus-group-news-5 :foreground ,grey-dark1))))
   `(gnus-group-news-6-empty ((,class (:inherit gnus-group-news-6 :foreground ,grey-dark1))))

   ;; grep
   `(grep-context-face ((,class (:foreground ,grey-dark1))))
   `(grep-error-face ((,class (:foreground ,red-dark :weight bold :underline t))))
   `(grep-hit-face ((,class (:foreground ,blue-dark))))
   `(grep-match-face ((,class (:foreground nil :background nil :inherit match))))

   ;; helm
   `(helm-M-x-key ((,class (:foreground ,orange-bright :underline t))))
   `(helm-buffer-size ((,class (:foreground ,yellow-dark))))
   `(helm-buffer-not-saved ((,class (:foreground ,yellow-dark))))
   `(helm-buffer-saved-out ((,class (:foreground ,red-dark :background ,black :inverse-video t))))
   `(helm-candidate-number ((,class (:background ,black :foreground ,yellow-bright :bold t))))
   `(helm-visible-mark ((,class (:background ,grey-dark2 :foreground ,magenta-bright :bold t))))
   `(helm-header ((,class (:inherit header-line))))
   `(helm-selection ((,class (:background ,grey-dark2 :underline t))))
   `(helm-selection-line ((,class (:background ,grey-bright1 :foreground ,yellow-bright :underline nil))))
   `(helm-separator ((,class (:foreground ,red-dark))))
   `(helm-source-header ((,class (:background ,black, :foreground ,orange-bright, :underline t, :weight bold))))
   `(helm-ff-directory ((t (:foreground ,magenta-bright))))
   `(helm-ff-symlink ((t (:foreground ,yellow-bright))))
   `(helm-buffer-directory ((t (:foreground ,magenta-bright))))
   `(helm-match ((t (:foreground ,yellow-bright))))
   `(helm-ff-prefix ((t (:foreground ,yellow-bright :weight bold))))

   ;; highlight-symbol
   `(highlight-symbol-face ((,class (:background ,yellow-dark))))

   ;; icomplete
   `(icomplete-first-match ((,class (:foreground ,grey-bright2 :bold t))))

   ;; ido
   `(ido-subdir ((,class (:foreground ,magenta-bright))))
   `(ido-first-match ((,class (:foreground ,yellow-bright))))
   `(ido-only-match ((,class (:foreground ,green-dark))))
   `(ido-indicator ((,class (:foreground ,red-dark :background ,black))))
   `(ido-virtual ((,class (:foreground ,grey-dark2))))

   ;; jabber
   `(jabber-chat-prompt-local ((,class (:foreground ,yellow-bright))))
   `(jabber-chat-prompt-foreign ((,class (:foreground ,yellow-dark))))
   `(jabber-chat-prompt-system ((,class (:foreground ,yellow-bright :weight bold))))
   `(jabber-chat-text-local ((,class (:foreground ,yellow-bright))))
   `(jabber-chat-text-foreign ((,class (:foreground ,yellow-dark))))
   `(jabber-chat-text-error ((,class (:foreground ,red-dark))))
   `(jabber-roster-user-online ((,class (:foreground ,green-dark))))
   `(jabber-roster-user-xa ((,class :foreground ,grey-dark1)))
   `(jabber-roster-user-dnd ((,class :foreground ,yellow-bright)))
   `(jabber-roster-user-away ((,class (:foreground ,yellow-dark))))
   `(jabber-roster-user-chatty ((,class (:foreground ,magenta-bright))))
   `(jabber-roster-user-error ((,class (:foreground ,red-dark))))
   `(jabber-roster-user-offline ((,class (:foreground ,grey-dark1))))
   `(jabber-rare-time-face ((,class (:foreground ,grey-dark1))))
   `(jabber-activity-face ((,class (:foreground ,magenta-bright))))
   `(jabber-activity-personal-face ((,class (:foreground ,magenta-dark))))

   ;; js2-mode
   `(js2-warning-face ((,class (:underline ,yellow-bright))))
   `(js2-error-face ((,class (:foreground nil :underline ,red-dark))))
   `(js2-external-variable-face ((,class (:foreground ,magenta-bright))))
   `(js2-function-param-face ((,class (:foreground ,blue-dark))))
   `(js2-instance-member-face ((,class (:foreground ,blue-dark))))
   `(js2-private-function-call-face ((,class (:foreground ,red-dark))))

   ;; js3-mode
   `(js3-warning-face ((,class (:underline ,yellow-bright))))
   `(js3-error-face ((,class (:foreground nil :underline ,red-dark))))
   `(js3-external-variable-face ((,class (:foreground ,magenta-bright))))
   `(js3-function-param-face ((,class (:foreground ,blue-dark))))
   `(js3-jsdoc-tag-face ((,class (:foreground ,magenta-bright))))
   `(js3-jsdoc-type-face ((,class (:foreground ,magenta-dark))))
   `(js3-jsdoc-value-face ((,class (:foreground ,magenta-bright))))
   `(js3-jsdoc-html-tag-name-face ((,class (:foreground ,blue-dark))))
   `(js3-jsdoc-html-tag-delimiter-face ((,class (:foreground ,green-dark))))
   `(js3-instance-member-face ((,class (:foreground ,blue-dark))))
   `(js3-private-function-call-face ((,class (:foreground ,red-dark))))

   ;; linum
   `(linum ((,class (:background ,grey-blue-dark))))

   ;; magit
   `(magit-branch ((,class (:foreground ,green-dark))))
   `(magit-header ((,class (:inherit nil :weight bold))))
   `(magit-item-highlight ((,class (:inherit highlight :background nil))))
   `(magit-log-graph ((,class (:foreground ,grey-dark2))))
   `(magit-log-sha1 ((,class (:foreground ,yellow-bright))))
   `(magit-log-head-label-bisect-bad ((,class (:foreground ,red-dark))))
   `(magit-log-head-label-bisect-good ((,class (:foreground ,green-dark))))
   `(magit-log-head-label-default ((,class (:foreground ,yellow-bright :box nil :weight bold))))
   `(magit-log-head-label-local ((,class (:foreground ,magenta-bright :box nil :weight bold))))
   `(magit-log-head-label-remote ((,class (:foreground ,magenta-bright :box nil :weight bold))))
   `(magit-log-head-label-tags ((,class (:foreground ,magenta-dark :box nil :weight bold))))
   `(magit-section-title ((,class (:foreground ,blue-dark :weight bold))))

   ;; magit `next'
   `(magit-section ((,class (:inherit nil))))
   `(magit-section-highlight ((,class (:background ,grey-blue-dark))))
   `(magit-section-heading ((,class (:foreground ,blue-bright))))
   `(magit-branch-local ((,class (:foreground ,turquoise-bright))))
   `(magit-branch-remote ((,class (:foreground ,yellow-bright))))
   `(magit-hash ((,class (:foreground ,grey-bright2))))
   `(magit-diff-file-heading ((,class (:foreground ,yellow-bright))))
   `(magit-diff-hunk-heading ((,class (:foreground ,magenta-bright))))
   `(magit-diff-hunk-heading-highlight ((,class (:inherit magit-diff-hunk-heading :weight bold))))
   `(magit-diff-context ((,class (:foreground ,grey-bright1))))
   `(magit-diff-context-highlight ((,class (:foreground ,grey-bright2 :background ,grey-blue-dark))))
   `(magit-diff-added ((,class (:foreground ,green-dark))))
   `(magit-diff-added-highlight ((,class (:foreground ,green-bright :background ,grey-blue-dark))))
   `(magit-diff-removed ((,class (:foreground ,red-dark))))
   `(magit-diff-removed-highlight ((,class (:foreground ,red-bright :background ,grey-blue-dark))))

   ;; markdown
   `(markdown-url-face ((,class (:inherit link))))
   `(markdown-link-face ((,class (:foreground ,blue-dark :underline t))))
   `(markdown-header-face-1 ((,class (:inherit org-level-1))))
   `(markdown-header-face-2 ((,class (:inherit org-level-2))))
   `(markdown-header-face-3 ((,class (:inherit org-level-3))))
   `(markdown-header-face-4 ((,class (:inherit org-level-4))))
   `(markdown-header-delimiter-face ((,class (:foreground ,yellow-dark))))
   `(markdown-pre-face ((,class (:foreground ,grey-bright2))))
   `(markdown-inline-code-face ((,class (:foreground ,grey-bright2))))
   `(markdown-list-face ((,class (:foreground ,magenta-dark))))

   ;; mark-multiple
   `(mm/master-face ((,class (:inherit region :foreground nil :background nil))))
   `(mm/mirror-face ((,class (:inherit region :foreground nil :background nil))))

   ;; message-mode
   `(message-header-other ((,class (:foreground nil :background nil :weight normal))))
   `(message-header-subject ((,class (:inherit message-header-other :weight bold :foreground ,yellow-bright))))
   `(message-header-to ((,class (:inherit message-header-other :weight bold :foreground ,yellow-dark))))
   `(message-header-cc ((,class (:inherit message-header-to :foreground nil))))
   `(message-header-name ((,class (:foreground ,green-dark :background nil))))
   `(message-header-newsgroups ((,class (:foreground ,magenta-dark :background nil :slant normal))))
   `(message-separator ((,class (:foreground ,magenta-bright))))

   ;; mic-paren
   `(paren-face-match ((,class (:foreground nil :background nil :inherit show-paren-match))))
   `(paren-face-mismatch ((,class (:foreground nil :background nil :inherit show-paren-mismatch))))
   `(paren-face-no-match ((,class (:foreground nil :background nil :inherit show-paren-mismatch))))

   ;; mmm-mode
   `(mmm-code-submode-face ((,class (:background ,grey-blue-dark))))
   `(mmm-comment-submode-face ((,class (:inherit font-lock-comment-face))))
   `(mmm-output-submode-face ((,class (:background ,grey-blue-dark))))

   ;; nrepl-eval-sexp-fu
   `(nrepl-eval-sexp-fu-flash ((,class (:background ,magenta-dark))))

   ;; nxml
   `(nxml-name-face ((,class (:foreground unspecified :inherit font-lock-constant-face))))
   `(nxml-attribute-local-name-face ((,class (:foreground unspecified :inherit font-lock-variable-name-face))))
   `(nxml-ref-face ((,class (:foreground unspecified :inherit font-lock-preprocessor-face))))
   `(nxml-delimiter-face ((,class (:foreground unspecified :inherit font-lock-keyword-face))))
   `(nxml-delimited-data-face ((,class (:foreground unspecified :inherit font-lock-string-face))))

   ;; org
   `(org-agenda-structure ((,class (:foreground ,blue-bright))))
   `(org-agenda-date ((,class (:foreground ,grey-bright2))))
   `(org-agenda-done ((,class (:foreground ,green-bright))))
   `(org-agenda-dimmed-todo-face ((,class (:foreground ,grey-dark1))))
   `(org-block ((,class (:background ,grey-blue-dark :inherit 'fixed-pitch))))
   `(org-code ((,class (:foreground ,grey-bright2 :inherit 'fixed-pitch))))
   `(org-column ((,class (:inherit default))))
   `(org-column-title ((,class (:inherit mode-line :foreground ,magenta-bright :weight bold :underline t))))
   `(org-date ((,class (:foreground ,blue-dark :underline t))))
   `(org-document-info ((,class (:foreground ,orange-bright))))
   `(org-document-info-keyword ((,class (:foreground ,orange-dark))))
   `(org-document-title ((,class (:weight bold :foreground ,yellow-bright :height 1.44))))
   `(org-done ((,class (:foreground ,green-bright))))
   `(org-ellipsis ((,class (:foreground ,grey-dark1))))
   `(org-footnote ((,class (:foreground ,magenta-dark))))
   `(org-formula ((,class (:foreground ,yellow-dark))))
   `(org-hide ((,class (:foreground ,black :background ,black))))
   `(org-level-1 ((,class (:foreground ,grey-bright2 :height 1.4))))
   `(org-level-2 ((,class (:foreground ,yellow-bright :height 1.3))))
   `(org-level-3 ((,class (:foreground ,magenta-bright :height 1.2))))
   `(org-level-4 ((,class (:foreground ,blue-dark :height 1.1))))
   `(org-link ((,class (:foreground ,turquoise-bright :underline t))))
   `(org-scheduled ((,class (:foreground ,yellow-dark))))
   `(org-scheduled-previously ((,class (:foreground ,yellow-dark))))
   `(org-scheduled-today ((,class (:foreground ,blue-dark))))
   `(org-special-keyword ((,class (:foreground ,yellow-dark))))
   `(org-table ((,class (:inherit org-block))))
   `(org-tag ((,class (:foreground ,magenta-bright))))
   `(org-target ((,class (:foreground ,green-dark))))
   `(org-time-grid ((,class (:inherit default))))
   `(org-todo ((,class (:foreground ,red-bright))))
   `(org-upcoming-deadline ((,class (:foreground ,yellow-bright))))
   `(org-verbatim ((,class (:inherit org-code))))
   `(org-warning ((,class (:foreground ,yellow-bright))))
   `(org-checkbox ((,class (:inherit 'fixed-pitch))))

   ;; outline
   `(outline-1 ((,class (:inherit org-level-1))))
   `(outline-2 ((,class (:inherit org-level-2))))
   `(outline-3 ((,class (:inherit org-level-3))))
   `(outline-4 ((,class (:inherit org-level-4))))

   ;; parenface
   `(paren-face ((,class (:foreground ,grey-dark2 :background nil))))

   ;; powerline
   `(powerline-active1 ((t (:foreground ,grey-bright1 :background ,grey-blue-bright))))
   `(powerline-active2 ((t (:foreground ,grey-bright1 :background ,grey-blue-dark))))

   ;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((,class (:foreground ,grey-bright1))))
   `(rainbow-delimiters-depth-2-face ((,class (:foreground ,red-dark))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground ,green-dark))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground ,blue-dark))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground ,grey-dark2))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground ,orange-dark))))
   `(rainbow-delimiters-depth-7-face ((,class (:foreground ,yellow-dark))))
   `(rainbow-delimiters-depth-8-face ((,class (:foreground ,turquoise-dark))))
   `(rainbow-delimiters-depth-9-face ((,class (:foreground ,magenta-dark))))
   `(rainbow-delimiters-unmatched-face ((,class (:background ,red-bright :weight bold))))

   ;; regex-tool
   `(regex-tool-matched-face ((,class (:foreground nil :background nil :inherit match))))
   `(regex-tool-matched-face ((,class (:foreground nil :background nil :inherit match))))

   ;; sh-script
   `(sh-heredoc ((,class (:foreground nil :inherit font-lock-string-face :weight normal))))
   `(sh-quoted-exec ((,class (:foreground nil :inherit font-lock-preprocessor-face))))

   ;; shr
   `(shr-link ((,class (:foreground ,blue-dark :underline t))))

   ;; slime
   `(slime-highlight-edits-face ((,class (:foreground ,grey-bright2))))
   `(slime-repl-input-face ((,class (:weight normal :underline nil))))
   `(slime-repl-prompt-face ((,class (:underline nil :weight bold :foreground ,magenta-bright))))
   `(slime-repl-result-face ((,class (:foreground ,green-dark))))
   `(slime-repl-output-face ((,class (:foreground ,blue-dark :background ,black))))

   ;; smart-mode-line
   `(sml/prefix ((,class (:foreground ,green-bright))))
   `(sml/folder ((,class (:foreground ,magenta-bright))))
   `(sml/filename ((,class (:foreground ,yellow-bright))))
   `(sml/vc-edited ((,class (:foreground ,orange-bright))))

   ;; undo-tree
   `(undo-tree-visualizer-default-face ((,class (:foreground ,grey-bright1))))
   `(undo-tree-visualizer-current-face ((,class (:foreground ,green-dark :weight bold))))
   `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,red-dark))))
   `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow-bright))))

   ;; web-mode
   `(web-mode-html-tag-face ((,class (:foreground ,grey-bright2))))
   `(web-mode-html-attr-name-face ((,class (:inherit font-lock-doc-face))))
   `(web-mode-doctype-face ((,class (:inherit font-lock-builtin-face))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

;; Local Variables:
;; no-byte-compile: t
;; End:

(provide-theme 'flatui-dark)

;;; flatui-dark-theme.el ends here
