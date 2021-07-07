;;; panda-theme.el --- Panda Theme

;; Copyright 2018-present, all rights reserved.
;;
;; Code licensed under MIT licence.

;; Author: jamiecollinson <jamiecollinson@gmail.com>
;; Version: 0.1
;; Package-Version: 20181128.1738
;; Package-Commit: 60aa47c7a930377807da0d601351ad91e8ca446a
;; Package-Requires: ((emacs "24"))
;; URL: https://github.com/jamiecollinson/emacs-panda-theme

;;; Commentary:

;; A Superminimal, dark Syntax Theme for Editors, IDEs, Terminal.
;; Color scheme from http://panda.siamak.work

;;; Code:

(deftheme panda
  "A Superminimal, dark Syntax Theme")

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

   ;; magit
   `(magit-branch ((t (:foreground ,cyan :weight bold))))
   `(magit-diff-context-highlight ((t (:background ,bg+))))
   `(magit-diff-file-header ((t (:foreground ,pink :box (:color ,pink)))))
   `(magit-diff-added ((t (:foreground ,cyan))))
   `(magit-diff-removed ((t (:foreground ,red))))
   `(magit-diff-added-highlight ((t (:foreground ,cyan :background ,bg+))))
   `(magit-diff-removed-highlight ((t (:foreground ,red :background ,bg+))))
   `(magit-diffstat-added ((t (:foreground ,cyan))))
   `(magit-diffstat-removed ((t (:foreground ,red))))
   `(magit-hash ((t (:foreground ,pink))))
   `(magit-hunk-heading ((t (:foreground ,blue))))
   `(magit-hunk-heading-highlight ((t (:foreground ,blue :background ,bg+))))
   `(magit-item-highlight ((t (:foreground ,pink :background ,bg+))))
   `(magit-log-author ((t (:foreground ,cyan))))
   `(magit-process-ng ((t (:foreground ,orange :weight bold))))
   `(magit-process-ok ((t (:foreground ,cyan :weight bold))))
   `(magit-section-heading ((t (:foreground ,fg :weight bold))))
   `(magit-section-highlight ((t (:background ,bg+))))

   ;; RJSX mode
   `(rjsx-attr ((t :foreground ,orange :inherit italic)))
   `(rjsx-tag ((t :foreground ,red)))

   ;; Org mode
   `(org-level-1 ((t :foreground ,orange)))
   `(org-level-2 ((t :foreground ,purple)))
   `(org-level-3 ((t :foreground ,blue)))
   `(org-level-4 ((t :foreground ,pink)))
   `(org-level-5 ((t :foreground ,cyan)))
   `(org-level-6 ((t :foreground ,purple)))
   `(org-level-7 ((t :foreground ,red)))
   `(org-level-8 ((t :foreground ,blue)))
   `(org-link ((t :foreground ,blue :underline t)))
   `(org-date ((t :foreground ,blue :underline t)))
   `(org-todo ((t :foreground ,cyan :weight bold)))
   `(org-done ((t :foreground ,pink :weight bold)))

   ;; highlight-indentation for modes like yaml
   `(highlight-indentation-face ((t (:background ,bg+))))
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
(provide 'panda-theme)

;;; panda-theme.el ends here
