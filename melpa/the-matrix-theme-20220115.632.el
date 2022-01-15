;;; the-matrix-theme.el --- Green-on-black dark theme inspired by "The Matrix" movie  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Dan Dee

;; Author: Dan Dee <monkeyjunglejuice@pm.me>
;; URL: https://github.com/monkeyjunglejuice/matrix-emacs-theme
;; Package-Version: 20220115.632
;; Package-Commit: 70edeba78da844bfbcbcaa24abd5c8983a9df0d7
;; Version: 0.1.0
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

;;; Credits:
;; `the-matrix-theme' is based on my `giorgio-theme' which may be released
;; after this one.

;;; Code:

(deftheme the-matrix "Unfortunately, no one can be told what The Matrix Theme is. You'll have to see it for yourself. --Morpheus")

;; Colors
(let* ((color-bg      "#000000")
       (color-bg-alt  "#011a0d")
       (color-bg-red  "#330800")
       (color-bg-blue "#001933")
       (color-hl      "#00ff7f")
       (color-bright  "#00ee76")
       (color-middle  "#00cd66")
       (color-fg      "#00a250")
       (color-dark    "#007338")
       (color-darker  "#004020")
       (color-red     "#cc2000")
       (color-blue    "#007bff"))

  (custom-theme-set-faces
   'the-matrix
   `(default ((t (:background ,color-bg :foreground ,color-fg))))
   `(cursor ((t (:background ,color-hl))))
   `(region ((t (:foreground ,color-middle :background ,color-darker))))
   `(success ((t (:foreground ,color-middle :background ,color-darker))))
   `(warning ((t (:foreground ,color-blue :background ,color-bg-blue))))
   `(error ((t (:foreground ,color-red :background ,color-bg-red))))
   `(secondary-selection ((t (:background ,color-bg-alt))))
   `(mode-line ((t (:foreground ,color-fg :box (:color ,color-fg)))))
   `(mode-line-buffer-id ((t (:foreground ,color-middle :weight bold))))
   `(mode-line-inactive ((t (:foreground ,color-dark :box (:color ,color-dark)))))
   `(fringe ((t (:background ,color-bg))))
   `(vertical-border ((t (:foreground ,color-fg :background nil))))
   `(minibuffer-prompt ((t (:foreground ,color-hl :slant italic :weight bold))))

   `(font-lock-face ((t (:foreground ,color-middle))))
   `(font-lock-builtin-face ((t (:foreground ,color-middle))))
   `(font-lock-comment-face ((t (:foreground ,color-dark :inherit fixed-pitch-serif))))
   `(font-lock-doc-face ((t (:foreground ,color-dark :slant italic :inherit fixed-pitch-serif))))
   `(font-lock-constant-face ((t (:foreground ,color-middle))))
   `(font-lock-function-name-face ((t (:weight bold :slant italic))))
   `(font-lock-keyword-face ((t (:foreground ,color-bright))))
   `(font-lock-string-face ((t (:background ,color-bg-alt :inherit fixed-pitch-serif))))
   `(font-lock-type-face ((t (:weight bold))))
   `(font-lock-variable-name-face ((t (:slant italic))))
   `(font-lock-warning-face ((t (:foreground ,color-red :weight bold))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,color-bright))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,color-bright))))

   `(isearch ((t (:foreground ,color-hl :weight bold :underline t))))
   `(isearch-fail ((t (:inherit error))))
   `(lazy-highlight ((t (:foreground ,color-hl :underline t))))

   `(link ((t (:foreground ,color-middle :underline t))))
   `(link-visited ((t (:foreground ,color-fg :underline t))))
   `(button ((t (:inherit link))))
   `(help-face-button ((t (:inherit button))))
   `(header-line ((t (:foreground ,color-dark :background ,color-bg-alt :slant italic :inherit fixed-pitch-serif))))
   `(shadow ((t (:foreground ,color-dark))))
   `(show-paren-match ((t (:foreground ,color-hl :weight bold :underline t))))
   `(show-paren-mismatch ((t (:inherit error))))
   `(highlight ((t (:foreground ,color-hl :underline (:color ,color-hl)))))
   `(hl-line ((t (:underline (:color ,color-dark) :extend t))))
   `(widget-field ((t (:foreground ,color-bright :background ,color-bg-alt))))
   `(trailing-whitespace ((t (:background ,color-bg-red))))
   `(escape-glyph ((t (:inverse-video t))))

   ;; ANSI colors
   `(ansi-color-names-vector [,color-bg ,color-red ,color-middle ,color-middle ,color-blue ,color-middle ,color-middle ,color-fg])

   ;; Term colors
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

   ;; Shell-script-mode
   `(sh-heredoc ((t (:foreground nil :inherit font-lock-string-face))))
   `(sh-quoted-exec ((t (:inherit font-lock-function-name-face))))

   ;; Dired
   `(dired-header ((t (:foreground ,color-bright :slant italic))))
   `(dired-directory ((t (:weight bold))))
   `(dired-symlink ((t (:slant italic))))
   `(dired-mark ((t (:foreground ,color-hl :background ,color-darker))))
   `(dired-marked ((t (:foreground ,color-bright :background ,color-darker))))
   `(dired-flagged ((t (:foreground ,color-red :background ,color-bg-red))))
   `(dired-perm-write ((t (:foreground ,color-bright))))
   `(dired-special ((t (:foreground ,color-middle))))

   ;; Eshell
   `(eshell-prompt ((t (:inherit minibuffer-prompt))))
   `(eshell-ls-directory ((t (:inherit dired-directory))))
   `(eshell-ls-archive ((t (:slant italic :inherit dired-directory))))
   `(eshell-ls-symlink ((t (:inherit dired-symlink))))
   `(eshell-ls-executable ((t (:foreground ,color-middle))))
   `(eshell-ls-missing ((t (:inherit error))))
   `(eshell-ls-readonly ((t (:inherit shadow))))
   `(eshell-ls-special ((t (:inherit dired-special))))

   ;; Comint
   `(comint-highlight-prompt ((t (:inherit minibuffer-prompt))))
   `(comint-highlight-input ((t (:inherit default))))

   ;; Completions
   `(completions-common-part ((t (:foreground ,color-middle))))
   `(icomplete-first-match ((t (:foreground ,color-hl :weight bold))))

   ;; Diff
   `(diff-added ((t (:foreground ,color-blue :background ,color-bg-blue))))
   `(diff-removed ((t (:foreground ,color-red :background ,color-bg-red))))
   `(diff-context ((t (:inherit shadow :background ,color-bg-alt))))
   `(diff-file-header ((t (:bold t :background ,color-hl :weight bold))))
   `(diff-header ((t (:background ,color-hl :foreground ,color-fg))))

   ;; Package manager
   `(package-name ((t (:inherit link))))
   `(package-description ((t (:slant italic :inherit fixed-pitch-serif))))
   `(package-status-installed ((t (:foreground ,color-fg))))
   `(package-status-dependency ((t (:foreground ,color-fg :slant italic))))
   `(package-status-built-in ((t (:foreground ,color-dark :slant italic))))
   `(package-status-incompat ((t (:slant italic :inherit font-lock-warning-face))))

   ;; Customization
   `(custom-group-tag ((t (:inherit bold))))
   `(custom-variable-tag ((t (:foreground ,color-fg :weight bold))))
   `(custom-variable-obsolete ((t (:foreground ,color-dark :weight bold))))
   `(custom-documentation ((t (:slant italic :inherit fixed-pitch-serif))))
   `(custom-visibility ((t (:inherit custom-documentation :underline t))))
   `(custom-state ((t (:foreground ,color-blue))))
   `(custom-button ((t (:foreground ,color-bg :background ,color-fg))))
   `(custom-button-mouse ((t (:foreground ,color-bg :background ,color-hl))))
   `(custom-button-pressed ((t (:foreground ,color-hl :background ,color-darker))))
   `(custom-button-pressed-unraised ((t (:inherit custom-button-pressed))))
   `(custom-button-unraised ((t (:inherit custom-button))))

   ;; Info
   `(info-node ((t (:foreground ,color-bright :weight bold :slant italic))))
   `(info-menu-star ((t (:foreground ,color-bright))))

   ;; Message
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

   ;; ERC
   `(erc-notice-face ((t (:foreground ,color-dark :weight unspecified))))
   `(erc-header-line ((t (:inherit header-line))))
   `(erc-timestamp-face ((t (:foreground ,color-bright :weight unspecified))))
   `(erc-current-nick-face ((t (:background ,color-dark :foreground ,color-bg :weight unspecified))))
   `(erc-input-face ((t (:foreground ,color-dark))))
   `(erc-prompt-face ((t (:inherit minibuffer-prompt))))
   `(erc-my-nick-face ((t (:foreground ,color-fg))))
   `(erc-pal-face ((t (:foreground ,color-dark :inherit italic))))

   ;; TeX
   `(font-latex-sedate-face ((t (:foreground ,color-dark))))
   `(font-latex-math-face ((t (:inherit default))))
   `(font-latex-script-char-face ((t (:inherit font-latex-math-face))))

   ;; Outline
   `(outline-1 ((t (:foreground ,color-middle :weight bold :height 1.6))))
   `(outline-2 ((t (:foreground ,color-middle :weight bold :height 1.4))))
   `(outline-3 ((t (:foreground ,color-middle :weight bold :height 1.2))))
   `(outline-4 ((t (:foreground ,color-middle :weight bold))))
   `(outline-5 ((t (:foreground ,color-middle :weight bold))))
   `(outline-6 ((t (:foreground ,color-middle :weight bold))))
   `(outline-7 ((t (:foreground ,color-middle :weight bold))))
   `(outline-8 ((t (:foreground ,color-middle :weight bold))))

   ;; Org-mode
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
   `(org-block ((t (:foreground ,color-fg :inherit fixed-pitch))))
   `(org-block-begin-line ((t (:inherit font-lock-comment-face))))
   `(org-block-end-line ((t (:inherit font-lock-comment-face))))
   `(org-meta-line ((t (:inherit font-lock-comment-face))))
   `(org-document-info-keyword ((t (:inherit font-lock-comment-face))))
   `(org-document-info ((t (:foreground ,color-middle))))
   `(org-archived ((t (:foreground ,color-dark))))

   ;; org-tree-slide
   `(org-tree-slide-header-overlay-face ((t (:inherit font-lock-comment-face :foreground nil :background nil))))

   ;; Compilation
   `(compilation-error ((t (:inherit error))))
   `(compilation-warning ((t (:inherit warning))))
   `(compilation-info ((t (:foreground ,color-blue))))

   ;; Whitespace
   `(whitespace-trailing ((t (:background ,color-bg-red))))
   `(whitespace-line ((t (:inherit whitespace-trailing))))
   `(whitespace-space (( t(:foreground ,color-darker))))
   `(whitespace-newline ((t (:inherit whitespace-space))))
   `(whitespace-empty ((t (:inherit whitespace-line))))

   ;; Smartparens
   `(sp-pair-overlay-face ((t (:foreground ,color-bright :background ,color-bg-alt))))

   ;; Rainbow delimiters
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

   ;; Paren face
   `(parenthesis ((t (:inherit shadow :weight light))))

   ;; Git-commit
   `(git-commit-summary ((t (:inherit default))))
   `(git-commit-comment-heading ((t (:slant italic :inherit font-lock-comment-face))))
   `(git-commit-comment-branch-local ((t (:slant italic :weight bold))))
   `(git-commit-comment-branch-remote ((t (:slant italic :weight bold))))
   `(git-commit-comment-file ((t (:foreground ,color-bright :background ,color-bg-alt))))
   `(git-commit-comment-action ((t (:weight bold :inherit font-lock-comment-face))))

   ;; Magit
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
   `(magit-diff-context-highlight ((t (:inherit magit-diff-context))))
   `(magit-popup-argument ((t (:inherit font-lock-function-name-face))))
   `(magit-popup-disabled-argument ((t (:inherit font-lock-comment-face))))
   `(magit-process-ok ((t (:inherit success))))
   `(magit-diff-hunk-heading ((t (:background ,color-bg :inherit header-line :underline t))))
   `(magit-diff-hunk-heading-highlight ((t (:background unspecified :foreground unspecified :inherit magit-diff-hunk-heading))))
   `(magit-filename ((t (:inherit git-commit-comment-file))))

   ;; Git-gutter-fringe
   `(git-gutter-fr:modified ((t (:foreground ,color-dark))))
   `(git-gutter-fr:added ((t (:foreground ,color-dark))))
   `(git-gutter-fr:deleted ((t (:foreground ,color-dark))))

   ;; Diff-hl
   `(diff-hl-change ((t (:foreground ,color-dark))))
   `(diff-hl-insert ((t (:foreground ,color-dark))))
   `(diff-hl-delete ((t (:foreground ,color-dark))))

   ;; Company
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
   `(company-scrollbar-bg ((t (:background ,color-darker))))
   `(company-scrollbar-fg ((t (:background ,color-dark))))

   ;; Flymake
   `(flymake-error ((t (:inherit error))))
   `(flymake-warning ((t (:inherit warning))))
   `(flymake-note ((t (:foreground ,color-blue))))

   ;; Flycheck
   `(flycheck-error ((t (:inherit error))))
   `(flycheck-fringe-error ((t (:inherit flycheck-error))))
   `(flycheck-warning ((t (:inherit warning))))
   `(flycheck-fringe-warning ((t (:foreground ,color-red))))
   `(flycheck-info ((t (:underline (:color ,color-blue :style wave)))))
   `(flycheck-fringe-info ((t (:foreground ,color-blue))))

   ;; LSP
   `(lsp-headerline-breadcrumb-path-face ((t (:foreground ,color-dark))))
   `(lsp-headerline-breadcrumb-path-error-face ((t (:inherit error))))
   `(lsp-headerline-breadcrumb-separator-face ((t (:foreground ,color-dark))))

   ;; Eglot
   `(eglot-highlight-symbol-face ((t (:inherit lazy-highlight))))

   ;; CSV
   `(csv-separator-face ((t (:foreground ,color-middle))))

   ;; CSS
   `(css-selector ((t (:weight bold))))
   `(css-property ((t (:inherit font-lock-builtin-face))))

   ;; Web-mode
   `(web-mode-html-tag-bracket-face ((t (:inherit shadow))))
   `(web-mode-html-tag-face ((t (:weight bold :inherit shadow))))
   `(web-mode-html-attr-name-face ((t (:inherit shadow))))
   `(web-mode-css-selector-face ((t (:inherit css-selector))))
   `(web-mode-css-property-name-face ((t (:inherit css-property))))
   `(web-mode-doctype-face ((t (:inherit shadow))))
   `(web-mode-css-color-face ((t (:foreground ,color-fg))))

   ;; Slime
   `(slime-repl-inputed-output-face ((t (:foreground ,color-middle))))
   `(slime-repl-output-mouseover-face ((t (:foreground ,color-bright :box nil))))
   `(slime-repl-input-face ((t (:inherit default))))
   `(slime-repl-prompt ((t (:inherit minibuffer-prompt))))
   `(sldb-restartable-frame-line-face ((t (:inherit link))))
   `(sldb-section-face ((t (:foreground ,color-dark :weight bold))))

   ;; Cider
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

   ;; Clojure-mode
   `(clojure-keyword-face ((t (:inherit font-lock-builtin-face))))

   ;; Tuareg
   `(tuareg-font-lock-interactive-output-face ((t (:foreground ,color-bright))))
   `(tuareg-font-lock-interactive-error-face ((t (:inherit error))))
   `(tuareg-font-lock-interactive-directive-face ((t (:foreground ,color-middle))))
   `(tuareg-font-lock-operator-face ((t (:foreground ,color-middle))))
   `(tuareg-font-lock-module-face ((t (:inherit shadow))))
   `(tuareg-font-lock-governing-face ((t (:foreground ,color-bright :weight bold))))
   `(tuareg-font-lock-label-face ((t (:inherit font-lock-builtin-face))))
   `(tuareg-font-lock-line-number-face ((t (:inherit linum))))
   `(tuareg-font-double-colon-face ((t (:inherit tuareg-font-lock-governing-face))))
   `(tuareg-font-lock-error-face ((t (:inherit error))))

   ;; Merlin
   `(merlin-compilation-error-face ((t (:inherit error))))
   `(merlin-type-face ((t (:background ,color-hl))))

   ;; Merlin-eldoc
   `(merlin-eldoc-occurrences-face ((t (:inherit lazy-highlight))))

   ;; Utop
   `(utop-frozen ((t (:inherit default))))
   `(utop-prompt ((t (:inherit minibuffer-prompt))))
   `(utop-error  ((t (:inherit error))))

   ;; Selectrum
   `(selectrum-mouse-highlight ((t (:background nil :underline t :extend t))))
   `(selectrum-prescient-primary-highlight ((t (:inherit completions-common-part))))

   ;; Marginalia
   `(marginalia-archive ((t (:inherit nil))))
   `(marginalia-key ((t (:inherit nil))))
   `(marginalia-number ((t (:inherit nil))))
   `(marginalia-file-priv-dir ((t (:weight bold))))
   `(marginalia-file-priv-read ((t (:foreground ,color-fg))))
   `(marginalia-file-priv-write ((t (:foreground ,color-red))))
   `(marginalia-file-priv-exec ((t (:foreground ,color-blue))))

   ;; Consult
   `(consult-preview-line ((t (:inherit highlight))))
   `(consult-preview-cursor ((t (:background ,color-bg :underline nil))))

   ;; Helm
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
   `(helm-buffer-file ((t (:foreground ,color-fg))))
   `(helm-buffer-archive ((t (:inherit helm-buffer-file))))
   `(helm-buffer-directory ((t (:inherit dired-directory))))
   `(helm-buffer-not-saved ((t (:inherit helm-buffer-file :foreground unspecified :background ,color-middle))))
   `(helm-buffer-saved-out ((t (:inherit helm-buffer-not-saved))))
   `(helm-buffer-modified ((t (:foreground ,color-dark))))
   `(helm-buffer-process ((t (:foreground ,color-dark))))
   `(helm-buffer-size ((t (:foreground ,color-dark))))
   `(helm-match ((t (:inherit completions-common-part))))

   ;; Adoc-mode
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
   `(markup-title-0-face ((t (:height 1.6 :inherit markup-gen-face))))
   `(markup-title-1-face ((t (:height 1.4 :inherit markup-gen-face))))
   `(markup-title-2-face ((t (:height 1.2 :inherit markup-gen-face))))
   `(markup-title-3-face ((t (:height 1.0 :inherit markup-gen-face))))
   `(markup-title-4-face ((t (:height 1.0 :inherit markup-gen-face))))
   `(markup-title-5-face ((t (:height 1.0 :inherit markup-gen-face))))

   ;; Highlight-indent-guides
   `(highlight-indent-guides-odd-face ((t (:background ,color-bg-alt))))
   `(highlight-indent-guides-even-face ((t (:background nil))))

   ;; Notmuch
   `(notmuch-search-unread-face ((t (:foreground ,color-bright))))
   `(notmuch-tag-face ((t (:foreground ,color-dark))))
   `(notmuch-tree-match-author-face ((t (:foreground ,color-middle))))
   `(notmuch-tree-no-match-face ((t (:foreground ,color-dark))))
   `(notmuch-tree-match-tag-face ((t (:inherit notmuch-tree-match-author-face))))
   `(notmuch-tag-unread-face ((t (:foreground ,color-bg :background ,color-dark))))
   `(notmuch-message-summary-face ((t (:foreground ,color-dark))))

   ;; Telega
   `(telega-msg-heading ((t (:foreground ,color-dark :background nil :inherit nil))))
   `(telega-msg-inline-reply ((t (:foreground ,color-bright :inherit nil))))
   `(telega-entity-type-texturl ((t (:inherit nil :foreground ,color-dark))))

   ;; Beancount
   `(beancount-date ((t (:inherit italic :foreground nil))))
   `(beancount-account ((t (:inherit default))))

   ;; W3m
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

   ;; Elfeed
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
