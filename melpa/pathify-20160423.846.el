;;; pathify.el --- Symlink your scripts into a PATH directory

;; Copyright © 2015, 2016 Alex Kost

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 19 May 2015
;; Version: 0.1
;; Package-Version: 20160423.846
;; Package-Commit: 401b184c743694a60b3bc4273fc43de05cd5ac4b
;; URL: https://gitlab.com/alezost-emacs/pathify
;; URL: https://github.com/alezost/pathify.el
;; Keywords: convenience

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

;; This file provides some code for convenient symlinking files into
;; particular directory (`pathify-directory').  It is intended to be
;; used for symlinking your scripts (or other executable files) into
;; your "~/bin" directory (as you surely have it in your PATH
;; environment variable :-).

;; To install the package manually, add the following to your init file:
;;
;;   (add-to-list 'load-path "/path/to/pathify-dir")
;;   (autoload 'pathify "pathify" nil t)
;;   (autoload 'pathify-dired "pathify" nil t)
;;
;; Optionally, set `pathify-directory' variable (if you do not use
;; "~/bin"):

;; Now you may use "M-x pathify-dired" command in a dired buffer to
;; pathify the marked files (or the current file if nothing is marked).
;; For more convenience, you may bind this command to some key, for
;; example:
;;
;;   (eval-after-load 'dired
;;     '(define-key dired-mode-map "P" 'pathify-dired))

;;; Code:

(defgroup pathify nil
  "Make symlinks in a your favourite PATH directory."
  :group 'convenience)

(defcustom pathify-directory "~/bin"
  "Directory where symlinks are created."
  :type 'string
  :group 'pathify)

(defcustom pathify-make-symlink-function
  #'pathify-make-symlink-truename
  "Function used to make a symlink."
  :type '(choice (function-item pathify-make-symlink)
                 (function-item pathify-make-symlink-truename)
                 (function :tag "Another function"))
  :group 'pathify)

(defcustom pathify-dired-confirm-function #'y-or-n-p
  "Function used to prompt about confirmation of pathifying."
  :type '(choice (function-item y-or-n-p)
                 (function-item yes-or-no-p)
                 (function :tag "Another function"))
  :group 'pathify)

(defun pathify-make-symlink (filename linkname)
  "Make a symbolic link to FILENAME, named LINKNAME.
Prompt for confirmation if the link already exists."
  (make-symbolic-link filename linkname 0))

(defun pathify-make-symlink-truename (filename linkname)
  "Make a symbolic link to a true name of FILENAME, named LINKNAME.
Prompt for confirmation if the link already exists."
  (make-symbolic-link (file-truename filename) linkname 0))

;;;###autoload
(defun pathify (file)
  "Pathify FILE.
Make symlink to FILE in `pathify-directory'."
  (interactive "fMake symlink to file: ")
  (or (file-directory-p pathify-directory)
      (error "Directory '%s' does not exist.
Set `pathify-directory' variable"
             pathify-directory))
  (let ((target (expand-file-name (file-name-nondirectory
                                   (directory-file-name file))
                                  pathify-directory)))
    (funcall pathify-make-symlink-function
             file target)
    (message "Symlink '%s' has been created." target)))

;;;###autoload
(defun pathify-dired (&optional arg)
  "Pathify all marked (or next ARG) files or the current file."
  (interactive "P")
  (require 'dired)
  (let* ((files (dired-map-over-marks (dired-get-filename) arg))
         (filenames (nreverse (mapcar #'dired-make-relative files))))
    (if (dired-mark-pop-up nil 'pathify filenames
                           pathify-dired-confirm-function
                           (concat "Pathify "
                                   (dired-mark-prompt arg filenames)))
        (mapc #'pathify files)
      (message "(Pathifying has been cancelled)"))))

(provide 'pathify)

;;; pathify.el ends here
