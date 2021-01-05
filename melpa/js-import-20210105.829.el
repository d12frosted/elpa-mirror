;;; js-import.el --- Import Javascript files from your current project or dependencies  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Jakob Lind

;; Author: Jakob Lind <karl.jakob.lind@gmail.com>
;; URL: https://github.com/jakoblind/js-import
;; Package-Version: 20210105.829
;; Package-Commit: 941091b3ab074c482a5920194d61f50e9b50d503
;; Package-Requires: ((emacs "24.4") (f "0.19.0") (projectile "0.14.0") (dash "2.13.0"))
;; Version: 1.0
;; Keywords: tools

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

;;

;;; Code:

(require 'f)
(require 'json)
(require 'subr-x)
(require 'projectile)

(defcustom js-import-quote "\""
  "Quote type used."
  :group 'js-import
  :type '(choice (const :tag "Double" "\"")
                 (const :tag "Single" "'")))

(defcustom js-import-style "relative"
  "Import style used."
  :group 'js-import
  :type '(choice (const :tag "from-project-root" "project-root")
                 (const :tag "relative" "relative")))

(defun js-import-get-package-json ()
  "Return the path to package.json from projectile-project-root."
  (concat (projectile-project-root) "package.json"))

(defun js-import-get-project-dependencies (package-json-path section)
  "Return a list of strings with dependencies fetched from PACKAGE-JSON-PATH in SECTION.  If file not found, return nil."
  (let ((json-object-type 'hash-table))
    (when-let ((package-json-content (condition-case nil (f-read-text package-json-path 'utf-8) (error nil)))
               (dependencies-hash (condition-case nil (gethash section (json-read-from-string package-json-content)) (error nil))))
      (when dependencies-hash
        (hash-table-keys dependencies-hash)))))

(defun js-import-is-js-file (filename)
  "Check if FILENAME ends with .js, .jsx, .ts or .tsx."
  (member (file-name-extension filename) '("js" "jsx" "ts" "tsx")))

(defun js-import-from-path (path arg)
  "Import symbols from module."
  (save-excursion
    (let* ((proposed-symbol (or (thing-at-point 'symbol) (f-base path)))
           (read-symbols
            (read-string
			 (format
			  (pcase arg
				(1 "Import default as (default: %s): ")
				(4 "Symbols to import (default: %s): ")
				(16 "Import all exports as (default: %s): "))
			  proposed-symbol)
			 nil nil proposed-symbol))
		   (symbols (string-trim read-symbols)))
	  (goto-char (point-min))
	  (while (re-search-forward "\\(^\\| +\\)import[ \t\n]+" nil t)
		(re-search-forward "['\"]" nil t 2)
		(forward-line 1))
	  (if (eq arg 16)
          (insert "import * as " symbols
                  " from " js-import-quote path js-import-quote ";\n")
        (if (not (re-search-backward (concat "from +['\"]" path "['\"]") nil t))
            (insert "import "
                    (pcase arg
                      (1 symbols)
                      (4 (concat "{ " symbols " }") ))
                    " from " js-import-quote path js-import-quote ";\n")
          (if (eq arg 4)
              (if (not (search-backward "}" (save-excursion (search-backward "import")) t))
				  (insert ", { " symbols " } " )
				(skip-chars-backward " \t\n")
				(insert ", " symbols " "))
			(search-backward "import")
			(if (looking-at-p "import\\(\n\\|\\s-\\)+\\w") ;; default symbol already imported
				(progn
				  (open-line 1)
				  (insert "import "
						  symbols
						  " from " js-import-quote path js-import-quote ";"))
			  (forward-word)
			  (insert " " symbols ","))))))))

(defun js-import-select-path (section)
  "Select path from modules in project or package.json SECTION."
  (let ((path (completing-read
	       "Select module: "
	       (append
		(js-import-get-project-dependencies (js-import-get-package-json) section)
		(-filter 'js-import-is-js-file (projectile-current-project-files))))))
    (when (js-import-is-js-file path)
      (if (equal js-import-style "relative")
 	  (setq path (f-relative
 		      (concat (projectile-project-root) (f-no-ext path))
 		      default-directory))
	(setq path (f-no-ext path)))
      (setq path (replace-regexp-in-string "/index$" "" path))
      (when (equal js-import-style "relative")
 	(when (not (string-prefix-p "." path))
	  (setq path (concat "./" path)))))
    path))

;;;###autoload
(defun js-import (arg)
  "Import default export from modules on your current project or dependencies.

With one prefix argument, import exported symbols.
With two prefix arguments, import all exports as a symbol."
  (interactive "p")
  (js-import-from-path (js-import-select-path "dependencies") arg))

;;;###autoload
(defun js-import-dev (arg)
  "Import default export from modules on your current project or dependencies.

With one prefix argument, import exported symbols.
With two prefix arguments, import all exports as a symbol."
  (interactive "p")
  (js-import-from-path (js-import-select-path "devDependencies") arg))

(provide 'js-import)
;;; js-import.el ends here
