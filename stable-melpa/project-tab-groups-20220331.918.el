;;; project-tab-groups.el --- Support a "one tab group per project" workflow -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Fritz Grabo

;; Author: Fritz Grabo <hello@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/project-tab-groups
;; Version: 0.1
;; Package-Requires: ((emacs "28"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; Support a "one tab group per project" workflow.

;;; Code:

(require 'seq)
(require 'project)

(eval-when-compile (require 'subr-x))

(defgroup project-tab-groups ()
  "Support a \"one tab group per project\" workflow."
  :group 'project)

(defcustom project-tab-groups-preserve-groupless-tab t
  "When non-nil, preserve the current groupless tab when switching projects."
  :type '(boolean))

(defvar project-tab-groups-tab-group-name-function
  #'project-tab-groups-tab-group-name
  "Function to find the tab group name for a directory.

The function is expected to take a directory as its single
argument and to return the tab group name to represent the
contained project.")

(defun project-tab-groups-tab-group-name (dir)
  "Derive tab group name for DIR.

Returns the value of directory-local variables `tab-group-name'
or `project-name', if present, and falls back to the directory
file name otherwise."
  (or (with-temp-buffer
        (setq default-directory dir)
        (hack-dir-local-variables-non-file-buffer)
        (or (and (boundp 'tab-group-name) tab-group-name)
            (and (boundp 'project-name) project-name)))
      (file-name-nondirectory (directory-file-name dir))))

(defun project-tab-groups--find-tab-by-group-name (tab-group-name)
  "Find the first tab that belongs to a group named TAB-GROUP-NAME."
  (seq-find
   (lambda (tab) (equal tab-group-name (alist-get 'group tab)))
   (funcall tab-bar-tabs-function)))

(defun project-tab-groups--select-or-create-tab-group (tab-group-name)
  "Select or create the first tab in a group named TAB-GROUP-NAME.

Returns non-nil if a new tab was created, and nil otherwise."
  (if-let ((tab (project-tab-groups--find-tab-by-group-name tab-group-name)))
      (progn
        (tab-bar-select-tab (1+ (tab-bar--tab-index tab)))
        nil)
    (tab-bar-new-tab)
    (tab-bar-change-tab-group tab-group-name)
    t))

(defun project-tab-groups--project-current-advice (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, then manage tab groups as needed.

Does nothing unless the user was allowed to be prompted for a
project if needed (that is, the `maybe-prompt' argument in the
adviced function call was non-nil), or if they did not select a
project when prompted.

Does nothing if the current tab belongs to the tab group of the
selected project already.

If the current tab does not belong to any group and if the value
of `project-tab-groups-preserve-groupless-tab' is nil, add it to
a tab group that represents the selected project.

Otherwise, select or create the first tab in a tab group that
represents the selected project."
  (let* ((result (funcall orig-fun args))
         (maybe-prompt (car args))
         (project-dir (and result (project-root result))))
    (when (and maybe-prompt project-dir)
      (let ((current-tab-group-name (alist-get 'group (tab-bar--current-tab)))
            (destination-tab-group-name (funcall project-tab-groups-tab-group-name-function project-dir)))
        (unless (equal current-tab-group-name destination-tab-group-name)
          (if (or current-tab-group-name project-tab-groups-preserve-groupless-tab)
              (project-tab-groups--select-or-create-tab-group destination-tab-group-name)
            (tab-bar-change-tab-group destination-tab-group-name)))))
    result))

(defun project-tab-groups--project-switch-project-advice (orig-fun &rest args)
  "Switch to the selected project's tab if it exists, call ORIG-FUN with ARGS otherwise."
  (let ((project-dir (or (car args) (project-prompt-project-dir))))
    (let ((tab-group-name (funcall project-tab-groups-tab-group-name-function project-dir)))
      (when (project-tab-groups--select-or-create-tab-group tab-group-name)
        (funcall orig-fun project-dir)))))

(defun project-tab-groups--project-kill-buffers-advice (orig-fun &rest args)
  "Call ORIG-FUN with ARGS, then close the current tab group, if any."
  (when (funcall orig-fun args)
    (when-let ((tab-group-name (alist-get 'group (tab-bar--current-tab))))
      (tab-bar-close-group-tabs tab-group-name))))

;;;###autoload
(define-minor-mode project-tab-groups-mode
  "Support a \"one tab group per project\" workflow."
  :group 'project
  :global t
  (dolist (name '(current switch-project kill-buffers))
    (let* ((f (intern (format "project-%s" name)))
           (advice (intern (format "project-tab-groups--%s-advice" f))))
      (if project-tab-groups-mode
          (advice-add f :around advice)
        (advice-remove f advice)))))

(provide 'project-tab-groups)
;;; project-tab-groups.el ends here
