;;; badwolf-theme.el --- Bad Wolf color theme

;; Copyright (C) 2015  Bartłomiej Kruczyk

;; Author: bkruczyk <bartlomiej.kruczyk@gmail.com>
;; Version: 1.2
;; Package-Version: 20151215.1725
;; Package-Commit: 24a557f92a702f632901a5b7bee59945a0a8cde9
;; Keywords: themes
;; Package-Requires: ((emacs "24"))
;; URL: https://github.com/bkruczyk/badwolf-emacs

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

;; An Emacs port of Steve's Losh theme for Vim:
;; https://github.com/sjl/badwolf

;;; Credits:

;; Steve Losh is creator of the original theme for Vim
;; (https://github.com/sjl/badwolf), on which this Emacs port was
;; based.

;; locojay is creator of the initial Emacs port
;; (https://github.com/locojay/badwolf).

;;; Code:

(deftheme badwolf "Bad Wolf color theme")

(let ((bg "#222120")
      (plain "#f8f6f2")
      (snow "#ffffff")
      (coal "#000000")
      (brightgravel "#d9cec3")
      (lightgravel "#998f84")
      (gravel "#857f78")
      (mediumgravel "#666462")
      (deepgravel "#45413b")
      (deepergravel "#35322d")
      (darkgravel "#242321")
      (blackgravel "#1c1b1a")
      (blackestgravel "#141413")
      (dalespale "#fade3e")
      (dirtyblonde "#f4cf86")
      (taffy "#ff2c4b")
      (saltwatertaffy "#8cffba")
      (tardis "#0a9dff")
      (orange "#ffa724")
      (lime "#aeee00")
      (dress "#ff9eb8")
      (toffee "#b88853")
      (coffee "#c7915b")
      (darkroast "#88633f"))

  (custom-theme-set-faces
   'badwolf

   ;; font lock
   `(default ((t (:inherit nil :foreground ,plain :background ,bg))))
   `(font-lock-builtin-face ((t (:foreground ,brightgravel))))
   `(font-lock-comment-face ((t (:foreground ,lightgravel))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,lightgravel))))
   `(font-lock-constant-face ((t (:foreground ,orange))))
   `(font-lock-doc-face ((t (:foreground ,snow))))
   `(font-lock-function-name-face ((t (:foreground ,orange))))
   `(font-lock-keyword-face ((t (:foreground ,taffy :weight bold))))
   `(font-lock-string-face ((t (:foreground ,dirtyblonde))))
   `(font-lock-type-face ((t (:foreground ,dress))))
   `(font-lock-variable-name-face ((t (:foreground ,plain))))
   `(font-lock-warning-face ((t (:foreground ,dress :weight bold))))
   `(shadow ((t (:foreground ,mediumgravel))))
   `(success ((t (:foreground ,lime))))
   `(error ((t (:foreground ,dress :weight bold))))
   `(warning ((t (:foreground ,orange))))

   ;; ui
   `(cursor ((t (:background ,tardis))))
   `(region ((t (:foreground nil :background ,mediumgravel))))
   `(secondary-selection ((t (:foreground ,darkgravel :background ,tardis))))
   `(fringe ((t (:background ,bg))))
   `(linum ((t (:foreground ,mediumgravel :background ,bg))))
   `(vertical-border ((t (:foreground ,gravel))))
   `(highlight ((t (:foreground ,coal :background ,dalespale))))
   `(escape-glyph ((t (:foreground ,tardis))))
   `(hl-line ((t (:inherit nil :background "#292826"))))
   `(minibuffer-prompt ((t (:foreground ,lime))))
   `(mode-line ((t (:box nil :foreground ,snow :background "#595959"))))
   `(mode-line-inactive ((t (:box nil :foreground "#848484" :background "#333333"))))
   `(header-line ((t (:inherit mode-line))))
   `(link ((t (:foreground ,lightgravel :underline t))))
   `(link-visited ((t (:inherit link :foreground ,orange))))

   ;; whitespace-mode
   `(trailing-whitespace ((t (:background ,taffy :foreground ,blackestgravel))))
   `(whitespace-trailing ((t (:background ,taffy :foreground ,blackestgravel))))
   `(whitespace-empty ((t :background ,dirtyblonde)))
   `(whitespace-line ((t (:background ,deepergravel :foreground ,dress))))

   `(whitespace-hspace ((t (:foreground ,mediumgravel))))
   `(whitespace-space ((t (:foreground ,mediumgravel))))
   `(whitespace-tab ((t (:foreground ,mediumgravel))))
   `(whitespace-newline ((t (:foreground ,mediumgravel))))

   `(whitespace-indentation ((t (:background ,dirtyblonde :foreground ,taffy))))
   `(whitespace-space-after-tab ((t (:background ,dirtyblonde :foreground ,taffy))))
   `(whitespace-space-before-tab ((t (:background ,dirtyblonde :foreground ,taffy))))

   ;; search
   `(isearch ((t (:foreground ,coal :background ,saltwatertaffy))))
   `(isearch-fail ((t (:foreground ,coal :background ,taffy))))
   `(lazy-highlight ((t (:foreground ,coal :background ,dalespale))))

   ;; show-paren-mode
   `(show-paren-match ((t (:foreground ,coal :background ,dalespale))))
   `(show-paren-mismatch ((t (:foreground ,coal :background ,taffy))))

   ;; anzu
   `(anzu-match-1 ((t (:background ,lime :foreground ,coal))))
   `(anzu-match-2 ((t (:background ,dalespale :foreground ,coal))))
   `(anzu-match-3 ((t (:background ,tardis :foreground ,coal))))
   `(anzu-mode-line ((t (:foreground ,dress))))
   `(anzu-replace-to ((t (:background ,dalespale :foreground ,coal))))

   ;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,gravel))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,orange))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,saltwatertaffy))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,dress))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground ,coffee))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,dirtyblonde))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,orange))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground ,saltwatertaffy))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground ,dress))))
   `(rainbow-delimiters-unmatched-face ((t (:foreground ,taffy))))

   ;; company
   `(company-echo-common ((t (:foreground ,plain))))
   `(company-preview ((t (:background ,deepergravel :foreground ,plain))))
   `(company-preview-common ((t (:foreground ,orange))))
   `(company-preview-search ((t (:foreground ,tardis))))
   `(company-scrollbar-bg ((t (:background ,deepgravel))))
   `(company-scrollbar-fg ((t (:background ,mediumgravel))))
   `(company-tooltip ((t (:foreground ,plain :background ,deepergravel))))
   `(company-tooltip-annotation ((t (:foreground ,coffee :background ,deepergravel))))
   `(company-tooltip-common ((t (:foreground ,dress :background ,deepergravel))))
   `(company-tooltip-common-selection ((t (:foreground ,dress :background ,deepergravel))))
   `(company-tooltip-mouse ((t (:inherit highlight))))
   `(company-tooltip-selection ((t (:background ,deepergravel :foreground ,orange))))
   `(company-template-field ((t (:inherit region))))

   ;; org
   `(outline-1 ((t (:foreground ,orange :height 1.2))))
   `(outline-2 ((t (:foreground ,brightgravel))))
   `(outline-3 ((t (:foreground ,saltwatertaffy))))
   `(outline-4 ((t (:foreground ,dress))))
   `(outline-5 ((t (:foreground ,coffee))))
   `(outline-6 ((t (:foreground ,dirtyblonde))))
   `(outline-7 ((t (:foreground ,orange))))
   `(outline-8 ((t (:foreground ,taffy))))

   `(org-done ((t (:foreground ,saltwatertaffy :weight bold))))
   `(org-todo ((t (:foreground ,dalespale :weight bold))))
   `(org-date ((t (:foreground ,dress :underline t))))
   `(org-special-keyword ((t (:foreground ,dress))))
   `(org-document-info ((t (:foreground ,brightgravel))))
   `(org-document-title ((t (:foreground ,plain :family "sans" :height 1.8 :weight bold))))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'badwolf)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; badwolf-theme.el ends here
