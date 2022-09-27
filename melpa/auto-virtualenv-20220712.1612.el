;;; auto-virtualenv.el --- Auto activate python virtualenvs

;; Copyright (C) 2017-2022 Marcwebbie

;; Author: Marcwebbie <marcwebbie@gmail.com>
;; URL: http://github.com/marcwebbie/auto-virtualenv
;; Version: 1.4.1
;; Keywords: Python, Virtualenv, Tools
;; Package-Requires: ((cl-lib "0.5") (pyvenv "1.9") (s "1.10.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Auto virtualenv activates virtualenv automatically when called.
;; To use auto-virtualenv set hooks for `auto-virtualenv-set-virtualenv'
;; To set a custom virtualenv path set variable `auto-virtualenv-custom-virtualenv-path'

;; For example:
;; (require 'auto-virtualenv)
;; (add-hook 'python-mode-hook 'auto-virtualenv-set-virtualenv)
;; (add-hook 'projectile-after-switch-project-hook 'auto-virtualenv-set-virtualenv)

;;; Code:

(require 'cl-lib)
(require 'vc)
(require 'python)
(require 'pyvenv)
(require 's)

(defun auto-virtualenv-first-file-exists-p (filelist)
  (cl-loop for filename in (mapcar #'expand-file-name filelist)
           when (file-exists-p filename)
           return filename))

(defcustom auto-virtualenv-dir (auto-virtualenv-first-file-exists-p '("~/.virtualenvs" "~/.pyenv/versions"))
  "The intended virtualenvs installation directory."
  :type 'directory
  :safe #'stringp
  :group 'auto-virtualenv)

(defvar auto-virtualenv-custom-virtualenv-path ".custom-virtualenv"
  "Variable that sets a custom virtualenv path")

(defvar auto-virtualenv-project-root-files
  '(".python-version" ".dir-locals.el" ".projectile" ".emacs-project" "manage.py" ".git" ".hg")
  "The presence of any file/directory in this list indicates a project root.")

(defvar auto-virtualenv-verbose nil
  "Verbose output on activation")

(defvar auto-virtualenv--path nil
  "Used internally to cache the current virtualenv path.")
(make-variable-buffer-local 'auto-virtualenv--path)

(defvar auto-virtualenv--project-root nil
  "Used internally to cache the project root.")
(make-variable-buffer-local 'auto-virtualenv--project-root)


(defun auto-virtualenv--project-root-projectile ()
  "Return projectile root if projectile is available"
  (when (and (boundp 'projectile-project-root) (not (equal (projectile-project-name) "-")))
    (projectile-project-root)))

(defun auto-virtualenv--project-root-vc ()
  "Return vc root if file is in version control"
  (or
   (vc-find-root (or (buffer-file-name) "") ".git")
   (vc-find-root (or (buffer-file-name) "") ".hg")))


(defun auto-virtualenv--project-root-traverse ()
  "Tranvese parent directories looking for files
in `auto-virtualenv-project-root-files' that indicates
a root directory"
  (let ((dominating-file (locate-dominating-file default-directory
                           (lambda (dir)
                             (cl-intersection
                              auto-virtualenv-project-root-files
                              (directory-files dir)
                              :test 'string-equal)))))
    (when dominating-file
      (expand-file-name dominating-file))))

(defun auto-virtualenv--project-root ()
  "Return the current project root directory."
  (or auto-virtualenv--project-root
      (setq auto-virtualenv--project-root
            (or (auto-virtualenv--project-root-projectile)
                (auto-virtualenv--project-root-vc)
                (auto-virtualenv--project-root-traverse)
             ""))))

(defun auto-virtualenv--project-name ()
  "Return the project project root name"
  (file-name-nondirectory
   (directory-file-name
    (or (file-name-directory (auto-virtualenv--project-root)) ""))))

(defun auto-virtualenv--versions ()
  "Get list of available virtualenv names"
  (if (and auto-virtualenv-dir (file-exists-p (expand-file-name auto-virtualenv-dir)))
      (directory-files (expand-file-name auto-virtualenv-dir))))

(defun auto-virtualenv-expandpath (path)
  (expand-file-name path auto-virtualenv-dir))

(defun auto-virtualenv-find-virtualenv-path ()
  "Get current buffer-file possible virtualenv name.
0. Try path set from custom virtualenv variable
1. Try path from .auto-virtualenv-version file if it exists or
2. Try name from .python-version file if it exists or
3. Try .venv or .virtualenv or venv dir in the root of project
4. Try find a virtualenv with the same name of Project Root.
Project root name is found using `auto-virtualenv--project-root'"
  (let ((python-version-file (expand-file-name ".python-version" (auto-virtualenv--project-root)))
        (custom-virtualenv-dir (expand-file-name auto-virtualenv-custom-virtualenv-path (auto-virtualenv--project-root)))
        (dot-venv-dir (expand-file-name ".venv/" (auto-virtualenv--project-root)))
        (dot-virtualenv-dir (expand-file-name ".virtualenv/" (auto-virtualenv--project-root)))
        (local-venv-dir (expand-file-name "venv/" (auto-virtualenv--project-root)))
        (auto-virtualenv-version-file (expand-file-name ".auto-virtualenv-version" (auto-virtualenv--project-root)))
        )
    (cond
     ;; 0. Try path set from custom virtualenv variable
     ((file-exists-p custom-virtualenv-dir)
      custom-virtualenv-dir)

     ;; 1. Try path from .auto-virtualenv-version file if it exists or
     ((file-exists-p auto-virtualenv-version-file)
      (auto-virtualenv-expandpath
       (with-temp-buffer
         (insert-file-contents auto-virtualenv-version-file) (s-trim (buffer-string)))))

     ;; 2. Try name from .python-version file if it exists or
     ((file-exists-p python-version-file)
      (auto-virtualenv-expandpath
       (with-temp-buffer
         (insert-file-contents python-version-file) (s-trim (buffer-string)))))

     ;; 3. Try .venv dir in the root of project
     ((file-exists-p dot-venv-dir)
      dot-venv-dir)
     ((file-exists-p dot-virtualenv-dir)
      dot-virtualenv-dir)
     ((file-exists-p local-venv-dir)
      local-venv-dir)

     ;; 4. Try find a virtualenv with the same name of Project Root.
     ((and (auto-virtualenv--versions) (member (auto-virtualenv--project-name) (auto-virtualenv--versions)))
      (auto-virtualenv-expandpath (auto-virtualenv--project-name))))))

;;;###autoload
(defun auto-virtualenv-set-virtualenv ()
  "Activate virtualenv for buffer-filename"
  (let ((virtualenv-path (auto-virtualenv-find-virtualenv-path)))
    (when (and virtualenv-path (not (equal virtualenv-path auto-virtualenv--path)))
      (setq auto-virtualenv--path virtualenv-path)
      (pyvenv-mode t)
      (pyvenv-activate virtualenv-path)
      (when auto-virtualenv-verbose
        (message "activated virtualenv: %s" virtualenv-path)))))

(provide 'auto-virtualenv)

;;; auto-virtualenv.el ends here
