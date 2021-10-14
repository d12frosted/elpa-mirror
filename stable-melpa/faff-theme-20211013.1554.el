;;; faff-theme.el --- Light Emacs color theme on cornsilk3 background

;; Copyright (C) 2003-2014 Free Software Foundation, Inc.

;; Author: James Ferguson <(concat "wjcferguson" at-sign "gmail.com")>
;; URL: https://github.com/WJCFerguson/emacs-faff-theme
;; Package-Version: 20211013.1554
;; Package-Commit: 3c13ae4d694025207ba7eb43f174f90bb49395d4
;; Version: 2.6
;; Keywords: color theme

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; The default Emacs theme with an cornsilk3 background, with tweaks applied.  Used
;; mostly for coding and magit, with some customizations for org, powerline,
;; hl-line
;;
;; This file created using customize-create-theme, rather than hand-rolled.
;; Comments and change suggestions welcome
;;
;; To use it, put the following in your Emacs configuration file:
;;
;;   (load-theme 'faff t)
;;
;; Requirements: Emacs 24.

;;; Code:

(deftheme faff
  "Emacs default with cornsilk3 background and a few tweaks")

(custom-theme-set-faces
 'faff
 '(default ((t (:foreground "black" :background "cornsilk3"))))
 '(breakpoint-disabled ((t (:foreground "grey40"))))
 '(match ((t (:background "yellow2"))))
 '(cursor ((t (:background "red3"))))
 '(fixed-pitch ((t (:inherit default :background "cornsilk2"))))
 '(variable-pitch ((t (:family "Sans Serif"))))
 '(escape-glyph ((((background dark)) (:foreground "cyan")) (((type pc)) (:foreground "magenta")) (t (:foreground "brown"))))
 '(minibuffer-prompt ((((background dark)) (:foreground "cyan")) (((type pc)) (:foreground "magenta")) (t (:foreground "medium blue"))))
 '(highlight ((t (:background "white"))))
 '(highlight-symbol-face ((t (:background "cornsilk2"))))
 '(shadow ((t (:foreground "cornsilk4"))))
 '(secondary-selection ((((class color) (min-colors 88) (background light)) (:background "yellow1")) (((class color) (min-colors 88) (background dark)) (:background "SkyBlue4")) (((class color) (min-colors 16) (background light)) (:background "yellow")) (((class color) (min-colors 16) (background dark)) (:background "SkyBlue4")) (((class color) (min-colors 8)) (:foreground "black" :background "cyan")) (t (:inverse-video t))))
 '(trailing-whitespace ((t (:background "cornsilk2"))))
 '(emms-playlist-selected-face ((t (:background "cornsilk2" :foreground "black"))))
 '(emms-playlist-track-face ((t (:foreground "red4"))))
 '(erc-notice-face ((t (:foreground "cornsilk4"))))
 '(erc-timestamp-face ((t (:foreground "white" :weight bold))))
 '(font-lock-builtin-face ((((class grayscale) (background light)) (:weight bold :foreground "LightGray")) (((class grayscale) (background dark)) (:weight bold :foreground "DimGray")) (((class color) (min-colors 88) (background light)) (:foreground "dark slate blue")) (((class color) (min-colors 88) (background dark)) (:foreground "LightSteelBlue")) (((class color) (min-colors 16) (background light)) (:foreground "Orchid")) (((class color) (min-colors 16) (background dark)) (:foreground "LightSteelBlue")) (((class color) (min-colors 8)) (:weight bold :foreground "blue")) (t (:weight bold))))
 '(font-lock-comment-delimiter-face ((default (:inherit (font-lock-comment-face)))))
 '(font-lock-comment-face ((t (:foreground "red3"))))
 '(font-lock-constant-face ((t (:foreground "blue3"))))
 '(font-lock-doc-face ((t (:foreground "red4"))))
 '(font-lock-function-name-face ((t (:foreground "navy"))))
 '(font-lock-keyword-face ((t (:foreground "black" :weight bold))))
 '(font-lock-negation-char-face ((t (:background "cornsilk2"))))
 '(font-lock-preprocessor-face ((t (:inherit (font-lock-builtin-face)))))
 '(font-lock-regexp-grouping-backslash ((t (:inherit (bold)))))
 '(font-lock-regexp-grouping-construct ((t (:inherit (bold)))))
 '(font-lock-string-face ((t (:foreground "darkgreen"))))
 '(font-lock-type-face ((t (:foreground "navy" :weight bold))))
 '(font-lock-variable-name-face ((t (:foreground "dark magenta"))))
 '(font-lock-warning-face ((t (:inherit (error)))))
 '(button ((t (:inherit (link)))))
 '(link ((((class color) (min-colors 88) (background light)) (:underline (:color foreground-color :style line) :foreground "RoyalBlue3")) (((class color) (background light)) (:underline (:color foreground-color :style line) :foreground "blue")) (((class color) (min-colors 88) (background dark)) (:underline (:color foreground-color :style line) :foreground "cyan1")) (((class color) (background dark)) (:underline (:color foreground-color :style line) :foreground "cyan")) (t (:inherit (underline)))))
 '(link-visited ((default (:inherit (link))) (((class color) (background light)) (:foreground "magenta4")) (((class color) (background dark)) (:foreground "violet"))))
 '(ein:cell-input-area ((t (:background "cornsilk2"))) t)
 '(fill-column-indicator ((t (:inherit shadow :foreground "cornsilk2"))))
 '(fringe ((t (:inherit default :background "cornsilk3"))))
 '(header-line ((t (:inherit mode-line :background "cornsilk4" :weight bold))))
 '(js2-external-variable ((t (:foreground "orange3"))))
 '(js2-function-call ((t (:inherit font-lock-function-name-face))))
 '(js2-jsdoc-type ((t (:inherit font-lock-type-face))))
 '(js2-jsdoc-value ((t (:inherit font-lock-variable-name-face)))) '(dired-subtree-depth-1-face ((t (:background "cornsilk2"))))
 '(js2-object-property ((t (:inherit font-lock-variable-name-face))))
 '(tooltip ((((class color)) (:inherit (variable-pitch) :foreground "black" :background "lightyellow")) (t (:inherit (variable-pitch)))))
 '(mode-line ((t (:background "gold" :foreground "black" :box nil))))
 '(mode-line-buffer-id ((t (:weight bold))))
 '(mode-line-emphasis ((t (:weight bold))))
 '(mode-line-highlight ((((class color) (min-colors 88)) (:box (:line-width 2 :color "cornsilk4" :style released-button))) (t (:inherit (highlight)))))
 '(mode-line-inactive ((t (:inherit mode-line :background "cornsilk4" :foreground "black" :box nil :weight light))))
 '(isearch ((((class color) (min-colors 88) (background light)) (:foreground "lightskyblue1" :background "magenta3")) (((class color) (min-colors 88) (background dark)) (:foreground "brown4" :background "palevioletred2")) (((class color) (min-colors 16)) (:foreground "cyan1" :background "magenta4")) (((class color) (min-colors 8)) (:foreground "cyan1" :background "magenta4")) (t (:inverse-video t))))
 '(isearch-fail ((((class color) (min-colors 88) (background light)) (:background "RosyBrown1")) (((class color) (min-colors 88) (background dark)) (:background "red4")) (((class color) (min-colors 16)) (:background "red")) (((class color) (min-colors 8)) (:background "red")) (((class color grayscale)) (:foreground "grey")) (t (:inverse-video t))))
 '(lazy-highlight ((((class color) (min-colors 88) (background light)) (:background "paleturquoise")) (((class color) (min-colors 88) (background dark)) (:background "paleturquoise4")) (((class color) (min-colors 16)) (:background "turquoise3")) (((class color) (min-colors 8)) (:background "turquoise3")) (t (:underline (:color foreground-color :style line)))))
 '(match ((((class color) (min-colors 88) (background light)) (:background "yellow1")) (((class color) (min-colors 88) (background dark)) (:background "RoyalBlue3")) (((class color) (min-colors 8) (background light)) (:foreground "black" :background "yellow")) (((class color) (min-colors 8) (background dark)) (:foreground "white" :background "blue")) (((type tty) (class mono)) (:inverse-video t)) (t (:background "gray"))))
 '(next-error ((t (:inherit (region)))))
 '(query-replace ((t (:inherit (isearch)))))
 '(aw-leading-char-face ((t (:foreground "red" :height 4.0))))
 '(aw-mode-line-face ((t (:background "green1" :inverse-video t))))
 '(calendar-today ((t (:background "yellow1" :underline t))))
 '(custom-button ((((type x w32 mac) (class color)) (:background "grey85" :foreground "black" :box (:line-width 1 :style released-button)))))
 '(diff-added ((t (:inherit diff-changed :foreground "green3"))))
 '(diff-file-header ((t (:background "grey80" :box (:line-width 2 :color "grey80") :weight bold))))
 '(diff-header ((t (:background "grey80" :box (:line-width 2 :color "grey80")))))
 '(diff-hunk-header ((t (:inherit diff-header :box (:line-width 2 :color "grey80")))))
 '(diff-removed ((t (:foreground "red"))))
 '(dired-async-mode-message ((t (:foreground "red4"))))
 '(dired-directory ((t (:inherit font-lock-keyword-face))))
 '(dired-filetype-compress ((t (:foreground "Orchid"))))
 '(dired-filetype-execute ((t (:foreground "green4" :weight bold))))
 '(dired-filetype-omit ((t (:foreground "cornsilk4"))))
 '(dired-filetype-plain ((t (:foreground "SeaGreen"))))
 '(dired-filetype-source ((t (:foreground "red4" :weight bold))))
 '(dired-filetype-video ((t (:foreground "brown"))))
 '(flymake-note ((t (:underline (:color "green yellow" :style wave)))))
 '(flymake-warning ((t (:background "gray"))))
 '(dired-filetype-js ((t (:foreground "goldenrod4"))))
 '(dired-subtree-depth-2-face ((t (:background "cornsilk1"))))
 '(dired-subtree-depth-3-face ((t (:background "white"))))
 '(dired-subtree-depth-4-face ((t (:background "cornsilk2"))))
 '(dired-subtree-depth-5-face ((t (:background "cornsilk1"))))
 '(dired-subtree-depth-6-face ((t (:background "white")))) '(flymake-warnline ((t (:background "LightBlue3"))))
 '(hi-green-b ((t (:foreground "green4" :weight bold))))
 '(hl-line ((t (:extend t :background "#ddd8bd"))))
 '(jabber-activity-face ((t (:background "green1"))))
 '(jabber-chat-error ((t (:background "pink"))))
 '(jabber-chat-prompt-system ((t (:foreground "green3" :weight bold))))
 '(jabber-chat-text-local ((t (:foreground "red4"))))
 '(jabber-title-large ((t (:weight bold :height 2.0 :width expanded))))
 '(jabber-title-medium ((t (:background "#ffb" :box (:line-width 2 :color "grey75" :style released-button) :weight bold :height 1.2 :width expanded))))
 '(lsp-face-highlight-read ((t (:background "cornsilk2"))))
 '(lsp-face-highlight-textual ((t (:background "cornsilk4"))))
 '(lsp-face-highlight-write ((t (:background "palegreen1"))))
 '(lsp-ui-sideline-current-symbol ((t (:inherit lsp-ui-sideline-symbol :box (:line-width 1 :color "cornsilk4") :weight bold))))
 '(lsp-ui-sideline-symbol ((t (:foreground "cornsilk2"))))
 '(lsp-ui-sideline-symbol-info ((t (:foreground "gray60" :slant italic))))
 '(helm-M-x-key ((t (:foreground "orange4" :underline t))))
 '(helm-ff-executable ((t (:foreground "darkgreen" :weight bold))))
 '(helm-ff-symlink ((t (:foreground "orange4"))))
 '(helm-grep-lineno ((t (:foreground "orange4"))))
 '(helm-source-header ((t (:background "cornsilk2" :foreground "black" :box (:line-width 1 :color "grey75" :style pressed-button) :weight normal :height 1.0 :family "Sans Serif"))))
 '(hydra-face-pink ((t (:foreground "deeppink" :weight bold))))
 '(Info-quoted ((t (:inherit fixed-pitch))))
 '(magit-branch ((t (:inherit magit-header :background "yellow" :box (:line-width 1 :color "grey75" :style released-button)))))
 '(magit-branch-current ((t (:inherit magit-branch-local :background "green1" :weight bold))))
 '(magit-branch-local ((t (:background "yellow" :box (:line-width 1 :color "black")))))
 '(magit-branch-remote ((t (:background "cornsilk2" :foreground "DarkOliveGreen4" :box (:line-width 1 :color "cornsilk4")))))
 '(magit-diff-add ((t (:inherit diff-added))))
 '(magit-diff-del ((t (:inherit diff-removed))))
 '(magit-diff-none ((t (:inherit diff-context))))
 '(magit-header ((t (:inherit header-line :background "white"))))
 '(magit-item-highlight ((t (:inherit highlight))))
 '(magit-reflog-commit ((t (:foreground "green4"))))
 '(magit-reflog-rebase ((t (:foreground "magenta3"))))
 '(magit-reflog-reset ((t (:foreground "red3"))))
 '(magit-refname ((t (:foreground "grey30" :box (:line-width 2 :color "grey75")))))
 '(magit-section-heading ((t (:background "cornsilk2" :box (:line-width 1 :color "grey75" :style released-button) :weight bold))))
 '(magit-section-title ((t (:inherit magit-header :box (:line-width 1 :color "grey75" :style released-button)))))
 '(magit-section-highlight ((t (:extend t :background "#ddd8bd"))))
 '(magit-signature-good ((t (:foreground "darkgreen"))))
 '(magit-tag ((t (:background "cornsilk2" :foreground "Goldenrod4" :box (:line-width 1 :color "gray25")))))
 '(menu ((((type x-toolkit)) (:background "gray92"))))
 '(org-agenda-date ((t (:inherit org-agenda-structure :background "cornsilk1" :box (:line-width 1 :color "grey75" :style pressed-button) :height 1.0))))
 '(org-agenda-date-today ((t (:inherit org-agenda-date :slant italic :weight bold :height 1.0))))
 '(org-agenda-dimmed-todo-face ((t (:background "yellow3" :foreground "black"))))
 '(org-agenda-done ((((class color) (min-colors 16) (background light)) (:foreground "#9b9"))))
 '(org-agenda-restriction-lock ((t (:background "cornsilk1"))))
 '(org-agenda-structure ((t (:background "cornsilk1" :foreground "Blue3" :box (:line-width 1 :color "grey75" :style pressed-button)))))
 '(org-block ((t (:inherit shadow :extend t :background "cornsilk2"))))
 '(org-column ((t (:background "cornsilk1" :strike-through nil :underline nil :slant normal :weight normal))))
 '(org-date ((t (:color "grey75" :style released-button))))
 '(org-hide ((((background light)) (:foreground "cornsilk2"))))
 '(org-meta-line ((t (:inherit fixed-pitch :background "cornsilk3" :foreground "cornsilk2"))))
 '(org-table ((t (:inherit org-block :foreground "Blue1"))))
 '(org-verbatim ((t (:inherit shadow :extend t :background "cornsilk2"))))
 '(outline-1 ((t (:weight bold))))
 '(outline-2 ((t (:foreground "dark red" :weight bold))))
 '(outline-3 ((t (:foreground "purple4" :weight normal))))
 '(outline-4 ((t (:inherit font-lock-variable-name-face))))
 '(powerline-active1 ((t (:inherit mode-line :background "gold4"))))
 '(powerline-active2 ((t (:inherit mode-line :background "gold3"))))
 '(powerline-inactive1 ((t (:inherit mode-line-inactive :background "grey11" :foreground "grey45"))))
 '(powerline-inactive2 ((t (:inherit mode-line-inactive :background "grey20" :foreground "grey55"))))
 '(rjsx-tag ((t (:inherit font-lock-keyword-face))))
 '(rjsx-tag-bracket-face ((t (:inherit font-lock-keyword-face))))
 '(rst-level-1 ((t (:background "grey85" :weight bold))))
 '(rst-literal ((t (:inherit shadow :extend t :background "cornsilk2"))))
 '(scroll-bar ((t (:background "cornsilk3"))))
 '(sh-heredoc ((t (:foreground "tan4"))))
 '(shadow ((t (:foreground "cornsilk4"))))
 '(success ((t (:foreground "darkgreen" :weight bold))))
 '(tab-bar ((t (:inherit variable-pitch :background "black"))))
 '(tab-bar-tab ((t (:inherit tab-bar :background "cornsilk3" :box (:line-width 1 :style pressed-button)))))
 '(tab-bar-tab-inactive ((t (:inherit tab-bar-tab :background "cornsilk4" :box (:line-width 1 :style released-button)))))
 '(term-color-green ((t (:background "green4" :foreground "green4"))))
 '(term-color-cyan ((t (:background "cyan4" :foreground "cyan4"))))
 '(term-color-magenta ((t (:background "magenta4" :foreground "magenta4"))))
 '(term-color-yellow ((t (:background "yellow" :foreground "yellow"))))
 '(tool-bar ((default (:foreground "black" :box (:line-width 1 :style released-button))) (((type x w32 mac) (class color)) (:background "grey92"))))
 '(treemacs-directory-collapsed-face ((t (:inherit treemacs-directory-face :foreground "gray30"))))
 '(treemacs-directory-face ((t (:weight bold))))
 '(treemacs-tags-face ((t (:inherit font-lock-function-name-face))))
 '(web-mode-doctype-face ((t (:foreground "Grey35"))))
 '(web-mode-html-attr-name-face ((t (:foreground "gray10"))))
 '(web-mode-html-tag-face ((t (:weight bold))))
 '(warning ((t (:foreground "DarkOrange3" :weight bold))))
 '(whitespace-hspace ((t (:background "LemonChiffon1"))))
 '(whitespace-line ((t (:background "yellow2"))))
 '(whitespace-newline ((t (:background "cornsilk2" :foreground "cornsilk4" :weight normal))))
 '(whitespace-space ((t (:foreground "cornsilk2"))))
 '(window-divider ((t (:inherit default :inverse-video t))))
 '(window-divider-first-pixel ((t (:foreground "cornsilk2"))))
 '(window-divider-last-pixel ((t (:foreground "cornsilk4")))))

(custom-theme-set-variables
 'faff
 ;; ansi-color-names-vector: defaults such as yellow3 are nearly unreadable
 '(ansi-color-names-vector
   ["black" "red3" "green4" "yellow" "blue2" "magenta4" "cyan4" "white"])
 ;; lsp-diagnostics-attributes: the default for `unnecessary', is gray, which is
 ;; nearly invisible on cornsilk3.
 '(lsp-diagnostics-attributes
   '((unnecessary :foreground "cornsilk4")
     (deprecated :strike-through t))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'faff)
;;; faff-theme.el ends here
