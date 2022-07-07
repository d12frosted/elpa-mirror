;;; tfsmacs.el --- MS TFS source control interaction.  -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Sebastian Monia
;;
;; Author: Dino Chiesa <dpchiesa@outlook.com>, Sebastian Monia <smonia@outlook.com>
;; URL: http://github.com/sebasmonia/tfsmacs/
;; Package-Version: 20180911.2114
;; Package-Commit: 6865d7bf772a6ecabacc868e45a0f5a5e197e1a5
;; Package-Requires: ((emacs "25") (tablist "0.70"))
;; Version: 1.25
;; Keywords: tfs, vc

;; This file is not part of GNU Emacs.

;;; License: MIT

;;; Commentary:

;; Steps to setup:
;;   1. Obtain the Team Explorer Everywhere CLI tool from https://github.com/Microsoft/team-explorer-everywhere/releases
;;      (don't forget to run "tf eula" to accept the terms and conditions)
;;   2. Place tfsmacs.el in your load-path.  Or install from MELPA.
;;   3. In your .emacs file you can setup keybindings for the tfsmacs commands, there's a keymap:
;;        (require 'tfsmacs)
;;        (global-set-key  "\C-ct" 'tfsmacs-map)
;;      OR for individual commands:
;;        (global-set-key  "\C-ctp" 'tfsmacs-pendingchanges)
;;        (global-set-key  "\C-cto" 'tfsmacs-checkout)
;;        (global-set-key  "\C-cti" 'tfsmacs-checkin)
;;        ; etc.
;;   4. Customize the group tfsmacs to provide credentials and the location of the TEE tool
;;   5. Run tfsmacs-setup-workspace to configure collections and their workspaces in your computer
;;
;; For a detailed user manual see:
;; https://github.com/sebasmonia/tfsmacs/blob/master/README.md

;;; Code:

(require 'ido)
(require 'dom)
(require 'cl-lib)
(require 'tablist)

(defgroup tfsmacs nil
  "MS TFS source control interaction."
  :group 'extensions)

(defcustom tfsmacs-cmd  "C:/HomeFolder/TEE-CLC-14.134.0/tf.cmd"
  "Location of the 'Team Explorer Everywhere' command line tool."
  :type 'string)

(defcustom tfsmacs-login ""
  "Values for the -login option.  Ignored if empty."
  :type 'string)

(defcustom tfsmacs-current-workspace ""
  "Name of the current workspace.  If empty, the TEE CLI will assume the workspace from the existing folder mappings."
  :type 'string)

(defcustom tfsmacs-log-buffer-name "*TFS Log*"
  "Name of the TFS log buffer."
  :type 'string)

(defcustom tfsmacs-show-less-messages t
  "Display less messages when processing commands."
  :type 'boolean)

(defcustom tfsmacs-async-command-timer 0.5
  "How often to check, in seconds, that a command has finished completing its output."
  :type 'float)
;; with default values of 0.5 and 60 we will keep retrying for 30 seconds to complete
;; an async command and get its output
(defcustom tfsmacs-async-command-retries 60
  "How many times to check that output was completed before giving up on the command."
  :type 'integer)

(defcustom tfsmacs-workspaces-alist nil
  "A string-string alist of all your workspaces, for easy switching.  Used by `tfsmacs-switch-workspace`."
  :type 'alist)

(defvar tfsmacs--process-name "*TEECLI*")
(defvar tfsmacs--changeset-buffer-name "*TFS Changeset*")
(defvar tfsmacs--shelveset-buffer-name "*TFS Shelveset*")
(defvar tfsmacs--server-dirs-buffer-name "*TFS Directories*")
(defvar tfsmacs--server-dirs-diff-buffer-name "*TFS Directory Compare*")
(defvar tfsmacs--current-help-message "")
;; Keeps track of the current directory when navigating server files using "tf dir"
(defvar tfsmacs--server-current-dir "$/")
;; Local path for directory on which "tfsmacs--server-compare-dir " was invoked on
(defvar tfsmacs--server-compare-local-dir "")
;; Used to repeat the command when using "g" in the status buffer. Buffer local.
(defvar tfsmacs--buffer-status-dir nil)
;; Changeset ID in the changeset details window. Buffer local.
(defvar tfsmacs--changeset-id "")
;; Used to determine the current file/dir in the history buffer
(defvar tfsmacs--history-target "")
;; Accumulates the output of the tf process until the command is complete
(defvar tfsmacs--command-output-buffer "")
;; Used to count the number of retries parsing the output of a command
;; It is resetted every time new input arrives
;; and set to "-1" to signal the timeout elapsed
(defvar tfsmacs--command-retries 0)
;; Holds the setup info when running initial setup
(defvar tfsmacs--setup-info "")

(define-prefix-command 'tfsmacs-map)
(define-key tfsmacs-map "p" 'tfsmacs-pending-changes)
(define-key tfsmacs-map "o" 'tfsmacs-checkout)
(define-key tfsmacs-map "i" 'tfsmacs-checkin)
(define-key tfsmacs-map "r" 'tfsmacs-rename)
(define-key tfsmacs-map "g" 'tfsmacs-get)
(define-key tfsmacs-map "d" 'tfsmacs-get-recursive)
(define-key tfsmacs-map "h" 'tfsmacs-history)
(define-key tfsmacs-map "c" 'tfsmacs-changeset)
(define-key tfsmacs-map "u" 'tfsmacs-undo)
(define-key tfsmacs-map "-" 'tfsmacs-delete)
(define-key tfsmacs-map "+" 'tfsmacs-add)
(define-key tfsmacs-map "s" 'tfsmacs-shelvesets)
;; Commands not mapped:
;; tfsmacs-server-directories
;; tfsmacs-setup-workspace
;; tfsmacs-switch-workspace

(defun tfsmacs--append-to-log (text)
  "Append TEXT to the TFS Messages buffer.
Intended for internal use only."
  (let ((messages-buffer (get-buffer-create tfsmacs-log-buffer-name)))
    (with-current-buffer messages-buffer
      (goto-char (point-max))
      (insert text)
      (insert "\n"))))

(defun tfsmacs--show-help (help-message)
  "Display the *TFS Help* buffer with the text in HELP-MESSAGE."
  (with-output-to-temp-buffer "*TFS Help*"
    (princ help-message)))

(defun tfsmacs--optional-message (text)
  "Display TEXT as message depending on the value of `tfsmacs-show-less-messages`."
  (when (not tfsmacs-show-less-messages)
    (message text)))

(defun tfsmacs--get-or-create-process ()
  "Create or return the TEE process."
  (let ((buffer-name tfsmacs--process-name)
        (process (get-process tfsmacs--process-name))
        (new-process-message "Creating new process instance..."))
    (when (not process)
      (tfsmacs--append-to-log new-process-message)
      (tfsmacs--optional-message new-process-message)
      (setq process (start-process tfsmacs--process-name buffer-name
                                   tfsmacs-cmd "@"))
      (set-process-filter process 'tfsmacs--async-command-callback))
    process))

;; Handling of parameters with call-process and TEE was hell. I opted to duplicate
;; the approach used for async commands, but instead of using stdin, sync cases
;; use an "input file". This worked much better. Now there's a lot of common ground
;; between the two functions, will refactor later I guess?
(defun tfsmacs--sync-command-to-file (command output-filename &optional no-workspace)
  "Create a new TEE process, run COMMAND and write output to OUTPUT-FILENAME.
If NO-WORKSPACE is provided, said parameter won't be added."
  (let* ((workspace-param (tfsmacs--get-workspace-parameter))
         (login-param (tfsmacs--get-login-parameter))
         (input-script (concat temporary-file-directory "input.temp"))
         (command-string ""))
    (when no-workspace
      (setq workspace-param ""))
    (setq command-string (mapconcat 'identity (append command (list workspace-param login-param)) " "))
    (tfsmacs--append-to-log (format "COMMAND (sync): %s" command-string))
    (with-temp-file input-script
      (insert command-string))
    (with-temp-file output-filename
      (call-process tfsmacs-cmd nil t nil (format "@%s" input-script)))))

;; See https://github.com/Microsoft/team-explorer-everywhere/issues/272 for details on
;; the "no-workspace" commands.
;; As a consequence getting from server paths is not working as expected
(defun tfsmacs--async-command (command callback &optional no-workspace)
  "Run COMMAND in the TEE CLI process and call CALLBACK once it's done.
Output will be passed to the callback function as parameter.
If NO-WORKSPACE is provided, said parameter won't be added."
  (let* ((workspace-param (format " %s " (tfsmacs--get-workspace-parameter)))
         (login-param (format " %s " (tfsmacs--get-login-parameter)))
         (command-string ""))
    (if no-workspace
        (setq command (append command (list login-param)))
      (setq command (append command (list workspace-param login-param))))
    (setq command-string (mapconcat 'identity command " "))
    (setq command-string (concat command-string " -exitcode\n"))
    (tfsmacs--append-to-log (format "COMMAND (async): %s" command-string))
    (setq tfsmacs--command-output-buffer "")
    (setq tfsmacs--command-retries 1)
    (tfsmacs--optional-message "TFS: Running command...")
    (process-send-string (tfsmacs--get-or-create-process) command-string)
    (tfsmacs--async-command-schedule-check callback)))
  
(defun tfsmacs--async-command-callback (_process output)
  "Accumulate the OUTPUT of PROCESS."
  ;; the test below diffentiates a command being processed from
  ;; one where we timed out but might still be running
  (if (> tfsmacs--command-retries 0)
      (progn
        (setq tfsmacs--command-output-buffer (concat tfsmacs--command-output-buffer output))
        (setq tfsmacs--command-retries 1) ;; Reset the retries counter as long as output is received
        (tfsmacs--optional-message "TFS: Receiving command output..."))
    (progn
      (tfsmacs--append-to-log (format "Timedout command partial output:\n%s\n-------"
                                      output)))))

(defun tfsmacs--async-command-complete (callback)
  "Check if the last command finished by looking for an ExitCode.
If it did invoke CALLBACK, else re-schedule the function."
  (setq tfsmacs--command-retries (+ tfsmacs--command-retries 1))
  (cond ((string-match "ExitCode: 0\n" tfsmacs--command-output-buffer)
         (let ((output (replace-regexp-in-string "ExitCode: 0\n" "" tfsmacs--command-output-buffer)))
           (tfsmacs--optional-message "TFS: Processing command output...")
           (funcall callback output)))
        ((string-match "ExitCode: " tfsmacs--command-output-buffer) ;;  will match all exit codes BUT 0 (since it matches in prev. expression)
         (tfsmacs--async-command-handle-error)
         (funcall callback ""))
        (t
         (if (< tfsmacs--command-retries tfsmacs-async-command-retries)
             (tfsmacs--async-command-schedule-check callback)
           (progn
             (tfsmacs--async-command-handle-timeout)
             (funcall callback ""))))))

(defun tfsmacs--async-command-schedule-check (callback)
  "Schedule `tfsmacs--async-command-complete` with CALLBACK."
  (run-at-time tfsmacs-async-command-timer nil 'tfsmacs--async-command-complete callback))

(defun tfsmacs--async-command-handle-timeout ()
  "Reset the state after a command timed out."
  (message (format "TFS: Command timed out. Command output, if any, will be dumped in the  buffer %s."
                   tfsmacs-log-buffer-name))
  (tfsmacs--append-to-log (format "Timedout command partial output:\n%s\n-----------------------"
                                  tfsmacs--command-output-buffer))
  ;; prevent the "receiving output" message if we already timed out, and send subsequent output
  ;; to the TFS log rather than processing it.
  (setq tfsmacs--command-retries -1))

(defun tfsmacs--async-command-handle-error ()
  "Reset the state after a command failed."
  (tfsmacs--append-to-log (format "Failed command output:\n%s\n-----------------------"
                                  tfsmacs--command-output-buffer))
  ;; Just in case the command killed the process instance, this will start another one
  ;; or just return the existing one, which is inexpensive
  (tfsmacs--get-or-create-process))
    
(defun tfsmacs--get-workspace-parameter ()
  "Return the collection parameter if configured, or empty string."
  (if (not (string-empty-p tfsmacs-current-workspace))
      (format "-workspace:\"%s\"" tfsmacs-current-workspace)
    ""))

(defun tfsmacs--get-login-parameter ()
  "Return the login parameter if configured, or empty string."
  (if (not (string-empty-p tfsmacs-login))
      (format "-login:%s" tfsmacs-login)
    ""))

(defun tfsmacs--message-callback (output)
  "Show OUTPUT as message.  Also append to the TFS log."
  (tfsmacs--append-to-log output)
  (message (format "TFS:\n%s" output)))

(defun tfsmacs--log-callback (output)
  "Append OUTPUT to the TFS log."
  (when (> tfsmacs--command-retries 0) ;; if the command failed, don't run
    (tfsmacs--append-to-log output)))

(defun tfsmacs--short-message-callback (output)
  "Append OUTPUT to the TFS Log, and show a \"command completed\" message."
  (when (> tfsmacs--command-retries 0) ;; if the command failed, don't run
    (tfsmacs--append-to-log output)
    (message (format "TFS: Command completed. Check out the buffer %s details."
                     tfsmacs-log-buffer-name))))

(defun tfsmacs--determine-target-files (filename prompt)
  "Determine the name of the file to use in a TF command, or prompt for one.
If FILENAME, use it directly.  If called from a dired buffer it tries to
use the selection or the current file.  Else use PROMPT to get the user to
pick a file."
  (cond
   ((stringp filename)
    (list filename))
   ((derived-mode-p 'dired-mode)
    (dired-get-marked-files))
   (buffer-file-name
    (list buffer-file-name))
   (t
    (list (expand-file-name (read-file-name prompt nil nil t))))))

(defun tfsmacs--determine-target-directory (dirname  prompt)
  "Determine the name of a directory to use in a TF command, or prompt for one.
If DIRNAME, use it directly.  If called from a dired buffer it tries to
use the current directory.  Else use PROMPT to get the user to pick a dir."
  (cond
   ((stringp dirname)
    dirname)
   ((or (derived-mode-p 'dired-mode) (buffer-file-name))
    default-directory)
   (t
    (expand-file-name (read-directory-name prompt nil nil t)))))

(defun tfsmacs--get-last-dir-name (path)
  "Return only the last directory name in PATH.
From: https://stackoverflow.com/questions/27284851/emacs-lisp-get-directory-name-not-path-from-the-path"
  (file-name-nondirectory
   (directory-file-name
     (file-name-directory path))))

(defun tfsmacs--write-file-to-temp-directory (path version)
  "Write the VERSION of PATH to a temporary directory.
It spins off a new instance of the TEE tool by calling 'tfsmacs--sync-command-to-file'"
  (let* ((only-name (file-name-nondirectory path))
         (filename (concat temporary-file-directory version ";" only-name))
         (command (list "print" (format "-version:%s" version) (tfsmacs--quote-string path))))
    (tfsmacs--sync-command-to-file command filename)
    filename))

(defun tfsmacs--format-xml-date (date-string)
  "Convert DATE-STRING to a better representation."
  ;; Maybe it is worth it to do proper date formatting. TODO?
  (replace-regexp-in-string "T" " " (substring date-string  0 -9)))

(defun tfsmacs--trim-string (string)
  "Remove white spaces in beginning and ending of STRING.
From http://ergoemacs.org/emacs/modernization_elisp_lib_problem.html."
  (replace-regexp-in-string "\\`[ \t\n]*" "" (replace-regexp-in-string "[ \t\n]*\\'" "" string)))

(defun tfsmacs--quote-string (param)
  "Surround PARAM with quotes using format.  Useful for paths and comments."
  (format "\"%s\"" param))

(defun tfsmacs--quote-list (param-list)
  "Surround each item in PARAM-LIST with quotes using `tfsmacs--quote-string`."
  (mapcar 'tfsmacs--quote-string param-list))

(defun tfsmacs--single-item-list (lst)
  "Return non-nil if LST is a single item lst."
  ( list(equal (length lst) 1)))

(defun tfsmacs-switch-workspace ()
  "Change to configuration to use a different workspace.
The list of possible values is read from the alist `tfsmacs-workspaces`."
  (interactive)
  (let ((ws (ido-completing-read "Switch to workspace: "
                                 (mapcar 'car tfsmacs-workspaces-alist))))
    (customize-save-variable 'tfsmacs-current-workspace (alist-get ws tfsmacs-workspaces-alist))))

(defun tfsmacs-setup-workspace ()
  "Interactive, opinionated function to configure a collection.
Not bound by default, you would run this operation once per collection."
  (interactive)
  (let ((url (read-string "The URL of your collection, for example: \"http://contoso.com:8080/tfs/Collection\": "))
        (workspace-name (read-string "We need a name for your new workspace. It should be unique!: ")))
    (setq tfsmacs--setup-info `((collection  . ,url)
                               (workspace . ,workspace-name)))
    (when (y-or-n-p "Now it's time to setup the workspace.  Ready? ")
      (tfsmacs--async-command (list "workspace"
                                            "-new"
                                            (format "-collection:\"%s\"" url)
                                            (tfsmacs--quote-string workspace-name))
                              'tfsmacs--workspace-callback
                              t))))

(defun tfsmacs--workspace-callback (output)
  "Process the OUTPUT of creating a new workspace and setups  mappings."
  (let ((local-dir "")
        (workspace-name (alist-get 'workspace tfsmacs--setup-info)))
    (when (not (string-match-p "' created." output))
      (progn
        (tfsmacs--append-to-log (format "----WORKSPACE ERROR:\n%s\n-----------" output))
        (error "Workspace creation failed.  See log for details")))
    (when (y-or-n-p (format "Set tfsmacs-current-workspace with \"%s\"? "
                            workspace-name))
      (customize-save-variable 'tfsmacs-current-workspace workspace-name))
    (setq local-dir (expand-file-name (read-directory-name "Directory to map $/ (TFS root) in your computer: "
                                                           nil nil t)))
    (tfsmacs--async-command (list "workfold"
                                          "-map"
                                          "$/"
                                          (tfsmacs--quote-string local-dir)
                                          (format "-workspace:\"%s\"" workspace-name))
                            'tfsmacs--mapping-callback
                            t)))

(defun tfsmacs--mapping-callback (_output)
  "Process OUTPUT of setting the $/ mapping."
  ;; For some mystical reason the workfold command has ZERO output.
  ;; On error we have the retries "flagged" with -1
  (when (equal tfsmacs--command-retries -1)
    (error "Mapping setup failed.  See log for details"))
  (message "TFS: Setup completed. If you plan to switch between different workspaces, you should customize `tfsmacs-workspaces-alist`."))

(defun tfsmacs-checkout (&optional filename)
  "Perform a tf checkout (edit).

The file to checkout is deteremined this way:

 - if FILENAME is specified, then this function selects that file
   to checkout.

 - When this function is called from a buffer that is in
   `dired-mode', it selects the files marked, or the file on the
   current line in none marked.

 - when there is a file backing the current buffer, it selects
   the file being visited by the current buffer.

 - else, prompt the user for the file to checkout.

Checkout will occur only if the file is non-writable before the
call; checkout will fail if the specified file is currently
writable."
  (interactive)
  (let* ((files-to-checkout (tfsmacs--determine-target-files filename "File to checkout: "))
         (command (append '("checkout") files-to-checkout)))
    (when files-to-checkout
      (message "TFS: Checking out file(s)...")
      (tfsmacs--async-command command 'tfsmacs--message-callback))))

(defun tfsmacs-checkin ()
  "Perform a tf checkin on the file being visited by the current buffer.
Checkin happens only if the file is writable now.  This
function allows you to specify a checkin comment.  It checks in
only the current file being visited - pending changes for any
other files will not be checked in."
  (interactive)
  (if buffer-file-name
      (let* ((command (append '("checkin")
                              (tfsmacs--checkin-parameters-builder)
                              (list (tfsmacs--quote-string buffer-file-name)))))
        (tfsmacs--async-command command 'tfsmacs--message-callback))
    (error "Error tfsmacs-checkin: No file")))

(defun tfsmacs--checkin-parameters-builder ()
  "Build the parameters for the checkin command: comment, work item ID, overrie."
  (let* ((comment (read-string "Check in comment: "))
        (wid (read-string "Workitem ID (empty to skip): "))
        (override  (read-string "Override reason (empty to skip): "))
        (params (list (format "-comment:%s" (tfsmacs--quote-string comment)))))
    (when (not (string-empty-p wid))
      (push (format "-associate:%s" wid) params))
    (when (not (string-empty-p override))
      (push (format "-override:%s" (tfsmacs--quote-string override)) params))
    params))

(defun tfsmacs-rename (&optional filename new-name)
  "Perform a tf rename on a file.

The file to rename is deteremined this way:

 - if FILENAME is specified, then this function selects that file.

 - When this function is called from a buffer that is in
   `dired-mode', it selects the files marked, or the file on the
   current line in none marked.  Only one file can be marked.

 - when there is a file backing the current buffer, it selects
   the file being visited by the current buffer.

 - else, prompt the user for the file.

The file is renamed to NEW-NAME, a string, which should be the
name of a non-existent file in the current directory, specified
without a qualifying path.

If the rename is successful, and if the buffer is visiting the
file that is being renamed, then this function also renames the
buffer to the new name."
  (interactive)
  (let ((file-to-rename (tfsmacs--determine-target-files filename "File to rename: ")))
    (if (equal (length file-to-rename) 1)
        (let* ((source (car file-to-rename))
               (newname (or new-name (read-string (format "New name for %s: " source) nil nil nil)))
               (command (list "rename" source newname)))
          (tfsmacs--async-command command 'tfsmacs--message-callback)
          (if (string= source buffer-file-name)
              (set-visited-file-name newname)
            (error "Rename of %s was unsuccessful" file-to-rename)))
      (error "Couldn't determine file to rename"))))

(defun tfsmacs-add (&optional filename)
  "Perform a tf add on a file.

The file to add is determined this way:

 - if FILENAME is specified, then this function selects that file
   to add.

 - When this function is called from a buffer that is in
   `dired-mode', it selects the files marked, or the file on the
   current line in none marked.

 - when there is a file backing the current buffer, it selects
   the file being visited by the current buffer.

 - else, prompt the user for the file to add."
  (interactive)
  (let ((files-to-add (tfsmacs--determine-target-files filename "File(s) to add: ")))
    (if files-to-add
        (let* ((items (tfsmacs--quote-list files-to-add))
               (command (append '("add") items)))
          (tfsmacs--async-command command 'tfsmacs--message-callback))
      (error "Error tfsmacs-add: No file"))))

(defun tfsmacs-delete (&optional filename)
  "Perform a tf delete on a file.

The file to delete is determined this way:

 - if FILENAME is specified, then this function selects that file.

 - When this function is called from a buffer that is in
   `dired-mode', it selects the files marked, or the file on the
   current line in none marked.

 - when there is a file backing the current buffer, it selects
   the file being visited by the current buffer.

 - else, prompt the user for the file.

If the delete is successful, and if the buffer is visiting the file that
is being deleted, then this function also kills the buffer."
  (interactive)
  (let ((files-to-delete (tfsmacs--determine-target-files filename "File to delete: ")))
    (if files-to-delete
        (let* ((items (tfsmacs--quote-list files-to-delete))
               (command (append '("delete") items)))
          (tfsmacs--async-command command 'tfsmacs--message-callback))
      (error "Error tfsmacs-delete: No file"))))

(defun tfsmacs-server-directories (&optional path files)
  "Navigate the server tree and download directories.
This should be useful for first time downloads of files, after
running `tfsmacs-setup-workspace`.
PATH and FILES are used only for internal calls."
  (interactive)
  (when (not path)
    (setq path "$/"))
  (let ((command (list "dir" (tfsmacs--quote-string path))))
    (when (not files)
      (setq command (append command '("-folders"))))
    (tfsmacs--async-command command 'tfsmacs--server-callback)))

(defun tfsmacs--server-callback (output)
  "Allow a selection from the list of server folders in OUTPUT."
  (when (> tfsmacs--command-retries 0) ;; if the command failed, don't run
    ;; the block below "fixes" the output when there are not subdirs/files to list
    ;; so that the same processing applies to both cases
    (when (string-prefix-p "No items found under " output)
      (setq output (replace-regexp-in-string "\n" "" output)) ;; only first line has content
      (setq output (format "%s:\n[No items found under in this dir. Try displaying files.]\n\n"
                           (cadr (split-string output "No items found under ")))))
    (get-buffer-create tfsmacs--server-dirs-buffer-name)
    (let ((lines (butlast (split-string output "\n") 2)))
      (setq tfsmacs--server-current-dir (substring (car lines) 0 -1))
      (setf (nth 0 lines) (format "Folders under %s\n" (car lines)))
      (with-current-buffer tfsmacs--server-dirs-buffer-name
        (setq buffer-read-only nil)
        (kill-region (point-min) (point-max))
        (insert (mapconcat 'identity lines "\n"))
        (goto-char (point-min))
        (forward-line 2) ; we are guaranteed to have at least that many lines
        (setq buffer-read-only t)
        (local-set-key "G" 'tfsmacs--server-get-directory)
        (local-set-key "F" 'tfsmacs--server-show-files)
        (local-set-key "D" 'tfsmacs--server-compare-dirs)
        (local-set-key "^" 'tfsmacs--server-go-up)
        (local-set-key (kbd "RET") 'tfsmacs--server-go-down)
        (local-set-key "p" 'previous-line)
        (local-set-key "n" 'next-line)
        (local-set-key "h" 'tfsmacs--server-directories-help)
        (switch-to-buffer tfsmacs--server-dirs-buffer-name)))
    (message "TFS: Done. Press \"h\" to show available bindings.")))

(defun tfsmacs--server-directories-help ()
  "Show help for the directories buffer."
  (interactive)
  (let ((help-message
        (concat
         "--TFS Server Directories help--\n\n"
         "You can use ^ and RET to navigate the folders just like in dired. Similarly n and p move between lines.\n\n"
         "G will get the folder under point and its contents recursively. If needed it will create a local"
         " directory tree to match the one on the server (based on the mappings for the workspace).\n\n"
         "F will display the files in the current folder. Use it wisely as it can be quite slow!\n\n"
         "D shows the difference between the local and server folder. Its useful to figure out if you "
         "missed adding files, or deleted something from your local and it's not synced any more.")))
    (tfsmacs--show-help help-message)))

(defun tfsmacs--server-show-files ()
  "Show files in the current directory.
Showing files all the time could get quite slow.  Hence this command."
  (interactive)
  (tfsmacs-server-directories tfsmacs--server-current-dir t))

(defun tfsmacs--server-go-down ()
  "Go down the server directory tree."
  (interactive)
  (let ((line (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
    (when (string-suffix-p "/" tfsmacs--server-current-dir)
      (setq tfsmacs--server-current-dir (substring tfsmacs--server-current-dir 0 -1))) ; remove trailing / if needed
    (tfsmacs-server-directories (concat tfsmacs--server-current-dir "/" (substring line 1)))))

(defun tfsmacs--server-go-up ()
  "Go up the server directory tree."
  (interactive)
  (let* ((parts (split-string tfsmacs--server-current-dir "/"))
         (target (mapconcat 'identity (butlast parts 1) "/")))
    (when (string= target "$")
      (setq target "$/"))
    (tfsmacs-server-directories target)))

(defun tfsmacs--server-get-directory ()
  "Recursive get the directory under point."
  (interactive)
  (let* ((line (buffer-substring-no-properties (line-beginning-position) (line-end-position)))
         (directory (concat tfsmacs--server-current-dir "/" (substring line 1))))
    (when (y-or-n-p (format "Run GET on \"%s\" and its subdirectories? " directory))
      (tfsmacs--async-command (list "resolvePath" (tfsmacs--quote-string directory)) 'tfsmacs--server-get-directory-callback))))

(defun tfsmacs--server-get-directory-callback (output)
  "Start the recursive get on the folder listed in OUTPUT, after creating it."
  (when (> tfsmacs--command-retries 0)
    (setq output (file-name-as-directory (substring output 0 -2))) ;; remove trailing new lines
    (make-directory output t)
    (tfsmacs-get-recursive output t)))

(defun tfsmacs--server-compare-dirs ()
  "Show the file differences between local and server directory."
  (interactive)
  (let ((command (list "resolvePath" (tfsmacs--quote-string tfsmacs--server-current-dir))))
    (tfsmacs--async-command command 'tfsmacs--server-compare-dirs-local-path)))

(defun tfsmacs--server-compare-dirs-local-path (output)
  "Obtain from OUTPUT the local path for dir compare, and list server contents."
  (setq tfsmacs--server-compare-local-dir (car (split-string output "\n")))
  (tfsmacs--async-command (list "dir" (tfsmacs--quote-string tfsmacs--server-current-dir)) 'tfsmacs--server-compare-dirs-results))

(defun tfsmacs--server-compare-dirs-results (output)
  "Process contents in OUTPUT and compare with local directory."
  (let* ((server-contents (tfsmacs--server-compare-dirs-clean-output output))
         (local-contents (directory-files tfsmacs--server-compare-local-dir))
         (only-local (cl-remove-if (lambda (x): (member x server-contents)) local-contents))
         (only-server (cl-remove-if (lambda (x): (member x local-contents)) server-contents)))
    (when (not only-server)
      (setq only-server '("--None--")))
    (when (not only-local)
      (setq only-local '("--None--")))
    (get-buffer-create tfsmacs--server-dirs-diff-buffer-name)
    (with-current-buffer tfsmacs--server-dirs-diff-buffer-name
      (setq buffer-read-only nil)
      (kill-region (point-min) (point-max))
      (insert "Server only elements:\n")
      (insert (mapconcat 'identity only-server "\n"))
      (insert "\n\nLocal only elements:\n")
      (insert (mapconcat 'identity only-local "\n"))
      (setq buffer-read-only t)
      (switch-to-buffer-other-window tfsmacs--server-dirs-diff-buffer-name))
    (message "TFS: Displaying directory compare result.")))

(defun tfsmacs--server-compare-dirs-clean-output (server-contents)
  "Process SERVER-CONTENTS to extract only the files and dirs."
  (let* ((cleaned (cl-remove-if (lambda (x): (or (string-empty-p x) (string-suffix-p "item(s)." x)))
                                (cdr (split-string server-contents "\n"))))
         (no-$-prefix (mapcar 'tfsmacs--server-compare-dirs-remove$ cleaned)))
    (append '("." "..") no-$-prefix)))

(defun tfsmacs--server-compare-dirs-remove$ (a-string)
  "Remove prefix $ from A-STRING if present, else return it unmodified."
  (if (string-prefix-p "$" a-string)
      (substring a-string 1)
    a-string))

(defun tfsmacs-get (&optional filename version)
  "Perform a tf get on a file.

The file to get is determined this way:

 - if FILENAME is specified, then this function selects that file.

 - When this function is called from a buffer that is in
   `dired-mode', it selects the files marked, or the file on the
   current line in none marked.

 - when there is a file backing the current buffer, it selects
   the file being visited by the current buffer.

 - else, prompt the user for the file.

If VERSION to get is not provided, it will be prompted."
  (interactive)
  (let ((files-to-get (tfsmacs--determine-target-files filename "File(s) to get: ")))
    (when files-to-get
        (let* ((items (tfsmacs--quote-list files-to-get))
               (version (list (tfsmacs--get-version-param version)))
               (command (append '("get") items version)))
          (tfsmacs--async-command command 'tfsmacs--short-message-callback t)))))

(defun tfsmacs--get-version-param (&optional version)
  "Get a version spec string for a command that supports it.
If VERSION is provided return said version as changeset."
  (let ((param " -version:%s "))
    (when (not version)
      (setq version (read-string "Version spec (blank for latest): ")))
    (when (string-empty-p version)
      (setq version "T"))
    (format param version)))

(defun tfsmacs-get-recursive (&optional dirname force)
  "Perform a recursive tf get on a directory.
Use FORCE (or prefix arg) to overwrite writeable files not checked out
and get even up-to-date files.

The directory to get is determined this way:

 - if DIRNAME is specified, then this function selects that file.

 - When this function is called from a buffer that is in
   `dired-mode', it selects the current directory.

 - when there is a file backing the current buffer, it selects
   the file's directory

 - else, prompt the user for a dir."
  (interactive)
  (when current-prefix-arg
    (setq force t))
  (let* ((dir-to-get (tfsmacs--determine-target-directory dirname "Directory to get: "))
         (command (list "get" "-recursive" (tfsmacs--quote-string dir-to-get))))
    (when force
      (setq command (append command '("-force"))))
    (message (format "TFS: Recursively getting directory %s" dir-to-get))
    (when dir-to-get
      (tfsmacs--async-command command 'tfsmacs--short-message-callback t))))


(defun tfsmacs-undo (&optional filename)
  "Perform a tf undo on a file.

The file to undo is determined this way:

 - if FILENAME is specified, then this function selects that file.

 - When this function is called from a buffer that is in
   `dired-mode', it selects the files marked, or the file on the
   current line in none marked.

 - when there is a file backing the current buffer, it selects
   the file being visited by the current buffer.

 - else, prompt the user for the file."
  (interactive)
  (let ((files-to-undo (tfsmacs--determine-target-files filename "File(s) to undo: ")))
    (when files-to-undo
        (let* ((items (tfsmacs--quote-list files-to-undo))
                (command (append '("undo") items)))
             (when (yes-or-no-p "Undo changes to file(s)? ")
               (tfsmacs--async-command command 'tfsmacs--message-callback))))))

(define-derived-mode tfsmacs-history-mode tabulated-list-mode "TFS history Mode" "Major mode TFS History, displays an item's history and allows compares."
  (setq tabulated-list-format [("Changeset" 10 t)
                               ("Type" 8. t)
                               ("Date" 20 t)
                               ("Committed by" 30 t)
                               ("Comment" 0 t)])
  (setq tabulated-list-padding 1)
  (setq tabulated-list-sort-key (cons "Date" t))
  (tabulated-list-init-header)
  (tablist-minor-mode))

(define-key tfsmacs-history-mode-map (kbd "T") 'tfsmacs--history-mode-get-this-version)
(define-key tfsmacs-history-mode-map (kbd "C") 'tfsmacs--history-mode-changeset-details)
(define-key tfsmacs-history-mode-map (kbd "D") 'tfsmacs--history-mode-difference)
(define-key tfsmacs-history-mode-map (kbd "h") 'tfsmacs--history-mode-help)

(defun tfsmacs--history-mode-help ()
  "Show help for the history mode."
  (interactive)
  (let ((help-message
        (concat
         "--TFS History mode help--\n\n"
         "This mode is derived from tabulated-list, so the usual bindings for marking elements work "
         "as expected (m and u to mark and unmark, for example).\n\n"
         "T will get the version under point (or marked, if only one file is marked).\n\n"
         "C shows the changeset details in a separate window.\n\n"
         "D runs ediff between two files marked in the list. The get for each file runs synchronous, "
         "Emacs will be unresponsive until the operations are completed.")))
    (tfsmacs--show-help help-message)))

(defun tfsmacs--history-mode-quote-path (item-pair)
  "Return the same ITEM-PAIR with only the path quoted."
  (list
   (car item-pair)
   (tfsmacs--quote-string (cadr item-pair))))

(defun tfsmacs--history-mode-get-marked-items ()
  "Return the selected items in ‘tfsmacs-history-mode’.
The function returns (changesed-id server-path) for each element."
  (mapcar 'car (tablist-get-marked-items)))

(defun tfsmacs--history-mode-get-this-version ()
  "Get the file version marked/selected in the ‘tfsmacs-history-mode’ buffer."
  (interactive)
  (let* ((items (tfsmacs--history-mode-get-marked-items))
         (to-get (car items)))
    (if (tfsmacs--single-item-list items)
        (progn
          (message (format "TFS: Getting changeset %s" (car to-get)))
          (tfsmacs-get (cadr to-get) (car to-get)))
      (error "Only one item should be selected for this operation"))))

(defun tfsmacs--history-mode-changeset-details ()
  "Open changeset details for the selected item in ‘tfsmacs-history-mode’."
  (interactive)
  (let* ((items (tfsmacs--history-mode-get-marked-items))
         (to-get (car items)))
    (if (tfsmacs--single-item-list items)
        (progn
          (message (format "TFS: Getting changeset details %s" (car to-get)))
          (tfsmacs-changeset (car to-get)))
      (error "Only one item should be selected for this operation"))))

(defun tfsmacs--history-mode-difference ()
  "Compare two selected items in ‘tfsmacs-history-mode’."
  (interactive)
  (let* ((items (tfsmacs--history-mode-get-marked-items))
         (first-item (car items))
         (second-item (cadr items)))
    (if (equal (length items) 2)
        (progn
          (tfsmacs--history-mode-ediff first-item second-item))
      (error "Only two items should be selected for this operation"))))

(defun tfsmacs--history-mode-ediff (file1 file2)
  "Compares FILE1 and FILE2 using ediff."
  (message "TFS: Retrieving files to compare. This operation can take a few seconds.")
  (let* ((temp1 (tfsmacs--write-file-to-temp-directory (cadr file1) (car file1)))
         (temp2 (tfsmacs--write-file-to-temp-directory (cadr file2) (car file2))))
    (ediff-files temp1 temp2)))

(defun tfsmacs-history (&optional filename)
  "Perform a tf history on a file.
How the file is determined:

 - if FILENAME is specified, then this function selects that file.

 - When this function is called from a buffer that is in
   `dired-mode', it selects the files marked, or the file on the
   current line in none marked.  Only one file can be marked.

 - when there is a file backing the current buffer, it selects
   the file being visited by the current buffer.

 - else, prompt the user for the file"
  (interactive)
  (let ((files-for-history (tfsmacs--determine-target-files filename "File: ")))
    (if (equal (length files-for-history) 1)
        (let* ((source (car files-for-history))
               (command (list "history" (tfsmacs--quote-string source) )))
          (setq command (append command (tfsmacs--history-parameters-builder)))
          (message (format "TFS: Getting history for \"%s\"..." source))
          (setq tfsmacs--history-target source)
          (tfsmacs--async-command command 'tfsmacs--history-callback))
      (error "Couldn't determine history target"))))

(defun tfsmacs--history-parameters-builder ()
  "Build the parameters for the history command: stopafter and user."
  (let ((user (read-string "Filter by user (blank to ignore): "))
        (stopafter (string-to-number (read-string "Number of items to retrieve (blank for 50): ")))
        (params (list "-recursive" "-format:xml")))
    (when (equal stopafter 0)
      (setq stopafter 50))
    (push (format " -stopafter:%d " stopafter) params)
    (when (not (string-empty-p user))
      (push (format " -user:%s " user) params))
     params))

(defun tfsmacs--history-callback (output)
  "Process the history output and display the ‘tfsmacs-history-mode’ buffer.
OUTPUT is the XML output from \"tf history\"."
  (when (> tfsmacs--command-retries 0) ;; if the command failed, don't run
    (let ((parsed-data (tfsmacs--get-history-data-for-tablist output)))
      (let* ((short-target (file-name-nondirectory tfsmacs--history-target))
             (history-bufname (format "*TFS History %s *" short-target))
             (buffer (get-buffer-create history-bufname)))
        (with-current-buffer buffer
          (setq tabulated-list-entries parsed-data)
          (tfsmacs-history-mode)
          (tablist-revert)
          (switch-to-buffer buffer))))
    (message "TFS: Showing item history. Press \"h\" to show available bindings.")))
  
(defun tfsmacs--get-history-data-for-tablist (xml-status-data)
  "Format XML-STATUS-DATA from the history command for tabulated list."
  (with-temp-buffer
    (insert xml-status-data)
    (let* ((converted-xml-data (libxml-parse-xml-region (point-min) (point-max)))
           (changeset-nodes (dom-by-tag converted-xml-data 'changeset)))
      (mapcar 'tfsmacs--format-history-node changeset-nodes))))

(defun tfsmacs--format-history-node (changeset-node)
  "Extract from CHANGESET-NODE the info."
  (let ((changeset (cadr changeset-node))
        (comment (car (dom-by-tag changeset-node 'comment)))
        (item (cadr (car (dom-by-tag changeset-node 'item)))))
    (setq comment (nth 2 comment))
    (when (not comment)
      (setq comment ""))
    (list
     (list (alist-get 'id changeset) (alist-get 'server-item item))
     (vector
      (alist-get 'id changeset)
      (alist-get 'change-type item)
      (tfsmacs--format-xml-date (alist-get 'date changeset))
      (alist-get 'committer changeset)
      comment))))

(defun tfsmacs--changeset-callback (output)
  "Show the buffer with the changeset command result.
OUTPUT is the command's output"
  (when (> tfsmacs--command-retries 0) ;; if the command failed, don't run
    (with-current-buffer tfsmacs--changeset-buffer-name
      (insert output)
      (read-only-mode)
      (local-set-key "U" 'tfsmacs--changeset-update)
      (switch-to-buffer-other-window tfsmacs--changeset-buffer-name t))
    (message "TFS: Displaying changeset details. Use \"U\" to update the comment.")))

(defun tfsmacs--changeset-update ()
  "Update the changeset comments in the current buffer."
  (interactive)
  (let* ((comment (read-string "Updated check in comment: "))
         (params (list "changeset" tfsmacs--changeset-id (format "-comment:%s" (tfsmacs--quote-string comment)))))
    (with-current-buffer tfsmacs--changeset-buffer-name
      (tfsmacs--async-command params 'tfsmacs--message-callback))))

(defun tfsmacs-changeset (&optional version)
  "Gets info on a changeset.
If VERSION to get is not provided, it will be prompted."
  (interactive)
  (when (not version)
    (setq version (read-string "Changeset number: (blank for latest): ")))
  (when (string-empty-p version)
      (setq version "-latest"))
  (when (get-buffer tfsmacs--changeset-buffer-name)
    (kill-buffer tfsmacs--changeset-buffer-name))
  (with-current-buffer (get-buffer-create tfsmacs--changeset-buffer-name)
    (set (make-local-variable 'tfsmacs--changeset-id) version))
  (message (format "TFS: Getting changeset %s details."
                   version))
  (tfsmacs--async-command (list "changeset" version) 'tfsmacs--changeset-callback))

(define-derived-mode tfsmacs-status-mode tabulated-list-mode "TFS Status Mode" "Major mode TFS Status, displays current pending changes"
  (setq tabulated-list-format [("Change" 7 t)
                               ("Local Path" 100 t)
                               ("Server Path" 0 t)])
  (set (make-local-variable 'tfsmacs--buffer-status-dir) nil)
  (setq tabulated-list-padding 1)
  (setq tabulated-list-sort-key (cons "Local Path" nil))
  (tabulated-list-init-header)
  (tablist-minor-mode))

(defun tfsmacs--status-mode-checkin ()
  "Process files marked in ‘tfsmacs-status-mode’ for check in."
  (interactive)
  (let* ((items (tfsmacs--status-mode-get-marked-items))
         (quoted-items (tfsmacs--quote-list items))
         (command (append '("checkin") (tfsmacs--checkin-parameters-builder) quoted-items)))
    (tfsmacs--async-command command 'tfsmacs--message-callback)))

(defun tfsmacs--status-mode-revert ()
  "Revert (undo) the files marked using ‘tfsmacs-status-mode’."
  (interactive)
  (let* ((items (tfsmacs--status-mode-get-marked-items))
         (quoted-items (tfsmacs--quote-list items))
         (command '("undo")))
    (when (yes-or-no-p "Undo changes to the  files marked? ")
      (setq command (append command quoted-items))
      (tfsmacs--async-command command 'tfsmacs--message-callback))))

(defun tfsmacs--status-mode-difference ()
  "Compares pending change to latest version."
  (interactive)
  (let ((items (tfsmacs--status-mode-get-marked-items)))
    (if (tfsmacs--single-item-list items)
        (progn
          (message "TFS: Retrieving files to compare. This operation can take a few seconds.")
          (let* ((local (car items))
                 (server (tfsmacs--write-file-to-temp-directory local "T")))
            (ediff-files local server)))
      (error "Select only one file to compare to latest version"))))

(defun tfsmacs--status-mode-shelve ()
  "Shelve files marked in the tfs-status-mode buffer."
  (interactive)
  (let* ((items (tfsmacs--status-mode-get-marked-items))
         (quoted-items (tfsmacs--quote-list items))
         (name (read-string "Shelveset name (must be unique): "))
         (comment (read-string "Comments: "))
         (command nil))
    (when (y-or-n-p (format "Shelve %d items? " (length items)))
      (setq command (append (list "shelve"
                                  (tfsmacs--quote-string name)
                                  (format "-comment:\"%s\"" comment ))
                            quoted-items))
      (when (y-or-n-p "Undo local changes after shelving? ")
        (push "-move" command))
      (tfsmacs--async-command command 'tfsmacs--message-callback)
  )))

(defun tfsmacs--status-mode-get-marked-items ()
  "Obtain only the path of the files selected in the list."
  (mapcar 'car (tablist-get-marked-items)))

(defun tfsmacs--status-mode-visit-item ()
  "Visit the file under the cursor in ‘tfsmacs-status-mode’."
  (interactive)
  (find-file (tabulated-list-get-id)))

(define-key tfsmacs-status-mode-map (kbd "C") 'tfsmacs--status-mode-checkin)
(define-key tfsmacs-status-mode-map  (kbd "R") 'tfsmacs--status-mode-revert)
(define-key tfsmacs-status-mode-map (kbd "g") 'tfsmacs-pending-changes)
(define-key tfsmacs-status-mode-map (kbd "RET") 'tfsmacs--status-mode-visit-item)
(define-key tfsmacs-status-mode-map  (kbd "D") 'tfsmacs--status-mode-difference)
(define-key tfsmacs-status-mode-map (kbd "h") 'tfsmacs--status-mode-help)
(define-key tfsmacs-status-mode-map (kbd "L") 'tfsmacs--status-mode-shelve)

(defun tfsmacs--status-mode-help ()
  "Show help for the status mode."
  (interactive)
  (let ((help-message
        (concat
         "--TFS Status help--\n\n"
         "This mode is derived from tabulated-list, so the usual bindings for marking elements work "
         "as expected (m and u to mark and unmark, for example).\n\n"
         "RET visits the file under point.\n\n"
         "C will check in the files marked. You will be prompted for a changeset comment, a PBI to "
         "associate and an override reason. Blank for any of the latter two means they are ignored.\n\n"
         "R runs \"undo\" in the files marked. R from \"Revert\" :).\n\n"
         "g updates the list of pending changes. It can take a couple seconds since it runs a check "
         "against the server.\n\n"
         "D runs ediff between a file marked in the list (or the one under point if none are marked)."
         " It will compare your local with the latest on the server. The get for file is synchronous, "
         "Emacs will be unresponsive until the operation is completed.\n\n"
         "L (later) will shelve the files marked.")))
    (tfsmacs--show-help help-message)))

(defun tfsmacs-pending-changes ()
  "Perform a recursive tf status.  Displays the result in a separate buffer."
  (interactive)
  (with-current-buffer (current-buffer)
    (if (derived-mode-p 'tfsmacs-status-mode)
        (tfsmacs--get-pending-changes tfsmacs--buffer-status-dir)
      (progn
        (let* ((status-dir (tfsmacs--quote-string (tfsmacs--select-status-directory)))
               (buffer (get-buffer-create "*TFS Status [...]*")))
          (with-current-buffer buffer
            (setq tfsmacs--buffer-status-dir status-dir)
            (tfsmacs--get-pending-changes status-dir)
            (switch-to-buffer buffer)))))))

(defun tfsmacs--get-pending-changes (directory)
  "Internal call to run the status command in DIRECTORY."
  (let* ((command (list "status" directory "-recursive" "-nodetect"  "-format:xml")))
    (message (format "TFS: Obtaining list of pending changes for directory %s"
                     directory))
    (tfsmacs--async-command command 'tfsmacs--status-callback)))

(defun tfsmacs--status-callback (output)
  "Process the OUTPUT of tf status and display the ‘tfsmacs-status-mode’ buffer."
  (when (> tfsmacs--command-retries 0) ;; if the command failed, don't run
    (let ((parsed-data (tfsmacs--get-status-data-for-tablist output)))
      (let* ((directory tfsmacs--buffer-status-dir)
             (last-dir-in-path (tfsmacs--get-last-dir-name directory))
             (status-bufname (format "*TFS Status %s *" last-dir-in-path))
             (buffer (get-buffer status-bufname)))
        (when (not buffer)
          (setq buffer (get-buffer "*TFS Status [...]*"))
          (erase-buffer))
        (with-current-buffer buffer
          (tfsmacs-status-mode)
          ;; Buffer local vars
          (setq tabulated-list-entries parsed-data)
          (setq tfsmacs--buffer-status-dir directory)
          (tablist-revert)
          (rename-buffer status-bufname)
          (switch-to-buffer buffer))))
    (message "TFS: Showing pending changes. Press \"h\" to show available bindings.")))

(defun tfsmacs--get-status-data-for-tablist (xml-status-data)
  "Format XML-STATUS-DATA from the status command for tabulated list."
  (with-temp-buffer
    (insert xml-status-data)
    (let* ((converted-xml-data (libxml-parse-xml-region (point-min) (point-max)))
           (pending-change-nodes (dom-by-tag converted-xml-data 'pending-change)))
      (mapcar 'tfsmacs--format-status-node pending-change-nodes))))

(defun tfsmacs--format-status-node (pending-changes-node)
  "Extract from PENDING-CHANGES-NODE the info."
  (let ((data (cadr pending-changes-node)))
    (list
     (alist-get 'local-item data)
     (vector
      (alist-get 'change-type data)
      (alist-get 'local-item data)
      (alist-get 'server-item data)))))

(defun tfsmacs--select-status-directory ()
  "Prompt for a directory.  Try  projectile root first, else use current buffer's directory."
  (let ((default-dir-prompt "?"))
    (ignore-errors
      (when (fboundp 'projectile-project-root)
        (setq default-dir-prompt (projectile-project-root))))
    (when (string= default-dir-prompt "?")
      (setq default-dir-prompt default-directory))
    (read-directory-name "Status for directory: " default-dir-prompt nil t)))

(defun tfsmacs--shelvesets-mode-unshelve ()
  "Unshelve to current workspace when in tfsmacs-shelvesets-mode."
  (interactive)
  (let* ((items (tfsmacs--shelvesets-mode-get-marked-items))
         (to-unshelve (car items))
         (as-string (format "\"%s;%s\"" (car to-unshelve) (cadr to-unshelve))))
    (if (tfsmacs--single-item-list items)
        (progn
          (message (format "TFS: Unshelving %s" as-string))
          (tfsmacs--async-command (list "unshelve" as-string) 'tfsmacs--shelvesets-mode-unshelve-callback))
      (error "Only one item should be selected for this operation"))))

(defun tfsmacs--shelvesets-mode-unshelve-callback (_output)
  "Process OUTPUT of unshelving."
  ;; Unshelving has empty output, but we can use our flag
  ;; to detect is the command ran fine.
  (when (> tfsmacs--command-retries 0) ;; if the command failed, don't run
    (message "TFS: Changes unshelved.")))

(defun tfsmacs--shelvesets-mode-details ()
  "Unshelve to current workspace when in tfsmacs-shelvesets-mode."
  (interactive)
  (let* ((items (tfsmacs--shelvesets-mode-get-marked-items))
         (to-unshelve (car items))
         (as-string (format "\"%s;%s\"" (car to-unshelve) (cadr to-unshelve))))
    (if (tfsmacs--single-item-list items)
        (progn
          (when (get-buffer tfsmacs--shelveset-buffer-name)
            (kill-buffer tfsmacs--shelveset-buffer-name))
          (message (format "TFS: Retrieving shelveset info for %s" as-string))
          (tfsmacs--async-command (list "shelvesets" "-format:detailed" as-string) 'tfsmacs--shelvesets-mode-details-callback1))
      (error "Only one item should be selected for this operation"))))

(defun tfsmacs--shelvesets-mode-details-callback1 (output)
  "Display OUTPUT (shelveset details header) in the buffer and invoke next command."
  (if (string-empty-p (tfsmacs--trim-string output))
      (error "Couldn't get shelveset details")
    (progn
      (with-current-buffer (get-buffer-create tfsmacs--shelveset-buffer-name)
        (insert output))
      (tfsmacs--optional-message "TFS: Retrieving collection URL...")
      (tfsmacs--async-command (list "workfold") 'tfsmacs--shelvesets-mode-details-callback2))))

(defun tfsmacs--shelvesets-mode-details-callback2 (output)
  "Process the OUTPUT of the command \"tf workfold -workspace:name\" to get the collection URL."
  (let* ((items (tfsmacs--shelvesets-mode-get-marked-items))
         (to-unshelve (car items))
         (as-string (format "\"%s;%s\"" (car to-unshelve) (cadr to-unshelve)))
         (url (car (cl-remove-if-not (lambda (x): (string-prefix-p "http://" x))
                                  (split-string output)))))
    (tfsmacs--async-command (list "status" (format "-collection:%s" url) (format "-shelveset:%s" as-string))
                            'tfsmacs--shelvesets-details-callback
                            t)))

(defun tfsmacs--shelvesets-details-callback (output)
  "Show the buffer with the shelveset details.
OUTPUT is the command's output"
  (with-current-buffer (get-buffer-create tfsmacs--shelveset-buffer-name)
    (insert output)
    (read-only-mode)
    (switch-to-buffer-other-window tfsmacs--shelveset-buffer-name t)))

(define-derived-mode tfsmacs-shelvesets-mode tabulated-list-mode "TFS Shelvesets Mode" "Major mode TFS Shelvesets, displays a list of shelvesets by user and allows operations on them."
  (setq tabulated-list-format [("Owner" 30 t)
                               ("Date" 20 t)
                               ("Name" 0 t)])
  (setq tabulated-list-padding 1)
  (setq tabulated-list-sort-key (cons "Date" t))
  (tabulated-list-init-header)
  (tablist-minor-mode))

(define-key tfsmacs-shelvesets-mode-map (kbd "R") 'tfsmacs--shelvesets-mode-unshelve)
(define-key tfsmacs-shelvesets-mode-map (kbd "D") 'tfsmacs--shelvesets-mode-details)
(define-key tfsmacs-shelvesets-mode-map (kbd "h") 'tfsmacs--shelvesets-mode-help)

(defun tfsmacs--shelvesets-mode-help ()
  "Show help for the shelvesets mode."
  (interactive)
  (let ((help-message
        (concat
         "--TFS Shelvesets help--\n\n"
         "This mode is derived from tabulated-list, so the usual bindings for marking elements work "
         "as expected (m and u to mark and unmark, for example).\n\n"
         "R (retrieve) unshelves the shelve under point or marked (only one can be marked).\n\n"
         "D shows details for the current/marked shelveset in a separate buffer.")))
    (tfsmacs--show-help help-message)))

(defun tfsmacs-shelvesets (&optional owner)
  "Run \"tf shelvesets\" and show the output in a tabulated list buffer.
If OWNER is not provided in the call, it will be prompted."
  (interactive)
  (when (not owner)
    (setq owner (read-string "Filter by user (blank for your own shelves, * for all users): ")))
  (message "TFS: Retrieving shelvesets...")
  (let ((command (list "shelvesets" "-format:xml")))
    (when (not (string-empty-p owner))
      (setq command (append command (list (format "-owner:\"%s\"" owner)))))
    (tfsmacs--async-command command 'tfsmacs--shelvesets-callback)))

(defun tfsmacs--shelvesets-callback (output)
  "Process the shelvesets list and display the ‘tfsmacs-shelvesets-mode’ buffer.
OUTPUT is the XML output from \"tf shelvesets\"."
  (when (> tfsmacs--command-retries 0) ;; if the command failed, don't run
    (message "TFS: Displaying shelvesets. Press \"h\" to show available bindings.")
    (let ((parsed-data (tfsmacs--get-shelvesets-data-for-tablist output)))
      (let* ((shelvesets-bufname (format "*TFS Shelvesets*"))
             (buffer (get-buffer-create shelvesets-bufname)))
        (with-current-buffer buffer
          (setq tabulated-list-entries parsed-data)
          (tfsmacs-shelvesets-mode)
          (tablist-revert)
          (switch-to-buffer buffer))))))

(defun tfsmacs--get-shelvesets-data-for-tablist (xml-status-data)
  "Format XML-STATUS-DATA from the history command for tabulated list."
  (with-temp-buffer
    (insert xml-status-data)
    (let* ((converted-xml-data (libxml-parse-xml-region (point-min) (point-max)))
           (shelvesets-nodes (dom-by-tag converted-xml-data 'shelveset)))
      (mapcar 'tfsmacs--format-shelveset-node shelvesets-nodes))))

(defun tfsmacs--format-shelveset-node (shelveset-node)
  "Extract from SHELVESET-NODE the info."
  (let* ((data (cadr shelveset-node))
         (name (alist-get 'name data))
         (owner (alist-get 'owner data))
         (date (tfsmacs--format-xml-date (alist-get 'date data))))
    (list (list name owner)
          (vector owner date name))))

(defun tfsmacs--shelvesets-mode-get-marked-items ()
  "Obtain only (name owner) of the files selected in the list."
  (mapcar 'car (tablist-get-marked-items)))

(provide 'tfsmacs)

;;; tfsmacs.el ends here
