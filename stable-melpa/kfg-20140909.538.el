;;; kfg.el --- an emacs configuration system
;;
;; Author: Austin Bingham <austin.bingham@gmail.com>
;; Version:
;; Package-Version: 20140909.538
;; Package-Commit: ffc35b77f227d4c64a1271ec30d31333ffeb0013
;; URL: https://github.com/abingham/kfg
;; Package-Requires: ((f "0.17.1"))
;;
;; This file is not part of GNU Emacs.
;;
;; Copyright (c) 2014 Austin Bingham
;;
;;; Commentary:
;;
;; Description:
;;
;; The kfg emacs configuration system.
;;
;; This is the engine for a module emacs configuration system. Various
;; configuration modules should go in the "modules" directory. Put any
;; miscellaneous elisp files you need in the "elisp" directory. Then
;; execute this file.
;;
;; For more details, see the project page at
;; https://github.com/abingham/kfg.
;;
;; Installation:
;;
;; Copy kfg.el to some location in your emacs load path. Then add
;; "(require 'kfg)" to your emacs initialization (.emacs,
;; init.el, or something). Or just install the kfg package.
;; 
;;; License:
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Code:

(require 'cl)
(require 'f)
(require 'package)

;;;###autoload
(defun kfg-activate-modules (modules)
  "Install packages and configure all modules in MODULES. MODULES is a list of module metadata e.g. as returned by kfg--scan-metadata."
  (package-initialize)
  (kfg--install-packagess (kfg--find-all-packages modules))
  (kfg--configure-modules modules))

;;;###autoload
(defun kfg-activate-module (module-dir)
  (interactive
   (list
    (read-directory-name "Directory: ")))
  (let ((meta (kfg--read-metadata module-dir)))
    (kfg-activate-modules (list meta))))

;;;###autoload
(defun kfg-find-and-activate-modules (root-dir &optional filter)
  (let ((filter (or filter 'kfg--default-filter)))
    (kfg-activate-modules
     (remove-if-not
      filter
      (kfg--scan-metadata root-dir)))))

(defun kfg--dir-contents (dir)
  (remove "." (remove ".." (directory-files dir))))

(defun kfg--read-metadata (module-dir)
  "((:module module-dir) (:metadata META-FILE-CONTENTS))"
  (let ((init_file (f-join module-dir "meta.el")))
    (if (file-exists-p init_file)
        (with-temp-buffer
          (insert-file-contents init_file)
          `((:module ,module-dir)
            (:metadata . ,(eval (read (buffer-string)))))))))

(defun kfg--scan-metadata (modules-dir)
  "Load metadata of all modules found in MODULES-DIR. Returns a
list of module metadata."
  (remove
   nil
   (mapcar (lambda (d) (kfg--read-metadata (f-join modules-dir d)))
           (kfg--dir-contents modules-dir))))

(defun kfg--find-all-packages (modules)
  "Find all packages required MODULES. Returns the resulting set
of packages (i.e. no duplications.)"
  (delete-dups
   (apply 'append
          (mapcar
           (lambda (m) (assoc-default :packages (assoc-default :metadata m)))
           modules))))

(defun kfg--install-packagess (pkgs)
  "Install any packages in PKGS that are not installed. If any
packages need to be installed, the package index is updated
first."
  (unless (every 'package-installed-p pkgs)
    ;;check for new packages (package versions)
    (message "%s" "Missing packages detected. Refreshing its package database...")
    (package-refresh-contents)
    (message "%s" " done.")
    ;; install the missing packages
    (dolist (p pkgs)
      (when (not (package-installed-p p))
        (package-install p)))))

(defun kfg--configure-modules (modules)
  (dolist (c modules)
    (let* ((module-dir (cadr (assoc :module c)))
	   (config-file (f-join module-dir "config.el")))
      (if (file-exists-p config-file)
	  (let ((profile (benchmark-run (load-file config-file))))
	    (message "Configured %s. Profile = %s"
		     module-dir profile))
	(warn (format "No config.el for %s" module-dir))))))

(defun kfg--default-filter (module)
  (assoc-default :enabled (assoc-default :metadata module)))

(provide 'kfg)

;;; kfg.el ends here
