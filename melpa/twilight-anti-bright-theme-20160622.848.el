;;; twilight-anti-bright-theme.el --- A soothing Emacs 24 light-on-dark theme
;;
;; Copyright (c) 2014 Jim Myhrberg.
;;
;; Author: Jim Myhrberg <contact@jimeh.me>
;; Version: 0.3.1
;; Package-Version: 20160622.848
;; Package-Commit: 523b95fcdbf4a6a6483af314ad05354a3d80f23f
;; Keywords: themes
;; URL: https://github.com/jimeh/twilight-anti-bright-theme.el
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
;; This is a light-on-dark theme inspired by the dark-on-light Twilight Bright
;; TextMate theme by Florian Pichler.
;;
;;; Commentary:
;;
;; I particularly like the colors used in Twilight Bright, but I prefer
;; light-on-dark themes, so I set out to create such a theme inspired by
;; Twilight Bright. This is the result :)
;;
;;; Change Log:
;;
;; 2016-06-22 (0.3.1):
;;    - Add support for highlight-indent-guide-mode.
;;
;; 2014-08-10 (0.3.0):
;;    - Tweaked fringe foreground color.
;;    - Made linum foreground color a bit brighter and more readable.
;;    - Added face definitions for yascroll.
;;    - Added face definitions for git-gutter.
;;    - Changed hl-line color from a dark to a light color.
;;
;; 2012-07-13 (0.2.0):
;;    Make default and comment foreground colors a bit brighter.
;;
;; 2012-07-03 (0.1.1):
;;    Make ECB foreground text colors a bit brighter.
;;
;; 2012-06-30 (0.1.0):
;;    Initial release.
;;
;;; Code:

(deftheme twilight-anti-bright
  "A soothing light-on-dark theme.")

(let ((background "#14191f")
      (foreground "#dcdddd")
      (selection "#313c4d")
      (hl-line "#1b2129")
      (cursor "#b4b4b4")
      (comment "#716d73")

      (gray-1 "#878289")   (gray-1bg "#181d23")
      (gray-2 "#2a3441")
      (gray-3 "#b3adb4")   (gray-3bg "#0e1116")
      (gray-4 "#1f2730")
      (gray-5 "#242d38")
      (gray-6 "#192028")
      (gray-7 "#39424d")
      (red-1 "#d15120")    (red-1bg "#2a1f1f")
      (red-2 "#b23f1e")    (red-2bg "#251c1e")
      (red-3 "#c6350b")
      (brown-1 "#9f621d")  (brown-1bg "#2a1f1f")
      (orange-1 "#d97a35") (orange-1bg "#272122")
      (yellow-1 "#deae3e") (yellow-1bg "#2a2921")
      (green-1 "#81af34")  (green-1bg "#1a2321")
      (green-2 "#4e9f75")  (green-2bg "#1a2321")
      (blue-1 "#7e9fc9")   (blue-1bg "#1e252f")
      (blue-2 "#417598")   (blue-2bg "#1b333e")
      (blue-3 "#00959e")   (blue-3bg "#132228")
      (blue-4 "#365e7a")   (blue-4bg "#172028")
      (purple-1 "#a878b5") (purple-1bg "#25222f")
      )

  (custom-theme-set-faces
   'twilight-anti-bright

   ;; Basics
   `(default ((t (:background ,background :foreground ,foreground))))
   `(cursor ((t (:background ,cursor))))
   `(region ((t (:background ,selection))))
   `(highlight ((t (:foreground ,blue-3 :background ,blue-3bg))))
   `(hl-line ((t (:background ,hl-line))))
   `(minibuffer-prompt ((t (:foreground ,orange-1 :background ,orange-1bg))))
   `(escape-glyph ((t (:foreground ,purple-1 :background , purple-1bg))))
   `(error ((t (:foreground ,red-3))))

   ;; Font-lock stuff
   `(font-lock-builtin-face ((t (:foreground ,yellow-1 :background ,yellow-1bg))))
   `(font-lock-constant-face ((t (:foreground ,purple-1 :background ,purple-1bg))))
   `(font-lock-comment-face ((t (:foreground ,comment :background ,gray-1bg :italic t))))
   `(font-lock-doc-face ((t (:foreground ,gray-1 :background ,gray-1bg))))
   `(font-lock-doc-string-face ((t (:foreground ,gray-1 :background ,gray-1bg))))
   `(font-lock-function-name-face ((t (:foreground ,red-1 :background ,red-1bg))))
   `(font-lock-keyword-face ((t (:foreground ,orange-1 :background ,orange-1bg))))
   `(font-lock-negation-char-face ((t (:foreground ,yellow-1 :background ,yellow-1bg))))
   `(font-lock-preprocessor-face ((t (:foreground ,orange-1 :background ,orange-1bg))))
   `(font-lock-string-face ((t (:foreground ,green-1 :background ,green-1bg))))
   `(font-lock-type-face ((t (:foreground ,red-2 :background ,red-2bg :bold nil))))
   `(font-lock-variable-name-face ((t (:foreground ,blue-1 :background ,blue-1bg))))
   `(font-lock-warning-face ((t (:foreground ,red-2 :background ,red-2bg))))

   ;; UI related
   `(link ((t (:foreground ,blue-1 :background ,blue-1bg))))
   `(fringe ((t (:foreground ,comment :background ,gray-1bg))))
   `(mode-line ((t (:foreground ,blue-1 :background ,blue-2bg))))
   `(mode-line-inactive ((t (:foreground ,blue-4 :background ,gray-4))))
   `(vertical-border ((t (:background ,background :foreground ,gray-5))))

   ;; Linum
   `(linum ((t (:foreground ,gray-7 :background ,gray-1bg))))

   ;; show-paren-mode
   `(show-paren-match ((t (:foreground ,orange-1 :background ,orange-1bg))))
   `(show-paren-mismatch ((t (:foreground ,red-2bg :background ,red-2))))

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
   `(flyspell-incorrect ((t (:underline ,red-2))))
   `(flyspell-duplicate ((t (:underline ,red-2))))

   ;; magit
   `(magit-diff-add ((t (:foreground ,green-1))))
   `(magit-diff-del ((t (:foreground ,red-2))))
   `(magit-item-highlight ((t (:background ,gray-1bg))))

   ;; highlight-indentation-mode
   `(highlight-indentation-face ((t (:background ,gray-1bg))))
   `(highlight-indentation-current-column-face ((t (:background ,gray-4))))

   ;; highlight-indent-guide-model
   `(highlight-indent-guides-odd-face ((t (:background ,gray-1bg))))
   `(highlight-indent-guides-even-face ((t (:background ,gray-6))))

   ;; yascroll
   `(yascroll:thumb-fringe ((t (:foreground ,gray-2 :background ,gray-2))))
   `(yascroll:thumb-text-area ((t (:background ,gray-2))))

   ;; git-gutter
   `(git-gutter:added ((t (:foreground ,green-1 :weight bold))))
   `(git-gutter:deleted ((t (:foreground ,red-1 :weight bold))))
   `(git-gutter:modified ((t (:foreground ,purple-1 :weight bold))))

   ;; ECB
   `(ecb-default-general-face ((t (:foreground ,gray-3 :background ,gray-1bg))))
   `(ecb-default-highlight-face ((t (:foreground ,red-1 :background ,red-1bg))))
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
   'twilight-anti-bright

   ;; ;; Fill Column Indicator mode
   `(fci-rule-color ,gray-6)
   `(fci-rule-character-color ,gray-6)

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

(provide-theme 'twilight-anti-bright)

;;; twilight-anti-bright-theme.el ends here
