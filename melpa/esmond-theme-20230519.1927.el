;;; esmond-theme.el --- Esmond dark theme

;; Copyright 2023 Çağan Korkmaz

;; Author: Çağan Korkmaz <cagankorkmaz35@gmail.com>
;; URL: https://github.com/xcatalyst/esmond-theme
;; Package-Version: 20230519.1927
;; Package-Commit: de697a6168e3a16c32ddd076294635a39f13f86a
;; Version: 0.01

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;; There may be colors that does not work with your packages, you
;; can add colors to the theme and do a pull request, please
;; do not try to use more colors then needed if possible

;;; Code:

(deftheme esmond "Esmond theme")

(let
    ((esmond-fg "#ece5e1")
     (esmond-fg-2 "#cac3bf")
     (esmond-fg-3 "#d1bba7")
     (esmond-fg-4 "#52494e")
     (esmond-bg "#181818")
     (esmond-bg-2 "#171717")
     (esmond-bg-3 "#242424")
     (esmond-bg-4 "#282828")
     (esmond-keyword "#c79b9e")
     (esmond-type "#d98259")
     (esmond-str "#c45247")
     (esmond-cursor "#fdf4c1")
     (esmond-bg-inactive "#121212")
     (esmond-comment "#474340")
     (esmond-select "#473030")
     (esmond-compilation-g "#73c936")
     (esmond-compilation-warn "#c98d40")
     (esmond-compilation-r "#bb2626"))


  (custom-theme-set-faces 'esmond
   `(default ((t (:foreground ,esmond-fg :background ,esmond-bg))))
   `(cursor ((t (:background ,esmond-cursor ))))
   `(fringe ((t (:background ,esmond-bg))))
   `(mode-line ((t (:foreground ,esmond-fg :background ,esmond-type))))
   `(mode-line-inactive ((t (:foreground ,esmond-fg :background ,esmond-bg-inactive))))
   `(region ((t (:background ,esmond-select ))))
   '(secondary-selection ((t (:background "#3e3834" ))))
   `(font-lock-builtin-face ((t (:foreground ,esmond-keyword :bold t ))))
   `(font-lock-comment-face ((t (:italic t :foreground ,esmond-comment))))
   `(font-lock-function-name-face ((t (:foreground ,esmond-fg :bold t ))))
   `(font-lock-keyword-face ((t (:foreground ,esmond-keyword :bold t))))
   `(font-lock-string-face ((t (:foreground ,esmond-str ))))
   `(font-lock-type-face ((t (:foreground ,esmond-type ))))
   `(font-lock-constant-face ((t (:foreground ,esmond-fg ))))
   `(font-lock-variable-name-face ((t (:foreground ,esmond-fg))))
   `(minibuffer-prompt ((t (:foreground ,esmond-fg-3))))

   `(show-paren-match ((t (:background ,esmond-bg-3))))
   '(show-paren-mismatch ((((class color)) (:background "red" :foreground "white"))))


   '(font-lock-warning-face ((t (:foreground "red" :bold t ))))

   `(shadow ((t (:foreground ,esmond-fg-4))))

   `(fringe ((t (:background nil :foreground ,esmond-bg-4))))
   `(vertical-border ((t (:foreground ,esmond-bg-4))))

   ;; Rainbow Delimeters Mode
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,esmond-str))))



   ;; Compilation
   `(compilation-info ((t (:foreground ,esmond-compilation-g :inherit 'unspecified))))
   `(compilation-warning ((t (:foreground ,esmond-compilation-warn :bold t :inherit 'unspecified))))
   `(compilation-error ((t (:foreground ,esmond-compilation-r))))
   `(compilation-mode-line-fail ((t ,(list :foreground esmond-compilation-r :weight 'bold :inherit 'unspecified))))
   `(compilation-mode-line-exit ((t ,(list :foreground esmond-compilation-g
					   :weight 'bold :inherit 'unspecified))))

   ;; Dired
   `(dired-directory ((t (:foreground ,esmond-type))))
   `(dired-ignored ((t ,(list :foreground esmond-compilation-g
			      :inherit 'unspecified))))

   `(line-number ((t (:inherit default :foreground ,esmond-fg-4))))
   `(line-number-current-line ((t (:inherit line-number :foreground ,esmond-str))))


    ;; Tab bar
   `(tab-bar ((t (:background ,esmond-bg-4 :foreground , esmond-fg-2))))
   `(tab-bar-tab ((t (:background nil :foreground ,esmond-str))))
   `(tab-bar-tab-inactive ((t (:background nil))))

   ;; Ido mode
   `(ido-first-match ((t (:foreground ,esmond-str :bold nil))))
   `(ido-only-match ((t (:foreground ,esmond-str :weight bold))))
   `(ido-subdir ((t (:foreground ,esmond-fg-3 :weight bold))))


   ;; Which Function
   `(which-func ((t (:foreground ,esmond-fg-3))))
   ;; Whitespace
   `(whitespace-space ((t (:background ,esmond-bg :foreground ,esmond-bg-2))))
   `(whitespace-tab ((t (:background ,esmond-bg :foreground ,esmond-bg-3))))
   `(whitespace-hspace ((t (:background ,esmond-bg-2 :foreground ,esmond-bg))))
   `(whitespace-line ((t  (:background ,esmond-bg-2 :foreground ,esmond-str))))

   `(whitespace-newline ((t (:background ,esmond-bg-2 :foreground ,esmond-bg-3))))
   `(whitespace-trailing ((t (:background ,esmond-bg :foreground ,esmond-str))))
   `(whitespace-empty ((t (:background ,esmond-bg-2
				 :foreground ,esmond-fg-2))))
   `(whitespace-indentation ((t (:background ,esmond-bg-3 :foreground ,esmond-fg-2))))
   `(whitespace-space-after-tab ((t (:background ,esmond-bg-3 :foreground ,esmond-fg-2))))
   `(whitespace-space-before-tab ((t (:background ,esmond-bg-3 :foreground ,esmond-fg-2))))))
;; autoload
(and load-file-name
    (boundp 'custom-theme-load-path)
    (add-to-list 'custom-theme-load-path
		 (file-name-as-directory
		  (file-name-directory load-file-name))))

(provide-theme 'esmond)

;;; esmond-theme.el ends here
