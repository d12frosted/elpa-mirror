;;; inkpot-theme.el --- A port of vim's inkpot theme -*- lexical-binding: t -*-

;; Author: Sarah Iovan <sarah@hwaetageek.com>
;;         Campbell Barton <ideasman42@gmail.com>
;; URL: https://gitlab.com/ideasman42/emacs-inkpot-theme
;; Package-Version: 20211007.357
;; Package-Commit: d82680ab7a7531a1c9369e65f2714285e43c6688
;; Version: 0.1
;; Package-Requires: ((emacs "24.1"))

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

;; This file is based on Per Vognsen's port of the original vim theme.

;;; Code:

(deftheme inkpot "Dark color scheme with bright easily identifiable colors.")

;; Colors from original Vim theme (for reference)
;; as of https://github.com/ciaranm/inkpot (Feb 11, 2013)

;; Ordered around the color wheel, starting at red.
;; Include VIM usage in comments.

(let ((ip-red-dark              "#6e2e2e") ;; bg:Error
      (ip-red-dark+0.2          "#6d3030") ;; bg:DiffDelete
      (ip-red-mid               "#af4f4b") ;; fg:Title
      (ip-red-light             "#ce4e4e") ;; bg:ErrorMsg
      ;; (ip-red-light+4.5      "#cc6666") ;; sp:SpellBad

      (ip-orange-dark           "#ad600b") ;; fg:doxygenSpecialMultilineDesc fg:doxygenSpecialOnelineDesc
      ;; (ip-orange-dark+12.3   "#ad7b20") ;; bg:doxygenComment
      (ip-orange-bright         "#cd8b00") ;; fg:Comment
      (ip-orange-light          "#df9f2d") ;; fg:Underlined
      ;; (ip-orange-light+11.7  "#fdd090") ;; fg:doxygenParam fg:doxygenPrev fg:doxygenSmallSpecial fg:doxygenSpecial

      (ip-brown-mid             "#ad7b57") ;; bg:Search
      ;; (ip-brown-mid+12.6     "#cd8b60") ;; bg:IncSearch
      (ip-brown-mid+13          "#ce8e4e") ;; bg:WarningMsg
      ;; (ip-brown-mid+13.8     "#d0a060") ;; fg:Folded
      ;; (ip-brown-mid+31.4     "#fdab60") ;; fg:doxygenBrief fg:doxygenSpecial

      (ip-brown-bright          "#f0ad6d") ;; fg:Number
      (ip-brown-light           "#ffcd8b") ;; fg:Constant fg:String
      (ip-brown-light+30.9      "#ffffcd") ;; fg:DiffText fg:DiffChange fg:DiffDelete fg:DiffAdd

      (ip-cream-light           "#cfbfad") ;; fg:Normal fg:MBENormal fg:MatchParen

      ;; (ip-yellow-mid         "#cccc66") ;; sp:SpellLocal
      (ip-yellow-bright         "#ffcd00") ;; fg:Question

      (ip-green-mid             "#306d30") ;; bg:DiffAdd
      (ip-green-bright          "#00ff8b") ;; fg:User1 fg:Directory
      ;; (ip-green-light        "#8fff8b") ;; bg:lCursor

      (ip-cyan-dark             "#306b8f") ;; bg:DiffChange
      (ip-cyan-mid              "#409090") ;; fg:PreProc
      ;; (ip-cyan-bright        "#66cccc") ;; sp:SpellCap

      ;; Use name 'slate' as the palette has many de-saturated blues.
      (ip-slate-dark-inverted   "#b38363")
      (ip-slate-dark            "#1e1e27") ;; bg:Normal
      (ip-slate-dark+7.6        "#2e2e37") ;; bg:CursorLine
      (ip-slate-dark+7.9        "#2e2e3f") ;; bg:MBENormal bg:MBEChanged bg:PmenuSel
      (ip-slate-dark+15.7       "#3e3e5e") ;; bg:StatusLine bg:User1 bg:User2 bg:StatusLineNC bg:VertSplit

      (ip-slate-mid             "#4e4e8f") ;; bg:MBEVisibleNormal bg:MBEVisibleChanged bg:Visual bg:Pmenu bg:MatchParen
      (ip-slate-light           "#7070a0") ;; fg:User2
      (ip-slate-light+5.5       "#7e7eae") ;; fg:ModeMsg fg:MoreMsg
      (ip-slate-light+5.9       "#6e6eaf") ;; bg:WildMenu bg:PmenuSbar bg:PmenuThumb
      (ip-slate-lite+17.7       "#8b8bcd") ;; fg:FoldColumn fg:LineNr fg:NonText

      (ip-blue-bright           "#808bed") ;; fg:Statement fg:TaglistTagName
      (ip-blue-bright+1.6       "#8b8bff") ;; bg:Cursor bg:CursorIM

      ;; (ip-purple-dark        "#3b205d") ;; fg:SpecialKey
      ;; (ip-purple-dark+10.4   "#4b208f") ;; bg:Folded
      ;; (ip-purple-mid         "#4a2a4a") ;; bg:DiffText

      ;; (ip-pink-dark-3.9      "#cc66cc") ;; sp:SpellRare
      (ip-pink-dark             "#c080d0") ;; fg:Special fg:SpecialChar fg:perlSpecialMatch fg:perlSpecialString
      ;;                                      fg:cSpecialCharacter fg:cFormat fg:Conceal
      (ip-pink-light            "#ff8bff") ;; fg:Identifier fg:Type

      ;; Tones.
      (ip-grey+18               "#2e2e2e") ;; bg:FoldColumn bg:LineNr bg:ColorColumn
      (ip-grey+19               "#303030") ;; fg:IncSearch fg:Search fg:Todo
      (ip-grey+25               "#404040") ;; fg:Cursor fg:lCursor fg:CursorIM bg:String bg:SpecialChar
      ;;                                      bg:perlSpecialMatch bg:perlSpecialString bg:cSpecialCharacter bg:cFormat
      (ip-grey+73               "#b9b9b9") ;; fg:StatusLine fg:StatusLineNC fg:VertSplit
      ;; (ip-grey+81            "#cfcfcd") ;; fg:MBEVisibleNormal
      ;; (ip-grey+93            "#eeeeee") ;; fg:WildMenu fg:MBEChanged  fg:MBEVisibleChanged fg:Visual
      ;;                                         fg:Pmenu fg:PmenuSel fg:PmenuSbar fg:PmenuThumb

      (ip-black                 "#000000") ;; bg:Normal
      (ip-white                 "#ffffff") ;; fg:ErrorMsg fg:WarningMsg

      ;; End palette colors.
      )

  (custom-theme-set-faces
   'inkpot

   ;; Basic coloring.
   `(default ((t (:background ,ip-slate-dark :foreground ,ip-cream-light))))
   '(default-italic ((t (:italic t))))
   `(cursor ((t (:background ,ip-blue-bright+1.6))))
   `(escape-glyph ((t (:foreground ,ip-slate-lite+17.7)))) ;; Not matching GVIM, just nice color.
   `(fringe ((t (:background ,ip-grey+18 :foreground ,ip-slate-lite+17.7))))
   `(highlight ((t (:background ,ip-grey+25))))
   `(region ((t (:background ,ip-slate-mid :foreground ,ip-white))))
   ;; Match GVIM secondary selection (which is the background inverted).
   `(secondary-selection ((t (:foreground ,ip-slate-dark-inverted :inverse-video t))))
   ;; Success output.
   `(success ((t (:foreground ,ip-green-bright))))
   `(warning ((t (:foreground ,ip-white :background ,ip-brown-mid+13))))
   `(error ((t (:foreground ,ip-white :background ,ip-red-dark))))
   ;; UI.
   `(button ((t (:underline t :foreground ,ip-pink-light))))
   `(link ((t (:foreground ,ip-pink-light))))
   `(link-visited ((t (:foreground ,ip-pink-dark)))) ;; Not a vim color, just a little darker.
   `(widget-field ((t (:foreground ,ip-pink-dark :background ,ip-yellow-bright)))) ;; FIXME

   ;; Default (font-lock)
   `(font-lock-builtin-face ((t (:foreground ,ip-pink-light))))
   `(font-lock-comment-face ((t (:foreground ,ip-orange-bright))))
   `(font-lock-comment-delimiter-face ((t (:inherit font-lock-comment-face))))
   `(font-lock-doc-face ((t (:foreground ,ip-blue-bright)))) ;; Alternate comment face.
   `(font-lock-constant-face ((t (:foreground ,ip-cyan-mid))))
   `(font-lock-function-name-face ((t (:foreground ,ip-pink-dark))))
   `(font-lock-keyword-face ((t (:foreground ,ip-blue-bright))))
   `(font-lock-preprocessor-face ((t (:foreground ,ip-cyan-mid))))
   `(font-lock-reference-face ((t (:bold t :foreground ,ip-blue-bright))))
   `(font-lock-string-face ((t (:foreground ,ip-brown-light :background ,ip-grey+25))))
   `(font-lock-type-face ((t (:foreground ,ip-pink-light))))
   '(font-lock-variable-name-face ((t nil)))
   `(font-lock-warning-face ((t (:foreground ,ip-white :background ,ip-red-dark))))

   `(font-lock-negation-char-face ((t (:foreground ,ip-cream-light)))) ;; currently no change.
   `(font-lock-regexp-grouping-construct ((t (:foreground ,ip-blue-bright :weight bold))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,ip-pink-dark :weight bold))))

   ;; Mode line.
   ;; Follow GVIM, inactive mode-line isn't bold.
   `(header-line ((t (:bold t :foreground ,ip-grey+73 :background ,ip-slate-dark+15.7
                            :box (:line-width -1 :color ,ip-slate-light)))))
   `(header-line-inactive ((t (:foreground ,ip-grey+73 :background ,ip-slate-dark+15.7
                                           :box (:line-width -1 :color ,ip-slate-light)))))
   `(mode-line ((t (:bold t :foreground ,ip-grey+73 :background ,ip-slate-dark+15.7
                          :box (:line-width -1 :color ,ip-slate-light)))))
   `(mode-line-inactive ((t (:foreground ,ip-grey+73 :background ,ip-slate-dark+15.7
                                         :box (:line-width -1 :color ,ip-slate-light)))))

   `(hl-line ((t (:background ,ip-slate-dark+7.6))))

   `(show-paren-match-face ((t (:background ,ip-slate-mid))))
   `(show-paren-match ((t (:background ,ip-slate-mid))))
   `(show-paren-match-expression ((t (:background ,ip-slate-dark+7.9))))
   ;; GVIM doesn't contain this color, use error color.
   `(show-paren-mismatch ((t (:foreground ,ip-white :background ,ip-red-dark))))

   ;; Note: original theme doesn't show different colors here,
   ;; simply use bold for 'isearch'.
   `(isearch ((t (:bold t :foreground ,ip-grey+19 :background ,ip-brown-mid))))
   `(isearch-fail ((t (:foreground ,ip-white :background ,ip-red-light))))
   `(lazy-highlight ((t (:foreground ,ip-grey+19 :background ,ip-brown-mid))))

   `(minibuffer-prompt ((t (:bold t :foreground ,ip-slate-light+5.5))))

   `(line-number ((t (:background ,ip-grey+18 :foreground ,ip-slate-lite+17.7))))
   `(line-number-current-line ((t (:bold t :background ,ip-slate-dark :foreground ,ip-yellow-bright))))

   ;; white-space.
   '(whitespace-trailing ((nil (:background "#343443" :foreground nil))))
   '(whitespace-space ((nil (:background nil :foreground "#434357"))))
   '(whitespace-tab ((nil (:background nil :foreground "#434357"))))

   ;; xref mode.
   `(xref-line-number ((t (:background ,ip-grey+18 :foreground ,ip-slate-lite+17.7))))

   ;; tab-bar-mode.
   `(tab-bar ((t (:bold t :foreground ,ip-grey+73 :background ,ip-slate-dark+7.6))))
   `(tab-bar-tab ((t (:foreground ,ip-grey+73 :background ,ip-slate-dark+15.7 :box (:line-width -1 :color ,ip-slate-light)))))
   `(tab-bar-tab-inactive ((t (:bold nil :italic t :foreground ,ip-grey+73 :background ,ip-slate-dark+15.7))))

   ;; which-func (shows in the mode-line).
   `(which-func ((t (:bold t :foreground ,ip-grey+73))))

   ;; compilation-mode
   ;;
   ;; Not matching vim, since there doesn't seem to be exact equivalents.
   `(compilation-warning ((t (:foreground ,ip-orange-bright))))
   `(compilation-error ((t (:foreground ,ip-red-mid))))

   ;; diff-mode
   ;;
   ;; Not from the inkpot palette, dark colors so we can see the refined colors properly.
   '(diff-added ((t (:background "#163616"))))
   '(diff-removed ((t (:background "#361616"))))
   ;; Refine colors for emacs 27+.
   `(diff-refine-added ((t (:background ,ip-green-mid))))
   `(diff-refine-removed ((t (:background ,ip-red-dark+0.2))))

   ;; Headers:
   ;; These are displayed grouped.
   `(diff-header ((t (:foreground ,ip-brown-light+30.9 :background ,ip-grey+18))))
   ;; Use the same colors, too many tones here makes diff headers overly busy.
   `(diff-index ((t (:foreground ,ip-brown-light+30.9 :background ,ip-grey+25))))
   `(diff-file-header ((t (:foreground ,ip-brown-light+30.9 :background ,ip-grey+25))))
   ;; These are displayed side-by-side, a rare exception where a black
   ;; background is useful to visually separate content.
   `(diff-hunk-header ((t (:foreground ,ip-cyan-mid :background ,ip-black))))
   `(diff-function ((t (:foreground ,ip-yellow-bright :background ,ip-black))))

   ;; ediff-mode
   `(ediff-current-diff-A ((t (:foreground ,ip-cream-light :background ,ip-red-mid))))
   `(ediff-current-diff-Ancestor ((t (:foreground ,ip-cream-light :background ,ip-red-mid))))
   `(ediff-current-diff-B ((t (:foreground ,ip-cream-light :background ,ip-green-mid))))
   `(ediff-current-diff-C ((t (:foreground ,ip-cream-light :background ,ip-cyan-dark))))
   `(ediff-even-diff-A ((t (:background ,ip-slate-dark+7.6))))
   `(ediff-even-diff-Ancestor ((t (:background ,ip-slate-dark+7.6))))
   `(ediff-even-diff-B ((t (:background ,ip-slate-dark+7.6))))
   `(ediff-even-diff-C ((t (:background ,ip-slate-dark+7.6))))
   `(ediff-fine-diff-A ((t (:foreground ,ip-cream-light :background ,ip-red-light :weight bold))))
   `(ediff-fine-diff-Ancestor ((t (:foreground ,ip-cream-light :background ,ip-red-light weight bold))))
   `(ediff-fine-diff-B ((t (:foreground ,ip-cream-light :background ,ip-green-bright :weight bold))))
   `(ediff-fine-diff-C ((t (:foreground ,ip-cream-light :background ,ip-cyan-mid :weight bold ))))
   `(ediff-odd-diff-A ((t (:background ,ip-slate-dark+15.7))))
   `(ediff-odd-diff-Ancestor ((t (:background ,ip-slate-dark+15.7))))
   `(ediff-odd-diff-B ((t (:background ,ip-slate-dark+15.7))))
   `(ediff-odd-diff-C ((t (:background ,ip-slate-dark+15.7))))

   ;; dired-mode
   `(dired-directory ((t (:foreground ,ip-green-bright))))
   `(dired-header ((t (:foreground ,ip-orange-bright))))
   `(dired-symlink ((t (:bold t :foreground ,ip-yellow-bright))))
   `(dired-broken-symlink ((t (:bold t :foreground ,ip-yellow-bright :background ,ip-red-dark))))

   `(w3m-anchor ((t (:foreground ,ip-pink-dark))))
   `(info-xref ((t (:foreground ,ip-cyan-mid))))
   `(info-menu-star ((t (:foreground ,ip-cyan-mid))))
   `(message-cited-text ((t (:foreground ,ip-orange-bright))))
   '(gnus-cite-face-1 ((t (:foreground "#708090"))))
   `(gnus-cite-face-2 ((t (:foreground ,ip-orange-light))))
   '(gnus-cite-face-3 ((t (:foreground "#ad7fa8"))))
   '(gnus-cite-face-4 ((t (:foreground "#4090904"))))
   `(gnus-group-mail-1-empty-face ((t (:foreground ,ip-pink-dark))))
   `(gnus-group-mail-1-face ((t (:bold t :foreground ,ip-pink-dark))))
   `(gnus-group-mail-2-empty-face ((t (:foreground ,ip-cyan-mid))))
   `(gnus-group-mail-2-face ((t (:bold t :foreground ,ip-cyan-mid))))
   '(gnus-group-mail-3-empty-face ((t (:foreground "#506dbd"))))
   `(gnus-group-mail-3-face ((t (:bold t :foreground ,ip-orange-bright))))
   `(gnus-group-mail-3 ((t (:bold t :foreground ,ip-orange-bright))))
   `(gnus-group-mail-low-empty-face ((t (:foreground ,ip-slate-lite+17.7))))
   `(gnus-group-mail-low-face ((t (:bold t :foreground,ip-slate-lite+17.7))))
   `(gnus-group-news-1-empty-face ((t (:foreground ,ip-pink-dark))))
   `(gnus-group-news-1-face ((t (:bold t :foreground ,ip-pink-dark))))
   `(gnus-group-news-2-empty-face ((t (:foreground ,ip-cyan-mid))))
   `(gnus-group-news-2-face ((t (:bold t :foreground ,ip-cyan-mid))))
   '(gnus-group-news-3-empty-face ((t (:foreground "#506dbd"))))
   '(gnus-group-news-3-empty ((t (:foreground "#506dbd"))))
   `(gnus-group-news-3-face ((t (:bold t :foreground ,ip-orange-bright))))
   `(gnus-group-news-low-empty-face ((t (:foreground,ip-slate-lite+17.7))))
   `(gnus-group-news-low-face ((t (:bold t :foreground,ip-slate-lite+17.7))))
   '(gnus-header-name-face ((t (:bold t :foreground "#ab60ed"))))
   `(gnus-header-from ((t (:bold t :foreground ,ip-orange-bright))))
   `(gnus-header-subject ((t (:foreground ,ip-blue-bright))))
   `(gnus-header-content ((t (:italic t :foreground ,ip-cyan-mid))))
   `(gnus-header-newsgroups-face ((t (:italic t :bold t :foreground ,ip-pink-light))))
   '(gnus-signature-face ((t (:italic t :foreground "#708090"))))
   `(gnus-summary-cancelled-face ((t (:foreground ,ip-orange-bright))))
   `(gnus-summary-cancelled ((t (:foreground ,ip-orange-bright))))
   '(gnus-summary-high-ancient-face ((t (:bold t :foreground "#ab60ed"))))
   `(gnus-summary-high-read-face ((t (:bold t :foreground ,ip-pink-dark))))
   `(gnus-summary-high-ticked-face ((t (:bold t :foreground ,ip-red-mid))))
   `(gnus-summary-high-unread-face ((t (:bold t :foreground ,ip-brown-light))))
   `(gnus-summary-low-ancient-face ((t (:italic t :foreground ,ip-pink-dark))))
   '(gnus-summary-low-read-face ((t (:italic t :foreground "#ab60ed"))))
   `(gnus-summary-low-ticked-face ((t (:italic t :foreground ,ip-red-mid))))
   `(gnus-summary-low-unread-face ((t (:italic t :foreground ,ip-brown-light))))
   `(gnus-summary-normal-ancient-face ((t (:foreground ,ip-slate-lite+17.7))))
   '(gnus-summary-normal-read-face ((t (:foreground "#2e3436"))))
   '(gnus-summary-normal-read ((t (:foreground "#2e3436"))))
   `(gnus-summary-normal-ticked-face ((t (:foreground ,ip-red-mid))))
   `(gnus-summary-normal-unread-face ((t (:foreground ,ip-brown-light))))
   `(gnus-summary-selected ((t (:background ,ip-grey+25 :foreground ,ip-brown-light))))
   `(gnus-header-from ((t (:bold t :foreground ,ip-orange-bright))))
   '(message-header-name-face ((t (:foreground "#ab60ed"))))
   '(message-header-name ((t (:foreground "#ab60ed"))))
   `(message-header-newsgroups-face ((t (:italic t :bold t :foreground ,ip-pink-light))))
   `(message-header-other-face ((t (:foreground ,ip-cyan-mid))))
   `(message-header-other ((t (:foreground ,ip-cyan-mid))))
   `(message-header-xheader-face ((t (:foreground ,ip-cyan-mid))))
   `(message-header-subject ((t (:foreground ,ip-blue-bright))))
   `(message-header-to ((t (:foreground ,ip-orange-bright))))
   `(message-header-cc ((t (:foreground ,ip-cyan-mid))))
   `(font-latex-bold-face ((t (:foreground ,ip-orange-bright))))
   `(font-latex-italic-face ((t (:foreground ,ip-blue-bright :italic t))))
   '(font-latex-string-face ((t (:foreground "#708090"))))
   '(font-latex-match-reference-keywords ((t (:foreground "#708090"))))
   '(font-latex-match-variable-keywords ((t (:foreground "#708090"))))

   ;; Haskell.
   `(haskell-operator-face ((t (:foreground ,ip-blue-bright))))

   ;; Org-Mode.
   '(org-hide ((t (:foreground "#708090"))))
   `(org-level-1 ((t (:bold t :foreground ,ip-slate-lite+17.7 :height 1.0))))
   `(org-level-2 ((t (:bold nil :foreground ,ip-cyan-mid :height 1.0))))
   `(org-level-3 ((t (:bold t :foreground ,ip-orange-light :height 1.0))))
   `(org-level-4 ((t (:bold nil :foreground ,ip-red-mid :height 1.0))))
   `(org-date ((t (:underline t :foreground ,ip-brown-bright))))
   `(org-footnote ((t (:underline t :foreground ,ip-orange-dark))))
   '(org-link ((t (:underline t :foreground "#708090"))))
   `(org-special-keyword ((t (:foreground ,ip-orange-dark))))
   `(org-verbatim ((t (:foreground ,ip-brown-light :background ,ip-grey+25))))
   `(org-code ((t (:foreground ,ip-brown-light :background ,ip-grey+25))))
   '(org-block ((t (:foreground "#708090"))))
   '(org-quote ((t (:inherit org-block :slant italic))))
   '(org-verse ((t (:inherit org-block :slant italic))))
   `(org-todo ((t (:bold t :foreground ,ip-red-mid))))
   `(org-done ((t (:bold t :foreground ,ip-cyan-mid))))
   `(org-warning ((t (:underline t :foreground ,ip-cyan-mid))))
   `(org-agenda-structure ((t (:weight bold :foreground ,ip-red-mid))))
   `(org-agenda-date ((t (:foreground ,ip-cyan-mid))))
   `(org-agenda-date-weekend ((t (:weight normal :foreground,ip-slate-lite+17.7))))
   `(org-agenda-date-today ((t (:weight bold :foreground ,ip-orange-bright))))

   ;; reStructuredText.
   `(rst-external ((t (:foreground ,ip-pink-light))))
   `(rst-definition ((t (:foreground ,ip-cyan-mid))))
   `(rst-directive ((t (:foreground ,ip-blue-bright))))
   '(rst-emphasis1 ((t (:italic t))))
   '(rst-emphasis2 ((t (:weight bold t))))
   `(rst-reference ((t (:foreground ,ip-pink-light))))
   ;; titles baseline.
   `(rst-adornment ((t (:foreground ,ip-red-mid))))
   ;; titles.
   `(rst-level-1 ((t (:foreground ,ip-red-mid))))
   `(rst-level-2 ((t (:foreground ,ip-red-mid))))
   `(rst-level-3 ((t (:foreground ,ip-red-mid))))
   `(rst-level-4 ((t (:foreground ,ip-red-mid))))
   `(rst-level-5 ((t (:foreground ,ip-red-mid))))
   `(rst-level-6 ((t (:foreground ,ip-red-mid))))

   ;; Colors for popular plugins.

   ;; highlight-numbers (melpa).
   `(highlight-numbers-number ((t (:foreground ,ip-brown-bright))))

   ;; diff-hl (melpa)
   ;; Use brighter colors to stand out from fringe.
   `(diff-hl-insert ((t (:background ,ip-green-mid))))
   `(diff-hl-delete ((t (:background ,ip-red-mid))))
   `(diff-hl-change ((t (:background ,ip-slate-mid))))

   ;; lsp-mode (melpa).
   `(lsp-face-highlight-read ((t (:background ,ip-slate-dark+7.9))))
   `(lsp-face-highlight-write ((t (:background ,ip-slate-dark+7.9))))
   `(lsp-face-highlight-textual ((t (:background ,ip-slate-dark+7.9))))

   ;; auto-complete (melpa).
   `(ac-candidate-face ((t (:foreground ,ip-white :background ,ip-slate-mid))))
   `(ac-selection-face ((t (:foreground ,ip-white :background ,ip-slate-dark+7.9 :weight bold))))

   ;; ivy (melpa).
   `(ivy-current-match ((t (:background ,ip-slate-mid :foreground ,ip-white))))
   ;; highlight matching chars (same as isearch).
   `(ivy-minibuffer-match-face-2 ((t (:background ,ip-brown-mid :foreground ,ip-grey+19))))

   ;; company (melpa).
   `(company-tooltip ((t (:background ,ip-slate-mid :foreground ,ip-white))))
   `(company-tooltip-selection ((t (:background ,ip-slate-dark+7.9 :weight bold))))
   `(company-tooltip-annotation ((t (:foreground ,ip-cream-light))))
   `(company-tooltip-common ((t (:foreground ,ip-grey+19 :background ,ip-brown-mid))))

   `(company-scrollbar-bg ((t (:background ,ip-slate-light+5.9))))
   ;; Not based on original theme, could change.
   `(company-scrollbar-fg ((t (:background ,ip-black))))

   ;; helm (melpa).
   `(helm-selection ((t (:background ,ip-slate-dark+7.6))))

   ;; fancy-dabbrev (melpa).
   ;; Colors selected from the palette to be a balance: not too intrusive, not too faded.
   `(fancy-dabbrev-preview-face ((t (:foreground ,ip-slate-light+5.5 :background ,ip-slate-dark+7.6))))

   ;; neotree (melpa).
   `(neo-banner-face ((t (:foreground ,ip-orange-bright))))
   `(neo-header-face ((t (:foreground ,ip-orange-bright))))
   `(neo-root-dir-face ((t (:foreground ,ip-blue-bright))))
   `(neo-dir-link-face ((t (:foreground ,ip-green-bright))))
   `(neo-expand-btn-face ((t (:foreground ,ip-blue-bright))))
   `(neo-file-link-face ((t (:foreground ,ip-cream-light))))

   ;; highlight-indent-guides (melpa).
   `(highlight-indent-guides-odd-face ((t (:background ,ip-slate-dark+15.7))))
   `(highlight-indent-guides-even-face ((t (:background ,ip-slate-dark+7.9))))

   ;; highlight-operators (melpa).
   `(highlight-operators-face ((t (:foreground ,ip-blue-bright))))

   ;; highlight-symbol (melpa).
   ;; Color selected because it's visible without being overly distracting.
   `(highlight-symbol-face ((t (:background ,ip-slate-dark+15.7))))
   ;; idle-highlight-mode (melpa).
   `(idle-highlight ((t (:background ,ip-slate-dark+15.7))))

   ;; visual-indentation-mode (stand alone package).
   `(visual-indentation-light-face ((t (:background ,ip-slate-dark+15.7))))
   `(visual-indentation-dark-face ((t (:background ,ip-slate-dark+7.9))))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'inkpot)

;;; inkpot-theme.el ends here
