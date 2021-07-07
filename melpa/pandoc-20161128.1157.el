;;; pandoc.el --- Pandoc interface -*- mode: lexical-binding: t -*-

;; Copyright (C) 2016 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 6 Jun 2016
;; Version: 0.0.1
;; Package-Version: 20161128.1157
;; Package-Commit: 198d262d09e30448f1672338b0b5a81cf75e1eaa
;; Keywords: hypermedia documentation markup converter
;; Homepage: https://github.com/zonuexe/pandoc.el
;; Package-Requires: ((emacs "24.4"))

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

;; Pandoc interface for Emacs.
;;
;; ** Functions
;; - pandoc-convert-file
;; - pandoc-convert-stdio
;; - pandoc-open-eww
;;
;; ** Customize
;; - pandoc-markdown-default-dialect

;;; Code:
(defgroup pandoc nil
  "Pandoc"
  :group 'text)

(defcustom pandoc-markdown-default-dialect 'commonmark
  ""
  :type '(choice (const :tag "Commonmark"  'commonmark)
                 (const :tag "Pandoc's Markdown" 'markdown)
                 (const :tag "PHP Markdown Extra" 'markdown_phpextra)
                 (const :tag "GitHub-Flavored Markdown" 'markdown-github)
                 (const :tag "MultiMarkdown" 'markdown_mmd)
                 (const :tag "Markdown.pl" 'markdown-strict)
                 string))

(defun pandoc--tmp-file (file-path)
  "Return path to temp file by `FILE-PATH'."
  (concat temporary-file-directory "emacs-pandoc_"
          (file-name-nondirectory file-path) ".html"))

(defun pandoc-markdown-dialect ()
  "Return markdown dialect/variable name string."
  (if (symbolp pandoc-markdown-default-dialect)
      (symbol-name pandoc-markdown-default-dialect)
    pandoc-markdown-default-dialect))

;;;###autoload
(defun pandoc-antiword (file)
  "Convert `FILE' to DocBook using Antiword."
  (with-temp-buffer
    (call-process "antiword" nil t nil "-x" "db" file)
    (buffer-substring-no-properties (point-min) (point-max))))

(defun pandoc--use-antiword (file)
  "Return t if `FILE' is MS Word .doc format."
  ;; require `file' command.
  (and
   (executable-find "antiword")
   (executable-find "file")
   (string= "application/msword"
            (with-temp-buffer
              (call-process "file" nil t nil "-b" "--mime-type" "--" file)
              (goto-char (point-min))
              (search-forward "\n")
              (replace-match  "")
              (buffer-substring-no-properties (point-min) (point-max))))))

;;;###autoload
(defun pandoc-convert-file (file-path input-format output-format)
  "Convert `FILE-PATH' as `INPUT-FORMAT' to `OUTPUT-FORMAT'."
  (if (pandoc--use-antiword file-path)
      (pandoc-convert-stdio (pandoc-antiword file-path) "docbook" output-format)
    (let ((args (list "-t" output-format "--" file-path)))
      (unless (null input-format)
        (setq args (append (list "-f" input-format) args)))
      (with-temp-buffer
        (apply 'call-process-region (point-min) (point-max) "pandoc" t t nil args)
        (buffer-substring-no-properties (point-min) (point-max))))))

;;;###autoload
(defun pandoc-convert-stdio (body input-format output-format)
  "Convert `BODY' as `INPUT-FORMAT' to `OUTPUT-FORMAT'."
  (let ((args (list "-f" input-format "-t" output-format)))
    (with-temp-buffer
      (insert body)
      (apply 'call-process-region (point-min) (point-max) "pandoc" t t nil args)
      (buffer-substring-no-properties (point-min) (point-max)))))

;;;###autoload
(defun pandoc-open-eww (file)
  "Render `FILE' using EWW and Pandoc."
  (interactive "F")
  (let* ((buf (find-file-noselect file))
         (tmp-file (pandoc--tmp-file file))
         (is-localfile (with-current-buffer buf
                         (and (buffer-file-name)
                              (not (file-remote-p (buffer-file-name)))))))
    (with-current-buffer (find-file-noselect tmp-file)
      (delete-region (point-min) (point-max))
      (insert (if is-localfile
                  (pandoc-convert-file file nil "html")))
      (save-buffer))
    (eww-open-file tmp-file)))

(defun pandoc--eww-open-wrapper (file)
  "Render `FILE' using Pandoc if file is not HTML."
  (if (string-match "\\.html?\\'" file)
      nil
    (pandoc-open-eww file)))

;;;###autoload
(defun pandoc-turn-on-advice-eww (&optional enable)
  "When `eww-open-file' using Pandoc if the file is not HTML.

Remove advice if `ENABLE' equals `-1'."
  (if (eq -1 enable)
      (advice-remove 'eww-open-file #'pandoc--eww-open-wrapper)
    (advice-add 'eww-open-file :before-until #'pandoc--eww-open-wrapper)
    t))

(provide 'pandoc)
;;; pandoc.el ends here
