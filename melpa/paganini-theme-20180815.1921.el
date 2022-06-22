;;; paganini-theme.el --- A colorful, dark and warm theme.
;;
;;; Author: Onur Temizkan
;;; Version: 0.13
;; Package-Version: 20180815.1921
;; Package-Commit: 255c5a2a8abee9c5935465ec42b9c3604c178c3c
;;
;;; Url: https://github.com/onurtemizkan/paganini
;;; Package-Requires: ((emacs "24.0"))
;;
;;; Commentary:
;;  A colorful, dark and warm Emacs theme.
;;
;;; Code:

(deftheme paganini
  "paganini-theme - A colorful, dark and warm theme.")

(custom-theme-set-variables
 'paganini
)

(custom-theme-set-faces
 'paganini
 ;; basic theming.

 '(default ((t (:foreground "#F8F8F2" :background "#191919" ))))
 '(region ((t (:background "firebrick" :foreground "gainsboro"))))
 '(cursor ((t (:background "orange red"))))

 ;; Temporary defaults
 '(linum                               ((t (:foreground "#464644"  :background "#2f2f2f" ))))
 '(fringe                              ((t (                       :background "#2f2f2f" ))))

 '(minibuffer-prompt                   ((t (:foreground "#1278A8"  :background nil       :weight bold                                  ))))
 '(escape-glyph                        ((t (:foreground "orange"   :background nil                                                     ))))
 '(highlight                           ((t (:foreground "orange"   :background nil                                                     ))))
 '(shadow                              ((t (:foreground "#777777"  :background nil                                                     ))))

 '(trailing-whitespace                 ((t (:foreground "#FFFFFF"  :background "#C74000"                                               ))))
 '(link                                ((t (:foreground "#00b7f0"  :background nil       :underline t                                  ))))
 '(link-visited                        ((t (:foreground "#4488cc"                        :underline t :inherit (link)                  ))))
 '(button                              ((t (:foreground "#FFFFFF"  :background "#444444" :underline t :inherit (link)                  ))))
 '(next-error                          ((t (                                             :inherit (region)                             ))))
 '(query-replace                       ((t (                                             :inherit (isearch)                            ))))
 '(header-line                         ((t (:foreground "#EEEEEE"  :background "#111111" :box nil :inherit (mode-line)                 ))))

 '(mode-line-highlight                 ((t (                                             :box nil                                      ))))
 '(mode-line-emphasis                  ((t (                                             :weight bold                                  ))))
 '(mode-line-buffer-id                 ((t (:foreground "black" :box nil :weight bold                                                  ))))
 
 '(mode-line-inactive                  ((t (:inherit mode-line :background "dim gray" :foreground "#c6c6c6" :box nil :weight light     ))))
 '(mode-line                           ((t (:background "goldenrod" :foreground "black" :box nil                                       ))))

 '(isearch                             ((t (:foreground "#99ccee"  :background "#444444"                                               ))))
 '(isearch-fail                        ((t (                       :background "#ffaaaa"                                               ))))
 '(lazy-highlight                      ((t (                       :background "#77bbdd"                                               ))))
 '(match                               ((t (                       :background "indian red"                                            ))))

 '(tooltip                             ((t (:foreground "black"    :background "LightYellow" :inherit (variable-pitch)                 ))))

 '(js3-function-param-face             ((t (:foreground "#BFC3A9"                                                                      ))))
 '(js3-external-variable-face          ((t (:foreground "#F0B090"  :bold t                                                             ))))

 '(secondary-selection                 ((t (                       :background "#342858"                                               ))))
 '(cua-rectangle                       ((t (:foreground "#E0E4CC"  :background "#342858" ))))

 ;; Magit hightlight
 '(magit-item-highlight                ((t (:foreground "white" :background "#1278A8" :inherit nil ))))

 ;; flyspell-mode
 '(flyspell-incorrect                  ((t (:underline "#AA0000" :background nil :inherit nil ))))
 '(flyspell-duplicate                  ((t (:underline "#009945" :background nil :inherit nil ))))

 ;; flymake-mode
 '(flymake-errline                     ((t (:underline "#AA0000" :background nil :inherit nil ))))
 '(flymake-warnline                    ((t (:underline "#009945" :background nil :inherit nil ))))

 ;;git-gutter
 '(git-gutter:added                    ((t (:foreground "#609f60" :bold t))))
 '(git-gutter:modified                 ((t (:foreground "#3388cc" :bold t))))
 '(git-gutter:deleted                  ((t (:foreground "#cc3333" :bold t))))

 '(diff-added                          ((t (:background "#305030"))))
 '(diff-removed                        ((t (:background "#903010"))))
 '(diff-file-header                    ((t (:background "#362145"))))
 '(diff-context                        ((t (:foreground "#E0E4CC"))))
 '(diff-changed                        ((t (:foreground "#3388cc"))))
 '(diff-hunk-header                    ((t (:background "#242130"))))

 ;; ecb
 '(ecb-analyse-face ((t (:inherit ecb-default-highlight-face :background "firebrick"))))
 '(ecb-default-highlight-face ((t (:background "forest green"))))

 ;; ensime
 '(ensime-implicit-highlight ((t (:underline (:color "pale green" :style wave)))))

 ;; flycheck
 '(flycheck-error ((t (:underline "dark sea green"))))

 ;; LaTeX
 '(font-latex-sectioning-0-face ((t (:inherit font-latex-sectioning-1-face))))
 '(font-latex-sectioning-1-face ((t (:inherit font-latex-sectioning-2-face))))
 '(font-latex-sectioning-2-face ((t (:inherit font-latex-sectioning-3-face))))
 '(font-latex-sectioning-3-face ((t (:inherit font-latex-sectioning-4-face))))
 '(font-latex-sectioning-4-face ((t (:inherit font-latex-sectioning-5-face))))
 '(font-latex-sectioning-5-face ((t (:foreground "yellow" :weight bold))))
 '(font-latex-slide-title-face ((t (:inherit font-lock-type-face :weight bold))))
 '(font-latex-verbatim-face ((t (:foreground "burlywood"))))

 ;; hl-line
 '(hl-line ((t (:background "#422E39"))))

 ;; popup
 '(popup-face ((t (:background "gray5" :foreground "gainsboro"))))
 '(popup-tip-face ((t (:background "gray15" :foreground "lemon chiffon"))))

 ;; scala
 '(scala-font-lock:var-face ((t (:background "orange" :foreground "black"))))

 ;; paren-match
 '(show-paren-match ((t (:foreground "gainsboro" :slant oblique :weight ultra-bold))))

 ;; vertical-border
 '(vertical-border ((((type x pm tty)) (:background "black" :foreground "dark slate gray"))))

 ;; window-divider
 '(window-divider ((t (:foreground "dark green"))))
 '(window-divider-first-pixel ((t (:foreground "dark green"))))
 '(window-divider-last-pixel ((t (:foreground "medium sea green"))))

 '(italic ((t (:slant italic))))
 '(font-lock-comment-face ((t (:foreground "#6d6d6d"  ))))
 '(font-lock-string-face ((t (:foreground "#3498db"  ))))
 '(font-lock-builtin-face ((t (:foreground "#3498db"))))
 '(font-lock-variable-name-face ((t (:foreground "medium sea green"))))
 '(font-lock-keyword-face ((t (:foreground "#ff8000" :bold t))))
 '(font-lock-type-face ((t (:foreground "#74C365" :bold t))))
 '(font-lock-function-name-face ((t (:foreground "#FFD500" :bold t))))
 '(js3-function-param-face ((t (:foreground "#fc9354"  :italic t))))
 '(js2-function-param ((t (:foreground "#C2B6D6"  :italic t))))
 '(js2-private-function-call-face ((t (:foreground "#028090"))))
 '(js2-function-param-face ((t (:foreground "#028090"))))
 '(js2-jsdoc-value ((t (:foreground "#3498db"))))
 '(js2-jsdoc-html-tag-delimiter ((t (:foreground "#3498db"))))
 '(font-lock-warning-face ((t (:foreground "#F8F8F0" :background "#FF80F4" ))))
 '(font-lock-comment-delimiter-face ((t (:foreground "#6d6d6d"  ))))
 '(font-lock-constant-face ((t (:foreground "#028090"))))
 '(font-lock-negation-char-face ((t (:bold t))))
 '(font-lock-preprocessor-face ((t (:italic t))))
 '(font-lock-regexp-grouping-backslash ((t (:foreground "#3498db"))))
 '(font-lock-regexp-grouping-construct ((t (:foreground "#3498db"))))
)
 ;; End face definitions

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'paganini)

;;; paganini-theme.el ends here
