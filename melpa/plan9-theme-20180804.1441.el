;;; plan9-theme.el --- A color theme for Emacs based on Plan9

;; Copyright (C) 2015 John Louis Del Rosario

;; Author: John Louis Del Rosario <john2x@gmail.com>
;; URL: https://github.com/john2x/plan9-theme.el
;; Package-Version: 20180804.1441
;; Package-Commit: 4c1050b8ed42e0f99ef64c77ec370a786bd0003c
;; Version: 0.2

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

;; This theme was modified from zenburn-theme.el by Bozhidar Batsov
;; https://github.com/bbatsov/zenburn-emacs

;;; Code:

(deftheme plan9 "Theme inspired by Plan9")

;;; Color Palette

(defvar plan9-colors-alist
  '(("bg"            . "#FFFFE8")
    ("bg-alt"        . "#FFFFD8")
    ("bg-dark"       . "#E5E5D0")

    ("fg"            . "#424242")
    ("fg-alt"        . "#B8B09A")
    ("fg-alt-dark"   . "#988d6d")
    ("fg-light"      . "#CCCCB7")

    ("highlight"     . "#e8eb98")

    ("cyan"          . "#4fa8a8")
    ("cyan-light"    . "#98ece8")

    ("red"           . "#b85c57")
    ("red-light"     . "#f8e8e8")

    ("yellow"        . "#989848")
    ("yellow-light"  . "#f8fce8")

    ("green"         . "#40883f")
    ("green-light"   . "#e8fce8")

    ("blue"          . "#0287c8")
    ("blue-light"    . "#c1e7f8")

    ("purple"        . "#8888c8")
    ("purple-light"  . "#e7fcf7"))
  "List of Plan9 colors.
Each element has the form (NAME . HEX). ")

(defmacro plan9/with-color-variables (&rest body)
  "`let' bind all colors defined in `plan9-colors-alist' around BODY.
Also bind `class' to ((class color) (min-colors 89))."
  (declare (indent 0))
  `(let ((class '((class color) (min-colors 89)))
         ,@(mapcar (lambda (cons)
                     (list (intern (car cons)) (cdr cons)))
                   plan9-colors-alist))
     ,@body))

;;; Theme Faces
(plan9/with-color-variables
  (custom-theme-set-faces
   'plan9
;;;; Built-in
;;;;; basic coloring
   '(button ((t (:underline t))))
   `(link ((t (:foreground ,blue :underline t :weight bold))))
   `(link-visited ((t (:foreground ,purple :underline t :weight normal))))
   `(default ((t (:foreground ,fg :background ,bg))))
   `(cursor ((t (:foreground ,bg :background ,fg))))
   `(escape-glyph ((t (:foreground ,cyan-light :bold t))))
   `(fringe ((t (:foreground ,fg :background ,bg-dark))))
   `(header-line ((t (:foreground ,purple
                                  :background ,purple-light
                                  :box (:line-width -1 :style released-button)))))
   `(highlight ((t (:background ,highlight))))
   `(success ((t (:foreground ,green :weight bold))))
   `(warning ((t (:foreground ,red :weight bold))))
;;;;; compilation
   `(compilation-column-face ((t (:foreground ,yellow :background ,yellow-light))))
   `(compilation-column-number ((t (:foreground ,yellow :background ,yellow-light))))
   ;;`(compilation-enter-directory-face ((t (:foreground ,))))
   `(compilation-error-face ((t (:foreground ,red :weight bold :underline t))))
   `(compilation-face ((t (:foreground ,fg))))
   `(compilation-info-face ((t (:foreground ,blue))))
   `(compilation-info ((t (:foreground ,blue :underline t))))
   ;;`(compilation-leave-directory-face ((t (:foreground ,wisteria))))
   `(compilation-line-face ((t (:foreground ,purple))))
   `(compilation-line-number ((t (:foreground ,yellow :background ,yellow-light))))
   `(compilation-message-face ((t (:foreground ,blue))))
   `(compilation-warning-face ((t (:foreground ,yellow :weight bold :underline t))))
   `(compilation-mode-line-exit ((t (:foreground ,cyan :weight bold))))
   `(compilation-mode-line-fail ((t (:foreground ,red :weight bold))))
   `(compilation-mode-line-run ((t (:foreground ,purple :weight bold))))
;;;;; grep
   `(grep-context-face ((t (:foreground ,fg-alt))))
   `(grep-error-face ((t (:foreground ,red :weight bold :underline t))))
   `(grep-hit-face ((t (:foreground ,purple :weight bold))))
   `(grep-match-face ((t (:foreground ,cyan :weight bold))))
   `(match ((t (:background ,cyan :foreground ,cyan-light))))
;;;;; ag
   `(ag-hit-face ((t (:foreground ,green :weight bold))))
   `(ag-match-face ((t (:foreground ,cyan :background ,cyan-light :weight bold))))
;;;;; isearch
   `(isearch ((t (:foreground ,fg :weight bold :background ,cyan-light))))
   `(isearch-fail ((t (:foreground ,fg :weight bold :background ,red))))
   `(lazy-highlight ((t (:foreground ,fg :weight bold :background ,blue-light))))

   `(menu ((t (:foreground ,bg :background ,fg))))
   `(minibuffer-prompt ((t (:foreground ,fg :weight bold))))
   `(region ((,class (:background ,highlight :foreground ,fg))
             (t :inverse-video t)))
   `(secondary-selection ((t (:background ,green-light))))
   `(trailing-whitespace ((t (:background ,red-light))))
   `(vertical-border ((t (:foreground ,cyan))))
;;;;; font lock
   `(font-lock-builtin-face ((t (:foreground ,fg :weight bold))))
   `(font-lock-comment-face ((t (:foreground ,green))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,green))))
   `(font-lock-constant-face ((t (:foreground ,yellow :weight bold))))
   `(font-lock-doc-face ((t (:foreground ,green))))
   `(font-lock-function-name-face ((t (:foreground ,fg :weight bold))))
   `(font-lock-keyword-face ((t (:foreground ,yellow))))
   `(font-lock-negation-char-face ((t (:foreground ,red :weight bold))))
   `(font-lock-preprocessor-face ((t (:foreground ,green :weight bold))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,red :weight bold))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,red :weight bold))))
   `(font-lock-string-face ((t (:foreground ,red))))
   `(font-lock-type-face ((t (:foreground ,blue, :weight bold))))
   `(font-lock-variable-name-face ((t (:foreground ,cyan))))
   `(font-lock-warning-face ((t (:foreground ,red :weight bold))))

 ;;;; table
   `(table-cell ((t (:background ,bg-alt))))

   ;; `(c-annotation-face ((t (:inherit font-lock-constant-face))))
 ;;;; ledger
   `(ledger-font-directive-face ((t (:foreground ,cyan))))
   `(ledger-font-periodic-xact-face ((t (:inherit ledger-font-directive-face))))
   `(ledger-font-posting-account-face ((t (:foreground ,blue))))
   `(ledger-font-posting-amount-face ((t (:foreground ,red))))
   `(ledger-font-posting-date-face ((t (:foreground ,red :weight bold))))
   `(ledger-font-payee-uncleared-face ((t (:foreground ,purple))))
   `(ledger-font-payee-cleared-face ((t (:foreground ,fg))))
   `(ledger-font-payee-pending-face ((t (:foreground ,yellow))))
   `(ledger-font-xact-highlight-face ((t (:background ,bg-alt))))
;;;; Third-party
;;;;; ace-jump
   ;; `(ace-jump-face-background
   ;;   ((t (:foreground ,nephritis :background ,clouds :inverse-video nil))))
   ;; `(ace-jump-face-foreground
   ;;   ((t (:foreground ,nephritis :background ,clouds :inverse-video nil))))
;;;; anzu
   `(anzu-mode-line ((t (:foreground ,yellow :background ,yellow-light :weight bold))))
;;;;; auto-complete
   ;; `(ac-candidate-face ((t (:background ,concrete :foreground ,midnight-blue))))
   ;; `(ac-selection-face ((t (:background ,asbestos :foreground ,midnight-blue))))
   ;; `(popup-tip-face ((t (:background ,sun-flower :foreground ,midnight-blue))))
   ;; `(popup-scroll-bar-foreground-face ((t (:background ,asbestos))))
   ;; `(popup-scroll-bar-background-face ((t (:background ,silver))))
   ;; `(popup-isearch-match ((t (:background ,clouds :foreground ,midnight-blue))))
;;;;; TODO: bm
   ;; `(bm-face ((t (:background ,zenburn-yellow-1 :foreground ,zenburn-bg))))
   ;; `(bm-fringe-face ((t (:background ,zenburn-yellow-1 :foreground ,zenburn-bg))))
   ;; `(bm-fringe-persistent-face ((t (:background ,zenburn-green-1 :foreground ,zenburn-bg))))
   ;; `(bm-persistent-face ((t (:background ,zenburn-green-1 :foreground ,zenburn-bg))))
;;;; clojure-mode
   `(clojure-interop-method-face ((t (:inherit font-lock-function-name-face))))
;;;; clojure-test-mode
   `(clojure-test-failure-face ((t (:foreground ,red :weight bold :underline t))))
   `(clojure-test-error-face ((t (:foreground ,red :weight bold :underline t))))
   `(clojure-test-success-face ((t (:foreground ,green :weight bold :underline t))))
;;;; diff
   `(diff-added ((,class (:foreground ,fg :background ,green-light))
                 (t (:foreground ,fg :background ,green-light))))
   `(diff-changed ((t (:foreground ,yellow))))
   `(diff-context ((t (:foreground ,fg))))
   `(diff-removed ((,class (:foreground ,fg :background ,red-light))
                   (t (:foreground ,fg :background ,red-light))))
   `(diff-refine-added ((t :inherit diff-added :background ,green-light :weight bold)))
   `(diff-refine-change ((t :inherit diff-changed :weight bold)))
   `(diff-refine-removed ((t :inherit diff-removed :background ,red-light :weight bold)))
   `(diff-header ((,class (:foreground ,fg :weight bold))
                  (t (:foreground ,purple-light :weight bold))))
   `(diff-file-header
     ((,class (:foreground ,fg :background ,cyan-light :weight bold))
      (t (:foreground ,fg :background ,cyan-light :weight bold))))
   `(diff-hunk-header
     ((,class (:foreground ,green :weight bold))
      (t (:foreground ,green :weight bold))))

;;;; diff-hl
   `(diff-hl-insert ((t (:foreground ,fg :background ,green-light))))
   `(diff-hl-delete ((t (:foreground ,fg :background ,red-light))))
   `(diff-hl-change ((t (:foreground ,fg :background ,yellow-light))))

;;;; dired/dired+/dired-subtree
   `(diredp-display-msg ((t (:foreground ,blue))))
   `(diredp-compressed-file-suffix ((t (:foreground ,purple))))
   `(diredp-date-time ((t (:foreground ,green))))
   `(diredp-deletion ((t (:foreground ,red))))
   `(diredp-deletion-file-name ((t (:foreground ,red))))
   `(diredp-dir-heading ((t (:foreground ,blue :background ,blue-light :weight bold))))
   `(diredp-dir-priv ((t (:foreground ,blue))))
   `(diredp-exec-priv ((t (:foreground ,yellow))))
   `(diredp-executable-tag ((t (:foreground ,yellow))))
   `(diredp-file-name ((t (:foreground ,fg))))
   `(diredp-file-suffix ((t (:foreground ,yellow))))
   `(diredp-flag-mark ((t (:foreground ,cyan))))
   `(diredp-flag-mark-line ((t (:foreground ,cyan))))
   `(diredp-ignored-file-name ((t (:foreground ,fg-light))))
   `(diredp-link-priv ((t (:foreground ,purple))))
   `(diredp-mode-line-flagged ((t (:foreground ,yellow))))
   `(diredp-mode-line-marked ((t (:foreground ,yellow))))
   `(diredp-no-priv ((t (:foreground ,fg))))
   `(diredp-number ((t (:foreground ,blue))))
   `(diredp-other-priv ((t (:foreground ,fg))))
   `(diredp-rare-priv ((t (:foreground ,fg))))
   `(diredp-read-priv ((t (:foreground ,fg))))
   `(diredp-symlink ((t (:foreground ,fg :background ,blue-light))))
   `(diredp-write-priv ((t (:foreground ,fg))))
   `(diredp-dir-name ((t (:foreground ,blue :background ,blue-light :weight bold))))
   `(dired-subtree-depth-1-face ((t (:background ,bg))))
   `(dired-subtree-depth-2-face ((t (:background ,bg))))
   `(dired-subtree-depth-3-face ((t (:background ,bg))))
;;;;; ediff
   ;; `(ediff-current-diff-A ((t (:foreground ,midnight-blue :background ,alizarin))))
   ;; `(ediff-current-diff-Ancestor ((t (:foreground ,midnight-blue :background ,alizarin))))
   ;; `(ediff-current-diff-B ((t (:foreground ,midnight-blue :background ,emerald))))
   ;; `(ediff-current-diff-C ((t (:foreground ,midnight-blue :background ,peter-river))))
   ;; `(ediff-even-diff-A ((t (:background ,clouds))))
   ;; `(ediff-even-diff-Ancestor ((t (:background ,clouds))))
   ;; `(ediff-even-diff-B ((t (:background ,silver))))
   ;; `(ediff-even-diff-C ((t (:background ,silver))))
   ;; `(ediff-fine-diff-A ((t (:foreground ,midnight-blue :background ,alizarin :weight bold))))
   ;; `(ediff-fine-diff-Ancestor ((t (:foreground ,midnight-blue :background ,alizarin weight bold))))
   ;; `(ediff-fine-diff-B ((t (:foreground ,midnight-blue :background ,emerald :weight bold))))
   ;; `(ediff-fine-diff-C ((t (:foreground ,midnight-blue :background ,peter-river :weight bold ))))
   ;; `(ediff-odd-diff-A ((t (:background ,silver))))
   ;; `(ediff-odd-diff-Ancestor ((t (:background ,silver))))
   ;; `(ediff-odd-diff-B ((t (:background ,silver))))
   ;; `(ediff-odd-diff-C ((t (:background ,silver))))
;;;;; elfeed
   `(elfeed-search-date-face ((t (:foreground ,blue))))
   `(elfeed-search-title-face ((t (:foreground ,fg))))
   `(elfeed-search-unread-title-facee ((t (:foreground ,fg))))
   `(elfeed-search-feed-face ((t (:foreground ,green))))
   `(elfeed-search-tag-face ((t (:foreground ,red))))
   `(elfeed-search-unread-count-face ((t (:foreground ,fg))))
;;;;; erc
   `(erc-default-face ((t (:foreground ,fg))))
   `(erc-header-line ((t (:inherit header-line))))
   `(erc-action-face ((t (:inherit erc-default-face))))
   `(erc-bold-face ((t (:inherit erc-default-face :weight bold))))
   `(erc-underline-face ((t (:underline t))))
   `(erc-error-face ((t (:inherit font-lock-warning-face))))
   `(erc-prompt-face ((t (:foreground ,green :background ,green-light :weight bold))))
   `(erc-timestamp-face ((t (:foreground ,green :background ,green-light))))
   `(erc-direct-msg-face ((t (:inherit erc-default))))
   `(erc-notice-face ((t (:foreground ,fg-light))))
   `(erc-highlight-face ((t (:background ,highlight))))

   `(erc-input-face ((t (:foreground ,fg :background ,bg-alt))))
   `(erc-current-nick-face ((t (:foreground ,fg :background ,cyan-light :weight bold :box (:line-width 1 :style released-button)))))
   `(erc-nick-default-face ((t (:weight bold :background ,bg-alt))))
   `(erc-my-nick-face ((t (:foreground ,fg :background ,cyan-light :weight bold :box (:line-width 1 :style released-button)))))
   `(erc-nick-msg-face ((t (:inherit erc-default))))
   `(erc-fool-face ((t (:inherit erc-default))))
   `(erc-pal-face ((t (:foreground ,purple :weight bold))))

   `(erc-dangerous-host-face ((t (:inherit font-lock-warning-face))))
   `(erc-keyword-face ((t (:foreground ,yellow :weight bold))))
;;;;; eshell
   ;; `(eshell-prompt ((t (:foreground ,pomegranate :weight bold))))
   ;; `(eshell-ls-archive ((t (:foreground ,amethyst :weight bold))))
   ;; `(eshell-ls-backup ((t (:inherit font-lock-comment-face))))
   ;; `(eshell-ls-clutter ((t (:inherit font-lock-comment-face))))
   ;; `(eshell-ls-directory ((t (:foreground ,peter-river :weight bold))))
   ;; `(eshell-ls-executable ((t (:foreground ,pumpkin))))
   ;; `(eshell-ls-unreadable ((t (:foreground ,concrete))))
   ;; `(eshell-ls-missing ((t (:inherit font-lock-warning-face))))
   ;; `(eshell-ls-product ((t (:inherit font-lock-doc-face))))
   ;; `(eshell-ls-special ((t (:foreground ,sun-flower :weight bold))))
   ;; `(eshell-ls-symlink ((t (:foreground ,clouds :background ,amethyst))))
  ;;;;; evil
   `(evil-search-highlight-persist-highlight-face ((t (:inherit lazy-highlight))))
;;;;; flx
   `(flx-highlight-face ((t (:foreground ,yellow :background ,green-light :weight bold :underline t))))
;;;;; company
   `(company-tooltip ((t (:background ,green-light))))
   `(company-tooltip-selection ((t (:background ,cyan-light))))
   `(company-tooltip-mouse ((t (:background ,blue-light))))
   `(company-tooltip-search ((t (:foreground ,red))))
   `(company-tooltip-common ((t (:foreground ,red :background ,green-light))))
   `(company-tooltip-annotation ((t (:foreground ,green :background ,green-light))))
   `(company-scrollbar-fg ((t (:background ,red))))
   `(company-scrollbar-bg ((t (:background ,red-light))))
   `(company-preview ((t (:foreground ,fg :background ,cyan-light))))
   `(company-preview-common ((t (:foreground ,fg :background ,cyan-light))))
;;;; flycheck
   `(flycheck-error
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,red) :inherit unspecified))
      (t (:foreground ,red :weight bold :underline t))))
   `(flycheck-warning
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,yellow) :inherit unspecified))
      (t (:foreground ,yellow :weight bold :underline t))))
   `(flycheck-info
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,purple) :inherit unspecified))
      (t (:foreground ,purple :weight bold :underline t))))
   `(flycheck-fringe-error ((t (:foreground ,red :weight bold))))
   `(flycheck-fringe-warning ((t (:foreground ,yellow :weight bold))))
   `(flycheck-fringe-info ((t (:foreground ,purple :weight bold))))
;; ;;;;; flymake
;;    `(flymake-errline
;;      ((((supports :underline (:style wave)))
;;        (:underline (:style wave :color ,alizarin)
;;                    :inherit unspecified :foreground unspecified :background unspecified))
;;       (t (:foreground ,alizarin :weight bold :underline t))))
;;    `(flymake-warnline
;;      ((((supports :underline (:style wave)))
;;        (:underline (:style wave :color ,orange)
;;                    :inherit unspecified :foreground unspecified :background unspecified))
;;       (t (:foreground ,orange :weight bold :underline t))))
;;    `(flymake-infoline
;;      ((((supports :underline (:style wave)))
;;        (:underline (:style wave :color ,wisteria)
;;                    :inherit unspecified :foreground unspecified :background unspecified))
;;       (t (:foreground ,wisteria :weight bold :underline t))))
;; ;;;;; flyspell
;;    `(flyspell-duplicate
;;      ((((supports :underline (:style wave)))
;;        (:underline (:style wave :color ,orange) :inherit unspecified))
;;       (t (:foreground ,orange :weight bold :underline t))))
;;    `(flyspell-incorrect
;;      ((((supports :underline (:style wave)))
;;        (:underline (:style wave :color ,alizarin) :inherit unspecified))
;;       (t (:foreground ,alizarin :weight bold :underline t))))
;; ;;;;; TODO: full-ack
;;    ;; `(ack-separator ((t (:foreground ,zenburn-fg))))
;;    ;; `(ack-file ((t (:foreground ,zenburn-blue))))
;;    ;; `(ack-line ((t (:foreground ,zenburn-yellow))))
;;    ;; `(ack-match ((t (:foreground ,zenburn-orange :background ,zenburn-bg-1 :weight bold))))
;;;;; git-gutter
   `(git-gutter:added ((t (:foreground ,green :weight bold))))
   `(git-gutter:deleted ((t (:foreground ,red :weight bold))))
   `(git-gutter:modified ((t (:foreground ,yellow :weight bold))))
   `(git-gutter:unchanged ((t (:foreground ,fg :weight bold))))
;;;;; git-gutter-fr
   `(git-gutter-fr:added ((t (:foreground ,green  :weight bold))))
   `(git-gutter-fr:deleted ((t (:foreground ,red :weight bold))))
   `(git-gutter-fr:modified ((t (:foreground ,yellow :weight bold))))
;; ;; ;;;;; git-rebase-mode
;; ;;    `(git-rebase-hash ((t (:foreground, zenburn-orange))))
;; ;;;;; guide-key
;;    `(guide-key/highlight-command-face ((t (:foreground ,peter-river))))
;;    `(guide-key/key-face ((t (:foreground ,orange))))
;;    `(guide-key/prefix-command-face ((t (:foreground ,wisteria))))

;; ;;;;; helm
;;    `(helm-action ((t (:underline nil))))
;;    `(helm-selection ((t (:background ,sun-flower :underline nil :weight bold))))
;;    `(helm-candidate-number ((t (:foreground ,turquoise))))
;;    `(helm-source-header ((t (:foreground ,midnight-blue :weight bold))))
;;    `(helm-visible-mark ((t (:foreground ,alizarin))))
;;    `(helm-ff-directory ((t (:foreground ,peter-river))))
;;    `(helm-ff-executable ((t (:foreground ,pumpkin))))
;;    `(helm-ff-symlink ((t (:foreground ,clouds :background ,amethyst))))
;;    `(helm-ff-prefix ((t (:foreground ,alizarin))))
;;    `(helm-M-x-key ((t (:foreground ,asbestos))))
;;    `(helm-grep-file ((t (:foreground ,turquoise))))
;;    `(helm-grep-lineno ((t (:foreground ,asbestos))))
;;    `(helm-grep-running ((t (:foreground ,alizarin))))
;;    `(helm-grep-finish ((t (:foreground ,turquoise))))
;;    `(helm-buffer-saved-out ((t (:foreground ,orange :background nil))))
;;    `(helm-moccur-buffer ((t (:foreground ,asbestos))))

;; ;;;;; highlight-symbol
    `(highlight-symbol-face ((t (:background ,bg-dark :underline t))))

;;;;; hl-line-mode
   `(hl-line-face ((,class (:background ,bg-alt))
                   (t :weight bold)))
   `(hl-line ((,class (:background ,bg-alt)) ; old emacsen
              (t :weight bold)))
;;;;; hl-sexp
   `(hl-sexp-face ((,class (:background ,bg-alt))
                   (t :weight bold)))
;;;;; ido-mode
   `(ido-first-match ((t (:foreground ,fg :weight bold))))
   `(ido-only-match ((t (:foreground ,fg :weight bold))))
   `(ido-subdir ((t (:foreground ,blue))))
   `(ido-indicator ((t (:foreground ,yellow))))
;;;;; ido-vertical
   `(ido-vertical-first-match-face ((t (:foreground ,fg :background ,cyan-light :weight bold))))
   `(ido-vertical-only-match-face ((t (:foreground ,red :background ,red-light :weight bold))))
   `(ido-vertical-match-face ((t (:foreground ,fg :background ,green-light :weight bold :underline t))))
;;;;; indent-guide
   `(indent-guide-face ((t (:foreground ,highlight))))
;;;;; ivy
   `(ivy-current-match ((t (:background ,highlight))))
   `(ivy-minibuffer-match-face-1 ((t (:background ,bg-alt))))
   `(ivy-minibuffer-match-face-2 ((t (:background ,cyan-light))))
   `(ivy-minibuffer-match-face-3 ((t (:background ,purple-light))))
   `(ivy-minibuffer-match-face-3 ((t (:background ,blue-light))))
;;;;; js2-mode
   `(js2-warning ((t (:underline ,yellow))))
   `(js2-error ((t (:foreground ,red :weight bold))))
   `(js2-jsdoc-tag ((t (:foreground ,purple))))
   `(js2-jsdoc-type ((t (:foreground ,blue))))
   `(js2-jsdoc-value ((t (:foreground ,cyan))))
   `(js2-function-param ((t (:foreground ,fg))))
   `(js2-external-variable ((t (:foreground ,cyan))))
;;;;; linum-mode
   `(linum ((t (:foreground ,fg-light))))
;;;;; lsp-mode
   `(lsp-face-highlight-textual ((t (:background ,bg-dark))))
   `(lsp-face-highlight-read ((t (:background ,purple-light))))
   `(lsp-face-highlight-write ((t (:background ,green-light))))
;;;;; magit
   `(magit-section-heading ((t (:foreground ,cyan :weight bold :underline t :height 1.4))))
   `(magit-section-highlight ((t (:background ,bg-alt))))
   `(magit-section-heading-selection ((t (:background ,highlight))))

   `(magit-filename ((t (:foreground ,fg))))
   `(magit-hash ((t (:foreground ,yellow :weight bold))))
   `(magit-tag ((t (:foreground ,purple :weight bold))))
   `(magit-refname ((t (:foreground ,purple :weight bold))))
   `(magit-head ((t (:foreground ,green :weight bold))))

   `(magit-branch-local ((t (:foreground ,blue :background ,blue-light
                                         :weight bold))))
   `(magit-branch-remote ((t (:foreground ,green :background ,green-light
                                          :weight bold))))
   `(magit-branch-current ((t (:foreground ,cyan :background ,cyan-light
                                          :weight bold
                                          :box (:line-width 1 :color ,cyan)))))

   `(magit-diff-file-heading ((t (:foreground ,fg :weight bold))))
   `(magit-diff-file-heading-highlight ((t (:background ,bg-alt))))
   `(magit-diff-file-heading-selection ((t (:foreground ,red :background ,highlight))))
   `(magit-diff-hunk-heading ((t (:foreground ,blue :weight bold :underline t))))
   `(magit-diff-hunk-heading-highlight ((t (:background ,blue-light))))
   `(magit-diff-added ((t (:foreground ,green :background ,green-light))))
   `(magit-diff-removed ((t (:foreground ,red :background ,red-light))))
   `(magit-diff-context ((t (:foreground ,fg-light :background nil))))
   `(magit-diff-added-highlight ((t (:foreground ,green :background ,green-light))))
   `(magit-diff-removed-highlight ((t (:foreground ,red :background ,red-light))))
   `(magit-diff-context-highlight ((t (:foreground ,fg-light :background ,bg-alt))))
   `(magit-diffstat-added ((t (:foreground ,green :background ,green-light :weight bold))))
   `(magit-diffstat-removed ((t (:foreground ,red :background ,red-light :weight bold))))

   `(magit-log-author ((t (:foreground ,blue :weight bold))))
   `(magit-log-date ((t (:foreground ,purple :weight bold))))
   `(magit-log-graph ((t (:foreground ,red :weight bold))))

   `(magit-blame-heading ((t (:foreground ,fg-light :background ,bg-alt))))
;;;;; paren-face
   `(parenthesis ((t (:foreground "#CCCCB7"))))
;;;;; project-explorer
   `(pe/file-face ((t (:foreground ,fg))))
   `(pe/directory-face ((t (:foreground ,blue :weight bold))))
;; ;;;;; outline
;;    `(outline-1 ((t (:foreground ,green-sea))))
;;    `(outline-2 ((t (:foreground ,belize-hole))))
;;    `(outline-3 ((t (:foreground ,wisteria))))
;;    `(outline-4 ((t (:foreground ,orange))))
;;    `(outline-5 ((t (:foreground ,pumpkin))))
;;    `(outline-6 ((t (:foreground ,pomegranate))))
;;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,green))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,blue))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,red))))
;;    `(rainbow-delimiters-depth-4-face ((t (:foreground ,peter-river))))
;;    `(rainbow-delimiters-depth-5-face ((t (:foreground ,amethyst))))
;;    `(rainbow-delimiters-depth-6-face ((t (:foreground ,sun-flower))))
;;    `(rainbow-delimiters-depth-7-face ((t (:foreground ,carrot))))
;;    `(rainbow-delimiters-depth-8-face ((t (:foreground ,alizarin))))
;;    `(rainbow-delimiters-depth-9-face ((t (:foreground ,green-sea))))
;;    `(rainbow-delimiters-depth-10-face ((t (:foreground ,nephritis))))
;;    `(rainbow-delimiters-depth-11-face ((t (:foreground ,belize-hole))))
;;    `(rainbow-delimiters-depth-12-face ((t (:foreground ,wisteria))))
;; ;;;;; structured-haskell-mode
;;    `(shm-current-face ((t (:background ,silver))))
;;    `(shm-quarantine-face ((t (:inherit font-lock-error))))
;;;;; show-paren
   `(show-paren-mismatch ((t (:foreground ,yellow :background ,red :weight bold))))
   `(show-paren-match ((t (:foreground ,fg :background ,cyan-light :weight bold))))
;;;;; mode-line/sml-mode-line
   `(mode-line
     ((,class (:foreground ,fg
                           :background ,cyan-light
                           :box (:line-width -1 :style released-button)))
      (t :inverse-video t)))
   `(mode-line-inactive
     ((t (:foreground ,fg
                      :background ,bg-dark
                      :box (:line-width -1 :style pressed-button)))))
   `(mode-line-buffer-id ((t (:foreground ,red :weight bold))))
   `(sml/global ((t (:foreground ,fg))))
   `(sml/modes ((t (:foreground ,green :background ,green-light))))
   `(sml/filename ((t (:foreground ,red))))
   `(sml/folder ((t (:foreground ,fg))))
   `(sml/prefix ((t (:foreground ,fg))))
   `(sml/read-only ((t (:foreground ,fg))))
   `(sml/modified ((t (:foreground ,red :weight bold))))
   `(sml/outside-modified ((t (:background ,red
                               :foreground ,red-light :weight bold))))
   `(sml/line-number ((t (:foreground ,fg :weight bold))))
   `(sml/col-number ((t (:foreground ,fg :weight bold))))
   `(sml/vc ((t (:foreground ,fg :weight bold))))
   `(sml/vc-edited ((t (:foreground ,red :weight bold))))
   `(sml/git ((t (:foreground ,fg :weight bold))))
;; sh
   `(sh-heredoc-face ((t (:foreground ,purple))))
;; ;;;;; SLIME
;;    `(slime-repl-output-face ((t (:foreground ,midnight-blue))))
;;    `(slime-repl-inputed-output-face ((t (:foreground ,wet-asphalt))))
;;    `(slime-error-face
;;      ((((supports :underline (:style wave)))
;;        (:underline (:style wave :color ,alizarin)))
;;       (t
;;        (:underline ,alizarin))))
;;    `(slime-warning-face
;;      ((((supports :underline (:style wave)))
;;        (:underline (:style wave :color ,orange)))
;;       (t
;;        (:underline ,orange))))
;;    `(slime-style-warning-face
;;      ((((supports :underline (:style wave)))
;;        (:underline (:style wave :color ,sun-flower)))
;;       (t
;;        (:underline ,sun-flower))))
;;    `(slime-note-face
;;      ((((supports :underline (:style wave)))
;;        (:underline (:style wave :color ,wisteria)))
;;       (t
;;        (:underline ,wisteria))))
;;    `(slime-highlight-face ((t (:inherit turquoise))))
;; ;;;;; term
;;    `(term-color-black ((t (:foreground ,midnight-blue
;;                                        :background ,midnight-blue))))
;;    `(term-color-red ((t (:foreground ,pomegranate
;;                                        :background ,pomegranate))))
;;    `(term-color-green ((t (:foreground ,nephritis
;;                                        :background ,nephritis))))
;;    `(term-color-yellow ((t (:foreground ,orange
;;                                        :background ,orange))))
;;    `(term-color-blue ((t (:foreground ,belize-hole
;;                                       :background ,belize-hole))))
;;    `(term-color-magenta ((t (:foreground ,wisteria
;;                                          :background ,wisteria))))
;;    `(term-color-cyan ((t (:foreground ,green-sea
;;                                        :background ,green-sea))))
;;    `(term-color-white ((t (:foreground ,clouds
;;                                        :background ,clouds))))
;;    '(term-default-fg-color ((t (:inherit term-color-white))))
;;    '(term-default-bg-color ((t (:inherit term-color-black))))
;;;;; web-mode
   `(web-mode-builtin-face ((t (:inherit ,font-lock-builtin-face))))
   `(web-mode-comment-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-constant-face ((t (:inherit ,font-lock-constant-face))))
   ;; `(web-mode-css-at-rule-face ((t (:foreground ,pumpkin ))))
   ;; `(web-mode-css-prop-face ((t (:foreground ,pumpkin))))
   ;; `(web-mode-css-pseudo-class-face ((t (:foreground ,orange :weight bold))))
   ;; `(web-mode-css-rule-face ((t (:foreground ,belize-hole))))
   `(web-mode-doctype-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-folded-face ((t (:underline t))))
   `(web-mode-function-name-face ((t (:foreground ,fg :weight bold))))
   `(web-mode-html-attr-name-face ((t (:foreground ,fg))))
   `(web-mode-html-attr-value-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-html-tag-face ((t (:foreground ,blue))))
   `(web-mode-keyword-face ((t (:inherit ,font-lock-keyword-face))))
   `(web-mode-preprocessor-face ((t (:inherit ,font-lock-preprocessor-face))))
   `(web-mode-string-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-type-face ((t (:inherit ,font-lock-type-face))))
   `(web-mode-variable-name-face ((t (:inherit ,font-lock-variable-name-face))))
   `(web-mode-server-background-face ((t (:background ,green-light))))
   `(web-mode-server-comment-face ((t (:inherit web-mode-comment-face))))
   `(web-mode-server-string-face ((t (:foreground ,red))))
   `(web-mode-symbol-face ((t (:inherit font-lock-constant-face))))
   `(web-mode-warning-face ((t (:inherit font-lock-warning-face))))
   `(web-mode-whitespaces-face ((t (:background ,red-light))))
   `(web-mode-block-face ((t (:background ,green-light))))
   `(web-mode-current-element-highlight-face ((t (:foreground ,fg :background ,blue-light))))
;; ;;;;; whitespace-mode
;;    `(whitespace-space ((t (:background ,clouds :foreground ,sun-flower))))
;;    `(whitespace-hspace ((t (:background ,clouds :foreground ,sun-flower))))
;;    `(whitespace-tab ((t (:background ,carrot))))
;;    `(whitespace-newline ((t (:foreground ,sun-flower))))
;;    `(whitespace-trailing ((t (:background ,alizarin))))
;;    `(whitespace-line ((t (:background nil :foreground ,alizarin))))
;;    `(whitespace-space-before-tab ((t (:background ,clouds :foreground ,alizarin))))
;;    `(whitespace-indentation ((t (:background ,clouds :foreground ,sun-flower))))
;;    `(whitespace-empty ((t (:background ,orange))))
;;    `(whitespace-space-after-tab ((t (:background ,clouds :foreground ,alizarin))))
;;;;; which-func-mode
   `(which-func ((t (:foreground ,purple :background ,purple-light))))
;;;;; yascroll
   `(yascroll:thumb-text-area ((t (:background ,highlight))))
   `(yascroll:thumb-fringe ((t (:background ,bg :foreground ,bg :box (:line-width 1 :style released-button)))))
;;;;; Org
   `(org-level-1 ((t (:height 1.4 :weight bold :background ,bg-dark
                              :family "Sans Serif"
                              :box (:line-width 1 :style released-button)))))
   `(org-level-2 ((t (:height 1.2 :background ,bg-dark
                              :box (:line-width 1 :style released-button)))))
   `(org-level-3 ((t (:weight bold))))
   `(org-level-4 ((t (:foreground ,fg-alt-dark :weight bold))))
   `(org-level-5 ((t (:foreground ,fg-alt-dark))))
   `(org-level-6 ((t (:foreground ,fg-alt))))
   `(org-level-7 ((t (:foreground ,fg-alt))))
   `(org-level-8 ((t (:foreground ,fg-alt))))
   `(org-meta-line ((t (:foreground ,green))))
   `(org-document-info ((t (:foreground ,cyan :weight bold))))
   `(org-document-info-keyword ((t (:foreground ,cyan))))
   `(org-document-title ((t (:foreground ,fg :height 1.5 :weight bold :family "Sans Serif" :underline t))))
   `(org-todo ((t (:foreground ,yellow :background ,bg-alt :weight bold
                               :box (:line-width 1 :style released-button)))))
   `(org-done ((t (:foreground ,green :background ,green-light :weight bold
                               :box (:style released-button)))))
   `(org-date ((t (:foreground ,purple))))
   `(org-table ((t (:foreground ,purple))))
   `(org-formula ((t (:foreground ,blue :background ,bg-alt))))
   `(org-code ((t (:foreground ,red :background ,bg-alt))))
   `(org-verbatim ((t (:foreground ,fg :background ,bg-alt :underline t))))
   `(org-special-keyword ((t (:foreground ,cyan))))
   `(org-agenda-date ((t (:foreground ,cyan))))
   `(org-agenda-structure ((t (:foreground ,purple))))
   `(org-block ((t (:foreground ,red))))
   `(org-block-background ((t (:background ,bg-alt))))
   `(org-block-begin-line ((t (:foreground ,fg-alt :background ,bg-dark
                               :italic t))))
   `(org-block-end-line ((t (:foreground ,fg-alt :background ,bg-dark
                             :italic t))))

;;;;; origami
   `(origami-fold-replacement-face ((t (:foreground ,red :background ,red-light
                                                    :box (:line-width -1)))))
;;;;; mu4e, mail
   `(mu4e-header-highlight-face ((t (:background ,highlight))))
   `(mu4e-unread-face ((t (:foreground ,blue :weight bold))))
   `(mu4e-flagged-face ((t (:foreground ,red :background ,red-light :weight bold))))
   `(mu4e-compose-separator-face ((t (:foreground ,green))))
   `(mu4e-header-value-face ((t (:foreground ,fg))))
   `(message-header-name ((t (:foreground ,purple :weight bold))))
   `(message-header-to ((t (:foreground ,blue))))
   `(message-header-subject ((t (:foreground ,blue))))
   `(message-header-other ((t (:foreground ,blue))))
   `(message-cited-text ((t (:inherit font-lock-comment-face))))
   ))

;;; Theme Variables
(plan9/with-color-variables
  (custom-theme-set-variables
   'plan9
;;;;; ansi-color
   ;;`(ansi-color-names-vector [,clouds ,alizarin ,emerald ,sun-flower
   ;;                                       ,peter-river ,amethyst ,turquoise ,midnight-blue])
;;;;; fill-column-indicator
   `(fci-rule-color ,yellow-light)
;;;;; highlight-parentheses
   `(hl-paren-colors '(,green ,blue ,red))
   `(hl-paren-background-colors '(,green-light ,blue-light ,red-light))
;;;;; sml-mode-line
   `(sml/active-foreground-color ,fg)
   `(sml/active-background-color ,cyan-light)
   `(sml/inactive-foreground-color ,fg)
   `(sml/inactive-background-color ,cyan)
;;;;; vc-annotate
   ;; `(vc-annotate-color-map
   ;;   '(( 30. . ,alizarin)
   ;;     ( 60. . ,pomegranate)
   ;;     ( 90. . ,carrot)
   ;;     (120. . ,pumpkin)
   ;;     (150. . ,sun-flower)
   ;;     (180. . ,orange)
   ;;     (210. . ,emerald)
   ;;     (240. . ,nephritis)
   ;;     (270. . ,turquoise)
   ;;     (300. . ,green-sea)
   ;;     (330. . ,peter-river)
   ;;     (360. . ,belize-hole)))
   ;; `(vc-annotate-very-old-color ,belize-hole)
   ;; `(vc-annotate-background ,clouds)
   ))


;;; Footer

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'plan9)

;; Local Variables:
;; no-byte-compile: t
;; indent-tabs-mode: nil
;; End:
;;; plan9-theme.el ends here
