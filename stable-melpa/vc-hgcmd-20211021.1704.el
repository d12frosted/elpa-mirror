;;; vc-hgcmd.el --- VC mercurial backend that uses hg command server -*- lexical-binding: t -*-

;; Copyright (C) 2018-2021 Free Software Foundation, Inc.

;; Author: Andrii Kolomoiets <andreyk.mad@gmail.com>
;; Keywords: vc
;; Package-Commit: d044448965d31ca8214f8bca48487e4d9b9d9a0f
;; URL: https://github.com/muffinmad/emacs-vc-hgcmd
;; Package-Version: 20211021.1704
;; Package-X-Original-Version: 1.14.1
;; Package-Requires: ((emacs "25.1"))

;; This file is NOT part of GNU Emacs.

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

;;; Commentary:

;; Functions implementation status
;;
;; FUNCTION NAME                                   STATUS
;; BACKEND PROPERTIES
;; * revision-granularity                          OK
;; - update-on-retrieve-tag                        OK
;; STATE-QUERYING FUNCTIONS
;; * registered (file)                             OK
;; * state (file)                                  OK
;; - dir-status-files (dir files update-function)  OK
;; - dir-extra-headers (dir)                       OK
;; - dir-printer (fileinfo)                        OK
;; - status-fileinfo-extra (file)                  OK
;; * working-revision (file)                       OK
;; * checkout-model (files)                        OK
;; - mode-line-string (file)                       OK
;; STATE-CHANGING FUNCTIONS
;; * create-repo (backend)                         OK
;; * register (files &optional comment)            OK
;; - responsible-p (file)                          OK
;; - receive-file (file rev)                       NO no specific actions
;; - unregister (file)                             OK
;; * checkin (files comment &optional rev)         OK
;; * find-revision (file rev buffer)               OK
;; * checkout (file &optional rev)                 OK
;; * revert (file &optional contents-done)         OK
;; - merge-file (file rev1 rev2)                   NO not needed
;; - merge-branch ()                               OK
;; - merge-news (file)                             NO not needed
;; - pull (prompt)                                 OK
;; - steal-lock (file &optional revision)          NO not needed
;; - modify-change-comment (files rev comment)     NO hg can modify only last comment
;; - mark-resolved (files)                         OK
;; - find-admin-dir (file)                         NO is this .hg dir?
;; HISTORY FUNCTIONS
;; * print-log (files buffer &optional shortlog start-revision limit)  OK
;; * log-outgoing (backend remote-location)        OK
;; * log-incoming (backend remote-location)        OK
;; - log-search (buffer pattern)                   OK
;; - log-view-mode ()                              OK
;; - show-log-entry (revision)                     OK
;; - comment-history (file)                        NO
;; - update-changelog (files)                      NO
;; * diff (files &optional rev1 rev2 buffer async) OK
;; - revision-completion-table (files)             OK branches and tags instead of revisions
;; - annotate-command (file buf &optional rev)     OK
;; - annotate-time ()                              OK
;; - annotate-current-time ()                      NO
;; - annotate-extract-revision-at-line ()          OK
;; - region-history (FILE BUFFER LFROM LTO)        OK experimental option "line-range" added in mercurial 4.4
;; - region-history-mode ()                        NO
;; - mergebase (rev1 &optional rev2)               TODO
;; TAG SYSTEM
;; - create-tag (dir name branchp)                 OK
;; - retrieve-tag (dir name update)                OK
;; MISCELLANEOUS
;; - make-version-backups-p (file)                 NO
;; - root (file)                                   OK
;; - ignore (file &optional directory)             OK find-ignore-file
;; - ignore-completion-table                       OK find-ignore-file
;; - previous-revision (file rev)                  OK
;; - next-revision (file rev)                      OK
;; - log-edit-mode ()                              OK
;; - check-headers ()                              NO
;; - delete-file (file)                            OK
;; - rename-file (old new)                         OK
;; - find-file-hook ()                             OK
;; - extra-menu ()                                 OK shelve, addremove
;; - extra-dir-menu ()                             OK extra-status-menu same as extra-menu
;; - conflicted-files (dir)                        OK with no respect to DIR
;; - repository-url (file-or-dir)                  OK
;;
;; VC backend to work with hg repositories through hg command server.
;; https://www.mercurial-scm.org/wiki/CommandServer
;;
;; The main advantage compared to vc-hg is speed.
;; Because communicating with hg over pipe is much faster than starting hg for each command.
;;
;; Also there are some other improvements and differences:
;;
;; - graph log is used for branch or root log
;;
;; - Conflict status for a file
;; Files with unresolved merge conflicts have appropriate status in `vc-dir'.
;; Also you can use `vc-find-conflicted-file' to find next file with unresolved merge conflict.
;; Files with resolved merge conflicts have extra file info in `vc-dir'.
;;
;; - hg summary as `vc-dir' extra headers
;; hg summary command gives useful information about commit, update and phase states.
;;
;; - Current branch is displayed on mode line.
;; It's not customizable yet.
;;
;; - Amend and close branch commits
;; While editing commit message you can toggle --amend and --close-branch flags.
;;
;; - Merge branch
;; vc-hgcmd will ask for branch name to merge.
;;
;; - Default pull arguments
;; You can customize default hg pull command arguments.
;; By default it's --update.  You can change it for particular pull by invoking `vc-pull' with prefix argument.
;;
;; - Branches and tags as revision completion table
;; Instead of list of all revisions of file vc-hgcmd provides list of named branches and tags.
;; It's very useful on `vc-retrieve-tag'.
;; You can specify -C to run hg update with -C flag and discard all uncommitted changes.
;;
;; - Filenames in vc-annotate buffer is omitted
;; They are mostly useless in annotate buffer.
;; To find out right filename to annotate vc-hgcmd uses `status --rev <rev> -C file'.
;;
;; - `previous-revision' and `next-revision' respect files
;; Keys `p' and `n' in annotation buffer works correctly.
;;
;; - Create tag
;; vc-hgcmd creates tag on `vc-create-tag'
;; If `vc-create-tag' is invoked with prefix argument then named branch will be created.
;;
;; - Predefined commit message
;; While committing merge changes commit message will be set to 'merged <branch>' if
;; different branch was merged or to 'merged <node>'.
;;
;; Additionally predefined commit message passed to custom function
;; `vc-hgcmd-log-edit-message-function' so one can change it.
;; For example, to include current task in commit message:
;;
;;     (defun my/hg-commit-message (original-message)
;;       (if org-clock-current-task
;;           (concat org-clock-current-task " " original-message)
;;         original-message))
;;
;;     (custom-set-variables
;;      '(vc-hgcmd-log-edit-message-function 'my/hg-commit-message))
;;
;; - Interactive command `vc-hgcmd-runcommand' that allow to run custom hg commands
;;
;; - It is possible to answer to hg questions, e.g. pick action during merge
;;
;; - Option to display shelves in `vc-dir'
;;
;; - View changes made by revision; diff to parents
;; Additional bindings in `log-view-mode':
;;  - `c c' view change made by revision at point (-c option to hg diff command)
;;  - `c 1' view diff between revision at point and its first parent
;;  - `c 2' view diff between revision at point and its second parent
;; `C c', `C 1' and `C 2' shows corresponding diffs for whole changeset.
;;
;; - View log for revset
;; Command `vc-hgcmd-print-log-revset' allows to print log for
;; revset, e.g. "branch(branch1) or branch(branch2)"

;;; Code:

(require 'bindat)
(require 'cl-lib)
(require 'diff-mode)
(require 'seq)
(require 'subr-x)
(require 'vc)
(require 'vc-dir)


;;;; Customization


(defgroup vc-hgcmd nil
  "Settings for VC mercurial commandserver backend."
  :group 'vc
  :prefix "vc-hgcmd-")

(defcustom vc-hgcmd-hg-executable "hg"
  "Hg executable."
  :type '(string))

(defcustom vc-hgcmd-cmdserver-config-options '("ui.interactive=True"
                                               "ui.editor=emacsclient -a emacs"
                                               "extensions.shelve=")
  "Config options for command server.
Specify options in form <option>=<value>.  It will be passed to hg with --config argument."
  :type '(repeat string))

(defcustom vc-hgcmd-cmdserver-process-environment nil
  "Environment variables for hg command server process."
  :type '(repeat string))

(defcustom vc-hgcmd-pull-args "--update"
  "Arguments for pull command.
This arguments will be used for each pull command.
You can edit this arguments for specific pull command by invoke `vc-pull' with prefix argument."
  :type '(string))

(defcustom vc-hgcmd-push-alternate-args "--new-branch"
  "Initial value for hg push arguments when asked."
  :type '(string))

(defcustom vc-hgcmd-log-edit-message-function nil
  "Function to return string that will be used as initial value for log edit.
First param will be commit message computed by backend: 'merged <branch>' if
named branch was merged to current branch or 'merged <node>' if two heads on
same branch was merged."
  :type '(choice
          (function)
          (const :tag "Default commit message" nil)))

(defcustom vc-hgcmd-dir-show-shelve t
  "Show current shelves in `vc-dir' buffer."
  :type '(boolean))

(defcustom vc-hgcmd-short-log-graph t
  "Use graph in short log."
  :type '(boolean))

(defcustom vc-hgcmd-short-log-format
  '("{rev}:{branch}: {author|person} {date|shortdate} {desc|firstline}\\n"
    "^\\(?:[-o@_x*+|: /\\]*\\)\\(%s\\):\\([^:]+\\): \\(.*?\\) \
\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\)"
    ((1 'log-view-message)
     (2 'change-log-file)
     (3 'change-log-name)
     (4 'change-log-date)))
  "Log template when viewing short log.
This should be a list (TEMPLATE REGEXP KEYWORDS), where TEMPLATE
is the \"--template\" argument string to pass to \"hg log\",
REGEXP is a regular expression matching the resulting
output, and KEYWORDS is a list of `font-lock-keywords' for
highlighting the Log View buffer.

REGEXP will be used to find revision with specific
number in log view, so write \"%s\" instead of \"[0-9]+\"
as revision number.

Note that revision number must be group 1."
  :type '(list string regexp (repeat sexp)))

(defcustom vc-hgcmd-checkin-switches t
  "A string or list of strings specifying extra switches for checkin.
These are passed to the \"hg commit\" command."
  :type '(choice (const :tag "Unspecified" nil)
                 (const :tag "None" t)
                 (string :tag "Argument String")
                 (repeat :tag "Argument List" :value ("") string)))

(defcustom vc-hgcmd-checkout-switches t
  "A string or list of strings specifying extra switches for checkout.
These are passed to the \"hg cat\" command."
  :type '(choice (const :tag "Unspecified" nil)
                 (const :tag "None" t)
                 (string :tag "Argument String")
                 (repeat :tag "Argument List" :value ("") string)))

(defcustom vc-hgcmd-register-switches t
  "A string or list of strings; extra switches for registering a file.
These are passed to the \"hg add\" command."
  :type '(choice (const :tag "Unspecified" nil)
                 (const :tag "None" t)
                 (string :tag "Argument String")
                 (repeat :tag "Argument List" :value ("") string)))

(defcustom vc-hgcmd-diff-switches t
  "A string or list of strings specifying switches for diff.
These are passed to the \"hg diff\" command."
  :type '(choice (const :tag "Unspecified" nil)
                 (const :tag "None" t)
                 (string :tag "Argument String")
                 (repeat :tag "Argument List" :value ("") string)))

(defcustom vc-hgcmd-annotate-switches t
  "A string or list of strings specifying switches for annotate.
These are passed to the \"hg annotate\" command."
  :type '(choice (const :tag "Unspecified" nil)
                 (const :tag "None" t)
                 (string :tag "Argument String")
                 (repeat :tag "Argument List" :value ("") string)))


;;;; Modes


(define-derived-mode vc-hgcmd-process-mode nil "Hgcmd process"
  "Major mode for hg cmdserver process"
  (hack-dir-local-variables-non-file-buffer)
  (set-buffer-multibyte nil)
  (setq
   buffer-undo-list t
   list-buffers-directory (abbreviate-file-name default-directory)
   buffer-read-only t))

(defvar vc-hgcmd-output-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map "g" nil)
    map))

(define-derived-mode vc-hgcmd-output-mode special-mode "Hgcmd output"
  "Major mode for hg output"
  (hack-dir-local-variables-non-file-buffer)
  (set (make-local-variable 'window-point-insertion-type) t)
  (setq
   buffer-undo-list t
   list-buffers-directory (abbreviate-file-name default-directory)))


;;;; cmdserver communication


(defvar vc-hgcmd--process-buffers-by-dir (make-hash-table :test #'equal))

(cl-defstruct (vc-hgcmd--command (:copier nil)) command output-buffer skip-error result-code wait callback callback-args)

(defvar-local vc-hgcmd--current-command nil
  "Current running hgcmd command.")
(put 'vc-hgcmd--current-command 'permanent-local t)

(defvar-local vc-hgcmd--encoding 'utf-8
  "Encoding that used for cmdserver communication.")
(put 'vc-hgcmd--encoding 'permanent-local t)

(defun vc-hgcmd--project-name (dir)
  "Get project name based on DIR."
  (file-name-nondirectory (directory-file-name dir)))

(defun vc-hgcmd--read-output ()
  "Parse process output in current buffer."
  ;; When some hg extension like hghooks 0.7.0 use 'print' then we will recieve output without channel.
  ;; So let's find '<channel><length>' pattern first and all output before it send to 'o' channel.
  ;; Suppose that length value will be less 2 ** 24 so there are always be \0 after channel.
  (goto-char 1)
  (when (search-forward-regexp "[oedrLI]\0\\(.\\|\n\\)\\{3\\}" nil t)
    (if (> (point) 6)
        (let ((data (decode-coding-string (buffer-substring-no-properties 1 (- (point) 5)) vc-hgcmd--encoding))
              (inhibit-read-only t))
          (delete-region 1 (- (point) 5))
          (cons ?o data))
      (let* ((data (bindat-unpack '((c byte) (d u32)) (buffer-substring-no-properties 1 6)))
             (channel (bindat-get-field data 'c))
             (size (bindat-get-field data 'd)))
        (cond ((memq channel '(?o ?e ?d ?r))
               (when (> (point-max) (+ 5 size))
                 (let ((data (buffer-substring-no-properties 6 (+ 6 size)))
                       (inhibit-read-only t))
                   (delete-region 1 (+ 6 size))
                   (cons channel (if (eq channel ?r)
                                     (bindat-get-field (bindat-unpack `((f u32)) data) 'f)
                                   (decode-coding-string data vc-hgcmd--encoding))))))
              ((memq channel '(?I ?L))
               (let ((inhibit-read-only t))
                 (delete-region 1 6))
               (cons channel size)))))))

(defun vc-hgcmd--data-for-tty (data)
  "Prepare binary DATA to be sent to tty process."
  (mapconcat #'identity (mapcar (lambda (c) (concat "\x16" (char-to-string c))) data) ""))

(defun vc-hgcmd--cmdserver-process-filter (process output)
  "Filter OUTPUT for hg cmdserver PROCESS.
Insert output to process buffer and check if amount of data is enought to parse it to output buffer."
  (let ((buffer (process-buffer process)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (goto-char (point-max))
        (let ((inhibit-read-only t)) (insert output))
        (let ((current-command (or vc-hgcmd--current-command
                                   (error "Hgcmd process output without command: %s" output))))
          (while
              (let ((data (vc-hgcmd--read-output)))
                (when data
                  (let ((channel (car data))
                        (data (cdr data)))
                    (cond ((memq channel '(?o ?e ?d))
                           (unless (and (eq channel ?e) (vc-hgcmd--command-skip-error current-command))
                             (let ((output-buffer (vc-hgcmd--command-output-buffer current-command)))
                               (when (or (stringp output-buffer) (buffer-live-p output-buffer))
                                 (with-current-buffer output-buffer
                                   (let ((inhibit-read-only t))
                                     (goto-char (point-max))
                                     (insert data)))))))
                          ((eq channel ?r)
                           (setf (vc-hgcmd--command-result-code current-command) data)
                           (setq vc-hgcmd--current-command nil)
                           (let ((output-buffer (vc-hgcmd--command-output-buffer current-command))
                                 (callback (vc-hgcmd--command-callback current-command))
                                 (args (vc-hgcmd--command-callback-args current-command)))
                             (when (or (stringp output-buffer) (buffer-live-p output-buffer))
                               (with-current-buffer output-buffer
                                 (setq mode-line-process nil)
                                 (when callback
                                   (if args (funcall callback args) (funcall callback)))))))
                          ((eq channel ?L)
                           (let ((output-buffer (vc-hgcmd--command-output-buffer current-command)))
                             (when (or (stringp output-buffer) (buffer-live-p output-buffer))
                               (display-buffer output-buffer)
                               (let ((tty (process-tty-name process))
                                     (answer (let ((inhibit-quit t))
                                               (prog1
                                                   (with-local-quit
                                                     (read-string "Hgcmd interactive input: "))
                                                 (setq quit-flag nil)))))
                                 (when answer
                                   (with-current-buffer output-buffer
                                     (let ((inhibit-read-only t))
                                       (goto-char (point-max))
                                       (insert answer "\n"))))
                                 (when (process-live-p process)
                                   (process-send-string
                                    process
                                    (let* ((to-send (when answer (concat (vc-hgcmd--encode-command-arg answer) "\n")))
                                           (binary-data (concat (bindat-pack '((l u32)) `((l . ,(length to-send)))) to-send)))
                                      (if tty
                                          (vc-hgcmd--data-for-tty binary-data)
                                        binary-data)))
                                   (when tty
                                     (process-send-eof process)))))))
                          ;; What is I channel for?
                          (t (error (format "Hgcmd unhandled channel %c" channel)))))
                  t))))))))

(defun vc-hgcmd--cmdserver-process-sentinel (process _event)
  "Will listen for PROCESS events and kill process buffer if process killed."
  (unless (process-live-p process)
    (let ((buffer (process-buffer process)))
      (when (buffer-live-p buffer)
        (with-current-buffer buffer
          (when vc-hgcmd--current-command
            ;; process has died but command waits for output
            (vc-hgcmd--cmdserver-process-filter process (bindat-pack
                                                         '((c byte) (l u32) (v u32))
                                                         '((c . ?r) (l . 4) (v . 255))))))
        (kill-buffer buffer)))))

(defun vc-hgcmd--repo-dir ()
  "Get repo dir."
  (abbreviate-file-name (or (vc-hgcmd-root default-directory) default-directory)))

(defun vc-hgcmd--process-buffer ()
  "Get hg cmdserver process buffer for repo in `default-directory'."
  (let ((dir (vc-hgcmd--repo-dir)))
    (or
     (let ((buffer (gethash dir vc-hgcmd--process-buffers-by-dir)))
       (when (buffer-live-p buffer) buffer))
     (puthash
      dir
      (with-current-buffer (generate-new-buffer (concat " *hgcmd process: " (vc-hgcmd--project-name dir) "*"))
        (setq default-directory dir)
        (vc-hgcmd-process-mode)
        (let* ((process-environment (append '("LANGUAGE=C") vc-hgcmd-cmdserver-process-environment process-environment))
               (process-connection-type nil)
               (process
                (condition-case nil
                    (apply
                     #'start-file-process
                     (concat "vc-hgcmd process: " (vc-hgcmd--project-name default-directory))
                     (current-buffer)
                     vc-hgcmd-hg-executable
                     (nconc (mapcan (lambda (option) (list "--config" option)) vc-hgcmd-cmdserver-config-options) (list "serve" "--cmdserver" "pipe")))
                  (error nil))))
          ;; process will be nil if hg executable not found
          (when (process-live-p process)
            (set-process-sentinel process #'ignore)
            (set-process-query-on-exit-flag process nil)
            (set-process-coding-system process 'no-conversion 'no-conversion)
            ;; read hello message
            ;; check process again because it can be tramp sh process with output like "env: hg not found"
            (let ((output (vc-hgcmd--read-output)))
              (while (and (process-live-p process) (or (not output) (not (string-prefix-p "capabilities: " (cdr output)))))
                (accept-process-output process 0.1 nil t)
                (setq output (vc-hgcmd--read-output)))
              (when (process-live-p process)
                (let* ((output (cdr output))
                       (encoding (when (string-match "\\bencoding: \\(.+\\)" output)
                                   (intern (downcase (match-string 1 output))))))
                  (when encoding
                    (setq vc-hgcmd--encoding (if (eq encoding 'ascii) 'us-ascii encoding))))
                (set-process-filter process #'vc-hgcmd--cmdserver-process-filter)
                (set-process-sentinel process #'vc-hgcmd--cmdserver-process-sentinel)))))
        (current-buffer))
      vc-hgcmd--process-buffers-by-dir))))

(defun vc-hgcmd--output-buffer (command)
  "Get and display hg output buffer for COMMAND."
  (let* ((dir (vc-hgcmd--repo-dir))
         (buffer
          (or (seq-find (lambda (buffer)
                          (with-current-buffer buffer
                            (and (eq major-mode 'vc-hgcmd-output-mode)
                                 (equal (abbreviate-file-name default-directory) dir))))
                        (buffer-list))
              (let ((buffer (generate-new-buffer (concat "*hgcmd output: " (vc-hgcmd--project-name dir) "*"))))
                (with-current-buffer buffer
                  (setq default-directory dir)
                  (vc-hgcmd-output-mode))
                buffer))))
    (let ((window (display-buffer buffer)))
      (with-current-buffer buffer
        (let ((inhibit-read-only t))
          (goto-char (point-max))
          (unless (eq (point) (point-min)) (insert "\f\n"))
          (set-window-start window (point))
          (insert (concat "Running \"" (mapconcat #'identity command " ") "\"...\n")))))
    buffer))

(defun vc-hgcmd--encode-command-arg (arg)
  "Encode command ARG."
  (encode-coding-string arg vc-hgcmd--encoding))

(defun vc-hgcmd--run-command (cmd)
  "Run hg CMD."
  (let* ((buffer (vc-hgcmd--process-buffer))
         (process (get-buffer-process buffer)))
    (with-current-buffer buffer
      (when vc-hgcmd--current-command
        (user-error "Hg command \"%s\" is active" (car (vc-hgcmd--command-command vc-hgcmd--current-command))))
      (when (process-live-p process)
        (let* ((tty (process-tty-name process))
               (command (vc-hgcmd--command-command cmd))
               (output-buffer (or (vc-hgcmd--command-output-buffer cmd)
                                  (setf (vc-hgcmd--command-output-buffer cmd) (vc-hgcmd--output-buffer command)))))
          (setq vc-hgcmd--current-command cmd)
          (when (or (stringp output-buffer) (buffer-live-p output-buffer))
            (with-current-buffer output-buffer
              (setq mode-line-process
                    (propertize (format " [running %s...]" (car command))
                                'face 'mode-line-emphasis
                                'help-echo
                                "A command is in progress in this buffer"))))
          (process-send-string
           process
           (concat
            "runcommand\n"
            (let* ((args (mapconcat #'vc-hgcmd--encode-command-arg
                                    (append '("--config" "ui.report_untrusted=0")
                                            command)
                                    "\0"))
                   (binary-data (bindat-pack '((l u32)) `((l . ,(length args))))))
              (concat (if tty
                          (vc-hgcmd--data-for-tty binary-data)
                        binary-data)
                      args))))
          (when tty
            (process-send-eof process)))
        (when (vc-hgcmd--command-wait cmd)
          (while vc-hgcmd--current-command
            (accept-process-output process 0.1 nil t)))
        t))))

(defun vc-hgcmd--command (skip-error &rest command)
  "Run hg COMMAND and return it's output.  If SKIP-ERROR is non nil data on error channel will be omited."
  (with-temp-buffer
    (let ((cmd (make-vc-hgcmd--command :command command :output-buffer (current-buffer) :wait t :skip-error skip-error)))
      (when (vc-hgcmd--run-command cmd)
        (let ((result (string-trim-right (buffer-string))))
          ;; TODO min result code for each command that is not error
          (if (= (vc-hgcmd--command-result-code cmd) 255)
              (with-current-buffer (vc-hgcmd--output-buffer command)
                (goto-char (point-max))
                (let ((inhibit-read-only t))
                  (insert (concat result "\n")))
                nil)
            (when (> (length result) 0)
              result)))))))

(defun vc-hgcmd-command (&rest command)
  "Run hg COMMAND and return it's output."
  (apply #'vc-hgcmd--command (nconc (list nil) command)))

(defun vc-hgcmd-command-to-buffer (buffer &rest command)
  "Send output of COMMAND to BUFFER and wait COMMAND to finish."
  (vc-setup-buffer buffer)
  (vc-hgcmd--run-command (make-vc-hgcmd--command :command command :output-buffer buffer :wait t)))

(defun vc-hgcmd--update-callback (buffer)
  "Update BUFFER where was command called from after command finished."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (cond
       ((derived-mode-p 'vc-dir-mode)
        (vc-dir-refresh))
       ((derived-mode-p 'dired-mode)
        (revert-buffer))))))

(defun vc-hgcmd-command-update-callback (command)
  "Run COMMAND and update current buffer after command finished."
  (vc-hgcmd--run-command
   (make-vc-hgcmd--command
    :command command
    :callback #'vc-hgcmd--update-callback
    :callback-args (current-buffer))))

(defconst vc-hgcmd--translation-status '((?C . up-to-date)
                                         (?= . up-to-date)
                                         (?A . added)
                                         (?I . ignored)
                                         (?R . removed)
                                         (?! . missing)
                                         (?? . unregistered)
                                         (?M . edited)
                                         (?\s . origin))
  "Translation for status command output.")

(defconst vc-hgcmd--translation-resolve '((?U . conflict)
                                          (?R . edited))
  "Translation for resolve command output.")

(defun vc-hgcmd--branches ()
  "Return branches list."
  (split-string (vc-hgcmd-command "branches" "-q") "\n"))

(defun vc-hgcmd--tags ()
  "Return tags list."
  (split-string (vc-hgcmd-command "tags" "-q") "\n"))

(defun vc-hgcmd--parents (template &optional revision)
  "Return parents of REVISION formatted by TEMPLATE string."
  (let* ((revision (or revision ""))
         (parents (vc-hgcmd-command
                   "log"
                   "-r"
                   (format "p1(%s)+p2(%s)" revision revision)
                   "--template"
                   (concat template "\\n"))))
    (when parents (split-string parents "\n"))))

(defun vc-hgcmd--file-relative-name (file)
  "Return FILE file name relative to vc root."
  (file-relative-name file (vc-hgcmd-root file)))


;;;; VC backend


(autoload 'vc-switches "vc")

(defun vc-hgcmd--switches (operation)
  "Return switch list for OPERATION."
  (let ((switches (vc-switches 'hgcmd operation)))
    (when switches
      (mapcan #'split-string-and-unquote switches))))

(defun vc-hgcmd-revision-granularity ()
  "Per-repository revision number."
  'repository)

(defun vc-hgcmd-update-on-retrieve-tag ()
  "No buffers update on retrieve tag."
  nil)

;;;###autoload (defun vc-hgcmd-registered (file)
;;;###autoload   (when (vc-find-root file ".hg")
;;;###autoload     (load "vc-hgcmd" nil t)
;;;###autoload     (vc-hgcmd-registered file)))

(defun vc-hgcmd-registered (file)
  "Is file FILE is registered."
  (when (vc-hgcmd-root file)
    (or (file-directory-p file)
        ;; vc-registered is called for buffer-file-name and
        ;; shortly then after for truename. Update default-dir so
        ;; 'hg state' will be called in right repo
        (let ((state
               (let ((default-directory (file-name-directory (expand-file-name file))))
                 (vc-hgcmd-state file))))
          (and state (not (memq state '(ignored unregistered))))))))

(defun vc-hgcmd-state (file)
  "State for FILE."
  (let ((out (vc-hgcmd--command t "status" "-A" (vc-hgcmd--file-relative-name file))))
    (when out
      (let ((state (cdr (assoc (aref out 0) vc-hgcmd--translation-status))))
        (if (and (eq state 'edited) (vc-hgcmd--file-unresolved-p file))
            'conflict
          state)))))

(cl-defstruct (vc-hgcmd-extra-fileinfo
               (:copier nil)
               (:constructor vc-hgcmd-create-extra-fileinfo (status &optional origin))
               (:conc-name vc-hgcmd-extra-fileinfo->))
  status ;; copied, renamed or resolved
  origin ;; origin file in case copied or renamed
  )

(defun vc-hgcmd-dir-printer (info)
  "Pretty print INFO."
  (vc-default-dir-printer 'Hgcmd info)
  (let ((extra (vc-dir-fileinfo->extra info)))
    (when extra
      (insert (propertize
               (format "   (%s)"
                       (pcase (vc-hgcmd-extra-fileinfo->status extra)
                         ('resolved "resolved conflict")
                         ('copied (format "copied from %s" (vc-hgcmd-extra-fileinfo->origin extra)))
                         ('renamed-from (format "renamed from %s" (vc-hgcmd-extra-fileinfo->origin extra)))
                         ('renamed-to (format "renamed to %s" (vc-hgcmd-extra-fileinfo->origin extra)))))
               'face 'font-lock-comment-face)))))

(defun vc-hgcmd--dir-status-callback (update-function)
  "Call UPDATE-FUNCTION with result of status command."
  (let* ((conflicted (vc-hgcmd-conflicted-files))
         (result (mapcar (lambda (file)
                           (list (car file) (cdr file) (when (eq (cdr file) 'edited) (vc-hgcmd-create-extra-fileinfo 'resolved))))
                         conflicted))
         (conflicted (mapcar #'car conflicted)))
    (goto-char (point-min))
    (while (not (eobp))
      (let ((status (cdr (assoc (char-after) vc-hgcmd--translation-status))))
        (when status
          (let ((file (buffer-substring-no-properties (+ (point) 2) (line-end-position))))
            (unless (or (member file conflicted) (eq status 'origin))
              (push (list
                     file
                     status
                     (pcase status
                       ('added (save-excursion
                                 (forward-line)
                                 (when (and (point-at-bol)
                                            (eq 'origin (cdr (assoc (char-after) vc-hgcmd--translation-status))))
                                   (let ((origin (buffer-substring-no-properties (+ (point) 2) (line-end-position))))
                                     (vc-hgcmd-create-extra-fileinfo
                                      (if (re-search-forward (concat "^R " (regexp-quote origin) "$") nil t)
                                          'renamed-from
                                        'copied)
                                      origin)))))
                       ('removed (save-excursion
                                   (when (re-search-backward (concat "^  " (regexp-quote file) "$") nil t)
                                     (forward-line -1)
                                     (vc-hgcmd-create-extra-fileinfo
                                      'renamed-to
                                      (buffer-substring-no-properties (+ (point) 2) (line-end-position))))))))
                    result)))))
      (forward-line))
    (funcall update-function result)))

(defun vc-hgcmd-dir-status-files (dir files update-function)
  "Call UPDATE-FUNCTION with status for files in DIR or FILES."
  (let ((command (if files
                     (nconc (list "status" "-A") (mapcar #'vc-hgcmd--file-relative-name files))
                   (list "status" "-C" (vc-hgcmd--file-relative-name dir)))))
    (vc-hgcmd--run-command
     (make-vc-hgcmd--command
      :command command
      :output-buffer (current-buffer)
      :callback #'vc-hgcmd--dir-status-callback
      :callback-args update-function
      :skip-error t))))

(defvar vc-hgcmd-extra-menu-map
  (let ((map (make-sparse-keymap)))
    (define-key map [hgcmd-sl]
      '(menu-item "Create shelve..." vc-hgcmd-shelve
                  :help "Shelve changes"))
    (define-key map [hgcmd-uc]
      '(menu-item "Continue unshelve" vc-hgcmd-shelve-unshelve-continue
                  :help "Continue unshelve"))
    (define-key map [hgcmd-ua]
      '(menu-item "Abort unshelve" vc-hgcmd-shelve-unshelve-abort
                  :help "Abort unshelve"))
    (define-key map [hgcmd-ar]
      '(menu-item "Addremove" vc-hgcmd-addremove
                  :help "Add new and remove missing files"))
    map))

(defun vc-hgcmd-extra-menu ()
  "Return a menu keymap with additional hg commands."
  vc-hgcmd-extra-menu-map)

(defun vc-hgcmd-extra-status-menu ()
  "Return a menu keymap with additional hg commands."
  vc-hgcmd-extra-menu-map)

(defvar vc-hgcmd-shelve-map
  (let ((map (make-sparse-keymap)))
    ;; Turn off vc-dir marking
    (define-key map [mouse-2] 'ignore)

    (define-key map [down-mouse-3] #'vc-hgcmd-shelve-menu)
    (define-key map "\C-k" #'vc-hgcmd-shelve-delete-at-point)
    (define-key map "=" #'vc-hgcmd-shelve-show-at-point)
    (define-key map "\C-m" #'vc-hgcmd-shelve-show-at-point)
    (define-key map "A" 'vc-hgcmd-shelve-apply-at-point)
    (define-key map "P" 'vc-hgcmd-shelve-pop-at-point)
    map))

(defvar vc-hgcmd-shelve-menu-map
  (let ((map (make-sparse-keymap "Hg shelve")))
    (define-key map [de]
      '(menu-item "Delete shelve" vc-hgcmd-shelve-delete-at-point
                  :help "Delete the current shelve"))
    (define-key map [ap]
      '(menu-item "Unshelve and keep shelve" vc-hgcmd-shelve-apply-at-point
                  :help "Apply the current shelve and keep it in the shelve list"))
    (define-key map [po]
      '(menu-item "Unshelve and remove shelve" vc-hgcmd-shelve-pop-at-point
                  :help "Apply the current shelve and remove it"))
    (define-key map [sh]
      '(menu-item "Show shelve" vc-hgcmd-shelve-show-at-point
                  :help "Show the contents of the current shelve"))
    map))

(defun vc-hgcmd-dir-extra-headers (_dir)
  "Return summary command for DIR output as dir extra headers."
  (concat
   (with-temp-buffer
     (when (vc-hgcmd--run-command (make-vc-hgcmd--command :command (list "summary") :output-buffer (current-buffer) :wait t))
       (mapconcat
        #'identity
        (let (result)
          (goto-char (point-min))
          (while (not (eobp))
            (push
             (let ((entry (if (looking-at "\\([^ ].*\\):\\s-+\\(.*\\)")
                              (cons (capitalize (match-string 1)) (match-string 2))
                            (cons "" (buffer-substring (point) (line-end-position))))))
               (concat
                (propertize (format "%-11s: " (car entry)) 'face 'font-lock-type-face)
                (propertize (cdr entry) 'face 'font-lock-variable-name-face)))
             result)
            (forward-line))
          (nreverse result))
        "\n")))
   (when vc-hgcmd-dir-show-shelve
     (let ((shelves (vc-hgcmd-shelve-list)))
       (when shelves
         (concat
          "\n"
          (propertize "Shelve     :\n" 'face 'font-lock-type-face)
          (with-temp-buffer
            (when (vc-hgcmd--run-command (make-vc-hgcmd--command :command (list "shelve" "-l") :output-buffer (current-buffer) :wait t))
              (goto-char (point-min))
              (mapconcat
               (lambda (shelve)
                 (prog1
                     (propertize
                      (concat
                       "             "
                       (propertize shelve 'face 'font-lock-variable-name-face)
                       (propertize
                        (replace-regexp-in-string
                         (concat "^" (regexp-quote shelve) "\s*")
                         "   "
                         (buffer-substring-no-properties (line-beginning-position) (line-end-position)))
                        'face 'font-lock-comment-face))
                      'mouse-face 'highlight
                      'help-echo "mouse-3: Show shelve menu\nRET: Show shelve\nA: Unshelve and keep\nP: Unshelve and remove\nC-k: Delete shelve"
                      'keymap vc-hgcmd-shelve-map
                      'vc-hgcmd--shelve-name shelve)
                   (forward-line)))
               shelves "\n")))))))))

(defun vc-hgcmd-shelve-list ()
  "Return shelve list."
  (let ((shelves (vc-hgcmd-command "shelve" "-l" "-q")))
    (when shelves (split-string shelves "\n"))))

(defun vc-hgcmd-shelve-name-at-point ()
  "Return shelve name at point."
  (or (get-text-property (point) 'vc-hgcmd--shelve-name)
      (error "Cannot find shelve at point")))

(defun vc-hgcmd-shelve-delete-at-point ()
  "Delete shelve at point."
  (interactive)
  (let ((shelve (vc-hgcmd-shelve-name-at-point)))
    (when (y-or-n-p (format "Delete shelve %s? " shelve))
      (vc-hgcmd-command "shelve" "-d" shelve)
      (vc-dir-refresh))))

(defun vc-hgcmd-shelve-read (prompt)
  "Read shelve name with PROMPT."
  (let ((name (completing-read prompt (letrec ((table (lazy-completion-table table (lambda () (vc-hgcmd-shelve-list)))))) nil t)))
    (when (not (string-equal "" name))
      name)))

(defun vc-hgcmd-shelve-apply (name)
  "Unshelve and keep shelve with NAME."
  (interactive (list (vc-hgcmd-shelve-read "Apply and keep shelve: ")))
  (when name
    (vc-hgcmd-command "unshelve" "-k" name)
    (vc-dir-refresh)))

(defun vc-hgcmd-shelve-apply-at-point ()
  "Unshelve and keep shelve at point."
  (interactive)
  (vc-hgcmd-shelve-apply (vc-hgcmd-shelve-name-at-point)))

(defun vc-hgcmd-shelve-pop (name)
  "Unshelve and remove shelve with NAME."
  (interactive (list (vc-hgcmd-shelve-read "Apply and remove shelve: ")))
  (when name
    (vc-hgcmd-command "unshelve" name)
    (vc-dir-refresh)))

(defun vc-hgcmd-shelve-pop-at-point ()
  "Unshelve and remove shelve at point."
  (interactive)
  (vc-hgcmd-shelve-pop (vc-hgcmd-shelve-name-at-point)))

(defun vc-hgcmd-shelve-show-at-point ()
  "Show shelve at point."
  (interactive)
  (let ((shelve (vc-hgcmd-shelve-name-at-point))
        (buffer (get-buffer-create "*vc-hgcmd-shelve*")))
    (vc-setup-buffer buffer)
    (with-current-buffer
        (when (vc-hgcmd--run-command (make-vc-hgcmd--command :command (list "shelve" "-p" shelve) :output-buffer (current-buffer) :wait t))
          (diff-mode)
          (setq buffer-read-only t)
          (pop-to-buffer (current-buffer))))))

(defun vc-hgcmd-shelve (name)
  "Create shelve named NAME."
  (interactive "sShelve name: ")
  (if (string-equal "" name)
      (vc-hgcmd-command "shelve")
    (vc-hgcmd-command "shelve" "-n" name))
  (vc-dir-refresh))

(defun vc-hgcmd-shelve-unshelve-continue ()
  "Continue unshelve."
  (interactive)
  (vc-hgcmd-command "unshelve" "--continue")
  (vc-dir-refresh))

(defun vc-hgcmd-shelve-unshelve-abort ()
  "Abort unshelve."
  (interactive)
  (vc-hgcmd-command "unshelve" "--abort")
  (vc-dir-refresh))

(defun vc-hgcmd-shelve-menu (event)
  "Popup shelve menu on EVENT."
  (interactive "e")
  (vc-dir-at-event event (popup-menu vc-hgcmd-shelve-menu-map event)))

(defun vc-hgcmd-addremove ()
  "Add new and remove missing files."
  (interactive)
  (vc-hgcmd-command "addremove")
  (vc-dir-refresh))

(defun vc-hgcmd-working-revision (file)
  "Working revision of FILE.  Result is revision of FILE up to repository revision."
  (let* ((reporev (car-safe (split-string (vc-hgcmd-command "id" "-n") "+")))
         (filerev (when file
                    (vc-hgcmd-command
                     "log"
                     "-r" (format "limit(reverse(follow('%s') and ..%s), 1)"
                                  (vc-hgcmd--file-relative-name file)
                                  reporev)
                     "--template" "{rev}"))))
    (or filerev reporev)))

(defun vc-hgcmd-checkout-model (_files)
  "Files are always writable."
  'implicit)

(defun vc-hgcmd-mode-line-string (file)
  "Return a string for `vc-mode-line' to put in the mode line for FILE."
  (let* ((state (vc-state file))
         (state-echo nil)
         (face nil)
         ;; TODO allow to customize it.
         (branch (vc-hgcmd-command "branch")))
    (propertize
     (concat
      "Hgcmd"
      (cond
       ((eq state 'up-to-date)
        (setq state-echo "Up to date file")
        (setq face 'vc-up-to-date-state)
        "-")
       ((eq state 'added)
        (setq state-echo "Locally added file")
        (setq face 'vc-locally-added-state)
        "@")
       ((eq state 'conflict)
        (setq state-echo "File contains conflicts after the last merge")
        (setq face 'vc-conflict-state)
        "!")
       ((eq state 'removed)
        (setq state-echo "File removed from the VC system")
        (setq face 'vc-removed-state)
        "!")
       ((eq state 'missing)
        (setq state-echo "File tracked by the VC system, but missing from the file system")
        (setq face 'vc-missing-state)
        "?")
       (t
        (setq state-echo "Locally modified file")
        (setq face 'vc-edited-state)
        ":"))
      branch)
     'face face
     'help-echo (concat state-echo " under the Hg version control system"))))

(defun vc-hgcmd-create-repo ()
  "Init Hg repository."
  (vc-hgcmd-command "init"))

;; TODO vc switches

(defun vc-hgcmd-register (files &optional _comment)
  "Register FILES."
  (apply #'vc-hgcmd-command (nconc
                             (list "add")
                             (vc-hgcmd--switches 'register)
                             (mapcar #'vc-hgcmd--file-relative-name files))))

(defalias 'vc-hgcmd-responsible-p 'vc-hgcmd-root)

(defun vc-hgcmd-unregister (file)
  "Forget FILE."
  (vc-hgcmd-command "forget" (vc-hgcmd--file-relative-name file)))

(declare-function log-edit-extract-headers "log-edit" (headers string))
(declare-function log-edit-toggle-header "log-edit" (header value))
(declare-function log-edit-set-header "log-edit" (header value &optional toggle))

(defun vc-hgcmd--arg-close-branch (value)
  "If VALUE is yes then --close-branch."
  (when (equal "yes" value) (list "--close-branch")))

(defun vc-hgcmd--arg-amend (value)
  "If VALUE is yes then --close-branch."
  (when (equal "yes" value) (list "--amend")))

(defun vc-hgcmd-checkin (files comment &optional _rev)
  "Commit FILES with COMMENT."
  (apply #'vc-hgcmd-command
         (nconc
          (list "commit")
          (vc-hgcmd--switches 'checkin)
          (list "-m")
          (log-edit-extract-headers `(("Author" . "--user")
                                      ("Date" . "--date")
                                      ("Amend" . vc-hgcmd--arg-amend)
                                      ("Close-branch" . vc-hgcmd--arg-close-branch))
                                    comment)
          (mapcar #'vc-hgcmd--file-relative-name files))))

(defun vc-hgcmd-find-revision (file rev buffer &optional args)
  "Put REV of FILE to BUFFER.
Optional ARGS passed to the \"cat\" command."
  (let ((file (vc-hgcmd--file-relative-name file)))
    (apply #'vc-hgcmd-command-to-buffer buffer
           (if rev
               (nconc
                (list "cat")
                args
                (list "-r" rev)
                (vc-hgcmd--file-name-at-rev (list file) rev))
             (nconc '("cat") args (list file))))))

(defun vc-hgcmd-checkout (file &optional rev)
  "Retrieve revision REV of FILE."
  (vc-hgcmd-find-revision file rev
                          (or (get-file-buffer file) (current-buffer))
                          (vc-hgcmd--switches 'checkout)))

(defun vc-hgcmd-revert (file &optional contents-done)
  "Revert FILE if not CONTENTS-DONE."
  (unless contents-done
    (vc-hgcmd-command "revert" (vc-hgcmd--file-relative-name file))))

(defun vc-hgcmd-merge-branch ()
  "Merge."
  (let ((branch (vc-read-revision "Revision to merge: ")))
    (vc-hgcmd-command-update-callback
     (if (> (length branch) 0)
         (list "merge" branch)
       (list "merge")))))

(defun vc-hgcmd-pull (prompt)
  "Pull.  Prompt for args if PROMPT."
  (vc-hgcmd-command-update-callback
   (nconc
    (list "pull")
    (split-string-and-unquote (if prompt (read-from-minibuffer "Hg pull: " vc-hgcmd-pull-args) vc-hgcmd-pull-args)))))

(defun vc-hgcmd-push (prompt)
  "Pull.  Prompt for args if PROMPT."
  (vc-hgcmd-command-update-callback
   (nconc
    (list "push")
    (when prompt (split-string-and-unquote (read-from-minibuffer "Hg push: " vc-hgcmd-push-alternate-args))))))

(defun vc-hgcmd-mark-resolved (files)
  "Mark FILES resolved."
  (apply #'vc-hgcmd-command (nconc (list "resolve" "-m") (mapcar #'vc-hgcmd--file-relative-name files))))

(defvar vc-hgcmd--print-log-revset nil)

(defun vc-hgcmd-print-log (files buffer &optional shortlog start-revision limit)
  "Put maybe SHORTLOG log of FILES to BUFFER starting with START-REVISION limited by LIMIT."
  (let ((command
         (nconc
          (list "log")
          (when shortlog
            `(,@(when vc-hgcmd-short-log-graph '("-G"))
              "--template" ,(car vc-hgcmd-short-log-format)))
          (when start-revision
            ;; start revision is used for branch log or specific revision log when limit is 1
            (list (if (or vc-hgcmd--print-log-revset (eq limit 1)) "-r" "-b") start-revision))
          (when limit (list "-l" (number-to-string limit)))
          ;; file list not needed if limit is 1
          (unless (eq limit 1)
            (nconc
             (unless shortlog (list "-f")) ; follow file renames
             (unless (equal files (list default-directory)) (mapcar #'vc-hgcmd--file-relative-name files))))
          (when (eq vc-log-view-type 'with-diff) (list "-p"))))
        ;; If limit is 1 or vc-log-show-limit then it is initial diff and better move to working revision
        ;; otherwise remember point position and restore it later
        (p (unless (or (member limit (list 1 vc-log-show-limit)))
             (with-current-buffer buffer (point)))))
    (apply #'vc-hgcmd-command-to-buffer buffer command)
    (with-current-buffer buffer
      (if p
          (goto-char p)
        (unless start-revision (vc-hgcmd-show-log-entry nil))))))

(defun vc-hgcmd-print-log-revset (revset)
  "Show the change log for REVSET."
  (interactive "sRevset to log: ")
  (when (string-blank-p revset)
    (user-error "No revset specified"))
  (let ((vc-hgcmd--print-log-revset t))
    (vc-print-log-internal
     'Hgcmd
     (list default-directory)
     revset
     t
     (when (> vc-log-show-limit 0) vc-log-show-limit))))

(defun vc-hgcmd--log-in-or-out (type buffer remote-location)
  "Log TYPE changesets for REMOTE-LOCATION to BUFFER."
  (apply #'vc-hgcmd-command-to-buffer buffer type (unless (string= "" remote-location) remote-location)))


(defun vc-hgcmd-log-outgoing (buffer remote-location)
  "Log outgoing for REMOTE-LOCATION to BUFFER."
  (vc-hgcmd--log-in-or-out "outgoing" buffer remote-location))

(defun vc-hgcmd-log-incoming (buffer remote-location)
  "Log incoming from REMOTE-LOCATION to BUFFER."
  (vc-hgcmd--log-in-or-out "incoming" buffer remote-location))

(defun vc-hgcmd-log-search (buffer pattern)
  "Search the change log for keyword PATTERN and output results into BUFFER.

PATTERN is passed as argument to 'hg log -k' command.

With prefix argument, ask for 'log' command arguments."
  (let ((args (if current-prefix-arg
                  (split-string-and-unquote
                   (read-shell-command
                    "Search log with command 'hg log': "
                    "-k "))
                (list "-k" pattern))))
    (apply #'vc-hgcmd-command-to-buffer buffer (nconc (list "log") args))))

(defconst vc-hgcmd--message-re "^changeset:\\s-*\\(%s\\):\\([[:xdigit:]]+\\)")
(defvar log-view-per-file-logs)
(defvar log-view-message-re)
(defvar log-view-font-lock-keywords)
(defvar log-view-vc-backend)
(defvar log-view-vc-fileset)
(defvar log-view-expanded-log-entry-function)

(defvar vc-hgcmd-log-view-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "c c") 'vc-hgcmd-diff-revision)
    (define-key map (kbd "c 1") 'vc-hgcmd-diff-parent1)
    (define-key map (kbd "c 2") 'vc-hgcmd-diff-parent2)
    (define-key map (kbd "C c") 'vc-hgcmd-diff-revision-changeset)
    (define-key map (kbd "C 1") 'vc-hgcmd-diff-parent1-changeset)
    (define-key map (kbd "C 2") 'vc-hgcmd-diff-parent2-changeset)
    map))

(define-derived-mode vc-hgcmd-log-view-mode log-view-mode "Log-View/Hgcmd"
  (require 'add-log)
  (set (make-local-variable 'log-view-per-file-logs) nil)
  (set (make-local-variable 'log-view-message-re)
       (format (if (eq vc-log-view-type 'short)
                   (cadr vc-hgcmd-short-log-format)
                 vc-hgcmd--message-re)
               "[[:digit:]]+"))
  (when (eq vc-log-view-type 'short)
    (set (make-local-variable 'log-view-expanded-log-entry-function)
         #'vc-hgcmd-expanded-log-entry))
  (set (make-local-variable 'log-view-font-lock-keywords)
       (if (eq vc-log-view-type 'short)
           (list (cons (format (nth 1 vc-hgcmd-short-log-format) "[[:digit:]]+")
                       (nth 2 vc-hgcmd-short-log-format)))
         (append
          log-view-font-lock-keywords
          '(
            ("user:[ \t]+\\([^<(]+?\\)[ \t]*[(<]\\([A-Za-z0-9_.+-]+@[A-Za-z0-9_.-]+\\)[>)]"
             (1 'change-log-name)
             (2 'change-log-email))
            ("user:[ \t]+\\([A-Za-z0-9_.+-]+\\(?:@[A-Za-z0-9_.-]+\\)?\\)"
             (1 'change-log-email))
            ("date: \\(.+\\)" (1 'change-log-date))
            ("parent:[ \t]+\\([[:digit:]]+:[[:xdigit:]]+\\)" (1 'change-log-acknowledgment))
            ("tag: +\\([^ ]+\\)$" (1 'highlight))
            ("summary:[ \t]+\\(.+\\)" (1 'log-view-message)))))))

(defun vc-hgcmd-show-log-entry (revision)
  "Show log entry positioning on REVISION."
  ;; REVISION might be branch name while print-branch-log
  ;; if 'changeset: revision' not found try move to working rev but return nil
  ;; because revision is not found
  (goto-char (point-min))
  (let ((re (if (eq vc-log-view-type 'short)
                (cadr vc-hgcmd-short-log-format)
              vc-hgcmd--message-re)))
    (if (search-forward-regexp (format re revision) nil t)
        (goto-char (match-beginning 0))
      (when (search-forward-regexp (format re (vc-hgcmd-working-revision nil)) nil t)
        (goto-char (match-beginning 0))
        nil))))

(defun vc-hgcmd-expanded-log-entry (revision)
  "Show log entry for REVISION."
  (concat (vc-hgcmd-command "log" "-v" "-r" revision) "\n"))

(declare-function log-view-current-tag "log-view" (&optional pos))

(defun vc-hgcmd--diff-revision (pos files)
  "Show change made by revision at POS for FILES.  If FILES is nil show diff for whole changeset."
  (vc-diff-internal t (list log-view-vc-backend files) nil (log-view-current-tag pos)))

(defun vc-hgcmd-diff-revision (pos)
  "Show change made by revision at POS."
  (interactive "d")
  (vc-hgcmd--diff-revision pos log-view-vc-fileset))

(defun vc-hgcmd-diff-revision-changeset (pos)
  "Show change made by revison at POS in whole changeset."
  (interactive "d")
  (vc-hgcmd--diff-revision pos nil))

(defun vc-hgcmd--diff-parent (pos parent-fn files)
  "Show diff for changeset at POS and parent retrieved by PARENT-FN for FILES.
PARENT-FN is called with `vc-hgcmd--parents' result as an argument.
If FILES is nil show diff for whole changeset."
  (let* ((to (log-view-current-tag pos))
         (fr (funcall parent-fn (vc-hgcmd--parents "{rev}" to))))
    (unless fr
      (user-error "Revision %s has no such parent" to))
    (vc-diff-internal t (list log-view-vc-backend files) fr to)))

(defun vc-hgcmd-diff-parent1 (pos)
  "Show diff between revision at POS and parent 1."
  (interactive "d")
  (vc-hgcmd--diff-parent pos 'car log-view-vc-fileset))

(defun vc-hgcmd-diff-parent2 (pos)
  "Show diff between revision at POS and parent 2."
  (interactive "d")
  (vc-hgcmd--diff-parent pos 'cadr log-view-vc-fileset))

(defun vc-hgcmd-diff-parent1-changeset (pos)
  "Show diff between revision at POS and parent 1 in whole changeset."
  (interactive "d")
  (vc-hgcmd--diff-parent pos 'car nil))

(defun vc-hgcmd-diff-parent2-changeset (pos)
  "Show diff between revision at POS and parent 2 in whole changeset."
  (interactive "d")
  (vc-hgcmd--diff-parent pos 'cadr nil))

(defun vc-hgcmd-diff (files &optional rev1 rev2 buffer _async)
  "Place diff of FILES between REV1 and REV2 into BUFFER."
  (let ((command (nconc
                  (list "diff")
                  (vc-hgcmd--switches 'diff)
                  (when rev1 (list "-r" rev1))
                  (when rev2 (list (if rev1 "-r" "-c") rev2))
                  (when (and files (not (equal files (list default-directory))))
                    (let ((files (mapcar #'vc-hgcmd--file-relative-name files)))
                      (if rev2 (vc-hgcmd--file-name-at-rev files rev2) files))))))
    (apply #'vc-hgcmd-command-to-buffer buffer command)))

(defun vc-hgcmd-revision-completion-table (&optional _files)
  "Return branches and tags as they are more usefull than file revisions."
  (letrec ((table (lazy-completion-table table (lambda () (nconc (list "") (vc-hgcmd--branches) (vc-hgcmd--tags))))))))

(defconst vc-hgcmd-annotate-re
  (concat
   "^\\(?: *[^ ]+ +\\)?\\([0-9]+\\) "
   "\\([0-9]\\{4\\}-[0-1][0-9]-[0-3][0-9]\\)[^:]*: "))

(defun vc-hgcmd--file-name-at-rev (files rev)
  "Return filename of FILES at REV."
  (when files
    (or (with-temp-buffer
          (when (vc-hgcmd--run-command (make-vc-hgcmd--command :command (nconc (list "status" "--rev" rev "-C") files) :output-buffer (current-buffer) :wait t))
            (goto-char (point-min))
            (let (result)
              (while (not (eobp))
                (unless (save-excursion
                          (forward-line)
                          (and (point-at-bol) (eq (char-after) ?\s)))
                  (push (buffer-substring-no-properties (+ (point) 2) (line-end-position)) result))
                (forward-line))
              result)))
        files)))

(defun vc-hgcmd-annotate-command (file buffer &optional revision)
  "Annotate REVISION of FILE to BUFFER."
  (apply #'vc-hgcmd-command-to-buffer buffer
         (nconc
          (list "annotate")
          (vc-hgcmd--switches 'annotate)
          (list "-qdnu")
          (when revision (list "-r" revision))
          (vc-hgcmd--file-name-at-rev (list (vc-hgcmd--file-relative-name file)) revision))))

(declare-function vc-annotate-convert-time "vc-annotate" (&optional time))

(defun vc-hgcmd-annotate-time ()
  "Return the time of the next line of annotation at or after point, as a floating point fractional number of days."
  (when (looking-at vc-hgcmd-annotate-re)
    (goto-char (match-end 0))
    (vc-annotate-convert-time
     (let ((str (match-string-no-properties 2)))
       (encode-time 0 0 0
                    (string-to-number (substring str 6 8))
                    (string-to-number (substring str 4 6))
                    (string-to-number (substring str 0 4)))))))

(defun vc-hgcmd-annotate-extract-revision-at-line ()
  "Return revision at line."
  (save-excursion
    (beginning-of-line)
    (when (looking-at vc-hgcmd-annotate-re)
      (match-string-no-properties 1))))

(defun vc-hgcmd-region-history(file buffer lfrom lto)
  "Insert into BUFFER the history of the content of FILE between lines LFROM and LTO."
  (when (vc-hgcmd-command-to-buffer
         buffer
         "log" "-fpL" (format "%s,%d:%d" (vc-hgcmd--file-relative-name file) lfrom lto))
    (with-current-buffer buffer
      (goto-char (point-min)))
    (select-window (display-buffer buffer))))

(defvar vc-hgcmd--log-view-region-history-font-lock-keywords nil)
(defvar font-lock-keywords)
(defvar vc-hgcmd-region-history-font-lock-keywords '((vc-hgcmd-region-history-font-lock)))

(defun vc-hgcmd-region-history-font-lock (limit)
  "Fontify region bounds by LIMIT in region history buffer."
  (let ((in-diff (save-excursion
                   (beginning-of-line)
                   (or (looking-at "^\\(?:diff\\|changeset\\)\\>")
                       (re-search-backward "^\\(?:diff\\|changeset\\)\\>" nil t))
                   (eq ?d (char-after (match-beginning 0))))))
    (while
        (let ((end (save-excursion
                     (if (re-search-forward "\n\\(diff\\|changeset\\)\\>" limit t)
                         (match-beginning 1)
                       limit))))
          (let ((font-lock-keywords (if in-diff
                                        diff-font-lock-keywords
                                      vc-hgcmd--log-view-region-history-font-lock-keywords)))
            (font-lock-fontify-keywords-region (point) end))
          (goto-char end)
          (prog1 (< (point) limit)
            (setq in-diff (eq ?d (char-after))))))
    nil))

(defvar vc-hgcmd-region-history-mode-map
  (let ((map (make-composed-keymap
              (list diff-mode-map vc-hgcmd-log-view-mode-map))))
    map))

(define-derived-mode vc-hgcmd-region-history-mode vc-hgcmd-log-view-mode "Region-History/Hgcmd"
  "Major mode to browse Hg's \"log -f -p -L\" output."
  (setq-local vc-hgcmd--log-view-region-history-font-lock-keywords
              log-view-font-lock-keywords)
  (setq-local font-lock-defaults
              (cons 'vc-hgcmd-region-history-font-lock-keywords
                    (cdr font-lock-defaults))))

(defun vc-hgcmd-create-tag (_dir name branchp)
  "Create tag NAME.  If BRANCHP create named branch."
  (vc-hgcmd-command (if branchp "branch" "tag") name))

(defun vc-hgcmd-retrieve-tag (_dir name _update)
  "Update to branch NAME."
  (if (string-empty-p name)
      (vc-hgcmd-command "update")
    (vc-hgcmd-command "update" name)))

(defun vc-hgcmd-root (file)
  "Return root folder of repository for FILE."
  (vc-find-root file ".hg"))

(defun vc-hgcmd-previous-revision (file rev)
  "Revison prior to REV for FILE."
  (let ((newrev (vc-hgcmd-command
                 "log"
                 "-r" (format "last(limit(reverse(%s..%s), 2))"
                              (if file (format "follow('%s') and " (vc-hgcmd--file-relative-name file)) "")
                              rev)
                 "--template" "{rev}")))
    (when (and newrev (not (string= rev newrev)))
      newrev)))

(defun vc-hgcmd-next-revision (file rev)
  "Revision after REV for FILE."
  (let ((nextrev (vc-hgcmd-command
                  "log"
                  "-r"
                  (format "last(limit(%s%s.., 2))"
                          (if file
                              (format "follow('%s') and " (vc-hgcmd--file-relative-name file))
                            "")
                          rev)
                  "--template"
                  "{rev}")))
    (when (and nextrev (not (string= nextrev rev)))
      nextrev)))

(declare-function log-edit-mode "log-edit" ())

(defun vc-hgcmd--log-edit-default-message ()
  "Return 'merged ...' if there are two parents."
  (let* ((parents (vc-hgcmd--parents "{node}\\0{branch}"))
         (p1 (car parents))
         (p2 (cadr parents)))
    (when p2
      (let ((p1 (split-string p1 "\0"))
            (p2 (split-string p2 "\0")))
        (concat "merged " (if (string= (cadr p1) (cadr p2)) (car p2) (cadr p2)))))))

(defun vc-hgcmd--set-log-edit-summary ()
  "Set summary of commit message to 'merged ...' if committing after merge."
  (let* ((message (or (vc-hgcmd--log-edit-default-message) ""))
         (message (if vc-hgcmd-log-edit-message-function
                      (funcall vc-hgcmd-log-edit-message-function message)
                    message)))
    (when (and message (length message))
      (save-excursion
        (insert message)))))

(defun vc-hgcmd-log-edit-toggle-close-branch ()
  "Toggle --close-branch commit option."
  (interactive)
  (log-edit-toggle-header "Close-branch" "yes"))

(defun vc-hgcmd-log-edit-toggle-amend ()
  "Toggle --amend commit option.  If on, insert commit message of the previous commit."
  (interactive)
  (when (log-edit-toggle-header "Amend" "yes")
    (log-edit-set-header "Summary" (vc-hgcmd-command "log" "-l" "1" "--template" "{desc}"))))

(defvar vc-hgcmd-log-edit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-e") 'vc-hgcmd-log-edit-toggle-amend)
    (define-key map (kbd "C-c C-l") 'vc-hgcmd-log-edit-toggle-close-branch)
    map)
  "Keymap for log edit mode.")

(define-derived-mode vc-hgcmd-log-edit-mode log-edit-mode "Log-Edit/Hgcmd"
  "Major mode for editing Hgcmd log messages.

\\{vc-hgcmd-log-edit-mode-map}"
  ;; if there are two parents create maybe helpful commit message
  ;; it must be done in log-edit-hook
  (add-hook 'log-edit-hook #'vc-hgcmd--set-log-edit-summary t t))

(defun vc-hgcmd-delete-file (file)
  "Delete FILE."
  (vc-hgcmd-command "remove" "--force" (vc-hgcmd--file-relative-name file)))

(defun vc-hgcmd-rename-file (old new)
  "Rename file from OLD to NEW using `hg mv'."
  (vc-hgcmd-command "move" (vc-hgcmd--file-relative-name old) (vc-hgcmd--file-relative-name new)))

(defun vc-hgcmd--file-unresolved-p (file)
  "Return t if FILE is in conflict state."
  (let ((out (vc-hgcmd-command "resolve" "-l" (vc-hgcmd--file-relative-name file))))
    (and out (eq (aref out 0) ?U))))

(defun vc-hgcmd--after-save-hook ()
  "After save hook.  Mark file as resolved if vc state eq conflict and no smerge mode."
  (when (and buffer-file-name
             (not (save-excursion
                    (goto-char (point-min))
                    (re-search-forward "^<<<<<<< " nil t)))
             (yes-or-no-p (format "Hgcmd: Mark %s as resolved? " buffer-file-name)))
    (vc-hgcmd-mark-resolved (list buffer-file-name))
    (remove-hook 'after-save-hook #'vc-hgcmd--after-save-hook t)))

(defun vc-hgcmd-find-file-hook ()
  "Find file hook.  Start smerge session if vc state eq conflict."
  (when (and buffer-file-name
             (eq (vc-state buffer-file-name 'Hgcmd) 'conflict))
    (smerge-start-session)
    (add-hook 'after-save-hook #'vc-hgcmd--after-save-hook nil t)
    (vc-message-unresolved-conflicts buffer-file-name)))

(defun vc-hgcmd-conflicted-files (&optional _dir)
  "List of files with conflict or resolved conflict."
  (let (result)
    (with-temp-buffer
      (when (vc-hgcmd--run-command (make-vc-hgcmd--command :command (list "resolve" "--list") :output-buffer (current-buffer) :wait t))
        (goto-char (point-min))
        (while (not (eobp))
          (let ((file (buffer-substring-no-properties (+ (point) 2) (line-end-position)))
                (status (cdr (assoc (char-after) vc-hgcmd--translation-resolve))))
            (push (cons file status) result))
          (forward-line))
        result))))

(defun vc-hgcmd-find-ignore-file (file)
  "Return the ignore file of the repository of FILE."
  (expand-file-name ".hgignore" (vc-hgcmd-root file)))

(defun vc-hgcmd-repository-url (file-or-dir &optional remote)
  "Return the URL of REMOTE or default repository of FILE-OR-DIR."
  (let ((default-directory (vc-hgcmd-root file-or-dir)))
    (vc-hgcmd-command "config" (concat "paths." (or remote "default")))))

(defun vc-hgcmd-runcommand (command)
  "Run custom hg COMMAND."
  (interactive "sRun hg: ")
  (vc-hgcmd-command-update-callback (split-string-and-unquote command)))

(provide 'vc-hgcmd)

;;; vc-hgcmd.el ends here
