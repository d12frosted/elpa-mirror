;;; soria-theme.el --- A xoria256 theme with some colors from openSUSE -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2021 Miquel Sabaté Solà <mikisabate@gmail.com>
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Author: Miquel Sabaté Solà <mikisabate@gmail.com>
;; Version: 0.3.3
;; Package-Version: 20210122.1027
;; Package-Commit: 1484ac1fdf79dc86907cd7a9db09fc760329bfa4
;; Package-Requires: ((emacs "25.1"))
;; Keywords: faces
;; URL: https://github.com/mssola/soria

;;; Commentary:
;;
;; This is a color theme based on xoria256 (vim.org #2140) but with some
;; modifications here and there with colors from openSUSE's guidelines
;; (http://opensuse.github.io/branding-guidelines/).

;;; Credits:
;;
;; FEI Hao for the xoria256 port (https://github.com/suxue/xoria256-emacs).
;; This theme is *largely* based on this port.
;;
;; Kelvin Smith for the port of the Monokai theme to Emacs
;; (https://github.com/oneKelvinSmith/monokai-emacs). I've taken a *lot* of
;; inspiration from its source code.
;;
;; I've adapted some of the color IDs with this gist:
;;  https://gist.github.com/MicahElliott/719710

;;; Code:

;; Defining the theme and its configuration group.

(deftheme soria "A xoria256 theme with some colors from openSUSE")

(defgroup soria nil
  "Soria theme options.
The theme has to be reloaded after changing anything in this group."
  :group 'faces)

(defcustom soria-theme-hide-helm-header t
  "Hide the Helm header."
  :type 'boolean
  :group 'soria)

;; The color theme itself.

(let*
    ((class '((class color) (min-colors 89)))
     (soria-purple       "#dfafdf")
     (soria-darkpurple   "#875f87")
     (soria-white        "#d0d0d0")
     (soria-darkgray     "#1c1c1c")
     (soria-brightgreen  "#81c13b")
     (soria-green        "#b9dc92")
     (soria-darkgreen    "#2f5361")
     (soria-gray         "#808080")
     (soria-linegray     "#3a3a3a")
     (soria-statusgray   "#4e4e4e")
     (soria-statusncgray "#b2b2b2")
     (soria-black        "#000000")
     (soria-whitest      "#eeeeee")
     (soria-yellow       "#ffffaf")
     (soria-orange       "#d7af87")
     (soria-redpastel    "#d78787")
     (soria-blue         "#87afd7"))

  (custom-theme-set-faces
   'soria
   ;; General coloring.
   `(default (
              (((class color) (min-colors 256))
               (:foreground ,soria-white
                            :background ,soria-darkgray))))

   `(mouse
     ((,class (:foreground ,soria-darkgray
                           :background ,soria-white
                           :inverse-video t))))

   `(cursor
     ((,class (:foreground ,soria-darkgray
                           :background ,soria-white
                           :inverse-video t))))

   `(shadow
     ((,class (:foreground ,soria-gray))))

   `(link
     ((,class (:foreground ,soria-blue
                           :underline t
                           :weight normal))))

   `(match
     ((,class (:background ,soria-orange
                           :foreground ,soria-darkgray
                           :weight bold))))

   `(link-visited
     ((,class (:inherit link))))

   `(minibuffer-prompt
     ((,class (:foreground ,soria-white))))

   `(escape-glyph
     ((,class (:foreground ,soria-redpastel))))

   `(escape-glyph-face
     ((,class (:foreground ,soria-redpastel))))

   `(error
     ((,class (:foreground ,soria-white))))

   `(warning
     ((,class (:foreground ,soria-orange))))

   `(success
     ((,class (:foreground ,soria-blue))))

   `(highlight
     ((,class (:background ,soria-darkpurple
                           :foreground ,soria-white))))

   `(region
     ((,class (:inherit highlight))))

   `(lazy-highlight
     ((,class (:inherit highlight))))

   `(isearch
     ((,class (:background ,soria-green
                           :foreground ,soria-black))))

   `(trailing-whitespace
     ((,class (:background ,soria-brightgreen))))

   `(hl-line
     ((,class (:background ,soria-linegray))))

   `(linum-highlight-face
     ((,class (:background ,soria-darkgray
                           :foreground ,soria-yellow))))

   `(show-paren-match
     ((,class (:background ,soria-brightgreen
                           :foreground ,soria-darkgreen))))

   `(vertical-border
     ((,class (:foreground ,soria-statusgray))))

   ;; Font lock faces

   `(font-lock-builtin-face
     ((,class (:foreground ,soria-blue))))

   `(font-lock-comment-face
     ((,class (:foreground ,soria-gray))))

   `(font-lock-comment-delimiter-face
     ((,class (:inherit font-lock-comment-face))))

   `(font-lock-doc-face
     ((,class (:inherit font-lock-comment-face))))

   `(font-lock-function-name-face
     ((,class (:foreground ,soria-white))))

   `(font-lock-variable-name-face
     ((,class (:foreground ,soria-white :underline nil))))

   `(font-lock-preprocessor-face
     ((,class (:foreground ,soria-green))))

   `(font-lock-constant-face
     ((,class (:foreground ,soria-yellow))))

   `(font-lock-keyword-face
     ((,class (:foreground ,soria-blue))))

   `(font-lock-string-face
     ((,class (:foreground ,soria-yellow))))

   `(font-lock-type-face
     ((,class (:foreground ,soria-blue))))

   `(font-lock-number-face
     ((,class (:foreground ,soria-orange))))

   `(font-lock-negation-char-face
     ((,class (:inherit default))))

   `(font-lock-warning-face
     ((,class (:foreground ,soria-green))))

   ;; highlight-numbers

   `(highlight-numbers-number
     ((,class (:foreground ,soria-orange))))

   ;; Search

   `(isearch
     ((,class (:inherit default))))

   `(isearch-fail
     ((,class (:foreground ,soria-redpastel
                           :background ,soria-darkgray))))

   ;; Mode line faces

   `(mode-line
     ((,class
       (:box (:line-width -1 :style released-button)
             :background ,soria-statusgray
             :foreground ,soria-white))))

   `(mode-line-inactive
     ((,class
       (:box (:line-width -1 :style released-button)
             :background ,soria-linegray
             :foreground ,soria-statusncgray))))

   `(compilation-mode-line-fail
     ((,class (:foreground ,soria-redpastel))))

   `(compilation-mode-line-run
     ((,class (:foreground ,soria-yellow))))

   `(compilation-mode-line-exit
     ((,class (:foreground ,soria-brightgreen))))

   ;; Custom

   `(custom-face-tag
     ((,class (:foreground ,soria-purple))))

   `(custom-variable-tag
     ((,class (:inherit custom-face-tag))))

   `(custom-comment-tag
     ((,class (:foreground ,soria-yellow))))

   `(custom-group-tag
     ((,class (:foreground ,soria-blue))))

   `(custom-group-tag-1
     ((,class (:foreground ,soria-purple))))

   `(custom-state
     ((,class (:foreground ,soria-yellow))))

   ;; Info

   `(info-node
     ((,class (:foreground ,soria-white
                           :background ,soria-darkgray))))

   `(info-title
     ((,class (:foreground ,soria-white
                           :background ,soria-darkgray
                           :weight bold))))

   `(info-title-2
     ((,class (:foreground ,soria-white
                           :background ,soria-darkgray
                           :weight normal))))

   `(info-title-3
     ((,class (:foreground ,soria-white
                           :background ,soria-darkgray
                           :weight normal))))

   `(info-title-4
     ((,class (:foreground ,soria-white
                           :background ,soria-darkgray
                           :weight normal))))

   `(info-menu-header
     ((,class (:weight normal))))

   `(info-menu-star
     ((,class (:foreground ,soria-white
                           :background ,soria-darkgray
                           :weight normal))))

   `(info-quoted
     ((,class (:inherit info-node))))

   `(Info-quoted
     ((,class (:inherit info-node))))

   ;; outline
   `(outline-1
     ((,class (:inherit org-level-1))))

   `(outline-2
     ((,class (:inherit org-level-2))))

   `(outline-3
     ((,class (:inherit org-level-3))))

   `(outline-4
     ((,class (:inherit org-level-4))))

   `(outline-5
     ((,class (:inherit org-level-5))))

   `(outline-6
     ((,class (:inherit org-level-6))))

   `(outline-7
     ((,class (:inherit org-level-7))))

   `(outline-8
     ((,class (:inherit org-level-8))))

   ;; Helm

   `(helm-buffer-file
     ((,class (:foreground ,soria-white))))

   `(helm-buffer-file
     ((,class (:foreground ,soria-blue))))

   `(helm-buffer-process
     ((,class (:foreground ,soria-statusgray))))

   `(helm-buffer-saved-out
     ((,class (:foreground ,soria-white
                           :background ,soria-darkgray))))

   `(helm-buffer-size
     ((,class (:background ,soria-statusgray))))

   `(helm-candidate-number
     ((,class (:background ,soria-statusgray
                           :foreground ,soria-white))))

   `(helm-ff-directory
     ((,class (:foreground ,soria-blue))))

   `(helm-ff-dotted-directory
     ((,class (:inherit helm-ff-directory))))

   `(helm-ff-symlink
     ((,class (:foreground ,soria-brightgreen))))

   `(helm-ff-dotted-symlink-directory
     ((,class (:inherit helm-ff-symlink))))

   `(helm-ff-executable
     ((,class (:foreground ,soria-white))))

   `(helm-ff-file
     ((,class (:foreground ,soria-white))))

   `(helm-ff-file-extension
     ((,class (:foreground ,soria-white))))

   `(helm-ff-invalid-symlink
     ((,class (:foreground ,soria-white))))

   `(helm-ff-prefix
     ((,class (:foreground ,soria-white))))

   `(helm-grep-finish
     ((,class (:foreground ,soria-green))))

   `(helm-grep-lineno
     ((,class (:foreground ,soria-orange))))

   `(helm-grep-match
     ((,class (:foreground ,soria-white :inherit bold))))

   `(helm-grep-running
     ((,class (:foreground ,soria-redpastel))))

   `(helm-match
     ((,class (:foreground ,soria-white :inherit bold))))

   `(helm-match-item
     ((,class (:inherit helm-match))))

   `(helm-moccur-buffer
     ((,class (:foreground ,soria-blue :underline nil))))

   `(helm-selection
     ((,class (:background ,soria-linegray,:underline nil :extend t))))

   `(helm-selection-line
     ((,class (:background ,soria-linegray
                           :foreground ,soria-white
                           :underline nil))))

   `(helm-M-x-key
     ((,class (:foreground ,soria-orange
                           :underline nil))))

   `(helm-separator
     ((,class (:foreground ,soria-gray))))

   ;; The Helm header might be hidden if the user decides so (true by default).
   (if soria-theme-hide-helm-header
       `(helm-source-header
         ((,class (:background ,soria-darkgray
                               :foreground ,soria-darkgray
                               :underline nil))))
     `(helm-source-header
       ((,class (:background ,soria-linegray
                             :foreground ,soria-white
                             :underline nil)))))

   ;; company-mode

   `(company-tooltip
     ((,class (:background ,soria-darkgray))))

   `(company-tooltip-selection
     ((,class (:inherit helm-selection))))

   `(company-tooltip-common
     ((,class (:foreground ,soria-green))))

   `(company-tooltip-annotation
     ((,class (:inherit font-lock-type-face))))

   `(company-scrollbar-fg
     ((,class (:background ,soria-white))))

   `(company-scrollbar-bg
     ((,class (:background ,soria-statusgray))))

   `(company-preview-search
     ((,class (:background ,soria-white))))

   ;; company-box

   `(company-box-candidate
     ((,class (:foreground ,soria-white))))

   `(company-box-scrollbar
     ((,class (:inherit company-scrollbar-fg))))

   ;; ansi color names
   (custom-theme-set-variables
    'soria
    `(ansi-color-names-vector
      [,soria-darkgray ,soria-redpastel ,soria-green ,soria-yellow ,soria-blue
                       ,soria-darkpurple ,soria-purple ,soria-white]))

   ;; Flycheck

   `(flycheck-error
     ((,(append '((supports :underline (:style wave))) class)
       (:underline
        (:style wave :color ,soria-redpastel)
        :inherit unspecified))))

   `(flycheck-warning
     ((,(append '((supports :underline (:style wave))) class)
       (:underline
        (:style wave :color ,soria-orange)
        :inherit unspecified))))

   `(flycheck-info
     ((,(append '((supports :underline (:style wave))) class)
       (:underline
        (:style wave :color ,soria-blue)
        :inherit unspecified))))

   `(flycheck-fringe-error
     ((,(append '((supports :underline (:style wave))) class)
       (:underline
        (:style wave :color ,soria-redpastel)
        :inherit unspecified))))

   `(flycheck-fringe-warning
     ((,(append '((supports :underline (:style wave))) class)
       (:underline
        (:style wave :color ,soria-orange)
        :inherit unspecified))))

   `(flycheck-fringe-info
     ((,(append '((supports :underline (:style wave))) class)
       (:underline
        (:style wave :color ,soria-blue)
        :inherit unspecified))))

   ;; Flyspell

   `(flyspell-duplicate
     ((,(append '((supports :underline (:style wave))) class)
       (:underline
        (:style wave :color ,soria-orange)
        :inherit unspecified))))

   `(flyspell-incorrect
     ((,(append '((supports :underline (:style wave))) class)
       (:underline
        (:style wave :color ,soria-redpastel)
        :inherit unspecified))))

   ;; languagetool
   `(langtool-errline
     ((,(append '((supports :underline (:style wave))) class)
       (:underline
        (:style wave :color ,soria-redpastel)
        :inherit unspecified))))

   `(langtool-correction-face
     ((,(append '((supports :underline (:style wave))) class)
       (:underline (:style wave :color ,soria-green) :inherit unspecified))))

   ;; eldoc

   `(eldoc-highlight-function-argument
     ((,class (:foreground ,soria-green
                           :underline nil))))

   ;; Makefile

   `(makefile-space
     ((,class (:background ,soria-darkpurple))))

   ;; eshell

   `(eshell-prompt
     ((,class (:inherit default))))

   `(eshell-ls-archive
     ((,class (:inherit default))))

   `(eshell-ls-backup
     ((,class (:inherit default))))

   `(eshell-ls-clutter
     ((,class (:inherit default))))

   `(eshell-ls-unreadable
     ((,class (:inherit default))))

   `(eshell-ls-product
     ((,class (:inherit default))))

   `(eshell-ls-special
     ((,class (:inherit default))))

   `(eshell-ls-directory
     ((,class (:foreground ,soria-blue))))

   `(eshell-ls-executable
     ((,class (:foreground ,soria-yellow))))

   `(eshell-ls-missing
     ((,class (:foreground ,soria-redpastel))))

   `(eshell-ls-symlink
     ((,class (:foreground ,soria-darkpurple))))

   ;; rainbow-delimiters

   `(rainbow-delimiters-depth-1-face
     ((,class (:foreground ,soria-brightgreen))))

   `(rainbow-delimiters-depth-2-face
     ((,class (:foreground ,soria-redpastel))))

   `(rainbow-delimiters-depth-3-face
     ((,class (:foreground ,soria-orange))))

   `(rainbow-delimiters-depth-4-face
     ((,class (:foreground ,soria-blue))))

   `(rainbow-delimiters-depth-5-face
     ((,class (:foreground ,soria-white))))

   `(rainbow-delimiters-depth-6-face
     ((,class (:foreground ,soria-white))))

   `(rainbow-delimiters-depth-7-face
     ((,class (:foreground ,soria-white))))

   `(rainbow-delimiters-depth-8-face
     ((,class (:foreground ,soria-white))))

   `(rainbow-delimiters-depth-9-face
     ((,class (:foreground ,soria-white))))

   `(rainbow-delimiters-unmatched-face
     ((,class (:foreground ,soria-purple :bold t))))

   `(rainbow-delimiters-missmatched-face
     ((,class (:foreground ,soria-purple :bold t))))

   ;; Magit

   `(magit-diff-file-heading
     ((,class (:foreground ,soria-white
                           :weight normal))))

   `(magit-diff-file-heading-highlight
     ((,class (:inherit magit-diff-file-heading))))

   `(magit-diff-file-heading-selection
     ((,class (:foreground ,soria-white
                           :weight normal))))

   `(magit-diff-hunk-heading
     ((,class (:foreground ,soria-white
                           :weight normal))))

   `(magit-diff-hunk-heading-highlight
     ((,class (:inherit magit-diff-hunk-heading))))

   `(magit-diff-hunk-heading-selection
     ((,class (:foreground ,soria-white
                           :weight normal))))

   `(magit-diff-lines-heading
     ((,class (:foreground ,soria-white
                           :weight normal))))

   `(magit-diff-lines-boundary
     ((,class (:foreground ,soria-white
                           :weight normal))))

   `(magit-diff-conflict-heading
     ((,class (:foreground ,soria-redpastel
                           :weight normal))))

   `(magit-diff-added
     ((,class (:foreground ,soria-green
                           :background ,soria-darkgray))))

   `(magit-diff-added-highlight
     ((,class (:inherit magit-diff-added))))

   `(magit-diff-removed
     ((,class (:foreground ,soria-redpastel
                           :background ,soria-darkgray))))

   `(magit-diff-removed-highlight
     ((,class (:inherit magit-diff-removed))))

   `(magit-diff-our
     ((,class (:foreground ,soria-blue
                           :weight normal))))

   `(magit-diff-base
     ((,class (:foreground ,soria-white
                           :weight normal))))

   `(magit-diff-their
     ((,class (:foreground ,soria-orange
                           :weight normal))))

   `(magit-diff-context
     ((,class (:inherit font-lock-comment-face))))

   `(magit-diff-our-highlight
     ((,class (:inherit magit-diff-context))))

   `(magit-diff-our-highlight
     ((,class (:inherit magit-diff-context))))

   `(magit-diff-their-highlight
     ((,class (:inherit magit-diff-context))))

   `(magit-diff-context-highlight
     ((,class (:inherit magit-diff-context))))

   `(magit-diffstat-added
     ((,class (:foreground ,soria-green))))

   `(magit-diffstat-removed
     ((,class (:foreground ,soria-redpastel))))

   `(magit-process-ok
     ((,class (:inherit default))))

   `(magit-process-ng
     ((,class (:foreground ,soria-redpastel
                           :weight normal))))

   `(magit-rebase-hash
     ((,class (:foreground ,soria-yellow
                           :weight normal))))

   `(magit-log-graph
     ((,class (:inherit font-lock-comment-face))))

   `(magit-log-author
     ((,class (:foreground ,soria-blue))))

   `(magit-log-date
     ((,class (:inherit font-lock-comment-face))))

   `(magit-log-head-label-bisect-bad
     ((,class (:foreground ,soria-redpastel
                           :background ,soria-darkgray
                           :box 1))))

   `(magit-log-head-label-bisect-good
     ((,class (:foreground ,soria-green
                           :background ,soria-darkgray
                           :box 1))))

   `(magit-log-head-label-default
     ((,class (:foreground ,soria-gray
                           :box 1))))

   `(magit-log-head-label-local
     ((,class (:foreground ,soria-darkpurple
                           :background ,soria-darkgray
                           :box 1))))

   `(magit-log-head-label-patches
     ((,class (:foreground ,soria-green
                           :background ,soria-darkgray
                           :box 1))))

   `(magit-log-head-label-remote
     ((,class (:foreground ,soria-orange
                           :background ,soria-darkgray
                           :box 1))))

   `(magit-log-head-label-tags
     ((,class (:foreground ,soria-yellow
                           :background ,soria-darkgray
                           :box 1))))

   `(magit-log-sha1
     ((,class (:foreground ,soria-yellow))))

   `(magit-bisect-good
     ((,class (:inherit default))))

   `(magit-bisect-skip
     ((,class (:inherit default))))

   `(magit-bisect-bad
     ((,class (:foreground ,soria-redpastel
                           :weight normal))))

   `(magit-sequence-pick
     ((,class (:inherit default))))

   `(magit-sequence-stop
     ((,class (:foreground ,soria-green
                           :weight normal))))

   `(magit-sequence-part
     ((,class (:foreground ,soria-orange
                           :weight normal))))

   `(magit-sequence-head
     ((,class (:foreground ,soria-blue
                           :weight normal))))

   `(magit-sequence-drop
     ((,class (:foreground ,soria-redpastel
                           :weight normal))))

   `(magit-sequence-done
     ((,class (:inherit magit-hash))))

   `(magit-sequence-onto
     ((,class (:inherit magit-sequence-done))))

   `(magit-section-title
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(magit-section-heading
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(magit-section-highlight
     ((,class (:background ,soria-darkgray))))

   `(magit-section-secondary-heading
     ((,class (:background ,soria-darkgray))))

   `(magit-section-heading-selection
     ((,class (:foreground ,soria-orange :weight normal))))

   `(magit-header-line
     ((,class (:inherit magit-section-heading))))

   `(magit-dimmed
     ((,class (:inherit font-lock-comment-face))))

   `(magit-hash
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(magit-tag
     ((,class (:background ,soria-darkgray
                           :foreground ,soria-green))))

   `(magit-branch-remote
     ((,class (:foreground ,soria-orange :weight normal))))

   `(magit-branch-local
     ((,class (:foreground ,soria-purple :weight normal))))

   `(magit-branch-current
     ((,class (:foreground ,soria-purple :weight normal))))

   `(magit-branch
     ((,class (:foreground ,soria-orange :weight normal))))

   `(magit-item-highlight
     ((,class (:inherit default))))

   `(magit-head
     ((,class (:inherit branch-local))))

   `(magit-refname
     ((,class (:inherit font-lock-comment-face))))

   `(magit-refname-stash
     ((,class (:inherit font-lock-comment-face))))

   `(magit-refname-wip
     ((,class (:inherit font-lock-comment-face))))

   `(magit-signature-good
     ((,class (:foreground ,soria-green
                           :weight normal))))

   `(magit-signature-bad
     ((,class (:foreground ,soria-redpastel
                           :weight normal))))

   `(magit-signature-unstrusted
     ((,class (:foreground ,soria-orange
                           :weight normal))))

   `(magit-cherry-unmatched
     ((,class (:foreground ,soria-blue
                           :weight normal))))

   `(magit-cherry-equivalent
     ((,class (:foreground ,soria-purple
                           :weight normal))))

   `(magit-filename
     ((,class (:foreground ,soria-white))))

   `(magit-blame-heading
     ((,class (:inherit font-lock-comment-face))))

   `(magit-blame-summary
     ((,class (:inherit magit-blame-heading))))

   `(magit-blame-hash
     ((,class (:inherit magit-blame-heading))))

   `(magit-blame-name
     ((,class (:inherit magit-blame-heading))))

   `(magit-blame-date
     ((,class (:inherit magit-blame-heading))))

   ;; git-timemachine

   `(git-timemachine-commit
     ((,class (:foreground ,soria-white :weight normal))))

   `(git-timemachine-minibuffer-detail-face
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(git-timemachine-minibuffer-author-face
     ((,class (:foreground ,soria-blue :weight normal))))

   ;; diff

   `(diff-added
     ((,class (:foreground ,soria-green :background ,soria-darkgray))))

   `(diff-changed
     ((,class (:background ,soria-darkgray :foreground ,soria-darkpurple))))

   `(diff-removed
     ((,class (:background ,soria-darkgray :foreground ,soria-redpastel))))

   `(diff-header
     ((,class (:background ,soria-darkgray :foreground ,soria-white))))

   `(diff-file-header
     ((,class (:background ,soria-darkgray :foreground ,soria-white))))

   `(diff-refine-added
     ((,class (:background ,soria-darkgreen :foreground ,soria-darkgray))))

   `(diff-refine-change
     ((,class (:background ,soria-darkpurple :foreground ,soria-darkgray))))

   `(diff-refine-removed
     ((,class (:background ,soria-redpastel :foreground ,soria-darkgray))))

   ;; diff-hl

   `(diff-hl-change
     ((,class (:background ,soria-darkpurple :foreground ,soria-whitest))))

   `(diff-hl-delete
     ((,class (:background ,soria-redpastel :foreground ,soria-whitest))))

   `(diff-hl-insert
     ((,class (:background ,soria-darkgreen :foreground ,soria-whitest))))

   `(diff-hl-unknown
     ((,class (:background ,soria-darkpurple :foreground ,soria-whitest))))

   ;; sh-mode

   `(sh-heredoc
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(sh-quoted-exec
     ((,class (:foreground ,soria-redpastel :weight normal))))

   `(sh-escaped-newline
     ((,class (:foreground ,soria-redpastel :weight normal))))

   ;; message-mode

   `(message-cited-text
     ((,class (:foreground ,soria-gray :weight normal))))

   `(message-cited-text-1
     ((,class (:foreground ,soria-white :weight normal))))

   `(message-cited-text-2
     ((,class (:foreground ,soria-gray :weight normal))))

   `(message-cited-text-3
     ((,class (:foreground ,soria-gray :weight normal))))

   `(message-cited-text-4
     ((,class (:foreground ,soria-gray :weight normal))))

   `(message-header-name
     ((,class (:foreground ,soria-gray :weight normal))))

   `(message-header-other
     ((,class (:foreground ,soria-white :weight normal))))

   `(message-header-to
     ((,class (:foreground ,soria-white :weight normal))))

   `(message-header-cc
     ((,class (:foreground ,soria-white :weight normal))))

   `(message-header-newsgroups
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(message-header-subject
     ((,class (:foreground ,soria-blue :weight normal))))

   `(message-header-xheader
     ((,class (:foreground ,soria-blue :weight normal))))

   `(message-mml
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(message-separator
     ((,class (:foreground ,soria-gray :slant italic))))

   ;; Evil mode

   `(evil-ex-info
     ((,class (:foreground ,soria-redpastel :inherit normal))))

   `(evil-ex-substitute-matches
     ((,class (:foreground ,soria-redpastel :inherit normal))))

   `(evil-ex-substitute-replacement
     ((,class (:foreground ,soria-green :inherit normal))))

   `(evil-search-highlight-persist-highlight-face
     ((,class (:inherit region))))

   ;; mu4e

   `(mu4e-cited-1-face
     ((,class (:foreground ,soria-gray :slant italic :weight normal))))

   `(mu4e-cited-2-face
     ((,class (:foreground ,soria-gray :slant italic :weight normal))))

   `(mu4e-cited-3-face
     ((,class (:foreground ,soria-gray :slant italic :weight normal))))

   `(mu4e-cited-4-face
     ((,class (:foreground ,soria-gray :slant italic :weight normal))))

   `(mu4e-cited-5-face
     ((,class (:foreground ,soria-gray :slant italic :weight normal))))

   `(mu4e-cited-6-face
     ((,class (:foreground ,soria-gray :slant italic :weight normal))))

   `(mu4e-cited-7-face
     ((,class (:foreground ,soria-gray :slant italic :weight normal))))

   `(mu4e-flagged-face
     ((,class (:foreground ,soria-darkpurple :weight normal))))

   `(mu4e-view-url-number-face
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(mu4e-warning-face
     ((,class (:foreground ,soria-redpastel :slant normal :weight normal))))

   `(mu4e-highlight-face
     ((,class (:inherit unspecified
                        :foreground ,soria-blue
                        :weight normal))))

   `(mu4e-header-highlight-face
     ((,class (:inherit unspecified
                        :foreground ,soria-white
                        :background ,soria-statusgray
                        :weight normal))))

   `(mu4e-draft-face
     ((,class (:inherit font-lock-string-face))))

   `(mu4e-footer-face
     ((,class (:inherit font-lock-comment-face))))

   `(mu4e-forwarded-face
     ((,class (:inherit font-lock-builtin-face :weight normal))))

   `(mu4e-header-face
     ((,class (:inherit font-lock-comment-face))))

   `(mu4e-header-marks-face
     ((,class (:inherit font-lock-preprocessor-face))))

   `(mu4e-header-title-face
     ((,class (:inherit font-lock-type-face))))

   `(mu4e-highlight-face
     ((,class (:inherit font-lock-pseudo-keyword-face :weight normal))))

   `(mu4e-moved-face
     ((,class (:inherit font-lock-comment-face :slant italic))))

   `(mu4e-ok-face
     ((,class (:inherit font-lock-comment-face :slant normal :weight normal))))

   `(mu4e-replied-face
     ((,class (:inherit font-lock-builtin-face :weight normal))))

   `(mu4e-system-face
     ((,class (:inherit font-lock-comment-face :slant italic))))

   `(mu4e-title-face
     ((,class (:inherit custom-face-tag :weight normal))))

   `(mu4e-trashed-face
     ((,class (:inherit font-lock-comment-face :strike-through t))))

   `(mu4e-unread-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(mu4e-header-key-face
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(mu4e-context-face
     ((,class (:inherit mu4e-title-face :weight normal))))

   `(mu4e-modeline-face
     ((,class (:inherit font-lock-string-face :weight normal))))

   `(mu4e-region-code
     ((,class (:background  ,soria-darkgray))))

   `(mu4e-view-attach-number-face
     ((,class (:inherit font-lock-variable-name-face :weight normal))))

   `(mu4e-view-contact-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(mu4e-view-header-key-face
     ((,class (:inherit message-header-name :weight normal))))

   `(mu4e-view-header-value-face
     ((,class (:foreground ,soria-blue :weight normal :slant normal))))

   `(mu4e-view-link-face
     ((,class (:inherit link))))

   `(mu4e-view-special-header-value-face
     ((,class (:foreground ,soria-blue :weight normal :underline nil))))

   ;; ERC

   `(erc-current-nick-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(erc-dangerous-host-face
     ((,class (:foreground ,soria-redpastel :weight normal))))

   `(erc-pal-face
     ((,class (:foreground ,soria-purple :weight normal))))

   `(erc-fool-face
     ((,class (:foreground ,soria-gray :weight normal))))

   `(erc-keyword-face
     ((,class (:foreground ,soria-green :weight normal))))

   `(erc-direct-msg-face
     ((,class (:foreground ,soria-redpastel :weight normal))))

   `(erc-header-line-face
     ((,class (:foreground ,soria-linegray :background ,soria-darkgray :weight normal))))

   `(erc-header-line
     ((,class (:foreground ,soria-linegray :background ,soria-darkgray :weight normal))))

   `(erc-input-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(erc-prompt-face
     ((,class (:foreground ,soria-white :background ,soria-darkgray :weight normal))))

   `(erc-notice-face
     ((,class (:foreground ,soria-gray :weight normal))))

   `(erc-error-face
     ((,class (:foreground ,soria-redpastel :weight normal))))

   `(erc-my-nick-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(erc-nick-default-face
     ((,class (:weight normal))))

   `(erc-nick-msg-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(erc-inverse-face
     ((,class (:foreground ,soria-black :background ,soria-white :weight normal))))

   `(erc-nick-prefix-face
     ((,class (:inherit erc-nick-default-face))))

   `(erc-my-nick-prefix-face
     ((,class (:inherit erc-nick-default-face))))

   `(erc-direct-msg-face
     ((,class (:foreground ,soria-green :weight normal))))

   `(erc-command-indicator-face
     ((,class (:weight normal))))

   `(erc-action-face
     ((,class (:weight normal))))

   `(fg:erc-color-face0
     ((,class (:foreground ,soria-white :weight normal))))

   `(fg:erc-color-face1
     ((,class (:foreground ,soria-green :weight normal))))

   `(fg:erc-color-face2
     ((,class (:foreground ,soria-blue :weight normal))))

   `(fg:erc-color-face3
     ((,class (:foreground ,soria-purple :weight normal))))

   `(fg:erc-color-face4
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(fg:erc-color-face5
     ((,class (:foreground ,soria-redpastel :weight normal))))

   `(fg:erc-color-face6
     ((,class (:foreground ,soria-orange :weight normal))))

   `(fg:erc-color-face7
     ((,class (:foreground ,soria-darkgreen :weight normal))))

   `(fg:erc-color-face8
     ((,class (:foreground ,soria-whitest :weight normal))))

   `(fg:erc-color-face9
     ((,class (:foreground ,soria-purple :weight normal))))

   `(fg:erc-color-face10
     ((,class (:foreground ,soria-brightgreen :weight normal))))

   `(fg:erc-color-face11
     ((,class (:foreground ,soria-white :weight normal))))

   `(fg:erc-color-face12
     ((,class (:foreground ,soria-white :weight normal))))

   `(fg:erc-color-face13
     ((,class (:foreground ,soria-white :weight normal))))

   `(fg:erc-color-face14
     ((,class (:foreground ,soria-white :weight normal))))

   `(fg:erc-color-face15
     ((,class (:foreground ,soria-white :weight normal))))

   `(bg:erc-color-face0
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face1
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face2
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face3
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face4
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face5
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face6
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face7
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face8
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face9
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face10
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face11
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face12
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face13
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face14
     ((,class (:background ,soria-darkgray :weight normal))))

   `(bg:erc-color-face15
     ((,class (:background ,soria-darkgray :weight normal))))

   `(erc-timestamp-face
     ((,class (:background ,soria-darkgray :foreground ,soria-gray :weight normal))))

   `(erc-button
     ((,class (:weight normal))))

   ;; circe

   `(circe-highlight-all-nicks-face
     ((,class (:foreground ,soria-green :weight normal))))

   `(circe-prompt-face
     ((,class (:background ,soria-black :foreground ,soria-white :weight normal))))

   `(circe-server-face
     ((,class (:foreground ,soria-blue :weight normal))))

   `(circe-fool-face
     ((,class (:foreground ,soria-gray :weight normal))))

   `(lui-track-bar
     ((,class (:inherit default))))

   `(lui-irc-colors-fg-0-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(lui-irc-colors-fg-1-face
     ((,class (:foreground ,soria-green :weight normal))))

   `(lui-irc-colors-fg-2-face
     ((,class (:foreground ,soria-blue :weight normal))))

   `(lui-irc-colors-fg-3-face
     ((,class (:foreground ,soria-purple :weight normal))))

   `(lui-irc-colors-fg-4-face
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(lui-irc-colors-fg-5-face
     ((,class (:foreground ,soria-redpastel :weight normal))))

   `(lui-irc-colors-fg-6-face
     ((,class (:foreground ,soria-orange :weight normal))))

   `(lui-irc-colors-fg-7-face
     ((,class (:foreground ,soria-darkgreen :weight normal))))

   `(lui-irc-colors-fg-8-face
     ((,class (:foreground ,soria-whitest :weight normal))))

   `(lui-irc-colors-fg-9-face
     ((,class (:foreground ,soria-darkpurple :weight normal))))

   `(lui-irc-colors-fg-10-face
     ((,class (:foreground ,soria-brightgreen :weight normal))))

   `(lui-irc-colors-fg-11-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(lui-irc-colors-fg-12-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(lui-irc-colors-fg-13-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(lui-irc-colors-fg-14-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(lui-irc-colors-fg-15-face
     ((,class (:foreground ,soria-white :weight normal))))

   `(lui-irc-colors-fg-16-face
     ((,class (:foreground ,soria-white :weight normal))))

   ;; org-mode

   `(org-document-title
     ((,class (:foreground ,soria-whitest :weight bold))))

   `(org-document-info
     ((,class (:foreground ,soria-whitest :weight normal))))

   `(org-level-1
     ((,class (:foreground ,soria-whitest :weight bold))))

   `(org-level-2
     ((,class (:foreground ,soria-whitest :weight normal))))

   `(org-level-3
     ((,class (:foreground ,soria-whitest :weight normal))))

   `(org-level-4
     ((,class (:foreground ,soria-whitest :weight normal))))

   `(org-level-5
     ((,class (:foreground ,soria-whitest :weight normal))))

   `(org-level-6
     ((,class (:foreground ,soria-whitest :weight normal))))

   `(org-level-7
     ((,class (:foreground ,soria-whitest :weight normal))))

   `(org-level-8
     ((,class (:foreground ,soria-whitest :weight normal))))

   `(org-footnote
     ((,class (:foreground ,soria-blue :weight normal :underline nil))))

   `(org-table
     ((,class (:foreground ,soria-white :weight normal))))

   `(org-formula
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(org-todo
     ((,class (:foreground ,soria-redpastel :weight normal))))

   `(org-done
     ((,class (:inherit success :weight normal))))

   `(org-agenda-done
     ((,class (:inherit org-done))))

   `(org-headline-done
     ((,class (:inherit org-done))))

   `(org-date
     ((,class (:foreground ,soria-gray, :weight normal :underline nil))))

   `(org-drawer ((,class (:inherit org-done))))

   `(org-special-keyword ((,class (:inherit org-done))))

   ;; markup-faces (which also includes adoc-mode)

   `(markup-title-0-face
     ((,class (:inherit org-level-1))))

   `(markup-title-1-face
     ((,class (:inherit org-level-1))))

   `(markup-title-2-face
     ((,class (:inherit org-level-2))))

   `(markup-title-3-face
     ((,class (:inherit org-level-3))))

   `(markup-title-4-face
     ((,class (:inherit org-level-4))))

   `(markup-title-5-face
     ((,class (:inherit org-level-5))))

   `(markup-meta-face
     ((,class (:inherit org-level-1))))

   `(markup-meta-hide-face
     ((,class (:inherit org-level-1))))

   `(markup-list-face
     ((,class (:inherit org-table))))

   `(markup-internal-reference-face
     ((,class (:inherit link))))

   `(markup-reference-face
     ((,class (:inherit link))))

   `(markup-typewriter-face
     ((,class (:inherit org-verbatim))))

   `(markup-verbatim-face
     ((,class (:inherit org-verbatim))))

   `(markup-comment-face
     ((,class (:inherit font-lock-comment-face))))

   `(markup-anchor-face
     ((,class (:inherit org-target))))

   ;; modeline: this is the base for faces from some modelines (doom-modeline).

   `(mode-line-emphasis
     ((,class (:foreground ,soria-white :inherit bold))))

   `(mode-line-buffer-id
     ((,class (:foreground ,soria-white :inherit bold))))

   `(mode-line-highlight
     ((,class (:foreground ,soria-yellow))))

   ;; doom-modeline

   `(doom-modeline-buffer-modified
     ((,class (:foreground ,soria-orange :weight normal))))

   `(doom-modeline-buffer-path
     ((,class (:foreground ,soria-white :weight normal))))

   `(doom-modeline-project-dir
     ((,class (:foreground ,soria-yellow :weight normal))))

   `(doom-modeline-evil-emacs-state
     ((,class (:foreground ,soria-darkpurple :weight bold))))

   `(doom-modeline-evil-insert-state
     ((,class (:foreground ,soria-orange :weight bold))))

   `(doom-modeline-evil-visual-state
     ((,class (:foreground ,soria-purple :weight bold))))

   `(doom-modeline-info
     ((,class (:foreground ,soria-green :weight normal))))

   `(doom-modeline-warning
     ((,class (:foreground ,soria-orange :weight normal))))))

(defun soria-theme-purple-identifiers ()
  "Make function identifiers purple.
This function might be used as a hook for modes that prefer having purple
function identifiers instead of the default white.  This might seem hackish,
but it tries to workaround discrepancies between Vim and Emacs in terms of
identifiers"

  (interactive)

  (let ((soria-purple "#dfafdf"))
    (set (make-local-variable 'face-remapping-alist)
         `((font-lock-function-name-face :foreground ,soria-purple)))))

(provide-theme 'soria)

;; Make package-lint happy. This file is not meant to be used as a library.
(provide 'soria-theme)

;;; soria-theme.el ends here
