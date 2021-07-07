;;; night-owl-theme.el --- A color theme for the night owls out there

;; Copyright (C) 2018

;; Author: Aaron Jensen <aaronjensen@gmail.com>
;; URL: http://github.com/aaronjensen/night-owl-theme
;; Package-Version: 20200622.1943
;; Package-Commit: 4b9b5cb4fead9c5f145ba399d172c7e6bf577121
;; Version: 0.1.0
;; Package-Requires: ((emacs "24"))

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

;;; Commentary:
;;
;; A port of the popular VS Code theme Night Owl. From the VS Code Night Owl README:
;;
;; A theme for the night owls out there. Works well in the daytime, too, but this theme is
;; fine-tuned for those of us who like to code late into the night. Color choices have taken
;; into consideration what is accessible to people with colorblindness and in low-light
;; circumstances. Decisions were also based on meaningful contrast for reading comprehension
;; and for optimal razzle dazzle.
;;
;;; Credits:
;;
;; Sarah Drasner created the original theme.
;; - https://github.com/sdras/night-owl-vscode-theme
;;
;; Kelvin Smith created monokai-theme.el on which this file is based.
;; -  https://github.com/oneKelvinSmith/monokai-emacs
;;
;; Color Scheme Designer 3 for complementary colours.
;; - http://colorschemedesigner.com/
;;
;;; Code:

(unless (>= emacs-major-version 24)
  (error "The night-owl theme requires Emacs 24 or later!"))

(deftheme night-owl "The Night Owl colour theme")

;; Customization {{{
(defgroup night-owl nil
  "Night Owl theme options.
The theme has to be reloaded after changing anything in this group."
  :group 'faces)

(defcustom night-owl-distinct-fringe-background nil
  "Make the fringe background different from the normal background color.
Also affects 'linum-mode' background."
  :type 'boolean
  :group 'night-owl)

(defcustom night-owl-use-variable-pitch nil
  "Use variable pitch face for some headings and titles."
  :type 'boolean
  :group 'night-owl)

(defcustom night-owl-doc-face-as-comment nil
  "Consider `font-lock-doc-face' as comment instead of a string."
  :type 'boolean
  :group 'night-owl
)

(defcustom night-owl-height-minus-1 0.8
  "Font size -1."
  :type 'number
  :group 'night-owl)

(defcustom night-owl-height-plus-1 1.1
  "Font size +1."
  :type 'number
  :group 'night-owl)

(defcustom night-owl-height-plus-2 1.15
  "Font size +2."
  :type 'number
  :group 'night-owl)

(defcustom night-owl-height-plus-3 1.2
  "Font size +3."
  :type 'number
  :group 'night-owl)

(defcustom night-owl-height-plus-4 1.3
  "Font size +4."
  :type 'number
  :group 'night-owl)

;; Primary colors

;; Converted
(defcustom night-owl-white "#FFFFFF"
  "Primary colors - white"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-green "#ADDB67"
  "Primary colors - green"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-orange "#F78C6C"
  "Primary colors - orange"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-red "#EF5350"
  "Primary colors - red"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-magenta "#C792EA"
  "Primary colors - magenta"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-blue "#82AAFF"
  "Primary colors - blue"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-gray "#5F7E97"
  "Primary colors - gray"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-cyan "#7FDBCA"
  "Primary colors - cyan"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-violet "#7E57C2"
  "Primary colors - violet"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-yellow "#FFEB95"
  "Primary colors - yellow"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-foreground "#D6DEEB"
  "Adaptive colors - foreground"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-foreground-slightly-muted "#8BADC1"
  "Adaptive colors - foreground slightly muted"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-foreground-muted "#676E95"
  "Adaptive colors - foreground muted"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-heading "#82B1FF"
  "Adaptive colors - heading"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-background "#011627"
  "Adaptive colors - background"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-background-highlight "#0B2942"
  "Adaptive colors - background highlight"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-comments "#637777"
  "Adaptive colors - comments"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-highlight "#1D3B53"
  "Adaptive colors - highlight"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-highlight-alt "#3C5B74"
  "Adaptive colors - highlight"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-highlight-line "#010F1D"
  "Adaptive colors - line highlight"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-line-number "#4B6479"
  "Adaptive colors - line number"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-emphasis "#FFFFFF"
  "Adaptive colors - emphasis"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-string "#ECC48D"
  "Adaptive colors - string"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-cursor "#80A4C2"
  "Adaptive colors - cursor"
  :type 'string
  :group 'night-owl)

(defcustom night-owl-classname "#FFCB8B"
  "Adaptive colors - class name"
  :type 'string
  :group 'night-owl)
;; }}}

;; Variables {{{

(let* (;; Variable pitch
       (night-owl-pitch (if night-owl-use-variable-pitch
                            'variable-pitch
                          'default))
       ;; }}}

       ;; Colors {{{
       (night-owl-input-fg          "#D1D5D9")
       (night-owl-input-bg          "#0B253A")
       (night-owl-button-fg         "#E2DDED")
       (night-owl-button-bg         "#674BA5")
       (night-owl-button-bg-hover   "#7e57c2")
       (night-owl-button-bg-pressed "#4f3f86")

       (night-owl-suggest-bg "#2C3043")
       (night-owl-match-bg "#1d374b")

       ;; Darker and lighter accented colors
       (night-owl-yellow-d      "#D8C15E")
       (night-owl-yellow-l      "#FFF2BA")
       (night-owl-green-d       "#89BA3F")
       (night-owl-green-l       "#CBEF94")
       (night-owl-magenta-d     "#AB69D7")
       (night-owl-magenta-l     "#E1C0F7")
       (night-owl-red-d         "#DC2E29")
       (night-owl-red-l         "#FF7B78")
       (night-owl-violet-d      "#643AAC")
       (night-owl-violet-l      "#9E7DD8")
       (night-owl-blue-d        "#5B8FFF")
       (night-owl-blue-l        "#ADC7FF")
       (night-owl-cyan-d        "#AFEFE2")
       (night-owl-cyan-l        "#55C1AC")
       (night-owl-orange-d      "#D76443")
       (night-owl-orange-l      "#FFAD95")
       (night-owl-gray-d        "#204462")
       (night-owl-gray-l        "#8BA2B6")
       ;; Adaptive higher/lower contrast accented colors
       (night-owl-foreground-hc "#141f1f")
       (night-owl-foreground-lc "#182525")
       ;; High contrast colors
       (night-owl-yellow-hc     "#FFF9DC")
       (night-owl-yellow-lc     "#B49C34")
       (night-owl-green-hc      "#E1F7C0")
       (night-owl-green-lc      "#6A9A21")
       (night-owl-magenta-hc    "#F9F2FF")
       (night-owl-magenta-lc    "#8C46BC")
       (night-owl-red-hc        "#FFA5A3")
       (night-owl-red-lc        "#AD1612")
       (night-owl-violet-hc     "#C5AEEC")
       (night-owl-violet-lc     "#4B1B9F")
       (night-owl-blue-hc       "#E8EFFF")
       (night-owl-blue-lc       "#3172FC")
       (night-owl-cyan-hc       "#E3FCF7")
       (night-owl-cyan-lc       "#34A18C")
       (night-owl-orange-hc     "#FFCDBE")
       (night-owl-orange-lc     "#B44322")

       ;; Distinct fringe
       (night-owl-fringe-bg (if night-owl-distinct-fringe-background
                                night-owl-gray
                              night-owl-background)))
  ;; }}}

  ;; custom-theme-set-faces {{{
  (custom-theme-set-faces
   'night-owl
   ;; }}}

   ;; font lock for syntax highlighting {{{
   `(font-lock-builtin-face
     ((t (:foreground ,night-owl-magenta
                      :weight normal))))

   `(font-lock-comment-delimiter-face
     ((t (:foreground ,night-owl-comments))))

   `(font-lock-comment-face
     ((t (:foreground ,night-owl-comments))))

   `(font-lock-constant-face
     ((t (:foreground ,night-owl-orange))))

   `(font-lock-doc-face
     ((t (:foreground ,(if night-owl-doc-face-as-comment
                           night-owl-comments
                         night-owl-string)))))

   `(font-lock-function-name-face
     ((t (:foreground ,night-owl-blue))))

   `(font-lock-keyword-face
     ((t (:foreground ,night-owl-magenta
                      :weight normal))))

   `(font-lock-negation-char-face
     ((t (:foreground ,night-owl-yellow
                      :weight bold))))

   `(font-lock-preprocessor-face
     ((t (:foreground ,night-owl-magenta))))

   `(font-lock-regexp-grouping-construct
     ((t (:foreground ,night-owl-yellow
                      :weight normal))))

   `(font-lock-regexp-grouping-backslash
     ((t (:foreground ,night-owl-violet
                      :weight normal))))

   `(font-lock-string-face
     ((t (:foreground ,night-owl-string))))

   `(font-lock-type-face
     ((t (:foreground ,night-owl-classname
                      :italic nil))))

   `(font-lock-variable-name-face
     ((t (:foreground ,night-owl-white))))

   `(font-lock-warning-face
     ((t (:foreground ,night-owl-orange
                      :weight bold
                      :italic t
                      :underline t))))

   `(c-annotation-face
     ((t (:inherit font-lock-constant-face))))
   ;; }}}

   ;; general colouring {{{
   '(button ((t (:underline t))))

   `(default
      ((t (:foreground ,night-owl-foreground
                       :background ,night-owl-background))))

   `(highlight
     ((t (:background ,night-owl-highlight
                      :distant-foreground ,night-owl-foreground-muted))))

   `(lazy-highlight
     ((t (:inherit highlight
                   :background ,night-owl-highlight-alt))))

   `(region
     ((t (:inherit highlight
                   :background ,night-owl-highlight
                   :distant-foreground ,night-owl-foreground-muted))))

   `(secondary-selection
     ((t (:inherit region
                   :background ,night-owl-highlight-alt))))

   `(shadow
     ((t (:foreground ,night-owl-comments))))

   `(match
     ((t (:background ,night-owl-highlight-alt
                      :foreground ,night-owl-white
                      :weight bold))))

   `(cursor
     ((t (:foreground ,night-owl-foreground
                      :background ,night-owl-cursor))))

   `(mouse
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-foreground
                      :inverse-video t))))

   `(escape-glyph
     ((t (:foreground ,night-owl-comments))))

   `(escape-glyph-face
     ((t (:foreground ,night-owl-comments))))

   `(fringe
     ((t (:foreground ,night-owl-foreground
                      :background ,night-owl-fringe-bg))))

   `(link
     ((t (:foreground ,night-owl-blue
                      :underline t
                      :weight bold))))

   `(link-visited
     ((t (:foreground ,night-owl-violet
                      :underline t
                      :weight normal))))

   `(success
     ((t (:foreground ,night-owl-green))))

   `(warning
     ((t (:foreground ,night-owl-yellow))))

   `(error
     ((t (:foreground ,night-owl-red))))

   `(eval-sexp-fu-flash
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-orange))))

   `(eval-sexp-fu-flash-error
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-magenta))))

   `(trailing-whitespace
     ((t (:background ,night-owl-magenta))))

   `(vertical-border
     ((t (:foreground ,night-owl-gray))))

   `(menu
     ((t (:foreground ,night-owl-foreground
                      :background ,night-owl-background))))

   `(minibuffer-prompt
     ((t (:foreground ,night-owl-blue))))

   `(widget-field
     ((t (:foreground ,night-owl-input-fg
                      :background ,night-owl-input-bg
                      :box (:color ,night-owl-gray
                                   :line-width 1)))))

   `(custom-button
     ((t (:foreground ,night-owl-button-fg
                      :background ,night-owl-button-bg
                      :box (:color ,night-owl-button-bg
                                   :line-width 2)))))

   `(custom-button-mouse
     ((t (:foreground ,night-owl-button-fg
                      :background ,night-owl-button-bg-hover
                      :box (:color ,night-owl-button-bg-hover
                                   :line-width 2)))))

   `(custom-button-pressed
     ((t (:foreground ,night-owl-button-fg
                      :background ,night-owl-button-bg-pressed
                      :box (:color ,night-owl-button-bg-pressed
                                   :line-width 2)))))
   ;; }}}

   ;; mode-line and powerline {{{
   `(mode-line-buffer-id
     ((t (:foreground ,night-owl-foreground
                      :weight bold))))

   `(mode-line
     ((t (:inverse-video unspecified
                         :underline unspecified
                         :foreground ,night-owl-foreground
                         :background ,night-owl-background-highlight
                         :box (:color ,night-owl-background-highlight
                                      :line-width 1)))))

   `(mode-line-highlight
     ((t (:box nil))))

   `(powerline-active1
     ((t (:background ,night-owl-gray-d))))

   `(powerline-active2
     ((t (:background ,night-owl-background))))


   `(mode-line-inactive
     ((t (:inverse-video unspecified
                         :underline unspecified
                         :foreground ,night-owl-foreground-muted
                         :background ,night-owl-background
                         :box (:color ,night-owl-gray
                                      :line-width 1)))))

   `(powerline-inactive1
     ((t (:background ,night-owl-gray-d))))

   `(powerline-inactive2
     ((t (:background ,night-owl-background))))
   ;; }}}

   ;; header-line {{{
   `(header-line
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-highlight
                      :box (:color ,night-owl-gray
                                   :line-width 1
                                   :style unspecified)))))
   ;; }}}

   ;; cua {{{
   `(cua-global-mark
     ((t (:background ,night-owl-yellow
                      :foreground ,night-owl-background))))

   `(cua-rectangle
     ((t (:inherit region))))

   `(cua-rectangle-noselect
     ((t (:inherit secondary-selection))))
   ;; }}}

   ;; diary {{{
   `(diary
     ((t (:foreground ,night-owl-yellow))))
   ;; }}}

   ;; dired {{{
   `(dired-directory
     ((t (:foreground ,night-owl-blue))))

   `(dired-flagged
     ((t (:foreground ,night-owl-magenta))))

   `(dired-header
     ((t (:foreground ,night-owl-blue
                      :background ,night-owl-background
                      :inherit bold))))

   `(dired-ignored
     ((t (:inherit shadow))))

   `(dired-mark
     ((t (:foreground ,night-owl-orange
                      :weight bold))))

   `(dired-marked
     ((t (:foreground ,night-owl-violet
                      :inherit bold))))

   `(dired-perm-write
     ((t (:foreground ,night-owl-foreground
                      :underline t))))

   `(dired-symlink
     ((t (:foreground ,night-owl-cyan
                      :slant italic))))

   `(dired-warning
     ((t (:foreground ,night-owl-green
                      :underline t))))
   ;; }}}

   ;; dired+ {{{
   `(diredp-compressed-file-suffix
     ((t (:foreground ,night-owl-blue))))

   `(diredp-compressed-file-name
     ((t (:foreground ,night-owl-blue))))

   `(diredp-deletion
     ((t (:inherit error
                   :inverse-video t))))

   `(diredp-deletion-file-name
     ((t (:inherit error))))

   `(diredp-date-time
     ((t (:foreground ,night-owl-cyan))))

   `(diredp-dir-heading
     ((t (:foreground ,night-owl-green
                      :weight bold))))

   `(diredp-dir-name
     ((t (:foreground ,night-owl-blue))))

   `(diredp-dir-priv
     ((t (:foreground ,night-owl-violet
                      :background nil))))

   `(diredp-exec-priv
     ((t (:foreground ,night-owl-orange
                      :background nil))))

   `(diredp-executable-tag
     ((t (:foreground ,night-owl-red
                      :background nil))))

   `(diredp-file-name
     ((t (:foreground ,night-owl-orange-d))))

   `(diredp-file-suffix
     ((t (:foreground ,night-owl-green))))

   `(diredp-flag-mark
     ((t (:foreground ,night-owl-green
                      :inverse-video t))))

   `(diredp-flag-mark-line
     ((t (:background nil
                      :inherit highlight))))

   `(diredp-ignored-file-name
     ((t (:foreground ,night-owl-comments))))

   `(diredp-link-priv
     ((t (:foreground ,night-owl-violet
                      :background nil))))

   `(diredp-mode-line-flagged
     ((t (:foreground ,night-owl-red))))

   `(diredp-mode-line-marked
     ((t (:foreground ,night-owl-green))))

   `(diredp-no-priv
     ((t (:background nil))))

   `(diredp-number
     ((t (:foreground ,night-owl-orange))))

   `(diredp-other-priv
     ((t (:foreground ,night-owl-violet
                      :background nil))))

   `(diredp-rare-priv
     ((t (:foreground ,night-owl-red :background nil))))

   `(diredp-read-priv
     ((t (:foreground ,night-owl-green :background nil))))

   `(diredp-symlink
     ((t (:foreground ,night-owl-violet))))

   `(diredp-write-priv
     ((t (:foreground ,night-owl-orange
                      :background nil))))
   ;; }}}

   ;; dropdown {{{
   `(dropdown-list-face
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-blue))))

   `(dropdown-list-selection-face
     ((t (:background ,night-owl-orange
                      :foreground ,night-owl-background))))
   ;; }}}

   ;; ecb {{{
   `(ecb-default-highlight-face
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-background))))

   `(ecb-history-bucket-node-dir-soure-path-face
     ((t (:inherit ecb-history-bucket-node-face
                   :foreground ,night-owl-yellow))))

   `(ecb-source-in-directories-buffer-face
     ((t (:inherit ecb-directories-general-face
                   :foreground ,night-owl-foreground))))

   `(ecb-history-dead-buffer-face
     ((t (:inherit ecb-history-general-face
                   :foreground ,night-owl-comments))))

   `(ecb-directory-not-accessible-face
     ((t (:inherit ecb-directories-general-face
                   :foreground ,night-owl-comments))))

   `(ecb-bucket-node-face
     ((t (:inherit ecb-default-general-face
                   :weight normal
                   :foreground ,night-owl-blue))))

   `(ecb-tag-header-face
     ((t (:background ,night-owl-highlight-line))))

   `(ecb-analyse-bucket-element-face
     ((t (:inherit ecb-analyse-general-face
                   :foreground ,night-owl-orange))))

   `(ecb-directories-general-face
     ((t (:inherit ecb-default-general-face
                   :height 1.0))))

   `(ecb-method-non-semantic-face
     ((t (:inherit ecb-methods-general-face
                   :foreground ,night-owl-cyan))))

   `(ecb-mode-line-prefix-face
     ((t (:foreground ,night-owl-orange))))

   `(ecb-tree-guide-line-face
     ((t (:inherit ecb-default-general-face
                   :foreground ,night-owl-gray
                   :height 1.0))))
   ;; }}}

   ;; ee {{{
   `(ee-bookmarked
     ((t (:foreground ,night-owl-emphasis))))

   `(ee-category
     ((t (:foreground ,night-owl-blue))))

   `(ee-link
     ((t (:inherit link))))

   `(ee-link-visited
     ((t (:inherit link-visited))))

   `(ee-marked
     ((t (:foreground ,night-owl-red
                      :weight bold))))

   `(ee-omitted
     ((t (:foreground ,night-owl-comments))))

   `(ee-shadow
     ((t (:inherit shadow))))
   ;; }}}

   ;; grep {{{
   `(grep-context-face
     ((t (:foreground ,night-owl-foreground))))

   `(grep-error-face
     ((t (:foreground ,night-owl-magenta
                      :weight bold
                      :underline t))))

   `(grep-hit-face
     ((t (:foreground ,night-owl-orange))))

   `(grep-match-face
     ((t (:foreground ,night-owl-green
                      :weight bold))))
   ;; }}}

   ;; isearch {{{
   `(isearch
     ((t (:inherit region
                   :foreground ,night-owl-background
                   :background ,night-owl-yellow))))

   `(isearch-fail
     ((t (:inherit isearch
                   :foreground ,night-owl-magenta
                   :background ,night-owl-background
                   :bold t))))
   ;; }}}

   ;; ace-jump-mode {{{
   `(ace-jump-face-background
     ((t (:foreground ,night-owl-comments
                      :background ,night-owl-background
                      :inverse-video nil))))

   `(ace-jump-face-foreground
     ((t (:foreground ,night-owl-yellow
                      :background ,night-owl-background
                      :inverse-video nil
                      :weight bold))))
   ;; }}}

   ;; ace-window {{{
   `(aw-background-face
     ((t (:foreground ,night-owl-comments
                      :background ,night-owl-highlight-line))))

   `(aw-leading-char-face
     ((t (:foreground ,night-owl-white))))
   ;; }}}

   ;; auctex {{{
   `(font-latex-bold-face
     ((t (:inherit bold
                   :foreground ,night-owl-emphasis))))

   `(font-latex-doctex-documentation-face
     ((t (:background unspecified))))

   `(font-latex-doctex-preprocessor-face
     ((t
       (:inherit (font-latex-doctex-documentation-face
                  font-lock-builtin-face
                  font-lock-preprocessor-face)))
      (t
       (:inherit (font-latex-doctex-documentation-face
                  font-lock-builtin-face
                  font-lock-preprocessor-face)))))

   `(font-latex-italic-face
     ((t (:inherit italic :foreground ,night-owl-emphasis))))

   `(font-latex-math-face
     ((t (:foreground ,night-owl-violet))))

   `(font-latex-sectioning-0-face
     ((t (:inherit font-latex-sectioning-1-face
                   :height ,night-owl-height-plus-1))))

   `(font-latex-sectioning-1-face
     ((t (:inherit font-latex-sectioning-2-face
                   :height ,night-owl-height-plus-1))))

   `(font-latex-sectioning-2-face
     ((t (:inherit font-latex-sectioning-3-face
                   :height ,night-owl-height-plus-1))))

   `(font-latex-sectioning-3-face
     ((t (:inherit font-latex-sectioning-4-face
                   :height ,night-owl-height-plus-1))))

   `(font-latex-sectioning-4-face
     ((t (:inherit font-latex-sectioning-5-face
                   :height ,night-owl-height-plus-1))))

   `(font-latex-sectioning-5-face
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-yellow
                   :weight bold))))

   `(font-latex-sedate-face
     ((t (:foreground ,night-owl-emphasis))))

   `(font-latex-slide-title-face
     ((t (:inherit (,night-owl-pitch font-lock-type-face)
                   :weight bold
                   :height ,night-owl-height-plus-3))))

   `(font-latex-string-face
     ((t (:foreground ,night-owl-cyan))))

   `(font-latex-subscript-face
     ((t (:height ,night-owl-height-minus-1))))

   `(font-latex-superscript-face
     ((t (:height ,night-owl-height-minus-1))))

   `(font-latex-verbatim-face
     ((t (:inherit fixed-pitch
                   :foreground ,night-owl-foreground
                   :slant italic))))

   `(font-latex-warning-face
     ((t (:inherit bold
                   :foreground ,night-owl-green))))
   ;; }}}

   ;; auto-complete {{{
   `(ac-candidate-face
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-blue))))

   `(ac-selection-face
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-background))))

   `(ac-candidate-mouse-face
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-background))))

   `(ac-completion-face
     ((t (:foreground ,night-owl-emphasis
                      :underline t))))

   `(ac-gtags-candidate-face
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-blue))))

   `(ac-gtags-selection-face
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-background))))

   `(ac-yasnippet-candidate-face
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-yellow))))

   `(ac-yasnippet-selection-face
     ((t (:background ,night-owl-yellow
                      :foreground ,night-owl-background))))
   ;; }}}

   ;; auto highlight symbol {{{
   `(ahs-definition-face
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-blue))))

   `(ahs-edit-mode-face
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-highlight))))

   `(ahs-face
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-yellow))))

   `(ahs-plugin-bod-face
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-violet ))))

   `(ahs-plugin-defalt-face
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-green))))

   `(ahs-plugin-whole-buffer-face
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-orange))))

   `(ahs-warning-face
     ((t (:foreground ,night-owl-magenta
                      :weight bold))))
   ;; }}}

   ;; android mode {{{
   `(android-mode-debug-face
     ((t (:foreground ,night-owl-orange))))

   `(android-mode-error-face
     ((t (:foreground ,night-owl-red
                      :weight bold))))

   `(android-mode-info-face
     ((t (:foreground ,night-owl-foreground))))

   `(android-mode-verbose-face
     ((t (:foreground ,night-owl-comments))))

   `(android-mode-warning-face
     ((t (:foreground ,night-owl-yellow))))
   ;; }}}

   ;; anzu-mode {{{
   `(anzu-mode-line
     ((t (:foreground ,night-owl-violet
                      :weight bold))))
   ;; }}}

   ;; bm {{{
   `(bm-face
     ((t (:background ,night-owl-yellow-lc
                      :foreground ,night-owl-background))))

   `(bm-fringe-face
     ((t (:background ,night-owl-yellow-lc
                      :foreground ,night-owl-background))))

   `(bm-fringe-persistent-face
     ((t (:background ,night-owl-orange-lc
                      :foreground ,night-owl-background))))

   `(bm-persistent-face
     ((t (:background ,night-owl-orange-lc
                      :foreground ,night-owl-background))))
   ;; }}}

   ;; calfw {{{
   `(cfw:face-day-title
     ((t (:background ,night-owl-highlight-line))))

   `(cfw:face-annotation
     ((t (:inherit cfw:face-day-title
                   :foreground ,night-owl-yellow))))

   `(cfw:face-default-content
     ((t (:foreground ,night-owl-orange))))

   `(cfw:face-default-day
     ((t (:inherit cfw:face-day-title
                   :weight bold))))

   `(cfw:face-disable
     ((t (:inherit cfw:face-day-title
                   :foreground ,night-owl-comments))))

   `(cfw:face-grid
     ((t (:foreground ,night-owl-comments))))

   `(cfw:face-header
     ((t (:foreground ,night-owl-blue-hc
                      :background ,night-owl-blue-lc
                      :weight bold))))

   `(cfw:face-holiday
     ((t (:background nil
                      :foreground ,night-owl-magenta
                      :weight bold))))

   `(cfw:face-periods
     ((t (:foreground ,night-owl-red))))

   `(cfw:face-select
     ((t (:background ,night-owl-red-lc
                      :foreground ,night-owl-red-hc))))

   `(cfw:face-saturday
     ((t (:foreground ,night-owl-cyan-hc
                      :background ,night-owl-cyan-lc))))

   `(cfw:face-sunday
     ((t (:foreground ,night-owl-magenta-hc
                      :background ,night-owl-magenta-lc
                      :weight bold))))

   `(cfw:face-title
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-yellow
                   :weight bold
                   :height ,night-owl-height-plus-4))))

   `(cfw:face-today
     ((t (:weight bold
                  :background ,night-owl-highlight-line
                  :foreground nil))))

   `(cfw:face-today-title
     ((t (:background ,night-owl-yellow-lc
                      :foreground ,night-owl-yellow-hc
                      :weight bold))))

   `(cfw:face-toolbar
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-foreground))))

   `(cfw:face-toolbar-button-off
     ((t (:background ,night-owl-yellow-lc
                      :foreground ,night-owl-yellow-hc
                      :weight bold))))

   `(cfw:face-toolbar-button-on
     ((t (:background ,night-owl-yellow-hc
                      :foreground ,night-owl-yellow-lc
                      :weight bold))))
   ;; }}}

   ;; cider {{{
   `(cider-enlightened
     ((t (:foreground ,night-owl-yellow
                      :background nil
                      :box (:color ,night-owl-yellow :line-width -1 :style nil)))))

   `(cider-enlightened-local
     ((t (:foreground ,night-owl-yellow))))

   `(cider-instrumented-face
     ((t (:foreground ,night-owl-violet
                      :background nil
                      :box (:color ,night-owl-violet :line-width -1 :style nil)))))

   `(cider-result-overlay-face
     ((t (:foreground ,night-owl-blue
                      :background nil
                      :box (:color ,night-owl-blue :line-width -1 :style nil)))))

   `(cider-test-error-face
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-red))))

   `(cider-test-failure-face
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-magenta))))

   `(cider-test-success-face
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-green))))

   `(cider-traced-face
     ((t :box (:color ,night-owl-blue :line-width -1 :style nil))))
   ;; }}}

   ;; clojure-test {{{
   `(clojure-test-failure-face
     ((t (:foreground ,night-owl-magenta
                      :weight bold
                      :underline t))))

   `(clojure-test-error-face
     ((t (:foreground ,night-owl-red
                      :weight bold
                      :underline t))))

   `(clojure-test-success-face
     ((t (:foreground ,night-owl-green
                      :weight bold
                      :underline t))))
   ;; }}}

   ;; company-mode {{{
   `(company-tooltip
     ((t (:background ,night-owl-suggest-bg
                      :foreground ,night-owl-foreground))))

   `(company-tooltip-annotation
     ((t (:background ,night-owl-suggest-bg
                      :foreground ,night-owl-green))))

   `(company-tooltip-annotation-selection
     ((t (:background ,night-owl-gray
                      :foreground ,night-owl-green))))

   `(company-tooltip-selection
     ((t (:background ,night-owl-gray
                      :foreground ,night-owl-foreground))))

   `(company-tooltip-mouse
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-background))))

   `(company-tooltip-common
     ((t (:foreground ,night-owl-white
                      :bold t))))

   `(company-tooltip-common-selection
     ((t (:foreground ,night-owl-white
                      :bold t))))

   `(company-preview
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-emphasis))))

   `(company-preview-common
     ((t (:foreground ,night-owl-blue
                      :underline t))))

   `(company-scrollbar-bg
     ((t (:background ,night-owl-suggest-bg))))

   `(company-scrollbar-fg
     ((t (:background ,night-owl-highlight-alt))))

   `(company-tooltip-annotation
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-blue))))

   `(company-template-field
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-blue))))
   ;; }}}

   ;; compilation {{{
   `(compilation-column-face
     ((t (:foreground ,night-owl-cyan
                      :underline nil))))

   `(compilation-column-number
     ((t (:inherit font-lock-doc-face
                   :foreground ,night-owl-cyan
                   :underline nil))))

   `(compilation-enter-directory-face
     ((t (:foreground ,night-owl-orange
                      :underline nil))))

   `(compilation-error
     ((t (:inherit error
                   :underline nil))))

   `(compilation-error-face
     ((t (:foreground ,night-owl-red
                      :underline nil))))

   `(compilation-face
     ((t (:foreground ,night-owl-foreground
                      :underline nil))))

   `(compilation-info
     ((t (:foreground ,night-owl-comments
                      :underline nil
                      :bold nil))))

   `(compilation-info-face
     ((t (:foreground ,night-owl-blue
                      :underline nil))))

   `(compilation-leave-directory-face
     ((t (:foreground ,night-owl-orange
                      :underline nil))))

   `(compilation-line-face
     ((t (:foreground ,night-owl-orange
                      :underline nil))))

   `(compilation-line-number
     ((t (:foreground ,night-owl-orange
                      :underline nil))))

   `(compilation-warning
     ((t (:inherit warning
                   :underline nil))))

   `(compilation-warning-face
     ((t (:foreground ,night-owl-yellow
                      :weight normal
                      :underline nil))))

   `(compilation-mode-line-exit
     ((t (:inherit compilation-info
                   :foreground ,night-owl-orange
                   :weight bold))))

   `(compilation-mode-line-fail
     ((t (:inherit compilation-error
                   :foreground ,night-owl-red
                   :weight bold))))

   `(compilation-mode-line-run
     ((t (:foreground ,night-owl-green
                      :weight bold))))
   ;; }}}

   ;; CSCOPE {{{
   `(cscope-file-face
     ((t (:foreground ,night-owl-orange
                      :weight bold))))

   `(cscope-function-face
     ((t (:foreground ,night-owl-blue))))

   `(cscope-line-number-face
     ((t (:foreground ,night-owl-yellow))))

   `(cscope-line-face
     ((t (:foreground ,night-owl-foreground))))

   `(cscope-mouse-face
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-foreground))))
   ;; }}}

   ;; ctable {{{
   `(ctbl:face-cell-select
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-emphasis
                      :underline ,night-owl-emphasis
                      :weight bold))))

   `(ctbl:face-continue-bar
     ((t (:background ,night-owl-gray
                      :foreground ,night-owl-yellow))))

   `(ctbl:face-row-select
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-foreground
                      :underline t))))
   ;; }}}

   ;; coffee {{{
   `(coffee-mode-class-name
     ((t (:foreground ,night-owl-yellow
                      :weight bold))))

   `(coffee-mode-function-param
     ((t (:foreground ,night-owl-violet
                      :slant italic))))
   ;; }}}

   ;; custom {{{
   `(custom-face-tag
     ((t (:inherit ,night-owl-pitch
                   :height ,night-owl-height-plus-3
                   :foreground ,night-owl-violet
                   :weight bold))))

   `(custom-variable-tag
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-cyan
                   :height ,night-owl-height-plus-3))))

   `(custom-comment-tag
     ((t (:foreground ,night-owl-comments))))

   `(custom-group-tag
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-blue
                   :height ,night-owl-height-plus-3))))

   `(custom-group-tag-1
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-magenta
                   :height ,night-owl-height-plus-3))))

   `(custom-state
     ((t (:foreground ,night-owl-orange))))
   ;; }}}

   ;; diff {{{
   `(diff-added
     ((t (:foreground ,night-owl-orange
                      :background ,night-owl-background))))

   `(diff-changed
     ((t (:foreground ,night-owl-blue
                      :background ,night-owl-background))))

   `(diff-removed
     ((t (:foreground ,night-owl-magenta
                      :background ,night-owl-background))))

   `(diff-header
     ((t (:background ,night-owl-background))))

   `(diff-file-header
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-foreground
                      :weight bold))))

   `(diff-refine-added
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-green))))

   `(diff-refine-change
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-blue))))

   `(diff-refine-removed
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-red))))
   ;; }}}

   ;; diff-hl {{{
   `(diff-hl-change
     ((t (:background ,night-owl-blue-lc
                      :foreground ,night-owl-blue-hc))))

   `(diff-hl-delete
     ((t (:background ,night-owl-magenta-lc
                      :foreground ,night-owl-magenta-hc))))

   `(diff-hl-insert
     ((t (:background ,night-owl-green-lc
                      :foreground ,night-owl-green-hc))))

   `(diff-hl-unknown
     ((t (:background ,night-owl-violet-lc
                      :foreground ,night-owl-violet-hc))))
   ;; }}}

   ;; ediff {{{
   `(ediff-fine-diff-A
     ((t (:background ,night-owl-orange-lc))))

   `(ediff-fine-diff-B
     ((t (:background ,night-owl-green-lc))))

   `(ediff-fine-diff-C
     ((t (:background ,night-owl-yellow-lc))))

   `(ediff-current-diff-C
     ((t (:background ,night-owl-blue-lc))))

   `(ediff-even-diff-A
     ((t (:background ,night-owl-comments
                      :foreground ,night-owl-foreground-lc ))))

   `(ediff-odd-diff-A
     ((t (:background ,night-owl-comments
                      :foreground ,night-owl-foreground-hc ))))

   `(ediff-even-diff-B
     ((t (:background ,night-owl-comments
                      :foreground ,night-owl-foreground-hc ))))

   `(ediff-odd-diff-B
     ((t (:background ,night-owl-comments
                      :foreground ,night-owl-foreground-lc ))))

   `(ediff-even-diff-C
     ((t (:background ,night-owl-comments
                      :foreground ,night-owl-foreground ))))

   `(ediff-odd-diff-C
     ((t (:background ,night-owl-comments
                      :foreground ,night-owl-background ))))
   ;; }}}

   ;; edts {{{
   `(edts-face-error-line
     ((((supports :underline (:style line)))
       (:underline (:style line :color ,night-owl-red)
                   :inherit unspecified))
      (t (:foreground ,night-owl-red-hc
                      :background ,night-owl-red-lc
                      :weight bold
                      :underline t))))

   `(edts-face-warning-line
     ((((supports :underline (:style line)))
       (:underline (:style line :color ,night-owl-yellow)
                   :inherit unspecified))
      (t (:foreground ,night-owl-yellow-hc
                      :background ,night-owl-yellow-lc
                      :weight bold
                      :underline t))))

   `(edts-face-error-fringe-bitmap
     ((t (:foreground ,night-owl-red
                      :background unspecified
                      :weight bold))))

   `(edts-face-warning-fringe-bitmap
     ((t (:foreground ,night-owl-yellow
                      :background unspecified
                      :weight bold))))

   `(edts-face-error-mode-line
     ((t (:background ,night-owl-red
                      :foreground unspecified))))

   `(edts-face-warning-mode-line
     ((t (:background ,night-owl-yellow
                      :foreground unspecified))))
   ;; }}}

   ;; elfeed {{{
   `(elfeed-search-date-face
     ((t (:foreground ,night-owl-comments))))

   `(elfeed-search-feed-face
     ((t (:foreground ,night-owl-comments))))

   `(elfeed-search-tag-face
     ((t (:foreground ,night-owl-foreground))))

   `(elfeed-search-title-face
     ((t (:foreground ,night-owl-cyan))))
   ;; }}}

   ;; elixir {{{
   `(elixir-attribute-face
     ((t (:foreground ,night-owl-green))))

   `(elixir-atom-face
     ((t (:foreground ,night-owl-violet))))
   ;; }}}

   ;; ein {{{
   `(ein:cell-input-area
     ((t (:background ,night-owl-highlight-line))))
   `(ein:cell-input-prompt
     ((t (:foreground ,night-owl-orange))))
   `(ein:cell-output-prompt
     ((t (:foreground ,night-owl-magenta))))
   `(ein:notification-tab-normal
     ((t (:foreground ,night-owl-blue))))
   `(ein:notification-tab-selected
     ((t (:foreground ,night-owl-green :inherit bold))))
   ;; }}}

   ;; enhanced ruby mode {{{
   `(enh-ruby-string-delimiter-face
     ((t (:inherit font-lock-string-face))))

   `(enh-ruby-heredoc-delimiter-face
     ((t (:inherit font-lock-string-face))))

   `(enh-ruby-regexp-delimiter-face
     ((t (:inherit font-lock-string-face))))

   `(enh-ruby-op-face
     ((t (:inherit font-lock-keyword-face))))
   ;; }}}

   ;; erm-syn {{{
   `(erm-syn-errline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,night-owl-magenta)
                   :inherit unspecified))
      (t (:foreground ,night-owl-magenta-hc
                      :background ,night-owl-magenta-lc
                      :weight bold
                      :underline t))))

   `(erm-syn-warnline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,night-owl-green)
                   :inherit unspecified))
      (t (:foreground ,night-owl-green-hc
                      :background ,night-owl-green-lc
                      :weight bold
                      :underline t))))
   ;; }}}

   ;; epc {{{
   `(epc:face-title
     ((t (:foreground ,night-owl-blue
                      :background ,night-owl-background
                      :weight normal
                      :underline nil))))
   ;; }}}

   ;; erc {{{
   `(erc-action-face
     ((t (:inherit erc-default-face))))

   `(erc-bold-face
     ((t (:weight bold))))

   `(erc-current-nick-face
     ((t (:foreground ,night-owl-blue :weight bold))))

   `(erc-dangerous-host-face
     ((t (:inherit font-lock-warning-face))))

   `(erc-default-face
     ((t (:foreground ,night-owl-foreground))))

   `(erc-highlight-face
     ((t (:inherit erc-default-face
                   :background ,night-owl-highlight))))

   `(erc-direct-msg-face
     ((t (:inherit erc-default-face))))

   `(erc-error-face
     ((t (:inherit font-lock-warning-face))))

   `(erc-fool-face
     ((t (:inherit erc-default-face))))

   `(erc-input-face
     ((t (:foreground ,night-owl-yellow))))

   `(erc-keyword-face
     ((t (:foreground ,night-owl-blue
                      :weight bold))))

   `(erc-nick-default-face
     ((t (:foreground ,night-owl-yellow
                      :weight bold))))

   `(erc-my-nick-face
     ((t (:foreground ,night-owl-magenta
                      :weight bold))))

   `(erc-nick-msg-face
     ((t (:inherit erc-default-face))))

   `(erc-notice-face
     ((t (:foreground ,night-owl-orange))))

   `(erc-pal-face
     ((t (:foreground ,night-owl-green
                      :weight bold))))

   `(erc-prompt-face
     ((t (:foreground ,night-owl-green
                      :background ,night-owl-background
                      :weight bold))))

   `(erc-timestamp-face
     ((t (:foreground ,night-owl-orange))))

   `(erc-underline-face
     ((t (:underline t))))
   ;; }}}

   ;; eshell {{{
   `(eshell-prompt
     ((t (:foreground ,night-owl-blue
                      :inherit bold))))

   `(eshell-ls-archive
     ((t (:foreground ,night-owl-magenta
                      :weight bold))))

   `(eshell-ls-backup
     ((t (:inherit font-lock-comment-face))))

   `(eshell-ls-clutter
     ((t (:inherit font-lock-comment-face))))

   `(eshell-ls-directory
     ((t (:foreground ,night-owl-blue
                      :inherit bold))))

   `(eshell-ls-executable
     ((t (:foreground ,night-owl-orange
                      :inherit bold))))

   `(eshell-ls-unreadable
     ((t (:foreground ,night-owl-foreground))))

   `(eshell-ls-missing
     ((t (:inherit font-lock-warning-face))))

   `(eshell-ls-product
     ((t (:inherit font-lock-doc-face))))

   `(eshell-ls-special
     ((t (:foreground ,night-owl-yellow
                      :inherit bold))))

   `(eshell-ls-symlink
     ((t (:foreground ,night-owl-cyan
                      :inherit bold))))
   ;; }}}

   ;; evil-ex-substitute {{{
   `(evil-ex-substitute-matches
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-magenta-l
                      :inherit italic))))
   `(evil-ex-substitute-replacement
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-orange-l
                      :inherit italic))))
   ;; }}}

   ;; evil-search-highlight-persist {{{
   `(evil-search-highlight-persist-highlight-face
     ((t (:inherit region))))
   ;; }}}

   ;; fic {{{
   `(fic-author-face
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-green
                      :underline t
                      :slant italic))))

   `(fic-face
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-green
                      :weight normal
                      :slant italic))))

   `(font-lock-fic-face
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-green
                      :weight normal
                      :slant italic))))
   ;; }}}

   ;; flx {{{
   `(flx-highlight-face
     ((t (:foreground ,night-owl-blue
                      :weight normal
                      :underline nil))))
   ;; }}}

   ;; flymake {{{
   `(flymake-errline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,night-owl-magenta)
                   :inherit unspecified
                   :foreground unspecified
                   :background unspecified))
      (t (:foreground ,night-owl-magenta-hc
                      :background ,night-owl-magenta-lc
                      :weight bold
                      :underline t))))

   `(flymake-infoline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,night-owl-orange)
                   :inherit unspecified
                   :foreground unspecified
                   :background unspecified))
      (t (:foreground ,night-owl-orange-hc
                      :background ,night-owl-orange-lc))))

   `(flymake-warnline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,night-owl-yellow)
                   :inherit unspecified
                   :foreground unspecified
                   :background unspecified))
      (t (:foreground ,night-owl-yellow-hc
                      :background ,night-owl-yellow-lc
                      :weight bold
                      :underline t))))
   ;; }}}

   ;; flycheck {{{
   `(flycheck-error
     ((((supports :underline (:style line)))
       (:underline (:style line :color ,night-owl-red)))
      (t (:foreground ,night-owl-red
                      :background ,night-owl-background
                      :weight bold
                      :underline t))))

   `(flycheck-warning
     ((((supports :underline (:style line)))
       (:underline (:style line :color ,night-owl-green)))
      (t (:foreground ,night-owl-orange
                      :background ,night-owl-background
                      :weight bold
                      :underline t))))

   `(flycheck-info
     ((((supports :underline (:style line)))
       (:underline (:style line :color ,night-owl-blue)))
      (t (:foreground ,night-owl-blue
                      :background ,night-owl-background
                      :weight bold
                      :underline t))))

   `(flycheck-fringe-error
     ((t (:foreground ,night-owl-red-l
                      :background unspecified
                      :weight bold))))

   `(flycheck-fringe-warning
     ((t (:foreground ,night-owl-orange-l
                      :background unspecified
                      :weight bold))))

   `(flycheck-fringe-info
     ((t (:foreground ,night-owl-blue-l
                      :background unspecified
                      :weight bold))))
   ;; }}}

   ;; flyspell {{{
   `(flyspell-duplicate
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,night-owl-yellow)
                   :inherit unspecified))
      (t (:foreground ,night-owl-yellow
                      :weight bold
                      :underline t))))

   `(flyspell-incorrect
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,night-owl-magenta)
                   :inherit unspecified))
      (t (:foreground ,night-owl-magenta
                      :weight bold
                      :underline t))))
   ;; }}}

   ;; git-gutter {{{
   `(git-gutter:added
     ((t (:background ,night-owl-orange
                      :foreground ,night-owl-background
                      :inherit bold))))

   `(git-gutter:deleted
     ((t (:background ,night-owl-magenta
                      :foreground ,night-owl-background
                      :inherit bold))))

   `(git-gutter:modified
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-background
                      :inherit bold))))

   `(git-gutter:unchanged
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-background
                      :inherit bold))))
   ;; }}}

   ;; git-gutter-fr {{{
   `(git-gutter-fr:added
     ((t (:foreground ,night-owl-orange
                      :inherit bold))))

   `(git-gutter-fr:deleted
     ((t (:foreground ,night-owl-magenta
                      :inherit bold))))

   `(git-gutter-fr:modified
     ((t (:foreground ,night-owl-blue
                      :inherit bold))))
   ;; }}}

   ;; git-gutter+ and git-gutter+-fr {{{
   `(git-gutter+-added
     ((t (:background ,night-owl-orange
                      :foreground ,night-owl-background
                      :inherit bold))))

   `(git-gutter+-deleted
     ((t (:background ,night-owl-magenta
                      :foreground ,night-owl-background
                      :inherit bold))))

   `(git-gutter+-modified
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-background
                      :inherit bold))))

   `(git-gutter+-unchanged
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-background
                      :inherit bold))))

   `(git-gutter-fr+-added
     ((t (:foreground ,night-owl-orange
                      :weight bold))))

   `(git-gutter-fr+-deleted
     ((t (:foreground ,night-owl-magenta
                      :weight bold))))

   `(git-gutter-fr+-modified
     ((t (:foreground ,night-owl-blue
                      :weight bold))))
   ;; }}}

   ;; git-timemachine {{{
   `(git-timemachine-minibuffer-detail-face
     ((t (:foreground ,night-owl-blue
                      :background ,night-owl-highlight-line
                      :inherit bold))))
   ;; }}}

   ;; guide-key {{{
   `(guide-key/highlight-command-face
     ((t (:foreground ,night-owl-blue))))

   `(guide-key/key-face
     ((t (:foreground ,night-owl-green))))

   `(guide-key/prefix-command-face
     ((t (:foreground ,night-owl-violet))))
   ;; }}}

   ;; gnus {{{
   `(gnus-group-mail-1
     ((t (:weight bold
                  :inherit gnus-group-mail-1-empty))))

   `(gnus-group-mail-1-empty
     ((t (:inherit gnus-group-news-1-empty))))

   `(gnus-group-mail-2
     ((t (:weight bold
                  :inherit gnus-group-mail-2-empty))))

   `(gnus-group-mail-2-empty
     ((t (:inherit gnus-group-news-2-empty))))

   `(gnus-group-mail-3
     ((t (:weight bold
                  :inherit gnus-group-mail-3-empty))))

   `(gnus-group-mail-3-empty
     ((t (:inherit gnus-group-news-3-empty))))

   `(gnus-group-mail-low
     ((t (:weight bold
                  :inherit gnus-group-mail-low-empty))))

   `(gnus-group-mail-low-empty
     ((t (:inherit gnus-group-news-low-empty))))

   `(gnus-group-news-1
     ((t (:weight bold
                  :inherit gnus-group-news-1-empty))))

   `(gnus-group-news-2
     ((t (:weight bold
                  :inherit gnus-group-news-2-empty))))

   `(gnus-group-news-3
     ((t (:weight bold
                  :inherit gnus-group-news-3-empty))))

   `(gnus-group-news-4
     ((t (:weight bold
                  :inherit gnus-group-news-4-empty))))

   `(gnus-group-news-5
     ((t (:weight bold
                  :inherit gnus-group-news-5-empty))))

   `(gnus-group-news-6
     ((t (:weight bold
                  :inherit gnus-group-news-6-empty))))

   `(gnus-group-news-low
     ((t (:weight bold
                  :inherit gnus-group-news-low-empty))))

   `(gnus-header-content
     ((t (:inherit message-header-other))))

   `(gnus-header-from
     ((t (:inherit message-header-other))))

   `(gnus-header-name
     ((t (:inherit message-header-name))))

   `(gnus-header-newsgroups
     ((t (:inherit message-header-other))))

   `(gnus-header-subject
     ((t (:inherit message-header-subject))))

   `(gnus-summary-cancelled
     ((t (:foreground ,night-owl-green))))

   `(gnus-summary-high-ancient
     ((t (:foreground ,night-owl-blue
                      :weight bold))))

   `(gnus-summary-high-read
     ((t (:foreground ,night-owl-orange
                      :weight bold))))

   `(gnus-summary-high-ticked
     ((t (:foreground ,night-owl-green
                      :weight bold))))

   `(gnus-summary-high-unread
     ((t (:foreground ,night-owl-foreground
                      :weight bold))))

   `(gnus-summary-low-ancient
     ((t (:foreground ,night-owl-blue))))

   `(gnus-summary-low-read
     ((t (:foreground ,night-owl-orange))))

   `(gnus-summary-low-ticked
     ((t (:foreground ,night-owl-green))))

   `(gnus-summary-low-unread
     ((t (:foreground ,night-owl-foreground))))

   `(gnus-summary-normal-ancient
     ((t (:foreground ,night-owl-blue))))

   `(gnus-summary-normal-read
     ((t (:foreground ,night-owl-orange))))

   `(gnus-summary-normal-ticked
     ((t (:foreground ,night-owl-green))))

   `(gnus-summary-normal-unread
     ((t (:foreground ,night-owl-foreground))))

   `(gnus-summary-selected
     ((t (:foreground ,night-owl-yellow
                      :weight bold))))

   `(gnus-cite-1
     ((t (:foreground ,night-owl-blue))))

   `(gnus-cite-2
     ((t (:foreground ,night-owl-blue))))

   `(gnus-cite-3
     ((t (:foreground ,night-owl-blue))))

   `(gnus-cite-4
     ((t (:foreground ,night-owl-orange))))

   `(gnus-cite-5
     ((t (:foreground ,night-owl-orange))))

   `(gnus-cite-6
     ((t (:foreground ,night-owl-orange))))

   `(gnus-cite-7
     ((t (:foreground ,night-owl-magenta))))

   `(gnus-cite-8
     ((t (:foreground ,night-owl-magenta))))

   `(gnus-cite-9
     ((t (:foreground ,night-owl-magenta))))

   `(gnus-cite-10
     ((t (:foreground ,night-owl-yellow))))

   `(gnus-cite-11
     ((t (:foreground ,night-owl-yellow))))

   `(gnus-group-news-1-empty
     ((t (:foreground ,night-owl-yellow))))

   `(gnus-group-news-2-empty
     ((t (:foreground ,night-owl-orange))))

   `(gnus-group-news-3-empty
     ((t (:foreground ,night-owl-orange))))

   `(gnus-group-news-4-empty
     ((t (:foreground ,night-owl-blue))))

   `(gnus-group-news-5-empty
     ((t (:foreground ,night-owl-blue))))

   `(gnus-group-news-6-empty
     ((t (:foreground ,night-owl-blue-lc))))

   `(gnus-group-news-low-empty
     ((t (:foreground ,night-owl-comments))))

   `(gnus-signature
     ((t (:foreground ,night-owl-yellow))))

   `(gnus-x-face
     ((t (:background ,night-owl-foreground
                      :foreground ,night-owl-background))))
   ;; }}}

   ;; helm {{{
   `(helm-apt-deinstalled
     ((t (:foreground ,night-owl-comments))))

   `(helm-apt-installed
     ((t (:foreground ,night-owl-orange))))

   `(helm-bookmark-directory
     ((t (:inherit helm-ff-directory))))

   `(helm-bookmark-file
     ((t (:foreground ,night-owl-foreground))))

   `(helm-bookmark-gnus
     ((t (:foreground ,night-owl-cyan))))

   `(helm-bookmark-info
     ((t (:foreground ,night-owl-orange))))

   `(helm-bookmark-man
     ((t (:foreground ,night-owl-violet))))

   `(helm-bookmark-w3m
     ((t (:foreground ,night-owl-yellow))))

   `(helm-bookmarks-su
     ((t (:foreground ,night-owl-green))))

   `(helm-buffer-file
     ((t (:foreground ,night-owl-foreground))))

   `(helm-buffer-directory
     ((t (:foreground ,night-owl-blue))))

   `(helm-buffer-process
     ((t (:foreground ,night-owl-comments))))

   `(helm-buffer-saved-out
     ((t (:foreground ,night-owl-magenta
                      :background ,night-owl-background
                      :inverse-video t))))

   `(helm-buffer-size
     ((t (:foreground ,night-owl-comments))))

   `(helm-candidate-number
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-emphasis
                      :bold t))))

   `(helm-ff-directory
     ((t (:foreground ,night-owl-blue))))

   `(helm-ff-executable
     ((t (:foreground ,night-owl-orange))))

   `(helm-ff-file
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-foreground))))

   `(helm-ff-invalid-symlink
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-green
                      :slant italic))))

   `(helm-ff-prefix
     ((t (:background ,night-owl-orange
                      :foreground ,night-owl-background))))

   `(helm-ff-symlink
     ((t (:foreground ,night-owl-cyan))))

   `(helm-grep-file
     ((t (:foreground ,night-owl-cyan
                      :underline t))))

   `(helm-grep-finish
     ((t (:foreground ,night-owl-orange))))

   `(helm-grep-lineno
     ((t (:foreground ,night-owl-green))))

   `(helm-grep-match
     ((t (:inherit helm-match))))

   `(helm-grep-running
     ((t (:foreground ,night-owl-magenta))))

   `(helm-header
     ((t (:inherit header-line))))

   `(helm-lisp-completion-info
     ((t (:foreground ,night-owl-foreground))))

   `(helm-lisp-show-completion
     ((t (:foreground ,night-owl-yellow
                      :background ,night-owl-highlight-line
                      :bold t))))

   `(helm-M-x-key
     ((t (:foreground ,night-owl-green
                      :underline t))))

   `(helm-moccur-buffer
     ((t (:foreground ,night-owl-cyan
                      :underline t))))

   `(helm-match
     ((t (:foreground ,night-owl-orange :inherit bold))))

   `(helm-match-item
     ((t (:inherit helm-match))))

   `(helm-selection
     ((t (:background ,night-owl-highlight
                      :inherit bold
                      :underline nil))))

   `(helm-selection-line
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-emphasis
                      :underline nil))))

   `(helm-separator
     ((t (:foreground ,night-owl-gray))))

   `(helm-source-header
     ((t (:background ,night-owl-violet-l
                      :foreground ,night-owl-background
                      :underline nil))))

   `(helm-swoop-target-line-face
     ((t (:background ,night-owl-highlight-line))))

   `(helm-swoop-target-line-block-face
     ((t (:background ,night-owl-highlight-line))))

   `(helm-swoop-target-word-face
     ((t (:foreground ,night-owl-orange))))

   `(helm-time-zone-current
     ((t (:foreground ,night-owl-orange))))

   `(helm-time-zone-home
     ((t (:foreground ,night-owl-magenta))))

   `(helm-visible-mark
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-red :bold t))))

   ;; helm-ls-git
   `(helm-ls-git-modified-not-staged-face
     ((t :foreground ,night-owl-blue)))

   `(helm-ls-git-modified-and-staged-face
     ((t :foreground ,night-owl-blue-l)))

   `(helm-ls-git-renamed-modified-face
     ((t :foreground ,night-owl-blue-l)))

   `(helm-ls-git-untracked-face
     ((t :foreground ,night-owl-green)))

   `(helm-ls-git-added-copied-face
     ((t :foreground ,night-owl-orange)))

   `(helm-ls-git-added-modified-face
     ((t :foreground ,night-owl-orange-l)))

   `(helm-ls-git-deleted-not-staged-face
     ((t :foreground ,night-owl-magenta)))

   `(helm-ls-git-deleted-and-staged-face
     ((t :foreground ,night-owl-magenta-l)))

   `(helm-ls-git-conflict-face
     ((t :foreground ,night-owl-yellow)))
   ;; }}}

   ;; hi-lock-mode {{{
   `(hi-yellow
     ((t (:foreground ,night-owl-yellow-lc
                      :background ,night-owl-yellow-hc))))

   `(hi-pink
     ((t (:foreground ,night-owl-red-lc
                      :background ,night-owl-red-hc))))

   `(hi-green
     ((t (:foreground ,night-owl-orange-lc
                      :background ,night-owl-orange-hc))))

   `(hi-blue
     ((t (:foreground ,night-owl-blue-lc
                      :background ,night-owl-blue-hc))))

   `(hi-black-b
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-background
                      :weight bold))))

   `(hi-blue-b
     ((t (:foreground ,night-owl-blue-lc
                      :weight bold))))

   `(hi-green-b
     ((t (:foreground ,night-owl-orange-lc
                      :weight bold))))

   `(hi-red-b
     ((t (:foreground ,night-owl-magenta
                      :weight bold))))

   `(hi-black-hb
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-background
                      :weight bold))))
   ;; }}}

   ;; highlight-changes {{{
   `(highlight-changes
     ((t (:foreground ,night-owl-green))))

   `(highlight-changes-delete
     ((t (:foreground ,night-owl-magenta
                      :underline t))))
   ;; }}}

   ;; highlight-indentation {{{
   `(highlight-indentation-face
     ((t (:background ,night-owl-gray))))

   `(highlight-indentation-current-column-face
     ((t (:background ,night-owl-gray))))
   ;; }}}

   ;; highlight-symbol {{{
   `(highlight-symbol-face
     ((t (:background ,night-owl-highlight))))
   ;; }}}

   ;; hl-line-mode {{{
   `(hl-line
     ((t (:background ,night-owl-highlight-line))))

   `(hl-line-face
     ((t (:background ,night-owl-highlight-line))))
   ;; }}}

   ;; ido-mode {{{
   `(ido-first-match
     ((t (:foreground ,night-owl-yellow
                      :weight normal))))

   `(ido-only-match
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-yellow
                      :weight normal))))

   `(ido-subdir
     ((t (:foreground ,night-owl-blue))))

   `(ido-incomplete-regexp
     ((t (:foreground ,night-owl-magenta
                      :weight bold ))))

   `(ido-indicator
     ((t (:background ,night-owl-magenta
                      :foreground ,night-owl-background
                      :width condensed))))

   `(ido-virtual
     ((t (:foreground ,night-owl-cyan))))
   ;; }}}

   ;; info {{{
   `(info-header-xref
     ((t (:foreground ,night-owl-orange
                      :inherit bold
                      :underline t))))

   `(info-menu
     ((t (:foreground ,night-owl-blue))))

   `(info-node
     ((t (:foreground ,night-owl-violet
                      :inherit bold))))

   `(info-quoted-name
     ((t (:foreground ,night-owl-green))))

   `(info-reference-item
     ((t (:background nil
                      :underline t
                      :inherit bold))))

   `(info-string
     ((t (:foreground ,night-owl-yellow))))

   `(info-title-1
     ((t (:height ,night-owl-height-plus-4))))

   `(info-title-2
     ((t (:height ,night-owl-height-plus-3))))

   `(info-title-3
     ((t (:height ,night-owl-height-plus-2))))

   `(info-title-4
     ((t (:height ,night-owl-height-plus-1))))
   ;; }}}

   ;; ivy {{{
   `(ivy-current-match
     ((t (:background ,night-owl-highlight-line :foreground ,night-owl-white))))

   `(ivy-not-current
     ((t (:foreground ,night-owl-foreground-slightly-muted))))

   `(ivy-minibuffer-match-highlight
     ((t (:inherit bold :foreground ,night-owl-white))))

   `(ivy-minibuffer-match-face-1
     ((t (:inherit bold :foreground ,night-owl-white))))

   `(ivy-minibuffer-match-face-2
     ((t (:foreground ,night-owl-violet
                      :underline t))))

   `(ivy-minibuffer-match-face-3
     ((t (:foreground ,night-owl-orange
                      :underline t))))

   `(ivy-minibuffer-match-face-4
     ((t (:foreground ,night-owl-yellow
                      :underline t))))

   `(ivy-remote
     ((t (:foreground ,night-owl-blue))))

   `(ivy-virtual
     ((t (:foreground ,night-owl-foreground-slightly-muted))))

   `(counsel-key-binding
     ((t (:foreground ,night-owl-input-fg))))

   `(swiper-line-face
     ((t (:background ,night-owl-highlight-line))))

   `(swiper-match-face-1
     ((t (:background ,night-owl-gray-d))))

   `(swiper-match-face-2
     ((t (:background ,night-owl-orange))))

   `(swiper-match-face-3
     ((t (:background ,night-owl-green))))

   `(swiper-match-face-4
     ((t (:background ,night-owl-red))))
   ;; }}}

   ;; jabber {{{
   `(jabber-activity-face
     ((t (:weight bold
                  :foreground ,night-owl-magenta))))

   `(jabber-activity-personal-face
     ((t (:weight bold
                  :foreground ,night-owl-blue))))

   `(jabber-chat-error
     ((t (:weight bold
                  :foreground ,night-owl-red))))

   `(jabber-chat-prompt-foreign
     ((t (:weight bold
                  :foreground ,night-owl-magenta))))

   `(jabber-chat-prompt-local
     ((t (:weight bold
                  :foreground ,night-owl-blue))))

   `(jabber-chat-prompt-system
     ((t (:weight bold
                  :foreground ,night-owl-orange))))

   `(jabber-chat-text-foreign
     ((t (:foreground ,night-owl-comments))))

   `(jabber-chat-text-local
     ((t (:foreground ,night-owl-foreground))))

   `(jabber-chat-rare-time-face
     ((t (:underline t
                     :foreground ,night-owl-orange))))

   `(jabber-roster-user-away
     ((t (:slant italic
                 :foreground ,night-owl-orange))))

   `(jabber-roster-user-chatty
     ((t (:weight bold
                  :foreground ,night-owl-green))))

   `(jabber-roster-user-dnd
     ((t (:slant italic
                 :foreground ,night-owl-magenta))))

   `(jabber-roster-user-error
     ((t (:weight light
                  :slant italic
                  :foreground ,night-owl-red))))

   `(jabber-roster-user-offline
     ((t (:foreground ,night-owl-comments))))

   `(jabber-roster-user-online
     ((t (:weight bold
                  :foreground ,night-owl-blue))))

   `(jabber-roster-user-xa
     ((t (:slant italic
                 :foreground ,night-owl-red))))
   ;; }}}

   ;; js2-mode colors {{{
   `(js2-error
     ((t (:foreground ,night-owl-red))))

   `(js2-external-variable
     ((t (:foreground ,night-owl-green))))

   `(js2-function-call
     ((t (:foreground ,night-owl-blue))))

   `(js2-function-param
     ((t (:foreground ,night-owl-green))))

   `(js2-instance-member
     ((t (:foreground ,night-owl-violet))))

   `(js2-jsdoc-html-tag-delimiter
     ((t (:foreground ,night-owl-orange))))

   `(js2-jsdoc-html-tag-name
     ((t (:foreground ,night-owl-orange))))

   `(js2-jsdoc-tag
     ((t (:foreground ,night-owl-violet))))

   `(js2-jsdoc-type
     ((t (:foreground ,night-owl-blue))))

   `(js2-jsdoc-value
     ((t (:foreground ,night-owl-green))))

   `(js2-magic-paren
     ((t (:underline t))))

   `(js2-object-property
     ((t (:foreground ,night-owl-magenta))))

   `(js2-object-property-access
     ((t (:foreground ,night-owl-cyan))))

   `(js2-private-function-call
     ((t (:foreground ,night-owl-violet))))

   `(js2-private-member
     ((t (:foreground ,night-owl-blue))))

   `(js2-warning
     ((t (:underline ,night-owl-green))))
   ;; }}}

   ;; jedi {{{
   `(jedi:highlight-function-argument
     ((t (:inherit bold))))
   ;; }}}

   ;; linum-mode {{{
   `(linum
     ((t (:foreground ,night-owl-line-number
                      :background ,night-owl-fringe-bg
                      :inherit default
                      :underline nil))))
   ;; }}}

   ;; line-number (>= Emacs26) {{{
   `(line-number
     ((t (:foreground ,night-owl-line-number
                      :background ,night-owl-fringe-bg
                      :inherit default
                      :underline nil))))
   `(line-number-current-line
     ((t (:foreground ,night-owl-foreground
                      :background ,night-owl-fringe-bg
                      :inherit default
                      :underline nil))))
   ;; }}}

   ;; linum-relative-current-face {{{
   `(linum-relative-current-face
     ((t (:foreground ,night-owl-line-number
                      :background ,night-owl-highlight-line
                      :underline nil))))
   ;; }}}

   ;; lusty-explorer {{{
   `(lusty-directory-face
     ((t (:inherit dinight-owl-magenta-directory))))

   `(lusty-file-face
     ((t nil)))

   `(lusty-match-face
     ((t (:inherit ido-first-match))))

   `(lusty-slash-face
     ((t (:foreground ,night-owl-cyan
                      :weight bold))))
   ;; }}}

   ;; magit {{{
   ;;
   ;; TODO: Add supports for all magit faces
   ;; https://github.com/magit/magit/search?utf8=%E2%9C%93&q=face
   ;;
   `(magit-diff-added
     ((t (:foreground ,night-owl-green
                      :background ,night-owl-background))))

   `(magit-diff-context-highlight
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-foreground-muted))))

   `(magit-diff-added-highlight
     ((t (:foreground ,night-owl-green
                      :background ,night-owl-highlight-line))))

   `(magit-diff-removed
     ((t (:foreground ,night-owl-red
                      :background ,night-owl-background))))

   `(magit-diff-removed-highlight
     ((t (:foreground ,night-owl-red
                      :background ,night-owl-highlight-line))))

   `(magit-section-highlight
     ((t (:background ,night-owl-highlight-line))))

   `(magit-section-title
     ((t (:foreground ,night-owl-yellow
                      :weight bold))))

   `(magit-branch
     ((t (:foreground ,night-owl-green
                      :weight bold))))

   `(magit-item-highlight
     ((t (:background ,night-owl-highlight-line
                      :weight unspecified))))

   `(magit-log-author
     ((t (:foreground ,night-owl-cyan))))

   `(magit-log-graph
     ((t (:foreground ,night-owl-comments))))

   `(magit-log-head-label-bisect-bad
     ((t (:background ,night-owl-magenta-hc
                      :foreground ,night-owl-magenta-lc
                      :box 1))))

   `(magit-log-head-label-bisect-good
     ((t (:background ,night-owl-orange-hc
                      :foreground ,night-owl-orange-lc
                      :box 1))))

   `(magit-log-head-label-default
     ((t (:background ,night-owl-highlight-line
                      :box 1))))

   `(magit-log-head-label-local
     ((t (:background ,night-owl-blue-lc
                      :foreground ,night-owl-blue-hc
                      :box 1))))

   `(magit-log-head-label-patches
     ((t (:background ,night-owl-magenta-lc
                      :foreground ,night-owl-magenta-hc
                      :box 1))))

   `(magit-log-head-label-remote
     ((t (:background ,night-owl-orange-lc
                      :foreground ,night-owl-orange-hc
                      :box 1))))

   `(magit-log-head-label-tags
     ((t (:background ,night-owl-yellow-lc
                      :foreground ,night-owl-yellow-hc
                      :box 1))))

   `(magit-log-sha1
     ((t (:foreground ,night-owl-yellow))))
   ;; }}}

   ;; man {{{
   `(Man-overstrike
     ((t (:foreground ,night-owl-blue
                      :weight bold))))

   `(Man-reverse
     ((t (:foreground ,night-owl-green))))

   `(Man-underline
     ((t (:foreground ,night-owl-orange :underline t))))
   ;; }}}

   ;; monky {{{
   `(monky-section-title
     ((t (:foreground ,night-owl-yellow
                      :weight bold))))

   `(monky-diff-add
     ((t (:foreground ,night-owl-orange))))

   `(monky-diff-del
     ((t (:foreground ,night-owl-magenta))))
   ;; }}}

   ;; markdown-mode {{{
   `(markdown-header-face
     ((t (:foreground ,night-owl-heading))))

   `(markdown-header-face-1
     ((t (:inherit markdown-header-face
                   :height ,night-owl-height-plus-4))))

   `(markdown-header-face-2
     ((t (:inherit markdown-header-face
                   :height ,night-owl-height-plus-3))))

   `(markdown-header-face-3
     ((t (:inherit markdown-header-face
                   :height ,night-owl-height-plus-2))))

   `(markdown-header-face-4
     ((t (:inherit markdown-header-face
                   :height ,night-owl-height-plus-1))))

   `(markdown-header-face-5
     ((t (:inherit markdown-header-face))))

   `(markdown-header-face-6
     ((t (:inherit markdown-header-face))))
   ;; }}}

   ;; message-mode {{{
   `(message-cited-text
     ((t (:foreground ,night-owl-comments))))

   `(message-header-name
     ((t (:foreground ,night-owl-comments))))

   `(message-header-other
     ((t (:foreground ,night-owl-foreground
                      :weight normal))))

   `(message-header-to
     ((t (:foreground ,night-owl-foreground
                      :weight normal))))

   `(message-header-cc
     ((t (:foreground ,night-owl-foreground
                      :weight normal))))

   `(message-header-newsgroups
     ((t (:foreground ,night-owl-yellow
                      :weight bold))))

   `(message-header-subject
     ((t (:foreground ,night-owl-cyan
                      :weight normal))))

   `(message-header-xheader
     ((t (:foreground ,night-owl-cyan))))

   `(message-mml
     ((t (:foreground ,night-owl-yellow
                      :weight bold))))

   `(message-separator
     ((t (:foreground ,night-owl-comments
                      :slant italic))))
   ;; }}}

   ;; mew {{{
   `(mew-face-header-subject
     ((t (:foreground ,night-owl-green))))

   `(mew-face-header-from
     ((t (:foreground ,night-owl-yellow))))

   `(mew-face-header-date
     ((t (:foreground ,night-owl-orange))))

   `(mew-face-header-to
     ((t (:foreground ,night-owl-magenta))))

   `(mew-face-header-key
     ((t (:foreground ,night-owl-orange))))

   `(mew-face-header-private
     ((t (:foreground ,night-owl-orange))))

   `(mew-face-header-important
     ((t (:foreground ,night-owl-blue))))

   `(mew-face-header-marginal
     ((t (:foreground ,night-owl-foreground
                      :weight bold))))

   `(mew-face-header-warning
     ((t (:foreground ,night-owl-magenta))))

   `(mew-face-header-xmew
     ((t (:foreground ,night-owl-orange))))

   `(mew-face-header-xmew-bad
     ((t (:foreground ,night-owl-magenta))))

   `(mew-face-body-url
     ((t (:foreground ,night-owl-green))))

   `(mew-face-body-comment
     ((t (:foreground ,night-owl-foreground
                      :slant italic))))

   `(mew-face-body-cite1
     ((t (:foreground ,night-owl-orange))))

   `(mew-face-body-cite2
     ((t (:foreground ,night-owl-blue))))

   `(mew-face-body-cite3
     ((t (:foreground ,night-owl-green))))

   `(mew-face-body-cite4
     ((t (:foreground ,night-owl-yellow))))

   `(mew-face-body-cite5
     ((t (:foreground ,night-owl-magenta))))

   `(mew-face-mark-review
     ((t (:foreground ,night-owl-blue))))

   `(mew-face-mark-escape
     ((t (:foreground ,night-owl-orange))))

   `(mew-face-mark-delete
     ((t (:foreground ,night-owl-magenta))))

   `(mew-face-mark-unlink
     ((t (:foreground ,night-owl-yellow))))

   `(mew-face-mark-refile
     ((t (:foreground ,night-owl-orange))))

   `(mew-face-mark-unread
     ((t (:foreground ,night-owl-magenta))))

   `(mew-face-eof-message
     ((t (:foreground ,night-owl-orange))))

   `(mew-face-eof-part
     ((t (:foreground ,night-owl-yellow))))
   ;; }}}

   ;; mingus {{{
   `(mingus-directory-face
     ((t (:foreground ,night-owl-blue))))

   `(mingus-pausing-face
     ((t (:foreground ,night-owl-red))))

   `(mingus-playing-face
     ((t (:foreground ,night-owl-cyan))))

   `(mingus-playlist-face
     ((t (:foreground ,night-owl-cyan ))))

   `(mingus-song-file-face
     ((t (:foreground ,night-owl-yellow))))

   `(mingus-stopped-face
     ((t (:foreground ,night-owl-magenta))))
   ;; }}}

   ;; mmm {{{
   `(mmm-init-submode-face
     ((t (:background ,night-owl-violet-d))))

   `(mmm-cleanup-submode-face
     ((t (:background ,night-owl-green-d))))

   `(mmm-declaration-submode-face
     ((t (:background ,night-owl-cyan-d))))

   `(mmm-comment-submode-face
     ((t (:background ,night-owl-blue-d))))

   `(mmm-output-submode-face
     ((t (:background ,night-owl-magenta-d))))

   `(mmm-special-submode-face
     ((t (:background ,night-owl-orange-d))))

   `(mmm-code-submode-face
     ((t (:background ,night-owl-gray))))

   `(mmm-default-submode-face
     ((t (:background ,night-owl-gray-d))))
   ;; }}}

   ;; moccur {{{
   `(moccur-current-line-face
     ((t (:underline t))))

   `(moccur-edit-done-face
     ((t (:foreground ,night-owl-comments
                      :background ,night-owl-background
                      :slant italic))))

   `(moccur-edit-face
     ((t (:background ,night-owl-yellow
                      :foreground ,night-owl-background))))

   `(moccur-edit-file-face
     ((t (:background ,night-owl-highlight-line))))

   `(moccur-edit-reject-face
     ((t (:foreground ,night-owl-magenta))))

   `(moccur-face
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-emphasis
                      :weight bold))))

   `(search-buffers-face
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-emphasis
                      :weight bold))))

   `(search-buffers-header-face
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-yellow
                      :weight bold))))
   ;; }}}

   ;; mu4e {{{
   `(mu4e-cited-1-face
     ((t (:foreground ,night-owl-orange
                      :slant italic
                      :weight normal))))

   `(mu4e-cited-2-face
     ((t (:foreground ,night-owl-blue
                      :slant italic
                      :weight normal))))

   `(mu4e-cited-3-face
     ((t (:foreground ,night-owl-green
                      :slant italic
                      :weight normal))))

   `(mu4e-cited-4-face
     ((t (:foreground ,night-owl-yellow
                      :slant italic
                      :weight normal))))

   `(mu4e-cited-5-face
     ((t (:foreground ,night-owl-cyan
                      :slant italic
                      :weight normal))))

   `(mu4e-cited-6-face
     ((t (:foreground ,night-owl-orange
                      :slant italic
                      :weight normal))))

   `(mu4e-cited-7-face
     ((t (:foreground ,night-owl-blue
                      :slant italic
                      :weight normal))))

   `(mu4e-flagged-face
     ((t (:foreground ,night-owl-red
                      :weight bold))))

   `(mu4e-view-url-number-face
     ((t (:foreground ,night-owl-yellow
                      :weight normal))))

   `(mu4e-warning-face
     ((t (:foreground ,night-owl-magenta
                      :slant normal
                      :weight bold))))

   `(mu4e-header-highlight-face
     ((t (:inherit unspecified
                   :foreground unspecified
                   :background ,night-owl-highlight-line
                   :underline ,night-owl-emphasis
                   :weight normal))))


   `(mu4e-draft-face
     ((t (:inherit font-lock-string-face))))

   `(mu4e-footer-face
     ((t (:inherit font-lock-comment-face))))

   `(mu4e-forwarded-face
     ((t (:inherit font-lock-builtin-face
                   :weight normal))))

   `(mu4e-header-face
     ((t (:inherit default))))

   `(mu4e-header-marks-face
     ((t (:inherit font-lock-preprocessor-face))))

   `(mu4e-header-title-face
     ((t (:inherit font-lock-type-face))))

   `(mu4e-highlight-face
     ((t (:inherit font-lock-pseudo-keyword-face
                   :weight bold))))

   `(mu4e-moved-face
     ((t (:inherit font-lock-comment-face
                   :slant italic))))

   `(mu4e-ok-face
     ((t (:inherit font-lock-comment-face
                   :slant normal
                   :weight bold))))

   `(mu4e-replied-face
     ((t (:inherit font-lock-builtin-face
                   :weight normal))))

   `(mu4e-system-face
     ((t (:inherit font-lock-comment-face
                   :slant italic))))

   `(mu4e-title-face
     ((t (:inherit font-lock-type-face
                   :weight bold))))

   `(mu4e-trashed-face
     ((t (:inherit font-lock-comment-face
                   :strike-through t))))

   `(mu4e-unread-face
     ((t (:inherit font-lock-keyword-face
                   :weight bold))))

   `(mu4e-view-attach-number-face
     ((t (:inherit font-lock-variable-name-face
                   :weight bold))))

   `(mu4e-view-contact-face
     ((t (:foreground ,night-owl-foreground
                      :weight normal))))

   `(mu4e-view-header-key-face
     ((t (:inherit message-header-name
                   :weight normal))))

   `(mu4e-view-header-value-face
     ((t (:foreground ,night-owl-cyan
                      :weight normal
                      :slant normal))))

   `(mu4e-view-link-face
     ((t (:inherit link))))

   `(mu4e-view-special-header-value-face
     ((t (:foreground ,night-owl-blue
                      :weight normal
                      :underline nil))))
   ;; }}}

   ;; mumamo {{{
   `(mumamo-background-chunk-submode1
     ((t (:background ,night-owl-highlight-line))))
   ;; }}}

   ;; nav {{{
   `(nav-face-heading
     ((t (:foreground ,night-owl-yellow))))

   `(nav-face-button-num
     ((t (:foreground ,night-owl-cyan))))

   `(nav-face-dir
     ((t (:foreground ,night-owl-orange))))

   `(nav-face-hdir
     ((t (:foreground ,night-owl-magenta))))

   `(nav-face-file
     ((t (:foreground ,night-owl-foreground))))

   `(nav-face-hfile
     ((t (:foreground ,night-owl-magenta))))
   ;; }}}

   ;; nav-flash {{{
   `(nav-flash-face
     ((t (:background ,night-owl-highlight-line))))
   ;; }}}

   ;; neo-tree {{{
   `(neo-banner-face
     ((t (:foreground ,night-owl-blue
                      :background ,night-owl-background
                      :weight bold))))


   `(neo-header-face
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-background))))

   `(neo-root-dir-face
     ((t (:foreground ,night-owl-orange
                      :background ,night-owl-background))))

   `(neo-dir-link-face
     ((t (:foreground ,night-owl-blue))))

   `(neo-file-link-face
     ((t (:foreground ,night-owl-foreground))))

   `(neo-button-face
     ((t (:underline nil))))

   `(neo-expand-btn-face
     ((t (:foreground ,night-owl-comments))))

   `(neo-vc-default-face
     ((t (:foreground ,night-owl-foreground))))

   `(neo-vc-user-face
     ((t (:foreground ,night-owl-magenta
                      :slant italic))))

   `(neo-vc-up-to-date-face
     ((t (:foreground ,night-owl-comments))))

   `(neo-vc-edited-face
     ((t (:foreground ,night-owl-green))))

   `(neo-vc-needs-update-face
     ((t (:underline t))))

   `(neo-vc-needs-merge-face
     ((t (:foreground ,night-owl-magenta))))

   `(neo-vc-unlocked-changes-face
     ((t (:foreground ,night-owl-magenta
                      :background ,night-owl-comments))))

   `(neo-vc-added-face
     ((t (:foreground ,night-owl-orange))))

   `(neo-vc-removed-face
     ((t (:strike-through t))))

   `(neo-vc-conflict-face
     ((t (:foreground ,night-owl-magenta))))

   `(neo-vc-missing-face
     ((t (:foreground ,night-owl-magenta))))

   `(neo-vc-ignored-face
     ((t (:foreground ,night-owl-comments))))
   ;; }}}

   ;; adoc-mode / markup {{{
   `(markup-meta-face
     ((t (:foreground ,night-owl-gray-l))))

   `(markup-table-face
     ((t (:foreground ,night-owl-blue-hc
                      :background ,night-owl-blue-lc))))

   `(markup-verbatim-face
     ((t (:background ,night-owl-green-lc))))

   `(markup-list-face
     ((t (:foreground ,night-owl-violet-hc
                      :background ,night-owl-violet-lc))))

   `(markup-replacement-face
     ((t (:foreground ,night-owl-violet))))

   `(markup-complex-replacement-face
     ((t (:foreground ,night-owl-violet-hc
                      :background ,night-owl-violet-lc))))

   `(markup-gen-face
     ((t (:foreground ,night-owl-blue))))

   `(markup-secondary-text-face
     ((t (:foreground ,night-owl-magenta))))
   ;; }}}

   ;; org-mode {{{
   `(org-agenda-structure
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-highlight-line
                      :weight bold
                      :slant normal
                      :inverse-video nil
                      :height ,night-owl-height-plus-1
                      :underline nil
                      :box (:line-width 2 :color ,night-owl-background)))))

   `(org-agenda-calendar-event
     ((t (:foreground ,night-owl-emphasis))))

   `(org-agenda-calendar-sexp
     ((t (:foreground ,night-owl-foreground
                      :slant italic))))

   `(org-agenda-date
     ((t (:foreground ,night-owl-comments
                      :background ,night-owl-background
                      :weight normal
                      :inverse-video nil
                      :overline nil
                      :slant normal
                      :height 1.0
                      :box (:line-width 2 :color ,night-owl-background)))) t)

   `(org-agenda-date-weekend
     ((t (:inherit org-agenda-date
                   :inverse-video nil
                   :background unspecified
                   :foreground ,night-owl-comments
                   :weight unspecified
                   :underline t
                   :overline nil
                   :box unspecified))) t)

   `(org-agenda-date-today
     ((t (:inherit org-agenda-date
                   :inverse-video t
                   :weight bold
                   :underline unspecified
                   :overline nil
                   :box unspecified
                   :foreground ,night-owl-blue
                   :background ,night-owl-background))) t)

   `(org-agenda-done
     ((t (:foreground ,night-owl-comments
                      :slant italic))) t)

   `(org-archived
     ((t (:foreground ,night-owl-comments
                      :weight normal))))

   `(org-block
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-highlight-alt))))

   `(org-block-background
     ((t (:background ,night-owl-highlight-alt))))

   `(org-block-begin-line
     ((t (:foreground ,night-owl-gray-l
                      :background ,night-owl-gray-d
                      :slant italic))))

   `(org-block-end-line
     ((t (:foreground ,night-owl-gray-l
                      :background ,night-owl-gray-d
                      :slant italic))))

   `(org-checkbox
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-foreground
                      :box (:line-width 1 :style released-button)))))

   `(org-code
     ((t (:foreground ,night-owl-comments))))

   `(org-date
     ((t (:foreground ,night-owl-blue
                      :underline t))))

   `(org-done
     ((t (:weight bold
                  :foreground ,night-owl-orange))))

   `(org-ellipsis
     ((t (:foreground ,night-owl-comments))))

   `(org-formula
     ((t (:foreground ,night-owl-yellow))))

   `(org-headline-done
     ((t (:foreground ,night-owl-orange))))

   `(org-hide
     ((t (:foreground ,night-owl-background))))

   `(org-level-1
     ((t (:inherit ,night-owl-pitch
                   :height ,night-owl-height-plus-4
                   :foreground ,night-owl-heading))))

   `(org-level-2
     ((t (:inherit ,night-owl-pitch
                   :height ,night-owl-height-plus-3
                   :foreground ,night-owl-heading))))

   `(org-level-3
     ((t (:inherit ,night-owl-pitch
                   :height ,night-owl-height-plus-2
                   :foreground ,night-owl-heading))))

   `(org-level-4
     ((t (:inherit ,night-owl-pitch
                   :height ,night-owl-height-plus-1
                   :foreground ,night-owl-heading))))

   `(org-level-5
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-heading))))

   `(org-level-6
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-heading))))

   `(org-level-7
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-heading))))

   `(org-level-8
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-heading))))

   `(org-link
     ((t (:foreground ,night-owl-blue
                      :underline t))))

   `(org-sexp-date
     ((t (:foreground ,night-owl-violet))))

   `(org-scheduled
     ((t (:foreground ,night-owl-orange))))

   `(org-scheduled-previously
     ((t (:foreground ,night-owl-cyan))))

   `(org-scheduled-today
     ((t (:foreground ,night-owl-blue
                      :weight normal))))

   `(org-special-keyword
     ((t (:foreground ,night-owl-comments
                      :weight bold))))

   `(org-table
     ((t (:foreground ,night-owl-foreground-slightly-muted))))

   `(org-tag
     ((t (:weight bold))))

   `(org-time-grid
     ((t (:foreground ,night-owl-comments))))

   `(org-todo
     ((t (:foreground ,night-owl-magenta
                      :weight bold))))

   `(org-upcoming-deadline
     ((t (:foreground ,night-owl-yellow
                      :weight normal
                      :underline nil))))

   `(org-warning
     ((t (:foreground ,night-owl-green
                      :weight normal
                      :underline nil))))

   ;; org-habit (clear=blue, ready=green, alert=yellow, overdue=red. future=lower contrast)
   `(org-habit-clear-face
     ((t (:background ,night-owl-blue-lc
                      :foreground ,night-owl-blue-hc))))

   `(org-habit-clear-future-face
     ((t (:background ,night-owl-blue-lc))))

   `(org-habit-ready-face
     ((t (:background ,night-owl-orange-lc
                      :foreground ,night-owl-orange))))

   `(org-habit-ready-future-face
     ((t (:background ,night-owl-orange-lc))))

   `(org-habit-alert-face
     ((t (:background ,night-owl-yellow
                      :foreground ,night-owl-yellow-lc))))

   `(org-habit-alert-future-face
     ((t (:background ,night-owl-yellow-lc))))

   `(org-habit-overdue-face
     ((t (:background ,night-owl-magenta
                      :foreground ,night-owl-magenta-lc))))

   `(org-habit-overdue-future-face
     ((t (:background ,night-owl-magenta-lc))))

   ;; latest additions
   `(org-agenda-dimmed-todo-face
     ((t (:foreground ,night-owl-comments))))

   `(org-agenda-restriction-lock
     ((t (:background ,night-owl-yellow))))

   `(org-clock-overlay
     ((t (:background ,night-owl-yellow))))

   `(org-column
     ((t (:background ,night-owl-highlight-line
                      :strike-through nil
                      :underline nil
                      :slant normal
                      :weight normal
                      :inherit default))))

   `(org-column-title
     ((t (:background ,night-owl-highlight-line
                      :underline t
                      :weight bold))))

   `(org-date-selected
     ((t (:foreground ,night-owl-magenta
                      :inverse-video t))))

   `(org-document-info
     ((t (:foreground ,night-owl-foreground))))

   `(org-document-title
     ((t (:foreground ,night-owl-emphasis
                      :weight bold
                      :height ,night-owl-height-plus-4))))

   `(org-drawer
     ((t (:foreground ,night-owl-cyan))))

   `(org-footnote
     ((t (:foreground ,night-owl-red
                      :underline t))))

   `(org-latex-and-export-specials
     ((t (:foreground ,night-owl-green))))

   `(org-mode-line-clock-overrun
     ((t (:inherit mode-line))))
   ;; }}}

   ;; outline {{{
   `(outline-1
     ((t (:inherit org-level-1))))

   `(outline-2
     ((t (:inherit org-level-2))))

   `(outline-3
     ((t (:inherit org-level-3))))

   `(outline-4
     ((t (:inherit org-level-4))))

   `(outline-5
     ((t (:inherit org-level-5))))

   `(outline-6
     ((t (:inherit org-level-6))))

   `(outline-7
     ((t (:inherit org-level-7))))

   `(outline-8
     ((t (:inherit org-level-8))))
   ;; }}}

   ;; parenface {{{
   `(paren-face)
   ;; }}}

   ;; perspective {{{
   `(persp-selected-face
     ((t (:foreground ,night-owl-blue
                      :weight bold))))
   ;; }}}

   ;; pretty-mode {{{
   `(pretty-mode-symbol-face
     ((t (:foreground ,night-owl-yellow
                      :weight normal))))
   ;; }}}

   ;; popup {{{
   `(popup-face
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-foreground))))

   `(popup-isearch-match
     ((t (:background ,night-owl-orange))))

   `(popup-menu-face
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-foreground))))

   `(popup-menu-mouse-face
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-foreground))))

   `(popup-menu-selection-face
     ((t (:background ,night-owl-red
                      :foreground ,night-owl-background))))

   `(popup-scroll-bar-background-face
     ((t (:background ,night-owl-comments))))

   `(popup-scroll-bar-foreground-face
     ((t (:background ,night-owl-emphasis))))

   `(popup-tip-face
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-foreground))))
   ;; }}}

   ;; rainbow-delimiters {{{
   `(rainbow-delimiters-depth-1-face
     ((t (:foreground ,night-owl-violet))))

   `(rainbow-delimiters-depth-2-face
     ((t (:foreground ,night-owl-blue))))

   `(rainbow-delimiters-depth-3-face
     ((t (:foreground ,night-owl-yellow))))

   `(rainbow-delimiters-depth-4-face
     ((t (:foreground ,night-owl-green))))

   `(rainbow-delimiters-depth-5-face
     ((t (:foreground ,night-owl-magenta))))

   `(rainbow-delimiters-depth-6-face
     ((t (:foreground ,night-owl-orange))))

   `(rainbow-delimiters-depth-7-face
     ((t (:foreground ,night-owl-violet))))

   `(rainbow-delimiters-depth-8-face
     ((t (:foreground ,night-owl-blue))))

   `(rainbow-delimiters-depth-9-face
     ((t (:foreground ,night-owl-yellow))))

   `(rainbow-delimiters-depth-10-face
     ((t (:foreground ,night-owl-green))))

   `(rainbow-delimiters-depth-11-face
     ((t (:foreground ,night-owl-magenta))))

   `(rainbow-delimiters-depth-12-face
     ((t (:foreground ,night-owl-orange))))

   `(rainbow-delimiters-unmatched-face
     ((t (:foreground ,night-owl-foreground
                      :background ,night-owl-background
                      :inverse-video t))))
   ;; }}}

   ;; realgud {{{
   `(realgud-overlay-arrow1
     ((t (:foreground ,night-owl-orange-d))))

   `(realgud-overlay-arrow2
     ((t (:foreground ,night-owl-yellow-d))))

   `(realgud-overlay-arrow3
     ((t (:foreground ,night-owl-green-d))))

   `(realgud-bp-enabled-face
     ((t (:inherit error))))

   `(realgud-bp-disabled-face
     ((t (:inherit secondary-selection))))

   `(realgud-bp-line-enabled-face
     ((t (:foreground ,night-owl-magenta-d))))

   `(realgud-bp-line-disabled-face
     ((t (:inherit secondary-selection))))

   `(realgud-line-number
     ((t (:inerhit night-owl-line-number))))

   `(realgud-backtrace-number
     ((t (:foreground ,night-owl-yellow-d
                      :weight bold))))
   ;; }}}

   ;; rhtm-mode {{{
   `(erb-face
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-background))))

   `(erb-delim-face
     ((t (:foreground ,night-owl-cyan
                      :background ,night-owl-background))))

   `(erb-exec-face
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-background))))

   `(erb-exec-delim-face
     ((t (:foreground ,night-owl-cyan
                      :background ,night-owl-background))))

   `(erb-out-face
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-background))))

   `(erb-out-delim-face
     ((t (:foreground ,night-owl-cyan
                      :background ,night-owl-background))))

   `(erb-comment-face
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-background))))

   `(erb-comment-delim-face
     ((t (:foreground ,night-owl-cyan
                      :background ,night-owl-background))))
   ;; }}}

   ;; rst-mode {{{
   `(rst-level-1-face
     ((t (:background ,night-owl-yellow
                      :foreground ,night-owl-background))))

   `(rst-level-2-face
     ((t (:background ,night-owl-cyan
                      :foreground ,night-owl-background))))

   `(rst-level-3-face
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-background))))

   `(rst-level-4-face
     ((t (:background ,night-owl-violet
                      :foreground ,night-owl-background))))

   `(rst-level-5-face
     ((t (:background ,night-owl-red
                      :foreground ,night-owl-background))))

   `(rst-level-6-face
     ((t (:background ,night-owl-magenta
                      :foreground ,night-owl-background))))
   ;; }}}

   ;; rpm-mode {{{
   `(rpm-spec-dir-face
     ((t (:foreground ,night-owl-orange))))

   `(rpm-spec-doc-face
     ((t (:foreground ,night-owl-orange))))

   `(rpm-spec-ghost-face
     ((t (:foreground ,night-owl-magenta))))

   `(rpm-spec-macro-face
     ((t (:foreground ,night-owl-yellow))))

   `(rpm-spec-obsolete-tag-face
     ((t (:foreground ,night-owl-magenta))))

   `(rpm-spec-package-face
     ((t (:foreground ,night-owl-magenta))))

   `(rpm-spec-section-face
     ((t (:foreground ,night-owl-yellow))))

   `(rpm-spec-tag-face
     ((t (:foreground ,night-owl-blue))))

   `(rpm-spec-var-face
     ((t (:foreground ,night-owl-magenta))))
   ;; }}}

   ;; sh-mode {{{
   `(sh-quoted-exec
     ((t (:foreground ,night-owl-violet
                      :weight bold))))

   `(sh-escaped-newline
     ((t (:foreground ,night-owl-yellow
                      :weight bold))))

   `(sh-heredoc
     ((t (:foreground ,night-owl-yellow
                      :weight bold))))
   ;; }}}

   ;; smartparens {{{
   `(sp-pair-overlay-face
     ((t (:background ,night-owl-highlight-line))))

   `(sp-wrap-overlay-face
     ((t (:background ,night-owl-highlight-line))))

   `(sp-wrap-tag-overlay-face
     ((t (:background ,night-owl-highlight-line))))

   `(sp-show-pair-enclosing
     ((t (:inherit highlight))))

   `(sp-show-pair-match-face
     ((t (:foreground ,night-owl-foreground
                      :background ,night-owl-match-bg
                      :weight normal))))

   `(sp-show-pair-mismatch-face
     ((t (:foreground ,night-owl-magenta
                      :background ,night-owl-background
                      :weight normal
                      :inverse-video t))))
   ;; }}}

   ;; show-paren {{{
   `(show-paren-match
     ((t (:foreground ,night-owl-foreground
                      :background ,night-owl-match-bg
                      :weight normal))))

   `(show-paren-mismatch
     ((t (:foreground ,night-owl-magenta
                      :background ,night-owl-background
                      :weight normal
                      :inverse-video t))))
   ;; }}}

   ;; mic-paren {{{
   `(paren-face-match
     ((t (:foreground ,night-owl-foreground
                      :background ,night-owl-match-bg
                      :weight normal))))

   `(paren-face-mismatch
     ((t (:foreground ,night-owl-magenta
                      :background ,night-owl-background
                      :weight normal
                      :inverse-video t))))

   `(paren-face-no-match
     ((t (:foreground ,night-owl-magenta
                      :background ,night-owl-background
                      :weight normal
                      :inverse-video t))))
   ;; }}}

   ;; SLIME {{{
   `(slime-repl-inputed-output-face
     ((t (:foreground ,night-owl-magenta))))
   ;; }}}

   ;; speedbar {{{
   `(speedbar-button-face
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-comments))))

   `(speedbar-directory-face
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-blue))))

   `(speedbar-file-face
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-foreground))))

   `(speedbar-highlight-face
     ((t (:inherit ,night-owl-pitch
                   :background ,night-owl-highlight-line))))

   `(speedbar-selected-face
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-yellow
                   :underline t))))

   `(speedbar-separator-face
     ((t (:inherit ,night-owl-pitch
                   :background ,night-owl-blue
                   :foreground ,night-owl-background
                   :overline ,night-owl-cyan-lc))))

   `(speedbar-tag-face
     ((t (:inherit ,night-owl-pitch
                   :foreground ,night-owl-orange))))
   ;; }}}

   ;; sunrise commander headings {{{
   `(sr-active-path-face
     ((t (:background ,night-owl-blue
                      :foreground ,night-owl-background
                      :height ,night-owl-height-plus-1
                      :weight bold))))

   `(sr-editing-path-face
     ((t (:background ,night-owl-yellow
                      :foreground ,night-owl-background
                      :weight bold
                      :height ,night-owl-height-plus-1))))

   `(sr-highlight-path-face
     ((t (:background ,night-owl-orange
                      :foreground ,night-owl-background
                      :weight bold
                      :height ,night-owl-height-plus-1))))

   `(sr-passive-path-face
     ((t (:background ,night-owl-comments
                      :foreground ,night-owl-background
                      :weight bold
                      :height ,night-owl-height-plus-1))))
   ;; }}}

   ;; sunrise commander marked {{{
   `(sr-marked-dir-face
     ((t (:inherit dinight-owl-magenta-marked))))

   `(sr-marked-file-face
     ((t (:inherit dinight-owl-magenta-marked))))

   `(sr-alt-marked-dir-face
     ((t (:background ,night-owl-red
                      :foreground ,night-owl-background
                      :weight bold))))

   `(sr-alt-marked-file-face
     ((t (:background ,night-owl-red
                      :foreground ,night-owl-background
                      :weight bold))))
   ;; }}}

   ;; sunrise commander fstat {{{
   `(sr-directory-face
     ((t (:inherit dinight-owl-magenta-directory
                   :weight normal))))

   `(sr-symlink-directory-face
     ((t (:inherit dinight-owl-magenta-directory
                   :slant italic
                   :weight normal))))

   `(sr-symlink-face
     ((t (:inherit dinight-owl-magenta-symlink
                   :slant italic
                   :weight normal))))

   `(sr-broken-link-face
     ((t (:inherit dinight-owl-magenta-warning
                   :slant italic
                   :weight normal))))
   ;; }}}

   ;; sunrise commander file types {{{
   `(sr-compressed-face
     ((t (:foreground ,night-owl-foreground))))

   `(sr-encrypted-face
     ((t (:foreground ,night-owl-foreground))))

   `(sr-log-face
     ((t (:foreground ,night-owl-foreground))))

   `(sr-packaged-face
     ((t (:foreground ,night-owl-foreground))))

   `(sr-html-face
     ((t (:foreground ,night-owl-foreground))))

   `(sr-xml-face
     ((t (:foreground ,night-owl-foreground))))
   ;; }}}

   ;; sunrise commander misc {{{
   `(sr-clex-hotchar-face
     ((t (:background ,night-owl-magenta
                      :foreground ,night-owl-background
                      :weight bold))))
   ;; }}}

   ;; syslog-mode {{{
   `(syslog-ip-face
     ((t (:background unspecified
                      :foreground ,night-owl-yellow))))

   `(syslog-hour-face
     ((t (:background unspecified
                      :foreground ,night-owl-orange))))

   `(syslog-error-face
     ((t (:background unspecified
                      :foreground ,night-owl-red
                      :weight bold))))

   `(syslog-warn-face
     ((t (:background unspecified
                      :foreground ,night-owl-green
                      :weight bold))))

   `(syslog-info-face
     ((t (:background unspecified
                      :foreground ,night-owl-blue
                      :weight bold))))

   `(syslog-debug-face
     ((t (:background unspecified
                      :foreground ,night-owl-cyan
                      :weight bold))))

   `(syslog-su-face
     ((t (:background unspecified
                      :foreground ,night-owl-red))))
   ;; }}}

   ;; table {{{
   `(table-cell
     ((t (:foreground ,night-owl-foreground
                      :background ,night-owl-highlight-line))))
   ;; }}}

   ;; term {{{
   `(term-color-black
     ((t (:foreground ,night-owl-background
                      :background ,night-owl-highlight-line))))

   `(term-color-red
     ((t (:foreground ,night-owl-magenta
                      :background ,night-owl-magenta-d))))

   `(term-color-green
     ((t (:foreground ,night-owl-orange
                      :background ,night-owl-orange-d))))

   `(term-color-yellow
     ((t (:foreground ,night-owl-yellow
                      :background ,night-owl-yellow-d))))

   `(term-color-blue
     ((t (:foreground ,night-owl-blue
                      :background ,night-owl-blue-d))))

   `(term-color-magenta
     ((t (:foreground ,night-owl-red
                      :background ,night-owl-red-d))))

   `(term-color-cyan
     ((t (:foreground ,night-owl-cyan
                      :background ,night-owl-cyan-d))))

   `(term-color-white
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-foreground))))

   `(term-default-fg-color
     ((t (:inherit term-color-white))))

   `(term-default-bg-color
     ((t (:inherit term-color-black))))
   ;; }}}

   ;; tooltip {{{
   ;; (NOTE: This setting has no effect on the os widgets for me zencoding uses this)
   `(tooltip
     ((t (:background ,night-owl-yellow-hc
                      :foreground ,night-owl-background
                      :inherit ,night-owl-pitch))))
   ;; }}}

   ;; treemacs {{{
   `(treemacs-directory-face
     ((t (:foreground ,night-owl-violet
                      :background ,night-owl-background
                      :weight bold))))

   `(treemacs-header-face
     ((t (:foreground ,night-owl-yellow
                      :background ,night-owl-background
                      :underline t
                      :weight bold))))

   `(treemacs-git-modified-face
     ((t (:foreground ,night-owl-orange
                      :background ,night-owl-background))))

   `(treemacs-git-renamed-face
     ((t (:foreground ,night-owl-magenta
                      :background ,night-owl-background))))

   `(treemacs-git-ignored-face
     ((t (:foreground ,night-owl-gray-l
                      :background ,night-owl-background))))

   `(treemacs-git-untracked-face
     ((t (:foreground ,night-owl-magenta
                      :background ,night-owl-background))))

   `(treemacs-git-added-face
     ((t (:foreground ,night-owl-orange
                      :background ,night-owl-background))))

   `(treemacs-git-conflict-face
     ((t (:foreground ,night-owl-green
                      :background ,night-owl-background))))
   ;; }}}

   ;; tuareg {{{
   `(tuareg-font-lock-governing-face
     ((t (:foreground ,night-owl-red
                      :weight bold))))

   `(tuareg-font-lock-multistage-face
     ((t (:foreground ,night-owl-blue
                      :background ,night-owl-highlight-line
                      :weight bold))))

   `(tuareg-font-lock-operator-face
     ((t (:foreground ,night-owl-emphasis))))

   `(tuareg-font-lock-error-face
     ((t (:foreground ,night-owl-yellow
                      :background ,night-owl-red
                      :weight bold))))

   `(tuareg-font-lock-interactive-output-face
     ((t (:foreground ,night-owl-cyan))))

   `(tuareg-font-lock-interactive-error-face
     ((t (:foreground ,night-owl-red))))
   ;; }}}

   ;; undo-tree {{{
   `(undo-tree-visualizer-default-face
     ((t (:foreground ,night-owl-comments
                      :background ,night-owl-background))))

   `(undo-tree-visualizer-unmodified-face
     ((t (:foreground ,night-owl-orange))))

   `(undo-tree-visualizer-current-face
     ((t (:foreground ,night-owl-blue
                      :inverse-video t))))

   `(undo-tree-visualizer-active-branch-face
     ((t (:foreground ,night-owl-emphasis
                      :background ,night-owl-background
                      :weight bold))))

   `(undo-tree-visualizer-register-face
     ((t (:foreground ,night-owl-yellow))))
   ;; }}}

   ;; volatile highlights {{{
   `(vhl/default-face
     ((t (:background ,night-owl-highlight-alt))))
   ;; }}}

   ;; w3m {{{
   `(w3m-anchor
     ((t (:inherit link))))

   `(w3m-arrived-anchor
     ((t (:inherit link-visited))))

   `(w3m-form
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-foreground))))

   `(w3m-header-line-location-title
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-yellow))))

   `(w3m-header-line-location-content

     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-foreground))))

   `(w3m-bold
     ((t (:foreground ,night-owl-emphasis
                      :weight bold))))

   `(w3m-image-anchor
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-cyan
                      :inherit link))))

   `(w3m-image
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-cyan))))

   `(w3m-lnum-minibuffer-prompt
     ((t (:foreground ,night-owl-emphasis))))

   `(w3m-lnum-match
     ((t (:background ,night-owl-highlight-line))))

   `(w3m-lnum
     ((t (:underline nil
                     :bold nil
                     :foreground ,night-owl-magenta))))

   `(w3m-session-select
     ((t (:foreground ,night-owl-foreground))))

   `(w3m-session-selected
     ((t (:foreground ,night-owl-emphasis
                      :bold t
                      :underline t))))

   `(w3m-tab-background
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-foreground))))

   `(w3m-tab-selected-background
     ((t (:background ,night-owl-background
                      :foreground ,night-owl-foreground))))

   `(w3m-tab-mouse
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-yellow))))

   `(w3m-tab-selected
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-emphasis
                      :bold t))))

   `(w3m-tab-unselected
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-foreground))))

   `(w3m-tab-selected-retrieving
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-magenta))))

   `(w3m-tab-unselected-retrieving
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-green))))

   `(w3m-tab-unselected-unseen
     ((t (:background ,night-owl-highlight-line
                      :foreground ,night-owl-violet))))
   ;; }}}

   ;; web-mode {{{
   `(web-mode-builtin-face
     ((t (:foreground ,night-owl-magenta))))

   `(web-mode-comment-face
     ((t (:foreground ,night-owl-comments))))

   `(web-mode-constant-face
     ((t (:foreground ,night-owl-red))))

   `(web-mode-current-element-highlight-face
     ((t (:underline unspecified
                     :weight unspecified
                     :background ,night-owl-highlight-line))))

   `(web-mode-doctype-face
     ((t (:foreground ,night-owl-comments
                      :slant italic
                      :weight bold))))

   `(web-mode-folded-face
     ((t (:underline t))))

   `(web-mode-function-name-face
     ((t (:foreground ,night-owl-blue))))

   `(web-mode-html-attr-name-face
     ((t (:foreground ,night-owl-green))))

   `(web-mode-html-attr-custom-face
     ((t (:inherit web-mode-html-attr-name-face))))

   `(web-mode-html-attr-engine-face
     ((t (:inherit web-mode-block-delimiter-face))))

   `(web-mode-html-attr-equal-face
     ((t (:inherit web-mode-html-attr-name-face))))

   `(web-mode-html-attr-value-face
     ((t (:foreground ,night-owl-yellow))))

   `(web-mode-html-tag-bracket-face
     ((t (:foreground ,night-owl-cyan))))

   `(web-mode-html-tag-face
     ((t (:foreground ,night-owl-cyan))))

   `(web-mode-keyword-face
     ((t (:foreground ,night-owl-magenta))))

   `(web-mode-preprocessor-face
     ((t (:foreground ,night-owl-yellow
                      :slant normal
                      :weight unspecified))))

   `(web-mode-string-face
     ((t (:foreground ,night-owl-string))))

   `(web-mode-type-face
     ((t (:inherit font-lock-type-face))))

   `(web-mode-variable-name-face
     ((t (:foreground ,night-owl-foreground))))

   `(web-mode-warning-face
     ((t (:inherit font-lock-warning-face))))

   `(web-mode-block-face
     ((t (:background unspecified))))

   `(web-mode-block-delimiter-face
     ((t (:inherit font-lock-preprocessor-face))))

   `(web-mode-block-comment-face
     ((t (:inherit web-mode-comment-face))))

   `(web-mode-block-control-face
     ((t (:inherit font-lock-preprocessor-face))))

   `(web-mode-block-string-face
     ((t (:inherit web-mode-string-face))))

   `(web-mode-comment-keyword-face
     ((t (:box 1 :weight bold))))

   `(web-mode-css-at-rule-face
     ((t (:inherit font-lock-constant-face))))

   `(web-mode-css-pseudo-class-face
     ((t (:inherit font-lock-builtin-face))))

   `(web-mode-css-color-face
     ((t (:inherit font-lock-builtin-face))))

   `(web-mode-css-filter-face
     ((t (:inherit font-lock-function-name-face))))

   `(web-mode-css-function-face
     ((t (:inherit font-lock-builtin-face))))

   `(web-mode-css-function-call-face
     ((t (:inherit font-lock-function-name-face))))

   `(web-mode-css-priority-face
     ((t (:inherit font-lock-builtin-face))))

   `(web-mode-css-property-name-face
     ((t (:inherit font-lock-variable-name-face))))

   `(web-mode-css-selector-face
     ((t (:inherit font-lock-keyword-face))))

   `(web-mode-css-string-face
     ((t (:inherit web-mode-string-face))))

   `(web-mode-javascript-string-face
     ((t (:inherit web-mode-string-face))))

   `(web-mode-json-comment-face
     ((t (:inherit web-mode-comment-face))))

   `(web-mode-json-context-face
     ((t (:foreground ,night-owl-violet))))

   `(web-mode-json-key-face
     ((t (:foreground ,night-owl-violet))))

   `(web-mode-json-string-face
     ((t (:inherit web-mode-string-face))))

   `(web-mode-param-name-face
     ((t (:foreground ,night-owl-foreground))))

   `(web-mode-part-comment-face
     ((t (:inherit web-mode-comment-face))))

   `(web-mode-part-face
     ((t (:inherit web-mode-block-face))))

   `(web-mode-part-string-face
     ((t (:inherit web-mode-string-face))))

   `(web-mode-symbol-face
     ((t (:foreground ,night-owl-violet))))

   `(web-mode-whitespace-face
     ((t (:background ,night-owl-magenta))))
   ;; }}}

   ;; whitespace-mode {{{
   `(whitespace-space
     ((t (:background unspecified
                      :foreground ,night-owl-comments
                      :inverse-video unspecified
                      :slant italic))))

   `(whitespace-hspace
     ((t (:background unspecified
                      :foreground ,night-owl-emphasis
                      :inverse-video unspecified))))

   `(whitespace-tab
     ((t (:background unspecified
                      :foreground ,night-owl-magenta
                      :inverse-video unspecified
                      :weight bold))))

   `(whitespace-newline
     ((t(:background unspecified
                     :foreground ,night-owl-comments
                     :inverse-video unspecified))))

   `(whitespace-trailing
     ((t (:background unspecified
                      :foreground ,night-owl-green-lc
                      :inverse-video t))))

   `(whitespace-line
     ((t (:background unspecified
                      :foreground ,night-owl-red
                      :inverse-video unspecified))))

   `(whitespace-space-before-tab
     ((t (:background ,night-owl-magenta-lc
                      :foreground unspecified
                      :inverse-video unspecified))))

   `(whitespace-indentation
     ((t (:background unspecified
                      :foreground ,night-owl-yellow
                      :inverse-video unspecified
                      :weight bold))))

   `(whitespace-empty
     ((t (:background unspecified
                      :foreground ,night-owl-magenta-lc
                      :inverse-video t))))

   `(whitespace-space-after-tab
     ((t (:background unspecified
                      :foreground ,night-owl-green
                      :inverse-video t
                      :weight bold))))
   ;; }}}

   ;; wanderlust {{{
   `(wl-highlight-folder-few-face
     ((t (:foreground ,night-owl-magenta))))

   `(wl-highlight-folder-many-face
     ((t (:foreground ,night-owl-magenta))))

   `(wl-highlight-folder-path-face
     ((t (:foreground ,night-owl-green))))

   `(wl-highlight-folder-unread-face
     ((t (:foreground ,night-owl-blue))))

   `(wl-highlight-folder-zero-face
     ((t (:foreground ,night-owl-foreground))))

   `(wl-highlight-folder-unknown-face
     ((t (:foreground ,night-owl-blue))))

   `(wl-highlight-message-citation-header
     ((t (:foreground ,night-owl-magenta))))

   `(wl-highlight-message-cited-text-1
     ((t (:foreground ,night-owl-magenta))))

   `(wl-highlight-message-cited-text-2
     ((t (:foreground ,night-owl-orange))))

   `(wl-highlight-message-cited-text-3
     ((t (:foreground ,night-owl-blue))))

   `(wl-highlight-message-cited-text-4
     ((t (:foreground ,night-owl-blue))))

   `(wl-highlight-message-header-contents-face
     ((t (:foreground ,night-owl-orange))))

   `(wl-highlight-message-headers-face
     ((t (:foreground ,night-owl-magenta))))

   `(wl-highlight-message-important-header-contents
     ((t (:foreground ,night-owl-orange))))

   `(wl-highlight-message-header-contents
     ((t (:foreground ,night-owl-orange))))

   `(wl-highlight-message-important-header-contents2
     ((t (:foreground ,night-owl-orange))))

   `(wl-highlight-message-signature
     ((t (:foreground ,night-owl-orange))))

   `(wl-highlight-message-unimportant-header-contents
     ((t (:foreground ,night-owl-foreground))))

   `(wl-highlight-summary-answenight-owl-magenta-face
     ((t (:foreground ,night-owl-blue))))

   `(wl-highlight-summary-disposed-face
     ((t (:foreground ,night-owl-foreground
                      :slant italic))))

   `(wl-highlight-summary-new-face
     ((t (:foreground ,night-owl-blue))))

   `(wl-highlight-summary-normal-face
     ((t (:foreground ,night-owl-foreground))))

   `(wl-highlight-summary-thread-top-face
     ((t (:foreground ,night-owl-yellow))))

   `(wl-highlight-thread-indent-face
     ((t (:foreground ,night-owl-red))))

   `(wl-highlight-summary-refiled-face
     ((t (:foreground ,night-owl-foreground))))

   `(wl-highlight-summary-displaying-face
     ((t (:underline t
                     :weight bold))))
   ;; }}}

   ;; weechat {{{
   `(weechat-error-face
     ((t (:inherit error))))

   `(weechat-highlight-face
     ((t (:foreground ,night-owl-emphasis
                      :weight bold))))

   `(weechat-nick-self-face
     ((t (:foreground ,night-owl-orange
                      :weight unspecified
                      :inverse-video t))))

   `(weechat-prompt-face
     ((t (:inherit minibuffer-prompt))))

   `(weechat-time-face
     ((t (:foreground ,night-owl-comments))))
   ;; }}}

   ;; which-func-mode {{{
   `(which-func
     ((t (:foreground ,night-owl-orange))))
   ;; }}}

   ;; which-key {{{
   `(which-key-key-face
     ((t (:foreground ,night-owl-orange
                      :weight bold))))

   `(which-key-separator-face
     ((t (:foreground ,night-owl-comments))))

   `(which-key-note-face
     ((t (:foreground ,night-owl-comments))))

   `(which-key-command-description-face
     ((t (:foreground ,night-owl-foreground))))

   `(which-key-local-map-description-face
     ((t (:foreground ,night-owl-yellow-hc))))

   `(which-key-group-description-face
     ((t (:foreground ,night-owl-magenta
                      :weight bold))))
   ;; }}}

   ;; window-number-mode {{{
   `(window-number-face
     ((t (:foreground ,night-owl-orange))))
   ;; }}}

   ;; yascroll {{{
   `(yascroll:thumb-text-area
     ((t (:foreground ,night-owl-comments
                      :background ,night-owl-comments))))

   `(yascroll:thumb-fringe
     ((t (:foreground ,night-owl-comments
                      :background ,night-owl-comments))))
   ;; }}}

   ;; zencoding {{{
   `(zencoding-preview-input
     ((t (:background ,night-owl-highlight-line
                      :box ,night-owl-emphasis)))))
  ;; }}}

  ;; custom-theme-set-variables {{{
  (custom-theme-set-variables
   'night-owl
   `(ansi-color-names-vector [,night-owl-background ,night-owl-red ,night-owl-green ,night-owl-yellow
                                                    ,night-owl-blue ,night-owl-magenta ,night-owl-cyan ,night-owl-foreground])

   ;; compilation
   `(compilation-message-face 'default)

   ;; fill-column-indicator
   `(fci-rule-color ,night-owl-highlight-line)

   ;; magit
   `(magit-diff-use-overlays nil)

   ;; highlight-changes
   `(highlight-changes-colors '(,night-owl-red ,night-owl-violet))

   ;; highlight-tail
   `(highlight-tail-colors
     '((,night-owl-highlight-line . 0)
       (,night-owl-orange-lc . 20)
       (,night-owl-cyan-lc . 30)
       (,night-owl-blue-lc . 50)
       (,night-owl-yellow-lc . 60)
       (,night-owl-orange-lc . 70)
       (,night-owl-magenta-lc . 85)
       (,night-owl-highlight-line . 100)))

   ;; pos-tip
   `(pos-tip-foreground-color ,night-owl-background)
   `(pos-tip-background-color ,night-owl-yellow-hc)

   ;; vc
   `(vc-annotate-color-map
     '((20 . ,night-owl-magenta)
       (40 . "#CF4F1F")
       (60 . "#C26C0F")
       (80 . ,night-owl-yellow)
       (100 . "#AB8C00")
       (120 . "#A18F00")
       (140 . "#989200")
       (160 . "#8E9500")
       (180 . ,night-owl-orange)
       (200 . "#729A1E")
       (220 . "#609C3C")
       (240 . "#4E9D5B")
       (260 . "#3C9F79")
       (280 . ,night-owl-cyan)
       (300 . "#299BA6")
       (320 . "#2896B5")
       (340 . "#2790C3")
       (360 . ,night-owl-blue)))
   `(vc-annotate-very-old-color nil)
   `(vc-annotate-background nil)

   ;; weechat
   `(weechat-color-list
     '(unspecified ,night-owl-background ,night-owl-highlight-line
                   ,night-owl-red-d ,night-owl-red
                   ,night-owl-orange-d ,night-owl-orange
                   ,night-owl-yellow-d ,night-owl-yellow
                   ,night-owl-blue-d ,night-owl-blue
                   ,night-owl-magenta-d ,night-owl-magenta
                   ,night-owl-cyan-d ,night-owl-cyan
                   ,night-owl-foreground ,night-owl-emphasis))))
;; }}}

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'night-owl)
;; Local Variables:
;; no-byte-compile: t
;; fill-column: 95
;; origami-fold-style: triple-braces
;; End:

;;; night-owl-theme.el ends here
