;;; magit-annex.el --- Control git-annex from Magit  -*- lexical-binding: t; -*-

;; Copyright (C) 2013-2021 Kyle Meyer <kyle@kyleam.com>

;; Author: Kyle Meyer <kyle@kyleam.com>
;;         Rémi Vanicat <vanicat@debian.org>
;; URL: https://github.com/magit/magit-annex
;; Package-Version: 20211004.2314
;; Package-Commit: 018e8eebd2b1e56e9e8c152c6fb249f4de52e2d8
;; Keywords: vc tools
;; Version: 1.8.1
;; Package-Requires: ((cl-lib "0.3") (magit "3.0.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Magit-annex adds a few git-annex operations to the Magit interface.
;; Annex commands are available under the annex popup menu, which is
;; bound to "@".  This key was chosen as a leading key mostly to be
;; consistent with John Wiegley's git-annex.el (which provides a Dired
;; interface to git-annex) [1].
;;
;; Adding files:
;;   @a   Add a file to the annex.
;;   @A   Add all untracked and modified files to the annex.
;;
;; Managing file content:
;;   @fu   Unlock files.
;;   @fl   Lock files.
;;   @fU   Undo files.
;;
;;   @fg   Get files.
;;   @fd   Drop files.
;;   @fc   Copy files.
;;   @fm   Move files.
;;
;;    The above commands, which operate on paths, are also useful
;;    outside of Magit buffers, especially in Dired buffers.  To make
;;    these commands easily accessible in Dired, you can add a binding
;;    for `magit-annex-file-action'.  If you use git-annex.el, you can
;;    put the popup under the same binding (@f) with
;;
;;     (define-key git-annex-dired-map "f"
;;       #'magit-annex-file-action)
;;
;;   @u    Browse unused files.
;;   @l    List annex files.
;;
;; Updating:
;;   @m   Run `git annex merge'.
;;   @y   Run `git annex sync'.
;;
;; In the unused buffer
;;   l    Show log for commits touching a file
;;   RET  Open a file
;;   k    Drop files
;;   s    Add files back to the index
;;
;; When Magit-annex is installed from MELPA, no additional setup is
;; needed.  The annex popup menu will be added under the main Magit
;; popup menu (and loading of Magit-annex will be deferred until the
;; first time the annex popup is called).
;;
;; To use Magit-annex from the source repository, put
;;
;;   (require 'magit-annex)
;;
;; in your initialization file.
;;
;;
;; [1] https://github.com/jwiegley/git-annex-el

;;; Code:

(require 'cl-lib)
(require 'magit)
(require 'transient)


;;; Variables

(defgroup magit-annex nil
  "Control git-annex from Magit"
  :prefix "magit-annex"
  :group 'magit-extensions)

(defcustom magit-annex-add-all-confirm t
  "Whether to confirm before adding all changes to the annex."
  :type 'boolean)

(define-obsolete-variable-alias 'magit-annex-standard-options
  'magit-annex-global-arguments "1.4.0")

(defcustom magit-annex-global-arguments nil
  "Arguments that are added to every git-annex call.
These are placed after \"annex\" in the call, whereas values from
`magit-git-global-arguments' are placed after \"git\"."
  :type '(repeat string))

(defcustom magit-annex-limit-file-choices t
  "Limit choices for file commands based on state of repo.
For example, if locking a file, limit choices to unlocked files."
  :safe 'booleanp
  :type 'boolean)

(defcustom magit-annex-confirm-all-files t
  "Require confirmation of empty input to `magit-annex-*-files' commands.
If this is nil, run the operation on all files without asking
first."
  :package-version '(magit-annex . "1.2.0")
  :type 'boolean)

(defcustom magit-annex-include-directories t
  "Whether to list directories in prompts of `magit-annex-*-files' commands.
Consider disabling this if the prompt is slow to appear in
repositories that contain many annexed files."
  :package-version '(magit-annex . "1.2.0")
  :safe 'booleanp
  :type 'boolean)

(defcustom magit-annex-unused-open-function nil
  "Function used by `magit-annex-unused-open'.

This function should take a single required argument, a file
name.  If you have configured Org mode to open files on your
system, consider using `org-open-file'.

If nil, `magit-annex-unused-open' will prompt for the name of the
program used to open the unused file."
  :type '(choice (const :tag "Read shell command" nil)
                 (function :tag "Function to open file")))

(defcustom magit-annex-unused-stat-argument t
  "Enable '--stat' flag in log popup when point is on unused item."
  :package-version '(magit-annex . "1.3.0")
  :type 'boolean)


;;; Transients
;;;; Infix Arguments

(transient-define-argument magit-annex:--jobs ()
  :description "Number of concurrent jobs"
  :class 'transient-option
  :key "-j"
  :shortarg "-J"
  :argument "--jobs="
  :reader 'transient-read-number-N+)

(transient-define-argument magit-annex:--fast ()
  :description "Fast variant of command"
  :class 'transient-option
  :key "-f"
  :argument "--fast")

(transient-define-argument magit-annex:--force ()
  :description "Force unsafe actions"
  :class 'transient-option
  :key "-F"
  :argument "--force")

(transient-define-argument magit-annex:--from ()
  :description "From remote"
  :class 'transient-option
  :key "=f"
  :argument "--from="
  :reader 'magit-read-remote)

(transient-define-argument magit-annex:--to ()
  :description "To remote"
  :class 'transient-option
  :key "=t"
  :argument "--to="
  :reader 'magit-read-remote)

;;;; Prefix commands

;;;###autoload (autoload 'magit-annex-dispatch "magit-annex" nil t)
(transient-define-prefix magit-annex-dispatch ()
  "Invoke a git-annex command."
  :man-page "git-annex"
  ["Actions"
   [("a" "Add" magit-annex-add)
    ("@" "Add" magit-annex-add)
    ("A" "Add all" magit-annex-add-all)]
   [("G" "Get all (auto)" magit-annex-get-all-auto)
    ("m" "Merge annex branches" magit-annex-merge)
    (":" "Annex subcommand (from pwd)" magit-annex-command)]]
  ["Transient commands"
   [("f" "Action on files" magit-annex-file-action)
    ("y" "Sync" magit-annex-sync)
    ("!" "Running" magit-annex-run-command)]
   [("u" "Unused" magit-annex-unused)
    ("l" "List files" magit-annex-list)]])

(transient-define-prefix magit-annex-file-action ()
  "Invoke a git-annex file command."
  :man-page "git-annex"
  ["Arguments"
   (magit-annex:--fast)
   (magit-annex:--force)]
  ["Arguments for get, drop, copy, and move"
   ("-a" "Auto" "--auto")
   (magit-annex:--from)
   ("-n" "Desired number of copies" "--numcopies=" transient-read-number-N+)
   (magit-annex:--jobs)]
  ["Arguments for copy and move"
   (magit-annex:--to)]
  ["Arguments for get, drop, copy, and move"
   ("=f" "From remote" "--from=" magit-read-remote)]
  ["Actions"
   [("g" "Get" magit-annex-get-files)
    ("d" "Drop" magit-annex-drop-files)
    ("c" "Copy" magit-annex-copy-files)
    ("m" "Move" magit-annex-move-files)]
   [("l" "Lock" magit-annex-lock-files)
    ("u" "Unlock" magit-annex-unlock-files)
    ("U" "Undo" magit-annex-undo-files)]])

(transient-define-prefix magit-annex-sync ()
  "Invoke 'git annex sync'."
  :man-page "git-annex-sync"
  ["Arguments"
   (magit-annex:--fast)
   (magit-annex:--force)
   ("-c" "Transfer content" "--content")
   ("-n" "Don't commit local changes" "--no-commit")
   (magit-annex:--jobs)]
  ["Actions"
   ("y" "Sync all remotes" magit-annex-sync-all)
   ("r" "Sync a remote" magit-annex-sync-remote)])

(transient-define-prefix magit-annex-unused ()
  "Invoke 'git annex unused'."
  :man-page "git-annex-unused"
  ["Arguments"
   (magit-annex:--fast)
   (magit-annex:--from)
   ("-r" "Refspec" "--used-refspec=")]
  ["Actions"
   ("u" "Unused" magit-annex-unused-in-refs)
   ("r" "Unused in reflog" magit-annex-unused-in-reflog)])

(transient-define-prefix magit-annex-list ()
  "Invoke 'git annex list'."
  :man-page "git-annex-list"
  ["Arguments"
   ("-a" "All repos" "--allrepos")]
  ["Actions"
   ("l" "List files" magit-annex-list-files)
   ("d" "List files in directory" magit-annex-list-dir-files)])

(transient-define-prefix magit-annex-run-command ()
  "Run an arbitrary git-annex command."
  :man-page "git-annex"
  ["Actions"
   ("!" "Annex subcommand (from root)" magit-annex-command-topdir)
   (":" "Annex subcommand (from pwd)" magit-annex-command)])

;;;###autoload
(eval-after-load 'magit
  '(progn
     (define-key magit-mode-map "@" 'magit-annex-dispatch-or-init)
     (transient-append-suffix 'magit-dispatch '(0 -1 -1)
       '("@" "Annex" magit-annex-dispatch-or-init))))


;;; Process calls

(defun magit-annex-run (&rest args)
  "Call git-annex synchronously in a separate process, and refresh.

Before ARGS are passed to git-annex,
`magit-annex-global-arguments' will be prepended.

See `magit-run-git' for more details on the git call."
  (magit-run-git "annex" magit-annex-global-arguments args))

(defun magit-annex-run-async (&rest args)
  "Call git-annex asynchronously with ARGS.
See `magit-annex-run' and `magit-run-git-async' for more
information."
  (magit-run-git-async "annex" magit-annex-global-arguments args))

(defun magit-annex-command (command)
  "Execute COMMAND asynchronously, displaying output.
This is like `magit-git-command', but \"git annex \" rather than
\"git \" is used as the initial input."
  (interactive (list (magit-read-shell-command nil "git annex ")))
  (magit-git-command command))

(defun magit-annex-command-topdir (command)
  "Execute COMMAND asynchronously from top directory, displaying output.
This is like `magit-git-command-topdir', but \"git annex \"
rather than \"git \" is used as the initial input."
  (interactive (list (magit-read-shell-command t "git annex ")))
  (magit-git-command-topdir command))


;;; Initialization

;;;###autoload
(defun magit-annex-dispatch-or-init ()
  "Call `magit-annex-dispatch' or offer to initialize non-annex repo."
  (interactive)
  (cond
   ((magit-annex-inside-annexdir-p)
    (magit-annex-dispatch))
   ((y-or-n-p (format "No git-annex repository in %s.  Initialize one? "
                      default-directory))
    (call-interactively 'magit-annex-init))))

;;;###autoload
(defun magit-annex-init (&optional description)
  "Initialize git-annex repository.
\('git annex init [DESCRIPTION]')"
  (interactive "sDescription: ")
  (magit-annex-run "init" description))

(defun magit-annex-inside-annexdir-p ()
  (file-exists-p (concat (magit-git-dir) "annex")))


;;; Annexing

(defun magit-annex-add (&optional file)
  "Add the item at point to annex.
With a prefix argument, prompt for FILE.
\('git annex add')"
  ;; NEEDSWORK: Use of `magit-annex-unlocked-files' doesn't make sense
  ;; for v6+ repos.
  ;;
  ;; Modified from `magit-stage'.
  (interactive
   (when current-prefix-arg
     (list (magit-completing-read "Add file"
                                  (nconc (magit-annex-unlocked-files)
                                         (magit-untracked-files))))))
  (if file
      (magit-annex-run "add" file)
    (--when-let (magit-current-section)
      (pcase (list (magit-diff-type) (magit-diff-scope))
        (`(untracked file)
         (magit-annex-run "add" (directory-file-name
                                 (oref it value))))
        (`(untracked files)
         (magit-annex-run "add" (mapcar #'directory-file-name
                                        (magit-region-values))))
        (`(untracked list)
         (magit-annex-run "add" (magit-untracked-files)))
        (`(unstaged file)
         (magit-annex-run "add" (oref it value)))
        (`(unstaged files)
         (magit-annex-run "add" (magit-region-values)))
        (`(unstaged list)
         (magit-annex-run "add" (magit-annex-unlocked-files)))))))

(defun magit-annex-add-all ()
  "Add all untracked and modified files to the annex.
\('git annex add .')"
  ;; Modified from `magit-stage-all'.
  (interactive)
  (when (or (not magit-annex-add-all-confirm)
            (not (magit-anything-staged-p))
            (yes-or-no-p "Add all changes to the annex?"))
    (magit-annex-run "add" ".")))


;;; Updating

(defun magit-annex-sync-arguments ()
  (transient-args 'magit-annex-sync))

(defun magit-annex-sync-all (&optional args)
  "Sync git-annex.
\('git annex sync [ARGS]')"
  (interactive (list (magit-annex-sync-arguments)))
  (magit-annex-run-async "sync" args))

(defun magit-annex-sync-remote (remote &optional args)
  "Sync git-annex with REMOTE.
\('git annex sync [ARGS] REMOTE')"
  (interactive (list (magit-read-remote "Remote")
                     (magit-annex-sync-arguments)))
  (magit-annex-run-async "sync" args remote))

(defun magit-annex-merge ()
  "Merge git-annex.
\('git annex merge')"
  (interactive)
  (magit-annex-run "merge"))


;;; Managing content

(defun magit-annex-files ()
  "Return all annex files."
  (magit-git-items "annex" "find" "--print0" "--include" "*"))

(defun magit-annex-present-files ()
  "Return annex files that are present in current repo."
  (magit-git-items "annex" "find" "--print0"))

(defun magit-annex-absent-files ()
  "Return annex files that are absent in current repo."
  (magit-git-items "annex" "find" "--print0" "--not" "--in=here"))

(defun magit-annex-unlocked-files ()
  "Return unlocked annex files."
  (with-temp-buffer
    (let ((exit (magit-process-file
                 magit-git-executable nil t nil
                 "annex" "find" "--print0" "--unlocked")))
      (if (zerop exit)
          (split-string (buffer-string) "\0" t)
        ;; `find --unlocked' isn't available until git-annex
        ;; 7.20191009.  Fall back to the old approach that is
        ;; compatible with v5 repos only.
        (magit-git-items "diff-files" "-z" "--diff-filter=T" "--name-only")))))

(defun magit-annex-get-all-auto ()
  "Run `git annex get --auto'."
  (interactive)
  (magit-annex-run-async "get" "--auto"))

(defun magit-annex-read-files (prompt &optional limit-to default)
  (let* ((files (pcase limit-to
                  ((guard (not magit-annex-limit-file-choices))
                   (magit-annex-files))
                  (`absent (magit-annex-absent-files))
                  (`present (magit-annex-present-files))
                  (`unlocked (magit-annex-unlocked-files))
                  (_ (magit-annex-files))))
         (dirs (and magit-annex-include-directories
                    (delete-dups
                     (sort (delq nil (mapcar #'file-name-directory files))
                           #'string-lessp))))
         (input (if files
                    (completing-read-multiple
                     (or prompt "File,s: ")
                     (cons "*all*" (if dirs (nconc dirs files) files))
                     nil nil nil nil
                     default)
                  (user-error "No files to act on"))))
    (cond
     ((and (not input) (or (not magit-annex-confirm-all-files)
                           (y-or-n-p "Act on all files?")
                           (user-error "Aborting call")))
      nil)
     ((member "*all*" input) nil)
     (t
      (cl-mapcan (lambda (f)
                   (if (string-match-p "[[.*+\\^$?]" f)
                       (file-expand-wildcards f)
                     (list f)))
                 input)))))

(defun magit-annex--dired-relist (files)
  ;; Modified from git-annex.el
  (let ((here (point)))
    (unwind-protect
        (dolist (file files)
          (dired-relist-file (expand-file-name file)))
      (goto-char here))))

(defun magit-annex--dired-relist-async (files)
  (when (derived-mode-p 'dired-mode)
       (set-process-sentinel
        magit-this-process
        (lambda (process event)
          (magit-process-sentinel process event)
          (when (eq (process-status process) 'exit)
            (magit-annex--dired-relist files))))
       (let ((magit-display-buffer-noselect t))
         (magit-process-buffer))))

(defun magit-annex-file-action-arguments ()
  (transient-args 'magit-annex-file-action))

(defun magit-annex--file-arguments (&optional limit-to unless-from)
  "Return interactive arguments for file-based commands.
LIMIT-TO is interpreted by `magit-annex-read-files'.  If
UNLESS-FROM is non-nil, pass LIMIT-TO only if the command
arguments don't include --from."
  (let* ((args (magit-annex-file-action-arguments))
         (files (or (mapcar #'cdr (magit-region-values 'annex-list-file))
                    (when-let ((file (cdr (magit-section-value-if
                                           'annex-list-file))))
                      (list file))
                    (and (derived-mode-p 'dired-mode)
                         (dired-get-marked-files t))))
         (default (mapconcat #'identity files ",")))
    (list
     (magit-annex-read-files
      (concat "File,s"
              (and files (format " (%s)" default))
              ": ")
      (and (or (not unless-from)
               (cl-notany (lambda (it) (string-match-p "--from=" it))
                          args))
           limit-to)
      default)
     args)))

(defun magit-annex-get-files (files &optional args)
  "Get annex files.
\('git annex get [ARGS] -- FILES)"
  (interactive (magit-annex--file-arguments 'absent))
  (magit-annex-run-async "get" args "--" files)
  (magit-annex--dired-relist-async files))

(defun magit-annex-drop-files (files &optional args)
  "Drop annex files.
\('git annex drop [ARGS] -- FILES)"
  (interactive (magit-annex--file-arguments 'present t))
  (magit-annex-run-async "drop" args "--" files)
  (magit-annex--dired-relist-async files))

(defun magit-annex-copy-files (files &optional args)
  "Copy annex files.
\('git annex copy [ARGS] -- FILES)"
  (interactive (magit-annex--file-arguments 'present t))
  (magit-annex-run-async "copy" args "--" files)
  (magit-annex--dired-relist-async files))

(defun magit-annex-move-files (files &optional args)
  "Move annex files.
\('git annex move [ARGS] -- FILES)"
  (interactive (magit-annex--file-arguments 'present t))
  (magit-annex-run-async "move" args "--" files)
  (magit-annex--dired-relist-async files))

(defun magit-annex-unlock-files (files &optional args)
  "Unlock annex files.
\('git annex unlock [ARGS] -- FILES)"
  (interactive (magit-annex--file-arguments 'present))
  (magit-annex-run "unlock" args "--" files)
  (magit-annex--dired-relist files))

(defun magit-annex-lock-files (files &optional args)
  "Lock annex files.
\('git annex lock [ARGS] -- FILES)"
  (interactive (magit-annex--file-arguments 'unlocked))
  (magit-annex-run "lock" args "--" files)
  (magit-annex--dired-relist files))

(defun magit-annex-undo-files (files &optional args)
  "Undo annex files.
\('git annex undo [ARGS] -- FILES)"
  (interactive (magit-annex--file-arguments))
  (magit-annex-run "undo" args "--" files)
  (magit-annex--dired-relist files))


;;; Unused mode

(defun magit-annex-unused-add ()
  "Add annex unused data back into the index."
  (interactive)
  (magit-section-case
    (unused-data
     (let ((data-nums (or (mapcar #'car (magit-region-values))
                          (list (car (oref it value))))))
       (magit-annex-run "addunused" data-nums)))))

(defun magit-annex-unused-drop (&optional force)
  "Drop current unused data.
With prefix argument FORCE, pass \"--force\" flag to
`git annex dropunused'."
  (interactive "P")
  (magit-section-case
    (unused-data
     (let ((data-nums (or (mapcar #'car (magit-region-values))
                          (list (car (oref it value))))))
       (magit-annex-run "dropunused" (if force
                                         (cons "--force" data-nums)
                                       data-nums))))
    (unused
     (magit-annex-run "dropunused" (if force
                                       '("--force" "all")
                                     "all")))))

(defun magit-annex-unused-log ()
  "Display log for unused file.

Show a log where the key for the unused file at point is supplied
as the value for the '-S' flag.  The '--stat' flag is also
enabled if `magit-annex-unused-stat-argument' is non-nil.

\('git log [--stat] -S<KEY>')"
  (interactive)
  (magit-section-case
    (unused-data
     (let ((args (car (magit-log-arguments))))
       (when (and magit-annex-unused-stat-argument
                  (not (member "--stat" args)))
         (push "--stat" args))
       (funcall
        (cond
         ;; `magit-git-log' was renamed to `magit-log-setup-buffer' in
         ;; v2.90.1-480-g249ce0eec.  This is a temporary compatibility
         ;; kludge for Guix, whose current version of Magit is from a
         ;; bit before that (v2.90.1-460-gc761d28d4).
         ((fboundp 'magit-log-setup-buffer)
          #'magit-log-setup-buffer)
         ((fboundp 'magit-git-log)
          #'magit-git-log)
         (t (error "bug: should never get here")))
        (list (or (magit-get-current-branch) "HEAD"))
        (cons (concat "-S" (cdr (oref it value)))
              (cl-remove-if (lambda (x) (string-prefix-p "-S" x))
                            args))
        nil)))
    (t
     (user-error "No unused file at point"))))

(defun magit-annex--file-name-from-key (key)
  (magit-git-string "annex" "contentlocation" key))

(declare-function dired-read-shell-command "dired-aux" (prompt arg files))

(defun magit-annex-unused-open (&optional in-emacs)
  "Open an unused file.
By default, prompt for a command to open the file.  If
`magit-annex-unused-open-function' is non-nil, pass the file name
to this function instead.  With prefix argument IN-EMACS, open
the file within Emacs."
  (interactive "P")
  (magit-section-case
    (unused-data
     (let* ((key (cdr (oref it value)))
            (file (magit-annex--file-name-from-key key)))
       (cond
        (in-emacs
         (find-file file))
        (magit-annex-unused-open-function
         (funcall magit-annex-unused-open-function file))
        (t
         (require 'dired-aux)
         (let ((command (dired-read-shell-command "open %s with " ()
                                                  (list file))))
           (dired-do-async-shell-command command () (list file)))))))))

(defvar magit-annex-unused-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map magit-mode-map)
    (define-key map (kbd "RET") #'magit-annex-unused-open)
    (define-key map "s" #'magit-annex-unused-add)
    (define-key map "k" #'magit-annex-unused-drop)
    (define-key map (kbd "C-c C-l") #'magit-annex-unused-log)
    map)
  "Keymap for `magit-annex-unused-mode'.")

(define-derived-mode magit-annex-unused-mode magit-mode "Magit-annex Unused"
  "Mode for looking at unused data in annex.

\\<magit-annex-unused-mode-map>\
Type \\[magit-annex-unused-drop] to drop data at point.
Type \\[magit-annex-unused-add] to add the unused data back into the index.
Type \\[magit-annex-unused-log] to show commit log for the unused file.
Type \\[magit-annex-unused-open] to open the file.
\n\\{magit-annex-unused-mode-map}"
  :group 'magit-modes
  (hack-dir-local-variables-non-file-buffer))

(defun magit-annex-unused-arguments ()
  (transient-args 'magit-annex-unused))

;;;###autoload
(defun magit-annex-unused-in-refs (&optional args)
  "Show annex files not used in any branches or tags.
These files are not pointed by the tips of the repositories
branches or tags.
\('git annex unused [ARGS]')"
  (interactive (list (magit-annex-unused-arguments)))
  (magit-annex-unused-setup-buffer args))

;;;###autoload
(defun magit-annex-unused-in-reflog (&optional args)
  "Show annex files not used in any of the revisions in HEAD's reflog.
\('git annex unused --used-refspec=reflog [ARGS]')"
  (interactive (list (magit-annex-unused-arguments)))
  (if (cl-some (lambda (x) (string-prefix-p "--used-refspec=" x))
               args)
      (user-error "Flag --used-refspec was given more than once")
    (setq args (cons "--used-refspec=reflog" args)))
  (magit-annex-unused-setup-buffer args))

(defun magit-annex-unused-setup-buffer (args)
  (magit-setup-buffer #'magit-annex-unused-mode nil
    (magit-buffer-arguments args)))

(defun magit-annex-unused-refresh-buffer ()
  "Refresh the content of the unused buffer."
  (magit-insert-section (unused)
    (magit-insert-heading
      (concat "Unused files"
              (and magit-buffer-arguments
                   (concat " ("
                           (mapconcat #'identity magit-buffer-arguments " ")
                           ")"))
              ":"))
    (magit-git-wash #'magit-annex-unused-wash
      "annex" "unused" magit-buffer-arguments)))

(defun magit-annex-unused-wash (&rest _)
  "Convert the output of git-annex unused into Magit section."
  (when (not (looking-at "unused .*
"))
    (error "Check magit-process for error"))
  (delete-region (point) (match-end 0))
  (if (not (looking-at ".*Some annexed data is no longer used by any files:
 *NUMBER *KEY
"))
      (progn
        (delete-region (point-min) (point-max))
        (insert "   nothing"))
    (delete-region (point) (match-end 0))
    (magit-wash-sequence #'magit-annex-unused-wash-line)
    (delete-region (point) (point-max))))

(defun magit-annex-unused-wash-line ()
  "Make a Magit section from description of unused data."
  (when (looking-at " *\\([0-9]+\\) *\\(.*\\)$")
    (let ((num (match-string 1))
          (key (match-string 2)))
      (delete-region (match-beginning 0) (match-end 0))
      (magit-insert-section (unused-data (cons num key))
        (insert (format "   %-3s   %s" num key))
        (forward-line)))))


;; List mode

(defcustom magit-annex-list-sections-hook
  '(magit-annex-list-insert-headers
    magit-annex-list-insert-files)
  "Hook run to insert sections into a `magit-annex-list-mode' buffer."
  :group 'magit-modes
  :type 'hook)

(defvar magit-annex-list-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map magit-mode-map)
    (define-key map "f" #'magit-annex-file-action)
    map)
  "Keymap for `magit-annex-list-mode'.")

(defvar-local magit-annex-buffer-directory nil)

(define-derived-mode magit-annex-list-mode magit-mode "Magit-annex List"
  "Mode for viewing on `git annex list' output.

\\<magit-annex-list-mode-map>\
Type \\[magit-annex-file-action] to perform git-annex action
on the files selected by the region (if active) or the file at point.
\n\\{magit-annex-list-mode-map}"
  :group 'magit-modes
  (hack-dir-local-variables-non-file-buffer))

(defun magit-annex-list-arguments ()
  (transient-args 'magit-annex-list))

;;;###autoload
(defun magit-annex-list-files (&optional args)
  "List annex files.
\('git annex list [ARGS]')"
  (interactive (magit-annex-list-arguments))
  (magit-annex-list-setup-buffer nil args))

;;;###autoload
(defun magit-annex-list-dir-files (directory &optional args)
  "List annex files in DIRECTORY.
\('git annex list [ARGS] DIRECTORY')"
  (interactive
   (list (directory-file-name
          (file-relative-name (read-directory-name "List annex files in: "
                                                   nil nil t)
                              (magit-toplevel)))
         (magit-annex-list-arguments)))
  (magit-annex-list-setup-buffer directory args))

(defun magit-annex-list-setup-buffer (directory args)
  (magit-setup-buffer #'magit-annex-list-mode nil
    (magit-annex-buffer-directory directory)
    (magit-buffer-arguments args)))

(defun magit-annex-list-refresh-buffer ()
  "Refresh content of a `magit-annex-list-mode' buffer."
  (magit-insert-section (annex-list-buffer)
    (run-hooks 'magit-annex-list-sections-hook)))

(defun magit-annex-list-insert-headers ()
  "Insert headers for `magit-annex-list-mode' buffer."
  (magit-insert-status-headers))

(defun magit-annex-list-insert-files ()
  "Insert output of `git annex list'."
  (let* ((subdir magit-annex-buffer-directory)
         (heading (if subdir
                      (format "Annex files in %s:" subdir)
                    "Annex files:")))
    (magit-insert-section (annex-list-buffer)
      (magit-insert-heading heading)
      (magit-git-wash #'magit-annex-list-wash
        "annex" "list" magit-annex-buffer-directory magit-buffer-arguments))))

(defconst magit-annex-list-line-re "\\([_X]+\\) \\(.*\\)$")

(defun magit-annex-list-wash (&rest _)
  "Convert the output of `git annex list' into Magit section."
  (when (looking-at "(merging .+)")
    (delete-region (point) (1+ (match-end 0))))
  (when (not (looking-at "here"))
    (error "Check magit-process for error"))
  (if (re-search-forward magit-annex-list-line-re nil t)
      (progn (beginning-of-line)
             (magit-wash-sequence #'magit-annex-list-wash-line))
    (re-search-forward "^|+$")))

(defun magit-annex-list-wash-line ()
  "Convert file line of `git annex list' into Magit section."
  (when (looking-at magit-annex-list-line-re)
    (let ((locs (match-string 1))
          (file (match-string 2)))
      (delete-region (match-beginning 0) (match-end 0))
      (magit-insert-section (annex-list-file (cons locs file))
        (insert (format "%s %s" locs file))
        (forward-line)))))

(provide 'magit-annex)

;;; magit-annex.el ends here
