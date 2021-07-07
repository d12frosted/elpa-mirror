;;; darcula-theme.el --- Inspired by IntelliJ's Darcula theme

;; Copyright (C) 2014  Sam Halliday

;; Author: Sam Halliday <Sam.Halliday@gmail.com>
;; Keywords: faces
;; Package-Version: 20171227.1845
;; Package-Commit: d9b82b58ded9014985be6658f4ab17e26ed9e93e
;; URL: https://gitlab.com/fommil/emacs-darcula-theme

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

;;; Code:

(deftheme darcula
  "Inspired by IntelliJ's Darcula theme")

;; NOTE: https://github.com/alezost/alect-themes/#emacs-2431-and-earlier
(when (version< emacs-version "24.4")
  (progn
    ;; WORKAROUND https://github.com/alezost/alect-themes/#emacs-2431-and-earlier
    (defun face-spec-recalc-new (face frame)
      "Improved version of `face-spec-recalc'."
      (while (get face 'face-alias)
        (setq face (get face 'face-alias)))
      (face-spec-reset-face face frame)
      (let ((theme-faces (get face 'theme-face)))
        (if theme-faces
            (dolist (spec (reverse theme-faces))
              (face-spec-set-2 face frame (cadr spec)))
          (face-spec-set-2 face frame (face-default-spec face))))
      (face-spec-set-2 face frame (get face 'face-override-spec)))
    (defadvice face-spec-recalc (around new-recalc (face frame) activate)
      "Use `face-spec-recalc-new' instead."
      (face-spec-recalc-new face frame))))

;; "C-u C-x =" useful for inspecting misbehaving faces.
;; "M-x list-faces-display" useful for listing everything that new major modes introduce.

(defcustom darcula-background
  "#2B2B2B"
  "Background colour for darcula-theme.")

(custom-theme-set-variables
 'darcula
 '(ensime-sem-high-faces
   ;; NOTE: Inconsolata doesn't have italics
   ;; FURTHER NOTE: these are overlays, not faces
   '((var . (:foreground "#9876aa" :underline (:style wave :color "yellow")))
     (val . (:foreground "#9876aa"))
     (varField . (:slant italic))
     (valField . (:foreground "#9876aa" :slant italic))
     (functionCall . (:foreground "#a9b7c6"))
     (implicitConversion . (:underline (:color "#808080")))
     (implicitParams . (:underline (:color "#808080")))
     (operator . (:foreground "#cc7832"))
     (param . (:foreground "#a9b7c6"))
     (class . (:foreground "#4e807d"))
     (trait . (:foreground "#4e807d" :slant italic))
     (object . (:foreground "#6897bb" :slant italic))
     (package . (:foreground "#cc7832"))
     (deprecated . (:strike-through "#a9b7c6"))
     )))

(custom-theme-set-faces
 'darcula
 `(default ((t (:inherit nil :stipple nil :background ,darcula-background :foreground "#a9b7c6"
                         :inverse-video nil :box nil :strike-through nil :overline nil
                         :underline nil :slant normal :weight normal
                         :width normal :foundry nil))))
 '(cursor ((t (:foreground "#042028" :background "#708183"))))
 '(error ((t (:inherit 'default :underline (:style wave :color "red")))))
 '(compilation-error ((t (:inherit 'default :foreground "red" :underline "red"))))
 '(scala-font-lock:var-face ((t (:foreground "#9876aa" :underline (:style wave :color "yellow") :inherit 'font-lock-variable-name-face))))
 '(sbt:error ((t (:inherit 'default :foreground "red"))))
 '(maker:error ((t (:inherit 'default :foreground "red"))))
 '(ensime-warnline-highlight ((t (:inherit 'font-lock-warning-face))))
 '(ensime-compile-infoline ((t (:foreground "#404040" :inherit 'default))))
 ;; http://www.gnu.org/software/emacs/manual/html_node/elisp/Faces-for-Font-Lock.html
 '(font-lock-warning-face ((t (:underline (:style wave :color "orange" :inherit 'default)))))
                                        ;for a construct that is peculiar, or that greatly changes the meaning of other text.
 '(font-lock-function-name-face ((t (:foreground "#fec66c" :inherit 'default))))
                                        ;for the name of a function being defined or declared.
 '(font-lock-variable-name-face ((t (:inherit 'default))))
                                        ;for the name of a variable being defined or declared.
 '(font-lock-keyword-face ((t (:foreground "#cc7832" :inherit 'default))))
                                        ;for a keyword with special syntactic significance, like ‘for’ and ‘if’ in C.
 '(font-lock-comment-face ((t (:foreground "#808080" :inherit 'default))))
                                        ;for comments.
 '(font-lock-comment-delimiter-face ((t (:inherit 'font-lock-comment-face))))
                                        ;for comments delimiters, like ‘/*’ and ‘*/’ in C.
 '(font-lock-type-face ((t (:foreground "#4e807d" :inherit 'default))))
                                        ;for the names of user-defined data types.
 '(font-lock-constant-face ((t (:foreground "#6897bb" :weight bold :inherit 'font-lock-variable-name-face))))
                                        ;for the names of constants, like ‘NULL’ in C.
 '(font-lock-builtin-face ((t (:inherit 'font-lock-keyword-face))))
                                        ;for the names of built-in functions.
 '(font-lock-preprocessor-face ((t (:inherit 'font-lock-builtin-face))))
                                        ;for preprocessor commands.
 '(font-lock-string-face ((t (:foreground "#a6c25c" :inherit 'default))))
                                        ;for string constants.
 '(font-lock-doc-face ((t (:foreground "#629755" :inherit 'font-lock-comment-face))))
                                        ;for documentation strings in the code.
 '(font-lock-negation-char-face ((t (:underline (:color foreground-color :style line) :inherit 'default))))
                                        ;for easily-overlooked negation characters.
 '(flymake-errline ((t (:inherit 'error))))
 '(flymake-warnline ((t (:inherit 'warning))))
 '(escape-glyph ((((background dark)) (:foreground "cyan")) (((type pc)) (:foreground "magenta")) (t (:foreground "brown"))))
 '(minibuffer-prompt ((t (:weight bold :slant normal :underline nil :inverse-video nil :foreground "#259185"))))
 '(highlight ((t (:background "#0a2832"))))
 '(region ((t (:weight normal :slant normal :underline nil :inverse-video t :foreground "#465a61" :background "#042028"))))
 '(shadow ((t (:foreground "#465a61"))))
 '(secondary-selection ((t (:background "#0a2832"))))
 '(trailing-whitespace ((t (:weight normal :slant normal :underline nil :inverse-video t :foreground "#c60007" :background "red1"))))
 '(button ((t (:inherit (link)))))
 '(link ((t (:weight normal :slant normal :underline (:color foreground-color :style line) :inverse-video nil :foreground "#5859b7"))))
 '(link-visited ((t (:weight normal :slant normal :underline (:color foreground-color :style line) :inverse-video nil :foreground "#c61b6e" :inherit (link)))))
 '(fringe ((t (:background nil :foreground nil))))
 '(header-line ((t (:weight normal :slant normal :underline nil :box nil :inverse-video t :foreground "#708183" :background "#0a2832" :inherit (mode-line)))))
 '(tooltip ((((class color)) (:foreground "black" :background "lightyellow"))))
 '(mode-line ((t (:weight normal :slant normal :underline nil :box nil :inverse-video t :foreground "#3c3f41" :background "#a9b7c6"))))
 '(mode-line-inactive ((t (:weight normal :slant normal :underline nil :box nil :inverse-video t :foreground "#3c3f41" :background "#313335" :inherit (mode-line)))))
 '(mode-line-buffer-id ((t (:weight bold))))
 '(mode-line-emphasis ((t (:weight bold))))
 '(mode-line-highlight ((((class color) (min-colors 88))) (t (:inherit (highlight)))))
 '(popup-menu-face ((t (:inherit 'mode-line))))
 '(popup-menu-selection-face ((t (:inherit 'highlight))))
 '(popup-face ((t (:inherit 'mode-line))))
 '(popup-menu-summary-face ((t (:inherit 'mode-line :weight bold))))
 '(popup-summary-face ((t (:inherit 'mode-line :weight bold))))
 '(ac-candidate-face ((t (:inherit 'mode-line))))
 '(ac-selection-face ((t (:inherit 'highlight))))
 '(company-tooltip ((t (:inherit 'mode-line))))
 '(company-scrollbar-bg ((t (:inherit 'mode-line-inactive))))
 '(company-scrollbar-fg ((t (:inherit 'tooltip))))
 '(company-tooltip-selection ((t (:inherit 'highlight))))
 '(company-tooltip-common ((t (:inherit 'mode-line-emphasis))))
 '(company-tooltip-common-selection ((t (:inherit 'highlight))))
 '(company-tooltip-annotation ((t (:inherit 'mode-line))))
 '(org-code ((t (:inherit 'default))))
 '(org-block ((t (:inherit 'org-code))))
 '(org-verbatim ((t (:foreground "#c9d7e6"))))
 ;; WORKAROUND https://github.com/jrblevin/markdown-mode/issues/273
 `(markdown-code-face ((t (:inherit 'org-code :background ,darcula-background))))
 '(markdown-pre-face ((t (:inherit 'org-verbatim))))
 ;; http://www.gnu.org/software/emacs/manual/html_node/ediff/Highlighting-Difference-Regions.html
 '(ediff-current-diff-A ((t (:background "#3B2B2B"))))
 '(ediff-current-diff-B ((t (:background "#2B3B2B"))))
 '(ediff-current-diff-C ((t (:background "#2B2B3B"))))
 '(ediff-fine-diff-A ((t (:weight ultra-bold :background "#5B2B2B"))))
 '(ediff-fine-diff-B ((t (:weight ultra-bold :background "#2B5B2B"))))
 '(ediff-fine-diff-C ((t (:weight ultra-bold :background "#2B2B5B"))))
 '(ediff-odd-diff-A ((t nil)))
 '(ediff-odd-diff-B ((t (:inherit 'ediff-odd-diff-A))))
 '(ediff-odd-diff-C ((t (:inherit 'ediff-odd-diff-A))))
 '(ediff-even-diff-A ((t nil)))
 '(ediff-even-diff-B ((t (:inherit 'ediff-even-diff-A))))
 '(ediff-even-diff-C ((t (:inherit 'ediff-even-diff-A))))
 '(smerge-mine ((t (:inherit 'ediff-current-diff-A))))
 '(smerge-other ((t (:inherit 'ediff-current-diff-B))))
 '(smerge-refined-removed ((t (:inherit 'ediff-fine-diff-A))))
 '(smerge-refined-added ((t (:inherit 'ediff-fine-diff-B))))
 '(smerge-markers ((t (:inherit 'font-lock-comment-face))))
 '(git-gutter:modified ((t (:foreground "#9876aa"))))
 '(git-gutter:added ((t (:foreground "#629755"))))
 '(git-gutter:deleted ((t (:foreground "#cc7832"))))
 '(ido-subdir ((t (:inherit 'font-lock-string-face))))
 '(isearch ((t (:weight normal :slant normal :underline nil :inverse-video t :foreground "#bd3612" :background "#042028"))))
 '(isearch-fail ((t (:weight normal :slant normal :underline nil :inverse-video t :foreground "#bd3612" :background "#042028"))))
 '(font-latex-sectioning-5-face ((t (:foreground "#9876aa"))))
 '(lazy-highlight ((t (:weight normal :slant normal :underline nil :inverse-video t :foreground "#a57705" :background "#042028"))))
 '(compilation-info ((t (:weight bold :foreground "#a6c25c" :underline nil))))
 '(match ((((class color) (min-colors 88) (background light)) (:background "yellow1"))
          (((class color) (min-colors 88) (background dark)) (:background "RoyalBlue3"))
          (((class color) (min-colors 8) (background light)) (:foreground "black" :background "yellow"))
          (((class color) (min-colors 8) (background dark)) (:foreground "white" :background "blue"))
          (((type tty) (class mono)) (:inverse-video t)) (t (:background "gray"))))
 '(next-error ((t (:inherit (region)))))
 '(query-replace ((t (:inherit (isearch))))))


;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))


(provide-theme 'darcula)

;;; darcula-theme.el ends here
