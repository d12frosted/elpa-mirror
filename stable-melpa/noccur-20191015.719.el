;;; noccur.el --- Run multi-occur on project/dired files

;; Copyright (C) 2014  Nicolas Petton

;; Author: Nicolas Petton <petton.nicolas@gmail.com>
;; Keywords: convenience
;; Package-Version: 20191015.719
;; Package-Commit: fa91647a305e89561d3dbe53da002fff49abe0bb
;; Version: 0.2
;; Package: noccur
;; Package-Requires: ()

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

;; occur-mode is one of the awesome modes that come builtin with Emacs.
;;
;; Sometimes I just want to run multi-occur on all (or a sub-directory)
;; of a project I'm working on.  Used with keyboard macros it makes it
;; a snap to perform modifications on many buffers at once.
;;
;; The way I use it is the following:

;; M-x noccur-project RET foo RET The occur buffer's content can then
;; be edited with occur-edit-mode (bound to e).  To save changes in all
;; modified buffer and go back to occur-mode press C-c C-c.

;;; Code:

;;;###autoload
(defun noccur-dired (regexp &optional nlines)
  "Perform `multi-occur' with REGEXP in all dired marked files.
When called with a prefix argument NLINES, display NLINES lines before and after."
  (interactive (occur-read-primary-args))
  (multi-occur (mapcar #'find-file (dired-get-marked-files)) regexp nlines))

;;;###autoload
(defun noccur-project (regexp &optional nlines directory-to-search)
  "Perform `multi-occur' with REGEXP in the current project files.
When called with a prefix argument NLINES, display NLINES lines before and after.
If DIRECTORY-TO-SEARCH is specified, this directory will be searched recursively;
otherwise, the user will be prompted to specify a directory to search.

For performance reasons, files are filtered using 'find' or 'git
ls-files' and 'grep'."
  (interactive (occur-read-primary-args))
  (let* ((default-directory (or directory-to-search (read-directory-name "Search in directory: ")))
         (files (mapcar #'find-file-noselect
                        (noccur--find-files regexp))))
    (multi-occur files regexp nlines)))

(defun noccur--within-git-repository-p ()
  (locate-dominating-file default-directory ".git"))

(defun noccur--find-files (regexp)
  (let* ((listing-command (if (noccur--within-git-repository-p)
                              "git ls-files -z"
                            "find . -type f -print0"))
         (command (format "%s | xargs -0 grep -l \"%s\""
                          listing-command
                          regexp)))
    (split-string (shell-command-to-string command) "\n")))

(provide 'noccur)
;;; noccur.el ends here
