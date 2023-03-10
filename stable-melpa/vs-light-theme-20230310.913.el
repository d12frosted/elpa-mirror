;;; vs-light-theme.el --- Visual Studio IDE light theme

;; Copyright (C) 2019-2023 , Jen-Chieh Shen

;; Author: Jen-Chieh Shen
;; URL: https://github.com/emacs-vs/vs-light-theme
;; Package-Version: 20230310.913
;; Package-Commit: 5accd5c1e4581005a0859cf7d85b0191b6b7a30b
;; Version: 1.0
;; Package-Requires: ((emacs "24.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Visual Studio IDE light theme.
;;

;;; Code:

(deftheme vs-light
  "Visual Studio IDE light theme.")

(custom-theme-set-faces
 'vs-light
 `(default                      ((t (:background "#ffffff" :foreground "#000000"))))
 `(font-lock-builtin-face       ((t (:foreground "#0C6EEF"))))
 `(font-lock-comment-face       ((t (:foreground "olive drab"))))
 `(font-lock-negation-char-face ((t (:foreground "#2B91AF"))))
 `(font-lock-reference-face     ((t (:foreground "#2B91AF"))))
 `(font-lock-constant-face      ((t (:foreground "#2B91AF"))))
 `(font-lock-doc-face           ((t (:foreground "olive drab"))))
 `(font-lock-function-name-face ((t (:foreground "#74534B"))))
 `(font-lock-keyword-face       ((t (:foreground "#0000FF"))))
 `(font-lock-preprocessor-face  ((t (:foreground "#808080"))))
 `(font-lock-string-face        ((t (:foreground "#B21515"))))
 `(font-lock-type-face          ((t (:foreground "#2B91AF"))))
 `(font-lock-variable-name-face ((t (:foreground "#000000"))))

 `(line-number ((t (:background "#EEEEEE" , :foreground "#2B91AF"))))
 `(cursor      ((t :background "#909090")))
 `(hl-line     ((t :background "#E6E6E6")))
 `(region      ((t :background "#99C9EF")))
 `(fringe      ((t :background "#E6E7E8")))

 `(completions-common-part ((t :foreground "#223fbf" :weight bold)))

 `(highlight ((t :background "#99C9EF")))

 `(fill-column-indicator ((t :foreground "#AA4242")))

 `(show-paren-match ((t :box (:line-width (-1 . -1) :style released-button :color "#A4A4A4"))))

 `(highlight-indent-guides-odd-face             ((t :foreground "#D0D0D0")))
 `(highlight-indent-guides-even-face            ((t :foreground "#D0D0D0")))
 `(highlight-indent-guides-character-face       ((t :foreground "#D0D0D0")))
 `(highlight-indent-guides-top-odd-face         ((t :foreground "#D0D0D0")))
 `(highlight-indent-guides-top-even-face        ((t :foreground "#D0D0D0")))
 `(highlight-indent-guides-top-character-face   ((t :foreground "#D0D0D0")))
 `(highlight-indent-guides-stack-odd-face       ((t :foreground "#D0D0D0")))
 `(highlight-indent-guides-stack-even-face      ((t :foreground "#D0D0D0")))
 `(highlight-indent-guides-stack-character-face ((t :foreground "#D0D0D0")))

 `(highlight-doxygen-comment    ((t :background "#ffffff")))
 `(highlight-doxygen-code-block ((t :background "grey85")))
 `(highlight-doxygen-command    ((t :foreground "SlateGray")))
 `(highlight-doxygen-type       ((t :foreground "SteelBlue")))
 `(highlight-doxygen-variable   ((t :foreground "gold4")))

 `(tree-sitter-hl-face:tag                 ((t :foreground "#800000")))
 `(tree-sitter-hl-face:type.builtin        ((t :foreground "#0000FF")))
 `(tree-sitter-hl-face:type                ((t :foreground "#2B91AF")))
 `(tree-sitter-hl-face:function            ((t :foreground "black")))
 `(tree-sitter-hl-face:function.call       ((t :foreground "black")))
 `(tree-sitter-hl-face:variable.parameter  ((t :foreground "#808080")))
 `(tree-sitter-hl-face:property            ((t :foreground "#2F4F4F")))
 `(tree-sitter-hl-face:property.definition ((t :foreground "#2F4F4F")))
 `(tree-sitter-hl-face:punctuation         ((t :foreground "#020000")))
 `(tree-sitter-hl-face:operator            ((t :foreground "#020000")))
 `(tree-sitter-hl-face:number              ((t :foreground "black")))
 `(tree-sitter-hl-face:constant            ((t :foreground "#6F008A")))
 `(tree-sitter-hl-face:constant.builtin    ((t :foreground "#0000FF")))
 `(tree-sitter-hl-face:keyword             ((t :foreground "#0000FF")))
 `(tree-sitter-hl-face:variable            ((t :foreground "#000000")))
 `(tree-sitter-hl-face:variable.special    ((t :foreground "#6F008A")))
 `(tree-sitter-hl-face:function.macro      ((t :foreground "#808080")))
 `(tree-sitter-hl-face:function.special    ((t :foreground "#808080")))

 `(company-tooltip-annotation       ((t :foreground "#41474D")))
 `(company-fuzzy-annotation-face    ((t :foreground "#5E85AB")))
 `(company-preview                  ((t :foreground "dark gray" :underline t)))
 `(company-preview-common           ((t (:inherit company-preview))))
 `(company-tooltip                  ((t :background "#F5F5F5" :foreground "black")))
 `(company-tooltip-selection        ((t :background "#D6EBFF" :foreground "black")))
 `(company-tooltip-common           ((((type x)) (:inherit company-tooltip :weight bold))
                                     (t (:background "#F5F5F5" :foreground "#0066BF"))))
 `(company-tooltip-common-selection ((((type x)) (:inherit company-tooltip-selection :weight bold))
                                     (t (:background "#D6EBFF" :foreground "#0066BF"))))
 `(company-scrollbar-bg             ((t :background "#F5F5F5")))
 `(company-scrollbar-fg             ((t :background "#C2C3C9")))

 `(popup-tip-face ((t :background "#E9EAED" :foreground "#1E1E1E")))

 `(flx-highlight-face ((t :foreground "#223fbf" :weight bold)))

 `(ahs-plugin-default-face           ((t :background "#E2E6D6" :box (:line-width (-1 . -1) :style pressed-button :color "#525D68"))))
 `(ahs-plugin-default-face-unfocused ((t :background "#F1F2EE" :box (:line-width (-1 . -1) :style pressed-button :color "#525D68"))))
 `(ahs-face                          ((t :background "#E2E6D6" :box (:line-width (-1 . -1) :style pressed-button :color "#525D68"))))
 `(ahs-definition-face               ((t :background "#E2E6D6" :box (:line-width (-1 . -1) :style pressed-button :color "#525D68"))))
 `(ahs-face-unfocused                ((t :background "#F1F2EE" :box (:line-width (-1 . -1) :style pressed-button :color "#525D68"))))
 `(ahs-definition-face-unfocused     ((t :background "#F1F2EE" :box (:line-width (-1 . -1) :style pressed-button :color "#525D68"))))

 `(centaur-tabs-display-line               ((t :background "#D3D3D3" :box nil :overline nil :underline nil)))
 `(centaur-tabs-default                    ((t :background "#D3D3D3")))
 `(centaur-tabs-unselected                 ((t :background "#E8E8E8" :foreground "grey50")))
 `(centaur-tabs-selected                   ((t :background "#E8E8E8" :foreground "black")))
 `(centaur-tabs-unselected-modified        ((t :background "#E8E8E8" :foreground "grey50")))
 `(centaur-tabs-selected-modified          ((t :background "#E8E8E8" :foreground "black")))
 `(centaur-tabs-modified-marker-unselected ((t :background "#E8E8E8" :foreground "grey50")))
 `(centaur-tabs-modified-marker-selected   ((t :background "#E8E8E8" :foreground "black")))

 `(dashboard-text-banner       ((t :foreground "black")))
 `(dashboard-banner-logo-title ((t :foreground "#616161")))
 `(dashboard-heading           ((t :foreground "#727272")))
 `(dashboard-items-face        ((t :foreground "#1475B7")))

 `(yascroll:thumb-fringe    ((t :background "#C2C3C9" :foreground "#C2C3C9")))
 `(yascroll:thumb-text-area ((t :background "#C2C3C9" :foreground "#C2C3C9")))

 `(region-occurrences-highlighter-face ((t :background "#113D6F")))

 `(whitespace-indentation ((t :background "grey20" :foreground "aquamarine3")))
 `(whitespace-trailing    ((t :background "grey20" :foreground "red")))

 `(highlight-numbers-number ((t :foreground "#9BCEA3")))

 `(modablist-select-face ((t :box (:line-width (-1 . -1) :color "#65A7E2" :style nil))))
 `(modablist-insert-face ((t :background "#565136" :box (:line-width (-1 . -1) :color "#65A7E2" :style nil))))

 `(ts-fold-replacement-face ((t :foreground "#808080" :box (:line-width (-1 . -1) :style pressed-button))))

 `(rjsx-tag              ((t (:foreground "#87CEFA"))))
 `(rjsx-attr             ((t (:foreground "#EEDD82"))))
 `(rjsx-text             ((t (:inherit default))))
 `(rjsx-tag-bracket-face ((t (:inherit web-mode-html-attr-name-face))))

 `(markdown-markup-face           ((t :foreground "#7EA728" :background "#ffffff")))
 `(markdown-code-face             ((t :foreground "#D2D2D2" :background "#2B2B2B" :extend t :inherit nil)))
 `(markdown-list-face             ((t :foreground "gold3")))
 `(markdown-table-face            ((t :foreground "#87CEFA" :background "#ffffff")))
 `(markdown-header-face           ((t :foreground "#B5CCEB" :background "#ffffff")))
 `(markdown-header-delimiter-face ((t :foreground "#B5CCEB" :background "#ffffff")))
 `(markdown-metadata-key-face     ((t :foreground "#0000FF")))
 `(markdown-metadata-value-face   ((t :foreground "#D2D2D2")))

 `(org-block   ((t :foreground "#000000" :background "#2B2B2B" :extend t :inherit nil)))
 `(org-level-1 ((t :foreground "#4ec9b0")))
 `(org-level-2 ((t :foreground "#9cdcfe")))
 `(org-level-3 ((t :foreground "#569cd6")))
 `(org-level-4 ((t :foreground "#dcdcaa")))
 `(org-level-5 ((t :foreground "#c586c0")))
 `(org-level-6 ((t :foreground "#ce9178")))
 `(org-level-7 ((t :foreground "#d7ba7d")))
 `(org-level-8 ((t :foreground "#d16969")))

 `(web-mode-doctype-face            ((t :foreground "Pink3")))
 `(web-mode-comment-face            ((t :foreground "olive drab")))
 `(web-mode-block-comment-face      ((t :foreground "olive drab")))
 `(web-mode-html-tag-bracket-face   ((t :foreground "#800052")))
 `(web-mode-html-tag-face           ((t :foreground "#800000")))
 `(web-mode-html-attr-name-face     ((t :foreground "#FF0000")))
 `(web-mode-html-attr-equal-face    ((t :foreground "#000000")))
 `(web-mode-html-attr-value-face    ((t :foreground "#0000FF")))
 `(web-mode-css-selector-tag-face   ((t :foreground "#88004A")))
 `(web-mode-css-selector-class-face ((t :foreground "#80004A")))
 `(web-mode-css-property-name-face  ((t :foreground "#FF0000")))

 `(define-it-pop-tip-color ((t :background "#E9EAED")))

 `(preview-it-background ((t :background "#E9EAED")))
 )

(custom-theme-set-variables
 'vs-light
 ;; coverlay overlays
 `(coverlay:tested-line-background-color   "#E1FFE1")
 `(coverlay:untested-line-background-color "LavenderBlush"))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

;;;###autoload
(defun vs-light-theme ()
  "Load Visual Studio light theme."
  (interactive)
  (load-theme 'vs-light t))

(provide-theme 'vs-light)

(provide 'vs-light-theme)
;;; vs-light-theme.el ends here
