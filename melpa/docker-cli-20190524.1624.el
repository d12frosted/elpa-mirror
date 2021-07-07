;;; docker-cli.el --- Running various commands in docker containers

;; Author: Boško Ivanišević <bosko.ivanisevic@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20190524.1624
;; Package-Commit: c4b02894466d8642ad3d49df4c4a80e023a672aa
;; Keywords: processes
;; URL: https://github.com/bosko/docker-cli

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; docker-cli provides mode for running commands within Docker
;; containers in Emacs buffer.  Package comes with few predefined
;; commands for running PostgreSQL, Redis and MySQL clients.  Package
;; can easily be extended with new commands by adding elements to
;; `docker-cli-commands-alist'.  Command is ran with interactive
;; function `docker-cli-run-cmd` which, after selecting command and
;; container from the list, executes given command in the target
;; Docker container.

;;; Code:

(require 'comint)

(defcustom docker-cli-db-username ""
  "Database username."
  :type 'string
  :group 'docker-cli)

(defcustom docker-cli-db-name ""
  "Database name."
  :type 'string
  :group 'docker-cli)

(defcustom docker-cli-host ""
  "Host name."
  :type 'string
  :group 'docker-cli)

(defvar docker-cli-cmd "docker"
  "Docker command.")

(defvar docker-cli-exec-arguments '("exec" "-it")
  "Commandline arguments to pass to docker.")

(defvar docker-cli-curr-command nil
  "Current selected command.")

(defvar docker-cli-commands-alist
  '((sh
     :command "/bin/sh"
     :arguments-compose-func nil
     :prompt-regexp "^[[:alnum:]_]*=[#>] "
     :prompt-cont-regexp "^[[:alnum:]_]*=[#>] ")

    (bash
     :command "/bin/bash"
     :arguments-compose-func nil
     :prompt-regexp "^[[:alnum:]_]*=[#>] "
     :prompt-cont-regexp "^[[:alnum:]_]*=[#>] ")

    (psql
     :command "psql"
     :arguments-compose-func docker-cli-psql-arguments
     :prompt-regexp "^[[:alnum:]_]*=[#>] "
     :prompt-cont-regexp "^[[:alnum:]_]*=[#>] ")

    (mysql
     :command "mysql"
     :arguments-compose-func docker-cli-mysql-arguments
     :prompt-regexp "^[[:alnum:]_]*=[#>] "
     :prompt-cont-regexp "^[[:alnum:]_]*=[#>] ")

    (redis-cli
     :command "redis-cli"
     :exec-arguments-func docker-cli-redis-exec-arguments
     :arguments-compose-func nil
     :prompt-regexp "^[a-zA-Z0-9_.-]+:[0-9]+\\(\\[[0-9]\\]\\)?> "
     :prompt-cont-regexp "^[a-zA-Z0-9_.-]+:[0-9]+\\(\\[[0-9]\\]\\)?> "))
  "An alist of defined commands that can be ran in docker container.

Each element in the list must be of the following format:

  (COMMAND-KEY FEATURE VALUE)

where COMMAND-KEY is unique value that determines command and can
be displayed in selection when `docker-run' is executed.  Each key
is followed by FEATURE-VALUE pairs.  Feature can be any of following:

  :command                    Command that will be executed in the
                              Docker container.

  :exec-arguments-func        Function without arguments that should
                              return Docker exec arguments. Value
                              returned by this fuction will be used
                              instead of `docker-cli-exec-arguments'.

  :arguments-compose-func     Function without arguments that will be
                              called in order to fetch all command
                              arguments.

New commands can be supported by adding new element to this list.")

(defvar docker-cli-mode-map
  (let ((map (nconc (make-sparse-keymap) comint-mode-map)))
    ;; example definition
    (define-key map "\t" 'completion-at-point)
    map)
  "Basic mode map for `docker-cli'.")

;; This value is for psql. It should be nil here and
;; set depending of command started
(defvar docker-cli-prompt-regexp nil
  "Prompt for `docker-cli'.")

;; This value is for psql. It should be nil here and
;; set depending of command started
(defvar docker-cli-prompt-cont-regexp nil
  "Prompt pattern for continuation prompt.")

(defun docker-cli-psql-arguments ()
  "Composes arguments for running psql in docker container."
  (setq docker-cli-db-username (read-string "Username: " docker-cli-db-username))
  (setq docker-cli-db-name (read-string "Database: " docker-cli-db-name))
  (setq docker-cli-host (read-string "Host: " docker-cli-host))
  `("-U" ,docker-cli-db-username "-h" ,docker-cli-host "-P" "pager=off" ,docker-cli-db-name))

(defun docker-cli-mysql-arguments ()
  "Composes arguments for running MySQL client in Docker container."
  (setq docker-cli-db-username (read-string "Username: " docker-cli-db-username))
  (setq docker-cli-db-name (read-string "Database: " docker-cli-db-name))
  (setq docker-cli-host (read-string "Host: " docker-cli-host))
  `("-u" ,docker-cli-db-username "-h" ,docker-cli-host "-p" ,docker-cli-db-name))

(defun docker-cli-redis-exec-arguments ()
  "Composes arguments for running Redis client in docker container."
  '("exec" "-it" "-e" "TERM=dumb"))

(defun docker-cli-compose-params-for (command-name container)
  "Composes params for given command and CONTAINER.
Argument COMMAND-NAME unique key of command from docker-cli-command-alist.
Argument CONTAINER name of the target Docker container."
  (let* ((curr-command (cdr (assoc (intern command-name) docker-cli-commands-alist)))
         (params (if (plist-get curr-command :arguments-compose-func)
                     (apply (plist-get curr-command :arguments-compose-func) nil))))
    (setq docker-cli-prompt-regexp (or (plist-get curr-command :prompt-regexp) ""))
    (setq docker-cli-prompt-cont-regexp (or (plist-get curr-command :prompt-cont-regexp) ""))
    (setq params (cons (plist-get curr-command :command) (or params '())))
    (setq params (cons container params))
    (if (plist-get curr-command :exec-arguments-func)
        (setq params (append (apply (plist-get curr-command :exec-arguments-func) nil) params))
      (setq params (append docker-cli-exec-arguments params)))))

(defun docker-cli ()
  "Run an inferior instance of `docker' inside Emacs."
  (interactive)
  (let* ((curr-command-name (completing-read
                             "Command: "
                             (mapcar 'symbol-name (mapcar 'car docker-cli-commands-alist)) nil t))
         (container (completing-read
                     "Container: "
                     (split-string (shell-command-to-string "docker ps --format '{{.Names}}'")) nil t))
         (buffer-name)
         (buffer))

    (if (and (not (string= "" curr-command-name)) (not (string= "" container)))
        (progn
          (setq buffer-name (format "%s-%s" container curr-command-name))
          (setq buffer (get-buffer-create (format "*%s*" buffer-name)))
          (pop-to-buffer-same-window buffer)

          ;; create the comint process
          (unless (comint-check-proc buffer)
            (apply 'make-comint-in-buffer buffer-name buffer
                   docker-cli-cmd nil (docker-cli-compose-params-for curr-command-name container)))
          (docker-cli-mode)))))

(defun docker-cli--initialize ()
  "Helper function to initialize Docker."
  (setq comint-process-echoes t)
  (setq comint-use-prompt-regexp t))

(define-derived-mode docker-cli-mode comint-mode "Docker"
  "Major mode for running commands in Docker containers.

\\<docker-cli-mode-map>"
  ;; this sets up the prompt so it matches things like: [foo@bar]
  (setq comint-prompt-regexp
        (if docker-cli-prompt-cont-regexp
            (concat "\\(" docker-cli-prompt-regexp
                    "\\|" docker-cli-prompt-cont-regexp "\\)")
          docker-cli-prompt-regexp))
  ;; this makes it read only; a contentious subject as some prefer the
  ;; buffer to be overwritable.
  (setq comint-prompt-read-only t)
  ;; this makes it so commands like M-{ and M-} work.
  (set (make-local-variable 'paragraph-separate) "\\'")
  (set (make-local-variable 'paragraph-start) docker-cli-prompt-regexp))

;; this has to be done in a hook. grumble grumble.
(add-hook 'docker-cli-mode-hook 'docker-cli--initialize)

(provide 'docker-cli)

;;; docker-cli.el ends here
