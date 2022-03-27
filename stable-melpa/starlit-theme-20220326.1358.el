;;; starlit-theme.el --- Deep blue dark theme with bright colors from the starlit sky  -*- lexical-binding: t -*-

;; Copyright (C) 2022-2022

;; Author: Jonas Jelten <jj@sft.lol>
;; Keywords: faces
;; Package-Version: 20220326.1358
;; Package-Commit: f3b26f134c54387aaf5c470e1d0ce811bf186604
;; URL: https://github.com/SFTtech/starlit-emacs
;; Version: 0.1

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

;; Starlit is a deep blue dark theme with brighter foreground colors like
;; a starlit sky.

;;; Code:

(when (version< emacs-version "25.1")
  (error "Starlit theme requires Emacs 25 or later!"))

(deftheme starlit
  "Starlit color theme - dark and colorful like beautiful stars of our universe.
Starlit is a dark theme with a dark blue background,
and foreground colors optimized for happy programming.")

(defgroup starlit-theme nil
  "Starlit theme."
  :group 'faces
  :prefix "starlit-"
  :link '(url-link :tag "GitHub" "http://github.com/SFTtech/starlit-emacs")
  :tag "Starlit theme")


;;; Color definitions

(defvar starlit-default-colors nil
  "Alist of default Starlit colors.
Each element has the form (NAME . HEX).")

(setq starlit-default-colors
      '(("current-line"                . "#0a121a")
        ("block"                       . "#11151e")
        ("background"                  . "#131729")
        ("backgroundlight"             . "#161930")
        ("bluepopup"                   . "#102040")
        ("selection"                   . "#103050")
        ("bluedark"                    . "#0e355d")
        ("bluehighlight"               . "#1e90ff")
        ("blue"                        . "#00bfff")
        ("bluelight"                   . "#87ceff")
        ("type"                        . "#98f5ff")
        ("cyan"                        . "#30f2f1")
        ("shadow"                      . "#cdc9c9")
        ("comment"                     . "#969896")
        ("greendark"                   . "#155903")
        ("aqua"                        . "#70c0b1")
        ("greenlight"                  . "#4df094")
        ("green"                       . "#a2cd5a")
        ("purple"                      . "#b387d8")
        ("redhighlight"                . "#ee0212")
        ("red"                         . "#de4e53")
        ("softred"                     . "#f08080")
        ("orange"                      . "#da9520")
        ("gold"                        . "#ffd700")
        ("yellow"                      . "#e7c547")
        ("string"                      . "#e5b489")
        ("docstring"                   . "#ffe4b5")
        ("foreground"                  . "#efedef")
        ("white"                       . "#ffffff")))


;;;###autoload
(defcustom starlit-custom-colors '()
  "Alist to override the theme's default colors.
Definitions in the alist will override a subset of the default colors
in the theme."
  :group 'starlit-theme
  :type '(alist
          :key-type (string :tag "Name")
          :value-type (string :tag "Hex")))


(defcustom starlit-scale-outline-headlines t
  "Increase the font size of `outline-mode' headlines."
  :type 'boolean
  :group 'starlit-theme)


(defcustom starlit-scale-org-headlines nil
  "Increase the font size of `org-mode' headlines."
  :type 'boolean
  :group 'starlit-theme)


;;; Mapping colors to Faces
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Defining-Faces.html
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Face-Attributes.html

(defun starlit-theme-setup ()
  "Set up faces with colors from the starlit base and custom palette."
  ;; create local variable mappings
  (let ((colorful t)
        ;; convert the keys to internal variables
        ;; and override the color customizations.
        (color-alist (mapcar (lambda (cons) `(,(intern (car cons)) . ,(cdr cons)))
                             (append starlit-custom-colors
                                     starlit-default-colors))))
    ;; the .key things in the body create compiletime lookups in `color-alist'.
    (let-alist color-alist
      (custom-theme-set-faces
       'starlit

       ;;; general faces
       `(bold ((,colorful (:weight bold))))
       `(bold-italic ((,colorful (:slant italic :weight bold))))
       `(border ((,colorful (:background ,.current-line))))
       `(border-glyph ((,colorful (nil))))
       `(cursor ((,colorful (:background ,.gold))))
       `(default ((,colorful (:foreground ,.foreground :background ,.background))))
       `(error ((,colorful (:foreground ,.red))))
       `(fringe ((,colorful (:background ,.current-line))))
       `(gui-element ((,colorful (:background ,.current-line :foreground ,.foreground))))
       `(italic ((,colorful (:slant italic))))
       `(header-line ((,colorful (:inherit mode-line :foreground ,.purple :background nil))))
       `(line-number ((,colorful (:inherit default :foreground ,.shadow))))
       `(line-number-current-line ((,colorful (:inherit line-number :background ,.current-line))))
       `(link ((,colorful (:foreground nil :underline t))))
       `(match ((,colorful (:foreground ,.blue :background ,.background :inverse-video t))))
       `(minibuffer-prompt ((,colorful (:foreground ,.blue))))
       `(mode-line ((,colorful (:foreground nil :background ,.current-line :box (:line-width -1 :color ,.bluehighlight :style released-button))) (t :inverse-video t)))
       `(mode-line-buffer-id ((,colorful (:foreground ,.purple :background nil))))
       `(mode-line-emphasis ((,colorful (:foreground ,.foreground :slant italic))))
       `(mode-line-highlight ((,colorful (:foreground ,.purple :box nil))))
       `(mode-line-inactive ((,colorful (:inherit mode-line :foreground ,.comment :background ,.current-line :weight normal :box (:line-width -1 :color ,.bluedark)))))
       `(region ((,colorful (:background ,.selection :extend t)) (t :inverse-video t)))
       `(secondary-selection ((,colorful (:background ,.current-line))))
       `(shadow ((,colorful (:foreground ,.comment))))
       `(success ((,colorful (:foreground ,.greenlight))))
       `(underline ((,colorful (:underline t))))
       `(warning ((,colorful (:foreground ,.orange))))

       ;;; mode specifics
       `(anzu-mode-line ((,colorful (:foreground ,.orange))))
       `(anzu-replace-highlight ((,colorful (:inherit isearch-lazy-highlight-face))))
       `(anzu-replace-to ((,colorful (:inherit isearch))))
       `(company-tooltip-selection ((,colorful (:background ,.selection))))
       `(company-tooltip ((,colorful (:background ,.bluepopup))))
       `(company-tooltip-scrollbar-thumb ((,colorful (:background ,.bluehighlight))))
       `(company-tooltip-scrollbar-track ((,colorful (:background ,.bluedark))))
       `(compilation-column-number ((,colorful (:foreground ,.yellow))))
       `(compilation-line-number ((,colorful (:foreground ,.yellow))))
       `(compilation-message-face ((,colorful (:foreground ,.blue))))
       `(compilation-mode-line-exit ((,colorful (:foreground ,.green))))
       `(compilation-mode-line-fail ((,colorful (:foreground ,.red))))
       `(compilation-mode-line-run ((,colorful (:foreground ,.blue))))
       `(custom-group-tag ((,colorful (:foreground ,.blue))))
       `(custom-state ((,colorful (:foreground ,.green))))
       `(custom-variable-tag ((,colorful (:foreground ,.blue))))
       `(diff-added ((,colorful (:foreground ,.green))))
       `(diff-changed ((,colorful (:foreground ,.purple))))
       `(diff-file-header ((,colorful (:foreground ,.blue :background nil))))
       `(diff-header ((,colorful (:foreground ,.aqua :background nil))))
       `(diff-hunk-header ((,colorful (:foreground ,.purple))))
       `(diff-refine-added ((,colorful (:inherit diff-added :inverse-video t))))
       `(diff-refine-removed ((,colorful (:inherit diff-removed :inverse-video t))))
       `(diff-removed ((,colorful (:foreground ,.orange))))
       `(ediff-even-diff-A ((,colorful (:foreground nil :background nil :inverse-video t))))
       `(ediff-even-diff-B ((,colorful (:foreground nil :background nil :inverse-video t))))
       `(ediff-odd-diff-A  ((,colorful (:foreground ,.comment :background nil :inverse-video t))))
       `(ediff-odd-diff-B  ((,colorful (:foreground ,.comment :background nil :inverse-video t))))
       `(eldoc-highlight-function-argument ((,colorful (:foreground ,.green :weight bold))))
       `(flx-highlight-face ((,colorful (:inherit nil :foreground ,.yellow :weight bold :underline nil))))
       `(flycheck-error ((,colorful (:underline (:style wave :color ,.red)))))
       `(flycheck-warning ((,colorful (:underline (:style wave :color ,.orange)))))
       `(flymake-errline ((,colorful (:underline (:style wave :color ,.red) :background ,.background))))
       `(flymake-warnline ((,colorful (:underline (:style wave :color ,.orange) :background ,.background))))
       `(font-lock-builtin-face ((,colorful (:foreground ,.softred))))
       `(font-lock-comment-delimiter-face ((,colorful (:foreground ,.comment))))
       `(font-lock-comment-face ((,colorful (:foreground ,.comment))))
       `(font-lock-constant-face ((,colorful (:foreground ,.green))))
       `(font-lock-doc-face ((,colorful (:foreground ,.docstring))))
       `(font-lock-function-name-face ((,colorful (:foreground ,.orange))))
       `(font-lock-keyword-face ((,colorful (:foreground ,.blue))))
       `(font-lock-negation-char-face ((,colorful (:foreground ,.blue))))
       `(font-lock-preprocessor-face ((,colorful (:foreground ,.gold))))
       `(font-lock-regexp-grouping-backslash ((,colorful (:foreground ,.yellow))))
       `(font-lock-regexp-grouping-construct ((,colorful (:foreground ,.purple))))
       `(font-lock-string-face ((,colorful (:foreground ,.string))))
       `(font-lock-type-face ((,colorful (:foreground ,.type))))
       `(font-lock-variable-name-face ((,colorful (:foreground ,.yellow))))
       `(font-lock-warning-face ((,colorful (:weight bold :foreground ,.red))))
       `(git-gutter-fr:added ((,colorful (:foreground ,.green :weight bold))))
       `(git-gutter-fr:deleted ((,colorful (:foreground ,.red :weight bold))))
       `(git-gutter-fr:modified ((,colorful (:foreground ,.purple :weight bold))))
       `(git-gutter:added ((,colorful (:foreground ,.green :weight bold))))
       `(git-gutter:deleted ((,colorful (:foreground ,.red :weight bold))))
       `(git-gutter:modified ((,colorful (:foreground ,.purple :weight bold))))
       `(git-gutter:unchanged ((,colorful (:background ,.yellow))))
       `(grep-context-face ((,colorful (:foreground ,.comment))))
       `(grep-error-face ((,colorful (:foreground ,.red :weight bold :underline t))))
       `(grep-hit-face ((,colorful (:foreground ,.blue))))
       `(grep-match-face ((,colorful (:foreground nil :background nil :inherit match))))
       `(helm-header ((,colorful (:inherit header-line :box (:line-width -1 :style released-button) :extend t))))
       `(helm-buffer-not-saved ((,colorful (:foreground ,.red :background nil))))
       `(helm-buffer-process ((,colorful (:foreground ,.cyan :background nil))))
       `(helm-buffer-saved-out ((,colorful (:foreground ,.softred :background nil))))
       `(helm-buffer-size ((,colorful (:foreground ,.shadow :background nil))))
       `(helm-ff-executable ((,colorful (:foreground ,.softred))))
       `(helm-ff-file ((,colorful (:foreground ,.foreground))))
       `(helm-ff-file-extension ((,colorful (:foreground ,.white))))
       `(helm-ff-directory ((,colorful (:foreground ,.bluelight :weight bold))))
       `(helm-selection ((,colorful (:background ,.greendark))))
       `(helm-selection-line ((,colorful (:inherit highlight))))
       `(helm-source-header ((,colorful (:inherit helm-header :foreground ,.foreground :background ,.bluedark :weight bold :box nil :height 1.2 :extend t))))
       `(highlight ((,colorful (:inverse-video nil :background ,.current-line))))
       `(highlight-80+ ((,colorful (:background ,.current-line))))
       `(highlight-parentheses-highlight ((nil (:weight bold))) t)
       `(highlight-symbol-face ((,colorful (:background ,.selection))))
       `(hl-sexp-face ((,colorful (:background ,.current-line))))
       `(idle-highlight ((((supports underline)) (:underline t))))
       `(ido-first-match ((,colorful (:foreground ,.orange))))
       `(ido-indicator ((,colorful (:foreground ,.red :background ,.background))))
       `(ido-only-match ((,colorful (:foreground ,.green))))
       `(ido-subdir ((,colorful (:foreground ,.purple))))
       `(ido-virtual ((,colorful (:foreground ,.comment))))
       `(isearch ((,colorful (:foreground ,.yellow :background ,.background :inverse-video t))))
       `(isearch-fail ((,colorful (:background ,.background :inherit font-lock-warning-face :inverse-video t))))
       `(isearch-lazy-highlight-face ((,colorful (:foreground ,.aqua :background ,.background :inverse-video t))))
       `(ledger-font-comment-face ((,colorful (:inherit font-lock-comment-face))))
       `(ledger-font-occur-narrowed-face ((,colorful (:inherit font-lock-comment-face :invisible t))))
       `(ledger-font-occur-xact-face ((,colorful (:inherit highlight))))
       `(ledger-font-payee-cleared-face ((,colorful (:foreground ,.green))))
       `(ledger-font-payee-uncleared-face ((,colorful (:foreground ,.aqua))))
       `(ledger-font-posting-account-cleared-face ((,colorful (:foreground ,.blue))))
       `(ledger-font-posting-account-face ((,colorful (:foreground ,.purple))))
       `(ledger-font-posting-account-pending-face ((,colorful (:foreground ,.yellow))))
       `(ledger-font-xact-highlight-face ((,colorful (:inherit highlight))))
       `(ledger-occur-narrowed-face ((,colorful (:inherit font-lock-comment-face :invisible t))))
       `(ledger-occur-xact-face ((,colorful (:inherit highlight))))
       `(markdown-link-face ((,colorful (:foreground ,.blue :underline t))))
       `(markdown-url-face ((,colorful (:inherit link))))
       `(message-header-cc ((,colorful (:inherit message-header-to :foreground nil))))
       `(message-header-name ((,colorful (:foreground ,.blue :background nil))))
       `(message-header-newsgroups ((,colorful (:foreground ,.aqua :background nil :slant normal))))
       `(message-header-other ((,colorful (:foreground nil :background nil :weight normal))))
       `(message-header-subject ((,colorful (:inherit message-header-other :weight bold :foreground ,.yellow))))
       `(message-header-to ((,colorful (:inherit message-header-other :weight bold :foreground ,.orange))))
       `(message-separator ((,colorful (:foreground ,.purple))))
       `(mmm-default-submode-face ((,colorful (:background ,.block))))
       `(org-agenda-date ((,colorful (:foreground ,.blue :underline nil))))
       `(org-agenda-dimmed-todo-face ((,colorful (:foreground ,.comment))))
       `(org-agenda-done ((,colorful (:foreground ,.green))))
       `(org-agenda-structure ((,colorful (:foreground ,.purple))))
       `(org-block ((,colorful (:foreground ,.orange :background ,.block))))
       `(org-code ((,colorful (:foreground ,.yellow))))
       `(org-column ((,colorful (:background ,.current-line))))
       `(org-column-title ((,colorful (:inherit org-column :weight bold :underline t))))
       `(org-date ((,colorful (:foreground ,.blue :underline t))))
       `(org-document-info ((,colorful (:foreground ,.aqua))))
       `(org-document-info-keyword ((,colorful (:foreground ,.green))))
       `(org-document-title ((,colorful (:weight bold :foreground ,.orange :height 1.45))))
       `(org-done ((,colorful (:foreground ,.green))))
       `(org-ellipsis ((,colorful (:foreground ,.comment))))
       `(org-footnote ((,colorful (:foreground ,.aqua))))
       `(org-formula ((,colorful (:foreground ,.red))))
       `(org-hide ((,colorful (:foreground ,.background :background ,.background))))
       `(org-level-1 ((,colorful (:inherit nil :foreground ,.bluelight ,@(when starlit-scale-org-headlines '(:height 1.3))))))
       `(org-level-2 ((,colorful (:inherit nil :foreground ,.yellow ,@(when starlit-scale-org-headlines '(:height 1.2))))))
       `(org-level-3 ((,colorful (:inherit nil :foreground ,.purple ,@(when starlit-scale-org-headlines '(:height 1.1))))))
       `(org-level-4 ((,colorful (:inherit nil :foreground ,.aqua))))
       `(org-level-5 ((,colorful (:inherit nil :foreground ,.orange))))
       `(org-level-6 ((,colorful (:inherit nil :foreground ,.greenlight))))
       `(org-level-7 ((,colorful (:inherit nil :foreground ,.type))))
       `(org-level-8 ((,colorful (:inherit nil :foreground ,.bluehighlight))))
       `(org-level-9 ((,colorful (:inherit nil :foreground ,.blue))))
       `(org-link ((,colorful (:foreground ,.blue :underline t))))
       `(org-meta-line ((,colorful (:inherit (fixed-pitch font-lock-comment-face) :foreground ,.bluedark))))
       `(org-ref-ref-face ((,colorful :underline t)))
       `(org-ref-label-face ((,colorful :underline t)))
       `(org-ref-cite-face ((,colorful :underline t)))
       `(org-ref-glossary-face ((,colorful :underline t)))
       `(org-ref-acronym-face ((,colorful :underline t)))
       `(org-scheduled ((,colorful (:foreground ,.green))))
       `(org-scheduled-previously ((,colorful (:foreground ,.orange))))
       `(org-scheduled-today ((,colorful (:foreground ,.green))))
       `(org-special-keyword ((,colorful (:foreground ,.orange))))
       `(org-table ((,colorful (:foreground ,.purple))))
       `(org-todo ((,colorful (:foreground ,.red))))
       `(org-upcoming-deadline ((,colorful (:foreground ,.orange))))
       `(org-warning ((,colorful (:weight bold :foreground ,.red))))
       `(outline-1 ((,colorful (:inherit nil :foreground ,.bluelight ,@(when starlit-scale-outline-headlines '(:height 1.3))))))
       `(outline-2 ((,colorful (:inherit nil :foreground ,.yellow ,@(when starlit-scale-outline-headlines '(:height 1.2))))))
       `(outline-3 ((,colorful (:inherit nil :foreground ,.purple ,@(when starlit-scale-outline-headlines '(:height 1.1))))))
       `(outline-4 ((,colorful (:inherit nil :foreground ,.aqua))))
       `(outline-5 ((,colorful (:inherit nil :foreground ,.orange))))
       `(outline-6 ((,colorful (:inherit nil :foreground ,.greenlight))))
       `(outline-7 ((,colorful (:inherit nil :foreground ,.type))))
       `(outline-8 ((,colorful (:inherit nil :foreground ,.bluehighlight))))
       `(outline-9 ((,colorful (:inherit nil :foreground ,.blue))))
       `(powerline-active1 ((,colorful (:foreground ,.foreground :background ,.selection))))
       `(powerline-active2 ((,colorful (:foreground ,.foreground :background ,.current-line))))
       `(py-builtins-face ((,colorful (:foreground ,.orange :weight normal))))
       `(rainbow-delimiters-depth-1-face ((,colorful (:foreground ,.foreground))))
       `(rainbow-delimiters-depth-2-face ((,colorful (:foreground ,.aqua))))
       `(rainbow-delimiters-depth-3-face ((,colorful (:foreground ,.yellow))))
       `(rainbow-delimiters-depth-4-face ((,colorful (:foreground ,.green))))
       `(rainbow-delimiters-depth-5-face ((,colorful (:foreground ,.blue))))
       `(rainbow-delimiters-depth-6-face ((,colorful (:foreground ,.foreground))))
       `(rainbow-delimiters-depth-7-face ((,colorful (:foreground ,.aqua))))
       `(rainbow-delimiters-depth-8-face ((,colorful (:foreground ,.yellow))))
       `(rainbow-delimiters-depth-9-face ((,colorful (:foreground ,.green))))
       `(rainbow-delimiters-unmatched-face ((,colorful (:foreground ,.red))))
       `(regex-tool-matched-face ((,colorful (:foreground nil :background nil :inherit match))))
       `(sh-heredoc ((,colorful (:foreground nil :inherit font-lock-string-face :weight normal))))
       `(sh-quoted-exec ((,colorful (:foreground nil :inherit font-lock-preprocessor-face))))
       `(show-paren-match-face ((,colorful (:background ,.bluehighlight :foreground ,.white))))
       `(show-paren-mismatch-face ((,colorful (:background ,.redhighlight :foreground ,.white))))
       `(slime-highlight-edits-face ((,colorful (:weight bold))))
       `(slime-repl-input-face ((,colorful (:weight normal :underline nil))))
       `(slime-repl-output-face ((,colorful (:foreground ,.blue :background ,.background))))
       `(slime-repl-prompt-face ((,colorful (:underline nil :weight bold :foreground ,.purple))))
       `(slime-repl-result-face ((,colorful (:foreground ,.green))))
       `(sp-show-pair-match-face ((,colorful (:foreground nil :background nil :inherit show-paren-match))))
       `(sp-show-pair-mismatch-face ((,colorful (:foreground nil :background nil :inherit show-paren-mismatch))))
       `(term ((,colorful (:foreground nil :background nil :inherit default))))
       `(term-color-black   ((,colorful (:foreground ,.foreground :background ,.foreground))))
       `(term-color-blue    ((,colorful (:foreground ,.blue :background ,.blue))))
       `(term-color-cyan    ((,colorful (:foreground ,.aqua :background ,.aqua))))
       `(term-color-green   ((,colorful (:foreground ,.green :background ,.green))))
       `(term-color-magenta ((,colorful (:foreground ,.purple :background ,.purple))))
       `(term-color-red     ((,colorful (:foreground ,.red :background ,.red))))
       `(term-color-white   ((,colorful (:foreground ,.background :background ,.background))))
       `(term-color-yellow  ((,colorful (:foreground ,.yellow :background ,.yellow))))
       `(trailing-whitespace ((,colorful (:foreground ,.red :inverse-video t :underline nil))))
       `(undo-tree-visualizer-active-branch-face ((,colorful (:foreground ,.red))))
       `(undo-tree-visualizer-current-face ((,colorful (:foreground ,.green :weight bold))))
       `(undo-tree-visualizer-default-face ((,colorful (:foreground ,.foreground))))
       `(undo-tree-visualizer-register-face ((,colorful (:foreground ,.yellow))))
       `(which-func ((,colorful (:foreground ,.blue :background nil))))
       `(whitespace-empty ((,colorful (:foreground ,.red :inverse-video t :underline nil))))
       `(whitespace-hspace ((,colorful (:background nil :foreground ,.selection))))
       `(whitespace-indentation ((,colorful (:background nil :foreground ,.aqua))))
       `(whitespace-line ((,colorful (:background nil :foreground ,.red))))
       `(whitespace-newline ((,colorful (:background nil :foreground ,.selection))))
       `(whitespace-space ((,colorful (:background nil :foreground ,.selection))))
       `(whitespace-space-after-tab ((,colorful (:background nil :foreground ,.background :underline nil))))
       `(whitespace-space-before-tab ((,colorful (:foreground ,.red :inverse-video t :underline nil))))
       `(whitespace-tab ((,colorful (:background nil :foreground ,.bluedark :background ,.backgroundlight))))
       `(whitespace-trailing ((,colorful (:foreground ,.red :inverse-video t :underline nil))))
       `(widget-button ((,colorful (:underline t))))
       `(widget-field ((,colorful (:background ,.current-line :box (:line-width 1 :color ,.foreground))))))

    (custom-theme-set-variables
     'starlit
     `(vc-annotate-color-map
       '((20  . ,.red)
         (40  . ,.orange)
         (60  . ,.yellow)
         (80  . ,.green)
         (100 . ,.aqua)
         (120 . ,.blue)
         (140 . ,.purple)
         (160 . ,.red)
         (180 . ,.orange)
         (200 . ,.yellow)
         (220 . ,.green)
         (240 . ,.aqua)
         (260 . ,.blue)
         (280 . ,.purple)
         (300 . ,.red)
         (320 . ,.orange)
         (340 . ,.yellow)
         (360 . ,.green)))
     `(ansi-color-names-vector (vector ,.foreground ,.red ,.green ,.yellow ,.blue ,.purple ,.aqua ,.background))
     '(ansi-color-faces-vector [default bold shadow italic underline bold bold-italic bold])))))


;;;###autoload
(when (and (boundp 'custom-theme-load-path)
           load-file-name)
  ;; when installing over MELPA, add theme to  `custom-theme-load-path'
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))


;; create theme settings
(starlit-theme-setup)

(provide-theme 'starlit)


;; Local Variables:
;; indent-tabs-mode: nil
;; rainbow-mode: t
;; End:

;;; starlit-theme.el ends here
