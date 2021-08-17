;;; notink-theme.el --- A custom theme inspired by e-ink displays -*- lexical-binding: t -*-

;; Copyright (C) 2021 MetroWind.

;; This program is free software. It comes without any warranty, to
;; the extent permitted by applicable law. You can redistribute it
;; and/or modify it under the terms of the Do What the Fuck You Want
;; to Public License, Version 2, as published by Sam Hocevar. See
;; http://www.wtfpl.net/ for more details.

;; Author: MetroWind <chris.corsair@gmail.com>
;; URL: https://github.com/MetroWind/notink-theme
;; Package-Version: 20210816.2337
;; Package-Commit: ede878ee06d4f94b5819ed3ccffe121823fbcf44
;; Keywords: faces
;; Version: 1.0
;; Package-Requires: ((emacs "26.1"))

;;; Commentary:
;;
;; Notink theme is a custom theme for Emacs. Inspired by e-ink displays,
;; it aims to be a comfortable grey-scale theme.

;;; Code:

(deftheme notink "A custom theme inspired by e-ink displays")

;; Colors
(let* ((color-fg "#4c5256")
       (color-bg "#c4cdd3")
       (color-bright "#ffffff")
       (color-black "#35393b")
       (color-dark "#616b72")
       (color-middle "#83919a")
       (color-light "#a9b5bd"))

  (custom-theme-set-faces
   'notink
   `(default ((t (:background ,color-bg
                  :foreground ,color-fg))))
   `(cursor ((t (:background ,color-fg
                 :foreground ,color-bg))))
   `(region ((t (:background ,color-fg
                 :foreground ,color-bg))))
   `(mode-line ((t (:background ,color-dark
                    :foreground ,color-bg
                    :box nil))))
   `(mode-line-buffer-id ((t (:foreground ,color-bg))))
   `(mode-line-inactive ((t (:background ,color-fg
                             :foreground ,color-bg))))
   `(fringe ((t (:background ,color-bg))))
   `(minibuffer-prompt ((t (:inherit italic :foreground ,color-dark))))
   `(font-lock-builtin-face ((t (:foreground ,color-dark))))
   `(font-lock-comment-face ((t (:inherit italic :foreground ,color-middle))))
   `(font-lock-doc-face ((t (:inherit font-lock-comment-face))))
   `(font-lock-constant-face ((t (:inherit italic :foreground ,color-dark))))
   `(font-lock-function-name-face ((t (:foreground ,color-black))))
   `(font-lock-keyword-face ((t (:foreground ,color-fg :inherit italic))))
   `(font-lock-string-face ((t (:foreground ,color-dark))))
   `(font-lock-type-face ((t (:foreground ,color-dark))))
   `(font-lock-variable-name-face ((t (:foreground ,color-fg))))
   `(font-lock-warning-face
     ((t (:foreground ,color-fg :background ,color-bright))))

   `(isearch ((t (:background ,color-middle
                  :foreground ,color-bg))))
   `(isearch-fail ((t (:inherit default))))

   `(lazy-highlight ((t (:background ,color-bright))))
   `(link ((t (:foreground ,color-dark :underline t))))
   `(link-visited ((t (:foreground ,color-middle :underline t))))
   `(button ((t (:background ,color-bright :underline t :foreground nil))))
   `(header-line ((t (:background ,color-light :foreground ,color-fg))))
   `(shadow ((t (:foreground ,color-middle))))
   `(show-paren-match ((t (:background ,color-dark :foreground ,color-bg))))
   `(show-paren-mismatch ((t (:background ,color-bright
                              :foreground ,color-fg))))
   `(highlight ((t (:inverse-video nil :background ,color-bright))))
   `(hl-line ((t (:inverse-video nil :background ,color-light))))
   `(widget-field ((t (:background ,color-bright))))

   ;; Faces for specific prog modes
   `(sh-heredoc ((t (:foreground nil :inherit font-lock-string-face))))

   ;; Dired
   `(dired-directory ((t (:foreground ,color-dark))))
   `(dired-symlink ((t (:foreground ,color-middle))))
   `(dired-perm-write ((t (:background ,color-bright))))

   ;; Diff
   `(diff-added ((t (:foreground unspecified :background ,color-bright))))
   `(diff-removed ((t (:foreground ,color-bg :background ,color-dark))))
   ;; `(diff-context ((t (:background nil))))
   `(diff-file-header ((t (:bold t :background ,color-light :weight bold))))
   `(diff-header ((t (:background ,color-light :foreground ,color-fg))))

   ;; Whitespace
   `(whitespace-trailing ((t (:background ,color-light))))
   `(whitespace-line ((t (:background ,color-light :foreground unspecified))))

   ;; ERC
   `(erc-notice-face ((t (:foreground ,color-dark
                          :weight unspecified))))
   `(erc-header-line ((t (:inherit header-line))))
   `(erc-timestamp-face ((t (:foreground ,color-middle :weight unspecified))))
   `(erc-current-nick-face ((t (:background ,color-dark :foreground ,color-bg
                                :weight unspecified))))
   `(erc-input-face ((t (:foreground ,color-dark))))
   `(erc-prompt-face ((t (:foreground ,color-middle
                          :background nil
                          :inherit italic
                          :weight unspecified))))
   `(erc-my-nick-face ((t (:foreground ,color-black))))
   `(erc-pal-face ((t (:foreground ,color-dark :inherit italic))))

   ;; Rainbow delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,color-fg))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,color-middle))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,color-fg))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,color-middle))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground ,color-fg))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,color-middle))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,color-fg))))
   `(rainbow-delimiters-unmatched-face ((t (:background ,color-bright))))

   ;; Magit
   `(magit-branch-local ((t (:foreground ,color-dark :background nil))))
   `(magit-branch-remote ((t (:foreground ,color-dark :background nil))))
   `(magit-tag ((t (:foreground ,color-dark :background nil :inherit italic))))
   `(magit-hash ((t (:foreground ,color-middle))))
   `(magit-section-title ((t (:foreground ,color-fg :background nil))))
   `(magit-section-heading ((t (:background nil :foreground ,color-fg))))
   `(magit-section-highlight ((t (:background nil))))
   `(magit-item-highlight ((t (:foreground ,color-fg
                               :background ,color-bright))))
   `(magit-log-author ((t (:foreground ,color-dark))))
   `(magit-diff-added ((t (:inherit diff-added))))
   `(magit-diff-added-highlight ((t (:inherit magit-diff-added))))
   `(magit-diff-removed ((t (:inherit diff-removed))))
   `(magit-diff-removed-highlight ((t (:inherit magit-diff-removed))))
   `(magit-diff-context ((t (:inherit diff-context))))
   `(magit-diff-context-highlight ((t (:inherit magit-diff-context))))
   `(magit-popup-argument ((t (:inherit font-lock-function-name-face))))
   `(magit-popup-disabled-argument ((t (:inherit font-lock-comment-face))))
   `(magit-diff-hunk-heading
     ((t (:background unspecified :foreground unspecified
          :inherit header-line))))
   `(magit-diff-hunk-heading-highlight
     ((t (:background unspecified :foreground unspecified
          :inherit magit-diff-hunk-heading))))

   ;; Git-gutter-fringe
   `(git-gutter-fr:modified ((t (:foreground ,color-dark))))
   `(git-gutter-fr:added ((t (:foreground ,color-dark))))
   `(git-gutter-fr:deleted ((t (:foreground ,color-dark))))

   ;; Company
   `(company-preview ((t (:foreground ,color-fg :background nil))))
   `(company-preview-common ((t (:foreground ,color-fg :background nil))))
   `(company-tooltip ((t (:foreground ,color-fg :background ,color-bright))))
   `(company-tooltip-common ((t (:foreground ,color-middle))))
   `(company-tooltip-selection ((t (:background ,color-bg))))
   `(company-tooltip-common-selection ((t (:foreground ,color-middle))))
   `(company-tooltip-annotation ((t (:foreground ,color-dark))))
   `(company-scrollbar-bg ((t (:background ,color-bright))))
   `(company-scrollbar-fg ((t (:background ,color-bg))))

   ;; Powerline
   `(powerline-active2 ((t (:foreground ,color-fg :background ,color-bg))))
   `(powerline-active1 ((t (:foreground ,color-bg :background ,color-dark))))
   `(powerline-inactive2 ((t (:foreground ,color-bg
                              :background ,color-middle))))
   `(powerline-inactive1 ((t (:foreground ,color-fg
                              :background ,color-middle))))

   ;; Smart mode line
   `(sml/global  ((t (:foreground ,color-bg))))
   `(sml/charging ((t (:foreground ,color-bg))))
   `(sml/discharging ((t (:foreground ,color-bg))))
   `(sml/read-only ((t (:foreground ,color-bg))))
   `(sml/filename ((t (:foreground ,color-bg :weight bold))))
   `(sml/prefix ((t (:foreground ,color-bg :weight normal :inherit italic))))
   `(sml/modes ((t (:foreground ,color-bg :weight bold))))
   `(sml/modified ((t (:foreground ,color-bg))))
   `(sml/outside-modified ((t (:foreground ,color-bg :background ,color-fg))))
   `(sml/position-percentage ((t (:foreground ,color-bg :slant normal))))

   ;; Helm
   `(helm-candidate-number ((t (:foreground ,color-fg :background nil))))
   `(helm-source-header ((t (:inherit font-lock-comment-face
                             :background unspecified :foreground unspecified))))
   `(helm-selection ((t (:inherit region :distant-foreground nil
                         :background nil))))
   `(helm-prefarg ((t (:foreground ,color-dark))))
   `(helm-ff-file ((t (:inherit default))))
   `(helm-ff-directory ((t (:inherit dired-directory :foreground unspecified))))
   `(helm-ff-executable ((t (:foreground unspecified))))
   `(helm-ff-file-extension ((t (:foreground nil :background nil))))
   `(helm-ff-invalid-symlink ((t (:inherit dired-symlink :foreground unspecified
                                  :background ,color-bright))))
   `(helm-ff-symlink ((t (:inherit dired-symlink :foreground unspecified))))
   `(helm-ff-prefix ((t (:background nil))))
   `(helm-ff-dotted-directory ((t (:background nil :foreground ,color-light))))
   `(helm-M-x-key ((t (:foreground ,color-middle))))
   `(helm-buffer-file ((t (:foreground ,color-fg))))
   `(helm-buffer-archive ((t (:inherit helm-buffer-file))))
   `(helm-buffer-directory ((t (:foreground ,color-dark :background nil))))
   `(helm-buffer-not-saved
     ((t (:inherit helm-buffer-file :foreground unspecified
          :background ,color-bright))))
   `(helm-buffer-saved-out ((t (:inherit helm-buffer-not-saved))))
   `(helm-buffer-modified ((t (:foreground ,color-dark))))
   `(helm-buffer-process ((t (:foreground ,color-dark))))
   `(helm-buffer-size ((t (:foreground ,color-middle))))
   `(helm-match ((t (:inherit italic))))

   ;; TeX
   `(font-latex-sedate-face ((t (:foreground ,color-dark))))
   `(font-latex-math-face ((t (:inherit default))))
   `(font-latex-script-char-face ((t (:inherit font-latex-math-face))))

   ;; adoc-mode
   `(markup-meta-hide-face ((t (:height 1.0 :foreground ,color-middle))))
   `(markup-meta-face ((t (:height 1.0 :foreground ,color-dark :family nil))))
   `(markup-reference-face ((t (:underline nil :foreground ,color-dark))))
   `(markup-gen-face ((t (:inherit default :foreground nil))))
   `(markup-passthrough-face ((t (:inherit markup-dark))))
   `(markup-replacement-face ((t (:family nil :foreground ,color-dark))))
   `(markup-list-face ((t (:weight bold))))
   `(markup-secondary-text-face ((t (:height 1.0 :foreground ,color-dark))))
   `(markup-verbatim-face ((t (:foreground ,color-dark))))
   `(markup-code-face ((t (:inherit markup-verbatim-face))))
   `(markup-typewriter-face ((t (:inherit nil))))
   `(markup-complex-replacement-face
     ((t (:background ,color-light :foreground ,color-fg))))
   `(markup-title-0-face ((t (:height 1.728 :inherit markup-gen-face))))
   `(markup-title-1-face ((t (:height 1.44 :inherit markup-gen-face))))
   `(markup-title-2-face ((t (:height 1.2 :inherit markup-gen-face))))
   `(markup-title-3-face ((t (:height 1.0 :inherit markup-gen-face))))
   `(markup-title-4-face ((t (:height 1.0 :inherit markup-gen-face))))
   `(markup-title-5-face ((t (:height 1.0 :inherit markup-gen-face))))

   ;; Outline
   `(outline-1 ((t (:height 1.44 :foreground nil))))
   `(outline-2 ((t (:height 1.2 :foreground nil))))
   `(outline-3 ((t (:foreground nil))))
   `(outline-4 ((t (:foreground nil))))
   `(outline-5 ((t (:foreground nil))))
   `(outline-6 ((t (:foreground nil))))
   `(outline-7 ((t (:foreground nil))))
   `(outline-8 ((t (:foreground nil))))

   ;; Org-mode
   `(org-hide ((t (:foreground ,color-bg))))
   `(org-table ((t (:foreground ,color-fg))))
   `(org-code ((t (:foreground ,color-dark))))
   `(org-date ((t (:foreground ,color-middle))))
   `(org-done ((t (:weight normal :foreground ,color-middle))))
   `(org-todo ((t (:weight normal :foreground nil :background ,color-bright))))
   `(org-latex-and-related ((t (:foreground ,color-dark :italic t))))
   `(org-checkbox ((t (:weight normal :foreground ,color-middle))))
   `(org-verbatim ((t (:foreground ,color-dark))))
   `(org-mode-line-clock ((t (:background nil))))
   `(org-document-title ((t (:weight normal :foreground nil))))
   `(org-drawer ((t (:foreground ,color-middle))))
   `(org-block ((t (:foreground ,color-dark))))
   `(org-block-begin-line ((t (:inherit font-lock-comment-face))))
   `(org-block-end-line ((t (:inherit font-lock-comment-face))))
   `(org-archived ((t (:foreground ,color-middle))))

   ;; org-tree-slide
   `(org-tree-slide-header-overlay-face
     ((t (:inherit font-lock-comment-face :foreground nil :background nil))))

   ;; Message
   `(message-header-name ((t (:foreground ,color-dark))))
   `(message-header-other ((t (:foreground ,color-middle))))
   `(message-header-cc ((t (:inherit message-header-other))))
   `(message-header-newsgroups ((t (:inherit message-header-other))))
   `(message-header-xheader ((t (:inherit message-header-other))))
   `(message-header-subject ((t (:inherit default))))
   `(message-header-to ((t (:foreground ,color-dark))))
   `(message-cited-text ((t (:foreground ,color-middle :inherit italic))))
   `(message-mml ((t (:foreground ,color-middle))))

   ;; Notmuch
   `(notmuch-search-unread-face ((t (:foreground ,color-dark))))
   `(notmuch-tag-face ((t (:foreground ,color-middle))))
   `(notmuch-tree-match-author-face ((t (:foreground ,color-dark))))
   `(notmuch-tree-no-match-face ((t (:foreground ,color-middle))))
   `(notmuch-tree-match-tag-face
     ((t (:inherit notmuch-tree-match-author-face))))
   `(notmuch-tag-unread-face
     ((t (:foreground ,color-fg :background ,color-bright))))
   `(notmuch-message-summary-face ((t (:foreground ,color-middle))))

   ;; Compilation
   `(compilation-error ((t (:foreground ,color-fg :background ,color-bright))))
   `(compilation-info ((t (:foreground ,color-middle))))
   `(compilation-warning ((t (:foreground ,color-dark))))

   ;; Highlight-indent-guides
   `(highlight-indent-guides-odd-face ((t (:background ,color-bright))))
   `(highlight-indent-guides-even-face ((t (:background nil))))

   ;; Telega
   `(telega-msg-heading ((t (:background nil :foreground ,color-dark
                             :inherit nil))))
   `(telega-msg-inline-reply ((t (:foreground ,color-middle :inherit nil))))
   `(telega-entity-type-texturl ((t (:inherit nil :foreground ,color-dark))))

   ;; Beancount
   `(beancount-date ((t (:inherit italic :foreground nil))))
   `(beancount-account ((t (:inherit default))))

   ;; LSP
   `(lsp-headerline-breadcrumb-path-face ((t (:foreground ,color-fg))))
   `(lsp-headerline-breadcrumb-path-error-face
     ((t (:underline nil :background ,color-bright))))
   `(lsp-headerline-breadcrumb-separator-face ((t (:foreground ,color-fg))))

   ;; Flymake
   `(flymake-error ((t (:underline (:style wave :color ,color-bright)))))
   `(flymake-warning ((t (:underline (:style wave :color ,color-middle)))))

   ;; Flycheck
   `(flycheck-error ((t (:inherit flymake-error))))
   `(flycheck-warning ((t (:inherit flymake-warning))))))

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'notink)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; notink-theme.el ends here
