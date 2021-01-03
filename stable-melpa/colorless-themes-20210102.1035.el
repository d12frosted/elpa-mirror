;;; colorless-themes.el --- A macro to generate mostly colorless themes

;; Copyright (C) 2018–2020 Thomas Letan
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;; Author: Thomas Letan <contact@thomasletan.fr>
;; URL: https://git.sr.ht/~lthms/colorless-themes.el
;; Package-Version: 20210102.1035
;; Package-Commit: c1ed1e12541cf05cc6c558d23c089c07e10b54d7
;; Package-Requires: ((emacs "24.1"))
;; Version: 0.2
;; License: GPL-3
;; Keywords: faces themes, faces

;;; Commentary:

;; colorless-themes generalizes nordless-theme, a minimalist theme inspired by
;; nofrils[1], an extremely minimalist colorscheme for vim, and nord[2], a
;; north-bluish color palette.  More precisely, it provides a macro called
;; `colorless-themes-make' to easily derive new “mostly colorless” themes.
;;
;; [1]: https://github.com/robertmeta/nofrils
;; [2]: https://github.com/arcticicestudio/nord

;;; Code:

;; -*- lexical-binding: t -*-

(defmacro colorless-themes-make (name bg bg+ current-line fade fg fg+ docs red warning yellow green)
  "A generic macro to create new themes.

Using this macro, it only takes minutes to write a new colorless theme.  To
create the theme NAME, you need to supply 12 different colors.  The three
primary colors are BG, FG and DOCS.  They together form the identity of the
newly created theme.  CURRENT-LINE is the background color of, well, the current
line.  BG+ is notably being used in the modline.  FADE is used for whitespace
characters.  FG+ is used in the cursor and the company tooltip.  Finally, RED,
WARNING, YELLOW and GREEN are pretty self-explanatory."
  `(progn
     (custom-theme-set-faces
      ',name
      '(default ((t (:background ,bg :foreground ,fg))))
      '(cursor ((t (:background ,fg+ :foreground ,bg+))))
      '(mode-line ((t (:background ,fade))))
      '(mode-line-inactive ((t ())))
      '(fill-column-indicator ((t (:foreground ,fade))))
      '(isearch ((t (:weight bold :background ,green :foreground ,bg))))
      '(lazy-highlight ((t (:weight bold :background ,current-line :foreground ,green))))
      '(evil-ex-substitute-matches ((t (:weight bold :strike-through t :foreground ,red))))
      '(evil-ex-substitute-replacement ((t (:weight bold :foreground ,green))))
      '(powerline-active1 ((t (:background ,bg))))
      '(powerline-active2 ((t (:background ,bg+))))
      '(powerline-inactive1 ((t (:background ,fade))))
      '(powerline-inactive2 ((t (:background ,fade))))
      '(link ((t (:underline ,docs))))
      '(secondary-selection ((t ())))
      '(italic ((t (:slant italic))))
      '(underline ((t (:underline ,fg))))
      '(shadow ((t ())))
      '(region ((t (:background ,fade :distant-foreground nil))))
      '(escape-glyph ((t ())))
      '(font-lock-warning-face ((t ())))
      '(font-lock-negation-char-face ((t ())))
      '(font-lock-regexp-grouping-backslash ((t ())))
      '(font-lock-regexp-grouping-construct ((t ())))
      '(font-lock-builtin-face ((t ())))
      '(minibuffer-prompt ((t ())))
      '(font-lock-constant-face ((t ())))
      '(font-lock-keyword-face ((t ())))
      '(font-lock-function-name-face ((t ())))
      '(font-lock-variable-name-face ((t ())))
      '(font-lock-preprocessor-face ((t ())))
      '(font-lock-type-face ((t ())))
      '(font-lock-comment-delimiter-face ((t (:foreground ,docs))))
      '(font-lock-comment-face ((t (:foreground ,docs))))
      '(font-lock-doc-face ((t (:foreground ,docs))))
      '(font-lock-string-face ((t (:weight bold :background ,bg+))))
      '(whitespace-space ((t (:foreground ,fade))))
      '(whitespace-tab ((t (:foreground ,fade))))
      '(whitespace-newline ((t (:foreground ,fade))))
      '(compilation-info ((t (:weight bold))))
      '(compilation-line-number ((t ())))
      '(compilation-mode-line-exit ((t (:foreground ,green))))
      '(compilation-mode-line-fail ((t (:foreground ,red))))
      '(match ((t (:foreground ,docs :background ,current-line))))
      '(linum ((t (:foreground ,fade))))
      '(line-number ((t (:foreground ,fade :height 0.8))))
      '(line-number-current-line ((t (:foreground ,fg :height 0.8))))
      '(hl-line ((t (:background ,current-line))))
      '(show-paren-match ((t (:foreground ,docs :weight bold))))
      '(show-paren-mismatch ((t (:foreground ,red :weight bold))))
      '(hl-paren-face ((t (:foreground ,docs :weight bold))))
      '(dired-directory ((t (:weight bold))))
      '(diredp-file-suffix ((t ())))
      '(diredp-ignored-file-name ((t ())))
      '(rst-level-1 ((t (:weight bold))))
      '(rst-level-2 ((t (:weight bold))))
      '(rst-level-3 ((t (:weight bold))))
      '(rst-level-4 ((t (:weight bold))))
      '(rst-level-5 ((t (:weight bold))))
      '(rst-level-6 ((t (:weight bold))))
      '(org-document-title ((t (:weight bold))))
      '(org-footnote ((t ())))
      '(org-level-1 ((t (:foreground ,docs :weight bold))))
      '(org-level-2 ((t (:foreground ,docs :weight bold))))
      '(org-level-3 ((t (:foreground ,docs :weight bold))))
      '(org-level-4 ((t (:foreground ,docs :weight bold))))
      '(org-level-5 ((t (:foreground ,docs :weight bold))))
      '(org-level-6 ((t (:foreground ,docs :weight bold))))
      '(org-level-7 ((t (:foreground ,docs :weight bold))))
      '(org-level-8 ((t (:foreground ,docs :weight bold))))
      '(org-date ((t ())))
      '(org-tag ((t (:foreground ,docs))))
      '(org-todo ((t (:foreground ,warning))))
      '(org-done ((t (:foreground ,green))))
      '(org-block ((t ())))
      '(org-table ((t ())))
      '(org-block-begin-line ((t (:background ,bg+ :foreground ,fg+ :extend t))))
      '(org-block-end-line ((t (:background ,bg+ :foreground ,fg+ :extend t))))
      '(org-meta-line ((t (:foreground ,fg+))))
      '(org-document-info-keyword ((t ())))
      '(org-document-info ((t ())))
      '(persp-selected-face ((t (:weight bold))))
      '(proof-tactics-name-face ((t ())))
      '(proof-tacticals-name-face ((t ())))
      '(proof-locked-face ((t (:background ,fade))))
      '(proof-queue-face ((t (:background ,bg+))))
      '(proof-error-face ((t (:underline ,red))))
      '(proof-warning-face ((t (:underline ,warning))))
      '(proof-declaration-name-face ((t (:weight bold))))
      '(coq-cheat-face ((t (:foreground ,bg :background ,red))))
      '(coq-solve-tactics-face ((t ())))
      '(company-coq-coqdoc-h1-face ((t (:weight bold))))
      '(company-coq-coqdoc-h2-face ((t (:weight bold))))
      '(company-coq-coqdoc-h2-face ((t (:weight bold))))
      '(company-coq-coqdoc-h2-face ((t (:weight bold))))
      '(elixir-atom-face ((t ())))
      '(elixir-attribute-face ((t (:foreground ,docs))))
      '(haskell-pragma-face ((t (:weight bold :foreground ,docs))))
      '(merlin-type-face ((t (:weight bold :background ,bg+))))
      '(diff-header ((t (:weight bold))))
      '(diff-context ((t ())))
      '(diff-file-header ((t (:foreground ,docs))))
      '(diff-added ((t (:foreground ,green))))
      '(diff-removed ((t (:foreground ,red))))
      '(diff-changed ((t (:foreground ,yellow))))
      '(diff-hl-change ((t (:foreground ,fade :background ,yellow))))
      '(diff-hl-insert ((t (:foreground ,fade :background ,green))))
      '(diff-hl-delete ((t (:foreground ,fade :background ,red))))
      '(flycheck-info ((t (:underline ,green))))
      '(flycheck-error ((t (:underline ,red))))
      '(flycheck-warning ((t (:underline ,warning))))
      '(flycheck-fringe-info ((t (:foreground ,green))))
      '(flycheck-fringe-error ((t (:foreground ,red))))
      '(flycheck-fringe-warning ((t (:foreground ,warning))))
      '(flyspell-incorrect ((t (:underline ,red))))
      '(flyspell-duplicate ((t (:underline ,warning))))
      '(fringe ((t (()))))
      '(git-commit-summary ((t ())))
      '(git-commit-overlong-summary ((t (:foreground ,red))))
      '(git-commit-nonempty-second-line ((t (:foreground ,red))))
      '(git-commit-comment-heading ((t (:foreground ,docs))))
      '(git-commit-comment-branch-local ((t (:foreground ,docs :weight bold))))
      '(git-commit-comment-branch-remote ((t (:foreground ,docs :weight bold))))
      '(git-commit-comment-action ((t (:foreground ,docs))))
      '(git-commit-comment-file ((t (:foreground ,docs))))
      '(magit-diff-file-heading ((t (:weight bold))))
      '(magit-diff-hunk-heading ((t (:foreground ,fade :slant italic))))
      '(magit-diff-hunk-heading-highlight ((t (:slant italic))))
      '(magit-diff-lines-heading ((t (:background ,docs :foreground ,bg))))
      '(magit-header ((t (:weight bold))))
      '(magit-section-highlight ((t (:background ,current-line))))
      '(magit-section-heading ((t (:weight bold))))
      '(magit-section-heading-selection ((t ())))
      '(magit-selection-title ((t ())))
      '(magit-selection-highlight ((t ())))
      '(magit-selection ((t ())))
      '(magit-diff-context ((t ())))
      '(magit-diff-context-highlight ((t ())))
      '(magit-diff-removed-highlight ((t (:foreground ,red))))
      '(magit-diff-removed ((t (:foreground ,red))))
      '(magit-diff-added-highlight ((t (:foreground ,green))))
      '(magit-diff-added ((t (:foreground ,green))))
      '(magit-log-author ((t (:foreground ,fg))))
      '(magit-log-date ((t (:foreground ,fade))))
      '(magit-branch-local ((t (:foreground ,docs))))
      '(magit-branch-remote ((t (:foreground ,warning))))
      '(magit-hash ((t (:foreground ,fade))))
      '(diff-refine-added ((t (:foreground ,bg :background ,green))))
      '(diff-refine-removed ((t (:foreground ,bg :background ,red))))
      '(markdown-header-delimiter-face ((t (:foreground ,docs :weight bold))))
      '(markdown-header-face-1 ((t (:foreground ,docs :weight bold))))
      '(markdown-header-face-2 ((t (:foreground ,docs :weight bold))))
      '(markdown-header-face-3 ((t (:foreground ,docs :weight bold))))
      '(markdown-header-face-4 ((t (:foreground ,docs :weight bold))))
      '(markdown-header-face-5 ((t (:foreground ,docs :weight bold))))
      '(markdown-header-face-6 ((t (:foreground ,docs :weight bold))))
      '(markdown-markup-face ((t ())))
      '(markdown-bold-face ((t (:weight bold))))
      '(markdown-italic-face ((t (:italic t))))
      '(markdown-link-face ((t ())))
      '(markdown-url-face ((t (:underline t))))
      '(font-latex-warning-face ((t (:slant italic))))
      '(font-latex-bold-face ((t (:weight bold))))
      '(font-latex-sedate-face ((t ())))
      '(font-latex-string-face ((t (:weight bold))))
      '(font-latex-math-face ((t ())))
      '(font-latex-italic-face ((t (:slant italic))))
      '(font-latex-superscript-face ((t ())))
      '(font-latex-subscript-face ((t ())))
      '(font-latex-script-char-face ((t ())))
      '(font-latex-sectioning-0-face ((t ())))
      '(font-latex-sectioning-1-face ((t ())))
      '(font-latex-sectioning-2-face ((t ())))
      '(font-latex-sectioning-3-face ((t ())))
      '(font-latex-sectioning-4-face ((t ())))
      '(font-latex-sectioning-5-face ((t ())))
      '(helm-header ((t (:background ,bg+))))
      '(helm-source-header ((t (:background ,bg+))))
      '(helm-match ((t (:weight bold))))
      '(helm-grep-match ((t (:weight bold))))
      '(helm-candidate-number ((t ())))
      '(helm-grep-running ((t ())))
      '(helm-selection ((t (:background ,fg :foreground ,bg))))
      '(helm-ff-prefix ((t ())))
      '(helm-ff-directory ((t (:weight bold))))
      '(helm-ff-dotted-directory ((t (:weight bold))))
      '(variable-pitch ((t ())))
      '(highlight ((t (:background ,fade))))
      '(compilation-warning ((t (:weight bold :underline t))))
      '(compilation-column-number ((t (:underline t))))
      '(tooltip ((t (:foreground ,bg :background ,fg+))))
      '(popup-tip-face ((t (:foreground ,bg :background ,fg+))))
      '(company-tooltip ((t (:foreground ,bg :background ,fg+))))
      '(company-scrollbar-fg ((t (:background ,bg))))
      '(company-scrollbar-bg ((t (:background ,fg))))
      '(company-tooltip-selection ((t (:background ,bg :foreground ,fg))))
      '(company-tooltip-annotation ((t (:foreground ,fade))))
      '(company-tooltip-annotation-selection ((t (:foreground ,fg+))))
      '(company-tooltip-common ((t (:weight bold))))
      '(company-preview-common ((t ())))
      '(company-preview ((t (:background ,fg :foreground ,bg))))
      '(company-posframe-active-backend-name ((t (:foreground ,bg))))
      '(company-posframe-metadata ((t (:foreground ,bg+ :weight bold))))
      '(sh-heredoc ((t (:foreground ,docs :weight bold))))
      '(sh-quoted-exec ((t ())))
      '(tuareg-font-lock-governing-face ((t ())))
      '(tuareg-font-lock-operator-face ((t ())))
      '(tuareg-font-double-colon-face ((t ())))
      '(tab-line ((t (:background ,current-line :foreground ,fg))))
      '(header-line ((t (:background ,current-line :foreground ,fg))))
      '(centaur-tabs-unselected ((t (:background ,current-line :foreground ,fg))))
      '(centaur-tabs-unselected-modified ((t (:background ,current-line :foreground ,fg))))
      '(centaur-tabs-selected ((t (:background ,bg :foreground ,fg))))
      '(centaur-tabs-selected-modified ((t (:background ,bg :foreground ,fg))))
      '(centaur-tabs-active-bar-face ((t (:background ,docs))))
      '(focus-unfocused ((t (:foreground ,fade)))))))

(defmacro colorless-themes-load-theme (theme)
  "Load the theme THEME."
  `(if (daemonp)
       (add-hook 'after-make-frame-functions
                 (lambda (frame)
                   (select-frame frame)
                   (load-theme ,theme t)))
     (load-theme ,theme t)))

(provide 'colorless-themes)
;;; colorless-themes.el ends here
