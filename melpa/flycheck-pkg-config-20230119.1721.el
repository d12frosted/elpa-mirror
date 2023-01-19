;;; flycheck-pkg-config.el --- configure flycheck using pkg-config  -*- lexical-binding: t; -*-

;; Copyright (C) 2016

;; Author: Wilfred Hughes <me@wilfred.me.uk>
;; Keywords: flycheck
;; Package-Version: 20230119.1721
;; Package-Commit: c4e4028f6621187365b7362566ac2786206765a1
;; Version: 0.3
;; Package-Requires: ((dash "2.8.0") (s "1.9.0") (flycheck "29"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Flycheck defines a several include path variables that it searches
;; for headers when checking C/C++ code.
;;
;; This package provides a convenient way of adding libraries to that
;; list, using pkg-config and completion.

;;; Code:

(require 's)
(require 'dash)
(require 'flycheck)

(defvar flycheck-pkg-config--libs nil)

(defcustom flycheck-pkg-config-path-vars
  '(flycheck-clang-include-path
    flycheck-gcc-include-path
    flycheck-cppcheck-include-path)
  "System include path variables to be configured."
  :type '(repeat (symbol :tag "Include Path Variable")))

(defun flycheck-pkg-config--ignore-case-less-p (s1 s2)
  (string< (downcase s1) (downcase s2)))

(defun flycheck-pkg-config--set-libs ()
  "Set `flycheck-pkg-config--libs' by calling pkg-config."
  (let* ((all-libs-with-names
          (shell-command-to-string "pkg-config --list-all"))
         (lines (s-split "\n" (s-trim all-libs-with-names)))
         (libs (--map (-first-item (s-split " " it)) lines)))
    (setq flycheck-pkg-config--libs (-sort #'flycheck-pkg-config--ignore-case-less-p libs))))

(defun flycheck-pkg-config--include-paths (library-name)
  "Get a list of include paths for LIBRARY-NAME.
Raises an error if pkg-config can't find any paths for this library."
  (let* (;; Find the include flags, e.g. "-I/usr/lib/foo"
         (pkgconfig-cmd (format "pkg-config --cflags %s" library-name))
         (cc-args (s-trim (shell-command-to-string pkgconfig-cmd))))
    (if (s-contains? "-I" cc-args)
        ;; pkg-config has found a library with this name.
	(let (ret)
	  (dolist (x (s-split " " cc-args) ret)
	    (if (s-starts-with? "-I" x) (setq ret (cons (s-chop-prefix "-I" x) ret)))))
      (user-error "Could not find an -I include in: %s" cc-args))))

;;;###autoload
(defun flycheck-pkg-config (lib-name)
  "Configure flycheck to use additional includes
when checking the current buffer."
  (interactive
   (progn
     ;; Find out all the libraries installed on this system.
     (unless flycheck-pkg-config--libs
       (flycheck-pkg-config--set-libs))
     (list (completing-read "Library name: " flycheck-pkg-config--libs))))

  (let* (;; Find the include paths, e.g. "-I/usr/lib/foo"
         (include-paths (flycheck-pkg-config--include-paths lib-name)))
    (dolist (path-var flycheck-pkg-config-path-vars)
      ;; Only set in this buffer.
      (make-local-variable path-var)
      ;; Add include paths unless already present.
      (set path-var (-union (eval path-var) include-paths)))
    (message "Added to include paths: %s"
             (s-join " " (--map (format "\"%s\"" it) include-paths)))))

(provide 'flycheck-pkg-config)
;;; flycheck-pkg-config.el ends here
