;;; counsel-fd.el --- counsel interface for fd  -*- lexical-binding: t; -*-

;; Copyright © 2020, Chetan Koneru tall rights reserved.

;; Version: 0.1.0
;; Package-Version: 20210606.1724
;; Package-Commit: e9513a3c7f6cdbdf038f951e828e631c0455e7d4
;; URL: https://github.com/CsBigDataHub/counsel-fd
;; Package-Requires: ((counsel "0.12.0"))
;; Keywords: tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;  counsel interface for fd

;;; Code:
(require 'counsel)

(defvar counsel-fd-command "fd --hidden --color never "
  "Base command for fd.")

;;;###autoload
(defun counsel-fd-dired-jump (&optional initial-input initial-directory)
  "Jump to a directory (in dired) below the current directory.
List all subdirectories within the current directory.
INITIAL-INPUT can be given as the initial minibuffer input.
INITIAL-DIRECTORY, if non-nil, is used as the root directory for search."
  (interactive
   (list nil
         (when current-prefix-arg
           (read-directory-name "From directory: "))))
  (counsel-require-program "fd")
  (let* ((default-directory (or initial-directory default-directory)))
    (ivy-read "Directory: "
              (split-string
               (shell-command-to-string
                (concat counsel-fd-command "--type d --exclude '*.git'"))
               "\n" t)
              :initial-input initial-input
              :action (lambda (d) (dired-x-find-file (expand-file-name d)))
              :caller 'counsel-fd-dired-jump)))

;;;###autoload
(defun counsel-fd-file-jump (&optional initial-input initial-directory)
  "Jump to a file below the current directory.
List all files within the current directory or any of its subdirectories.
INITIAL-INPUT can be given as the initial minibuffer input.
INITIAL-DIRECTORY, if non-nil, is used as the root directory for search."
  (interactive
   (list nil
         (when current-prefix-arg
           (read-directory-name "From directory: "))))
  (counsel-require-program "fd")
  (let* ((default-directory (or initial-directory default-directory)))
    (ivy-read "File: "
              (split-string
               (shell-command-to-string
                (concat counsel-fd-command "--type f --exclude '*.git'"))
               "\n" t)
              :initial-input initial-input
              :action (lambda (d) (find-file (expand-file-name d)))
              :caller 'counsel-fd-file-jump)))

(provide 'counsel-fd)

;;; counsel-fd.el ends here
