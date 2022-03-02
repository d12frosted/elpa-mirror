;;; zoxide.el --- Find file by zoxide -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Ruoyu Feng

;; Author: Ruoyu Feng <emacs@vonfry.name>
;; Maintainer: Ruoyu Feng <emacs@vonfry.name>
;; Created: 23 Jun 2021
;; Modified: 23 Jun 2021
;; Version: 0.0.1
;; Package-Version: 20220302.522
;; Package-Commit: ecdcb62847b5e54ccd477d740e4974f28c8f5809
;; Package-Requires: ((emacs "25.1"))
;; Keywords: converience matching
;; URL: https://gitlab.com/Vonfry/zoxide.el

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is free software: you can redistribute it and/or modify
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

;; Zoxide for finding file and open directory.
;;
;; Please see readme.org from the same repository for documentation.

;;; Code:

(defgroup zoxide nil
  "Zoxide for finding file and open directory."
  :group 'convenience)

(defcustom zoxide-executable (executable-find "zoxide")
  "The zoxide executable."
  :type 'string
  :group 'zoxide)

(defcustom zoxide-find-file-function #'find-file
  "The callback function for the target path in `zoxide-find-file'.
If the function is interactive, it will be called by `call-interactively' in
`default-directory' with target path.  Otherwise, the target path is passed as
argument.

For example, you set this to `counsel-fzf' to open file with fzf through counsel
or `dired' to open directory instead of a file."
  :type 'function
  :group 'zoxide)

(defcustom zoxide-travel-callback-function #'find-file
  "The callback function for the target path in `zoxide-travel'.
Unlike `zoxide-find-file-function', this always be called with the selected path
as its first argument noninteractively."
  :type 'function
  :group 'zoxide)

(defcustom zoxide-get-path-function (lambda (&rest _) default-directory)
  "A function how to get current path.

The function should take a argument to get the context and return a string for
path.

The context may be one of add or remove.

The default defination is get from `default-directory' for add and remove and."
  :type 'function
  :group 'zoxide)

;;;###autoload
(defun zoxide-run (async &rest args)
  "Run zoxide command with args.
The first argument ASYNC specifies whether calling asynchronously or not.
The second argument ARGS is passed to zoxide directly, like query -l"
  (if async
      (apply #'start-process "zoxide" "*zoxide*" zoxide-executable args)
    (with-temp-buffer
      (if (equal 0 (apply #'call-process zoxide-executable nil t nil args))
          (buffer-string)
        (append-to-buffer "*zoxide*" (point-min) (point-max))
        (warn "Zoxide error. See buffer *zoxide* for more details.")))))

;;;###autoload
(defun zoxide-add (&optional path &rest _)
  "Add PATH to zoxide database.  This function is called asynchronously."
  (interactive "Dpath: ")
  (unless path
    (setq path (funcall zoxide-get-path-function 'add)))
  (zoxide-run t "add" path))

;;;###autoload
(defun zoxide-remove (&optional path)
  "Remove PATH from zoxide database."
  (interactive "Dpath: ")
  (unless path
    (setq path (funcall zoxide-get-path-function 'remove)))
  (zoxide-run t "remove" path))

;;;###autoload
(defun zoxide-query-with (query)
  "Search zoxide database with QUERY by calling zoxide query.
When calling interactively, it will open a buffer to show results.  Otherwise,
a list of paths is returned."
  (interactive "squery: ")
  (let ((results  (zoxide-run nil "query" query)))
    (if (called-interactively-p 'any)
        (let ((buf-name "*zoxide query*"))
          (when (get-buffer buf-name)
            (kill-buffer buf-name))
          (switch-to-buffer-other-window buf-name)
          (with-current-buffer buf-name
            (erase-buffer)
            (insert results)
            (special-mode)))
      (split-string results))))

;;;###autoload
(defun zoxide-query ()
  "Similar to `zoxide-query-with', but list all paths instead of matching."
  (interactive)
  (if (called-interactively-p 'any)
      (funcall-interactively #'zoxide-query-with "-l")
    (zoxide-query-with "-l")))

;;;###autoload
(defun zoxide-open-with (query callback &optional noninteractive)
  "Search QUERY and run CALLBACK function with a selected path.

If NONINTERACTIVE is non-nil, the callback is always called
directly with the selected path as its first argument.

This is a help function to define interactive commands like
`zoxide-find-file'.  If you want to do things noninteractive, please use
`zoxide-query', filter results and pass it to your function manually instead."
  (let* ((results (if query
                      (zoxide-query-with query)
                    (zoxide-query)))
         (default-directory (completing-read "path: " results nil t)))
    (if (and (not noninteractive) (commandp callback))
        (call-interactively callback)
      (funcall callback default-directory))))

;;;###autoload
(defun zoxide-find-file-with-query ()
  "Open file in path from zoxide with a search query."
  (interactive)
  (let ((query (read-string "query: ")))
    (zoxide-open-with query zoxide-find-file-function)))

;;;###autoload
(defun zoxide-find-file ()
  "Open file in path from zoxide with all paths."
  (interactive)
  (zoxide-open-with nil zoxide-find-file-function))

;;;###autoload
(defun zoxide-cd-with-query ()
  "Select default directory through zoxide with a search query."
  (interactive)
  (let ((query (read-string "query: ")))
    (zoxide-open-with query #'cd t)))

;;;###autoload
(defun zoxide-cd ()
  "Select default directory through zoxide with all paths."
  (interactive)
  (zoxide-open-with nil #'cd t))

;;;###autoload
(defun zoxide-travel ()
  "Like `zoxide-find-file', this function is used to open the path directly."
  (interactive)
  (zoxide-open-with nil zoxide-travel-callback-function t))

;;;###autoload
(defun zoxide-travel-with-query ()
  "Like `zoxide-travel', a query mached at first."
  (interactive)
  (let ((query (read-string "query: ")))
    (zoxide-open-with query zoxide-travel-callback-function t)))
(provide 'zoxide)

;;; zoxide.el ends here
