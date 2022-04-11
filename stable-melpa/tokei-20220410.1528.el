;;; tokei.el --- Display codebase statistics -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Daniel Nagy
;;
;; Author: Daniel Nagy <https://github.com/nagy>
;; Maintainer: Daniel Nagy <danielnagy@posteo.de>
;; Created: April 1, 2022
;; Version: 0.1
;; Package-Version: 20220410.1528
;; Package-Commit: 948a62dc7b2f66db4f25b1836dca6bc20ea2f02d
;; Homepage: https://github.com/nagy/tokei.el
;; Package-Requires: ((emacs "27.1") (magit-section "3.3.0"))
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;;  Tokei mode for Emacs
;;
;;; Code:

(require 'magit-section)
(require 'json)
(eval-when-compile
  (require 'cl-lib)
  (require 'let-alist))

;;; Options

(defgroup tokei nil
  "Display codebase statistics."
  :group 'extensions
  :prefix "tokei-")

(defcustom tokei-program "tokei"
  "Path to the 'tokei' program."
  :type 'string)

(defcustom tokei-use-header-line t
  "If non-nil, display a header line."
  :type 'boolean)

(defcustom tokei-separator " · "
  "The separator to be displayed between code and comment numbers."
  :type 'string)

;;;; Faces

(defgroup tokei-faces nil
  "Faces used by Tokei."
  :group 'tokei
  :group 'faces)

(defface tokei-num-code-face nil
  "Tokei number of lines of code."
  :group 'tokei-faces)

(defface tokei-num-comments-face nil
  "Tokei number of lines of comments."
  :group 'tokei-faces)

;;; Commands

(defvar-local tokei-data nil "Tokei buffer local data.")

(defun tokei--data ()
  "Return newly created tokei data for this directory."
  (json-parse-string
    (with-temp-buffer
      (if (zerop (call-process tokei-program nil t nil "--output=json" ))
        (buffer-string)
        ""))
    :object-type 'alist
    :array-type 'list))

(defun tokei--sort-predicate (elem1 elem2)
  "A predicate to compare ELEM1 and ELEM2 by num of code and then name."
  (let ((numcode1 (or (alist-get 'code elem1) (alist-get 'code (alist-get 'stats elem1))))
       (numcode2 (or (alist-get 'code elem2) (alist-get 'code (alist-get 'stats elem2))))
       (name1 (or (alist-get 'name elem1) (car  elem1)))
       (name2 (or (alist-get 'name elem2) (car  elem2))))
    (if (= numcode1 numcode2)
      (string-lessp name1 name2)
      (> numcode1 numcode2))))

(cl-defun tokei--get-sorted (&optional (data tokei-data))
  "Sort the provided tokei DATA."
  (sort (copy-sequence data) #'tokei--sort-predicate))

(defun tokei--formatted-stats (code comments)
  "Format one entry.

Takes CODE and COMMENTS entries."
  (concat
    (cond
      ((>= 9 code) "    ")
      ((>= 99 code) "   ")
      ((>= 999 code) "  ")
      ((>= 9999 code) " "))
    (propertize (number-to-string code) 'face 'tokei-num-code-face)
    tokei-separator
    (cond
      ((>= 9 comments) "    ")
      ((>= 99 comments) "   ")
      ((>= 999 comments) "  ")
      ((>= 9999 comments) " "))
    (propertize (number-to-string comments) 'face 'tokei-num-comments-face)))

(defun tokei--get-formatted-files (json)
  "Retrieve multiple formatted entries.

Data is provided via the JSON argument."
  (cl-loop for s in (sort
                (copy-sequence (alist-get 'reports json))
                #'tokei--sort-predicate)
    collect
    (let-alist s
      (list
        :name .name
        :code .stats.code
        :comments .stats.comments
        :blanks .stats.blanks))))

(define-derived-mode tokei-mode magit-section-mode "Tokei"
  "Tokei mode."
  :group 'tokei
  (setq tokei-data (tokei--data))
  (setq-local revert-buffer-function (lambda (&rest _) (tokei-mode)))
  (when tokei-use-header-line
    (setq-local header-line-format (concat
                                     "File"
                                     (propertize " " 'display '(space :align-to center))
                                     "Code"
                                     tokei-separator
                                     "Comments")))
  (let ((inhibit-read-only t))
    (erase-buffer)
    (magit-insert-section (tokei-root)
      (cl-loop for lang in (tokei--get-sorted)
        for langname = (format "%s" (car lang))
        unless (string= langname "Total")
        do
        (magit-insert-section (tokei-language langname)
          (magit-insert-heading (concat
                                  (propertize langname 'face 'magit-section-heading)
                                  (propertize " " 'display '(space :align-to center))
                                  (tokei--formatted-stats (alist-get 'code lang) (alist-get 'comments lang))
                                  "\n"))
          (cl-loop for file in (tokei--get-formatted-files lang)
            for filename = (plist-get file :name)
            for numcode = (plist-get file :code)
            for numcomments = (plist-get file :comments)
            do
            (magit-insert-section (tokei-file filename)
              (insert
                (string-remove-prefix "./" filename)
                (propertize " " 'display '(space :align-to center))
                (tokei--formatted-stats numcode numcomments)
                "\n")))
          (insert "\n"))))
    (setf (point) (point-min))))

;;;###autoload
(defun tokei ()
  "Show codebase statistics."
  (interactive)
  (unless (executable-find tokei-program)
    (user-error "Command not found: %s" tokei-program))
  (switch-to-buffer (generate-new-buffer "*tokei*"))
  (tokei-mode))

;; TODO virtual dired from one language files
;; TODO context-menu
;; TODO dired tokei only marked entries to filter out
;; TODO count all marked lines ( region )
;; TODO show only minimum amount of code/comment lines. take prefix argument
;; TODO segment definition for telephone line
;; TODO project.el mode new in emacs

(provide 'tokei)
;;; tokei.el ends here
