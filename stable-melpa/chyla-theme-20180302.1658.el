;;; chyla-theme.el --- chyla.org - green color theme.

;; Copyright (C) 2018 Adam Chyła
;; Author: Adam Chyła <adam@chyla.org> https://chyla.org/
;; URL: https://github.com/chyla/ChylaThemeForEmacs
;; Package-Version: 20180302.1658
;; Package-Commit: ae5e7ecace2ab474151eb0ac5ef07fba2dc32f8a
;; Version: 0.1

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

;; chyla.org - green color theme.

;;; Credits:

;; Philip Arvidsson created the GitHub theme file which this file is based on.
;; Bozhidar Batsov created the Zenburn theme file which GitHub theme file were based on.

;;; Code:

(deftheme chyla "The chyla.org color theme")

;;; Color Palette

(defvar chyla-default-colors-alist
  '(("chyla-border"                 . "#d0d0d0")
    ("chyla-comment"                . "#888a88")
    ("chyla-constant"               . "#0086b3")
    ("chyla-diff-added"             . "#eaffea")
    ("chyla-diff-added-highlight"   . "#a6f3a6")
    ("chyla-diff-changed"           . "#f8cca9")
    ("chyla-diff-changed-highlight" . "#f6dac3")
    ("chyla-diff-removed"           . "#ffecec")
    ("chyla-diff-removed-highlight" . "#f8cbcb")
    ("chyla-function"               . "#183691")
    ("chyla-highlight"              . "#edf5dc")
    ("chyla-header-bg"              . "#5fa600")
    ("chyla-header-fg"              . "#ffffff")
    ("chyla-header-inactive-fg"     . "#539100")
    ("chyla-header-inactive-bg"     . "#d9ded2")
    ("chyla-html-tag"               . "#63a35c")
    ("chyla-keyword"                . "#539100")
    ("chyla-selection"              . "#d5dec4")
    ("chyla-string"                 . "#183691")
    ("chyla-text"                   . "#333333")
    ("chyla-white"                  . "#fafafa"))
  "List of chyla.org colors.
Each element has the form (NAME . HEX).")

(defvar chyla-override-colors-alist
  '()
  "Place to override default theme colors.

You can override a subset of the theme's default colors by
defining them in this alist before loading the theme.")

(defvar chyla-colors-alist
  (append chyla-default-colors-alist chyla-override-colors-alist))

(defmacro chyla-with-color-variables (&rest body)
  "`let' bind all colors defined in `chyla-colors-alist' around BODY.
Also bind `class' to ((class color) (min-colors 89))."
  (declare (indent 0))
  `(let ((class '((class color) (min-colors 89)))
         ,@(mapcar (lambda (cons)
                     (list (intern (car cons)) (cdr cons)))
                   chyla-colors-alist))
     ,@body))

;;; Theme Faces
(chyla-with-color-variables
  (custom-theme-set-faces
   'chyla
;;;; Built-in
;;;;; basic coloring
   '(button ((t (:underline t))))
   `(link ((t (:foreground ,chyla-keyword :underline t :weight bold))))
   `(link-visited ((t (:foreground ,chyla-text :underline t :weight normal))))
   `(default ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(cursor ((t (:foreground ,chyla-keyword :background ,chyla-keyword))))
   `(escape-glyph ((t (:foreground ,chyla-keyword :bold t))))
   `(fringe ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(header-line ((t (:foreground ,chyla-keyword
                                  :background ,chyla-selection
                                  :box (:line-width -1 :style released-button)))))
   `(highlight ((t (:background ,chyla-highlight))))
   `(success ((t (:foreground ,chyla-comment :weight bold))))
   `(warning ((t (:foreground ,chyla-text :weight bold))))
   `(tooltip ((t (:foreground ,chyla-text :background ,chyla-white))))
;;;;; compilation
   `(compilation-column-face ((t (:foreground ,chyla-keyword))))
   `(compilation-enter-directory-face ((t (:foreground ,chyla-comment))))
   `(compilation-error-face ((t (:foreground ,chyla-text :weight bold :underline t))))
   `(compilation-face ((t (:foreground ,chyla-text))))
   `(compilation-info-face ((t (:foreground ,chyla-text))))
   `(compilation-info ((t (:foreground ,chyla-constant :underline t))))
   `(compilation-leave-directory-face ((t (:foreground ,chyla-comment))))
   `(compilation-line-face ((t (:foreground ,chyla-keyword))))
   `(compilation-line-number ((t (:foreground ,chyla-keyword))))
   `(compilation-message-face ((t (:foreground ,chyla-text))))
   `(compilation-warning-face ((t (:foreground ,chyla-text :weight bold :underline t))))
   `(compilation-mode-line-exit ((t (:foreground ,chyla-comment :weight bold))))
   `(compilation-mode-line-fail ((t (:foreground ,chyla-string :weight bold))))
   `(compilation-mode-line-run ((t (:foreground ,chyla-keyword :weight bold))))
;;;;; completions
   `(completions-annotations ((t (:foreground ,chyla-text))))
;;;;; grep
   `(grep-context-face ((t (:foreground ,chyla-text))))
   `(grep-error-face ((t (:foreground ,chyla-text :weight bold :underline t))))
   `(grep-hit-face ((t (:foreground ,chyla-text))))
   `(grep-match-face ((t (:foreground ,chyla-text :weight bold))))
   `(match ((t (:background ,chyla-selection :foreground ,chyla-text :weight bold))))
;;;;; info
   `(Info-quoted ((t (:inherit font-lock-constant-face))))
;;;;; isearch
   `(isearch ((t (:foreground ,chyla-white :weight bold :background ,chyla-selection))))
   `(isearch-fail ((t (:foreground ,chyla-border :background ,chyla-white))))
   `(lazy-highlight ((t (:foreground ,chyla-text :weight bold :background ,chyla-highlight))))

   `(menu ((t (:foreground ,chyla-white :background ,chyla-header-bg))))
   `(minibuffer-prompt ((t (:foreground ,chyla-keyword))))
   `(mode-line
     ((,class (:foreground ,chyla-header-fg
                           :background ,chyla-header-bg))
      (t :inverse-video t)))
   `(mode-line-buffer-id ((t (:foreground ,chyla-white :weight bold :distant-foreground ,chyla-header-inactive-fg))))
   `(mode-line-inactive
     ((t (:foreground ,chyla-comment
                      :background ,chyla-header-inactive-bg
                      :box (:line-width -1 :color ,chyla-border)))))
   `(region ((,class (:background ,chyla-selection))
             (t :inverse-video t)))
   `(secondary-selection ((t (:background ,chyla-white))))
   `(trailing-whitespace ((t (:background ,chyla-string))))
   `(vertical-border ((t (:foreground ,chyla-border))))
;;;;; font lock
   `(font-lock-builtin-face ((t (:foreground ,chyla-keyword))))
   `(font-lock-comment-face ((t (:foreground ,chyla-comment))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,chyla-comment))))
   `(font-lock-constant-face ((t (:foreground ,chyla-constant))))
   `(font-lock-doc-face ((t (:foreground ,chyla-string))))
   `(font-lock-function-name-face ((t (:foreground ,chyla-function))))
   `(font-lock-keyword-face ((t (:foreground ,chyla-keyword :weight bold))))
   `(font-lock-negation-char-face ((t (:foreground ,chyla-keyword))))
   `(font-lock-preprocessor-face ((t (:foreground ,chyla-keyword))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,chyla-keyword))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,chyla-comment))))
   `(font-lock-string-face ((t (:foreground ,chyla-string))))
   `(font-lock-type-face ((t (:foreground ,chyla-constant))))
   `(font-lock-variable-name-face ((t (:foreground ,chyla-text))))
   `(font-lock-warning-face ((t (:foreground ,chyla-text))))

   `(c-annotation-face ((t (:inherit font-lock-constant-face))))
;;;;; newsticker
   `(newsticker-date-face ((t (:foreground ,chyla-text))))
   `(newsticker-default-face ((t (:foreground ,chyla-text))))
   `(newsticker-enclosure-face ((t (:foreground ,chyla-html-tag))))
   `(newsticker-extra-face ((t (:foreground ,chyla-white :height 0.8))))
   `(newsticker-feed-face ((t (:foreground ,chyla-text))))
   `(newsticker-immortal-item-face ((t (:foreground ,chyla-comment))))
   `(newsticker-new-item-face ((t (:foreground ,chyla-text))))
   `(newsticker-obsolete-item-face ((t (:foreground ,chyla-string))))
   `(newsticker-old-item-face ((t (:foreground ,chyla-white))))
   `(newsticker-statistics-face ((t (:foreground ,chyla-text))))
   `(newsticker-treeview-face ((t (:foreground ,chyla-text))))
   `(newsticker-treeview-immortal-face ((t (:foreground ,chyla-comment))))
   `(newsticker-treeview-listwindow-face ((t (:foreground ,chyla-text))))
   `(newsticker-treeview-new-face ((t (:foreground ,chyla-text :weight bold))))
   `(newsticker-treeview-obsolete-face ((t (:foreground ,chyla-string))))
   `(newsticker-treeview-old-face ((t (:foreground ,chyla-white))))
   `(newsticker-treeview-selection-face ((t (:background ,chyla-selection :foreground ,chyla-keyword))))
;;;; Third-party
;;;;; ace-jump
   `(ace-jump-face-background
     ((t (:foreground ,chyla-text :background ,chyla-white :inverse-video nil))))
   `(ace-jump-face-foreground
     ((t (:foreground ,chyla-comment :background ,chyla-white :inverse-video nil))))
;;;;; ace-window
   `(aw-background-face
     ((t (:foreground ,chyla-text :background ,chyla-white :inverse-video nil))))
   `(aw-leading-char-face ((t (:foreground ,chyla-white :background ,chyla-keyword :weight bold))))
;;;;; android mode
   `(android-mode-debug-face ((t (:foreground ,chyla-text))))
   `(android-mode-error-face ((t (:foreground ,chyla-text :weight bold))))
   `(android-mode-info-face ((t (:foreground ,chyla-text))))
   `(android-mode-verbose-face ((t (:foreground ,chyla-comment))))
   `(android-mode-warning-face ((t (:foreground ,chyla-keyword))))
;;;;; anzu
   `(anzu-mode-line ((t (:foreground ,chyla-function :weight bold))))
   `(anzu-match-1 ((t (:foreground ,chyla-white :background ,chyla-comment))))
   `(anzu-match-2 ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(anzu-match-3 ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(anzu-replace-to ((t (:inherit anzu-replace-highlight :foreground ,chyla-keyword))))
;;;;; auctex
   `(font-latex-bold-face ((t (:inherit bold))))
   `(font-latex-warning-face ((t (:foreground nil :inherit font-lock-warning-face))))
   `(font-latex-sectioning-5-face ((t (:foreground ,chyla-string :weight bold ))))
   `(font-latex-sedate-face ((t (:foreground ,chyla-keyword))))
   `(font-latex-italic-face ((t (:foreground ,chyla-function :slant italic))))
   `(font-latex-string-face ((t (:inherit ,font-lock-string-face))))
   `(font-latex-math-face ((t (:foreground ,chyla-text))))
;;;;; agda-mode
   `(agda2-highlight-keyword-face ((t (:foreground ,chyla-keyword :weight bold))))
   `(agda2-highlight-string-face ((t (:foreground ,chyla-string))))
   `(agda2-highlight-symbol-face ((t (:foreground ,chyla-text))))
   `(agda2-highlight-primitive-type-face ((t (:foreground ,chyla-constant))))
   `(agda2-highlight-inductive-constructor-face ((t (:foreground ,chyla-text))))
   `(agda2-highlight-coinductive-constructor-face ((t (:foreground ,chyla-text))))
   `(agda2-highlight-datatype-face ((t (:foreground ,chyla-text))))
   `(agda2-highlight-function-face ((t (:foreground ,chyla-text))))
   `(agda2-highlight-module-face ((t (:foreground ,chyla-constant))))
   `(agda2-highlight-error-face ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(agda2-highlight-unsolved-meta-face ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(agda2-highlight-unsolved-constraint-face ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(agda2-highlight-termination-problem-face ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(agda2-highlight-incomplete-pattern-face ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(agda2-highlight-typechecks-face ((t (:background ,chyla-text))))
;;;;; auto-complete
   `(ac-candidate-face ((t (:background ,chyla-white :foreground ,chyla-text))))
   `(ac-completion-face ((t (:background ,chyla-selection :foreground ,chyla-text))))
   `(ac-selection-face ((t (:background ,chyla-selection :foreground ,chyla-text))))
   `(popup-tip-face ((t (:background ,chyla-text :foreground ,chyla-white))))
   `(popup-scroll-bar-foreground-face ((t (:background ,chyla-text))))
   `(popup-scroll-bar-background-face ((t (:background ,chyla-comment))))
   `(popup-isearch-match ((t (:background ,chyla-white :foreground ,chyla-text))))
;;;;; avy
   `(avy-background-face
     ((t (:foreground ,chyla-text :background ,chyla-white :inverse-video nil))))
   `(avy-lead-face-0
     ((t (:foreground ,chyla-html-tag :background ,chyla-white :inverse-video nil :weight bold))))
   `(avy-lead-face-1
     ((t (:foreground ,chyla-keyword :background ,chyla-white :inverse-video nil :weight bold))))
   `(avy-lead-face-2
     ((t (:foreground ,chyla-text :background ,chyla-white :inverse-video nil :weight bold))))
   `(avy-lead-face
     ((t (:foreground ,chyla-function :background ,chyla-white :inverse-video nil :weight bold))))
;;;;; company-mode
   `(company-tooltip ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(company-tooltip-annotation ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(company-tooltip-annotation-selection ((t (:foreground ,chyla-text :background ,chyla-selection))))
   `(company-tooltip-selection ((t (:foreground ,chyla-text :background ,chyla-selection))))
   `(company-tooltip-mouse ((t (:background ,chyla-selection))))
   `(company-tooltip-common ((t (:foreground ,chyla-comment))))
   `(company-tooltip-common-selection ((t (:foreground ,chyla-comment))))
   `(company-scrollbar-fg ((t (:background ,chyla-text))))
   `(company-scrollbar-bg ((t (:background ,chyla-white))))
   `(company-preview ((t (:background ,chyla-comment))))
   `(company-preview-common ((t (:foreground ,chyla-comment :background ,chyla-selection))))
;;;;; bm
   `(bm-face ((t (:background ,chyla-text :foreground ,chyla-white))))
   `(bm-fringe-face ((t (:background ,chyla-text :foreground ,chyla-white))))
   `(bm-fringe-persistent-face ((t (:background ,chyla-comment :foreground ,chyla-white))))
   `(bm-persistent-face ((t (:background ,chyla-comment :foreground ,chyla-white))))
;;;;; cider
   `(cider-result-overlay-face ((t (:background unspecified))))
   `(cider-enlightened-face ((t (:box (:color ,chyla-text :line-width -1)))))
   `(cider-enlightened-local-face ((t (:weight bold :foreground ,chyla-text))))
   `(cider-deprecated-face ((t (:background ,chyla-text))))
   `(cider-instrumented-face ((t (:box (:color ,chyla-string :line-width -1)))))
   `(cider-traced-face ((t (:box (:color ,chyla-function :line-width -1)))))
   `(cider-test-failure-face ((t (:background ,chyla-text))))
   `(cider-test-error-face ((t (:background ,chyla-text))))
   `(cider-test-success-face ((t (:background ,chyla-comment))))
;;;;; circe
   `(circe-highlight-nick-face ((t (:foreground ,chyla-function))))
   `(circe-my-message-face ((t (:foreground ,chyla-text))))
   `(circe-fool-face ((t (:foreground ,chyla-text))))
   `(circe-topic-diff-removed-face ((t (:foreground ,chyla-string :weight bold))))
   `(circe-originator-face ((t (:foreground ,chyla-text))))
   `(circe-server-face ((t (:foreground ,chyla-comment))))
   `(circe-topic-diff-new-face ((t (:foreground ,chyla-text :weight bold))))
   `(circe-prompt-face ((t (:foreground ,chyla-text :background ,chyla-white :weight bold))))
;;;;; context-coloring
   `(context-coloring-level-0-face ((t :foreground ,chyla-text)))
   `(context-coloring-level-1-face ((t :foreground ,chyla-function)))
   `(context-coloring-level-2-face ((t :foreground ,chyla-constant)))
   `(context-coloring-level-3-face ((t :foreground ,chyla-keyword)))
   `(context-coloring-level-4-face ((t :foreground ,chyla-text)))
   `(context-coloring-level-5-face ((t :foreground ,chyla-text)))
   `(context-coloring-level-6-face ((t :foreground ,chyla-keyword)))
   `(context-coloring-level-7-face ((t :foreground ,chyla-comment)))
   `(context-coloring-level-8-face ((t :foreground ,chyla-text)))
   `(context-coloring-level-9-face ((t :foreground ,chyla-text)))
;;;;; coq
   `(coq-solve-tactics-face ((t (:foreground nil :inherit font-lock-constant-face))))
;;;;; ctable
   `(ctbl:face-cell-select ((t (:background ,chyla-text :foreground ,chyla-white))))
   `(ctbl:face-continue-bar ((t (:background ,chyla-highlight :foreground ,chyla-white))))
   `(ctbl:face-row-select ((t (:background ,chyla-function :foreground ,chyla-white))))
;;;;; diff
   `(diff-added          ((t (:background ,chyla-diff-added :foreground ,chyla-text))))
   `(diff-changed        ((t (:background ,chyla-diff-changed :foreground ,chyla-text))))
   `(diff-removed        ((t (:background ,chyla-diff-removed :foreground ,chyla-text))))
   `(diff-refine-added   ((t (:background ,chyla-diff-added-highlight :foreground ,chyla-text))))
   `(diff-refine-change  ((t (:background ,chyla-diff-changed-highlight :foreground ,chyla-text))))
   `(diff-refine-removed ((t (:background ,chyla-diff-removed-highlight :foreground ,chyla-text))))
   `(diff-header ((,class (:background ,chyla-white))
                  (t (:background ,chyla-text :foreground ,chyla-white))))
   `(diff-file-header
     ((,class (:background ,chyla-white :foreground ,chyla-text :bold t))
      (t (:background ,chyla-text :foreground ,chyla-white :bold t))))
;;;;; diff-hl
   `(diff-hl-change ((,class (:foreground ,chyla-text :background ,chyla-diff-added))))
   `(diff-hl-delete ((,class (:foreground ,chyla-text :background ,chyla-diff-removed-highlight))))
   `(diff-hl-insert ((,class (:foreground ,chyla-text :background ,chyla-diff-added-highlight))))
;;;;; dim-autoload
   `(dim-autoload-cookie-line ((t :foreground ,chyla-white)))
;;;;; dired+
   `(diredp-display-msg ((t (:foreground ,chyla-text))))
   `(diredp-compressed-file-suffix ((t (:foreground ,chyla-text))))
   `(diredp-date-time ((t (:foreground ,chyla-text))))
   `(diredp-deletion ((t (:foreground ,chyla-keyword))))
   `(diredp-deletion-file-name ((t (:foreground ,chyla-string))))
   `(diredp-dir-heading ((t (:foreground ,chyla-text :background ,chyla-selection))))
   `(diredp-dir-priv ((t (:foreground ,chyla-function))))
   `(diredp-exec-priv ((t (:foreground ,chyla-string))))
   `(diredp-executable-tag ((t (:foreground ,chyla-text))))
   `(diredp-file-name ((t (:foreground ,chyla-text))))
   `(diredp-file-suffix ((t (:foreground ,chyla-comment))))
   `(diredp-flag-mark ((t (:foreground ,chyla-keyword))))
   `(diredp-flag-mark-line ((t (:foreground ,chyla-text))))
   `(diredp-ignored-file-name ((t (:foreground ,chyla-string))))
   `(diredp-link-priv ((t (:foreground ,chyla-keyword))))
   `(diredp-mode-line-flagged ((t (:foreground ,chyla-keyword))))
   `(diredp-mode-line-marked ((t (:foreground ,chyla-text))))
   `(diredp-no-priv ((t (:foreground ,chyla-text))))
   `(diredp-number ((t (:foreground ,chyla-text))))
   `(diredp-other-priv ((t (:foreground ,chyla-text))))
   `(diredp-rare-priv ((t (:foreground ,chyla-text))))
   `(diredp-read-priv ((t (:foreground ,chyla-comment))))
   `(diredp-symlink ((t (:foreground ,chyla-keyword))))
   `(diredp-write-priv ((t (:foreground ,chyla-text))))
;;;;; dired-async
   `(dired-async-failures ((t (:foreground ,chyla-string :weight bold))))
   `(dired-async-message ((t (:foreground ,chyla-keyword :weight bold))))
   `(dired-async-mode-message ((t (:foreground ,chyla-keyword))))
;;;;; ediff
   `(ediff-current-diff-A ((t (:foreground ,chyla-text :background ,chyla-diff-removed))))
   `(ediff-current-diff-Ancestor ((t (:foreground ,chyla-text :background ,chyla-text))))
   `(ediff-current-diff-B ((t (:foreground ,chyla-text :background ,chyla-diff-added))))
   `(ediff-current-diff-C ((t (:foreground ,chyla-text :background ,chyla-text))))
   `(ediff-even-diff-A ((t (:background ,chyla-white))))
   `(ediff-even-diff-Ancestor ((t (:background ,chyla-white))))
   `(ediff-even-diff-B ((t (:background ,chyla-white))))
   `(ediff-even-diff-C ((t (:background ,chyla-white))))
   `(ediff-fine-diff-A ((t (:foreground ,chyla-text :background ,chyla-diff-removed-highlight :weight bold))))
   `(ediff-fine-diff-Ancestor ((t (:foreground ,chyla-text :background ,chyla-text weight bold))))
   `(ediff-fine-diff-B ((t (:foreground ,chyla-text :background ,chyla-diff-added-highlight :weight bold))))
   `(ediff-fine-diff-C ((t (:foreground ,chyla-text :background ,chyla-text :weight bold ))))
   `(ediff-odd-diff-A ((t (:background ,chyla-white))))
   `(ediff-odd-diff-Ancestor ((t (:background ,chyla-white))))
   `(ediff-odd-diff-B ((t (:background ,chyla-white))))
   `(ediff-odd-diff-C ((t (:background ,chyla-white))))
;;;;; egg
   `(egg-text-base ((t (:foreground ,chyla-text))))
   `(egg-help-header-1 ((t (:foreground ,chyla-keyword))))
   `(egg-help-header-2 ((t (:foreground ,chyla-html-tag))))
   `(egg-branch ((t (:foreground ,chyla-keyword))))
   `(egg-branch-mono ((t (:foreground ,chyla-keyword))))
   `(egg-term ((t (:foreground ,chyla-keyword))))
   `(egg-diff-add ((t (:foreground ,chyla-constant))))
   `(egg-diff-del ((t (:foreground ,chyla-text))))
   `(egg-diff-file-header ((t (:foreground ,chyla-text))))
   `(egg-section-title ((t (:foreground ,chyla-keyword))))
   `(egg-stash-mono ((t (:foreground ,chyla-constant))))
;;;;; elfeed
   `(elfeed-log-error-level-face ((t (:foreground ,chyla-string))))
   `(elfeed-log-info-level-face ((t (:foreground ,chyla-text))))
   `(elfeed-log-warn-level-face ((t (:foreground ,chyla-keyword))))
   `(elfeed-search-date-face ((t (:foreground ,chyla-text :underline t
                                              :weight bold))))
   `(elfeed-search-tag-face ((t (:foreground ,chyla-comment))))
   `(elfeed-search-feed-face ((t (:foreground ,chyla-function))))
;;;;; emacs-w3m
   `(w3m-anchor ((t (:foreground ,chyla-keyword :underline t
                                 :weight bold))))
   `(w3m-arrived-anchor ((t (:foreground ,chyla-text
                                         :underline t :weight normal))))
   `(w3m-form ((t (:foreground ,chyla-text :underline t))))
   `(w3m-header-line-location-title ((t (:foreground ,chyla-keyword
                                                     :underline t :weight bold))))
   '(w3m-history-current-url ((t (:inherit match))))
   `(w3m-lnum ((t (:foreground ,chyla-comment :background ,chyla-white))))
   `(w3m-lnum-match ((t (:background ,chyla-selection
                                     :foreground ,chyla-text
                                     :weight bold))))
   `(w3m-lnum-minibuffer-prompt ((t (:foreground ,chyla-keyword))))
;;;;; erc
   `(erc-action-face ((t (:inherit erc-default-face))))
   `(erc-bold-face ((t (:weight bold))))
   `(erc-current-nick-face ((t (:foreground ,chyla-text :weight bold))))
   `(erc-dangerous-host-face ((t (:inherit font-lock-warning-face))))
   `(erc-default-face ((t (:foreground ,chyla-text))))
   `(erc-direct-msg-face ((t (:inherit erc-default-face))))
   `(erc-error-face ((t (:inherit font-lock-warning-face))))
   `(erc-fool-face ((t (:inherit erc-default-face))))
   `(erc-highlight-face ((t (:inherit hover-highlight))))
   `(erc-input-face ((t (:foreground ,chyla-keyword))))
   `(erc-keyword-face ((t (:foreground ,chyla-text :weight bold))))
   `(erc-nick-default-face ((t (:foreground ,chyla-keyword :weight bold))))
   `(erc-my-nick-face ((t (:foreground ,chyla-string :weight bold))))
   `(erc-nick-msg-face ((t (:inherit erc-default-face))))
   `(erc-notice-face ((t (:foreground ,chyla-comment))))
   `(erc-pal-face ((t (:foreground ,chyla-text :weight bold))))
   `(erc-prompt-face ((t (:foreground ,chyla-text :background ,chyla-white :weight bold))))
   `(erc-timestamp-face ((t (:foreground ,chyla-constant))))
   `(erc-underline-face ((t (:underline t))))
;;;;; ert
   `(ert-test-result-expected ((t (:foreground ,chyla-constant :background ,chyla-white))))
   `(ert-test-result-unexpected ((t (:foreground ,chyla-string :background ,chyla-white))))
;;;;; eshell
   `(eshell-prompt ((t (:foreground ,chyla-keyword :weight bold))))
   `(eshell-ls-archive ((t (:foreground ,chyla-text :weight bold))))
   `(eshell-ls-backup ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-clutter ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-directory ((t (:foreground ,chyla-keyword :weight bold))))
   `(eshell-ls-executable ((t (:foreground ,chyla-text :weight bold))))
   `(eshell-ls-unreadable ((t (:foreground ,chyla-text))))
   `(eshell-ls-missing ((t (:inherit font-lock-warning-face))))
   `(eshell-ls-product ((t (:inherit font-lock-doc-face))))
   `(eshell-ls-special ((t (:foreground ,chyla-keyword :weight bold))))
   `(eshell-ls-symlink ((t (:foreground ,chyla-function :weight bold))))
;;;;; flx
   `(flx-highlight-face ((t (:foreground ,chyla-comment :weight bold))))
;;;;; flycheck
   `(flycheck-error
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-text) :inherit unspecified))
      (t (:foreground ,chyla-text :weight bold :underline t))))
   `(flycheck-warning
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-keyword) :inherit unspecified))
      (t (:foreground ,chyla-keyword :weight bold :underline t))))
   `(flycheck-info
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-function) :inherit unspecified))
      (t (:foreground ,chyla-function :weight bold :underline t))))
   `(flycheck-fringe-error ((t (:foreground ,chyla-text :weight bold))))
   `(flycheck-fringe-warning ((t (:foreground ,chyla-keyword :weight bold))))
   `(flycheck-fringe-info ((t (:foreground ,chyla-function :weight bold))))
;;;;; flymake
   `(flymake-errline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-string)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,chyla-text :weight bold :underline t))))
   `(flymake-warnline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-text)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,chyla-text :weight bold :underline t))))
   `(flymake-infoline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-comment)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,chyla-comment :weight bold :underline t))))
;;;;; flyspell
   `(flyspell-duplicate
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-text) :inherit unspecified))
      (t (:foreground ,chyla-text :weight bold :underline t))))
   `(flyspell-incorrect
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-string) :inherit unspecified))
      (t (:foreground ,chyla-text :weight bold :underline t))))
;;;;; full-ack
   `(ack-separator ((t (:foreground ,chyla-text))))
   `(ack-file ((t (:foreground ,chyla-text))))
   `(ack-line ((t (:foreground ,chyla-keyword))))
   `(ack-match ((t (:foreground ,chyla-text :background ,chyla-selection :weight bold))))
;;;;; git-commit
   `(git-commit-comment-action  ((,class (:foreground ,chyla-text :weight bold))))
   `(git-commit-comment-branch  ((,class (:foreground ,chyla-keyword  :weight bold))))
   `(git-commit-comment-heading ((,class (:foreground ,chyla-keyword  :weight bold))))
;;;;; git-gutter
   `(git-gutter:added ((t (:foreground ,chyla-constant :weight bold))))
   `(git-gutter:deleted ((t (:foreground ,chyla-keyword :weight bold))))
   `(git-gutter:modified ((t (:foreground ,chyla-string :weight bold))))
   `(git-gutter:unchanged ((t (:foreground ,chyla-text :weight bold :inverse-video t))))
;;;;; git-gutter-fr
   `(git-gutter-fr:added ((t (:foreground ,chyla-comment  :weight bold))))
   `(git-gutter-fr:deleted ((t (:foreground ,chyla-string :weight bold))))
   `(git-gutter-fr:modified ((t (:foreground ,chyla-text :weight bold))))
;;;;; git-rebase
   `(git-rebase-hash ((t (:foreground, chyla-text))))
;;;;; gnus
   `(gnus-group-mail-1 ((t (:bold t :inherit gnus-group-mail-1-empty))))
   `(gnus-group-mail-1-empty ((t (:inherit gnus-group-news-1-empty))))
   `(gnus-group-mail-2 ((t (:bold t :inherit gnus-group-mail-2-empty))))
   `(gnus-group-mail-2-empty ((t (:inherit gnus-group-news-2-empty))))
   `(gnus-group-mail-3 ((t (:bold t :inherit gnus-group-mail-3-empty))))
   `(gnus-group-mail-3-empty ((t (:inherit gnus-group-news-3-empty))))
   `(gnus-group-mail-4 ((t (:bold t :inherit gnus-group-mail-4-empty))))
   `(gnus-group-mail-4-empty ((t (:inherit gnus-group-news-4-empty))))
   `(gnus-group-mail-5 ((t (:bold t :inherit gnus-group-mail-5-empty))))
   `(gnus-group-mail-5-empty ((t (:inherit gnus-group-news-5-empty))))
   `(gnus-group-mail-6 ((t (:bold t :inherit gnus-group-mail-6-empty))))
   `(gnus-group-mail-6-empty ((t (:inherit gnus-group-news-6-empty))))
   `(gnus-group-mail-low ((t (:bold t :inherit gnus-group-mail-low-empty))))
   `(gnus-group-mail-low-empty ((t (:inherit gnus-group-news-low-empty))))
   `(gnus-group-news-1 ((t (:bold t :inherit gnus-group-news-1-empty))))
   `(gnus-group-news-2 ((t (:bold t :inherit gnus-group-news-2-empty))))
   `(gnus-group-news-3 ((t (:bold t :inherit gnus-group-news-3-empty))))
   `(gnus-group-news-4 ((t (:bold t :inherit gnus-group-news-4-empty))))
   `(gnus-group-news-5 ((t (:bold t :inherit gnus-group-news-5-empty))))
   `(gnus-group-news-6 ((t (:bold t :inherit gnus-group-news-6-empty))))
   `(gnus-group-news-low ((t (:bold t :inherit gnus-group-news-low-empty))))
   `(gnus-header-content ((t (:inherit message-header-other))))
   `(gnus-header-from ((t (:inherit message-header-to))))
   `(gnus-header-name ((t (:inherit message-header-name))))
   `(gnus-header-newsgroups ((t (:inherit message-header-other))))
   `(gnus-header-subject ((t (:inherit message-header-subject))))
   `(gnus-server-opened ((t (:foreground ,chyla-comment :weight bold))))
   `(gnus-server-denied ((t (:foreground ,chyla-text :weight bold))))
   `(gnus-server-closed ((t (:foreground ,chyla-text :slant italic))))
   `(gnus-server-offline ((t (:foreground ,chyla-keyword :weight bold))))
   `(gnus-server-agent ((t (:foreground ,chyla-text :weight bold))))
   `(gnus-summary-cancelled ((t (:foreground ,chyla-text))))
   `(gnus-summary-high-ancient ((t (:foreground ,chyla-text))))
   `(gnus-summary-high-read ((t (:foreground ,chyla-comment :weight bold))))
   `(gnus-summary-high-ticked ((t (:foreground ,chyla-text :weight bold))))
   `(gnus-summary-high-unread ((t (:foreground ,chyla-text :weight bold))))
   `(gnus-summary-low-ancient ((t (:foreground ,chyla-text))))
   `(gnus-summary-low-read ((t (:foreground ,chyla-comment))))
   `(gnus-summary-low-ticked ((t (:foreground ,chyla-text :weight bold))))
   `(gnus-summary-low-unread ((t (:foreground ,chyla-text))))
   `(gnus-summary-normal-ancient ((t (:foreground ,chyla-text))))
   `(gnus-summary-normal-read ((t (:foreground ,chyla-comment))))
   `(gnus-summary-normal-ticked ((t (:foreground ,chyla-text :weight bold))))
   `(gnus-summary-normal-unread ((t (:foreground ,chyla-text))))
   `(gnus-summary-selected ((t (:foreground ,chyla-keyword :weight bold))))
   `(gnus-cite-1 ((t (:foreground ,chyla-text))))
   `(gnus-cite-10 ((t (:foreground ,chyla-text))))
   `(gnus-cite-11 ((t (:foreground ,chyla-keyword))))
   `(gnus-cite-2 ((t (:foreground ,chyla-constant))))
   `(gnus-cite-3 ((t (:foreground ,chyla-text))))
   `(gnus-cite-4 ((t (:foreground ,chyla-comment))))
   `(gnus-cite-5 ((t (:foreground ,chyla-text))))
   `(gnus-cite-6 ((t (:foreground ,chyla-comment))))
   `(gnus-cite-7 ((t (:foreground ,chyla-string))))
   `(gnus-cite-8 ((t (:foreground ,chyla-text))))
   `(gnus-cite-9 ((t (:foreground ,chyla-text))))
   `(gnus-group-news-1-empty ((t (:foreground ,chyla-keyword))))
   `(gnus-group-news-2-empty ((t (:foreground ,chyla-html-tag))))
   `(gnus-group-news-3-empty ((t (:foreground ,chyla-text))))
   `(gnus-group-news-4-empty ((t (:foreground ,chyla-text))))
   `(gnus-group-news-5-empty ((t (:foreground ,chyla-text))))
   `(gnus-group-news-6-empty ((t (:foreground ,chyla-white))))
   `(gnus-group-news-low-empty ((t (:foreground ,chyla-white))))
   `(gnus-signature ((t (:foreground ,chyla-keyword))))
   `(gnus-x ((t (:background ,chyla-text :foreground ,chyla-white))))
;;;;; guide-key
   `(guide-key/highlight-command-face ((t (:foreground ,chyla-text))))
   `(guide-key/key-face ((t (:foreground ,chyla-comment))))
   `(guide-key/prefix-command-face ((t (:foreground ,chyla-text))))
;;;;; helm
   `(helm-header
     ((t (:foreground ,chyla-comment
                      :background ,chyla-white
                      :underline nil
                      :box nil))))
   `(helm-source-header
     ((t (:foreground ,chyla-keyword
                      :background ,chyla-selection
                      :underline nil
                      :weight bold
                      :box (:line-width -1 :style released-button)))))
   `(helm-selection ((t (:background ,chyla-highlight :underline nil))))
   `(helm-selection-line ((t (:background ,chyla-white))))
   `(helm-visible-mark ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(helm-candidate-number ((t (:foreground ,chyla-constant :background ,chyla-selection))))
   `(helm-separator ((t (:foreground ,chyla-string :background ,chyla-white))))
   `(helm-time-zone-current ((t (:foreground ,chyla-comment :background ,chyla-white))))
   `(helm-time-zone-home ((t (:foreground ,chyla-string :background ,chyla-white))))
   `(helm-bookmark-addressbook ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(helm-bookmark-directory ((t (:foreground nil :background nil :inherit helm-ff-directory))))
   `(helm-bookmark-file ((t (:foreground nil :background nil :inherit helm-ff-file))))
   `(helm-bookmark-gnus ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(helm-bookmark-info ((t (:foreground ,chyla-comment :background ,chyla-white))))
   `(helm-bookmark-man ((t (:foreground ,chyla-keyword :background ,chyla-white))))
   `(helm-bookmark-w3m ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(helm-buffer-not-saved ((t (:foreground ,chyla-string :background ,chyla-white))))
   `(helm-buffer-process ((t (:foreground ,chyla-function :background ,chyla-white))))
   `(helm-buffer-saved-out ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(helm-buffer-size ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(helm-ff-directory ((t (:foreground ,chyla-function :background ,chyla-white :weight bold))))
   `(helm-ff-file ((t (:foreground ,chyla-text :background ,chyla-white :weight normal))))
   `(helm-ff-executable ((t (:foreground ,chyla-comment :background ,chyla-white :weight normal))))
   `(helm-ff-invalid-symlink ((t (:foreground ,chyla-string :background ,chyla-white :weight bold))))
   `(helm-ff-symlink ((t (:foreground ,chyla-keyword :background ,chyla-white :weight bold))))
   `(helm-ff-prefix ((t (:foreground ,chyla-white :background ,chyla-keyword :weight normal))))
   `(helm-grep-cmd-line ((t (:foreground ,chyla-function :background ,chyla-white))))
   `(helm-grep-file ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(helm-grep-finish ((t (:foreground ,chyla-comment :background ,chyla-white))))
   `(helm-grep-lineno ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(helm-grep-match ((t (:foreground nil :background nil :inherit helm-match))))
   `(helm-grep-running ((t (:foreground ,chyla-string :background ,chyla-white))))
   `(helm-match ((t (:foreground ,chyla-text :background ,chyla-selection :weight bold))))
   `(helm-moccur-buffer ((t (:foreground ,chyla-function :background ,chyla-white))))
   `(helm-mu-contacts-address-face ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(helm-mu-contacts-name-face ((t (:foreground ,chyla-text :background ,chyla-white))))
;;;;; helm-swoop
   `(helm-swoop-target-line-face ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(helm-swoop-target-word-face ((t (:foreground ,chyla-keyword :background ,chyla-white :weight bold))))
;;;;; highlight-numbers
   `(highlight-numbers-number ((t (:foreground ,chyla-constant))))
;;;;; hl-line-mode
   `(hl-line-face ((,class (:background ,chyla-highlight))
                   (t :weight bold)))
   `(hl-line ((,class (:background ,chyla-highlight)) ; old emacsen
              (t :weight bold)))
;;;;; hl-sexp
   `(hl-sexp-face ((,class (:background ,chyla-white))
                   (t :weight bold)))
;;;;; hlinum
   `(linum-highlight-face ((t (:foreground ,chyla-comment :background ,chyla-highlight))))
;;;;; hydra
   `(hydra-face-red ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(hydra-face-amaranth ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(hydra-face-blue ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(hydra-face-pink ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(hydra-face-teal ((t (:foreground ,chyla-function :background ,chyla-white))))
;;;;; ivy
   `(ivy-confirm-face ((t (:foreground ,chyla-comment :background ,chyla-white))))
   `(ivy-match-required-face ((t (:foreground ,chyla-string :background ,chyla-white))))
   `(ivy-remote ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(ivy-subdir ((t (:foreground ,chyla-keyword :background ,chyla-white))))
   `(ivy-current-match ((t (:foreground ,chyla-keyword :weight bold :underline t))))
   `(ivy-minibuffer-match-face-1 ((t (:background ,chyla-white))))
   `(ivy-minibuffer-match-face-2 ((t (:background ,chyla-comment))))
   `(ivy-minibuffer-match-face-3 ((t (:background ,chyla-comment))))
   `(ivy-minibuffer-match-face-4 ((t (:background ,chyla-text))))
;;;;; ido-mode
   `(ido-first-match ((t (:foreground ,chyla-keyword :weight bold))))
   `(ido-only-match ((t (:foreground ,chyla-text :weight bold))))
   `(ido-subdir ((t (:foreground ,chyla-keyword))))
   `(ido-indicator ((t (:foreground ,chyla-keyword :background ,chyla-text))))
;;;;; iedit-mode
   `(iedit-occurrence ((t (:background ,chyla-white :weight bold))))
;;;;; jabber-mode
   `(jabber-roster-user-away ((t (:foreground ,chyla-comment))))
   `(jabber-roster-user-online ((t (:foreground ,chyla-constant))))
   `(jabber-roster-user-dnd ((t (:foreground ,chyla-text))))
   `(jabber-roster-user-xa ((t (:foreground ,chyla-text))))
   `(jabber-roster-user-chatty ((t (:foreground ,chyla-text))))
   `(jabber-roster-user-error ((t (:foreground ,chyla-text))))
   `(jabber-rare-time-face ((t (:foreground ,chyla-text))))
   `(jabber-chat-prompt-local ((t (:foreground ,chyla-constant))))
   `(jabber-chat-prompt-foreign ((t (:foreground ,chyla-text))))
   `(jabber-chat-prompt-system ((t (:foreground ,chyla-html-tag))))
   `(jabber-activity-face((t (:foreground ,chyla-text))))
   `(jabber-activity-personal-face ((t (:foreground ,chyla-keyword))))
   `(jabber-title-small ((t (:height 1.1 :weight bold))))
   `(jabber-title-medium ((t (:height 1.2 :weight bold))))
   `(jabber-title-large ((t (:height 1.3 :weight bold))))
;;;;; js2-mode
   `(js2-warning ((t (:underline ,chyla-text))))
   `(js2-error ((t (:foreground ,chyla-string :weight bold))))
   `(js2-jsdoc-tag ((t (:foreground ,chyla-comment))))
   `(js2-jsdoc-type ((t (:foreground ,chyla-comment))))
   `(js2-jsdoc-value ((t (:foreground ,chyla-html-tag))))
   `(js2-function-param ((t (:foreground, chyla-text))))
   `(js2-external-variable ((t (:foreground ,chyla-text))))
;;;;; additional js2 mode attributes for better syntax highlighting
   `(js2-instance-member ((t (:foreground ,chyla-comment))))
   `(js2-jsdoc-html-tag-delimiter ((t (:foreground ,chyla-text))))
   `(js2-jsdoc-html-tag-name ((t (:foreground ,chyla-text))))
   `(js2-object-property ((t (:foreground ,chyla-keyword))))
   `(js2-magic-paren ((t (:foreground ,chyla-text))))
   `(js2-private-function-call ((t (:foreground ,chyla-function))))
   `(js2-function-call ((t (:foreground ,chyla-function))))
   `(js2-private-member ((t (:foreground ,chyla-constant))))
   `(js2-keywords ((t (:foreground ,chyla-text))))
;;;;; ledger-mode
   `(ledger-font-payee-uncleared-face ((t (:foreground ,chyla-text :weight bold))))
   `(ledger-font-payee-cleared-face ((t (:foreground ,chyla-text :weight normal))))
   `(ledger-font-xact-highlight-face ((t (:background ,chyla-white))))
   `(ledger-font-pending-face ((t (:foreground ,chyla-text weight: normal))))
   `(ledger-font-other-face ((t (:foreground ,chyla-text))))
   `(ledger-font-posting-account-face ((t (:foreground ,chyla-constant))))
   `(ledger-font-posting-account-cleared-face ((t (:foreground ,chyla-text))))
   `(ledger-font-posting-account-pending-face ((t (:foreground ,chyla-text))))
   `(ledger-font-posting-amount-face ((t (:foreground ,chyla-text))))
   `(ledger-occur-narrowed-face ((t (:foreground ,chyla-text :invisible t))))
   `(ledger-occur-xact-face ((t (:background ,chyla-white))))
   `(ledger-font-comment-face ((t (:foreground ,chyla-comment))))
   `(ledger-font-reconciler-uncleared-face ((t (:foreground ,chyla-text :weight bold))))
   `(ledger-font-reconciler-cleared-face ((t (:foreground ,chyla-text :weight normal))))
   `(ledger-font-reconciler-pending-face ((t (:foreground ,chyla-text :weight normal))))
   `(ledger-font-report-clickable-face ((t (:foreground ,chyla-text :weight normal))))
;;;;; linum-mode
   `(linum ((t (:foreground ,chyla-comment :background ,chyla-white))))
;;;;; lispy
   `(lispy-command-name-face ((t (:background ,chyla-highlight :inherit font-lock-function-name-face))))
   `(lispy-cursor-face ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(lispy-face-hint ((t (:inherit highlight :foreground ,chyla-keyword))))
;;;;; ruler-mode
   `(ruler-mode-column-number ((t (:inherit 'ruler-mode-default :foreground ,chyla-text))))
   `(ruler-mode-fill-column ((t (:inherit 'ruler-mode-default :foreground ,chyla-keyword))))
   `(ruler-mode-goal-column ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-comment-column ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-tab-stop ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-current-column ((t (:foreground ,chyla-keyword :box t))))
   `(ruler-mode-default ((t (:foreground ,chyla-comment :background ,chyla-white))))

;;;;; lui
   `(lui-time-stamp-face ((t (:foreground ,chyla-constant))))
   `(lui-hilight-face ((t (:foreground ,chyla-comment :background ,chyla-white))))
   `(lui-button-face ((t (:inherit hover-highlight))))
;;;;; macrostep
   `(macrostep-gensym-1
     ((t (:foreground ,chyla-comment :background ,chyla-selection))))
   `(macrostep-gensym-2
     ((t (:foreground ,chyla-text :background ,chyla-selection))))
   `(macrostep-gensym-3
     ((t (:foreground ,chyla-keyword :background ,chyla-selection))))
   `(macrostep-gensym-4
     ((t (:foreground ,chyla-text :background ,chyla-selection))))
   `(macrostep-gensym-5
     ((t (:foreground ,chyla-keyword :background ,chyla-selection))))
   `(macrostep-expansion-highlight-face
     ((t (:inherit highlight))))
   `(macrostep-macro-face
     ((t (:underline t))))
;;;;; magit
;;;;;; headings and diffs
   `(magit-section-highlight           ((t (:background ,chyla-white))))
   `(magit-section-heading             ((t (:foreground ,chyla-keyword :weight bold))))
   `(magit-section-heading-selection   ((t (:foreground ,chyla-text :weight bold))))
   `(magit-diff-file-heading           ((t (:weight bold))))
   `(magit-diff-file-heading-highlight ((t (:background ,chyla-white  :weight bold))))
   `(magit-diff-file-heading-selection ((t (:background ,chyla-white
                                                        :foreground ,chyla-text :weight bold))))
   `(magit-diff-hunk-heading           ((t (:background ,chyla-white))))
   `(magit-diff-hunk-heading-highlight ((t (:background ,chyla-white))))
   `(magit-diff-hunk-heading-selection ((t (:background ,chyla-white
                                                        :foreground ,chyla-text))))
   `(magit-diff-lines-heading          ((t (:background ,chyla-text
                                                        :foreground ,chyla-white))))
   `(magit-diff-context-highlight      ((t (:background ,chyla-white
                                                        :foreground "grey70"))))
   `(magit-diffstat-added   ((t (:foreground ,chyla-constant))))
   `(magit-diffstat-removed ((t (:foreground ,chyla-string))))
;;;;;; popup
   `(magit-popup-heading             ((t (:foreground ,chyla-keyword  :weight bold))))
   `(magit-popup-key                 ((t (:foreground ,chyla-comment :weight bold))))
   `(magit-popup-argument            ((t (:foreground ,chyla-comment   :weight bold))))
   `(magit-popup-disabled-argument   ((t (:foreground ,chyla-text    :weight normal))))
   `(magit-popup-option-value        ((t (:foreground ,chyla-text  :weight bold))))
;;;;;; process
   `(magit-process-ok    ((t (:foreground ,chyla-comment  :weight bold))))
   `(magit-process-ng    ((t (:foreground ,chyla-string    :weight bold))))
;;;;;; log
   `(magit-log-author    ((t (:foreground ,chyla-text))))
   `(magit-log-date      ((t (:foreground ,chyla-text))))
   `(magit-log-graph     ((t (:foreground ,chyla-text))))
;;;;;; sequence
   `(magit-sequence-pick ((t (:foreground ,chyla-text))))
   `(magit-sequence-stop ((t (:foreground ,chyla-comment))))
   `(magit-sequence-part ((t (:foreground ,chyla-keyword))))
   `(magit-sequence-head ((t (:foreground ,chyla-text))))
   `(magit-sequence-drop ((t (:foreground ,chyla-string))))
   `(magit-sequence-done ((t (:foreground ,chyla-text))))
   `(magit-sequence-onto ((t (:foreground ,chyla-text))))
;;;;;; bisect
   `(magit-bisect-good ((t (:foreground ,chyla-comment))))
   `(magit-bisect-skip ((t (:foreground ,chyla-keyword))))
   `(magit-bisect-bad  ((t (:foreground ,chyla-string))))
;;;;;; blame
   `(magit-blame-heading ((t (:background ,chyla-selection :foreground ,chyla-text))))
   `(magit-blame-hash    ((t (:background ,chyla-selection :foreground ,chyla-text))))
   `(magit-blame-name    ((t (:background ,chyla-selection :foreground ,chyla-text))))
   `(magit-blame-date    ((t (:background ,chyla-selection :foreground ,chyla-text))))
   `(magit-blame-summary ((t (:background ,chyla-selection :foreground ,chyla-text
                                          :weight bold))))
;;;;;; references etc
   `(magit-dimmed         ((t (:foreground ,chyla-text))))
   `(magit-hash           ((t (:foreground ,chyla-text))))
   `(magit-tag            ((t (:foreground ,chyla-text :weight bold))))
   `(magit-branch-remote  ((t (:foreground ,chyla-comment  :weight bold))))
   `(magit-branch-local   ((t (:foreground ,chyla-text   :weight bold))))
   `(magit-branch-current ((t (:foreground ,chyla-text   :weight bold :box t))))
   `(magit-head           ((t (:foreground ,chyla-text   :weight bold))))
   `(magit-refname        ((t (:background ,chyla-white :foreground ,chyla-text :weight bold))))
   `(magit-refname-stash  ((t (:background ,chyla-white :foreground ,chyla-text :weight bold))))
   `(magit-refname-wip    ((t (:background ,chyla-white :foreground ,chyla-text :weight bold))))
   `(magit-signature-good      ((t (:foreground ,chyla-comment))))
   `(magit-signature-bad       ((t (:foreground ,chyla-string))))
   `(magit-signature-untrusted ((t (:foreground ,chyla-keyword))))
   `(magit-cherry-unmatched    ((t (:foreground ,chyla-function))))
   `(magit-cherry-equivalent   ((t (:foreground ,chyla-text))))
   `(magit-reflog-commit       ((t (:foreground ,chyla-comment))))
   `(magit-reflog-amend        ((t (:foreground ,chyla-text))))
   `(magit-reflog-merge        ((t (:foreground ,chyla-comment))))
   `(magit-reflog-checkout     ((t (:foreground ,chyla-text))))
   `(magit-reflog-reset        ((t (:foreground ,chyla-string))))
   `(magit-reflog-rebase       ((t (:foreground ,chyla-text))))
   `(magit-reflog-cherry-pick  ((t (:foreground ,chyla-comment))))
   `(magit-reflog-remote       ((t (:foreground ,chyla-function))))
   `(magit-reflog-other        ((t (:foreground ,chyla-function))))
;;;;; message-mode
   `(message-cited-text ((t (:inherit font-lock-comment-face))))
   `(message-header-name ((t (:foreground ,chyla-text))))
   `(message-header-other ((t (:foreground ,chyla-comment))))
   `(message-header-to ((t (:foreground ,chyla-keyword :weight bold))))
   `(message-header-cc ((t (:foreground ,chyla-keyword :weight bold))))
   `(message-header-newsgroups ((t (:foreground ,chyla-keyword :weight bold))))
   `(message-header-subject ((t (:foreground ,chyla-text :weight bold))))
   `(message-header-xheader ((t (:foreground ,chyla-comment))))
   `(message-mml ((t (:foreground ,chyla-keyword :weight bold))))
   `(message-separator ((t (:inherit font-lock-comment-face))))
;;;;; mew
   `(mew-face-header-subject ((t (:foreground ,chyla-text))))
   `(mew-face-header-from ((t (:foreground ,chyla-keyword))))
   `(mew-face-header-date ((t (:foreground ,chyla-comment))))
   `(mew-face-header-to ((t (:foreground ,chyla-string))))
   `(mew-face-header-key ((t (:foreground ,chyla-comment))))
   `(mew-face-header-private ((t (:foreground ,chyla-comment))))
   `(mew-face-header-important ((t (:foreground ,chyla-text))))
   `(mew-face-header-marginal ((t (:foreground ,chyla-text :weight bold))))
   `(mew-face-header-warning ((t (:foreground ,chyla-string))))
   `(mew-face-header-xmew ((t (:foreground ,chyla-comment))))
   `(mew-face-header-xmew-bad ((t (:foreground ,chyla-string))))
   `(mew-face-body-url ((t (:foreground ,chyla-text))))
   `(mew-face-body-comment ((t (:foreground ,chyla-text :slant italic))))
   `(mew-face-body-cite1 ((t (:foreground ,chyla-comment))))
   `(mew-face-body-cite2 ((t (:foreground ,chyla-text))))
   `(mew-face-body-cite3 ((t (:foreground ,chyla-text))))
   `(mew-face-body-cite4 ((t (:foreground ,chyla-keyword))))
   `(mew-face-body-cite5 ((t (:foreground ,chyla-string))))
   `(mew-face-mark-review ((t (:foreground ,chyla-text))))
   `(mew-face-mark-escape ((t (:foreground ,chyla-comment))))
   `(mew-face-mark-delete ((t (:foreground ,chyla-string))))
   `(mew-face-mark-unlink ((t (:foreground ,chyla-keyword))))
   `(mew-face-mark-refile ((t (:foreground ,chyla-comment))))
   `(mew-face-mark-unread ((t (:foreground ,chyla-text))))
   `(mew-face-eof-message ((t (:foreground ,chyla-comment))))
   `(mew-face-eof-part ((t (:foreground ,chyla-keyword))))
;;;;; mic-paren
   `(paren-face-match ((t (:foreground ,chyla-function :background ,chyla-white :weight bold))))
   `(paren-face-mismatch ((t (:foreground ,chyla-white :background ,chyla-text :weight bold))))
   `(paren-face-no-match ((t (:foreground ,chyla-white :background ,chyla-string :weight bold))))
;;;;; mingus
   `(mingus-directory-face ((t (:foreground ,chyla-text))))
   `(mingus-pausing-face ((t (:foreground ,chyla-text))))
   `(mingus-playing-face ((t (:foreground ,chyla-function))))
   `(mingus-playlist-face ((t (:foreground ,chyla-function ))))
   `(mingus-song-file-face ((t (:foreground ,chyla-keyword))))
   `(mingus-stopped-face ((t (:foreground ,chyla-string))))
;;;;; nav
   `(nav-face-heading ((t (:foreground ,chyla-keyword))))
   `(nav-face-button-num ((t (:foreground ,chyla-function))))
   `(nav-face-dir ((t (:foreground ,chyla-comment))))
   `(nav-face-hdir ((t (:foreground ,chyla-string))))
   `(nav-face-file ((t (:foreground ,chyla-text))))
   `(nav-face-hfile ((t (:foreground ,chyla-text))))
;;;;; mu4e
   `(mu4e-cited-1-face ((t (:foreground ,chyla-text    :slant italic))))
   `(mu4e-cited-2-face ((t (:foreground ,chyla-comment :slant italic))))
   `(mu4e-cited-3-face ((t (:foreground ,chyla-text  :slant italic))))
   `(mu4e-cited-4-face ((t (:foreground ,chyla-comment   :slant italic))))
   `(mu4e-cited-5-face ((t (:foreground ,chyla-text  :slant italic))))
   `(mu4e-cited-6-face ((t (:foreground ,chyla-comment :slant italic))))
   `(mu4e-cited-7-face ((t (:foreground ,chyla-text    :slant italic))))
   `(mu4e-replied-face ((t (:foreground ,chyla-text))))
   `(mu4e-trashed-face ((t (:foreground ,chyla-text :strike-through t))))
;;;;; mumamo
   `(mumamo-background-chunk-major ((t (:background nil))))
   `(mumamo-background-chunk-submode1 ((t (:background ,chyla-selection))))
   `(mumamo-background-chunk-submode2 ((t (:background ,chyla-white))))
   `(mumamo-background-chunk-submode3 ((t (:background ,chyla-white))))
   `(mumamo-background-chunk-submode4 ((t (:background ,chyla-white))))
;;;;; neotree
   `(neo-banner-face ((t (:foreground ,chyla-keyword :weight bold))))
   `(neo-header-face ((t (:foreground ,chyla-text))))
   `(neo-root-dir-face ((t (:foreground ,chyla-keyword :weight bold))))
   `(neo-dir-link-face ((t (:foreground ,chyla-text))))
   `(neo-file-link-face ((t (:foreground ,chyla-text))))
   `(neo-expand-btn-face ((t (:foreground ,chyla-text))))
   `(neo-vc-default-face ((t (:foreground ,chyla-text))))
   `(neo-vc-user-face ((t (:foreground ,chyla-string :slant italic))))
   `(neo-vc-up-to-date-face ((t (:foreground ,chyla-text))))
   `(neo-vc-edited-face ((t (:foreground ,chyla-text))))
   `(neo-vc-needs-merge-face ((t (:foreground ,chyla-text))))
   `(neo-vc-unlocked-changes-face ((t (:foreground ,chyla-string :background ,chyla-text))))
   `(neo-vc-added-face ((t (:foreground ,chyla-text))))
   `(neo-vc-conflict-face ((t (:foreground ,chyla-text))))
   `(neo-vc-missing-face ((t (:foreground ,chyla-text))))
   `(neo-vc-ignored-face ((t (:foreground ,chyla-text))))
;;;;; org-mode
   `(org-agenda-clocking
     ((t (:bold t :background ,chyla-highlight))) t)
   `(org-agenda-date-today
     ((t (:foreground ,chyla-text :slant italic :weight bold))) t)
   `(org-agenda-structure
     ((t (:inherit font-lock-comment-face))))
   `(org-archived ((t (:foreground ,chyla-text :weight bold))))
   `(org-checkbox ((t (:background ,chyla-white :foreground ,chyla-text
                                   :box (:line-width 1 :style released-button)))))
   `(org-date ((t (:foreground ,chyla-text :underline t))))
   `(org-deadline-announce ((t (:foreground ,chyla-text))))
   `(org-done ((t (:bold t :weight bold :foreground ,chyla-html-tag))))
   `(org-formula ((t (:foreground ,chyla-text))))
   `(org-headline-done ((t (:foreground ,chyla-html-tag))))
   `(org-hide ((t (:foreground ,chyla-selection))))
   `(org-level-1 ((t (:foreground ,chyla-text))))
   `(org-level-2 ((t (:foreground ,chyla-constant))))
   `(org-level-3 ((t (:foreground ,chyla-constant))))
   `(org-level-4 ((t (:foreground ,chyla-text))))
   `(org-level-5 ((t (:foreground ,chyla-function))))
   `(org-level-6 ((t (:foreground ,chyla-comment))))
   `(org-level-7 ((t (:foreground ,chyla-text))))
   `(org-level-8 ((t (:foreground ,chyla-text))))
   `(org-link ((t (:foreground ,chyla-text :underline t))))
   `(org-scheduled ((t (:foreground ,chyla-constant))))
   `(org-scheduled-previously ((t (:foreground ,chyla-string))))
   `(org-scheduled-today ((t (:foreground ,chyla-keyword))))
   `(org-sexp-date ((t (:foreground ,chyla-keyword :underline t))))
   `(org-special-keyword ((t (:inherit font-lock-comment-face))))
   `(org-table ((t (:foreground ,chyla-comment))))
   `(org-tag ((t (:bold t :weight bold))))
   `(org-time-grid ((t (:foreground ,chyla-text))))
   `(org-todo ((t (:bold t :foreground ,chyla-string :weight bold))))
   `(org-upcoming-deadline ((t (:inherit font-lock-keyword-face))))
   `(org-warning ((t (:bold t :foreground ,chyla-string :weight bold :underline nil))))
   `(org-column ((t (:background ,chyla-selection))))
   `(org-column-title ((t (:background ,chyla-selection :underline t :weight bold))))
   `(org-mode-line-clock ((t (:foreground ,chyla-text :background ,chyla-selection))))
   `(org-mode-line-clock-overrun ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(org-ellipsis ((t (:foreground ,chyla-text :underline t))))
   `(org-footnote ((t (:foreground ,chyla-function :underline t))))
   `(org-document-title ((t (:foreground ,chyla-text))))
   `(org-document-info ((t (:foreground ,chyla-text))))
   `(org-habit-ready-face ((t :background ,chyla-comment)))
   `(org-habit-alert-face ((t :background ,chyla-text :foreground ,chyla-white)))
   `(org-habit-clear-face ((t :background ,chyla-text)))
   `(org-habit-overdue-face ((t :background ,chyla-text)))
   `(org-habit-clear-future-face ((t :background ,chyla-text)))
   `(org-habit-ready-future-face ((t :background ,chyla-comment)))
   `(org-habit-alert-future-face ((t :background ,chyla-text :foreground ,chyla-white)))
   `(org-habit-overdue-future-face ((t :background ,chyla-text)))
;;;;; outline
   `(outline-1 ((t (:foreground ,chyla-text))))
   `(outline-2 ((t (:foreground ,chyla-constant))))
   `(outline-3 ((t (:foreground ,chyla-constant))))
   `(outline-4 ((t (:foreground ,chyla-text))))
   `(outline-5 ((t (:foreground ,chyla-function))))
   `(outline-6 ((t (:foreground ,chyla-comment))))
   `(outline-7 ((t (:foreground ,chyla-text))))
   `(outline-8 ((t (:foreground ,chyla-text))))
;;;;; p4
   `(p4-depot-added-face ((t :inherit diff-added)))
   `(p4-depot-branch-op-face ((t :inherit diff-changed)))
   `(p4-depot-deleted-face ((t :inherit diff-removed)))
   `(p4-depot-unmapped-face ((t :inherit diff-changed)))
   `(p4-diff-change-face ((t :inherit diff-changed)))
   `(p4-diff-del-face ((t :inherit diff-removed)))
   `(p4-diff-file-face ((t :inherit diff-file-header)))
   `(p4-diff-head-face ((t :inherit diff-header)))
   `(p4-diff-ins-face ((t :inherit diff-added)))
;;;;; perspective
   `(persp-selected-face ((t (:foreground ,chyla-text :inherit mode-line))))
;;;;; powerline
   `(powerline-active1 ((t (:background ,chyla-string :inherit mode-line))))
   `(powerline-active2 ((t (:background ,chyla-keyword :inherit mode-line))))
   `(powerline-inactive1 ((t (:inherit mode-line-inactive))))
   `(powerline-inactive2 ((t (:inherit mode-line-inactive))))
;;;;; proofgeneral
   `(proof-active-area-face ((t (:underline t))))
   `(proof-boring-face ((t (:foreground ,chyla-text :background ,chyla-white))))
   `(proof-command-mouse-highlight-face ((t (:inherit proof-mouse-highlight-face))))
   `(proof-debug-message-face ((t (:inherit proof-boring-face))))
   `(proof-declaration-name-face ((t (:inherit font-lock-keyword-face :foreground nil))))
   `(proof-eager-annotation-face ((t (:foreground ,chyla-white :background ,chyla-text))))
   `(proof-error-face ((t (:foreground ,chyla-text :background ,chyla-text))))
   `(proof-highlight-dependency-face ((t (:foreground ,chyla-white :background ,chyla-comment))))
   `(proof-highlight-dependent-face ((t (:foreground ,chyla-white :background ,chyla-comment))))
   `(proof-locked-face ((t (:background ,chyla-comment))))
   `(proof-mouse-highlight-face ((t (:foreground ,chyla-white :background ,chyla-comment))))
   `(proof-queue-face ((t (:background ,chyla-comment))))
   `(proof-region-mouse-highlight-face ((t (:inherit proof-mouse-highlight-face))))
   `(proof-script-highlight-error-face ((t (:background ,chyla-comment))))
   `(proof-tacticals-name-face ((t (:inherit font-lock-constant-face :foreground nil :background ,chyla-white))))
   `(proof-tactics-name-face ((t (:inherit font-lock-constant-face :foreground nil :background ,chyla-white))))
   `(proof-warning-face ((t (:foreground ,chyla-white :background ,chyla-comment))))
;;;;; racket-mode
   `(racket-keyword-argument-face ((t (:inherit font-lock-constant-face))))
   `(racket-selfeval-face ((t (:inherit font-lock-type-face))))
;;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,chyla-comment))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,chyla-constant))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,chyla-comment))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,chyla-function))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground ,chyla-comment))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,chyla-keyword))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,chyla-comment))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground ,chyla-comment))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground ,chyla-comment))))
   `(rainbow-delimiters-depth-10-face ((t (:foreground ,chyla-comment))))
   `(rainbow-delimiters-depth-11-face ((t (:foreground ,chyla-comment))))
   `(rainbow-delimiters-depth-12-face ((t (:foreground ,chyla-comment))))
;;;;; rcirc
   `(rcirc-my-nick ((t (:foreground ,chyla-comment))))
   `(rcirc-other-nick ((t (:foreground ,chyla-comment))))
   `(rcirc-bright-nick ((t (:foreground ,chyla-keyword))))
   `(rcirc-dim-nick ((t (:foreground ,chyla-comment))))
   `(rcirc-server ((t (:foreground ,chyla-comment))))
   `(rcirc-server-prefix ((t (:foreground ,chyla-comment))))
   `(rcirc-timestamp ((t (:foreground ,chyla-comment))))
   `(rcirc-nick-in-message ((t (:foreground ,chyla-keyword))))
   `(rcirc-nick-in-message-full-line ((t (:bold t))))
   `(rcirc-prompt ((t (:foreground ,chyla-keyword :bold t))))
   `(rcirc-track-nick ((t (:inverse-video t))))
   `(rcirc-track-keyword ((t (:bold t))))
   `(rcirc-url ((t (:bold t))))
   `(rcirc-keyword ((t (:foreground ,chyla-keyword :bold t))))
;;;;; realgud
   `(realgud-overlay-arrow1 ((t (:foreground "#24292e"))))
   `(realgud-overlay-arrow2 ((t (:foreground "#63645c"))))
   `(realgud-overlay-arrow3 ((t (:foreground "#bcbdc0"))))
;;;;; rpm-mode
   `(rpm-spec-dir-face ((t (:foreground ,chyla-comment))))
   `(rpm-spec-doc-face ((t (:foreground ,chyla-comment))))
   `(rpm-spec-ghost-face ((t (:foreground ,chyla-string))))
   `(rpm-spec-macro-face ((t (:foreground ,chyla-keyword))))
   `(rpm-spec-obsolete-tag-face ((t (:foreground ,chyla-string))))
   `(rpm-spec-package-face ((t (:foreground ,chyla-string))))
   `(rpm-spec-section-face ((t (:foreground ,chyla-keyword))))
   `(rpm-spec-tag-face ((t (:foreground ,chyla-comment))))
   `(rpm-spec-var-face ((t (:foreground ,chyla-string))))
;;;;; rst-mode
   `(rst-level-1-face ((t (:foreground ,chyla-comment))))
   `(rst-level-2-face ((t (:foreground ,chyla-comment))))
   `(rst-level-3-face ((t (:foreground ,chyla-constant))))
   `(rst-level-4-face ((t (:foreground ,chyla-comment))))
   `(rst-level-5-face ((t (:foreground ,chyla-function))))
   `(rst-level-6-face ((t (:foreground ,chyla-comment))))
;;;;; sh-mode
   `(sh-heredoc     ((t (:foreground ,chyla-keyword :bold t))))
   `(sh-quoted-exec ((t (:foreground ,chyla-string))))
;;;;; show-paren
   `(show-paren-mismatch ((t (:foreground ,chyla-comment :background ,chyla-white :weight bold))))
   `(show-paren-match ((t (:foreground ,chyla-white :background ,chyla-keyword :weight bold))))
;;;;; smart-mode-line
   ;; use (setq sml/theme nil) to enable chyla.org for sml
   `(sml/global ((,class (:foreground ,chyla-comment :weight bold))))
   `(sml/modes ((,class (:foreground ,chyla-keyword :weight bold))))
   `(sml/minor-modes ((,class (:foreground ,chyla-comment :weight bold))))
   `(sml/filename ((,class (:foreground ,chyla-keyword :weight bold))))
   `(sml/line-number ((,class (:foreground ,chyla-comment :weight bold))))
   `(sml/col-number ((,class (:foreground ,chyla-keyword :weight bold))))
   `(sml/position-percentage ((,class (:foreground ,chyla-constant :weight bold))))
   `(sml/prefix ((,class (:foreground ,chyla-comment))))
   `(sml/git ((,class (:foreground ,chyla-html-tag))))
   `(sml/process ((,class (:weight bold))))
   `(sml/sudo ((,class  (:foreground ,chyla-comment :weight bold))))
   `(sml/read-only ((,class (:foreground ,chyla-comment))))
   `(sml/outside-modified ((,class (:foreground ,chyla-comment))))
   `(sml/modified ((,class (:foreground ,chyla-string))))
   `(sml/vc-edited ((,class (:foreground ,chyla-comment))))
   `(sml/charging ((,class (:foreground ,chyla-constant))))
   `(sml/discharging ((,class (:foreground ,chyla-comment))))
;;;;; smartparens
   `(sp-show-pair-mismatch-face ((t (:foreground ,chyla-comment :background ,chyla-white :weight bold))))
   `(sp-show-pair-match-face ((t (:background ,chyla-white :weight bold))))
;;;;; sml-mode-line
   '(sml-modeline-end-face ((t :inherit default :width condensed)))
;;;;; SLIME
   `(slime-repl-output-face ((t (:foreground ,chyla-string))))
   `(slime-repl-inputed-output-face ((t (:foreground ,chyla-comment))))
   `(slime-error-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-string)))
      (t
       (:underline ,chyla-string))))
   `(slime-warning-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-comment)))
      (t
       (:underline ,chyla-comment))))
   `(slime-style-warning-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-keyword)))
      (t
       (:underline ,chyla-keyword))))
   `(slime-note-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,chyla-comment)))
      (t
       (:underline ,chyla-comment))))
   `(slime-highlight-face ((t (:inherit highlight))))
;;;;; speedbar
   `(speedbar-button-face ((t (:foreground ,chyla-comment))))
   `(speedbar-directory-face ((t (:foreground ,chyla-function))))
   `(speedbar-file-face ((t (:foreground ,chyla-comment))))
   `(speedbar-highlight-face ((t (:foreground ,chyla-white :background ,chyla-comment))))
   `(speedbar-selected-face ((t (:foreground ,chyla-string))))
   `(speedbar-separator-face ((t (:foreground ,chyla-white :background ,chyla-constant))))
   `(speedbar-tag-face ((t (:foreground ,chyla-keyword))))
;;;;; tabbar
   `(tabbar-button ((t (:foreground ,chyla-comment
                                    :background ,chyla-white))))
   `(tabbar-selected ((t (:foreground ,chyla-comment
                                      :background ,chyla-white
                                      :box (:line-width -1 :style pressed-button)))))
   `(tabbar-unselected ((t (:foreground ,chyla-comment
                                        :background ,chyla-white
                                        :box (:line-width -1 :style released-button)))))
;;;;; term
   `(term-color-black ((t (:foreground ,chyla-white
                                       :background ,chyla-selection))))
   `(term-color-red ((t (:foreground ,chyla-comment
                                     :background ,chyla-comment))))
   `(term-color-green ((t (:foreground ,chyla-comment
                                       :background ,chyla-comment))))
   `(term-color-yellow ((t (:foreground ,chyla-comment
                                        :background ,chyla-keyword))))
   `(term-color-blue ((t (:foreground ,chyla-constant
                                      :background ,chyla-comment))))
   `(term-color-magenta ((t (:foreground ,chyla-comment
                                         :background ,chyla-string))))
   `(term-color-cyan ((t (:foreground ,chyla-function
                                      :background ,chyla-comment))))
   `(term-color-white ((t (:foreground ,chyla-comment
                                       :background ,chyla-comment))))
   '(term-default-fg-color ((t (:inherit term-color-white))))
   '(term-default-bg-color ((t (:inherit term-color-black))))
;;;;; undo-tree
   `(undo-tree-visualizer-active-branch-face ((t (:foreground ,chyla-comment :weight bold))))
   `(undo-tree-visualizer-current-face ((t (:foreground ,chyla-comment :weight bold))))
   `(undo-tree-visualizer-default-face ((t (:foreground ,chyla-comment))))
   `(undo-tree-visualizer-register-face ((t (:foreground ,chyla-keyword))))
   `(undo-tree-visualizer-unmodified-face ((t (:foreground ,chyla-function))))
;;;;; volatile-highlights
   `(vhl/default-face ((t (:background ,chyla-highlight))))
;;;;; web-mode
   `(web-mode-builtin-face ((t (:inherit ,font-lock-builtin-face))))
   `(web-mode-comment-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-constant-face ((t (:inherit ,font-lock-constant-face))))
   `(web-mode-css-at-rule-face ((t (:foreground ,chyla-comment ))))
   `(web-mode-css-prop-face ((t (:foreground ,chyla-constant))))
   `(web-mode-css-pseudo-class-face ((t (:foreground ,chyla-html-tag :weight bold))))
   `(web-mode-css-rule-face ((t (:foreground ,chyla-html-tag))))
   `(web-mode-doctype-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-folded-face ((t (:underline t))))
   `(web-mode-function-name-face ((t (:foreground ,chyla-comment))))
   `(web-mode-html-attr-name-face ((t (:foreground ,chyla-function))))
   `(web-mode-html-attr-value-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-html-tag-face ((t (:foreground ,chyla-html-tag))))
   `(web-mode-keyword-face ((t (:inherit ,font-lock-keyword-face))))
   `(web-mode-preprocessor-face ((t (:inherit ,font-lock-preprocessor-face))))
   `(web-mode-string-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-type-face ((t (:inherit ,font-lock-type-face))))
   `(web-mode-variable-name-face ((t (:inherit ,font-lock-variable-name-face))))
   `(web-mode-server-background-face ((t (:background ,chyla-white))))
   `(web-mode-server-comment-face ((t (:inherit web-mode-comment-face))))
   `(web-mode-server-string-face ((t (:inherit web-mode-string-face))))
   `(web-mode-symbol-face ((t (:inherit font-lock-constant-face))))
   `(web-mode-warning-face ((t (:inherit font-lock-warning-face))))
   `(web-mode-whitespaces-face ((t (:background ,chyla-string))))
;;;;; whitespace-mode
   `(whitespace-space ((t (:background ,chyla-white :foreground ,chyla-white))))
   `(whitespace-hspace ((t (:background ,chyla-white :foreground ,chyla-white))))
   `(whitespace-tab ((t (:background ,chyla-comment))))
   `(whitespace-newline ((t (:foreground ,chyla-white))))
   `(whitespace-trailing ((t (:background ,chyla-string))))
   `(whitespace-line ((t (:background ,chyla-white :foreground ,chyla-comment))))
   `(whitespace-space-before-tab ((t (:background ,chyla-comment :foreground ,chyla-comment))))
   `(whitespace-indentation ((t (:background ,chyla-keyword :foreground ,chyla-string))))
   `(whitespace-empty ((t (:background ,chyla-keyword))))
   `(whitespace-space-after-tab ((t (:background ,chyla-keyword :foreground ,chyla-string))))
;;;;; wanderlust
   `(wl-highlight-folder-few-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-folder-many-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-folder-path-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-folder-unread-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-folder-zero-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-folder-unknown-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-message-citation-header ((t (:foreground ,chyla-comment))))
   `(wl-highlight-message-cited-text-1 ((t (:foreground ,chyla-string))))
   `(wl-highlight-message-cited-text-2 ((t (:foreground ,chyla-comment))))
   `(wl-highlight-message-cited-text-3 ((t (:foreground ,chyla-comment))))
   `(wl-highlight-message-cited-text-4 ((t (:foreground ,chyla-keyword))))
   `(wl-highlight-message-header-contents-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-message-headers-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-message-important-header-contents ((t (:foreground ,chyla-comment))))
   `(wl-highlight-message-header-contents ((t (:foreground ,chyla-comment))))
   `(wl-highlight-message-important-header-contents2 ((t (:foreground ,chyla-comment))))
   `(wl-highlight-message-signature ((t (:foreground ,chyla-comment))))
   `(wl-highlight-message-unimportant-header-contents ((t (:foreground ,chyla-comment))))
   `(wl-highlight-summary-answered-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-summary-disposed-face ((t (:foreground ,chyla-comment
                                                         :slant italic))))
   `(wl-highlight-summary-new-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-summary-normal-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-summary-thread-top-face ((t (:foreground ,chyla-keyword))))
   `(wl-highlight-thread-indent-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-summary-refiled-face ((t (:foreground ,chyla-comment))))
   `(wl-highlight-summary-displaying-face ((t (:underline t :weight bold))))
;;;;; which-func-mode
   `(which-func ((t (:foreground ,chyla-constant))))
;;;;; xcscope
   `(cscope-file-face ((t (:foreground ,chyla-keyword :weight bold))))
   `(cscope-function-face ((t (:foreground ,chyla-function :weight bold))))
   `(cscope-line-number-face ((t (:foreground ,chyla-string :weight bold))))
   `(cscope-mouse-face ((t (:foreground ,chyla-white :background ,chyla-keyword))))
   `(cscope-separator-face ((t (:foreground ,chyla-string :weight bold
                                            :underline t :overline t))))
;;;;; yascroll
   `(yascroll:thumb-text-area ((t (:background ,chyla-selection))))
   `(yascroll:thumb-fringe ((t (:background ,chyla-selection :foreground ,chyla-selection))))

;;;;; elscreen
  `(elscreen-tab-background-face ((t (:background ,chyla-keyword))))
  `(elscreen-tab-control-face ((t (:foreground ,chyla-white :background ,chyla-keyword))))
  `(elscreen-tab-current-screen-face ((t (:foreground ,chyla-text :background ,chyla-selection))))
  `(elscreen-tab-other-screen-face ((t (:foreground ,chyla-text :background ,chyla-highlight))))
  ))

;;; Theme Variables
(chyla-with-color-variables
  (custom-theme-set-variables
   'chyla
;;;;; ansi-color
   `(ansi-color-names-vector [,chyla-white ,chyla-string ,chyla-comment ,chyla-keyword
                                          ,chyla-comment ,chyla-comment ,chyla-function ,chyla-comment])
;;;;; fill-column-indicator
   `(fci-rule-color ,chyla-comment)
;;;;; nrepl-client
   `(nrepl-message-colors
     '(,chyla-string ,chyla-comment ,chyla-keyword ,chyla-comment ,chyla-constant
                    ,chyla-function ,chyla-keyword ,chyla-comment))
;;;;; pdf-tools
   `(pdf-view-midnight-colors '(,chyla-comment . ,chyla-highlight))
;;;;; vc-annotate
   `(vc-annotate-color-map
     '(( 20. . ,chyla-comment)
       ( 40. . ,chyla-string)
       ( 60. . ,chyla-comment)
       ( 80. . ,chyla-comment)
       (100. . ,chyla-comment)
       (120. . ,chyla-keyword)
       (140. . ,chyla-comment)
       (160. . ,chyla-comment)
       (180. . ,chyla-comment)
       (200. . ,chyla-comment)
       (220. . ,chyla-html-tag)
       (240. . ,chyla-constant)
       (260. . ,chyla-function)
       (280. . ,chyla-comment)
       (300. . ,chyla-constant)
       (320. . ,chyla-comment)
       (340. . ,chyla-keyword)
       (360. . ,chyla-comment)))
   `(vc-annotate-very-old-color ,chyla-comment)
   `(vc-annotate-background ,chyla-selection)
   ))

;;; Footer

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'chyla)

;; Local Variables:
;; no-byte-compile: t
;; indent-tabs-mode: nil
;; End:
;;; chyla-theme.el ends here
