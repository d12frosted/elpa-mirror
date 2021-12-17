;;; horizon-theme.el ---  A beautifully warm dual theme -*- lexical-binding: t; -*-

;; This file is not part of GNU Emacs.
;; Copyright (C) 2019-2020 Aodnait Étaín
;; Authors: Aodnait Étaín <aodhneine@tuta.io>
;; Version: 0.1.5
;; Package-Version: 20200720.1832
;; Package-Commit: 9595549c514a9376c61d5d303405f6a6982e9e46
;; URL: https://github.com/aodhneine/horizon-theme.el
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:
;; This theme is based on its namesake, Horizon theme for Visual Studio Code,
;; which can be find here: https://horizontheme.netlify.com/.

;;; Credits:
;; Thanks to author of the original theme, jolaleye at https://github.com/jolaleye.
;; Huge thanks to rexim, https://github.com/rexim/gruber-darker-theme for
;; creating simple theme on which I based this implementation. <3

;;; License:
;; This project is licensed under MIT License.

;;; Code:

(deftheme horizon
  "A beautifully warm dual theme for Emacs")

(defun horizon-theme-join-colour (r g b)
  "Build a color from R G B.
Inverse of `color-values'."
  (format "#%02x%02x%02x"
          (ash r -8)
          (ash g -8)
          (ash b -8)))

(defun horizon-theme-blend-colours (c1 c2 &optional alpha)
  "Blend the two colors C1 and C2 with ALPHA.
C1 and C2 are in the format of `color-values'.
ALPHA is a number between 0.0 and 1.0 which corresponds to the
influence of C1 on the result."
  (let ((alpha (or alpha 0.5))
        (c1 (color-values c1))
        (c2 (color-values c2)))
    (apply #'horizon-theme-join-colour
           (cl-mapcar
            (lambda (x y)
              (round (+ (* x alpha) (* y (- 1 alpha)))))
            c1 c2))))

(let* (;; syntax
       (lavender "#B877DB")
       (cranberry "#E95678")
       (turquoise "#25B0BC")
       (apricot "#F09483")
       (rosebud "#FAB795")
       ;; (tacao "#FAC29A")
       (grey "#6a6a6a")
       ;; ui
       (shadow "#16161C")
       (border "#1A1C23")
       (background "#1C1E26")
       (background-alt "#232530")
       (accent "#2E303E")
       (accent-alt "#6C6F93")
       ;; (secondary-accent "#E9436D")
       (secondary-accent-alt "#E95378")
       (tertiary-accent "#FAB38E")
       (positive "#09F7A0")
       (negative "#F43E5C")
       (warning "#27D797")
       (modified "#21BFC2")
       (light-text "#D5D8DA")
       (dark-text "#06060C")
       (foreground (horizon-theme-blend-colours light-text "#808080"))
       ;; ansi
       (blue "#3FC4DE")
       (cyan "#6BE4E6")
       (green "#3FDAA4")
       (magenta "#F075B5")
       (red "#EC6A88")
       (yellow "#FBC3A7"))
  (custom-theme-set-faces
   'horizon
   `(default ((t (:foreground ,foreground :background ,background))))
   ;; miscellanous
   `(region ((t :background ,(horizon-theme-blend-colours accent "#1A1A1A"))))
   `(highlight ((t (:background ,(horizon-theme-blend-colours accent-alt "#1A1A1A")))))
   `(cursor ((t (:background ,secondary-accent-alt :foreground ,background))))
   `(fringe ((t :foreground ,background-alt)))
   `(show-paren-match-face ((t :foreground ,foreground :background ,accent-alt)))
   `(show-paren-match ((t (:foreground ,foreground :background ,(horizon-theme-blend-colours accent-alt background)))))
   `(show-paren-mismatch ((t (:background ,warning))))
   `(match ((t :foreground ,foreground :background ,(horizon-theme-blend-colours accent-alt "#4D4D4D"))))
   `(lazy-highlight ((t :foreground ,foreground :background ,(horizon-theme-blend-colours accent-alt "#000000"))))
   `(minibuffer-prompt ((t :foreground ,lavender)))
   `(shadow ((t :foreground ,shadow)))
   `(vertical-border ((t :foreground ,border)))
   `(success ((t :foreground ,turquoise)))
   `(warning ((t :foreground ,warning)))
   `(error ((t :foreground ,cranberry)))
   `(trailing-whitespace ((t :foreground ,turquoise :background ,turquoise)))
   `(link ((t :foreground ,apricot :underline t)))
   `(line-number ((t :foreground ,(horizon-theme-blend-colours light-text "#1A1A1A") :background ,background)))
   `(line-number-current-line ((t :foreground ,(horizon-theme-blend-colours light-text "#808080") :background ,background)))
   ;; font-lock faces
   `(font-lock-builtin-face ((t :foreground ,lavender)))
   `(font-lock-comment-face ((t :foreground ,grey)))
   `(font-lock-constant-face ((t :foreground ,apricot)))
   `(font-lock-doc-face ((t :foreground ,grey)))
   `(font-lock-function-name-face ((t :foreground ,turquoise)))
   `(font-lock-keyword-face ((t :foreground ,lavender)))
   `(font-lock-negation-char-face ((t :foreground ,lavender)))
   `(font-lock-preprocessor-face ((t :foreground ,lavender)))
   `(font-lock-reference-face ((t: :foreground ,rosebud)))
   `(font-lock-string-face ((t :foreground ,rosebud)))
   `(font-lock-type-face ((t :foreground ,apricot)))
   `(font-lock-variable-name-face ((t :foreground ,cranberry)))
   `(font-lock-warning-face ((t :foreground ,warning)))
   ;; diff
   `(diff-added ((t :foreground ,positive)))
   `(diff-removed ((t :foreground ,negative)))
   `(diff-changed ((t :foreground ,modified)))
   `(diff-refine-added ((t :background ,positive :foreground ,dark-text)))
   `(diff-refine-removed ((t :background ,negative :foreground ,dark-text)))
   `(diff-refine-changed ((t :background ,modified :foreground ,dark-text)))
   `(diff-header ((t :foreground ,lavender)))
   `(diff-file-header ((t :background ,lavender :foreground ,dark-text)))
   ;; isearch
   `(isearch ((t :foreground ,foreground :background ,accent)))
   `(isearch-lazy-highlight-face ((t :inherit lazy-highlight)))
   `(isearch-fail ((t :foreground ,background :background ,cranberry)))
   ;; mode-line
   `(mode-line ((t :background ,background-alt :foreground ,(horizon-theme-blend-colours light-text "#808080"))))
   `(mode-line-buffer-id ((t :foreground ,foreground :bold t)))
   `(mode-line-inactive ((t :foreground ,(horizon-theme-blend-colours foreground accent) :background ,background)))
   ;; markdown
   `(markdown-header-face-1 ((t :foreground ,secondary-accent-alt)))
   `(markdown-header-face-2 ((t :foreground ,secondary-accent-alt)))
   `(markdown-header-face-3 ((t :foreground ,secondary-accent-alt)))
   `(markdown-header-face-4 ((t :foreground ,secondary-accent-alt)))
   `(markdown-header-face-5 ((t :foreground ,secondary-accent-alt)))
   `(markdown-header-face-6 ((t :foreground ,secondary-accent-alt)))
   `(markdown-header-delimiter-face ((t :foreground ,secondary-accent-alt)))
   `(markdown-markup-face ((t :foreground ,light-text)))
   `(markdown-link-face ((t :foreground ,apricot)))
   `(markdown-url-face ((t :foreground ,tertiary-accent :underline t)))
   `(markdown-bold-face ((t :foreground ,lavender :bold t)))
   `(markdown-italic-face ((t :foreground ,turquoise :italic t)))
   ;; company
   `(company-tooltip ((t :inherit region)))
   `(company-tooltip-selection ((t :background ,accent :foreground)))
   `(company-tooltip-common ((t :foreground ,red :bold t)))
   `(company-tooltip-annotation ((t :foreground ,(horizon-theme-blend-colours light-text "#404040"))))
   `(company-scrollbar-bg ((t :inherit region)))
   `(company-scrollbar-fg ((t :background ,accent)))
   `(company-preview ((t :foreground ,lavender)))
   `(company-preview-common ((t :foreground ,lavender :background ,accent)))
   ;; org mode
   `(org-headline-done ((t :foreground ,green)))
   `(org-headline-todo ((t :foreground ,yellow)))
   `(org-level-1 ((t :foreground ,lavender)))
   `(org-level-2 ((t :foreground ,rosebud)))
   `(org-level-3 ((t :foreground ,turquoise)))
   `(org-level-4 ((t :foreground ,(horizon-theme-blend-colours cranberry "#ffffff" 0.5))))
   `(org-level-5 ((t :foreground ,(horizon-theme-blend-colours turquoise "#ffffff" 0.5))))
   `(org-level-6 ((t :foreground ,(horizon-theme-blend-colours rosebud "#ffffff" 0.5))))
   `(org-level-7 ((t :foreground ,(horizon-theme-blend-colours lavender "#ffffff" 0.75))))
   `(org-level-8 ((t :foreground ,light-text)))
   `(org-document-info-keyword ((t :foreground ,grey)))
   ;; vterm
   `(vterm-color-default ((t :foreground ,foreground)))
   `(vterm-color-black ((t :foreground "#16161C")))
   `(vterm-color-red ((t :foreground ,red)))
   `(vterm-color-green ((t :foreground ,green)))
   `(vterm-color-yellow ((t :foreground ,yellow)))
   `(vterm-color-blue ((t :foreground ,blue)))
   `(vterm-color-magenta ((t :foreground ,magenta)))
   `(vterm-color-cyan ((t :foreground ,cyan)))
   `(vterm-color-white ((t :foreground ,"#FAC29A")))
   ;; magit
   `(magit-branch ((t :foreground ,tertiary-accent)))
   `(magit-diffstat-file-header ((t :inherit diff-file-header)))
   `(magit-diffstat-added ((t :ingerit diff-added)))
   `(magit-diffstat-removed ((t :ingerit diff-removed)))
   `(magit-hash ((t :foreground ,tertiary-accent)))
   `(magit-hunk-heading ((t :foreground ,lavender)))
   `(magit-hunk-heading-highlight ((t :inherity region :foreground ,lavender)))
   `(magit-item-highlight ((t :inherit region)))
   `(magit-log-author ((t :foreground ,lavender)))
   `(magit-process-ng ((t :foreground ,secondary-accent-alt)))
   `(magit-process-ok ((t :foreground ,green)))
   `(magit-section-heading ((t :foreground ,lavender)))
   `(magit-section-highlight ((t :inherit region)))
   ;; evil
   `(evil-ex-substitute-matches ((t :foreground ,red :strike-through t)))
   `(evil-ex-substitute-replacement ((t :foreground ,green)))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'horizon)

(provide 'horizon-theme)

;;; horizon-theme.el ends here
