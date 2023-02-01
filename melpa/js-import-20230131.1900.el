;;; js-import.el --- Import Javascript files from your current project or dependencies  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Jakob Lind

;; Author: Jakob Lind <karl.jakob.lind@gmail.com>
;; URL: https://github.com/jakoblind/js-import
;; Package-Version: 20230131.1900
;; Package-Commit: 9f8b6bc4f080c7146ce7ee5dd5a6572aeb6f1cc7
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

(require 'map)
(require 'f)
(require 'json)
(require 'subr-x)
(require 'projectile)

(defcustom js-import-omit-file-extension nil
  "Omit import file extensions.
Possible values of this option are:

t       Always omit.
never   Never omit.
nil     Omit if current file has a .[tj]sx? extension and
        package.json#type is not \"module\", include otherwise."
  :group 'js-import
  :type '(choice (const :tag "If needed" nil)
								 (const :tag "Always omit" t)
                 (const :tag "Never omit" never)))
(make-variable-buffer-local 'js-import-omit-file-extension)

(defcustom js-import-quote "\""
  "Quote type used."
  :group 'js-import
  :type '(choice (const :tag "Double" "\"")
                 (const :tag "Single" "'")))

(defcustom js-import-style 'relative
  "Import style used."
  :group 'js-import
  :type '(choice (const :tag "from-project-root" project-root)
                 (const :tag "relative" relative)))

(defun js-import--project-root-package-json-path ()
  "Path to package.json from projectile-project-root."
  (f-expand "package.json" (projectile-project-root)))

(defun js-import--package-json (&optional package-json-path)
	(condition-case-unless-debug nil
			(let ((json-object-type 'hash-table))
				(json-read-from-string
				 (f-read-text (or package-json-path (js-import--project-root-package-json-path)) 'utf-8)))))

(defun js-import--package-json-dependencies (section &optional package-json-path)
  "List of dependencies from SECTION in PACKAGE-JSON-PATH."
  (map-keys (map-elt (js-import--package-json package-json-path) section)))

(defun js-import--js-file-p (filename)
  "Return FILENAME extension (with period) if one of:
.js .jsx .cjs .cjsx .mjs .mjsx
.ts .tsx .mts .mtsx .cts .ctsx"
  (when-let* ((ext (f-ext filename t))
							((string-match-p "[cm]?[jt]sx?$" ext)))
		ext))

(defun js-import--from-path (path arg)
  "Import symbols from module."
  (save-excursion
    (let* ((proposed-symbol (or (thing-at-point 'symbol) (f-base path)))
           (read-symbols
            (read-string
						 (format
							(pcase arg
								(1 "import ＿ from %s (default: %s): ")
								(4 "import { ＿ } from %s (default: %s): ")
								(16 "import * as ＿ from %s (default: %s): "))
							path proposed-symbol)
						 nil nil proposed-symbol))
					 (symbols (string-trim read-symbols)))
			(goto-char (point-min))
			(while (re-search-forward "^import[ \t\n]+" nil t)
				(re-search-forward "['\"]" nil t 2)
				(forward-line 1))
			(if (eq arg 16)
					(insert "import * as " symbols " from " js-import-quote path js-import-quote ";\n")
        (if (re-search-backward (concat "from +['\"]" path "['\"]") nil t)
						;; module is already imported
						(if (eq arg 4)
								(let ((bound (save-excursion (re-search-backward "\\_<import\\_>"))))
									(if (not (search-backward "}" bound t))
											(insert ", { " symbols " } " )
										(let ((is-multiline (< (save-excursion (search-backward "{" bound t))
																					 (line-beginning-position))))
											;; module already has an { import, list }
											(skip-chars-backward " \t\n")
											(if (not (looking-back ",\\s-*" bound))
													(insert "," (if is-multiline "\n" "") " " symbols " ")
												;; trailling comma
												(insert (if is-multiline "\n" "") symbols ",")
												(when is-multiline
													(funcall indent-line-function))))))
							(search-backward "import")
							(if (looking-at-p "import\\(\n\\|\\s-\\)+\\w") ;; default symbol already imported
									(progn
										(open-line 1)
										(insert "import "
														symbols
														" from " js-import-quote path js-import-quote ";"))
								(forward-word)
								(insert " " symbols ",")))
					;; module is not imported
					(insert "import "
                  (pcase arg
                    (1 symbols)
                    (4 (concat "{ " symbols " }") ))
                  " from " js-import-quote path js-import-quote ";\n"))))))

(defun js-import--normalize-typescript-ext (path)
	(if-let ((ext (js-import--js-file-p path)))
			(concat (f-no-ext path) (subst-char-in-string ?t ?j ext t))
		path))

(defun js-import--normalize-ext (path)
	(js-import--normalize-typescript-ext
	 (pcase js-import-omit-file-extension
		 ('t (f-no-ext path))
		 ('never path)
		 (_ (if (or (string-match-p "[cm][jt]sx?$" (f-ext path))
								(string= (map-elt (js-import--package-json) "type") "module"))
						path
					(f-no-ext path))))))

(defun js-import--select-path (section)
  "Select path from modules in project or package.json SECTION."
  (let ((path
				 (completing-read
					"Select module: "
					(append
					 (js-import--package-json-dependencies section)
					 (-filter 'js-import--js-file-p (projectile-current-project-files))))))
    (when (js-import--js-file-p path)
			(setq path (js-import--normalize-ext path))
      (when (eq js-import-style 'relative)
 				(setq path (f-relative (concat (projectile-project-root) path)
 															 default-directory))
				(when (not (string-prefix-p "." path))
 					(setq path (concat "./" path))))
      (setq path (replace-regexp-in-string "/index$" "" path)))
    path))

;;;###autoload
(defun js-import (arg)
  "Import default export from a project module or dependencies.

With one prefix argument, import exported symbols.
With two prefix arguments, import all exports as a symbol."
  (interactive "p")
  (js-import--from-path (js-import--select-path "dependencies") arg))

;;;###autoload
(defun js-import-dev (arg)
  "Import default export from a project module or devDependencies.

With one prefix argument, import exported symbols.
With two prefix arguments, import all exports as a symbol."
  (interactive "p")
  (js-import--from-path (js-import--select-path "devDependencies") arg))

(provide 'js-import)
;;; js-import.el ends here
