;;; sisyphus.el --- Create releases of Emacs packages  -*- lexical-binding:t -*-

;; Copyright (C) 2022 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/magit/sisyphus
;; Keywords: git tools vc
;; Package-Commit: 1018df74396211c42403e20f6e96dfdf39c2f582

;; Package-Version: 20221127.2255
;; Package-X-Original-Version: 0.1.0.50-git
;; Package-Requires: (
;;     (emacs "27")
;;     (compat "28.1.1.0")
;;     (elx "1.6.0")
;;     (llama "0.3.0")
;;     (magit "3.4.0"))

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
(require 'llama)

(require 'elx)
(require 'magit-tag)

;;; Key Bindings

(transient-insert-suffix 'magit-tag "r"
  '("c" "release commit" sisyphus-create-release))

(transient-suffix-put 'magit-tag "r" :description "release tag")

(transient-append-suffix 'magit-tag "r"
  '("g" "post release commit" sisyphus-bump-post-release))

;;; Variables

(defvar sisyphus--non-release-suffix ".50-git"
  "String appended to version strings for non-release revisions.")

;;; Commands

;;;###autoload
(defun sisyphus-create-release (version &optional nocommit)
  "Create a release commit, bumping version strings.
With prefix argument NOCOMMIT, do not create a commit."
  (interactive (list (sisyphus--read-version)))
  (magit-with-toplevel
    (sisyphus--bump-changelog version)
    (sisyphus--bump-version version)
    (unless nocommit
      (sisyphus--commit (format "Release version %s" version)))))

;;;###autoload
(defun sisyphus-bump-post-release (version &optional nocommit)
  "Create a post-release commit, bumping version strings.
With prefix argument NOCOMMIT, do not create a commit."
  (interactive (list (and (file-exists-p (expand-file-name "CHANGELOG"))
                          (sisyphus--read-version "Tentative next release"))
                     current-prefix-arg))
  (magit-with-toplevel
    (sisyphus--bump-changelog version t)
    (sisyphus--bump-version (concat (sisyphus--previous-version)
                                    sisyphus--non-release-suffix))
    (unless nocommit
      (sisyphus--commit "Resume development"))))

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
           (prog1 (progn ,@body)
             (save-buffer)
             (unless ,open*
               (kill-buffer))))))))

;;; Functions

(defun sisyphus--package-name ()
  (file-name-nondirectory (directory-file-name (magit-toplevel))))

(defun sisyphus--previous-version ()
  (caar (magit--list-releases)))

(defun sisyphus--get-changelog-version ()
  (let ((file (expand-file-name "CHANGELOG")))
    (and (file-exists-p file)
         (sisyphus--with-file file
           (and (re-search-forward "^\\* v\\([^ ]+\\)" nil t)
                (match-string-no-properties 1))))))

(defun sisyphus--read-version (&optional prompt)
  (let* ((prev (sisyphus--previous-version))
         (next (sisyphus--get-changelog-version))
         (version (read-string
                   (if prev
                       (format "%s (previous was %s): "
                               (or prompt "Create release")
                               prev)
                     "Create first release: ")
                   (cond ((and next
                               (or (not prev)
                                   (magit--version> next prev)))
                          next)
                         (prev
                          (let ((v (version-to-list prev)))
                            (mapconcat #'number-to-string
                                       (nconc (butlast v)
                                              (list (1+ (car (last v)))))
                                       ".")))))))
    (when (and prev (not (magit--version> version prev)))
      (user-error "Version must increase, but %s is not greater than %s"
                  version prev))
    version))

(defun sisyphus--bump-changelog (version &optional stub)
  (let ((file (expand-file-name "CHANGELOG")))
    (when (file-exists-p file)
      (sisyphus--with-file file
        (if (re-search-forward "^\\* v\\([^ ]+\\) +\\(.+\\)$" nil t)
            (let ((vers (match-string-no-properties 1))
                  (date (match-string-no-properties 2))
                  (prev (sisyphus--previous-version))
                  (today (format-time-string "%F")))
              (goto-char (line-beginning-position))
              (cond
               (stub
                (insert (format "* v%-9sUNRELEASED\n\n" version)))
               ((equal vers prev)
                (insert (format "* v%-9s%s\n\n" version today))
                (user-error "CHANGELOG entry missing; inserting stub"))
               ((equal vers version)
                (unless (equal date today)
                  (replace-match today nil t nil 2)))
               ((y-or-n-p
                 (format "%sCHANGELOG version is %s, change%s to %s"
                         (if prev (format "Previous version is %s, " prev) "")
                         vers
                         (if prev " latter" "")
                         version))
                (delete-region (point) (line-end-position))
                (insert (format "* v%-9s%s" version today)))
               ((user-error "Abort"))))
          (user-error "Unsupported CHANGELOG format"))))))

(defun sisyphus--bump-version (version)
  (let* ((lisp (if (file-directory-p "lisp") "lisp" "."))
         (docs (if (file-directory-p "docs") "docs" "."))
         (pkgs (nconc (directory-files lisp t "-pkg\\.el\\'")
                      (and (equal lisp "lisp")
                           (directory-files "." t "-pkg\\.el\\'"))))
         (libs (cl-set-difference (directory-files lisp t "\\.el\\'") pkgs))
         (orgs (cl-delete "README.org" (directory-files docs t "\\.org\\'")
                          :test #'equal :key #'file-name-nondirectory))
         (updates (mapcar (lambda (lib)
                            (list (intern
                                   (file-name-sans-extension
                                    (file-name-nondirectory lib)))
                                  version))
                          libs))
         (pkg-updates (if (string-suffix-p sisyphus--non-release-suffix version)
                          (let ((timestamp (format-time-string "%Y%m%d")))
                            (mapcar (pcase-lambda (`(,pkg ,_)) (list pkg timestamp))
                                    updates))
                        updates)))
    (mapc (##sisyphus--edit-package % version pkg-updates) pkgs)
    (mapc (##sisyphus--edit-library % version updates) libs)
    (mapc (##sisyphus--edit-manual  % version) orgs)))

(defun sisyphus--edit-package (file version updates)
  (sisyphus--with-file file
    (pcase-let* ((`(,_ ,name ,_ ,docstring ,deps . ,props)
                  (read (current-buffer)))
                 (deps (cadr deps)))
      (erase-buffer)
      (insert (format "(define-package %S %S\n  %S\n  '("
                      name version docstring))
      (when deps
        (setq deps (elx--update-dependencies deps updates))
        (let ((dep nil)
              (format
               (format "(%%-%is %%S)"
                       (apply #'max
                              (mapcar (##length (symbol-name (car %))) deps)))))
          (while (setq dep (pop deps))
            (indent-to 4)
            (insert (format format (car dep) (cadr dep)))
            (when deps (insert "\n")))))
      (insert ")")
      (when props
        (let (key val)
          (while (setq key (pop props) val (pop props))
            (insert (format "\n  %s %S" key val)))))
      (insert ")\n"))))

(defun sisyphus--edit-library (file version updates)
  (sisyphus--with-file file
    (when (lm-header "Package-Version")
      (delete-region (point) (line-end-position))
      (insert version)
      (goto-char (point-min)))
    (when (re-search-forward
           (format "(defconst %s-version \"\\([^\"]+\\)\""
                   (file-name-sans-extension
                    (file-name-nondirectory file)))
           nil t)
      (replace-match version nil t nil 1)
      (goto-char (point-min)))
    (unless (string-suffix-p "-git" version)
      (elx-update-package-requires nil updates nil t)
      (let ((prev (sisyphus--previous-version)))
        (while (re-search-forward
                ":package-version '([^ ]+ +\\. +\"\\([^\"]+\\)\")" nil t)
          (let ((found (match-string-no-properties 1)))
            (when (and (magit--version> found prev)
                       (version< found version))
              (replace-match version nil t nil 1))))))
    (save-buffer)))

(defun sisyphus--edit-manual (file version)
  (sisyphus--with-file file
    (re-search-forward "^#\\+subtitle: for version \\(.+\\)$")
    (replace-match version t t nil 1)
    (re-search-forward "^This manual is for [^ ]+ version \\(.+\\)\\.$")
    (replace-match version t t nil 1))
  (magit-call-process "make" "texi"))

(defun sisyphus--commit (msg)
  (let ((magit-inhibit-refresh t))
    (magit-stage-1 "-u"))
  (magit-commit-create
   (list "--edit" "--message" msg
         (if (eq transient-current-command 'magit-tag)
             (and-let* ((key (transient-arg-value
                              "--local-user=" (transient-args 'magit-tag))))
               (concat "--gpg-sign=" key))
           (transient-args 'magit-commit)))))

;;; _
(provide 'sisyphus)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; sisyphus.el ends here
