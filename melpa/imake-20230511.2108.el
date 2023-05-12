;;; imake.el --- Simple, opinionated make target runner  -*- lexical-binding:t -*-

;; Copyright (C) 2017-2023 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/imake
;; Keywords: convenience
;; Package-Version: 20230511.2108
;; Package-Commit: 96ac809dbe9cae0e620bb5b1d5d1fb391f3f4741

;; Package-Requires: ((emacs "25.1") (compat "29.1.4.1"))

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

;; This package provides the command `imake', which prompts for
;; make targets and runs them in the current directory.

;; If the `marginalia' package is available and some targets are
;; documented as shown below, using one or more targets whose
;; names begin with "help", then that documentation is shown.

;;   help helpall::
;;           $(info make lisp  - generate byte-code and autoloads)
;;   helpall::
;;           $(info make clean - remove generated files)

;;; Code:

(require 'compat)
(require 'subr-x)

(require 'marginalia nil t)

(defvar marginalia-command-categories)
(defvar marginalia-annotator-registry)

(defvar crm-separator)

(defvar imake--target-alist nil)

(defvar imake-history nil)

;;;###autoload
(defun imake (targets)
  "Read one or make TARGETS and run them."
  (interactive
   (let ((crm-separator "\\(?:[ \t]*,[ \t]*\\|[ \t]+\\)")
         (imake--target-alist (and (require 'marginalia nil t)
                                   (imake-target-alist))))
     (list (completing-read-multiple "Targets: " (imake-targets)
                                     nil nil nil 'imake-history))))
  (async-shell-command
   (mapconcat #'shell-quote-argument (cons "make" targets) " ")))

(defun imake-targets ()
  "Return a complete list of make targets."
  (thread-last (split-string (shell-command-to-string "\
make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:\
([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}' | \
sort -u") "\n")
    (delete "Makefile")
    (delete "")))

(defun imake-target-alist ()
  "Return an alist of documented make targets."
  (and (file-exists-p "Makefile")
       (let (targets)
         (with-temp-buffer
           (save-excursion
             (insert-file-contents "Makefile"))
           (while (re-search-forward "^help[^:]*:" nil t)
             (while (re-search-forward "\
^\t$(info make \\(\\(\\([^ ]*\\) *\\(?:- \\)?\\)\\([^)]*\\)\\))" nil t)
               (let ((name (match-string-no-properties 3))
                     (desc (match-string-no-properties 4)))
                 (if (string-match-p "\\`\\[[^]]+\\]\\'" name)
                     (dolist (name (split-string (substring name 1 -1) "|"))
                       (push (cons name desc) targets))
                   (push (cons name desc) targets))))))
         (nreverse targets))))

(with-eval-after-load 'marginalia
  (defun emir-annotate-make-target (target)
    (marginalia--fields
     ((or (cdr (assoc target imake--target-alist)) ""))))
  (add-to-list 'marginalia-command-categories '(imake . imake))
  (add-to-list 'marginalia-annotator-registry
               '(imake emir-annotate-make-target)))

(provide 'imake)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; imake.el ends here
