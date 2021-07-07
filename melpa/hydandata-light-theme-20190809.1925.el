;;; hydandata-light-theme.el --- A light color theme that is easy on your eyes

;;; Copyright (C) 2019 David Chkhikvadze
;;; Copyright (C) 2010 Yves Senn

;;; Author: David Chkhikvadze <david@chkhd.net>
;;; Homepage: https://github.com/chkhd/hydandata-light-theme
;;; Version: 0.2
;; Package-Version: 20190809.1925
;; Package-Commit: 180c3797fa7ef3e4bb679baaf5b492c33bbb9b8b
;;; Created: 01 January 2016
;;; Keywords: color-theme theme

;;; This file is NOT part of GNU Emacs.

;;; License:

;;; This program is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3, or (at your option)
;;; any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to the
;;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;;; Boston, MA 02110-1301, USA.

;;; Commentary:

;;; A light color theme with bluish tint that is very easy on your
;;; eyes. Extracted from senny/theme-roller.el and modified for modern
;;; Emacs deftheme.

;;; Code:

(deftheme hydandata-light
  "Light theme based on the one included with theme-roller by Yves Senn.")

(custom-theme-set-faces
 'hydandata-light
 '(default ((t (:inherit nil :stipple nil :background "#f8f8ff" :foreground "black" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :width normal :bold nil))))
 '(hl-line ((t (:background "#effca6"))))
 '(highlight ((t (:background "#acc3e6"))))
 '(region ((t (:background "#bcd5fa"))))
 '(mode-line ((t (:background "#bcd5fa" :foreground "black"))))
 '(minibuffer-prompt ((t (:foreground "#445588"))))
 '(minibuffer-noticeable-prompt ((t (:foreground "#445588"))))
 '(link ((t (:foreground "blue1" :underline t))))
 '(fringe ((t (:background "gray95" :foreground "black"))))
 '(linum ((t (:inherit fringe))))
 '(cursor ((t (:foreground "black" :background "black"))))

 '(show-paren-match ((t (:background "#bcd5fa" :foreground "white"))))
 '(show-paren-mismatch ((t (:bold t :background "#9d1e15" :foreground "#f8f8f8"))))

 '(font-lock-warning-face ((t (:background "#ffe4b5"))))
 '(font-lock-comment-face ((t (:italic t :foreground "#999999" :slant italic))))
 '(font-lock-comment-delimiter-face ((t (:inherit font-lock-comment-face))))
 '(font-lock-builtin-face ((t (:inherit default))))
 '(font-lock-constant-face ((t (:foreground "#3b5bb5"))))
 '(font-lock-doc-face ((t (:foreground "#409b1c"))))
 '(font-lock-doc-string-face ((t (:inherit font-lock-doc-face))))
 '(font-lock-function-name-face ((t (:inherit default :bold t))))
 '(font-lock-keyword-face ((t (:bold t :weight bold :foreground "#ff7800"))))
 '(font-lock-preprocessor-face ((t (:foreground "#3a4a64" :background "gray95"))))

 '(font-lock-reference-face ((t (nil))))
 '(font-lock-negatoin-char-face ((t (nil))))

 '(font-lock-regexp-grouping-backslash ((t (:inheirt font-lock-comment-face))))
 '(font-lock-regexp-grouping-construct ((t (:foreground "red"))))
 '(font-lock-string-face ((t (:foreground "#409b1c"))))
 '(font-lock-type-face ((t (:foreground "#445588"))))
 '(font-lock-variable-name-face ((t (:foreground "#671ebb"))))

 '(mac-ts-caret-position ((t (:background "#effca6"))))

 '(whitespace-line ((t (:inherit font-lock-code-warning))))
 '(whitespace-tab ((t (:inherit font-lock-code-warning))))

 '(compilation-info ((t (:inherit font-lock-string-face))))
 '(compilation-line-number ((t (:foreground "#3b5bb5"))))

 '(flymake-errline ((t (:bold t :background "#9d1e15" :foreground "#f8f8f8"))))
 '(flymake-warnline ((t (:inherit font-lock-warning-face))))

 '(flycheck-error ((t (:inherit font-lock-warning-face))))
 '(flycheck-error-list-error ((t (:inherit font-lock-warning-face))))
 '(flycheck-fringe-error ((t (:inherit font-lock-warning-face))))
 '(flycheck-color-mode-line-info-face ((t (:inherit highlight))))
 '(flycheck-color-mode-line-warning-face ((t (:inherit flycheck-fringe-error))))
 '(flycheck-color-mode-line-error-face ((t (:inherit flycheck-fringe-error))))

 '(diff-header ((t (:background "LightSteelBlue3"))))
 '(diff-file-header ((t (:inherit diff-header :bold t))))
 '(diff-added ((t (:background "DarkOliveGreen3"))))
 '(diff-removed ((t (:background "IndianRed1"))))
 '(diff-changed ((t (:background "burlywood3"))))
 '(diff-context ((t (:background "gray90"))))
 '(diff-index ((t (:inherit font-lock-comment-face))))
 '(diff-refine-change ((t (:inherit font-lock-comment-face))))

 '(magit-item-highlight ((t (:background nil :bold t))))
 '(magit-diff-add ((t (:inherit diff-added))))
 '(magit-diff-del ((t (:inherit diff-removed))))
 '(magit-diff-none ((t (:inherit diff-context))))
 '(magit-log-sha1 ((t (:inherit font-lock-code-keyword))))
 '(magit-log-head-label-remote ((t (:inherit font-lock-string-face :box t))))
 '(magit-log-head-label-local ((t (:inherit font-lock-variable-name-face :box t))))

 '(ediff-current-diff-A ((t (:background "#01243C" :foreground "white"))))
 '(ediff-current-diff-Ancestor ((t (:background "#4D0600" :foreground "white"))))
 '(ediff-current-diff-B ((t (:background "#574A00" :foreground "white"))))
 '(ediff-current-diff-C ((t (:background "#5C285C" :foreground "white"))))
 '(ediff-even-diff-A ((t (:background "#222222"))))
 '(ediff-even-diff-Ancestor ((t (:background "#222222"))))
 '(ediff-even-diff-B ((t (:background "#222222"))))
 '(ediff-even-diff-C ((t (:background "#222222"))))
 '(ediff-fine-diff-A ((t (:background "#0B5C00" :foreground "white"))))
 '(ediff-fine-diff-Ancestor ((t (:background "#0B5C00" :foreground "white"))))
 '(ediff-fine-diff-B ((t (:background "#0B5C00" :foreground "white"))))
 '(ediff-fine-diff-C ((t (:background "#0B5C00" :foreground "white"))))
 '(ediff-odd-diff-A ((t (:background "#222222"))))
 '(ediff-odd-diff-Ancestor ((t (:background "#222222"))))
 '(ediff-odd-diff-B ((t (:background "#222222"))))
 '(ediff-odd-diff-C ((t (:background "#222222"))))

 '(org-done ((t (:inherit font-lock-string-face :bold t))))
 '(org-todo ((t (:inherit font-lock-variable-name-face :bold t))))
 '(org-level-1 ((t (:inherit default :underline t :bold t))))
 '(org-level-2 ((t (:inherit font-lock-variable-name-face))))
 '(org-level-3 ((t (:inherit font-lock-keyword-face))))
 '(org-level-4 ((t (:inherit font-lock-type-face))))
 '(org-special-keyword ((t (:inherit font-lock-doc-face))))

 '(newsticker-treeview-selection-face ((t (:inherit highlight))))
 '(newsticker-treeview-face ((t (:inherit default))))
 '(newsticker-treeview-immortal-face ((t (:inherit font-lock-keyword-face))))

 '(js2-error-face ((t (:bold t :background "#9d1e15" :foreground "#f8f8f8"))))
 '(js2-external-variable-face ((t (:inherit font-lock-variable-name-face))))
 '(js2-function-param-face ((t (:inherit font-lock-variable-name-face))))
 '(js2-instance-member-face ((t (:inherit font-lock-variable-name-face))))
 '(js2-private-function-call-face ((t (:inherit default))))
 '(js2-private-member-face ((t (:inherit font-lock-variable-name-face))))
 '(js2-warning-face ((t (:inherit font-lock-warning-face))))

 '(html-tag-face ((t (:inherit font-lock-keyword-face))))

 '(sgml-namespace ((t (:inherit font-locl-type-face))))
 '(css-selector ((t (:inherit font-lock-keyword-face))))

 '(border-glyph ((t (nil)))) ; flat borders
 '(left-fringe ((t (nil)))))

;;;###autoload
(when load-file-name
  (add-to-list
   'custom-theme-load-path
   (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'hydandata-light)

;;; hydandata-light-theme.el ends here
