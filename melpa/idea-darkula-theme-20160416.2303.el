;;; idea-darkula-theme.el --- Color theme based on IntelliJ IDEA Darkula color theme

;; Copyright (C) 2015 Alexey Veretennikov

;; Author: Alexey Veretennikov <alexey dot veretennikov at gmail dot com>
;; Keywords: themes
;; URL: http://github.com/fourier/idea-darkula-theme
;; Version: 0.1
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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To use it, put the following in your Emacs configuration file:
;;
;;   (load-theme 'idea-darkula t)
;;
;; Requirements: Emacs 24.

;;; Code:

(deftheme idea-darkula
  "Theme based on IntelliJ IDEA darkula theme")

(custom-theme-set-faces
 'idea-darkula
 '(default ((t (:underline nil
                           :overline nil
                           :strike-through nil
                           :box nil
                           :inverse-video nil
                           :foreground "#A9B7C6"
                           :background "#2B2B2B"
                           :stipple nil
                           :inherit nil))))
 '(cursor ((t (:background "#bbbbbb"))))
 '(region ((t (:background "#214283"))))
 ;; vertical line when spilt window with C-x 3 on text terminals
 '(vertical-border ((t (:foreground "#555555"))))
 ;; same on graphical displays
 '(fringe ((t (:foreground "#555555"))))
 '(link ((t (:underline (:color foreground-color :style line) :foreground "#287BDE"))))
 '(link-visited ((t (:underline (:color foreground-color :style line) :foreground "#287BDE" :inherit (link)))))
 ;; search
 '(isearch ((t (:background "#214283" :box (:line-width -1 :color "#bbbbbb")))))
 ;; other search matches
 '(lazy-highlight ((t (:background "#32593d" :box (:line-width -1 :color "#3c704b")))))
 ;; tooltip colors doesn't work on OSX
 '(tooltip ((t (:inherit (variable-pitch) :foreground "#bbbbbb" :background "#5c5c42"))))
 '(mode-line ((t (:box (:line-width -1 :color "#464646") :weight bold :foreground "#bbbbbb" :background "#3c3f41"))))
 '(mode-line-inactive ((t (:style released-button :inherit (mode-line) :weight normal))))
 ;; '(mode-line-highlight ((((class color) (min-colors 88)) (:box (:line-width 2 :color "grey40" :style released-button))) (t (:inherit (highlight)))))
 ;; IDEA supports something like hl-mode
 '(hl-line ((t (:background "#323232"))))
 ;; ecb customizations
 '(ecb-default-highlight-face ((t (:background "DarkSlateGray" :box (:line-width 1 :style released-button)))))
 '(ecb-default-general-face ((t (:foreground "white"))))
 ;; coding customizations
 '(font-lock-comment-face ((t (:foreground "#808080"))))
 '(font-lock-comment-delimiter-face ((t (:foreground "#808080"))))
 '(font-lock-doc-face ((t (:foreground "#629755" :italic t))))
 '(font-lock-keyword-face ((t (:foreground "#CC7832"))))
 '(font-lock-preprocessor-face ((t (:foreground "green"))))
 '(font-lock-string-face ((t (:foreground "#6A8759"))))
 '(font-latex-string-face ((t (:foreground "#6A8759"))))
 '(font-latex-math-face ((t (:foreground "aquamarine1"))))
 '(font-lock-type-face ((t (:foreground "#CC7832"))))
 '(font-lock-builtin-face ((t (:foreground "#CC7832"))))
 '(font-lock-function-name-face ((t (:foreground "#FFC66D"))))
 ;; (font-lock-function-name-face ((t (:foreground "selectedControlColor"))))
 ;; (font-lock-variable-name-face ((t (:foreground "green"))))
 ;; (font-lock-negation-char-face ((t (:foreground "white"))))
 '(font-lock-number-face ((t (:foreground "#6897BB"))))
 '(font-lock-constant-face ((t (:foreground "#9876AA" :italic t))))
 '(font-lock-warning-face ((t (:foreground "red"))))
 '(font-lock-operator-face ((t (:foreground "#CC7832"))))
 '(font-lock-end-statement ((t (:foreground "white"))))
 ;; Java-like annotations 
 '(c-annotation-face ((t (:foreground "#BBB529"))))
 ;; log4j customizations
 '(log4j-font-lock-warn-face ((t (:foreground "Orange"))))
 ;; info-mode customization
 '(info-menu-header ((t (:foreground "white"))))
 '(info-title-1 ((t (:foreground "white"))))
 '(info-title-2 ((t (:foreground "white"))))
 '(info-title-3 ((t (:foreground "white"))))
 '(info-title-4 ((t (:foreground "white"))))
 ;; python customizations
 '(py-builtins-face ((t (:foreground "#ffffff"))))
 ;; helm customizations
 '(helm-selection ((t (:background "Cyan" :foreground "black"))))
 '(helm-ff-directory ((t (:foreground "#ffffff" :background "MidnightBlue"))))
 ;; dired customizations
 '(diredp-file-name ((t (:foreground "cyan1"))))
 '(diredp-file-suffix ((t (:foreground "cyan1"))))
 '(diredp-dir-heading ((t (:foreground "white" :background "#2B2B2B" :underline t ))))
 '(diredp-dir-priv ((t (:foreground "#ffffff" :background "#2B2B2B"))))
 ;; file attributes in the dired
 '(diredp-read-priv ((t (:foreground "grey" :background "#2B2B2B"))))
 '(diredp-write-priv ((t (:foreground "grey" :background "#2B2B2B"))))
 '(diredp-exec-priv ((t (:foreground "grey" :background "#2B2B2B"))))
 ;; no attribute set
 '(diredp-no-priv ((t (:foreground "grey" :background "#2B2B2B"))))
 ;; marked file color and mark sign
 '(diredp-flag-mark-line ((t (:background "#2B2B2B" :foreground "gold"))))
 '(diredp-flag-mark ((t (:foreground "gold" :background "#2B2B2B"))))
 '(diredp-inode+size ((t (:foreground "white"))))
 '(diredp-compressed-file-suffix ((t (:foreground "cyan1"))))
 '(diredp-ignored-file-name ((t (:foreground "cyan1"))))
 ;; nXML customizations
 ; '<' and '>' characters
 '(nxml-tag-delimiter ((t (:foreground "#E8BF6A"))))
 ; '=' and '"' characters 
 '(nxml-attribute-value-delimiter ((t (:foreground "#E8BF6A"))))
 ; tag name
 '(nxml-element-local-name ((t (:foreground "#CC7832"))))
 ; attribute name
 ;'(nxml-attribute-local-name ((t (:foreground "#BABABA"))))
 '(nxml-attribute-local-name ((t (:foreground "#ABCDEF"))))
 ; attribute value
 '(nxml-attribute-value ((t (:foreground "#A5C261"))))
 '(nxml-text ((t (:foreground "#BABABA"))))
 '(nxml-cdata-section-content ((t (:foreground "gold"))))
 ; attribute prefix like xlink:href - here it is "xlink"
 ;'(nxml-attribute-prefix ((t (:foreground "#DADADA"))))
 '(nxml-attribute-prefix ((t (:foreground "#BBEDFF"))))
 ; tag prefix : <ui:Checkbox> - here it is "ui"
 '(nxml-element-prefix ((t (:foreground "#EC9852"))))
 ;; ERC customizations
 '(erc-nick-default-face ((t (:foreground "##9876AA" :bold t))))
 '(erc-action-face ((t (:foreground "#808080"))))
 '(erc-button ((t (:foreground "cyan" :underline t))))
 ;; GNUS customizations
 '(gnus-group-mail-3-empty ((t )))
 '(gnus-group-mail-3 ((t (:foreground "#BBEDFF" :weight bold))))
 '(gnus-group-mail-low-empty  ((t )))
 '(gnus-group-mail-low  ((t (:foreground "#BBEDFF" :weight bold))))
 '(gnus-group-news-3-empty  ((t )))
 '(gnus-group-news-3  ((t (:foreground "#BBEDFF" :weight bold))))
 ;; GNUS topic face. By default GNUS doesn't support
 ;; topic faces, see http://www.emacswiki.org/emacs/GnusFormatting#toc6
 ;; how to add one
 '(gnus-topic-face ((t (:foreground "#FFC66D" :weight bold :underline t))))
 '(gnus-topic-empty-face ((t (:foreground "#FFC66D" :underline t))))
 ;; GNUS summary (list of messages) faces
 '(gnus-summary-normal-ancient ((t )))
 '(gnus-summary-normal ((t )))
 '(gnus-summary-normal-unread ((t (:foreground "#BBEDFF" :weight bold))))

 ;; Company-mode faces based on IntelliJ IDEA colors
 '(company-tooltip ((t (:foreground "#bbbbbb" :background "#3c3f41"))))
 '(company-tooltip-selection ((t (:background "#0052a4"))))

 '(company-tooltip-search ((t (:inherit isearch))))
 '(company-tooltip-mouse ((t (:background "#4a4e4f"))))
 '(company-tooltip-common ((t (:foreground "#d17ad6"))))
 '(company-tooltip-annotation ((t (:inherit company-tooltip-common))))
 '(company-scrollbar-fg ((t (:background "#5b5d5e"))))
 '(company-scrollbar-bg ((t (:background "#3b3f40"))))
 ;;'(company-preview ((t (:background "blue4" :foreground "wheat"))))
 '(company-preview ((t (:inherit region))))
 '(company-preview-common ((t (:inherit company-preview :foreground "#d17ad6"))))
 '(company-preview-search ((t (:inherit isearch))))
 ;; some custom additions to the Common Lisp code
 '(lisp-font-lock-annotation-face ((t (:foreground "#BBB529"))))
 '(slime-repl-inputed-output-face ((t (:inherit 'default))))
 '(slime-repl-input-face ((t (:inherit 'default :weight bold))))
 '(slime-repl-output-face ((t (:foreground "cyan1"))))
 '(slime-repl-prompt-face ((t (:foreground "#007f00"))))
 )


 ;; '(font-lock-regexp-grouping-backslash ((t (:inherit (bold)))))
 ;; '(font-lock-regexp-grouping-construct ((t (:inherit (bold)))))
 ;; '(header-line ((t (:underline (:color foreground-color :style line) :inverse-video nil :foreground "#e7f6da" :background "#303030" :inherit (mode-line)))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path)
           load-file-name)
  ;; add theme folder to `custom-theme-load-path' when installing over MELPA
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))


(provide-theme 'idea-darkula)
;;; idea-darkula-theme.el ends here
