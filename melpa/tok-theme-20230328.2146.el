;;; tok-theme.el --- Minimal light monochromatic theme for Emacs in the spirit of Zmacs and Smalltalk-80-*- lexical-binding: t; -*-

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20230328.2146
;; Package-Commit: c56aa7337bf71d4dac491aa2f9623365c078a604
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

;; Tok is a minimal light monochromatic theme for Emacs in the spirit of Zmacs and Smalltalk-80.

;;; Code:

(deftheme tok
  "Minimal light monochromatic theme for Emacs in the spirit of Zmacs and Smalltalk-80")

(let ((class '((class color) (min-colors 89))))
  (custom-theme-set-faces
   'tok
   ;; In case you're using this theme in terminal, let the terminal
   ;; emulator define these.
   (when (display-graphic-p)
     `(cursor ((,class (:background "black")))))
   (when (display-graphic-p) ; Have to call `when' here due to reasons.
     `(default ((,class (:foreground "black" :background "white")))))

   ;; Basic faces
   `(highlight ((,class (:background "grey95"))))
   `(region ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                      :background "grey90"))))
   `(secondary-selection ((,class (:inherit region))))
   `(trailing-whitespace ((,class (:background "hotpink"))))
   `(error ((,class (:weight bold :foreground "red"))))
   `(warning ((,class (:weight bold :foreground "orange"))))
   `(success ((,class (:weight bold :foreground "green"))))
   `(fringe ((t (nil))))
   `(button ((,class (:underline t))))
   `(vertical-border ((,class (:foreground "black"))))
   `(minibuffer-prompt ((t (nil))))

   ;; Line-numbes
   `(line-number ((,class (:foreground "grey75"))))
   `(line-number-current-line ((,class (:foreground "black" :background "grey95"))))

   ;; Mode-line
   `(mode-line ((,class (:foreground "black" :background "white" :box 1))))
   (when (>= emacs-major-version 29)
     `(mode-line-active ((,class (:inherit mode-line)))))
   `(mode-line-inactive ((,class (:weight light
                                          :foreground "grey20"
                                          :background "grey90"
                                          :box 1))))
   `(mode-line-highlight ((t (nil))))
   `(mode-line-emphasis ((,class (:weight bold))))
   `(mode-line-buffer-id ((,class (:weight bold))))

   ;; Font-lock
   `(font-lock-comment-face ((,class (:weight bold))))
   `(font-lock-comment-delimiter-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-string-face ((,class (:italic t :weight light))))
   `(font-lock-doc-face ((,class (:inherit font-lock-comment-face))))
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

   ;; Dired
   `(dired-directory ((,class (:weight bold))))
   `(dired-broken-symlink ((,class (:inherit error))))

   ;; ERC
   `(erc-timestamp-face ((t (nil))))

   ;; sh
   `(sh-heredoc ((t (nil))))
   `(sh-quoted-exec ((t (nil))))

   ;; Org
   `(org-block ((t (nil))))

   ;; Outline
   `(outline-1 ((,class (:weight bold))))
   `(outline-2 ((,class (:inherit outline-1))))
   `(outline-3 ((,class (:inherit outline-1))))
   `(outline-4 ((,class (:inherit outline-1))))
   `(outline-5 ((,class (:inherit outline-1))))
   `(outline-6 ((,class (:inherit outline-1))))
   `(outline-7 ((,class (:inherit outline-1))))
   `(outline-8 ((,class (:inherit outline-1))))

   ;; Show paren
   `(show-paren-match ((,class (:background "grey80"))))
   `(show-paren-match-expression ((,class (:inherit show-paren-match))))
   `(show-paren-mismatch ((,class (:inherit error))))

   ;; Terraform
   `(terraform--resource-name-face ((t (nil))))
   `(terraform--resource-type-face ((t (nil))))

   ;; Markdown
   `(markdown-header-face ((,class (:inherit outline-1))))
   `(markdown-header-delimiter-face ((t (nil))))
   `(markdown-metadata-key-face ((,class (:inherit font-lock-comment-face))))
   `(markdown-metadata-value-face ((,class (:inherit font-lock-comment-face))))
   `(markdown-blockquote-face ((t (nil))))
   `(markdown-pre-face ((t (nil))))

   ;; Magit
   `(magit-diff-file-heading ((t (nil))))
   `(magit-section-heading ((,class (:weight bold))))
   `(magit-diff-added ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                                :background "#ddffdd"))))
   `(magit-diff-added-highlight ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                                          :background "#cceecc"))))
   `(magit-diff-removed ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                                  :background "#ffdddd"))))
   `(magit-diff-removed-highlight ((,class (,@(and (>= emacs-major-version 27) '(:extend t))
                                          :background "#eecccc"))))

   ;; Completions
   `(completions-common-part ((,class (:weight bold))))
   `(completions-first-difference ((t (nil))))

   ;; Corfu
   `(corfu-default ((,class (:background "white"))))
   `(corfu-bar ((,class (:background "black"))))
   `(corfu-border ((,class (:background "black"))))
   `(corfu-current ((,class (:inherit highlight))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'tok)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; tok-theme.el ends here
