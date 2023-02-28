;;; kosmos-theme.el --- Black and lightgray theme with not so much syntax highlighting.

;; Author: Maxim Kim <habamax@gmail.com>
;; Url: https://github.com/habamax/kosmos-theme
;; Package-Version: 20170502.1850
;; Package-Commit: 616456d2376a75dc31190ad65137d179fbad4336
;; Package-Requires: ((emacs "24"))

;;; Commentary:

;; Black and LightGray theme with limited syntax highlighting focusing on:
;; 1. keywords -- a bit of standout (just white)
;; 2. strings -- clearly visible, to be sure quotes are closed (greenish)
;; 3. comments -- should standout of other source code (kind of cyanish).

;;; Code:

(deftheme kosmos "Have you set up optical filters for you space suit? I have...")

(let
    ((kosmos-fg "#bdbdbd")
     (kosmos-bg "#000000")
     (kosmos-bg-modeline-active "#2f4f4f")
     (kosmos-bg-modeline-inactive "#202020")
     (kosmos-box-modeline-active "#3f5f5f")
     (kosmos-box-modeline-inactive "#303030")
     (kosmos-keyword "#ffffff")
     (kosmos-str "#73bd7a")
     (kosmos-comment "#5797a0")
     (kosmos-gray "#777777")
     (kosmos-fg-dim "#777777")
     (kosmos-bg-dim "#101010")
     (kosmos-fg-dim-2 "#506060")
     (kosmos-fg-todo "#bdabab")
     (kosmos-bg-todo "#775555")
     (kosmos-fg-done "#abbdab")
     (kosmos-bg-done "#777777")
     (kosmos-title "#f0f07f")
     (kosmos-heading "#ffffff")
     (kosmos-bg-hl-parens "#703000")
     (kosmos-bg-alt "#252520")
     (kosmos-fg-modeline-hl "#ffff00")
     (kosmos-bg-whitespace "#1a1a1f")
     (kosmos-fg-whitespace "#303040")
     (kosmos-fg-search "#fff68f")
     (kosmos-bg-search "#606020")
     (kosmos-fg-lazysearch "#40e0d0")
     (kosmos-bg-lazysearch "#206060")
     (kosmos-fg-search-fail "#da70d6")
     (kosmos-bg-search-fail "#603060")
     (kosmos-bg-highlight "#203040")
     (kosmos-fg-url "#90a0bd")
)



  (custom-theme-set-faces
   'kosmos

   ;; standard faces
   `(default ((t (:background ,kosmos-bg :foreground ,kosmos-fg))))
   '(cursor ((nil (:background "#ffffff"))))
   `(region ((t (:background "#839191" :foreground ,kosmos-bg))))
   `(highlight ((nil (:background ,kosmos-bg-highlight))))
   '(bold ((t (:weight bold))))
   '(minibuffer-prompt ((t (:foreground "#00ff00" :weight bold))))
   '(widget-field-face ((t (:background "#a0a0a0" :foreground "#000000"))))
   ;; `(header-line ((t (:foreground ,kosmos-keyword :background "#6b5e46" :box (:line-width 1 :color "#8d7a56" :style none)))))
   `(header-line ((t (:foreground ,kosmos-keyword :background "#404040"))))


   `(isearch ((t (:background ,kosmos-bg-search :foreground ,kosmos-fg-search :weight bold :underline (:color ,kosmos-fg-search)))))
   `(lazy-highlight ((t (:background ,kosmos-bg-lazysearch :foreground ,kosmos-fg-lazysearch :weight bold :underline (:color ,kosmos-fg-lazysearch)))))
   ;; match?
   `(isearch-fail ((t (:background ,kosmos-bg-search-fail :foreground ,kosmos-fg-search-fail :weight bold :underline (:color ,kosmos-fg-search-fail)))))


   ;; frame UI
   `(mode-line ((t (:background ,kosmos-bg-modeline-active :foreground ,kosmos-keyword :box (:line-width 1 :color ,kosmos-box-modeline-active)))))
   `(mode-line-inactive ((t (:background ,kosmos-bg-modeline-inactive :foreground ,kosmos-gray :box (:line-width 1 :color ,kosmos-box-modeline-inactive)))))
   `(mode-line-highlight ((nil (:foreground ,kosmos-fg-modeline-hl :box (:line-width 1 :color ,kosmos-fg)))))
   `(vertical-border ((nil (:foreground ,kosmos-box-modeline-inactive))))
   `(fringe ((nil (:background ,kosmos-bg-dim))))


   ;; syntax font-lock I DO care about
   `(font-lock-string-face ((t (:foreground ,kosmos-str))))
   `(font-lock-comment-face ((t (:foreground ,kosmos-comment))))
   `(font-lock-keyword-face ((t (:foreground ,kosmos-keyword))))
   ;; syntax font-lock I DON'T care about
   '(font-lock-builtin-face ((t nil)))
   '(font-lock-type-face ((t nil)))
   '(font-lock-function-name-face ((t nil)))
   '(font-lock-variable-name-face ((t nil)))
   '(font-lock-constant-face ((t nil)))
   ;; review this later.
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,kosmos-str :weight bold))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,kosmos-str :weight bold :slant italic))))


   ;; parenthesis and pairs
   `(show-paren-match ((t :background ,kosmos-bg-hl-parens)))
   `(sp-show-pair-match-face ((t (:background ,kosmos-bg-hl-parens))))


   ;; links
   `(link ((t (:foreground ,kosmos-fg-url :underline (:color ,kosmos-fg-url)))))
   `(link-visited ((t (:foreground ,kosmos-fg :underline (:color ,kosmos-fg)))))

   ;; dired
   '(dired-directory ((t (:inherit font-lock-keyword-face :weight bold))))

   ;; flycheck
   '(flycheck-warning ((t (:underline (:color "Wheat3" :style wave)))))
   '(flycheck-error ((t (:underline (:color "Coral" :style wave)))))
   '(flycheck-fringe-warning ((t (:foreground "Wheat3"))))
   '(flycheck-fringe-error ((t (:foreground "Coral"))))

   ;; which-key
   '(which-key-key-face ((t (:foreground "#ffa500"))))
   '(which-key-separator-face ((t (:foreground "#4d4d4d"))))

   ;; company
   '(company-tooltip ((t (:background "Gray20" :foreground "Gray80"))))
   '(company-tooltip-selection ((t (:background "LightSteelBlue4" :foreground "White"))))
   '(company-tooltip-annotation ((t (:foreground "Gray60" :slant italic))))
   '(company-tooltip-annotation-selection ((t (:foreground "Gray80"))))
   '(company-tooltip-common ((t (:slant italic))))
   '(company-scrollbar-bg ((t (:background "Gray40"))))
   '(company-scrollbar-fg ((t (:background "Gray80"))))
   '(company-preview ((t (:inherit company-tooltip-selection))))
   '(company-preview-common ((t (:inherit company-preview :slant italic))))

   ;; erc
   '(erc-current-nick-face ((t (:foreground "#ffffff"))))
   ;; if erc-nick-default-face has foreground setup then it could not be
   ;; overriden by erc-my-nick-face
   ;; '(erc-nick-default-face ((t (:foreground "#779977"))))
   '(erc-my-nick-face ((t (:foreground "#cc5555"))))
   '(erc-input-face ((t (:foreground "#8dbdbd"))))
   '(erc-timestamp-face ((t (:foreground "Wheat"))))
   '(erc-notice-face ((t (:foreground "#555555"))))
   '(erc-action-face ((nil (:slant italic))))
   '(erc-button ((t (:underlined on))))


   ;; rcirc
   '(rcirc-server ((t (:foreground "#555555"))))
   '(rcirc-timestamp ((t (:foreground "#555555"))))
   '(rcirc-other-nick ((t (:foreground "#779977"))))
   '(rcirc-my-nick ((t (:foreground "#cc5555"))))
   `(rcirc-url ((t (:foreground ,kosmos-fg-url :weight normal :underline (:color ,kosmos-fg-url)))))


   ;; magit
   '(git-commit-summary ((t (:inherit font-lock-string-face))))

   ;; git gutter fringe
   `(git-gutter-fr:modified ((nil (:background ,kosmos-bg-dim :foreground "#ff55ff"))))
   `(git-gutter-fr:added ((nil (:background ,kosmos-bg-dim :foreground "#55ff55"))))
   `(git-gutter-fr:deleted ((nil (:background ,kosmos-bg-dim :foreground "#ff5555"))))


   ;; ivy
   `(ivy-current-match ((t (:background ,kosmos-bg-highlight))))
   `(ivy-minibuffer-match-face-1 ((t (:foreground ,kosmos-fg-dim))))
   `(ivy-minibuffer-match-face-2 ((t (:foreground ,kosmos-fg-search :weight bold :underline (:color ,kosmos-fg-search)))))
   `(ivy-minibuffer-match-face-3 ((t (:foreground ,kosmos-fg-lazysearch :weight bold :underline (:color ,kosmos-bg-lazysearch)))))
   `(ivy-minibuffer-match-face-4 ((t (:foreground ,kosmos-fg-search-fail :weight bold :underline (:color ,kosmos-bg-search-fail)))))
   `(ivy-modified-buffer ((nil (:foreground ,kosmos-keyword :slant italic))))
   '(ivy-remote ((t (:inherit font-lock-comment-face))))
   `(ivy-virtual ((t (:foreground ,kosmos-fg-dim))))

   ;; swiper
   `(swiper-match-face-1 ((t (:foreground ,kosmos-fg-dim))))
   `(swiper-match-face-2 ((t (:background ,kosmos-bg-search :foreground ,kosmos-fg-search :weight bold :underline (:color ,kosmos-fg-search)))))
   `(swiper-match-face-3 ((t (:background ,kosmos-bg-lazysearch :foreground ,kosmos-fg-lazysearch :weight bold :underline (:color ,kosmos-bg-lazysearch)))))
   `(swiper-match-face-4 ((t (:background ,kosmos-bg-search-fail :foreground ,kosmos-fg-search-fail :weight bold :underline (:color ,kosmos-bg-search-fail)))))


   ;; org
   `(org-document-title ((t (:foreground ,kosmos-keyword :weight bold :height 1.6))))

   `(org-level-1 ((t (:foreground ,kosmos-heading :weight bold :height 1.3))))
   `(org-level-2 ((t (:foreground ,kosmos-heading :weight bold :height 1.2))))
   `(org-level-3 ((t (:foreground ,kosmos-heading :weight bold :height 1.1))))

   `(org-level-4 ((t (:foreground ,kosmos-heading :slant italic :height 1.1))))
   `(org-level-5 ((t (:foreground ,kosmos-heading :slant italic :height 1.1))))
   `(org-level-6 ((t (:foreground ,kosmos-heading :slant italic :height 1.1))))

   `(org-level-7 ((t (:foreground ,kosmos-heading :slant italic :height 1))))
   `(org-level-8 ((t (:foreground ,kosmos-heading :slant italic :height 1))))
   `(org-level-9 ((t (:foreground ,kosmos-heading :slant italic :height 1))))
   `(org-level-10 ((t (:foreground ,kosmos-heading :slant italic :height 1))))

   `(org-tag ((nil (:foreground ,kosmos-comment))))

   `(org-archived ((nil (:foreground ,kosmos-gray))))
   ;; todo: play with colors of the box
   `(org-todo ((nil (:background ,kosmos-bg-todo :foreground ,kosmos-fg-todo :weight bold :box (:line-width 1 :color ,kosmos-fg-todo)))))
   `(org-done ((nil (:background ,kosmos-bg-done :foreground ,kosmos-fg-done :weight bold :box (:line-width 1 :color ,kosmos-fg-done)))))

   '(org-table ((t (:inherit default))))

   `(org-date ((t (:foreground ,kosmos-comment :underline (:color ,kosmos-comment)))))

   `(org-verbatim ((nil (:background ,kosmos-bg-alt :foreground ,kosmos-fg))))

   `(org-special-keyword ((t (:foreground ,kosmos-gray :background ,kosmos-bg-modeline-inactive))))

   `(org-agenda-structure ((t (:foreground ,kosmos-fg :height 1.6 :weight bold))))
   `(org-agenda-date ((nil (:height 1.0))))
   `(org-agenda-date-today ((t (:height 1.5 :weight bold))))
   `(org-agenda-date-weekend ((t (:foreground ,kosmos-title :height 1.3))))

   '(org-scheduled ((t (:inherit :default))))
   `(org-scheduled-today ((t (:inherit :default :foreground ,kosmos-keyword))))
   `(org-scheduled-previously ((t (:inherit :default :foreground "#d05050"))))
   `(org-agenda-done ((t (:inherit :default :foreground ,kosmos-gray))))
   `(org-warning ((t (:foreground "#d0a000"))))

   `(org-agenda-clocking ((t (:background "#303030"))))

   '(org-meta-line ((t (:foreground "#707070" ))))
   '(org-document-info-keyword ((t (:inherit org-meta-line))))

   `(org-block-begin-line ((t :foreground ,kosmos-comment)))
   `(org-block-end-line ((t (:foreground ,kosmos-comment))))


   ;; calendar
   `(calendar-month-header ((t (:foreground ,kosmos-keyword :weight bold))))
   `(calendar-weekday-header ((t (:foreground ,kosmos-comment))))
   `(calendar-weekend-header ((t (:foreground ,kosmos-str :weight bold))))
   `(calendar-today ((t (:foreground ,kosmos-keyword :weight bold))))


   ;; emms
   '(emms-playlist-track-face ((t (:inherit default))))
   '(emms-playlist-selected-face ((t (:background "#20408b" :foreground "white" :weight bold))))


   ;; LaTeX
   '(font-latex-sectioning-1-face ((t (:inherit org-level-1))))
   '(font-latex-sectioning-2-face ((t (:inherit org-level-2))))
   '(font-latex-sectioning-3-face ((t (:inherit org-level-3))))
   '(font-latex-string-face ((t (:inherit font-lock-string-face))))
   '(font-latex-bold-face ((t (:inherit bold))))

   ;; CSS
   '(css-selector ((t (:inherit font-lock-keyword-face))))
   ;; '(css-property ((t (:inherit font-lock-keyword-face))))


   ;; XML
   `(nxml-element-local-name ((t (:foreground ,kosmos-fg-dim))))
   `(nxml-tag-delimiter ((t (:foreground ,kosmos-fg-dim))))
   `(nxml-namespace-attribute-xmlns ((t (:foreground ,kosmos-fg-dim))))
   `(nxml-attribute-local-name ((t (:foreground ,kosmos-fg-dim))))
   `(nxml-attribute-value ((t (:foreground ,kosmos-str))))
   `(nxml-cdata-section-CDATA ((t (:foreground ,kosmos-fg-dim))))
   `(nxml-cdata-section-content ((t (:foreground ,kosmos-fg))))
   `(nxml-cdata-section-delimiter ((t (:foreground ,kosmos-fg-dim-2))))


   ;; whitespace-mode
   `(whitespace-space ((t (:foreground ,kosmos-fg-whitespace))))
   `(whitespace-newline ((t (:foreground ,kosmos-fg-whitespace))))
   `(whitespace-indentation ((t (:foreground ,kosmos-fg-whitespace :background ,kosmos-bg-whitespace))))
   `(whitespace-line ((nil (:background ,kosmos-bg-whitespace))))


   ;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,kosmos-fg))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground "#bd7070"))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground "#bdbd70"))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground "#7070bd"))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground "#bd70bd"))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground "#70bdbd"))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground "#bda090"))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground "#90a0bd"))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground "#a0bd90"))))


   ;; asciidoctor-mode
   `(asciidoctor-header-delimiter-face ((t (:foreground ,kosmos-fg-dim))))

   `(asciidoctor-header-face-1 ((t (:foreground ,kosmos-title :weight bold :height 1.3))))
   `(asciidoctor-header-face-2 ((t (:foreground ,kosmos-heading :weight bold :height 1.3))))
   `(asciidoctor-header-face-3 ((t (:foreground ,kosmos-heading :weight bold :height 1.2))))
   `(asciidoctor-header-face-4 ((t (:foreground ,kosmos-heading :weight bold :height 1.1))))
   `(asciidoctor-header-face-5 ((t (:foreground ,kosmos-heading :slant italic :height 1.1))))
   `(asciidoctor-header-face-6 ((t (:foreground ,kosmos-heading :slant italic :height 1.1))))

   `(asciidoctor-option-face ((t (:foreground ,kosmos-fg-dim))))
   `(asciidoctor-option-markup-face ((t (:foreground ,kosmos-fg-dim))))


   `(bongo-comment ((t (:foreground ,kosmos-fg-dim))))
   `(bongo-elapsed-track-part ((t (:background ,kosmos-bg-alt))))
   `(bongo-currently-playing-track ((t (:slant italic))))

   )
  )

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'kosmos)

;;; kosmos-theme.el ends here
