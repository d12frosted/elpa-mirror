;;; timu-caribbean-theme.el --- Color theme with cyan as a dominant color -*- lexical-binding:t -*-

;; Copyright (C) 2022 Aimé Bertrand

;; Author: Aimé Bertrand <aime.bertrand@macowners.club>
;; Maintainer: Aimé Bertrand <aime.bertrand@macowners.club>
;; Created: 2022-11-13
;; Keywords: faces themes
;; Package-Version: 20221226.1556
;; Package-Commit: af60151fe35bd1c780b7c4a37032699989ee6162
;; Version: 1.5
;; Package-Requires: ((emacs "27.1"))
;; Homepage: https://gitlab.com/aimebertrand/timu-caribbean-theme

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
;;     1. Download the `timu-caribbean-theme.el' file and add it to your `custom-load-path'.
;;     2. In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (load-theme 'timu-caribbean t)
;;
;;   B. From Melpa
;;     1. M-x package-instal <RET> timu-caribbean-theme.el <RET>.
;;     2. In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (load-theme 'timu-caribbean t)
;;
;;   C. With use-package
;;     In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (use-package timu-caribbean-theme
;;         :ensure t
;;         :config
;;         (load-theme 'timu-caribbean t))
;;
;; II. Configuration
;;   A. Scaling
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
;;         (customize-set-variable 'timu-caribbean-scale-org-document-title t)
;;         (customize-set-variable 'timu-caribbean-scale-org-document-info t)
;;         (customize-set-variable 'timu-caribbean-scale-org-level-1 t)
;;         (customize-set-variable 'timu-caribbean-scale-org-level-2 t)
;;         (customize-set-variable 'timu-caribbean-scale-org-level-3 t)
;;
;;     2. Custom scaling
;;       You can choose your own scaling values as well.
;;       The following is a somewhat exaggerated example.
;;
;;         (customize-set-variable 'timu-caribbean-scale-org-document-title 1.8)
;;         (customize-set-variable 'timu-caribbean-scale-org-document-info 1.4)
;;         (customize-set-variable 'timu-caribbean-scale-org-level-1 1.8)
;;         (customize-set-variable 'timu-caribbean-scale-org-level-2 1.4)
;;         (customize-set-variable 'timu-caribbean-scale-org-level-3 1.2)
;;
;;   B. "Intense" colors for `org-mode'
;;     To emphasize some elements in `org-mode'.
;;     You can set a variable to make some faces more "intense".
;;
;;     By default the intense colors are turned off.
;;     To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
;;       (customize-set-variable 'timu-caribbean-org-intense-colors t)
;;
;;   C. Border for the `mode-line'
;;     You can set a variable to add a border to the `mode-line'.
;;
;;     By default the border is turned off.
;;     To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
;;       (customize-set-variable 'timu-caribbean-mode-line-border t)
;;
;; III. Utility functions
;;   A. Toggle between intense and non intense colors for `org-mode'
;;       M-x timu-caribbean-toggle-org-colors-intensity RET.
;;
;;   B. Toggle between borders and no borders for the `mode-line'
;;       M-x timu-caribbean-toggle-mode-line-border RET.


;;; Code:

(defgroup timu-caribbean-theme ()
  "Customise group for the \"Timu Caribbean\" theme."
  :group 'faces
  :prefix "timu-caribbean-")

(defface timu-caribbean-grey-face
  '((t nil))
  "Custom basic grey `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-red-face
  '((t nil))
  "Custom basic red `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-darkred-face
  '((t nil))
  "Custom basic darkred `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-orange-face
  '((t nil))
  "Custom basic orange `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-green-face
  '((t nil))
  "Custom basic green `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-blue-face
  '((t nil))
  "Custom basic blue `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-magenta-face
  '((t nil))
  "Custom basic magenta `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-teal-face
  '((t nil))
  "Custom basic teal `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-yellow-face
  '((t nil))
  "Custom basic yellow `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-darkblue-face
  '((t nil))
  "Custom basic darkblue `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-purple-face
  '((t nil))
  "Custom basic purple `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-cyan-face
  '((t nil))
  "Custom basic cyan `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-darkcyan-face
  '((t nil))
  "Custom basic darkcyan `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-black-face
  '((t nil))
  "Custom basic black `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-white-face
  '((t nil))
  "Custom basic white `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-default-face
  '((t nil))
  "Custom basic default `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-bold-face
  '((t :weight bold))
  "Custom basic bold `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-bold-face-italic
  '((t :weight bold :slant italic))
  "Custom basic bold-italic `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-italic-face
  '((((supports :slant italic)) :slant italic)
    (t :slant italic))
  "Custom basic italic `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-underline-face
  '((((supports :underline t)) :underline t)
    (t :underline t))
  "Custom basic underlined `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defface timu-caribbean-strike-through-face
  '((((supports :strike-through t)) :strike-through t)
    (t :strike-through t))
  "Custom basic strike-through `timu-caribbean-theme' face."
  :group 'timu-caribbean-theme)

(defcustom timu-caribbean-scale-org-document-info nil
  "Variable to control the scale of the `org-document-info' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-caribbean-theme)

(defcustom timu-caribbean-scale-org-document-title nil
  "Variable to control the scale of the `org-document-title' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-caribbean-theme)

(defcustom timu-caribbean-scale-org-level-1 nil
  "Variable to control the scale of the `org-level-1' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-caribbean-theme)

(defcustom timu-caribbean-scale-org-level-2 nil
  "Variable to control the scale of the `org-level-2' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-caribbean-theme)

(defcustom timu-caribbean-scale-org-level-3 nil
  "Variable to control the scale of the `org-level-3' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-caribbean-theme)

(defun timu-caribbean-do-scale (custom-height default-height)
  "Function for scaling the face to the DEFAULT-HEIGHT or CUSTOM-HEIGHT.
Uses `timu-caribbean-scale-faces' for the value of CUSTOM-HEIGHT."
  (cond
   ((numberp custom-height) (list :height custom-height))
   ((eq t custom-height) (list :height default-height))
   ((eq nil custom-height) (list :height 1.0))
   (t nil)))

(defcustom timu-caribbean-org-intense-colors nil
  "Variable to control \"intensity\" of `org-mode' header colors."
  :type 'boolean
  :group 'timu-caribbean-theme)

(defun timu-caribbean-set-intense-org-colors (overline-color background-color)
  "Function Adding intense colors to `org-mode'.
OVERLINE-COLOR changes the `overline' color.
BACKGROUND-COLOR changes the `background' color."
  (if (eq t timu-caribbean-org-intense-colors)
      (list :overline overline-color :background background-color)))

(defcustom timu-caribbean-mode-line-border nil
  "Variable to control the border of `mode-line'.
With a value of t the mode-line has a border."
  :type 'boolean
  :group 'timu-caribbean-theme)

(defun timu-caribbean-set-mode-line-active-border (boxcolor)
  "Function adding a border to the `mode-line' of the active window.
BOXCOLOR supplies the border color."
  (if (eq t timu-caribbean-mode-line-border)
        (list :box boxcolor)))

(defun timu-caribbean-set-mode-line-inactive-border (boxcolor)
  "Function adding a border to the `mode-line' of the inactive window.
BOXCOLOR supplies the border color."
  (if (eq t timu-caribbean-mode-line-border)
        (list :box boxcolor)))

;;;###autoload
(defun timu-caribbean-toggle-org-colors-intensity ()
  "Toggle between intense and non intense colors for `org-mode'.
Customize `timu-caribbean-org-intense-colors' the to achieve this."
  (interactive)
  (if (eq t timu-caribbean-org-intense-colors)
      (customize-set-variable 'timu-caribbean-org-intense-colors nil)
    (customize-set-variable 'timu-caribbean-org-intense-colors t))
  (load-theme (car custom-enabled-themes) t))

;;;###autoload
(defun timu-caribbean-toggle-mode-line-border ()
  "Toggle between borders and no borders for the `mode-line'.
Customize `timu-caribbean-mode-line-border' the to achieve this."
  (interactive)
  (if (eq t timu-caribbean-mode-line-border)
      (customize-set-variable 'timu-caribbean-mode-line-border nil)
    (customize-set-variable 'timu-caribbean-mode-line-border t))
  (load-theme (car custom-enabled-themes) t))

(deftheme timu-caribbean
  "Color theme with cyan as a dominant color.
Sourced other themes to get information about font faces for packages.")

(let ((class '((class color) (min-colors 89)))
      (bg         "#151515")
      (bg-org     "#161a1f")
      (bg-other   "#222222")
      (caribbean0 "#333333")
      (caribbean1 "#394851")
      (caribbean2 "#555555")
      (caribbean3 "#5e5e5e")
      (caribbean4 "#8c8c8c")
      (caribbean5 "#b3b3b3")
      (caribbean6 "#b3b3b3")
      (caribbean7 "#e8e9eb")
      (caribbean8 "#f0f4fc")
      (fg         "#ffffff")
      (fg-other   "#dedede")

      (grey       "#555555")
      (red        "#ff6c60")
      (darkred    "#fd721f")
      (orange     "#fd971f")
      (green      "#15bb84")
      (blue       "#87cefa")
      (magenta    "#fa87ce")
      (teal       "#7fffd4")
      (yellow     "#eedc82")
      (darkblue   "#59a5fe")
      (purple     "#8795fa")
      (cyan       "#88c0d0")
      (lightcyan  "#46d9ff")
      (darkcyan   "#5297a5")
      (black      "#000000")
      (white      "#ffffff"))

  (custom-theme-set-faces
   'timu-caribbean

;;; Custom faces

;;;; timu-caribbean-faces
   `(timu-caribbean-grey-face ((,class (:foreground ,grey))))
   `(timu-caribbean-red-face ((,class (:foreground ,red))))
   `(timu-caribbean-darkred-face ((,class (:foreground ,darkred))))
   `(timu-caribbean-orange-face ((,class (:foreground ,orange))))
   `(timu-caribbean-green-face ((,class (:foreground ,green))))
   `(timu-caribbean-blue-face ((,class (:foreground ,blue))))
   `(timu-caribbean-magenta-face ((,class (:foreground ,magenta))))
   `(timu-caribbean-teal-face ((,class (:foreground ,teal))))
   `(timu-caribbean-yellow-face ((,class (:foreground ,yellow))))
   `(timu-caribbean-darkblue-face ((,class (:foreground ,darkblue))))
   `(timu-caribbean-purple-face ((,class (:foreground ,purple))))
   `(timu-caribbean-cyan-face ((,class (:foreground ,cyan))))
   `(timu-caribbean-darkcyan-face ((,class (:foreground ,darkcyan))))
   `(timu-caribbean-black-face ((,class (:foreground ,black))))
   `(timu-caribbean-white-face ((,class (:foreground ,white))))
   `(timu-caribbean-default-face ((,class (:background ,bg :foreground ,fg))))
   `(timu-caribbean-bold-face ((,class (:weight bold :foreground ,white))))
   `(timu-caribbean-bold-face-italic ((,class (:weight bold :slant italic :foreground ,white))))
   `(timu-caribbean-italic-face ((,class (:slant italic :foreground ,white))))
   `(timu-caribbean-underline-face ((,class (:underline ,cyan))))
   `(timu-caribbean-strike-through-face ((,class (:strike-through ,cyan))))

;;;; default faces
   `(bold ((,class (:weight bold))))
   `(bold-italic ((,class (:weight bold :slant italic))))
   `(bookmark-face ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(cursor ((,class (:background ,teal))))
   `(default ((,class (:background ,bg :foreground ,fg))))
   `(error ((,class (:foreground ,red))))
   `(fringe ((,class (:foreground ,caribbean4))))
   `(highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(italic ((,class (:slant  italic))))
   `(lazy-highlight ((,class (:background ,darkblue  :foreground ,caribbean8 :distant-foreground ,caribbean0 :weight bold))))
   `(link ((,class (:foreground ,teal :underline t :weight bold))))
   `(match ((,class (:foreground ,green :background ,caribbean0 :weight bold))))
   `(minibuffer-prompt ((,class (:foreground ,red))))
   `(nobreak-space ((,class (:background ,bg :foreground ,fg))))
   `(region ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
   `(secondary-selection ((,class (:background ,grey :extend t))))
   `(shadow ((,class (:foreground ,caribbean5))))
   `(success ((,class (:foreground ,green))))
   `(tooltip ((,class (:background ,bg-other :foreground ,fg))))
   `(trailing-whitespace ((,class (:background ,red))))
   `(vertical-border ((,class (:background ,teal :foreground ,teal))))
   `(warning ((,class (:foreground ,yellow))))

;;;; font-lock
   `(font-lock-builtin-face ((,class (:foreground ,cyan))))
   `(font-lock-comment-delimiter-face ((,class (:foreground ,caribbean4))))
   `(font-lock-comment-face ((,class (:foreground ,caribbean4 :slant italic))))
   `(font-lock-constant-face ((,class (:foreground ,teal))))
   `(font-lock-doc-face ((,class (:foreground ,yellow :slant italic))))
   `(font-lock-function-name-face ((,class (:foreground ,lightcyan))))
   `(font-lock-keyword-face ((,class (:foreground ,teal))))
   `(font-lock-negation-char-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-preprocessor-char-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-preprocessor-face ((,class (:foreground ,fg :weight bold))))
   `(font-lock-regexp-grouping-backslash ((,class (:foreground ,fg :weight bold))))
   `(font-lock-regexp-grouping-construct ((,class (:foreground ,fg :weight bold))))
   `(font-lock-string-face ((,class (:foreground ,cyan))))
   `(font-lock-type-face ((,class (:foreground ,teal))))
   `(font-lock-variable-name-face ((,class (:foreground ,magenta))))
   `(font-lock-warning-face ((,class (:foreground ,yellow))))

;;;; ace-window
   `(aw-leading-char-face ((,class (:foreground ,red :height 500 :weight bold))))
   `(aw-background-face ((,class (:foreground ,caribbean5))))

;;;; alert
   `(alert-high-face ((,class (:foreground ,yellow :weight bold))))
   `(alert-low-face ((,class (:foreground ,grey))))
   `(alert-moderate-face ((,class (:foreground ,fg-other :weight bold))))
   `(alert-trivial-face ((,class (:foreground ,caribbean5))))
   `(alert-urgent-face ((,class (:foreground ,red :weight bold))))

;;;; all-the-icons
   `(all-the-icons-blue ((,class (:foreground ,blue))))
   `(all-the-icons-blue-alt ((,class (:foreground ,teal))))
   `(all-the-icons-cyan ((,class (:foreground ,darkblue))))
   `(all-the-icons-cyan-alt ((,class (:foreground ,darkblue))))
   `(all-the-icons-dblue ((,class (:foreground ,darkblue))))
   `(all-the-icons-dcyan ((,class (:foreground ,darkcyan))))
   `(all-the-icons-dgreen ((,class (:foreground ,green))))
   `(all-the-icons-dmagenta ((,class (:foreground ,red))))
   `(all-the-icons-dmaroon ((,class (:foreground ,purple))))
   `(all-the-icons-dorange ((,class (:foreground ,teal))))
   `(all-the-icons-dpurple ((,class (:foreground ,magenta))))
   `(all-the-icons-dred ((,class (:foreground ,red))))
   `(all-the-icons-dsilver ((,class (:foreground ,grey))))
   `(all-the-icons-dyellow ((,class (:foreground ,yellow))))
   `(all-the-icons-green ((,class (:foreground ,green))))
   `(all-the-icons-lblue ((,class (:foreground ,blue))))
   `(all-the-icons-lcyan ((,class (:foreground ,darkblue))))
   `(all-the-icons-lgreen ((,class (:foreground ,green))))
   `(all-the-icons-lmagenta ((,class (:foreground ,red))))
   `(all-the-icons-lmaroon ((,class (:foreground ,purple))))
   `(all-the-icons-lorange ((,class (:foreground ,teal))))
   `(all-the-icons-lpurple ((,class (:foreground ,magenta))))
   `(all-the-icons-lred ((,class (:foreground ,red))))
   `(all-the-icons-lsilver ((,class (:foreground ,grey))))
   `(all-the-icons-lyellow ((,class (:foreground ,yellow))))
   `(all-the-icons-magenta ((,class (:foreground ,red))))
   `(all-the-icons-maroon ((,class (:foreground ,purple))))
   `(all-the-icons-orange ((,class (:foreground ,teal))))
   `(all-the-icons-purple ((,class (:foreground ,magenta))))
   `(all-the-icons-purple-alt ((,class (:foreground ,magenta))))
   `(all-the-icons-red ((,class (:foreground ,red))))
   `(all-the-icons-red-alt ((,class (:foreground ,red))))
   `(all-the-icons-silver ((,class (:foreground ,grey))))
   `(all-the-icons-yellow ((,class (:foreground ,yellow))))
   `(all-the-icons-ibuffer-mode-face ((,class (:foreground ,teal))))
   `(all-the-icons-ibuffer-dir-face ((,class (:foreground ,cyan))))
   `(all-the-icons-ibuffer-file-face ((,class (:foreground ,blue))))
   `(all-the-icons-ibuffer-icon-face ((,class (:foreground ,magenta))))
   `(all-the-icons-ibuffer-size-face ((,class (:foreground ,yellow))))

;;;; all-the-icons-dired
   `(all-the-icons-dired-dir-face ((,class (:foreground ,fg-other))))

;;;; all-the-icons-ivy-rich
   `(all-the-icons-ivy-rich-doc-face ((,class (:foreground ,blue))))
   `(all-the-icons-ivy-rich-path-face ((,class (:foreground ,blue))))
   `(all-the-icons-ivy-rich-size-face ((,class (:foreground ,blue))))
   `(all-the-icons-ivy-rich-time-face ((,class (:foreground ,blue))))

;;;; annotate
   `(annotate-annotation ((,class (:background ,red :foreground ,caribbean5))))
   `(annotate-annotation-secondary ((,class (:background ,green :foreground ,caribbean5))))
   `(annotate-highlight ((,class (:background ,red :underline ,red))))
   `(annotate-highlight-secondary ((,class (:background ,green :underline ,green))))

;;;; ansi
   `(ansi-color-black ((,class (:foreground ,caribbean0))))
   `(ansi-color-blue ((,class (:foreground ,blue))))
   `(ansi-color-cyan ((,class (:foreground ,darkblue))))
   `(ansi-color-green ((,class (:foreground ,green))))
   `(ansi-color-magenta ((,class (:foreground ,magenta))))
   `(ansi-color-purple ((,class (:foreground ,purple))))
   `(ansi-color-red ((,class (:foreground ,red))))
   `(ansi-color-white ((,class (:foreground ,caribbean8))))
   `(ansi-color-yellow ((,class (:foreground ,yellow))))
   `(ansi-color-bright-black ((,class (:foreground ,caribbean0))))
   `(ansi-color-bright-blue ((,class (:foreground ,blue))))
   `(ansi-color-bright-cyan ((,class (:foreground ,darkblue))))
   `(ansi-color-bright-green ((,class (:foreground ,green))))
   `(ansi-color-bright-magenta ((,class (:foreground ,magenta))))
   `(ansi-color-bright-purple ((,class (:foreground ,purple))))
   `(ansi-color-bright-red ((,class (:foreground ,red))))
   `(ansi-color-bright-white ((,class (:foreground ,caribbean8))))
   `(ansi-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; anzu
   `(anzu-replace-highlight ((,class (:background ,caribbean0 :foreground ,red :weight bold :strike-through t))))
   `(anzu-replace-to ((,class (:background ,caribbean0 :foreground ,green :weight bold))))

;;;; auctex
   `(TeX-error-description-error ((,class (:foreground ,red :weight bold))))
   `(TeX-error-description-tex-said ((,class (:foreground ,green :weight bold))))
   `(TeX-error-description-warning ((,class (:foreground ,yellow :weight bold))))
   `(font-latex-bold-face ((,class (:weight bold))))
   `(font-latex-italic-face ((,class (:slant italic))))
   `(font-latex-math-face ((,class (:foreground ,blue))))
   `(font-latex-script-char-face ((,class (:foreground ,darkblue))))
   `(font-latex-sectioning-0-face ((,class (:foreground ,blue :weight ultra-bold))))
   `(font-latex-sectioning-1-face ((,class (:foreground ,purple :weight semi-bold))))
   `(font-latex-sectioning-2-face ((,class (:foreground ,magenta :weight semi-bold))))
   `(font-latex-sectioning-3-face ((,class (:foreground ,blue :weight semi-bold))))
   `(font-latex-sectioning-4-face ((,class (:foreground ,purple :weight semi-bold))))
   `(font-latex-sectioning-5-face ((,class (:foreground ,magenta :weight semi-bold))))
   `(font-latex-string-face ((,class (:foreground ,teal))))
   `(font-latex-verbatim-face ((,class (:foreground ,magenta :slant italic))))
   `(font-latex-warning-face ((,class (:foreground ,yellow))))

;;;; avy
   `(avy-background-face ((,class (:foreground ,caribbean5))))
   `(avy-lead-face ((,class (:background ,teal :foreground ,black))))
   `(avy-lead-face-0 ((,class (:background ,teal :foreground ,black))))
   `(avy-lead-face-1 ((,class (:background ,teal :foreground ,black))))
   `(avy-lead-face-2 ((,class (:background ,teal :foreground ,black))))

;;;; bookmark+
   `(bmkp-*-mark ((,class (:foreground ,bg :background ,yellow))))
   `(bmkp->-mark ((,class (:foreground ,yellow))))
   `(bmkp-D-mark ((,class (:foreground ,bg :background ,red))))
   `(bmkp-X-mark ((,class (:foreground ,red))))
   `(bmkp-a-mark ((,class (:background ,red))))
   `(bmkp-bad-bookmark ((,class (:foreground ,bg :background ,yellow))))
   `(bmkp-bookmark-file ((,class (:foreground ,magenta :background ,bg-other))))
   `(bmkp-bookmark-list ((,class (:background ,bg-other))))
   `(bmkp-buffer ((,class (:foreground ,blue))))
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
   `(bmkp-local-file-without-region ((,class (:foreground ,caribbean5))))
   `(bmkp-man ((,class (:foreground ,magenta))))
   `(bmkp-no-jump ((,class (:foreground ,caribbean5))))
   `(bmkp-no-local ((,class (:foreground ,yellow))))
   `(bmkp-non-file ((,class (:foreground ,green))))
   `(bmkp-remote-file ((,class (:foreground ,red))))
   `(bmkp-sequence ((,class (:foreground ,blue))))
   `(bmkp-su-or-sudo ((,class (:foreground ,red))))
   `(bmkp-t-mark ((,class (:foreground ,magenta))))
   `(bmkp-url ((,class (:foreground ,blue :underline t))))
   `(bmkp-variable-list ((,class (:foreground ,green))))

;;;; calfw
   `(cfw:face-annotation ((,class (:foreground ,magenta))))
   `(cfw:face-day-title ((,class (:foreground ,fg :weight bold))))
   `(cfw:face-default-content ((,class (:foreground ,fg))))
   `(cfw:face-default-day ((,class (:weight bold))))
   `(cfw:face-disable ((,class (:foreground ,grey))))
   `(cfw:face-grid ((,class (:foreground ,bg))))
   `(cfw:face-header ((,class (:foreground ,blue :weight bold))))
   `(cfw:face-holiday ((,class (:foreground nil :background ,bg-other :weight bold))))
   `(cfw:face-periods ((,class (:foreground ,yellow))))
   `(cfw:face-saturday ((,class (:foreground ,red :weight bold))))
   `(cfw:face-select ((,class (:background ,grey))))
   `(cfw:face-sunday ((,class (:foreground ,red :weight bold))))
   `(cfw:face-title ((,class (:foreground ,blue :weight bold :height 2.0))))
   `(cfw:face-today ((,class (:foreground nil :background nil :weight bold))))
   `(cfw:face-today-title ((,class (:foreground ,bg :background ,blue :weight bold))))
   `(cfw:face-toolbar ((,class (:foreground nil :background nil))))
   `(cfw:face-toolbar-button-off ((,class (:foreground ,caribbean6 :weight bold))))
   `(cfw:face-toolbar-button-on ((,class (:foreground ,blue :weight bold))))

;;;; centaur-tabs
   `(centaur-tabs-active-bar-face ((,class (:background ,bg :foreground ,teal))))
   `(centaur-tabs-close-mouse-face ((,class (:foreground ,teal))))
   `(centaur-tabs-close-selected ((,class (:background ,bg :foreground ,fg))))
   `(centaur-tabs-close-unselected ((,class (:background ,bg-other :foreground ,grey))))
   `(centaur-tabs-default ((,class (:background ,bg-other :foreground ,fg))))
   `(centaur-tabs-modified-marker-selected ((,class (:background ,bg :foreground ,teal))))
   `(centaur-tabs-modified-marker-unselected ((,class (:background ,bg :foreground ,teal))))
   `(centaur-tabs-name-mouse-face ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(centaur-tabs-selected ((,class (:background ,caribbean2 :foreground ,fg))))
   `(centaur-tabs-selected-modified ((,class (:background ,bg :foreground ,cyan))))
   `(centaur-tabs-unselected ((,class (:background ,bg-other :foreground ,grey))))
   `(centaur-tabs-unselected-modified ((,class (:background ,bg-other :foreground ,red))))

;;;; circe
   `(circe-fool ((,class (:foreground ,caribbean5))))
   `(circe-highlight-nick-face ((,class (:weight bold :foreground ,teal))))
   `(circe-my-message-face ((,class (:weight bold))))
   `(circe-prompt-face ((,class (:weight bold :foreground ,teal))))
   `(circe-server-face ((,class (:foreground ,caribbean5))))

;;;; company
   `(company-preview ((,class (:background ,bg-other :foreground ,caribbean5))))
   `(company-preview-common ((,class (:background ,caribbean3 :foreground ,cyan))))
   `(company-preview-search ((,class (:background ,cyan :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(company-scrollbar-bg ((,class (:background ,bg-other :foreground ,fg))))
   `(company-scrollbar-fg ((,class (:background ,cyan))))
   `(company-template-field ((,class (:foreground ,green :background ,caribbean0 :weight bold))))
   `(company-tooltip ((,class (:background ,bg-other :foreground ,fg))))
   `(company-tooltip-annotation ((,class (:foreground ,magenta :distant-foreground ,bg))))
   `(company-tooltip-common ((,class (:foreground ,cyan :distant-foreground ,caribbean0 :weight bold))))
   `(company-tooltip-mouse ((,class (:background ,purple :foreground ,bg :distant-foreground ,fg))))
   `(company-tooltip-search ((,class (:background ,cyan :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(company-tooltip-search-selection ((,class (:background ,grey))))
   `(company-tooltip-selection ((,class (:background ,grey :weight bold))))

;;;; company-box
   `(company-box-candidate ((,class (:foreground ,fg))))

;;;; compilation
   `(compilation-column-number ((,class (:foreground ,caribbean5))))
   `(compilation-error ((,class (:foreground ,red :weight bold))))
   `(compilation-info ((,class (:foreground ,green))))
   `(compilation-line-number ((,class (:foreground ,red))))
   `(compilation-mode-line-exit ((,class (:foreground ,green))))
   `(compilation-mode-line-fail ((,class (:foreground ,red :weight bold))))
   `(compilation-warning ((,class (:foreground ,yellow :slant italic))))

;;;; consult
   `(consult-file ((,class (:foreground ,blue))))

;;;; corfu
   `(corfu-bar ((,class (:background ,bg-other :foreground ,fg))))
   `(corfu-echo ((,class (:foreground ,red))))
   `(corfu-border ((,class (:background ,bg-other :foreground ,fg))))
   `(corfu-current ((,class (:foreground ,red :weight bold))))
   `(corfu-default ((,class (:background ,bg-other :foreground ,fg))))
   `(corfu-deprecated ((,class (:foreground ,teal))))
   `(corfu-annotations ((,class (:foreground ,magenta))))

;;;; counsel
   `(counsel-variable-documentation ((,class (:foreground ,blue))))

;;;; cperl
   `(cperl-array-face ((,class (:foreground ,red :weight bold))))
   `(cperl-hash-face ((,class (:foreground ,red :weight bold :slant italic))))
   `(cperl-nonoverridable-face ((,class (:foreground ,cyan))))

;;;; custom
   `(custom-button ((,class (:foreground ,fg :background ,bg-other :box (:line-width 3 :style released-button)))))
   `(custom-button-mouse ((,class (:foreground ,yellow :background ,bg-other :box (:line-width 3 :style released-button)))))
   `(custom-button-pressed ((,class (:foreground ,bg :background ,bg-other :box (:line-width 3 :style pressed-button)))))
   `(custom-button-pressed-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
   `(custom-button-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
   `(custom-changed ((,class (:foreground ,blue :background ,bg))))
   `(custom-comment ((,class (:foreground ,fg :background ,grey))))
   `(custom-comment-tag ((,class (:foreground ,grey))))
   `(custom-documentation ((,class (:foreground ,fg))))
   `(custom-face-tag ((,class (:foreground ,blue :weight bold))))
   `(custom-group-subtitle ((,class (:foreground ,magenta :weight bold))))
   `(custom-group-tag ((,class (:foreground ,magenta :weight bold))))
   `(custom-group-tag-1 ((,class (:foreground ,blue))))
   `(custom-invalid ((,class (:foreground ,red))))
   `(custom-link ((,class (:foreground ,cyan :underline t))))
   `(custom-modified ((,class (:foreground ,blue))))
   `(custom-rogue ((,class (:foreground ,blue :box (:line-width 3 :style none)))))
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
   `(diff-file-header ((,class (:foreground ,teal :weight bold))))
   `(diff-hunk-header ((,class (:foreground ,bg :background ,magenta :extend t))))
   `(diff-function ((,class (:foreground ,bg :background ,magenta :extend t))))

;;;; diff-hl
   `(diff-hl-change ((,class (:foreground ,teal :background ,teal))))
   `(diff-hl-delete ((,class (:foreground ,red :background ,red))))
   `(diff-hl-insert ((,class (:foreground ,green :background ,green))))

;;;; dired
   `(dired-directory ((,class (:foreground ,darkcyan :underline ,darkcyan))))
   `(dired-flagged ((,class (:foreground ,red))))
   `(dired-header ((,class (:foreground ,cyan :weight bold :underline ,darkcyan))))
   `(dired-ignored ((,class (:foreground ,caribbean5))))
   `(dired-mark ((,class (:foreground ,cyan :weight bold))))
   `(dired-marked ((,class (:foreground ,yellow :weight bold))))
   `(dired-perm-write ((,class (:foreground ,red :underline t))))
   `(dired-symlink ((,class (:foreground ,magenta))))
   `(dired-warning ((,class (:foreground ,yellow))))

;;;; dired-async
   `(dired-async-failures ((,class (:foreground ,red))))
   `(dired-async-message ((,class (:foreground ,cyan))))
   `(dired-async-mode-message ((,class (:foreground ,cyan))))

;;;; dired-filetype-face
   `(dired-filetype-common ((,class (:foreground ,fg))))
   `(dired-filetype-compress ((,class (:foreground ,yellow))))
   `(dired-filetype-document ((,class (:foreground ,cyan))))
   `(dired-filetype-execute ((,class (:foreground ,red))))
   `(dired-filetype-image ((,class (:foreground ,teal))))
   `(dired-filetype-js ((,class (:foreground ,yellow))))
   `(dired-filetype-link ((,class (:foreground ,magenta))))
   `(dired-filetype-music ((,class (:foreground ,magenta))))
   `(dired-filetype-omit ((,class (:foreground ,blue))))
   `(dired-filetype-plain ((,class (:foreground ,fg))))
   `(dired-filetype-program ((,class (:foreground ,red))))
   `(dired-filetype-source ((,class (:foreground ,green))))
   `(dired-filetype-video ((,class (:foreground ,magenta))))
   `(dired-filetype-xml ((,class (:foreground ,green))))

;;;; dired+
   `(diredp-compressed-file-suffix ((,class (:foreground ,caribbean5))))
   `(diredp-date-time ((,class (:foreground ,blue))))
   `(diredp-dir-heading ((,class (:foreground ,blue :weight bold))))
   `(diredp-dir-name ((,class (:foreground ,caribbean8 :weight bold))))
   `(diredp-dir-priv ((,class (:foreground ,blue :weight bold))))
   `(diredp-exec-priv ((,class (:foreground ,yellow))))
   `(diredp-file-name ((,class (:foreground ,caribbean8))))
   `(diredp-file-suffix ((,class (:foreground ,magenta))))
   `(diredp-ignored-file-name ((,class (:foreground ,caribbean5))))
   `(diredp-no-priv ((,class (:foreground ,caribbean5))))
   `(diredp-number ((,class (:foreground ,purple))))
   `(diredp-rare-priv ((,class (:foreground ,red :weight bold))))
   `(diredp-read-priv ((,class (:foreground ,purple))))
   `(diredp-symlink ((,class (:foreground ,magenta))))
   `(diredp-write-priv ((,class (:foreground ,green))))

;;;; dired-k
   `(dired-k-added ((,class (:foreground ,green :weight bold))))
   `(dired-k-commited ((,class (:foreground ,green :weight bold))))
   `(dired-k-directory ((,class (:foreground ,blue :weight bold))))
   `(dired-k-ignored ((,class (:foreground ,caribbean5 :weight bold))))
   `(dired-k-modified ((,class (:foreground , :weight bold))))
   `(dired-k-untracked ((,class (:foreground ,orange :weight bold))))

;;;; dired-subtree
   `(dired-subtree-depth-1-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-2-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-3-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-4-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-5-face ((,class (:background ,bg-other))))
   `(dired-subtree-depth-6-face ((,class (:background ,bg-other))))

;;;; diredfl
   `(diredfl-autofile-name ((,class (:foreground ,caribbean4))))
   `(diredfl-compressed-file-name ((,class (:foreground ,teal))))
   `(diredfl-compressed-file-suffix ((,class (:foreground ,yellow))))
   `(diredfl-date-time ((,class (:foreground ,darkblue :weight light))))
   `(diredfl-deletion ((,class (:foreground ,red :weight bold))))
   `(diredfl-deletion-file-name ((,class (:foreground ,red))))
   `(diredfl-dir-heading ((,class (:foreground ,blue :weight bold))))
   `(diredfl-dir-name ((,class (:foreground ,darkcyan))))
   `(diredfl-dir-priv ((,class (:foreground ,blue))))
   `(diredfl-exec-priv ((,class (:foreground ,red))))
   `(diredfl-executable-tag ((,class (:foreground ,red))))
   `(diredfl-file-name ((,class (:foreground ,fg))))
   `(diredfl-file-suffix ((,class (:foreground ,orange))))
   `(diredfl-flag-mark ((,class (:foreground ,yellow :background ,yellow :weight bold))))
   `(diredfl-flag-mark-line ((,class (:background ,yellow))))
   `(diredfl-ignored-file-name ((,class (:foreground ,caribbean5))))
   `(diredfl-link-priv ((,class (:foreground ,magenta))))
   `(diredfl-no-priv ((,class (:foreground ,fg))))
   `(diredfl-number ((,class (:foreground ,teal))))
   `(diredfl-other-priv ((,class (:foreground ,purple))))
   `(diredfl-rare-priv ((,class (:foreground ,fg))))
   `(diredfl-read-priv ((,class (:foreground ,yellow))))
   `(diredfl-symlink ((,class (:foreground ,magenta))))
   `(diredfl-tagged-autofile-name ((,class (:foreground ,caribbean5))))
   `(diredfl-write-priv ((,class (:foreground ,red))))

;;;; doom-modeline
   `(doom-modeline-bar ((,class (:foreground ,magenta))))
   `(doom-modeline-bar-inactive ((,class (:background nil))))
   `(doom-modeline-buffer-major-mode ((,class (:foreground ,magenta))))
   `(doom-modeline-buffer-path ((,class (:foreground ,magenta))))
   `(doom-modeline-eldoc-bar ((,class (:background ,green))))
   `(doom-modeline-evil-emacs-state ((,class (:foreground ,darkblue :weight bold))))
   `(doom-modeline-evil-insert-state ((,class (:foreground ,red :weight bold))))
   `(doom-modeline-evil-motion-state ((,class (:foreground ,blue :weight bold))))
   `(doom-modeline-evil-normal-state ((,class (:foreground ,green :weight bold))))
   `(doom-modeline-evil-operator-state ((,class (:foreground ,magenta :weight bold))))
   `(doom-modeline-evil-replace-state ((,class (:foreground ,purple :weight bold))))
   `(doom-modeline-evil-visual-state ((,class (:foreground ,yellow :weight bold))))
   `(doom-modeline-highlight ((,class (:foreground ,magenta))))
   `(doom-modeline-input-method ((,class (:foreground ,magenta))))
   `(doom-modeline-panel ((,class (:foreground ,magenta))))
   `(doom-modeline-project-dir ((,class (:foreground ,teal :weight bold))))
   `(doom-modeline-project-root-dir ((,class (:foreground ,magenta))))

;;;; ediff
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

;;;; elfeed
   `(elfeed-log-debug-level-face ((,class (:foreground ,caribbean5))))
   `(elfeed-log-error-level-face ((,class (:foreground ,red))))
   `(elfeed-log-info-level-face ((,class (:foreground ,green))))
   `(elfeed-log-warn-level-face ((,class (:foreground ,yellow))))
   `(elfeed-search-date-face ((,class (:foreground ,cyan))))
   `(elfeed-search-feed-face ((,class (:foreground ,teal))))
   `(elfeed-search-filter-face ((,class (:foreground ,magenta))))
   `(elfeed-search-tag-face ((,class (:foreground ,caribbean5))))
   `(elfeed-search-title-face ((,class (:foreground ,caribbean5))))
   `(elfeed-search-unread-count-face ((,class (:foreground ,yellow))))
   `(elfeed-search-unread-title-face ((,class (:foreground ,fg :weight bold))))

;;;; elixir-mode
   `(elixir-atom-face ((,class (:foreground ,darkblue))))
   `(elixir-attribute-face ((,class (:foreground ,magenta))))

;;;; elscreen
   `(elscreen-tab-background-face ((,class (:background ,bg))))
   `(elscreen-tab-control-face ((,class (:background ,bg :foreground ,bg))))
   `(elscreen-tab-current-screen-face ((,class (:background ,bg-other :foreground ,fg))))
   `(elscreen-tab-other-screen-face ((,class (:background ,bg :foreground ,fg-other))))

;;;; enh-ruby-mode
   `(enh-ruby-heredoc-delimiter-face ((,class (:foreground ,teal))))
   `(enh-ruby-op-face ((,class (:foreground ,fg))))
   `(enh-ruby-regexp-delimiter-face ((,class (:foreground ,teal))))
   `(enh-ruby-regexp-face ((,class (:foreground ,teal))))
   `(enh-ruby-string-delimiter-face ((,class (:foreground ,teal))))
   `(erm-syn-errline ((,class (:underline (:style wave :color ,red)))))
   `(erm-syn-warnline ((,class (:underline (:style wave :color ,yellow)))))

;;;; erc
   `(erc-action-face  ((,class (:weight bold))))
   `(erc-button ((,class (:weight bold :underline t))))
   `(erc-command-indicator-face ((,class (:weight bold))))
   `(erc-current-nick-face ((,class (:foreground ,green :weight bold))))
   `(erc-default-face ((,class (:background ,bg :foreground ,fg))))
   `(erc-direct-msg-face ((,class (:foreground ,purple))))
   `(erc-error-face ((,class (:foreground ,red))))
   `(erc-header-line ((,class (:background ,bg-other :foreground ,teal))))
   `(erc-input-face ((,class (:foreground ,green))))
   `(erc-my-nick-face ((,class (:foreground ,green :weight bold))))
   `(erc-my-nick-prefix-face ((,class (:foreground ,green :weight bold))))
   `(erc-nick-default-face ((,class (:weight bold))))
   `(erc-nick-msg-face ((,class (:foreground ,purple))))
   `(erc-nick-prefix-face ((,class (:background ,bg :foreground ,fg))))
   `(erc-notice-face ((,class (:foreground ,caribbean5))))
   `(erc-prompt-face ((,class (:foreground ,teal :weight bold))))
   `(erc-timestamp-face ((,class (:foreground ,blue :weight bold))))

;;;; eshell
   `(eshell-ls-archive ((,class (:foreground ,yellow))))
   `(eshell-ls-backup ((,class (:foreground ,yellow))))
   `(eshell-ls-clutter ((,class (:foreground ,red))))
   `(eshell-ls-directory ((,class (:foreground ,teal))))
   `(eshell-ls-executable ((,class (:foreground ,red))))
   `(eshell-ls-missing ((,class (:foreground ,red))))
   `(eshell-ls-product ((,class (:foreground ,teal))))
   `(eshell-ls-readonly ((,class (:foreground ,teal))))
   `(eshell-ls-special ((,class (:foreground ,magenta))))
   `(eshell-ls-symlink ((,class (:foreground ,magenta))))
   `(eshell-ls-unreadable ((,class (:foreground ,caribbean5))))
   `(eshell-prompt ((,class (:foreground ,cyan :weight bold))))

;;;; evil
   `(evil-ex-info ((,class (:foreground ,red :slant italic))))
   `(evil-ex-search ((,class (:background ,teal :foreground ,caribbean0 :weight bold))))
   `(evil-ex-substitute-matches ((,class (:background ,caribbean0 :foreground ,red :weight bold :strike-through t))))
   `(evil-ex-substitute-replacement ((,class (:background ,caribbean0 :foreground ,green :weight bold))))
   `(evil-search-highlight-persist-highlight-face ((,class (:background ,darkblue  :foreground ,caribbean8 :distant-foreground ,caribbean0 :weight bold))))

;;;; evil-googles
   `(evil-goggles-default-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-mc
   `(evil-mc-cursor-bar-face ((,class (:height 1 :background ,purple :foreground ,caribbean0))))
   `(evil-mc-cursor-default-face ((,class (:background ,purple :foreground ,caribbean0 :inverse-video nil))))
   `(evil-mc-cursor-hbar-face ((,class (:underline (:color ,teal)))))
   `(evil-mc-region-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-snipe
   `(evil-snipe-first-match-face ((,class (:foreground ,red :background ,darkblue :weight bold))))
   `(evil-snipe-matches-face ((,class (:foreground ,red :underline t :weight bold))))

;;;; expenses
   `(expenses-face-date ((,class (:foreground ,red :weight bold))))
   `(expenses-face-expence ((,class (:foreground ,green :weight bold))))
   `(expenses-face-message ((,class (:foreground ,teal :weight bold))))

;;;; flx-ido
   `(flx-highlight-face ((,class (:weight bold :foreground ,yellow :underline nil))))

;;;; flycheck
   `(flycheck-error ((,class (:underline (:style wave :color ,red)))))
   `(flycheck-fringe-error ((,class (:foreground ,red))))
   `(flycheck-fringe-info ((,class (:foreground ,green))))
   `(flycheck-fringe-warning ((,class (:foreground ,yellow))))
   `(flycheck-info ((,class (:underline (:style wave :color ,green)))))
   `(flycheck-warning ((,class (:underline (:style wave :color ,yellow)))))

;;;; flycheck-posframe
   `(flycheck-posframe-background-face ((,class (:background ,bg-other))))
   `(flycheck-posframe-error-face ((,class (:foreground ,red))))
   `(flycheck-posframe-face ((,class (:background ,bg :foreground ,fg))))
   `(flycheck-posframe-info-face ((,class (:background ,bg :foreground ,fg))))
   `(flycheck-posframe-warning-face ((,class (:foreground ,yellow))))

;;;; flymake
   `(flymake-error ((,class (:underline (:style wave :color ,red)))))
   `(flymake-note ((,class (:underline (:style wave :color ,green)))))
   `(flymake-warning ((,class (:underline (:style wave :color ,teal)))))

;;;; flyspell
   `(flyspell-duplicate ((,class (:underline (:style wave :color ,yellow)))))
   `(flyspell-incorrect ((,class (:underline (:style wave :color ,red)))))

;;;; forge
   `(forge-topic-closed ((,class (:foreground ,caribbean5 :strike-through t))))
   `(forge-topic-label ((,class (:box nil))))

;;;; git-commit
   `(git-commit-comment-branch-local ((,class (:foreground ,purple))))
   `(git-commit-comment-branch-remote ((,class (:foreground ,green))))
   `(git-commit-comment-detached ((,class (:foreground ,cyan))))
   `(git-commit-comment-file ((,class (:foreground ,magenta))))
   `(git-commit-comment-heading ((,class (:foreground ,magenta))))
   `(git-commit-keyword ((,class (:foreground ,darkblue :slant italic))))
   `(git-commit-known-pseudo-header ((,class (:foreground ,caribbean5 :weight bold :slant italic))))
   `(git-commit-nonempty-second-line ((,class (:foreground ,red))))
   `(git-commit-overlong-summary ((,class (:foreground ,red :slant italic :weight bold))))
   `(git-commit-pseudo-header ((,class (:foreground ,caribbean5 :slant italic))))
   `(git-commit-summary ((,class (:foreground ,teal))))

;;;; git-gutter
   `(git-gutter:added ((,class (:foreground ,green))))
   `(git-gutter:deleted ((,class (:foreground ,red))))
   `(git-gutter:modified ((,class (:foreground ,darkblue))))

;;;; git-gutter+
   `(git-gutter+-added ((,class (:foreground ,green))))
   `(git-gutter+-deleted ((,class (:foreground ,red))))
   `(git-gutter+-modified ((,class (:foreground ,darkblue))))

;;;; git-gutter-fringe
   `(git-gutter-fr:added ((,class (:foreground ,green))))
   `(git-gutter-fr:deleted ((,class (:foreground ,red))))
   `(git-gutter-fr:modified ((,class (:foreground ,darkblue))))

;;;; gnus
   `(gnus-cite-1 ((,class (:foreground ,purple))))
   `(gnus-cite-2 ((,class (:foreground ,magenta))))
   `(gnus-cite-3 ((,class (:foreground ,darkblue))))
   `(gnus-cite-4 ((,class (:foreground ,darkcyan))))
   `(gnus-cite-5 ((,class (:foreground ,purple))))
   `(gnus-cite-6 ((,class (:foreground ,magenta))))
   `(gnus-cite-7 ((,class (:foreground ,darkblue))))
   `(gnus-cite-8 ((,class (:foreground ,darkcyan))))
   `(gnus-cite-9 ((,class (:foreground ,purple))))
   `(gnus-cite-10 ((,class (:foreground ,magenta))))
   `(gnus-cite-11 ((,class (:foreground ,darkblue))))
   `(gnus-group-mail-1 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-1-empty ((,class (:foreground ,caribbean5))))
   `(gnus-group-mail-2 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-2-empty ((,class (:foreground ,caribbean5))))
   `(gnus-group-mail-3 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-mail-3-empty ((,class (:foreground ,caribbean5))))
   `(gnus-group-mail-low ((,class (:foreground ,fg))))
   `(gnus-group-mail-low-empty ((,class (:foreground ,caribbean5))))
   `(gnus-group-news-1 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-1-empty ((,class (:foreground ,caribbean5))))
   `(gnus-group-news-2 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-2-empty ((,class (:foreground ,caribbean5))))
   `(gnus-group-news-3 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-3-empty ((,class (:foreground ,caribbean5))))
   `(gnus-group-news-4 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-4-empty ((,class (:foreground ,caribbean5))))
   `(gnus-group-news-5 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-5-empty ((,class (:foreground ,caribbean5))))
   `(gnus-group-news-6 ((,class (:weight bold :foreground ,fg))))
   `(gnus-group-news-6-empty ((,class (:foreground ,caribbean5))))
   `(gnus-group-news-low ((,class (:weight bold :foreground ,caribbean5))))
   `(gnus-group-news-low-empty ((,class (:foreground ,fg))))
   `(gnus-header-content ((,class (:foreground ,blue))))
   `(gnus-header-from ((,class (:foreground ,blue))))
   `(gnus-header-name ((,class (:foreground ,red))))
   `(gnus-header-newsgroups ((,class (:foreground ,blue))))
   `(gnus-header-subject ((,class (:foreground ,cyan :weight bold))))
   `(gnus-signature ((,class (:foreground ,yellow))))
   `(gnus-summary-cancelled ((,class (:foreground ,red :strike-through t))))
   `(gnus-summary-high-ancient ((,class (:foreground ,caribbean5 :slant italic))))
   `(gnus-summary-high-read ((,class (:foreground ,fg))))
   `(gnus-summary-high-ticked ((,class (:foreground ,purple))))
   `(gnus-summary-high-unread ((,class (:foreground ,green))))
   `(gnus-summary-low-ancient ((,class (:foreground ,caribbean5 :slant italic))))
   `(gnus-summary-low-read ((,class (:foreground ,fg))))
   `(gnus-summary-low-ticked ((,class (:foreground ,purple))))
   `(gnus-summary-low-unread ((,class (:foreground ,green))))
   `(gnus-summary-normal-ancient ((,class (:foreground ,caribbean5 :slant italic))))
   `(gnus-summary-normal-read ((,class (:foreground ,fg))))
   `(gnus-summary-normal-ticked ((,class (:foreground ,purple))))
   `(gnus-summary-normal-unread ((,class (:foreground ,green :weight bold))))
   `(gnus-summary-selected ((,class (:foreground ,blue :weight bold))))
   `(gnus-x-face ((,class (:background ,caribbean5 :foreground ,fg))))

;;;; goggles
   `(goggles-added ((,class (:background ,green))))
   `(goggles-changed ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
   `(goggles-removed ((,class (:background ,red :extend t))))

;;;; header-line
   `(header-line ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))

;;;; helm
   `(helm-ff-directory ((,class (:foreground ,red))))
   `(helm-ff-dotted-directory ((,class (:foreground ,grey))))
   `(helm-ff-executable ((,class (:foreground ,caribbean8 :slant italic))))
   `(helm-ff-file ((,class (:foreground ,fg))))
   `(helm-ff-prefix ((,class (:foreground ,magenta))))
   `(helm-grep-file ((,class (:foreground ,blue))))
   `(helm-grep-finish ((,class (:foreground ,green))))
   `(helm-grep-lineno ((,class (:foreground ,caribbean5))))
   `(helm-grep-match ((,class (:foreground ,teal :distant-foreground ,red))))
   `(helm-match ((,class (:foreground ,teal :distant-foreground ,caribbean8 :weight bold))))
   `(helm-moccur-buffer ((,class (:foreground ,red :underline t :weight bold))))
   `(helm-selection ((,class (:background ,grey :extend t :distant-foreground ,teal :weight bold))))
   `(helm-source-header ((,class (:background ,caribbean2 :foreground ,magenta :weight bold))))
   `(helm-swoop-target-line-block-face ((,class (:foreground ,yellow))))
   `(helm-swoop-target-line-face ((,class (:foreground ,teal :inverse-video t))))
   `(helm-swoop-target-line-face ((,class (:foreground ,teal :inverse-video t))))
   `(helm-swoop-target-number-face ((,class (:foreground ,caribbean5))))
   `(helm-swoop-target-word-face ((,class (:foreground ,green :weight bold))))
   `(helm-visible-mark ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))

;;;; helpful
   `(helpful-heading ((,class (:foreground ,darkblue :weight bold :height 1.2))))

;;;; hi-lock
   `(hi-blue ((,class (:background ,blue))))
   `(hi-blue-b ((,class (:foreground ,blue :weight bold))))
   `(hi-green ((,class (:background ,green))))
   `(hi-green-b ((,class (:foreground ,green :weight bold))))
   `(hi-magenta ((,class (:background ,purple))))
   `(hi-red-b ((,class (:foreground ,red :weight bold))))
   `(hi-yellow ((,class (:background ,yellow))))

;;;; highlight-indentation-mode
   `(highlight-indentation-current-column-face ((,class (:background ,caribbean1))))
   `(highlight-indentation-face ((,class (:background ,caribbean2 :extend t))))
   `(highlight-indentation-guides-even-face ((,class (:background ,caribbean2 :extend t))))
   `(highlight-indentation-guides-odd-face ((,class (:background ,caribbean2 :extend t))))

;;;; highlight-numbers-mode
   `(highlight-numbers-number ((,class (:foreground ,teal :weight bold))))

;;;; highlight-quoted-mode
   `(highlight-quoted-quote  ((,class (:foreground ,fg))))
   `(highlight-quoted-symbol ((,class (:foreground ,yellow))))

;;;; highlight-symbol
   `(highlight-symbol-face ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; highlight-thing
   `(highlight-thing ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; hl-fill-column-face
   `(hl-fill-column-face ((,class (:background ,caribbean2 :extend t))))

;;;; hl-line (built-in)
   `(hl-line ((,class (:background ,bg-other :extend t))))

;;;; hl-todo
   `(hl-todo ((,class (:foreground ,red :weight bold))))

;;;; hlinum
   `(linum-highlight-face ((,class (:foreground ,fg :distant-foreground nil :weight normal))))

;;;; hydra
   `(hydra-face-amaranth ((,class (:foreground ,purple :weight bold))))
   `(hydra-face-blue ((,class (:foreground ,blue :weight bold))))
   `(hydra-face-magenta ((,class (:foreground ,magenta :weight bold))))
   `(hydra-face-red ((,class (:foreground ,red :weight bold))))
   `(hydra-face-teal ((,class (:foreground ,orange :weight bold))))

;;;; ido
   `(ido-first-match ((,class (:foreground ,teal))))
   `(ido-indicator ((,class (:foreground ,red :background ,bg))))
   `(ido-only-match ((,class (:foreground ,green))))
   `(ido-subdir ((,class (:foreground ,magenta))))
   `(ido-virtual ((,class (:foreground ,caribbean5))))

;;;; iedit
   `(iedit-occurrence ((,class (:foreground ,purple :weight bold :inverse-video t))))
   `(iedit-read-only-occurrence ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))


;;;; imenu-list
   `(imenu-list-entry-face-0 ((,class (:foreground ,red))))
   `(imenu-list-entry-face-1 ((,class (:foreground ,blue))))
   `(imenu-list-entry-face-2 ((,class (:foreground ,teal))))
   `(imenu-list-entry-subalist-face-0 ((,class (:foreground ,red :weight bold))))
   `(imenu-list-entry-subalist-face-1 ((,class (:foreground ,blue :weight bold))))
   `(imenu-list-entry-subalist-face-2 ((,class (:foreground ,teal :weight bold))))

;;;; indent-guide
   `(indent-guide-face ((,class (:background ,caribbean2 :extend t))))

;;;; isearch
   `(isearch ((,class (:background ,darkblue  :foreground ,caribbean8 :distant-foreground ,caribbean0 :weight bold))))
   `(isearch-fail ((,class (:background ,red :foreground ,caribbean0 :weight bold))))

;;;; ivy
   `(ivy-confirm-face ((,class (:foreground ,green))))
   `(ivy-current-match ((,class (:background ,grey :distant-foreground nil :extend t))))
   `(ivy-highlight-face ((,class (:foreground ,magenta))))
   `(ivy-match-required-face ((,class (:foreground ,red))))
   `(ivy-minibuffer-match-face-1 ((,class (:background nil :foreground ,teal :weight bold :underline t))))
   `(ivy-minibuffer-match-face-2 ((,class (:foreground ,purple :background ,caribbean1 :weight semi-bold))))
   `(ivy-minibuffer-match-face-3 ((,class (:foreground ,green :weight semi-bold))))
   `(ivy-minibuffer-match-face-4 ((,class (:foreground ,yellow :weight semi-bold))))
   `(ivy-minibuffer-match-highlight ((,class (:foreground ,magenta))))
   `(ivy-modified-buffer ((,class (:weight bold :foreground ,darkcyan))))
   `(ivy-virtual ((,class (:slant italic :foreground ,fg))))

;;;; ivy-posframe
   `(ivy-posframe ((,class (:background ,bg-other))))
   `(ivy-posframe-border ((,class (:background ,red))))

;;;; jabber
   `(jabber-activity-face ((,class (:foreground ,red :weight bold))))
   `(jabber-activity-personal-face ((,class (:foreground ,blue :weight bold))))
   `(jabber-chat-error ((,class (:foreground ,red :weight bold))))
   `(jabber-chat-prompt-foreign ((,class (:foreground ,red :weight bold))))
   `(jabber-chat-prompt-local ((,class (:foreground ,blue :weight bold))))
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

;;;; jdee
   `(jdee-font-lock-bold-face ((,class (:weight bold))))
   `(jdee-font-lock-constant-face ((,class (:foreground ,red))))
   `(jdee-font-lock-constructor-face ((,class (:foreground ,blue))))
   `(jdee-font-lock-doc-tag-face ((,class (:foreground ,magenta))))
   `(jdee-font-lock-italic-face ((,class (:slant italic))))
   `(jdee-font-lock-link-face ((,class (:foreground ,blue :underline t))))
   `(jdee-font-lock-modifier-face ((,class (:foreground ,yellow))))
   `(jdee-font-lock-number-face ((,class (:foreground ,teal))))
   `(jdee-font-lock-operator-face ((,class (:foreground ,fg))))
   `(jdee-font-lock-private-face ((,class (:foreground ,cyan))))
   `(jdee-font-lock-protected-face ((,class (:foreground ,cyan))))
   `(jdee-font-lock-public-face ((,class (:foreground ,cyan))))

;;;; js2-mode
   `(js2-external-variable ((,class (:foreground ,fg))))
   `(js2-function-call ((,class (:foreground ,blue))))
   `(js2-function-param ((,class (:foreground ,red))))
   `(js2-jsdoc-tag ((,class (:foreground ,caribbean5))))
   `(js2-object-property ((,class (:foreground ,magenta))))

;;;; keycast
   `(keycast-command ((,class (:foreground ,red))))
   `(keycast-key ((,class (:foreground ,red :weight bold))))

;;;; ledger-mode
   `(ledger-font-payee-cleared-face ((,class (:foreground ,magenta :weight bold))))
   `(ledger-font-payee-uncleared-face ((,class (:foreground ,caribbean5  :weight bold))))
   `(ledger-font-posting-account-face ((,class (:foreground ,caribbean8))))
   `(ledger-font-posting-amount-face ((,class (:foreground ,yellow))))
   `(ledger-font-posting-date-face ((,class (:foreground ,blue))))
   `(ledger-font-xact-highlight-face ((,class (:background ,caribbean0))))

;;;; line numbers
   `(line-number ((,class (:foreground ,caribbean5))))
   `(line-number-current-line ((,class (:background ,bg-other :foreground ,fg))))

;;;; linum
   `(linum ((,class (:foreground ,caribbean5))))

;;;; linum-relative
   `(linum-relative-current-face ((,class (:background ,caribbean2 :foreground ,fg))))

;;;; lsp-mode
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
   `(lsp-ui-peek-selection ((,class (:foreground ,bg :background ,blue :bold bold))))
   `(lsp-ui-sideline-code-action ((,class (:foreground ,teal))))
   `(lsp-ui-sideline-current-symbol ((,class (:foreground ,teal))))
   `(lsp-ui-sideline-symbol-info ((,class (:foreground ,caribbean5 :background ,bg-other :extend t))))

;;;; lui
   `(lui-button-face ((,class (:backgroung ,bg-other :foreground ,teal :underline t))))
   `(lui-highlight-face ((,class (:backgroung ,bg-other :foreground ,teal))))
   `(lui-time-stamp-face ((,class (:backgroung ,bg-other :foreground ,magenta))))

;;;; magit
   `(magit-bisect-bad ((,class (:foreground ,red))))
   `(magit-bisect-good ((,class (:foreground ,green))))
   `(magit-bisect-skip ((,class (:foreground ,red))))
   `(magit-blame-date ((,class (:foreground ,red))))
   `(magit-blame-heading ((,class (:foreground ,cyan :background ,caribbean3 :extend t))))
   `(magit-branch-current ((,class (:foreground ,red))))
   `(magit-branch-local ((,class (:foreground ,red))))
   `(magit-branch-remote ((,class (:foreground ,green))))
   `(magit-branch-remote-head ((,class (:foreground ,green))))
   `(magit-cherry-equivalent ((,class (:foreground ,magenta))))
   `(magit-cherry-unmatched ((,class (:foreground ,darkblue))))
   `(magit-diff-added ((,class (:foreground ,bg  :background ,green :extend t))))
   `(magit-diff-added-highlight ((,class (:foreground ,bg :background ,green :weight bold :extend t))))
   `(magit-diff-base ((,class (:foreground ,cyan :background ,teal :extend t))))
   `(magit-diff-base-highlight ((,class (:foreground ,cyan :background ,teal :weight bold :extend t))))
   `(magit-diff-context ((,class (:foreground ,fg :background ,bg :extend t))))
   `(magit-diff-context-highlight ((,class (:foreground ,fg :background ,bg-other :extend t))))
   `(magit-diff-file-heading ((,class (:foreground ,fg :weight bold :extend t))))
   `(magit-diff-file-heading-selection ((,class (:foreground ,purple :background ,darkblue :weight bold :extend t))))
   `(magit-diff-hunk-heading ((,class (:foreground ,bg :background ,magenta :extend t))))
   `(magit-diff-hunk-heading-highlight ((,class (:foreground ,bg :background ,magenta :weight bold :extend t))))
   `(magit-diff-lines-heading ((,class (:foreground ,yellow :background ,red :extend t :extend t))))
   `(magit-diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
   `(magit-diff-removed-highlight ((,class (:foreground ,bg :background ,red :weight bold :extend t))))
   `(magit-diffstat-added ((,class (:foreground ,green))))
   `(magit-diffstat-removed ((,class (:foreground ,red))))
   `(magit-dimmed ((,class (:foreground ,caribbean5))))
   `(magit-filename ((,class (:foreground ,magenta))))
   `(magit-hash ((,class (:foreground ,magenta))))
   `(magit-header-line ((,class (:background ,bg-other :foreground ,darkcyan :weight bold :box (:line-width 3 :color ,bg-other)))))
   `(magit-log-author ((,class (:foreground ,cyan))))
   `(magit-log-date ((,class (:foreground ,blue))))
   `(magit-log-graph ((,class (:foreground ,caribbean5))))
   `(magit-process-ng ((,class (:foreground ,red))))
   `(magit-process-ok ((,class (:foreground ,green))))
   `(magit-reflog-amend ((,class (:foreground ,purple))))
   `(magit-reflog-checkout ((,class (:foreground ,blue))))
   `(magit-reflog-cherry-pick ((,class (:foreground ,green))))
   `(magit-reflog-commit ((,class (:foreground ,green))))
   `(magit-reflog-merge ((,class (:foreground ,green))))
   `(magit-reflog-other ((,class (:foreground ,darkblue))))
   `(magit-reflog-rebase ((,class (:foreground ,purple))))
   `(magit-reflog-remote ((,class (:foreground ,darkblue))))
   `(magit-reflog-reset ((,class (:foreground ,red))))
   `(magit-refname ((,class (:foreground ,caribbean5))))
   `(magit-section-heading ((,class (:foreground ,darkcyan :weight bold :extend t))))
   `(magit-section-heading-selection ((,class (:foreground ,cyan :weight bold :extend t))))
   `(magit-section-highlight ((,class (:background ,bg-other :extend t))))
   `(magit-section-secondary-heading ((,class (:foreground ,magenta :weight bold :extend t))))
   `(magit-sequence-drop ((,class (:foreground ,red))))
   `(magit-sequence-head ((,class (:foreground ,blue))))
   `(magit-sequence-part ((,class (:foreground ,cyan))))
   `(magit-sequence-stop ((,class (:foreground ,green))))
   `(magit-signature-bad ((,class (:foreground ,red))))
   `(magit-signature-error ((,class (:foreground ,red))))
   `(magit-signature-expired ((,class (:foreground ,cyan))))
   `(magit-signature-good ((,class (:foreground ,green))))
   `(magit-signature-revoked ((,class (:foreground ,purple))))
   `(magit-signature-untrusted ((,class (:foreground ,yellow))))
   `(magit-tag ((,class (:foreground ,yellow))))

;;;; make-mode
   `(makefile-targets ((,class (:foreground ,blue))))

;;;; marginalia
   `(marginalia-documentation ((,class (:foreground ,blue))))
   `(marginalia-file-name ((,class (:foreground ,blue))))
   `(marginalia-size ((,class (:foreground ,yellow))))
   `(marginalia-modified ((,class (:foreground ,red))))
   `(marginalia-file-priv-read ((,class (:foreground ,green))))
   `(marginalia-file-priv-write ((,class (:foreground ,yellow))))
   `(marginalia-file-priv-exec ((,class (:foreground ,red))))

;;;; markdown-mode
   `(markdown-blockquote-face ((,class (:foreground ,caribbean5 :slant italic))))
   `(markdown-bold-face ((,class (:foreground ,teal :weight bold))))
   `(markdown-code-face ((,class (:background ,bg-org :extend t))))
   `(markdown-header-delimiter-face ((,class (:foreground ,teal :weight bold))))
   `(markdown-header-face ((,class (:foreground ,teal :weight bold))))
   `(markdown-html-attr-name-face ((,class (:foreground ,teal))))
   `(markdown-html-attr-value-face ((,class (:foreground ,red))))
   `(markdown-html-entity-face ((,class (:foreground ,teal))))
   `(markdown-html-tag-delimiter-face ((,class (:foreground ,fg))))
   `(markdown-html-tag-name-face ((,class (:foreground ,cyan))))
   `(markdown-inline-code-face ((,class (:background ,bg-org :foreground ,teal))))
   `(markdown-italic-face ((,class (:foreground ,magenta :slant italic))))
   `(markdown-link-face ((,class (:foreground ,blue))))
   `(markdown-list-face ((,class (:foreground ,teal))))
   `(markdown-markup-face ((,class (:foreground ,fg))))
   `(markdown-metadata-key-face ((,class (:foreground ,teal))))
   `(markdown-pre-face ((,class (:background ,bg-org :foreground ,yellow))))
   `(markdown-reference-face ((,class (:foreground ,caribbean5))))
   `(markdown-url-face ((,class (:foreground ,magenta))))

;;;; message
   `(message-cited-text-1 ((,class (:foreground ,purple))))
   `(message-cited-text-2 ((,class (:foreground ,magenta))))
   `(message-cited-text-3 ((,class (:foreground ,darkblue))))
   `(message-cited-text-3 ((,class (:foreground ,darkcyan))))
   `(message-header-cc ((,class (:foreground ,red :weight bold))))
   `(message-header-name ((,class (:foreground ,red))))
   `(message-header-newsgroups ((,class (:foreground ,yellow))))
   `(message-header-other ((,class (:foreground ,blue))))
   `(message-header-subject ((,class (:foreground ,cyan :weight bold))))
   `(message-header-to ((,class (:foreground ,cyan :weight bold))))
   `(message-header-xheader ((,class (:foreground ,caribbean5))))
   `(message-mml ((,class (:foreground ,caribbean5 :slant italic))))
   `(message-separator ((,class (:foreground ,caribbean5))))

;;;; mic-paren
   `(paren-face-match ((,class (:foreground ,red :background ,caribbean0 :weight ultra-bold))))
   `(paren-face-mismatch ((,class (:foreground ,caribbean0 :background ,red :weight ultra-bold))))
   `(paren-face-no-match ((,class (:foreground ,caribbean0 :background ,red :weight ultra-bold))))

;;;; minimap
   `(minimap-active-region-background ((,class (:background ,bg))))
   `(minimap-current-line-face ((,class (:background ,grey))))

;;;; mmm-mode
   `(mmm-cleanup-submode-face ((,class (:background ,yellow))))
   `(mmm-code-submode-face ((,class (:background ,bg-other))))
   `(mmm-comment-submode-face ((,class (:background ,blue))))
   `(mmm-declaration-submode-face ((,class (:background ,darkblue))))
   `(mmm-default-submode-face ((,class (:background nil))))
   `(mmm-init-submode-face ((,class (:background ,red))))
   `(mmm-output-submode-face ((,class (:background ,magenta))))
   `(mmm-special-submode-face ((,class (:background ,green))))

;;;; mode-line
   `(mode-line ((,class (,@(timu-caribbean-set-mode-line-active-border caribbean4) :background ,bg-other :foreground ,fg :distant-foreground ,bg))))
   `(mode-line-buffer-id ((,class (:weight bold))))
   `(mode-line-emphasis ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(mode-line-highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
   `(mode-line-inactive ((,class (,@(timu-caribbean-set-mode-line-inactive-border caribbean2) :background ,bg-other :foreground ,caribbean3 :distant-foreground ,bg-other))))

;;;; mu4e
   `(mu4e-forwarded-face ((,class (:foreground ,darkblue))))
   `(mu4e-header-key-face ((,class (:foreground ,red))))
   `(mu4e-header-title-face ((,class (:foreground ,cyan))))
   `(mu4e-highlight-face ((,class (:foreground ,teal :weight bold))))
   `(mu4e-link-face ((,class (:foreground ,cyan))))
   `(mu4e-replied-face ((,class (:foreground ,green))))
   `(mu4e-title-face ((,class (:foreground ,teal :weight bold))))
   `(mu4e-unread-face ((,class (:foreground ,darkred :weight bold))))

;;;; mu4e-column-faces
   `(mu4e-column-faces-date ((,class (:foreground ,blue))))
   `(mu4e-column-faces-flags ((,class (:foreground ,yellow))))
   `(mu4e-column-faces-to-from ((,class (:foreground ,teal))))

;;;; mu4e-thread-folding
   `(mu4e-thread-folding-child-face ((,class (:extend t :background ,bg-org :underline nil))))
   `(mu4e-thread-folding-root-folded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))
   `(mu4e-thread-folding-root-unfolded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))

;;;; multiple cursors
   `(mc/cursor-face ((,class (:background ,cyan))))

;;;; nano-modeline
   `(nano-modeline-active-name ((,class (:foreground ,fg :weight bold))))
   `(nano-modeline-inactive-name ((,class (:foreground ,caribbean5 :weight bold))))
   `(nano-modeline-active-primary ((,class (:foreground ,fg))))
   `(nano-modeline-inactive-primary ((,class (:foreground ,caribbean5))))
   `(nano-modeline-active-secondary ((,class (:foreground ,teal :weight bold))))
   `(nano-modeline-inactive-secondary ((,class (:foreground ,caribbean5 :weight bold))))
   `(nano-modeline-active-status-RO ((,class (:background ,red :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-RO ((,class (:background ,caribbean5 :foreground ,bg :weight bold))))
   `(nano-modeline-active-status-RW ((,class (:background ,teal :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-RW ((,class (:background ,caribbean5 :foreground ,bg :weight bold))))
   `(nano-modeline-active-status-** ((,class (:background ,red :foreground ,bg :weight bold))))
   `(nano-modeline-inactive-status-** ((,class (:background ,caribbean5 :foreground ,bg :weight bold))))

;;;; nav-flash
   `(nav-flash-face ((,class (:background ,grey :foreground ,caribbean8 :weight bold))))

;;;; neotree
   `(neo-dir-link-face ((,class (:foreground ,teal))))
   `(neo-expand-btn-face ((,class (:foreground ,teal))))
   `(neo-file-link-face ((,class (:foreground ,fg))))
   `(neo-root-dir-face ((,class (:foreground ,green :background ,bg :box (:line-width 4 :color ,bg)))))
   `(neo-vc-added-face ((,class (:foreground ,green))))
   `(neo-vc-conflict-face ((,class (:foreground ,purple :weight bold))))
   `(neo-vc-edited-face ((,class (:foreground ,yellow))))
   `(neo-vc-ignored-face ((,class (:foreground ,caribbean5))))
   `(neo-vc-removed-face ((,class (:foreground ,red :strike-through t))))

;;;; nlinum
   `(nlinum-current-line ((,class (:background ,caribbean2 :foreground ,fg))))

;;;; nlinum-hl
   `(nlinum-hl-face ((,class (:background ,caribbean2 :foreground ,fg))))

;;;; nlinum-relative
   `(nlinum-relative-current-face ((,class (:background ,caribbean2 :foreground ,fg))))

;;;; notmuch
   `(notmuch-message-summary-face ((,class (:foreground ,grey :background nil))))
   `(notmuch-search-count ((,class (:foreground ,caribbean5))))
   `(notmuch-search-date ((,class (:foreground ,teal))))
   `(notmuch-search-flagged-face ((,class (:foreground ,red))))
   `(notmuch-search-matching-authors ((,class (:foreground ,blue))))
   `(notmuch-search-non-matching-authors ((,class (:foreground ,fg))))
   `(notmuch-search-subject ((,class (:foreground ,fg))))
   `(notmuch-search-unread-face ((,class (:weight bold))))
   `(notmuch-tag-added ((,class (:foreground ,green :weight normal))))
   `(notmuch-tag-deleted ((,class (:foreground ,red :weight normal))))
   `(notmuch-tag-face ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tag-flagged ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tag-unread ((,class (:foreground ,yellow :weight normal))))
   `(notmuch-tree-match-author-face ((,class (:foreground ,blue :weight bold))))
   `(notmuch-tree-match-date-face ((,class (:foreground ,teal :weight bold))))
   `(notmuch-tree-match-face ((,class (:foreground ,fg))))
   `(notmuch-tree-match-subject-face ((,class (:foreground ,fg))))
   `(notmuch-tree-match-tag-face ((,class (:foreground ,yellow))))
   `(notmuch-tree-match-tree-face ((,class (:foreground ,caribbean5))))
   `(notmuch-tree-no-match-author-face ((,class (:foreground ,blue))))
   `(notmuch-tree-no-match-date-face ((,class (:foreground ,teal))))
   `(notmuch-tree-no-match-face ((,class (:foreground ,caribbean5))))
   `(notmuch-tree-no-match-subject-face ((,class (:foreground ,caribbean5))))
   `(notmuch-tree-no-match-tag-face ((,class (:foreground ,yellow))))
   `(notmuch-tree-no-match-tree-face ((,class (:foreground ,yellow))))
   `(notmuch-wash-cited-text ((,class (:foreground ,caribbean4))))
   `(notmuch-wash-toggle-button ((,class (:foreground ,fg))))

;;;; orderless
   `(orderless-match-face-0 ((,class (:foreground ,teal :weight bold :underline t))))
   `(orderless-match-face-1 ((,class (:foreground ,cyan :weight bold :underline t))))
   `(orderless-match-face-2 ((,class (:foreground ,blue :weight bold :underline t))))
   `(orderless-match-face-3 ((,class (:foreground ,darkcyan :weight bold :underline t))))

;;;; objed
   `(objed-hl ((,class (:background ,grey :distant-foreground ,bg :extend t))))
   `(objed-mode-line ((,class (:foreground ,yellow :weight bold))))

;;;; org-agenda
   `(org-agenda-clocking ((,class (:background ,blue))))
   `(org-agenda-date ((,class (:foreground ,teal :weight ultra-bold))))
   `(org-agenda-date-today ((,class (:foreground ,teal :weight ultra-bold))))
   `(org-agenda-date-weekend ((,class (:foreground ,teal :weight ultra-bold))))
   `(org-agenda-dimmed-todo-face ((,class (:foreground ,caribbean5))))
   `(org-agenda-done ((,class (:foreground ,caribbean5))))
   `(org-agenda-structure ((,class (:foreground ,fg :weight ultra-bold))))
   `(org-scheduled ((,class (:foreground ,fg))))
   `(org-scheduled-previously ((,class (:foreground ,caribbean8))))
   `(org-scheduled-today ((,class (:foreground ,caribbean7))))
   `(org-sexp-date ((,class (:foreground ,fg))))
   `(org-time-grid ((,class (:foreground ,caribbean5))))
   `(org-upcoming-deadline ((,class (:foreground ,fg))))
   `(org-upcoming-distant-deadline ((,class (:foreground ,fg))))
   `(org-agenda-structure-filter ((,class (:foreground ,magenta :weight bold))))

;;;; org-habit
   `(org-habit-alert-face ((,class (:weight bold :background ,yellow))))
   `(org-habit-alert-future-face ((,class (:weight bold :background ,yellow))))
   `(org-habit-clear-face ((,class (:weight bold :background ,caribbean4))))
   `(org-habit-clear-future-face ((,class (:weight bold :background ,caribbean3))))
   `(org-habit-overdue-face ((,class (:weight bold :background ,red))))
   `(org-habit-overdue-future-face ((,class (:weight bold :background ,red))))
   `(org-habit-ready-face ((,class (:weight bold :background ,blue))))
   `(org-habit-ready-future-face ((,class (:weight bold :background ,blue))))

;;;; org-journal
   `(org-journal-calendar-entry-face ((,class (:foreground ,purple :slant italic))))
   `(org-journal-calendar-scheduled-face ((,class (:foreground ,red :slant italic))))
   `(org-journal-highlight ((,class (:foreground ,cyan))))

;;;; org-mode
   `(org-archived ((,class (:foreground ,caribbean5))))
   `(org-block ((,class (:foreground ,caribbean8 :background ,bg-org :extend t))))
   `(org-block-background ((,class (:background ,bg-org :extend t))))
   `(org-block-begin-line ((,class (:foreground ,caribbean5 :slant italic :background ,bg-org :extend t ,@(timu-caribbean-set-intense-org-colors bg bg-other)))))
   `(org-block-end-line ((,class (:foreground ,caribbean5 :slant italic :background ,bg-org :extend t ,@(timu-caribbean-set-intense-org-colors bg-other bg-other)))))
   `(org-checkbox ((,class (:foreground ,green :background ,bg-org :weight bold))))
   `(org-checkbox-statistics-done ((,class (:foreground ,caribbean5 :background ,bg-org :weight bold))))
   `(org-checkbox-statistics-todo ((,class (:foreground ,green :background ,bg-org :weight bold))))
   `(org-code ((,class (:foreground ,cyan ,@(timu-caribbean-set-intense-org-colors bg bg-other)))))
   `(org-date ((,class (:foreground ,yellow :background ,bg-org))))
   `(org-default ((,class (:background ,bg :foreground ,fg))))
   `(org-document-info ((,class (:foreground ,teal ,@(timu-caribbean-do-scale timu-caribbean-scale-org-document-info 1.2) ,@(timu-caribbean-set-intense-org-colors bg bg-other)))))
   `(org-document-info-keyword ((,class (:foreground ,caribbean5))))
   `(org-document-title ((,class (:foreground ,teal :weight bold ,@(timu-caribbean-do-scale timu-caribbean-scale-org-document-info 1.3) ,@(timu-caribbean-set-intense-org-colors teal bg-other)))))
   `(org-done ((,class (:foreground ,caribbean5 :weight bold))))
   `(org-ellipsis ((,class (:foreground ,grey))))
   `(org-footnote ((,class (:foreground ,cyan))))
   `(org-formula ((,class (:foreground ,darkblue))))
   `(org-headline-done ((,class (:foreground ,caribbean5))))
   `(org-hide ((,class (:foreground ,bg))))
   `(org-latex-and-related ((,class (:foreground ,caribbean8 :weight bold))))
   `(org-level-1 ((,class (:foreground ,blue :weight ultra-bold ,@(timu-caribbean-do-scale timu-caribbean-scale-org-document-info 1.3) ,@(timu-caribbean-set-intense-org-colors blue bg-other)))))
   `(org-level-2 ((,class (:foreground ,red :weight bold ,@(timu-caribbean-do-scale timu-caribbean-scale-org-document-info 1.2) ,@(timu-caribbean-set-intense-org-colors red bg-other)))))
   `(org-level-3 ((,class (:foreground ,teal :weight bold ,@(timu-caribbean-do-scale timu-caribbean-scale-org-document-info 1.1) ,@(timu-caribbean-set-intense-org-colors teal bg-other)))))
   `(org-level-4 ((,class (:foreground ,cyan ,@(timu-caribbean-set-intense-org-colors cyan bg-org)))))
   `(org-level-5 ((,class (:foreground ,green ,@(timu-caribbean-set-intense-org-colors green bg-org)))))
   `(org-level-6 ((,class (:foreground ,orange ,@(timu-caribbean-set-intense-org-colors orange bg-org)))))
   `(org-level-7 ((,class (:foreground ,purple ,@(timu-caribbean-set-intense-org-colors purple bg-org)))))
   `(org-level-8 ((,class (:foreground ,fg ,@(timu-caribbean-set-intense-org-colors fg bg-org)))))
   `(org-link ((,class (:foreground ,magenta :underline t))))
   `(org-list-dt ((,class (:foreground ,cyan))))
   `(org-meta-line ((,class (:foreground ,caribbean5))))
   `(org-priority ((,class (:foreground ,red))))
   `(org-property-value ((,class (:foreground ,caribbean5))))
   `(org-quote ((,class (:background ,caribbean3 :slant italic :extend t))))
   `(org-special-keyword ((,class (:foreground ,caribbean5))))
   `(org-table ((,class (:foreground ,red))))
   `(org-tag ((,class (:foreground ,caribbean5 :weight normal))))
   `(org-todo ((,class (:foreground ,green :weight bold))))
   `(org-verbatim ((,class (:foreground ,teal ,@(timu-caribbean-set-intense-org-colors bg bg-other)))))
   `(org-warning ((,class (:foreground ,yellow))))

;;;; org-pomodoro
   `(org-pomodoro-mode-line ((,class (:foreground ,red))))
   `(org-pomodoro-mode-line-overtime ((,class (:foreground ,yellow :weight bold))))

;;;; org-ref
   `(org-ref-acronym-face ((,class (:foreground ,magenta))))
   `(org-ref-cite-face ((,class (:foreground ,yellow :weight light :underline t))))
   `(org-ref-glossary-face ((,class (:foreground ,purple))))
   `(org-ref-label-face ((,class (:foreground ,blue))))
   `(org-ref-ref-face ((,class (:foreground ,red :underline t :weight bold))))

;;;; outline
   `(outline-1 ((,class (:foreground ,blue :weight ultra-bold ,@(timu-caribbean-do-scale timu-caribbean-scale-org-document-info 1.2)))))
   `(outline-2 ((,class (:foreground ,red :weight bold ,@(timu-caribbean-do-scale timu-caribbean-scale-org-document-info 1.2)))))
   `(outline-3 ((,class (:foreground ,teal :weight bold ,@(timu-caribbean-do-scale timu-caribbean-scale-org-document-info 1.1)))))
   `(outline-4 ((,class (:foreground ,cyan))))
   `(outline-5 ((,class (:foreground ,green))))
   `(outline-6 ((,class (:foreground ,orange))))
   `(outline-7 ((,class (:foreground ,purple))))
   `(outline-8 ((,class (:foreground ,fg))))

;;;; parenface
   `(paren-face ((,class (:foreground ,caribbean5))))

;;;; parinfer
   `(parinfer-pretty-parens:dim-paren-face ((,class (:foreground ,caribbean5))))
   `(parinfer-smart-tab:indicator-face ((,class (:foreground ,caribbean5))))

;;;; persp-mode
   `(persp-face-lighter-buffer-not-in-persp ((,class (:foreground ,caribbean5))))
   `(persp-face-lighter-default ((,class (:foreground ,red :weight bold))))
   `(persp-face-lighter-nil-persp ((,class (:foreground ,caribbean5))))

;;;; perspective
   `(persp-selected-face ((,class (:foreground ,blue :weight bold))))

;;;; pkgbuild-mode
   `(pkgbuild-error-face ((,class (:underline (:style wave :color ,red)))))

;;;; popup
   `(popup-face ((,class (:background ,bg-other :foreground ,fg))))
   `(popup-selection-face ((,class (:background ,grey))))
   `(popup-tip-face ((,class (:foreground ,magenta :background ,caribbean0))))

;;;; powerline
   `(powerline-active0 ((,class (:background ,caribbean1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-active1 ((,class (:background ,caribbean1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-active2 ((,class (:background ,caribbean1 :foreground ,fg :distant-foreground ,bg))))
   `(powerline-inactive0 ((,class (:background ,caribbean2 :foreground ,caribbean5 :distant-foreground ,bg-other))))
   `(powerline-inactive1 ((,class (:background ,caribbean2 :foreground ,caribbean5 :distant-foreground ,bg-other))))
   `(powerline-inactive2 ((,class (:background ,caribbean2 :foreground ,caribbean5 :distant-foreground ,bg-other))))

;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((,class (:foreground ,blue))))
   `(rainbow-delimiters-depth-2-face ((,class (:foreground ,purple))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground ,green))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground ,red))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground ,magenta))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground ,yellow))))
   `(rainbow-delimiters-depth-7-face ((,class (:foreground ,orange))))
   `(rainbow-delimiters-mismatched-face ((,class (:foreground ,magenta :weight bold :inverse-video t))))
   `(rainbow-delimiters-unmatched-face ((,class (:foreground ,magenta :weight bold :inverse-video t))))

;;;; re-builder
   `(reb-match-0 ((,class (:foreground ,red :inverse-video t))))
   `(reb-match-1 ((,class (:foreground ,purple :inverse-video t))))
   `(reb-match-2 ((,class (:foreground ,green :inverse-video t))))
   `(reb-match-3 ((,class (:foreground ,yellow :inverse-video t))))

;;;; rjsx-mode
   `(rjsx-attr ((,class (:foreground ,blue))))
   `(rjsx-tag ((,class (:foreground ,yellow))))

;;;; rpm-spec-mode
   `(rpm-spec-dir-face ((,class (:foreground ,green))))
   `(rpm-spec-doc-face ((,class (:foreground ,teal))))
   `(rpm-spec-ghost-face ((,class (:foreground ,caribbean5))))
   `(rpm-spec-macro-face ((,class (:foreground ,yellow))))
   `(rpm-spec-obsolete-tag-face ((,class (:foreground ,red))))
   `(rpm-spec-package-face ((,class (:foreground ,teal))))
   `(rpm-spec-section-face ((,class (:foreground ,purple))))
   `(rpm-spec-tag-face ((,class (:foreground ,blue))))
   `(rpm-spec-var-face ((,class (:foreground ,magenta))))

;;;; rst
   `(rst-block ((,class (:foreground ,red))))
   `(rst-level-1 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-2 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-3 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-4 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-5 ((,class (:foreground ,magenta :weight bold))))
   `(rst-level-6 ((,class (:foreground ,magenta :weight bold))))

;;;; selectrum
   `(selectrum-current-candidate ((,class (:background ,grey :distant-foreground nil :extend t))))

;;;; sh-script
   `(sh-heredoc ((,class (:foreground ,teal))))
   `(sh-quoted-exec ((,class (:foreground ,fg :weight bold))))

;;;; show-paren
   `(show-paren-match ((,class (:foreground ,magenta :weight ultra-bold :underline ,magenta))))
   `(show-paren-mismatch ((,class (:foreground ,bg :background ,magenta :weight ultra-bold))))

;;;; smart-mode-line
   `(sml/charging ((,class (:foreground ,green))))
   `(sml/discharging ((,class (:foreground ,yellow :weight bold))))
   `(sml/filename ((,class (:foreground ,magenta :weight bold))))
   `(sml/git ((,class (:foreground ,blue))))
   `(sml/modified ((,class (:foreground ,darkblue))))
   `(sml/outside-modified ((,class (:foreground ,darkblue))))
   `(sml/process ((,class (:weight bold))))
   `(sml/read-only ((,class (:foreground ,darkblue))))
   `(sml/sudo ((,class (:foreground ,red :weight bold))))
   `(sml/vc-edited ((,class (:foreground ,green))))

;;;; smartparens
   `(sp-pair-overlay-face ((,class (:background ,grey))))
   `(sp-show-pair-match-face ((,class (:foreground ,red :background ,caribbean0 :weight ultra-bold))))
   `(sp-show-pair-mismatch-face ((,class (:foreground ,caribbean0 :background ,red :weight ultra-bold))))

;;;; smerge-tool
   `(smerge-base ((,class (:background ,blue :foreground ,bg))))
   `(smerge-lower ((,class (:background ,green))))
   `(smerge-markers ((,class (:background ,caribbean5 :foreground ,bg :distant-foreground ,fg :weight bold))))
   `(smerge-mine ((,class (:background ,red :foreground ,bg))))
   `(smerge-other ((,class (:background ,green :foreground ,bg))))
   `(smerge-refined-added ((,class (:background ,green :foreground ,bg))))
   `(smerge-refined-removed ((,class (:background ,red :foreground ,bg))))
   `(smerge-upper ((,class (:background ,red))))

;;;; solaire-mode
   `(solaire-default-face ((,class (:background ,bg-other))))
   `(solaire-hl-line-face ((,class (:background ,bg-other :extend t))))
   `(solaire-mode-line-face ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))
   `(solaire-mode-line-inactive-face ((,class (:background ,bg-other :foreground ,fg-other :distant-foreground ,bg-other))))
   `(solaire-org-hide-face ((,class (:foreground ,bg))))

;;;; spaceline
   `(spaceline-evil-emacs ((,class (:background ,darkblue))))
   `(spaceline-evil-insert ((,class (:background ,green))))
   `(spaceline-evil-motion ((,class (:background ,purple))))
   `(spaceline-evil-normal ((,class (:background ,blue))))
   `(spaceline-evil-replace ((,class (:background ,red))))
   `(spaceline-evil-visual ((,class (:background ,grey))))
   `(spaceline-flycheck-error ((,class (:foreground ,red :distant-background ,caribbean0))))
   `(spaceline-flycheck-info ((,class (:foreground ,green :distant-background ,caribbean0))))
   `(spaceline-flycheck-warning ((,class (:foreground ,yellow :distant-background ,caribbean0))))
   `(spaceline-highlight-face ((,class (:background ,red))))
   `(spaceline-modified ((,class (:background ,red))))
   `(spaceline-python-venv ((,class (:foreground ,purple :distant-foreground ,magenta))))
   `(spaceline-unmodified ((,class (:background ,red))))

;;;; stripe-buffer
   `(stripe-highlight ((,class (:background ,caribbean3))))

;;;; swiper
   `(swiper-line-face ((,class (:background ,blue :foreground ,caribbean0))))
   `(swiper-match-face-1 ((,class (:background ,caribbean0 :foreground ,caribbean5))))
   `(swiper-match-face-2 ((,class (:background ,teal :foreground ,caribbean0 :weight bold))))
   `(swiper-match-face-3 ((,class (:background ,purple :foreground ,caribbean0 :weight bold))))
   `(swiper-match-face-4 ((,class (:background ,green :foreground ,caribbean0 :weight bold))))

;;;; tabbar
   `(tabbar-button ((,class (:foreground ,fg :background ,bg))))
   `(tabbar-button-highlight ((,class (:foreground ,fg :background ,bg :inverse-video t))))
   `(tabbar-default ((,class (:foreground ,bg :background ,bg :height 1.0))))
   `(tabbar-highlight ((,class (:foreground ,fg :background ,grey :distant-foreground ,bg))))
   `(tabbar-modified ((,class (:foreground ,red :weight bold))))
   `(tabbar-selected ((,class (:foreground ,fg :background ,bg-other :weight bold))))
   `(tabbar-selected-modified ((,class (:foreground ,green :background ,bg-other :weight bold))))
   `(tabbar-unselected ((,class (:foreground ,caribbean5))))
   `(tabbar-unselected-modified ((,class (:foreground ,red :weight bold))))

;;;; tab-bar
   `(tab-bar ((,class (:background ,bg-other :foreground ,bg-other))))
   `(tab-bar-tab ((,class (:background ,bg :foreground ,fg))))
   `(tab-bar-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; tab-line
   `(tab-line ((,class (:background ,bg-other :foreground ,bg-other))))
   `(tab-line-close-highlight ((,class (:foreground ,red))))
   `(tab-line-highlight ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab-current ((,class (:background ,bg :foreground ,fg))))
   `(tab-line-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; telephone-line
   `(telephone-line-accent-active ((,class (:foreground ,fg :background ,caribbean4))))
   `(telephone-line-accent-inactive ((,class (:foreground ,fg :background ,caribbean2))))
   `(telephone-line-evil ((,class (:foreground ,fg :weight bold))))
   `(telephone-line-evil-emacs ((,class (:background ,purple :weight bold))))
   `(telephone-line-evil-insert ((,class (:background ,green :weight bold))))
   `(telephone-line-evil-motion ((,class (:background ,blue :weight bold))))
   `(telephone-line-evil-normal ((,class (:background ,red :weight bold))))
   `(telephone-line-evil-operator ((,class (:background ,magenta :weight bold))))
   `(telephone-line-evil-replace ((,class (:background ,bg-other :weight bold))))
   `(telephone-line-evil-visual ((,class (:background ,red :weight bold))))
   `(telephone-line-projectile ((,class (:foreground ,green))))

;;;; term
   `(term ((,class (:foreground ,fg))))
   `(term-bold ((,class (:weight bold))))
   `(term-color-black ((,class (:background ,caribbean0 :foreground ,caribbean0))))
   `(term-color-blue ((,class (:background ,blue :foreground ,blue))))
   `(term-color-cyan ((,class (:background ,darkblue :foreground ,darkblue))))
   `(term-color-green ((,class (:background ,green :foreground ,green))))
   `(term-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
   `(term-color-purple ((,class (:background ,purple :foreground ,purple))))
   `(term-color-red ((,class (:background ,red :foreground ,red))))
   `(term-color-white ((,class (:background ,caribbean8 :foreground ,caribbean8))))
   `(term-color-yellow ((,class (:background ,yellow :foreground ,yellow))))
   `(term-color-bright-black ((,class (:foreground ,caribbean0))))
   `(term-color-bright-blue ((,class (:foreground ,blue))))
   `(term-color-bright-cyan ((,class (:foreground ,darkblue))))
   `(term-color-bright-green ((,class (:foreground ,green))))
   `(term-color-bright-magenta ((,class (:foreground ,magenta))))
   `(term-color-bright-purple ((,class (:foreground ,purple))))
   `(term-color-bright-red ((,class (:foreground ,red))))
   `(term-color-bright-white ((,class (:foreground ,caribbean8))))
   `(term-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; tldr
   `(tldr-code-block ((,class (:foreground ,green :weight bold))))
   `(tldr-command-argument ((,class (:foreground ,fg))))
   `(tldr-command-itself ((,class (:foreground ,green :weight bold))))
   `(tldr-description ((,class (:foreground ,caribbean4))))
   `(tldr-introduction ((,class (:foreground ,teal))))
   `(tldr-title ((,class (:foreground ,darkred :weight bold :height 1.4))))

;;;; transient
   `(transient-key ((,class (:foreground ,darkred :height 1.1))))
   `(transient-blue ((,class (:foreground ,blue))))
   `(transient-pink ((,class (:foreground ,magenta))))
   `(transient-purple ((,class (:foreground ,purple))))
   `(transient-red ((,class (:foreground ,red))))
   `(transient-teal ((,class (:foreground ,teal))))

;;;; treemacs
   `(treemacs-directory-face ((,class (:foreground ,fg))))
   `(treemacs-file-face ((,class (:foreground ,fg))))
   `(treemacs-git-added-face ((,class (:foreground ,green))))
   `(treemacs-git-conflict-face ((,class (:foreground ,red))))
   `(treemacs-git-modified-face ((,class (:foreground ,magenta))))
   `(treemacs-git-untracked-face ((,class (:foreground ,caribbean5))))
   `(treemacs-root-face ((,class (:foreground ,teal :weight bold :height 1.2))))
   `(treemacs-tags-face ((,class (:foreground ,red))))

;;;; treemacs-all-the-icons
     `(treemacs-all-the-icons-file-face ((,class (:foreground ,blue))))
     `(treemacs-all-the-icons-root-face ((,class (:foreground ,fg))))

;;;; tree-sitter-hl
   `(tree-sitter-hl-face:function ((,class (:foreground ,lightcyan))))
   `(tree-sitter-hl-face:function.call ((,class (:foreground ,lightcyan))))
   `(tree-sitter-hl-face:function.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:function.special ((,class (:foreground ,fg :weight bold))))
   `(tree-sitter-hl-face:function.macro ((,class (:foreground ,fg :weight bold))))
   `(tree-sitter-hl-face:method ((,class (:foreground ,lightcyan))))
   `(tree-sitter-hl-face:method.call ((,class (:foreground ,lightcyan))))
   `(tree-sitter-hl-face:type ((,class (:foreground ,teal))))
   `(tree-sitter-hl-face:type.parameter ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:type.argument ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:type.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:type.super ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:constructor ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:variable ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:variable.parameter ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:variable.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:variable.special ((,class (:foreground ,magenta))))
   `(tree-sitter-hl-face:property ((,class (:foreground ,teal))))
   `(tree-sitter-hl-face:property.definition ((,class (:foreground ,darkcyan))))
   `(tree-sitter-hl-face:comment ((,class (:foreground ,caribbean4 :slant italic))))
   `(tree-sitter-hl-face:doc ((,class (:foreground ,yellow :slant italic))))
   `(tree-sitter-hl-face:string ((,class (:foreground ,cyan))))
   `(tree-sitter-hl-face:string.special ((,class (:foreground ,cyan :weight bold))))
   `(tree-sitter-hl-face:escape ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:embedded ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:keyword ((,class (:foreground ,teal))))
   `(tree-sitter-hl-face:operator ((,class (:foreground ,green))))
   `(tree-sitter-hl-face:label ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:constant ((,class (:foreground ,teal))))
   `(tree-sitter-hl-face:constant.builtin ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:number ((,class (:foreground ,green))))
   `(tree-sitter-hl-face:punctuation ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.bracket ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.delimiter ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:punctuation.special ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:tag ((,class (:foreground ,red))))
   `(tree-sitter-hl-face:attribute ((,class (:foreground ,fg))))

;;;; typescript-mode
   `(typescript-jsdoc-tag ((,class (:foreground ,caribbean5))))
   `(typescript-jsdoc-type ((,class (:foreground ,caribbean5))))
   `(typescript-jsdoc-value ((,class (:foreground ,caribbean5))))

;;;; undo-tree
   `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,blue))))
   `(undo-tree-visualizer-current-face ((,class (:foreground ,green :weight bold))))
   `(undo-tree-visualizer-default-face ((,class (:foreground ,caribbean5))))
   `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow))))
   `(undo-tree-visualizer-unmodified-face ((,class (:foreground ,caribbean5))))

;;;; vimish-fold
   `(vimish-fold-fringe ((,class (:foreground ,purple))))
   `(vimish-fold-overlay ((,class (:foreground ,caribbean5 :background ,caribbean0 :weight light))))

;;;; volatile-highlights
   `(vhl/default-face ((,class (:background ,grey))))

;;;; vterm
   `(vterm ((,class (:foreground ,fg))))
   `(vterm-color-black ((,class (:background ,caribbean0 :foreground ,caribbean0))))
   `(vterm-color-blue ((,class (:background ,blue :foreground ,blue))))
   `(vterm-color-cyan ((,class (:background ,darkblue :foreground ,darkblue))))
   `(vterm-color-default ((,class (:foreground ,fg))))
   `(vterm-color-green ((,class (:background ,green :foreground ,green))))
   `(vterm-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
   `(vterm-color-purple ((,class (:background ,purple :foreground ,purple))))
   `(vterm-color-red ((,class (:background ,red :foreground ,red))))
   `(vterm-color-white ((,class (:background ,caribbean8 :foreground ,caribbean8))))
   `(vterm-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

;;;; web-mode
   `(web-mode-block-control-face ((,class (:foreground ,red))))
   `(web-mode-block-control-face ((,class (:foreground ,red))))
   `(web-mode-block-delimiter-face ((,class (:foreground ,red))))
   `(web-mode-css-property-name-face ((,class (:foreground ,yellow))))
   `(web-mode-doctype-face ((,class (:foreground ,caribbean5))))
   `(web-mode-html-attr-name-face ((,class (:foreground ,blue))))
   `(web-mode-html-attr-value-face ((,class (:foreground ,yellow))))
   `(web-mode-html-entity-face ((,class (:foreground ,darkblue :slant italic))))
   `(web-mode-html-tag-bracket-face ((,class (:foreground ,blue))))
   `(web-mode-html-tag-bracket-face ((,class (:foreground ,fg))))
   `(web-mode-html-tag-face ((,class (:foreground ,teal))))
   `(web-mode-json-context-face ((,class (:foreground ,green))))
   `(web-mode-json-key-face ((,class (:foreground ,green))))
   `(web-mode-keyword-face ((,class (:foreground ,magenta))))
   `(web-mode-string-face ((,class (:foreground ,green))))
   `(web-mode-type-face ((,class (:foreground ,yellow))))

;;;; wgrep
   `(wgrep-delete-face ((,class (:foreground ,caribbean3 :background ,red))))
   `(wgrep-done-face ((,class (:foreground ,blue))))
   `(wgrep-face ((,class (:weight bold :foreground ,green :background ,caribbean5))))
   `(wgrep-file-face ((,class (:foreground ,caribbean5))))
   `(wgrep-reject-face ((,class (:foreground ,red :weight bold))))

;;;; which-func
   `(which-func ((,class (:foreground ,blue))))

;;;; which-key
   `(which-key-command-description-face ((,class (:foreground ,blue))))
   `(which-key-group-description-face ((,class (:foreground ,teal))))
   `(which-key-key-face ((,class (:foreground ,darkred :height 1.1))))
   `(which-key-local-map-description-face ((,class (:foreground ,purple))))

;;;; whitespace
   `(whitespace-empty ((,class (:background ,caribbean3))))
   `(whitespace-indentation ((,class (:foreground ,caribbean4 :background ,caribbean3))))
   `(whitespace-line ((,class (:background ,caribbean0 :foreground ,red :weight bold))))
   `(whitespace-newline ((,class (:foreground ,caribbean4))))
   `(whitespace-space ((,class (:foreground ,caribbean4))))
   `(whitespace-tab ((,class (:foreground ,caribbean4 :background ,caribbean3))))
   `(whitespace-trailing ((,class (:background ,red))))

;;;; widget
   `(widget-button ((,class (:foreground ,fg :weight bold))))
   `(widget-button-pressed ((,class (:foreground ,red))))
   `(widget-documentation ((,class (:foreground ,green))))
   `(widget-field ((,class (:foreground ,fg :background ,caribbean0 :extend nil))))
   `(widget-inactive ((,class (:foreground ,grey :background ,bg-other))))
   `(widget-single-line-field ((,class (:foreground ,fg :background ,caribbean0))))

;;;; window-divider
   `(window-divider ((,class (:background ,red :foreground ,red))))
   `(window-divider-first-pixel ((,class (:background ,red :foreground ,red))))
   `(window-divider-last-pixel ((,class (:background ,red :foreground ,red))))

;;;; woman
   `(woman-bold ((,class (:foreground ,fg :weight bold))))
   `(woman-italic ((,class (:foreground ,magenta :underline ,magenta))))

;;;; workgroups2
   `(wg-brace-face ((,class (:foreground ,red))))
   `(wg-current-workgroup-face ((,class (:foreground ,caribbean0 :background ,red))))
   `(wg-divider-face ((,class (:foreground ,grey))))
   `(wg-other-workgroup-face ((,class (:foreground ,caribbean5))))

;;;; yasnippet
   `(yas-field-highlight-face ((,class (:foreground ,green :background ,caribbean0 :weight bold))))

;;;; ytel
   `(ytel-video-published-face ((,class (:foreground ,blue))))
   `(ytel-channel-name-face ((,class (:foreground ,red))))
   `(ytel-video-length-face ((,class (:foreground ,cyan))))
   `(ytel-video-view-face ((,class (:foreground ,darkblue))))

   (custom-theme-set-variables
    'timu-caribbean
    `(ansi-color-names-vector [bg, red, green, teal, cyan, blue, yellow, fg]))))


;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory
                (file-name-directory load-file-name))))

(provide-theme 'timu-caribbean)

;;; timu-caribbean-theme.el ends here
