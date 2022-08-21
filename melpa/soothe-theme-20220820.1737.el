;;; soothe-theme.el --- A dark colorful theme. -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2012-2022 Jason Milkins
;;
;; Author: Jason Milkins <jasonm23@gmail.com>
;; Maintainer: Jason Milkins <jasonm23@gmail.com>
;; URL: https://github.com/emacsfodder/emacs-soothe-theme
;; Package-Version: 20220820.1737
;; Package-Commit: 0cee7400ebc565ce3c2fb81a810062205385aec4
;; Version: 1.1.5
;; Package-Requires: ((emacs "24.3") (autothemer "0.2"))
;;
;; This file is not part of GNU Emacs.
;;
;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;;  A dark colorful theme.
;;
;;; Code:

(require 'autothemer)

(unless (>= emacs-major-version 24)
  (error "Requires Emacs 24 or later"))

(autothemer-deftheme  soothe
                      "A dark colorful theme"
 ((((class color) (min-colors #xFFFFFF))) ;; GUI/24bit only
  (soothe-foreground           "#F4F1ED")
  (soothe-snow-code            "#ECEAE5")
  (soothe-foam                 "#E3E4E2")
  (soothe-dirty-crem           "#DBD9D4")
  (soothe-darker-crem          "#CECCC7")
  (soothe-background-dark-0    "#000000")
  (soothe-background-dark      "#0F0E11")
  (soothe-background           "#111013")
  (soothe-alt-background       "#121113")
  (soothe-dirty-crem-bg        "#2B2A2A")
  (soothe-darker-crem-bg       "#333030")

  (soothe-gray-1               "#AAAAAA")
  (soothe-gray-2               "#828282")
  (soothe-gray-3               "#333333")
  (soothe-gray-4               "#2A2A2A")
  (soothe-gray-5               "#252525")
  (soothe-gray-6               "#202020")
  (soothe-gray-1bg             "#0A0A0A")
  (soothe-gray-2bg             "#111111")
  (soothe-gray-3bg             "#141414")

  (soothe-red-1                "#B14E41")
  (soothe-orange-1             "#D9662E")
  (soothe-yellow-1             "#CEB666")
  (soothe-green-1              "#7D9F51")
  (soothe-blue-1               "#A4B3C9")
  (soothe-purple-1             "#948CB5")

  (soothe-turquoise-1          "#0E545F")
  (soothe-turquoise-2          "#113E46")
  (soothe-turquoise-3          "#0D3239")
  (soothe-turquoise-1bg        "#06181C")
  (soothe-turquoise-2bg        "#051316")
  (soothe-turquoise-3bg        "#15252A")

  (soothe-red-2                "#A24B2E")
  (soothe-red-3                "#AA2010")
  (soothe-red-5                "#4C2020")
  (soothe-orange-2             "#FF642A")
  (soothe-green-2              "#4C8F79")
  (soothe-green-3              "#899F6D")
  (soothe-blue-2               "#407A98")
  (soothe-blue-3               "#0E9090")
  (soothe-blue-4               "#42557A")
  (soothe-purple-3             "#50486C")
  (soothe-purple-4             "#3B3358")

  (soothe-red-1bg              "#1D1717")
  (soothe-red-2bg              "#251F20")
  (soothe-orange-1bg           "#1F1813")
  (soothe-orange-2bg           "#2B211A")
  (soothe-yellow-1bg           "#18140E")
  (soothe-green-2bg            "#272F2D")
  (soothe-green-1bg            "#1B2320")
  (soothe-blue-1bg             "#22272F")
  (soothe-blue-2bg             "#21343E")
  (soothe-blue-3bg             "#162328")
  (soothe-blue-4bg             "#1B2128")
  (soothe-blue-5bg             "#16273A")
  (soothe-purple-1bg           "#1F1E25")
  (soothe-purple-2bg           "#353048")
  (soothe-purple-3bg           "#282436")

  (soothe-bright-red           "#ED6767")
  (soothe-bright-orange        "#D77B00")
  (soothe-bright-green         "#70AC16")
  (soothe-bright-blue          "#2994BF")
  (soothe-bright-purple        "#AC78FA")

  (soothe-muted-red            "#ED8E8E")
  (soothe-muted-orange         "#D7B181")
  (soothe-muted-green          "#90AC67")
  (soothe-muted-blue           "#72A9BF")
  (soothe-muted-purple         "#BD95FA")

  (soothe-overexposed-red      "#F2A9A9")
  (soothe-overexposed-orange   "#F2D0A9")
  (soothe-overexposed-green    "#D4F2A9")
  (soothe-overexposed-blue     "#A9DCF2")
  (soothe-overexposed-purple   "#C6A9F2")

  (soothe-faded-red            "#7F5858")
  (soothe-faded-orange         "#7F6D58")
  (soothe-faded-green          "#6F7F58")
  (soothe-faded-blue           "#58737F")
  (soothe-faded-purple         "#67587F")

  (soothe-mid-red              "#883B3B")
  (soothe-mid-orange           "#8B5000")
  (soothe-mid-green            "#3F610D")
  (soothe-mid-blue             "#195A73")
  (soothe-mid-purple           "#563C7C")

  (soothe-low-red              "#411C1C")
  (soothe-low-orange           "#412500")
  (soothe-low-green            "#2A4107")
  (soothe-low-blue             "#0D3241")
  (soothe-low-purple           "#2C1F41")

  (soothe-dark-red             "#261010")
  (soothe-dark-orange          "#261500")
  (soothe-dark-green           "#182604")
  (soothe-dark-blue            "#071D26")
  (soothe-dark-purple          "#1A1226")

  (soothe-bg-red               "#190A0A")
  (soothe-bg-orange            "#190E00")
  (soothe-bg-green             "#101902")
  (soothe-bg-blue              "#041319")
  (soothe-bg-purple            "#110C19")

  (soothe-rainbow-delimiters-0 "#476121")
  (soothe-rainbow-delimiters-1 "#306173")
  (soothe-rainbow-delimiters-2 "#65557C")
  (soothe-rainbow-delimiters-3 "#8B5100")
  (soothe-rainbow-delimiters-4 "#885757")
  (soothe-rainbow-delimiters-5 "#566752")
  (soothe-rainbow-delimiters-6 "#4F7B75")
  (soothe-rainbow-delimiters-7 "#4A646F")
  (soothe-rainbow-delimiters-8 "#71687B")
  (soothe-rainbow-delimiters-9 "#503E69"))

 ((default                                   (:foreground soothe-foreground  :background soothe-background))
  (cursor                                    (:background soothe-orange-1))
  (region                                    (:background soothe-blue-5bg))
  (secondary-selection                       (:background soothe-turquoise-3bg))
  (match                                     (:background soothe-blue-4bg))
  (highlight                                 (:background soothe-blue-5bg))
  (hl-line                                   (:background soothe-turquoise-3bg))
  (minibuffer-prompt                         (:foreground soothe-orange-1    :background soothe-orange-1bg))
  (escape-glyph                              (:foreground soothe-red-1       :background soothe-purple-1bg))
  (error                                     (:foreground soothe-red-1       :background soothe-red-1bg))
  (font-lock-builtin-face                    (:foreground soothe-red-2       :background soothe-red-1bg))
  (font-lock-constant-face                   (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (font-lock-comment-face                    (:foreground soothe-purple-1    :background soothe-alt-background :italic t))
  (font-lock-comment-delimiter-face          (:foreground soothe-turquoise-1 :background soothe-alt-background :italic t))
  (font-lock-doc-face                        (:foreground soothe-blue-3      :background soothe-gray-1bg))
  (font-lock-doc-string-face                 (:foreground soothe-blue-3      :background soothe-gray-1bg))
  (font-lock-function-name-face              (:foreground soothe-red-1       :background soothe-red-1bg))
  (font-lock-keyword-face                    (:foreground soothe-orange-1    :background soothe-orange-1bg))
  (font-lock-negation-char-face              (:foreground soothe-yellow-1    :background soothe-yellow-1bg))
  (font-lock-preprocessor-face               (:foreground soothe-orange-1    :background soothe-orange-1bg))
  (font-lock-string-face                     (:foreground soothe-blue-3      :background soothe-turquoise-2bg))
  (font-lock-type-face                       (:foreground soothe-red-2       :background soothe-red-1bg        :bold nil))
  (font-lock-variable-name-face              (:foreground soothe-blue-1      :background soothe-blue-1bg))
  (font-lock-warning-face                    (:foreground soothe-red-2       :background soothe-red-2bg))
  (link                                      (:foreground soothe-blue-1      :background soothe-blue-1bg))
  (link-visited                              (:foreground soothe-blue-3      :background soothe-blue-4bg))
  (fringe                                    (:background soothe-gray-3bg))
  (vertical-border                           (:foreground soothe-gray-4      :background soothe-background))
  (mode-line                                 (:foreground soothe-gray-2      :background soothe-gray-3bg  :box nil))
  (mode-line-inactive                        (:foreground soothe-gray-5      :background soothe-gray-2bg  :inherit 'mode-line))
  (mode-line-highlight                       (:foreground soothe-red-1))
  (mode-line-buffer-id                       (:foreground soothe-orange-1))
  (mode-line-emphasis                        (:bold t))
  (which-func                                (:foreground soothe-blue-1))
  (isearch                                   (:foreground soothe-foam        :background soothe-purple-2bg))
  (isearch-fail                              (:foreground soothe-foam        :background soothe-red-5))
  (lazy-highlight                            (:foreground soothe-purple-1    :background soothe-green-2bg))
  (success                                   (:foreground soothe-foam        :background soothe-mid-blue))

  (ediff-current-diff-A                      (:background soothe-bg-red))
  (ediff-current-diff-B                      (:background soothe-turquoise-1bg))
  (ediff-current-diff-C                      (:background soothe-bg-green))
  (ediff-current-diff-Ancestor               (:background soothe-dark-blue))
  (ediff-fine-diff-A                         (:background soothe-dark-red))
  (ediff-fine-diff-B                         (:background soothe-turquoise-2bg))
  (ediff-fine-diff-C                         (:background soothe-dark-green))
  (ediff-fine-diff-Ancestor                  (:background soothe-bg-blue))
  (ediff-even-diff-A                         (:background soothe-dark-red))
  (ediff-even-diff-B                         (:background soothe-turquoise-3))
  (ediff-even-diff-C                         (:background soothe-bg-green))
  (ediff-even-diff-Ancestor                  (:background soothe-dark-blue))
  (ediff-odd-diff-A                          (:background soothe-red-2bg))
  (ediff-odd-diff-B                          (:background soothe-turquoise-3))
  (ediff-odd-diff-C                          (:background soothe-green-1bg))
  (ediff-odd-diff-Ancestor                   (:background soothe-bg-blue))

  (ivy-cursor                                (:foreground soothe-foam :background soothe-turquoise-3bg))
  (ivy-current-match                         (:inherit 'match))
  (ivy-minibuffer-match-highlight            (:inherit 'highlight))
  (ivy-minibuffer-match-face-1               (:inherit 'match))
  (ivy-minibuffer-match-face-2               (:inherit 'highlight))
  (ivy-minibuffer-match-face-3               (:inherit 'secondary-selection))
  (ivy-minibuffer-match-face-4               (:inherit 'region))
  (ivy-confirm-face                          (:foreground soothe-rainbow-delimiters-0 :inherit 'minibuffer-prompt))
  (ivy-match-required-face                   (:foreground soothe-red-3 :inherit 'minibuffer-prompt))
  (ivy-subdir                                (:inherit 'dired-directory))
  (ivy-org                                   (:inherit 'org-level-4))
  (ivy-modified-buffer                       (:inherit 'default))
  (ivy-modified-outside-buffer               (:inherit 'default))
  (ivy-remote                                (:foreground soothe-blue-5bg))
  (ivy-virtual                               (:inherit 'font-lock-builtin-face))
  (ivy-action                                (:inherit 'font-lock-builtin-face))
  (ivy-highlight-face                        (:inherit 'highlight))
  (ivy-prompt-match                          (:inherit 'ivy-current-match))
  (ivy-separator                             (:inherit 'font-lock-doc-face))
  (ivy-grep-info                             (:inherit 'compilation-info))
  (ivy-grep-line-number                      (:inherit 'compilation-line-number))
  (ivy-completions-annotations               (:inherit 'completions-annotations))
  (ivy-yanked-word                           (:inherit 'highlight))

  (ac-selection-face                         (:foreground soothe-dirty-crem  :background soothe-dirty-crem-bg))
  (ac-candidate-face                         (:foreground soothe-background  :background soothe-dirty-crem))
  (ac-yasnippet-candidate-face               (:foreground soothe-background  :background soothe-green-2))
  (ac-yasnippet-selection-face               (:foreground soothe-foam        :background soothe-dirty-crem-bg))
  (ac-gtags-candidate-face                   (:foreground soothe-background  :background soothe-purple-3))
  (ac-gtags-selection-face                   (:foreground soothe-dirty-crem  :background soothe-dirty-crem-bg))
  (ac-candidate-mouse-face                   (:foreground soothe-foam        :background soothe-turquoise-1))
  (ac-completion-face                        (:foreground soothe-snow-code   :background soothe-purple-3bg))
  (popup-tip-face                            (:foreground soothe-dirty-crem     :background soothe-dirty-crem-bg))
  (tooltip                                   (:foreground soothe-dirty-crem-bg  :background soothe-dirty-crem))
  (dired-filename                            (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (dired-directory                           (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (dired-flagged                             (:foreground soothe-red-1       :background soothe-orange-1bg))
  (dired-header                              (:foreground soothe-orange-1    :background soothe-background))
  (dired-ignored                             (:foreground soothe-turquoise-1 :background soothe-background))
  (dired-mark                                (:foreground soothe-orange-2    :background soothe-background))
  (dired-marked                              (:foreground soothe-green-3     :background soothe-orange-1bg))
  (dired-perm-write                          (:foreground soothe-foam        :background soothe-background))
  (dired-symlink                             (:foreground soothe-blue-1      :background soothe-blue-4bg))
  (dired-warning                             (:foreground soothe-red-1       :background soothe-red-2bg))

  (diredfl-filename                          (:inherit 'dired-filename))
  (diredfl-directory                         (:inherit 'dired-directory))
  (diredfl-flagged                           (:inherit 'dired-flagged))
  (diredfl-header                            (:inherit 'dired-header))
  (diredfl-ignored                           (:inherit 'dired-ignored))
  (diredfl-mark                              (:inherit 'dired-mark))
  (diredfl-marked                            (:inherit 'dired-marked))
  (diredfl-perm-write                        (:inherit 'dired-perm-write))
  (diredfl-symlink                           (:inherit 'dired-symlink))
  (diredfl-warning                           (:inherit 'dired-warning))

  (js3-error-face                            (:underline (:color soothe-red-1 :style 'wave)    :background soothe-red-1bg))
  (js3-warning-face                          (:underline (:color soothe-yellow-1 :style 'wave) :background soothe-yellow-1bg))
  (js3-external-variable-face                (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (js3-function-param-face                   (:foreground soothe-blue-3      :background soothe-blue-3bg))
  (js3-instance-member-face                  (:foreground soothe-dirty-crem  :background soothe-purple-1bg))
  (js3-magic-paren-face                      (:foreground soothe-snow-code   :background soothe-purple-1bg))
  (js3-private-function-call-face            (:foreground soothe-orange-1    :background soothe-orange-1bg))
  (js3-private-member-face                   (:foreground soothe-orange-2    :background soothe-orange-1bg))
  (js3-jsdoc-html-tag-delimiter-face         (:foreground soothe-blue-4      :background soothe-blue-2bg))
  (js3-jsdoc-html-tag-name-face              (:foreground soothe-foam        :background soothe-blue-3bg))
  (js3-jsdoc-tag-face                        (:foreground soothe-green-3     :background soothe-green-2bg))
  (js3-jsdoc-type-face                       (:foreground soothe-green-2     :background soothe-green-2bg))
  (js3-jsdoc-value-face                      (:foreground soothe-green-1     :background soothe-green-1bg))

  (diff-changed-unspcified                   (:foreground soothe-overexposed-purple    :background soothe-dark-purple))
  (diff-changed                              (:foreground soothe-overexposed-purple    :background soothe-dark-purple))
  (diff-added                                (:foreground soothe-overexposed-green     :background soothe-dark-green))
  (diff-removed                              (:foreground soothe-overexposed-red       :background soothe-dark-red))
  (diff-function                             (:foreground soothe-foam                  :background soothe-dark-orange))

  (diff-refine-changed                       (:inherit 'diff-changed))
  (diff-refine-added                         (:inherit 'diff-added))
  (diff-refine-removed                       (:inherit 'diff-removed))

  (smerge-refined-changed                    (:inherit 'diff-changed))
  (smerge-refined-added                      (:inherit 'diff-added))
  (smerge-refined-removed                    (:inherit 'diff-removed))
  (smerge-base                               (:inherit 'diff-context))

  (smerge-markers                            (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (smerge-upper                              (:background soothe-blue-1bg))
  (smerge-lower                              (:background soothe-turquoise-1bg))

  (diff-file-header                          (:foreground soothe-orange-1    :background soothe-orange-1bg))
  (diff-context                              (:foreground soothe-foam))
  (diff-hunk-header                          (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (diff-hl-insert                            (:foreground soothe-green-1     :background soothe-green-2bg))
  (diff-hl-delete                            (:foreground soothe-red-1       :background soothe-red-1bg))
  (diff-hl-change                            (:foreground soothe-purple-1    :background soothe-purple-1bg))

  (linum                                     (:foreground soothe-gray-6 :background soothe-alt-background))
  (show-paren-match                          (:foreground soothe-foam        :background soothe-orange-1bg))
  (show-paren-mismatch                       (:foreground soothe-orange-1    :background soothe-red-2bg))

  (swiper-match-face-1                       (:inherit 'lazy-highlight))
  (swiper-match-face-2                       (:inherit 'isearch))
  (swiper-match-face-3                       (:inherit 'match))
  (swiper-match-face-4                       (:inherit 'isearch-fail))
  (swiper-background-match-face-1            (:inherit 'swiper-match-face-1))
  (swiper-background-match-face-2            (:inherit 'swiper-match-face-2))
  (swiper-background-match-face-3            (:inherit 'swiper-match-face-3))
  (swiper-background-match-face-4            (:inherit 'swiper-match-face-4))
  (swiper-line-face                          (:inherit 'match))

  (ido-only-match                            (:foreground soothe-green-1     :background soothe-green-1bg))
  (ido-subdir                                (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (ido-first-match                           (:foreground soothe-orange-1    :background soothe-orange-1bg))
  (ido-incomplete-regexp                     (:foreground soothe-red-1       :background soothe-orange-1bg))
  (ido-indicator                             (:foreground soothe-turquoise-1 :background soothe-turquoise-1bg))
  (ido-virtual                               (:foreground soothe-green-3     :background soothe-turquoise-1bg))
  (whitespace-empty                          (:foreground soothe-yellow-1    :background soothe-turquoise-2bg))
  (whitespace-hspace                         (:foreground soothe-turquoise-2 :background soothe-turquoise-2bg))
  (whitespace-indentation                    (:foreground soothe-turquoise-2 :background soothe-turquoise-2bg))
  (whitespace-line                           (:foreground soothe-orange-1    :background soothe-turquoise-2bg))
  (whitespace-newline                        (:foreground soothe-turquoise-2 :background soothe-turquoise-2bg))
  (whitespace-space                          (:foreground soothe-turquoise-2 :background soothe-turquoise-2bg))
  (whitespace-space-after-tab                (:foreground soothe-turquoise-2 :background soothe-turquoise-2bg))
  (whitespace-tab                            (:foreground soothe-turquoise-2 :background soothe-turquoise-2bg))
  (whitespace-trailing                       (:foreground soothe-red-1       :background soothe-turquoise-2bg))
  (flyspell-incorrect                        (:underline soothe-red-2))
  (flyspell-duplicate                        (:underline soothe-green-2))
  (flymake-errline                           (:underline soothe-red-2        :background nil :inherit nil))
  (flymake-warnline                          (:underline soothe-green-2      :background nil :inherit nil))
  (dropdown-list-selection-face              (:foreground soothe-foam        :background soothe-purple-1bg))
  (dropdown-list-face                        (:foreground soothe-background  :background soothe-foam))

  (git-gutter:added                          (:foreground soothe-green-1     :background soothe-green-2bg))
  (git-gutter:deleted                        (:foreground soothe-red-1       :background soothe-red-1bg))
  (git-gutter:modified                       (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (git-gutter:unchanged                      (:background soothe-yellow-1bg))

  (magit-item-highlight                      (:background soothe-purple-3bg))
  (magit-branch                              (:foreground soothe-orange-1     :background soothe-orange-2bg))
  (magit-branch-remote                       (:foreground soothe-orange-1     :background soothe-orange-2bg))
  (magit-whitespace-warning-face             (:foreground soothe-red-3       :background soothe-red-1bg))
  (magit-section-heading                     (:foreground soothe-orange-1    :background soothe-purple-1bg))
  (magit-section-title                       (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (magit-section-highlight                   (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (magit-section-highlight-selection         (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (magit-header                              (:foreground soothe-orange-1    :background soothe-orange-1bg))
  (magit-hash                                (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (magit-tag                                 (:foreground soothe-orange-1    :background soothe-orange-1bg))
  (magit-item-mark                           (:foreground soothe-green-1))

  (magit-diff-added-highlight                (:foreground soothe-foam :background soothe-dark-green))
  (magit-diff-removed-highlight              (:foreground soothe-foam :background soothe-dark-red))

  (magit-diff-added                          (:foreground soothe-foam :background soothe-bg-green))
  (magit-diff-removed                        (:foreground soothe-foam :background soothe-bg-red))

  (magit-diffstat-added                      (:foreground soothe-overexposed-green))
  (magit-diffstat-removed                    (:foreground soothe-overexposed-red))

  (magit-diff-merge-proposed                 (:foreground soothe-foam))
  (magit-diff-merge-current                  (:foreground soothe-blue-1))
  (magit-diff-merge-separator                (:foreground soothe-blue-2))

  (magit-diff-context-highlight              (:background soothe-alt-background))

  (magit-diff-file-heading                   (:weight 'bold :extend t))
  (magit-diff-file-heading-highlight         (:extend t :inherit 'magit-section-highlight))
  (magit-diff-file-heading-selection         (:extend t :foreground soothe-yellow-1 :inherit 'magit-diff-file-heading-highlight))
  (magit-diff-hunk-heading                   (:extend t :foreground soothe-foreground :background soothe-low-purple))
  (magit-diff-hunk-heading-highlight         (:extend t :foreground soothe-foreground :background soothe-low-purple))
  (magit-diff-hunk-heading-selection         (:extend t :foreground soothe-yellow-1 :inherit 'magit-diff-hunk-heading-highlight))

  (magit-diff-lines-heading                  (:extend t :foreground soothe-darker-crem :background soothe-red-2 :inherit 'magit-diff-hunk-heading-highlight))

  (magit-diff-hunk-region                    (:extend t :inherit 'bold))

  (magit-diff-revision-summary               (:inherit 'magit-diff-hunk-heading))
  (magit-diff-revision-summary-highlight     (:inherit 'magit-diff-hunk-heading-highlight))
  (magit-diff-lines-boundary                 (:extend t :inherit 'magit-diff-lines-heading))
  (magit-diff-conflict-heading               (:inherit 'magit-diff-hunk-heading))

  (magit-diff-our                            (:inherit 'magit-diff-removed))
  (magit-diff-base                           (:extend t :foreground soothe-foreground :background soothe-rainbow-delimiters-0))
  (magit-diff-their                          (:inherit 'magit-diff-added))
  (magit-diff-context                        (:extend t :foreground soothe-gray-1))
  (magit-diff-base-highlight                 (:extend t :foreground soothe-snow-code :background soothe-rainbow-delimiters-0))
  (magit-diff-our-highlight                  (:inherit 'magit-diff-removed-highlight))
  (magit-diff-their-highlight                (:inherit 'magit-diff-added-highlight))
  (magit-diff-whitespace-warning             (:inherit 'trailing-whitespace))

  (magit-branch-current                      (:foreground soothe-purple-1    :background soothe-purple-1bg :box (:line-width -1 :color soothe-purple-1)))
  (magit-branch-local                        (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (magit-log-author                          (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (magit-log-author                          (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (magit-log-graph                           (:foreground soothe-blue-2      :background soothe-blue-2bg))
  (magit-log-head-label-bisect-good          (:foreground soothe-turquoise-1 :background soothe-turquoise-1bg))
  (magit-log-head-label-local                (:foreground soothe-foam        :background soothe-turquoise-1bg))
  (magit-log-head-label-remote               (:foreground soothe-foam        :background soothe-purple-2bg))
  (magit-log-message                         (:foreground soothe-dirty-crem  :background soothe-background))
  (magit-log-date                            (:foreground soothe-blue-4      :background soothe-background))
  (magit-log-head-label-bisect-bad           (:foreground soothe-red-1       :background soothe-red-1bg))
  (magit-log-head-label-default              (:foreground soothe-foam        :background soothe-turquoise-1bg))
  (magit-log-head-label-patches              (:foreground soothe-blue-2      :background soothe-blue-1bg))
  (magit-log-head-label-tags                 (:foreground soothe-orange-1    :background soothe-orange-1bg))
  (magit-log-sha1                            (:foreground soothe-turquoise-1 :background soothe-turquoise-1bg))

  (markdown-header-face-1                    (:height 1.9 :inherit 'variable-pitch :foreground soothe-overexposed-purple))
  (markdown-header-face-2                    (:height 1.8 :inherit 'variable-pitch :foreground soothe-overexposed-blue))
  (markdown-header-face-3                    (:height 1.6 :inherit 'variable-pitch :foreground soothe-overexposed-green))
  (markdown-header-face-4                    (:height 1.5 :inherit 'variable-pitch :foreground soothe-overexposed-orange))
  (markdown-header-face-5                    (:height 1.4 :inherit 'variable-pitch :foreground soothe-overexposed-purple))
  (markdown-header-face-6                    (:height 1.3 :inherit 'variable-pitch :foreground soothe-overexposed-blue))

  (iedit-occurrence                          (:foreground soothe-green-3   :background soothe-turquoise-2bg))
  (iedit-read-only-occurrence                (:foreground soothe-red-1     :background soothe-orange-2bg))

  (highlight-indentation-face                (:background soothe-background-dark))
  (highlight-indentation-current-column-face (:background soothe-gray-5))
  (ecb-default-general-face                  (:foreground soothe-gray-1      :background soothe-gray-1bg))
  (ecb-default-highlight-face                (:foreground soothe-red-1       :background soothe-red-1bg))
  (ecb-method-face                           (:foreground soothe-red-1       :background soothe-red-1bg))
  (ecb-tag-header-face                       (:background soothe-blue-2bg))
  (org-date                                  (:foreground soothe-purple-1    :background soothe-purple-1bg))
  (org-done                                  (:foreground soothe-green-1     :background soothe-green-1bg))
  (org-hide                                  (:foreground soothe-gray-3      :background soothe-gray-1bg))
  (org-link                                  (:foreground soothe-blue-1      :background soothe-blue-1bg))
  (org-todo                                  (:foreground soothe-red-1       :background soothe-red-1bg))
  (cua-global-mark                           (:foreground soothe-foam :background soothe-turquoise-1))
  (cua-rectangle                             (:foreground soothe-foam :background soothe-purple-4))
  (cua-rectangle-noselect                    (:foreground soothe-foam :background soothe-orange-1))
  (hl-sexp-face                              (:background soothe-turquoise-2bg))

  (orderless-match-face-0                    (:inherit 'match :foreground soothe-overexposed-green))
  (orderless-match-face-1                    (:inherit 'highlight :foreground soothe-overexposed-blue))
  (orderless-match-face-2                    (:inherit 'lazy-highlight :foreground soothe-overexposed-purple))
  (orderless-match-face-3                    (:inherit 'secondary-selection :foreground soothe-overexposed-orange))

  (vertico-posframe                          (:background soothe-background-dark))
  (vertico-posframe-border                   (:background soothe-background-dark-0))
  (vertico-posframe-border-2                 (:background soothe-alt-background))
  (vertico-posframe-border-3                 (:background soothe-dirty-crem-bg))
  (vertico-posframe-border-4                 (:background soothe-darker-crem-bg))

  (which-key-command-description-face        (:inherit 'font-lock-function-name-face))
  (which-key-group-description-face          (:inherit 'font-lock-keyword-face))
  (which-key-highlighted-command-face        (:underline t :inherit 'which-key-command-description-face))
  (which-key-key-face                        (:inherit 'font-lock-constant-face))
  (which-key-local-map-description-face      (:inherit 'which-key-command-description-face))
  (which-key-note-face                       (:inherit 'which-key-separator-face))
  (which-key-separator-face                  (:inherit 'font-lock-comment-face))
  (which-key-special-key-face                (:weight 'bold :inverse-video t :inherit 'which-key-key-face))

  (rainbow-delimiters-depth-1-face           (:foreground soothe-rainbow-delimiters-0))
  (rainbow-delimiters-depth-2-face           (:foreground soothe-rainbow-delimiters-1))
  (rainbow-delimiters-depth-3-face           (:foreground soothe-rainbow-delimiters-2))
  (rainbow-delimiters-depth-4-face           (:foreground soothe-rainbow-delimiters-3))
  (rainbow-delimiters-depth-5-face           (:foreground soothe-rainbow-delimiters-4))
  (rainbow-delimiters-depth-6-face           (:foreground soothe-rainbow-delimiters-5))
  (rainbow-delimiters-depth-7-face           (:foreground soothe-rainbow-delimiters-6))
  (rainbow-delimiters-depth-8-face           (:foreground soothe-rainbow-delimiters-7))
  (rainbow-delimiters-depth-9-face           (:foreground soothe-rainbow-delimiters-8))
  (rainbow-delimiters-unmatched-face         (:foreground soothe-rainbow-delimiters-9)))

 (custom-theme-set-variables 'soothe
                            `(pos-tip-foreground-color ,soothe-foreground)
                            `(pos-tip-background-color ,soothe-background)
                            `(ansi-color-names-vector [,soothe-background
                                                       ,soothe-red-1
                                                       ,soothe-green-1
                                                       ,soothe-yellow-1
                                                       ,soothe-blue-1
                                                       ,soothe-purple-1
                                                       ,soothe-blue-3
                                                       ,soothe-foreground])))

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'soothe)

;; Local Variables:
;; eval: (when (fboundp 'rainbow-mode) (rainbow-mode 1))
;; End:

;;; soothe-theme.el ends here
