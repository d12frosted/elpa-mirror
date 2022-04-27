;;; mandm-theme.el --- An M&M color theme.

;; Copyright (C) 2016-2017 Christian E. Hopps
;; Copyright (C) 2011-2014 Bozhidar Batsov

;; Author: Christian Hopps <chopps@gmail.com>
;; URL: https://github.com/choppsv1/emacs-mandm-theme.git
;; Package-Version: 20220426.1131
;; Package-Commit: 4991bbc4b17308f5dc53742dc528cbfdc467ee01

;; Author: Bozhidar Batsov <bozhidar@batsov.com>
;; URL: http://github.com/bbatsov/zenburn
;; Version: 20141112.923
;; X-Original-Version: 2.3-cvs

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

;; This is a port of zenburn-theme, replacing the colors with M&M
;; colors.

;;; Credits:

;; Bozhidar Batsov created the zenburn theme for emacs on such this port
;; is based.
;; Jani Nurminen created the original theme for vim on such this port
;; is based.

;;; Code:

(require 'color)

(setq                                 ; a little dark
 mmyellow-color "#FFF200"             ; "#FCBB47"
 mmblue-color   "#0168A3"             ; "#0168A3"
 mmgreen-color "#57CD7F"              ; "#57CD7F"
 mmorange-color "#FF7509"             ; "#FF7509"
 mmred-color "#EE3932"                ; "#EE3932"
 mmbrown-color "#441B02"              ; I made this up
 mmfg-color "#dcdcdc"                 ; zenburn fg
 mmbg-color "#011827"                 ; This is nicer than the darkbrown
 )

;; (setq mmbg-color (color-darken-name (color-desaturate-name mmbrown-color 10) 10))
;; (setq mmbg-color (color-darken-name (color-desaturate-name mmblue-color 10) 22))

(deftheme mandm "The M&M color theme")

(defcustom mandm-height-minus-1 0.8
  "Font size -1."
  :type 'number
  :group 'mandm)

(defcustom mandm-height-plus-1 1.1
  "Font size +1."
  :type 'number
  :group 'mandm)

(defcustom mandm-height-plus-2 1.15
  "Font size +2."
  :type 'number
  :group 'mandm)

(defcustom mandm-height-plus-3 1.2
  "Font size +3."
  :type 'number
  :group 'mandm)

(defcustom mandm-height-plus-4 1.3
  "Font size +4."
  :type 'number
  :group 'mandm)


;;; Color Palette


(defvar mandm-colors-alist
  `(("mandm-fg+2"     . ,(color-lighten-name mmfg-color 22))
    ("mandm-fg+1"     . ,(color-lighten-name mmfg-color 12))
    ("mandm-fg+05"    . ,(color-lighten-name mmfg-color 5))
    ("mandm-fg"       . ,mmfg-color)
    ("mandm-fg-1"     . ,(color-darken-name mmfg-color 10))
    ("mandm-fg-2"     . ,(color-darken-name mmfg-color 20))
    ("mandm-fg-4"     . ,(color-darken-name mmfg-color 40))
    ("mandm-bg+3"     . ,(color-lighten-name mmbg-color 33))
    ("mandm-bg+2"     . ,(color-lighten-name mmbg-color 23))
    ("mandm-bg+1"     . ,(color-lighten-name mmbg-color 13))
    ("mandm-bg+05"    . ,(color-lighten-name mmbg-color 5))
    ("mandm-bg"       . ,mmbg-color)
    ("mandm-bg-05"    . ,(color-darken-name mmbg-color 5))
    ("mandm-bg-1"     . ,(color-darken-name mmbg-color 10))
    ("mandm-bg-2"     . ,(color-darken-name mmbg-color 20))
    ("mandm-bg-3"     . ,(color-darken-name mmbg-color 30))
    ("mandm-red+1"    . ,(color-lighten-name mmred-color 10))
    ("mandm-red"      . ,mmred-color)
    ("mandm-red-1"    . ,(color-darken-name mmred-color 5))
    ("mandm-red-2"    . ,(color-darken-name mmred-color 10))
    ("mandm-red-3"    . ,(color-darken-name mmred-color 15))
    ("mandm-red-4"    . ,(color-darken-name mmred-color 20))
    ("mandm-orange+1" . ,(color-lighten-name mmorange-color 10))
    ("mandm-orange"   . ,mmorange-color)
    ("mandm-orange-1" . ,(color-darken-name mmorange-color 10))
    ("mandm-yellow"   . ,mmyellow-color)
    ("mandm-yellow-1" . ,(color-darken-name mmyellow-color 3))
    ("mandm-yellow-2" . ,(color-darken-name mmyellow-color 6))
    ("mandm-yellow-5" . ,(color-darken-name mmyellow-color 20))
    ("mandm-green+4"  . ,(color-lighten-name mmgreen-color 12))
    ("mandm-green+3"  . ,(color-lighten-name mmgreen-color 8))
    ("mandm-green+2"  . ,(color-lighten-name mmgreen-color 6))
    ("mandm-green+1"  . ,(color-lighten-name mmgreen-color 3))
    ("mandm-green"    . ,mmgreen-color)
    ("mandm-green-1"  . ,(color-darken-name mmgreen-color 5))
    ("mandm-green-2"  . ,(color-darken-name mmgreen-color 10))
    ("mandm-green-3"  . ,(color-darken-name mmgreen-color 15))
    ("mandm-green-4"  . ,(color-darken-name mmgreen-color 20))
    ("mandm-cyan"     . "#93E0E3")
    ("mandm-blue+3"   . ,(color-lighten-name mmblue-color 40))
    ("mandm-blue+2"   . ,(color-lighten-name mmblue-color 20))
    ("mandm-blue+1"   . ,(color-lighten-name mmblue-color 20))
    ("mandm-blue"     . ,(color-lighten-name mmblue-color 10))
    ("mandm-blue-1"   . ,(color-darken-name mmblue-color 1))
    ("mandm-blue-2"   . ,(color-darken-name mmblue-color 5))
    ("mandm-blue-3"   . ,(color-darken-name mmblue-color 10))
    ("mandm-blue-4"   . ,(color-darken-name mmblue-color 15))
    ("mandm-blue-5"   . ,(color-darken-name mmblue-color 20))
    ("mandm-brown+2"  . ,(color-lighten-name mmbrown-color 20))
    ("mandm-brown+1"  . ,(color-lighten-name mmbrown-color 10))
    ("mandm-brown"    . ,mmbrown-color)
    ("mandm-brown-1"  . ,(color-darken-name mmbrown-color 10))
    ("mandm-brown-2"  . ,(color-darken-name mmbrown-color 20))
    ("mandm-violet"  . "#DDA0DD"))
  "List of Mandm colors.
Each element has the form (NAME . HEX).

`+N' suffixes indicate a color is lighter.
`-N' suffixes indicate a color is darker.")

(defmacro mandm-with-color-variables (&rest body)
  "`let' bind all colors defined in `mandm-colors-alist' around BODY.
Also bind `class' to ((class color) (min-colors 89))."
  (declare (indent 0))
  `(let ((class '((class color) (min-colors 89)))
         ,@(mapcar (lambda (cons)
                     (list (intern (car cons)) (cdr cons)))
                   mandm-colors-alist))
     ,@body))

;;; Theme Faces
(mandm-with-color-variables
  (custom-theme-set-faces
   'mandm
;;;; Built-in
;;;;; basic coloring
   '(button ((t (:underline t))))
   `(link ((t (:foreground ,mandm-blue-2 :underline t :weight bold))))
   `(link-visited ((t (:foreground ,mandm-red :underline t :weight normal))))
   `(default ((t (:foreground ,mandm-fg :background ,mandm-bg))))
   `(cursor ((t (:foreground ,mandm-fg :background ,mandm-fg+1))))
   `(escape-glyph ((t (:foreground ,mandm-yellow :bold t))))
   `(fringe ((t (:foreground ,mandm-fg :background ,mandm-bg+05))))
   `(header-line ((t (:foreground ,mandm-yellow
                                  :background ,mandm-bg-1
                                  :box (:line-width -1 :style released-button)))))
   `(highlight ((t (:foreground ,mandm-bg+1 :background ,mandm-yellow))))
   `(success ((t (:foreground ,mandm-green :weight bold))))
   `(warning ((t (:foreground ,mandm-orange-1 :weight bold))))
;;;;; compilation
   `(compilation-column-face ((t (:foreground ,mandm-yellow))))
   `(compilation-enter-directory-face ((t (:foreground ,mandm-green))))
   `(compilation-error-face ((t (:foreground ,mandm-red-1 :weight bold :underline t))))
   `(compilation-face ((t (:foreground ,mandm-fg))))
   `(compilation-info-face ((t (:foreground ,mandm-blue))))
   `(compilation-info ((t (:foreground ,mandm-green+4 :underline t))))
   `(compilation-leave-directory-face ((t (:foreground ,mandm-green))))
   `(compilation-line-face ((t (:foreground ,mandm-yellow))))
   `(compilation-line-number ((t (:foreground ,mandm-yellow))))
   `(compilation-message-face ((t (:foreground ,mandm-blue))))
   `(compilation-warning-face ((t (:foreground ,mandm-orange-1 :weight bold :underline t))))
   `(compilation-mode-line-exit ((t (:foreground ,mandm-green+2 :weight bold))))
   `(compilation-mode-line-fail ((t (:foreground ,mandm-red :weight bold))))
   `(compilation-mode-line-run ((t (:foreground ,mandm-yellow :weight bold))))
;;;;; grep
   `(grep-context-face ((t (:foreground ,mandm-fg))))
   `(grep-error-face ((t (:foreground ,mandm-red-1 :weight bold :underline t))))
   `(grep-hit-face ((t (:foreground ,mandm-blue))))
   `(grep-match-face ((t (:foreground ,mandm-orange :weight bold))))
   `(match ((t (:background ,mandm-bg-1 :foreground ,mandm-orange :weight bold))))
;;;;; isearch
   `(isearch ((t (:foreground ,mandm-yellow-2 :weight bold :background ,mandm-bg+2))))
   `(isearch-fail ((t (:foreground ,mandm-fg :background ,mandm-red-4))))
   `(lazy-highlight ((t (:foreground ,mandm-yellow-2 :weight bold :background ,mandm-bg-05))))

   `(menu ((t (:foreground ,mandm-fg :background ,mandm-bg))))
   `(minibuffer-prompt ((t (:foreground ,mandm-yellow))))
   `(mode-line
     ((,class (:foreground ,mandm-green+1
                           :background ,mandm-bg-1
                           :box (:line-width -1 :style released-button)))
      (t :inverse-video t)))
   `(mode-line-buffer-id ((t (:foreground ,mandm-yellow :weight bold))))
   `(mode-line-inactive
     ((t (:foreground ,mandm-green-1
                      :background ,mandm-bg-05
                      :box (:line-width -1 :style released-button)))))
   `(region ((,class (:background ,mandm-blue-5))
             (t :inverse-video t)))
   `(secondary-selection ((t (:background ,mandm-bg+2))))
   `(trailing-whitespace ((t (:background ,mandm-red))))
   `(vertical-border ((t (:foreground ,mandm-fg))))
;;;;; font lock
   `(font-lock-builtin-face ((t (:foreground ,mandm-fg+05 :weight bold))))
   `(font-lock-comment-face ((t (:foreground "grey55" :slant italic))))
   `(font-lock-comment-delimiter-face ((t (:foreground "grey33" :slant italic))))
   `(font-lock-constant-face ((t (:foreground ,(color-lighten-name mandm-green 20))))) ; mandm-green+4
   `(font-lock-doc-face ((t (:foreground ,mandm-orange)))) ; mandm-green+2
   `(font-lock-function-name-face ((t (:foreground ,mandm-blue+3))))
   `(font-lock-keyword-face ((t (:foreground ,(color-lighten-name mandm-blue 40) :weight bold)))) ; mandm-yellow
   `(font-lock-negation-char-face ((t (:foreground ,mandm-yellow-1 :weight bold))))
   `(font-lock-preprocessor-face ((t (:foreground ,mandm-yellow))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,mandm-yellow-1 :weight bold))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,mandm-red :weight bold))))
   `(font-lock-string-face ((t (:foreground ,(color-lighten-name mandm-green 20))))) ; mandm-green
   `(font-lock-type-face ((t (:foreground ,(color-lighten-name mandm-blue 40)))))
   `(font-lock-variable-name-face ((t (:foreground ,(color-lighten-name mandm-blue 50)))))
   `(font-lock-warning-face ((t (:foreground ,mandm-yellow-2 :weight bold))))

   `(c-annotation-face ((t (:inherit font-lock-constant-face))))
;;;;; newsticker
   `(newsticker-date-face ((t (:foreground ,mandm-fg))))
   `(newsticker-default-face ((t (:foreground ,mandm-fg))))
   `(newsticker-enclosure-face ((t (:foreground ,mandm-green+3))))
   `(newsticker-extra-face ((t (:foreground ,mandm-bg+2 :height 0.8))))
   `(newsticker-feed-face ((t (:foreground ,mandm-fg))))
   `(newsticker-immortal-item-face ((t (:foreground ,mandm-green))))
   `(newsticker-new-item-face ((t (:foreground ,mandm-blue))))
   `(newsticker-obsolete-item-face ((t (:foreground ,mandm-red))))
   `(newsticker-old-item-face ((t (:foreground ,mandm-bg+3))))
   `(newsticker-statistics-face ((t (:foreground ,mandm-fg))))
   `(newsticker-treeview-face ((t (:foreground ,mandm-fg))))
   `(newsticker-treeview-immortal-face ((t (:foreground ,mandm-green))))
   `(newsticker-treeview-listwindow-face ((t (:foreground ,mandm-fg))))
   `(newsticker-treeview-new-face ((t (:foreground ,mandm-blue :weight bold))))
   `(newsticker-treeview-obsolete-face ((t (:foreground ,mandm-red))))
   `(newsticker-treeview-old-face ((t (:foreground ,mandm-bg+3))))
   `(newsticker-treeview-selection-face ((t (:background ,mandm-bg-1 :foreground ,mandm-yellow))))
;;;; Third-party
;;;;; ace-jump
   `(ace-jump-face-background
     ((t (:foreground ,mandm-fg-1 :background ,mandm-bg :inverse-video nil))))
   `(ace-jump-face-foreground
     ((t (:foreground ,mandm-green+2 :background ,mandm-bg :inverse-video nil))))
;;;;; android mode
   `(android-mode-debug-face ((t (:foreground ,mandm-green+1))))
   `(android-mode-error-face ((t (:foreground ,mandm-orange-1 :weight bold))))
   `(android-mode-info-face ((t (:foreground ,mandm-fg))))
   `(android-mode-verbose-face ((t (:foreground ,mandm-green))))
   `(android-mode-warning-face ((t (:foreground ,mandm-yellow))))
;;;;; anzu
   `(anzu-mode-line ((t (:foreground ,mandm-cyan :weight bold))))
;;;;; auctex
   `(font-latex-bold-face ((t (:inherit bold))))
   `(font-latex-warning-face ((t (:foreground nil :inherit font-lock-warning-face))))
   `(font-latex-sectioning-5-face ((t (:foreground ,mandm-red :weight bold ))))
   `(font-latex-sedate-face ((t (:foreground ,mandm-yellow))))
   `(font-latex-italic-face ((t (:foreground ,mandm-cyan :slant italic))))
   `(font-latex-string-face ((t (:inherit ,font-lock-string-face))))
   `(font-latex-math-face ((t (:foreground ,mandm-orange))))
;;;;; auto-complete
   `(ac-candidate-face ((t (:background ,mandm-bg+3 :foreground ,mandm-bg-2))))
   `(ac-selection-face ((t (:background ,mandm-blue-4 :foreground ,mandm-fg))))
   `(popup-tip-face ((t (:background ,mandm-yellow-2 :foreground ,mandm-bg-2))))
   `(popup-scroll-bar-foreground-face ((t (:background ,mandm-blue-5))))
   `(popup-scroll-bar-background-face ((t (:background ,mandm-bg-1))))
   `(popup-isearch-match ((t (:background ,mandm-bg :foreground ,mandm-fg))))
;;;;; company-mode
   `(company-tooltip ((t (:foreground ,mandm-fg :background ,mandm-bg+1))))
   `(company-tooltip-selection ((t (:foreground ,mandm-fg :background ,mandm-bg-1))))
   `(company-tooltip-mouse ((t (:background ,mandm-bg-1))))
   `(company-tooltip-common ((t (:foreground ,mandm-green+2))))
   `(company-tooltip-common-selection ((t (:foreground ,mandm-green+2))))
   `(company-scrollbar-fg ((t (:background ,mandm-bg-1))))
   `(company-scrollbar-bg ((t (:background ,mandm-bg+2))))
   `(company-preview ((t (:background ,mandm-green+2))))
   `(company-preview-common ((t (:foreground ,mandm-green+2 :background ,mandm-bg-1))))
;;;;; bm
   `(bm-face ((t (:background ,mandm-yellow-1 :foreground ,mandm-bg))))
   `(bm-fringe-face ((t (:background ,mandm-yellow-1 :foreground ,mandm-bg))))
   `(bm-fringe-persistent-face ((t (:background ,mandm-green-1 :foreground ,mandm-bg))))
   `(bm-persistent-face ((t (:background ,mandm-green-1 :foreground ,mandm-bg))))
;;;;; clojure-test-mode
   `(clojure-test-failure-face ((t (:foreground ,mandm-orange :weight bold :underline t))))
   `(clojure-test-error-face ((t (:foreground ,mandm-red :weight bold :underline t))))
   `(clojure-test-success-face ((t (:foreground ,mandm-green+1 :weight bold :underline t))))
;;;;; coq
   `(coq-solve-tactics-face ((t (:foreground nil :inherit font-lock-constant-face))))
;;;;; ctable
   `(ctbl:face-cell-select ((t (:background ,mandm-blue :foreground ,mandm-bg))))
   `(ctbl:face-continue-bar ((t (:background ,mandm-bg-05 :foreground ,mandm-bg))))
   `(ctbl:face-row-select ((t (:background ,mandm-cyan :foreground ,mandm-bg))))
;;;;; diff
   `(diff-added ((,class (:foreground ,mandm-green+4 :background nil))
                 (t (:foreground ,mandm-green-1 :background nil))))
   `(diff-changed ((t (:foreground ,mandm-yellow))))
   `(diff-removed ((,class (:foreground ,mandm-red :background nil))
                   (t (:foreground ,mandm-red-3 :background nil))))
   `(diff-refine-added ((t (:inherit diff-added :weight bold))))
   `(diff-refine-change ((t (:inherit diff-changed :weight bold))))
   `(diff-refine-removed ((t (:inherit diff-removed :weight bold))))
   `(diff-header ((,class (:background ,mandm-bg+2))
                  (t (:background ,mandm-fg :foreground ,mandm-bg))))
   `(diff-file-header
     ((,class (:background ,mandm-bg+2 :foreground ,mandm-fg :bold t))
      (t (:background ,mandm-fg :foreground ,mandm-bg :bold t))))
;;;;; diff-hl
   `(diff-hl-change ((,class (:foreground ,mandm-yellow-2 :background ,mandm-bg-05))))
   `(diff-hl-delete ((,class (:foreground ,mandm-red+1 :background ,mandm-bg-05))))
   `(diff-hl-insert ((,class (:foreground ,mandm-green+1 :background ,mandm-bg-05))))
   `(diff-hl-unknown ((,class (:foreground ,mandm-blue :background ,mandm-bg-05))))
;;;;; dim-autoload
   `(dim-autoload-cookie-line ((t :foreground ,mandm-bg+1)))
;;;;; dired+
   `(diredp-display-msg ((t (:foreground ,mandm-blue))))
   `(diredp-compressed-file-suffix ((t (:foreground ,mandm-orange))))
   `(diredp-date-time ((t (:foreground ,mandm-violet))))
   `(diredp-deletion ((t (:foreground ,mandm-yellow))))
   `(diredp-deletion-file-name ((t (:foreground ,mandm-red))))
   `(diredp-dir-heading ((t (:foreground ,mandm-blue :background ,mandm-bg-1))))
   `(diredp-dir-priv ((t (:foreground ,mandm-cyan))))
   `(diredp-exec-priv ((t (:foreground ,mandm-red))))
   `(diredp-executable-tag ((t (:foreground ,mandm-green+1))))
   `(diredp-file-name ((t (:foreground ,mandm-blue))))
   `(diredp-file-suffix ((t (:foreground ,mandm-green))))
   `(diredp-flag-mark ((t (:foreground ,mandm-yellow))))
   `(diredp-flag-mark-line ((t (:foreground ,mandm-orange))))
   `(diredp-ignored-file-name ((t (:foreground ,mandm-red))))
   `(diredp-link-priv ((t (:foreground ,mandm-yellow))))
   `(diredp-mode-line-flagged ((t (:foreground ,mandm-yellow))))
   `(diredp-mode-line-marked ((t (:foreground ,mandm-orange))))
   `(diredp-no-priv ((t (:foreground ,mandm-fg))))
   `(diredp-number ((t (:foreground ,mandm-green+1))))
   `(diredp-other-priv ((t (:foreground ,mandm-yellow-1))))
   `(diredp-rare-priv ((t (:foreground ,mandm-red-1))))
   `(diredp-read-priv ((t (:foreground ,mandm-green-1))))
   `(diredp-symlink ((t (:foreground ,mandm-yellow))))
   `(diredp-write-priv ((t (:foreground ,mandm-violet))))
;;;;; ediff
   `(ediff-current-diff-A ((t (:foreground ,mandm-fg :background ,mandm-blue-3))))
   `(ediff-current-diff-Ancestor ((t (:background ,mandm-bg-1))))
   `(ediff-current-diff-B ((t (:foreground ,mandm-fg :background ,mandm-green-4))))
   `(ediff-current-diff-C ((t (:foreground ,mandm-fg :background ,mandm-brown))))
   `(ediff-even-diff-A ((t (:background ,mandm-bg+05))))
   `(ediff-even-diff-Ancestor ((t (:background ,mandm-bg+1))))
   `(ediff-even-diff-B ((t (:background ,mandm-bg+05))))
   `(ediff-even-diff-C ((t (:background ,mandm-bg+05))))
   `(ediff-fine-diff-Ancestor ((t (:background ,mandm-bg+1 :weight bold))))
   `(ediff-fine-diff-A ((t (:foreground ,mandm-fg :background ,mandm-blue-2 :weight bold))))
   `(ediff-fine-diff-B ((t (:foreground ,mandm-fg :background ,mandm-green-2 :weight bold))))
   `(ediff-fine-diff-C ((t (:foreground ,mandm-fg :background ,mandm-brown+1 :weight bold ))))
   `(ediff-odd-diff-A ((t (:background ,mandm-bg+05))))
   `(ediff-odd-diff-Ancestor ((t (:background ,mandm-bg+1))))
   `(ediff-odd-diff-B ((t (:background ,mandm-bg+05))))
   `(ediff-odd-diff-C ((t (:background ,mandm-bg+05))))
;;;;; egg
   `(egg-text-base ((t (:foreground ,mandm-fg))))
   `(egg-help-header-1 ((t (:foreground ,mandm-yellow))))
   `(egg-help-header-2 ((t (:foreground ,mandm-green+3))))
   `(egg-branch ((t (:foreground ,mandm-yellow))))
   `(egg-branch-mono ((t (:foreground ,mandm-yellow))))
   `(egg-term ((t (:foreground ,mandm-yellow))))
   `(egg-diff-add ((t (:foreground ,mandm-green+4))))
   `(egg-diff-del ((t (:foreground ,mandm-red+1))))
   `(egg-diff-file-header ((t (:foreground ,mandm-yellow-2))))
   `(egg-section-title ((t (:foreground ,mandm-yellow))))
   `(egg-stash-mono ((t (:foreground ,mandm-green+4))))
;;;;; elfeed
   `(elfeed-search-date-face ((t (:foreground ,mandm-yellow-1 :underline t
                                              :weight bold))))
   `(elfeed-search-tag-face ((t (:foreground ,mandm-green))))
   `(elfeed-search-feed-face ((t (:foreground ,mandm-cyan))))
;;;;; emacs-w3m
   `(w3m-anchor ((t (:foreground ,mandm-yellow :underline t
                                 :weight bold))))
   `(w3m-arrived-anchor ((t (:foreground ,mandm-yellow-2
                                         :underline t :weight normal))))
   `(w3m-form ((t (:foreground ,mandm-red-1 :underline t))))
   `(w3m-header-line-location-title ((t (:foreground ,mandm-yellow
                                                     :underline t :weight bold))))
   '(w3m-history-current-url ((t (:inherit match))))
   `(w3m-lnum ((t (:foreground ,mandm-green+2 :background ,mandm-bg))))
   `(w3m-lnum-match ((t (:background ,mandm-bg-1
                                     :foreground ,mandm-orange
                                     :weight bold))))
   `(w3m-lnum-minibuffer-prompt ((t (:foreground ,mandm-yellow))))
;;;;; erc
   `(erc-action-face ((t (:inherit erc-default-face))))
   `(erc-bold-face ((t (:weight bold))))
   `(erc-current-nick-face ((t (:foreground ,mandm-blue :weight bold))))
   `(erc-dangerous-host-face ((t (:inherit font-lock-warning-face))))
   `(erc-default-face ((t (:foreground ,mandm-fg))))
   `(erc-direct-msg-face ((t (:inherit erc-default))))
   `(erc-error-face ((t (:inherit font-lock-warning-face))))
   `(erc-fool-face ((t (:inherit erc-default))))
   `(erc-highlight-face ((t (:inherit hover-highlight))))
   `(erc-input-face ((t (:foreground ,mandm-yellow))))
   `(erc-keyword-face ((t (:foreground ,mandm-blue :weight bold))))
   `(erc-nick-default-face ((t (:foreground ,mandm-yellow :weight bold))))
   `(erc-my-nick-face ((t (:foreground ,mandm-red :weight bold))))
   `(erc-nick-msg-face ((t (:inherit erc-default))))
   `(erc-notice-face ((t (:foreground ,mandm-green))))
   `(erc-pal-face ((t (:foreground ,mandm-orange :weight bold))))
   `(erc-prompt-face ((t (:foreground ,mandm-orange :background ,mandm-bg :weight bold))))
   `(erc-timestamp-face ((t (:foreground ,mandm-green+4))))
   `(erc-underline-face ((t (:underline t))))
;;;;; ert
   `(ert-test-result-expected ((t (:foreground ,mandm-green+4 :background ,mandm-bg))))
   `(ert-test-result-unexpected ((t (:foreground ,mandm-red :background ,mandm-bg))))
;;;;; eshell
   `(eshell-prompt ((t (:foreground ,mandm-yellow :weight bold))))
   `(eshell-ls-archive ((t (:foreground ,mandm-red-1 :weight bold))))
   `(eshell-ls-backup ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-clutter ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-directory ((t (:foreground ,mandm-blue+1 :weight bold))))
   `(eshell-ls-executable ((t (:foreground ,mandm-red+1 :weight bold))))
   `(eshell-ls-unreadable ((t (:foreground ,mandm-fg))))
   `(eshell-ls-missing ((t (:inherit font-lock-warning-face))))
   `(eshell-ls-product ((t (:inherit font-lock-doc-face))))
   `(eshell-ls-special ((t (:foreground ,mandm-yellow :weight bold))))
   `(eshell-ls-symlink ((t (:foreground ,mandm-cyan :weight bold))))
;;;;; flx
   `(flx-highlight-face ((t (:foreground ,mandm-green+2 :weight bold))))
;;;;; flycheck
   ;; I like color-"inverse" otherwise I completely miss the fact that it's set.
   `(flycheck-error   ((t (:background ,mandm-red-4 :foreground ,mandm-fg :weight bold))))
   `(flycheck-warning ((t (:background ,mandm-yellow-5 :foreground ,mandm-fg :weight bold))))
   `(flycheck-info    ((t (:background "DodgerBlue3" :foreground ,mandm-fg :weight bold ))))
   ;; `(flycheck-error
   ;;   ((((supports :underline (:style wave)))
   ;;     (:underline (:style wave :color ,mandm-red-1) :inherit unspecified))
   ;;    (t (:foreground ,mandm-red-1 :weight bold :underline t))))
   ;; `(flycheck-warning
   ;;   ((((supports :underline (:style wave)))
   ;;     (:underline (:style wave :color ,mandm-yellow) :inherit unspecified))
   ;;    (t (:foreground ,mandm-yellow :weight bold :underline t))))
   ;; `(flycheck-info
   ;;   ((((supports :underline (:style wave)))
   ;;     (:underline (:style wave :color ,mandm-cyan) :inherit unspecified))
   ;;    (t (:foreground ,mandm-cyan :weight bold :underline t))))
   `(flycheck-fringe-error   ((t (:foreground ,mandm-red-1 :weight bold))))
   `(flycheck-fringe-warning ((t (:foreground ,mandm-yellow :weight bold))))
   `(flycheck-fringe-info    ((t (:foreground ,mandm-cyan :weight bold))))
;;;;; flymake
   `(flymake-errline  ((t (:background ,mandm-red-4 :foreground ,mandm-fg :weight bold))))
   `(flymake-warnline ((t (:background ,mandm-yellow-5 :foreground ,mandm-fg :weight bold))))
   `(flymake-infoline ((t (:background ,mandm-cyan :foreground ,mandm-fg :weight bold ))))
;;;;; flyspell
   `(flyspell-duplicate
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,mandm-orange) :inherit unspecified))
      (t (:foreground ,mandm-orange :weight bold :underline t))))
   `(flyspell-incorrect
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,mandm-red) :inherit unspecified))
      (t (:foreground ,mandm-red-1 :weight bold :underline t))))
;;;;; full-ack
   `(ack-separator ((t (:foreground ,mandm-fg))))
   `(ack-file ((t (:foreground ,mandm-blue))))
   `(ack-line ((t (:foreground ,mandm-yellow))))
   `(ack-match ((t (:foreground ,mandm-orange :background ,mandm-bg-1 :weight bold))))
;;;;; git-gutter
   `(git-gutter:added ((t (:foreground ,mandm-green :weight bold :inverse-video t))))
   `(git-gutter:deleted ((t (:foreground ,mandm-red :weight bold :inverse-video t))))
   `(git-gutter:modified ((t (:foreground ,mandm-violet :weight bold :inverse-video t))))
   `(git-gutter:unchanged ((t (:foreground ,mandm-fg :weight bold :inverse-video t))))
;;;;; git-gutter-fr
   `(git-gutter-fr:added ((t (:foreground ,mandm-green  :weight bold))))
   `(git-gutter-fr:deleted ((t (:foreground ,mandm-red :weight bold))))
   `(git-gutter-fr:modified ((t (:foreground ,mandm-violet :weight bold))))
;;;;; git-rebase-mode
   `(git-rebase-hash ((t (:foreground, mandm-orange))))
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
   `(gnus-header-from ((t (:inherit message-header-from))))
   `(gnus-header-name ((t (:inherit message-header-name))))
   `(gnus-header-newsgroups ((t (:inherit message-header-other))))
   `(gnus-header-subject ((t (:inherit message-header-subject))))
   `(gnus-summary-cancelled ((t (:foreground ,mandm-orange))))
   `(gnus-summary-high-ancient ((t (:foreground ,mandm-blue))))
   `(gnus-summary-high-read ((t (:foreground ,mandm-green :weight bold))))
   `(gnus-summary-high-ticked ((t (:foreground ,mandm-orange :weight bold))))
   `(gnus-summary-high-unread ((t (:foreground ,mandm-fg :weight bold))))
   `(gnus-summary-low-ancient ((t (:foreground ,mandm-blue))))
   `(gnus-summary-low-read ((t (:foreground ,mandm-green))))
   `(gnus-summary-low-ticked ((t (:foreground ,mandm-orange :weight bold))))
   `(gnus-summary-low-unread ((t (:foreground ,mandm-fg))))
   `(gnus-summary-normal-ancient ((t (:foreground ,mandm-blue))))
   `(gnus-summary-normal-read ((t (:foreground ,mandm-green))))
   `(gnus-summary-normal-ticked ((t (:foreground ,mandm-orange :weight bold))))
   `(gnus-summary-normal-unread ((t (:foreground ,mandm-fg))))
   `(gnus-summary-selected ((t (:foreground ,mandm-yellow :weight bold))))
   `(gnus-cite-1 ((t (:foreground ,mandm-blue))))
   `(gnus-cite-10 ((t (:foreground ,mandm-yellow-1))))
   `(gnus-cite-11 ((t (:foreground ,mandm-yellow))))
   `(gnus-cite-2 ((t (:foreground ,mandm-blue-1))))
   `(gnus-cite-3 ((t (:foreground ,mandm-blue-2))))
   `(gnus-cite-4 ((t (:foreground ,mandm-green+2))))
   `(gnus-cite-5 ((t (:foreground ,mandm-green+1))))
   `(gnus-cite-6 ((t (:foreground ,mandm-green))))
   `(gnus-cite-7 ((t (:foreground ,mandm-red))))
   `(gnus-cite-8 ((t (:foreground ,mandm-red-1))))
   `(gnus-cite-9 ((t (:foreground ,mandm-red-2))))
   `(gnus-group-news-1-empty ((t (:foreground ,mandm-yellow))))
   `(gnus-group-news-2-empty ((t (:foreground ,mandm-green+3))))
   `(gnus-group-news-3-empty ((t (:foreground ,mandm-green+1))))
   `(gnus-group-news-4-empty ((t (:foreground ,mandm-blue-2))))
   `(gnus-group-news-5-empty ((t (:foreground ,mandm-blue-3))))
   `(gnus-group-news-6-empty ((t (:foreground ,mandm-bg+2))))
   `(gnus-group-news-low-empty ((t (:foreground ,mandm-bg+2))))
   `(gnus-signature ((t (:foreground ,mandm-yellow))))
   `(gnus-x ((t (:background ,mandm-fg :foreground ,mandm-bg))))
;;;;; guide-key
   `(guide-key/highlight-command-face ((t (:foreground ,mandm-blue))))
   `(guide-key/key-face ((t (:foreground ,mandm-green))))
   `(guide-key/prefix-command-face ((t (:foreground ,mandm-green+1))))
;;;;; helm
   `(helm-header
     ((t (:foreground ,mandm-green
                      :background ,mandm-bg
                      :underline nil
                      :box nil))))
   `(helm-source-header
     ((t (:foreground ,mandm-yellow
                      :background ,mandm-bg-1
                      :underline nil
                      :weight bold
                      :box (:line-width -1 :style released-button)))))
   `(helm-selection ((t (:background ,(color-desaturate-name mandm-yellow 80) :foreground ,mandm-bg))))
   `(helm-selection-line ((t (:background ,mandm-bg+3))))
   `(helm-visible-mark ((t (:foreground ,mandm-bg :background ,mandm-yellow-2))))
   `(helm-candidate-number ((t (:foreground ,mandm-green+4 :background ,mandm-bg-1))))
   `(helm-separator ((t (:foreground ,mandm-red :background ,mandm-bg))))
   `(helm-time-zone-current ((t (:foreground ,mandm-green+2 :background ,mandm-bg))))
   `(helm-time-zone-home ((t (:foreground ,mandm-red :background ,mandm-bg))))
   `(helm-bookmark-addressbook ((t (:foreground ,mandm-orange :background ,mandm-bg))))
   `(helm-bookmark-directory ((t (:foreground nil :background nil :inherit helm-ff-directory))))
   `(helm-bookmark-file ((t (:foreground nil :background nil :inherit helm-ff-file))))
   `(helm-bookmark-gnus ((t (:foreground ,mandm-violet :background ,mandm-bg))))
   `(helm-bookmark-info ((t (:foreground ,mandm-green+2 :background ,mandm-bg))))
   `(helm-bookmark-man ((t (:foreground ,mandm-yellow :background ,mandm-bg))))
   `(helm-bookmark-w3m ((t (:foreground ,mandm-violet :background ,mandm-bg))))
   `(helm-buffer-not-saved ((t (:foreground ,mandm-red :background ,mandm-bg))))
   `(helm-buffer-process ((t (:foreground ,mandm-cyan :background ,mandm-bg))))
   `(helm-buffer-saved-out ((t (:foreground ,mandm-fg :background ,mandm-bg))))
   `(helm-buffer-size ((t (:foreground ,mandm-fg-1 :background ,mandm-bg))))
   `(helm-ff-directory ((t (:foreground ,mandm-blue+3 :background ,mandm-bg))))
   `(helm-ff-dotted-directory ((t (:foreground ,(color-desaturate-name mandm-blue+3 60) :background ,mandm-bg))))
   `(helm-ff-dotted-symlink-directory ((t (:foreground ,(color-desaturate-name mandm-blue+3 60) :background ,mandm-bg :italic t))))
   `(helm-ff-dirs ((t (:foreground ,mandm-cyan :background ,mandm-bg))))
   `(helm-ff-file ((t (:weight normal))))
   `(helm-ff-executable ((t (:foreground ,mandm-green :weight bold))))
   `(helm-ff-invalid-symlink ((t (:foreground ,mandm-red :underline t))))
   `(helm-ff-symlink ((t (:foreground ,mandm-cyan :italic t))))
   `(helm-ff-prefix ((t (:foreground ,mandm-bg :background ,mandm-yellow :weight normal))))
   `(helm-grep-cmd-line ((t (:foreground ,mandm-cyan :background ,mandm-bg))))
   `(helm-grep-file ((t (:foreground ,mandm-fg :background ,mandm-bg))))
   `(helm-grep-finish ((t (:foreground ,mandm-green+2 :background ,mandm-bg))))
   `(helm-grep-lineno ((t (:foreground ,mandm-fg-1 :background ,mandm-bg))))
   `(helm-grep-match ((t (:foreground nil :background nil :inherit helm-match))))
   `(helm-grep-running ((t (:foreground ,mandm-red :background ,mandm-bg))))
   `(helm-moccur-buffer ((t (:foreground ,mandm-cyan :background ,mandm-bg))))
   `(helm-mu-contacts-address-face ((t (:foreground ,mandm-fg-1 :background ,mandm-bg))))
   `(helm-mu-contacts-name-face ((t (:foreground ,mandm-fg :background ,mandm-bg))))
;;;;; hl-line-mode
   `(hl-line-face ((,class (:background ,mandm-bg-05))
                   (t :weight bold)))
   `(hl-line ((,class (:background ,mandm-bg-05)) ; old emacsen
              (t :weight bold)))
;;;;; hl-sexp
   `(hl-sexp-face ((,class (:background ,mandm-bg+1))
                   (t :weight bold)))
;;;;; ido-mode
   `(ido-first-match ((t (:foreground ,mandm-yellow :weight bold))))
   `(ido-only-match ((t (:foreground ,mandm-orange :weight bold))))
   `(ido-subdir ((t (:foreground ,mandm-yellow))))
   `(ido-indicator ((t (:foreground ,mandm-yellow :background ,mandm-red-4))))
;;;;; iedit-mode
   `(iedit-occurrence ((t (:background ,mandm-bg+2 :weight bold))))
;;;;; irfc-mode
   `(irfc-head-name-face ((t (:foreground ,mandm-orange))))
   `(irfc-head-number-face ((t (:foreground ,mandm-orange))))
   `(irfc-reference-face ((t (:foreground ,mandm-yellow-2 :underline t))))
   `(irfc-requirement-keyword-face ((t (:bold t :italic t :slant italic :weight bold))))
   `(irfc-rfc-link-face ((t (:foreground ,mandm-yellow-2 :underline t))))
   `(irfc-rfc-number-face ((t (:bold t :weight bold))))
   `(irfc-std-number-face ((t (:bold t :weight bold))))
   `(irfc-table-item-face ((t (:foreground ,mandm-yellow-2 :underline t))))
   `(irfc-title-face ((t (:foreground ,mandm-orange))))
;;;;; jabber-mode
   `(jabber-roster-user-away ((t (:foreground ,mandm-green+2))))
   `(jabber-roster-user-online ((t (:foreground ,mandm-blue-1))))
   `(jabber-roster-user-dnd ((t (:foreground ,mandm-red+1))))
   `(jabber-rare-time-face ((t (:foreground ,mandm-green+1))))
   `(jabber-chat-prompt-local ((t (:foreground ,mandm-blue-1))))
   `(jabber-chat-prompt-foreign ((t (:foreground ,mandm-red+1))))
   `(jabber-activity-face((t (:foreground ,mandm-red+1))))
   `(jabber-activity-personal-face ((t (:foreground ,mandm-blue+1))))
   `(jabber-title-small ((t (:height 1.1 :weight bold))))
   `(jabber-title-medium ((t (:height 1.2 :weight bold))))
   `(jabber-title-large ((t (:height 1.3 :weight bold))))
;;;;; js2-mode
   `(js2-warning ((t (:underline ,mandm-orange))))
   `(js2-error ((t (:foreground ,mandm-red :weight bold))))
   `(js2-jsdoc-tag ((t (:foreground ,mandm-green-1))))
   `(js2-jsdoc-type ((t (:foreground ,mandm-green+2))))
   `(js2-jsdoc-value ((t (:foreground ,mandm-green+3))))
   `(js2-function-param ((t (:foreground, mandm-green+3))))
   `(js2-external-variable ((t (:foreground ,mandm-orange))))
;;;;; ledger-mode
   `(ledger-font-payee-uncleared-face ((t (:foreground ,mandm-red-1 :weight bold))))
   `(ledger-font-payee-cleared-face ((t (:foreground ,mandm-fg :weight normal))))
   `(ledger-font-xact-highlight-face ((t (:background ,mandm-bg+1))))
   `(ledger-font-pending-face ((t (:foreground ,mandm-orange weight: normal))))
   `(ledger-font-other-face ((t (:foreground ,mandm-fg))))
   `(ledger-font-posting-account-face ((t (:foreground ,mandm-blue-1))))
   `(ledger-font-posting-account-cleared-face ((t (:foreground ,mandm-fg))))
   `(ledger-font-posting-account-pending-face ((t (:foreground ,mandm-orange))))
   `(ledger-font-posting-amount-face ((t (:foreground ,mandm-orange))))
   `(ledger-font-posting-account-pending-face ((t (:foreground ,mandm-orange))))
   `(ledger-occur-narrowed-face ((t (:foreground ,mandm-fg-1 :invisible t))))
   `(ledger-occur-xact-face ((t (:background ,mandm-bg+1))))
   `(ledger-font-comment-face ((t (:foreground ,mandm-green))))
   `(ledger-font-reconciler-uncleared-face ((t (:foreground ,mandm-red-1 :weight bold))))
   `(ledger-font-reconciler-cleared-face ((t (:foreground ,mandm-fg :weight normal))))
   `(ledger-font-reconciler-pending-face ((t (:foreground ,mandm-orange :weight normal))))
   `(ledger-font-report-clickable-face ((t (:foreground ,mandm-orange :weight normal))))
;;;;; linum-mode
   `(linum ((t (:foreground ,mandm-green+2 :background ,mandm-bg))))
;;;;; macrostep
   `(macrostep-gensym-1
     ((t (:foreground ,mandm-green+2 :background ,mandm-bg-1))))
   `(macrostep-gensym-2
     ((t (:foreground ,mandm-red+1 :background ,mandm-bg-1))))
   `(macrostep-gensym-3
     ((t (:foreground ,mandm-blue+1 :background ,mandm-bg-1))))
   `(macrostep-gensym-4
     ((t (:foreground ,mandm-violet :background ,mandm-bg-1))))
   `(macrostep-gensym-5
     ((t (:foreground ,mandm-yellow :background ,mandm-bg-1))))
   `(macrostep-expansion-highlight-face
     ((t (:inherit highlight))))
   `(macrostep-macro-face
     ((t (:underline t))))
;;;;; magit
   `(magit-item-highlight ((t (:background ,mandm-bg+05))))
   `(magit-section-title ((t (:foreground ,mandm-yellow :weight bold))))
   `(magit-process-ok ((t (:foreground ,mandm-green :weight bold))))
   `(magit-process-ng ((t (:foreground ,mandm-red :weight bold))))
   `(magit-branch ((t (:foreground ,mandm-blue :weight bold))))
   `(magit-log-author ((t (:foreground ,mandm-orange))))
   `(magit-log-sha1 ((t (:foreground, mandm-orange))))
;;;;; message-mode
   `(message-cited-text ((t (:inherit font-lock-comment-face))))
   `(message-header-name ((t (:foreground ,mandm-green+1))))
   `(message-header-other ((t (:foreground ,mandm-green))))
   `(message-header-to ((t (:foreground ,mandm-yellow :weight bold))))
   `(message-header-from ((t (:foreground ,mandm-yellow :weight bold))))
   `(message-header-cc ((t (:foreground ,mandm-yellow :weight bold))))
   `(message-header-newsgroups ((t (:foreground ,mandm-yellow :weight bold))))
   `(message-header-subject ((t (:foreground ,mandm-orange :weight bold))))
   `(message-header-xheader ((t (:foreground ,mandm-green))))
   `(message-mml ((t (:foreground ,mandm-yellow :weight bold))))
   `(message-separator ((t (:inherit font-lock-comment-face))))
;;;;; mew
   `(mew-face-header-subject ((t (:foreground ,mandm-orange))))
   `(mew-face-header-from ((t (:foreground ,mandm-yellow))))
   `(mew-face-header-date ((t (:foreground ,mandm-green))))
   `(mew-face-header-to ((t (:foreground ,mandm-red))))
   `(mew-face-header-key ((t (:foreground ,mandm-green))))
   `(mew-face-header-private ((t (:foreground ,mandm-green))))
   `(mew-face-header-important ((t (:foreground ,mandm-blue))))
   `(mew-face-header-marginal ((t (:foreground ,mandm-fg :weight bold))))
   `(mew-face-header-warning ((t (:foreground ,mandm-red))))
   `(mew-face-header-xmew ((t (:foreground ,mandm-green))))
   `(mew-face-header-xmew-bad ((t (:foreground ,mandm-red))))
   `(mew-face-body-url ((t (:foreground ,mandm-orange))))
   `(mew-face-body-comment ((t (:foreground ,mandm-fg :slant italic))))
   `(mew-face-body-cite1 ((t (:foreground ,mandm-green))))
   `(mew-face-body-cite2 ((t (:foreground ,mandm-blue))))
   `(mew-face-body-cite3 ((t (:foreground ,mandm-orange))))
   `(mew-face-body-cite4 ((t (:foreground ,mandm-yellow))))
   `(mew-face-body-cite5 ((t (:foreground ,mandm-red))))
   `(mew-face-mark-review ((t (:foreground ,mandm-blue))))
   `(mew-face-mark-escape ((t (:foreground ,mandm-green))))
   `(mew-face-mark-delete ((t (:foreground ,mandm-red))))
   `(mew-face-mark-unlink ((t (:foreground ,mandm-yellow))))
   `(mew-face-mark-refile ((t (:foreground ,mandm-green))))
   `(mew-face-mark-unread ((t (:foreground ,mandm-red-2))))
   `(mew-face-eof-message ((t (:foreground ,mandm-green))))
   `(mew-face-eof-part ((t (:foreground ,mandm-yellow))))
;;;;; mic-paren
   `(paren-face-match ((t (:foreground ,mandm-cyan :background ,mandm-bg :weight bold))))
   `(paren-face-mismatch ((t (:foreground ,mandm-bg :background ,mandm-violet :weight bold))))
   `(paren-face-no-match ((t (:foreground ,mandm-bg :background ,mandm-red :weight bold))))
;;;;; mingus
   `(mingus-directory-face ((t (:foreground ,mandm-blue))))
   `(mingus-pausing-face ((t (:foreground ,mandm-violet))))
   `(mingus-playing-face ((t (:foreground ,mandm-cyan))))
   `(mingus-playlist-face ((t (:foreground ,mandm-cyan ))))
   `(mingus-song-file-face ((t (:foreground ,mandm-yellow))))
   `(mingus-stopped-face ((t (:foreground ,mandm-red))))
;;;;; nav
   `(nav-face-heading ((t (:foreground ,mandm-yellow))))
   `(nav-face-button-num ((t (:foreground ,mandm-cyan))))
   `(nav-face-dir ((t (:foreground ,mandm-green))))
   `(nav-face-hdir ((t (:foreground ,mandm-red))))
   `(nav-face-file ((t (:foreground ,mandm-fg))))
   `(nav-face-hfile ((t (:foreground ,mandm-red-4))))
;;;;; mu4e
   `(mu4e-cited-1-face ((t (:foreground ,mandm-blue    :slant italic))))
   `(mu4e-cited-2-face ((t (:foreground ,mandm-green+2 :slant italic))))
   `(mu4e-cited-3-face ((t (:foreground ,mandm-blue-2  :slant italic))))
   `(mu4e-cited-4-face ((t (:foreground ,mandm-green   :slant italic))))
   `(mu4e-cited-5-face ((t (:foreground ,mandm-blue-4  :slant italic))))
   `(mu4e-cited-6-face ((t (:foreground ,mandm-green-1 :slant italic))))
   `(mu4e-cited-7-face ((t (:foreground ,mandm-blue    :slant italic))))
   `(mu4e-replied-face ((t (:foreground ,mandm-bg+3))))
   `(mu4e-trashed-face ((t (:foreground ,mandm-bg+3 :strike-through t))))
;;;;; mumamo
   `(mumamo-background-chunk-major ((t (:background nil))))
   `(mumamo-background-chunk-submode1 ((t (:background ,mandm-bg-1))))
   `(mumamo-background-chunk-submode2 ((t (:background ,mandm-bg+2))))
   `(mumamo-background-chunk-submode3 ((t (:background ,mandm-bg+3))))
   `(mumamo-background-chunk-submode4 ((t (:background ,mandm-bg+1))))
;;;;; org-mode
   `(org-agenda-date-today
     ((t (:foreground ,mandm-fg+1 :slant italic :weight bold))) t)
   `(org-agenda-structure
     ((t (:inherit font-lock-comment-face))))
   `(org-archived ((t (:foreground ,mandm-fg :weight bold))))
   `(org-checkbox ((t (:background ,mandm-bg+2 :foreground ,mandm-fg+1
                                   :box (:line-width 1 :style released-button)))))
   `(org-date ((t (:foreground ,mandm-blue :underline t))))
   `(org-deadline-announce ((t (:foreground ,mandm-red-1))))
   `(org-done ((t (:bold t :weight bold :foreground ,mandm-green+3))))
   `(org-formula ((t (:foreground ,mandm-yellow-2))))
   `(org-headline-done ((t (:foreground ,mandm-green+3))))
   `(org-hide ((t (:foreground ,mandm-bg-1))))
   `(org-level-1 ((t (:foreground ,mandm-green+2 :height ,mandm-height-plus-4))))
   `(org-level-2 ((t (:foreground ,mandm-green+2 :height ,mandm-height-plus-3))))
   `(org-level-3 ((t (:foreground ,mandm-green+2 :height ,mandm-height-plus-2))))
   `(org-level-4 ((t (:foreground ,mandm-green+2 :height ,mandm-height-plus-1))))
   `(org-level-5 ((t (:foreground ,mandm-green+2 :weight bold))))
   `(org-level-6 ((t (:foreground ,mandm-green+1 :weight bold))))
   `(org-level-7 ((t (:foreground ,mandm-green :weight bold))))
   `(org-level-8 ((t (:foreground ,mandm-green))))
   `(org-link ((t (:foreground ,mandm-yellow-2 :underline t))))
   `(org-scheduled ((t (:foreground ,mandm-green+4))))
   `(org-scheduled-previously ((t (:foreground ,mandm-red))))
   `(org-scheduled-today ((t (:foreground ,mandm-blue+1))))
   `(org-sexp-date ((t (:foreground ,mandm-blue+1 :underline t))))
   `(org-special-keyword ((t (:inherit font-lock-comment-face))))
   `(org-table ((t (:foreground ,mandm-green+2))))
   `(org-tag ((t (:bold t :weight bold))))
   `(org-time-grid ((t (:foreground ,mandm-orange))))
   `(org-todo ((t (:bold t :foreground ,mandm-red :weight bold))))
   `(org-upcoming-deadline ((t (:inherit font-lock-keyword-face))))
   `(org-warning ((t (:bold t :foreground ,mandm-red :weight bold :underline nil))))
   `(org-column ((t (:background ,mandm-bg-1))))
   `(org-column-title ((t (:background ,mandm-bg-1 :underline t :weight bold))))
   `(org-mode-line-clock ((t (:foreground ,mandm-fg :background ,mandm-bg-1))))
   `(org-mode-line-clock-overrun ((t (:foreground ,mandm-bg :background ,mandm-red-1))))
   `(org-ellipsis ((t (:foreground ,mandm-yellow-1 :underline t))))
   `(org-footnote ((t (:foreground ,mandm-cyan :underline t))))
;;;;; outline
   `(outline-1 ((t (:foreground ,mandm-orange))))
   `(outline-2 ((t (:foreground ,mandm-green+4))))
   `(outline-3 ((t (:foreground ,mandm-blue-1))))
   `(outline-4 ((t (:foreground ,mandm-yellow-2))))
   `(outline-5 ((t (:foreground ,mandm-cyan))))
   `(outline-6 ((t (:foreground ,mandm-green+2))))
   `(outline-7 ((t (:foreground ,mandm-red-4))))
   `(outline-8 ((t (:foreground ,mandm-blue-4))))
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
   `(persp-selected-face ((t (:foreground ,mandm-yellow-2 :inherit mode-line))))
;;;;; powerline
   `(powerline-active1 ((t (:background ,mandm-brown :inherit mode-line))))
   `(powerline-active2 ((t (:background ,mandm-brown+1 :inherit mode-line))))
   `(powerline-inactive1 ((t (:background ,mandm-bg+1 :inherit mode-line-inactive))))
   `(powerline-inactive2 ((t (:background ,mandm-bg+2 :inherit mode-line-inactive))))
;;;;; proofgeneral
   `(proof-active-area-face ((t (:underline t))))
   `(proof-boring-face ((t (:foreground ,mandm-fg :background ,mandm-bg+2))))
   `(proof-command-mouse-highlight-face ((t (:inherit proof-mouse-highlight-face))))
   `(proof-debug-message-face ((t (:inherit proof-boring-face))))
   `(proof-declaration-name-face ((t (:inherit font-lock-keyword-face :foreground nil))))
   `(proof-eager-annotation-face ((t (:foreground ,mandm-bg :background ,mandm-orange))))
   `(proof-error-face ((t (:foreground ,mandm-fg :background ,mandm-red-4))))
   `(proof-highlight-dependency-face ((t (:foreground ,mandm-bg :background ,mandm-yellow-1))))
   `(proof-highlight-dependent-face ((t (:foreground ,mandm-bg :background ,mandm-orange))))
   `(proof-locked-face ((t (:background ,mandm-blue-5))))
   `(proof-mouse-highlight-face ((t (:foreground ,mandm-bg :background ,mandm-orange))))
   `(proof-queue-face ((t (:background ,mandm-red-4))))
   `(proof-region-mouse-highlight-face ((t (:inherit proof-mouse-highlight-face))))
   `(proof-script-highlight-error-face ((t (:background ,mandm-red-2))))
   `(proof-tacticals-name-face ((t (:inherit font-lock-constant-face :foreground nil :background ,mandm-bg))))
   `(proof-tactics-name-face ((t (:inherit font-lock-constant-face :foreground nil :background ,mandm-bg))))
   `(proof-warning-face ((t (:foreground ,mandm-bg :background ,mandm-yellow-1))))
;;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,mandm-fg))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,mandm-green+4))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,mandm-yellow-2))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,mandm-cyan))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground ,mandm-green+2))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,mandm-blue+1))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,mandm-yellow-1))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground ,mandm-green+1))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground ,mandm-blue-2))))
   `(rainbow-delimiters-depth-10-face ((t (:foreground ,mandm-orange))))
   `(rainbow-delimiters-depth-11-face ((t (:foreground ,mandm-green))))
   `(rainbow-delimiters-depth-12-face ((t (:foreground ,mandm-blue-5))))
;;;;; rcirc
   `(rcirc-my-nick ((t (:foreground ,mandm-blue))))
   `(rcirc-other-nick ((t (:foreground ,mandm-orange))))
   `(rcirc-bright-nick ((t (:foreground ,mandm-blue+1))))
   `(rcirc-dim-nick ((t (:foreground ,mandm-blue-2))))
   `(rcirc-server ((t (:foreground ,mandm-green))))
   `(rcirc-server-prefix ((t (:foreground ,mandm-green+1))))
   `(rcirc-timestamp ((t (:foreground ,mandm-green+2))))
   `(rcirc-nick-in-message ((t (:foreground ,mandm-yellow))))
   `(rcirc-nick-in-message-full-line ((t (:bold t))))
   `(rcirc-prompt ((t (:foreground ,mandm-yellow :bold t))))
   `(rcirc-track-nick ((t (:inverse-video t))))
   `(rcirc-track-keyword ((t (:bold t))))
   `(rcirc-url ((t (:bold t))))
   `(rcirc-keyword ((t (:foreground ,mandm-yellow :bold t))))
;;;;; rpm-mode
   `(rpm-spec-dir-face ((t (:foreground ,mandm-green))))
   `(rpm-spec-doc-face ((t (:foreground ,mandm-green))))
   `(rpm-spec-ghost-face ((t (:foreground ,mandm-red))))
   `(rpm-spec-macro-face ((t (:foreground ,mandm-yellow))))
   `(rpm-spec-obsolete-tag-face ((t (:foreground ,mandm-red))))
   `(rpm-spec-package-face ((t (:foreground ,mandm-red))))
   `(rpm-spec-section-face ((t (:foreground ,mandm-yellow))))
   `(rpm-spec-tag-face ((t (:foreground ,mandm-blue))))
   `(rpm-spec-var-face ((t (:foreground ,mandm-red))))
;;;;; rst-mode
   `(rst-level-1-face ((t (:foreground ,mandm-orange))))
   `(rst-level-2-face ((t (:foreground ,mandm-green+1))))
   `(rst-level-3-face ((t (:foreground ,mandm-blue-1))))
   `(rst-level-4-face ((t (:foreground ,mandm-yellow-2))))
   `(rst-level-5-face ((t (:foreground ,mandm-cyan))))
   `(rst-level-6-face ((t (:foreground ,mandm-green-1))))
;;;;; sh-mode
   `(sh-heredoc     ((t (:foreground ,mandm-yellow :bold t))))
   `(sh-quoted-exec ((t (:foreground ,mandm-red))))
;;;;; show-paren
   `(show-paren-mismatch ((t (:foreground ,mandm-red+1 :background ,mandm-bg+3 :weight bold))))
   `(show-paren-match ((t (:background ,mandm-bg+3 :weight bold))))
;;;;; smartparens
   `(sp-show-pair-mismatch-face ((t (:foreground ,mandm-red+1 :background ,mandm-bg+3 :weight bold))))
   `(sp-show-pair-match-face ((t (:background ,mandm-bg+3 :weight bold))))
;;;;; sml-mode-line
   '(sml-modeline-end-face ((t :inherit default :width condensed)))
;;;;; SLIME
   `(slime-repl-output-face ((t (:foreground ,mandm-red))))
   `(slime-repl-inputed-output-face ((t (:foreground ,mandm-green))))
   `(slime-error-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,mandm-red)))
      (t
       (:underline ,mandm-red))))
   `(slime-warning-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,mandm-orange)))
      (t
       (:underline ,mandm-orange))))
   `(slime-style-warning-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,mandm-yellow)))
      (t
       (:underline ,mandm-yellow))))
   `(slime-note-face
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,mandm-green)))
      (t
       (:underline ,mandm-green))))
   `(slime-highlight-face ((t (:inherit highlight))))
;;;;; speedbar
   `(speedbar-button-face ((t (:foreground ,mandm-green+2))))
   `(speedbar-directory-face ((t (:foreground ,mandm-cyan))))
   `(speedbar-file-face ((t (:foreground ,mandm-fg))))
   `(speedbar-highlight-face ((t (:foreground ,mandm-bg :background ,mandm-green+2))))
   `(speedbar-selected-face ((t (:foreground ,mandm-red))))
   `(speedbar-separator-face ((t (:foreground ,mandm-bg :background ,mandm-blue-1))))
   `(speedbar-tag-face ((t (:foreground ,mandm-yellow))))
;;;;; tabbar
   `(tabbar-button ((t (:foreground ,mandm-fg
                                    :background ,mandm-bg))))
   `(tabbar-selected ((t (:foreground ,mandm-fg
                                      :background ,mandm-bg
                                      :box (:line-width -1 :style pressed-button)))))
   `(tabbar-unselected ((t (:foreground ,mandm-fg
                                        :background ,mandm-bg+1
                                        :box (:line-width -1 :style released-button)))))
;;;;; term
   `(term-color-black ((t (:foreground ,mandm-bg
                                       :background ,mandm-bg-1))))
   `(term-color-red ((t (:foreground ,mandm-red-2
                                       :background ,mandm-red-4))))
   `(term-color-green ((t (:foreground ,mandm-green
                                       :background ,mandm-green+2))))
   `(term-color-yellow ((t (:foreground ,mandm-orange
                                       :background ,mandm-yellow))))
   `(term-color-blue ((t (:foreground ,mandm-blue-1
                                      :background ,mandm-blue-4))))
   `(term-color-magenta ((t (:foreground ,mandm-violet
                                         :background ,mandm-red))))
   `(term-color-cyan ((t (:foreground ,mandm-cyan
                                       :background ,mandm-blue))))
   `(term-color-white ((t (:foreground ,mandm-fg
                                       :background ,mandm-fg-1))))
   '(term-default-fg-color ((t (:inherit term-color-white))))
   '(term-default-bg-color ((t (:inherit term-color-black))))
;;;;; undo-tree
   `(undo-tree-visualizer-active-branch-face ((t (:foreground ,mandm-fg+1 :weight bold))))
   `(undo-tree-visualizer-current-face ((t (:foreground ,mandm-red-1 :weight bold))))
   `(undo-tree-visualizer-default-face ((t (:foreground ,mandm-fg))))
   `(undo-tree-visualizer-register-face ((t (:foreground ,mandm-yellow))))
   `(undo-tree-visualizer-unmodified-face ((t (:foreground ,mandm-cyan))))
;;;;; volatile-highlights
   `(vhl/default-face ((t (:background ,mandm-bg-05))))
;;;;; web-mode
   `(web-mode-builtin-face ((t (:inherit ,font-lock-builtin-face))))
   `(web-mode-comment-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-constant-face ((t (:inherit ,font-lock-constant-face))))
   `(web-mode-css-at-rule-face ((t (:foreground ,mandm-orange ))))
   `(web-mode-css-prop-face ((t (:foreground ,mandm-orange))))
   `(web-mode-css-pseudo-class-face ((t (:foreground ,mandm-green+3 :weight bold))))
   `(web-mode-css-rule-face ((t (:foreground ,mandm-blue))))
   `(web-mode-doctype-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-folded-face ((t (:underline t))))
   `(web-mode-function-name-face ((t (:foreground ,mandm-blue))))
   `(web-mode-html-attr-name-face ((t (:foreground ,mandm-orange))))
   `(web-mode-html-attr-value-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-html-tag-face ((t (:foreground ,mandm-cyan))))
   `(web-mode-keyword-face ((t (:inherit ,font-lock-keyword-face))))
   `(web-mode-preprocessor-face ((t (:inherit ,font-lock-preprocessor-face))))
   `(web-mode-string-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-type-face ((t (:inherit ,font-lock-type-face))))
   `(web-mode-variable-name-face ((t (:inherit ,font-lock-variable-name-face))))
   `(web-mode-server-background-face ((t (:background ,mandm-bg))))
   `(web-mode-server-comment-face ((t (:inherit web-mode-comment-face))))
   `(web-mode-server-string-face ((t (:inherit web-mode-string-face))))
   `(web-mode-symbol-face ((t (:inherit font-lock-constant-face))))
   `(web-mode-warning-face ((t (:inherit font-lock-warning-face))))
   `(web-mode-whitespaces-face ((t (:background ,mandm-red))))
;;;;; whitespace-mode
   `(whitespace-space ((t (:background ,mandm-bg+1 :foreground ,mandm-bg+1))))
   `(whitespace-hspace ((t (:background ,mandm-bg+1 :foreground ,mandm-bg+1))))
   `(whitespace-tab ((t (:background ,mandm-red-1))))
   `(whitespace-newline ((t (:foreground ,mandm-bg+1))))
   `(whitespace-trailing ((t (:background ,mandm-red))))
   `(whitespace-line ((t (:background ,mandm-bg :foreground ,mandm-violet))))
   `(whitespace-space-before-tab ((t (:background ,mandm-orange :foreground ,mandm-orange))))
   `(whitespace-indentation ((t (:background ,mandm-yellow :foreground ,mandm-red))))
   `(whitespace-empty ((t (:background ,mandm-yellow))))
   `(whitespace-space-after-tab ((t (:background ,mandm-yellow :foreground ,mandm-red))))
;;;;; wanderlust
   `(wl-highlight-folder-few-face ((t (:foreground ,mandm-red-2))))
   `(wl-highlight-folder-many-face ((t (:foreground ,mandm-red-1))))
   `(wl-highlight-folder-path-face ((t (:foreground ,mandm-orange))))
   `(wl-highlight-folder-unread-face ((t (:foreground ,mandm-blue))))
   `(wl-highlight-folder-zero-face ((t (:foreground ,mandm-fg))))
   `(wl-highlight-folder-unknown-face ((t (:foreground ,mandm-blue))))
   `(wl-highlight-message-citation-header ((t (:foreground ,mandm-red-1))))
   `(wl-highlight-message-cited-text-1 ((t (:foreground ,mandm-red))))
   `(wl-highlight-message-cited-text-2 ((t (:foreground ,mandm-green+2))))
   `(wl-highlight-message-cited-text-3 ((t (:foreground ,mandm-blue))))
   `(wl-highlight-message-cited-text-4 ((t (:foreground ,mandm-blue+1))))
   `(wl-highlight-message-header-contents-face ((t (:foreground ,mandm-green))))
   `(wl-highlight-message-headers-face ((t (:foreground ,mandm-red+1))))
   `(wl-highlight-message-important-header-contents ((t (:foreground ,mandm-green+2))))
   `(wl-highlight-message-header-contents ((t (:foreground ,mandm-green+1))))
   `(wl-highlight-message-important-header-contents2 ((t (:foreground ,mandm-green+2))))
   `(wl-highlight-message-signature ((t (:foreground ,mandm-green))))
   `(wl-highlight-message-unimportant-header-contents ((t (:foreground ,mandm-fg))))
   `(wl-highlight-summary-answered-face ((t (:foreground ,mandm-blue))))
   `(wl-highlight-summary-disposed-face ((t (:foreground ,mandm-fg
                                                         :slant italic))))
   `(wl-highlight-summary-new-face ((t (:foreground ,mandm-blue))))
   `(wl-highlight-summary-normal-face ((t (:foreground ,mandm-fg))))
   `(wl-highlight-summary-thread-top-face ((t (:foreground ,mandm-yellow))))
   `(wl-highlight-thread-indent-face ((t (:foreground ,mandm-violet))))
   `(wl-highlight-summary-refiled-face ((t (:foreground ,mandm-fg))))
   `(wl-highlight-summary-displaying-face ((t (:underline t :weight bold))))
;;;;; which-func-mode
   `(which-func ((t (:foreground ,mandm-green+4))))
;;;;; yascroll
   `(yascroll:thumb-text-area ((t (:background ,mandm-bg-1))))
   `(yascroll:thumb-fringe ((t (:background ,mandm-bg-1 :foreground ,mandm-bg-1))))
   ))

;;; Theme Variables
(mandm-with-color-variables
  (custom-theme-set-variables
   'mandm
;;;;; ansi-color
   `(ansi-color-names-vector [,mandm-bg ,mandm-red ,mandm-green ,mandm-yellow
                                          ,mandm-blue ,mandm-violet ,mandm-cyan ,mandm-fg])
;;;;; fill-column-indicator
   `(fci-rule-color ,mandm-bg-05)
;;;;; vc-annotate
   `(vc-annotate-color-map
     '(( 20. . ,mandm-red-1)
       ( 40. . ,mandm-red)
       ( 60. . ,mandm-orange)
       ( 80. . ,mandm-yellow-2)
       (100. . ,mandm-yellow-1)
       (120. . ,mandm-yellow)
       (140. . ,mandm-green-1)
       (160. . ,mandm-green)
       (180. . ,mandm-green+1)
       (200. . ,mandm-green+2)
       (220. . ,mandm-green+3)
       (240. . ,mandm-green+4)
       (260. . ,mandm-cyan)
       (280. . ,mandm-blue-2)
       (300. . ,mandm-blue-1)
       (320. . ,mandm-blue)
       (340. . ,mandm-blue+1)
       (360. . ,mandm-violet)))
   `(vc-annotate-very-old-color ,mandm-violet)
   `(vc-annotate-background ,mandm-bg-1)
   ))

;;; Rainbow Support

(declare-function rainbow-mode 'rainbow-mode)
(declare-function rainbow-colorize-by-assoc 'rainbow-mode)

(defvar mandm-add-font-lock-keywords nil
  "Whether to add font-lock keywords for mandm color names.
In buffers visiting library `mandm-theme.el' the mandm
specific keywords are always added.  In all other Emacs-Lisp
buffers this variable controls whether this should be done.
This requires library `rainbow-mode'.")

(defvar mandm-colors-font-lock-keywords nil)

;; (defadvice rainbow-turn-on (after mandm activate)
;;   "Maybe also add font-lock keywords for mandm colors."
;;   (when (and (derived-mode-p 'emacs-lisp-mode)
;;              (or mandm-add-font-lock-keywords
;;                  (equal (file-name-nondirectory (buffer-file-name))
;;                         "mandm-theme.el")))
;;     (unless mandm-colors-font-lock-keywords
;;       (setq mandm-colors-font-lock-keywords
;;             `((,(regexp-opt (mapcar 'car mandm-colors-alist) 'words)
;;                (0 (rainbow-colorize-by-assoc mandm-colors-alist))))))
;;     (font-lock-add-keywords nil mandm-colors-font-lock-keywords)))

;; (defadvice rainbow-turn-off (after mandm activate)
;;   "Also remove font-lock keywords for mandm colors."
;;   (font-lock-remove-keywords nil mandm-colors-font-lock-keywords))

;;; Footer

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'mandm)

;; Local Variables:
;; no-byte-compile: t
;; indent-tabs-mode: nil
;; eval: (when (require 'rainbow-mode nil t) (rainbow-mode 1))
;; End:

;;; mandm-theme.el ends here
