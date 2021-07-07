;;; acme-theme.el --- A color theme for Emacs based on Acme & Sam from Plan 9
;; Package-Version: 20200601.402
;; Package-Commit: 680b2022445861e3e9030a96d9fe587188d778c8

;; Copyright (C) 2020 Ian Yi-En Pan

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

;;; Credits:
;; This theme was modified from plan9-theme.el by John Louis Del Rosario

;;; Code:

(deftheme acme "Theme inspired by Acme")

;;; Color Palette

(defvar acme-colors-alist
  '(("bg"            . "#FFFFE8") ; default bg
    ("bg-alt"        . "#FFFFD8")
    ("bg-alt2"       . "#eFeFd8")
    ("bg-dark"       . "#E5E5D0")
    ("fg"            . "#444444") ; default fg
    ("fg-alt"        . "#B8B09A")
    ("fg-alt-dark"   . "#988d6d")
    ("fg-light"      . "#CCCCB7")
    ("highlight"     . "#e8eb98")

    ("acme-cyan"          . "#007777")
    ("acme-cyan-light"    . "#a8efeb")
    ("acme-red"           . "#880000")
    ("acme-red-light"     . "#f8e8e8")
    ("acme-yellow"        . "#888838")
    ("acme-yellow-light"  . "#f8fce8")
    ("acme-green"         . "#005500")
    ("acme-green-alt"     . "#006600")
    ("acme-green-light"   . "#e8fce8")
    ("acme-blue"          . "#1054af")
    ("acme-blue-light"    . "#e1faff")
    ("acme-purple"        . "#555599")
    ("acme-purple-light"  . "#ffeaff")))

(defmacro acme/with-color-variables (&rest body)
  "`let' bind all colors defined in `acme-colors-alist' around BODY.
Also bind `class' to ((class color) (min-colors 89))."
  (declare (indent 0))
  `(let ((class '((class color) (min-colors 89)))
         ,@(mapcar (lambda (cons)
                     (list (intern (car cons)) (cdr cons)))
                   acme-colors-alist))
     ,@body))

;;; Theme Faces
(acme/with-color-variables
  (custom-theme-set-faces
   'acme

;;;; Built-in

;;;;; basic coloring
   '(button                                       ((t (:underline t))))
   `(link                                         ((t (:foreground ,acme-blue :underline t :weight normal))))
   `(link-visited                                 ((t (:foreground ,acme-purple :underline t :weight normal))))
   `(default                                      ((t (:foreground ,fg :background ,bg))))
   `(cursor                                       ((t (:foreground ,bg :background ,fg))))
   `(escape-glyph                                 ((t (:foreground ,acme-cyan-light :bold nil))))
   `(fringe                                       ((t (:foreground ,fg :background ,bg))))
   `(line-number                                  ((t (:foreground ,fg :background ,bg-alt2))))
   `(line-number-current-line                     ((t (:foreground ,fg :background ,bg-alt2))))
   `(header-line                                  ((t (:foreground ,fg :background ,acme-blue-light :box t))))
   `(highlight                                    ((t (:background ,highlight))))
   `(success                                      ((t (:foreground ,acme-green :weight normal))))
   `(warning                                      ((t (:foreground ,acme-red :weight normal))))

;;;;; compilation
   `(compilation-column-face                      ((t (:foreground ,acme-yellow :background ,acme-yellow-light))))
   `(compilation-column-number                    ((t (:foreground ,acme-yellow :background ,acme-yellow-light))))
   `(compilation-error-face                       ((t (:foreground ,acme-red :weight normal :underline t))))
   `(compilation-face                             ((t (:foreground ,fg))))
   `(compilation-info-face                        ((t (:foreground ,acme-blue))))
   `(compilation-info                             ((t (:foreground ,acme-blue :underline t))))
   `(compilation-line-face                        ((t (:foreground ,acme-purple))))
   `(compilation-line-number                      ((t (:foreground ,acme-yellow :background ,acme-yellow-light))))
   `(compilation-message-face                     ((t (:foreground ,acme-blue))))
   `(compilation-warning-face                     ((t (:foreground ,acme-yellow :weight normal :underline t))))
   `(compilation-mode-line-exit                   ((t (:foreground ,acme-cyan :weight normal))))
   `(compilation-mode-line-fail                   ((t (:foreground ,acme-red :weight normal))))
   `(compilation-mode-line-run                    ((t (:foreground ,acme-purple :weight normal))))

;;;;; grep
   `(grep-context-face                            ((t (:foreground ,fg-alt))))
   `(grep-error-face                              ((t (:foreground ,acme-red :weight normal :underline t))))
   `(grep-hit-face                                ((t (:foreground ,acme-purple :weight normal))))
   `(grep-match-face                              ((t (:foreground ,acme-cyan :weight normal))))
   `(match                                        ((t (:background ,acme-cyan :foreground ,acme-cyan-light))))

;;;;; ag
   `(ag-hit-face                                  ((t (:foreground ,acme-green :weight normal))))
   `(ag-match-face                                ((t (:foreground ,acme-cyan :background ,acme-cyan-light :weight normal))))

;;;;; isearch
   `(isearch                                      ((t (:foreground ,fg :weight normal :background ,acme-cyan-light))))
   `(isearch-fail                                 ((t (:foreground ,fg :weight normal :background ,acme-red))))
   `(lazy-highlight                               ((t (:foreground ,fg :weight normal :background ,acme-blue-light))))

   `(menu                                         ((t (:foreground ,bg :background ,fg))))
   `(minibuffer-prompt                            ((t (:foreground ,fg :weight normal))))
   `(region                                       ((,class (:background ,highlight :foreground ,fg)) (t :inverse-video t)))
   `(secondary-selection                          ((t (:background ,acme-green-light))))
   `(trailing-whitespace                          ((t (:background ,acme-red-light))))
   `(vertical-border                              ((t (:foreground ,acme-cyan))))

;;;;; font lock
   `(font-lock-builtin-face                       ((t (:foreground ,fg :weight normal))))
   `(font-lock-function-name-face                 ((t (:foreground ,fg :weight normal))))
   `(font-lock-string-face                        ((t (:foreground ,acme-red))))
   `(font-lock-keyword-face                       ((t (:foreground ,acme-blue :weight bold)))) ; if, else, for, while, return...
   `(font-lock-type-face                          ((t (:foreground ,fg :weight bold)))) ; int, float, string, void...
   `(font-lock-constant-face                      ((t (:foreground ,fg :weight bold)))) ; NULL, nullptr, true, false...
   `(font-lock-variable-name-face                 ((t (:foreground ,fg :weight normal))))
   `(font-lock-comment-face                       ((t (:foreground ,acme-green :italic nil))))
   `(font-lock-comment-delimiter-face             ((t (:foreground ,acme-green :italic nil))))
   `(font-lock-doc-face                           ((t (:foreground ,acme-yellow :italic nil))))
   `(font-lock-negation-char-face                 ((t (:foreground ,acme-red :weight normal))))
   `(font-lock-preprocessor-face                  ((t (:foreground ,acme-red :weight normal))))
   `(font-lock-regexp-grouping-construct          ((t (:foreground ,acme-purple :weight normal))))
   `(font-lock-regexp-grouping-backslash          ((t (:foreground ,acme-purple :weight normal))))
   `(font-lock-warning-face                       ((t (:foreground ,acme-red :weight normal))))

 ;;;; table
   `(table-cell                                   ((t (:background ,bg-alt2))))

 ;;;; ledger
   `(ledger-font-directive-face                   ((t (:foreground ,acme-cyan))))
   `(ledger-font-periodic-xact-face               ((t (:inherit ledger-font-directive-face))))
   `(ledger-font-posting-account-face             ((t (:foreground ,acme-blue))))
   `(ledger-font-posting-amount-face              ((t (:foreground ,acme-red))))
   `(ledger-font-posting-date-face                ((t (:foreground ,acme-red :weight normal))))
   `(ledger-font-payee-uncleared-face             ((t (:foreground ,acme-purple))))
   `(ledger-font-payee-cleared-face               ((t (:foreground ,fg))))
   `(ledger-font-payee-pending-face               ((t (:foreground ,acme-yellow))))
   `(ledger-font-xact-highlight-face              ((t (:background ,bg-alt2))))

;;;; Third-party


;;;;; anzu
   `(anzu-mode-line                               ((t (:foreground ,acme-yellow :background ,acme-yellow-light :weight normal))))

;;;;; clojure-mode
   `(clojure-interop-method-face                  ((t (:inherit font-lock-function-name-face))))

;;;;; clojure-test-mode
   `(clojure-test-failure-face                    ((t (:foreground ,acme-red :weight normal :underline t))))
   `(clojure-test-error-face                      ((t (:foreground ,acme-red :weight normal :underline t))))
   `(clojure-test-success-face                    ((t (:foreground ,acme-green :weight normal :underline t))))

;;;;; diff
   `(diff-added                                   ((,class (:foreground ,fg :background ,acme-green-light))
                                                   (t (:foreground ,fg :background ,acme-green-light))))
   `(diff-changed                                 ((t (:foreground ,acme-yellow))))
   `(diff-context                                 ((t (:foreground ,fg))))
   `(diff-removed                                 ((,class (:foreground ,fg :background ,acme-red-light))
                                                   (t (:foreground ,fg :background ,acme-red-light))))
   `(diff-refine-added                            ((t :inherit diff-added :background ,acme-green-light :weight normal)))
   `(diff-refine-change                           ((t :inherit diff-changed :weight normal)))
   `(diff-refine-removed                          ((t :inherit diff-removed :background ,acme-red-light :weight normal)))
   `(diff-header                                  ((,class (:foreground ,fg :weight normal))
                                                   (t (:foreground ,acme-purple-light :weight normal))))
   `(diff-file-header                             ((,class (:foreground ,fg :background ,acme-cyan-light :weight normal))
                                                   (t (:foreground ,fg :background ,acme-cyan-light :weight normal))))
   `(diff-hunk-header                             ((,class (:foreground ,acme-green :weight normal))
                                                   (t (:foreground ,acme-green :weight normal))))
;;;;; dired/dired+/dired-subtree
   `(dired-directory                              ((t (:foreground ,acme-blue :weight bold))))
   `(diredp-display-msg                           ((t (:foreground ,acme-blue))))
   `(diredp-compressed-file-suffix                ((t (:foreground ,acme-purple))))
   `(diredp-date-time                             ((t (:foreground ,acme-green))))
   `(diredp-deletion                              ((t (:foreground ,acme-red))))
   `(diredp-deletion-file-name                    ((t (:foreground ,acme-red))))
   `(diredp-dir-heading                           ((t (:foreground ,acme-blue :background ,acme-blue-light :weight bold))))
   `(diredp-dir-priv                              ((t (:foreground ,acme-blue))))
   `(diredp-exec-priv                             ((t (:foreground ,acme-yellow))))
   `(diredp-executable-tag                        ((t (:foreground ,acme-yellow))))
   `(diredp-file-name                             ((t (:foreground ,fg))))
   `(diredp-file-suffix                           ((t (:foreground ,acme-yellow))))
   `(diredp-flag-mark                             ((t (:foreground ,acme-cyan))))
   `(diredp-flag-mark-line                        ((t (:foreground ,acme-cyan))))
   `(diredp-ignored-file-name                     ((t (:foreground ,fg-light))))
   `(diredp-link-priv                             ((t (:foreground ,acme-purple))))
   `(diredp-mode-line-flagged                     ((t (:foreground ,acme-yellow))))
   `(diredp-mode-line-marked                      ((t (:foreground ,acme-yellow))))
   `(diredp-no-priv                               ((t (:foreground ,fg))))
   `(diredp-number                                ((t (:foreground ,acme-blue))))
   `(diredp-other-priv                            ((t (:foreground ,fg))))
   `(diredp-rare-priv                             ((t (:foreground ,fg))))
   `(diredp-read-priv                             ((t (:foreground ,fg))))
   `(diredp-symlink                               ((t (:foreground ,fg :background ,acme-blue-light))))
   `(diredp-write-priv                            ((t (:foreground ,fg))))
   `(diredp-dir-name                              ((t (:foreground ,acme-blue :weight bold))))
   `(dired-subtree-depth-1-face                   ((t (:background ,bg))))
   `(dired-subtree-depth-2-face                   ((t (:background ,bg))))
   `(dired-subtree-depth-3-face                   ((t (:background ,bg))))

;;;;; elfeed
   `(elfeed-search-date-face                      ((t (:foreground ,acme-blue))))
   `(elfeed-search-title-face                     ((t (:foreground ,fg))))
   `(elfeed-search-unread-title-facee             ((t (:foreground ,fg))))
   `(elfeed-search-feed-face                      ((t (:foreground ,acme-green))))
   `(elfeed-search-tag-face                       ((t (:foreground ,acme-red))))
   `(elfeed-search-unread-count-face              ((t (:foreground ,fg))))

;;;;; erc
   `(erc-default-face                             ((t (:foreground ,fg))))
   `(erc-header-line                              ((t (:inherit header-line))))
   `(erc-action-face                              ((t (:inherit erc-default-face))))
   `(erc-bold-face                                ((t (:inherit erc-default-face :weight normal))))
   `(erc-underline-face                           ((t (:underline t))))
   `(erc-error-face                               ((t (:inherit font-lock-warning-face))))
   `(erc-prompt-face                              ((t (:foreground ,acme-green :background ,acme-green-light :weight normal))))
   `(erc-timestamp-face                           ((t (:foreground ,acme-green :background ,acme-green-light))))
   `(erc-direct-msg-face                          ((t (:inherit erc-default))))
   `(erc-notice-face                              ((t (:foreground ,fg-light))))
   `(erc-highlight-face                           ((t (:background ,highlight))))

   `(erc-input-face                               ((t (:foreground ,fg :background ,bg-alt2))))
   `(erc-current-nick-face                        ((t (:foreground ,fg :background ,acme-cyan-light :weight normal :box (:line-width 1 :style released-button)))))
   `(erc-nick-default-face                        ((t (:weight normal :background ,bg-alt2))))
   `(erc-my-nick-face                             ((t (:foreground ,fg :background ,acme-cyan-light :weight normal :box (:line-width 1 :style released-button)))))
   `(erc-nick-msg-face                            ((t (:inherit erc-default))))
   `(erc-fool-face                                ((t (:inherit erc-default))))
   `(erc-pal-face                                 ((t (:foreground ,acme-purple :weight normal))))

   `(erc-dangerous-host-face                      ((t (:inherit font-lock-warning-face))))
   `(erc-keyword-face                             ((t (:foreground ,acme-yellow :weight normal))))

  ;;;;; evil
   `(evil-search-highlight-persist-highlight-face ((t (:inherit lazy-highlight))))

;;;;; flx
   `(flx-highlight-face                           ((t (:foreground ,acme-yellow :background ,acme-green-light :weight normal :underline t))))

;;;;; company
   `(company-tooltip                              ((t (:background ,acme-blue-light))))
   `(company-tooltip-selection                    ((t (:background ,acme-cyan-light))))
   `(company-tooltip-common-selection             ((t (:foreground ,acme-blue :background ,acme-cyan-light :bold t))))
   `(company-tooltip-mouse                        ((t (:background ,acme-blue-light))))
   `(company-tooltip-search                       ((t (:foreground ,acme-red))))
   `(company-tooltip-common                       ((t (:foreground ,acme-blue :bold t))))
   `(company-tooltip-annotation                   ((t (:foreground ,acme-yellow :italic t)))) ; parameter hints etc.
   `(company-tooltip-annotation-selection         ((t (:foreground ,acme-yellow :italic t))))
   `(company-scrollbar-fg                         ((t (:background ,acme-cyan))))
   `(company-scrollbar-bg                         ((t (:background ,acme-cyan-light))))
   `(company-preview                              ((t (:foreground ,fg :background ,acme-cyan-light))))
   `(company-preview-common                       ((t (:foreground ,fg :background ,acme-cyan-light))))

;;;;; highlight-symbol
   `(highlight-symbol-face                        ((t (:background ,bg-alt2))))

;;;;; highlight-numbers
   `(highlight-numbers-number                     ((t (:foreground ,acme-blue))))

;;;;; highlight-operators
   `(highlight-operators-face                     ((t (:foreground ,fg))))

;;;;; hl-todo
   `(hl-todo                                      ((t (:inverse-video t))))

;;;;; hl-line-mode
   `(hl-line-face                                 ((,class (:background ,bg-alt2)) (t :weight normal)))

;;;;; hl-sexp
   `(hl-sexp-face                                 ((,class (:background ,bg-alt2)) (t :weight normal)))

;;;;; ido-mode
   `(ido-first-match                              ((t (:foreground ,fg :weight normal))))
   `(ido-only-match                               ((t (:foreground ,fg :weight normal))))
   `(ido-subdir                                   ((t (:foreground ,acme-blue))))
   `(ido-indicator                                ((t (:foreground ,acme-yellow))))

;;;;; ido-vertical
   `(ido-vertical-first-match-face                ((t (:foreground ,fg :background ,acme-cyan-light :weight normal))))
   `(ido-vertical-only-match-face                 ((t (:foreground ,acme-red :background ,acme-red-light :weight normal))))
   `(ido-vertical-match-face                      ((t (:foreground ,fg :background ,acme-green-light :weight normal :underline t))))

;;;;; indent-guide
   `(indent-guide-face                            ((t (:foreground ,highlight))))

;;;;; ivy
   `(ivy-current-match                            ((t (:background ,acme-blue-light :underline t :extend t))))
   `(ivy-minibuffer-match-face-1                  ((t (:background ,bg-alt2))))
   `(ivy-minibuffer-match-face-2                  ((t (:background ,acme-cyan-light))))
   `(ivy-minibuffer-match-face-3                  ((t (:background ,acme-purple-light))))
   `(ivy-minibuffer-match-face-3                  ((t (:background ,acme-blue-light))))

;;;;; js2-mode
   `(js2-warning                                  ((t (:underline ,acme-yellow))))
   `(js2-error                                    ((t (:foreground ,acme-red :weight normal))))
   `(js2-jsdoc-tag                                ((t (:foreground ,acme-purple))))
   `(js2-jsdoc-type                               ((t (:foreground ,acme-blue))))
   `(js2-jsdoc-value                              ((t (:foreground ,acme-cyan))))
   `(js2-function-param                           ((t (:foreground ,fg))))
   `(js2-external-variable                        ((t (:foreground ,acme-cyan))))

;;;;; linum-mode
   `(linum                                        ((t (:foreground ,fg-light))))

;;;;; lsp-mode
   `(lsp-face-highlight-textual                   ((t (:background ,bg-dark))))
   `(lsp-face-highlight-read                      ((t (:background ,acme-purple-light))))
   `(lsp-face-highlight-write                     ((t (:background ,acme-green-light))))

;;;;; magit
   `(magit-section-heading                        ((t (:foreground ,acme-cyan :background ,acme-blue-light :weight normal :underline t))))
   `(magit-section-highlight                      ((t (:background ,bg-alt2))))
   `(magit-section-heading-selection              ((t (:background ,highlight))))
   `(magit-filename                               ((t (:foreground ,fg))))
   `(magit-hash                                   ((t (:foreground ,acme-yellow :weight normal))))
   `(magit-tag                                    ((t (:foreground ,acme-purple :weight normal))))
   `(magit-refname                                ((t (:foreground ,acme-purple :weight normal))))
   `(magit-head                                   ((t (:foreground ,acme-green :weight normal))))
   `(magit-branch-local                           ((t (:foreground ,acme-blue :background ,acme-blue-light
                                                                   :weight normal))))
   `(magit-branch-remote                          ((t (:foreground ,acme-green :background ,acme-green-light
                                                                   :weight normal))))
   `(magit-branch-current                         ((t (:foreground ,acme-cyan :background ,acme-cyan-light
                                                                   :weight normal
                                                                   :box (:line-width 1 :color ,acme-cyan)))))
   `(magit-diff-file-heading                      ((t (:foreground ,fg :weight normal))))
   `(magit-diff-file-heading-highlight            ((t (:background ,bg-alt2))))
   `(magit-diff-file-heading-selection            ((t (:foreground ,acme-red :background ,highlight))))
   `(magit-diff-hunk-heading                      ((t (:foreground ,acme-blue :background ,acme-blue-light :weight normal :underline t))))
   `(magit-diff-hunk-heading-highlight            ((t (:background ,acme-cyan-light))))
   `(magit-diff-added                             ((t (:foreground ,acme-green :background ,acme-green-light))))
   `(magit-diff-removed                           ((t (:foreground ,acme-red :background ,acme-red-light))))
   `(magit-diff-context                           ((t (:foreground ,fg-alt-dark :background nil))))
   `(magit-diff-added-highlight                   ((t (:foreground ,acme-green :background ,acme-green-light))))
   `(magit-diff-removed-highlight                 ((t (:foreground ,acme-red :background ,acme-red-light))))
   `(magit-diff-context-highlight                 ((t (:foreground ,fg-alt-dark :background ,bg-alt2))))
   `(magit-diffstat-added                         ((t (:foreground ,acme-green :background ,acme-green-light :weight normal))))
   `(magit-diffstat-removed                       ((t (:foreground ,acme-red :background ,acme-red-light :weight normal))))
   `(magit-log-author                             ((t (:foreground ,acme-blue :weight normal))))
   `(magit-log-date                               ((t (:foreground ,acme-purple :weight normal))))
   `(magit-log-graph                              ((t (:foreground ,acme-red :weight normal))))
   `(magit-blame-heading                          ((t (:foreground ,fg-alt-dark :background ,bg-alt2))))

;;;;; paren-face
   `(parenthesis                                  ((t (:foreground "#CCCCB7"))))

;;;;; project-explorer
   `(pe/file-face                                 ((t (:foreground ,fg))))
   `(pe/directory-face                            ((t (:foreground ,acme-blue :weight normal))))

;;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face              ((t (:foreground ,acme-green))))
   `(rainbow-delimiters-depth-2-face              ((t (:foreground ,acme-blue))))
   `(rainbow-delimiters-depth-3-face              ((t (:foreground ,acme-red))))

;;;;; show-paren
   `(show-paren-mismatch                          ((t (:foreground ,acme-yellow :background ,acme-red :weight normal))))
   `(show-paren-match                             ((t (:foreground ,fg :background ,acme-cyan-light :weight normal))))

;;;;; mode-line/sml-mode-line
   `(mode-line                                    ((,class (:foreground ,fg :background ,acme-blue-light :box t))))
   `(mode-line-inactive                           ((t (:foreground ,fg :background ,bg-dark :box t))))
   `(mode-line-buffer-id                          ((t (:foreground ,fg :weight bold)))) ; associated buffer/file name
   `(sml/global                                   ((t (:foreground ,fg))))
   `(sml/modes                                    ((t (:foreground ,acme-green :background ,acme-green-light))))
   `(sml/filename                                 ((t (:foreground ,acme-red))))
   `(sml/folder                                   ((t (:foreground ,fg))))
   `(sml/prefix                                   ((t (:foreground ,fg))))
   `(sml/read-only                                ((t (:foreground ,fg))))
   `(sml/modified                                 ((t (:foreground ,acme-red :weight normal))))
   `(sml/outside-modified                         ((t (:background ,acme-red :foreground ,acme-red-light :weight normal))))
   `(sml/line-number                              ((t (:foreground ,fg :weight normal))))
   `(sml/col-number                               ((t (:foreground ,fg :weight normal))))
   `(sml/vc                                       ((t (:foreground ,fg :weight normal))))
   `(sml/vc-edited                                ((t (:foreground ,acme-red :weight normal))))
   `(sml/git                                      ((t (:foreground ,fg :weight normal))))

;;;;; sh
   `(sh-heredoc-face                              ((t (:foreground ,acme-purple))))

;;;;; web-mode
   `(web-mode-builtin-face                        ((t (:inherit ,font-lock-builtin-face))))
   `(web-mode-comment-face                        ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-constant-face                       ((t (:inherit ,font-lock-constant-face))))
   `(web-mode-doctype-face                        ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-folded-face                         ((t (:underline t))))
   `(web-mode-function-name-face                  ((t (:foreground ,fg :weight normal))))
   `(web-mode-html-attr-name-face                 ((t (:foreground ,fg))))
   `(web-mode-html-attr-value-face                ((t (:inherit ,font-lock-string-face))))
   `(web-mode-html-tag-face                       ((t (:foreground ,acme-blue))))
   `(web-mode-keyword-face                        ((t (:inherit ,font-lock-keyword-face))))
   `(web-mode-preprocessor-face                   ((t (:inherit ,font-lock-preprocessor-face))))
   `(web-mode-string-face                         ((t (:inherit ,font-lock-string-face))))
   `(web-mode-type-face                           ((t (:inherit ,font-lock-type-face))))
   `(web-mode-variable-name-face                  ((t (:inherit ,font-lock-variable-name-face))))
   `(web-mode-server-background-face              ((t (:background ,acme-green-light))))
   `(web-mode-server-comment-face                 ((t (:inherit web-mode-comment-face))))
   `(web-mode-server-string-face                  ((t (:foreground ,acme-red))))
   `(web-mode-symbol-face                         ((t (:inherit font-lock-constant-face))))
   `(web-mode-warning-face                        ((t (:inherit font-lock-warning-face))))
   `(web-mode-whitespaces-face                    ((t (:background ,acme-red-light))))
   `(web-mode-block-face                          ((t (:background ,acme-green-light))))
   `(web-mode-current-element-highlight-face      ((t (:foreground ,fg :background ,acme-blue-light))))
   `(web-mode-json-key-face                       ((,class (:inherit font-lock-string-face))))
   `(web-mode-json-context-face                   ((,class (:inherit font-lock-string-face :bold t))))

;;;;; which-func-mode
   `(which-func                                   ((t (:foreground ,acme-purple :background ,acme-purple-light))))

;;;;; yascroll
   `(yascroll:thumb-text-area                     ((t (:background ,highlight))))
   `(yascroll:thumb-fringe                        ((t (:background ,bg :foreground ,bg :box (:line-width 1 :style released-button)))))

;;;;; Org
   `(org-level-1                                  ((t (:background ,acme-blue-light :foreground ,acme-blue :weight bold :overline t))))
   `(org-level-2                                  ((t (:background ,acme-blue-light :foreground ,acme-cyan :weight bold :overline t))))
   `(org-level-3                                  ((t (:background ,acme-blue-light :foreground ,acme-blue :weight bold :overline t))))
   `(org-level-4                                  ((t (:background ,acme-blue-light :foreground ,acme-cyan))))
   `(org-level-5                                  ((t (:background ,acme-blue-light :foreground ,acme-blue))))
   `(org-level-6                                  ((t (:background ,acme-blue-light :foreground ,acme-cyan))))
   `(org-level-7                                  ((t (:background ,acme-blue-light :foreground ,acme-blue))))
   `(org-level-8                                  ((t (:background ,acme-blue-light :foreground ,acme-cyan))))
   `(org-document-title                           ((t (:height 1.2 :foreground ,acme-blue :weight bold :underline t)))) ; #TITLE
   `(org-meta-line                                ((t (:foreground ,acme-green))))
   `(org-document-info                            ((t (:foreground ,acme-cyan :weight normal))))
   `(org-document-info-keyword                    ((t (:foreground ,acme-cyan))))
   `(org-todo                                     ((t (:foreground ,acme-yellow :background ,bg-alt2 :weight normal :box (:line-width 1 :style released-button)))))
   `(org-done                                     ((t (:foreground ,acme-green :background ,acme-green-light :weight normal :box (:style released-button)))))
   `(org-date                                     ((t (:foreground ,acme-purple))))
   `(org-table                                    ((t (:foreground ,acme-purple))))
   `(org-formula                                  ((t (:foreground ,acme-blue :background ,bg-alt2))))
   `(org-code                                     ((t (:foreground ,acme-red :background ,bg-alt2))))
   `(org-verbatim                                 ((t (:foreground ,fg :background ,bg-alt2 :underline t))))
   `(org-special-keyword                          ((t (:foreground ,acme-cyan))))
   `(org-agenda-date                              ((t (:foreground ,acme-cyan))))
   `(org-agenda-structure                         ((t (:foreground ,acme-purple))))
   `(org-block                                    ((t (:foreground ,fg :background ,bg-alt2))))
   `(org-block-background                         ((t (:background ,bg-alt2))))
   `(org-block-begin-line                         ((t (:foreground ,fg-alt :background ,bg-dark :italic t))))
   `(org-block-end-line                           ((t (:foreground ,fg-alt :background ,bg-dark :italic t))))

;;;;; origami
   `(origami-fold-replacement-face                ((t (:foreground ,acme-red :background ,acme-red-light
                                                                   :box (:line-width -1)))))

;;;;; git-gutter
   `(git-gutter:added                             ((t (:background ,acme-green-alt :foreground ,acme-green-alt :weight normal))))
   `(git-gutter:deleted                           ((t (:background ,acme-red :foreground ,acme-red :weight normal))))
   `(git-gutter:modified                          ((t (:background ,acme-yellow :foreground ,acme-yellow :weight normal))))
   `(git-gutter-fr:added                          ((t (:background ,acme-green-alt :foreground ,acme-green-alt :weight normal))))
   `(git-gutter-fr:deleted                        ((t (:background ,acme-red :foreground ,acme-red :weight normal))))
   `(git-gutter-fr:modified                       ((t (:background ,acme-yellow :foreground ,acme-yellow :weight normal))))

;;;;; diff-hl
   `(diff-hl-insert                               ((t (:background ,acme-green-alt :foreground ,acme-green-alt))))
   `(diff-hl-delete                               ((t (:background ,acme-red :foreground ,acme-red))))
   `(diff-hl-change                               ((t (:background ,acme-yellow :foreground ,acme-yellow))))

;;;;; mu4e, mail
   `(mu4e-header-highlight-face                   ((t (:background ,highlight))))
   `(mu4e-unread-face                             ((t (:foreground ,acme-blue :weight normal))))
   `(mu4e-flagged-face                            ((t (:foreground ,acme-red :background ,acme-red-light :weight normal))))
   `(mu4e-compose-separator-face                  ((t (:foreground ,acme-green))))
   `(mu4e-header-value-face                       ((t (:foreground ,fg))))
   `(message-header-name                          ((t (:foreground ,acme-purple :weight normal))))
   `(message-header-to                            ((t (:foreground ,acme-blue))))
   `(message-header-subject                       ((t (:foreground ,acme-blue))))
   `(message-header-other                         ((t (:foreground ,acme-blue))))
   `(message-cited-text                           ((t (:inherit font-lock-comment-face))))
   ))

;;; Theme Variables
(acme/with-color-variables
  (custom-theme-set-variables
   'acme

;;;;; fill-column-indicator
   `(fci-rule-color ,acme-yellow-light)

;;;;; highlight-parentheses
   `(hl-paren-colors '(,acme-green ,acme-blue ,acme-red))
   `(hl-paren-background-colors '(,acme-green-light ,acme-blue-light ,acme-red-light))

;;;;; sml-mode-line
   `(sml/active-foreground-color ,fg)
   `(sml/active-background-color ,acme-blue-light)
   `(sml/inactive-foreground-color ,fg)
   `(sml/inactive-background-color ,acme-blue)
   ))


;;; Footer

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'acme)

;; Local Variables:
;; no-byte-compile: t
;; indent-tabs-mode: nil
;; End:
;;; acme-theme.el ends here
