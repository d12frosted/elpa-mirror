;;; liso-theme.el ---  Eclectic Dark Theme for GNU Emacs

;; Author: Vlad Piersec <vlad.piersec@gmail.com>
;; Keywords: theme, themes
;; URL: https://github.com/caisah/liso-theme
;; Version: 2.1

;;; Commentary:
;; Inspired by TangoTango Theme https://github.com/juba/color-theme-tangotango

;;; License:

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later
;; version.
;;
;; This is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(deftheme liso
  "Liso - Eclectic Dark Theme inspired by TangoTango")

(let ((background "#272C2E")
      (foreground "#EDEDE1")
      (cursor-yellow "#E6CB00")
      (foreground-black "#1A1A1A")
      (escape "#C83194")
      (prompt-green "#C8FF03")
      (highlight-yellow "#ECE185")
      (region-background "#31454F")
      (fail-dark-red "#8B0000")
      (error-red "#E02831")
      (warning "#FF7E00")
      (search-pink "#FFEDE6")
      (search-orange "#CE5C00")
      (search-brown "#795317")
      (comment "#5D6A70")
      (liso-yellow "#FFE203")
      (liso-orange "#FF9326")
      (liso-pink "#FFABAB")
      (liso-purple "#B46DCC")
      (liso-red "#C04040")
      (liso-dark-red "#9D3E3E")
      (liso-green "#C8FF03")
      (liso-dark-green "#6E8C02")
      (liso-blue "#99D6FF")
      (link-blue "#7CA4CF")
      (link-dark-blue "#5075A4")
      (ml-black "#131617")
      (ml-yellow "#EAB700")
      (ml-grey "#C7C7AB")
      (ml-grey-darker "#414B4E")
      (paren-blue "#7AD9FF")
      (paren-red "#9D005C")
      (diff-dark-red "#8C5454")
      (diff-dark-green "#598C54")
      (diff-light-green "#7ABF73")
      (diff-ultra-green "#2BBD1C")
      (diff-light-red "#A63232")
      (diff-light-orange "#DE7000")
      (darker-background "#1A1C1F"))

  (custom-theme-set-faces
   'liso

   `(default ((t (:family "Ubuntu Mono"
                          :foundry "unknown"
                          :width normal
                          :height 128
                          :weight normal
                          :slant normal
                          :underline nil
                          :overline nil
                          :strike-through nil
                          :box nil
                          :inverse-video nil
                          :foreground ,foreground
                          :background ,background
                          :stipple nil
                          :inherit nil))))
   `(cursor ((t (:foreground ,foreground-black :background ,cursor-yellow))))
   `(fixed-pitch ((t (:inherit (default)))))
   `(variable-pitch ((t (:family "Sans Serif"))))
   `(escape-glyph ((t (:foreground ,escape))))
   `(minibuffer-prompt ((t (:weight normal :foreground ,prompt-green))))
   `(highlight ((t (:foreground ,foreground-black :background ,highlight-yellow))))
   `(region ((t (:background ,region-background))))
   `(shadow ((((class color grayscale) (min-colors 88) (background light)) (:foreground "grey50"))
             (((class color grayscale) (min-colors 88) (background dark)) (:foreground "grey70"))
             (((class color) (min-colors 8) (background light)) (:foreground "green"))
             (((class color) (min-colors 8) (background dark)) (:foreground "yellow"))))
   `(secondary-selection ((t (:background ,search-brown))))
   `(trailing-whitespace ((t (:background ,fail-dark-red))))
   `(whitespace-trailing ((t (:background ,fail-dark-red :foreground ,foreground-black))))
   ;;
   `(font-lock-builtin-face ((t (:foreground ,liso-purple))))
   `(font-lock-comment-face ((t (:foreground ,comment))))
   `(font-lock-comment-delimiter-face ((t (:inherit (font-lock-comment-face)))))
   `(font-lock-constant-face ((t (:foreground ,liso-red))))
   `(font-lock-doc-face ((t (:foreground ,liso-dark-green))))
   `(font-lock-function-name-face ((t (:foreground ,liso-yellow))))
   `(font-lock-keyword-face ((t (:foreground ,liso-green))))
   `(font-lock-negation-char-face ((t nil)))
   `(font-lock-preprocessor-face ((t (:inherit (font-lock-builtin-face)))))
   `(font-lock-regexp-grouping-backslash ((t (:inherit (bold)))))
   `(font-lock-regexp-grouping-construct ((t (:inherit (bold)))))
   `(font-lock-string-face ((t (:foreground ,liso-pink))))
   `(font-lock-type-face ((t (:foreground ,liso-blue))))
   `(font-lock-variable-name-face ((t (:foreground ,liso-orange))))
   `(font-lock-warning-face ((t (:weight bold :foreground ,warning :inherit (error)))))

   `(button ((t (:inherit (link)))))
   `(link ((t (:underline (:color foreground-color :style line) :foreground ,link-blue))))
   `(link-visited ((t (:underline (:color foreground-color :style line) :foreground ,link-dark-blue :inherit (link)))))
   `(fringe ((t (:background ,background))))
   `(header-line ((t (:foreground ,comment :weight bold))))
   `(tooltip ((t (:foreground "black" :background "lightyellow" :inherit (quote variable-pitch)))))
   `(mode-line ((t (:box (:line-width -1 :color nil :style pressed-button) :foreground "white smoke" :background ,ml-black))))
   `(mode-line-buffer-id ((t (:weight bold :foreground ,ml-yellow))))
   `(mode-line-emphasis ((t (:weight bold))))
   `(mode-line-highlight ((((class color) (min-colors 88)) (:box (:line-width 2 :color "grey40" :style released-button))) (t (:inherit (highlight)))))
   `(mode-line-inactive ((t (:weight light :box (:line-width -1 :color nil :style released-button) :foreground ,ml-grey :background ,ml-grey-darker :inherit (mode-line)))))
   `(isearch ((t (:foreground ,search-pink :background ,search-orange :underline (:color foreground-color :style line)))))
   `(isearch-fail ((((class color) (min-colors 88) (background light)) (:background "RosyBrown1"))
                   (((class color) (min-colors 88) (background dark)) (:background "red4"))
                   (((class color) (min-colors 16)) (:background "red"))
                   (((class color) (min-colors 8)) (:background "red"))
                   (((class color grayscale)) (:foreground "grey"))
                   (t (:inverse-video t))))
   `(anzu-mode-line ((t (:foreground "PaleVioletRed2" :weight bold))))
   `(lazy-highlight ((t (:foreground ,foreground-black :background ,search-brown))))
   `(match ((t (:weight bold :foreground ,search-orange :background ,foreground-black))))
   `(next-error ((t (:inherit (region)))))
   `(query-replace ((t (:inherit (isearch)))))
   `(show-paren-match ((t (:background ,paren-blue :foreground ,background))))
   `(show-paren-mismatch ((t (:background ,paren-red :foreground "red"))))
   `(linum ((t (:foreground "#6F8085" :weight light :height 0.9))))
   `(vertical-border ((t (:foreground ,ml-black))))
   `(error ((t (:foreground ,error-red :weight semi-bold))))
   `(completions-first-difference ((t (:inherit (highlight)))))

   ;; flycheck
   `(flycheck-error ((t (:background ,ml-black :underline (:color ,error-red :style wave)))))
   `(flycheck-warning ((t (:underline (:color ,warning :style wave)))))

   ;; helm
   `(helm-action ((t (:foreground ,foreground :underline nil))))
   `(helm-selection ((t (:background ,ml-grey-darker :weight bold))))
   `(helm-source-header ((t (:background: ,background :foreground ,ml-yellow :family "Ubuntu Mono" :weight normal :height: 1.1))))
   `(helm-visible-mark ((t (:inherit (diredp-flag-mark)))))
   `(helm-candidate-number ((t (:inherit (match)))))
   `(helm-buffer-directory ((t (:inherit (diredp-dir-priv)))))
   `(helm-buffer-size ((t (:foreground ,comment))))
   `(helm-buffer-process ((t (:inherit (font-lock-doc-face)))))
   `(helm-buffer-not-saved ((t (:foreground ,liso-orange))))
   `(helm-buffer-file ((t (:foreground ,liso-pink :weight normal))))
   `(helm-ff-directory ((t (:inherit (diredp-dir-priv)))))
   `(helm-ff-file ((t (:inherit (diredp-file-name)))))
   `(helm-ff-dotted-directory ((t (:inherit (diredp-dir-priv)))))
   `(helm-ff-symlink ((t (:inherit (font-lock-warning-face)))))
   `(helm-M-x-key ((t (:foreground ,liso-red :weight bold))))
   `(helm-match ((t (:foreground ,prompt-green))))
   `(helm-separator ((t (:foreground ,liso-dark-green))))
   `(helm-grep-file ((t (:foreground ,liso-dark-green))))
   `(helm-grep-match ((t (:foreground ,prompt-green))))
   `(helm-swoop-target-word-face ((t (:background ,ml-black :foreground ,prompt-green :underline nil))))
   `(helm-swoop-target-line-face ((t (:background ,ml-grey-darker))))

   ;; company
   `(company-tooltip-selection ((t (:inherit (helm-selection)))))
   `(company-tooltip-search ((t (:background ,foreground-black))))
   `(company-tooltip-common-selection ((t (:foreground ,prompt-green :background ,ml-grey-darker))))
   `(company-tooltip ((t (:foreground ,foreground :background ,darker-background))))
   `(company-tooltip-common ((t (:foreground ,prompt-green :background ,darker-background))))
   `(company-scrollbar-fg ((t (:background ,ml-yellow))))
   `(company-scrollbar-bg ((t (:background ,ml-black))))
   `(company-preview-common ((t (:background ,liso-pink :foreground ,ml-black))))

   ;; dired plus
   `(diredp-dir-priv ((t (:foreground ,liso-yellow :weight bold))))
   `(diredp-dir-name ((t (:foreground ,liso-yellow :weight bold))))
   `(diredp-file-name ((t (:foreground ,foreground :weight normal))))
   `(diredp-file-suffix ((t (:foreground ,comment :slant italic))))
   `(diredp-dir-heading ((t (:background ,background :foreground ,ml-yellow :weight ultra-bold))))
   `(diredp-symlink ((t (:foreground ,link-blue))))
   `(diredp-compressed-file-suffix ((t (:foreground ,foreground))))
   `(diredp-flag-mark ((t (:background ,liso-yellow :foreground ,background))))
   `(diredp-flag-mark-line ((t (:inherit (diredp-flag-mark)))))
   `(diredp-ignored-file-name ((t (:foreground ,comment))))
   `(diredp-deletion-file-name ((t (:background ,liso-red :foreground ,foreground))))
   `(diredp-deletion ((t (:inherit (diredp-deletion-file-name)))))
   `(diredp-read-priv ((t (:background ,background :foreground ,foreground :weight bold))))
   `(diredp-write-priv ((t (:background ,background :foreground ,liso-dark-green :weight bold))))
   `(diredp-exec-priv ((t (:background ,background :foreground ,liso-green :weight bold))))
   `(diredp-link-priv ((t (:background ,background :foreground ,liso-orange :weight bold))))
   `(diredp-date-time ((t (:foreground ,comment))))
   `(diredp-number ((t (:foreground ,comment))))
   `(diredp-no-priv ((t (:foreground ,foreground))))

   ;; magit
   `(magit-log-author ((t (:foreground ,comment))))
   `(magit-log-date ((t (:foreground ,comment))))
   `(magit-tag ((t (:foreground ,liso-purple))))
   `(magit-branch-remote ((t (:foreground ,liso-blue))))
   `(magit-branch-local ((t (:foreground ,liso-green :box (:width 2)))))
   `(magit-branch-current ((t (:foreground ,liso-green :box (:width 2)))))
   `(magit-hash ((t (:foreground ,liso-red))))
   `(magit-head ((t (:foreground ,liso-red :background ,ml-black))))
   `(magit-section-heading ((t (:foreground ,ml-yellow))))
   `(magit-section-highlight ((t (:background ,ml-grey-darker))))
   `(magit-diff-file-heading ((t (:foreground ,foreground))))
   `(magit-diff-file-heading-highlight ((t (:foreground ,foreground :background ,ml-grey-darker :weight bold))))
   `(magit-diff-context-highlight ((t (:background ,ml-black :foreground ,comment))))
   `(magit-diff-hunk-heading-highlight ((t (:background ,ml-black :foreground ,comment))))
   `(magit-diff-added ((t (:foreground ,diff-dark-green))))
   `(magit-diff-added-highlight ((t (:background ,ml-black :foreground ,diff-light-green))))
   `(magit-diff-removed ((t (:foreground ,diff-dark-red))))
   `(magit-diff-removed-highlight ((t (:background ,ml-black :foreground ,diff-light-red))))

   ;; org
   `(org-table ((t (:foreground ,liso-dark-green))))
   `(org-level-1 ((t (:foreground ,liso-red))))
   `(org-level-2 ((t (:foreground ,liso-orange))))
   `(org-level-3 ((t (:foreground ,liso-yellow))))
   `(org-level-4 ((t (:foreground ,liso-green))))
   `(org-level-5 ((t (:foreground ,liso-blue))))
   `(org-level-6 ((t (:foreground ,liso-purple))))
   `(org-level-7 ((t (:foreground ,liso-pink))))
   `(org-level-8 ((t (:foreground ,liso-dark-green))))

   ;; ediff
   `(diff-removed ((t (:foreground ,diff-dark-red))))
   `(diff-refine-removed ((t (:foreground ,diff-light-red))))
   `(diff-added ((t (:foreground ,diff-dark-green))))
   `(diff-refine-added ((t (:foreground ,diff-light-green))))
   `(ediff-current-diff-A ((t (:background ,ml-black))))
   `(ediff-current-diff-B ((t (:background ,ml-black))))
   `(ediff-current-diff-C ((t (:background ,ml-black))))
   `(ediff-even-diff-A ((t (:background ,ml-black))))
   `(ediff-even-diff-B ((t (:background ,ml-black))))
   `(ediff-even-diff-C ((t (:background ,ml-black))))
   `(ediff-odd-diff-A ((t (:background ,ml-black))))
   `(ediff-odd-diff-B ((t (:background ,ml-black))))
   `(ediff-odd-diff-C ((t (:background ,ml-black))))
   `(ediff-fine-diff-A ((t (:foreground ,diff-light-orange))))
   `(ediff-fine-diff-B ((t (:foreground ,diff-light-orange))))
   `(ediff-fine-diff-C ((t (:background ,ml-black :foreground ,diff-ultra-green))))

   ;; web mode
   `(web-mode-html-tag-face ((t (:foreground ,liso-yellow))))
   `(web-mode-html-tag-bracket-face ((t (:inherit (web-mode-html-tag-face)))))
   `(web-mode-html-attr-name-face ((t (:foreground ,liso-dark-green))))
   `(web-mode-html-attr-value-face ((t (:foreground ,liso-dark-red))))

   ;; js2 mode
   `(js2-error ((t (:inherit (flycheck-error)))))
   `(js2-warning ((t (:inherit (flycheck-warning)))))
   `(js2-external-variable ((t (:foreground "HotPink1"))))

   ;; eshell
   `(eshell-prompt ((t (:foreground ,ml-yellow :background ,ml-black :weight ultra-bold))))
   `(eshell-ls-directory ((t (:foreground ,liso-yellow :weight bold))))
   `(eshell-ls-symlink ((t (:foreground ,link-blue))))
   `(eshell-ls-executable ((t (:foreground ,liso-green))))

   ;; whitespace
   `(whitespace-trailing ((t (:background ,error-red))))
   `(whitespace-tab ((t (:background ,highlight-yellow))))
   `(whitespace-line ((t (:background ,background :foreground ,foreground))))

   ;; markdown
   `(markdown-header-face ((t (:inherit (org-level-1)))))
   `(markdown-header-delimiter-face ((t (:foreground ,search-orange))))
   `(markdown-header-face-1 ((t (:inherit (org-level-1)))))
   `(markdown-header-face-2 ((t (:inherit (org-level-2)))))
   `(markdown-header-face-3 ((t (:inherit (org-level-3)))))
   `(markdown-header-face-4 ((t (:inherit (org-level-4)))))
   `(markdown-header-face-5 ((t (:inherit (org-level-5)))))
   `(markdown-url-face ((t (:foreground ,link-dark-blue))))
   `(markdown-link-face ((t (:foreground ,liso-blue))))

   ;; hs
   `(hs-face ((t (:foreground ,liso-dark-green :background ,ml-black))))

   ;; re-builder
   `(reb-match-0 ((t (:background ,search-orange :foreground ,foreground :box (:line-width 1 :color ,liso-pink)))))
   `(reb-match-1 ((t (:background ,search-brown :foreground ,foreground :box (:line-width 1 :color ,liso-pink)))))

   ;; Twitter
   `(twittering-uri-face ((t (:inherit (link)))))
   `(twittering-username-face ((t (:inherit (font-lock-type-face)))))

   ;; ERC
   `(erc-timestamp-face ((t (:foreground ,liso-dark-green))))
   `(erc-notice-face ((t (:foreground ,comment))))
   `(erc-nick-default-face ((t (:foreground ,liso-blue))))
   `(erc-action-face ((t (:foreground ,liso-purple))))
   ))

(custom-theme-set-variables
 'liso
 '(ansi-color-names-vector ["black" "red3" "green3" "yellow3" "#FFE203" "magenta3" "cyan3" "gray90"])
 '(ansi-color-map (ansi-color-make-color-map))
 '(ibuffer-marked-face 'diredp-flag-mark)
 '(ibuffer-deletion-face 'diredp-deletion-file-name))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

;; Export
(provide-theme 'liso)

;;; liso-theme.el ends here
