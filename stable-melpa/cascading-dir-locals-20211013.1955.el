;;; cascading-dir-locals.el --- Apply all (!) .dir-locals.el from root to current directory -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Fritz Grabo

;; Author: Fritz Grabo <hello@fritzgrabo.com>
;; URL: https://github.com/fritzgrabo/cascading-dir-locals
;; Package-Version: 20211013.1955
;; Package-Commit: 345d4b70e837d45ee84014684127e7399932d5e6
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; Provides a global minor mode that changes how Emacs handles the
;; lookup of applicable dir-locals files (".dir-locals.el"): instead of
;; starting at the directory of the visited file and moving up the
;; directory tree only until a first dir-locals file is found, collect
;; and apply all (!) dir-locals files found from the current directory
;; up to the root one.

;; Values specified in files nearer to the current directory take
;; precedence over values in files farther away from it.

;; You might want to use this to globally set dir-local variables that
;; apply to all of your projects, then override or add variables on a
;; per-project basis.

;;; Code:

(eval-when-compile (require 'subr-x))
(require 'seq)

(defcustom cascading-dir-locals-debug nil
  "When non-nil, print debug messages regarding the lookup and collection of dir-locals files."
  :type 'boolean
  :group 'find-file)

(defun cascading-dir-locals--called-by-p (f &optional base)
  "Return t if the containing function was called by function F.
If BASE is non-nil, ignore invocations of F after BASE."
  (catch 'found
    (mapbacktrace
     (lambda (_evald fun _args _flags)
       (when (eq fun f) (throw 'found t)))
     base)))

(defun cascading-dir-locals--all-files (orig-fun dir)
  "Collect all dir-locals files found from the root directory up to DIR.
Pass the unadvised version of `dir-locals--all-files' as ORIG-FUN."
  (let* ((dir (expand-file-name dir))
         (parent-dir (file-name-directory (directory-file-name dir))))
    (when cascading-dir-locals-debug
      (message "#<%s>: looking for dir-locals files in %s"
               (buffer-name)
               (abbreviate-file-name dir)))
    (if (equal parent-dir dir) ;; That is, we have hit the root directory: stop recursion.
        (apply orig-fun (list dir))
      (let ((files-in-parent-dirs (cascading-dir-locals--all-files orig-fun parent-dir))
            (files-in-dir (apply orig-fun (list dir))))
        (when (and cascading-dir-locals-debug files-in-dir)
          (message "#<%s>: collecting dir-local variables from %s"
                   (buffer-name)
                   (string-join (seq-map #'abbreviate-file-name files-in-dir) ", ")))
        (append files-in-parent-dirs files-in-dir)))))

(defun cascading-dir-locals--all-files-dispatch (orig-fun &rest args)
  "Based on caller, call original or recursive version of `dir-locals--all-files' (ORIG-FUN) with ARGS."
  ;; `dir-locals--all-files' is called in various places in "files.el";
  ;; we only need it to do a (potentially expensive) recursion when it
  ;; is called by `dir-locals-read-from-dir'.
  (if (cascading-dir-locals--called-by-p #'dir-locals-read-from-dir #'dir-locals--all-files)
      (apply #'cascading-dir-locals--all-files orig-fun args)
    (apply orig-fun args)))

;;;###autoload
(define-minor-mode cascading-dir-locals-mode
  "Apply all dir-locals files found from the current directory up to the root one."
  :global t
  :group 'find-file
  (if cascading-dir-locals-mode
      (advice-add #'dir-locals--all-files :around #'cascading-dir-locals--all-files-dispatch)
    (advice-remove #'dir-locals--all-files #'cascading-dir-locals--all-files-dispatch)))

(provide 'cascading-dir-locals)
;;; cascading-dir-locals.el ends here
