;;; tok-theme.el --- Minimal and calm theme with saffron color scheme -*- lexical-binding: t; -*-

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20230108.1817
;; Package-Commit: 63b862f6029536791a0e0f9ecb5688acef7801fe
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

;; Tok is a minimal and calm theme with saffron color scheme.

;;; Code:

(deftheme tok
  "Minimal and calm theme with saffron color scheme")

(let ((class '((class color) (min-colors 89)))
      (dark-saffron "#6e5406") (saffron "#f4c430") (light-saffron "#f8d979")
      (bg "#fffefd") (fg "#110d01") (comment "#7f7f7f"))
  (custom-theme-set-faces
   'tok
   ;; In case you're using this theme in terminal, let the terminal
   ;; emulator define these.
   (when (display-graphic-p)
     `(cursor ((,class (:background "red")))))
   (when (display-graphic-p) ; Have to call `when' here due to reasons.
     `(default ((,class (:foreground ,fg :background ,bg)))))
   
   ;; Basic faces
   `(highlight ((,class (:background ,light-saffron))))
   `(region ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                      :foreground ,fg :background ,saffron))))
   `(secondary-selection ((,class (:inherit region))))
   `(trailing-whitespace ((,class (:inherit error))))
   `(error ((,class (:weight bold :foreground "firebrick1"))))
   `(warning ((,class (:weight bold :foreground "DarkOrange"))))
   `(success ((,class (:weight bold :foreground "Green1"))))
   `(minibuffer-prompt ((,class (:foreground "medium blue"))))
   `(fringe ((,class (nil))))
   `(button ((,class (:underline t))))

   ;; Line-numbes
   `(line-number-current-line ((,class (:inherit highlight))))

   ;; Mode-line
   `(mode-line ((,class (:foreground ,fg :background ,saffron :box (:line-width -1 :style released-button)))))
   (when (>= emacs-major-version 29)
     `(mode-line-active ((,class (:inherit mode-line)))))
   `(mode-line-inactive ((,class (:weight light :foreground ,fg :background ,light-saffron))))
   `(mode-line-highlight ((,class (nil))))
   `(mode-line-emphasis ((,class (:weight bold))))
   `(mode-line-buffer-id ((,class (:weight bold))))

   ;; Header
   `(header-line ((,class (:inherit mode-line-inactive :box nil))))

   ;; Font-lock
   `(font-lock-comment-face ((,class (:foreground ,comment))))
   `(font-lock-comment-delimiter-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-string-face ((,class (:foreground ,dark-saffron))))
   `(font-lock-doc-face ((, class(:inherit font-lock-comment-face))))
   `(font-lock-doc-markup-face ((,class (nil))))
   `(font-lock-keyword-face ((,class (nil))))
   `(font-lock-builtin-face ((,class (nil))))
   `(font-lock-function-name-face ((,class (nil))))
   `(font-lock-variable-name-face ((,class (nil))))
   `(font-lock-type-face ((,class (nil))))
   `(font-lock-constant-face ((,class (nil))))
   `(font-lock-warning-face ((,class (nil))))
   `(font-lock-negation-char-face ((,class (nil))))
   `(font-lock-preprocessor-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-regexp-grouping-backslash ((,class (nil))))
   `(font-lock-regexp-grouping-construct ((,class (nil))))

   ;; ERC
   `(erc-timestamp-face ((,class (:foreground nil))))

   ;; sh
   `(sh-heredoc ((,class (nil))))
   `(sh-quoted-exec ((,class (nil))))

   ;; Outline
   `(outline-1 ((,class (:foreground ,dark-saffron))))
   `(outline-2 ((,class (:inherit outline-1))))
   `(outline-3 ((,class (:inherit outline-1))))
   `(outline-4 ((,class (:inherit outline-1))))
   `(outline-5 ((,class (:inherit outline-1))))
   `(outline-6 ((,class (:inherit outline-1))))
   `(outline-7 ((,class (:inherit outline-1))))
   `(outline-8 ((,class (:inherit outline-1))))

   ;; Terraform
   `(terraform--resource-name-face ((,class (nil))))
   `(terraform--resource-type-face ((,class (nil))))

   ;; Magit
   `(magit-diff-added ((,class (:background "#ddffdd"))))
   `(magit-diff-removed ((,class (:background "#ffdddd"))))
   `(magit-diff-added-highlight ((,class (:background "#cceecc"))))
   `(magit-diff-removed-highlight ((,class (:background "#eecccc"))))

   ;; Markdown
   `(markdown-header-face ((,class (:inherit outline-1))))
   `(markdown-header-delimiter-face ((,class (nil))))
   `(markdown-metadata-key-face ((,class (:inherit font-lock-comment-face))))
   `(markdown-metadata-value-face ((,class (:inherit font-lock-comment-face))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'tok)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; tok-theme.el ends here
