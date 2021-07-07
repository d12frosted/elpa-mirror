;;; helm-pages.el --- Pages in current buffer as Helm datasource  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  David Christiansen

;; Author: David Christiansen <david@davidchristiansen.dk>
;; Keywords: convenience, helm, outlines
;; Package-Version: 20150117.2233
;; Package-Commit: e334ca3312e51d6fdfa989df5d3ebe683d673c0e
;; Package-Requires: ((helm "1.6.5") (emacs "24") (cl-lib "0.5"))
;; Version: 0.1.1

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

;; 

;;; Code:
(require 'cl-lib)
(require 'helm)
(require 'helm-grep)


;; Functions for getting information about the pages in the buffer

(defun helm-pages-get-next-header ()
  "Get the next non-blank line after POINT."
  (with-helm-current-buffer
    (save-restriction
      (save-excursion
        (narrow-to-page)
        (beginning-of-line)
        (while (and (not (eobp))
                    (looking-at-p "^\\s-*$"))
          (forward-line))
        (let* ((start (progn (beginning-of-line) (point)))
               (end (progn (end-of-line) (point))))
          (buffer-substring start end))))))

(defun helm-pages-get-pages ()
  "Get a list of (POS . HEADER) pairs, where POS denotes the beginning of a page and HEADER is the contents of the first non-blank line in that page."
  (with-helm-current-buffer
    (save-restriction
      (widen)
      (save-excursion
        (goto-char (point-min))
        (let ((pages (list (cons (point) (helm-pages-get-next-header)))))

          (while (re-search-forward page-delimiter nil t)
            (push (cons (match-beginning 0) (helm-pages-get-next-header))
                  pages))
          (nreverse pages))))))


;; Functions implementing Helm commands

(defun helm-pages-goto-page (pos)
  "Go to the page at POS, preserving narrowing."
  (with-helm-current-buffer
    (let ((narrowed (buffer-narrowed-p)))
      (widen)
      (goto-char pos)
      (forward-line)
      (recenter-top-bottom 0)
      (when narrowed (narrow-to-page)))))

(defun helm-pages-narrow-to-page (pos)
  "Narrow to the page at POS."
  (with-helm-current-buffer
    (goto-char pos)
    (forward-line)
    (recenter-top-bottom 0)
    (narrow-to-page)))


;; The Helm datasource itself

(defun helm-pages-name (&optional _name)
  "Get the name of the Helm pages source, for the user, where NAME is Helm's name."
  (with-helm-current-buffer
    (or
     (ignore-errors (concat "Pages in " (buffer-name)))
     "Pages")))

(defun helm-pages-candidates ()
  "Get the Helm view of the buffer's pages."
  (with-helm-current-buffer
    (cl-loop for (pos . header)
             in (helm-pages-get-pages)
             collect (let ((lineno (concat (number-to-string
                                            (line-number-at-pos pos))
                                           ": ")))
                       (cons (concat (propertize lineno 'face 'helm-grep-lineno)
                                     header)
                             pos)))))

(defvar helm-pages-source
  (helm-build-sync-source "pages"
    :header-name 'helm-pages-name
    :candidates 'helm-pages-candidates
    :action (helm-make-actions
             "Go to page" 'helm-pages-goto-page
             "Narrow to page" 'helm-pages-narrow-to-page)
    :persistent-help "View page"
    :persistent-action 'helm-pages-goto-page
    ))

;;;###autoload
(defun helm-pages ()
  "View the pages in the current buffer with Helm."
  (interactive)
  (helm :sources '(helm-pages-source)
        :buffer "*helm-pages"))

(provide 'helm-pages)
;;; helm-pages.el ends here
