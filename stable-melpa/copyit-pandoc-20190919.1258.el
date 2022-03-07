;;; copyit-pandoc.el --- Copy it, yank anything! -*- lexical-binding: t -*-

;; Copyright (C) 2019 USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 6 Jun 2016
;; Version: 0.1.0
;; Package-Version: 20190919.1258
;; Package-Commit: c4f2c28e5b6270e8e3364341619f1154bb4e682e
;; Keywords: convenience yank clipboard
;; Homepage: https://github.com/zonuexe/emacs-copyit
;; Package-Requires: ((emacs "24.3") (copyit "0.1.0") (pandoc "0.0.1"))

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

;; “Copy” is known as “Yank” in Emacs.
;;
;; ** Functions
;; - copyit-pandoc-export-to-html
;; - copyit-pandoc-export-to-markdown

;;; Code:
(require 'copyit)
(require 'pandoc)

;;;###autoload
(defun copyit-pandoc-export-to-html (file-path)
  "Convert and Copy `FILE-PATH' file as HTML."
  (interactive "p")
  (kill-new
   (pandoc-convert-file
    (if (and (eq 4 file-path) buffer-file-name)
        buffer-file-name
      (read-file-name ""))
    nil "html")))

;;;###autoload
(defun copyit-pandoc-export-to-markdown (file-path)
  "Convert and Copy `FILE-PATH' file as Markdown."
  (interactive "p")
  (kill-new
   (pandoc-convert-file
    (if (and (eq 4 file-path) buffer-file-name)
        buffer-file-name
      (read-file-name ""))
    nil (pandoc-markdown-dialect))))

(provide 'copyit-pandoc)
;;; copyit-pandoc.el ends here
