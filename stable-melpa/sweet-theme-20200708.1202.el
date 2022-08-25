;;; sweet-theme.el --- Sweet-looking theme -*- lexical-binding: t; -*-

;; Copyright (C) 2020  weebojensen

;; Author: 2bruh4me
;; Keywords: faces
;; Package-Version: 20200708.1202
;; Package-Commit: ccbfdb6a17e25ab18a0b64101675bc1dfef44006
;; Version: 4
;; URL: https://github.com/2bruh4me/sweet-theme
;; Package-Requires: ((emacs "24.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Inspired by the GTK theme Sweet

;;; Code:

(deftheme sweet
  "A sweet theme inspired by the GTK theme with the same name.")

(eval-and-compile
  (defvar sweet-colors-alist
    (let* ((256color  (eq (display-color-cells (selected-frame)) 256))
           (colors `(("sweet-accent"   . (if ,256color "197" "#fc1c5b"))
                     ("sweet-fg"       . (if ,256color "252" "#b8c0d4"))
                     ("sweet-bg"       . (if ,256color "236" "#222235"))
                     ("sweet-bg-1"     . (if ,256color "237" "#292235"))
                     ("sweet-bg-hl"    . (if ,256color "238" "#28283f"))
                     ("sweet-gutter"   . "#a2a9ba")
                     ("sweet-mono-1"   . "#a2a9ba")
                     ("sweet-mono-2"   . "#bfc2e6")
                     ("sweet-mono-3"   . "#808693")
                     ("sweet-pink"     . "#f561ab")
                     ("sweet-blue"     . "#06c993")
                     ("sweet-purple"   . "#e17df3")
                     ("sweet-green"    . "#06c993")
                     ("sweet-red-1"    . "#f6717e")
                     ("sweet-red-2"    . "#ff4769")
                     ("sweet-orange-1" . "#f6ce55")
                     ("sweet-orange-2" . "#c7be5a")
                     ("sweet-gray"     . "#49505f")
                     ("sweet-silver"   . "#a3a3ff")
                     ("sweet-black"    . "#13131e")
                     ("sweet-border"   . "#19191e"))))
      colors)))

(defmacro sweet-with-color-variables (&rest body)
  "Bind the colors list around BODY."
  (declare (indent 0))
  `(let ((class '((class color) (min-colors 89)))
         ,@ (mapcar (lambda (cons)
                      (list (intern (car cons)) (cdr cons)))
                    sweet-colors-alist))
     ,@body))

(sweet-with-color-variables
  (custom-theme-set-faces 'sweet
                          `(default ((t (:foreground ,sweet-fg :background ,sweet-bg))))
                          `(success ((t (:foreground ,sweet-green))))
                          `(warning ((t (:foreground ,sweet-orange-2))))
                          `(error ((t (:foreground ,sweet-red-1 :weight bold))))
                          `(link ((t (:foreground ,sweet-blue :underline t :weight bold))))
                          `(link-visited ((t (:foreground ,sweet-blue :underline t :weight normal))))
                          `(cursor ((t (:background ,sweet-accent))))
                          `(fringe ((t (:background ,sweet-bg))))
                          `(region ((t (:background ,sweet-gray :distant-foreground ,sweet-mono-2))))
                          `(highlight ((t (:background ,sweet-gray :distant-foreground ,sweet-mono-2))))
                          `(hl-line ((t (:background ,sweet-bg-hl :distant-foreground nil))))
                          `(header-line ((t (:background ,sweet-black))))
                          `(vertical-border ((t (:background ,sweet-border :foreground ,sweet-border))))
                          `(secondary-selection ((t (:background ,sweet-bg-1))))
                          `(query-replace ((t (:inherit (isearch)))))
                          `(minibuffer-prompt ((t (:foreground ,sweet-silver))))
                          `(tooltip ((t (:foreground ,sweet-fg :background ,sweet-bg-1 :inherit variable-pitch))))

                          `(font-lock-builtin-face ((t (:foreground ,sweet-pink))))
                          `(font-lock-comment-face ((t (:foreground ,sweet-mono-3 :slant italic))))
                          `(font-lock-comment-delimiter-face ((default (:inherit (font-lock-comment-face)))))
                          `(font-lock-doc-face ((t (:inherit (font-lock-string-face)))))
                          `(font-lock-function-name-face ((t (:foreground ,sweet-blue))))
                          `(font-lock-keyword-face ((t (:foreground ,sweet-purple :weight normal))))
                          `(font-lock-preprocessor-face ((t (:foreground ,sweet-mono-2))))
                          `(font-lock-string-face ((t (:foreground ,sweet-green))))
                          `(font-lock-type-face ((t (:foreground ,sweet-orange-2))))
                          `(font-lock-constant-face ((t (:foreground ,sweet-pink))))
                          `(font-lock-variable-name-face ((t (:foreground ,sweet-red-1))))
                          `(font-lock-warning-face ((t (:foreground ,sweet-mono-3 :bold t))))
                          `(font-lock-negation-char-face ((t (:foreground ,sweet-pink :bold t))))

                          ;; mode-line
                          `(mode-line ((t (:background ,sweet-black :foreground ,sweet-silver :box (:color ,sweet-border :line-width 1)))))
                          `(mode-line-buffer-id ((t (:weight bold))))
                          `(mode-line-emphasis ((t (:weight bold))))
                          `(mode-line-inactive ((t (:background ,sweet-border :foreground ,sweet-gray :box (:color ,sweet-border :line-width 1)))))

                          ;; window-divider
                          `(window-divider ((t (:foreground ,sweet-border))))
                          `(window-divider-first-pixel ((t (:foreground ,sweet-border))))
                          `(window-divider-last-pixel ((t (:foreground ,sweet-border))))

                          ;; custom
                          `(custom-state ((t (:foreground ,sweet-green))))

                          ;; ido
                          `(ido-first-match ((t (:foreground ,sweet-purple :weight bold))))
                          `(ido-only-match ((t (:foreground ,sweet-red-1 :weight bold))))
                          `(ido-subdir ((t (:foreground ,sweet-blue))))
                          `(ido-virtual ((t (:foreground ,sweet-mono-3))))

                          ;; ace-jump
                          `(ace-jump-face-background ((t (:foreground ,sweet-mono-3 :background ,sweet-bg-1 :inverse-video nil))))
                          `(ace-jump-face-foreground ((t (:foreground ,sweet-red-1 :background ,sweet-bg-1 :inverse-video nil))))

                          ;; ace-window
                          `(aw-background-face ((t (:inherit font-lock-comment-face))))
                          `(aw-leading-char-face ((t (:foreground ,sweet-red-1 :weight bold))))

                          ;; centaur-tabs
                          `(centaur-tabs-default ((t (:background ,sweet-black :foreground ,sweet-black))))
                          `(centaur-tabs-selected ((t (:background ,sweet-bg :foreground ,sweet-fg :weight bold))))
                          `(centaur-tabs-unselected ((t (:background ,sweet-black :foreground ,sweet-fg :weight light))))
                          `(centaur-tabs-selected-modified ((t (:background ,sweet-bg
                                                                            :foreground ,sweet-blue :weight bold))))
                          `(centaur-tabs-unselected-modified ((t (:background ,sweet-black :weight light
                                                                              :foreground ,sweet-blue))))
                          `(centaur-tabs-active-bar-face ((t (:background ,sweet-accent))))
                          `(centaur-tabs-modified-marker-selected ((t (:inherit 'centaur-tabs-selected :foreground,sweet-accent))))
                          `(centaur-tabs-modified-marker-unselected ((t (:inherit 'centaur-tabs-unselected :foreground,sweet-accent))))

                          ;; company-mode
                          `(company-tooltip ((t (:foreground ,sweet-fg :background ,sweet-bg-1))))
                          `(company-tooltip-annotation ((t (:foreground ,sweet-mono-2 :background ,sweet-bg-1))))
                          `(company-tooltip-annotation-selection ((t (:foreground ,sweet-mono-2 :background ,sweet-gray))))
                          `(company-tooltip-selection ((t (:foreground ,sweet-fg :background ,sweet-gray))))
                          `(company-tooltip-mouse ((t (:background ,sweet-gray))))
                          `(company-tooltip-common ((t (:foreground ,sweet-orange-2 :background ,sweet-bg-1))))
                          `(company-tooltip-common-selection ((t (:foreground ,sweet-orange-2 :background ,sweet-gray))))
                          `(company-preview ((t (:background ,sweet-bg))))
                          `(company-preview-common ((t (:foreground ,sweet-orange-2 :background ,sweet-bg))))
                          `(company-scrollbar-fg ((t (:background ,sweet-mono-1))))
                          `(company-scrollbar-bg ((t (:background ,sweet-bg-1))))
                          `(company-template-field ((t (:inherit highlight))))

                          ;; doom-modeline
                          `(doom-modeline-bar ((t (:background ,sweet-accent))))

                          ;; flyspell
                          `(flyspell-duplicate ((t (:underline (:color ,sweet-orange-1 :style wave)))))
                          `(flyspell-incorrect ((t (:underline (:color ,sweet-red-1 :style wave)))))

                          ;; flymake
                          `(flymake-error ((t (:underline (:color ,sweet-red-1 :style wave)))))
                          `(flymake-note ((t (:underline (:color ,sweet-green :style wave)))))
                          `(flymake-warning ((t (:underline (:color ,sweet-orange-1 :style wave)))))

                          ;; flycheck
                          `(flycheck-error ((t (:underline (:color ,sweet-red-1 :style wave)))))
                          `(flycheck-info ((t (:underline (:color ,sweet-green :style wave)))))
                          `(flycheck-warning ((t (:underline (:color ,sweet-orange-1 :style wave)))))

                          ;; compilation
                          `(compilation-face ((t (:foreground ,sweet-fg))))
                          `(compilation-line-number ((t (:foreground ,sweet-mono-2))))
                          `(compilation-column-number ((t (:foreground ,sweet-mono-2))))
                          `(compilation-mode-line-exit ((t (:inherit compilation-info :weight bold))))
                          `(compilation-mode-line-fail ((t (:inherit compilation-error :weight bold))))

                          ;; isearch
                          `(isearch ((t (:foreground ,sweet-bg :background ,sweet-purple))))
                          `(isearch-fail ((t (:foreground ,sweet-red-2 :background nil))))
                          `(lazy-highlight ((t (:foreground ,sweet-purple :background ,sweet-bg-1 :underline ,sweet-purple))))

                          ;; diff-hl (https://github.com/dgutov/diff-hl)
                          '(diff-hl-change ((t (:foreground "#E9C062" :background "#8b733a"))))
                          '(diff-hl-delete ((t (:foreground "#CC6666" :background "#7a3d3d"))))
                          '(diff-hl-insert ((t (:foreground "#A8FF60" :background "#547f30"))))

                          ;; dired-mode
                          '(dired-directory ((t (:inherit (font-lock-keyword-face)))))
                          '(dired-flagged ((t (:inherit (diff-hl-delete)))))
                          '(dired-symlink ((t (:foreground "#FD5FF1"))))

                          ;; dired-async
                          `(dired-async-failures ((t (:inherit error))))
                          `(dired-async-message ((t (:inherit success))))
                          `(dired-async-mode-message ((t (:foreground ,sweet-orange-1))))

                          ;; helm
                          `(helm-header ((t (:foreground ,sweet-mono-2
                                                         :background ,sweet-bg
                                                         :underline nil
                                                         :box (:line-width 6 :color ,sweet-bg)))))
                          `(helm-source-header ((t (:foreground ,sweet-orange-2
                                                                :background ,sweet-bg
                                                                :underline nil
                                                                :weight bold
                                                                :box (:line-width 6 :color ,sweet-bg)))))
                          `(helm-selection ((t (:background ,sweet-gray))))
                          `(helm-selection-line ((t (:background ,sweet-gray))))
                          `(helm-visible-mark ((t (:background ,sweet-bg :foreground ,sweet-orange-2))))
                          `(helm-candidate-number ((t (:foreground ,sweet-green :background ,sweet-bg-1))))
                          `(helm-separator ((t (:background ,sweet-bg :foreground ,sweet-red-1))))
                          `(helm-M-x-key ((t (:foreground ,sweet-orange-1))))
                          `(helm-bookmark-addressbook ((t (:foreground ,sweet-orange-1))))
                          `(helm-bookmark-directory ((t (:foreground nil :background nil :inherit helm-ff-directory))))
                          `(helm-bookmark-file ((t (:foreground nil :background nil :inherit helm-ff-file))))
                          `(helm-bookmark-gnus ((t (:foreground ,sweet-purple))))
                          `(helm-bookmark-info ((t (:foreground ,sweet-green))))
                          `(helm-bookmark-man ((t (:foreground ,sweet-orange-2))))
                          `(helm-bookmark-w3m ((t (:foreground ,sweet-purple))))
                          `(helm-match ((t (:foreground ,sweet-orange-2))))
                          `(helm-ff-directory ((t (:foreground ,sweet-pink :background ,sweet-bg :weight bold))))
                          `(helm-ff-file ((t (:foreground ,sweet-fg :background ,sweet-bg :weight normal))))
                          `(helm-ff-executable ((t (:foreground ,sweet-green :background ,sweet-bg :weight normal))))
                          `(helm-ff-invalid-symlink ((t (:foreground ,sweet-red-1 :background ,sweet-bg :weight bold))))
                          `(helm-ff-symlink ((t (:foreground ,sweet-orange-2 :background ,sweet-bg :weight bold))))
                          `(helm-ff-prefix ((t (:foreground ,sweet-bg :background ,sweet-orange-2 :weight normal))))
                          `(helm-buffer-not-saved ((t (:foreground ,sweet-red-1))))
                          `(helm-buffer-process ((t (:foreground ,sweet-mono-2))))
                          `(helm-buffer-saved-out ((t (:foreground ,sweet-fg))))
                          `(helm-buffer-size ((t (:foreground ,sweet-mono-2))))
                          `(helm-buffer-directory ((t (:foreground ,sweet-purple))))
                          `(helm-grep-cmd-line ((t (:foreground ,sweet-pink))))
                          `(helm-grep-file ((t (:foreground ,sweet-fg))))
                          `(helm-grep-finish ((t (:foreground ,sweet-green))))
                          `(helm-grep-lineno ((t (:foreground ,sweet-mono-2))))
                          `(helm-grep-finish ((t (:foreground ,sweet-red-1))))
                          `(helm-grep-match ((t (:foreground nil :background nil :inherit helm-match))))
                          `(helm-swoop-target-line-block-face ((t (:background ,sweet-mono-3 :foreground "#222222"))))
                          `(helm-swoop-target-line-face ((t (:background ,sweet-mono-3 :foreground "#222222"))))
                          `(helm-swoop-target-word-face ((t (:background ,sweet-purple :foreground "#ffffff"))))
                          `(helm-locate-finish ((t (:foreground ,sweet-green))))
                          `(info-menu-star ((t (:foreground ,sweet-red-1))))

                          ;; ivy
                          `(ivy-confirm-face ((t (:inherit minibuffer-prompt :foreground ,sweet-green))))
                          `(ivy-current-match ((t (:background ,sweet-gray :weight normal))))
                          `(ivy-highlight-face ((t (:inherit font-lock-builtin-face))))
                          `(ivy-match-required-face ((t (:inherit minibuffer-prompt :foreground ,sweet-red-1))))
                          `(ivy-minibuffer-match-face-1 ((t (:background ,sweet-bg-hl))))
                          `(ivy-minibuffer-match-face-2 ((t (:inherit ivy-minibuffer-match-face-1 :background ,sweet-black :foreground ,sweet-purple :weight semi-bold))))
                          `(ivy-minibuffer-match-face-3 ((t (:inherit ivy-minibuffer-match-face-2 :background ,sweet-black :foreground ,sweet-green :weight semi-bold))))
                          `(ivy-minibuffer-match-face-4 ((t (:inherit ivy-minibuffer-match-face-2 :background ,sweet-black :foreground ,sweet-orange-2 :weight semi-bold))))
                          `(ivy-minibuffer-match-highlight ((t (:inherit ivy-current-match))))
                          `(ivy-modified-buffer ((t (:inherit default :foreground ,sweet-orange-1))))
                          `(ivy-virtual ((t (:inherit font-lock-builtin-face :slant italic))))

                          ;; counsel
                          `(counsel-key-binding ((t (:foreground ,sweet-orange-2 :weight bold))))

                          ;; swiper
                          `(swiper-match-face-1 ((t (:inherit ivy-minibuffer-match-face-1))))
                          `(swiper-match-face-2 ((t (:inherit ivy-minibuffer-match-face-2))))
                          `(swiper-match-face-3 ((t (:inherit ivy-minibuffer-match-face-3))))
                          `(swiper-match-face-4 ((t (:inherit ivy-minibuffer-match-face-4))))

                          ;; git-commit
                          `(git-commit-comment-action  ((t (:foreground ,sweet-green :weight bold))))
                          `(git-commit-comment-branch  ((t (:foreground ,sweet-blue :weight bold))))
                          `(git-commit-comment-heading ((t (:foreground ,sweet-orange-2 :weight bold))))

                          ;; git-gutter
                          `(git-gutter:added ((t (:foreground ,sweet-green :weight bold))))
                          `(git-gutter:deleted ((t (:foreground ,sweet-red-1 :weight bold))))
                          `(git-gutter:modified ((t (:foreground ,sweet-orange-1 :weight bold))))

                          ;; eshell
                          `(eshell-ls-archive ((t (:foreground ,sweet-purple :weight bold))))
                          `(eshell-ls-backup ((t (:foreground ,sweet-orange-2))))
                          `(eshell-ls-clutter ((t (:foreground ,sweet-red-2 :weight bold))))
                          `(eshell-ls-directory ((t (:foreground ,sweet-blue :weight bold))))
                          `(eshell-ls-executable ((t (:foreground ,sweet-green :weight bold))))
                          `(eshell-ls-missing ((t (:foreground ,sweet-red-1 :weight bold))))
                          `(eshell-ls-product ((t (:foreground ,sweet-orange-2))))
                          `(eshell-ls-special ((t (:foreground "#FD5FF1" :weight bold))))
                          `(eshell-ls-symlink ((t (:foreground ,sweet-pink :weight bold))))
                          `(eshell-ls-unreadable ((t (:foreground ,sweet-mono-1))))
                          `(eshell-prompt ((t (:inherit minibuffer-prompt))))

                          ;; man
                          `(Man-overstrike ((t (:inherit font-lock-type-face :weight bold))))
                          `(Man-underline ((t (:inherit font-lock-keyword-face :slant italic :weight bold))))

                          ;; woman
                          `(woman-bold ((t (:inherit font-lock-type-face :weight bold))))
                          `(woman-italic ((t (:inherit font-lock-keyword-face :slant italic :weight bold))))

                          ;; dictionary
                          `(dictionary-button-face ((t (:inherit widget-button))))
                          `(dictionary-reference-face ((t (:inherit font-lock-type-face :weight bold))))
                          `(dictionary-word-entry-face ((t (:inherit font-lock-keyword-face :slant italic :weight bold))))

                          ;; erc
                          `(erc-error-face ((t (:inherit error))))
                          `(erc-input-face ((t (:inherit shadow))))
                          `(erc-my-nick-face ((t (:foreground ,sweet-accent))))
                          `(erc-notice-face ((t (:inherit font-lock-comment-face))))
                          `(erc-timestamp-face ((t (:foreground ,sweet-green :weight bold))))

                          ;; jabber
                          `(jabber-roster-user-online ((t (:foreground ,sweet-green))))
                          `(jabber-roster-user-away ((t (:foreground ,sweet-red-1))))
                          `(jabber-roster-user-xa ((t (:foreground ,sweet-red-2))))
                          `(jabber-roster-user-dnd ((t (:foreground ,sweet-purple))))
                          `(jabber-roster-user-chatty ((t (:foreground ,sweet-orange-2))))
                          `(jabber-roster-user-error ((t (:foreground ,sweet-red-1 :bold t))))
                          `(jabber-roster-user-offline ((t (:foreground ,sweet-mono-3))))
                          `(jabber-chat-prompt-local ((t (:foreground ,sweet-blue))))
                          `(jabber-chat-prompt-foreign ((t (:foreground ,sweet-orange-2))))
                          `(jabber-chat-prompt-system ((t (:foreground ,sweet-mono-3))))
                          `(jabber-chat-error ((t (:inherit jabber-roster-user-error))))
                          `(jabber-rare-time-face ((t (:foreground ,sweet-pink))))
                          `(jabber-activity-face ((t (:inherit jabber-chat-prompt-foreign))))
                          `(jabber-activity-personal-face ((t (:inherit jabber-chat-prompt-local))))

                          ;; eww
                          `(eww-form-checkbox ((t (:inherit eww-form-submit))))
                          `(eww-form-file ((t (:inherit eww-form-submit))))
                          `(eww-form-select ((t (:inherit eww-form-submit))))
                          `(eww-form-submit ((t (:background ,sweet-gray :foreground ,sweet-fg :box (:line-width 2 :color ,sweet-border :style released-button)))))
                          `(eww-form-text ((t (:inherit widget-field :box (:line-width 1 :color ,sweet-border)))))
                          `(eww-form-textarea ((t (:inherit eww-form-text))))
                          `(eww-invalid-certificate ((t (:foreground ,sweet-red-1))))
                          `(eww-valid-certificate ((t (:foreground ,sweet-green))))

                          ;; js2-mode
                          `(js2-error ((t (:underline (:color ,sweet-red-1 :style wave)))))
                          `(js2-external-variable ((t (:foreground ,sweet-pink))))
                          `(js2-warning ((t (:underline (:color ,sweet-orange-1 :style wave)))))
                          `(js2-function-call ((t (:inherit (font-lock-function-name-face)))))
                          `(js2-function-param ((t (:foreground ,sweet-mono-1))))
                          `(js2-jsdoc-tag ((t (:foreground ,sweet-purple))))
                          `(js2-jsdoc-type ((t (:foreground ,sweet-orange-2))))
                          `(js2-jsdoc-value((t (:foreground ,sweet-red-1))))
                          `(js2-object-property ((t (:foreground ,sweet-red-1))))

                          ;; magit
                          `(magit-section-highlight ((t (:background ,sweet-bg-hl))))
                          `(magit-section-heading ((t (:foreground ,sweet-orange-2 :weight bold))))
                          `(magit-section-heading-selection ((t (:foreground ,sweet-fg :weight bold))))
                          `(magit-diff-file-heading ((t (:weight bold))))
                          `(magit-diff-file-heading-highlight ((t (:background ,sweet-gray :weight bold))))
                          `(magit-diff-file-heading-selection ((t (:foreground ,sweet-orange-2 :background ,sweet-bg-hl :weight bold))))
                          `(magit-diff-hunk-heading ((t (:foreground ,sweet-mono-2 :background ,sweet-gray))))
                          `(magit-diff-hunk-heading-highlight ((t (:foreground ,sweet-mono-1 :background ,sweet-mono-3))))
                          `(magit-diff-hunk-heading-selection ((t (:foreground ,sweet-purple :background ,sweet-mono-3))))
                          `(magit-diff-context ((t (:foreground ,sweet-fg))))
                          `(magit-diff-context-highlight ((t (:background ,sweet-bg-1 :foreground ,sweet-fg))))
                          `(magit-diffstat-added ((t (:foreground ,sweet-green))))
                          `(magit-diffstat-removed ((t (:foreground ,sweet-red-1))))
                          `(magit-process-ok ((t (:foreground ,sweet-green))))
                          `(magit-process-ng ((t (:foreground ,sweet-red-1))))
                          `(magit-log-author ((t (:foreground ,sweet-orange-2))))
                          `(magit-log-date ((t (:foreground ,sweet-mono-2))))
                          `(magit-log-graph ((t (:foreground ,sweet-silver))))
                          `(magit-sequence-pick ((t (:foreground ,sweet-orange-2))))
                          `(magit-sequence-stop ((t (:foreground ,sweet-green))))
                          `(magit-sequence-part ((t (:foreground ,sweet-orange-1))))
                          `(magit-sequence-head ((t (:foreground ,sweet-blue))))
                          `(magit-sequence-drop ((t (:foreground ,sweet-red-1))))
                          `(magit-sequence-done ((t (:foreground ,sweet-mono-2))))
                          `(magit-sequence-onto ((t (:foreground ,sweet-mono-2))))
                          `(magit-bisect-good ((t (:foreground ,sweet-green))))
                          `(magit-bisect-skip ((t (:foreground ,sweet-orange-1))))
                          `(magit-bisect-bad ((t (:foreground ,sweet-red-1))))
                          `(magit-blame-heading ((t (:background ,sweet-bg-1 :foreground ,sweet-mono-2))))
                          `(magit-blame-hash ((t (:background ,sweet-bg-1 :foreground ,sweet-purple))))
                          `(magit-blame-name ((t (:background ,sweet-bg-1 :foreground ,sweet-orange-2))))
                          `(magit-blame-date ((t (:background ,sweet-bg-1 :foreground ,sweet-mono-3))))
                          `(magit-blame-summary ((t (:background ,sweet-bg-1 :foreground ,sweet-mono-2))))
                          `(magit-dimmed ((t (:foreground ,sweet-mono-2))))
                          `(magit-hash ((t (:foreground ,sweet-purple))))
                          `(magit-tag  ((t (:foreground ,sweet-orange-1 :weight bold))))
                          `(magit-branch-remote  ((t (:foreground ,sweet-green :weight bold))))
                          `(magit-branch-local   ((t (:foreground ,sweet-blue :weight bold))))
                          `(magit-branch-current ((t (:foreground ,sweet-blue :weight bold :box t))))
                          `(magit-head           ((t (:foreground ,sweet-blue :weight bold))))
                          `(magit-refname        ((t (:background ,sweet-bg :foreground ,sweet-fg :weight bold))))
                          `(magit-refname-stash  ((t (:background ,sweet-bg :foreground ,sweet-fg :weight bold))))
                          `(magit-refname-wip    ((t (:background ,sweet-bg :foreground ,sweet-fg :weight bold))))
                          `(magit-signature-good      ((t (:foreground ,sweet-green))))
                          `(magit-signature-bad       ((t (:foreground ,sweet-red-1))))
                          `(magit-signature-untrusted ((t (:foreground ,sweet-orange-1))))
                          `(magit-cherry-unmatched    ((t (:foreground ,sweet-pink))))
                          `(magit-cherry-equivalent   ((t (:foreground ,sweet-purple))))
                          `(magit-reflog-commit       ((t (:foreground ,sweet-green))))
                          `(magit-reflog-amend        ((t (:foreground ,sweet-purple))))
                          `(magit-reflog-merge        ((t (:foreground ,sweet-green))))
                          `(magit-reflog-checkout     ((t (:foreground ,sweet-blue))))
                          `(magit-reflog-reset        ((t (:foreground ,sweet-red-1))))
                          `(magit-reflog-rebase       ((t (:foreground ,sweet-purple))))
                          `(magit-reflog-cherry-pick  ((t (:foreground ,sweet-green))))
                          `(magit-reflog-remote       ((t (:foreground ,sweet-pink))))
                          `(magit-reflog-other        ((t (:foreground ,sweet-pink))))

                          ;; message
                          `(message-cited-text ((t (:foreground ,sweet-green))))
                          `(message-header-cc ((t (:foreground ,sweet-orange-1 :weight bold))))
                          `(message-header-name ((t (:foreground ,sweet-purple))))
                          `(message-header-newsgroups ((t (:foreground ,sweet-orange-2 :weight bold :slant italic))))
                          `(message-header-other ((t (:foreground ,sweet-red-1))))
                          `(message-header-subject ((t (:foreground ,sweet-blue))))
                          `(message-header-to ((t (:foreground ,sweet-orange-2 :weight bold))))
                          `(message-header-xheader ((t (:foreground ,sweet-silver))))
                          `(message-mml ((t (:foreground ,sweet-purple))))
                          `(message-separator ((t (:foreground ,sweet-mono-3 :slant italic))))

                          ;; epa
                          `(epa-field-body ((t (:foreground ,sweet-blue :slant italic))))
                          `(epa-field-name ((t (:foreground ,sweet-pink :weight bold))))

                          ;; notmuch
                          `(notmuch-crypto-decryption ((t (:foreground ,sweet-purple :background ,sweet-black))))
                          `(notmuch-crypto-signature-bad ((t (:foreground ,sweet-red-1 :background ,sweet-black))))
                          `(notmuch-crypto-signature-good ((t (:foreground ,sweet-green :background ,sweet-black))))
                          `(notmuch-crypto-signature-good-key ((t (:foreground ,sweet-green :background ,sweet-black))))
                          `(notmuch-crypto-signature-unknown ((t (:foreground ,sweet-orange-1 :background ,sweet-black))))
                          `(notmuch-hello-logo-background ((t (:inherit default))))
                          `(notmuch-message-summary-face ((t (:background ,sweet-black))))
                          `(notmuch-search-count ((t (:inherit default :foreground ,sweet-silver))))
                          `(notmuch-search-date ((t (:inherit default :foreground ,sweet-purple))))
                          `(notmuch-search-matching-authors ((t (:inherit default :foreground ,sweet-orange-2))))
                          `(notmuch-search-non-matching-authors ((t (:inherit font-lock-comment-face :slant italic))))
                          `(notmuch-tag-added ((t (:underline t))))
                          `(notmuch-tag-deleted ((t (:strike-through ,sweet-red-2))))
                          `(notmuch-tag-face ((t (:foreground ,sweet-green))))
                          `(notmuch-tag-unread ((t (:foreground ,sweet-red-1))))
                          `(notmuch-tree-match-author-face ((t (:inherit notmuch-search-matching-authors))))
                          `(notmuch-tree-match-date-face ((t (:inherit notmuch-search-date))))
                          `(notmuch-tree-match-face ((t (:weight semi-bold))))
                          `(notmuch-tree-match-tag-face ((t (:inherit notmuch-tag-face))))
                          `(notmuch-tree-no-match-face ((t (:slant italic :weight light :inherit font-lock-comment-face))))

                          ;; elfeed
                          `(elfeed-log-debug-level-face ((t (:background ,sweet-black :foreground ,sweet-green))))
                          `(elfeed-log-error-level-face ((t (:background ,sweet-black :foreground ,sweet-red-1))))
                          `(elfeed-log-info-level-face ((t (:background ,sweet-black :foreground ,sweet-blue))))
                          `(elfeed-log-warn-level-face ((t (:background ,sweet-black :foreground ,sweet-orange-1))))
                          `(elfeed-search-date-face ((t (:foreground ,sweet-purple))))
                          `(elfeed-search-feed-face ((t (:foreground ,sweet-orange-2))))
                          `(elfeed-search-tag-face ((t (:foreground ,sweet-green))))
                          `(elfeed-search-title-face ((t (:foreground ,sweet-mono-1))))
                          `(elfeed-search-unread-count-face ((t (:foreground ,sweet-silver))))

                          ;; perspective
                          `(persp-selected-face ((t (:foreground ,sweet-blue))))

                          ;; powerline
                          `(powerline-active1 ((,class (:background ,sweet-bg-hl :foreground ,sweet-purple))))
                          `(powerline-active2 ((,class (:background ,sweet-bg-hl :foreground ,sweet-purple))))
                          `(powerline-inactive1 ((,class (:background ,sweet-bg :foreground ,sweet-fg))))
                          `(powerline-inactive2 ((,class (:background ,sweet-bg :foreground ,sweet-fg))))

                          ;; rainbow-delimiters
                          `(rainbow-delimiters-depth-1-face ((t (:foreground ,sweet-blue))))
                          `(rainbow-delimiters-depth-2-face ((t (:foreground ,sweet-green))))
                          `(rainbow-delimiters-depth-3-face ((t (:foreground ,sweet-orange-1))))
                          `(rainbow-delimiters-depth-4-face ((t (:foreground ,sweet-pink))))
                          `(rainbow-delimiters-depth-5-face ((t (:foreground ,sweet-purple))))
                          `(rainbow-delimiters-depth-6-face ((t (:foreground ,sweet-orange-2))))
                          `(rainbow-delimiters-depth-7-face ((t (:foreground ,sweet-blue))))
                          `(rainbow-delimiters-depth-8-face ((t (:foreground ,sweet-green))))
                          `(rainbow-delimiters-depth-9-face ((t (:foreground ,sweet-orange-1))))
                          `(rainbow-delimiters-depth-10-face ((t (:foreground ,sweet-pink))))
                          `(rainbow-delimiters-depth-11-face ((t (:foreground ,sweet-purple))))
                          `(rainbow-delimiters-depth-12-face ((t (:foreground ,sweet-orange-2))))
                          `(rainbow-delimiters-unmatched-face ((t (:foreground ,sweet-red-1 :weight bold))))

                          ;; rbenv
                          `(rbenv-active-ruby-face ((t (:foreground ,sweet-green))))

                          ;; elixir
                          `(elixir-atom-face ((t (:foreground ,sweet-pink))))
                          `(elixir-attribute-face ((t (:foreground ,sweet-red-1))))

                          ;; show-paren
                          `(show-paren-match ((,class (:foreground ,sweet-purple :inherit bold :underline t))))
                          `(show-paren-mismatch ((,class (:foreground ,sweet-red-1 :inherit bold :underline t))))

                          ;; sh-mode
                          `(sh-heredoc ((t (:inherit font-lock-string-face :slant italic))))

                          ;; cider
                          `(cider-fringe-good-face ((t (:foreground ,sweet-green))))

                          ;; sly
                          `(sly-error-face ((t (:underline (:color ,sweet-red-1 :style wave)))))
                          `(sly-mrepl-note-face ((t (:inherit font-lock-comment-face))))
                          `(sly-mrepl-output-face ((t (:inherit font-lock-string-face))))
                          `(sly-mrepl-prompt-face ((t (:inherit comint-highlight-prompt))))
                          `(sly-note-face ((t (:underline (:color ,sweet-green :style wave)))))
                          `(sly-style-warning-face ((t (:underline (:color ,sweet-orange-2 :style wave)))))
                          `(sly-warning-face ((t (:underline (:color ,sweet-orange-1 :style wave)))))

                          ;; smartparens
                          `(sp-show-pair-mismatch-face ((t (:foreground ,sweet-red-1 :background ,sweet-gray :weight bold))))
                          `(sp-show-pair-match-face ((t (:background ,sweet-gray :weight bold))))

                          ;; lispy
                          `(lispy-face-hint ((t (:background ,sweet-border :foreground ,sweet-orange-2))))

                          ;; lispyville
                          `(lispyville-special-face ((t (:foreground ,sweet-red-1))))

                          ;; spaceline
                          `(spaceline-flycheck-error  ((,class (:foreground ,sweet-red-1))))
                          `(spaceline-flycheck-info   ((,class (:foreground ,sweet-green))))
                          `(spaceline-flycheck-warning((,class (:foreground ,sweet-orange-1))))
                          `(spaceline-python-venv ((,class (:foreground ,sweet-purple))))

                          ;; solaire mode
                          `(solaire-default-face ((,class (:inherit default :background ,sweet-black))))
                          `(solaire-minibuffer-face ((,class (:inherit default :background ,sweet-black))))

                          ;; web-mode
                          `(web-mode-doctype-face ((t (:inherit font-lock-comment-face))))
                          `(web-mode-error-face ((t (:background ,sweet-black :foreground ,sweet-red-1))))
                          `(web-mode-html-attr-equal-face ((t (:inherit default))))
                          `(web-mode-html-attr-name-face ((t (:foreground ,sweet-orange-1))))
                          `(web-mode-html-tag-bracket-face ((t (:inherit default))))
                          `(web-mode-html-tag-face ((t (:foreground ,sweet-red-1))))
                          `(web-mode-symbol-face ((t (:foreground ,sweet-orange-1))))

                          ;; nxml
                          `(nxml-attribute-local-name ((t (:foreground ,sweet-orange-1))))
                          `(nxml-element-local-name ((t (:foreground ,sweet-red-1))))
                          `(nxml-markup-declaration-delimiter ((t (:inherit (font-lock-comment-face nxml-delimiter)))))
                          `(nxml-processing-instruction-delimiter ((t (:inherit nxml-markup-declaration-delimiter))))

                          ;; flx-ido
                          `(flx-highlight-face ((t (:inherit (link) :weight bold))))

                          ;; rpm-spec-mode
                          `(rpm-spec-tag-face ((t (:foreground ,sweet-blue))))
                          `(rpm-spec-obsolete-tag-face ((t (:foreground "#FFFFFF" :background ,sweet-red-2))))
                          `(rpm-spec-macro-face ((t (:foreground ,sweet-orange-2))))
                          `(rpm-spec-var-face ((t (:foreground ,sweet-red-1))))
                          `(rpm-spec-doc-face ((t (:foreground ,sweet-purple))))
                          `(rpm-spec-dir-face ((t (:foreground ,sweet-pink))))
                          `(rpm-spec-package-face ((t (:foreground ,sweet-red-2))))
                          `(rpm-spec-ghost-face ((t (:foreground ,sweet-red-2))))
                          `(rpm-spec-section-face ((t (:foreground ,sweet-orange-2))))

                          ;; guix
                          `(guix-true ((t (:foreground ,sweet-green :weight bold))))
                          `(guix-build-log-phase-end ((t (:inherit success))))
                          `(guix-build-log-phase-start ((t (:inherit success :weight bold))))

                          ;; gomoku
                          `(gomoku-O ((t (:foreground ,sweet-red-1 :weight bold))))
                          `(gomoku-X ((t (:foreground ,sweet-green :weight bold))))

                          ;; term
                          `(term-color-black ((t :foreground ,sweet-mono-1)))
                          `(term-color-blue ((t (:foreground ,sweet-blue))))
                          `(term-color-cyan ((t :foreground ,sweet-pink)))
                          `(term-color-green ((t (:foreground ,sweet-green))))
                          `(term-color-magenta ((t :foreground ,sweet-purple)))
                          `(term-color-red ((t :foreground ,sweet-red-1)))
                          `(term-color-white ((t :foreground ,sweet-fg)))
                          `(term-color-yellow ((t (:foreground ,sweet-orange-1))))

                          ;; tabbar
                          `(tabbar-default ((,class (:foreground ,sweet-fg :background ,sweet-black))))
                          `(tabbar-highlight ((,class (:underline t))))
                          `(tabbar-button ((,class (:foreground ,sweet-fg :background ,sweet-bg))))
                          `(tabbar-button-highlight ((,class (:inherit 'tabbar-button :inverse-video t))))
                          `(tabbar-modified ((,class (:inherit tabbar-button :foreground ,sweet-purple :weight light :slant italic))))
                          `(tabbar-unselected ((,class (:inherit tabbar-default :foreground ,sweet-fg :background ,sweet-black :slant italic :underline nil :box (:line-width 1 :color ,sweet-bg)))))
                          `(tabbar-unselected-modified ((,class (:inherit tabbar-modified :background ,sweet-black :underline nil :box (:line-width 1 :color ,sweet-bg)))))
                          `(tabbar-selected ((,class (:inherit tabbar-default :foreground ,sweet-fg :background ,sweet-bg :weight bold :underline nil :box (:line-width 1 :color ,sweet-bg)))))
                          `(tabbar-selected-modified ((,class (:inherit tabbar-selected :foreground ,sweet-purple :underline nil :box (:line-width 1 :color ,sweet-bg)))))

                          ;; linum
                          `(linum ((t (:foreground ,sweet-gutter :background ,sweet-bg))))
                          ;; hlinum
                          `(linum-highlight-face ((t (:foreground ,sweet-fg :background ,sweet-bg))))
                          ;; native line numbers (emacs version >=26)
                          `(line-number ((t (:foreground ,sweet-gutter :background ,sweet-bg))))
                          `(line-number-current-line ((t (:foreground ,sweet-fg :background ,sweet-bg))))

                          ;; regexp-builder
                          `(reb-match-0 ((t (:background ,sweet-gray))))
                          `(reb-match-1 ((t (:background ,sweet-black :foreground ,sweet-purple :weight semi-bold))))
                          `(reb-match-2 ((t (:background ,sweet-black :foreground ,sweet-green :weight semi-bold))))
                          `(reb-match-3 ((t (:background ,sweet-black :foreground ,sweet-orange-2 :weight semi-bold))))

                          ;; desktop-entry
                          `(desktop-entry-deprecated-keyword-face ((t (:inherit font-lock-warning-face))))
                          `(desktop-entry-group-header-face ((t (:inherit font-lock-type-face))))
                          `(desktop-entry-locale-face ((t (:inherit font-lock-string-face))))
                          `(desktop-entry-unknown-keyword-face ((t (:underline (:color ,sweet-red-1 :style wave) :inherit font-lock-keyword-face))))
                          `(desktop-entry-value-face ((t (:inherit default))))

                          ;; latex-mode
                          `(font-latex-sectioning-0-face ((t (:foreground ,sweet-blue :height 1.0))))
                          `(font-latex-sectioning-1-face ((t (:foreground ,sweet-blue :height 1.0))))
                          `(font-latex-sectioning-2-face ((t (:foreground ,sweet-blue :height 1.0))))
                          `(font-latex-sectioning-3-face ((t (:foreground ,sweet-blue :height 1.0))))
                          `(font-latex-sectioning-4-face ((t (:foreground ,sweet-blue :height 1.0))))
                          `(font-latex-sectioning-5-face ((t (:foreground ,sweet-blue :height 1.0))))
                          `(font-latex-bold-face ((t (:foreground ,sweet-green :weight bold))))
                          `(font-latex-italic-face ((t (:foreground ,sweet-green))))
                          `(font-latex-warning-face ((t (:foreground ,sweet-red-1))))
                          `(font-latex-doctex-preprocessor-face ((t (:foreground ,sweet-pink))))
                          `(font-latex-script-char-face ((t (:foreground ,sweet-mono-2))))

                          ;; org-mode
                          `(org-date ((t (:foreground ,sweet-pink))))
                          `(org-document-info ((t (:foreground ,sweet-mono-2))))
                          `(org-document-info-keyword ((t (:inherit org-meta-line :underline t))))
                          `(org-document-title ((t (:weight bold))))
                          `(org-footnote ((t (:foreground ,sweet-pink))))
                          `(org-sexp-date ((t (:foreground ,sweet-pink))))

                          ;; calendar
                          `(diary ((t (:inherit warning))))
                          `(holiday ((t (:foreground ,sweet-green))))

                          ;; gud
                          `(breakpoint-disabled ((t (:foreground ,sweet-orange-1))))
                          `(breakpoint-enabled ((t (:foreground ,sweet-red-1 :weight bold))))

                          ;; realgud
                          `(realgud-overlay-arrow1        ((t (:foreground ,sweet-green))))
                          `(realgud-overlay-arrow3        ((t (:foreground ,sweet-orange-1))   `(realgud-overlay-arrow2        ((t (:foreground ,sweet-orange-2))))
                                                           ))
                          '(realgud-bp-enabled-face       ((t (:inherit (error)))))
                          `(realgud-bp-disabled-face      ((t (:inherit (secondary-selection)))))
                          `(realgud-bp-line-enabled-face  ((t (:box (:color ,sweet-red-1)))))
                          `(realgud-bp-line-disabled-face ((t (:box (:color ,sweet-gray)))))
                          `(realgud-line-number           ((t (:foreground ,sweet-mono-2))))
                          `(realgud-backtrace-number      ((t (:inherit (secondary-selection)))))

                          ;; rmsbolt
                          `(rmsbolt-current-line-face ((t (:inherit hl-line :weight bold))))

                          ;; ruler-mode
                          `(ruler-mode-column-number ((t (:inherit ruler-mode-default))))
                          `(ruler-mode-comment-column ((t (:foreground ,sweet-red-1))))
                          `(ruler-mode-current-column ((t (:foreground ,sweet-accent :inherit ruler-mode-default))))
                          `(ruler-mode-default ((t (:inherit mode-line))))
                          `(ruler-mode-fill-column ((t (:foreground ,sweet-orange-1 :inherit ruler-mode-default))))
                          `(ruler-mode-fringes ((t (:foreground ,sweet-green :inherit ruler-mode-default))))
                          `(ruler-mode-goal-column ((t (:foreground ,sweet-pink :inherit ruler-mode-default))))
                          `(ruler-mode-margins ((t (:inherit ruler-mode-default))))
                          `(ruler-mode-tab-stop ((t (:foreground ,sweet-mono-3 :inherit ruler-mode-default))))

                          ;; undo-tree
                          `(undo-tree-visualizer-current-face ((t (:foreground ,sweet-red-1))))
                          `(undo-tree-visualizer-register-face ((t (:foreground ,sweet-orange-1))))
                          `(undo-tree-visualizer-unmodified-face ((t (:foreground ,sweet-pink))))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'sweet)

;;; sweet-theme.el ends here
