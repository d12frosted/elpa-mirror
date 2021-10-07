;;; java-imports.el --- Code for dealing with Java imports

;; Copyright (C) 2015 Matthew Lee Hinman

;; Author: Lee Hinman <lee@writequit.org>
;; URL: http://www.github.com/dakrone/emacs-java-imports
;; Package-Version: 20211006.2153
;; Package-Commit: 7535a36d85497448a6e83579b822beaca7251ccb
;; Version: 0.1.1
;; Keywords: java kotlin
;; Package-Requires: ((emacs "24.4") (s "1.10.0") (pcache "0.3.2"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides a way to easily add `import' statements for Java classes

;;; Usage:

;; (require 'java-imports)
;; (define-key java-mode-map (kbd "M-I") 'java-imports-add-import)

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
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

;;; Code:

(require 'cl-lib)
(require 'thingatpt)
(require 'subr-x)
(require 's)
(require 'pcache)

(defgroup java-imports nil
  "Customization for java imports package"
  :group 'languages)

(defcustom java-imports-save-buffer-after-import-added t
  "`t' to save the current buffer after inserting an import statement."
  :group 'java-imports
  :type 'boolean)

(defcustom java-imports-use-cache t
  "Whether packages for classes should be cached"
  :group 'java-imports
  :type 'boolean)

(defcustom java-imports-find-block-function 'java-imports-find-place-after-last-import
  "A function that should find a proper insertion place within
  the block of import declarations."
  :group 'java-imports
  :type 'function)

(defcustom java-imports-cache-name "java-imports"
  "Name of the cache to be used for the ClassName to Package
  mapping cache."
  :group 'java-imports
  :type 'string)

(defcustom java-imports-default-packages
  '(("List" . "java.util")
    ("Collection" . "java.util")
    ("Set" . "java.util")
    ("Queue" . "java.util")
    ("Deque" . "java.util")
    ("HashSet" . "java.util")
    ("TreeSet" . "java.util")
    ("ArrayList" . "java.util")
    ("LinkedList" . "java.util")
    ("ArrayDeque" . "java.util")
    ("PriorityQueue" . "java.util")
    ("HashMap" . "java.util")
    ("TreeMap" . "java.util")
    ("Iterator" . "java.util"))
  "An alist mapping class names to probable packages of the
classes."
  :group 'java-imports
  :type '(alist :key-type string :value-type string))

(defun java-imports-go-to-imports-start ()
  "Go to the point where java import statements start or should
start (if there are none)."
  (goto-char (point-min))
  ;; package declaration is always in the beginning of a file, so no need to
  ;; reset the point after the first search
  (let ((package-decl-point (re-search-forward "package .*;" nil t))
        (import-decl-point (re-search-forward "import .*;" nil t)))
    ;; 1. If there are imports in the file - go to the first one
    ;;
    ;; 2. No imports, and the package declaration is available - go to the end
    ;; of the declaration
    ;;
    ;; 3. Neither package nor import declarations are present - just go to the
    ;; first line
    (cond (import-decl-point (goto-char import-decl-point)
                             (beginning-of-line))
          (package-decl-point (goto-char package-decl-point)
                              (forward-line)
                              (open-line 2)
                              (forward-line))
          (t (goto-char (point-min))
             (open-line 1)))))

(defun java-imports-get-import (line)
  "Return the fully-qualified package for the given import line."
  (when line
    (cadr (s-match "import \\\(.*?\\\);?$"
                   (string-trim line)))))

(defun java-imports-get-package-and-class (import)
  "Explode the import and return (pkg . class) for the given import.

Example 'java.util.Map' returns '(\"java.util\" \"Map\")."
  (when import
    (cl-subseq (s-match "\\\(.*\\\)\\\.\\\([A-Z].+?\\\)\\\(?:;\\\|$\\\)" import) 1)))

(defun java-imports-import-for-line ()
  "Returns the fully-qualified class name for the import line."
  (java-imports-get-import (thing-at-point 'line)))

(defun java-imports-import-exists-p (full-name)
  "Checks if the import already exists"
  (save-excursion
    (goto-char (point-min))
    (re-search-forward (concat "^[ \t]*import[ \t]+" full-name "[ \t]*;") nil t)))

(defun java-imports-find-place-sorted-block (full-name class-name package)
  "Finds the insertion place within a sorted import block.

Follows a convention where non-JRE imports are separated from JRE
imports by a single line, and both blocks are always present."

  ;; Skip builtin imports if not a JRE import
  (and (not (s-starts-with? "java." (java-imports-import-for-line)))
       (when (s-starts-with? "java." full-name)
         (re-search-forward "^$" nil t)
         (forward-line 1)))

  ;; Search for a proper place within a block
  (while (and (java-imports-import-for-line)
              (string< (java-imports-import-for-line) full-name))
    (forward-line 1))
  (open-line 1))

(defun java-imports-find-place-after-last-import (full-name class-name package)
  "Finds the insertion place by moving past the last import declaration in the file."
  (while (re-search-forward "import[ \t]+.+[ \t]*;" nil t))
  (beginning-of-line)
  (unless (equal (point-at-bol) (point-at-eol))
    (forward-line)
    (open-line 1)))

(defun java-imports-read-package (class-name cached-package)
  "Reads a package name for a class, offers default values for
known classes"
  (or (car (s-match ".*\\\..*" class-name))
      (and (not current-prefix-arg)
           cached-package)
      (let* ((default-package (cdr (assoc-string class-name java-imports-default-packages)))
             (default-prompt (if default-package
                                 (concat "[" default-package "]") ""))
             (prompt (concat "Package " default-prompt ": ")))
        (read-string prompt nil nil default-package))))

;;;###autoload
(defun java-imports-scan-file ()
  "Scans a java-mode or kotlin-mode buffer, adding any import class -> package
mappings to the import cache. If called with a prefix arguments
overwrites any existing cache entries for the file."
  (interactive)
  (when (member major-mode '(java-mode kotlin-mode))
    (let* ((cache (pcache-repository java-imports-cache-name)))
      (dolist (import (java-imports-list-imports))
        (let ((pkg-class-list (java-imports-get-package-and-class import)))
          (when pkg-class-list
            (let* ((pkg (car pkg-class-list))
                   (class (intern (cadr pkg-class-list)))
                   (exists-p (pcache-get cache class)))
              (when (or current-prefix-arg (not exists-p))
                (message "Adding %s -> %s to the java imports cache" class pkg)
                (pcache-put cache class pkg))))))
      (pcache-save cache))))

;;;###autoload
(defun java-imports-list-imports ()
  "Return a list of all fully-qualified packages in the current
Java-mode or Kotlin-mode buffer"
  (interactive)
  (cl-mapcar
   #'java-imports-get-import
   (cl-remove-if-not (lambda (str) (s-matches? "import[ \t]+.+?[ \t]*;?" str))
                     (s-lines (buffer-string)))))

;;;###autoload
(defun java-imports-add-import-with-package (class-name package)
  "Add an import for the class for the name and package. Uses no caching."
  (interactive (list (read-string "Class name: " (thing-at-point 'symbol))
                     (read-string "Package name: " (thing-at-point 'symbol))))
  (save-excursion
    (let ((class-name (s-chop-prefix "@" class-name))
          (full-name (or (car (s-match ".*\\\..*" class-name))
                         (concat package "." class-name))))
      (when (java-imports-import-exists-p full-name)
        (user-error "Import for '%s' already exists" full-name))

      ;; Goto the start of the imports block
      (java-imports-go-to-imports-start)

      ;; Search for a proper insertion place within the block of imports
      (funcall java-imports-find-block-function full-name class-name package)

      ;; The insertion itself. Note that the only thing left to do here is to
      ;; insert the import.
      (insert "import " (concat package "." class-name) ";")
      full-name)))

;;;###autoload
(defun java-imports-add-import (class-name)
  "Import the Java class for the symbol at point. Uses the symbol
at the point for the class name, ask for a confirmation of the
class name before adding it.

Checks the import cache to see if a package entry exists for the
given class. If found, adds an import statement for the class. If
not found, prompts for the package and saves it to the cache.

If called with a prefix argument, overwrites the package for an
already-existing class name."
  (interactive (list (read-string "Class name: " (thing-at-point 'symbol))))
  (save-excursion
    (let* ((class-name (s-chop-prefix "@" class-name))
           (key (intern class-name))
           (cache (pcache-repository java-imports-cache-name))
           ;; Check if we have seen this class's package before
           (cached-package (and java-imports-use-cache
                                (pcache-get cache key)))
           ;; If called with a prefix, overwrite the cached value always
           (add-to-cache? (or current-prefix-arg
                              (eq nil cached-package)))
           (package (java-imports-read-package class-name cached-package))
           (full-name (java-imports-add-import-with-package
                       class-name package)))

      ;; Optionally save the buffer and cache the full package name
      (when java-imports-save-buffer-after-import-added
        (save-buffer))
      (when add-to-cache?
        (message "Adding %s -> %s to java imports cache"
                 class-name package)
        (pcache-put cache key package)
        (pcache-save cache))
      full-name)))

;;;###autoload
(defun java-imports-add-import-dwim ()
  "Add an import statement for the class at point. If no class is
found, prompt for the class name. If the class's package already
exists in the cache, add it and return, otherwise prompt for the
package and cache it for future statements."
  (interactive)
  (let ((class (or (thing-at-point 'symbol)
                   (read-string "Class name: "))))
    (java-imports-add-import (s-chop-prefix "@" class))))

;;;###autoload
(defun java-imports-scan-local-jars (&optional local-repo)
  (interactive)
  "scan the local repository, find local jars and add them to the cache.
if a class is found in multiple packages, any such package may be registered
for that class in the cache.
This is currently a synchronous and potentially slow operation, but
hopefully faster than adding imports manually or using eclipse"
  (cl-labels ((shell-command-to-lines
               (cmd)
               (s-split "\n" (shell-command-to-string cmd) t)))
    (let* ((local-repo (or local-repo (expand-file-name
                                       "~/.m2/repository/")))
           (jars (shell-command-to-lines
                  (format "find '%s' -name '*.jar'"
                          local-repo)))
           (cache (pcache-repository java-imports-cache-name)))
      (dolist (jar jars)
        (dolist (line (shell-command-to-lines (concat "jar -tf " jar)))
          (when (string-match "\\(.*\\)/\\(.*\\)[.]class" line)
            (let ((class (intern (match-string 2 line)))
                  (package-name
                   (replace-regexp-in-string "/" "." (match-string 1 line))))
              (if (pcache-get cache class)
                  (message "skipping %s -> %s" class package-name)
                (progn (message "adding %s -> %s..." class package-name)
                       (pcache-put cache class package-name))))))))))

(provide 'java-imports)

;;; java-imports.el ends here
