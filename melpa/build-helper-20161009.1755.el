;;; build-helper.el --- Utilities to help build code -*- lexical-binding: t -*-

;; Copyright (C) 2016 Afonso Bordado

;; Author:  Afonso Bordado <afonsobordado@az8.co>
;; Version: 0.1
;; Package-Version: 20161009.1755
;; Package-Commit: d1962858734253eca791721ccf62d1c4a10719f5
;; URL: http://github.com/afonso360/build-helper
;; Keywords: convenience
;; Package-Requires: ((projectile "0.9.0"))

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
;; build-helper helps you set your build configurations in order.
;; enabling you to have different commands to build, run, test, etc.. per project
;; these commands persist across Emacs sessions and in the same project
;; different major modes can have different run commands

;;; Usage:
;; For a quick setup add these lines to your init.el
;;
;; (require 'build-helper)
;; (build-helper-setup)
;;
;; and M-x build-helper-run to build
;; you can then use M-x build-helper-re-run to run the last command
;;
;; you can bind these to your preferred keys, however there are convinience
;; functions that run and re-run common targets (run, build, test)
;; these have the name build-helper-run-TARGET and build-helper-re-run-TARGET
;; replacing target with one of the 3 preset targets
;;
;; Advanced functionality
;; build-helper can also run functions from other packages, for example
;; if you use cmake-ide-mode, you will most certainly want to execute
;; `cmake-ide-compile' when executing the run target on c++-mode
;; to achieve this add the following code to the init.el file
;;
;; (build-helper-add-function 'c++-mode 'run #'cmake-ide-compile)
;;
;; This adds the function `cmake-ide-compile' to be executed when the user
;; executes the "run" target in c++-mode on any project
;;
;; Function return values:
;; The return value of the executed functions is checked, when t no other function
;; will be executed and the user will not be prompted for a command.
;; If all the functions return nil the user will be prompted as usual
;;
;; To ensure a function returns t you can add the following instead
;;
;; (build-helper-add-function 'c++-mode 'run #'(lambda () (cmake-ide-compile) t))


;; Some code based on company-statistics.el
;; https://github.com/company-mode/company-statistics

;;; Code:
(require 'projectile)

(defgroup build-helper nil
  "Helper functions to build files."
  :group 'tools)

(defcustom build-helper-file
  (concat user-emacs-directory ".build-helper-targets.el")
  "File to save build-helper command history."
  :group 'build-helper
  :type 'string)

(defcustom build-helper-functions '()
  "List of functions to run per major mode and per target."
  :group 'build-helper
  :type '(alist :tag "Major mode list"
		:key-type (symbol :tag "Major mode")
		:value-type (alist :tag "Target list"
				   :key-type (symbol :tag "Target")
				   :value-type (repeat :tag "Functions" function))))

(defcustom build-helper-comint '()
  "Comint settings for the compile buffer per major mode and per target."
  :group 'build-helper
  :type '(alist :tag "Major mode list"
		:key-type (symbol :tag "Major mode")
		:value-type (alist :tag "Target list"
				   :key-type (symbol :tag "Target")
				   :value-type (group (choice (const :tag "Compilation mode" nil)
							      (const :tag "Comint mode" t))))))

(defvar build-helper--targets '()
  "Build helper targets.")

(defun build-helper--save-targets ()
  "Save the targets to the ‘build-helper-file’."
  (with-temp-buffer
    (insert (format "(setf build-helper--targets '%S)" build-helper--targets))
    (write-file build-helper-file nil)))

(defun build-helper--load-targets ()
  "Load the targets from ‘build-helper-file’."
  (ignore-errors
    (load build-helper-file)))

(defun build-helper--get-comint (major target)
  "Get the comint value for the specified MAJOR mode and TARGET or nil.
Unlike with targets these values are not saved"
  (car (alist-get target (alist-get major build-helper-comint  nil) nil)))

(defun build-helper--set-comint (major target value)
  "For the specified MAJOR mode and TARGET set the comint VALUE.
By default the value is nil."
  (push value
	(alist-get target
		   (alist-get major build-helper-comint  nil) nil)))

(defun build-helper--get-target (project major target)
  "Get `compile-history' list for PROJECT for MAJOR mode and TARGET.
If any of those is not found return nil."
  (let ((nplist (assoc-string project build-helper--targets)))
    (when nplist
      (alist-get target (alist-get major (cdr nplist) nil) nil))))

(defun build-helper--get-target-string-list (project major)
  "Return a list of string targets for PROJECT and MAJOR mode."
  (mapcar
   #'(lambda (a)
       (symbol-name (car a)))
   (cdr (assoc major (cdr (assoc project build-helper--targets))))))

(defun build-helper--add-command-to-target (project major target command)
  "Add an entry to a PROJECT in a MAJOR mode for a TARGET,the entry is COMMAND.
If any of PROJECT, MAJOR or TARGET are not found create them."
  (let ((nplist (assoc-string project build-helper--targets)))
    (if nplist
	(setf build-helper--targets (delete nplist build-helper--targets))
      (setq nplist (cons project '())))
    (push command (alist-get target (alist-get major (cdr nplist) nil) nil))
    (delete nplist build-helper--targets)
    (push nplist build-helper--targets)))

(defun build-helper--run-all-functions (major target)
    "Run all functions associated with a MAJOR mode and TARGET.

Functions will be executed in the order that they were registered in.

Should any function return t halt the execution of the following functions
otherwise keep executing.

If the last function returns nil, or if there is no functions to be executed
return nil, otherwise return t"
    (let ((funlist (alist-get target
			      (alist-get major build-helper-functions nil) nil)))
      (when funlist
	(let (value)
	  (dolist (fun (reverse funlist) value)
	    (unless value
	      (setq value (funcall fun))))))))

(defun build-helper-add-function (major target function)
  "Add to a MAJOR mode and TARGET a FUNCTION to be executed when ran.

Functions are guaranteed to be executed in the order of registration.
If a function returns t no other functions will be executed.
Should the last function return nil, a compilation command will be asked."
  (push function
	(alist-get target
		   (alist-get major build-helper-functions nil) nil)))

;;;###autoload
(defun build-helper-setup ()
  "Setup build-helper."
  (build-helper--load-targets)
  (add-hook 'kill-emacs-hook 'build-helper--save-targets))

;;;###autoload
(defun build-helper-re-run (target)
  "Run the last command or functions associated with a TARGET."
  (interactive
   (list (completing-read "Target: "
			  (build-helper--get-target-string-list
			   (projectile-project-root)
			   major-mode))))
  (when (stringp target)
    (setq target (intern target)))

  (let* ((compile-history (build-helper--get-target (projectile-project-root)
						    major-mode
						    target))
	 (comint (build-helper--get-comint major-mode target)))
    ;; when we have a compile history, run normally
    (when compile-history
      (unless (build-helper--run-all-functions major-mode target)
	(let ((default-directory (projectile-project-root)))
	  (compile (car compile-history) comint))))

    ;; when we don't have a compile history, run the normal run
    (unless compile-history
      (build-helper-run target))))

;;;###autoload
(defun build-helper-run (target)
  "Run functions associated with TARGET, prompt if all fail.

This runs functions associated with the current `major-mode' and TARGET.

If all functions return nil, display a prompt with history of the last commands
executed in this project, `major-mode' and target.

This compile command will be executed from the function `projectile-project-root' directory."
  (interactive
   (list (completing-read "Target: "
			  (build-helper--get-target-string-list
			   (projectile-project-root)
			   major-mode)
			  nil)))
  (when (stringp target)
    (setq target (intern target)))
  (unless (build-helper--run-all-functions major-mode target)
    (let* ((compile-history (build-helper--get-target (projectile-project-root)
						      major-mode
						      target))
	   (comint (build-helper--get-comint major-mode target))
	   (command (read-from-minibuffer (format "'%s' command: " target)
					  nil
					  nil
					  nil
					  '(compile-history . 1)
					  (car compile-history))))

      (unless (string-equal (car compile-history) (cadr compile-history))
	(build-helper--add-command-to-target (projectile-project-root)
					     major-mode
					     target command))

      (let ((default-directory (projectile-project-root)))
	(compile command comint)))))

;;;###autoload
(defun build-helper-re-run-test ()
  "Run `build-helper-re-run' with target test."
  (interactive)
  (build-helper-re-run 'test))

;;;###autoload
(defun build-helper-re-run-build ()
  "Run `build-helper-re-run' with target build."
  (interactive)
  (build-helper-re-run 'build))

;;;###autoload
(defun build-helper-re-run-run ()
  "Run `build-helper-re-run' with target run."
  (interactive)
  (build-helper-re-run 'run))

;;;###autoload
(defun build-helper-run-test ()
  "Run `build-helper-run' with target test."
  (interactive)
  (build-helper-run 'test))

;;;###autoload
(defun build-helper-run-build ()
  "Run `build-helper-run' with target build."
  (interactive)
  (build-helper-run 'build))

;;;###autoload
(defun build-helper-run-run ()
  "Run `build-helper-run' with target run."
  (interactive)
  (build-helper-run 'run))

(provide 'build-helper)
;;; build-helper.el ends here
