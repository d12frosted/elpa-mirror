;;; ppcompile.el --- Ping-pong compile projects on remote machines -*- lexical-binding: t -*-

;; Author: Guangwang Huang <whatacold@gmail.com>
;; Maintainer: Guangwang Huang
;; URL: https://github.com/whatacold/ppcompile
;; Package-Version: 20220613.1410
;; Package-Commit: c6450517157dfb73572892785a0aafe440596d19
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))
;; Homepage: https://github.com/whatacold/ppcompile
;; Keywords: tools


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; This package tries to ease the workflow that consists of coding locally,
;; compiling remotely, and fixing errors with `next-error' and `previous-error' locally.
;; It depends on built-in packages: auth-source,
;; project , files-x and compile.
;; And it also depends on external programs: rsync, ssh, and expect.

;;; Code:

(require 'compile)
(require 'auth-source)
(require 'project)
(require 'files-x)

(defgroup ppcompile nil
  "Ping pong compile."
  :group 'tools)

(defcustom ppcompile-ssh-executable (if (eq system-type 'windows-nt)
                                        "ssh.exe"
                                      "ssh")
  "The ssh executable."
  :type 'string
  :group 'ppcompile)

(defcustom ppcompile-rsync-executable (if (eq system-type 'windows-nt)
                                          "rsync.exe"
                                        "rsync")
  "The rsync executable."
  :type 'string
  :group 'ppcompile)

(defcustom ppcompile-expect-executable (if (eq system-type 'windows-nt)
                                           "expect.exe"
                                         "expect")
  "The expect executable."
  :type 'string
  :group 'ppcompile)

(defcustom ppcompile-with-password-script-path
  (concat (file-name-directory (or load-file-name buffer-file-name))
          "with-password.exp")
  "The path of the helper expect script `with-password.exp'."
  :type 'string
  :group 'ppcompile)

(defcustom ppcompile-ssh-host nil
  "Host of the remote machine, where remote compilation runs."
  :type 'string
  :group 'ppcompile)

(defcustom ppcompile-ssh-port 22
  "SSH port of the remote machine."
  :type 'integer
  :group 'ppcompile)

(defcustom ppcompile-ssh-user (user-login-name)
  "SSH user to login for remote compilations."
  :type 'string
  :group 'ppcompile)

(defcustom ppcompile-ssh-additional-args ""
  "Additional arguments for `ssh'."
  :type 'string
  :group 'ppcompile)

(defcustom ppcompile-rsync-exclude-list '("*.o"
                                          ".git*"
                                          ".svn*")
  "Files that `rsync' should exclude.
See `--exclude' option of `rsync' for the syntax."
  :type '(repeat string)
  :group 'ppcompile)

(defcustom ppcompile-rsync-additional-args "-az"
  "Arguments for `rsync', in addition to `ppcompile-rsync-exclude-list'.
Do not contain spaces in the value."
  :type 'string
  :group 'ppcompile)

(defcustom ppcompile-rsync-dst-dir nil
  "The destination containing directory to `rsync' files into."
  :type 'string
  :group 'ppcompile)

(defcustom ppcompile-remote-compile-command "make -k -C ."
  "The default compile command executed on remote.

The command will be executed under the remote project directory.

You should specify the `-C' argument if it's `make', which makes `make'
print things like \"make: Entering directory '/tmp/hello-world-project'\",
so as to make ppcompile convert the remote paths correctly."
  :type 'string
  :group 'ppcompile)

(defcustom ppcompile-path-mapping-alist nil
  "A list of `cons' cells tells how to map remote paths to local paths.
Each cons cell's key is remote path, and value is local path, all paths
should be in absolute path."
  :type '(alist :key-type string :value-type string)
  :group 'ppcompile)

(defvar ppcompile--current-buffer nil
  "The current buffer before compiling.

Used to fetch its buffer-local variables.")

(defvar ppcompile--debug nil
  "If non-nil, log additional messages while using.")

(defvar ppcompile--config-history nil
  "History list of user configuration input.")

(defvar ppcompile--remote-command-history nil
  "History list of the user's remote commands.")

(defun ppcompile--expect-available-p ()
  "Predicate whether `expect' and the helper script are both available."
  (and (file-exists-p ppcompile-with-password-script-path)
       (file-executable-p (or (executable-find ppcompile-expect-executable)
                              ppcompile-expect-executable))))

(defun ppcompile--replace-path (buffer _finish-msg)
  "Replace paths in BUFFER, according to `ppcompile-path-mapping-alist'.
Argument _FINISH-MSG is a string describing how the process finished."
  (let ((path-mapping-list (with-current-buffer ppcompile--current-buffer
                             ppcompile-path-mapping-alist)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t)
            from to)
        (dolist (map path-mapping-list)
          ;; ensure both `from' & `to' ending with /
          (setq from (car map))
          (when (/= ?/ (aref from (1- (length from))))
            (setq from (concat from "/")))
          (setq to (cdr map))
          (when (/= ?/ (aref to (1- (length to))))
            (setq to (concat to "/")))
          (goto-char (point-min))
          (while (search-forward from nil t)
            (replace-match to)))))))

(defun ppcompile--project-root ()
  "Find the root directory of current project.

If `project-current' finds the root, return it;
or else fallback to use `git' root directory containing `.git'."
  (or (cdr (project-current))
      (locate-dominating-file default-directory (lambda (dir)
                                                  (file-directory-p (expand-file-name ".git" dir))))
      default-directory))

;;;###autoload
(defun ppcompile-ping ()
  "Rsync current project from local machine to remote one."
  (interactive)
  (let* ((default-directory (ppcompile--project-root))
         (project-path (expand-file-name default-directory))
         (expect-available-p (ppcompile--expect-available-p))
         (process-environment process-environment)
         (rsync-status 1)
         (ping-args (mapcar #'(lambda (pattern) (format "--exclude=%s" pattern))
                            ppcompile-rsync-exclude-list))
         ping-output)
    (push (format "--rsh=%s -p %d %s"
                  ppcompile-ssh-executable
                  ppcompile-ssh-port
                  ppcompile-ssh-additional-args)
          ping-args)
    (when ppcompile-rsync-additional-args
      (push ppcompile-rsync-additional-args ping-args))

    ;; a trailing slash makes a difference for rsync, trim it if any.
    (when (equal (substring project-path
                            (1- (length project-path))) "/" )
      (setq project-path (substring project-path 0 (1- (length project-path)))))
    (push project-path ping-args)

    (push (format "%s@%s:%s"
                  ppcompile-ssh-user
                  ppcompile-ssh-host
                  ppcompile-rsync-dst-dir)
          ping-args)
    (setq ping-args (nreverse ping-args))

    (when ppcompile--debug
      (if (not expect-available-p)
          (message "ppcompile ping command: %s %s"
                   ppcompile-rsync-executable
                   (mapconcat #'(lambda (arg) (format "'%s'" arg))
                              ping-args " "))
        (message "ppcompile ping command: %s %s %s %s"
                 ppcompile-expect-executable
                 ppcompile-with-password-script-path
                 ppcompile-rsync-executable
                 (mapconcat #'(lambda (arg) (format "'%s'" arg))
                            ping-args " "))
        (setq process-environment (cons (format "PPCOMPILE_PASSWORD=%s"
                                                (ppcompile-get-ssh-password))
                                        process-environment))))

    (save-some-buffers)
    (with-temp-buffer
      (setq rsync-status (if expect-available-p (apply #'call-process
                                                       ppcompile-expect-executable
                                                       nil
                                                       (current-buffer)
                                                       nil
                                                       ppcompile-with-password-script-path
                                                       ppcompile-rsync-executable
                                                       ping-args)
                           (apply #'call-process
                                  ppcompile-rsync-executable
                                  nil
                                  (current-buffer)
                                  nil
                                  ping-args)))
      (setq ping-output (buffer-substring-no-properties (point-min) (point-max))))
    (cons rsync-status ping-output)))

(defun ppcompile-pong (flip-pong-prompt-p)
  "Compile the project remotely.

And replace remote paths with local ones in the *compilation* buffer,
So that \\[next-error] and \\[previous-error] work correctly.

If FLIP-PONG-PROMPT-P is not nil, it flips the value of variable
`compilation-read-command' when executing this function."
  (interactive "P")
  (let* ((default-directory (ppcompile--project-root))
         (compilation-environment compilation-environment)
         (expect-available-p (ppcompile--expect-available-p))
         (compilation-read-command (if flip-pong-prompt-p
                                       (not compilation-read-command)
                                     compilation-read-command))
         (remote-compile-command ppcompile-remote-compile-command)
         (project-basename (file-name-nondirectory
                            (directory-file-name
                             (ppcompile--project-root))))
         (user-prompt-command-initial (if (> (length ppcompile--remote-command-history) 0)
                                          (car ppcompile--remote-command-history)
                                        ppcompile-remote-compile-command))
         pong-command)
    (setq ppcompile--current-buffer (current-buffer))
    (add-to-list 'compilation-finish-functions #'ppcompile--replace-path) ; XXX how to do this elegantly?

    (when compilation-read-command
      (setq remote-compile-command (read-from-minibuffer
                                    (format "[ppcompile] on remote dir \"%s/%s\": "
                                            ppcompile-rsync-dst-dir
                                            project-basename)
                                    user-prompt-command-initial
                                    nil
                                    nil
                                    'ppcompile--remote-command-history
                                    user-prompt-command-initial))
      (when (string-equal "" remote-compile-command)
        (setq remote-compile-command user-prompt-command-initial)))

    (if (not expect-available-p)
        (setq pong-command (format "%s -p %d %s %s@%s 'cd %s/%s && %s'"
                                   ppcompile-ssh-executable
                                   ppcompile-ssh-port
                                   ppcompile-ssh-additional-args
                                   ppcompile-ssh-user
                                   ppcompile-ssh-host
                                   ppcompile-rsync-dst-dir
                                   project-basename
                                   remote-compile-command))
      (setq compilation-environment (cons (format "PPCOMPILE_PASSWORD=%s"
                                                  (ppcompile-get-ssh-password))
                                          compilation-environment))
      (setq pong-command (format "%s %s %s -p %d %s %s@%s 'cd %s/%s && %s'"
                                 ppcompile-expect-executable
                                 ppcompile-with-password-script-path
                                 ppcompile-ssh-executable
                                 ppcompile-ssh-port
                                 ppcompile-ssh-additional-args
                                 ppcompile-ssh-user
                                 ppcompile-ssh-host
                                 ppcompile-rsync-dst-dir
                                 project-basename
                                 remote-compile-command)))

    (when ppcompile--debug
      (message "ppcompile pong command: %s" pong-command))
    (compilation-start pong-command)

    (with-current-buffer "*compilation*"
      (hack-dir-local-variables-non-file-buffer))))

;;;###autoload
(defun ppcompile (&optional flip-pong-prompt-p)
  "Ping-pong compile current project.

If FLIP-PONG-PROMPT-P is not nil, it flips the value of variable
`compilation-read-command' when executing this function."
  (interactive "P")
  (let* ((rsync-result (ppcompile-ping)))
    (if (not (eq 0 (car rsync-result)))
        (message "Failed to rsync current project, rsync output is: %s" (cdr rsync-result))
      (ppcompile-pong flip-pong-prompt-p))))

;;;###autoload
(defun ppcompile-toggle-debug ()
  "Toggle debugging."
  (interactive)
  (setq ppcompile--debug (not ppcompile--debug))
  (message "ppcompile debug %s" (if ppcompile--debug
                                    "on"
                                  "off")))

;;;###autoload
(defun ppcompile-get-ssh-password (&optional interactive-p)
  "Get SSH password using auth-source if `INTERACTIVE-P' is non nil.

nil returned if no password configured."
  (interactive "p")
  (let ((secret
         (plist-get
          (nth 0
               (auth-source-search :max 1
                                   :host ppcompile-ssh-host
                                   :user ppcompile-ssh-user
                                   ;; secrets.el wouldn’t accept a number
                                   :port (if (numberp ppcompile-ssh-port)
                                             (number-to-string ppcompile-ssh-port)
                                           ppcompile-ssh-port)
                                   :require '(:secret)))
          :secret)))
    (when (functionp secret)
      (setq secret (funcall secret)))
    (when (not (stringp secret))
      (setq secret ""))
    (when (and ppcompile--debug (= 0 (length secret)))
      (message "No ppcompile password for the current project!"))
    (if interactive-p
        (message "ppcompile password for the current project: '%s'" secret)
      secret)))

;;;###autoload
(defun ppcompile-config-project ()
  "Guide you to configure variables in `.dir-locals.el' in the project root."
  (interactive)
  (save-excursion
    (let ((default-directory (ppcompile--project-root))
          host port user dst-dir remote-compile-command modified-p)
      (setq host (read-from-minibuffer "[ppcompile] ssh host: "
                                       nil
                                       nil
                                       nil
                                       'ppcompile--config-history))
      (setq port (string-to-number (read-from-minibuffer "[ppcompile] ssh port: "
                                                         nil
                                                         nil
                                                         nil
                                                         'ppcompile--config-history
                                                         "22")))
      (setq user (read-from-minibuffer "[ppcompile] ssh user: "
                                       nil
                                       nil
                                       nil
                                       'ppcompile--config-history))
      (setq dst-dir (read-from-minibuffer "[ppcompile] remote containing directory to rsync it: "
                                          nil
                                          nil
                                          nil
                                          'ppcompile--config-history))
      (setq remote-compile-command (read-from-minibuffer "[ppcompile] compile command (`M-n' to get started): "
                                               nil
                                               nil
                                               nil
                                               'ppcompile--config-history
                                               ppcompile-remote-compile-command))
      (when (> (length host) 0)
        (setq modified-p t)
        (add-dir-local-variable nil 'ppcompile-ssh-host host))
      (when (> port 0)
        (setq modified-p t)
        (add-dir-local-variable nil 'ppcompile-ssh-port port))
      (when (> (length user) 0)
        (setq modified-p t)
        (add-dir-local-variable nil 'ppcompile-ssh-user user))
      (when (> (length dst-dir) 0)
        (setq modified-p t)
        (add-dir-local-variable nil 'ppcompile-rsync-dst-dir dst-dir)

        ;; FIXME The mapping in the .dir-locals.el file may have duplicates
        (push (cons dst-dir (expand-file-name (concat default-directory "/../")))
              ppcompile-path-mapping-alist)
        (add-dir-local-variable nil 'eval `(setq ppcompile-path-mapping-alist
                                                 ',ppcompile-path-mapping-alist)))
      (when (> (length remote-compile-command) 0)
        (setq modified-p t)
        (add-dir-local-variable nil 'ppcompile-remote-compile-command remote-compile-command))

      (when modified-p
        (when (y-or-n-p (format "Save %s.dir-locals.el? " default-directory))
          (save-buffer)
          (bury-buffer))))))

(provide 'ppcompile)

;;; ppcompile.el ends here
