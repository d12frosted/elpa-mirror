;;; ditz-mode.el --- Emacs interface to Ditz issue tracking system
;;
;; Copyright (C) 2008-2015 Kentaro Kuribayashi, Glenn Hutchings
;;
;; Author:     Glenn Hutchings <zondo42@gmail.com>
;; Maintainer: Glenn Hutchings <zondo42@gmail.com>
;; Keywords:   tools
;; Package-Version: 20150729.940
;; Package-Commit: 56668844acd91c3d15a08ba406dbb1ba0c2fe9b4
;; Version:    0.4
;;
;; This file is not a part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; This is an Emacs interface to the Ditz distributed issue tracking
;; system, which can be found at http://rubygems.org/gems/ditz.
;;
;; Put this file in your Lisp load path and something like the following in
;; your .emacs file:
;;
;;     (require 'ditz-mode)
;;     (define-key global-map "\C-c\C-d" ditz-prefix)
;;
;; See the documentation for `ditz-mode' for more info.
;;
;;; History:
;; Version 0.4 (unreleased):
;;    Add arbitrary Ditz command execution via '!'.
;;
;; Version 0.3 (Nov 24 2013):
;;    Auto-shrink issue windows.
;;    Add directory name to ditz buffer names.
;;    Issue regexps now only match words and digits.
;;    Add pyditz support (https://pypi.python.org/pypi/pyditz)
;;
;; Version 0.2 (24 Jun 2010):
;;    Add support for issue-claiming plugin.
;;    Add highlighting of issue status.
;;    Add optional count to log commands.
;;    Minor bug fixes.
;;
;; Version 0.1 (21 Mar 2010):
;;    First released version.
;;
;;; Credits:
;;
;; Thanks to Kentaro Kuribayashi <kentarok@gmail.com>, author of the
;; original Ditz mode.  This was based on that version, but now hardly any
;; of the original code remains.
;;
;;; Code:

;;;; Customizable stuff.

(defgroup ditz nil
  "Interface to Ditz distributed bug tracker."
  :prefix "ditz-"
  :group 'tools)

(defcustom ditz-program "ditz"
  "Ditz command.

Set this to 'pyditz' to use that program instead."
  :type 'string
  :group 'ditz)

(defcustom ditz-log-count ""
  "Number of log entries to show."
  :type 'string
  :group 'ditz)

;;;; Constants.

(defconst ditz-config-filename ".ditz-config"
  "File name of the Ditz config file.")

(defconst ditz-plugin-filename ".ditz-plugins"
  "File name of the Ditz plugin file.")

(defconst ditz-issue-id-regex "\\b\\([a-z][a-z0-9-]*-[0-9]+\\)\\b"
  "Regex for issue id.")

(defconst ditz-issue-attr-regex "\\(^[A-Za-z ]\\{11\\}\\): "
  "Regex for issue attribute.")

(defconst ditz-issue-unstarted-regex "Status: \\(unstarted\\)"
  "Regex for issue unstarted status.")

(defconst ditz-issue-progress-regex "Status: \\(in progress\\)"
  "Regex for issue in-progress status.")

(defconst ditz-issue-paused-regex "Status: \\(paused\\)"
  "Regex for issue paused status.")

(defconst ditz-issue-fixed-regex "Status: closed: \\(fixed\\)"
  "Regex for issue fixed status.")

(defconst ditz-issue-wontfix-regex "Status: closed: \\(won't fix\\)"
  "Regex for issue wontfix status.")

(defconst ditz-issue-reorg-regex "Status: closed: \\(reorganized\\)"
  "Regex for issue reorganized status.")

(defconst ditz-log-attr-regex
  (concat (regexp-opt '("date" "author" "issue") 'words) " *:")
  "Regex for log attribute.")

(defconst ditz-release-name-regex "^\\([^ ]+\\) (.*$"
  "Regex for release name.")

(defconst ditz-comment-regex "^\s+\\(>.*\\)$"
  "Regex for comment.")

(defconst ditz-feature-regex "(\\(feature\\))"
  "Regex for feature indicator.")

(defconst ditz-bug-regex "(\\(bug\\))"
  "Regex for bug indicator.")

;;;; Variables.

(defvar ditz-todo-flags ""
  "Flags to pass to `ditz-todo'.")

(defvar ditz-todo-release ""
  "Release specified by `ditz-todo'.")

(defvar ditz-todo-lastdir nil
  "Last issue directory visited by `ditz-todo'.")

(defvar ditz-is-pyditz (string= ditz-program "pyditz")
  "Whether we're using pyditz.")

;;;; Commands.

(defun ditz-command (cmd)
  "Run arbitrary Ditz command."
  (interactive "sDitz command: ")
  (ditz-call-process cmd nil 'pop t))

(defun ditz-todo ()
  "Show current todo list."
  (interactive)
  (let ((issuedir (ditz-issue-directory)))
    (unless (equal issuedir ditz-todo-lastdir)
      (setq ditz-todo-release ""))
    (setq ditz-todo-lastdir issuedir))
  (ditz-call-process "todo" (ditz-todo-args) 'switch))

(defun ditz-add ()
  "Add a new issue."
  (interactive)
  (ditz-call-process "add" nil 'pop t))

(defun ditz-add-release ()
  "Add a new release."
  (interactive)
  (ditz-call-process "add-release" nil 'pop t))

(defun ditz-status ()
  "Show status of issues."
  (interactive)
  (ditz-call-process "status" nil 'display))

(defun ditz-log ()
  "Show log of recent activities."
  (interactive)
  (ditz-call-process "log" ditz-log-count 'pop))

(defun ditz-shortlog ()
  "Show short log of recent activities."
  (interactive)
  (ditz-call-process "shortlog" ditz-log-count 'pop))

(defun ditz-show ()
  "Show issue details."
  (interactive)
  (ditz-call-process "show" (ditz-current-issue) 'switch))

(defun ditz-grep (regexp)
  "Show issue details."
  (interactive "sShow issues matching regexp: ")
  (ditz-call-process "grep" (concat "\"" regexp "\"") 'pop))

(defun ditz-assign ()
  "Assign issue to a release."
  (interactive)
  (ditz-call-process "assign" (ditz-current-issue) 'switch t))

(defun ditz-unassign ()
  "Unassign an issue."
  (interactive)
  (ditz-call-process "unassign" (ditz-current-issue) 'switch t))

(defun ditz-comment ()
  "Comment on an issue."
  (interactive)
  (ditz-call-process "comment" (ditz-current-issue) 'pop t))

(defun ditz-edit ()
  "Edit issue details."
  (interactive)
  (let ((issue-id (ditz-current-issue))
	(issue-dir (ditz-issue-directory)))
    (ditz-call-process "show" issue-id 'switch)
    (goto-char (point-min))
    (save-excursion
      (let ((beg (search-forward "Identifier: "))
	    (end (line-end-position)))
	(setq issue-id (buffer-substring-no-properties beg end))))
    (find-file (ditz-issue-file issue-id))))

(defun ditz-edit-project ()
  "Edit the project file."
  (interactive)
  (find-file (ditz-project-file)))

(defun ditz-close ()
  "Close an issue."
  (interactive)
  (ditz-call-process "close" (ditz-current-issue) 'switch t))

(defun ditz-drop ()
  "Drop an issue."
  (interactive)
  (let ((issue-id (ditz-current-issue)))
    (when (yes-or-no-p (concat "Drop " issue-id " "))
      (ditz-call-process "drop" issue-id 'switch))))

(defun ditz-start ()
  "Start work on an issue."
  (interactive)
  (ditz-call-process "start" (ditz-current-issue) 'switch t))

(defun ditz-stop ()
  "Stop work on an issue."
  (interactive)
  (ditz-call-process "stop" (ditz-current-issue) 'switch t))

(defun ditz-claim ()
  "Claim an issue."
  (interactive)
  (ditz-require "issue-claiming")
  (ditz-call-process "claim" (ditz-current-issue) 'switch t))

(defun ditz-unclaim ()
  "Unclaim an issue."
  (interactive)
  (ditz-require "issue-claiming")
  (ditz-call-process "unclaim" (ditz-current-issue) 'switch t))

(defun ditz-show-claimed ()
  "Show list of claimed issues."
  (interactive)
  (ditz-require "issue-claiming")
  (ditz-call-process "claimed" (ditz-todo-args) 'switch))

(defun ditz-show-unclaimed ()
  "Show list of unclaimed issues."
  (interactive)
  (ditz-require "issue-claiming")
  (ditz-call-process "unclaimed" (ditz-todo-args) 'switch))

(defun ditz-show-mine ()
  "Show list of my issues."
  (interactive)
  (ditz-require "issue-claiming")
  (ditz-call-process "mine" (ditz-todo-args) 'switch))

(defun ditz-set-component ()
  "Set an issue's component."
  (interactive)
  (ditz-call-process "set-component" (ditz-current-issue) 'switch t))

(defun ditz-add-reference ()
  "Add an issue reference."
  (interactive)
  (ditz-call-process "add-reference" (ditz-current-issue) 'switch t))

(defun ditz-release ()
  "Mark release as released."
  (interactive)
  (ditz-call-process "release" (ditz-current-release) 'switch t))

(defun ditz-show-releases ()
  "Show list of all releases."
  (interactive)
  (ditz-call-process "releases" nil 'pop))

(defun ditz-toggle-status ()
  "Show/hide by issue status."
  (interactive)
  (if (string= ditz-todo-flags "")
      (setq ditz-todo-flags "-a")
    (setq ditz-todo-flags ""))
  (ditz-toggle-message)
  (ditz-reload))

(defun ditz-toggle-release ()
  "Show/hide by release."
  (interactive)
  (if (string= ditz-todo-release "")
      (setq ditz-todo-release (ditz-current-release))
    (setq ditz-todo-release ""))
  (ditz-toggle-message)
  (ditz-reload))

(defun ditz-next-thing ()
  "Go to the next thing, maybe showing it in another window."
  (interactive)
  (if (ditz-current-buffer-p "releases")
      (forward-line)
    (forward-button 1 t))
  (ditz-show-thing))

(defun ditz-previous-thing ()
  "Go to the previous thing, maybe showing it in another window."
  (interactive)
  (if (ditz-current-buffer-p "releases")
      (forward-line -1)
    (backward-button 1 t))
  (ditz-show-thing))

(defun ditz-html-generate ()
  "Generate HTML files of issues, returning the created HTML file."
  (interactive)
  (ditz-call-process "html" nil)
  (when (search-forward "URL: " nil t)
    (let ((url (buffer-substring (point) (line-end-position))))
      (message "Generated HTML in %s" url)
      url)))

(defun ditz-html-browse ()
  "Generate and browse HTML files of issues."
  (interactive)
  (browse-url-of-file (ditz-html-generate)))

(defun ditz-archive ()
  "Archive a release."
  (interactive)
  (let ((release-name (ditz-current-release)))
    (when (yes-or-no-p (concat "Archive release " release-name "? "))
      (ditz-call-process "archive" release-name 'display)
      (ditz-reload))))

(defun ditz-changelog ()
  "Show change log for a release."
  (interactive)
  (ditz-call-process "changelog" (ditz-current-release) 'display))

(defun ditz-show-config ()
  "Show pathname of the Ditz config file."
  (interactive)
  (message "Ditz config file: %s" (ditz-config-file)))

(defun ditz-edit-config ()
  "Edit the Ditz config file."
  (interactive)
  (find-file (ditz-config-file)))

(defun ditz-reload ()
  "Reload the current Ditz buffer."
  (interactive)
  (goto-char (point-min))
  (cond ((ditz-current-buffer-p "todo")
         (ditz-call-process "todo" (ditz-todo-args) 'switch))
        ((ditz-current-buffer-p "status")
         (ditz-call-process "status" nil 'switch))
        ((ditz-current-buffer-p "releases")
         (ditz-call-process "releases" nil 'switch))
        ((ditz-current-buffer-p "show")
         (ditz-call-process "show" (ditz-current-issue) 'switch))
        ((ditz-current-buffer-p "shortlog")
	 (ditz-call-process "shortlog" nil 'switch))
        ((ditz-current-buffer-p "log")
         (ditz-call-process "log" nil 'switch))
	((ditz-current-buffer-p "claimed")
	 (ditz-call-process "claimed" (ditz-todo-args) 'switch))
	((ditz-current-buffer-p "unclaimed")
	 (ditz-call-process "unclaimed" (ditz-todo-args) 'switch))
	((ditz-current-buffer-p "mine")
	 (ditz-call-process "mine" (ditz-todo-args) 'switch))))

(defun ditz-quit ()
  "Bury the current Ditz buffer."
  (interactive)
  (bury-buffer))

(defun ditz-quit-all ()
  "Bury all Ditz buffers."
  (interactive)
  (delete-other-windows)
  (dolist (name '("todo" "status" "show" "shortlog" "releases" "log"
		  "claimed" "unclaimed" "mine" "grep"))
    (let ((buffer (get-buffer (ditz-buffer-name name))))
      (when buffer
	(with-current-buffer buffer
	  (bury-buffer (current-buffer))
	  (replace-buffer-in-windows))))))

;;;; Internal functions.

(defun ditz-current-issue (&optional noerror)
  "Return issue ID at the current/next issue button."
  (let ((button (next-button (point) t)))
    (cond (button
	   (button-label button))
	  (noerror
	   nil)
	  (t
	   (error "No current issue")))))

(defun ditz-current-release (&optional noerror)
  "Return the release ID on the current line."
  (save-excursion
    (let* ((beg (progn (beginning-of-line) (point)))
	   (end (progn (end-of-line) (point)))
	   (line (buffer-substring-no-properties beg end))
	   (release (when (string-match ditz-release-name-regex line)
		      (match-string 1 line))))
      (cond ((or release noerror)
	     release)
	    (t
	     (error "No release on this line"))))))

(defun ditz-todo-args (&optional release)
  "Return current Ditz todo arguments."
  (format "%s %s" ditz-todo-flags (or release ditz-todo-release)))

(defun ditz-toggle-message ()
  "Give message based on current display settings."
  (message
   (concat "Showing "
	   (if (string= ditz-todo-flags "")
	       "unresolved" "all")
	   " issues "
	   (if (string= ditz-todo-release "")
	       "" (format "assigned to release %s" ditz-todo-release)))))

(defun ditz-call-process (command &optional arg popup-flag interactive)
  "Invoke a Ditz command."

  (let* ((issuedir (ditz-issue-directory))
	 (quoteddir (concat "\"" issuedir "\""))
	 (cmd (mapconcat 'identity
			 (if ditz-is-pyditz
			     (list ditz-program command arg)
			   (list ditz-program "-i" quoteddir command arg)) " "))
	 (bufname (ditz-buffer-name command))
	 (buffer (get-buffer-create bufname))
         (proc (get-buffer-process buffer)))

    ;; If not interactive, make sure we get a new buffer.
    (unless interactive
      (kill-buffer buffer)
      (setq buffer (get-buffer-create bufname)))

    ;; If interactive and already running, ask for confirmation.
    (if (and interactive proc (eq (process-status proc) 'run))
        (when (y-or-n-p (format "A %s process is running; kill it? "
                                (process-name proc)))
          (interrupt-process proc)
          (sit-for 1)
          (delete-process proc)))

    ;; Initialize command buffer.
    (with-current-buffer buffer
      (setq default-directory (file-name-directory issuedir))
      (setq buffer-read-only nil)
      (erase-buffer)
      (buffer-disable-undo (current-buffer)))

    ;; Start the Ditz process.
    (if interactive
	(make-comint-in-buffer "ditz-call-process"
			       buffer shell-file-name nil
			       shell-command-switch cmd)
      (call-process-shell-command cmd nil buffer))

    ;; Display results.
    (cond ((eq popup-flag 'switch)
	   (switch-to-buffer buffer))
          ((eq popup-flag 'pop)
           (pop-to-buffer buffer))
          ((eq popup-flag 'display)
           (display-buffer buffer))
          ((eq popup-flag 'display-other)
	   (with-current-buffer buffer
	     (ditz-mode)
	     (goto-char (point-min)))
           (display-buffer buffer))
          (t
           (set-buffer buffer)))

    ;; Go to Ditz mode if required.
    (when (and (not interactive) (eq buffer (current-buffer)))
      (ditz-mode)
      (goto-char (point-min)))

    ;; Shrink other window (must be a better way than this!).
    (other-window 1)
    (shrink-window-if-larger-than-buffer)
    (other-window -1)))

(defun ditz-project-file ()
  "Return the pathname of the current project file."
  (concat (ditz-issue-directory) "/project.yaml"))

(defun ditz-issue-file (id)
  "Return the pathname of issue ID."
  (concat (ditz-issue-directory) "/issue-" id ".yaml"))

(defun ditz-issue-directory ()
  "Return pathname of the Ditz issue directory.

The issue directory is found by searching upward from the current
directory for a .ditz-config file containing the issue_dir
setting.  Then the issue directory is located either in the
current directory or the one with the .ditz-config file in it."

  (let* ((configfile (ditz-config-file))
	 (parentdir (file-name-directory configfile))
	 (buf (get-buffer-create "*ditz-config*"))
	 (issuedir nil)
	 (issuedirname nil))

    ;; Get issue directory name from config file.
    (with-current-buffer buf
      (erase-buffer)
      (insert-file-contents configfile nil nil nil t)
      (goto-char (point-min))
      (if (search-forward "issue_dir: ")
	  (setq issuedirname (buffer-substring (point) (line-end-position)))
	(error "Can't find 'issue_dir' setting in %s" configfile)))

    ;; Try looking in current directory for it.
    (setq issuedir (concat default-directory "/" issuedirname))

    ;; If not there, try same directory as config file.
    (unless (file-exists-p issuedir)
      (setq issuedir (concat parentdir "/" issuedirname)))

    ;; If still not there, give up.
    (unless (file-exists-p issuedir)
      (error "Can't find Ditz issue directory '%s'" issuedirname))

    (expand-file-name issuedir)))

(defun ditz-config-file ()
  "Find Ditz config file in current or parent directories."

  (let ((curdir (expand-file-name (file-name-directory default-directory)))
	(configfile nil))

    (while (not configfile)
      (setq path (concat curdir "/" ditz-config-filename))
      (cond ((file-exists-p path)
	     (setq configfile path))
	    ((string= curdir "/")
	     (error "Can't find %s; have you run 'ditz init'?"
		    ditz-config-filename))
	    (t
	     (setq curdir (directory-file-name (file-name-directory curdir))))))
    (expand-file-name configfile)))

(defun ditz-plugin-file ()
  "Return pathname of the Ditz plugin file."
  (let* ((configfile (ditz-config-file))
	 (parentdir (file-name-directory configfile)))
    (concat parentdir ditz-plugin-filename)))

(defun ditz-require (plugin)
  "Raise error if a plugin is not enabled."

  (let ((pluginfile (ditz-plugin-file))
	(buf (get-buffer-create "*ditz-plugins*"))
	(enabled nil))
    (with-current-buffer buf
      (erase-buffer)
      (if (file-exists-p pluginfile)
	  (insert-file-contents pluginfile nil nil nil t))
      (goto-char (point-min))
      (if (search-forward plugin nil t)
	  (setq enabled t)))
    (unless enabled
      (error "Ditz '%s' plugin is not enabled" plugin))))

(defun ditz-show-thing ()
  "Show current thing in another window."
  (cond ((or (ditz-current-buffer-p "todo")
	     (ditz-current-buffer-p "log")
	     (ditz-current-buffer-p "shortlog")
	     (ditz-current-buffer-p "grep")
	     (ditz-current-buffer-p "claimed")
	     (ditz-current-buffer-p "unclaimed")
	     (ditz-current-buffer-p "mine"))
	 (let ((issue-id (ditz-current-issue t)))
	   (when issue-id
	     (ditz-call-process "show" issue-id 'display-other))))
	((ditz-current-buffer-p "releases")
	 (let* ((release (ditz-current-release t))
		(args (ditz-todo-args release)))
	   (when release
	     (ditz-call-process "todo" args 'display-other))))))

(defun ditz-button-press (button)
  "Press button BUTTON to show an issue."
  (ditz-call-process "show" (button-label button) 'switch))

(defun ditz-buffer-name (cmd)
  "Return buffer name for command CMD."
  (let* ((issuedir (ditz-issue-directory))
	 (dir (file-name-directory issuedir)))
    (concat "*ditz-" cmd ": " dir "*")))

(defun ditz-current-buffer-p (cmd)
  "Return whether the current buffer has output of command CMD."
  (string= (buffer-name) (ditz-buffer-name cmd)))

;;;; Hooks.

(defvar ditz-mode-hook nil
  "*Hooks for Ditz major mode.")

;;;; Commands.

;; Prefix commands.
(defvar ditz-prefix (make-keymap)
  "*Prefix for Ditz commands.")

(define-key ditz-prefix "t" 'ditz-todo)
(define-key ditz-prefix "l" 'ditz-shortlog)
(define-key ditz-prefix "L" 'ditz-log)
(define-key ditz-prefix "s" 'ditz-grep)
(define-key ditz-prefix "r" 'ditz-show-releases)

(define-key ditz-prefix "c" 'ditz-show-claimed)
(define-key ditz-prefix "u" 'ditz-show-unclaimed)
(define-key ditz-prefix "m" 'ditz-show-mine)

(define-key ditz-prefix "g" 'ditz-html-generate)
(define-key ditz-prefix "b" 'ditz-html-browse)

;; Main commands.
(defvar ditz-mode-map (make-keymap)
  "*Keymap for Ditz major mode.")

(define-key ditz-mode-map "t" 'ditz-todo)
(define-key ditz-mode-map " " 'ditz-show)
(define-key ditz-mode-map "l" 'ditz-shortlog)
(define-key ditz-mode-map "L" 'ditz-log)
(define-key ditz-mode-map "s" 'ditz-grep)

(define-key ditz-mode-map "n" 'next-line)
(define-key ditz-mode-map "p" 'previous-line)

(define-key ditz-mode-map (kbd "TAB") 'ditz-next-thing)
(define-key ditz-mode-map (kbd "<backtab>") 'ditz-previous-thing)

(define-key ditz-mode-map "S" 'ditz-toggle-status)
(define-key ditz-mode-map "R" 'ditz-toggle-release)

(define-key ditz-mode-map "c" 'ditz-show-claimed)
(define-key ditz-mode-map "u" 'ditz-show-unclaimed)
(define-key ditz-mode-map "m" 'ditz-show-mine)

(define-key ditz-mode-map "g" 'ditz-reload)
(define-key ditz-mode-map "q" 'ditz-quit)
(define-key ditz-mode-map "Q" 'ditz-quit-all)

(define-key ditz-mode-map "!" 'ditz-command)
(define-key ditz-mode-map "o" 'delete-other-windows)
(define-key ditz-mode-map "?" 'describe-mode)

;; Issue commands.
(defvar ditz-issue-mode-map (make-keymap)
  "*Keymap for Ditz issue commands.")

(define-key ditz-mode-map "i" ditz-issue-mode-map)

(define-key ditz-issue-mode-map "n" 'ditz-add)
(define-key ditz-issue-mode-map "c" 'ditz-comment)
(define-key ditz-issue-mode-map "<" 'ditz-start)
(define-key ditz-issue-mode-map ">" 'ditz-stop)
(define-key ditz-issue-mode-map "(" 'ditz-claim)
(define-key ditz-issue-mode-map ")" 'ditz-unclaim)
(define-key ditz-issue-mode-map "a" 'ditz-assign)
(define-key ditz-issue-mode-map "u" 'ditz-unassign)
(define-key ditz-issue-mode-map "r" 'ditz-add-reference)
(define-key ditz-issue-mode-map "o" 'ditz-set-component)
(define-key ditz-issue-mode-map "e" 'ditz-edit)
(define-key ditz-issue-mode-map "C" 'ditz-close)
(define-key ditz-issue-mode-map "D" 'ditz-drop)

;; Release commands.
(defvar ditz-release-mode-map (make-keymap)
  "*Keymap for Ditz release commands.")

(define-key ditz-mode-map "r" ditz-release-mode-map)

(define-key ditz-release-mode-map "n" 'ditz-add-release)
(define-key ditz-release-mode-map "e" 'ditz-edit-project)
(define-key ditz-release-mode-map "r" 'ditz-release)
(define-key ditz-release-mode-map "s" 'ditz-status)
(define-key ditz-release-mode-map "c" 'ditz-changelog)
(define-key ditz-release-mode-map "l" 'ditz-show-releases)
(define-key ditz-release-mode-map "A" 'ditz-archive)

;; Config commands.
(defvar ditz-config-mode-map (make-keymap)
  "*Keymap for Ditz config commands.")

(define-key ditz-mode-map "f" ditz-config-mode-map)

(define-key ditz-config-mode-map "s" 'ditz-show-config)
(define-key ditz-config-mode-map "e" 'ditz-edit-config)

;; HTML commands.
(defvar ditz-html-mode-map (make-keymap)
  "*Keymap for Ditz HTML commands.")

(define-key ditz-mode-map "h" ditz-html-mode-map)

(define-key ditz-html-mode-map "g" 'ditz-html-generate)
(define-key ditz-html-mode-map "b" 'ditz-html-browse)

;;;; Easymenu.

(easy-menu-define ditz-mode-menu ditz-mode-map "Ditz mode menu"
 '("Ditz"
   ("Display"
    ["TODO list"                        ditz-todo t]
    ["Current issue"                    ditz-show t]
    ["Issues matching regexp"           ditz-grep t]
    "---"
    ["Short log"                        ditz-shortlog t]
    ["Detailed log"                     ditz-log t]
    "---"
    ["Claimed issues"                   ditz-show-claimed t]
    ["Unclaimed issues"                 ditz-show-unclaimed t]
    ["My issues"                        ditz-show-mine t]
    "---"
    ["Toggle issue status"              ditz-toggle-status t]
    ["Toggle release"         		ditz-toggle-release t])

   ("Issue"
    ["New"                              ditz-add t]
    ["Edit"                        	ditz-edit t]
    "---"
    ["Start working"            	ditz-start t]
    ["Stop working"             	ditz-stop t]
    "---"
    ["Add comment"                  	ditz-comment t]
    ["Add reference"            	ditz-add-reference t]
    ["Set component"          		ditz-set-component t]
    "---"
    ["Assign to release"           	ditz-assign t]
    ["Unassign"                    	ditz-unassign t]
    "---"
    ["Claim"		          	ditz-claim t]
    ["Unclaim"                    	ditz-unclaim t]
    "---"
    ["Close"                       	ditz-close t]
    ["Drop"                        	ditz-drop t])

   ("Release"
    ["New"                              ditz-add-release t]
    ["Edit"                             ditz-edit-project t]
    "---"
    ["Show status"                      ditz-status t]
    ["Show changelog"                   ditz-changelog t]
    ["Show all releases"                ditz-show-releases t]
    "---"
    ["Release"                          ditz-release t]
    ["Archive"                          ditz-archive t])

   ("HTML"
    ["Generate"                         ditz-html-generate t]
    ["Generate and browse"              ditz-html-browse t])

   ("Config"
    ["Show config file path"            ditz-show-config t]
    ["Edit config file"                 ditz-edit-config t])

   "---"
   ["Run command"			ditz-command t]
   ["Refresh"                           ditz-reload t]
   ["Quit"                              ditz-quit t]
   ["Quit all"             		ditz-quit-all t]))

;;;; Faces.

(defface ditz-issue-id-face
  '((((class color) (background light))
     (:foreground "blue" :weight bold))
    (((class color) (background dark))
     (:foreground "blue" :weight bold)))
  "Face definition for issue id."
  :group 'ditz)

(defface ditz-issue-attr-face
  '((((class color) (background light))
     (:foreground "steel blue" :weight bold))
    (((class color) (background dark))
     (:foreground "steel blue" :weight bold)))
  "Face definition for issue attribute."
  :group 'ditz)

(defface ditz-release-name-face
  '((((class color) (background light))
     (:foreground "red" :weight bold))
    (((class color) (background dark))
     (:foreground "red" :weight bold)))
  "Face definition for release name."
  :group 'ditz)

(defface ditz-comment-face
  '((((class color) (background light))
     (:foreground "dim gray" :slant italic))
    (((class color) (background dark))
     (:foreground "dim gray" :slant italic)))
  "Face definition for comments."
  :group 'ditz)

(defface ditz-issue-unstarted-face
  '((((class color) (background light))
     (:foreground "black"))
    (((class color) (background dark))
     (:foreground "black")))
  "Face definition for issue unstarted status."
  :group 'ditz)

(defface ditz-issue-progress-face
  '((((class color) (background light))
     (:foreground "black"))
    (((class color) (background dark))
     (:foreground "black")))
  "Face definition for issue in-progress status."
  :group 'ditz)

(defface ditz-issue-paused-face
  '((((class color) (background light))
     (:foreground "dark orange"))
    (((class color) (background dark))
     (:foreground "dark orange")))
  "Face definition for issue paused status."
  :group 'ditz)

(defface ditz-issue-fixed-face
  '((((class color) (background light))
     (:foreground "dark green"))
    (((class color) (background dark))
     (:foreground "dark green")))
  "Face definition for issue fixed status."
  :group 'ditz)

(defface ditz-issue-wontfix-face
  '((((class color) (background light))
     (:foreground "red"))
    (((class color) (background dark))
     (:foreground "red")))
  "Face definition for issue wontfix status."
  :group 'ditz)

(defface ditz-issue-reorg-face
  '((((class color) (background light))
     (:foreground "blue"))
    (((class color) (background dark))
     (:foreground "blue")))
  "Face definition for issue reorganized status."
  :group 'ditz)

(defface ditz-feature-face
  '((((class color) (background light))
     (:foreground "dark green"))
    (((class color) (background dark))
     (:foreground "dark green")))
  "Face definition for feature indicators."
  :group 'ditz)

(defface ditz-bug-face
  '((((class color) (background light))
     (:foreground "red"))
    (((class color) (background dark))
     (:foreground "red")))
  "Face definition for bug indicators."
  :group 'ditz)

(defconst ditz-issue-id-face 'ditz-issue-id-face)
(defconst ditz-issue-attr-face 'ditz-issue-attr-face)
(defconst ditz-release-name-face 'ditz-release-name-face)
(defconst ditz-comment-face 'ditz-comment-face)

(defconst ditz-issue-unstarted-face 'ditz-issue-unstarted-face)
(defconst ditz-issue-progress-face 'ditz-issue-progress-face)
(defconst ditz-issue-paused-face 'ditz-issue-paused-face)
(defconst ditz-issue-fixed-face 'ditz-issue-fixed-face)
(defconst ditz-issue-wontfix-face 'ditz-issue-wontfix-face)
(defconst ditz-issue-reorg-face 'ditz-issue-reorg-face)

(defconst ditz-feature-face 'ditz-feature-face)
(defconst ditz-bug-face 'ditz-bug-face)

(defconst ditz-font-lock-keywords
  `((,ditz-issue-attr-regex (1 ditz-issue-attr-face t))
    (,ditz-log-attr-regex (1 ditz-issue-attr-face t))

    (,ditz-comment-regex (1 ditz-comment-face t))
    (,ditz-issue-id-regex (1 ditz-issue-id-face t))
    (,ditz-release-name-regex (1 ditz-release-name-face t))

    (,ditz-issue-unstarted-regex (1 ditz-issue-unstarted-face t))
    (,ditz-issue-progress-regex (1 ditz-issue-progress-face t))
    (,ditz-issue-paused-regex (1 ditz-issue-paused-face t))
    (,ditz-issue-fixed-regex (1 ditz-issue-fixed-face t))
    (,ditz-issue-wontfix-regex (1 ditz-issue-wontfix-face t))
    (,ditz-issue-reorg-regex (1 ditz-issue-reorg-face t))

    (,ditz-feature-regex (1 ditz-feature-face t))
    (,ditz-bug-regex (1 ditz-bug-face t))))

;;;; Ditz major mode.

(define-derived-mode ditz-mode fundamental-mode "Ditz"
  "Major mode for the Ditz distributed issue tracker.

Ditz mode operates on directories that have already been
Ditz-enabled: i.e., 'ditz init' has already been run from the
command line.  After that, you can invoke 'ditz-todo' and get a
list of issues in a Ditz buffer.

See `ditz-issue-directory' for details on how the Ditz issue
directory is located.

Calling this function invokes the function(s) listed in
`ditz-mode-hook' before doing anything else.

\\{ditz-mode-map}
"
  :group 'ditz

  (interactive)
  (kill-all-local-variables)

  ;; Become the current major mode.
  (setq major-mode 'ditz-mode)
  (setq mode-name "Ditz")

  ;; Set readonly.
  (setq buffer-read-only t)

  ;; Set up font lock.
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(ditz-font-lock-keywords t))

  ;; Activate keymap.
  (use-local-map ditz-mode-map)

  ;; Create buttons for issues.
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward ditz-issue-id-regex nil t)
      (make-button (match-beginning 0) (match-end 0)
		   'action 'ditz-button-press
		   'help-echo "mouse-2, RET: show this issue")))

  ;; Run startup hooks.
  (run-hooks 'ditz-mode-hook))

(provide 'ditz-mode)
;;; ditz-mode.el ends here
