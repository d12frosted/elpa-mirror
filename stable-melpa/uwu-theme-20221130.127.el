;;; uwu-theme.el --- An awesome dark color scheme  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Kevin Borling <kborling@protonmail.com>

;; Author: Kevin Borling
;; Created: December 24, 2021
;; Version: 1.0.0
;; Package-Version: 20221130.127
;; Package-Commit: 7c1e7eb0a004b5afd2c3241ccd07df08212c53f1
;; Keywords: custom themes, dark, faces
;; License: MIT
;; URL: https://github.com/kborling/uwu-theme
;; Homepage: https://github.com/kborling/uwu-theme
;; Filename: uwu-theme.el
;; Package-Requires: ((emacs "24.1"))

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; Inspired by uwu theme for vim <https://github.com/Mangeshrex/uwu.vim>

;; Usage:

;; If your Emacs has the `load-theme' command, you can use it to
;; activate one of these themes programatically, or use
;; `customize-themes' to select a theme interactively.

;;; Code:

(deftheme uwu "UwU color theme.")

;;; Variables
(eval-and-compile
  (defvar uwu-colors-alist
    '(("uwu-fg"             . "#C5C8C9")
      ("uwu-bg"             . "#131A1C")
      ("uwu-black"          . "#1B2224")
      ("uwu-red"            . "#F65B5B")
      ("uwu-green"          . "#6BB05D")
      ("uwu-yellow"         . "#E59E67")
      ("uwu-blue"           . "#53A7BF")
      ("uwu-magenta"        . "#B185DB")
      ("uwu-cyan"           . "#51A39F")
      ("uwu-white"          . "#C4C4C4")
      ("uwu-bright-black"   . "#232A2C")
      ("uwu-bright-red"     . "#C26F6F")
      ("uwu-bright-green"   . "#8DC776")
      ("uwu-bright-yellow"  . "#E7AC7E")
      ("uwu-bright-blue"    . "#6CBAD1")
      ("uwu-bright-magenta" . "#BB8FE5")
      ("uwu-bright-cyan"    . "#6DB0AD")
      ("uwu-bright-white"   . "#C5C8C9")
      ("uwu-comment"        . "#62686A")
      ("uwu-highlight"      . "#2F3638")
      ("uwu-warning"        . "#E6D967")
      ("uwu-error"          . "#E93D3D"))))

(defvar uwu-use-variable-pitch nil
  "When non-nil, use variable pitch face for some headings and titles.")

(defvar uwu-scale-org-headlines nil
  "Whether `org-mode' headlines should be scaled.")

(defvar uwu-scale-outline-headlines nil
  "Whether `outline-mode' headlines should be scaled.")

(defvar uwu-scale-shr-headlines nil
  "Whether `shr' headlines should be scaled.")

(defcustom uwu-distinct-line-numbers t
  "Whether line numbers should look distinct."
  :type 'boolean
  :group 'uwu-theme
  :package-version '(uwu . "1.0"))

(defcustom uwu-height-minus-1 0.8
  "Font size -1."
  :type 'number
  :group 'uwu-theme
  :package-version '(uwu . "1.0"))

(defcustom uwu-height-plus-1 1.075
  "Font size +1."
  :type 'number
  :group 'uwu-theme
  :package-version '(uwu . "1.0"))

(defcustom uwu-height-plus-2 1.1
  "Font size +1."
  :type 'number
  :group 'uwu-theme
  :package-version '(uwu . "1.0"))

(defcustom uwu-height-plus-3 1.125
  "Font size +2."
  :type 'number
  :group 'uwu-theme
  :package-version '(uwu . "1.0"))

(defcustom uwu-height-plus-4 1.15
  "Font size +3."
  :type 'number
  :group 'uwu-theme
  :package-version '(uwu . "1.0"))

(defcustom uwu-height-plus-5 1.2
  "Font size +4."
  :type 'number
  :group 'uwu-theme
  :package-version '(uwu . "1.0"))

(defcustom uwu-height-plus-6 1.3
  "Font size +5."
  :type 'number
  :group 'uwu-theme
  :package-version '(uwu . "1.0"))

(defmacro uwu-with-color-variables (&rest body)
  "`let' bind all colors defined in `uwu-colors-alist' around BODY.
Also bind `class' to ((class color) (min-colors 89))."
  (declare (indent 0))
  `(let ((class '((class color) (min-colors 89)))
         ,@(mapcar (lambda (cons)
                     (list (intern (car cons)) (cdr cons)))
                   (append uwu-colors-alist))
         (z-variable-pitch (if uwu-use-variable-pitch
                               'variable-pitch 'default)))
     ,@body))

;;; Theme Faces
(uwu-with-color-variables
  (custom-theme-set-faces 'uwu
                          '(button ((t (:underline t))))
                          `(default ((t (:background ,uwu-bg :foreground ,uwu-fg))))
                          `(cursor ((t (:background ,uwu-white :foreground ,uwu-bright-black))))
                          `(link ((t (:underline t :foreground ,uwu-blue))))
                          `(link-visited ((t (:underline t :foreground ,uwu-bright-blue))))
                          `(underline ((t (:underline t :foreground ,uwu-yellow))))
                          `(font-lock-keyword-face ((t (:foreground ,uwu-magenta))))
                          `(font-lock-function-name-face ((t (:foreground ,uwu-blue))))
                          `(font-lock-string-face ((t (:foreground ,uwu-green))))
                          `(font-lock-warning-face ((t (:inverse-video t :background ,uwu-bg :foreground ,uwu-error))))
                          `(font-lock-type-face ((t (:weight bold :foreground ,uwu-yellow))))
                          `(font-lock-preprocessor-face ((t (:foreground ,uwu-blue))))
                          `(font-lock-builtin-face ((t (:weight bold :foreground ,uwu-yellow))))
                          `(font-lock-variable-name-face ((t (:foreground ,uwu-red))))
                          `(font-lock-constant-face ((t (:foreground ,uwu-yellow))))
                          `(font-lock-doc-face ((t (:slant italic :foreground ,uwu-comment))))
                          `(font-lock-comment-face ((t (:slant italic :foreground ,uwu-comment))))
                          `(shadow ((t (:foreground ,uwu-comment))))
                          `(Info-quoted ((t (:inherit font-lock-constant-face))))
                          `(show-paren-match-face ((t (:inverse-video t :background ,uwu-white :foreground ,uwu-red))))
                          `(highline-face ((t (:background ,uwu-black))))
                          `(ac-selection-face ((t (:background ,uwu-magenta :foreground ,uwu-highlight))))
                          `(ac-candidate-face ((t (:background ,uwu-black :foreground ,uwu-white))))
                          `(flymake-errline
                            ((((supports :underline (:style wave)))
                              (:underline (:style wave :color ,uwu-error)
                                          :inherit unspecified :foreground unspecified :background unspecified))
                             (t (:foreground ,uwu-error :weight bold :underline t))))
                          `(flymake-warnline
                            ((((supports :underline (:style wave)))
                              (:underline (:style wave :color ,uwu-warning)
                                          :inherit unspecified :foreground unspecified :background unspecified))
                             (t (:foreground ,uwu-warning :weight bold :underline t))))
                          `(flymake-infoline
                            ((((supports :underline (:style wave)))
                              (:underline (:style wave :color ,uwu-green)
                                          :inherit unspecified :foreground unspecified :background unspecified))
                             (t (:foreground ,uwu-bright-green :weight bold :underline t))))
                          `(flyspell-duplicate
                            ((((supports :underline (:style wave)))
                              (:underline (:style wave :color ,uwu-yellow) :inherit unspecified))
                             (t (:foreground ,uwu-yellow :weight bold :underline t))))
                          `(flyspell-incorrect
                            ((((supports :underline (:style wave)))
                              (:underline (:style wave :color ,uwu-red) :inherit unspecified))
                             (t (:foreground ,uwu-bright-red :weight bold :underline t))))
                          `(minibuffer-prompt ((t (:foreground ,uwu-yellow))))
                          `(menu ((t (:foreground ,uwu-fg :background ,uwu-bg))))
                          `(highlight ((t (:background ,uwu-highlight))))
                          `(hl-line-face ((,class (:background ,uwu-highlight))
                                          (t :weight bold)))
                          `(hl-line ((,class (:background ,uwu-highlight :extend t))
                                     (t :weight bold)))
                          `(success ((t (:foreground ,uwu-green :weight bold))))
                          `(warning ((t (:foreground ,uwu-warning :weight bold))))
                          `(error ((t  (:foreground ,uwu-error))))
                          `(tooltip ((t (:foreground ,uwu-fg :background ,uwu-black))))
                          `(region ((t (:inverse-video t :background ,uwu-black))))
                          `(secondary-selection ((t (:background ,uwu-bright-black))))
                          `(trailing-whitespace ((t (:background ,uwu-red))))
                          `(border ((t (:background ,uwu-bright-black :foreground ,uwu-white))))
                          `(vertical-border ((t (:foreground ,uwu-bright-black))))
                          `(mode-line ((t (:foreground ,uwu-white :background ,uwu-black :weight normal
                                                       :box (:line-width 1 :color ,uwu-black)))))
                          `(mode-line-inactive ((t (:foreground ,uwu-comment :background ,uwu-black :weight normal :box (:line-width 1 :color ,uwu-black)))))
                          `(mode-line-buffer-id ((t (:weight bold :background ,uwu-black :foreground ,uwu-bright-white))))
                          `(mode-line-emphasis ((t (:foreground ,uwu-fg :slant italic))))
                          `(mode-line-highlight ((t (:foreground ,uwu-magenta :box nil :weight bold))))
                          `(fringe ((t (:underline t :background ,uwu-bg :foreground ,uwu-highlight))))
                          `(fill-column-indicator ((,class :foreground ,uwu-highlight :weight semilight)))
                          `(linum ((t (:background ,uwu-black :foreground ,uwu-white))))
                          `(line-number ((t (:foreground ,(if uwu-distinct-line-numbers uwu-white uwu-comment)
                                                         ,@(when uwu-distinct-line-numbers
                                                             (list :background uwu-black))))))
                          `(line-number-current-line ((t (:inherit line-number :foreground ,(if uwu-distinct-line-numbers uwu-bright-white uwu-white)
                                                                   ,@(when uwu-distinct-line-numbers
                                                                       (list :background uwu-highlight))))))
                          `(header-line ((t (:foreground ,uwu-yellow
                                                         :background ,uwu-black
                                                         :box (:line-width -1 :style released-button)
                                                         :extend t))))
                          `(widget-field ((t (:foreground ,uwu-fg :background ,uwu-bright-black))))
                          `(widget-button ((t (:underline t))))
                          `(escape-glyph ((t (:foreground ,uwu-yellow :weight bold))))
                          `(dired-directory ((t (:weight bold :foreground ,uwu-blue))))
                          `(lazy-highlight ((t (:foreground ,uwu-blue :background ,uwu-bg :inverse-video t))))
                          `(isearch ((t (:inverse-video t :background ,uwu-highlight :foreground ,uwu-bright-blue))))
                          `(isearch-fail ((t (:background ,uwu-bg :inherit font-lock-warning-face :inverse-video t))))
                          `(isearch-lazy-highlight-face ((t (:inverse-video t :foreground ,uwu-yellow))))
                          `(grep-context-face ((t (:foreground ,uwu-fg))))
                          `(grep-error-face ((t (:foreground ,uwu-red :weight bold :underline t))))
                          `(grep-hit-face ((t (:foreground ,uwu-bright-blue))))
                          `(grep-match-face ((t (:foreground ,uwu-bright-blue :weight bold))))
                          `(match ((t (:background ,uwu-black :foreground ,uwu-bright-blue :weight bold))))
                          `(completions-annotations ((t (:foreground ,uwu-white))))
                          `(completions-common-part ((t (:foreground ,uwu-bright-blue))))
                          `(completions-first-difference ((t (:inherit bold :foreground ,uwu-white))))
                          ;; ido
                          `(ido-first-match ((t (:foreground ,uwu-blue :weight bold))))
                          `(ido-only-match ((t (:foreground ,uwu-green :weight bold))))
                          `(ido-subdir ((t (:foreground ,uwu-yellow))))
                          `(ido-indicator ((t (:foreground ,uwu-yellow :background ,uwu-bright-red))))
                          ;; org-mode
                          `(org-agenda-date-today
                            ((t (:foreground ,uwu-fg :slant italic :weight bold))) t)
                          `(org-agenda-structure
                            ((t (:inherit font-lock-comment-face))))
                          `(org-archived ((t (:foreground ,uwu-fg :weight bold))))
                          `(org-block ((t (:background ,uwu-black :foreground ,uwu-white :extend t))))
                          `(org-block-begin-line ((t (:foreground ,uwu-comment :background ,uwu-black :extend t))))
                          `(org-code ((t (:foreground ,uwu-bright-yellow ))))
                          `(org-checkbox ((t (:background ,uwu-bg :foreground ,uwu-fg
                                                          :box (:line-width 1 :style released-button)))))
                          `(org-date ((t (:foreground ,uwu-blue :underline t))))
                          `(org-deadline-announce ((t (:foreground ,uwu-red))))
                          `(org-done ((t (:weight bold :weight bold :foreground ,uwu-green))))
                          `(org-formula ((t (:foreground ,uwu-yellow))))
                          `(org-headline-done ((t (:foreground ,uwu-green))))
                          `(org-hide ((t (:background ,uwu-bg :foreground ,uwu-bg))))
                          `(org-verbatim ((t (:foreground ,uwu-bright-yellow))))
                          `(org-meta-line ((t (:foreground ,uwu-comment))))
                          `(org-indent ((t (:background ,uwu-bg :foreground ,uwu-bg))))
                          `(org-level-1 ((t (:inherit ,z-variable-pitch :foreground ,uwu-bright-blue
                                                      ,@(when uwu-scale-org-headlines
                                                          (list :height uwu-height-plus-6))))))
                          `(org-level-2 ((t (:inherit ,z-variable-pitch :foreground ,uwu-bright-green
                                                      ,@(when uwu-scale-org-headlines
                                                          (list :height uwu-height-plus-5))))))
                          `(org-level-3 ((t (:inherit ,z-variable-pitch :foreground ,uwu-bright-magenta
                                                      ,@(when uwu-scale-org-headlines
                                                          (list :height uwu-height-plus-4))))))
                          `(org-level-4 ((t (:inherit ,z-variable-pitch :foreground ,uwu-bright-red
                                                      ,@(when uwu-scale-org-headlines
                                                          (list :height uwu-height-plus-3))))))
                          `(org-level-5 ((t (:inherit ,z-variable-pitch :foreground ,uwu-blue
                                                      ,@(when uwu-scale-org-headlines
                                                          (list :height uwu-height-plus-2))))))
                          `(org-level-6 ((t (:inherit ,z-variable-pitch :foreground ,uwu-green
                                                      ,@(when uwu-scale-org-headlines
                                                          (list :height uwu-height-plus-1))))))
                          `(org-level-7 ((t (:inherit ,z-variable-pitch :foreground ,uwu-magenta))))
                          `(org-level-8 ((t (:inherit ,z-variable-pitch :foreground ,uwu-red))))
                          `(org-link ((t (:foreground ,uwu-blue :underline t))))
                          `(org-scheduled ((t (:foreground ,uwu-green))))
                          `(org-scheduled-previously ((t (:foreground ,uwu-red))))
                          `(org-scheduled-today ((t (:foreground ,uwu-blue))))
                          `(org-sexp-date ((t (:foreground ,uwu-blue :underline t))))
                          `(org-special-keyword ((t (:inherit font-lock-comment-face))))
                          `(org-table ((t (:foreground ,uwu-blue))))
                          `(org-tag ((t (:weight bold :weight bold))))
                          `(org-time-grid ((t (:foreground ,uwu-yellow))))
                          `(org-todo ((t (:weight bold :foreground ,uwu-red :weight bold))))
                          `(org-upcoming-deadline ((t (:inherit font-lock-keyword-face))))
                          `(org-warning ((t (:weight bold :foreground ,uwu-error :weight bold :underline nil))))
                          `(org-column ((t (:background ,uwu-bg))))
                          `(org-column-title ((t (:background ,uwu-bg :underline t :weight bold))))
                          `(org-mode-line-clock ((t (:foreground ,uwu-fg :background ,uwu-bg))))
                          `(org-mode-line-clock-overrun ((t (:foreground ,uwu-bg :background ,uwu-red))))
                          `(org-ellipsis ((t (:foreground ,uwu-yellow :underline t))))
                          `(org-footnote ((t (:foreground ,uwu-cyan :underline t))))
                          `(org-document-title ((t (:inherit ,z-variable-pitch :foreground ,uwu-bright-blue
                                                             :weight bold
                                                             ,@(when uwu-scale-org-headlines
                                                                 (list :height uwu-height-plus-4))))))
                          `(org-document-info ((t (:foreground ,uwu-magenta))))
                          `(org-document-info-keyword ((t (:foreground ,uwu-comment))))
                          `(org-habit-ready-face ((t :background ,uwu-green)))
                          `(org-habit-alert-face ((t :background ,uwu-yellow :foreground ,uwu-bg)))
                          `(org-habit-clear-face ((t :background ,uwu-blue)))
                          `(org-habit-overdue-face ((t :background ,uwu-red)))
                          `(org-habit-clear-future-face ((t :background ,uwu-blue)))
                          `(org-habit-ready-future-face ((t :background ,uwu-green)))
                          `(org-habit-alert-future-face ((t :background ,uwu-yellow :foreground ,uwu-bg)))
                          `(org-habit-overdue-future-face ((t :background ,uwu-red)))
                          ;; org-ref
                          `(org-ref-ref-face ((t :underline t)))
                          `(org-ref-label-face ((t :underline t)))
                          `(org-ref-cite-face ((t :underline t)))
                          `(org-ref-glossary-face ((t :underline t)))
                          `(org-ref-acronym-face ((t :underline t)))
                          ;; flycheck
                          `(flycheck-error
                            ((((supports :underline (:style wave)))
                              (:underline (:style wave :color ,uwu-error) :inherit unspecified))
                             (t (:foreground ,uwu-error :weight bold :underline t))))
                          `(flycheck-warning
                            ((((supports :underline (:style wave)))
                              (:underline (:style wave :color ,uwu-warning) :inherit unspecified))
                             (t (:foreground ,uwu-warning :weight bold :underline t))))
                          `(flycheck-info
                            ((((supports :underline (:style wave)))
                              (:underline (:style wave :color ,uwu-cyan) :inherit unspecified))
                             (t (:foreground ,uwu-cyan :weight bold :underline t))))
                          `(flycheck-fringe-error ((t (:foreground ,uwu-error :weight bold))))
                          `(flycheck-fringe-warning ((t (:foreground ,uwu-warning :weight bold))))
                          `(flycheck-fringe-info ((t (:foreground ,uwu-cyan :weight bold))))
                          ;; company-mode
                          `(company-tooltip ((t (:foreground ,uwu-fg :background ,uwu-black))))
                          `(company-tooltip-annotation ((t (:foreground ,uwu-blue :background ,uwu-black))))
                          `(company-tooltip-annotation-selection ((t (:foreground ,uwu-blue :background ,uwu-black))))
                          `(company-tooltip-selection ((t (:foreground ,uwu-bright-white :background ,uwu-highlight))))
                          `(company-tooltip-mouse ((t (:background ,uwu-black))))
                          `(company-tooltip-common ((t (:foreground ,uwu-green))))
                          `(company-tooltip-common-selection ((t (:foreground ,uwu-green))))
                          `(company-scrollbar-fg ((t (:background ,uwu-black))))
                          `(company-scrollbar-bg ((t (:background ,uwu-bright-black))))
                          `(company-preview ((t (:background ,uwu-bright-green))))
                          `(company-preview-common ((t (:foreground ,uwu-bright-green :background ,uwu-black))))
                          ;; term, ansi-term, vterm
                          `(term-color-black ((t (:foreground ,uwu-bg
                                                              :background , uwu-bg))))
                          `(term-color-red ((t (:foreground ,uwu-red
                                                            :background ,uwu-bright-red))))
                          `(term-color-green ((t (:foreground ,uwu-green
                                                              :background ,uwu-bright-green))))
                          `(term-color-yellow ((t (:foreground ,uwu-yellow
                                                               :background ,uwu-bright-yellow))))
                          `(term-color-blue ((t (:foreground ,uwu-blue
                                                             :background ,uwu-bright-blue))))
                          `(term-color-magenta ((t (:foreground ,uwu-magenta
                                                                :background ,uwu-bright-magenta))))
                          `(term-color-cyan ((t (:foreground ,uwu-cyan
                                                             :background ,uwu-bright-cyan))))
                          `(term-color-white ((t (:foreground ,uwu-fg
                                                              :background ,uwu-fg))))
                          '(term-default-fg-color ((t (:inherit uwu-fg))))
                          '(term-default-bg-color ((t (:inherit uwu-bg))))
                          ;; diff-mode
                          `(diff-added ((t (:foreground ,uwu-bright-green :background: ,uwu-black :extend t))))
                          `(diff-changed ((t  (:foreground ,uwu-warning :background: ,uwu-black :extend t))))
                          `(diff-removed ((t (:foreground ,uwu-error :background: ,uwu-black :extend t))))
                          `(diff-indicator-added ((t (:inherit diff-added))))
                          `(diff-indicator-changed ((t (:inherit diff-changed))))
                          `(diff-indicator-removed ((t (:inherit diff-removed))))
                          `(diff-refine-added   ((t (:background ,uwu-bright-green :foreground ,uwu-black))))
                          `(diff-refine-changed ((t (:background ,uwu-warning :foreground ,uwu-black))))
                          `(diff-refine-removed ((t (:background ,uwu-error :foreground ,uwu-black))))
                          `(diff-header ((,class (:background ,uwu-black))
                                         (t (:background ,uwu-fg :foreground ,uwu-bg))))
                          `(diff-file-header
                            ((,class (:background ,uwu-black :foreground ,uwu-fg :weight bold))
                             (t (:background ,uwu-fg :foreground ,uwu-bg :weight bold))))
                          ;; diff-hl
                          `(diff-hl-change ((,class (:inverse-video t :foreground ,uwu-warning :background ,uwu-bg))))
                          `(diff-hl-delete ((,class (:inverse-video t :foreground ,uwu-error :background ,uwu-bg))))
                          `(diff-hl-insert ((,class (:inverse-video t :foreground ,uwu-bright-green :background ,uwu-bg))))
                          ;; tab-bar
                          `(tab-bar ((t (:height 1.1 :foreground ,uwu-white :background ,uwu-black))))
                          `(tab-bar-tab ((t (:background ,uwu-black
                                                         :foreground ,uwu-magenta
                                                         :box (:line-width 1 :style released-button)))))
                          `(tab-bar-tab-inactive ((t (:inherit tab-bar-tab
                                                               :background ,uwu-black
                                                               :foreground ,uwu-comment))))

                          ;; tab-line
                          `(tab-line ((t (:foreground ,uwu-white :background ,uwu-black))))
                          `(tab-line-close-highlight ((t (:foreground ,uwu-red))))
                          `(tab-line-tab ((t (:background ,uwu-black
                                                          :foreground ,uwu-magenta
                                                          :box (:line-width 1 :style released-button)))))
                          `(tab-line-tab-inactive ((t (:inherit tab-line-tab
                                                                :background ,uwu-black
                                                                :foreground ,uwu-comment))))
                          ;; spaceline
                          `(spaceline-flycheck-error  ((t (:foreground ,uwu-error))))
                          `(spaceline-flycheck-info   ((t (:foreground ,uwu-cyan))))
                          `(spaceline-flycheck-warning((t (:foreground ,uwu-warning))))
                          ;; powerline
                          `(powerline-active1 ((t (:background ,uwu-black :foreground ,uwu-white))))
                          `(powerline-active2 ((t (:background ,uwu-black :foreground ,uwu-white))))
                          `(powerline-inactive1 ((t (:background ,uwu-black :foreground ,uwu-comment))))
                          `(powerline-inactive2 ((t (:background ,uwu-black :foreground ,uwu-comment))))
                          ;; consult
                          `(consult-async-split ((t (:inherit warning))))
                          `(consult-key ((t (:inherit uwu-magenta))))
                          `(consult-line-number ((t (:foreground ,(if uwu-distinct-line-numbers uwu-white uwu-comment)
                                                         ,@(when uwu-distinct-line-numbers
                                                             (list :background uwu-black))))))
                          `(consult-separator ((t (:foreground ,uwu-bright-black))))
                          ;; embark
                          `(embark-keybinding ((t (:foreground ,uwu-magenta))))
                          `(embark-keybinding-repeat ((t (:inherit bold))))
                          `(embark-collect-group-title ((t (:inherit bold :foreground ,uwu-green))))
                          `(embark-collect-zebra-highlight ((t (:background ,uwu-black))))
                          ;; vertico
                          `(vertico-current ((t (:background ,uwu-black :foreground ,uwu-yellow :weight bold))))
                          `(vertico-multiline ((t (:foreground ,uwu-green :weight bold))))
                          `(vertico-group-title ((t (:foreground ,uwu-green :weight bold))))
                          `(vertico-group-separator ((t (:foreground ,uwu-green :weight bold))))
                          ;; selectrum
                          `(selectrum-current-candidate ((t (:background ,uwu-black :foreground ,uwu-yellow :weight bold))))
                          `(selectrum-primary-highlight ((t (:foreground ,uwu-blue :weight bold))))
                          `(selectrum-secondary-highlight ((t (:foreground ,uwu-magenta :weight bold))))
                          ;; orderless
                          `(orderless-match-face-0 ((t (:foreground ,uwu-blue))))
                          `(orderless-match-face-1 ((t (:foreground ,uwu-magenta))))
                          `(orderless-match-face-2 ((t (:foreground ,uwu-green))))
                          `(orderless-match-face-3 ((t (:foreground ,uwu-cyan))))
                          ;; helm
                          `(helm-header
                            ((t (:foreground ,uwu-green
                                             :background ,uwu-bg
                                             :underline nil
                                             :box nil
                                             :extend t))))
                          `(helm-source-header
                            ((t (:foreground ,uwu-yellow
                                             :background ,uwu-black
                                             :underline nil
                                             :weight bold
                                             :box (:line-width -1 :style released-button)
                                             :extend t))))
                          `(helm-selection ((t (:background ,uwu-black :weight bold :underline nil))))
                          `(helm-selection-line ((t (:background ,uwu-black))))
                          `(helm-visible-mark ((t (:foreground ,uwu-bg :background ,uwu-bright-yellow))))
                          `(helm-candidate-number ((t (:foreground ,uwu-green :background ,uwu-black))))
                          `(helm-separator ((t (:foreground ,uwu-red :background ,uwu-bg))))
                          `(helm-time-zone-current ((t (:foreground ,uwu-green :background ,uwu-bg))))
                          `(helm-time-zone-home ((t (:foreground ,uwu-red :background ,uwu-bg))))
                          `(helm-bookmark-addressbook ((t (:foreground ,uwu-yellow :background ,uwu-bg))))
                          `(helm-bookmark-directory ((t (:foreground nil :background nil :inherit helm-ff-directory))))
                          `(helm-bookmark-file ((t (:foreground nil :background nil :inherit helm-ff-file))))
                          `(helm-bookmark-gnus ((t (:foreground ,uwu-magenta :background ,uwu-bg))))
                          `(helm-bookmark-info ((t (:foreground ,uwu-green :background ,uwu-bg))))
                          `(helm-bookmark-man ((t (:foreground ,uwu-yellow :background ,uwu-bg))))
                          `(helm-bookmark-w3m ((t (:foreground ,uwu-magenta :background ,uwu-bg))))
                          `(helm-buffer-not-saved ((t (:foreground ,uwu-red :background ,uwu-bg))))
                          `(helm-buffer-process ((t (:foreground ,uwu-cyan :background ,uwu-bg))))
                          `(helm-buffer-saved-out ((t (:foreground ,uwu-fg :background ,uwu-bg))))
                          `(helm-buffer-size ((t (:foreground ,uwu-white :background ,uwu-bg))))
                          `(helm-ff-directory ((t (:foreground ,uwu-cyan :background ,uwu-bg :weight bold))))
                          `(helm-ff-file ((t (:foreground ,uwu-fg :background ,uwu-bg :weight normal))))
                          `(helm-ff-file-extension ((t (:foreground ,uwu-fg :background ,uwu-bg :weight normal))))
                          `(helm-ff-executable ((t (:foreground ,uwu-green :background ,uwu-bg :weight normal))))
                          `(helm-ff-invalid-symlink ((t (:foreground ,uwu-red :background ,uwu-bg :weight bold))))
                          `(helm-ff-symlink ((t (:foreground ,uwu-yellow :background ,uwu-bg :weight bold))))
                          `(helm-ff-prefix ((t (:foreground ,uwu-bg :background ,uwu-yellow :weight normal))))
                          `(helm-grep-cmd-line ((t (:foreground ,uwu-cyan :background ,uwu-bg))))
                          `(helm-grep-file ((t (:foreground ,uwu-fg :background ,uwu-bg))))
                          `(helm-grep-finish ((t (:foreground ,uwu-green :background ,uwu-bg))))
                          `(helm-grep-lineno ((t (:foreground ,uwu-white :background ,uwu-bg))))
                          `(helm-grep-match ((t (:foreground nil :background nil :inherit helm-match))))
                          `(helm-grep-running ((t (:foreground ,uwu-red :background ,uwu-bg))))
                          `(helm-match ((t (:foreground ,uwu-yellow :background ,uwu-black :weight bold))))
                          `(helm-match-item ((t (:foreground ,uwu-yellow :background ,uwu-black :weight bold))))
                          `(helm-moccur-buffer ((t (:foreground ,uwu-cyan :background ,uwu-bg))))
                          `(helm-mu-contacts-address-face ((t (:foreground ,uwu-white :background ,uwu-bg))))
                          `(helm-mu-contacts-name-face ((t (:foreground ,uwu-fg :background ,uwu-bg))))
                          ;; ivy
                          `(ivy-confirm-face ((t (:foreground ,uwu-green :background ,uwu-bg))))
                          `(ivy-current-match ((t (:foreground ,uwu-yellow :background ,uwu-black :weight bold))))
                          `(ivy-cursor ((t (:foreground ,uwu-bg :background ,uwu-fg))))
                          `(ivy-match-required-face ((t (:foreground ,uwu-red :background ,uwu-bg :weight bold))))
                          `(ivy-minibuffer-match-face-1 ((t (:foreground ,uwu-magenta :weight bold ))))
                          `(ivy-minibuffer-match-face-2 ((t (:foreground ,uwu-blue :weight bold))))
                          `(ivy-minibuffer-match-face-3 ((t (:foreground ,uwu-green :weight bold))))
                          `(ivy-minibuffer-match-face-4 ((t (:foreground ,uwu-cyan :weight bold))))
                          `(ivy-remote ((t (:foreground ,uwu-blue :background ,uwu-bg))))
                          `(ivy-subdir ((t (:foreground ,uwu-yellow :background ,uwu-bg))))
                          ;; swiper
                          `(swiper-line-face ((t (:background ,uwu-highlight))))
                          ;; helpful
                          `(helpful-heading ((t (:foreground ,uwu-bright-green :height 1.2))))
                          ;; which function
                          `(which-func ((t (:foreground ,uwu-blue))))
                          ;; rainbow-delimiters
                          `(rainbow-delimiters-depth-1-face ((t (:foreground ,uwu-bright-blue))))
                          `(rainbow-delimiters-depth-2-face ((t (:foreground ,uwu-bright-green))))
                          `(rainbow-delimiters-depth-3-face ((t (:foreground ,uwu-bright-magenta))))
                          `(rainbow-delimiters-depth-4-face ((t (:foreground ,uwu-bright-yellow))))
                          `(rainbow-delimiters-depth-5-face ((t (:foreground ,uwu-bright-red))))
                          `(rainbow-delimiters-depth-6-face ((t (:foreground ,uwu-bright-cyan))))
                          `(rainbow-delimiters-depth-7-face ((t (:foreground ,uwu-blue))))
                          `(rainbow-delimiters-depth-8-face ((t (:foreground ,uwu-green))))
                          `(rainbow-delimiters-depth-9-face ((t (:foreground ,uwu-magenta))))
                          `(rainbow-delimiters-depth-10-face ((t (:foreground ,uwu-yellow))))
                          `(rainbow-delimiters-depth-11-face ((t (:foreground ,uwu-red))))
                          `(rainbow-delimiters-depth-12-face ((t (:foreground ,uwu-cyan))))
                          ;; gnus
                          `(gnus-group-mail-1 ((t (:weight bold :inherit gnus-group-mail-1-empty))))
                          `(gnus-group-mail-1-empty ((t (:inherit gnus-group-news-1-empty))))
                          `(gnus-group-mail-2 ((t (:weight bold :inherit gnus-group-mail-2-empty))))
                          `(gnus-group-mail-2-empty ((t (:inherit gnus-group-news-2-empty))))
                          `(gnus-group-mail-3 ((t (:weight bold :inherit gnus-group-mail-3-empty))))
                          `(gnus-group-mail-3-empty ((t (:inherit gnus-group-news-3-empty))))
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
                          `(gnus-header-from ((t (:inherit message-header-other))))
                          `(gnus-header-name ((t (:inherit message-header-name))))
                          `(gnus-header-newsgroups ((t (:inherit message-header-other))))
                          `(gnus-header-subject ((t (:inherit message-header-subject))))
                          `(gnus-summary-cancelled ((t (:foreground ,uwu-yellow))))
                          `(gnus-summary-high-ancient ((t (:foreground ,uwu-blue :weight bold))))
                          `(gnus-summary-high-read ((t (:foreground ,uwu-green :weight bold))))
                          `(gnus-summary-high-ticked ((t (:foreground ,uwu-yellow :weight bold))))
                          `(gnus-summary-high-unread ((t (:foreground ,uwu-fg :weight bold))))
                          `(gnus-summary-low-ancient ((t (:foreground ,uwu-blue))))
                          `(gnus-summary-low-read ((t (:foreground ,uwu-green))))
                          `(gnus-summary-low-ticked ((t (:foreground ,uwu-yellow))))
                          `(gnus-summary-low-unread ((t (:foreground ,uwu-fg))))
                          `(gnus-summary-normal-ancient ((t (:foreground ,uwu-blue))))
                          `(gnus-summary-normal-read ((t (:foreground ,uwu-green))))
                          `(gnus-summary-normal-ticked ((t (:foreground ,uwu-yellow))))
                          `(gnus-summary-normal-unread ((t (:foreground ,uwu-fg))))
                          `(gnus-summary-selected ((t (:foreground ,uwu-yellow :weight bold))))
                          `(gnus-cite-1 ((t (:foreground ,uwu-blue))))
                          `(gnus-cite-2 ((t (:foreground ,uwu-blue))))
                          `(gnus-cite-3 ((t (:foreground ,uwu-blue))))
                          `(gnus-cite-4 ((t (:foreground ,uwu-green))))
                          `(gnus-cite-5 ((t (:foreground ,uwu-green))))
                          `(gnus-cite-6 ((t (:foreground ,uwu-green))))
                          `(gnus-cite-7 ((t (:foreground ,uwu-red))))
                          `(gnus-cite-8 ((t (:foreground ,uwu-red))))
                          `(gnus-cite-9 ((t (:foreground ,uwu-red))))
                          `(gnus-cite-10 ((t (:foreground ,uwu-yellow))))
                          `(gnus-cite-11 ((t (:foreground ,uwu-yellow))))
                          `(gnus-group-news-1-empty ((t (:foreground ,uwu-yellow))))
                          `(gnus-group-news-2-empty ((t (:foreground ,uwu-green))))
                          `(gnus-group-news-3-empty ((t (:foreground ,uwu-green))))
                          `(gnus-group-news-4-empty ((t (:foreground ,uwu-blue))))
                          `(gnus-group-news-5-empty ((t (:foreground ,uwu-blue))))
                          `(gnus-group-news-6-empty ((t (:foreground ,uwu-bright-blue))))
                          `(gnus-group-news-low-empty ((t (:foreground ,uwu-comment))))
                          `(gnus-signature ((t (:foreground ,uwu-yellow))))
                          `(gnus-x-face ((t (:background ,uwu-bg :foreground ,uwu-comment))))
                          ;; shr
                          `(shr-h1 ((t (:inherit ,z-variable-pitch :foreground ,uwu-bright-blue
                                                 ,@(when uwu-scale-shr-headlines
                                                     (list :height uwu-height-plus-6))))))
                          `(shr-h2 ((t (:inherit ,z-variable-pitch :foreground ,uwu-bright-green
                                                 ,@(when uwu-scale-shr-headlines
                                                     (list :height uwu-height-plus-5))))))
                          `(shr-h3 ((t (:inherit ,z-variable-pitch :foreground ,uwu-bright-magenta
                                                 ,@(when uwu-scale-shr-headlines
                                                     (list :height uwu-height-plus-4))))))
                          `(shr-h4 ((t (:inherit ,z-variable-pitch :foreground ,uwu-bright-red
                                                 ,@(when uwu-scale-shr-headlines
                                                     (list :height uwu-height-plus-3))))))
                          `(shr-h5 ((t (:inherit ,z-variable-pitch :foreground ,uwu-blue
                                                 ,@(when uwu-scale-shr-headlines
                                                     (list :height uwu-height-plus-2))))))
                          `(shr-h6 ((t (:inherit ,z-variable-pitch :foreground ,uwu-green
                                                 ,@(when uwu-scale-shr-headlines
                                                     (list :height uwu-height-plus-1))))))
                          `(shr-code ((t (:foreground ,uwu-bright-yellow ))))
                          `(shr-link ((t (:inherit link))))
                          `(shr-selected-link ((t (:inherit link-visited))))
                          ;; message
                          `(message-cited-text ((t (:inherit font-lock-comment-face))))
                          `(message-header-name ((t (:foreground ,uwu-comment))))
                          `(message-header-other ((t (:foreground ,uwu-magenta))))
                          `(message-header-to ((t (:foreground ,uwu-yellow :weight bold))))
                          `(message-header-cc ((t (:foreground ,uwu-yellow :weight bold))))
                          `(message-header-newsgroups ((t (:foreground ,uwu-yellow :weight bold))))
                          `(message-header-subject ((t (:foreground ,uwu-bright-blue :weight bold))))
                          `(message-header-xheader ((t (:foreground ,uwu-magenta))))
                          `(message-mml ((t (:foreground ,uwu-yellow :weight bold))))
                          `(message-separator ((t (:inherit font-lock-comment-face))))
                          `(message-cited-text-1 ((t (:foreground ,uwu-blue))))
                          `(message-cited-text-2 ((t (:foreground ,uwu-green))))
                          `(message-cited-text-3 ((t (:foreground ,uwu-yellow))))
                          `(message-cited-text-4 ((t (:foreground ,uwu-red))))
                          `(mm-uu-extract ((t (:background ,uwu-black :foreground ,uwu-bright-green))))
                          ;; notmuch
                          `(notmuch-crypto-decryption ((t (:foreground ,uwu-bg :background ,uwu-magenta))))
                          `(notmuch-crypto-part-header ((t (:foreground ,uwu-bright-blue))))
                          `(notmuch-crypto-signature-bad ((t (:foreground ,uwu-bg :background ,uwu-error))))
                          `(notmuch-crypto-signature-good ((t (:foreground ,uwu-bg :background ,uwu-green))))
                          `(notmuch-crypto-signature-good-key ((t (:foreground ,uwu-bg :background ,uwu-yellow))))
                          `(notmuch-crypto-signature-unknown ((t (:foreground ,uwu-bg :background ,uwu-error))))
                          `(notmuch-hello-logo-background ((t (:background ,uwu-black))))
                          `(notmuch-wash-cited-text ((t (:foreground ,uwu-cyan))))
                          `(notmuch-tag-face ((t (:foreground ,uwu-yellow))))
                          `(notmuch-tag-unread ((t (:foreground ,uwu-magenta))))
                          `(notmuch-tag-added ((t (:underline ,uwu-green))))
                          `(notmuch-tag-deleted ((t (:strike-through ,uwu-red))))
                          `(notmuch-tag-flagged ((t (:foreground ,uwu-blue))));
                          `(notmuch-message-summary-face ((t (:inherit highlight))))
                          `(notmuch-search-date ((t (:inherit default))))
                          `(notmuch-search-count ((t (:inherit default))))
                          `(notmuch-search-subject ((t (:inherit default))))
                          `(notmuch-search-matching-authors ((t (:inherit default))))
                          `(notmuch-search-non-matching-authors ((t (:inherit shadow))))
                          `(notmuch-search-flagged-face ((t (:foreground ,uwu-blue))))
                          `(notmuch-search-unread-face ((t (:weight bold))))
                          `(notmuch-tree-match-author-face ((t (:foreground ,uwu-blue))))
                          `(notmuch-tree-match-date-face ((t (:foreground ,uwu-yellow))))
                          `(notmuch-tree-match-tag-face ((t (:foreground ,uwu-cyan))))
                          `(notmuch-tree-no-match-face ((t (:inherit font-lock-comment-face))))
                          ;; mu4e
                          `(mu4e-unread-face ((t (:foreground ,uwu-green :weight normal))))
                          `(mu4e-replied-face ((t (:foreground ,uwu-comment))))
                          `(mu4e-flagged-face ((t (:foreground ,uwu-blue :weight normal))))
                          `(mu4e-warning-face ((t (:foreground ,uwu-red :slant normal :weight bold))))
                          `(mu4e-trashed-face ((t (:foreground ,uwu-comment :strike-through t))))
                          `(mu4e-cited-1-face ((t (:foreground ,uwu-bright-blue :slant italic :weight normal))))
                          `(mu4e-cited-2-face ((t (:foreground ,uwu-bright-green :slant italic :weight normal))))
                          `(mu4e-cited-3-face ((t (:foreground ,uwu-bright-magenta :slant italic :weight normal))))
                          `(mu4e-cited-4-face ((t (:foreground ,uwu-bright-red :slant italic :weight normal))))
                          `(mu4e-cited-5-face ((t (:foreground ,uwu-blue :slant italic :weight normal))))
                          `(mu4e-cited-6-face ((t (:foreground ,uwu-green :slant italic :weight normal))))
                          `(mu4e-cited-7-face ((t (:foreground ,uwu-magenta :slant italic :weight normal))))
                          `(mu4e-view-url-number-face ((t (:foreground ,uwu-yellow :weight normal))))
                          `(mu4e-header-highlight-face
                            ((t (,@(and (>= emacs-major-version 27) '(:extend t))
                                 :inherit unspecified
                                 :foreground unspecified :background ,uwu-bg
                                 :underline unspecified  :weight unspecified))))
                          `(mu4e-view-contact-face ((t (:foreground ,uwu-fg  :weight normal))))
                          `(mu4e-view-header-key-face ((t (:inherit message-header-name :weight normal))))
                          `(mu4e-view-header-value-face ((t (:foreground ,uwu-cyan :weight normal :slant normal))))
                          `(mu4e-view-link-face ((t (:inherit link))))
                          `(mu4e-view-special-header-value-face ((t (:foreground ,uwu-blue :weight normal :underline nil))))))

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'uwu)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; uwu-theme.el ends here
