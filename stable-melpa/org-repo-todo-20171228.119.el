;;; org-repo-todo.el --- Simple repository todo management with org-mode -*- lexical-binding: t -*-

;; Copyright (C) 2014-2017 justin talbott

;; Author: justin talbott <justin@waymondo.com>
;; Keywords: convenience
;; Package-Version: 20171228.119
;; Package-Commit: f73ebd91399c5760ad52c6ad9033de1066042003
;; URL: https://github.com/waymondo/org-repo-todo
;; Version: 0.0.3

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

;; This is a simple package for capturing and visiting todo items for
;; the repository you are currently within.  Under the hood it uses
;; `org-capture' to provide a popup window for inputting `org-mode'
;; checkboxed todo items (http://orgmode.org/manual/Checkboxes.html)
;; or regular ** TODO items that get saved to a TODO.org file in the
;; root of the repository.
;;
;; Install is as easy as dropping this file into your load path and setting
;; the relevent functions to keybindings of your choice, i.e.:
;;
;;   (global-set-key (kbd "C-;") 'ort/capture-todo)
;;   (global-set-key (kbd "C-'") 'ort/capture-checkitem)
;;   (global-set-key (kbd "C-`") 'ort/goto-todos)
;;

;;; Code:

(require 'org-capture)

(defvar ort/todo-root)
(defvar ort/template)

(defgroup org-repo-todo nil
  "Simple repository todo management with `org-mode'."
  :version "0.0.2"
  :link '(url-link "https://github.com/waymondo/org-repo-todo")
  :group 'convenience)

(defcustom ort/prefix-arg-directory user-emacs-directory
  "This is the alternate directory to visit/capture to with the `C-u' prefix."
  :group 'org-repo-todo
  :type 'directory)

(autoload 'vc-git-root "vc-git")
(autoload 'vc-svn-root "vc-svn")
(autoload 'vc-hg-root "vc-hg")

(push '("ort/todo" "Org Repo Todo"
        entry
        (file+headline "TODO.org" "Todos")
        "* TODO  %?\t\t\t%T\n %i\n Link: %l\n")
      org-capture-templates)

(push '("ort/checkitem" "Org Repo Checklist Item"
        checkitem
        (file+headline "TODO.org" "Checklist"))
      org-capture-templates)

(defun ort/todo-file ()
  "Find the TODO.org file for the current root directory."
  (concat ort/todo-root "TODO.org"))

(defun ort/find-root (&optional arg-directory)
  "Find the repo root of the current directory.
With the argument ARG-DIRECTORY, find `ort/prefix-arg-directory'."
  (let ((ort/dir (if arg-directory ort/prefix-arg-directory default-directory)))
    (or (vc-git-root ort/dir)
        (vc-svn-root ort/dir)
        (vc-hg-root ort/dir)
        ort/dir)))

;;;###autoload
(defun ort/goto-todos (&optional arg-directory)
  "Visit the current repo's TODO.org file.
With the argument ARG-DIRECTORY, visit `ort/prefix-arg-directory''s
TODO.org file."
  (interactive "P")
  (let ((ort/todo-root (ort/find-root arg-directory)))
    (find-file (ort/todo-file))))

(defun ort/capture (&optional arg-directory)
  "Create a small `org-mode' capture window.
Items will be captured into the project root.
If ARG-DIRECTORY is supplied, capture into `ort/prefix-arg-directory'."
  ;; make window split horizontally
  (let* ((split-width-threshold nil)
         (split-height-threshold 0)
         (ort/todo-root (ort/find-root arg-directory))
         (org-directory ort/todo-root))
    (org-capture nil ort/template)
    (fit-window-to-buffer nil nil 5)))

;;;###autoload
(defun ort/capture-todo (&optional arg-directory)
  "Capture an org todo for the current repo in an `org-capture' popup window.
Items will be captured into the project root.
If ARG-DIRECTORY is supplied, capture into `ort/prefix-arg-directory'."
  (interactive "P")
  (let ((ort/template "ort/todo"))
    (ort/capture arg-directory)))

;;;###autoload
(defun ort/capture-checkitem (&optional arg-directory)
  "Capture a checkitem for the current repo in an `org-capture' popup window.
Items will be captured into the project root.
If ARG-DIRECTORY is supplied, capture into `ort/prefix-arg-directory'."
  (interactive "P")
  (let ((ort/template "ort/checkitem"))
    (ort/capture arg-directory)))

(provide 'org-repo-todo)
;;; org-repo-todo.el ends here
