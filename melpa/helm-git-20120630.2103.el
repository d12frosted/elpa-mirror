;;; helm-git.el --- Helm extension for Git.

;; Copyright (C) 2012 Marian Schubert

;; Author   : Marian Schubert <marian.schubert@gmail.com>
;; URL      : https://github.com/maio/helm-git
;; Package-Version: 20120630.2103
;; Package-Commit: 5b4a6eb7a97b2583236a1f919b75249957918e29
;; Version  : 1.1
;; Keywords : helm, git

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Helm Git extension makes opening files from current Git repository
;; fast and easy. It uses Git binary (using magit) to get list of
;; project files so it's prety fast even for large projects with
;; thousands of files. It also takes into account .gitignore file so
;; that you only get real project files. Magit should also make it
;; usable on wide variety of OS.
;;
;;; Code:

(require 'helm-locate)
(require 'magit)

(defun helm-git-file-name-localname (path)
  (if (file-remote-p path)
      (tramp-file-name-localname (tramp-dissect-file-name path))
    path))

(defun helm-git-git-dir ()
  "This function is required because magit-git-dir doesn't always return tramp path."
  (if (file-remote-p default-directory)
      (let ((path (tramp-dissect-file-name default-directory)))
        (tramp-make-tramp-file-name
         (tramp-file-name-method path)
         (tramp-file-name-user path)
         (tramp-file-name-host path)
         (helm-git-file-name-localname (magit-git-dir))))
    (magit-git-dir)))

(defun helm-git-root-dir ()
  (expand-file-name ".." (helm-git-git-dir)))

(defun helm-git-root-p (candidate)
  (setq candidate (expand-file-name candidate))
  (let ((default-directory (if (file-directory-p candidate)
                               (file-name-as-directory candidate)
                               (file-name-as-directory
                                helm-ff-default-directory))))
    (stringp (condition-case nil
                 (helm-git-root-dir)
               (error nil)))))

(defun helm-git-file-full-path (name)
  (expand-file-name name (helm-git-root-dir)))

(defun helm-git-find-file (name)
  (find-file (helm-git-file-full-path name)))

(defun helm-c-git-files ()
  (magit-git-lines "ls-files" "--full-name"
                   "--" (helm-git-file-name-localname (helm-git-root-dir))))

;; [NOTE] When value is changed need to restart emacs.
(defvar helm-git-ff-action-index 4
  "Add list git files action in `helm-c-source-find-files' at this index.")

(defun helm-ff-git-find-files (candidate)
  (let ((default-directory (file-name-as-directory
                            (if (file-directory-p candidate)
                                (expand-file-name candidate)
                                (file-name-directory candidate))))) 
    (helm-run-after-quit
     #'(lambda (d)
         (let ((default-directory d))
           (helm-git-find-files)))
     default-directory)))

(when (require 'helm-files)
  (helm-add-action-to-source-if
   "List git files"
   'helm-ff-git-find-files
   helm-c-source-find-files
   'helm-git-root-p
   helm-git-ff-action-index))

(defvar helm-c-source-git-files
  `((name . "Git files list")
    (init . (lambda ()
              (helm-init-candidates-in-buffer
               "*helm git*" (helm-c-git-files))))
    (candidates-in-buffer)
    (keymap . ,helm-generic-files-map)
    (help-message . helm-generic-file-help-message)
    (mode-line . helm-generic-file-mode-line-string)
    (match helm-c-match-on-basename)
    (type . file)
    (action . (lambda (candidate)
                (helm-git-find-file candidate))))
  "Helm Git files source definition")

(defun helm-git-find-files ()
  (interactive)
  (helm :sources '(helm-c-source-git-files)))

(provide 'helm-git)

;;; helm-git.el ends here
