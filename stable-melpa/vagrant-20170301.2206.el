;;; vagrant.el --- Manage a vagrant box from emacs

;;; Version: 0.6.2
;; Package-Version: 20170301.2206
;; Package-Commit: 636ce2f9af32ea199170335a9cf1201b64873440
;;; Author: Robert Crim <rob@servermilk.com>
;;; Url: https://github.com/ottbot/vagrant.el
;;; Keywords: vagrant chef
;;; Created: 08 August 2013

;;; Commentary:

;; This package lets you send vagrant commands while working within a
;; project containing a Vagrantfile.
;;
;; It will traverse the directory tree until a Vagrantfile is found
;; and assume this is the box you want to work with. It can be handy
;; to bring a box up, (re)provision, or even ssh to without leaving
;; emacs.
;;
;; The emacs command `vagrant-up` will run `vagrant up` in a shell,
;; other commands follow the pattern `vagrant-X` emacs command runs
;; `vagrant X` in the shell. An exception is vagrant-edit, which will
;; open the Vagrantfile for editing.

;;; Code:
(defgroup vagrant nil
  "Customization group for `vagrant.el'."
  :group 'tools)

(defcustom vagrant-up-options ""
  "Options to run vagrant up command"
  :group 'vagrant)

(defcustom vagrant-project-directory "~/vagrant"
  "The path to a Vagrant sandbox."
  :group 'vagrant
  :type 'string)

;;;###autoload
(defun vagrant-up ()
  "Bring up the vagrant box."
  (interactive)
  (vagrant-command (concat "vagrant up " vagrant-up-options)))

;;;###autoload
(defun vagrant-provision ()
  "Provision the vagrant box."
  (interactive)
  (vagrant-command "vagrant provision"))

;;;###autoload
(defun vagrant-destroy ()
  "Destroy the vagrant box."
  (interactive)
  (vagrant-command "vagrant destroy"))

;;;###autoload
(defun vagrant-reload ()
  "Reload the vagrant box."
  (interactive)
  (vagrant-command "vagrant reload"))

;;;###autoload
(defun vagrant-resume ()
  "Resume the vagrant box."
  (interactive)
  (vagrant-command "vagrant resume"))

;;;###autoload
(defun vagrant-ssh ()
  "SSH to the vagrant box."
  (interactive)
  (vagrant-command "vagrant ssh"))

;;;###autoload
(defun vagrant-status ()
  "Show the vagrant box status."
  (interactive)
  (vagrant-command "vagrant status"))

;;;###autoload
(defun vagrant-suspend ()
  "Suspend the vagrant box."
  (interactive)
  (vagrant-command "vagrant suspend"))

;;;###autoload
(defun vagrant-halt ()
  "Halt the vagrant box."
  (interactive)
  (vagrant-command "vagrant halt"))

;;;###autoload
(defun vagrant-rsync ()
  "Rsync the vagrant box."
  (interactive)
  (vagrant-command "vagrant rsync"))

;;;###autoload
(defun vagrant-edit ()
  "Edit the Vagrantfile."
  (interactive)
  (find-file (vagrant-locate-vagrantfile)))

(defvar-local vagrant-vagrantfile nil
  "Default path to Vagrantfile")

(defun vagrant-locate-vagrantfile (&optional dir)
  "Find Vagrantfile for DIR."
  (or (locate-dominating-file (or dir default-directory) "Vagrantfile")
      (or vagrant-vagrantfile
          (error "No Vagrantfile found in %s or any parent directory" dir))))

(defun vagrant-command (cmd)
  "Run the vagrant command CMD in an async buffer."
  (let* ((default-directory (file-name-directory (vagrant-locate-vagrantfile)))
         (name (if current-prefix-arg
                   (completing-read "Vagrant box: " (vagrant-box-list)))))
    (async-shell-command (if name (concat cmd " " name) cmd) "*Vagrant*")))

(defun vagrant-box-list ()
  "List of vagrant box names."
  (let ((dir ".vagrant/machines/"))
    (delq nil
          (mapcar (lambda (name)
                    (and (not (member name '("." "..")))
                         (file-directory-p (concat dir name))
                         name))
                  (directory-files dir)))))

(provide 'vagrant)

;;; vagrant.el ends here
