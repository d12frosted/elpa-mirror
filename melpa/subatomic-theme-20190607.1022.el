;;; subatomic-theme.el --- Low contrast bluish color theme

;; Copyright (C) 2012, 2013, 2014, 2015, 2016 John Olsson

;; Author: John Olsson <john@cryon.se>
;; Maintainer: John Olsson <john@cryon.se>
;; URL: https://github.com/cryon/subatomic
;; Package-Version: 20190607.1022
;; Package-Commit: a13cdac97a6d0488b13bc36d4c2f4d4102ff6a31
;; Created: 25th December 2012
;; Version: 1.8.1
;; Keywords: color-theme, blue, low contrast

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A low contrast bluish color theme. A high contrast mode can be toggled in the
;; "subatomic" customization group.

;;; Code:

(deftheme subatomic
  "subatomic emacs theme")

(defgroup subatomic nil
  "Subatomic theme options.
The theme has to be reloaded after changing anything in this group."
  :group 'faces)

(defcustom subatomic-high-contrast nil
  "Makes the general contrast higher by setting the background as black."
  :type 'boolean
  :group 'subatomic)

(defcustom subatomic-more-visible-comment-delimiters nil
  "Makes the comment delimiter characters the same color as the rest of the comment"
  :type 'boolean
  :group 'subatomic)

(let ((midnight          (if subatomic-high-contrast "#000000" "#303347"))
      (midnight-1        "#2e3043")
      (midnight-2        "#2a2c3e")
      (midnight-3        "#232533")
      (midnight-red      "#421d17")
      (mystic-blue       "#696e92")
      (victory-blue      "#8aa6bc")
      (victory-blue+1    "#9dbbd3")
      (jungle-green      "#a9dc69")
      (undergrowth-green "#81a257")
      (contrast-green    "#22aa22")
      (deep-gold         "#f9b529")
      (bright-gold       "#ffd700")
      (axiomatic-purple  "#9c71a5")
      (brick-red         "#ea8673")
      (contrast-red      "#aa2222")
      (piggy-pink        "#feccd4")
      (relaxed-white     "#e5e5e5")
      (cold-mud          "#cebca5")

      (full-white        "#ffffff")
      (full-black        "#000000")
      (full-red          "#ff0000")
      (full-green        "#00ff00")
      (full-blue         "#0000ff")
      (full-yellow       "#ffff00")
      (full-magenta      "#ff00ff")
      (full-cyan         "#00ffff"))
  (custom-theme-set-faces
   'subatomic

   ;; default stuff

   `(default
      ((t (:background ,midnight :foreground ,relaxed-white))))

   `(fringe
     ((t (:background ,midnight))))

   `(linum
     ((t (:background ,midnight :foreground ,mystic-blue))))

   `(vertical-border
     ((t (:foreground ,midnight-2))))

   `(region
     ((t (:background ,mystic-blue :foreground ,full-white))))

   `(show-paren-match-face
     ((t (:foreground ,full-green :bold t))))

   `(show-paren-mismatch-face
     ((t (:foreground ,full-red :bold t))))

   `(isearch
     ((t (:background ,midnight-2 :foreground ,full-green :bold t))))

   `(lazy-highlight
     ((t (:background ,midnight-2 :foreground ,deep-gold :bold t))))

   `(query-replace
     ((t (:inherit lazy-highlight))))

   `(trailing-whitespace
     ((t (:inherit show-paren-mismatch-face :underline t))))

   `(mode-line
     ((t (:background ,midnight-3 :foreground ,full-white :weight bold
                      :box (:line-width 1 :style released-button)))))

   `(powerline-active1
     ((t (:background ,midnight-2))))

   `(powerline-active2
     ((t (:background ,midnight-1))))

   `(mode-line-inactive
     ((t (:background ,midnight-2 :foreground ,mystic-blue))))

   `(powerline-inactive1
     ((t (:background ,midnight-2))))

   `(powerline-inactive2
     ((t (:background ,midnight-1))))

   `(header-line
     ((t (:background ,midnight-3 :foreground ,full-white :weight bold))))

   `(hl-line
     ((t (:background ,(if subatomic-high-contrast midnight-3 midnight-1)))))

   `(highlight-current-line-face
     ((t (:inherit hl-line))))

   `(minibuffer-prompt
     ((t (:foreground ,axiomatic-purple :weight bold))))

   `(escape-glyph
     ((t (:foreground ,cold-mud :weight bold))))

   `(link
     ((t (:foreground ,victory-blue+1 :weight bold :underline t))))

   ;; font lock

   `(font-lock-keyword-face
     ((t (:foreground ,deep-gold :weight bold))))

   `(font-lock-function-name-face
     ((t (:foreground ,victory-blue))))

   `(font-lock-warning-face
     ((t (:foreground ,brick-red))))

   `(font-lock-builtin-face
     ((t (:foreground ,deep-gold))))

   `(font-lock-variable-name-face
     ((t (:foreground ,victory-blue))))

   `(font-lock-constant-face
     ((t (:foreground ,full-white, :weight bold :italic t))))

   `(font-lock-type-face
     ((t (:foreground ,victory-blue+1 :weight bold))))

   `(font-lock-negation-char-face
     ((t (:foreground ,brick-red :weight bold))))

   `(font-lock-preprocessor-face
     ((t (:foreground ,cold-mud))))

   `(font-lock-comment-face
     ((t (:foreground ,mystic-blue))))

   `(font-lock-string-face
     ((t (:foreground ,jungle-green))))

   `(font-lock-comment-delimiter-face
     ((t (:foreground ,(if subatomic-more-visible-comment-delimiters
                           mystic-blue
                         midnight-3)))))

   `(font-lock-doc-face
     ((t (:foreground ,axiomatic-purple :italic t))))

   ;; flymake

   `(flymake-errline
     ((t (:underline ,full-red))))

   `(flymake-warnline
     ((t (:underline ,full-yellow))))

   ;; eshell

   `(eshell-ls-clutter
     ((t (:inherit font-lock-comment-face))))

   `(eshell-ls-executable
     ((t (:foreground ,jungle-green))))

   `(eshell-ls-directory
     ((t (:foreground ,victory-blue :bold t))))

   `(eshell-ls-archive
     ((t (:foreground ,deep-gold))))

   `(eshell-ls-backup
     ((t (:inherit font-lock-comment-face))))

   `(eshell-ls-missing
     ((t (:inherit font-lock-warning-face))))

   `(eshell-ls-unreadable
     ((t (:inherit font-lock-warning-face))))

   `(eshell-ls-symlink
     ((t (:inherit font-lock-builtin-face))))

   `(eshell-prompt
     ((t (:inherit minibuffer-prompt))))

   `(eshell-ls-backup
     ((t (:foreground ,brick-red :slant italic))))

   `(eshell-ls-product
     ((t (:inherit default :weight bold))))

   `(eshell-ls-readonly
     ((t (:inherit font-lock-comment))))

   `(eshell-ls-special
     ((t (:foreground ,cold-mud))))

   ;; calendar

   `(calendar-today-face
     ((t (:foreground ,jungle-green :bold t))))

   `(holiday-face
     ((t (:foreground ,brick-red))))

   `(diary-face
     ((t (:foreground ,axiomatic-purple))))

   ;; ido-mode

   `(ido-subdir
     ((t (:inherit eshell-ls-directory))))

   `(ido-only-match
     ((t (:foreground ,jungle-green :bold t))))

   `(ido-first-match
     ((t (:foreground ,deep-gold :bold t))))

   `(ido-virtual
     ((t (:inherit font-lock-comment-face))))

   ;; Can't really figure out what these are for...

   ;;   `(ido-indicator
   ;;     ((t (:foreground ,brick-red :bold t))))
   ;;
   ;;   `(ido-inclomplete-regexp
   ;;     ((t (:foreground ,piggy-pink))))

   ;; jabber

   `(jabber-roster-user-online
     ((t (:foreground ,jungle-green))))

   `(jabber-roster-user-offline
     ((t (:foreground ,mystic-blue))))

   `(jabber-roster-user-dnd
     ((t (:foreground ,brick-red))))

   `(jabber-roster-user-away
     ((t (:foreground ,cold-mud))))

   `(jabber-roster-user-chatty
     ((t (:foreground ,victory-blue+1 :bold t))))

   `(jabber-roster-user-xa
     ((t (:foreground ,brick-red))))

   `(jabber-roster-user-error
     ((t (:foreground ,full-red))))

   `(jabber-chat-prompt-local
     ((t (:foreground ,victory-blue+1))))

   `(jabber-chat-prompt-foreign
     ((t (:foreground ,cold-mud))))

   `(jabber-chat-text-local
     ((t (:foreground ,relaxed-white))))

   `(jabber-chat-text-foreign
     ((t (:foreground ,relaxed-white))))

   `(jabber-rare-time-face
     ((t (:foreground ,mystic-blue :bold t))))

   `(jabber-activity-face
     ((t (:foreground ,deep-gold :bold t))))

   `(jabber-activity-personal-face
     ((t (:foreground ,cold-mud :bold t))))

   `(jabber-chat-error
     ((t (:foreground ,full-red))))

   `(jabber-chat-prompt-system
     ((t (:foreground ,full-red))))

   `(jabber-title-large
     ((t (:foreground ,deep-gold :height 1.3 :bold t))))

   `(jabber-title-medium
     ((t (:foreground ,deep-gold :bold t))))

   `(jabber-title-small
     ((t (:foreground ,deep-gold))))

   ;; erc

   `(erc-default-face
     ((t (:inherit default))))

   `(erc-current-nick-face
     ((t (:inherit font-lock-keyword-face))))

   `(erc-action-face
     ((t (:foreground ,cold-mud))))

   `(erc-dangerous-host-face
     ((t (:inherit font-lock-warning-face))))

   `(erc-highlight-face
     ((t (:weight bold))))

   `(erc-direct-msg-face
     ((t (:foreground ,jungle-green))))

   `(erc-nick-msg-face
     ((t (:foreground ,victory-blue+1 :weight bold))))

   `(erc-fool-face
     ((t (:inherit font-lock-comment-face))))

   `(erc-input-face
     ((t (:inherit default :weight bold))))

   `(erc-error-face
     ((t (:inherit font-lock-warning-face))))

   `(erc-keyword-face
     ((t (:inherit font-lock-keyword-face))))

   `(erc-nick-default-face
     ((t (:inherit default))))

   `(erc-prompt-face
     ((t (:inherit eshell-prompt))))

   `(erc-notice-face
     ((t (:foreground ,axiomatic-purple))))

   `(erc-timestamp-face
     ((t (:inherit font-lock-comment-face))))

   `(erc-pal-face
     ((t (:foreground ,jungle-green))))

   ;; highlight-symbol

   `(highlight-symbol-face
     ((t (:background ,midnight-3))))

   ;; diff

   `(diff-file-header
     ((t (:background ,midnight :foreground ,relaxed-white :weight bold))))

   `(diff-header
     ((t (:inherit default :foreground ,mystic-blue))))

   `(diff-indicator-changed
     ((t (:foreground ,full-yellow :weight bold))))

   `(diff-changed
     ((t (:foreground ,deep-gold))))

   `(diff-indicator-removed
     ((t (:foreground ,full-red :weight bold))))

   `(diff-removed
     ((t (:foreground ,brick-red))))

   `(diff-indicator-added
     ((t (:foreground ,full-green :weight bold))))

   `(diff-added
     ((t (:foreground ,jungle-green))))

   `(diff-hunk-header
     ((t (:foreground ,axiomatic-purple))))

   `(diff-refine-removed
     ((t (:background ,contrast-red :foreground ,relaxed-white :weight bold))))

   `(diff-refine-added
     ((t (:background ,contrast-green :foreground ,relaxed-white :weight bold))))

   `(diff-refine-change
     ((t (:background ,deep-gold :foreground ,relaxed-white :weight bold))))

   ;; magit (new faces since 2.1.0)
   ;; there may be some duplication with the older magit faces.
   ;; they should be merged over time.

   `(magit-bisect-bad
     ((t (:foreground ,brick-red))))

   `(magit-bisect-good
     ((t (:foreground ,jungle-green))))

   `(magit-bisect-skip
     ((t (:inherit default))))

   `(magit-blame-date
     ((t (:foreground ,cold-mud :background ,midnight-3))))

   `(magit-blame-hash
     ((t (:foreground ,mystic-blue :background ,midnight-3))))

   `(magit-blame-heading
     ((t (:background ,midnight-3))))

   `(magit-blame-name
     ((t (:foreground ,jungle-green :background ,midnight-3 :bold t))))

   `(magit-blame-summary
     ((t (:foreground ,relaxed-white :background ,midnight-3 :bold t))))

   `(magit-branch-current
     ((t (:foreground ,jungle-green :weight bold :underline t))))

   `(magit-branch-local
     ((t (:foreground ,jungle-green))))

   `(magit-branch-remote
     ((t (:foreground ,cold-mud))))

   ;;`(magit-cherry-equivalent ((t (:inherit default))))
   ;;`(magit-cherry-unmatched ((t (:inherit default))))

   `(magit-diff-added
     ((t (:inherit diff-added))))

   `(magit-diff-added-highlight
     ((t (:inherit magit-diff-added
          :background ,(if subatomic-high-contrast midnight-3 midnight-1)))))

   ;;`(magit-diff-base ((t (:inherit default))))
   ;;`(magit-diff-base-highlight ((t (:inherit default))))
   ;;`(magit-diff-conflict-heading ((t (:inherit default))))

   `(magit-diff-context
     ((t (:inherit default))))

   `(magit-diff-context-highlight
     ((t (:inherit magit-diff-context
          :background ,(if subatomic-high-contrast midnight-3 midnight-1)))))

   `(magit-diff-file-heading
     ((t (:inherit diff-file-header))))

   ;;`(magit-diff-file-heading-highlight ((t (:inherit default))))

   `(magit-diff-file-heading-selection
     ((t (:inherit default))))

   `(magit-diff-hunk-heading
     ((t (:inherit diff-hunk-header))))

   `(magit-diff-hunk-heading-highlight
     ((t (:inherit hunk-heading-highlight
          :background ,(if subatomic-high-contrast midnight-3 midnight-1)))))

   `(magit-diff-hunk-heading-selection
     ((t (:inherit magit-diff-hunk-heading-highlight))))

   `(magit-diff-lines-boundary
     ((t (:inherit region))))

   `(magit-diff-lines-heading
     ((t (:inherit magit-diff-hunk-heading-highlight))))

   ;;`(magit-diff-our ((t (:inherit default))))
   ;;`(magit-diff-our-highlight ((t (:inherit default))))

   `(magit-diff-removed
     ((t (:inherit diff-removed))))

   `(magit-diff-removed-highlight
     ((t (:inherit magit-diff-removed
          :background ,(if subatomic-high-contrast midnight-3 midnight-1)))))

   ;;`(magit-diff-their ((t (:inherit default))))
   ;;`(magit-diff-their-highlight ((t (:inherit default))))

   `(magit-diff-whitespace-warning
     ((t (:inherit trailing-whitespace))))

   `(magit-diffstat-added
     ((t (:foreground ,jungle-green))))

   `(magit-diffstat-removed
     ((t (:foreground ,brick-red))))

   `(magit-dimmed
     ((t (:inherit font-lock-comment-face))))

   ;;`(magit-filename ((t (:inherit default))))

   `(magit-hash
     ((t (:foreground ,victory-blue :weight bold))))

   ;;`(magit-head ((t (:inherit default))))
   ;;`(magit-header-line ((t (:inherit default))))
   ;;`(magit-log-author ((t (:inherit default))))
   ;;`(magit-log-date ((t (:inherit default))))
   ;;`(magit-log-graph ((t (:inherit default))))

   `(magit-process-ng
     ((t (:foreground ,brick-red))))

   `(magit-process-ok
     ((t (:foreground ,jungle-green))))

   `(magit-reflog-amend
     ((t (:foreground ,victory-blue))))

   `(magit-reflog-checkout
     ((t (:foreground ,victory-blue))))

   `(magit-reflog-cherry-pick
     ((t :foreground ,victory-blue)))

   `(magit-reflog-commit
     ((t (:foreground ,victory-blue))))

   `(magit-reflog-merge
     ((t (:foreground ,victory-blue))))

   `(magit-reflog-other
     ((t (:foreground ,victory-blue))))

   `(magit-reflog-rebase
     ((t (:foreground ,victory-blue))))

   `(magit-reflog-remote
     ((t (:foreground ,victory-blue))))

   `(magit-reflog-reset
     ((t (:foreground ,victory-blue))))

   `(magit-section-heading
     ((t (:foreground ,deep-gold :bold t))))

   ;;`(magit-section-heading-selection ((t (:inherit default))))

   `(magit-section-highlight
     ((t (:inherit hl-line))))

   ;;`(magit-sequence-done ((t (:inherit default))))
   ;;`(magit-sequence-drop ((t (:inherit default))))
   ;;`(magit-sequence-head ((t (:inherit default))))
   ;;`(magit-sequence-onto ((t (:inherit default))))
   ;;`(magit-sequence-part ((t (:inherit default))))
   ;;`(magit-sequence-pick ((t (:inherit default))))
   ;;`(magit-sequence-stop ((t (:inherit default))))
   ;;`(magit-signature-bad ((t (:inherit default))))
   ;;`(magit-signature-good ((t (:inherit default))))
   ;;`(magit-signature-untrusted ((t (:inherit default))))
   ;;`(magit-tag ((t (:inherit default))))
   ;;`(magit-valid-signature ((t (:inherit default))))

   ;; magit

   `(magit-branch
     ((t (:foreground ,jungle-green :weight bold))))

   `(magit-diff-add
     ((t (:inherit diff-added))))

   `(magit-diff-del
     ((t (:inherit diff-removed))))

   `(magit-diff-file-header
     ((t (:inherit diff-file-header))))

   `(magit-diff-hunk-header
     ((t (:inherit diff-hunk-header))))

   `(magit-diff-none
     ((t (:inherit default))))

   `(magit-header
     ((t (:inherit diff-header))))

   `(magit-item-highlight
     ((t (:background ,midnight-2))))

   `(magit-item-mark
     ((t (:background ,midnight-2))))

   `(magit-log-graph
     ((t (:foreground ,victory-blue))))

   `(magit-log-head-label-head
     ((t (:foreground ,cold-mud :weight bold))))

   `(magit-log-head-label-bisect-bad
     ((t (:foreground ,brick-red))))

   `(magit-log-head-label-bisect-good
     ((t (:foreground ,jungle-green))))

   `(magit-log-head-label-default
     ((t (:foreground ,axiomatic-purple :weight bold))))

   `(magit-log-head-label-local
     ((t (:inherit magit-log-head-label-default :foreground ,jungle-green))))

   `(magit-log-head-label-patches
     ((t (:inherit magit-log-head-label-default))))

   `(magit-log-head-label-remote
     ((t (:inherit magit-log-head-label-default :foreground ,deep-gold))))

   `(magit-log-head-label-tags
     ((t (:inherit magit-log-head-label-default))))

   `(magit-log-message
     ((t (:inherit default))))

   `(magit-log-sha1
     ((t (:foreground ,victory-blue :weight bold))))

   `(magit-log-author
     ((t (:foreground ,jungle-green :weight normal))))

   `(magit-log-date
     ((t (:inherit font-lock-comment-face :weight normal))))

   `(magit-section-title
     ((t (:inherit header-line))))

   `(magit-whitespace-warning-face
     ((t (:inherit font-lock-warning))))

   `(magit-blame-header
     ((t (:background ,midnight-3))))

   `(magit-blame-sha1
     ((t (:foreground ,mystic-blue :background ,midnight-3))))

   `(magit-blame-culprit
     ((t (:foreground ,jungle-green :background ,midnight-3 :bold t))))

   `(magit-blame-time
     ((t (:foreground ,cold-mud :background ,midnight-3))))

   `(magit-blame-subject
     ((t (:foreground ,relaxed-white :background ,midnight-3 :bold t))))

   ;; compilation

   `(compilation-info
     ((t (:inherit default))))

   `(compilation-warning
     ((t (:inherit font-lock-warning))))

   ;; twittering-mode
   `(twittering-username-face
     ((t (:inherit font-lock-keyword-face))))

   `(twittering-uri-face
     ((t (:inherit link))))

   `(twittering-timeline-header-face
     ((t (:foreground ,cold-mud :weight bold))))

   `(twittering-timeline-footer-face
     ((t (:inherit twittering-timeline-header-face))))

   ;; outline
   `(outline-1
     ((t (:foreground ,deep-gold :weight bold))))

   `(outline-2
     ((t (:foreground ,victory-blue+1 :weight bold))))

   `(outline-3
     ((t (:foreground ,jungle-green :weight bold))))

   `(outline-4
     ((t (:foreground ,brick-red :weight bold))))

   `(outline-5
     ((t (:foreground ,axiomatic-purple :weight bold))))

   `(outline-6
     ((t (:foreground ,undergrowth-green :weight bold))))

   `(outline-7
     ((t (:foreground ,mystic-blue :weight bold))))

   `(outline-8
     ((t (:foreground ,mystic-blue :weight bold))))

   ;; org-mode
   `(org-level-1
     ((t (:inherit outline-1))))

   `(org-level-2
     ((t (:inherit outline-2))))

   `(org-level-3
     ((t (:inherit outline-3))))

   `(org-level-4
     ((t (:inherit outline-4))))

   `(org-level-5
     ((t (:inherit outline-5))))

   `(org-level-6
     ((t (:inherit outline-6))))

   `(org-level-7
     ((t (:inherit outline-7))))

   `(org-level-8
     ((t (:inherit outline-8))))

   `(org-hide
     ((t (:foreground ,midnight))))

   `(org-link
     ((t (:inherit link))))

   `(org-checkbox
     ((t (:background ,midnight :foreground ,full-white :weight bold
                      :box (:line-width 1 :style released-button)))))

   `(org-done
     ((t (:foreground ,jungle-green :weight bold))))

   `(org-todo
     ((t (:foreground ,piggy-pink :weight bold))))

   `(org-table
     ((t (:foreground ,cold-mud))))

   `(org-date
     ((t (:foreground ,piggy-pink :weight bold))))

   `(org-document-info-keyword
     ((t (:foreground ,mystic-blue))))

   `(org-document-info
     ((t (:foreground ,cold-mud :weight bold :slant italic))))

   `(org-block-begin-line
     ((t (:background ,midnight-2 :foreground ,mystic-blue :weight bold))))

   `(org-block-background
     ((t (:background ,midnight-1))))

   `(org-block-end-line
     ((t (:inherit org-block-begin-line))))

   `(org-agenda-date-today
     ((t (:foreground ,jungle-green :background ,midnight-2 :weight bold))))

   `(org-agenda-date
     ((t (:foreground ,victory-blue+1))))

   `(org-agenda-date-weekend
     ((t (:foreground ,piggy-pink))))

   `(org-agenda-structure
     ((t (:inherit header-line))))

   `(org-warning
     ((t (:inherit font-lock-warning-face))))

   `(org-agenda-clocking
     ((t (:inherit org-date))))

   `(org-deadline-announce
     ((t (:inherit font-lock-warning-face))))

   `(org-formula
     ((t (:inherit font-lock-doc-face))))

   `(org-special-keyword
     ((t (:inherit font-lock-keyword))))

   ;; dired+

   `(diredp-compressed-file-suffix
     ((t (:foreground ,deep-gold :weight bold))))

   `(diredp-date-time
     ((t (:foreground ,mystic-blue))))

   `(diredp-deletion
     ((t (:foreground ,brick-red :weight bold :slant italic))))

   `(diredp-deletion-file-name
     ((t (:foreground ,brick-red :underline t))))

   `(diredp-symlink
     ((t (:foreground ,deep-gold))))

   `(diredp-dir-heading
     ((t (:inherit minibuffer-prompt))))

   `(diredp-display-msg
     ((t (:inherit default))))

   `(diredp-exec-priv
     ((t (:foreground ,jungle-green))))

   `(diredp-write-priv
     ((t (:foreground ,brick-red))))

   `(diredp-read-priv
     ((t (:foreground ,deep-gold))))

   `(diredp-dir-priv
     ((t (:foreground ,victory-blue+1 :weight bold))))

   `(diredp-link-priv
     ((t (:foreground ,deep-gold))))

   `(diredp-other-priv
     ((t (:foreground ,deep-gold :weight bold))))

   `(diredp-rare-priv
     ((t (:foreground ,brick-red :weight bold))))

   `(diredp-no-priv
     ((t (:foreground ,mystic-blue))))

   `(diredp-file-name
     ((t (:foreground ,relaxed-white))))

   `(diredp-file-suffix
     ((t (:inherit dired-file-name))))

   `(diredp-number
     ((t (:foreground ,victory-blue))))

   `(diredp-executable-tag
     ((t (:foreground ,jungle-green :weight bold))))

   `(diredp-flag-mark
     ((t (:bareground ,brick-red :weight bold))))

   `(diredp-flag-mark-line
     ((t (:background ,midnight-2))))

   `(diredp-mode-line-marked
     ((t (:foreground ,brick-red))))

   `(diredp-mode-line-flagged
     ((t (:foreground ,deep-gold))))

   `(diredp-ignored-file-name
     ((t (:foreground ,mystic-blue))))

   ;; nXML

   `(nxml-cdata-section-CDATA
     ((t (:foreground ,deep-gold))))

   `(nxml-cdata-section-content
     ((t (:foreground ,cold-mud))))

   `(nxml-attribute-local-name
     ((t (:foreground ,relaxed-white))))

   `(nxml-element-local-name
     ((t (:foreground ,victory-blue))))

   `(nxml-element-prefix
     ((t (:foreground ,deep-gold))))

   ;; git-gutter

   `(git-gutter:modified
     ((t (:background ,bright-gold :foreground ,bright-gold))))

   `(git-gutter:added
     ((t (:background ,jungle-green :foreground ,jungle-green))))

   `(git-gutter:deleted
     ((t (:background ,brick-red :foreground ,brick-red))))

   `(git-gutter:separator
     ((t (:background ,midnight-2 :foreground ,midnight-2))))

   `(git-gutter:unchanged
     ((t (:background ,midnight-3 :foreground ,midnight-3))))

   ;; git-gutter-fringe

   `(git-gutter-fr:modified
     ((t (:background ,bright-gold :foreground ,bright-gold))))

   `(git-gutter-fr:added
     ((t (:background ,jungle-green :foreground ,jungle-green))))

   `(git-gutter-fr:deleted
     ((t (:background ,brick-red :foreground ,brick-red))))

   ;; company-mode

   ;; TODO
   ;; company-tooltip-search           - Face used for the search string in the tooltip
   ;; company-tooltip-mouse            - Face used for the tooltip item under the mouse
   ;; company-preview-search           - Face used for the search string in the completion preview
   ;; company-echo                     - Face used for completions in the echo area
   ;; company-echo-common              - Face used for the common part of completions in the echo area

   `(company-tooltip
     ((t (:background ,midnight-2 :foreground ,relaxed-white))))

   `(company-tooltip-selection
     ((t (:background ,midnight-3 :foreground ,full-white :weight bold))))

   `(company-tooltip-common
     ((t (:background ,midnight-2 :foreground ,jungle-green :weight bold))))

   `(company-tooltip-annotation
     ((t (:background ,midnight-2 :foreground ,mystic-blue))))

   `(company-preview
     ((t (:background ,midnight :foreground ,bright-gold))))

   `(company-preview-common
     ((t (:background ,midnight :foreground ,bright-gold))))

   `(company-tooltip-common-selection
     ((t (:background ,midnight-3 :foreground ,jungle-green :weight bold))))

   `(company-scrollbar-bg
     ((t (:background ,midnight-3 :foreground ,midnight-2))))

   `(company-scrollbar-fg
     ((t (:background ,mystic-blue))))

   ;; helm

   `(helm-header
     ((t (:inherit header-line :height 1.3 :bold t))))

   `(helm-source-header
     ((t (:background ,midnight-1 :foreground ,axiomatic-purple :weight bold :height 1.1))))

   `(helm-selection
     ((t (:background ,midnight-2 :weight bold))))

   `(helm-candidate-number
     ((t (:foreground ,jungle-green))))

   `(helm-match
     ((t (:foreground ,jungle-green :weight bold :underline t))))

   `(helm-M-x-key
     ((t (:foreground ,victory-blue))))

   `(helm-prefarg
     ((t (:foreground ,deep-gold))))

   `(helm-selection-line
     ((t (:background ,midnight-2 :weight bold))))

   `(helm-match-item
     ((t (:inherit match))))

   `(helm-buffer-saved-out
     ((t (:foreground ,cold-mud))))

   `(helm-buffer-not-saved
     ((t (:foreground ,piggy-pink))))

   `(helm-buffer-size
     ((t (:foreground ,mystic-blue))))

   `(helm-buffer-file
     ((t (:inherit default))))

   `(helm-buffer-directory
     ((t (:foreground ,victory-blue))))

   `(helm-buffer-process
     ((t (:inherit helm-buffer-directory))))

   `(helm-grep-match
     ((t (:inherit helm-match))))

   `(helm-grep-file
     ((t (:foreground ,victory-blue))))

   `(helm-moccur-buffer
     ((t (:inherit helm-grep-file))))

   `(helm-grep-lineno
     ((t (:foreground ,mystic-blue))))

   `(helm-ff-file
     ((t (:inherit default))))

   `(helm-ff-directory
     ((t (:inherit eshell-ls-directory))))

   `(helm-ff-executable
     ((t (:inherit eshell-ls-executable))))

   `(helm-ff-invalid-symlink
     ((t (:inherit eshell-ls-missing))))

   `(helm-ff-symlink
     ((t (:inherit eshell-ls-symlink))))

   `(helm-ff-prefix
     ((t (:inherit default :foreground ,mystic-blue))))

   ;; TODO
   ;; helm-top-columns                 - Face for helm help string in minibuffer.
   ;; helm-visible-mark                - Face for visible mark.
   ;; helm-separator                   - Face for multiline source separator.
   ;; helm-action                      - Face for action lines in the helm action buffer.
   ;; helm-header-line-left-margin     - Face used to highlight helm-header sign in left-margin.
   ;; helm-moccur-buffer               - Face used to highlight moccur buffer names.
   ;; helm-grep-finish                 - Face used in mode line when grep is finish.
   ;; helm-grep-cmd-line               - Face used to highlight grep command line when no results.
   ;; helm-resume-need-update          - Face used to flash moccur buffer when it needs update.
   ;; helm-locate-finish               - Face used in mode line when locate process is finish.
   ;; helm-helper                      - Face for helm help string in minibuffer.
   ;; helm-ff-dotted-directory         - Face used for dotted directories in `helm-find-files'.
   ;; helm-ff-dotted-symlink-directory - Face used for dotted symlinked directories in `helm-find-files'.
   ;; helm-history-deleted             - Face used for deleted files in `file-name-history'.
   ;; helm-history-remote              - Face used for remote files in `file-name-history'.

   ;; structured-haskell-mode

   `(shm-current-face
     ((t (:background ,midnight-2))))

   `(shm-quarantine-face
     ((t (:background ,midnight-red))))

   ;; fill-column-indicator

   `(fci-rule-color
     ((t (:background ,mystic-blue))))

   ;; basic auctex support

   `(font-latex-sectioning-0-face
     ((t (:inherit outline-1 :height 1.1))))

   `(font-latex-sectioning-1-face
     ((t (:inherit outline-2 :height 1.1))))

   `(font-latex-sectioning-2-face
     ((t (:inherit outline-3 :height 1.1))))

   `(font-latex-sectioning-3-face
     ((t (:inherit outline-4 :height 1.1))))

   `(font-latex-sectioning-4-face
     ((t (:inherit outline-5 :height 1.1))))

   `(font-latex-sectioning-5-face
     ((t (:inherit outline-6 :height 1.1))))

   `(font-latex-bold-face
     ((t (:inherit bold :foreground ,relaxed-white))))

   `(font-latex-italic-face
     ((t (:inherit italic :foreground ,relaxed-white))))

   `(font-latex-math-face
     ((t (:foreground ,axiomatic-purple))))

   `(font-latex-slide-title-face
     ((t (:inherit font-lock-type-face :weight bold :height 1.2))))

   `(font-latex-string-face
     ((t (:inherit font-lock-string-face))))

   `(font-latex-subscript-face
     ((t (:height 0.8))))

   `(font-latex-superscript-face
     ((t (:height 0.8))))

   `(font-latex-warning-face
     ((t (:inherit font-lock-warning-face))))

   `(font-latex-doctex-documentation-face
     ((t (:background unspecified))))

   `(font-latex-doctex-preprocessor-face
     ((t (:inherit (font-latex-doctex-documentation-face
                    font-lock-builtin-face font-lock-preprocessor-face)))))

   ))

;;;###autoload
(when load-file-name
  (add-to-list
   'custom-theme-load-path
   (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'subatomic)

;;; subatomic-theme.el ends here
