;;; flatfluc-theme.el --- Custom merge of flucui and flatui themes  -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Sébastien Le Maguer based on the work of MetroWind and John Louis Del Rosario

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

;; Author: Sébastien Le Maguer <lemagues@tcd.ie>
;; URL: https://github.com/seblemaguer/flatfluc-theme
;; Package-Version: 20210908.1423
;; Package-Commit: 33726cd072ad83c6943e1c3b83db2fff60f324ce
;; Keywords: lisp
;; Version: 0.5
;; Package-Requires: ((emacs "26.1"))

;;; Commentary:
;;
;; FlatFluc theme is a custom theme for Emacs corresponding to the merge of:
;;  - flucui light theme: https://github.com/MetroWind/flucui-theme
;;  - flatui theme: https://github.com/john2x/flatui-theme.el
;;
;;  The default font used is Inconsolata-11

;;; Code:

(defconst fui-turquoise "#1abc9c")
(defconst fui-emerald "#2ecc71")
(defconst fui-river "#3498db")
(defconst fui-amethyst "#9b59b6")
(defconst fui-deep-asphalt "#34495e")
(defconst fui-asphalt "#425d78")
(defconst fui-sunflower "#f1c40f")
(defconst fui-carrot "#e67e22")
(defconst fui-alizarin "#e74c3c")
(defconst fui-clouds "#ecf0f1")
(defconst fui-concrete "#95a5a6")

;; Dark colors
(defconst fui-dark-turquoise "#16a085")
(defconst fui-dark-emerald "#27ae60")
(defconst fui-dark-river "#2980b9")
(defconst fui-dark-amethyst "#8e44ad")
(defconst fui-dark-asphalt "#2c3e50")
(defconst fui-dark-sunflower "#f39c12")
(defconst fui-dark-carrot "#d35400")
(defconst fui-dark-alizarin "#c0392b")
(defconst fui-dark-clouds "#bdc3c7")
(defconst fui-deep-clouds "#dce0e1")
(defconst fui-dark-concrete "#7f8c8d")

(defconst fui-bg fui-clouds)
(defconst fui-fg fui-asphalt)

(deftheme flatfluc
  "FlatUI based theme which is  merge of flatui and flucui-light themes.")

;; Colors

(custom-theme-set-faces
 'flatfluc

 ;; ===== basic coloring
 `(header-line ((t (:foreground ,fui-deep-asphalt :background ,fui-deep-clouds :box (:line-width -1)))))
 '(button ((t (:underline t))))
 `(link ((t (:foreground ,fui-dark-river :underline t))))
 `(link-visited ((t (:foreground ,fui-amethyst :underline t :weight normal))))
 `(escape-glyph ((t (:foreground ,fui-sunflower :bold t))))
 `(highlight ((t (:background ,fui-deep-clouds))))
 `(hl-line ((t (:inverse-video nil :background ,fui-deep-clouds))))
 `(shadow ((t (:foreground ,fui-concrete))))
 `(success ((t (:foreground ,fui-dark-emerald :weight bold))))
 `(warning ((t (:foreground ,fui-dark-carrot :weight bold))))
 `(show-paren-match ((t (:background ,fui-emerald :foreground ,fui-clouds))))
 `(show-paren-mismatch ((t (:background ,fui-alizarin :foreground ,fui-clouds))))
 `(menu ((t (:foreground ,fui-dark-river :background ,fui-deep-clouds))))
 `(minibuffer-prompt ((t (:foreground ,fui-asphalt :weight bold))))
 `(secondary-selection ((t (:background ,fui-deep-clouds))))
 `(trailing-whitespace ((t (:background ,fui-alizarin))))
 `(vertical-border ((t (:foreground ,fui-deep-clouds))))
 `(default ((t (:background ,fui-bg :foreground ,fui-fg))))
 `(cursor ((t (:background ,fui-carrot :foreground ,fui-fg))))
 `(region ((t (:background ,fui-dark-sunflower :foreground ,fui-fg))))
 `(fringe ((t (:background ,fui-bg))))
 `(minibuffer-prompt ((t (:slant italic :foreground ,fui-dark-concrete))))

 ;; ===== Font lock part
 `(font-lock-builtin-face ((t (:foreground ,fui-dark-turquoise))))
 `(font-lock-comment-face ((t (:slant italic :foreground ,fui-concrete))))
 `(font-lock-constant-face ((t (:slant italic :foreground ,fui-amethyst))))
 `(font-lock-doc-string-face ((t (:foreground "green4"))))
 `(font-lock-function-name-face ((t (:foreground ,fui-amethyst))))
 `(font-lock-keyword-face ((t (:foreground ,fui-river))))
 `(font-lock-preprocessor-face ((t (:foreground "blue3"))))
 `(font-lock-reference-face ((t (:foreground ,fui-dark-carrot))))
 `(font-lock-string-face ((t (:foreground ,fui-dark-turquoise))))
 `(font-lock-type-face ((t (:foreground ,fui-dark-emerald))))
 `(font-lock-variable-name-face ((t (:foreground ,fui-river))))
 `(font-lock-warning-face ((t (:foreground ,fui-dark-carrot))))

 ;; ===== compilation
 `(compilation-column-face ((t (:foreground ,fui-dark-sunflower))))
 `(compilation-enter-directory-face ((t (:foreground ,fui-dark-turquoise))))
 `(compilation-error-face ((t (:foreground ,fui-dark-alizarin :weight bold :underline t))))
 `(compilation-face ((t (:foreground ,fui-dark-river))))
 `(compilation-info-face ((t (:foreground ,fui-dark-river))))
 `(compilation-info ((t (:foreground ,fui-dark-emerald :underline t))))
 `(compilation-leave-directory-face ((t (:foreground ,fui-dark-amethyst))))
 `(compilation-line-face ((t (:foreground ,fui-sunflower))))
 `(compilation-line-number ((t (:foreground ,fui-sunflower))))
 `(compilation-message-face ((t (:foreground ,fui-asphalt))))
 `(compilation-warning-face ((t (:foreground ,fui-dark-carrot :weight bold :underline t))))
 `(compilation-mode-line-exit ((t (:foreground ,fui-turquoise :weight bold))))
 `(compilation-mode-line-fail ((t (:foreground ,fui-dark-alizarin :weight bold))))
 `(compilation-mode-line-run ((t (:foreground ,fui-dark-sunflower :weight bold))))

 ;; ===== grep
 `(grep-context-face ((t (:foreground ,fui-asphalt))))
 `(grep-error-face ((t (:foreground ,fui-dark-alizarin :weight bold :underline t))))
 `(grep-hit-face ((t (:foreground ,fui-turquoise :weight bold))))
 `(grep-match-face ((t (:foreground ,fui-sunflower :weight bold))))
 `(match ((t (:background ,fui-turquoise :foreground ,fui-asphalt))))

 ;; ===== isearch
 `(isearch ((t (:foreground ,fui-clouds :weight bold :background ,fui-alizarin))))
 `(isearch-fail ((t (:foreground ,fui-sunflower :weight bold :background ,fui-dark-alizarin))))
 `(lazy-highlight ((t (:foreground ,fui-asphalt :weight bold :background ,fui-sunflower))))

 ;; ===== Modeline
 `(mode-line ((t (:background ,fui-deep-clouds :foreground ,fui-fg :box (:line-width 1) :family "Inconsolata-11" :height 0.8))))
 `(mode-line-buffer-id ((t (:foreground ,fui-fg))))
 `(mode-line-inactive ((t (:background ,fui-dark-clouds :foreground ,fui-fg :box (:line-width 1) :family "Inconsolata-11" :height 0.8))))

 ;; ==== Main pages
 `(set-face-attribute 'Man-overstrike nil :weight bold :foreground ,fui-dark-carrot)
 `(set-face-attribute 'Man-underline nil  :weight underline :foreground ,fui-dark-river)

 ;; ==== Face for specific prog modes
 `(sh-heredoc ((t (:foreground nil :inherit font-lock-string-face))))

 ;; ==== Dired
 `(dired-directory ((t (:foreground ,fui-river))))
 `(dired-symlink ((t (:foreground ,fui-dark-turquoise))))
 `(dired-perm-write ((t (:foreground ,fui-dark-carrot))))

 ;; ==== Diff
 `(diff-added ((t (:foreground ,fui-river))))
 `(diff-removed ((t (:foreground ,fui-alizarin))))
 ;; `(diff-context ((t (:background nil))))
 `(diff-file-header ((t (:bold t :background ,fui-concrete :weight bold))))
 `(diff-header ((t (:background ,fui-deep-clouds :foreground ,fui-fg))))

 ;; ==== Whitespace
 `(whitespace-trailing ((t (:background ,fui-dark-clouds))))
 `(whitespace-line ((t (:background ,fui-dark-clouds :foreground unspecified))))

 ;; ==== ERC
 `(erc-notice-face ((t (:foreground ,fui-dark-river :weight unspecified))))
 `(erc-header-line ((t (:foreground ,fui-bg :background ,fui-dark-clouds))))
 `(erc-timestamp-face ((t (:foreground ,fui-concrete :weight unspecified))))
 `(erc-current-nick-face ((t (:foreground ,fui-dark-carrot :weight unspecified))))
 `(erc-input-face ((t (:foreground ,fui-amethyst))))
 `(erc-prompt-face ((t (:foreground ,fui-dark-concrete :background nil :slant italic :weight unspecified))))
 `(erc-my-nick-face ((t (:foreground ,fui-dark-carrot))))
 `(erc-pal-face ((t (:foreground ,fui-dark-amethyst))))

 ;; ==== Rainbow delimiters
 `(rainbow-delimiters-depth-1-face ((t (:foreground ,fui-fg))))
 `(rainbow-delimiters-depth-2-face ((t (:foreground ,fui-turquoise))))
 `(rainbow-delimiters-depth-3-face ((t (:foreground ,fui-dark-river))))
 `(rainbow-delimiters-depth-4-face ((t (:foreground ,fui-dark-amethyst))))
 `(rainbow-delimiters-depth-5-face ((t (:foreground ,fui-dark-sunflower))))
 `(rainbow-delimiters-depth-6-face ((t (:foreground ,fui-dark-emerald))))
 `(rainbow-delimiters-depth-7-face ((t (:foreground ,fui-dark-concrete))))
 '(rainbow-delimiters-mismatched-face ((t (:foreground "white" :background "red" :weight bold))))
 '(rainbow-delimiters-unmatched-face ((t (:foreground "white" :background "red" :weight bold))))

 ;; ==== Magit
 `(magit-branch-local ((t (:foreground ,fui-river :background nil))))
 `(magit-branch-remote ((t (:foreground ,fui-dark-emerald :background nil))))
 `(magit-tag ((t (:foreground ,fui-river :background ,fui-bg))))
 `(magit-hash ((t (:foreground ,fui-concrete))))
 `(magit-section-title ((t (:foreground ,fui-dark-emerald :background ,fui-bg))))
 `(magit-section-heading ((t (:background ,fui-bg :foreground ,fui-fg))))
 `(magit-section-highlight ((t (:background ,fui-bg))))
 `(magit-item-highlight ((t (:foreground ,fui-fg :background ,fui-dark-clouds))))
 `(magit-log-author ((t (:foreground ,fui-amethyst))))
 `(magit-diff-added ((t (:inherit diff-added))))
 `(magit-diff-added-highlight ((t (:inherit magit-diff-added))))
 `(magit-diff-removed ((t (:inherit diff-removed))))
 `(magit-diff-removed-highlight ((t (:inherit magit-diff-removed))))
 `(magit-diff-context ((t (:inherit diff-context))))
 `(magit-diff-context-highlight ((t (:inherit magit-diff-context))))

 ;; ==== Git-gutter-fringe
 `(git-gutter-fr:modified ((t (:foreground ,fui-amethyst))))
 `(git-gutter-fr:added ((t (:foreground ,fui-emerald))))
 `(git-gutter-fr:deleted ((t (:foreground ,fui-alizarin))))

 ;; ==== Company
 `(company-preview ((t (:foreground ,fui-fg :background ,fui-sunflower))))
 `(company-preview-common ((t (:foreground ,fui-fg :background ,fui-carrot))))
 `(company-tooltip ((t (:foreground ,fui-fg :background ,fui-dark-clouds))))
 `(company-tooltip-common ((t (:foreground ,fui-dark-carrot))))
 `(company-tooltip-selection ((t (:background ,fui-deep-clouds))))
 `(company-tooltip-common-selection ((t (:foreground ,fui-dark-carrot))))
 `(company-tooltip-annotation ((t (:foreground ,fui-river))))
 `(company-scrollbar-bg ((t (:background ,fui-bg))))
 `(company-scrollbar-fg ((t (:background ,fui-dark-clouds))))

 ;; ==== Cperl
 `(cperl-array-face ((t (:weight bold :inherit font-lock-variable-name-face))))
 `(cperl-hash-face ((t (:weight bold :slant italic :inherit font-lock-variable-name-face))))
 `(cperl-nonoverridable-face ((t (:inherit font-lock-builtin-face))))

 ;; ==== Powerline
 `(mode-line ((t (:box nil))))
 `(powerline-active2 ((t (:foreground ,fui-fg :background ,fui-dark-clouds))))
 `(powerline-active1 ((t (:foreground ,fui-bg :background ,fui-emerald))))
 `(powerline-inactive2 ((t (:foreground ,fui-bg :background ,fui-concrete))))
 `(powerline-inactive1 ((t (:foreground ,fui-fg :background ,fui-dark-clouds))))

 ;; ==== Smart mode line
 `(sml/global  ((t (:foreground ,fui-fg))))
 `(sml/charging ((t (:foreground ,fui-emerald))))
 `(sml/discharging ((t (:foreground ,fui-dark-alizarin))))
 `(sml/read-only ((t (:foreground ,fui-dark-emerald))))
 `(sml/filename ((t (:foreground ,fui-river :weight bold))))
 `(sml/prefix ((t (:foreground ,fui-dark-amethyst :weight normal :slant italic))))
 `(sml/modes ((t (:foreground ,fui-fg :weight bold))))
 `(sml/modified ((t (:foreground ,fui-alizarin))))
 `(sml/outside-modified ((t (:foreground ,fui-bg :background ,fui-alizarin))))
 `(sml/position-percentage ((t (:foreground ,fui-amethyst :slant normal))))

 ;; ==== Helm
 `(helm-candidate-number ((t (:foreground ,fui-fg :background nil))))
 `(helm-source-header ((t (:foreground ,fui-bg :background ,fui-river :weight normal :slant italic))))
 `(helm-selection ((t (:background ,fui-dark-sunflower))))
 `(helm-prefarg ((t (:foreground ,fui-dark-alizarin))))
 `(helm-ff-directory ((t (:foreground ,fui-river))))
 `(helm-ff-executable ((t (:foreground ,fui-dark-emerald))))
 `(helm-ff-invalid-symlink ((t (:foreground ,fui-bg :background ,fui-dark-alizarin))))
 `(helm-ff-symlink ((t (:foreground ,fui-amethyst))))
 `(helm-ff-prefix ((t (:background ,fui-sunflower))))
 `(helm-ff-dotted-directory ((t (:background nil :foreground ,fui-dark-clouds))))
 `(helm-M-x-key ((t (:foreground ,fui-dark-emerald))))
 `(helm-buffer-file ((t (:foreground ,fui-fg))))
 `(helm-buffer-archive ((t (:inherit helm-buffer-file))))
 `(helm-buffer-directory ((t (:foreground ,fui-river :background nil))))
 `(helm-buffer-not-saved ((t (:foreground ,fui-dark-alizarin))))
 `(helm-buffer-modified ((t (:foreground ,fui-carrot))))
 `(helm-buffer-process ((t (:foreground ,fui-dark-emerald))))
 `(helm-buffer-size ((t (:foreground ,fui-concrete))))
 `(helm-ff-file ((t (:inherit default))))

 ;; ==== TeX
 `(font-latex-sedate-face ((t (:foreground ,fui-river))))
 `(font-latex-math-face ((t (:foreground ,fui-dark-turquoise))))
 `(font-latex-script-char-face ((t (:inherit font-latex-math-face))))

 ;; ==== adoc-mode
 `(markup-meta-hide-face ((t (:height 1.0 :foreground ,fui-fg))))
 `(markup-meta-face ((t (:height 1.0 :foreground ,fui-fg :family nil))))
 `(markup-reference-face ((t (:underline nil :foreground ,fui-dark-river))))
 `(markup-gen-face ((t (:foreground ,fui-dark-river))))
 `(markup-passthrough-face ((t (:inherit markup-gen-face))))
 `(markup-replacement-face ((t (:family nil :foreground ,fui-amethyst))))
 `(markup-list-face ((t (:weight bold))))
 `(markup-secondary-text-face ((t (:height 1.0 :foreground ,fui-dark-emerald))))
 `(markup-verbatim-face ((t (:foreground ,fui-dark-concrete))))
 `(markup-typewriter-face ((t (:inherit nil))))
 `(markup-title-0-face ((t (:height 1.2 :inherit markup-gen-face))))
 `(markup-title-1-face ((t (:height 1.0 :inherit markup-gen-face))))
 `(markup-title-2-face ((t (:height 1.0 :inherit markup-gen-face))))
 `(markup-title-3-face ((t (:height 1.0 :inherit markup-gen-face))))
 `(markup-title-4-face ((t (:height 1.0 :inherit markup-gen-face))))
 `(markup-title-5-face ((t (:height 1.0 :inherit markup-gen-face))))

 ;; ==== Org-mode
 `(org-hide ((t (:foreground ,fui-bg))))
 `(org-table ((t (:foreground ,fui-fg))))
 `(org-date ((t (:foreground ,fui-emerald))))
 `(org-done ((t (:weight normal :foreground ,fui-dark-concrete))))
 `(org-todo ((t (:weight normal :foreground ,fui-carrot))))
 `(org-latex-and-related ((t (:foreground ,fui-concrete :italic t))))
 `(org-checkbox ((t (:weight normal :foreground ,fui-dark-concrete))))
 `(org-mode-line-clock ((t (:background nil))))
 `(org-document-title ((t (:weight normal :foreground nil))))

 ;; ==== Message
 `(message-header-name ((t (:foreground ,fui-dark-concrete))))
 `(message-header-other ((t (:foreground ,fui-fg))))
 `(message-header-cc ((t (:inherit message-header-other))))
 `(message-header-newsgroups ((t (:inherit message-header-other))))
 `(message-header-xheader ((t (:inherit message-header-other))))
 `(message-header-subject ((t (:foreground ,fui-dark-emerald))))
 `(message-header-to ((t (:foreground ,fui-dark-river))))
 `(message-mml ((t (:foreground ,fui-concrete))))

 ;; ==== Notmuch
 `(notmuch-search-unread-face ((t (:foreground ,fui-dark-river))))
 `(notmuch-tag-face ((t (:foreground ,fui-dark-emerald))))
 `(notmuch-tree-match-author-face ((t (:foreground ,fui-dark-river))))
 `(notmuch-tree-no-match-face ((t (:foreground ,fui-concrete))))
 `(notmuch-tree-match-tag-face ((t (:inherit notmuch-tree-match-author-face))))
 `(notmuch-tag-unread-face ((t (:foreground ,fui-carrot))))
 `(notmuch-message-summary-face ((t (:foreground ,fui-dark-concrete :background ,fui-deep-clouds))))

 ;; ==== Mu4e
 `(mu4e-title-face                ((t ((t (:foreground ,fui-dark-emerald :background ,fui-bg))))))
 `(mu4e-cited-1-face              ((t (:foreground ,fui-dark-alizarin))))
 `(mu4e-cited-2-face              ((t (:foreground ,fui-dark-asphalt))))
 `(mu4e-cited-3-face              ((t (:foreground ,fui-dark-amethyst))))
 `(mu4e-cited-4-face              ((t (:foreground ,fui-dark-concrete))))
 `(mu4e-cited-5-face              ((t (:foreground ,fui-dark-carrot))))
 `(mu4e-cited-6-face              ((t (:foreground ,fui-dark-river))))
 `(mu4e-cited-7-face              ((t (:foreground ,fui-dark-sunflower))))
 `(mu4e-compose-separator-face    ((t (:inherit message-separator))))
 `(mu4e-contact-face              ((t (:inherit message-header-to))))
 `(mu4e-draft-face                ((t (:foreground ,fui-dark-alizarin))))
 `(mu4e-flagged-face              ((t (:foreground ,fui-dark-sunflower))))
 `(mu4e-footer-face               ((t (:foreground ,fui-dark-turquoise))))
 `(mu4e-forwarded-face            ((t (:foreground ,fui-dark-amethyst))))
 `(mu4e-header-highlight-face     ((t (:background ,fui-deep-clouds))))
 `(mu4e-header-key-face           ((t (:inherit message-header-name))))
 `(mu4e-header-value-face         ((t (:inherit message-header-other))))
 `(mu4e-special-header-value-face ((t (:foreground ,fui-dark-emerald))))
 `(mu4e-header-marks-face         ((t (:foreground ,fui-dark-alizarin))))
 `(mu4e-highlight-face            ((t (:inherit highlight))))
 `(mu4e-modeline-face             ((t (:foreground ,fui-dark-emerald))))
 `(mu4e-moved-face                ((t (:foreground ,fui-dark-river))))
 `(mu4e-region-code               ((t (:background ,fui-deep-clouds))))
 `(mu4e-replied-face              ((t (:foreground ,fui-dark-emerald))))
 `(mu4e-system-face               ((t (:foreground ,fui-dark-turquoise))))
 `(mu4e-trashed-face              ((t (:foreground ,fui-deep-asphalt))))
 `(mu4e-unread-face               ((t (:foreground ,fui-dark-river))))
 `(mu4e-attach-number-face        ((t (:foreground ,fui-deep-asphalt :background ,fui-deep-clouds))))
 `(mu4e-url-number-face           ((t (:foreground ,fui-dark-sunflower :background ,fui-deep-clouds))))

 ;; ==== Highlight-indent-guides
 `(highlight-indent-guides-odd-face ((t (:background ,fui-deep-clouds))))
 `(highlight-indent-guides-even-face ((t (:background nil)))))


;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'flatfluc)
(provide 'flatfluc-theme)

;; Local Variables:
;; rainbow-mode: t
;; hl-sexp-mode: nil
;; End:

;;; flatfluc-theme.el ends here
