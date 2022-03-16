;;; pyvenv-auto.el --- Automatically switch Python venvs -*- lexical-binding: t -*-

;; Copyright (C) 2022 Nakamura, Ryotaro <nakamura.ryotaro.kzs@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20220315.1606
;; Package-Commit: 59ece8554bf249f30984c81c103a5704d2fb27bf
;; Package-Requires: ((emacs "26.3") (pyvenv "1.21"))
;; URL: https://github.com/nryotaro/pyvenv-auto
;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.

;;; Commentary:

;; pyvenv-auto automatically activates a Python venv with pyvenv package.
;; When you open a file in python-mode, it searches for the venv
;; directory near the file, and activates it.  When you open a Python
;; file, pyvenv-auto searches for a venv directory with a name in
;; `pyvenv-auto-venv-dirnames`.  The search behavior is similar to that of
;; `locate-dominating-file`.  The directory name with a smaller index
;; has higher priority than that with a greater index.

;;; Code:
(require 'pyvenv)

(defgroup pyvenv-auto-mode nil
  "Autmatic switcher of Python venv."
  :prefix "pyvenv-auto-"
  :group 'pyvenv-auto)

(defcustom pyvenv-auto-venv-dirnames
  (list "venv" ".venv")
  "The patterns of venv directories that you want to activate."
  :type '(repeat string))

(defun pyvenv-auto--locate-venv
    (base-directory venv-dirname)
  "Search for a venv directory.
Search for a venv that matches VENV-DIRNAME
from BASE-DIRECTORY.  The behavior is similar to
`locate-dominating-file'."
  (when-let ((parent-dir (locate-dominating-file
			  base-directory
			  (pyvenv-auto--resolve-activate
			   venv-dirname))))
    (expand-file-name
         (concat (file-name-as-directory parent-dir)
	    venv-dirname))))

(defun pyvenv-auto--locate-venvs
    (base-directory venv-dirnames)
  "Search for a venv directory from venv directories.
Search for VENV-DIRNAMES from BASE-DIRECTORY.
The behavior is similar to `locate-dominating-file'.
The priority is same as the order of VENV-DIRNMAES.
Return a path of the venv directory or nil."
  (seq-some #'identity
	    (mapcar (lambda (venv-dirname)
		      (pyvenv-auto--locate-venv base-directory
					   venv-dirname))
		    venv-dirnames)))

(defun pyvenv-auto--run ()
  "Search for a venv directory and activate it."
  (when-let* ((venv-dir (pyvenv-auto--locate-venvs
			 default-directory
			 pyvenv-auto-venv-dirnames))
	      (match (not (equal venv-dir pyvenv-virtual-env))))
    (pyvenv-activate venv-dir)
    (message "pyvenv-auto activated %s." venv-dir)))

(defun pyvenv-auto--resolve-activate (directory)
  "Return the path of the activete file in DIRECTORY."
  (concat (file-name-as-directory
	   (concat (file-name-as-directory directory) "bin"))
	  "activate"))

;;;###autoload
(define-minor-mode pyvenv-auto-mode
  "Turn on pyvenv-auto-mode."
  :init-value nil
  :lighter " pyvenv-auto"
  :global t
  (let ((hook 'python-mode-hook))
  (if pyvenv-auto-mode
      (add-hook hook #'pyvenv-auto--run)
    (remove-hook hook #'pyvenv-auto--run))))

(provide 'pyvenv-auto)
;;; pyvenv-auto.el ends here
