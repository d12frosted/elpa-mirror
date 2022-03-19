;;; morgentau-theme.el --- Tango-based custom theme -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Benjamin Vincent Schulenburg <ben@wolkenwelten.net>

;; Author: Benjamin Vincent Schulenburg
;; URL: https://github.com/Melchizedek6809/morgentau-theme
;; Package-Version: 20220319.1049
;; Package-Commit: a8da5640b4a9b72a3136901d0a1a03071d9fcb00
;; Created: 2022
;; Version: 1.0
;; Keywords: theme, dark, faces
;; License: GPL-3.0-or-later
;; Filename: morgentau-theme.el
;; Package-Requires: ((emacs "24"))

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; This started out as a couple of modifications to the tango-dark theme
;; included with GNU Emacs, but has diverged quite a bit over time.

;;; Code:

(deftheme morgentau
  "Dark theme, based on tango-dark")

(let ((class '((class color) (min-colors 96)))
      ;; Tango palette colors.
      (butter-1 "#e5c07b") (butter-2 "#e5c07b") (butter-3 "#e5c07b")
      (choc-2 "#c17d11") (choc-3 "#8f5902")
      (cham-1 "#98c379") (cham-2 "#98c379") (cham-3 "#98c379")
      (blue-1 "#61afef") (blue-2 "#3465a4") (blue-3 "#204a87")
      (plum-1 "#fa988f") (plum-3 "#5c3566")
      (red-1 "#e06c75")  (red-3 "#a40000") (red-4 "#440905")
      (alum-1 "#bbc2cf") (alum-3 "#babdb6")
      (alum-4 "#888a85") (alum-5 "#555753") (alum-6 "#2e3436")
      ;; Not in Tango palette; used for better contrast.
      (butter-0 "#f5d080") (cham-0 "#9ce389") (blue-0 "#61afef") (plum-0 "#e9b2e3")
      (red-0 "#ff4b4b")  (alum-5.5 "#41423f") (alum-7 "#282c34") (alum-8 "#282c34"))

  (custom-theme-set-faces
   'morgentau
   ;; Ensure sufficient contrast on low-color terminals.
   `(default ((((class color) (min-colors 4096))
               (:foreground ,alum-1 :background ,alum-8))
              (((class color) (min-colors 256))
               (:foreground ,alum-1 :background "undefined"))
              (,class
               (:foreground ,alum-1 :background "undefined" ))))
   `(cursor ((,class (:background ,butter-1))))
   `(header-line ((,class (:background "#666"))))
   ;; Highlighting faces
   `(fringe ((,class (:background ,alum-7))))
   `(highlight ((,class (:foreground ,alum-6 :background "#c0c000"))))
   `(whitespace-tab ((,class (:foreground ,alum-6))))
   `(whitespace-space ((,class (:foreground ,alum-6))))
   `(whitespace-space-after-tab ((,class (:foreground ,alum-5 :background ,alum-8))))
   `(whitespace-indentation ((,class (:foreground ,alum-6))))
   `(whitespace-newline ((,class (:foreground ,alum-7))))
   `(region ((,class (:background ,alum-6))))
   `(secondary-selection ((,class (:background ,blue-3))))
   `(isearch ((,class (:foreground ,butter-1 :background ,blue-1))))
   `(lazy-highlight ((,class (:background ,blue-3))))
   `(line-number ((,class (:foreground ,alum-3 :background ,alum-7))))
   `(line-number-current-line ((,class (:foreground ,butter-1 :background ,blue-2))))

   `(trailing-whitespace ((,class (:foreground ,alum-1 :background ,red-4))))
   `(whitespace-trailing ((,class (:foreground ,alum-1 :background ,red-4))))
   ;; Mode line faces
   `(mode-line ((,class (:box (:line-width -1 :style released-button)
                  :foreground ,butter-1 :background ,blue-2))))
   `(mode-line-buffer-id ((,class (:weight normal))))
   `(mode-line-inactive ((,class
                          (:box (:line-width -1 :style released-button)
                           :background ,alum-5 :foreground ,alum-1))))
   `(compilation-mode-line-fail ((,class (:foreground ,red-3))))
   `(compilation-mode-line-run  ((,class (:foreground ,butter-3))))
   `(compilation-mode-line-exit ((,class (:foreground ,cham-3))))
   ;; Escape and prompt faces
   `(minibuffer-prompt ((,class (:foreground ,cham-2))))
   `(escape-glyph ((,class (:foreground ,butter-3))))
   `(homoglyph ((,class (:foreground ,butter-3))))
   `(error ((,class (:foreground ,red-0))))
   `(warning ((,class (:foreground ,butter-1))))
   `(success ((,class (:foreground ,cham-1))))
   ;; Font Lock
   `(font-lock-string-face ((,class (:foreground ,butter-3))))
   `(font-lock-constant-face ((,class (:foreground ,blue-2))))
   `(font-lock-function-name-face ((,class (:foreground ,butter-1 :weight bold))))
   `(font-lock-variable-name-face ((,class (:foreground ,butter-1 :weight bold))))
   `(font-lock-operator-face ((,class (:foreground ,blue-1))))
   `(font-lock-end-statement-face ((,class (:foreground ,blue-3))))
   `(font-lock-builtin-face ((,class (:foreground ,plum-1))))
   `(font-lock-comment-face ((,class (:foreground ,alum-4))))
   `(font-lock-keyword-face ((,class (:foreground ,cham-0))))
   `(font-lock-type-face ((,class (:foreground ,blue-0))))
   `(highlight-numbers-number ((,class (:foreground ,blue-1))))
   `(highlight-operators-face ((,class (:foreground ,butter-0))))
   `(highlight-parentheses-highlight ((,class (:foreground ,blue-1 :weight bold))))
   `(company-tooltip ((,class (:foreground ,blue-1 :background ,alum-6))))
   `(company-scrollbar-fg ((,class (:foreground ,blue-1 :background ,blue-2))))
   `(company-scrollbar-bg ((,class (:foreground ,alum-5 :background ,alum-7))))
   `(company-tooltip-common ((,class (:foreground ,alum-1))))
   `(company-tooltip-selection ((,class (:foreground ,blue-1 :background ,alum-5 :weight bold))))
   `(ac-completion-face ((,class (:foreground ,blue-1 :underline t))))
   `(ac-candidate-face ((,class (:foreground ,alum-1 :background ,alum-5.5))))
   `(ac-selection-face ((,class (:foreground ,butter-1 :background ,blue-3))))
   ;; `(hl-line ((,class (:background ,alum-6))))
   ;; Button and link faces
   `(link ((,class (:underline t :foreground ,blue-1))))
   `(link-visited ((,class (:underline t :foreground ,blue-2))))
   ;; Rainbow
   `(rainbow-delimiters-depth-1-face ((,class (:foreground ,blue-2))))
   `(rainbow-delimiters-depth-2-face ((,class (:foreground ,cham-3))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground ,butter-1))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground ,red-3))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground ,blue-1))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground ,cham-1))))
   `(rainbow-delimiters-depth-7-face ((,class (:foreground ,butter-1))))
   `(rainbow-delimiters-depth-8-face ((,class (:foreground ,red-1))))
   `(rainbow-delimiters-depth-9-face ((,class (:foreground ,alum-1))))
   ;; Gnus faces
   `(gnus-group-news-1 ((,class (:weight bold :foreground ,plum-3))))
   `(gnus-group-news-1-low ((,class (:foreground ,plum-3))))
   `(gnus-group-news-2 ((,class (:weight bold :foreground ,blue-3))))
   `(gnus-group-news-2-low ((,class (:foreground ,blue-3))))
   `(gnus-group-news-3 ((,class (:weight bold :foreground ,red-3))))
   `(gnus-group-news-3-low ((,class (:foreground ,red-3))))
   `(gnus-group-news-4 ((,class (:weight bold :foreground ,"#7a4c02"))))
   `(gnus-group-news-4-low ((,class (:foreground ,"#7a4c02"))))
   `(gnus-group-news-5 ((,class (:weight bold :foreground ,butter-3))))
   `(gnus-group-news-5-low ((,class (:foreground ,butter-3))))
   `(gnus-group-news-low ((,class (:foreground ,alum-4))))
   `(gnus-group-mail-1 ((,class (:weight bold :foreground ,plum-3))))
   `(gnus-group-mail-1-low ((,class (:foreground ,plum-3))))
   `(gnus-group-mail-2 ((,class (:weight bold :foreground ,blue-3))))
   `(gnus-group-mail-2-low ((,class (:foreground ,blue-3))))
   `(gnus-group-mail-3 ((,class (:weight bold :foreground ,cham-3))))
   `(gnus-group-mail-3-low ((,class (:foreground ,cham-3))))
   `(gnus-group-mail-low ((,class (:foreground ,alum-4))))
   `(gnus-header-content ((,class (:foreground ,cham-3))))
   `(gnus-header-from ((,class (:weight bold :foreground ,butter-3))))
   `(gnus-header-subject ((,class (:foreground ,red-3))))
   `(gnus-header-name ((,class (:foreground ,blue-3))))
   `(gnus-header-newsgroups ((,class (:foreground ,alum-4))))
   ;; Message faces
   `(message-header-name ((,class (:foreground ,blue-1))))
   `(message-header-cc ((,class (:foreground ,butter-3))))
   `(message-header-other ((,class (:foreground ,choc-2))))
   `(message-header-subject ((,class (:foreground ,cham-1))))
   `(message-header-to ((,class (:foreground ,butter-2))))
   `(message-cited-text ((,class (:foreground ,cham-1))))
   `(message-separator ((,class (:foreground ,plum-1))))
   ;; SMerge faces
   `(smerge-refined-change ((,class (:background ,blue-3))))
   ;; Ediff faces
   `(ediff-current-diff-A ((,class (:background ,alum-5))))
   `(ediff-fine-diff-A ((,class (:background ,blue-3))))
   `(ediff-even-diff-A ((,class (:background ,alum-5.5))))
   `(ediff-odd-diff-A ((,class (:background ,alum-5.5))))
   `(ediff-current-diff-B ((,class (:background ,alum-5))))
   `(ediff-fine-diff-B ((,class (:background ,choc-3))))
   `(ediff-even-diff-B ((,class (:background ,alum-5.5))))
   `(ediff-odd-diff-B ((,class (:background ,alum-5.5))))
   ;; Realgud
   `(realgud-overlay-arrow1  ((,class (:foreground "green"))))
   `(realgud-overlay-arrow2  ((,class (:foreground ,butter-1))))
   `(realgud-overlay-arrow3  ((,class (:foreground ,plum-0))))
   `(realgud-bp-disabled-face      ((,class (:foreground ,blue-3))))
   `(realgud-bp-line-enabled-face  ((,class (:underline "red"))))
   `(realgud-bp-line-disabled-face ((,class (:underline ,blue-3))))
   `(realgud-file-name             ((,class :foreground ,blue-1)))
   `(realgud-line-number           ((,class :foreground ,plum-0)))
   `(realgud-backtrace-number      ((,class :foreground ,plum-0 :weight bold)))
   ;; Semantic faces
   `(semantic-decoration-on-includes ((,class (:underline ,alum-4))))
   `(semantic-decoration-on-private-members-face
     ((,class (:background ,plum-3))))
   `(semantic-decoration-on-protected-members-face
     ((,class (:background ,choc-3))))
   `(semantic-decoration-on-unknown-includes
     ((,class (:background ,red-3))))
   `(semantic-decoration-on-unparsed-includes
     ((,class (:background ,alum-5.5))))
   `(semantic-tag-boundary-face ((,class (:overline ,blue-1))))
   `(semantic-unmatched-syntax-face ((,class (:underline ,red-1)))))

  (custom-theme-set-variables
   'morgentau
   `(ansi-color-names-vector [,alum-8 ,red-0 ,cham-0 ,butter-1
                                      ,blue-1 ,plum-1 ,blue-0 ,alum-1])))

;;;###autoload
(when load-file-name
  (add-to-list
   'custom-theme-load-path
   (file-name-as-directory (file-name-directory load-file-name))))

;;;###autoload
(defun morgentau-theme()
  "Load `morgentau-theme`."
  (interactive)
  (load-theme 'morgentau t))

(provide-theme 'morgentau)

;;; morgentau-theme.el ends here
