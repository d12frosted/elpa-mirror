;;; elune-theme.el --- Elune theme

;; Copyright 2023 Çağan Korkmaz

;; Author: Çağan Korkmaz <xcatalystt@gmail.com>
;; URL: https://github.com/xcatalyst/elune-theme
;; Package-Version: 20230526.2238
;; Package-Commit: e0f3f4def066e679cfdde3bbade4c83dcfc38cd8
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
;; Visual studio dark inspired color scheme
;; modified for making it more readable

;;; Code:

(deftheme elune "elune theme")

(let
    ((elune-fg "#bdbfcd")
     (elune-fg-2 "#73778C")
     (elune-fg-3 "#84858f")
     (elune-fg-4 "#84858f")
     (elune-fg-5 "#FEFEFE")
     (elune-bg "#181818")
     (elune-bg-2 "#171717")
     (elune-bg-3 "#242424")
     (elune-bg-4 "#282828")
     (elune-keyword "#90788F")
     (elune-type "#7794C7")
     (elune-str "#EF8B77")
     (elune-cursor "#bdbfcd")
     (elune-bg-inactive "#121212")
     (elune-comment "#474340")
     (elune-select "#3c3c3d")
     (elune-compilation-g "#73c936")
     (elune-compilation-warn "#c98d40")
     (elune-compilation-r "#bb2626")
     (elune-whitespace-line "#9e3131"))


  (custom-theme-set-faces 'elune
   `(default ((t (:foreground ,elune-fg :background ,elune-bg))))
   `(cursor ((t (:background ,elune-cursor ))))
   `(fringe ((t (:background ,elune-bg))))
   `(mode-line ((t (:foreground ,elune-fg-5 :background ,elune-type))))
   `(mode-line-inactive ((t (:foreground ,elune-fg-5 :background ,elune-bg-inactive))))
   `(region ((t (:background ,elune-select ))))
   '(secondary-selection ((t (:background "#3e3834" ))))
   `(font-lock-builtin-face ((t (:foreground ,elune-keyword :bold t ))))
   `(font-lock-comment-face ((t (:italic t :foreground ,elune-comment))))
   `(font-lock-function-name-face ((t (:foreground ,elune-fg :bold t ))))
   `(font-lock-keyword-face ((t (:foreground ,elune-keyword :bold t))))
   `(font-lock-string-face ((t (:foreground ,elune-str ))))
   `(font-lock-type-face ((t (:foreground ,elune-type ))))
   `(font-lock-constant-face ((t (:foreground ,elune-fg ))))
   `(font-lock-variable-name-face ((t (:foreground ,elune-fg))))
   `(highlight ((t (:background ,elune-bg-3 :foreground nil))))
   `(highlight-current-line-face ((t ,(list :background elune-bg-3 :foreground nil))))
   `(font-lock-preprocessor-face ((t (:foreground ,elune-keyword :bold t))))
   `(minibuffer-prompt ((t (:foreground ,elune-fg-3))))

   `(show-paren-match ((t (:background ,elune-bg-3))))
   '(show-paren-mismatch ((((class color)) (:background "red" :foreground "white"))))


   '(font-lock-warning-face ((t (:foreground "red" :bold t ))))

   `(shadow ((t (:foreground ,elune-fg-4))))

   `(fringe ((t (:background nil :foreground ,elune-bg-4))))
   `(vertical-border ((t (:foreground ,elune-bg-4))))

   ;; Rainbow Delimeters Mode
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,elune-fg))))



   ;; Compilation
   `(compilation-info ((t (:foreground ,elune-compilation-g :inherit 'unspecified))))
   `(compilation-warning ((t (:foreground ,elune-compilation-warn :bold t :inherit 'unspecified))))
   `(compilation-error ((t (:foreground ,elune-compilation-r))))
   `(compilation-mode-line-fail ((t ,(list :foreground elune-compilation-r :weight 'bold :inherit 'unspecified))))
   `(compilation-mode-line-exit ((t ,(list :foreground elune-compilation-g
					   :weight 'bold :inherit 'unspecified))))

   ;; Dired
   `(dired-directory ((t (:foreground ,elune-type))))
   `(dired-ignored ((t ,(list :foreground elune-compilation-g
			      :inherit 'unspecified))))

   `(line-number ((t (:inherit default :foreground ,elune-fg-4))))
   `(line-number-current-line ((t (:inherit line-number :foreground ,elune-str))))


    ;; Tab bar
   `(tab-bar ((t (:background ,elune-bg-4 :foreground , elune-fg-2))))
   `(tab-bar-tab ((t (:background nil :foreground ,elune-str))))
   `(tab-bar-tab-inactive ((t (:background nil))))

   ;; Ido mode
   `(ido-first-match ((t (:foreground ,elune-type :bold nil))))
   `(ido-only-match ((t (:foreground ,elune-type :weight bold))))
   `(ido-subdir ((t (:foreground ,elune-fg-3 :weight bold))))


   ;; Which Function
   `(which-func ((t (:foreground ,elune-fg-3))))
   ;; Whitespace
   `(whitespace-space ((t (:background ,elune-bg :foreground ,elune-bg-2))))
   `(whitespace-tab ((t (:background ,elune-bg :foreground ,elune-bg-3))))
   `(whitespace-hspace ((t (:background ,elune-bg-2 :foreground ,elune-bg))))
   `(whitespace-line ((t  (:background ,elune-bg-2 :foreground ,elune-compilation-r :bold t))))

   `(whitespace-newline ((t (:background ,elune-bg-2 :foreground ,elune-bg-3))))
   `(whitespace-trailing ((t (:background ,elune-bg :foreground ,elune-str))))
   `(whitespace-empty ((t (:background ,elune-bg-3
				 :foreground ,elune-fg-2))))
   `(whitespace-indentation ((t (:background ,elune-bg-3 :foreground ,elune-fg-2))))
   `(whitespace-space-after-tab ((t (:background ,elune-bg-3 :foreground ,elune-fg-2))))
   `(whitespace-space-before-tab ((t (:background ,elune-bg-3 :foreground ,elune-fg-2))))))
;; autoload
(and load-file-name
    (boundp 'custom-theme-load-path)
    (add-to-list 'custom-theme-load-path
		 (file-name-as-directory
		  (file-name-directory load-file-name))))

(provide-theme 'elune)

;;; elune-theme.el ends here
