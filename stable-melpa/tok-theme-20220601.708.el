;;; tok-theme.el --- Minimal theme with dark and yellow color scheme  -*- lexical-binding: t; -*-

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20220601.708
;; Package-Commit: 3e7e946f0e474fa2d2a5bbdddf7f168e6ed759ba
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

;; Tok is a simple and minimal Emacs theme with dark and yellow color scheme.

;;; Code:

(deftheme tok
  "Minimal Emacs theme with dark and yellow color scheme")

(let* ((class '((class color) (min-colors 89)))
       ;; Color palette
       (sun-0 "#cc9900") (sun-1 "#ffcc33") (sun-2 "#fcd765")
       (sun-3 "#ffe699") (sun-4 "#fff3cc") (sun-5 "#fffbf5")
       (earth-0 "#8b572a") (earth-1 "#bf8f00")
       (grey-0 "#151515") (grey-1 "#252525") (grey-2 "#353535")
       (fg "#ffffff") (bg "#000000")
       (error "Red1") (warning "DarkOrange2") (success "ForestGreen"))
  (custom-theme-set-faces
   'tok
   ;; Basic faces
   `(default ((,class (:foreground ,fg :background ,bg))))
   `(fringe ((,class (:inherit default))))
   `(cursor ((,class (:background ,sun-0))))
   `(region ((,class (:background ,grey-2))))
   `(show-paren-match ((,class (:foreground ,bg :background ,sun-3))))
   `(hl-line ((,class (:background ,grey-0))))
   `(isearch ((,class (:foreground ,bg :background ,sun-2))))
   `(lazy-highlight ((,class (:foreground ,bg :background ,sun-4))))
   `(link ((,class (:underline t :foreground ,sun-0))))
   `(link-visited ((,class (:inherit link))))
   `(vertical-border ((,class (:foreground ,sun-0))))
   `(error ((,class (:foreground ,error))))
   `(warning ((,class (:foreground ,warning))))
   `(success ((,class (:foreground ,success))))
   `(outline-1 ((,class (:foreground ,sun-3))))
   `(outline-2 ((,class (:inherit outline-1))))
   `(outline-3 ((,class (:inherit outline-1))))
   `(outline-4 ((,class (:inherit outline-1))))
   `(outline-5 ((,class (:inherit outline-1))))
   `(outline-6 ((,class (:inherit outline-1))))
   `(outline-7 ((,class (:inherit outline-1))))
   `(outline-8 ((,class (:inherit outline-1))))
   `(minibuffer-prompt ((,class (:foreground ,sun-1))))
   ;; Mode-line faces
   `(mode-line ((,class (:foreground ,sun-1 :background ,bg :box (:line-width -1 :color ,sun-1)))))
   `(mode-line-inactive ((,class (:foreground ,sun-0 :background ,grey-1 :box (:line-width -1 :color ,sun-0)))))
   ;; Line number faces
   `(line-number ((,class (:foreground ,grey-2))))
   `(line-number-current-line ((,class (:foreground ,sun-1 :background ,grey-0))))
   `(linum ((,class (:inherit line-number))))
   ;; Font lock faces
   `(font-lock-keyword-face ((,class (:foreground ,sun-1))))
   `(font-lock-function-name-face ((,class (:foreground ,sun-3))))
   `(font-lock-warning-face ((,class (:foreground ,fg :underline (:color ,warning :style wave)))))
   `(font-lock-builtin-face ((,class (:foreground ,sun-4))))
   `(font-lock-variable-name-face ((,class (:foreground ,sun-3))))
   `(font-lock-constant-face ((,class (:foreground ,fg))))
   `(font-lock-type-face ((,class (:foreground ,sun-1))))
   `(font-lock-preprocessor-face ((,class (:foreground ,sun-1))))
   `(font-lock-comment-face ((,class (:foreground ,earth-1))))
   `(font-lock-string-face ((,class (:foreground ,sun-4))))
   `(font-lock-doc-face ((,class (:inherit font-lock-comment-face))))
   ;; Shell script faces
   `(sh-heredoc ((t nil)))
   ;; Org faces
   `(org-block ((,class (:foreground ,fg :extend t :inherit (fixed-pitch shadow)))))
   `(org-block-begin-line ((,class (:foreground ,sun-0))))
   `(org-block-end-line ((,class (:inherit org-block-begin-line))))
   `(org-code ((,class (:foreground ,sun-0))))
   `(org-headline-done ((,class (:foreground ,sun-1))))
   `(org-document-title ((,class (:foreground ,sun-0))))
   `(org-drawer ((,class (:foreground ,sun-3))))
   `(org-link ((,class (:inherit link))))
   `(org-date ((,class (:inherit (fixed-pitch link)))))
   ;; Terraform faces
   `(terraform--resource-name-face ((,class (:foreground ,sun-3))))
   `(terraform--resource-type-face ((,class (:foreground ,sun-1))))))

(provide-theme 'tok)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; tok-theme.el ends here
