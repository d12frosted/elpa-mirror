;;; the-matrix-theme.el --- Green-on-black dark theme inspired by "The Matrix" movie  -*- lexical-binding: t; -*-

;; Copyright (C) 2021–2022 Dan Dee

;; Author: Dan Dee <monkeyjunglejuice@pm.me>
;; URL: https://github.com/monkeyjunglejuice/matrix-emacs-theme
;; Package-Version: 20220622.1214
;; Package-Commit: 289ed872003708ef1595e5e6765b50ca53e34ac8
;; Version: 1.0.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: faces, theme
;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

;;; Commentary:
;; "Unfortunately, no one can be told what The Matrix Theme is.
;; You'll have to see it for yourself." --Morpheus
;; I've made this almost monochrome green-on-black theme, because
;; it helps me focus. Syntax highlighting is implemented by different
;; font styles and a green base color which varies only in brightness
;; and luminosity, with additional clues in red and blue.
;;
;; Other themes:
;; - "Nude Beach" https://github.com/monkeyjunglejuice/nude-beach-emacs-theme

;;; Code:

(deftheme the-matrix "Unfortunately, no one can be told what The Matrix Theme is. You'll have to see it for yourself. --Morpheus")

;; Colors
(let* ((color-bg      "#000000")
       (color-bg-alt  "#011a0d")
       (color-hl      "#00ff7f")
       (color-bright  "#00ee76")
       (color-middle  "#00cd66")
       (color-fg      "#00a250")
       (color-dark    "#007338")
       (color-darker  "#004020")
       (color-red     "#cc2000")
       (color-blue    "#007bff")
       (color-bg-red  "#330800")
       (color-bg-blue "#001933"))

  (custom-theme-set-faces
   'the-matrix
   `(default ((t (:background ,color-bg :foreground ,color-fg))))
   `(cursor ((t (:background ,color-bright))))
   `(region ((t (:foreground ,color-middle :background ,color-darker))))
   `(success ((t (:foreground ,color-middle :background ,color-darker :extend t))))
   `(warning ((t (:foreground ,color-blue :background ,color-bg-blue :extend t))))
   `(error ((t (:foreground ,color-red :background ,color-bg-red :extend t))))
   `(secondary-selection ((t (:background ,color-bg-alt))))
   `(mode-line ((t (:foreground ,color-fg :box (:color ,color-fg)))))
   `(mode-line-buffer-id ((t (:foreground ,color-middle :weight bold))))
   `(mode-line-inactive ((t (:foreground ,color-dark :box (:color ,color-dark)))))
   `(fringe ((t (:background ,color-bg))))
   `(vertical-border ((t (:foreground ,color-dark :background nil))))
   `(minibuffer-prompt ((t (:foreground ,color-bright :weight bold))))
   `(isearch ((t (:foreground ,color-hl :weight bold :underline t))))
   `(isearch-fail ((t (:inherit error))))
   `(lazy-highlight ((t (:foreground ,color-bright :underline (:color ,color-bright)))))
   `(link ((t (:foreground ,color-middle :underline t))))
   `(link-visited ((t (:foreground ,color-fg :underline t))))
   `(button ((t (:inherit link))))
   `(help-face-button ((t (:inherit button))))
   `(help-key-binding ((t (:foreground ,color-middle :background ,color-bg-alt :box (:color ,color-dark) :inherit fixed-pitch-serif))))
   `(header-line ((t (:foreground ,color-dark :background ,color-bg-alt))))
   `(shadow ((t (:foreground ,color-dark))))
   `(show-paren-match ((t (:foreground ,color-hl :weight bold :underline t))))
   `(show-paren-mismatch ((t (:inherit error))))
   `(highlight ((t (:foreground ,color-hl :weight bold :underline (:color ,color-hl)))))
   `(match ((t (:inherit highlight))))
   `(hl-line ((t (:underline (:color ,color-dark) :extend t))))
   `(separator-line ((t (:height 0.1 :background ,color-darker))))
   `(widget-field ((t (:foreground ,color-bright :background ,color-bg-alt))))
   `(trailing-whitespace ((t (:background ,color-bg-red))))
   `(escape-glyph ((t (:inverse-video t))))

   `(font-lock-face ((t (:foreground ,color-middle))))
   `(font-lock-builtin-face ((t (:foreground ,color-middle))))
   `(font-lock-comment-face ((t (:foreground ,color-dark :inherit fixed-pitch-serif))))
   `(font-lock-constant-face ((t (:foreground ,color-fg))))
   `(font-lock-doc-face ((t (:foreground ,color-dark :slant italic :inherit fixed-pitch-serif))))
   `(font-lock-function-name-face ((t (:foreground ,color-fg :weight bold :slant italic))))
   `(font-lock-keyword-face ((t (:foreground ,color-bright))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,color-bright))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,color-bright))))
   `(font-lock-string-face ((t (:inherit fixed-pitch-serif))))
   `(font-lock-type-face ((t (:weight bold))))
   `(font-lock-variable-name-face ((t (:foreground ,color-fg :slant italic))))
   `(font-lock-warning-face ((t (:foreground ,color-red :slant italic))))

   ;; ansi colors
   `(ansi-color-names-vector [,color-bg ,color-red ,color-middle ,color-middle ,color-blue ,color-middle ,color-middle ,color-fg])

   ;; term colors
   `(term ((t (:inherit default))))
   `(term-bold ((t (:weight bold))))
   `(term-color-black ((t (:foreground ,color-bg :background ,color-bg))))
   `(term-color-blue ((t (:foreground ,color-blue :background ,color-blue))))
   `(term-color-cyan ((t (:foreground ,color-middle :background ,color-middle))))
   `(term-color-green ((t (:foreground ,color-middle :background ,color-middle))))
   `(term-color-magenta ((t (:foreground ,color-middle :background ,color-middle))))
   `(term-color-red ((t (:foreground ,color-red :background ,color-red))))
   `(term-color-white ((t (:foreground ,color-fg :background ,color-fg))))
   `(term-color-yellow ((t (:foreground ,color-middle :background ,color-middle))))
   `(term-underline ((t (:underline t))))

   ;; shell-script-mode
   `(sh-heredoc ((t (:foreground nil :inherit font-lock-string-face))))
   `(sh-quoted-exec ((t (:inherit font-lock-function-name-face))))

   ;; dired
   `(dired-header ((t (:foreground ,color-bright :slant italic))))
   `(dired-directory ((t (:weight bold))))
   `(dired-broken-symlink ((t (:slant italic :inherit error))))
   `(dired-symlink ((t (:slant italic))))
   `(dired-mark ((t (:foreground ,color-hl :background ,color-darker))))
   `(dired-marked ((t (:foreground ,color-bright :background ,color-darker))))
   `(dired-flagged ((t (:foreground ,color-red :background ,color-bg-red))))
   `(dired-perm-write ((t (:foreground ,color-bright))))
   `(dired-special ((t (:foreground ,color-middle))))

   ;; eldoc
   `(eldoc-highlight-function-argument ((t (:inherit highlight))))

   ;; proced
   `(proced-mark ((t (:inherit dired-mark))))
   `(proced-marked ((t (:inherit dired-marked))))

   ;; eshell
   `(eshell-prompt ((t (:inherit minibuffer-prompt))))
   `(eshell-ls-directory ((t (:inherit dired-directory))))
   `(eshell-ls-archive ((t (:slant italic :inherit dired-directory))))
   `(eshell-ls-symlink ((t (:inherit dired-symlink))))
   `(eshell-ls-executable ((t (:foreground ,color-bright))))
   `(eshell-ls-missing ((t (:inherit error))))
   `(eshell-ls-product ((t (:foreground ,color-middle))))
   `(eshell-ls-readonly ((t (:inherit shadow))))
   `(eshell-ls-special ((t (:inherit dired-special))))

   ;; comint
   `(comint-highlight-prompt ((t (:inherit minibuffer-prompt))))
   `(comint-highlight-input ((t (:inherit default))))

   ;; completions
   `(completions-common-part ((t (:foreground ,color-middle))))
   `(icomplete-first-match ((t (:foreground ,color-hl :weight bold :underline t))))

   ;; diff
   `(diff-added ((t (:foreground ,color-blue :background ,color-bg-blue))))
   `(diff-removed ((t (:foreground ,color-red :background ,color-bg-red))))
   `(diff-context ((t (:inherit shadow))))
   `(diff-file-header ((t (:bold t :background ,color-hl :weight bold))))
   `(diff-header ((t (:background ,color-hl :foreground ,color-fg))))

   ;; package manager
   `(package-name ((t (:inherit link))))
   `(package-description ((t (:slant italic :inherit fixed-pitch-serif))))
   `(package-status-installed ((t (:foreground ,color-fg))))
   `(package-status-dependency ((t (:foreground ,color-fg :slant italic))))
   `(package-status-built-in ((t (:foreground ,color-dark :slant italic))))
   `(package-status-incompat ((t (:slant italic :inherit font-lock-warning-face))))

   ;; customization
   `(custom-group-tag ((t (:inherit bold))))
   `(custom-variable-tag ((t (:foreground ,color-fg :weight bold))))
   `(custom-variable-obsolete ((t (:foreground ,color-dark :weight bold))))
   `(custom-documentation ((t (:inherit fixed-pitch-serif))))
   `(custom-visibility ((t (:inherit custom-documentation :underline t))))
   `(custom-state ((t (:foreground ,color-bright :slant italic))))
   `(custom-button ((t (:foreground ,color-bg :background ,color-fg))))
   `(custom-button-mouse ((t (:foreground ,color-hl :background ,color-dark))))
   `(custom-button-pressed ((t (:foreground ,color-hl :background ,color-darker))))
   `(custom-button-pressed-unraised ((t (:inherit custom-button-pressed))))
   `(custom-button-unraised ((t (:inherit custom-button))))

   ;; info
   `(info-node ((t (:foreground ,color-bright :weight bold :slant italic))))
   `(info-menu-star ((t (:foreground ,color-bright))))

   ;; message
   `(message-header-name ((t (:foreground ,color-dark :weight bold :slant italic))))
   `(message-header-other ((t (:foreground ,color-fg))))
   `(message-header-cc ((t (:inherit message-header-other))))
   `(message-header-newsgroups ((t (:inherit message-header-other))))
   `(message-header-xheader ((t (:inherit message-header-other))))
   `(message-header-subject ((t (:foreground ,color-bright :weight bold))))
   `(message-header-to ((t (:foreground ,color-bright))))
   `(message-cited-text ((t (:foreground ,color-dark :inherit italic))))
   `(message-mml ((t (:foreground ,color-bright))))
   `(message-separator ((t (:inherit font-lock-comment-face))))

   ;; erc
   `(erc-notice-face ((t (:foreground ,color-dark :weight unspecified))))
   `(erc-header-line ((t (:inherit header-line))))
   `(erc-timestamp-face ((t (:foreground ,color-bright :weight unspecified))))
   `(erc-current-nick-face ((t (:background ,color-dark :foreground ,color-bg :weight unspecified))))
   `(erc-input-face ((t (:foreground ,color-dark))))
   `(erc-prompt-face ((t (:inherit minibuffer-prompt))))
   `(erc-my-nick-face ((t (:foreground ,color-fg))))
   `(erc-pal-face ((t (:foreground ,color-dark :inherit italic))))

   ;; tex
   `(font-latex-sedate-face ((t (:foreground ,color-dark))))
   `(font-latex-math-face ((t (:inherit default))))
   `(font-latex-script-char-face ((t (:inherit font-latex-math-face))))

   ;; outline
   `(outline-1 ((t (:foreground ,color-middle :weight bold :height 1.2))))
   `(outline-2 ((t (:foreground ,color-middle :weight bold))))
   `(outline-3 ((t (:foreground ,color-middle :weight bold))))
   `(outline-4 ((t (:foreground ,color-middle :weight bold))))
   `(outline-5 ((t (:foreground ,color-middle :weight bold))))
   `(outline-6 ((t (:foreground ,color-middle :weight bold))))
   `(outline-7 ((t (:foreground ,color-middle :weight bold))))
   `(outline-8 ((t (:foreground ,color-middle :weight bold))))

   ;; org-mode
   `(org-hide ((t (:foreground ,color-bg))))
   `(org-table ((t (:foreground ,color-fg :inherit fixed-pitch-serif))))
   `(org-code ((t (:foreground ,color-middle :inherit fixed-pitch))))
   `(org-date ((t (:foreground ,color-bright))))
   `(org-todo ((t (:foreground ,color-red :box t :weight normal))))
   `(org-done ((t (:foreground ,color-middle :box t :weight normal))))
   `(org-headline-done ((t (:foreground ,color-dark))))
   `(org-latex-and-related ((t (:foreground ,color-dark :italic t))))
   `(org-checkbox ((t (:foreground ,color-bright :weight normal :inherit fixed-pitch))))
   `(org-verbatim ((t (:inherit font-lock-string-face))))
   `(org-mode-line-clock ((t (:background nil))))
   `(org-document-title ((t (:foreground ,color-middle :weight bold))))
   `(org-drawer ((t (:inherit font-lock-comment-face))))
   `(org-block ((t (:foreground ,color-fg :background ,color-bg-alt :inherit fixed-pitch :extend t))))
   `(org-block-begin-line ((t (:foreground ,color-dark))))
   `(org-block-end-line ((t (:foreground ,color-dark))))
   `(org-meta-line ((t (:foreground ,color-dark))))
   `(org-document-info-keyword ((t (:foreground ,color-dark))))
   `(org-document-info ((t (:foreground ,color-middle))))
   `(org-archived ((t (:foreground ,color-dark))))

   ;; org-tree-slide
   `(org-tree-slide-header-overlay-face ((t (:inherit font-lock-comment-face :foreground nil :background nil))))

   ;; shortdoc
   `(shortdoc-heading ((t (:inherit outline-1))))

   ;; compilation
   `(compilation-error ((t (:inherit error))))
   `(compilation-warning ((t (:inherit warning))))
   `(compilation-info ((t (:foreground ,color-blue))))

   ;; whitespace
   `(whitespace-trailing ((t (:background ,color-bg-red))))
   `(whitespace-line ((t (:inherit whitespace-trailing))))
   `(whitespace-space (( t(:foreground ,color-darker))))
   `(whitespace-newline ((t (:inherit whitespace-space))))
   `(whitespace-empty ((t (:inherit whitespace-line))))

   ;; smartparens
   `(sp-pair-overlay-face ((t (:foreground ,color-bright :background ,color-bg-alt))))
   `(sp-show-pair-match-content ((t (:inherit show-paren-match-expression))))

   ;; rainbow delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,color-fg :weight light))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,color-dark :weight light))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,color-dark :weight light))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,color-dark :weight light))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground ,color-dark :weight light))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,color-dark :weight light))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,color-dark :weight light))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground ,color-dark :weight light))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground ,color-dark :weight light))))
   `(rainbow-delimiters-unmatched-face ((t (:inherit error))))

   ;; paren face
   `(parenthesis ((t (:inherit shadow :weight light))))

   ;; git-commit
   `(git-commit-summary ((t (:inherit default))))
   `(git-commit-comment-heading ((t (:slant italic :inherit font-lock-comment-face))))
   `(git-commit-comment-branch-local ((t (:slant italic :weight bold))))
   `(git-commit-comment-branch-remote ((t (:slant italic :weight bold))))
   `(git-commit-comment-file ((t (:foreground ,color-bright :background ,color-bg-alt))))
   `(git-commit-comment-action ((t (:weight bold :inherit font-lock-comment-face))))

   ;; magit
   `(magit-branch-local ((t (:foreground ,color-middle :weight bold))))
   `(magit-branch-remote ((t (:foreground ,color-middle :weight bold :slant italic))))
   `(magit-tag ((t (:foreground ,color-dark :background nil :inherit italic))))
   `(magit-hash ((t (:foreground ,color-bright))))
   `(magit-section-title ((t (:foreground ,color-fg :background nil))))
   `(magit-section-heading ((t (:background nil :foreground ,color-fg))))
   `(magit-section-heading-selection ((t (:inherit region))))
   `(magit-section-highlight ((t (:background ,color-bg-alt))))
   `(magit-item-highlight ((t (:foreground ,color-fg :background ,color-bright))))
   `(magit-log-author ((t (:foreground ,color-dark))))
   `(magit-diff-added ((t (:inherit diff-added))))
   `(magit-diffstat-added ((t (:foreground ,color-blue))))
   `(magit-diff-added-highlight ((t (:inherit magit-diff-added))))
   `(magit-diff-removed ((t (:inherit diff-removed))))
   `(magit-diffstat-removed ((t (:foreground ,color-red))))
   `(magit-diff-removed-highlight ((t (:inherit magit-diff-removed))))
   `(magit-diff-context ((t (:inherit diff-context))))
   `(magit-diff-context-highlight ((t (:foreground ,color-dark :inherit magit-section-highlight))))
   `(magit-popup-argument ((t (:inherit font-lock-function-name-face))))
   `(magit-popup-disabled-argument ((t (:inherit font-lock-comment-face))))
   `(magit-process-ok ((t (:inherit success))))
   `(magit-diff-hunk-heading ((t (:background ,color-bg :inherit header-line :underline t))))
   `(magit-diff-hunk-heading-highlight ((t (:inherit magit-section-highlight))))
   `(magit-filename ((t (:inherit git-commit-comment-file))))

   ;; git-gutter-fringe
   `(git-gutter-fr:modified ((t (:foreground ,color-dark))))
   `(git-gutter-fr:added ((t (:foreground ,color-blue))))
   `(git-gutter-fr:deleted ((t (:foreground ,color-red))))

   ;; diff-hl
   `(diff-hl-change ((t (:foreground ,color-dark))))
   `(diff-hl-insert ((t (:foreground ,color-blue))))
   `(diff-hl-delete ((t (:foreground ,color-red))))

   ;; company
   `(company-echo ((t (:inherit company-preview))))
   `(company-echo-common ((t (:inherit company-tooltip-common))))
   `(company-preview ((t (:foreground ,color-fg))))
   `(company-preview-common ((t (:foreground ,color-fg :background nil))))
   `(company-tooltip-search ((t (:inherit lazy-highlight))))
   `(company-tooltip-search-selection ((t (:inherit company-tooltip-search))))
   `(company-tooltip ((t (:foreground ,color-bright :background ,color-darker))))
   `(company-tooltip-annotation ((t (:foreground ,color-middle))))
   `(company-tooltip-annotation-selection ((t (:weight normal))))
   `(company-tooltip-common ((t (:foreground ,color-fg))))
   `(company-tooltip-common-selection ((t (:foreground ,color-middle))))
   `(company-tooltip-selection ((t (:foreground ,color-hl :background ,color-darker :weight bold :underline (:color ,color-bright)))))
   `(company-tooltip-scrollbar-thumb ((t (:background ,color-dark))))
   `(company-tooltip-scrollbar-track ((t (:background ,color-darker))))
   `(company-scrollbar-fg ((t (:inherit company-tooltip-scrollbar-thumb))))  ; obsolete
   `(company-scrollbar-bg ((t (:inherit company-tooltip-scrollbar-track))))  ; obsolete

   ;; flymake
   `(flymake-error ((t (:inherit error))))
   `(flymake-warning ((t (:inherit warning))))
   `(flymake-note ((t (:foreground ,color-blue))))

   ;; flycheck
   `(flycheck-error ((t (:inherit error))))
   `(flycheck-fringe-error ((t (:inherit flycheck-error))))
   `(flycheck-warning ((t (:inherit warning))))
   `(flycheck-fringe-warning ((t (:inherit flycheck-warning))))
   `(flycheck-info ((t (:foreground ,color-blue))))
   `(flycheck-fringe-info ((t (:inherit flycheck-info))))
   `(flycheck-error-list-info ((t (:inherit flycheck-info))))

   ;; lsp
   `(lsp-headerline-breadcrumb-path-face ((t (:foreground ,color-dark))))
   `(lsp-headerline-breadcrumb-path-error-face ((t (:inherit error))))
   `(lsp-headerline-breadcrumb-separator-face ((t (:foreground ,color-dark))))

   ;; eglot
   `(eglot-highlight-symbol-face ((t (:inherit lazy-highlight))))

   ;; csv
   `(csv-separator-face ((t (:foreground ,color-middle))))

   ;; css
   `(css-selector ((t (:weight bold))))
   `(css-property ((t (:inherit font-lock-builtin-face))))

   ;; web-mode
   `(web-mode-html-tag-bracket-face ((t (:inherit shadow))))
   `(web-mode-html-tag-face ((t (:weight bold :inherit shadow))))
   `(web-mode-html-attr-name-face ((t (:inherit shadow))))
   `(web-mode-css-selector-face ((t (:inherit css-selector))))
   `(web-mode-css-property-name-face ((t (:inherit css-property))))
   `(web-mode-css-color-face ((t (:foreground ,color-fg))))
   `(web-mode-current-element-highlight-face ((t (:inherit lazy-highlight))))
   `(web-mode-doctype-face ((t (:inherit shadow))))

   ;; slime
   `(slime-repl-inputed-output-face ((t (:foreground ,color-middle))))
   `(slime-repl-output-mouseover-face ((t (:foreground ,color-bright :box nil))))
   `(slime-repl-input-face ((t (:inherit default))))
   `(slime-repl-prompt ((t (:inherit minibuffer-prompt))))
   `(slime-highlight-edits-face ((t (:underline (:color ,color-darker)))))
   `(slime-highlight-face ((t (:inherit highlight))))
   `(slime-error-face ((t (:inherit error))))
   `(slime-warning-face ((t (:inherit warning))))
   `(slime-style-warning-face ((t (:inherit warning))))
   `(sldb-restartable-frame-line-face ((t (:inherit link))))
   `(sldb-section-face ((t (:foreground ,color-dark :weight bold))))

   ;; geiser
   `(geiser-font-lock-repl-output ((t (:foreground ,color-middle))))
   `(geiser-font-lock-autodoc-identifier ((t (:inherit font-lock-keyword-face))))
   `(geiser-font-lock-autodoc-current-arg ((t (:inherit highlight))))

   ;; cider
   `(cider-result-overlay-face ((t (:background ,color-bg-alt))))
   `(cider-fringe-good-face ((t (:foreground ,color-dark))))
   `(cider-warning-highlight-face ((t (:foreground ,color-blue :background ,color-bg-blue :slant italic))))
   `(cider-test-error-face ((t (:inherit font-lock-warning-face))))
   `(cider-test-failure-face ((t (:inherit font-lock-warning-face))))
   `(cider-test-success-face ((t (:foreground ,color-middle :weight bold))))
   `(cider-repl-prompt-face ((t (:inherit minibuffer-prompt))))
   `(cider-repl-stdout-face ((t (:inherit default))))
   `(cider-repl-stderr-face ((t (:inherit font-lock-warning-face))))
   `(cider-stacktrace-error-class-face ((t (:inherit font-lock-warning-face))))
   `(cider-error-highlight-face ((t (:inherit error))))

   ;; clojure-mode
   `(clojure-keyword-face ((t (:inherit font-lock-builtin-face))))

   ;; tuareg
   `(tuareg-font-lock-interactive-output-face ((t (:foreground ,color-bright))))
   `(tuareg-font-lock-interactive-error-face ((t (:inherit font-lock-warning-face))))
   `(tuareg-font-lock-interactive-directive-face ((t (:foreground ,color-middle))))
   `(tuareg-font-lock-operator-face ((t (:foreground ,color-middle))))
   `(tuareg-font-lock-module-face ((t (:inherit shadow))))
   `(tuareg-font-lock-governing-face ((t (:foreground ,color-bright :weight bold))))
   `(tuareg-font-lock-label-face ((t (:inherit shadow))))
   `(tuareg-font-lock-line-number-face ((t (:inherit linum))))
   `(tuareg-font-double-semicolon-face ((t (:inherit tuareg-font-lock-interactive-directive-face))))
   `(tuareg-font-double-colon-face ((t (:inherit tuareg-font-double-semicolon-face))))
   `(tuareg-font-lock-error-face ((t (:inherit error))))

   ;; merlin
   `(merlin-compilation-error-face ((t (:inherit error))))
   `(merlin-type-face ((t (:inherit lazy-highlight))))

   ;; merlin-eldoc
   `(merlin-eldoc-occurrences-face ((t (:inherit lazy-highlight))))

   ;; utop
   `(utop-frozen ((t (:inherit default))))
   `(utop-prompt ((t (:inherit minibuffer-prompt))))
   `(utop-error  ((t (:inherit error))))

   ;; selectrum
   `(selectrum-mouse-highlight ((t (:background nil :underline t :extend t))))
   `(selectrum-prescient-primary-highlight ((t (:inherit completions-common-part))))

   ;; marginalia
   `(marginalia-archive ((t (:inherit nil))))
   `(marginalia-key ((t (:inherit nil))))
   `(marginalia-number ((t (:inherit nil))))
   `(marginalia-file-priv-dir ((t (:weight bold))))
   `(marginalia-file-priv-read ((t (:foreground ,color-fg))))
   `(marginalia-file-priv-write ((t (:foreground ,color-red))))
   `(marginalia-file-priv-exec ((t (:foreground ,color-blue))))

   ;; consult
   `(consult-preview-line ((t (:inherit highlight))))
   `(consult-preview-cursor ((t (:background ,color-bg :underline nil))))

   ;; helm
   `(helm-candidate-number ((t (:foreground ,color-dark :background nil))))
   `(helm-source-header ((t (:inherit font-lock-comment-face :background unspecified :foreground unspecified))))
   `(helm-selection ((t (:inherit highlight))))
   `(helm-prefarg ((t (:foreground ,color-dark))))
   `(helm-ff-file ((t (:inherit default))))
   `(helm-ff-directory ((t (:inherit dired-directory :foreground unspecified))))
   `(helm-ff-executable ((t (:inherit eshell-ls-executable :foreground unspecified))))
   `(helm-ff-file-extension ((t (:foreground nil :background nil))))
   `(helm-ff-invalid-symlink ((t (:slant italic :inherit error))))
   `(helm-ff-symlink ((t (:inherit dired-symlink))))
   `(helm-ff-prefix ((t (:background nil))))
   `(helm-ff-dotted-directory ((t (:background nil :foreground ,color-middle))))
   `(helm-M-x-key ((t (:foreground ,color-bright))))
   `(helm-M-x-short-doc ((t (:inherit font-lock-doc-face))))
   `(helm-buffer-file ((t (:foreground ,color-fg))))
   `(helm-buffer-archive ((t (:inherit eshell-ls-archive))))
   `(helm-buffer-directory ((t (:inherit dired-directory))))
   `(helm-buffer-not-saved ((t (:foreground ,color-red :underline (:color ,color-red :style wave)))))
   `(helm-buffer-saved-out ((t (:inherit helm-buffer-not-saved))))
   `(helm-buffer-modified ((t (:foreground ,color-blue :underline (:color ,color-blue :style wave)))))
   `(helm-buffer-process ((t (:foreground ,color-dark))))
   `(helm-buffer-size ((t (:foreground ,color-dark))))
   `(helm-match ((t (:inherit completions-common-part))))
   `(helm-bookmark-addressbook ((t (:inherit default))))
   `(helm-bookmark-directory ((t (:inherit dired-directory))))
   `(helm-bookmark-file ((t (:inherit default))))
   `(helm-bookmark-file-not-found ((t (:inherit default :slant italic))))
   `(helm-bookmark-gnus ((t (:inherit default))))
   `(helm-bookmark-info ((t (:inherit default))))
   `(helm-bookmark-man ((t (:inherit default))))
   `(helm-bookmark-w3m ((t (:inherit default))))

   ;; adoc-mode
   `(markup-meta-hide-face ((t (:height 1.0 :foreground ,color-bright))))
   `(markup-meta-face ((t (:height 1.0 :foreground ,color-dark :family nil))))
   `(markup-reference-face ((t (:underline nil :foreground ,color-dark))))
   `(markup-gen-face ((t (:inherit default :foreground nil))))
   `(markup-passthrough-face ((t (:inherit markup-dark))))
   `(markup-replacement-face ((t (:family nil :foreground ,color-dark))))
   `(markup-list-face ((t (:weight bold))))
   `(markup-secondary-text-face ((t (:height 1.0 :foreground ,color-dark))))
   `(markup-verbatim-face ((t (:foreground ,color-dark :inherit fixed-pitch-serif))))
   `(markup-code-face ((t (:inherit markup-verbatim-face))))
   `(markup-typewriter-face ((t (:inherit nil))))
   `(markup-complex-replacement-face ((t (:background ,color-hl :foreground ,color-fg))))
   `(markup-title-0-face ((t (:height 1.2 :inherit markup-gen-face))))
   `(markup-title-1-face ((t (:height 1.0 :inherit markup-gen-face))))
   `(markup-title-2-face ((t (:height 1.0 :inherit markup-gen-face))))
   `(markup-title-3-face ((t (:height 1.0 :inherit markup-gen-face))))
   `(markup-title-4-face ((t (:height 1.0 :inherit markup-gen-face))))
   `(markup-title-5-face ((t (:height 1.0 :inherit markup-gen-face))))

   ;; highlight-indent-guides
   `(highlight-indent-guides-odd-face ((t (:background ,color-bg-alt))))
   `(highlight-indent-guides-even-face ((t (:background nil))))

   ;; notmuch
   `(notmuch-search-unread-face ((t (:foreground ,color-bright))))
   `(notmuch-tag-face ((t (:foreground ,color-dark))))
   `(notmuch-tree-match-author-face ((t (:foreground ,color-middle))))
   `(notmuch-tree-no-match-face ((t (:foreground ,color-dark))))
   `(notmuch-tree-match-tag-face ((t (:inherit notmuch-tree-match-author-face))))
   `(notmuch-tag-unread-face ((t (:foreground ,color-bg :background ,color-dark))))
   `(notmuch-message-summary-face ((t (:foreground ,color-dark))))

   ;; telega
   `(telega-msg-heading ((t (:foreground ,color-dark :background nil :inherit nil))))
   `(telega-msg-inline-reply ((t (:foreground ,color-bright :inherit nil))))
   `(telega-entity-type-texturl ((t (:inherit nil :foreground ,color-dark))))

   ;; beancount
   `(beancount-date ((t (:inherit italic :foreground nil))))
   `(beancount-account ((t (:inherit default))))

   ;; w3m
   `(w3m-anchor ((t (:inherit link))))
   `(w3m-arrived-anchor ((t (:inherit link-visited))))
   `(w3m-current-anchor ((t (:inherit highlight))))
   `(w3m-error ((t (:inherit error))))
   `(w3m-header-line-content ((t (:inherit header-line))))
   `(w3m-header-line-background ((t (:inherit header-line))))
   `(w3m-header-line-title ((t (:inherit header-line))))
   `(w3m-form ((t (:inherit widget-field))))
   `(w3m-form-button ((t (:inherit custom-button))))
   `(w3m-form-button-mouse ((t (:inherit custom-button-mouse))))
   `(w3m-form-button-pressed ((t (:inherit custom-button-pressed))))

   ;; elfeed
   `(elfeed-search-date-face ((t (:foreground ,color-dark))))
   `(elfeed-search-title-face ((t (:inherit default))))
   `(elfeed-search-unread-title-face ((t (:foreground ,color-middle))))
   `(elfeed-search-feed-face ((t (:foreground ,color-dark))))
   `(elfeed-search-tag-face ((t (:inherit default))))
   `(elfeed-search-last-update-face ((t (:inherit font-lock-comment-face))))
   `(elfeed-search-unread-count-face ((t (:weight bold))))
   `(elfeed-search-filter-face ((t (:foreground ,color-bright))))
   `(elfeed-log-debug-level-face ((t (:foreground ,color-blue))))
   `(elfeed-log-error-level-face ((t (:inherit error))))
   `(elfeed-log-info-level-face ((t (:foreground ,color-blue))))
   `(elfeed-log-warn-level-face ((t (:inherit warning))))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'the-matrix)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; the-matrix-theme.el ends here
