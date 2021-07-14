;;; commentary-theme.el ---  A minimal theme with contrasting comments  -*- lexical-binding: t; -*-

;; This file is not part of GNU Emacs.
;; Copyright (C) 2013 Amirreza Ghaderi
;; Copyright (C) 2017-21 Simon Zelazny
;; Authors: Amirreza Ghaderi <amirreza.blog@gmail.com>,
;;          Simon Zelazny <zelazny@mailbox.org>
;; Version: 0.4.1
;; Package-Version: 20210714.1757
;; Package-Commit: a73e1256f667065933e96bd6032c463cb115201d
;; URL: https://github.com/pzel/commentary-theme
;; Package-Requires: ((emacs "24"))

;;; Commentary:

;; This is a high-contrast theme designed to accentuate three visual 'layers':
;;
;; 1) Comments are in red.  The intent is for comments to stand out!
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

(let* ((black        "#000000")
       (light-gray   "#eeeeee")
       (medium-gray  "#dadada")
       (light-yellow "#ffffdf")
       (dark-yellow  "#dcdca9")
       (red          "#d70000")

       (cursor-background black)
       (fringe-background light-gray)
       (highlight-background light-yellow)
       (region-background dark-yellow)

       (default-layer `((t (:foreground ,black :background ,(face-attribute 'default :background)))))
       (commentary-layer `((t (:foreground ,red :background ,(face-attribute 'default :background)))))
       (string-layer `((t (:foreground ,black :background ,light-yellow))))
       (bold-layer `((t (:foreground ,black :weight bold)))))

  ;; Set faces
  (custom-theme-set-faces
   'commentary
   `(default ,default-layer)
   `(cursor  ((t (:background ,cursor-background))))

   ;; Highlighting
   `(fringe    ((t (:background ,fringe-background))))
   `(highlight ((t (:background ,highlight-background))))
   `(region    ((t (:background ,region-background))))

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
     ((t (:foreground ,red :background ,light-gray :weight bold))))
   `(show-paren-match
     ((t (:foreground ,black  :background ,dark-yellow :weight bold))))

   ;; Line numbers, current line, mode-line
   `(hl-line      ((t (:background ,dark-yellow))))  ;;current line
   `(linum        ((t (:background ,medium-gray))))    ;;line numbers

   ;;; Coloring for other major modes
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
