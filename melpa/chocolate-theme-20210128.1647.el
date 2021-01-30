;;; chocolate-theme.el --- A dark chocolaty theme -*- lexical-binding: t; -*-

;; Copyright (c) 2018-2019 Valeriy Savchenko (GNU/GPL Licence)

;; Authors: Valeriy Savchenko <sinmipt@gmail.com>
;; URL: http://github.com/SavchenkoValeriy/emacs-chocolate-theme
;; Package-Version: 20210128.1647
;; Package-Commit: ccc05f7ad96d3d1332727689bf6250443adc7ec0
;; Version: 0.2.0
;; Package-Requires: ((emacs "24.1") (autothemer "0.2"))

;;; Commentary:
;;  Poor doggies can't experience it because of two reasons

;;; Code:
(require 'autothemer)

(autothemer-deftheme
 chocolate "Poor doggies can't experience it because of two reasons"

 ((((class color) (min-colors #xFFFFFF))) ;; color column 1 GUI/24bit

  (chocolate-mono-1           "#BFAAAE")
  (chocolate-mono-2           "#968185")
  (chocolate-mono-3           "#705B5F")
  (chocolate-hue-1            "#56B5C2")
  (chocolate-hue-1-2          "#7CEFFF")
  (chocolate-hue-1-3          "#6ED6E5")
  (chocolate-hue-1-4          "#54BCCA")
  (chocolate-hue-1-5          "#45AFBD")
  (chocolate-hue-2            "#EAEAFE")
  (chocolate-hue-3            "#DC672C")
  (chocolate-hue-4            "#C7AE9D")
  (chocolate-hue-4-2          "#937F73")
  (chocolate-hue-5            "#DF6B75")
  (chocolate-hue-5-2          "#BE5046")
  (chocolate-hue-5-3          "#D2646E")
  (chocolate-hue-5-4          "#C55D67")
  (chocolate-hue-5-5          "#B85660")
  (chocolate-hue-5-6          "#AB5059")
  (chocolate-hue-6            "#D19965")
  (chocolate-hue-6-2          "#E4BF7A")
  (chocolate-hue-6-3          "#AA8768")
  (chocolate-hue-7            "#FFC15E")
  (chocolate-hue-7-2          "#FFC05B")
  (chocolate-hue-7-3          "#FBBD5A")
  (chocolate-hue-7-4          "#EDB254")
  (chocolate-hue-7-5          "#E0A84F")
  (chocolate-hue-8            "#C77497")
  (chocolate-hue-8-2          "#BB6D8E")
  (chocolate-hue-8-3          "#AF6685")
  (chocolate-hue-8-4          "#975873")
  (chocolate-hue-8-5          "#8B516A")
  (chocolate-hue-9            "#56E39F")
  (chocolate-hue-9-2          "#50D595")
  (chocolate-hue-9-3          "#4BC88C")
  (chocolate-hue-9-4          "#46BB83")
  (chocolate-hue-9-5          "#41AE7A")
  (chocolate-syntax-light     "#4B393E")
  (chocolate-syntax-bg-light  "#3E2F33")
  (chocolate-syntax-bg        "#33272A")
  (chocolate-syntax-bg-dark   "#261D1F")
  (chocolate-syntax-accent    "#F88425")
  (chocolate-syntax-renamed   "#329fff")
  (chocolate-syntax-added     "#43d089")
  (chocolate-syntax-modified  "#e0c184")
  (chocolate-syntax-removed   "#e05151")
  (chocolate-darker-green     "#292D29")
  (chocolate-dark-green       "#2A382F")
  (chocolate-darker-red       "#4B2729")
  (chocolate-dark-red         "#632E2F")
  (chocolate-darker-yellow    "#483B31")
  (chocolate-dark-yellow      "#594A3B"))

 ((default (:foreground chocolate-hue-4 :background chocolate-syntax-bg))
  (cursor (:background chocolate-hue-4))
  (link (:foreground chocolate-hue-1 :underline t))
  (link-visited (:foreground chocolate-hue-1 :underline nil))
  (mode-line (:foreground chocolate-hue-6 :background chocolate-syntax-light :box nil))
  (mode-line-inactive (:foreground chocolate-hue-6-3 :background chocolate-syntax-bg-light :box nil))
  (fringe (:background chocolate-syntax-bg))
  (linum (:foreground chocolate-hue-4-2))
  (region (:background chocolate-syntax-light :distant-foreground chocolate-hue-4))
  (secondary-selection (:background chocolate-syntax-light))
  (hl-line (:background chocolate-syntax-bg-light))

  ;; Built-in syntax
  (font-lock-builtin-face (:foreground chocolate-syntax-accent))
  (font-lock-constant-face (:foreground chocolate-hue-6))
  (font-lock-comment-face (:foreground chocolate-mono-3))
  (font-lock-function-name-face (:weight 'bold :foreground chocolate-hue-1))
  (font-lock-keyword-face (:foreground chocolate-hue-3))
  (font-lock-string-face (:foreground chocolate-hue-6-2))
  (font-lock-variable-name-face (:foreground chocolate-hue-5))
  (font-lock-type-face (:foreground chocolate-hue-1))
  (font-lock-warning-face (:foreground chocolate-hue-5-2 :bold t))

  ;; MODE SUPPORT: rainbow-delimiters
  (rainbow-delimiters-depth-1-face (:foreground chocolate-hue-1))
  (rainbow-delimiters-depth-2-face (:foreground chocolate-hue-2))
  (rainbow-delimiters-depth-3-face (:foreground chocolate-hue-3))
  (rainbow-delimiters-depth-4-face (:foreground chocolate-hue-4))
  (rainbow-delimiters-depth-5-face (:foreground chocolate-hue-5))
  (rainbow-delimiters-depth-6-face (:foreground chocolate-hue-6))
  (rainbow-delimiters-depth-7-face (:foreground chocolate-hue-1))
  (rainbow-delimiters-depth-8-face (:foreground chocolate-hue-2))
  (rainbow-delimiters-depth-9-face (:foreground chocolate-hue-3))
  (rainbow-delimiters-depth-10-face (:foreground chocolate-hue-4))
  (rainbow-delimiters-depth-11-face (:foreground chocolate-hue-5))
  (rainbow-delimiters-depth-12-face (:foreground chocolate-hue-6))
  (rainbow-delimiters-unmatched-face (:foreground chocolate-hue-4 nil))

  (cquery-sem-variable-face-0 (:foreground chocolate-hue-5))
  (cquery-sem-variable-face-1 (:foreground chocolate-hue-5-3))
  (cquery-sem-variable-face-2 (:foreground chocolate-hue-5-4))
  (cquery-sem-variable-face-3 (:foreground chocolate-hue-5-5))
  (cquery-sem-variable-face-4 (:foreground chocolate-hue-5-6))
  (cquery-sem-variable-face-5 (:foreground chocolate-hue-5))
  (cquery-sem-variable-face-6 (:foreground chocolate-hue-5-3))
  (cquery-sem-variable-face-7 (:foreground chocolate-hue-5-4))
  (cquery-sem-variable-face-8 (:foreground chocolate-hue-5-5))
  (cquery-sem-variable-face-9 (:foreground chocolate-hue-5-6))

  (cquery-sem-type-face-0 (:foreground chocolate-hue-1))
  (cquery-sem-type-face-1 (:foreground chocolate-hue-1-2))
  (cquery-sem-type-face-2 (:foreground chocolate-hue-1-3))
  (cquery-sem-type-face-3 (:foreground chocolate-hue-1-4))
  (cquery-sem-type-face-4 (:foreground chocolate-hue-1-5))
  (cquery-sem-type-face-5 (:foreground chocolate-hue-1))
  (cquery-sem-type-face-6 (:foreground chocolate-hue-1-2))
  (cquery-sem-type-face-7 (:foreground chocolate-hue-1-3))
  (cquery-sem-type-face-8 (:foreground chocolate-hue-1-4))
  (cquery-sem-type-face-9 (:foreground chocolate-hue-1-5))

  (cquery-sem-function-face-0 (:foreground chocolate-hue-7))
  (cquery-sem-function-face-1 (:foreground chocolate-hue-7-2))
  (cquery-sem-function-face-2 (:foreground chocolate-hue-7-3))
  (cquery-sem-function-face-3 (:foreground chocolate-hue-7-4))
  (cquery-sem-function-face-4 (:foreground chocolate-hue-7-5))
  (cquery-sem-function-face-5 (:foreground chocolate-hue-7))
  (cquery-sem-function-face-6 (:foreground chocolate-hue-7-2))
  (cquery-sem-function-face-7 (:foreground chocolate-hue-7-3))
  (cquery-sem-function-face-8 (:foreground chocolate-hue-7-4))
  (cquery-sem-function-face-9 (:foreground chocolate-hue-7-5))

  (cquery-sem-namespace-face-0 (:foreground chocolate-hue-8))
  (cquery-sem-namespace-face-1 (:foreground chocolate-hue-8-2))
  (cquery-sem-namespace-face-2 (:foreground chocolate-hue-8-3))
  (cquery-sem-namespace-face-3 (:foreground chocolate-hue-8-4))
  (cquery-sem-namespace-face-4 (:foreground chocolate-hue-8-5))
  (cquery-sem-namespace-face-5 (:foreground chocolate-hue-8))
  (cquery-sem-namespace-face-6 (:foreground chocolate-hue-8-2))
  (cquery-sem-namespace-face-7 (:foreground chocolate-hue-8-3))
  (cquery-sem-namespace-face-8 (:foreground chocolate-hue-8-4))
  (cquery-sem-namespace-face-9 (:foreground chocolate-hue-8-5))

  (cquery-sem-parameter-face-0 (:foreground chocolate-hue-9))
  (cquery-sem-parameter-face-1 (:foreground chocolate-hue-9-2))
  (cquery-sem-parameter-face-2 (:foreground chocolate-hue-9-3))
  (cquery-sem-parameter-face-3 (:foreground chocolate-hue-9-4))
  (cquery-sem-parameter-face-4 (:foreground chocolate-hue-9-5))
  (cquery-sem-parameter-face-5 (:foreground chocolate-hue-9))
  (cquery-sem-parameter-face-6 (:foreground chocolate-hue-9-2))
  (cquery-sem-parameter-face-7 (:foreground chocolate-hue-9-3))
  (cquery-sem-parameter-face-8 (:foreground chocolate-hue-9-4))
  (cquery-sem-parameter-face-9 (:foreground chocolate-hue-9-5))

  (lsp-face-highlight-textual (:background chocolate-syntax-light))

  ;; MODE SUPPORT: ivy
  (ivy-prompt-match (:inherit 'ivy-current-match))
  (ivy-highlight-face (:inherit 'highlight))
  (ivy-action (:inherit 'font-lock-builtin-face))
  (ivy-virtual (:foreground chocolate-mono-1))
  (ivy-remote (:foreground chocolate-syntax-renamed))
  (ivy-modified-buffer (:inherit 'default))
  (ivy-subdir (:inherit 'dired-directory))
  (ivy-match-required-face (:foreground chocolate-syntax-accent :inherit 'minibuffer-prompt))
  (ivy-confirm-face (:foreground chocolate-syntax-bg-dark :inherit 'minibuffer-prompt))
  (ivy-org (:foreground chocolate-hue-1-5))
  (ivy-minibuffer-match-face-4 (:foreground chocolate-hue-6-2 :inherit 'ivy-minibuffer-match-face-1))
  (ivy-minibuffer-match-face-3 (:foreground chocolate-syntax-added :inherit 'ivy-minibuffer-match-face-1))
  (ivy-minibuffer-match-face-2 (:foreground chocolate-hue-6 :inherit 'ivy-minibuffer-match-face-1))
  (ivy-minibuffer-match-face-1 (:weight 'bold :foreground chocolate-mono-3 :background chocolate-syntax-bg-dark))
  (ivy-minibuffer-match-highlight (:inherit 'highlight))
  (ivy-current-match (:weight 'bold :background chocolate-mono-3))
  (ivy-cursor (:foreground chocolate-hue-2 :background chocolate-syntax-bg-dark))

  ;; MODE SUPPORT: selectrum
  (selectrum-current-candidate (:background chocolate-syntax-light))

  ;; MODE support: js2
  (js2-function-param (:foreground chocolate-hue-1))
  (js2-external-variable (:weight 'bold :foreground chocolate-hue-7))
  (js2-function-call (:foreground chocolate-hue-6))

  ;; MODE support: display-line-numbers
  (line-number (:foreground chocolate-mono-3))
  (line-number-current-line (:foreground chocolate-mono-2 :weight 'bold))

  ;; MODE support: ediff
  (ediff-current-diff-A (:background chocolate-darker-red))
  (ediff-current-diff-Ancestor (:inherit 'ediff-current-diff-A))
  (ediff-current-diff-B (:background chocolate-darker-green))
  (ediff-current-diff-C (:background chocolate-darker-yellow))
  (ediff-even-diff-A (:background chocolate-syntax-bg-light))
  (ediff-even-diff-Ancestor (:inherit 'ediff-even-diff-A))
  (ediff-even-diff-B (:background chocolate-syntax-bg-light))
  (ediff-even-diff-C (:background chocolate-syntax-bg-light))
  (ediff-fine-diff-A (:background chocolate-dark-red))
  (ediff-fine-diff-Ancestor (:inherit 'ediff-fine-diff-A))
  (ediff-fine-diff-B (:background chocolate-dark-green))
  (ediff-fine-diff-C (:background chocolate-dark-yellow))
  (ediff-odd-diff-A (:inherut 'ediff-even-diff-A))
  (ediff-odd-diff-Ancestor (:inherit 'ediff-odd-diff-A))
  (ediff-odd-diff-B (:inherit 'ediff-even-diff-B))
  (ediff-odd-diff-C (:inherit 'ediff-even-diff-C))

  ;; MODE SUPPORT: diff-hl
  (diff-hl-change (:background chocolate-dark-yellow :foreground chocolate-syntax-modified))
  (diff-hl-insert (:background chocolate-dark-green :foreground chocolate-syntax-added))
  (diff-hl-delete (:background chocolate-dark-red :foreground chocolate-syntax-removed))

  ;; MODE SUPPORT: org
  (org-table (:foreground chocolate-hue-1-5))
  (org-date (:foreground chocolate-hue-1-3))
  (org-done (:foreground chocolate-hue-9))
  (org-agenda-done (:foreground chocolate-hue-9))
  (org-headline-done (:foreground chocolate-hue-5-3))
  (org-formula (:foreground chocolate-syntax-accent))
  (org-document-title (:foreground chocolate-hue-1))
  (org-document-info (:foreground chocolate-hue-1))
  (org-agenda-structure (:foreground chocolate-hue-1-5))
  (org-scheduled (:foreground chocolate-hue-9))
  (org-scheduled-today (:foreground chocolate-hue-9))
  (org-agenda-dimmed-todo-face (:foreground chocolate-mono-3))
  (org-scheduled-previously (:foreground chocolate-syntax-accent))
  (org-agenda-restriction-lock (:background chocolate-syntax-bg-dark))
  (org-time-grid (:foreground chocolate-hue-7))

  ;; MODE SUPPORT: popup
  (popup-face (:foreground chocolate-hue-4
                           :background chocolate-syntax-light))
  (popup-menu-mouse-face (:foreground chocolate-hue-4
                                      :background chocolate-hue-1))
  (popup-menu-selection-face (:foreground chocolate-hue-4
                                          :background chocolate-hue-1))
  (popup-tip-face (:foreground chocolate-hue-4
                               :background chocolate-syntax-bg-dark))
  ;; Use tip colors for the pos-tip color vars (see below)

  ;; MODE SUPPORT: powerline
  (powerline-active1 (:background chocolate-syntax-light :foreground chocolate-hue-4 :inherit 'mode-line))
  (powerline-active2 (:background chocolate-syntax-bg))
  (powerline-inactive1 (:background chocolate-syntax-bg-dark :inherit 'mode-line-inactive))
  (powerline-inactive2 (:background chocolate-syntax-bg-dark :inherit 'mode-line-inactive))
  (spaceline-highlight-face (:background chocolate-hue-6 :foreground chocolate-syntax-bg-dark))
  
    ;; MODE SUPPORT tab-bar-mode
  (tab-bar (:foreground chocolate-hue-4 :background chocolate-syntax-bg-dark))
  (tab-bar-tab (:foreground chocolate-hue-4 :background chocolate-syntax-bg-dark))

  ;; MODE SUPPORT tab-line-mode
  (tab-line (:foreground chocolate-hue-4 :background chocolate-syntax-bg-dark))
  (tab-bar-tab-inactive (:foreground chocolate-hue-4 :background chocolate-syntax-bg-dark))

  ;; MODE SUPPORT: centaur tabs
  (centaur-tabs-default (:background chocolate-syntax-bg-dark :foreground chocolate-hue-4))
  (centaur-tabs-selected (:background chocolate-syntax-bg :foreground chocolate-hue-4 :weight 'bold))
  (centaur-tabs-unselected (:background chocolate-syntax-bg-dark :foreground chocolate-mono-3 :weight 'light))
  (centaur-tabs-selected-modified (:background chocolate-syntax-bg :foreground chocolate-hue-6 :weight 'bold))
  (centaur-tabs-unselected-modified (:background chocolate-syntax-bg-dark :foreground chocolate-hue-6-3 :weight 'light))
  (centaur-tabs-active-bar-face (:background chocolate-hue-7))
  (centaur-tabs-modified-marker-selected (:inherit 'centaur-tabs-selected-modified :foreground chocolate-hue-6-2))
  (centaur-tabs-modified-marker-unselected (:inherit 'centaur-tabs-unselected-modified))

  ;; MODE SUPPORT: latex
  (font-latex-sectioning-5-face (:foreground chocolate-hue-6-2))
  (font-latex-italic-face (:foreground chocolate-hue-9-5 :inherit 'italic))
  (font-latex-bold-face (:foreground chocolate-hue-7 :inherit 'bold))

  (ffap
   (:inherit 'highlight))
  (epa-field-body
   (:slant 'italic :foreground chocolate-hue-1))
  (epa-field-name
   (:weight 'bold :foreground chocolate-hue-2))
  (epa-mark
   (:weight 'bold :foreground chocolate-syntax-accent))
  (epa-string
   (:foreground chocolate-hue-2))
  (epa-validity-disabled
   (:slant 'italic :inverse-video t))
  (epa-validity-low
   (:slant 'italic))
  (epa-validity-medium
   (:slant 'italic :foreground chocolate-hue-2))
  (epa-validity-high
   (:weight 'bold :foreground chocolate-hue-2))
  (helm-bookmark-addressbook
   (:foreground chocolate-syntax-removed))
  (helm-bookmark-directory
   (:inherit 'helm-ff-directory))
  (helm-bookmark-file-not-found
   (:foreground chocolate-mono-2))
  (helm-bookmark-file
   (:foreground chocolate-syntax-renamed))
  (helm-bookmark-man
   (:foreground chocolate-mono-3))
  (helm-bookmark-gnus
   (:foreground chocolate-hue-2))
  (helm-bookmark-w3m
   (:foreground chocolate-syntax-accent))
  (helm-bookmark-info
   (:foreground chocolate-syntax-added))
  (bookmark-menu-heading
   (:inherit 'font-lock-type-face))
  (bookmark-menu-bookmark
   (:weight 'bold))
  (eshell-prompt
   (:foreground chocolate-mono-1))
  (eshell-ls-clutter
   (:foreground chocolate-hue-5))
  (eshell-ls-product
   (:foreground chocolate-hue-6))
  (eshell-ls-backup
   (:foreground chocolate-hue-6-2))
  (eshell-ls-archive
   (:foreground chocolate-mono-1))
  (eshell-ls-missing
   (:foreground chocolate-hue-5))
  (eshell-ls-special
   (:foreground chocolate-mono-1))
  (eshell-ls-unreadable
   (:foreground chocolate-mono-3))
  (eshell-ls-readonly
   (:foreground chocolate-hue-6))
  (eshell-ls-executable
   (:foreground chocolate-syntax-added))
  (eshell-ls-symlink
   (:foreground chocolate-syntax-renamed))
  (eshell-ls-directory
   (:foreground chocolate-hue-1))
  (nlinum-current-line
   (:weight 'bold :foreground chocolate-hue-1))
  (aw-mode-line-face
   (:inherit 'mode-line-buffer-id))
  (aw-background-face
   (:foreground chocolate-mono-3))
  (aw-leading-char-face
   (:foreground chocolate-syntax-accent))
  (avy-goto-char-timer-face
   (:inherit 'highlight))
  (avy-background-face
   (:foreground chocolate-mono-3))
  (avy-lead-face
   (:foreground chocolate-syntax-bg-dark :background chocolate-hue-1))
  (avy-lead-face-2
   (:inherit 'avy-lead-face))
  (avy-lead-face-1
   (:inherit 'avy-lead-face))
  (avy-lead-face-0
   (:inherit 'avy-lead-face))
  (helm-M-x-key
   (:underline t :foreground chocolate-syntax-accent))
  (helm-lisp-completion-info
   (:foreground chocolate-syntax-accent))
  (helm-lisp-show-completion
   (:background chocolate-syntax-light))
  (whitespace-space-after-tab
   (:foreground chocolate-hue-5-2 :background chocolate-syntax-accent))
  (whitespace-empty
   (:background chocolate-syntax-bg))
  (whitespace-big-indent
   (:foreground chocolate-hue-5-2 :background chocolate-syntax-accent))
  (whitespace-indentation
   (:foreground chocolate-hue-5 :background chocolate-hue-6-2))
  (whitespace-space-before-tab
   (:foreground chocolate-hue-5-2 :background chocolate-syntax-accent))
  (whitespace-line
   (:weight 'bold :foreground chocolate-hue-5 :background chocolate-syntax-bg-dark))
  (whitespace-trailing
   (:inherit 'trailing-whitespace))
  (whitespace-newline
   (:foreground chocolate-syntax-light))
  (whitespace-tab
   (:foreground chocolate-syntax-light))
  (whitespace-hspace
   (:foreground chocolate-mono-1 :background chocolate-syntax-light))
  (whitespace-space
   (:foreground chocolate-syntax-light))
  (custom-group-subtitle
   (:weight 'bold))
  (custom-group-tag
   (:height 1.2 :weight 'bold :foreground chocolate-hue-2 :inherit 'variable-pitch))
  (custom-group-tag-1
   (:height 1.2 :weight 'bold :foreground chocolate-syntax-modified :inherit 'variable-pitch))
  (custom-face-tag
   (:inherit 'custom-variable-tag))
  (custom-visibility
   (:height 0.8 :inherit 'link))
  (custom-variable-button
   (:weight 'bold :underline t))
  (custom-variable-tag
   (:weight 'bold :foreground chocolate-hue-2))
  (custom-comment-tag
   (:foreground chocolate-mono-1))
  (custom-comment
   (:background chocolate-mono-3))
  (custom-link
   (:inherit 'link))
  (custom-state
   (:foreground chocolate-syntax-added))
  (custom-documentation nil)
  (custom-button-pressed-unraised
   (:foreground chocolate-hue-2 :inherit 'custom-button-unraised))
  (custom-button-pressed
   (:box
    (:line-width 2 :style 'pressed-button)
    :foreground chocolate-syntax-bg-dark :background chocolate-hue-2))
  (custom-button-unraised
   (:inherit 'underline))
  (custom-button-mouse
   (:box
    (:line-width 2 :style 'released-button)
    :foreground chocolate-syntax-bg-dark :background chocolate-hue-2))
  (custom-button
   (:box
    (:line-width 2 :style 'released-button)
    :foreground chocolate-syntax-bg-dark :background chocolate-hue-2))
  (custom-saved
   (:underline t))
  (custom-themed
   (:foreground chocolate-hue-2 :background chocolate-syntax-renamed))
  (custom-changed
   (:foreground chocolate-hue-2 :background chocolate-syntax-renamed))
  (custom-set
   (:foreground chocolate-syntax-renamed :background chocolate-hue-2))
  (custom-modified
   (:foreground chocolate-hue-2 :background chocolate-syntax-renamed))
  (custom-rogue
   (:foreground chocolate-syntax-modified :background chocolate-syntax-bg-dark))
  (custom-invalid
   (:foreground chocolate-syntax-accent :background chocolate-syntax-accent))
  (memrise-session-keybinding
   (:weight 'bold))
  (memrise-session-literal-translation
   (:inherit 'memrise-dashboard-description))
  (memrise-session-keyword
   (:weight 'bold))
  (memrise-session-thing
   (:height 270))
  (memrise-dashboard-description
   (:height 125 :inherit 'font-lock-comment-face))
  (memrise-dashboard-difficult
   (:foreground chocolate-syntax-accent))
  (memrise-dashboard-review
   (:foreground chocolate-syntax-renamed))
  (memrise-dashboard-all
   (:inherit 'memrise-dashboard-learned))
  (memrise-dashboard-learned
   (:foreground chocolate-mono-3))
  (memrise-dashboard-name
   (:inherit 'font-lock-keyword-face))
  (paradox-description-face-multiline
   (:inherit 'font-lock-doc-face))
  (paradox-description-face
   (:inherit 'default))
  (paradox-download-face
   (:inherit 'font-lock-keyword-face))
  (paradox-starred-face
   (:inherit 'font-lock-variable-name-face))
  (paradox-star-face
   (:inherit 'font-lock-string-face))
  (paradox-archive-face
   (:inherit 'paradox-comment-face))
  (paradox-homepage-button-face
   (:underline t :inherit 'font-lock-comment-face))
  (paradox-name-face
   (:inherit 'link))
  (paradox-mode-line-face
   (:weight 'normal :inherit
            ('font-lock-keyword-face 'mode-line-buffer-id)))
  (paradox-commit-tag-face
   (:box 1 :foreground chocolate-hue-3 :background chocolate-hue-2))
  (paradox-highlight-face
   (:weight 'bold :inherit 'font-lock-variable-name-face))
  (paradox-comment-face
   (:foreground chocolate-mono-2))
  (emms-metaplaylist-mode-current-face
   (:foreground chocolate-hue-3))
  (emms-metaplaylist-mode-face
   (:foreground chocolate-mono-1))
  (emms-browser-track-face
   (:height 1.0 :foreground chocolate-mono-1))
  (emms-browser-album-face
   (:height 1.1 :foreground chocolate-mono-1))
  (emms-browser-performer-face
   (:height 1.3 :foreground chocolate-mono-1))
  (emms-browser-composer-face
   (:height 1.3 :foreground chocolate-mono-1))
  (emms-browser-artist-face
   (:height 1.3 :foreground chocolate-mono-1))
  (emms-browser-year/genre-face
   (:height 1.5 :foreground chocolate-mono-1))
  (emms-stream-url-face
   (:foreground chocolate-mono-1))
  (emms-stream-name-face
   (:weight 'bold))
  (emms-playlist-selected-face
   (:foreground chocolate-hue-1))
  (emms-playlist-track-face
   (:foreground chocolate-mono-2))
  (writegood-duplicates-face
   (:underline
    (:style 'wave :color chocolate-hue-5)))
  (writegood-passive-voice-face
   (:underline
    (:style 'wave :color chocolate-syntax-renamed)))
  (writegood-weasels-face
   (:underline
    (:style 'wave :color chocolate-syntax-accent)))
  (haskell-quasi-quote-face
   (:inherit 'font-lock-string-face))
  (haskell-definition-face
   (:inherit 'font-lock-function-name-face))
  (flymake-warnline
   (:underline
    (:style 'wave :color chocolate-hue-6)
    :background chocolate-syntax-bg))
  (flymake-errline
   (:underline
    (:style 'wave :color chocolate-hue-5)
    :background chocolate-syntax-bg))
  (jedi:highlight-function-argument
   (:inherit 'bold))
  (epc:face-title
   (:weight 'bold :foreground chocolate-hue-5))
  (ctbl:face-continue-bar
   (:background chocolate-syntax-light))
  (ctbl:face-cell-select
   (:background chocolate-syntax-renamed))
  (ctbl:face-row-select
   (:background chocolate-syntax-bg-dark))
  (ido-incomplete-regexp
   (:inherit 'font-lock-warning-face))
  (ido-indicator
   (:foreground chocolate-hue-5 :background chocolate-syntax-bg))
  (ido-virtual
   (:foreground chocolate-mono-3))
  (ido-subdir
   (:foreground chocolate-mono-1))
  (ido-only-match
   (:foreground chocolate-syntax-added))
  (ido-first-match
   (:foreground chocolate-hue-6))
  (ac-selection-face
   (:inherit 'popup-menu-selection-face))
  (ac-candidate-mouse-face
   (:inherit 'popup-menu-mouse-face))
  (ac-candidate-face
   (:inherit 'popup-face))
  (ac-completion-face
   (:underline t :foreground chocolate-mono-1))
  (c-annotation-face
   (:inherit 'font-lock-constant-face))
  (company-template-field
   (:inherit 'match))
  (flycheck-error-list-highlight
   (:inherit 'highlight))
  (flycheck-error-list-checker-name
   (:inherit 'font-lock-function-name-face))
  (flycheck-error-list-id-with-explainer
   (:box
    (:style 'released-button)
    :inherit 'flycheck-error-list-id))
  (flycheck-error-list-id
   (:inherit 'font-lock-type-face))
  (flycheck-error-list-filename
   (:inherit 'font-lock-variable-name-face))
  (flycheck-error-list-column-number
   (:inherit 'font-lock-constant-face))
  (flycheck-error-list-line-number
   (:inherit 'font-lock-constant-face))
  (flycheck-error-list-info
   (:inherit 'success))
  (flycheck-error-list-warning
   (:inherit 'warning))
  (flycheck-error-list-error
   (:inherit 'error))
  (flycheck-fringe-info
   (:inherit 'success))
  (flycheck-fringe-warning
   (:inherit 'warning))
  (flycheck-fringe-error
   (:inherit 'error))
  (flycheck-info
   (:underline
    (:style 'wave :color chocolate-syntax-added)))
  (flycheck-warning
   (:underline
    (:style 'wave :color chocolate-hue-6-2)))
  (flycheck-error
   (:underline
    (:style 'wave :color chocolate-hue-5)))
  (term-color-white
   (:foreground chocolate-hue-2 :background chocolate-hue-2))
  (term-color-cyan
   (:foreground chocolate-syntax-renamed :background chocolate-syntax-renamed))
  (term-color-magenta
   (:foreground chocolate-mono-1 :background chocolate-mono-1))
  (term-color-blue
   (:foreground chocolate-hue-1 :background chocolate-hue-1))
  (term-color-yellow
   (:foreground chocolate-hue-6-2 :background chocolate-hue-6-2))
  (term-color-green
   (:foreground chocolate-syntax-added :background chocolate-syntax-added))
  (term-color-red
   (:foreground chocolate-hue-5 :background chocolate-hue-5))
  (term-color-black
   (:foreground chocolate-syntax-bg-dark :background chocolate-syntax-bg-dark))
  (term-underline
   (:underline t))
  (term-bold
   (:inherit 'bold))
  (term
   (:inherit 'default))
  (popup-menu-summary-face
   (:inherit 'popup-summary-face))
  (popup-menu-face
   (:inherit 'popup-face))
  (popup-isearch-match
   (:background chocolate-hue-1 :inherit 'default))
  (popup-scroll-bar-background-face
   (:background chocolate-mono-1))
  (popup-scroll-bar-foreground-face
   (:background chocolate-syntax-bg-dark))
  (popup-summary-face
   (:foreground chocolate-mono-3 :inherit 'popup-face))
  (helm-history-remote
   (:foreground chocolate-hue-5))
  (helm-history-deleted
   (:inherit 'helm-ff-invalid-symlink))
  (helm-ff-dirs
   (:inherit 'font-lock-function-name-face))
  (helm-ff-file
   (:foreground chocolate-mono-1))
  (helm-ff-invalid-symlink
   (:foreground chocolate-syntax-bg-dark :background chocolate-syntax-accent))
  (helm-ff-symlink
   (:inherit 'font-lock-comment-face))
  (helm-ff-dotted-symlink-directory
   (:foreground chocolate-syntax-accent :background chocolate-mono-3))
  (helm-ff-dotted-directory
   (:foreground chocolate-syntax-light))
  (helm-ff-directory
   (:foreground chocolate-hue-2))
  (helm-ff-executable
   (:foreground chocolate-hue-2 :inherit 'italic))
  (helm-ff-prefix
   (:foreground chocolate-hue-1))
  (helm-non-file-buffer
   (:inherit 'italic))
  (helm-buffer-archive
   (:foreground chocolate-syntax-accent))
  (helm-buffer-file
   (:inherit 'font-lock-builtin-face))
  (helm-buffer-directory
   (:foreground chocolate-syntax-bg-dark :background chocolate-hue-2))
  (helm-buffer-process
   (:foreground chocolate-hue-3))
  (helm-buffer-size
   (:foreground chocolate-hue-4))
  (helm-buffer-modified
   (:inherit 'font-lock-comment-face))
  (helm-buffer-not-saved
   (:foreground chocolate-hue-5))
  (helm-buffer-saved-out
   (:foreground chocolate-syntax-accent :background chocolate-syntax-bg-dark))
  (helm-etags-file
   (:underline t :foreground chocolate-hue-4-2))
  (helm-locate-finish
   (:foreground chocolate-syntax-added))
  (helm-grep-cmd-line
   (:inherit 'font-lock-type-face))
  (helm-grep-finish
   (:foreground chocolate-syntax-added))
  (helm-grep-lineno
   (:foreground chocolate-mono-3))
  (helm-grep-file
   (:foreground chocolate-mono-1))
  (helm-grep-match
   (:foreground chocolate-hue-1))
  (helm-resume-need-update
   (:background chocolate-syntax-accent))
  (helm-moccur-buffer
   (:underline t :foreground chocolate-hue-1))
  (helm-match-item
   (:inherit 'isearch))
  (helm-selection-line
   (:inherit 'highlight))
  (helm-helper
   (:inherit 'helm-header))
  (helm-header-line-left-margin
   (:foreground chocolate-syntax-bg-dark :background chocolate-syntax-accent))
  (helm-match
   (:underline t :foreground chocolate-hue-1))
  (helm-prefarg
   (:foreground chocolate-syntax-added))
  (helm-action
   (:underline t))
  (helm-separator
   (:foreground chocolate-syntax-accent))
  (helm-selection
   (:background chocolate-mono-3 :inherit 'bold))
  (helm-candidate-number-suspended
   (:inverse-video t :inherit 'helm-candidate-number))
  (helm-candidate-number
   (:foreground chocolate-syntax-bg-dark :background chocolate-syntax-accent))
  (helm-header
   (:inherit 'header-line))
  (helm-visible-mark
   (:inherit
    ('bold 'highlight)))
  (helm-source-header
   (:foreground chocolate-mono-3 :background chocolate-syntax-bg))
  (compilation-column-number
   (:inherit 'font-lock-doc-face))
  (compilation-line-number
   (:inherit 'font-lock-keyword-face))
  (compilation-mode-line-exit
   (:weight 'bold :foreground chocolate-syntax-bg-dark :inherit 'compilation-info))
  (compilation-mode-line-run
   (:inherit 'compilation-warning))
  (compilation-mode-line-fail
   (:weight 'bold :foreground chocolate-syntax-accent :inherit 'compilation-error))
  (compilation-info
   (:inherit 'success))
  (compilation-warning
   (:inherit 'warning))
  (compilation-error
   (:inherit 'error))
  (rainbow-delimiters-mismatched-face
   (:inherit 'rainbow-delimiters-unmatched-face))
  (rainbow-delimiters-base-face nil)
  (yas--field-debug-face nil)
  (yas-field-highlight-face
   (:inherit 'match))
  (magithub-edit-title
   (:inherit 'markdown-header-face-1))
  (magithub-deleted-thing
   (:background chocolate-syntax-bg-dark :inherit 'magit-section-highlight))
  (magithub-notification-reason
   (:inherit 'magit-dimmed))
  (magithub-label
   (:box 1))
  (magithub-ci-unknown
   (:inherit 'magit-signature-untrusted))
  (magithub-ci-failure
   (:inherit 'error))
  (magithub-ci-success
   (:inherit 'success))
  (magithub-ci-pending
   (:inherit 'magit-signature-untrusted))
  (magithub-ci-error
   (:inherit 'magit-signature-untrusted))
  (magithub-ci-no-status
   (:inherit 'magit-dimmed))
  (magithub-user
   (:inherit 'magit-log-author))
  (magithub-issue-title-with-note
   (:inherit
    ('git-commit-summary)))
  (magithub-issue-title-edit
   (:inherit
    ('git-commit-summary)))
  (magithub-issue-number
   (:inherit 'magit-dimmed))
  (magithub-issue-title nil)
  (magithub-repo
   (:inherit 'magit-branch-remote))
  (widget-button-pressed
   (:foreground chocolate-syntax-accent))
  (widget-inactive
   (:inherit 'shadow))
  (widget-single-line-field
   (:background chocolate-mono-3))
  (widget-field
   (:background chocolate-mono-3))
  (widget-button
   (:weight 'bold))
  (widget-documentation
   (:foreground chocolate-syntax-added))
  (markdown-header-face-6
   (:inherit 'markdown-header-face))
  (markdown-header-face-5
   (:inherit 'markdown-header-face))
  (markdown-header-face-4
   (:inherit 'markdown-header-face))
  (markdown-header-face-3
   (:inherit 'markdown-header-face))
  (markdown-header-face-2
   (:inherit 'markdown-header-face))
  (markdown-header-face-1
   (:inherit 'markdown-header-face))
  (markdown-header-face
   (:foreground chocolate-hue-5 :inherit 'bold))
  (markdown-html-entity-face
   (:inherit 'font-lock-variable-name-face))
  (markdown-html-attr-value-face
   (:inherit 'font-lock-string-face))
  (markdown-html-attr-name-face
   (:inherit 'font-lock-variable-name-face))
  (markdown-html-tag-delimiter-face
   (:inherit 'markdown-markup-face))
  (markdown-html-tag-name-face
   (:inherit 'font-lock-type-face))
  (markdown-hr-face
   (:inherit 'markdown-markup-face))
  (markdown-highlight-face
   (:inherit 'highlight))
  (markdown-gfm-checkbox-face
   (:inherit 'font-lock-builtin-face))
  (markdown-metadata-value-face
   (:inherit 'font-lock-string-face))
  (markdown-metadata-key-face
   (:foreground chocolate-hue-5))
  (markdown-math-face
   (:inherit 'font-lock-string-face))
  (markdown-comment-face
   (:inherit 'font-lock-comment-face))
  (markdown-line-break-face
   (:underline t :inherit 'font-lock-constant-face))
  (markdown-link-title-face
   (:inherit 'font-lock-comment-face))
  (markdown-plain-url-face
   (:inherit 'markdown-link-face))
  (markdown-url-face
   (:weight 'normal :foreground chocolate-mono-1))
  (markdown-footnote-text-face
   (:inherit 'font-lock-comment-face))
  (markdown-footnote-marker-face
   (:inherit 'markdown-markup-face))
  (markdown-reference-face
   (:inherit 'markdown-markup-face))
  (markdown-missing-link-face
   (:inherit 'font-lock-warning-face))
  (markdown-link-face
   (:foreground chocolate-hue-1 :inherit 'bold))
  (markdown-language-info-face
   (:inherit 'font-lock-string-face))
  (markdown-language-keyword-face
   (:inherit 'font-lock-type-face))
  (markdown-table-face
   (:inherit
    ('markdown-code-face)))
  (markdown-pre-face
   (:foreground chocolate-syntax-added))
  (markdown-inline-code-face
   (:inherit
    ('markdown-code-face 'markdown-pre-face)))
  (markdown-code-face
   (:background chocolate-syntax-bg))
  (markdown-blockquote-face
   (:foreground chocolate-mono-2 :inherit 'italic))
  (markdown-list-face
   (:foreground chocolate-hue-5))
  (markdown-header-delimiter-face
   (:inherit 'markdown-header-face))
  (markdown-header-rule-face
   (:inherit 'markdown-markup-face))
  (markdown-markup-face
   (:foreground chocolate-mono-1))
  (markdown-strike-through-face
   (:strike-through t))
  (markdown-bold-face
   (:foreground chocolate-hue-6 :inherit 'bold))
  (markdown-italic-face
   (:foreground chocolate-mono-1 :inherit 'italic))
  (outline-8
   (:inherit 'font-lock-string-face))
  (outline-7
   (:inherit 'font-lock-builtin-face))
  (outline-6
   (:inherit 'font-lock-constant-face))
  (outline-5
   (:inherit 'font-lock-type-face))
  (outline-4
   (:inherit 'font-lock-comment-face))
  (outline-3
   (:inherit 'font-lock-keyword-face))
  (outline-2
   (:inherit 'font-lock-variable-name-face))
  (outline-1
   (:inherit 'font-lock-function-name-face))
  (magit-blame-date
   (:foreground chocolate-hue-5))
  (magit-blame-name
   (:inherit 'magit-blame-heading))
  (magit-blame-hash
   (:inherit 'magit-blame-heading))
  (magit-blame-summary
   (:inherit 'magit-blame-heading))
  (magit-blame-heading
   (:foreground chocolate-hue-6 :background chocolate-syntax-bg))
  (magit-bisect-bad
   (:foreground chocolate-hue-5))
  (magit-bisect-skip
   (:foreground chocolate-hue-6))
  (magit-bisect-good
   (:foreground chocolate-syntax-added))
  (magit-sequence-exec
   (:inherit 'magit-hash))
  (magit-sequence-onto
   (:inherit 'magit-sequence-done))
  (magit-sequence-done
   (:inherit 'magit-hash))
  (magit-sequence-drop
   (:foreground chocolate-hue-5))
  (magit-sequence-head
   (:foreground chocolate-hue-1))
  (magit-sequence-part
   (:foreground chocolate-hue-6))
  (magit-sequence-stop
   (:foreground chocolate-syntax-added))
  (magit-sequence-pick
   (:inherit 'default))
  (magit-filename
   (:foreground chocolate-mono-1))
  (magit-cherry-equivalent
   (:foreground chocolate-mono-1))
  (magit-cherry-unmatched
   (:foreground chocolate-syntax-renamed))
  (magit-signature-error
   (:inherit 'error))
  (magit-signature-revoked
   (:foreground chocolate-mono-1))
  (magit-signature-expired-key
   (:inherit 'magit-signature-expired))
  (magit-signature-expired
   (:foreground chocolate-hue-6))
  (magit-signature-untrusted
   (:foreground chocolate-syntax-renamed))
  (magit-signature-bad
   (:inherit 'error))
  (magit-signature-good
   (:inherit 'success))
  (magit-keyword
   (:inherit 'font-lock-string-face))
  (magit-refname-wip
   (:inherit 'magit-refname))
  (magit-refname-stash
   (:inherit 'magit-refname))
  (magit-refname
   (:foreground chocolate-mono-3))
  (magit-head
   (:inherit 'magit-branch-local))
  (magit-branch-current
   (:foreground chocolate-hue-1))
  (magit-branch-local
   (:foreground chocolate-syntax-renamed))
  (magit-branch-remote-head
   (:box 1 :inherit 'magit-branch-remote))
  (magit-branch-remote
   (:foreground chocolate-syntax-added))
  (magit-tag
   (:foreground chocolate-hue-6-2))
  (magit-hash
   (:foreground chocolate-mono-3))
  (magit-dimmed
   (:foreground chocolate-mono-3))
  (magit-header-line-key
   (:inherit 'magit-popup-key))
  (magit-header-line
   (:weight 'bold :box
            (:line-width 3 :color chocolate-mono-3)
            :foreground chocolate-hue-2 :background chocolate-mono-3))
  (magit-reflog-other
   (:foreground chocolate-syntax-renamed))
  (magit-reflog-remote
   (:foreground chocolate-syntax-renamed))
  (magit-reflog-cherry-pick
   (:foreground chocolate-syntax-added))
  (magit-reflog-rebase
   (:foreground chocolate-mono-1))
  (magit-reflog-reset
   (:inherit 'error))
  (magit-reflog-checkout
   (:foreground chocolate-hue-1))
  (magit-reflog-merge
   (:foreground chocolate-syntax-added))
  (magit-reflog-amend
   (:foreground chocolate-mono-1))
  (magit-reflog-commit
   (:foreground chocolate-syntax-added))
  (magit-header-line-log-select
   (:inherit 'bold))
  (magit-log-date
   (:foreground chocolate-hue-1))
  (magit-log-author
   (:foreground chocolate-hue-6))
  (magit-log-graph
   (:foreground chocolate-mono-3))
  (magit-diffstat-removed
   (:foreground chocolate-syntax-removed))
  (magit-diffstat-added
   (:foreground chocolate-syntax-added))
  (magit-diff-whitespace-warning
   (:inherit 'trailing-whitespace))
  (magit-diff-context-highlight
   (:foreground chocolate-mono-1 :background chocolate-syntax-bg))
  (magit-diff-their-highlight
   (:inherit 'magit-diff-added-highlight))
  (magit-diff-base-highlight
   (:weight 'bold :foreground chocolate-hue-6 :background chocolate-syntax-light))
  (magit-diff-our-highlight
   (:inherit 'magit-diff-removed-highlight))
  (magit-diff-removed-highlight
   (:weight 'bold :foreground chocolate-syntax-removed :background chocolate-syntax-bg))
  (magit-diff-added-highlight
   (:weight 'bold :foreground chocolate-syntax-added :background chocolate-syntax-light))
  (magit-diff-context
   (:foreground chocolate-mono-3 :background chocolate-syntax-bg))
  (magit-diff-their
   (:inherit 'magit-diff-added))
  (magit-diff-base
   (:foreground chocolate-hue-5-2 :background chocolate-syntax-bg))
  (magit-diff-our
   (:inherit 'magit-diff-removed))
  (magit-diff-removed
   (:foreground chocolate-hue-5-2 :background chocolate-syntax-bg))
  (magit-diff-added
   (:foreground chocolate-hue-9-5 :background chocolate-syntax-bg))
  (magit-diff-conflict-heading
   (:inherit 'magit-diff-hunk-heading))
  (magit-diff-lines-boundary
   (:inherit 'magit-diff-lines-heading))
  (magit-diff-lines-heading
   (:foreground chocolate-hue-6-2 :background chocolate-hue-5))
  (magit-diff-hunk-region
   (:inherit 'bold))
  (magit-diff-hunk-heading-selection
   (:foreground chocolate-hue-6 :inherit 'magit-diff-hunk-heading-highlight))
  (magit-diff-hunk-heading-highlight
   (:weight 'bold :foreground chocolate-syntax-bg :background chocolate-mono-1))
  (magit-diff-hunk-heading
   (:foreground chocolate-syntax-bg :background chocolate-syntax-light))
  (magit-diff-file-heading-selection
   (:weight 'bold :foreground chocolate-mono-1 :background chocolate-mono-3))
  (magit-diff-file-heading-highlight
   (:inherit
    ('magit-section-highlight)))
  (magit-diff-file-heading
   (:weight 'bold :foreground chocolate-mono-1))
  (smerge-refined-added
   (:background chocolate-syntax-bg-dark :inherit 'smerge-refined-change))
  (smerge-refined-removed
   (:background chocolate-hue-5-2 :inherit 'smerge-refined-change))
  (smerge-refined-changed nil)
  (smerge-markers
   (:background chocolate-syntax-light))
  (smerge-base
   (:background chocolate-hue-4-2))
  (smerge-other
   (:background chocolate-syntax-bg))
  (smerge-mine
   (:background chocolate-syntax-light))
  (diff-refine-added
   (:inverse-video t :inherit 'diff-added))
  (diff-refine-removed
   (:inverse-video t :inherit 'diff-removed))
  (diff-refine-changed
   (:inverse-video t :inherit 'diff-changed))
  (diff-nonexistent
   (:inherit 'diff-file-header))
  (diff-context
   (:foreground chocolate-hue-2))
  (diff-function
   (:inherit 'diff-header))
  (diff-indicator-changed
   (:inherit 'diff-changed))
  (diff-indicator-added
   (:inherit 'diff-added))
  (diff-indicator-removed
   (:inherit 'diff-removed))
  (diff-changed
   (:foreground chocolate-mono-1))
  (diff-added
   (:foreground chocolate-syntax-added :inherit 'hl-line))
  (diff-removed
   (:foreground chocolate-hue-5 :background chocolate-syntax-bg))
  (diff-hunk-header
   (:foreground chocolate-mono-1))
  (diff-index
   (:inherit 'diff-file-header))
  (diff-file-header
   (:foreground chocolate-hue-1))
  (diff-header
   (:foreground chocolate-syntax-renamed))
  (magit-mode-line-process-error
   (:inherit 'error))
  (magit-mode-line-process
   (:inherit 'mode-line-emphasis))
  (magit-process-ng
   (:inherit 'error))
  (magit-process-ok
   (:inherit 'success))
  (git-commit-comment-action
   (:inherit 'bold))
  (git-commit-comment-file
   (:inherit 'git-commit-pseudo-header))
  (git-commit-comment-heading
   (:inherit 'git-commit-known-pseudo-header))
  (git-commit-comment-detached
   (:inherit 'git-commit-comment-branch-local))
  (git-commit-comment-branch-remote
   (:inherit 'font-lock-variable-name-face))
  (git-commit-comment-branch-local
   (:inherit 'font-lock-variable-name-face))
  (git-commit-known-pseudo-header
   (:inherit 'font-lock-keyword-face))
  (git-commit-pseudo-header
   (:inherit 'font-lock-string-face))
  (git-commit-note
   (:inherit 'font-lock-string-face))
  (git-commit-nonempty-second-line
   (:inherit 'font-lock-warning-face))
  (git-commit-overlong-summary
   (:inherit 'font-lock-warning-face))
  (git-commit-summary
   (:inherit 'font-lock-type-face))
  (magit-section-heading-selection
   (:weight 'bold :foreground chocolate-hue-6))
  (magit-section-secondary-heading
   (:weight 'bold :foreground chocolate-mono-1))
  (magit-section-heading
   (:weight 'bold :foreground chocolate-hue-1))
  (magit-section-highlight
   (:background chocolate-syntax-bg-light))
  (magit-popup-option-value
   (:inherit 'font-lock-string-face))
  (magit-popup-disabled-argument
   (:inherit 'shadow))
  (magit-popup-argument
   (:inherit 'font-lock-warning-face))
  (magit-popup-key
   (:inherit 'font-lock-builtin-face))
  (magit-popup-heading
   (:inherit 'font-lock-keyword-face))
  (log-edit-unknown-header
   (:inherit 'font-lock-comment-face))
  (log-edit-header
   (:inherit 'font-lock-keyword-face))
  (log-edit-summary
   (:inherit 'font-lock-function-name-face))
  (message-mml
   (:foreground chocolate-syntax-added))
  (message-cited-text
   (:foreground chocolate-mono-1))
  (message-separator
   (:foreground chocolate-hue-2))
  (message-header-xheader
   (:foreground chocolate-syntax-renamed))
  (message-header-name
   (:foreground chocolate-syntax-added))
  (message-header-other
   (:foreground chocolate-hue-5))
  (message-header-newsgroups
   (:weight 'bold :slant 'italic :foreground chocolate-syntax-accent))
  (message-header-subject
   (:foreground chocolate-hue-6))
  (message-header-cc
   (:weight 'bold :foreground chocolate-syntax-added))
  (message-header-to
   (:weight 'bold :foreground chocolate-hue-6-2))
  (dired-ignored
   (:foreground chocolate-mono-3))
  (dired-symlink
   (:inherit 'font-lock-keyword-face))
  (dired-directory
   (:foreground chocolate-mono-1))
  (dired-perm-write
   (:inherit 'font-lock-comment-delimiter-face))
  (dired-warning
   (:inherit 'font-lock-warning-face))
  (dired-flagged
   (:inherit 'error))
  (dired-marked
   (:inherit 'warning))
  (dired-mark
   (:inherit 'font-lock-constant-face))
  (dired-header
   (:inherit 'font-lock-type-face))
  (mm-command-output
   (:foreground chocolate-syntax-bg-dark))
  (change-log-acknowledgment
   (:inherit 'font-lock-comment-face))
  (change-log-function
   (:inherit 'font-lock-variable-name-face))
  (change-log-conditionals
   (:inherit 'font-lock-variable-name-face))
  (change-log-list
   (:inherit 'font-lock-keyword-face))
  (change-log-file
   (:inherit 'font-lock-function-name-face))
  (change-log-email
   (:inherit 'font-lock-variable-name-face))
  (change-log-name
   (:inherit 'font-lock-constant-face))
  (change-log-date
   (:inherit 'font-lock-string-face))
  (comint-highlight-prompt
   (:inherit 'minibuffer-prompt))
  (comint-highlight-input
   (:weight 'bold))
  (company-echo-common
   (:foreground chocolate-hue-3))
  (company-echo nil)
  (company-preview-search
   (:inherit 'company-tooltip-search))
  (company-preview-common
   (:foreground chocolate-mono-1 :background chocolate-syntax-bg))
  (company-preview
   (:foreground chocolate-hue-1))
  (company-scrollbar-bg
   (:inherit 'tooltip))
  (company-scrollbar-fg
   (:background chocolate-hue-1))
  (company-tooltip-annotation-selection
   (:inherit 'company-tooltip-annotation))
  (company-tooltip-annotation
   (:foreground chocolate-mono-1))
  (company-tooltip-common-selection
   (:inherit 'company-tooltip-common))
  (company-tooltip-common
   (:foreground chocolate-hue-1))
  (company-tooltip-mouse
   (:foreground chocolate-syntax-bg :background chocolate-mono-1))
  (company-tooltip-search-selection
   (:inherit 'highlight))
  (company-tooltip-search
   (:foreground chocolate-syntax-bg :background chocolate-hue-1))
  (company-tooltip-selection
   (:background chocolate-mono-3))
  (company-tooltip
   (:inherit 'tooltip))
  (hydra-face-teal
   (:weight 'bold :foreground chocolate-hue-1))
  (hydra-face-pink
   (:weight 'bold :foreground chocolate-mono-1))
  (hydra-face-amaranth
   (:weight 'bold :foreground chocolate-mono-1))
  (hydra-face-blue
   (:weight 'bold :foreground chocolate-hue-1))
  (hydra-face-red
   (:weight 'bold :foreground chocolate-hue-5))
  (lv-separator
   (:background chocolate-syntax-light))
  (origami-fold-replacement-face
   (:inherit
    ('quote 'font-lock-comment-face)))
  (origami-fold-fringe-face nil)
  (origami-fold-header-face
   (:box
    (:line-width 1 :color chocolate-hue-1)
    :background chocolate-hue-1))
  (mc/region-face
   (:inherit 'region))
  (mc/cursor-bar-face
   (:height 1 :background chocolate-hue-1))
  (mc/cursor-face
   (:inherit 'cursor))
  (rectangle-preview
   (:inherit 'region))
  (highlight-leading-spaces
   (:inherit 'font-lock-comment-face))
  (spaceline-all-the-icons-sunset-face
   (:foreground chocolate-syntax-accent :inherit 'powerline-active2))
  (spaceline-all-the-icons-sunrise-face
   (:foreground chocolate-hue-6-2 :inherit 'powerline-active2))
  (spaceline-all-the-icons-info-face
   (:foreground chocolate-syntax-renamed))
  (spaceline-python-venv
   (:foreground chocolate-hue-2))
  (spaceline-flycheck-info
   (:foreground chocolate-hue-2))
  (spaceline-flycheck-warning
   (:foreground chocolate-syntax-modified))
  (spaceline-flycheck-error
   (:foreground chocolate-hue-5))
  (spaceline-read-only
   (:foreground chocolate-syntax-light :background chocolate-mono-1 :inherit
                ('quote 'mode-line)))
  (spaceline-modified
   (:foreground chocolate-syntax-light :background chocolate-hue-1 :inherit
                ('quote 'mode-line)))
  (spaceline-unmodified
   (:foreground chocolate-syntax-light :background chocolate-syntax-accent :inherit
                ('quote 'mode-line)))
  (spaceline-evil-motion
   (:foreground chocolate-syntax-light :background chocolate-mono-1 :inherit
                ('quote 'mode-line)))
  (spaceline-evil-visual
   (:foreground chocolate-syntax-light :background chocolate-mono-1 :inherit
                ('quote 'mode-line)))
  (spaceline-evil-replace
   (:foreground chocolate-syntax-light :background chocolate-hue-3 :inherit
                ('quote 'mode-line)))
  (spaceline-evil-emacs
   (:foreground chocolate-syntax-light :background chocolate-hue-1 :inherit
                ('quote 'mode-line)))
  (spaceline-evil-insert
   (:foreground chocolate-syntax-light :background chocolate-syntax-added :inherit
                ('quote 'mode-line)))
  (spaceline-evil-normal
   (:foreground chocolate-syntax-light :background chocolate-syntax-accent :inherit
                ('quote 'mode-line)))
  (mode-line-buffer-id-inactive
   (:inherit 'mode-line-buffer-id))
  (powerline-inactive0
   (:inherit 'mode-line-inactive))
  (powerline-active0
   (:inherit 'mode-line))
  (doom-modeline-error
   (:foreground chocolate-syntax-bg-dark :background chocolate-hue-5-2))
  (all-the-icons-dsilver
   (:foreground chocolate-mono-2))
  (all-the-icons-lsilver
   (:foreground chocolate-mono-1))
  (all-the-icons-silver
   (:foreground chocolate-mono-3))
  (all-the-icons-dpink
   (:foreground chocolate-mono-2))
  (all-the-icons-lpink
   (:foreground chocolate-syntax-modified))
  (all-the-icons-pink
   (:foreground chocolate-mono-1))
  (all-the-icons-dcyan
   (:foreground chocolate-mono-3))
  (all-the-icons-lcyan
   (:foreground chocolate-hue-2))
  (all-the-icons-cyan-alt
   (:foreground chocolate-hue-1))
  (all-the-icons-cyan
   (:foreground chocolate-hue-1))
  (all-the-icons-dorange
   (:foreground chocolate-hue-5-2))
  (all-the-icons-lorange
   (:foreground chocolate-syntax-accent))
  (all-the-icons-orange
   (:foreground chocolate-hue-3))
  (all-the-icons-dpurple
   (:foreground chocolate-mono-3))
  (all-the-icons-lpurple
   (:foreground chocolate-mono-1))
  (all-the-icons-purple
   (:foreground chocolate-mono-2))
  (all-the-icons-dmaroon
   (:foreground chocolate-mono-3))
  (all-the-icons-lmaroon
   (:foreground chocolate-hue-6))
  (all-the-icons-maroon
   (:foreground chocolate-hue-5-2))
  (all-the-icons-dblue
   (:foreground chocolate-mono-3))
  (all-the-icons-lblue
   (:foreground chocolate-hue-2))
  (all-the-icons-blue-alt
   (:foreground chocolate-hue-1))
  (all-the-icons-blue
   (:foreground chocolate-hue-1))
  (all-the-icons-dyellow
   (:foreground chocolate-hue-6-3))
  (all-the-icons-lyellow
   (:foreground chocolate-hue-6-2))
  (all-the-icons-yellow
   (:foreground chocolate-hue-6-2))
  (all-the-icons-dgreen
   (:foreground chocolate-mono-3))
  (all-the-icons-lgreen
   (:foreground chocolate-hue-6-2))
  (all-the-icons-green
   (:foreground chocolate-hue-4-2))
  (all-the-icons-red-alt
   (:foreground chocolate-hue-5-2))
  (all-the-icons-dred
   (:foreground chocolate-syntax-light))
  (all-the-icons-lred
   (:foreground chocolate-syntax-removed))
  (all-the-icons-red
   (:foreground chocolate-hue-5-2))
  (w3m-haddock-heading-face
   (:inherit 'highlight))

  ;; MODE SUPPORT: haskell
  (haskell-hole-face
   (:underline
    (:style 'wave :color chocolate-hue-1)))
  (haskell-warning-face
   (:underline
    (:style 'wave :color chocolate-syntax-accent)))
  (haskell-error-face
   (:underline
    (:style 'wave :color chocolate-hue-3)))
  (haskell-interactive-face-garbage
   (:inherit 'font-lock-string-face))
  (haskell-interactive-face-result
   (:inherit 'font-lock-string-face))
  (haskell-interactive-face-compile-warning
   (:inherit 'compilation-warning))
  (haskell-interactive-face-compile-error
   (:inherit 'compilation-error))
  (haskell-interactive-face-prompt2
   (:inherit 'font-lock-keyword-face))
  (haskell-interactive-face-prompt
   (:inherit 'font-lock-function-name-face))
  (haskell-literate-comment-face
   (:inherit 'font-lock-doc-face))
  (haskell-liquid-haskell-annotation-face
   (:inherit 'haskell-pragma-face))
  (haskell-pragma-face
   (:inherit 'font-lock-preprocessor-face))
  (haskell-operator-face
   (:inherit 'font-lock-variable-name-face))
  (haskell-type-face (:foreground chocolate-hue-6))
  (haskell-constructor-face (:foreground chocolate-hue-6-2))
  (haskell-keyword-face
   (:inherit 'font-lock-keyword-face))
  (haskell-debug-muted-face
   (:foreground chocolate-mono-2))
  (haskell-debug-heading-face
   (:inherit
    ('quote 'font-lock-keyword-face)))
  (haskell-debug-keybinding-face
   (:weight 'bold :inherit
            ('quote 'font-lock-type-face)))
  (haskell-debug-newline-face
   (:weight 'bold :background chocolate-hue-2))
  (haskell-debug-trace-number-face
   (:weight 'bold :background chocolate-hue-2))
  (haskell-debug-warning-face
   (:inherit
    ('quote 'compilation-warning)))
  (Info-quoted
   (:inherit 'fixed-pitch-serif))
  (info-index-match
   (:inherit 'match))
  (info-header-node
   (:inherit 'info-node))
  (info-header-xref
   (:inherit 'info-xref))
  (info-xref-visited
   (:inherit
    ('link-visited 'info-xref)))
  (info-xref
   (:inherit 'link))
  (info-menu-star
   (:foreground chocolate-syntax-accent))
  (info-menu-header
   (:weight 'bold :inherit 'variable-pitch))
  (info-title-4
   (:weight 'bold :inherit 'variable-pitch))
  (info-title-3
   (:height 1.2 :inherit 'info-title-4))
  (info-title-2
   (:height 1.2 :inherit 'info-title-3))
  (info-title-1
   (:height 1.2 :inherit 'info-title-2))
  (info-node
   (:weight 'bold :slant 'italic :foreground chocolate-hue-2))
  (package-status-avail-obso
   (:inherit 'package-status-incompat))
  (package-status-incompat
   (:inherit 'font-lock-comment-face))
  (package-status-unsigned
   (:inherit 'font-lock-warning-face))
  (package-status-dependency
   (:inherit 'package-status-installed))
  (package-status-installed
   (:inherit 'font-lock-comment-face))
  (package-status-disabled
   (:inherit 'font-lock-warning-face))
  (package-status-held
   (:inherit 'font-lock-constant-face))
  (package-status-new
   (:inherit
    ('bold 'package-status-available)))
  (package-status-available
   (:inherit 'default))
  (package-status-external
   (:inherit 'package-status-built-in))
  (package-status-built-in
   (:inherit 'font-lock-builtin-face))
  (package-description
   (:inherit 'default))
  (package-name
   (:inherit 'link))
  (package-help-section-name
   (:inherit
    ('bold 'font-lock-function-name-face)))
  (tooltip
   (:foreground chocolate-mono-1 :background chocolate-syntax-bg-light))
  (eldoc-highlight-function-argument
   (:inherit 'bold))
  (vc-edited-state
   (:inherit 'vc-state-base))
  (vc-missing-state
   (:inherit 'vc-state-base))
  (vc-removed-state
   (:inherit 'vc-state-base))
  (vc-conflict-state
   (:inherit 'vc-state-base))
  (vc-locally-added-state
   (:inherit 'vc-state-base))
  (vc-locked-state
   (:inherit 'vc-state-base))
  (vc-needs-update-state
   (:inherit 'vc-state-base))
  (vc-up-to-date-state
   (:inherit 'vc-state-base))
  (vc-state-base nil)
  (ns-working-text-face
   (:underline t))
  (buffer-menu-buffer
   (:weight 'bold))
  (match
   (:weight 'bold :foreground chocolate-syntax-added :background chocolate-syntax-bg-dark))
  (query-replace
   (:inherit 'isearch))
  (file-name-shadow
   (:inherit 'shadow))
  (lazy-highlight
   (:weight 'bold :foreground chocolate-hue-2 :background chocolate-mono-3))
  (isearch-fail
   (:background chocolate-syntax-bg-dark))
  (isearch
   (:weight 'bold :foreground chocolate-syntax-bg-dark :background chocolate-hue-1))
  (font-lock-regexp-grouping-construct
   (:foreground chocolate-mono-1 :inherit 'bold))
  (font-lock-regexp-grouping-backslash
   (:foreground chocolate-mono-1 :inherit 'bold))
  (font-lock-preprocessor-face
   (:foreground chocolate-mono-1 :inherit 'bold))
  (font-lock-negation-char-face
   (:foreground chocolate-mono-1 :inherit 'bold))
  (font-lock-doc-face
   (:foreground chocolate-mono-2 :inherit 'font-lock-comment-face))
  (font-lock-comment-delimiter-face
   (:inherit 'font-lock-comment-face))
  (next-error
   (:inherit 'region))
  (completions-common-part nil)
  (completions-first-difference
   (:inherit 'bold))
  (completions-annotations
   (:inherit 'italic))
  (button
   (:inherit 'link))
  (show-paren-mismatch
   (:weight 'bold :foreground chocolate-syntax-bg-dark :background chocolate-hue-5))
  (show-paren-match
   (:weight 'bold :foreground chocolate-hue-5 :background chocolate-syntax-bg-dark))
  (tty-menu-selected-face
   (:background chocolate-syntax-accent))
  (tty-menu-disabled-face
   (:foreground chocolate-hue-2 :background chocolate-syntax-renamed))
  (tty-menu-enabled-face
   (:weight 'bold :foreground chocolate-syntax-accent :background chocolate-syntax-renamed))
  (success
   (:foreground chocolate-syntax-added))
  (warning
   (:foreground chocolate-hue-6-2))
  (error
   (:foreground chocolate-hue-5))
  (glyphless-char
   (:height 0.6))
  (help-argument-name
   (:inherit 'italic))
  (menu
   (:inverse-video t))
  (tool-bar
   (:box
    (:line-width 1 :style 'released-button)
    :foreground chocolate-syntax-bg-dark :background chocolate-mono-1))
  (mouse nil)
  (border nil)
  (scroll-bar nil)
  (minibuffer-prompt
   (:foreground chocolate-hue-1))
  (window-divider-last-pixel
   (:inherit 'window-divider))
  (window-divider-first-pixel
   (:inherit 'window-divider))
  (window-divider
   (:inherit 'vertical-border))
  (vertical-border
   (:foreground chocolate-syntax-bg-dark :background chocolate-syntax-bg-dark))
  (header-line
   (:inherit 'mode-line))
  (mode-line-buffer-id
   (:weight 'bold :foreground chocolate-mono-1))
  (mode-line-emphasis
   (:foreground chocolate-hue-1))
  (mode-line-highlight
   (:inherit 'highlight))
  (nobreak-space
   (:underline t :inherit 'escape-glyph))
  (escape-glyph
   (:foreground chocolate-syntax-renamed))
  (trailing-whitespace
   (:background chocolate-hue-5))
  (highlight
   (:foreground chocolate-syntax-bg-dark :background chocolate-hue-1))
  (shadow
   (:foreground chocolate-mono-3))
  (variable-pitch
   (:family "Sans Serif"))
  (fixed-pitch-serif
   (:family "Monospace Serif"))
  (fixed-pitch
   (:family "Monospace"))
  (underline
   (:underline t))
  (bold-italic
   (:inherit
    ('bold 'italic)))
  (italic
   (:slant 'italic))
  (bold
   (:weight 'bold))
  (helm-ag-edit-deleted-line
   (:strike-through t :inherit 'font-lock-comment-face))
  (swiper-line-face
   (:foreground chocolate-syntax-bg-dark :background chocolate-hue-1))
  (swiper-match-face-4
   (:weight 'bold :foreground chocolate-syntax-bg-dark :background chocolate-syntax-added))
  (swiper-match-face-3
   (:weight 'bold :foreground chocolate-syntax-bg-dark :background chocolate-mono-1))
  (swiper-match-face-2
   (:weight 'bold :foreground chocolate-syntax-bg-dark :background chocolate-hue-6))
  (swiper-match-face-1
   (:foreground chocolate-mono-3 :background chocolate-syntax-bg-dark))
  (git-gutter-fr+-deleted
   (:foreground chocolate-syntax-removed :background chocolate-syntax-removed :inherit 'git-gutter+-deleted))
  (git-gutter-fr+-added
   (:foreground chocolate-syntax-added :background chocolate-syntax-added :inherit 'git-gutter+-added))
  (git-gutter-fr+-modified
   (:foreground chocolate-syntax-modified :background chocolate-syntax-modified :inherit 'git-gutter+-modified))
  (git-gutter+-commit-header-face
   (:inherit 'font-lock-comment-face))
  (git-gutter+-unchanged
   (:background chocolate-syntax-accent))
  (git-gutter+-deleted
   (:foreground chocolate-hue-5))
  (git-gutter+-added
   (:foreground chocolate-syntax-added))
  (git-gutter+-modified
   (:foreground chocolate-hue-6-2))
  (git-gutter+-separator
   (:weight 'bold :foreground chocolate-syntax-renamed))
  (pulse-highlight-face
   (:background chocolate-hue-6-3))
  (pulse-highlight-start-face
   (:background chocolate-hue-6-3))
  (which-func
   (:foreground chocolate-hue-1))
  ))


;;;###autoload
(and load-file-name
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'chocolate)

;;; chocolate-theme.el ends here
