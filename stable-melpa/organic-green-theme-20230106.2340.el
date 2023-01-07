;;; organic-green-theme.el --- Low-contrast green color theme.
;; Package-Version: 20230106.2340
;; Package-Commit: bb0472993b8ffa6edcc8d787c18046b6fd3bac88

;;; Copyright © 2009-2022 - Kostafey <kostafey@gmail.com>

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

(defcustom organic-green-version 1
  "Set organic-green color theme version."
  :type 'integer
  :group 'organic-green)

(if (eq organic-green-version 2)
    ;;-------------------------------------------------------------------
    ;; version 2
    (let ((class '((class color) (min-colors 89)))
          ;; base color pallet
          (organic-fg        "#326B6B")
          (organic-bg        "#F0FFF0")
          (organic-cursor-fg "#225522")
          (organic-cursor-bg "#D5F0D5")
          (organic-highlight-yellow "#F0F0A1")
          (organic-highlight-green  "#C1F3CA")
          (organic-highlight-gray   "#E3F2E1")
          (organic-highlight-blue   "#ACD7E5")

          (organic-dark-black       "#24292E")
          (organic-black            "#2E3436")
          (organic-green-black      "#444D56")
          (organic-dark-gray        "#5F5F5F")
          (organic-medium-gray      "#666666")
          (organic-gray             "#7F7F7F")
          (organic-light-gray       "#B2BDB1")
          (organic-dark-white       "#CCCCCC")
          (organic-shadow           "#D3E0D3")
          (organic-light-white      "#EEEEEC")

          (organic-red             "#EF2929")
          (organic-orange          "#CE5C00")
          (organic-yellow          "#B8860B")
          (organic-sun             "#999900")
          (organic-green           "#119911")
          (organic-teal            "#008888")
          (organic-blue            "#0065CC")
          (organic-violet          "#5544EE")
          (organic-purple          "#912CEE")
          (organic-magenta         "#D33682")

          (organic-sign-add        "#27A745")
          (organic-sign-change     "#2188FF")
          (organic-sign-delete     "#D73A49")

          (organic-marker-yellow   "#FFF68F")
          (organic-marker-green    "#B7EB8F")
          (organic-marker-teal     "#76DDBA")
          (organic-marker-blue     "#91D5FF")
          (organic-marker-violet   "#ADC6FF")
          (organic-marker-purple   "#D3ADF7")
          (organic-marker-pink     "#FFADD2")
          (organic-marker-red      "#FFA39E")
          (organic-marker-orange   "#FFD591"))

      (custom-theme-set-faces
       'organic-green
       ;; essential styles
       `(default ((,class (:foreground ,organic-fg :background ,organic-bg))))

       ;; base
       `(bold ((,class (:weight bold))))
       `(extra-bold ((,class (:weight extra-bold))))
       `(semi-bold ((,class (:weight semi-bold))))
       `(italic ((,class (:slant italic))))
       `(error ((,class (:foreground ,organic-red :weight normal))))
       `(escape-glyph ((,class (:foreground ,organic-sun))))
       `(warning ((,class (:foreground ,organic-orange))))
       `(success ((,class (:foreground ,organic-sun))))
       `(compilation-info ((,class (:foreground ,organic-green))))
       `(shadow ((,class (:foreground ,organic-gray))))
       `(match ((,class (:foreground ,organic-yellow))))
       `(menu ((,class (:foreground ,organic-violet))))
       `(completions-annotations ((,class (:foreground ,organic-green))))
       `(completions-common-part ((,class (:foreground ,organic-blue :bold t :underline t))))       
       `(completions-first-difference ((,class (:foreground ,organic-blue))))
       `(font-lock-builtin-face ((,class (:foreground ,organic-teal))))
       `(font-lock-comment-face ((,class (:foreground ,organic-gray))))
       `(font-lock-constant-face ((,class (:foreground ,organic-blue))))
       `(font-lock-function-name-face ((,class (:foreground ,organic-blue :weight normal))))
       `(font-lock-keyword-face ((,class (:foreground ,organic-purple :weight normal))))
       `(font-lock-string-face ((t (:foreground ,organic-green))) t)
       `(font-lock-doc-face ((t (:foreground ,organic-green))) t)
       `(font-lock-type-face ((t (:foreground ,organic-teal :weight normal))))
       `(font-lock-variable-name-face ((,class (:foreground ,organic-yellow))))
       `(font-lock-warning-face ((,class (:foreground ,organic-orange :weight normal))))

       ;; ui
       `(cursor ((,class (:background ,organic-cursor-fg))))
       `(fringe ((,class (:background ,organic-highlight-gray :foreground ,organic-gray))))
       ;; TODO:
       `(vertical-border ((,class (:foreground ,organic-medium-gray))))
       `(minibuffer-prompt ((,class (:foreground ,organic-blue :weight bold))))
       `(mode-line ((,class :background ,organic-dark-white :foreground ,organic-dark-black)))
       `(mode-line-inactive ((,class :background ,organic-shadow :foreground ,organic-dark-black)))
       `(link ((,class (:underline t :foreground ,organic-blue))))
       `(link-visited ((,class (:underline t :foreground ,organic-blue))))
       `(highlight ((,class (:background ,organic-highlight-green))))
       `(hl-line ((,class (:background ,organic-cursor-bg :inverse-video nil))))
       `(region ((,class (:background ,organic-highlight-yellow))))
       `(lazy-highlight ((,class (:background ,organic-highlight-green :inverse-video nil))))
       `(isearch ((,class (:foreground ,organic-fg :background ,organic-marker-yellow :inverse-video nil))))
       `(cua-rectangle ((,class (:background ,organic-marker-green))))
       `(secondary-selection ((,class (:background ,organic-marker-blue))))
       `(trailing-whitespace ((,class (:background ,organic-red))))

       ;; external packages
       ;; Tabbar
       `(tabbar-default ((t (:inherit variable-pitch
                             :height 0.8
                             :foreground ,organic-green-black
                             :background ,organic-highlight-gray))))
       `(tabbar-button ((t (:inherit tabbar-default
                            :background ,organic-shadow))))
       `(tabbar-modified ((t (:inherit tabbar-button
                              :foreground ,organic-green
                              :bold t))))
       `(tabbar-unselected ((t (:inherit tabbar-button))))
       `(tabbar-selected ((t (:inherit tabbar-button
                              :foreground ,organic-green-black
                              :background ,organic-bg
                              :bold t))))
       '(tabbar-selected-modified ((t :inherit tabbar-selected)))

       ;; Jabber
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

       ;; LaTeX
       `(font-latex-bold-face ((t (:bold t :foreground ,organic-purple))))
       `(font-latex-italic-face ((t (:italic t :foreground ,organic-blue))))
       `(font-latex-math-face ((t (:foreground ,organic-sun))))
       `(font-latex-sedate-face ((t (:foreground ,organic-dark-gray))))
       '(font-latex-string-face ((t (:inherit font-lock-string-face))))
       `(font-latex-warning-face ((t (:foreground ,organic-orange))))

       ;; Quack
       `(quack-pltish-paren-face ((t (:foreground ,organic-yellow))))
       '(quack-pltish-keyword-face ((t (:inheit font-lock-keyword-face))))

       ;; js2-mode
       `(js2-external-variable ((t (:inherit warning))))
       `(js2-function-param ((t (:foreground ,organic-teal))))
       `(js2-jsdoc-type ((t (:foreground ,organic-blue))))
       `(js2-jsdoc-tag ((t (:foreground ,organic-blue))))
       `(js2-jsdoc-value ((t (:foreground ,organic-teal))))

       ;; clojure/CIDER
       `(cider-result-overlay-face ((t (:background ,organic-bg :box (:line-width -1 :color ,organic-yellow)))))

       ;; Java
       '(jdee-java-properties-font-lock-comment-face ((t (:inherit font-lock-comment-face))))
       `(jdee-java-properties-font-lock-equal-face ((t (:foreground ,organic-blue))))
       '(jdee-java-properties-font-lock-substitution-face ((t (:inherit font-lock-function-name-face :bold nil))))
       '(jdee-java-properties-font-lock-class-name-face ((t (:inherit font-lock-constant-face :bold nil))))
       '(jdee-java-properties-font-lock-value-face ((t (:inherit font-lock-string-face :bold nil))))
       `(jdee-java-properties-font-lock-backslash-face ((t (:foreground ,organic-sun))))

       ;; Scala
       `(scala-font-lock:var-face ((t (:foreground ,organic-orange))))

       ;; Lsp
       `(lsp-ui-doc-border ((t (:background ,organic-gray))))
       `(lsp-ui-doc-background ((t (:background ,organic-highlight-green))))
       `(lsp-ui-sideline-code-action ((t (:background ,organic-highlight-green :foreground ,organic-gray))))

       ;; Tcl
       `(tcl-substitution-char-face ((t (:foreground ,organic-teal))))

       ;; Erc
       `(erc-action-face ((t (:foreground ,organic-gray :weight bold))))
       `(erc-command-indicator-face ((t (:foreground ,organic-dark-gray :weight bold))))
       `(erc-nick-default-face ((t (:foreground ,organic-purple :weight bold))))
       `(erc-input-face ((t (:foreground ,organic-blue))))
       `(erc-notice-face ((t (:foreground ,organic-green :weight bold))))
       `(erc-timestamp-face ((t (:foreground ,organic-green :weight bold))))

       ;; Circe
       `(circe-server-face ((t (:foreground ,organic-green))))
       `(circe-prompt-face ((t (:foreground ,organic-dark-gray :weight bold))))
       `(circe-highlight-nick-face ((t (:foreground ,organic-orange))))
       `(lui-time-stamp-face ((t (:foreground ,organic-green))))

       ;; Markdown
       `(markdown-pre-face ((t (:foreground ,organic-green-black :family ,(face-attribute 'default :family)))))
       `(markdown-markup-face ((t (:foreground ,organic-green-black :family ,(face-attribute 'default :family)))))
       `(markdown-language-keyword-face ((t (:foreground ,organic-green :family ,(face-attribute 'default :family)))))
       `(markdown-code-face ((t (:foreground ,organic-green :family ,(face-attribute 'default :family)))))

       ;; Rst
       '(rst-definition ((t (:inherit font-lock-constant-face))) t)
       `(rst-level-1 ((t (:background ,organic-purple))) t)
       `(rst-level-2 ((t (:background ,organic-blue))))
       `(rst-level-3 ((t (:background ,organic-yellow))))
       `(rst-level-4 ((t (:background ,organic-green))))
       `(rst-level-5 ((t (:background ,organic-sun))))
       `(rst-level-6 ((t (:background ,organic-orange))))
       '(rst-block ((t (:inherit font-lock-function-name-face :bold t))) t)
       '(rst-external ((t (:inherit font-lock-constant-face))) t)
       '(rst-directive ((t (:inheit font-lock-builtin-face))) t)
       '(rst-literal ((t (:inheit font-lock-string-face))))
       '(rst-emphasis1 ((t (:inherit italic))) t)
       `(rst-adornment ((t (:bold t :foreground ,organic-blue))))

       ;; Whitespace-Mode
       `(whitespace-empty ((t (:background ,organic-bg :foreground ,organic-light-gray))) t)
       `(whitespace-indentation ((t (:background ,organic-bg :foreground ,organic-light-gray))) t)
       `(whitespace-newline ((t (:background ,organic-bg :foreground ,organic-light-gray))) t)
       `(whitespace-space-after-tab ((t (:background ,organic-bg :foreground ,organic-light-gray))) t)
       `(whitespace-tab ((t (:background ,organic-bg :foreground ,organic-light-gray))) t)
       `(whitespace-hspace ((t (:background ,organic-bg :foreground ,organic-light-gray))) t)
       `(whitespace-line ((t (:background ,organic-bg :foreground ,organic-light-gray))) t)
       `(whitespace-space ((t (:background ,organic-bg :foreground ,organic-light-gray))) t)
       `(whitespace-space-before-tab ((t (:background ,organic-bg :foreground ,organic-light-gray))) t)
       `(whitespace-trailing ((t (:background ,organic-bg :foreground ,organic-red))) t)

       ;; Log4j
       '(log4j-font-lock-warn-face ((t (:inherit warning))))

       ;; sh-mode
       '(sh-heredoc ((t (:inherit font-lock-string-face))))
       '(sh-quoted-exec ((t (:inherit font-lock-constant-face))))

       ;; Ace-Jump
       `(ace-jump-face-foreground ((t (:background ,organic-marker-yellow :underline nil))) t)
       `(ace-jump-face-background ((t (:foreground ,organic-dark-gray :underline nil))) t)

       ;; Diff
       `(diff-indicator-added ((t (:foreground ,organic-green)) t))
       `(diff-added ((t (:foreground ,organic-green)) t))
       `(diff-indicator-removed ((t (:foreground ,organic-red))) t)
       `(diff-removed ((t (:foreground ,organic-red))) T)

       ;; Magit
       `(magit-diff-add ((t (:foreground ,organic-green)) t))
       `(magit-diff-del ((t (:foreground ,organic-red))) t)
       `(magit-diff-added ((t (:foreground ,organic-green :background ,organic-bg))) t)
       `(magit-diff-removed ((t (:foreground ,organic-sign-delete :background ,organic-bg))) t)
       `(magit-diff-added-highlight ((t (:foreground ,organic-green :background ,organic-cursor-bg))) t)
       `(magit-diff-removed-highlight ((t (:foreground ,organic-sign-delete :background ,organic-cursor-bg))) t)
       `(magit-diff-context-highlight ((t (:foreground ,organic-green-black :background ,organic-cursor-bg))) t)
       `(magit-diff-file-heading-highlight ((t (:background ,organic-cursor-bg))) t)
       `(magit-item-highlight ((t (:background ,organic-highlight-gray))) t)
       `(magit-log-author ((t (:foreground ,organic-sun))) t)
       `(magit-popup-argument ((t (:foreground ,organic-blue))) t)
       `(magit-process-ok ((t (:foreground ,organic-green))) t)
       `(magit-section-highlight ((t (:background ,organic-cursor-bg))) t)
       `(magit-branch-remote ((t (:foreground ,organic-yellow))) t)
       `(magit-section-heading ((t (:bold nil :foreground ,organic-purple))) t)
       `(magit-branch-local ((t (:foreground ,organic-yellow))) t)
       `(magit-tag ((t (:foreground ,organic-sun))) t)
       `(git-commit-summary ((t (:foreground ,organic-teal))) t)

       ;; Git-Gutter
       `(git-gutter:added ((t (:foreground ,organic-green)) t))
       `(git-gutter:deleted ((t (:foreground ,organic-red))) t)
       `(git-gutter:modified ((t (:foreground ,organic-blue))) t)
       `(git-gutter-fr:added ((t (:foreground ,organic-sign-add :background ,organic-sign-add)) t))
       `(git-gutter-fr:deleted ((t (:foreground ,organic-sign-delete :background ,organic-sign-delete))) t)
       `(git-gutter-fr:modified ((t (:foreground ,organic-sign-change :background ,organic-sign-change))) t)

       ;; Org-Mode
       `(org-table ((t (:foreground ,organic-teal))) t)
       `(org-level-1 ((t (:foreground ,organic-purple :weight normal))) t)
       `(org-level-2 ((t (:foreground ,organic-blue :weight normal))) t)
       `(org-level-3 ((t (:foreground ,organic-yellow :weight normal))) t)
       `(org-level-4 ((t (:foreground ,organic-green :weight normal))) t)
       `(org-level-5 ((t (:foreground ,organic-sun :weight normal))) t)
       `(org-level-6 ((t (:foreground ,organic-orange :weight normal))) t)
       `(org-block ((,class (:foreground ,organic-fg))))
       `(org-block-begin-line ((t (:foreground ,organic-blue))) t)
       `(org-block-end-line ((t (:foreground ,organic-blue))) t)
       `(org-done ((t (:inherit success))) t)
       `(org-todo ((t (:inherit warning))) t)

       ;; Misc
       `(nxml-element-local-name ((t (:foreground ,organic-blue :weight normal))) t)
       `(yas-field-highlight-face ((t (:background ,organic-yellow))))
       `(idle-highlight ((t (:background ,organic-highlight-green))) t)
       `(comint-highlight-prompt ((t (:foreground ,organic-blue))) t)
       `(flx-highlight-face  ((t (:foreground ,organic-blue :bold t :underline t))) t)

       ;; Powerline
       `(powerline-active1 ((t (:background ,organic-light-gray :inherit mode-line))) t)
       `(powerline-active2 ((t (:background ,organic-dark-white :inherit mode-line))) t)
       `(powerline-inactive1  ((t (:background ,organic-light-white :inherit mode-line-inactive))) t)
       `(powerline-inactive2  ((t (:background ,organic-light-white :inherit mode-line-inactive))) t)

       ;; Company
       `(company-tooltip ((t :foreground ,organic-dark-gray :background ,organic-light-white)))
       `(company-tooltip-annotation ((t :foreground ,organic-fg)))
       `(company-tooltip-common ((t :foreground ,organic-blue)))
       `(company-tooltip-search ((t :background ,organic-yellow)))
       `(company-tooltip-search-selection ((t :background ,organic-yellow)))
       `(company-echo-common ((t :foreground ,organic-violet)))
       `(company-tooltip-scrollbar-thumb ((t :background ,organic-dark-gray)))
       `(company-tooltip-scrollbar-track ((t :background ,organic-dark-white)))

       ;; Web-Mode
       `(web-mode-current-element-highlight-face ((,class (:background ,organic-highlight-green))))
       `(web-mode-html-tag-face ((t (:foreground ,organic-black))) t)
       `(web-mode-html-attr-name-face ((t (:foreground ,organic-blue))) t)
       `(web-mode-doctype-face ((t (:foreground ,organic-blue))) t)
       `(web-mode-comment-face ((t (:foreground ,organic-gray)) t))
       `(web-mode-css-selector-face ((t (:foreground ,organic-teal))) t)
       `(web-mode-function-call-face ((t (:foreground ,organic-fg))) t)
       `(web-mode-function-name-face ((t :inherit font-lock-function-name-face)))

       `(eldoc-highlight-function-argument
         ((t (:foreground ,organic-green :weight bold))) t)

       `(table-cell ((t (:foreground ,organic-fg :background ,organic-highlight-green))) t)

       ;; Dired
       `(diredp-dir-heading ((t (:background ,organic-green))))
       `(diredp-dir-name ((t (:foreground ,organic-black))))
       `(diredp-file-name ((t (:foreground ,organic-fg))))
       `(diredp-file-suffix ((t (:foreground ,organic-teal))))

       ;; Dired+
       `(diredp-compressed-file-suffix ((t (:foreground ,organic-orange))))

       ;;Highlight pair parentheses
       `(show-paren-match ((t (:background ,organic-highlight-yellow))))
       `(show-paren-mismatch ((t (:background ,organic-marker-red))))

       ;; Rainbow-Delimiters
       ;; (1 (2 (3 (4 (5 (6 (7 (8 (9 (10 (11 (12))))))))))))
       `(rainbow-delimiters-depth-1-face ((t (:foreground ,organic-medium-gray :background ,organic-bg))))
       `(rainbow-delimiters-depth-2-face ((t (:foreground ,organic-violet :background ,organic-bg))))
       `(rainbow-delimiters-depth-3-face ((t (:foreground ,organic-blue :background ,organic-bg))))
       `(rainbow-delimiters-depth-4-face ((t (:foreground ,organic-teal :background ,organic-bg))))
       `(rainbow-delimiters-depth-5-face ((t (:foreground ,organic-green :background ,organic-bg))))
       `(rainbow-delimiters-depth-6-face ((t (:foreground ,organic-sun :background ,organic-bg))))
       `(rainbow-delimiters-depth-7-face ((t (:foreground ,organic-yellow :background ,organic-bg))))
       `(rainbow-delimiters-depth-8-face ((t (:foreground ,organic-orange :background ,organic-bg))))
       `(rainbow-delimiters-depth-9-face ((t (:foreground ,organic-magenta :background ,organic-bg))))
       `(rainbow-delimiters-base-error-face ((t (:foreground ,organic-red)))))

      (custom-set-faces
       ;; Multi-Magit
       `(multi-magit-repo-heading ((t (:inherit magit-section-heading :box nil))))

       ;; Speedbar
       `(speedbar-selected-face ((t (:foreground ,organic-green :underline t))))

       ;; fill-column-indicator for `emacs-major-version' >= 27
       `(fill-column-indicator ((t (:foreground ,organic-dark-white :weight normal)))))

      (custom-theme-set-variables
       'organic-green

       ;; marker
       `(highlight-symbol-colors
         '(,organic-marker-yellow
           ,organic-marker-green
           ,organic-marker-teal
           ,organic-marker-blue
           ,organic-marker-violet
           ,organic-marker-purple
           ,organic-marker-pink
           ,organic-marker-red
           ,organic-marker-orange))

       ;; org-mode code blocks
       `(org-src-block-faces '(("emacs-lisp" (:background ,organic-bg))
                               ("dot" (:foreground ,organic-dark-gray))))))

  ;;-------------------------------------------------------------------
  ;; version 1
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
                             ("dot" (:foreground ,organic-gray-4)))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'organic-green)
;;; organic-green-theme.el ends here
