;;; timu-macos-theme.el --- Color theme inspired by the macOS UI -*- lexical-binding:t -*-

;; Copyright (C) 2022 Aimé Bertrand

;; Author: Aimé Bertrand <aime.bertrand@macowners.club>
;; Maintainer: Aimé Bertrand <aime.bertrand@macowners.club>
;; Created: 2023-01-03
;; Keywords: faces themes
;; Package-Version: 20230201.2203
;; Package-Commit: 665c6e409c7d6a37575b3e64961b17ae3db18cb8
;; Version: 1.2
;; Package-Requires: ((emacs "27.1"))
;; Homepage: https://gitlab.com/aimebertrand/timu-macos-theme

;; This file is not part of GNU Emacs.

;; The MIT License (MIT)
;;
;; Copyright (C) 2022 Aimé Bertrand
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
;; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
;; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:
;; Sourced other themes to get information about font faces for packages.
;;
;; I. Installation
;;   A. Manual installation
;;     1. Download the `timu-macos-theme.el' file and add it to your `custom-load-path'.
;;     2. In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (load-theme 'timu-macos t)
;;
;;   B. From Melpa
;;     1. M-x package-instal <RET> timu-macos-theme.el <RET>.
;;     2. In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (load-theme 'timu-macos t)
;;
;;   C. With use-package
;;     In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (use-package timu-macos-theme
;;         :ensure t
;;         :config
;;         (load-theme 'timu-macos t))
;;
;; II. Configuration
;;   A. Dark and light flavour
;;     By default the theme is `dark', to setup the `light' flavour:
;;
;;     - Change the variable `timu-macos-flavour' in the Customization Interface.
;;       M-x customize RET. Then Search for `timu'.
;;
;;     or
;;
;;     - add the following to your `~/.emacs.d/init.el' or `~/.emacs'
;;       (customize-set-variable 'timu-macos-flavour "light")
;;
;;   B. Scaling
;;     You can now scale some faces (in `org-mode' for now):
;;
;;     - `org-document-info'
;;     - `org-document-title'
;;     - `org-level-1'
;;     - `org-level-2'
;;     - `org-level-3'
;;
;;     More to follow in the future.
;;
;;     By default the scaling is turned off.
;;     To setup the scaling add the following to your `~/.emacs.d/init.el' or `~/.emacs':
;;
;;     1. Default scaling
;;       This will turn on default values of scaling in the theme.
;;
;;         (customize-set-variable 'timu-macos-scale-org-document-title t)
;;         (customize-set-variable 'timu-macos-scale-org-document-info t)
;;         (customize-set-variable 'timu-macos-scale-org-level-1 t)
;;         (customize-set-variable 'timu-macos-scale-org-level-2 t)
;;         (customize-set-variable 'timu-macos-scale-org-level-3 t)
;;
;;     2. Custom scaling
;;       You can choose your own scaling values as well.
;;       The following is a somewhat exaggerated example.
;;
;;         (customize-set-variable 'timu-macos-scale-org-document-title 1.8)
;;         (customize-set-variable 'timu-macos-scale-org-document-info 1.4)
;;         (customize-set-variable 'timu-macos-scale-org-level-1 1.8)
;;         (customize-set-variable 'timu-macos-scale-org-level-2 1.4)
;;         (customize-set-variable 'timu-macos-scale-org-level-3 1.2)
;;
;;   C. "Intense" colors for `org-mode'
;;     To emphasize some elements in `org-mode'.
;;     You can set a variable to make some faces more "intense".
;;
;;     By default the intense colors are turned off.
;;     To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
;;       (customize-set-variable 'timu-macos-org-intense-colors t)
;;
;;   D. Muted colors for the theme
;;     You can set muted colors for the dark flavour of the theme.
;;
;;     By default muted colors are turned off.
;;     To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
;;       (customize-set-variable 'timu-macos-muted-colors t)
;;
;;   E. Border for the `mode-line'
;;     You can set a variable to add a border to the `mode-line'.
;;
;;     By default the border is turned off.
;;     To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
;;       (customize-set-variable 'timu-macos-mode-line-border t)
;;
;; III. Utility functions
;;   A. Toggle dark and light flavour of the theme
;;       M-x timu-macos-toggle-dark-light RET.
;;
;;   B. Toggle between intense and non intense colors for `org-mode'
;;       M-x timu-macos-toggle-org-colors-intensity RET.
;;
;;   C. Toggle between borders and no borders for the `mode-line'
;;       M-x timu-macos-toggle-mode-line-border RET.


;;; Code:

(defgroup timu-macos-theme ()
  "Customise group for the \"Timu Macos\" theme."
  :group 'faces
  :prefix "timu-macos-")

(defface timu-macos-grey-face
  '((t nil))
  "Custom basic grey `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-red-face
  '((t nil))
  "Custom basic red `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-darkred-face
  '((t nil))
  "Custom basic darkred `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-orange-face
  '((t nil))
  "Custom basic orange `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-green-face
  '((t nil))
  "Custom basic green `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-blue-face
  '((t nil))
  "Custom basic blue `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-magenta-face
  '((t nil))
  "Custom basic magenta `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-teal-face
  '((t nil))
  "Custom basic teal `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-yellow-face
  '((t nil))
  "Custom basic yellow `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-darkblue-face
  '((t nil))
  "Custom basic darkblue `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-purple-face
  '((t nil))
  "Custom basic purple `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-cyan-face
  '((t nil))
  "Custom basic cyan `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-darkcyan-face
  '((t nil))
  "Custom basic darkcyan `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-black-face
  '((t nil))
  "Custom basic black `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-white-face
  '((t nil))
  "Custom basic white `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-default-face
  '((t nil))
  "Custom basic default `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-bold-face
  '((t :weight bold))
  "Custom basic bold `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-bold-face-italic
  '((t :weight bold :slant italic))
  "Custom basic bold-italic `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-italic-face
  '((((supports :slant italic)) :slant italic)
    (t :slant italic))
  "Custom basic italic `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-underline-face
  '((((supports :underline t)) :underline t)
    (t :underline t))
  "Custom basic underlined `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defface timu-macos-strike-through-face
  '((((supports :strike-through t)) :strike-through t)
    (t :strike-through t))
  "Custom basic strike-through `timu-macos-theme' face."
  :group 'timu-macos-theme)

(defcustom timu-macos-flavour "dark"
  "Variable to control the variant of the theme.
Possible values: `dark' or `light'."
  :type 'string
  :group 'timu-macos-theme)

(defcustom timu-macos-scale-org-document-info nil
  "Variable to control the scale of the `org-document-info' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-macos-theme)

(defcustom timu-macos-scale-org-document-title nil
  "Variable to control the scale of the `org-document-title' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-macos-theme)

(defcustom timu-macos-scale-org-level-1 nil
  "Variable to control the scale of the `org-level-1' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-macos-theme)

(defcustom timu-macos-scale-org-level-2 nil
  "Variable to control the scale of the `org-level-2' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-macos-theme)

(defcustom timu-macos-scale-org-level-3 nil
  "Variable to control the scale of the `org-level-3' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-macos-theme)

(defun timu-macos-do-scale (custom-height default-height)
  "Function for scaling the face to the DEFAULT-HEIGHT or CUSTOM-HEIGHT.
Uses `timu-macos-scale-faces' for the value of CUSTOM-HEIGHT."
  (cond
   ((numberp custom-height) (list :height custom-height))
   ((eq t custom-height) (list :height default-height))
   ((eq nil custom-height) (list :height 1.0))
   (t nil)))

(defcustom timu-macos-org-intense-colors nil
  "Variable to control \"intensity\" of `org-mode' header colors."
  :type 'boolean
  :group 'timu-macos-theme)

(defun timu-macos-set-intense-org-colors (overline-color background-color)
  "Function Adding intense colors to `org-mode'.
OVERLINE-COLOR changes the `overline' color.
BACKGROUND-COLOR changes the `background' color."
  (if (eq t timu-macos-org-intense-colors)
      (list :overline overline-color :background background-color)))

(defcustom timu-macos-muted-colors nil
  "Variable to set muted colors for the theme."
  :type 'boolean
  :group 'timu-macos-theme)

(defcustom timu-macos-mode-line-border nil
  "Variable to control the border of `mode-line'.
With a value of t the mode-line has a border."
  :type 'boolean
  :group 'timu-macos-theme)

(defun timu-macos-set-mode-line-active-border (boxcolor)
  "Function adding a border to the `mode-line' of the active window.
BOXCOLOR supplies the border color."
  (if (eq t timu-macos-mode-line-border)
        (list :box boxcolor)))

(defun timu-macos-set-mode-line-inactive-border (boxcolor)
  "Function adding a border to the `mode-line' of the inactive window.
BOXCOLOR supplies the border color."
  (if (eq t timu-macos-mode-line-border)
        (list :box boxcolor)))

;;;###autoload
(defun timu-macos-toggle-dark-light ()
  "Toggle between \"dark\" and \"light\" `timu-macos-flavour'."
  (interactive)
  (if (equal "dark" timu-macos-flavour)
      (customize-set-variable 'timu-macos-flavour "light")
    (customize-set-variable 'timu-macos-flavour "dark"))
  (load-theme (car custom-enabled-themes) t))

;;;###autoload
(defun timu-macos-toggle-org-colors-intensity ()
  "Toggle between intense and non intense colors for `org-mode'.
Customize `timu-macos-org-intense-colors' the to achieve this."
  (interactive)
  (if (eq t timu-macos-org-intense-colors)
      (customize-set-variable 'timu-macos-org-intense-colors nil)
    (customize-set-variable 'timu-macos-org-intense-colors t))
  (load-theme (car custom-enabled-themes) t))

;;;###autoload
(defun timu-macos-toggle-mode-line-border ()
  "Toggle between borders and no borders for the `mode-line'.
Customize `timu-macos-mode-line-border' the to achieve this."
  (interactive)
  (if (eq t timu-macos-mode-line-border)
      (customize-set-variable 'timu-macos-mode-line-border nil)
    (customize-set-variable 'timu-macos-mode-line-border t))
  (load-theme (car custom-enabled-themes) t))

(deftheme timu-macos
  "Color theme with cyan as a dominant color.
Sourced other themes to get information about font faces for packages.")

;;; DARK FLAVOUR
(when (equal timu-macos-flavour "dark")
(let ((class '((class color) (min-colors 89)))
      (bg        (if timu-macos-muted-colors "#262626" "#262626"))
      (bg-org    (if timu-macos-muted-colors "#232323" "#232323"))
      (bg-other  (if timu-macos-muted-colors "#2a2a2a" "#2a2a2a"))
      (macos0    (if timu-macos-muted-colors "#2c2c2c" "#2c2c2c"))
      (macos1    (if timu-macos-muted-colors "#393939" "#393939"))
      (macos2    (if timu-macos-muted-colors "#616161" "#616161"))
      (macos3    (if timu-macos-muted-colors "#5e5e5e" "#5e5e5e"))
      (macos4    (if timu-macos-muted-colors "#8c8c8c" "#8c8c8c"))
      (macos5    (if timu-macos-muted-colors "#b3b3b3" "#b3b3b3"))
      (macos6    (if timu-macos-muted-colors "#b3b3b3" "#b3b3b3"))
      (macos7    (if timu-macos-muted-colors "#e8e8e8" "#e8e8e8"))
      (macos8    (if timu-macos-muted-colors "#f4f4f4" "#f4f4f4"))
      (fg        (if timu-macos-muted-colors "#ffffff" "#ffffff"))
      (fg-other  (if timu-macos-muted-colors "#dedede" "#dedede"))

      (grey      (if timu-macos-muted-colors "#d2d2d2" "#8c8c8c"))
      (red       (if timu-macos-muted-colors "#ffa5a4" "#ec5f5e"))
      (darkred   (if timu-macos-muted-colors "#d7806f" "#913a29"))
      (orange    (if timu-macos-muted-colors "#ffce80" "#e8883a"))
      (green     (if timu-macos-muted-colors "#befe9c" "#78b856"))
      (blue      (if timu-macos-muted-colors "#96ebff" "#50a5eb"))
      (magenta   (if timu-macos-muted-colors "#ffa2e2" "#e45c9c"))
      (teal      (if timu-macos-muted-colors "#d7ffff" "#91f3e7"))
      (yellow    (if timu-macos-muted-colors "#ffff8a" "#f6c844"))
      (darkblue  (if timu-macos-muted-colors "#7abeff" "#3478f6"))
      (purple    (if timu-macos-muted-colors "#e19ae9" "#9b54a3"))
      (cyan      (if timu-macos-muted-colors "#ceffff" "#88c0d0"))
      (lightcyan (if timu-macos-muted-colors "#8cffff" "#46d9ff"))
      (darkcyan  (if timu-macos-muted-colors "#98ddeb" "#5297a5"))

      (black     (if timu-macos-muted-colors "#000000" "#000000"))
      (white     (if timu-macos-muted-colors "#ffffff" "#ffffff")))

  (custom-theme-set-faces
   'timu-macos

;;; Custom faces

;;;; timu-macos-faces - dark
   `(timu-macos-grey-face ((,class (:foreground ,grey))))
   `(timu-macos-red-face ((,class (:foreground ,red))))
   `(timu-macos-darkred-face ((,class (:foreground ,darkred))))
   `(timu-macos-orange-face ((,class (:foreground ,orange))))
   `(timu-macos-green-face ((,class (:foreground ,green))))
   `(timu-macos-blue-face ((,class (:foreground ,purple))))
   `(timu-macos-magenta-face ((,class (:foreground ,magenta))))
   `(timu-macos-teal-face ((,class (:foreground ,blue))))
   `(timu-macos-yellow-face ((,class (:foreground ,yellow))))
   `(timu-macos-darkblue-face ((,class (:foreground ,darkblue))))
   `(timu-macos-purple-face ((,class (:foreground ,purple))))
   `(timu-macos-cyan-face ((,class (:foreground ,cyan))))
   `(timu-macos-darkcyan-face ((,class (:foreground ,darkcyan))))
   `(timu-macos-black-face ((,class (:foreground ,black))))
   `(timu-macos-white-face ((,class (:foreground ,white))))
   `(timu-macos-default-face ((,class (:background ,bg :foreground ,fg))))
   `(timu-macos-bold-face ((,class (:weight bold :foreground ,white))))
   `(timu-macos-bold-face-italic ((,class (:weight bold :slant italic :foreground ,white))))
   `(timu-macos-italic-face ((,class (:slant italic :foreground ,white))))
   `(timu-macos-underline-face ((,class (:underline ,magenta))))
   `(timu-macos-strike-through-face ((,class (:strike-through ,magenta))))

;;;; default - dark faces
   `(bold ((,class (:weight bold))))
   `(bold-italic ((,class (:weight bold :slant italic))))
   `(bookmark-face ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(cursor ((,class (:background ,blue))))
   `(default ((,class (:background ,bg :foreground ,fg))))
   `(error ((,class (:foreground ,red))))
   `(fringe ((,class (:foreground ,macos4))))
   `(highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(italic ((,class (:slant  italic))))
   `(lazy-highlight ((,class (:background ,darkblue  :foreground ,macos8 :distant-foreground ,macos0 :weight bold))))
   `(link ((,class (:foreground ,blue :underline t :weight bold))))
   `(match ((,class (:foreground ,green :background ,macos0 :weight bold))))
   `(minibuffer-prompt ((,class (:foreground ,red))))
   `(nobreak-space ((,class (:background ,bg :foreground ,fg))))
   `(region ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
   `(secondary-selection ((,class (:background ,grey :extend t))))
   `(shadow ((,class (:foreground ,macos5))))
   `(success ((,class (:foreground ,green))))
   `(tooltip ((,class (:background ,bg-other :foreground ,fg))))
   `(trailing-whitespace ((,class (:background ,red))))
   `(vertical-border ((,class (:background ,blue :foreground ,blue))))
   `(warning ((,class (:foreground ,yellow))))

;;;; font-lock - dark
   `(font-lock-builtin-face ((,class (:foreground ,blue))))
   `(font-lock-comment-delimiter-face ((,class (:foreground ,macos4))))
   `(font-lock-comment-face ((,class (:foreground ,macos4 :slant italic))))
   `(font-lock-constant-face ((,class (:foreground ,red))))
   `(font-lock-doc-face ((,class (:foreground ,grey :slant italic))))
   `(font-lock-function-name-face ((,class (:foreground ,teal))))
   `(font-lock-keyword-face ((,class (:foreground ,blue))))
   `(font-lock-negation-char-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-preprocessor-char-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-preprocessor-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-regexp-grouping-backslash ((,class (:foreground ,fg :weight bold))))
   `(font-lock-regexp-grouping-construct ((,class (:foreground ,fg :weight bold))))
   `(font-lock-string-face ((,class (:foreground ,green))))
   `(font-lock-type-face ((,class (:foreground ,blue))))
   `(font-lock-variable-name-face ((,class (:foreground ,magenta))))
   `(font-lock-warning-face ((,class (:foreground ,yellow))))

;;;; ace-window - dark
   `(aw-leading-char-face ((,class (:foreground ,red :height 500 :weight bold))))
   `(aw-background-face ((,class (:foreground ,macos5))))

;;;; alert - dark
   `(alert-high-face ((,class (:foreground ,yellow :weight bold))))
   `(alert-low-face ((,class (:foreground ,grey))))
   `(alert-moderate-face ((,class (:foreground ,fg-other :weight bold))))
   `(alert-trivial-face ((,class (:foreground ,macos5))))
   `(alert-urgent-face ((,class (:foreground ,red :weight bold))))

;;;; all-the-icons - dark
   `(all-the-icons-blue ((,class (:foreground ,purple))))
   `(all-the-icons-blue-alt ((,class (:foreground ,blue))))
   `(all-the-icons-cyan ((,class (:foreground ,darkblue))))
   `(all-the-icons-cyan-alt ((,class (:foreground ,darkblue))))
   `(all-the-icons-dblue ((,class (:foreground ,darkblue))))
   `(all-the-icons-dcyan ((,class (:foreground ,darkcyan))))
   `(all-the-icons-dgreen ((,class (:foreground ,green))))
   `(all-the-icons-dmagenta ((,class (:foreground ,red))))
   `(all-the-icons-dmaroon ((,class (:foreground ,teal))))
   `(all-the-icons-dorange ((,class (:foreground ,blue))))
   `(all-the-icons-dpurple ((,class (:foreground ,magenta))))
   `(all-the-icons-dred ((,class (:foreground ,red))))
   `(all-the-icons-dsilver ((,class (:foreground ,grey))))
   `(all-the-icons-dyellow ((,class (:foreground ,yellow))))
   `(all-the-icons-green ((,class (:foreground ,green))))
   `(all-the-icons-lblue ((,class (:foreground ,purple))))
   `(all-the-icons-lcyan ((,class (:foreground ,darkblue))))
   `(all-the-icons-lgreen ((,class (:foreground ,green))))
   `(all-the-icons-lmagenta ((,class (:foreground ,red))))
   `(all-the-icons-lmaroon ((,class (:foreground ,teal))))
   `(all-the-icons-lorange ((,class (:foreground ,blue))))
   `(all-the-icons-lpurple ((,class (:foreground ,magenta))))
   `(all-the-icons-lred ((,class (:foreground ,red))))
   `(all-the-icons-lsilver ((,class (:foreground ,grey))))
   `(all-the-icons-lyellow ((,class (:foreground ,yellow))))
   `(all-the-icons-magenta ((,class (:foreground ,red))))
   `(all-the-icons-maroon ((,class (:foreground ,teal))))
   `(all-the-icons-orange ((,class (:foreground ,blue))))
   `(all-the-icons-purple ((,class (:foreground ,magenta))))
   `(all-the-icons-purple-alt ((,class (:foreground ,magenta))))
   `(all-the-icons-red ((,class (:foreground ,red))))
   `(all-the-icons-red-alt ((,class (:foreground ,red))))
   `(all-the-icons-silver ((,class (:foreground ,grey))))
   `(all-the-icons-yellow ((,class (:foreground ,yellow))))
   `(all-the-icons-ibuffer-mode-face ((,class (:foreground ,purple))))
   `(all-the-icons-ibuffer-dir-face ((,class (:foreground ,cyan))))
   `(all-the-icons-ibuffer-file-face ((,class (:foreground ,blue))))
   `(all-the-icons-ibuffer-icon-face ((,class (:foreground ,magenta))))
   `(all-the-icons-ibuffer-size-face ((,class (:foreground ,yellow))))

;;;; all-the-icons-dired - dark
   `(all-the-icons-dired-dir-face ((,class (:foreground ,fg-other))))

;;;; all-the-icons-ivy-rich - dark
   `(all-the-icons-ivy-rich-doc-face ((,class (:foreground ,purple))))
   `(all-the-icons-ivy-rich-path-face ((,class (:foreground ,purple))))
   `(all-the-icons-ivy-rich-size-face ((,class (:foreground ,purple))))
   `(all-the-icons-ivy-rich-time-face ((,class (:foreground ,purple))))

;;;; annotate - dark
   `(annotate-annotation ((,class (:background ,red :foreground ,macos5))))
   `(annotate-annotation-secondary ((,class (:background ,green :foreground ,macos5))))
   `(annotate-highlight ((,class (:background ,red :underline ,red))))
   `(annotate-highlight-secondary ((,class (:background ,green :underline ,green))))

;;;; ansi - dark
   `(ansi-color-black ((,class (:foreground ,macos0))))
   `(ansi-color-blue ((,class (:foreground ,purple))))
   `(ansi-color-cyan ((,class (:foreground ,darkblue))))
   `(ansi-color-green ((,class (:foreground ,green))))
   `(ansi-color-magenta ((,class (:foreground ,magenta))))
   `(ansi-color-purple ((,class (:foreground ,teal))))
   `(ansi-color-red ((,class (:foreground ,red))))
   `(ansi-color-white ((,class (:foreground ,macos8))))
   `(ansi-color-yellow ((,class (:foreground ,yellow))))
   `(ansi-color-bright-black ((,class (:foreground ,macos0))))
   `(ansi-color-bright-blue ((,class (:foreground ,purple))))
   `(ansi-color-bright-cyan ((,class (:foreground ,darkblue))))
   `(ansi-color-bright-green ((,class (:foreground ,green))))
   `(ansi-color-bright-magenta ((,class (:foreground ,magenta))))
   `(ansi-color-bright-purple ((,class (:foreground ,teal))))
   `(ansi-color-bright-red ((,class (:foreground ,red))))
   `(ansi-color-bright-white ((,class (:foreground ,macos8))))
   `(ansi-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; anzu - dark
   `(anzu-replace-highlight ((,class (:background ,macos0 :foreground ,red :weight bold :strike-through t))))
   `(anzu-replace-to ((,class (:background ,macos0 :foreground ,green :weight bold))))

;;;; auctex - dark
   `(TeX-error-description-error ((,class (:foreground ,red :weight bold))))
   `(TeX-error-description-tex-said ((,class (:foreground ,green :weight bold))))
   `(TeX-error-description-warning ((,class (:foreground ,yellow :weight bold))))
   `(font-latex-bold-face ((,class (:weight bold))))
   `(font-latex-italic-face ((,class (:slant italic))))
   `(font-latex-math-face ((,class (:foreground ,purple))))
   `(font-latex-script-char-face ((,class (:foreground ,blue))))
   `(font-latex-sedate-face ((,class (:foreground ,blue))))
   `(font-latex-sectioning-0-face ((,class (:foreground ,orange :weight ultra-bold))))
   `(font-latex-sectioning-1-face ((,class (:foreground ,teal :weight semi-bold))))
   `(font-latex-sectioning-2-face ((,class (:foreground ,magenta :weight semi-bold))))
   `(font-latex-sectioning-3-face ((,class (:foreground ,orange :weight semi-bold))))
   `(font-latex-sectioning-4-face ((,class (:foreground ,teal :weight semi-bold))))
   `(font-latex-sectioning-5-face ((,class (:foreground ,magenta :weight semi-bold))))
   `(font-latex-string-face ((,class (:foreground ,green))))
   `(font-latex-verbatim-face ((,class (:foreground ,cyan :slant italic))))
   `(font-latex-warning-face ((,class (:foreground ,yellow))))

;;;; avy - dark
   `(avy-background-face ((,class (:foreground ,macos5))))
   `(avy-lead-face ((,class (:background ,magenta :foreground ,black))))
   `(avy-lead-face-0 ((,class (:background ,magenta :foreground ,black))))
   `(avy-lead-face-1 ((,class (:background ,magenta :foreground ,black))))
   `(avy-lead-face-2 ((,class (:background ,magenta :foreground ,black))))

;;;; bookmark+ - dark
   `(bmkp-*-mark ((,class (:foreground ,bg :background ,yellow))))
   `(bmkp->-mark ((,class (:foreground ,yellow))))
   `(bmkp-D-mark ((,class (:foreground ,bg :background ,red))))
   `(bmkp-X-mark ((,class (:foreground ,red))))
   `(bmkp-a-mark ((,class (:background ,red))))
   `(bmkp-bad-bookmark ((,class (:foreground ,bg :background ,yellow))))
   `(bmkp-bookmark-file ((,class (:foreground ,magenta :background ,bg-other))))
   `(bmkp-bookmark-list ((,class (:background ,bg-other))))
   `(bmkp-buffer ((,class (:foreground ,purple))))
   `(bmkp-desktop ((,class (:foreground ,bg :background ,magenta))))
   `(bmkp-file-handler ((,class (:background ,red))))
   `(bmkp-function ((,class (:foreground ,green))))
   `(bmkp-gnus ((,class (:foreground ,red))))
   `(bmkp-heading ((,class (:foreground ,yellow))))
   `(bmkp-info ((,class (:foreground ,darkblue))))
   `(bmkp-light-autonamed ((,class (:foreground ,bg-other :background ,darkblue))))
   `(bmkp-light-autonamed-region ((,class (:foreground ,bg-other :background ,red))))
   `(bmkp-light-fringe-autonamed ((,class (:foreground ,bg-other :background ,magenta))))
   `(bmkp-light-fringe-non-autonamed ((,class (:foreground ,bg-other :background ,green))))
   `(bmkp-light-mark ((,class (:foreground ,bg :background ,darkblue))))
   `(bmkp-light-non-autonamed ((,class (:foreground ,bg :background ,magenta))))
   `(bmkp-light-non-autonamed-region ((,class (:foreground ,bg :background ,red))))
   `(bmkp-local-directory ((,class (:foreground ,bg :background ,magenta))))
   `(bmkp-local-file-with-region ((,class (:foreground ,yellow))))
   `(bmkp-local-file-without-region ((,class (:foreground ,macos5))))
   `(bmkp-man ((,class (:foreground ,magenta))))
   `(bmkp-no-jump ((,class (:foreground ,macos5))))
   `(bmkp-no-local ((,class (:foreground ,yellow))))
   `(bmkp-non-file ((,class (:foreground ,green))))
   `(bmkp-remote-file ((,class (:foreground ,red))))
   `(bmkp-sequence ((,class (:foreground ,purple))))
   `(bmkp-su-or-sudo ((,class (:foreground ,red))))
   `(bmkp-t-mark ((,class (:foreground ,magenta))))
   `(bmkp-url ((,class (:foreground ,purple :underline t))))
   `(bmkp-variable-list ((,class (:foreground ,green))))

;;;; calfw - dark
   `(cfw:face-annotation ((,class (:foreground ,magenta))))
   `(cfw:face-day-title ((,class (:foreground ,fg :weight bold))))
   `(cfw:face-default-content ((,class (:foreground ,fg))))
   `(cfw:face-default-day ((,class (:weight bold))))
   `(cfw:face-disable ((,class (:foreground ,grey))))
   `(cfw:face-grid ((,class (:foreground ,bg))))
   `(cfw:face-header ((,class (:foreground ,purple :weight bold))))
   `(cfw:face-holiday ((,class (:foreground nil :background ,bg-other :weight bold))))
   `(cfw:face-periods ((,class (:foreground ,yellow))))
   `(cfw:face-saturday ((,class (:foreground ,red :weight bold))))
   `(cfw:face-select ((,class (:background ,grey))))
   `(cfw:face-sunday ((,class (:foreground ,red :weight bold))))
   `(cfw:face-title ((,class (:foreground ,purple :weight bold :height 2.0))))
   `(cfw:face-today ((,class (:foreground nil :background nil :weight bold))))
   `(cfw:face-today-title ((,class (:foreground ,bg :background ,purple :weight bold))))
   `(cfw:face-toolbar ((,class (:foreground nil :background nil))))
   `(cfw:face-toolbar-button-off ((,class (:foreground ,macos6 :weight bold))))
   `(cfw:face-toolbar-button-on ((,class (:foreground ,purple :weight bold))))

;;;; centaur-tabs - dark
   `(centaur-tabs-active-bar-face ((,class (:background ,bg :foreground ,fg))))
   `(centaur-tabs-close-mouse-face ((,class (:foreground ,magenta))))
   `(centaur-tabs-close-selected ((,class (:background ,bg :foreground ,fg))))
   `(centaur-tabs-close-unselected ((,class (:background ,bg-other :foreground ,grey))))
   `(centaur-tabs-default ((,class (:background ,bg-other :foreground ,fg))))
   `(centaur-tabs-modified-marker-selected ((,class (:background ,bg :foreground ,blue))))
   `(centaur-tabs-modified-marker-unselected ((,class (:background ,bg :foreground ,blue))))
   `(centaur-tabs-name-mouse-face ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(centaur-tabs-selected ((,class (:background ,bg :foreground ,blue))))
   `(centaur-tabs-selected-modified ((,class (:background ,bg :foreground ,magenta))))
   `(centaur-tabs-unselected ((,class (:background ,bg-other :foreground ,grey))))
   `(centaur-tabs-unselected-modified ((,class (:background ,bg-other :foreground ,magenta))))

;;;; circe - dark
   `(circe-fool ((,class (:foreground ,macos5))))
   `(circe-highlight-nick-face ((,class (:weight bold :foreground ,blue))))
   `(circe-my-message-face ((,class (:weight bold))))
   `(circe-prompt-face ((,class (:weight bold :foreground ,blue))))
   `(circe-server-face ((,class (:foreground ,macos5))))

;;;; company - dark
   `(company-preview ((,class (:background ,bg-other :foreground ,macos5))))
   `(company-preview-common ((,class (:background ,macos3 :foreground ,cyan))))
   `(company-preview-search ((,class (:background ,cyan :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(company-scrollbar-bg ((,class (:background ,bg-other :foreground ,fg))))
   `(company-scrollbar-fg ((,class (:background ,cyan))))
   `(company-template-field ((,class (:foreground ,green :background ,macos0 :weight bold))))
   `(company-tooltip ((,class (:background ,bg-other :foreground ,fg))))
   `(company-tooltip-annotation ((,class (:foreground ,magenta :distant-foreground ,bg))))
   `(company-tooltip-common ((,class (:foreground ,cyan :distant-foreground ,macos0 :weight bold))))
   `(company-tooltip-mouse ((,class (:background ,teal :foreground ,bg :distant-foreground ,fg))))
   `(company-tooltip-search ((,class (:background ,cyan :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(company-tooltip-search-selection ((,class (:background ,grey))))
   `(company-tooltip-selection ((,class (:background ,grey :weight bold))))

;;;; company-box - dark
   `(company-box-candidate ((,class (:foreground ,fg))))

;;;; compilation - dark
   `(compilation-column-number ((,class (:foreground ,macos5))))
   `(compilation-error ((,class (:foreground ,red :weight bold))))
   `(compilation-info ((,class (:foreground ,green))))
   `(compilation-line-number ((,class (:foreground ,red))))
   `(compilation-mode-line-exit ((,class (:foreground ,green))))
   `(compilation-mode-line-fail ((,class (:foreground ,red :weight bold))))
   `(compilation-warning ((,class (:foreground ,yellow :slant italic))))

;;;; consult - dark
   `(consult-file ((,class (:foreground ,blue))))

;;;; corfu - dark
   `(corfu-bar ((,class (:background ,bg-org :foreground ,fg))))
   `(corfu-echo ((,class (:foreground ,magenta))))
   `(corfu-border ((,class (:background ,macos2 :foreground ,fg))))
   `(corfu-current ((,class (:foreground ,magenta :weight bold :underline ,fg))))
   `(corfu-default ((,class (:background ,bg-org :foreground ,fg))))
   `(corfu-deprecated ((,class (:foreground ,blue))))
   `(corfu-annotations ((,class (:foreground ,magenta))))

;;;; counsel - dark
   `(counsel-variable-documentation ((,class (:foreground ,purple))))

;;;; cperl - dark
   `(cperl-array-face ((,class (:foreground ,red :weight bold))))
   `(cperl-hash-face ((,class (:foreground ,red :weight bold :slant italic))))
   `(cperl-nonoverridable-face ((,class (:foreground ,cyan))))

;;;; custom - dark
   `(custom-button ((,class (:foreground ,fg :background ,bg-other :box (:line-width 3 :style released-button)))))
   `(custom-button-mouse ((,class (:foreground ,yellow :background ,bg-other :box (:line-width 3 :style released-button)))))
   `(custom-button-pressed ((,class (:foreground ,bg :background ,bg-other :box (:line-width 3 :style pressed-button)))))
   `(custom-button-pressed-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
   `(custom-button-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
   `(custom-changed ((,class (:foreground ,purple :background ,bg))))
   `(custom-comment ((,class (:foreground ,fg :background ,grey))))
   `(custom-comment-tag ((,class (:foreground ,grey))))
   `(custom-documentation ((,class (:foreground ,fg))))
   `(custom-face-tag ((,class (:foreground ,purple :weight bold))))
   `(custom-group-subtitle ((,class (:foreground ,magenta :weight bold))))
   `(custom-group-tag ((,class (:foreground ,magenta :weight bold))))
   `(custom-group-tag-1 ((,class (:foreground ,purple))))
   `(custom-invalid ((,class (:foreground ,red))))
   `(custom-link ((,class (:foreground ,cyan :underline t))))
   `(custom-modified ((,class (:foreground ,purple))))
   `(custom-rogue ((,class (:foreground ,purple :box (:line-width 3 :style none)))))
   `(custom-saved ((,class (:foreground ,green :weight bold))))
   `(custom-set ((,class (:foreground ,yellow :background ,bg))))
   `(custom-state ((,class (:foreground ,green))))
   `(custom-themed ((,class (:foreground ,yellow :background ,bg))))
   `(custom-variable-button ((,class (:foreground ,green :underline t))))
   `(custom-variable-obsolete ((,class (:foreground ,grey :background ,bg))))
   `(custom-variable-tag ((,class (:foreground ,darkcyan :underline t :extend nil))))
   `(custom-visibility ((,class (:foreground ,yellow :height 0.8 :underline t))))

;;; diff
   `(diff-added ((,class (:foreground ,bg :background ,green :extend t))))
   `(diff-indicator-added ((,class (:foreground ,bg :weight bold :background ,green :extend t))))
   `(diff-refine-added ((,class (:foreground ,bg :weight bold :background ,green :extend t))))
   `(diff-changed ((,class (:foreground ,bg :background ,yellow :extend t))))
   `(diff-indicator-changed ((,class (:foreground ,bg :weight bold :background ,yellow :extend t))))
   `(diff-refine-changed ((,class (:foreground ,bg :weight bold :background ,yellow :extend t))))
   `(diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
   `(diff-indicator-removed ((,class (:foreground ,bg :weight bold :background ,red :extend t))))
   `(diff-refine-removed ((,class (:foreground ,bg :weight bold :background ,red :extend t))))
   `(diff-header ((,class (:foreground ,darkcyan))))
   `(diff-file-header ((,class (:foreground ,blue :weight bold))))
   `(diff-hunk-header ((,class (:foreground ,bg :background ,magenta :extend t))))
   `(diff-function ((,class (:foreground ,bg :background ,magenta :extend t))))

;;;; diff-hl - dark
   `(diff-hl-change ((,class (:foreground ,blue :background ,blue))))
   `(diff-hl-delete ((,class (:foreground ,red :background ,red))))
   `(diff-hl-insert ((,class (:foreground ,green :background ,green))))

;;;; dired - dark
   `(dired-directory ((,class (:foreground ,blue :underline ,blue))))
   `(dired-flagged ((,class (:foreground ,red))))
   `(dired-header ((,class (:foreground ,cyan :weight bold :underline ,darkcyan))))
   `(dired-ignored ((,class (:foreground ,macos5))))
   `(dired-mark ((,class (:foreground ,cyan :weight bold))))
   `(dired-marked ((,class (:foreground ,yellow :weight bold))))
   `(dired-perm-write ((,class (:foreground ,red :underline t))))
   `(dired-symlink ((,class (:foreground ,magenta))))
   `(dired-warning ((,class (:foreground ,yellow))))

;;;; dired-async - dark
   `(dired-async-failures ((,class (:foreground ,red))))
   `(dired-async-message ((,class (:foreground ,cyan))))
   `(dired-async-mode-message ((,class (:foreground ,cyan))))

;;;; dired-filetype-face - dark
   `(dired-filetype-common ((,class (:foreground ,fg))))
   `(dired-filetype-compress ((,class (:foreground ,yellow))))
   `(dired-filetype-document ((,class (:foreground ,cyan))))
   `(dired-filetype-execute ((,class (:foreground ,red))))
   `(dired-filetype-image ((,class (:foreground ,orange))))
   `(dired-filetype-js ((,class (:foreground ,yellow))))
   `(dired-filetype-link ((,class (:foreground ,magenta))))
   `(dired-filetype-music ((,class (:foreground ,magenta))))
   `(dired-filetype-omit ((,class (:foreground ,purple))))
   `(dired-filetype-plain ((,class (:foreground ,fg))))
   `(dired-filetype-program ((,class (:foreground ,red))))
   `(dired-filetype-source ((,class (:foreground ,green))))
   `(dired-filetype-video ((,class (:foreground ,magenta))))
   `(dired-filetype-xml ((,class (:foreground ,green))))

;;;; dired - dark+
   `(diredp-compressed-file-suffix ((,class (:foreground ,macos5))))
   `(diredp-date-time ((,class (:foreground ,purple))))
   `(diredp-dir-heading ((,class (:foreground ,purple :weight bold))))
   `(diredp-dir-name ((,class (:foreground ,macos8 :weight bold))))
   `(diredp-dir-priv ((,class (:foreground ,purple :weight bold))))
   `(diredp-exec-priv ((,class (:foreground ,yellow))))
   `(diredp-file-name ((,class (:foreground ,macos8))))
   `(diredp-file-suffix ((,class (:foreground ,magenta))))
   `(diredp-ignored-file-name ((,class (:foreground ,macos5))))
   `(diredp-no-priv ((,class (:foreground ,macos5))))
   `(diredp-number ((,class (:foreground ,teal))))
   `(diredp-rare-priv ((,class (:foreground ,red :weight bold))))
   `(diredp-read-priv ((,class (:foreground ,teal))))
   `(diredp-symlink ((,class (:foreground ,magenta))))
   `(diredp-write-priv ((,class (:foreground ,green))))

;;;; dired-k - dark
   `(dired-k-added ((,class (:foreground ,green :weight bold))))
   `(dired-k-commited ((,class (:foreground ,green :weight bold))))
   `(dired-k-directory ((,class (:foreground ,purple :weight bold))))
   `(dired-k-ignored ((,class (:foreground ,macos5 :weight bold))))
   `(dired-k-modified ((,class (:foreground , :weight bold))))
   `(dired-k-untracked ((,class (:foreground ,orange :weight bold))))

;;;; dired-subtree - dark
   `(dired-subtree-depth-1-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-2-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-3-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-4-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-5-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-6-face ((,class (:background ,bg-other))))

;;;; diredfl - dark
   `(diredfl-autofile-name ((,class (:foreground ,macos4))))
   `(diredfl-compressed-file-name ((,class (:foreground ,blue))))
   `(diredfl-compressed-file-suffix ((,class (:foreground ,yellow))))
   `(diredfl-date-time ((,class (:foreground ,darkblue :weight light))))
   `(diredfl-deletion ((,class (:foreground ,red :weight bold))))
   `(diredfl-deletion-file-name ((,class (:foreground ,red))))
   `(diredfl-dir-heading ((,class (:foreground ,purple :weight bold))))
   `(diredfl-dir-name ((,class (:foreground ,darkcyan))))
   `(diredfl-dir-priv ((,class (:foreground ,purple))))
   `(diredfl-exec-priv ((,class (:foreground ,red))))
   `(diredfl-executable-tag ((,class (:foreground ,red))))
   `(diredfl-file-name ((,class (:foreground ,fg))))
   `(diredfl-file-suffix ((,class (:foreground ,orange))))
   `(diredfl-flag-mark ((,class (:foreground ,yellow :background ,yellow :weight bold))))
   `(diredfl-flag-mark-line ((,class (:background ,yellow))))
   `(diredfl-ignored-file-name ((,class (:foreground ,macos5))))
   `(diredfl-link-priv ((,class (:foreground ,magenta))))
   `(diredfl-no-priv ((,class (:foreground ,fg))))
   `(diredfl-number ((,class (:foreground ,blue))))
   `(diredfl-other-priv ((,class (:foreground ,teal))))
   `(diredfl-rare-priv ((,class (:foreground ,fg))))
   `(diredfl-read-priv ((,class (:foreground ,yellow))))
   `(diredfl-symlink ((,class (:foreground ,magenta))))
   `(diredfl-tagged-autofile-name ((,class (:foreground ,macos5))))
   `(diredfl-write-priv ((,class (:foreground ,red))))

;;;; doom-modeline - dark
   `(doom-modeline-bar ((,class (:foreground ,magenta))))
   `(doom-modeline-bar-inactive ((,class (:background nil))))
   `(doom-modeline-buffer-major-mode ((,class (:foreground ,magenta))))
   `(doom-modeline-buffer-path ((,class (:foreground ,magenta))))
   `(doom-modeline-eldoc-bar ((,class (:background ,green))))
   `(doom-modeline-evil-emacs-state ((,class (:foreground ,darkblue :weight bold))))
   `(doom-modeline-evil-insert-state ((,class (:foreground ,red :weight bold))))
   `(doom-modeline-evil-motion-state ((,class (:foreground ,purple :weight bold))))
   `(doom-modeline-evil-normal-state ((,class (:foreground ,green :weight bold))))
   `(doom-modeline-evil-operator-state ((,class (:foreground ,magenta :weight bold))))
   `(doom-modeline-evil-replace-state ((,class (:foreground ,teal :weight bold))))
   `(doom-modeline-evil-visual-state ((,class (:foreground ,yellow :weight bold))))
   `(doom-modeline-highlight ((,class (:foreground ,magenta))))
   `(doom-modeline-input-method ((,class (:foreground ,magenta))))
   `(doom-modeline-panel ((,class (:foreground ,magenta))))
   `(doom-modeline-project-dir ((,class (:foreground ,blue :weight bold))))
   `(doom-modeline-project-root-dir ((,class (:foreground ,magenta))))

;;;; ediff - dark
   `(ediff-current-diff-A ((,class (:foreground ,bg :background ,red :extend t))))
   `(ediff-current-diff-B ((,class (:foreground ,bg :background ,green :extend t))))
   `(ediff-current-diff-C ((,class (:foreground ,bg :background ,yellow :extend t))))
   `(ediff-even-diff-A ((,class (:background ,bg-other :extend t))))
   `(ediff-even-diff-B ((,class (:background ,bg-other :extend t))))
   `(ediff-even-diff-C ((,class (:background ,bg-other :extend t))))
   `(ediff-fine-diff-A ((,class (:background ,red :weight bold :underline t :extend t))))
   `(ediff-fine-diff-B ((,class (:background ,green :weight bold :underline t :extend t))))
   `(ediff-fine-diff-C ((,class (:background ,yellow :weight bold :underline t :extend t))))
   `(ediff-odd-diff-A ((,class (:background ,bg-other :extend t))))
   `(ediff-odd-diff-B ((,class (:background ,bg-other :extend t))))
   `(ediff-odd-diff-C ((,class (:background ,bg-other :extend t))))

;;;; elfeed - dark
   `(elfeed-log-debug-level-face ((,class (:foreground ,macos5))))
   `(elfeed-log-error-level-face ((,class (:foreground ,red))))
   `(elfeed-log-info-level-face ((,class (:foreground ,green))))
   `(elfeed-log-warn-level-face ((,class (:foreground ,yellow))))
   `(elfeed-search-date-face ((,class (:foreground ,cyan))))
   `(elfeed-search-feed-face ((,class (:foreground ,blue))))
   `(elfeed-search-filter-face ((,class (:foreground ,magenta))))
   `(elfeed-search-tag-face ((,class (:foreground ,macos5))))
   `(elfeed-search-title-face ((,class (:foreground ,macos5))))
   `(elfeed-search-unread-count-face ((,class (:foreground ,yellow))))
   `(elfeed-search-unread-title-face ((,class (:foreground ,fg :weight bold))))

;;;; elixir-mode - dark
   `(elixir-atom-face ((,class (:foreground ,darkblue))))
   `(elixir-attribute-face ((,class (:foreground ,magenta))))

;;;; elscreen - dark
   `(elscreen-tab-background-face ((,class (:background ,bg))))
   `(elscreen-tab-control-face ((,class (:background ,bg :foreground ,bg))))
   `(elscreen-tab-current-screen-face ((,class (:background ,bg-other :foreground ,fg))))
   `(elscreen-tab-other-screen-face ((,class (:background ,bg :foreground ,fg-other))))

;;;; enh-ruby-mode - dark
   `(enh-ruby-heredoc-delimiter-face ((,class (:foreground ,blue))))
   `(enh-ruby-op-face ((,class (:foreground ,fg))))
   `(enh-ruby-regexp-delimiter-face ((,class (:foreground ,blue))))
   `(enh-ruby-regexp-face ((,class (:foreground ,blue))))
   `(enh-ruby-string-delimiter-face ((,class (:foreground ,blue))))
   `(erm-syn-errline ((,class (:underline (:style wave :color ,red)))))
   `(erm-syn-warnline ((,class (:underline (:style wave :color ,yellow)))))

;;;; erc - dark
   `(erc-action-face  ((,class (:weight bold))))
   `(erc-button ((,class (:weight bold :underline t))))
   `(erc-command-indicator-face ((,class (:weight bold))))
   `(erc-current-nick-face ((,class (:foreground ,green :weight bold))))
   `(erc-default-face ((,class (:background ,bg :foreground ,fg))))
   `(erc-direct-msg-face ((,class (:foreground ,teal))))
   `(erc-error-face ((,class (:foreground ,red))))
   `(erc-header-line ((,class (:background ,bg-other :foreground ,blue))))
   `(erc-input-face ((,class (:foreground ,green))))
   `(erc-my-nick-face ((,class (:foreground ,green :weight bold))))
   `(erc-my-nick-prefix-face ((,class (:foreground ,green :weight bold))))
   `(erc-nick-default-face ((,class (:weight bold))))
   `(erc-nick-msg-face ((,class (:foreground ,teal))))
   `(erc-nick-prefix-face ((,class (:background ,bg :foreground ,fg))))
   `(erc-notice-face ((,class (:foreground ,macos5))))
   `(erc-prompt-face ((,class (:foreground ,blue :weight bold))))
   `(erc-timestamp-face ((,class (:foreground ,purple :weight bold))))

;;;; eshell - dark
   `(eshell-ls-archive ((,class (:foreground ,yellow))))
   `(eshell-ls-backup ((,class (:foreground ,yellow))))
   `(eshell-ls-clutter ((,class (:foreground ,red))))
   `(eshell-ls-directory ((,class (:foreground ,blue))))
   `(eshell-ls-executable ((,class (:foreground ,red))))
   `(eshell-ls-missing ((,class (:foreground ,red))))
   `(eshell-ls-product ((,class (:foreground ,blue))))
   `(eshell-ls-readonly ((,class (:foreground ,blue))))
   `(eshell-ls-special ((,class (:foreground ,magenta))))
   `(eshell-ls-symlink ((,class (:foreground ,magenta))))
   `(eshell-ls-unreadable ((,class (:foreground ,macos5))))
   `(eshell-prompt ((,class (:foreground ,cyan :weight bold))))

;;;; evil - dark
   `(evil-ex-info ((,class (:foreground ,red :slant italic))))
   `(evil-ex-search ((,class (:background ,blue :foreground ,macos0 :weight bold))))
   `(evil-ex-substitute-matches ((,class (:background ,macos0 :foreground ,red :weight bold :strike-through t))))
   `(evil-ex-substitute-replacement ((,class (:background ,macos0 :foreground ,green :weight bold))))
   `(evil-search-highlight-persist-highlight-face ((,class (:background ,darkblue  :foreground ,macos8 :distant-foreground ,macos0 :weight bold))))

;;;; evil-googles - dark
   `(evil-goggles-default-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-mc - dark
   `(evil-mc-cursor-bar-face ((,class (:height 1 :background ,teal :foreground ,macos0))))
   `(evil-mc-cursor-default-face ((,class (:background ,teal :foreground ,macos0 :inverse-video nil))))
   `(evil-mc-cursor-hbar-face ((,class (:underline (:color ,blue)))))
   `(evil-mc-region-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-snipe - dark
   `(evil-snipe-first-match-face ((,class (:foreground ,red :background ,darkblue :weight bold))))
   `(evil-snipe-matches-face ((,class (:foreground ,red :underline t :weight bold))))

;;;; expenses - dark
   `(expenses-face-date ((,class (:foreground ,red :weight bold))))
   `(expenses-face-expence ((,class (:foreground ,green :weight bold))))
   `(expenses-face-message ((,class (:foreground ,blue :weight bold))))

;;;; flx-ido - dark
   `(flx-highlight-face ((,class (:weight bold :foreground ,yellow :underline nil))))

;;;; flycheck - dark
   `(flycheck-error ((,class (:underline (:style wave :color ,red)))))
   `(flycheck-fringe-error ((,class (:foreground ,red))))
   `(flycheck-fringe-info ((,class (:foreground ,green))))
   `(flycheck-fringe-warning ((,class (:foreground ,yellow))))
   `(flycheck-info ((,class (:underline (:style wave :color ,green)))))
   `(flycheck-warning ((,class (:underline (:style wave :color ,yellow)))))

;;;; flycheck-posframe - dark
   `(flycheck-posframe-background-face ((,class (:background ,bg-other))))
   `(flycheck-posframe-error-face ((,class (:foreground ,red))))
   `(flycheck-posframe-face ((,class (:background ,bg :foreground ,fg))))
   `(flycheck-posframe-info-face ((,class (:background ,bg :foreground ,fg))))
   `(flycheck-posframe-warning-face ((,class (:foreground ,yellow))))

;;;; flymake - dark
   `(flymake-error ((,class (:underline (:style wave :color ,red)))))
   `(flymake-note ((,class (:underline (:style wave :color ,green)))))
   `(flymake-warning ((,class (:underline (:style wave :color ,blue)))))

;;;; flyspell - dark
   `(flyspell-duplicate ((,class (:underline (:style wave :color ,yellow)))))
   `(flyspell-incorrect ((,class (:underline (:style wave :color ,red)))))

;;;; forge - dark
   `(forge-topic-closed ((,class (:foreground ,macos5 :strike-through t))))
   `(forge-topic-label ((,class (:box nil))))

;;;; git-commit - dark
   `(git-commit-comment-branch-local ((,class (:foreground ,teal))))
   `(git-commit-comment-branch-remote ((,class (:foreground ,green))))
   `(git-commit-comment-detached ((,class (:foreground ,cyan))))
   `(git-commit-comment-file ((,class (:foreground ,magenta))))
   `(git-commit-comment-heading ((,class (:foreground ,magenta))))
   `(git-commit-keyword ((,class (:foreground ,darkblue :slant italic))))
   `(git-commit-known-pseudo-header ((,class (:foreground ,macos5 :weight bold :slant italic))))
   `(git-commit-nonempty-second-line ((,class (:foreground ,red))))
   `(git-commit-overlong-summary ((,class (:foreground ,red :slant italic :weight bold))))
   `(git-commit-pseudo-header ((,class (:foreground ,macos5 :slant italic))))
   `(git-commit-summary ((,class (:foreground ,blue))))

;;;; git-gutter - dark
   `(git-gutter:added ((,class (:foreground ,green))))
   `(git-gutter:deleted ((,class (:foreground ,red))))
   `(git-gutter:modified ((,class (:foreground ,darkblue))))

;;;; git-gutter - dark+
   `(git-gutter+-added ((,class (:foreground ,green))))
   `(git-gutter+-deleted ((,class (:foreground ,red))))
   `(git-gutter+-modified ((,class (:foreground ,darkblue))))

;;;; git-gutter-fringe - dark
   `(git-gutter-fr:added ((,class (:foreground ,green))))
   `(git-gutter-fr:deleted ((,class (:foreground ,red))))
   `(git-gutter-fr:modified ((,class (:foreground ,darkblue))))

;;;; gnus - dark
   `(gnus-cite-1 ((,class (:foreground ,teal))))
   `(gnus-cite-2 ((,class (:foreground ,magenta))))
   `(gnus-cite-3 ((,class (:foreground ,darkblue))))
   `(gnus-cite-4 ((,class (:foreground ,darkcyan))))
   `(gnus-cite-5 ((,class (:foreground ,teal))))
   `(gnus-cite-6 ((,class (:foreground ,magenta))))
   `(gnus-cite-7 ((,class (:foreground ,darkblue))))
   `(gnus-cite-8 ((,class (:foreground ,darkcyan))))
   `(gnus-cite-9 ((,class (:foreground ,teal))))
   `(gnus-cite-10 ((,class (:foreground ,magenta))))
   `(gnus-cite-11 ((,class (:foreground ,darkblue))))
   `(gnus-group-mail-1 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-1-empty ((,class (:foreground ,macos5))))
   `(gnus-group-mail-2 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-2-empty ((,class (:foreground ,macos5))))
   `(gnus-group-mail-3 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-3-empty ((,class (:foreground ,macos5))))
   `(gnus-group-mail-low ((,class (:foreground ,fg))))
   `(gnus-group-mail-low-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-1 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-1-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-2 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-2-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-3 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-3-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-4 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-4-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-5 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-5-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-6 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-6-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-low ((,class (:weight bold :foreground ,macos5))))
   `(gnus-group-news-low-empty ((,class (:foreground ,fg))))
   `(gnus-header-content ((,class (:foreground ,cyan))))
   `(gnus-header-from ((,class (:foreground ,magenta))))
   `(gnus-header-name ((,class (:foreground ,blue :weight bold))))
   `(gnus-header-newsgroups ((,class (:foreground ,purple))))
   `(gnus-header-subject ((,class (:foreground ,magenta :weight bold))))
   `(gnus-signature ((,class (:foreground ,yellow))))
   `(gnus-summary-cancelled ((,class (:foreground ,red :strike-through t))))
   `(gnus-summary-high-ancient ((,class (:foreground ,macos5 :slant italic))))
   `(gnus-summary-high-read ((,class (:foreground ,fg))))
   `(gnus-summary-high-ticked ((,class (:foreground ,teal))))
   `(gnus-summary-high-unread ((,class (:foreground ,green))))
   `(gnus-summary-low-ancient ((,class (:foreground ,macos5 :slant italic))))
   `(gnus-summary-low-read ((,class (:foreground ,fg))))
   `(gnus-summary-low-ticked ((,class (:foreground ,teal))))
   `(gnus-summary-low-unread ((,class (:foreground ,green))))
   `(gnus-summary-normal-ancient ((,class (:foreground ,macos5 :slant italic))))
   `(gnus-summary-normal-read ((,class (:foreground ,fg))))
   `(gnus-summary-normal-ticked ((,class (:foreground ,teal))))
   `(gnus-summary-normal-unread ((,class (:foreground ,green :weight bold))))
   `(gnus-summary-selected ((,class (:foreground ,purple :weight bold))))
   `(gnus-x-face ((,class (:background ,macos5 :foreground ,fg))))

;;;; goggles - dark
   `(goggles-added ((,class (:background ,green))))
   `(goggles-changed ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
   `(goggles-removed ((,class (:background ,red :extend t))))

;;;; header-line - dark
   `(header-line ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))

;;;; helm - dark
   `(helm-ff-directory ((,class (:foreground ,red))))
   `(helm-ff-dotted-directory ((,class (:foreground ,grey))))
   `(helm-ff-executable ((,class (:foreground ,macos8 :slant italic))))
   `(helm-ff-file ((,class (:foreground ,fg))))
   `(helm-ff-prefix ((,class (:foreground ,magenta))))
   `(helm-grep-file ((,class (:foreground ,purple))))
   `(helm-grep-finish ((,class (:foreground ,green))))
   `(helm-grep-lineno ((,class (:foreground ,macos5))))
   `(helm-grep-match ((,class (:foreground ,blue :distant-foreground ,red))))
   `(helm-match ((,class (:foreground ,blue :distant-foreground ,macos8 :weight bold))))
   `(helm-moccur-buffer ((,class (:foreground ,red :underline t :weight bold))))
   `(helm-selection ((,class (:background ,grey :extend t :distant-foreground ,blue :weight bold))))
   `(helm-source-header ((,class (:background ,macos2 :foreground ,magenta :weight bold))))
   `(helm-swoop-target-line-block-face ((,class (:foreground ,yellow))))
   `(helm-swoop-target-line-face ((,class (:foreground ,blue :inverse-video t))))
   `(helm-swoop-target-line-face ((,class (:foreground ,blue :inverse-video t))))
   `(helm-swoop-target-number-face ((,class (:foreground ,macos5))))
   `(helm-swoop-target-word-face ((,class (:foreground ,green :weight bold))))
   `(helm-visible-mark ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))

;;;; helpful - dark
   `(helpful-heading ((,class (:foreground ,cyan :weight bold :height 1.2))))

;;;; hi-lock - dark
   `(hi-blue ((,class (:background ,purple))))
   `(hi-blue-b ((,class (:foreground ,purple :weight bold))))
   `(hi-green ((,class (:background ,green))))
   `(hi-green-b ((,class (:foreground ,green :weight bold))))
   `(hi-magenta ((,class (:background ,teal))))
   `(hi-red-b ((,class (:foreground ,red :weight bold))))
   `(hi-yellow ((,class (:background ,yellow))))

;;;; highlight-indentation-mode - dark
   `(highlight-indentation-current-column-face ((,class (:background ,macos1))))
   `(highlight-indentation-face ((,class (:background ,macos2 :extend t))))
   `(highlight-indentation-guides-even-face ((,class (:background ,macos2 :extend t))))
   `(highlight-indentation-guides-odd-face ((,class (:background ,macos2 :extend t))))

;;;; highlight-numbers-mode - dark
   `(highlight-numbers-number ((,class (:foreground ,blue :weight bold))))

;;;; highlight-quoted-mode - dark
   `(highlight-quoted-quote  ((,class (:foreground ,fg))))
   `(highlight-quoted-symbol ((,class (:foreground ,yellow))))

;;;; highlight-symbol - dark
   `(highlight-symbol-face ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; highlight-thing - dark
   `(highlight-thing ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; hl-fill-column-face - dark
   `(hl-fill-column-face ((,class (:background ,macos2 :extend t))))

;;;; hl-line - dark (built-in)
   `(hl-line ((,class (:background ,bg-other :extend t))))

;;;; hl-todo - dark
   `(hl-todo ((,class (:foreground ,red :weight bold))))

;;;; hlinum - dark
   `(linum-highlight-face ((,class (:foreground ,fg :distant-foreground nil :weight normal))))

;;;; hydra - dark
   `(hydra-face-amaranth ((,class (:foreground ,teal :weight bold))))
   `(hydra-face-blue ((,class (:foreground ,purple :weight bold))))
   `(hydra-face-magenta ((,class (:foreground ,magenta :weight bold))))
   `(hydra-face-red ((,class (:foreground ,red :weight bold))))
   `(hydra-face-teal ((,class (:foreground ,orange :weight bold))))

;;;; ido - dark
   `(ido-first-match ((,class (:foreground ,blue))))
   `(ido-indicator ((,class (:foreground ,red :background ,bg))))
   `(ido-only-match ((,class (:foreground ,green))))
   `(ido-subdir ((,class (:foreground ,magenta))))
   `(ido-virtual ((,class (:foreground ,macos5))))

;;;; iedit - dark
   `(iedit-occurrence ((,class (:foreground ,teal :weight bold :inverse-video t))))
   `(iedit-read-only-occurrence ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))


;;;; imenu-list - dark
   `(imenu-list-entry-face-0 ((,class (:foreground ,cyan))))
   `(imenu-list-entry-face-1 ((,class (:foreground ,blue))))
   `(imenu-list-entry-face-2 ((,class (:foreground ,magenta))))
   `(imenu-list-entry-subalist-face-0 ((,class (:foreground ,magenta :weight bold))))
   `(imenu-list-entry-subalist-face-1 ((,class (:foreground ,blue :weight bold))))
   `(imenu-list-entry-subalist-face-2 ((,class (:foreground ,cyan :weight bold))))

;;;; indent-guide - dark
   `(indent-guide-face ((,class (:background ,macos2 :extend t))))

;;;; isearch - dark
   `(isearch ((,class (:background ,darkblue  :foreground ,macos8 :distant-foreground ,macos0 :weight bold))))
   `(isearch-fail ((,class (:background ,red :foreground ,macos0 :weight bold))))

;;;; ivy - dark
   `(ivy-confirm-face ((,class (:foreground ,green))))
   `(ivy-current-match ((,class (:background ,grey :distant-foreground nil :extend t))))
   `(ivy-highlight-face ((,class (:foreground ,magenta))))
   `(ivy-match-required-face ((,class (:foreground ,red))))
   `(ivy-minibuffer-match-face-1 ((,class (:background nil :foreground ,blue :weight bold :underline t))))
   `(ivy-minibuffer-match-face-2 ((,class (:foreground ,teal :background ,macos1 :weight semi-bold))))
   `(ivy-minibuffer-match-face-3 ((,class (:foreground ,green :weight semi-bold))))
   `(ivy-minibuffer-match-face-4 ((,class (:foreground ,yellow :weight semi-bold))))
   `(ivy-minibuffer-match-highlight ((,class (:foreground ,magenta))))
   `(ivy-modified-buffer ((,class (:weight bold :foreground ,darkcyan))))
   `(ivy-virtual ((,class (:slant italic :foreground ,fg))))

;;;; ivy-posframe - dark
   `(ivy-posframe ((,class (:background ,bg-other))))
   `(ivy-posframe-border ((,class (:background ,red))))

;;;; jabber - dark
   `(jabber-activity-face ((,class (:foreground ,red :weight bold))))
   `(jabber-activity-personal-face ((,class (:foreground ,purple :weight bold))))
   `(jabber-chat-error ((,class (:foreground ,red :weight bold))))
   `(jabber-chat-prompt-foreign ((,class (:foreground ,red :weight bold))))
   `(jabber-chat-prompt-local ((,class (:foreground ,purple :weight bold))))
   `(jabber-chat-prompt-system ((,class (:foreground ,green :weight bold))))
   `(jabber-chat-text-foreign ((,class (:foreground ,fg))))
   `(jabber-chat-text-local ((,class (:foreground ,fg))))
   `(jabber-rare-time-face ((,class (:foreground ,green))))
   `(jabber-roster-user-away ((,class (:foreground ,yellow))))
   `(jabber-roster-user-chatty ((,class (:foreground ,green :weight bold))))
   `(jabber-roster-user-dnd ((,class (:foreground ,red))))
   `(jabber-roster-user-error ((,class (:foreground ,red))))
   `(jabber-roster-user-offline ((,class (:foreground ,fg))))
   `(jabber-roster-user-online ((,class (:foreground ,green :weight bold))))
   `(jabber-roster-user-xa ((,class (:foreground ,darkblue))))

;;;; jdee - dark
   `(jdee-font-lock-bold-face ((,class (:weight bold))))
   `(jdee-font-lock-constant-face ((,class (:foreground ,red))))
   `(jdee-font-lock-constructor-face ((,class (:foreground ,purple))))
   `(jdee-font-lock-doc-tag-face ((,class (:foreground ,magenta))))
   `(jdee-font-lock-italic-face ((,class (:slant italic))))
   `(jdee-font-lock-link-face ((,class (:foreground ,purple :underline t))))
   `(jdee-font-lock-modifier-face ((,class (:foreground ,yellow))))
   `(jdee-font-lock-number-face ((,class (:foreground ,blue))))
   `(jdee-font-lock-operator-face ((,class (:foreground ,fg))))
   `(jdee-font-lock-private-face ((,class (:foreground ,cyan))))
   `(jdee-font-lock-protected-face ((,class (:foreground ,cyan))))
   `(jdee-font-lock-public-face ((,class (:foreground ,cyan))))

;;;; js2-mode - dark
   `(js2-external-variable ((,class (:foreground ,fg))))
   `(js2-function-call ((,class (:foreground ,purple))))
   `(js2-function-param ((,class (:foreground ,red))))
   `(js2-jsdoc-tag ((,class (:foreground ,macos5))))
   `(js2-object-property ((,class (:foreground ,magenta))))

;;;; keycast - dark
   `(keycast-command ((,class (:foreground ,red))))
   `(keycast-key ((,class (:foreground ,red :weight bold))))

;;;; ledger-mode - dark
   `(ledger-font-payee-cleared-face ((,class (:foreground ,magenta :weight bold))))
   `(ledger-font-payee-uncleared-face ((,class (:foreground ,macos5  :weight bold))))
   `(ledger-font-posting-account-face ((,class (:foreground ,macos8))))
   `(ledger-font-posting-amount-face ((,class (:foreground ,yellow))))
   `(ledger-font-posting-date-face ((,class (:foreground ,purple))))
   `(ledger-font-xact-highlight-face ((,class (:background ,macos0))))

;;;; line - dark numbers
   `(line-number ((,class (:foreground ,macos5))))
   `(line-number-current-line ((,class (:background ,bg-other :foreground ,fg))))

;;;; linum - dark
   `(linum ((,class (:foreground ,macos5))))

;;;; linum-relative - dark
   `(linum-relative-current-face ((,class (:background ,macos2 :foreground ,fg))))

;;;; lsp-mode - dark
   `(lsp-face-highlight-read ((,class (:foreground ,bg :weight bold :background ,cyan))))
   `(lsp-face-highlight-textual ((,class (:foreground ,bg :weight bold :background ,cyan))))
   `(lsp-face-highlight-write ((,class (:foreground ,bg :weight bold :background ,cyan))))
   `(lsp-headerline-breadcrumb-separator-face ((,class (:foreground ,fg-other))))
   `(lsp-ui-doc-background ((,class (:background ,bg-other :foreground ,fg))))
   `(lsp-ui-peek-filename ((,class (:weight bold))))
   `(lsp-ui-peek-header ((,class (:foreground ,fg :background ,bg :weight bold))))
   `(lsp-ui-peek-highlight ((,class (:background ,grey :foreground ,bg :box t))))
   `(lsp-ui-peek-line-number ((,class (:foreground ,green))))
   `(lsp-ui-peek-list ((,class (:background ,bg))))
   `(lsp-ui-peek-peek ((,class (:background ,bg))))
   `(lsp-ui-peek-selection ((,class (:foreground ,bg :background ,purple :bold bold))))
   `(lsp-ui-sideline-code-action ((,class (:foreground ,blue))))
   `(lsp-ui-sideline-current-symbol ((,class (:foreground ,blue))))
   `(lsp-ui-sideline-symbol-info ((,class (:foreground ,macos5 :background ,bg-other :extend t))))

;;;; lui - dark
   `(lui-button-face ((,class (:backgroung ,bg-other :foreground ,blue :underline t))))
   `(lui-highlight-face ((,class (:backgroung ,bg-other :foreground ,blue))))
   `(lui-time-stamp-face ((,class (:backgroung ,bg-other :foreground ,magenta))))

;;;; magit - dark
   `(magit-bisect-bad ((,class (:foreground ,red))))
   `(magit-bisect-good ((,class (:foreground ,green))))
   `(magit-bisect-skip ((,class (:foreground ,red))))
   `(magit-blame-date ((,class (:foreground ,red))))
   `(magit-blame-heading ((,class (:foreground ,cyan :background ,macos3 :extend t))))
   `(magit-branch-current ((,class (:foreground ,red))))
   `(magit-branch-local ((,class (:foreground ,red))))
   `(magit-branch-remote ((,class (:foreground ,green))))
   `(magit-branch-remote-head ((,class (:foreground ,green))))
   `(magit-cherry-equivalent ((,class (:foreground ,magenta))))
   `(magit-cherry-unmatched ((,class (:foreground ,darkblue))))
   `(magit-diff-added ((,class (:foreground ,bg  :background ,green :extend t))))
   `(magit-diff-added-highlight ((,class (:foreground ,bg :background ,green :weight bold :extend t))))
   `(magit-diff-base ((,class (:foreground ,cyan :background ,blue :extend t))))
   `(magit-diff-base-highlight ((,class (:foreground ,cyan :background ,blue :weight bold :extend t))))
   `(magit-diff-context ((,class (:foreground ,fg :background ,bg :extend t))))
   `(magit-diff-context-highlight ((,class (:foreground ,fg :background ,bg-other :extend t))))
   `(magit-diff-file-heading ((,class (:foreground ,fg :weight bold :extend t))))
   `(magit-diff-file-heading-selection ((,class (:foreground ,teal :background ,darkblue :weight bold :extend t))))
   `(magit-diff-hunk-heading ((,class (:foreground ,bg :background ,blue :extend t :weight bold))))
   `(magit-diff-hunk-heading-highlight ((,class (:foreground ,bg :background ,blue :weight bold :extend t))))
   `(magit-diff-lines-heading ((,class (:foreground ,yellow :background ,red :extend t :extend t))))
   `(magit-diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
   `(magit-diff-removed-highlight ((,class (:foreground ,bg :background ,red :weight bold :extend t))))
   `(magit-diff-revision-summary ((,class (:foreground ,bg  :background ,blue :extend t :weight bold))))
   `(magit-diffstat-added ((,class (:foreground ,green))))
   `(magit-diffstat-removed ((,class (:foreground ,red))))
   `(magit-dimmed ((,class (:foreground ,macos5))))
   `(magit-filename ((,class (:foreground ,magenta))))
   `(magit-hash ((,class (:foreground ,magenta))))
   `(magit-header-line ((,class (:background ,bg-other :foreground ,blue :weight bold :box (:line-width 3 :color ,bg-other)))))
   `(magit-log-author ((,class (:foreground ,cyan))))
   `(magit-log-date ((,class (:foreground ,purple))))
   `(magit-log-graph ((,class (:foreground ,macos5))))
   `(magit-process-ng ((,class (:foreground ,red))))
   `(magit-process-ok ((,class (:foreground ,green))))
   `(magit-reflog-amend ((,class (:foreground ,teal))))
   `(magit-reflog-checkout ((,class (:foreground ,purple))))
   `(magit-reflog-cherry-pick ((,class (:foreground ,green))))
   `(magit-reflog-commit ((,class (:foreground ,green))))
   `(magit-reflog-merge ((,class (:foreground ,green))))
   `(magit-reflog-other ((,class (:foreground ,darkblue))))
   `(magit-reflog-rebase ((,class (:foreground ,teal))))
   `(magit-reflog-remote ((,class (:foreground ,darkblue))))
   `(magit-reflog-reset ((,class (:foreground ,red))))
   `(magit-refname ((,class (:foreground ,macos5))))
   `(magit-section-heading ((,class (:foreground ,blue :weight bold :extend t))))
   `(magit-section-heading-selection ((,class (:foreground ,cyan :weight bold :extend t))))
   `(magit-section-highlight ((,class (:background ,bg-other :extend t))))
   `(magit-section-secondary-heading ((,class (:foreground ,magenta :weight bold :extend t))))
   `(magit-sequence-drop ((,class (:foreground ,red))))
   `(magit-sequence-head ((,class (:foreground ,purple))))
   `(magit-sequence-part ((,class (:foreground ,cyan))))
   `(magit-sequence-stop ((,class (:foreground ,green))))
   `(magit-signature-bad ((,class (:foreground ,red))))
   `(magit-signature-error ((,class (:foreground ,red))))
   `(magit-signature-expired ((,class (:foreground ,cyan))))
   `(magit-signature-good ((,class (:foreground ,green))))
   `(magit-signature-revoked ((,class (:foreground ,teal))))
   `(magit-signature-untrusted ((,class (:foreground ,yellow))))
   `(magit-tag ((,class (:foreground ,yellow))))

;;;; make-mode - dark
   `(makefile-targets ((,class (:foreground ,purple))))

;;;; marginalia - dark
   `(marginalia-documentation ((,class (:foreground ,blue))))
   `(marginalia-file-name ((,class (:foreground ,blue))))
   `(marginalia-size ((,class (:foreground ,yellow))))
   `(marginalia-mode ((,class (:foreground ,purple))))
   `(marginalia-modified ((,class (:foreground ,red))))
   `(marginalia-file-priv-read ((,class (:foreground ,green))))
   `(marginalia-file-priv-write ((,class (:foreground ,yellow))))
   `(marginalia-file-priv-exec ((,class (:foreground ,red))))

;;;; markdown-mode - dark
   `(markdown-blockquote-face ((,class (:foreground ,macos5 :slant italic))))
   `(markdown-bold-face ((,class (:foreground ,blue :weight bold))))
   `(markdown-code-face ((,class (:background ,bg-org :extend t))))
   `(markdown-header-delimiter-face ((,class (:foreground ,blue :weight bold))))
   `(markdown-header-face ((,class (:foreground ,blue :weight bold))))
   `(markdown-html-attr-name-face ((,class (:foreground ,blue))))
   `(markdown-html-attr-value-face ((,class (:foreground ,red))))
   `(markdown-html-entity-face ((,class (:foreground ,blue))))
   `(markdown-html-tag-delimiter-face ((,class (:foreground ,fg))))
   `(markdown-html-tag-name-face ((,class (:foreground ,cyan))))
   `(markdown-inline-code-face ((,class (:background ,bg-org :foreground ,blue))))
   `(markdown-italic-face ((,class (:foreground ,magenta :slant italic))))
   `(markdown-link-face ((,class (:foreground ,purple))))
   `(markdown-list-face ((,class (:foreground ,blue))))
   `(markdown-markup-face ((,class (:foreground ,fg))))
   `(markdown-metadata-key-face ((,class (:foreground ,blue))))
   `(markdown-pre-face ((,class (:background ,bg-org :foreground ,yellow))))
   `(markdown-reference-face ((,class (:foreground ,macos5))))
   `(markdown-url-face ((,class (:foreground ,magenta))))

;;;; message - dark
   `(message-cited-text-1 ((,class (:foreground ,teal))))
   `(message-cited-text-2 ((,class (:foreground ,magenta))))
   `(message-cited-text-3 ((,class (:foreground ,darkblue))))
   `(message-cited-text-3 ((,class (:foreground ,darkcyan))))
   `(message-header-cc ((,class (:foreground ,red :weight bold))))
   `(message-header-name ((,class (:foreground ,red))))
   `(message-header-newsgroups ((,class (:foreground ,yellow))))
   `(message-header-other ((,class (:foreground ,purple))))
   `(message-header-subject ((,class (:foreground ,cyan :weight bold))))
   `(message-header-to ((,class (:foreground ,cyan :weight bold))))
   `(message-header-xheader ((,class (:foreground ,macos5))))
   `(message-mml ((,class (:foreground ,macos5 :slant italic))))
   `(message-separator ((,class (:foreground ,macos5))))

;;;; mic-paren - dark
   `(paren-face-match ((,class (:foreground ,red :background ,macos0 :weight ultra-bold))))
   `(paren-face-mismatch ((,class (:foreground ,macos0 :background ,red :weight ultra-bold))))
   `(paren-face-no-match ((,class (:foreground ,macos0 :background ,red :weight ultra-bold))))

;;;; minimap - dark
   `(minimap-active-region-background ((,class (:background ,bg))))
   `(minimap-current-line-face ((,class (:background ,grey))))

;;;; mmm-mode - dark
   `(mmm-cleanup-submode-face ((,class (:background ,yellow))))
   `(mmm-code-submode-face ((,class (:background ,bg-other))))
   `(mmm-comment-submode-face ((,class (:background ,purple))))
   `(mmm-declaration-submode-face ((,class (:background ,darkblue))))
   `(mmm-default-submode-face ((,class (:background nil))))
   `(mmm-init-submode-face ((,class (:background ,red))))
   `(mmm-output-submode-face ((,class (:background ,magenta))))
   `(mmm-special-submode-face ((,class (:background ,green))))

;;;; mode-line - dark
   `(mode-line ((,class (,@(timu-macos-set-mode-line-active-border blue) :background ,bg-other :foreground ,fg :distant-foreground ,bg))))
   `(mode-line-buffer-id ((,class (:weight bold))))
   `(mode-line-emphasis ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(mode-line-highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(mode-line-inactive ((,class (,@(timu-macos-set-mode-line-inactive-border macos4) :background ,bg-other :foreground ,macos4 :distant-foreground ,macos4))))

;;;; mu4e - dark
   `(mu4e-forwarded-face ((,class (:foreground ,purple))))
   `(mu4e-header-key-face ((,class (:foreground ,magenta :weight bold))))
   `(mu4e-header-title-face ((,class (:foreground ,cyan))))
   `(mu4e-highlight-face ((,class (:foreground ,blue :weight bold))))
   `(mu4e-link-face ((,class (:foreground ,cyan))))
   `(mu4e-replied-face ((,class (:foreground ,green))))
   `(mu4e-title-face ((,class (:foreground ,blue :weight bold))))
   `(mu4e-unread-face ((,class (:foreground ,magenta :weight bold))))

;;;; mu4e-column-faces - dark
   `(mu4e-column-faces-date ((,class (:foreground ,cyan))))
   `(mu4e-column-faces-flags ((,class (:foreground ,yellow))))
   `(mu4e-column-faces-to-from ((,class (:foreground ,blue))))

;;;; mu4e-thread-folding - dark
   `(mu4e-thread-folding-child-face ((,class (:extend t :background ,bg-org :underline nil))))
   `(mu4e-thread-folding-root-folded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))
   `(mu4e-thread-folding-root-unfolded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))

;;;; multiple - dark cursors
   `(mc/cursor-face ((,class (:background ,cyan))))

;;;; nano-modeline - dark
   `(nano-modeline-active-name ((,class (:foreground ,fg :weight bold))))
   `(nano-modeline-inactive-name ((,class (:foreground ,macos2 :weight bold))))
   `(nano-modeline-active-primary ((,class (:foreground ,magenta))))
   `(nano-modeline-inactive-primary ((,class (:foreground ,macos2))))
   `(nano-modeline-active-secondary ((,class (:foreground ,blue :weight bold))))
   `(nano-modeline-inactive-secondary ((,class (:foreground ,macos2 :weight bold))))
   `(nano-modeline-active-status-RO ((,class (:background ,purple :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-RO ((,class (:background ,macos2 :foreground ,bg :weight bold))))
   `(nano-modeline-active-status-RW ((,class (:background ,blue :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-RW ((,class (:background ,macos2 :foreground ,bg :weight bold))))
   `(nano-modeline-active-status-** ((,class (:background ,red :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-** ((,class (:background ,macos2 :foreground ,bg :weight bold))))

;;;; nav-flash - dark
   `(nav-flash-face ((,class (:background ,grey :foreground ,macos8 :weight bold))))

;;;; neotree - dark
   `(neo-dir-link-face ((,class (:foreground ,blue))))
   `(neo-expand-btn-face ((,class (:foreground ,blue))))
   `(neo-file-link-face ((,class (:foreground ,fg))))
   `(neo-root-dir-face ((,class (:foreground ,green :background ,bg :box (:line-width 4 :color ,bg)))))
   `(neo-vc-added-face ((,class (:foreground ,green))))
   `(neo-vc-conflict-face ((,class (:foreground ,teal :weight bold))))
   `(neo-vc-edited-face ((,class (:foreground ,yellow))))
   `(neo-vc-ignored-face ((,class (:foreground ,macos5))))
   `(neo-vc-removed-face ((,class (:foreground ,red :strike-through t))))

;;;; nlinum - dark
   `(nlinum-current-line ((,class (:background ,macos2 :foreground ,fg))))

;;;; nlinum-hl - dark
   `(nlinum-hl-face ((,class (:background ,macos2 :foreground ,fg))))

;;;; nlinum-relative - dark
   `(nlinum-relative-current-face ((,class (:background ,macos2 :foreground ,fg))))

;;;; notmuch - dark
   `(notmuch-message-summary-face ((,class (:foreground ,grey :background nil))))
   `(notmuch-search-count ((,class (:foreground ,macos5))))
   `(notmuch-search-date ((,class (:foreground ,blue))))
   `(notmuch-search-flagged-face ((,class (:foreground ,red))))
   `(notmuch-search-matching-authors ((,class (:foreground ,purple))))
   `(notmuch-search-non-matching-authors ((,class (:foreground ,fg))))
   `(notmuch-search-subject ((,class (:foreground ,fg))))
   `(notmuch-search-unread-face ((,class (:weight bold))))
   `(notmuch-tag-added ((,class (:foreground ,green :weight normal))))
   `(notmuch-tag-deleted ((,class (:foreground ,red :weight normal))))
   `(notmuch-tag-face ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tag-flagged ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tag-unread ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tree-match-author-face ((,class (:foreground ,purple :weight bold))))
   `(notmuch-tree-match-date-face ((,class (:foreground ,blue :weight bold))))
   `(notmuch-tree-match-face ((,class (:foreground ,fg))))
   `(notmuch-tree-match-subject-face ((,class (:foreground ,fg))))
   `(notmuch-tree-match-tag-face ((,class (:foreground ,yellow))))
   `(notmuch-tree-match-tree-face ((,class (:foreground ,macos5))))
   `(notmuch-tree-no-match-author-face ((,class (:foreground ,purple))))
   `(notmuch-tree-no-match-date-face ((,class (:foreground ,blue))))
   `(notmuch-tree-no-match-face ((,class (:foreground ,macos5))))
   `(notmuch-tree-no-match-subject-face ((,class (:foreground ,macos5))))
   `(notmuch-tree-no-match-tag-face ((,class (:foreground ,yellow))))
   `(notmuch-tree-no-match-tree-face ((,class (:foreground ,yellow))))
   `(notmuch-wash-cited-text ((,class (:foreground ,macos4))))
   `(notmuch-wash-toggle-button ((,class (:foreground ,fg))))

;;;; orderless - dark
   `(orderless-match-face-0 ((,class (:foreground ,blue :weight bold :underline t))))
   `(orderless-match-face-1 ((,class (:foreground ,cyan :weight bold :underline t))))
   `(orderless-match-face-2 ((,class (:foreground ,purple :weight bold :underline t))))
   `(orderless-match-face-3 ((,class (:foreground ,darkcyan :weight bold :underline t))))

;;;; objed - dark
   `(objed-hl ((,class (:background ,grey :distant-foreground ,bg :extend t))))
   `(objed-mode-line ((,class (:foreground ,yellow :weight bold))))

;;;; org-agenda - dark
   `(org-agenda-clocking ((,class (:background ,purple))))
   `(org-agenda-date ((,class (:foreground ,blue :weight ultra-bold))))
   `(org-agenda-date-today ((,class (:foreground ,blue :weight ultra-bold))))
   `(org-agenda-date-weekend ((,class (:foreground ,blue :weight ultra-bold))))
   `(org-agenda-dimmed-todo-face ((,class (:foreground ,macos5))))
   `(org-agenda-done ((,class (:foreground ,macos5))))
   `(org-agenda-structure ((,class (:foreground ,fg :weight ultra-bold))))
   `(org-scheduled ((,class (:foreground ,fg))))
   `(org-scheduled-previously ((,class (:foreground ,macos8))))
   `(org-scheduled-today ((,class (:foreground ,macos7))))
   `(org-sexp-date ((,class (:foreground ,fg))))
   `(org-time-grid ((,class (:foreground ,macos5))))
   `(org-upcoming-deadline ((,class (:foreground ,fg))))
   `(org-upcoming-distant-deadline ((,class (:foreground ,fg))))
   `(org-agenda-structure-filter ((,class (:foreground ,magenta :weight bold))))

;;;; org-habit - dark
   `(org-habit-alert-face ((,class (:weight bold :background ,yellow))))
   `(org-habit-alert-future-face ((,class (:weight bold :background ,yellow))))
   `(org-habit-clear-face ((,class (:weight bold :background ,macos4))))
   `(org-habit-clear-future-face ((,class (:weight bold :background ,macos3))))
   `(org-habit-overdue-face ((,class (:weight bold :background ,red))))
   `(org-habit-overdue-future-face ((,class (:weight bold :background ,red))))
   `(org-habit-ready-face ((,class (:weight bold :background ,purple))))
   `(org-habit-ready-future-face ((,class (:weight bold :background ,purple))))

;;;; org-journal - dark
   `(org-journal-calendar-entry-face ((,class (:foreground ,teal :slant italic))))
   `(org-journal-calendar-scheduled-face ((,class (:foreground ,red :slant italic))))
   `(org-journal-highlight ((,class (:foreground ,cyan))))

;;;; org-mode - dark
   `(org-archived ((,class (:foreground ,macos5))))
   `(org-block ((,class (:foreground ,macos8 :background ,bg-org :extend t))))
   `(org-block-background ((,class (:background ,bg-org :extend t))))
   `(org-block-begin-line ((,class (:foreground ,macos5 :slant italic :background ,bg-org :extend t ,@(timu-macos-set-intense-org-colors bg bg-other)))))
   `(org-block-end-line ((,class (:foreground ,macos5 :slant italic :background ,bg-org :extend t ,@(timu-macos-set-intense-org-colors bg-other bg-other)))))
   `(org-checkbox ((,class (:foreground ,green :background ,bg-org :weight bold))))
   `(org-checkbox-statistics-done ((,class (:foreground ,macos5 :background ,bg-org :weight bold))))
   `(org-checkbox-statistics-todo ((,class (:foreground ,green :background ,bg-org :weight bold))))
   `(org-code ((,class (:foreground ,blue ,@(timu-macos-set-intense-org-colors bg bg-other)))))
   `(org-date ((,class (:foreground ,yellow :background ,bg-org))))
   `(org-default ((,class (:background ,bg :foreground ,fg))))
   `(org-document-info ((,class (:foreground ,purple ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.2) ,@(timu-macos-set-intense-org-colors bg bg-other)))))
   `(org-document-info-keyword ((,class (:foreground ,macos5))))
   `(org-document-title ((,class (:foreground ,purple :weight bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.3) ,@(timu-macos-set-intense-org-colors purple bg-other)))))
   `(org-done ((,class (:foreground ,macos5 :weight bold))))
   `(org-ellipsis ((,class (:foreground ,grey))))
   `(org-footnote ((,class (:foreground ,cyan))))
   `(org-formula ((,class (:foreground ,darkblue))))
   `(org-headline-done ((,class (:foreground ,macos5))))
   `(org-hide ((,class (:foreground ,bg))))
   `(org-latex-and-related ((,class (:foreground ,macos8 :weight bold))))
   `(org-level-1 ((,class (:foreground ,blue :weight ultra-bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.3) ,@(timu-macos-set-intense-org-colors blue bg-other)))))
   `(org-level-2 ((,class (:foreground ,magenta :weight bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.2) ,@(timu-macos-set-intense-org-colors magenta bg-other)))))
   `(org-level-3 ((,class (:foreground ,lightcyan :weight bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.1) ,@(timu-macos-set-intense-org-colors lightcyan bg-other)))))
   `(org-level-4 ((,class (:foreground ,red ,@(timu-macos-set-intense-org-colors red bg-org)))))
   `(org-level-5 ((,class (:foreground ,green ,@(timu-macos-set-intense-org-colors green bg-org)))))
   `(org-level-6 ((,class (:foreground ,orange ,@(timu-macos-set-intense-org-colors orange bg-org)))))
   `(org-level-7 ((,class (:foreground ,purple ,@(timu-macos-set-intense-org-colors purple bg-org)))))
   `(org-level-8 ((,class (:foreground ,fg ,@(timu-macos-set-intense-org-colors fg bg-org)))))
   `(org-link ((,class (:foreground ,blue :underline t))))
   `(org-list-dt ((,class (:foreground ,green :weight bold))))
   `(org-meta-line ((,class (:foreground ,macos5))))
   `(org-priority ((,class (:foreground ,red))))
   `(org-property-value ((,class (:foreground ,macos5))))
   `(org-quote ((,class (:background ,macos3 :slant italic :extend t))))
   `(org-special-keyword ((,class (:foreground ,macos5))))
   `(org-table ((,class (:foreground ,red))))
   `(org-tag ((,class (:foreground ,macos5 :weight normal))))
   `(org-todo ((,class (:foreground ,green :weight bold))))
   `(org-verbatim ((,class (:foreground ,green ,@(timu-macos-set-intense-org-colors bg bg-other)))))
   `(org-warning ((,class (:foreground ,yellow))))

;;;; org-pomodoro - dark
   `(org-pomodoro-mode-line ((,class (:foreground ,red))))
   `(org-pomodoro-mode-line-overtime ((,class (:foreground ,yellow :weight bold))))

;;;; org-ref - dark
   `(org-ref-acronym-face ((,class (:foreground ,magenta))))
   `(org-ref-cite-face ((,class (:foreground ,yellow :weight light :underline t))))
   `(org-ref-glossary-face ((,class (:foreground ,teal))))
   `(org-ref-label-face ((,class (:foreground ,purple))))
   `(org-ref-ref-face ((,class (:foreground ,red :underline t :weight bold))))

;;;; outline - dark
   `(outline-1 ((,class (:foreground ,purple :weight ultra-bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.2)))))
   `(outline-2 ((,class (:foreground ,red :weight bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.2)))))
   `(outline-3 ((,class (:foreground ,blue :weight bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.1)))))
   `(outline-4 ((,class (:foreground ,cyan))))
   `(outline-5 ((,class (:foreground ,green))))
   `(outline-6 ((,class (:foreground ,orange))))
   `(outline-7 ((,class (:foreground ,teal))))
   `(outline-8 ((,class (:foreground ,fg))))

;;;; parenface - dark
   `(paren-face ((,class (:foreground ,macos5))))

;;;; parinfer - dark
   `(parinfer-pretty-parens:dim-paren-face ((,class (:foreground ,macos5))))
   `(parinfer-smart-tab:indicator-face ((,class (:foreground ,macos5))))

;;;; persp-mode - dark
   `(persp-face-lighter-buffer-not-in-persp ((,class (:foreground ,macos5))))
   `(persp-face-lighter-default ((,class (:foreground ,red :weight bold))))
   `(persp-face-lighter-nil-persp ((,class (:foreground ,macos5))))

;;;; perspective - dark
   `(persp-selected-face ((,class (:foreground ,purple :weight bold))))

;;;; pkgbuild-mode - dark
   `(pkgbuild-error-face ((,class (:underline (:style wave :color ,red)))))

;;;; popup - dark
   `(popup-face ((,class (:background ,bg-other :foreground ,fg))))
   `(popup-selection-face ((,class (:background ,grey))))
   `(popup-tip-face ((,class (:foreground ,magenta :background ,macos0))))

;;;; powerline - dark
   `(powerline-active0 ((,class (:background ,macos1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-active1 ((,class (:background ,macos1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-active2 ((,class (:background ,macos1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-inactive0 ((,class (:background ,macos2 :foreground ,macos5 :distant-foreground ,bg-other))))
   `(powerline-inactive1 ((,class (:background ,macos2 :foreground ,macos5 :distant-foreground ,bg-other))))
   `(powerline-inactive2 ((,class (:background ,macos2 :foreground ,macos5 :distant-foreground ,bg-other))))

;;;; rainbow-delimiters - dark
   `(rainbow-delimiters-depth-1-face ((,class (:foreground ,magenta))))
   `(rainbow-delimiters-depth-2-face ((,class (:foreground ,teal))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground ,red))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground ,green))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground ,purple))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground ,yellow))))
   `(rainbow-delimiters-depth-7-face ((,class (:foreground ,orange))))
   `(rainbow-delimiters-mismatched-face ((,class (:foreground ,magenta :weight bold :inverse-video t))))
   `(rainbow-delimiters-unmatched-face ((,class (:foreground ,magenta :weight bold :inverse-video t))))

;;;; re-builder - dark
   `(reb-match-0 ((,class (:foreground ,red :inverse-video t))))
   `(reb-match-1 ((,class (:foreground ,teal :inverse-video t))))
   `(reb-match-2 ((,class (:foreground ,green :inverse-video t))))
   `(reb-match-3 ((,class (:foreground ,yellow :inverse-video t))))

;;;; rjsx-mode - dark
   `(rjsx-attr ((,class (:foreground ,purple))))
   `(rjsx-tag ((,class (:foreground ,yellow))))

;;;; rpm-spec-mode - dark
   `(rpm-spec-dir-face ((,class (:foreground ,green))))
   `(rpm-spec-doc-face ((,class (:foreground ,blue))))
   `(rpm-spec-ghost-face ((,class (:foreground ,macos5))))
   `(rpm-spec-macro-face ((,class (:foreground ,yellow))))
   `(rpm-spec-obsolete-tag-face ((,class (:foreground ,red))))
   `(rpm-spec-package-face ((,class (:foreground ,blue))))
   `(rpm-spec-section-face ((,class (:foreground ,teal))))
   `(rpm-spec-tag-face ((,class (:foreground ,purple))))
   `(rpm-spec-var-face ((,class (:foreground ,magenta))))

;;;; rst - dark
   `(rst-block ((,class (:foreground ,red))))
   `(rst-level-1 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-2 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-3 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-4 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-5 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-6 ((,class (:foreground ,magenta :weight bold))))

;;;; selectrum - dark
   `(selectrum-current-candidate ((,class (:background ,grey :distant-foreground nil :extend t))))

;;;; sh-script - dark
   `(sh-heredoc ((,class (:foreground ,blue))))
   `(sh-quoted-exec ((,class (:foreground ,fg :weight bold))))

;;;; show-paren - dark
   `(show-paren-match ((,class (:foreground ,magenta :weight ultra-bold :underline ,magenta))))
   `(show-paren-mismatch ((,class (:foreground ,bg :background ,magenta :weight ultra-bold))))

;;;; smart-mode-line - dark
   `(sml/charging ((,class (:foreground ,green))))
   `(sml/discharging ((,class (:foreground ,yellow :weight bold))))
   `(sml/filename ((,class (:foreground ,magenta :weight bold))))
   `(sml/git ((,class (:foreground ,purple))))
   `(sml/modified ((,class (:foreground ,darkblue))))
   `(sml/outside-modified ((,class (:foreground ,darkblue))))
   `(sml/process ((,class (:weight bold))))
   `(sml/read-only ((,class (:foreground ,darkblue))))
   `(sml/sudo ((,class (:foreground ,red :weight bold))))
   `(sml/vc-edited ((,class (:foreground ,green))))

;;;; smartparens - dark
   `(sp-pair-overlay-face ((,class (:background ,grey))))
   `(sp-show-pair-match-face ((,class (:foreground ,red :background ,macos0 :weight ultra-bold))))
   `(sp-show-pair-mismatch-face ((,class (:foreground ,macos0 :background ,red :weight ultra-bold))))

;;;; smerge-tool - dark
   `(smerge-base ((,class (:background ,purple :foreground ,bg))))
   `(smerge-lower ((,class (:background ,green))))
   `(smerge-markers ((,class (:background ,macos5 :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(smerge-mine ((,class (:background ,red :foreground ,bg))))
   `(smerge-other ((,class (:background ,green :foreground ,bg))))
   `(smerge-refined-added ((,class (:background ,green :foreground ,bg))))
   `(smerge-refined-removed ((,class (:background ,red :foreground ,bg))))
   `(smerge-upper ((,class (:background ,red))))

;;;; solaire-mode - dark
   `(solaire-default-face ((,class (:background ,bg-other))))
   `(solaire-hl-line-face ((,class (:background ,bg-other :extend t))))
   `(solaire-mode-line-face ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))
   `(solaire-mode-line-inactive-face ((,class (:background ,bg-other :foreground ,fg-other :distant-foreground ,bg-other))))
   `(solaire-org-hide-face ((,class (:foreground ,bg))))

;;;; spaceline - dark
   `(spaceline-evil-emacs ((,class (:background ,darkblue))))
   `(spaceline-evil-insert ((,class (:background ,green))))
   `(spaceline-evil-motion ((,class (:background ,teal))))
   `(spaceline-evil-normal ((,class (:background ,purple))))
   `(spaceline-evil-replace ((,class (:background ,red))))
   `(spaceline-evil-visual ((,class (:background ,grey))))
   `(spaceline-flycheck-error ((,class (:foreground ,red :distant-background ,macos0))))
   `(spaceline-flycheck-info ((,class (:foreground ,green :distant-background ,macos0))))
   `(spaceline-flycheck-warning ((,class (:foreground ,yellow :distant-background ,macos0))))
   `(spaceline-highlight-face ((,class (:background ,red))))
   `(spaceline-modified ((,class (:background ,red))))
   `(spaceline-python-venv ((,class (:foreground ,teal :distant-foreground ,magenta))))
   `(spaceline-unmodified ((,class (:background ,red))))

;;;; stripe-buffer - dark
   `(stripe-highlight ((,class (:background ,macos3))))

;;;; swiper - dark
   `(swiper-line-face ((,class (:background ,purple :foreground ,macos0))))
   `(swiper-match-face-1 ((,class (:background ,macos0 :foreground ,macos5))))
   `(swiper-match-face-2 ((,class (:background ,blue :foreground ,macos0 :weight bold))))
   `(swiper-match-face-3 ((,class (:background ,teal :foreground ,macos0 :weight bold))))
   `(swiper-match-face-4 ((,class (:background ,green :foreground ,macos0 :weight bold))))

;;;; tabbar - dark
   `(tabbar-button ((,class (:foreground ,fg :background ,bg))))
   `(tabbar-button-highlight ((,class (:foreground ,fg :background ,bg :inverse-video t))))
   `(tabbar-default ((,class (:foreground ,bg :background ,bg :height 1.0))))
   `(tabbar-highlight ((,class (:foreground ,fg :background ,grey :distant-foreground ,bg))))
   `(tabbar-modified ((,class (:foreground ,red :weight bold))))
   `(tabbar-selected ((,class (:foreground ,fg :background ,bg-other :weight bold))))
   `(tabbar-selected-modified ((,class (:foreground ,green :background ,bg-other :weight bold))))
   `(tabbar-unselected ((,class (:foreground ,macos5))))
   `(tabbar-unselected-modified ((,class (:foreground ,red :weight bold))))

;;;; tab-bar - dark
   `(tab-bar ((,class (:background ,bg-other :foreground ,bg-other))))
   `(tab-bar-tab ((,class (:background ,bg :foreground ,fg))))
   `(tab-bar-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; tab-line - dark
   `(tab-line ((,class (:background ,bg-other :foreground ,bg-other))))
   `(tab-line-close-highlight ((,class (:foreground ,red))))
   `(tab-line-highlight ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab-current ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; telephone-line - dark
   `(telephone-line-accent-active ((,class (:foreground ,fg :background ,macos4))))
   `(telephone-line-accent-inactive ((,class (:foreground ,fg :background ,macos2))))
   `(telephone-line-evil ((,class (:foreground ,fg :weight bold))))
   `(telephone-line-evil-emacs ((,class (:background ,teal :weight bold))))
   `(telephone-line-evil-insert ((,class (:background ,green :weight bold))))
   `(telephone-line-evil-motion ((,class (:background ,purple :weight bold))))
   `(telephone-line-evil-normal ((,class (:background ,red :weight bold))))
   `(telephone-line-evil-operator ((,class (:background ,magenta :weight bold))))
   `(telephone-line-evil-replace ((,class (:background ,bg-other :weight bold))))
   `(telephone-line-evil-visual ((,class (:background ,red :weight bold))))
   `(telephone-line-projectile ((,class (:foreground ,green))))

;;;; term - dark
   `(term ((,class (:foreground ,fg))))
   `(term-bold ((,class (:weight bold))))
   `(term-color-black ((,class (:background ,macos0 :foreground ,macos0))))
   `(term-color-blue ((,class (:background ,purple :foreground ,purple))))
   `(term-color-cyan ((,class (:background ,darkblue :foreground ,darkblue))))
   `(term-color-green ((,class (:background ,green :foreground ,green))))
   `(term-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
   `(term-color-purple ((,class (:background ,teal :foreground ,teal))))
   `(term-color-red ((,class (:background ,red :foreground ,red))))
   `(term-color-white ((,class (:background ,macos8 :foreground ,macos8))))
   `(term-color-yellow ((,class (:background ,yellow :foreground ,yellow))))
   `(term-color-bright-black ((,class (:foreground ,macos0))))
   `(term-color-bright-blue ((,class (:foreground ,purple))))
   `(term-color-bright-cyan ((,class (:foreground ,darkblue))))
   `(term-color-bright-green ((,class (:foreground ,green))))
   `(term-color-bright-magenta ((,class (:foreground ,magenta))))
   `(term-color-bright-purple ((,class (:foreground ,teal))))
   `(term-color-bright-red ((,class (:foreground ,red))))
   `(term-color-bright-white ((,class (:foreground ,macos8))))
   `(term-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; tldr - dark
   `(tldr-code-block ((,class (:foreground ,green :weight bold))))
   `(tldr-command-argument ((,class (:foreground ,fg))))
   `(tldr-command-itself ((,class (:foreground ,green :weight bold))))
   `(tldr-description ((,class (:foreground ,macos4))))
   `(tldr-introduction ((,class (:foreground ,blue))))
   `(tldr-title ((,class (:foreground ,darkred :weight bold :height 1.4))))

;;;; transient - dark
   `(transient-key ((,class (:foreground ,blue :height 1.1))))
   `(transient-blue ((,class (:foreground ,purple))))
   `(transient-pink ((,class (:foreground ,magenta))))
   `(transient-purple ((,class (:foreground ,teal))))
   `(transient-red ((,class (:foreground ,red))))
   `(transient-teal ((,class (:foreground ,blue))))

;;;; treemacs - dark
   `(treemacs-directory-face ((,class (:foreground ,fg))))
   `(treemacs-file-face ((,class (:foreground ,fg))))
   `(treemacs-git-added-face ((,class (:foreground ,green))))
   `(treemacs-git-conflict-face ((,class (:foreground ,red))))
   `(treemacs-git-modified-face ((,class (:foreground ,magenta))))
   `(treemacs-git-untracked-face ((,class (:foreground ,macos5))))
   `(treemacs-root-face ((,class (:foreground ,blue :weight bold :height 1.2))))
   `(treemacs-tags-face ((,class (:foreground ,red))))

;;;; treemacs-all-the-icons - dark
     `(treemacs-all-the-icons-file-face ((,class (:foreground ,blue))))
     `(treemacs-all-the-icons-root-face ((,class (:foreground ,fg))))

;;;; tree-sitter-hl - dark
   `(tree-sitter-hl-face:function ((,class (:foreground ,teal))))
   `(tree-sitter-hl-face:function.call ((,class (:foreground ,teal))))
   `(tree-sitter-hl-face:function.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:function.special ((,class (:foreground ,fg :weight bold))))
   `(tree-sitter-hl-face:function.macro ((,class (:foreground ,fg :weight bold))))
   `(tree-sitter-hl-face:method ((,class (:foreground ,lightcyan))))
   `(tree-sitter-hl-face:method.call ((,class (:foreground ,lightcyan))))
   `(tree-sitter-hl-face:type ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:type.parameter ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:type.argument ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:type.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:type.super ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:constructor ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:variable ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:variable.parameter ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:variable.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:variable.special ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:property ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:property.definition ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:comment ((,class (:foreground ,macos4 :slant italic))))
   `(tree-sitter-hl-face:doc ((,class (:foreground ,grey :slant italic))))
   `(tree-sitter-hl-face:string ((,class (:foreground ,green))))
   `(tree-sitter-hl-face:string.special ((,class (:foreground ,green :weight bold))))
   `(tree-sitter-hl-face:escape ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:embedded ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:keyword ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:operator ((,class (:foreground ,green))))
   `(tree-sitter-hl-face:label ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:constant ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:constant.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:number ((,class (:foreground ,green))))
   `(tree-sitter-hl-face:punctuation ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.bracket ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.delimiter ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.special ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:tag ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:attribute ((,class (:foreground ,fg))))

;;;; typescript-mode - dark
   `(typescript-jsdoc-tag ((,class (:foreground ,macos5))))
   `(typescript-jsdoc-type ((,class (:foreground ,macos5))))
   `(typescript-jsdoc-value ((,class (:foreground ,macos5))))

;;;; undo-tree - dark
   `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,purple))))
   `(undo-tree-visualizer-current-face ((,class (:foreground ,green :weight bold))))
   `(undo-tree-visualizer-default-face ((,class (:foreground ,macos5))))
   `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow))))
   `(undo-tree-visualizer-unmodified-face ((,class (:foreground ,macos5))))

;;;; vimish-fold - dark
   `(vimish-fold-fringe ((,class (:foreground ,teal))))
   `(vimish-fold-overlay ((,class (:foreground ,macos5 :background ,macos0 :weight light))))

;;;; volatile-highlights - dark
   `(vhl/default-face ((,class (:background ,grey))))

;;;; vterm - dark
   `(vterm ((,class (:foreground ,fg))))
   `(vterm-color-black ((,class (:background ,macos0 :foreground ,macos0))))
   `(vterm-color-blue ((,class (:background ,purple :foreground ,purple))))
   `(vterm-color-cyan ((,class (:background ,darkblue :foreground ,darkblue))))
   `(vterm-color-default ((,class (:foreground ,fg))))
   `(vterm-color-green ((,class (:background ,green :foreground ,green))))
   `(vterm-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
   `(vterm-color-purple ((,class (:background ,teal :foreground ,teal))))
   `(vterm-color-red ((,class (:background ,red :foreground ,red))))
   `(vterm-color-white ((,class (:background ,macos8 :foreground ,macos8))))
   `(vterm-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

;;;; web-mode - dark
   `(web-mode-block-control-face ((,class (:foreground ,red))))
   `(web-mode-block-control-face ((,class (:foreground ,red))))
   `(web-mode-block-delimiter-face ((,class (:foreground ,red))))
   `(web-mode-css-property-name-face ((,class (:foreground ,yellow))))
   `(web-mode-doctype-face ((,class (:foreground ,macos5))))
   `(web-mode-html-attr-name-face ((,class (:foreground ,purple))))
   `(web-mode-html-attr-value-face ((,class (:foreground ,yellow))))
   `(web-mode-html-entity-face ((,class (:foreground ,darkblue :slant italic))))
   `(web-mode-html-tag-bracket-face ((,class (:foreground ,purple))))
   `(web-mode-html-tag-bracket-face ((,class (:foreground ,fg))))
   `(web-mode-html-tag-face ((,class (:foreground ,blue))))
   `(web-mode-json-context-face ((,class (:foreground ,green))))
   `(web-mode-json-key-face ((,class (:foreground ,green))))
   `(web-mode-keyword-face ((,class (:foreground ,magenta))))
   `(web-mode-string-face ((,class (:foreground ,green))))
   `(web-mode-type-face ((,class (:foreground ,yellow))))

;;;; wgrep - dark
   `(wgrep-delete-face ((,class (:foreground ,macos3 :background ,red))))
   `(wgrep-done-face ((,class (:foreground ,purple))))
   `(wgrep-face ((,class (:weight bold :foreground ,green :background ,macos5))))
   `(wgrep-file-face ((,class (:foreground ,macos5))))
   `(wgrep-reject-face ((,class (:foreground ,red :weight bold))))

;;;; which-func - dark
   `(which-func ((,class (:foreground ,purple))))

;;;; which-key - dark
   `(which-key-command-description-face ((,class (:foreground ,teal))))
   `(which-key-group-description-face ((,class (:foreground ,blue))))
   `(which-key-key-face ((,class (:foreground ,magenta :weight bold :height 1.1))))
   `(which-key-local-map-description-face ((,class (:foreground ,teal))))

;;;; whitespace - dark
   `(whitespace-empty ((,class (:background ,macos3))))
   `(whitespace-indentation ((,class (:foreground ,macos4 :background ,macos3))))
   `(whitespace-line ((,class (:background ,macos0 :foreground ,red :weight bold))))
   `(whitespace-newline ((,class (:foreground ,macos4))))
   `(whitespace-space ((,class (:foreground ,macos4))))
   `(whitespace-tab ((,class (:foreground ,macos4 :background ,macos3))))
   `(whitespace-trailing ((,class (:background ,red))))

;;;; widget - dark
   `(widget-button ((,class (:foreground ,fg :weight bold))))
   `(widget-button-pressed ((,class (:foreground ,red))))
   `(widget-documentation ((,class (:foreground ,green))))
   `(widget-field ((,class (:foreground ,fg :background ,macos0 :extend nil))))
   `(widget-inactive ((,class (:foreground ,grey :background ,bg-other))))
   `(widget-single-line-field ((,class (:foreground ,fg :background ,macos0))))

;;;; window-divider - dark
   `(window-divider ((,class (:background ,red :foreground ,red))))
   `(window-divider-first-pixel ((,class (:background ,red :foreground ,red))))
   `(window-divider-last-pixel ((,class (:background ,red :foreground ,red))))

;;;; woman - dark
   `(woman-bold ((,class (:foreground ,fg :weight bold))))
   `(woman-italic ((,class (:foreground ,magenta :underline ,magenta))))

;;;; workgroups2 - dark
   `(wg-brace-face ((,class (:foreground ,red))))
   `(wg-current-workgroup-face ((,class (:foreground ,macos0 :background ,red))))
   `(wg-divider-face ((,class (:foreground ,grey))))
   `(wg-other-workgroup-face ((,class (:foreground ,macos5))))

;;;; yasnippet - dark
   `(yas-field-highlight-face ((,class (:foreground ,green :background ,macos0 :weight bold))))

;;;; ytel - dark
   `(ytel-video-published-face ((,class (:foreground ,purple))))
   `(ytel-channel-name-face ((,class (:foreground ,red))))
   `(ytel-video-length-face ((,class (:foreground ,cyan))))
   `(ytel-video-view-face ((,class (:foreground ,darkblue))))

   (custom-theme-set-variables
    'timu-macos
    `(ansi-color-names-vector [bg, red, green, teal, cyan, blue, yellow, fg])))))


;;; LIGHT FLAVOUR
(when (equal timu-macos-flavour "light")
(let ((class '((class color) (min-colors 89)))
      (bg        "#ffffff")
      (bg-org    "#f4f4f4")
      (bg-other  "#e8e8e8")
      (macos0    "#f4f4f4")
      (macos1    "#dedede")
      (macos2    "#b3b3b3")
      (macos3    "#b3b3b3")
      (macos4    "#8c8c8c")
      (macos5    "#5e5e5e")
      (macos6    "#616161")
      (macos7    "#393939")
      (macos8    "#2c2c2c")
      (fg        "#262626")
      (fg-other  "#2a2a2a")

      (grey      "#8c8c8c")
      (red       "#ec5f5e")
      (darkred   "#913a29")
      (orange    "#e8883a")
      (green     "#78b856")
      (blue      "#50a5eb")
      (magenta   "#e45c9c")
      (teal      "#91f3e7")
      (yellow    "#f6c844")
      (darkblue  "#3478f6")
      (purple    "#9b54a3")
      (cyan      "#88c0d0")
      (lightcyan "#46d9ff")
      (darkcyan  "#5297a5")

      (black     "#000000")
      (white     "#ffffff"))

  (custom-theme-set-faces
   'timu-macos

;;; Custom faces

;;;; timu-macos-faces - light
   `(timu-macos-grey-face ((,class (:foreground ,grey))))
   `(timu-macos-red-face ((,class (:foreground ,red))))
   `(timu-macos-darkred-face ((,class (:foreground ,darkred))))
   `(timu-macos-orange-face ((,class (:foreground ,orange))))
   `(timu-macos-green-face ((,class (:foreground ,green))))
   `(timu-macos-blue-face ((,class (:foreground ,purple))))
   `(timu-macos-magenta-face ((,class (:foreground ,magenta))))
   `(timu-macos-teal-face ((,class (:foreground ,blue))))
   `(timu-macos-yellow-face ((,class (:foreground ,yellow))))
   `(timu-macos-darkblue-face ((,class (:foreground ,darkblue))))
   `(timu-macos-purple-face ((,class (:foreground ,purple))))
   `(timu-macos-cyan-face ((,class (:foreground ,cyan))))
   `(timu-macos-darkcyan-face ((,class (:foreground ,darkcyan))))
   `(timu-macos-black-face ((,class (:foreground ,black))))
   `(timu-macos-white-face ((,class (:foreground ,white))))
   `(timu-macos-default-face ((,class (:background ,bg :foreground ,fg))))
   `(timu-macos-bold-face ((,class (:weight bold :foreground ,black))))
   `(timu-macos-bold-face-italic ((,class (:weight bold :slant italic :foreground ,black))))
   `(timu-macos-italic-face ((,class (:slant italic :foreground ,black))))
   `(timu-macos-underline-face ((,class (:underline ,magenta))))
   `(timu-macos-strike-through-face ((,class (:strike-through ,magenta))))

;;;; default - light faces
   `(bold ((,class (:weight bold))))
   `(bold-italic ((,class (:weight bold :slant italic))))
   `(bookmark-face ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(cursor ((,class (:background ,blue))))
   `(default ((,class (:background ,bg :foreground ,fg))))
   `(error ((,class (:foreground ,red))))
   `(fringe ((,class (:foreground ,macos4))))
   `(highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(italic ((,class (:slant  italic))))
   `(lazy-highlight ((,class (:background ,darkblue  :foreground ,macos8 :distant-foreground ,macos0 :weight bold))))
   `(link ((,class (:foreground ,blue :underline t :weight bold))))
   `(match ((,class (:foreground ,green :background ,macos0 :weight bold))))
   `(minibuffer-prompt ((,class (:foreground ,red))))
   `(nobreak-space ((,class (:background ,bg :foreground ,fg))))
   `(region ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
   `(secondary-selection ((,class (:background ,grey :extend t))))
   `(shadow ((,class (:foreground ,macos5))))
   `(success ((,class (:foreground ,green))))
   `(tooltip ((,class (:background ,bg-other :foreground ,fg))))
   `(trailing-whitespace ((,class (:background ,red))))
   `(vertical-border ((,class (:background ,blue :foreground ,blue))))
   `(warning ((,class (:foreground ,yellow))))

;;;; font-lock - light
   `(font-lock-builtin-face ((,class (:foreground ,blue))))
   `(font-lock-comment-delimiter-face ((,class (:foreground ,macos4))))
   `(font-lock-comment-face ((,class (:foreground ,macos4 :slant italic))))
   `(font-lock-constant-face ((,class (:foreground ,red))))
   `(font-lock-doc-face ((,class (:foreground ,grey :slant italic))))
   `(font-lock-function-name-face ((,class (:foreground ,blue))))
   `(font-lock-keyword-face ((,class (:foreground ,darkblue))))
   `(font-lock-negation-char-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-preprocessor-char-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-preprocessor-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-regexp-grouping-backslash ((,class (:foreground ,fg :weight bold))))
   `(font-lock-regexp-grouping-construct ((,class (:foreground ,fg :weight bold))))
   `(font-lock-string-face ((,class (:foreground ,green))))
   `(font-lock-type-face ((,class (:foreground ,blue))))
   `(font-lock-variable-name-face ((,class (:foreground ,magenta))))
   `(font-lock-warning-face ((,class (:foreground ,yellow))))

;;;; ace-window - light
   `(aw-leading-char-face ((,class (:foreground ,red :height 500 :weight bold))))
   `(aw-background-face ((,class (:foreground ,macos5))))

;;;; alert - light
   `(alert-high-face ((,class (:foreground ,yellow :weight bold))))
   `(alert-low-face ((,class (:foreground ,grey))))
   `(alert-moderate-face ((,class (:foreground ,fg-other :weight bold))))
   `(alert-trivial-face ((,class (:foreground ,macos5))))
   `(alert-urgent-face ((,class (:foreground ,red :weight bold))))

;;;; all-the-icons - light
   `(all-the-icons-blue ((,class (:foreground ,purple))))
   `(all-the-icons-blue-alt ((,class (:foreground ,blue))))
   `(all-the-icons-cyan ((,class (:foreground ,darkblue))))
   `(all-the-icons-cyan-alt ((,class (:foreground ,darkblue))))
   `(all-the-icons-dblue ((,class (:foreground ,darkblue))))
   `(all-the-icons-dcyan ((,class (:foreground ,darkcyan))))
   `(all-the-icons-dgreen ((,class (:foreground ,green))))
   `(all-the-icons-dmagenta ((,class (:foreground ,red))))
   `(all-the-icons-dmaroon ((,class (:foreground ,teal))))
   `(all-the-icons-dorange ((,class (:foreground ,blue))))
   `(all-the-icons-dpurple ((,class (:foreground ,magenta))))
   `(all-the-icons-dred ((,class (:foreground ,red))))
   `(all-the-icons-dsilver ((,class (:foreground ,grey))))
   `(all-the-icons-dyellow ((,class (:foreground ,yellow))))
   `(all-the-icons-green ((,class (:foreground ,green))))
   `(all-the-icons-lblue ((,class (:foreground ,purple))))
   `(all-the-icons-lcyan ((,class (:foreground ,darkblue))))
   `(all-the-icons-lgreen ((,class (:foreground ,green))))
   `(all-the-icons-lmagenta ((,class (:foreground ,red))))
   `(all-the-icons-lmaroon ((,class (:foreground ,teal))))
   `(all-the-icons-lorange ((,class (:foreground ,blue))))
   `(all-the-icons-lpurple ((,class (:foreground ,magenta))))
   `(all-the-icons-lred ((,class (:foreground ,red))))
   `(all-the-icons-lsilver ((,class (:foreground ,grey))))
   `(all-the-icons-lyellow ((,class (:foreground ,yellow))))
   `(all-the-icons-magenta ((,class (:foreground ,red))))
   `(all-the-icons-maroon ((,class (:foreground ,teal))))
   `(all-the-icons-orange ((,class (:foreground ,blue))))
   `(all-the-icons-purple ((,class (:foreground ,magenta))))
   `(all-the-icons-purple-alt ((,class (:foreground ,magenta))))
   `(all-the-icons-red ((,class (:foreground ,red))))
   `(all-the-icons-red-alt ((,class (:foreground ,red))))
   `(all-the-icons-silver ((,class (:foreground ,grey))))
   `(all-the-icons-yellow ((,class (:foreground ,yellow))))
   `(all-the-icons-ibuffer-mode-face ((,class (:foreground ,purple))))
   `(all-the-icons-ibuffer-dir-face ((,class (:foreground ,cyan))))
   `(all-the-icons-ibuffer-file-face ((,class (:foreground ,blue))))
   `(all-the-icons-ibuffer-icon-face ((,class (:foreground ,magenta))))
   `(all-the-icons-ibuffer-size-face ((,class (:foreground ,yellow))))

;;;; all-the-icons-dired - light
   `(all-the-icons-dired-dir-face ((,class (:foreground ,fg-other))))

;;;; all-the-icons-ivy-rich - light
   `(all-the-icons-ivy-rich-doc-face ((,class (:foreground ,purple))))
   `(all-the-icons-ivy-rich-path-face ((,class (:foreground ,purple))))
   `(all-the-icons-ivy-rich-size-face ((,class (:foreground ,purple))))
   `(all-the-icons-ivy-rich-time-face ((,class (:foreground ,purple))))

;;;; annotate - light
   `(annotate-annotation ((,class (:background ,red :foreground ,macos5))))
   `(annotate-annotation-secondary ((,class (:background ,green :foreground ,macos5))))
   `(annotate-highlight ((,class (:background ,red :underline ,red))))
   `(annotate-highlight-secondary ((,class (:background ,green :underline ,green))))

;;;; ansi - light
   `(ansi-color-black ((,class (:foreground ,macos0))))
   `(ansi-color-blue ((,class (:foreground ,purple))))
   `(ansi-color-cyan ((,class (:foreground ,darkblue))))
   `(ansi-color-green ((,class (:foreground ,green))))
   `(ansi-color-magenta ((,class (:foreground ,magenta))))
   `(ansi-color-purple ((,class (:foreground ,teal))))
   `(ansi-color-red ((,class (:foreground ,red))))
   `(ansi-color-white ((,class (:foreground ,macos8))))
   `(ansi-color-yellow ((,class (:foreground ,yellow))))
   `(ansi-color-bright-black ((,class (:foreground ,macos0))))
   `(ansi-color-bright-blue ((,class (:foreground ,purple))))
   `(ansi-color-bright-cyan ((,class (:foreground ,darkblue))))
   `(ansi-color-bright-green ((,class (:foreground ,green))))
   `(ansi-color-bright-magenta ((,class (:foreground ,magenta))))
   `(ansi-color-bright-purple ((,class (:foreground ,teal))))
   `(ansi-color-bright-red ((,class (:foreground ,red))))
   `(ansi-color-bright-white ((,class (:foreground ,macos8))))
   `(ansi-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; anzu - light
   `(anzu-replace-highlight ((,class (:background ,macos0 :foreground ,red :weight bold :strike-through t))))
   `(anzu-replace-to ((,class (:background ,macos0 :foreground ,green :weight bold))))

;;;; auctex - light
   `(TeX-error-description-error ((,class (:foreground ,red :weight bold))))
   `(TeX-error-description-tex-said ((,class (:foreground ,green :weight bold))))
   `(TeX-error-description-warning ((,class (:foreground ,yellow :weight bold))))
   `(font-latex-bold-face ((,class (:weight bold))))
   `(font-latex-italic-face ((,class (:slant italic))))
   `(font-latex-math-face ((,class (:foreground ,purple))))
   `(font-latex-sedate-face ((,class (:foreground ,darkblue))))
   `(font-latex-script-char-face ((,class (:foreground ,darkblue))))
   `(font-latex-sectioning-0-face ((,class (:foreground ,purple :weight ultra-bold))))
   `(font-latex-sectioning-1-face ((,class (:foreground ,green :weight semi-bold))))
   `(font-latex-sectioning-2-face ((,class (:foreground ,magenta :weight semi-bold))))
   `(font-latex-sectioning-3-face ((,class (:foreground ,purple :weight semi-bold))))
   `(font-latex-sectioning-4-face ((,class (:foreground ,green :weight semi-bold))))
   `(font-latex-sectioning-5-face ((,class (:foreground ,magenta :weight semi-bold))))
   `(font-latex-string-face ((,class (:foreground ,green))))
   `(font-latex-verbatim-face ((,class (:foreground ,darkcyan :slant italic))))
   `(font-latex-warning-face ((,class (:foreground ,yellow))))

;;;; avy - light
   `(avy-background-face ((,class (:foreground ,macos5))))
   `(avy-lead-face ((,class (:background ,blue :foreground ,black))))
   `(avy-lead-face-0 ((,class (:background ,blue :foreground ,black))))
   `(avy-lead-face-1 ((,class (:background ,blue :foreground ,black))))
   `(avy-lead-face-2 ((,class (:background ,blue :foreground ,black))))

;;;; bookmark+ - light
   `(bmkp-*-mark ((,class (:foreground ,bg :background ,yellow))))
   `(bmkp->-mark ((,class (:foreground ,yellow))))
   `(bmkp-D-mark ((,class (:foreground ,bg :background ,red))))
   `(bmkp-X-mark ((,class (:foreground ,red))))
   `(bmkp-a-mark ((,class (:background ,red))))
   `(bmkp-bad-bookmark ((,class (:foreground ,bg :background ,yellow))))
   `(bmkp-bookmark-file ((,class (:foreground ,magenta :background ,bg-other))))
   `(bmkp-bookmark-list ((,class (:background ,bg-other))))
   `(bmkp-buffer ((,class (:foreground ,purple))))
   `(bmkp-desktop ((,class (:foreground ,bg :background ,magenta))))
   `(bmkp-file-handler ((,class (:background ,red))))
   `(bmkp-function ((,class (:foreground ,green))))
   `(bmkp-gnus ((,class (:foreground ,red))))
   `(bmkp-heading ((,class (:foreground ,yellow))))
   `(bmkp-info ((,class (:foreground ,darkblue))))
   `(bmkp-light-autonamed ((,class (:foreground ,bg-other :background ,darkblue))))
   `(bmkp-light-autonamed-region ((,class (:foreground ,bg-other :background ,red))))
   `(bmkp-light-fringe-autonamed ((,class (:foreground ,bg-other :background ,magenta))))
   `(bmkp-light-fringe-non-autonamed ((,class (:foreground ,bg-other :background ,green))))
   `(bmkp-light-mark ((,class (:foreground ,bg :background ,darkblue))))
   `(bmkp-light-non-autonamed ((,class (:foreground ,bg :background ,magenta))))
   `(bmkp-light-non-autonamed-region ((,class (:foreground ,bg :background ,red))))
   `(bmkp-local-directory ((,class (:foreground ,bg :background ,magenta))))
   `(bmkp-local-file-with-region ((,class (:foreground ,yellow))))
   `(bmkp-local-file-without-region ((,class (:foreground ,macos5))))
   `(bmkp-man ((,class (:foreground ,magenta))))
   `(bmkp-no-jump ((,class (:foreground ,macos5))))
   `(bmkp-no-local ((,class (:foreground ,yellow))))
   `(bmkp-non-file ((,class (:foreground ,green))))
   `(bmkp-remote-file ((,class (:foreground ,red))))
   `(bmkp-sequence ((,class (:foreground ,purple))))
   `(bmkp-su-or-sudo ((,class (:foreground ,red))))
   `(bmkp-t-mark ((,class (:foreground ,magenta))))
   `(bmkp-url ((,class (:foreground ,purple :underline t))))
   `(bmkp-variable-list ((,class (:foreground ,green))))

;;;; calfw - light
   `(cfw:face-annotation ((,class (:foreground ,magenta))))
   `(cfw:face-day-title ((,class (:foreground ,fg :weight bold))))
   `(cfw:face-default-content ((,class (:foreground ,fg))))
   `(cfw:face-default-day ((,class (:weight bold))))
   `(cfw:face-disable ((,class (:foreground ,grey))))
   `(cfw:face-grid ((,class (:foreground ,bg))))
   `(cfw:face-header ((,class (:foreground ,purple :weight bold))))
   `(cfw:face-holiday ((,class (:foreground nil :background ,bg-other :weight bold))))
   `(cfw:face-periods ((,class (:foreground ,yellow))))
   `(cfw:face-saturday ((,class (:foreground ,red :weight bold))))
   `(cfw:face-select ((,class (:background ,grey))))
   `(cfw:face-sunday ((,class (:foreground ,red :weight bold))))
   `(cfw:face-title ((,class (:foreground ,purple :weight bold :height 2.0))))
   `(cfw:face-today ((,class (:foreground nil :background nil :weight bold))))
   `(cfw:face-today-title ((,class (:foreground ,bg :background ,purple :weight bold))))
   `(cfw:face-toolbar ((,class (:foreground nil :background nil))))
   `(cfw:face-toolbar-button-off ((,class (:foreground ,macos6 :weight bold))))
   `(cfw:face-toolbar-button-on ((,class (:foreground ,purple :weight bold))))

;;;; centaur-tabs - light
   `(centaur-tabs-active-bar-face ((,class (:background ,bg :foreground ,fg))))
   `(centaur-tabs-close-mouse-face ((,class (:foreground ,magenta))))
   `(centaur-tabs-close-selected ((,class (:background ,bg :foreground ,fg))))
   `(centaur-tabs-close-unselected ((,class (:background ,bg-other :foreground ,grey))))
   `(centaur-tabs-default ((,class (:background ,bg-other :foreground ,fg))))
   `(centaur-tabs-modified-marker-selected ((,class (:background ,bg :foreground ,blue))))
   `(centaur-tabs-modified-marker-unselected ((,class (:background ,bg :foreground ,blue))))
   `(centaur-tabs-name-mouse-face ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(centaur-tabs-selected ((,class (:background ,bg :foreground ,blue))))
   `(centaur-tabs-selected-modified ((,class (:background ,bg :foreground ,magenta))))
   `(centaur-tabs-unselected ((,class (:background ,bg-other :foreground ,grey))))
   `(centaur-tabs-unselected-modified ((,class (:background ,bg-other :foreground ,magenta))))

;;;; circe - light
   `(circe-fool ((,class (:foreground ,macos5))))
   `(circe-highlight-nick-face ((,class (:weight bold :foreground ,blue))))
   `(circe-my-message-face ((,class (:weight bold))))
   `(circe-prompt-face ((,class (:weight bold :foreground ,blue))))
   `(circe-server-face ((,class (:foreground ,macos5))))

;;;; company - light
   `(company-preview ((,class (:background ,bg-other :foreground ,macos5))))
   `(company-preview-common ((,class (:background ,macos3 :foreground ,cyan))))
   `(company-preview-search ((,class (:background ,cyan :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(company-scrollbar-bg ((,class (:background ,bg-other :foreground ,fg))))
   `(company-scrollbar-fg ((,class (:background ,cyan))))
   `(company-template-field ((,class (:foreground ,green :background ,macos0 :weight bold))))
   `(company-tooltip ((,class (:background ,bg-other :foreground ,fg))))
   `(company-tooltip-annotation ((,class (:foreground ,magenta :distant-foreground ,bg))))
   `(company-tooltip-common ((,class (:foreground ,cyan :distant-foreground ,macos0 :weight bold))))
   `(company-tooltip-mouse ((,class (:background ,teal :foreground ,bg :distant-foreground ,fg))))
   `(company-tooltip-search ((,class (:background ,cyan :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(company-tooltip-search-selection ((,class (:background ,grey))))
   `(company-tooltip-selection ((,class (:background ,grey :weight bold))))

;;;; company-box - light
   `(company-box-candidate ((,class (:foreground ,fg))))

;;;; compilation - light
   `(compilation-column-number ((,class (:foreground ,macos5))))
   `(compilation-error ((,class (:foreground ,red :weight bold))))
   `(compilation-info ((,class (:foreground ,green))))
   `(compilation-line-number ((,class (:foreground ,red))))
   `(compilation-mode-line-exit ((,class (:foreground ,green))))
   `(compilation-mode-line-fail ((,class (:foreground ,red :weight bold))))
   `(compilation-warning ((,class (:foreground ,yellow :slant italic))))

;;;; consult - light
   `(consult-file ((,class (:foreground ,blue))))

;;;; corfu - light
   `(corfu-bar ((,class (:background ,bg-org :foreground ,fg))))
   `(corfu-echo ((,class (:foreground ,magenta))))
   `(corfu-border ((,class (:background ,macos1 :foreground ,fg))))
   `(corfu-current ((,class (:foreground ,magenta :weight bold :underline ,fg))))
   `(corfu-default ((,class (:background ,bg-org :foreground ,fg))))
   `(corfu-deprecated ((,class (:foreground ,blue))))
   `(corfu-annotations ((,class (:foreground ,magenta))))

;;;; counsel - light
   `(counsel-variable-documentation ((,class (:foreground ,purple))))

;;;; cperl - light
   `(cperl-array-face ((,class (:foreground ,red :weight bold))))
   `(cperl-hash-face ((,class (:foreground ,red :weight bold :slant italic))))
   `(cperl-nonoverridable-face ((,class (:foreground ,cyan))))

;;;; custom - light
   `(custom-button ((,class (:foreground ,fg :background ,bg-other :box (:line-width 3 :style released-button)))))
   `(custom-button-mouse ((,class (:foreground ,yellow :background ,bg-other :box (:line-width 3 :style released-button)))))
   `(custom-button-pressed ((,class (:foreground ,bg :background ,bg-other :box (:line-width 3 :style pressed-button)))))
   `(custom-button-pressed-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
   `(custom-button-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
   `(custom-changed ((,class (:foreground ,purple :background ,bg))))
   `(custom-comment ((,class (:foreground ,fg :background ,grey))))
   `(custom-comment-tag ((,class (:foreground ,grey))))
   `(custom-documentation ((,class (:foreground ,fg))))
   `(custom-face-tag ((,class (:foreground ,purple :weight bold))))
   `(custom-group-subtitle ((,class (:foreground ,magenta :weight bold))))
   `(custom-group-tag ((,class (:foreground ,magenta :weight bold))))
   `(custom-group-tag-1 ((,class (:foreground ,purple))))
   `(custom-invalid ((,class (:foreground ,red))))
   `(custom-link ((,class (:foreground ,cyan :underline t))))
   `(custom-modified ((,class (:foreground ,purple))))
   `(custom-rogue ((,class (:foreground ,purple :box (:line-width 3 :style none)))))
   `(custom-saved ((,class (:foreground ,green :weight bold))))
   `(custom-set ((,class (:foreground ,yellow :background ,bg))))
   `(custom-state ((,class (:foreground ,green))))
   `(custom-themed ((,class (:foreground ,yellow :background ,bg))))
   `(custom-variable-button ((,class (:foreground ,green :underline t))))
   `(custom-variable-obsolete ((,class (:foreground ,grey :background ,bg))))
   `(custom-variable-tag ((,class (:foreground ,darkcyan :underline t :extend nil))))
   `(custom-visibility ((,class (:foreground ,yellow :height 0.8 :underline t))))

;;; diff
   `(diff-added ((,class (:foreground ,bg :background ,green :extend t))))
   `(diff-indicator-added ((,class (:foreground ,bg :weight bold :background ,green :extend t))))
   `(diff-refine-added ((,class (:foreground ,bg :weight bold :background ,green :extend t))))
   `(diff-changed ((,class (:foreground ,bg :background ,yellow :extend t))))
   `(diff-indicator-changed ((,class (:foreground ,bg :weight bold :background ,yellow :extend t))))
   `(diff-refine-changed ((,class (:foreground ,bg :weight bold :background ,yellow :extend t))))
   `(diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
   `(diff-indicator-removed ((,class (:foreground ,bg :weight bold :background ,red :extend t))))
   `(diff-refine-removed ((,class (:foreground ,bg :weight bold :background ,red :extend t))))
   `(diff-header ((,class (:foreground ,darkcyan))))
   `(diff-file-header ((,class (:foreground ,blue :weight bold))))
   `(diff-hunk-header ((,class (:foreground ,bg :background ,magenta :extend t))))
   `(diff-function ((,class (:foreground ,bg :background ,magenta :extend t))))

;;;; diff-hl - light
   `(diff-hl-change ((,class (:foreground ,blue :background ,blue))))
   `(diff-hl-delete ((,class (:foreground ,red :background ,red))))
   `(diff-hl-insert ((,class (:foreground ,green :background ,green))))

;;;; dired - light
   `(dired-directory ((,class (:foreground ,blue :underline ,blue))))
   `(dired-flagged ((,class (:foreground ,red))))
   `(dired-header ((,class (:foreground ,cyan :weight bold :underline ,darkcyan))))
   `(dired-ignored ((,class (:foreground ,macos5))))
   `(dired-mark ((,class (:foreground ,cyan :weight bold))))
   `(dired-marked ((,class (:foreground ,yellow :weight bold))))
   `(dired-perm-write ((,class (:foreground ,red :underline t))))
   `(dired-symlink ((,class (:foreground ,magenta))))
   `(dired-warning ((,class (:foreground ,yellow))))

;;;; dired-async - light
   `(dired-async-failures ((,class (:foreground ,red))))
   `(dired-async-message ((,class (:foreground ,cyan))))
   `(dired-async-mode-message ((,class (:foreground ,cyan))))

;;;; dired-filetype-face - light
   `(dired-filetype-common ((,class (:foreground ,fg))))
   `(dired-filetype-compress ((,class (:foreground ,yellow))))
   `(dired-filetype-document ((,class (:foreground ,cyan))))
   `(dired-filetype-execute ((,class (:foreground ,red))))
   `(dired-filetype-image ((,class (:foreground ,darkred))))
   `(dired-filetype-js ((,class (:foreground ,yellow))))
   `(dired-filetype-link ((,class (:foreground ,magenta))))
   `(dired-filetype-music ((,class (:foreground ,magenta))))
   `(dired-filetype-omit ((,class (:foreground ,purple))))
   `(dired-filetype-plain ((,class (:foreground ,fg))))
   `(dired-filetype-program ((,class (:foreground ,red))))
   `(dired-filetype-source ((,class (:foreground ,green))))
   `(dired-filetype-video ((,class (:foreground ,magenta))))
   `(dired-filetype-xml ((,class (:foreground ,green))))

;;;; dired - light+
   `(diredp-compressed-file-suffix ((,class (:foreground ,macos5))))
   `(diredp-date-time ((,class (:foreground ,purple))))
   `(diredp-dir-heading ((,class (:foreground ,purple :weight bold))))
   `(diredp-dir-name ((,class (:foreground ,macos8 :weight bold))))
   `(diredp-dir-priv ((,class (:foreground ,purple :weight bold))))
   `(diredp-exec-priv ((,class (:foreground ,yellow))))
   `(diredp-file-name ((,class (:foreground ,macos8))))
   `(diredp-file-suffix ((,class (:foreground ,magenta))))
   `(diredp-ignored-file-name ((,class (:foreground ,macos5))))
   `(diredp-no-priv ((,class (:foreground ,macos5))))
   `(diredp-number ((,class (:foreground ,teal))))
   `(diredp-rare-priv ((,class (:foreground ,red :weight bold))))
   `(diredp-read-priv ((,class (:foreground ,teal))))
   `(diredp-symlink ((,class (:foreground ,magenta))))
   `(diredp-write-priv ((,class (:foreground ,green))))

;;;; dired-k - light
   `(dired-k-added ((,class (:foreground ,green :weight bold))))
   `(dired-k-commited ((,class (:foreground ,green :weight bold))))
   `(dired-k-directory ((,class (:foreground ,purple :weight bold))))
   `(dired-k-ignored ((,class (:foreground ,macos5 :weight bold))))
   `(dired-k-modified ((,class (:foreground , :weight bold))))
   `(dired-k-untracked ((,class (:foreground ,orange :weight bold))))

;;;; dired-subtree - light
   `(dired-subtree-depth-1-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-2-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-3-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-4-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-5-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-6-face ((,class (:background ,bg-other))))

;;;; diredfl - light
   `(diredfl-autofile-name ((,class (:foreground ,macos4))))
   `(diredfl-compressed-file-name ((,class (:foreground ,blue))))
   `(diredfl-compressed-file-suffix ((,class (:foreground ,yellow))))
   `(diredfl-date-time ((,class (:foreground ,darkblue :weight light))))
   `(diredfl-deletion ((,class (:foreground ,red :weight bold))))
   `(diredfl-deletion-file-name ((,class (:foreground ,red))))
   `(diredfl-dir-heading ((,class (:foreground ,purple :weight bold))))
   `(diredfl-dir-name ((,class (:foreground ,darkcyan))))
   `(diredfl-dir-priv ((,class (:foreground ,purple))))
   `(diredfl-exec-priv ((,class (:foreground ,red))))
   `(diredfl-executable-tag ((,class (:foreground ,red))))
   `(diredfl-file-name ((,class (:foreground ,fg))))
   `(diredfl-file-suffix ((,class (:foreground ,orange))))
   `(diredfl-flag-mark ((,class (:foreground ,yellow :background ,yellow :weight bold))))
   `(diredfl-flag-mark-line ((,class (:background ,yellow))))
   `(diredfl-ignored-file-name ((,class (:foreground ,macos5))))
   `(diredfl-link-priv ((,class (:foreground ,magenta))))
   `(diredfl-no-priv ((,class (:foreground ,fg))))
   `(diredfl-number ((,class (:foreground ,blue))))
   `(diredfl-other-priv ((,class (:foreground ,teal))))
   `(diredfl-rare-priv ((,class (:foreground ,fg))))
   `(diredfl-read-priv ((,class (:foreground ,yellow))))
   `(diredfl-symlink ((,class (:foreground ,magenta))))
   `(diredfl-tagged-autofile-name ((,class (:foreground ,macos5))))
   `(diredfl-write-priv ((,class (:foreground ,red))))

;;;; doom-modeline - light
   `(doom-modeline-bar ((,class (:foreground ,magenta))))
   `(doom-modeline-bar-inactive ((,class (:background nil))))
   `(doom-modeline-buffer-major-mode ((,class (:foreground ,magenta))))
   `(doom-modeline-buffer-path ((,class (:foreground ,magenta))))
   `(doom-modeline-eldoc-bar ((,class (:background ,green))))
   `(doom-modeline-evil-emacs-state ((,class (:foreground ,darkblue :weight bold))))
   `(doom-modeline-evil-insert-state ((,class (:foreground ,red :weight bold))))
   `(doom-modeline-evil-motion-state ((,class (:foreground ,purple :weight bold))))
   `(doom-modeline-evil-normal-state ((,class (:foreground ,green :weight bold))))
   `(doom-modeline-evil-operator-state ((,class (:foreground ,magenta :weight bold))))
   `(doom-modeline-evil-replace-state ((,class (:foreground ,teal :weight bold))))
   `(doom-modeline-evil-visual-state ((,class (:foreground ,yellow :weight bold))))
   `(doom-modeline-highlight ((,class (:foreground ,magenta))))
   `(doom-modeline-input-method ((,class (:foreground ,magenta))))
   `(doom-modeline-panel ((,class (:foreground ,magenta))))
   `(doom-modeline-project-dir ((,class (:foreground ,blue :weight bold))))
   `(doom-modeline-project-root-dir ((,class (:foreground ,magenta))))

;;;; ediff - light
   `(ediff-current-diff-A ((,class (:foreground ,bg :background ,red :extend t))))
   `(ediff-current-diff-B ((,class (:foreground ,bg :background ,green :extend t))))
   `(ediff-current-diff-C ((,class (:foreground ,bg :background ,yellow :extend t))))
   `(ediff-even-diff-A ((,class (:background ,bg-other :extend t))))
   `(ediff-even-diff-B ((,class (:background ,bg-other :extend t))))
   `(ediff-even-diff-C ((,class (:background ,bg-other :extend t))))
   `(ediff-fine-diff-A ((,class (:background ,red :weight bold :underline t :extend t))))
   `(ediff-fine-diff-B ((,class (:background ,green :weight bold :underline t :extend t))))
   `(ediff-fine-diff-C ((,class (:background ,yellow :weight bold :underline t :extend t))))
   `(ediff-odd-diff-A ((,class (:background ,bg-other :extend t))))
   `(ediff-odd-diff-B ((,class (:background ,bg-other :extend t))))
   `(ediff-odd-diff-C ((,class (:background ,bg-other :extend t))))

;;;; elfeed - light
   `(elfeed-log-debug-level-face ((,class (:foreground ,macos5))))
   `(elfeed-log-error-level-face ((,class (:foreground ,red))))
   `(elfeed-log-info-level-face ((,class (:foreground ,green))))
   `(elfeed-log-warn-level-face ((,class (:foreground ,yellow))))
   `(elfeed-search-date-face ((,class (:foreground ,cyan))))
   `(elfeed-search-feed-face ((,class (:foreground ,blue))))
   `(elfeed-search-filter-face ((,class (:foreground ,magenta))))
   `(elfeed-search-tag-face ((,class (:foreground ,macos5))))
   `(elfeed-search-title-face ((,class (:foreground ,macos5))))
   `(elfeed-search-unread-count-face ((,class (:foreground ,yellow))))
   `(elfeed-search-unread-title-face ((,class (:foreground ,fg :weight bold))))

;;;; elixir-mode - light
   `(elixir-atom-face ((,class (:foreground ,darkblue))))
   `(elixir-attribute-face ((,class (:foreground ,magenta))))

;;;; elscreen - light
   `(elscreen-tab-background-face ((,class (:background ,bg))))
   `(elscreen-tab-control-face ((,class (:background ,bg :foreground ,bg))))
   `(elscreen-tab-current-screen-face ((,class (:background ,bg-other :foreground ,fg))))
   `(elscreen-tab-other-screen-face ((,class (:background ,bg :foreground ,fg-other))))

;;;; enh-ruby-mode - light
   `(enh-ruby-heredoc-delimiter-face ((,class (:foreground ,blue))))
   `(enh-ruby-op-face ((,class (:foreground ,fg))))
   `(enh-ruby-regexp-delimiter-face ((,class (:foreground ,blue))))
   `(enh-ruby-regexp-face ((,class (:foreground ,blue))))
   `(enh-ruby-string-delimiter-face ((,class (:foreground ,blue))))
   `(erm-syn-errline ((,class (:underline (:style wave :color ,red)))))
   `(erm-syn-warnline ((,class (:underline (:style wave :color ,yellow)))))

;;;; erc - light
   `(erc-action-face  ((,class (:weight bold))))
   `(erc-button ((,class (:weight bold :underline t))))
   `(erc-command-indicator-face ((,class (:weight bold))))
   `(erc-current-nick-face ((,class (:foreground ,green :weight bold))))
   `(erc-default-face ((,class (:background ,bg :foreground ,fg))))
   `(erc-direct-msg-face ((,class (:foreground ,teal))))
   `(erc-error-face ((,class (:foreground ,red))))
   `(erc-header-line ((,class (:background ,bg-other :foreground ,blue))))
   `(erc-input-face ((,class (:foreground ,green))))
   `(erc-my-nick-face ((,class (:foreground ,green :weight bold))))
   `(erc-my-nick-prefix-face ((,class (:foreground ,green :weight bold))))
   `(erc-nick-default-face ((,class (:weight bold))))
   `(erc-nick-msg-face ((,class (:foreground ,teal))))
   `(erc-nick-prefix-face ((,class (:background ,bg :foreground ,fg))))
   `(erc-notice-face ((,class (:foreground ,macos5))))
   `(erc-prompt-face ((,class (:foreground ,blue :weight bold))))
   `(erc-timestamp-face ((,class (:foreground ,purple :weight bold))))

;;;; eshell - light
   `(eshell-ls-archive ((,class (:foreground ,yellow))))
   `(eshell-ls-backup ((,class (:foreground ,yellow))))
   `(eshell-ls-clutter ((,class (:foreground ,red))))
   `(eshell-ls-directory ((,class (:foreground ,blue))))
   `(eshell-ls-executable ((,class (:foreground ,red))))
   `(eshell-ls-missing ((,class (:foreground ,red))))
   `(eshell-ls-product ((,class (:foreground ,blue))))
   `(eshell-ls-readonly ((,class (:foreground ,blue))))
   `(eshell-ls-special ((,class (:foreground ,magenta))))
   `(eshell-ls-symlink ((,class (:foreground ,magenta))))
   `(eshell-ls-unreadable ((,class (:foreground ,macos5))))
   `(eshell-prompt ((,class (:foreground ,cyan :weight bold))))

;;;; evil - light
   `(evil-ex-info ((,class (:foreground ,red :slant italic))))
   `(evil-ex-search ((,class (:background ,blue :foreground ,macos0 :weight bold))))
   `(evil-ex-substitute-matches ((,class (:background ,macos0 :foreground ,red :weight bold :strike-through t))))
   `(evil-ex-substitute-replacement ((,class (:background ,macos0 :foreground ,green :weight bold))))
   `(evil-search-highlight-persist-highlight-face ((,class (:background ,darkblue  :foreground ,macos8 :distant-foreground ,macos0 :weight bold))))

;;;; evil-googles - light
   `(evil-goggles-default-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-mc - light
   `(evil-mc-cursor-bar-face ((,class (:height 1 :background ,teal :foreground ,macos0))))
   `(evil-mc-cursor-default-face ((,class (:background ,teal :foreground ,macos0 :inverse-video nil))))
   `(evil-mc-cursor-hbar-face ((,class (:underline (:color ,blue)))))
   `(evil-mc-region-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-snipe - light
   `(evil-snipe-first-match-face ((,class (:foreground ,red :background ,darkblue :weight bold))))
   `(evil-snipe-matches-face ((,class (:foreground ,red :underline t :weight bold))))

;;;; expenses - light
   `(expenses-face-date ((,class (:foreground ,red :weight bold))))
   `(expenses-face-expence ((,class (:foreground ,green :weight bold))))
   `(expenses-face-message ((,class (:foreground ,blue :weight bold))))

;;;; flx-ido - light
   `(flx-highlight-face ((,class (:weight bold :foreground ,yellow :underline nil))))

;;;; flycheck - light
   `(flycheck-error ((,class (:underline (:style wave :color ,red)))))
   `(flycheck-fringe-error ((,class (:foreground ,red))))
   `(flycheck-fringe-info ((,class (:foreground ,green))))
   `(flycheck-fringe-warning ((,class (:foreground ,yellow))))
   `(flycheck-info ((,class (:underline (:style wave :color ,green)))))
   `(flycheck-warning ((,class (:underline (:style wave :color ,yellow)))))

;;;; flycheck-posframe - light
   `(flycheck-posframe-background-face ((,class (:background ,bg-other))))
   `(flycheck-posframe-error-face ((,class (:foreground ,red))))
   `(flycheck-posframe-face ((,class (:background ,bg :foreground ,fg))))
   `(flycheck-posframe-info-face ((,class (:background ,bg :foreground ,fg))))
   `(flycheck-posframe-warning-face ((,class (:foreground ,yellow))))

;;;; flymake - light
   `(flymake-error ((,class (:underline (:style wave :color ,red)))))
   `(flymake-note ((,class (:underline (:style wave :color ,green)))))
   `(flymake-warning ((,class (:underline (:style wave :color ,blue)))))

;;;; flyspell - light
   `(flyspell-duplicate ((,class (:underline (:style wave :color ,yellow)))))
   `(flyspell-incorrect ((,class (:underline (:style wave :color ,red)))))

;;;; forge - light
   `(forge-topic-closed ((,class (:foreground ,macos5 :strike-through t))))
   `(forge-topic-label ((,class (:box nil))))

;;;; git-commit - light
   `(git-commit-comment-branch-local ((,class (:foreground ,teal))))
   `(git-commit-comment-branch-remote ((,class (:foreground ,green))))
   `(git-commit-comment-detached ((,class (:foreground ,cyan))))
   `(git-commit-comment-file ((,class (:foreground ,magenta))))
   `(git-commit-comment-heading ((,class (:foreground ,magenta))))
   `(git-commit-keyword ((,class (:foreground ,darkblue :slant italic))))
   `(git-commit-known-pseudo-header ((,class (:foreground ,macos5 :weight bold :slant italic))))
   `(git-commit-nonempty-second-line ((,class (:foreground ,red))))
   `(git-commit-overlong-summary ((,class (:foreground ,red :slant italic :weight bold))))
   `(git-commit-pseudo-header ((,class (:foreground ,macos5 :slant italic))))
   `(git-commit-summary ((,class (:foreground ,blue))))

;;;; git-gutter - light
   `(git-gutter:added ((,class (:foreground ,green))))
   `(git-gutter:deleted ((,class (:foreground ,red))))
   `(git-gutter:modified ((,class (:foreground ,darkblue))))

;;;; git-gutter - light+
   `(git-gutter+-added ((,class (:foreground ,green))))
   `(git-gutter+-deleted ((,class (:foreground ,red))))
   `(git-gutter+-modified ((,class (:foreground ,darkblue))))

;;;; git-gutter-fringe - light
   `(git-gutter-fr:added ((,class (:foreground ,green))))
   `(git-gutter-fr:deleted ((,class (:foreground ,red))))
   `(git-gutter-fr:modified ((,class (:foreground ,darkblue))))

;;;; gnus - light
   `(gnus-cite-1 ((,class (:foreground ,teal))))
   `(gnus-cite-2 ((,class (:foreground ,magenta))))
   `(gnus-cite-3 ((,class (:foreground ,darkblue))))
   `(gnus-cite-4 ((,class (:foreground ,darkcyan))))
   `(gnus-cite-5 ((,class (:foreground ,teal))))
   `(gnus-cite-6 ((,class (:foreground ,magenta))))
   `(gnus-cite-7 ((,class (:foreground ,darkblue))))
   `(gnus-cite-8 ((,class (:foreground ,darkcyan))))
   `(gnus-cite-9 ((,class (:foreground ,teal))))
   `(gnus-cite-10 ((,class (:foreground ,magenta))))
   `(gnus-cite-11 ((,class (:foreground ,darkblue))))
   `(gnus-group-mail-1 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-1-empty ((,class (:foreground ,macos5))))
   `(gnus-group-mail-2 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-2-empty ((,class (:foreground ,macos5))))
   `(gnus-group-mail-3 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-3-empty ((,class (:foreground ,macos5))))
   `(gnus-group-mail-low ((,class (:foreground ,fg))))
   `(gnus-group-mail-low-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-1 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-1-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-2 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-2-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-3 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-3-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-4 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-4-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-5 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-5-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-6 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-6-empty ((,class (:foreground ,macos5))))
   `(gnus-group-news-low ((,class (:weight bold :foreground ,macos5))))
   `(gnus-group-news-low-empty ((,class (:foreground ,fg))))
   `(gnus-header-content ((,class (:foreground ,blue))))
   `(gnus-header-from ((,class (:foreground ,magenta))))
   `(gnus-header-name ((,class (:foreground ,purple :weight bold))))
   `(gnus-header-newsgroups ((,class (:foreground ,purple))))
   `(gnus-header-subject ((,class (:foreground ,magenta :weight bold))))
   `(gnus-signature ((,class (:foreground ,yellow))))
   `(gnus-summary-cancelled ((,class (:foreground ,red :strike-through t))))
   `(gnus-summary-high-ancient ((,class (:foreground ,macos5 :slant italic))))
   `(gnus-summary-high-read ((,class (:foreground ,fg))))
   `(gnus-summary-high-ticked ((,class (:foreground ,teal))))
   `(gnus-summary-high-unread ((,class (:foreground ,green))))
   `(gnus-summary-low-ancient ((,class (:foreground ,macos5 :slant italic))))
   `(gnus-summary-low-read ((,class (:foreground ,fg))))
   `(gnus-summary-low-ticked ((,class (:foreground ,teal))))
   `(gnus-summary-low-unread ((,class (:foreground ,green))))
   `(gnus-summary-normal-ancient ((,class (:foreground ,macos5 :slant italic))))
   `(gnus-summary-normal-read ((,class (:foreground ,fg))))
   `(gnus-summary-normal-ticked ((,class (:foreground ,teal))))
   `(gnus-summary-normal-unread ((,class (:foreground ,green :weight bold))))
   `(gnus-summary-selected ((,class (:foreground ,purple :weight bold))))
   `(gnus-x-face ((,class (:background ,macos5 :foreground ,fg))))

;;;; goggles - light
   `(goggles-added ((,class (:background ,green))))
   `(goggles-changed ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
   `(goggles-removed ((,class (:background ,red :extend t))))

;;;; header-line - light
   `(header-line ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))

;;;; helm - light
   `(helm-ff-directory ((,class (:foreground ,red))))
   `(helm-ff-dotted-directory ((,class (:foreground ,grey))))
   `(helm-ff-executable ((,class (:foreground ,macos8 :slant italic))))
   `(helm-ff-file ((,class (:foreground ,fg))))
   `(helm-ff-prefix ((,class (:foreground ,magenta))))
   `(helm-grep-file ((,class (:foreground ,purple))))
   `(helm-grep-finish ((,class (:foreground ,green))))
   `(helm-grep-lineno ((,class (:foreground ,macos5))))
   `(helm-grep-match ((,class (:foreground ,blue :distant-foreground ,red))))
   `(helm-match ((,class (:foreground ,blue :distant-foreground ,macos8 :weight bold))))
   `(helm-moccur-buffer ((,class (:foreground ,red :underline t :weight bold))))
   `(helm-selection ((,class (:background ,grey :extend t :distant-foreground ,blue :weight bold))))
   `(helm-source-header ((,class (:background ,macos2 :foreground ,magenta :weight bold))))
   `(helm-swoop-target-line-block-face ((,class (:foreground ,yellow))))
   `(helm-swoop-target-line-face ((,class (:foreground ,blue :inverse-video t))))
   `(helm-swoop-target-line-face ((,class (:foreground ,blue :inverse-video t))))
   `(helm-swoop-target-number-face ((,class (:foreground ,macos5))))
   `(helm-swoop-target-word-face ((,class (:foreground ,green :weight bold))))
   `(helm-visible-mark ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))

;;;; helpful - light
   `(helpful-heading ((,class (:foreground ,cyan :weight bold :height 1.2))))

;;;; hi-lock - light
   `(hi-blue ((,class (:background ,purple))))
   `(hi-blue-b ((,class (:foreground ,purple :weight bold))))
   `(hi-green ((,class (:background ,green))))
   `(hi-green-b ((,class (:foreground ,green :weight bold))))
   `(hi-magenta ((,class (:background ,teal))))
   `(hi-red-b ((,class (:foreground ,red :weight bold))))
   `(hi-yellow ((,class (:background ,yellow))))

;;;; highlight-indentation-mode - light
   `(highlight-indentation-current-column-face ((,class (:background ,macos1))))
   `(highlight-indentation-face ((,class (:background ,macos2 :extend t))))
   `(highlight-indentation-guides-even-face ((,class (:background ,macos2 :extend t))))
   `(highlight-indentation-guides-odd-face ((,class (:background ,macos2 :extend t))))

;;;; highlight-numbers-mode - light
   `(highlight-numbers-number ((,class (:foreground ,blue :weight bold))))

;;;; highlight-quoted-mode - light
   `(highlight-quoted-quote  ((,class (:foreground ,fg))))
   `(highlight-quoted-symbol ((,class (:foreground ,yellow))))

;;;; highlight-symbol - light
   `(highlight-symbol-face ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; highlight-thing - light
   `(highlight-thing ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; hl-fill-column-face - light
   `(hl-fill-column-face ((,class (:background ,macos2 :extend t))))

;;;; hl-line - light (built-in)
   `(hl-line ((,class (:background ,bg-other :extend t))))

;;;; hl-todo - light
   `(hl-todo ((,class (:foreground ,red :weight bold))))

;;;; hlinum - light
   `(linum-highlight-face ((,class (:foreground ,fg :distant-foreground nil :weight normal))))

;;;; hydra - light
   `(hydra-face-amaranth ((,class (:foreground ,teal :weight bold))))
   `(hydra-face-blue ((,class (:foreground ,purple :weight bold))))
   `(hydra-face-magenta ((,class (:foreground ,magenta :weight bold))))
   `(hydra-face-red ((,class (:foreground ,red :weight bold))))
   `(hydra-face-teal ((,class (:foreground ,orange :weight bold))))

;;;; ido - light
   `(ido-first-match ((,class (:foreground ,blue))))
   `(ido-indicator ((,class (:foreground ,red :background ,bg))))
   `(ido-only-match ((,class (:foreground ,green))))
   `(ido-subdir ((,class (:foreground ,magenta))))
   `(ido-virtual ((,class (:foreground ,macos5))))

;;;; iedit - light
   `(iedit-occurrence ((,class (:foreground ,teal :weight bold :inverse-video t))))
   `(iedit-read-only-occurrence ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))


;;;; imenu-list - light
   `(imenu-list-entry-face-0 ((,class (:foreground ,cyan))))
   `(imenu-list-entry-face-1 ((,class (:foreground ,blue))))
   `(imenu-list-entry-face-2 ((,class (:foreground ,magenta))))
   `(imenu-list-entry-subalist-face-0 ((,class (:foreground ,magenta :weight bold))))
   `(imenu-list-entry-subalist-face-1 ((,class (:foreground ,blue :weight bold))))
   `(imenu-list-entry-subalist-face-2 ((,class (:foreground ,cyan :weight bold))))

;;;; indent-guide - light
   `(indent-guide-face ((,class (:background ,macos2 :extend t))))

;;;; isearch - light
   `(isearch ((,class (:background ,darkblue  :foreground ,macos8 :distant-foreground ,macos0 :weight bold))))
   `(isearch-fail ((,class (:background ,red :foreground ,macos0 :weight bold))))

;;;; ivy - light
   `(ivy-confirm-face ((,class (:foreground ,green))))
   `(ivy-current-match ((,class (:background ,grey :distant-foreground nil :extend t))))
   `(ivy-highlight-face ((,class (:foreground ,magenta))))
   `(ivy-match-required-face ((,class (:foreground ,red))))
   `(ivy-minibuffer-match-face-1 ((,class (:background nil :foreground ,blue :weight bold :underline t))))
   `(ivy-minibuffer-match-face-2 ((,class (:foreground ,teal :background ,macos1 :weight semi-bold))))
   `(ivy-minibuffer-match-face-3 ((,class (:foreground ,green :weight semi-bold))))
   `(ivy-minibuffer-match-face-4 ((,class (:foreground ,yellow :weight semi-bold))))
   `(ivy-minibuffer-match-highlight ((,class (:foreground ,magenta))))
   `(ivy-modified-buffer ((,class (:weight bold :foreground ,darkcyan))))
   `(ivy-virtual ((,class (:slant italic :foreground ,fg))))

;;;; ivy-posframe - light
   `(ivy-posframe ((,class (:background ,bg-other))))
   `(ivy-posframe-border ((,class (:background ,red))))

;;;; jabber - light
   `(jabber-activity-face ((,class (:foreground ,red :weight bold))))
   `(jabber-activity-personal-face ((,class (:foreground ,purple :weight bold))))
   `(jabber-chat-error ((,class (:foreground ,red :weight bold))))
   `(jabber-chat-prompt-foreign ((,class (:foreground ,red :weight bold))))
   `(jabber-chat-prompt-local ((,class (:foreground ,purple :weight bold))))
   `(jabber-chat-prompt-system ((,class (:foreground ,green :weight bold))))
   `(jabber-chat-text-foreign ((,class (:foreground ,fg))))
   `(jabber-chat-text-local ((,class (:foreground ,fg))))
   `(jabber-rare-time-face ((,class (:foreground ,green))))
   `(jabber-roster-user-away ((,class (:foreground ,yellow))))
   `(jabber-roster-user-chatty ((,class (:foreground ,green :weight bold))))
   `(jabber-roster-user-dnd ((,class (:foreground ,red))))
   `(jabber-roster-user-error ((,class (:foreground ,red))))
   `(jabber-roster-user-offline ((,class (:foreground ,fg))))
   `(jabber-roster-user-online ((,class (:foreground ,green :weight bold))))
   `(jabber-roster-user-xa ((,class (:foreground ,darkblue))))

;;;; jdee - light
   `(jdee-font-lock-bold-face ((,class (:weight bold))))
   `(jdee-font-lock-constant-face ((,class (:foreground ,red))))
   `(jdee-font-lock-constructor-face ((,class (:foreground ,purple))))
   `(jdee-font-lock-doc-tag-face ((,class (:foreground ,magenta))))
   `(jdee-font-lock-italic-face ((,class (:slant italic))))
   `(jdee-font-lock-link-face ((,class (:foreground ,purple :underline t))))
   `(jdee-font-lock-modifier-face ((,class (:foreground ,yellow))))
   `(jdee-font-lock-number-face ((,class (:foreground ,blue))))
   `(jdee-font-lock-operator-face ((,class (:foreground ,fg))))
   `(jdee-font-lock-private-face ((,class (:foreground ,cyan))))
   `(jdee-font-lock-protected-face ((,class (:foreground ,cyan))))
   `(jdee-font-lock-public-face ((,class (:foreground ,cyan))))

;;;; js2-mode - light
   `(js2-external-variable ((,class (:foreground ,fg))))
   `(js2-function-call ((,class (:foreground ,purple))))
   `(js2-function-param ((,class (:foreground ,red))))
   `(js2-jsdoc-tag ((,class (:foreground ,macos5))))
   `(js2-object-property ((,class (:foreground ,magenta))))

;;;; keycast - light
   `(keycast-command ((,class (:foreground ,red))))
   `(keycast-key ((,class (:foreground ,red :weight bold))))

;;;; ledger-mode - light
   `(ledger-font-payee-cleared-face ((,class (:foreground ,magenta :weight bold))))
   `(ledger-font-payee-uncleared-face ((,class (:foreground ,macos5  :weight bold))))
   `(ledger-font-posting-account-face ((,class (:foreground ,macos8))))
   `(ledger-font-posting-amount-face ((,class (:foreground ,yellow))))
   `(ledger-font-posting-date-face ((,class (:foreground ,purple))))
   `(ledger-font-xact-highlight-face ((,class (:background ,macos0))))

;;;; line - light numbers
   `(line-number ((,class (:foreground ,macos5))))
   `(line-number-current-line ((,class (:background ,bg-other :foreground ,fg))))

;;;; linum - light
   `(linum ((,class (:foreground ,macos5))))

;;;; linum-relative - light
   `(linum-relative-current-face ((,class (:background ,macos2 :foreground ,fg))))

;;;; lsp-mode - light
   `(lsp-face-highlight-read ((,class (:foreground ,bg :weight bold :background ,cyan))))
   `(lsp-face-highlight-textual ((,class (:foreground ,bg :weight bold :background ,cyan))))
   `(lsp-face-highlight-write ((,class (:foreground ,bg :weight bold :background ,cyan))))
   `(lsp-headerline-breadcrumb-separator-face ((,class (:foreground ,fg-other))))
   `(lsp-ui-doc-background ((,class (:background ,bg-other :foreground ,fg))))
   `(lsp-ui-peek-filename ((,class (:weight bold))))
   `(lsp-ui-peek-header ((,class (:foreground ,fg :background ,bg :weight bold))))
   `(lsp-ui-peek-highlight ((,class (:background ,grey :foreground ,bg :box t))))
   `(lsp-ui-peek-line-number ((,class (:foreground ,green))))
   `(lsp-ui-peek-list ((,class (:background ,bg))))
   `(lsp-ui-peek-peek ((,class (:background ,bg))))
   `(lsp-ui-peek-selection ((,class (:foreground ,bg :background ,purple :bold bold))))
   `(lsp-ui-sideline-code-action ((,class (:foreground ,blue))))
   `(lsp-ui-sideline-current-symbol ((,class (:foreground ,blue))))
   `(lsp-ui-sideline-symbol-info ((,class (:foreground ,macos5 :background ,bg-other :extend t))))

;;;; lui - light
   `(lui-button-face ((,class (:backgroung ,bg-other :foreground ,blue :underline t))))
   `(lui-highlight-face ((,class (:backgroung ,bg-other :foreground ,blue))))
   `(lui-time-stamp-face ((,class (:backgroung ,bg-other :foreground ,magenta))))

;;;; magit - light
   `(magit-bisect-bad ((,class (:foreground ,red))))
   `(magit-bisect-good ((,class (:foreground ,green))))
   `(magit-bisect-skip ((,class (:foreground ,red))))
   `(magit-blame-date ((,class (:foreground ,red))))
   `(magit-blame-heading ((,class (:foreground ,cyan :background ,macos3 :extend t))))
   `(magit-branch-current ((,class (:foreground ,red))))
   `(magit-branch-local ((,class (:foreground ,red))))
   `(magit-branch-remote ((,class (:foreground ,green))))
   `(magit-branch-remote-head ((,class (:foreground ,green))))
   `(magit-cherry-equivalent ((,class (:foreground ,magenta))))
   `(magit-cherry-unmatched ((,class (:foreground ,darkblue))))
   `(magit-diff-added ((,class (:foreground ,bg  :background ,green :extend t))))
   `(magit-diff-added-highlight ((,class (:foreground ,bg :background ,green :weight bold :extend t))))
   `(magit-diff-base ((,class (:foreground ,cyan :background ,blue :extend t))))
   `(magit-diff-base-highlight ((,class (:foreground ,cyan :background ,blue :weight bold :extend t))))
   `(magit-diff-context ((,class (:foreground ,fg :background ,bg :extend t))))
   `(magit-diff-context-highlight ((,class (:foreground ,fg :background ,bg-other :extend t))))
   `(magit-diff-file-heading ((,class (:foreground ,fg :weight bold :extend t))))
   `(magit-diff-file-heading-selection ((,class (:foreground ,teal :background ,darkblue :weight bold :extend t))))
   `(magit-diff-hunk-heading ((,class (:foreground ,bg :background ,blue :extend t :weight bold))))
   `(magit-diff-hunk-heading-highlight ((,class (:foreground ,bg :background ,blue :weight bold :extend t))))
   `(magit-diff-lines-heading ((,class (:foreground ,yellow :background ,red :extend t :extend t))))
   `(magit-diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
   `(magit-diff-removed-highlight ((,class (:foreground ,bg :background ,red :weight bold :extend t))))
   `(magit-diff-revision-summary ((,class (:foreground ,bg  :background ,blue :extend t :weight bold))))
   `(magit-diffstat-added ((,class (:foreground ,green))))
   `(magit-diffstat-removed ((,class (:foreground ,red))))
   `(magit-dimmed ((,class (:foreground ,macos5))))
   `(magit-filename ((,class (:foreground ,magenta))))
   `(magit-hash ((,class (:foreground ,magenta))))
   `(magit-header-line ((,class (:background ,bg-other :foreground ,blue :weight bold :box (:line-width 3 :color ,bg-other)))))
   `(magit-log-author ((,class (:foreground ,cyan))))
   `(magit-log-date ((,class (:foreground ,purple))))
   `(magit-log-graph ((,class (:foreground ,macos5))))
   `(magit-process-ng ((,class (:foreground ,red))))
   `(magit-process-ok ((,class (:foreground ,green))))
   `(magit-reflog-amend ((,class (:foreground ,teal))))
   `(magit-reflog-checkout ((,class (:foreground ,purple))))
   `(magit-reflog-cherry-pick ((,class (:foreground ,green))))
   `(magit-reflog-commit ((,class (:foreground ,green))))
   `(magit-reflog-merge ((,class (:foreground ,green))))
   `(magit-reflog-other ((,class (:foreground ,darkblue))))
   `(magit-reflog-rebase ((,class (:foreground ,teal))))
   `(magit-reflog-remote ((,class (:foreground ,darkblue))))
   `(magit-reflog-reset ((,class (:foreground ,red))))
   `(magit-refname ((,class (:foreground ,macos5))))
   `(magit-section-heading ((,class (:foreground ,blue :weight bold :extend t))))
   `(magit-section-heading-selection ((,class (:foreground ,cyan :weight bold :extend t))))
   `(magit-section-highlight ((,class (:background ,bg-other :extend t))))
   `(magit-section-secondary-heading ((,class (:foreground ,magenta :weight bold :extend t))))
   `(magit-sequence-drop ((,class (:foreground ,red))))
   `(magit-sequence-head ((,class (:foreground ,purple))))
   `(magit-sequence-part ((,class (:foreground ,cyan))))
   `(magit-sequence-stop ((,class (:foreground ,green))))
   `(magit-signature-bad ((,class (:foreground ,red))))
   `(magit-signature-error ((,class (:foreground ,red))))
   `(magit-signature-expired ((,class (:foreground ,cyan))))
   `(magit-signature-good ((,class (:foreground ,green))))
   `(magit-signature-revoked ((,class (:foreground ,teal))))
   `(magit-signature-untrusted ((,class (:foreground ,yellow))))
   `(magit-tag ((,class (:foreground ,yellow))))

;;;; make-mode - light
   `(makefile-targets ((,class (:foreground ,purple))))

;;;; marginalia - light
   `(marginalia-documentation ((,class (:foreground ,blue))))
   `(marginalia-file-name ((,class (:foreground ,blue))))
   `(marginalia-size ((,class (:foreground ,yellow))))
   `(marginalia-mode ((,class (:foreground ,purple))))
   `(marginalia-modified ((,class (:foreground ,red))))
   `(marginalia-file-priv-read ((,class (:foreground ,green))))
   `(marginalia-file-priv-write ((,class (:foreground ,yellow))))
   `(marginalia-file-priv-exec ((,class (:foreground ,red))))

;;;; markdown-mode - light
   `(markdown-blockquote-face ((,class (:foreground ,macos5 :slant italic))))
   `(markdown-bold-face ((,class (:foreground ,blue :weight bold))))
   `(markdown-code-face ((,class (:background ,bg-org :extend t))))
   `(markdown-header-delimiter-face ((,class (:foreground ,blue :weight bold))))
   `(markdown-header-face ((,class (:foreground ,blue :weight bold))))
   `(markdown-html-attr-name-face ((,class (:foreground ,blue))))
   `(markdown-html-attr-value-face ((,class (:foreground ,red))))
   `(markdown-html-entity-face ((,class (:foreground ,blue))))
   `(markdown-html-tag-delimiter-face ((,class (:foreground ,fg))))
   `(markdown-html-tag-name-face ((,class (:foreground ,cyan))))
   `(markdown-inline-code-face ((,class (:background ,bg-org :foreground ,blue))))
   `(markdown-italic-face ((,class (:foreground ,magenta :slant italic))))
   `(markdown-link-face ((,class (:foreground ,purple))))
   `(markdown-list-face ((,class (:foreground ,blue))))
   `(markdown-markup-face ((,class (:foreground ,fg))))
   `(markdown-metadata-key-face ((,class (:foreground ,blue))))
   `(markdown-pre-face ((,class (:background ,bg-org :foreground ,yellow))))
   `(markdown-reference-face ((,class (:foreground ,macos5))))
   `(markdown-url-face ((,class (:foreground ,magenta))))

;;;; message - light
   `(message-cited-text-1 ((,class (:foreground ,teal))))
   `(message-cited-text-2 ((,class (:foreground ,magenta))))
   `(message-cited-text-3 ((,class (:foreground ,darkblue))))
   `(message-cited-text-3 ((,class (:foreground ,darkcyan))))
   `(message-header-cc ((,class (:foreground ,red :weight bold))))
   `(message-header-name ((,class (:foreground ,red))))
   `(message-header-newsgroups ((,class (:foreground ,yellow))))
   `(message-header-other ((,class (:foreground ,purple))))
   `(message-header-subject ((,class (:foreground ,cyan :weight bold))))
   `(message-header-to ((,class (:foreground ,cyan :weight bold))))
   `(message-header-xheader ((,class (:foreground ,macos5))))
   `(message-mml ((,class (:foreground ,macos5 :slant italic))))
   `(message-separator ((,class (:foreground ,macos5))))

;;;; mic-paren - light
   `(paren-face-match ((,class (:foreground ,red :background ,macos0 :weight ultra-bold))))
   `(paren-face-mismatch ((,class (:foreground ,macos0 :background ,red :weight ultra-bold))))
   `(paren-face-no-match ((,class (:foreground ,macos0 :background ,red :weight ultra-bold))))

;;;; minimap - light
   `(minimap-active-region-background ((,class (:background ,bg))))
   `(minimap-current-line-face ((,class (:background ,grey))))

;;;; mmm-mode - light
   `(mmm-cleanup-submode-face ((,class (:background ,yellow))))
   `(mmm-code-submode-face ((,class (:background ,bg-other))))
   `(mmm-comment-submode-face ((,class (:background ,purple))))
   `(mmm-declaration-submode-face ((,class (:background ,darkblue))))
   `(mmm-default-submode-face ((,class (:background nil))))
   `(mmm-init-submode-face ((,class (:background ,red))))
   `(mmm-output-submode-face ((,class (:background ,magenta))))
   `(mmm-special-submode-face ((,class (:background ,green))))

;;;; mode-line - light
   `(mode-line ((,class (,@(timu-macos-set-mode-line-active-border blue) :background ,bg-other :foreground ,fg :distant-foreground ,bg))))
   `(mode-line-buffer-id ((,class (:weight bold))))
   `(mode-line-emphasis ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(mode-line-highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(mode-line-inactive ((,class (,@(timu-macos-set-mode-line-inactive-border macos4) :background ,bg-other :foreground ,macos4 :distant-foreground ,macos4))))

;;;; mu4e - light
   `(mu4e-forwarded-face ((,class (:foreground ,purple))))
   `(mu4e-header-key-face ((,class (:foreground ,magenta :weight bold))))
   `(mu4e-header-title-face ((,class (:foreground ,cyan))))
   `(mu4e-highlight-face ((,class (:foreground ,blue :weight bold))))
   `(mu4e-link-face ((,class (:foreground ,cyan))))
   `(mu4e-replied-face ((,class (:foreground ,green))))
   `(mu4e-title-face ((,class (:foreground ,blue :weight bold))))
   `(mu4e-unread-face ((,class (:foreground ,magenta :weight bold))))

;;;; mu4e-column-faces - light
   `(mu4e-column-faces-date ((,class (:foreground ,purple))))
   `(mu4e-column-faces-flags ((,class (:foreground ,orange))))
   `(mu4e-column-faces-to-from ((,class (:foreground ,blue))))

;;;; mu4e-thread-folding - light
   `(mu4e-thread-folding-child-face ((,class (:extend t :background ,bg-org :underline nil))))
   `(mu4e-thread-folding-root-folded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))
   `(mu4e-thread-folding-root-unfolded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))

;;;; multiple - light cursors
   `(mc/cursor-face ((,class (:background ,cyan))))

;;;; nano-modeline - light
   `(nano-modeline-active-name ((,class (:foreground ,fg :weight bold))))
   `(nano-modeline-inactive-name ((,class (:foreground ,macos1 :weight bold))))
   `(nano-modeline-active-primary ((,class (:foreground ,magenta))))
   `(nano-modeline-inactive-primary ((,class (:foreground ,macos1))))
   `(nano-modeline-active-secondary ((,class (:foreground ,blue :weight bold))))
   `(nano-modeline-inactive-secondary ((,class (:foreground ,macos1 :weight bold))))
   `(nano-modeline-active-status-RO ((,class (:background ,purple :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-RO ((,class (:background ,macos1 :foreground ,bg :weight bold))))
   `(nano-modeline-active-status-RW ((,class (:background ,blue :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-RW ((,class (:background ,macos1 :foreground ,bg :weight bold))))
   `(nano-modeline-active-status-** ((,class (:background ,red :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-** ((,class (:background ,macos1 :foreground ,bg :weight bold))))

;;;; nav-flash - light
   `(nav-flash-face ((,class (:background ,grey :foreground ,macos8 :weight bold))))

;;;; neotree - light
   `(neo-dir-link-face ((,class (:foreground ,blue))))
   `(neo-expand-btn-face ((,class (:foreground ,blue))))
   `(neo-file-link-face ((,class (:foreground ,fg))))
   `(neo-root-dir-face ((,class (:foreground ,green :background ,bg :box (:line-width 4 :color ,bg)))))
   `(neo-vc-added-face ((,class (:foreground ,green))))
   `(neo-vc-conflict-face ((,class (:foreground ,teal :weight bold))))
   `(neo-vc-edited-face ((,class (:foreground ,yellow))))
   `(neo-vc-ignored-face ((,class (:foreground ,macos5))))
   `(neo-vc-removed-face ((,class (:foreground ,red :strike-through t))))

;;;; nlinum - light
   `(nlinum-current-line ((,class (:background ,macos2 :foreground ,fg))))

;;;; nlinum-hl - light
   `(nlinum-hl-face ((,class (:background ,macos2 :foreground ,fg))))

;;;; nlinum-relative - light
   `(nlinum-relative-current-face ((,class (:background ,macos2 :foreground ,fg))))

;;;; notmuch - light
   `(notmuch-message-summary-face ((,class (:foreground ,grey :background nil))))
   `(notmuch-search-count ((,class (:foreground ,macos5))))
   `(notmuch-search-date ((,class (:foreground ,blue))))
   `(notmuch-search-flagged-face ((,class (:foreground ,red))))
   `(notmuch-search-matching-authors ((,class (:foreground ,purple))))
   `(notmuch-search-non-matching-authors ((,class (:foreground ,fg))))
   `(notmuch-search-subject ((,class (:foreground ,fg))))
   `(notmuch-search-unread-face ((,class (:weight bold))))
   `(notmuch-tag-added ((,class (:foreground ,green :weight normal))))
   `(notmuch-tag-deleted ((,class (:foreground ,red :weight normal))))
   `(notmuch-tag-face ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tag-flagged ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tag-unread ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tree-match-author-face ((,class (:foreground ,purple :weight bold))))
   `(notmuch-tree-match-date-face ((,class (:foreground ,blue :weight bold))))
   `(notmuch-tree-match-face ((,class (:foreground ,fg))))
   `(notmuch-tree-match-subject-face ((,class (:foreground ,fg))))
   `(notmuch-tree-match-tag-face ((,class (:foreground ,yellow))))
   `(notmuch-tree-match-tree-face ((,class (:foreground ,macos5))))
   `(notmuch-tree-no-match-author-face ((,class (:foreground ,purple))))
   `(notmuch-tree-no-match-date-face ((,class (:foreground ,blue))))
   `(notmuch-tree-no-match-face ((,class (:foreground ,macos5))))
   `(notmuch-tree-no-match-subject-face ((,class (:foreground ,macos5))))
   `(notmuch-tree-no-match-tag-face ((,class (:foreground ,yellow))))
   `(notmuch-tree-no-match-tree-face ((,class (:foreground ,yellow))))
   `(notmuch-wash-cited-text ((,class (:foreground ,macos4))))
   `(notmuch-wash-toggle-button ((,class (:foreground ,fg))))

;;;; orderless - light
   `(orderless-match-face-0 ((,class (:foreground ,blue :weight bold :underline t))))
   `(orderless-match-face-1 ((,class (:foreground ,cyan :weight bold :underline t))))
   `(orderless-match-face-2 ((,class (:foreground ,purple :weight bold :underline t))))
   `(orderless-match-face-3 ((,class (:foreground ,darkcyan :weight bold :underline t))))

;;;; objed - light
   `(objed-hl ((,class (:background ,grey :distant-foreground ,bg :extend t))))
   `(objed-mode-line ((,class (:foreground ,yellow :weight bold))))

;;;; org-agenda - light
   `(org-agenda-clocking ((,class (:background ,purple))))
   `(org-agenda-date ((,class (:foreground ,blue :weight ultra-bold))))
   `(org-agenda-date-today ((,class (:foreground ,blue :weight ultra-bold))))
   `(org-agenda-date-weekend ((,class (:foreground ,blue :weight ultra-bold))))
   `(org-agenda-dimmed-todo-face ((,class (:foreground ,macos5))))
   `(org-agenda-done ((,class (:foreground ,macos5))))
   `(org-agenda-structure ((,class (:foreground ,fg :weight ultra-bold))))
   `(org-scheduled ((,class (:foreground ,fg))))
   `(org-scheduled-previously ((,class (:foreground ,macos8))))
   `(org-scheduled-today ((,class (:foreground ,macos7))))
   `(org-sexp-date ((,class (:foreground ,fg))))
   `(org-time-grid ((,class (:foreground ,macos5))))
   `(org-upcoming-deadline ((,class (:foreground ,fg))))
   `(org-upcoming-distant-deadline ((,class (:foreground ,fg))))
   `(org-agenda-structure-filter ((,class (:foreground ,magenta :weight bold))))

;;;; org-habit - light
   `(org-habit-alert-face ((,class (:weight bold :background ,yellow))))
   `(org-habit-alert-future-face ((,class (:weight bold :background ,yellow))))
   `(org-habit-clear-face ((,class (:weight bold :background ,macos4))))
   `(org-habit-clear-future-face ((,class (:weight bold :background ,macos3))))
   `(org-habit-overdue-face ((,class (:weight bold :background ,red))))
   `(org-habit-overdue-future-face ((,class (:weight bold :background ,red))))
   `(org-habit-ready-face ((,class (:weight bold :background ,purple))))
   `(org-habit-ready-future-face ((,class (:weight bold :background ,purple))))

;;;; org-journal - light
   `(org-journal-calendar-entry-face ((,class (:foreground ,teal :slant italic))))
   `(org-journal-calendar-scheduled-face ((,class (:foreground ,red :slant italic))))
   `(org-journal-highlight ((,class (:foreground ,cyan))))

;;;; org-mode - light
   `(org-archived ((,class (:foreground ,macos5))))
   `(org-block ((,class (:foreground ,macos8 :background ,bg-org :extend t))))
   `(org-block-background ((,class (:background ,bg-org :extend t))))
   `(org-block-begin-line ((,class (:foreground ,macos5 :slant italic :background ,bg-org :extend t ,@(timu-macos-set-intense-org-colors bg bg-other)))))
   `(org-block-end-line ((,class (:foreground ,macos5 :slant italic :background ,bg-org :extend t ,@(timu-macos-set-intense-org-colors bg-other bg-other)))))
   `(org-checkbox ((,class (:foreground ,green :weight bold))))
   `(org-checkbox-statistics-done ((,class (:foreground ,macos5 :weight bold))))
   `(org-checkbox-statistics-todo ((,class (:foreground ,green :weight bold))))
   `(org-code ((,class (:foreground ,blue ,@(timu-macos-set-intense-org-colors bg bg-other)))))
   `(org-date ((,class (:foreground ,yellow))))
   `(org-default ((,class (:background ,bg :foreground ,fg))))
   `(org-document-info ((,class (:foreground ,purple ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.2) ,@(timu-macos-set-intense-org-colors bg bg-other)))))
   `(org-document-info-keyword ((,class (:foreground ,macos5))))
   `(org-document-title ((,class (:foreground ,purple :weight bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.3) ,@(timu-macos-set-intense-org-colors purple bg-other)))))
   `(org-done ((,class (:foreground ,macos5 :weight bold))))
   `(org-ellipsis ((,class (:foreground ,grey))))
   `(org-footnote ((,class (:foreground ,cyan))))
   `(org-formula ((,class (:foreground ,darkblue))))
   `(org-headline-done ((,class (:foreground ,macos5))))
   `(org-hide ((,class (:foreground ,bg))))
   `(org-latex-and-related ((,class (:foreground ,macos8 :weight bold))))
   `(org-level-1 ((,class (:foreground ,darkblue :weight ultra-bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.3) ,@(timu-macos-set-intense-org-colors darkblue bg-other)))))
   `(org-level-2 ((,class (:foreground ,magenta :weight bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.2) ,@(timu-macos-set-intense-org-colors magenta bg-other)))))
   `(org-level-3 ((,class (:foreground ,blue :weight bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.1) ,@(timu-macos-set-intense-org-colors blue bg-other)))))
   `(org-level-4 ((,class (:foreground ,red ,@(timu-macos-set-intense-org-colors red bg-org)))))
   `(org-level-5 ((,class (:foreground ,green ,@(timu-macos-set-intense-org-colors green bg-org)))))
   `(org-level-6 ((,class (:foreground ,orange ,@(timu-macos-set-intense-org-colors orange bg-org)))))
   `(org-level-7 ((,class (:foreground ,purple ,@(timu-macos-set-intense-org-colors purple bg-org)))))
   `(org-level-8 ((,class (:foreground ,fg ,@(timu-macos-set-intense-org-colors fg bg-org)))))
   `(org-link ((,class (:foreground ,blue :underline t))))
   `(org-list-dt ((,class (:foreground ,purple :weight bold))))
   `(org-meta-line ((,class (:foreground ,macos5))))
   `(org-priority ((,class (:foreground ,red))))
   `(org-property-value ((,class (:foreground ,macos5))))
   `(org-quote ((,class (:background ,macos3 :slant italic :extend t))))
   `(org-special-keyword ((,class (:foreground ,macos5))))
   `(org-table ((,class (:foreground ,purple))))
   `(org-tag ((,class (:foreground ,macos5 :weight normal))))
   `(org-todo ((,class (:foreground ,green :weight bold))))
   `(org-verbatim ((,class (:foreground ,green ,@(timu-macos-set-intense-org-colors bg bg-other)))))
   `(org-warning ((,class (:foreground ,yellow))))

;;;; org-pomodoro - light
   `(org-pomodoro-mode-line ((,class (:foreground ,red))))
   `(org-pomodoro-mode-line-overtime ((,class (:foreground ,yellow :weight bold))))

;;;; org-ref - light
   `(org-ref-acronym-face ((,class (:foreground ,magenta))))
   `(org-ref-cite-face ((,class (:foreground ,yellow :weight light :underline t))))
   `(org-ref-glossary-face ((,class (:foreground ,teal))))
   `(org-ref-label-face ((,class (:foreground ,purple))))
   `(org-ref-ref-face ((,class (:foreground ,red :underline t :weight bold))))

;;;; outline - light
   `(outline-1 ((,class (:foreground ,purple :weight ultra-bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.2)))))
   `(outline-2 ((,class (:foreground ,red :weight bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.2)))))
   `(outline-3 ((,class (:foreground ,blue :weight bold ,@(timu-macos-do-scale timu-macos-scale-org-document-info 1.1)))))
   `(outline-4 ((,class (:foreground ,cyan))))
   `(outline-5 ((,class (:foreground ,green))))
   `(outline-6 ((,class (:foreground ,orange))))
   `(outline-7 ((,class (:foreground ,teal))))
   `(outline-8 ((,class (:foreground ,fg))))

;;;; parenface - light
   `(paren-face ((,class (:foreground ,macos5))))

;;;; parinfer - light
   `(parinfer-pretty-parens:dim-paren-face ((,class (:foreground ,macos5))))
   `(parinfer-smart-tab:indicator-face ((,class (:foreground ,macos5))))

;;;; persp-mode - light
   `(persp-face-lighter-buffer-not-in-persp ((,class (:foreground ,macos5))))
   `(persp-face-lighter-default ((,class (:foreground ,red :weight bold))))
   `(persp-face-lighter-nil-persp ((,class (:foreground ,macos5))))

;;;; perspective - light
   `(persp-selected-face ((,class (:foreground ,purple :weight bold))))

;;;; pkgbuild-mode - light
   `(pkgbuild-error-face ((,class (:underline (:style wave :color ,red)))))

;;;; popup - light
   `(popup-face ((,class (:background ,bg-other :foreground ,fg))))
   `(popup-selection-face ((,class (:background ,grey))))
   `(popup-tip-face ((,class (:foreground ,magenta :background ,macos0))))

;;;; powerline - light
   `(powerline-active0 ((,class (:background ,macos1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-active1 ((,class (:background ,macos1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-active2 ((,class (:background ,macos1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-inactive0 ((,class (:background ,macos2 :foreground ,macos5 :distant-foreground ,bg-other))))
   `(powerline-inactive1 ((,class (:background ,macos2 :foreground ,macos5 :distant-foreground ,bg-other))))
   `(powerline-inactive2 ((,class (:background ,macos2 :foreground ,macos5 :distant-foreground ,bg-other))))

;;;; rainbow-delimiters - light
   `(rainbow-delimiters-depth-1-face ((,class (:foreground ,magenta))))
   `(rainbow-delimiters-depth-2-face ((,class (:foreground ,darkblue))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground ,red))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground ,green))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground ,purple))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground ,yellow))))
   `(rainbow-delimiters-depth-7-face ((,class (:foreground ,orange))))
   `(rainbow-delimiters-mismatched-face ((,class (:foreground ,magenta :weight bold :inverse-video t))))
   `(rainbow-delimiters-unmatched-face ((,class (:foreground ,magenta :weight bold :inverse-video t))))

;;;; re-builder - light
   `(reb-match-0 ((,class (:foreground ,red :inverse-video t))))
   `(reb-match-1 ((,class (:foreground ,teal :inverse-video t))))
   `(reb-match-2 ((,class (:foreground ,green :inverse-video t))))
   `(reb-match-3 ((,class (:foreground ,yellow :inverse-video t))))

;;;; rjsx-mode - light
   `(rjsx-attr ((,class (:foreground ,purple))))
   `(rjsx-tag ((,class (:foreground ,yellow))))

;;;; rpm-spec-mode - light
   `(rpm-spec-dir-face ((,class (:foreground ,green))))
   `(rpm-spec-doc-face ((,class (:foreground ,blue))))
   `(rpm-spec-ghost-face ((,class (:foreground ,macos5))))
   `(rpm-spec-macro-face ((,class (:foreground ,yellow))))
   `(rpm-spec-obsolete-tag-face ((,class (:foreground ,red))))
   `(rpm-spec-package-face ((,class (:foreground ,blue))))
   `(rpm-spec-section-face ((,class (:foreground ,teal))))
   `(rpm-spec-tag-face ((,class (:foreground ,purple))))
   `(rpm-spec-var-face ((,class (:foreground ,magenta))))

;;;; rst - light
   `(rst-block ((,class (:foreground ,red))))
   `(rst-level-1 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-2 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-3 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-4 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-5 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-6 ((,class (:foreground ,magenta :weight bold))))

;;;; selectrum - light
   `(selectrum-current-candidate ((,class (:background ,grey :distant-foreground nil :extend t))))

;;;; sh-script - light
   `(sh-heredoc ((,class (:foreground ,blue))))
   `(sh-quoted-exec ((,class (:foreground ,fg :weight bold))))

;;;; show-paren - light
   `(show-paren-match ((,class (:foreground ,magenta :weight ultra-bold :underline ,magenta))))
   `(show-paren-mismatch ((,class (:foreground ,bg :background ,magenta :weight ultra-bold))))

;;;; smart-mode-line - light
   `(sml/charging ((,class (:foreground ,green))))
   `(sml/discharging ((,class (:foreground ,yellow :weight bold))))
   `(sml/filename ((,class (:foreground ,magenta :weight bold))))
   `(sml/git ((,class (:foreground ,purple))))
   `(sml/modified ((,class (:foreground ,darkblue))))
   `(sml/outside-modified ((,class (:foreground ,darkblue))))
   `(sml/process ((,class (:weight bold))))
   `(sml/read-only ((,class (:foreground ,darkblue))))
   `(sml/sudo ((,class (:foreground ,red :weight bold))))
   `(sml/vc-edited ((,class (:foreground ,green))))

;;;; smartparens - light
   `(sp-pair-overlay-face ((,class (:background ,grey))))
   `(sp-show-pair-match-face ((,class (:foreground ,red :background ,macos0 :weight ultra-bold))))
   `(sp-show-pair-mismatch-face ((,class (:foreground ,macos0 :background ,red :weight ultra-bold))))

;;;; smerge-tool - light
   `(smerge-base ((,class (:background ,purple :foreground ,bg))))
   `(smerge-lower ((,class (:background ,green))))
   `(smerge-markers ((,class (:background ,macos5 :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(smerge-mine ((,class (:background ,red :foreground ,bg))))
   `(smerge-other ((,class (:background ,green :foreground ,bg))))
   `(smerge-refined-added ((,class (:background ,green :foreground ,bg))))
   `(smerge-refined-removed ((,class (:background ,red :foreground ,bg))))
   `(smerge-upper ((,class (:background ,red))))

;;;; solaire-mode - light
   `(solaire-default-face ((,class (:background ,bg-other))))
   `(solaire-hl-line-face ((,class (:background ,bg-other :extend t))))
   `(solaire-mode-line-face ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))
   `(solaire-mode-line-inactive-face ((,class (:background ,bg-other :foreground ,fg-other :distant-foreground ,bg-other))))
   `(solaire-org-hide-face ((,class (:foreground ,bg))))

;;;; spaceline - light
   `(spaceline-evil-emacs ((,class (:background ,darkblue))))
   `(spaceline-evil-insert ((,class (:background ,green))))
   `(spaceline-evil-motion ((,class (:background ,teal))))
   `(spaceline-evil-normal ((,class (:background ,purple))))
   `(spaceline-evil-replace ((,class (:background ,red))))
   `(spaceline-evil-visual ((,class (:background ,grey))))
   `(spaceline-flycheck-error ((,class (:foreground ,red :distant-background ,macos0))))
   `(spaceline-flycheck-info ((,class (:foreground ,green :distant-background ,macos0))))
   `(spaceline-flycheck-warning ((,class (:foreground ,yellow :distant-background ,macos0))))
   `(spaceline-highlight-face ((,class (:background ,red))))
   `(spaceline-modified ((,class (:background ,red))))
   `(spaceline-python-venv ((,class (:foreground ,teal :distant-foreground ,magenta))))
   `(spaceline-unmodified ((,class (:background ,red))))

;;;; stripe-buffer - light
   `(stripe-highlight ((,class (:background ,macos3))))

;;;; swiper - light
   `(swiper-line-face ((,class (:background ,purple :foreground ,macos0))))
   `(swiper-match-face-1 ((,class (:background ,macos0 :foreground ,macos5))))
   `(swiper-match-face-2 ((,class (:background ,blue :foreground ,macos0 :weight bold))))
   `(swiper-match-face-3 ((,class (:background ,teal :foreground ,macos0 :weight bold))))
   `(swiper-match-face-4 ((,class (:background ,green :foreground ,macos0 :weight bold))))

;;;; tabbar - light
   `(tabbar-button ((,class (:foreground ,fg :background ,bg))))
   `(tabbar-button-highlight ((,class (:foreground ,fg :background ,bg :inverse-video t))))
   `(tabbar-default ((,class (:foreground ,bg :background ,bg :height 1.0))))
   `(tabbar-highlight ((,class (:foreground ,fg :background ,grey :distant-foreground ,bg))))
   `(tabbar-modified ((,class (:foreground ,red :weight bold))))
   `(tabbar-selected ((,class (:foreground ,fg :background ,bg-other :weight bold))))
   `(tabbar-selected-modified ((,class (:foreground ,green :background ,bg-other :weight bold))))
   `(tabbar-unselected ((,class (:foreground ,macos5))))
   `(tabbar-unselected-modified ((,class (:foreground ,red :weight bold))))

;;;; tab-bar - light
   `(tab-bar ((,class (:background ,bg-other :foreground ,bg-other))))
   `(tab-bar-tab ((,class (:background ,bg :foreground ,fg))))
   `(tab-bar-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; tab-line - light
   `(tab-line ((,class (:background ,bg-other :foreground ,bg-other))))
   `(tab-line-close-highlight ((,class (:foreground ,red))))
   `(tab-line-highlight ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab-current ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; telephone-line - light
   `(telephone-line-accent-active ((,class (:foreground ,fg :background ,macos4))))
   `(telephone-line-accent-inactive ((,class (:foreground ,fg :background ,macos2))))
   `(telephone-line-evil ((,class (:foreground ,fg :weight bold))))
   `(telephone-line-evil-emacs ((,class (:background ,teal :weight bold))))
   `(telephone-line-evil-insert ((,class (:background ,green :weight bold))))
   `(telephone-line-evil-motion ((,class (:background ,purple :weight bold))))
   `(telephone-line-evil-normal ((,class (:background ,red :weight bold))))
   `(telephone-line-evil-operator ((,class (:background ,magenta :weight bold))))
   `(telephone-line-evil-replace ((,class (:background ,bg-other :weight bold))))
   `(telephone-line-evil-visual ((,class (:background ,red :weight bold))))
   `(telephone-line-projectile ((,class (:foreground ,green))))

;;;; term - light
   `(term ((,class (:foreground ,fg))))
   `(term-bold ((,class (:weight bold))))
   `(term-color-black ((,class (:background ,macos0 :foreground ,macos0))))
   `(term-color-blue ((,class (:background ,purple :foreground ,purple))))
   `(term-color-cyan ((,class (:background ,darkblue :foreground ,darkblue))))
   `(term-color-green ((,class (:background ,green :foreground ,green))))
   `(term-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
   `(term-color-purple ((,class (:background ,teal :foreground ,teal))))
   `(term-color-red ((,class (:background ,red :foreground ,red))))
   `(term-color-white ((,class (:background ,macos8 :foreground ,macos8))))
   `(term-color-yellow ((,class (:background ,yellow :foreground ,yellow))))
   `(term-color-bright-black ((,class (:foreground ,macos0))))
   `(term-color-bright-blue ((,class (:foreground ,purple))))
   `(term-color-bright-cyan ((,class (:foreground ,darkblue))))
   `(term-color-bright-green ((,class (:foreground ,green))))
   `(term-color-bright-magenta ((,class (:foreground ,magenta))))
   `(term-color-bright-purple ((,class (:foreground ,teal))))
   `(term-color-bright-red ((,class (:foreground ,red))))
   `(term-color-bright-white ((,class (:foreground ,macos8))))
   `(term-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; tldr - light
   `(tldr-code-block ((,class (:foreground ,green :weight bold))))
   `(tldr-command-argument ((,class (:foreground ,fg))))
   `(tldr-command-itself ((,class (:foreground ,green :weight bold))))
   `(tldr-description ((,class (:foreground ,macos4))))
   `(tldr-introduction ((,class (:foreground ,blue))))
   `(tldr-title ((,class (:foreground ,darkred :weight bold :height 1.4))))

;;;; transient - light
   `(transient-key ((,class (:foreground ,blue :height 1.1))))
   `(transient-blue ((,class (:foreground ,purple))))
   `(transient-pink ((,class (:foreground ,magenta))))
   `(transient-purple ((,class (:foreground ,teal))))
   `(transient-red ((,class (:foreground ,red))))
   `(transient-teal ((,class (:foreground ,blue))))

;;;; treemacs - light
   `(treemacs-directory-face ((,class (:foreground ,fg))))
   `(treemacs-file-face ((,class (:foreground ,fg))))
   `(treemacs-git-added-face ((,class (:foreground ,green))))
   `(treemacs-git-conflict-face ((,class (:foreground ,red))))
   `(treemacs-git-modified-face ((,class (:foreground ,magenta))))
   `(treemacs-git-untracked-face ((,class (:foreground ,macos5))))
   `(treemacs-root-face ((,class (:foreground ,blue :weight bold :height 1.2))))
   `(treemacs-tags-face ((,class (:foreground ,red))))

;;;; treemacs-all-the-icons - light
     `(treemacs-all-the-icons-file-face ((,class (:foreground ,blue))))
     `(treemacs-all-the-icons-root-face ((,class (:foreground ,fg))))

;;;; tree-sitter-hl - light
   `(tree-sitter-hl-face:function ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:function.call ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:function.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:function.special ((,class (:foreground ,fg :weight bold))))
   `(tree-sitter-hl-face:function.macro ((,class (:foreground ,fg :weight bold))))
   `(tree-sitter-hl-face:method ((,class (:foreground ,orange))))
   `(tree-sitter-hl-face:method.call ((,class (:foreground ,orange))))
   `(tree-sitter-hl-face:type ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:type.parameter ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:type.argument ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:type.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:type.super ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:constructor ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:variable ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:variable.parameter ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:variable.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:variable.special ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:property ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:property.definition ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:comment ((,class (:foreground ,macos4 :slant italic))))
   `(tree-sitter-hl-face:doc ((,class (:foreground ,grey :slant italic))))
   `(tree-sitter-hl-face:string ((,class (:foreground ,green))))
   `(tree-sitter-hl-face:string.special ((,class (:foreground ,green :weight bold))))
   `(tree-sitter-hl-face:escape ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:embedded ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:keyword ((,class (:foreground ,darkblue))))
   `(tree-sitter-hl-face:operator ((,class (:foreground ,green))))
   `(tree-sitter-hl-face:label ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:constant ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:constant.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:number ((,class (:foreground ,green))))
   `(tree-sitter-hl-face:punctuation ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.bracket ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.delimiter ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.special ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:tag ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:attribute ((,class (:foreground ,fg))))

;;;; typescript-mode - light
   `(typescript-jsdoc-tag ((,class (:foreground ,macos5))))
   `(typescript-jsdoc-type ((,class (:foreground ,macos5))))
   `(typescript-jsdoc-value ((,class (:foreground ,macos5))))

;;;; undo-tree - light
   `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,purple))))
   `(undo-tree-visualizer-current-face ((,class (:foreground ,green :weight bold))))
   `(undo-tree-visualizer-default-face ((,class (:foreground ,macos5))))
   `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow))))
   `(undo-tree-visualizer-unmodified-face ((,class (:foreground ,macos5))))

;;;; vimish-fold - light
   `(vimish-fold-fringe ((,class (:foreground ,teal))))
   `(vimish-fold-overlay ((,class (:foreground ,macos5 :background ,macos0 :weight light))))

;;;; volatile-highlights - light
   `(vhl/default-face ((,class (:background ,grey))))

;;;; vterm - light
   `(vterm ((,class (:foreground ,fg))))
   `(vterm-color-black ((,class (:background ,macos0 :foreground ,macos0))))
   `(vterm-color-blue ((,class (:background ,purple :foreground ,purple))))
   `(vterm-color-cyan ((,class (:background ,darkblue :foreground ,darkblue))))
   `(vterm-color-default ((,class (:foreground ,fg))))
   `(vterm-color-green ((,class (:background ,green :foreground ,green))))
   `(vterm-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
   `(vterm-color-purple ((,class (:background ,teal :foreground ,teal))))
   `(vterm-color-red ((,class (:background ,red :foreground ,red))))
   `(vterm-color-white ((,class (:background ,macos8 :foreground ,macos8))))
   `(vterm-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

;;;; web-mode - light
   `(web-mode-block-control-face ((,class (:foreground ,red))))
   `(web-mode-block-control-face ((,class (:foreground ,red))))
   `(web-mode-block-delimiter-face ((,class (:foreground ,red))))
   `(web-mode-css-property-name-face ((,class (:foreground ,yellow))))
   `(web-mode-doctype-face ((,class (:foreground ,macos5))))
   `(web-mode-html-attr-name-face ((,class (:foreground ,purple))))
   `(web-mode-html-attr-value-face ((,class (:foreground ,yellow))))
   `(web-mode-html-entity-face ((,class (:foreground ,darkblue :slant italic))))
   `(web-mode-html-tag-bracket-face ((,class (:foreground ,purple))))
   `(web-mode-html-tag-bracket-face ((,class (:foreground ,fg))))
   `(web-mode-html-tag-face ((,class (:foreground ,blue))))
   `(web-mode-json-context-face ((,class (:foreground ,green))))
   `(web-mode-json-key-face ((,class (:foreground ,green))))
   `(web-mode-keyword-face ((,class (:foreground ,magenta))))
   `(web-mode-string-face ((,class (:foreground ,green))))
   `(web-mode-type-face ((,class (:foreground ,yellow))))

;;;; wgrep - light
   `(wgrep-delete-face ((,class (:foreground ,macos3 :background ,red))))
   `(wgrep-done-face ((,class (:foreground ,purple))))
   `(wgrep-face ((,class (:weight bold :foreground ,green :background ,macos5))))
   `(wgrep-file-face ((,class (:foreground ,macos5))))
   `(wgrep-reject-face ((,class (:foreground ,red :weight bold))))

;;;; which-func - light
   `(which-func ((,class (:foreground ,purple))))

;;;; which-key - light
   `(which-key-command-description-face ((,class (:foreground ,purple))))
   `(which-key-group-description-face ((,class (:foreground ,darkblue))))
   `(which-key-key-face ((,class (:foreground ,magenta :weight bold :height 1.1))))
   `(which-key-local-map-description-face ((,class (:foreground ,blue))))

;;;; whitespace - light
   `(whitespace-empty ((,class (:background ,macos3))))
   `(whitespace-indentation ((,class (:foreground ,macos4 :background ,macos3))))
   `(whitespace-line ((,class (:background ,macos0 :foreground ,red :weight bold))))
   `(whitespace-newline ((,class (:foreground ,macos4))))
   `(whitespace-space ((,class (:foreground ,macos4))))
   `(whitespace-tab ((,class (:foreground ,macos4 :background ,macos3))))
   `(whitespace-trailing ((,class (:background ,red))))

;;;; widget - light
   `(widget-button ((,class (:foreground ,fg :weight bold))))
   `(widget-button-pressed ((,class (:foreground ,red))))
   `(widget-documentation ((,class (:foreground ,green))))
   `(widget-field ((,class (:foreground ,fg :background ,macos0 :extend nil))))
   `(widget-inactive ((,class (:foreground ,grey :background ,bg-other))))
   `(widget-single-line-field ((,class (:foreground ,fg :background ,macos0))))

;;;; window-divider - light
   `(window-divider ((,class (:background ,red :foreground ,red))))
   `(window-divider-first-pixel ((,class (:background ,red :foreground ,red))))
   `(window-divider-last-pixel ((,class (:background ,red :foreground ,red))))

;;;; woman - light
   `(woman-bold ((,class (:foreground ,fg :weight bold))))
   `(woman-italic ((,class (:foreground ,magenta :underline ,magenta))))

;;;; workgroups2 - light
   `(wg-brace-face ((,class (:foreground ,red))))
   `(wg-current-workgroup-face ((,class (:foreground ,macos0 :background ,red))))
   `(wg-divider-face ((,class (:foreground ,grey))))
   `(wg-other-workgroup-face ((,class (:foreground ,macos5))))

;;;; yasnippet - light
   `(yas-field-highlight-face ((,class (:foreground ,green :background ,macos0 :weight bold))))

;;;; ytel - light
   `(ytel-video-published-face ((,class (:foreground ,purple))))
   `(ytel-channel-name-face ((,class (:foreground ,red))))
   `(ytel-video-length-face ((,class (:foreground ,cyan))))
   `(ytel-video-view-face ((,class (:foreground ,darkblue))))

   (custom-theme-set-variables
    'timu-macos
    `(ansi-color-names-vector [bg, red, green, teal, cyan, blue, yellow, fg])))))


;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory
                (file-name-directory load-file-name))))

(provide-theme 'timu-macos)

;;; timu-macos-theme.el ends here
