;;; prassee-theme.el --- A high contrast color theme for Emacs.

;; Copyright (c) 2017 Prassee

;; Author: Prassee  <prassee.sathian@gmail.com>
;; Keywords: dark high-contrast  faces
;; Package-Version: 20180709.1004
;; Package-Commit: 81126f69cdbaab836c00ae7a49aaf89d4229fde1
;; URL: https://github.com/prassee/prassee-emacs-theme
;; Package-Requires: ((emacs "24"))
;; Version: 1.2

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Fdoundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(deftheme prassee
  "A dark theme for emacs and compatible with most programming modes")

(let ((c '((class color) (min-colors 89)))
      (black          "#181e26")
      (white          "#DFDFDF")
      (grey           (if window-system "#5B6268" "#525252"))
      (greenr         "green")
      (green-c        "#65737E")
      (grey-c         "#3d4451")
      (grey-d         "#3D3D48")
      (grey-dd        "#404850")
      (yellow         "#ECBE7B")
      (yellow-d       "#CDB464")
      (orange         "#da8548")
      (red            "#ff6c6b")
      (magenta        "#c678dd")
      (violet         "#a9a1e1")
      (cyanr          "cyan")
      (cyan           "#46D9FF")
      (cyan-d         "#5699AF")
      (teal           "#4db5bd")
      (blue           "#51afef")
      (blue-d         "#1f5582")
      (green          "#98be65"))

  (let* (
         (bg             "#002b36")
         (bg-d           "#002a36")
         (bg-dd          "#0087af")
         (fg             "#bbc2cf")
         (highlight      grey-c)
         (chighlight     grey-c)
         (vertical-bar   black)
         (current-line   (if window-system "#23272e" "#262626"))
         (selection      highlight)
         (builtin        magenta)
         (comments       green-c)
         (constants      violet)
         (functions      magenta)
         (keywords       blue)
         (methods        cyan)
         (operators      blue)
         (type           yellow)
         (strings        green)
         (variables      white)
         (numbers        orange)
         (region         "#3d4451")

         ;; tabs
         (tab-unfocused-bg "#353a42")
         (tab-unfocused-fg "#1e2022")

         ;; main search regions
         (search-bg      blue)
         (search-fg      black)

         ;; other search regions
         (search-rest-bg grey-d)
         (search-rest-fg blue)

         ;; mode line
         (modeline-fg    grey)
         (modeline-fg-l  blue)
         (modeline-bg    (if window-system bg-d current-line))
         (modeline-bg-l  (if window-system blue current-line))
         (modeline-fg-inactive white)
         (modeline-bg-inactive grey)

         ;; vcs
         (vc-modified    yellow-d)
         (vc-added       green)
         (vc-deleted     red))

    (custom-theme-set-faces
     'prassee

     ;; Global
     `(default                ((,c (:background ,bg :foreground ,fg))))
     `(fringe                 ((,c (:inherit default :foreground ,comments))))
     `(region                 ((,c (:background ,region))))
     `(highlight              ((,c (:background ,teal :foreground ,black))))
     `(hl-line                ((,c (:background ,bg))))
     `(cursor                 ((,c (:background ,greenr))))
     `(shadow                 ((,c (:foreground ,grey))))
     `(minibuffer-prompt      ((,c (:foreground ,blue))))
     `(tooltip                ((,c (:background ,black :foreground ,fg))))
     `(error                  ((,c (:foreground ,orange))))
     `(warning                ((,c (:foreground ,yellow))))
     `(success                ((,c (:foreground ,green))))
     `(secondary-selection    ((,c (:background ,blue :foreground ,black))))
     `(lazy-highlight         ((,c (:background ,blue-d :foreground ,white))))
     `(match                  ((,c (:foreground ,green :background ,black ))))
     `(trailing-whitespace    ((,c (:background ,comments))))
     `(vertical-border        ((,c (:foreground ,teal :background ,white))))
     `(show-paren-match       ((,c (:foreground ,black :background ,teal ))))
     `(show-paren-mismatch    ((,c (:foreground ,black :background ,red ))))
     `(linum
       ((((type graphic)) :background ,bg :foreground ,cyanr)
        (t                :background ,bg :foreground ,cyanr)))
     `(font-lock-builtin-face           ((,c (:foreground ,builtin))))
     `(font-lock-comment-face           ((,c (:foreground ,comments))))
     `(font-lock-comment-delimiter-face ((,c (:foreground ,comments))))
     `(font-lock-doc-face               ((,c (:foreground ,comments))))
     `(font-lock-doc-string-face        ((,c (:foreground ,comments))))
     `(font-lock-constant-face          ((,c (:foreground ,constants))))
     `(font-lock-function-name-face     ((,c (:foreground ,functions))))
     `(font-lock-keyword-face           ((,c (:foreground ,keywords))))
     `(font-lock-string-face            ((,c (:foreground ,strings))))
     `(font-lock-type-face              ((,c (:foreground ,type))))
     `(font-lock-variable-name-face     ((,c (:foreground ,variables))))
     `(font-lock-warning-face           ((,c (:inherit warning))))
     `(font-lock-negation-char-face          ((,c (:foreground ,operators ))))
     `(font-lock-preprocessor-face           ((,c (:foreground ,operators ))))
     `(font-lock-preprocessor-char-face      ((,c (:foreground ,operators ))))
     `(font-lock-regexp-grouping-backslash   ((,c (:foreground ,operators ))))
     `(font-lock-regexp-grouping-construct   ((,c (:foreground ,operators ))))
  
     ;; Dired/dired-k
     `(dired-directory             ((,c (:foreground ,orange))))
     `(dired-ignored               ((,c (:foreground ,comments))))
     `(dired-k-directory           ((,c (:foreground ,blue))))

     ;; Search
     `(isearch                     ((,c (:background ,search-bg :foreground ,black ))))
     `(isearch-lazy-highlight-face ((,c (:background ,search-rest-bg))))
     `(yas-field-highlight-face    ((,c (:inherit match))))

     ;; `window-divider'
     `(window-divider              ((,c (:foreground ,vertical-bar))))
     `(window-divider-first-pixel  ((,c (:foreground ,vertical-bar))))
     `(window-divider-last-pixel   ((,c (:foreground ,vertical-bar))))

     ;;
     ;; Plugins
     ;;

     ;; company-mode
     `(company-tooltip             ((,c (:inherit tooltip))))
     `(company-tooltip-common      ((,c (:foreground ,blue))))
     `(company-tooltip-search      ((,c (:foreground ,search-fg :background ,highlight))))
     `(company-tooltip-selection   ((,c (:background ,selection))))
     `(company-tooltip-mouse       ((,c (:background ,magenta :foreground ,bg))))
     `(company-tooltip-annotation  ((,c (:foreground ,violet))))
     `(company-scrollbar-bg        ((,c (:background ,black))))
     `(company-scrollbar-fg        ((,c (:background ,blue))))
     `(company-preview             ((,c (:foreground ,blue))))
     `(company-preview-common      ((,c (:foreground ,magenta :background ,grey-d))))
     `(company-preview-search      ((,c (:inherit company-tooltip-search))))

     ;; diff-hl
     `(diff-hl-change              ((,c (:foreground ,vc-modified))))
     `(diff-hl-delete              ((,c (:foreground ,vc-deleted))))
     `(diff-hl-insert              ((,c (:foreground ,vc-added))))

     ;; elscreen
     `(elscreen-tab-background-face     ((,c (:background ,bg-d))))
     `(elscreen-tab-control-face        ((,c (:background ,bg-d :foreground ,bg-d))))
     `(elscreen-tab-current-screen-face ((,c (:background ,bg :foreground ,fg))))
     `(elscreen-tab-other-screen-face   ((,c (:background ,tab-unfocused-bg :foreground ,tab-unfocused-fg))))

     ;; flycheck
     `(flycheck-error     ((,c (:underline (:style wave :color ,red)))))
     `(flycheck-warning   ((,c (:underline (:style wave :color ,yellow)))))
     `(flycheck-info      ((,c (:underline (:style wave :color ,green)))))
     `(flyspell-incorrect ((,c (:underline (:style wave :color ,red) :inherit unspecified))))

     ;; git-gutter
     `(git-gutter:modified         ((,c (:foreground ,vc-modified))))
     `(git-gutter:added            ((,c (:foreground ,vc-added))))
     `(git-gutter:deleted          ((,c (:foreground ,vc-deleted))))
     `(git-gutter-fr:modified      ((,c (:foreground ,vc-modified))))
     `(git-gutter-fr:added         ((,c (:foreground ,vc-added))))
     `(git-gutter-fr:deleted       ((,c (:foreground ,vc-deleted))))
     `(git-gutter+-modified        ((,c (:foreground ,vc-modified))))
     `(git-gutter+-added           ((,c (:foreground ,vc-added))))
     `(git-gutter+-deleted         ((,c (:foreground ,vc-deleted))))

     ;; Helm
     `(helm-selection              ((,c (:background ,teal :foreground ,bg))))
     `(helm-match                  ((,c (:foreground ,orange :underline t :bold t))))
     `(helm-source-header          ((,c (:background ,orange :foreground ,black :weight bold ))))
     `(helm-swoop-target-line-face ((,c (:foreground ,highlight :inverse-video t))))
     `(helm-ff-file                ((,c (:foreground ,fg))))
     `(helm-ff-prefix              ((,c (:foreground ,white))))
     `(helm-ff-dotted-directory    ((,c (:foreground ,cyan-d :weight bold))))
     `(helm-ff-directory           ((,c (:foreground ,orange :weight bold))))
     `(helm-ff-executable          ((,c (:foreground ,white ))))

     ;; indent-guide, highlight-{quoted,numbers,indentation}-mode
     `(indent-guide-face                         ((,c (:foreground ,green))))
     `(highlight-indentation-face                ((,c (:background ,green))))
     `(highlight-indentation-current-column-face ((,c (:background ,green))))
     `(highlight-indentation-guides-odd-face     ((,c (:background ,teal))))
     `(highlight-indentation-guides-even-face    ((,c (:background ,green))))
     `(highlight-quoted-symbol                   ((,c (:foreground ,type))))
     `(highlight-quoted-quote                    ((,c (:foreground ,operators))))
     `(highlight-numbers-number                  ((,c (:foreground ,numbers))))

     ;; neotree
     `(neo-root-dir-face           ((,c (:foreground ,green :background ,bg :box (:line-width 4 :color ,bg)))))
     `(neo-file-link-face          ((,c (:foreground ,fg))))
     `(neo-dir-link-face           ((,c (:foreground ,blue))))
     `(neo-expand-btn-face         ((,c (:foreground ,blue))))

     ;; pos-tip
     `(popup                       ((,c (:inherit tooltip))))
     `(popup-tip-face              ((,c (:inherit tooltip))))

     ;; stripe-buffer
     `(stripe-highlight            ((,c (:background ,bg))))

     ;; Volatile highlights
     `(vhl/default-face            ((,c (:background ,grey-d))))

     ;; Rainbow delimiters
     `(rainbow-delimiters-depth-1-face   ((,c (:foreground ,blue))))
     `(rainbow-delimiters-depth-2-face   ((,c (:foreground ,magenta))))
     `(rainbow-delimiters-depth-3-face   ((,c (:foreground ,green))))
     `(rainbow-delimiters-depth-4-face   ((,c (:foreground ,orange))))
     `(rainbow-delimiters-depth-5-face   ((,c (:foreground ,violet))))

     ;; re-builder
     `(reb-match-0 ((,c (:foreground ,orange   :inverse-video t))))
     `(reb-match-1 ((,c (:foreground ,magenta  :inverse-video t))))
     `(reb-match-2 ((,c (:foreground ,green    :inverse-video t))))
     `(reb-match-3 ((,c (:foreground ,yellow   :inverse-video t))))

     ;; which-key
     `(which-key-key-face                   ((,c (:foreground ,green))))
     `(which-key-group-description-face     ((,c (:foreground ,violet))))
     `(which-key-command-description-face   ((,c (:foreground ,blue))))
     `(which-key-local-map-description-face ((,c (:foreground ,magenta))))

     ;; whitespace
     `(whitespace-tab              ((,c (:foreground ,grey-d))))
     `(whitespace-newline          ((,c (:foreground ,grey-d))))
     `(whitespace-trailing         ((,c (:background ,grey-d))))
     `(whitespace-line             ((,c (:background ,current-line :foreground ,magenta))))

     ;; workgroups2
     `(wg-current-workgroup-face   ((,c (:foreground ,black  :background ,blue))))
     `(wg-other-workgroup-face     ((,c (:foreground ,grey :background ,current-line))))
     `(wg-divider-face             ((,c (:foreground ,grey-d))))
     `(wg-brace-face               ((,c (:foreground ,blue))))

     ;;
     ;; Language-specific
     ;;

     ;; (css|scss)-mode
     `(css-proprietary-property ((,c (:foreground ,orange))))
     `(css-property             ((,c (:foreground ,green))))
     `(css-selector             ((,c (:foreground ,blue))))

     ;; js2-mode
     `(js2-function-param  ((,c (:foreground ,variables))))
     `(js2-function-call   ((,c (:foreground ,functions))))
     `(js2-object-property ((,c (:foreground ,violet))))
     `(js2-jsdoc-tag       ((,c (:foreground ,comments))))

     ;; makefile-*-mode
     `(makefile-targets     ((,c (:foreground ,blue))))

     ;; markdown-mode
     `(markdown-header-face           ((,c (:foreground ,red :bold t))))
     `(markdown-header-delimiter-face ((,c (:inherit markdown-header-face))))
     `(markdown-metadata-key-face     ((,c (:foreground ,red))))
     `(markdown-blockquote-face ((,c (:foreground ,violet))))
     `(markdown-markup-face     ((,c (:foreground ,grey))))
     `(markdown-markup-face     ((,c (:foreground ,operators))))
     `(markdown-pre-face        ((,c (:foreground ,green))))
     `(markdown-inline-face     ((,c (:foreground ,cyan))))
     `(markdown-list-face       ((,c (:foreground ,red))))
     `(markdown-link-face       ((,c (:foreground ,blue :bold t))))
     `(markdown-url-face        ((,c (:foreground ,magenta :bold t))))
     `(markdown-header-face-1   ((,c (:inherit markdown-header-face))))
     `(markdown-header-face-2   ((,c (:inherit markdown-header-face))))
     `(markdown-header-face-3   ((,c (:inherit markdown-header-face))))
     `(markdown-header-face-4   ((,c (:inherit markdown-header-face))))
     `(markdown-header-face-5   ((,c (:inherit markdown-header-face))))
     `(markdown-header-face-6   ((,c (:inherit markdown-header-face))))
     `(markdown-header-rule-face       ((,c (:inherit shadow))))
     `(markdown-italic-face            ((,c (:inherit italic :foreground ,violet))))
     `(markdown-bold-face              ((,c (:inherit bold :foreground ,orange))))
     `(markdown-link-face              ((,c (:inherit shadow))))
     `(markdown-link-title-face        ((,c (:inherit link))))
     `(markdown-url-face               ((,c (:inherit link))))

     ;; org-mode
     `(org-tag                   ((,c (:foreground ,yellow :bold t))))
     `(org-priority              ((,c (:foreground ,red))))
     `(org-ellipsis              ((,c (:inherit hs-face))))
     `(org-hide                  ((,c (:foreground ,bg))))
     `(org-table                 ((,c (:foreground ,yellow-d))))
     `(org-quote                 ((,c (:slant italic :foreground ,grey :background ,current-line))))
     `(org-document-info         ((,c (:foreground ,orange))))
     `(org-document-info-keyword ((,c (:foreground ,grey-d))))
     `(org-meta-line             ((,c (:foreground ,comments))))
     `(org-block-begin-line      ((,c (:background ,current-line :foreground ,comments))))
     `(org-block-end-line        ((,c (:inherit org-block-begin-line))))
     `(org-block-background      ((,c (:background ,current-line))))
     `(org-archived              ((,c (:foreground ,grey))))
     `(org-document-title        ((,c (:foreground ,cyan :height 1.2))))
     `(org-level-1               ((,c (:background ,current-line :foreground ,blue  :height 1.2 :bold t))))
     `(org-level-2               ((,c (:foreground ,yellow-d :height 1.1 :bold t))))
     `(org-level-3               ((,c (:foreground ,cyan :height 1.0 :bold t))))
     `(org-level-4               ((,c (:foreground ,teal))))
     `(org-level-5               ((,c (:foreground ,yellow))))
     `(org-level-6               ((,c (:foreground ,green))))
     `(org-code                  ((,c (:foreground ,orange))))
     `(org-verbatim              ((,c (:foreground ,green))))
     `(org-formula               ((,c (:foreground ,cyan))))
     `(org-list              ((,c (:foreground ,cyan))))
     `(org-footnote              ((,c (:foreground ,orange))))
     `(org-link                  ((,c (:foreground ,cyan :underline t))))
     `(org-date                  ((,c (:foreground ,violet))))
     `(org-todo                  ((,c (:foreground ,yellow :bold inherit))))
     `(org-done                  ((,c (:foreground ,green  :bold inherit))))
     `(org-headline-done         ((,c (:foreground ,grey :bold t :strike-through t))))
     `(org-special-keyword       ((,c (:foreground ,magenta))))
     `(org-checkbox              ((,c (:inherit org-todo))))
     `(org-checkbox-statistics-todo ((,c (:inherit org-todo))))
     `(org-checkbox-statistics-done ((,c (:inherit org-done))))
     `(org-list-bullet           ((,c (:foreground ,cyan :bold t :italic t))))  ; custom
     `(message-header-name       ((,c (:foreground ,green)))) ; custom
  
     ;; mode-line with slightly more height
     `(mode-line ((,c (:background ,teal :foreground ,black :box (:line-width 2 :color ,teal)))))    
     `(mode-line-inactive ((,c (:background ,region :foreground ,teal :box (:line-width 2 :color ,region)))))
     
     ;; web-mode
     `(web-mode-doctype-face           ((,c (:foreground ,comments))))
     `(web-mode-html-tag-face          ((,c (:foreground ,methods))))
     `(web-mode-html-tag-bracket-face  ((,c (:foreground ,methods))))
     `(web-mode-html-attr-name-face    ((,c (:foreground ,type))))
     `(web-mode-html-entity-face       ((,c (:foreground ,cyan ))))
     `(web-mode-block-control-face     ((,c (:foreground ,orange))))

     ;; only left fringe
     '(fringe-mode (quote (nil . 0)) nil (fringe))
     
     )))

;; set cursor style
(setq-default cursor-type '(bar . 5))

;; autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(add-hook 'org-mode-hook (lambda () (linum-mode 0)))

;; Footer
(provide-theme 'prassee)

;; Local Variables:
;; no-byte-compile: t
;; indent-tabs-mode: nil
;; End:
;;; prassee-theme.el ends here prassee-theme.el ends hereprassee-theme.el ends hereprassee-theme.el ends hereprassee-theme.el ends hereprassee-theme.el ends here
