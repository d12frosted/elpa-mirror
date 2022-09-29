;;; underwater-theme.el --- A gentle, deep blue color theme

;; Copyright (C) 2012 Jon-Michael Deldin

;; Author: Jon-Michael Deldin <dev@jmdeldin.com>
;; Keywords: faces
;; Compatibility: 24.1
;; Version: 1.1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This is an Emacs 24 port of underwater-mod.vim by Mario Gutierrez
;; from URL `http://www.vim.org/scripts/script.php?script_id=3132'.
;;
;; To use this theme, download it to ~/.emacs.d/themes. In your `.emacs'
;; or `init.el', add this line:
;;
;;   (add-to-list 'custom-theme-load-path "~/.emacs.d/themes")
;;
;; Once you have reloaded your configuration (`eval-buffer'), do `M-x
;; load-theme' and select "underwater".

;;; Code:

(deftheme underwater "Port of underwater Vim theme")

(let ((*background-color*   "#102235")
      (*brown*              "#E64")
      (*comments*           "#4E6F91")
      (*constant*           "#FFC287")
      (*current-line*       "#18374f")
      (*cursor-block*       "#FFFFFF")
      (*cursor-underscore*  "#FFFAAA")
      (*keywords*           "#8AC6F2")
      (*light-purple*       "#FFCCFF")
      (*line-number*        "#2F577C")
      (*method-declaration* "#AF81F4")
      (*mode-line-bg*       "#0A1721")
      (*mode-line-fg*       "#FFEC99")
      (*mode-line-inactive* "#4E6F91")
      (*normal*             "#DFEFF6")
      (*number*             "#96DEFA")
      (*operators*          "#3E71A1")
      (*parens*             "magenta")
      (*red*                "#C62626")
      (*red-light*          "#FFB6B0")
      (*regexp*             "#EF7760")
      (*regexp-alternate*   "#FF0")
      (*regexp-alternate-2* "#B18A3D")
      (*search-fg*          "#E2DAEF")
      (*search-bg*          "#AF81F4")
      (*string*             "#89E14B")
      (*type*               "#5BA0EB")
      (*variable*           "#8AC6F2")
      (*vertical-border*    "#0A1721")
      (*visual-selection*   "#262D51"))

  (custom-theme-set-faces
   'underwater

   `(bold ((t (:bold t))))
   `(button ((t (:foreground, *keywords* :underline t))))
   `(default ((t (:background, *background-color* :foreground, *normal*))))
   `(header-line ((t (:background, *mode-line-bg* :foreground, *normal*)))) ;; info header
   `(highlight ((t (:background, *current-line*))))
   `(highlight-face ((t (:background, *current-line*))))
   `(hl-line ((t (:background, *current-line* :underline t))))
   `(info-xref ((t (:foreground, *keywords* :underline t))))
   `(region ((t (:background, *visual-selection*))))
   `(underline ((nil (:underline t))))

   ;; font-lock
   `(font-lock-builtin-face ((t (:foreground, *operators*))))
   `(font-lock-comment-delimiter-face ((t (:foreground, *comments*))))
   `(font-lock-comment-face ((t (:foreground, *comments*))))
   `(font-lock-constant-face ((t (:foreground, *constant*))))
   `(font-lock-doc-face ((t (:foreground, *string*))))
   `(font-lock-doc-string-face ((t (:foreground, *string*))))
   `(font-lock-function-name-face ((t (:foreground, *method-declaration*))))
   `(font-lock-keyword-face ((t (:foreground, *keywords*))))
   `(font-lock-negation-char-face ((t (:foreground, *red*))))
   `(font-lock-preprocessor-face ((t (:foreground, *keywords*))))
   `(font-lock-reference-face ((t (:foreground, *constant*))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground, *regexp*))))
   `(font-lock-regexp-grouping-construct ((t (:foreground, *regexp*))))
   `(font-lock-string-face ((t (:italic t :foreground, *string*))))
   `(font-lock-type-face ((t (:foreground, *type*))))
   `(font-lock-variable-name-face ((t (:foreground, *variable*))))
   `(font-lock-warning-face ((t (:foreground, *red*))))

   ;; GUI
   `(fringe ((t (:background, *background-color*))))
   `(linum ((t (:background, *line-number*))))
   `(minibuffer-prompt ((t (:foreground, *variable*))))
   `(mode-line ((t (:background, *mode-line-bg* :foreground, *mode-line-fg*))))
   `(mode-line-inactive ((t (:background, *mode-line-bg* :foreground, *mode-line-inactive*))))
   `(text-cursor ((t (:background, *cursor-underscore*))))
   `(vertical-border ((t (:foreground, *vertical-border*)))) ;; between splits

   ;; show-paren
   `(show-paren-mismatch ((t (:background, *red* :foreground, *normal* :weight bold))))
   `(show-paren-match ((t (:background, *background-color* :foreground, *parens* :weight bold))))

   ;; search
   `(isearch ((t (:background, *search-bg* :foreground, *search-fg*))))
   `(isearch-fail ((t (:background, *red*))))
   `(lazy-highlight ((t (:background, *operators* :foreground, *search-fg*))))

   ;; erb/rhtml-mode
   `(erb-out-delim-face ((t (:foreground, *regexp*))))

   ;; magit
   `(magit-diff-add ((t (:foreground, *string*))))
   `(magit-diff-del ((t (:foreground, *red*))))

   ;; enh-ruby-mode
   `(enh-ruby-op-face ((t (:foreground, *operators*))))
   `(enh-ruby-regexp-delimiter-face ((t (:foreground, *regexp*))))
   `(enh-ruby-string-delimiter-face ((t (:foreground, *normal*))))

   ;; org-mode
   `(org-date ((t (:foreground, *light-purple* :underline t))))
   `(org-level-1 ((t (:foreground, *string*))))
   `(org-special-keyword ((t (:foreground, *variable*))))
   `(org-link ((t (:foreground, *keywords* :underline t))))
   `(org-checkbox ((t (:foreground, *keywords* :background, *background-color* :bold t))))
   `(org-clock-overlay ((t (:foreground, *mode-line-bg* :background, *string*))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

;; Local Variables:
;; no-byte-compile: t
;; End:

(provide-theme 'underwater)
;;; underwater-theme.el ends here
