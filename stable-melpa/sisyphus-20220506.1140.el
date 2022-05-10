;;; sisyphus.el --- Create releases of Emacs packages  -*- lexical-binding:t -*-

;; Copyright (C) 2022 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/magit/sisyphus
;; Keywords: git tools vc
;; Package-Commit: 9626d9d26dc9f3cc57d41fa119a74e0cb1c4aab9

;; Package-Version: 20220506.1140
;; Package-X-Original-Version: 0.1.0-git
;; Package-Requires: ((emacs "27") (compat "28.1.1.0") (magit "3.4.0"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Create a release and watch it roll down the hill again.

;; Recommended setup:
;;   (with-eval-after-load 'magit (require 'sisyphus))

;;; Code:

(require 'compat)

(require 'magit-tag)

;;; Key Bindings

(transient-insert-suffix 'magit-tag "r"
  '("c" "release commit" sisyphus-create-release))

(transient-suffix-put 'magit-tag "r" :description "release tag")

(transient-append-suffix 'magit-tag "r"
  '("g" "post release commit" sisyphus-bump-post-release))

;;; Commands

;;;###autoload
(defun sisyphus-create-release (version)
  "Create a release commit, bumping version strings."
  (interactive
   (let ((prev (caar (magit--list-releases))))
     (list (read-string (if prev
                            (format "Create release (previous was %s): " prev)
                          "Create first release: ")
                        prev))))
  (when-let ((prev (caar (magit--list-releases))))
    (cond ((equal version prev)
           (user-error "Version must change: %s -> %s" prev version))
          ((version< version prev)
           (user-error "Version must increase: %s -> %s" prev version))))
  (magit-with-toplevel
    (let ((name (sisyphus--package-name)))
      (sisyphus--check-changelog name version)
      (sisyphus--edit-library name version)
      (sisyphus--edit-manual name version)
      (when (equal name "magit")
        (sisyphus--edit-magit version)))
    (sisyphus--commit (format "Release version %s" version))
    (magit-show-commit "HEAD")))

;;;###autoload
(defun sisyphus-bump-post-release ()
  "Create a post-release commit, bumping version strings."
  (interactive)
  (magit-with-toplevel
    (let ((name (sisyphus--package-name))
          (version (concat (caar (magit--list-releases)) "-git")))
      (sisyphus--edit-library name version)
      (sisyphus--edit-manual name version)
      (when (equal name "magit")
        (sisyphus--edit-magit version)))
    (sisyphus--commit "Resume development")
    (magit-show-commit "HEAD")))

;;; Macros

(defmacro sisyphus--with-file (file &rest body)
  (declare (indent 1))
  (let ((file* (gensym "file"))
        (open* (gensym "open")))
    `(let* ((,file* ,file)
            (,open* (find-buffer-visiting ,file*)))
       (with-current-buffer (find-file-noselect ,file*)
         (save-excursion
           (goto-char (point-min))
           ,@body)
         (save-buffer)
         (unless ,open*
           (kill-buffer (current-buffer)))))))

;;; Functions

(defun sisyphus--edit-library (name version)
  (let ((file (expand-file-name (format "%s.el" name))))
    (unless (file-exists-p file)
      (setq file (expand-file-name (format "lisp/%s.el" name))))
    (if (file-exists-p file)
        (sisyphus--with-file file
          (when (re-search-forward "^;; Package-Version: \\(.+\\)$" nil t)
            (replace-match version t t nil 1)
            (save-buffer)))
      (error "Library %s.el not found" name))))

(defun sisyphus--edit-manual (name version)
  (let ((file (expand-file-name (format "docs/%s.org" name))))
    (when (file-exists-p file)
      (sisyphus--with-file file
        (re-search-forward "^#\\+subtitle: for version \\(.+\\)$")
        (replace-match version t t nil 1)
        (re-search-forward "^This manual is for [^ ]+ version \\(.+\\)\\.$")
        (replace-match version t t nil 1))
      (magit-call-process "make" "texi"))))

(defun sisyphus--edit-magit (version)
  (sisyphus--edit-pkg "git-commit" version)
  (sisyphus--edit-pkg "magit" version)
  (sisyphus--edit-pkg "magit-libgit" version)
  (sisyphus--edit-pkg "magit-section" version)
  (sisyphus--edit-library "git-commit" version)
  (sisyphus--edit-library "magit-libgit" version)
  (sisyphus--edit-library "magit-section" version)
  (sisyphus--edit-manual "magit-section" version))

(defun sisyphus--edit-pkg (name version)
  (let ((file (expand-file-name (format "lisp/%s-pkg.el" name))))
    (when (file-exists-p file)
      (sisyphus--with-file file
        (re-search-forward "^(define-package \"[^\"]+\" \"\\([^\"]+\\)\"$")
        (replace-match version t t nil 1)))))

(defun sisyphus--check-changelog (_name version)
  (let ((file (expand-file-name "CHANGELOG")))
    (when (file-exists-p file)
      (sisyphus--with-file file
        (cond
         ((not (re-search-forward
                (format-time-string
                 (format "^\\* v%s    \\(%%F$\\)?" version))
                nil t))
          (user-error "CHANGELOG entry missing"))
         ((not (match-end 1))
          (user-error "CHANGELOG entry unfinished")))))))

(defun sisyphus--commit (msg)
  (magit-run-git
   "commit" "-a" "-m" msg
   (if (eq transient-current-command 'magit-tag)
       (and-let* ((key (transient-arg-value
                        "--local-user=" (transient-args 'magit-tag))))
         (concat "--gpg-sign=" key))
     (transient-args 'magit-commit))))

(defun sisyphus--package-name ()
  (file-name-nondirectory (directory-file-name (magit-toplevel))))

;;; _
(provide 'sisyphus)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; sisyphus.el ends here
