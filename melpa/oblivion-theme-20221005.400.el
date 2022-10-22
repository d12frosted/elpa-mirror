;;; oblivion-theme.el --- A port of GEdit oblivion theme -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Author: Campbell Barton <ideasman42@gmail.com>
;; URL: https://codeberg.org/ideasman42/emacs-oblivion-theme
;; Version: 0.1
;; Package-Requires: ((emacs "24.1"))

;;; Commentary:

;; This file is based on GEdit theme of the same name.

;;; Code:

(deftheme oblivion "Dark color scheme based on GEdit's oblivion theme.")

;; See: https://gitlab.gnome.org/GNOME/gtksourceview/-/blob/master/data/styles/oblivion.xml
;; for the latest reference of colors.
(let
  (
    (ob-butter1 "#fce94f")
    (ob-butter2 "#edd400")
    (ob-butter3 "#c4a000")
    (ob-chameleon1 "#8ae234")
    (ob-chameleon2 "#73d216")
    (ob-chameleon3 "#4e9a06")
    (ob-orange1 "#fcaf3e")
    (ob-orange2 "#f57900")
    (ob-orange3 "#ce5c00")
    (ob-skyblue1 "#729fcf")
    (ob-skyblue2 "#3465a4")
    ;; (ob-skyblue3 "#204a87")
    (ob-plum1 "#ad7fa8")
    (ob-plum2 "#75507b")
    ;; (ob-plum3 "#5c3566")
    (ob-chocolate1 "#e9b96e")
    (ob-chocolate2 "#c17d11")
    (ob-chocolate3 "#8f5902")
    (ob-scarletred1 "#ef2929")
    (ob-scarletred2 "#cc0000")
    ;; (ob-scarletred3 "#a40000")
    (ob-aluminium1 "#eeeeec")
    (ob-aluminium2 "#d3d7cf")
    (ob-aluminium3 "#babdb6")
    (ob-aluminium4 "#888a85")
    (ob-aluminium5 "#555753")
    (ob-aluminium6 "#2e3436")
    (ob-white "#ffffff")
    (ob-black "#000000")

    ;; Needed for tints on the background that can show regular text on-top.
    (ob-aluminium6-chameleon3-blend "#3e671e")
    (ob-aluminium6-scarletred3-blend "#691a1b")

    ;; Needed because `ob-skyblue2' is too dark to be visible over the default background color.
    (ob-skyblue1-2-blend "#5382ba")

    (ob-aluminium6-as-green "#1b3602")
    (ob-aluminium6-as-red "#360000")

    ;; Blends, not part of GEdit theme.
    (ob-aluminium6+16 "#464f52")
    (ob-aluminium6+5 "#3a4144"))

  (custom-theme-set-faces 'oblivion

    ;; Basic coloring.
    `(default ((t (:background ,ob-aluminium6 :foreground ,ob-aluminium2))))
    '(default-italic ((t (:italic t))))
    `(cursor ((t (:background ,ob-aluminium2))))
    `(escape-glyph ((t (:foreground ,ob-orange3))))
    `(fringe ((t (:background ,ob-aluminium5 :foreground ,ob-aluminium2))))
    `(highlight ((t (:background ,ob-aluminium5))))
    `(region ((t (:foreground ,ob-aluminium1 :background ,ob-aluminium4))))
    `(secondary-selection ((t (:foreground ,ob-chocolate2 :inverse-video t))))
    ;; Success output.
    `(success ((t (:foreground ,ob-chameleon1))))
    `(warning ((t (:foreground ,ob-aluminium1 :background ,ob-plum1))))
    `(error ((t (:foreground ,ob-aluminium1 :background ,ob-scarletred2))))

    ;; UI.
    `(button ((t (:underline t :foreground ,ob-plum1))))
    `(link ((t (:foreground ,ob-plum1))))
    `(link-visited ((t (:foreground ,ob-plum2)))) ;; Not a GEdit color, just a little darker.
    `(widget-field ((t (:foreground ,ob-plum2 :background ,ob-butter1)))) ;; FIXME
    ;; Follow other window border colors (mode-line in this case), don't blend in with the fringe.
    `(scroll-bar ((t (:foreground ,ob-aluminium4 :background ,ob-aluminium6))))


    ;; Default (font-lock)
    `(font-lock-builtin-face ((t (:foreground ,ob-skyblue1))))
    `(font-lock-comment-face ((t (:foreground ,ob-aluminium4))))
    `(font-lock-comment-delimiter-face ((t (:inherit font-lock-comment-face))))
    `(font-lock-doc-face ((t (:foreground ,ob-skyblue1-2-blend)))) ;; Alternate comment face.
    ;; This doesn't have an equivalent for GEdit.
    `(font-lock-doc-markup-face ((t (:foreground ,ob-plum1))))
    `(font-lock-constant-face ((t (:foreground ,ob-plum1))))
    `(font-lock-function-name-face ((t (:foreground ,ob-skyblue1))))
    `(font-lock-keyword-face ((t (:foreground ,ob-white))))
    `(font-lock-preprocessor-face ((t (:foreground ,ob-plum1))))
    `(font-lock-string-face ((t (:foreground ,ob-butter2))))
    `(font-lock-type-face ((t (:foreground ,ob-chameleon1))))
    `(font-lock-variable-name-face ((t (:foreground ,ob-orange1))))
    `(font-lock-warning-face ((t (:foreground ,ob-aluminium1 :background ,ob-plum1))))

    `(font-lock-negation-char-face ((t (:foreground ,ob-aluminium2)))) ;; currently no change.
    `(font-lock-regexp-grouping-construct ((t (:foreground ,ob-orange1 :weight bold))))
    `(font-lock-regexp-grouping-backslash ((t (:foreground ,ob-orange2 :weight bold))))

    ;; Mode line.
    `(header-line ((t (:foreground ,ob-aluminium6 :background ,ob-aluminium3))))
    `(header-line-inactive ((t (:foreground ,ob-aluminium6 :background ,ob-aluminium4))))
    `(mode-line ((t (:foreground ,ob-aluminium6 :background ,ob-aluminium4))))
    `(mode-line-active ((t (:foreground ,ob-aluminium6 :background ,ob-aluminium3))))
    `(mode-line-inactive ((t (:foreground ,ob-aluminium6 :background ,ob-aluminium4))))
    `(mode-line-buffer-id ((t (:foreground ,ob-aluminium6+5))))

    `(hl-line ((t (:background ,ob-aluminium5))))

    `(show-paren-match-face ((t (:foreground ,ob-chocolate2))))
    ;; Note that bold is not part of the original GEdit theme,
    ;; however it's not visible enough so use bold.
    `(show-paren-match ((t (:foreground ,ob-chocolate2 :bold t))))
    `(show-paren-match-expression ((t (:foreground ,ob-chocolate2))))
    ;; No equivalent from GEdit.
    `
    (show-paren-mismatch
      ((t (:foreground ,ob-scarletred2 :background ,ob-aluminium6-scarletred3-blend))))

    ;; Note: original theme doesn't show different colors here,
    ;; simply use bold for 'isearch'.
    `(isearch ((t (:foreground ,ob-aluminium1 :background ,ob-aluminium4 :bold t))))
    `(isearch-fail ((t (:foreground ,ob-white :background ,ob-scarletred1))))
    `(lazy-highlight ((t (:foreground ,ob-aluminium1 :background ,ob-chameleon3))))

    `(minibuffer-prompt ((t (:foreground ,ob-aluminium2 :bold t))))

    `(line-number ((t (:foreground ,ob-aluminium5 :background ,ob-black))))
    ;; GEdit is same color but bold, this is _NOT_ bright enough.
    `(line-number-current-line ((t (:background ,ob-black :foreground ,ob-butter2 :bold t))))

    ;; white-space.
    `(whitespace-trailing ((nil (:background ,ob-aluminium4 :foreground nil))))
    `(whitespace-space ((nil (:background nil :foreground ,ob-aluminium4))))
    `(whitespace-tab ((nil (:background ,ob-aluminium6+5 :foreground ,ob-aluminium4))))

    ;; xref mode.
    `(xref-line-number ((t (:background ,ob-aluminium6+16 :foreground ,ob-aluminium4))))

    ;; tab-bar-mode.
    `(tab-bar ((t (:bold t :foreground ,ob-aluminium3 :background ,ob-aluminium6+5))))
    `
    (tab-bar-tab
      (
        (t
          (:foreground
            ,ob-aluminium3
            :background ,ob-aluminium6+16
            :box (:line-width -1 :color ,ob-aluminium4)))))
    `
    (tab-bar-tab-inactive
      ((t (:bold nil :italic t :foreground ,ob-aluminium3 :background ,ob-aluminium6+16))))

    ;; which-func (shows in the mode-line).
    `(which-func ((t (:bold t :foreground ,ob-aluminium3))))

    ;; compilation-mode
    ;;
    `(compilation-warning ((t (:foreground ,ob-chocolate2))))
    `(compilation-error ((t (:foreground ,ob-scarletred2))))

    ;; diff-mode
    ;;
    ;; Not from the inkpot palette, dark colors so we can see the refined colors properly.
    `(diff-added ((t (:background ,ob-aluminium6-as-green))))
    `(diff-removed ((t (:background ,ob-aluminium6-as-red))))
    ;; Refine colors for emacs 27+.
    `(diff-refine-added ((t (:background ,ob-aluminium6-chameleon3-blend))))
    `(diff-refine-removed ((t (:background ,ob-aluminium6-scarletred3-blend))))

    ;; Headers:
    ;; These are displayed grouped.
    `(diff-header ((t (:foreground ,ob-aluminium1 :background ,ob-aluminium6+16))))
    ;; Use the same colors, too many tones here makes diff headers overly busy.
    `(diff-index ((t (:foreground ,ob-aluminium1 :background ,ob-aluminium6+16))))
    `(diff-file-header ((t (:foreground ,ob-aluminium1 :background ,ob-aluminium6+16))))
    ;; These are displayed side-by-side, a rare exception where a black
    ;; background is useful to visually separate content.
    `(diff-hunk-header ((t (:foreground ,ob-skyblue1 :background ,ob-black))))
    `(diff-function ((t (:foreground ,ob-butter1 :background ,ob-black))))

    ;; ediff-mode
    `(ediff-current-diff-A ((t (:foreground ,ob-aluminium2 :background ,ob-scarletred2))))
    `(ediff-current-diff-Ancestor ((t (:foreground ,ob-aluminium2 :background ,ob-scarletred2))))
    `(ediff-current-diff-B ((t (:foreground ,ob-aluminium2 :background ,ob-chameleon2))))
    `(ediff-current-diff-C ((t (:foreground ,ob-aluminium2 :background ,ob-skyblue1))))
    `(ediff-even-diff-A ((t (:background ,ob-aluminium6+5))))
    `(ediff-even-diff-Ancestor ((t (:background ,ob-aluminium6+5))))
    `(ediff-even-diff-B ((t (:background ,ob-aluminium6+5))))
    `(ediff-even-diff-C ((t (:background ,ob-aluminium6+5))))
    `
    (ediff-fine-diff-A
      ((t (:foreground ,ob-aluminium2 :background ,ob-scarletred1 :weight bold))))
    `
    (ediff-fine-diff-Ancestor
      ((t (:foreground ,ob-aluminium2 :background ,ob-scarletred1 weight bold))))
    `(ediff-fine-diff-B ((t (:foreground ,ob-aluminium2 :background ,ob-chameleon1 :weight bold))))
    `(ediff-fine-diff-C ((t (:foreground ,ob-aluminium2 :background ,ob-skyblue1 :weight bold))))
    `(ediff-odd-diff-A ((t (:background ,ob-aluminium6+16))))
    `(ediff-odd-diff-Ancestor ((t (:background ,ob-aluminium6+16))))
    `(ediff-odd-diff-B ((t (:background ,ob-aluminium6+16))))
    `(ediff-odd-diff-C ((t (:background ,ob-aluminium6+16))))

    `(font-latex-bold-face ((t (:foreground ,ob-orange1))))
    `(font-latex-italic-face ((t (:foreground ,ob-skyblue2 :italic t))))
    `(font-latex-string-face ((t (:foreground ,ob-skyblue1))))
    `(font-latex-match-reference-keywords ((t (:foreground ,ob-skyblue1))))
    `(font-latex-match-variable-keywords ((t (:foreground ,ob-skyblue1))))

    ;; dired-mode
    `(dired-directory ((t (:foreground ,ob-chameleon1))))
    `(dired-header ((t (:foreground ,ob-chocolate2))))
    `(dired-symlink ((t (:bold t :foreground ,ob-butter1))))
    `(dired-broken-symlink ((t (:bold t :foreground ,ob-butter1 :background ,ob-scarletred2))))

    ;; Haskell.
    `(haskell-operator-face ((t (:foreground ,ob-white))))

    ;; Org-Mode.
    `(org-document-title ((t (:foreground ,ob-white))))
    `(org-hide ((t (:foreground ,ob-aluminium3))))
    `(org-level-1 ((t (:foreground ,ob-skyblue1 :bold t :height 1.0))))
    `(org-level-2 ((t (:foreground ,ob-plum1 :bold t :height 1.0))))
    `(org-level-3 ((t (:foreground ,ob-orange1 :bold t :height 1.0))))
    `(org-level-4 ((t (:foreground ,ob-scarletred1 :bold t :height 1.0))))
    `(org-date ((t (:foreground ,ob-butter1 :underline t))))
    `(org-footnote ((t (:foreground ,ob-orange2 :underline t))))
    `(org-link ((t (:foreground ,ob-aluminium3 :underline t))))
    `(org-special-keyword ((t (:foreground ,ob-orange2))))
    `(org-verbatim ((t (:foreground ,ob-chocolate1 :background ,ob-aluminium6+16))))
    `(org-code ((t (:inherit font-lock-string-face :background ,ob-aluminium6+16))))
    `(org-block ((t (:foreground ,ob-aluminium3))))
    `(org-quote ((t (:inherit org-block :slant italic))))
    `(org-verse ((t (:inherit org-block :slant italic))))
    `(org-todo ((t (:foreground ,ob-scarletred1 :bold t))))
    `(org-done ((t (:foreground ,ob-chameleon1 :bold t))))
    `(org-warning ((t (:foreground ,ob-chameleon1 :underline t))))
    `(org-agenda-structure ((t (:foreground ,ob-scarletred1 :weight bold))))
    `(org-agenda-date ((t (:foreground ,ob-chameleon1))))
    `(org-agenda-date-weekend ((t (:foreground ,ob-skyblue1 :weight normal))))
    `(org-agenda-date-today ((t (:foreground ,ob-butter2 :weight bold))))

    ;; reStructuredText.
    `(rst-external ((t (:foreground ,ob-plum1))))
    `(rst-definition ((t (:foreground ,ob-skyblue1))))
    `(rst-directive ((t (:foreground ,ob-skyblue1))))
    '(rst-emphasis1 ((t (:italic t))))
    '(rst-emphasis2 ((t (:weight bold t))))
    `(rst-reference ((t (:foreground ,ob-plum1))))
    `(rst-literal ((t (:inherit font-lock-string-face :background ,ob-aluminium6+16))))
    ;; titles baseline.
    `(rst-adornment ((t (:foreground ,ob-butter3))))

    ;; titles.
    `(rst-level-1 ((t (:foreground ,ob-butter3))))
    `(rst-level-2 ((t (:foreground ,ob-butter3))))
    `(rst-level-3 ((t (:foreground ,ob-butter3))))
    `(rst-level-4 ((t (:foreground ,ob-butter3))))
    `(rst-level-6 ((t (:foreground ,ob-butter3))))

    ;; `markdown-mode`.
    `
    (markdown-inline-code-face
      ((t (:inherit font-lock-string-face :background ,ob-aluminium6+16))))
    `(markdown-header-face-1 ((t (:foreground ,ob-butter3))))
    `(markdown-header-face-2 ((t (:foreground ,ob-butter3))))
    `(markdown-header-face-3 ((t (:foreground ,ob-butter3))))
    `(markdown-header-face-4 ((t (:foreground ,ob-butter3))))
    `(markdown-header-face-5 ((t (:foreground ,ob-butter3))))
    `(markdown-header-face-6 ((t (:foreground ,ob-butter3))))
    `(markdown-header-rule-face ((t (:foreground ,ob-butter3))))

    ;; Colors for popular plugins.

    ;; highlight-numbers (melpa).
    `(highlight-numbers-number ((t (:foreground ,ob-butter2))))

    ;; diff-hl (melpa)

    `(diff-hl-insert ((t (:background ,ob-chameleon2))))
    `(diff-hl-delete ((t (:background ,ob-scarletred2))))
    `(diff-hl-change ((t (:background ,ob-skyblue2))))

    ;; lsp-mode (melpa).
    `(lsp-face-highlight-read ((t (:background ,ob-aluminium6+5))))
    `(lsp-face-highlight-write ((t (:background ,ob-aluminium6+5))))
    `(lsp-face-highlight-textual ((t (:background ,ob-aluminium6+5))))
    ;; Arbitrary, could be a little lighter?
    `(lsp-face-semhl-comment ((t (:foreground ,ob-aluminium5))))

    ;; Without this, inherit from `font-lock-type-face' face which isn't so nice.
    `(lsp-face-semhl-interface ((t ())))
    `(lsp-face-semhl-parameter ((t (:inherit font-lock-variable-name-face))))
    `(lsp-face-semhl-variable ((t (:inherit font-lock-variable-name-face))))
    `(lsp-face-semhl-constant ((t (:inherit font-lock-variable-name-face))))
    `(lsp-face-semhl-function ((t (:inherit font-lock-function-name-face))))

    ;; magit-commit-mark (melpa).
    `(magit-commit-mark-read-face ((t (:foreground ,ob-skyblue1))))
    `(magit-commit-mark-unread-face ((t (:foreground ,ob-chameleon1))))

    ;; ivy (melpa).
    `(ivy-current-match ((t (:inherit region))))
    `(ivy-grep-info ((t (:foreground ,ob-plum1))))
    ;; highlight matching chars (same as isearch).
    `(ivy-minibuffer-match-face-2 ((t (:background ,ob-chocolate3 :foreground ,ob-aluminium6+16))))

    ;; company (melpa).
    `(company-tooltip ((t (:background ,ob-aluminium4 :foreground ,ob-white))))
    `(company-tooltip-selection ((t (:background ,ob-aluminium6+5 :weight bold))))
    `(company-tooltip-annotation ((t (:foreground ,ob-aluminium2))))
    `(company-tooltip-common ((t (:foreground ,ob-aluminium6+16 :background ,ob-chocolate3))))

    `(company-scrollbar-bg ((t (:background ,ob-aluminium4))))
    ;; Not based on original theme, could change.
    `(company-scrollbar-fg ((t (:background ,ob-black))))

    ;; helm (melpa).
    `(helm-selection ((t (:background ,ob-aluminium6+5))))

    ;; fancy-dabbrev (melpa).
    ;; Colors selected from the palette to be a balance: not too intrusive, not too faded.
    `(fancy-dabbrev-preview-face ((t (:foreground ,ob-aluminium4 :background ,ob-aluminium6+5))))

    ;; neotree (melpa).
    `(neo-banner-face ((t (:foreground ,ob-chocolate2))))
    `(neo-header-face ((t (:foreground ,ob-chocolate2))))
    `(neo-root-dir-face ((t (:foreground ,ob-skyblue2))))
    `(neo-dir-link-face ((t (:foreground ,ob-chameleon1))))
    `(neo-expand-btn-face ((t (:foreground ,ob-skyblue2))))
    `(neo-file-link-face ((t (:foreground ,ob-aluminium2))))

    ;; highlight-indent-guides (melpa).
    `(highlight-indent-guides-odd-face ((t (:background ,ob-aluminium6+16))))
    `(highlight-indent-guides-even-face ((t (:background ,ob-aluminium6+5))))

    ;; hl-indent-scope (melpa).
    `(hl-indent-scope-odd-face ((t (:background ,ob-aluminium6+16))))
    `(hl-indent-scope-even-face ((t (:background ,ob-aluminium6+5))))

    ;; highlight-operators (melpa).
    `(highlight-operators-face ((t (:foreground ,ob-white))))

    ;; highlight-symbol (melpa).
    ;; Color selected because it's visible without being overly distracting.
    `(highlight-symbol-face ((t (:background ,ob-aluminium6+16))))
    ;; idle-highlight-mode (melpa).
    `(idle-highlight ((t (:background ,ob-aluminium6+16))))

    ;; visual-indentation-mode (stand alone package).
    `(visual-indentation-light-face ((t (:background ,ob-aluminium6+16))))
    `(visual-indentation-dark-face ((t (:background ,ob-aluminium6+5))))

    ;; swiper (melpa).
    ;; NOTE: This color is needed as a more subtle tone that doesn't make comments unreadable.
    `(swiper-line-face ((t (:background ,ob-aluminium6+5 :extend t))))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
    (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'oblivion)

;;; oblivion-theme.el ends here
