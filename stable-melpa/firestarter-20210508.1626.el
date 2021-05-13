;;; firestarter.el --- Execute (shell) commands on save

;; Copyright (C) 2015 Vasilij Schneidermann <mail@vasilij.de>

;; Author: Vasilij Schneidermann <mail@vasilij.de>
;; URL: https://depp.brause.cc/firestarter
;; Package-Version: 20210508.1626
;; Package-Commit: 76070c9074aa363350abe6ad06143e90b3e12ab1
;; Version: 0.2.5
;; Package-Requires: ((emacs "24.1"))
;; Keywords: convenience

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This global minor mode allows you to run (shell) commands on save.

;; See the README for more info: https://depp.brause.cc/firestarter

;;; Code:

(require 'format-spec)
(require 'ansi-color)

(defgroup firestarter nil
  "Execute shell commands on save."
  :group 'convenience
  :prefix "firestarter-")

(defvar firestarter nil
  "Command to run on file save.
A string value is interpreted as shell command and passed to an
asynchronous subprocess.  A symbol value is interpreted as
command and executed interactively.  A list value is interpreted
as code and evaluated.")
(make-variable-buffer-local 'firestarter)

(defcustom firestarter-default-type 'silent
  "Default shell command reporting type.
It may be one of the following values:

nil, 'silent: Don't report anything at all.

'success: Report on successful execution (return code equals zero).

'failure: Report on failed execution (return code equals non-zero).

t, 'finished: Report after either outcome once the subprocess quit."
  :type '(choice (const :tag "Silent" silent)
                 (const :tag "Success" success)
                 (const :tag "Failure" failure)
                 (const :tag "Finished" finished))
  :group 'firestarter)

(defcustom firestarter-auto-kill nil
  "Non-nil to kill current process automatically when starting anew"
  :type 'boolean
  :group 'firestarter)

(defvar firestarter-type nil
  "Current shell command reporting type.
See `firestarter-default-type' for valid values.")
(make-variable-buffer-local 'firestarter-type)

(defvar firestarter-process nil
  "Process associated with current buffer.")
(make-variable-buffer-local 'firestarter-process)

(defcustom firestarter-buffer-name "*firestarter*"
  "Buffer name of the reporting buffer for shell commands."
  :type 'string
  :group 'firestarter)

(defcustom firestarter-reporting-functions nil
  "Abnormal hook run after process termination.
The process is used as argument.  See
`firestarter-report-to-buffer' for the default value and as
example for writing your own reporting function."
  :type 'hook
  :group 'firestarter)
(add-hook 'firestarter-reporting-functions 'firestarter-report-to-buffer)

(defcustom firestarter-reporting-format
  (concat (propertize "%b (%c):" 'face 'highlight)
          "\n\n%s\n"
          (propertize "---" 'face 'shadow)
          "\n\n")
  "Format string for a single report item.
Available format codes are:

%b: Buffer name

%c: Return code

%s: Process output"
  :type 'string
  :group 'firestarter)

(defun firestarter-process-running-p ()
  "Return non-nil if a process is currently running."
  (and firestarter-process
       (not (memq (process-status firestarter-process)
                  '(exit signal nil)))))

(defun firestarter-command (command &optional type)
  "Execute COMMAND in a shell.
Optionally, override the reporting type as documented in
`firestarter-default-type' with TYPE."
  (let ((should-start
         (or (not (firestarter-process-running-p))
             (when firestarter-auto-kill
               (message "Killing the current process") t)
             (y-or-n-p "Kill current process to start a new one? "))))
    (when should-start
      (firestarter-abort)
      (setq firestarter-process
            (start-process "firestarter" nil
                           shell-file-name shell-command-switch
                           (firestarter-format command)))
      (process-put firestarter-process 'output "")
      (process-put firestarter-process 'type
                   (or type firestarter-type firestarter-default-type))
      (process-put firestarter-process 'buffer-name
                   (buffer-name (current-buffer)))
      (set-process-filter firestarter-process 'firestarter-filter)
      (set-process-sentinel firestarter-process 'firestarter-sentinel))))

(defun firestarter-format (string)
  "Apply format codes on STRING.
Available format codes are:

%b: Buffer name.  Equals the file name for buffers linked with
 files.  Beware that this is merely convention and buffers can be
 renamed to conform to their unique name constraint!

%p: Full path of the file associated with the buffer.  Decomposes
 into a directory and file name part.  If there is no file
 association, the value is an empty string.  As the following
 format codes are directly derived from this value, the same
 caveat applies to them as well.

%d: Directory name of the file associated with the buffer.
 Equals the full path without the file name.

%f: File name of the file associated with the buffer.  Decomposes
 into a file stem and a file extension.

%s: File stem of the file associated with the buffer.  Equals the
 file name without its extension.

%e: File extension of the file associated with the buffer.
 Equals the file name without its stem.  Includes the period if
 an extension is present, otherwise the value is an empty
 string."
  (let* ((buffer (shell-quote-argument (buffer-name)))
         (path (shell-quote-argument (or (buffer-file-name) "")))
         (directory (shell-quote-argument (file-name-directory (or path ""))))
         (file (shell-quote-argument (file-name-nondirectory (or path ""))))
         (stem (shell-quote-argument (file-name-sans-extension file)))
         (extension (shell-quote-argument (file-name-extension file t))))
    (format-spec string (format-spec-make ?b buffer ?p path ?d directory
                                          ?f file ?s stem ?e extension))))

(defun firestarter-filter (process output)
  "Special process filter.
Appends OUTPUT to the process output property."
  (process-put process 'output (concat (process-get process 'output) output)))

(defun firestarter-sentinel (process _type)
  "Special process sentinel.
It retrieves the status of PROCESS, then sets up and displays the
reporting buffer according to the reporting type."
  (when (memq (process-status process) '(exit signal nil))
    (run-hook-with-args 'firestarter-reporting-functions process)))

(defun firestarter-report-to-buffer (process)
  "Sets up and displays a reporting buffer.
Process output, buffer name, return code and reporting type are
all derived from PROCESS.  See also `firestarter-default-type'."
  (let ((return-code (process-exit-status process))
        (buffer-name (process-get process 'buffer-name))
        (output (process-get process 'output))
        (type (process-get process 'type))
        end)
    (unless (memq type '(silent nil))
      (with-current-buffer (get-buffer-create firestarter-buffer-name)
        (let ((inhibit-read-only t))
          (special-mode)
          (goto-char (point-max))
          (insert
           (ansi-color-apply
            (format-spec firestarter-reporting-format
                         (format-spec-make ?b buffer-name
                                           ?c return-code
                                           ?s output))))
          (setq end (point-max))))
      (when (or (and (eq type 'success) (= return-code 0))
                (and (eq type 'failure) (/= return-code 0))
                (memq type '(finished t)))
        (let ((window (display-buffer firestarter-buffer-name)))
          (when window
            (set-window-point window end)))))))

(defun firestarter ()
  "Hook function run after save.
It dispatches upon the value type of `firestarter'."
  (interactive)
  (when firestarter
    (cond
     ((stringp firestarter)
      (firestarter-command firestarter))
     ((functionp firestarter)
      (call-interactively firestarter))
     ((listp firestarter)
      (eval firestarter))
     (t (error "Invalid value for `firestarter': %s" firestarter)))))

(defun firestarter-abort ()
  "Abort the currently active firestarter process."
  (interactive)
  (when firestarter-process
    (delete-process firestarter-process)))

;;;###autoload
(defun firestarter-set-function (fname)
  "Set function on the firestarter variable."
  (interactive "aWhich function: ")
  (setq firestarter fname))

;;;###autoload
(define-minor-mode firestarter-mode
  "Toggle `firestarter-mode'.
When activated, run a command as specified in the buffer-local
`firestarter' variable on every file save."
  :global t
  (if firestarter-mode
      (add-hook 'after-save-hook 'firestarter)
    (remove-hook 'after-save-hook 'firestarter)))

(provide 'firestarter)
;;; firestarter.el ends here
