;;; pixiv-novel-mode.el --- Major mode for pixiv novel

;; Copyright (C) 2014 pixiv

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 19 Dec 2014
;; Version: 0.0.3
;; Package-Version: 20160220.1421
;; Package-Commit: 0d1ca524d92b91f20a7105402a773bc21779b434
;; Keywords: novel pixiv

;; This file is NOT part of GNU Emacs.

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

;; This is a major-mode for editing novel pixiv Novel format.

;;; Code:

(defconst pixiv-novel-syntax-keywords
  (list
   (cons
    (concat
     "\\(\\[\\[\\)"
     "\\(\\rb:\\)"
     "\\([^>]+\\)"
     "\\( > \\)"
     "\\([^>]+\\)"
     "\\(\\]\\]\\)")
    '((1 font-lock-keyword-face)
      (2 font-lock-builtin-face)
      (3 font-lock-variable-name-face)
      (4 font-lock-keyword-face)
      (5 font-lock-string-face)
      (6 font-lock-keyword-face)))
   (cons
    (concat
     "\\(\\[\\)"
     "\\(newpage\\)"
     "\\(\\]\\)")
    '((1 font-lock-keyword-face)
      (2 font-lock-builtin-face)
      (3 font-lock-keyword-face)))
   (cons
    (concat
     "\\(\\[\\)"
     "\\(chapter:\\)"
     "\\([^\]]+\\)"
     "\\(\\]\\)")
    '((1 font-lock-keyword-face)
      (2 font-lock-builtin-face)
      (3 font-lock-function-name-face)
      (4 font-lock-keyword-face)))
   (cons
    (concat
     "\\(\\[\\[\\)"
     "\\(\\jumpuri:\\)"
     "\\([^>]+\\)"
     "\\( > \\)"
     "\\(https?://[^\]]+\\)"
     "\\(\\]\\]\\)")
    '((1 font-lock-keyword-face)
      (2 font-lock-builtin-face)
      (3 font-lock-variable-name-face)
      (4 font-lock-keyword-face)
      (5 font-lock-string-face)
      (6 font-lock-keyword-face)))
   (cons
    (concat
     "\\(\\[\\)"
     "\\(jump:\\)"
     "\\([1-9][0-9]*\\)"
     "\\(\\]\\)")
    '((1 font-lock-keyword-face)
      (2 font-lock-builtin-face)
      (3 font-lock-variable-name-face)
      (4 font-lock-keyword-face)))
   (cons
    (concat
     "\\(\\[\\)"
     "\\(pixivimage:\\)"
     "\\([1-9][0-9]*\\)"
     "\\(\\]\\)")
    '((1 font-lock-keyword-face)
      (2 font-lock-builtin-face)
      (3 font-lock-variable-name-face)
      (4 font-lock-keyword-face)))))

(defvar pixiv-novel-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "C-c C-i n") 'pixiv-novel/insert-newpage)
    (define-key map (kbd "C-c C-i c") 'pixiv-novel/insert-chapter)
    (define-key map (kbd "C-c C-i i") 'pixiv-novel/insert-illustration)
    (define-key map (kbd "C-c C-i p") 'pixiv-novel/insert-jump-page)
    (define-key map (kbd "C-c C-i u") 'pixiv-novel/insert-jump-url)
    map)
  "Keymap for pixiv novel major mode.")

(defun pixiv-novel/insert-newpage ()
  "Insert [newpage] tag."
  (interactive)
  (insert "[newpage]\n"))

(defun pixiv-novel/insert-jump-page (page)
  "Insert [jump] tag that move to `PAGE'."
  (interactive "nPage:")
  (insert (concat "[jump:" (number-to-string page) "]\n")))

(defun pixiv-novel/insert-jump-url (url)
  "Insert [[jumpurl]] tag that referes `URL'."
  (interactive "sURL:")
  (insert (concat "[jump:" url "]\n")))

(defun pixiv-novel/insert-chapter (title)
  "Insert [chapter] tag that named `TITLE'."
  (interactive "sTitle:")
  (insert (concat "[chapter:" title "]\n")))

(defun pixiv-novel/insert-illustration (id-or-url)
  "Insert [pixivimage] tag that insert illustration by `ID-OR-URL'."
  (interactive "spixiv Illustration ID or URL:")
  (insert (concat "[pixivimage:" (pixiv-novel/parse-pixiv-illustration-id id-or-url) "]\n")))

(defun pixiv-novel/parse-pixiv-illustration-id (input)
  "Parse pixiv URL by `INPUT'."
  (string-match "\\([1-9][0-9]*\\)" input)
  (match-string 0 input))

;;;###autoload
(define-derived-mode pixiv-novel-mode text-mode "pixivNovel"
  "Major mode for pixiv novel"
  (setq font-lock-defaults '(pixiv-novel-syntax-keywords)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pxv\\(\\.txt\\)?\\'" . pixiv-novel-mode))

(provide 'pixiv-novel-mode)
;;; pixiv-novel-mode.el ends here
