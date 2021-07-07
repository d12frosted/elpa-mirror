;;; blackboard-theme.el --- TextMate Blackboard Theme

;; MIT License Copyright (c) 2008 JD Huntington <jdhuntington at gmail dot com>
;; Credits due to the excellent TextMate Blackboard theme
;;
;; All patches welcome

;; --------------

;; Author: Dong Zheng
;; Version: 1.0
;; Package-Version: 20161216.656
;; Package-Commit: 7a0d79410feb728ff5cce75c140fadc19a3f9a6d
;; Package-Requires: ((emacs "24"))
;; URL: https://github.com/don9z/blackboard-theme

;;; Commentary:

;; This porting makes blackboard-theme no longer rely on color-theme package

;; How to use:
;; First, add a local directory to custome-theme-load-path,
;; (add-to-list 'custom-theme-load-path "~/home/$USER/drop/the/theme/to")
;; Then drop this theme into it,
;; M-x load-theme, then choose blackboard, it should work
;; Or, simple use (load-theme 'blackboard t) to enable the theme from start.

;;; Code:

(deftheme blackboard
  "Based on Color theme by JD Huntington, which based off the TextMate Blackboard theme, created 2008-11-27")

(custom-theme-set-faces
 `blackboard
 `(default ((t (:background "#0C1021" :foreground "#F8F8F8" ))))
 `(bold ((t (:bold t))))
 `(bold-italic ((t (:bold t))))
 `(border-glyph ((t (nil))))
 `(buffers-tab ((t (:background "#0C1021" :foreground "#F8F8F8"))))
 `(font-lock-builtin-face ((t (:foreground "#94bff3"))))
 `(font-lock-comment-face ((t (:italic t :foreground "#AEAEAE"))))
 `(font-lock-constant-face ((t (:foreground "#D8FA3C"))))
 `(font-lock-doc-string-face ((t (:foreground "DarkOrange"))))
 `(font-lock-function-name-face ((t (:foreground "#FF6400"))))
 `(font-lock-keyword-face ((t (:foreground "#FBDE2D"))))
 `(font-lock-preprocessor-face ((t (:foreground "Aquamarine"))))
 `(font-lock-reference-face ((t (:foreground "SlateBlue"))))

 `(font-lock-regexp-grouping-backslash ((t (:foreground "#E9C062"))))
 `(font-lock-regexp-grouping-construct ((t (:foreground "red"))))

 ;; org-mode
 `(org-hide ((t (:foreground "#2e3436"))))
 `(org-level-1 ((t (:bold nil :foreground "dodger blue" :height 1.3))))
 `(org-level-2 ((t (:bold nil :foreground "#edd400" :height 1.2))))
 `(org-level-3 ((t (:bold nil :foreground "#6ac214" :height 1.1))))
 `(org-level-4 ((t (:bold nil :foreground "tomato" :height 1.0))))
 `(org-date ((t (:underline t :foreground "magenta3"))))
 `(org-footnote  ((t (:underline t :foreground "magenta3"))))
 `(org-link ((t (:foreground "skyblue2" :background "#2e3436"))))
 `(org-special-keyword ((t (:foreground "brown"))))
 `(org-verbatim ((t (:foreground "#eeeeec" :underline t :slant italic))))
 `(org-block ((t (:foreground "#bbbbbc"))))
 `(org-quote ((t (:inherit org-block :slant italic))))
 `(org-verse ((t (:inherit org-block :slant italic))))
 `(org-todo ((t (:bold t :foreground "Red"))))
 `(org-done ((t (:bold t :foreground "ForestGreen"))))
 `(org-agenda-structure ((t (:weight bold :foreground "tomato"))))
 `(org-agenda-date ((t (:foreground "#6ac214"))))
 `(org-agenda-date-weekend ((t (:weight normal :foreground "dodger blue"))))
 `(org-agenda-date-today ((t (:weight bold :foreground "#edd400"))))

 `(font-lock-string-face ((t (:foreground "#61CE3C"))))
 `(font-lock-type-face ((t (:foreground "#8DA6CE"))))
 `(font-lock-variable-name-face ((t (:foreground "#FF6400"))))
 `(font-lock-warning-face ((t (:bold t :foreground "pink"))))
 `(gui-element ((t (:background "#D4D0C8" :foreground "black"))))
 `(region ((t (:background "#253B76"))))
 `(mode-line ((t (:background "grey75" :foreground "black"))))
 `(highlight ((t (:background "#222222"))))
 `(highline-face ((t (:background "SeaGreen"))))
 `(italic ((t (nil))))
 `(left-margin ((t (nil))))
 `(text-cursor ((t (:background "yellow" :foreground "black"))))
 `(toolbar ((t (nil))))
 `(underline ((nil (:underline nil))))
 `(zmacs-region ((t (:background "snow" :foreground "ble")))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'blackboard)

;;; blackboard-theme.el ends here.
