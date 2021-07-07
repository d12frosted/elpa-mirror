;;; graphene-meta-theme.el --- Integrated theming for common packages
;;
;; Copyright (c) 2015 Robert Dallas Gray
;;
;; Author: Robert Dallas Gray <mail@robertdallasgray.com>
;; URL: https://github.com/rdallasgray/graphene
;; Package-Version: 20161204.1607
;; Package-Commit: 62cc73fee31f1bd9474027b83a249feee050271e
;; Version: 0.0.5
;; Keywords: defaults

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This theme works with any other active theme to provide a pleasing default look.
;; It does not provide new interface colours but rather re-uses the theming
;; of Emacs built-ins to integrate the overall look of several common or
;; built-in packages. It should be loaded *after* any theme you normally
;; use to set the interface colours of your Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;; Set relative font heights
(defvar graphene-font-height
  (face-attribute 'default :height)
  "Default font height.")
(defvar graphene-small-font-height
  (floor (* .917 graphene-font-height))
  "Relative size for 'small' fonts.")

(deftheme graphene-meta "The Graphene meta-theme -- some simple additions to any theme to improve the look of speedbar, linum, etc.")

(custom-theme-set-faces
 'graphene-meta

 `(bm-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit compilation-warning
                    :inverse-video t))))
 `(bm-fringe-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit bm-face
                    :inverse-video nil))))
 `(bm-persistent-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-function-name-face
                    :inverse-video t))))
 `(bm-fringe-persistent-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit bm-persistent-face
                    :inverse-video nil))))

 `(speedbar-directory-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit variable-pitch
                    :weight bold
                    :height ,graphene-small-font-height))))
 `(speedbar-file-face
   ((t (:foreground unspecified
                    :inherit speedbar-directory-face
                    :weight normal))))
 `(speedbar-selected-face
   ((t (:background unspecified
                    :foreground unspecified
                    :height unspecified
                    :inherit (speedbar-file-face font-lock-function-name-face)))))
 `(speedbar-highlight-face
   ((t (:background unspecified
                    :inherit region))))
 `(speedbar-button-face
   ((t (:foreground unspecified
                    :background unspecified
                    :box nil
                    :inherit file-name-shadow))))
 `(speedbar-tag-face
   ((t (:background unspecified
                    :foreground unspecified
                    :height unspecified
                    :inherit speedbar-file-face))))
 `(speedbar-separator-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inverse-video nil
                    :inherit speedbar-directory-face
                    :overline nil
                    :weight bold))))

 `(linum
   ((t (:height ,graphene-small-font-height
                :foreground unspecified
                :inherit 'shadow
                :slant normal))))

 `(visible-mark-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inverse-video unspecified
                    :inherit 'hl-line))))

 `(hl-sexp-face
   ((t (:bold nil
              :background unspecified
              :inherit 'hl-line))))

 `(fringe
   ((t (:background unspecified))))

 `(vertical-border
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit file-name-shadow))))

 `(font-lock-comment-face
   ((t (:slant normal))))
 `(font-lock-comment-delimiter-face
   ((t (:slant normal))))

 `(font-lock-doc-face
   ((t (:slant normal))))

 `(popup-face
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit linum
                    :height ,graphene-font-height))))
 `(popup-scroll-bar-foreground-face
   ((t (:background unspecified
                    :inherit region))))
 `(popup-scroll-bar-background-face
   ((t (:background unspecified
                    :inherit popup-face))))

 `(ac-completion-face
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit popup-face))))
 `(ac-candidate-face
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit linum
                    :height ,graphene-font-height))))
 `(ac-selection-face
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit font-lock-variable-name-face
                    :inverse-video t))))
 `(ac-candidate-mouse-face
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit region))))
 `(ac-dabbrev-menu-face
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit popup-face))))
 `(ac-dabbrev-selection-face
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit ac-selection-face))))

 `(company-preview
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit file-name-shadow))))
 `(company-preview-common
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit company-preview))))
 `(company-preview-search
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit company-preview
                    :weight bold))))
 `(company-tooltip
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit linum
                    :height ,graphene-font-height))))
 `(company-tooltip-common
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit linum
                    :weight bold
                    :height ,graphene-font-height))))
 `(company-tooltip-selection
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit font-lock-variable-name-face
                    :inverse-video t))))
 `(company-tooltip-common-selection
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit font-lock-variable-name-face
                    :weight bold
                    :inverse-video t))))
 `(company-tooltip-mouse
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit region))))
 `(company-tooltip-annotation
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit font-lock-function-name-face))))
 `(company-echo-common
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit company-echo
                    :weight bold))))
 `(company-scrollbar-fg
   ((t (:background unspecified
                    :inherit popup-scroll-bar-foreground-face))))
 `(company-scrollbar-bg
   ((t (:background unspecified
                    :inherit popup-scroll-bar-background-face))))

 `(flymake-warnline
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit font-lock-preprocessor-face))))

 `(web-mode-symbol-face
   ((t (:foreground unspecified
                    :inherit font-lock-constant-face))))
 `(web-mode-builtin-face
   ((t (:foreground unspecified
                    :inherit default))))
 `(web-mode-doctype-face
   ((t (:foreground unspecified
                    :inherit font-lock-comment-face))))
 `(web-mode-html-tag-face
   ((t (:foreground unspecified
                    :inherit font-lock-function-name-face))))
 `(web-mode-html-attr-name-face
   ((t (:foreground unspecified
                    :inherit font-lock-variable-name-face))))
 `(web-mode-html-param-name-face
   ((t (:foreground unspecified
                    :inherit font-lock-constant-face))))
 `(web-mode-whitespace-face
   ((t (:foreground unspecified
                    :inherit whitespace-space))))
 `(web-mode-block-face
   ((t (:foreground unspecified
                    :inherit highlight))))

 `(sp-show-pair-match-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit show-paren-match))))
 `(sp-show-pair-mismatch-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit show-paren-mismatch))))

 `(vr/match-0
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit font-lock-regexp-grouping-construct
                    :inverse-video t))))
 `(vr/match-1
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit font-lock-regexp-grouping-backslash
                    :inverse-video t))))
 `(vr/group-0
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit font-lock-keyword-face
                    :inverse-video t))))
 `(vr/group-1
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit font-lock-function-name-face
                    :inverse-video t))))
 `(vr/group-2
   ((t (:background unspecified
                    :foreground unspecified
                    :inherit font-lock-constant-face
                    :inverse-video t))))

 `(whitespace-space
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit highlight))))
 `(ivy-action
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-builtin-face))))
 `(ivy-confirm-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit ivy-action
                    :weight bold))))
 `(ivy-current-match
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit highlight))))
 `(ivy-cursor
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit cursor))))
 `(ivy-match-required-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-warning-face))))
 `(ivy-minibuffer-match-face-1
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit secondary-selection))))
 `(ivy-minibuffer-match-face-2
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-constant-face
                    :inverse-video t))))
 `(ivy-minibuffer-match-face-3
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-function-name-face
                    :inverse-video t))))
 `(ivy-minibuffer-match-face-4
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-keyword-face
                    :inverse-video t))))
 `(ivy-remote
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-keyword-face))))
 `(ivy-subdir
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-function-name-face))))
 `(ivy-virtual
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit ivy-action))))
 `(swiper-line-face
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit highlight))))
 `(swiper-match-face-1
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-regexp-grouping-backslash
                    :inverse-video t))))
 `(swiper-match-face-2
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-regexp-grouping-construct
                    :inverse-video t))))
 `(swiper-match-face-3
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-keyword-face
                    :inverse-video t))))
 `(swiper-match-face-4
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-negation-char-face
                    :inverse-video t))))
 `(hydra-face-amaranth
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit link-visited))))
 `(hydra-face-blue
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-function-name-face))))
 `(hydra-face-pink
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-regexp-grouping-construct))))
 `(hydra-face-red
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-warning-face))))
 `(hydra-face-teal
   ((t (:foreground unspecified
                    :background unspecified
                    :inherit font-lock-constant-face)))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'graphene-meta)

;;; graphene-meta-theme.el ends here
