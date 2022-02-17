;;; simplicity-theme.el --- A minimalist dark theme  -*- lexical-binding: t -*-

;; Copyright (C) 2021 Matthieu Petiteau <mpetiteau.pro@gmail.com>

;; Author: Matthieu Petiteau <mpetiteau.pro@gmail.com>
;; Maintainer: Matthieu Petiteau <mpetiteau.pro@gmail.com>
;; Keywords: faces, theme, minimal
;; Package-Version: 20220217.1928
;; Package-Commit: 2a0aaf19cf1e99c50df0d2e6225a2d2931a203d2
;; Homepage: http://github.com/smallwat3r/emacs-simplicity-theme
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.1"))
;; Licence: GPL-3.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A minimalist dark theme for Emacs.
;; Most of the colors have been turned off, which gets rid of any
;; distraction and improve focus on reading and writing code after
;; getting used to it.

;;; Code:

(deftheme simplicity "A minimalist dark theme.")

(defgroup simplicity-theme nil
  "Simplicity theme."
  :group 'faces
  :prefix "simplicity-"
  :link '(url-link :tag "GitHub" "http://github.com/smallwat3r/emacs-simplicity-theme")
  :tag "Simplicity theme")

;;;###autoload
(eval-and-compile
  (defcustom simplicity-override-colors-alist '()
    "Place to override default theme colors.

You can override a subset of the theme's default colors by
defining them in this alist."
    :group 'simplicity-theme
    :type '(alist
            :key-type (string :tag "Name")
            :value-type (string :tag " Hex"))))

(eval-and-compile
  (defvar simplicity-default-colors-alist
    '(("simplicity-foreground"    . "#eeeeee")
      ("simplicity-background"    . "#000000")
      ("simplicity-comment"       . "#b4a7d6")
      ("simplicity-string"        . "#d3e0bc")
      ("simplicity-white"         . "#ffffff")
      ("simplicity-grey-1"        . "#dddddd")
      ("simplicity-grey"          . "#595959")
      ("simplicity-grey+1"        . "#403D3D")
      ("simplicity-grey+2"        . "#1A1A1A")
      ("simplicity-yellow-1"      . "#fffcb9")
      ("simplicity-yellow"        . "#f2ff2a")
      ("simplicity-green"         . "#b6d7a8")
      ("simplicity-magenta"       . "#d7b3d8")
      ("simplicity-orange"        . "#ff5f00")
      ("simplicity-red"           . "#ff25a9")
      ("simplicity-cyan"          . "#97FFEB")
      ("simplicity-cyan+1"        . "#00ffff")
      ("simplicity-purple"        . "#420dab")
      ("simplicity-blue"          . "#aaddd2")
      ("simplicity-navy"          . "#010029"))
    "List of Simplicity colors."))

(defmacro simplicity-with-color-variables (&rest body)
  "Binds all simplicity colors around BODY."
  (declare (indent 0))
  `(let (,@(mapcar (lambda (cons)
                     (list (intern (car cons)) (cdr cons)))
                   (append simplicity-default-colors-alist
                           simplicity-override-colors-alist)))
     ,@body))

(simplicity-with-color-variables
  (custom-theme-set-faces
   'simplicity
;;;;; General
   `(default
      ((t (:background ,simplicity-background
           :foreground ,simplicity-foreground))))
   `(cursor
     ((t (:background ,simplicity-cyan
          :foreground ,simplicity-background))))
   `(hl-line
     ((t (:background ,simplicity-background))))
   `(fringe
     ((t (:background ,simplicity-background))))
   `(success
     ((t (:foreground ,simplicity-green))))
   `(warning
     ((t (:foreground ,simplicity-orange))))
   `(error
     ((t (:foreground ,simplicity-red))))
   `(link
     ((t (:background ,simplicity-background
          :foreground ,simplicity-cyan+1
          :underline t))))
   `(link-visited
     ((t (:background ,simplicity-background
          :foreground ,simplicity-purple
          :underline t))))
   `(highlight
     ((t (:background ,simplicity-grey+2
          :foreground ,simplicity-white
          :weight bold))))
;;;;; Markdown
   `(markdown-pre-face
     ((t (:foreground ,simplicity-yellow-1))))
   `(markdown-inline-code-face
     ((t (:foreground ,simplicity-yellow-1))))
;;;;; Org
   `(org-code
     ((t (:foreground ,simplicity-yellow-1))))
   `(org-block-begin-line
     ((t (:background ,simplicity-navy
          :foreground ,simplicity-cyan+1))))
   `(org-block-end-line
     ((t (:background ,simplicity-navy
          :foreground ,simplicity-cyan+1))))
;;;;; Modeline
   `(mode-line-inactive
     ((t (:box nil
          :foreground ,simplicity-background
          :background ,simplicity-grey))))
   `(mode-line
     ((t (:box nil
          :foreground ,simplicity-background
          :background ,simplicity-grey-1))))
;;;;; Search
   `(isearch
     ((t (:foreground ,simplicity-navy
          :background ,simplicity-yellow-1
          :weight bold))))
   `(isearch-fail
     ((t (:foreground ,simplicity-red
          :weight bold))))
   `(lazy-highlight
     ((t (:foreground ,simplicity-navy
          :background ,simplicity-yellow-1
          :weight bold))))
   `(pdf-isearch-match
     ((t (:foreground ,simplicity-navy
          :background ,simplicity-cyan
          :weight bold))))
;;;;; XML
   `(nxml-element-local-name
     ((t (:foreground ,simplicity-yellow-1))))
   `(nxml-tag-delimiter
     ((t (:foreground ,simplicity-yellow-1))))
;;;;; Web-mode
   `(web-mode-html-tag-face
     ((t (:foreground ,simplicity-yellow-1))))
   `(web-mode-html-tag-bracket-face
     ((t (:foreground ,simplicity-yellow-1))))
   `(web-mode-html-attr-name-face
     ((t (:foreground ,simplicity-foreground))))
;;;;; Dired search prompt
   `(minibuffer-prompt
     ((t (:foreground ,simplicity-foreground))))
;;;;; Line number
   `(line-number
     ((t (:background nil
          :foreground ,simplicity-grey))))
   `(line-number-current-line
     ((t (:background nil
          :foreground ,simplicity-foreground))))
;;;;; Highlight region color
   `(region
     ((t (:foreground ,simplicity-foreground
          :background ,simplicity-grey+1))))
;;;;; Builtins
   `(font-lock-builtin-face
     ((t (:foreground ,simplicity-foreground))))
;;;;; Constants
   `(font-lock-constant-face
     ((t (:foreground ,simplicity-foreground))))
;;;;; Comments
   `(font-lock-comment-face
     ((t (:foreground ,simplicity-comment))))
   `(font-lock-doc-face
     ((t (:foreground ,simplicity-comment))))
;;;;; Function names
   `(font-lock-function-name-face
     ((t (:foreground ,simplicity-foreground))))
;;;;; Keywords
   `(font-lock-keyword-face
     ((t (:foreground ,simplicity-foreground))))
;;;;; Strings
   `(font-lock-string-face
     ((t (:foreground ,simplicity-string))))
;;;;; Variables
   `(font-lock-variable-name-face
     ((t (:foreground ,simplicity-foreground))))
   `(font-lock-type-face
     ((t (:foreground ,simplicity-foreground))))
   `(font-lock-warning-face
     ((t (:foreground ,simplicity-red :weight bold))))
;;;;; Parenthesis
   `(show-paren-match
     ((t (:foreground ,simplicity-navy
          :background ,simplicity-cyan
          :underline (:color ,simplicity-cyan)
          :weight bold))))
   `(show-paren-mismatch
     ((t (:background ,simplicity-red
          :foreground ,simplicity-foreground
          :underline (:color ,simplicity-red)
          :weight bold))))
;;;;; sh
   `(sh-quoted-exec
     ((t (:foreground ,simplicity-yellow-1 :weight bold))))
;;;;; Ivy
   `(ivy-current-match
     ((t (:background ,simplicity-background
          :foreground ,simplicity-white
          :underline (:color ,simplicity-cyan)
          :weight bold))))
   `(ivy-minibuffer-match-highlight
     ((t (:inherit ivy-current-match
          :background ,simplicity-background
          :foreground ,simplicity-foreground
          :weight bold))))
   `(ivy-yanked-word
     ((t (:inherit ivy-current-match
          :background ,simplicity-yellow-1))))
   `(ivy-minibuffer-match-face-1
     ((t (:inherit ivy-current-match
          :background ,simplicity-background))))
   `(ivy-minibuffer-match-face-2
     ((t (:inherit ivy-current-match
          :background ,simplicity-background
          :foreground ,simplicity-cyan))))
   `(ivy-minibuffer-match-face-3
     ((t (:inherit ivy-current-match
          :background ,simplicity-background
          :foreground ,simplicity-green))))
   `(ivy-minibuffer-match-face-4
     ((t (:inherit ivy-current-match
          :background ,simplicity-background
          :foreground ,simplicity-yellow))))
;;;;; Ivy-posframe
   `(ivy-posframe
     ((t (:background ,simplicity-navy
          :foreground ,simplicity-foreground))))
   `(ivy-posframe-border
     ((t (:background ,simplicity-cyan))))
;;;;; Swiper
   `(swiper-line-face
     ((t (:background ,simplicity-navy
          :foreground ,simplicity-foreground
          :weight bold))))
;;;;; Eshell
   `(eshell-syntax-highlighting-alias-face
     ((t (:background ,simplicity-background
          :foreground ,simplicity-cyan))))
   `(eshell-syntax-highlighting-command-face
     ((t (:background ,simplicity-background
          :foreground ,simplicity-green))))
;;;;; Flycheck
   `(flycheck-error
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,simplicity-red)
        :inherit unspecified))
      (t (:foreground ,simplicity-red
          :weight bold
          :underline t))))
   `(flycheck-error-list-error
     ((t (:foreground ,simplicity-red))))
   `(flycheck-fringe-error
     ((t (:foreground ,simplicity-red))))
   `(flycheck-posframe-error-face
     ((t (:foreground ,simplicity-red))))
   `(flycheck-error-list-error-message
     ((t (:foreground ,simplicity-red))))
   `(flycheck-info
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,simplicity-cyan)
        :inherit unspecified))
      (t (:foreground ,simplicity-cyan
          :weight bold
          :underline t))))
   `(flycheck-error-list-info
     ((t (:foreground ,simplicity-cyan))))
   `(flycheck-fringe-info
     ((t (:foreground ,simplicity-cyan))))
   `(flycheck-posframe-info-face
     ((t (:foreground ,simplicity-cyan))))
   `(flycheck-warning
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,simplicity-yellow)
        :inherit unspecified))
      (t (:foreground ,simplicity-yellow
          :weight bold
          :underline t))))
   `(flycheck-error-list-warning
     ((t (:foreground ,simplicity-yellow))))
   `(flycheck-fringe-warning
     ((t (:foreground ,simplicity-yellow))))
   `(flycheck-posframe-warning-face
     ((t (:foreground ,simplicity-yellow))))
;;;;; Company
   `(company-tooltip
     ((t (:background ,simplicity-grey+2
          :foreground ,simplicity-foreground))))
   `(company-tooltip-common
     ((t (:inherit company-tooltip
          :foreground ,simplicity-white
          :weight bold))))
   `(company-tooltip-selection
     ((t (:foreground ,simplicity-white
          :background ,simplicity-grey+1
          :weight bold))))
   `(company-tooltip-common-selection
     ((t (:inherit company-tooltip-selection))))
   `(company-tooltip-annotation
     ((t (:inherit company-tooltip
          :foreground ,simplicity-string))))
   `(company-tooltip-annotation-selection
     ((t (:inherit company-tooltip-selection))))
   `(company-scrollbar-fg
     ((t (:background ,simplicity-grey))))
   `(company-scrollbar-bg
     ((t (:background ,simplicity-string))))
   `(company-preview
     ((t (:foreground ,simplicity-cyan
          :background ,simplicity-background
          :slant italic))))
   `(company-preview-common
     ((t (:foreground ,simplicity-cyan
          :background ,simplicity-background
          :slant italic))))
;;;;; vTerm
   `(vterm-color-black
     ((t (:background "gray35"
          :foreground "gray35"))))
   `(vterm-color-blue
     ((t (:background ,simplicity-blue
          :foreground ,simplicity-blue))))
   `(vterm-color-cyan
     ((t (:background ,simplicity-cyan
          :foreground ,simplicity-cyan))))
   `(vterm-color-default
     ((t (:background ,simplicity-background
          :foreground ,simplicity-foreground))))
   `(vterm-color-green
     ((t (:background ,simplicity-green
          :foreground ,simplicity-green))))
   `(vterm-color-inverse-video
     ((t (:background ,simplicity-background
          :inverse-video t))))
   `(vterm-color-magenta
     ((t (:background ,simplicity-magenta
          :foreground ,simplicity-magenta))))
   `(vterm-color-red
     ((t (:background ,simplicity-red
          :foreground ,simplicity-red))))
   `(vterm-color-white
     ((t (:background "gray65"
          :foreground "gray65"))))
   `(vterm-color-yellow
     ((t (:background ,simplicity-yellow
          :foreground ,simplicity-yellow))))
;;;;; term
   `(term-color-black
     ((t (:background "gray35"
          :foreground "gray35"))))
   `(term-color-blue
     ((t (:background ,simplicity-blue
          :foreground ,simplicity-blue))))
   `(term-color-cyan
     ((t (:background ,simplicity-cyan
          :foreground ,simplicity-cyan))))
   `(term-color-green
     ((t (:background ,simplicity-green
          :foreground ,simplicity-green))))
   `(term-color-magenta
     ((t (:background ,simplicity-magenta
          :foreground ,simplicity-magenta))))
   `(term-color-red
     ((t (:background ,simplicity-red
          :foreground ,simplicity-red))))
   `(term-color-white
     ((t (:background "gray65"
          :foreground "gray65"))))
   `(term-color-yellow
     ((t (:background ,simplicity-yellow
          :foreground ,simplicity-yellow))))
   `(term-default-fg-color
     ((t (:inherit term-color-white))))
   `(term-default-bg-color
     ((t (:inherit term-color-black))))
;;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face
     ((t (:foreground ,simplicity-blue))))
   `(rainbow-delimiters-depth-2-face
     ((t (:foreground ,simplicity-green))))
   `(rainbow-delimiters-depth-3-face
     ((t (:foreground ,simplicity-magenta))))
   `(rainbow-delimiters-depth-4-face
     ((t (:foreground ,simplicity-cyan))))
   `(rainbow-delimiters-depth-5-face
     ((t (:foreground ,simplicity-yellow))))
   `(rainbow-delimiters-depth-6-face
     ((t (:foreground ,simplicity-orange))))
   `(rainbow-delimiters-depth-7-face
     ((t (:foreground ,simplicity-red))))
   `(rainbow-delimiters-depth-8-face
     ((t (:foreground ,simplicity-blue))))
   `(rainbow-delimiters-depth-9-face
     ((t (:foreground ,simplicity-green))))
   `(rainbow-delimiters-mismatched-face
     ((t (:inherit show-paren-mismatch))))
   `(rainbow-delimiters-unmatched-face
     ((t (:inherit show-paren-mismatch))))
;;;;; dired
   `(dired-directory
     ((t (:foreground ,simplicity-orange))))
   `(dired-flagged
     ((t (:background ,simplicity-background
          :foreground ,simplicity-magenta))))
   `(dired-header
     ((t (:background ,simplicity-background
          :foreground ,simplicity-yellow))))
;;;;; diredfl
   `(diredfl-dir-name
     ((t (:inherit dired-directory))))
   `(diredfl-dir-heading
     ((t (:inherit dired-header))))
   `(diredfl-exec-priv
     ((t (:background ,simplicity-background
          :foreground ,simplicity-red))))
   `(diredfl-executable-tag
     ((t (:background ,simplicity-background
          :foreground ,simplicity-cyan))))
   `(diredfl-read-priv
     ((t (:background ,simplicity-background
          :foreground ,simplicity-green))))
   `(diredfl-write-priv
     ((t (:background ,simplicity-background
          :foreground ,simplicity-magenta))))
   `(diredfl-no-priv
     ((t (:background ,simplicity-background
          :foreground ,simplicity-foreground))))
   `(diredfl-rare-priv
     ((t (:background ,simplicity-background
          :foreground ,simplicity-magenta))))
   `(diredfl-other-priv
     ((t (:background ,simplicity-background
          :foreground ,simplicity-yellow))))
   `(diredfl-dir-priv
     ((t (:background ,simplicity-background
          :foreground ,simplicity-orange))))
   `(diredfl-date-time
     ((t (:background ,simplicity-background
          :foreground ,simplicity-foreground))))
   `(diredfl-file-name
     ((t (:background ,simplicity-background
          :foreground ,simplicity-foreground))))
   `(diredfl-file-suffix
     ((t (:background ,simplicity-background
          :foreground ,simplicity-yellow))))
   `(diredfl-number
     ((t (:background ,simplicity-background
          :foreground ,simplicity-foreground))))
   `(diredfl-flag-mark
     ((t (:background ,simplicity-background
          :foreground ,simplicity-magenta))))
;;;;; git-gutter
   `(git-gutter:added
     ((t (:foreground ,simplicity-green
          :background ,simplicity-background))))
   `(git-gutter:modified
     ((t (:foreground ,simplicity-yellow
          :background ,simplicity-background))))
   `(git-gutter:deleted
     ((t (:foreground ,simplicity-red
          :background ,simplicity-background))))
;;;;; git-gutter-fringe
   `(git-gutter-fr:added
     ((t (:inherit git-gutter:added))))
   `(git-gutter-fr:modified
     ((t (:inherit git-gutter:modified))))
   `(git-gutter-fr:deleted
     ((t (:inherit git-gutter:deleted))))
;;;;; git-gutter+
   `(git-gutter+-added
     ((t (:inherit git-gutter:added))))
   `(git-gutter+-modified
     ((t (:inherit git-gutter:modified))))
   `(git-gutter+-deleted
     ((t (:inherit git-gutter:deleted))))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name)))
  (when (not window-system)
    (custom-set-faces '(default ((t (:background nil)))))))

(provide-theme 'simplicity)

;;; simplicity-theme.el ends here
