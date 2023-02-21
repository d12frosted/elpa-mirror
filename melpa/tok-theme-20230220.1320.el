;;; tok-theme.el --- Dark but vibrant theme for Emacs -*- lexical-binding: t; -*-

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20230220.1320
;; Package-Commit: 4dd1efcab11576c0989c52f67c89759a43e07f0b
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

;; Tok is a dark but vibrant theme for Emacs.

;;; Code:

(deftheme tok
  "Dark but vibrant theme for Emacs")

(let ((class '((class color) (min-colors 89)))
      (fg "#eeeeee")
      (bg "#121212")
      (grey "#212121")
      (light-grey "#484848")
      (green "#9ccc65")
      (blue "#81d4fa")
      (purple "#ce93d8")
      (orange "#ffcc80")
      (yellow "#fff59d")
      (teal "#80cbc4")
      (cyan "#80deea"))
  (custom-theme-set-faces
   'tok
   ;; In case you're using this theme in terminal, let the terminal
   ;; emulator define these.
   (when (display-graphic-p)
     `(cursor ((,class (:background "red")))))
   (when (display-graphic-p) ; Have to call `when' here due to reasons.
     `(default ((,class (:foreground ,fg :background ,bg)))))

   ;; Basic faces
   `(highlight ((,class (:background ,grey))))
   `(region ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                      :background ,light-grey))))
   `(secondary-selection ((,class (:inherit region))))
   `(trailing-whitespace ((,class (:background "hotpink"))))
   `(error ((,class (:weight bold :foreground "red"))))
   `(warning ((,class (:weight bold :foreground "orange"))))
   `(success ((,class (:weight bold :foreground "green"))))
   `(fringe ((t (nil))))
   `(button ((,class (:underline t))))

   ;; Line-numbes
   `(line-number ((,class (:foreground ,light-grey))))
   `(line-number-current-line ((,class (:inherit highlight))))

   ;; Mode-line
   `(mode-line ((,class (:foreground ,fg :background ,grey :box (:line-width -1 :style released-button)))))
   (when (>= emacs-major-version 29)
     `(mode-line-active ((,class (:inherit mode-line)))))
   `(mode-line-inactive ((,class (:weight light :foreground ,light-grey :background "black"))))
   `(mode-line-highlight ((t (nil))))
   `(mode-line-emphasis ((,class (:weight bold))))
   `(mode-line-buffer-id ((,class (:weight bold))))

   ;; Font-lock
   `(font-lock-comment-face ((,class (:foreground ,green))))
   `(font-lock-comment-delimiter-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-string-face ((,class (:foreground ,orange))))
   `(font-lock-doc-face ((, class(:inherit font-lock-comment-face))))
   `(font-lock-doc-markup-face ((t (nil))))
   `(font-lock-keyword-face ((,class (:foreground ,blue))))
   `(font-lock-builtin-face ((,class (:inherit font-lock-keyword-face))))
   `(font-lock-function-name-face ((,class (:foreground ,cyan))))
   `(font-lock-variable-name-face ((t (nil))))
   `(font-lock-type-face ((,class (:foreground ,blue))))
   `(font-lock-constant-face ((,class (:foreground ,teal))))
   `(font-lock-warning-face ((,class (:inherit error))))
   `(font-lock-negation-char-face ((t (nil))))
   `(font-lock-preprocessor-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-regexp-grouping-backslash ((t (nil))))
   `(font-lock-regexp-grouping-construct ((t (nil))))

   ;; Dired
   `(dired-directory ((,class (:foreground "cyan"))))
   `(dired-symlink ((,class (:foreground "magenta"))))
   `(dired-broken-symlink ((,class (:foreground "red"))))

   ;; ERC
   `(erc-timestamp-face ((,class (:foreground nil))))

   ;; sh
   `(sh-heredoc ((t (nil))))
   `(sh-quoted-exec ((t (nil))))

   ;; Terraform
   `(terraform--resource-name-face ((,class (:inherit font-lock-function-name-face))))
   `(terraform--resource-type-face ((,class (:inherit font-lock-type-face))))

   ;; Markdown
   `(markdown-metadata-key-face ((,class (:inherit font-lock-comment-face))))
   `(markdown-metadata-value-face ((,class (:inherit font-lock-comment-face))))
   `(markdown-blockquote-face ((t (nil))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'tok)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; tok-theme.el ends here
