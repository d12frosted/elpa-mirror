;;; timu-spacegrey-theme.el --- Color theme inspired by the Spacegray theme in Sublime Text  -*- lexical-binding:t -*-

;; Copyright (C) 2021 Aimé Bertrand

;; Author: Aimé Bertrand <aime.bertrand@macowners.club>
;; Maintainer: Aimé Bertrand <aime.bertrand@macowners.club>
;; Created: 06 Jun 2021
;; Keywords: faces themes
;; Package-Version: 20230102.59
;; Package-Commit: 0d0d977c2149f695de0e4de55ae64a672c34bfac
;; Version: 2.6
;; Package-Requires: ((emacs "26.1"))
;; Homepage: https://gitlab.com/aimebertrand/timu-spacegrey-theme

;; This file is not part of GNU Emacs.

;; The MIT License (MIT)
;;
;; Copyright (C) 2021 Aimé Bertrand
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
;;     1. Download the `timu-spacegrey-theme.el' file and add it to your `custom-load-path'.
;;     2. In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (load-theme 'timu-spacegrey t)
;;
;;   B. From Melpa
;;     1. M-x package-install RET timu-spacegrey-theme RET.
;;     2. In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (load-theme 'timu-spacegrey t)
;;
;;   C. With use-package
;;     In your `~/.emacs.d/init.el' or `~/.emacs':
;;       (use-package timu-spacegrey-theme
;;         :ensure t
;;         :config
;;         (load-theme 'timu-spacegrey t))
;;
;; II. Configuration
;;   A. Dark and light flavour
;;     By default the theme is `dark', to setup the `light' flavour:
;;
;;     - Change the variable `timu-spacegrey-flavour' in the Customization Interface.
;;       M-x customize RET. Then Search for `timu'.
;;
;;     or
;;
;;     - add the following to your `~/.emacs.d/init.el' or `~/.emacs'
;;       (setq timu-spacegrey-flavour "light")
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
;;         (customize-set-variable 'timu-spacegrey-scale-org-document-title t)
;;         (customize-set-variable 'timu-spacegrey-scale-org-document-info t)
;;         (customize-set-variable 'timu-spacegrey-scale-org-level-1 t)
;;         (customize-set-variable 'timu-spacegrey-scale-org-level-2 t)
;;         (customize-set-variable 'timu-spacegrey-scale-org-level-3 t)
;;
;;     2. Custom scaling
;;       You can choose your own scaling values as well.
;;       The following is a somewhat exaggerated example.
;;
;;         (customize-set-variable 'timu-spacegrey-scale-org-document-title 1.8)
;;         (customize-set-variable 'timu-spacegrey-scale-org-document-info 1.4)
;;         (customize-set-variable 'timu-spacegrey-scale-org-level-1 1.8)
;;         (customize-set-variable 'timu-spacegrey-scale-org-level-2 1.4)
;;         (customize-set-variable 'timu-spacegrey-scale-org-level-3 1.2)
;;
;;   C. "Intense" colors for `org-mode'
;;     To emphasize some elements in org-mode.
;;     You can set a variable to make some faces more "intense".
;;
;;     By default the intense colors are turned off.
;;     To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
;;       (customize-set-variable 'timu-spacegrey-org-intense-colors t)
;;
;;   D. Muted colors for the dark flavour
;;     You can set muted colors for the dark flavour of the theme.
;;
;;     By default muted colors are turned off.
;;     To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
;;       (customize-set-variable 'timu-spacegrey-muted-colors t)
;;
;;   E. Border for the `mode-line'
;;     You can set a variable to add a border to the mode-line.
;;
;;     By default the border is turned off.
;;     To turn this on add the following to your =~/.emacs.d/init.el= or =~/.emacs=:
;;       (customize-set-variable 'timu-spacegrey-mode-line-border t)
;;
;; III. Utility functions
;;   A. Toggle dark and light flavour of the theme
;;       M-x timu-spacegrey-toggle-dark-light RET.
;;
;;   B. Toggle between intense and non intense colors for `org-mode'
;;       M-x timu-spacegrey-toggle-org-colors-intensity RET.
;;
;;   C. Toggle between borders and no borders for the `mode-line'
;;       M-x timu-spacegrey-toggle-mode-line-border RET.


;;; Code:

(defgroup timu-spacegrey-theme ()
  "Customise group for the \"Timu Spacegrey\" theme."
  :group 'faces
  :prefix "timu-spacegrey-")

(defface timu-spacegrey-default-face
  '((t nil))
  "Custom basic default `timu-spacegrey-theme' face."
  :group 'timu-spacegrey-theme)

(defface timu-spacegrey-bold-face
  '((t :weight bold))
  "Custom basic bold `timu-spacegrey-theme' face."
  :group 'timu-spacegrey-theme)

(defface timu-spacegrey-bold-face-italic
  '((t :weight bold :slant italic))
  "Custom basic bold-italic `timu-spacegrey-theme' face."
  :group 'timu-spacegrey-theme)

(defface timu-spacegrey-italic-face
  '((((supports :slant italic)) :slant italic)
    (t :slant italic))
  "Custom basic italic `timu-spacegrey-theme' face."
  :group 'timu-spacegrey-theme)

(defface timu-spacegrey-underline-face
  '((((supports :underline t)) :underline t)
    (t :underline t))
  "Custom basic underlined `timu-spacegrey-theme' face."
  :group 'timu-spacegrey-theme)

(defface timu-spacegrey-strike-through-face
  '((((supports :strike-through t)) :strike-through t)
    (t :strike-through t))
  "Custom basic strike-through `timu-spacegrey-theme' face."
  :group 'timu-spacegrey-theme)

(defcustom timu-spacegrey-flavour "dark"
  "Variable to control the variant of the theme.
Possible values: `dark' or `light'."
  :type 'string
  :group 'timu-spacegrey-theme)

(defcustom timu-spacegrey-scale-org-document-info nil
  "Variable to control the scale of the `org-document-info' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-spacegrey-theme)

(defcustom timu-spacegrey-scale-org-document-title nil
  "Variable to control the scale of the `org-document-title' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-spacegrey-theme)

(defcustom timu-spacegrey-scale-org-level-1 nil
  "Variable to control the scale of the `org-level-1' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-spacegrey-theme)

(defcustom timu-spacegrey-scale-org-level-2 nil
  "Variable to control the scale of the `org-level-2' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-spacegrey-theme)

(defcustom timu-spacegrey-scale-org-level-3 nil
  "Variable to control the scale of the `org-level-3' faces.
Possible values: t, number or nil. When t, use theme default height."
  :type '(choice
          (const :tag "No scaling" nil)
          (const :tag "Theme default scaling" t)
          (number :tag "Your custom scaling"))
  :group 'timu-spacegrey-theme)

(defun timu-spacegrey-do-scale (custom-height default-height)
  "Function for scaling the face to the DEFAULT-HEIGHT or CUSTOM-HEIGHT.
Uses `timu-spacegrey-scale-faces' for the value of CUSTOM-HEIGHT."
  (cond
   ((numberp custom-height) (list :height custom-height))
   ((eq t custom-height) (list :height default-height))
   ((eq nil custom-height) (list :height 1.0))
   (t nil)))

(defcustom timu-spacegrey-org-intense-colors nil
  "Variable to control \"intensity\" of `org-mode' header colors."
  :type 'boolean
  :group 'timu-spacegrey-theme)

(defun timu-spacegrey-set-intense-org-colors (overline-color background-color)
  "Function Adding intense colors to `org-mode'.
OVERLINE-COLOR changes the `overline' color.
BACKGROUND-COLOR changes the `background' color."
  (if (eq t timu-spacegrey-org-intense-colors)
      (list :overline overline-color :background background-color)))

(defcustom timu-spacegrey-muted-colors nil
  "Variable to set muted colors for the \"dark\" flavour of the theme."
  :type 'boolean
  :group 'timu-spacegrey-theme)

(defcustom timu-spacegrey-mode-line-border nil
  "Variable to control the border of `mode-line'.
With a value of t the mode-line has a border."
  :type 'boolean
  :group 'timu-spacegrey-theme)

(defun timu-spacegrey-set-mode-line-active-border (dbox lbox)
  "Function adding a border to the `mode-line' of the active window.
DBOX supplies the border color of the dark `timu-spacegrey-flavour'.
LBOX supplies the border color of the light `timu-spacegrey-flavour'."
  (if (eq t timu-spacegrey-mode-line-border)
      (if (equal "dark" timu-spacegrey-flavour)
          (list :box dbox)
        (list :box lbox))))

(defun timu-spacegrey-set-mode-line-inactive-border (dbox lbox)
  "Function adding a border to the `mode-line' of the inactive window.
DBOX supplies the border color of the dark `timu-spacegrey-flavour'.
LBOX supplies the border color of the light `timu-spacegrey-flavour'."
  (if (eq t timu-spacegrey-mode-line-border)
      (if (equal "dark" timu-spacegrey-flavour)
          (list :box dbox)
        (list :box lbox))))

;;;###autoload
(defun timu-spacegrey-toggle-dark-light ()
  "Toggle between \"dark\" and \"light\" `timu-spacegrey-flavour'."
  (interactive)
  (if (equal "dark" timu-spacegrey-flavour)
      (customize-set-variable 'timu-spacegrey-flavour "light")
    (customize-set-variable 'timu-spacegrey-flavour "dark"))
  (load-theme (car custom-enabled-themes) t))

;;;###autoload
(defun timu-spacegrey-toggle-org-colors-intensity ()
  "Toggle between intense and non intense colors for `org-mode'.
Customize `timu-spacegrey-org-intense-colors' the to achieve this. "
  (interactive)
  (if (eq t timu-spacegrey-org-intense-colors)
      (customize-set-variable 'timu-spacegrey-org-intense-colors nil)
    (customize-set-variable 'timu-spacegrey-org-intense-colors t))
  (load-theme (car custom-enabled-themes) t))

;;;###autoload
(defun timu-spacegrey-toggle-mode-line-border ()
  "Toggle between borders and no borders for the `mode-line'.
Customize `timu-spacegrey-mode-line-border' the to achieve this. "
  (interactive)
  (if (eq t timu-spacegrey-mode-line-border)
      (customize-set-variable 'timu-spacegrey-mode-line-border nil)
    (customize-set-variable 'timu-spacegrey-mode-line-border t))
  (load-theme (car custom-enabled-themes) t))

(deftheme timu-spacegrey
  "Custom theme inspired by the spacegray theme in Sublime Text.
Sourced other themes to get information about font faces for packages.")

;;; DARK FLAVOUR
(when (equal timu-spacegrey-flavour "dark")
  (let ((class '((class color) (min-colors 89)))
        (bg          "#2b303b")
        (bg-org      "#282d37")
        (bg-other    "#232830")
        (spacegrey0  "#1b2229")
        (spacegrey1  "#1c1f24")
        (spacegrey2  "#202328")
        (spacegrey3  "#2f3237")
        (spacegrey4  "#4f5b66")
        (spacegrey5  "#65737e")
        (spacegrey6  "#73797e")
        (spacegrey7  "#9ca0a4")
        (spacegrey8  "#dfdfdf")
        (fg          "#c0c5ce")
        (fg-other    "#c0c5ce")

        (grey      (if timu-spacegrey-muted-colors "#95a1ac" "#4f5b66"))
        (red       (if timu-spacegrey-muted-colors "#ffa7b0" "#bf616a"))
        (orange    (if timu-spacegrey-muted-colors "#ffcdb6" "#d08770"))
        (green     (if timu-spacegrey-muted-colors "#e9ffd2" "#a3be8c"))
        (blue      (if timu-spacegrey-muted-colors "#d5e7f9" "#8fa1b3"))
        (magenta   (if timu-spacegrey-muted-colors "#fad4f3" "#b48ead"))
        (teal      (if timu-spacegrey-muted-colors "#93fbff" "#4db5bd"))
        (yellow    (if timu-spacegrey-muted-colors "#ffffc1" "#ecbe7b"))
        (darkblue  (if timu-spacegrey-muted-colors "#689de6" "#2257a0"))
        (purple    (if timu-spacegrey-muted-colors "#ffbeff" "#c678dd"))
        (cyan      (if timu-spacegrey-muted-colors "#8cffff" "#46d9ff"))
        (lightcyan (if timu-spacegrey-muted-colors "#ceffff" "#88c0d0"))
        (darkcyan  (if timu-spacegrey-muted-colors "#9cdff5" "#5699af"))

        (black       "#000000")
        (white       "#ffffff"))

    (custom-theme-set-faces
     'timu-spacegrey

;;; Custom faces - dark

;;;; timu-spacegrey-faces - dark
     `(timu-spacegrey-default-face ((,class (:background ,bg :foreground ,fg))))
     `(timu-spacegrey-bold-face ((,class (:weight bold :foreground ,spacegrey8))))
     `(timu-spacegrey-bold-face-italic ((,class (:weight bold :slant italic :foreground ,spacegrey8))))
     `(timu-spacegrey-italic-face ((,class (:slant italic :foreground ,white))))
     `(timu-spacegrey-underline-face ((,class (:underline ,yellow))))
     `(timu-spacegrey-strike-through-face ((,class (:strike-through ,yellow))))

;;;; default faces - dark
     `(bold ((,class (:weight bold))))
     `(bold-italic ((,class (:weight bold :slant italic))))
     `(bookmark-face ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
     `(cursor ((,class (:background ,orange))))
     `(default ((,class (:background ,bg :foreground ,fg))))
     `(error ((,class (:foreground ,red))))
     `(fringe ((,class (:background ,bg :foreground ,spacegrey4))))
     `(highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
     `(italic ((,class (:slant  italic))))
     `(lazy-highlight ((,class (:background ,darkblue  :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(link ((,class (:foreground ,orange :underline t :weight bold))))
     `(match ((,class (:foreground ,green :background ,spacegrey0 :weight bold))))
     `(minibuffer-prompt ((,class (:foreground ,orange))))
     `(nobreak-space ((,class (:background ,bg :foreground ,fg :underline nil))))
     `(region ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
     `(secondary-selection ((,class (:background ,grey :extend t))))
     `(shadow ((,class (:foreground ,spacegrey5))))
     `(success ((,class (:foreground ,green))))
     `(tooltip ((,class (:background ,bg-other :foreground ,fg))))
     `(trailing-whitespace ((,class (:background ,red))))
     `(vertical-border ((,class (:background ,spacegrey4 :foreground ,spacegrey4))))
     `(warning ((,class (:foreground ,yellow))))

;;;; font-lock - dark
     `(font-lock-builtin-face ((,class (:foreground ,orange))))
     `(font-lock-comment-delimiter-face ((,class (:foreground ,spacegrey5))))
     `(font-lock-comment-face ((,class (:foreground ,spacegrey5 :slant italic))))
     `(font-lock-constant-face ((,class (:foreground ,magenta))))
     `(font-lock-doc-face ((,class (:foreground ,spacegrey5 :slant italic))))
     `(font-lock-function-name-face ((,class (:foreground ,blue))))
     `(font-lock-keyword-face ((,class (:foreground ,orange))))
     `(font-lock-negation-char-face ((,class (:foreground ,fg :weight bold))))
     `(font-lock-preprocessor-char-face ((,class (:foreground ,fg :weight bold))))
     `(font-lock-preprocessor-face ((,class (:foreground ,fg :weight bold))))
     `(font-lock-regexp-grouping-backslash ((,class (:foreground ,fg :weight bold))))
     `(font-lock-regexp-grouping-construct ((,class (:foreground ,fg :weight bold))))
     `(font-lock-string-face ((,class (:foreground ,green))))
     `(font-lock-type-face ((,class (:foreground ,yellow))))
     `(font-lock-variable-name-face ((,class (:foreground ,red))))
     `(font-lock-warning-face ((,class (:foreground ,yellow))))

;;;; ace-window - dark
     `(aw-leading-char-face ((,class (:foreground ,orange :height 500 :weight bold))))
     `(aw-background-face ((,class (:foreground ,spacegrey5))))

;;;; agda-mode - dark
     `(agda2-highlight-bound-variable-face ((,class (:foreground ,red))))
     `(agda2-highlight-coinductive-constructor-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-datatype-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-dotted-face ((,class (:foreground ,red))))
     `(agda2-highlight-error-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-field-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-function-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-incomplete-pattern-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-inductive-constructor-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-keyword-face ((,class (:foreground ,magenta))))
     `(agda2-highlight-macro-face ((,class (:foreground ,blue))))
     `(agda2-highlight-module-face ((,class (:foreground ,red))))
     `(agda2-highlight-number-face ((,class (:foreground ,green))))
     `(agda2-highlight-positivity-problem-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-postulate-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-primitive-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-primitive-type-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-record-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-string-face ((,class (:foreground ,green))))
     `(agda2-highlight-symbol-face ((,class (:foreground ,red))))
     `(agda2-highlight-termination-problem-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-typechecks-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-unsolved-constraint-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-unsolved-meta-face ((,class (:foreground ,yellow))))

;;;; alert - dark
     `(alert-high-face ((,class (:weight bold :foreground ,yellow))))
     `(alert-low-face ((,class (:foreground ,grey))))
     `(alert-moderate-face ((,class (:weight bold :foreground ,fg-other))))
     `(alert-trivial-face ((,class (:foreground ,spacegrey5))))
     `(alert-urgent-face ((,class (:weight bold :foreground ,red))))

;;;; all-the-icons - dark
     `(all-the-icons-blue ((,class (:foreground ,blue))))
     `(all-the-icons-blue-alt ((,class (:foreground ,teal))))
     `(all-the-icons-cyan ((,class (:foreground ,cyan))))
     `(all-the-icons-cyan-alt ((,class (:foreground ,cyan))))
     `(all-the-icons-dblue ((,class (:foreground ,darkblue))))
     `(all-the-icons-dcyan ((,class (:foreground ,darkcyan))))
     `(all-the-icons-dgreen ((,class (:foreground ,green))))
     `(all-the-icons-dmagenta ((,class (:foreground ,red))))
     `(all-the-icons-dmaroon ((,class (:foreground ,purple))))
     `(all-the-icons-dorange ((,class (:foreground ,orange))))
     `(all-the-icons-dpurple ((,class (:foreground ,magenta))))
     `(all-the-icons-dred ((,class (:foreground ,red))))
     `(all-the-icons-dsilver ((,class (:foreground ,grey))))
     `(all-the-icons-dyellow ((,class (:foreground ,yellow))))
     `(all-the-icons-green ((,class (:foreground ,green))))
     `(all-the-icons-lblue ((,class (:foreground ,blue))))
     `(all-the-icons-lcyan ((,class (:foreground ,cyan))))
     `(all-the-icons-lgreen ((,class (:foreground ,green))))
     `(all-the-icons-lmagenta ((,class (:foreground ,red))))
     `(all-the-icons-lmaroon ((,class (:foreground ,purple))))
     `(all-the-icons-lorange ((,class (:foreground ,orange))))
     `(all-the-icons-lpurple ((,class (:foreground ,magenta))))
     `(all-the-icons-lred ((,class (:foreground ,red))))
     `(all-the-icons-lsilver ((,class (:foreground ,grey))))
     `(all-the-icons-lyellow ((,class (:foreground ,yellow))))
     `(all-the-icons-magenta ((,class (:foreground ,red))))
     `(all-the-icons-maroon ((,class (:foreground ,purple))))
     `(all-the-icons-orange ((,class (:foreground ,orange))))
     `(all-the-icons-purple ((,class (:foreground ,magenta))))
     `(all-the-icons-purple-alt ((,class (:foreground ,magenta))))
     `(all-the-icons-red ((,class (:foreground ,red))))
     `(all-the-icons-red-alt ((,class (:foreground ,red))))
     `(all-the-icons-silver ((,class (:foreground ,grey))))
     `(all-the-icons-yellow ((,class (:foreground ,yellow))))

;;;; all-the-icons-dired - dark
     `(all-the-icons-dired-dir-face ((,class (:foreground ,fg-other))))

;;;; all-the-icons-ivy-rich - dark
     `(all-the-icons-ivy-rich-doc-face ((,class (:foreground ,blue))))
     `(all-the-icons-ivy-rich-path-face ((,class (:foreground ,blue))))
     `(all-the-icons-ivy-rich-size-face ((,class (:foreground ,blue))))
     `(all-the-icons-ivy-rich-time-face ((,class (:foreground ,blue))))

;;;; annotate - dark
     `(annotate-annotation ((,class (:background ,orange :foreground ,spacegrey5))))
     `(annotate-annotation-secondary ((,class (:background ,green :foreground ,spacegrey5))))
     `(annotate-highlight ((,class (:background ,orange :underline ,orange))))
     `(annotate-highlight-secondary ((,class (:background ,green :underline ,green))))

;;;; ansi - dark
     `(ansi-color-black ((,class (:foreground ,spacegrey0))))
     `(ansi-color-blue ((,class (:foreground ,blue))))
     `(ansi-color-cyan ((,class (:foreground ,cyan))))
     `(ansi-color-green ((,class (:foreground ,green))))
     `(ansi-color-magenta ((,class (:foreground ,magenta))))
     `(ansi-color-purple ((,class (:foreground ,purple))))
     `(ansi-color-red ((,class (:foreground ,red))))
     `(ansi-color-white ((,class (:foreground ,spacegrey8))))
     `(ansi-color-yellow ((,class (:foreground ,yellow))))
     `(ansi-color-bright-black ((,class (:foreground ,spacegrey0))))
     `(ansi-color-bright-blue ((,class (:foreground ,blue))))
     `(ansi-color-bright-cyan ((,class (:foreground ,cyan))))
     `(ansi-color-bright-green ((,class (:foreground ,green))))
     `(ansi-color-bright-magenta ((,class (:foreground ,magenta))))
     `(ansi-color-bright-purple ((,class (:foreground ,purple))))
     `(ansi-color-bright-red ((,class (:foreground ,red))))
     `(ansi-color-bright-white ((,class (:foreground ,spacegrey8))))
     `(ansi-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; anzu - dark
     `(anzu-replace-highlight ((,class (:background ,spacegrey0 :foreground ,red :weight bold :strike-through t))))
     `(anzu-replace-to ((,class (:background ,spacegrey0 :foreground ,green :weight bold))))

;;;; auctex - dark
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
     `(font-latex-string-face ((,class (:foreground ,green))))
     `(font-latex-verbatim-face ((,class (:foreground ,magenta :slant italic))))
     `(font-latex-warning-face ((,class (:foreground ,yellow))))

;;;; avy - dark
     `(avy-background-face ((,class (:foreground ,spacegrey5))))
     `(avy-lead-face ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(avy-lead-face-0 ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(avy-lead-face-1 ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(avy-lead-face-2 ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))

;;;; bookmark+ - dark
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
     `(bmkp-gnus ((,class (:foreground ,orange))))
     `(bmkp-heading ((,class (:foreground ,yellow))))
     `(bmkp-info ((,class (:foreground ,cyan))))
     `(bmkp-light-autonamed ((,class (:foreground ,bg-other :background ,cyan))))
     `(bmkp-light-autonamed-region ((,class (:foreground ,bg-other :background ,red))))
     `(bmkp-light-fringe-autonamed ((,class (:foreground ,bg-other :background ,magenta))))
     `(bmkp-light-fringe-non-autonamed ((,class (:foreground ,bg-other :background ,green))))
     `(bmkp-light-mark ((,class (:foreground ,bg :background ,cyan))))
     `(bmkp-light-non-autonamed ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-light-non-autonamed-region ((,class (:foreground ,bg :background ,red))))
     `(bmkp-local-directory ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-local-file-with-region ((,class (:foreground ,yellow))))
     `(bmkp-local-file-without-region ((,class (:foreground ,spacegrey5))))
     `(bmkp-man ((,class (:foreground ,magenta))))
     `(bmkp-no-jump ((,class (:foreground ,spacegrey5))))
     `(bmkp-no-local ((,class (:foreground ,yellow))))
     `(bmkp-non-file ((,class (:foreground ,green))))
     `(bmkp-remote-file ((,class (:foreground ,orange))))
     `(bmkp-sequence ((,class (:foreground ,blue))))
     `(bmkp-su-or-sudo ((,class (:foreground ,red))))
     `(bmkp-t-mark ((,class (:foreground ,magenta))))
     `(bmkp-url ((,class (:foreground ,blue :underline t))))
     `(bmkp-variable-list ((,class (:foreground ,green))))

;;;; calfw - dark
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
     `(cfw:face-toolbar-button-off ((,class (:foreground ,spacegrey6 :weight bold))))
     `(cfw:face-toolbar-button-on ((,class (:foreground ,blue :weight bold))))

;;;; centaur-tabs - dark
     `(centaur-tabs-active-bar-face ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-close-mouse-face ((,class (:foreground ,orange))))
     `(centaur-tabs-close-selected ((,class (:background ,bg :foreground ,fg))))
     `(centaur-tabs-close-unselected ((,class (:background ,bg-other :foreground ,grey))))
     `(centaur-tabs-default ((,class (:background ,bg-other :foreground ,fg))))
     `(centaur-tabs-modified-marker-selected ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-modified-marker-unselected ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-selected ((,class (:background ,bg :foreground ,fg))))
     `(centaur-tabs-selected-modified ((,class (:background ,bg :foreground ,red))))
     `(centaur-tabs-unselected ((,class (:background ,bg-other :foreground ,grey))))
     `(centaur-tabs-unselected-modified ((,class (:background ,bg-other :foreground ,red))))

;;;; circe - dark
     `(circe-fool ((,class (:foreground ,spacegrey5))))
     `(circe-highlight-nick-face ((,class (:weight bold :foreground ,orange))))
     `(circe-my-message-face ((,class (:weight bold))))
     `(circe-prompt-face ((,class (:weight bold :foreground ,orange))))
     `(circe-server-face ((,class (:foreground ,spacegrey5))))

;;;; company - dark
     `(company-preview ((,class (:foreground ,spacegrey5))))
     `(company-preview-common ((,class (:background ,spacegrey3 :foreground ,orange))))
     `(company-preview-search ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(company-scrollbar-bg ((,class (:background ,bg-other :foreground ,fg))))
     `(company-scrollbar-fg ((,class (:background ,orange))))
     `(company-template-field ((,class (:foreground ,green :background ,spacegrey0 :weight bold))))
     `(company-tooltip ((,class (:background ,bg-other :foreground ,fg))))
     `(company-tooltip-annotation ((,class (:foreground ,magenta :distant-foreground ,bg))))
     `(company-tooltip-common ((,class (:foreground ,orange :distant-foreground ,spacegrey0 :weight bold))))
     `(company-tooltip-mouse ((,class (:background ,purple :foreground ,bg :distant-foreground ,fg))))
     `(company-tooltip-search ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(company-tooltip-search-selection ((,class (:background ,grey))))
     `(company-tooltip-selection ((,class (:background ,grey :weight bold))))

;;;; company-box - dark
     `(company-box-candidate ((,class (:foreground ,fg))))

;;;; compilation - dark
     `(compilation-column-number ((,class (:foreground ,spacegrey5 :slant italic))))
     `(compilation-error ((,class (:foreground ,red :weight bold))))
     `(compilation-info ((,class (:foreground ,green))))
     `(compilation-line-number ((,class (:foreground ,orange))))
     `(compilation-mode-line-exit ((,class (:foreground ,green))))
     `(compilation-mode-line-fail ((,class (:foreground ,red :weight bold))))
     `(compilation-warning ((,class (:foreground ,yellow :slant italic))))

;;;; corfu - dark
     `(corfu-bar ((,class (:background ,bg-org :foreground ,fg))))
     `(corfu-echo ((,class (:foreground ,orange))))
     `(corfu-border ((,class (:background ,fg))))
     `(corfu-current ((,class (:foreground ,orange :weight bold))))
     `(corfu-default ((,class (:background ,bg-org :foreground ,fg))))
     `(corfu-deprecated ((,class (:foreground ,red))))
     `(corfu-annotations ((,class (:foreground ,magenta))))

;;;; counsel - dark
     `(counsel-variable-documentation ((,class (:foreground ,blue))))

;;;; cperl - dark
     `(cperl-array-face ((,class (:weight bold :foreground ,red))))
     `(cperl-hash-face ((,class (:weight bold :slant italic :foreground ,red))))
     `(cperl-nonoverridable-face ((,class (:foreground ,orange))))

;;;; custom - dark
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
     `(custom-link ((,class (:foreground ,orange :underline t))))
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

;;; diff - dark
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
     `(diff-file-header ((,class (:foreground ,orange :weight bold))))
     `(diff-hunk-header ((,class (:foreground ,bg :background ,magenta :extend t))))
     `(diff-function ((,class (:foreground ,bg :background ,magenta :extend t))))

;;;; diff-hl - dark
     `(diff-hl-change ((,class (:foreground ,orange :background ,orange))))
     `(diff-hl-delete ((,class (:foreground ,red :background ,red))))
     `(diff-hl-insert ((,class (:foreground ,green :background ,green))))

;;;; dired - dark
     `(dired-directory ((,class (:foreground ,darkcyan :weight bold))))
     `(dired-flagged ((,class (:foreground ,red))))
     `(dired-header ((,class (:foreground ,orange :weight bold :underline ,darkcyan))))
     `(dired-ignored ((,class (:foreground ,spacegrey5))))
     `(dired-mark ((,class (:foreground ,orange :weight bold))))
     `(dired-marked ((,class (:foreground ,yellow :weight bold))))
     `(dired-perm-write ((,class (:foreground ,red :underline t))))
     `(dired-symlink ((,class (:foreground ,magenta))))
     `(dired-warning ((,class (:foreground ,yellow))))

;;;; dired-async - dark
     `(dired-async-failures ((,class (:foreground ,red))))
     `(dired-async-message ((,class (:foreground ,orange))))
     `(dired-async-mode-message ((,class (:foreground ,orange))))

;;;; dired-filetype-face - dark
     `(dired-filetype-common ((,class (:foreground ,fg))))
     `(dired-filetype-compress ((,class (:foreground ,yellow))))
     `(dired-filetype-document ((,class (:foreground ,fg))))
     `(dired-filetype-execute ((,class (:foreground ,red))))
     `(dired-filetype-image ((,class (:foreground ,orange))))
     `(dired-filetype-js ((,class (:foreground ,yellow))))
     `(dired-filetype-link ((,class (:foreground ,magenta))))
     `(dired-filetype-music ((,class (:foreground ,magenta))))
     `(dired-filetype-omit ((,class (:foreground ,blue))))
     `(dired-filetype-plain ((,class (:foreground ,fg))))
     `(dired-filetype-program ((,class (:foreground ,red))))
     `(dired-filetype-source ((,class (:foreground ,green))))
     `(dired-filetype-video ((,class (:foreground ,magenta))))
     `(dired-filetype-xml ((,class (:foreground ,green))))

;;;; dired+ - dark
     `(diredp-compressed-file-suffix ((,class (:foreground ,spacegrey5))))
     `(diredp-date-time ((,class (:foreground ,blue))))
     `(diredp-dir-heading ((,class (:foreground ,blue :weight bold))))
     `(diredp-dir-name ((,class (:foreground ,spacegrey8 :weight bold))))
     `(diredp-dir-priv ((,class (:foreground ,blue :weight bold))))
     `(diredp-exec-priv ((,class (:foreground ,yellow))))
     `(diredp-file-name ((,class (:foreground ,spacegrey8))))
     `(diredp-file-suffix ((,class (:foreground ,magenta))))
     `(diredp-ignored-file-name ((,class (:foreground ,spacegrey5))))
     `(diredp-no-priv ((,class (:foreground ,spacegrey5))))
     `(diredp-number ((,class (:foreground ,purple))))
     `(diredp-rare-priv ((,class (:foreground ,red :weight bold))))
     `(diredp-read-priv ((,class (:foreground ,purple))))
     `(diredp-symlink ((,class (:foreground ,magenta))))
     `(diredp-write-priv ((,class (:foreground ,green))))

;;;; dired-k - dark
     `(dired-k-added ((,class (:foreground ,green :weight bold))))
     `(dired-k-commited ((,class (:foreground ,green :weight bold))))
     `(dired-k-directory ((,class (:foreground ,blue :weight bold))))
     `(dired-k-ignored ((,class (:foreground ,spacegrey5 :weight bold))))
     `(dired-k-modified ((,class (:foreground ,orange :weight bold))))
     `(dired-k-untracked ((,class (:foreground ,teal :weight bold))))

;;;; dired-subtree - dark
     `(dired-subtree-depth-1-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-2-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-3-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-4-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-5-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-6-face ((,class (:background ,bg-other))))

;;;; diredfl - dark
     `(diredfl-autofile-name ((,class (:foreground ,spacegrey4))))
     `(diredfl-compressed-file-name ((,class (:foreground ,orange))))
     `(diredfl-compressed-file-suffix ((,class (:foreground ,yellow))))
     `(diredfl-date-time ((,class (:foreground ,cyan :weight light))))
     `(diredfl-deletion ((,class (:foreground ,red :weight bold))))
     `(diredfl-deletion-file-name ((,class (:foreground ,red))))
     `(diredfl-dir-heading ((,class (:foreground ,blue :weight bold))))
     `(diredfl-dir-name ((,class (:foreground ,darkcyan))))
     `(diredfl-dir-priv ((,class (:foreground ,blue))))
     `(diredfl-exec-priv ((,class (:foreground ,red))))
     `(diredfl-executable-tag ((,class (:foreground ,red))))
     `(diredfl-file-name ((,class (:foreground ,fg))))
     `(diredfl-file-suffix ((,class (:foreground ,teal))))
     `(diredfl-flag-mark ((,class (:foreground ,yellow :background ,yellow :weight bold))))
     `(diredfl-flag-mark-line ((,class (:background ,yellow))))
     `(diredfl-ignored-file-name ((,class (:foreground ,spacegrey5))))
     `(diredfl-link-priv ((,class (:foreground ,magenta))))
     `(diredfl-no-priv ((,class (:foreground ,fg))))
     `(diredfl-number ((,class (:foreground ,orange))))
     `(diredfl-other-priv ((,class (:foreground ,purple))))
     `(diredfl-rare-priv ((,class (:foreground ,fg))))
     `(diredfl-read-priv ((,class (:foreground ,yellow))))
     `(diredfl-symlink ((,class (:foreground ,magenta))))
     `(diredfl-tagged-autofile-name ((,class (:foreground ,spacegrey5))))
     `(diredfl-write-priv ((,class (:foreground ,red))))

;;;; doom-modeline - dark
     `(doom-modeline-bar-inactive ((,class (:background nil))))
     `(doom-modeline-buffer-modified ((,class (:foreground ,red :weight bold))))
     `(doom-modeline-eldoc-bar ((,class (:background ,green))))
     `(doom-modeline-evil-emacs-state ((,class (:foreground ,cyan :weight bold))))
     `(doom-modeline-evil-insert-state ((,class (:foreground ,red :weight bold))))
     `(doom-modeline-evil-motion-state ((,class (:foreground ,blue :weight bold))))
     `(doom-modeline-evil-normal-state ((,class (:foreground ,green :weight bold))))
     `(doom-modeline-evil-operator-state ((,class (:foreground ,magenta :weight bold))))
     `(doom-modeline-evil-replace-state ((,class (:foreground ,purple :weight bold))))
     `(doom-modeline-evil-visual-state ((,class (:foreground ,yellow :weight bold))))

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
     `(elfeed-log-debug-level-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-log-error-level-face ((,class (:foreground ,red))))
     `(elfeed-log-info-level-face ((,class (:foreground ,green))))
     `(elfeed-log-warn-level-face ((,class (:foreground ,yellow))))
     `(elfeed-search-date-face ((,class (:foreground ,magenta))))
     `(elfeed-search-feed-face ((,class (:foreground ,blue))))
     `(elfeed-search-filter-face ((,class (:foreground ,magenta))))
     `(elfeed-search-tag-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-search-title-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-search-unread-count-face ((,class (:foreground ,yellow))))
     `(elfeed-search-unread-title-face ((,class (:foreground ,fg :weight bold))))

;;;; elixir-mode - dark
     `(elixir-atom-face ((,class (:foreground ,cyan))))
     `(elixir-attribute-face ((,class (:foreground ,magenta))))

;;;; elscreen - dark
     `(elscreen-tab-background-face ((,class (:background ,bg))))
     `(elscreen-tab-control-face ((,class (:background ,bg :foreground ,bg))))
     `(elscreen-tab-current-screen-face ((,class (:background ,bg-other :foreground ,fg))))
     `(elscreen-tab-other-screen-face ((,class (:background ,bg :foreground ,fg-other))))

;;;; enh-ruby-mode - dark
     `(enh-ruby-heredoc-delimiter-face ((,class (:foreground ,green))))
     `(enh-ruby-op-face ((,class (:foreground ,fg))))
     `(enh-ruby-regexp-delimiter-face ((,class (:foreground ,orange))))
     `(enh-ruby-regexp-face ((,class (:foreground ,orange))))
     `(enh-ruby-string-delimiter-face ((,class (:foreground ,green))))
     `(erm-syn-errline ((,class (:underline (:style wave :color ,red)))))
     `(erm-syn-warnline ((,class (:underline (:style wave :color ,yellow)))))

;;;; erc - dark
     `(erc-action-face  ((,class (:weight bold))))
     `(erc-button ((,class (:weight bold :underline t))))
     `(erc-command-indicator-face ((,class (:weight bold))))
     `(erc-current-nick-face ((,class (:foreground ,green :weight bold))))
     `(erc-default-face ((,class (:background ,bg :foreground ,fg))))
     `(erc-direct-msg-face ((,class (:foreground ,purple))))
     `(erc-error-face ((,class (:foreground ,red))))
     `(erc-header-line ((,class (:background ,bg-other :foreground ,orange))))
     `(erc-input-face ((,class (:foreground ,green))))
     `(erc-my-nick-face ((,class (:foreground ,green :weight bold))))
     `(erc-my-nick-prefix-face ((,class (:foreground ,green :weight bold))))
     `(erc-nick-default-face ((,class (:weight bold))))
     `(erc-nick-msg-face ((,class (:foreground ,purple))))
     `(erc-nick-prefix-face ((,class (:weight bold))))
     `(erc-notice-face ((,class (:foreground ,spacegrey5))))
     `(erc-prompt-face ((,class (:foreground ,orange :weight bold))))
     `(erc-timestamp-face ((,class (:foreground ,blue :weight bold))))

;;;; eshell - dark
     `(eshell-ls-archive ((,class (:foreground ,yellow))))
     `(eshell-ls-backup ((,class (:foreground ,yellow))))
     `(eshell-ls-clutter ((,class (:foreground ,red))))
     `(eshell-ls-directory ((,class (:foreground ,darkcyan))))
     `(eshell-ls-executable ((,class (:foreground ,red))))
     `(eshell-ls-missing ((,class (:foreground ,red))))
     `(eshell-ls-product ((,class (:foreground ,orange))))
     `(eshell-ls-readonly ((,class (:foreground ,orange))))
     `(eshell-ls-special ((,class (:foreground ,magenta))))
     `(eshell-ls-symlink ((,class (:foreground ,magenta))))
     `(eshell-ls-unreadable ((,class (:foreground ,spacegrey5))))
     `(eshell-prompt ((,class (:foreground ,orange :weight bold))))

;;;; evil - dark
     `(evil-ex-info ((,class (:foreground ,red :slant italic))))
     `(evil-ex-search ((,class (:background ,orange :foreground ,spacegrey0 :weight bold))))
     `(evil-ex-substitute-matches ((,class (:background ,spacegrey0 :foreground ,red :weight bold :strike-through t))))
     `(evil-ex-substitute-replacement ((,class (:background ,spacegrey0 :foreground ,green :weight bold))))
     `(evil-search-highlight-persist-highlight-face ((,class (:background ,darkblue  :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))

;;;; evil-googles - dark
     `(evil-goggles-default-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-mc - dark
     `(evil-mc-cursor-bar-face ((,class (:height 1 :background ,purple :foreground ,spacegrey0))))
     `(evil-mc-cursor-default-face ((,class (:background ,purple :foreground ,spacegrey0 :inverse-video nil))))
     `(evil-mc-cursor-hbar-face ((,class (:underline (:color ,orange)))))
     `(evil-mc-region-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-snipe - dark
     `(evil-snipe-first-match-face ((,class (:foreground ,orange :background ,darkblue :weight bold))))
     `(evil-snipe-matches-face ((,class (:foreground ,orange :underline t :weight bold))))

;;;; expenses - dark
     `(expenses-face-date ((,class (:foreground ,orange :weight bold))))
     `(expenses-face-expence ((,class (:foreground ,green :weight bold))))
     `(expenses-face-message ((,class (:foreground ,darkcyan :weight bold))))

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
     `(flycheck-posframe-info-face ((,class (:foreground ,fg))))
     `(flycheck-posframe-warning-face ((,class (:foreground ,yellow))))

;;;; flymake - dark
     `(flymake-error ((,class (:underline (:style wave :color ,red)))))
     `(flymake-note ((,class (:underline (:style wave :color ,green)))))
     `(flymake-warning ((,class (:underline (:style wave :color ,orange)))))

;;;; flyspell - dark
     `(flyspell-duplicate ((,class (:underline (:style wave :color ,yellow)))))
     `(flyspell-incorrect ((,class (:underline (:style wave :color ,red)))))

;;;; forge - dark
     `(forge-topic-closed ((,class (:foreground ,spacegrey5 :strike-through t))))
     `(forge-topic-label ((,class (:box nil))))

;;;; git-commit - dark
     `(git-commit-comment-branch-local ((,class (:foreground ,purple))))
     `(git-commit-comment-branch-remote ((,class (:foreground ,green))))
     `(git-commit-comment-detached ((,class (:foreground ,orange))))
     `(git-commit-comment-file ((,class (:foreground ,magenta))))
     `(git-commit-comment-heading ((,class (:foreground ,magenta))))
     `(git-commit-keyword ((,class (:foreground ,cyan :slant italic))))
     `(git-commit-known-pseudo-header ((,class (:foreground ,spacegrey5 :weight bold :slant italic))))
     `(git-commit-nonempty-second-line ((,class (:foreground ,red))))
     `(git-commit-overlong-summary ((,class (:foreground ,red :slant italic :weight bold))))
     `(git-commit-pseudo-header ((,class (:foreground ,spacegrey5 :slant italic))))
     `(git-commit-summary ((,class (:foreground ,darkcyan))))

;;;; git-gutter - dark
     `(git-gutter:added ((,class (:foreground ,green))))
     `(git-gutter:deleted ((,class (:foreground ,red))))
     `(git-gutter:modified ((,class (:foreground ,cyan))))

;;;; git-gutter+ - dark
     `(git-gutter+-added ((,class (:foreground ,green :background ,bg))))
     `(git-gutter+-deleted ((,class (:foreground ,red :background ,bg))))
     `(git-gutter+-modified ((,class (:foreground ,cyan :background ,bg))))

;;;; git-gutter-fringe - dark
     `(git-gutter-fr:added ((,class (:foreground ,green))))
     `(git-gutter-fr:deleted ((,class (:foreground ,red))))
     `(git-gutter-fr:modified ((,class (:foreground ,cyan))))

;;;; gnus - dark
     `(gnus-cite-1 ((,class (:foreground ,magenta))))
     `(gnus-cite-2 ((,class (:foreground ,magenta))))
     `(gnus-cite-3 ((,class (:foreground ,magenta))))
     `(gnus-cite-4 ((,class (:foreground ,green))))
     `(gnus-cite-5 ((,class (:foreground ,green))))
     `(gnus-cite-6 ((,class (:foreground ,green))))
     `(gnus-cite-7 ((,class (:foreground ,purple))))
     `(gnus-cite-8 ((,class (:foreground ,purple))))
     `(gnus-cite-9 ((,class (:foreground ,purple))))
     `(gnus-cite-10 ((,class (:foreground ,yellow))))
     `(gnus-cite-11 ((,class (:foreground ,yellow))))
     `(gnus-group-mail-1 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-mail-1-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-mail-2 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-mail-2-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-mail-3 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-mail-3-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-mail-low ((,class (:foreground ,fg))))
     `(gnus-group-mail-low-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-1 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-1-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-2 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-2-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-3 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-3-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-4 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-4-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-5 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-5-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-6 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-6-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-low ((,class (:weight bold :foreground ,spacegrey5))))
     `(gnus-group-news-low-empty ((,class (:foreground ,fg))))
     `(gnus-header-content ((,class (:foreground ,magenta))))
     `(gnus-header-from ((,class (:foreground ,magenta))))
     `(gnus-header-name ((,class (:foreground ,green))))
     `(gnus-header-newsgroups ((,class (:foreground ,magenta))))
     `(gnus-header-subject ((,class (:foreground ,orange :weight bold))))
     `(gnus-signature ((,class (:foreground ,yellow))))
     `(gnus-summary-cancelled ((,class (:foreground ,red :strike-through t))))
     `(gnus-summary-high-ancient ((,class (:foreground ,spacegrey5 :slant italic))))
     `(gnus-summary-high-read ((,class (:foreground ,fg))))
     `(gnus-summary-high-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-high-unread ((,class (:foreground ,green))))
     `(gnus-summary-low-ancient ((,class (:foreground ,spacegrey5 :slant italic))))
     `(gnus-summary-low-read ((,class (:foreground ,fg))))
     `(gnus-summary-low-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-low-unread ((,class (:foreground ,green))))
     `(gnus-summary-normal-ancient ((,class (:foreground ,spacegrey5 :slant italic))))
     `(gnus-summary-normal-read ((,class (:foreground ,fg))))
     `(gnus-summary-normal-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-normal-unread ((,class (:foreground ,green :weight bold))))
     `(gnus-summary-selected ((,class (:foreground ,blue :weight bold))))
     `(gnus-x-face ((,class (:background ,spacegrey5 :foreground ,fg))))

;;;; goggles - dark
     `(goggles-added ((,class (:background ,green))))
     `(goggles-changed ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
     `(goggles-removed ((,class (:background ,red :extend t))))

;;;; header-line - dark
     `(header-line ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))

;;;; helm - dark
     `(helm-ff-directory ((,class (:foreground ,red))))
     `(helm-ff-dotted-directory ((,class (:foreground ,grey))))
     `(helm-ff-executable ((,class (:foreground ,spacegrey8 :slant italic))))
     `(helm-ff-file ((,class (:foreground ,fg))))
     `(helm-ff-prefix ((,class (:foreground ,magenta))))
     `(helm-grep-file ((,class (:foreground ,blue))))
     `(helm-grep-finish ((,class (:foreground ,green))))
     `(helm-grep-lineno ((,class (:foreground ,spacegrey5))))
     `(helm-grep-match ((,class (:foreground ,orange :distant-foreground ,red))))
     `(helm-match ((,class (:weight bold :foreground ,orange :distant-foreground ,spacegrey8))))
     `(helm-moccur-buffer ((,class (:foreground ,orange :underline t :weight bold))))
     `(helm-selection ((,class (:weight bold :background ,grey :extend t :distant-foreground ,orange))))
     `(helm-source-header ((,class (:background ,spacegrey2 :foreground ,magenta :weight bold))))
     `(helm-swoop-target-line-block-face ((,class (:foreground ,yellow))))
     `(helm-swoop-target-line-face ((,class (:foreground ,orange :inverse-video t))))
     `(helm-swoop-target-line-face ((,class (:foreground ,orange :inverse-video t))))
     `(helm-swoop-target-number-face ((,class (:foreground ,spacegrey5))))
     `(helm-swoop-target-word-face ((,class (:foreground ,green :weight bold))))
     `(helm-visible-mark ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))

;;;; helpful - dark
     `(helpful-heading ((,class (:weight bold :height 1.2))))

;;;; hi-lock - dark
     `(hi-blue ((,class (:background ,blue))))
     `(hi-blue-b ((,class (:foreground ,blue :weight bold))))
     `(hi-green ((,class (:background ,green))))
     `(hi-green-b ((,class (:foreground ,green :weight bold))))
     `(hi-magenta ((,class (:background ,purple))))
     `(hi-red-b ((,class (:foreground ,red :weight bold))))
     `(hi-yellow ((,class (:background ,yellow))))

;;;; highlight-indentation-mode - dark
     `(highlight-indentation-current-column-face ((,class (:background ,spacegrey1))))
     `(highlight-indentation-face ((,class (:background ,bg-other :extend t))))
     `(highlight-indentation-guides-even-face ((,class (:background ,bg-other :extend t))))
     `(highlight-indentation-guides-odd-face ((,class (:background ,bg-other :extend t))))

;;;; highlight-numbers-mode - dark
     `(highlight-numbers-number ((,class (:weight bold :foreground ,orange))))

;;;; highlight-quoted-mode - dark
     `(highlight-quoted-quote  ((,class (:foreground ,fg))))
     `(highlight-quoted-symbol ((,class (:foreground ,yellow))))

;;;; highlight-symbol - dark
     `(highlight-symbol-face ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; highlight-thing - dark
     `(highlight-thing ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; hl-fill-column-face - dark
     `(hl-fill-column-face ((,class (:foreground ,spacegrey5 :background ,bg-other :extend t))))

;;;; hl-line (built-in) - dark
     `(hl-line ((,class (:background ,bg-other :extend t))))

;;;; hl-todo - dark
     `(hl-todo ((,class (:foreground ,red :weight bold))))

;;;; hlinum - dark
     `(linum-highlight-face ((,class (:foreground ,fg :distant-foreground nil :weight normal))))

;;;; hydra - dark
     `(hydra-face-amaranth ((,class (:foreground ,purple :weight bold))))
     `(hydra-face-blue ((,class (:foreground ,blue :weight bold))))
     `(hydra-face-magenta ((,class (:foreground ,magenta :weight bold))))
     `(hydra-face-red ((,class (:foreground ,red :weight bold))))
     `(hydra-face-teal ((,class (:foreground ,teal :weight bold))))

;;;; ido - dark
     `(ido-first-match ((,class (:foreground ,orange))))
     `(ido-indicator ((,class (:foreground ,red :background ,bg))))
     `(ido-only-match ((,class (:foreground ,green))))
     `(ido-subdir ((,class (:foreground ,magenta))))
     `(ido-virtual ((,class (:foreground ,spacegrey5))))

;;;; iedit - dark
     `(iedit-occurrence ((,class (:foreground ,purple :weight bold :inverse-video t))))
     `(iedit-read-only-occurrence ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; imenu-list - dark
     `(imenu-list-entry-face-0 ((,class (:foreground ,orange))))
     `(imenu-list-entry-face-1 ((,class (:foreground ,green))))
     `(imenu-list-entry-face-2 ((,class (:foreground ,yellow))))
     `(imenu-list-entry-subalist-face-0 ((,class (:foreground ,orange :weight bold))))
     `(imenu-list-entry-subalist-face-1 ((,class (:foreground ,green :weight bold))))
     `(imenu-list-entry-subalist-face-2 ((,class (:foreground ,yellow :weight bold))))

;;;; indent-guide - dark
     `(indent-guide-face ((,class (:background ,bg-other :extend t))))

;;;; isearch - dark
     `(isearch ((,class (:background ,darkblue  :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(isearch-fail ((,class (:background ,red :foreground ,spacegrey0 :weight bold))))

;;;; ivy - dark
     `(ivy-confirm-face ((,class (:foreground ,green))))
     `(ivy-current-match ((,class (:background ,grey :distant-foreground nil :extend t))))
     `(ivy-highlight-face ((,class (:foreground ,magenta))))
     `(ivy-match-required-face ((,class (:foreground ,red))))
     `(ivy-minibuffer-match-face-1 ((,class (:background nil :foreground ,orange :weight bold :underline t))))
     `(ivy-minibuffer-match-face-2 ((,class (:foreground ,purple :background ,spacegrey1 :weight semi-bold))))
     `(ivy-minibuffer-match-face-3 ((,class (:foreground ,green :weight semi-bold))))
     `(ivy-minibuffer-match-face-4 ((,class (:foreground ,yellow :weight semi-bold))))
     `(ivy-minibuffer-match-highlight ((,class (:foreground ,magenta))))
     `(ivy-modified-buffer ((,class (:weight bold :foreground ,darkcyan))))
     `(ivy-virtual ((,class (:slant italic :foreground ,fg))))

;;;; ivy-posframe - dark
     `(ivy-posframe ((,class (:background ,bg-other))))
     `(ivy-posframe-border ((,class (:background ,spacegrey4 :foreground ,spacegrey4))))

;;;; jabber - dark
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
     `(jabber-roster-user-xa ((,class (:foreground ,cyan))))

;;;; jdee - dark
     `(jdee-font-lock-bold-face ((,class (:weight bold))))
     `(jdee-font-lock-constant-face ((,class (:foreground ,orange))))
     `(jdee-font-lock-constructor-face ((,class (:foreground ,blue))))
     `(jdee-font-lock-doc-tag-face ((,class (:foreground ,magenta))))
     `(jdee-font-lock-italic-face ((,class (:slant italic))))
     `(jdee-font-lock-link-face ((,class (:foreground ,blue :italic nil :underline t))))
     `(jdee-font-lock-modifier-face ((,class (:foreground ,yellow))))
     `(jdee-font-lock-number-face ((,class (:foreground ,orange))))
     `(jdee-font-lock-operator-face ((,class (:foreground ,fg))))
     `(jdee-font-lock-private-face ((,class (:foreground ,magenta))))
     `(jdee-font-lock-protected-face ((,class (:foreground ,magenta))))
     `(jdee-font-lock-public-face ((,class (:foreground ,magenta))))

;;;; js2-mode - dark
     `(js2-external-variable ((,class (:foreground ,fg))))
     `(js2-function-call ((,class (:foreground ,blue))))
     `(js2-function-param ((,class (:foreground ,red))))
     `(js2-jsdoc-tag ((,class (:foreground ,spacegrey5))))
     `(js2-object-property ((,class (:foreground ,magenta))))

;;;; keycast - dark
     `(keycast-command ((,class (:foreground ,orange :distant-foreground ,bg))))
     `(keycast-key ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))

;;;; ledger-mode - dark
     `(ledger-font-payee-cleared-face ((,class (:foreground ,magenta :weight bold))))
     `(ledger-font-payee-uncleared-face ((,class (:foreground ,spacegrey5  :weight bold))))
     `(ledger-font-posting-account-face ((,class (:foreground ,spacegrey8))))
     `(ledger-font-posting-amount-face ((,class (:foreground ,yellow))))
     `(ledger-font-posting-date-face ((,class (:foreground ,blue))))
     `(ledger-font-xact-highlight-face ((,class (:background ,spacegrey0))))

;;;; line numbers - dark
     `(line-number ((,class (:foreground ,spacegrey5))))
     `(line-number-current-line ((,class (:foreground ,fg))))

;;;; linum - dark
     `(linum ((,class (:foreground ,spacegrey5))))

;;;; linum-relative - dark
     `(linum-relative-current-face ((,class (:foreground ,fg))))

;;;; lsp-mode - dark
     `(lsp-face-highlight-read ((,class (:foreground ,yellow :weight bold :underline ,yellow ))))
     `(lsp-face-highlight-textual ((,class (:foreground ,yellow :weight bold))))
     `(lsp-face-highlight-write ((,class (:foreground ,yellow :weight bold :underline ,yellow ))))
     `(lsp-headerline-breadcrumb-separator-face ((,class (:foreground ,fg-other))))
     `(lsp-ui-doc-background ((,class (:background ,bg-other :foreground ,fg))))
     `(lsp-ui-peek-filename ((,class (:weight bold))))
     `(lsp-ui-peek-header ((,class (:foreground ,fg :background ,bg :weight bold))))
     `(lsp-ui-peek-highlight ((,class (:background ,grey :foreground ,bg :box t :weight bold))))
     `(lsp-ui-peek-line-number ((,class (:foreground ,green))))
     `(lsp-ui-peek-list ((,class (:background ,bg))))
     `(lsp-ui-peek-peek ((,class (:background ,bg))))
     `(lsp-ui-peek-selection ((,class (:foreground ,bg :background ,blue :bold bold))))
     `(lsp-ui-sideline-code-action ((,class (:foreground ,orange))))
     `(lsp-ui-sideline-current-symbol ((,class (:foreground ,orange))))
     `(lsp-ui-sideline-symbol-info ((,class (:foreground ,spacegrey5 :background ,bg-other :extend t))))

;;;; lui - dark
     `(lui-button-face ((,class (:foreground ,orange :underline t))))
     `(lui-highlight-face ((,class (:foreground ,orange))))
     `(lui-time-stamp-face ((,class (:foreground ,magenta))))

;;;; magit - dark
     `(magit-bisect-bad ((,class (:foreground ,red))))
     `(magit-bisect-good ((,class (:foreground ,green))))
     `(magit-bisect-skip ((,class (:foreground ,orange))))
     `(magit-blame-date ((,class (:foreground ,red))))
     `(magit-blame-heading ((,class (:foreground ,orange :background ,spacegrey3 :extend t))))
     `(magit-branch-current ((,class (:foreground ,red))))
     `(magit-branch-local ((,class (:foreground ,red))))
     `(magit-branch-remote ((,class (:foreground ,green))))
     `(magit-branch-remote-head ((,class (:foreground ,green))))
     `(magit-cherry-equivalent ((,class (:foreground ,magenta))))
     `(magit-cherry-unmatched ((,class (:foreground ,cyan))))
     `(magit-diff-added ((,class (:foreground ,bg  :background ,green :extend t))))
     `(magit-diff-added-highlight ((,class (:foreground ,bg :background ,green :weight bold :extend t))))
     `(magit-diff-base ((,class (:foreground ,orange :background ,orange :extend t))))
     `(magit-diff-base-highlight ((,class (:foreground ,orange :background ,orange :weight bold :extend t))))
     `(magit-diff-context ((,class (:foreground ,fg :background ,bg :extend t))))
     `(magit-diff-context-highlight ((,class (:foreground ,fg :background ,bg-other :extend t))))
     `(magit-diff-file-heading ((,class (:foreground ,fg :weight bold :extend t))))
     `(magit-diff-file-heading-selection ((,class (:foreground ,orange :background ,darkblue :weight bold :extend t))))
     `(magit-diff-hunk-heading ((,class (:foreground ,bg :background ,magenta :extend t))))
     `(magit-diff-hunk-heading-highlight ((,class (:foreground ,bg :background ,magenta :weight bold :extend t))))
     `(magit-diff-lines-heading ((,class (:foreground ,yellow :background ,red :extend t :extend t))))
     `(magit-diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
     `(magit-diff-removed-highlight ((,class (:foreground ,bg :background ,red :weight bold :extend t))))
     `(magit-diffstat-added ((,class (:foreground ,green))))
     `(magit-diffstat-removed ((,class (:foreground ,red))))
     `(magit-dimmed ((,class (:foreground ,spacegrey5))))
     `(magit-filename ((,class (:foreground ,magenta))))
     `(magit-hash ((,class (:foreground ,blue))))
     `(magit-header-line ((,class (:background ,bg-other :foreground ,darkcyan :weight bold :box (:line-width 3 :color ,bg-other)))))
     `(magit-log-author ((,class (:foreground ,orange))))
     `(magit-log-date ((,class (:foreground ,blue))))
     `(magit-log-graph ((,class (:foreground ,spacegrey5))))
     `(magit-process-ng ((,class (:foreground ,red))))
     `(magit-process-ok ((,class (:foreground ,green))))
     `(magit-reflog-amend ((,class (:foreground ,purple))))
     `(magit-reflog-checkout ((,class (:foreground ,blue))))
     `(magit-reflog-cherry-pick ((,class (:foreground ,green))))
     `(magit-reflog-commit ((,class (:foreground ,green))))
     `(magit-reflog-merge ((,class (:foreground ,green))))
     `(magit-reflog-other ((,class (:foreground ,cyan))))
     `(magit-reflog-rebase ((,class (:foreground ,purple))))
     `(magit-reflog-remote ((,class (:foreground ,cyan))))
     `(magit-reflog-reset ((,class (:foreground ,red))))
     `(magit-refname ((,class (:foreground ,spacegrey5))))
     `(magit-section-heading ((,class (:foreground ,darkcyan :weight bold :extend t))))
     `(magit-section-heading-selection ((,class (:foreground ,orange :weight bold :extend t))))
     `(magit-section-highlight ((,class (:background ,bg-other :extend t))))
     `(magit-section-secondary-heading ((,class (:foreground ,magenta :weight bold :extend t))))
     `(magit-sequence-drop ((,class (:foreground ,red))))
     `(magit-sequence-head ((,class (:foreground ,blue))))
     `(magit-sequence-part ((,class (:foreground ,orange))))
     `(magit-sequence-stop ((,class (:foreground ,green))))
     `(magit-signature-bad ((,class (:foreground ,red))))
     `(magit-signature-error ((,class (:foreground ,red))))
     `(magit-signature-expired ((,class (:foreground ,orange))))
     `(magit-signature-good ((,class (:foreground ,green))))
     `(magit-signature-revoked ((,class (:foreground ,purple))))
     `(magit-signature-untrusted ((,class (:foreground ,yellow))))
     `(magit-tag ((,class (:foreground ,yellow))))

;;;; make-mode - dark
     `(makefile-targets ((,class (:foreground ,blue))))

;;;; marginalia - dark
     `(marginalia-documentation ((,class (:foreground ,blue))))
     `(marginalia-file-name ((,class (:foreground ,blue))))

;;;; markdown-mode - dark
     `(markdown-blockquote-face ((,class (:slant italic :foreground ,spacegrey5))))
     `(markdown-bold-face ((,class (:weight bold :foreground ,orange))))
     `(markdown-code-face ((,class (:background ,bg-org :extend t))))
     `(markdown-header-delimiter-face ((,class (:weight bold :foreground ,orange))))
     `(markdown-header-face-1 ((,class (:weight bold :foreground ,red))))
     `(markdown-header-face-2 ((,class (:weight bold :foreground ,darkcyan))))
     `(markdown-header-face-3 ((,class (:weight bold :foreground ,magenta))))
     `(markdown-header-face-4 ((,class (:weight bold :foreground ,blue))))
     `(markdown-header-face-5 ((,class (:weight bold :foreground ,yellow))))
     `(markdown-html-attr-name-face ((,class (:foreground ,red))))
     `(markdown-html-attr-value-face ((,class (:foreground ,green))))
     `(markdown-html-entity-face ((,class (:foreground ,red))))
     `(markdown-html-tag-delimiter-face ((,class (:foreground ,fg))))
     `(markdown-html-tag-name-face ((,class (:foreground ,magenta))))
     `(markdown-inline-code-face ((,class (:background ,bg-org :foreground ,green))))
     `(markdown-italic-face ((,class (:slant italic :foreground ,magenta))))
     `(markdown-link-face ((,class (:foreground ,orange))))
     `(markdown-list-face ((,class (:foreground ,red))))
     `(markdown-markup-face ((,class (:foreground ,orange))))
     `(markdown-metadata-key-face ((,class (:foreground ,red))))
     `(markdown-pre-face ((,class (:background ,bg-org :foreground ,green))))
     `(markdown-reference-face ((,class (:foreground ,spacegrey5))))
     `(markdown-url-face ((,class (:foreground ,purple :weight normal))))

;;;; message - dark
     `(message-cited-text ((,class (:foreground ,purple))))
     `(message-header-cc ((,class (:foreground ,orange :weight bold))))
     `(message-header-name ((,class (:foreground ,green))))
     `(message-header-newsgroups ((,class (:foreground ,yellow))))
     `(message-header-other ((,class (:foreground ,magenta))))
     `(message-header-subject ((,class (:foreground ,orange :weight bold))))
     `(message-header-to ((,class (:foreground ,orange :weight bold))))
     `(message-header-xheader ((,class (:foreground ,spacegrey5))))
     `(message-mml ((,class (:foreground ,spacegrey5 :slant italic))))
     `(message-separator ((,class (:foreground ,spacegrey5))))

;;;; mic-paren - dark
     `(paren-face-match ((,class (:foreground ,red :background ,spacegrey0 :weight ultra-bold))))
     `(paren-face-mismatch ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))
     `(paren-face-no-match ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))

;;;; minimap - dark
     `(minimap-active-region-background ((,class (:background ,bg))))
     `(minimap-current-line-face ((,class (:background ,grey))))

;;;; mmm-mode - dark
     `(mmm-cleanup-submode-face ((,class (:background ,yellow))))
     `(mmm-code-submode-face ((,class (:background ,bg-other))))
     `(mmm-comment-submode-face ((,class (:background ,blue))))
     `(mmm-declaration-submode-face ((,class (:background ,cyan))))
     `(mmm-default-submode-face ((,class (:background nil))))
     `(mmm-init-submode-face ((,class (:background ,red))))
     `(mmm-output-submode-face ((,class (:background ,magenta))))
     `(mmm-special-submode-face ((,class (:background ,green))))

;;;; mode-line - dark
     `(mode-line ((,class (,@(timu-spacegrey-set-mode-line-active-border spacegrey5 fg) :background ,bg-other :foreground ,fg :distant-foreground ,bg))))
     `(mode-line-buffer-id ((,class (:weight bold))))
     `(mode-line-emphasis ((,class (:foreground ,orange :distant-foreground ,bg))))
     `(mode-line-highlight ((,class (:foreground ,magenta :weight bold :underline ,darkcyan))))
     `(mode-line-inactive ((,class (,@(timu-spacegrey-set-mode-line-inactive-border spacegrey4 spacegrey7) :background ,bg-other :foreground ,spacegrey5 :distant-foreground ,bg-other))))

;;;; mu4e - dark
     `(mu4e-forwarded-face ((,class (:foreground ,yellow))))
     `(mu4e-header-key-face ((,class (:foreground ,darkcyan))))
     `(mu4e-header-title-face ((,class (:foreground ,magenta))))
     `(mu4e-highlight-face ((,class (:foreground ,orange :weight bold))))
     `(mu4e-replied-face ((,class (:foreground ,darkcyan))))
     `(mu4e-title-face ((,class (:foreground ,magenta))))

;;;; mu4e-column-faces - dark
     `(mu4e-column-faces-date ((,class (:foreground ,blue))))
     `(mu4e-column-faces-to-from ((,class (:foreground ,green))))

;;;; mu4e-thread-folding - dark
     `(mu4e-thread-folding-child-face ((,class (:extend t :background ,bg-org :underline nil))))
     `(mu4e-thread-folding-root-folded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))
     `(mu4e-thread-folding-root-unfolded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))

;;;; multiple cursors - dark
     `(mc/cursor-face ((,class (:background ,orange))))

;;;; nano-modeline - dark
     `(nano-modeline-active-name ((,class (:foreground ,fg :weight bold))))
     `(nano-modeline-inactive-name ((,class (:foreground ,spacegrey5 :weight bold))))
     `(nano-modeline-active-primary ((,class (:foreground ,fg))))
     `(nano-modeline-inactive-primary ((,class (:foreground ,spacegrey5))))
     `(nano-modeline-active-secondary ((,class (:foreground ,orange :weight bold))))
     `(nano-modeline-inactive-secondary ((,class (:foreground ,spacegrey5 :weight bold))))
     `(nano-modeline-active-status-RO ((,class (:background ,red :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-RO ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))
     `(nano-modeline-active-status-RW ((,class (:background ,orange :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-RW ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))
     `(nano-modeline-active-status-** ((,class (:background ,red :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-** ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))

;;;; nav-flash - dark
     `(nav-flash-face ((,class (:background ,grey :foreground ,spacegrey8 :weight bold))))

;;;; neotree - dark
     `(neo-dir-link-face ((,class (:foreground ,orange))))
     `(neo-expand-btn-face ((,class (:foreground ,orange))))
     `(neo-file-link-face ((,class (:foreground ,fg))))
     `(neo-root-dir-face ((,class (:foreground ,green :background ,bg :box (:line-width 4 :color ,bg)))))
     `(neo-vc-added-face ((,class (:foreground ,green))))
     `(neo-vc-conflict-face ((,class (:foreground ,purple :weight bold))))
     `(neo-vc-edited-face ((,class (:foreground ,yellow))))
     `(neo-vc-ignored-face ((,class (:foreground ,spacegrey5))))
     `(neo-vc-removed-face ((,class (:foreground ,red :strike-through t))))

;;;; nlinum - dark
     `(nlinum-current-line ((,class (:foreground ,fg))))

;;;; nlinum-hl - dark
     `(nlinum-hl-face ((,class (:foreground ,fg))))

;;;; nlinum-relative - dark
     `(nlinum-relative-current-face ((,class (:foreground ,fg))))

;;;; notmuch - dark
     `(notmuch-message-summary-face ((,class (:foreground ,grey :background nil))))
     `(notmuch-search-count ((,class (:foreground ,spacegrey5))))
     `(notmuch-search-date ((,class (:foreground ,orange))))
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
     `(notmuch-tree-match-date-face ((,class (:foreground ,orange :weight bold))))
     `(notmuch-tree-match-face ((,class (:foreground ,fg))))
     `(notmuch-tree-match-subject-face ((,class (:foreground ,fg))))
     `(notmuch-tree-match-tag-face ((,class (:foreground ,yellow))))
     `(notmuch-tree-match-tree-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-author-face ((,class (:foreground ,blue))))
     `(notmuch-tree-no-match-date-face ((,class (:foreground ,orange))))
     `(notmuch-tree-no-match-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-subject-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-tag-face ((,class (:foreground ,yellow))))
     `(notmuch-tree-no-match-tree-face ((,class (:foreground ,yellow))))
     `(notmuch-wash-cited-text ((,class (:foreground ,spacegrey4))))
     `(notmuch-wash-toggle-button ((,class (:foreground ,fg))))

;;;; orderless - dark
     `(orderless-match-face-0 ((,class (:foreground ,teal :weight bold :underline t))))
     `(orderless-match-face-1 ((,class (:foreground ,darkcyan :weight bold :underline t))))
     `(orderless-match-face-2 ((,class (:foreground ,cyan :weight bold :underline t))))
     `(orderless-match-face-3 ((,class (:foreground ,green :weight bold :underline t))))

;;;; objed - dark
     `(objed-hl ((,class (:background ,grey))))
     `(objed-mode-line ((,class (:foreground ,yellow :weight bold))))

;;;; org-agenda - dark
     `(org-agenda-clocking ((,class (:background ,blue))))
     `(org-agenda-date ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-date-today ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-date-weekend ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-dimmed-todo-face ((,class (:foreground ,spacegrey5))))
     `(org-agenda-done ((,class (:foreground ,spacegrey5))))
     `(org-agenda-structure ((,class (:foreground ,fg :weight ultra-bold))))
     `(org-scheduled ((,class (:foreground ,fg))))
     `(org-scheduled-previously ((,class (:foreground ,spacegrey8))))
     `(org-scheduled-today ((,class (:foreground ,spacegrey7))))
     `(org-sexp-date ((,class (:foreground ,fg))))
     `(org-time-grid ((,class (:foreground ,spacegrey5))))
     `(org-upcoming-deadline ((,class (:foreground ,fg))))
     `(org-upcoming-distant-deadline ((,class (:foreground ,fg))))

;;;; org-habit - dark
     `(org-habit-alert-face ((,class (:weight bold :background ,yellow))))
     `(org-habit-alert-future-face ((,class (:weight bold :background ,yellow))))
     `(org-habit-clear-face ((,class (:weight bold :background ,spacegrey4))))
     `(org-habit-clear-future-face ((,class (:weight bold :background ,spacegrey3))))
     `(org-habit-overdue-face ((,class (:weight bold :background ,red))))
     `(org-habit-overdue-future-face ((,class (:weight bold :background ,red))))
     `(org-habit-ready-face ((,class (:weight bold :background ,blue))))
     `(org-habit-ready-future-face ((,class (:weight bold :background ,blue))))

;;;; org-journal - dark
     `(org-journal-calendar-entry-face ((,class (:foreground ,purple :slant italic))))
     `(org-journal-calendar-scheduled-face ((,class (:foreground ,red :slant italic))))
     `(org-journal-highlight ((,class (:foreground ,orange))))

;;;; org-mode - dark
     `(org-archived ((,class (:foreground ,spacegrey5))))
     `(org-block ((,class (:foreground ,spacegrey8 :background ,bg-org :extend t))))
     `(org-block-background ((,class (:background ,bg-org :extend t))))
     `(org-block-begin-line ((,class (:foreground ,spacegrey5 :slant italic :background ,bg-org :extend t ,@(timu-spacegrey-set-intense-org-colors bg bg-other)))))
     `(org-block-end-line ((,class (:foreground ,spacegrey5 :slant italic :background ,bg-org :extend t ,@(timu-spacegrey-set-intense-org-colors bg-other bg-other)))))
     `(org-checkbox ((,class (:foreground ,green :weight bold))))
     `(org-checkbox-statistics-done ((,class (:foreground ,spacegrey5))))
     `(org-checkbox-statistics-todo ((,class (:foreground ,green :weight bold))))
     `(org-code ((,class (:foreground ,green ,@(timu-spacegrey-set-intense-org-colors bg bg-other)))))
     `(org-date ((,class (:foreground ,yellow))))
     `(org-default ((,class (:background ,bg :foreground ,fg))))
     `(org-document-info ((,class (:foreground ,orange ,@(timu-spacegrey-do-scale timu-spacegrey-scale-org-document-info 1.2) ,@(timu-spacegrey-set-intense-org-colors bg bg-other)))))
     `(org-document-title ((,class (:foreground ,orange :weight bold ,@(timu-spacegrey-do-scale timu-spacegrey-scale-org-document-title 1.3) ,@(timu-spacegrey-set-intense-org-colors orange bg-other)))))
     `(org-done ((,class (:foreground ,spacegrey5))))
     `(org-ellipsis ((,class (:underline nil :background nil :foreground ,grey))))
     `(org-footnote ((,class (:foreground ,orange))))
     `(org-formula ((,class (:foreground ,cyan))))
     `(org-headline-done ((,class (:foreground ,spacegrey5))))
     `(org-hide ((,class (:foreground ,bg))))
     `(org-latex-and-related ((,class (:foreground ,spacegrey8 :weight bold))))
     `(org-level-1 ((,class (:foreground ,blue :weight ultra-bold ,@(timu-spacegrey-do-scale timu-spacegrey-scale-org-document-info 1.3) ,@(timu-spacegrey-set-intense-org-colors blue bg-other)))))
     `(org-level-2 ((,class (:foreground ,magenta :weight bold ,@(timu-spacegrey-do-scale timu-spacegrey-scale-org-document-info 1.2) ,@(timu-spacegrey-set-intense-org-colors magenta bg-other)))))
     `(org-level-3 ((,class (:foreground ,darkcyan :weight bold ,@(timu-spacegrey-do-scale timu-spacegrey-scale-org-document-info 1.1) ,@(timu-spacegrey-set-intense-org-colors darkcyan bg-other)))))
     `(org-level-4 ((,class (:foreground ,orange))))
     `(org-level-5 ((,class (:foreground ,green))))
     `(org-level-6 ((,class (:foreground ,teal))))
     `(org-level-7 ((,class (:foreground ,purple))))
     `(org-level-8 ((,class (:foreground ,fg))))
     `(org-link ((,class (:foreground ,darkcyan :underline t))))
     `(org-list-dt ((,class (:foreground ,orange))))
     `(org-meta-line ((,class (:foreground ,spacegrey5))))
     `(org-priority ((,class (:foreground ,red))))
     `(org-property-value ((,class (:foreground ,spacegrey5))))
     `(org-quote ((,class (:background ,spacegrey3 :slant italic :extend t))))
     `(org-special-keyword ((,class (:foreground ,spacegrey5))))
     `(org-table ((,class (:foreground ,magenta))))
     `(org-tag ((,class (:foreground ,spacegrey5 :weight normal))))
     `(org-todo ((,class (:foreground ,green :weight bold))))
     `(org-verbatim ((,class (:foreground ,orange ,@(timu-spacegrey-set-intense-org-colors bg bg-other)))))
     `(org-warning ((,class (:foreground ,yellow))))

;;;; org-pomodoro - dark
     `(org-pomodoro-mode-line ((,class (:foreground ,red))))
     `(org-pomodoro-mode-line-overtime ((,class (:foreground ,yellow :weight bold))))

;;;; org-ref - dark
     `(org-ref-acronym-face ((,class (:foreground ,magenta))))
     `(org-ref-cite-face ((,class (:foreground ,yellow :weight light :underline t))))
     `(org-ref-glossary-face ((,class (:foreground ,purple))))
     `(org-ref-label-face ((,class (:foreground ,blue))))
     `(org-ref-ref-face ((,class (:foreground ,teal :underline t :weight bold))))

;;;; outline - dark
     `(outline-1 ((,class (:foreground ,blue :weight ultra-bold))))
     `(outline-2 ((,class (:foreground ,magenta :weight bold))))
     `(outline-3 ((,class (:foreground ,green :weight bold))))
     `(outline-4 ((,class (:foreground ,orange))))
     `(outline-5 ((,class (:foreground ,purple))))
     `(outline-6 ((,class (:foreground ,purple))))
     `(outline-7 ((,class (:foreground ,purple))))
     `(outline-8 ((,class (:foreground ,fg))))

;;;; parenface - dark
     `(paren-face ((,class (:foreground ,spacegrey5))))

;;;; parinfer - dark
     `(parinfer-pretty-parens:dim-paren-face ((,class (:foreground ,spacegrey5))))
     `(parinfer-smart-tab:indicator-face ((,class (:foreground ,spacegrey5))))

;;;; persp-mode - dark
     `(persp-face-lighter-buffer-not-in-persp ((,class (:foreground ,spacegrey5))))
     `(persp-face-lighter-default ((,class (:foreground ,orange :weight bold))))
     `(persp-face-lighter-nil-persp ((,class (:foreground ,spacegrey5))))

;;;; perspective - dark
     `(persp-selected-face ((,class (:foreground ,blue :weight bold))))

;;;; pkgbuild-mode - dark
     `(pkgbuild-error-face ((,class (:underline (:style wave :color ,red)))))

;;;; popup - dark
     `(popup-face ((,class (:background ,bg-other :foreground ,fg))))
     `(popup-selection-face ((,class (:background ,grey))))
     `(popup-tip-face ((,class (:foreground ,magenta :background ,bg-other))))

;;;; powerline - dark
     `(powerline-active0 ((,class (:background ,bg-other :foreground ,fg :distant-foreground ,bg))))
     `(powerline-active1 ((,class (:background ,bg-other :foreground ,fg :distant-foreground ,bg))))
     `(powerline-active2 ((,class (:background ,bg-other :foreground ,fg :distant-foreground ,bg))))
     `(powerline-inactive0 ((,class (:background ,bg-other :foreground ,spacegrey5 :distant-foreground ,bg-other))))
     `(powerline-inactive1 ((,class (:background ,bg-other :foreground ,spacegrey5 :distant-foreground ,bg-other))))
     `(powerline-inactive2 ((,class (:background ,bg-other :foreground ,spacegrey5 :distant-foreground ,bg-other))))

;;;; rainbow-delimiters - dark
     `(rainbow-delimiters-depth-1-face ((,class (:foreground ,blue))))
     `(rainbow-delimiters-depth-2-face ((,class (:foreground ,purple))))
     `(rainbow-delimiters-depth-3-face ((,class (:foreground ,green))))
     `(rainbow-delimiters-depth-4-face ((,class (:foreground ,orange))))
     `(rainbow-delimiters-depth-5-face ((,class (:foreground ,magenta))))
     `(rainbow-delimiters-depth-6-face ((,class (:foreground ,yellow))))
     `(rainbow-delimiters-depth-7-face ((,class (:foreground ,teal))))
     `(rainbow-delimiters-mismatched-face ((,class (:foreground ,red :weight bold :inverse-video t))))
     `(rainbow-delimiters-unmatched-face ((,class (:foreground ,red :weight bold :inverse-video t))))

;;;; re-builder - dark
     `(reb-match-0 ((,class (:foreground ,orange :inverse-video t))))
     `(reb-match-1 ((,class (:foreground ,purple :inverse-video t))))
     `(reb-match-2 ((,class (:foreground ,green :inverse-video t))))
     `(reb-match-3 ((,class (:foreground ,yellow :inverse-video t))))

;;;; rjsx-mode - dark
     `(rjsx-attr ((,class (:foreground ,blue))))
     `(rjsx-tag ((,class (:foreground ,yellow))))

;;;; rpm-spec-mode - dark
     `(rpm-spec-dir-face ((,class (:foreground ,green))))
     `(rpm-spec-doc-face ((,class (:foreground ,orange))))
     `(rpm-spec-ghost-face ((,class (:foreground ,spacegrey5))))
     `(rpm-spec-macro-face ((,class (:foreground ,yellow))))
     `(rpm-spec-obsolete-tag-face ((,class (:foreground ,red))))
     `(rpm-spec-package-face ((,class (:foreground ,orange))))
     `(rpm-spec-section-face ((,class (:foreground ,purple))))
     `(rpm-spec-tag-face ((,class (:foreground ,blue))))
     `(rpm-spec-var-face ((,class (:foreground ,magenta))))

;;;; rst - dark
     `(rst-block ((,class (:foreground ,orange))))
     `(rst-level-1 ((,class (:foreground ,magenta :weight bold))))
     `(rst-level-2 ((,class (:foreground ,magenta :weight bold))))
     `(rst-level-3 ((,class (:foreground ,magenta :weight bold))))
     `(rst-level-4 ((,class (:foreground ,magenta :weight bold))))
     `(rst-level-5 ((,class (:foreground ,magenta :weight bold))))
     `(rst-level-6 ((,class (:foreground ,magenta :weight bold))))

;;;; selectrum - dark
     `(selectrum-current-candidate ((,class (:background ,grey :distant-foreground nil :extend t))))

;;;; sh-script - dark
     `(sh-heredoc ((,class (:foreground ,green))))
     `(sh-quoted-exec ((,class (:foreground ,fg :weight bold))))

;;;; show-paren - dark
     `(show-paren-match ((,class (:foreground ,red :weight ultra-bold :underline ,red))))
     `(show-paren-mismatch ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))

;;;; smart-mode-line - dark
     `(sml/charging ((,class (:foreground ,green))))
     `(sml/discharging ((,class (:foreground ,yellow :weight bold))))
     `(sml/filename ((,class (:foreground ,magenta :weight bold))))
     `(sml/git ((,class (:foreground ,blue))))
     `(sml/modified ((,class (:foreground ,cyan))))
     `(sml/outside-modified ((,class (:foreground ,cyan))))
     `(sml/process ((,class (:weight bold))))
     `(sml/read-only ((,class (:foreground ,cyan))))
     `(sml/sudo ((,class (:foreground ,orange :weight bold))))
     `(sml/vc-edited ((,class (:foreground ,green))))

;;;; smartparens - dark
     `(sp-pair-overlay-face ((,class (:background ,grey))))
     `(sp-show-pair-match-face ((,class (:foreground ,red :background ,spacegrey0 :weight ultra-bold))))
     `(sp-show-pair-mismatch-face ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))

;;;; smerge-tool - dark
     `(smerge-base ((,class (:background ,blue))))
     `(smerge-lower ((,class (:background ,green))))
     `(smerge-markers ((,class (:background ,spacegrey5 :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(smerge-mine ((,class (:background ,red))))
     `(smerge-other ((,class (:background ,green))))
     `(smerge-refined-added ((,class (:foreground ,bg  :background ,green :extend t))))
     `(smerge-refined-removed ((,class (:foreground ,bg :background ,red :extend t))))
     `(smerge-upper ((,class (:background ,red))))

;;;; solaire-mode - dark
     `(solaire-default-face ((,class (:foreground ,fg :background ,bg-other))))
     `(solaire-hl-line-face ((,class (:background ,bg-other :extend t))))
     `(solaire-mode-line-face ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))
     `(solaire-mode-line-inactive-face ((,class (:background ,bg-other :foreground ,fg-other :distant-foreground ,bg-other))))
     `(solaire-org-hide-face ((,class (:foreground ,bg))))

;;;; spaceline - dark
     `(spaceline-evil-emacs ((,class (:background ,cyan))))
     `(spaceline-evil-insert ((,class (:background ,green))))
     `(spaceline-evil-motion ((,class (:background ,purple))))
     `(spaceline-evil-normal ((,class (:background ,blue))))
     `(spaceline-evil-replace ((,class (:background ,orange))))
     `(spaceline-evil-visual ((,class (:background ,grey))))
     `(spaceline-flycheck-error ((,class (:foreground ,red :distant-background ,spacegrey0))))
     `(spaceline-flycheck-info ((,class (:foreground ,green :distant-background ,spacegrey0))))
     `(spaceline-flycheck-warning ((,class (:foreground ,yellow :distant-background ,spacegrey0))))
     `(spaceline-highlight-face ((,class (:background ,orange))))
     `(spaceline-modified ((,class (:background ,orange))))
     `(spaceline-python-venv ((,class (:foreground ,purple :distant-foreground ,magenta))))
     `(spaceline-unmodified ((,class (:background ,orange))))

;;;; stripe-buffer - dark
     `(stripe-highlight ((,class (:background ,spacegrey3))))

;;;; swiper - dark
     `(swiper-line-face ((,class (:background ,blue :foreground ,spacegrey0))))
     `(swiper-match-face-1 ((,class (:background ,spacegrey0 :foreground ,spacegrey5))))
     `(swiper-match-face-2 ((,class (:background ,orange :foreground ,spacegrey0 :weight bold))))
     `(swiper-match-face-3 ((,class (:background ,purple :foreground ,spacegrey0 :weight bold))))
     `(swiper-match-face-4 ((,class (:background ,green :foreground ,spacegrey0 :weight bold))))

;;;; tabbar - dark
     `(tabbar-button ((,class (:foreground ,fg :background ,bg))))
     `(tabbar-button-highlight ((,class (:foreground ,fg :background ,bg :inverse-video t))))
     `(tabbar-default ((,class (:foreground ,fg :background ,bg :height 1.0))))
     `(tabbar-highlight ((,class (:foreground ,fg :background ,grey :distant-foreground ,bg))))
     `(tabbar-modified ((,class (:foreground ,red :weight bold :height 1.0))))
     `(tabbar-selected ((,class (:weight bold :foreground ,fg :background ,bg-other :height 1.0))))
     `(tabbar-selected-modified ((,class (:background ,bg-other  :foreground ,green))))
     `(tabbar-unselected ((,class (:foreground ,spacegrey5))))
     `(tabbar-unselected-modified ((,class (:foreground ,red :weight bold :height 1.0))))

;;;; tab-bar - dark
     `(tab-bar ((,class (:background ,bg-other :foreground ,bg-other))))
     `(tab-bar-tab ((,class (:background ,bg :foreground ,fg))))
     `(tab-bar-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; tab-line - dark
     `(tab-line ((,class (:background ,bg-other :foreground ,bg-other))))
     `(tab-line-close-highlight ((,class (:foreground ,orange))))
     `(tab-line-highlight ((,class (:background ,bg :foreground ,fg))))
     `(tab-line-tab ((,class (:background ,bg :foreground ,fg))))
     `(tab-line-tab-current ((,class (:background ,bg :foreground ,fg))))
     `(tab-line-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; telephone-line - dark
     `(telephone-line-accent-active ((,class (:foreground ,fg :background ,spacegrey4))))
     `(telephone-line-accent-inactive ((,class (:foreground ,fg :background ,spacegrey2))))
     `(telephone-line-evil ((,class (:foreground ,fg :weight bold))))
     `(telephone-line-evil-emacs ((,class (:background ,purple :weight bold))))
     `(telephone-line-evil-insert ((,class (:background ,green :weight bold))))
     `(telephone-line-evil-motion ((,class (:background ,blue :weight bold))))
     `(telephone-line-evil-normal ((,class (:background ,red :weight bold))))
     `(telephone-line-evil-operator ((,class (:background ,magenta :weight bold))))
     `(telephone-line-evil-replace ((,class (:background ,bg-other :weight bold))))
     `(telephone-line-evil-visual ((,class (:background ,orange :weight bold))))
     `(telephone-line-projectile ((,class (:foreground ,green))))

;;;; term - dark
     `(term ((,class (:foreground ,fg))))
     `(term-bold ((,class (:weight bold))))
     `(term-color-black ((,class (:foreground ,spacegrey0))))
     `(term-color-blue ((,class (:foreground ,blue))))
     `(term-color-cyan ((,class (:foreground ,cyan))))
     `(term-color-green ((,class (:foreground ,green))))
     `(term-color-magenta ((,class (:foreground ,magenta))))
     `(term-color-purple ((,class (:foreground ,purple))))
     `(term-color-red ((,class (:foreground ,red))))
     `(term-color-white ((,class (:foreground ,spacegrey8))))
     `(term-color-yellow ((,class (:foreground ,yellow))))
     `(term-color-bright-black ((,class (:foreground ,spacegrey0))))
     `(term-color-bright-blue ((,class (:foreground ,blue))))
     `(term-color-bright-cyan ((,class (:foreground ,cyan))))
     `(term-color-bright-green ((,class (:foreground ,green))))
     `(term-color-bright-magenta ((,class (:foreground ,magenta))))
     `(term-color-bright-purple ((,class (:foreground ,purple))))
     `(term-color-bright-red ((,class (:foreground ,red))))
     `(term-color-bright-white ((,class (:foreground ,spacegrey8))))
     `(term-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; tldr - dark
     `(tldr-code-block ((,class (:foreground ,green :background ,grey :weight semi-bold))))
     `(tldr-command-argument ((,class (:foreground ,fg :background ,grey))))
     `(tldr-command-itself ((,class (:foreground ,bg :background ,green :weight semi-bold))))
     `(tldr-description ((,class (:foreground ,fg :weight semi-bold))))
     `(tldr-introduction ((,class (:foreground ,blue :weight semi-bold))))
     `(tldr-title ((,class (:foreground ,yellow :bold t :height 1.4))))

;;;; treemacs - dark
     `(treemacs-directory-face ((,class (:foreground ,fg))))
     `(treemacs-file-face ((,class (:foreground ,fg))))
     `(treemacs-git-added-face ((,class (:foreground ,green))))
     `(treemacs-git-conflict-face ((,class (:foreground ,red))))
     `(treemacs-git-modified-face ((,class (:foreground ,magenta))))
     `(treemacs-git-untracked-face ((,class (:foreground ,spacegrey5 :slant italic))))
     `(treemacs-root-face ((,class (:foreground ,green :weight bold :height 1.2))))
     `(treemacs-tags-face ((,class (:foreground ,orange))))

;;;; treemacs-all-the-icons - dark
     `(treemacs-all-the-icons-file-face ((,class (:foreground ,blue))))
     `(treemacs-all-the-icons-root-face ((,class (:foreground ,fg))))

;;;; tree-sitter-hl - dark
     `(tree-sitter-hl-face:function ((,class (:foreground ,blue))))
     `(tree-sitter-hl-face:function.call ((,class (:foreground ,blue))))
     `(tree-sitter-hl-face:function.builtin ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:function.special ((,class (:foreground ,fg :weight bold))))
     `(tree-sitter-hl-face:function.macro ((,class (:foreground ,fg :weight bold))))
     `(tree-sitter-hl-face:method ((,class (:foreground ,blue))))
     `(tree-sitter-hl-face:method.call ((,class (:foreground ,red))))
     `(tree-sitter-hl-face:type ((,class (:foreground ,yellow))))
     `(tree-sitter-hl-face:type.parameter ((,class (:foreground ,darkcyan))))
     `(tree-sitter-hl-face:type.argument ((,class (:foreground ,yellow))))
     `(tree-sitter-hl-face:type.builtin ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:type.super ((,class (:foreground ,yellow))))
     `(tree-sitter-hl-face:constructor ((,class (:foreground ,yellow))))
     `(tree-sitter-hl-face:variable ((,class (:foreground ,darkcyan))))
     `(tree-sitter-hl-face:variable.parameter ((,class (:foreground ,darkcyan))))
     `(tree-sitter-hl-face:variable.builtin ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:variable.special ((,class (:foreground ,yellow))))
     `(tree-sitter-hl-face:property ((,class (:foreground ,magenta))))
     `(tree-sitter-hl-face:property.definition ((,class (:foreground ,darkcyan))))
     `(tree-sitter-hl-face:comment ((,class (:foreground ,spacegrey5 :slant italic))))
     `(tree-sitter-hl-face:doc ((,class (:foreground ,spacegrey5 :slant italic))))
     `(tree-sitter-hl-face:string ((,class (:foreground ,green))))
     `(tree-sitter-hl-face:string.special ((,class (:foreground ,green :weight bold))))
     `(tree-sitter-hl-face:escape ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:embedded ((,class (:foreground ,fg))))
     `(tree-sitter-hl-face:keyword ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:operator ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:label ((,class (:foreground ,fg))))
     `(tree-sitter-hl-face:constant ((,class (:foreground ,magenta))))
     `(tree-sitter-hl-face:constant.builtin ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:number ((,class (:foreground ,magenta))))
     `(tree-sitter-hl-face:punctuation ((,class (:foreground ,fg))))
     `(tree-sitter-hl-face:punctuation.bracket ((,class (:foreground ,fg))))
     `(tree-sitter-hl-face:punctuation.delimiter ((,class (:foreground ,fg))))
     `(tree-sitter-hl-face:punctuation.special ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:tag ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:attribute ((,class (:foreground ,fg))))

;;;; typescript-mode - dark
     `(typescript-jsdoc-tag ((,class (:foreground ,spacegrey5))))
     `(typescript-jsdoc-type ((,class (:foreground ,spacegrey5))))
     `(typescript-jsdoc-value ((,class (:foreground ,spacegrey5))))

;;;; undo-tree - dark
     `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,blue))))
     `(undo-tree-visualizer-current-face ((,class (:foreground ,green :weight bold))))
     `(undo-tree-visualizer-default-face ((,class (:foreground ,spacegrey5))))
     `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow))))
     `(undo-tree-visualizer-unmodified-face ((,class (:foreground ,spacegrey5))))

;;;; vimish-fold - dark
     `(vimish-fold-fringe ((,class (:foreground ,purple))))
     `(vimish-fold-overlay ((,class (:foreground ,spacegrey5 :slant italic :background ,spacegrey0 :weight light))))

;;;; volatile-highlights - dark
     `(vhl/default-face ((,class (:background ,grey))))

;;;; vterm - dark
     `(vterm ((,class (:foreground ,fg))))
     `(vterm-color-black ((,class (:background ,spacegrey0 :foreground ,spacegrey0))))
     `(vterm-color-blue ((,class (:background ,blue :foreground ,blue))))
     `(vterm-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
     `(vterm-color-default ((,class (:foreground ,fg))))
     `(vterm-color-green ((,class (:background ,green :foreground ,green))))
     `(vterm-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
     `(vterm-color-purple ((,class (:background ,purple :foreground ,purple))))
     `(vterm-color-red ((,class (:background ,red :foreground ,red))))
     `(vterm-color-white ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))
     `(vterm-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

;;;; web-mode - dark
     `(web-mode-block-control-face ((,class (:foreground ,orange))))
     `(web-mode-block-control-face ((,class (:foreground ,orange))))
     `(web-mode-block-delimiter-face ((,class (:foreground ,orange))))
     `(web-mode-css-property-name-face ((,class (:foreground ,yellow))))
     `(web-mode-doctype-face ((,class (:foreground ,spacegrey5))))
     `(web-mode-html-attr-name-face ((,class (:foreground ,yellow))))
     `(web-mode-html-attr-value-face ((,class (:foreground ,green))))
     `(web-mode-html-entity-face ((,class (:foreground ,cyan :slant italic))))
     `(web-mode-html-tag-bracket-face ((,class (:foreground ,blue))))
     `(web-mode-html-tag-bracket-face ((,class (:foreground ,fg))))
     `(web-mode-html-tag-face ((,class (:foreground ,blue))))
     `(web-mode-json-context-face ((,class (:foreground ,green))))
     `(web-mode-json-key-face ((,class (:foreground ,green))))
     `(web-mode-keyword-face ((,class (:foreground ,magenta))))
     `(web-mode-string-face ((,class (:foreground ,green))))
     `(web-mode-type-face ((,class (:foreground ,yellow))))

;;;; wgrep - dark
     `(wgrep-delete-face ((,class (:foreground ,spacegrey3 :background ,red))))
     `(wgrep-done-face ((,class (:foreground ,blue))))
     `(wgrep-face ((,class (:weight bold :foreground ,green :background ,spacegrey5))))
     `(wgrep-file-face ((,class (:foreground ,spacegrey5))))
     `(wgrep-reject-face ((,class (:foreground ,red :weight bold))))

;;;; which-func - dark
     `(which-func ((,class (:foreground ,blue))))

;;;; which-key - dark
     `(which-key-command-description-face ((,class (:foreground ,blue))))
     `(which-key-group-description-face ((,class (:foreground ,magenta))))
     `(which-key-key-face ((,class (:foreground ,green))))
     `(which-key-local-map-description-face ((,class (:foreground ,purple))))

;;;; whitespace - dark
     `(whitespace-empty ((,class (:background ,spacegrey3))))
     `(whitespace-indentation ((,class (:foreground ,spacegrey4 :background ,spacegrey3))))
     `(whitespace-line ((,class (:background ,spacegrey0 :foreground ,red :weight bold))))
     `(whitespace-newline ((,class (:foreground ,spacegrey4))))
     `(whitespace-space ((,class (:foreground ,spacegrey4))))
     `(whitespace-tab ((,class (:foreground ,spacegrey4 :background ,spacegrey3))))
     `(whitespace-trailing ((,class (:background ,red))))

;;;; widget - dark
     `(widget-button ((,class (:foreground ,fg :weight bold))))
     `(widget-button-pressed ((,class (:foreground ,red))))
     `(widget-documentation ((,class (:foreground ,green))))
     `(widget-field ((,class (:foreground ,fg :background ,spacegrey0 :extend nil))))
     `(widget-inactive ((,class (:foreground ,grey :background ,bg-other))))
     `(widget-single-line-field ((,class (:foreground ,fg :background ,spacegrey0))))

;;;; window-divider - dark
     `(window-divider ((,class (:background ,spacegrey4 :foreground ,spacegrey4))))
     `(window-divider-first-pixel ((,class (:background ,spacegrey4 :foreground ,spacegrey4))))
     `(window-divider-last-pixel ((,class (:background ,spacegrey4 :foreground ,spacegrey4))))

;;;; woman - dark
     `(woman-bold ((,class (:weight bold :foreground ,fg))))
     `(woman-italic ((,class (:underline t :foreground ,magenta))))

;;;; workgroups2 - dark
     `(wg-brace-face ((,class (:foreground ,orange))))
     `(wg-current-workgroup-face ((,class (:foreground ,spacegrey0 :background ,orange))))
     `(wg-divider-face ((,class (:foreground ,grey))))
     `(wg-other-workgroup-face ((,class (:foreground ,spacegrey5))))

;;;; yasnippet - dark
     `(yas-field-highlight-face ((,class (:foreground ,green :background ,spacegrey0 :weight bold))))

;;;; ytel - dark
     `(ytel-video-published-face ((,class (:foreground ,magenta))))
     `(ytel-channel-name-face ((,class (:foreground ,orange))))
     `(ytel-video-length-face ((,class (:foreground ,blue))))
     `(ytel-video-view-face ((,class (:foreground ,darkcyan))))

     (custom-theme-set-variables
      'timu-spacegrey
      `(ansi-color-names-vector [bg, red, green, teal, cyan, blue, yellow, fg])))))

;;; LIGHT FLAVOUR
(when (equal timu-spacegrey-flavour "light")
  (let ((class '((class color) (min-colors 89)))
        (bg          "#ffffff")
        (bg-org      "#fafafa")
        (bg-other    "#dfdfdf")
        (spacegrey0  "#1b2229")
        (spacegrey1  "#1c1f24")
        (spacegrey2  "#202328")
        (spacegrey3  "#2f3237")
        (spacegrey4  "#4f5b66")
        (spacegrey5  "#65737e")
        (spacegrey6  "#73797e")
        (spacegrey7  "#9ca0a4")
        (spacegrey8  "#dfdfdf")
        (fg          "#2b303b")
        (fg-other    "#232830")

        (grey        "#4f5b66")
        (red         "#bf616a")
        (orange      "#d08770")
        (green       "#a3be8c")
        (blue        "#8fa1b3")
        (magenta     "#b48ead")
        (teal        "#4db5bd")
        (yellow      "#ecbe7b")
        (darkblue    "#2257a0")
        (purple      "#c678dd")
        (cyan        "#46d9ff")
        (lightcyan   "#88c0d0")
        (darkcyan    "#5699af")

        (l-grey      "#f3f3f3")
        (l-red       "#ffbbc4")
        (l-orange    "#ffe1ca")
        (l-green     "#fdffe6")
        (l-blue      "#e9fbff")
        (l-magenta   "#ffe8ff")
        (l-teal      "#a7ffff")
        (l-yellow    "#ffffd5")
        (l-darkblue  "#7cb1fa")
        (l-purple    "#ffd2ff")
        (l-cyan      "#a0ffff")
        (l-lightcyan "#e2ffff")
        (l-darkcyan  "#b0f3ff")

        (black       "#000000")
        (white       "#ffffff"))

    (custom-theme-set-faces
     'timu-spacegrey

;;; Custom faces - light

;;;; timu-spacegrey-faces - light
     `(timu-spacegrey-default-face ((,class (:background ,bg :foreground ,fg))))
     `(timu-spacegrey-bold-face ((,class (:weight bold :foreground ,spacegrey0))))
     `(timu-spacegrey-bold-face-italic ((,class (:weight bold :slant italic :foreground ,spacegrey0))))
     `(timu-spacegrey-italic-face ((,class (:slant italic :foreground ,black))))
     `(timu-spacegrey-underline-face ((,class (:underline ,red))))
     `(timu-spacegrey-strike-through-face ((,class (:strike-through ,red))))

;;;; default faces - light
     `(bold ((,class (:weight bold))))
     `(bold-italic ((,class (:weight bold :slant italic))))
     `(bookmark-face ((,class (:foreground ,magenta  :weight bold :underline ,darkcyan))))
     `(cursor ((,class (:background ,orange))))
     `(default ((,class (:background ,bg :foreground ,fg))))
     `(error ((,class (:foreground ,red))))
     `(fringe ((,class (:background ,bg :foreground ,spacegrey4))))
     `(highlight ((,class (:foreground ,magenta  :weight bold :underline ,darkcyan))))
     `(italic ((,class (:slant  italic))))
     `(lazy-highlight ((,class (:background ,blue  :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(link ((,class (:foreground ,orange :underline t :weight bold))))
     `(match ((,class (:foreground ,green :background ,spacegrey0 :weight bold))))
     `(minibuffer-prompt ((,class (:foreground ,orange))))
     `(nobreak-space ((,class (:background ,bg :foreground ,fg :underline nil))))
     `(region ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
     `(secondary-selection ((,class (:background ,grey :extend t))))
     `(shadow ((,class (:foreground ,spacegrey5))))
     `(success ((,class (:foreground ,green))))
     `(tooltip ((,class (:background ,bg-other :foreground ,fg))))
     `(trailing-whitespace ((,class (:background ,red))))
     `(vertical-border ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))
     `(warning ((,class (:foreground ,yellow))))

;;;; font-lock - light
     `(font-lock-builtin-face ((,class (:foreground ,orange))))
     `(font-lock-comment-delimiter-face ((,class (:foreground ,spacegrey5))))
     `(font-lock-comment-face ((,class (:foreground ,spacegrey5 :slant italic))))
     `(font-lock-constant-face ((,class (:foreground ,magenta))))
     `(font-lock-doc-face ((,class (:foreground ,spacegrey5 :slant italic))))
     `(font-lock-function-name-face ((,class (:foreground ,darkblue))))
     `(font-lock-keyword-face ((,class (:foreground ,orange))))
     `(font-lock-negation-char-face ((,class (:foreground ,fg :weigth bold))))
     `(font-lock-preprocessor-char-face ((,class (:foreground ,fg :weight bold))))
     `(font-lock-preprocessor-face ((,class (:foreground ,fg :weight bold))))
     `(font-lock-regexp-grouping-backslash ((,class (:foreground ,fg :weight bold))))
     `(font-lock-regexp-grouping-construct ((,class (:foreground ,fg :weight bold))))
     `(font-lock-string-face ((,class (:foreground ,green))))
     `(font-lock-type-face ((,class (:foreground ,yellow))))
     `(font-lock-variable-name-face ((,class (:foreground ,red))))
     `(font-lock-warning-face ((,class (:foreground ,yellow))))

;;;; ace-window - light
     `(aw-leading-char-face ((,class (:foreground ,orange :height 500 :weight bold))))
     `(aw-background-face ((,class (:foreground ,spacegrey5))))

;;;; agda-mode - light
     `(agda2-highlight-bound-variable-face ((,class (:foreground ,red))))
     `(agda2-highlight-coinductive-constructor-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-datatype-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-dotted-face ((,class (:foreground ,red))))
     `(agda2-highlight-error-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-field-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-function-face ((,class (:foreground ,darkblue))))
     `(agda2-highlight-incomplete-pattern-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-inductive-constructor-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-keyword-face ((,class (:foreground ,magenta))))
     `(agda2-highlight-macro-face ((,class (:foreground ,darkblue))))
     `(agda2-highlight-module-face ((,class (:foreground ,red))))
     `(agda2-highlight-number-face ((,class (:foreground ,green))))
     `(agda2-highlight-positivity-problem-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-postulate-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-primitive-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-primitive-type-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-record-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-string-face ((,class (:foreground ,green))))
     `(agda2-highlight-symbol-face ((,class (:foreground ,red))))
     `(agda2-highlight-termination-problem-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-typechecks-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-unsolved-constraint-face ((,class (:foreground ,yellow))))
     `(agda2-highlight-unsolved-meta-face ((,class (:foreground ,yellow))))

;;;; alert - light
     `(alert-high-face ((,class (:weight bold :foreground ,yellow))))
     `(alert-low-face ((,class (:foreground ,grey))))
     `(alert-moderate-face ((,class (:weight bold :foreground ,fg-other))))
     `(alert-trivial-face ((,class (:foreground ,spacegrey5))))
     `(alert-urgent-face ((,class (:weight bold :foreground ,red))))

;;;; all-the-icons - light
     `(all-the-icons-blue ((,class (:foreground ,darkblue))))
     `(all-the-icons-blue-alt ((,class (:foreground ,teal))))
     `(all-the-icons-cyan ((,class (:foreground ,cyan))))
     `(all-the-icons-cyan-alt ((,class (:foreground ,cyan))))
     `(all-the-icons-dblue ((,class (:foreground ,darkblue))))
     `(all-the-icons-dcyan ((,class (:foreground ,darkcyan))))
     `(all-the-icons-dgreen ((,class (:foreground ,green))))
     `(all-the-icons-dmagenta ((,class (:foreground ,red))))
     `(all-the-icons-dmaroon ((,class (:foreground ,purple))))
     `(all-the-icons-dorange ((,class (:foreground ,orange))))
     `(all-the-icons-dpurple ((,class (:foreground ,magenta))))
     `(all-the-icons-dred ((,class (:foreground ,red))))
     `(all-the-icons-dsilver ((,class (:foreground ,grey))))
     `(all-the-icons-dyellow ((,class (:foreground ,yellow))))
     `(all-the-icons-green ((,class (:foreground ,green))))
     `(all-the-icons-lblue ((,class (:foreground ,darkblue))))
     `(all-the-icons-lcyan ((,class (:foreground ,cyan))))
     `(all-the-icons-lgreen ((,class (:foreground ,green))))
     `(all-the-icons-lmagenta ((,class (:foreground ,red))))
     `(all-the-icons-lmaroon ((,class (:foreground ,purple))))
     `(all-the-icons-lorange ((,class (:foreground ,orange))))
     `(all-the-icons-lpurple ((,class (:foreground ,magenta))))
     `(all-the-icons-lred ((,class (:foreground ,red))))
     `(all-the-icons-lsilver ((,class (:foreground ,grey))))
     `(all-the-icons-lyellow ((,class (:foreground ,yellow))))
     `(all-the-icons-magenta ((,class (:foreground ,red))))
     `(all-the-icons-maroon ((,class (:foreground ,purple))))
     `(all-the-icons-orange ((,class (:foreground ,orange))))
     `(all-the-icons-purple ((,class (:foreground ,magenta))))
     `(all-the-icons-purple-alt ((,class (:foreground ,magenta))))
     `(all-the-icons-red ((,class (:foreground ,red))))
     `(all-the-icons-red-alt ((,class (:foreground ,red))))
     `(all-the-icons-silver ((,class (:foreground ,grey))))
     `(all-the-icons-yellow ((,class (:foreground ,yellow))))

;;;; all-the-icons-dired - light
     `(all-the-icons-dired-dir-face ((,class (:foreground ,fg-other))))

;;;; all-the-icons-ivy-rich - light
     `(all-the-icons-ivy-rich-doc-face ((,class (:foreground ,darkblue))))
     `(all-the-icons-ivy-rich-path-face ((,class (:foreground ,darkblue))))
     `(all-the-icons-ivy-rich-size-face ((,class (:foreground ,darkblue))))
     `(all-the-icons-ivy-rich-time-face ((,class (:foreground ,darkblue))))

;;;; annotate - light
     `(annotate-annotation ((,class (:background ,orange :foreground ,spacegrey5))))
     `(annotate-annotation-secondary ((,class (:background ,green :foreground ,spacegrey5))))
     `(annotate-highlight ((,class (:background ,orange :underline ,orange))))
     `(annotate-highlight-secondary ((,class (:background ,green :underline ,green))))

;;;; ansi - light
     `(ansi-color-black ((,class (:foreground ,spacegrey0))))
     `(ansi-color-blue ((,class (:foreground ,darkblue))))
     `(ansi-color-cyan ((,class (:foreground ,cyan))))
     `(ansi-color-green ((,class (:foreground ,green))))
     `(ansi-color-magenta ((,class (:foreground ,magenta))))
     `(ansi-color-purple ((,class (:foreground ,purple))))
     `(ansi-color-red ((,class (:foreground ,red))))
     `(ansi-color-white ((,class (:foreground ,spacegrey8))))
     `(ansi-color-yellow ((,class (:foreground ,yellow))))
     `(ansi-color-bright-black ((,class (:foreground ,spacegrey0))))
     `(ansi-color-bright-blue ((,class (:foreground ,darkblue))))
     `(ansi-color-bright-cyan ((,class (:foreground ,cyan))))
     `(ansi-color-bright-green ((,class (:foreground ,green))))
     `(ansi-color-bright-magenta ((,class (:foreground ,magenta))))
     `(ansi-color-bright-purple ((,class (:foreground ,purple))))
     `(ansi-color-bright-red ((,class (:foreground ,red))))
     `(ansi-color-bright-white ((,class (:foreground ,spacegrey8))))
     `(ansi-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; anzu - light
     `(anzu-replace-highlight ((,class (:background ,spacegrey0 :foreground ,red :weight bold :strike-through t))))
     `(anzu-replace-to ((,class (:background ,spacegrey0 :foreground ,green :weight bold))))

;;;; auctex - light
     `(TeX-error-description-error ((,class (:foreground ,red :weight bold))))
     `(TeX-error-description-tex-said ((,class (:foreground ,green :weight bold))))
     `(TeX-error-description-warning ((,class (:foreground ,yellow :weight bold))))
     `(font-latex-bold-face ((,class (:weight bold))))
     `(font-latex-italic-face ((,class (:slant italic))))
     `(font-latex-math-face ((,class (:foreground ,darkblue))))
     `(font-latex-script-char-face ((,class (:foreground ,blue))))
     `(font-latex-sectioning-0-face ((,class (:foreground ,darkblue :weight ultra-bold))))
     `(font-latex-sectioning-1-face ((,class (:foreground ,purple :weight semi-bold))))
     `(font-latex-sectioning-2-face ((,class (:foreground ,magenta :weight semi-bold))))
     `(font-latex-sectioning-3-face ((,class (:foreground ,darkblue :weight semi-bold))))
     `(font-latex-sectioning-4-face ((,class (:foreground ,purple :weight semi-bold))))
     `(font-latex-sectioning-5-face ((,class (:foreground ,magenta :weight semi-bold))))
     `(font-latex-string-face ((,class (:foreground ,green))))
     `(font-latex-verbatim-face ((,class (:foreground ,magenta :slant italic))))
     `(font-latex-warning-face ((,class (:foreground ,yellow))))

;;;; avy - light
     `(avy-background-face ((,class (:foreground ,spacegrey5))))
     `(avy-lead-face ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(avy-lead-face-0 ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(avy-lead-face-1 ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(avy-lead-face-2 ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))

;;;; bookmark+ - light
     `(bmkp-*-mark ((,class (:foreground ,bg :background ,yellow))))
     `(bmkp->-mark ((,class (:foreground ,yellow))))
     `(bmkp-D-mark ((,class (:foreground ,bg :background ,red))))
     `(bmkp-X-mark ((,class (:foreground ,red))))
     `(bmkp-a-mark ((,class (:background ,red))))
     `(bmkp-bad-bookmark ((,class (:foreground ,bg :background ,yellow))))
     `(bmkp-bookmark-file ((,class (:foreground ,magenta :background ,bg-other))))
     `(bmkp-bookmark-list ((,class (:background ,bg-other))))
     `(bmkp-buffer ((,class (:foreground ,darkblue))))
     `(bmkp-desktop ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-file-handler ((,class (:background ,red))))
     `(bmkp-function ((,class (:foreground ,green))))
     `(bmkp-gnus ((,class (:foreground ,orange))))
     `(bmkp-heading ((,class (:foreground ,yellow))))
     `(bmkp-info ((,class (:foreground ,cyan))))
     `(bmkp-light-autonamed ((,class (:foreground ,bg-other :background ,cyan))))
     `(bmkp-light-autonamed-region ((,class (:foreground ,bg-other :background ,red))))
     `(bmkp-light-fringe-autonamed ((,class (:foreground ,bg-other :background ,magenta))))
     `(bmkp-light-fringe-non-autonamed ((,class (:foreground ,bg-other :background ,green))))
     `(bmkp-light-mark ((,class (:foreground ,bg :background ,cyan))))
     `(bmkp-light-non-autonamed ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-light-non-autonamed-region ((,class (:foreground ,bg :background ,red))))
     `(bmkp-local-directory ((,class (:foreground ,bg :background ,magenta))))
     `(bmkp-local-file-with-region ((,class (:foreground ,yellow))))
     `(bmkp-local-file-without-region ((,class (:foreground ,spacegrey5))))
     `(bmkp-man ((,class (:foreground ,magenta))))
     `(bmkp-no-jump ((,class (:foreground ,spacegrey5))))
     `(bmkp-no-local ((,class (:foreground ,yellow))))
     `(bmkp-non-file ((,class (:foreground ,green))))
     `(bmkp-remote-file ((,class (:foreground ,orange))))
     `(bmkp-sequence ((,class (:foreground ,darkblue))))
     `(bmkp-su-or-sudo ((,class (:foreground ,red))))
     `(bmkp-t-mark ((,class (:foreground ,magenta))))
     `(bmkp-url ((,class (:foreground ,darkblue :underline t))))
     `(bmkp-variable-list ((,class (:foreground ,green))))

;;;; calfw - light
     `(cfw:face-annotation ((,class (:foreground ,magenta))))
     `(cfw:face-day-title ((,class (:foreground ,fg :weight bold))))
     `(cfw:face-default-content ((,class (:foreground ,fg))))
     `(cfw:face-default-day ((,class (:weight bold))))
     `(cfw:face-disable ((,class (:foreground ,grey))))
     `(cfw:face-grid ((,class (:foreground ,bg))))
     `(cfw:face-header ((,class (:foreground ,darkblue :weight bold))))
     `(cfw:face-holiday ((,class (:foreground nil :background ,bg-other :weight bold))))
     `(cfw:face-periods ((,class (:foreground ,yellow))))
     `(cfw:face-saturday ((,class (:foreground ,red :weight bold))))
     `(cfw:face-select ((,class (:background ,grey))))
     `(cfw:face-sunday ((,class (:foreground ,red :weight bold))))
     `(cfw:face-title ((,class (:foreground ,darkblue :weight bold :height 2.0))))
     `(cfw:face-today ((,class (:foreground nil :background nil :weight bold))))
     `(cfw:face-today-title ((,class (:foreground ,bg :background ,darkblue :weight bold))))
     `(cfw:face-toolbar ((,class (:foreground nil :background nil))))
     `(cfw:face-toolbar-button-off ((,class (:foreground ,spacegrey6 :weight bold))))
     `(cfw:face-toolbar-button-on ((,class (:foreground ,darkblue :weight bold))))

;;;; centaur-tabs - light
     `(centaur-tabs-active-bar-face ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-close-mouse-face ((,class (:foreground ,orange))))
     `(centaur-tabs-close-selected ((,class (:background ,bg :foreground ,fg))))
     `(centaur-tabs-close-unselected ((,class (:background ,bg-other :foreground ,grey))))
     `(centaur-tabs-default ((,class (:background ,bg-other :foreground ,fg))))
     `(centaur-tabs-modified-marker-selected ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-modified-marker-unselected ((,class (:background ,bg :foreground ,orange))))
     `(centaur-tabs-selected ((,class (:background ,bg :foreground ,fg))))
     `(centaur-tabs-selected-modified ((,class (:background ,bg :foreground ,red))))
     `(centaur-tabs-unselected ((,class (:background ,bg-other :foreground ,grey))))
     `(centaur-tabs-unselected-modified ((,class (:background ,bg-other :foreground ,red))))

;;;; circe - light
     `(circe-fool ((,class (:foreground ,spacegrey5))))
     `(circe-highlight-nick-face ((,class (:weight bold :foreground ,orange))))
     `(circe-my-message-face ((,class (:weight bold))))
     `(circe-prompt-face ((,class (:weight bold :foreground ,orange))))
     `(circe-server-face ((,class (:foreground ,spacegrey5))))

;;;; company - light
     `(company-preview ((,class (:foreground ,spacegrey5))))
     `(company-preview-common ((,class (:background ,spacegrey3 :foreground ,orange))))
     `(company-preview-search ((,class (:background ,bg-other :foreground ,fg))))
     `(company-scrollbar-bg ((,class (:background ,bg-other :foreground ,fg))))
     `(company-scrollbar-fg ((,class (:background ,orange))))
     `(company-template-field ((,class (:foreground ,green :background ,spacegrey0 :weight bold))))
     `(company-tooltip ((,class (:background ,bg-other :foreground ,fg))))
     `(company-tooltip-annotation ((,class (:foreground ,magenta :distant-foreground ,bg))))
     `(company-tooltip-common ((,class (:foreground ,orange :distant-foreground ,spacegrey0 :weight bold))))
     `(company-tooltip-mouse ((,class (:background ,purple :foreground ,bg :distant-foreground ,fg))))
     `(company-tooltip-search ((,class (:background ,orange :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(company-tooltip-search-selection ((,class (:background ,grey))))
     `(company-tooltip-selection ((,class (:background ,grey :weight bold))))

;;;; company-box - light
     `(company-box-candidate ((,class (:foreground ,fg))))

;;;; compilation - light
     `(compilation-column-number ((,class (:foreground ,spacegrey5 :slant italic))))
     `(compilation-error ((,class (:background ,red :weight bold))))
     `(compilation-info ((,class (:foreground ,green))))
     `(compilation-line-number ((,class (:foreground ,orange))))
     `(compilation-mode-line-exit ((,class (:foreground ,green))))
     `(compilation-mode-line-fail ((,class (:background ,red :weight bold))))
     `(compilation-warning ((,class (:foreground ,yellow :slant italic))))

;;;; corfu - light
     `(corfu-bar ((,class (:background ,bg-org :foreground ,fg))))
     `(corfu-echo ((,class (:foreground ,orange))))
     `(corfu-border ((,class (:background ,fg))))
     `(corfu-current ((,class (:foreground ,orange :weight bold))))
     `(corfu-default ((,class (:background ,bg-org :foreground ,fg))))
     `(corfu-deprecated ((,class (:foreground ,red))))
     `(corfu-annotations ((,class (:foreground ,magenta))))

;;;; counsel - light
     `(counsel-variable-documentation ((,class (:foreground ,darkblue))))

;;;; cperl - light
     `(cperl-array-face ((,class (:weight bold :foreground ,red))))
     `(cperl-hash-face ((,class (:weight bold :slant italic :foreground ,red))))
     `(cperl-nonoverridable-face ((,class (:foreground ,orange))))

;;;; custom - light
     `(custom-button ((,class (:foreground ,fg :background ,bg-other :box (:line-width 3 :style released-button)))))
     `(custom-button-mouse ((,class (:foreground ,yellow :background ,bg-other :box (:line-width 3 :style released-button)))))
     `(custom-button-pressed ((,class (:foreground ,fg :background ,bg-other :box (:line-width 3 :style pressed-button)))))
     `(custom-button-pressed-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
     `(custom-button-unraised ((,class (:foreground ,magenta :background ,bg :box (:line-width 3 :style pressed-button)))))
     `(custom-changed ((,class (:foreground ,darkblue :background ,bg))))
     `(custom-comment ((,class (:foreground ,fg :background ,grey))))
     `(custom-comment-tag ((,class (:foreground ,grey))))
     `(custom-documentation ((,class (:foreground ,fg))))
     `(custom-face-tag ((,class (:foreground ,darkblue :weight bold)))) ; done
     `(custom-group-subtitle ((,class (:foreground ,red :weight bold))))
     `(custom-group-tag ((,class (:foreground ,red :weight bold)))) ; done
     `(custom-group-tag-1 ((,class (:foreground ,darkblue :weight bold))))
     `(custom-invalid ((,class (:foreground ,red))))
     `(custom-link ((,class (:foreground ,orange :underline t :weight bold)))) ; done
     `(custom-modified ((,class (:foreground ,darkblue))))
     `(custom-rogue ((,class (:foreground ,darkblue :box (:line-width 3 :style none)))))
     `(custom-saved ((,class (:foreground ,green :weight bold))))
     `(custom-set ((,class (:foreground ,yellow :background ,bg))))
     `(custom-state ((,class (:foreground ,green :weight bold))))
     `(custom-themed ((,class (:foreground ,yellow :background ,bg))))
     `(custom-variable-button ((,class (:foreground ,green :underline t))))
     `(custom-variable-obsolete ((,class (:foreground ,grey :background ,bg))))
     `(custom-variable-tag ((,class (:foreground ,darkcyan :weight bold))))
     `(custom-visibility ((,class (:foreground ,orange :height 0.8 :weight bold :underline t))))

;;; diff - light
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
     `(diff-file-header ((,class (:foreground ,orange :weight bold))))
     `(diff-hunk-header ((,class (:foreground ,bg :background ,magenta :extend t))))
     `(diff-function ((,class (:foreground ,bg :background ,magenta :extend t))))

;;;; diff-hl - light
     `(diff-hl-change ((,class (:foreground ,orange :background ,orange))))
     `(diff-hl-delete ((,class (:foreground ,red :background ,red))))
     `(diff-hl-insert ((,class (:foreground ,green :background ,green))))

;;;; dired - light
     `(dired-directory ((,class (:foreground ,darkcyan :weight bold))))
     `(dired-flagged ((,class (:foreground ,red))))
     `(dired-header ((,class (:foreground ,orange :weight bold :underline ,darkcyan))))
     `(dired-ignored ((,class (:foreground ,spacegrey5))))
     `(dired-mark ((,class (:foreground ,orange :weight bold))))
     `(dired-marked ((,class (:foreground ,yellow :weight bold))))
     `(dired-perm-write ((,class (:foreground ,red :underline t))))
     `(dired-symlink ((,class (:foreground ,magenta))))
     `(dired-warning ((,class (:foreground ,yellow))))

;;;; dired-async - light
     `(dired-async-failures ((,class (:foreground ,red))))
     `(dired-async-message ((,class (:foreground ,orange))))
     `(dired-async-mode-message ((,class (:foreground ,orange))))

;;;; dired-filetype-face - light
     `(dired-filetype-common ((,class (:foreground ,fg))))
     `(dired-filetype-compress ((,class (:foreground ,yellow))))
     `(dired-filetype-document ((,class (:foreground ,fg))))
     `(dired-filetype-execute ((,class (:foreground ,red))))
     `(dired-filetype-image ((,class (:foreground ,orange))))
     `(dired-filetype-js ((,class (:foreground ,yellow))))
     `(dired-filetype-link ((,class (:foreground ,magenta))))
     `(dired-filetype-music ((,class (:foreground ,magenta))))
     `(dired-filetype-omit ((,class (:foreground ,darkblue))))
     `(dired-filetype-plain ((,class (:foreground ,fg))))
     `(dired-filetype-program ((,class (:foreground ,red))))
     `(dired-filetype-source ((,class (:foreground ,green))))
     `(dired-filetype-video ((,class (:foreground ,magenta))))
     `(dired-filetype-xml ((,class (:foreground ,green))))

;;;; dired+ - light
     `(diredp-compressed-file-suffix ((,class (:foreground ,spacegrey5))))
     `(diredp-date-time ((,class (:foreground ,darkblue))))
     `(diredp-dir-heading ((,class (:foreground ,darkblue :weight bold))))
     `(diredp-dir-name ((,class (:foreground ,spacegrey8 :weight bold))))
     `(diredp-dir-priv ((,class (:foreground ,darkblue :weight bold))))
     `(diredp-exec-priv ((,class (:foreground ,yellow))))
     `(diredp-file-name ((,class (:foreground ,spacegrey8))))
     `(diredp-file-suffix ((,class (:foreground ,magenta))))
     `(diredp-ignored-file-name ((,class (:foreground ,spacegrey5))))
     `(diredp-no-priv ((,class (:foreground ,spacegrey5))))
     `(diredp-number ((,class (:foreground ,purple))))
     `(diredp-rare-priv ((,class (:foreground ,red :weight bold))))
     `(diredp-read-priv ((,class (:foreground ,purple))))
     `(diredp-symlink ((,class (:foreground ,magenta))))
     `(diredp-write-priv ((,class (:foreground ,green))))

;;;; dired-k - light
     `(dired-k-added ((,class (:foreground ,green :weight bold))))
     `(dired-k-commited ((,class (:foreground ,green :weight bold))))
     `(dired-k-directory ((,class (:foreground ,darkblue :weight bold))))
     `(dired-k-ignored ((,class (:foreground ,spacegrey5 :weight bold))))
     `(dired-k-modified ((,class (:foreground ,orange :weight bold))))
     `(dired-k-untracked ((,class (:foreground ,teal :weight bold))))

;;;; dired-subtree - light
     `(dired-subtree-depth-1-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-2-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-3-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-4-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-5-face ((,class (:background ,bg-other))))
     `(dired-subtree-depth-6-face ((,class (:background ,bg-other))))

;;;; diredfl - light
     `(diredfl-autofile-name ((,class (:foreground ,spacegrey4))))
     `(diredfl-compressed-file-name ((,class (:foreground ,orange))))
     `(diredfl-compressed-file-suffix ((,class (:foreground ,yellow))))
     `(diredfl-date-time ((,class (:foreground ,cyan :weight light))))
     `(diredfl-deletion ((,class (:foreground ,red :weight bold))))
     `(diredfl-deletion-file-name ((,class (:foreground ,red))))
     `(diredfl-dir-heading ((,class (:foreground ,darkblue :weight bold))))
     `(diredfl-dir-name ((,class (:foreground ,darkcyan))))
     `(diredfl-dir-priv ((,class (:foreground ,darkblue))))
     `(diredfl-exec-priv ((,class (:foreground ,red))))
     `(diredfl-executable-tag ((,class (:foreground ,red))))
     `(diredfl-file-name ((,class (:foreground ,fg))))
     `(diredfl-file-suffix ((,class (:foreground ,teal))))
     `(diredfl-flag-mark ((,class (:foreground ,yellow :background ,yellow :weight bold))))
     `(diredfl-flag-mark-line ((,class (:background ,yellow))))
     `(diredfl-ignored-file-name ((,class (:foreground ,spacegrey5))))
     `(diredfl-link-priv ((,class (:foreground ,magenta))))
     `(diredfl-no-priv ((,class (:foreground ,fg))))
     `(diredfl-number ((,class (:foreground ,orange))))
     `(diredfl-other-priv ((,class (:foreground ,purple))))
     `(diredfl-rare-priv ((,class (:foreground ,fg))))
     `(diredfl-read-priv ((,class (:foreground ,yellow))))
     `(diredfl-symlink ((,class (:foreground ,magenta))))
     `(diredfl-tagged-autofile-name ((,class (:foreground ,spacegrey5))))
     `(diredfl-write-priv ((,class (:foreground ,red))))

;;;; doom-modeline - light
     `(doom-modeline-bar-inactive ((,class (:background nil))))
     `(doom-modeline-buffer-modified ((,class (:foreground ,red :weight bold))))
     `(doom-modeline-eldoc-bar ((,class (:background ,green))))
     `(doom-modeline-evil-emacs-state ((,class (:foreground ,cyan :weight bold))))
     `(doom-modeline-evil-insert-state ((,class (:foreground ,red :weight bold))))
     `(doom-modeline-evil-motion-state ((,class (:foreground ,darkblue :weight bold))))
     `(doom-modeline-evil-normal-state ((,class (:foreground ,green :weight bold))))
     `(doom-modeline-evil-operator-state ((,class (:foreground ,magenta :weight bold))))
     `(doom-modeline-evil-replace-state ((,class (:foreground ,purple :weight bold))))
     `(doom-modeline-evil-visual-state ((,class (:foreground ,yellow :weight bold))))

;;;; ediff - light
     `(ediff-current-diff-A ((,class (:foreground ,fg :background ,red :extend t))))
     `(ediff-current-diff-B ((,class (:foreground ,fg :background ,green :extend t))))
     `(ediff-current-diff-C ((,class (:foreground ,fg :background ,yellow :extend t))))
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
     `(elfeed-log-debug-level-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-log-error-level-face ((,class (:foreground ,red))))
     `(elfeed-log-info-level-face ((,class (:foreground ,green))))
     `(elfeed-log-warn-level-face ((,class (:foreground ,yellow))))
     `(elfeed-search-date-face ((,class (:foreground ,magenta))))
     `(elfeed-search-feed-face ((,class (:foreground ,darkblue))))
     `(elfeed-search-filter-face ((,class (:foreground ,magenta))))
     `(elfeed-search-tag-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-search-title-face ((,class (:foreground ,spacegrey5))))
     `(elfeed-search-unread-count-face ((,class (:foreground ,yellow))))
     `(elfeed-search-unread-title-face ((,class (:foreground ,fg :weight bold))))

;;;; elixir-mode - light
     `(elixir-atom-face ((,class (:foreground ,cyan))))
     `(elixir-attribute-face ((,class (:foreground ,magenta))))

;;;; elscreen - light
     `(elscreen-tab-background-face ((,class (:background ,bg))))
     `(elscreen-tab-control-face ((,class (:background ,bg :foreground ,bg))))
     `(elscreen-tab-current-screen-face ((,class (:background ,bg-other :foreground ,fg))))
     `(elscreen-tab-other-screen-face ((,class (:background ,bg :foreground ,fg-other))))

;;;; enh-ruby-mode - light
     `(enh-ruby-heredoc-delimiter-face ((,class (:foreground ,green))))
     `(enh-ruby-op-face ((,class (:foreground ,fg))))
     `(enh-ruby-regexp-delimiter-face ((,class (:foreground ,orange))))
     `(enh-ruby-regexp-face ((,class (:foreground ,orange))))
     `(enh-ruby-string-delimiter-face ((,class (:foreground ,green))))
     `(erm-syn-errline ((,class (:underline (:style wave :color ,red)))))
     `(erm-syn-warnline ((,class (:underline (:style wave :color ,yellow)))))

;;;; erc - light
     `(erc-action-face  ((,class (:weight bold))))
     `(erc-button ((,class (:weight bold :underline t))))
     `(erc-command-indicator-face ((,class (:weight bold))))
     `(erc-current-nick-face ((,class (:foreground ,green :weight bold))))
     `(erc-default-face ((,class (:background ,bg :foreground ,fg))))
     `(erc-direct-msg-face ((,class (:foreground ,purple))))
     `(erc-error-face ((,class (:foreground ,red))))
     `(erc-header-line ((,class (:background ,bg-other :foreground ,orange))))
     `(erc-input-face ((,class (:foreground ,green))))
     `(erc-my-nick-face ((,class (:foreground ,green :weight bold))))
     `(erc-my-nick-prefix-face ((,class (:foreground ,green :weight bold))))
     `(erc-nick-default-face ((,class (:weight bold))))
     `(erc-nick-msg-face ((,class (:foreground ,purple))))
     `(erc-nick-prefix-face ((,class (:weight bold))))
     `(erc-notice-face ((,class (:foreground ,spacegrey5))))
     `(erc-prompt-face ((,class (:foreground ,orange :weight bold))))
     `(erc-timestamp-face ((,class (:foreground ,darkblue :weight bold))))

;;;; eshell - light
     `(eshell-ls-archive ((,class (:foreground ,yellow))))
     `(eshell-ls-backup ((,class (:foreground ,yellow))))
     `(eshell-ls-clutter ((,class (:foreground ,red))))
     `(eshell-ls-directory ((,class (:foreground ,darkcyan))))
     `(eshell-ls-executable ((,class (:foreground ,red))))
     `(eshell-ls-missing ((,class (:foreground ,red))))
     `(eshell-ls-product ((,class (:foreground ,orange))))
     `(eshell-ls-readonly ((,class (:foreground ,orange))))
     `(eshell-ls-special ((,class (:foreground ,magenta))))
     `(eshell-ls-symlink ((,class (:foreground ,magenta))))
     `(eshell-ls-unreadable ((,class (:foreground ,spacegrey5))))
     `(eshell-prompt ((,class (:foreground ,orange :weight bold))))

;;;; evil - light
     `(evil-ex-info ((,class (:foreground ,red :slant italic))))
     `(evil-ex-search ((,class (:background ,orange :foreground ,spacegrey0 :weight bold))))
     `(evil-ex-substitute-matches ((,class (:background ,spacegrey0 :foreground ,red :weight bold :strike-through t))))
     `(evil-ex-substitute-replacement ((,class (:background ,spacegrey0 :foreground ,green :weight bold))))
     `(evil-search-highlight-persist-highlight-face ((,class (:background ,blue  :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))

;;;; evil-googles - light
     `(evil-goggles-default-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-mc - light
     `(evil-mc-cursor-bar-face ((,class (:height 1 :background ,purple :foreground ,spacegrey0))))
     `(evil-mc-cursor-default-face ((,class (:background ,purple :foreground ,spacegrey0 :inverse-video nil))))
     `(evil-mc-cursor-hbar-face ((,class (:underline (:color ,orange)))))
     `(evil-mc-region-face ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; evil-snipe - light
     `(evil-snipe-first-match-face ((,class (:foreground ,orange :background ,blue :weight bold))))
     `(evil-snipe-matches-face ((,class (:foreground ,orange :underline t :weight bold))))

;;;; expenses - light
     `(expenses-face-date ((,class (:foreground ,orange :weight bold))))
     `(expenses-face-expence ((,class (:foreground ,green :weight bold))))
     `(expenses-face-message ((,class (:foreground ,darkcyan :weight bold))))

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
     `(flycheck-posframe-info-face ((,class (:foreground ,fg))))
     `(flycheck-posframe-warning-face ((,class (:foreground ,yellow))))

;;;; flymake - light
     `(flymake-error ((,class (:underline (:style wave :color ,red)))))
     `(flymake-note ((,class (:underline (:style wave :color ,green)))))
     `(flymake-warning ((,class (:underline (:style wave :color ,orange)))))

;;;; flyspell - light
     `(flyspell-duplicate ((,class (:underline (:style wave :color ,yellow)))))
     `(flyspell-incorrect ((,class (:underline (:style wave :color ,red)))))

;;;; forge - light
     `(forge-topic-closed ((,class (:foreground ,spacegrey5 :strike-through t))))
     `(forge-topic-label ((,class (:box nil))))

;;;; git-commit - light
     `(git-commit-comment-branch-local ((,class (:foreground ,purple))))
     `(git-commit-comment-branch-remote ((,class (:foreground ,green))))
     `(git-commit-comment-detached ((,class (:foreground ,orange))))
     `(git-commit-comment-file ((,class (:foreground ,magenta))))
     `(git-commit-comment-heading ((,class (:foreground ,magenta))))
     `(git-commit-keyword ((,class (:foreground ,cyan :slant italic))))
     `(git-commit-known-pseudo-header ((,class (:foreground ,spacegrey5 :weight bold :slant italic))))
     `(git-commit-nonempty-second-line ((,class (:foreground ,red))))
     `(git-commit-overlong-summary ((,class (:foreground ,red :slant italic :weight bold))))
     `(git-commit-pseudo-header ((,class (:foreground ,spacegrey5 :slant italic))))
     `(git-commit-summary ((,class (:foreground ,darkcyan))))

;;;; git-gutter - light
     `(git-gutter:added ((,class (:foreground ,green))))
     `(git-gutter:deleted ((,class (:foreground ,red))))
     `(git-gutter:modified ((,class (:foreground ,cyan))))

;;;; git-gutter+ - light
     `(git-gutter+-added ((,class (:foreground ,green :background ,bg))))
     `(git-gutter+-deleted ((,class (:foreground ,red :background ,bg))))
     `(git-gutter+-modified ((,class (:foreground ,cyan :background ,bg))))

;;;; git-gutter-fringe - light
     `(git-gutter-fr:added ((,class (:foreground ,green))))
     `(git-gutter-fr:deleted ((,class (:foreground ,red))))
     `(git-gutter-fr:modified ((,class (:foreground ,cyan))))

;;;; gnus - light
     `(gnus-cite-1 ((,class (:foreground ,magenta))))
     `(gnus-cite-2 ((,class (:foreground ,magenta))))
     `(gnus-cite-3 ((,class (:foreground ,magenta))))
     `(gnus-cite-4 ((,class (:foreground ,green))))
     `(gnus-cite-5 ((,class (:foreground ,green))))
     `(gnus-cite-6 ((,class (:foreground ,green))))
     `(gnus-cite-7 ((,class (:foreground ,purple))))
     `(gnus-cite-8 ((,class (:foreground ,purple))))
     `(gnus-cite-9 ((,class (:foreground ,purple))))
     `(gnus-cite-10 ((,class (:foreground ,yellow))))
     `(gnus-cite-11 ((,class (:foreground ,yellow))))
     `(gnus-group-mail-1 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-mail-1-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-mail-2 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-mail-2-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-mail-3 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-mail-3-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-mail-low ((,class (:foreground ,fg))))
     `(gnus-group-mail-low-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-1 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-1-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-2 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-2-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-3 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-3-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-4 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-4-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-5 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-5-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-6 ((,class (:weight bold :foreground ,fg))))
     `(gnus-group-news-6-empty ((,class (:foreground ,spacegrey5))))
     `(gnus-group-news-low ((,class (:weight bold :foreground ,spacegrey5))))
     `(gnus-group-news-low-empty ((,class (:foreground ,fg))))
     `(gnus-header-content ((,class (:foreground ,magenta))))
     `(gnus-header-from ((,class (:foreground ,magenta))))
     `(gnus-header-name ((,class (:foreground ,green))))
     `(gnus-header-newsgroups ((,class (:foreground ,magenta))))
     `(gnus-header-subject ((,class (:foreground ,orange :weight bold))))
     `(gnus-signature ((,class (:foreground ,yellow))))
     `(gnus-summary-cancelled ((,class (:foreground ,red :strike-through t))))
     `(gnus-summary-high-ancient ((,class (:foreground ,spacegrey5 :slant italic))))
     `(gnus-summary-high-read ((,class (:foreground ,fg))))
     `(gnus-summary-high-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-high-unread ((,class (:foreground ,green))))
     `(gnus-summary-low-ancient ((,class (:foreground ,spacegrey5 :slant italic))))
     `(gnus-summary-low-read ((,class (:foreground ,fg))))
     `(gnus-summary-low-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-low-unread ((,class (:foreground ,green))))
     `(gnus-summary-normal-ancient ((,class (:foreground ,spacegrey5 :slant italic))))
     `(gnus-summary-normal-read ((,class (:foreground ,fg))))
     `(gnus-summary-normal-ticked ((,class (:foreground ,purple))))
     `(gnus-summary-normal-unread ((,class (:foreground ,green :weight bold))))
     `(gnus-summary-selected ((,class (:foreground ,darkblue :weight bold))))
     `(gnus-x-face ((,class (:background ,spacegrey5 :foreground ,fg))))

;;;; goggles - light
     `(goggles-added ((,class (:background ,green))))
     `(goggles-changed ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))
     `(goggles-removed ((,class (:background ,red :extend t))))

;;;; header-line - light
     `(header-line ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))

;;;; helm - light
     `(helm-ff-directory ((,class (:foreground ,red))))
     `(helm-ff-dotted-directory ((,class (:foreground ,grey))))
     `(helm-ff-executable ((,class (:foreground ,spacegrey8 :slant italic))))
     `(helm-ff-file ((,class (:foreground ,fg))))
     `(helm-ff-prefix ((,class (:foreground ,magenta))))
     `(helm-grep-file ((,class (:foreground ,darkblue))))
     `(helm-grep-finish ((,class (:foreground ,green))))
     `(helm-grep-lineno ((,class (:foreground ,spacegrey5))))
     `(helm-grep-match ((,class (:foreground ,orange :distant-foreground ,red))))
     `(helm-match ((,class (:weight bold :foreground ,orange :distant-foreground ,spacegrey8))))
     `(helm-moccur-buffer ((,class (:foreground ,orange :underline t :weight bold))))
     `(helm-selection ((,class (:weight bold :background ,grey :extend t :distant-foreground ,orange))))
     `(helm-source-header ((,class (:background ,spacegrey2 :foreground ,magenta :weight bold))))
     `(helm-swoop-target-line-block-face ((,class (:foreground ,yellow))))
     `(helm-swoop-target-line-face ((,class (:foreground ,orange :inverse-video t))))
     `(helm-swoop-target-line-face ((,class (:foreground ,orange :inverse-video t))))
     `(helm-swoop-target-number-face ((,class (:foreground ,spacegrey5))))
     `(helm-swoop-target-word-face ((,class (:foreground ,green :weight bold))))
     `(helm-visible-mark ((,class (:foreground ,magenta  :weight bold :underline ,darkcyan))))

;;;; helpful - light
     `(helpful-heading ((,class (:weight bold :height 1.2))))

;;;; hi-lock - light
     `(hi-blue ((,class (:background ,darkblue))))
     `(hi-blue-b ((,class (:foreground ,darkblue :weight bold))))
     `(hi-green ((,class (:background ,green))))
     `(hi-green-b ((,class (:foreground ,green :weight bold))))
     `(hi-magenta ((,class (:background ,purple))))
     `(hi-red-b ((,class (:foreground ,red :weight bold))))
     `(hi-yellow ((,class (:background ,yellow))))

;;;; highlight-indentation-mode - light
     `(highlight-indentation-current-column-face ((,class (:background ,spacegrey1))))
     `(highlight-indentation-face ((,class (:background ,bg-other :extend t))))
     `(highlight-indentation-guides-even-face ((,class (:background ,bg-other :extend t))))
     `(highlight-indentation-guides-odd-face ((,class (:background ,bg-other :extend t))))

;;;; highlight-numbers-mode - light
     `(highlight-numbers-number ((,class (:weight bold :foreground ,orange))))

;;;; highlight-quoted-mode - light
     `(highlight-quoted-symbol ((,class (:foreground ,yellow))))
     `(highlight-quoted-quote  ((,class (:foreground ,fg))))

;;;; highlight-symbol - light
     `(highlight-symbol-face ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; highlight-thing - light
     `(highlight-thing ((,class (:background ,grey :distant-foreground ,fg-other))))

;;;; hl-fill-column-face - light
     `(hl-fill-column-face ((,class (:foreground ,spacegrey5 :background ,bg-other :extend t))))

;;;; hl-line (built-in) - light
     `(hl-line ((,class (:background ,bg-other :extend t))))

;;;; hl-todo - light
     `(hl-todo ((,class (:foreground ,red :weight bold))))

;;;; hlinum - light
     `(linum-highlight-face ((,class (:foreground ,fg :distant-foreground nil :weight normal))))

;;;; hydra - light
     `(hydra-face-amaranth ((,class (:foreground ,purple :weight bold))))
     `(hydra-face-blue ((,class (:foreground ,darkblue :weight bold))))
     `(hydra-face-magenta ((,class (:foreground ,magenta :weight bold))))
     `(hydra-face-red ((,class (:foreground ,red :weight bold))))
     `(hydra-face-teal ((,class (:foreground ,teal :weight bold))))

;;;; ido - light
     `(ido-first-match ((,class (:foreground ,orange))))
     `(ido-indicator ((,class (:foreground ,red :background ,bg))))
     `(ido-only-match ((,class (:foreground ,green))))
     `(ido-subdir ((,class (:foreground ,magenta))))
     `(ido-virtual ((,class (:foreground ,spacegrey5))))

;;;; iedit - light
     `(iedit-occurrence ((,class (:foreground ,purple :weight bold :inverse-video t))))
     `(iedit-read-only-occurrence ((,class (:background ,grey :foreground nil :distant-foreground ,bg :extend t))))

;;;; imenu-list - light
     `(imenu-list-entry-face-0 ((,class (:foreground ,orange))))
     `(imenu-list-entry-face-1 ((,class (:foreground ,green))))
     `(imenu-list-entry-face-2 ((,class (:foreground ,yellow))))
     `(imenu-list-entry-subalist-face-0 ((,class (:foreground ,orange :weight bold))))
     `(imenu-list-entry-subalist-face-1 ((,class (:foreground ,green :weight bold))))
     `(imenu-list-entry-subalist-face-2 ((,class (:foreground ,yellow :weight bold))))

;;;; indent-guide - light
     `(indent-guide-face ((,class (:background ,bg-other :extend t))))

;;;; isearch - light
     `(isearch ((,class (:background ,blue  :foreground ,spacegrey8 :distant-foreground ,spacegrey0 :weight bold))))
     `(isearch-fail ((,class (:background ,red :foreground ,spacegrey0 :weight bold))))

;;;; ivy - light
     `(ivy-confirm-face ((,class (:foreground ,green))))
     `(ivy-current-match ((,class (:background ,bg-other :distant-foreground nil :extend t))))
     `(ivy-highlight-face ((,class (:foreground ,magenta))))
     `(ivy-match-required-face ((,class (:foreground ,red))))
     `(ivy-minibuffer-match-face-1 ((,class (:background nil :foreground ,orange :weight bold :underline t))))
     `(ivy-minibuffer-match-face-2 ((,class (:foreground ,purple :background ,spacegrey1 :weight semi-bold))))
     `(ivy-minibuffer-match-face-3 ((,class (:foreground ,green :weight semi-bold))))
     `(ivy-minibuffer-match-face-4 ((,class (:foreground ,yellow :weight semi-bold))))
     `(ivy-minibuffer-match-highlight ((,class (:foreground ,magenta))))
     `(ivy-modified-buffer ((,class (:weight bold :foreground ,darkcyan))))
     `(ivy-virtual ((,class (:slant italic :foreground ,spacegrey5))))

;;;; ivy-posframe - light
     `(ivy-posframe ((,class (:background ,bg-other))))
     `(ivy-posframe-border ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))

;;;; jabber - light
     `(jabber-activity-face ((,class (:foreground ,red :weight bold))))
     `(jabber-activity-personal-face ((,class (:foreground ,darkblue :weight bold))))
     `(jabber-chat-error ((,class (:foreground ,red :weight bold))))
     `(jabber-chat-prompt-foreign ((,class (:foreground ,red :weight bold))))
     `(jabber-chat-prompt-local ((,class (:foreground ,darkblue :weight bold))))
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
     `(jabber-roster-user-xa ((,class (:foreground ,cyan))))

;;;; jdee - light
     `(jdee-font-lock-bold-face ((,class (:weight bold))))
     `(jdee-font-lock-constant-face ((,class (:foreground ,orange))))
     `(jdee-font-lock-constructor-face ((,class (:foreground ,darkblue))))
     `(jdee-font-lock-doc-tag-face ((,class (:foreground ,magenta))))
     `(jdee-font-lock-italic-face ((,class (:slant italic))))
     `(jdee-font-lock-link-face ((,class (:foreground ,darkblue :italic nil :underline t))))
     `(jdee-font-lock-modifier-face ((,class (:foreground ,yellow))))
     `(jdee-font-lock-number-face ((,class (:foreground ,orange))))
     `(jdee-font-lock-operator-face ((,class (:foreground ,fg))))
     `(jdee-font-lock-private-face ((,class (:foreground ,magenta))))
     `(jdee-font-lock-protected-face ((,class (:foreground ,magenta))))
     `(jdee-font-lock-public-face ((,class (:foreground ,magenta))))

;;;; js2-mode - light
     `(js2-external-variable ((,class (:foreground ,fg))))
     `(js2-function-call ((,class (:foreground ,darkblue))))
     `(js2-function-param ((,class (:foreground ,red))))
     `(js2-jsdoc-tag ((,class (:foreground ,spacegrey5))))
     `(js2-object-property ((,class (:foreground ,magenta))))

;;;; keycast - light
     `(keycast-command ((,class (:foreground ,orange :distant-foreground ,bg))))
     `(keycast-key ((,class (:foreground ,magenta  :weight bold :underline ,darkcyan))))

;;;; ledger-mode - light
     `(ledger-font-payee-cleared-face ((,class (:foreground ,magenta :weight bold))))
     `(ledger-font-payee-uncleared-face ((,class (:foreground ,spacegrey5  :weight bold))))
     `(ledger-font-posting-account-face ((,class (:foreground ,spacegrey8))))
     `(ledger-font-posting-amount-face ((,class (:foreground ,yellow))))
     `(ledger-font-posting-date-face ((,class (:foreground ,darkblue))))
     `(ledger-font-xact-highlight-face ((,class (:background ,spacegrey0))))

;;;; line numbers - light
     `(line-number ((,class (:foreground ,spacegrey5))))
     `(line-number-current-line ((,class (:foreground ,fg))))

;;;; linum - light
     `(linum ((,class (:foreground ,spacegrey5))))

;;;; linum-relative - light
     `(linum-relative-current-face ((,class (:foreground ,fg))))

;;;; lsp-mode - light
     `(lsp-face-highlight-read ((,class (:foreground ,darkcyan :weight bold :underline ,darkcyan))))
     `(lsp-face-highlight-textual ((,class (:foreground ,darkcyan :weight bold))))
     `(lsp-face-highlight-write ((,class (:foreground ,darkcyan :weight bold :underline ,darkcyan))))
     `(lsp-headerline-breadcrumb-separator-face ((,class (:foreground ,fg-other))))
     `(lsp-ui-doc-background ((,class (:background ,bg-other :foreground ,fg))))
     `(lsp-ui-peek-filename ((,class (:foreground ,fg :weight bold))))
     `(lsp-ui-peek-header ((,class (:foreground ,fg :background ,bg :weight bold))))
     `(lsp-ui-peek-highlight ((,class (:background ,grey :foreground ,bg :box t :weight bold))))
     `(lsp-ui-peek-line-number ((,class (:foreground ,green))))
     `(lsp-ui-peek-list ((,class (:background ,bg))))
     `(lsp-ui-peek-peek ((,class (:background ,bg))))
     `(lsp-ui-peek-selection ((,class (:foreground ,bg :background ,darkblue :bold bold))))
     `(lsp-ui-sideline-code-action ((,class (:foreground ,orange))))
     `(lsp-ui-sideline-current-symbol ((,class (:foreground ,orange))))
     `(lsp-ui-sideline-symbol-info ((,class (:foreground ,spacegrey5 :background ,bg-other :extend t))))

;;;; lui - light
     `(lui-button-face ((,class (:foreground ,orange :underline t))))
     `(lui-highlight-face ((,class (:foreground ,orange))))
     `(lui-time-stamp-face ((,class (:foreground ,magenta))))

;;;; magit - light
     `(magit-bisect-bad ((,class (:foreground ,red))))
     `(magit-bisect-good ((,class (:foreground ,green))))
     `(magit-bisect-skip ((,class (:foreground ,orange))))
     `(magit-blame-date ((,class (:foreground ,red))))
     `(magit-blame-heading ((,class (:foreground ,orange :background ,spacegrey3 :extend t))))
     `(magit-branch-current ((,class (:foreground ,red))))
     `(magit-branch-local ((,class (:foreground ,red))))
     `(magit-branch-remote ((,class (:foreground ,green))))
     `(magit-branch-remote-head ((,class (:foreground ,green))))
     `(magit-cherry-equivalent ((,class (:foreground ,magenta))))
     `(magit-cherry-unmatched ((,class (:foreground ,cyan))))
     `(magit-diff-added ((,class (:foreground ,bg  :background ,green :extend t))))
     `(magit-diff-added-highlight ((,class (:foreground ,bg :background ,green :weight bold :extend t))))
     `(magit-diff-base ((,class (:foreground ,orange :background ,orange :extend t))))
     `(magit-diff-base-highlight ((,class (:foreground ,orange :background ,orange :weight bold :extend t))))
     `(magit-diff-context ((,class (:foreground ,fg :background ,bg :extend t))))
     `(magit-diff-context-highlight ((,class (:foreground ,fg :background ,bg-other :extend t))))
     `(magit-diff-file-heading ((,class (:foreground ,fg :weight bold :extend t))))
     `(magit-diff-file-heading-selection ((,class (:foreground ,orange :background ,blue :weight bold :extend t))))
     `(magit-diff-hunk-heading ((,class (:foreground ,bg :background ,magenta :extend t))))
     `(magit-diff-hunk-heading-highlight ((,class (:foreground ,bg :background ,magenta :weight bold :extend t))))
     `(magit-diff-lines-heading ((,class (:foreground ,yellow :background ,red :extend t :extend t))))
     `(magit-diff-removed ((,class (:foreground ,bg :background ,red :extend t))))
     `(magit-diff-removed-highlight ((,class (:foreground ,bg :background ,red :weight bold :extend t))))
     `(magit-diffstat-added ((,class (:foreground ,green))))
     `(magit-diffstat-removed ((,class (:foreground ,red))))
     `(magit-dimmed ((,class (:foreground ,spacegrey5))))
     `(magit-filename ((,class (:foreground ,magenta))))
     `(magit-hash ((,class (:foreground ,darkblue))))
     `(magit-header-line ((,class (:background ,bg-other :foreground ,darkcyan :weight bold :box (:line-width 3 :color ,bg-other)))))
     `(magit-log-author ((,class (:foreground ,orange))))
     `(magit-log-date ((,class (:foreground ,darkblue))))
     `(magit-log-graph ((,class (:foreground ,spacegrey5))))
     `(magit-process-ng ((,class (:foreground ,red))))
     `(magit-process-ok ((,class (:foreground ,green))))
     `(magit-reflog-amend ((,class (:foreground ,purple))))
     `(magit-reflog-checkout ((,class (:foreground ,darkblue))))
     `(magit-reflog-cherry-pick ((,class (:foreground ,green))))
     `(magit-reflog-commit ((,class (:foreground ,green))))
     `(magit-reflog-merge ((,class (:foreground ,green))))
     `(magit-reflog-other ((,class (:foreground ,cyan))))
     `(magit-reflog-rebase ((,class (:foreground ,purple))))
     `(magit-reflog-remote ((,class (:foreground ,cyan))))
     `(magit-reflog-reset ((,class (:foreground ,red))))
     `(magit-refname ((,class (:foreground ,spacegrey5))))
     `(magit-section-heading ((,class (:foreground ,darkcyan :weight bold :extend t))))
     `(magit-section-heading-selection ((,class (:foreground ,orange :weight bold :extend t))))
     `(magit-section-highlight ((,class (:background ,bg-other :extend t))))
     `(magit-section-secondary-heading ((,class (:foreground ,magenta :weight bold :extend t))))
     `(magit-sequence-drop ((,class (:foreground ,red))))
     `(magit-sequence-head ((,class (:foreground ,darkblue))))
     `(magit-sequence-part ((,class (:foreground ,orange))))
     `(magit-sequence-stop ((,class (:foreground ,green))))
     `(magit-signature-bad ((,class (:foreground ,red))))
     `(magit-signature-error ((,class (:foreground ,red))))
     `(magit-signature-expired ((,class (:foreground ,orange))))
     `(magit-signature-good ((,class (:foreground ,green))))
     `(magit-signature-revoked ((,class (:foreground ,purple))))
     `(magit-signature-untrusted ((,class (:foreground ,yellow))))
     `(magit-tag ((,class (:foreground ,yellow))))

;;;; make-mode - light
     `(makefile-targets ((,class (:foreground ,darkblue))))

;;;; marginalia - light
     `(marginalia-documentation ((,class (:foreground ,darkblue))))
     `(marginalia-file-name ((,class (:foreground ,darkblue))))

;;;; markdown-mode - light
     `(markdown-blockquote-face ((,class (:slant italic :foreground ,spacegrey5))))
     `(markdown-bold-face ((,class (:weight bold :foreground ,orange))))
     `(markdown-code-face ((,class (:background ,bg-org :extend t))))
     `(markdown-header-delimiter-face ((,class (:weight bold :foreground ,orange))))
     `(markdown-header-face-1 ((,class (:weight bold :foreground ,red))))
     `(markdown-header-face-2 ((,class (:weight bold :foreground ,darkcyan))))
     `(markdown-header-face-3 ((,class (:weight bold :foreground ,magenta))))
     `(markdown-header-face-4 ((,class (:weight bold :foreground ,darkblue))))
     `(markdown-header-face-5 ((,class (:weight bold :foreground ,yellow))))
     `(markdown-html-attr-name-face ((,class (:foreground ,red))))
     `(markdown-html-attr-value-face ((,class (:foreground ,green))))
     `(markdown-html-entity-face ((,class (:foreground ,red))))
     `(markdown-html-tag-delimiter-face ((,class (:foreground ,fg))))
     `(markdown-html-tag-name-face ((,class (:foreground ,magenta))))
     `(markdown-inline-code-face ((,class (:background ,bg-org :foreground ,green))))
     `(markdown-italic-face ((,class (:slant italic :foreground ,magenta))))
     `(markdown-link-face ((,class (:foreground ,orange))))
     `(markdown-list-face ((,class (:foreground ,red))))
     `(markdown-markup-face ((,class (:foreground ,orange))))
     `(markdown-metadata-key-face ((,class (:foreground ,red))))
     `(markdown-pre-face ((,class (:background ,bg-org :foreground ,green))))
     `(markdown-reference-face ((,class (:foreground ,spacegrey5))))
     `(markdown-url-face ((,class (:foreground ,purple :weight normal))))

;;;; message - light
     `(message-cited-text ((,class (:foreground ,purple))))
     `(message-header-cc ((,class (:foreground ,orange :weight bold))))
     `(message-header-name ((,class (:foreground ,green))))
     `(message-header-newsgroups ((,class (:foreground ,yellow))))
     `(message-header-other ((,class (:foreground ,magenta))))
     `(message-header-subject ((,class (:foreground ,orange :weight bold))))
     `(message-header-to ((,class (:foreground ,orange :weight bold))))
     `(message-header-xheader ((,class (:foreground ,spacegrey5))))
     `(message-mml ((,class (:foreground ,spacegrey5 :slant italic))))
     `(message-separator ((,class (:foreground ,spacegrey5))))

;;;; mic-paren - light
     `(paren-face-match ((,class (:foreground ,red :background ,spacegrey0 :weight ultra-bold))))
     `(paren-face-mismatch ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))
     `(paren-face-no-match ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))

;;;; minimap - light
     `(minimap-active-region-background ((,class (:background ,bg))))
     `(minimap-current-line-face ((,class (:background ,grey))))

;;;; mmm-mode - light
     `(mmm-cleanup-submode-face ((,class (:background ,yellow))))
     `(mmm-code-submode-face ((,class (:background ,bg-other))))
     `(mmm-comment-submode-face ((,class (:background ,darkblue))))
     `(mmm-declaration-submode-face ((,class (:background ,cyan))))
     `(mmm-default-submode-face ((,class (:background nil))))
     `(mmm-init-submode-face ((,class (:background ,red))))
     `(mmm-output-submode-face ((,class (:background ,magenta))))
     `(mmm-special-submode-face ((,class (:background ,green))))

;;;; mode-line - light
     `(mode-line ((,class (,@(timu-spacegrey-set-mode-line-active-border spacegrey5 spacegrey4) :background ,spacegrey8 :foreground ,fg :distant-foreground ,orange))))
     `(mode-line-buffer-id ((,class (:foreground ,fg :weight bold))))
     `(mode-line-emphasis ((,class (:foreground ,darkcyan :distant-foreground ,bg))))
     `(mode-line-highlight ((,class (:foreground ,magenta  :weight bold :underline ,darkcyan))))
     `(mode-line-inactive ((,class (,@(timu-spacegrey-set-mode-line-inactive-border spacegrey4 spacegrey7) :background ,bg-other :foreground ,spacegrey7 :distant-foreground ,bg-other))))

;;;; mu4e - light
     `(mu4e-forwarded-face ((,class (:foreground ,yellow))))
     `(mu4e-header-key-face ((,class (:foreground ,darkcyan))))
     `(mu4e-header-title-face ((,class (:foreground ,magenta))))
     `(mu4e-highlight-face ((,class (:foreground ,orange :weight bold))))
     `(mu4e-replied-face ((,class (:foreground ,darkcyan))))
     `(mu4e-title-face ((,class (:foreground ,magenta))))

;;;; mu4e-column-faces - light
     `(mu4e-column-faces-date ((,class (:foreground ,darkblue))))
     `(mu4e-column-faces-to-from ((,class (:foreground ,green))))

;;;; mu4e-thread-folding - light
     `(mu4e-thread-folding-child-face ((,class (:extend t :background ,bg-org :underline nil))))
     `(mu4e-thread-folding-root-folded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))
     `(mu4e-thread-folding-root-unfolded-face ((,class (:extend t :background ,bg-other :overline nil :underline nil))))

;;;; multiple cursors - light
     `(mc/cursor-face ((,class (:background ,orange))))

;;;; nano-modeline - light
     `(nano-modeline-active-name ((,class (:foreground ,fg :weight bold))))
     `(nano-modeline-inactive-name ((,class (:foreground ,spacegrey5 :weight bold))))
     `(nano-modeline-active-primary ((,class (:foreground ,fg))))
     `(nano-modeline-inactive-primary ((,class (:foreground ,spacegrey5))))
     `(nano-modeline-active-secondary ((,class (:foreground ,darkcyan :weight bold))))
     `(nano-modeline-inactive-secondary ((,class (:foreground ,spacegrey5 :weight bold))))
     `(nano-modeline-active-status-RO ((,class (:background ,red :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-RO ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))
     `(nano-modeline-active-status-RW ((,class (:background ,darkcyan :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-RW ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))
     `(nano-modeline-active-status-** ((,class (:background ,red :foreground ,bg :weight bold))))
     `(nano-modeline-inactive-status-** ((,class (:background ,spacegrey5 :foreground ,bg :weight bold))))

;;;; nav-flash - light
     `(nav-flash-face ((,class (:background ,grey :foreground ,spacegrey8 :weight bold))))

;;;; neotree - light
     `(neo-dir-link-face ((,class (:foreground ,orange))))
     `(neo-expand-btn-face ((,class (:foreground ,orange))))
     `(neo-file-link-face ((,class (:foreground ,fg))))
     `(neo-root-dir-face ((,class (:foreground ,green :background ,bg :box (:line-width 4 :color ,bg)))))
     `(neo-vc-added-face ((,class (:foreground ,green))))
     `(neo-vc-conflict-face ((,class (:foreground ,purple :weight bold))))
     `(neo-vc-edited-face ((,class (:foreground ,yellow))))
     `(neo-vc-ignored-face ((,class (:foreground ,spacegrey5))))
     `(neo-vc-removed-face ((,class (:foreground ,red :strike-through t))))

;;;; nlinum - light
     `(nlinum-current-line ((,class (:foreground ,fg))))

;;;; nlinum-hl - light
     `(nlinum-hl-face ((,class (:foreground ,fg))))

;;;; nlinum-relative - light
     `(nlinum-relative-current-face ((,class (:foreground ,fg))))

;;;; notmuch - light
     `(notmuch-message-summary-face ((,class (:foreground ,grey :background nil))))
     `(notmuch-search-count ((,class (:foreground ,spacegrey5))))
     `(notmuch-search-date ((,class (:foreground ,orange))))
     `(notmuch-search-flagged-face ((,class (:foreground ,red))))
     `(notmuch-search-matching-authors ((,class (:foreground ,darkblue))))
     `(notmuch-search-non-matching-authors ((,class (:foreground ,fg))))
     `(notmuch-search-subject ((,class (:foreground ,fg))))
     `(notmuch-search-unread-face ((,class (:weight bold))))
     `(notmuch-tag-added ((,class (:foreground ,green :weight normal))))
     `(notmuch-tag-deleted ((,class (:foreground ,red :weight normal))))
     `(notmuch-tag-face ((,class (:foreground ,yellow :weight normal))))
     `(notmuch-tag-flagged ((,class (:foreground ,yellow :weight normal))))
     `(notmuch-tag-unread ((,class (:foreground ,yellow :weight normal))))
     `(notmuch-tree-match-author-face ((,class (:foreground ,darkblue :weight bold))))
     `(notmuch-tree-match-date-face ((,class (:foreground ,orange :weight bold))))
     `(notmuch-tree-match-face ((,class (:foreground ,fg))))
     `(notmuch-tree-match-subject-face ((,class (:foreground ,fg))))
     `(notmuch-tree-match-tag-face ((,class (:foreground ,yellow))))
     `(notmuch-tree-match-tree-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-author-face ((,class (:foreground ,darkblue))))
     `(notmuch-tree-no-match-date-face ((,class (:foreground ,orange))))
     `(notmuch-tree-no-match-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-subject-face ((,class (:foreground ,spacegrey5))))
     `(notmuch-tree-no-match-tag-face ((,class (:foreground ,yellow))))
     `(notmuch-tree-no-match-tree-face ((,class (:foreground ,yellow))))
     `(notmuch-wash-cited-text ((,class (:foreground ,spacegrey4))))
     `(notmuch-wash-toggle-button ((,class (:foreground ,fg))))

;;;; orderless - light
     `(orderless-match-face-0 ((,class (:foreground ,darkblue :weight bold :underline t))))
     `(orderless-match-face-1 ((,class (:foreground ,teal :weight bold :underline t))))
     `(orderless-match-face-2 ((,class (:foreground ,darkcyan :weight bold :underline t))))
     `(orderless-match-face-3 ((,class (:foreground ,cyan :weight bold :underline t))))

;;;; objed - light
     `(objed-hl ((,class (:background ,grey))))
     `(objed-mode-line ((,class (:foreground ,yellow :weight bold))))

;;;; org-agenda - light
     `(org-agenda-clocking ((,class (:background ,darkblue))))
     `(org-agenda-date ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-date-today ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-date-weekend ((,class (:foreground ,magenta :weight ultra-bold))))
     `(org-agenda-dimmed-todo-face ((,class (:foreground ,spacegrey5))))
     `(org-agenda-done ((,class (:foreground ,spacegrey5))))
     `(org-agenda-structure ((,class (:foreground ,fg :weight ultra-bold))))
     `(org-scheduled ((,class (:foreground ,fg))))
     `(org-scheduled-previously ((,class (:foreground ,spacegrey8))))
     `(org-scheduled-today ((,class (:foreground ,spacegrey7))))
     `(org-sexp-date ((,class (:foreground ,fg))))
     `(org-time-grid ((,class (:foreground ,spacegrey5))))
     `(org-upcoming-deadline ((,class (:foreground ,fg))))
     `(org-upcoming-distant-deadline ((,class (:foreground ,fg))))

;;;; org-habit - light
     `(org-habit-alert-face ((,class (:weight bold :background ,yellow))))
     `(org-habit-alert-future-face ((,class (:weight bold :background ,yellow))))
     `(org-habit-clear-face ((,class (:weight bold :background ,spacegrey4))))
     `(org-habit-clear-future-face ((,class (:weight bold :background ,spacegrey3))))
     `(org-habit-overdue-face ((,class (:weight bold :background ,red))))
     `(org-habit-overdue-future-face ((,class (:weight bold :background ,red))))
     `(org-habit-ready-face ((,class (:weight bold :background ,darkblue))))
     `(org-habit-ready-future-face ((,class (:weight bold :background ,darkblue))))

;;;; org-journal - light
     `(org-journal-calendar-entry-face ((,class (:foreground ,purple :slant italic))))
     `(org-journal-calendar-scheduled-face ((,class (:foreground ,red :slant italic))))
     `(org-journal-highlight ((,class (:foreground ,orange))))

;;;; org-mode - light
     `(org-archived ((,class (:foreground ,spacegrey5))))
     `(org-block ((,class (:foreground ,fg :background ,bg-org :extend t ,@(timu-spacegrey-set-intense-org-colors bg-org bg-org)))))
     `(org-block-background ((,class (:background ,bg-org :extend t))))
     `(org-block-begin-line ((,class (:foreground ,spacegrey5 :slant italic :background ,bg-org :extend t ,@(timu-spacegrey-set-intense-org-colors bg l-grey)))))
     `(org-block-end-line ((,class (:foreground ,spacegrey5 :slant italic :background ,bg-org :extend t ,@(timu-spacegrey-set-intense-org-colors bg l-grey)))))
     `(org-checkbox ((,class (:foreground ,green :weight bold))))
     `(org-checkbox-statistics-done ((,class (:foreground ,spacegrey5))))
     `(org-checkbox-statistics-todo ((,class (:foreground ,green :weight bold))))
     `(org-code ((,class (:foreground ,green ,@(timu-spacegrey-set-intense-org-colors bg l-green)))))
     `(org-date ((,class (:foreground ,yellow))))
     `(org-default ((,class (:background ,bg :foreground ,fg))))
     `(org-document-info ((,class (:foreground ,orange ,@(timu-spacegrey-do-scale timu-spacegrey-scale-org-document-info 1.2) ,@(timu-spacegrey-set-intense-org-colors bg l-orange)))))
     `(org-document-title ((,class (:foreground ,orange :weight bold ,@(timu-spacegrey-do-scale timu-spacegrey-scale-org-document-title 1.3) ,@(timu-spacegrey-set-intense-org-colors orange l-orange)))))
     `(org-done ((,class (:foreground ,spacegrey5))))
     `(org-ellipsis ((,class (:underline nil :background nil :foreground ,grey))))
     `(org-footnote ((,class (:foreground ,orange))))
     `(org-formula ((,class (:foreground ,cyan))))
     `(org-headline-done ((,class (:foreground ,spacegrey5))))
     `(org-hide ((,class (:foreground ,bg))))
     `(org-latex-and-related ((,class (:foreground ,spacegrey8 :weight bold))))
     `(org-level-1 ((,class (:foreground ,darkblue :weight ultra-bold ,@(timu-spacegrey-do-scale timu-spacegrey-scale-org-document-info 1.3) ,@(timu-spacegrey-set-intense-org-colors blue l-blue)))))
     `(org-level-2 ((,class (:foreground ,magenta :weight bold ,@(timu-spacegrey-do-scale timu-spacegrey-scale-org-document-info 1.2) ,@(timu-spacegrey-set-intense-org-colors magenta l-magenta)))))
     `(org-level-3 ((,class (:foreground ,darkcyan :weight bold ,@(timu-spacegrey-do-scale timu-spacegrey-scale-org-document-info 1.1) ,@(timu-spacegrey-set-intense-org-colors darkcyan l-lightcyan)))))
     `(org-level-4 ((,class (:foreground ,orange ,@(timu-spacegrey-set-intense-org-colors orange l-orange)))))
     `(org-level-5 ((,class (:foreground ,green ,@(timu-spacegrey-set-intense-org-colors green l-green)))))
     `(org-level-6 ((,class (:foreground ,teal ,@(timu-spacegrey-set-intense-org-colors teal l-teal)))))
     `(org-level-7 ((,class (:foreground ,purple ,@(timu-spacegrey-set-intense-org-colors purple l-purple)))))
     `(org-level-8 ((,class (:foreground ,fg ,@(timu-spacegrey-set-intense-org-colors fg l-grey)))))
     `(org-link ((,class (:foreground ,darkcyan :underline t))))
     `(org-list-dt ((,class (:foreground ,orange))))
     `(org-meta-line ((,class (:foreground ,spacegrey5))))
     `(org-priority ((,class (:foreground ,red))))
     `(org-property-value ((,class (:foreground ,spacegrey5))))
     `(org-quote ((,class (:background ,spacegrey3 :slant italic :extend t))))
     `(org-special-keyword ((,class (:foreground ,spacegrey5))))
     `(org-table ((,class (:foreground ,magenta))))
     `(org-tag ((,class (:foreground ,spacegrey5 :weight normal))))
     `(org-todo ((,class (:foreground ,green :weight bold))))
     `(org-verbatim ((,class (:foreground ,orange ,@(timu-spacegrey-set-intense-org-colors bg l-orange)))))
     `(org-warning ((,class (:foreground ,yellow))))

;;;; org-pomodoro - light
     `(org-pomodoro-mode-line ((,class (:foreground ,red))))
     `(org-pomodoro-mode-line-overtime ((,class (:foreground ,yellow :weight bold))))

;;;; org-ref - light
     `(org-ref-acronym-face ((,class (:foreground ,magenta))))
     `(org-ref-cite-face ((,class (:foreground ,yellow :weight light :underline t))))
     `(org-ref-glossary-face ((,class (:foreground ,purple))))
     `(org-ref-label-face ((,class (:foreground ,darkblue))))
     `(org-ref-ref-face ((,class (:foreground ,teal :underline t :weight bold))))

;;;; outline - light
     `(outline-1 ((,class (:foreground ,darkblue :weight ultra-bold))))
     `(outline-2 ((,class (:foreground ,magenta :weight bold))))
     `(outline-3 ((,class (:foreground ,green :weight bold))))
     `(outline-4 ((,class (:foreground ,orange))))
     `(outline-5 ((,class (:foreground ,purple))))
     `(outline-6 ((,class (:foreground ,purple))))
     `(outline-7 ((,class (:foreground ,purple))))
     `(outline-8 ((,class (:foreground ,fg))))

;;;; parenface - light
     `(paren-face ((,class (:foreground ,spacegrey5))))

;;;; parinfer - light
     `(parinfer-pretty-parens:dim-paren-face ((,class (:foreground ,spacegrey5))))
     `(parinfer-smart-tab:indicator-face ((,class (:foreground ,spacegrey5))))

;;;; persp-mode - light
     `(persp-face-lighter-buffer-not-in-persp ((,class (:foreground ,spacegrey5))))
     `(persp-face-lighter-default ((,class (:foreground ,orange :weight bold))))
     `(persp-face-lighter-nil-persp ((,class (:foreground ,spacegrey5))))

;;;; perspective - light
     `(persp-selected-face ((,class (:foreground ,darkblue :weight bold))))

;;;; pkgbuild-mode - light
     `(pkgbuild-error-face ((,class (:underline (:style wave :color ,red)))))

;;;; popup - light
     `(popup-face ((,class (:background ,bg-other :foreground ,fg))))
     `(popup-selection-face ((,class (:background ,grey))))
     `(popup-tip-face ((,class (:foreground ,magenta :background ,bg-other))))

;;;; powerline - light
     `(powerline-active0 ((,class (:background ,spacegrey8 :foreground ,fg :distant-foreground ,bg))))
     `(powerline-active1 ((,class (:background ,spacegrey8 :foreground ,fg :distant-foreground ,bg))))
     `(powerline-active2 ((,class (:background ,spacegrey8 :foreground ,fg :distant-foreground ,bg))))
     `(powerline-inactive0 ((,class (:background ,spacegrey8 :foreground ,spacegrey5 :distant-foreground ,bg-other))))
     `(powerline-inactive1 ((,class (:background ,spacegrey8 :foreground ,spacegrey5 :distant-foreground ,bg-other))))
     `(powerline-inactive2 ((,class (:background ,spacegrey8 :foreground ,spacegrey5 :distant-foreground ,bg-other))))

;;;; rainbow-delimiters - light
     `(rainbow-delimiters-depth-1-face ((,class (:foreground ,darkblue))))
     `(rainbow-delimiters-depth-2-face ((,class (:foreground ,purple))))
     `(rainbow-delimiters-depth-3-face ((,class (:foreground ,green))))
     `(rainbow-delimiters-depth-4-face ((,class (:foreground ,orange))))
     `(rainbow-delimiters-depth-5-face ((,class (:foreground ,magenta))))
     `(rainbow-delimiters-depth-6-face ((,class (:foreground ,yellow))))
     `(rainbow-delimiters-depth-7-face ((,class (:foreground ,teal))))
     `(rainbow-delimiters-mismatched-face ((,class (:foreground ,red :weight bold :inverse-video t))))
     `(rainbow-delimiters-unmatched-face ((,class (:foreground ,red :weight bold :inverse-video t))))

;;;; re-builder - light
     `(reb-match-0 ((,class (:foreground ,orange :inverse-video t))))
     `(reb-match-1 ((,class (:foreground ,purple :inverse-video t))))
     `(reb-match-2 ((,class (:foreground ,green :inverse-video t))))
     `(reb-match-3 ((,class (:foreground ,yellow :inverse-video t))))

;;;; rjsx-mode - light
     `(rjsx-attr ((,class (:foreground ,darkblue))))
     `(rjsx-tag ((,class (:foreground ,yellow))))

;;;; rpm-spec-mode - light
     `(rpm-spec-dir-face ((,class (:foreground ,green))))
     `(rpm-spec-doc-face ((,class (:foreground ,orange))))
     `(rpm-spec-ghost-face ((,class (:foreground ,spacegrey5))))
     `(rpm-spec-macro-face ((,class (:foreground ,yellow))))
     `(rpm-spec-obsolete-tag-face ((,class (:foreground ,red))))
     `(rpm-spec-package-face ((,class (:foreground ,orange))))
     `(rpm-spec-section-face ((,class (:foreground ,purple))))
     `(rpm-spec-tag-face ((,class (:foreground ,darkblue))))
     `(rpm-spec-var-face ((,class (:foreground ,magenta))))

;;;; rst - light
     `(rst-block ((,class (:foreground ,orange))))
     `(rst-level-1 ((,class (:foreground ,magenta :weight bold))))
     `(rst-level-2 ((,class (:foreground ,magenta :weight bold))))
     `(rst-level-3 ((,class (:foreground ,magenta :weight bold))))
     `(rst-level-4 ((,class (:foreground ,magenta :weight bold))))
     `(rst-level-5 ((,class (:foreground ,magenta :weight bold))))
     `(rst-level-6 ((,class (:foreground ,magenta :weight bold))))

;;;; selectrum - light
     `(selectrum-current-candidate ((,class (:background ,grey :distant-foreground nil :extend t))))

;;;; sh-script - light
     `(sh-heredoc ((,class (:foreground ,green))))
     `(sh-quoted-exec ((,class (:foreground ,fg :weight bold))))

;;;; show-paren - light
     `(show-paren-match ((,class (:foreground ,red :weight ultra-bold :underline ,red))))
     `(show-paren-mismatch ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))

;;;; smart-mode-line - light
     `(sml/charging ((,class (:foreground ,green))))
     `(sml/discharging ((,class (:foreground ,yellow :weight bold))))
     `(sml/filename ((,class (:foreground ,magenta :weight bold))))
     `(sml/git ((,class (:foreground ,darkblue))))
     `(sml/modified ((,class (:foreground ,cyan))))
     `(sml/outside-modified ((,class (:foreground ,cyan))))
     `(sml/process ((,class (:weight bold))))
     `(sml/read-only ((,class (:foreground ,cyan))))
     `(sml/sudo ((,class (:foreground ,orange :weight bold))))
     `(sml/vc-edited ((,class (:foreground ,green))))

;;;; smartparens - light
     `(sp-pair-overlay-face ((,class (:background ,grey))))
     `(sp-show-pair-match-face ((,class (:foreground ,red :background ,spacegrey0 :weight ultra-bold))))
     `(sp-show-pair-mismatch-face ((,class (:foreground ,spacegrey0 :background ,red :weight ultra-bold))))

;;;; smerge-tool - light
     `(smerge-base ((,class (:background ,darkblue))))
     `(smerge-lower ((,class (:background ,green))))
     `(smerge-markers ((,class (:background ,spacegrey5 :foreground ,bg :distant-foreground ,fg :weight bold))))
     `(smerge-mine ((,class (:background ,red))))
     `(smerge-other ((,class (:background ,green))))
     `(smerge-refined-added ((,class (:foreground ,bg  :background ,green :extend t))))
     `(smerge-refined-removed ((,class (:foreground ,bg :background ,red :extend t))))
     `(smerge-upper ((,class (:background ,red))))

;;;; solaire-mode - light
     `(solaire-default-face ((,class (:foreground ,fg :background ,bg-other))))
     `(solaire-hl-line-face ((,class (:background ,bg-other :extend t))))
     `(solaire-mode-line-face ((,class (:background ,bg :foreground ,fg :distant-foreground ,bg))))
     `(solaire-mode-line-inactive-face ((,class (:background ,bg-other :foreground ,fg-other :distant-foreground ,bg-other))))
     `(solaire-org-hide-face ((,class (:foreground ,bg))))

;;;; spaceline - light
     `(spaceline-evil-emacs ((,class (:background ,cyan))))
     `(spaceline-evil-insert ((,class (:background ,green))))
     `(spaceline-evil-motion ((,class (:background ,purple))))
     `(spaceline-evil-normal ((,class (:background ,darkblue))))
     `(spaceline-evil-replace ((,class (:background ,orange))))
     `(spaceline-evil-visual ((,class (:background ,grey))))
     `(spaceline-flycheck-error ((,class (:foreground ,red :distant-background ,spacegrey0))))
     `(spaceline-flycheck-info ((,class (:foreground ,green :distant-background ,spacegrey0))))
     `(spaceline-flycheck-warning ((,class (:foreground ,yellow :distant-background ,spacegrey0))))
     `(spaceline-highlight-face ((,class (:background ,orange))))
     `(spaceline-modified ((,class (:background ,orange))))
     `(spaceline-python-venv ((,class (:foreground ,purple :distant-foreground ,magenta))))
     `(spaceline-unmodified ((,class (:background ,orange))))

;;;; stripe-buffer - light
     `(stripe-highlight ((,class (:background ,spacegrey3))))

;;;; swiper - light
     `(swiper-line-face ((,class (:background ,darkblue :foreground ,spacegrey0))))
     `(swiper-match-face-1 ((,class (:background ,spacegrey0 :foreground ,spacegrey5))))
     `(swiper-match-face-2 ((,class (:background ,orange :foreground ,spacegrey0 :weight bold))))
     `(swiper-match-face-3 ((,class (:background ,purple :foreground ,spacegrey0 :weight bold))))
     `(swiper-match-face-4 ((,class (:background ,green :foreground ,spacegrey0 :weight bold))))

;;;; tabbar - light
     `(tabbar-button ((,class (:foreground ,fg :background ,bg))))
     `(tabbar-button-highlight ((,class (:foreground ,fg :background ,bg :inverse-video t))))
     `(tabbar-default ((,class (:foreground ,fg :background ,bg :height 1.0))))
     `(tabbar-highlight ((,class (:foreground ,fg :background ,grey :distant-foreground ,bg))))
     `(tabbar-modified ((,class (:foreground ,red :weight bold :height 1.0))))
     `(tabbar-selected ((,class (:weight bold :foreground ,fg :background ,bg-other :height 1.0))))
     `(tabbar-selected-modified ((,class (:background ,bg-other :foreground ,green))))
     `(tabbar-unselected ((,class (:foreground ,spacegrey5))))
     `(tabbar-unselected-modified ((,class (:foreground ,red :weight bold :height 1.0))))

;;;; tab-bar - light
     `(tab-bar ((,class (:background ,bg-other :foreground ,bg-other))))
     `(tab-bar-tab ((,class (:background ,bg :foreground ,fg))))
     `(tab-bar-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; tab-line - light
     `(tab-line ((,class (:background ,bg-other :foreground ,bg-other))))
     `(tab-line-close-highlight ((,class (:foreground ,orange))))
     `(tab-line-highlight ((,class (:background ,bg :foreground ,fg))))
     `(tab-line-tab ((,class (:background ,bg :foreground ,fg))))
     `(tab-line-tab-current ((,class (:background ,bg :foreground ,fg))))
     `(tab-line-tab-inactive ((,class (:background ,bg-other :foreground ,fg-other))))

;;;; telephone-line - light
     `(telephone-line-accent-active ((,class (:foreground ,fg :background ,spacegrey4))))
     `(telephone-line-accent-inactive ((,class (:foreground ,fg :background ,spacegrey2))))
     `(telephone-line-evil ((,class (:foreground ,fg :weight bold))))
     `(telephone-line-evil-emacs ((,class (:background ,purple :weight bold))))
     `(telephone-line-evil-insert ((,class (:background ,green :weight bold))))
     `(telephone-line-evil-motion ((,class (:background ,darkblue :weight bold))))
     `(telephone-line-evil-normal ((,class (:background ,red :weight bold))))
     `(telephone-line-evil-operator ((,class (:background ,magenta :weight bold))))
     `(telephone-line-evil-replace ((,class (:background ,bg-other :weight bold))))
     `(telephone-line-evil-visual ((,class (:background ,orange :weight bold))))
     `(telephone-line-projectile ((,class (:foreground ,green))))

;;;; term - light
     `(term ((,class (:foreground ,fg))))
     `(term-bold ((,class (:weight bold))))
     `(term-color-black ((,class (:foreground ,spacegrey0))))
     `(term-color-blue ((,class (:foreground ,darkblue))))
     `(term-color-cyan ((,class (:foreground ,cyan))))
     `(term-color-green ((,class (:foreground ,green))))
     `(term-color-magenta ((,class (:foreground ,magenta))))
     `(term-color-purple ((,class (:foreground ,purple))))
     `(term-color-red ((,class (:foreground ,red))))
     `(term-color-white ((,class (:foreground ,spacegrey8))))
     `(term-color-yellow ((,class (:foreground ,yellow))))
     `(term-color-bright-black ((,class (:foreground ,spacegrey0))))
     `(term-color-bright-blue ((,class (:foreground ,darkblue))))
     `(term-color-bright-cyan ((,class (:foreground ,cyan))))
     `(term-color-bright-green ((,class (:foreground ,green))))
     `(term-color-bright-magenta ((,class (:foreground ,magenta))))
     `(term-color-bright-purple ((,class (:foreground ,purple))))
     `(term-color-bright-red ((,class (:foreground ,red))))
     `(term-color-bright-white ((,class (:foreground ,spacegrey8))))
     `(term-color-bright-yellow ((,class (:foreground ,yellow))))

;;;; tldr - light
     `(tldr-code-block ((,class (:foreground ,green :background ,grey :weight semi-bold))))
     `(tldr-command-argument ((,class (:foreground ,fg :background ,grey))))
     `(tldr-command-itself ((,class (:foreground ,bg :background ,green :weight semi-bold))))
     `(tldr-description ((,class (:foreground ,fg :weight semi-bold))))
     `(tldr-introduction ((,class (:foreground ,darkblue :weight semi-bold))))
     `(tldr-title ((,class (:foreground ,yellow :bold t :height 1.4))))

;;;; treemacs - light
     `(treemacs-directory-face ((,class (:foreground ,fg))))
     `(treemacs-file-face ((,class (:foreground ,fg))))
     `(treemacs-git-added-face ((,class (:foreground ,green))))
     `(treemacs-git-conflict-face ((,class (:foreground ,red))))
     `(treemacs-git-modified-face ((,class (:foreground ,magenta))))
     `(treemacs-git-untracked-face ((,class (:foreground ,spacegrey5 :slant italic))))
     `(treemacs-root-face ((,class (:foreground ,green :weight bold :height 1.2))))
     `(treemacs-tags-face ((,class (:foreground ,orange))))

;;;; treemacs-all-the-icons - light
     `(treemacs-all-the-icons-file-face ((,class (:foreground ,darkblue))))
     `(treemacs-all-the-icons-root-face ((,class (:foreground ,fg))))

;;;; tree-sitter-hl - light
     `(tree-sitter-hl-face:function ((,class (:foreground ,darkblue))))
     `(tree-sitter-hl-face:function.call ((,class (:foreground ,darkblue))))
     `(tree-sitter-hl-face:function.builtin ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:function.special ((,class (:foreground ,fg :weight bold))))
     `(tree-sitter-hl-face:function.macro ((,class (:foreground ,fg :weight bold))))
     `(tree-sitter-hl-face:method ((,class (:foreground ,darkblue))))
     `(tree-sitter-hl-face:method.call ((,class (:foreground ,red))))
     `(tree-sitter-hl-face:type ((,class (:foreground ,yellow))))
     `(tree-sitter-hl-face:type.parameter ((,class (:foreground ,darkcyan))))
     `(tree-sitter-hl-face:type.argument ((,class (:foreground ,yellow))))
     `(tree-sitter-hl-face:type.builtin ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:type.super ((,class (:foreground ,yellow))))
     `(tree-sitter-hl-face:constructor ((,class (:foreground ,yellow))))
     `(tree-sitter-hl-face:variable ((,class (:foreground ,darkcyan))))
     `(tree-sitter-hl-face:variable.parameter ((,class (:foreground ,darkcyan))))
     `(tree-sitter-hl-face:variable.builtin ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:variable.special ((,class (:foreground ,yellow))))
     `(tree-sitter-hl-face:property ((,class (:foreground ,magenta))))
     `(tree-sitter-hl-face:property.definition ((,class (:foreground ,darkcyan))))
     `(tree-sitter-hl-face:comment ((,class (:foreground ,spacegrey5 :slant italic))))
     `(tree-sitter-hl-face:doc ((,class (:foreground ,spacegrey5 :slant italic))))
     `(tree-sitter-hl-face:string ((,class (:foreground ,green))))
     `(tree-sitter-hl-face:string.special ((,class (:foreground ,green :weight bold))))
     `(tree-sitter-hl-face:escape ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:embedded ((,class (:foreground ,fg))))
     `(tree-sitter-hl-face:keyword ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:operator ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:label ((,class (:foreground ,fg))))
     `(tree-sitter-hl-face:constant ((,class (:foreground ,magenta))))
     `(tree-sitter-hl-face:constant.builtin ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:number ((,class (:foreground ,magenta))))
     `(tree-sitter-hl-face:punctuation ((,class (:foreground ,fg))))
     `(tree-sitter-hl-face:punctuation.bracket ((,class (:foreground ,fg))))
     `(tree-sitter-hl-face:punctuation.delimiter ((,class (:foreground ,fg))))
     `(tree-sitter-hl-face:punctuation.special ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:tag ((,class (:foreground ,orange))))
     `(tree-sitter-hl-face:attribute ((,class (:foreground ,fg))))

;;;; typescript-mode - light
     `(typescript-jsdoc-tag ((,class (:foreground ,spacegrey5))))
     `(typescript-jsdoc-type ((,class (:foreground ,spacegrey5))))
     `(typescript-jsdoc-value ((,class (:foreground ,spacegrey5))))

;;;; undo-tree - light
     `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,darkblue))))
     `(undo-tree-visualizer-current-face ((,class (:foreground ,green :weight bold))))
     `(undo-tree-visualizer-default-face ((,class (:foreground ,spacegrey5))))
     `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow))))
     `(undo-tree-visualizer-unmodified-face ((,class (:foreground ,spacegrey5))))

;;;; vimish-fold - light
     `(vimish-fold-fringe ((,class (:foreground ,purple))))
     `(vimish-fold-overlay ((,class (:foreground ,spacegrey5 :slant italic :background ,spacegrey0 :weight light))))

;;;; volatile-highlights - light
     `(vhl/default-face ((,class (:background ,grey))))

;;;; vterm - light
     `(vterm ((,class (:foreground ,fg))))
     `(vterm-color-black ((,class (:background ,spacegrey0 :foreground ,spacegrey0))))
     `(vterm-color-blue ((,class (:background ,darkblue :foreground ,darkblue))))
     `(vterm-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
     `(vterm-color-default ((,class (:foreground ,fg))))
     `(vterm-color-green ((,class (:background ,green :foreground ,green))))
     `(vterm-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
     `(vterm-color-purple ((,class (:background ,purple :foreground ,purple))))
     `(vterm-color-red ((,class (:background ,red :foreground ,red))))
     `(vterm-color-white ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))
     `(vterm-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

;;;; web-mode - light
     `(web-mode-block-control-face ((,class (:foreground ,orange))))
     `(web-mode-block-control-face ((,class (:foreground ,orange))))
     `(web-mode-block-delimiter-face ((,class (:foreground ,orange))))
     `(web-mode-css-property-name-face ((,class (:foreground ,yellow))))
     `(web-mode-doctype-face ((,class (:foreground ,spacegrey5))))
     `(web-mode-html-attr-name-face ((,class (:foreground ,yellow))))
     `(web-mode-html-attr-value-face ((,class (:foreground ,green))))
     `(web-mode-html-entity-face ((,class (:foreground ,cyan :slant italic))))
     `(web-mode-html-tag-bracket-face ((,class (:foreground ,darkblue))))
     `(web-mode-html-tag-bracket-face ((,class (:foreground ,fg))))
     `(web-mode-html-tag-face ((,class (:foreground ,darkblue))))
     `(web-mode-json-context-face ((,class (:foreground ,green))))
     `(web-mode-json-key-face ((,class (:foreground ,green))))
     `(web-mode-keyword-face ((,class (:foreground ,magenta))))
     `(web-mode-string-face ((,class (:foreground ,green))))
     `(web-mode-type-face ((,class (:foreground ,yellow))))

;;;; wgrep - light
     `(wgrep-delete-face ((,class (:foreground ,spacegrey3 :background ,red))))
     `(wgrep-done-face ((,class (:foreground ,darkblue))))
     `(wgrep-face ((,class (:weight bold :foreground ,green :background ,spacegrey5))))
     `(wgrep-file-face ((,class (:foreground ,spacegrey5))))
     `(wgrep-reject-face ((,class (:foreground ,red :weight bold))))

;;;; which-func - light
     `(which-func ((,class (:foreground ,darkblue))))

;;;; which-key - light
     `(which-key-command-description-face ((,class (:foreground ,darkblue))))
     `(which-key-group-description-face ((,class (:foreground ,magenta))))
     `(which-key-key-face ((,class (:foreground ,green))))
     `(which-key-local-map-description-face ((,class (:foreground ,purple))))

;;;; whitespace - light
     `(whitespace-empty ((,class (:background ,spacegrey3))))
     `(whitespace-indentation ((,class (:foreground ,spacegrey4 :background ,spacegrey3))))
     `(whitespace-line ((,class (:background ,spacegrey0 :foreground ,red :weight bold))))
     `(whitespace-newline ((,class (:foreground ,spacegrey4))))
     `(whitespace-space ((,class (:foreground ,spacegrey4))))
     `(whitespace-tab ((,class (:foreground ,spacegrey4 :background ,spacegrey3))))
     `(whitespace-trailing ((,class (:background ,red))))

;;;; widget - light
     `(widget-button ((,class (:foreground ,fg :weight bold))))
     `(widget-button-pressed ((,class (:foreground ,red))))
     `(widget-documentation ((,class (:foreground ,green))))
     `(widget-field ((,class (:foreground ,fg :background ,spacegrey8 :extend nil))))
     `(widget-inactive ((,class (:foreground ,grey :background ,bg-other))))
     `(widget-single-line-field ((,class (:foreground ,fg :background ,spacegrey8))))

;;;; window-divider - light
     `(window-divider ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))
     `(window-divider-first-pixel ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))
     `(window-divider-last-pixel ((,class (:background ,spacegrey8 :foreground ,spacegrey8))))

;;;; woman - light
     `(woman-bold ((,class (:weight bold :foreground ,fg))))
     `(woman-italic ((,class (:underline t :foreground ,magenta))))

;;;; workgroups2 - light
     `(wg-brace-face ((,class (:foreground ,orange))))
     `(wg-current-workgroup-face ((,class (:foreground ,spacegrey0 :background ,orange))))
     `(wg-divider-face ((,class (:foreground ,grey))))
     `(wg-other-workgroup-face ((,class (:foreground ,spacegrey5))))

;;;; yasnippet - light
     `(yas-field-highlight-face ((,class (:foreground ,green :background ,spacegrey0 :weight bold))))

;;;; ytel - light
     `(ytel-video-published-face ((,class (:foreground ,magenta))))
     `(ytel-channel-name-face ((,class (:foreground ,orange))))
     `(ytel-video-length-face ((,class (:foreground ,darkblue))))
     `(ytel-video-view-face ((,class (:foreground ,darkcyan))))

     (custom-theme-set-variables
      'timu-spacegrey
      `(ansi-color-names-vector [bg, red, green, teal, cyan, blue, yellow, fg])))))


;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory
                (file-name-directory load-file-name))))

(provide-theme 'timu-spacegrey)

;;; timu-spacegrey-theme.el ends here
