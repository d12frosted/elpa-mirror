;;; speedbar-git-respect.el --- Particular respect git repo in speedbar -*- lexical-binding: t -*-

;; Copyright (C) 2019 chendianbuji@gmail.com

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; Version: 0.1.1
;; Package-Version: 20200901.246
;; Package-Commit: dd8f0849fc1dd21b42380e1a8c28a9a29acd9511
;; Url: https://github.com/ukari/speedbar-git-respect
;; Author: Muromi Ukari <chendianbuji@gmail.com>
;; Package-Requires: ((f "0.8.0") (emacs "25.1"))

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This package will override the Emacs builtin speedbar-file-lists function
;; and change its behaviour when the directory is a git repo.
;;
;; The file list will show the following stuffs:
;; 1. All directorys and files tracked by git
;; 2. All directorys and files untracked by git but not matched in .gitignore
;;
;; The unicode filename or directory name won't display correct
;; unless disable the git's octal utf8 display.
;; To disable it, run `git config --global core.quotepath off`

;;; Code:
(require 'f)
(require 'speedbar)
(require 'vc-git)
(require 'seq)

(defgroup speedbar-git-respect nil "Particular respect git repo in speedbar" :group 'speedbar)

;;;###autoload
(define-minor-mode speedbar-git-respect-mode
  "Toggle speedbar-git-respect mode"
  :init-value nil
  :global t
  :lighter " Speedbar-Git"
  :group 'speedbar-git-respect
  (if speedbar-git-respect-mode
      (speedbar-git-respect--enable)
    (speedbar-git-respect--disable)))

(defun speedbar-git-respect--enable ()
  "Enable speedbar git respect mode."
  (setq speedbar-git-respect-mode t)
  (advice-add #'speedbar-file-lists :around #'speedbar-git-respect--speedbar-file-lists))

(defun speedbar-git-respect--disable ()
  "Disable speedbar git respect mode."
  (setq speedbar-git-respect-mode nil)
  (advice-remove #'speedbar-file-lists #'speedbar-git-respect--speedbar-file-lists))

(defun speedbar-git-respect--toggle ()
  "Toggle speedbar git respect mode."
  (if speedbar-git-respect-mode
      (speedbar-git-respect--disable)
    (speedbar-git-respect--enable)))

(defun speedbar-git-respect--vc-git-dir-p (directory)
  "Check if DIRECTORY a git repo."
  (eq 'Git (condition-case nil (vc-responsible-backend directory) (error nil))))

(defun speedbar-git-respect--speedbar-file-lists (origin directory)
  "Create file lists for DIRECTORY.
ORIGIN is function `speedbar-file-lists'"
  (if (speedbar-git-respect--vc-git-dir-p directory)
      (let ((origin-directory default-directory)
            (result))
        (setq default-directory directory)
        (setq result (speedbar-git-respect--git-file-lists directory))
        (setq default-directory origin-directory)
        result)
    (funcall origin directory)))

(defun speedbar-git-respect--git-file-lists (directory)
  "Create file lists for DIRECTORY which is git repo."
  (setq directory (expand-file-name directory))
  ;; find the directory, either in the cache, or build it.
  (or (and (not dframe-power-click) ;; In powerclick mode, always rescan.
           (cdr-safe (assoc directory speedbar-directory-contents-alist)))
      ;; tracked files and directory
      ;; git ls-files --directory
      ;; untracked files and directory
      ;; git ls-files --other --directory
      ;; untracked ignored
      ;; git ls-files --other --directory --ignored --exclude-standard
      (let ((tracked-fd (speedbar-git-respect--file-list-process (vc-git--run-command-string nil "ls-files" "--directory")))
            (untracked-fd (speedbar-git-respect--file-list-process (vc-git--run-command-string nil "ls-files" "--other" "--directory")))
            (untracked-ignored (speedbar-git-respect--file-list-process (vc-git--run-command-string nil "ls-files" "--other" "--directory" "--ignored" "--exclude-standard")))
            (dirs nil)
            (files nil))
        (setf dirs (seq-filter (lambda (x) (not (member x (car untracked-ignored)))) (car untracked-fd)))
        (setf files (seq-filter (lambda (x) (not (member x (cadr untracked-ignored)))) (cadr untracked-fd)))
        (setf dirs (delete-dups (append (car tracked-fd) dirs)))
        (setf files (delete-dups (append (cadr tracked-fd) files)))
        (setf dirs (seq-filter (lambda (x) (< 0 (length x))) dirs))
        (setf files (seq-filter (lambda (x) (< 0 (length x))) files))
        (setf dirs (sort dirs #'string>))
        (setf files (sort files #'string>))
	(let ((nl (cons (nreverse dirs) (list (nreverse files))))
              (ae (assoc directory speedbar-directory-contents-alist)))
          (if ae (setcdr ae nl)
            (push (cons directory nl)
                  speedbar-directory-contents-alist))
	  nl))))

(defun speedbar-git-respect--file-directory-split (path)
  "Split PATH with os path separator."
  (split-string path (f-path-separator)))

(defun speedbar-git-respect--file-list-process (list)
  "Process git ls-files result to a list.
LIST is a multiline string of pathnames."
  (setq list (split-string list "\n"))
  (let ((dirs nil)
        (files nil))
    (mapc (lambda (path)
            (let* ((res (speedbar-git-respect--file-directory-split path))
                   (name (car res)))
              (if (> (length res) 1)
                  (setq dirs (cons name dirs))
                (setq files (cons name files)))))
          list)
    (list (delete-dups dirs) files)))

(provide 'speedbar-git-respect)

;;; speedbar-git-respect.el ends here
