;;; yatemplate.el --- File templates with yasnippet

;; Copyright (C) 2015, 2016, 2018, 2020  Wieland Hoffmann <themineo+yatemplate@gmail.com>

;; Author: Wieland Hoffmann <themineo+yatemplate@gmail.com>
;; URL: https://github.com/mineo/yatemplate
;; Package-Version: 20200625.1336
;; Package-Commit: 399564fc1afa100aa6049ac6de11fb065882d230
;; Version: 1.0
;; Package-Requires: ((yasnippet "0.8.1") (emacs "24.3"))
;; Keywords: files, convenience

;; This file is not part of GNU Emacs.

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

;; This package bridges the gap between yasnippet and auto-insert-mode.  By
;; populating auto-insert-alist with filenames and automatically expanding their
;; content after insertion by auto-insert-mode, it's an easy way to create
;; dynamic file templates.  Simply call `yatemplate-fill-alist' somewhere in
;; your Emacs initialization file to populate `auto-insert-alist' with filenames
;; from `yatemplate-dir'.

;; Each filename will be turned into a new element to `push' onto
;; `auto-insert-alist'.  To guarantee a particular order, filenames must contain
;; one colon (":").  After collecting all the filenames in `yatemplate-dir',
;; their names will be sorted with `string<', then split on the colon.  The
;; first substring will be discarded, which means it can be used to establish an
;; ordering.  The second substring will be used as a regexp as the CONDITION of
;; the element to push onto `auto-insert-alist'.  The ACTION will be a vector of
;; actions that first insert the content of the template file and then expand
;; the content of the buffer with `yatemplate-expand-yas-buffer', which simply
;; calls `yas-expand-snippet', so you can use everything YASnippet offers in the
;; template.

;; This means that if `yatemplate-dir' looks like this:

;; .emacs.d/templates
;; ├── 00:test_.*.py
;; └── 01:.*.py

;; `yatemplate-fill-alist' will first `push' (".*.py" . ACTION) onto
;; `auto-insert-alist' and then ("test_.*.py" . ACTION).

;; Of course, you will need to enable `auto-insert-mode' to have the snippet
;; inserted and expanded into new files.

;;; Code:

(require 'autoinsert)
(require 'yasnippet)

(defgroup yatemplate
  nil
  "Customization group for yatemplate."
  :group 'files
  :group 'convenience)

;;;###autoload
(defcustom yatemplate-dir
  (locate-user-emacs-file "templates")
  "The directory containing file templates."
  :group 'yatemplate
  :type 'directory)

;;;###autoload
(defcustom yatemplate-separator
  ":"
  "Separator used for splitting filenames.

This is the separator that is used to split template filenames into
the ordering and regular expression parts.

Note that this will be used as the SEPARATORS argument of
`split-string', so be careful when setting this to a value that
has special meaning in regular expressions."
  :group 'yatemplate
  :type 'string)

;;;###autoload
(defcustom yatemplate-ignored-files-regexp "README.md$"
  "Regular expression matching files that do not contain `yatemplate-separator', but will generate no warning."
  :group 'yatemplate
  :type 'regexp)

(defvar-local yatemplate-owner user-full-name
  "The copyright owner for the buffer.
Particularly useful when combined with `.dir-locals.el'.")

;;;###autoload
(put 'yatemplate-owner 'safe-local-variable #'stringp)

(defvar-local yatemplate-license "http://www.gnu.org/licenses/gpl.html"
  "The license (usually a URL) for the buffer.
Particularly useful when combined with `.dir-locals.el'.")

;;;###autoload
(put 'yatemplate-license 'safe-local-variable #'stringp)

(defun yatemplate-expand-yas-buffer ()
  "Expand the whole buffer with `yas-expand-snippet'."
  (yas-expand-snippet (buffer-string) (point-min) (point-max)))

(defun yatemplate-sorted-files-in-dir ()
  "Return a sorted list of files in the template directory."
  (sort (file-expand-wildcards (concat (file-name-as-directory yatemplate-dir) "*")) 'string<))

(defun yatemplate-regex-from-filename (FILENAME)
  "Split the regular expression from FILENAME and return it."
  (let ((split-name (split-string FILENAME yatemplate-separator)))
    (if (eq (length split-name) 2)
        ;; Add the dollar sign for end-of-string automatically since the last
        ;; characters of the filename are most likely a file extension.
        (concat (nth 1 split-name) "$")
      (progn
        (unless (string-match yatemplate-ignored-files-regexp FILENAME)
          (message "yatemplate: %s does not contain %s exactly once"
                   FILENAME yatemplate-separator))
        nil))))

;;;###autoload
(defun yatemplate-fill-alist ()
  "Fill `auto-insert-alist'."
  (yatemplate-remove-old-yatemplates-from-alist)
  (dolist (filename (reverse (yatemplate-sorted-files-in-dir)) nil)
    (let ((file-regex (yatemplate-regex-from-filename filename)))
      (if file-regex
          (push `(,file-regex . [,filename yatemplate-expand-yas-buffer])
                auto-insert-alist)))))

(defun yatemplate-remove-old-yatemplates-from-alist ()
  "Remove all yatemplates from `auto-insert-alist' not to keep old settings."
  (setq auto-insert-alist
        (cl-remove-if
         (lambda (pair)
           (ignore-errors (eq 'yatemplate-expand-yas-buffer (aref (cdr pair) 1))))
         auto-insert-alist)))

;;; Hooks
(defun yatemplate--find-file-hook ()
  "Set yatemplate files `snippet-mode' to be able to test."
  ;; Some modes (for example nov-mode) explicitly call `set-visited-file-name
  ;; nil t', in which case buffer-file-name returns nil.
  (when (and buffer-file-name (file-in-directory-p buffer-file-name yatemplate-dir))
    (let ((mode major-mode))
      (snippet-mode)
      (set (make-local-variable 'yas--guessed-modes) (list mode)))))
(add-hook 'find-file-hook 'yatemplate--find-file-hook)

(defun yatemplate--after-save-hook ()
  "Set `auto-insert-alist' after saving yatemplate files."
  (when (and buffer-file-name (file-in-directory-p buffer-file-name yatemplate-dir))
    (yatemplate-fill-alist)))
(add-hook 'after-save-hook 'yatemplate--after-save-hook)

(defun yatemplate-unload-function ()
  "Unload function for yatemplate."
  (interactive)
  (remove-hook 'find-file-hook 'yatemplate--find-file-hook)
  (remove-hook 'after-save-hook 'yatemplate--after-save-hook)
  (yatemplate-remove-old-yatemplates-from-alist))

(provide 'yatemplate)
;;; yatemplate.el ends here
