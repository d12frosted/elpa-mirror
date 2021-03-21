;;; klere-theme.el --- A dark theme with lambent color highlights and incremental grays

;; Copyright (C) 2018,2020, Wamm K. D.

;; Author: Wamm K. D. <jaft.r@outlook.com>
;; Homepage: https://codeberg.org/WammKD/emacs-klere-theme
;; Version: 0.1
;; Package-Version: 20210320.1912
;; Package-Commit: f9eacacc00455e6c42961ec41f24f864c2a05ace
;; Package-Requires: ((emacs "24"))
;; Started with emacs-theme-generator, https://github.com/mswift42/theme-creator.


;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of Emacs.

;;; Commentary:

;; I haven't seen all themes out there, I'm sure, but it seems most users
;; prefer – what look like, to me – washed out colors. In some cases, some
;; themes have stated that was their point, that contrasting colors are
;; harder on the eyes. But call me a slave to the asthetic but I wanted a
;; dark theme with radiant colors that seem to shine against the dark
;; backgrounds; I dunno if I quite achieved that but it's the color scheme
;; I've found myself most liking so I'm pleased with it. Options are
;; great so everyone gets what they like so here's it for you to try.

;;; Code:

 (deftheme klere)
 (let ((class   '((class color) (min-colors 89)))
       (fg1                            "#FFFFFF")
       (fg2                            "#e8e8e8")
       (fg3                            "#d1d1d1")
       (fg4                            "#bbbbbb")
       (bg1                            "#000000")
       (bg2                            "#101010")
       (bg3                            "#181818")
       (bg4                            "#282828")
       (bg5                            "#393939")
       (key2                           "#3e89bb")
       (key3                           "#0f6d9e")
       (builtin                        "#F52749")
       (keyword                        "#007bb3")
       (const                          "#00d1e0")
       (comment                        "#484848") ;; #e01d1d
       (func                           "#622f7d")
       (str                            "#1D8B15") ;; #34be34 (but darker and more green)
       (type                           "#eab700")
       (var                            "#e87400")
       (warning                        "#ff0000"))
   (custom-theme-set-faces
   'klere
        `(default                                  ((,class (:background ,bg2 :foreground ,fg1))))
        `(font-lock-builtin-face                   ((,class (:foreground ,builtin))))
        `(font-lock-comment-face                   ((,class (:foreground ,comment))))
	`(font-lock-negation-char-face             ((,class (:foreground ,const))))
	`(font-lock-reference-face                 ((,class (:foreground ,const))))
	`(font-lock-constant-face                  ((,class (:foreground ,const))))
        `(font-lock-doc-face                       ((,class (:foreground ,comment))))
        `(font-lock-function-name-face             ((,class (:foreground ,func :weight bold))))
        `(font-lock-keyword-face                   ((,class (:bold ,class :foreground ,keyword))))
        `(font-lock-string-face                    ((,class (:foreground ,str))))
        `(font-lock-type-face                      ((,class (:foreground ,type ))))
        `(font-lock-variable-name-face             ((,class (:foreground ,var))))
        `(font-lock-warning-face                   ((,class (:foreground ,warning :background ,bg3))))
        `(region                                   ((,class (:background ,fg1 :foreground ,bg1))))
        `(highlight                                ((,class (:foreground ,fg3 :background ,bg4))))
	`(hl-line                                  ((,class (:background  ,bg3))))
	`(fringe                                   ((,class (:background ,bg3 :foreground ,fg4))))
	`(cursor                                   ((,class (:background ,bg4))))
        `(show-paren-match-face                    ((,class (:foreground ,warning :background ,bg1))))
        `(isearch                                  ((,class (:bold t :foreground ,warning :background ,bg4))))
        `(mode-line                                ((,class (:bold t :underline unspecified :foreground ,fg1 :background "#232323"))))
        `(mode-line-inactive                       ((,class (:foreground ,fg4 :background ,bg2 :weight normal))))
        `(mode-line-buffer-id                      ((,class (:bold t :foreground ,keyword :background nil))))
	`(mode-line-highlight                      ((,class (:foreground ,func :box nil :weight bold))))
        `(mode-line-emphasis                       ((,class (:foreground ,fg1))))
	`(vertical-border                          ((,class (:foreground ,fg3))))
        `(minibuffer-prompt                        ((,class (:bold t :foreground ,keyword))))
        `(default-italic                           ((,class (:italic t))))
	`(link                                     ((,class (:foreground ,const :underline t))))
	`(org-code                                 ((,class (:foreground ,fg2))))
	`(org-hide                                 ((,class (:foreground ,fg4))))
        `(org-level-1                              ((,class (:bold t :foreground ,fg2 :height 1.1))))
        `(org-level-2                              ((,class (:bold nil :foreground ,fg3))))
        `(org-level-3                              ((,class (:bold t :foreground ,fg4))))
        `(org-level-4                              ((,class (:bold nil :foreground ,bg5))))
        `(org-date                                 ((,class (:underline t :foreground ,var) )))
        `(org-footnote                             ((,class (:underline t :foreground ,fg4))))
        `(org-link                                 ((,class (:underline t :foreground ,type ))))
        `(org-special-keyword                      ((,class (:foreground ,func))))
        `(org-block                                ((,class (:foreground ,fg3))))
        `(org-quote                                ((,class (:inherit org-block :slant italic))))
        `(org-verse                                ((,class (:inherit org-block :slant italic))))
        `(org-todo                                 ((,class (:box (:line-width 1 :color ,fg3) :foreground ,keyword :bold t))))
        `(org-done                                 ((,class (:box (:line-width 1 :color ,bg4) :bold t :foreground ,bg5))))
        `(org-warning                              ((,class (:underline t :foreground ,warning))))
        `(org-agenda-structure                     ((,class (:weight bold :foreground ,fg3 :box (:color ,fg4) :background ,bg4))))
        `(org-agenda-date                          ((,class (:foreground ,var :height 1.1 ))))
        `(org-agenda-date-weekend                  ((,class (:weight normal :foreground ,fg4))))
        `(org-agenda-date-today                    ((,class (:weight bold :foreground ,keyword :height 1.4))))
        `(org-agenda-done                          ((,class (:foreground ,bg5))))
	`(org-scheduled                            ((,class (:foreground ,type))))
        `(org-scheduled-today                      ((,class (:foreground ,func :weight bold :height 1.2))))
	`(org-ellipsis                             ((,class (:foreground ,builtin))))
	`(org-verbatim                             ((,class (:foreground ,fg4))))
        `(org-document-info-keyword                ((,class (:foreground ,func))))
	`(font-latex-bold-face                     ((,class (:foreground ,type))))
	`(font-latex-italic-face                   ((,class (:foreground ,key3 :italic t))))
	`(font-latex-string-face                   ((,class (:foreground ,str))))
	`(font-latex-match-reference-keywords      ((,class (:foreground ,const))))
	`(font-latex-match-variable-keywords       ((,class (:foreground ,var))))
	`(ido-only-match                           ((,class (:foreground ,warning))))
	`(org-sexp-date                            ((,class (:foreground ,fg4))))
	`(ido-first-match                          ((,class (:foreground ,keyword :bold t))))
	`(gnus-header-content                      ((,class (:foreground ,keyword))))
	`(gnus-header-from                         ((,class (:foreground ,var))))
	`(gnus-header-name                         ((,class (:foreground ,type))))
	`(gnus-header-subject                      ((,class (:foreground ,func :bold t))))
	`(mu4e-view-url-number-face                ((,class (:foreground ,type))))
	`(mu4e-cited-1-face                        ((,class (:foreground ,fg2))))
	`(mu4e-cited-7-face                        ((,class (:foreground ,fg3))))
	`(mu4e-header-marks-face                   ((,class (:foreground ,type))))
	`(ffap                                     ((,class (:foreground ,fg4))))
	`(js2-private-function-call                ((,class (:foreground ,const))))
	`(js2-jsdoc-html-tag-delimiter             ((,class (:foreground ,str))))
	`(js2-jsdoc-html-tag-name                  ((,class (:foreground ,key2))))
	`(js2-external-variable                    ((,class (:foreground ,type  ))))
        `(js2-function-param                       ((,class (:foreground ,const))))
        `(js2-jsdoc-value                          ((,class (:foreground ,str))))
        `(js2-private-member                       ((,class (:foreground ,fg3))))
        `(js3-warning-face                         ((,class (:underline ,keyword))))
        `(js3-error-face                           ((,class (:underline ,warning))))
        `(js3-external-variable-face               ((,class (:foreground ,var))))
        `(js3-function-param-face                  ((,class (:foreground ,key3))))
        `(js3-jsdoc-tag-face                       ((,class (:foreground ,keyword))))
        `(js3-instance-member-face                 ((,class (:foreground ,const))))
        `(warning                                  ((,class (:foreground ,warning))))
	`(ac-completion-face                       ((,class (:underline t :foreground ,keyword))))
	`(info-quoted-name                         ((,class (:foreground ,builtin))))
	`(info-string                              ((,class (:foreground ,str))))
	`(icompletep-determined                    ((,class :foreground ,builtin)))
        `(undo-tree-visualizer-current-face        ((,class :foreground ,builtin)))
        `(undo-tree-visualizer-default-face        ((,class :foreground ,fg2)))
        `(undo-tree-visualizer-unmodified-face     ((,class :foreground ,var)))
        `(undo-tree-visualizer-register-face       ((,class :foreground ,type)))
	`(slime-repl-inputed-output-face           ((,class (:foreground ,type))))
        `(trailing-whitespace                      ((,class :foreground nil :background ,warning)))
        `(rainbow-delimiters-depth-1-face          ((,class :foreground ,fg1)))
        `(rainbow-delimiters-depth-2-face          ((,class :foreground ,type)))
        `(rainbow-delimiters-depth-3-face          ((,class :foreground ,var)))
        `(rainbow-delimiters-depth-4-face          ((,class :foreground ,const)))
        `(rainbow-delimiters-depth-5-face          ((,class :foreground ,keyword)))
        `(rainbow-delimiters-depth-6-face          ((,class :foreground ,fg1)))
        `(rainbow-delimiters-depth-7-face          ((,class :foreground ,type)))
        `(rainbow-delimiters-depth-8-face          ((,class :foreground ,var)))
        `(magit-item-highlight                     ((,class :background ,bg4)))
        `(magit-section-heading                    ((,class (:foreground ,keyword :weight bold))))
        `(magit-hunk-heading                       ((,class (:background ,bg4))))
        `(magit-section-highlight                  ((,class (:background ,bg3))))
        `(magit-hunk-heading-highlight             ((,class (:background ,bg4))))
        `(magit-diff-context-highlight             ((,class (:background ,bg4 :foreground ,fg3))))
        `(magit-diffstat-added                     ((,class (:foreground ,type))))
        `(magit-diffstat-removed                   ((,class (:foreground ,var))))
        `(magit-process-ok                         ((,class (:foreground ,func :weight bold))))
        `(magit-process-ng                         ((,class (:foreground ,warning :weight bold))))
        `(magit-branch                             ((,class (:foreground ,const :weight bold))))
        `(magit-log-author                         ((,class (:foreground ,fg3))))
        `(magit-hash                               ((,class (:foreground ,fg2))))
        `(magit-diff-file-header                   ((,class (:foreground ,fg2 :background ,bg4))))
        `(lazy-highlight                           ((,class (:foreground ,fg2 :background ,bg4))))
        `(term                                     ((,class (:foreground ,fg1 :background ,bg1))))
        `(term-color-black                         ((,class (:foreground ,bg4 :background ,bg4))))
        `(term-color-blue                          ((,class (:foreground ,func :background ,func))))
        `(term-color-red                           ((,class (:foreground ,keyword :background ,bg4))))
        `(term-color-green                         ((,class (:foreground ,type :background ,bg4))))
        `(term-color-yellow                        ((,class (:foreground ,var :background ,var))))
        `(term-color-magenta                       ((,class (:foreground ,builtin :background ,builtin))))
        `(term-color-cyan                          ((,class (:foreground ,str :background ,str))))
        `(term-color-white                         ((,class (:foreground ,fg2 :background ,fg2))))
        `(rainbow-delimiters-unmatched-face        ((,class :foreground ,warning)))
        `(helm-header                              ((,class (:foreground ,fg2 :background ,bg1 :underline nil :box nil))))
        `(helm-source-header                       ((,class (:foreground ,keyword :background ,bg1 :underline nil :weight bold))))
        `(helm-selection                           ((,class (:background ,bg3 :underline nil))))
        `(helm-selection-line                      ((,class (:background ,bg3))))
        `(helm-visible-mark                        ((,class (:foreground ,bg1 :background ,bg4))))
        `(helm-candidate-number                    ((,class (:foreground ,bg1 :background ,fg1))))
        `(helm-separator                           ((,class (:foreground ,type :background ,bg1))))
        `(helm-time-zone-current                   ((,class (:foreground ,builtin :background ,bg1))))
        `(helm-time-zone-home                      ((,class (:foreground ,type :background ,bg1))))
        `(helm-buffer-not-saved                    ((,class (:foreground ,type :background ,bg1))))
        `(helm-buffer-process                      ((,class (:foreground ,builtin :background ,bg1))))
        `(helm-buffer-saved-out                    ((,class (:foreground ,fg1 :background ,bg1))))
        `(helm-buffer-size                         ((,class (:foreground ,fg1 :background ,bg1))))
        `(helm-ff-directory                        ((,class (:foreground ,func :background ,bg1 :weight bold))))
        `(helm-ff-file                             ((,class (:foreground ,fg1 :background ,bg1 :weight normal))))
        `(helm-ff-executable                       ((,class (:foreground ,key2 :background ,bg1 :weight normal))))
        `(helm-ff-invalid-symlink                  ((,class (:foreground ,key3 :background ,bg1 :weight bold))))
        `(helm-ff-symlink                          ((,class (:foreground ,keyword :background ,bg1 :weight bold))))
        `(helm-ff-prefix                           ((,class (:foreground ,bg1 :background ,keyword :weight normal))))
        `(helm-grep-cmd-line                       ((,class (:foreground ,fg1 :background ,bg1))))
        `(helm-grep-file                           ((,class (:foreground ,fg1 :background ,bg1))))
        `(helm-grep-finish                         ((,class (:foreground ,fg2 :background ,bg1))))
        `(helm-grep-lineno                         ((,class (:foreground ,fg1 :background ,bg1))))
        `(helm-grep-match                          ((,class (:foreground nil :background nil :inherit helm-match))))
        `(helm-grep-running                        ((,class (:foreground ,func :background ,bg1))))
        `(helm-moccur-buffer                       ((,class (:foreground ,func :background ,bg1))))
        `(helm-source-go-package-godoc-description ((,class (:foreground ,str))))
        `(helm-bookmark-w3m                        ((,class (:foreground ,type))))
        `(company-echo-common                      ((,class (:foreground ,bg1 :background ,fg1))))
        `(company-preview                          ((,class (:background ,bg1 :foreground ,key2))))
        `(company-preview-common                   ((,class (:foreground ,bg3 :foreground ,fg3))))
        `(company-preview-search                   ((,class (:foreground ,type :background ,bg1))))
        `(company-scrollbar-bg                     ((,class (:background ,bg4))))
        `(company-scrollbar-fg                     ((,class (:foreground ,keyword))))
        `(company-tooltip                          ((,class (:foreground ,fg2 :background ,bg1 :bold t))))
        `(company-tooltop-annotation               ((,class (:foreground ,const))))
        `(company-tooltip-common                   ((,class ( :foreground ,fg3))))
        `(company-tooltip-common-selection         ((,class (:foreground ,str))))
        `(company-tooltip-mouse                    ((,class (:inherit highlight))))
        `(company-tooltip-selection                ((,class (:background ,bg4 :foreground ,fg3))))
        `(company-template-field                   ((,class (:inherit region))))
        `(web-mode-builtin-face                    ((,class (:inherit    ,font-lock-builtin-face))))
        `(web-mode-comment-face                    ((,class (:inherit    ,font-lock-comment-face))))
        `(web-mode-constant-face                   ((,class (:inherit    ,font-lock-constant-face))))
        `(web-mode-keyword-face                    ((,class (:foreground ,keyword))))
        `(web-mode-doctype-face                    ((,class (:foreground "#9FE55B"                     :weight bold))))
        `(web-mode-function-name-face              ((,class (:inherit    ,font-lock-function-name-face))))
        `(web-mode-string-face                     ((,class (:foreground ,str))))
        `(web-mode-type-face                       ((,class (:inherit    ,font-lock-type-face))))
        `(web-mode-html-attr-name-face             ((,class (:foreground ,func))))
        `(web-mode-html-attr-value-face            ((,class (:foreground ,keyword))))
        `(web-mode-warning-face                    ((,class (:inherit    ,font-lock-warning-face))))
        `(web-mode-html-tag-face                   ((,class (:foreground ,builtin                      :weight bold))))
        `(web-mode-css-pseudo-class-face           ((,class (:foreground "cyan3"                       :weight normal))))
        `(jde-java-font-lock-package-face          ((t (:foreground ,var))))
        `(jde-java-font-lock-public-face           ((t (:foreground ,keyword))))
        `(jde-java-font-lock-private-face          ((t (:foreground ,keyword))))
        `(jde-java-font-lock-constant-face         ((t (:foreground ,const))))
        `(jde-java-font-lock-modifier-face         ((t (:foreground ,key3))))
        `(jde-jave-font-lock-protected-face        ((t (:foreground ,keyword))))
        `(jde-java-font-lock-number-face           ((t (:foreground ,var))))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'klere)

;; Local Variables:
;; no-byte-compile: t
;; End:
(provide 'klere-theme)
;;; klere-theme.el ends here
