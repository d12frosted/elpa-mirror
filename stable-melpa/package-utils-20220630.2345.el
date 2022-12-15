;;; package-utils.el --- Extensions for package.el  -*- lexical-binding: t -*-

;; Author: Philippe Vaucher <philippe.vaucher@gmail.com>
;; URL: https://github.com/Silex/package-utils
;; Keywords: package, convenience
;; Version: 1.0.1
;; Package-Requires: ((restart-emacs "0.1.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This library provides extensions for package.el
;;
;;; Code:

(require 'package)
(require 'cl-lib) ;; For `cl-letf'.

(defmacro package-utils-with-packages-list (packages &rest body)
  "List PACKAGES inside a `package-list-packages' buffer and evaluate BODY.

PACKAGES should be a list of packages, or t for all packages.
See the second argument to `package-menu--generate'."
  (declare (indent 1))
  `(with-temp-buffer
     (package-menu-mode)
     (package-menu--generate nil ,packages)
     ,@body))

(defun package-utils-upgradable-packages ()
  "Return the list of upgradable packages as a list of symbols."
  (package-utils-with-packages-list t
    (mapcar #'car (package-menu--find-upgrades))))

(defun package-utils-installed-packages ()
  "Return the list of installed packages as a list of symbols."
  (reverse (mapcar #'car package-alist)))

(defun package-utils-read-upgradable-package ()
  "Read the name of a package to upgrade."
  (intern (completing-read "Upgrade package: "
                           (mapcar #'symbol-name (package-utils-upgradable-packages))
                           nil
                           'require-match)))

(defun package-utils-upgradable-p (name)
  "Return true if NAME can be upgraded, nil otherwise."
  (not (null (member name (package-utils-upgradable-packages)))))

(defun package-utils-installed-p (name)
  "Return true if NAME is installed, nil otherwise."
  (not (null (member name (package-utils-installed-packages)))))

(defun package-utils--byte-recompile-all-packages ()
  "Recompile all `byte-code' for all packages in `package-alist'."
  ;; We could use `load-paths', instead - find all package paths.
  (let ((load-path-extracted
         (mapcar (lambda (item)
                   (pcase-let ((`(,_pkg-key . ,pkg-desc) item))
                     (package-desc-dir (car pkg-desc))))
                 package-alist))
        (load-paths-to-compile (list))
        (cache-delete-len 0)
        (emacs-binary (executable-find (car command-line-args)))
        (message-log-max nil)
        (print-fn (if noninteractive
                      (lambda (_proc str) (princ str))
                    (lambda (_proc str) (message str)))))

    (unless emacs-binary
      (user-error "Cannot find Emacs own binary!"))

    ;; First run emacs, dumping the load paths into a temporary file.
    (dolist (p load-path-extracted)
      ;; When upgrading, the previous load path from the older
      ;; package is still in the list,
      ;; even though it has been deleted.
      (when (file-directory-p p)
        ;; Safety check that we have write permissions.
        (when (file-writable-p p)
          (push p load-paths-to-compile))))

    ;; Clearing.
    (dolist (p load-paths-to-compile)
      (dolist (cache-file (directory-files p t "\\.elc\\'"))
        (delete-file cache-file)
        (setq cache-delete-len (1+ cache-delete-len))))

    (message "Removed: %d '.elc' file(s) from %d path(s)"
             cache-delete-len
             (length load-paths-to-compile))

    ;; Now run a fresh Emacs instance with the load paths set,
    ;; recompile all directories.
    (let ((proc-script
           ;; The script to recompile code, passed to the `stdin'.
           (concat
            "(let ((paths '" (prin1-to-string load-paths-to-compile) "))"
            "(nconc load-path paths)"
            "(dolist (p paths) (byte-recompile-directory p 0 t)))"))
          (proc
           (make-process
            :name "emacs-recompile-all-proc"
            :filter print-fn
            ;; Don't encode `stdout' as string.
            :coding 'no-conversion
            :command
	    (list emacs-binary
		  "-Q" "--batch" "--eval" "(eval (read))" "--kill")
            :connection-type 'pipe
            :sentinel
            (lambda (process msg)
              (let ((status (process-status process)))
                (cond
                 ((eq status 'exit)
                  (message "Recompile: success with %d directories"
                           (length load-paths-to-compile)))
                 (t
                  (message "Recompile: failed with status %S, %S"
                           status msg))))))))

      (process-send-string proc proc-script)
      (process-send-eof proc)

      ;; When running as a batch job,
      ;; block until the process is finished.
      (when noninteractive
        (while (accept-process-output proc))))))


;;;###autoload
(defun package-utils-list-upgrades (&optional no-fetch)
  "List all packages that can be upgraded.

With prefix argument NO-FETCH, do not call `package-refresh-contents'."
  (interactive "P")
  (unless no-fetch
    (package-refresh-contents))
  (let ((packages (package-utils-upgradable-packages)))
    (if (null packages)
        (message "All packages are already up to date.")
      (message "Upgradable packages: %s" (mapconcat #'symbol-name packages ", ")))))

;;;###autoload
(defun package-utils-upgrade-all (&optional no-fetch)
  "Upgrade all packages that can be upgraded.

With prefix argument NO-FETCH, do not call `package-refresh-contents'.

Return true if there were packages to install, nil otherwise."
  (interactive "P")
  (unless no-fetch
    (package-refresh-contents))
  (let ((packages (package-utils-upgradable-packages)))
    (if (null packages)
        (progn
          (message "All packages are already up to date.")
          nil)
      (package-utils-with-packages-list t
        (package-menu-mark-upgrades)
        (package-menu-execute t))
      (message "Upgraded packages: %s" (mapconcat 'symbol-name packages ", "))
      t)))

;;;###autoload
(defun package-utils-upgrade-all-no-fetch ()
  "Upgrade all packages that can be upgraded without refreshing first.

This skips calling `package-refresh-contents'."
  (interactive)
  (package-utils-upgrade-all t))

;;;###autoload
(defun package-utils-upgrade-all-and-recompile (&optional no-fetch)
  "Upgrade all packages that can be upgraded, and recompile all byte-code.

With prefix argument NO-FETCH, do not call `package-refresh-contents'."

  (interactive "P")
  ;; Prevent redundant recompile on package installation,
  ;; since this is performed afterwards.
  (when (cl-letf (((symbol-function 'byte-recompile-directory)
                   (lambda (&rest _args))))
          (package-utils-upgrade-all no-fetch))
    (package-utils--byte-recompile-all-packages)))

;;;###autoload
(defun package-utils-upgrade-all-and-quit (&optional no-fetch)
  "Upgrade all packages that can be upgraded, then quit emacs.

With prefix argument NO-FETCH, do not call `package-refresh-contents'."
  (interactive "P")
  (package-utils-upgrade-all no-fetch)
  (sleep-for 1)
  (save-buffers-kill-emacs t))

;;;###autoload
(defun package-utils-upgrade-all-and-restart (&optional no-fetch)
  "Upgrade all packages that can be upgraded, then restart emacs.

With prefix argument NO-FETCH, do not call `package-refresh-contents'."
  (interactive "P")
  (package-utils-upgrade-all no-fetch)
  (sleep-for 1)
  (restart-emacs))

;;;###autoload
(defun package-utils-upgrade-by-name (name &optional no-fetch)
  "Upgrade the package NAME.

With prefix argument NO-FETCH, do not call `package-refresh-contents'."
  (interactive
   (progn
     (unless current-prefix-arg
       (package-refresh-contents))
     (list (package-utils-read-upgradable-package)
           current-prefix-arg)))
  (package-utils-with-packages-list (list name)
    (package-menu-mark-upgrades)
    (package-menu-execute t))
  (message "Package \"%s\" was upgraded." name))

;;;###autoload
(defun package-utils-upgrade-by-name-no-fetch (name)
  "Upgrade the package NAME, without calling `package-refresh-contents' first."
  (interactive (list (package-utils-read-upgradable-package)))
  (package-utils-upgrade-by-name name t))

;;;###autoload
(defun package-utils-remove-by-name (name)
  "Uninstall the package NAME."
  (interactive
   (list (intern (completing-read "Remove package: "
                                  (mapcar #'symbol-name (package-utils-installed-packages))
                                  nil
                                  'require-match))))
  (package-delete (cadr (assoc name package-alist))))

(provide 'package-utils)

;;; package-utils.el ends here
