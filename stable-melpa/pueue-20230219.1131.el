;;; pueue.el --- Interface for pueue                 -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Valeriy Litkovskyy

;; Author: Valeriy Litkovskyy <vlr.ltkvsk@protonmail.com>
;; Keywords: processes
;; Package-Version: 20230219.1131
;; Package-Commit: 96d33e5d93b2844eb260c346502029b4d2c49b6c
;; Version: 2.1.0
;; URL: https://github.com/xFA25E/pueue
;; Package-Requires: ((emacs "28.1") (with-editor "3.0.4"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides an intuitive GUI for pueue task manager.

;;;; Installation

;;;;; Package manager

;; If you've installed it with your package manager, then you are probably done.
;; `pueue' command is autoloaded, so you can call it right away.

;;;;; Manual

;; It depends on the following packages:

;; + with-editor

;; Then put this file in your load-path, and put this in your init
;; file:

;; (require 'pueue)

;;;; Usage

;; Run `pueue' command.  You can press ? key or call `describe-mode' to discover
;; available keybindings.  Dired-like marking also works.

;;;; Tips

;; + You can customize settings in the `pueue' group.

;; + Required version of pueue is 2.0.0.  Although the visualization of tasks
;;   and detailed view will work with 1.0.0, some commands (like group) have
;;   changed their API in 2.0.0.

;;;; Credits

;; This package would not have been possible without the excellent pueue[1] task
;; manager.
;;
;;  [1] https://github.com/Nukesor/pueue

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'map)
(require 'parse-time)
(require 'rx)
(require 'tabulated-list)
(require 'transient)
(require 'with-editor)

(defvar crm-completion-table)

;;;; Customization

(defgroup pueue nil
  "Settings for `pueue'."
  :link '(url-link "https://github.com/xFA25E/pueue")
  :group 'external
  :group 'processes
  :group 'applications)

(defcustom pueue-command '("pueue")
  "Pueue command."
  :type '(repeat :tag "Command" (string :tag "Part"))
  :group 'pueue)

(defcustom pueue-buffer-name "*Pueue*"
  "Default buffer name for `pueue-mode'."
  :type 'string
  :group 'pueue)

(defcustom pueue-info-buffer-name "*Pueue Info*"
  "Default buffer name for `pueue-info-mode'."
  :type 'string
  :group 'pueue)

(defface pueue-success
  '((t :inherit success))
  "Face used for success."
  :group 'pueue)

(defface pueue-error
  '((t :inherit error))
  "Face used for error."
  :group 'pueue)

(defface pueue-label
  '((t :inherit font-lock-constant-face))
   "Face used for field labels."
   :group 'pueue)

(defface pueue-environment-variable
  '((t :inherit font-lock-variable-name-face))
   "Face used for environment variables."
   :group 'pueue)

;;;; Variables

(defvar-local pueue-marked-ids nil
  "Marked ids in tabulated list mode.")

(defvar-local pueue--info-history nil
  "List containing history of visited tasks.
History is recorded only when tasks are visited from the same
buffer.  Every time `pueue-info' is called from different buffer,
history is reset.")

;;;;; Keymaps

(easy-mmode-defmap pueue-mode-map
  '(("\C-m" . pueue-info)
    ("m" . pueue-mark)
    ("u" . pueue-unmark)
    ("U" . pueue-unmark-all)
    ("t" . pueue-toggle-marks)
    ("a" . pueue-add)
    ("c" . pueue-clean)
    ("e" . pueue-edit)
    ("Q" . pueue-enqueue)
    ("f" . pueue-follow)
    ("G" . pueue-group)
    ("k" . pueue-kill)
    ("l" . pueue-log)
    ("L" . pueue-parallel)
    ("P" . pueue-pause)
    ("R" . pueue-remove)
    ("T" . pueue-reset)
    ("r" . pueue-restart)
    ("d" . pueue-send)
    ("s" . pueue-start)
    ("H" . pueue-stash)
    ("w" . pueue-switch)
    ("?" . pueue-help))
  "Keymap for `pueue-mode'.")

(easy-mmode-defmap pueue-info-mode-map
  '(("l" . pueue-info-backward-history))
  "Keymap for `pueue-info-mode'.")

;;;; Commands

;;;###autoload
(defun pueue ()
  "Main entry command for pueue task manager."
  (interactive)
  (with-current-buffer (get-buffer-create pueue-buffer-name)
    (pueue-mode)
    (pueue--refresh-tabulated-list-entries)
    (tabulated-list-print)
    (pop-to-buffer (current-buffer))))

(define-derived-mode pueue-mode tabulated-list-mode "Pueue"
  "Mode used to manage pueue tasks."
  :group 'pueue
  (cl-flet ((compare-ids (a b) (< (car a) (car b))))
    (setq tabulated-list-padding 2
          tabulated-list-sort-key (cons "ID" t)
          tabulated-list-printer #'pueue--tabulated-list-print-entry
          tabulated-list-format (vector (list "ID"      5 #'compare-ids)
                                        (list "Status"  9 t)
                                        (list "Start"   6 t)
                                        (list "End"     6 t)
                                        (list "Group"   8 t)
                                        (list "Label"   6 t)
                                        (list "Command" 0 t))))
  (add-hook 'tabulated-list-revert-hook #'pueue--refresh-tabulated-list-entries
            nil t)
  (tabulated-list-init-header))

(defun pueue-mark ()
  "Mark pueue task at point."
  (interactive)
  (cl-pushnew (pueue--id-at-point) pueue-marked-ids :test #'=)
  (tabulated-list-put-tag "*" t))

(defun pueue-unmark ()
  "Unmark pueue taks at point."
  (interactive)
  (cl-callf2 cl-delete (pueue--id-at-point) pueue-marked-ids :test #'=)
  (tabulated-list-put-tag " " t))

(defun pueue-unmark-all ()
  "Unmark all pueue tasks."
  (interactive)
  (setq pueue-marked-ids nil)
  (tabulated-list-clear-all-tags))

(defun pueue-toggle-marks ()
  "Toggle every mark in buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (if (memq (pueue--id-at-point) pueue-marked-ids)
          (pueue-unmark)
        (pueue-mark)))))

(defun pueue-info (id)
  "Main entry command to display details of pueue some task.
ID is a number which corresponds to some pueue task id."
  (interactive (list (pueue--id-at-point)))
  (with-current-buffer (get-buffer-create pueue-info-buffer-name)
    (pueue-info-mode)
    (pueue--draw-task id)
    (pop-to-buffer (current-buffer))))

(define-derived-mode pueue-info-mode special-mode "PueueInfo"
  "Mode used to draw detailed pueue task information."
  :group 'pueue
  (buffer-disable-undo)
  (cl-flet ((redraw (&rest _) (pueue--draw-task (pop pueue--info-history))))
    (setq-local revert-buffer-function #'redraw))
  (button-mode))

(defun pueue-info-backward-history ()
  "Go back in history."
  (interactive)
  (when-let ((history (cdr pueue--info-history)))
    (setq pueue--info-history history)
    (pueue--draw-task (pop pueue--info-history))))

;;;;; Pueue

(transient-define-infix pueue:--delay ()
  "Number of seconds or a \"date expression\".

2020-04-01T18:30:00   // RFC 3339 timestamp
2020-4-1 18:2:30      // Optional leading zeros
2020-4-1 5:30pm       // Informal am/pm time
2020-4-1 5pm          // Optional minutes and seconds
April 1 2020 18:30:00 // English months
1 Apr 8:30pm          // Implies current year
4/1                   // American form date
wednesday 10:30pm     // The closest wednesday in the future at 22:30
wednesday             // The closest wednesday in the future
4 months              // 4 months from today at 00:00:00
1 week                // 1 week at the current time
1days                 // 1 day from today at the current time
1d 03:00              // The closest 3:00 after 1 day (24 hours)
3h                    // 3 hours from now
3600s                 // 3600 seconds from now"
  :description "Delay"
  :class transient-option
  :argument "--delay="
  :shortarg "-d")

;;;;;; Add

(defun pueue-add-command (command &rest args)
  "Add COMMAND to pueue.
ARGS are arguments for pueue add command."
  (interactive
   (let ((command (read-shell-command "Command: ")))
     (if (length> command 0)
         (cons command (transient-args 'pueue-add))
       (user-error "Empty input"))))
  (pueue--call "add" args "--" command))

(transient-define-prefix pueue-add ()
  "Run pueue add command."
  :incompatible '(("--immediate" "--stashed") ("--immediate" "--delay="))
  ["Flags"
   ("-i" "Immediately start the task" "--immediate")
   ("-s" "Create the task in Stashed state" "--stashed")]
  ["Options"
   (pueue:--delay
    :description "Prevents the task from being enqueued until <delay> elapses")
   ("-a" "Start the task after other tasks" "--after=" pueue--read-tasks
    :multi-value repeat)
   ("-g" "Assign the task to a group" "--group=" pueue--read-group)
   ("-l" "Add some information for yourself" "--label=")
   ("-w" "Specify current working directory" "--working-directory="
    transient-read-existing-directory)]
   ["Actions" ("a" "Add" pueue-add-command)])

;;;;;; Clean

(defun pueue-clean-tasks (&rest args)
  "Run pueue clean command with ARGS."
  (interactive (transient-args 'pueue-clean))
  (pueue--call "clean" args))

(transient-define-prefix pueue-clean ()
  "Run pueue clean command."
  ["Flags"
   ("-s" "Only clean tasks that finished successfully" "--successful-only")]
  ["Options"
   ("-g" "Only clean tasks of a specific group" "--group=" pueue--read-group)]
  ["Actions" ("c" "Clean" pueue-clean-tasks)])

;;;;;; Edit

(defun pueue-edit-task (id &rest args)
  "Run pueue edit command with ARGS and ID.
ID is a string."
  (interactive (cons (pueue--id-arg) (transient-args 'pueue-edit)))
  (pueue--start "edit" args id))

(transient-define-prefix pueue-edit ()
  "Run pueue edit command."
  ["Flags" ("-p" "Edit the path of the task" "--path")]
  ["Actions" ("e" "Edit" pueue-edit-task)])

;;;;;; Enqueue

(defun pueue-enqueue-tasks (ids &rest args)
  "Run pueue enqueue command with ARGS and IDS.
IDS are strings."
  (interactive (cons (pueue--id-args) (transient-args 'pueue-enqueue)))
  (pueue--call "enqueue" args ids))

(transient-define-prefix pueue-enqueue ()
  "Run pueue enqueue command."
  ["Options"
   (pueue:--delay
    :description "Delay enqueuing these tasks until <delay> elapses")]
  ["Actions" ("Q" "Enqueue" pueue-enqueue-tasks)])

;;;;;; Follow

(defun pueue-follow-task (id &rest args)
  "Run pueue follow command with ARGS and ID.
ID is a string."
  (interactive (cons (pueue--id-arg) (transient-args 'pueue-follow)))
  (let* ((buffer-name "*Pueue Follow*")
         (parts `(,@pueue-command "follow" ,@args ,id))
         (command (mapconcat #'shell-quote-argument parts " ")))
    (when-let ((buffer (get-buffer buffer-name)))
      (kill-buffer buffer))
    (async-shell-command command buffer-name)))

(transient-define-prefix pueue-follow ()
  "Run pueue follow command."
  ["Options"
   ("-l" "Print the last X lines of the output before following" "--lines="
    transient-read-number-N+)]
  ["Actions" ("f" "Follow" pueue-follow-task)])

;;;;;; Group

(defun pueue-group-add (group &rest args)
  "Run pueue group add command with ARGS and GROUP."
  (interactive (let ((group (read-string "Group name: ")))
                 (if (length> group 0)
                     (cons group (transient-args 'pueue-group))
                   (user-error "Empty group"))))
  (pueue--call "group" "add" args group)
  (revert-buffer nil t))

(defun pueue-group-remove (group)
  "Run pueue group remove command with GROUP."
  (interactive (list (pueue--read-group "Remove group")))
  (pueue--call "group" "remove" group))

(transient-define-prefix pueue-group ()
  "Run pueue group command."
  ["Add"
   ("-l" "Set the amount of parallel tasks this group can have" "--parallel="
    transient-read-number-N+)
   ("a" "Add a group by name" pueue-group-add)]
  ["Remove" ("r" "Remove" pueue-group-remove)])

;;;;;; Kill

(defun pueue-kill-tasks (ids &rest args)
  "Run pueue kill command with ARGS and IDS.
IDS are strings."
  (interactive
   (let ((args (transient-args 'pueue-kill)))
     (cons (pueue--id-args-unless '("--all" "--group=") args) args)))
  (pueue--call "kill" args ids))

(transient-define-prefix pueue-kill ()
  "Run pueue kill command."
  :incompatible '(("--all" "--group="))
  ["Flags"
   ("-a" "Kill all running tasks across ALL groups. This also pauses all groups"
    "--all")
   ("-c" "Send the SIGTERM signal to all children as well" "--children")]
  ["Options"
   ("-g" "Kill all running tasks in a group. Pause the group" "--group="
    pueue--read-group)
   ("-s" "Send a UNIX signal instead of simply killing the process" "--signal="
    transient-read-number-N+)]
  ["Actions" ("k" "Kill" pueue-kill-tasks)])

;;;;;; Log

(defun pueue-log-tasks (ids &rest args)
  "Run pueue log command with ARGS and IDS.
IDS are strings."
  (interactive (cons (pueue--id-args) (transient-args 'pueue-log)))
  (let* ((buffer-name "*Pueue Log*")
         (parts `(,@pueue-command "log" ,@args ,@ids))
         (command (mapconcat #'shell-quote-argument parts " ")))
    (async-shell-command command buffer-name)))

(transient-define-prefix pueue-log ()
  "Run pueue log command."
  :incompatible '(("--full" "--lines="))
  ["Flags" ("-f" "Show the whole stdout and stderr output" "--full")]
  ["Options" ("-l" "Print the last X lines of tasks output" "--lines="
              transient-read-number-N+)]
  ["Actions" ("l" "Log" pueue-log-tasks)])

;;;;;; Parallel

(defun pueue-parallel-tasks (count &rest args)
  "Run pueue parallel command with ARGS and COUNT.
COUNT is a string."
  (interactive
   (let ((count (transient-read-number-N+ "Parallel tasks: " nil nil)))
     (if (length> count 0)
         (cons count (transient-args 'pueue-parallel))
       (user-error "Empty input"))))
  (pueue--call "parallel" args count))

(transient-define-prefix pueue-parallel ()
  "Run pueue parallel command."
  ["Options"
   ("-g" "Set the amount for the specific group" "--group="
    pueue--read-group)]
  ["Actions" ("L" "Parallel" pueue-parallel-tasks)])

;;;;;; Pause

(defun pueue-pause-tasks (ids &rest args)
  "Run pueue pause command with ARGS and IDS.
IDS are strings."
  (interactive
   (let ((args (transient-args 'pueue-pause)))
     (cons (pueue--id-args-unless '("--all" "--group=") args) args)))
  (pueue--call "pause" args ids))

(transient-define-prefix pueue-pause ()
  "Run pueue pause command."
  :incompatible '(("--all" "--group="))
  ["Flags"
   ("-a" "Pause all groups" "--all")
   ("-c" "Also pause direct child processes of a task's main proces"
    "--children")
   ("-w" "Pause a group letting running tasks finish" "--wait")]
  ["Options" ("-g" "Pause a specific group" "--group=" pueue--read-group)]
  ["Actions" ("P" "Pause" pueue-pause-tasks)])

;;;;;; Remove

(defun pueue-remove (ids)
  "Run pueue remove command with IDS.
IDS are strigs"
  (interactive (list (pueue--id-args)))
  (when (zerop (pueue--call "remove" ids))
    (pueue-unmark-all)))

;;;;;; Reset

(defun pueue-reset-tasks (&rest args)
  "Run pueue reset command with ARGS."
  (interactive (transient-args 'pueue-reset))
  (pueue--call "reset" args))

(transient-define-prefix pueue-reset ()
  "Run pueue reset command."
  ["Flags"
   ("-c" "Send the SIGTERM signal to all children as well" "--children")
   ("-f" "Don't ask for any confirmation" "--force")]
  ["Actions" ("t" "Reset" pueue-reset-tasks)])

;;;;;; Restart

(defun pueue-restart-tasks (ids &rest args)
  "Run pueue restart command with ARGS and IDS.
IDS are strings."
  (interactive (let ((incompatible '("--all-failed" "--failed-in-group="))
                     (args (transient-args 'pueue-restart)))
                 (cons (pueue--id-args-unless incompatible args) args)))
  (if (or (transient-arg-value "--edit" args)
          (transient-arg-value "--edit-path" args))
      (pueue--start "restart" args ids)
    (pueue--call "restart" args ids)))


(transient-define-prefix pueue-restart ()
  "Run pueue restart command."
  :incompatible '(("--all-failed" "--failed-in-group=")
                  ("--start-immediately" "--stashed"))
  ["Flags"
   ("-a" "Restart all failed tasks" "--all-failed")
   ("-e" "Edit the tasks' command before restarting" "--edit")
   ("-i" "Restart the task by reusing the already existing tasks" "--in-place")
   ("-k" "Immediately start the tasks" "--start-immediately")
   ("-p" "Edit the tasks' path before restarting" "--edit-path")
   ("-s" "Set the restarted task to a \"Stashed\" state" "--stashed")]
  ["Options"
   ("-g" "Restart all failed tasks in group" "--failed-in-group="
    pueue--read-group)]
  ["Actions" ("r" "Restart" pueue-restart-tasks)])

;;;;;; Send

(defun pueue-send (id input)
  "Run pueue send command with ID and INPUT.
ID is a string."
  (interactive (list (pueue--id-arg) (read-string "Input: ")))
  (pueue--call "send" id input))

;;;;;; Start

(defun pueue-start-tasks (ids &rest args)
  "Run pueue start command with ARGS and IDS.
IDS are strings."
  (interactive
   (let ((args (transient-args 'pueue-start)))
     (cons (pueue--id-args-unless '("--all" "--group=") args) args)))
  (pueue--call "start" args ids))

(transient-define-prefix pueue-start ()
  "Run pueue start command."
  :incompatible '(("--all" "--group="))
  ["Flags"
   ("-a" "Resume all groups" "--all")
   ("-c" "Also resume direct child processes of your paused tasks"
    "--children")]
  ["Options"
   ("-g" "Resume a specific group and all paused tasks in it" "--group="
    pueue--read-group)]
  ["Actions" ("s" "Start" pueue-start-tasks)])

;;;;;; Stash

(defun pueue-stash (ids)
  "Run pueue stash command with IDS.
IDS are strings."
  (interactive (list (pueue--id-args)))
  (pueue--call "stash" ids))

;;;;;; Switch

(defun pueue-switch (id-1 id-2)
  "Run pueue switch command with ID-1 and ID-2.
ID-1 and ID-2 are strings."
  (interactive
   (let ((ids (pueue--id-args)))
     (if (length= ids 2)
         ids
       (user-error "Need two marked tasks"))))
  (pueue--call "switch" id-1 id-2))

;;;;;; Help

(transient-define-prefix pueue-help ()
  "Show all pueue commmands."
  [["Task actions"
    ("e" "Edit" pueue-edit)
    ("Q" "Enqueue" pueue-enqueue)
    ("k" "Kill" pueue-kill)
    ("P" "Pause" pueue-pause)]
   [""
    ("R" "Remove" pueue-remove)
    ("r" "Restart" pueue-restart)
    ("s" "Start" pueue-start)
    ("H" "Stash" pueue-stash)]
   ["Task info"
    ("f" "Follow" pueue-follow)
    ("l" "Log" pueue-log)
    ("d" "Send" pueue-send)]
   ["Queue actions"
    ("a" "Add" pueue-add)
    ("c" "Clean" pueue-clean)
    ("w" "Switch" pueue-switch)]
   [""
    ("G" "Group" pueue-group)
    ("L" "Parallel" pueue-parallel)
    ("t" "Reset" pueue-reset)]])

;;;; Functions

(defun pueue--status ()
  "Get parsed output of pueue status command."
  (with-temp-buffer
    (save-excursion
      (apply #'call-process (car pueue-command) nil t nil
             `(,@(cdr pueue-command) "status" "--json")))
    (json-parse-buffer :null-object nil :false-object nil)))

(defun pueue--id-at-point ()
  "Get pueue task id at point or signal an error."
  (or (tabulated-list-get-id) (user-error "No task at point")))

(defun pueue--id-arg ()
  "Like `pueue--id-at-point', but convert to string.
This function is used in various pueue commands, since
`call-program' and friends require strings."
  (number-to-string (pueue--id-at-point)))

(defun pueue--id-args ()
  "Get marked task ids or id at point.
Its behaviour is similar to `pueue--id-arg'."
  (or (seq-map #'number-to-string pueue-marked-ids) (list (pueue--id-arg))))

(defun pueue--id-args-unless (incompatible args)
  "Get `pueue--id-args' unless INCOMPATIBLE are in ARGS."
  (unless (seq-some (lambda (a) (transient-arg-value a args)) incompatible)
    (pueue--id-args)))

(defun pueue--tabulated-list-print-entry (id cols)
  "Function used in `tabulated-list-printer'.
See it's documentation for ID and COLS."
  (tabulated-list-print-entry id cols)
  (when (memq id pueue-marked-ids)
    (forward-line -1)
    (tabulated-list-put-tag "*" t)))

(defun pueue--refresh-tabulated-list-entries ()
  "Refresh `tabulated-list-entries' with pueue tasks."
  (thread-last
    (map-elt (pueue--status) "tasks")
    (map-values-apply #'pueue--make-tabulated-list-entry)
    (setq tabulated-list-entries)))

(defun pueue--make-tabulated-list-entry (task)
  "Make tabulated list entry from TASK."
  (list (map-elt task "id")
        (seq-into (seq-map (pcase-lambda ((seq key fn))
                             (funcall fn (map-elt task key)))
                           [["id" number-to-string]
                            ["status" pueue--format-status-short]
                            ["start" pueue--format-time-short]
                            ["end" pueue--format-time-short]
                            ["group" identity]
                            ["label" concat]
                            ["command" identity]])
                  'vector)))

(defun pueue--draw-task (id)
  "Draw pueue task by ID.
If task with id ID does not exist, do nothing."
  (when-let* ((task (thread-first
                      (pueue--status)
                      (map-elt "tasks")
                      (map-elt (number-to-string id)))))
    (push id pueue--info-history)
    (with-silent-modifications
      (erase-buffer)
      (insert (pueue--format-task task))
      (goto-char (point-min)))))

;;;;; Processes

(defun pueue--call (&rest args)
  "Call pueue with ARGS.
ARGS is flattened with `flatten-tree'.  Show success or error
message."
  (with-temp-buffer
    (prog1 (apply #'call-process (car pueue-command) nil t nil
                  (flatten-tree (cons (cdr pueue-command) args)))
      (message "%s" (string-trim-right (buffer-string)))
      (with-current-buffer pueue-buffer-name (revert-buffer nil t)))))

(defun pueue--start (&rest args)
  "Start pueue with ARGS.
ARGS is flattened with `flatten-tree'.  Async process will revert
pueue buffer at the end.  Also, started `with-editor'."
  (with-editor
    ;; See https://github.com/Nukesor/pueue/issues/336
    (unless (pueue--client-supports-editor-shell-command-p)
      (setenv "EDITOR" with-editor-emacsclient-executable)
      (let ((socket-path (expand-file-name server-name server-socket-dir)))
        (setenv "EMACS_SOCKET_NAME" socket-path)))

    (make-process :name "pueue" :buffer " *pueue-process*"
                  :command (flatten-tree (cons pueue-command args))
                  :sentinel #'pueue--sentinel)))

(defun pueue--client-supports-editor-shell-command-p ()
  "Check if client supports $EDITOR as shell command."
  (with-temp-buffer
    (apply #'call-process (car pueue-command) nil t nil
           `(,@(cdr pueue-command) "--version"))
    (goto-char (point-min))
    (search-forward "Pueue client ")
    (thread-last
      (buffer-substring-no-properties (point) (1- (point-max)))
      version-to-list
      (version-list-<= '(2 1 1)))))

(defun pueue--sentinel (_process event)
  "Pueue process sentinel.
Reverts pueue buffer on success.

For _PROCESS and EVENT, see info node `(elisp) Sentinels'."
  (pcase event
    ((or "finished\n" (rx bos "exited abnormally with code"))
     (with-current-buffer pueue-buffer-name
       (revert-buffer nil t)))))

;;;;; Readers

(defun pueue--read-tasks (prompt initial-input history)
  "Reader for pueue task ids.
PROMPT, INITIAL-INPUT and HISTORY are the same as in
`completing-read'."
  (let* ((tasks (map-elt (pueue--status) "tasks"))
         (def (string-join (ignore-errors (pueue--id-args)) ","))
         (prompt (format-prompt prompt def))
         (completion-extra-properties
          (list :annotation-function
                (lambda (id)
                  (when-let ((task (map-elt crm-completion-table id)))
                    (concat "  -- " (map-elt task "command")))))))
    (completing-read-multiple prompt tasks nil t initial-input history def)))

(defun pueue--read-group (prompt &optional initial-input history)
  "Read pueue group name.
For PROMPT, INITIAL-INPUT and HISTORY see `completing-read'."
  (let* ((status (pueue--status))
         (groups (map-keys (map-elt status "groups")))
         (def (when-let ((id (ignore-errors (pueue--id-arg))))
                (map-nested-elt status (vector "tasks" id "group"))))
         (prompt (format-prompt prompt def)))
    (completing-read prompt groups nil t initial-input history def)))

;;;;; Formatters

(defun pueue--format-task (task)
  "Format TASK to string."
  (mapconcat
   (pcase-lambda ((seq key label fn))
     (concat (propertize label 'face 'pueue-label) ": "
             (funcall fn (map-elt task key))))
   [["id" "ID" number-to-string]
    ["command" "Command" identity]
    ["label" "Label" concat]
    ["path" "Path" identity]
    ["status" "Status" pueue--format-status]
    ["start" "Start" pueue--format-time]
    ["end" "End" pueue--format-time]
    ["group" "Group" identity]
    ["dependencies" "Dependencies" pueue--format-dependencies]
    ["prev_status" "Previous status" pueue--format-status]
    ["original_command" "Original command" identity]
    ["envs" "Environment variables" pueue--format-envs]]
   "\n"))

(defun pueue--format-envs (envs)
  "Format pueue task ENVS."
  (cl-labels (( format-var (var)
                (propertize var 'face 'pueue-environment-variable))
              ( format-env ((var . value))
                (concat (format-var var) "=" value)))
    (let ((envs (seq-sort-by #'car #'string< (map-pairs envs))))
      (concat "\n" (mapconcat #'format-env envs "\n")))))

(defun pueue--format-dependencies (dependencies)
  "Format pueue task DEPENDENCIES."
  (mapconcat
   (lambda (id) (button-buttonize (number-to-string id) #'pueue--draw-task id))
   dependencies " "))

(defun pueue--format-time (time)
  "Format TIME string."
  (condition-case nil
      (format-time-string "%F %T" (parse-iso8601-time-string time))
    (wrong-type-argument "")))

(defun pueue--format-status (status)
  "Format STATUS of pueue task."
  (pcase status
    ((pred stringp) status)
    ((pred mapp)
     (pcase (seq-first (map-pairs status))
       (`("Done" . ,result)
        (concat "Done " (pueue--format-result result)))
       (`("Stashed" . ,(map ("enqueue_at" enqueue-at)))
        (concat "Stashed " (pueue--format-time enqueue-at)))
       (`(,(and (pred stringp) status) . ,else)
        (format "%s %s" status else))
       (else (format "%s" else))))
    (else (format "%s" else))))

(defun pueue--format-result (result)
  "Format RESULT of pueue task."
  (pcase result
    ((pred stringp) result)
    ((pred mapp)
     (pcase (seq-first (map-pairs result))
       (`("Failed" . ,code)
        (concat "Failed " (number-to-string code)))
       (`("FailedToSpawn" . ,reason)
        (concat "FailedToSpawn " reason))
       (`(,(and (pred stringp) status) . ,else)
        (format "%s %s" status else))
       (else (format "%s" else))))
    (else (format "%s" else))))

(defun pueue--format-time-short (time)
  "Format TIME string, displaying only hours and minutes."
  (condition-case nil
      (format-time-string "%R" (parse-iso8601-time-string time))
    (wrong-type-argument "")))

(defun pueue--format-status-short (status)
  "Format STATUS of pueue task."
  (pcase status
    ((pred stringp) status)
    ((pred mapp)
     (pcase (seq-first (map-pairs status))
       (`("Done" . "Success") (propertize "Done" 'face 'pueue-success))
       (`("Done" . ,_) (propertize "Done" 'face 'pueue-error))
       (`(,(and (pred stringp) status) . ,_) status)
       (_ "")))
    (_ "")))

;;;; Footer

(provide 'pueue)
;;; pueue.el ends here
