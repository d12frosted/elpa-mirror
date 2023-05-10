;;; ghq.el --- Ghq interface for emacs -*- lexical-binding: t -*-

;; Copyright (C) 2015 Roman Coedo
;; Copyright (C) 2021 Joseph LaFreniere

;; Author: Roman Coedo <romancoedo@gmail.com>
;; Maintainer: Joseph LaFreniere <joseph@lafreniere.xyz>
;; URL: https://github.com/lafrenierejm/emacs-ghq
;; Package-Version: 20230510.332
;; Package-Commit: eb197c14e53ac57a136ea8d34eec7528487c3301
;; Created 28 November 2015
;; Version: 0.2.0
;; Keywords: convenience
;; Package-Requires: ((emacs "26.1") (dash "2.18.0") (s "1.7.0"))

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
(require 'dash)
(require 'rx)
(require 's)
(require 'simple)

(defun ghq--find-root ()
  "Find the ghq root directory."
  (car (split-string (shell-command-to-string "ghq root"))))

(defvar ghq--root
  (ghq--find-root))

(defcustom ghq-after-clone-functions nil
  "List of functions to be called on the path of a newly cloned repository."
  :group 'ghq
  :type '(repeat symbol))

(defun ghq--find-projects ()
  "Find the list of ghq projects relative to ghq root."
  (split-string (shell-command-to-string "ghq list")))

(defun ghq--find-projects-full-path ()
  "Find the list of ghq projects."
  (split-string (shell-command-to-string "ghq list --full-path")))

;;;###autoload
(defun ghq (repository &optional ssh)
  "Clone REPOSITORY via ghq, optionally over SSH."
  (interactive "MEnter the repository: \nP")
  (let* ((clone-command (-non-nil `("ghq" "get" ,(when ssh "-p") ,repository)))
         (clone-command-string (s-join " " clone-command)))
    (set-process-sentinel
     (apply #'start-file-process clone-command-string nil clone-command)
     `(lambda (process event)
        (when (eq (process-status process) 'exit)
          (let* ((list-command (list "ghq" "list" "--full-path" "--exact" ,repository))
                 (list-command-string (s-join " " list-command))
                 (buffer (generate-new-buffer (s-wrap list-command-string "*"))))
            (set-process-sentinel
             (apply #'start-file-process list-command-string buffer list-command)
             `(lambda (process event)
                (when (memq (process-status process) '(exit signal))
                  (when-let
                      ((path (with-current-buffer ,buffer
                               (goto-char (point-min))
                               (re-search-forward
                                (rx
                                 (seq line-start (group-n 1 (one-or-more not-newline)) line-end)))
                               (match-string 1))))
                    (message "%s cloned to %s" ,,repository path)
                    (when path
                      (dolist (fun ghq-after-clone-functions)
                        (funcall fun path)))))))))))))

;;;###autoload
(defun ghq-ssh ()
  "Clone a repository via ghq over SSH."
  (interactive)
  (let ((current-prefix-arg t))
    (call-interactively #'ghq)))

(defvar ghq--helm-action
  '(("Open Dired"              . (lambda (dir) (dired              (concat ghq--root "/" dir))))
    ("Open Dired other window" . (lambda (dir) (dired-other-window (concat ghq--root "/" dir))))
    ("Open Dired other frame"  . (lambda (dir) (dired-other-frame  (concat ghq--root "/" dir))))))

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
  (when (and  (fboundp 'helm) (fboundp 'helm-make-source))
    (helm
     :sources (helm-make-source
               "Search ghq projects with helm"
               'helm-source-sync
               :candidates (ghq--find-projects)
               :action ghq--helm-action)
     :prompt "Select repository: "
     :buffer "*ghq-helm*")))

(provide 'ghq)
;;; ghq.el ends here
