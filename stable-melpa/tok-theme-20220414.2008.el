;;; tok-theme.el --- Minimal theme with yellow and green color scheme  -*- lexical-binding: t; -*-

;; Copyright (C) 2022, Topi Kettunen <topi@topikettunen.com>

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20220414.2008
;; Package-Commit: be713a135fe50047fe33f076c2ddfb8d95570ab6
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

;; Tok is a simple and minimal Emacs theme with dark green and yellow color
;; scheme.

;;; Code:

(deftheme tok
  "Minimal Emacs theme with yellow and green color scheme")

(let* ((class '((class color) (min-colors 89)))
       ;; Color palette
       (emerald "#33ff33")
       (emerald-2 "#008000")
       (emerald-3 "#004d00")
       (emerald-4 "#003300")
       (emerald-5 "#001900")
       (bg emerald-5)
       (fg "#fae68c")
       (fg-highlight fg)
       (bg-highlight emerald-5)
       (fg-active bg)
       (bg-active fg)
       (fg-inactive fg)
       (bg-inactive "#998d56")
       (hl-line emerald-4)
       (region emerald-4)
       (comment emerald-2)
       (link emerald)
       (red "#ff4b4b"))
  (custom-theme-set-faces
   'tok
   ;; Basic faces
   `(default ((,class (:background ,bg :foreground ,fg))))
   `(fringe ((,class (:background ,bg :foreground ,fg))))
   `(cursor ((,class (:background ,emerald))))
   `(region ((,class (:foreground ,fg :background ,region))))
   `(show-paren-match ((,class (:foreground ,fg :background ,emerald-2))))
   `(hl-line ((,class (:foreground ,fg :background ,hl-line))))
   `(isearch ((,class (:foreground ,fg :background ,emerald-2))))
   `(link ((,class (:foreground ,emerald :underline t))))
   `(mode-line ((,class (:foreground ,fg-active :background ,bg-active))))
   `(mode-line-inactive ((,class (:foreground ,fg-active :background ,bg-inactive))))
   `(line-number ((,class (:foreground ,emerald-3))))
   `(line-number-current-line ((,class (:foreground ,fg))))
   ;; Font lock faces
   `(font-lock-comment-face ((,class (:foreground ,comment))))
   `(font-lock-string-face ((,class (:foreground ,emerald))))
   `(font-lock-doc-face ((,class (:inherit font-lock-string-face))))
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
   `(org-block-begin-line ((,class (:foreground ,comment))))
   `(org-block-end-line ((,class (:foreground ,comment))))
   `(org-code ((,class (:foreground ,comment))))
   `(org-headline-done ((,class (:foreground ,comment))))
   `(org-document-title ((,class (:foreground ,fg))))
   `(org-drawer ((,class (:foreground ,comment))))
   `(org-link ((,class (:foreground ,emerald :underline t))))
   ;; Terraform faces
   '(terraform--resource-name-face ((t nil)))
   '(terraform--resource-type-face ((t nil)))))

(provide-theme 'tok)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; tok-theme.el ends here
