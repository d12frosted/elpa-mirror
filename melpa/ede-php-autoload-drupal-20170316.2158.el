;;; ede-php-autoload-drupal.el --- Drupal support for ede-php-autoload  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Thomas Fini Hansen

;; Author: Thomas Fini Hansen <xen@xen.dk>
;; Created: February 16, 2017
;; Version: 0.1.0
;; Package-Version: 20170316.2158
;; Package-Commit: 54a04241d94fabc4f4d16ae4dc8ba4f0c6e3b435
;; Package-Requires: ((ede-php-autoload "1.0.0") (f "0.19.0") (s "1.7.0"))
;; Keywords: programming, php, drupal

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

;; Add support for Drupal 8+ to ede-php-autoload.
;;
;; Supplies ede-php-autoload with information on the classes located
;; in modules in a Drupal project. All modules found in core/modules,
;; modules, profiles/<profile>/modules and sites/<sites, including
;; default and all>/modules is added.
;;
;; As Drupal uses composer/installers,
;; ede-php-autoload-composer-installers is required for practical use.

;;; Code:

(require 'ede-php-autoload)
(require 'f)
(require 's)

(defun ede-php-autoload-drupal-autoloads (context autoloads)
  "Visitor that add Drupal module autoloads.

CONTEXT is the composer context and AUTOLOADS are the currently
found autoloads."
  (let* ((core-path (ede-php-autoload-drupal--core-path autoloads))
         (drupal-root (if core-path (f-dirname core-path)))
         (module-autoloads ()))
    (when core-path
      (setq autoloads
            (ede-php-autoload-composer-merge-autoloads
             (list :psr-4
                   (cl-loop for (module . path)
                            in (ede-php-autoload-drupal--filter-modules
                                (ede-php-autoload-drupal--find-modules drupal-root))
                            collect (cons (concat "Drupal\\" module)
                                          (f-join drupal-root path "src"))))
             autoloads))))
  autoloads)

(defun ede-php-autoload-drupal--core-path (autoloads)
  "Check for Drupal core in AUTOLOADS and return path if found."
  (let* ((psr4 (member :psr-4 autoloads))
         path)
    (if psr4
      (let* ((path (cdr (assoc "Drupal\\Core" (car (cdr psr4)))))
             (path (if (listp path) (car path) path)))
        (if path (f-parent (f-parent (f-parent path)))))
      nil)))

(defun ede-php-autoload-drupal--find-modules (path)
  "Scan Drupal PATH and return all modules as (name . path)."
  (let* ((paths (append
                 ;; Drupal core modules.
                 (list (f-join path "core"))
                 ;; Profiles.
                 (ede-php-autoload-drupal--find-dirs-with-modules (f-join path "profiles"))
                 ;; Site wide modules.
                 (list path)
                 ;; All sites. Includes sites/all.
                 (ede-php-autoload-drupal--find-dirs-with-modules (f-join path "sites"))))
         (yaml-files (cl-loop for path in paths
                              append (if (f-exists? (f-join path "modules"))
                                         (f--entries (f-join path "modules")
                                                     (s-matches? "\\.info\\.yml$"
                                                                 (f-filename it))
                                                 t))))
         (modules (cl-loop for yaml in yaml-files
                           collect (cons (f-no-ext (f-no-ext (f-filename yaml)))
                                         (f-relative (f-dirname yaml) path)))))
    modules))

(defun ede-php-autoload-drupal--find-dirs-with-modules (path)
  "Return directories in PATH which contain a `modules' directory."
  (when (f-exists? path)
    (f--directories path (f-directory? (f-join it "modules")))))

(defun ede-php-autoload-drupal--filter-modules (modules)
  "Filters blacklisted paths from MODULES.

MODULES is a list of (name . path) cons cells."
  (let ((filtered ())
        (blacklist (concat "\\("
                           (s-join "\\|"
                                   ;; Directories that's skipped by Drupal.
                                   ;; List gotten from Drupal\Core\Extension\Discovery\RecursiveExtensionFilterIterator.
                                   (list "src" "lib" "vendor" "assets" "css" "files"
                                         "images" "js" "misc" "templates" "includes"
                                         "fixtures" "Drupal" "config" "tests"))
                           "\\)")))
    (cl-loop for (name . path) in modules
             do (cond
                 ;; modules/config is a special case.
                 ( (s-matches? "modules/config$" path)
                   (setq filtered (push (cons name path) filtered)))
                 ((s-matches? (concat
                               "\\(/\\|^\\)" ;; Slash or start of string.
                               blacklist
                               "\\(/\\|$\\)" ;; Slash or end of string.
                               ) path))
                 (t (setq filtered (push (cons name path) filtered)))))
    ;; Reverse list again, so the ordering stays the same.
    (reverse filtered)))

(ede-php-autoload-composer-define-visitor #'ede-php-autoload-drupal-autoloads :late)

(provide 'ede-php-autoload-drupal)
;;; ede-php-autoload-drupal.el ends here
