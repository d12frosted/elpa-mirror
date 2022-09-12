;;; qtcreator-theme.el --- A color theme that mimics Qt Creator IDE
;;
;; Copyright (C) 2020 Lesley Lai
;;
;; Author: Lesley Lai <lesley@lesleylai.info>
;; Version: 0.1.0
;; Package-Version: 20201215.1523
;; Package-Commit: 515532b05063898459157d2ba5c10ec0d5a4b1bd
;; Package-Requires: ((emacs "24.3"))
;; Keywords: theme light faces
;; URL: https://github.com/LesleyLai/emacs-qtcreator-theme
;;
;; This file is not part of GNU Emacs.
;;
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.
;;
;;; Commentary:
;;
;; Qt Creator Theme is a color theme that mimics the default color
;; scheme of the Qt Creator IDE.
;;
;;; Credits:
;;
;; Lesley Lai came up with the color scheme.
;;
;;; Code:


(deftheme qtcreator
  "Mimics the Qt Creator's default color theme.")

(defgroup qtcreator-theme nil
  "Qtcreator theme options. Reload the theme after changing to see effect."
  :group 'faces)

(unless (>= emacs-major-version 24)
  (error "The qtcreator-theme requires Emacs 24 or later"))

(let ((class '((class color) (min-colors 89)))
      (white "#FFFFFF") (black "#000000")

      (bg-0 "#EFEFEF") (bg-1 "#e7e7e7") (bg-2 "#dfdfdf") (bg-3 "#c6c7c7")
      (fg-0 "#ABABAB") (fg-1 "#888888") (fg-2 "#383a42") (fg-3 "#1b2229")
      (red-0 "#FE0000")
      (orange-1 "#ce5c00") (orange-2 "#b35000") (orange-3 "#EFC846")
      (yellow-0 "#FEEE0B") (yellow-1 "#808000")
      (green-0 "#008000") (green-1 "#B4EDB3")
      (blue-0 "#2D83DE") (blue-1 "#0000FE") (blue-2 "#000080") (blue-3 "#EAEAFF")
      (cyan-1 "#00677C")
      (purple-0 "#800080"))

  (custom-theme-set-faces
   'qtcreator

   ;; Built-in
   ;; basic coloring
   `(default ((t (:foreground , black :background , white))))
   `(fringe ((,class (:background ,bg-0))))
   `(region ((t (:foreground ,white :background ,blue-0))))
   `(isearch ((,class (:foreground ,white :background ,orange-1))))
   `(lazy-highlight ((,class (:background ,yellow-0))))
   `(show-paren-match ((,t (:background ,green-1 :foreground ,red-0))))

   ;; Font lock faces
   `(font-lock-builtin-face ((,t (:foreground ,yellow-1))))
   `(font-lock-comment-face ((,t (:foreground ,green-0))))
   `(font-lock-comment-delimiter-face((t (:inherit font-lock-comment-face))))
   `(font-lock-constant-face ((,t (:foreground ,blue-2))))
   `(font-lock-doc-face ((,class (:foreground ,blue-2))))
   `(font-lock-function-name-face ((,class (:foreground ,orange-2))))
   `(font-lock-keyword-face ((,class (:foreground ,yellow-1))))
   `(font-lock-string-face ((,class (:foreground ,green-0))))
   `(font-lock-type-face ((,class (:foreground ,purple-0))))
   `(font-lock-preprocessor-face ((,class (:foreground ,blue-2))))
   `(font-lock-variable-name-face ((,class (:foreground ,orange-2))))
   `(font-lock-warning-face ((,t (:foreground ,red-0 :weight bold))))

   ;; Modeline
   `(mode-line ((t (:foreground , black :background , bg-2))))
   `(mode-line-inactive ((t (:foreground , fg-3 :background , bg-3))))

   ;; Link faces
   `(link ((,class (:underline t :foreground ,blue-1))))
   ;; `(link-visited ((,class (:underline t :foreground ,blue-2))))

   ;; Line-number-mode
   `(line-number ((,class (:inherit default :background ,bg-0 :foreground ,fg-0))))
   `(line-number-current-line ((t :inherit line-number :weight bold :foreground ,fg-1)))

   ;; fill-column-indicator
   `(fill-column-indicator ((,class (:foreground ,bg-2))))

   ;; merlin
   `(merlin-eldoc-occurrences-face((t (:inherit idle-highlight-face))))

   ;; flycheck
   `(flycheck-error
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,red-0) :inherit unspecified))
      (t (:foreground ,red-0 :weight bold :underline t))))
   `(flycheck-warning
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,orange-3) :inherit unspecified))
      (t (:foreground ,orange-3 :weight bold :underline t))))
   `(flycheck-info
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,green-0) :inherit unspecified))
      (t (:foreground ,green-0 :weight bold :underline t))))
   `(flycheck-fringe-error ((t (:foreground ,red-0 :weight bold))))
   `(flycheck-fringe-warning ((t (:foreground ,orange-3 :weight bold))))
   `(flycheck-fringe-info ((t (:foreground ,green-0 :weight bold))))

   ;; org-mode
   `(org-code
     ((t (:foreground ,black :background ,white :box (:line-width 2 :color "grey75")))))
   `(org-block
     ((t (:foreground ,black :background "#F8FBFD"))))
   `(org-block-begin-line
     ((t (:underline "#A7A6AA" :foreground "#008ED1" :background ,blue-3))))
   `(org-block-end-line
     ((t (:overline "#A7A6AA" :foreground "#008ED1" :background ,blue-3))))
   `(org-ellipsis ((t (:foreground ,fg-2 :underline nil))))

   ;; org-agenda
   `(org-agenda-structure ((t (:foreground ,blue-2 :weight extra-bold))))
   `(org-super-agenda-header ((t (:inherit org-agenda-structure :background ,blue-3 :overline t))))

   ;; Highlight doxygen mode
   `(highlight-doxygen-comment ((t (:inherit font-lock-doc-face))))
   `(highlight-doxygen-command ((t (:foreground ,blue-1 :weight bold))))

  `(vterm-color-black ((t (:foreground "#16161C" :background "#1A1C23"))))
  `(vterm-color-blue ((t (:foreground "#26BBD9" :background "#3FC6DE"))))
  `(vterm-color-cyan ((t (:foreground "#59E3E3" :background "#6BE6E6"))))
  `(vterm-color-green ((t (:foreground "#29D398" :background "#3FDAA4"))))
  `(vterm-color-magenta ((t (:foreground "#EE64AE" :background "#F075B7"))))
  `(vterm-color-red ((t (:foreground "#E95678" :background "#EC6A88"))))
  `(vterm-color-white ((t (:foreground "#FDF0ED" :background "#FADAD1"))))

  ;; lsp-mode
  `(lsp-ui-sideline-code-action ((t (:foreground ,green-0))))))

  (custom-theme-set-variables
   'qtcreator
   `(git-gutter:modified-sign "✱")
   `(org-hide-emphasis-markers t)
   `(org-ellipsis " ▾"))

;;----------------------------------------------------------------------------


;;;###autoload
(when (and load-file-name (boundp 'custom-theme-load-path))
  (add-to-list
   'custom-theme-load-path
   (file-name-directory load-file-name)))
(provide-theme 'qtcreator)

(provide 'qtcreator-theme)
;;; qtcreator-theme.el ends here
