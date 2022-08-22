;;; soothe-theme.el --- A dark colorful theme -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2012-2022 Jason Milkins
;;
;; Author: Jason Milkins <jasonm23@gmail.com>
;; Maintainer: Jason Milkins <jasonm23@gmail.com>
;; URL: https://github.com/emacsfodder/emacs-soothe-theme
;; Package-Version: 20220822.437
;; Package-Commit: f61180e99fa31a124692374fd5f3ffca7ad5e3fa
;; Version: 1.4.0
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

(autothemer-deftheme soothe
                      "A dark colorful theme"
 ;;; Palette
 ((((class color) (min-colors #xFFFFFF))) ;; GUI/24bit only
  ;;; Foreground colors
  (soothe-foreground           "#F4F1ED")
  (soothe-foreground-0         "#ECEAE5")
  (soothe-foreground-1         "#E3E4E2")
  (soothe-foreground-2         "#DBD9D4")
  (soothe-foreground-3         "#CECCC7")

  ;;; Background colors
  (soothe-background-dark-0    "#000000")
  (soothe-background-dark      "#0F0E11")
  (soothe-background           "#111013")
  (soothe-background-0         "#111013")
  (soothe-alt-background       "#121113")
  (soothe-background-1         "#121113")
  (soothe-background-2         "#2B2A2A")
  (soothe-background-3         "#313030")
  (soothe-background-4         "#343333")

  ;;; Colors Gray
  (soothe-gray-1               "#AAAAAA")
  (soothe-gray-2               "#828282")
  (soothe-gray-3               "#333333")
  (soothe-gray-4               "#2A2A2A")
  (soothe-gray-5               "#252525")
  (soothe-gray-6               "#202020")
  (soothe-gray-1bg             "#0A0A0A")
  (soothe-gray-2bg             "#111111")
  (soothe-gray-3bg             "#141414")

  ;;; Colors Prime
  (soothe-prime-red            "#B14E41")
  (soothe-prime-orange         "#D9662E")
  (soothe-prime-yellow         "#CEB666")
  (soothe-prime-green          "#7D9F51")
  (soothe-prime-blue           "#A4B3C9")
  (soothe-prime-purple         "#948CB5")
  (soothe-prime-turquoise      "#1FA8A8")

  ;;; Colors Turquoise
  (soothe-turquoise-0          "#106A77")
  (soothe-turquoise-1          "#0E545F")
  (soothe-turquoise-2          "#113E46")
  (soothe-turquoise-3          "#0D3239")
  (soothe-turquoise-1bg        "#06181C")
  (soothe-turquoise-2bg        "#051316")

  ;;; Colors Accents
  (soothe-red-2                "#A24B2E")
  (soothe-red-3                "#AA2010")
  (soothe-orange-2             "#FF642A")
  (soothe-green-2              "#4C8F79")
  (soothe-green-3              "#899F6D")
  (soothe-blue-2               "#407A98")
  (soothe-blue-4               "#42557A")
  (soothe-purple-3             "#50486C")
  (soothe-purple-4             "#3B3358")

  ;;; Original Background Colors
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

  ;;; 2022 Palette add-ons
  ;;; Muted colors
  (soothe-muted-red            "#ED8E8E")
  (soothe-muted-orange         "#D7B181")
  (soothe-muted-green          "#90AC67")
  (soothe-muted-blue           "#72A9BF")
  (soothe-muted-purple         "#BD95FA")

  ;;; Overexposed colors
  (soothe-overexposed-red      "#F2A9A9")
  (soothe-overexposed-orange   "#F2D0A9")
  (soothe-overexposed-green    "#D4F2A9")
  (soothe-overexposed-blue     "#A9DCF2")
  (soothe-overexposed-purple   "#C6A9F2")

  ;;; Faded colors
  (soothe-faded-red            "#7F5858")
  (soothe-faded-orange         "#7F6D58")
  (soothe-faded-green          "#6F7F58")
  (soothe-faded-blue           "#58737F")
  (soothe-faded-purple         "#67587F")

  ;;; Mid colors
  (soothe-mid-red              "#883B3B")
  (soothe-mid-orange           "#8B5000")
  (soothe-mid-green            "#3F610D")
  (soothe-mid-blue             "#195A73")
  (soothe-mid-purple           "#563C7C")

  ;;; Low colors
  (soothe-low-red              "#411010")
  (soothe-low-orange           "#412500")
  (soothe-low-green            "#2A4107")
  (soothe-low-blue             "#0D3241")
  (soothe-low-purple           "#2C1F41")

  ;;; Dark colors
  (soothe-dark-red             "#261010")
  (soothe-dark-orange          "#261500")
  (soothe-dark-green           "#182604")
  (soothe-dark-blue            "#071D26")
  (soothe-dark-purple          "#1A1226")

  ;;; 2022 Background colors
  (soothe-bg-red               "#190A0A")
  (soothe-bg-orange            "#190E00")
  (soothe-bg-green             "#101902")
  (soothe-bg-blue              "#041319")
  (soothe-bg-purple            "#110C19")
  (soothe-bg-turquoise         "#15252A")

  ;;; Rainbow Delimiter colors
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

 ;;; Face Specs
 ((default                                   (:foreground soothe-foreground                :background soothe-background))
  (cursor                                    (:background soothe-prime-orange))
  (region                                    (:background soothe-blue-5bg))
  (secondary-selection                       (:background soothe-bg-turquoise))
  (match                                     (:background soothe-blue-4bg))
  (highlight                                 (:background soothe-blue-5bg))
  (hl-line                                   (:background soothe-bg-turquoise))
  (minibuffer-prompt                         (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (escape-glyph                              (:foreground soothe-prime-red                 :background soothe-purple-1bg))
  (error                                     (:foreground soothe-prime-red                 :background soothe-red-1bg))
  (font-lock-builtin-face                    (:foreground soothe-red-2                     :background soothe-red-1bg))
  (font-lock-constant-face                   (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (font-lock-comment-face                    (:foreground soothe-prime-purple              :background soothe-alt-background :italic t))
  (font-lock-comment-delimiter-face          (:foreground soothe-turquoise-1               :background soothe-alt-background :italic t))
  (font-lock-doc-face                        (:foreground soothe-prime-turquoise           :background soothe-gray-1bg))
  (font-lock-function-name-face              (:foreground soothe-prime-red                 :background soothe-red-1bg))
  (font-lock-keyword-face                    (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (font-lock-negation-char-face              (:foreground soothe-prime-yellow              :background soothe-yellow-1bg))
  (font-lock-preprocessor-face               (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (font-lock-string-face                     (:foreground soothe-prime-turquoise           :background soothe-turquoise-2bg))
  (font-lock-type-face                       (:foreground soothe-red-2                     :background soothe-red-1bg :bold nil))
  (font-lock-variable-name-face              (:foreground soothe-prime-blue                :background soothe-blue-1bg))
  (font-lock-warning-face                    (:foreground soothe-red-2                     :background soothe-red-2bg))
  (link                                      (:foreground soothe-prime-blue                :background soothe-blue-1bg))
  (link-visited                              (:foreground soothe-prime-turquoise           :background soothe-blue-4bg))
  (fringe                                    (:background soothe-gray-3bg))
  (vertical-border                           (:foreground soothe-gray-4                    :background soothe-background))
  (mode-line                                 (:foreground soothe-gray-2                    :background soothe-gray-3bg :box nil))
  (mode-line-inactive                        (:foreground soothe-gray-5                    :background soothe-gray-2bg :inherit 'mode-line))
  (mode-line-highlight                       (:foreground soothe-prime-red))
  (mode-line-buffer-id                       (:foreground soothe-prime-orange))
  (mode-line-emphasis                        (:bold t))
  (which-func                                (:foreground soothe-prime-blue))
  (isearch                                   (:foreground soothe-foreground-1              :background soothe-purple-2bg))
  (isearch-fail                              (:foreground soothe-foreground-1              :background soothe-low-red))
  (lazy-highlight                            (:foreground soothe-prime-purple              :background soothe-purple-2bg))
  (success                                   (:foreground soothe-foreground-1              :background soothe-mid-blue))

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

  (ivy-cursor                                (:foreground soothe-foreground-1              :background soothe-bg-turquoise))
  (ivy-current-match                         (:inherit 'match))
  (ivy-minibuffer-match-highlight            (:inherit 'highlight))
  (ivy-minibuffer-match-face-1               (:inherit 'match))
  (ivy-minibuffer-match-face-2               (:inherit 'highlight))
  (ivy-minibuffer-match-face-3               (:inherit 'secondary-selection))
  (ivy-minibuffer-match-face-4               (:inherit 'region))
  (ivy-confirm-face                          (:inherit 'minibuffer-prompt                  :foreground soothe-rainbow-delimiters-0))
  (ivy-match-required-face                   (:inherit 'minibuffer-prompt                  :foreground soothe-red-3))
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

  (company-echo-common                       (:foreground soothe-prime-blue                :background nil))
  (company-preview-common                    (:inherit 'font-lock-builtin-face             :underline soothe-foreground-1))
  (company-echo                              (:inherit 'company-echo-common))
  (company-preview                           (:inherit 'company-preview-common))
  (company-preview-search                    (:inherit 'company-preview-common))
  (company-scrollbar-bg                      (:foreground nil                              :background soothe-turquoise-2bg))
  (company-scrollbar-fg                      (:foreground nil                              :background soothe-turquoise-2))
  (company-template-field                    (:foreground soothe-prime-blue                :background nil :underline soothe-bg-blue))
  (company-tooltip                           (:foreground soothe-foreground-0              :background soothe-turquoise-1bg))
  (company-tooltip-annotation                (:foreground soothe-foreground-0              :background soothe-turquoise-2bg))
  (company-tooltip-common                    (:foreground soothe-prime-turquoise           :background soothe-turquoise-2bg))
  (company-tooltip-common-selection          (:foreground soothe-prime-orange              :background soothe-turquoise-2bg))
  (company-tooltip-mouse                     (:foreground soothe-prime-purple              :background soothe-turquoise-2bg))
  (company-tooltip-selection                 (:inherit 'font-lock-constant-face            :background soothe-background-dark-0))

  (ac-selection-face                         (:foreground soothe-foreground-2              :background soothe-background-2))
  (ac-candidate-face                         (:foreground soothe-background                :background soothe-foreground-2))
  (ac-yasnippet-candidate-face               (:foreground soothe-background                :background soothe-green-2))
  (ac-yasnippet-selection-face               (:foreground soothe-foreground-1              :background soothe-background-2))
  (ac-gtags-candidate-face                   (:foreground soothe-background                :background soothe-purple-3))
  (ac-gtags-selection-face                   (:foreground soothe-foreground-2              :background soothe-background-2))
  (ac-candidate-mouse-face                   (:foreground soothe-foreground-1              :background soothe-turquoise-1))
  (ac-completion-face                        (:foreground soothe-foreground-0              :background soothe-purple-3bg))
  (popup-tip-face                            (:foreground soothe-foreground-2              :background soothe-background-2))
  (tooltip                                   (:foreground soothe-background-2              :background soothe-foreground-2))

  (dired-directory                           (:foreground soothe-prime-turquoise           :background soothe-bg-turquoise))
  (dired-flagged                             (:foreground soothe-prime-red                 :background soothe-orange-1bg))
  (dired-header                              (:foreground soothe-prime-orange              :background soothe-background))
  (dired-ignored                             (:foreground soothe-turquoise-1               :background soothe-background))
  (dired-mark                                (:foreground soothe-orange-2                  :background soothe-background))
  (dired-marked                              (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (dired-perm-write                          (:foreground soothe-prime-turquoise           :background soothe-turquoise-1bg))
  (dired-symlink                             (:foreground soothe-prime-blue                :background soothe-blue-4bg))
  (dired-warning                             (:foreground soothe-prime-red                 :background soothe-red-2bg))

  (diredfl-dir-name                          (:inherit 'dired-directory))
  (diredfl-flagged                           (:inherit 'dired-flagged))
  (diredfl-header                            (:inherit 'dired-header))
  (diredfl-ignored                           (:inherit 'dired-ignored))
  (diredfl-mark                              (:inherit 'dired-mark))
  (diredfl-marked                            (:inherit 'dired-marked))
  (diredfl-write-priv                        (:inherit 'dired-perm-write))
  (diredfl-symlink                           (:inherit 'dired-symlink))
  (diredfl-warning                           (:inherit 'dired-warning))

  (diredfl-file-name                         (:foreground soothe-prime-purple              :background soothe-dark-purple))
  (diredfl-file-suffix                       (:foreground soothe-faded-purple              :background soothe-dark-purple))
  (diredfl-autofile-name                     (:foreground soothe-prime-blue                :background soothe-dark-purple))
  (diredfl-compressed-file-name              (:foreground soothe-prime-turquoise))
  (diredfl-compressed-file-suffix            (:foreground soothe-turquoise-0))
  (diredfl-date-time                         (:foreground soothe-prime-orange              :background soothe-dark-purple))
  (diredfl-no-priv                           (:foreground soothe-faded-purple              :background soothe-dark-purple))
  (diredfl-deletion                          (:foreground soothe-prime-orange              :background soothe-red-3))
  (diredfl-deletion-file-name                (:foreground soothe-red-3                     :background-color soothe-red-2bg))

  (diredfl-dir-heading                       (:inherit 'font-lock-builtin-face))
  (diredfl-dir-priv                          (:foreground soothe-prime-orange              :background soothe-bg-orange))

  (diredfl-exec-priv                         (:foreground soothe-prime-red                 :background soothe-bg-red))
  (diredfl-executable-tag                    (:foreground soothe-red-3))
  (diredfl-flag-mark                         (:foreground soothe-prime-orange              :background soothe-bg-orange))
  (diredfl-flag-mark-line                    (:background soothe-low-red))
  (diredfl-ignored-file-name                 (:foreground soothe-prime-orange))
  (diredfl-link-priv                         (:foreground soothe-prime-turquoise           :background soothe-bg-turquoise))
  (diredfl-number                            (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (diredfl-other-priv                        (:background soothe-blue-5bg))
  (diredfl-rare-priv                         (:foreground soothe-prime-green               :background soothe-prime-red))
  (diredfl-read-priv                         (:foreground soothe-prime-purple              :background soothe-bg-purple))
  (diredfl-tagged-autofile-name              (:background soothe-purple-3bg))

  (diredp-autofile-name                      (:inherit 'diredfl-autofile-name))
  (diredp-compressed-file-name               (:inherit 'diredfl-compressed-file-name))
  (diredp-compressed-file-suffix             (:inherit 'diredfl-compressed-file-suffix))
  (diredp-date-time                          (:inherit 'diredfl-date-time))
  (diredp-deletion                           (:inherit 'diredfl-deletion))
  (diredp-deletion-file-name                 (:inherit 'diredfl-deletion-file-name))
  (diredp-dir-heading                        (:inherit 'diredfl-dir-heading))
  (diredp-dir-name                           (:inherit 'diredfl-dir-name))
  (diredp-dir-priv                           (:inherit 'diredfl-dir-priv))
  (diredp-exec-priv                          (:inherit 'diredfl-exec-priv))
  (diredp-executable-tag                     (:inherit 'diredfl-executable-tag))
  (diredp-file-name                          (:inherit 'diredfl-file-name))
  (diredp-file-suffix                        (:inherit 'diredfl-file-suffix))
  (diredp-flag-mark                          (:inherit 'diredfl-flag-mark))
  (diredp-flag-mark-line                     (:inherit 'diredfl-flag-mark-line))
  (diredp-ignored-file-name                  (:inherit 'diredfl-ignored-file-name))
  (diredp-link-priv                          (:inherit 'diredfl-link-priv))
  (diredp-no-priv                            (:inherit 'diredfl-no-priv))
  (diredp-number                             (:inherit 'diredfl-number))
  (diredp-other-priv                         (:inherit 'diredfl-other-priv))
  (diredp-rare-priv                          (:inherit 'diredfl-rare-priv))
  (diredp-read-priv                          (:inherit 'diredfl-read-priv))
  (diredp-symlink                            (:inherit 'diredfl-symlink))
  (diredp-tagged-autofile-name               (:inherit 'diredfl-tagged-autofile-name))
  (diredp-write-priv                         (:inherit 'diredfl-write-priv))

  (js3-error-face                            (:background soothe-red-1bg                   :underline (:color soothe-prime-red :style 'wave)))
  (js3-warning-face                          (:background soothe-yellow-1bg                :underline (:color soothe-prime-yellow :style 'wave)))
  (js3-external-variable-face                (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (js3-function-param-face                   (:foreground soothe-prime-turquoise           :background soothe-blue-3bg))
  (js3-instance-member-face                  (:foreground soothe-foreground-2              :background soothe-purple-1bg))
  (js3-magic-paren-face                      (:foreground soothe-foreground-0              :background soothe-purple-1bg))
  (js3-private-function-call-face            (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (js3-private-member-face                   (:foreground soothe-orange-2                  :background soothe-orange-1bg))
  (js3-jsdoc-html-tag-delimiter-face         (:foreground soothe-blue-4                    :background soothe-blue-2bg))
  (js3-jsdoc-html-tag-name-face              (:foreground soothe-foreground-1              :background soothe-blue-3bg))
  (js3-jsdoc-tag-face                        (:foreground soothe-green-3                   :background soothe-green-2bg))
  (js3-jsdoc-type-face                       (:foreground soothe-green-2                   :background soothe-green-2bg))
  (js3-jsdoc-value-face                      (:foreground soothe-prime-green               :background soothe-green-1bg))

  (diff-changed-unspcified                   (:foreground soothe-overexposed-purple        :background soothe-dark-purple))
  (diff-changed                              (:foreground soothe-overexposed-purple        :background soothe-dark-purple))
  (diff-added                                (:foreground soothe-overexposed-green         :background soothe-dark-green))
  (diff-removed                              (:foreground soothe-overexposed-red           :background soothe-dark-red))
  (diff-function                             (:foreground soothe-foreground-1              :background soothe-dark-orange))

  (diff-refine-changed                       (:inherit 'diff-changed))
  (diff-refine-added                         (:inherit 'diff-added))
  (diff-refine-removed                       (:inherit 'diff-removed))

  (smerge-refined-changed                    (:inherit 'diff-changed))
  (smerge-refined-added                      (:inherit 'diff-added))
  (smerge-refined-removed                    (:inherit 'diff-removed))
  (smerge-base                               (:inherit 'diff-context))

  (smerge-markers                            (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (smerge-upper                              (:background soothe-blue-1bg))
  (smerge-lower                              (:background soothe-turquoise-1bg))

  (diff-file-header                          (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (diff-context                              (:foreground soothe-foreground-1))
  (diff-hunk-header                          (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (diff-hl-insert                            (:foreground soothe-prime-green               :background soothe-green-2bg))
  (diff-hl-delete                            (:foreground soothe-prime-red                 :background soothe-red-1bg))
  (diff-hl-change                            (:foreground soothe-prime-purple              :background soothe-purple-1bg))

  (linum                                     (:foreground soothe-gray-6                    :background soothe-alt-background))
  (show-paren-match                          (:foreground soothe-foreground-1              :background soothe-orange-1bg))
  (show-paren-mismatch                       (:foreground soothe-prime-orange              :background soothe-red-2bg))

  (swiper-match-face-1                       (:inherit 'lazy-highlight))
  (swiper-match-face-2                       (:inherit 'isearch))
  (swiper-match-face-3                       (:inherit 'match))
  (swiper-match-face-4                       (:inherit 'isearch-fail))
  (swiper-background-match-face-1            (:inherit 'swiper-match-face-1))
  (swiper-background-match-face-2            (:inherit 'swiper-match-face-2))
  (swiper-background-match-face-3            (:inherit 'swiper-match-face-3))
  (swiper-background-match-face-4            (:inherit 'swiper-match-face-4))
  (swiper-line-face                          (:inherit 'match))

  (ido-only-match                            (:foreground soothe-prime-green               :background soothe-green-1bg))
  (ido-subdir                                (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (ido-first-match                           (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (ido-incomplete-regexp                     (:foreground soothe-prime-red                 :background soothe-orange-1bg))
  (ido-indicator                             (:foreground soothe-turquoise-1               :background soothe-turquoise-1bg))
  (ido-virtual                               (:foreground soothe-green-3                   :background soothe-turquoise-1bg))
  (whitespace-empty                          (:foreground soothe-prime-yellow              :background soothe-turquoise-2bg))
  (whitespace-hspace                         (:foreground soothe-turquoise-2               :background soothe-turquoise-2bg))
  (whitespace-indentation                    (:foreground soothe-turquoise-2               :background soothe-turquoise-2bg))
  (whitespace-line                           (:foreground soothe-prime-orange              :background soothe-turquoise-2bg))
  (whitespace-newline                        (:foreground soothe-turquoise-2               :background soothe-turquoise-2bg))
  (whitespace-space                          (:foreground soothe-turquoise-2               :background soothe-turquoise-2bg))
  (whitespace-space-after-tab                (:foreground soothe-turquoise-2               :background soothe-turquoise-2bg))
  (whitespace-tab                            (:foreground soothe-turquoise-2               :background soothe-turquoise-2bg))
  (whitespace-trailing                       (:foreground soothe-prime-red                 :background soothe-turquoise-2bg))
  (flyspell-incorrect                        (:underline soothe-red-2))
  (flyspell-duplicate                        (:underline soothe-green-2))
  (flymake-errline                           (:underline soothe-red-2                      :background nil                       :inherit nil))
  (flymake-warnline                          (:underline soothe-green-2                    :background nil                       :inherit nil))
  (dropdown-list-selection-face              (:foreground soothe-foreground-1              :background soothe-purple-1bg))
  (dropdown-list-face                        (:foreground soothe-background                :background soothe-foreground-1))

  (git-gutter                                :added                                        (:foreground soothe-prime-green       :background soothe-green-2bg))
  (git-gutter                                :deleted                                      (:foreground soothe-prime-red         :background soothe-red-1bg))
  (git-gutter                                :modified                                     (:foreground soothe-prime-purple      :background soothe-purple-1bg))
  (git-gutter                                :unchanged                                    (:background soothe-yellow-1bg))

  (magit-item-highlight                      (:background soothe-purple-3bg))
  (magit-branch                              (:foreground soothe-prime-orange              :background soothe-orange-2bg))
  (magit-branch-remote                       (:foreground soothe-prime-orange              :background soothe-orange-2bg))
  (magit-whitespace-warning-face             (:foreground soothe-red-3                     :background soothe-red-1bg))
  (magit-section-heading                     (:foreground soothe-prime-orange              :background soothe-purple-1bg))
  (magit-section-title                       (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (magit-section-highlight                   (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (magit-section-highlight-selection         (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (magit-header                              (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (magit-hash                                (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (magit-tag                                 (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (magit-item-mark                           (:foreground soothe-prime-green))

  (magit-diff-added-highlight                (:foreground soothe-foreground-1              :background soothe-dark-green))
  (magit-diff-removed-highlight              (:foreground soothe-foreground-1              :background soothe-dark-red))

  (magit-diff-added                          (:foreground soothe-foreground-1              :background soothe-bg-green))
  (magit-diff-removed                        (:foreground soothe-foreground-1              :background soothe-bg-red))

  (magit-diffstat-added                      (:foreground soothe-overexposed-green))
  (magit-diffstat-removed                    (:foreground soothe-overexposed-red))

  (magit-diff-merge-proposed                 (:foreground soothe-foreground-1))
  (magit-diff-merge-current                  (:foreground soothe-prime-blue))
  (magit-diff-merge-separator                (:foreground soothe-blue-2))

  (magit-diff-context                        (:background soothe-background))
  (magit-diff-context-highlight              (:background soothe-alt-background))

  (magit-diff-file-heading                   (:weight 'bold))
  (magit-diff-file-heading-highlight         (:inherit 'magit-section-highlight))
  (magit-diff-file-heading-selection         (:inherit 'magit-diff-file-heading-highlight  :foreground soothe-prime-yellow))

  (magit-diff-hunk-heading                   (:foreground soothe-foreground                :background soothe-low-purple))
  (magit-diff-hunk-heading-highlight         (:foreground soothe-foreground                :background soothe-low-purple))
  (magit-diff-hunk-heading-selection         (:foreground soothe-prime-yellow              :inherit 'magit-diff-hunk-heading-highlight))

  (magit-diff-lines-heading                  (:inherit 'magit-diff-hunk-heading-highlight  :foreground soothe-foreground-3 :background soothe-red-2))
  (magit-diff-hunk-region                    (:inherit 'bold))

  (magit-diff-revision-summary               (:inherit 'magit-diff-hunk-heading))
  (magit-diff-revision-summary-highlight     (:inherit 'magit-diff-hunk-heading-highlight))

  (magit-diff-lines-boundary                 (:inherit 'magit-diff-lines-heading))
  (magit-diff-conflict-heading               (:inherit 'magit-diff-hunk-heading))

  (magit-diff-base                           (:foreground soothe-foreground                :background soothe-rainbow-delimiters-0))
  (magit-diff-base-highlight                 (:foreground soothe-foreground-0              :background soothe-rainbow-delimiters-0))
  (magit-diff-our                            (:inherit 'magit-diff-removed))
  (magit-diff-their                          (:inherit 'magit-diff-added))
  (magit-diff-our-highlight                  (:inherit 'magit-diff-removed-highlight))
  (magit-diff-their-highlight                (:inherit 'magit-diff-added-highlight))
  (magit-diff-whitespace-warning             (:inherit 'trailing-whitespace))

  (magit-branch-current                      (:foreground soothe-prime-purple              :background soothe-purple-1bg :box (:line-width -1 :color soothe-prime-purple)))
  (magit-branch-local                        (:foreground soothe-prime-purple              :background soothe-purple-1bg))

  (magit-log-author                          (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (magit-log-author                          (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (magit-log-graph                           (:foreground soothe-blue-2                    :background soothe-blue-2bg))
  (magit-log-head-label-bisect-good          (:foreground soothe-turquoise-1               :background soothe-turquoise-1bg))
  (magit-log-head-label-local                (:foreground soothe-foreground-1              :background soothe-turquoise-1bg))
  (magit-log-head-label-remote               (:foreground soothe-foreground-1              :background soothe-purple-2bg))
  (magit-log-message                         (:foreground soothe-foreground-2              :background soothe-background))
  (magit-log-date                            (:foreground soothe-blue-4                    :background soothe-background))
  (magit-log-head-label-bisect-bad           (:foreground soothe-prime-red                 :background soothe-red-1bg))
  (magit-log-head-label-default              (:foreground soothe-foreground-1              :background soothe-turquoise-1bg))
  (magit-log-head-label-patches              (:foreground soothe-blue-2                    :background soothe-blue-1bg))
  (magit-log-head-label-tags                 (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (magit-log-sha1                            (:foreground soothe-turquoise-1               :background soothe-turquoise-1bg))

  (markdown-header-face-1                    (:inherit 'variable-pitch                     :foreground soothe-overexposed-purple :height 1.9))
  (markdown-header-face-2                    (:inherit 'variable-pitch                     :foreground soothe-overexposed-blue   :height 1.8))
  (markdown-header-face-3                    (:inherit 'variable-pitch                     :foreground soothe-overexposed-green  :height 1.6))
  (markdown-header-face-4                    (:inherit 'variable-pitch                     :foreground soothe-overexposed-orange :height 1.5))
  (markdown-header-face-5                    (:inherit 'variable-pitch                     :foreground soothe-overexposed-purple :height 1.4))
  (markdown-header-face-6                    (:inherit 'variable-pitch                     :foreground soothe-overexposed-blue   :height 1.3))

  (iedit-occurrence                          (:inherit 'match                              :foreground soothe-prime-purple))
  (iedit-read-only-occurrence                (:inherit 'match                              :foreground soothe-prime-red))

  (highlight-indentation-face                (:background soothe-background-dark))
  (highlight-indentation-current-column-face (:background soothe-gray-5))

  (ecb-default-general-face                  (:foreground soothe-foreground))
  (ecb-default-highlight-face                (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (ecb-method-face                           (:foreground soothe-prime-orange              :background soothe-orange-1bg))
  (ecb-tag-header-face                       (:foreground soothe-prime-turquoise           :background soothe-turquoise-1bg))

  (org-date                                  (:foreground soothe-prime-purple              :background soothe-purple-1bg))
  (org-done                                  (:foreground soothe-prime-green               :background soothe-green-1bg))
  (org-hide                                  (:foreground soothe-gray-3                    :background soothe-gray-1bg))
  (org-link                                  (:foreground soothe-prime-blue                :background soothe-blue-1bg))
  (org-todo                                  (:foreground soothe-prime-red                 :background soothe-red-1bg))
  (cua-global-mark                           (:foreground soothe-foreground-1              :background soothe-turquoise-1))
  (cua-rectangle                             (:foreground soothe-foreground-1              :background soothe-purple-4))
  (cua-rectangle-noselect                    (:foreground soothe-foreground-1              :background soothe-prime-orange))

  (hl-sexp-face                              (:background soothe-turquoise-2bg))

  (orderless-match-face-0                    (:inherit 'match                              :foreground soothe-prime-turquoise))
  (orderless-match-face-1                    (:inherit 'highlight                          :foreground soothe-prime-purple))
  (orderless-match-face-2                    (:inherit 'lazy-highlight                     :foreground soothe-prime-orange))
  (orderless-match-face-3                    (:inherit 'secondary-selection                :foreground soothe-prime-blue))

  (vertico-posframe                          (:background soothe-background-dark))
  (vertico-posframe-border                   (:background soothe-background-dark-0))
  (vertico-posframe-border-2                 (:background soothe-alt-background))
  (vertico-posframe-border-3                 (:background soothe-background-2))
  (vertico-posframe-border-4                 (:background soothe-background-3))

  (web-mode-doctype-face                     (:foreground soothe-foreground-2 :weight 'bold))
  (web-mode-html-attr-equal-face             (:inherit 'default))
  (web-mode-html-attr-name-face              (:inherit 'font-lock-keyword-face))
  (web-mode-html-tag-bracket-face            (:inherit 'default))
  (web-mode-html-tag-face                    (:inherit 'font-lock-builtin-face))

  (which-key-command-description-face        (:inherit 'font-lock-function-name-face))
  (which-key-group-description-face          (:inherit 'font-lock-keyword-face))
  (which-key-highlighted-command-face        (:inherit 'which-key-command-description-face :underline t))
  (which-key-key-face                        (:inherit 'font-lock-constant-face))
  (which-key-local-map-description-face      (:inherit 'which-key-command-description-face))
  (which-key-note-face                       (:inherit 'which-key-separator-face))
  (which-key-separator-face                  (:inherit 'font-lock-comment-face))
  (which-key-special-key-face                (:inherit 'which-key-key-face                 :weight 'bold :inverse-video t))

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
                                                       ,soothe-prime-red
                                                       ,soothe-prime-green
                                                       ,soothe-prime-yellow
                                                       ,soothe-prime-blue
                                                       ,soothe-prime-purple
                                                       ,soothe-prime-turquoise
                                                       ,soothe-foreground])))

  ;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))


;; For development.

(defun soothe-dev-reload ()
  "For development, reload soothe-theme from development file."
  (interactive)
  (let (dev-file-name)
   (when (featurep 'soothe-theme)
    (unload-feature 'soothe-theme))
   (disable-theme 'soothe)
   (setq dev-file-name (read-file-name "Locate sooth-theme.el: " nil nil t nil))
   (byte-compile-file dev-file-name)
   (load-file (replace-regexp-in-string "[.]el" ".elc" dev-file-name))
   (enable-theme 'soothe)))

(provide-theme 'soothe)

;; Local Variables:
;; eval: (when (fboundp 'rainbow-mode) (rainbow-mode 1))
;; End:

;;; soothe-theme.el ends here
