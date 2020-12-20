;;; sunburn-theme.el --- A low contrast color theme

;; Copyright © 2017 Martín Varela
;; Copyright (C) 2011-2016 Bozhidar Batsov (zenburn-theme.el)

;; Author: Martín Varela (martin@varela.fi)
;; URL: http://github.com/mvarela/Sunburn-Theme
;; Package-Version: 20201216.1539
;; Package-Commit: 6b5c14c76dcdfdb099102ef7a388b2f0c6f1951d
;; Version: 1.0
;; Package-Requires: ((emacs "24"))

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

;; A port of the popular Vim theme Zenburn for Emacs 24, built on top
;; of the new built-in theme support in Emacs 24.

;;; Credits:

;; This code is based off Bozhidar Batsov's port of the Zenburn theme

;;; Code:

(deftheme sunburn "The Sunburn color theme")

;;; Color Palette

(defvar sunburn-default-colors-alist
  '(("sunburn-fg+1"     . "#f1f1f1")
    ("sunburn-fg"       . "#dedded")
    ("sunburn-fg-1"     . "#aeadbd")
    ("sunburn-bg-2"     . "#383339")
    ("sunburn-bg-1"     . "#433844")
    ("sunburn-bg-05"    . "#4A4159")
    ("sunburn-bg"       . "#484349")
    ("sunburn-bg+05"    . "#373664")
    ("sunburn-bg+1"     . "#686369")
    ("sunburn-bg+2"     . "#787379")
    ("sunburn-bg+3"     . "#888389")
    ("sunburn-red+1"    . "#DCA3A3")
    ("sunburn-red"      . "#CC9393")
    ("sunburn-red-1"    . "#BC8383")
    ("sunburn-red-2"    . "#AC7373")
    ("sunburn-red-3"    . "#9C6363")
    ("sunburn-red-4"    . "#8C5353")
    ("sunburn-orange"   . "#DFAF8F")
    ("sunburn-yellow"   . "#F0DFAF")
    ("sunburn-yellow-1" . "#E0CF9F")
    ("sunburn-yellow-2" . "#D0BF8F")
    ("sunburn-gold"     . "#eead0e")
    ("sunburn-green-1"  . "#5F7F5F")
    ("sunburn-green"    . "#7F9F7F")
    ("sunburn-green+1"  . "#8FB28F")
    ("sunburn-green+2"  . "#9FC59F")
    ("sunburn-green+3"  . "#AFD8AF")
    ("sunburn-green+4"  . "#BFEBBF")
    ("sunburn-cyan"     . "#a7a6d4")
    ("sunburn-blue+1"   . "#9796c4")
    ("sunburn-blue"     . "#8786b4")
    ("sunburn-blue-1"   . "#777694")
    ("sunburn-blue-2"   . "#676694")
    ("sunburn-blue-3"   . "#575684")
    ("sunburn-blue-4"   . "#474674")
    ("sunburn-blue-5"   . "#373664")
    ("sunburn-magenta"  . "#b48ead"))
  "List of Sunburn colors.
Each element has the form (NAME . HEX).

`+N' suffixes indicate a color is lighter.
`-N' suffixes indicate a color is darker.")

(defvar sunburn-override-colors-alist
  '()
  "Place to override default theme colors.

You can override a subset of the theme's default colors by
defining them in this alist before loading the theme.")

(defvar sunburn-colors-alist
  (append sunburn-default-colors-alist sunburn-override-colors-alist))

(defmacro sunburn-with-color-variables (&rest body)
  "`let' bind all colors defined in `sunburn-colors-alist' around BODY.
Also bind `class' to ((class color) (min-colors 89))."
  (declare (indent 0))
  `(let ((class '((class color) (min-colors 89)))
         ,@(mapcar (lambda (cons)
                     (list (intern (car cons)) (cdr cons)))
                   sunburn-colors-alist))
     ,@body))

;;; Theme Faces
(sunburn-with-color-variables
  (custom-theme-set-faces
   'sunburn
;;;; Built-in
;;;;; basic coloring
   `(button ((t (:foreground ,sunburn-yellow-2 :underline t))))
   `(widget-button ((t (:foreground ,sunburn-yellow-2 :underline t))))
   `(link ((t (:foreground ,sunburn-yellow :underline t :weight bold))))
   `(link-visited ((t (:foreground ,sunburn-yellow-2 :underline t :weight normal))))
   `(default ((t (:foreground ,sunburn-fg :background ,sunburn-bg))))
   `(cursor ((t (:foreground ,sunburn-fg :background ,sunburn-fg+1))))
   `(escape-glyph ((t (:foreground ,sunburn-yellow :weight bold))))
   `(fringe ((t (:foreground ,sunburn-fg :background ,sunburn-bg+1))))
   `(header-line ((t (:foreground ,sunburn-yellow
                                  :background ,sunburn-bg-1
                                  :box (:line-width -1 :style released-button)))))
   `(highlight ((t (:background ,sunburn-bg-05))))
   `(success ((t (:foreground ,sunburn-green :weight bold))))
   `(warning ((t (:foreground ,sunburn-orange :weight bold))))
   `(tooltip ((t (:foreground ,sunburn-fg :background ,sunburn-bg+1))))


   ;; Spaceline colors

   `(spaceline-evil-insert ((t (:foreground ,sunburn-green :weight bold))))
;;;;; compilation
   `(compilation-column-face ((t (:foreground ,sunburn-yellow))))
   `(compilation-enter-directory-face ((t (:foreground ,sunburn-green))))
   `(compilation-error-face ((t (:foreground ,sunburn-red-1 :weight bold :underline t))))
   `(compilation-face ((t (:foreground ,sunburn-fg))))
   `(compilation-info-face ((t (:foreground ,sunburn-blue))))
   `(compilation-info ((t (:foreground ,sunburn-green+4 :underline t))))
   `(compilation-leave-directory-face ((t (:foreground ,sunburn-green))))
   `(compilation-line-face ((t (:foreground ,sunburn-yellow))))
   `(compilation-line-number ((t (:foreground ,sunburn-yellow))))
   `(compilation-message-face ((t (:foreground ,sunburn-blue))))
   `(compilation-warning-face ((t (:foreground ,sunburn-orange :weight bold :underline t))))
   `(compilation-mode-line-exit ((t (:foreground ,sunburn-green+2 :weight bold))))
   `(compilation-mode-line-fail ((t (:foreground ,sunburn-red :weight bold))))
   `(compilation-mode-line-run ((t (:foreground ,sunburn-yellow :weight bold))))
;;;;; completions
   `(completions-annotations ((t (:foreground ,sunburn-fg-1))))
;;;;; grep
   `(grep-context-face ((t (:foreground ,sunburn-fg))))
   `(grep-error-face ((t (:foreground ,sunburn-red-1 :weight bold :underline t))))
   `(grep-hit-face ((t (:foreground ,sunburn-blue))))
   `(grep-match-face ((t (:foreground ,sunburn-orange :weight bold))))
   `(match ((t (:background ,sunburn-bg-1 :foreground ,sunburn-orange :weight bold))))
;;;;; info
   `(Info-quoted ((t (:inherit font-lock-constant-face))))
;;;;; isearch
   `(isearch ((t (:foreground ,sunburn-yellow-2 :weight bold :background ,sunburn-bg+2))))
   `(isearch-fail ((t (:foreground ,sunburn-fg :background ,sunburn-red-4))))
   `(lazy-highlight ((t (:foreground ,sunburn-yellow-2 :weight bold :background ,sunburn-bg-05))))

   `(menu ((t (:foreground ,sunburn-fg :background ,sunburn-bg))))
   `(minibuffer-prompt ((t (:background ,sunburn-bg-05 :foreground ,sunburn-yellow))))
   `(mode-line
     ((,class (:foreground ,sunburn-fg+1
                           :background ,sunburn-bg-2
                          ; :box (:line-width -1 :style released-button)
                           ))
      (t :inverse-video t)))
   `(mode-line-buffer-id ((t (:foreground ,sunburn-fg-1 :weight bold))))
   `(mode-line-inactive
     ((t (:foreground ,sunburn-blue-1
                      :background ,sunburn-bg-05
                     ; :box (:line-width -1 :style released-button)
                      ))))
   ;; `(region ((,class (:background ,sunburn-gold))
   ;;           (t :inverse-video t)))
   `(region ((t (:foreground ,sunburn-bg-05  :background ,sunburn-gold :reverse-video t))))
   `(secondary-selection ((t (:background ,sunburn-bg+2))))
   `(trailing-whitespace ((t (:background ,sunburn-red))))
   `(vertical-border ((t (:foreground ,sunburn-fg))))
;;;;; font lock
   `(font-lock-builtin-face ((t (:foreground ,sunburn-fg-1, :weight bold))))
   `(font-lock-comment-face ((t (:background ,sunburn-bg :foreground ,sunburn-bg+3))))
   `(font-lock-comment-delimiter-face ((t (:background ,sunburn-bg :foreground ,sunburn-bg+3))))
   `(font-lock-constant-face ((t (:foreground ,sunburn-blue+1))))
   `(font-lock-doc-face ((t (:foreground ,sunburn-blue+1))))
   `(font-lock-function-name-face ((t (:foreground ,sunburn-cyan))))
   `(font-lock-keyword-face ((t (:foreground ,sunburn-yellow :weight bold))))
   `(font-lock-negation-char-face ((t (:foreground ,sunburn-yellow :weight bold))))
   `(font-lock-preprocessor-face ((t (:foreground ,sunburn-blue+1))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,sunburn-yellow :weight bold))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,sunburn-green :weight bold))))
   `(font-lock-string-face ((t (:foreground ,sunburn-red+1))))
   `(font-lock-type-face ((t (:foreground ,sunburn-green))))
   `(font-lock-variable-name-face ((t (:foreground ,sunburn-yellow-1))))
   `(font-lock-warning-face ((t (:foreground ,sunburn-yellow-2 :weight bold))))

   `(c-annotation-face ((t (:inherit font-lock-constant-face))))
;;;;; newsticker
   `(newsticker-date-face ((t (:foreground ,sunburn-fg))))
   `(newsticker-default-face ((t (:foreground ,sunburn-fg))))
   `(newsticker-enclosure-face ((t (:foreground ,sunburn-green+3))))
   `(newsticker-extra-face ((t (:foreground ,sunburn-bg+2 :height 0.8))))
   `(newsticker-feed-face ((t (:foreground ,sunburn-fg))))
   `(newsticker-immortal-item-face ((t (:foreground ,sunburn-green))))
   `(newsticker-new-item-face ((t (:foreground ,sunburn-blue))))
   `(newsticker-obsolete-item-face ((t (:foreground ,sunburn-red))))
   `(newsticker-old-item-face ((t (:foreground ,sunburn-bg+3))))
   `(newsticker-statistics-face ((t (:foreground ,sunburn-fg))))
   `(newsticker-treeview-face ((t (:foreground ,sunburn-fg))))
   `(newsticker-treeview-immortal-face ((t (:foreground ,sunburn-green))))
   `(newsticker-treeview-listwindow-face ((t (:foreground ,sunburn-fg))))
   `(newsticker-treeview-new-face ((t (:foreground ,sunburn-blue :weight bold))))
   `(newsticker-treeview-obsolete-face ((t (:foreground ,sunburn-red))))
   `(newsticker-treeview-old-face ((t (:foreground ,sunburn-bg+3))))
   `(newsticker-treeview-selection-face ((t (:background ,sunburn-bg-1 :foreground ,sunburn-yellow))))
;;;; Third-party
;;;;; ace-jump
   `(ace-jump-face-background
     ((t (:foreground ,sunburn-fg-1 :background ,sunburn-bg :inverse-video nil))))
   `(ace-jump-face-foreground
     ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg :inverse-video nil))))
;;;;; ace-window
   `(aw-background-face
     ((t (:foreground ,sunburn-fg-1 :background ,sunburn-bg :inverse-video nil))))
   `(aw-leading-char-face ((t (:inherit aw-mode-line-face))))
;;;;; android mode
   `(android-mode-debug-face ((t (:foreground ,sunburn-green+1))))
   `(android-mode-error-face ((t (:foreground ,sunburn-orange :weight bold))))
   `(android-mode-info-face ((t (:foreground ,sunburn-fg))))
   `(android-mode-verbose-face ((t (:foreground ,sunburn-green))))
   `(android-mode-warning-face ((t (:foreground ,sunburn-yellow))))
;;;;; anzu
   `(anzu-mode-line ((t (:foreground ,sunburn-cyan :weight bold))))
   `(anzu-mode-line-no-match ((t (:foreground ,sunburn-red :weight bold))))
   `(anzu-match-1 ((t (:foreground ,sunburn-bg :background ,sunburn-green))))
   `(anzu-match-2 ((t (:foreground ,sunburn-bg :background ,sunburn-orange))))
   `(anzu-match-3 ((t (:foreground ,sunburn-bg :background ,sunburn-blue))))
   `(anzu-replace-to ((t (:inherit anzu-replace-highlight :foreground ,sunburn-yellow))))
;;;;; auctex
   `(font-latex-bold-face ((t (:inherit bold))))
   `(font-latex-warning-face ((t (:foreground nil :inherit font-lock-warning-face))))
   `(font-latex-slide-title-face ((t (:foreground ,sunburn-cyan :weight bold :scale 1.3))))
   `(font-latex-sectioning-0-face ((t (:foreground ,sunburn-yellow :weight bold :scale 1.3))))
   `(font-latex-sectioning-1-face ((t (:foreground ,sunburn-blue+1 :weight bold :scale 1.2))))
   `(font-latex-sectioning-2-face ((t (:foreground ,sunburn-orange :weight bold :scale 1.1))))
   `(font-latex-sectioning-3-face ((t (:foreground ,sunburn-cyan :weight bold ))))
   `(font-latex-sectioning-4-face ((t (:foreground ,sunburn-green :weight bold ))))
   `(font-latex-sectioning-5-face ((t (:foreground ,sunburn-red :weight bold ))))
   `(font-latex-verbatim-face ((t (:foreground ,sunburn-blue+1 :weight bold ))))
   `(font-latex-sedate-face ((t (:foreground ,sunburn-yellow))))
   `(font-latex-italic-face ((t (:foreground ,sunburn-cyan :slant italic))))
   `(font-latex-string-face ((t (:foreground ,sunburn-red+1))))
   `(font-latex-math-face ((t (:foreground ,sunburn-orange))))
;;;;; agda-mode
   `(agda2-highlight-keyword-face ((t (:foreground ,sunburn-yellow :weight bold))))
   `(agda2-highlight-string-face ((t (:foreground ,sunburn-red))))
   `(agda2-highlight-symbol-face ((t (:foreground ,sunburn-orange))))
   `(agda2-highlight-primitive-type-face ((t (:foreground ,sunburn-blue-1))))
   `(agda2-highlight-inductive-constructor-face ((t (:foreground ,sunburn-fg))))
   `(agda2-highlight-coinductive-constructor-face ((t (:foreground ,sunburn-fg))))
   `(agda2-highlight-datatype-face ((t (:foreground ,sunburn-blue))))
   `(agda2-highlight-function-face ((t (:foreground ,sunburn-blue))))
   `(agda2-highlight-module-face ((t (:foreground ,sunburn-blue-1))))
   `(agda2-highlight-error-face ((t (:foreground ,sunburn-bg :background ,sunburn-magenta))))
   `(agda2-highlight-unsolved-meta-face ((t (:foreground ,sunburn-bg :background ,sunburn-magenta))))
   `(agda2-highlight-unsolved-constraint-face ((t (:foreground ,sunburn-bg :background ,sunburn-magenta))))
   `(agda2-highlight-termination-problem-face ((t (:foreground ,sunburn-bg :background ,sunburn-magenta))))
   `(agda2-highlight-incomplete-pattern-face ((t (:foreground ,sunburn-bg :background ,sunburn-magenta))))
   `(agda2-highlight-typechecks-face ((t (:background ,sunburn-red-4))))
;;;;; auto-complete
   `(ac-candidate-face ((t (:background ,sunburn-bg+3 :foreground ,sunburn-bg-2))))
   `(ac-selection-face ((t (:background ,sunburn-blue-4 :foreground ,sunburn-fg))))
   `(popup-tip-face ((t (:background ,sunburn-yellow-2 :foreground ,sunburn-bg-2))))
   `(popup-menu-mouse-face ((t (:background ,sunburn-yellow-2 :foreground ,sunburn-bg-2))))
   `(popup-summary-face ((t (:background ,sunburn-bg+3 :foreground ,sunburn-bg-2))))
   `(popup-scroll-bar-foreground-face ((t (:background ,sunburn-blue-5))))
   `(popup-scroll-bar-background-face ((t (:background ,sunburn-bg-1))))
   `(popup-isearch-match ((t (:background ,sunburn-bg :foreground ,sunburn-fg))))
;;;;; avy
   `(avy-background-face
     ((t (:foreground ,sunburn-fg-1 :background ,sunburn-bg :inverse-video nil))))
   `(avy-lead-face-0
     ((t (:foreground ,sunburn-green+3 :background ,sunburn-bg :inverse-video nil :weight bold))))
   `(avy-lead-face-1
     ((t (:foreground ,sunburn-yellow :background ,sunburn-bg :inverse-video nil :weight bold))))
   `(avy-lead-face-2
     ((t (:foreground ,sunburn-red+1 :background ,sunburn-bg :inverse-video nil :weight bold))))
   `(avy-lead-face
     ((t (:foreground ,sunburn-cyan :background ,sunburn-bg :inverse-video nil :weight bold))))
;;;;; company-mode
   `(company-tooltip ((t (:foreground ,sunburn-fg :background ,sunburn-bg+1))))
   `(company-tooltip-annotation ((t (:foreground ,sunburn-orange :background ,sunburn-bg+1))))
   `(company-tooltip-annotation-selection ((t (:foreground ,sunburn-orange :background ,sunburn-bg-1))))
   `(company-tooltip-selection ((t (:foreground ,sunburn-fg :background ,sunburn-bg-1))))
   `(company-tooltip-mouse ((t (:background ,sunburn-bg-1))))
   `(company-tooltip-common ((t (:foreground ,sunburn-green+2))))
   `(company-tooltip-common-selection ((t (:foreground ,sunburn-green+2))))
   `(company-scrollbar-fg ((t (:background ,sunburn-bg-1))))
   `(company-scrollbar-bg ((t (:background ,sunburn-bg+2))))
   `(company-preview ((t (:background ,sunburn-green+2))))
   `(company-preview-common ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg-1))))
;;;;; bm
   `(bm-face ((t (:background ,sunburn-yellow-1 :foreground ,sunburn-bg))))
   `(bm-fringe-face ((t (:background ,sunburn-yellow-1 :foreground ,sunburn-bg))))
   `(bm-fringe-persistent-face ((t (:background ,sunburn-green-1 :foreground ,sunburn-bg))))
   `(bm-persistent-face ((t (:background ,sunburn-green-1 :foreground ,sunburn-bg))))
;;;;; calfw
   `(cfw:face-annotation ((t (:foreground ,sunburn-red :inherit cfw:face-day-title))))
   `(cfw:face-day-title ((t nil)))
   `(cfw:face-default-content ((t (:foreground ,sunburn-green))))
   `(cfw:face-default-day ((t (:weight bold))))
   `(cfw:face-disable ((t (:foreground ,sunburn-fg-1))))
   `(cfw:face-grid ((t (:inherit shadow))))
   `(cfw:face-header ((t (:inherit font-lock-keyword-face))))
   `(cfw:face-holiday ((t (:inherit cfw:face-sunday))))
   `(cfw:face-periods ((t (:foreground ,sunburn-cyan))))
   `(cfw:face-saturday ((t (:foreground ,sunburn-blue :weight bold))))
   `(cfw:face-select ((t (:background ,sunburn-blue-5))))
   `(cfw:face-sunday ((t (:foreground ,sunburn-red :weight bold))))
   `(cfw:face-title ((t (:height 2.0 :inherit (variable-pitch font-lock-keyword-face)))))
   `(cfw:face-today ((t (:foreground ,sunburn-cyan :weight bold))))
   `(cfw:face-today-title ((t (:inherit highlight bold))))
   `(cfw:face-toolbar ((t (:background ,sunburn-blue-5))))
   `(cfw:face-toolbar-button-off ((t (:underline nil :inherit link))))
   `(cfw:face-toolbar-button-on ((t (:underline nil :inherit link-visited))))
;;;;; cider
   `(cider-result-overlay-face ((t (:background unspecified))))
   `(cider-enlightened-face ((t (:box (:color ,sunburn-orange :line-width -1)))))
   `(cider-enlightened-local-face ((t (:weight bold :foreground ,sunburn-green+1))))
   `(cider-deprecated-face ((t (:background ,sunburn-yellow-2))))
   `(cider-instrumented-face ((t (:box (:color ,sunburn-red :line-width -1)))))
   `(cider-traced-face ((t (:box (:color ,sunburn-cyan :line-width -1)))))
   `(cider-test-failure-face ((t (:background ,sunburn-red-4))))
   `(cider-test-error-face ((t (:background ,sunburn-magenta))))
   `(cider-test-success-face ((t (:background ,sunburn-green-1))))
;;;;; circe
   `(circe-highlight-nick-face ((t (:foreground ,sunburn-cyan))))
   `(circe-my-message-face ((t (:foreground ,sunburn-fg))))
   `(circe-fool-face ((t (:foreground ,sunburn-red+1))))
   `(circe-topic-diff-removed-face ((t (:foreground ,sunburn-red :weight bold))))
   `(circe-originator-face ((t (:foreground ,sunburn-fg))))
   `(circe-server-face ((t (:foreground ,sunburn-green))))
   `(circe-topic-diff-new-face ((t (:foreground ,sunburn-orange :weight bold))))
   `(circe-prompt-face ((t (:foreground ,sunburn-orange :background ,sunburn-bg :weight bold))))
;;;;; context-coloring
   `(context-coloring-level-0-face ((t :foreground ,sunburn-fg)))
   `(context-coloring-level-1-face ((t :foreground ,sunburn-cyan)))
   `(context-coloring-level-2-face ((t :foreground ,sunburn-green+4)))
   `(context-coloring-level-3-face ((t :foreground ,sunburn-yellow)))
   `(context-coloring-level-4-face ((t :foreground ,sunburn-orange)))
   `(context-coloring-level-5-face ((t :foreground ,sunburn-magenta)))
   `(context-coloring-level-6-face ((t :foreground ,sunburn-blue+1)))
   `(context-coloring-level-7-face ((t :foreground ,sunburn-green+2)))
   `(context-coloring-level-8-face ((t :foreground ,sunburn-yellow-2)))
   `(context-coloring-level-9-face ((t :foreground ,sunburn-red+1)))
;;;;; coq
   `(coq-solve-tactics-face ((t (:foreground nil :inherit font-lock-constant-face))))
;;;;; ctable
   `(ctbl:face-cell-select ((t (:background ,sunburn-blue :foreground ,sunburn-bg))))
   `(ctbl:face-continue-bar ((t (:background ,sunburn-bg-05 :foreground ,sunburn-bg))))
   `(ctbl:face-row-select ((t (:background ,sunburn-cyan :foreground ,sunburn-bg))))
;;;;; debbugs
   `(debbugs-gnu-done ((t (:foreground ,sunburn-fg-1))))
   `(debbugs-gnu-handled ((t (:foreground ,sunburn-green))))
   `(debbugs-gnu-new ((t (:foreground ,sunburn-red))))
   `(debbugs-gnu-pending ((t (:foreground ,sunburn-blue))))
   `(debbugs-gnu-stale ((t (:foreground ,sunburn-orange))))
   `(debbugs-gnu-tagged ((t (:foreground ,sunburn-red))))
;;;;; diff
   `(diff-added          ((t (:background "#335533" :foreground ,sunburn-green))))
   `(diff-changed        ((t (:background "#555511" :foreground ,sunburn-yellow-1))))
   `(diff-removed        ((t (:background "#553333" :foreground ,sunburn-red-2))))
   `(diff-refine-added   ((t (:background "#338833" :foreground ,sunburn-green+4))))
   `(diff-refine-change  ((t (:background "#888811" :foreground ,sunburn-yellow))))
   `(diff-refine-removed ((t (:background "#883333" :foreground ,sunburn-red))))
   `(diff-header ((,class (:background ,sunburn-bg+2))
                  (t (:background ,sunburn-fg :foreground ,sunburn-bg))))
   `(diff-file-header
     ((,class (:background ,sunburn-bg+2 :foreground ,sunburn-fg :weight bold))
      (t (:background ,sunburn-fg :foreground ,sunburn-bg :weight bold))))
;;;;; diff-hl
   `(diff-hl-change ((,class (:foreground ,sunburn-blue :background ,sunburn-blue-2))))
   `(diff-hl-delete ((,class (:foreground ,sunburn-red+1 :background ,sunburn-red-1))))
   `(diff-hl-insert ((,class (:foreground ,sunburn-green+1 :background ,sunburn-green-1))))
;;;;; dim-autoload
   `(dim-autoload-cookie-line ((t :foreground ,sunburn-bg+1)))
;;;;; dired+
   `(diredp-display-msg ((t (:foreground ,sunburn-blue))))
   `(diredp-compressed-file-suffix ((t (:foreground ,sunburn-orange))))
   `(diredp-date-time ((t (:foreground ,sunburn-magenta))))
   `(diredp-deletion ((t (:foreground ,sunburn-yellow))))
   `(diredp-deletion-file-name ((t (:foreground ,sunburn-red))))
   `(diredp-dir-heading ((t (:foreground ,sunburn-blue :background ,sunburn-bg-1))))
   `(diredp-dir-priv ((t (:foreground ,sunburn-cyan))))
   `(diredp-exec-priv ((t (:foreground ,sunburn-red))))
   `(diredp-executable-tag ((t (:foreground ,sunburn-green+1))))
   `(diredp-file-name ((t (:foreground ,sunburn-blue))))
   `(diredp-file-suffix ((t (:foreground ,sunburn-green))))
   `(diredp-flag-mark ((t (:foreground ,sunburn-yellow))))
   `(diredp-flag-mark-line ((t (:foreground ,sunburn-orange))))
   `(diredp-ignored-file-name ((t (:foreground ,sunburn-red))))
   `(diredp-link-priv ((t (:foreground ,sunburn-yellow))))
   `(diredp-mode-line-flagged ((t (:foreground ,sunburn-yellow))))
   `(diredp-mode-line-marked ((t (:foreground ,sunburn-orange))))
   `(diredp-no-priv ((t (:foreground ,sunburn-fg))))
   `(diredp-number ((t (:foreground ,sunburn-green+1))))
   `(diredp-other-priv ((t (:foreground ,sunburn-yellow-1))))
   `(diredp-rare-priv ((t (:foreground ,sunburn-red-1))))
   `(diredp-read-priv ((t (:foreground ,sunburn-green-1))))
   `(diredp-symlink ((t (:foreground ,sunburn-yellow))))
   `(diredp-write-priv ((t (:foreground ,sunburn-magenta))))
;;;;; dired-async
   `(dired-async-failures ((t (:foreground ,sunburn-red :weight bold))))
   `(dired-async-message ((t (:foreground ,sunburn-yellow :weight bold))))
   `(dired-async-mode-message ((t (:foreground ,sunburn-yellow))))
;;;;; ediff
   `(ediff-current-diff-A ((t (:foreground ,sunburn-fg :background ,sunburn-red-4))))
   `(ediff-current-diff-Ancestor ((t (:foreground ,sunburn-fg :background ,sunburn-red-4))))
   `(ediff-current-diff-B ((t (:foreground ,sunburn-fg :background ,sunburn-green-1))))
   `(ediff-current-diff-C ((t (:foreground ,sunburn-fg :background ,sunburn-blue-5))))
   `(ediff-even-diff-A ((t (:background ,sunburn-bg+1))))
   `(ediff-even-diff-Ancestor ((t (:background ,sunburn-bg+1))))
   `(ediff-even-diff-B ((t (:background ,sunburn-bg+1))))
   `(ediff-even-diff-C ((t (:background ,sunburn-bg+1))))
   `(ediff-fine-diff-A ((t (:foreground ,sunburn-fg :background ,sunburn-red-2 :weight bold))))
   `(ediff-fine-diff-Ancestor ((t (:foreground ,sunburn-fg :background ,sunburn-red-2 weight bold))))
   `(ediff-fine-diff-B ((t (:foreground ,sunburn-fg :background ,sunburn-green :weight bold))))
   `(ediff-fine-diff-C ((t (:foreground ,sunburn-fg :background ,sunburn-blue-3 :weight bold ))))
   `(ediff-odd-diff-A ((t (:background ,sunburn-bg+2))))
   `(ediff-odd-diff-Ancestor ((t (:background ,sunburn-bg+2))))
   `(ediff-odd-diff-B ((t (:background ,sunburn-bg+2))))
   `(ediff-odd-diff-C ((t (:background ,sunburn-bg+2))))
;;;;; egg
   `(egg-text-base ((t (:foreground ,sunburn-fg))))
   `(egg-help-header-1 ((t (:foreground ,sunburn-yellow))))
   `(egg-help-header-2 ((t (:foreground ,sunburn-green+3))))
   `(egg-branch ((t (:foreground ,sunburn-yellow))))
   `(egg-branch-mono ((t (:foreground ,sunburn-yellow))))
   `(egg-term ((t (:foreground ,sunburn-yellow))))
   `(egg-diff-add ((t (:foreground ,sunburn-green+4))))
   `(egg-diff-del ((t (:foreground ,sunburn-red+1))))
   `(egg-diff-file-header ((t (:foreground ,sunburn-yellow-2))))
   `(egg-section-title ((t (:foreground ,sunburn-yellow))))
   `(egg-stash-mono ((t (:foreground ,sunburn-green+4))))
;;;;; elfeed
   `(elfeed-log-error-level-face ((t (:foreground ,sunburn-red))))
   `(elfeed-log-info-level-face ((t (:foreground ,sunburn-blue))))
   `(elfeed-log-warn-level-face ((t (:foreground ,sunburn-yellow))))
   `(elfeed-search-date-face ((t (:foreground ,sunburn-yellow-1 :underline t
                                              :weight bold))))
   `(elfeed-search-tag-face ((t (:foreground ,sunburn-green))))
   `(elfeed-search-feed-face ((t (:foreground ,sunburn-cyan))))
;;;;; emacs-w3m
   `(w3m-anchor ((t (:foreground ,sunburn-yellow :underline t
                                 :weight bold))))
   `(w3m-arrived-anchor ((t (:foreground ,sunburn-yellow-2
                                         :underline t :weight normal))))
   `(w3m-form ((t (:foreground ,sunburn-red-1 :underline t))))
   `(w3m-header-line-location-title ((t (:foreground ,sunburn-yellow
                                                     :underline t :weight bold))))
   '(w3m-history-current-url ((t (:inherit match))))
   `(w3m-lnum ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg))))
   `(w3m-lnum-match ((t (:background ,sunburn-bg-1
                                     :foreground ,sunburn-orange
                                     :weight bold))))
   `(w3m-lnum-minibuffer-prompt ((t (:foreground ,sunburn-yellow))))
;;;;; erc
   `(erc-action-face ((t (:inherit erc-default-face))))
   `(erc-bold-face ((t (:weight bold))))
   `(erc-current-nick-face ((t (:foreground ,sunburn-blue :weight bold))))
   `(erc-dangerous-host-face ((t (:inherit font-lock-warning-face))))
   `(erc-default-face ((t (:foreground ,sunburn-fg))))
   `(erc-direct-msg-face ((t (:inherit erc-default-face))))
   `(erc-error-face ((t (:inherit font-lock-warning-face))))
   `(erc-fool-face ((t (:inherit erc-default-face))))
   `(erc-highlight-face ((t (:inherit hover-highlight))))
   `(erc-input-face ((t (:foreground ,sunburn-yellow))))
   `(erc-keyword-face ((t (:foreground ,sunburn-blue :weight bold))))
   `(erc-nick-default-face ((t (:foreground ,sunburn-yellow :weight bold))))
   `(erc-my-nick-face ((t (:foreground ,sunburn-red :weight bold))))
   `(erc-nick-msg-face ((t (:inherit erc-default-face))))
   `(erc-notice-face ((t (:foreground ,sunburn-green))))
   `(erc-pal-face ((t (:foreground ,sunburn-orange :weight bold))))
   `(erc-prompt-face ((t (:foreground ,sunburn-orange :background ,sunburn-bg :weight bold))))
   `(erc-timestamp-face ((t (:foreground ,sunburn-green+4))))
   `(erc-underline-face ((t (:underline t))))
;;;;; eros
   `(eros-result-overlay-face ((t (:background unspecified))))
;;;;; ert
   `(ert-test-result-expected ((t (:foreground ,sunburn-green+4 :background ,sunburn-bg))))
   `(ert-test-result-unexpected ((t (:foreground ,sunburn-red :background ,sunburn-bg))))
;;;;; eshell
   `(eshell-prompt ((t (:foreground ,sunburn-yellow :weight bold))))
   `(eshell-ls-archive ((t (:foreground ,sunburn-red-1 :weight bold))))
   `(eshell-ls-backup ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-clutter ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-directory ((t (:foreground ,sunburn-blue+1 :weight bold))))
   `(eshell-ls-executable ((t (:foreground ,sunburn-red+1 :weight bold))))
   `(eshell-ls-unreadable ((t (:foreground ,sunburn-fg))))
   `(eshell-ls-missing ((t (:inherit font-lock-warning-face))))
   `(eshell-ls-product ((t (:inherit font-lock-doc-face))))
   `(eshell-ls-special ((t (:foreground ,sunburn-yellow :weight bold))))
   `(eshell-ls-symlink ((t (:foreground ,sunburn-cyan :weight bold))))
;;;;; flx
   `(flx-highlight-face ((t (:foreground ,sunburn-green+2 :weight bold))))
;;;;; flycheck
   `(flycheck-error
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-red-1) :inherit unspecified))
      (t (:foreground ,sunburn-red-1 :weight bold :underline t))))
   `(flycheck-warning
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-yellow) :inherit unspecified))
      (t (:foreground ,sunburn-yellow :weight bold :underline t))))
   `(flycheck-info
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-cyan) :inherit unspecified))
      (t (:foreground ,sunburn-cyan :weight bold :underline t))))
   `(flycheck-fringe-error ((t (:foreground ,sunburn-red-1 :weight bold))))
   `(flycheck-fringe-warning ((t (:foreground ,sunburn-yellow :weight bold))))
   `(flycheck-fringe-info ((t (:foreground ,sunburn-cyan :weight bold))))
;;;;; flymake
   `(flymake-errline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-red)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,sunburn-red-1 :weight bold :underline t))))
   `(flymake-warnline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-orange)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,sunburn-orange :weight bold :underline t))))
   `(flymake-infoline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-green)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,sunburn-green-1 :weight bold :underline t))))
;;;;; flyspell
   `(flyspell-duplicate
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-orange) :inherit unspecified))
      (t (:foreground ,sunburn-orange :weight bold :underline t))))
   `(flyspell-incorrect
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-red) :inherit unspecified))
      (t (:foreground ,sunburn-red-1 :weight bold :underline t))))
;;;;; full-ack
   `(ack-separator ((t (:foreground ,sunburn-fg))))
   `(ack-file ((t (:foreground ,sunburn-blue))))
   `(ack-line ((t (:foreground ,sunburn-yellow))))
   `(ack-match ((t (:foreground ,sunburn-orange :background ,sunburn-bg-1 :weight bold))))
;;;;; git-commit
   `(git-commit-comment-action  ((,class (:foreground ,sunburn-green+1 :weight bold))))
   `(git-commit-comment-branch  ((,class (:foreground ,sunburn-blue+1  :weight bold))))
   `(git-commit-comment-heading ((,class (:foreground ,sunburn-yellow  :weight bold))))
;;;;; git-gutter
   `(git-gutter:added ((t (:foreground ,sunburn-green :weight bold :inverse-video t))))
   `(git-gutter:deleted ((t (:foreground ,sunburn-red :weight bold :inverse-video t))))
   `(git-gutter:modified ((t (:foreground ,sunburn-magenta :weight bold :inverse-video t))))
   `(git-gutter:unchanged ((t (:foreground ,sunburn-fg :weight bold :inverse-video t))))
;;;;; git-gutter-fr
   `(git-gutter-fr:added ((t (:foreground ,sunburn-green  :weight bold))))
   `(git-gutter-fr:deleted ((t (:foreground ,sunburn-red :weight bold))))
   `(git-gutter-fr:modified ((t (:foreground ,sunburn-magenta :weight bold))))
;;;;; git-rebase
   `(git-rebase-hash ((t (:foreground, sunburn-orange))))
;;;;; gnus
   `(gnus-group-mail-1 ((t (:weight bold :inherit gnus-group-mail-1-empty))))
   `(gnus-group-mail-1-empty ((t (:inherit gnus-group-news-1-empty))))
   `(gnus-group-mail-2 ((t (:weight bold :inherit gnus-group-mail-2-empty))))
   `(gnus-group-mail-2-empty ((t (:inherit gnus-group-news-2-empty))))
   `(gnus-group-mail-3 ((t (:weight bold :inherit gnus-group-mail-3-empty))))
   `(gnus-group-mail-3-empty ((t (:inherit gnus-group-news-3-empty))))
   `(gnus-group-mail-4 ((t (:weight bold :inherit gnus-group-mail-4-empty))))
   `(gnus-group-mail-4-empty ((t (:inherit gnus-group-news-4-empty))))
   `(gnus-group-mail-5 ((t (:weight bold :inherit gnus-group-mail-5-empty))))
   `(gnus-group-mail-5-empty ((t (:inherit gnus-group-news-5-empty))))
   `(gnus-group-mail-6 ((t (:weight bold :inherit gnus-group-mail-6-empty))))
   `(gnus-group-mail-6-empty ((t (:inherit gnus-group-news-6-empty))))
   `(gnus-group-mail-low ((t (:weight bold :inherit gnus-group-mail-low-empty))))
   `(gnus-group-mail-low-empty ((t (:inherit gnus-group-news-low-empty))))
   `(gnus-group-news-1 ((t (:weight bold :inherit gnus-group-news-1-empty))))
   `(gnus-group-news-2 ((t (:weight bold :inherit gnus-group-news-2-empty))))
   `(gnus-group-news-3 ((t (:weight bold :inherit gnus-group-news-3-empty))))
   `(gnus-group-news-4 ((t (:weight bold :inherit gnus-group-news-4-empty))))
   `(gnus-group-news-5 ((t (:weight bold :inherit gnus-group-news-5-empty))))
   `(gnus-group-news-6 ((t (:weight bold :inherit gnus-group-news-6-empty))))
   `(gnus-group-news-low ((t (:weight bold :inherit gnus-group-news-low-empty))))
   `(gnus-header-content ((t (:inherit message-header-other))))
   `(gnus-header-from ((t (:inherit message-header-to))))
   `(gnus-header-name ((t (:inherit message-header-name))))
   `(gnus-header-newsgroups ((t (:inherit message-header-other))))
   `(gnus-header-subject ((t (:inherit message-header-subject))))
   `(gnus-server-opened ((t (:foreground ,sunburn-green+2 :weight bold))))
   `(gnus-server-denied ((t (:foreground ,sunburn-red+1 :weight bold))))
   `(gnus-server-closed ((t (:foreground ,sunburn-blue :slant italic))))
   `(gnus-server-offline ((t (:foreground ,sunburn-yellow :weight bold))))
   `(gnus-server-agent ((t (:foreground ,sunburn-blue :weight bold))))
   `(gnus-summary-cancelled ((t (:foreground ,sunburn-orange))))
   `(gnus-summary-high-ancient ((t (:foreground ,sunburn-blue))))
   `(gnus-summary-high-read ((t (:foreground ,sunburn-green :weight bold))))
   `(gnus-summary-high-ticked ((t (:foreground ,sunburn-orange :weight bold))))
   `(gnus-summary-high-unread ((t (:foreground ,sunburn-fg :weight bold))))
   `(gnus-summary-low-ancient ((t (:foreground ,sunburn-blue))))
   `(gnus-summary-low-read ((t (:foreground ,sunburn-green))))
   `(gnus-summary-low-ticked ((t (:foreground ,sunburn-orange :weight bold))))
   `(gnus-summary-low-unread ((t (:foreground ,sunburn-fg))))
   `(gnus-summary-normal-ancient ((t (:foreground ,sunburn-blue))))
   `(gnus-summary-normal-read ((t (:foreground ,sunburn-green))))
   `(gnus-summary-normal-ticked ((t (:foreground ,sunburn-orange :weight bold))))
   `(gnus-summary-normal-unread ((t (:foreground ,sunburn-fg))))
   `(gnus-summary-selected ((t (:foreground ,sunburn-yellow :weight bold))))
   `(gnus-cite-1 ((t (:foreground ,sunburn-blue))))
   `(gnus-cite-10 ((t (:foreground ,sunburn-yellow-1))))
   `(gnus-cite-11 ((t (:foreground ,sunburn-yellow))))
   `(gnus-cite-2 ((t (:foreground ,sunburn-blue-1))))
   `(gnus-cite-3 ((t (:foreground ,sunburn-blue-2))))
   `(gnus-cite-4 ((t (:foreground ,sunburn-green+2))))
   `(gnus-cite-5 ((t (:foreground ,sunburn-green+1))))
   `(gnus-cite-6 ((t (:foreground ,sunburn-green))))
   `(gnus-cite-7 ((t (:foreground ,sunburn-red))))
   `(gnus-cite-8 ((t (:foreground ,sunburn-red-1))))
   `(gnus-cite-9 ((t (:foreground ,sunburn-red-2))))
   `(gnus-group-news-1-empty ((t (:foreground ,sunburn-yellow))))
   `(gnus-group-news-2-empty ((t (:foreground ,sunburn-green+3))))
   `(gnus-group-news-3-empty ((t (:foreground ,sunburn-green+1))))
   `(gnus-group-news-4-empty ((t (:foreground ,sunburn-blue-2))))
   `(gnus-group-news-5-empty ((t (:foreground ,sunburn-blue-3))))
   `(gnus-group-news-6-empty ((t (:foreground ,sunburn-bg+2))))
   `(gnus-group-news-low-empty ((t (:foreground ,sunburn-bg+2))))
   `(gnus-signature ((t (:foreground ,sunburn-yellow))))
   `(gnus-x ((t (:background ,sunburn-fg :foreground ,sunburn-bg))))
;;;;; guide-key
   `(guide-key/highlight-command-face ((t (:foreground ,sunburn-blue))))
   `(guide-key/key-face ((t (:foreground ,sunburn-green))))
   `(guide-key/prefix-command-face ((t (:foreground ,sunburn-green+1))))
;;;;; helm
   `(helm-header
     ((t (:foreground ,sunburn-green
                      :background ,sunburn-bg
                      :underline nil
                      :box nil))))
   `(helm-source-header
     ((t (:foreground ,sunburn-yellow
                      :background ,sunburn-bg-1
                      :underline nil
                      :weight bold
                      :box (:line-width -1 :style released-button)))))
   `(helm-selection ((t (:background ,sunburn-bg-05 :foreground ,sunburn-gold :weight bold))))
   `(helm-selection-line ((t (:background ,sunburn-bg-05 :foreground ,sunburn-gold :weight bold))))
   `(helm-visible-mark ((t (:foreground ,sunburn-bg :background ,sunburn-yellow-2))))
   `(helm-candidate-number ((t (:foreground ,sunburn-green+4 :background ,sunburn-bg-1))))
   `(helm-separator ((t (:foreground ,sunburn-red :background ,sunburn-bg))))
   `(helm-time-zone-current ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg))))
   `(helm-time-zone-home ((t (:foreground ,sunburn-red :background ,sunburn-bg))))
   `(helm-bookmark-addressbook ((t (:foreground ,sunburn-orange :background ,sunburn-bg))))
   `(helm-bookmark-directory ((t (:foreground nil :background nil :inherit helm-ff-directory))))
   `(helm-bookmark-file ((t (:foreground nil :background nil :inherit helm-ff-file))))
   `(helm-bookmark-gnus ((t (:foreground ,sunburn-magenta :background ,sunburn-bg))))
   `(helm-bookmark-info ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg))))
   `(helm-bookmark-man ((t (:foreground ,sunburn-yellow :background ,sunburn-bg))))
   `(helm-bookmark-w3m ((t (:foreground ,sunburn-magenta :background ,sunburn-bg))))
   `(helm-buffer-not-saved ((t (:foreground ,sunburn-red :background ,sunburn-bg))))
   `(helm-buffer-process ((t (:foreground ,sunburn-cyan :background ,sunburn-bg))))
   `(helm-buffer-saved-out ((t (:foreground ,sunburn-fg :background ,sunburn-bg))))
   `(helm-buffer-size ((t (:foreground ,sunburn-fg-1 :background ,sunburn-bg))))
   `(helm-ff-directory ((t (:foreground ,sunburn-cyan :background ,sunburn-bg :weight bold))))
   `(helm-ff-file ((t (:foreground ,sunburn-fg :background ,sunburn-bg :weight normal))))
   `(helm-ff-executable ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg :weight normal))))
   `(helm-ff-invalid-symlink ((t (:foreground ,sunburn-red :background ,sunburn-bg :weight bold))))
   `(helm-ff-symlink ((t (:foreground ,sunburn-yellow :background ,sunburn-bg :weight bold))))
   `(helm-ff-prefix ((t (:foreground ,sunburn-bg :background ,sunburn-yellow :weight normal))))
   `(helm-grep-cmd-line ((t (:foreground ,sunburn-cyan :background ,sunburn-bg))))
   `(helm-grep-file ((t (:foreground ,sunburn-fg :background ,sunburn-bg))))
   `(helm-grep-finish ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg))))
   `(helm-grep-lineno ((t (:foreground ,sunburn-fg-1 :background ,sunburn-bg))))
   `(helm-grep-match ((t (:foreground nil :background nil :inherit helm-match))))
   `(helm-grep-running ((t (:foreground ,sunburn-red :background ,sunburn-bg))))
   `(helm-match ((t (:foreground ,sunburn-orange :background ,sunburn-bg-1 :weight bold))))
   `(helm-moccur-buffer ((t (:foreground ,sunburn-cyan :background ,sunburn-bg))))
   `(helm-mu-contacts-address-face ((t (:foreground ,sunburn-fg-1 :background ,sunburn-bg))))
   `(helm-mu-contacts-name-face ((t (:foreground ,sunburn-fg :background ,sunburn-bg))))
;;;;; helm-swoop
   `(helm-swoop-target-line-face ((t (:foreground ,sunburn-fg :background ,sunburn-bg+1))))
   `(helm-swoop-target-word-face ((t (:foreground ,sunburn-yellow :background ,sunburn-bg+2 :weight bold))))
;;;;; hl-line-mode
   `(hl-line-face ((,class (:background ,sunburn-bg-05))
                   (t :weight bold)))
   `(hl-line ((,class (:background ,sunburn-bg-05)) ; old emacsen
              (t :weight bold)))
;;;;; hl-sexp
   `(hl-sexp-face ((,class (:background ,sunburn-bg+1))
                   (t :weight bold)))
;;;;; hydra
   `(hydra-face-red ((t (:foreground ,sunburn-red-1 :background ,sunburn-bg))))
   `(hydra-face-amaranth ((t (:foreground ,sunburn-red-3 :background ,sunburn-bg))))
   `(hydra-face-blue ((t (:foreground ,sunburn-blue :background ,sunburn-bg))))
   `(hydra-face-pink ((t (:foreground ,sunburn-magenta :background ,sunburn-bg))))
   `(hydra-face-teal ((t (:foreground ,sunburn-cyan :background ,sunburn-bg))))
;;;;; irfc
   `(irfc-head-name-face ((t (:foreground ,sunburn-red :weight bold))))
   `(irfc-head-number-face ((t (:foreground ,sunburn-red :weight bold))))
   `(irfc-reference-face ((t (:foreground ,sunburn-blue-1 :weight bold))))
   `(irfc-requirement-keyword-face ((t (:inherit font-lock-keyword-face))))
   `(irfc-rfc-link-face ((t (:inherit link))))
   `(irfc-rfc-number-face ((t (:foreground ,sunburn-cyan :weight bold))))
   `(irfc-std-number-face ((t (:foreground ,sunburn-green+4 :weight bold))))
   `(irfc-table-item-face ((t (:foreground ,sunburn-green+3))))
   `(irfc-title-face ((t (:foreground ,sunburn-yellow
                                      :underline t :weight bold))))
;;;;; ivy
   `(ivy-confirm-face ((t (:foreground ,sunburn-green :background ,sunburn-bg))))
   `(ivy-match-required-face ((t (:foreground ,sunburn-red :background ,sunburn-bg))))
   `(ivy-remote ((t (:foreground ,sunburn-blue :background ,sunburn-bg))))
   `(ivy-subdir ((t (:foreground ,sunburn-yellow :background ,sunburn-bg))))
   `(ivy-current-match ((t (:foreground ,sunburn-yellow :weight bold :underline t))))
   `(ivy-minibuffer-match-face-1 ((t (:background ,sunburn-bg+1))))
   `(ivy-minibuffer-match-face-2 ((t (:background ,sunburn-green-1))))
   `(ivy-minibuffer-match-face-3 ((t (:background ,sunburn-green))))
   `(ivy-minibuffer-match-face-4 ((t (:background ,sunburn-green+1))))
;;;;; ido-mode
   `(ido-first-match ((t (:foreground ,sunburn-yellow :weight bold))))
   `(ido-only-match ((t (:foreground ,sunburn-orange :weight bold))))
   `(ido-subdir ((t (:foreground ,sunburn-yellow))))
   `(ido-indicator ((t (:foreground ,sunburn-yellow :background ,sunburn-red-4))))
;;;;; iedit-mode
   `(iedit-occurrence ((t (:background ,sunburn-bg+2 :weight bold))))
;;;;; jabber-mode
   `(jabber-roster-user-away ((t (:foreground ,sunburn-green+2))))
   `(jabber-roster-user-online ((t (:foreground ,sunburn-blue-1))))
   `(jabber-roster-user-dnd ((t (:foreground ,sunburn-red+1))))
   `(jabber-roster-user-xa ((t (:foreground ,sunburn-magenta))))
   `(jabber-roster-user-chatty ((t (:foreground ,sunburn-orange))))
   `(jabber-roster-user-error ((t (:foreground ,sunburn-red+1))))
   `(jabber-rare-time-face ((t (:foreground ,sunburn-green+1))))
   `(jabber-chat-prompt-local ((t (:foreground ,sunburn-blue-1))))
   `(jabber-chat-prompt-foreign ((t (:foreground ,sunburn-red+1))))
   `(jabber-chat-prompt-system ((t (:foreground ,sunburn-green+3))))
   `(jabber-activity-face((t (:foreground ,sunburn-red+1))))
   `(jabber-activity-personal-face ((t (:foreground ,sunburn-blue+1))))
   `(jabber-title-small ((t (:height 1.1 :weight bold))))
   `(jabber-title-medium ((t (:height 1.2 :weight bold))))
   `(jabber-title-large ((t (:height 1.3 :weight bold))))
;;;;; js2-mode
   `(js2-warning ((t (:underline ,sunburn-orange))))
   `(js2-error ((t (:foreground ,sunburn-red :weight bold))))
   `(js2-jsdoc-tag ((t (:foreground ,sunburn-green-1))))
   `(js2-jsdoc-type ((t (:foreground ,sunburn-green+2))))
   `(js2-jsdoc-value ((t (:foreground ,sunburn-green+3))))
   `(js2-function-param ((t (:foreground, sunburn-orange))))
   `(js2-external-variable ((t (:foreground ,sunburn-orange))))
;;;;; additional js2 mode attributes for better syntax highlighting
   `(js2-instance-member ((t (:foreground ,sunburn-green-1))))
   `(js2-jsdoc-html-tag-delimiter ((t (:foreground ,sunburn-orange))))
   `(js2-jsdoc-html-tag-name ((t (:foreground ,sunburn-red-1))))
   `(js2-object-property ((t (:foreground ,sunburn-blue+1))))
   `(js2-magic-paren ((t (:foreground ,sunburn-blue-5))))
   `(js2-private-function-call ((t (:foreground ,sunburn-cyan))))
   `(js2-function-call ((t (:foreground ,sunburn-cyan))))
   `(js2-private-member ((t (:foreground ,sunburn-blue-1))))
   `(js2-keywords ((t (:foreground ,sunburn-magenta))))
;;;;; ledger-mode
   `(ledger-font-payee-uncleared-face ((t (:foreground ,sunburn-red-1 :weight bold))))
   `(ledger-font-payee-cleared-face ((t (:foreground ,sunburn-fg :weight normal))))
   `(ledger-font-payee-pending-face ((t (:foreground ,sunburn-red :weight normal))))
   `(ledger-font-xact-highlight-face ((t (:background ,sunburn-bg+1))))
   `(ledger-font-auto-xact-face ((t (:foreground ,sunburn-yellow-1 :weight normal))))
   `(ledger-font-periodic-xact-face ((t (:foreground ,sunburn-green :weight normal))))
   `(ledger-font-pending-face ((t (:foreground ,sunburn-orange weight: normal))))
   `(ledger-font-other-face ((t (:foreground ,sunburn-fg))))
   `(ledger-font-posting-date-face ((t (:foreground ,sunburn-orange :weight normal))))
   `(ledger-font-posting-account-face ((t (:foreground ,sunburn-blue-1))))
   `(ledger-font-posting-account-cleared-face ((t (:foreground ,sunburn-fg))))
   `(ledger-font-posting-account-pending-face ((t (:foreground ,sunburn-orange))))
   `(ledger-font-posting-amount-face ((t (:foreground ,sunburn-orange))))
   `(ledger-occur-narrowed-face ((t (:foreground ,sunburn-fg-1 :invisible t))))
   `(ledger-occur-xact-face ((t (:background ,sunburn-bg+1))))
   `(ledger-font-comment-face ((t (:foreground ,sunburn-green))))
   `(ledger-font-reconciler-uncleared-face ((t (:foreground ,sunburn-red-1 :weight bold))))
   `(ledger-font-reconciler-cleared-face ((t (:foreground ,sunburn-fg :weight normal))))
   `(ledger-font-reconciler-pending-face ((t (:foreground ,sunburn-orange :weight normal))))
   `(ledger-font-report-clickable-face ((t (:foreground ,sunburn-orange :weight normal))))
;;;;; linum-mode
   `(linum ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg))))
;;;;; Line numbers in Emacs 26
   `(line-number ((t (:foreground ,sunburn-bg+3 :background ,sunburn-bg))))
   `(line-number-current-line ((t (:foreground ,sunburn-green+1 :background ,sunburn-bg))))
;;;;; lispy
   `(lispy-command-name-face ((t (:background ,sunburn-bg-05 :inherit font-lock-function-name-face))))
   `(lispy-cursor-face ((t (:foreground ,sunburn-bg :background ,sunburn-fg))))
   `(lispy-face-hint ((t (:inherit highlight :foreground ,sunburn-yellow))))
;;;;; ruler-mode
   `(ruler-mode-column-number ((t (:inherit 'ruler-mode-default :foreground ,sunburn-fg))))
   `(ruler-mode-fill-column ((t (:inherit 'ruler-mode-default :foreground ,sunburn-yellow))))
   `(ruler-mode-goal-column ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-comment-column ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-tab-stop ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-current-column ((t (:foreground ,sunburn-yellow :box t))))
   `(ruler-mode-default ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg))))

;;;;; lui
   `(lui-time-stamp-face ((t (:foreground ,sunburn-blue-1))))
   `(lui-hilight-face ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg))))
   `(lui-button-face ((t (:inherit hover-highlight))))
;;;;; macrostep
   `(macrostep-gensym-1
     ((t (:foreground ,sunburn-green+2 :background ,sunburn-bg-1))))
   `(macrostep-gensym-2
     ((t (:foreground ,sunburn-red+1 :background ,sunburn-bg-1))))
   `(macrostep-gensym-3
     ((t (:foreground ,sunburn-blue+1 :background ,sunburn-bg-1))))
   `(macrostep-gensym-4
     ((t (:foreground ,sunburn-magenta :background ,sunburn-bg-1))))
   `(macrostep-gensym-5
     ((t (:foreground ,sunburn-yellow :background ,sunburn-bg-1))))
   `(macrostep-expansion-highlight-face
     ((t (:inherit highlight))))
   `(macrostep-macro-face
     ((t (:underline t))))
;;;;; magit
;;;;;; headings and diffs
   `(magit-section-highlight           ((t (:background ,sunburn-bg-1 :foreground ,sunburn-fg-1))))
   `(magit-section-heading             ((t (:foreground ,sunburn-yellow :weight bold))))
   `(magit-section-heading-selection   ((t (:foreground ,sunburn-orange :weight bold))))
   `(magit-diff-file-heading           ((t (:background ,sunburn-bg-05 :foreground ,sunburn-fg+1 :weight bold))))
   `(magit-diff-file-heading-highlight ((t (:background ,sunburn-bg-05  :weight bold))))
   `(magit-diff-file-heading-selection ((t (:background ,sunburn-bg-05
                                                        :foreground ,sunburn-gold :weight bold))))
   `(magit-diff-hunk-heading           ((t (:background ,sunburn-bg-05))))
   `(magit-diff-hunk-heading-highlight ((t (:background ,sunburn-bg-05 :foreground ,sunburn-gold))))
   `(magit-diff-hunk-heading-selection ((t (:background ,sunburn-bg+2
                                                        :foreground ,sunburn-orange))))
   `(magit-diff-lines-heading          ((t (:background ,sunburn-red+1
                                                        :foreground ,sunburn-bg-2))))
   `(magit-diff-base      ((t (:background ,sunburn-bg :foreground ,sunburn-fg))))
   `(magit-diff-context   ((t (:background ,sunburn-bg :foreground ,sunburn-fg :weight bold))))
   `(magit-diff-context-highlight ((t (:background ,sunburn-bg :foreground ,sunburn-gold))))
   `(magit-diff-removed-highlight ((t (:background ,sunburn-bg :foreground ,sunburn-red-2))))
   `(magit-diff-removed  ((t (:background ,sunburn-bg :foreground ,sunburn-red+1))))
   `(magit-diff-added-highlight  ((t (:background ,sunburn-bg :foreground ,sunburn-green+3))))
   `(magit-diff-added  ((t (:background ,sunburn-bg :foreground ,sunburn-green+4))))
   `(magit-diffstat-added   ((t (:background ,sunburn-bg :foreground ,sunburn-green+4))))
   `(magit-diff-whitespace-warning ((t (:background ,sunburn-red :foreground ,sunburn-fg+1))))
   `(magit-diff-conflict-heading ((t (:background ,sunburn-red-4 :foreground ,sunburn-fg+1))))
   `(magit-diffstat-removed ((t (:foreground ,sunburn-red))))
;;;;;; popup
   `(magit-popup-heading             ((t (:foreground ,sunburn-yellow  :weight bold))))
   `(magit-popup-key                 ((t (:foreground ,sunburn-green-1 :weight bold))))
   `(magit-popup-argument            ((t (:foreground ,sunburn-green   :weight bold))))
   `(magit-popup-disabled-argument   ((t (:foreground ,sunburn-fg-1    :weight normal))))
   `(magit-popup-option-value        ((t (:foreground ,sunburn-blue-2  :weight bold))))
;;;;;; process
   `(magit-process-ok    ((t (:foreground ,sunburn-green  :weight bold))))
   `(magit-process-ng    ((t (:foreground ,sunburn-red    :weight bold))))
;;;;;; log
   `(magit-log-author    ((t (:foreground ,sunburn-orange))))
   `(magit-log-date      ((t (:foreground ,sunburn-fg-1))))
   `(magit-log-graph     ((t (:foreground ,sunburn-fg+1))))
;;;;;; sequence
   `(magit-sequence-pick ((t (:foreground ,sunburn-yellow-2))))
   `(magit-sequence-stop ((t (:foreground ,sunburn-green))))
   `(magit-sequence-part ((t (:foreground ,sunburn-yellow))))
   `(magit-sequence-head ((t (:foreground ,sunburn-blue))))
   `(magit-sequence-drop ((t (:foreground ,sunburn-red))))
   `(magit-sequence-done ((t (:foreground ,sunburn-fg-1))))
   `(magit-sequence-onto ((t (:foreground ,sunburn-fg-1))))
;;;;;; bisect
   `(magit-bisect-good ((t (:background ,sunburn-bg :foreground ,sunburn-green))))
   `(magit-bisect-skip ((t (:background ,sunburn-bg :foreground ,sunburn-yellow))))
   `(magit-bisect-bad  ((t (:background ,sunburn-bg :foreground ,sunburn-red))))
;;;;;; blame
   `(magit-blame-heading ((t (:background ,sunburn-bg-1 :foreground ,sunburn-blue+1))))
   `(magit-blame-hash    ((t (:background ,sunburn-bg-1 :foreground ,sunburn-orange))))
   `(magit-blame-name    ((t (:background ,sunburn-bg-1 :foreground ,sunburn-orange))))
   `(magit-blame-date    ((t (:background ,sunburn-bg-1 :foreground ,sunburn-orange))))
   `(magit-blame-summary ((t (:background ,sunburn-bg-1 :foreground ,sunburn-blue-2
                                          :weight bold))))
;;;;;; references etc
   `(magit-dimmed         ((t (:background ,sunburn-bg :foreground ,sunburn-bg+3))))
   `(magit-hash           ((t (:background ,sunburn-bg :foreground ,sunburn-bg+3))))
   `(magit-tag            ((t (:background ,sunburn-bg :foreground ,sunburn-orange :weight bold))))
   `(magit-branch-remote  ((t (:background ,sunburn-bg :foreground ,sunburn-green  :weight bold))))
   `(magit-branch-local   ((t (:background ,sunburn-bg :foreground ,sunburn-blue   :weight bold))))
   `(magit-branch-current ((t (:background ,sunburn-bg :foreground ,sunburn-blue   :weight bold :box t))))
   `(magit-head           ((t (:background ,sunburn-bg :foreground ,sunburn-blue   :weight bold))))
   `(magit-refname        ((t (:background ,sunburn-bg+2 :foreground ,sunburn-fg :weight bold))))
   `(magit-refname-stash  ((t (:background ,sunburn-bg+2 :foreground ,sunburn-fg :weight bold))))
   `(magit-refname-wip    ((t (:background ,sunburn-bg+2 :foreground ,sunburn-fg :weight bold))))
   `(magit-signature-good      ((t (:foreground ,sunburn-green))))
   `(magit-signature-bad       ((t (:foreground ,sunburn-red))))
   `(magit-signature-untrusted ((t (:foreground ,sunburn-yellow))))
   `(magit-cherry-unmatched    ((t (:foreground ,sunburn-cyan))))
   `(magit-cherry-equivalent   ((t (:foreground ,sunburn-magenta))))
   `(magit-reflog-commit       ((t (:foreground ,sunburn-green))))
   `(magit-reflog-amend        ((t (:foreground ,sunburn-magenta))))
   `(magit-reflog-merge        ((t (:foreground ,sunburn-green))))
   `(magit-reflog-checkout     ((t (:foreground ,sunburn-blue))))
   `(magit-reflog-reset        ((t (:foreground ,sunburn-red))))
   `(magit-reflog-rebase       ((t (:foreground ,sunburn-magenta))))
   `(magit-reflog-cherry-pick  ((t (:foreground ,sunburn-green))))
   `(magit-reflog-remote       ((t (:foreground ,sunburn-cyan))))
   `(magit-reflog-other        ((t (:foreground ,sunburn-cyan))))
;;;;; message-mode
   `(message-cited-text ((t (:inherit font-lock-comment-face))))
   `(message-header-name ((t (:foreground ,sunburn-green+1))))
   `(message-header-other ((t (:foreground ,sunburn-green))))
   `(message-header-to ((t (:foreground ,sunburn-yellow :weight bold))))
   `(message-header-cc ((t (:foreground ,sunburn-yellow :weight bold))))
   `(message-header-newsgroups ((t (:foreground ,sunburn-yellow :weight bold))))
   `(message-header-subject ((t (:foreground ,sunburn-orange :weight bold))))
   `(message-header-xheader ((t (:foreground ,sunburn-green))))
   `(message-mml ((t (:foreground ,sunburn-yellow :weight bold))))
   `(message-separator ((t (:inherit font-lock-comment-face))))
;;;;; mew
   `(mew-face-header-subject ((t (:foreground ,sunburn-orange))))
   `(mew-face-header-from ((t (:foreground ,sunburn-yellow))))
   `(mew-face-header-date ((t (:foreground ,sunburn-green))))
   `(mew-face-header-to ((t (:foreground ,sunburn-red))))
   `(mew-face-header-key ((t (:foreground ,sunburn-green))))
   `(mew-face-header-private ((t (:foreground ,sunburn-green))))
   `(mew-face-header-important ((t (:foreground ,sunburn-blue))))
   `(mew-face-header-marginal ((t (:foreground ,sunburn-fg :weight bold))))
   `(mew-face-header-warning ((t (:foreground ,sunburn-red))))
   `(mew-face-header-xmew ((t (:foreground ,sunburn-green))))
   `(mew-face-header-xmew-bad ((t (:foreground ,sunburn-red))))
   `(mew-face-body-url ((t (:foreground ,sunburn-orange))))
   `(mew-face-body-comment ((t (:foreground ,sunburn-fg :slant italic))))
   `(mew-face-body-cite1 ((t (:foreground ,sunburn-green))))
   `(mew-face-body-cite2 ((t (:foreground ,sunburn-blue))))
   `(mew-face-body-cite3 ((t (:foreground ,sunburn-orange))))
   `(mew-face-body-cite4 ((t (:foreground ,sunburn-yellow))))
   `(mew-face-body-cite5 ((t (:foreground ,sunburn-red))))
   `(mew-face-mark-review ((t (:foreground ,sunburn-blue))))
   `(mew-face-mark-escape ((t (:foreground ,sunburn-green))))
   `(mew-face-mark-delete ((t (:foreground ,sunburn-red))))
   `(mew-face-mark-unlink ((t (:foreground ,sunburn-yellow))))
   `(mew-face-mark-refile ((t (:foreground ,sunburn-green))))
   `(mew-face-mark-unread ((t (:foreground ,sunburn-red-2))))
   `(mew-face-eof-message ((t (:foreground ,sunburn-green))))
   `(mew-face-eof-part ((t (:foreground ,sunburn-yellow))))
;;;;; mic-paren
   `(paren-face-match ((t (:foreground ,sunburn-cyan :background ,sunburn-bg :weight bold))))
   `(paren-face-mismatch ((t (:foreground ,sunburn-bg :background ,sunburn-magenta :weight bold))))
   `(paren-face-no-match ((t (:foreground ,sunburn-bg :background ,sunburn-red :weight bold))))
;;;;; mingus
   `(mingus-directory-face ((t (:foreground ,sunburn-blue))))
   `(mingus-pausing-face ((t (:foreground ,sunburn-magenta))))
   `(mingus-playing-face ((t (:foreground ,sunburn-cyan))))
   `(mingus-playlist-face ((t (:foreground ,sunburn-cyan ))))
   `(mingus-mark-face ((t (:bold t :foreground ,sunburn-magenta))))
   `(mingus-song-file-face ((t (:foreground ,sunburn-yellow))))
   `(mingus-artist-face ((t (:foreground ,sunburn-cyan))))
   `(mingus-album-face ((t (:underline t :foreground ,sunburn-red+1))))
   `(mingus-album-stale-face ((t (:foreground ,sunburn-red+1))))
   `(mingus-stopped-face ((t (:foreground ,sunburn-red))))
;;;;; nav
   `(nav-face-heading ((t (:foreground ,sunburn-yellow))))
   `(nav-face-button-num ((t (:foreground ,sunburn-cyan))))
   `(nav-face-dir ((t (:foreground ,sunburn-green))))
   `(nav-face-hdir ((t (:foreground ,sunburn-red))))
   `(nav-face-file ((t (:foreground ,sunburn-fg))))
   `(nav-face-hfile ((t (:foreground ,sunburn-red-4))))
;;;;; mu4e
   `(mu4e-cited-1-face ((t (:foreground ,sunburn-blue    :slant italic))))
   `(mu4e-cited-2-face ((t (:foreground ,sunburn-green+2 :slant italic))))
   `(mu4e-cited-3-face ((t (:foreground ,sunburn-blue-2  :slant italic))))
   `(mu4e-cited-4-face ((t (:foreground ,sunburn-green   :slant italic))))
   `(mu4e-cited-5-face ((t (:foreground ,sunburn-blue-4  :slant italic))))
   `(mu4e-cited-6-face ((t (:foreground ,sunburn-green-1 :slant italic))))
   `(mu4e-cited-7-face ((t (:foreground ,sunburn-blue    :slant italic))))
   `(mu4e-replied-face ((t (:foreground ,sunburn-bg+3))))
   `(mu4e-trashed-face ((t (:foreground ,sunburn-bg+3 :strike-through t))))
;;;;; mumamo
   `(mumamo-background-chunk-major ((t (:background nil))))
   `(mumamo-background-chunk-submode1 ((t (:background ,sunburn-bg-1))))
   `(mumamo-background-chunk-submode2 ((t (:background ,sunburn-bg+2))))
   `(mumamo-background-chunk-submode3 ((t (:background ,sunburn-bg+3))))
   `(mumamo-background-chunk-submode4 ((t (:background ,sunburn-bg+1))))
;;;;; neotree
   `(neo-banner-face ((t (:foreground ,sunburn-blue+1 :weight bold))))
   `(neo-header-face ((t (:foreground ,sunburn-fg))))
   `(neo-root-dir-face ((t (:foreground ,sunburn-blue+1 :weight bold))))
   `(neo-dir-link-face ((t (:foreground ,sunburn-blue))))
   `(neo-file-link-face ((t (:foreground ,sunburn-fg))))
   `(neo-expand-btn-face ((t (:foreground ,sunburn-blue))))
   `(neo-vc-default-face ((t (:foreground ,sunburn-fg+1))))
   `(neo-vc-user-face ((t (:foreground ,sunburn-red :slant italic))))
   `(neo-vc-up-to-date-face ((t (:foreground ,sunburn-fg))))
   `(neo-vc-edited-face ((t (:foreground ,sunburn-magenta))))
   `(neo-vc-needs-merge-face ((t (:foreground ,sunburn-red+1))))
   `(neo-vc-unlocked-changes-face ((t (:foreground ,sunburn-red :background ,sunburn-blue-5))))
   `(neo-vc-added-face ((t (:foreground ,sunburn-green+1))))
   `(neo-vc-conflict-face ((t (:foreground ,sunburn-red+1))))
   `(neo-vc-missing-face ((t (:foreground ,sunburn-red+1))))
   `(neo-vc-ignored-face ((t (:foreground ,sunburn-fg-1))))
;;;;; org-mode
   `(org-agenda-date-today
     ((t (:background ,sunburn-bg :foreground ,sunburn-fg+1 :slant italic :weight bold))) t)
   `(org-agenda-clocking
     ((t (:background ,sunburn-bg :foreground ,sunburn-blue+1))) t)
   `(org-agenda-column-dateline
     ((t (:background ,sunburn-bg :foreground ,sunburn-yellow-1))) t)
   `(org-agenda-structure
     ((t (:inherit font-lock-comment-face))))
   `(org-agenda-dimmed-todo-face ((t (:background ,sunburn-red-1 :foreground ,sunburn-bg-1))))
   `(org-archived ((t (:foreground ,sunburn-fg :weight bold))))
   `(org-checkbox ((t (:background ,sunburn-bg+2 :foreground ,sunburn-fg+1
                                   :box (:line-width 1 :style released-button)))))
   `(org-date ((t (:foreground ,sunburn-blue :underline t))))
   `(org-deadline-announce ((t (:foreground ,sunburn-red-1))))
   `(org-formula ((t (:foreground ,sunburn-yellow-2))))
   `(org-headline-done ((t (:foreground ,sunburn-green+3))))
   `(org-hide ((t (:foreground ,sunburn-bg-1))))
   `(org-level-1 ((t (:weight bold :foreground ,sunburn-yellow))))
   `(org-level-2 ((t (:weight bold :foreground ,sunburn-blue+1))))
   `(org-level-3 ((t (:weight bold :foreground ,sunburn-orange))))
   `(org-level-4 ((t (:weight bold :foreground ,sunburn-cyan))))
   `(org-level-5 ((t (:weight bold :foreground ,sunburn-green))))
   `(org-level-6 ((t (:weight bold :foreground ,sunburn-red))))
   `(org-level-7 ((t (:foreground ,sunburn-yellow))))
   `(org-level-8 ((t (:foreground ,sunburn-blue+1))))
   `(org-link ((t (:foreground ,sunburn-yellow :underline t))))
   `(org-ref-acronym-face ((t (:foreground ,sunburn-gold :underline t))))
   `(org-ref-cite-face ((t (:foreground ,sunburn-green :underline t))))
   `(org-ref-glossary-face ((t (:foreground ,sunburn-blue :underline t))))
   `(org-ref-label-face ((t (:foreground ,sunburn-magenta :underline t))))
   `(org-ref-ref-face ((t (:foreground ,sunburn-red-2 :underline t))))
   `(org-verbatim ((,class (:weight bold :background ,sunburn-bg :foreground ,sunburn-blue+1))))
   `(org-quote ((,class (:weight bold :background ,sunburn-bg :foreground ,sunburn-blue+1))))
   `(org-code ((,class (:weight bold :background ,sunburn-bg :foreground ,sunburn-blue+1))))
   `(org-scheduled ((t (:foreground ,sunburn-green+4))))
   `(org-scheduled-previously ((t (:foreground ,sunburn-red))))
   `(org-scheduled-today ((t (:foreground ,sunburn-blue))))
   `(org-special-keyword ((t (:foreground ,sunburn-cyan))))
   `(org-special-properties ((t (:foreground ,sunburn-cyan))))
   `(org-sexp-date ((t (:foreground ,sunburn-cyan :underline t))))
   `(org-meta-line ((t (:foreground ,sunburn-yellow-1))))
   ;; `(org-table ((t (:foreground ,sunburn-fg))))
   `(org-table ((t :background ,sunburn-bg :foreground ,sunburn-cyan)))
   `(org-priority ((t (:background ,sunburn-bg :foreground ,sunburn-red :weight bold))))
   `(org-tag ((t (:background ,sunburn-bg :weight bold))))
   `(org-tag-group ((t (:background ,sunburn-bg :weight bold))))
   `(org-special-keyword ((t (:background ,sunburn-bg :weight bold))))
   `(org-time-grid ((t (:foreground ,sunburn-orange))))
   `(org-kbd ((t :background ,sunburn-gold :foreground ,sunburn-bg-05 :weight bold)))
   `(org-done ((t :background ,sunburn-bg :foreground ,sunburn-green+3)))
   `(org-todo ((t :background ,sunburn-bg :foreground ,sunburn-red)))
   `(org-upcoming-deadline ((t (:inherit font-lock-keyword-face))))
   `(org-warning ((t (:weight bold :foreground ,sunburn-red :weight bold :underline nil))))
   `(org-column ((t (:background ,sunburn-bg-1))))
   `(org-column-title ((t (:background ,sunburn-bg-1 :underline t :weight bold))))
   `(org-mode-line-clock ((t (:foreground ,sunburn-fg :background ,sunburn-bg-1))))
   `(org-mode-line-clock-overrun ((t (:foreground ,sunburn-bg :background ,sunburn-red-1))))
   `(org-ellipsis ((t (:foreground ,sunburn-yellow-1 :underline t))))
   `(org-footnote ((t (:foreground ,sunburn-cyan :underline t))))
   `(org-date ((t (:foreground ,sunburn-cyan :underline t))))
   `(org-property-value ((t (:foreground ,sunburn-magenta :underline t))))
   `(org-document-title ((t (:background ,sunburn-bg :foreground ,sunburn-blue :height 1.4))))
   `(org-document-info ((t (:background ,sunburn-bg :foreground ,sunburn-blue :height 1.2))))
   `(org-document-info-keyword ((t (:background ,sunburn-bg :foreground ,sunburn-green :height 1.2))))
   `(org-habit-ready-face ((t :background ,sunburn-green)))
   `(org-habit-alert-face ((t :background ,sunburn-yellow-1 :foreground ,sunburn-bg)))
   `(org-habit-clear-face ((t :background ,sunburn-blue-3)))
   `(org-habit-overdue-face ((t :background ,sunburn-red-3)))
   `(org-habit-clear-future-face ((t :background ,sunburn-blue-4)))
   `(org-habit-ready-future-face ((t :background ,sunburn-green-1)))
   `(org-habit-alert-future-face ((t :background ,sunburn-yellow-2 :foreground ,sunburn-bg)))
   `(org-habit-overdue-future-face ((t :background ,sunburn-red-4)))
   ;; `(org-block-begin-line ((t :background ,sunburn-bg-1 :foreground ,sunburn-yellow)))
   ;; `(org-block-end-line ((t :background ,sunburn-bg-1 :foreground ,sunburn-yellow)))
   ;; `(org-block ((t :background ,sunburn-bg :foreground ,sunburn-fg+1)))
   `(org-block-begin-line ((t :background ,sunburn-bg :foreground ,sunburn-bg+2)))
   `(org-block-end-line ((t :background ,sunburn-bg :foreground ,sunburn-bg+2)))
   `(org-block ((t :background ,sunburn-bg :foreground ,sunburn-fg)))
;;;;; ein
   `(ein:cell-input-prompt ((t (:foreground ,sunburn-cyan))))
   `(ein:cell-input-area ((t :background ,sunburn-bg-1)))
   `(ein:cell-heading-1 ((t (:weight bold :foreground ,sunburn-yellow))))
   `(ein:cell-heading-2 ((t (:weight bold :foreground ,sunburn-blue+1))))
   `(ein:cell-heading-3 ((t (:weight bold :foreground ,sunburn-orange))))
   `(ein:cell-heading-4 ((t (:weight bold :foreground ,sunburn-cyan))))
   `(ein:cell-heading-5 ((t (:weight bold :foreground ,sunburn-green))))
   `(ein:cell-heading-6 ((t (:weight bold :foreground ,sunburn-red))))
   `(ein:cell-output-stderr ((t (:weight bold :foreground ,sunburn-red :weight bold :underline nil))))
   `(ein:cell-output-prompt ((t (:foreground ,sunburn-green+3))))
;;;;; outline
   `(outline-1 ((t (:foreground ,sunburn-orange))))
   `(outline-2 ((t (:foreground ,sunburn-green+4))))
   `(outline-3 ((t (:foreground ,sunburn-blue-1))))
   `(outline-4 ((t (:foreground ,sunburn-yellow-2))))
   `(outline-5 ((t (:foreground ,sunburn-cyan))))
   `(outline-6 ((t (:foreground ,sunburn-green+2))))
   `(outline-7 ((t (:foreground ,sunburn-red-4))))
   `(outline-8 ((t (:foreground ,sunburn-blue-4))))
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
   `(persp-selected-face ((t (:foreground ,sunburn-yellow-2 :inherit mode-line))))
;;;;;
   `(powerline-active1 ((t (:background ,sunburn-bg-05 :inherit mode-line))))
   `(powerline-active2 ((t (:background ,sunburn-bg+2 :inherit mode-line))))
   `(powerline-inactive1 ((t (:background ,sunburn-bg+1 :inherit mode-line-inactive))))
   `(powerline-inactive2 ((t (:background ,sunburn-bg+3 :inherit mode-line-inactive))))
;;;;; proofgeneral
   `(proof-active-area-face ((t (:underline t))))
   `(proof-boring-face ((t (:foreground ,sunburn-fg :background ,sunburn-bg+2))))
   `(proof-command-mouse-highlight-face ((t (:inherit proof-mouse-highlight-face))))
   `(proof-debug-message-face ((t (:inherit proof-boring-face))))
   `(proof-declaration-name-face ((t (:inherit font-lock-keyword-face :foreground nil))))
   `(proof-eager-annotation-face ((t (:foreground ,sunburn-bg :background ,sunburn-orange))))
   `(proof-error-face ((t (:foreground ,sunburn-fg :background ,sunburn-red-4))))
   `(proof-highlight-dependency-face ((t (:foreground ,sunburn-bg :background ,sunburn-yellow-1))))
   `(proof-highlight-dependent-face ((t (:foreground ,sunburn-bg :background ,sunburn-orange))))
   `(proof-locked-face ((t (:background ,sunburn-blue-5))))
   `(proof-mouse-highlight-face ((t (:foreground ,sunburn-bg :background ,sunburn-orange))))
   `(proof-queue-face ((t (:background ,sunburn-red-4))))
   `(proof-region-mouse-highlight-face ((t (:inherit proof-mouse-highlight-face))))
   `(proof-script-highlight-error-face ((t (:background ,sunburn-red-2))))
   `(proof-tacticals-name-face ((t (:inherit font-lock-constant-face :foreground nil :background ,sunburn-bg))))
   `(proof-tactics-name-face ((t (:inherit font-lock-constant-face :foreground nil :background ,sunburn-bg))))
   `(proof-warning-face ((t (:foreground ,sunburn-bg :background ,sunburn-yellow-1))))
;;;;; racket-mode
   `(racket-keyword-argument-face ((t (:inherit font-lock-constant-face))))
   `(racket-selfeval-face ((t (:inherit font-lock-type-face))))
;;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,sunburn-fg))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,sunburn-green+4))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,sunburn-yellow-2))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,sunburn-cyan))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground ,sunburn-green+2))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,sunburn-blue+1))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,sunburn-yellow-1))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground ,sunburn-green+1))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground ,sunburn-blue-2))))
   `(rainbow-delimiters-depth-10-face ((t (:foreground ,sunburn-orange))))
   `(rainbow-delimiters-depth-11-face ((t (:foreground ,sunburn-green))))
   `(rainbow-delimiters-depth-12-face ((t (:foreground ,sunburn-blue-5))))
;;;;; rcirc
   `(rcirc-my-nick ((t (:foreground ,sunburn-blue))))
   `(rcirc-other-nick ((t (:foreground ,sunburn-orange))))
   `(rcirc-bright-nick ((t (:foreground ,sunburn-blue+1))))
   `(rcirc-dim-nick ((t (:foreground ,sunburn-blue-2))))
   `(rcirc-server ((t (:foreground ,sunburn-green))))
   `(rcirc-server-prefix ((t (:foreground ,sunburn-green+1))))
   `(rcirc-timestamp ((t (:foreground ,sunburn-green+2))))
   `(rcirc-nick-in-message ((t (:foreground ,sunburn-yellow))))
   `(rcirc-nick-in-message-full-line ((t (:weight bold))))
   `(rcirc-prompt ((t (:foreground ,sunburn-yellow :weight bold))))
   `(rcirc-track-nick ((t (:inverse-video t))))
   `(rcirc-track-keyword ((t (:weight bold))))
   `(rcirc-url ((t (:weight bold))))
   `(rcirc-keyword ((t (:foreground ,sunburn-yellow :weight bold))))
;;;;; re-builder
   `(reb-match-0 ((t (:foreground ,sunburn-bg :background ,sunburn-magenta))))
   `(reb-match-1 ((t (:foreground ,sunburn-bg :background ,sunburn-blue))))
   `(reb-match-2 ((t (:foreground ,sunburn-bg :background ,sunburn-orange))))
   `(reb-match-3 ((t (:foreground ,sunburn-bg :background ,sunburn-red))))
;;;;; regex-tool
   `(regex-tool-matched-face ((t (:background ,sunburn-blue-4 :weight bold))))
;;;;; rpm-mode
   `(rpm-spec-dir-face ((t (:foreground ,sunburn-green))))
   `(rpm-spec-doc-face ((t (:foreground ,sunburn-green))))
   `(rpm-spec-ghost-face ((t (:foreground ,sunburn-red))))
   `(rpm-spec-macro-face ((t (:foreground ,sunburn-yellow))))
   `(rpm-spec-obsolete-tag-face ((t (:foreground ,sunburn-red))))
   `(rpm-spec-package-face ((t (:foreground ,sunburn-red))))
   `(rpm-spec-section-face ((t (:foreground ,sunburn-yellow))))
   `(rpm-spec-tag-face ((t (:foreground ,sunburn-blue))))
   `(rpm-spec-var-face ((t (:foreground ,sunburn-red))))
;;;;; rst-mode
   `(rst-level-1-face ((t (:foreground ,sunburn-orange))))
   `(rst-level-2-face ((t (:foreground ,sunburn-green+1))))
   `(rst-level-3-face ((t (:foreground ,sunburn-blue-1))))
   `(rst-level-4-face ((t (:foreground ,sunburn-yellow-2))))
   `(rst-level-5-face ((t (:foreground ,sunburn-cyan))))
   `(rst-level-6-face ((t (:foreground ,sunburn-green-1))))
;;;;; sh-mode
   `(sh-heredoc     ((t (:foreground ,sunburn-yellow :weight bold))))
   `(sh-quoted-exec ((t (:foreground ,sunburn-red))))
;;;;; show-paren
   `(show-paren-mismatch ((t (:foreground ,sunburn-red+1 :background ,sunburn-bg+3 :weight bold))))
   `(show-paren-match ((t (:background ,sunburn-bg+3 :weight bold))))
;;;;; smart-mode-line
   ;; use (setq sml/theme nil) to enable Sunburn for sml
   `(sml/global ((,class (:foreground ,sunburn-fg :weight bold))))
   `(sml/modes ((,class (:foreground ,sunburn-yellow :weight bold))))
   `(sml/minor-modes ((,class (:foreground ,sunburn-fg-1 :weight bold))))
   `(sml/filename ((,class (:foreground ,sunburn-yellow :weight bold))))
   `(sml/line-number ((,class (:foreground ,sunburn-blue :weight bold))))
   `(sml/col-number ((,class (:foreground ,sunburn-blue+1 :weight bold))))
   `(sml/position-percentage ((,class (:foreground ,sunburn-blue-1 :weight bold))))
   `(sml/prefix ((,class (:foreground ,sunburn-orange))))
   `(sml/git ((,class (:foreground ,sunburn-green+3))))
   `(sml/process ((,class (:weight bold))))
   `(sml/sudo ((,class  (:foreground ,sunburn-orange :weight bold))))
   `(sml/read-only ((,class (:foreground ,sunburn-red-2))))
   `(sml/outside-modified ((,class (:foreground ,sunburn-orange))))
   `(sml/modified ((,class (:foreground ,sunburn-red))))
   `(sml/vc-edited ((,class (:foreground ,sunburn-green+2))))
   `(sml/charging ((,class (:foreground ,sunburn-green+4))))
   `(sml/discharging ((,class (:foreground ,sunburn-red+1))))
;;;;; smartparens
   `(sp-show-pair-mismatch-face ((t (:foreground ,sunburn-red+1 :background ,sunburn-bg+3 :weight bold))))
   `(sp-show-pair-match-face ((t (:background ,sunburn-bg+3 :weight bold))))
;;;;; sml-mode-line
   '(sml-modeline-end-face ((t :inherit default :width condensed)))
;;;;; SLIME
   `(slime-repl-output-face ((t (:foreground ,sunburn-red))))
   `(slime-repl-inputed-output-face ((t (:foreground ,sunburn-green))))
   `(slime-error-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-red)))
      (t
       (:underline ,sunburn-red))))
   `(slime-warning-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-orange)))
      (t
       (:underline ,sunburn-orange))))
   `(slime-style-warning-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-yellow)))
      (t
       (:underline ,sunburn-yellow))))
   `(slime-note-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,sunburn-green)))
      (t
       (:underline ,sunburn-green))))
   `(slime-highlight-face ((t (:inherit highlight))))
;;;;; speedbar
   `(speedbar-button-face ((t (:foreground ,sunburn-green+2))))
   `(speedbar-directory-face ((t (:foreground ,sunburn-cyan))))
   `(speedbar-file-face ((t (:foreground ,sunburn-fg))))
   `(speedbar-highlight-face ((t (:foreground ,sunburn-bg :background ,sunburn-green+2))))
   `(speedbar-selected-face ((t (:foreground ,sunburn-red))))
   `(speedbar-separator-face ((t (:foreground ,sunburn-bg :background ,sunburn-blue-1))))
   `(speedbar-tag-face ((t (:foreground ,sunburn-yellow))))
;;;;; tabbar
   `(tabbar-button ((t (:foreground ,sunburn-fg
                                    :background ,sunburn-bg))))
   `(tabbar-selected ((t (:foreground ,sunburn-fg
                                      :background ,sunburn-bg
                                      :box (:line-width -1 :style pressed-button)))))
   `(tabbar-unselected ((t (:foreground ,sunburn-fg
                                        :background ,sunburn-bg+1
                                        :box (:line-width -1 :style released-button)))))
;;;;; term
   `(term-color-black ((t (:foreground ,sunburn-bg
                                       :background ,sunburn-bg-1))))
   `(term-color-red ((t (:foreground ,sunburn-red-2
                                     :background ,sunburn-red-4))))
   `(term-color-green ((t (:foreground ,sunburn-green
                                       :background ,sunburn-green+2))))
   `(term-color-yellow ((t (:foreground ,sunburn-orange
                                        :background ,sunburn-yellow))))
   `(term-color-blue ((t (:foreground ,sunburn-blue-1
                                      :background ,sunburn-blue-4))))
   `(term-color-magenta ((t (:foreground ,sunburn-magenta
                                         :background ,sunburn-red))))
   `(term-color-cyan ((t (:foreground ,sunburn-cyan
                                      :background ,sunburn-blue))))
   `(term-color-white ((t (:foreground ,sunburn-fg
                                       :background ,sunburn-fg-1))))
   '(term-default-fg-color ((t (:inherit term-color-white))))
   '(term-default-bg-color ((t (:inherit term-color-black))))
;;;;; undo-tree
   `(undo-tree-visualizer-active-branch-face ((t (:foreground ,sunburn-fg+1 :weight bold))))
   `(undo-tree-visualizer-current-face ((t (:foreground ,sunburn-red-1 :weight bold))))
   `(undo-tree-visualizer-default-face ((t (:foreground ,sunburn-fg))))
   `(undo-tree-visualizer-register-face ((t (:foreground ,sunburn-yellow))))
   `(undo-tree-visualizer-unmodified-face ((t (:foreground ,sunburn-cyan))))
;;;;; visual-regexp
   `(vr/group-0 ((t (:foreground ,sunburn-bg :background ,sunburn-green :weight bold))))
   `(vr/group-1 ((t (:foreground ,sunburn-bg :background ,sunburn-orange :weight bold))))
   `(vr/group-2 ((t (:foreground ,sunburn-bg :background ,sunburn-blue :weight bold))))
   `(vr/match-0 ((t (:inherit isearch))))
   `(vr/match-1 ((t (:foreground ,sunburn-yellow-2 :background ,sunburn-bg-1 :weight bold))))
   `(vr/match-separator-face ((t (:foreground ,sunburn-red :weight bold))))
;;;;; volatile-highlights
   `(vhl/default-face ((t (:background ,sunburn-bg-05))))
;;;;; web-mode
   `(web-mode-builtin-face ((t (:inherit ,font-lock-builtin-face))))
   `(web-mode-comment-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-constant-face ((t (:inherit ,font-lock-constant-face))))
   `(web-mode-css-at-rule-face ((t (:foreground ,sunburn-orange ))))
   `(web-mode-css-prop-face ((t (:foreground ,sunburn-orange))))
   `(web-mode-css-pseudo-class-face ((t (:foreground ,sunburn-green+3 :weight bold))))
   `(web-mode-css-rule-face ((t (:foreground ,sunburn-blue))))
   `(web-mode-doctype-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-folded-face ((t (:underline t))))
   `(web-mode-function-name-face ((t (:foreground ,sunburn-blue))))
   `(web-mode-html-attr-name-face ((t (:foreground ,sunburn-orange))))
   `(web-mode-html-attr-value-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-html-tag-face ((t (:foreground ,sunburn-cyan))))
   `(web-mode-keyword-face ((t (:inherit ,font-lock-keyword-face))))
   `(web-mode-preprocessor-face ((t (:inherit ,font-lock-preprocessor-face))))
   `(web-mode-string-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-type-face ((t (:inherit ,font-lock-type-face))))
   `(web-mode-variable-name-face ((t (:inherit ,font-lock-variable-name-face))))
   `(web-mode-server-background-face ((t (:background ,sunburn-bg))))
   `(web-mode-server-comment-face ((t (:inherit web-mode-comment-face))))
   `(web-mode-server-string-face ((t (:inherit web-mode-string-face))))
   `(web-mode-symbol-face ((t (:inherit font-lock-constant-face))))
   `(web-mode-warning-face ((t (:inherit font-lock-warning-face))))
   `(web-mode-whitespaces-face ((t (:background ,sunburn-red))))
;;;;; whitespace-mode
   `(whitespace-space ((t (:background ,sunburn-bg+1 :foreground ,sunburn-bg+1))))
   `(whitespace-hspace ((t (:background ,sunburn-bg+1 :foreground ,sunburn-bg+1))))
   `(whitespace-tab ((t (:background ,sunburn-red-1))))
   `(whitespace-newline ((t (:foreground ,sunburn-bg+1))))
   `(whitespace-trailing ((t (:background ,sunburn-red))))
   `(whitespace-line ((t (:background ,sunburn-bg :foreground ,sunburn-magenta))))
   `(whitespace-space-before-tab ((t (:background ,sunburn-orange :foreground ,sunburn-orange))))
   `(whitespace-indentation ((t (:background ,sunburn-yellow :foreground ,sunburn-red))))
   `(whitespace-empty ((t (:background ,sunburn-yellow))))
   `(whitespace-space-after-tab ((t (:background ,sunburn-yellow :foreground ,sunburn-red))))
;;;;; wanderlust
   `(wl-highlight-folder-few-face ((t (:foreground ,sunburn-red-2))))
   `(wl-highlight-folder-many-face ((t (:foreground ,sunburn-red-1))))
   `(wl-highlight-folder-path-face ((t (:foreground ,sunburn-orange))))
   `(wl-highlight-folder-unread-face ((t (:foreground ,sunburn-blue))))
   `(wl-highlight-folder-zero-face ((t (:foreground ,sunburn-fg))))
   `(wl-highlight-folder-unknown-face ((t (:foreground ,sunburn-blue))))
   `(wl-highlight-message-citation-header ((t (:foreground ,sunburn-red-1))))
   `(wl-highlight-message-cited-text-1 ((t (:foreground ,sunburn-red))))
   `(wl-highlight-message-cited-text-2 ((t (:foreground ,sunburn-green+2))))
   `(wl-highlight-message-cited-text-3 ((t (:foreground ,sunburn-blue))))
   `(wl-highlight-message-cited-text-4 ((t (:foreground ,sunburn-blue+1))))
   `(wl-highlight-message-header-contents-face ((t (:foreground ,sunburn-green))))
   `(wl-highlight-message-headers-face ((t (:foreground ,sunburn-red+1))))
   `(wl-highlight-message-important-header-contents ((t (:foreground ,sunburn-green+2))))
   `(wl-highlight-message-header-contents ((t (:foreground ,sunburn-green+1))))
   `(wl-highlight-message-important-header-contents2 ((t (:foreground ,sunburn-green+2))))
   `(wl-highlight-message-signature ((t (:foreground ,sunburn-green))))
   `(wl-highlight-message-unimportant-header-contents ((t (:foreground ,sunburn-fg))))
   `(wl-highlight-summary-answered-face ((t (:foreground ,sunburn-blue))))
   `(wl-highlight-summary-disposed-face ((t (:foreground ,sunburn-fg
                                                         :slant italic))))
   `(wl-highlight-summary-new-face ((t (:foreground ,sunburn-blue))))
   `(wl-highlight-summary-normal-face ((t (:foreground ,sunburn-fg))))
   `(wl-highlight-summary-thread-top-face ((t (:foreground ,sunburn-yellow))))
   `(wl-highlight-thread-indent-face ((t (:foreground ,sunburn-magenta))))
   `(wl-highlight-summary-refiled-face ((t (:foreground ,sunburn-fg))))
   `(wl-highlight-summary-displaying-face ((t (:underline t :weight bold))))
;;;;; which-func-mode
   `(which-func ((t (:foreground ,sunburn-green+4))))
;;;;; xcscope
   `(cscope-file-face ((t (:foreground ,sunburn-yellow :weight bold))))
   `(cscope-function-face ((t (:foreground ,sunburn-cyan :weight bold))))
   `(cscope-line-number-face ((t (:foreground ,sunburn-red :weight bold))))
   `(cscope-mouse-face ((t (:foreground ,sunburn-bg :background ,sunburn-blue+1))))
   `(cscope-separator-face ((t (:foreground ,sunburn-red :weight bold
                                            :underline t :overline t))))
;;;;; yascroll
   `(yascroll:thumb-text-area ((t (:background ,sunburn-bg-1))))
   `(yascroll:thumb-fringe ((t (:background ,sunburn-bg-1 :foreground ,sunburn-bg-1))))
   ))

;;; Theme Variables
(sunburn-with-color-variables
  (custom-theme-set-variables
   'sunburn
;;;;; ansi-color
   `(ansi-color-names-vector [,sunburn-bg ,sunburn-red ,sunburn-green ,sunburn-yellow
                                          ,sunburn-blue ,sunburn-magenta ,sunburn-cyan ,sunburn-fg])
;;;;; fill-column-indicator
   `(fci-rule-color ,sunburn-bg-05)
;;;;; nrepl-client
   `(nrepl-message-colors
     '(,sunburn-red ,sunburn-orange ,sunburn-yellow ,sunburn-green ,sunburn-green+4
                    ,sunburn-cyan ,sunburn-blue+1 ,sunburn-magenta))
;;;;; pdf-tools
   `(pdf-view-midnight-colors '(,sunburn-fg . ,sunburn-bg-05))
;;;;; vc-annotate
   `(vc-annotate-color-map
     '(( 20. . ,sunburn-red-1)
       ( 40. . ,sunburn-red)
       ( 60. . ,sunburn-orange)
       ( 80. . ,sunburn-yellow-2)
       (100. . ,sunburn-yellow-1)
       (120. . ,sunburn-yellow)
       (140. . ,sunburn-green-1)
       (160. . ,sunburn-green)
       (180. . ,sunburn-green+1)
       (200. . ,sunburn-green+2)
       (220. . ,sunburn-green+3)
       (240. . ,sunburn-green+4)
       (260. . ,sunburn-cyan)
       (280. . ,sunburn-blue-2)
       (300. . ,sunburn-blue-1)
       (320. . ,sunburn-blue)
       (340. . ,sunburn-blue+1)
       (360. . ,sunburn-magenta)))
   `(vc-annotate-very-old-color ,sunburn-magenta)
   `(vc-annotate-background ,sunburn-bg-1)
   ))

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'sunburn)

;; Local Variables:
;; no-byte-compile: t
;; indent-tabs-mode: nil
;; End:
;;; sunburn-theme.el ends here
