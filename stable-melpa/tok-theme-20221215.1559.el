;;; tok-theme.el --- Comfy minimal theme -*- lexical-binding: t; -*-

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20221215.1559
;; Package-Commit: c8b781a34b1e6e342804f40c5141ebdb04e8390b
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

;; Tok is a comfy minimal theme.

;;; Code:

(deftheme tok
  "Comfy minimal theme")

(let ((class '((class color) (min-colors 89)))
      (sun "#ffd22a") (light-sun "#ffe995")
      (bg "#fffae6") (fg "#444444"))
  (custom-theme-set-faces
   'tok
   ;; Basic faces
   `(default ((,class (:foreground ,fg :background ,bg))))
   `(highlight ((,class (:background ,light-sun))))
   `(region ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                      :background ,sun))))
   `(secondary-selection ((t (:inherit region))))
   `(trailing-whitespace ((,class (:inherit error))))
   `(cursor ((,class (:background "red"))))
   `(error ((,class (:weight bold :foreground "firebrick1"))))
   `(warning ((,class (:weight bold :foreground "DarkOrange"))))
   `(success ((,class (:weight bold :foreground "Green1"))))
   `(minibuffer-prompt ((,class (:foreground "medium blue"))))
   `(fringe ((t (nil))))
   `(button ((t (:underline t))))

   ;; Line-numbes
   `(line-number-current-line ((,class (:inherit highlight))))

   ;; Mode-line
   `(mode-line ((,class (:foreground ,fg :background ,sun :box (:line-width -1 :style released-button)))))
   (when (>= emacs-major-version 29)
     `(mode-line-active ((,class (:inherit mode-line)))))
   `(mode-line-inactive ((,class (:weight light :foreground ,fg :background ,light-sun))))
   `(mode-line-highlight ((t (nil))))
   `(mode-line-emphasis ((,class (:weight bold))))
   `(mode-line-buffer-id ((,class (:weight bold))))

   ;; Font-lock
   `(font-lock-comment-face ((,class (:foreground "gray65" :slant italic))))
   `(font-lock-comment-delimiter-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-string-face ((,class (:slant italic))))
   `(font-lock-doc-face ((, class(:inherit font-lock-comment-face))))
   `(font-lock-doc-markup-face ((t (nil))))
   `(font-lock-keyword-face ((t (nil))))
   `(font-lock-builtin-face ((t (nil))))
   `(font-lock-function-name-face ((t (nil))))
   `(font-lock-variable-name-face ((t (nil))))
   `(font-lock-type-face ((t (nil))))
   `(font-lock-constant-face ((t (nil))))
   `(font-lock-warning-face ((t (nil))))
   `(font-lock-negation-char-face ((t (nil))))
   `(font-lock-preprocessor-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-regexp-grouping-backslash ((t (nil))))
   `(font-lock-regexp-grouping-construct ((t (nil))))

   ;; Flymake
   `(flymake-error ((,class (:underline (:style wave :color "red")))))
   `(flymake-warning ((,class (:underline (:style wave :color "DarkOrange")))))
   `(flymake-note ((t (nil))))

   ;; sh
   `(sh-heredoc ((t (nil))))
   `(sh-quoted-exec ((t (nil))))

   ;; Outline
   `(outline-1 ((t (nil))))
   `(outline-2 ((t (nil))))
   `(outline-3 ((t (nil))))
   `(outline-4 ((t (nil))))
   `(outline-5 ((t (nil))))
   `(outline-6 ((t (nil))))
   `(outline-7 ((t (nil))))
   `(outline-8 ((t (nil))))

   ;; Terraform
   `(terraform--resource-name-face ((t (nil))))
   `(terraform--resource-type-face ((t (nil))))

   ;; Markdown
   `(markdown-header-face ((t (nil))))
   `(markdown-header-delimiter-face ((t (nil))))
   `(markdown-metadata-key-face ((t (:inherit font-lock-comment-face))))
   `(markdown-metadata-value-face ((t (:inherit font-lock-comment-face))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'tok)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; tok-theme.el ends here
