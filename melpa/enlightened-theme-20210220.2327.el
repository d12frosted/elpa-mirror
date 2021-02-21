;;; enlightened-theme.el --- A theme based on enlightened
;;; SPDX-License-Identifier: FSFAP
;;; Commentary:
;; This package provides an Emacs theme based on `enlightened' for Sublime Text
;;; URL: https://hg.sr.ht/~slondr/enlightened
;; Package-Version: 20210220.2327
;; Package-Commit: 1bfebd8f47e8a8357c9e557cf6e95d7027861e6d
;;; Code:

(deftheme enlightened
  "enlightened-theme - Created by tmtheme-to-deftheme - 2020-05-04 20:51:25 -0400")

(custom-theme-set-variables
 'enlightened)

(custom-theme-set-faces
 'enlightened
 ;; basic theming.

 '(default ((t (:foreground "#F8F8F2" :background "#1b1b1b" ))))
 '(region  ((t (:background "#49483E"))))
 '(cursor  ((t (:background "#00f808"))))

 ;; Temporary defaults
 '(linum                               ((t (:foreground "#474746"  :background "#313130" ))))
 '(fringe                              ((t (                       :background "#313130" ))))

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
 '(header-line                         ((t (:foreground "#EEEEEE"  :background "#444444" :box nil :inherit (mode-line)                 ))))

 '(mode-line-highlight                 ((t (                                             :box nil                                      ))))
 '(mode-line-emphasis                  ((t (                                             :weight bold                                  ))))
 '(mode-line-buffer-id                 ((t (                                             :box nil :weight bold                         ))))

 '(mode-line-inactive                  ((t (:foreground "#d6d6b2"  :background "#313130" :box nil :weight light :inherit (mode-line)   ))))
 '(mode-line                           ((t (:foreground "#f8f8f2"  :background "#313130" :box nil ))))

 '(isearch                             ((t (:foreground "#99ccee"  :background "#444444"                                               ))))
 '(isearch-fail                        ((t (                       :background "#ffaaaa"                                               ))))
 '(lazy-highlight                      ((t (                       :background "#77bbdd"                                               ))))
 '(match                               ((t (                       :background "#3388cc"                                               ))))

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


 '(font-lock-comment-face ((t (:foreground "#616671"  ))))
 '(font-lock-string-face ((t (:foreground "#A6E32D"  ))))
 '(font-lock-builtin-face ((t (:foreground "#ff29a2"  :bold t))))
 '(font-lock-variable-name-face ((t (:foreground "#9CFFFF"  ))))
 '(font-lock-keyword-face ((t (:foreground "#2499DA"  :bold t))))
 '(font-lock-type-face ((t (:foreground "#A6E22E"  :underline t))))
 '(font-lock-function-name-face ((t (:foreground "#3eff9e"  ))))
 '(js3-function-param-face ((t (:foreground "#FD971F"  :italic t))))
 '(js2-function-param ((t (:foreground "#FD971F"  :italic t))))
 '(font-lock-warning-face ((t (:foreground "#F8F8F0" :background "#AE81FF" ))))
 '(diff-removed ((t (:foreground "#F92672"  ))))
 '(diff-added ((t (:foreground "#A6E22E"  ))))
 '(diff-changed ((t (:foreground "#E6DB74"  ))))
 '(font-lock-comment-delimiter-face ((t (:foreground "#616671"  ))))

 ;; Rainbow delimiters
 '(rainbow-delimiters-depth-1-face ((t (:foreground "#b31e71"))))
 '(rainbow-delimiters-depth-2-face ((t (:foreground "#c5217d"))))
 '(rainbow-delimiters-depth-3-face ((t (:foreground "#d62388"))))
 '(rainbow-delimiters-depth-4-face ((t (:foreground "#dd3292"))))
 '(rainbow-delimiters-depth-5-face ((t (:foreground "#e0449c"))))
 '(rainbow-delimiters-depth-6-face ((t (:foreground "#e355a5"))))
 '(rainbow-delimiters-depth-7-face ((t (:foreground "#e667af"))))
 '(rainbow-delimiters-depth-8-face ((t (:foreground "#e979b8"))))
 '(rainbow-delimiters-depth-9-face ((t (:foreground "#ec8bc1"))))
 '(rainbow-delimiters-unmatched-face ((t (:foreground "#FF0000")))))
;; End face definitions

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'enlightened)
(provide 'enlightened-theme)

;;; enlightened-theme.el ends here
