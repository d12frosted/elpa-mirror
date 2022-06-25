;;; tok-theme.el --- Simple, brutalistic and minimal Emacs theme  -*- lexical-binding: t; -*-

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20220624.1832
;; Package-Commit: 3df2d34c8fcefa2d43938599c66f93dd81d8e3f7
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

;; Tok is a simple, brutalistic and minimal Emacs theme.

;;; Code:

(deftheme tok
  "Minimal Emacs theme with dark and yellow color scheme")

(let ((class '((class color) (min-colors 89))))
  (custom-theme-set-faces
   'tok
   ;; Basic
   `(default ((,class (:foreground "black" :background "white"))))
   `(cursor ((,class (:background "red"))))
   `(region ((,class (:background "khaki"))))
   `(fringe ((,class (:inherit default))))
   ;; Outline mode
   `(outline-1 ((,class (:weight bold :height 1.3))))
   `(outline-2 ((,class (:weight bold :height 1.15))))
   `(outline-3 ((,class (:weight bold :height 1.1))))
   `(outline-4 ((,class (:weight bold))))
   `(outline-5 ((,class (:weight bold))))
   `(outline-6 ((,class (:weight bold))))
   `(outline-7 ((,class (:weight bold))))
   `(outline-8 ((,class (:weight bold))))
   ;; Mode-line
   `(mode-line ((,class (:box "black"))))
   (when (>= emacs-major-version 29)
     `(mode-line-active ((,class (:inherit mode-line)))))
   `(mode-line-inactive ((,class (:background "gray95" :box "gray50"))))
   `(mode-line-buffer-id ((,class (:weight bold))))
   ;; Font lock
   `(font-lock-keyword-face ((t nil)))
   `(font-lock-function-name-face ((t nil)))
   `(font-lock-warning-face ((t nil)))
   `(font-lock-builtin-face ((t nil)))
   `(font-lock-variable-name-face ((t nil)))
   `(font-lock-constant-face ((t nil)))
   `(font-lock-type-face ((t nil)))
   `(font-lock-preprocessor-face ((t nil)))
   `(font-lock-comment-face ((,class (:foreground "grey50" :slant italic))))
   `(font-lock-string-face ((t nil)))
   `(font-lock-doc-face ((,class (:inherit font-lock-comment-face))))
   `(font-lock-regexp-grouping-backslash ((t nil)))
   `(font-lock-regexp-grouping-construct ((t nil)))
   ;; show-paren
   `(show-paren-match ((,class (:background "turquoise"))))
   `(show-paren-match-expression ((,class (:background "turquoise"))))
   `(show-paren-mismatch ((,class (:foreground "white" :background "purple"))))
   ;; Line numbers
   `(line-number ((,class (:inherit (shadow default)))))
   `(line-number-current-line ((,class (:inherit line-number))))
   ;; hl-line
   `(hl-line ((,class (:background "gray95"))))
   ;; Shell script
   `(sh-heredoc ((t nil)))
   ;; org-mode
   `(org-block ((t nil)))
   `(org-block-begin-line ((,class (:inherit shadow))))
   `(org-block-end-line ((,class (:inherit org-block-begin-line))))
   `(org-code ((t nil)))
   `(org-document-title ((t nil)))
   `(org-drawer ((t nil)))
   `(org-link ((,class (:inherit link))))
   `(org-date ((,class (:inherit (fixed-pitch link)))))
   `(org-meta-line ((,class (:inherit org-document-info-keyword))))
   `(org-headline-todo ((,class (:weight normal))))
   `(org-headline-done ((,class (:foreground "grey75" :weight normal :strike-through t :slant italic))))
   `(org-level-1 ((,class (:inherit outline-1))))
   `(org-level-2 ((,class (:inherit outline-2))))
   `(org-level-3 ((,class (:inherit outline-3))))
   `(org-level-4 ((,class (:inherit outline-4))))
   `(org-level-5 ((,class (:inherit outline-5))))
   `(org-level-6 ((,class (:inherit outline-6))))
   `(org-level-7 ((,class (:inherit outline-7))))
   `(org-level-8 ((,class (:inherit outline-8))))
   `(org-special-keyword ((,class (:inherit shadow))))
   ;; Dired
   `(dired-directory ((,class (:foreground "blue"))))
   `(dired-symlink ((,class (:foreground "magenta"))))
   ;; ERC
   `(erc-timestamp-face ((,class (:weight unspecified :foreground unspecified))))
   ;; Terraform
   `(terraform--resource-name-face ((t nil)))
   `(terraform--resource-type-face ((t nil)))
   ;; Markdown
   `(markdown-header-face-1 ((,class (:inherit outline-1))))
   `(markdown-header-face-2 ((,class (:inherit outline-2))))
   `(markdown-header-face-3 ((,class (:inherit outline-3))))
   `(markdown-header-face-4 ((,class (:inherit outline-4))))
   `(markdown-header-face-5 ((,class (:inherit outline-5))))
   `(markdown-header-face-6 ((,class (:inherit outline-6))))))

(provide-theme 'tok)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; tok-theme.el ends here
