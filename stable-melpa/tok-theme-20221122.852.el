;;; tok-theme.el --- Comfy dark monochromatic theme -*- lexical-binding: t; -*-

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20221122.852
;; Package-Commit: cb68e94c1493729ef4f083fb9e3f54626b5a9913
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))

;; This is free and unencumbered software released into the public domain.
;; 
;; Anyone is free to copy, modify, publish, use, compile, sell, or
;; distribute this software, either in source code form or as a compiled
;; binary, for any purpose, commercial or non-commercial, and by any
;; means.
;; 
;; In jurisdictions that recognize copyright laws, the author or authors
;; of this software dedicate any and all copyright interest in the
;; software to the public domain. We make this dedication for the benefit
;; of the public at large and to the detriment of our heirs and
;; successors. We intend this dedication to be an overt act of
;; relinquishment in perpetuity of all present and future rights to this
;; software under copyright law.
;; 
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
;; OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
;; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;; OTHER DEALINGS IN THE SOFTWARE.
;; 
;; For more information, please refer to <https://unlicense.org>

;; This file is not part of Emacs.

;;; Commentary:

;; Tok is a comfy dark monochromatic theme.

;;; Code:

(deftheme tok
  "Comfy dark monochromatic theme")

(let ((class '((class color) (min-colors 89))))
  (custom-theme-set-faces
   'tok
   ;; Basic faces
   `(default ((,class (:foreground "white" :background "black"))))
   `(highlight ((,class (:background "grey15"))))
   `(region ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                      :background "gray30"))))
   `(secondary-selection ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                                   :background "SkyBlue4"))))
   `(trailing-whitespace ((,class (:inherit error))))
   `(cursor ((,class (:background "red"))))
   `(error ((,class (:weight bold :foreground "firebrick1"))))
   `(warning ((,class (:weight bold :foreground "DarkOrange"))))
   `(success ((,class (:weight bold :foreground "Green1"))))
   `(minibuffer-prompt ((,class (:foreground "grey80"))))

   ;; Line-numbes
   `(line-number ((,class (:foreground "gray50"))))
   `(line-number-current-line ((,class (:inherit highlight))))
   `(line-number-major-tick ((,class (:weight bold :background "grey75"))))
   `(line-number-minor-tick ((,class (:weight bold :background "grey55"))))

   ;; Mode-line
   `(mode-line ((,class (:foreground "white" :background "grey10" :box (:line-width -1 :style released-button)))))
   (when (>= emacs-major-version 29)
     `(mode-line-active ((,class (:inherit mode-line)))))
   `(mode-line-inactive ((,class (:weight light :foreground "white" :background "grey20"))))
   `(mode-line-highlight ((t (nil))))
   `(mode-line-emphasis ((,class (:weight bold))))
   `(mode-line-buffer-id ((,class (:weight bold))))

   ;; Font-lock
   `(font-lock-comment-face ((,class (:foreground "grey50"))))
   `(font-lock-comment-delimiter-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-string-face ((t (nil))))
   `(font-lock-doc-markup-face ((t (nil))))
   `(font-lock-keyword-face ((t (nil))))
   `(font-lock-builtin-face ((t (nil))))
   `(font-lock-function-name-face ((t (nil))))
   `(font-lock-variable-name-face ((t (nil))))
   `(font-lock-type-face ((t (nil))))
   `(font-lock-constant-face ((t (nil))))
   `(font-lock-warning-face ((t (nil))))
   `(font-lock-negation-char-face ((t (nil))))
   `(font-lock-preprocessor-face ((t (nil))))
   `(font-lock-regexp-grouping-backslash ((t (nil))))
   `(font-lock-regexp-grouping-construct ((t (nil))))

   ;; isearch
   `(isearch ((,class (:foreground "brown4" :background "palevioletred2"))))
   `(isearch-fail ((,class (:background "red4"))))
   `(lazy-highlight ((,class (:background "paleturquoise4"))))
   `(isearch-group-1 ((,class (:foreground "brown4" :background "palevioletred1"))))
   `(isearch-group-2 ((,class (:foreground "brown4" :background "palevioletred3"))))

   ;; Flymake
   `(flymake-error ((,class (:underline (:style wave :color "red")))))
   `(flymake-warning ((,class (:underline (:style wave :color "DarkOrange")))))
   `(flymake-note ((t (nil))))

   ;; Disabled faces
   `(fringe ((t (nil))))
   `(sh-heredoc ((t (nil))))
   `(sh-quoted-exec ((t (nil))))
   `(terraform--resource-name-face ((t (nil))))
   `(terraform--resource-type-face ((t (nil))))
   `(outline-1 ((t (nil))))
   `(outline-2 ((t (nil))))
   `(outline-3 ((t (nil))))
   `(outline-4 ((t (nil))))
   `(outline-5 ((t (nil))))
   `(outline-6 ((t (nil))))
   `(outline-7 ((t (nil))))
   `(outline-8 ((t (nil))))
   `(markdown-header-face ((t (nil))))
   `(markdown-header-delimiter-face ((t (nil))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'tok)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; tok-theme.el ends here
