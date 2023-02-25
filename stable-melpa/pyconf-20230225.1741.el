;;; pyconf.el --- Set up python execution configurations like dap-mode ones
;;
;; Copyright (C) 2022 Andrew Favia
;; Author: Andrew Favia <drewlinguistics01 at gmail dot com>
;; Version: 0.1.0
;; Package-Version: 20230225.1741
;; Package-Commit: 25adcbdc007011f2b6f4b5b0a6748298ab229fc2
;; Package-Requires: ((pyvenv "1.21") (emacs "28.1") (transient "0.3.7") (pyenv-mode "0.1.0"))
;; Keywords: processes, python
;; URL: https://github.com/andcarnivorous/pyconf
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; This small package provides a class and functions to set up python execution configurations.
;; It is possible to configure the python execution command, virtualenv to load and use for the run,
;; environment variables, parameters to pass and the directory where to execute the python file.
;;
;; Usage:
;;
;; You can use the `pyconf-add-config' function passing a `pyconf-config' object
;; You can then call `pyconf-start' to execute one of your configurations
;; Example:
;; (pyconf-add-config (pyconf-config :name "test1"
;;                                   :pyconf-exec-command "python3"
;;                                   :pyconf-file-to-exec "~/test/test.py"
;;                                   :pyconf-path-to-exec "~/test/"
;;                                   :pyconf-params "--verbose"
;;                                   :pyconf-venv "~/test/.venv/"
;;                                   :pyconf-env-vars '("TEST5=5")))
;;
;; Add multiple configurations:
;; (pyconf-add-configurations `(,(pyconf-config :name "test3"
;;                                              :pyconf-exec-command "python3 -i"
;;                                              :pyconf-file-to-exec "~/test/test.py"
;;                                              :pyconf-path-to-exec "~/test/"
;;                                              :pyconf-params ""
;;                                              :pyconf-venv "~/test/.venv/"
;;                                              :pyconf-env-vars '("TEST5=5"))
;;                              ,(pyconf-config :name "test2"
;;                                              :pyconf-exec-command "python3 -i"
;;                                              :pyconf-file-to-exec "~/test/test.py"
;;                                              :pyconf-path-to-exec "~/test/"
;;                                              :pyconf-params ""
;;                                              :pyconf-venv "~/test/.venv/"
;;                                              :pyconf-env-vars '("TEST5=5"))))
;;
;;; Code:

(require 'eieio)
(require 'subr-x)
(require 'pyvenv)
(require 'transient)
(require 'pyenv-mode)

(defvar pyconf-config-list '())

(defun pyconf-run-python-proc (command-s path-to-file exec-dir &optional params venv pyenv-version env-vars)
  "Execute COMMAND-S pointing to PATH-TO-FILE.
Set the `default-directory' to EXEC-DIR if provided and pass the
PARAMS given.  Load with `pyvenv' the VENV virtualenv if provided,
othersiwe if PYENV-VERSION is provided use `pyenv'.
finally, set the ENV-VARS if provided."
  (let ((venv (pyconf--is-empty-string venv))
        (params (pyconf--is-empty-string params))
        (env-vars (or env-vars nil))
        (pyenv-version (pyconf--is-empty-string pyenv-version))
        (cached-venv nil)
        (built-env-vars nil))
    (when (or venv pyenv-version)
      (if (or pyvenv-virtual-env (pyenv-mode-version))
          (setq cached-venv (or pyvenv-virtual-env (pyenv-mode-version))))
      (pyconf-venv-or-pyenv venv pyenv-version))
    (if (> (length env-vars) 0)
        (setq built-env-vars (string-join env-vars " ")))
    (let ((default-directory exec-dir))
      (pyconf--run-shell-command built-env-vars command-s path-to-file params))
    (if cached-venv
        (pyconf-venv-or-pyenv venv pyenv-version)
      (pyvenv-deactivate))))

(defun pyconf--run-shell-command (built-env-vars command-s path-to-file params)
  "Run given COMMAND-S preceded by BUILT-ENV-VARS and followed by PATH-TO-FILE and PARAMS."
      (async-shell-command
       (string-join (list built-env-vars command-s path-to-file params) " ") (format "*PyConf %s*" path-to-file)))

(defun pyconf-venv-or-pyenv (venv pyenv-version)
  "Check if only one of VENV or PYENV-VERSION is nil and activate."
  (cond ((and venv pyenv-version)
         (error "Pyconf Configuration cannot have both a pyenv and a venv reference"))
        ((not venv)
         (pyconf-pyenv-activate pyenv-version))
        ((not pyenv-version)
         (pyconf-venv-activate venv))
        ((and (not venv) (not pyenv-version))
         (message "no venv or pyenv passed"))))

(defun pyconf-pyenv-activate (pyenv-version)
  "Unset any active pyenv version and then set it to PYENV-VERSION."
  (pyenv-mode-unset)
  (pyenv-mode-set pyenv-version))

(defun pyconf-venv-activate (venv)
  "Activate given VENV after deactivating any eventual active one."
  (pyvenv-deactivate)
  (pyvenv-activate venv))

(defclass pyconf-config ()
  ((name :initarg :name
         :type string
         :custom string)
   (pyconf-exec-command :initarg :pyconf-exec-command
                        :type string
                        :custom string)
   (pyconf-file-to-exec :initarg :pyconf-file-to-exec
                        :type string
                        :custom string)
   (pyconf-path-to-exec :initarg :pyconf-path-to-exec
                        :type string
                        :custom string
                        :initform ".")
   (pyconf-params :initarg :pyconf-params
                  :type string
                  :custom string)
   (pyconf-venv :initarg :pyconf-venv
                :type string
                :custom string
                :initform "")
   (pyconf-pyenv :initarg :pyconf-pyenv
                  :type string
                  :custom string
                  :initform "")
   (pyconf-env-vars :initarg :pyconf-env-vars
                    :type list
                    :custom list
                    :initform '())))

(defun pyconf-execute-config (pyconf-config-obj)
  "Pass to the PYCONF-RUN-PYTHON-PROC all the values from PYCONF-CONFIG-OBJ."
  (pyconf-run-python-proc (slot-value pyconf-config-obj 'pyconf-exec-command)
                          (slot-value pyconf-config-obj 'pyconf-file-to-exec)
                          (slot-value pyconf-config-obj 'pyconf-path-to-exec)
                          (slot-value pyconf-config-obj 'pyconf-params)
                          (slot-value pyconf-config-obj 'pyconf-venv)
                          (slot-value pyconf-config-obj 'pyconf-pyenv)
                          (slot-value pyconf-config-obj 'pyconf-env-vars)))

(defun pyconf-start (choice)
  "Prompt to choose one CHOICE configuration and then execute it."
  (interactive
   (let ((completion-ignore-case  t))
     (list (completing-read "Choose Config: " pyconf-config-list nil t))))
  (pyconf-execute-config (cdr (assoc choice pyconf-config-list)))
  choice)

(defun pyconf-add-config (config-listp)
  "Add CONFIG-LISTP configuration to PYCONF-CONFIG-LIST."
  (let ((config-name (slot-value config-listp 'name)))
    (add-to-list 'pyconf-config-list `(,(slot-value config-listp 'name) . ,config-listp))))

(defun pyconf-add-configurations (configurations-list)
  "Add a list of configurations from CONFIGURATIONS-LIST to the PYCONF-CONFIG-LIST."
  (dolist (configuration-item configurations-list)
    (pyconf-add-config configuration-item)))

(defun pyconf--eval-env-vars (vars-list)
  "Evaluate elisp code stored in a string."
  (eval (car (read-from-string vars-list))))

(transient-define-suffix pyconf-transient-save (&optional args)
  "Save a pyconf configuration given the necessary parameters."
  :key "s"
  :description "save"
  :transient nil
  (interactive (list (transient-args transient-current-command)))
  (let ((config-name (or (transient-arg-value "--name=" args) (buffer-name)))
        (config-command (or (transient-arg-value "--command=" args) "python"))
        (config-file-path (or (transient-arg-value "--file-path=" args) (buffer-file-name)))
        (config-exec-path (or (transient-arg-value "--path=" args) (file-name-directory buffer-file-name)))
        (config-params (or (transient-arg-value "--params=" args) ""))
        (config-venv (or (transient-arg-value "--venv=" args) ""))
        (config-pyenv (or (transient-arg-value "--pyenv=" args) ""))
        (config-env-vars (or (pyconf--eval-env-vars (transient-arg-value "--env-vars=" args)) '())))
    (pyconf-add-configurations (list (pyconf-config :name config-name
                                                 :pyconf-exec-command config-command
                                                 :pyconf-file-to-exec config-file-path
                                                 :pyconf-path-to-exec config-exec-path
                                                 :pyconf-params config-params
                                                 :pyconf-venv config-venv
                                                 :pyconf-pyenv config-pyenv
                                                 :pyconf-env-vars config-env-vars)))))

(transient-define-suffix pyconf-transient-execute (&optional args)
  "Execute a non-persistent pyconf configuration given the necessary parameters."
  :key "x"
  :description "execute"
  :transient nil
  (interactive (list (transient-args transient-current-command)))
  (let ((config-name (or (transient-arg-value "--name=" args) (buffer-name)))
        (config-command (or (transient-arg-value "--command=" args) "python"))
        (config-file-path (or (transient-arg-value "--file-path=" args) (buffer-file-name)))
        (config-exec-path (or (transient-arg-value "--path=" args) (file-name-directory buffer-file-name)))
        (config-params (or (transient-arg-value "--params=" args) ""))
        (config-venv (or (transient-arg-value "--venv=" args) ""))
        (config-pyenv (or (transient-arg-value "--pyenv=" args) ""))
        (config-env-vars (or (pyconf--eval-env-vars (transient-arg-value "--env-vars=" args) ""))))
    (pyconf-execute-config (pyconf-config :name config-name
                                           :pyconf-exec-command config-command
                                           :pyconf-file-to-exec config-file-path
                                           :pyconf-path-to-exec config-exec-path
                                           :pyconf-params config-params
                                           :pyconf-venv config-venv
                                           :pyconf-pyenv config-pyenv
                                           :pyconf-env-vars (pyconf--split-vars-string config-env-vars)))))

(defun pyconf-prefix-init (obj)
  "Load dynamically default values and set OBJ value slot.
Refer to
https://stackoverflow.com/questions/28196228/emacs-how-to-get-directory-of-current-buffer"
  (oset obj value `(,(format "--name=%s" (buffer-name))
                    "--command=python"
                    ,(format "--file-path=%s" (buffer-file-name))
                    ,(format "--path=%s" (file-name-directory buffer-file-name)))))

(transient-define-prefix pyconf-menu ()
  "PyConf transient interface."
  :init-value 'pyconf-prefix-init
  ["Arguments"
   ("-n" "name" "--name=" :always-read t)
   ("-c" "command" "--command=" :always-read t)
   ("-f" "file path" "--file-path=" :always-read t)
   ("-p" "execution path" "--path=" :always-read t)
   ("-v" "virtualenv" "--venv=" :always-read t)
   ("--params" "parameters" "--params=" :always-read t)
   ("-e" "envvars" "--env-vars=" :always-read t)
   ("--pyenv" "pyenv-version" "--pyenv=" :always-read t)
   ]
  ["Actions"
   [(pyconf-transient-save)
    (pyconf-transient-execute)]])

(defun pyconf--is-empty-string (input-string)
  "Check return INPUT-STRING if it is not empty."
  (or (if (not (string= "" input-string))
          input-string
        nil)))

(defun pyconf--split-vars-string (vars-string)
  "Split a VARS-STRING containing environment variables comma separated into a list."
  (split-string vars-string ","))

(provide 'pyconf)

;;; pyconf.el ends here
