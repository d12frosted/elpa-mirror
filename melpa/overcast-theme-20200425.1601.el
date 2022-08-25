;;; overcast-theme.el --- A dark but vibrant color theme for Emacs

;; This file is not part of Emacs

;; Author: Mohammed Ismail Ansari <team.terminal@gmail.com>
;; Version: 1.3
;; Package-Version: 20200425.1601
;; Package-Commit: e02b835a08919ead079d7221d513348ac02ba92e
;; Keywords: theme
;; Maintainer: Mohammed Ismail Ansari <team.terminal@gmail.com>
;; Created: 2018/02/15
;; Package-Requires: ((emacs "24"))
;; Description: A dark but vibrant color theme
;; URL: http://ismail.teamfluxion.com
;; Compatibility: Emacs24
;; Inspired by a template from https://github.com/mswift42/themecreator.

;; COPYRIGHT NOTICE
;;
;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
;; for more details.
;;

;;; Install:

;; Put this file on your Emacs-Lisp load path and add the following to your
;; ~/.emacs startup file
;;
;;     (require 'overcast-theme)
;;
;; Enable the theme with
;;
;;     (load-theme 'overcast)
;;

;;; Commentary:

;;     A dark but vibrant color theme.
;;
;;  Overview of features:
;;
;;     o   Dark, vibrant
;;

;;; Code:

(deftheme overcast)
(let ((class '((class color) (min-colors 89)))

      (color-primary "#d9ffff")
      (color-level1 "#c8ebeb")
      (color-level2 "#b6d6d6")
      (color-level3 "#a5c2c2")

      (bgcolor-primary "#001c1c")
      (bgcolor-level1 "#142e2e")
      (bgcolor-level2 "#294040")
      (bgcolor-level3 "#3d5252")

      (color-black "black")
      (color-white "white")
      (color-violet "violet")
      (color-purple "purple")
      (color-blue "steel blue")
      (color-green "green")
      (color-yellow "yellow")
      (color-orange "orange")
      (color-red "red")
      (color-cyan "cyan")
      (color-magenta "magenta")

      (color-cursor "white")

      (color-builtin "#9dff9d")
      (color-keyword "#c7c7c7")
      (color-const   "#ffffb0")
      (color-comment "#005353")
      (color-func    "#9dff9d")
      (color-str     "#ffbc79")
      (color-type    "#e4a6ff")
      (color-var     "#00eaea")

      (color-success "green")
      (color-info "yellow")
      (color-warning "#ff8000")
      (color-error "#ff0000"))
  (custom-theme-set-faces
   'overcast

   ;; Default
   `(default ((,class (:background ,bgcolor-primary :foreground ,color-primary))))
   `(font-lock-builtin-face ((,class (:foreground ,color-builtin))))
   `(font-lock-comment-face ((,class (:foreground ,color-comment))))
   `(font-lock-negation-char-face ((,class (:foreground ,color-const))))
   `(font-lock-reference-face ((,class (:foreground ,color-const))))
   `(font-lock-constant-face ((,class (:foreground ,color-const))))
   `(font-lock-doc-face ((,class (:foreground ,color-comment))))
   `(font-lock-function-name-face ((,class (:foreground ,color-func ))))
   `(font-lock-keyword-face ((,class (:bold t :foreground ,color-keyword))))
   `(font-lock-string-face ((,class (:foreground ,color-str))))
   `(font-lock-type-face ((,class (:foreground ,color-type ))))
   `(font-lock-variable-name-face ((,class (:foreground ,color-var))))
   `(font-lock-warning-face ((,class (:foreground ,color-warning :background ,bgcolor-level1))))

   ;; Misc
   `(cursor ((,class (:background ,color-cursor))))
   `(region ((,class (:background ,color-primary :foreground ,bgcolor-primary))))
   `(highlight ((,class (:foreground ,color-level2 :background ,bgcolor-level2))))
   `(hl-line ((,class (:background  ,bgcolor-level1))))
   `(fringe ((,class (:background ,bgcolor-level1 :foreground ,bgcolor-level3))))
   `(vertical-border ((,class (:foreground ,bgcolor-primary))))
   `(line-number ((,class (:background ,bgcolor-primary :foreground ,bgcolor-level3 :height 0.8))))
   `(line-number-current-line ((,class (:background ,bgcolor-level1 :foreground ,color-level3 :height 0.8))))
   `(linum ((,class (:foreground ,bgcolor-level3))))
   `(show-paren-match-face ((,class (:background ,color-level3 :foreground ,color-white))))
   `(isearch ((,class (:bold t :foreground ,bgcolor-primary :background ,color-warning))))
   `(minibuffer-prompt ((,class (:bold t :background ,bgcolor-level3 :foreground ,color-primary))))
   `(default-italic ((,class (:italic t))))
   `(link ((,class (:foreground ,color-const :underline t))))
   `(warning ((,class (:foreground ,color-warning))))
   `(trailing-whitespace ((,class :foreground nil :background ,color-warning)))

   ;; Modeline
   `(mode-line ((,class (:box (:line-width 1 :color ,color-primary) :foreground ,color-primary :background ,bgcolor-level3))))
   `(mode-line-inactive ((,class (:box (:line-width 1 :color ,bgcolor-level3) :foreground ,color-level3 :background ,bgcolor-primary))))
   `(mode-line-buffer-id ((,class (:bold t :foreground ,color-func :background nil))))
   `(mode-line-highlight ((,class (:foreground ,color-keyword :box nil :weight bold))))
   `(mode-line-emphasis ((,class (:foreground ,color-primary))))

   ;; Ido
   `(ido-only-match ((,class (:foreground ,color-warning))))
   `(ido-first-match ((,class (:foreground ,color-keyword :bold t))))

   ;; Org
   `(org-code ((,class (:foreground ,color-level1))))
   `(org-hide ((,class (:foreground ,color-level3))))
   `(org-level-1 ((,class (:bold nil :foreground ,color-primary :height 1.1))))
   `(org-level-2 ((,class (:bold nil :foreground ,color-level1))))
   `(org-level-3 ((,class (:bold nil :foreground ,color-level2))))
   `(org-level-4 ((,class (:bold nil :foreground ,color-level3))))
   `(org-date ((,class (:underline t :foreground ,color-var) )))
   `(org-footnote  ((,class (:underline t :foreground ,color-level3))))
   `(org-link ((,class (:underline t :foreground ,color-type ))))
   `(org-special-keyword ((,class (:foreground ,color-func))))
   `(org-block ((,class (:foreground ,color-level2))))
   `(org-quote ((,class (:inherit org-block :slant italic))))
   `(org-verse ((,class (:inherit org-block :slant italic))))
   `(org-todo ((,class (:box (:line-width 1 :color ,color-error) :foreground ,color-error :bold t))))
   `(org-done ((,class (:box (:line-width 1 :color ,color-success) :foreground ,color-success :bold t))))
   `(org-warning ((,class (:underline t :foreground ,color-warning))))
   `(org-agenda-structure ((,class (:weight bold :foreground ,color-level2 :box (:color ,color-level3) :background ,bgcolor-level2))))
   `(org-agenda-date ((,class (:foreground ,color-var :height 1.1 ))))
   `(org-agenda-date-weekend ((,class (:weight normal :foreground ,color-level3))))
   `(org-agenda-date-today ((,class (:weight bold :foreground ,color-keyword :height 1.4))))
   `(org-agenda-done ((,class (:foreground ,bgcolor-level3))))
   `(org-scheduled ((,class (:foreground ,color-type))))
   `(org-scheduled-today ((,class (:foreground ,color-func :weight bold :height 1.2))))
   `(org-ellipsis ((,class (:foreground ,color-builtin))))
   `(org-verbatim ((,class (:foreground ,color-level3))))
   `(org-document-info-keyword ((,class (:foreground ,color-func))))
   `(org-sexp-date ((,class (:foreground ,color-level3))))

   ;; Anzu
   `(anzu-mode-line ((,class (:foreground ,color-warning :bold t))))

   ;; autocomplete
   `(ac-candidate-face ((,class :foreground ,color-level2 :background ,bgcolor-level2)))
   `(ac-completion-face ((,class :foreground ,bgcolor-level3)))
   `(ac-selection-face ((,class :foreground ,bgcolor-level2 :background ,color-level2)))
   `(popup-tip-face ((,class :foreground ,color-black :background ,color-const)))
   `(popup-scroll-bar-foreground-face ((,class :background ,bgcolor-level3)))
   `(popup-scroll-bar-background-face ((,class :background ,bgcolor-level1)))
   `(popup-isearch-match ((,class :foreground ,color-warning :background ,color-white)))

   ;; Company
   `(company-echo-common ((,class (:foreground ,bgcolor-primary :background ,color-primary))))
   `(company-preview ((,class (:background ,bgcolor-primary :foreground ,color-var))))
   `(company-preview-common ((,class (:foreground ,bgcolor-level1 :foreground ,color-level2))))
   `(company-preview-search ((,class (:foreground ,color-type :background ,bgcolor-primary))))
   `(company-scrollbar-bg ((,class (:background ,bgcolor-level2))))
   `(company-scrollbar-fg ((,class (:foreground ,color-keyword))))
   `(company-tooltip ((,class (:foreground ,color-level1 :background ,bgcolor-primary :bold t))))
   `(company-tooltop-annotation ((,class (:foreground ,color-const))))
   `(company-tooltip-common ((,class ( :foreground ,color-level2))))
   `(company-tooltip-common-selection ((,class (:foreground ,color-str))))
   `(company-tooltip-mouse ((,class (:inherit highlight))))
   `(company-tooltip-selection ((,class (:background ,bgcolor-level2 :foreground ,color-level2))))
   `(company-template-field ((,class (:inherit region))))

   ;; ace-jump
   `(ace-jump-face-background ((,class :foreground ,bgcolor-level2 nil)))
   `(ace-jump-face-foreground ((,class :foreground ,bgcolor-primary :background ,color-warning)))

   ;; ace-window
   `(aw-background-face ((,class :foreground ,bgcolor-level2)))
   `(aw-leading-char-face ((,class :foreground ,color-warning :height 200 :weight bold)))

   ;; Undo tree
   `(undo-tree-visualizer-current-face ((,class :foreground ,color-warning)))
   `(undo-tree-visualizer-default-face ((,class :foreground ,color-comment)))
   `(undo-tree-visualizer-unmodified-face ((,class :foreground ,color-var)))
   `(undo-tree-visualizer-register-face ((,class :foreground ,color-type)))

   ;; Rainbow delimiters
   `(rainbow-delimiters-depth-1-face ((,class :foreground ,color-violet)))
   `(rainbow-delimiters-depth-2-face ((,class :foreground ,color-purple)))
   `(rainbow-delimiters-depth-3-face ((,class :foreground ,color-blue)))
   `(rainbow-delimiters-depth-4-face ((,class :foreground ,color-green)))
   `(rainbow-delimiters-depth-5-face ((,class :foreground ,color-yellow)))
   `(rainbow-delimiters-depth-6-face ((,class :foreground ,color-orange)))
   `(rainbow-delimiters-depth-7-face ((,class :foreground ,color-red)))
   `(rainbow-delimiters-depth-8-face ((,class :foreground ,color-white)))
   `(rainbow-delimiters-unmatched-face ((,class :foreground ,color-warning)))

   ;; Magit
   `(magit-item-highlight ((,class :background ,bgcolor-level2)))
   `(magit-section-heading        ((,class (:foreground ,color-keyword :weight bold))))
   `(magit-hunk-heading           ((,class (:background ,bgcolor-level2))))
   `(magit-section-highlight      ((,class (:background ,bgcolor-level1))))
   `(magit-hunk-heading-highlight ((,class (:background ,bgcolor-level2))))
   `(magit-diff-context-highlight ((,class (:background ,bgcolor-level2 :foreground ,color-level2))))
   `(magit-diffstat-added   ((,class (:foreground ,color-green))))
   `(magit-diffstat-removed ((,class (:foreground ,color-red))))
   `(magit-process-ok ((,class (:foreground ,color-func :weight bold))))
   `(magit-process-ng ((,class (:foreground ,color-warning :weight bold))))
   `(magit-branch ((,class (:foreground ,color-const :weight bold))))
   `(magit-log-author ((,class (:foreground ,color-level2))))
   `(magit-hash ((,class (:foreground ,color-level1))))
   `(magit-diff-file-header ((,class (:foreground ,color-level1 :background ,bgcolor-level2))))

   ;; Helm
   `(helm-header ((,class (:foreground ,color-level1 :background ,bgcolor-primary :underline nil :box nil))))
   `(helm-source-header ((,class (:foreground ,color-keyword :background ,bgcolor-primary :underline nil :weight bold))))
   `(helm-selection ((,class (:background ,bgcolor-level1 :underline nil))))
   `(helm-selection-line ((,class (:background ,bgcolor-level1))))
   `(helm-visible-mark ((,class (:foreground ,bgcolor-primary :background ,bgcolor-level2))))
   `(helm-candidate-number ((,class (:foreground ,bgcolor-primary :background ,color-primary))))
   `(helm-separator ((,class (:foreground ,color-type :background ,bgcolor-primary))))
   `(helm-time-zone-current ((,class (:foreground ,color-builtin :background ,bgcolor-primary))))
   `(helm-time-zone-home ((,class (:foreground ,color-type :background ,bgcolor-primary))))
   `(helm-buffer-not-saved ((,class (:foreground ,color-type :background ,bgcolor-primary))))
   `(helm-buffer-process ((,class (:foreground ,color-builtin :background ,bgcolor-primary))))
   `(helm-buffer-saved-out ((,class (:foreground ,color-primary :background ,bgcolor-primary))))
   `(helm-buffer-size ((,class (:foreground ,color-primary :background ,bgcolor-primary))))
   `(helm-ff-directory ((,class (:foreground ,color-func :background ,bgcolor-primary :weight bold))))
   `(helm-ff-file ((,class (:foreground ,color-primary :background ,bgcolor-primary :weight normal))))
   `(helm-ff-executable ((,class (:foreground ,color-var :background ,bgcolor-primary :weight normal))))
   `(helm-ff-invalid-symlink ((,class (:foreground ,color-warning :background ,bgcolor-primary :weight bold))))
   `(helm-ff-symlink ((,class (:foreground ,color-keyword :background ,bgcolor-primary :weight bold))))
   `(helm-ff-prefix ((,class (:foreground ,bgcolor-primary :background ,color-keyword :weight normal))))
   `(helm-grep-cmd-line ((,class (:foreground ,color-primary :background ,bgcolor-primary))))
   `(helm-grep-file ((,class (:foreground ,color-primary :background ,bgcolor-primary))))
   `(helm-grep-finish ((,class (:foreground ,color-level1 :background ,bgcolor-primary))))
   `(helm-grep-lineno ((,class (:foreground ,color-primary :background ,bgcolor-primary))))
   `(helm-grep-match ((,class (:foreground nil :background nil :inherit helm-match))))
   `(helm-grep-running ((,class (:foreground ,color-func :background ,bgcolor-primary))))
   `(helm-moccur-buffer ((,class (:foreground ,color-func :background ,bgcolor-primary))))
   `(helm-source-go-package-godoc-description ((,class (:foreground ,color-str))))
   `(helm-bookmark-w3m ((,class (:foreground ,color-type))))

   ;; Web-mode
   `(web-mode-builtin-face ((,class (:inherit ,font-lock-builtin-face))))
   `(web-mode-comment-face ((,class (:inherit ,font-lock-comment-face))))
   `(web-mode-constant-face ((,class (:inherit ,font-lock-constant-face))))
   `(web-mode-keyword-face ((,class (:foreground ,color-keyword))))
   `(web-mode-doctype-face ((,class (:inherit ,font-lock-comment-face))))
   `(web-mode-function-name-face ((,class (:inherit ,font-lock-function-name-face))))
   `(web-mode-string-face ((,class (:foreground ,color-str))))
   `(web-mode-type-face ((,class (:inherit ,font-lock-type-face))))
   `(web-mode-html-attr-name-face ((,class (:foreground ,color-func))))
   `(web-mode-html-attr-value-face ((,class (:foreground ,color-keyword))))
   `(web-mode-warning-face ((,class (:inherit ,font-lock-warning-face))))
   `(web-mode-html-tag-face ((,class (:foreground ,color-type))))

   ;; js2
   `(js2-private-function-call ((,class (:foreground ,color-const))))
   `(js2-jsdoc-html-tag-delimiter ((,class (:foreground ,color-str))))
   `(js2-jsdoc-html-tag-name ((,class (:foreground ,color-var))))
   `(js2-external-variable ((,class (:foreground ,color-type  ))))
   `(js2-function-param ((,class (:foreground ,color-const))))
   `(js2-jsdoc-value ((,class (:foreground ,color-str))))
   `(js2-private-member ((,class (:foreground ,color-level2))))

   ;; js3
   `(js3-warning-face ((,class (:underline ,color-keyword))))
   `(js3-error-face ((,class (:underline ,color-warning))))
   `(js3-external-variable-face ((,class (:foreground ,color-var))))
   `(js3-function-param-face ((,class (:foreground ,color-level1))))
   `(js3-jsdoc-tag-face ((,class (:foreground ,color-keyword))))
   `(js3-instance-member-face ((,class (:foreground ,color-const))))

   ;; jde
   `(jde-java-font-lock-package-face ((t (:foreground ,color-var))))
   `(jde-java-font-lock-public-face ((t (:foreground ,color-keyword))))
   `(jde-java-font-lock-private-face ((t (:foreground ,color-keyword))))
   `(jde-java-font-lock-constant-face ((t (:foreground ,color-const))))
   `(jde-java-font-lock-modifier-face ((t (:foreground ,color-level1))))
   `(jde-jave-font-lock-protected-face ((t (:foreground ,color-keyword))))
   `(jde-java-font-lock-number-face ((t (:foreground ,color-var))))

   ;; telephone-line
   `(telephone-line-accent-active ((t (:foreground ,bgcolor-primary :background ,color-level3))))
   `(telephone-line-accent-inactive ((t (:foreground ,color-primary :background ,bgcolor-level2))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path)
           load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'overcast)

;; Local Variables:
;; no-byte-compile: t
;; eval: (when (fboundp 'rainbow-mode) (rainbow-mode 1))
;; End:

;;; overcast-theme.el ends here
