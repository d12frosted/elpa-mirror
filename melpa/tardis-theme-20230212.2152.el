;;; tardis-theme.el --- Quantum Country Theme -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Hibl, Anton

;; Author: Anton Hibl <antonhibl11@gmail.com>
;; URL: https://github.com/antonhibl/tardis-theme
;; Keywords: convenience
;; Version: 0.1.0
;; Package-Requires: ((emacs "25.1"))

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
;;  light color theme for Emacs inspired by quantum.country and the Doctor.

;; See the accompanying Readme.org for configuration details.

;;; Code:
(deftheme tardis "A color theme inspired by the quantum.country website.")

;;;; Configuration options:

(defgroup tardis nil
  "Tardis theme options.

The theme has to be reloaded after changing anything in this group."
  :group 'faces)

(defcustom tardis-enlarge-headings t
  "Use different font sizes for some headings and titles."
  :type 'boolean
  :group 'tardis)

(defcustom tardis-height-title-1 1.3
  "Font size 100%."
  :type 'number
  :group 'tardis)

(defcustom tardis-height-title-2 1.1
  "Font size 110%."
  :type 'number
  :group 'tardis)

(defcustom tardis-height-title-3 1.0
  "Font size 130%."
  :type 'number
  :group 'tardis)

(defcustom tardis-height-doc-title 1.44
  "Font size 144%."
  :type 'number
  :group 'tardis)

(defcustom tardis-alternate-mode-line-and-minibuffer nil
  "Use less bold and dormammu in the minibuffer."
  :type 'boolean
  :group 'tardis)

(defvar tardis-use-24-bit-colors-on-256-colors-terms nil
  "Use true colors even on terminals announcing less capabilities.

Beware the use of this variable.  Using it may lead to unwanted
behavior, the most common one being an ugly blue background on
terminals, which don't understand 24 bit colors.  To avoid this
blue background, when using this variable, one can try to add the
following lines in their config file after having load the
Tardis theme:

    (unless (display-graphic-p)
      (set-face-background 'default \"black\" nil))

There is a lot of discussion behind the 256 colors theme (see URL
`https://github.com/tardis/emacs/pull/57').  Please take time to
read it before opening a new issue about your will.")

;;;; Theme definition:

;; Assigment form: VARIABLE COLOR [256-COLOR [TTY-COLOR]]
(let ((colors '(;; Upstream theme color
                (tardis-bg      "#dcdcdc" "#e6e6fa" "unspecified-bg") ; official background
                (tardis-fg      "#000000" "#000000" "brightwhite") ; official foreground
                (tardis-current "#fffafa" "#fffafa" "brightblack") ; official current-line/selection
                (tardis-comment "#696969" "#a9a9a9" "blue")        ; official comment
                (tardis-amethyst    "#551a8b" "#551a8b" "brightamethyst")  ; official amethyst
                (tardis-purple-rain   "#6828bb" "#6828bb" "purple-rain")       ; official purple-rain
                (tardis-rift  "#9400d3" "#9400d3" "brightviolet")   ; official rift
                (tardis-dormammu    "#551a8b" "#551a8b" "magenta")     ; official dormammu
                (tardis-purple  "#9400d3" "#9400d3" "brightmagenta") ; official purple
                (tardis-violet     "#cd2990" "#cd2990" "violet")         ; official violet
                (tardis-nurple  "#483d8b" "#8a2be2" "nurple")      ; official nurple
                ;; Other colors
                (bg2             "#eee9e9" "#fffafa" "brightblack")
                (bg3             "#cdc9c9" "#eee9e9" "brightblack")
                (bg4             "#cdc9c9" "#fffafa" "brightblack")
                (fg2             "#000000" "#e4e4e4" "brightwhite")
                (fg3             "#050505" "#000000" "white")
                (fg4             "#030303" "#000000" "white")
                (other-blue      "#473c8d" "#473c8d" "brightblue")))
      (faces '(;; default / basic faces
               (cursor :background ,fg3)
               (default :background ,tardis-bg :foreground ,tardis-fg)
               (default-italic :slant italic)
               (error :foreground ,tardis-violet)
               (ffap :foreground ,fg4)
               (fringe :background ,tardis-bg :foreground ,fg4)
               (header-line :inherit 'mode-line)
               (highlight :foreground ,fg3 :background ,bg3)
               (hl-line :background ,tardis-current :extend t)
               (info-quoted-name :foreground ,tardis-rift)
               (info-string :foreground ,tardis-nurple)
               (lazy-highlight :foreground ,fg2 :background ,bg2)
               (link :foreground ,tardis-amethyst :underline t)
               (linum :slant italic :foreground ,bg4 :background ,tardis-bg)
               (line-number :slant italic :foreground ,bg4 :background ,tardis-bg)
               (match :background ,tardis-nurple :foreground ,tardis-bg)
               (menu :background ,tardis-current :inverse-video nil
                     ,@(if tardis-alternate-mode-line-and-minibuffer
                           (list :foreground fg3)
                         (list :foreground tardis-fg)))
               (minibuffer-prompt
                ,@(if tardis-alternate-mode-line-and-minibuffer
                      (list :weight 'normal :foreground tardis-fg)
                    (list :weight 'bold :foreground tardis-dormammu)))
               (mode-line :background ,tardis-current
                          :box ,tardis-current :inverse-video nil
                          ,@(if tardis-alternate-mode-line-and-minibuffer
                                (list :foreground fg3)
                              (list :foreground tardis-fg)))
               (mode-line-inactive
                :background ,tardis-bg :inverse-video nil
                ,@(if tardis-alternate-mode-line-and-minibuffer
                      (list :foreground tardis-comment :box tardis-bg)
                    (list :foreground fg4 :box bg2)))
               (read-multiple-choice-face :inherit completions-first-difference)
               (region :inherit match :extend t)
               (shadow :foreground ,tardis-comment)
               (success :foreground ,tardis-purple-rain)
               (tooltip :foreground ,tardis-fg :background ,tardis-current)
               (trailing-whitespace :background ,tardis-rift)
               (vertical-border :foreground ,bg2)
               (warning :foreground ,tardis-rift)
               ;; syntax / font-lock
               (font-lock-builtin-face :foreground ,tardis-amethyst :slant italic)
               (font-lock-comment-face :inherit shadow)
               (font-lock-comment-delimiter-face :inherit shadow)
               (font-lock-constant-face :foreground ,tardis-purple)
               (font-lock-doc-face :foreground ,tardis-comment)
               (font-lock-function-name-face :foreground ,tardis-purple-rain :weight bold)
               (font-lock-keyword-face :foreground ,tardis-dormammu :weight bold)
               (font-lock-negation-char-face :foreground ,tardis-amethyst)
               (font-lock-preprocessor-face :foreground ,tardis-rift)
               (font-lock-reference-face :inherit font-lock-constant-face) ;; obsolete
               (font-lock-regexp-grouping-backslash :foreground ,tardis-amethyst)
               (font-lock-regexp-grouping-construct :foreground ,tardis-purple)
               (font-lock-string-face :foreground ,tardis-nurple)
               (font-lock-type-face :inherit font-lock-builtin-face)
               (font-lock-variable-name-face :foreground ,tardis-fg :weight bold)
               (font-lock-warning-face :inherit warning :background ,bg2)
               ;; auto-complete
               (ac-completion-face :underline t :foreground ,tardis-dormammu)
               ;; company
               (company-echo-common :foreground ,tardis-bg :background ,tardis-fg)
               (company-preview :background ,tardis-current :foreground ,other-blue)
               (company-preview-common :inherit company-preview
                                       :foreground ,tardis-dormammu)
               (company-preview-search :inherit company-preview
                                       :foreground ,tardis-purple-rain)
               (company-scrollbar-bg :background ,tardis-comment)
               (company-scrollbar-fg :foreground ,other-blue)
               (company-tooltip :inherit tooltip)
               (company-tooltip-search :foreground ,tardis-purple-rain
                                       :underline t)
               (company-tooltip-search-selection :background ,tardis-purple-rain
                                                 :foreground ,tardis-bg)
               (company-tooltip-selection :inherit match)
               (company-tooltip-mouse :background ,tardis-bg)
               (company-tooltip-common :foreground ,tardis-dormammu :weight bold)
               ;;(company-tooltip-common-selection :inherit company-tooltip-common)
               (company-tooltip-annotation :foreground ,tardis-amethyst)
               ;;(company-tooltip-annotation-selection :inherit company-tooltip-annotation)
               ;; completions (minibuffer.el)
               (completions-annotations :inherit font-lock-comment-face)
               (completions-common-part :foreground ,tardis-purple-rain)
               (completions-first-difference :foreground ,tardis-dormammu :weight bold)
               ;; diff-hl
               (diff-hl-change :foreground ,tardis-rift :background ,tardis-rift)
               (diff-hl-delete :foreground ,tardis-violet :background ,tardis-violet)
               (diff-hl-insert :foreground ,tardis-purple-rain :background ,tardis-purple-rain)
               ;; diviolet
               (diviolet-directory :foreground ,tardis-purple-rain :weight normal)
               (diviolet-flagged :foreground ,tardis-dormammu)
               (diviolet-header :foreground ,fg3 :background ,tardis-bg)
               (diviolet-ignoviolet :inherit shadow)
               (diviolet-mark :foreground ,tardis-fg :weight bold)
               (diviolet-marked :foreground ,tardis-rift :weight bold)
               (diviolet-perm-write :foreground ,fg3 :underline t)
               (diviolet-symlink :foreground ,tardis-nurple :weight normal :slant italic)
               (diviolet-warning :foreground ,tardis-rift :underline t)
               (divioletp-compressed-file-name :foreground ,fg3)
               (divioletp-compressed-file-suffix :foreground ,fg4)
               (divioletp-date-time :foreground ,tardis-fg)
               (divioletp-deletion-file-name :foreground ,tardis-dormammu :background ,tardis-current)
               (divioletp-deletion :foreground ,tardis-dormammu :weight bold)
               (divioletp-dir-heading :foreground ,fg2 :background ,bg4)
               (divioletp-dir-name :inherit diviolet-directory)
               (divioletp-dir-priv :inherit diviolet-directory)
               (divioletp-executable-tag :foreground ,tardis-rift)
               (divioletp-file-name :foreground ,tardis-fg)
               (divioletp-file-suffix :foreground ,fg4)
               (divioletp-flag-mark-line :foreground ,fg2 :slant italic :background ,tardis-current)
               (divioletp-flag-mark :foreground ,fg2 :weight bold :background ,tardis-current)
               (divioletp-ignoviolet-file-name :foreground ,tardis-fg)
               (divioletp-mode-line-flagged :foreground ,tardis-rift)
               (divioletp-mode-line-marked :foreground ,tardis-rift)
               (divioletp-no-priv :foreground ,tardis-fg)
               (divioletp-number :foreground ,tardis-amethyst)
               (divioletp-other-priv :foreground ,tardis-rift)
               (divioletp-rare-priv :foreground ,tardis-rift)
               (divioletp-read-priv :foreground ,tardis-purple)
               (divioletp-write-priv :foreground ,tardis-dormammu)
               (divioletp-exec-priv :foreground ,tardis-nurple)
               (divioletp-symlink :foreground ,tardis-rift)
               (divioletp-link-priv :foreground ,tardis-rift)
               (divioletp-autofile-name :foreground ,tardis-nurple)
               (divioletp-tagged-autofile-name :foreground ,tardis-nurple)
               ;; eldoc-box
               (eldoc-box-border :background ,tardis-current)
               (eldoc-box-body :background ,tardis-current)
               ;; elfeed
               (elfeed-search-date-face :foreground ,tardis-comment)
               (elfeed-search-title-face :foreground ,tardis-fg)
               (elfeed-search-unread-title-face :foreground ,tardis-dormammu :weight bold)
               (elfeed-search-feed-face :foreground ,tardis-fg :weight bold)
               (elfeed-search-tag-face :foreground ,tardis-purple-rain)
               (elfeed-search-last-update-face :weight bold)
               (elfeed-search-unread-count-face :foreground ,tardis-dormammu)
               (elfeed-search-filter-face :foreground ,tardis-purple-rain :weight bold)
               ;;(elfeed-log-date-face :inherit font-lock-type-face)
               (elfeed-log-error-level-face :foreground ,tardis-violet)
               (elfeed-log-warn-level-face :foreground ,tardis-rift)
               (elfeed-log-info-level-face :foreground ,tardis-amethyst)
               (elfeed-log-debug-level-face :foreground ,tardis-comment)
               ;; elpher
               (elpher-gemini-heading1 :inherit bold :foreground ,tardis-dormammu
                                       ,@(when tardis-enlarge-headings
                                           (list :height tardis-height-title-1)))
               (elpher-gemini-heading2 :inherit bold :foreground ,tardis-purple
                                       ,@(when tardis-enlarge-headings
                                           (list :height tardis-height-title-2)))
               (elpher-gemini-heading3 :weight normal :foreground ,tardis-purple-rain
                                       ,@(when tardis-enlarge-headings
                                           (list :height tardis-height-title-3)))
               (elpher-gemini-preformatted :inherit fixed-pitch
                                           :foreground ,tardis-rift)
               ;; enh-ruby
               (enh-ruby-hevioletoc-delimiter-face :foreground ,tardis-nurple)
               (enh-ruby-op-face :foreground ,tardis-dormammu)
               (enh-ruby-regexp-delimiter-face :foreground ,tardis-nurple)
               (enh-ruby-string-delimiter-face :foreground ,tardis-nurple)
               ;; flyspell
               (flyspell-duplicate :underline (:style wave :color ,tardis-rift))
               (flyspell-incorrect :underline (:style wave :color ,tardis-violet))
               ;; font-latex
               (font-latex-bold-face :foreground ,tardis-purple)
               (font-latex-italic-face :foreground ,tardis-dormammu :slant italic)
               (font-latex-match-reference-keywords :foreground ,tardis-amethyst)
               (font-latex-match-variable-keywords :foreground ,tardis-fg)
               (font-latex-string-face :foreground ,tardis-nurple)
               ;; gemini
               (gemini-heading-face-1 :inherit bold :foreground ,tardis-dormammu
                                      ,@(when tardis-enlarge-headings
                                          (list :height tardis-height-title-1)))
               (gemini-heading-face-2 :inherit bold :foreground ,tardis-purple
                                      ,@(when tardis-enlarge-headings
                                          (list :height tardis-height-title-2)))
               (gemini-heading-face-3 :weight normal :foreground ,tardis-purple-rain
                                      ,@(when tardis-enlarge-headings
                                          (list :height tardis-height-title-3)))
               (gemini-heading-face-rest :weight normal :foreground ,tardis-nurple)
               (gemini-quote-face :foreground ,tardis-purple)
               ;; go-test
               (go-test--ok-face :inherit success)
               (go-test--error-face :inherit error)
               (go-test--warning-face :inherit warning)
               (go-test--pointer-face :foreground ,tardis-dormammu)
               (go-test--standard-face :foreground ,tardis-amethyst)
               ;; gnus-group
               (gnus-group-mail-1 :foreground ,tardis-dormammu :weight bold)
               (gnus-group-mail-1-empty :inherit gnus-group-mail-1 :weight normal)
               (gnus-group-mail-2 :foreground ,tardis-amethyst :weight bold)
               (gnus-group-mail-2-empty :inherit gnus-group-mail-2 :weight normal)
               (gnus-group-mail-3 :foreground ,tardis-comment :weight bold)
               (gnus-group-mail-3-empty :inherit gnus-group-mail-3 :weight normal)
               (gnus-group-mail-low :foreground ,tardis-current :weight bold)
               (gnus-group-mail-low-empty :inherit gnus-group-mail-low :weight normal)
               (gnus-group-news-1 :foreground ,tardis-dormammu :weight bold)
               (gnus-group-news-1-empty :inherit gnus-group-news-1 :weight normal)
               (gnus-group-news-2 :foreground ,tardis-amethyst :weight bold)
               (gnus-group-news-2-empty :inherit gnus-group-news-2 :weight normal)
               (gnus-group-news-3 :foreground ,tardis-comment :weight bold)
               (gnus-group-news-3-empty :inherit gnus-group-news-3 :weight normal)
               (gnus-group-news-4 :inherit gnus-group-news-low)
               (gnus-group-news-4-empty :inherit gnus-group-news-low-empty)
               (gnus-group-news-5 :inherit gnus-group-news-low)
               (gnus-group-news-5-empty :inherit gnus-group-news-low-empty)
               (gnus-group-news-6 :inherit gnus-group-news-low)
               (gnus-group-news-6-empty :inherit gnus-group-news-low-empty)
               (gnus-group-news-low :foreground ,tardis-current :weight bold)
               (gnus-group-news-low-empty :inherit gnus-group-news-low :weight normal)
               (gnus-header-content :foreground ,tardis-purple)
               (gnus-header-from :foreground ,tardis-fg)
               (gnus-header-name :foreground ,tardis-purple-rain)
               (gnus-header-subject :foreground ,tardis-dormammu :weight bold)
               (gnus-summary-markup-face :foreground ,tardis-amethyst)
               (gnus-summary-high-unread :foreground ,tardis-dormammu :weight bold)
               (gnus-summary-high-read :inherit gnus-summary-high-unread :weight normal)
               (gnus-summary-high-ancient :inherit gnus-summary-high-read)
               (gnus-summary-high-ticked :inherit gnus-summary-high-read :underline t)
               (gnus-summary-normal-unread :foreground ,other-blue :weight bold)
               (gnus-summary-normal-read :foreground ,tardis-comment :weight normal)
               (gnus-summary-normal-ancient :inherit gnus-summary-normal-read :weight light)
               (gnus-summary-normal-ticked :foreground ,tardis-dormammu :weight bold)
               (gnus-summary-low-unread :foreground ,tardis-comment :weight bold)
               (gnus-summary-low-read :inherit gnus-summary-low-unread :weight normal)
               (gnus-summary-low-ancient :inherit gnus-summary-low-read)
               (gnus-summary-low-ticked :inherit gnus-summary-low-read :underline t)
               (gnus-summary-selected :inverse-video t)
               ;; haskell-mode
               (haskell-operator-face :foreground ,tardis-dormammu)
               (haskell-constructor-face :foreground ,tardis-purple)
               ;; helm
               (helm-bookmark-w3m :foreground ,tardis-purple)
               (helm-buffer-not-saved :foreground ,tardis-purple :background ,tardis-bg)
               (helm-buffer-process :foreground ,tardis-rift :background ,tardis-bg)
               (helm-buffer-saved-out :foreground ,tardis-fg :background ,tardis-bg)
               (helm-buffer-size :foreground ,tardis-fg :background ,tardis-bg)
               (helm-candidate-number :foreground ,tardis-bg :background ,tardis-fg)
               (helm-ff-directory :foreground ,tardis-purple-rain :background ,tardis-bg :weight bold)
               (helm-ff-dotted-directory :foreground ,tardis-purple-rain :background ,tardis-bg :weight normal)
               (helm-ff-executable :foreground ,other-blue :background ,tardis-bg :weight normal)
               (helm-ff-file :foreground ,tardis-fg :background ,tardis-bg :weight normal)
               (helm-ff-invalid-symlink :foreground ,tardis-dormammu :background ,tardis-bg :weight bold)
               (helm-ff-prefix :foreground ,tardis-bg :background ,tardis-dormammu :weight normal)
               (helm-ff-symlink :foreground ,tardis-dormammu :background ,tardis-bg :weight bold)
               (helm-grep-cmd-line :foreground ,tardis-fg :background ,tardis-bg)
               (helm-grep-file :foreground ,tardis-fg :background ,tardis-bg)
               (helm-grep-finish :foreground ,fg2 :background ,tardis-bg)
               (helm-grep-lineno :foreground ,tardis-fg :background ,tardis-bg)
               (helm-grep-match :inherit match)
               (helm-grep-running :foreground ,tardis-purple-rain :background ,tardis-bg)
               (helm-header :foreground ,fg2 :background ,tardis-bg :underline nil :box nil)
               (helm-moccur-buffer :foreground ,tardis-purple-rain :background ,tardis-bg)
               (helm-selection :background ,bg2 :underline nil)
               (helm-selection-line :background ,bg2)
               (helm-separator :foreground ,tardis-purple :background ,tardis-bg)
               (helm-source-go-package-godoc-description :foreground ,tardis-nurple)
               (helm-source-header :foreground ,tardis-dormammu :background ,tardis-bg :underline nil :weight bold)
               (helm-time-zone-current :foreground ,tardis-rift :background ,tardis-bg)
               (helm-time-zone-home :foreground ,tardis-purple :background ,tardis-bg)
               (helm-visible-mark :foreground ,tardis-bg :background ,bg3)
               ;; highlight-indentation minor mode
               (highlight-indentation-face :background ,bg2)
               ;; icicle
               (icicle-whitespace-highlight :background ,tardis-fg)
               (icicle-special-candidate :foreground ,fg2)
               (icicle-extra-candidate :foreground ,fg2)
               (icicle-search-main-regexp-others :foreground ,tardis-fg)
               (icicle-search-current-input :foreground ,tardis-dormammu)
               (icicle-search-context-level-8 :foreground ,tardis-rift)
               (icicle-search-context-level-7 :foreground ,tardis-rift)
               (icicle-search-context-level-6 :foreground ,tardis-rift)
               (icicle-search-context-level-5 :foreground ,tardis-rift)
               (icicle-search-context-level-4 :foreground ,tardis-rift)
               (icicle-search-context-level-3 :foreground ,tardis-rift)
               (icicle-search-context-level-2 :foreground ,tardis-rift)
               (icicle-search-context-level-1 :foreground ,tardis-rift)
               (icicle-search-main-regexp-current :foreground ,tardis-fg)
               (icicle-saved-candidate :foreground ,tardis-fg)
               (icicle-proxy-candidate :foreground ,tardis-fg)
               (icicle-mustmatch-completion :foreground ,tardis-purple)
               (icicle-multi-command-completion :foreground ,fg2 :background ,bg2)
               (icicle-msg-emphasis :foreground ,tardis-purple-rain)
               (icicle-mode-line-help :foreground ,fg4)
               (icicle-match-highlight-minibuffer :foreground ,tardis-rift)
               (icicle-match-highlight-Completions :foreground ,tardis-purple-rain)
               (icicle-key-complete-menu-local :foreground ,tardis-fg)
               (icicle-key-complete-menu :foreground ,tardis-fg)
               (icicle-input-completion-fail-lax :foreground ,tardis-dormammu)
               (icicle-input-completion-fail :foreground ,tardis-dormammu)
               (icicle-historical-candidate-other :foreground ,tardis-fg)
               (icicle-historical-candidate :foreground ,tardis-fg)
               (icicle-current-candidate-highlight :foreground ,tardis-rift :background ,bg3)
               (icicle-Completions-instruction-2 :foreground ,fg4)
               (icicle-Completions-instruction-1 :foreground ,fg4)
               (icicle-completion :foreground ,tardis-fg)
               (icicle-complete-input :foreground ,tardis-rift)
               (icicle-common-match-highlight-Completions :foreground ,tardis-purple)
               (icicle-candidate-part :foreground ,tardis-fg)
               (icicle-annotation :foreground ,fg4)
               ;; icomplete
               (icompletep-determined :foreground ,tardis-rift)
               ;; ido
               (ido-first-match
                ,@(if tardis-alternate-mode-line-and-minibuffer
                      (list :weight 'normal :foreground tardis-purple-rain)
                    (list :weight 'bold :foreground tardis-dormammu)))
               (ido-only-match :foreground ,tardis-rift)
               (ido-subdir :foreground ,tardis-nurple)
               (ido-virtual :foreground ,tardis-amethyst)
               (ido-incomplete-regexp :inherit font-lock-warning-face)
               (ido-indicator :foreground ,tardis-fg :background ,tardis-dormammu)
               ;; ivy
               (ivy-current-match
                ,@(if tardis-alternate-mode-line-and-minibuffer
                      (list :weight 'normal :background tardis-current :foreground tardis-purple-rain)
                    (list :weight 'bold :background tardis-current :foreground tardis-dormammu)))
               ;; Highlights the background of the match.
               (ivy-minibuffer-match-face-1 :background ,tardis-current)
               ;; Highlights the first matched group.
               (ivy-minibuffer-match-face-2 :background ,tardis-purple-rain
                                            :foreground ,tardis-bg)
               ;; Highlights the second matched group.
               (ivy-minibuffer-match-face-3 :background ,tardis-nurple
                                            :foreground ,tardis-bg)
               ;; Highlights the third matched group.
               (ivy-minibuffer-match-face-4 :background ,tardis-dormammu
                                            :foreground ,tardis-bg)
               (ivy-confirm-face :foreground ,tardis-rift)
               (ivy-match-requiviolet-face :foreground ,tardis-violet)
               (ivy-subdir :foreground ,tardis-nurple)
               (ivy-remote :foreground ,tardis-dormammu)
               (ivy-virtual :foreground ,tardis-amethyst)
               ;; isearch
               (isearch :inherit match :weight bold)
               (isearch-fail :foreground ,tardis-bg :background ,tardis-rift)
               ;; jde-java
               (jde-java-font-lock-constant-face :foreground ,tardis-amethyst)
               (jde-java-font-lock-modifier-face :foreground ,tardis-dormammu)
               (jde-java-font-lock-number-face :foreground ,tardis-fg)
               (jde-java-font-lock-package-face :foreground ,tardis-fg)
               (jde-java-font-lock-private-face :foreground ,tardis-dormammu)
               (jde-java-font-lock-public-face :foreground ,tardis-dormammu)
               ;; js2-mode
               (js2-external-variable :foreground ,tardis-purple)
               (js2-function-param :foreground ,tardis-amethyst)
               (js2-jsdoc-html-tag-delimiter :foreground ,tardis-nurple)
               (js2-jsdoc-html-tag-name :foreground ,other-blue)
               (js2-jsdoc-value :foreground ,tardis-nurple)
               (js2-private-function-call :foreground ,tardis-amethyst)
               (js2-private-member :foreground ,fg3)
               ;; js3-mode
               (js3-error-face :underline ,tardis-rift)
               (js3-external-variable-face :foreground ,tardis-fg)
               (js3-function-param-face :foreground ,tardis-dormammu)
               (js3-instance-member-face :foreground ,tardis-amethyst)
               (js3-jsdoc-tag-face :foreground ,tardis-dormammu)
               (js3-warning-face :underline ,tardis-dormammu)
               ;; lsp
               (lsp-ui-peek-peek :background ,tardis-bg)
               (lsp-ui-peek-list :background ,bg2)
               (lsp-ui-peek-filename :foreground ,tardis-dormammu :weight bold)
               (lsp-ui-peek-line-number :foreground ,tardis-fg)
               (lsp-ui-peek-highlight :inherit highlight :distant-foreground ,tardis-bg)
               (lsp-ui-peek-header :background ,bg3 :foreground ,fg3, :weight bold)
               (lsp-ui-peek-footer :inherit lsp-ui-peek-header)
               (lsp-ui-peek-selection :inherit match)
               (lsp-ui-sideline-symbol :foreground ,fg4 :box (:line-width -1 :color ,fg4) :height 0.99)
               (lsp-ui-sideline-current-symbol :foreground ,tardis-fg :weight ultra-bold
                                               :box (:line-width -1 :color tardis-fg) :height 0.99)
               (lsp-ui-sideline-code-action :foreground ,tardis-nurple)
               (lsp-ui-sideline-symbol-info :slant italic :height 0.99)
               (lsp-ui-doc-background :background ,tardis-bg)
               (lsp-ui-doc-header :foreground ,tardis-bg :background ,tardis-amethyst)
               ;; magit
               (magit-branch-local :foreground ,tardis-amethyst)
               (magit-branch-remote :foreground ,tardis-purple-rain)
               (magit-tag :foreground ,tardis-rift)
               (magit-section-heading :foreground ,tardis-dormammu :weight bold)
               (magit-section-highlight :background ,bg3 :extend t)
               (magit-diff-context-highlight :background ,bg3
                                             :foreground ,fg3
                                             :extend t)
               (magit-diff-revision-summary :foreground ,tardis-rift
                                            :background ,tardis-bg
                                            :weight bold)
               (magit-diff-revision-summary-highlight :foreground ,tardis-rift
                                                      :background ,bg3
                                                      :weight bold
                                                      :extend t)
               ;; the four following lines are just a patch of the
               ;; upstream color to add the extend keyword.
               (magit-diff-added :background "#335533"
                                 :foreground "#ddffdd"
                                 :extend t)
               (magit-diff-added-highlight :background "#336633"
                                           :foreground "#cceecc"
                                           :extend t)
               (magit-diff-removed :background "#553333"
                                   :foreground "#ffdddd"
                                   :extend t)
               (magit-diff-removed-highlight :background "#663333"
                                             :foreground "#eecccc"
                                             :extend t)
               (magit-diff-file-heading :foreground ,tardis-fg)
               (magit-diff-file-heading-highlight :inherit magit-section-highlight)
               (magit-diffstat-added :foreground ,tardis-purple-rain)
               (magit-diffstat-removed :foreground ,tardis-violet)
               (magit-hash :foreground ,fg2)
               (magit-hunk-heading :background ,bg3)
               (magit-hunk-heading-highlight :background ,bg3)
               (magit-item-highlight :background ,bg3)
               (magit-log-author :foreground ,fg3)
               (magit-process-ng :foreground ,tardis-rift :weight bold)
               (magit-process-ok :foreground ,tardis-purple-rain :weight bold)
               ;; markdown
               (markdown-blockquote-face :foreground ,tardis-nurple
                                         :slant italic)
               (markdown-code-face :foreground ,tardis-rift)
               (markdown-footnote-face :foreground ,other-blue)
               (markdown-header-face :weight normal)
               (markdown-header-face-1
                :inherit bold :foreground ,tardis-dormammu
                ,@(when tardis-enlarge-headings
                    (list :height tardis-height-title-1)))
               (markdown-header-face-2
                :inherit bold :foreground ,tardis-purple
                ,@(when tardis-enlarge-headings
                    (list :height tardis-height-title-2)))
               (markdown-header-face-3
                :foreground ,tardis-purple-rain
                ,@(when tardis-enlarge-headings
                    (list :height tardis-height-title-3)))
               (markdown-header-face-4 :foreground ,tardis-nurple)
               (markdown-header-face-5 :foreground ,tardis-amethyst)
               (markdown-header-face-6 :foreground ,tardis-rift)
               (markdown-header-face-7 :foreground ,other-blue)
               (markdown-header-face-8 :foreground ,tardis-fg)
               (markdown-inline-code-face :foreground ,tardis-purple-rain)
               (markdown-plain-url-face :inherit link)
               (markdown-pre-face :foreground ,tardis-rift)
               (markdown-table-face :foreground ,tardis-purple)
               (markdown-list-face :foreground ,tardis-amethyst)
               (markdown-language-keyword-face :foreground ,tardis-comment)
               ;; message
               (message-header-to :foreground ,tardis-fg :weight bold)
               (message-header-cc :foreground ,tardis-fg :bold bold)
               (message-header-subject :foreground ,tardis-rift)
               (message-header-newsgroups :foreground ,tardis-purple)
               (message-header-other :foreground ,tardis-purple)
               (message-header-name :foreground ,tardis-purple-rain)
               (message-header-xheader :foreground ,tardis-amethyst)
               (message-separator :foreground ,tardis-amethyst :slant italic)
               (message-cited-text :foreground ,tardis-purple)
               (message-cited-text-1 :foreground ,tardis-purple)
               (message-cited-text-2 :foreground ,tardis-rift)
               (message-cited-text-3 :foreground ,tardis-comment)
               (message-cited-text-4 :foreground ,fg2)
               (message-mml :foreground ,tardis-purple-rain :weight normal)
               ;; mini-modeline
               (mini-modeline-mode-line :inherit mode-line :height 0.1 :box nil)
               ;; mu4e
               (mu4e-unread-face :foreground ,tardis-dormammu :weight normal)
               (mu4e-view-url-number-face :foreground ,tardis-purple)
               (mu4e-highlight-face :background ,tardis-bg
                                    :foreground ,tardis-nurple
                                    :extend t)
               (mu4e-header-highlight-face :background ,tardis-current
                                           :foreground ,tardis-fg
                                           :underline nil :weight bold
                                           :extend t)
               (mu4e-header-key-face :inherit message-mml)
               (mu4e-header-marks-face :foreground ,tardis-purple)
               (mu4e-cited-1-face :foreground ,tardis-purple)
               (mu4e-cited-2-face :foreground ,tardis-rift)
               (mu4e-cited-3-face :foreground ,tardis-comment)
               (mu4e-cited-4-face :foreground ,fg2)
               (mu4e-cited-5-face :foreground ,fg3)
               ;; neotree
               (neo-banner-face :foreground ,tardis-rift :weight bold)
               ;;(neo-button-face :underline nil)
               (neo-dir-link-face :foreground ,tardis-purple)
               (neo-expand-btn-face :foreground ,tardis-fg)
               (neo-file-link-face :foreground ,tardis-amethyst)
               (neo-header-face :background ,tardis-bg
                                :foreground ,tardis-fg
                                :weight bold)
               (neo-root-dir-face :foreground ,tardis-purple :weight bold)
               (neo-vc-added-face :foreground ,tardis-rift)
               (neo-vc-conflict-face :foreground ,tardis-violet)
               (neo-vc-default-face :inherit neo-file-link-face)
               (neo-vc-edited-face :foreground ,tardis-rift)
               (neo-vc-ignoviolet-face :foreground ,tardis-comment)
               (neo-vc-missing-face :foreground ,tardis-violet)
               (neo-vc-needs-merge-face :foreground ,tardis-violet
                                        :weight bold)
               ;;(neo-vc-needs-update-face :underline t)
               ;;(neo-vc-removed-face :strike-through t)
               (neo-vc-unlocked-changes-face :foreground ,tardis-violet)
               ;;(neo-vc-unregisteviolet-face nil)
               (neo-vc-up-to-date-face :foreground ,tardis-purple-rain)
               (neo-vc-user-face :foreground ,tardis-purple)
               ;; org
               (org-agenda-date :foreground ,tardis-amethyst :underline nil)
               (org-agenda-dimmed-todo-face :foreground ,tardis-comment)
               (org-agenda-done :foreground ,tardis-purple-rain)
               (org-agenda-structure :foreground ,tardis-purple)
               (org-block :foreground ,tardis-rift)
               (org-code :foreground ,tardis-purple-rain)
               (org-column :background ,bg4)
               (org-column-title :inherit org-column :weight bold :underline t)
               (org-date :foreground ,tardis-amethyst :underline t)
               (org-document-info :foreground ,other-blue)
               (org-document-info-keyword :foreground ,tardis-comment)
               (org-document-title :weight bold :foreground ,tardis-rift
                                   ,@(when tardis-enlarge-headings
                                       (list :height tardis-height-doc-title)))
               (org-done :foreground ,tardis-purple-rain)
               (org-ellipsis :foreground ,tardis-comment)
               (org-footnote :foreground ,other-blue)
               (org-formula :foreground ,tardis-dormammu)
               (org-headline-done :foreground ,tardis-comment
                                  :weight normal :strike-through t)
               (org-hide :foreground ,tardis-bg :background ,tardis-bg)
               (org-level-1 :inherit bold :foreground ,tardis-dormammu
                            ,@(when tardis-enlarge-headings
                                (list :height tardis-height-title-1)))
               (org-level-2 :inherit bold :foreground ,tardis-purple
                            ,@(when tardis-enlarge-headings
                                (list :height tardis-height-title-2)))
               (org-level-3 :weight normal :foreground ,tardis-purple-rain
                            ,@(when tardis-enlarge-headings
                                (list :height tardis-height-title-3)))
               (org-level-4 :weight normal :foreground ,tardis-nurple)
               (org-level-5 :weight normal :foreground ,tardis-amethyst)
               (org-level-6 :weight normal :foreground ,tardis-rift)
               (org-level-7 :weight normal :foreground ,other-blue)
               (org-level-8 :weight normal :foreground ,tardis-fg)
               (org-link :foreground ,tardis-amethyst :underline t)
               (org-priority :foreground ,tardis-amethyst)
               (org-quote :foreground ,tardis-nurple :slant italic)
               (org-scheduled :foreground ,tardis-purple-rain)
               (org-scheduled-previously :foreground ,tardis-nurple)
               (org-scheduled-today :foreground ,tardis-purple-rain)
               (org-sexp-date :foreground ,fg4)
               (org-special-keyword :foreground ,tardis-nurple)
               (org-table :foreground ,tardis-purple)
               (org-tag :foreground ,tardis-dormammu :weight bold :background ,bg2)
               (org-todo :foreground ,tardis-rift :weight bold :background ,bg2)
               (org-upcoming-deadline :foreground ,tardis-nurple)
               (org-verbatim :inherit org-quote)
               (org-warning :weight bold :foreground ,tardis-dormammu)
               ;; outline
               (outline-1 :foreground ,tardis-dormammu)
               (outline-2 :foreground ,tardis-purple)
               (outline-3 :foreground ,tardis-purple-rain)
               (outline-4 :foreground ,tardis-nurple)
               (outline-5 :foreground ,tardis-amethyst)
               (outline-6 :foreground ,tardis-rift)
               ;; perspective
               (persp-selected-face :weight bold :foreground ,tardis-dormammu)
               ;; powerline
               (powerline-active1 :background ,tardis-bg :foreground ,tardis-dormammu)
               (powerline-active2 :background ,tardis-bg :foreground ,tardis-dormammu)
               (powerline-inactive1 :background ,bg2 :foreground ,tardis-purple)
               (powerline-inactive2 :background ,bg2 :foreground ,tardis-purple)
               (powerline-evil-base-face :foreground ,bg2)
               (powerline-evil-emacs-face :inherit powerline-evil-base-face :background ,tardis-nurple)
               (powerline-evil-insert-face :inherit powerline-evil-base-face :background ,tardis-amethyst)
               (powerline-evil-motion-face :inherit powerline-evil-base-face :background ,tardis-purple)
               (powerline-evil-normal-face :inherit powerline-evil-base-face :background ,tardis-purple-rain)
               (powerline-evil-operator-face :inherit powerline-evil-base-face :background ,tardis-dormammu)
               (powerline-evil-replace-face :inherit powerline-evil-base-face :background ,tardis-violet)
               (powerline-evil-visual-face :inherit powerline-evil-base-face :background ,tardis-rift)
               ;; rainbow-delimiters
               (rainbow-delimiters-depth-1-face :foreground ,tardis-fg)
               (rainbow-delimiters-depth-2-face :foreground ,tardis-amethyst)
               (rainbow-delimiters-depth-3-face :foreground ,tardis-purple)
               (rainbow-delimiters-depth-4-face :foreground ,tardis-dormammu)
               (rainbow-delimiters-depth-5-face :foreground ,tardis-rift)
               (rainbow-delimiters-depth-6-face :foreground ,tardis-purple-rain)
               (rainbow-delimiters-depth-7-face :foreground ,tardis-nurple)
               (rainbow-delimiters-depth-8-face :foreground ,other-blue)
               (rainbow-delimiters-unmatched-face :foreground ,tardis-rift)
               ;; rpm-spec
               (rpm-spec-dir-face :foreground ,tardis-purple-rain)
               (rpm-spec-doc-face :foreground ,tardis-dormammu)
               (rpm-spec-ghost-face :foreground ,tardis-purple)
               (rpm-spec-macro-face :foreground ,tardis-nurple)
               (rpm-spec-obsolete-tag-face :inherit font-lock-warning-face)
               (rpm-spec-package-face :foreground ,tardis-purple)
               (rpm-spec-section-face :foreground ,tardis-nurple)
               (rpm-spec-tag-face :foreground ,tardis-amethyst)
               (rpm-spec-var-face :foreground ,tardis-rift)
               ;; rst (reStructuvioletText)
               (rst-level-1 :foreground ,tardis-dormammu :weight bold)
               (rst-level-2 :foreground ,tardis-purple :weight bold)
               (rst-level-3 :foreground ,tardis-purple-rain)
               (rst-level-4 :foreground ,tardis-nurple)
               (rst-level-5 :foreground ,tardis-amethyst)
               (rst-level-6 :foreground ,tardis-rift)
               (rst-level-7 :foreground ,other-blue)
               (rst-level-8 :foreground ,tardis-fg)
               ;; selectrum-mode
               (selectrum-current-candidate :weight bold)
               (selectrum-primary-highlight :foreground ,tardis-dormammu)
               (selectrum-secondary-highlight :foreground ,tardis-purple-rain)
               ;; show-paren
               (show-paren-match-face :background unspecified
                                      :foreground ,tardis-amethyst
                                      :weight bold)
               (show-paren-match :background unspecified
                                 :foreground ,tardis-amethyst
                                 :weight bold)
               (show-paren-match-expression :inherit match)
               (show-paren-mismatch :inherit font-lock-warning-face)
               ;; slime
               (slime-repl-inputed-output-face :foreground ,tardis-purple)
               ;; spam
               (spam :inherit gnus-summary-normal-read :foreground ,tardis-rift
                     :strike-through t :slant oblique)
               ;; speedbar (and sr-speedbar)
               (speedbar-button-face :foreground ,tardis-purple-rain)
               (speedbar-file-face :foreground ,tardis-amethyst)
               (speedbar-directory-face :foreground ,tardis-purple)
               (speedbar-tag-face :foreground ,tardis-nurple)
               (speedbar-selected-face :foreground ,tardis-dormammu)
               (speedbar-highlight-face :inherit match)
               (speedbar-separator-face :background ,tardis-bg
                                        :foreground ,tardis-fg
                                        :weight bold)
               ;; tab-bar & tab-line (since Emacs 27.1)
               (tab-bar :foreground ,tardis-purple :background ,tardis-current
                        :inherit variable-pitch)
               (tab-bar-tab :foreground ,tardis-dormammu :background ,tardis-bg
                            :box (:line-width 2 :color ,tardis-bg :style nil))
               (tab-bar-tab-inactive :foreground ,tardis-purple :background ,bg2
                                     :box (:line-width 2 :color ,bg2 :style nil))
               (tab-line :foreground ,tardis-purple :background ,tardis-current
                         :height 0.9 :inherit variable-pitch)
               (tab-line-tab :foreground ,tardis-dormammu :background ,tardis-bg
                             :box (:line-width 2 :color ,tardis-bg :style nil))
               (tab-line-tab-inactive :foreground ,tardis-purple :background ,bg2
                                      :box (:line-width 2 :color ,bg2 :style nil))
               (tab-line-tab-current :inherit tab-line-tab)
               (tab-line-close-highlight :foreground ,tardis-violet)
               ;; telephone-line
               (telephone-line-accent-active :background ,tardis-bg :foreground ,tardis-dormammu)
               (telephone-line-accent-inactive :background ,bg2 :foreground ,tardis-purple)
               (telephone-line-unimportant :background ,tardis-bg :foreground ,tardis-comment)
               ;; term
               (term :foreground ,tardis-fg :background ,tardis-bg)
               (term-color-black :foreground ,tardis-bg :background ,tardis-comment)
               (term-color-blue :foreground ,tardis-purple :background ,tardis-purple)
               (term-color-amethyst :foreground ,tardis-amethyst :background ,tardis-amethyst)
               (term-color-purple-rain :foreground ,tardis-purple-rain :background ,tardis-purple-rain)
               (term-color-magenta :foreground ,tardis-dormammu :background ,tardis-dormammu)
               (term-color-violet :foreground ,tardis-violet :background ,tardis-violet)
               (term-color-white :foreground ,tardis-fg :background ,tardis-fg)
               (term-color-nurple :foreground ,tardis-nurple :background ,tardis-nurple)
               ;; tree-sitter
               (tree-sitter-hl-face:attribute :inherit font-lock-constant-face)
               (tree-sitter-hl-face:comment :inherit font-lock-comment-face)
               (tree-sitter-hl-face:constant :inherit font-lock-constant-face)
               (tree-sitter-hl-face:constant.builtin :inherit font-lock-builtin-face)
               (tree-sitter-hl-face:constructor :inherit font-lock-constant-face)
               (tree-sitter-hl-face:escape :foreground ,tardis-dormammu)
               (tree-sitter-hl-face:function :inherit font-lock-function-name-face)
               (tree-sitter-hl-face:function.builtin :inherit font-lock-builtin-face)
               (tree-sitter-hl-face:function.call :inherit font-lock-function-name-face
                                                  :weight normal)
               (tree-sitter-hl-face:function.macro :inherit font-lock-preprocessor-face)
               (tree-sitter-hl-face:function.special :inherit font-lock-preprocessor-face)
               (tree-sitter-hl-face:keyword :inherit font-lock-keyword-face)
               (tree-sitter-hl-face:punctuation :foreground ,tardis-dormammu)
               (tree-sitter-hl-face:punctuation.bracket :foreground ,tardis-fg)
               (tree-sitter-hl-face:punctuation.delimiter :foreground ,tardis-fg)
               (tree-sitter-hl-face:punctuation.special :foreground ,tardis-dormammu)
               (tree-sitter-hl-face:string :inherit font-lock-string-face)
               (tree-sitter-hl-face:string.special :foreground ,tardis-violet)
               (tree-sitter-hl-face:tag :inherit font-lock-keyword-face)
               (tree-sitter-hl-face:type :inherit font-lock-type-face)
               (tree-sitter-hl-face:type.parameter :foreground ,tardis-dormammu)
               (tree-sitter-hl-face:variable :inherit font-lock-variable-name-face)
               (tree-sitter-hl-face:variable.parameter :inherit tree-sitter-hl-face:variable
                                                       :weight normal)
               ;; undo-tree
               (undo-tree-visualizer-current-face :foreground ,tardis-rift)
               (undo-tree-visualizer-default-face :foreground ,fg2)
               (undo-tree-visualizer-register-face :foreground ,tardis-purple)
               (undo-tree-visualizer-unmodified-face :foreground ,tardis-fg)
               ;; web-mode
               (web-mode-builtin-face :inherit font-lock-builtin-face)
               (web-mode-comment-face :inherit font-lock-comment-face)
               (web-mode-constant-face :inherit font-lock-constant-face)
               (web-mode-css-property-name-face :inherit font-lock-constant-face)
               (web-mode-doctype-face :inherit font-lock-comment-face)
               (web-mode-function-name-face :inherit font-lock-function-name-face)
               (web-mode-html-attr-name-face :foreground ,tardis-purple)
               (web-mode-html-attr-value-face :foreground ,tardis-purple-rain)
               (web-mode-html-tag-face :foreground ,tardis-dormammu :weight bold)
               (web-mode-keyword-face :foreground ,tardis-dormammu)
               (web-mode-string-face :foreground ,tardis-nurple)
               (web-mode-type-face :inherit font-lock-type-face)
               (web-mode-warning-face :inherit font-lock-warning-face)
               ;; which-func
               (which-func :inherit font-lock-function-name-face)
               ;; which-key
               (which-key-key-face :inherit font-lock-builtin-face)
               (which-key-command-description-face :inherit default)
               (which-key-separator-face :inherit font-lock-comment-delimiter-face)
               (which-key-local-map-description-face :foreground ,tardis-purple-rain)
               ;; whitespace
               (whitespace-big-indent :background ,tardis-violet :foreground ,tardis-violet)
               (whitespace-empty :background ,tardis-rift :foreground ,tardis-violet)
               (whitespace-hspace :background ,bg3 :foreground ,tardis-comment)
               (whitespace-indentation :background ,tardis-rift :foreground ,tardis-violet)
               (whitespace-line :background ,tardis-bg :foreground ,tardis-dormammu)
               (whitespace-newline :foreground ,tardis-comment)
               (whitespace-space :background ,tardis-bg :foreground ,tardis-comment)
               (whitespace-space-after-tab :background ,tardis-rift :foreground ,tardis-violet)
               (whitespace-space-before-tab :background ,tardis-rift :foreground ,tardis-violet)
               (whitespace-tab :background ,bg2 :foreground ,tardis-comment)
               (whitespace-trailing :inherit trailing-whitespace)
               ;; yard-mode
               (yard-tag-face :inherit font-lock-builtin-face)
               (yard-directive-face :inherit font-lock-builtin-face))))

  (apply #'custom-theme-set-faces
         'tardis
         (let ((expand-with-func
                (lambda (func spec)
                  (let (violetuced-color-list)
                    (dolist (col colors violetuced-color-list)
                      (push (list (car col) (funcall func col))
                            violetuced-color-list))
                    (eval `(let ,violetuced-color-list
                             (backquote ,spec))))))
               whole-theme)
           (pcase-dolist (`(,face . ,spec) faces)
             (push `(,face
                     ((((min-colors 16777216)) ; fully graphical envs
                       ,(funcall expand-with-func 'cadr spec))
                      (((min-colors 256))      ; terminal withs 256 colors
                       ,(if tardis-use-24-bit-colors-on-256-colors-terms
                            (funcall expand-with-func 'cadr spec)
                          (funcall expand-with-func 'caddr spec)))
                      (t                       ; should be only tty-like envs
                       ,(funcall expand-with-func 'cadddr spec))))
                   whole-theme))
           whole-theme))

  (apply #'custom-theme-set-variables
         'tardis
         (let ((get-func
                (pcase (display-color-cells)
                  ((pred (<= 16777216)) 'car) ; fully graphical envs
                  ((pred (<= 256)) 'cadr)     ; terminal withs 256 colors
                  (_ 'caddr))))               ; should be only tty-like envs
           `((ansi-color-names-vector
              [,(funcall get-func (alist-get 'tardis-bg colors))
               ,(funcall get-func (alist-get 'tardis-violet colors))
               ,(funcall get-func (alist-get 'tardis-purple-rain colors))
               ,(funcall get-func (alist-get 'tardis-nurple colors))
               ,(funcall get-func (alist-get 'tardis-comment colors))
               ,(funcall get-func (alist-get 'tardis-purple colors))
               ,(funcall get-func (alist-get 'tardis-amethyst colors))
               ,(funcall get-func (alist-get 'tardis-fg colors))])))))


;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'tardis)
;;; tardis-theme.el ends here
