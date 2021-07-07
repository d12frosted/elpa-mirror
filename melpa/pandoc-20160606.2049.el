;;; pandoc.el --- Pandoc interface -*- mode: lexical-binding: t -*-

;; Copyright (C) 2016 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 6 Jun 2016
;; Version: 0.0.1
;; Package-Version: 20160606.2049
;; Package-Commit: 0f59533bbd8494fea3172551efb6ec49f61ba285
;; Keywords: documentation markup converter
;; Homepage: https://github.com/zonuexe/pandoc.el
;; Package-Requires: ((emacs "24"))

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
(defun pandoc-convert-file (file-path input-format output-format)
  "Convert `FILE-PATH' as `INPUT-FORMAT' to `OUTPUT-FORMAT'."
  (let ((args (list "-t" output-format "--" file-path)))
    (unless (null input-format)
      (setq args (append (list "-f" input-format) args)))
    (with-temp-buffer
      (apply 'call-process-region (point-min) (point-max) "pandoc" t t nil args)
      (buffer-substring-no-properties (point-min) (point-max)))))

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
      (insert (if is-localfile
                  (pandoc-convert-file file nil "html")))
      (save-buffer))
    (eww-open-file tmp-file)))

(provide 'pandoc)
;;; pandoc.el ends here
