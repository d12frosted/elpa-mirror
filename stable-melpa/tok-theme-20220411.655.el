;;; tok-theme.el --- Simple dark theme with cyberpunk aesthetics  -*- lexical-binding: t; -*-

;; Copyright (C) 2022, Topi Kettunen <topi@topikettunen.com>

;; Author: Topi Kettunen <topi@topikettunen.com>
;; URL: https://github.com/topikettunen/tok-theme
;; Package-Version: 20220411.655
;; Package-Commit: f8ec6b3e301d511649ce84b36067c8eab7038c72
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

;; Tok is a simple Emacs theme emphasizing the aesthetics of old terminals
;; with the classic dark and green color scheme.

;;; Code:

(deftheme tok
  "Simple dark theme with cyberpunk aesthetics")

(let* ((class '((class color) (min-colors 89)))
       ;; Color palette
       (primary "#33ff33")
       (primary2 "#008000")
       (primary3 "#004d00")
       (primary4 "#003300")
       (primary5 "#001900")
       (bg "#151515")
       (fg primary)
       (fg-highlight fg)
       (bg-highlight primary5)
       (fg-active primary)
       (bg-active primary3)
       (fg-inactive primary2)
       (bg-inactive primary4)
       (hl-line primary4)
       (region primary4)
       (comment primary2)
       (link primary))
  (custom-theme-set-faces
   'tok
   ;; Basic faces
   `(default ((,class (:background ,bg :foreground ,fg))))
   `(fringe ((,class (:background ,bg :foreground ,fg))))
   `(cursor ((,class (:background ,primary))))
   `(region ((,class (:foreground ,fg :background ,region))))
   `(vertical-border ((,class (:foreground ,primary))))
   `(show-paren-match ((,class (:foreground ,fg :background ,primary2))))
   `(hl-line ((,class (:foreground ,fg :background ,hl-line))))
   `(isearch ((,class (:foreground ,fg :background ,primary2))))
   `(link ((,class (:foreground ,primary :underline t))))
   `(mode-line ((,class (:foreground ,fg-active :background ,bg-active :box (:line-width 1 :color ,fg-active)))))
   `(mode-line-inactive ((,class (:foreground ,fg-inactive :background ,bg-inactive :box (:line-width 1 :color ,fg-inactive)))))
   `(line-number ((,class (:foreground ,primary3))))
   `(line-number-current-line ((,class (:foreground ,primary :background ,primary4))))
   `(minibuffer-prompt ((,class (:foreground ,primary))))
   ;; Org faces
   `(org-block ((,class (:foreground ,fg :extend t :inherit (fixed-pitch shadow)))))
   `(org-block-begin-line ((,class (:foreground ,comment))))
   `(org-block-end-line ((,class (:foreground ,comment))))
   `(org-code ((,class (:foreground ,comment))))
   `(org-headline-done ((,class (:foreground ,comment))))
   `(org-document-title ((,class (:foreground ,fg))))
   `(org-drawer ((,class (:foreground ,comment))))
   `(org-link ((,class (:foreground ,primary :underline t))))
   ;; Disabled faces
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
   `(font-lock-string-face ((t nil)))
   `(font-lock-doc-face ((t nil)))
   `(font-lock-comment-face ((t nil)))
   `(sh-heredoc ((t nil)))
   '(terraform--resource-name-face ((t nil)))
   '(terraform--resource-type-face ((t nil)))))


(provide-theme 'tok)

;;; tok-theme.el ends here
