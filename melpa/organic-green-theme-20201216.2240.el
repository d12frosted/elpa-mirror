;;; organic-green-theme.el --- Low-contrast green color theme.
;; Package-Version: 20201216.2240
;; Package-Commit: 0ed99a9c0cf14be0a1f491518821f0e9b7e88b88

;;; Copyright © 2009-2020 - Kostafey <kostafey@gmail.com>

;; This file is not [yet] part of GNU Emacs, but is distributed under
;; the same terms.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 2 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; (load-theme 'organic-green t)

;;; Code:

(deftheme organic-green "Low-contract green color theme.")

(defgroup organic-green nil
  "Organic-green theme customization.
The theme needs to be reloaded after changing anything in this group."
  :group 'faces)

(defcustom organic-green-boldless nil
  "Use bold text in less code constructs."
  :type 'boolean
  :group 'organic-green)

(let ((class '((class color) (min-colors 89)))
      (organic-fg        "#326B6B")
      (organic-bg        "#F0FFF0")
      (organic-cursor-fg "#225522")
      (organic-fringe-bg "#E5E5E5")
      (organic-fringe-fg "gray40")

      ;; base color pallet
      (organic-white     "white")

      (organic-teal      "#009292")
      (organic-olive-0   "#6E8B3D")
      (organic-olive-1   "DarkOliveGreen")

      (organic-green-0   "#D5F0D5")
      (organic-green-1   "#A0F0A0")
      (organic-green-2   "#119911")
      (organic-green-3   "#22aa22")
      (organic-green-4   "#008B45")
      (organic-green-5   "#00A86B")
      (organic-green-6   "dark sea green")

      (organic-blue-0    "#8CC4FF")
      (organic-blue-1    "LightSkyBlue3")
      (organic-blue-2    "#1874CD")
      (organic-blue-3    "#3063EA")
      (organic-blue-4    "#0066CC")
      (organic-blue-5    "#3465BD")
      (organic-blue-6    "#204a87")

      (organic-yellow-0  "#F2FFC0")
      (organic-yellow-1  "#F0F0A1")
      (organic-yellow-2  "#DDEE00")
      (organic-yellow-3  "yellow")
      (organic-yellow-4  "#B8860B")
      (organic-yellow-5  "#8B6508")

      (organic-yellow-green-0 "#BFFF00")

      (organic-purple    (if organic-green-boldless "#912CEE" "#A020F0"))
      (organic-cornflower "#4045F0")
      (organic-orange    "#CE5C00")

      (organic-red-0     "#FFF0F0")
      (organic-red-1     "#ffdddd")
      (organic-red-2     "#eecccc")
      (organic-red-3     "tomato1")
      (organic-red-4     "red")
      (organic-red-5     "#cc0000")
      (organic-red-6     "#A40000")

      (organic-alum-1    "#eeeeec")
      (organic-alum-2    "#d3d7cf")
      (organic-alum-3    "#babdb6")
      (organic-alum-4    "#2e3436")

      (organic-gray-0    "#E3F2E1")
      (organic-gray-1    "#DAEADA")
      (organic-gray-2    "#E5E5E5")
      (organic-gray-3    "gray")
      (organic-gray-4    "gray50")
      (organic-gray-5    "DimGray")
      (organic-gray-6    "gray28")

      ;; conditional styles that evaluate user-facing customization
      ;; options
      (organic-green-bold
       (if organic-green-boldless
           'normal
         'bold))

      (organic-green-extra-bold
       (if organic-green-boldless
           'normal
         'extra-bold))

      (organic-green-semi-bold
       (if organic-green-boldless
           'normal
         'semi-bold)))

  (custom-theme-set-faces
   'organic-green
   ;; essential styles
   `(default ((,class (:foreground ,organic-fg :background ,organic-bg))))

   ;; base
   `(bold ((,class (:weight bold))))
   `(extra-bold ((,class (:weight extra-bold))))
   `(semi-bold ((,class (:weight semi-bold))))
   `(italic ((,class (:slant italic))))
   `(error ((,class (:foreground ,organic-red-6 :weight ,organic-green-bold))))
   `(escape-glyph ((,class (:foreground ,organic-green-5))))
   `(warning ((,class (:foreground ,organic-orange))))
   `(success ((,class (:foreground ,organic-green-3))))
   `(font-lock-builtin-face ((,class (:foreground ,organic-teal))))
   `(font-lock-comment-face ((,class (:foreground ,organic-gray-4))))
   `(font-lock-constant-face ((,class (:foreground ,organic-blue-5))))
   `(font-lock-function-name-face ((,class (:foreground ,organic-blue-3 :weight ,organic-green-extra-bold))))
   `(font-lock-keyword-face ((,class (:foreground ,organic-purple :weight ,organic-green-semi-bold))))
   `(font-lock-string-face ((t (:foreground ,organic-green-2))) t)
   `(font-lock-type-face ((t (:foreground ,organic-teal :weight ,organic-green-bold))))
   `(font-lock-variable-name-face ((,class (:foreground ,organic-yellow-4 :width condensed))))
   `(font-lock-warning-face ((,class (:foreground ,organic-red-6 :weight ,organic-green-bold))))

   ;; ui
   `(cursor ((,class (:background ,organic-cursor-fg))))
   `(fringe ((,class (:background ,organic-fringe-bg :foreground ,organic-fringe-fg))))
   `(vertical-border ((,class (:foreground ,organic-fringe-fg))))
   `(minibuffer-prompt ((,class (:foreground ,organic-blue-6 :weight bold))))
   `(mode-line ((,class (:box (:line-width -1 :style released-button) :background ,organic-alum-2 :foreground ,organic-alum-4))))
   `(mode-line-inactive ((,class (:box (:line-width -1 :style released-button) :background ,organic-alum-1 :foreground ,organic-alum-4))))
   `(link ((,class (:underline t :foreground ,organic-blue-6))))
   `(link-visited ((,class (:underline t :foreground ,organic-blue-5))))
   `(highlight ((,class (:background ,organic-green-0))))
   `(hl-line ((,class (:background ,organic-green-1 :inverse-video nil))))
   `(region ((,class (:background "#EEEEA0"))))
   `(lazy-highlight ((,class (:background ,organic-yellow-2 :inverse-video nil))))
   `(isearch ((,class (:foreground ,organic-fg :background ,organic-yellow-3 :inverse-video nil))))
   `(cua-rectangle ((,class (:background ,organic-yellow-green-0))))
   `(secondary-selection ((,class (:background ,organic-blue-0))))
   `(trailing-whitespace ((,class (:background ,organic-red-5))))

   ;; external packages
   ;;; Jabber
   '(jabber-roster-user-chatty ((t (:inherit font-lock-type-face :bold t))))
   '(jabber-roster-user-online ((t (:inherit font-lock-keyword-face :bold t))))
   `(jabber-roster-user-offline ((t (:foreground ,organic-fg :background ,organic-bg))))
   '(jabber-roster-user-away ((t (:inherit font-lock-doc-face))))
   '(jabber-roster-user-xa ((t (:inherit font-lock-doc-face))))
   '(jabber-roster-user-dnd ((t (:inherit font-lock-comment-face))))
   '(jabber-roster-user-error ((t (:inherit font-lock-warning-face))))
   '(jabber-title-small ((t (:height 1.2 :weight bold))))
   '(jabber-title-medium ((t (:inherit jabber-title-small :height 1.2))))
   '(jabber-title-large ((t (:inherit jabber-title-medium :height 1.2))))
   '(jabber-chat-prompt-local ((t (:inherit font-lock-string-face :bold t))))
   '(jabber-chat-prompt-foreign ((t (:inherit font-lock-function-name-face :bold nil))))
   '(jabber-chat-prompt-system ((t (:inherit font-lock-comment-face :bold t))))
   '(jabber-rare-time-face ((t (:inherit font-lock-function-name-face :bold nil))))
   '(jabber-activity-face ((t (:inherit jabber-chat-prompt-foreign))))
   '(jabber-activity-personal-face ((t (:inherit jabber-chat-prompt-local :bold t))))

   ;;; LaTeX
   `(font-latex-bold-face ((t (:bold t :foreground ,organic-olive-1))))
   `(font-latex-italic-face ((t (:italic t :foreground ,organic-olive-1))))
   `(font-latex-math-face ((t (:foreground ,organic-yellow-4))))
   `(font-latex-sedate-face ((t (:foreground ,organic-gray-5))))
   '(font-latex-string-face ((t (nil))))
   `(font-latex-warning-face ((t (:bold t :weight semi-bold :foreground ,organic-orange))))

   ;;; Quack
   `(quack-pltish-paren-face ((((class color) (background light)) (:foreground ,organic-green-5))))
   `(quack-pltish-keyword-face ((t (:foreground ,organic-purple :weight bold))))

   ;;; js2-mode
   `(js2-external-variable ((t (:inherit warning))))
   `(js2-function-param ((t (:foreground ,organic-teal))))
   `(js2-jsdoc-type ((t (:foreground ,organic-blue-2))))
   `(js2-jsdoc-tag ((t (:foreground ,organic-blue-5))))
   `(js2-jsdoc-value ((t (:foreground ,organic-teal))))

   ;; clojure/CIDER
   `(cider-result-overlay-face ((t (:background ,organic-bg :box (:line-width -1 :color ,organic-yellow-1)))))

   ;;; Java
   `(jdee-java-properties-font-lock-comment-face ((t (:foreground ,organic-gray-4))))
   `(jdee-java-properties-font-lock-equal-face ((t (:foreground ,organic-blue-2))))
   '(jdee-java-properties-font-lock-substitution-face ((t (:inherit font-lock-function-name-face :bold nil))))
   '(jdee-java-properties-font-lock-class-name-face ((t (:inherit font-lock-constant-face :bold nil))))
   '(jdee-java-properties-font-lock-value-face ((t (:inherit font-lock-string-face :bold nil))))
   `(jdee-java-properties-font-lock-backslash-face ((t (:foreground ,organic-green-5))))

   ;;; Scala
   `(scala-font-lock:var-face ((t (:foreground ,organic-orange))))

   ;;; Lsp
   `(lsp-ui-doc-border ((t (:background ,organic-gray-2))))
   `(lsp-ui-doc-background ((t (:background ,organic-green-0))))
   `(lsp-ui-sideline-code-action ((t (:background ,organic-green-0 :foreground ,organic-gray-4))))

   ;;; Tcl
   `(tcl-substitution-char-face ((t (:foreground ,organic-olive-0))))

   ;;; Erc
   `(erc-action-face ((t (:foreground ,organic-gray-3 :weight bold))))
   `(erc-command-indicator-face ((t (:foreground ,organic-gray-6 :weight bold))))
   `(erc-nick-default-face ((t (:foreground ,organic-purple :weight bold))))
   `(erc-input-face ((t (:foreground ,organic-blue-6))))
   `(erc-notice-face ((t (:foreground ,organic-green-6 :weight bold))))
   `(erc-timestamp-face ((t (:foreground ,organic-green-2 :weight bold))))

   ;; Circe
   `(circe-server-face ((t (:foreground ,organic-green-6))))
   `(circe-prompt-face ((t (:foreground ,organic-gray-5 :background ,organic-green-0 :weight bold))))
   `(circe-highlight-nick-face ((t (:foreground ,organic-orange))))
   `(lui-time-stamp-face ((t (:foreground ,organic-green-2))))

   ;;; Rst
   '(rst-definition ((t (:inherit font-lock-constant-face))) t)
   `(rst-level-1 ((t (:background ,organic-green-0))) t)
   `(rst-level-2 ((t (:background ,organic-gray-1))))
   `(rst-level-3 ((t (:background ,organic-gray-1))))
   `(rst-level-4 ((t (:background ,organic-gray-1))))
   `(rst-level-5 ((t (:background ,organic-gray-1))))
   `(rst-level-6 ((t (:background ,organic-gray-1))))
   '(rst-block ((t (:inherit font-lock-function-name-face :bold t))) t)
   '(rst-external ((t (:inherit font-lock-constant-face))) t)
   '(rst-directive ((t (:inheit font-lock-builtin-face))) t)
   '(rst-literal ((t (:inheit font-lock-string-face))))
   '(rst-emphasis1 ((t (:inherit italic))) t)
   `(rst-adornment ((t (:bold t :foreground ,organic-blue-5))))

   ;; Whitespace-Mode
   `(whitespace-empty ((t (:background ,organic-bg :foreground ,organic-alum-3))) t)
   `(whitespace-indentation ((t (:background ,organic-bg :foreground ,organic-alum-3))) t)
   `(whitespace-newline ((t (:background ,organic-bg :foreground ,organic-alum-3))) t)
   `(whitespace-space-after-tab ((t (:background ,organic-bg :foreground ,organic-alum-3))) t)
   `(whitespace-tab ((t (:background ,organic-bg :foreground ,organic-alum-3))) t)
   `(whitespace-hspace ((t (:background ,organic-bg :foreground ,organic-alum-3))) t)
   `(whitespace-line ((t (:background ,organic-bg :foreground ,organic-alum-3))) t)
   `(whitespace-space ((t (:background ,organic-bg :foreground ,organic-alum-3))) t)
   `(whitespace-space-before-tab ((t (:background ,organic-bg :foreground ,organic-alum-3))) t)
   `(whitespace-trailing ((t (:background ,organic-bg :foreground ,organic-red-6))) t)

   ;;; Log4j
   '(log4j-font-lock-warn-face ((t (:inherit warning))))

   ;;; sh-mode
   '(sh-heredoc ((t (:inherit font-lock-string-face))))
   '(sh-quoted-exec ((t (:inherit font-lock-constant-face))))

   ;;; Ace-Jump
   `(ace-jump-face-foreground ((t (:foreground ,organic-red-4 :underline nil))) t)

   ;;; Diff
   `(diff-indicator-added ((t (:foreground ,organic-green-2)) t))
   `(diff-added ((t (:foreground ,organic-green-2)) t))
   `(diff-indicator-removed ((t (:foreground ,organic-red-5))) t)
   `(diff-removed ((t (:foreground ,organic-red-5))) T)

   ;;; Magit
   `(magit-diff-add ((t (:foreground ,organic-green-2)) t))
   `(magit-diff-del ((t (:foreground ,organic-red-5))) t)
   `(magit-diff-added ((t (:foreground ,organic-green-3 :background "#ddffdd"))) t)
   `(magit-diff-removed ((t (:foreground "#aa2222" :background ,organic-red-1))) t)
   `(magit-diff-added-highlight ((t (:foreground ,organic-green-3 :background "#cceecc"))) t)
   `(magit-diff-removed-highlight ((t (:foreground "#aa2222" :background ,organic-red-2))) t)
   `(magit-diff-context-highlight ((t (:background ,organic-bg :foreground ,organic-gray-4))) t)
   `(magit-diff-file-heading-highlight ((t (:background ,organic-green-0))) t)
   `(magit-item-highlight ((t (:background ,organic-gray-0))) t)
   `(magit-log-author ((t (:foreground ,organic-green-4))) t)
   `(magit-popup-argument ((t (:foreground ,organic-blue-3))) t)
   `(magit-process-ok ((t (:foreground ,organic-green-2))) t)
   `(magit-section-highlight ((t (:background ,organic-green-0))) t)
   `(magit-branch-remote ((t (:foreground ,organic-olive-0))) t)
   `(magit-section-heading ((t (:bold t :foreground ,organic-yellow-5))) t)

   ;;; Git-Gutter
   `(git-gutter:added ((t (:foreground ,organic-green-2)) t))
   `(git-gutter:deleted ((t (:foreground ,organic-red-5))) t)
   `(git-gutter:modified ((t (:foreground ,organic-blue-2))) t)
   `(git-gutter-fr:added ((t (:foreground ,organic-green-6 :background ,organic-green-6)) t))
   `(git-gutter-fr:deleted ((t (:foreground ,organic-red-3 :background ,organic-red-3))) t)
   `(git-gutter-fr:modified ((t (:foreground ,organic-blue-1 :background ,organic-blue-1))) t)

   ;;; Org-Mode
   `(org-table ((t (:foreground ,organic-teal))) t)
   `(org-level-1 ((t (:inherit font-lock-keyword-face :weight ,organic-green-bold))) t)
   `(org-level-2 ((t (:inherit font-lock-function-name-face :weight ,organic-green-bold))) t)
   `(org-level-3 ((t (:inherit font-lock-variable-name-face :weight ,organic-green-bold))) t)
   `(org-level-4 ((t (:foreground ,organic-green-5 :weight ,organic-green-bold))) t)
   `(org-level-5 ((t (:foreground  ,organic-blue-5 :weight ,organic-green-bold))) t)
   `(org-level-6 ((t (:foreground ,organic-teal :weight ,organic-green-bold))) t)
   `(org-block ((,class (:foreground ,organic-fg))))
   `(org-block-begin-line ((t (:foreground ,organic-blue-5))) t)
   `(org-block-end-line ((t (:foreground ,organic-blue-5))) t)
   `(org-done ((t (:inherit success))) t)
   `(org-todo ((t (:inherit warning))) t)

   ;;; Misc
   `(nxml-element-local-name ((t (:foreground ,organic-blue-4 :weight normal))) t)
   `(yas-field-highlight-face ((t (:background ,organic-yellow-2))))
   `(idle-highlight ((t (:background ,organic-yellow-0))) t)
   `(comint-highlight-prompt ((t (:foreground ,organic-blue-5 :weight bold))) t)
   `(flx-highlight-face  ((t (:foreground ,organic-blue-4 :bold t :underline t))) t)

   ;;; Powerline
   `(powerline-active1 ((t (:background ,organic-alum-3 :inherit mode-line))) t)
   `(powerline-active2 ((t (:background ,organic-alum-2 :inherit mode-line))) t)
   `(powerline-inactive1  ((t (:background ,organic-gray-3 :inherit mode-line-inactive))) t)
   `(powerline-inactive2  ((t (:background ,organic-gray-3 :inherit mode-line-inactive))) t)

   ;;; Tabbar
   `(tabbar-button ((t :inherit tabbar-default :box (:line-width 1 :color ,organic-gray-3))))
   `(tabbar-modified ((t (:inherit tabbar-default :foreground ,organic-green-2
                                   :bold t
                                   :box (:line-width 1 :color ,organic-white
                                                     :style released-button)))))
   `(tabbar-selected ((t :inherit tabbar-default
                         :box (:line-width 1 :color ,organic-white :style pressed-button)
                         :foreground ,organic-alum-4 :bold t)))
   '(tabbar-selected-modified ((t :inherit tabbar-selected)))

   ;; Company
   `(company-tooltip ((t :foreground ,organic-gray-6 :background ,organic-gray-0)))
   `(company-tooltip-annotation ((t :foreground ,organic-fg)))
   `(company-tooltip-common ((t :foreground ,organic-blue-4)))
   `(company-tooltip-search ((t :background ,organic-yellow-1)))
   `(company-tooltip-search-selection ((t :background ,organic-yellow-1)))
   `(company-echo-common ((t :foreground ,organic-cornflower)))
   `(company-scrollbar-fg ((t :background ,organic-gray-4)))
   `(company-scrollbar-bg ((t :background ,organic-gray-3)))

   ;;; Web-Mode
   `(web-mode-current-element-highlight-face ((,class (:background ,organic-green-0))))
   `(web-mode-html-tag-face ((t (:foreground ,organic-gray-6))) t)
   `(web-mode-html-attr-name-face ((t (:foreground ,organic-blue-4))) t)
   `(web-mode-doctype-face ((t (:foreground ,organic-blue-5))) t)
   `(web-mode-comment-face ((t (:foreground ,organic-gray-4)) t))
   `(web-mode-css-selector-face ((t (:foreground ,organic-teal))) t)
   `(web-mode-function-call-face ((t (:foreground ,organic-fg))) t)
   `(web-mode-function-name-face ((t :inherit font-lock-function-name-face)))

   `(eldoc-highlight-function-argument
     ((t (:foreground ,organic-green-2 :weight bold))) t)

   `(table-cell ((t (:foreground ,organic-fg :background ,organic-green-0))) t)

   ;;; Dired
   `(diredp-dir-heading ((t (:background ,organic-green-0))))
   `(diredp-dir-name ((t (:foreground ,organic-alum-4))))
   `(diredp-file-name ((t (:foreground ,organic-fg))))
   `(diredp-file-suffix ((t (:foreground ,organic-teal))))

   ;;; Dired+
   `(diredp-compressed-file-suffix ((t (:foreground ,organic-orange))))

   ;;Highlight pair parentheses
   `(show-paren-match ((t (:background ,organic-yellow-1))))
   `(show-paren-mismatch ((t (:background ,organic-red-1))))

   ;;; Rainbow-Delimiters
   ;; (1 (2 (3 (4 (5 (6 (7 (8 (9 (10 (11 (12))))))))))))
   `(rainbow-delimiters-depth-1-face ((t (:foreground "#666666" :background ,organic-bg))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground "#5544EE" :background ,organic-bg))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground "#2265DC" :background ,organic-bg))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground "#00A89B" :background ,organic-bg))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground "#229900" :background ,organic-bg))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground "#999900" :background ,organic-bg))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground "#F57900" :background ,organic-bg))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground "#EE66E8" :background ,organic-bg))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground "purple"  :background ,organic-bg)))))

  (custom-set-faces
   ;; Multi-Magit
   `(multi-magit-repo-heading ((t (:inherit magit-section-heading :box nil))))

   ;; Speedbar
   `(speedbar-selected-face ((t (:foreground ,organic-green-4 :underline t))))

   ;; fill-column-indicator for `emacs-major-version' >= 27
   `(fill-column-indicator ((t (:foreground "gray80" :weight normal)))))

  (custom-theme-set-variables
   'organic-green

   ;; fill-column-indicator
   `(fci-rule-color "gray80")

   ;; marker
   `(highlight-symbol-colors
     '("#FFF68F"
       "#B7EB8F"
       "#76DDBA"
       "#91D5FF"
       "#ADC6FF"
       "#D3ADF7"
       "#FFADD2"
       "#FFA39E"
       "#FFD591"))

   ;; org-mode code blocks
   `(org-src-block-faces '(("emacs-lisp" (:background ,organic-bg))
                           ("dot" (:foreground ,organic-gray-4))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'organic-green)
;;; organic-green-theme.el ends here
