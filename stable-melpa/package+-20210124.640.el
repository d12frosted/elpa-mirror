;;; package+.el --- Extensions for the package library.  -*- lexical-binding: t; -*-

;; Copyright (C) Ryan Davis

;; Author: Ryan Davis <ryand-ruby@zenspider.com>
;; Created: 2013-07-25
;; Keywords: extensions, tools
;; Package-Version: 20210124.640
;; Package-Commit: 06fbc904e09d3349b669c2624a587fee5accf5ef
;; Package-Requires: ((emacs "24.3"))
;; URL: https://github.com/zenspider/package
;; Compatibility: GNU Emacs: 24.3?, 24.4+
;; Version: 1.1.0

;;; The MIT License:

;; http://en.wikipedia.org/wiki/MIT_License
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
;; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
;; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;; Provides extensions to `package.el` for Emacs 24 and later.

;; Declares a manifest of packages that should be installed on this
;; system, installing any missing packages and removing any installed
;; packages that are not in the manifest.
;;
;; This makes it easy to keep a list of packages under version control
;; and replicated across all your environments, without having to have
;; all the packages themselves under version control.
;;
;; Example:
;;
;;    (package-initialize)
;;    (add-to-list 'package-archives
;;      '("melpa" . "https://melpa.org/packages/") t)
;;    (unless (package-installed-p 'package+)
;;      (package-install 'package+))
;;
;;    (package-manifest 'ag
;;                      'expand-region
;;                      'magit
;;                      'melpa
;;                      'package+
;;                      'paredit
;;                      'ruby-mode
;;                      'ssh
;;                      'window-number)

;;; Note:

;; Call (package-refresh-contents) before running (package-manifest ...)
;; if you want to ensure you're using the latest package data.

;; package-version-for, package-delete-by-name, package-maybe-install,
;; package-cleanup, package-deps-for, and package-transitive-closure
;; are all going to be submitted upstream to emacs. They're in here
;; and only defined if package-cleanup is not already defined. If my
;; contributions get accepted upstream, they'll be deleted here at
;; some point.

;; If automatic package cleanup is not desired (for example, if you have
;; locally-installed packages you want to keep), you can disable this
;; functionality by setting package-disable-cleanup to t.
;;
;;    (package-manifest 'foo
;;                      'bar
;;                      ... )

;; If automatic updating of package-selected-packages is not desired
;; (for example, if you have manually-installed packages you want to
;; keep), you can disable this functionality by setting
;; package-disable-record to t.

;;; Code:

(require 'package)
(require 'cl-extra)                     ; cl-prettyprint

(eval-and-compile
  (require 'cl))

(defcustom package-disable-cleanup nil
  "Disable automatic cleanup of undeclared packages and their dependencies."
  :type 'boolean
  :group 'package+)

(defcustom package-disable-record nil
  "Disable automatic recording of declared packages in ‘package-selected-packages’."
  :type 'boolean
  :group 'package+)

(unless (fboundp 'package-desc-version)
  ;; provide compatibilty back to 24.3--hopefully.
  (defsubst package-desc-version (desc)
    "Extract version from a package description vector."
    (aref desc 0)))

(defun symbol< (a b) (string< (symbol-name a) (symbol-name b)))

(defun symbol-list< (a b) (symbol< (car a) (car b)))

(defun package-details-for (name)
  (let ((v (cdr (assoc name (append package-alist package-archive-contents)))))
    (and v (if (consp v)
               (car v)                ; emacs 24+
             v))))                    ; emacs 23

(defun package-version-for (name)
  "Returns the installed version for a package with a given NAME."
  (package-desc-version (package-details-for name)))

(defun package-delete-by-name (name)
  "Deletes a package by NAME"
  (message "Removing %s" name)
  (setq package+-dirty t)
  (package-delete (package-details-for name)))

(defun package-maybe-install (name)
  "Installs a package by NAME, but only if it isn't already installed."
  (unless (package-installed-p name)
    (message "Installing %s" name)
    (setq package+-dirty t)
    (package-install name package-disable-record)))

(defun package-deps-for (pkg)
  "Returns the dependency list for PKG or nil if none or the PKG doesn't exist."
  (unless package-archive-contents
    (package-refresh-contents))
  (let ((v (package-details-for pkg)))
    (and v (package-desc-reqs v))))

(defun map-to-package-deps (pkg)
  (cons pkg (sort (mapcar 'car (package-deps-for pkg)) 'symbol<)))

(defun flatten (lists)
  (apply #'append lists))

(defun package-transitive-closure (pkgs)
  (car
   (package+/topological-sort
    (mapcar 'map-to-package-deps
            (sort (delete-dups
                   (flatten (mapcar 'map-to-package-deps pkgs)))
                  'symbol<)))))

(defun rwd-map-filter (pred map)
  "FUCK YOU ORIGINAL map-filter FOR NOT BEING A MAP AT ALL"
  (seq-filter (lambda (x) x)
              (mapcar pred map)))

(defun package-installed-with-deps (&optional pkgs)
  (sort
   (rwd-map-filter (lambda (pair)
                     (let ((x (and pair (cadr pair))))
                       (and x (cons (package-desc-name x)
                                    (sort (mapcar 'car (package-desc-reqs x))
                                          'symbol<)))))
                   (or pkgs package-alist))
   'symbol-list<))

(defun package-manifest-with-deps (packages)
  (sort
   (rwd-map-filter (lambda (pkg)
                     (let ((deps (package-deps-for pkg)))
                       (and (assoc pkg package-archive-contents)
                            (cons pkg (sort (mapcar 'car deps)
                                            'symbol<)))))
                   (package-transitive-closure packages))
   'symbol-list<))

(defun topo (lst)
  (car (package+/topological-sort lst)))

(defun package-cleanup (packages)
  "Delete installed packages not explicitly declared in PACKAGES."
  (let* ((haves (package-manifest-with-deps (mapcar 'car package-alist)))
         (wants (package-manifest-with-deps packages))
         (removes (seq-filter
                   (lambda (name) (assoc name package-alist))
                   (cl-set-difference
                    (topo haves)
                    (topo wants)))))
    (message "Removing packages: %S" removes)
    (mapc 'package-delete-by-name (reverse removes))
    )) ; (unless (fboundp 'package-cleanup)

;;;###autoload
(defun package-manifest (&rest manifest)
  "Ensures MANIFEST is installed and uninstalls other packages.
MANIFEST declares a list of packages that should be installed on
this system, installing any missing packages and removing any
installed packages that are not in the manifest. After
installation and cleanup, record the manifest in
‘package-selected-packages’ so Emacs can track packages versus
their dependencies.

This makes it easy to keep a list of packages under version
control and replicated across all your environments, without
having to have all the packages themselves under version
control.

If automatic package cleanup is not desired, you can disable this
functionality by setting package-disable-cleanup to t.

If updating ‘package-selected-packages’ is not desired, you can
disable this functionality by setting package-disable-record to
t."
  ;; do not conditionalize. must be loaded or closure
  ;; calculation/installation breaks on `emacs` itself.
  (package-initialize)

  (unless package-archive-contents    ; why? package-install has this.
    (package-refresh-contents))

  (setq package+-dirty nil)
  (mapc 'package-maybe-install (package-transitive-closure manifest))

  (unless package-disable-cleanup (package-cleanup manifest))

  (when (and package-quickstart
           package-quickstart-file
           (or (not (file-readable-p package-quickstart-file))
               package+-dirty))
    (message "package+ auto-updating %s" package-quickstart-file)
    (package-quickstart-refresh))

  (sort (package-transitive-closure manifest) 'symbol<))

;;;###autoload
(defun package-view-manifest ()
  "Pop up a buffer listing out all installed packages with their dependencies."
  (interactive)
  (with-help-window "my-packages"
    (with-current-buffer "my-packages"
      (cl-prettyprint (package-manifest-with-deps package-selected-packages)))))

;; stolen (and modified) from:
;; https://github.com/dimitri/el-get/blob/master/el-get-dependencies.el
(defun package+/topological-sort (graph)
  "Return a list of packages to install in order.
GRAPH is an association list whose keys are objects and whose
values are lists of objects on which the corresponding key depends.
Test is used to compare elements, and should be a suitable test for
hash-tables.  Topological-sort returns two values.  The first is a
list of objects sorted toplogically.  The second is a boolean
indicating whether all of the objects in the input graph are present
in the topological ordering (i.e., the first value)."
  (let* ((entries (make-hash-table))
         ;; avoid obsolete `flet' & backward-incompatible `cl-flet'
         (entry (lambda (v)
                  "Return the entry for vertex.  Each entry is a cons whose
              car is the number of outstanding dependencies of vertex
              and whose cdr is a list of dependants of vertex."
                  (or (gethash v entries)
                      (puthash v (cons 0 '()) entries)))))
    ;; populate entries initially
    (dolist (gvertex graph)
      (destructuring-bind (vertex &rest dependencies) gvertex
        (let ((ventry (funcall entry vertex)))
          (dolist (dependency dependencies)
            (let ((dentry (funcall entry dependency)))
              (unless (eql dependency vertex)
                (incf (car ventry))
                (push vertex (cdr dentry))))))))
    ;; L is the list of sorted elements, and S the set of vertices
    ;; with no outstanding dependencies.
    (let ((L '())
          (S (loop for entry being each hash-value of entries
                   using (hash-key vertex)
                   when (zerop (car entry)) collect vertex)))
      ;; Until there are no vertices with no outstanding dependencies,
      ;; process vertices from S, adding them to L.
      (do* () ((endp S))
        (let* ((v (pop S)) (ventry (funcall entry v)))
          (remhash v entries)
          (dolist (dependant (cdr ventry) (push v L))
            (when (zerop (decf (car (funcall entry dependant))))
              (push dependant S)))))
      ;; return (1) the list of sorted items, (2) whether all items
      ;; were sorted, and (3) if there were unsorted vertices, the
      ;; hash table mapping these vertices to their dependants
      (let ((all-sorted-p (zerop (hash-table-count entries))))
        (values (nreverse L)
                all-sorted-p
                (unless all-sorted-p
                  entries))))))

(provide 'package+)

;;; package+.el ends here
