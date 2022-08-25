;;; twilight-bright-theme.el --- A Emacs 24 faces port of the TextMate theme
;;
;; Copyright (c) 2012 Jim Myhrberg.
;;
;; Author: Jim Myhrberg <contact@jimeh.me>
;; Version: 0.1.0
;; Package-Version: 20130605.843
;; Package-Commit: 9859474333fee9f907474dbd8763f617e8bfd89c
;; Keywords: themes
;; URL: https://github.com/jimeh/twilight-bright-theme.el
;;
;; This file is NOT part of GNU Emacs.
;;
;;; License:
;;
;; Permission is hereby granted, free of charge, to any person obtaining a
;; copy of this software and associated documentation files (the "Software"),
;; to deal in the Software without restriction, including without limitation
;; the rights to use, copy, modify, merge, publish, distribute, sublicense,
;; and/or sell copies of the Software, and to permit persons to whom the
;; Software is furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;; DEALINGS IN THE SOFTWARE.
;;
;;; Credit:
;;
;; The original TextMate version created by Florian Pichler is available here:
;; http://einserver.de/goodies
;;
;;; Commentary:
;;
;; This is not a straight up port as some colors have been slightly tweaked
;; and some were simply invented as the original TextMate version didn't
;; include any colors that would fit.
;;
;;; Code:

(deftheme twilight-bright
  "A soothing dark-on-light theme.")

(let ((background "#FFFFFF")
      (foreground "#505050")
      (selection "#c7e1f2")
      (hl-line "#f5f5f5")
      (cursor "#b4b4b4")

      (gray-1 "#a49da5") (gray-1bg "#f7f7f7")
      (gray-2 "#d9d9d9")
      (gray-3 "#b3adb4") (gray-3bg "#eaeaea")
      (gray-4 "#c8c8c8")
      (gray-5 "#efefef")
      (red-1 "#d15120") (red-1bg "#fdf2ed")
      (red-2 "#b23f1e") (red-2bg "#fcf3f1")
      (brown-1 "#9f621d") (brown-1bg "#fdf2ed")
      (orange-1 "#cf7900") (orange-1bg "#fdf9f2")
      (yellow-1 "#d2ad00") (yellow-1bg "#faf7e7")
      (green-1 "#5f9411") (green-1bg "#eff8e9")
      (blue-1 "#6b82a7") (blue-1bg "#f1f4f8")
      (blue-2 "#417598") (blue-2bg "#e3f4ff")
      (purple-1 "#a66bab") (purple-1bg "#f8f1f8")
      )

  (custom-theme-set-faces
   'twilight-bright

   ;; Basics
   `(default ((t (:background ,background :foreground ,foreground))))
   `(cursor ((t (:background ,cursor))))
   `(region ((t (:background ,selection))))
   `(highlight ((t (:foreground ,blue-2 :background ,blue-2bg))))
   `(hl-line ((t (:background ,hl-line))))
   `(minibuffer-prompt ((t (:foreground ,orange-1 :background ,orange-1bg))))
   `(escape-glyph ((t (:foreground ,purple-1 :background , purple-1bg))))

   ;; Font-lock stuff
   `(font-lock-builtin-face ((t (:foreground ,yellow-1 :background ,yellow-1bg))))
   `(font-lock-constant-face ((t (:foreground ,purple-1 :background ,purple-1bg))))
   `(font-lock-comment-face ((t (:foreground ,gray-1 :background ,gray-1bg :italic t))))
   `(font-lock-doc-face ((t (:foreground ,gray-1 :background ,gray-1bg))))
   `(font-lock-doc-string-face ((t (:foreground ,gray-1 :background ,gray-1bg))))
   `(font-lock-function-name-face ((t (:foreground ,red-1 :background ,red-1bg))))
   `(font-lock-keyword-face ((t (:foreground ,orange-1 :background ,orange-1bg))))
   `(font-lock-negation-char-face ((t (:foreground ,yellow-1 :background ,yellow-1bg))))
   `(font-lock-preprocessor-face ((t (:foreground ,orange-1 :background ,orange-1bg))))
   `(font-lock-string-face ((t (:foreground ,green-1 :background ,green-1bg))))
   `(font-lock-type-face ((t (:foreground ,red-2 :background ,red-2bg :bold nil))))
   `(font-lock-variable-name-face ((t (:foreground ,blue-1 :background ,blue-1bg))))
   `(font-lock-warning-face ((t (:foreground ,red-1 :background ,red-1bg))))

   ;; UI related
   `(link ((t (:foreground ,blue-1 :background ,blue-1bg))))
   `(fringe ((t (:background ,gray-1bg))))
   `(mode-line ((t (:foreground ,blue-2 :background ,blue-2bg))))
   `(mode-line-inactive ((t (:foreground ,gray-1 :background ,gray-3bg))))
   `(vertical-border ((t (:background ,background :foreground ,gray-4))))

   ;; Linum
   `(linum ((t (:foreground ,gray-2 :background ,gray-1bg))))

   ;; show-paren-mode
   `(show-paren-match ((t (:foreground ,blue-2 :background ,blue-2bg))))
   `(show-paren-mismatch ((t (:background ,red-1 :foreground ,red-1bg))))

   ;; ido
   `(ido-only-match ((t (:foreground ,green-1 :background ,green-1bg))))
   `(ido-subdir ((t (:foreground ,purple-1 :background ,purple-1bg))))

   ;; whitespace-mode
   `(whitespace-empty ((t (:foreground ,yellow-1bg :background ,yellow-1))))
   `(whitespace-hspace ((t (:foreground ,gray-2))))
   `(whitespace-indentation ((t (:foreground ,gray-2))))
   `(whitespace-line ((t (:background ,gray-2))))
   `(whitespace-newline ((t (:foreground ,gray-2))))
   `(whitespace-space ((t (:foreground ,gray-2))))
   `(whitespace-space-after-tab ((t (:foreground ,gray-2))))
   `(whitespace-tab ((t (:foreground ,gray-2))))
   `(whitespace-trailing ((t (:foreground ,red-1bg :background ,red-1))))

   ;; flyspell-mode
   `(flyspell-incorrect ((t (:underline ,red-1))))
   `(flyspell-duplicate ((t (:underline ,red-1))))

   ;; magit
   `(magit-diff-add ((t (:foreground ,green-1 :background ,green-1bg))))
   `(magit-diff-del ((t (:foreground ,red-1 :background ,red-1bg))))
   `(magit-item-highlight ((t (:background ,gray-1bg))))

   ;; highlight-indentation-mode
   `(highlight-indentation-face ((t (:background ,gray-1bg))))
   `(highlight-indentation-current-column-face ((t (:background ,gray-5))))

   ;; ECB
   `(ecb-default-general-face ((t (:foreground ,foreground :background ,gray-1bg))))
   `(ecb-default-highlight-face ((t (:foreground ,purple-1 :background ,purple-1bg))))
   `(ecb-method-face ((t (:foreground ,red-1 :background ,red-1bg))))
   `(ecb-tag-header-face ((t (:background ,blue-2bg))))

   ;; org-mode
   `(org-date ((t (:foreground ,purple-1 :background ,purple-1bg))))
   `(org-done ((t (:foreground ,green-1 :background ,green-1bg))))
   `(org-hide ((t (:foreground ,gray-2 :background ,gray-1bg))))
   `(org-link ((t (:foreground ,blue-1 :background ,blue-1bg))))
   `(org-todo ((t (:foreground ,red-1 :background ,red-1bg))))
   )

  (custom-theme-set-variables
   'twilight-bright

   ;; ;; Fill Column Indicator mode
   `(fci-rule-color ,gray-2)
   `(fci-rule-character-color ,gray-2)

   `(ansi-color-names-vector
     ;; black, red, green, yellow, blue, magenta, cyan, white
     [,background ,red-1 ,green-1 ,yellow-1 ,blue-1 ,purple-1 ,blue-1 ,foreground])
   `(ansi-term-color-vector
     ;; black, red, green, yellow, blue, magenta, cyan, white
     [unspecified ,background ,red-1 ,green-1 ,yellow-1 ,blue-1 ,purple-1 ,blue-1 ,foreground])
   )
  )

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'twilight-bright)

;;; twilight-bright-theme.el ends here
