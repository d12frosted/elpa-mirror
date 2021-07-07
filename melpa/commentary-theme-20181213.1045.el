;;; commentary-theme.el ---  A minimal theme with contrasting comments  -*- lexical-binding: t; -*-

;; This file is not part of GNU Emacs.
;; Copyright (C) 2013 Amirreza Ghaderi
;; Copyright (C) 2017-18 Simon Zelazny
;; Authors: Amirreza Ghaderi <amirreza.blog@gmail.com>,
;;          Simon Zelazny <zelazny@mailbox.org>
;; Version: 0.4.0
;; Package-Version: 20181213.1045
;; Package-Commit: dede0f8ecb72156fa6ae81198ea570ead02997ff
;; URL: https://github.com/pzel/commentary-theme
;; Package-Requires: ((emacs "24"))

;;; Commentary:

;; This is a high-contrast theme designed to accentuate three visual 'layers':
;;
;; 1) Comments are in red.  The intent is for comments to stand out!  Use them
;; sparingly, to draw the reader's attention to problematic or tricky code.
;;
;; 2) Strings are furnished with a light yellow background, so it's easier to
;; track where they start and end.
;;
;; 3) Function definitions are in bold.


;;; Credits:

;; This theme is based on minimal-light-theme.el by Amirezza Ghaderi, the
;; original source for which can no loger be found on the Web.


;;; License:
;; Use of this source code is governed by the 'Revised BSD License'
;; which can be found in the LICENSE file.

;;; Code:

(deftheme commentary
  "A minimal theme with contrasting comments")

(let* ((black016  "#000000")
       (white231  "#ffffff")
       (yellow230 "#ffffdf")   ;; background
       (gray243   "#767676")   ;; text, code
       (gray249   "#b2b2b2")   ;; comments
       (gray255   "#eeeeee")   ;; fringe
       (red160    "#d70000")   ;; match
       (blue066   "#5f8787")   ;; strings
       (gray253   "#dadada")
       (soapy     "#eaffff")
       (strawberry "#f2e6e4")
       (yellow187 "#dfdfaf")   ;; current line (unused)
       (default-layer `((t (:foreground ,black016)))) ;; :background ,white231))))
       (commentary-layer `((t (:foreground ,red160)))) ;; :background ,white231))))
       (string-layer `((t (:foreground ,black016 :background ,yellow230))))
       (bold-layer `((t (:foreground ,black016 :weight bold))))
      )


  ;; Set faces
  (custom-theme-set-faces
   'commentary

   `(default ,default-layer)
   `(cursor  ((t (:background ,black016))))

   ;; Highlighting
   `(fringe    ((t (:background ,gray255))))
   `(highlight ((t (:background ,white231))))
   `(region    ((t (:background ,yellow187))))

   ;; Comments, documentation are contrastive
   `(font-lock-comment-face ,commentary-layer)
   `(font-lock-doc-face ,commentary-layer)

   ;; String literals are highlighted
   `(font-lock-string-face ,string-layer)

   ;; Defintions are set in bold
   `(font-lock-function-name-face ,bold-layer)

   ;; Everything else belongs in the normal layer
   `(font-lock-constant-face      ,default-layer)
   `(font-lock-variable-name-face ,default-layer)
   `(font-lock-builtin-face       ,default-layer)
   `(font-lock-keyword-face       ,default-layer)
   `(font-lock-type-face          ,default-layer)

   ;; Parentheses
   `(show-paren-mismatch
     ((t (:foreground ,blue066 :background ,gray255 :weight bold))))
   `(show-paren-match
     ((t (:foreground ,red160  :background ,gray255 :weight bold))))

   ;; Line numbers, current line, mode-line
   `(hl-line      ((t (:background ,yellow187))))  ;;current line
   `(linum        ((t (:background ,gray253))))    ;;line numbers

   ;; Coloring for external modes
   ;; Elixir-mode
   `(elixir-attribute-face ,default-layer)
   `(elixir-atom-face ,default-layer)

   )

  ;; Set variables
  (custom-theme-set-variables 'commentary)
)

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory
                (file-name-directory load-file-name))))

(provide-theme 'commentary)
(provide 'commentary-theme)

;; Local Variables:
;; ----no-byte-compile: t
;; End:
;;; commentary-theme.el ends here
