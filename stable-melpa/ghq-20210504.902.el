;;; ghq.el --- Ghq interface for emacs -*- lexical-binding: t -*-

;; Author: Roman Coedo <romancoedo@gmail.com>
;; Created 28 November 2015
;; Version: 0.1.3
;; Package-Version: 20210504.902
;; Package-Commit: 582bd6daa505d04c7cc06d6c82ed8aee0624bfbe
;; Package-Requires: ()

;; Keywords: ghq

;;; Commentary:

;; This package provides a set of functions wrapping ghq.

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(defun ghq--find-root ()
  "Find the ghq root directory."
  (car (split-string (shell-command-to-string "ghq root"))))

(defvar ghq--root
  (ghq--find-root))

(defun ghq--find-projects ()
  "Find the list of ghq projects relative to ghq root."
  (split-string (shell-command-to-string "ghq list")))

(defun ghq--find-projects-full-path ()
  "Find the list of ghq projects."
  (split-string (shell-command-to-string "ghq list --full-path")))

(defun ghq--get-repository (repository)
  "Get the REPOSITORY."
  (async-shell-command (concat "ghq get " repository)))

(defun ghq--get-repository-ssh (repository)
  "Get the REPOSITORY using ssh."
  (async-shell-command (concat "ghq get -p " repository)))

(defvar ghq--helm-action
  '(("Open Dired"              . (lambda (dir) (dired              (concat ghq--root "/" dir))))
    ("Open Dired other window" . (lambda (dir) (dired-other-window (concat ghq--root "/" dir))))
    ("Open Dired other frame"  . (lambda (dir) (dired-other-frame  (concat ghq--root "/" dir))))))

;(defun ghq--build-helm-source ()
  ;"Build a helm source."
  ;(when (fboundp 'helm-build-sync-source)
  ;(helm-build-async-source "Search ghq projects with helm"
    ;:candidates-process (lambda () (start-process "ghq-list-process" nil "ghq" "list" helm-pattern))
    ;:action ghq--helm-action)))

(defun ghq--build-helm-source ()
  "Build a helm source."
  (helm-make-source "Search ghq projects with helm" 'helm-source-sync
    :candidates (ghq--find-projects)
    :action ghq--helm-action))

;;;###autoload
(defun ghq ()
  "Get the repository via ghq."
  (interactive)
  (ghq--get-repository (read-string "Enter the repository: ")))

(defun ghq-ssh ()
  "Get the repository via ghq using ssh."
  (interactive)
  (ghq--get-repository-ssh (read-string "Enter the repository: ")))

(defun ghq-list ()
  "Display the ghq project list in a message."
  (interactive)
  (message (shell-command-to-string "ghq list")))

(defun ghq-list-full-path ()
  "Display the ghq project list in a message."
  (interactive)
  (message (shell-command-to-string "ghq list --full-path")))

(defun helm-ghq-list ()
  "Opens a helm buffer with ghq projects as source."
  (interactive)
  (when (and (fboundp 'ghq--build-helm-source) (fboundp 'helm))
    (helm :sources (ghq--build-helm-source) :prompt "Select repository: " :buffer "*ghq-helm*")))

(provide 'ghq)
;;; ghq.el ends here
