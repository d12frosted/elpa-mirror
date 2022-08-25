;;; ox-mdx-deck.el --- org-mode to mdx-deck exporter  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Joshua Wolfe

;; Author: Joshua Wolfe
;; Keywords: lisp org ox mdx deck
;; Package-Version: 20181115.1847
;; Package-Commit: f3dbc35870b69a5d8971b1647da8c5468f520c5d
;; Version: 0.0.1
;; URL: https://github.com/WolfeCub/ox-mdx-deck/
;; Package-Requires: ((emacs "24") (ox-hugo "0.7"))

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

;; An exporter from org-mode to mdx-deck.

;;; Code:

;;; Dependencies

(require 'ox-hugo)

(defun ox-mdx-deck--export-to-file (async subtreep visible-only body-only)
  "Export the current buffer to an .mdx file.

For more information on ASYNC SUBTREEP VISIBLE-ONLY and BODY-ONLY see `org-export-define-backend'"
  (ignore async subtreep visible-only body-only)
  (org-export-to-file 'mdx-deck
      (concat (file-name-sans-extension (buffer-file-name (current-buffer)))
              ".mdx")))

(defun ox-mdx-deck--export-to-buffer (async subtreep visible-only body-only)
  "Export the current buffer to a new mdx buffer.

For more information on ASYNC SUBTREEP VISIBLE-ONLY and BODY-ONLY see `org-export-define-backend'"
  (ignore async subtreep visible-only body-only)
  (org-export-to-buffer 'mdx-deck "*mdx-deck export*"))

;;;###autoload
(org-export-define-derived-backend 'mdx-deck 'blackfriday
  :menu-entry '(?x "MDX Deck" ((?f "File" ox-mdx-deck--export-to-file)
                               (?b "Buffer" ox-mdx-deck--export-to-buffer)))
  :options-alist '((:with-toc . nil)
                   (:with-special-strings . nil))
  :translate-alist
  '((headline . (lambda (headline contents info)
                  (concat (org-md-headline headline contents info) "---")))
    (src-block . (lambda (src-block contents info)
                   (if (string-equal "rjsx"
                                     (org-element-property :language src-block))
                       (org-element-property :value src-block)
                     (org-blackfriday-src-block src-block contents info))))))

  
(provide 'ox-mdx-deck)
;;; ox-mdx-deck.el ends here
