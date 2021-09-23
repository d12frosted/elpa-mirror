;;; abl-mode.el --- Python TDD minor mode

;;
;; Author: Ulas Tuerkmen <ulas.tuerkmen at gmail dot com>
;; URL: http://github.com/afroisalreadyinu/abl-mode
;; Package-Version: 20210923.950
;; Package-Commit: fc0eeb780d22aa1aac337f06cc9b479c51600243
;; Version: 0.9.2
;;
;; Copyright (C) 2011 Ulas Tuerkmen
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; The aim of this mode is to make editing Python code in a
;; version-controlled project easier, and enable the execution of
;; repetitive tasks --such as running tests or scripts-- in Emacs
;; shell buffers.  Please see README.rst for details.

;;; Code:
;; <<--------- The necessary minor-mode stuff  ---------->>
(eval-when-compile (require 'cl-lib)
		   (require 'subr-x)
		   (require 'f))

(defgroup abl-mode nil
  "Python TDD minor mode."
  :group 'python)

(defvar abl-mode nil
  "Mode variable for abl-mode.")
(make-variable-buffer-local 'abl-mode)

;;;###autoload
(defun abl-mode (&optional arg)
  "Minor mode for TDD in Python"
  (interactive "P")
  (setq abl-mode (if (null arg) (not abl-mode)
		   (> (prefix-numeric-value arg) 0)))
  (if abl-mode
      (let ((package-base (abl-find-base-dir (buffer-file-name))))
	(if (not package-base)
	    (progn (message "Could not find project base. Please make sure there is a setup.py or requirements.txt in a higher directory.")
		   (setq abl-mode nil))
	  (setq abl-package-base package-base)
	  (setq abl-mode-branch (abl-git-branch abl-package-base))
	  (setq abl-mode-project-name (abl-get-project-name abl-package-base))
	  (setq abl-mode-shell-name (abl-mode-shell-name-for-branch
				     abl-mode-project-name
				     abl-mode-branch))
	  (setq abl-ve-name (abl-make-ve-name))
	  (abl-mode-local-options package-base)))))

;;;###autoload
(defun abl-mode-hook ()
  (abl-mode))

(if (not (assq 'abl-mode minor-mode-alist))
    (setq minor-mode-alist
	  (cons '(abl-mode " abl-mode")
		minor-mode-alist)))

(defvar abl-mode-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c t") 'abl-mode-run-test-at-point)
    (define-key map (kbd "C-c u") 'abl-mode-rerun-last-test)
    (define-key map (kbd "C-c o") 'abl-mode-open-python-path-at-point)
    (define-key map (kbd "C-c m") 'abl-mode-open-module)
    map)
  "The keymap for abl-mode")

(or (assoc 'abl-mode minor-mode-map-alist)
    (setq minor-mode-map-alist
          (cons (cons 'abl-mode abl-mode-keymap)
                minor-mode-map-alist)))

;; <<------------  Customization options  -------------->>

(defcustom abl-mode-ve-activate-command "workon %s"
  "The command for activating a virtual environment")
(make-variable-buffer-local 'abl-mode-ve-activate-command)

(defcustom abl-mode-ve-create-command "mkvirtualenv %s"
  "The command for activating a virtual environment")
(make-variable-buffer-local 'abl-mode-ve-create-command)

(defcustom abl-mode-test-command "python -m unittest %s"
  "The command for running tests")
(make-variable-buffer-local 'abl-mode-test-command)

(defcustom abl-mode-branch-shell-prefix "ABL-SHELL:"
  "Prefix for the shell buffers opened")
(make-variable-buffer-local 'abl-mode-branch-shell-prefix)

(defcustom abl-mode-check-and-activate-ve t
  "Check existence of virtualenv, and activate it when a command is run")
(make-variable-buffer-local 'abl-mode-check-and-activate-ve)

(defcustom abl-mode-ve-base-dir "~/.virtualenvs"
  "base directory for virtual environments")
(make-variable-buffer-local 'abl-mode-ve-base-dir)

(defcustom abl-mode-install-command "python setup.py develop"
  "The command to install a package.")
(make-variable-buffer-local 'abl-mode-install-command)

(defcustom abl-mode-test-file-regexp ".*_tests.py"
  "regexp used to check whether a file is a test file")
(make-variable-buffer-local 'abl-mode-test-file-regexp)

(defcustom abl-file-class-separator "::"
  "string used to separate class name from test file path.")
(make-variable-buffer-local 'abl-file-class-separator)

(defcustom abl-class-method-separator "::"
  "string used to separate class name from test method.")
(make-variable-buffer-local 'abl-class-method-separator)

(defcustom abl-use-test-file-path t
  "Use the file path for referring to a test file. When nil, the
  module name is used")
(make-variable-buffer-local 'abl-mode-use-file-module)

;; <<----------------  Here ends the customization -------------->>

(defvar abl-package-base ""
  "Base directory of the package")
(make-variable-buffer-local 'abl-package-base)

(defvar abl-ve-name ""
  "Name of the virtual env")
(make-variable-buffer-local 'abl-ve-name)

(defvar abl-mode-branch "master"
  "The branch you are working on.When abl-mode is started, it is
  set to the name of the directory in which you are for svn, the
  git branch if you're on git.")
(make-variable-buffer-local 'abl-mode-branch)

(defvar abl-mode-shell-name "ABL-SHELL")
(make-variable-buffer-local 'abl-mode-shell-name)

(defvar abl-mode-project-name "web"
  "The name of the project. ")
(make-variable-buffer-local 'abl-mode-project-name)

(defvar abl-mode-replacement-vems (make-hash-table :test 'equal))

(defvar abl-mode-last-shell-points (make-hash-table :test 'equal))

(defvar abl-mode-last-tests-run (make-hash-table :test 'equal))

(defvar abl-mode-shell-child-cmd
  (if (eq system-type 'darwin)
      "ps -j | grep %d | grep -v grep | grep -v \"/bin/bash\" | wc -l"
    "ps --ppid %d  h | wc -l"))

(defvar abl-mode-identifier-re "[^a-zA-Z0-9_\.]")

;; <<-------------------------------------------------------------->>

(defun abl-find-base-dir (path)
  (or (locate-dominating-file path "setup.py")
      (locate-dominating-file path "requirements.txt")))

(defun abl-capitalized? (strng)
  (s-uppercase? (substring strng 0 1)))


(defun abl-mode-set-config (name value)
  (set (intern name) (eval (read value))))

(defun parse-abl-options (file-path)
  (let ((config-lines (with-temp-buffer
			(insert-file-contents file-path)
			(split-string (buffer-string) "\n" t))))
    (cl-loop for config-line in config-lines
	  do (let* ((parts (split-string config-line))
		    (command-part (car parts))
		    (rest-part (s-join " " (cdr parts))))
	       (abl-mode-set-config command-part rest-part)))))


(defun abl-mode-local-options (base-dir)
  (let ((file-path (f-join base-dir ".abl")))
    (if (file-exists-p file-path)
	 (parse-abl-options file-path)
      nil)))

(defun abl-git-branch (base-dir)
  (let* ((command (concat "cd " base-dir " && git branch --show-current"))
	 (git-output (shell-command-to-string command)))
    (if (string-match-p (regexp-quote "fatal: not a git repository") git-output)
	nil
      (string-trim git-output))))

(defun abl-get-project-name (path)
  "Returns the name of the project, which will be the directory in which the setup.py is."
  (car (last (f-split (abl-find-base-dir path)))))

(defun abl-make-ve-name (&optional branch project)
  (let ((branch-name (or branch abl-mode-branch))
	(prjct-name (or project abl-mode-project-name)))
    (or
     (gethash abl-mode-shell-name abl-mode-replacement-vems nil)
     (if (not branch-name)
	 prjct-name
     (s-join "_" (list prjct-name (replace-regexp-in-string "/" "-" branch-name)))))))

;;<< ---------------  Shell stuff  ----------------->>

(defun abl-mode-shell-name-for-branch (project-name branch-name)
  (concat abl-mode-branch-shell-prefix project-name "_" branch-name))


(defun abl-shell-busy (&optional shell-name)
  "Find out whether the shell has any child processes
running using ps."
  (let ((abl-shell-buffer (get-buffer (or shell-name abl-mode-shell-name))))
    (if (not abl-shell-buffer)
	nil
      (let* ((shell-process-id (process-id (get-buffer-process abl-shell-buffer)))
	     (command (format abl-mode-shell-child-cmd shell-process-id))
	     (output (shell-command-to-string command)))
	(/= (string-to-number output) 0)))))

(defun abl-mode-exec-command (command)
  (let* ((new-or-name (abl-ve-name-or-create abl-ve-name))
	 (ve-name (car new-or-name))
	 (create-vem (cdr new-or-name))
	 (shell-name abl-mode-shell-name)
	 (commands
	  (cond (create-vem (list (concat "cd " abl-package-base)
				  (format abl-mode-ve-create-command ve-name)
				  (format abl-mode-ve-activate-command ve-name)
				  abl-mode-install-command
				  command))
		((not ve-name) (list (concat "cd " abl-package-base)
					  command))
		(t (list (concat "cd " abl-package-base)
			 (format abl-mode-ve-activate-command ve-name)
			 command))))
	 (open-shell-buffer (get-buffer shell-name))
	 (open-shell-window (if open-shell-buffer
				(get-buffer-window-list shell-name nil t)
			      nil))
	 (code-window (selected-window)))
    (if open-shell-window
	(select-window (car open-shell-window))
      (if open-shell-buffer
	  (switch-to-buffer open-shell-buffer)
	(shell shell-name)
	(sleep-for 2)))
    (goto-char (point-max))
    (puthash shell-name (point) abl-mode-last-shell-points)
    (insert (s-join " && " commands))
    (comint-send-input)
    (select-window code-window)))


(defun abl-ve-name-or-create (name &optional is-replacement)
  (if (not abl-mode-check-and-activate-ve)
      (cons nil nil)
    (let ((vem-path (expand-file-name name abl-mode-ve-base-dir)))
      (if (file-exists-p vem-path)
	  (progn (puthash
		  abl-mode-shell-name
		  name
		  abl-mode-replacement-vems)
		 (setq abl-ve-name name)
		 (cons name nil))
	(let* ((command-string
		(format
		 "No virtualenv %s; y to create it, or name of existing to use instead: "
		 name))
	     (vem-or-y (read-from-minibuffer command-string))
	     (create-new (or (string-equal vem-or-y "y") (string-equal vem-or-y "Y"))))
	  (if create-new
	      (cons name create-new)
	    (abl-ve-name-or-create vem-or-y 't)))))))

;; <<------------  Figuring out what test to run -------->>

(defun abl-class-and-indent ()
  "Return name of the class the cursor is in, its indentation
level and the line it's at. All are nil if there is no class
declaration above the current point."
  (save-excursion
    (if (not (re-search-backward "^ *class .*" nil t))
	(list nil nil nil)
    (let* ((line (s-trim-right (thing-at-point 'line t)))
	   (class-indentation (length (progn (string-match "^ *" line) (match-string 0 line))))
	   (class-name (s-chop-prefix
			"class "
			(progn (string-match "class [^(]*" line) (match-string 0 line)))))
      (list class-name class-indentation (line-number-at-pos))))))


(defun abl-function-and-indent ()
  "Return name of the function the cursor is in, its indentation
level and the line it's at. If there is no test function in the
text above, all are nil."
  (save-excursion
    (end-of-line)
    (if (not (re-search-backward "^ *def test_*" nil t))
	(list nil nil nil)
    ;; we are now at the beginning of the line with "def test"
    (let* ((line (s-trim-right (thing-at-point 'line t)))
	   (test-indentation (length (progn (string-match "^ *" line) (match-string 0 line))))
	   (func-name (progn (string-match "test_[^(]*" line) (match-string 0 line))))
      (list func-name test-indentation (line-number-at-pos))))))


(defun abl-mode-get-test-entity ()
  "Which tests should be run? If this is a test file, depending
on where the cursor is, test whole file, class, or test method.
Error if none of these is true."
  (let* ((relative-path (file-relative-name (buffer-file-name) abl-package-base))
	 (file-entity (if abl-use-test-file-path
			  relative-path
			(replace-regexp-in-string "/" "." (f-no-ext relative-path)))))
    (if (= (line-number-at-pos) 1)
	file-entity
      (cl-destructuring-bind (func-name func-indent func-loc) (abl-function-and-indent)
	(cl-destructuring-bind (class-name class-indent class-loc) (abl-class-and-indent)
	(cond ((and func-name (not class-name))
	       (concat file-entity abl-file-class-separator func-name))
	      ((and (not func-name) class-name)
	       (concat file-entity abl-file-class-separator class-name))
	      ((and class-name func-name (< class-loc func-loc) (< class-indent func-indent))
	       ;; function in class
	       (concat file-entity abl-file-class-separator class-name abl-class-method-separator func-name))
	      ((and class-name func-name (> class-loc func-loc) (<= class-indent func-indent))
	       ;; class comes after function but is the right context
	       (concat file-entity abl-file-class-separator class-name))
	      ((and class-name func-name (< class-loc func-loc) (<= func-indent class-indent))
	       ;; function after class and is indented less or equal, i.e. is the right context
	       (concat file-entity abl-file-class-separator func-name))
	      (t (error "You do not appear to be in a recognized test entity")))
	   )))))


;; <<------------  Running tests   -------->>

(defun abl-mode-run-test (test-path &optional branch-name)
  (if (abl-shell-busy)
      (message "The shell is busy; please end the process before running a test")
    (let* ((shell-command (format abl-mode-test-command test-path))
	   (shell-name abl-mode-shell-name))
      (message (format "Running test(s) %s on %s" test-path shell-name))
      (abl-mode-exec-command shell-command)
      (puthash shell-name
	       test-path
	       abl-mode-last-tests-run))))


(defun abl-mode-run-test-at-point ()
  (interactive)
  (let* ((test-path (abl-mode-get-test-entity)))
    (abl-mode-run-test test-path)))

(defun abl-mode-rerun-last-test ()
  (interactive)
  (let ((last-run (gethash abl-mode-shell-name abl-mode-last-tests-run)))
    (if (not last-run)
	(message "You haven't run any tests yet.")
      (abl-mode-run-test last-run))))

(provide 'abl-mode)


;;; abl-mode.el ends here
