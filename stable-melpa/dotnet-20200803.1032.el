;;; dotnet.el --- Interact with dotnet CLI tool

;; Copyright (C) 2020 by Julien Blanchard

;; Author: Julien BLANCHARD <julien@sideburns.eu>
;; URL: https://github.com/julienXX/dotnet.el
;; Package-Version: 20200803.1032
;; Package-Commit: 83ba1305d7895b03f3dffb2d3458b7ec75e6909f
;; Version: 0.6
;; Keywords: .net, tools

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
;; dotnet CLI minor mode.

;; Provides some key combinations to interact with dotnet CLI.

;;; Code:

(defgroup dotnet nil
  "dotnet group."
  :prefix "dotnet-"
  :group 'tools)

(defcustom dotnet-mode-keymap-prefix (kbd "C-c C-n")
  "Dotnet minor mode keymap prefix."
  :group 'dotnet
  :type 'string)

;;;###autoload
(defun dotnet-add-package (package-name)
  "Add package reference from PACKAGE-NAME."
  (interactive "sPackage name: ")
  (dotnet-command (concat "dotnet add package " package-name)))

;;;###autoload
(defun dotnet-add-reference (reference project)
  "Add a REFERENCE to a PROJECT."
  (interactive (list (read-file-name "Reference file: ")
                     (read-file-name "In Project: ")))
  (dotnet-command (concat "dotnet add " project " reference "  reference)))

;;;###autoload
(defun dotnet-build ()
  "Build a .NET project."
  (interactive)
  (let* ((target (dotnet-select-project-or-solution))
         (command "dotnet build -v n /p:GenerateFullPaths=true \"%s\""))
    (compile (format command target))))

;;;###autoload
(defun dotnet-clean ()
  "Clean build output."
  (interactive)
  (dotnet-command "dotnet clean -v n"))

(defvar dotnet-langs '("c#" "f#"))
(defvar dotnet-templates '("console" "classlib" "mstest" "xunit" "web" "mvc" "webapi"))

(defvar dotnet-compilation-regexps
  (cons
   "^\\([^\n]+\\)(\\([0-9]+\\),\\([0-9]+\\)): \\(?:error\\|\\(warning\\)\\)"
   '(1 2 3 (4 . 5) 1)))

;;;###autoload
(defun dotnet-new (project-path template lang)
  "Initialize a new console .NET project.
PROJECT-PATH is the path to the new project, TEMPLATE is a
template (see `dotnet-templates'), and LANG is a supported
language (see `dotnet-langs')."
  (interactive (list (read-directory-name "Project path: ")
                     (completing-read "Choose a template: " dotnet-templates)
                     (completing-read "Choose a language: " dotnet-langs)))
  (dotnet-command (concat "dotnet "
                          (mapconcat 'shell-quote-argument
                                     (list "new" template  "-o" project-path "-lang" lang)
                                     " "))))

;;;###autoload
(defun dotnet-publish ()
  "Publish a .NET project for deployment."
  (interactive)
  (dotnet-command "dotnet publish -v n"))

;;;###autoload
(defun dotnet-restore ()
  "Restore dependencies specified in the .NET project."
  (interactive)
  (dotnet-command "dotnet restore"))

(defvar dotnet-run-last-proj-dir nil
  "Last project directory executed by `dotnet-run'.")

;;;###autoload
(defun dotnet-run (arg)
  "Compile and execute a .NET project.  With ARG, query for project path again."
  (interactive "P")
  (when (or (not dotnet-run-last-proj-dir) arg)
    (setq dotnet-run-last-proj-dir (read-directory-name "Run project in directory: ")))
  (let ((default-directory dotnet-run-last-proj-dir))
    (dotnet-command (concat "dotnet run " dotnet-run-last-proj-dir))))

;;;###autoload
(defun dotnet-run-with-args (args)
  "Compile and execute a .NET project with ARGS."
  (interactive "Arguments: ")
  (dotnet-command (concat "dotnet run " args)))

;;;###autoload
(defun dotnet-sln-add ()
  "Add a project to a Solution."
  (interactive)
  (let ((solution-file (read-file-name "Solution file: ")))
    (let ((to-add (read-file-name "Project/Pattern to add to the solution: ")))
      (dotnet-command (concat "dotnet sln " solution-file " add " to-add)))))

;;;###autoload
(defun dotnet-sln-remove ()
  "Remove a project from a Solution."
  (interactive)
  (let ((solution-file (read-file-name "Solution file: ")))
    (let ((to-remove (read-file-name "Project/Pattern to remove from the solution: ")))
      (dotnet-command (concat "dotnet sln " solution-file " remove " to-remove)))))

;;;###autoload
(defun dotnet-sln-list ()
  "List all projects in a Solution."
  (interactive)
  (let ((solution-file (read-file-name "Solution file: ")))
    (dotnet-command (concat "dotnet sln " solution-file " list"))))

;;;###autoload
(defun dotnet-sln-new ()
  "Create a new Solution."
  (interactive)
  (let ((solution-path (read-directory-name "Solution path: ")))
    (dotnet-command (concat "dotnet new sln -o " solution-path))))

(defvar dotnet-test-last-test-proj nil
  "Last unit test project file executed by `dotnet-test'.")

;;;###autoload
(defun dotnet-test (arg)
  "Launch project unit-tests, querying for a project on first call.  With ARG, query for project path again."
  (interactive "P")
  (when (or (not dotnet-test-last-test-proj) arg)
    (setq dotnet-test-last-test-proj (read-file-name "Launch tests for Project file: ")))
  (dotnet-command (concat "dotnet test " dotnet-test-last-test-proj)))

(defun dotnet-command (cmd)
  "Run CMD in an async buffer."
  (async-shell-command cmd "*dotnet*"))

(defun dotnet-find (extension)
  "Search for a EXTENSION file in any enclosing folders relative to current directory."
  (dotnet-search-upwards (rx-to-string extension)
                         (file-name-directory buffer-file-name)))

(defun dotnet-goto (extension)
  "Open file with EXTENSION in any enclosing folders relative to current directory."
  (let ((file (dotnet-find extension)))
    (if file
        (find-file file)
      (error "Could not find any %s file" extension))))

(defun dotnet-goto-sln ()
  "Search for a solution file in any enclosing folders relative to current directory."
  (interactive)
  (dotnet-goto ".sln"))

(defun dotnet-goto-csproj ()
  "Search for a C# project file in any enclosing folders relative to current directory."
  (interactive)
  (dotnet-goto ".csproj"))

(defun dotnet-goto-fsproj ()
  "Search for a F# project file in any enclosing folders relative to current directory."
  (interactive)
  (dotnet-goto ".fsproj"))

(defun dotnet-search-upwards (regex dir)
  "Search for REGEX in DIR."
  (when dir
    (or (car-safe (directory-files dir 'full regex))
        (dotnet-search-upwards regex (dotnet-parent-dir dir)))))

(defun dotnet-parent-dir (dir)
  "Find parent DIR."
  (let ((p (file-name-directory (directory-file-name dir))))
    (unless (equal p dir)
      p)))

(defun dotnet-select-project-or-solution ()
  "Prompt for the project/solution file or directory.  Try projectile root first, else use current buffer's directory."
  (let ((default-dir-prompt "?"))
    (ignore-errors
      (when (fboundp 'projectile-project-root)
        (setq default-dir-prompt (projectile-project-root))))
    (when (string= default-dir-prompt "?")
      (setq default-dir-prompt default-directory))
    (expand-file-name (read-file-name "Project or solution: " default-dir-prompt nil t))))

(defun dotnet-valid-project-solutions (path)
  "Predicate to validate project/solution paths.  PATH is passed by `'read-file-name`."
  ;; file-attributes returns t for directories
  ;; if not a dir, then check the common extensions
  (let ((extension (file-name-extension path))
        (valid-projects (list "sln" "csproj" "fsproj")))
    (or (member extension valid-projects)
        (car (file-attributes path)))))

(defvar dotnet-mode-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "a p") #'dotnet-add-package)
    (define-key map (kbd "a r") #'dotnet-add-reference)
    (define-key map (kbd "b")   #'dotnet-build)
    (define-key map (kbd "c")   #'dotnet-clean)
    (define-key map (kbd "g c") #'dotnet-goto-csproj)
    (define-key map (kbd "g f") #'dotnet-goto-fsproj)
    (define-key map (kbd "g s") #'dotnet-goto-sln)
    (define-key map (kbd "n")   #'dotnet-new)
    (define-key map (kbd "p")   #'dotnet-publish)
    (define-key map (kbd "r")   #'dotnet-restore)
    (define-key map (kbd "e")   #'dotnet-run)
    (define-key map (kbd "C-e") #'dotnet-run-with-args)
    (define-key map (kbd "s a") #'dotnet-sln-add)
    (define-key map (kbd "s l") #'dotnet-sln-list)
    (define-key map (kbd "s n") #'dotnet-sln-new)
    (define-key map (kbd "s r") #'dotnet-sln-remove)
    (define-key map (kbd "t")   #'dotnet-test)
    map)
  "Keymap for dotnet-mode commands after `dotnet-mode-keymap-prefix'.")

(defvar dotnet-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd dotnet-mode-keymap-prefix) dotnet-mode-command-map)
    map)
  "Keymap for dotnet-mode.")

;;;###autoload
(define-minor-mode dotnet-mode
  "dotnet CLI minor mode."
  nil
  " dotnet"
  dotnet-mode-map
  :group 'dotnet
  (add-to-list 'compilation-error-regexp-alist-alist
               (cons 'dotnet dotnet-compilation-regexps))
  (add-to-list 'compilation-error-regexp-alist 'dotnet))


(provide 'dotnet)
;;; dotnet.el ends here
