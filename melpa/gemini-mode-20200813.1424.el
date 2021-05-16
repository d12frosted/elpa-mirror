;;; gemini-mode.el --- A simple highlighting package for text/gemini -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Jason McBrayer

;; Author: Jason McBrayer <jmcbray@carcosa.net>, tastytea <tastytea@tastytea.de>
;; Created: 20 May 2020
;; Version: 0.6.0
;; Package-Version: 20200813.1424
;; Package-Commit: d114bacfb12f9e66821254ff0a1fb85443700b24
;; Keywords: languages
;; Homepage: https://git.carcosa.net/jmcbray/gemini.el
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; This package provides a major mode for editing text/gemini files.
;; Currently, it only provides syntax-highlighting support.

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:
(require 'cl-lib)

(defface gemini-heading-face-1
  '((t :inherit bold :height 1.8))
  "Face for Gemini headings level 1"
  :group 'gemini-mode)
(defface gemini-heading-face-2
  '((t :inherit bold :height 1.4))
  "Face for Gemini headings level 2"
  :group 'gemini-mode)
(defface gemini-heading-face-3
  '((t :inherit bold :height 1.2))
  "Face for Gemini headings level 3"
  :group 'gemini-mode)
(defface gemini-heading-face-rest
  '((t :inherit bold))
  "Face for Gemini headings below level 3"
  :group 'gemini-mode)
(defface gemini-quote-face
  '((t :inherit italic))
  "Face for quoted lines in Gemini"
  :group 'gemini-mode)

(defvar gemini-highlights
  (let* ((gemini-heading-3-regexp "^###\s.*$")
         (gemini-heading-2-regexp "^##\s.*$")
         (gemini-heading-1-regexp "^#\s.*$")
         (gemini-heading-rest-regexp "^###+\s.*$")
         (gemini-link-regexp "^=>.*$")
         (gemini-ulist-regexp "^\\* .*$")
         (gemini-preformatted-regexp "^```")
         (gemini-quote-regexp "^> .*$"))
    `((,gemini-heading-rest-regexp . 'gemini-heading-face-rest)
      (,gemini-heading-3-regexp . 'gemini-heading-face-3)
      (,gemini-heading-2-regexp . 'gemini-heading-face-2)
      (,gemini-heading-1-regexp . 'gemini-heading-face-1)
      (,gemini-link-regexp . 'link)
      (,gemini-ulist-regexp . 'font-lock-keyword-face)
      (,gemini-preformatted-regexp . 'font-lock-builtin-face)
      (,gemini-quote-regexp . 'gemini-quote-face)))
  "Font lock keywords for `gemini-mode'.")

(defvar gemini-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "C-c C-l") #'gemini-insert-link)
    (define-key map (kbd "C-c RET") #'gemini-insert-list-item)
    map)
  "Keymap for `gemini-mode'.")

;; See RFC 3986 (URI).
(defconst gemini-regex-uri
  "\\([a-zA-z0-9+-.]+:[^]\t\n\r<>,;() ]+\\)"
  "Regular expression for matching URIs.")

(defun gemini-get-used-uris ()
  "Return a list of all used URIs in the buffer."
  (save-excursion
    (goto-char (point-min))
    (let (uris)
      (while (re-search-forward gemini-regex-uri nil t)
        (push (match-string 1) uris))
      uris)))

(defun gemini-insert-link ()
  "Insert new link, with interactive prompts.
If there is an active region, use the text as the default URL, if
it seems to be a URL, or link text value otherwise."
  (interactive)
  (cl-multiple-value-bind (begin end text uri)
      (if (use-region-p)
          ;; Use region as either link text or URL as appropriate.
          (let ((region (buffer-substring-no-properties
                         (region-beginning) (region-end))))
            (if (string-match gemini-regex-uri region)
                ;; Region contains a URL; use it as such.
                (list (region-beginning) (region-end)
                      nil (match-string 1 region))
              ;; Region doesn't contain a URL, so use it as text.
              (list (region-beginning) (region-end)
                    region nil))))
    (let* ((used-uris (gemini-get-used-uris))
           (uri (completing-read "URL: "
                                 used-uris nil nil uri))
           (text (completing-read "Link text (blank for plain URL): "
                                  nil nil nil text)))
      (when (and begin end)
        (delete-region begin end))
      (insert "=> " uri)
      (unless (string= text "")
        (insert " " text)))))

(defun gemini-insert-list-item ()
  "Insert a new list item.
If at the beginning of a line, just insert it. Otherwise
go to the end of the current line, insert a newline, and
insert a list item."
  (interactive)
  (if (equal (line-beginning-position) (point))
      (insert "* ")
    (end-of-line)
    (newline)
    (insert "* ")))

;;;###autoload
(define-derived-mode gemini-mode text-mode "gemini"
  "Major mode for editing text/gemini 'geminimap' documents"
  (setq font-lock-defaults '(gemini-highlights))
  (visual-line-mode 1)
  (when (featurep 'visual-fill-column)
    (visual-fill-column-mode 1)))

;;;###autoload
(progn
  (add-to-list 'auto-mode-alist '("\\.gmi\\'" . gemini-mode))
  (add-to-list 'auto-mode-alist '("\\.gemini\\'" . gemini-mode))
  (add-to-list 'auto-mode-alist '("\\.geminimap\\'" . gemini-mode)))

(provide 'gemini-mode)

;;; gemini-mode.el ends here
