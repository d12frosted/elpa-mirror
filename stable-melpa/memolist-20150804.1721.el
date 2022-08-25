;;; memolist.el --- memolist.el is Emacs port of memolist.vim.
;; Author: mikanfactory <k952i4j14x17_at_gmail.com>
;; Maintainer: mikanfactory
;; Copyright (C) 2015 mikanfactory all rights reserved.
;; Created: :2015-03-01
;; Version: 0.0.1
;; Package-Version: 20150804.1721
;; Package-Commit: 60c296e202a71e9dcf1c3936d47b5c4b95c5839f
;; Keywords: markdown, memo
;; URL: http://github.com/mikanfactory/emacs-memolist
;; Package-Requires: ((markdown-mode "22.0") (ag "0.45"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; 
;; memolist.el is Emacs port of memolist.vim. Org-mode is very useful and multifunction,
;; but it is also hard to approach and coufuse with markdown. memolist.el offer you
;; simple interface for writing and searching.
;; 
;; This program make markdown file in your `memolist-memo-directory' or
;; search markdown file there. By default, `memolist-memo-directory' is
;; set to "~/Memo" directory. If you would like to change it,
;; use custom-set-valiables function like this.
;; 
;; (custom-set-variables '(memolist-memo-directory "/path/to/your/memo/directory"))
;; 
;; Commands:
;; `memolist-show-list': Show markdown file which placed in `memolist-memo-directory'.
;; `memolist-memo-grep': Search contents of markdown file by arg.
;; `memolist-memo-grep-tag': Search tags in markdown file by arg.
;; `memolist-memo-new': Create new markdown file in `memolist-memo-directory'.
;; 

;;; Code:
(require 'ag)
(require 'markdown-mode)

(defgroup memolist nil
  "memolist.el is Emacs port of memolist.vim."
  :prefix "memolist"
  :group 'convenience)

(defcustom memolist-memo-directory "~/Memo"
  "This package make markdown file in specified directory."
  :type 'string
  :group 'memolist)

(defun memolist-exist-memo-directory? ()
  "Check `memolist-memo-directory' is already exist or not."
  (file-directory-p memolist-memo-directory))

(defun memolist-create-memo-directory ()
  "Make new directory specified by `memolist-memo-directory'."
  (make-directory memolist-memo-directory))

(defun memolist-init-directory? ()
  (when (y-or-n-p (format "Create new directory in %s?" memolist-memo-directory))
    (memolist-create-memo-directory)
    t))

(defun memolist-overwrite-or-edit (title tags)
  "Ask whethre overwrite or edit file."
  (if (y-or-n-p "The file already exists. Do you want to edit the file? ")
      (memolist-edit-memo (memolist-make-file-name title))
    (memolist-overwrite-memo title tags)))

(defun memolist-create-new-memo (title tags)
  "Create new markdown file and insert header."
  (find-file (memolist-make-file-name title))
  (memolist-write-header title tags))

(defun memolist-overwrite-memo (title tags)
  "Overwrite markdown file."
  (find-file (memolist-make-file-name title))
  (erase-buffer)
  (memolist-write-header title tags))

(defun memolist-edit-memo (file)
  "Just open markdown file."
  (find-file file))

(defun memolist-write-header (title tags)
  "Insert headers."
  (progn
    (insert (format "title: %s\n" title))
    (insert "===================\n")
    (insert (format "date: %s" (memolist-format-current-time)))
    (insert (format "tags: [%s]\n" tags))
    (insert "- - - - - - - - - -\n\n")))

(defun memolist-make-title (title)
  "Format title."
  (format "%s-%s.markdown"
          (format-time-string "%Y-%m-%d"(current-time)) title)) 

(defun memolist-make-file-name (title)
  "Create full path of markdown file."
  (expand-file-name (memolist-make-title title) memolist-memo-directory))

(defun memolist-format-current-time ()
  "Format current time."
  (format-time-string "%Y/%m/%d(%a) %H:%M:%S\n" (current-time)))

;;;###autoload
(defun memolist-memo-new (title tags)
  "Create new markdown file in `memolist-memo-directory'.
If already same file was created, ask whether overwrite it or edit it.
And when same file does not exist, create new markdown file."
  (interactive "sMemo title: \nsMemo tags: ")
  (if (or (memolist-exist-memo-directory?) (memolist-init-directory?))
      (if (file-exists-p (memolist-make-file-name title))
          (memolist-overwrite-or-edit title tags)
        (memolist-create-new-memo title tags))))

;;;###autoload
(defun memolist-show-list ()
  "Show markdown file which placed in `memolist-memo-directory'."
  (interactive)
  (if (memolist-exist-memo-directory?)
      (find-file memolist-memo-directory)
    (message "Please create directory %s" memolist-memo-directory)))

;;;###autoload
(defun memolist-memo-grep (expr)
  "Search contents of markdown file by `expr'."
  (interactive "sag: ")
  (if (memolist-exist-memo-directory?)
      (ag-regexp expr memolist-memo-directory)
    (message "Please create directory %s" memolist-memo-directory)))

;;;###autoload
(defun memolist-memo-grep-tag (tag)
  "Search tags in markdown file by `tag'."
  (interactive "sInput tag: ")
  (if (memolist-exist-memo-directory?)
      (ag-regexp (format "tags:(.*)?%s(.*)?" tag) memolist-memo-directory))
  (message "Please create directory %s" memolist-memo-directory))

(provide 'memolist)

;;; memolist.el ends here
