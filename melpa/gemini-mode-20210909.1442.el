;;; gemini-mode.el --- A simple highlighting package for text/gemini -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Jason McBrayer

;; Author: Jason McBrayer <jmcbray@carcosa.net>, tastytea <tastytea@tastytea.de>, Étienne Deparis <etienne@depar.is>
;; Created: 20 May 2020
;; Version: 1.1.2
;; Keywords: languages
;; Homepage: https://git.carcosa.net/jmcbray/gemini.el
;; Package-Requires: ((emacs "24.4"))

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
(require 'time-stamp)

(eval-when-compile
  (defvar font-lock-beg)
  (defvar font-lock-end)
  (defun elpher-go (_))
  (defun visual-fill-column-mode (_)))

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
(defface gemini-ulist-face
  '((t :inherit font-lock-keyword-face))
  "Face for unordered list items in Gemini"
  :group 'gemini-mode)

(defcustom gemini-mode-hook 'turn-on-visual-line-mode
  "Normal hook run when entering Gemini mode. Usually used to set line
wrapping"
  :type 'hook
  :options '(turn-on-visual-line-mode turn-on-visual-fill-column-mode)
  :group 'gemini-mode)

(defcustom gemini-timestamp-format "%a %d %b %Y %H:%M:%S %Z"
  "Format for inserting timestamps in Gemini text documents.
This includes TinyLogs headers, which need to be in specific formats. Valid values include \"%a %d %b %Y %H:%M:%S %Z\" and \"%Y-%m-%d %H:%M:%S %Z\". You can use other values suitable for `format-time-string', however."
  :type 'string
  :group 'gemini-mode)

;; See RFC 3986 (URI).
(defconst gemini-regex-uri
  "\\([a-zA-z0-9+-.]+:[^]\t\n\r<>,;() ]+\\)"
  "Regular expression for matching URIs.")

(defconst gemini-regex-link-line
  "^=>[[:blank:]]?\\([^[:blank:]]+\\)\\([[:blank:]]?.*\\)?$"
  "Regular expression for matching link lines.
Used by ‘font-lock-defaults’ and ‘gemini-link-at-point’.")

(defvar gemini-highlights
  (let* ((gemini-preformatted-regexp "^```[^`]+```$")
         (gemini-heading-rest-regexp "^####+[[:blank:]]*.*$")
         (gemini-heading-3-regexp "^###[[:blank:]]*.*$")
         (gemini-heading-2-regexp "^##[[:blank:]]*.*$")
         (gemini-heading-1-regexp "^#[[:blank:]]*.*$")
         (gemini-ulist-regexp "^\\* .*$")
         (gemini-quote-regexp "^>[[:blank:]]*.*$"))
    ;; preformatted must be declared first has it must absolutely be set
    ;; before any other face (for exemple to avoid a title inside a
    ;; preformatted block to hijack it).
    `((,gemini-preformatted-regexp . 'font-lock-builtin-face)
      (,gemini-heading-rest-regexp . 'gemini-heading-face-rest)
      (,gemini-heading-3-regexp . 'gemini-heading-face-3)
      (,gemini-heading-2-regexp . 'gemini-heading-face-2)
      (,gemini-heading-1-regexp . 'gemini-heading-face-1)
      (,gemini-regex-link-line 1 'link)
      (,gemini-ulist-regexp . 'gemini-ulist-face)
      (,gemini-quote-regexp . 'gemini-quote-face)))
  "Font lock keywords for `gemini-mode'.")

(defvar gemini-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "C-c C-l") #'gemini-insert-link)
    (define-key map (kbd "C-c C-o") #'gemini-open-link-at-point)
    (define-key map (kbd "C-c RET") #'gemini-insert-list-item)
    (define-key map (kbd "C-c C-t") #'gemini-insert-time-stamp)
    (define-key map (kbd "C-c C-n") #'gemini-insert-tinylog-header)
    map)
  "Keymap for `gemini-mode'.")

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

(defun gemini-insert-time-stamp ()
  "Insert the current time into the buffer.
Formatting depends on `gemini-timestamp-format'."
  (interactive)
  (insert (time-stamp-string gemini-timestamp-format)))

(defun gemini-insert-tinylog-header (title)
  (interactive "sEntry Title: ")
  (insert "## " (time-stamp-string gemini-timestamp-format)
          " " title "\n"))

(defun gemini-link-at-point ()
  "Return the link present on the line at point."
  (let ((line (thing-at-point 'line t)))
    (when (string-match gemini-regex-link-line line)
      (match-string 1 line))))

(defun gemini-open-link-at-point ()
  "Open the link at point with elpher if it is installed."
  (interactive)
  (let ((link (gemini-link-at-point)))
    (when link
      (cond ((string-prefix-p "gemini://" link t)
             (when (require 'elpher nil t)
               (elpher-go link)))
            ((file-exists-p link)
             (find-file link))
            ((string-match "https?://" link)
             (browse-url link))
            (t (error "Don't know what to do with %s" link))))))

(defun gemini-font-lock-extend-region-for-preformatted-blocks ()
  "Extend the current font-lock focus to allow preformatted block discovering."
  (save-excursion
    (let (block-start block-end)
      (goto-char font-lock-beg)
      (end-of-line)
      (when (re-search-backward "^```.*$" nil t)
        (setq block-start (match-beginning 0))
        (unless (eq block-start (point-min))
          (setq block-start (1- block-start))))
      (goto-char font-lock-end)
      (beginning-of-line)
      (when (re-search-forward "^```$" nil t)
        (setq block-end (match-end 0))
        (unless (eq block-end (point-max))
          (setq block-end (1+ block-end))))
      (when (and block-start block-end)
        (setq font-lock-beg block-start
              font-lock-end block-end)))))

(defun turn-on-visual-fill-column-mode nil
  (require 'visual-fill-column)
  (visual-fill-column-mode 1))

;;;###autoload
(define-derived-mode gemini-mode text-mode "gemini"
  "Major mode for editing text/gemini 'geminimap' documents"
  (setq font-lock-defaults '(gemini-highlights))
  (add-hook 'font-lock-extend-region-functions
            #'gemini-font-lock-extend-region-for-preformatted-blocks)
  (visual-line-mode 1)
  (run-hooks 'gemini-mode-hook))

;;;###autoload
(progn
  (add-to-list 'auto-mode-alist '("\\.gmi\\'" . gemini-mode))
  (add-to-list 'auto-mode-alist '("\\.gemini\\'" . gemini-mode))
  (add-to-list 'auto-mode-alist '("\\.geminimap\\'" . gemini-mode)))

(provide 'gemini-mode)

;;; gemini-mode.el ends here
