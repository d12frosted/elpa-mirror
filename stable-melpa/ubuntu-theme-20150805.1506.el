;;; ubuntu-theme.el --- A theme inspired by the default terminal colors in Ubuntu

;; Copyright (C) 2014, 2015 Francesc Rocher

;; Author: Francesc Rocher <francesc.rocher@gmail.com>
;; URL: http://github.com/rocher/ubuntu-theme
;; Package-Version: 20150805.1506
;; Package-Commit: 88b0eefc75d4cbcde103057e1c5968d4c3052f69
;; Version: 0.5.2

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

;; A color theme for Emacs 24 inspired by the default terminal colors in
;; Ubuntu.

;;; Code:

(deftheme ubuntu "Ubuntu color theme")

(custom-theme-set-faces
 'ubuntu
 '(button ((t (:inherit (link)))))
 '(cursor ((t (:background "white"))))
 '(custom-button ((t (:background "bisque1" :foreground "black" :box (:line-width 2 :style released-button)))))
 '(custom-button ((t (:background "bisque1" :foreground "black" :box (:line-width 2 :style released-button)))))
 '(custom-button-mouse ((t (:background "cornsilk" :foreground "black" :box (:line-width 2 :style released-button)))))
 '(custom-button-mouse ((t (:background "cornsilk" :foreground "black" :box (:line-width 2 :style released-button)))))
 '(custom-button-pressed ((t (:background "bisque4" :foreground "black" :box (:line-width 2 :style pressed-button)))))
 '(custom-button-pressed ((t (:background "bisque4" :foreground "black" :box (:line-width 2 :style pressed-button)))))
 '(custom-documentation ((t (:inherit default))))
 '(custom-group-subtitle ((t (:foreground "orange2" :underline t :weight normal :height 1.1 :family "Ubuntu Condensed"))))
 '(custom-group-tag ((t (:inherit default :foreground "orange red" :height 1.6 :family "Ubuntu Condensed"))))
 '(custom-variable-tag ((t (:foreground "orange1" :weight normal :height 1.2 :family "Ubuntu Condensed"))))
 '(custom-visibility ((t (:inherit link :height 0.9))))
 '(default ((t (:inherit nil :stipple nil :background "#300a24" :foreground "#e0e0e0" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :width normal :foundry "unknown" :family "Ubuntu Mono"))))
 '(diff-file-header ((t (:background "grey60" :foreground "black" :weight bold))))
 '(diff-refine-added ((t (:inherit diff-refine-change :background "#114411" :foreground "#11ff11"))))
 '(diff-refine-changed ((t (:background "#444411" :foreground "#ffff11"))))
 '(diff-refine-removed ((t (:inherit diff-refine-change :background "#441111" :foreground "#ff1111"))))
 '(ediff-current-diff-A ((t (:background "#553333" :foreground "ligth grey"))))
 '(ediff-current-diff-Ancestor ((t (:background "VioletRed" :foreground "white"))))
 '(ediff-current-diff-B ((t (:background "#335533" :foreground "light grey"))))
 '(ediff-current-diff-C ((t (:background "#888833" :foreground "white"))))
 '(ediff-even-diff-A ((t (:background "light grey" :foreground "dim grey"))))
 '(ediff-even-diff-Ancestor ((t (:background "ligth grey" :foreground "dim grey"))))
 '(ediff-even-diff-B ((t (:background "light grey" :foreground "dim grey"))))
 '(ediff-even-diff-C ((t (:background "light grey" :foreground "dim grey"))))
 '(ediff-fine-diff-A ((t (:background "#441111" :foreground "#ff1111"))))
 '(ediff-fine-diff-Ancestor ((t (:background "#114411" :foreground "#11ff11" :weight normal))))
 '(ediff-fine-diff-B ((t (:background "#114411" :foreground "#11ff11" :weight normal))))
 '(ediff-fine-diff-C ((t (:background "#444411" :foreground "#ffff11" :weight normal))))
 '(ediff-odd-diff-A ((t (:background "light grey" :foreground "dim gray"))))
 '(ediff-odd-diff-B ((t (:background "light grey" :foreground "dim gray"))))
 '(ediff-odd-diff-C ((t (:background "dim grey" :foreground "light grey"))))
 '(escape-glyph ((((background dark)) (:foreground "cyan")) (((type pc)) (:foreground "magenta")) (t (:foreground "brown"))))
 '(fixed-pitch ((t (:family "Ubuntu Mono"))))
 '(flycheck-fringe-error ((t (:background "#600000" :foreground "#ff4444" :weight bold))))
 '(flycheck-fringe-info ((t (:background "#006600" :foreground "green" :weight bold))))
 '(flycheck-fringe-warning ((t (:background "saddle brown" :foreground "yellow2" :weight bold))))
 '(font-lock-builtin-face ((t (:foreground "#FF7FD4"))))
 '(font-lock-comment-delimiter-face ((t (:inherit (font-lock-comment-face)))))
 '(font-lock-comment-face ((t (:foreground "#a5a5a5" :slant italic))))
 '(font-lock-constant-face ((t (:foreground "#8dd7e9"))))
 '(font-lock-doc-face ((t (:inherit (font-lock-string-face)))))
 '(font-lock-function-name-face ((t (:foreground "#1D68C4" :weight bold))))
 '(font-lock-function-name-face ((t (:foreground "#2D78f4" :weight bold))))
 '(font-lock-keyword-face ((t (:foreground "#5FB7CC"))))
 '(font-lock-negation-char-face ((t nil)))
 '(font-lock-preprocessor-face ((t (:inherit font-lock-builtin-face))))
 '(font-lock-regexp-grouping-backslash ((t (:inherit (bold)))))
 '(font-lock-regexp-grouping-construct ((t (:inherit (bold)))))
 '(font-lock-string-face ((t (:foreground "#aa3939"))))
 '(font-lock-type-face ((t (:foreground "#7FFFD4"))))
 '(font-lock-variable-name-face ((t (:foreground "#ffffaa"))))
 '(font-lock-warning-face ((t (:inherit (error)))))
 '(fringe ((t (:background "#1a0013"))))
 '(git-gutter+-added ((t (:background "#1a0013" :foreground "green2" :weight bold))))
 '(git-gutter+-deleted ((t (:background "#1a0013" :foreground "red" :weight bold))))
 '(git-gutter+-modified ((t (:background "#1a0013" :foreground "dark orange" :weight bold))))
 '(git-gutter+-unchanged ((t (:background "yellow" :foreground "black"))))
 '(header-line ((t (:box nil :foreground "grey90" :background "grey20" :inherit (mode-line)))))
 '(helm-M-x-key ((t (:foreground "coral" :underline t))))
 '(helm-action ((t (:underline t))))
 '(helm-buffer-directory ((t (:background "#300A24" :foreground "dodger blue" :weight bold))))
 '(helm-buffer-file ((t (:inherit font-lock-builtin-face))))
 '(helm-buffer-not-saved ((t (:background "#300A24" :foreground "Indianred2"))))
 '(helm-buffer-process ((t (:background "#300A24" :foreground "Sienna2"))))
 '(helm-buffer-saved-out ((t (:background "black" :foreground "red"))))
 '(helm-buffer-size ((t (:background "#300A24" :foreground "RosyBrown"))))
 '(helm-candidate-number ((t (:foreground "gold1"))))
 '(helm-etags-file ((t (:background "#300A24" :foreground "Lightgoldenrod2" :underline t))))
 '(helm-ff-directory ((t (:background "#300A24" :foreground "dodger blue" :weight bold))))
 '(helm-ff-dotted-directory ((t (:background "#300A24" :foreground "dodger blue" :weight bold))))
 '(helm-ff-executable ((t (:background "#300A24" :foreground "green2"))))
 '(helm-ff-file ((t (:inherit default))))
 '(helm-ff-invalid-symlink ((t (:background "black" :foreground "red" :weight bold))))
 '(helm-ff-prefix ((t (:background "gold" :foreground "black" :weight bold))))
 '(helm-ff-symlink ((t (:background "#300A24" :foreground "cyan2" :weight bold))))
 '(helm-grep-cmd-line ((t (:background "#300A24" :foreground "green3"))))
 '(helm-grep-file ((t (:background "#300A24" :foreground "medium purple" :underline t))))
 '(helm-grep-finish ((t (:background "#300A24" :foreground "Green1"))))
 '(helm-grep-lineno ((t (:background "#300A24" :foreground "Darkorange1"))))
 '(helm-grep-match ((t (:background "#300A24" :foreground "gold1"))))
 '(helm-grep-running ((t (:background "#300A24" :foreground "Red1" :weight bold))))
 '(helm-header ((t (:inherit header-line :weight normal :height 1.2 :family "Ubuntu Condensed"))))
 '(helm-header-line-left-margin ((t (:background "gold" :foreground "black"))))
 '(helm-history-deleted ((t (:inherit helm-ff-invalid-symlink))))
 '(helm-history-remote ((t (:background "#300A24" :foreground "indianred1"))))
 '(helm-lisp-completion-info ((t (:background "#300A24" :foreground "red"))))
 '(helm-lisp-show-completion ((t (:background "#300A24" :background "dim gray"))))
 '(helm-match ((t (:background "#300A24" :foreground "gold1"))))
 '(helm-match-item ((t (:inherit isearch))))
 '(helm-prefarg ((t (:background "#300A24" :foreground "green2"))))
 '(helm-selection ((t (:background "#1a000e"))))
 '(helm-selection-line ((t (:inherit highlight :distant-foreground "black"))))
 '(helm-separator ((t (:background "#300A24" :foreground "red1"))))
 '(helm-source-header ((t (:background "#300A24" :foreground "light pink" :underline t :weight normal :height 1.33 :family "Ubuntu Condensed"))))
 '(helm-visible-mark ((t (:background "green3" :foreground "black"))))
 '(highlight ((t (:background "#441133"))))
 '(hs-face ((t (:background "dark orange" :foreground "black"))))
 '(info-menu-header ((t (:foreground "bisque" :underline t :weight normal :height 1.2 :family "Ubuntu Condensed"))))
 '(info-title-1 ((t (:inherit info-title-2 :height 1.25))))
 '(info-title-2 ((t (:inherit info-title-3 :height 1.25))))
 '(info-title-3 ((t (:inherit info-title-4 :height 1.25))))
 '(info-title-4 ((t (:foreground "bisque" :weight normal :height 1.25 :family "Ubuntu Condensed"))))
 '(isearch ((t (:background "palevioletred1" :foreground "brown4"))))
 '(isearch ((t (:background "palevioletred1" :foreground "brown4"))))
 '(isearch-fail ((t (:background "red4" :foreground "white"))))
 '(isearch-fail ((t (:background "red4" :foreground "white"))))
 '(lazy-highlight ((((class color) (min-colors 88) (background light)) (:background "paleturquoise")) (((class color) (min-colors 88) (background dark)) (:background "paleturquoise4")) (((class color) (min-colors 16)) (:background "turquoise3")) (((class color) (min-colors 8)) (:background "turquoise3")) (t (:underline (:color foreground-color :style line)))))
 '(lazy-highlight ((t (:background "khaki3" :foreground "black"))))
 '(link ((t (:underline (:color foreground-color :style line) :foreground "deep sky blue"))))
 '(link-visited ((t (:foreground "violet" :inherit (link)))))
 '(linum ((t (:background "#300a24" :foreground "gainsboro" :box (:line-width 1 :color "#300a24") :slant normal :height 0.85))))
 '(match ((((class color) (min-colors 88) (background light)) (:background "yellow1")) (((class color) (min-colors 88) (background dark)) (:background "RoyalBlue3")) (((class color) (min-colors 8) (background light)) (:foreground "black" :background "yellow")) (((class color) (min-colors 8) (background dark)) (:foreground "white" :background "blue")) (((type tty) (class mono)) (:inverse-video t)) (t (:background "gray"))))
 '(minibuffer-prompt ((((background dark)) (:foreground "deep sky blue")) (((type pc)) (:foreground "magenta")) (t (:foreground "medium blue"))))
 '(mode-line ((t (:background "violetred4" :foreground "#FFFFf9" :box (:line-width 2 :color "violetred4")))))
 '(mode-line-buffer-id ((t (:weight bold))))
 '(mode-line-emphasis ((t (:weight bold))))
 '(mode-line-highlight ((t nil)))
 '(mode-line-inactive ((t (:background "#200019" :foreground "#999999" :box (:line-width 2 :color "#200019")))))
 '(next-error ((t (:inherit (region)))))
 '(query-replace ((t (:inherit (isearch)))))
 '(region ((t (:foreground "#FFFFFF" :background "#1D68C4"))))
 '(secondary-selection ((((class color) (min-colors 88) (background light)) (:background "yellow1")) (((class color) (min-colors 88) (background dark)) (:background "SkyBlue4")) (((class color) (min-colors 16) (background light)) (:background "yellow")) (((class color) (min-colors 16) (background dark)) (:background "SkyBlue4")) (((class color) (min-colors 8)) (:foreground "black" :background "cyan")) (t (:inverse-video t))))
 '(shadow ((((class color grayscale) (min-colors 88) (background light)) (:foreground "grey50")) (((class color grayscale) (min-colors 88) (background dark)) (:foreground "grey70")) (((class color) (min-colors 8) (background light)) (:foreground "green")) (((class color) (min-colors 8) (background dark)) (:foreground "yellow"))))
 '(show-tabs-space ((t (:background "orange3"))))
 '(show-tabs-tab ((t (:background "red3"))))
 '(term-color-blue ((t (:background "midnight blue" :foreground "dodger blue"))))
 '(term-color-cyan ((t (:background "cyan4" :foreground "cyan2"))))
 '(term-color-green ((t (:background "green4" :foreground "green2"))))
 '(term-color-magenta ((t (:background "magenta4" :foreground "magenta"))))
 '(term-color-red ((t (:background "red4" :foreground "red"))))
 '(term-color-yellow ((t (:background "yellow4" :foreground "yellow2"))))
 '(tooltip ((t (:foreground "black" :background "lightyellow" :inherit (variable-pitch)))))
 '(trailing-whitespace ((((class color) (background light)) (:background "red1")) (((class color) (background dark)) (:background "red1")) (t (:inverse-video t))))
 '(variable-pitch ((t (:family "Ubuntu"))))
 )

(when (macrop 'fringe-helper-define)
    (fringe-helper-define 'git-gutter-fr+-added nil
    "........"
    "..X....."
    "..XXX..."
    "..XXXX.."
    "..XXXX.."
    "..XXX..."
    "..X....."
    "........")

  (fringe-helper-define 'git-gutter-fr+-deleted nil
    "........"
    ".....X.."
    "...XXX.."
    "..XXXX.."
    "..XXXX.."
    "...XXX.."
    ".....X.."
    "........")

  (fringe-helper-define 'git-gutter-fr+-modified nil
    "........"
    "..XXXX.."
    "..XXXX.."
    "..XXXX.."
    "..XXXX.."
    "..XXXX.."
    "..XXXX.."
    "........")
  )

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'ubuntu)

;;; ubuntu-theme.el ends here
