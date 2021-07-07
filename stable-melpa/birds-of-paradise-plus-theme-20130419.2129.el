;;; birds-of-paradise-plus-theme.el --- A brown/orange light-on-dark theme for Emacs 24 (deftheme).
;;
;; Copyright (c) 2012 Jim Myhrberg.
;;
;; Author: Jim Myhrberg <contact@jimeh.me>
;; Version: 0.1.1
;; Package-Version: 20130419.2129
;; Package-Commit: bb9f9d4ef7f7872a388ec4eee1253069adcadb6f
;; Keywords: themes
;; URL: https://github.com/jimeh/birds-of-paradise-plus-theme.el
;;
;; This file is not part of GNU Emacs.
;;
;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Credit:
;;
;; The original Birds of Paradise theme was created by Joe Bergantine for
;; Coda: http://joebergantine.com/werkstatt/birds-of-paradise
;;
;; The original Emacs port (birds-of-paradise-theme.el) of Birds of Paradise
;; was created by Paul M. Rodriguez <paulmrodriguez@gmail.com>.
;;
;;; Code:

(deftheme birds-of-paradise-plus
  "Port of the brown-based warm light-on-dark theme by Joe Bergantine.")

(let ((brown-1 "#452E2E") (brown-2 "#865C38") (brown-3 "#4B3330")
                          (brown-4 "#523D2B") (brown-5 "#7D504A")
                          (brown-6 "#392626") (brown-7 "#3E2929")
      (white-1 "#E6E1C4") (white-2 "#E6E1DC") (white-3 "#654D4D")
      (black-1 "#1F1611") (black-2 "#16120E") (black-3 "#000000")
      (gray-1 "#4e4e4e")
      (yellow-1 "#D9D762") (yellow-2 "#EFAC32") (yellow-3 "#EFCB43")
                           (yellow-4 "#EFC232") (yellow-5 "#FFC05C")
      (orange-1 "#EF5D32") (orange-2 "#CC762E") (orange-3 "#C74725")
      (red-1 "#990000") (red-2 "#660000") (red-3 "#CC4232")
                        (red-4 "#BE3250") (red-5 "#D23850")
                        (red-6 "firebrick4") (red-7 "#FF7575")
      (blue-1 "#7DAF9C") (blue-2 "#6C99BB") (blue-3 "#5798AE")
                         (blue-4 "#93C1BC") (blue-5 "#2F33AB")
      (purple-1 "#BB99BB") (purple-2 "#8856D2") (purple-3 "#BE73FD")
      (green-1 "#144212") (green-2 "#8CFF8C"))
  (custom-theme-set-faces
   'birds-of-paradise-plus

   ;; Basics
   `(default ((t (:background ,brown-1 :foreground ,white-1))))
   `(cursor ((t (:foreground ,brown-2 :background ,white-1))))
   `(highlight ((t (:background ,black-1 :foreground ,white-1))))
   `(hl-line ((t (:background ,brown-7))))
   `(region ((t (:background ,brown-4))))
   `(escape-glyph ((t (:foreground ,purple-3))))
   `(minibuffer-prompt ((t (:foreground ,blue-2)))) ;todo

   ;; Font-lock stuff
   `(font-lock-builtin-face ((t (:foreground ,blue-2))))
   `(font-lock-constant-face ((t (:foreground ,blue-2))))
   `(font-lock-comment-face ((t (:italic t :foreground ,brown-2))))
   `(font-lock-doc-face ((t (:foreground ,brown-2))))
   `(font-lock-doc-string-face ((t (:foreground ,brown-2))))
   `(font-lock-function-name-face ((t (:foreground ,yellow-2))))
   `(font-lock-keyword-face ((t (:foreground ,orange-1))))
   `(font-lock-negation-char-face ((t (:foreground ,blue-1))))
   `(font-lock-preprocessor-face ((t (:foreground ,red-4))))
   `(font-lock-string-face ((t (:foreground ,yellow-1))))
   `(font-lock-type-face ((t (:bold t :foreground ,yellow-2))))
   `(font-lock-variable-name-face ((t (:foreground ,blue-1))))
   `(font-lock-warning-face ((t (:background ,red-1 :foreground "white"))))

   ;; UI related
   `(link ((t (:foreground ,yellow-1))))
   `(button ((t (:foreground ,yellow-1 :background ,blue-1 :weight bold :underline t))))
   `(mode-line ((t (:background ,brown-2 :foreground ,white-1))))
   `(mode-line-inactive ((t (:background ,gray-1 :foreground ,white-1))))
   `(vertical-border ((t (:foreground ,brown-4))))
   `(fringe ((t (:background ,brown-7 :foreground ,white-3))))

   ;; Linum
   `(linum ((t (:background ,brown-1 :foreground ,white-3))))

   ;; show-paren
   `(show-paren-match ((t (:background ,brown-5))))
   `(show-paren-mismatch ((t (:inherit font-lock-warning-face))))

   ;; ido
   `(ido-only-match ((t (:foreground ,orange-1))))
   `(ido-subdir ((t (:foreground ,yellow-2))))

   ;; highlight-indentation-mode
   `(highlight-indentation-face ((t (:background ,brown-3))))
   `(highlight-indentation-current-column-face ((t (:background ,brown-4))))

   ;; whitespace-mode
   `(whitespace-empty ((t (:background ,yellow-2))))
   `(whitespace-hspace ((t (:foreground ,brown-4))))
   `(whitespace-indentation ((t (:foreground ,brown-4))))
   `(whitespace-line ((t (:background ,gray-1))))
   `(whitespace-newline ((t (:foreground ,brown-4))))
   `(whitespace-space ((t (:foreground ,brown-4))))
   `(whitespace-space-after-tab ((t (:foreground ,brown-4))))
   `(whitespace-tab ((t (:foreground ,brown-4))))
   `(whitespace-trailing ((t (:background ,red-3))))

   ;; flyspell-mode
   `(flyspell-incorrect ((t (:underline ,red-6))))
   `(flyspell-duplicate ((t (:underline ,red-6))))

   ;; magit
   `(magit-diff-add ((t (:foreground ,green-2))))
   `(magit-diff-del ((t (:foreground ,red-7))))
   `(magit-item-highlight ((t (:background ,brown-6))))

   ;; ECB
   `(ecb-default-highlight-face ((t (:background ,red-1))))

   ;; ElScreen
   `(elscreen-tab-background-face ((t (:background ,brown-3))))
   `(elscreen-tab-control-face ((t (:background ,brown-2 :foreground ,white-1 :underline nil))))
   `(elscreen-tab-current-screen-face ((t (:background ,brown-2 :foreground ,white-1))))
   `(elscreen-tab-other-screen-face ((t (:background ,brown-3 :foreground ,white-1 :underline nil))))

   ;; column-marker-mode
   `(column-marker-1 ((t (:background ,brown-4))))

   ;; Misc.
   `(gnus-group-news-1 ((t (:foreground ,yellow-1 :weight bold))))
   `(gnus-group-news-1-empty ((t (:foreground ,yellow-1))))
   `(gnus-group-news-2 ((t (:foreground ,orange-1 :weight bold))))
   `(gnus-group-news-2-empty ((t (:foreground ,orange-1))))
   `(gnus-group-news-3 ((t (:foreground ,red-3 :weight bold))))
   `(gnus-group-news-3-empty ((t (:foreground ,red-3))))
   `(gnus-group-news-4 ((t (:foreground ,purple-1 :weight bold))))
   `(gnus-group-news-4-empty ((t (:foreground ,purple-1))))
   `(gnus-group-news-5 ((t (:foreground ,blue-1 :weight bold))))
   `(gnus-group-news-5-empty ((t (:foreground ,blue-1))))
   `(gnus-group-news-6 ((t (:foreground ,blue-2 :weight bold))))
   `(gnus-group-news-6-empty ((t (:foreground ,blue-2))))
   `(gnus-group-news-low ((t (:foreground ,brown-2 :italic t))))
   `(gnus-group-news-low-empty ((t (:foreground ,brown-2))))
   `(gnus-group-mail-1 ((t (:foreground ,yellow-1 :weight bold))))
   `(gnus-group-mail-1-empty ((t (:foreground ,yellow-1))))
   `(gnus-group-mail-2 ((t (:foreground ,orange-1 :weight bold))))
   `(gnus-group-mail-2-empty ((t (:foreground ,orange-1 :weight bold))))
   `(gnus-group-mail-3 ((t (:foreground ,red-3 :weight bold))))
   `(gnus-group-mail-3-empty ((t (:foreground ,red-3))))
   `(gnus-group-mail-low ((t (:foreground ,brown-2 :italic t))))
   `(gnus-group-mail-low-empty ((t (:foreground ,brown-2))))
   `(gnus-header-content ((t (:weight normal :foreground ,yellow-1))))
   `(gnus-header-from ((t (:foreground ,yellow-1))))
   `(gnus-header-subject ((t (:foreground ,red-3))))
   `(gnus-header-name ((t (:foreground ,blue-2))))
   `(gnus-header-newsgroups ((t (:foreground ,yellow-2))))
   `(message-header-name ((t (:foreground ,orange-1))))
   `(message-header-cc ((t (:foreground ,brown-2))))
   `(message-header-other ((t (:foreground ,brown-2))))
   `(message-header-subject ((t (:foreground ,white-1))))
   `(message-header-to ((t (:foreground ,white-1))))
   `(message-cited-text ((t (:foreground ,yellow-2))))
   `(message-separator ((t (:foreground ,yellow-2))))
   `(nxml-comment-content ((t (:inherit 'font-lock-comment-face))))
   `(nxml-tag-delimiter ((t (:foreground ,yellow-3))))
   `(nxml-processing-instruction-target ((t (:foreground ,brown-2))))
   `(nxml-entity-ref-delimiter ((t (:foreground ,blue-2))))
   `(nxml-entity-ref-name ((t (:foreground ,blue-2))))
   `(nxml-element-local-name ((t (:foreground ,yellow-3))))
   `(nxml-cdata-section-content ((t (:foreground ,red-3))))
   `(nxml-attribute-local-name ((t (:foreground ,orange-1))))
   `(nxml-attribute-value ((t (:foreground ,yellow-1)))))
  (custom-theme-set-variables
   'birds-of-paradise-plus

   ;; Fill Column Indicator mode
   `(fci-rule-color ,brown-1) ;; renders much brighter for some reason
   `(fci-rule-character-color ,brown-1)

   ;; Misc.
   `(ansi-color-names-vector
     ;; black, red, green, yellow, blue, magenta, cyan, white
     [,black-1 ,red-2 ,green-1 ,yellow-4 ,blue-3 ,purple-3 ,blue-4 ,white-2])
   `(ansi-term-color-vector
     ;; [unspecified "black" "red3" "green3" "yellow3" "blue2" "magenta3" "cyan3" "white"]
     [unspecified ,black-1 ,red-2 ,green-1 ,yellow-4 ,blue-3 ,purple-3 ,blue-4 ,white-2])))


;;;###autoload
(and load-file-name
  (boundp 'custom-theme-load-path)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'birds-of-paradise-plus)

;;; birds-of-paradise-plus-theme.el ends here
