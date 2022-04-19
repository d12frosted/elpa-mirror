;;; laguna-theme.el --- An updated blue-green Laguna Theme.
;;
;; Filename: laguna-theme.el
;; Description: An updated blue-green Laguna Theme.
;; Author: Henry Newcomer <a.cliche.email@gmail.com>
;; Version: 2.0
;; Package-Version: 20220419.1459
;; Package-Commit: 48d14ffad6f0ffb4bd60c341e618c47ddbb7a2d8
;; URL: https://github.com/HenryNewcomer/laguna-theme
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;  Framework based on the initial code found within "Ample Theme"
;;  by Jordon Biondo.
;;  URL: https://github.com/jordonbiondo/ample-theme
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:
(deftheme laguna "An updated blue-green Laguna Theme.")

;; Color palette
(let (
  ;; Main background and foreground colors
  (color-bg "#191f2b")
  (color-bg-2 "#141922") ;; Some random areas may want to be slightly offset from the background color
  (color-fg "#3b78d3") ;; Regular text color; ex. ::getchar in std::getchar()
  (color-fg-alt "#a9e3ad") ;; NOTE Not actually used at the moment.
  (color-fringe "#0c0e14") ;; Outside border of window and splits
  (color-main "#a2efb4") ;; ex. main function
  (color-error "#e34e3e")
  (color-warning "#e34e3e")
  (color-keyword "#469281") ;; ex. return,  let
  (color-search-bg "#3298c3") ;; ex. Highlighted search text
  (color-search-fg "#000") ;; ex. Highlighted search text
  (color-built-in "#e8f6e6") ;; ex. :foreground, :background, :weight, etc.
  (color-preprocessor "#423f68") ;; #include
  (color-quotes "#128157")
  (color-elisp-func-desc "#65a9e3")
  (color-param-names "#83a598")
  (color-minibuffer-prompt "#94d68c")
  (color-consquotest "#36585c") ;; ex. std in std::getchar
  (color-comment-symbols "#647769")
  (color-comment-text "#82aabf")
  (color-mode-line-bg "#0c0f15")
  (color-mode-line-fg "#7694b0")
  (color-vertical-line "#141923")
  (color-types "#7cb8e7") ;; Function type, param type, etc. (ex. int, char, ...)
  (color-cursor-bg "#f19e64")
  (color-cursor-bg-alt "#7cb8e7")
  (color-constant "#20905f")
  ;; (color-cursor-fg "#141922")
  (color-line-number-fg "#1e252f") ;; The font color for line numbers
  (color-current-line-text-area-bg "#141923")
  (color-current-line-side-bg "#1c3445")
  (color-current-line-side-fg "#b2c5d4")
  ;; Gradients (Parentheses, org heiarchy, etc.)
; (message (((((((message "Example."))))))))
  (color-gradient0 "#7fb486")
  (color-gradient1 "#53a451") ;; ex. () within std::getchar()
  (color-gradient2 "#43a4bd")
  (color-gradient3 "#674593")
  (color-gradient4 "#aa17ed")
  (color-gradient5 "#3b78d3")
  (color-paren-match-bg "#6b4841")
  (color-paren-match-fg "#f19e64")
  ;; Magit
  (color-add-fg "#335d39")
  (color-add-bg "#00f;")
  (color-remove-fg "#5e1c1c")
  (color-remove-bg "#a56969")
  (color-number "#834079") ;; FIXME "Highlight numbers" pkg overrides rainbow-mode functionality.
  (color-region-bg "#3d78b0")
  (color-region-fg "#141923")

  ;; Not yet configured...
  (color-link "#0f0")
  (color-undefined1 "#0f0")
  (color-undefined2 "#0f0")
  (color-undefined3 "#0f0"))

  ;; Set faces
  (custom-theme-set-faces
    `laguna ;; you must use the same theme name here...
    `(error ((t (:foreground ,color-error))))
    `(default ((t (:foreground ,color-fg :background ,color-bg))))
    `(cursor  ((t (:foreground ,color-fg :background ,color-cursor-bg))))
    `(face-spec-set column-enforce-face '((t (:foreground ,color-warning :bold t :underline t))))
    `(fringe  ((t (:background ,color-fringe))))
    `(highlight  ((t (:foreground ,color-region-fg :background ,color-region-bg))))
    `(highlight-numbers-number ((t (:foreground ,color-number :weight bold))))
    `(link    ((t (:foreground ,color-link :underline t))))
    `(region  ((t (:foreground ,color-region-fg :background ,color-region-bg))))

    ;; Standard font lock
    `(font-lock-builtin-face  ((t (:foreground ,color-built-in :weight bold))))
    `(font-lock-comment-face  ((t (:foreground ,color-comment-text))))
    `(font-lock-comment-delimiter-face ((t (:foreground ,color-comment-symbols))))
    `(font-lock-constant-face ((t (:foreground ,color-constant))))
    `(font-lock-function-name-face ((t (:foreground ,color-main))))
    `(font-lock-keyword-face  ((t (:foreground ,color-keyword))))
    `(font-lock-string-face  ((t (:foreground ,color-quotes :weight bold))))
    `(font-lock-preprocessor-face ((t (:foreground ,color-preprocessor))))
    `(font-lock-type-face  ((t (:foreground ,color-types :weight bold))))
    `(font-lock-consquotest-face  ((t (:foreground ,color-consquotest))))
    `(font-lock-warning-face  ((t (:foreground ,color-warning :weight bold))))
    `(font-lock-variable-name-face ((t (:foreground ,color-param-names))))
    `(font-lock-doc-face   ((t (:foreground ,color-elisp-func-desc))))

    ;; Mode line & powerline
    `(powerline-active1 ((t (:foreground ,color-vertical-line))))
    `(mode-line-inactive ((t (:background ,color-mode-line-bg :foreground ,color-mode-line-fg))))
    `(mode-line  ((t (:background ,color-mode-line-bg :foreground ,color-mode-line-fg))))

    `(linum ((t (:background nil :foreground ,color-comment-text))))

    `(popup-tip-face ((t (:background ,color-fg :foreground ,color-bg))))

    `(header-line ((t (:background ,color-fg :foreground ,color-bg))))

    `(button  ((t (:foreground ,color-link :background nil :underline t))))

    ;; search
    `(isearch  ((t (:background ,color-search-bg :foreground ,color-search-fg))))
    `(lazy-highlight ((t (:background ,color-search-bg :foreground ,color-search-fg :underline t))))

    ;; evil-search-highlight-persist
    `(evil-search-highlight-persist-highlight-face ((t (:background ,color-search-bg :foreground ,color-fg))))

    ;; ace-jump
    `(ace-jump-face-background ((t (:inherit font-lock-comment-face))))
    `(ace-jump-face-foreground ((t (:foreground ,color-preprocessor))))


    `(avy-background-face  ((t (:foreground ,color-comment-symbols :background nil))))
    `(avy-lead-face  ((t (:foreground "white" :background ,color-types))))
    `(avy-lead-face-0  ((t (:foreground "white" :background ,color-keyword))))
    `(avy-lead-face-1  ((t (:foreground "white" :background ,color-fg))))

    `(vertical-border ((t (:background ,color-mode-line-bg :foreground ,color-vertical-line))))

    `(hl-line ((t (:background ,color-current-line-text-area-bg))))

    `(highlight-indentation-face ((t (:background ,color-vertical-line))))

    `(line-number-current-line  ((t (:foreground ,color-current-line-side-fg
                                      :background ,color-current-line-side-bg
                                      :weight bold))))

    `(line-number ((t (:foreground ,color-line-number-fg :background nil))))

    ;; mini buff
    `(minibuffer-prompt ((t (:foreground ,color-minibuffer-prompt :weight bold :background nil))))


    `(compilation-error  ((t (:foreground ,color-types :weight bold))))
    `(compilation-warning ((t (:foreground ,color-preprocessor :weight bold))))
    `(compilation-info  ((t (:foreground ,color-main :weight bold))))

    ;; eshell
    `(eshell-prompt ((t (:foreground ,color-consquotest))))
    `(eshell-ls-directory ((t (:foreground ,color-keyword))))
    `(eshell-ls-product ((t (:foreground ,color-preprocessor))))
    `(eshell-ls-backup ((t (:foreground ,color-mode-line-fg :background ,color-mode-line-bg))))
    `(eshell-ls-executable ((t (:foreground ,color-main))))

    ;; shell
    `(comint-highlight-prompt ((t (:foreground ,color-main))))

    ;; term
    `(term-color-black ((t (:foreground ,color-vertical-line :background ,color-vertical-line))))
    `(term-color-red ((t (:foreground ,color-types :background ,color-types))))
    `(term-color-green ((t (:foreground ,color-main :background ,color-main))))
    `(term-color-yellow ((t (:foreground ,color-param-names :background ,color-param-names))))
    `(term-color-blue ((t (:foreground ,color-keyword :background ,color-keyword))))
    `(term-color-magenta ((t (:foreground ,color-consquotest :background ,color-consquotest))))
    `(term-color-cyan ((t (:foreground ,color-link :background ,color-link))))
    `(term-color-white ((t (:foreground ,color-fg :background ,color-fg))))
    `(term-default-fg-color ((t (:inherit color-fg))))
    `(term-default-bg-color ((t (:inherit color-bg))))

    ;; erc
    `(erc-nick-default-face ((t (:foreground ,color-keyword))))
    `(erc-my-nick-face ((t (:foreground ,color-param-names))))
    `(erc-current-nick-face ((t (:foreground ,color-built-in))))
    `(erc-notice-face ((t (:foreground ,color-main))))
    `(erc-input-face ((t (:foreground "white"))))
    `(erc-timestamp-face ((t (:foreground ,color-mode-line-bg))))
    `(erc-prompt-face ((t (:foreground "#191919" :background ,color-consquotest))))

    ;;undo-tree
    `(undo-tree-visualizer-active-branch-face ((t (:inherit default))))
    `(undo-tree-visualizer-default-face ((t (:inherit font-lock-comment-face))))
    `(undo-tree-visualizer-register-face ((t (:foreground ,color-param-names :background nil))))
    `(undo-tree-visualizer-current-face ((t (:foreground ,color-types :background nil))))
    `(undo-tree-visualizer-unmodified-face ((t (:foreground ,color-consquotest :background nil))))

    ;;show paren
    `(show-paren-match ((t (:foreground ,color-paren-match-fg :background ,color-paren-match-bg))))
    `(show-paren-mismatch ((t (:inherit error))))

    ;; ido
    `(ido-only-match  ((t (:foreground ,color-main))))
    `(ido-first-match  ((t (:foreground ,color-keyword))))
    `(ido-incomplete-regexp ((t (:foreground ,color-types))))
    `(ido-subdir   ((t (:foreground ,color-param-names))))
    ;; flx-ido
    `(flx-highlight-face         ((t (:foreground ,color-link :background nil :underline nil :weight bold))))

    ;;js2
    `(js2-external-variable  ((t (:foreground ,color-preprocessor :background nil))))
    `(js2-function-param   ((t (:foreground ,color-undefined3 :background nil))))
    `(js2-insquotesce-member  ((t (:foreground ,color-consquotest :background nil))))
    `(js2-jsdoc-html-tag-delimiter ((t (:foreground ,color-comment-symbols :background nil))))
    `(js2-jsdoc-html-tag-name  ((t (:foreground ,color-vertical-line :background nil))))
    `(js2-jsdoc-tag   ((t (:foreground ,color-undefined2 :background nil))))
    `(js2-jsdoc-type   ((t (:foreground ,color-types :background nil))))
    `(js2-jsdoc-value   ((t (:foreground ,color-quotes :background nil))))
    `(js2-private-function-call  ((t (:foreground ,color-undefined3 :background nil))))
    `(js2-private-member   ((t (:foreground ,color-elisp-func-desc :background nil))))
    `(js2-warning   ((t (:foreground nil :background nil :underline ,color-preprocessor))))

    ;;web-mode
    `(web-mode-block-attr-name-face  ((t (:foreground "#8fbc8f" :background nil))))
    `(web-mode-block-attr-value-face  ((t (:inherit font-lock-string-face))))
    `(web-mode-block-comment-face  ((t (:inherit font-lock-comment-face))))
    `(web-mode-block-control-face  ((t (:inherit font-lock-preprocessor-face))))
    `(web-mode-block-delimiter-face  ((t (:inherit font-lock-preprocessor-face))))
    `(web-mode-block-face   ((t (:foreground nil :background "LightYellow1"))))
    `(web-mode-block-string-face   ((t (:inherit font-lock-string-face))))
    `(web-mode-builtin-face   ((t (:inherit font-lock-builtin-face))))
    `(web-mode-comment-face   ((t (:inherit font-lock-comment-face))))
    `(web-mode-comment-keyword-face  ((t (:foreground nil :background nil :weight bold))))
    `(web-mode-consquotest-face   ((t (:foreground ,color-consquotest :background nil))))
    `(web-mode-css-at-rule-face   ((t (:foreground ,color-consquotest :background nil))))
    `(web-mode-css-color-face   ((t (:foreground ,color-built-in :background nil))))
    `(web-mode-css-comment-face   ((t (:inherit font-lock-comment-face))))
    `(web-mode-css-function-face   ((t (:foreground ,color-built-in :background nil))))
    `(web-mode-css-priority-face   ((t (:foreground ,color-built-in :background nil))))
    `(web-mode-css-property-name-face  ((t (:inherit font-lock-variable-name-face))))
    `(web-mode-css-pseudo-class-face  ((t (:foreground ,color-built-in :background nil))))
    `(web-mode-css-selector-face   ((t (:foreground ,color-keyword :background nil))))
    `(web-mode-css-string-face   ((t (:foreground ,color-quotes :background nil))))
    `(web-mode-current-element-highlight-face ((t (:foreground nil :background "#000000"))))
    `(web-mode-doctype-face   ((t (:inherit font-lock-doc-face))))
    `(web-mode-error-face   ((t (:inherit error))))
    `(web-mode-folded-face   ((t (:foreground nil :background nil :underline t))))
    `(web-mode-function-call-face  ((t (:inherit font-lock-function-name-face))))
    `(web-mode-function-name-face  ((t (:inherit font-lock-function-name-face))))
    `(web-mode-html-attr-custom-face  ((t (:inherit font-lock-comment-face))))
    `(web-mode-html-attr-equal-face  ((t (:inherit font-lock-comment-face))))
    `(web-mode-html-attr-name-face  ((t (:inherit font-lock-comment-face))))
    `(web-mode-html-attr-value-face  ((t (:inherit font-lock-string-face))))
    `(web-mode-html-tag-bracket-face  ((t (:inherit font-lock-comment-face))))
    `(web-mode-html-tag-custom-face  ((t (:inherit font-lock-comment-face))))
    `(web-mode-html-tag-face   ((t (:inherit font-lock-comment-face))))
    `(web-mode-javascript-comment-face  ((t (:inherit font-lock-comment-face))))
    `(web-mode-javascript-string-face  ((t (:inherit font-lock-string-face))))
    `(web-mode-json-comment-face   ((t (:inherit font-lock-comment-face))))
    `(web-mode-json-context-face   ((t (:foreground "orchid3" :background nil))))
    `(web-mode-json-key-face   ((t (:foreground "plum" :background nil))))
    `(web-mode-json-string-face   ((t (:inherit font-lock-string-face))))
    `(web-mode-keyword-face   ((t (:inherit font-lock-keyword-face))))
    `(web-mode-param-name-face   ((t (:foreground "Snow3" :background nil))))
    `(web-mode-part-comment-face   ((t (:inherit font-lock-comment-face))))
    `(web-mode-part-face    ((t (:foreground nil :background "LightYellow1"))))
    `(web-mode-part-string-face   ((t (:inherit font-lock-string-face))))
    `(web-mode-preprocessor-face   ((t (:inherit font-lock-preprocessor-face))))
    `(web-mode-string-face   ((t (:inherit font-lock-string-face))))
    `(web-mode-symbol-face   ((t (:foreground "gold" :background nil))))
    `(web-mode-type-face    ((t (:inherit font-lock-type-face))))
    `(web-mode-variable-name-face  ((t (:inherit font-lock-variable-name-face))))
    `(web-mode-warning-face   ((t (:inherit font-lock-warning-face))))
    `(web-mode-whitespace-face   ((t (:foreground nil :background "DarkOrchid4"))))

    ;; helm
    `(helm-M-x-key   ((t (:foreground ,color-preprocessor :underline nil))))
    ;;`(helm-action   ((t ())))
    ;;`(helm-bookmark-addressbook ((t ())))
    ;;`(helm-bookmark-directory  ((t ())))
    ;;`(helm-bookmark-file  ((t ())))
    ;;`(helm-bookmark-gnus  ((t ())))
    ;;`(helm-bookmark-info  ((t ())))
    ;;`(helm-bookmark-man  ((t ())))
    ;;`(helm-bookmark-w3m  ((t ())))
    ;;`(helm-buffer-not-saved  ((t ())))
    ;;`(helm-buffer-process  ((t ())))
    ;;`(helm-buffer-saved-out  ((t ())))
    ;;`(helm-buffer-size   ((t ())))
    `(helm-candidate-number  ((t (:foreground ,color-main :background ,color-mode-line-bg))))
    `(helm-ff-directory   ((t (:foreground ,color-keyword))))
    `(helm-ff-executable   ((t (:foreground ,color-main))))
    `(helm-ff-file   ((t (:inherit default))))
    ;;`(helm-ff-invalid-symlink  ((t ())))
    `(helm-ff-prefix   ((t (:foreground ,color-types))))
    ;;`(helm-ff-symlink   ((t ())))
    ;;`(helm-grep-cmd-line  ((t ())))
    `(helm-grep-file   ((t (:foreground ,color-keyword))))
    ;;`(helm-grep-finish   ((t ())))
    `(helm-grep-lineno   ((t (:foreground ,color-consquotest))))
    `(helm-grep-match   ((t (:foreground ,color-fg :background ,color-region-bg))))
    ;;`(helm-grep-running  ((t ())))
    `(helm-header   ((t (:foreground ,color-bg :background ,color-fg))))
    ;;`(helm-helper   ((t ())))
    ;;`(helm-history-deleted  ((t ())))
    ;;`(helm-history-remote  ((t ())))
    ;;`(helm-lisp-completion-info ((t ())))
    ;;`(helm-lisp-show-completion ((t ())))
    `(helm-match    ((t (:foreground ,color-keyword :background ,color-vertical-line))))
    ;;`(helm-moccur-buffer  ((t ())))
    `(helm-selection   ((t (:foreground ,color-param-names :background ,color-region-bg :weight bold))))
    ;;`(helm-selection-line  ((t ())))
    ;;`(helm-separator   ((t ())))
    `(helm-source-header   ((t (:foreground ,color-vertical-line :background ,color-keyword))))
    ;;`(helm-visible-mark  ((t ())))

    ;; jabber
    `(jabber-activity-face  ((t (:inherit font-lock-variable-name-face :weight bold))))
    `(jabber-activity-personal-face ((t (:inherit font-lock-function-name-face :weight bold))))
    `(jabber-chat-error   ((t (:inherit error :weight bold))))
    `(jabber-chat-prompt-foreign  ((t (:foreground ,color-main  :background nil :underline nil :weight bold))))
    `(jabber-chat-prompt-local  ((t (:foreground ,color-built-in   :background nil :underline nil :weight bold))))
    `(jabber-chat-prompt-system  ((t (:foreground ,color-param-names :background nil :underline nil :weight bold))))
    `(jabber-chat-text-foreign  ((t (:inherit default :background nil))))
    `(jabber-chat-text-local  ((t (:inherit default :weight bold))))
    `(jabber-rare-time-face  ((t (:foreground ,color-consquotest :background nil :underline t))))
    `(jabber-roster-user-away  ((t (:inherit font-lock-string-face))))
    `(jabber-roster-user-chatty  ((t (:foreground ,color-preprocessor :background nil :weight bold))))
    ;;`(jabber-roster-user-dnd  ((t (:foreground "red" :background nil))))
    `(jabber-roster-user-error  ((t (:inherit error))))
    `(jabber-roster-user-offline  ((t (:inherit font-lock-comment-face))))
    `(jabber-roster-user-online  ((t (:inherit font-lock-keyword-face :weight bold))))
    `(jabber-roster-user-xa  ((t (:inherit font-lock-doc-face))))
    ;;`(jabber-title-large  ((t (:foreground nil :background nil :weight bold))))
    ;;`(jabber-title-medium  ((t (:foreground nil :background nil :weight bold))))
    ;;`(jabber-title-small  ((t (:foreground nil :background nil :weight bold))))


    ;; rainbow delim
    `(rainbow-delimiters-depth-1-face ((t (:foreground ,color-gradient0 :background nil :weight bold))))
    `(rainbow-delimiters-depth-2-face ((t (:foreground ,color-gradient1 :background nil :weight bold))))
    `(rainbow-delimiters-depth-3-face ((t (:foreground ,color-gradient2 :background nil :weight bold))))
    `(rainbow-delimiters-depth-4-face ((t (:foreground ,color-gradient3 :background nil :weight bold))))
    `(rainbow-delimiters-depth-5-face ((t (:foreground ,color-gradient4 :background nil :weight bold))))
    `(rainbow-delimiters-depth-6-face ((t (:foreground ,color-gradient5 :background nil :weight bold))))
    `(rainbow-delimiters-depth-7-face ((t (:foreground ,color-gradient0 :background nil :weight bold))))
    `(rainbow-delimiters-depth-8-face ((t (:foreground ,color-gradient1 :background nil :weight bold))))
    `(rainbow-delimiters-depth-9-face ((t (:foreground ,color-gradient2 :background nil :weight bold))))
    `(rainbow-delimiters-unmatched-face ((t (:inherit error))))

    ;; auto complete
    `(ac-candidate-face   ((t (:foreground "black" :background ,color-fg))))
    `(ac-selection-face   ((t (:foreground ,color-fg :background ,color-keyword))))
    `(ac-candidate-mouse-face  ((t (:inherit ac-selection-face))))
    `(ac-clang-candidate-face  ((t (:inherit ac-candidate-face))))
    `(ac-clang-selection-face  ((t (:inherit ac-selection-face))))
    `(ac-completion-face   ((t (:inherit font-lock-comment-face :underline t))))
    `(ac-gtags-candidate-face  ((t (:inherit ac-candidate-face))))
    `(ac-gtags-selection-face  ((t (:inherit ac-selection-face))))
    `(ac-slime-menu-face   ((t (:inherit ac-candidate-face))))
    `(ac-slime-selection-face  ((t (:inherit ac-selection-face))))
    `(ac-yasnippet-candidate-face ((t (:inherit ac-candidate-face))))
    `(ac-yasnippet-selection-face ((t (:inherit ac-selection-face))))

    ;;`(company-echo                   ((t (:foreground nil :background nil))))
    ;;`(company-echo-common            ((t (:foreground nil :background "firebrick4"))))
    ;;`(company-preview                ((t (:foreground "wheat" :background "blue4"))))
    `(company-preview-common           ((t (:inherit font-lock-comment-face))))
    ;;`(company-preview-search         ((t (:foreground "wheat" :background "blue1"))))
    ;;`(company-template-field         ((t (:foreground "black" :background "preprocessor"))))
    `(company-scrollbar-bg             ((t (:foreground nil :background ,color-vertical-line))))
    `(company-scrollbar-fg             ((t (:foreground nil :background ,color-comment-symbols))))
    `(company-tooltip                  ((t (:foreground ,color-bg :background ,color-fg))))
    `(company-tooltip-common           ((t (:foreground ,color-undefined2 :background ,color-fg))))
    `(company-tooltip-common-selection ((t (:foreground ,color-bg :background ,color-keyword))))
    `(company-tooltip-mouse            ((t (:foreground nil :background ,color-built-in))))
    `(company-tooltip-selection        ((t (:foreground ,color-comment-symbols :background ,color-keyword))))


    ;; w3m
    ;;`(w3m-anchor   ((t (:foreground "cyan" :background nil))))
    ;;`(w3m-arrived-anchor  ((t (:foreground "LightSkyBlue" :background nil))))
    `(w3m-bold    ((t (:foreground ,color-keyword :background nil :weight bold))))
    `(w3m-current-anchor   ((t (:foreground nil :background nil :underline t :weight bold))))
    ;;`(w3m-form    ((t (:foreground "red" :background nil :underline t))))
    ;;`(w3m-form-button   ((t (:foreground "red" :background nil :underline t))))
    ;;`(w3m-form-button-mouse  ((t (:foreground "red" :background nil :underline t))))
    ;;`(w3m-form-button-pressed  ((t (:foreground "red" :background nil :underline t))))
    ;;`(w3m-form-inactive  ((t (:foreground "grey70" :background nil :underline t))))
    ;;`(w3m-header-line-location-content ((t (:foreground "LightGoldenrod" :background "Comment-Text20"))))
    ;;`(w3m-header-line-location-title ((t (:foreground "Cyan" :background "Comment-Text20"))))
    ;;`(w3m-history-current-url  ((t (:foreground "LightSkyBlue" :background "SkyBlue4"))))
    ;;`(w3m-image   ((t (:foreground "PaleGreen" :background nil))))
    ;;`(w3m-image-anchor   ((t (:foreground nil :background "dark green"))))
    ;;`(w3m-insert   ((t (:foreground "orchid" :background nil))))
    `(w3m-italic    ((t (:foreground ,color-preprocessor :background nil :underline t))))
    ;;`(w3m-session-select  ((t (:foreground "cyan" :background nil))))
    ;;`(w3m-session-selected  ((t (:foreground "cyan" :background nil :underline t :weight bold))))
    ;;`(w3m-strike-through  ((t (:foreground nil :background nil))))
    ;;`(w3m-tab-background  ((t (:foreground "black" :background "white"))))
    ;;`(w3m-tab-mouse   ((t (:foreground nil :background nil))))
    ;;`(w3m-tab-selected   ((t (:foreground "black" :background "cyan"))))
    ;;`(w3m-tab-selected-background ((t (:foreground "black" :background "white"))))
    ;;`(w3m-tab-selected-retrieving ((t (:foreground "red" :background "cyan"))))
    ;;`(w3m-tab-unselected  ((t (:foreground "black" :background "blue"))))
    ;;`(w3m-tab-unselected-retrieving ((t (:foreground "PreprocessorRed" :background "blue"))))
    ;;`(w3m-tab-unselected-unseen ((t (:foreground "comment-text60" :background "blue"))))
    `(w3m-underline   ((t (:foreground ,color-main :background nil :underline t))))


    ;; ediff
    `(ediff-current-diff-A((t (:foreground nil :background ,color-types))))
    `(ediff-current-diff-B((t (:foreground nil :background ,color-main))))
    `(ediff-current-diff-C((t (:foreground nil :background ,color-param-names))))
    ;;`(ediff-current-diff-Ancestor((t ())))
    `(ediff-even-diff-A   ((t (:foreground nil :background "#191925"))))
    `(ediff-even-diff-B   ((t (:foreground nil :background "#191925"))))
    `(ediff-even-diff-C   ((t (:foreground nil :background "#191925"))))
    ;;`(ediff-even-diff-Ancestor  ((t ())))

    `(diff-added             ((t (:background nil :foreground ,color-main))))
    `(diff-changed           ((t (:background nil :foreground ,color-param-names))))
    `(diff-removed           ((t (:background nil :foreground ,color-types))))
    `(diff-context           ((t (:foreground ,color-comment-text :background nil))))
    `(diff-file-header       ((t (:foreground ,color-bg :background nil :weight bold))))
    `(diff-function          ((t (:foreground ,color-bg :background nil))))
    `(diff-header            ((t (:foreground ,color-bg :background nil))))
    `(diff-hunk-header       ((t (:foreground ,color-bg :background nil))))
    `(diff-index             ((t (:foreground ,color-bg :background nil))))
    `(diff-indicator-added   ((t (:inherit diff-added))))
    `(diff-indicator-changed ((t (:inherit diff-changed))))
    `(diff-indicator-removed ((t (:inherit diff-removed))))
    `(diff-nonexistent       ((t (:foreground nil :background nil))))
    `(diff-refine-added      ((t (:foreground nil :background "#649694")))())
    `(diff-refine-changed    ((t (:foreground nil :background "#8f8f40"))))
    `(diff-refine-removed    ((t (:foreground nil :background "#694949"))))

    `(ediff-fine-diff-A   ((t (:foreground ,color-fg :background "#694949"))))
    `(ediff-fine-diff-B   ((t (:foreground ,color-fg :background "#496949"))))
    `(ediff-fine-diff-C   ((t (:foreground ,color-fg :background "#696949"))))
    ;;`(ediff-fine-diff-Ancestor  ((t ())))

    `(ediff-odd-diff-A   ((t (:foreground nil :background "#171723"))))
    `(ediff-odd-diff-B   ((t (:foreground nil :background "#171723"))))
    `(ediff-odd-diff-C   ((t (:foreground nil :background "#171723"))))
    ;;`(ediff-odd-diff-Ancestor  ((t ())))

    ;; man pages
    `(Man-overstrike ((t (:foreground ,color-keyword))))
    `(Man-underline ((t (:foreground ,color-param-names))))

    `(slime-apropos-label  ((t (:foreground ,color-types :background nil))))
    `(slime-apropos-symbol  ((t (:foreground ,color-keyword :background nil))))
    `(slime-error-face  ((t (:foreground ,color-types :background nil :underline t))))
    `(slime-highlight-face  ((t (:foreground nil :background ,color-undefined3))))
    `(slime-inspector-action-face  ((t (:foreground "red" :background nil))))
    `(slime-inspector-label-face  ((t (:foreground "#ab85a3" :background nil))))
    `(slime-inspector-topline-face  ((t (:foreground nil :background nil))))
    `(slime-inspector-type-face  ((t (:foreground "#ad8572" :background nil))))
    `(slime-inspector-value-face  ((t (:foreground "#9fbfdf" :background nil))))
    `(slime-note-face  ((t (:foreground nil :background nil :underline t))))
    `(slime-style-warning-face  ((t (:foreground ,color-preprocessor :background nil :underline t))))
    `(slime-warning-face  ((t (:foreground nil :background nil :underline t))))

    ;; org
    ;;`(org-agenda-calendar-event ((t (:foreground nil :background nil))))
    ;;`(org-agenda-calendar-sexp ((t (:foreground nil :background nil))))
    ;;`(org-agenda-clocking ((t (:foreground nil :background nil))))
    ;;`(org-agenda-column-dateline ((t (:foreground nil :background nil))))
    ;;`(org-agenda-current-time ((t (:foreground nil :background nil))))
    ;;`(org-agenda-date ((t (:foreground nil :background nil))))
    ;;`(org-agenda-date-today ((t (:foreground nil :background nil))))
    ;;`(org-agenda-date-weekend ((t (:foreground nil :background nil))))
    ;;`(org-agenda-diary ((t (:foreground nil :background nil))))
    ;;`(org-agenda-dimmed-todo-face ((t (:foreground nil :background nil))))
    ;;`(org-agenda-done ((t (:foreground nil :background nil))))
    ;;`(org-agenda-filter-category ((t (:foreground nil :background nil))))
    ;;`(org-agenda-filter-tags ((t (:foreground nil :background nil))))
    ;;`(org-agenda-restriction-lock ((t (:foreground nil :background nil))))
    ;;`(org-agenda-structure ((t (:foreground nil :background nil))))
    ;;`(org-archived ((t (:foreground nil :background nil))))
    ;;`(org-beamer-tag ((t (:foreground nil :background nil))))
    ;;`(org-block ((t (:foreground nil :background nil))))
    ;;`(org-block-background ((t (:foreground nil :background nil))))
    ;;`(org-block-begin-line ((t (:foreground nil :background nil))))
    ;;`(org-block-end-line ((t (:foreground nil :background nil))))
    ;;`(org-checkbox ((t (:foreground nil :background nil))))
    ;;`(org-checkbox-statistics-done ((t (:foreground nil :background nil))))
    ;;`(org-checkbox-statistics-todo ((t (:foreground nil :background nil))))
    ;;`(org-clock-overlay ((t (:foreground nil :background nil))))
    ;;`(org-code ((t (:foreground nil :background nil))))
    ;;`(org-column ((t (:foreground nil :background nil))))
    ;;`(org-column-title ((t (:foreground nil :background nil))))
    ;;`(org-date ((t (:foreground nil :background nil))))
    ;;`(org-date-selected ((t (:foreground nil :background nil))))
    ;;`(org-default ((t (:foreground nil :background nil))))
    ;;`(org-document-info ((t (:foreground nil :background nil))))
    ;;`(org-document-info-keyword ((t (:foreground nil :background nil))))
    ;;`(org-document-title ((t (:foreground nil :background nil))))
    `(org-done ((t (:foreground ,color-main :background nil))))
    `(org-todo ((t (:foreground ,color-types :background nil))))
    ;;`(org-drawer ((t (:foreground nil :background nil))))
    ;;`(org-ellipsis ((t (:foreground nil :background nil))))
    ;;`(org-footnote ((t (:foreground nil :background nil))))
    ;;`(org-formula ((t (:foreground nil :background nil))))
    ;;`(org-headline-done ((t (:foreground nil :background nil))))
    `(org-hide ((t (:foreground ,color-bg :background nil))))
    ;;`(org-latex-and-export-specials ((t (:foreground nil :background nil))))
    `(org-level-1 ((t (:foreground ,color-gradient2 :background nil :weight bold))))
    `(org-level-2 ((t (:foreground ,color-gradient1 :background nil :weight bold))))
    `(org-level-3 ((t (:foreground ,color-gradient0 :background nil :weight bold))))
    `(org-level-4 ((t (:foreground ,color-gradient3 :background nil :weight bold))))
    `(org-level-5 ((t (:foreground ,color-gradient4 :background nil :weight bold))))
    `(org-level-6 ((t (:foreground ,color-gradient5 :background nil :weight bold))))
    `(org-level-7 ((t (:foreground ,color-gradient4 :background nil :weight bold))))
    `(org-level-8 ((t (:foreground ,color-gradient3 :background nil :weight bold))))
   ;'(org-link                  ((t (:foreground "royal blue" :underline t))))
    `(org-link ((t (:foreground "#fff" :background ,color-fringe :underline t))))
    ;;`(org-list-dt ((t (:foreground nil :background nil))))
    ;;`(org-meta-line ((t (:foreground nil :background nil))))
    ;;`(org-mode-line-clock ((t (:foreground nil :background nil))))
    ;;`(org-mode-line-clock-overrun ((t (:foreground nil :background nil))))
    ;;`(org-property-value ((t (:foreground nil :background nil))))
    ;;`(org-quote ((t (:foreground nil :background nil))))
    ;;`(org-scheduled ((t (:foreground nil :background nil))))
    ;;`(org-scheduled-previously ((t (:foreground nil :background nil))))
    ;;`(org-scheduled-today ((t (:foreground nil :background nil))))
    ;;`(org-sexp-date ((t (:foreground nil :background nil))))
    ;;`(org-special-keyword ((t (:foreground nil :background nil))))
    ;;`(org-table ((t (:foreground nil :background nil))))
    ;;`(org-tag ((t (:foreground nil :background nil))))
    ;;`(org-target ((t (:foreground nil :background nil))))
    ;;`(org-time-grid ((t (:foreground nil :background nil))))
    ;;`(org-upcoming-deadline ((t (:foreground nil :background nil))))
    ;;`(org-verbatim ((t (:foreground nil :background nil))))
    ;;`(org-verse ((t (:foreground nil :background nil))))
    ;;`(org-warning ((t (:foreground nil :background nil))))


    ;; message-mode
    `(message-cited-text  ((t (:inherit font-lock-comment-face))))
    `(message-header-cc  ((t (:foreground ,color-built-in :background nil :weight bold))))
    `(message-header-name  ((t (:foreground ,color-preprocessor :background nil))))
    `(message-header-newsgroups  ((t (:foreground ,color-elisp-func-desc :background nil :weight bold))))
    `(message-header-other  ((t (:foreground ,color-keyword :background nil))))
    `(message-header-subject  ((t (:foreground ,color-quotes :background nil))))
    `(message-header-to  ((t (:foreground ,color-param-names :background nil :weight bold))))
    `(message-header-xheader  ((t (:foreground ,color-consquotest :background nil))))
    `(message-mml  ((t (:foreground ,color-elisp-func-desc :background nil))))

    ;; gnus
    `(gnus-button    ((t (:foreground nil :background nil :weight bold))))
    `(gnus-cite-1    ((t (:foreground "light blue" :background nil))))
    `(gnus-cite-10    ((t (:foreground "plum1" :background nil))))
    `(gnus-cite-11    ((t (:foreground "turquoise" :background nil))))
    `(gnus-cite-2    ((t (:foreground "light cyan" :background nil))))
    `(gnus-cite-3    ((t (:foreground "light yellow" :background nil))))
    `(gnus-cite-4    ((t (:foreground "light pink" :background nil))))
    `(gnus-cite-5    ((t (:foreground "pale green" :background nil))))
    `(gnus-cite-6    ((t (:foreground "beige" :background nil))))
    `(gnus-cite-7    ((t (:foreground "preprocessor" :background nil))))
    `(gnus-cite-8    ((t (:foreground "magenta" :background nil))))
    `(gnus-cite-9    ((t (:foreground "violet" :background nil))))
    `(gnus-cite-attribution   ((t (:foreground nil :background nil))))
    `(gnus-emphasis-bold    ((t (:foreground nil :background nil :weight bold))))
    `(gnus-emphasis-bold-italic   ((t (:foreground nil :background nil :weight bold))))
    `(gnus-emphasis-highlight-words  ((t (:foreground "yellow" :background "black"))))
    `(gnus-emphasis-italic   ((t (:foreground nil :background nil))))
    `(gnus-emphasis-strikethru   ((t (:foreground nil :background nil))))
    `(gnus-emphasis-underline   ((t (:foreground nil :background nil :underline t))))
    `(gnus-emphasis-underline-bold  ((t (:foreground nil :background nil :underline t :weight bold))))
    `(gnus-emphasis-underline-bold-italic ((t (:foreground nil :background nil :underline t :weight bold))))
    `(gnus-emphasis-underline-italic  ((t (:foreground nil :background nil :underline t))))
    `(gnus-group-mail-1    ((t (:foreground ,color-keyword :background nil :weight bold))))
    `(gnus-group-mail-1-empty   ((t (:foreground ,color-keyword :background nil))))
    `(gnus-group-mail-2    ((t (:foreground ,color-link :background nil :weight bold))))
    `(gnus-group-mail-2-empty   ((t (:foreground ,color-link :background nil))))
    `(gnus-group-mail-3    ((t (:foreground ,color-built-in :background nil :weight bold))))
    `(gnus-group-mail-3-empty   ((t (:foreground ,color-built-in :background nil))))
    `(gnus-group-mail-low   ((t (:foreground ,color-param-names :background nil :weight bold))))
    `(gnus-group-mail-low-empty   ((t (:foreground ,color-param-names :background nil))))
    `(gnus-group-news-1    ((t (:foreground "PaleTurquoise" :background nil :weight bold))))
    `(gnus-group-news-1-empty   ((t (:foreground "PaleTurquoise" :background nil))))
    `(gnus-group-news-2    ((t (:foreground "turquoise" :background nil :weight bold))))
    `(gnus-group-news-2-empty   ((t (:foreground "turquoise" :background nil))))
    `(gnus-group-news-3    ((t (:foreground nil :background nil :weight bold))))
    `(gnus-group-news-3-empty   ((t (:foreground nil :background nil))))
    `(gnus-group-news-4    ((t (:foreground nil :background nil :weight bold))))
    `(gnus-group-news-4-empty   ((t (:foreground nil :background nil))))
    `(gnus-group-news-5    ((t (:foreground nil :background nil :weight bold))))
    `(gnus-group-news-5-empty   ((t (:foreground nil :background nil))))
    `(gnus-group-news-6    ((t (:foreground nil :background nil :weight bold))))
    `(gnus-group-news-6-empty   ((t (:foreground nil :background nil))))
    `(gnus-group-news-low   ((t (:foreground "DarkTurquoise" :background nil :weight bold))))
    `(gnus-group-news-low-empty   ((t (:foreground "DarkTurquoise" :background nil))))
    `(gnus-header-content   ((t (:inherit message-header-other))))
    `(gnus-header-from    ((t (:inherit message-header-other))))
    `(gnus-header-name    ((t (:inherit message-header-name))))
    `(gnus-header-newsgroups   ((t (:inherit message-header-newsgroups))))
    `(gnus-header-subject   ((t (:inherit message-header-subject))))
    `(gnus-server-agent    ((t (:foreground "PaleTurquoise" :background nil :weight bold))))
    `(gnus-server-closed    ((t (:foreground "LightBlue" :background nil))))
    `(gnus-server-denied    ((t (:foreground "pink" :background nil :weight bold))))
    `(gnus-server-offline   ((t (:foreground "yellow" :background nil :weight bold))))
    `(gnus-server-opened    ((t (:foreground "green1" :background nil :weight bold))))
    `(gnus-signature    ((t (:foreground nil :background nil))))
    `(gnus-splash    ((t (:foreground "#cccccc" :background nil))))
    `(gnus-summary-cancelled   ((t (:foreground "yellow" :background "black"))))
    `(gnus-summary-high-ancient   ((t (:foreground "SkyBlue" :background nil :weight bold))))
    `(gnus-summary-high-read   ((t (:foreground "PaleGreen" :background nil :weight bold))))
    `(gnus-summary-high-ticked   ((t (:foreground "pink" :background nil :weight bold))))
    `(gnus-summary-high-undownloaded  ((t (:foreground "LightComment-Text" :background nil :weight bold))))
    `(gnus-summary-high-unread   ((t (:foreground nil :background nil :weight bold))))
    `(gnus-summary-low-ancient   ((t (:foreground "SkyBlue" :background nil))))
    `(gnus-summary-low-read   ((t (:foreground "PaleGreen" :background nil))))
    `(gnus-summary-low-ticked   ((t (:foreground "pink" :background nil))))
    `(gnus-summary-low-undownloaded  ((t (:foreground "LightComment-Text" :background nil))))
    `(gnus-summary-low-unread   ((t (:foreground nil :background nil))))
    `(gnus-summary-normal-ancient  ((t (:inherit default))))
    `(gnus-summary-normal-read   ((t (:foreground ,color-main :background nil))))
    `(gnus-summary-normal-ticked   ((t (:foreground ,color-preprocessor :background nil))))
    `(gnus-summary-normal-undownloaded  ((t (:foreground ,color-comment-symbols :background nil))))
    `(gnus-summary-normal-unread   ((t (:foreground ,color-built-in :background nil))))
    `(gnus-summary-selected   ((t (:foreground nil :background nil :underline t))))

    `(twittering-timeline-footer-face ((t (:foreground nil :background nil :inherit font-lock-function-name-face))))
    `(twittering-timeline-header-face ((t (:foreground nil :background nil :inherit font-lock-function-name-face))))
    `(twittering-uri-face  ((t (:foreground nil :background nil :underline t))))
    `(twittering-username-face  ((t (:foreground nil :background nil :inherit font-lock-keyword-face :underline t))))

    ;; whitespace mode
    `(whitespace-empty   ((t (:foreground ,color-comment-text :background "comment-text10"))))
    `(whitespace-hspace   ((t (:foreground ,color-comment-text :background ,color-line-number-fg))))
    `(whitespace-indentation  ((t (:foreground ,color-comment-text :background "comment-text12"))))
    `(whitespace-line   ((t (:foreground ,color-consquotest :background nil))))
    `(whitespace-newline   ((t (:foreground ,color-comment-text :background nil))))
    `(whitespace-space   ((t (:foreground ,color-comment-text :background nil))))
    `(whitespace-space-after-tab  ((t (:foreground ,color-comment-text :background "comment-text13"))))
    `(whitespace-space-before-tab ((t (:foreground ,color-comment-text :background "comment-text14"))))
    `(whitespace-tab   ((t (:foreground ,color-comment-text :background ,color-line-number-fg))))
    `(whitespace-trailing  ((t (:foreground ,color-gradient3 :background ,color-bg :weight bold))))

    ;; magit
    `(magit-section-heading        ((t (:foreground ,color-keyword, :background nil))))
    `(magit-hash                   ((t (:foreground ,color-consquotest :background nil))))
    `(magit-branch-local           ((t (:foreground ,color-preprocessor :background nil))))
    `(magit-branch-remote          ((t (:foreground ,color-param-names :background nil))))

    `(magit-diff-added             ((t (:background ,color-add-bg :foreground ,color-add-fg))))
    `(magit-diff-added-highlight   ((t (:background ,color-add-bg :foreground ,color-add-fg))))
    `(magit-diff-removed           ((t (:background ,color-remove-bg :foreground ,color-remove-fg))))
    `(magit-diff-removed-highlight ((t (:background ,color-remove-bg :foreground ,color-remove-fg))))

    ;; Prevents default, gray backgrounds
    ;; Solution based on https://github.com/tee3/unobtrusive-magit-theme/blob/master/unobtrusive-magit-theme.el
    `(magit-diff-context-highlight  ((t (:inherit magit-diff-context))))
    `(magit-diff-file-heading           ((t (:background "#2d3144" :foreground nil))))
    `(magit-diff-file-heading-highlight           ((t (:background "#323958" :foreground nil))))
    `(magit-diff-file-heading-selection        ((t (:inherit magit-diff-file-heading))))
    `(magit-section-heading            ((t (:inherit font-lock-type-face))))
    `(magit-section-heading-selection        ((t (:weight bold))))
    `(magit-section-heading-secondary-heading    ((t (:inherit magit-section-heading-selection))))
    `(magit-section-highlight           ((t (:background "#0c0f15" :foreground "#5558a6" :weight bold))))
    `(magit-diff-hunk-heading           ((t (:background "#1b1f2f" :foreground nil))))
    `(magit-diff-hunk-heading-highlight        ((t (:inherit magit-diff-hunk-heading))))
    `(magit-diff-hunk-heading-selection        ((t (:inherit magit-diff-hunk-heading))))
    `(magit-diff-hunk-region            ((t (:inherit magit-diff-hunk-heading))))
    `(magit-blame-date             ((t (:foreground ,color-consquotest :background ,color-bg-2))))
    `(magit-blame-hash             ((t (:foreground ,color-consquotest :background ,color-bg-2))))
    `(magit-blame-heading          ((t (:foreground ,color-keyword :background ,color-bg-2))))
    `(magit-blame-name             ((t (:foreground ,color-main :background ,color-bg-2))))
    `(magit-blame-summary          ((t (:foreground ,color-keyword :background ,color-bg-2))))
    `(magit-dimmed                ((t (:inherit shadow))))
    `(magit-hash                    ((t (:inherit log-view-message))))
    `(magit-keyword                ((t (:inherit default))))
    `(magit-tag                    ((t (:inherit change-log-list))))
    `(magit-head                    ((t (:inherit change-log-list :inverse-video t))))
    `(magit-filename                ((t (:inherit change-log-file))))

    ;; NOTE If odd colors appear, give these vars a look:
    ;;`(git-commit-summary                ((t (:inherit log-edit-summary))))
    ;;`(git-commit-overlong-summary        ((t (:inherit warning))))
    ;;`(git-commit-nonempty-second-line        ((t (:inherit warning))))
    ;;`(git-commit-note                ((t (:inherit default))))
    ;;`(git-commit-pseudo-header            ((t (:inherit log-edit-unknown-header))))
    ;;`(git-commit-known-pseudo-header        ((t (:inherit git-commit-pseudo-header))))
    ;;`(git-commit-comment-action            ((t (:inherit font-lock-comment-face))))
    ;;`(git-commit-comment-branch-local        ((t (:inherit font-lock-comment-face))))
    ;;`(git-commit-comment-branch-remote        ((t (:inherit font-lock-comment-face))))
    ;;`(git-commit-comment-detached        ((t (:inherit font-lock-comment-face))))
    ;;`(git-commit-comment-file            ((t (:inherit font-lock-comment-face))))
    ;;`(git-commit-comment-heading            ((t (:inherit font-lock-comment-face))))
    ;;`(git-commit-comment-keyword            ((t (:inherit font-lock-comment-face))))

    ;; Old vars (check if these are deprecated)
    `(magit-branch    ((t (:foreground ,color-preprocessor :background nil))))
    `(magit-diff-add    ((t (:background nil :foreground ,color-main))))
    `(magit-diff-del    ((t (:background nil :foreground ,color-types))))
    `(magit-diff-file-header   ((t (:foreground ,color-bg :background ,color-keyword :weight bold))))
    `(magit-diff-hunk-header   ((t (:foreground ,color-bg :background ,color-keyword))))
    `(magit-diff-merge-current   ((t (:foreground ,color-preprocessor :background nil))))
    `(magit-diff-merge-diff3-separator  ((t (:foreground ,color-preprocessor :background nil))))
    `(magit-diff-merge-proposed   ((t (:foreground ,color-preprocessor :background nil))))
    `(magit-diff-merge-separator   ((t (:foreground ,color-preprocessor :background nil))))
    `(magit-diff-none    ((t (:foreground ,color-fg :background ,color-region-bg))))
    `(magit-header    ((t (:foreground ,color-keyword :background nil))))
    `(magit-item-highlight   ((t (:foreground nil :background ,color-region-bg))))
    `(magit-key-mode-button-face   ((t (:foreground ,color-built-in :background nil))))
    `(magit-key-mode-header-face   ((t (:foreground ,color-keyword :background nil))))
    `(magit-log-author    ((t (:foreground ,color-types :background nil))))
    `(magit-log-author-date-cutoff  ((t (:foreground ,color-types :background nil :weight bold))))
    `(magit-log-date    ((t (:foreground nil :background nil))))
    `(magit-log-graph    ((t (:foreground ,color-bg-2 :background nil))))
    `(magit-log-sha1    ((t (:foreground ,color-consquotest :background nil))))
    `(magit-section-title   ((t (:foreground ,color-keyword :background nil))))
    `(magit-tag     ((t (:foreground ,color-keyword :background nil))))
    `(magit-whitespace-warning-face  ((t (:foreground ,color-bg :background "white" :weight bold))))

    `(git-gutter:deleted   ((t (:foreground ,color-types :background nil :weight bold))))
    `(git-gutter:modified  ((t (:foreground ,color-consquotest :background nil :weight bold))))
    `(git-gutter:separator ((t (:foreground ,color-preprocessor :background nil :weight bold))))
    `(git-gutter:unchanged ((t (:foreground ,color-param-names :background nil))))

    `(highlight-indentation-current-column-face ((t (:foreground nil :background ,color-comment-text))))
    `(highlight-indentation-face                ((t (:foreground nil :background ,color-vertical-line))))

    ;; trailing whitespace
    `(trailing-whitespace ((t (:background "white" :weight bold))))

    ;; auctex
    `(font-latex-bold-face                 ((t (:inherit bold :foreground ,color-comment-text))))
    `(font-latex-doctex-documentation-face ((t (:background unspecified))))
    `(font-latex-doctex-preprocessor-face  ((t (:inherit (font-latex-doctex-documentation-face font-lock-builtin-face font-lock-preprocessor-face)))))
    `(font-latex-italic-face               ((t (:inherit italic :foreground ,color-comment-text))))
    `(font-latex-math-face                 ((t (:foreground ,color-consquotest))))
    `(font-latex-sectioning-0-face         ((t (:inherit font-latex-sectioning-1-face :height 1.1))))
    `(font-latex-sectioning-1-face         ((t (:inherit font-latex-sectioning-2-face :height 1.1))))
    `(font-latex-sectioning-2-face         ((t (:inherit font-latex-sectioning-3-face :height 1.1))))
    `(font-latex-sectioning-3-face         ((t (:inherit font-latex-sectioning-4-face :height 1.1))))
    `(font-latex-sectioning-4-face         ((t (:inherit font-latex-sectioning-5-face :height 1.1))))
    `(font-latex-sectioning-5-face         ((t (:foreground ,color-types :weight bold))))
    `(font-latex-sedate-face               ((t (:foreground ,color-comment-text))))
    `(font-latex-slide-title-face          ((t (:inherit font-lock-type-face :weight bold :height 1.2))))
    `(font-latex-string-face               ((t (:inherit font-lock-string-face))))
    `(font-latex-subscript-face            ((t (:height 0.8))))
    `(font-latex-superscript-face          ((t (:height 0.8))))
    `(font-latex-warning-face              ((t (:inherit font-lock-warning-face))))

    ;; guide-key
    `(guide-key/prefix-command-face    ((t (:foreground ,color-main))))
    `(guide-key/highlight-command-face ((t (:foreground ,color-keyword))))
    `(guide-key/key-face               ((t (:foreground ,color-comment-text))))

    ;; custom
    `(custom-button                  ((t (:foreground nil :background nil))))
    `(custom-button-mouse            ((t (:foreground nil :background nil))))
    `(custom-button-pressed          ((t (:foreground nil :background nil))))
    `(custom-button-pressed-unraised ((t (:foreground ,color-consquotest :background nil))))
    `(custom-button-unraised         ((t (:foreground nil :background nil))))
    `(custom-changed                 ((t (:foreground ,color-types :background nil))))
    `(custom-comment                 ((t (:foreground ,color-bg :background ,color-param-names))))
    `(custom-comment-tag             ((t (:foreground ,color-fg :background nil))))
    `(custom-documentation           ((t (:foreground nil :background nil))))
    `(custom-face-tag                ((t (:foreground ,color-built-in :background nil))))
    `(custom-group-subtitle          ((t (:foreground nil :background nil :weight bold))))
    `(custom-group-tag               ((t (:foreground ,color-built-in :background nil :weight bold))))
    `(custom-group-tag-1             ((t (:foreground ,color-param-names :background nil :weight bold))))
    `(custom-invalid                 ((t (:foreground ,color-bg :background ,color-types))))
    `(custom-link                    ((t (:inherit button))))
    `(custom-modified                ((t (:foreground ,color-types :background nil))))
    `(custom-rogue                   ((t (:foreground ,color-param-names :background ,color-bg))))
    `(custom-saved                   ((t (:foreground nil :background nil :underline t))))
    `(custom-set                     ((t (:foreground ,color-fg :background ,color-comment-symbols))))
    `(custom-state                   ((t (:foreground ,color-main :background nil))))
    `(custom-themed                  ((t (:foreground ,color-types :background nil))))
    `(custom-variable-button         ((t (:foreground nil :background nil :underline t :weight bold))))
    `(custom-variable-tag            ((t (:foreground ,color-built-in :background nil :weight bold))))
    `(custom-visibility              ((t (:inherit button))))

    `(neo-banner-face              ((t (:foreground ,color-built-in :background nil :weight bold))))
    `(neo-button-face              ((t (:foreground nil :background nil))))
    `(neo-dir-link-face            ((t (:foreground ,color-keyword :background nil))))
    `(neo-expand-btn-face          ((t (:foreground ,color-fg :background nil))))
    `(neo-file-link-face           ((t (:foreground ,color-fg :background nil))))
    `(neo-header-face              ((t (:foreground ,color-fg :background nil))))
    `(neo-root-dir-face            ((t (:foreground ,color-main :background nil :weight bold))))
    `(neo-vc-added-face            ((t (:foreground ,color-main :background nil))))
    `(neo-vc-conflict-face         ((t (:foreground ,color-preprocessor :background nil))))
    `(neo-vc-default-face          ((t (:foreground ,color-fg :background nil))))
    `(neo-vc-edited-face           ((t (:foreground ,color-param-names :background nil))))
    `(neo-vc-ignored-face          ((t (:foreground ,color-comment-symbols :background nil))))
    `(neo-vc-missing-face          ((t (:foreground ,color-types :background nil))))
    `(neo-vc-needs-merge-face      ((t (:foreground ,color-preprocessor :background nil))))
    `(neo-vc-needs-update-face     ((t (:foreground nil :background nil :underline t))))
    `(neo-vc-removed-face          ((t (:foreground ,color-consquotest :background nil))))
    `(neo-vc-unlocked-changes-face ((t (:foreground ,color-types :background "Blue"))))
    `(neo-vc-unregistered-face     ((t (:foreground nil :background nil))))
    `(neo-vc-up-to-date-face       ((t (:foreground ,color-fg :background nil))))


    ;; realgud
    `(realgud-overlay-arrow1         ((t (:foreground ,color-main))))
    `(realgud-overlay-arrow2         ((t (:foreground ,color-minibuffer-prompt))))
    `(realgud-overlay-arrow3         ((t (:foreground ,color-preprocessor))))
    `(realgud-bp-enabled-face        ((t (:inherit error))))
    `(realgud-bp-disabled-face       ((t (:foreground ,color-comment-symbols))))
    `(realgud-bp-line-enabled-face   ((t (:box (:color ,color-types)))))
    `(realgud-bp-line-disabled-face  ((t (:box (:color "grey50")))))
    `(realgud-line-number            ((t (:foreground ,color-param-names))))
    `(realgud-backtrace-number       ((t (:foreground ,color-param-names, :weight bold))))

    ;; widget
    `(widget-field  ((t (:foreground ,color-fg :background ,color-comment-symbols))))

    ) ;; end of custom-theme-set-faces

  (custom-theme-set-variables
    'laguna
    `(ansi-color-names-vector
       [,color-mode-line-bg ,color-types ,color-main ,color-param-names ,color-keyword ,color-consquotest ,color-link ,color-fg])))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
    (file-name-as-directory (file-name-directory load-file-name))))

;;;###autoload
(defun laguna()
  "Apply the Laguna theme."
  (interactive)
  (load-theme 'laguna t))


(provide-theme 'laguna)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; laguna-theme.el ends here
