;;; zweilight-theme.el --- A dark color theme for Emacs.

;; Copyright (C) 2011-2016 Bozhidar Batsov

;; Author: Philip Arvidsson <contact@philiparvidsson.com>
;; URL: http://github.com/philiparvidsson/zweilight-emacs
;; Package-Version: 20170113.605
;; Package-Commit: 890f27c939d8a358c9ef0f402fc3314f475ec874
;; Version: 2.4

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

;; Custom theme inspired by Hero Dark for Sublime Text.

;;; Credits:

;; This file is taken from the Zenburn theme by Bozhidar Batsov, so all
;; credits to him - I've merely modified the colors.

;;; Code:

(deftheme zweilight "The Zweilight color theme")

;;; Color Palette

(defvar zweilight-default-colors-alist
  '(("zweilight-yellow"        . "#ffe000")
    ("zweilight-yellow+1"      . "#efef80")
    ("zweilight-orange"        . "#ffa500")
    ("zweilight-blue"          . "#0bafed")
    ("zweilight-green"         . "#65ba08")
    ("zweilight-red"           . "#E81A14")
    ("zweilight-red-1"         . "#CF1712")
    ("zweilight-pink"          . "#ee11dd")
    ("zweilight-pink+1"        . "#DC8CC3")
    ("zweilight-grey+1"        . "#656555")
    ("zweilight-grey"          . "#4F4F4F")
    ("zweilight-grey-1"        . "#494949")
    ("zweilight-bg"            . "#1b1a24")
    ("zweilight-bg+1"          . "#1f1d2e")
    ("zweilight-bg+2"          . "#211f30")
    ("zweilight-bg+3"          . "#252634")
    ("zweilight-fg"            . "#8584ae")
    ("zweilight-fg-1"          . "#4c406d")
    ("zweilight-red-pastel"    . "#8C5353")
    ("zweilight-red-pastel+1"  . "#9C6363")
    ("zweilight-red-pastel+2"  . "#AC7373")
    ("zweilight-red-pastel+3"  . "#BC8383")
    ("zweilight-red-pastel+4"  . "#DCA3A3")
    ("zweilight-cyan"          . "#b4f5fe")
    ("zweilight-cyan-1"        . "#8CD0D3")
    ("zweilight-cyan-2"        . "#6CA0A3")
    ("zweilight-cyan-3"        . "#5C888B"))
  "List of Zweilight colors.
Each element has the form (NAME . HEX).

`+N' suffixes indicate a color is lighter.
`-N' suffixes indicate a color is darker.")

(defvar zweilight-override-colors-alist
  '()
  "Place to override default theme colors.

You can override a subset of the theme's default colors by
defining them in this alist before loading the theme.")

(defvar zweilight-colors-alist
  (append zweilight-default-colors-alist zweilight-override-colors-alist))

(defmacro zweilight-with-color-variables (&rest body)
  "`let' bind all colors defined in `zweilight-colors-alist' around BODY.
Also bind `class' to ((class color) (min-colors 89))."
  (declare (indent 0))
  `(let ((class '((class color) (min-colors 89)))
         ,@(mapcar (lambda (cons)
                     (list (intern (car cons)) (cdr cons)))
                   zweilight-colors-alist))
     ,@body))

;;; Theme Faces
(zweilight-with-color-variables
  (custom-theme-set-faces
   'zweilight
;;;; Built-in
;;;;; basic coloring
   '(button ((t (:underline t))))
   `(link ((t (:foreground ,zweilight-cyan :underline t :weight bold))))
   `(link-visited ((t (:foreground ,zweilight-yellow :underline t :weight normal))))
   `(default ((t (:foreground ,zweilight-fg :background ,zweilight-bg))))
   `(cursor ((t (:foreground ,zweilight-fg :background ,zweilight-yellow))))
   `(escape-glyph ((t (:foreground ,zweilight-cyan :bold t))))
   `(fringe ((t (:foreground ,zweilight-fg :background ,zweilight-bg))))
   `(header-line ((t (:foreground ,zweilight-cyan
                                  :background ,zweilight-blue
                                  :box (:line-width -1 :style released-button)))))
   `(highlight ((t (:background ,zweilight-bg+3))))
   `(success ((t (:foreground ,zweilight-fg-1 :weight bold))))
   `(warning ((t (:foreground ,zweilight-fg :weight bold))))
   `(tooltip ((t (:foreground ,zweilight-fg :background ,zweilight-grey))))
;;;;; compilation
   `(compilation-column-face ((t (:foreground ,zweilight-cyan))))
   `(compilation-enter-directory-face ((t (:foreground ,zweilight-fg-1))))
   `(compilation-error-face ((t (:foreground ,zweilight-red-pastel+3 :weight bold :underline t))))
   `(compilation-face ((t (:foreground ,zweilight-fg))))
   `(compilation-info-face ((t (:foreground ,zweilight-cyan-1))))
   `(compilation-info ((t (:foreground ,zweilight-yellow :underline t))))
   `(compilation-leave-directory-face ((t (:foreground ,zweilight-fg-1))))
   `(compilation-line-face ((t (:foreground ,zweilight-cyan))))
   `(compilation-line-number ((t (:foreground ,zweilight-cyan))))
   `(compilation-message-face ((t (:foreground ,zweilight-cyan-1))))
   `(compilation-warning-face ((t (:foreground ,zweilight-fg :weight bold :underline t))))
   `(compilation-mode-line-exit ((t (:foreground ,zweilight-fg-1 :weight bold))))
   `(compilation-mode-line-fail ((t (:foreground ,zweilight-pink :weight bold))))
   `(compilation-mode-line-run ((t (:foreground ,zweilight-cyan :weight bold))))
;;;;; completions
   `(completions-annotations ((t (:foreground ,zweilight-grey+1))))
;;;;; grep
   `(grep-context-face ((t (:foreground ,zweilight-fg))))
   `(grep-error-face ((t (:foreground ,zweilight-red-pastel+3 :weight bold :underline t))))
   `(grep-hit-face ((t (:foreground ,zweilight-cyan-1))))
   `(grep-match-face ((t (:foreground ,zweilight-fg :weight bold))))
   `(match ((t (:background ,zweilight-blue :foreground ,zweilight-fg :weight bold))))
;;;;; isearch
   `(isearch ((t (:foreground ,zweilight-yellow :weight bold :background ,zweilight-fg))))
   `(isearch-fail ((t (:foreground ,zweilight-fg :background ,zweilight-red-pastel))))
   `(lazy-highlight ((t (:foreground ,zweilight-yellow :weight bold :background ,zweilight-bg+3))))

   `(menu ((t (:foreground ,zweilight-fg :background ,zweilight-bg))))
   `(minibuffer-prompt ((t (:foreground ,zweilight-cyan))))
   `(mode-line
     ((,class (:foreground ,zweilight-bg
               :background ,zweilight-blue))
      (t :inverse-video t)))
   `(mode-line-buffer-id ((t (:foreground ,zweilight-cyan :weight bold))))
   `(mode-line-inactive
     ((t (:foreground ,zweilight-fg-1
          :background ,zweilight-bg+3))))
   `(region ((,class (:background ,zweilight-yellow+1))
             (t :inverse-video t)))
   `(secondary-selection ((t (:background ,zweilight-fg))))
   `(trailing-whitespace ((t (:background ,zweilight-pink))))
   `(vertical-border ((t (:foreground ,zweilight-fg))))
;;;;; font lock
   `(font-lock-builtin-face ((t (:foreground ,zweilight-cyan))))
   `(font-lock-comment-face ((t (:foreground ,zweilight-fg-1 :slant italic))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,zweilight-fg-1))))
   `(font-lock-constant-face ((t (:foreground ,zweilight-yellow))))
   `(font-lock-doc-face ((t (:foreground ,zweilight-fg-1 :slant italic))))
   `(font-lock-function-name-face ((t (:foreground ,zweilight-orange))))
   `(font-lock-keyword-face ((t (:foreground ,zweilight-cyan ))))
   `(font-lock-negation-char-face ((t (:foreground ,zweilight-cyan))))
   `(font-lock-preprocessor-face ((t (:foreground ,zweilight-orange))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,zweilight-cyan :weight bold))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,zweilight-fg-1 :weight bold))))
   `(font-lock-string-face ((t (:foreground ,zweilight-pink))))
   `(font-lock-type-face ((t (:foreground ,zweilight-blue))))
   `(font-lock-variable-name-face ((t (:foreground ,zweilight-fg))))
   `(font-lock-warning-face ((t (:foreground ,zweilight-yellow :weight bold))))

   `(c-annotation-face ((t (:inherit font-lock-constant-face))))
;;;;; newsticker
   `(newsticker-date-face ((t (:foreground ,zweilight-fg))))
   `(newsticker-default-face ((t (:foreground ,zweilight-fg))))
   `(newsticker-enclosure-face ((t (:foreground ,zweilight-green))))
   `(newsticker-extra-face ((t (:foreground ,zweilight-fg :height 0.8))))
   `(newsticker-feed-face ((t (:foreground ,zweilight-fg))))
   `(newsticker-immortal-item-face ((t (:foreground ,zweilight-fg-1))))
   `(newsticker-new-item-face ((t (:foreground ,zweilight-cyan-1))))
   `(newsticker-obsolete-item-face ((t (:foreground ,zweilight-pink))))
   `(newsticker-old-item-face ((t (:foreground ,zweilight-blue))))
   `(newsticker-statistics-face ((t (:foreground ,zweilight-fg))))
   `(newsticker-treeview-face ((t (:foreground ,zweilight-fg))))
   `(newsticker-treeview-immortal-face ((t (:foreground ,zweilight-fg-1))))
   `(newsticker-treeview-listwindow-face ((t (:foreground ,zweilight-fg))))
   `(newsticker-treeview-new-face ((t (:foreground ,zweilight-cyan-1 :weight bold))))
   `(newsticker-treeview-obsolete-face ((t (:foreground ,zweilight-pink))))
   `(newsticker-treeview-old-face ((t (:foreground ,zweilight-blue))))
   `(newsticker-treeview-selection-face ((t (:background ,zweilight-blue :foreground ,zweilight-cyan))))
;;;; Third-party
;;;;; ace-jump
   `(ace-jump-face-background
     ((t (:foreground ,zweilight-grey+1 :background ,zweilight-bg :inverse-video nil))))
   `(ace-jump-face-foreground
     ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg :inverse-video nil))))
;;;;; ace-window
   `(aw-background-face
     ((t (:foreground ,zweilight-grey+1 :background ,zweilight-bg :inverse-video nil))))
   `(aw-leading-char-face ((t (:inherit aw-mode-line-face))))
;;;;; android mode
   `(android-mode-debug-face ((t (:foreground ,zweilight-bg))))
   `(android-mode-error-face ((t (:foreground ,zweilight-fg :weight bold))))
   `(android-mode-info-face ((t (:foreground ,zweilight-fg))))
   `(android-mode-verbose-face ((t (:foreground ,zweilight-fg-1))))
   `(android-mode-warning-face ((t (:foreground ,zweilight-cyan))))
;;;;; anzu
   `(anzu-mode-line ((t (:foreground ,zweilight-orange :weight bold))))
   `(anzu-match-1 ((t (:foreground ,zweilight-bg :background ,zweilight-fg-1))))
   `(anzu-match-2 ((t (:foreground ,zweilight-bg :background ,zweilight-fg))))
   `(anzu-match-3 ((t (:foreground ,zweilight-bg :background ,zweilight-cyan-1))))
   `(anzu-replace-to ((t (:inherit anzu-replace-highlight :foreground ,zweilight-cyan))))
;;;;; auctex
   `(font-latex-bold-face ((t (:inherit bold))))
   `(font-latex-warning-face ((t (:foreground nil :inherit font-lock-warning-face))))
   `(font-latex-sectioning-5-face ((t (:foreground ,zweilight-pink :weight bold ))))
   `(font-latex-sedate-face ((t (:foreground ,zweilight-cyan))))
   `(font-latex-italic-face ((t (:foreground ,zweilight-orange :slant italic))))
   `(font-latex-string-face ((t (:inherit ,font-lock-string-face))))
   `(font-latex-math-face ((t (:foreground ,zweilight-fg))))
;;;;; agda-mode
   `(agda2-highlight-keyword-face ((t (:foreground ,zweilight-cyan :weight bold))))
   `(agda2-highlight-string-face ((t (:foreground ,zweilight-pink))))
   `(agda2-highlight-symbol-face ((t (:foreground ,zweilight-fg))))
   `(agda2-highlight-primitive-type-face ((t (:foreground ,zweilight-blue))))
   `(agda2-highlight-inductive-constructor-face ((t (:foreground ,zweilight-fg))))
   `(agda2-highlight-coinductive-constructor-face ((t (:foreground ,zweilight-fg))))
   `(agda2-highlight-datatype-face ((t (:foreground ,zweilight-cyan-1))))
   `(agda2-highlight-function-face ((t (:foreground ,zweilight-cyan-1))))
   `(agda2-highlight-module-face ((t (:foreground ,zweilight-blue))))
   `(agda2-highlight-error-face ((t (:foreground ,zweilight-bg :background ,zweilight-pink+1))))
   `(agda2-highlight-unsolved-meta-face ((t (:foreground ,zweilight-bg :background ,zweilight-pink+1))))
   `(agda2-highlight-unsolved-constraint-face ((t (:foreground ,zweilight-bg :background ,zweilight-pink+1))))
   `(agda2-highlight-termination-problem-face ((t (:foreground ,zweilight-bg :background ,zweilight-pink+1))))
   `(agda2-highlight-incomplete-pattern-face ((t (:foreground ,zweilight-bg :background ,zweilight-pink+1))))
   `(agda2-highlight-typechecks-face ((t (:background ,zweilight-red-pastel))))
;;;;; auto-complete
   `(ac-candidate-face ((t (:background ,zweilight-blue :foreground ,zweilight-bg))))
   `(ac-selection-face ((t (:background ,zweilight-yellow :foreground ,zweilight-bg))))
   `(popup-tip-face ((t (:background ,zweilight-yellow :foreground ,zweilight-bg))))
   `(popup-scroll-bar-foreground-face ((t (:background ,zweilight-bg))))
   `(popup-scroll-bar-background-face ((t (:background ,zweilight-bg+3))))
   `(popup-isearch-match ((t (:background ,zweilight-bg :foreground ,zweilight-fg))))
;;;;; avy
   `(avy-background-face
     ((t (:foreground ,zweilight-grey+1 :background ,zweilight-bg :inverse-video nil))))
   `(avy-lead-face-0
     ((t (:foreground ,zweilight-green :background ,zweilight-bg :inverse-video nil :weight bold))))
   `(avy-lead-face-1
     ((t (:foreground ,zweilight-cyan :background ,zweilight-bg :inverse-video nil :weight bold))))
   `(avy-lead-face-2
     ((t (:foreground ,zweilight-red-pastel+4 :background ,zweilight-bg :inverse-video nil :weight bold))))
   `(avy-lead-face
     ((t (:foreground ,zweilight-orange :background ,zweilight-bg :inverse-video nil :weight bold))))
;;;;; company-mode
   `(company-tooltip ((t (:foreground ,zweilight-fg :background ,zweilight-bg+3))))
   `(company-tooltip-annotation ((t (:foreground ,zweilight-fg :background ,zweilight-grey))))
   `(company-tooltip-annotation-selection ((t (:foreground ,zweilight-fg :background ,zweilight-blue))))
   `(company-tooltip-selection ((t (:foreground ,zweilight-bg :background ,zweilight-blue))))
   `(company-tooltip-mouse ((t (:foreground ,zweilight-bg :background ,zweilight-blue))))
   `(company-tooltip-common ((t (:foreground ,zweilight-cyan :weight bold))))
   `(company-tooltip-common-selection ((t (:foreground ,zweilight-cyan :weight bold))))
   `(company-scrollbar-fg ((t (:background ,zweilight-blue))))
   `(company-scrollbar-bg ((t (:background ,zweilight-grey-1))))
   `(company-preview ((t (:background ,zweilight-fg-1))))
   `(company-preview-common ((t (:foreground ,zweilight-fg-1 :background ,zweilight-blue))))
;;;;; bm
   `(bm-face ((t (:background ,zweilight-yellow+1 :foreground ,zweilight-bg))))
   `(bm-fringe-face ((t (:background ,zweilight-yellow+1 :foreground ,zweilight-bg))))
   `(bm-fringe-persistent-face ((t (:background ,zweilight-fg-1 :foreground ,zweilight-bg))))
   `(bm-persistent-face ((t (:background ,zweilight-fg-1 :foreground ,zweilight-bg))))
;;;;; cider
   `(cider-result-overlay-face ((t (:foreground ,zweilight-grey+1 :background unspecified))))
   `(cider-enlightened-face ((t (:box (:color ,zweilight-fg :line-width -1)))))
   `(cider-enlightened-local-face ((t (:weight bold :foreground ,zweilight-bg))))
   `(cider-deprecated-face ((t (:background ,zweilight-yellow))))
   `(cider-instrumented-face ((t (:box (:color ,zweilight-pink :line-width -1)))))
   `(cider-traced-face ((t (:box (:color ,zweilight-orange :line-width -1)))))
   `(cider-test-failure-face ((t (:background ,zweilight-red-pastel))))
   `(cider-test-error-face ((t (:background ,zweilight-pink+1))))
   `(cider-test-success-face ((t (:background ,zweilight-fg-1))))
;;;;; circe
   `(circe-highlight-nick-face ((t (:foreground ,zweilight-orange))))
   `(circe-my-message-face ((t (:foreground ,zweilight-fg))))
   `(circe-fool-face ((t (:foreground ,zweilight-red-pastel+4))))
   `(circe-topic-diff-removed-face ((t (:foreground ,zweilight-pink :weight bold))))
   `(circe-originator-face ((t (:foreground ,zweilight-fg))))
   `(circe-server-face ((t (:foreground ,zweilight-fg-1))))
   `(circe-topic-diff-new-face ((t (:foreground ,zweilight-fg :weight bold))))
   `(circe-prompt-face ((t (:foreground ,zweilight-fg :background ,zweilight-bg :weight bold))))
;;;;; context-coloring
   `(context-coloring-level-0-face ((t :foreground ,zweilight-fg)))
   `(context-coloring-level-1-face ((t :foreground ,zweilight-orange)))
   `(context-coloring-level-2-face ((t :foreground ,zweilight-yellow)))
   `(context-coloring-level-3-face ((t :foreground ,zweilight-cyan)))
   `(context-coloring-level-4-face ((t :foreground ,zweilight-fg)))
   `(context-coloring-level-5-face ((t :foreground ,zweilight-pink+1)))
   `(context-coloring-level-6-face ((t :foreground ,zweilight-orange)))
   `(context-coloring-level-7-face ((t :foreground ,zweilight-fg-1)))
   `(context-coloring-level-8-face ((t :foreground ,zweilight-yellow)))
   `(context-coloring-level-9-face ((t :foreground ,zweilight-red-pastel+4)))
;;;;; coq
   `(coq-solve-tactics-face ((t (:foreground nil :inherit font-lock-constant-face))))
;;;;; ctable
   `(ctbl:face-cell-select ((t (:background ,zweilight-cyan-1 :foreground ,zweilight-bg))))
   `(ctbl:face-continue-bar ((t (:background ,zweilight-bg+3 :foreground ,zweilight-bg))))
   `(ctbl:face-row-select ((t (:background ,zweilight-orange :foreground ,zweilight-bg))))
;;;;; diff
   `(diff-added          ((t (:background "#335533" :foreground ,zweilight-fg-1))))
   `(diff-changed        ((t (:background "#555511" :foreground ,zweilight-yellow+1))))
   `(diff-removed        ((t (:background "#553333" :foreground ,zweilight-red-pastel+2))))
   `(diff-refine-added   ((t (:background "#338833" :foreground ,zweilight-yellow))))
   `(diff-refine-change  ((t (:background "#888811" :foreground ,zweilight-cyan))))
   `(diff-refine-removed ((t (:background "#883333" :foreground ,zweilight-pink))))
   `(diff-header ((,class (:background ,zweilight-fg))
                  (t (:background ,zweilight-fg :foreground ,zweilight-bg))))
   `(diff-file-header
     ((,class (:background ,zweilight-fg :foreground ,zweilight-fg :bold t))
      (t (:background ,zweilight-fg :foreground ,zweilight-bg :bold t))))
;;;;; diff-hl
   `(diff-hl-change ((,class (:foreground ,zweilight-cyan-1 :background ,zweilight-cyan-2))))
   `(diff-hl-delete ((,class (:foreground ,zweilight-red-pastel+4 :background ,zweilight-red-pastel+3))))
   `(diff-hl-insert ((,class (:foreground ,zweilight-bg :background ,zweilight-fg-1))))
;;;;; dim-autoload
   `(dim-autoload-cookie-line ((t :foreground ,zweilight-grey)))
;;;;; dired+
   `(diredp-display-msg ((t (:foreground ,zweilight-cyan-1))))
   `(diredp-compressed-file-suffix ((t (:foreground ,zweilight-fg))))
   `(diredp-date-time ((t (:foreground ,zweilight-pink+1))))
   `(diredp-deletion ((t (:foreground ,zweilight-cyan))))
   `(diredp-deletion-file-name ((t (:foreground ,zweilight-pink))))
   `(diredp-dir-heading ((t (:foreground ,zweilight-cyan-1 :background ,zweilight-blue))))
   `(diredp-dir-priv ((t (:foreground ,zweilight-orange))))
   `(diredp-exec-priv ((t (:foreground ,zweilight-pink))))
   `(diredp-executable-tag ((t (:foreground ,zweilight-bg))))
   `(diredp-file-name ((t (:foreground ,zweilight-cyan-1))))
   `(diredp-file-suffix ((t (:foreground ,zweilight-fg-1))))
   `(diredp-flag-mark ((t (:foreground ,zweilight-cyan))))
   `(diredp-flag-mark-line ((t (:foreground ,zweilight-fg))))
   `(diredp-ignored-file-name ((t (:foreground ,zweilight-pink))))
   `(diredp-link-priv ((t (:foreground ,zweilight-cyan))))
   `(diredp-mode-line-flagged ((t (:foreground ,zweilight-cyan))))
   `(diredp-mode-line-marked ((t (:foreground ,zweilight-fg))))
   `(diredp-no-priv ((t (:foreground ,zweilight-fg))))
   `(diredp-number ((t (:foreground ,zweilight-bg))))
   `(diredp-other-priv ((t (:foreground ,zweilight-yellow+1))))
   `(diredp-rare-priv ((t (:foreground ,zweilight-red-pastel+3))))
   `(diredp-read-priv ((t (:foreground ,zweilight-fg-1))))
   `(diredp-symlink ((t (:foreground ,zweilight-cyan))))
   `(diredp-write-priv ((t (:foreground ,zweilight-pink+1))))
;;;;; dired-async
   `(dired-async-failures ((t (:foreground ,zweilight-pink :weight bold))))
   `(dired-async-message ((t (:foreground ,zweilight-cyan :weight bold))))
   `(dired-async-mode-message ((t (:foreground ,zweilight-cyan))))
;;;;; ediff
   `(ediff-current-diff-A ((t (:foreground ,zweilight-fg :background ,zweilight-red-pastel))))
   `(ediff-current-diff-Ancestor ((t (:foreground ,zweilight-fg :background ,zweilight-red-pastel))))
   `(ediff-current-diff-B ((t (:foreground ,zweilight-fg :background ,zweilight-fg-1))))
   `(ediff-current-diff-C ((t (:foreground ,zweilight-fg :background ,zweilight-bg))))
   `(ediff-even-diff-A ((t (:background ,zweilight-grey))))
   `(ediff-even-diff-Ancestor ((t (:background ,zweilight-grey))))
   `(ediff-even-diff-B ((t (:background ,zweilight-grey))))
   `(ediff-even-diff-C ((t (:background ,zweilight-grey))))
   `(ediff-fine-diff-A ((t (:foreground ,zweilight-fg :background ,zweilight-red-pastel+2 :weight bold))))
   `(ediff-fine-diff-Ancestor ((t (:foreground ,zweilight-fg :background ,zweilight-red-pastel+2 weight bold))))
   `(ediff-fine-diff-B ((t (:foreground ,zweilight-fg :background ,zweilight-fg-1 :weight bold))))
   `(ediff-fine-diff-C ((t (:foreground ,zweilight-fg :background ,zweilight-cyan-3 :weight bold ))))
   `(ediff-odd-diff-A ((t (:background ,zweilight-fg))))
   `(ediff-odd-diff-Ancestor ((t (:background ,zweilight-fg))))
   `(ediff-odd-diff-B ((t (:background ,zweilight-fg))))
   `(ediff-odd-diff-C ((t (:background ,zweilight-fg))))
;;;;; egg
   `(egg-text-base ((t (:foreground ,zweilight-fg))))
   `(egg-help-header-1 ((t (:foreground ,zweilight-cyan))))
   `(egg-help-header-2 ((t (:foreground ,zweilight-green))))
   `(egg-branch ((t (:foreground ,zweilight-cyan))))
   `(egg-branch-mono ((t (:foreground ,zweilight-cyan))))
   `(egg-term ((t (:foreground ,zweilight-cyan))))
   `(egg-diff-add ((t (:foreground ,zweilight-yellow))))
   `(egg-diff-del ((t (:foreground ,zweilight-red-pastel+4))))
   `(egg-diff-file-header ((t (:foreground ,zweilight-yellow))))
   `(egg-section-title ((t (:foreground ,zweilight-cyan))))
   `(egg-stash-mono ((t (:foreground ,zweilight-yellow))))
;;;;; elfeed
   `(elfeed-log-error-level-face ((t (:foreground ,zweilight-pink))))
   `(elfeed-log-info-level-face ((t (:foreground ,zweilight-cyan-1))))
   `(elfeed-log-warn-level-face ((t (:foreground ,zweilight-cyan))))
   `(elfeed-search-date-face ((t (:foreground ,zweilight-yellow+1 :underline t
                                              :weight bold))))
   `(elfeed-search-tag-face ((t (:foreground ,zweilight-fg-1))))
   `(elfeed-search-feed-face ((t (:foreground ,zweilight-orange))))
;;;;; emacs-w3m
   `(w3m-anchor ((t (:foreground ,zweilight-cyan :underline t
                                 :weight bold))))
   `(w3m-arrived-anchor ((t (:foreground ,zweilight-yellow
                                         :underline t :weight normal))))
   `(w3m-form ((t (:foreground ,zweilight-red-pastel+3 :underline t))))
   `(w3m-header-line-location-title ((t (:foreground ,zweilight-cyan
                                                     :underline t :weight bold))))
   '(w3m-history-current-url ((t (:inherit match))))
   `(w3m-lnum ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg))))
   `(w3m-lnum-match ((t (:background ,zweilight-blue
                                     :foreground ,zweilight-fg
                                     :weight bold))))
   `(w3m-lnum-minibuffer-prompt ((t (:foreground ,zweilight-cyan))))
;;;;; erc
   `(erc-action-face ((t (:inherit erc-default-face))))
   `(erc-bold-face ((t (:weight bold))))
   `(erc-current-nick-face ((t (:foreground ,zweilight-cyan-1 :weight bold))))
   `(erc-dangerous-host-face ((t (:inherit font-lock-warning-face))))
   `(erc-default-face ((t (:foreground ,zweilight-fg))))
   `(erc-direct-msg-face ((t (:inherit erc-default-face))))
   `(erc-error-face ((t (:inherit font-lock-warning-face))))
   `(erc-fool-face ((t (:inherit erc-default-face))))
   `(erc-highlight-face ((t (:inherit hover-highlight))))
   `(erc-input-face ((t (:foreground ,zweilight-cyan))))
   `(erc-keyword-face ((t (:foreground ,zweilight-cyan-1 :weight bold))))
   `(erc-nick-default-face ((t (:foreground ,zweilight-cyan :weight bold))))
   `(erc-my-nick-face ((t (:foreground ,zweilight-pink :weight bold))))
   `(erc-nick-msg-face ((t (:inherit erc-default-face))))
   `(erc-notice-face ((t (:foreground ,zweilight-fg-1))))
   `(erc-pal-face ((t (:foreground ,zweilight-fg :weight bold))))
   `(erc-prompt-face ((t (:foreground ,zweilight-fg :background ,zweilight-bg :weight bold))))
   `(erc-timestamp-face ((t (:foreground ,zweilight-yellow))))
   `(erc-underline-face ((t (:underline t))))
;;;;; ert
   `(ert-test-result-expected ((t (:foreground ,zweilight-yellow :background ,zweilight-bg))))
   `(ert-test-result-unexpected ((t (:foreground ,zweilight-pink :background ,zweilight-bg))))
;;;;; eshell
   `(eshell-prompt ((t (:foreground ,zweilight-cyan :weight bold))))
   `(eshell-ls-archive ((t (:foreground ,zweilight-red-pastel+3 :weight bold))))
   `(eshell-ls-backup ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-clutter ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-directory ((t (:foreground ,zweilight-orange :weight bold))))
   `(eshell-ls-executable ((t (:foreground ,zweilight-red-pastel+4 :weight bold))))
   `(eshell-ls-unreadable ((t (:foreground ,zweilight-fg))))
   `(eshell-ls-missing ((t (:inherit font-lock-warning-face))))
   `(eshell-ls-product ((t (:inherit font-lock-doc-face))))
   `(eshell-ls-special ((t (:foreground ,zweilight-cyan :weight bold))))
   `(eshell-ls-symlink ((t (:foreground ,zweilight-orange :weight bold))))
;;;;; flx
   `(flx-highlight-face ((t (:foreground ,zweilight-fg-1 :weight bold))))
;;;;; flycheck
   `(flycheck-error
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-red-pastel+3) :inherit unspecified))
      (t (:foreground ,zweilight-red-pastel+3 :weight bold :underline t))))
   `(flycheck-warning
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-cyan) :inherit unspecified))
      (t (:foreground ,zweilight-cyan :weight bold :underline t))))
   `(flycheck-info
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-orange) :inherit unspecified))
      (t (:foreground ,zweilight-orange :weight bold :underline t))))
   `(flycheck-fringe-error ((t (:foreground ,zweilight-red-pastel+3 :weight bold))))
   `(flycheck-fringe-warning ((t (:foreground ,zweilight-cyan :weight bold))))
   `(flycheck-fringe-info ((t (:foreground ,zweilight-orange :weight bold))))
;;;;; flymake
   `(flymake-errline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-pink)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,zweilight-red-pastel+3 :weight bold :underline t))))
   `(flymake-warnline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-fg)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,zweilight-fg :weight bold :underline t))))
   `(flymake-infoline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-fg-1)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,zweilight-fg-1 :weight bold :underline t))))
;;;;; flyspell
   `(flyspell-duplicate
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-fg) :inherit unspecified))
      (t (:foreground ,zweilight-fg :weight bold :underline t))))
   `(flyspell-incorrect
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-pink) :inherit unspecified))
      (t (:foreground ,zweilight-red-pastel+3 :weight bold :underline t))))
;;;;; full-ack
   `(ack-separator ((t (:foreground ,zweilight-fg))))
   `(ack-file ((t (:foreground ,zweilight-cyan-1))))
   `(ack-line ((t (:foreground ,zweilight-cyan))))
   `(ack-match ((t (:foreground ,zweilight-fg :background ,zweilight-blue :weight bold))))
;;;;; git-commit
   `(git-commit-comment-action  ((,class (:foreground ,zweilight-bg :weight bold))))
   `(git-commit-comment-branch  ((,class (:foreground ,zweilight-orange  :weight bold))))
   `(git-commit-comment-heading ((,class (:foreground ,zweilight-cyan  :weight bold))))
;;;;; git-gutter
   `(git-gutter:added ((t (:foreground ,zweilight-fg-1 :weight bold :inverse-video t))))
   `(git-gutter:deleted ((t (:foreground ,zweilight-pink :weight bold :inverse-video t))))
   `(git-gutter:modified ((t (:foreground ,zweilight-pink+1 :weight bold :inverse-video t))))
   `(git-gutter:unchanged ((t (:foreground ,zweilight-fg :weight bold :inverse-video t))))
;;;;; git-gutter-fr
   `(git-gutter-fr:added ((t (:foreground ,zweilight-fg-1  :weight bold))))
   `(git-gutter-fr:deleted ((t (:foreground ,zweilight-pink :weight bold))))
   `(git-gutter-fr:modified ((t (:foreground ,zweilight-pink+1 :weight bold))))
;;;;; git-rebase
   `(git-rebase-hash ((t (:foreground, zweilight-fg))))
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
   `(gnus-server-opened ((t (:foreground ,zweilight-fg-1 :weight bold))))
   `(gnus-server-denied ((t (:foreground ,zweilight-red-pastel+4 :weight bold))))
   `(gnus-server-closed ((t (:foreground ,zweilight-cyan-1 :slant italic))))
   `(gnus-server-offline ((t (:foreground ,zweilight-cyan :weight bold))))
   `(gnus-server-agent ((t (:foreground ,zweilight-cyan-1 :weight bold))))
   `(gnus-summary-cancelled ((t (:foreground ,zweilight-fg))))
   `(gnus-summary-high-ancient ((t (:foreground ,zweilight-cyan-1))))
   `(gnus-summary-high-read ((t (:foreground ,zweilight-fg-1 :weight bold))))
   `(gnus-summary-high-ticked ((t (:foreground ,zweilight-fg :weight bold))))
   `(gnus-summary-high-unread ((t (:foreground ,zweilight-fg :weight bold))))
   `(gnus-summary-low-ancient ((t (:foreground ,zweilight-cyan-1))))
   `(gnus-summary-low-read ((t (:foreground ,zweilight-fg-1))))
   `(gnus-summary-low-ticked ((t (:foreground ,zweilight-fg :weight bold))))
   `(gnus-summary-low-unread ((t (:foreground ,zweilight-fg))))
   `(gnus-summary-normal-ancient ((t (:foreground ,zweilight-cyan-1))))
   `(gnus-summary-normal-read ((t (:foreground ,zweilight-fg-1))))
   `(gnus-summary-normal-ticked ((t (:foreground ,zweilight-fg :weight bold))))
   `(gnus-summary-normal-unread ((t (:foreground ,zweilight-fg))))
   `(gnus-summary-selected ((t (:foreground ,zweilight-cyan :weight bold))))
   `(gnus-cite-1 ((t (:foreground ,zweilight-cyan-1))))
   `(gnus-cite-10 ((t (:foreground ,zweilight-yellow+1))))
   `(gnus-cite-11 ((t (:foreground ,zweilight-cyan))))
   `(gnus-cite-2 ((t (:foreground ,zweilight-blue))))
   `(gnus-cite-3 ((t (:foreground ,zweilight-cyan-2))))
   `(gnus-cite-4 ((t (:foreground ,zweilight-fg-1))))
   `(gnus-cite-5 ((t (:foreground ,zweilight-bg))))
   `(gnus-cite-6 ((t (:foreground ,zweilight-fg-1))))
   `(gnus-cite-7 ((t (:foreground ,zweilight-pink))))
   `(gnus-cite-8 ((t (:foreground ,zweilight-red-pastel+3))))
   `(gnus-cite-9 ((t (:foreground ,zweilight-red-pastel+2))))
   `(gnus-group-news-1-empty ((t (:foreground ,zweilight-cyan))))
   `(gnus-group-news-2-empty ((t (:foreground ,zweilight-green))))
   `(gnus-group-news-3-empty ((t (:foreground ,zweilight-bg))))
   `(gnus-group-news-4-empty ((t (:foreground ,zweilight-cyan-2))))
   `(gnus-group-news-5-empty ((t (:foreground ,zweilight-cyan-3))))
   `(gnus-group-news-6-empty ((t (:foreground ,zweilight-fg))))
   `(gnus-group-news-low-empty ((t (:foreground ,zweilight-fg))))
   `(gnus-signature ((t (:foreground ,zweilight-cyan))))
   `(gnus-x ((t (:background ,zweilight-fg :foreground ,zweilight-bg))))
;;;;; guide-key
   `(guide-key/highlight-command-face ((t (:foreground ,zweilight-cyan-1))))
   `(guide-key/key-face ((t (:foreground ,zweilight-fg-1))))
   `(guide-key/prefix-command-face ((t (:foreground ,zweilight-bg))))
;;;;; helm
   `(helm-header
     ((t (:foreground ,zweilight-fg-1
          :background ,zweilight-bg
          :underline nil
          :box nil))))
   `(helm-source-header
     ((t (:foreground ,zweilight-cyan
          :underline nil
          :weight bold
          :box nil))))
   `(helm-selection ((t (:background ,zweilight-grey :underline nil))))
   `(helm-selection-line ((t (:background ,zweilight-grey))))
   `(helm-visible-mark ((t (:foreground ,zweilight-bg :background ,zweilight-yellow))))
   `(helm-candidate-number ((t (:foreground nil :background nil))))
   `(helm-separator ((t (:foreground ,zweilight-pink :background ,zweilight-bg))))
   `(helm-time-zone-current ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg))))
   `(helm-time-zone-home ((t (:foreground ,zweilight-pink :background ,zweilight-bg))))
   `(helm-bookmark-addressbook ((t (:foreground ,zweilight-fg :background ,zweilight-bg))))
   `(helm-bookmark-directory ((t (:foreground nil :background nil :inherit helm-ff-directory))))
   `(helm-bookmark-file ((t (:foreground nil :background nil :inherit helm-ff-file))))
   `(helm-bookmark-gnus ((t (:foreground ,zweilight-pink+1 :background ,zweilight-bg))))
   `(helm-bookmark-info ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg))))
   `(helm-bookmark-man ((t (:foreground ,zweilight-cyan :background ,zweilight-bg))))
   `(helm-bookmark-w3m ((t (:foreground ,zweilight-pink+1 :background ,zweilight-bg))))
   `(helm-buffer-not-saved ((t (:foreground ,zweilight-pink :background ,zweilight-bg))))
   `(helm-buffer-process ((t (:foreground ,zweilight-orange :background ,zweilight-bg))))
   `(helm-buffer-saved-out ((t (:foreground ,zweilight-fg :background ,zweilight-bg))))
   `(helm-buffer-size ((t (:foreground ,zweilight-grey+1 :background ,zweilight-bg))))
   `(helm-ff-directory ((t (:foreground ,zweilight-cyan :background ,zweilight-bg))))
   `(helm-ff-file ((t (:foreground ,zweilight-fg :background ,zweilight-bg :weight normal))))
   `(helm-ff-dotted-directory ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg :weight normal))))
   `(helm-ff-executable ((t (:foreground ,zweilight-green :background ,zweilight-bg :weight normal))))
   `(helm-ff-invalid-symlink ((t (:foreground ,zweilight-orange :background ,zweilight-bg :slant italic))))
   `(helm-ff-symlink ((t (:foreground ,zweilight-fg :background ,zweilight-bg :slant italic))))
   `(helm-ff-prefix ((t (:foreground ,zweilight-bg :background ,zweilight-cyan :weight normal))))
   `(helm-grep-cmd-line ((t (:foreground ,zweilight-orange :background ,zweilight-bg))))
   `(helm-grep-file ((t (:foreground ,zweilight-fg :background ,zweilight-bg))))
   `(helm-grep-finish ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg))))
   `(helm-grep-lineno ((t (:foreground ,zweilight-grey+1 :background ,zweilight-bg))))
   `(helm-grep-match ((t (:foreground nil :background nil :inherit helm-match))))
   `(helm-grep-running ((t (:foreground ,zweilight-pink :background ,zweilight-bg))))
   `(helm-match ((t (:foreground ,zweilight-cyan :weight bold))))
   `(helm-moccur-buffer ((t (:foreground ,zweilight-orange :background ,zweilight-bg))))
   `(helm-mu-contacts-address-face ((t (:foreground ,zweilight-grey+1 :background ,zweilight-bg))))
   `(helm-mu-contacts-name-face ((t (:foreground ,zweilight-fg :background ,zweilight-bg))))
;;;;; helm-swoop
   `(helm-swoop-target-line-face ((t (:foreground ,zweilight-fg :background ,zweilight-grey))))
   `(helm-swoop-target-word-face ((t (:foreground ,zweilight-cyan :background ,zweilight-fg :weight bold))))
;;;;; highlight-numbers
   `(highlight-numbers-number ((t (:foreground ,zweilight-yellow))))
;;;;; hl-line-mode
   `(hl-line-face ((,class (:background ,zweilight-bg+3))
                   (t :weight bold)))
   `(hl-line ((,class (:background ,zweilight-bg+3)) ; old emacsen
              (t :weight bold)))
;;;;; hl-sexp
   `(hl-sexp-face ((,class (:background ,zweilight-grey))
                   (t :weight bold)))
;;;;; hlinum
   `(linum-highlight-face ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg+3))))
;;;;; hydra
   `(hydra-face-red ((t (:foreground ,zweilight-red-pastel+3 :background ,zweilight-bg))))
   `(hydra-face-amaranth ((t (:foreground ,zweilight-red-pastel+1 :background ,zweilight-bg))))
   `(hydra-face-blue ((t (:foreground ,zweilight-cyan-1 :background ,zweilight-bg))))
   `(hydra-face-pink ((t (:foreground ,zweilight-pink+1 :background ,zweilight-bg))))
   `(hydra-face-teal ((t (:foreground ,zweilight-orange :background ,zweilight-bg))))
;;;; ivy
   `(ivy-confirm-face ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg))))
   `(ivy-match-required-face ((t (:foreground ,zweilight-pink :background ,zweilight-bg))))
   `(ivy-remote ((t (:foreground ,zweilight-cyan-1 :background ,zweilight-bg))))
   `(ivy-subdir ((t (:foreground ,zweilight-cyan :background ,zweilight-bg))))
   `(ivy-current-match ((t (:foreground ,zweilight-cyan :weight bold :underline t))))
   `(ivy-minibuffer-match-face-1 ((t (:background ,zweilight-grey))))
   `(ivy-minibuffer-match-face-2 ((t (:background ,zweilight-fg-1))))
   `(ivy-minibuffer-match-face-3 ((t (:background ,zweilight-fg-1))))
   `(ivy-minibuffer-match-face-4 ((t (:background ,zweilight-bg))))
;;;;; ido-mode
   `(ido-first-match ((t (:foreground ,zweilight-cyan :weight bold))))
   `(ido-only-match ((t (:foreground ,zweilight-fg :weight bold))))
   `(ido-subdir ((t (:foreground ,zweilight-cyan))))
   `(ido-indicator ((t (:foreground ,zweilight-cyan :background ,zweilight-red-pastel))))
;;;;; iedit-mode
   `(iedit-occurrence ((t (:background ,zweilight-fg :weight bold))))
;;;;; jabber-mode
   `(jabber-roster-user-away ((t (:foreground ,zweilight-fg-1))))
   `(jabber-roster-user-online ((t (:foreground ,zweilight-blue))))
   `(jabber-roster-user-dnd ((t (:foreground ,zweilight-red-pastel+4))))
   `(jabber-roster-user-xa ((t (:foreground ,zweilight-pink+1))))
   `(jabber-roster-user-chatty ((t (:foreground ,zweilight-fg))))
   `(jabber-roster-user-error ((t (:foreground ,zweilight-red-pastel+4))))
   `(jabber-rare-time-face ((t (:foreground ,zweilight-bg))))
   `(jabber-chat-prompt-local ((t (:foreground ,zweilight-blue))))
   `(jabber-chat-prompt-foreign ((t (:foreground ,zweilight-red-pastel+4))))
   `(jabber-chat-prompt-system ((t (:foreground ,zweilight-green))))
   `(jabber-activity-face((t (:foreground ,zweilight-red-pastel+4))))
   `(jabber-activity-personal-face ((t (:foreground ,zweilight-orange))))
   `(jabber-title-small ((t (:height 1.1 :weight bold))))
   `(jabber-title-medium ((t (:height 1.2 :weight bold))))
   `(jabber-title-large ((t (:height 1.3 :weight bold))))
;;;;; js2-mode
   `(js2-warning ((t (:underline ,zweilight-fg))))
   `(js2-error ((t (:foreground ,zweilight-pink :weight bold))))
   `(js2-jsdoc-tag ((t (:foreground ,zweilight-fg-1))))
   `(js2-jsdoc-type ((t (:foreground ,zweilight-fg-1))))
   `(js2-jsdoc-value ((t (:foreground ,zweilight-green))))
   `(js2-function-param ((t (:foreground, zweilight-fg))))
   `(js2-external-variable ((t (:foreground ,zweilight-fg))))
;;;;; additional js2 mode attributes for better syntax highlighting
   `(js2-instance-member ((t (:foreground ,zweilight-fg-1))))
   `(js2-jsdoc-html-tag-delimiter ((t (:foreground ,zweilight-fg))))
   `(js2-jsdoc-html-tag-name ((t (:foreground ,zweilight-red-pastel+3))))
   `(js2-object-property ((t (:foreground ,zweilight-orange))))
   `(js2-magic-paren ((t (:foreground ,zweilight-bg))))
   `(js2-private-function-call ((t (:foreground ,zweilight-orange))))
   `(js2-function-call ((t (:foreground ,zweilight-orange))))
   `(js2-private-member ((t (:foreground ,zweilight-blue))))
   `(js2-keywords ((t (:foreground ,zweilight-pink+1))))
;;;;; ledger-mode
   `(ledger-font-payee-uncleared-face ((t (:foreground ,zweilight-red-pastel+3 :weight bold))))
   `(ledger-font-payee-cleared-face ((t (:foreground ,zweilight-fg :weight normal))))
   `(ledger-font-xact-highlight-face ((t (:background ,zweilight-grey))))
   `(ledger-font-pending-face ((t (:foreground ,zweilight-fg weight: normal))))
   `(ledger-font-other-face ((t (:foreground ,zweilight-fg))))
   `(ledger-font-posting-account-face ((t (:foreground ,zweilight-blue))))
   `(ledger-font-posting-account-cleared-face ((t (:foreground ,zweilight-fg))))
   `(ledger-font-posting-account-pending-face ((t (:foreground ,zweilight-fg))))
   `(ledger-font-posting-amount-face ((t (:foreground ,zweilight-fg))))
   `(ledger-occur-narrowed-face ((t (:foreground ,zweilight-grey+1 :invisible t))))
   `(ledger-occur-xact-face ((t (:background ,zweilight-grey))))
   `(ledger-font-comment-face ((t (:foreground ,zweilight-fg-1))))
   `(ledger-font-reconciler-uncleared-face ((t (:foreground ,zweilight-red-pastel+3 :weight bold))))
   `(ledger-font-reconciler-cleared-face ((t (:foreground ,zweilight-fg :weight normal))))
   `(ledger-font-reconciler-pending-face ((t (:foreground ,zweilight-fg :weight normal))))
   `(ledger-font-report-clickable-face ((t (:foreground ,zweilight-fg :weight normal))))
;;;;; linum-mode
   `(linum ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg))))
;;;;; lispy
   `(lispy-command-name-face ((t (:background ,zweilight-bg+3 :inherit font-lock-function-name-face))))
   `(lispy-cursor-face ((t (:foreground ,zweilight-bg :background ,zweilight-fg))))
   `(lispy-face-hint ((t (:inherit highlight :foreground ,zweilight-cyan))))
;;;;; ruler-mode
   `(ruler-mode-column-number ((t (:inherit 'ruler-mode-default :foreground ,zweilight-fg))))
   `(ruler-mode-fill-column ((t (:inherit 'ruler-mode-default :foreground ,zweilight-cyan))))
   `(ruler-mode-goal-column ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-comment-column ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-tab-stop ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-current-column ((t (:foreground ,zweilight-cyan :box t))))
   `(ruler-mode-default ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg))))

;;;;; lui
   `(lui-time-stamp-face ((t (:foreground ,zweilight-blue))))
   `(lui-hilight-face ((t (:foreground ,zweilight-fg-1 :background ,zweilight-bg))))
   `(lui-button-face ((t (:inherit hover-highlight))))
;;;;; macrostep
   `(macrostep-gensym-1
     ((t (:foreground ,zweilight-fg-1 :background ,zweilight-blue))))
   `(macrostep-gensym-2
     ((t (:foreground ,zweilight-red-pastel+4 :background ,zweilight-blue))))
   `(macrostep-gensym-3
     ((t (:foreground ,zweilight-orange :background ,zweilight-blue))))
   `(macrostep-gensym-4
     ((t (:foreground ,zweilight-pink+1 :background ,zweilight-blue))))
   `(macrostep-gensym-5
     ((t (:foreground ,zweilight-cyan :background ,zweilight-blue))))
   `(macrostep-expansion-highlight-face
     ((t (:inherit highlight))))
   `(macrostep-macro-face
     ((t (:underline t))))
;;;;; magit
;;;;;; headings and diffs`(magit-section-highlight           ((t (:background ,zweilight-grey-1   `(magit-section-heading             ((t (:foreground ,zweilight-cyan :weight bold))))
   `(magit-section-heading-selection   ((t (:foreground ,zweilight-fg :weight bold))))
   `(magit-diff-file-headi         ((t (:weight bold))))
   `(magit-diff-file-headiighlight ((t (:background ,zweilight-grey-1 bold))))
   `(magit-diff-file-heading-selection ((t (:background ,zweilight-grey-1                                                    :foreground ,zweilight-fg :weight bold))))
   `(magit-diff-hunk-heading           ((t (:background ,zweilight-grey))))
   `(magit-diff-hunk-heading-highlight ((t (:background ,zweilight-fg))))
   `(magit-diff-hunk-heading-selection ((t (:background ,zweilight-fg
                                                        :foreground ,zweilight-fg))))
   `(magit-diff-lines-heading          ((t (:background ,zweilight-fg
                                                    :foreground ,zweilight-fg))))
   `(magit-diff-context-highlight      ((t (:background ,zweilight-grey-1                                                    :foreground "grey70"))))
   `(magit-diffstat-added   ((t (:foreground ,zweilight-yellow))))
   `(magit-diffstat-removed ((t (:foreground ,zweilight-pink))))
;;;;;; popup
   `(magit-popup-heading             ((t (:foreground ,zweilight-cyan  :weight bold))))
   `(magit-popup-key                 ((t (:foreground ,zweilight-fg-1 :weight bold))))
   `(magit-popup-argument            ((t (:foreground ,zweilight-fg-1   :weight bold))))
   `(magit-popup-disabled-argument   ((t (:foreground ,zweilight-grey+1    :weight normal))))
   `(magit-popup-option-value        ((t (:foreground ,zweilight-cyan-2  :weight bold))))
;;;;;; process
   `(magit-process-ok    ((t (:foreground ,zweilight-fg-1  :weight bold))))
   `(magit-process-ng    ((t (:foreground ,zweilight-pink    :weight bold))))
;;;;;; log
   `(magit-log-author    ((t (:foreground ,zweilight-fg))))
   `(magit-log-date      ((t (:foreground ,zweilight-grey+1))))
   `(magit-log-graph     ((t (:foreground ,zweilight-yellow))))
;;;;;; sequence
   `(magit-sequence-pick ((t (:foreground ,zweilight-yellow))))
   `(magit-sequence-stop ((t (:foreground ,zweilight-fg-1))))
   `(magit-sequence-part ((t (:foreground ,zweilight-cyan))))
   `(magit-sequence-head ((t (:foreground ,zweilight-cyan-1))))
   `(magit-sequence-drop ((t (:foreground ,zweilight-pink))))
   `(magit-sequence-done ((t (:foreground ,zweilight-grey+1))))
   `(magit-sequence-onto ((t (:foreground ,zweilight-grey+1))))
;;;;;; bisect
   `(magit-bisect-good ((t (:foreground ,zweilight-fg-1))))
   `(magit-bisect-skip ((t (:foreground ,zweilight-cyan))))
   `(magit-bisect-bad  ((t (:foreground ,zweilight-pink))))
;;;;;; blame
   `(magit-blame-heading ((t (:background ,zweilight-blue :foreground ,zweilight-cyan-2))))
   `(magit-blame-hash    ((t (:background ,zweilight-blue :foreground ,zweilight-cyan-2))))
   `(magit-blame-name    ((t (:background ,zweilight-blue :foreground ,zweilight-fg))))
   `(magit-blame-date    ((t (:background ,zweilight-blue :foreground ,zweilight-fg))))
   `(magit-blame-summary ((t (:background ,zweilight-blue :foreground ,zweilight-cyan-2
                                          :weight bold))))
;;;;;; references etc
   `(magit-dimmed         ((t (:foreground ,zweilight-blue))))
   `(magit-hash           ((t (:foreground ,zweilight-blue))))
   `(magit-tag            ((t (:foreground ,zweilight-fg :weight bold))))
   `(magit-branch-remote  ((t (:foreground ,zweilight-fg-1  :weight bold))))
   `(magit-branch-local   ((t (:foreground ,zweilight-cyan-1   :weight bold))))
   `(magit-branch-current ((t (:foreground ,zweilight-cyan-1   :weight bold :box t))))
   `(magit-head           ((t (:foreground ,zweilight-cyan-1   :weight bold))))
   `(magit-refname        ((t (:background ,zweilight-fg :foreground ,zweilight-fg :weight bold))))
   `(magit-refname-stash  ((t (:background ,zweilight-fg :foreground ,zweilight-fg :weight bold))))
   `(magit-refname-wip    ((t (:background ,zweilight-fg :foreground ,zweilight-fg :weight bold))))
   `(magit-signature-good      ((t (:foreground ,zweilight-fg-1))))
   `(magit-signature-bad       ((t (:foreground ,zweilight-pink))))
   `(magit-signature-untrusted ((t (:foreground ,zweilight-cyan))))
   `(magit-cherry-unmatched    ((t (:foreground ,zweilight-orange))))
   `(magit-cherry-equivalent   ((t (:foreground ,zweilight-pink+1))))
   `(magit-reflog-commit       ((t (:foreground ,zweilight-fg-1))))
   `(magit-reflog-amend        ((t (:foreground ,zweilight-pink+1))))
   `(magit-reflog-merge        ((t (:foreground ,zweilight-fg-1))))
   `(magit-reflog-checkout     ((t (:foreground ,zweilight-cyan-1))))
   `(magit-reflog-reset        ((t (:foreground ,zweilight-pink))))
   `(magit-reflog-rebase       ((t (:foreground ,zweilight-pink+1))))
   `(magit-reflog-cherry-pick  ((t (:foreground ,zweilight-fg-1))))
   `(magit-reflog-remote       ((t (:foreground ,zweilight-orange))))
   `(magit-reflog-other        ((t (:foreground ,zweilight-orange))))
;;;;; message-mode
   `(message-cited-text ((t (:inherit font-lock-comment-face))))
   `(message-header-name ((t (:foreground ,zweilight-bg))))
   `(message-header-other ((t (:foreground ,zweilight-fg-1))))
   `(message-header-to ((t (:foreground ,zweilight-cyan :weight bold))))
   `(message-header-cc ((t (:foreground ,zweilight-cyan :weight bold))))
   `(message-header-newsgroups ((t (:foreground ,zweilight-cyan :weight bold))))
   `(message-header-subject ((t (:foreground ,zweilight-fg :weight bold))))
   `(message-header-xheader ((t (:foreground ,zweilight-fg-1))))
   `(message-mml ((t (:foreground ,zweilight-cyan :weight bold))))
   `(message-separator ((t (:inherit font-lock-comment-face))))
;;;;; mew
   `(mew-face-header-subject ((t (:foreground ,zweilight-fg))))
   `(mew-face-header-from ((t (:foreground ,zweilight-cyan))))
   `(mew-face-header-date ((t (:foreground ,zweilight-fg-1))))
   `(mew-face-header-to ((t (:foreground ,zweilight-pink))))
   `(mew-face-header-key ((t (:foreground ,zweilight-fg-1))))
   `(mew-face-header-private ((t (:foreground ,zweilight-fg-1))))
   `(mew-face-header-important ((t (:foreground ,zweilight-cyan-1))))
   `(mew-face-header-marginal ((t (:foreground ,zweilight-fg :weight bold))))
   `(mew-face-header-warning ((t (:foreground ,zweilight-pink))))
   `(mew-face-header-xmew ((t (:foreground ,zweilight-fg-1))))
   `(mew-face-header-xmew-bad ((t (:foreground ,zweilight-pink))))
   `(mew-face-body-url ((t (:foreground ,zweilight-fg))))
   `(mew-face-body-comment ((t (:foreground ,zweilight-fg :slant italic))))
   `(mew-face-body-cite1 ((t (:foreground ,zweilight-fg-1))))
   `(mew-face-body-cite2 ((t (:foreground ,zweilight-cyan-1))))
   `(mew-face-body-cite3 ((t (:foreground ,zweilight-fg))))
   `(mew-face-body-cite4 ((t (:foreground ,zweilight-cyan))))
   `(mew-face-body-cite5 ((t (:foreground ,zweilight-pink))))
   `(mew-face-mark-review ((t (:foreground ,zweilight-cyan-1))))
   `(mew-face-mark-escape ((t (:foreground ,zweilight-fg-1))))
   `(mew-face-mark-delete ((t (:foreground ,zweilight-pink))))
   `(mew-face-mark-unlink ((t (:foreground ,zweilight-cyan))))
   `(mew-face-mark-refile ((t (:foreground ,zweilight-fg-1))))
   `(mew-face-mark-unread ((t (:foreground ,zweilight-red-pastel+2))))
   `(mew-face-eof-message ((t (:foreground ,zweilight-fg-1))))
   `(mew-face-eof-part ((t (:foreground ,zweilight-cyan))))
;;;;; mic-paren
   `(paren-face-match ((t (:foreground ,zweilight-orange :background ,zweilight-bg :weight bold))))
   `(paren-face-mismatch ((t (:foreground ,zweilight-bg :background ,zweilight-pink+1 :weight bold))))
   `(paren-face-no-match ((t (:foreground ,zweilight-bg :background ,zweilight-pink :weight bold))))
;;;;; mingus
   `(mingus-directory-face ((t (:foreground ,zweilight-cyan-1))))
   `(mingus-pausing-face ((t (:foreground ,zweilight-pink+1))))
   `(mingus-playing-face ((t (:foreground ,zweilight-orange))))
   `(mingus-playlist-face ((t (:foreground ,zweilight-orange ))))
   `(mingus-song-file-face ((t (:foreground ,zweilight-cyan))))
   `(mingus-stopped-face ((t (:foreground ,zweilight-pink))))
;;;;; nav
   `(nav-face-heading ((t (:foreground ,zweilight-cyan))))
   `(nav-face-button-num ((t (:foreground ,zweilight-orange))))
   `(nav-face-dir ((t (:foreground ,zweilight-fg-1))))
   `(nav-face-hdir ((t (:foreground ,zweilight-pink))))
   `(nav-face-file ((t (:foreground ,zweilight-fg))))
   `(nav-face-hfile ((t (:foreground ,zweilight-red-pastel))))
;;;;; mu4e
   `(mu4e-cited-1-face ((t (:foreground ,zweilight-cyan-1    :slant italic))))
   `(mu4e-cited-2-face ((t (:foreground ,zweilight-fg-1 :slant italic))))
   `(mu4e-cited-3-face ((t (:foreground ,zweilight-cyan-2  :slant italic))))
   `(mu4e-cited-4-face ((t (:foreground ,zweilight-fg-1   :slant italic))))
   `(mu4e-cited-5-face ((t (:foreground ,zweilight-yellow  :slant italic))))
   `(mu4e-cited-6-face ((t (:foreground ,zweilight-fg-1 :slant italic))))
   `(mu4e-cited-7-face ((t (:foreground ,zweilight-cyan-1    :slant italic))))
   `(mu4e-replied-face ((t (:foreground ,zweilight-blue))))
   `(mu4e-trashed-face ((t (:foreground ,zweilight-blue :strike-through t))))
;;;;; mumamo
   `(mumamo-background-chunk-major ((t (:background nil))))
   `(mumamo-background-chunk-submode1 ((t (:background ,zweilight-blue))))
   `(mumamo-background-chunk-submode2 ((t (:background ,zweilight-fg))))
   `(mumamo-background-chunk-submode3 ((t (:background ,zweilight-blue))))
   `(mumamo-background-chunk-submode4 ((t (:background ,zweilight-grey))))
;;;;; org-mode
   `(org-agenda-date-today
     ((t (:foreground ,zweilight-yellow :slant italic :weight bold))) t)
   `(org-agenda-structure
     ((t (:inherit font-lock-comment-face))))
   `(org-archived ((t (:foreground ,zweilight-fg :weight bold))))
   `(org-checkbox ((t (:background ,zweilight-fg :foreground ,zweilight-yellow
                                   :box (:line-width 1 :style released-button)))))
   `(org-date ((t (:foreground ,zweilight-cyan-1 :underline t))))
   `(org-deadline-announce ((t (:foreground ,zweilight-red-pastel+3))))
   `(org-done ((t (:bold t :weight bold :foreground ,zweilight-green))))
   `(org-formula ((t (:foreground ,zweilight-yellow))))
   `(org-headline-done ((t (:foreground ,zweilight-green))))
   `(org-hide ((t (:foreground ,zweilight-blue))))
   `(org-level-1 ((t (:weight bold :foreground ,zweilight-fg))))
   `(org-level-2 ((t (:foreground ,zweilight-yellow))))
   `(org-level-3 ((t (:foreground ,zweilight-blue))))
   `(org-level-4 ((t (:foreground ,zweilight-yellow))))
   `(org-level-5 ((t (:foreground ,zweilight-orange))))
   `(org-level-6 ((t (:foreground ,zweilight-fg-1))))
   `(org-level-7 ((t (:foreground ,zweilight-red-pastel))))
   `(org-level-8 ((t (:foreground ,zweilight-yellow))))
   `(org-link ((t (:foreground ,zweilight-yellow :underline t))))
   `(org-scheduled ((t (:foreground ,zweilight-yellow))))
   `(org-scheduled-previously ((t (:foreground ,zweilight-pink))))
   `(org-scheduled-today ((t (:foreground ,zweilight-orange))))
   `(org-sexp-date ((t (:foreground ,zweilight-orange :underline t))))
   `(org-special-keyword ((t (:inherit font-lock-comment-face))))
   `(org-table ((t (:foreground ,zweilight-fg-1))))
   `(org-tag ((t (:bold t :weight bold))))
   `(org-time-grid ((t (:foreground ,zweilight-fg))))
   `(org-todo ((t (:bold t :foreground ,zweilight-pink :weight bold))))
   `(org-upcoming-deadline ((t (:inherit font-lock-keyword-face))))
   `(org-warning ((t (:bold t :foreground ,zweilight-pink :weight bold :underline nil))))
   `(org-column ((t (:background ,zweilight-blue))))
   `(org-column-title ((t (:background ,zweilight-blue :underline t :weight bold))))
   `(org-mode-line-clock ((t (:foreground ,zweilight-fg :background ,zweilight-blue))))
   `(org-mode-line-clock-overrun ((t (:foreground ,zweilight-bg :background ,zweilight-red-pastel+3))))
   `(org-ellipsis ((t (:foreground ,zweilight-yellow+1 :underline t))))
   `(org-footnote ((t (:foreground ,zweilight-orange :underline t))))
   `(org-document-title ((t (:foreground ,zweilight-cyan-1))))
   `(org-document-info ((t (:foreground ,zweilight-cyan-1))))
   `(org-habit-ready-face ((t :background ,zweilight-fg-1)))
   `(org-habit-alert-face ((t :background ,zweilight-yellow+1 :foreground ,zweilight-bg)))
   `(org-habit-clear-face ((t :background ,zweilight-cyan-3)))
   `(org-habit-overdue-face ((t :background ,zweilight-red-pastel+1)))
   `(org-habit-clear-future-face ((t :background ,zweilight-yellow)))
   `(org-habit-ready-future-face ((t :background ,zweilight-fg-1)))
   `(org-habit-alert-future-face ((t :background ,zweilight-yellow :foreground ,zweilight-bg)))
   `(org-habit-overdue-future-face ((t :background ,zweilight-red-pastel)))
;;;;; outline
   `(outline-1 ((t (:foreground ,zweilight-fg))))
   `(outline-2 ((t (:foreground ,zweilight-yellow))))
   `(outline-3 ((t (:foreground ,zweilight-blue))))
   `(outline-4 ((t (:foreground ,zweilight-yellow))))
   `(outline-5 ((t (:foreground ,zweilight-orange))))
   `(outline-6 ((t (:foreground ,zweilight-fg-1))))
   `(outline-7 ((t (:foreground ,zweilight-red-pastel))))
   `(outline-8 ((t (:foreground ,zweilight-yellow))))
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
   `(persp-selected-face ((t (:foreground ,zweilight-yellow :inherit mode-line))))
;;;;; powerline
   `(powerline-active1 ((t (:background ,zweilight-bg+3 :inherit mode-line))))
   `(powerline-active2 ((t (:background ,zweilight-fg :inherit mode-line))))
   `(powerline-inactive1 ((t (:background ,zweilight-grey :inherit mode-line-inactive))))
   `(powerline-inactive2 ((t (:background ,zweilight-blue :inherit mode-line-inactive))))
;;;;; proofgeneral
   `(proof-active-area-face ((t (:underline t))))
   `(proof-boring-face ((t (:foreground ,zweilight-fg :background ,zweilight-fg))))
   `(proof-command-mouse-highlight-face ((t (:inherit proof-mouse-highlight-face))))
   `(proof-debug-message-face ((t (:inherit proof-boring-face))))
   `(proof-declaration-name-face ((t (:inherit font-lock-keyword-face :foreground nil))))
   `(proof-eager-annotation-face ((t (:foreground ,zweilight-bg :background ,zweilight-fg))))
   `(proof-error-face ((t (:foreground ,zweilight-fg :background ,zweilight-red-pastel))))
   `(proof-highlight-dependency-face ((t (:foreground ,zweilight-bg :background ,zweilight-yellow+1))))
   `(proof-highlight-dependent-face ((t (:foreground ,zweilight-bg :background ,zweilight-fg))))
   `(proof-locked-face ((t (:background ,zweilight-bg))))
   `(proof-mouse-highlight-face ((t (:foreground ,zweilight-bg :background ,zweilight-fg))))
   `(proof-queue-face ((t (:background ,zweilight-red-pastel))))
   `(proof-region-mouse-highlight-face ((t (:inherit proof-mouse-highlight-face))))
   `(proof-script-highlight-error-face ((t (:background ,zweilight-red-pastel+2))))
   `(proof-tacticals-name-face ((t (:inherit font-lock-constant-face :foreground nil :background ,zweilight-bg))))
   `(proof-tactics-name-face ((t (:inherit font-lock-constant-face :foreground nil :background ,zweilight-bg))))
   `(proof-warning-face ((t (:foreground ,zweilight-bg :background ,zweilight-yellow+1))))
;;;;; racket-mode
   `(racket-keyword-argument-face ((t (:inherit font-lock-constant-face))))
   `(racket-selfeval-face ((t (:inherit font-lock-type-face))))
;;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,zweilight-fg))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,zweilight-yellow))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,zweilight-yellow))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,zweilight-orange))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground ,zweilight-fg-1))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,zweilight-orange))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,zweilight-yellow+1))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground ,zweilight-bg))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground ,zweilight-cyan-2))))
   `(rainbow-delimiters-depth-10-face ((t (:foreground ,zweilight-fg))))
   `(rainbow-delimiters-depth-11-face ((t (:foreground ,zweilight-fg-1))))
   `(rainbow-delimiters-depth-12-face ((t (:foreground ,zweilight-bg))))
;;;;; rcirc
   `(rcirc-my-nick ((t (:foreground ,zweilight-cyan-1))))
   `(rcirc-other-nick ((t (:foreground ,zweilight-fg))))
   `(rcirc-bright-nick ((t (:foreground ,zweilight-orange))))
   `(rcirc-dim-nick ((t (:foreground ,zweilight-cyan-2))))
   `(rcirc-server ((t (:foreground ,zweilight-fg-1))))
   `(rcirc-server-prefix ((t (:foreground ,zweilight-bg))))
   `(rcirc-timestamp ((t (:foreground ,zweilight-fg-1))))
   `(rcirc-nick-in-message ((t (:foreground ,zweilight-cyan))))
   `(rcirc-nick-in-message-full-line ((t (:bold t))))
   `(rcirc-prompt ((t (:foreground ,zweilight-cyan :bold t))))
   `(rcirc-track-nick ((t (:inverse-video t))))
   `(rcirc-track-keyword ((t (:bold t))))
   `(rcirc-url ((t (:bold t))))
   `(rcirc-keyword ((t (:foreground ,zweilight-cyan :bold t))))
;;;;; rpm-mode
   `(rpm-spec-dir-face ((t (:foreground ,zweilight-fg-1))))
   `(rpm-spec-doc-face ((t (:foreground ,zweilight-fg-1))))
   `(rpm-spec-ghost-face ((t (:foreground ,zweilight-pink))))
   `(rpm-spec-macro-face ((t (:foreground ,zweilight-cyan))))
   `(rpm-spec-obsolete-tag-face ((t (:foreground ,zweilight-pink))))
   `(rpm-spec-package-face ((t (:foreground ,zweilight-pink))))
   `(rpm-spec-section-face ((t (:foreground ,zweilight-cyan))))
   `(rpm-spec-tag-face ((t (:foreground ,zweilight-cyan-1))))
   `(rpm-spec-var-face ((t (:foreground ,zweilight-pink))))
;;;;; rst-mode
   `(rst-level-1-face ((t (:foreground ,zweilight-fg))))
   `(rst-level-2-face ((t (:foreground ,zweilight-bg))))
   `(rst-level-3-face ((t (:foreground ,zweilight-blue))))
   `(rst-level-4-face ((t (:foreground ,zweilight-yellow))))
   `(rst-level-5-face ((t (:foreground ,zweilight-orange))))
   `(rst-level-6-face ((t (:foreground ,zweilight-fg-1))))
;;;;; sh-mode
   `(sh-heredoc     ((t (:foreground ,zweilight-cyan :bold t))))
   `(sh-quoted-exec ((t (:foreground ,zweilight-pink))))
;;;;; show-paren
   `(show-paren-mismatch ((t (:foreground ,zweilight-red-pastel+4 :background ,zweilight-blue :weight bold))))
   `(show-paren-match ((t (:foreground ,zweilight-cyan :background ,zweilight-blue :weight bold))))
;;;;; smart-mode-line
   ;; use (setq sml/theme nil) to enable Zweilight for sml
   `(sml/global ((,class (:foreground ,zweilight-fg :weight bold))))
   `(sml/modes ((,class (:foreground ,zweilight-cyan :weight bold))))
   `(sml/minor-modes ((,class (:foreground ,zweilight-grey+1 :weight bold))))
   `(sml/filename ((,class (:foreground ,zweilight-cyan :weight bold))))
   `(sml/line-number ((,class (:foreground ,zweilight-cyan-1 :weight bold))))
   `(sml/col-number ((,class (:foreground ,zweilight-orange :weight bold))))
   `(sml/position-percentage ((,class (:foreground ,zweilight-blue :weight bold))))
   `(sml/prefix ((,class (:foreground ,zweilight-fg))))
   `(sml/git ((,class (:foreground ,zweilight-green))))
   `(sml/process ((,class (:weight bold))))
   `(sml/sudo ((,class  (:foreground ,zweilight-fg :weight bold))))
   `(sml/read-only ((,class (:foreground ,zweilight-red-pastel+2))))
   `(sml/outside-modified ((,class (:foreground ,zweilight-fg))))
   `(sml/modified ((,class (:foreground ,zweilight-pink))))
   `(sml/vc-edited ((,class (:foreground ,zweilight-fg-1))))
   `(sml/charging ((,class (:foreground ,zweilight-yellow))))
   `(sml/discharging ((,class (:foreground ,zweilight-red-pastel+4))))
;;;;; smartparens
   `(sp-show-pair-mismatch-face ((t (:foreground ,zweilight-red-pastel+4 :background ,zweilight-blue :weight bold))))
   `(sp-show-pair-match-face ((t (:background ,zweilight-blue :weight bold))))
;;;;; sml-mode-line
   '(sml-modeline-end-face ((t :inherit default :width condensed)))
;;;;; SLIME
   `(slime-repl-output-face ((t (:foreground ,zweilight-pink))))
   `(slime-repl-inputed-output-face ((t (:foreground ,zweilight-fg-1))))
   `(slime-error-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-pink)))
      (t
       (:underline ,zweilight-pink))))
   `(slime-warning-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-fg)))
      (t
       (:underline ,zweilight-fg))))
   `(slime-style-warning-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-cyan)))
      (t
       (:underline ,zweilight-cyan))))
   `(slime-note-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,zweilight-fg-1)))
      (t
       (:underline ,zweilight-fg-1))))
   `(slime-highlight-face ((t (:inherit highlight))))
;;;;; speedbar
   `(speedbar-button-face ((t (:foreground ,zweilight-fg-1))))
   `(speedbar-directory-face ((t (:foreground ,zweilight-orange))))
   `(speedbar-file-face ((t (:foreground ,zweilight-fg))))
   `(speedbar-highlight-face ((t (:foreground ,zweilight-bg :background ,zweilight-fg-1))))
   `(speedbar-selected-face ((t (:foreground ,zweilight-pink))))
   `(speedbar-separator-face ((t (:foreground ,zweilight-bg :background ,zweilight-blue))))
   `(speedbar-tag-face ((t (:foreground ,zweilight-cyan))))
;;;;; tabbar
   `(tabbar-default ((t (:foreground ,zweilight-fg
                        :background ,zweilight-bg+3))))
   `(tabbar-button ((t (:foreground ,zweilight-fg
                        :background ,zweilight-bg+3))))
   `(tabbar-unselected ((t (:foreground ,zweilight-fg
                            :background ,zweilight-bg+3))))
   `(tabbar-selected ((t (:foreground ,zweilight-bg+3
                           :background ,zweilight-blue))))
   `(tabbar-modified ((t (:foreground ,zweilight-red
                          :background ,zweilight-bg+3))))
   `(tabbar-selected-modified ((t (:foreground ,zweilight-bg+3
                                   :background ,zweilight-red-1 ))))
;;;;; term
   `(term-color-black ((t (:foreground ,zweilight-bg
                                       :background ,zweilight-blue))))
   `(term-color-red ((t (:foreground ,zweilight-red-pastel+2
                                     :background ,zweilight-red-pastel))))
   `(term-color-green ((t (:foreground ,zweilight-fg-1
                                       :background ,zweilight-fg-1))))
   `(term-color-yellow ((t (:foreground ,zweilight-fg
                                        :background ,zweilight-cyan))))
   `(term-color-blue ((t (:foreground ,zweilight-blue
                                      :background ,zweilight-yellow))))
   `(term-color-magenta ((t (:foreground ,zweilight-pink+1
                                         :background ,zweilight-pink))))
   `(term-color-cyan ((t (:foreground ,zweilight-orange
                                      :background ,zweilight-cyan-1))))
   `(term-color-white ((t (:foreground ,zweilight-fg
                                       :background ,zweilight-grey+1))))
   '(term-default-fg-color ((t (:inherit term-color-white))))
   '(term-default-bg-color ((t (:inherit term-color-black))))
;;;;; undo-tree
   `(undo-tree-visualizer-active-branch-face ((t (:foreground ,zweilight-yellow :weight bold))))
   `(undo-tree-visualizer-current-face ((t (:foreground ,zweilight-red-pastel+3 :weight bold))))
   `(undo-tree-visualizer-default-face ((t (:foreground ,zweilight-fg))))
   `(undo-tree-visualizer-register-face ((t (:foreground ,zweilight-cyan))))
   `(undo-tree-visualizer-unmodified-face ((t (:foreground ,zweilight-orange))))
;;;;; volatile-highlights
   `(vhl/default-face ((t (:background ,zweilight-bg+3))))
;;;;; web-mode
   `(web-mode-builtin-face ((t (:inherit ,font-lock-builtin-face))))
   `(web-mode-comment-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-constant-face ((t (:inherit ,font-lock-constant-face))))
   `(web-mode-css-at-rule-face ((t (:foreground ,zweilight-fg ))))
   `(web-mode-css-prop-face ((t (:foreground ,zweilight-fg))))
   `(web-mode-css-pseudo-class-face ((t (:foreground ,zweilight-green :weight bold))))
   `(web-mode-css-rule-face ((t (:foreground ,zweilight-cyan-1))))
   `(web-mode-doctype-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-folded-face ((t (:underline t))))
   `(web-mode-function-name-face ((t (:foreground ,zweilight-cyan-1))))
   `(web-mode-html-attr-name-face ((t (:foreground ,zweilight-fg))))
   `(web-mode-html-attr-value-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-html-tag-face ((t (:foreground ,zweilight-orange))))
   `(web-mode-keyword-face ((t (:inherit ,font-lock-keyword-face))))
   `(web-mode-preprocessor-face ((t (:inherit ,font-lock-preprocessor-face))))
   `(web-mode-string-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-type-face ((t (:inherit ,font-lock-type-face))))
   `(web-mode-variable-name-face ((t (:inherit ,font-lock-variable-name-face))))
   `(web-mode-server-background-face ((t (:background ,zweilight-bg))))
   `(web-mode-server-comment-face ((t (:inherit web-mode-comment-face))))
   `(web-mode-server-string-face ((t (:inherit web-mode-string-face))))
   `(web-mode-symbol-face ((t (:inherit font-lock-constant-face))))
   `(web-mode-warning-face ((t (:inherit font-lock-warning-face))))
   `(web-mode-whitespaces-face ((t (:background ,zweilight-pink))))
;;;;; whitespace-mode
   `(whitespace-space ((t (:background ,zweilight-grey :foreground ,zweilight-grey))))
   `(whitespace-hspace ((t (:background ,zweilight-grey :foreground ,zweilight-grey))))
   `(whitespace-tab ((t (:background ,zweilight-bg+3))))
   `(whitespace-newline ((t (:foreground ,zweilight-grey))))
   `(whitespace-trailing ((t (:background ,zweilight-bg+3))))
   `(whitespace-line ((t (:background ,zweilight-bg :foreground ,zweilight-pink+1))))
   `(whitespace-space-before-tab ((t (:background ,zweilight-fg :foreground ,zweilight-fg))))
   `(whitespace-indentation ((t (:background ,zweilight-bg :foreground ,zweilight-fg-1))))
   `(whitespace-empty ((t (:background ,zweilight-cyan))))
   `(whitespace-space-after-tab ((t (:background ,zweilight-bg :foreground ,zweilight-fg-1))))
;;;;; wanderlust
   `(wl-highlight-folder-few-face ((t (:foreground ,zweilight-red-pastel+2))))
   `(wl-highlight-folder-many-face ((t (:foreground ,zweilight-red-pastel+3))))
   `(wl-highlight-folder-path-face ((t (:foreground ,zweilight-fg))))
   `(wl-highlight-folder-unread-face ((t (:foreground ,zweilight-cyan-1))))
   `(wl-highlight-folder-zero-face ((t (:foreground ,zweilight-fg))))
   `(wl-highlight-folder-unknown-face ((t (:foreground ,zweilight-cyan-1))))
   `(wl-highlight-message-citation-header ((t (:foreground ,zweilight-red-pastel+3))))
   `(wl-highlight-message-cited-text-1 ((t (:foreground ,zweilight-pink))))
   `(wl-highlight-message-cited-text-2 ((t (:foreground ,zweilight-fg-1))))
   `(wl-highlight-message-cited-text-3 ((t (:foreground ,zweilight-cyan-1))))
   `(wl-highlight-message-cited-text-4 ((t (:foreground ,zweilight-orange))))
   `(wl-highlight-message-header-contents-face ((t (:foreground ,zweilight-fg-1))))
   `(wl-highlight-message-headers-face ((t (:foreground ,zweilight-red-pastel+4))))
   `(wl-highlight-message-important-header-contents ((t (:foreground ,zweilight-fg-1))))
   `(wl-highlight-message-header-contents ((t (:foreground ,zweilight-bg))))
   `(wl-highlight-message-important-header-contents2 ((t (:foreground ,zweilight-fg-1))))
   `(wl-highlight-message-signature ((t (:foreground ,zweilight-fg-1))))
   `(wl-highlight-message-unimportant-header-contents ((t (:foreground ,zweilight-fg))))
   `(wl-highlight-summary-answered-face ((t (:foreground ,zweilight-cyan-1))))
   `(wl-highlight-summary-disposed-face ((t (:foreground ,zweilight-fg
                                                         :slant italic))))
   `(wl-highlight-summary-new-face ((t (:foreground ,zweilight-cyan-1))))
   `(wl-highlight-summary-normal-face ((t (:foreground ,zweilight-fg))))
   `(wl-highlight-summary-thread-top-face ((t (:foreground ,zweilight-cyan))))
   `(wl-highlight-thread-indent-face ((t (:foreground ,zweilight-pink+1))))
   `(wl-highlight-summary-refiled-face ((t (:foreground ,zweilight-fg))))
   `(wl-highlight-summary-displaying-face ((t (:underline t :weight bold))))
;;;;; which-func-mode
   `(which-func ((t (:foreground ,zweilight-yellow))))
;;;;; xcscope
   `(cscope-file-face ((t (:foreground ,zweilight-cyan :weight bold))))
   `(cscope-function-face ((t (:foreground ,zweilight-orange :weight bold))))
   `(cscope-line-number-face ((t (:foreground ,zweilight-pink :weight bold))))
   `(cscope-mouse-face ((t (:foreground ,zweilight-bg :background ,zweilight-orange))))
   `(cscope-separator-face ((t (:foreground ,zweilight-pink :weight bold
                                            :underline t :overline t))))
;;;;; yascroll
   `(yascroll:thumb-text-area ((t (:background ,zweilight-blue))))
   `(yascroll:thumb-fringe ((t (:background ,zweilight-blue :foreground ,zweilight-blue))))

;;;;; highlight-indent-guides
   `(highlight-indent-guides-odd-face ((t (:background ,zweilight-bg+1))))
   `(highlight-indent-guides-even-face ((t (:background ,zweilight-bg+2))))
   ))

;;; Theme Variables
(zweilight-with-color-variables
  (custom-theme-set-variables
   'zweilight
;;;;; ansi-color
   `(ansi-color-names-vector [,zweilight-bg ,zweilight-pink ,zweilight-fg-1 ,zweilight-cyan
                                          ,zweilight-cyan-1 ,zweilight-pink+1 ,zweilight-orange ,zweilight-fg])
;;;;; fill-column-indicator
   `(fci-rule-color ,zweilight-fg-1)
;;;;; nrepl-client
   `(nrepl-message-colors
     '(,zweilight-pink ,zweilight-fg ,zweilight-cyan ,zweilight-fg-1 ,zweilight-yellow
                    ,zweilight-orange ,zweilight-orange ,zweilight-pink+1))
;;;;; vc-annotate
   `(vc-annotate-color-map
     '(( 20. . ,zweilight-red-pastel+3)
       ( 40. . ,zweilight-pink)
       ( 60. . ,zweilight-fg)
       ( 80. . ,zweilight-yellow)
       (100. . ,zweilight-yellow+1)
       (120. . ,zweilight-cyan)
       (140. . ,zweilight-fg-1)
       (160. . ,zweilight-fg-1)
       (180. . ,zweilight-bg)
       (200. . ,zweilight-fg-1)
       (220. . ,zweilight-green)
       (240. . ,zweilight-yellow)
       (260. . ,zweilight-orange)
       (280. . ,zweilight-cyan-2)
       (300. . ,zweilight-blue)
       (320. . ,zweilight-cyan-1)
       (340. . ,zweilight-orange)
       (360. . ,zweilight-pink+1)))
   `(vc-annotate-very-old-color ,zweilight-pink+1)
   `(vc-annotate-background ,zweilight-blue)
   ))

;;; Footer

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'zweilight)

;; Local Variables:
;; no-byte-compile: t
;; indent-tabs-mode: nil
;; End:
;;; zweilight-theme.el ends here
