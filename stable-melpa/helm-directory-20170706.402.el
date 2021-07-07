;;; helm-directory.el --- selecting directory before select the file -*- lexical-binding: t; -*-

;; Copyright (C) 2017 by Masashı Mıyaura

;; Author: Masashı Mıyaura
;; URL: https://github.com/masasam/emacs-helm-directory
;; Package-Version: 20170706.402
;; Package-Commit: 51bd7cd6e40a84a7efda894283ec76a0107830ad
;; Version: 0.6.4
;; Package-Requires: ((emacs "24.4") (helm "2.0"))

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

;; You can select directory before select the file with helm interface.
;; Since the directory has important meanings at the framework,
;; I want to complement with helm only the files that is in the meaningful directory.
;; This package provide it.
;; When you select a directory with helm, the file in that directory can be used with helm.

;;; Code:

(require 'helm)
(require 'helm-mode)
(require 'helm-files)

(defgroup helm-directory nil
  "Selecting directory before select the file."
  :group 'helm)

(defcustom helm-directory-basedir nil
  "Search directories that belong to this directory by helm."
  :group 'helm-directory
  :type 'string)

(defcustom helm-directory-basedir-list nil
  "A list of `helm-directory-basedir' that can be set with `helm-directory-change'."
  :group 'helm-directory
  :type 'string)

(defvar helm-directory--action
  '(("Open File" . find-file)
    ("Open Directory" . helm-directory--open-dired)))

(defun helm-directory--open-dired (file)
  "Open FILE with dired."
  (dired (file-name-directory file)))

(defun helm-directory--list-candidates ()
  "Collect directory candidate list with find."
  (let ((paths))
    (when (file-exists-p (expand-file-name helm-directory-basedir))
      (with-temp-buffer
	(let ((ret (call-process-shell-command (concat "find " helm-directory-basedir " -type d") nil t)))
	  (goto-char (point-min))
	  (while (not (eobp))
	    (let ((line (buffer-substring-no-properties
			 (line-beginning-position) (line-end-position))))
	      (push line paths))
	    (forward-line 1))
	  (reverse paths))))))

(defun helm-directory--source (repo)
  "Helm-directory source as REPO."
  (let ((name (file-name-nondirectory (directory-file-name repo))))
    (helm-build-in-buffer-source name
      :init #'helm-directory--ls-files
      :action helm-directory--action)))

(defun helm-directory--ls-files ()
  "Display the files in the selected directory with helm interface."
  (with-current-buffer (helm-candidate-buffer 'global)
    (unless (zerop (apply #'call-process "ls" nil '(t nil) nil))
      (error "Failed: Can't get file list candidates"))))

;;;###autoload
(defun helm-directory ()
  "Selecting directory before select the file."
  (interactive)
  (let ((repo (helm-comp-read "Directory: "
                              (helm-directory--list-candidates)
                              :name "Directory"
                              :must-match t)))
    (let ((default-directory (file-name-as-directory repo)))
      (helm :sources (list (helm-directory--source default-directory))
            :buffer "*helm-directory-list*"))))

(defun helm-directory-change-open (path)
  "Set `helm-directory-basedir' with PATH."
  (setq helm-directory-basedir path))

(defun helm-directory-basedir-set ()
  "Set `helm-directory-basedir'."
  (let ((resultlist)
	(basedir-list helm-directory-basedir-list))
    (while basedir-list
      (push (car basedir-list) resultlist)
      (pop basedir-list))
    (reverse resultlist)))

(defvar helm-directory-change-list--source
  (helm-build-sync-source "Change helm-directory-basedir"
    :candidates #'helm-directory-basedir-set
    :volatile t
    :action (helm-make-actions
             "Change directory" #'helm-directory-change-open)))

;;;###autoload
(defun helm-directory-change ()
  "Change `helm-directory-basedir' with helm interface."
  (interactive)
  (helm :sources '(helm-directory-change-list--source) :buffer "*helm-directory-change*"))

(provide 'helm-directory)

;;; helm-directory.el ends here
