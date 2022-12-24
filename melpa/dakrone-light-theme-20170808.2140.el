;;; dakrone-light-theme.el --- dakrone's custom light theme
;; Copyright (C) 2017 Lee Hinman

;; Author: Lee Hinman <lee _AT_ writequit.org>
;; URL: https://github.com/dakrone/dakrone-light-theme
;; Package-Version: 20170808.2140
;; Package-Commit: 06f198dc8b4ca7421990b30a23d89c8e0b8c5de4
;; Version: 1.0.0
;; Keywords: color themes faces
;; This file is not part of GNU Emacs.

;;; License:
;; This file is free software; you can redistribute it and/or modify it under
;; the terms of the GNU Lesser General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later version.

;; This file is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
;; A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
;; details.

;; You should have received a copy of the GNU Lesser General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; A high-contrast light theme with greens and steely blues
;;
;; To use, put the following in your Emacs config:
;;
;;   (load-theme 'dakrone-light t)
;;
;; Requires Emacs 24

;;; Code:

(deftheme dakrone-light
  "Dakrone's light background theme. A high-contrast light theme
  with greens and steely blues")

(custom-theme-set-faces
 'dakrone-light
 '(default ((t (:foreground "black" :background "#f9f9f9"))))
 '(fringe ((t (:background "#f9f9f9"))))
 '(foreground-color ((t (:foreground "black"))))
 '(Info-quoted ((t (:underline "gray40" :weight bold))))
 '(font-lock-comment-face ((t (:foreground "#888888"))))
 '(font-lock-string-face ((t (:background "#fff0f0"))))
 '(font-lock-keyword-face ((t (:foreground "#008800"))))
 '(font-lock-builtin-face ((t (:foreground "#007020"))))
 '(font-lock-function-name-face ((t (:foreground "#0066BB"))))
 '(font-lock-variable-name-face ((t (:foreground "#996633"))))
 '(font-lock-type-face ((t (:foreground "#333399"))))
 '(font-lock-constant-face ((t (:foreground "#003366"))))
 '(font-lock-warning-face ((t (:foreground "#ff0000" :bold t))))
 '(font-lock-doc-face ((t (:foreground "#206070"))))
 '(font-lock-preprocessor-face ((t (:foreground "#557799"))))
 '(font-lock-negation-char-face ((t (:foreground "#fa8072"))))
 '(font-lock-comment-delimiter-face ((t (:foreground "#888888"))))
 '(sh-heredoc ((t (:background "#fff0f0" :foreground "black"))))
 '(default ((t (:background "white" :foreground "black"))))
 '(diff-added ((t (:inherit diff-changed :background "light green"))))
 '(diff-changed ((t (:background "light steel blue"))))
 '(diff-removed ((t (:inherit diff-changed :background "sandy brown"))))
 '(diff-indicator-added ((t (:inherit diff-indicator-changed))))
 '(diff-indicator-changed ((t (:weight bold))))
 '(diff-indicator-removed ((t (:inherit diff-indicator-changed))))
 '(dired-directory ((t (:inherit font-lock-function-name-face :weight bold))))
 '(hl-line ((t (:background "grey90"))))
 '(hl-paren-face ((t (:weight bold))) t)
 '(region ((t (:background "lightgoldenrod1"))))
 '(eshell-prompt ((t (:foreground "#c65d09"))))
 '(show-paren-match ((t (:background "#0088DD" :foreground "white"))))
 '(mode-line ((t (:box (:line-width 1) :background "grey80"))))
 '(mode-line-inactive ((t (:background "#f9f9f9" :box (:line-width 1 :color "grey80")))))
 ;; git-gutter
 '(git-gutter:added ((t (:foreground "light green" :weight bold))))
 '(git-gutter:modified ((t (:foreground "steel blue" :weight bold))))
 '(git-gutter:deleted ((t (:foreground "#fa8072" :weight bold))))

 ;; highlight-numbers
 '(highlight-numbers-number ((t (:foreground "#4400EE"))))

 ;; eyebrowse
 '(eyebrowse-mode-line-active ((t (:bold t :foreground "brown" :slant italic))))
 '(eyebrowse-mode-line-inactive ((t (:background nil))))

 ;; visible mark
 '(visible-mark-active ((t (:background "#DDDDDD"))))

 ;; Linum & nLinum
 '(linum ((t (:foreground "grey65" :height 0.85))))

 ;; Dired+
 '(diredp-dir-name ((t (:inherit font-lock-function-name-face))))
 '(diredp-file-name ((t (:inherit font-lock-constant-face))))
 '(diredp-dir-priv ((t (:foreground "black"))))
 '(diredp-read-priv ((t (:foreground "black"))))
 '(diredp-write-priv ((t (:foreground "black"))))
 '(diredp-exec-priv ((t (:foreground "black" :underline t))))
 '(diredp-no-priv ((t (:foreground "black"))))
 '(diredp-compressed-file-suffix ((t (:foreground "#888888"))))
 '(font-lock-regexp-grouping-backslash ((t (:inherit bold :foreground "black"))))
 '(font-lock-regexp-grouping-construct ((t (:inherit bold :foreground "black"))))

 ;; Gnus
 '(gnus-button ((t (:inherit button))))
 '(gnus-header-name ((t (:box (:line-width 1 :style released-button) :weight bold))))
 '(gnus-group-mail-1 ((t (:inherit gnus-group-mail-1-empty :weight bold))))
 '(gnus-group-mail-1-empty ((t (:foreground "DodgerBlue4"))))
 '(gnus-group-mail-2 ((t (:inherit gnus-group-mail-2-empty :weight bold))))
 '(gnus-group-mail-2-empty ((t (:foreground "DodgerBlue3"))))
 '(gnus-group-mail-3 ((t (:inherit gnus-group-mail-3-empty :weight bold))))
 '(gnus-group-mail-3-empty ((t (:foreground "DodgerBlue2"))))
 '(gnus-group-news-1 ((t (:inherit gnus-group-news-1-empty :weight bold))))
 '(gnus-group-news-1-empty ((t (:foreground "tomato4"))))
 '(gnus-group-news-2 ((t (:inherit gnus-group-news-2-empty :weight bold))))
 '(gnus-group-news-2-empty ((t (:foreground "tomato3"))))
 '(gnus-group-news-3 ((t (:inherit gnus-group-news-3-empty :weight bold))))
 '(gnus-group-news-3-empty ((t (:foreground "tomato2"))))
 '(header-line ((t (:background "#f0f0f0"))))

 ;; Helm
 '(helm-header ((t (:background "#f0f0f0"))))
 '(helm-source-header
   ((t (:height 1.1 :foreground "black" :weight bold :background "#abd7f0"))))
 '(helm-ls-git-added-copied-face ((t (:foreground "#007020"))))
 '(helm-ls-git-modified-not-staged-face ((t (:foreground "#996633"))))

 ;; Mu4e
 '(mu4e-unread-face ((t (:foreground "#005588" :weight bold))))
 '(mu4e-header-highlight-face
   ((t (:background "grey90" :weight bold :underline t))))

 ;; Org-mode
 '(org-agenda-date ((t (:inherit org-agenda-structure))))
 '(org-agenda-date-today ((t (:inherit org-agenda-date :underline t))))
 '(org-agenda-date-weekend ((t (:inherit org-agenda-date :foreground "dark green"))))
 '(org-agenda-structure ((t (:foreground "steel blue" :weight bold :height 1.1 :family "DeJaVu Sans"))))
 '(org-agenda-clocking ((t (:background "light steel blue"))))
 '(org-time-grid ((t (:foreground "#007020"))))
 '(org-block ((t (:inherit nil))))
 '(org-hide ((t (:foreground "white"))))
 '(org-table ((t (:foreground "#0066BB"))))
 '(org-verbatim ((t (:foreground "SteelBlue4" :bold t))))
 '(org-code ((t (:foreground "SeaGreen4"))))
 '(org-level-1 ((t (:inherit outline-1 :box nil))))
 '(org-level-2 ((t (:inherit outline-2 :box nil))))
 '(org-level-3 ((t (:inherit outline-3 :box nil))))
 '(org-level-4 ((t (:inherit outline-4 :box nil))))
 '(org-level-5 ((t (:inherit outline-5 :box nil))))
 '(org-level-6 ((t (:inherit outline-6 :box nil))))
 '(org-level-7 ((t (:inherit outline-7 :box nil))))
 '(org-level-8 ((t (:inherit outline-8 :box nil))))
 '(org-tag ((t (:foreground "grey60"))))
 '(outline-1 ((t (:inherit font-lock-function-name-face :weight bold))))
 '(outline-2 ((t (:inherit font-lock-variable-name-face :weight bold))))
 '(outline-3 ((t (:inherit font-lock-keyword-face :weight bold))))
 '(outline-4 ((t (:inherit font-lock-comment-face :weight bold))))
 '(outline-5 ((t (:inherit font-lock-type-face :weight bold))))
 '(outline-6 ((t (:inherit font-lock-constant-face :weight bold))))
 '(outline-7 ((t (:inherit font-lock-builtin-face :weight bold))))
 '(outline-8 ((t (:inherit font-lock-string-face :weight bold))))
 '(org-block-begin-line ((t (:foreground "grey55" :underline t :background "grey98"))))
 '(org-block-end-line ((t (:foreground "grey55" :overline t :background "grey98"))))
 '(org-mode-line-clock ((t (:foreground "#16446b"))))
 '(org-mode-line-clock-overrun ((t (:background "#fa8072"))))
 '(org-special-keyword ((t (:foreground "#90a4be"))))

 ;; Semantic
 '(semantic-tag-boundary-face ((t (:overline "steel blue"))))
 '(semantic-highlight-func-current-tag-face ((t (:background "grey95"))))

 ;; Company
 '(company-tooltip ((t (:background "#e0f4fe"))))
 '(company-tooltip-selection ((t (:background "light steel blue"))))

 ;; TODO:
 ;; anzu
 )

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'dakrone-light)
(provide 'dakrone-light-theme)

;; Local Variables:
;; eval: (when (fboundp 'rainbow-mode) (rainbow-mode +1))
;; End:

;;; dakrone-light-theme.el ends here
