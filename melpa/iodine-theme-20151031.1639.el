;;; iodine-theme.el --- A light emacs color theme

;; Copyright (C) 2015 Srđan Panić

;; Author: Srđan Panić <srdja.panic@gmail.com>
;; URL: https://github.com/srdja/iodine-theme
;; Package-Version: 20151031.1639
;; Package-Commit: 02fb780e1d8d8a6b9c709bfac399abe1665c6999
;; Version 0.1
;; Keywords: themes
;; Package-Requires: ((emacs "24"))

;; This program is free software: you can redistribute it and/or modify
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

;; Iodine is a light purplish emacs color theme

;;; Usage:

;; The theme can be loaded with M-x load-theme

;;; Code:

(deftheme iodine
  "Created 2015-10-20.")

(custom-theme-set-faces
 'iodine
 '(cursor              ((t (:background "#3e4155"))))
 '(fixed-pitch         ((t (:family "Monospace"))))
 '(variable-pitch      ((t (:family "Sans Serif"))))
 '(escape-glyph        ((t (:foreground "#008ED1"))))
 '(minibuffer-prompt   ((t (:background "#B1B1B1" :foreground "black" :weight bold))))
 '(highlight           ((t (:background "dark violet" :foreground "white" :underline nil))))
 '(region              ((t (:background "#c5cdff" :foreground "black"))))
 '(shadow              ((t (:foreground "#7F7F7F"))))
 '(secondary-selection ((t (:weight bold :background "#FBE448"))))
 '(trailing-whitespace ((t (:background "#FFFF57"))))

 '(font-lock-builtin-face              ((t (:foreground "black" :weight ultra-bold))))
 '(font-lock-comment-delimiter-face    ((t (:foreground "#8D8D84"))))
 '(font-lock-comment-face              ((t (:foreground "dark gray" :slant italic))))
 '(font-lock-constant-face             ((t (:foreground "dark slate gray" :weight ultra-bold))))
 '(font-lock-doc-face                  ((t (:foreground "#7D9C9F" :weight normal))))
 '(font-lock-function-name-face        ((t (:foreground "black" :weight bold))))
 '(font-lock-keyword-face              ((t (:foreground "black" :weight ultra-bold))))
 '(font-lock-negation-char-face        ((t (:foreground "black" :weight ultra-bold))))
 '(font-lock-preprocessor-face         ((t (:foreground "#808080"))))
 '(font-lock-regexp-grouping-backslash ((t (:weight bold :inherit nil))))
 '(font-lock-regexp-grouping-construct ((t (:weight bold :inherit nil))))
 '(font-lock-string-face               ((t (:foreground "orange red" :slant italic))))
 '(font-lock-type-face                 ((t (:foreground "dark violet" :weight extra-bold))))
 '(font-lock-variable-name-face        ((t (:foreground "#007781" :weight normal))))
 '(font-lock-warning-face              ((t (:weight bold :foreground "red"))))

 '(button                 ((t (:foreground "dark violet" :box nil :overline nil :underline nil))))
 '(link                   ((t (:foreground "dark violet" :underline t :weight normal))))
 '(link-visited           ((t (:foreground "#E5786D" :underline nil))))
 '(fringe                 ((t (:background "#ededed" :foreground "black" :weight light :width ultra-condensed))))
 '(header-line            ((t (:weight bold :foreground "#dfeff0" :background "#1e2626"))))
 '(tooltip                ((t (:foreground "black" :background "light yellow"))))
 '(mode-line              ((t (:background "#2b2d3b" :foreground "#c8d0ff" :box (:line-width 1 :color "#222b2b")))))
 '(mode-line-buffer-id    ((t (:foreground "white" :weight bold))))
 '(mode-line-emphasis     ((t (:foreground "white" :weight bold))))
 '(mode-line-highlight    ((t (:background "#1e2626" :foreground "#dfeff0"))))
 '(mode-line-inactive     ((t (:box (:line-width 1 :color "#4E4E4C" :style nil) :foreground "#F0F0EF" :background "#9B9C97"))))
 '(isearch                ((t (:background "#732C7B" :foreground "white" :underline nil :weight bold))))
 '(isearch-fail           ((t (:weight bold :foreground "black" :background "#FF9999"))))
 '(lazy-highlight         ((t (:background "#BDAEC6" :foreground "black" :underline nil))))
 '(match                  ((t (:background "#FBE448" :underline nil :weight bold))))
 '(next-error             ((t (:underline nil :background "#FFF876"))))
 '(query-replace          ((t (:inherit isearch))))
 '(linum                  ((t (:background "#3e4155" :foreground "white"))))
 '(tty-menu-selected-face ((t (:background "red"))))
 '(ido-first-match        ((t (:foreground "dark violet" :weight bold))))
 '(menu                   ((t nil)))

 '(ido-subdir             ((t (:foreground "dark slate gray"))))
 '(ido-incomplete-regexp  ((t (:foreground "dark slate gray" :weight ultra-bold))))
 '(ido-only-match         ((t (:foreground "#007781"))))
 '(ido-virtual            ((t (:inherit (font-lock-builtin-face)))))
 '(ido-indicator          ((((min-colors 88) (class color))
                            (:width condensed :background "red1" :foreground "yellow1"))
                           (((class color))
                            (:width condensed :background "red" :foreground "yellow"))
                           (t (:inverse-video t))))

 '(buffer-menu-buffer             ((t (:weight bold))))
 '(border                         ((t nil)))
 '(custom-button                  ((t (:background "lightgrey" :foreground "black" :box nil))))
 '(custom-button-pressed          ((t (:background "light grey" :foreground "black" :box nil))))
 '(custom-button-unraised         ((t (:box nil))))
 '(custom-button-mouse            ((t (:background "grey90" :foreground "dark violet" :box nil))))
 '(custom-button-pressed-unraised ((t (:underline (:color foreground-color :style line) :foreground "magenta4"))))
 '(custom-set                     ((t (:background "white" :foreground "magenta4"))))
 '(custom-link                    ((t (:foreground "dark violet" :underline t))))
 '(custom-rogue                   ((((class color))
                                    (:background "black" :foreground "pink"))
                                   (t
                                    (:underline (:color foreground-color :style line)))))


 '(widget-button             ((t (:weight bold))))

 '(widget-button-pressed     ((((min-colors 88) (class color))
                               (:foreground "red1"))
                              (((class color))
                               (:foreground "red"))
                              (t
                               (:underline (:color foreground-color :style line) :weight bold))))

 '(window-divider-last-pixel ((t (:foreground "gray40"))))
 '(underline                 ((t (:underline (:color foreground-color :style line)))))
 '(custom-group-tag          ((t (:foreground "dark violet" :weight bold :height 1.2))))
 '(custom-documentation      ((t nil)))
 '(default                   ((t
                               (:family "DejaVu Sans Mono"
                                        :foundry "unknown"
                                        :width normal
                                        :height 98
                                        :weight normal
                                        :slant normal
                                        :underline nil
                                        :overline nil
                                        :strike-through nil
                                        :box nil
                                        :inverse-video nil
                                        :foreground "#333333"
                                        :background "#FFFFFF"
                                        :stipple nil
                                        :inherit nil))))

 '(rainbow-delimiters-depth-1-face    ((t (:foreground "black"))))
 '(rainbow-delimiters-depth-2-face    ((t (:foreground "magenta4" :weight semi-bold))))
 '(rainbow-delimiters-depth-3-face    ((t (:foreground "orange red" :weight normal))))
 '(rainbow-delimiters-depth-4-face    ((t (:foreground "#007781" :weight semi-bold))))
 '(rainbow-delimiters-depth-5-face    ((t (:foreground "magenta4" :weight semi-bold))))
 '(rainbow-delimiters-depth-6-face    ((t (:foreground "orange red" :weight normal))))
 '(rainbow-delimiters-depth-7-face    ((t (:foreground "#007781" :weight semi-bold))))
 '(rainbow-delimiters-depth-8-face    ((t (:foreground "magenta4" :weight semi-bold))))
 '(rainbow-delimiters-depth-9-face    ((t (:foreground "orange red" :weight normal))))
 '(rainbow-delimiters-mismatched-face ((t (:underline (:color "red" :style line) :background "#FFDCDC"))))
 '(rainbow-delimiters-unmatched-face  ((t (:underline (:color "red" :style line) :background "#FFDCDC"))))

 '(info-node         ((t (:foreground "magenta4"))))
 '(info-header-xref  ((t (:foreground "dark violet"))))
 '(info-header-node  ((t (:foreground "#E5786D" :underline t))))
 '(info-menu-header  ((t (:background "#c5cdff" :foreground "#123555" :overline "#123555" :weight bold :height 1.0))))
 '(info-title-2      ((t (:height 1.2 :inherit (info-title-3)))))
 '(info-title-4      ((t (:weight bold :inherit (variable-pitch)))))
 '(info-xref-visited ((t (:underline (:color foreground-color :style line) :foreground "magenta4"))))
 '(info-index-match  ((t (:inherit (match)))))
 '(info-menu-star    ((t (:foreground "black"))))
 '(info-title-1      ((t (:background "#c5cdff" :foreground "#2b2d3b" :weight bold :height 1.3))))
 '(info-title-3      ((t (:height 1.2 :inherit (info-title-4)))))
 '(info-xref         ((t (:foreground "dark violet")))))

;;;###autoload
(when (and load-file-name (boundp 'custom-theme-load-path))
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'iodine)
;;; iodine-theme.el ends here
