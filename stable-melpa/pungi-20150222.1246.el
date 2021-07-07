;;; pungi.el --- Integrates jedi with virtualenv and buildout python environments

;; Copyright (C) 2014  Matthew Russell

;; Author: Matthew Russell <matthew.russell@horizon5.org>
;; Version: 1.1
;; Package-Version: 20150222.1246
;; Package-Commit: a2d4d439ea371be0b064a12248288903b8a521a0
;; Keywords: convenience
;; Package-Requires: ((jedi "0.2.0alpha2") (pyvenv "1.5"))

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
;; If not using ELPA (i.e list-packages), then add the following to
;; your init.el/.emacs:
;;
;; (add-to-list 'load-path 'path-to-this-file)
;;
;; Using ELPA (When installed from `list-packages'):
;; (require 'pungi)
;; (add-hook #'python-mode-hook
;;           '(lambda ()
;;              (pungi:setup-jedi)))
;;
;; Verification that everything is setup correctly:
;; When visiting a python buffer, move the cursor over a symbol
;; and check that invoking M-x `jedi:goto-definition' opens a
;; new buffer showing the source of that python symbol.
;;
;;; Code:
(require 'python)
(require 'pyvenv)
(require 'jedi)

;;;###autoload
(defun pungi:setup-jedi ()
  "Integrate with jedi."
  (pungi--set-jedi-paths-for-detected-environment)
  (jedi:setup))

(defun pungi--set-jedi-paths-for-detected-environment ()
  "Set `jedi:server-args' for the detected environment."
  (let* ((venv pyvenv-virtual-env)
	 (omelette (pungi--detect-buffer-omelette buffer-file-name)))
    (if venv
	(setq python-shell-virtualenv-path venv))
    (if (and omelette (file-exists-p omelette))
	(setq python-shell-extra-pythonpaths (list omelette)))))

(defun pungi--find-directory-container-from-path (directory path)
  "Find a DIRECTORY located within a subdirectory of the given PATH."
  (let ((buffer-dir (file-name-directory path)))
    (while (and (not (file-exists-p
                      (concat buffer-dir directory)))
                buffer-dir)
      (setq buffer-dir
            (if (equal buffer-dir "/")
                nil
              (file-name-directory (directory-file-name buffer-dir)))))
    buffer-dir))

(defun pungi--detect-buffer-omelette (path)
  "Detect if the file pointed to by PATH is in use by buildout.

;;; Commentary:
buildout recipes usually contain a `part` called `omelette`,
which is a hierarchy of symlinks,
generated from the python eggs specified by the buildout configuration."
  (let ((parent-dir (pungi--find-directory-container-from-path "omelette" path)))
    (if (not parent-dir)
	(let* ((prefix (pungi--find-directory-container-from-path "parts" path)))
	  (setq parent-dir (concat prefix "parts/"))))
    (concat parent-dir "omelette")))

(provide 'pungi)
;;; pungi.el ends here
