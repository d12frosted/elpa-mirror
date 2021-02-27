;;; brutal-theme.el --- Brutalist theme -*- lexical-binding: t; -*-

;; Copyright (C) 2021, Topi Kettunen <topi@kettunen.io>

;; Author: Topi Kettunen <topi@kettunen.io>
;; URL: https://github.com/topikettunen/brutal-emacs
;; Package-Version: 20210226.1538
;; Package-Commit: 8173b7d041cccfa3e5bb3f3f85ec8c6109fd264b
;; Version: 0.1
;; Package-Requires: ((emacs "24.1"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of Emacs.

;;; Commentary:

;; Brutalist theme for Emacs for all your minimalistic needs.

(deftheme brutal)

(let ((class '((class color) (min-colors 89)))
       (fg1 "#444444")
       (fg2 "#535353")
       (fg3 "#626262")
       (fg4 "#717171")
       (bg1 "#ffffef")
       (bg2 "#ebebdc")
       (bg3 "#d6d6c9")
       (comment "#969696"))
  
  (custom-theme-set-faces
   
   'brutal

   ;; Crucial faces
   ;;
   ;; Exceptions
   ;;   - For region, default face is good enough.
   
   `(default ((,class (:background ,bg1 :foreground ,fg1))))
   `(highlight ((,class (:foreground ,fg3 :background ,bg3))))
   `(hl-line ((,class (:background  ,bg2))))
   `(fringe ((,class (:background ,bg2 :foreground ,fg4))))
   `(cursor ((,class (:background ,fg1))))
   `(isearch ((,class (:bold t :foreground ,bg1 :background ,fg1))))
   `(mode-line ((,class (:bold t :foreground ,bg1 :background ,fg1))))
   `(mode-line-inactive ((,class (:foreground ,fg4 :background ,bg2 :weight normal))))
   `(font-lock-comment-face ((,class (:foreground ,comment))))
   `(org-link ((,class (:underline '(:color ,fg1)))))

   ;; Disabled faces

   `(show-paren-match-face ((t nil)))
   `(mode-line-buffer-id ((t nil)))
   `(mode-line-highlight ((t nil)))
   `(mode-line-emphasis ((t nil)))
   
   `(vertical-border ((t nil)))
   `(minibuffer-prompt ((t nil)))
   `(default-italic ((t nil)))
   `(link ((t nil)))

   `(font-lock-builtin-face ((t nil)))
   `(font-lock-negation-char-face ((t nil)))
   `(font-lock-reference-face ((t nil)))
   `(font-lock-constant-face ((t nil)))
   `(font-lock-doc-face ((t nil)))
   `(font-lock-function-name-face ((t nil)))
   `(font-lock-keyword-face ((t nil)))
   `(font-lock-string-face ((t nil)))
   `(font-lock-type-face ((t nil)))
   `(font-lock-variable-name-face ((t nil)))
   `(font-lock-warning-face ((t nil)))
   
   `(sh-quoted-exec ((t nil)))
   `(eshell-prompt ((t nil)))
   
   `(org-code ((t nil)))
   `(org-hide ((t nil)))
   `(org-level-1 ((t nil)))
   `(org-level-2 ((t nil)))
   `(org-level-3 ((t nil)))
   `(org-level-4 ((t nil)))
   `(org-date ((t nil)))
   `(org-footnote  ((t nil)))
   `(org-special-keyword ((t nil)))
   `(org-block ((t nil)))
   `(org-quote ((t nil)))
   `(org-verse ((t nil)))
   `(org-todo ((t nil)))
   `(org-done ((t nil)))
   `(org-warning ((t nil)))
   `(org-agenda-structure ((t nil)))
   `(org-agenda-date ((t nil)))
   `(org-agenda-date-weekend ((t nil)))
   `(org-agenda-date-today ((t nil)))
   `(org-agenda-done ((t nil)))
   `(org-scheduled ((t nil)))
   `(org-scheduled-today ((t nil)))
   `(org-ellipsis ((t nil)))
   `(org-verbatim ((t nil)))
   `(org-document-title ((t nil)))
   `(org-document-info ((t nil)))
   `(org-document-info-keyword ((t nil)))
   `(org-sexp-date ((t nil)))
   
   `(font-latex-bold-face ((t nil)))
   `(font-latex-italic-face ((t nil)))
   `(font-latex-string-face ((t nil)))
   `(font-latex-match-reference-keywords ((t nil)))
   `(font-latex-match-variable-keywords ((t nil)))
   
   `(ido-only-match ((t nil)))
   `(ido-first-match ((t nil)))
   
   `(gnus-header-content ((t nil)))
   `(gnus-header-from ((t nil)))
   `(gnus-header-name ((t nil)))
   `(gnus-header-subject ((t nil)))
   
   `(mu4e-view-url-number-face ((t nil)))
   `(mu4e-cited-1-face ((t nil)))
   `(mu4e-cited-7-face ((t nil)))
   `(mu4e-header-marks-face ((t nil)))
   
   `(ffap ((t nil)))
   
   `(js2-private-function-call ((t nil)))
   `(js2-jsdoc-html-tag-delimiter ((t nil)))
   `(js2-jsdoc-html-tag-name ((t nil)))
   `(js2-external-variable ((t nil)))
   `(js2-function-param ((t nil)))
   `(js2-jsdoc-value ((t nil)))
   `(js2-private-member ((t nil)))
   
   `(js3-warning-face ((t nil)))
   `(js3-error-face ((t nil)))
   `(js3-external-variable-face ((t nil)))
   `(js3-function-param-face ((t nil)))
   `(js3-jsdoc-tag-face ((t nil)))
   `(js3-instance-member-face ((t nil)))
   
   `(warning ((t nil)))
   
   `(ac-completion-face ((t nil)))
   
   `(info-quoted-name ((t nil)))
   `(info-string ((t nil)))
   
   `(icompletep-determined ((t nil)))
   
   `(undo-tree-visualizer-current-face ((t nil)))
   `(undo-tree-visualizer-default-face ((t nil)))
   `(undo-tree-visualizer-unmodified-face ((t nil)))
   `(undo-tree-visualizer-register-face ((t nil)))
   
   `(slime-repl-inputed-output-face ((t nil)))
   
   `(trailing-whitespace ((t nil)))
   
   `(rainbow-delimiters-depth-1-face ((t nil)))
   `(rainbow-delimiters-depth-2-face ((t nil)))
   `(rainbow-delimiters-depth-3-face ((t nil)))
   `(rainbow-delimiters-depth-4-face ((t nil)))
   `(rainbow-delimiters-depth-5-face ((t nil)))
   `(rainbow-delimiters-depth-6-face ((t nil)))
   `(rainbow-delimiters-depth-7-face ((t nil)))
   `(rainbow-delimiters-depth-8-face ((t nil)))
   `(rainbow-delimiters-unmatched-face ((t nil)))
   
   `(magit-item-highlight ((t nil)))
   `(magit-section-heading        ((t nil)))
   `(magit-hunk-heading           ((t nil)))
   `(magit-section-highlight      ((t nil)))
   `(magit-hunk-heading-highlight ((t nil)))
   `(magit-diff-context-highlight ((t nil)))
   `(magit-diffstat-added   ((t nil)))
   `(magit-diffstat-removed ((t nil)))
   `(magit-process-ok ((t nil)))
   `(magit-process-ng ((t nil)))
   `(magit-branch ((t nil)))
   `(magit-log-author ((t nil)))
   `(magit-hash ((t nil)))
   `(magit-diff-file-header ((t nil)))
   
   `(lazy-highlight ((t nil)))
   
   `(term ((t nil)))
   `(term-color-black ((t nil)))
   `(term-color-blue ((t nil)))
   `(term-color-red ((t nil)))
   `(term-color-green ((t nil)))
   `(term-color-yellow ((t nil)))
   `(term-color-magenta ((t nil)))
   `(term-color-cyan ((t nil)))
   `(term-color-white ((t nil)))
   
   `(helm-header ((t nil)))
   `(helm-source-header ((t nil)))
   `(helm-selection ((t nil)))
   `(helm-selection-line ((t nil)))
   `(helm-visible-mark ((t nil)))
   `(helm-candidate-number ((t nil)))
   `(helm-separator ((t nil)))
   `(helm-time-zone-current ((t nil)))
   `(helm-time-zone-home ((t nil)))
   `(helm-buffer-not-saved ((t nil)))
   `(helm-buffer-process ((t nil)))
   `(helm-buffer-saved-out ((t nil)))
   `(helm-buffer-size ((t nil)))
   `(helm-ff-directory ((t nil)))
   `(helm-ff-file ((t nil)))
   `(helm-ff-executable ((t nil)))
   `(helm-ff-invalid-symlink ((t nil)))
   `(helm-ff-symlink ((t nil)))
   `(helm-ff-prefix ((t nil)))
   `(helm-grep-cmd-line ((t nil)))
   `(helm-grep-file ((t nil)))
   `(helm-grep-finish ((t nil)))
   `(helm-grep-lineno ((t nil)))
   `(helm-grep-match ((t nil)))
   `(helm-grep-running ((t nil)))
   `(helm-moccur-buffer ((t nil)))
   `(helm-source-go-package-godoc-description ((t nil)))
   `(helm-bookmark-w3m ((t nil)))
   
   `(company-echo-common ((t nil)))
   `(company-preview ((t nil)))
   `(company-preview-common ((t nil)))
   `(company-preview-search ((t nil)))
   `(company-scrollbar-bg ((t nil)))
   `(company-scrollbar-fg ((t nil)))
   `(company-tooltip ((t nil)))
   `(company-tooltop-annotation ((t nil)))
   `(company-tooltip-common ((t nil)))
   `(company-tooltip-common-selection ((t nil)))
   `(company-tooltip-mouse ((t nil)))
   `(company-tooltip-selection ((t nil)))
   `(company-template-field ((t nil)))
   `(web-mode-builtin-face ((t nil)))
   
   `(web-mode-comment-face ((t nil)))
   `(web-mode-constant-face ((t nil)))
   `(web-mode-keyword-face ((t nil)))
   `(web-mode-doctype-face ((t nil)))
   `(web-mode-function-name-face ((t nil)))
   `(web-mode-string-face ((t nil)))
   `(web-mode-type-face ((t nil)))
   `(web-mode-html-attr-name-face ((t nil)))
   `(web-mode-html-attr-value-face ((t nil)))
   `(web-mode-warning-face ((t nil)))
   `(web-mode-html-tag-face ((t nil)))
   
   `(jde-java-font-lock-package-face ((t nil)))
   `(jde-java-font-lock-public-face ((t nil)))
   `(jde-java-font-lock-private-face ((t nil)))
   `(jde-java-font-lock-constant-face ((t nil)))
   `(jde-java-font-lock-modifier-face ((t nil)))
   `(jde-jave-font-lock-protected-face ((t nil)))
   `(jde-java-font-lock-number-face ((t nil)))
   
   '(terraform--resource-name-face ((t nil)))
   '(terraform--resource-type-face ((t nil)))))

(provide-theme 'brutal)

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide 'brutal-theme)

;;; brutal-theme.el ends here
