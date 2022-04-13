;;; vampyricdark-theme.el --- VampyricDark Theme

;; Code licensed under the MIT license

;; Version: 1.0.1
;; Package-Version: 20220405.2235
;; Package-Commit: 7b9ac67efd38466765b85b1dd131d6b64d8f71f9
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/VampyricDark/emacs

;;; Commentary:

;; The GNU Emacs Vampyric Dark theme is based on the Dracula theme for Emacs.
;; The original Dracula theme for Emacs can be found on https://github.com/dracula/emacs

;;; Code:
(deftheme vampyricdark)

;;;; Configuration options:

(defgroup vampyricdark nil
  "vampyricdark theme options.

The theme has to be reloaded after changing anything in this group."
  :group 'faces)

(defcustom vampyricdark-enlarge-headings t
  "Use different font sizes for some headings and titles."
  :type 'boolean
  :group 'vampyricdark)

(defcustom vampyricdark-height-title-1 1.3
  "Font size 100%."
  :type 'number
  :group 'vampyricdark)

(defcustom vampyricdark-height-title-2 1.1
  "Font size 110%."
  :type 'number
  :group 'vampyricdark)

(defcustom vampyricdark-height-title-3 1.0
  "Font size 130%."
  :type 'number
  :group 'vampyricdark)

(defcustom vampyricdark-height-doc-title 1.44
  "Font size 144%."
  :type 'number
  :group 'vampyricdark)

(defcustom vampyricdark-alternate-mode-line-and-minibuffer nil
  "Use less bold and pink in the minibuffer."
  :type 'boolean
  :group 'vampyricdark)

(defvar vampyricdark-use-24-bit-colors-on-256-colors-terms nil)

;;;; Theme definition:

;; Assigment form: VARIABLE COLOR [256-COLOR [TTY-COLOR]]
(let ((colors '(;; Upstream theme color
                (vampyricdark-bg      "#18191f" "unspecified-bg" "unspecified-bg") ; official background
                (vampyricdark-fg      "#f8f8f2" "#f8f8f2" "brightwhite") ; official foreground
                (vampyricdark-current "#383a59" "#525473" "brightblack") ; official current-line/selection
                (vampyricdark-comment "#3b3c4a" "#6E6F7D" "blue")        ; official comment
                (vampyricdark-cyan    "#54a7f0" "#87DAFF" "brightcyan")  ; official cyan
                (vampyricdark-green   "#59de47" "#73F861" "green")       ; official green
                (vampyricdark-orange  "#ffb86c" "#ffd286" "brightred")   ; official orange
                (vampyricdark-pink    "#ff59c5" "#ff8cf8" "magenta")     ; official pink
                (vampyricdark-purple  "#6550eb" "#af87ff" "brightmagenta") ; official purple
                (vampyricdark-red     "#e04848" "#ff8787" "red")         ; official red
                (vampyricdark-yellow  "#f1fa8c" "#ffff87" "yellow")      ; official yellow
                ;; Other colors
                (bg2             "#373844" "#121212" "brightblack")
                (bg3             "#464752" "#262626" "brightblack")
                (bg4             "#565761" "#444444" "brightblack")
                (fg2             "#e2e2dc" "#e4e4e4" "brightwhite")
                (fg3             "#ccccc7" "#c6c6c6" "white")
                (fg4             "#b6b6b2" "#b2b2b2" "white")
                (other-blue      "#4e72e6" "#3559CD" "brightblue")))
      (faces '(;; default / basic faces
               (cursor :background ,fg3)
               (default :background ,vampyricdark-bg :foreground ,vampyricdark-fg)
               (default-italic :slant italic)
               (error :foreground ,vampyricdark-red)
               (ffap :foreground ,fg4)
               (fringe :background ,vampyricdark-bg :foreground ,fg4)
               (header-line :background ,vampyricdark-bg)
               (highlight :foreground ,fg3 :background ,bg3)
               (hl-line :background ,vampyricdark-current :extend t)
               (info-quoted-name :foreground ,vampyricdark-orange)
               (info-string :foreground ,vampyricdark-yellow)
               (lazy-highlight :foreground ,fg2 :background ,bg2)
               (link :foreground ,vampyricdark-cyan :underline t)
               (linum :slant italic :foreground ,bg4 :background ,vampyricdark-bg)
               (line-number :slant italic :foreground ,bg4 :background ,vampyricdark-bg)
               (match :background ,vampyricdark-yellow :foreground ,vampyricdark-bg)
               (menu :background ,vampyricdark-current :inverse-video nil
                     ,@(if vampyricdark-alternate-mode-line-and-minibuffer
                           (list :foreground fg3)
                         (list :foreground vampyricdark-fg)))
               (minibuffer-prompt
                ,@(if vampyricdark-alternate-mode-line-and-minibuffer
                      (list :weight 'normal :foreground vampyricdark-fg)
                    (list :weight 'bold :foreground vampyricdark-pink)))
               (read-multiple-choice-face :inherit completions-first-difference)
               (region :inherit match :extend t)
               (shadow :foreground ,vampyricdark-comment)
               (success :foreground ,vampyricdark-green)
               (tooltip :foreground ,vampyricdark-fg :background ,vampyricdark-current)
               (trailing-whitespace :background ,vampyricdark-orange)
               (vertical-border :foreground ,bg2)
               (warning :foreground ,vampyricdark-orange)
               ;; syntax / font-lock
               (font-lock-builtin-face :foreground ,vampyricdark-cyan :slant italic)
               (font-lock-comment-face :inherit shadow)
               (font-lock-comment-delimiter-face :inherit shadow)
               (font-lock-constant-face :foreground ,vampyricdark-purple)
               (font-lock-doc-face :foreground ,vampyricdark-comment)
               (font-lock-function-name-face :foreground ,vampyricdark-green :weight bold)
               (font-lock-keyword-face :foreground ,vampyricdark-pink :weight bold)
               (font-lock-negation-char-face :foreground ,vampyricdark-cyan)
               (font-lock-preprocessor-face :foreground ,vampyricdark-orange)
               (font-lock-reference-face :inherit font-lock-constant-face) ;; obsolete
               (font-lock-regexp-grouping-backslash :foreground ,vampyricdark-cyan)
               (font-lock-regexp-grouping-construct :foreground ,vampyricdark-purple)
               (font-lock-string-face :foreground ,vampyricdark-yellow)
               (font-lock-type-face :inherit font-lock-builtin-face)
               (font-lock-variable-name-face :foreground ,vampyricdark-fg :weight bold)
               (font-lock-warning-face :inherit warning :background ,bg2)
               ;; auto-complete
               (ac-completion-face :underline t :foreground ,vampyricdark-pink)
               ;; company
               (company-echo-common :foreground ,vampyricdark-bg :background ,vampyricdark-fg)
               (company-preview :background ,vampyricdark-current :foreground ,other-blue)
               (company-preview-common :inherit company-preview
                                       :foreground ,vampyricdark-pink)
               (company-preview-search :inherit company-preview
                                       :foreground ,vampyricdark-green)
               (company-scrollbar-bg :background ,vampyricdark-comment)
               (company-scrollbar-fg :foreground ,other-blue)
               (company-tooltip :inherit tooltip)
               (company-tooltip-search :foreground ,vampyricdark-green
                                       :underline t)
               (company-tooltip-search-selection :background ,vampyricdark-green
                                                 :foreground ,vampyricdark-bg)
               (company-tooltip-selection :inherit match)
               (company-tooltip-mouse :background ,vampyricdark-bg)
               (company-tooltip-common :foreground ,vampyricdark-pink :weight bold)
               ;;(company-tooltip-common-selection :inherit company-tooltip-common)
               (company-tooltip-annotation :foreground ,vampyricdark-cyan)
               ;;(company-tooltip-annotation-selection :inherit company-tooltip-annotation)
               ;; completions (minibuffer.el)
               (completions-annotations :inherit font-lock-comment-face)
               (completions-common-part :foreground ,vampyricdark-green)
               (completions-first-difference :foreground ,vampyricdark-pink :weight bold)
               ;; diff-hl
               (diff-hl-change :foreground ,vampyricdark-orange :background ,vampyricdark-orange)
               (diff-hl-delete :foreground ,vampyricdark-red :background ,vampyricdark-red)
               (diff-hl-insert :foreground ,vampyricdark-green :background ,vampyricdark-green)
               ;; dired
               (dired-directory :foreground ,vampyricdark-green :weight normal)
               (dired-flagged :foreground ,vampyricdark-pink)
               (dired-header :foreground ,fg3 :background ,vampyricdark-bg)
               (dired-ignored :inherit shadow)
               (dired-mark :foreground ,vampyricdark-fg :weight bold)
               (dired-marked :foreground ,vampyricdark-orange :weight bold)
               (dired-perm-write :foreground ,fg3 :underline t)
               (dired-symlink :foreground ,vampyricdark-yellow :weight normal :slant italic)
               (dired-warning :foreground ,vampyricdark-orange :underline t)
               (diredp-compressed-file-name :foreground ,fg3)
               (diredp-compressed-file-suffix :foreground ,fg4)
               (diredp-date-time :foreground ,vampyricdark-fg)
               (diredp-deletion-file-name :foreground ,vampyricdark-pink :background ,vampyricdark-current)
               (diredp-deletion :foreground ,vampyricdark-pink :weight bold)
               (diredp-dir-heading :foreground ,fg2 :background ,bg4)
               (diredp-dir-name :inherit dired-directory)
               (diredp-dir-priv :inherit dired-directory)
               (diredp-executable-tag :foreground ,vampyricdark-orange)
               (diredp-file-name :foreground ,vampyricdark-fg)
               (diredp-file-suffix :foreground ,fg4)
               (diredp-flag-mark-line :foreground ,fg2 :slant italic :background ,vampyricdark-current)
               (diredp-flag-mark :foreground ,fg2 :weight bold :background ,vampyricdark-current)
               (diredp-ignored-file-name :foreground ,vampyricdark-fg)
               (diredp-mode-line-flagged :foreground ,vampyricdark-orange)
               (diredp-mode-line-marked :foreground ,vampyricdark-orange)
               (diredp-no-priv :foreground ,vampyricdark-fg)
               (diredp-number :foreground ,vampyricdark-cyan)
               (diredp-other-priv :foreground ,vampyricdark-orange)
               (diredp-rare-priv :foreground ,vampyricdark-orange)
               (diredp-read-priv :foreground ,vampyricdark-purple)
               (diredp-write-priv :foreground ,vampyricdark-pink)
               (diredp-exec-priv :foreground ,vampyricdark-yellow)
               (diredp-symlink :foreground ,vampyricdark-orange)
               (diredp-link-priv :foreground ,vampyricdark-orange)
               (diredp-autofile-name :foreground ,vampyricdark-yellow)
               (diredp-tagged-autofile-name :foreground ,vampyricdark-yellow)
               ;; elfeed
               (elfeed-search-date-face :foreground ,vampyricdark-comment)
               (elfeed-search-title-face :foreground ,vampyricdark-fg)
               (elfeed-search-unread-title-face :foreground ,vampyricdark-pink :weight bold)
               (elfeed-search-feed-face :foreground ,vampyricdark-fg :weight bold)
               (elfeed-search-tag-face :foreground ,vampyricdark-green)
               (elfeed-search-last-update-face :weight bold)
               (elfeed-search-unread-count-face :foreground ,vampyricdark-pink)
               (elfeed-search-filter-face :foreground ,vampyricdark-green :weight bold)
               ;;(elfeed-log-date-face :inherit font-lock-type-face)
               (elfeed-log-error-level-face :foreground ,vampyricdark-red)
               (elfeed-log-warn-level-face :foreground ,vampyricdark-orange)
               (elfeed-log-info-level-face :foreground ,vampyricdark-cyan)
               (elfeed-log-debug-level-face :foreground ,vampyricdark-comment)
               ;; elpher
               (elpher-gemini-heading1 :inherit bold :foreground ,vampyricdark-pink
                                       ,@(when vampyricdark-enlarge-headings
                                           (list :height vampyricdark-height-title-1)))
               (elpher-gemini-heading2 :inherit bold :foreground ,vampyricdark-purple
                                       ,@(when vampyricdark-enlarge-headings
                                           (list :height vampyricdark-height-title-2)))
               (elpher-gemini-heading3 :weight normal :foreground ,vampyricdark-green
                                       ,@(when vampyricdark-enlarge-headings
                                           (list :height vampyricdark-height-title-3)))
               (elpher-gemini-preformatted :inherit fixed-pitch
                                           :foreground ,vampyricdark-orange)
               ;; enh-ruby
               (enh-ruby-heredoc-delimiter-face :foreground ,vampyricdark-yellow)
               (enh-ruby-op-face :foreground ,vampyricdark-pink)
               (enh-ruby-regexp-delimiter-face :foreground ,vampyricdark-yellow)
               (enh-ruby-string-delimiter-face :foreground ,vampyricdark-yellow)
               ;; flyspell
               (flyspell-duplicate :underline (:style wave :color ,vampyricdark-orange))
               (flyspell-incorrect :underline (:style wave :color ,vampyricdark-red))
               ;; font-latex
               (font-latex-bold-face :foreground ,vampyricdark-purple)
               (font-latex-italic-face :foreground ,vampyricdark-pink :slant italic)
               (font-latex-match-reference-keywords :foreground ,vampyricdark-cyan)
               (font-latex-match-variable-keywords :foreground ,vampyricdark-fg)
               (font-latex-string-face :foreground ,vampyricdark-yellow)
               ;; gemini
               (gemini-heading-face-1 :inherit bold :foreground ,vampyricdark-pink
                                      ,@(when vampyricdark-enlarge-headings
                                          (list :height vampyricdark-height-title-1)))
               (gemini-heading-face-2 :inherit bold :foreground ,vampyricdark-purple
                                      ,@(when vampyricdark-enlarge-headings
                                          (list :height vampyricdark-height-title-2)))
               (gemini-heading-face-3 :weight normal :foreground ,vampyricdark-green
                                      ,@(when vampyricdark-enlarge-headings
                                          (list :height vampyricdark-height-title-3)))
               (gemini-heading-face-rest :weight normal :foreground ,vampyricdark-yellow)
               (gemini-quote-face :foreground ,vampyricdark-purple)
               ;; go-test
               (go-test--ok-face :inherit success)
               (go-test--error-face :inherit error)
               (go-test--warning-face :inherit warning)
               (go-test--pointer-face :foreground ,vampyricdark-pink)
               (go-test--standard-face :foreground ,vampyricdark-cyan)
               ;; gnus-group
               (gnus-group-mail-1 :foreground ,vampyricdark-pink :weight bold)
               (gnus-group-mail-1-empty :inherit gnus-group-mail-1 :weight normal)
               (gnus-group-mail-2 :foreground ,vampyricdark-cyan :weight bold)
               (gnus-group-mail-2-empty :inherit gnus-group-mail-2 :weight normal)
               (gnus-group-mail-3 :foreground ,vampyricdark-comment :weight bold)
               (gnus-group-mail-3-empty :inherit gnus-group-mail-3 :weight normal)
               (gnus-group-mail-low :foreground ,vampyricdark-current :weight bold)
               (gnus-group-mail-low-empty :inherit gnus-group-mail-low :weight normal)
               (gnus-group-news-1 :foreground ,vampyricdark-pink :weight bold)
               (gnus-group-news-1-empty :inherit gnus-group-news-1 :weight normal)
               (gnus-group-news-2 :foreground ,vampyricdark-cyan :weight bold)
               (gnus-group-news-2-empty :inherit gnus-group-news-2 :weight normal)
               (gnus-group-news-3 :foreground ,vampyricdark-comment :weight bold)
               (gnus-group-news-3-empty :inherit gnus-group-news-3 :weight normal)
               (gnus-group-news-4 :inherit gnus-group-news-low)
               (gnus-group-news-4-empty :inherit gnus-group-news-low-empty)
               (gnus-group-news-5 :inherit gnus-group-news-low)
               (gnus-group-news-5-empty :inherit gnus-group-news-low-empty)
               (gnus-group-news-6 :inherit gnus-group-news-low)
               (gnus-group-news-6-empty :inherit gnus-group-news-low-empty)
               (gnus-group-news-low :foreground ,vampyricdark-current :weight bold)
               (gnus-group-news-low-empty :inherit gnus-group-news-low :weight normal)
               (gnus-header-content :foreground ,vampyricdark-purple)
               (gnus-header-from :foreground ,vampyricdark-fg)
               (gnus-header-name :foreground ,vampyricdark-green)
               (gnus-header-subject :foreground ,vampyricdark-pink :weight bold)
               (gnus-summary-markup-face :foreground ,vampyricdark-cyan)
               (gnus-summary-high-unread :foreground ,vampyricdark-pink :weight bold)
               (gnus-summary-high-read :inherit gnus-summary-high-unread :weight normal)
               (gnus-summary-high-ancient :inherit gnus-summary-high-read)
               (gnus-summary-high-ticked :inherit gnus-summary-high-read :underline t)
               (gnus-summary-normal-unread :foreground ,other-blue :weight bold)
               (gnus-summary-normal-read :foreground ,vampyricdark-comment :weight normal)
               (gnus-summary-normal-ancient :inherit gnus-summary-normal-read :weight light)
               (gnus-summary-normal-ticked :foreground ,vampyricdark-pink :weight bold)
               (gnus-summary-low-unread :foreground ,vampyricdark-comment :weight bold)
               (gnus-summary-low-read :inherit gnus-summary-low-unread :weight normal)
               (gnus-summary-low-ancient :inherit gnus-summary-low-read)
               (gnus-summary-low-ticked :inherit gnus-summary-low-read :underline t)
               (gnus-summary-selected :inverse-video t)
               ;; haskell-mode
               (haskell-operator-face :foreground ,vampyricdark-pink)
               (haskell-constructor-face :foreground ,vampyricdark-purple)
               ;; helm
               (helm-bookmark-w3m :foreground ,vampyricdark-purple)
               (helm-buffer-not-saved :foreground ,vampyricdark-purple :background ,vampyricdark-bg)
               (helm-buffer-process :foreground ,vampyricdark-orange :background ,vampyricdark-bg)
               (helm-buffer-saved-out :foreground ,vampyricdark-fg :background ,vampyricdark-bg)
               (helm-buffer-size :foreground ,vampyricdark-fg :background ,vampyricdark-bg)
               (helm-candidate-number :foreground ,vampyricdark-bg :background ,vampyricdark-fg)
               (helm-ff-directory :foreground ,vampyricdark-green :background ,vampyricdark-bg :weight bold)
               (helm-ff-dotted-directory :foreground ,vampyricdark-green :background ,vampyricdark-bg :weight normal)
               (helm-ff-executable :foreground ,other-blue :background ,vampyricdark-bg :weight normal)
               (helm-ff-file :foreground ,vampyricdark-fg :background ,vampyricdark-bg :weight normal)
               (helm-ff-invalid-symlink :foreground ,vampyricdark-pink :background ,vampyricdark-bg :weight bold)
               (helm-ff-prefix :foreground ,vampyricdark-bg :background ,vampyricdark-pink :weight normal)
               (helm-ff-symlink :foreground ,vampyricdark-pink :background ,vampyricdark-bg :weight bold)
               (helm-grep-cmd-line :foreground ,vampyricdark-fg :background ,vampyricdark-bg)
               (helm-grep-file :foreground ,vampyricdark-fg :background ,vampyricdark-bg)
               (helm-grep-finish :foreground ,fg2 :background ,vampyricdark-bg)
               (helm-grep-lineno :foreground ,vampyricdark-fg :background ,vampyricdark-bg)
               (helm-grep-match :inherit match)
               (helm-grep-running :foreground ,vampyricdark-green :background ,vampyricdark-bg)
               (helm-header :foreground ,fg2 :background ,vampyricdark-bg :underline nil :box nil)
               (helm-moccur-buffer :foreground ,vampyricdark-green :background ,vampyricdark-bg)
               (helm-selection :background ,bg2 :underline nil)
               (helm-selection-line :background ,bg2)
               (helm-separator :foreground ,vampyricdark-purple :background ,vampyricdark-bg)
               (helm-source-go-package-godoc-description :foreground ,vampyricdark-yellow)
               (helm-source-header :foreground ,vampyricdark-pink :background ,vampyricdark-bg :underline nil :weight bold)
               (helm-time-zone-current :foreground ,vampyricdark-orange :background ,vampyricdark-bg)
               (helm-time-zone-home :foreground ,vampyricdark-purple :background ,vampyricdark-bg)
               (helm-visible-mark :foreground ,vampyricdark-bg :background ,bg3)
               ;; highlight-indentation minor mode
               (highlight-indentation-face :background ,bg2)
               ;; icicle
               (icicle-whitespace-highlight :background ,vampyricdark-fg)
               (icicle-special-candidate :foreground ,fg2)
               (icicle-extra-candidate :foreground ,fg2)
               (icicle-search-main-regexp-others :foreground ,vampyricdark-fg)
               (icicle-search-current-input :foreground ,vampyricdark-pink)
               (icicle-search-context-level-8 :foreground ,vampyricdark-orange)
               (icicle-search-context-level-7 :foreground ,vampyricdark-orange)
               (icicle-search-context-level-6 :foreground ,vampyricdark-orange)
               (icicle-search-context-level-5 :foreground ,vampyricdark-orange)
               (icicle-search-context-level-4 :foreground ,vampyricdark-orange)
               (icicle-search-context-level-3 :foreground ,vampyricdark-orange)
               (icicle-search-context-level-2 :foreground ,vampyricdark-orange)
               (icicle-search-context-level-1 :foreground ,vampyricdark-orange)
               (icicle-search-main-regexp-current :foreground ,vampyricdark-fg)
               (icicle-saved-candidate :foreground ,vampyricdark-fg)
               (icicle-proxy-candidate :foreground ,vampyricdark-fg)
               (icicle-mustmatch-completion :foreground ,vampyricdark-purple)
               (icicle-multi-command-completion :foreground ,fg2 :background ,bg2)
               (icicle-msg-emphasis :foreground ,vampyricdark-green)
               (icicle-mode-line-help :foreground ,fg4)
               (icicle-match-highlight-minibuffer :foreground ,vampyricdark-orange)
               (icicle-match-highlight-Completions :foreground ,vampyricdark-green)
               (icicle-key-complete-menu-local :foreground ,vampyricdark-fg)
               (icicle-key-complete-menu :foreground ,vampyricdark-fg)
               (icicle-input-completion-fail-lax :foreground ,vampyricdark-pink)
               (icicle-input-completion-fail :foreground ,vampyricdark-pink)
               (icicle-historical-candidate-other :foreground ,vampyricdark-fg)
               (icicle-historical-candidate :foreground ,vampyricdark-fg)
               (icicle-current-candidate-highlight :foreground ,vampyricdark-orange :background ,bg3)
               (icicle-Completions-instruction-2 :foreground ,fg4)
               (icicle-Completions-instruction-1 :foreground ,fg4)
               (icicle-completion :foreground ,vampyricdark-fg)
               (icicle-complete-input :foreground ,vampyricdark-orange)
               (icicle-common-match-highlight-Completions :foreground ,vampyricdark-purple)
               (icicle-candidate-part :foreground ,vampyricdark-fg)
               (icicle-annotation :foreground ,fg4)
               ;; icomplete
               (icompletep-determined :foreground ,vampyricdark-orange)
               ;; ido
               (ido-first-match
                ,@(if vampyricdark-alternate-mode-line-and-minibuffer
                      (list :weight 'normal :foreground vampyricdark-green)
                    (list :weight 'bold :foreground vampyricdark-pink)))
               (ido-only-match :foreground ,vampyricdark-orange)
               (ido-subdir :foreground ,vampyricdark-yellow)
               (ido-virtual :foreground ,vampyricdark-cyan)
               (ido-incomplete-regexp :inherit font-lock-warning-face)
               (ido-indicator :foreground ,vampyricdark-fg :background ,vampyricdark-pink)
               ;; ivy
               (ivy-current-match
                ,@(if vampyricdark-alternate-mode-line-and-minibuffer
                      (list :weight 'normal :background vampyricdark-current :foreground vampyricdark-green)
                    (list :weight 'bold :background vampyricdark-current :foreground vampyricdark-pink)))
               ;; Highlights the background of the match.
               (ivy-minibuffer-match-face-1 :background ,vampyricdark-current)
               ;; Highlights the first matched group.
               (ivy-minibuffer-match-face-2 :background ,vampyricdark-green
                                            :foreground ,vampyricdark-bg)
               ;; Highlights the second matched group.
               (ivy-minibuffer-match-face-3 :background ,vampyricdark-yellow
                                            :foreground ,vampyricdark-bg)
               ;; Highlights the third matched group.
               (ivy-minibuffer-match-face-4 :background ,vampyricdark-pink
                                            :foreground ,vampyricdark-bg)
               (ivy-confirm-face :foreground ,vampyricdark-orange)
               (ivy-match-required-face :foreground ,vampyricdark-red)
               (ivy-subdir :foreground ,vampyricdark-yellow)
               (ivy-remote :foreground ,vampyricdark-pink)
               (ivy-virtual :foreground ,vampyricdark-cyan)
               ;; isearch
               (isearch :inherit match :weight bold)
               (isearch-fail :foreground ,vampyricdark-bg :background ,vampyricdark-orange)
               ;; jde-java
               (jde-java-font-lock-constant-face :foreground ,vampyricdark-cyan)
               (jde-java-font-lock-modifier-face :foreground ,vampyricdark-pink)
               (jde-java-font-lock-number-face :foreground ,vampyricdark-fg)
               (jde-java-font-lock-package-face :foreground ,vampyricdark-fg)
               (jde-java-font-lock-private-face :foreground ,vampyricdark-pink)
               (jde-java-font-lock-public-face :foreground ,vampyricdark-pink)
               ;; js2-mode
               (js2-external-variable :foreground ,vampyricdark-purple)
               (js2-function-param :foreground ,vampyricdark-cyan)
               (js2-jsdoc-html-tag-delimiter :foreground ,vampyricdark-yellow)
               (js2-jsdoc-html-tag-name :foreground ,other-blue)
               (js2-jsdoc-value :foreground ,vampyricdark-yellow)
               (js2-private-function-call :foreground ,vampyricdark-cyan)
               (js2-private-member :foreground ,fg3)
               ;; js3-mode
               (js3-error-face :underline ,vampyricdark-orange)
               (js3-external-variable-face :foreground ,vampyricdark-fg)
               (js3-function-param-face :foreground ,vampyricdark-pink)
               (js3-instance-member-face :foreground ,vampyricdark-cyan)
               (js3-jsdoc-tag-face :foreground ,vampyricdark-pink)
               (js3-warning-face :underline ,vampyricdark-pink)
               ;; lsp
               (lsp-ui-peek-peek :background ,vampyricdark-bg)
               (lsp-ui-peek-list :background ,bg2)
               (lsp-ui-peek-filename :foreground ,vampyricdark-pink :weight bold)
               (lsp-ui-peek-line-number :foreground ,vampyricdark-fg)
               (lsp-ui-peek-highlight :inherit highlight :distant-foreground ,vampyricdark-bg)
               (lsp-ui-peek-header :background ,bg3 :foreground ,fg3, :weight bold)
               (lsp-ui-peek-footer :inherit lsp-ui-peek-header)
               (lsp-ui-peek-selection :inherit match)
               (lsp-ui-sideline-symbol :foreground ,fg4 :box (:line-width -1 :color ,fg4) :height 0.99)
               (lsp-ui-sideline-current-symbol :foreground ,vampyricdark-fg :weight ultra-bold
                                               :box (:line-width -1 :color vampyricdark-fg) :height 0.99)
               (lsp-ui-sideline-code-action :foreground ,vampyricdark-yellow)
               (lsp-ui-sideline-symbol-info :slant italic :height 0.99)
               (lsp-ui-doc-background :background ,vampyricdark-bg)
               (lsp-ui-doc-header :foreground ,vampyricdark-bg :background ,vampyricdark-cyan)
               ;; magit
               (magit-branch-local :foreground ,vampyricdark-cyan)
               (magit-branch-remote :foreground ,vampyricdark-green)
               (magit-tag :foreground ,vampyricdark-orange)
               (magit-section-heading :foreground ,vampyricdark-pink :weight bold)
               (magit-section-highlight :background ,bg3 :extend t)
               (magit-diff-context-highlight :background ,bg3
                                             :foreground ,fg3
                                             :extend t)
               (magit-diff-revision-summary :foreground ,vampyricdark-orange
                                            :background ,vampyricdark-bg
                                            :weight bold)
               (magit-diff-revision-summary-highlight :foreground ,vampyricdark-orange
                                                      :background ,bg3
                                                      :weight bold
                                                      :extend t)
               ;; the four following lines are just a patch of the
               ;; upstream color to add the extend keyword.
               (magit-diff-added :background "#335533"
                                 :foreground "#ddffdd"
                                 :extend t)
               (magit-diff-added-highlight :background "#336633"
                                           :foreground "#cceecc"
                                           :extend t)
               (magit-diff-removed :background "#553333"
                                   :foreground "#ffdddd"
                                   :extend t)
               (magit-diff-removed-highlight :background "#663333"
                                             :foreground "#eecccc"
                                             :extend t)
               (magit-diff-file-heading :foreground ,vampyricdark-fg)
               (magit-diff-file-heading-highlight :inherit magit-section-highlight)
               (magit-diffstat-added :foreground ,vampyricdark-green)
               (magit-diffstat-removed :foreground ,vampyricdark-red)
               (magit-hash :foreground ,fg2)
               (magit-hunk-heading :background ,bg3)
               (magit-hunk-heading-highlight :background ,bg3)
               (magit-item-highlight :background ,bg3)
               (magit-log-author :foreground ,fg3)
               (magit-process-ng :foreground ,vampyricdark-orange :weight bold)
               (magit-process-ok :foreground ,vampyricdark-green :weight bold)
               ;; markdown
               (markdown-blockquote-face :foreground ,vampyricdark-yellow
                                         :slant italic)
               (markdown-code-face :foreground ,vampyricdark-orange)
               (markdown-footnote-face :foreground ,other-blue)
               (markdown-header-face :weight normal)
               (markdown-header-face-1
                :inherit bold :foreground ,vampyricdark-pink
                ,@(when vampyricdark-enlarge-headings
                    (list :height vampyricdark-height-title-1)))
               (markdown-header-face-2
                :inherit bold :foreground ,vampyricdark-purple
                ,@(when vampyricdark-enlarge-headings
                    (list :height vampyricdark-height-title-2)))
               (markdown-header-face-3
                :foreground ,vampyricdark-green
                ,@(when vampyricdark-enlarge-headings
                    (list :height vampyricdark-height-title-3)))
               (markdown-header-face-4 :foreground ,vampyricdark-yellow)
               (markdown-header-face-5 :foreground ,vampyricdark-cyan)
               (markdown-header-face-6 :foreground ,vampyricdark-orange)
               (markdown-header-face-7 :foreground ,other-blue)
               (markdown-header-face-8 :foreground ,vampyricdark-fg)
               (markdown-inline-code-face :foreground ,vampyricdark-green)
               (markdown-plain-url-face :inherit link)
               (markdown-pre-face :foreground ,vampyricdark-orange)
               (markdown-table-face :foreground ,vampyricdark-purple)
               (markdown-list-face :foreground ,vampyricdark-cyan)
               (markdown-language-keyword-face :foreground ,vampyricdark-comment)
               ;; message
               (message-header-to :foreground ,vampyricdark-fg :weight bold)
               (message-header-cc :foreground ,vampyricdark-fg :bold bold)
               (message-header-subject :foreground ,vampyricdark-orange)
               (message-header-newsgroups :foreground ,vampyricdark-purple)
               (message-header-other :foreground ,vampyricdark-purple)
               (message-header-name :foreground ,vampyricdark-green)
               (message-header-xheader :foreground ,vampyricdark-cyan)
               (message-separator :foreground ,vampyricdark-cyan :slant italic)
               (message-cited-text :foreground ,vampyricdark-purple)
               (message-cited-text-1 :foreground ,vampyricdark-purple)
               (message-cited-text-2 :foreground ,vampyricdark-orange)
               (message-cited-text-3 :foreground ,vampyricdark-comment)
               (message-cited-text-4 :foreground ,fg2)
               (message-mml :foreground ,vampyricdark-green :weight normal)
               ;; mode-line
               (mode-line :background ,vampyricdark-current
                          :box ,vampyricdark-current :inverse-video nil
                          ,@(if vampyricdark-alternate-mode-line-and-minibuffer
                                (list :foreground fg3)
                              (list :foreground vampyricdark-fg)))
               (mode-line-inactive
                :background ,vampyricdark-bg :inverse-video nil
                ,@(if vampyricdark-alternate-mode-line-and-minibuffer
                      (list :foreground vampyricdark-comment :box vampyricdark-bg)
                    (list :foreground fg4 :box bg2)))
               (mini-modeline-mode-line :inherit mode-line :height 0.1 :box nil)
               ;; mu4e
               (mu4e-unread-face :foreground ,vampyricdark-pink :weight normal)
               (mu4e-view-url-number-face :foreground ,vampyricdark-purple)
               (mu4e-highlight-face :background ,vampyricdark-bg
                                    :foreground ,vampyricdark-yellow
                                    :extend t)
               (mu4e-header-highlight-face :background ,vampyricdark-current
                                           :foreground ,vampyricdark-fg
                                           :underline nil :weight bold
                                           :extend t)
               (mu4e-header-key-face :inherit message-mml)
               (mu4e-header-marks-face :foreground ,vampyricdark-purple)
               (mu4e-cited-1-face :foreground ,vampyricdark-purple)
               (mu4e-cited-2-face :foreground ,vampyricdark-orange)
               (mu4e-cited-3-face :foreground ,vampyricdark-comment)
               (mu4e-cited-4-face :foreground ,fg2)
               (mu4e-cited-5-face :foreground ,fg3)
               ;; neotree
               (neo-banner-face :foreground ,vampyricdark-orange :weight bold)
               ;;(neo-button-face :underline nil)
               (neo-dir-link-face :foreground ,vampyricdark-purple)
               (neo-expand-btn-face :foreground ,vampyricdark-fg)
               (neo-file-link-face :foreground ,vampyricdark-cyan)
               (neo-header-face :background ,vampyricdark-bg
                                :foreground ,vampyricdark-fg
                                :weight bold)
               (neo-root-dir-face :foreground ,vampyricdark-purple :weight bold)
               (neo-vc-added-face :foreground ,vampyricdark-orange)
               (neo-vc-conflict-face :foreground ,vampyricdark-red)
               (neo-vc-default-face :inherit neo-file-link-face)
               (neo-vc-edited-face :foreground ,vampyricdark-orange)
               (neo-vc-ignored-face :foreground ,vampyricdark-comment)
               (neo-vc-missing-face :foreground ,vampyricdark-red)
               (neo-vc-needs-merge-face :foreground ,vampyricdark-red
                                        :weight bold)
               ;;(neo-vc-needs-update-face :underline t)
               ;;(neo-vc-removed-face :strike-through t)
               (neo-vc-unlocked-changes-face :foreground ,vampyricdark-red)
               ;;(neo-vc-unregistered-face nil)
               (neo-vc-up-to-date-face :foreground ,vampyricdark-green)
               (neo-vc-user-face :foreground ,vampyricdark-purple)
               ;; org
               (org-agenda-date :foreground ,vampyricdark-cyan :underline nil)
               (org-agenda-dimmed-todo-face :foreground ,vampyricdark-comment)
               (org-agenda-done :foreground ,vampyricdark-green)
               (org-agenda-structure :foreground ,vampyricdark-purple)
               (org-block :foreground ,vampyricdark-orange)
               (org-code :foreground ,vampyricdark-green)
               (org-column :background ,bg4)
               (org-column-title :inherit org-column :weight bold :underline t)
               (org-date :foreground ,vampyricdark-cyan :underline t)
               (org-document-info :foreground ,other-blue)
               (org-document-info-keyword :foreground ,vampyricdark-comment)
               (org-document-title :weight bold :foreground ,vampyricdark-orange
                                   ,@(when vampyricdark-enlarge-headings
                                       (list :height vampyricdark-height-doc-title)))
               (org-done :foreground ,vampyricdark-green)
               (org-ellipsis :foreground ,vampyricdark-comment)
               (org-footnote :foreground ,other-blue)
               (org-formula :foreground ,vampyricdark-pink)
               (org-headline-done :foreground ,vampyricdark-comment
                                  :weight normal :strike-through t)
               (org-hide :foreground ,vampyricdark-bg :background ,vampyricdark-bg)
               (org-level-1 :inherit bold :foreground ,vampyricdark-pink
                            ,@(when vampyricdark-enlarge-headings
                                (list :height vampyricdark-height-title-1)))
               (org-level-2 :inherit bold :foreground ,vampyricdark-purple
                            ,@(when vampyricdark-enlarge-headings
                                (list :height vampyricdark-height-title-2)))
               (org-level-3 :weight normal :foreground ,vampyricdark-green
                            ,@(when vampyricdark-enlarge-headings
                                (list :height vampyricdark-height-title-3)))
               (org-level-4 :weight normal :foreground ,vampyricdark-yellow)
               (org-level-5 :weight normal :foreground ,vampyricdark-cyan)
               (org-level-6 :weight normal :foreground ,vampyricdark-orange)
               (org-level-7 :weight normal :foreground ,other-blue)
               (org-level-8 :weight normal :foreground ,vampyricdark-fg)
               (org-link :foreground ,vampyricdark-cyan :underline t)
               (org-priority :foreground ,vampyricdark-cyan)
               (org-quote :foreground ,vampyricdark-yellow :slant italic)
               (org-scheduled :foreground ,vampyricdark-green)
               (org-scheduled-previously :foreground ,vampyricdark-yellow)
               (org-scheduled-today :foreground ,vampyricdark-green)
               (org-sexp-date :foreground ,fg4)
               (org-special-keyword :foreground ,vampyricdark-yellow)
               (org-table :foreground ,vampyricdark-purple)
               (org-tag :foreground ,vampyricdark-pink :weight bold :background ,bg2)
               (org-todo :foreground ,vampyricdark-orange :weight bold :background ,bg2)
               (org-upcoming-deadline :foreground ,vampyricdark-yellow)
               (org-verbatim :inherit org-quote)
               (org-warning :weight bold :foreground ,vampyricdark-pink)
               ;; outline
               (outline-1 :foreground ,vampyricdark-pink)
               (outline-2 :foreground ,vampyricdark-purple)
               (outline-3 :foreground ,vampyricdark-green)
               (outline-4 :foreground ,vampyricdark-yellow)
               (outline-5 :foreground ,vampyricdark-cyan)
               (outline-6 :foreground ,vampyricdark-orange)
               ;; perspective
               (persp-selected-face :weight bold :foreground ,vampyricdark-pink)
               ;; powerline
               (powerline-active1 :background ,vampyricdark-bg :foreground ,vampyricdark-pink)
               (powerline-active2 :background ,vampyricdark-bg :foreground ,vampyricdark-pink)
               (powerline-inactive1 :background ,bg2 :foreground ,vampyricdark-purple)
               (powerline-inactive2 :background ,bg2 :foreground ,vampyricdark-purple)
               (powerline-evil-base-face :foreground ,bg2)
               (powerline-evil-emacs-face :inherit powerline-evil-base-face :background ,vampyricdark-yellow)
               (powerline-evil-insert-face :inherit powerline-evil-base-face :background ,vampyricdark-cyan)
               (powerline-evil-motion-face :inherit powerline-evil-base-face :background ,vampyricdark-purple)
               (powerline-evil-normal-face :inherit powerline-evil-base-face :background ,vampyricdark-green)
               (powerline-evil-operator-face :inherit powerline-evil-base-face :background ,vampyricdark-pink)
               (powerline-evil-replace-face :inherit powerline-evil-base-face :background ,vampyricdark-red)
               (powerline-evil-visual-face :inherit powerline-evil-base-face :background ,vampyricdark-orange)
               ;; rainbow-delimiters
               (rainbow-delimiters-depth-1-face :foreground ,vampyricdark-fg)
               (rainbow-delimiters-depth-2-face :foreground ,vampyricdark-cyan)
               (rainbow-delimiters-depth-3-face :foreground ,vampyricdark-purple)
               (rainbow-delimiters-depth-4-face :foreground ,vampyricdark-pink)
               (rainbow-delimiters-depth-5-face :foreground ,vampyricdark-orange)
               (rainbow-delimiters-depth-6-face :foreground ,vampyricdark-green)
               (rainbow-delimiters-depth-7-face :foreground ,vampyricdark-yellow)
               (rainbow-delimiters-depth-8-face :foreground ,other-blue)
               (rainbow-delimiters-unmatched-face :foreground ,vampyricdark-orange)
               ;; rpm-spec
               (rpm-spec-dir-face :foreground ,vampyricdark-green)
               (rpm-spec-doc-face :foreground ,vampyricdark-pink)
               (rpm-spec-ghost-face :foreground ,vampyricdark-purple)
               (rpm-spec-macro-face :foreground ,vampyricdark-yellow)
               (rpm-spec-obsolete-tag-face :inherit font-lock-warning-face)
               (rpm-spec-package-face :foreground ,vampyricdark-purple)
               (rpm-spec-section-face :foreground ,vampyricdark-yellow)
               (rpm-spec-tag-face :foreground ,vampyricdark-cyan)
               (rpm-spec-var-face :foreground ,vampyricdark-orange)
               ;; rst (reStructuredText)
               (rst-level-1 :foreground ,vampyricdark-pink :weight bold)
               (rst-level-2 :foreground ,vampyricdark-purple :weight bold)
               (rst-level-3 :foreground ,vampyricdark-green)
               (rst-level-4 :foreground ,vampyricdark-yellow)
               (rst-level-5 :foreground ,vampyricdark-cyan)
               (rst-level-6 :foreground ,vampyricdark-orange)
               (rst-level-7 :foreground ,other-blue)
               (rst-level-8 :foreground ,vampyricdark-fg)
               ;; selectrum-mode
               (selectrum-current-candidate :weight bold)
               (selectrum-primary-highlight :foreground ,vampyricdark-pink)
               (selectrum-secondary-highlight :foreground ,vampyricdark-green)
               ;; show-paren
               (show-paren-match-face :background unspecified
                                      :foreground ,vampyricdark-cyan
                                      :weight bold)
               (show-paren-match :background unspecified
                                 :foreground ,vampyricdark-cyan
                                 :weight bold)
               (show-paren-match-expression :inherit match)
               (show-paren-mismatch :inherit font-lock-warning-face)
               ;; slime
               (slime-repl-inputed-output-face :foreground ,vampyricdark-purple)
               ;; spam
               (spam :inherit gnus-summary-normal-read :foreground ,vampyricdark-orange
                     :strike-through t :slant oblique)
               ;; speedbar (and sr-speedbar)
               (speedbar-button-face :foreground ,vampyricdark-green)
               (speedbar-file-face :foreground ,vampyricdark-cyan)
               (speedbar-directory-face :foreground ,vampyricdark-purple)
               (speedbar-tag-face :foreground ,vampyricdark-yellow)
               (speedbar-selected-face :foreground ,vampyricdark-pink)
               (speedbar-highlight-face :inherit match)
               (speedbar-separator-face :background ,vampyricdark-bg
                                        :foreground ,vampyricdark-fg
                                        :weight bold)
               ;; tab-bar & tab-line (since Emacs 27.1)
               (tab-bar :foreground ,vampyricdark-purple :background ,vampyricdark-current
                        :inherit variable-pitch)
               (tab-bar-tab :foreground ,vampyricdark-pink :background ,vampyricdark-bg
                            :box (:line-width 2 :color ,vampyricdark-bg :style nil))
               (tab-bar-tab-inactive :foreground ,vampyricdark-purple :background ,bg2
                                     :box (:line-width 2 :color ,bg2 :style nil))
               (tab-line :foreground ,vampyricdark-purple :background ,vampyricdark-current
                         :height 0.9 :inherit variable-pitch)
               (tab-line-tab :foreground ,vampyricdark-pink :background ,vampyricdark-bg
                             :box (:line-width 2 :color ,vampyricdark-bg :style nil))
               (tab-line-tab-inactive :foreground ,vampyricdark-purple :background ,bg2
                                      :box (:line-width 2 :color ,bg2 :style nil))
               (tab-line-tab-current :inherit tab-line-tab)
               (tab-line-close-highlight :foreground ,vampyricdark-red)
               ;; telephone-line
               (telephone-line-accent-active :background ,vampyricdark-bg :foreground ,vampyricdark-pink)
               (telephone-line-accent-inactive :background ,bg2 :foreground ,vampyricdark-purple)
               (telephone-line-unimportant :background ,vampyricdark-bg :foreground ,vampyricdark-comment)
               ;; term
               (term :foreground ,vampyricdark-fg :background ,vampyricdark-bg)
               (term-color-black :foreground ,vampyricdark-bg :background ,vampyricdark-comment)
               (term-color-blue :foreground ,vampyricdark-purple :background ,vampyricdark-purple)
               (term-color-cyan :foreground ,vampyricdark-cyan :background ,vampyricdark-cyan)
               (term-color-green :foreground ,vampyricdark-green :background ,vampyricdark-green)
               (term-color-magenta :foreground ,vampyricdark-pink :background ,vampyricdark-pink)
               (term-color-red :foreground ,vampyricdark-red :background ,vampyricdark-red)
               (term-color-white :foreground ,vampyricdark-fg :background ,vampyricdark-fg)
               (term-color-yellow :foreground ,vampyricdark-yellow :background ,vampyricdark-yellow)
               ;; tree-sitter
               (tree-sitter-hl-face:attribute :inherit font-lock-constant-face)
               (tree-sitter-hl-face:comment :inherit font-lock-comment-face)
               (tree-sitter-hl-face:constant :inherit font-lock-constant-face)
               (tree-sitter-hl-face:constant.builtin :inherit font-lock-builtin-face)
               (tree-sitter-hl-face:constructor :inherit font-lock-constant-face)
               (tree-sitter-hl-face:escape :foreground ,vampyricdark-pink)
               (tree-sitter-hl-face:function :inherit font-lock-function-name-face)
               (tree-sitter-hl-face:function.builtin :inherit font-lock-builtin-face)
               (tree-sitter-hl-face:function.call :inherit font-lock-function-name-face
                                                  :weight normal)
               (tree-sitter-hl-face:function.macro :inherit font-lock-preprocessor-face)
               (tree-sitter-hl-face:function.special :inherit font-lock-preprocessor-face)
               (tree-sitter-hl-face:keyword :inherit font-lock-keyword-face)
               (tree-sitter-hl-face:punctuation :foreground ,vampyricdark-pink)
               (tree-sitter-hl-face:punctuation.bracket :foreground ,vampyricdark-fg)
               (tree-sitter-hl-face:punctuation.delimiter :foreground ,vampyricdark-fg)
               (tree-sitter-hl-face:punctuation.special :foreground ,vampyricdark-pink)
               (tree-sitter-hl-face:string :inherit font-lock-string-face)
               (tree-sitter-hl-face:string.special :foreground ,vampyricdark-red)
               (tree-sitter-hl-face:tag :inherit font-lock-keyword-face)
               (tree-sitter-hl-face:type :inherit font-lock-type-face)
               (tree-sitter-hl-face:type.parameter :foreground ,vampyricdark-pink)
               (tree-sitter-hl-face:variable :inherit font-lock-variable-name-face)
               (tree-sitter-hl-face:variable.parameter :inherit tree-sitter-hl-face:variable
                                                       :weight normal)
               ;; undo-tree
               (undo-tree-visualizer-current-face :foreground ,vampyricdark-orange)
               (undo-tree-visualizer-default-face :foreground ,fg2)
               (undo-tree-visualizer-register-face :foreground ,vampyricdark-purple)
               (undo-tree-visualizer-unmodified-face :foreground ,vampyricdark-fg)
               ;; web-mode
               (web-mode-builtin-face :inherit font-lock-builtin-face)
               (web-mode-comment-face :inherit font-lock-comment-face)
               (web-mode-constant-face :inherit font-lock-constant-face)
               (web-mode-css-property-name-face :inherit font-lock-constant-face)
               (web-mode-doctype-face :inherit font-lock-comment-face)
               (web-mode-function-name-face :inherit font-lock-function-name-face)
               (web-mode-html-attr-name-face :foreground ,vampyricdark-purple)
               (web-mode-html-attr-value-face :foreground ,vampyricdark-green)
               (web-mode-html-tag-face :foreground ,vampyricdark-pink :weight bold)
               (web-mode-keyword-face :foreground ,vampyricdark-pink)
               (web-mode-string-face :foreground ,vampyricdark-yellow)
               (web-mode-type-face :inherit font-lock-type-face)
               (web-mode-warning-face :inherit font-lock-warning-face)
               ;; which-func
               (which-func :inherit font-lock-function-name-face)
               ;; which-key
               (which-key-key-face :inherit font-lock-builtin-face)
               (which-key-command-description-face :inherit default)
               (which-key-separator-face :inherit font-lock-comment-delimiter-face)
               (which-key-local-map-description-face :foreground ,vampyricdark-green)
               ;; whitespace
               (whitespace-big-indent :background ,vampyricdark-red :foreground ,vampyricdark-red)
               (whitespace-empty :background ,vampyricdark-orange :foreground ,vampyricdark-red)
               (whitespace-hspace :background ,bg3 :foreground ,vampyricdark-comment)
               (whitespace-indentation :background ,vampyricdark-orange :foreground ,vampyricdark-red)
               (whitespace-line :background ,vampyricdark-bg :foreground ,vampyricdark-pink)
               (whitespace-newline :foreground ,vampyricdark-comment)
               (whitespace-space :background ,vampyricdark-bg :foreground ,vampyricdark-comment)
               (whitespace-space-after-tab :background ,vampyricdark-orange :foreground ,vampyricdark-red)
               (whitespace-space-before-tab :background ,vampyricdark-orange :foreground ,vampyricdark-red)
               (whitespace-tab :background ,bg2 :foreground ,vampyricdark-comment)
               (whitespace-trailing :inherit trailing-whitespace)
               ;; yard-mode
               (yard-tag-face :inherit font-lock-builtin-face)
               (yard-directive-face :inherit font-lock-builtin-face))))

  (apply #'custom-theme-set-faces
         'vampyricdark
         (let ((expand-with-func
                (lambda (func spec)
                  (let (reduced-color-list)
                    (dolist (col colors reduced-color-list)
                      (push (list (car col) (funcall func col))
                            reduced-color-list))
                    (eval `(let ,reduced-color-list
                             (backquote ,spec))))))
               whole-theme)
           (pcase-dolist (`(,face . ,spec) faces)
             (push `(,face
                     ((((min-colors 16777216)) ; fully graphical envs
                       ,(funcall expand-with-func 'cadr spec))
                      (((min-colors 256))      ; terminal withs 256 colors
                       ,(if vampyricdark-use-24-bit-colors-on-256-colors-terms
                            (funcall expand-with-func 'cadr spec)
                          (funcall expand-with-func 'caddr spec)))
                      (t                       ; should be only tty-like envs
                       ,(funcall expand-with-func 'cadddr spec))))
                   whole-theme))
           whole-theme))

  (apply #'custom-theme-set-variables
         'vampyricdark
         (let ((get-func
                (pcase (display-color-cells)
                  ((pred (<= 16777216)) 'car) ; fully graphical envs
                  ((pred (<= 256)) 'cadr)     ; terminal withs 256 colors
                  (_ 'caddr))))               ; should be only tty-like envs
           `((ansi-color-names-vector
              [,(funcall get-func (alist-get 'vampyricdark-bg colors))
               ,(funcall get-func (alist-get 'vampyricdark-red colors))
               ,(funcall get-func (alist-get 'vampyricdark-green colors))
               ,(funcall get-func (alist-get 'vampyricdark-yellow colors))
               ,(funcall get-func (alist-get 'vampyricdark-comment colors))
               ,(funcall get-func (alist-get 'vampyricdark-purple colors))
               ,(funcall get-func (alist-get 'vampyricdark-cyan colors))
               ,(funcall get-func (alist-get 'vampyricdark-fg colors))])))))


;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'vampyricdark)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; vampyricdark-theme.el ends here
