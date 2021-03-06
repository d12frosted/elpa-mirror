;;; mlso-theme.el --- A dark, medium contrast theme -*- lexical-binding :t; -*-

;; Version: 1.4
;; Package-Version: 20210215.1755
;; Package-Commit: 177a269d1f16dc5902f08d56d12a084ea028c8ab
;; URL: https://github.com/Mulling/mlso-theme
;; Author: github.com/Mulling
;; Package-Requires: ((emacs "24"))
;; SPDX-License-Identifier: WTFPL

;;; Commentary:

;;            _                 _   _                               _
;;  _ __ ___ | |___  ___       | |_| |__   ___ _ __ ___   ___   ___| |
;; | '_ ` _ \| / __|/ _ \ _____| __| '_ \ / _ \ '_ ` _ \ / _ \ / _ \ |
;; | | | | | | \__ \ (_) |_____| |_| | | |  __/ | | | | |  __/|  __/ |
;; |_| |_| |_|_|___/\___/       \__|_| |_|\___|_| |_| |_|\___(_)___|_|
;;
;; A dark, medium contrast theme with warm colors.

;; This work is licensed under the WTFPL. See <http://www.wtfpl.net/about/>.
;; This is also a work in progress, so things may change.

;;; Code:

(deftheme mlso
  "A dark, medium contrast theme.")

;; no terminal support - for now
(when window-system
 (let ((black       "#0A0B09")
       (light-black "#686250")
       (white       "#E1D7A0")
       (gray        "#292723")
       (red         "#FE7246")
       (green       "#43A047")
       (yellow      "#FE9D4D")
       (blue        "#83A598")
       (magenta     "#D73570")
       (cyan        "#83A5B3")
       (orange      "#FE8019")
       (salmon      "#D7875F"))

   (custom-theme-set-faces
    'mlso

    `(default     ((t :background ,black :foreground ,white)))
    `(cursor      ((t :background ,orange :foreground ,black)))
    `(fringe      ((t :inherit default :background ,black :foreground ,gray)))
    `(error       ((t :foreground ,red)))
    `(success     ((t :foreground ,green)))
    `(warning     ((t :foreground ,yellow)))
    `(header-line ((t :background ,gray)))

    ;; font lock
    `(font-lock-builtin-face           ((t :foreground ,blue)))
    `(font-lock-comment-face           ((t :foreground ,light-black)))
    `(font-lock-constant-face          ((t :foreground ,salmon)))
    `(font-lock-doc-face               ((t :foreground ,green)))
    `(font-lock-function-name-face     ((t :foreground ,yellow)))
    `(font-lock-keyword-face           ((t :foreground ,red)))
    `(font-lock-string-face            ((t :foreground ,green)))
    `(font-lock-type-face              ((t :foreground ,salmon)))
    `(font-lock-variable-name-face     ((t :foreground ,cyan)))
    `(font-lock-reference-face         ((t :foreground ,white)))
    `(font-lock-preprocessor-face      ((t :foreground ,yellow)))
    `(font-lock-warning-face           ((t :foreground ,red)))
    `(font-lock-negation-char-face     ((t :foregournd ,blue)))
    `(font-lock-comment-delimiter-face ((t :inherit font-lock-comment-face)))

    ;; search and highlight
    `(highlight           ((t :inverse-video t :extend t)))
    `(hl-line             ((t :inherit highlight)))
    `(secondary-selection ((t :inherit highlight)))
    `(isearch             ((t :inherit highlight)))
    `(lazy-highlight      ((t :inherit highlight)))
    `(match               ((t :inherit highlight)))
    `(region              ((t :inherit highlight)))
    `(minibuffer-prompt   ((t :foreground ,orange)))
    `(vertical-border     ((t :foreground ,gray)))
    `(isearch-fail        ((t :inherit error                  :strike-through t)))
    `(link                ((t :inherit font-lock-comment-face :underline t)))

    ;; company
    `(company-echo-common              ((t :inherit match)))
    `(company-preview                  ((t :inherit match)))
    `(company-preview-common           ((t :inherit match)))
    `(company-preview-search           ((t :inherit match)))
    `(company-scrollbar-bg             ((t :background ,gray)))
    `(company-scrollbar-fg             ((t :background ,white)))
    `(company-template-field           ((t :inherit region)))
    `(company-tooltip                  ((t :background ,gray :foreground ,white)))
    `(company-tooltip-annotation       ((t :underline t)))
    `(company-tooltip-common           ((t :background ,gray :underline t)))
    `(company-tooltip-common-selection ((t :underline t)))
    `(company-tooltip-mouse            ((t :inherit highlight)))
    `(company-tooltip-search           ((t :inherit match)))
    `(company-tooltip-selection        ((t :foreground ,orange)))

    ;; dired
    `(dired-directory  ((t :foreground ,blue)))
    `(dired-flagged    ((t :inherit error)))
    `(dired-header     ((t :foreground ,orange)))
    `(dired-mark       ((t :inherit success)))
    `(dired-marked     ((t :foreground ,magenta)))
    `(dired-perm-write ((t :foreground ,orange)))
    `(dired-symlink    ((t :foreground ,yellow)))
    `(dired-warning    ((t :inherit warning)))
    `(dired-ignored    ((t :inherit font-lock-comment-face)))

    ;; eshell
    `(eshell-ls-archive    ((t :inherit font-lock-comment-face)))
    `(eshell-ls-backup     ((t :inherit font-lock-comment-face)))
    `(eshell-ls-clutter    ((t :inherit font-lock-comment-face)))
    `(eshell-ls-archive    ((t :inherit font-lock-comment-face)))
    `(eshell-ls-product    ((t :inherit font-lock-comment-face)))
    `(eshell-ls-directory  ((t :foreground ,blue)))
    `(eshell-ls-executable ((t :foreground ,magenta)))
    `(eshell-ls-special    ((t :foreground ,magenta)))
    `(eshell-ls-symlink    ((t :foreground ,yellow)))
    `(eshell-prompt        ((t :foreground ,orange)))
    `(eshell-ls-missing    ((t :inherit error)))

    ;; flycheck
    `(flycheck-error                   ((t :inherit error   :underline t)))
    `(flycheck-info                    ((t :inherit success :underline t)))
    `(flycheck-warning                 ((t :inherit warning :underline t)))
    `(flycheck-error-list-checker-name ((t :foreground ,magenta)))
    `(flycheck-fringe-error            ((t :inherit error)))
    `(flycheck-fringe-info             ((t :inherit success)))
    `(flycheck-fringe-warning          ((t :inherit warning)))

    ;; magit
    `(magit-blame-time                  ((t :foreground ,green)))
    `(magit-blame-name                  ((t :foreground ,orange)))
    `(magit-blame-heading               ((t :foreground ,yellow)))
    `(magit-blame-hash                  ((t :foreground ,yellow)))
    `(magit-blame-summary               ((t :foreground ,yellow)))
    `(magit-blame-date                  ((t :foreground ,green)))
    `(magit-reflog-amend                ((t :foreground ,white)))
    `(magit-reflog-other                ((t :foreground ,white)))
    `(magit-reflog-rebase               ((t :foreground ,white)))
    `(magit-reflog-remote               ((t :foreground ,white)))
    `(magit-reflog-reset                ((t :foreground ,white)))
    `(magit-reflog-commit               ((t :foreground ,white)))
    `(magit-reflog-cherry-pick          ((t :foreground ,white)))
    `(magit-reflog-merge                ((t :foreground ,orange)))
    `(magit-branch                      ((t :foreground ,white)))
    `(magit-branch-current              ((t :foreground ,magenta)))
    `(magit-branch-local                ((t :foreground ,blue)))
    `(magit-branch-remote               ((t :foreground ,cyan)))
    `(magit-diff-file-header            ((t :foreground ,yellow)))
    `(magit-diff-file-heading           ((t :foreground ,blue)))
    `(magit-diff-file-heading-highlight ((t :foreground ,blue)))
    `(magit-diff-file-heading-selection ((t :foreground ,blue :background ,white)))
    `(magit-diff-hunk-heading           ((t :foreground ,yellow)))
    `(magit-diff-hunk-heading-highlight ((t :foreground ,yellow)))
    `(magit-diff-hunk-heading-selection ((t :foreground ,white)))
    `(magit-diff-added                  ((t :foreground ,green)))
    `(magit-diff-removed                ((t :foreground ,salmon)))
    `(magit-diff-context                ((t :foreground ,white)))
    `(magit-diff-added-highlight        ((t :foreground ,green :bold t)))
    `(magit-diff-removed-highlight      ((t :foreground ,salmon)))
    `(magit-diff-context-highlight      ((t :foreground ,light-black)))
    `(magit-diff-base                   ((t :foreground ,light-black)))
    `(magit-diff-base-highlight         ((t :foreground ,light-black)))
    `(magit-diff-lines-boundary         ((t :foreground ,white)))
    `(magit-diff-lines-heading          ((t :foreground ,white)))
    `(magit-hash                        ((t :foreground ,yellow)))
    `(magit-item-highlight              ((t :background ,light-black)))
    `(magit-log-author                  ((t :foreground ,orange)))
    `(magit-log-date                    ((t :foreground ,white)))
    `(magit-log-graph                   ((t :foreground ,gray)))
    `(magit-process-ng                  ((t :foreground ,orange)))
    `(magit-process-ok                  ((t :foreground ,yellow)))
    `(magit-section-heading             ((t :foreground ,orange)))
    `(magit-section-highlight           ((t :bold t)))
    `(magit-section-heading-selection   ((t :foreground ,orange)))
    `(magit-section-title               ((t :foreground ,orange)))
    `(magit-cherry-equivalent           ((t :foreground ,orange)))
    `(magit-cherry-unmatched            ((t :foreground ,gray)))
    `(magit-reflog-checkout             ((t :foreground ,blue)))
    `(magit-reflog-cherry-pick          ((t :foreground ,green)))
    `(magit-bisect-bad                  ((t :inherit error)))
    `(magit-bisect-good                 ((t :inherit success)))
    `(magit-bisect-skip                 ((t :foreground ,white)))
    `(magit-diff-conflict-heading       ((t :foreground ,white)))
    `(magit-dimmed                      ((t :foreground ,white)))

    ;; modeline
    `(mode-line           ((t :foreground ,white :background ,gray)))
    `(mode-line-inactive  ((t :foreground ,white :background ,gray)))
    `(mode-line-buffer-id ((t :foreground ,orange :background ,gray)))

    ;; term
    `(term               ((t :foreground ,white :background ,black)))
    `(term-color-black   ((t :foreground ,white)))
    `(term-color-blue    ((t :foreground ,blue)))
    `(term-color-cyan    ((t :foreground ,cyan)))
    `(term-color-green   ((t :foreground ,green)))
    `(term-color-magenta ((t :foreground ,magenta)))
    `(term-color-red     ((t :foreground ,red)))
    `(term-color-white   ((t :foreground ,black)))
    `(term-color-yellow  ((t :foreground ,yellow)))

    ;; line numbers
    `(line-number              ((t :inherit default :foreground ,light-black)))
    `(line-number-current-line ((t :inherit default :foreground ,orange :background ,gray)))

    ;; ido
    `(ido-first-match ((t :foreground ,orange)))
    `(ido-only-match  ((t :foreground ,orange)))
    `(ido-subdir      ((t :foreground ,blue)))
    `(ido-indicator   ((t :foreground ,black :background ,green)))

    ;; show-paren
    `(show-paren-match    ((t :inherit cursor)))
    `(show-paren-mismatch ((t :inherit error)))

    ;; slime
    `(slime-repl-inputed-output-face ((t :foreground ,white)))

    ;; which key
    `(which-key-key-face                   ((t :foreground ,blue)))
    `(which-key-separator-face             ((t :foreground ,orange)))
    `(which-key-note-face                  ((t :foreground ,white)))
    `(which-key-command-description-face   ((t :foreground ,white)))
    `(which-key-local-map-description-face ((t :foreground ,white)))
    `(which-key-highlighted-command-face   ((t :foreground ,yellow)))
    `(which-key-group-description-face     ((t :foreground ,red)))
    `(which-key-special-key-face           ((t :foreground ,magenta)))
    `(which-key-docstring-face             ((t :foreground ,green)))

    ;; completions
    `(completions-first-difference ((t :foreground ,white, :bold t)))
    `(completions-common-part      ((t :foreground ,blue)))
    `(completions-annotations      ((t :foreground ,white)))

    ;; compilation
    `(compilation-error          ((t :inherit error)))
    `(compilation-warning        ((t :inherit warning)))
    `(compilation-info           ((t :foreground ,green)))
    `(compilation-mode-line-fail ((t :foreground ,red)))
    `(compilation-mode-line-run  ((t :foreground ,yellow)))
    `(compilation-mode-line-exit ((t :foreground ,green)))
    `(compilation-line-number    ((t :foreground ,orange)))
    `(compilation-column-number  ((t :foreground ,cyan)))

    ;; markdown mode
    `(markdown-markup-face             ((t :foreground ,light-black)))
    `(markdown-header-rule-face        ((t :foreground ,light-black)))
    `(markdown-header-delimiter-face   ((t :foreground ,cyan)))
    `(markdown-list-face               ((t :foreground ,cyan)))
    `(markdown-blockquote-face         ((t :foreground ,cyan)))
    `(markdown-code-face               ((t :foreground ,salmon)))
    `(markdown-inline-code-face        ((t :foreground ,salmon)))
    `(markdown-pre-face                ((t :foreground ,salmon)))
    `(markdown-table-face              ((t :foreground ,white)))
    `(markdown-language-keyword-face   ((t :foreground ,red)))
    `(markdown-language-info-face      ((t :foreground ,green)))
    `(markdown-link-face               ((t :foreground ,blue)))
    `(markdown-missing-link-face       ((t :foreground ,blue :strike-through t)))
    `(markdown-reference-face          ((t :foreground ,green)))
    `(markdown-footnote-marker-face    ((t :foreground ,light-black)))
    `(markdown-footnote-text-face      ((t :foreground ,white)))
    `(markdown-url-face                ((t :foreground ,green)))
    `(markdown-plain-url-face          ((t :foreground ,green)))
    `(markdown-link-title-face         ((t :foreground ,green)))
    `(markdown-line-break-face         ((t :foregronnd ,green)))
    `(markdown-comment-face            ((t :foreground ,light-black)))
    `(markdown-math-face               ((t :foreground ,magenta)))
    `(markdown-metadata-key-face       ((t :foreground ,green)))
    `(markdown-metadata-value-face     ((t :foreground ,green)))
    `(markdown-gfm-checkbox-face       ((t :foreground ,blue)))
    `(markdown-highlight-face          ((t :inherit highlight)))
    `(markdown-hr-face                 ((t :foreground ,light-black)))
    `(markdown-html-tag-name-face      ((t :foreground ,red)))
    `(markdown-html-tag-delimiter-face ((t :foreground ,white)))
    `(markdown-html-attr-name-face     ((t :foreground ,cyan)))
    `(markdown-html-attr-value-face    ((t :foreground ,green)))
    `(markdown-html-entity-face        ((t :foreground ,yellow)))
    `(markdown-header-face             ((t :foreground ,yellow :bold t)))
    )))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'mlso)
(provide 'mlso-theme)

;;; mlso-theme.el ends here
