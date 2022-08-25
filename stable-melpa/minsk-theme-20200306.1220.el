;;; minsk-theme.el --- Minsk, a theme in deep muted greens -*- lexical-binding: t; -*-

;; Author: Jean Lo <jlpaca@users.noreply.github.com>
;; Version: 0.2
;; Package-Version: 20200306.1220
;; Package-Commit: c924eb90fc2ef53d4c366b752ea8cb5c5b8f87ea
;; Package-Requires: ((emacs "24"))
;; Keywords: theme, faces
;; URL: https://github.com/jlpaca/minsk-theme

;;; Commentary:

;; A low-ish contrast theme on a restricted palette, intended for
;; generic everyday use.  It tries to be almost-monochrome, and most
;; of the time prefers highlighting by font style over by colour,
;; though it isn't excessively strict about wiggling a little in
;; hue-space.

;;; Code:

(deftheme minsk
  "a theme in deep muted greens.")

(let (
      ;; deepest colours
      (b "#0f1414")
      (w "#fefee0")

      ;; background shades
      (bg-0 "#151c1b")
      (bg-1 "#1d2826")
      (bg-2 "#2b3933")
      (bg-3 "#374a3f")

      ;; foreground shades
      (fg-0 "#cdd2a7")
      (fg-1 "#98a883")
      (fg-2 "#78906c")

      ;; monochromes
      (gr-0 "#bcbcbc")
      ;; (gr-1 "#909090")
      (gr-2 "#535353")

      ;; highlights - neutral
      (h-na "#7e9859")
      (h-nb "#cdd67d")

      ;; highlights - red
      (h-ra "#fe2848")
      ;; (h-rb "#ff9cad")
      (h-rc "#552629")

      ;; highlights - green
      (h-ga "#abe500")
      ;; (h-gb "#e8f7d5")
      ;; (h-gc "#3c5122")

      ;; highlights - yellow
      (h-ya "#feae00")
      ;; (h-yb "#fbeabf")
      (h-yc "#553e21")

      ;; highlights - blue
      ;; (h-ba "#00c9d9")
      ;; (h-bb "#93e8f3")
      ;; (h-bc "#194b4c")

      ;; highlights - magenta
      ;; (h-ma "#ffc5eb")
      ;; (h-mb "#fe7bd9")
      ;; (h-mc "#54324e")

      ;; highlights - cyan
      (h-ca "#d6fff5")
      ;; (h-cb "#00ffbb")
      ;; (h-cc "#195a40"))
      )


  (custom-theme-set-faces
   'minsk
   `(default   ((t (:foreground ,fg-0 :background ,bg-0))))

   ;; generic
   `(button           ((t (:foreground ,h-na :underline t))))
   `(cursor           ((t (:invert-video t))))
   `(error            ((t (:foreground ,h-ra :bold t))))
   `(escape-glyph     ((t (:foreground ,h-ca))))
   `(fringe           ((t (:background ,bg-0))))
   `(header-line      ((t (:inherit mode-line))))
   `(highlight        ((t (:foreground ,h-nb :underline t))))
   `(homoglyph        ((t (:foreground ,h-ca))))
   `(region           ((t (:background ,bg-1))))
   `(shadow           ((t (:foreground ,gr-2))))
   `(show-paren-match ((t (:foreground ,bg-0 :background ,h-nb))))
   `(success          ((t (:foreground ,h-ga :bold t))))
   `(tool-bar         ((t (:inherit mode-line))))
   `(tooltip          ((t (:foreground ,w :background ,b))))
   `(trailing-whitespace ((t (:foreground ,h-ra :background ,h-rc))))
   `(warning          ((t (:foreground ,h-ya :bold t))))


   ;; search
   `(isearch        ((t (:foreground ,bg-0 :background ,h-nb))))
   `(isearch-fail   ((t (:foreground ,bg-0 :background ,gr-2))))
   `(lazy-highlight ((t (:foreground ,h-nb :underline t))))

   ;; line numbers
   `(line-number              ((t (:foreground ,bg-3 :bold t))))
   `(line-number-current-line ((t (:foreground ,fg-1 :bold t))))

   ;; links
   `(link         ((t (:foreground ,h-na :underline t))))
   `(link-visited ((t (:foreground ,h-na :underline t))))

   ;; syntax highlighting
   `(font-lock-builtin-face       ((t (:foreground ,fg-1))))
   `(font-lock-comment-face       ((t (:foreground ,fg-2))))
   `(font-lock-constant-face      ((t (:foreground ,h-ra))))
   `(font-lock-doc-face           ((t (:foreground ,fg-2 :slant italic))))
   `(font-lock-function-name-face ((t (:foreground ,w))))
   `(font-lock-keyword-face       ((t (:foreground ,fg-1 :bold t))))
   `(font-lock-string-face        ((t (:foreground ,h-nb))))
   `(font-lock-type-face          ((t (:foreground ,fg-2 :bold t))))
   `(font-lock-variable-name-face ((t (:underline t))))

   ;; mode line
   `(mode-line           ((t (:foreground ,fg-0 :background ,bg-2))))
   `(mode-line-inactive  ((t (:foreground ,fg-2 :background ,bg-1))))
   `(mode-line-highlight ((t (:foreground ,bg-2 :background ,fg-0))))

   ;; minibuffer
   `(minibuffer-prompt ((t (:foreground ,fg-2))))

   ;; customize
   `(custom-button                  ((t (:box (:color ,bg-3) :background ,bg-3))))
   `(custom-button-mouse            ((t (:box (:color ,h-na) :foreground ,bg-0 :background ,h-na))))
   `(custom-button-pressed          ((t (:box (:color ,h-na) :foreground ,h-na))))
   `(custom-button-pressed-unraised ((t (:inherit custom-button-pressed))))
   `(custom-button-unraised         ((t (:inherit custom-button))))
   `(custom-variable-tag            ((t (:foreground ,h-na :bold t))))

   ;; whitespace mode
   `(whitespace-empty       ((t (:background ,h-ya))))
   `(whitespace-hspace      ((t (:foreground ,gr-0 :background ,gr-2))))
   `(whitespace-indentation ((t (:foreground ,h-ya :background ,h-yc :bold t))))
   `(whitespace-line        ((t (:foreground ,h-ra :bold t))))
   `(whitespace-newline     ((t (:foreground ,gr-2))))
   `(whitespace-space       ((t (:foreground ,gr-2 :bold t))))
   `(whitespace-trailing    ((t (:foreground ,h-ra :background ,h-rc :bold t))))

    ;; widgets
   `(widget-field              ((t (:background ,bg-1))))
   `(widget-single-line-field  ((t (:inherit widget-field))))

   ;; helm
   `(helm-candidate-number        ((t (:foreground ,bg-0 :background ,fg-0))))
   `(helm-header-line-left-margin ((t (:foreground ,bg-0 :background ,h-ya))))
   `(helm-match                   ((t (:foreground ,h-ya))))
   `(helm-prefarg                 ((t (:foreground ,h-ga))))
   `(helm-separator               ((t (:foreground ,h-ra))))
   `(helm-selection               ((t (:background ,bg-2))))
   `(helm-source-header           ((t (:foreground ,bg-0 :background ,fg-0))))
   `(helm-visible-mark            ((t (:foreground ,bg-0 :background ,h-ga)))) ))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
	       (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'minsk)
(provide 'minsk-theme)

;;; minsk-theme.el ends here
