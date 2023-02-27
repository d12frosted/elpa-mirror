;;; tok-theme.el --- Minimal, calm and dark theme for Emacs -*- lexical-binding: t; -*-

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20230227.1357
;; Package-Commit: f0d7193595c9b19e3b96d19c3b2f39456872bf26
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

;; Tok is a minimal, calm and dark theme for Emacs.

;;; Code:

(deftheme tok
  "Minimal, calm and dark theme for Emacs")

(let ((class '((class color) (min-colors 89)))
      (fg     "#dedede")
      (bg     "#121212")
      (grey-1 "#212121")
      (grey-2 "#484848")
      (comment "#757575"))
  (custom-theme-set-faces
   'tok
   ;; In case you're using this theme in terminal, let the terminal
   ;; emulator define these.
   (when (display-graphic-p)
     `(cursor ((,class (:background "red")))))
   (when (display-graphic-p) ; Have to call `when' here due to reasons.
     `(default ((,class (:foreground ,fg :background ,bg)))))

   ;; Basic faces
   `(highlight ((,class (:background ,grey-1))))
   `(region ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                      :background ,grey-2))))
   `(secondary-selection ((,class (:inherit region))))
   `(trailing-whitespace ((,class (:background "hotpink"))))
   `(error ((,class (:weight bold :foreground "red"))))
   `(warning ((,class (:weight bold :foreground "orange"))))
   `(success ((,class (:weight bold :foreground "green"))))
   `(fringe ((t (nil))))
   `(button ((,class (:underline t))))

   ;; Line-numbes
   `(line-number ((,class (:foreground ,grey-2))))
   `(line-number-current-line ((,class (:inherit highlight))))

   ;; Mode-line
   `(mode-line ((,class (:foreground ,fg :background ,grey-1 :box (:line-width -1 :style released-button)))))
   (when (>= emacs-major-version 29)
     `(mode-line-active ((,class (:inherit mode-line)))))
   `(mode-line-inactive ((,class (:weight light :foreground ,grey-2 :background "black"))))
   `(mode-line-highlight ((t (nil))))
   `(mode-line-emphasis ((,class (:weight bold))))
   `(mode-line-buffer-id ((,class (:weight bold))))

   ;; Font-lock
   `(font-lock-comment-face ((,class (:foreground ,comment))))
   `(font-lock-comment-delimiter-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-string-face ((t (nil))))
   `(font-lock-doc-face ((, class(:inherit font-lock-comment-face))))
   `(font-lock-doc-markup-face ((t (nil))))
   `(font-lock-keyword-face ((t (nil))))
   `(font-lock-builtin-face ((t (nil))))
   `(font-lock-function-name-face ((t (nil))))
   `(font-lock-variable-name-face ((t (nil))))
   `(font-lock-type-face ((t (nil))))
   `(font-lock-constant-face ((t (nil))))
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

   ;; Outline
   `(outline-1 ((,class (:inherit font-lock-comment-face))))
   `(outline-2 ((,class (:inherit outline-1))))
   `(outline-3 ((,class (:inherit outline-1))))
   `(outline-4 ((,class (:inherit outline-1))))
   `(outline-5 ((,class (:inherit outline-1))))
   `(outline-6 ((,class (:inherit outline-1))))
   `(outline-7 ((,class (:inherit outline-1))))
   `(outline-8 ((,class (:inherit outline-1))))

   ;; Terraform
   `(terraform--resource-name-face ((t (nil))))
   `(terraform--resource-type-face ((t (nil))))

   ;; Markdown
   `(markdown-header-face ((,class (:inherit outline-1))))
   `(markdown-header-delimiter-face ((t (nil))))
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
