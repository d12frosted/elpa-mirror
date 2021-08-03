;;; epkg-marginalia.el --- Show Epkg information in completion annotations  -*- lexical-binding: t -*-

;; Copyright (C) 2021  Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/emacscollective/epkg-marginalia
;; Keywords: tools
;; Package-Version: 20210802.1740
;; Package-Commit: 0879f5b2cf87fff17dcfb74009d289d6a89c9816
;; Package-Requires: ((emacs "26") (epkg "3.3.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3 of the License,
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

;; Out of the box marginalia enriches package completion with
;; information from the built-in package manager.  This packages
;; teaches it to additionally use the Epkgs database, and if the
;; Borg package manager is available, then it uses information
;; provided by that as well.

;;   (with-eval-after-load 'marginalia
;;     (cl-pushnew 'epkg-marginalia-annotate-package
;;                 (alist-get 'package marginalia-annotator-registry)))

;;; Code:

(require 'marginalia)

(require 'epkg)
(require 'borg nil t)

(eval-when-compile (require 'package))
(declare-function package--from-builtin "package")
(declare-function package-version-join "package")
(declare-function package-installed-p "package")
(defvar package-alist)
(defvar package-archive-contents)
(defvar package--builtins)

;;;###autoload
(defun epkg-marginalia-annotate-package (cand)
  "Annotate package CAND with its description summary.
Uses information provided by `borg', `epkg' and `package'."
  (require 'package)
  (let* ((name (replace-regexp-in-string "-[[:digit:]\\.-]+\\'" "" cand))
         (epkg (epkg name))
         (symb (intern name))
         (desc (or (car (alist-get symb package-alist))
                   (if-let (built-in (assq symb package--builtins))
                       (package--from-builtin built-in)
                     (car (alist-get symb package-archive-contents))))))
    (when (or epkg desc)
      (marginalia--fields
       ((if desc (package-version-join (package-desc-version desc)) "")
        :width 16
        :face 'marginalia-version)
       ((cond
         ((and desc (eq (package-desc-dir desc) 'builtin))
          (propertize "builtin" 'face 'marginalia-installed))
         ((and epkg
               (fboundp 'borg-drones)
               (member name (borg-drones)))
          (propertize "assimilated" 'face 'marginalia-installed))
         ((and epkg
               (fboundp 'borg-clones)
               (member name (borg-clones)))
          (propertize "cloned" 'face 'marginalia-installed))
         ((and desc (package-installed-p desc))
          (propertize "installed" 'face 'marginalia-installed))
         (epkg
          (propertize "mirror" 'face 'marginalia-archive))
         (desc
          (propertize (package-desc-archive desc) 'face 'marginalia-archive)))
        :width 11)
       ((or (and epkg (oref epkg summary))
            (and desc (package-desc-summary desc)))
        :truncate marginalia-truncate-width
        :face 'marginalia-documentation)))))

;;; _
(provide 'epkg-marginalia)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; epkg-marginalia.el ends here
