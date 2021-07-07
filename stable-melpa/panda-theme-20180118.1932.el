;;; panda-theme.el --- Panda Theme

;; Copyright 2018-present, all rights reserved.
;;
;; Code licensed under MIT licence.

;; Author: jamiecollinson
;; Version: 0.1
;; Package-Commit: ae24179e7a8a9667b169f00dbd891257530c1d22
;; Package-Version: 20180118.1932
;; Package-X-Original-Version: 20180114t1941
;; Package-Requires: ((emacs "24"))
;; URL: https://github.com/jamiecollinson/emacs-panda-theme

;;; Commentary:

;; A Superminimal, dark Syntax Theme for Editors, IDEs, Terminal.
;; Color scheme from http://panda.siamak.work

;;; Code:

(deftheme panda
  "Created 2018-01-11.")

(let ((bg "#292A2B")
      (bg+ "#404954") ;; emphasis

      (fg- "#676B79") ;; de-emphasis
      (fg "#E6E6E6")
      (fg+ "#F8F8F0") ;; emphasis

      (cyan "#35ffdc")
      (pink "#ff90d0")
      (red "#ec2864")
      (orange "#ffb86c")
      (blue "#7dc1ff")
      (purple "#b084eb"))

  (custom-theme-set-faces
   'panda

   ;; Default
   `(default ((t (:background ,bg :foreground ,fg))))
   `(italic ((t (:italic t))))
   `(cursor ((t (:background ,fg+))))
   `(ffap ((t :foreground ,fg+)))
   `(fringe ((t (:background ,bg))))
   `(highlight ((t (:background ,bg+))))
   `(region ((t :background ,bg+)))
   `(linum ((t :foreground ,fg-)))
   `(lazy-highlight ((t (:background ,orange))))
   `(link ((t (:foreground ,blue :underline t))))
   `(minibuffer-prompt ((t :foreground ,pink)))
   `(region ((t (:background ,pink :foreground ,bg))))
   `(show-paren-match-face ((t (:background ,red))))
   `(trailing-whitespace ((t :foreground nil :background ,red)))
   `(vertical-border ((t (:foreground ,fg-))))
   `(warning ((t (:foreground ,orange))))

   ;; flycheck
   `(flycheck-info ((t :underline ,cyan)))
   `(flycheck-warning ((t :underline ,orange)))
   `(flycheck-error ((t :underline ,red)))
   `(flycheck-fringe-info ((t :foreground ,cyan)))
   `(flycheck-fringe-warning ((t :foreground ,orange)))
   `(flycheck-fringe-error ((t :foreground ,red)))

   ;; Syntax highlighting
   `(font-lock-builtin-face ((t (:foreground ,orange))))
   `(font-lock-comment-face ((t (:foreground ,fg- :inherit italic))))
   `(font-lock-constant-face ((t (:foreground ,orange))))
   `(font-lock-doc-face ((t (:foreground ,fg- :inherit italic))))
   `(font-lock-function-name-face ((t (:foreground ,blue))))
   `(font-lock-keyword-face ((t (:foreground ,orange))))
   `(font-lock-string-face ((t (:foreground ,cyan))))
   `(font-lock-type-face ((t (:foreground ,purple))))
   `(font-lock-variable-name-face ((t (:foreground ,pink))))
   `(font-lock-warning-face ((t (:foreground ,red :background ,bg+))))

   ;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((t :foreground ,fg+)))
   `(rainbow-delimiters-depth-2-face ((t :foreground ,cyan)))
   `(rainbow-delimiters-depth-3-face ((t :foreground ,pink)))
   `(rainbow-delimiters-depth-4-face ((t :foreground ,blue)))
   `(rainbow-delimiters-depth-5-face ((t :foreground ,orange)))
   `(rainbow-delimiters-depth-6-face ((t :foreground ,purple)))
   `(rainbow-delimiters-depth-7-face ((t :foreground ,cyan)))
   `(rainbow-delimiters-depth-8-face ((t :foreground ,pink)))
   `(rainbow-delimiters-unmatched-face ((t :foreground ,red :underline ,red)))

   ;; company
   `(company-tooltip ((t (:foreground ,fg :background ,bg :bold t))))
   `(company-tooltip-selection ((t (:foreground ,fg+ :background ,bg+ :bold t))))
   `(company-scrollbar-bg ((t (:background ,bg))))
   `(company-scrollbar-fg ((t (:background ,fg))))
   `(company-tooltip-common ((t (:foreground ,pink))))

   ;; git-gutter
   `(git-gutter:added ((t :foreground ,cyan)))
   `(git-gutter:changed ((t :foreground ,orange)))
   `(git-gutter:deleted ((t :foreground ,red)))

   ;; RJSX mode
   `(rjsx-attr ((t :foreground ,orange :inherit italic)))
   `(rjsx-tag ((t :foreground ,red)))
   )

  (custom-theme-set-variables
   'panda
   `(ansi-color-names-vector
     [,bg ,red ,purple ,orange ,blue ,pink ,cyan ,fg])))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'panda)

;;; panda-theme.el ends here
