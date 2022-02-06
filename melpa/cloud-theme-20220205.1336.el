;;; cloud-theme.el --- A light colored theme -*- lexical-binding: t -*-

;; Copyright (C) 2019 Valerii Lysenko

;; Author: Valerii Lysenko <vallyscode@gmail.com>
;; Maintainer: Valerii Lysenko <vallyscode@gmail.com>
;; Keywords: color theme
;; Package-Version: 20220205.1336
;; Package-Commit: 16372ea1f527917102ac302afaec3ef09e289d24
;; URL: https://github.com/vallyscode/cloud-theme
;; Version: 0.1
;; Package: cloud-theme
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

;; This file is NOT part of GNU Emacs

;;; Commentary:

;; To use it, put the following in your Emacs configuration file:
;;
;; (use-package cloud-theme
;;   :ensure t
;;   :config
;;   (load-theme 'cloud t))
;;

;;; Code:

(defgroup cloud nil
  "Cloud theme options."
  :group 'faces)

(deftheme cloud
  "Cloud light color theme.")

(let ((class '((class color) (min-colors 89))))
  (custom-theme-set-faces
   'cloud
   `(default ((,class (:background "#f2f2f2" :foreground "#454545"))))


   `(cursor ((,class (:background "#00638a" :foreground "#f2f2f2" ))))
   `(fringe ((,class (:background "#f2f2f2" :foreground "#454545"  ))))
   `(border ((,class (:foreground "#2f7e9d"))))
   `(vertical-border ((,class (:foreground "#2f7e9d"))))
   `(highlight ((,class (:background "#fffbc4"))))
   `(region ((,class (:background "#3389ab" :foreground "#f2f2f2"))))
   `(secondary-selection ((,class (:weight bold :background "#fffbc4"))))
   `(isearch ((,class (:foreground "#f2f2f2" :background "#008abd"))))
   `(isearch-fail ((,class (:weight bold :foreground "#f2f2f2" :background "#d0372d"))))
   `(query-replace ((,class (:inherit isearch))))
   `(lazy-highlight ((,class (:foreground "#454545" :background "#fffbc4")))) ; Isearch others (see `match').
   `(hl-line ((,class (:background "#ededed"))))
   `(shadow ((,class ((:foreground "#cccccc")))))
   `(match ((,class (:weight bold :background "#fffbc4"))))
   `(show-paren-match ((,class (:background "#cccccc" :foreground "#2f7e9d"))))
   `(show-paren-mismatch ((,class (:background "#cccccc" :foreground "#d0372d"))))
   `(trailing-whitespace ((,class (:foreground "#d0d0d0" :background "#f2f2f2"))))


   `(button ((,class (:underline t :foreground "#2f7e9d"))))
   `(help-argument-name ((,class (:foreground "#2f7e9d"))))
   `(info-menu-star ((,class (:foreground "#2f7e9d"))))
   `(next-error ((,class (:inherit error))))
   `(nobreak-space ((,class (:background "#b48cff"))))
   `(file-name-shadow ((,class (:foreground "#cccccc"))))


   `(line-number ((,class (:background "#f2f2f2" :foreground "#8c8c8c"))))
   `(line-number-current-line ((,class (:background "#f2f2f2" :foreground "#cc6d00"))))


   `(linum ((,class (:background "#f2f2f2" :foreground "#8c8c8c"))))
   `(linum-highlight-face ((,class (:background "#f2f2f2" :foreground "#8c8c8c"))))


   `(font-lock-builtin-face ((,class (:foreground "#7d57c2"))))
   `(font-lock-comment-delimiter-face ((,class (:weight normal :foreground "#919aa1"))))
   `(font-lock-comment-face ((,class (:slant italic :weight normal :foreground "#919aa1"))))
   `(font-lock-constant-face ((,class (:foreground "#008080"))))
   `(font-lock-doc-face ((,class (:slant italic :weight normal :foreground "#678f03"))))
   `(font-lock-function-name-face ((,class (:foreground "#454545"))))
   `(font-lock-keyword-face ((,class (:weight bold :foreground "#00638a"))))
   `(font-lock-preprocessor-face ((,class (:foreground "#7d57c2"))))
   `(font-lock-regexp-grouping-backslash ((,class (:weight bold :inherit nil))))
   `(font-lock-regexp-grouping-construct ((,class (:weight bold :inherit nil))))
   `(font-lock-string-face ((,class (:foreground "#678f03"))))
   `(font-lock-type-face ((,class (:weight bold :foreground "#008abd"))))
   `(font-lock-variable-name-face ((,class (:weight normal :foreground "#454545"))))
   `(font-lock-warning-face ((,class (:weight bold :foreground "#cc6d00"))))


   `(mode-line ((,class (:background "#2f7e9d" :foreground "#f2f2f2" :box (:line-width 1 :color "#2f7e9d")))))
   `(mode-line-inactive ((,class (:background "#cccccc" :foreground "#f2f2f2" :box (:line-width 1 :color "#cccccc")))))
   `(mode-line-buffer-id ((,class (:weight bold))))
   `(mode-line-emphasis ((,class (:foreground "#f2f2f2"))))
   `(mode-line-highlight ((,class (:background "#fffbc4" :foreground "#454545"))))
   `(header-line ((,class (:background "#2f7e9d" :foreground "#f2f2f2" :box (:line-width 1 :color "#2f7e9d")))))
   `(header-line-highlight ((,class (:background "#fffbc4" :foreground "#454545"))))


   `(error ((,class (:weight bold :foreground "#d0372d"))))
   `(warning ((,class (:weight bold :foreground "#cc6d00"))))
   `(success ((,class (:weight bold :foreground "#2e994c"))))


   `(minibuffer-prompt ((,class (:weight bold :foreground "#2f7e9d"))))
   `(minibuffer-noticeable-prompt ((,class (:weight bold :foreground "#2f7e9d"))))
   `(escape-glyph ((,class (:weight bold :foreground "#b48cff"))))


   `(whitespace-hspace ((,class (:foreground "#cccccc"))))
   `(whitespace-indentation ((,class (:background nil :foreground "#454545"))))
   `(whitespace-line ((,class (:foreground "#e67373" :background "#f2f2f2"))))
   `(whitespace-tab ((,class (:background nil :foreground "#454545"))))
   `(whitespace-trailing ((,class (:background nil :foreground "#e67373"))))
   `(whitespace-space ((,class (:background nil :foreground "#d0d0d0"))))`
   `(whitespace-newline ((,class (:background nil :foreground "#d0d0d0"))))`
   `(window-divider ((,class (:background "#2f7e9d"))))
   `(window-divider-first-pixel ((,class (:background "#2f7e9d"))))
   `(window-divider-last-pixel ((,class (:background "#2f7e9d"))))


   `(link ((,class (:underline t :foreground "#006c96"))))
   `(link-visited ((,class (:underline t :foreground "#6c4ca8"))))


   `(dired-header ((,class (:weight bold :foreground "#2f7e9d" :background "#f2f2f2"))))
   `(dired-directory ((,class (:weight bold :foreground "#2f7e9d" :background "#f2f2f2"))))
   `(dired-ignored ((,class (:strike-through t :foreground "#d0372d"))))
   `(dired-mark ((,class (:foreground "#d0372d" :background "#f2f2f2"))))
   `(dired-marked ((,class (:foreground "#d0372d" :background "#ffdddd"))))
   `(dired-symlink ((,class (:foreground "#855dcf"))))
   `(dired-special ((,class (:foreground "#d0372d" :background "#ffdddd"))))


   `(diredfl-number ((,class (:foreground "#cc6d00" :background "#f2f2f2"))))
   `(diredfl-date-time ((,class (:slant italic :foreground "#8c8c8c" :background "#f2f2f2"))))
   `(diredfl-write-priv ((,class (:weight bold :foreground "#d0372d" :background "#f2f2f2"))))
   `(diredfl-read-priv ((,class (:weight bold :foreground "#22863a" :background "#f2f2f2"))))
   `(diredfl-exec-priv ((,class (:weight bold :foreground "#855dcf" :background "#f2f2f2"))))
   `(diredfl-dir-heading ((,class (:foreground "#2f7e9d" :background "#f2f2f2"))))
   `(diredfl-dir-name ((,class (:foreground "#2f7e9d" :background "#f2f2f2"))))
   `(diredfl-file-name ((,class (:foreground "#454545" :background "#f2f2f2"))))
   `(diredfl-file-suffix ((,class (:foreground "#454545" :background "#f2f2f2"))))
   `(diredfl-no-priv ((,class (:foreground "#454545" :background "#f2f2f2"))))
   `(diredfl-dir-priv ((,class (:foreground "#6c7378" :background "#f2f2f2"))))
   `(diredfl-link-priv ((,class (:foreground "#855dcf" :background "#f2f2f2"))))
   `(diredfl-rare-priv ((,class (:foreground "#d70087" :background "#f2f2f2"))))


   `(diff-added ((,class (:background "#ddffdd" :foreground "#22863a"))))
   `(diff-removed ((,class (:background "#ffdddd" :foreground "#d0372d"))))
   `(diff-changed ((,class (:background "#f8f1d3" :foreground "#bf7000"))))
   `(diff-refine-added ((,class (:background "#cceecc"))))
   `(diff-refine-removed ((,class (:background "#eecccc"))))
   `(diff-refine-changed ((,class (:background "#fce8c9"))))
   `(diff-header ((,class (:foreground "#8c8c8c" :background "#f2f2f2"))))
   `(diff-file-header ((,class (:foreground "#2f7e9d" :background "#f2f2f2"))))
   `(diff-hunk-header ((,class (:weight bold :foreground "#6f42c1" :background "#f2f2f2"))))
   `(diff-index ((,class (:foreground "#8c8c8c" :background "#f2f2f2"))))
   `(diff-indicator-added ((,class (:foreground "#22863a" :background "#ddffdd"))))
   `(diff-indicator-removed ((,class (:foreground "#d0372d" :background "#ffdddd"))))
   `(diff-indicator-changed ((,class (:foreground "#bf7000" :background "#f8f1d3"))))
   `(diff-nonexistent ((,class (:foreground "#454545"))))


   `(ediff-current-diff-A ((,class (:background "#ffdddd"))))
   `(ediff-current-diff-B ((,class (:background "#ddffdd"))))
   `(ediff-current-diff-C ((,class (:background "#f8f1d3"))))
   `(ediff-even-diff-A ((,class (:background "#cccccc"))))
   `(ediff-even-diff-B ((,class (:background "#cccccc"))))
   `(ediff-fine-diff-A ((,class (:background "#eecccc"))))
   `(ediff-fine-diff-B ((,class (:background "#cceecc"))))
   `(ediff-odd-diff-A ((,class (:background "#cccccc"))))
   `(ediff-odd-diff-B ((,class (:background "#cccccc"))))


   `(company-tooltip-common-selection ((,class (:weight normal :foreground "#f2f2f2"))))
   `(company-tooltip-selection ((,class (:weight normal :foreground "#f2f2f2" :background "#2f7e9d"))))
   `(company-tooltip-annotation-selection ((,class (:weight normal :foreground "eeeeee"))))
   `(company-tooltip-common ((,class (:weight bold))))
   `(company-tooltip ((,class (:foreground "#454545" :background "#cccccc"))))
   `(company-tooltip-annotation ((,class (:weight normal :foreground "#7d57c2"))))
   `(company-preview-common ((,class (:weight normal :foreground "#2f7e9d" :inherit hl-line))))
   `(company-scrollbar-bg ((,class (:background "#cccccc"))))
   `(company-scrollbar-fg ((,class (:background "#8c8c8c"))))


   `(eldoc-highlight-function-argument ((,class (:foreground "#008abd" :weight bold))))


   `(haskell-pragma-face ((,class (:foreground "#7d57c2"))))
   `(haskell-keyword-face ((,class (:foreground "#2f7e9d"))))
   `(haskell-operator-face ((,class (:foreground "#d70087"))))
   `(haskell-type-face ((,class (:weight bold :foreground "#008abd"))))


   `(which-func ((,class (:foreground "#7d57c2"))))


   `(undo-tree-visualizer-current-face ((,class (:foreground "#cc6d00"))))
   `(undo-tree-visualizer-active-branch-face ((,class (:foreground "#b48cff"))))
   `(undo-tree-visualizer-default-face ((,class (:foreground "#6c4ca8"))))
   `(undo-tree-visualizer-register-face ((,class (:foreground "#678f03"))))
   `(undo-tree-visualizer-unmodified-face ((,class (:foreground "#6c7378"))))


   `(grep-context-face ((,class (:foreground "#919aa1"))))
   `(grep-error-face ((,class (:foreground "#d0372D"))))
   `(grep-hit-face ((,class (:foreground "#2f7e9d"))))
   `(grep-match-face ((,class (:foreground nil :background nil :inherit match))))


   `(regex-tool-matched-face ((,class (:foreground nil :background nil :inherit match))))


   `(compilation-column-number ((,class (:foreground "#cc6d00"))))
   `(compilation-line-number ((,class (:foreground "#cc6d00"))))
   `(compilation-message-face ((,class (:foreground "#2f7e9d"))))
   `(compilation-error ((,class (:foreground "#ff9999"))))
   `(compilation-warning ((,class (:foreground "#f4ad49"))))
   `(compilation-info ((,class (:foreground "#b4efb4"))))
   `(compilation-mode-line-fail ((,class (:foreground "#ff9999"))))
   `(compilation-mode-line-exit ((,class (:foreground "#b4efb4"))))
   `(compilation-mode-line-run ((,class (:foreground "#b48cff"))))

   `(eglot-mode-line ((,class (:foreground "#f2f2f2" :weight bold))))

   `(xref-file-header ((,class (:weight bold :foreground "#2f7e9d" :background "#f2f2f2"))))

   `(flycheck-info ((,class (:underline (:color "#2e994c" :style wave) :weight bold))))
   `(flycheck-warning ((,class (:underline (:color "#cc6d00" :style wave) :weight bold))))
   `(flycheck-error ((,class (:underline (:color "#d0372d" :style wave) :weight bold))))
   `(flycheck-fringe-info ((,class (:foreground "#2e994c"))))
   `(flycheck-fringe-warning ((,class (:foreground "#cc6d00"))))
   `(flycheck-fringe-error ((,class (:foreground "#d0372d"))))
   `(flycheck-warning ((,class (:underline (:color "#cc6d00" :style wave)))))
   `(flycheck-error ((,class (:underline (:color "#d0372d" :style wave)))))
   `(flycheck-error-list-line-number ((,class (:foreground "#7d57c2"))))


   `(helm-M-x-key ((,class (:foreground "#2e994c"))))
   `(helm-action ((,class (:foreground "#454545"))))
   `(helm-header ((,class (:foreground "#f2f2f2" :background "#008abd"))))
   `(helm-moccur-buffer ((,class (:foreground "#454545" :background "#cfd8dc"))));;highlight moccur buffer name
   `(helm-source-header ((,class (:foreground "#454545" :background "#cfd8dc" :height 1.3 :bold t))))
   `(helm-match ((,class (:foreground "#454545" :background "#fffbc4"))))
   `(helm-selection ((,class (:background "#cccccc"))))
   `(helm-selection-line ((,class (:background "#f2f2f2"))))
   `(helm-separator ((,class (:foreground "#454545"))))
   `(helm-visible-mark ((,class (:foreground "#d0372d" :background "#ffdddd"))))
   `(helm-buffer-directory ((,class (:foreground "#2f7e9d" :weight normal))))
   `(helm-buffer-file ((,class (:foreground "#454545"))))
   `(helm-buffer-not-saved ((,class (:foreground "#f4ad49"))))
   `(helm-buffer-process ((,class (:foreground "#d0372d"))))
   `(helm-buffer-saved-out ((,class (:foreground "#d0372d"))))
   `(helm-buffer-size ((,class (:foreground "#cc6d00"))))
   `(helm-candidate-number ((,class (:foreground "#f2f2f2" :background "#cc6d00"))))
   `(helm-ff-directory ((,class (:foreground "#2f7e9d" :weight bold))))
   `(helm-ff-executable ((,class (:foreground "#2e994c"))))
   `(helm-ff-file ((,class (:foreground "#454545"))))
   `(helm-ff-invalid-symlink ((,class (:foreground "#7d57c2" :background "#ffdddd"))))
   `(helm-ff-symlink ((,class (:foreground "#7d57c2"))))


   `(which-key-key-face ((,class (:foreground "#7d57c2" :weight bold))))
   `(which-key-special-key-face ((,class (:foreground "#d70087"  :weight bold :height 1.1))))
   `(which-key-command-description-face ((,class (:foreground "#454545" ))))
   `(which-key-group-description-face ((,class (:foreground "#2f7e9d"))))
   `(which-key-separator-face ((,class (:foreground "#919aa1"))))


   `(rainbow-delimiters-depth-1-face ((,class (:foreground "#00638a"))))
   `(rainbow-delimiters-depth-2-face ((,class (:foreground "#7d57c2"))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground "#008080"))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground "#2e994c"))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground "#00638a"))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground "#7d57c2"))))
   `(rainbow-delimiters-depth-7-face ((,class (:foreground "#008080"))))
   `(rainbow-delimiters-depth-8-face ((,class (:foreground "#2e994c"))))
   `(rainbow-delimiters-depth-9-face ((,class (:foreground "#00638a"))))
   `(rainbow-delimiters-depth-10-face ((,class (:foreground "#7d57c2"))))
   `(rainbow-delimiters-depth-11-face ((,class (:foreground "#008080"))))
   `(rainbow-delimiters-depth-12-face ((,class (:foreground "#2e994c"))))


   `(outline-1 ((,class (:height 1.3 :weight bold :foreground "#008abd"))))
   `(outline-2 ((,class (:height 1.2 :weight bold :foreground "#7d57c2"))))
   `(outline-3 ((,class (:height 1.1 :weight bold :foreground "#cc6d00"))))
   `(outline-4 ((,class (:height 1.0 :weight bold :foreground "#2e994c"))))
   `(outline-5 ((,class (:height 1.0 :weight bold :foreground "#00638a"))))
   `(outline-6 ((,class (:height 1.0 :weight bold :foreground "#D0372D"))))
   `(outline-7 ((,class (:height 1.0 :weight bold :foreground "#008080"))))
   `(outline-8 ((,class (:height 1.0 :weight bold :foreground "#6c7378"))))


   `(org-level-1 ((,class (:height 1.3 :weight bold :foreground "#008abd"))))
   `(org-level-2 ((,class (:height 1.2 :weight bold :foreground "#7d57c2"))))
   `(org-level-3 ((,class (:height 1.1 :weight bold :foreground "#cc6d00"))))
   `(org-level-4 ((,class (:height 1.0 :weight bold :foreground "#2e994c"))))
   `(org-level-5 ((,class (:height 1.0 :weight bold :foreground "#00638a"))))
   `(org-level-6 ((,class (:height 1.0 :weight bold :foreground "#D0372D"))))
   `(org-level-7 ((,class (:height 1.0 :weight bold :foreground "#008080"))))
   `(org-level-8 ((,class (:height 1.0 :weight bold :foreground "#6c7378"))))

   `(org-block ((,class (:background "#f2f2f2"))))
   `(org-block-background ((,class (:background "#f2f2f2"))))
   `(org-block-begin-line ((,class (:underline nil :foreground "#454545" :background "#cfd8dc"))))
   `(org-block-end-line ((,class (:overline nil :foreground "#454545" :background "#cfd8dc"))))
   `(org-checkbox ((,class (:weight bold :foreground "#7d57c2" :background "#f2f2f2"))))
   `(org-code ((,class (:foreground "#006400" :background "#fdfff7"))))

   `(org-todo ((,class (:weight bold :box (:line-width 1 :color "#993d3d") :foreground "#993d3d" :background "#ffdddd"))))
   `(org-done ((,class (:weight bold :box (:line-width 1 :color "#2e994c") :foreground "#2e994c" :background "#ddffdd"))))
   `(org-headline-done ((,class (:height 1.0 :weight normal :strike-through t :foreground "#454545"))))
   `(org-date ((,class (:underline t :foreground "#7d57c2"))))
   `(org-document-title ((,class (:height 1.8 :weight bold :foreground "#454545"))))


   `(highlight-numbers-number ((,class (:foreground "#d75f00"))))


   `(js2-error ((,class (:box (:line-width 1 :color "#d0372d") :background "#ffdddd"))))
   `(js2-warning ((,class (:underline "#cc6d00"))))
   `(js2-external-variable ((,class (:foreground "#d0372d"))))
   `(js2-function-param ((,class (:foreground "#008abd"))))
   `(js2-instance-member ((,class (:foreground "#2f7e9d"))))
   `(js2-jsdoc-html-tag-delimiter ((,class (:foreground "#d0372d"))))
   `(js2-jsdoc-html-tag-name ((,class (:foreground "#d0372d"))))
   `(js2-jsdoc-tag ((,class (:weight normal :foreground "#7d57c2"))))
   `(js2-jsdoc-type ((,class (:foreground "#008abd"))))
   `(js2-jsdoc-value ((,class (:weight normal :foreground "#7d57c2"))))
   `(js2-magic-paren ((,class (:underline t))))
   `(js2-private-function-call ((,class (:foreground "#f38e00"))))
   `(js2-private-member ((,class (:foreground "#008abd"))))
   `(js2-object-property ((,class (:foreground "#009688"))))


   `(ivy-current-match ((,class (:background "#cccccc"))))
   `(ivy-minibuffer-match-face-1 ((,class (:background "#f2f2f2"))))
   `(ivy-minibuffer-match-face-2 ((,class (:weight bold :background "#fffbc4"))))
   `(ivy-minibuffer-match-face-3 ((,class (:weight bold :background "#fffbc4"))))
   `(ivy-minibuffer-match-face-4 ((,class (:weight bold :background "#fffbc4"))))


   `(swiper-line-face ((,class (:background "#f2f2f2"))))
   `(swiper-match-face-1 ((,class (:background "#fffbc4"))))
   `(swiper-match-face-2 ((,class (:background "#fffbc4"))))
   `(swiper-match-face-3 ((,class (:background "#fffbc4"))))
   `(swiper-match-face-4 ((,class (:background "#fffbc4"))))


   `(magit-header-line ((,class (:foreground "#f2f2f2"))))
   `(magit-hash ((,class (:foreground "#008080"))))
   `(magit-blame-hash ((,class (:foreground "#008080"))))
   `(magit-blame-name ((,class (:foreground "#008abd" :weight bold))))
   `(magit-blame-date ((,class (:foreground "#cc6d00"))))
   `(magit-blame-summary ((,class (:foreground "#678f03" :slant italic))))
   `(magit-blame-heading ((,class (:background "#e6e6e6"))))
   `(magit-log-graph ((,class (:foreground "#7d57c2"))))
   `(magit-log-author ((,class (:foreground "#008abd" :weight bold))))
   `(magit-log-date ((,class (:foreground "#cc6d00"))))


   `(cypher-clause-face ((,class (:weight normal :foreground "#00638a"))))
   `(cypher-function-face ((,class (:foreground "#454545"))))
   `(cypher-keyword-face ((,class (:weight bold :foreground "#00638a"))))
   `(cypher-node-type-face ((,class (:weight normal :foreground "#008abd"))))
   `(cypher-pattern-face ((,class (:foreground "#d70087" :background "#f2f2f2"))))
   `(cypher-relation-type-face ((,class (:weight normal :foreground "#008080"))))
   `(cypher-symbol-face ((,class (:slant italic :foreground "#454545"))))
   `(cypher-variable-face ((,class (:foreground "#454545"))))))


;;
;; Cloud mode line

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Utils

(defvar cloudline-selected-window (frame-selected-window) "Selected window.")

(defun cloudline-selected-window-active-p ()
  "Return t if selected window is active."
  (eq cloudline-selected-window (selected-window)))

(defun cloudline-set-selected-window ()
  "Set the variable for current selected window."
  (when (not (minibuffer-window-active-p (frame-selected-window)))
    (setq cloudline-selected-window (frame-selected-window))
    (force-mode-line-update)))

(defun cloudline-unset-selected-window ()
  "Unset the variable for current selected window."
  (setq cloudline-selected-window nil)
  (force-mode-line-update))

(add-hook 'window-configuration-change-hook 'cloudline-set-selected-window)
(add-hook 'buffer-list-update-hook 'cloudline-set-selected-window)
(with-no-warnings
  (add-hook 'focus-in-hook 'cloudline-set-selected-window)
  (add-hook 'focus-out-hook 'cloudline-unset-selected-window))

;; Handle mode line alignment

(defun cloudline--format (left right)
  "Return a string of `window-width' length with aligned `LEFT' and `RIGHT' segments."
  (let ((right-length (length right)))
    (when (and (display-graphic-p) (eq 'right (get-scroll-bar-mode)))
      (setq right-length (- right-length 3)))
    (concat left
            " "
            (propertize " "
                        'display
                        `((space :align-to (- (+ right right-fringe right-margin) ,(+ right-length 0)))))
            right)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Faces

(defface cloudline-evil-normal-active
  '((t :foreground "#388e3c"
       :weight bold
       :height 1.0))
  "Face for evil normal state active.")

(defface cloudline-evil-normal-inactive
  '((t :foreground "#a7cf42"
       :weight bold
       :height 1.0))
  "Face for evil normal state inactive.")

(defface cloudline-evil-insert-active
  '((t :foreground "#d0372d"
       :weight bold
       :height 1.0))
  "Face for evil insert state active.")

(defface cloudline-evil-insert-inactive
  '((t :foreground "#ff9999"
       :weight bold
       :height 1.0))
  "Face for evil insert state inactive.")

(defface cloudline-evil-visual-active
  '((t :foreground "#008abc"
       :weight bold
       :height 1.0))
  "Face for evil visual state active.")

(defface cloudline-evil-visual-inactive
  '((t :foreground "#8dd0eb"
       :weight bold
       :height 1.0))
  "Face for evil visual state inactive.")

(defface cloudline-evil-replace-active
  '((t :foreground "#c06600"
       :weight bold
       :height 1.0))
  "Face for evil replace state active.")

(defface cloudline-evil-replace-inactive
  '((t :foreground "#f0d97a"
       :weight bold
       :height 1.0))
  "Face for evil replace state inactive.")

(defface cloudline-evil-emacs-active
  '((t :foreground "#6c4ca8"
       :weight bold
       :height 1.0))
  "Face for evil emacs state active.")

(defface cloudline-evil-emacs-inactive
  '((t :foreground "#b48cff"
       :weight bold
       :height 1.0))
  "Face for evil emacs state inactive.")

(defface cloudline-file-name-active
  '((t :foreground "#00638a"
       :weight bold))
  "Face for buffer file name active.")

(defface cloudline-file-name-inactive
  '((t :foreground "#8dd0eb"
       :weight bold))
  "Face for buffer file name inactive.")

(defface cloudline-major-mode-active
  '((t :foreground "#6c4ca8"
       :weight bold
       :height 1.0))
  "Face for major mode name active.")

(defface cloudline-major-mode-inactive
  '((t :foreground "#b48cff"
       :weight bold
       :height 1.0))
  "Face for major mode name inactive.")

(defface cloudline-vc-active
  '((t :foreground "#5e8203"
       :weight normal
       :slant italic))
  "Face for VC state active.")

(defface cloudline-vc-inactive
  '((t :foreground "#a7cf42"
       :weight normal
       :slant italic))
  "Face for VC state inactive.")

(defface cloudline-file-size-active
  '((t :foreground "#cc6d00"
       :weight normal))
  "Face for file size active buffer.")

(defface cloudline-file-size-inactive
  '((t :foreground "#f0d97a"
       :weight normal))
  "Face for file size inactive buffer.")

(defface cloudline-readonly
  '((t :weight normal))
  "Face for rean only buffer indication."
  :group 'cloudline)

(defface cloudline-modified
  '((t :weight normal))
  "Face for modified buffer indication."
  :group 'cloudline)

(defface cloudline-position-active
  '((t :foreground "#cc6d00"
       :weight normal))
  "Face for position in active buffer.")

(defface cloudline-position-inactive
  '((t :foreground "#f0d97a"
       :weight normal))
  "Face for position in inactive buffer.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Segments

(defmacro defcloudline (name body)
  "Create a function with `NAME' and `BODY'."
  `(defun ,name (&optional face)
     (let ((str (format-mode-line ,body)))
       (if face
           (propertize str 'face face)
         str))))

(defvar evil-state)
(declare-function evil-normal-state-p "evil")
(declare-function evil-insert-state-p "evil")
(declare-function evil-motion-state-p "evil")
(declare-function evil-visual-state-p "evil")
(declare-function evil-operator-state-p "evil")
(declare-function evil-replace-state-p "evil")
(declare-function evil-emacs-state-p "evil")
(declare-function evil-state-property "evil")

(defcloudline cloudline--evil
  (when (bound-and-true-p evil-local-mode)
    (let ((active (cloudline-selected-window-active-p))
          (tag (evil-state-property evil-state :tag t)))
      (propertize tag
                  'face
                  (if active
                      (cond ((evil-normal-state-p) 'cloudline-evil-normal-active)
                            ((evil-insert-state-p) 'cloudline-evil-insert-active)
                            ((evil-motion-state-p) 'cloudline-evil-normal-active)
                            ((evil-visual-state-p) 'cloudline-evil-visual-active)
                            ((evil-operator-state-p) 'cloudline-evil-normal-active)
                            ((evil-replace-state-p) 'cloudline-evil-replace-active)
                            ((evil-emacs-state-p) 'cloudline-evil-emacs-active))
                    'cloudline-evil-emacs-inactive)))))

;; File name segment

(defcloudline cloudline--file-name
  (propertize "%b"
              'help-echo (buffer-file-name)
              'face
              (if (cloudline-selected-window-active-p)
                  'cloudline-file-name-active
                'cloudline-file-name-inactive)))

;; Major mode segment

(defcloudline cloudline--major-mode
  (propertize "%m"
              'help-echo "Major mode name"
              'face
              (if (cloudline-selected-window-active-p)
                  'cloudline-major-mode-active
                'cloudline-major-mode-inactive)))

;; Version Control segment

(defcloudline cloudline--vc
  (when (and vc-mode buffer-file-name)
    (list
     (propertize (format-mode-line '(vc-mode vc-mode))
                 'face
                 (if (cloudline-selected-window-active-p)
                     'cloudline-vc-active
                   'cloudline-vc-inactive)))))

;; File size segment

(defcloudline cloudline--file-size
  (propertize "%I"
              'help-echo "file size"
              'face
              (if (cloudline-selected-window-active-p)
                  'cloudline-file-size-active
                'cloudline-file-size-inactive)))

;; Readonly segment

(defcloudline cloudline--readonly
  (let ((tag (if (and
                  buffer-read-only
                  (not (string-match-p "\\*.*\\*" (buffer-name))))
                 (char-to-string ?r)
               "")))
    (propertize tag
                'help-echo "read only"
                'face
                'cloudline-readonly)))

;; Modified segment

(defcloudline cloudline--modified
  (let ((tag (if (and (buffer-modified-p (current-buffer))
                      (not (string-match-p "\\*.*\\*" (buffer-name))))
                 (char-to-string ?*)
               "")))
    (propertize tag 'face 'cloudline-modified)))

;; Position segment

(defcloudline cloudline--position
  (let ((f (if (cloudline-selected-window-active-p)
               'cloudline-position-active
             'cloudline-position-inactive)))
    (list
     (propertize "%l" 'face f)
     ":"
     (propertize "%c" 'face f))))

;; End of line segment

(defcloudline cloudline--eol
  (pcase (coding-system-eol-type buffer-file-coding-system)
    (0 "LF")
    (1 "CRLF")
    (2 "CR")))

;; Encoding segment

(defcloudline cloudline--encoding
  (let ((sys (coding-system-plist buffer-file-coding-system)))
    (cond ((memq (plist-get sys :category) '(coding-category-undecided coding-category-utf-8))
           "utf-8")
          (t (symbol-name (plist-get sys :name))))))

;; Flycheck segment

(declare-function flycheck-count-errors "flycheck" (errors))
(defvar flycheck-current-errors)
(defvar-local cloudline--flycheck-state nil)

(defun cloudline--flycheck-segment (&optional status)
  "Display flycheck `STATUS'."
  (setq cloudline--flycheck-state
        (pcase status
          ('finished (if flycheck-current-errors
                         (let-alist (flycheck-count-errors flycheck-current-errors)
                           (let* ((errors (or .error 0))
                                  (warnings (or .warning 0)))
                             (concat
                              (propertize "●" 'help-echo "warnings" 'face 'warning)
                              " "
                              (number-to-string warnings)
                              " "
                              (propertize "●" 'help-echo "errors" 'face 'error)
                              " "
                              (number-to-string errors)
                              )))
                       (propertize "✔" 'help-echo "good" 'face 'success)))
          ('running "⟲ checking")
          ('no-checker "? no checker")
          ('errored "! error")
          ('interrupted "! paused"))))

(defcloudline cloudline--flycheck
  cloudline--flycheck-state)

(defvar cloudline-default-mode-line-format mode-line-format
  "Default format for mode line.")

(defun cloudline-default ()
  "Rollback to default mode line."
  (interactive)
  (setq-default mode-line-format cloudline-default-mode-line-format))

;;;###autoload
(defun cloud-theme-mode-line ()
  "Customize mode line to cloud style."
  (interactive)

  ;; Setup flycheck hooks
  (add-hook 'flycheck-status-changed-functions #'cloudline--flycheck-segment)
  (add-hook 'flycheck-mode-hook #'cloudline--flycheck-segment)

  (let ((class '((class color) (min-colors 89))))
    (custom-set-faces
     `(mode-line
       ((,class (:background "#f2f2f2"
                             :height 120
                             :foreground "#6c7b8b"
                             :box (:line-width 1 :color "#f2f2f2")))))
     `(mode-line-inactive
       ((,class (:background "#f2f2f2"
                             :height 120
                             :foreground "#a8b3ba"
                             :box (:line-width 1 :color "#f2f2f2")))))))
  (setq-default mode-line-format
                '((:eval
                   (cloudline--format
                    ;; left
                    (format-mode-line
                     '((:eval (cloudline--evil))
                       " "
                       (:eval (cloudline--file-name))
                       (:eval (cloudline--readonly))
                       (:eval (cloudline--modified))
                       " "
                       (:eval (cloudline--vc))
                       " "
                       (:eval (cloudline--flycheck))
                       " "
                       ))
                    (format-mode-line
                     '(" "
                       (:eval (cloudline--position))
                       " "
                       (:eval (cloudline--encoding))
                       " "
                       (:eval (cloudline--eol))
                       " "
                       (:eval (cloudline--major-mode))
                       "  ")))))))

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'cloud)
(provide 'cloud-theme)

;;; cloud-theme.el ends here
