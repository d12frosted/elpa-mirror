;;; tok-theme.el --- Minimal theme with dark and yellow color scheme  -*- lexical-binding: t; -*-

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20220621.2110
;; Package-Commit: beb7c7ef691bd5b3254f43d7e596b6210215f4bb
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

;; Tok is a simple and minimal Emacs theme with personal preferences.

;;; Code:

(deftheme tok
  "Minimal Emacs theme with dark and yellow color scheme")

(let ((class '((class color) (min-colors 89))))
  (custom-theme-set-faces
   'tok
   ;; Basic faces
   `(default ((,class (:foreground "black" :background "white"))))
   `(cursor ((,class (:background "red"))))
   `(region ((,class (:background "khaki"))))
   `(outline-1 ((,class (:weight bold))))
   `(outline-2 ((,class (:inherit outline-1))))
   `(outline-3 ((,class (:inherit outline-1))))
   `(outline-4 ((,class (:inherit outline-1))))
   `(outline-5 ((,class (:inherit outline-1))))
   `(outline-6 ((,class (:inherit outline-1))))
   `(outline-7 ((,class (:inherit outline-1))))
   `(outline-8 ((,class (:inherit outline-1))))
   ;; Mode-line faces
   `(mode-line ((,class (:foreground "black" :background "goldenrod1"))))
   `(mode-line-inactive ((,class (:foreground "black" :background "goldenrod3"))))
   ;; ;; Font lock faces
   `(font-lock-keyword-face ((t nil)))
   `(font-lock-function-name-face ((t nil)))
   `(font-lock-warning-face ((t nil)))
   `(font-lock-builtin-face ((t nil)))
   `(font-lock-variable-name-face ((t nil)))
   `(font-lock-constant-face ((t nil)))
   `(font-lock-type-face ((t nil)))
   `(font-lock-preprocessor-face ((t nil)))
   `(font-lock-comment-face ((t nil)))
   `(font-lock-string-face ((t nil)))
   `(font-lock-doc-face ((t nil)))
   ;; ;; Shell script faces
   `(sh-heredoc ((t nil)))
   ;; ;; Org faces
   `(org-block ((,class nil)))
   `(org-block-begin-line ((,class (:inherit shadow))))
   `(org-block-end-line ((,class (:inherit org-block-begin-line))))
   `(org-code ((,class nil)))
   `(org-headline-done ((,class nil)))
   `(org-document-title ((,class nil)))
   `(org-drawer ((,class nil)))
   `(org-link ((,class (:inherit link))))
   `(org-date ((,class (:inherit (fixed-pitch link)))))
   `(org-meta-line ((,class (:inherit org-document-info-keyword))))
   ;; ;; Terraform faces
   `(terraform--resource-name-face ((t nil)))
   `(terraform--resource-type-face ((t nil)))))

(provide-theme 'tok)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; tok-theme.el ends here
