;;; tok-theme.el --- Minimal theme with dark and yellow color scheme  -*- lexical-binding: t; -*-

;; Copyright (C) 2022, Topi Kettunen <topi@topikettunen.com>

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20220501.2130
;; Package-Commit: 4efb664ed48df333b29ac06fc99dd529c08a3acc
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

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
       (grey-0 "#454545") (grey-1 "#353535")
       (fg "#eaeaea") (bg "#282828"))
  (custom-theme-set-faces
   'tok
   ;; Basic faces
   `(default ((,class (:foreground ,fg :background ,bg))))
   `(fringe ((,class (:inherit default))))
   `(cursor ((,class (:background ,sun-0))))
   `(region ((,class (:background ,grey-0))))
   `(show-paren-match ((,class (:foreground ,bg :background ,sun-3))))
   `(hl-line ((,class (:foreground ,fg :background ,grey-1))))
   `(isearch ((,class (:foreground ,bg :background ,sun-2))))
   `(lazy-highlight ((,class (:foreground ,bg :background ,sun-4))))
   `(link ((,class (:underline t :foreground ,sun-0))))
   `(link-visited ((,class (:inherit link))))
   `(mode-line ((,class (:foreground ,sun-1 :background ,bg :box (:line-width 1 :color ,sun-1)))))
   `(mode-line-inactive ((,class (:foreground ,sun-0 :background ,grey-1 :box (:line-width 1 :color ,sun-0)))))
   `(line-number ((,class (:foreground ,grey-0))))
   `(line-number-current-line ((,class (:foreground ,sun-1 :background ,grey-1))))
   `(error ((,class (:foreground "Red1"))))
   `(warning ((,class (:foreground "DarkOrange2"))))
   `(success ((,class (:foreground "ForestGreen"))))
   ;; Font lock faces
   `(font-lock-comment-face ((t nil)))
   `(font-lock-string-face ((t nil)))
   `(font-lock-doc-face ((t nil)))
   `(font-lock-builtin-face ((t nil)))
   `(font-lock-keyword-face ((t nil)))
   `(font-lock-negation-char-face ((t nil)))
   `(font-lock-reference-face ((t nil)))
   `(font-lock-constant-face ((t nil)))
   `(font-lock-function-name-face ((t nil)))
   `(font-lock-type-face ((t nil)))
   `(font-lock-variable-name-face ((t nil)))
   `(font-lock-warning-face ((t nil)))
   `(font-lock-preprocessor-face ((t nil)))
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
   '(terraform--resource-name-face ((t nil)))
   '(terraform--resource-type-face ((t nil)))))

(provide-theme 'tok)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; tok-theme.el ends here
