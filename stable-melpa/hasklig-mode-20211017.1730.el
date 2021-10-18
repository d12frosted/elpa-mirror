;;; hasklig-mode.el --- Hasklig ligatures -*- lexical-binding: t -*-
;;
;; Author: Daniel Mendler
;; Created: 2018
;; License: GPL-3.0-or-later
;; Version: 0.2
;; Package-Version: 20211017.1730
;; Package-Commit: 4b73d61f4ef1c73733f7201fbf0b49ba9e3395b6
;; Package-Requires: ((emacs "25"))
;; Homepage: https://github.com/minad/hasklig-mode
;;
;;; Commentary:
;;
;; Minor mode for Hasklig ligatures
;;
;;; Code:

(defun hasklig-mode--make-alist (list)
  "Generate prettify-symbols alist from LIST."
  (let ((idx -1))
    (mapcar
     (lambda (s)
       (setq idx (1+ idx))
       (let* ((code (+ #Xe100 idx))
              (width (string-width s))
              (prefix ())
              (suffix '(?\s (Br . Br)))
              (n 1))
         (while (< n width)
           (setq prefix (append prefix '(?\s (Br . Bl))))
           (setq n (1+ n)))
         (cons s (append prefix suffix (list (decode-char 'ucs code))))))
     list)))

;; Hasklig ligatures. See https://github.com/i-tu/Hasklig/blob/master/GlyphOrderAndAliasDB.
(defconst hasklig-mode--ligatures
  '("&&" "***" "*>" "\\\\" "||" "|>" "::"
    "==" "===" "==>" "=>" "=<<" "!!" ">>"
    ">>=" ">>>" ">>-" ">-" "->" "-<" "-<<"
    "<*" "<*>" "<|" "<|>" "<$>" "<>" "<-"
    "<<" "<<<" "<+>" ".." "..." "++" "+++"
    "/=" ":::" ">=>" "->>" "<=>" "<=<" "<->"))

(defvar hasklig-mode--old-prettify-alist)

(defun hasklig-mode--enable ()
  "Enable Hasklig ligatures in current buffer."
  (setq-local hasklig-mode--old-prettify-alist prettify-symbols-alist)
  (setq-local prettify-symbols-alist (append (hasklig-mode--make-alist hasklig-mode--ligatures) hasklig-mode--old-prettify-alist))
  (prettify-symbols-mode t))

(defun hasklig-mode--disable ()
  "Disable Hasklig ligatures in current buffer."
  (setq-local prettify-symbols-alist hasklig-mode--old-prettify-alist)
  (prettify-symbols-mode -1))

;;;###autoload
(define-minor-mode hasklig-mode
  "Hasklig Ligatures minor mode."
  :lighter " Hasklig"
  (setq-local prettify-symbols-unprettify-at-point 'right-edge)
  (if hasklig-mode
      (hasklig-mode--enable)
      (hasklig-mode--disable)))

(provide 'hasklig-mode)
;;; hasklig-mode.el ends here
