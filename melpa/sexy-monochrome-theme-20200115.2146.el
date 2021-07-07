;;; sexy-monochrome-theme.el --- A sexy dark Emacs >= 24 theme for your sexy code

;; Copyright (c) 2017 Volodymyr Yevtushenko

;; Author: Volodymyr Yevtushenko <voloyev@vivaldi.net>
;; Keywords: themes
;; Package-Version: 20200115.2146
;; Package-Commit: f3ad07d60c966ef34cb11026eaba053e114bb8f1
;; URL: https://github.com/voloyev/sexy-monochrome-theme
;; Version: 3.0

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

;; To use it, put the following in your Emacs configuration file:
;;
;;   (load-theme 'sexy-monochrome t)
;;
;; Requirements: Emacs >= 24.

;;; Credits:

;; Based on the Xavier Noria monochrome-theme
;; https://github.com/fxn/monochrome-theme.el/

;; And impressed by "Monochrome color scheme for Vim"
;; https://github.com/fxn/vim-monochrome

;;; Code:

(deftheme sexy-monochrome
  "Gray on black (with bit of light slate gray colours) theme for your hacking sessions.")

(font-lock-add-keywords 'c-mode
                        '(("\\(\\w+\\)\\s-*\("
                           (1 font-lock-function-name-face)))
                        t)

(let ((class '((class color) (min-colors 10)))
      (gblack "#000000")
      (gwhite "#ffffff")
      (lgray "#d3d3d3")
      (dgray "#a9a9a9")
      (sgray "#778899")
      (foreground "#e5e5e5")
      (region "#191970")
      (comment "#616161")
      (string "#4682b4")
      (linum "#696969")
      (paren-match "#483d8b")
      (paren-mismatch "#ff0000")
      (whitespace-mode-color "gray30")
      (warning-color "yellow")
      (error-color "red"))

  (custom-theme-set-faces
   'sexy-monochrome

   `(default ((,class (:foreground ,lgray :background ,gblack))))
   `(cursor ((,class (:background ,lgray))))

   ;; Highlighting faces
   `(fringe ((t (:background "black" :foreground "light gray"))))
   `(highlight ((t (:background "gray9"))))
   `(region ((t (:background ,region))))
   `(secondary-selection ((,class (:foreground: ,gblack :background ,sgray))))
   `(isearch ((,class (:foreground ,gblack :background ,lgray))))
   `(lazy-highlight ((,class (:foreground ,gblack :background ,lgray))))
   `(linum ((t (:foreground ,linum))))
   `(trailing-whitespace ((,class (:background ,error-color))))

   ;; Mode line faces
   `(mode-line ((t ( :box (:line-width -1 :style released-button)))))
   `(mode-line-inactive ((t (:box (:line-width -1 :style released-button)))))

   ;; Whitespace-mode
   `(whitespace-empty ((,class (:background unspecified :foreground ,error-color))))
   `(whitespace-line ((,class (:background ,lgray :underline t))))
   `(whitespace-newline ((t (:background nil :foreground ,whitespace-mode-color))))
   `(whitespace-space ((t (:foreground ,whitespace-mode-color :background nil))))
   `(whitespace-tab ((t (:foreground ,whitespace-mode-color :background nil))))

   ;; Escape and prompt faces
   `(minibuffer-prompt ((,class (:weight bold :foreground ,gwhite))))
   `(escape-glyph ((,class (:foreground ,lgray))))
   `(error ((,class (:weight bold :slant italic :foreground ,error-color))))
   `(warning ((,class (:foreground ,warning-color))))
   `(success ((,class (:foreground "green"))))

   ;; Font lock faces
   `(font-lock-builtin-face ((,class (:foreground ,foreground :weight bold))))
   `(font-lock-constant-face ((,class (:foreground ,foreground :weight bold))))
   `(font-lock-keyword-face ((,class (:foreground ,foreground :weight bold))))
   `(font-lock-type-face ((,class (:foreground ,foreground :slant italic))))
   `(font-lock-function-name-face ((,class (:foreground ,foreground :weight bold))))
   `(font-lock-variable-name-face ((,class (:foreground ,foreground))))
   `(font-lock-comment-delimiter-face ((,class (:foreground ,comment))))
   `(font-lock-comment-face ((,class (:foreground ,comment))))
   `(font-lock-doc-face ((,class (:inherit (font-lock-comment-face)))))
   `(font-lock-string-face ((,class (:foreground ,foreground :foreground ,string))))
   `(font-lock-warning-face ((,class (:foreground ,warning-color))))
   
   ;; Button and link faces
   `(link ((,class (:underline t :foreground ,lgray))))
   `(link-visited ((,class (:underline t :foreground ,lgray))))

   ;; Show-paren
   `(show-paren-match ((t (:background ,paren-match))))
   `(show-paren-mismatch  ((t (:background ,paren-mismatch))))
   
   ;; Smartparens show mode
   `(sp-show-pair-match-face ((t (:background ,paren-match))))
   `(sp-show-pair-mismatch-face ((t (:background ,paren-mismatch))))

   ;; highlight indentation current column face
   `(highlight-indentation-current-column-face ((t (:background "gray40"))))
   `(highlight-indentation-face ((t (:background "gray20"))))

   ;; Speedbar
   `(speedbar-button-face ((,class (:foreground ,dgray))))
   `(speedbar-file-face ((,class (:foreground ,lgray))))
   `(speedbar-directory-face ((,class (:weight bold :foreground ,gwhite))))
   `(speedbar-tag-face ((,class (:foreground ,dgray))))
   `(speedbar-selected-face ((,class (:underline ,lgray :foreground ,lgray))))
   `(speedbar-highlight-face ((,class (:weight bold :background ,gblack :foreground ,gwhite))))

   ;; ido
   `(ido-first-match ((,class (:foreground ,lgray))))
   `(ido-only-match ((,class (:underline ,lgray :foreground ,lgray))))
   `(ido-subdir ((,class (:weight bold :foreground ,gwhite))))

   ;; MuMaMo
   `(mumamo-background-chunk-major ((,class (:background ,gblack))))
   `(mumamo-background-chunk-submode1 ((,class (:background ,gblack))))
   `(mumamo-background-chunk-submode2 ((,class (:background ,gblack))))
   `(mumamo-background-chunk-submode3 ((,class (:background ,gblack))))
   `(mumamo-background-chunk-submode4 ((,class (:background ,gblack))))
   `(mumamo-border-face-in ((,class (:slant unspecified :underline unspecified
                                            :weight bold :foreground ,gwhite))))
   `(mumamo-border-face-out ((,class (:slant unspecified :underline unspecified
                                             :weight bold :foreground ,gwhite))))

   ;; Gnus faces
   `(gnus-group-news-1 ((,class (:weight bold :foreground ,lgray))))
   `(gnus-group-news-1-low ((,class (:foreground ,lgray))))
   `(gnus-group-news-2 ((,class (:weight bold :foreground ,lgray))))
   `(gnus-group-news-2-low ((,class (:foreground ,lgray))))
   `(gnus-group-news-3 ((,class (:weight bold :foreground ,lgray))))
   `(gnus-group-news-3-low ((,class (:foreground ,lgray))))
   `(gnus-group-news-4 ((,class (:weight bold :foreground ,lgray))))
   `(gnus-group-news-4-low ((,class (:foreground ,lgray))))
   `(gnus-group-news-5 ((,class (:weight bold :foreground ,lgray))))
   `(gnus-group-news-5-low ((,class (:foreground ,lgray))))
   `(gnus-group-news-low ((,class (:foreground ,lgray))))
   `(gnus-group-mail-1 ((,class (:weight bold :foreground ,lgray))))
   `(gnus-group-mail-1-low ((,class (:foreground ,lgray))))
   `(gnus-group-mail-2 ((,class (:weight bold :foreground ,lgray))))
   `(gnus-group-mail-2-low ((,class (:foreground ,lgray))))
   `(gnus-group-mail-3 ((,class (:weight bold :foreground ,lgray))))
   `(gnus-group-mail-3-low ((,class (:foreground ,lgray))))
   `(gnus-group-mail-low ((,class (:foreground ,lgray))))
   `(gnus-header-content ((,class (:foreground ,lgray))))
   `(gnus-header-from ((,class (:weight bold :foreground ,lgray))))
   `(gnus-header-subject ((,class (:foreground ,lgray))))
   `(gnus-header-name ((,class (:foreground ,lgray))))
   `(gnus-header-newsgroups ((,class (:foreground ,lgray))))

   ;; Message faces
   `(message-header-name ((,class (:foreground ,lgray))))
   `(message-header-cc ((,class (:foreground ,lgray))))
   `(message-header-other ((,class (:foreground ,lgray))))
   `(message-header-subject ((,class (:foreground ,lgray))))
   `(message-header-to ((,class (:weight bold :foreground ,lgray))))
   `(message-cited-text ((,class (:slant italic :foreground ,lgray))))
   `(message-separator ((,class (:weight bold :foreground ,lgray))))

   ;; EShell
   `(eshell-prompt ((,class (:foreground ,gwhite :bold t))))
   `(eshell-ls-archive ((,class (:inherit eshell-ls-unreadable))))
   `(eshell-ls-backup ((,class (:inherit eshell-ls-unreadable))))
   `(eshell-ls-clutter ((,class (:inherit eshell-ls-unreadable))))
   `(eshell-ls-directory ((,class (:foreground ,lgray :bold t))))
   `(eshell-ls-executable ((,class (:inherit eshell-ls-unreadable))))
   `(eshell-ls-missing ((,class (:inherit eshell-ls-unreadable))))
   `(eshell-ls-product ((,class (:inherit eshell-ls-unreadable))))
   `(eshell-ls-readonly ((,class (:inherit eshell-ls-unreadable))))
   `(eshell-ls-special ((,class (:inherit eshell-ls-unreadable))))
   `(eshell-ls-symlink ((,class (:inherit eshell-ls-unreadable))))

   ;; easy-kill
   `(easy-kill-selection ((t (:background "#333333"))))

   ;; Org-mode
   `(org-link ((t (:foreground ,sgray :underline t))))
   `(org-todo ((t (:bold t :foreground ,error-color))))
   `(org-done ((t (:bold t :foreground "green"))))
   `(org-verbatim ((t (:foreground "dim gray"))))

   ;; helm
   `(helm-header ((t (:foreground ,dgray :background ,gblack :underline nil :box nil))))
   `(helm-source-header
     ((t (:foreground ,gwhite
                      :background ,gblack
                      :underline nil
                      :weight bold
                      :box (:line-width 1 :style released-button)))))
   `(helm-selection-line ((t (:background ,gblack))))
   `(helm-visible-mark ((t (:foreground ,gblack :background ,gwhite))))
   `(helm-candidate-number ((t (:foreground ,lgray :background ,gblack))))
   `(helm-separator ((t (:foreground ,gwhite :background ,gblack))))
   `(helm-time-zone-current ((t (:foreground ,lgray :background ,gblack))))
   `(helm-time-zone-home ((t (:foreground ,gwhite :background ,gblack))))
   `(helm-bookmark-addressbook ((t (:foreground ,lgray :background ,gblack))))
   `(helm-bookmark-directory ((t (:foreground nil :background nil :inherit helm-ff-directory))))
   `(helm-bookmark-file ((t (:foreground nil :background nil :inherit helm-ff-file))))
   `(helm-bookmark-gnus ((t (:foreground ,gwhite :background ,gblack))))
   `(helm-bookmark-info ((t (:foreground ,lgray :background ,gblack))))
   `(helm-bookmark-man ((t (:foreground ,gwhite :background ,gblack))))
   `(helm-bookmark-w3m ((t (:foreground ,gwhite :background ,gblack))))
   `(helm-buffer-directory ((t (:background ,gwhite :foreground ,sgray :weight bold))))
   `(helm-buffer-not-saved ((t (:foreground ,gwhite :background ,gblack))))
   `(helm-buffer-process ((t (:foreground ,gwhite :background ,gblack))))
   `(helm-buffer-saved-out ((t (:foreground ,lgray :background ,gblack))))
   `(helm-buffer-size ((t (:foreground ,lgray :background ,gblack))))
   `(helm-ff-directory ((t (:foreground ,gwhite :background ,gblack :weight bold))))
   `(helm-ff-file ((t (:foreground ,lgray :background ,gblack :weight normal))))
   `(helm-ff-executable ((t (:foreground ,lgray :background ,gblack :weight normal))))
   `(helm-ff-invalid-symlink ((t (:foreground ,gwhite :background ,gblack :weight bold))))
   `(helm-ff-symlink ((t (:foreground ,gwhite :background ,gblack :weight bold))))
   `(helm-ff-prefix ((t (:foreground ,gblack :background ,gwhite :weight normal))))
   `(helm-grep-cmd-line ((t (:foreground ,gwhite :background ,gblack))))
   `(helm-grep-file ((t (:foreground ,lgray :background ,gblack))))
   `(helm-grep-finish ((t (:foreground ,lgray :background ,gblack))))
   `(helm-grep-lineno ((t (:foreground ,lgray :background ,gblack))))
   `(helm-grep-match ((t (:foreground nil :background nil :inherit helm-match))))
   `(helm-grep-running ((t (:foreground ,gwhite :background ,gblack))))
   `(helm-moccur-buffer ((t (:foreground ,gwhite :background ,gblack))))
   `(helm-mu-contacts-address-face ((t (:foreground ,lgray :background ,gblack))))
   `(helm-mu-contacts-name-face ((t (:foreground ,lgray :background ,gblack))))
   `(helm-match ((t (:background "dim gray"))))
   `(helm-selection ((t (:background "#3b3b3b" :underline nil))))

   ;; diff
   '(diff-added ((t (:foreground "dark sea green"))))
   '(diff-context ((t (:foreground "white" :weight bold))))
   '(diff-file-header ((t (:foreground "white" :weight bold))))
   '(diff-header ((t (:background "brightblack"))))
   '(diff-indicator-added ((t (:foreground "dark sea green"))))
   '(diff-indicator-removed ((t (:foreground "light coral"))))
   '(diff-refine-added ((t (:inherit diff-refine-change :background "#Caff70" :foreground "black" :weight bold))))
   '(diff-refine-removed ((t (:background "red" :foreground "white" :weight bold))))
   '(diff-removed ((t (:foreground "light coral"))))

   ;; Magit
   '(magit-diff-add ((t (:foreground "dark sea green"))))
   '(magit-diff-del ((t (:foreground "light coral"))))
   '(magit-diff-file-header ((t (:box (:line-width 2 :color "grey75" :style released-button)))))
   '(magit-diff-hunk-header ((t (:weight bold))))
   '(magit-item-highlight ((t (:weight bold))))
   '(magit-section-title ((t (:underline t :weight bold))))
   '(magit-key-mode-button-face ((t (:foreground "yellow" :weight bold))))
   '(magit-key-mode-switch-face ((t (:foreground "yellow" :weight bold))))
   '(makey-key-mode-button-face ((t (:foreground "yellow" :weight bold))))

   ;; smartparens
   '(sp-show-pair-match-face ((t (:background "honeydew" :foreground "dim gray"))))

   ;; highlight-symbol-face
   `(highlight-symbol-face ((t (:background "#333333"))))

   ;; volatile-highlights
   `(vhl/default-face ((t (:background "#333333"))))

   ;; rainbow-identifiers
   `(rainbow-identifiers-identifier-1 ((t (:foreground "#9999bb" :weight bold))))
   `(rainbow-identifiers-identifier-10 ((t (:foreground "#e0a0bc" :weight bold))))
   `(rainbow-identifiers-identifier-11 ((t (:foreground "#a7c0b9" :weight bold))))
   `(rainbow-identifiers-identifier-12 ((t (:foreground "#a7aac0" :weight bold))))
   `(rainbow-identifiers-identifier-13 ((t (:foreground "#c0a7bd" :weight bold))))
   `(rainbow-identifiers-identifier-14 ((t (:foreground "#c0afa7" :weight bold))))
   `(rainbow-identifiers-identifier-15 ((t (:foreground "#b3c0a7" :weight bold))))
   `(rainbow-identifiers-identifier-2 ((t (:foreground "#bb99b4" :weight bold))))
   `(rainbow-identifiers-identifier-3 ((t (:foreground "#bba699" :weight bold))))
   `(rainbow-identifiers-identifier-4 ((t (:foreground "#a6bb99" :weight bold))))
   `(rainbow-identifiers-identifier-5 ((t (:foreground "#99bbb4" :weight bold))))
   `(rainbow-identifiers-identifier-6 ((t (:foreground "#e0d0a0" :weight bold))))
   `(rainbow-identifiers-identifier-7 ((t (:foreground "#a3e0a0" :weight bold))))
   `(rainbow-identifiers-identifier-8 ((t (:foreground "#a0d6e0" :weight bold))))
   `(rainbow-identifiers-identifier-9 ((t (:foreground "#b6a0e0" :weight bold))))

   ;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground "grey55" :weight bold))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground "#93a8c6" :weight bold))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground "#b0b1a3" :weight bold))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground "#97b098" :weight bold))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground "#aebed8" :weight bold))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground "#b0b0b3" :weight bold))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground "#90a890" :weight bold))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground "#a2b6da" :weight bold))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground "#9cb6ad" :weight bold))))
   `(rainbow-delimiters-mismatched-face ((t (:inherit rainbow-delimiters-unmatched-face :weight bold))))
   `(rainbow-delimiters-unmatched-face ((t (:foreground "#88090B" :weight bold))))

   ;; Flyspell
   `(flyspell-duplicate ((,class (:weight unspecified :foreground unspecified
                                          :slant unspecified :underline ,lgray))))
   `(flyspell-incorrect ((,class (:weight unspecified :foreground unspecified
                                          :slant unspecified :underline ,sgray)))))
   
  (custom-theme-set-variables
   'sexy-monochrome
   `(ansi-color-names-vector [,gblack ,lgray ,dgray ,sgray])))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'sexy-monochrome)

;; Local Variables:
;; End:

;;; sexy-monochrome-theme.el ends here
