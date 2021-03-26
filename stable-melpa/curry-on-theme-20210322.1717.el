;;; curry-on-theme.el --- A low contrast color theme

;; Copyright © 2019-2021 Martín Varela
;; Copyright (C) 2011016 Bozhidar Batsov (zenburn-theme.el)

;; Author: Martín Varela (martin@varela.fi)
;; URL: https://github.com/mvarela/Curry-On-Theme
;; Package-Version: 20210322.1717
;; Package-Commit: b53a61d443cc75906d9f97e19f19be71f1e19bc4
;; Version: 1.0
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
;; A punchy, blue-orange-cream theme for Emacs
;;; Credits:
;; This code is based off my Sunburn theme, which in turn is based off Bozhidar
;; Batsov's port of the Zenburn theme

;;; Code:

(deftheme curry-on "The Curry-On color theme")

;;; Color Palette
(eval-when-compile
 (defvar curry-on-theme-default-colors-alist
  '(("curry-on-fg+1"     . "#edecc9")
    ("curry-on-fg"       . "#fdfcd9")
    ("curry-on-bg"       . "#302e40")
    ("curry-on-bg+1"     . "#686369")
    ("curry-on-bg+3"     . "#7d94b0")
    ("curry-on-red"      . "#e46d39")
    ("curry-on-orange"   . "#ffb242")
    ("curry-on-yellow"   . "#f5d563")
    ("curry-on-gold"     . "#ffb242")
    ("curry-on-green"    . "#91b221")
    ("curry-on-blue"   .   "#7d94b0")
    ("curry-on-magenta"  . "#e3aae3"))
  "List of Curry-On colors.
Each element has the form (NAME . HEX).

`+N' suffixes indicate a color is lighter.
`-N' suffixes indicate a color is darker.")

(defvar curry-on-theme-override-colors-alist
  '()
  "Place to override default theme colors.

You can override a subset of the theme's default colors by
defining them in this alist before loading the theme.
Please note that this won't work if you compile this file.")
(defvar curry-on-theme-colors-alist
  (append curry-on-theme-default-colors-alist curry-on-theme-override-colors-alist)))


(defmacro curry-on-theme-with-color-variables (&rest body)
  "`let' bind all colors defined in `curry-on-colors-alist' around BODY.
Also bind `class' to ((class color) (min-colors 89))."
  (declare (indent 0))
  `(let ((class '((class color) (min-colors 89)))
         ,@(mapcar (lambda (cons)
                     (list (intern (car cons)) (cdr cons)))
                   curry-on-theme-colors-alist))
     ,@body))

;;; Theme Faces
(curry-on-theme-with-color-variables
  (custom-theme-set-faces
   'curry-on
;;;; Built-in
;;;;; basic coloring
   `(button ((t (:foreground ,curry-on-yellow :underline t))))
   `(widget-button ((t (:foreground ,curry-on-yellow :underline t))))
   `(link ((t (:foreground ,curry-on-yellow :underline t :weight bold))))
   `(link-visited ((t (:foreground ,curry-on-yellow :underline t :weight normal))))
   `(default ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
   `(cursor ((t (:foreground ,curry-on-fg :background ,curry-on-fg+1))))
   `(escape-glyph ((t (:foreground ,curry-on-yellow :weight bold))))
   `(fringe ((t (:foreground ,curry-on-fg :background ,curry-on-bg+1))))
   `(header-line ((t (:foreground ,curry-on-yellow
                                  :background ,curry-on-bg
                                  :box (:line-width -1  :style released-button)))))
   `(highlight ((t (:background ,curry-on-bg))))
   `(success ((t (:foreground ,curry-on-green :weight bold))))
   `(warning ((t (:foreground ,curry-on-orange :weight bold))))
   `(tooltip ((t (:foreground ,curry-on-fg :background ,curry-on-bg+1))))


   ;; Spaceline colors

   `(spaceline-evil-insert ((t (:foreground ,curry-on-green :weight bold))))
;;;;; compilation
   `(compilation-column-face ((t (:foreground ,curry-on-yellow))))
   `(compilation-enter-directory-face ((t (:foreground ,curry-on-green))))
   `(compilation-error-face ((t (:foreground ,curry-on-red :weight bold :underline t))))
   `(compilation-face ((t (:foreground ,curry-on-fg))))
   `(compilation-info-face ((t (:foreground ,curry-on-blue))))
   `(compilation-info ((t (:foreground ,curry-on-green :underline t))))
   `(compilation-leave-directory-face ((t (:foreground ,curry-on-green))))
   `(compilation-line-face ((t (:foreground ,curry-on-yellow))))
   `(compilation-line-number ((t (:foreground ,curry-on-yellow))))
   `(compilation-message-face ((t (:foreground ,curry-on-blue))))
   `(compilation-warning-face ((t (:foreground ,curry-on-orange :weight bold :underline t))))
   `(compilation-mode-line-exit ((t (:foreground ,curry-on-green :weight bold))))
   `(compilation-mode-line-fail ((t (:foreground ,curry-on-red :weight bold))))
   `(compilation-mode-line-run ((t (:foreground ,curry-on-yellow :weight bold))))
;;;;; completions
   `(completions-annotations ((t (:foreground ,curry-on-fg))))
;;;;; grep
   `(grep-context-face ((t (:foreground ,curry-on-fg))))
   `(grep-error-face ((t (:foreground ,curry-on-red :weight bold :underline t))))
   `(grep-hit-face ((t (:foreground ,curry-on-blue))))
   `(grep-match-face ((t (:foreground ,curry-on-orange :weight bold))))
   `(match ((t (:background ,curry-on-bg :foreground ,curry-on-orange :weight bold))))
;;;;; info
   `(Info-quoted ((t (:inherit font-lock-constant-face))))
;;;;; isearch
   `(isearch ((t (:foreground ,curry-on-yellow :weight bold :background ,curry-on-bg))))
   `(isearch-fail ((t (:foreground ,curry-on-fg :background ,curry-on-red))))
   `(lazy-highlight ((t (:foreground ,curry-on-yellow :weight bold :background ,curry-on-bg))))

   `(menu ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
   `(minibuffer-prompt ((t (:background ,curry-on-bg :foreground ,curry-on-yellow))))
   `(mode-line
     ((,class (:foreground ,curry-on-fg+1
                           :background ,curry-on-bg
                           :box (:line-width -1  :style released-button)))
      (t :inverse-video t)))
   `(mode-line-buffer-id ((t (:foreground ,curry-on-fg :weight bold))))
   `(mode-line-inactive
     ((t (:foreground ,curry-on-blue
                      :background ,curry-on-bg
                      :box (:line-width -1 :style released-button)))))
   ;; `(region ((,class (:background ,curry-on-gold))
   ;;           (t :inverse-video t)))
   `(region ((t (:foreground ,curry-on-bg  :background ,curry-on-gold :reverse-video t))))
   `(secondary-selection ((t (:background ,curry-on-bg))))
   `(trailing-whitespace ((t (:background ,curry-on-red))))
   `(vertical-border ((t (:foreground ,curry-on-fg))))
;;;;; font lock
   `(font-lock-builtin-face ((t (:foreground ,curry-on-fg, :weight bold))))
   `(font-lock-comment-face ((t (:background ,curry-on-bg :foreground ,curry-on-bg+3))))
   `(font-lock-comment-delimiter-face ((t (:background ,curry-on-bg :foreground ,curry-on-bg+3))))
   `(font-lock-constant-face ((t (:foreground ,curry-on-fg+1, :weight bold))))
   `(font-lock-doc-face ((t (:foreground ,curry-on-blue))))
   `(font-lock-function-name-face ((t (:foreground ,curry-on-fg))))
   `(font-lock-keyword-face ((t (:foreground ,curry-on-orange :weight bold))))
   `(font-lock-negation-char-face ((t (:foreground ,curry-on-yellow :weight bold))))
   `(font-lock-preprocessor-face ((t (:foreground ,curry-on-blue))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,curry-on-yellow :weight bold))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,curry-on-green :weight bold))))
   `(font-lock-string-face ((t (:foreground ,curry-on-red))))
   `(font-lock-type-face ((t (:foreground ,curry-on-green))))
   `(font-lock-variable-name-face ((t (:foreground ,curry-on-orange))))
   `(font-lock-warning-face ((t (:foreground ,curry-on-yellow :weight bold))))

   `(c-annotation-face ((t (:inherit font-lock-constant-face))))
;;;;; newsticker
   `(newsticker-date-face ((t (:foreground ,curry-on-fg))))
   `(newsticker-default-face ((t (:foreground ,curry-on-fg))))
   `(newsticker-enclosure-face ((t (:foreground ,curry-on-green))))
   `(newsticker-extra-face ((t (:foreground ,curry-on-bg :height 0.8))))
   `(newsticker-feed-face ((t (:foreground ,curry-on-fg))))
   `(newsticker-immortal-item-face ((t (:foreground ,curry-on-green))))
   `(newsticker-new-item-face ((t (:foreground ,curry-on-blue))))
   `(newsticker-obsolete-item-face ((t (:foreground ,curry-on-red))))
   `(newsticker-old-item-face ((t (:foreground ,curry-on-bg+3))))
   `(newsticker-statistics-face ((t (:foreground ,curry-on-fg))))
   `(newsticker-treeview-face ((t (:foreground ,curry-on-fg))))
   `(newsticker-treeview-immortal-face ((t (:foreground ,curry-on-green))))
   `(newsticker-treeview-listwindow-face ((t (:foreground ,curry-on-fg))))
   `(newsticker-treeview-new-face ((t (:foreground ,curry-on-blue :weight bold))))
   `(newsticker-treeview-obsolete-face ((t (:foreground ,curry-on-red))))
   `(newsticker-treeview-old-face ((t (:foreground ,curry-on-bg+3))))
   `(newsticker-treeview-selection-face ((t (:background ,curry-on-bg :foreground ,curry-on-yellow))))
;;;; Third-party
;;;;; ace-jump
   `(ace-jump-face-background
     ((t (:foreground ,curry-on-fg :background ,curry-on-bg :inverse-video nil))))
   `(ace-jump-face-foreground
     ((t (:foreground ,curry-on-green :background ,curry-on-bg :inverse-video nil))))
;;;;; ace-window
   `(aw-background-face
     ((t (:foreground ,curry-on-fg :background ,curry-on-bg :inverse-video nil))))
   `(aw-leading-char-face ((t (:inherit aw-mode-line-face))))
;;;;; android mode
   `(android-mode-debug-face ((t (:foreground ,curry-on-green))))
   `(android-mode-error-face ((t (:foreground ,curry-on-orange :weight bold))))
   `(android-mode-info-face ((t (:foreground ,curry-on-fg))))
   `(android-mode-verbose-face ((t (:foreground ,curry-on-green))))
   `(android-mode-warning-face ((t (:foreground ,curry-on-yellow))))
;;;;; anzu
   `(anzu-mode-line ((t (:foreground ,curry-on-blue :weight bold))))
   `(anzu-mode-line-no-match ((t (:foreground ,curry-on-red :weight bold))))
   `(anzu-match ((t (:foreground ,curry-on-bg :background ,curry-on-green))))
   `(anzu-match ((t (:foreground ,curry-on-bg :background ,curry-on-orange))))
   `(anzu-match ((t (:foreground ,curry-on-bg :background ,curry-on-blue))))
   `(anzu-replace-to ((t (:inherit anzu-replace-highlight :foreground ,curry-on-yellow))))
;;;;; auctex
   `(font-latex-bold-face ((t (:inherit bold))))
   `(font-latex-warning-face ((t (:foreground nil :inherit font-lock-warning-face))))
   `(font-latex-slide-title-face ((t (:foreground ,curry-on-blue :weight bold :scale 1.3))))
   `(font-latex-sectioning-0-face ((t (:foreground ,curry-on-yellow :weight bold :scale 1.3))))
   `(font-latex-sectioning-face ((t (:foreground ,curry-on-blue :weight bold :scale 1.2))))
   `(font-latex-sectioning-face ((t (:foreground ,curry-on-orange :weight bold :scale 1.1))))
   `(font-latex-sectioning-face ((t (:foreground ,curry-on-blue :weight bold ))))
   `(font-latex-sectioning-face ((t (:foreground ,curry-on-green :weight bold ))))
   `(font-latex-sectioning-face ((t (:foreground ,curry-on-red :weight bold ))))
   `(font-latex-verbatim-face ((t (:foreground ,curry-on-blue :weight bold ))))
   `(font-latex-sedate-face ((t (:foreground ,curry-on-yellow))))
   `(font-latex-italic-face ((t (:foreground ,curry-on-blue :slant italic))))
   `(font-latex-string-face ((t (:foreground ,curry-on-red))))
   `(font-latex-math-face ((t (:foreground ,curry-on-orange))))
;;;;; agda-mode
   `(agda2-highlight-keyword-face ((t (:foreground ,curry-on-yellow :weight bold))))
   `(agda2-highlight-string-face ((t (:foreground ,curry-on-red))))
   `(agda2-highlight-symbol-face ((t (:foreground ,curry-on-orange))))
   `(agda2-highlight-primitive-type-face ((t (:foreground ,curry-on-blue))))
   `(agda2-highlight-inductive-constructor-face ((t (:foreground ,curry-on-fg))))
   `(agda2-highlight-coinductive-constructor-face ((t (:foreground ,curry-on-fg))))
   `(agda2-highlight-datatype-face ((t (:foreground ,curry-on-blue))))
   `(agda2-highlight-function-face ((t (:foreground ,curry-on-blue))))
   `(agda2-highlight-module-face ((t (:foreground ,curry-on-blue))))
   `(agda2-highlight-error-face ((t (:foreground ,curry-on-bg :background ,curry-on-magenta))))
   `(agda2-highlight-unsolved-meta-face ((t (:foreground ,curry-on-bg :background ,curry-on-magenta))))
   `(agda2-highlight-unsolved-constraint-face ((t (:foreground ,curry-on-bg :background ,curry-on-magenta))))
   `(agda2-highlight-termination-problem-face ((t (:foreground ,curry-on-bg :background ,curry-on-magenta))))
   `(agda2-highlight-incomplete-pattern-face ((t (:foreground ,curry-on-bg :background ,curry-on-magenta))))
   `(agda2-highlight-typechecks-face ((t (:background ,curry-on-red))))
;;;;; auto-complete
   `(ac-candidate-face ((t (:background ,curry-on-bg+3 :foreground ,curry-on-bg))))
   `(ac-selection-face ((t (:background ,curry-on-blue :foreground ,curry-on-fg))))
   `(popup-tip-face ((t (:background ,curry-on-yellow :foreground ,curry-on-bg))))
   `(popup-menu-mouse-face ((t (:background ,curry-on-yellow :foreground ,curry-on-bg))))
   `(popup-summary-face ((t (:background ,curry-on-bg+3 :foreground ,curry-on-bg))))
   `(popup-scroll-bar-foreground-face ((t (:background ,curry-on-blue))))
   `(popup-scroll-bar-background-face ((t (:background ,curry-on-bg))))
   `(popup-isearch-match ((t (:background ,curry-on-bg :foreground ,curry-on-fg))))
;;;;; avy
   `(avy-background-face
     ((t (:foreground ,curry-on-fg :background ,curry-on-bg :inverse-video nil))))
   `(avy-lead-face-0
     ((t (:foreground ,curry-on-green :background ,curry-on-bg :inverse-video nil :weight bold))))
   `(avy-lead-face
     ((t (:foreground ,curry-on-yellow :background ,curry-on-bg :inverse-video nil :weight bold))))
   `(avy-lead-face
     ((t (:foreground ,curry-on-red :background ,curry-on-bg :inverse-video nil :weight bold))))
   `(avy-lead-face
     ((t (:foreground ,curry-on-blue :background ,curry-on-bg :inverse-video nil :weight bold))))
;;;;; company-mode
   `(company-tooltip ((t (:foreground ,curry-on-fg :background ,curry-on-bg+1))))
   `(company-tooltip-annotation ((t (:foreground ,curry-on-orange :background ,curry-on-bg+1))))
   `(company-tooltip-annotation-selection ((t (:foreground ,curry-on-orange :background ,curry-on-bg))))
   `(company-tooltip-selection ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
   `(company-tooltip-mouse ((t (:background ,curry-on-bg))))
   `(company-tooltip-common ((t (:foreground ,curry-on-green))))
   `(company-tooltip-common-selection ((t (:foreground ,curry-on-green))))
   `(company-scrollbar-fg ((t (:background ,curry-on-bg))))
   `(company-scrollbar-bg ((t (:background ,curry-on-bg))))
   `(company-preview ((t (:background ,curry-on-green))))
   `(company-preview-common ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
;;;;; bm
   `(bm-face ((t (:background ,curry-on-yellow :foreground ,curry-on-bg))))
   `(bm-fringe-face ((t (:background ,curry-on-yellow :foreground ,curry-on-bg))))
   `(bm-fringe-persistent-face ((t (:background ,curry-on-green :foreground ,curry-on-bg))))
   `(bm-persistent-face ((t (:background ,curry-on-green :foreground ,curry-on-bg))))
;;;;; calfw
   `(cfw:face-annotation ((t (:foreground ,curry-on-red :inherit cfw:face-day-title))))
   `(cfw:face-day-title ((t nil)))
   `(cfw:face-default-content ((t (:foreground ,curry-on-green))))
   `(cfw:face-default-day ((t (:weight bold))))
   `(cfw:face-disable ((t (:foreground ,curry-on-fg))))
   `(cfw:face-grid ((t (:inherit shadow))))
   `(cfw:face-header ((t (:inherit font-lock-keyword-face))))
   `(cfw:face-holiday ((t (:inherit cfw:face-sunday))))
   `(cfw:face-periods ((t (:foreground ,curry-on-blue))))
   `(cfw:face-saturday ((t (:foreground ,curry-on-blue :weight bold))))
   `(cfw:face-select ((t (:background ,curry-on-blue))))
   `(cfw:face-sunday ((t (:foreground ,curry-on-red :weight bold))))
   `(cfw:face-title ((t (:height 2.0 :inherit (variable-pitch font-lock-keyword-face)))))
   `(cfw:face-today ((t (:foreground ,curry-on-blue :weight bold))))
   `(cfw:face-today-title ((t (:inherit highlight bold))))
   `(cfw:face-toolbar ((t (:background ,curry-on-blue))))
   `(cfw:face-toolbar-button-off ((t (:underline nil :inherit link))))
   `(cfw:face-toolbar-button-on ((t (:underline nil :inherit link-visited))))
;;;;; cider
   `(cider-result-overlay-face ((t (:background unspecified))))
   `(cider-enlightened-face ((t (:box (:color ,curry-on-orange :line-width -1 )))))
   `(cider-enlightened-local-face ((t (:weight bold :foreground ,curry-on-green))))
   `(cider-deprecated-face ((t (:background ,curry-on-yellow))))
   `(cider-instrumented-face ((t (:box (:color ,curry-on-red :line-width -1)))))
   `(cider-traced-face ((t (:box (:color ,curry-on-blue :line-width -1)))))
   `(cider-test-failure-face ((t (:background ,curry-on-red))))
   `(cider-test-error-face ((t (:background ,curry-on-magenta))))
   `(cider-test-success-face ((t (:background ,curry-on-green))))
;;;;; circe
   `(circe-highlight-nick-face ((t (:foreground ,curry-on-blue))))
   `(circe-my-message-face ((t (:foreground ,curry-on-fg))))
   `(circe-fool-face ((t (:foreground ,curry-on-red))))
   `(circe-topic-diff-removed-face ((t (:foreground ,curry-on-red :weight bold))))
   `(circe-originator-face ((t (:foreground ,curry-on-fg))))
   `(circe-server-face ((t (:foreground ,curry-on-green))))
   `(circe-topic-diff-new-face ((t (:foreground ,curry-on-orange :weight bold))))
   `(circe-prompt-face ((t (:foreground ,curry-on-orange :background ,curry-on-bg :weight bold))))
;;;;; context-coloring
   `(context-coloring-level-0-face ((t :foreground ,curry-on-fg)))
   `(context-coloring-level-face ((t :foreground ,curry-on-blue)))
   `(context-coloring-level-face ((t :foreground ,curry-on-green)))
   `(context-coloring-level-face ((t :foreground ,curry-on-yellow)))
   `(context-coloring-level-face ((t :foreground ,curry-on-orange)))
   `(context-coloring-level-face ((t :foreground ,curry-on-magenta)))
   `(context-coloring-level-6-face ((t :foreground ,curry-on-blue)))
   `(context-coloring-level-7-face ((t :foreground ,curry-on-green)))
   `(context-coloring-level-8-face ((t :foreground ,curry-on-yellow)))
   `(context-coloring-level-9-face ((t :foreground ,curry-on-red)))
;;;;; coq
   `(coq-solve-tactics-face ((t (:foreground nil :inherit font-lock-constant-face))))
;;;;; ctable
   `(ctbl:face-cell-select ((t (:background ,curry-on-blue :foreground ,curry-on-bg))))
   `(ctbl:face-continue-bar ((t (:background ,curry-on-bg :foreground ,curry-on-bg))))
   `(ctbl:face-row-select ((t (:background ,curry-on-blue :foreground ,curry-on-bg))))
;;;;; debbugs
   `(debbugs-gnu-done ((t (:foreground ,curry-on-fg))))
   `(debbugs-gnu-handled ((t (:foreground ,curry-on-green))))
   `(debbugs-gnu-new ((t (:foreground ,curry-on-red))))
   `(debbugs-gnu-pending ((t (:foreground ,curry-on-blue))))
   `(debbugs-gnu-stale ((t (:foreground ,curry-on-orange))))
   `(debbugs-gnu-tagged ((t (:foreground ,curry-on-red))))
;;;;; diff
   `(diff-added          ((t (:background "#335533" :foreground ,curry-on-green))))
   `(diff-changed        ((t (:background "#555511" :foreground ,curry-on-yellow))))
   `(diff-removed        ((t (:background "#553333" :foreground ,curry-on-red))))
   `(diff-refine-added   ((t (:background "#338833" :foreground ,curry-on-green))))
   `(diff-refine-change  ((t (:background "#888811" :foreground ,curry-on-yellow))))
   `(diff-refine-removed ((t (:background "#883333" :foreground ,curry-on-red))))
   `(diff-header ((,class (:background ,curry-on-bg))
                  (t (:background ,curry-on-fg :foreground ,curry-on-bg))))
   `(diff-file-header
     ((,class (:background ,curry-on-bg :foreground ,curry-on-fg :weight bold))
      (t (:background ,curry-on-fg :foreground ,curry-on-bg :weight bold))))
;;;;; diff-hl
   `(diff-hl-change ((,class (:foreground ,curry-on-blue :background ,curry-on-blue))))
   `(diff-hl-delete ((,class (:foreground ,curry-on-red :background ,curry-on-red))))
   `(diff-hl-insert ((,class (:foreground ,curry-on-green :background ,curry-on-green))))
;;;;; dim-autoload
   `(dim-autoload-cookie-line ((t :foreground ,curry-on-bg+1)))
;;;;; dired+
   `(diredp-display-msg ((t (:foreground ,curry-on-blue))))
   `(diredp-compressed-file-suffix ((t (:foreground ,curry-on-orange))))
   `(diredp-date-time ((t (:foreground ,curry-on-magenta))))
   `(diredp-deletion ((t (:foreground ,curry-on-yellow))))
   `(diredp-deletion-file-name ((t (:foreground ,curry-on-red))))
   `(diredp-dir-heading ((t (:foreground ,curry-on-blue :background ,curry-on-bg))))
   `(diredp-dir-priv ((t (:foreground ,curry-on-blue))))
   `(diredp-exec-priv ((t (:foreground ,curry-on-red))))
   `(diredp-executable-tag ((t (:foreground ,curry-on-green))))
   `(diredp-file-name ((t (:foreground ,curry-on-blue))))
   `(diredp-file-suffix ((t (:foreground ,curry-on-green))))
   `(diredp-flag-mark ((t (:foreground ,curry-on-yellow))))
   `(diredp-flag-mark-line ((t (:foreground ,curry-on-orange))))
   `(diredp-ignored-file-name ((t (:foreground ,curry-on-red))))
   `(diredp-link-priv ((t (:foreground ,curry-on-yellow))))
   `(diredp-mode-line-flagged ((t (:foreground ,curry-on-yellow))))
   `(diredp-mode-line-marked ((t (:foreground ,curry-on-orange))))
   `(diredp-no-priv ((t (:foreground ,curry-on-fg))))
   `(diredp-number ((t (:foreground ,curry-on-green))))
   `(diredp-other-priv ((t (:foreground ,curry-on-yellow))))
   `(diredp-rare-priv ((t (:foreground ,curry-on-red))))
   `(diredp-read-priv ((t (:foreground ,curry-on-green))))
   `(diredp-symlink ((t (:foreground ,curry-on-yellow))))
   `(diredp-write-priv ((t (:foreground ,curry-on-magenta))))
;;;;; dired-async
   `(dired-async-failures ((t (:foreground ,curry-on-red :weight bold))))
   `(dired-async-message ((t (:foreground ,curry-on-yellow :weight bold))))
   `(dired-async-mode-message ((t (:foreground ,curry-on-yellow))))
;;;;; ediff
   `(ediff-current-diff-A ((t (:foreground ,curry-on-fg :background ,curry-on-red))))
   `(ediff-current-diff-Ancestor ((t (:foreground ,curry-on-fg :background ,curry-on-red))))
   `(ediff-current-diff-B ((t (:foreground ,curry-on-fg :background ,curry-on-green))))
   `(ediff-current-diff-C ((t (:foreground ,curry-on-fg :background ,curry-on-blue))))
   `(ediff-even-diff-A ((t (:background ,curry-on-bg+1))))
   `(ediff-even-diff-Ancestor ((t (:background ,curry-on-bg+1))))
   `(ediff-even-diff-B ((t (:background ,curry-on-bg+1))))
   `(ediff-even-diff-C ((t (:background ,curry-on-bg+1))))
   `(ediff-fine-diff-A ((t (:foreground ,curry-on-fg :background ,curry-on-red :weight bold))))
   `(ediff-fine-diff-Ancestor ((t (:foreground ,curry-on-fg :background ,curry-on-red weight bold))))
   `(ediff-fine-diff-B ((t (:foreground ,curry-on-fg :background ,curry-on-green :weight bold))))
   `(ediff-fine-diff-C ((t (:foreground ,curry-on-fg :background ,curry-on-blue :weight bold ))))
   `(ediff-odd-diff-A ((t (:background ,curry-on-bg))))
   `(ediff-odd-diff-Ancestor ((t (:background ,curry-on-bg))))
   `(ediff-odd-diff-B ((t (:background ,curry-on-bg))))
   `(ediff-odd-diff-C ((t (:background ,curry-on-bg))))
;;;;; egg
   `(egg-text-base ((t (:foreground ,curry-on-fg))))
   `(egg-help-header ((t (:foreground ,curry-on-yellow))))
   `(egg-help-header ((t (:foreground ,curry-on-green))))
   `(egg-branch ((t (:foreground ,curry-on-yellow))))
   `(egg-branch-mono ((t (:foreground ,curry-on-yellow))))
   `(egg-term ((t (:foreground ,curry-on-yellow))))
   `(egg-diff-add ((t (:foreground ,curry-on-green))))
   `(egg-diff-del ((t (:foreground ,curry-on-red))))
   `(egg-diff-file-header ((t (:foreground ,curry-on-yellow))))
   `(egg-section-title ((t (:foreground ,curry-on-yellow))))
   `(egg-stash-mono ((t (:foreground ,curry-on-green))))
;;;;; elfeed
   `(elfeed-log-error-level-face ((t (:foreground ,curry-on-red))))
   `(elfeed-log-info-level-face ((t (:foreground ,curry-on-blue))))
   `(elfeed-log-warn-level-face ((t (:foreground ,curry-on-yellow))))
   `(elfeed-search-date-face ((t (:foreground ,curry-on-yellow :underline t
                                              :weight bold))))
   `(elfeed-search-tag-face ((t (:foreground ,curry-on-green))))
   `(elfeed-search-feed-face ((t (:foreground ,curry-on-blue))))
;;;;; emacs-w3m
   `(w3m-anchor ((t (:foreground ,curry-on-yellow :underline t
                                 :weight bold))))
   `(w3m-arrived-anchor ((t (:foreground ,curry-on-yellow
                                         :underline t :weight normal))))
   `(w3m-form ((t (:foreground ,curry-on-red :underline t))))
   `(w3m-header-line-location-title ((t (:foreground ,curry-on-yellow
                                                     :underline t :weight bold))))
   '(w3m-history-current-url ((t (:inherit match))))
   `(w3m-lnum ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
   `(w3m-lnum-match ((t (:background ,curry-on-bg
                                     :foreground ,curry-on-orange
                                     :weight bold))))
   `(w3m-lnum-minibuffer-prompt ((t (:foreground ,curry-on-yellow))))
;;;;; erc
   `(erc-action-face ((t (:inherit erc-default-face))))
   `(erc-bold-face ((t (:weight bold))))
   `(erc-current-nick-face ((t (:foreground ,curry-on-blue :weight bold))))
   `(erc-dangerous-host-face ((t (:inherit font-lock-warning-face))))
   `(erc-default-face ((t (:foreground ,curry-on-fg))))
   `(erc-direct-msg-face ((t (:inherit erc-default-face))))
   `(erc-error-face ((t (:inherit font-lock-warning-face))))
   `(erc-fool-face ((t (:inherit erc-default-face))))
   `(erc-highlight-face ((t (:inherit hover-highlight))))
   `(erc-input-face ((t (:foreground ,curry-on-yellow))))
   `(erc-keyword-face ((t (:foreground ,curry-on-blue :weight bold))))
   `(erc-nick-default-face ((t (:foreground ,curry-on-yellow :weight bold))))
   `(erc-my-nick-face ((t (:foreground ,curry-on-red :weight bold))))
   `(erc-nick-msg-face ((t (:inherit erc-default-face))))
   `(erc-notice-face ((t (:foreground ,curry-on-green))))
   `(erc-pal-face ((t (:foreground ,curry-on-orange :weight bold))))
   `(erc-prompt-face ((t (:foreground ,curry-on-orange :background ,curry-on-bg :weight bold))))
   `(erc-timestamp-face ((t (:foreground ,curry-on-green))))
   `(erc-underline-face ((t (:underline t))))
;;;;; eros
   `(eros-result-overlay-face ((t (:background unspecified))))
;;;;; ert
   `(ert-test-result-expected ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
   `(ert-test-result-unexpected ((t (:foreground ,curry-on-red :background ,curry-on-bg))))
;;;;; eshell
   `(eshell-prompt ((t (:foreground ,curry-on-yellow :weight bold))))
   `(eshell-ls-archive ((t (:foreground ,curry-on-red :weight bold))))
   `(eshell-ls-backup ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-clutter ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-directory ((t (:foreground ,curry-on-blue :weight bold))))
   `(eshell-ls-executable ((t (:foreground ,curry-on-red :weight bold))))
   `(eshell-ls-unreadable ((t (:foreground ,curry-on-fg))))
   `(eshell-ls-missing ((t (:inherit font-lock-warning-face))))
   `(eshell-ls-product ((t (:inherit font-lock-doc-face))))
   `(eshell-ls-special ((t (:foreground ,curry-on-yellow :weight bold))))
   `(eshell-ls-symlink ((t (:foreground ,curry-on-blue :weight bold))))
;;;;; flx
   `(flx-highlight-face ((t (:foreground ,curry-on-green :weight bold))))
;;;;; flycheck
   `(flycheck-error
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-red) :inherit unspecified))
      (t (:foreground ,curry-on-red :weight bold :underline t))))
   `(flycheck-warning
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-yellow) :inherit unspecified))
      (t (:foreground ,curry-on-yellow :weight bold :underline t))))
   `(flycheck-info
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-blue) :inherit unspecified))
      (t (:foreground ,curry-on-blue :weight bold :underline t))))
   `(flycheck-fringe-error ((t (:foreground ,curry-on-red :weight bold))))
   `(flycheck-fringe-warning ((t (:foreground ,curry-on-yellow :weight bold))))
   `(flycheck-fringe-info ((t (:foreground ,curry-on-blue :weight bold))))
;;;;; flymake
   `(flymake-errline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-red)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,curry-on-red :weight bold :underline t))))
   `(flymake-warnline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-orange)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,curry-on-orange :weight bold :underline t))))
   `(flymake-infoline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-green)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,curry-on-green :weight bold :underline t))))
;;;;; flyspell
   `(flyspell-duplicate
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-orange) :inherit unspecified))
      (t (:foreground ,curry-on-orange :weight bold :underline t))))
   `(flyspell-incorrect
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-red) :inherit unspecified))
      (t (:foreground ,curry-on-red :weight bold :underline t))))
;;;;; full-ack
   `(ack-separator ((t (:foreground ,curry-on-fg))))
   `(ack-file ((t (:foreground ,curry-on-blue))))
   `(ack-line ((t (:foreground ,curry-on-yellow))))
   `(ack-match ((t (:foreground ,curry-on-orange :background ,curry-on-bg :weight bold))))
;;;;; git-commit
   `(git-commit-comment-action  ((,class (:foreground ,curry-on-green :weight bold))))
   `(git-commit-comment-branch  ((,class (:foreground ,curry-on-blue  :weight bold))))
   `(git-commit-comment-heading ((,class (:foreground ,curry-on-yellow  :weight bold))))
;;;;; git-gutter
   `(git-gutter:added ((t (:foreground ,curry-on-green :weight bold :inverse-video t))))
   `(git-gutter:deleted ((t (:foreground ,curry-on-red :weight bold :inverse-video t))))
   `(git-gutter:modified ((t (:foreground ,curry-on-magenta :weight bold :inverse-video t))))
   `(git-gutter:unchanged ((t (:foreground ,curry-on-fg :weight bold :inverse-video t))))
;;;;; git-gutter-fr
   `(git-gutter-fr:added ((t (:foreground ,curry-on-green  :weight bold))))
   `(git-gutter-fr:deleted ((t (:foreground ,curry-on-red :weight bold))))
   `(git-gutter-fr:modified ((t (:foreground ,curry-on-magenta :weight bold))))
;;;;; git-rebase
   `(git-rebase-hash ((t (:foreground, curry-on-orange))))
;;;;; gnus
   `(gnus-group-mail ((t (:weight bold :inherit gnus-group-mail-empty))))
   `(gnus-group-mail-empty ((t (:inherit gnus-group-news-empty))))
   `(gnus-group-mail ((t (:weight bold :inherit gnus-group-mail-empty))))
   `(gnus-group-mail-empty ((t (:inherit gnus-group-news-empty))))
   `(gnus-group-mail ((t (:weight bold :inherit gnus-group-mail-empty))))
   `(gnus-group-mail-empty ((t (:inherit gnus-group-news-empty))))
   `(gnus-group-mail ((t (:weight bold :inherit gnus-group-mail-empty))))
   `(gnus-group-mail-empty ((t (:inherit gnus-group-news-empty))))
   `(gnus-group-mail ((t (:weight bold :inherit gnus-group-mail-empty))))
   `(gnus-group-mail-empty ((t (:inherit gnus-group-news-empty))))
   `(gnus-group-mail-6 ((t (:weight bold :inherit gnus-group-mail-6-empty))))
   `(gnus-group-mail-6-empty ((t (:inherit gnus-group-news-6-empty))))
   `(gnus-group-mail-low ((t (:weight bold :inherit gnus-group-mail-low-empty))))
   `(gnus-group-mail-low-empty ((t (:inherit gnus-group-news-low-empty))))
   `(gnus-group-news ((t (:weight bold :inherit gnus-group-news-empty))))
   `(gnus-group-news ((t (:weight bold :inherit gnus-group-news-empty))))
   `(gnus-group-news ((t (:weight bold :inherit gnus-group-news-empty))))
   `(gnus-group-news ((t (:weight bold :inherit gnus-group-news-empty))))
   `(gnus-group-news ((t (:weight bold :inherit gnus-group-news-empty))))
   `(gnus-group-news-6 ((t (:weight bold :inherit gnus-group-news-6-empty))))
   `(gnus-group-news-low ((t (:weight bold :inherit gnus-group-news-low-empty))))
   `(gnus-header-content ((t (:inherit message-header-other))))
   `(gnus-header-from ((t (:inherit message-header-to))))
   `(gnus-header-name ((t (:inherit message-header-name))))
   `(gnus-header-newsgroups ((t (:inherit message-header-other))))
   `(gnus-header-subject ((t (:inherit message-header-subject))))
   `(gnus-server-opened ((t (:foreground ,curry-on-green :weight bold))))
   `(gnus-server-denied ((t (:foreground ,curry-on-red :weight bold))))
   `(gnus-server-closed ((t (:foreground ,curry-on-blue :slant italic))))
   `(gnus-server-offline ((t (:foreground ,curry-on-yellow :weight bold))))
   `(gnus-server-agent ((t (:foreground ,curry-on-blue :weight bold))))
   `(gnus-summary-cancelled ((t (:foreground ,curry-on-orange))))
   `(gnus-summary-high-ancient ((t (:foreground ,curry-on-blue))))
   `(gnus-summary-high-read ((t (:foreground ,curry-on-green :weight bold))))
   `(gnus-summary-high-ticked ((t (:foreground ,curry-on-orange :weight bold))))
   `(gnus-summary-high-unread ((t (:foreground ,curry-on-fg :weight bold))))
   `(gnus-summary-low-ancient ((t (:foreground ,curry-on-blue))))
   `(gnus-summary-low-read ((t (:foreground ,curry-on-green))))
   `(gnus-summary-low-ticked ((t (:foreground ,curry-on-orange :weight bold))))
   `(gnus-summary-low-unread ((t (:foreground ,curry-on-fg))))
   `(gnus-summary-normal-ancient ((t (:foreground ,curry-on-blue))))
   `(gnus-summary-normal-read ((t (:foreground ,curry-on-green))))
   `(gnus-summary-normal-ticked ((t (:foreground ,curry-on-orange :weight bold))))
   `(gnus-summary-normal-unread ((t (:foreground ,curry-on-fg))))
   `(gnus-summary-selected ((t (:foreground ,curry-on-yellow :weight bold))))
   `(gnus-cite ((t (:foreground ,curry-on-blue))))
   `(gnus-cite0 ((t (:foreground ,curry-on-yellow))))
   `(gnus-cite1 ((t (:foreground ,curry-on-yellow))))
   `(gnus-cite ((t (:foreground ,curry-on-blue))))
   `(gnus-cite ((t (:foreground ,curry-on-blue))))
   `(gnus-cite ((t (:foreground ,curry-on-green))))
   `(gnus-cite ((t (:foreground ,curry-on-green))))
   `(gnus-cite-6 ((t (:foreground ,curry-on-green))))
   `(gnus-cite-7 ((t (:foreground ,curry-on-red))))
   `(gnus-cite-8 ((t (:foreground ,curry-on-red))))
   `(gnus-cite-9 ((t (:foreground ,curry-on-red))))
   `(gnus-group-news-empty ((t (:foreground ,curry-on-yellow))))
   `(gnus-group-news-empty ((t (:foreground ,curry-on-green))))
   `(gnus-group-news-empty ((t (:foreground ,curry-on-green))))
   `(gnus-group-news-empty ((t (:foreground ,curry-on-blue))))
   `(gnus-group-news-empty ((t (:foreground ,curry-on-blue))))
   `(gnus-group-news-6-empty ((t (:foreground ,curry-on-bg))))
   `(gnus-group-news-low-empty ((t (:foreground ,curry-on-bg))))
   `(gnus-signature ((t (:foreground ,curry-on-yellow))))
   `(gnus-x ((t (:background ,curry-on-fg :foreground ,curry-on-bg))))
;;;;; guide-key
   `(guide-key/highlight-command-face ((t (:foreground ,curry-on-blue))))
   `(guide-key/key-face ((t (:foreground ,curry-on-green))))
   `(guide-key/prefix-command-face ((t (:foreground ,curry-on-green))))
;;;;; helm
   `(helm-header
     ((t (:foreground ,curry-on-green
                      :background ,curry-on-bg
                      :underline nil
                      :box nil))))
   `(helm-source-header
     ((t (:foreground ,curry-on-yellow
                      :background ,curry-on-bg
                      :underline nil
                      :weight bold
                      :box (:line-width -1  :style released-button)))))
   `(helm-selection ((t (:background ,curry-on-bg :foreground ,curry-on-gold :weight bold))))
   `(helm-selection-line ((t (:background ,curry-on-bg :foreground ,curry-on-gold :weight bold))))
   `(helm-visible-mark ((t (:foreground ,curry-on-bg :background ,curry-on-yellow))))
   `(helm-candidate-number ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
   `(helm-separator ((t (:foreground ,curry-on-red :background ,curry-on-bg))))
   `(helm-time-zone-current ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
   `(helm-time-zone-home ((t (:foreground ,curry-on-red :background ,curry-on-bg))))
   `(helm-bookmark-addressbook ((t (:foreground ,curry-on-orange :background ,curry-on-bg))))
   `(helm-bookmark-directory ((t (:foreground nil :background nil :inherit helm-ff-directory))))
   `(helm-bookmark-file ((t (:foreground nil :background nil :inherit helm-ff-file))))
   `(helm-bookmark-gnus ((t (:foreground ,curry-on-magenta :background ,curry-on-bg))))
   `(helm-bookmark-info ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
   `(helm-bookmark-man ((t (:foreground ,curry-on-yellow :background ,curry-on-bg))))
   `(helm-bookmark-w3m ((t (:foreground ,curry-on-magenta :background ,curry-on-bg))))
   `(helm-buffer-not-saved ((t (:foreground ,curry-on-red :background ,curry-on-bg))))
   `(helm-buffer-process ((t (:foreground ,curry-on-blue :background ,curry-on-bg))))
   `(helm-buffer-saved-out ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
   `(helm-buffer-size ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
   `(helm-ff-directory ((t (:foreground ,curry-on-blue :background ,curry-on-bg :weight bold))))
   `(helm-ff-file ((t (:foreground ,curry-on-fg :background ,curry-on-bg :weight normal))))
   `(helm-ff-executable ((t (:foreground ,curry-on-green :background ,curry-on-bg :weight normal))))
   `(helm-ff-invalid-symlink ((t (:foreground ,curry-on-red :background ,curry-on-bg :weight bold))))
   `(helm-ff-symlink ((t (:foreground ,curry-on-yellow :background ,curry-on-bg :weight bold))))
   `(helm-ff-prefix ((t (:foreground ,curry-on-bg :background ,curry-on-yellow :weight normal))))
   `(helm-grep-cmd-line ((t (:foreground ,curry-on-blue :background ,curry-on-bg))))
   `(helm-grep-file ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
   `(helm-grep-finish ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
   `(helm-grep-lineno ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
   `(helm-grep-match ((t (:foreground nil :background nil :inherit helm-match))))
   `(helm-grep-running ((t (:foreground ,curry-on-red :background ,curry-on-bg))))
   `(helm-match ((t (:foreground ,curry-on-orange :background ,curry-on-bg :weight bold))))
   `(helm-moccur-buffer ((t (:foreground ,curry-on-blue :background ,curry-on-bg))))
   `(helm-mu-contacts-address-face ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
   `(helm-mu-contacts-name-face ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
;;;;; helm-swoop
   `(helm-swoop-target-line-face ((t (:foreground ,curry-on-fg :background ,curry-on-bg+1))))
   `(helm-swoop-target-word-face ((t (:foreground ,curry-on-yellow :background ,curry-on-bg :weight bold))))
;;;;; hl-line-mode
   `(hl-line-face ((,class (:background ,curry-on-bg))
                   (t :weight bold)))
   `(hl-line ((,class (:background ,curry-on-bg)) ; old emacsen
              (t :weight bold)))
;;;;; hl-sexp
   `(hl-sexp-face ((,class (:background ,curry-on-bg+1))
                   (t :weight bold)))
;;;;; hydra
   `(hydra-face-red ((t (:foreground ,curry-on-red :background ,curry-on-bg))))
   `(hydra-face-amaranth ((t (:foreground ,curry-on-red :background ,curry-on-bg))))
   `(hydra-face-blue ((t (:foreground ,curry-on-blue :background ,curry-on-bg))))
   `(hydra-face-pink ((t (:foreground ,curry-on-magenta :background ,curry-on-bg))))
   `(hydra-face-teal ((t (:foreground ,curry-on-blue :background ,curry-on-bg))))
;;;;; irfc
   `(irfc-head-name-face ((t (:foreground ,curry-on-red :weight bold))))
   `(irfc-head-number-face ((t (:foreground ,curry-on-red :weight bold))))
   `(irfc-reference-face ((t (:foreground ,curry-on-blue :weight bold))))
   `(irfc-requirement-keyword-face ((t (:inherit font-lock-keyword-face))))
   `(irfc-rfc-link-face ((t (:inherit link))))
   `(irfc-rfc-number-face ((t (:foreground ,curry-on-blue :weight bold))))
   `(irfc-std-number-face ((t (:foreground ,curry-on-green :weight bold))))
   `(irfc-table-item-face ((t (:foreground ,curry-on-green))))
   `(irfc-title-face ((t (:foreground ,curry-on-yellow
                                      :underline t :weight bold))))
;;;;; ivy
   `(ivy-confirm-face ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
   `(ivy-match-required-face ((t (:foreground ,curry-on-red :background ,curry-on-bg))))
   `(ivy-remote ((t (:foreground ,curry-on-blue :background ,curry-on-bg))))
   `(ivy-subdir ((t (:foreground ,curry-on-yellow :background ,curry-on-bg))))
   `(ivy-current-match ((t (:foreground ,curry-on-yellow :weight bold :underline t))))
   `(ivy-minibuffer-match-face ((t (:background ,curry-on-bg+1))))
   `(ivy-minibuffer-match-face ((t (:background ,curry-on-green))))
   `(ivy-minibuffer-match-face ((t (:background ,curry-on-green))))
   `(ivy-minibuffer-match-face ((t (:background ,curry-on-green))))
;;;;; ido-mode
   `(ido-first-match ((t (:foreground ,curry-on-yellow :weight bold))))
   `(ido-only-match ((t (:foreground ,curry-on-orange :weight bold))))
   `(ido-subdir ((t (:foreground ,curry-on-yellow))))
   `(ido-indicator ((t (:foreground ,curry-on-yellow :background ,curry-on-red))))
;;;;; iedit-mode
   `(iedit-occurrence ((t (:background ,curry-on-bg :weight bold))))
;;;;; jabber-mode
   `(jabber-roster-user-away ((t (:foreground ,curry-on-green))))
   `(jabber-roster-user-online ((t (:foreground ,curry-on-blue))))
   `(jabber-roster-user-dnd ((t (:foreground ,curry-on-red))))
   `(jabber-roster-user-xa ((t (:foreground ,curry-on-magenta))))
   `(jabber-roster-user-chatty ((t (:foreground ,curry-on-orange))))
   `(jabber-roster-user-error ((t (:foreground ,curry-on-red))))
   `(jabber-rare-time-face ((t (:foreground ,curry-on-green))))
   `(jabber-chat-prompt-local ((t (:foreground ,curry-on-blue))))
   `(jabber-chat-prompt-foreign ((t (:foreground ,curry-on-red))))
   `(jabber-chat-prompt-system ((t (:foreground ,curry-on-green))))
   `(jabber-activity-face((t (:foreground ,curry-on-red))))
   `(jabber-activity-personal-face ((t (:foreground ,curry-on-blue))))
   `(jabber-title-small ((t (:height 1.1 :weight bold))))
   `(jabber-title-medium ((t (:height 1.2 :weight bold))))
   `(jabber-title-large ((t (:height 1.3 :weight bold))))
;;;;; js2-mode
   `(js2-warning ((t (:underline ,curry-on-orange))))
   `(js2-error ((t (:foreground ,curry-on-red :weight bold))))
   `(js2-jsdoc-tag ((t (:foreground ,curry-on-green))))
   `(js2-jsdoc-type ((t (:foreground ,curry-on-green))))
   `(js2-jsdoc-value ((t (:foreground ,curry-on-green))))
   `(js2-function-param ((t (:foreground, curry-on-orange))))
   `(js2-external-variable ((t (:foreground ,curry-on-orange))))
;;;;; additional js2 mode attributes for better syntax highlighting
   `(js2-instance-member ((t (:foreground ,curry-on-green))))
   `(js2-jsdoc-html-tag-delimiter ((t (:foreground ,curry-on-orange))))
   `(js2-jsdoc-html-tag-name ((t (:foreground ,curry-on-red))))
   `(js2-object-property ((t (:foreground ,curry-on-blue))))
   `(js2-magic-paren ((t (:foreground ,curry-on-blue))))
   `(js2-private-function-call ((t (:foreground ,curry-on-blue))))
   `(js2-function-call ((t (:foreground ,curry-on-blue))))
   `(js2-private-member ((t (:foreground ,curry-on-blue))))
   `(js2-keywords ((t (:foreground ,curry-on-magenta))))
;;;;; ledger-mode
   `(ledger-font-payee-uncleared-face ((t (:foreground ,curry-on-red :weight bold))))
   `(ledger-font-payee-cleared-face ((t (:foreground ,curry-on-fg :weight normal))))
   `(ledger-font-payee-pending-face ((t (:foreground ,curry-on-red :weight normal))))
   `(ledger-font-xact-highlight-face ((t (:background ,curry-on-bg+1))))
   `(ledger-font-auto-xact-face ((t (:foreground ,curry-on-yellow :weight normal))))
   `(ledger-font-periodic-xact-face ((t (:foreground ,curry-on-green :weight normal))))
   `(ledger-font-pending-face ((t (:foreground ,curry-on-orange weight: normal))))
   `(ledger-font-other-face ((t (:foreground ,curry-on-fg))))
   `(ledger-font-posting-date-face ((t (:foreground ,curry-on-orange :weight normal))))
   `(ledger-font-posting-account-face ((t (:foreground ,curry-on-blue))))
   `(ledger-font-posting-account-cleared-face ((t (:foreground ,curry-on-fg))))
   `(ledger-font-posting-account-pending-face ((t (:foreground ,curry-on-orange))))
   `(ledger-font-posting-amount-face ((t (:foreground ,curry-on-orange))))
   `(ledger-occur-narrowed-face ((t (:foreground ,curry-on-fg :invisible t))))
   `(ledger-occur-xact-face ((t (:background ,curry-on-bg+1))))
   `(ledger-font-comment-face ((t (:foreground ,curry-on-green))))
   `(ledger-font-reconciler-uncleared-face ((t (:foreground ,curry-on-red :weight bold))))
   `(ledger-font-reconciler-cleared-face ((t (:foreground ,curry-on-fg :weight normal))))
   `(ledger-font-reconciler-pending-face ((t (:foreground ,curry-on-orange :weight normal))))
   `(ledger-font-report-clickable-face ((t (:foreground ,curry-on-orange :weight normal))))
;;;;; linum-mode
   `(linum ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
;;;;; Line numbers in Emacs 26
   `(line-number ((t (:foreground ,curry-on-bg+3 :background ,curry-on-bg))))
   `(line-number-current-line ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
;;;;; lispy
   `(lispy-command-name-face ((t (:background ,curry-on-bg :inherit font-lock-function-name-face))))
   `(lispy-cursor-face ((t (:foreground ,curry-on-bg :background ,curry-on-fg))))
   `(lispy-face-hint ((t (:inherit highlight :foreground ,curry-on-yellow))))
;;;;; ruler-mode
   `(ruler-mode-column-number ((t (:inherit 'ruler-mode-default :foreground ,curry-on-fg))))
   `(ruler-mode-fill-column ((t (:inherit 'ruler-mode-default :foreground ,curry-on-yellow))))
   `(ruler-mode-goal-column ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-comment-column ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-tab-stop ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-current-column ((t (:foreground ,curry-on-yellow :box t))))
   `(ruler-mode-default ((t (:foreground ,curry-on-green :background ,curry-on-bg))))

;;;;; lui
   `(lui-time-stamp-face ((t (:foreground ,curry-on-blue))))
   `(lui-hilight-face ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
   `(lui-button-face ((t (:inherit hover-highlight))))
;;;;; macrostep
   `(macrostep-gensym
     ((t (:foreground ,curry-on-green :background ,curry-on-bg))))
   `(macrostep-gensym
     ((t (:foreground ,curry-on-red :background ,curry-on-bg))))
   `(macrostep-gensym
     ((t (:foreground ,curry-on-blue :background ,curry-on-bg))))
   `(macrostep-gensym
     ((t (:foreground ,curry-on-magenta :background ,curry-on-bg))))
   `(macrostep-gensym
     ((t (:foreground ,curry-on-yellow :background ,curry-on-bg))))
   `(macrostep-expansion-highlight-face
     ((t (:inherit highlight))))
   `(macrostep-macro-face
     ((t (:underline t))))
;;;;; magit
;;;;;; headings and diffs
   `(magit-section-highlight           ((t (:background ,curry-on-bg :foreground ,curry-on-fg))))
   `(magit-section-heading             ((t (:foreground ,curry-on-yellow :weight bold))))
   `(magit-section-heading-selection   ((t (:foreground ,curry-on-orange :weight bold))))
   `(magit-diff-file-heading           ((t (:background ,curry-on-bg :foreground ,curry-on-fg+1 :weight bold))))
   `(magit-diff-file-heading-highlight ((t (:background ,curry-on-bg  :weight bold))))
   `(magit-diff-file-heading-selection ((t (:background ,curry-on-bg
                                                        :foreground ,curry-on-gold :weight bold))))
   `(magit-diff-hunk-heading           ((t (:background ,curry-on-bg))))
   `(magit-diff-hunk-heading-highlight ((t (:background ,curry-on-bg :foreground ,curry-on-gold))))
   `(magit-diff-hunk-heading-selection ((t (:background ,curry-on-bg
                                                        :foreground ,curry-on-orange))))
   `(magit-diff-lines-heading          ((t (:background ,curry-on-red
                                                        :foreground ,curry-on-bg))))
   `(magit-diff-base      ((t (:background ,curry-on-bg :foreground ,curry-on-fg))))
   `(magit-diff-context   ((t (:background ,curry-on-bg :foreground ,curry-on-fg :weight bold))))
   `(magit-diff-context-highlight ((t (:background ,curry-on-bg :foreground ,curry-on-gold))))
   `(magit-diff-removed-highlight ((t (:background ,curry-on-bg :foreground ,curry-on-red))))
   `(magit-diff-removed  ((t (:background ,curry-on-bg :foreground ,curry-on-red))))
   `(magit-diff-added-highlight  ((t (:background ,curry-on-bg :foreground ,curry-on-green))))
   `(magit-diff-added  ((t (:background ,curry-on-bg :foreground ,curry-on-green))))
   `(magit-diffstat-added   ((t (:background ,curry-on-bg :foreground ,curry-on-green))))
   `(magit-diff-whitespace-warning ((t (:background ,curry-on-red :foreground ,curry-on-fg+1))))
   `(magit-diff-conflict-heading ((t (:background ,curry-on-red :foreground ,curry-on-fg+1))))
   `(magit-diffstat-removed ((t (:foreground ,curry-on-red))))
;;;;;; popup
   `(magit-popup-heading             ((t (:foreground ,curry-on-yellow  :weight bold))))
   `(magit-popup-key                 ((t (:foreground ,curry-on-green :weight bold))))
   `(magit-popup-argument            ((t (:foreground ,curry-on-green   :weight bold))))
   `(magit-popup-disabled-argument   ((t (:foreground ,curry-on-fg    :weight normal))))
   `(magit-popup-option-value        ((t (:foreground ,curry-on-blue  :weight bold))))
;;;;;; process
   `(magit-process-ok    ((t (:foreground ,curry-on-green  :weight bold))))
   `(magit-process-ng    ((t (:foreground ,curry-on-red    :weight bold))))
;;;;;; log
   `(magit-log-author    ((t (:foreground ,curry-on-orange))))
   `(magit-log-date      ((t (:foreground ,curry-on-fg))))
   `(magit-log-graph     ((t (:foreground ,curry-on-fg+1))))
;;;;;; sequence
   `(magit-sequence-pick ((t (:foreground ,curry-on-yellow))))
   `(magit-sequence-stop ((t (:foreground ,curry-on-green))))
   `(magit-sequence-part ((t (:foreground ,curry-on-yellow))))
   `(magit-sequence-head ((t (:foreground ,curry-on-blue))))
   `(magit-sequence-drop ((t (:foreground ,curry-on-red))))
   `(magit-sequence-done ((t (:foreground ,curry-on-fg))))
   `(magit-sequence-onto ((t (:foreground ,curry-on-fg))))
;;;;;; bisect
   `(magit-bisect-good ((t (:background ,curry-on-bg :foreground ,curry-on-green))))
   `(magit-bisect-skip ((t (:background ,curry-on-bg :foreground ,curry-on-yellow))))
   `(magit-bisect-bad  ((t (:background ,curry-on-bg :foreground ,curry-on-red))))
;;;;;; blame
   `(magit-blame-heading ((t (:background ,curry-on-bg :foreground ,curry-on-blue))))
   `(magit-blame-hash    ((t (:background ,curry-on-bg :foreground ,curry-on-orange))))
   `(magit-blame-name    ((t (:background ,curry-on-bg :foreground ,curry-on-orange))))
   `(magit-blame-date    ((t (:background ,curry-on-bg :foreground ,curry-on-orange))))
   `(magit-blame-summary ((t (:background ,curry-on-bg :foreground ,curry-on-blue
                                          :weight bold))))
;;;;;; references etc
   `(magit-dimmed         ((t (:background ,curry-on-bg :foreground ,curry-on-bg+3))))
   `(magit-hash           ((t (:background ,curry-on-bg :foreground ,curry-on-bg+3))))
   `(magit-tag            ((t (:background ,curry-on-bg :foreground ,curry-on-orange :weight bold))))
   `(magit-branch-remote  ((t (:background ,curry-on-bg :foreground ,curry-on-green  :weight bold))))
   `(magit-branch-local   ((t (:background ,curry-on-bg :foreground ,curry-on-blue   :weight bold))))
   `(magit-branch-current ((t (:background ,curry-on-bg :foreground ,curry-on-blue   :weight bold :box t))))
   `(magit-head           ((t (:background ,curry-on-bg :foreground ,curry-on-blue   :weight bold))))
   `(magit-refname        ((t (:background ,curry-on-bg :foreground ,curry-on-fg :weight bold))))
   `(magit-refname-stash  ((t (:background ,curry-on-bg :foreground ,curry-on-fg :weight bold))))
   `(magit-refname-wip    ((t (:background ,curry-on-bg :foreground ,curry-on-fg :weight bold))))
   `(magit-signature-good      ((t (:foreground ,curry-on-green))))
   `(magit-signature-bad       ((t (:foreground ,curry-on-red))))
   `(magit-signature-untrusted ((t (:foreground ,curry-on-yellow))))
   `(magit-cherry-unmatched    ((t (:foreground ,curry-on-blue))))
   `(magit-cherry-equivalent   ((t (:foreground ,curry-on-magenta))))
   `(magit-reflog-commit       ((t (:foreground ,curry-on-green))))
   `(magit-reflog-amend        ((t (:foreground ,curry-on-magenta))))
   `(magit-reflog-merge        ((t (:foreground ,curry-on-green))))
   `(magit-reflog-checkout     ((t (:foreground ,curry-on-blue))))
   `(magit-reflog-reset        ((t (:foreground ,curry-on-red))))
   `(magit-reflog-rebase       ((t (:foreground ,curry-on-magenta))))
   `(magit-reflog-cherry-pick  ((t (:foreground ,curry-on-green))))
   `(magit-reflog-remote       ((t (:foreground ,curry-on-blue))))
   `(magit-reflog-other        ((t (:foreground ,curry-on-blue))))
;;;;; message-mode
   `(message-cited-text ((t (:inherit font-lock-comment-face))))
   `(message-header-name ((t (:foreground ,curry-on-green))))
   `(message-header-other ((t (:foreground ,curry-on-green))))
   `(message-header-to ((t (:foreground ,curry-on-yellow :weight bold))))
   `(message-header-cc ((t (:foreground ,curry-on-yellow :weight bold))))
   `(message-header-newsgroups ((t (:foreground ,curry-on-yellow :weight bold))))
   `(message-header-subject ((t (:foreground ,curry-on-orange :weight bold))))
   `(message-header-xheader ((t (:foreground ,curry-on-green))))
   `(message-mml ((t (:foreground ,curry-on-yellow :weight bold))))
   `(message-separator ((t (:inherit font-lock-comment-face))))
;;;;; mew
   `(mew-face-header-subject ((t (:foreground ,curry-on-orange))))
   `(mew-face-header-from ((t (:foreground ,curry-on-yellow))))
   `(mew-face-header-date ((t (:foreground ,curry-on-green))))
   `(mew-face-header-to ((t (:foreground ,curry-on-red))))
   `(mew-face-header-key ((t (:foreground ,curry-on-green))))
   `(mew-face-header-private ((t (:foreground ,curry-on-green))))
   `(mew-face-header-important ((t (:foreground ,curry-on-blue))))
   `(mew-face-header-marginal ((t (:foreground ,curry-on-fg :weight bold))))
   `(mew-face-header-warning ((t (:foreground ,curry-on-red))))
   `(mew-face-header-xmew ((t (:foreground ,curry-on-green))))
   `(mew-face-header-xmew-bad ((t (:foreground ,curry-on-red))))
   `(mew-face-body-url ((t (:foreground ,curry-on-orange))))
   `(mew-face-body-comment ((t (:foreground ,curry-on-fg :slant italic))))
   `(mew-face-body-cite1 ((t (:foreground ,curry-on-green))))
   `(mew-face-body-cite2 ((t (:foreground ,curry-on-blue))))
   `(mew-face-body-cite3 ((t (:foreground ,curry-on-orange))))
   `(mew-face-body-cite4 ((t (:foreground ,curry-on-yellow))))
   `(mew-face-body-cite5 ((t (:foreground ,curry-on-red))))
   `(mew-face-mark-review ((t (:foreground ,curry-on-blue))))
   `(mew-face-mark-escape ((t (:foreground ,curry-on-green))))
   `(mew-face-mark-delete ((t (:foreground ,curry-on-red))))
   `(mew-face-mark-unlink ((t (:foreground ,curry-on-yellow))))
   `(mew-face-mark-refile ((t (:foreground ,curry-on-green))))
   `(mew-face-mark-unread ((t (:foreground ,curry-on-red))))
   `(mew-face-eof-message ((t (:foreground ,curry-on-green))))
   `(mew-face-eof-part ((t (:foreground ,curry-on-yellow))))
;;;;; mic-paren
   `(paren-face-match ((t (:foreground ,curry-on-blue :background ,curry-on-bg :weight bold))))
   `(paren-face-mismatch ((t (:foreground ,curry-on-bg :background ,curry-on-magenta :weight bold))))
   `(paren-face-no-match ((t (:foreground ,curry-on-bg :background ,curry-on-red :weight bold))))
;;;;; mingus
   `(mingus-directory-face ((t (:foreground ,curry-on-blue))))
   `(mingus-pausing-face ((t (:foreground ,curry-on-magenta))))
   `(mingus-playing-face ((t (:foreground ,curry-on-blue))))
   `(mingus-playlist-face ((t (:foreground ,curry-on-blue ))))
   `(mingus-mark-face ((t (:bold t :foreground ,curry-on-magenta))))
   `(mingus-song-file-face ((t (:foreground ,curry-on-yellow))))
   `(mingus-artist-face ((t (:foreground ,curry-on-blue))))
   `(mingus-album-face ((t (:underline t :foreground ,curry-on-red))))
   `(mingus-album-stale-face ((t (:foreground ,curry-on-red))))
   `(mingus-stopped-face ((t (:foreground ,curry-on-red))))
;;;;; nav
   `(nav-face-heading ((t (:foreground ,curry-on-yellow))))
   `(nav-face-button-num ((t (:foreground ,curry-on-blue))))
   `(nav-face-dir ((t (:foreground ,curry-on-green))))
   `(nav-face-hdir ((t (:foreground ,curry-on-red))))
   `(nav-face-file ((t (:foreground ,curry-on-fg))))
   `(nav-face-hfile ((t (:foreground ,curry-on-red))))
;;;;; mu4e
   `(mu4e-cited-face ((t (:foreground ,curry-on-blue    :slant italic))))
   `(mu4e-cited-face ((t (:foreground ,curry-on-green :slant italic))))
   `(mu4e-cited-face ((t (:foreground ,curry-on-blue  :slant italic))))
   `(mu4e-cited-face ((t (:foreground ,curry-on-green   :slant italic))))
   `(mu4e-cited-face ((t (:foreground ,curry-on-blue  :slant italic))))
   `(mu4e-cited-6-face ((t (:foreground ,curry-on-green :slant italic))))
   `(mu4e-cited-7-face ((t (:foreground ,curry-on-blue    :slant italic))))
   `(mu4e-replied-face ((t (:foreground ,curry-on-bg+3))))
   `(mu4e-trashed-face ((t (:foreground ,curry-on-bg+3 :strike-through t))))
;;;;; mumamo
   `(mumamo-background-chunk-major ((t (:background nil))))
   `(mumamo-background-chunk-submode1 ((t (:background ,curry-on-bg))))
   `(mumamo-background-chunk-submode2 ((t (:background ,curry-on-bg))))
   `(mumamo-background-chunk-submode3 ((t (:background ,curry-on-bg+3))))
   `(mumamo-background-chunk-submode4 ((t (:background ,curry-on-bg+1))))
;;;;; neotree
   `(neo-banner-face ((t (:foreground ,curry-on-blue :weight bold))))
   `(neo-header-face ((t (:foreground ,curry-on-fg))))
   `(neo-root-dir-face ((t (:foreground ,curry-on-blue :weight bold))))
   `(neo-dir-link-face ((t (:foreground ,curry-on-blue))))
   `(neo-file-link-face ((t (:foreground ,curry-on-fg))))
   `(neo-expand-btn-face ((t (:foreground ,curry-on-blue))))
   `(neo-vc-default-face ((t (:foreground ,curry-on-fg+1))))
   `(neo-vc-user-face ((t (:foreground ,curry-on-red :slant italic))))
   `(neo-vc-up-to-date-face ((t (:foreground ,curry-on-fg))))
   `(neo-vc-edited-face ((t (:foreground ,curry-on-magenta))))
   `(neo-vc-needs-merge-face ((t (:foreground ,curry-on-red))))
   `(neo-vc-unlocked-changes-face ((t (:foreground ,curry-on-red :background ,curry-on-blue))))
   `(neo-vc-added-face ((t (:foreground ,curry-on-green))))
   `(neo-vc-conflict-face ((t (:foreground ,curry-on-red))))
   `(neo-vc-missing-face ((t (:foreground ,curry-on-red))))
   `(neo-vc-ignored-face ((t (:foreground ,curry-on-fg))))
;;;;; org-mode
   `(org-agenda-date-today
     ((t (:background ,curry-on-bg :foreground ,curry-on-fg+1 :slant italic :weight bold))) t)
   `(org-agenda-clocking
     ((t (:background ,curry-on-bg :foreground ,curry-on-blue))) t)
   `(org-agenda-column-dateline
     ((t (:background ,curry-on-bg :foreground ,curry-on-yellow))) t)
   `(org-agenda-structure
     ((t (:inherit font-lock-comment-face))))
   `(org-agenda-dimmed-todo-face ((t (:background ,curry-on-red :foreground ,curry-on-bg))))
   `(org-archived ((t (:foreground ,curry-on-fg :weight bold))))
   `(org-checkbox ((t (:background ,curry-on-bg :foreground ,curry-on-fg+1
                                   :box (:line-width 1 :style released-button)))))
   `(org-date ((t (:foreground ,curry-on-blue :underline t))))
   `(org-deadline-announce ((t (:foreground ,curry-on-red))))
   `(org-formula ((t (:foreground ,curry-on-yellow))))
   `(org-headline-done ((t (:foreground ,curry-on-green))))
   `(org-hide ((t (:foreground ,curry-on-bg))))
   `(org-level-1 ((t (:weight bold :foreground ,curry-on-yellow))))
   `(org-level-2 ((t (:weight bold :foreground ,curry-on-blue))))
   `(org-level-3 ((t (:weight bold :foreground ,curry-on-orange))))
   `(org-level-4 ((t (:weight bold :foreground ,curry-on-blue))))
   `(org-level-5 ((t (:weight bold :foreground ,curry-on-green))))
   `(org-level-6 ((t (:weight bold :foreground ,curry-on-red))))
   `(org-level-7 ((t (:foreground ,curry-on-yellow))))
   `(org-level-8 ((t (:foreground ,curry-on-blue))))
   `(org-link ((t (:foreground ,curry-on-yellow :underline t))))
   `(org-ref-acronym-face ((t (:foreground ,curry-on-gold :underline t))))
   `(org-ref-cite-face ((t (:foreground ,curry-on-green :underline t))))
   `(org-ref-glossary-face ((t (:foreground ,curry-on-blue :underline t))))
   `(org-ref-label-face ((t (:foreground ,curry-on-magenta :underline t))))
   `(org-ref-ref-face ((t (:foreground ,curry-on-red :underline t))))
   `(org-verbatim ((,class (:weight bold :background ,curry-on-bg :foreground ,curry-on-blue))))
   `(org-quote ((,class (:weight bold :background ,curry-on-bg :foreground ,curry-on-blue))))
   `(org-code ((,class (:weight bold :background ,curry-on-bg :foreground ,curry-on-blue))))
   `(org-scheduled ((t (:foreground ,curry-on-green))))
   `(org-scheduled-previously ((t (:foreground ,curry-on-red))))
   `(org-scheduled-today ((t (:foreground ,curry-on-blue))))
   `(org-special-keyword ((t (:foreground ,curry-on-blue))))
   `(org-special-properties ((t (:foreground ,curry-on-blue))))
   `(org-sexp-date ((t (:foreground ,curry-on-blue :underline t))))
   `(org-meta-line ((t (:foreground ,curry-on-yellow))))
   ;; `(org-table ((t (:foreground ,curry-on-fg))))
   `(org-table ((t :background ,curry-on-bg :foreground ,curry-on-blue)))
   `(org-priority ((t (:background ,curry-on-bg :foreground ,curry-on-red :weight bold))))
   `(org-tag ((t (:background ,curry-on-bg :weight bold))))
   `(org-tag-group ((t (:background ,curry-on-bg :weight bold))))
   `(org-special-keyword ((t (:background ,curry-on-bg :weight bold))))
   `(org-time-grid ((t (:foreground ,curry-on-orange))))
   `(org-kbd ((t :background ,curry-on-gold :foreground ,curry-on-bg :weight bold)))
   `(org-done ((t :background ,curry-on-bg :foreground ,curry-on-green)))
   `(org-todo ((t :background ,curry-on-bg :foreground ,curry-on-red)))
   `(org-upcoming-deadline ((t (:inherit font-lock-keyword-face))))
   `(org-warning ((t (:weight bold :foreground ,curry-on-red :weight bold :underline nil))))
   `(org-column ((t (:background ,curry-on-bg))))
   `(org-column-title ((t (:background ,curry-on-bg :underline t :weight bold))))
   `(org-mode-line-clock ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
   `(org-mode-line-clock-overrun ((t (:foreground ,curry-on-bg :background ,curry-on-red))))
   `(org-ellipsis ((t (:foreground ,curry-on-yellow :underline t))))
   `(org-footnote ((t (:foreground ,curry-on-blue :underline t))))
   `(org-date ((t (:foreground ,curry-on-blue :underline t))))
   `(org-property-value ((t (:foreground ,curry-on-magenta :underline t))))
   `(org-document-title ((t (:background ,curry-on-bg :foreground ,curry-on-blue :height 1.4))))
   `(org-document-info ((t (:background ,curry-on-bg :foreground ,curry-on-blue :height 1.2))))
   `(org-document-info-keyword ((t (:background ,curry-on-bg :foreground ,curry-on-green :height 1.2))))
   `(org-habit-ready-face ((t :background ,curry-on-green)))
   `(org-habit-alert-face ((t :background ,curry-on-yellow :foreground ,curry-on-bg)))
   `(org-habit-clear-face ((t :background ,curry-on-blue)))
   `(org-habit-overdue-face ((t :background ,curry-on-red)))
   `(org-habit-clear-future-face ((t :background ,curry-on-blue)))
   `(org-habit-ready-future-face ((t :background ,curry-on-green)))
   `(org-habit-alert-future-face ((t :background ,curry-on-yellow :foreground ,curry-on-bg)))
   `(org-habit-overdue-future-face ((t :background ,curry-on-red)))
   `(org-block-begin-line ((t :background ,curry-on-bg :foreground ,curry-on-yellow)))
   `(org-block-end-line ((t :background ,curry-on-bg :foreground ,curry-on-yellow)))
   `(org-block ((t :background ,curry-on-bg :foreground ,curry-on-fg+1)))
;;;;; ein
   `(ein:cell-input-prompt ((t (:foreground ,curry-on-blue))))
   `(ein:cell-input-area ((t :background ,curry-on-bg)))
   `(ein:cell-heading ((t (:weight bold :foreground ,curry-on-yellow))))
   `(ein:cell-heading ((t (:weight bold :foreground ,curry-on-blue))))
   `(ein:cell-heading ((t (:weight bold :foreground ,curry-on-orange))))
   `(ein:cell-heading ((t (:weight bold :foreground ,curry-on-blue))))
   `(ein:cell-heading ((t (:weight bold :foreground ,curry-on-green))))
   `(ein:cell-heading-6 ((t (:weight bold :foreground ,curry-on-red))))
   `(ein:cell-output-stderr ((t (:weight bold :foreground ,curry-on-red :weight bold :underline nil))))
   `(ein:cell-output-prompt ((t (:foreground ,curry-on-green))))
;;;;; outline
   `(outline ((t (:foreground ,curry-on-orange))))
   `(outline ((t (:foreground ,curry-on-green))))
   `(outline ((t (:foreground ,curry-on-blue))))
   `(outline ((t (:foreground ,curry-on-yellow))))
   `(outline ((t (:foreground ,curry-on-blue))))
   `(outline-6 ((t (:foreground ,curry-on-green))))
   `(outline-7 ((t (:foreground ,curry-on-red))))
   `(outline-8 ((t (:foreground ,curry-on-blue))))
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
   `(persp-selected-face ((t (:foreground ,curry-on-yellow :inherit mode-line))))
;;;;;
   `(powerline-active1 ((t (:background ,curry-on-bg :inherit mode-line))))
   `(powerline-active2 ((t (:background ,curry-on-bg :inherit mode-line))))
   `(powerline-inactive1 ((t (:background ,curry-on-bg+1 :inherit mode-line-inactive))))
   `(powerline-inactive2 ((t (:background ,curry-on-bg+3 :inherit mode-line-inactive))))
;;;;; proofgeneral
   `(proof-active-area-face ((t (:underline t))))
   `(proof-boring-face ((t (:foreground ,curry-on-fg :background ,curry-on-bg))))
   `(proof-command-mouse-highlight-face ((t (:inherit proof-mouse-highlight-face))))
   `(proof-debug-message-face ((t (:inherit proof-boring-face))))
   `(proof-declaration-name-face ((t (:inherit font-lock-keyword-face :foreground nil))))
   `(proof-eager-annotation-face ((t (:foreground ,curry-on-bg :background ,curry-on-orange))))
   `(proof-error-face ((t (:foreground ,curry-on-fg :background ,curry-on-red))))
   `(proof-highlight-dependency-face ((t (:foreground ,curry-on-bg :background ,curry-on-yellow))))
   `(proof-highlight-dependent-face ((t (:foreground ,curry-on-bg :background ,curry-on-orange))))
   `(proof-locked-face ((t (:background ,curry-on-blue))))
   `(proof-mouse-highlight-face ((t (:foreground ,curry-on-bg :background ,curry-on-orange))))
   `(proof-queue-face ((t (:background ,curry-on-red))))
   `(proof-region-mouse-highlight-face ((t (:inherit proof-mouse-highlight-face))))
   `(proof-script-highlight-error-face ((t (:background ,curry-on-red))))
   `(proof-tacticals-name-face ((t (:inherit font-lock-constant-face :foreground nil :background ,curry-on-bg))))
   `(proof-tactics-name-face ((t (:inherit font-lock-constant-face :foreground nil :background ,curry-on-bg))))
   `(proof-warning-face ((t (:foreground ,curry-on-bg :background ,curry-on-yellow))))
;;;;; racket-mode
   `(racket-keyword-argument-face ((t (:inherit font-lock-constant-face))))
   `(racket-selfeval-face ((t (:inherit font-lock-type-face))))
;;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-face ((t (:foreground ,curry-on-fg))))
   `(rainbow-delimiters-depth-face ((t (:foreground ,curry-on-green))))
   `(rainbow-delimiters-depth-face ((t (:foreground ,curry-on-yellow))))
   `(rainbow-delimiters-depth-face ((t (:foreground ,curry-on-blue))))
   `(rainbow-delimiters-depth-face ((t (:foreground ,curry-on-green))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,curry-on-blue))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,curry-on-yellow))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground ,curry-on-green))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground ,curry-on-blue))))
   `(rainbow-delimiters-depth0-face ((t (:foreground ,curry-on-orange))))
   `(rainbow-delimiters-depth1-face ((t (:foreground ,curry-on-green))))
   `(rainbow-delimiters-depth2-face ((t (:foreground ,curry-on-blue))))
;;;;; rcirc
   `(rcirc-my-nick ((t (:foreground ,curry-on-blue))))
   `(rcirc-other-nick ((t (:foreground ,curry-on-orange))))
   `(rcirc-bright-nick ((t (:foreground ,curry-on-blue))))
   `(rcirc-dim-nick ((t (:foreground ,curry-on-blue))))
   `(rcirc-server ((t (:foreground ,curry-on-green))))
   `(rcirc-server-prefix ((t (:foreground ,curry-on-green))))
   `(rcirc-timestamp ((t (:foreground ,curry-on-green))))
   `(rcirc-nick-in-message ((t (:foreground ,curry-on-yellow))))
   `(rcirc-nick-in-message-full-line ((t (:weight bold))))
   `(rcirc-prompt ((t (:foreground ,curry-on-yellow :weight bold))))
   `(rcirc-track-nick ((t (:inverse-video t))))
   `(rcirc-track-keyword ((t (:weight bold))))
   `(rcirc-url ((t (:weight bold))))
   `(rcirc-keyword ((t (:foreground ,curry-on-yellow :weight bold))))
;;;;; re-builder
   `(reb-match-0 ((t (:foreground ,curry-on-bg :background ,curry-on-magenta))))
   `(reb-match ((t (:foreground ,curry-on-bg :background ,curry-on-blue))))
   `(reb-match ((t (:foreground ,curry-on-bg :background ,curry-on-orange))))
   `(reb-match ((t (:foreground ,curry-on-bg :background ,curry-on-red))))
;;;;; regex-tool
   `(regex-tool-matched-face ((t (:background ,curry-on-blue :weight bold))))
;;;;; rpm-mode
   `(rpm-spec-dir-face ((t (:foreground ,curry-on-green))))
   `(rpm-spec-doc-face ((t (:foreground ,curry-on-green))))
   `(rpm-spec-ghost-face ((t (:foreground ,curry-on-red))))
   `(rpm-spec-macro-face ((t (:foreground ,curry-on-yellow))))
   `(rpm-spec-obsolete-tag-face ((t (:foreground ,curry-on-red))))
   `(rpm-spec-package-face ((t (:foreground ,curry-on-red))))
   `(rpm-spec-section-face ((t (:foreground ,curry-on-yellow))))
   `(rpm-spec-tag-face ((t (:foreground ,curry-on-blue))))
   `(rpm-spec-var-face ((t (:foreground ,curry-on-red))))
;;;;; rst-mode
   `(rst-level-face ((t (:foreground ,curry-on-orange))))
   `(rst-level-face ((t (:foreground ,curry-on-green))))
   `(rst-level-face ((t (:foreground ,curry-on-blue))))
   `(rst-level-face ((t (:foreground ,curry-on-yellow))))
   `(rst-level-face ((t (:foreground ,curry-on-blue))))
   `(rst-level-6-face ((t (:foreground ,curry-on-green))))
;;;;; sh-mode
   `(sh-heredoc     ((t (:foreground ,curry-on-yellow :weight bold))))
   `(sh-quoted-exec ((t (:foreground ,curry-on-red))))
;;;;; show-paren
   `(show-paren-mismatch ((t (:foreground ,curry-on-red :background ,curry-on-bg+3 :weight bold))))
   `(show-paren-match ((t (:background ,curry-on-bg+3 :weight bold))))
;;;;; smart-mode-line
   ;; use (setq sml/theme nil) to enable Curry-On for sml
   `(sml/global ((,class (:foreground ,curry-on-fg :weight bold))))
   `(sml/modes ((,class (:foreground ,curry-on-yellow :weight bold))))
   `(sml/minor-modes ((,class (:foreground ,curry-on-fg :weight bold))))
   `(sml/filename ((,class (:foreground ,curry-on-yellow :weight bold))))
   `(sml/line-number ((,class (:foreground ,curry-on-blue :weight bold))))
   `(sml/col-number ((,class (:foreground ,curry-on-blue :weight bold))))
   `(sml/position-percentage ((,class (:foreground ,curry-on-blue :weight bold))))
   `(sml/prefix ((,class (:foreground ,curry-on-orange))))
   `(sml/git ((,class (:foreground ,curry-on-green))))
   `(sml/process ((,class (:weight bold))))
   `(sml/sudo ((,class  (:foreground ,curry-on-orange :weight bold))))
   `(sml/read-only ((,class (:foreground ,curry-on-red))))
   `(sml/outside-modified ((,class (:foreground ,curry-on-orange))))
   `(sml/modified ((,class (:foreground ,curry-on-red))))
   `(sml/vc-edited ((,class (:foreground ,curry-on-green))))
   `(sml/charging ((,class (:foreground ,curry-on-green))))
   `(sml/discharging ((,class (:foreground ,curry-on-red))))
;;;;; smartparens
   `(sp-show-pair-mismatch-face ((t (:foreground ,curry-on-red :background ,curry-on-bg+3 :weight bold))))
   `(sp-show-pair-match-face ((t (:background ,curry-on-bg+3 :weight bold))))
;;;;; sml-mode-line
   '(sml-modeline-end-face ((t :inherit default :width condensed)))
;;;;; SLIME
   `(slime-repl-output-face ((t (:foreground ,curry-on-red))))
   `(slime-repl-inputed-output-face ((t (:foreground ,curry-on-green))))
   `(slime-error-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-red)))
      (t
       (:underline ,curry-on-red))))
   `(slime-warning-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-orange)))
      (t
       (:underline ,curry-on-orange))))
   `(slime-style-warning-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-yellow)))
      (t
       (:underline ,curry-on-yellow))))
   `(slime-note-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,curry-on-green)))
      (t
       (:underline ,curry-on-green))))
   `(slime-highlight-face ((t (:inherit highlight))))
;;;;; speedbar
   `(speedbar-button-face ((t (:foreground ,curry-on-green))))
   `(speedbar-directory-face ((t (:foreground ,curry-on-blue))))
   `(speedbar-file-face ((t (:foreground ,curry-on-fg))))
   `(speedbar-highlight-face ((t (:foreground ,curry-on-bg :background ,curry-on-green))))
   `(speedbar-selected-face ((t (:foreground ,curry-on-red))))
   `(speedbar-separator-face ((t (:foreground ,curry-on-bg :background ,curry-on-blue))))
   `(speedbar-tag-face ((t (:foreground ,curry-on-yellow))))
;;;;; tabbar
   `(tabbar-button ((t (:foreground ,curry-on-fg
                                    :background ,curry-on-bg))))
   `(tabbar-selected ((t (:foreground ,curry-on-fg
                                      :background ,curry-on-bg
                                      :box (:line-width -1  :style pressed-button)))))
   `(tabbar-unselected ((t (:foreground ,curry-on-fg
                                        :background ,curry-on-bg+1
                                        :box (:line-width -1  :style released-button)))))
;;;;; term
   `(term-color-black ((t (:foreground ,curry-on-bg
                                       :background ,curry-on-bg))))
   `(term-color-red ((t (:foreground ,curry-on-red
                                     :background ,curry-on-red))))
   `(term-color-green ((t (:foreground ,curry-on-green
                                       :background ,curry-on-green))))
   `(term-color-yellow ((t (:foreground ,curry-on-orange
                                        :background ,curry-on-yellow))))
   `(term-color-blue ((t (:foreground ,curry-on-blue
                                      :background ,curry-on-blue))))
   `(term-color-magenta ((t (:foreground ,curry-on-magenta
                                         :background ,curry-on-red))))
   `(term-color-blue ((t (:foreground ,curry-on-blue
                                      :background ,curry-on-blue))))
   `(term-color-white ((t (:foreground ,curry-on-fg
                                       :background ,curry-on-fg))))
   '(term-default-fg-color ((t (:inherit term-color-white))))
   '(term-default-bg-color ((t (:inherit term-color-black))))
;;;;; undo-tree
   `(undo-tree-visualizer-active-branch-face ((t (:foreground ,curry-on-fg+1 :weight bold))))
   `(undo-tree-visualizer-current-face ((t (:foreground ,curry-on-red :weight bold))))
   `(undo-tree-visualizer-default-face ((t (:foreground ,curry-on-fg))))
   `(undo-tree-visualizer-register-face ((t (:foreground ,curry-on-yellow))))
   `(undo-tree-visualizer-unmodified-face ((t (:foreground ,curry-on-blue))))
;;;;; visual-regexp
   `(vr/group-0 ((t (:foreground ,curry-on-bg :background ,curry-on-green :weight bold))))
   `(vr/group ((t (:foreground ,curry-on-bg :background ,curry-on-orange :weight bold))))
   `(vr/group ((t (:foreground ,curry-on-bg :background ,curry-on-blue :weight bold))))
   `(vr/match-0 ((t (:inherit isearch))))
   `(vr/match ((t (:foreground ,curry-on-yellow :background ,curry-on-bg :weight bold))))
   `(vr/match-separator-face ((t (:foreground ,curry-on-red :weight bold))))
;;;;; volatile-highlights
   `(vhl/default-face ((t (:background ,curry-on-bg))))
;;;;; web-mode
   `(web-mode-builtin-face ((t (:inherit ,font-lock-builtin-face))))
   `(web-mode-comment-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-constant-face ((t (:inherit ,font-lock-constant-face))))
   `(web-mode-css-at-rule-face ((t (:foreground ,curry-on-orange ))))
   `(web-mode-css-prop-face ((t (:foreground ,curry-on-orange))))
   `(web-mode-css-pseudo-class-face ((t (:foreground ,curry-on-green :weight bold))))
   `(web-mode-css-rule-face ((t (:foreground ,curry-on-blue))))
   `(web-mode-doctype-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-folded-face ((t (:underline t))))
   `(web-mode-function-name-face ((t (:foreground ,curry-on-blue))))
   `(web-mode-html-attr-name-face ((t (:foreground ,curry-on-orange))))
   `(web-mode-html-attr-value-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-html-tag-face ((t (:foreground ,curry-on-blue))))
   `(web-mode-keyword-face ((t (:inherit ,font-lock-keyword-face))))
   `(web-mode-preprocessor-face ((t (:inherit ,font-lock-preprocessor-face))))
   `(web-mode-string-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-type-face ((t (:inherit ,font-lock-type-face))))
   `(web-mode-variable-name-face ((t (:inherit ,font-lock-variable-name-face))))
   `(web-mode-server-background-face ((t (:background ,curry-on-bg))))
   `(web-mode-server-comment-face ((t (:inherit web-mode-comment-face))))
   `(web-mode-server-string-face ((t (:inherit web-mode-string-face))))
   `(web-mode-symbol-face ((t (:inherit font-lock-constant-face))))
   `(web-mode-warning-face ((t (:inherit font-lock-warning-face))))
   `(web-mode-whitespaces-face ((t (:background ,curry-on-red))))
;;;;; whitespace-mode
   `(whitespace-space ((t (:background ,curry-on-bg+1 :foreground ,curry-on-bg+1))))
   `(whitespace-hspace ((t (:background ,curry-on-bg+1 :foreground ,curry-on-bg+1))))
   `(whitespace-tab ((t (:background ,curry-on-red))))
   `(whitespace-newline ((t (:foreground ,curry-on-bg+1))))
   `(whitespace-trailing ((t (:background ,curry-on-red))))
   `(whitespace-line ((t (:background ,curry-on-bg :foreground ,curry-on-magenta))))
   `(whitespace-space-before-tab ((t (:background ,curry-on-orange :foreground ,curry-on-orange))))
   `(whitespace-indentation ((t (:background ,curry-on-yellow :foreground ,curry-on-red))))
   `(whitespace-empty ((t (:background ,curry-on-yellow))))
   `(whitespace-space-after-tab ((t (:background ,curry-on-yellow :foreground ,curry-on-red))))
;;;;; wanderlust
   `(wl-highlight-folder-few-face ((t (:foreground ,curry-on-red))))
   `(wl-highlight-folder-many-face ((t (:foreground ,curry-on-red))))
   `(wl-highlight-folder-path-face ((t (:foreground ,curry-on-orange))))
   `(wl-highlight-folder-unread-face ((t (:foreground ,curry-on-blue))))
   `(wl-highlight-folder-zero-face ((t (:foreground ,curry-on-fg))))
   `(wl-highlight-folder-unknown-face ((t (:foreground ,curry-on-blue))))
   `(wl-highlight-message-citation-header ((t (:foreground ,curry-on-red))))
   `(wl-highlight-message-cited-text ((t (:foreground ,curry-on-red))))
   `(wl-highlight-message-cited-text ((t (:foreground ,curry-on-green))))
   `(wl-highlight-message-cited-text ((t (:foreground ,curry-on-blue))))
   `(wl-highlight-message-cited-text ((t (:foreground ,curry-on-blue))))
   `(wl-highlight-message-header-contents-face ((t (:foreground ,curry-on-green))))
   `(wl-highlight-message-headers-face ((t (:foreground ,curry-on-red))))
   `(wl-highlight-message-important-header-contents ((t (:foreground ,curry-on-green))))
   `(wl-highlight-message-header-contents ((t (:foreground ,curry-on-green))))
   `(wl-highlight-message-important-header-contents2 ((t (:foreground ,curry-on-green))))
   `(wl-highlight-message-signature ((t (:foreground ,curry-on-green))))
   `(wl-highlight-message-unimportant-header-contents ((t (:foreground ,curry-on-fg))))
   `(wl-highlight-summary-answered-face ((t (:foreground ,curry-on-blue))))
   `(wl-highlight-summary-disposed-face ((t (:foreground ,curry-on-fg
                                                         :slant italic))))
   `(wl-highlight-summary-new-face ((t (:foreground ,curry-on-blue))))
   `(wl-highlight-summary-normal-face ((t (:foreground ,curry-on-fg))))
   `(wl-highlight-summary-thread-top-face ((t (:foreground ,curry-on-yellow))))
   `(wl-highlight-thread-indent-face ((t (:foreground ,curry-on-magenta))))
   `(wl-highlight-summary-refiled-face ((t (:foreground ,curry-on-fg))))
   `(wl-highlight-summary-displaying-face ((t (:underline t :weight bold))))
;;;;; which-func-mode
   `(which-func ((t (:foreground ,curry-on-green))))
;;;;; xcscope
   `(cscope-file-face ((t (:foreground ,curry-on-yellow :weight bold))))
   `(cscope-function-face ((t (:foreground ,curry-on-blue :weight bold))))
   `(cscope-line-number-face ((t (:foreground ,curry-on-red :weight bold))))
   `(cscope-mouse-face ((t (:foreground ,curry-on-bg :background ,curry-on-blue))))
   `(cscope-separator-face ((t (:foreground ,curry-on-red :weight bold
                                            :underline t :overline t))))
;;;;; yascroll
   `(yascroll:thumb-text-area ((t (:background ,curry-on-bg))))
   `(yascroll:thumb-fringe ((t (:background ,curry-on-bg :foreground ,curry-on-bg))))))

;;; Theme Variables
(curry-on-theme-with-color-variables
  (custom-theme-set-variables
   'curry-on
;;;;; ansi-color
   `(ansi-color-names-vector [,curry-on-bg ,curry-on-red ,curry-on-green ,curry-on-yellow
                                          ,curry-on-blue ,curry-on-magenta ,curry-on-blue ,curry-on-fg])
;;;;; fill-column-indicator
   `(fci-rule-color ,curry-on-bg)
;;;;; nrepl-client
   `(nrepl-message-colors
     '(,curry-on-red ,curry-on-orange ,curry-on-yellow ,curry-on-green ,curry-on-green
                    ,curry-on-blue ,curry-on-blue ,curry-on-magenta))
;;;;; pdf-tools
   `(pdf-view-midnight-colors '(,curry-on-fg . ,curry-on-bg))
;;;;; vc-annotate
   `(vc-annotate-color-map
     '(( 20. . ,curry-on-red)
       ( 40. . ,curry-on-red)
       ( 60. . ,curry-on-orange)
       ( 80. . ,curry-on-yellow)
       (100. . ,curry-on-yellow)
       (120. . ,curry-on-yellow)
       (140. . ,curry-on-green)
       (160. . ,curry-on-green)
       (180. . ,curry-on-green)
       (200. . ,curry-on-green)
       (220. . ,curry-on-green)
       (240. . ,curry-on-green)
       (260. . ,curry-on-blue)
       (280. . ,curry-on-blue)
       (300. . ,curry-on-blue)
       (320. . ,curry-on-blue)
       (340. . ,curry-on-blue)
       (360. . ,curry-on-magenta)))
   `(vc-annotate-very-old-color ,curry-on-magenta)
   `(vc-annotate-background ,curry-on-bg)))

;;; autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide 'curry-on-theme)
(provide-theme 'curry-on)

;; Local Variables:
;; no-byte-compile: t
;; indent-tabs-mode: nil
;; End:
;;; curry-on-theme.el ends here
