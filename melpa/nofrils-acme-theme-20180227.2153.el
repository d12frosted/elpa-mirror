;;; nofrils-acme-theme.el --- Port of "No Frils Acme" Vim theme.

;; Copyright (c) 2018 Eric Sessoms
;; See COPYING for details.

;; Author: Eric Sessoms <esessoms@protonmail.com>
;; Package-Requires: ((emacs "24"))
;; Package-Version: 20180227.2153
;; Package-Commit: 7825f88cb881a84eaa5cd1689772819a18eb2943
;; URL: https://gitlab.com/esessoms/nofrils-theme
;; Version: 0.1.0

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Minimal syntax highlighting to reduce distractions.  Only
;; highlights comments and errors by default.  High-contrast
;; black-on-yellow and other colors inspired by Plan 9's Acme.

;; (require 'nofrils-acme-theme)
;; (load-theme 'nofrils-acme t)

;;; Credits:

;; This theme was ported from No Frils Acme by Robert Melton.
;; https://github.com/robertmeta/nofrils

;;; Code:

(deftheme nofrils-acme
  "Port of No Frils Acme by Robert Melton.")

(let ((background "#FFFFD7")
      (foreground "#000000")
      (comment "#AF8700")
      (error "#FF5555")
      (fringe "#EAFFFF")
      (search "#40883F")
      (selection "#CCCC7C")
      (status "#AEEEEE"))

  (custom-theme-set-faces
   'nofrils-acme

   `(default ((t :background ,background :foreground ,foreground)))

   ;; Highlight only comments and errors.
   `(error ((t :background "white" :foreground ,error)))
   `(font-lock-builtin-face ((t nil)))
   `(font-lock-comment-face ((t :foreground ,comment)))
   `(font-lock-constant-face ((t nil)))
   `(font-lock-function-name-face ((t nil)))
   `(font-lock-keyword-face ((t nil)))
   `(font-lock-negation-char-face ((t nil)))
   `(font-lock-regexp-grouping-backslash ((t nil)))
   `(font-lock-regexp-grouping-construct ((t nil)))
   `(font-lock-string-face ((t nil)))
   `(font-lock-type-face ((t nil)))
   `(font-lock-variable-name-face ((t nil)))

   ;; Show searches and selections.
   `(isearch ((t :background ,search :foreground "white")))
   `(lazy-highlight ((t :background "white" :foreground ,foreground)))
   `(region ((t :background ,selection)))

   ;; Parenthesis matching is never wrong.
   `(show-paren-match ((t :weight bold)))
   `(show-paren-mismatch ((t :background ,error :weight bold)))

   ;; Decorate the frame to resemble Acme.
   `(fringe ((t :background ,fringe)))
   `(minibuffer-prompt ((t :foreground ,foreground)))
   `(mode-line ((t :background ,status)))
   `(mode-line-inactive ((t :background ,fringe)))

   ;; Org mode needs to chill.
   `(org-done ((t :weight bold)))
   `(org-todo ((t :weight bold)))))

;;; Footer:

;;;###autoload
(when load-file-name
  (add-to-list
   'custom-theme-load-path
   (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'nofrils-acme)

(provide 'nofrils-acme-theme)

;;; nofrils-acme-theme.el ends here
