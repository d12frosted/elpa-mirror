;;; elpa-deploy.el --- ELPA deployment library  -*- lexical-binding: t -*-

;; Copyright (C) 2019 Bruno Félix Rezende Ribeiro <oitofelix@gnu.org>

;; Author: Bruno Félix Rezende Ribeiro <oitofelix@gnu.org>
;; Keywords: tools
;; Package-Version: 20191022.718
;; Package-Commit: f5126a2da1e0e52981fad9c12028814be80328c2
;; Package: elpa-deploy
;; Homepage: https://github.com/oitofelix/elpa-deploy

;; Version: 20191022.411
;; Package-Requires: ((emacs "24.4") (f "0.0"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides ‘elpa-deploy’: a complement to the function
;; ‘package-upload-file’ from ‘package-x.el’, which automatizes the
;; deployment of simple and multi-file packages.  This function
;; automatizes the upload of a library to an ELPA directory so that no
;; other action is needed.  Particularly useful for rapid ELPA
;; deployment aiding testing and releases.  The procedures
;; automatically taken care of consist of updating the version field
;; of a package source using the current time-stamp, generating its
;; tar archive if multi-file, and uploading the results to a specified
;; ELPA directory, while deleting any previous version of the same
;; package already deployed.

;;; Code:


(require 'package-x)
(require 'lisp-mnt)
(require 'f)


;;;###autoload
(cl-defun elpa-deploy
    (path upload-base &aux
	  (version (format "%d.%d"
                           (string-to-number (format-time-string "%Y%m%d"))
                           (string-to-number (format-time-string "%H%M"))))
	  (package-name (f-base path)))
  "Deploy simple or multi-file package.
PATH is the filename of a single ‘.el’ file (simple package) or a
directory containing a ‘*-pkg.el’ file (multi-file package).
UPLOAD-BASE is the target ELPA directory.

This function updates the version field of the package source
in-place -- using the current timestamp, then it generates its
tar archive (in the multi-file case), *deletes* any previously
deployed version of the same package in UPLOAD-BASE and finally
uploads the result.

See ‘package-archive-upload-base’ for the exact meaning of
UPLOAD-BASE."
  (interactive "GPackage file or directory: \nDArchive upload base directory: ")
  (pcase path
    ((pred file-regular-p)
     (elpa-deploy--update-version-string-simple-package path version)
     (mapc #'delete-file
	   (directory-files
	    upload-base 'full
	    (format "^%s-[[:digit:]]\\{8\\}\\.[[:digit:]]\\{3,4\\}\\.el$"
                    package-name)))
     (let ((package-archive-upload-base upload-base))
       (package-upload-file path)))
    ((and (pred file-directory-p)
	  (let file (f-expand (f-join (f-parent path)
                                      (format "%s-%s.tar"
                                              package-name version)))))
     (elpa-deploy--update-version-string-multi-file-package path version)
     (call-process "tar" nil nil nil "--create"
		   "--file" file
		   (format "--transform=s,^%s,%s-%s,"
                           package-name package-name version)
                   "--exclude-vcs"
                   "--exclude-backups"
                   "--exclude=*.elc"
                   (format "--exclude=%s-autoloads.el" package-name)
                   (format "--directory=%s" (f-dirname file))
		   (f-relative path (f-dirname file)))
     (mapc #'delete-file
	   (directory-files
	    upload-base 'full
	    (format "^%s-[[:digit:]]\\{8\\}\\.[[:digit:]]\\{3,4\\}\\.tar$"
                    package-name)))
     (let ((package-archive-upload-base upload-base))
       (package-upload-file file))
     (delete-file file))))

(defun elpa-deploy--update-version-string-simple-package (file version)
  "Update version string of simple package FILE to VERSION.
The header \"Package-Version\" takes precedence over \"Version\".
Having none previous to the invocation of this function is an error."
  (with-current-buffer (find-file-noselect file)
    (save-excursion
      (goto-char (point-min))
      (when (or (re-search-forward (lm-get-header-re "package-version")
                                   (lm-code-mark) t)
		(re-search-forward (lm-get-header-re "version")
                                   (lm-code-mark) t)
		(error
                 "Package lacks a \"Version\" or \"Package-Version\" header"))
	(kill-line)
	(just-one-space)
	(insert version)
	(save-buffer)))))

(cl-defun elpa-deploy--update-version-string-multi-file-package
    (dir version &aux (pkg-file (f-join dir (format "%s-pkg.el" (f-base dir)))))
  "Update version string of multi-file package inside directory DIR to VERSION.
Presumably file ‘*-pkg.el’ has the ‘define-package’ form as its first."
  (with-current-buffer (or (and (file-exists-p pkg-file)
				(find-file-noselect pkg-file))
			   (error "Package definition file ‘%s’ doesn’t exist"
				  (f-filename pkg-file)))
    (save-excursion
      (goto-char (point-min))
      (when (or (package-process-define-package (read (current-buffer)))
		(error "Can’t find ‘define-package’ in %s" pkg-file))
        (goto-char (point-min))
	(down-list)
	(forward-sexp 2)
	(kill-sexp)
	(just-one-space)
	(insert (format "\"%s\"" version))
	(save-buffer)))))


(provide 'elpa-deploy)

;;; elpa-deploy.el ends here
