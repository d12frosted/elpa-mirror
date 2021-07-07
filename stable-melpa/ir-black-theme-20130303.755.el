;;; ir-black-theme.el --- Port of ir-black theme

;; Copyright (C) 2012  Jon-Michael Deldin

;; Author: Jon-Michael Deldin <dev@jmdeldin.com>
;; Keywords: faces
;; Package-Version: 20130303.755
;; Package-Commit: 36e930d107604b5763c80294a6f92aaa02e6c272
;; Compatibility: 24
;; Version: 1.0.1

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

;; This is an Emacs 24 port of Todd Werth's IR Black theme available at URL
;; `http://blog.toddwerth.com/entries/8'. It still needs font-locking for
;; operators, numbers, and regular expressions, and it could definitely use
;; some cleaning up. Improvements are welcome!
;;
;; To use this theme, download it to ~/.emacs.d/themes. In your `.emacs' or
;; `init.el', add this line:
;;
;;    (add-to-list 'custom-theme-load-path "~/.emacs.d/themes")
;;
;; Once you have reloaded your configuration (`eval-buffer'), do `M-x
;; load-theme' and select "ir-black".

;;; Credits:

;; Thanks to Bozhidar Batsov for pointers and the autoloader from his
;; solarized theme at URL
;; `https://github.com/bbatsov/solarized-emacs/blob/master/solarized-theme.el'.

;;; Code:

(deftheme ir-black "Port of ir-black theme")

(let ((*background-color*   "#000000")
      (*brown*              "#E64")
      (*comments*           "#7C7C7C")
      (*constant*           "#99CC99")
      (*current-line*       "#151515")
      (*cursor-underscore*  "#FFFAAA")
      (*keywords*           "#96CBFE")
      (*light-purple*       "#FFCCFF")
      (*line-number*        "#3D3D3D")
      (*method-declaration* "#FFD2A7")
      (*mode-line-bg*       "#202020")
      (*mode-line-fg*       "#CCCCCC")
      (*normal*             "#F6F3E8")
      (*number*             "#FF73FD")
      (*operators*          "#FFFFB6")
      (*red*                "#FF6C60")
      (*red-light*          "#FFB6B0")
      (*regexp*             "#E9C")
      (*regexp-alternate*   "#FF0")
      (*regexp-alternate-2* "#B18A3D")
      (*search-selection*   "#2F2F00")
      (*string*             "#A8FF60")
      (*string-inner*       "#00A0A0")
      (*variable*           "#C6C5FE")
      (*visual-selection*   "#262D51"))

  (custom-theme-set-faces
   'ir-black

   `(bold ((t (:bold t))))
   `(button ((t (:foreground, *keywords* :underline t))))
   `(default ((t (:background, *background-color* :foreground, *normal*))))
   `(escape-glyph ((t (:foreground, *string-inner*))))
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
   `(font-lock-number-face ((t (:foreground, *number*))))
   `(font-lock-preprocessor-face ((t (:foreground, *keywords*))))
   `(font-lock-reference-face ((t (:foreground, *constant*))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground, *regexp*))))
   `(font-lock-regexp-grouping-construct ((t (:foreground, *regexp*))))
   `(font-lock-string-face ((t (:foreground, *string*))))
   `(font-lock-type-face ((t (:foreground, *operators*))))
   `(font-lock-variable-name-face ((t (:foreground, *variable*))))
   `(font-lock-warning-face ((t (:foreground, *red*))))

   ;; GUI
   `(fringe ((t (:background, *background-color*))))
   `(linum ((t (:background, *line-number*))))
   `(minibuffer-prompt ((t (:foreground, *variable*))))
   `(mode-line ((t (:background, *mode-line-bg* :foreground, *mode-line-fg*))))
   `(mode-line-inactive ((t (:background, *mode-line-bg* :foreground, *background-color*))))
   `(cursor ((t (:background, *cursor-underscore*))))
   `(text-cursor ((t (:background, *cursor-underscore*))))
   `(vertical-border ((t (:foreground, *background-color*)))) ;; between splits

   ;; show-paren
   `(show-paren-mismatch ((t (:background, *red* :foreground, *normal* :weight bold))))
   `(show-paren-match ((t (:background, *keywords* :foreground, *normal* :weight bold))))

   ;; search
   `(isearch ((t (:background, *regexp-alternate* :foreground, *search-selection*))))
   `(isearch-fail ((t (:background, *red*))))
   `(lazy-highlight ((t (:background, *operators* :foreground, *search-selection*))))

   ;; magit
   `(magit-diff-add ((t (:foreground, *string*))))
   `(magit-diff-del ((t (:foreground, *red*))))

   ;; org-mode
   `(org-date ((t (:foreground, *light-purple* :underline t))))
   `(org-level-1 ((t (:foreground, *string*))))
   `(org-special-keyword ((t (:foreground, *variable*))))
   `(org-link ((t (:foreground, *keywords* :underline t))))
   `(org-checkbox ((t (:foreground, *keywords* :background, *background-color* :bold t))))
   `(org-clock-overlay ((t (:foreground, *mode-line-bg* :background, *string*))))

   ;; starter kit
   `(esk-paren-face ((t (:foreground, *string-inner*))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

;; Local Variables:
;; no-byte-compile: t
;; End:

(provide-theme 'ir-black)
;;; ir-black-theme.el ends here
