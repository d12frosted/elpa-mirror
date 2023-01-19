;;; hyperlist-mode.el --- A major-mode for viewing Hyperlists   -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Wojciech Siewierski

;; Author: Wojciech Siewierski
;; URL: https://github.com/vifon/hyperlist-mode
;; Package-Version: 20230119.28
;; Package-Commit: 480dbf33ca72e7b5fade952aaf0d5a5eb43acb1d
;; Keywords: outlines
;; Version: 0.9
;; Package-Requires: ((emacs "24"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A major-mode for viewing Hyperlists by Geir Isene.
;;
;; See: https://isene.org/hyperlist/

;;; Code:

(defgroup hyperlist nil
  "Hyperlist mode."
  :group 'outlines)

(defgroup hyperlist-faces nil
  "Faces in Hyperlist mode."
  :group 'hyperlist)

(defface hyperlist-toplevel
  '((t :inherit bold))
  "Face for the Hyperlist toplevel headings.")

(defface hyperlist-condition
  '((((background light)) :foreground "#008000")
    (((background dark))  :foreground "#33a333"))
  "Face for the Hyperlist [conditions].")

(defface hyperlist-operator
  '((((background light)) :foreground "#000080")
    (((background dark))  :foreground "#8C8CFF"))
  "Face for the Hyperlist OPERATORS: (capitals + colon).")

(defface hyperlist-tag
  '((((background light)) :foreground "#800000")
    (((background dark))  :foreground "#ff7777"))
  "Face for the Hyperlist tags: (string + colon).")

(defface hyperlist-hashtag
  '((((background light)) :foreground "#999900")
    (((background dark))  :foreground "#dddd00"))
  "Face for the Hyperlist #hashtags.")

(defface hyperlist-quote
  '((((background light)) :foreground "#006666")
    (((background dark))  :foreground "#33aaaa"))
  "Face for the Hyperlist \"quotes\".")

(defface hyperlist-paren
  '((t :inherit hyperlist-quote))
  "Face for the Hyperlist (parens).")

(defface hyperlist-ref
  '((((background light)) :foreground "#660066")
    (((background dark))  :foreground "#dd00dd"))
  "Face for the Hyperlist (parens).")

(defface hyperlist-stars
  '((((background light)) :foreground "#ddd")
    (((background dark))  :foreground "#444"))
  "Face for the leading outline stars in Hyperlists.")

(defvar hyperlist-mode-font-lock-keywords
  '(("^\\*\\([^*].*\\)" 1 'hyperlist-toplevel)
    ("\\[[^]]*\\]" . 'hyperlist-condition)
    ("\"[^\"]*\"" . 'hyperlist-quote)
    ("([^)]*)" . 'hyperlist-paren)
    ("<[^>]*>" . 'hyperlist-ref)
    ("\\b[A-Z]+:" . 'hyperlist-operator)
    ("^\\** *\\(?:\\[[^]]*\\] *\\)?\\(\\(?:\\w\\| \\)+\\w:\\)" 1 'hyperlist-tag)
    ("\\_<\\(#\\w+\\)\\_>" 1 'hyperlist-hashtag)
    ("^\\*+" . 'hyperlist-stars)
    ("\\W\\(\\*.*\\*\\)\\W" 1 'bold)
    ("\\W\\(/.*/\\)\\W" 1 'italic)
    ("\\W\\(_.*_\\)\\W" 1 'underline)))

(defvar hyperlist-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\( "()" st)
    (modify-syntax-entry ?\) ")(" st)
    (modify-syntax-entry ?\< "(>" st)
    (modify-syntax-entry ?\> ")<" st)
    (modify-syntax-entry ?# "_ p" st)
    st))

(define-derived-mode hyperlist-mode outline-mode "Hyperlist"
  "A major-mode for Hyperlists by Geir Isene."
  (setq font-lock-defaults
        '(hyperlist-mode-font-lock-keywords
          t)))

(add-to-list 'auto-mode-alist '("\\.hl\\'" . hyperlist-mode))

(provide 'hyperlist-mode)
;;; hyperlist-mode.el ends here
