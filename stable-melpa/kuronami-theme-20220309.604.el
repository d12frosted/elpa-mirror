;;; kuronami-theme.el --- A deep blue theme with cool autumnal colors -*- lexical-binding: t; -*-

;; Author: Eric Chung <>
;; Version: 1.0.0
;; Package-Version: 20220309.604
;; Package-Commit: 910e8fa56a0cfe89dae888522f9fec4045d017fb
;; Filename: kuronami-theme.el
;; Package-Requires: ((emacs "24.1"))
;; URL: https://github.com/super3ggo/kuronami
;; License: GPL-3+
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; An Emacs theme with cool autumnal colors against a deep blue background.
;; Inspired by other Emacs themes - Deeper Blue shipped with most modern
;; versions of GNU Emacs, Gruber Darker by Alexey Kutepov, and Naysayer by
;; Nick Aversano. The character designs of Rei Ayanami and
;; Rei Ayanami (Tentative Name) from the anime Neon Genesis Evangelion by
;; Studio Khara/Gainax provided the main source of inspiration regarding the
;; central ideas behind the colors used in this theme.

;; This theme advocates the oxymoronic minimalist Emacs user. Popular third
;; party packages most likely do not have overwritten colors. Further, many
;; default Faces that Inherit other default Faces do not get overwritten.
;; Generally, only Faces that do not use Inherit have themed coloring though
;; exceptions exist.

;; A total of sixteen colors make up this theme. Eight of them stolen from other
;; Emacs themes or sampled from the Internet using color identifying software.
;; The other eight then derive from a subset of this first half. The website
;; https://www.color-hex.com provided much needed assistance in selecting these
;; derived colors according to the Analogous, Complementary, Triadic, Tint, and
;; Shade properties provided there. This theme's color declarations contain
;; in-line comments, attempting to explain the respective derivation process in
;; addition to crediting sources accordingly.

;;; Code:

(deftheme kuronami
  "Kuronami theme for Emacs. Cool colors against a deep blue background.")

;; NOTE: Kuronami colors with the same name generally have a dark-less-intense
;;       to a light-more-intense arrangement such that the former gets a lower
;;       number and the latter, a higher number. For example, "kuronami-blue-00"
;;       has a darker, less intense blue than "kuronami-blue-01," which has a
;;       lighter, more intense blue.
;;
;;       The author has historically struggled seeing and describing colors the
;;       way others do so please show some leniency if these descriptions do not
;;       make sense.
;;
;;       As mentioned earlier, each color declaration has an in-line comment
;;       describing its origin or derivation.
;;
(let ((kuronami-black-00  "#181a26")  ; Stolen from the Deeper Blue Emacs theme.
      (kuronami-black-01  "#202129")  ; black-02 -> 3 Shades darker.
      (kuronami-black-02  "#2f303b")  ; black-00 -> 1 Tint lighter.
      (kuronami-blue-00   "#2e41ac")  ; Sampled from an image of NGE Unit-00 (blue).
      (kuronami-blue-01   "#7fbbe9")  ; Sampled from official Ayanami Blue!
      (kuronami-blue-02   "#abbfda")  ; yellow-00 -> Complementary #97b0d1 -> 2 Tints lighter.
      (kuronami-gray-00   "#595959")  ; Stolen from Emacs default "gray/grey 35."
      (kuronami-gray-01   "#b3b3b3")  ; Stolen from Emacs default "gray/grey 70."
      (kuronami-green-00  "#708b4c")  ; green-03 -> 4 Shades darker.
      (kuronami-green-01  "#668b8b")  ; Stolen from Emacs default "pale turquoise 4."
      (kuronami-green-02  "#65bab4")  ; blue-01 -> Analogous #7fe9e2 -> 2 Shades darker.
      (kuronami-green-03  "#bbe97f")  ; blue-01 -> Triadic.
      (kuronami-orange-00 "#e9ad7f")  ; blue-01 -> Complementary.
      (kuronami-red-00    "#e97f86")  ; blue-01 -> Triadic #e97fbb -> Analogous.
      (kuronami-white-00  "#fffafa")  ; Stolen from Emacs default "snow."
      (kuronami-yellow-00 "#d1b897")) ; Stolen from the Naysayer Emacs theme.
  (custom-theme-set-faces
   `kuronami

   ;;; Vanilla Faces:

   ;; UI Elements:
   `(cursor              ((t (:background ,kuronami-red-00))))
   `(default             ((t (:background ,kuronami-black-00 :foreground ,kuronami-yellow-00))))
   `(error               ((t (:foreground ,kuronami-red-00 :weight bold))))
   `(fringe              ((t (:background ,kuronami-black-00))))
   `(highlight           ((t (:background ,kuronami-green-00))))
   `(isearch             ((t (:background ,kuronami-red-00 :foreground ,kuronami-black-00))))
   `(lazy-highlight      ((t (:background ,kuronami-green-01))))
   `(line-number         ((t (:foreground ,kuronami-blue-02))))
   `(link                ((t (:foreground ,kuronami-green-02 :bold t :underline t))))
   `(link-visited        ((t (:foreground ,kuronami-yellow-00 :bold t :underline t))))
   `(match               ((t (:inherit lazy-highlight))))
   `(minibuffer-prompt   ((t (:foreground ,kuronami-white-00))))
   `(region              ((t (:extend nil :background ,kuronami-blue-00)))) ; Mark to one past the final non-whitespace character kinda like Vi!
   `(show-paren-match    ((t (:background ,kuronami-blue-02))))
   `(show-paren-mismatch ((t (:background ,kuronami-red-00))))
   `(success             ((t (:foreground ,kuronami-green-03 :weight bold))))
   `(warning             ((t (:foreground ,kuronami-orange-00 :weight bold))))

   ;; Font Lock:
   `(font-lock-builtin-face           ((t (:foreground ,kuronami-white-00))))
   `(font-lock-comment-face           ((t (:foreground ,kuronami-blue-01 :italic t))))
   `(font-lock-comment-delimiter-face ((t (:inherit font-lock-comment-face))))
   `(font-lock-constant-face          ((t (:foreground ,kuronami-orange-00))))
   `(font-lock-doc-face               ((t (:foreground ,kuronami-green-00))))
   `(font-lock-function-name-face     ((t (:foreground ,kuronami-blue-02))))
   `(font-lock-keyword-face           ((t (:inherit font-lock-builtin-face))))
   `(font-lock-negation-char-face     ((t (:foreground ,kuronami-red-00))))
   `(font-lock-preprocessor-face      ((t (:foreground ,kuronami-green-03))))
   `(font-lock-string-face            ((t (:foreground ,kuronami-green-02))))
   `(font-lock-type-face              ((t (:inherit font-lock-constant-face))))
   `(font-lock-variable-name-face     ((t (:inherit font-lock-function-name-face))))
   `(font-lock-warning-face           ((t (:foreground ,kuronami-red-00 :bold t :italic t))))

   ;;; From this point, the Faces get organized alphabetically.

   ;; Compilation:
   `(compilation-column-number  ((t (:foreground ,kuronami-white-00))))
   `(compilation-line-number    ((t (:foreground ,kuronami-blue-02))))
   `(compilation-mode-line-exit ((t (:inherit compilation-info))))
   `(compilation-mode-line-fail ((t (:inherit compilation-error))))

   ;; Completions:
   `(completions-common-part      ((t (:foreground ,kuronami-white-00))))
   `(completions-first-difference ((t (:foreground ,kuronami-orange-00 :bold t))))

   ;; Flyspell:
   `(flyspell-duplicate ((t nil))) ; Setting "flyspell-duplicate-distance" does not work for Emacs 27.2 on macOS x86 so disable the Face. For now.
   `(flyspell-incorrect
     ((((supports :underline (:style wave))) (:underline (:color ,kuronami-red-00 :style wave)))
      (t (:foreground ,kuronami-red-00 :underline t :weight bold)))) ; For terminal Emacsclient.

   ;; Ido:
   `(ido-first-match ((t (:foreground ,kuronami-orange-00 :italic t))))
   `(ido-only-match  ((t (:foreground ,kuronami-green-03 :bold t :italic t))))
   `(ido-subdir      ((t (:foreground ,kuronami-blue-02))))

   ;; Mode Line:
   `(mode-line           ((t (:background ,kuronami-gray-01 :foreground ,kuronami-black-00)))) ; Just colors. No "boxing" effect.
   `(mode-line-buffer-id ((t nil)))
   `(mode-line-emphasis  ((t nil)))
   `(mode-line-inactive  ((t (:background ,kuronami-gray-00 :foreground ,kuronami-gray-01))))

   ;; Org:
   `(org-block ((t (:extend t :background ,kuronami-black-01 :foreground ,kuronami-gray-01))))
   `(org-done  ((t (:foreground ,kuronami-green-03 :weight bold))))
   `(org-table ((t (:foreground ,kuronami-blue-01))))
   `(org-todo  ((t (:foreground ,kuronami-orange-00 :weight bold))))

   ;; Whitespace:
   `(trailing-whitespace         ((t (:inherit whitespace-trailing)))) ; Different from whitespace-trailing? Shrug.
   `(whitespace-empty            ((t (:background ,kuronami-red-00 :foreground ,kuronami-black-02))))
   `(whitespace-hspace           ((t (:background ,kuronami-black-00 :foreground ,kuronami-black-02))))
   `(whitespace-indentation      ((t (:inherit whitespace-empty))))
   `(whitespace-line             ((t (:background ,kuronami-black-00 :foreground ,kuronami-red-00))))
   `(whitespace-newline          ((t (:background ,kuronami-black-00 :foreground ,kuronami-black-02))))
   `(whitespace-space            ((t (:background ,kuronami-black-00 :foreground ,kuronami-black-02))))
   `(whitespace-space-after-tab  ((t (:inherit whitespace-empty))))
   `(whitespace-space-before-tab ((t (:inherit whitespace-empty))))
   `(whitespace-tab              ((t (:background ,kuronami-black-00 :foreground ,kuronami-black-02))))
   `(whitespace-trailing         ((t (:inherit whitespace-empty))))

   ;;; Programming Language Faces:
   ;; Nothing here yet.

   ;;; Third Party Faces:

   ;;; Programming Language Faces:

   ;; Markdown:
   `(markdown-code-face             ((t (:extend t :background ,kuronami-black-01 :foreground ,kuronami-gray-01))))
   `(markdown-language-keyword-face ((t (:foreground ,kuronami-blue-01))))

   ;; Rust:
   `(rust-builtin-formatting-macro ((t (:inherit font-lock-preprocessor-face)))))) ; Macros get one color.

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'kuronami)
(provide 'kuronami-theme)
;;; kuronami-theme.el ends here.
