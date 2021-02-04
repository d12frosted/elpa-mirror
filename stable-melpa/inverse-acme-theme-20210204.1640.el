;;; inverse-acme-theme.el --- A theme that looks like an inverse of Acme's color scheme.

;; Author: Dylan Johnson
;; (current maintainer)
;;
;; URL: http://github.com/dcjohnson/inverse-acme-theme
;; Package-Version: 20210204.1640
;; Package-Commit: 79008920ce7923312ada6f95a3ec1f96ce513c0b
;; Version: 1.0
;; Package-Requires: ((autothemer "0.2") (cl-lib "0.5"))

;;; Credits:
;; Forked from the gruvbox-theme just to have access to all the color definitions.

;; Pavel Pertsev created the original theme for Vim, on which this port
;; is based.

;; Lee Machin created the first port of the original theme, which
;; Greduan developed further adding support for several major modes.
;;
;; Jason Milkins (ocodo) has maintained the theme since 2015 and is
;; working with the community to add further mode support and align
;; the project more closely with Vim Gruvbox.

;; background is set as acme-dark0
;; text is set as acme-light0

;;; Commentary:
;; I haven't done anything with the Xterm/256 colors yet.

;;; Code:
(provide 'inverse-acme-theme)
(eval-when-compile
  (require 'cl-lib))

(require 'autothemer)

(unless (>= emacs-major-version 24)
  (error "Requires Emacs 24 or later"))

(defcustom  inverse-acme-contrast 'medium
  "Contrast level for the theme background."
  :options '(soft medium hard))

(autothemer-deftheme
 inverse-acme
 "Acme but reversed; and in a better editor."

 ((((class color) (min-colors #xFFFFFF))        ; col 1 GUI/24bit
   ((class color) (min-colors #xFF)))           ; col 2 Xterm/256

  (acme-dark0_hard      "#1d2021" "#1c1c1c")
  (acme-dark0           "#282828" "#262626")
  (acme-dark0_soft      "#32302f" "#303030")
  (acme-dark1           "#3c3836" "#3a3a3a")
  (acme-dark2           "#504945" "#4e4e4e")
  (acme-dark3           "#665c54" "#626262")
  (acme-dark4           "#7c6f64" "#767676")

  (acme-gray            "#928374" "#8a8a8a")

  (acme-light0_hard     "#ffffc8" "#ffffd7")
  (acme-light0          "#fdf4c1" "#ffffaf")
  (acme-light0_soft     "#f4e8ba" "#ffffaf")
  (acme-light1          "#ebdbb2" "#ffdfaf")
  (acme-light2          "#d5c4a1" "#bcbcbc")
  (acme-light3          "#bdae93" "#a8a8a8")
  (acme-light4          "#a89984" "#949494")

  (acme-bright_red      "#fb4933" "#d75f5f")
  (acme-bright_green    "#b8bb26" "#afaf00")
  (acme-bright_yellow   "#fabd2f" "#ffaf00")
  (acme-bright_blue     "#83a598" "#87afaf")
  (acme-bright_purple   "#d3869b" "#d787af")
  (acme-bright_aqua     "#8ec07c" "#87af87")
  (acme-bright_orange   "#fe8019" "#ff8700")

  (acme-neutral_red     "#fb4934" "#d75f5f")
  (acme-neutral_green   "#b8bb26" "#afaf00")
  (acme-neutral_yellow  "#fabd2f" "#ffaf00")
  (acme-neutral_blue    "#83a598" "#87afaf")
  (acme-neutral_purple  "#d3869b" "#d787af")
  (acme-neutral_aqua    "#8ec07c" "#87af87")
  (acme-neutral_orange  "#fe8019" "#ff8700")

  (acme-faded_red       "#9d0006" "#870000")
  (acme-faded_green     "#79740e" "#878700")
  (acme-faded_yellow    "#b57614" "#af8700")
  (acme-faded_blue      "#076678" "#005f87")
  (acme-faded_purple    "#8f3f71" "#875f87")
  (acme-faded_aqua      "#427b58" "#5f8787")
  (acme-faded_orange    "#af3a03" "#af5f00")

  (acme-dark_red        "#421E1E" "#5f0000")
  (acme-dark_blue       "#2B3C44" "#000087")
  (acme-dark_aqua       "#36473A" "#005f5f")

  (acme-delimiter-one   "#458588" "#008787")
  (acme-delimiter-two   "#b16286" "#d75f87")
  (acme-delimiter-three "#8ec07c" "#87af87")
  (acme-delimiter-four  "#d65d0e" "#d75f00")
  (acme-white           "#FFFFFF" "#FFFFFF")
  (acme-black           "#000000" "#000000")
  (acme-sienna          "#DD6F48" "#d7875f")
  (acme-darkslategray4  "#528B8B" "#5f8787")
  (acme-lightblue4      "#66999D" "#5fafaf")
  (acme-burlywood4      "#BBAA97" "#afaf87")
  (acme-aquamarine4     "#83A598" "#87af87")
  (acme-turquoise4      "#61ACBB" "#5fafaf")

  (acme-bg (cl-case inverse-acme-contrast
                (hard acme-dark0_hard)
                (soft acme-dark0_soft)
                ;; Medium by default.
                (t    acme-dark0))))

 ;; UI
 ((default                                   (:background acme-bg :foreground acme-light0))
  (cursor                                    (:background acme-light0))
  (mode-line                                 (:background acme-dark2 :foreground acme-light2 :box nil))
  (mode-line-inactive                        (:background acme-dark1 :foreground acme-light4 :box nil))
  (fringe                                    (:background acme-bg))
  (linum                                     (:background acme-bg :foreground acme-dark4))
  (hl-line                                   (:background acme-dark1))
  (region                                    (:background acme-dark2)) ;;selection
  (secondary-selection                       (:background acme-dark1))
  (minibuffer-prompt                         (:background acme-bg :foreground acme-neutral_green :bold t))
  (vertical-border                           (:foreground acme-dark2))
  (link                                      (:foreground acme-faded_blue :underline t))
  (shadow                                    (:foreground acme-dark4))

  ;; Built-in syntax
  (font-lock-builtin-face                           (:foreground acme-light0))
  (font-lock-constant-face                          (:foreground acme-light0))
  (font-lock-comment-face                           (:foreground acme-light0))
  (font-lock-function-name-face                     (:foreground acme-light0))
  (font-lock-keyword-face                           (:foreground acme-light0))
  (font-lock-string-face                            (:foreground acme-light0))
  (font-lock-variable-name-face                     (:foreground acme-light0))
  (font-lock-type-face                              (:foreground acme-light0))
  (font-lock-warning-face                           (:foreground acme-light0))

  ;; whitespace-mode
  (whitespace-space                          (:background acme-bg :foreground acme-dark4))
  (whitespace-hspace                         (:background acme-bg :foreground acme-dark4))
  (whitespace-tab                            (:background acme-bg :foreground acme-dark4))
  (whitespace-newline                        (:background acme-bg :foreground acme-dark4))
  (whitespace-trailing                       (:background acme-dark1 :foreground acme-neutral_red))
  (whitespace-line                           (:background acme-dark1 :foreground acme-neutral_red))
  (whitespace-space-before-tab               (:background acme-bg :foreground acme-dark4))
  (whitespace-indentation                    (:background acme-bg :foreground acme-dark4))
  (whitespace-empty                          (:background nil :foreground nil))
  (whitespace-space-after-tab                (:background acme-bg :foreground acme-dark4))

  ;; RainbowDelimiters
  (rainbow-delimiters-depth-1-face           (:foreground acme-delimiter-one))
  (rainbow-delimiters-depth-2-face           (:foreground acme-delimiter-two))
  (rainbow-delimiters-depth-3-face           (:foreground acme-delimiter-three))
  (rainbow-delimiters-depth-4-face           (:foreground acme-delimiter-four))
  (rainbow-delimiters-depth-5-face           (:foreground acme-delimiter-one))
  (rainbow-delimiters-depth-6-face           (:foreground acme-delimiter-two))
  (rainbow-delimiters-depth-7-face           (:foreground acme-delimiter-three))
  (rainbow-delimiters-depth-8-face           (:foreground acme-delimiter-four))
  (rainbow-delimiters-depth-9-face           (:foreground acme-delimiter-one))
  (rainbow-delimiters-depth-10-face          (:foreground acme-delimiter-two))
  (rainbow-delimiters-depth-11-face          (:foreground acme-delimiter-three))
  (rainbow-delimiters-depth-12-face          (:foreground acme-delimiter-four))
  (rainbow-delimiters-unmatched-face         (:background nil :foreground acme-light0))

  ;; sh-mode
  (sh-quoted-exec (:foreground acme-light0))

  ;; eshell-mode
  (eshell-ls-archive      (:foreground acme-light0))
  (eshell-ls-backup       (:foreground acme-light0))
  (eshell-ls-clutter      (:foreground acme-light0))
  (eshell-ls-directory    (:foreground acme-light0))
  (eshell-ls-executable   (:foreground acme-light0))
  (eshell-ls-missing      (:foreground acme-light0))
  (eshell-ls-product      (:foreground acme-light0))
  (eshell-ls-readonly     (:foreground acme-light0))
  (eshell-ls-special      (:foreground acme-light0))
  (eshell-ls-symlink      (:foreground acme-light0))
  (eshell-ls-unreadable   (:foreground acme-light2))
  (eshell-prompt          (:foreground acme-gray))

  ;; ocaml
  (tuareg-font-lock-operator-face (:foreground acme-light0))
  (tuareg-font-lock-governing-face (:foreground acme-light0))

  ;; coq via proof general
  (coq-solve-tactics-face (:foreground acme-light0))
  (coq-cheat-face (:foreground acme-light0))
  (proof-tactics-name-face (:foreground acme-light0))
  (proof-tacticals-name-face (:foreground acme-light0))
  
  ;; linum-relative
  (linum-relative-current-face               (:background acme-dark1 :foreground acme-light4))

  ;; Highlight indentation mode
  (highlight-indentation-current-column-face (:background acme-dark2))
  (highlight-indentation-face                (:background acme-dark1))

  ;; Smartparens
  (sp-pair-overlay-face                      (:background acme-dark2))
  (sp-show-pair-match-face                   (:background acme-dark2)) ;; Pair tags highlight
  (sp-show-pair-mismatch-face                (:background acme-neutral_red)) ;; Highlight for bracket without pair
  ;;(sp-wrap-overlay-face                     (:inherit 'sp-wrap-overlay-face))
  ;;(sp-wrap-tag-overlay-face                 (:inherit 'sp-wrap-overlay-face))

  ;; elscreen
  (elscreen-tab-background-face              (:background acme-bg :box nil)) ;; Tab bar, not the tabs
  (elscreen-tab-control-face                 (:background acme-dark2 :foreground acme-neutral_red :underline nil :box nil)) ;; The controls
  (elscreen-tab-current-screen-face          (:background acme-dark4 :foreground acme-dark0 :box nil)) ;; Current tab
  (elscreen-tab-other-screen-face            (:background acme-dark2 :foreground acme-light4 :underline nil :box nil)) ;; Inactive tab

  ;; ag (The Silver Searcher)
  (ag-hit-face                               (:foreground acme-neutral_blue))
  (ag-match-face                             (:foreground acme-neutral_red))

  ;; Diffs
  (diff-changed                              (:background nil :foreground acme-light1))
  (diff-added                                (:background nil :foreground acme-neutral_green))
  (diff-removed                              (:background nil :foreground acme-neutral_red))
  (diff-indicator-changed                    (:inherit 'diff-changed))
  (diff-indicator-added                      (:inherit 'diff-added))
  (diff-indicator-removed                    (:inherit 'diff-removed))

  (js2-warning                               (:underline (:color acme-bright_yellow :style 'wave)))
  (js2-error                                 (:underline (:color acme-bright_red :style 'wave)))
  (js2-external-variable                     (:underline (:color acme-bright_aqua :style 'wave)))
  (js2-jsdoc-tag                             (:background nil :foreground acme-gray  ))
  (js2-jsdoc-type                            (:background nil :foreground acme-light4))
  (js2-jsdoc-value                           (:background nil :foreground acme-light3))
  (js2-function-param                        (:background nil :foreground acme-bright_aqua))
  (js2-function-call                         (:background nil :foreground acme-bright_blue))
  (js2-instance-member                       (:background nil :foreground acme-bright_orange))
  (js2-private-member                        (:background nil :foreground acme-faded_yellow))
  (js2-private-function-call                 (:background nil :foreground acme-faded_aqua))
  (js2-jsdoc-html-tag-name                   (:background nil :foreground acme-light4))
  (js2-jsdoc-html-tag-delimiter              (:background nil :foreground acme-light3))

  ;; popup
  (popup-face                                (:foreground acme-light1 :background acme-dark1))
  (popup-menu-mouse-face                     (:foreground acme-light0 :background acme-faded_green))
  (popup-menu-selection-face                 (:foreground acme-light0 :background acme-faded_green))
  (popup-tip-face                            (:foreground acme-light2 :background acme-dark2))

  ;; helm
  (helm-M-x-key                              (:foreground acme-neutral_orange ))
  (helm-action                               (:foreground acme-white :underline t))
  (helm-bookmark-addressbook                 (:foreground acme-neutral_red))
  (helm-bookmark-directory                   (:foreground acme-bright_purple))
  (helm-bookmark-file                        (:foreground acme-faded_blue))
  (helm-bookmark-gnus                        (:foreground acme-faded_purple))
  (helm-bookmark-info                        (:foreground acme-turquoise4))
  (helm-bookmark-man                         (:foreground acme-sienna))
  (helm-bookmark-w3m                         (:foreground acme-neutral_yellow))
  (helm-buffer-directory                     (:foreground acme-white :background acme-bright_blue))
  (helm-buffer-not-saved                     (:foreground acme-faded_red))
  (helm-buffer-process                       (:foreground acme-burlywood4))
  (helm-buffer-saved-out                     (:foreground acme-bright_red))
  (helm-buffer-size                          (:foreground acme-bright_purple))
  (helm-candidate-number                     (:foreground acme-neutral_green))
  (helm-ff-directory                         (:foreground acme-neutral_purple))
  (helm-ff-executable                        (:foreground acme-turquoise4))
  (helm-ff-file                              (:foreground acme-sienna))
  (helm-ff-invalid-symlink                   (:foreground acme-white :background acme-bright_red))
  (helm-ff-prefix                            (:foreground acme-black :background acme-neutral_yellow))
  (helm-ff-symlink                           (:foreground acme-neutral_orange))
  (helm-grep-cmd-line                        (:foreground acme-neutral_green))
  (helm-grep-file                            (:foreground acme-faded_purple))
  (helm-grep-finish                          (:foreground acme-turquoise4))
  (helm-grep-lineno                          (:foreground acme-neutral_orange))
  (helm-grep-match                           (:foreground acme-neutral_yellow))
  (helm-grep-running                         (:foreground acme-neutral_red))
  (helm-header                               (:foreground acme-aquamarine4))
  (helm-helper                               (:foreground acme-aquamarine4))
  (helm-history-deleted                      (:foreground acme-black :background acme-bright_red))
  (helm-history-remote                       (:foreground acme-faded_red))
  (helm-lisp-completion-info                 (:foreground acme-faded_orange))
  (helm-lisp-show-completion                 (:foreground acme-bright_red))
  (helm-locate-finish                        (:foreground acme-white :background acme-aquamarine4))
  (helm-match                                (:foreground acme-neutral_orange))
  (helm-moccur-buffer                        (:foreground acme-bright_aqua :underline t))
  (helm-prefarg                              (:foreground acme-turquoise4))
  (helm-selection                            (:foreground acme-white :background acme-dark2))
  (helm-selection-line                       (:foreground acme-white :background acme-dark2))
  (helm-separator                            (:foreground acme-faded_red))
  (helm-source-header                        (:foreground acme-light2))
  (helm-visible-mark                         (:foreground acme-black :background acme-light3))

  ;; company-mode
  (company-scrollbar-bg                      (:background acme-dark1))
  (company-scrollbar-fg                      (:background acme-dark0_soft))
  (company-tooltip                           (:background acme-dark0_soft))
  (company-tooltip-annotation                (:foreground acme-neutral_green))
  (company-tooltip-selection                 (:foreground acme-neutral_purple))
  (company-tooltip-common                    (:foreground acme-neutral_blue :underline t))
  (company-tooltip-common-selection          (:foreground acme-neutral_blue :underline t))
  (company-preview-common                    (:foreground acme-neutral_purple))

  ;; Term
  (term-color-black                          (:foreground acme-dark1))
  (term-color-blue                           (:foreground acme-neutral_blue))
  (term-color-cyan                           (:foreground acme-neutral_aqua))
  (term-color-green                          (:foreground acme-neutral_green))
  (term-color-magenta                        (:foreground acme-neutral_purple))
  (term-color-red                            (:foreground acme-neutral_red))
  (term-color-white                          (:foreground acme-light1))
  (term-color-yellow                         (:foreground acme-neutral_yellow))
  (term-default-fg-color                     (:foreground acme-light0))
  (term-default-bg-color                     (:background acme-bg))

  ;; message-mode
  (message-header-to                         (:inherit 'font-lock-variable-name-face))
  (message-header-cc                         (:inherit 'font-lock-variable-name-face))
  (message-header-subject                    (:foreground acme-neutral_orange :weight 'bold))
  (message-header-newsgroups                 (:foreground acme-neutral_yellow :weight 'bold))
  (message-header-other                      (:inherit 'font-lock-variable-name-face))
  (message-header-name                       (:inherit 'font-lock-keyword-face))
  (message-header-xheader                    (:foreground acme-faded_blue))
  (message-separator                         (:inherit 'font-lock-comment-face))
  (message-cited-text                        (:inherit 'font-lock-comment-face))
  (message-mml                               (:foreground acme-faded_green :weight 'bold))

  ;; org-mode
  (org-hide                                  (:foreground acme-dark0))
  (org-level-1                               (:foreground acme-neutral_blue))
  (org-level-2                               (:foreground acme-neutral_yellow))
  (org-level-3                               (:foreground acme-neutral_purple))
  (org-level-4                               (:foreground acme-neutral_red))
  (org-level-5                               (:foreground acme-neutral_green))
  (org-level-6                               (:foreground acme-neutral_aqua))
  (org-level-7                               (:foreground acme-faded_blue))
  (org-level-8                               (:foreground acme-neutral_orange))
  (org-special-keyword                       (:inherit 'font-lock-comment-face))
  (org-drawer                                (:inherit 'font-lock-function-face))
  (org-column                                (:background acme-dark0))
  (org-column-title                          (:background acme-dark0 :underline t :weight 'bold))
  (org-warning                               (:foreground acme-neutral_red :weight 'bold :underline nil :bold t))
  (org-archived                              (:foreground acme-light0 :weight 'bold))
  (org-link                                  (:foreground acme-faded_aqua :underline t))
  (org-footnote                              (:foreground acme-neutral_aqua :underline t))
  (org-ellipsis                              (:foreground acme-light4 :underline t))
  (org-date                                  (:foreground acme-neutral_blue :underline t))
  (org-sexp-date                             (:foreground acme-faded_blue :underline t))
  (org-tag                                   (:bold t :weight 'bold))
  (org-list-dt                               (:bold t :weight 'bold))
  (org-todo                                  (:foreground acme-neutral_red :weight 'bold :bold t))
  (org-done                                  (:foreground acme-neutral_aqua :weight 'bold :bold t))
  (org-agenda-done                           (:foreground acme-neutral_aqua))
  (org-headline-done                         (:foreground acme-neutral_aqua))
  (org-table                                 (:foreground acme-neutral_blue))
  (org-formula                               (:foreground acme-neutral_yellow))
  (org-document-title                        (:foreground acme-faded_blue))
  (org-document-info                         (:foreground acme-faded_blue))
  (org-agenda-structure                      (:inherit 'font-lock-comment-face))
  (org-agenda-date-today                     (:foreground acme-light0 :weight 'bold :italic t))
  (org-scheduled                             (:foreground acme-neutral_yellow))
  (org-scheduled-today                       (:foreground acme-neutral_blue))
  (org-scheduled-previously                  (:foreground acme-faded_red))
  (org-upcoming-deadline                     (:inherit 'font-lock-keyword-face))
  (org-deadline-announce                     (:foreground acme-faded_red))
  (org-time-grid                             (:foreground acme-faded_orange))

  ;; org-habit
  (org-habit-clear-face                      (:background acme-faded_blue))
  (org-habit-clear-future-face               (:background acme-neutral_blue))
  (org-habit-ready-face                      (:background acme-faded_green))
  (org-habit-ready-future-face               (:background acme-neutral_green))
  (org-habit-alert-face                      (:background acme-faded_yellow))
  (org-habit-alert-future-face               (:background acme-neutral_yellow))
  (org-habit-overdue-face                    (:background acme-faded_red))
  (org-habit-overdue-future-face             (:background acme-neutral_red))

  ;; elfeed
  (elfeed-search-title-face                  (:foreground acme-gray  ))
  (elfeed-search-unread-title-face           (:foreground acme-light0))
  (elfeed-search-date-face                   (:inherit 'font-lock-builtin-face :underline t))
  (elfeed-search-feed-face                   (:inherit 'font-lock-variable-name-face))
  (elfeed-search-tag-face                    (:inherit 'font-lock-keyword-face))
  (elfeed-search-last-update-face            (:inherit 'font-lock-comment-face))
  (elfeed-search-unread-count-face           (:inherit 'font-lock-comment-face))
  (elfeed-search-filter-face                 (:inherit 'font-lock-string-face))

  ;; Smart-mode-line
  (sml/global                                (:foreground acme-burlywood4 :inverse-video nil))
  (sml/modes                                 (:foreground acme-bright_green))
  (sml/filename                              (:foreground acme-bright_red :weight 'bold))
  (sml/prefix                                (:foreground acme-light1))
  (sml/read-only                             (:foreground acme-neutral_blue))
  (persp-selected-face                       (:foreground acme-neutral_orange))

  ;;isearch
  (isearch                                   (:foreground acme-black :background acme-neutral_orange))
  (lazy-highlight                            (:foreground acme-black :background acme-neutral_yellow))
  (isearch-fail                              (:foreground acme-light0 :background acme-bright_red))

  ;; markdown-mode
  (markdown-header-face-1                    (:foreground acme-light0))
  (markdown-header-face-2                    (:foreground acme-light0))
  (markdown-header-face-3                    (:foreground acme-light0))
  (markdown-header-face-4                    (:foreground acme-light0))
  (markdown-header-face-5                    (:foreground acme-light0))
  (markdown-header-face-6                    (:foreground acme-light0))

  ;; anzu-mode
  (anzu-mode-line                            (:foreground acme-bright_yellow :weight 'bold))
  (anzu-match-1                              (:background acme-bright_green))
  (anzu-match-2                              (:background acme-faded_yellow))
  (anzu-match-3                              (:background acme-aquamarine4))
  (anzu-replace-to                           (:foreground acme-bright_yellow))
  (anzu-replace-highlight                    (:inherit 'isearch))

  ;; Ace-jump-mode
  (ace-jump-face-background                  (:foreground acme-light4 :background acme-bg :inverse-video nil))
  (ace-jump-face-foreground                  (:foreground acme-bright_red :background acme-bg :inverse-video nil :box 1))

  ;; Ace-window
  (aw-background-face                        (:forground  acme-light1 :background acme-bg :inverse-video nil))
  (aw-leading-char-face                      (:foreground acme-bright_orange :background acme-bg :height 4.0 :box (:line-width 1 :color acme-bright_orange)))

  ;; show-paren
  (show-paren-match                          (:background acme-dark3 :weight 'bold))
  (show-paren-mismatch                       (:background acme-bright_red :foreground acme-dark3 :weight 'bold))

  ;; ivy
  (ivy-current-match                         (:foreground acme-white :weight 'bold :underline t))
  (ivy-minibuffer-match-face-1               (:foreground acme-neutral_orange))
  (ivy-minibuffer-match-face-2               (:foreground acme-neutral_yellow))
  (ivy-minibuffer-match-face-3               (:foreground acme-faded_orange))
  (ivy-minibuffer-match-face-4               (:foreground acme-faded_yellow))

  ;; MODE SUPPORT: dired+
  (diredp-file-name                          (:foreground acme-light2))
  (diredp-file-suffix                        (:foreground acme-light4))
  (diredp-compressed-file-suffix             (:foreground acme-faded_blue))
  (diredp-dir-name                           (:foreground acme-faded_blue))
  (diredp-dir-heading                        (:foreground acme-bright_blue))
  (diredp-symlink                            (:foreground acme-bright_orange))
  (diredp-date-time                          (:foreground acme-light3))
  (diredp-number                             (:foreground acme-faded_blue))
  (diredp-no-priv                            (:foreground acme-dark4))
  (diredp-other-priv                         (:foreground acme-dark2))
  (diredp-rare-priv                          (:foreground acme-dark4))
  (diredp-ignored-file-name                  (:foreground acme-dark4))

  (diredp-dir-priv                           (:foreground acme-faded_blue  :background acme-dark_blue))
  (diredp-exec-priv                          (:foreground acme-faded_blue  :background acme-dark_blue))
  (diredp-link-priv                          (:foreground acme-faded_aqua  :background acme-dark_aqua))
  (diredp-read-priv                          (:foreground acme-bright_red  :background acme-dark_red))
  (diredp-write-priv                         (:foreground acme-bright_aqua :background acme-dark_aqua)))

 (custom-theme-set-variables 'inverse-acme
                             `(ansi-color-names-vector
                               [,acme-dark1
                                ,acme-neutral_red
                                ,acme-neutral_green
                                ,acme-neutral_yellow
                                ,acme-neutral_blue
                                ,acme-neutral_purple
                                ,acme-neutral_aqua
                                ,acme-light1])))

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'inverse-acme)

;;; inverse-acme-theme.el ends here
