;;; grey-paper-theme.el --- A greyscale theme with look-n-feel of an eink display -*- lexical-binding: t; -*-

;;; Author: Kang-min Liu <gugod@gugod.org>
;;; Version: 1.0.0
;; Package-Version: 20220811.2301
;; Package-Commit: 760e8d26f5b2aeaa56b91bf435e42b1e5d6f69d7
;;; Keywords: faces
;;; URL: https://github.com/gugod/grey-paper-theme
;;; Package-Requires: ((emacs "24.1"))
;;; LICENSE: CC0
;;;   To the extent possible under law, Kang-min Liu has waived all
;;;   copyright and related or neighboring rights to
;;;   grey-paper-theme.el. This work is published from: Taiwan.
;;; SPDX-License-Identifier: CC0-1.0

;;; Commentary:
;;;   Then intention is to make the look-and-feel somewhere similar to eink.

;;; Code:
(deftheme grey-paper
  "A greyscale theme with look-n-feel of an eink display.")

(let ((bg "#d0d1d0")
      (bg-dark "#c0c0c0")
      (fg "#222a33")
      (fg-dark "#111a22")
      (fg-light "#909090")
      (fg-alt "#224022"))

  (custom-theme-set-faces
   'grey-paper
   `(default ((t (:background ,bg :foreground ,fg))))
   `(fringe ((t (:background ,bg :foreground ,fg))))
   `(region ((t (:background ,bg-dark :distant-foreground "ns_selection_,fg_color"))))
   `(link ((t (:foreground ,fg-alt :underline t))))
   `(error ((t (:foreground ,fg-dark :bold t))))
   `(highlight ((t (:foreground ,fg-alt))))

   `(message-header-name ((t (:foreground ,fg-alt))))
   `(message-header-cc ((t (:foreground ,fg-light))))
   `(message-header-to ((t (:foreground ,fg :bold t))))
   `(message-header-newsgroups ((t (:foreground ,fg :bold t))))
   `(message-header-subject ((t (:foreground ,fg :bold t))))
   `(message-header-other ((t (:foreground ,fg-alt))))
   `(message-header-xheader ((t (:foreground ,fg-alt))))

   `(gnus-header-name ((t (:foreground ,fg))))
   `(gnus-header-content ((t (:foreground ,fg))))
   `(gnus-header-from ((t (:foreground ,fg-dark))))
   `(gnus-header-subject ((t (:foreground ,fg-dark))))

   `(font-lock-builtin-face ((t (:foreground ,fg))))
   `(font-lock-comment-face ((t (:foreground ,fg-light))))
   `(font-lock-constant-face ((t (:foreground ,fg-dark))))
   `(font-lock-function-name-face ((t (:foreground ,fg :bold t))))
   `(font-lock-keyword-face ((t (:foreground ,fg))))
   `(font-lock-string-face ((t (:foreground ,fg))))
   `(font-lock-type-face ((t (:foreground ,fg-dark))))
   `(font-lock-variable-name-face ((t (:foreground ,fg))))

   `(cperl-array-face ((t (:background ,bg :foreground ,fg :bold t))))
   `(cperl-hash-face ((t (:background ,bg :foreground ,fg :bold t))))
   `(cperl-nonoverridable-face ((t (:background ,bg :foreground ,fg :bold t))))))


;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'grey-paper)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; grey-paper-theme.el ends here
