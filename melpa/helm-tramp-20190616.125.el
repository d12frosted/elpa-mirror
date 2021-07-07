;;; helm-tramp.el --- Tramp helm interface for ssh, docker, vagrant -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2019 by Masashı Mıyaura

;; Author: Masashı Mıyaura
;; URL: https://github.com/masasam/emacs-helm-tramp
;; Package-Version: 20190616.125
;; Package-Commit: 55e56975fe1456591a293bf60c183c3dda9f788f
;; Version: 1.3.9
;; Package-Requires: ((emacs "24.3") (helm "2.0"))

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

;; helm-tramp provides interfaces of Tramp
;; You can also use tramp with helm interface as root
;; If you use it with docker-tramp, you can also use docker with helm interface
;; If you use it with vagrant-tramp, you can also use vagrant with helm interface

;;; Code:

(require 'helm)
(require 'tramp)
(require 'cl-lib)

(defgroup helm-tramp nil
  "Tramp with helm interface for ssh, docker, vagrant"
  :group 'helm)

(defcustom helm-tramp-default-method "ssh"
  "Default method when use tramp multi hop."
  :group 'helm-tramp
  :type 'string)

(defcustom helm-tramp-docker-user nil
  "If you want to use login user name when `docker-tramp' used, set variable."
  :group 'helm-tramp
  :type 'string)

(defcustom helm-tramp-localhost-directory "/"
  "Initial directory when connecting with /sudo:root@localhost:."
  :group 'helm-tramp
  :type 'string)

(defcustom helm-tramp-control-master nil
  "If you want to put out a candidate for completion from ssh controlmaster, please set to t."
  :group 'helm-tramp
  :type 'string)

(defcustom helm-tramp-control-master-path "~/.ssh/"
  "Path where ssh controlmaster exists."
  :group 'helm-tramp
  :type 'string)

(defcustom helm-tramp-control-master-prefix "master-"
  "Prefix of ssh controlmaster."
  :group 'helm-tramp
  :type 'string)

(defcustom helm-tramp-pre-command-hook nil
  "Hook run before `helm-tramp'.
The hook is called with one argument that is non-nil."
  :type 'hook)

(defcustom helm-tramp-post-command-hook nil
  "Hook run after `helm-tramp'.
The hook is called with one argument that is non-nil."
  :type 'hook)

(defcustom helm-tramp-quit-hook nil
  "Hook run when `helm-tramp-quit'.
The hook is called with one argument that is non-nil."
  :type 'hook)

(defcustom helm-tramp-custom-connections '()
  "A list to manually add extra connections.
E.g.: '(/ssh:domain|sudo:user@localhost:/)."
  :type 'string)

(defun helm-tramp-quit ()
  "Quit helm-tramp.
Kill all remote buffers."
  (interactive)
  (run-hooks 'helm-tramp-quit-hook)
  (tramp-cleanup-all-buffers))

(defun helm-tramp--candidates (&optional file)
  "Collect candidates for helm-tramp from FILE."
  (let ((source (split-string
                 (with-temp-buffer
                   (insert-file-contents (or file "~/.ssh/config"))
                   (buffer-string))
                 "\n"))
        (hosts (if file '() helm-tramp-custom-connections)))
    (dolist (host source)
      (when (string-match "[H\\|h]ost +\\(.+?\\)$" host)
	(setq host (match-string 1 host))
	(if (string-match "[ \t\n\r]+\\'" host)
	    (replace-match "" t t host))
	(if (string-match "\\`[ \t\n\r]+" host)
	    (replace-match "" t t host))
        (unless (string= host "*")
	  (if (string-match "[ ]+" host)
	      (let ((result (split-string host " ")))
		(while result
		  (push
		   (concat "/" tramp-default-method ":" (car result) ":")
		   hosts)
		  (push
		   (concat "/" helm-tramp-default-method ":" (car result) "|sudo:root@" (car result) ":/")
		   hosts)
		  (pop result)))
	    (push
	     (concat "/" tramp-default-method ":" host ":")
	     hosts)
	    (push
	     (concat "/" helm-tramp-default-method ":" host "|sudo:root@" host ":/")
	     hosts))))
      (when (string-match "Include +\\(.+\\)$" host)
        (setq include-file (match-string 1 host))
        (when (not (file-name-absolute-p include-file))
          (setq include-file (concat (file-name-as-directory "~/.ssh") include-file)))
        (when (file-exists-p include-file)
          (setq hosts (append hosts (helm-tramp--candidates include-file))))))
    (when helm-tramp-control-master
      (let ((files (helm-tramp--directory-files
		    (expand-file-name
		     helm-tramp-control-master-path)
		    helm-tramp-control-master-prefix))
	    (hostuser nil)
	    (hostname nil)
	    (port nil))
	(dolist (controlmaster files)
	  (let ((file (file-name-nondirectory controlmaster)))
	    (when (string-match
		   (concat helm-tramp-control-master-prefix "\\(.+?\\)@\\(.+?\\):\\(.+?\\)$")
		   file)
	      (setq hostuser (match-string 1 file))
	      (setq hostname (match-string 2 file))
	      (setq port (match-string 3 file))
	      (push
	       (concat "/" tramp-default-method ":" hostuser "@" hostname "#" port ":")
	       hosts)
	      (push
	       (concat "/" helm-tramp-default-method ":" hostuser "@" hostname "#" port "|sudo:root@" hostname ":/")
	       hosts))))))
    (when (require 'docker-tramp nil t)
      (cl-loop for line in (cdr (ignore-errors (apply #'process-lines "docker" (list "ps"))))
	       for info = (reverse (split-string line "[[:space:]]+" t))
	       collect (progn (push
			       (concat "/docker:" (car info) ":/")
			       hosts)
			      (when helm-tramp-docker-user
				(if (listp helm-tramp-docker-user)
				    (let ((docker-user helm-tramp-docker-user))
				      (while docker-user
					(push
					 (concat "/docker:" (car docker-user) "@" (car info) ":/")
					 hosts)
					(pop docker-user)))
				  (push
				   (concat "/docker:" helm-tramp-docker-user "@" (car info) ":/")
				   hosts))))))
    (when (require 'vagrant-tramp nil t)
      (cl-loop for box-name in (cl-map 'list 'cadr (vagrant-tramp--completions))
	       do (progn
		    (push (concat "/vagrant:" box-name ":/") hosts)
		    (push (concat "/vagrant:" box-name "|sudo:" box-name ":/") hosts))))
    (push (concat "/sudo:root@localhost:" helm-tramp-localhost-directory) hosts)
    (reverse hosts)))

(defun helm-tramp--directory-files (dir regexp)
  "Return list of all files under DIR that have file names matching REGEXP."
  (let ((result nil)
	(files nil)
	(tramp-mode (and tramp-mode (file-remote-p (expand-file-name dir)))))
    (dolist (file (sort (file-name-all-completions "" dir)
			'string<))
      (unless (member file '("./" "../"))
	(if (not (helm-tramp--directory-name-p file))
	    (when (string-match regexp file)
	      (push (expand-file-name file dir) files)))))
    (nconc result (nreverse files))))

(defsubst helm-tramp--directory-name-p (name)
  "Return non-nil if NAME ends with a directory separator character."
  (let ((len (length name))
        (lastc ?.))
    (if (> len 0)
        (setq lastc (aref name (1- len))))
    (or (= lastc ?/)
        (and (memq system-type '(windows-nt ms-dos))
             (= lastc ?\\)))))

(defun helm-tramp-open (path)
  "Tramp open with PATH."
  (find-file path))

(defun helm-tramp-open-shell (path)
  "Tramp open shell at PATH."
  (let ((default-directory path))
    (shell (concat "* Helm tramp shell - " path))))

(defvar helm-tramp--source
  (helm-build-sync-source "Tramp"
    :candidates #'helm-tramp--candidates
    :volatile t
    :action (helm-make-actions
             "Tramp" #'helm-tramp-open
             "Shell" #'helm-tramp-open-shell)))

;;;###autoload
(defun helm-tramp ()
  "Open your ~/.ssh/config with helm interface.
You can connect your server with tramp"
  (interactive)
  (unless (file-exists-p "~/.ssh/config")
    (error "There is no ~/.ssh/config"))
  (when (require 'docker-tramp nil t)
    (unless (executable-find "docker")
      (error "'docker' is not installed")))
  (when (require 'vagrant-tramp nil t)
    (unless (executable-find "vagrant")
      (error "'vagrant' is not installed")))
  (run-hooks 'helm-tramp-pre-command-hook)
  (helm :sources '(helm-tramp--source) :buffer "*helm tramp*")
  (run-hooks 'helm-tramp-post-command-hook))

(provide 'helm-tramp)

;;; helm-tramp.el ends here
