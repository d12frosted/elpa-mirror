;;; pnpm-mode.el --- Minor mode for working with pnpm projects

;; Version: 1.0.0
;; Package-Version: 20200527.557
;; Package-Commit: 391207e6505948b0d0cb57b802ee4885e3292c21
;; Author: Rajasegar Chandran <rajasegar.c@gmail.com>
;; Url: https://github.com/rajasegar/pnpm-mode
;; Keywords: convenience, project, javascript, node, npm, pnpm
;; Package-Requires: ((emacs "24.1"))

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

;; This package allows you to easily work with pnpm projects.  It provides
;; a minor mode for convenient interactive use of API with a
;; mode-specific command keymap.
;;
;; | command                      | keymap       | description                         |
;; |------------------------------+--------------+-------------------------------------|
;; | pnpm-mode-npm-init           | <kbd>n</kbd> | Initialize new project              |
;; | pnpm-mode-pnpm-install       | <kbd>i</kbd> | Install all project dependencies    |
;; | pnpm-mode-pnpm-add           | <kbd>s</kbd> | Add new project dependency          |
;; | pnpm-mode-pnpm-add-save-dev  | <kbd>d</kbd> | Add new project dev dependency      |
;; | pnpm-mode-pnpm-remove        | <kbd>u</kbd> | Remove project dependency           |
;; | pnpm-mode-pnpm-update        | <kbd>U</kbd> | Update project dependency           |
;; | pnpm-mode-pnpm-list          | <kbd>l</kbd> | List installed project dependencies |
;; | pnpm-mode-pnpm-run           | <kbd>r</kbd> | Run project script                  |
;; | pnpm-mode-pnpm-test          | <kbd>t</kbd> | Run project test script             |
;; | pnpm-mode-visit-project-file | <kbd>v</kbd> | Visit project package.json file     |
;; |                              | <kbd>?</kbd> | Display keymap commands             |

;;; Credit:

;; This package began as an inspiration of the npm-mode package.
;; Many thanks to Alen Gooch for his contribution.
;; https://github.com/mojochao/npm-mode repo.

;;; Code:

(require 'json)

(defvar pnpm-mode--project-file-name "package.json"
  "The name of pnpm project files.")

(defvar pnpm-mode--modeline-name " pnpm"
  "Name of pnpm mode modeline name.")

(defun pnpm-mode--ensure-pnpm-module ()
  "Asserts that you're currently inside an pnpm module."
  (pnpm-mode--project-file))

(defun pnpm-mode--project-file ()
  "Return path to the project file, or nil.
If project file exists in the current working directory, or a
parent directory recursively, return its path.  Otherwise, return
nil."
  (let ((dir (locate-dominating-file default-directory pnpm-mode--project-file-name)))
    (unless dir
      (error (concat "Error: cannot find " pnpm-mode--project-file-name)))
    (concat dir pnpm-mode--project-file-name)))

(defun pnpm-mode--get-project-property (prop)
  "Get the given PROP from the current project file."
  (let* ((project-file (pnpm-mode--project-file))
         (json-object-type 'hash-table)
         (json-contents (with-temp-buffer
                          (insert-file-contents project-file)
                          (buffer-string)))
         (json-hash (json-read-from-string json-contents))
         (value (gethash prop json-hash))
         (commands (list)))
    (cond ((hash-table-p value)
           (maphash (lambda (key value)
                      (setq commands
                            (append commands
                                    (list (list key (format "%s %s" "pnpm" key))))))
                    value)
           commands)
          (t value))))

(defun pnpm-mode--get-project-scripts ()
  "Get a list of project scripts."
  (pnpm-mode--get-project-property "scripts"))

(defun pnpm-mode--get-project-dependencies ()
  "Get a list of project dependencies."
  (pnpm-mode--get-project-property "dependencies"))

(defun pnpm-mode--exec-process (cmd &optional comint)
  "Execute a process running CMD.
Optional argument COMINT ."
  (let ((compilation-buffer-name-function
         (lambda (mode)
           (format "*pnpm:%s - %s*"
                   (pnpm-mode--get-project-property "name") cmd))))
    (message (concat "Running " cmd))
    (compile cmd comint)))

(defun pnpm-mode-pnpm-clean ()
  "Remove the node_modules folder."
  (interactive)
  (let ((dir (concat (file-name-directory (pnpm-mode--ensure-pnpm-module)) "node_modules")))
    (if (file-directory-p dir)
      (when (yes-or-no-p (format "Are you sure you wish to delete %s" dir))
        (pnpm-mode--exec-process (format "rm -rf %s" dir)))
      (message (format "%s has already been cleaned" dir)))))

(defun pnpm-mode-npm-init ()
  "Run the pnpm init command."
  (interactive)
  (pnpm-mode--exec-process "npm init" t))

(defun pnpm-mode-pnpm-install ()
  "Run the 'pnpm install' command."
  (interactive)
  (pnpm-mode--exec-process "pnpm install" t))

(defun pnpm-mode-pnpm-add (dep)
  "Run the 'pnpm add' command for DEP."
  (interactive "sEnter package name: ")
  (pnpm-mode--exec-process (format "pnpm add %s " dep)))

(defun pnpm-mode-pnpm-add-dev (dep)
  "Run the 'pnpm add -D' command for DEP."
  (interactive "sEnter package name: ")
  (pnpm-mode--exec-process (format "pnpm add %s -D" dep)))

(defun pnpm-mode-pnpm-remove ()
  "Run the 'pnpm remove' command."
  (interactive)
  (let ((dep (completing-read "Remove dependency: " (pnpm-mode--get-project-dependencies))))
    (pnpm-mode--exec-process (format "pnpm remove %s" dep))))

(defun pnpm-mode-pnpm-list ()
  "Run the 'pnpm list' command."
  (interactive)
  (pnpm-mode--exec-process "pnpm list --depth=0"))

(defun pnpm-run--read-command ()
  (completing-read "Run script: " (pnpm-mode--get-project-scripts)))

(defun pnpm-mode-pnpm-run (script &optional comint)
  "Run the 'pnpm run' command on a project SCRIPT.
Optional argument COMINT ."
  (interactive
   (list (pnpm-run--read-command)
         (consp current-prefix-arg)))
  (pnpm-mode--exec-process (format "pnpm run %s" script) comint))

(defun pnpm-mode-visit-project-file ()
  "Visit the project file."
  (interactive)
  (find-file (pnpm-mode--project-file)))

(defun pnpm-mode-pnpm-update ()
  "Run the 'pnpm update' command."
  (interactive)
  (pnpm-mode--exec-process "pnpm update"))

(defun pnpm-mode-pnpm-test ()
  "Run the 'pnpm test' command."
  (interactive)
  (pnpm-mode--exec-process "pnpm test"))

(defgroup pnpm nil
  "Customization group for pnpm-mode."
  :group 'convenience)

(defcustom pnpm-mode-command-prefix "C-c n"
  "Prefix for variable `pnpm-mode'."
  :group 'pnpm-mode
  :type 'string)

(defvar pnpm-mode-command-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map "n" 'pnpm-mode-pnpm-init)
    (define-key map "i" 'pnpm-mode-pnpm-install)
    (define-key map "s" 'pnpm-mode-pnpm-add)
    (define-key map "d" 'pnpm-mode-pnpm-add-dev)
    (define-key map "u" 'pnpm-mode-pnpm-remove)
    (define-key map "U" 'pnpm-mode-pnpm-remove)
    (define-key map "l" 'pnpm-mode-pnpm-list)
    (define-key map "r" 'pnpm-mode-pnpm-run)
    (define-key map "v" 'pnpm-mode-visit-project-file)
    (define-key map "t" 'pnpm-mode-pnpm-test)
    map)
  "Keymap for variable `pnpm-mode' commands.")

(defvar pnpm-mode-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd pnpm-mode-command-prefix) pnpm-mode-command-keymap)
    map)
  "Keymap for variable `pnpm-mode'.")

;;;###autoload
(define-minor-mode pnpm-mode
  "Minor mode for working with pnpm projects."
  nil
  pnpm-mode--modeline-name
  pnpm-mode-keymap
  :group 'pnpm-mode)

;;;###autoload
(define-globalized-minor-mode pnpm-global-mode
  pnpm-mode
  pnpm-mode)

(provide 'pnpm-mode)
;;; pnpm-mode.el ends here
