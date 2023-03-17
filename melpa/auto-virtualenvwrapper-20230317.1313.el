;;; auto-virtualenvwrapper.el --- Lightweight auto activate python virtualenvs

;; Copyright (C) 2017 Marcwebbie, Robert Zaremba

;; Author: Marcwebbie <marcwebbie@gmail.com>
;;         Robert Zaremba <robert-zaremba@scale-it.pl>
;; Version: 1.2
;; Package-Commit: 8cc2616af46d7e26c1d9ecea5fffd8974e5b1acb
;; Package-Version: 20230317.1313
;; Package-X-Original-Version: 20230317
;; Keywords: Python, Virtualenv, Tools
;; Package-Requires: ((cl-lib "1.0") (s "1.13.0") (virtualenvwrapper "0"))

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

;; Auto virtualenvwrapper activates virtualenv automatically when called.
;; To use auto-virtualenvwrapper set hooks for `auto-virtualenvwrapper-activate'

;; For example:
;; (require 'auto-virtualenvwrapper)
;; (add-hook 'python-mode-hook #'auto-virtualenvwrapper-activate)
;; (add-hook 'projectile-after-switch-project-hook #'auto-virtualenvwrapper-activate)

;;; Code:

(require 'cl-lib)
(require 'vc)
(require 'python)
(require 'virtualenvwrapper)
(require 's)

(declare-function projectile-project-name "projectile")
(declare-function projectile-project-root "projectile")

(defun auto-virtualenvwrapper-first-file-exists-p (filelist)
  "Select first file from the FILELIST which exists."
  (cl-loop for filename in (mapcar #'expand-file-name filelist)
           when (file-exists-p filename)
           return filename))

(defcustom auto-virtualenvwrapper-dir (auto-virtualenvwrapper-first-file-exists-p '("~/.virtualenvs" "~/.pyenv/versions"))
  "The intended virtualenvs installation directory."
  :type 'directory
  :safe #'stringp
  :group 'auto-virtualenvwrapper)

(defcustom auto-virtualenvwrapper-auto-deactivate
  nil
  "If set to t, `auto-virtualenvwrapper-activate' deactivates
already activated virtualenv at visiting the buffer not related
any virtualenv. This is nil by default, for backward compatibility."
  :type '(boolean)
  :group 'auto-virtualenvwrapper)

(defvar auto-virtualenvwrapper-project-root-files
  '(".python-version" ".dir-locals.el" ".projectile" ".emacs-project" ".workon" "Pipfile" "pyproject.toml")
  "The presence of any file/directory in this list indicates a project root.")

(defvar auto-virtualenvwrapper-verbose t
  "Verbose output on activation.")

(defvar auto-virtualenvwrapper--path nil
  "Used internally to cache the current virtualenv path.")
(make-variable-buffer-local 'auto-virtualenvwrapper--path)

(defvar auto-virtualenvwrapper--path-cached-in nil
  "Used internally to validate `auto-virtualenvwrapper--path' cache.
`default-directory' value is assigned to this variable at caching
in function `auto-virtualenvwrapper-activate'.
If this is not equal to `default-directory', cache is treated as
invalid, because the buffer might be moved to another project.
This is nil, if `auto-virtualenvwrapper-find-virtualenv-path'
finds no related virtualenv for a buffer")
(make-variable-buffer-local 'auto-virtualenvwrapper--path-cached-in)

(defvar auto-virtualenvwrapper--project-root nil
  "Used internally to cache the project root.")
(make-variable-buffer-local 'auto-virtualenvwrapper--project-root)

(defvar auto-virtualenvwrapper--project-root-cached-in nil
  "Used internally to validate `auto-virtualenvwrapper--project-root' cache.
`default-directory' value is assigned to this variable at caching
in function `auto-virtualenvwrapper--project-root'.
If this is not equal to `default-directory', cache is treated as
invalid, because the buffer might be moved to another project.")
(make-variable-buffer-local 'auto-virtualenvwrapper--project-root-cached-in)

(defun auto-virtualenvwrapper-message (msg &rest rest)
  "Prints the MSG REST in the message area."
  (when auto-virtualenvwrapper-verbose
    (apply #'message (concat "[auto-virtualenvwrapper] " msg) rest)))

(defun auto-virtualenvwrapper--project-root-projectile ()
  "Return projectile root if projectile is available."
  (when (and (boundp 'projectile-project-root) (not (equal (projectile-project-name) "-")))
    (projectile-project-root)))

(defun auto-virtualenvwrapper--project-root-vc ()
  "Return vc root if file is in version control."
  (or
   (vc-find-root (or (buffer-file-name) "") ".git")
   (vc-find-root (or (buffer-file-name) "") ".hg")))


(defun auto-virtualenvwrapper--project-root-traverse ()
  "Tranvese parent directories looking for files in `auto-virtualenvwrapper-project-root-files' that indicates a root directory."
  (let ((dominating-file (locate-dominating-file default-directory
                           (lambda (dir)
                             (and (file-directory-p dir)
                                  (cl-intersection
                                   auto-virtualenvwrapper-project-root-files
                                   (directory-files dir)
                                   :test 'string-equal))))))
    (when dominating-file
      (expand-file-name dominating-file))))

(defun auto-virtualenvwrapper--project-root ()
  "Return the current project root directory."
  (or (and (equal auto-virtualenvwrapper--project-root-cached-in
                  default-directory)
               auto-virtualenvwrapper--project-root)
      (setq auto-virtualenvwrapper--project-root
            (or (auto-virtualenvwrapper--project-root-projectile)
                (auto-virtualenvwrapper--project-root-traverse)
                (auto-virtualenvwrapper--project-root-vc)
                "")
            auto-virtualenvwrapper--project-root-cached-in
            default-directory))
  (when (eq auto-virtualenvwrapper--project-root "")
      (auto-virtualenvwrapper-message "Can't find project root"))
  auto-virtualenvwrapper--project-root)

(defun auto-virtualenvwrapper--project-name ()
  "Return the project project root name."
  (file-name-nondirectory
   (directory-file-name
    (or (file-name-directory (auto-virtualenvwrapper--project-root)) ""))))

(defun auto-virtualenvwrapper--versions ()
  "Get list of available virtualenv names."
  (if (and auto-virtualenvwrapper-dir (file-exists-p (expand-file-name auto-virtualenvwrapper-dir)))
      (directory-files (expand-file-name auto-virtualenvwrapper-dir))))

(defun auto-virtualenvwrapper-expandpath (path)
  (expand-file-name path auto-virtualenvwrapper-dir))

(defun auto-virtualenvwrapper--is-valid-venv (path)
  "Check if a virtualenv PATH is valid.
That is, it must contain a Python executable."
  (file-exists-p (expand-file-name "bin/python" path)))

(defun auto-virtualenvwrapper--venv-by-file (file)
  "Build a virtualenv path by reading its name from FILE."
  (auto-virtualenvwrapper-expandpath
   (with-temp-buffer
     (insert-file-contents file) (s-trim (buffer-string)))))

(defun auto-virtualenvwrapper-find-virtualenv-path ()
  "Get current buffer-file possible virtualenv name.
1. Try name from .python-version or .workon file if it exists
2. Try .venv dir in the root of project
3. Try venv dir in the root of project
4. Try find a virtualenv with the same name of Project Root.
Project root name is found using `auto-virtualenvwrapper--project-root'"
  (let ((python-version-file (expand-file-name ".python-version" (auto-virtualenvwrapper--project-root)))
        (workon-file (expand-file-name ".workon" (auto-virtualenvwrapper--project-root)))
        (dot-venv-dir (expand-file-name ".venv/" (auto-virtualenvwrapper--project-root)))
        (venv-dir (expand-file-name "venv/" (auto-virtualenvwrapper--project-root))))
    (cond
     ;; 1.1 Try name from .python-version file if it exists
     ((and (file-exists-p python-version-file)
	   (auto-virtualenvwrapper--is-valid-venv
	    (auto-virtualenvwrapper--venv-by-file python-version-file)))
      (auto-virtualenvwrapper-message "using virtualenv from .python-version")
      (auto-virtualenvwrapper--venv-by-file python-version-file))
     ;; 1.2 Try name from .workon file if it exists
     ((and (file-exists-p workon-file)
	   (auto-virtualenvwrapper--is-valid-venv
	    (auto-virtualenvwrapper--venv-by-file workon-file)))
      (auto-virtualenvwrapper-message "using virtualenv from .workon")
      (auto-virtualenvwrapper--venv-by-file workon-file))
     ;; 2. Try .venv dir in the root of project
     ((and (file-exists-p dot-venv-dir)
	   (auto-virtualenvwrapper--is-valid-venv dot-venv-dir))
      (auto-virtualenvwrapper-message "using virtualenv from .venv directory")
      dot-venv-dir)
     ;; 3. Try .venv dir in the root of project
     ((and (file-exists-p venv-dir)
	   (auto-virtualenvwrapper--is-valid-venv venv-dir))
      (auto-virtualenvwrapper-message "using virtualenv from venv directory")
      venv-dir)
     ;; 4. Try find a virtualenv with the same name of Project Root.
     ((and (auto-virtualenvwrapper--versions)
	   (member (auto-virtualenvwrapper--project-name) (auto-virtualenvwrapper--versions))
	   (auto-virtualenvwrapper--is-valid-venv
	    (auto-virtualenvwrapper-expandpath (auto-virtualenvwrapper--project-name))))
      (auto-virtualenvwrapper-message "using virtualenv based on the root directory name")
      (auto-virtualenvwrapper-expandpath (auto-virtualenvwrapper--project-name))))))

;;;###autoload
(defun auto-virtualenvwrapper-activate (&optional ignore-cache)
  "Activate virtualenv for buffer-filename.
If invoked with prefix command argument, cached information is ignored.
Set `auto-virtualenvwrapper-auto-deactivate' to t, if you want deactivate
automatically at visiting the buffer not related to any virtualenv."
  (interactive "P")
  (when ignore-cache
    (kill-local-variable 'auto-virtualenvwrapper--path)
    (kill-local-variable 'auto-virtualenvwrapper--project-root))
  (let ((path (or (and (equal auto-virtualenvwrapper--path-cached-in
                              default-directory)
                       auto-virtualenvwrapper--path)
                  (auto-virtualenvwrapper-find-virtualenv-path))))
    (if path
        (setq auto-virtualenvwrapper--path path
              auto-virtualenvwrapper--path-cached-in default-directory))
    (cond
     ((and path (not (equal path venv-current-dir)))
      (venv-deactivate)
      (setq venv-current-name (file-name-nondirectory (file-truename path)))
      (venv--activate-dir auto-virtualenvwrapper--path)
      (auto-virtualenvwrapper-message "activated virtualenv: %s" path))
     ((and (not path) venv-current-dir auto-virtualenvwrapper-auto-deactivate)
      (auto-virtualenvwrapper-message
       "deactivated virtualenv: %s" venv-current-dir)
      (venv-deactivate)))))

(provide 'auto-virtualenvwrapper)

;;; auto-virtualenvwrapper.el ends here
