;;; terminal-here.el --- Run an external terminal in current directory -*- lexical-binding: t; -*-

;; Copyright © 2017-2020 David Shepherd

;; Author: David Shepherd <davidshepherd7@gmail.com>
;; Version: 2.0
;; Package-Version: 20210605.1453
;; Package-Commit: e0e89344624fadf080f6770132ebdd7991355fdd
;; Package-Requires: ((emacs "25.1"))
;; Keywords: tools, frames
;; URL: https://github.com/davidshepherd7/terminal-here


;;; Commentary:

;; Provides commands to help open external terminal emulators in the
;; directory of the current buffer.


;;; Code:

(require 'cl-lib)
(require 'subr-x)

;; TODO: it would be nice not to need to load all of tramp just for the file
;; name parsing. I'm not sure if that's possible though.
(require 'tramp)

;; TODO: readme updates, v2?

;; TODO ssh support on Mac OS?

;; TODO try to fix Konsole ssh



(defgroup terminal-here nil
  "Open external terminal emulators in current buffer's directory."
  :group 'external
  :prefix "terminal-here-")

(defun terminal-here--pick-linux-default ()
  "Inspect environment variables to try to figure out what kind of Linux this is and pick a sensible terminal."
  (let ((xdg-current-desktop (or (getenv "XDG_CURRENT_DESKTOP") ""))
        (desktop-session (or (getenv "DESKTOP_SESSION") "")))
    (cond
     ;; Try to guess from the wide range of "standard" environment variables!
     ;; Based on xdg_util.cc.
     ((equal xdg-current-desktop "Unity") 'gnome-terminal)
     ((equal xdg-current-desktop "GNOME") 'gnome-terminal)
     ((equal xdg-current-desktop "KDE") 'konsole)
     ((equal desktop-session "gnome") 'gnome-terminal)
     ((equal desktop-session "mate") 'gnome-terminal)
     ((equal desktop-session "kde4") 'konsole)
     ((equal desktop-session "kde-plasma") 'konsole)
     ((equal desktop-session "kde") 'konsole)
     ((equal desktop-session "xubuntu") 'xfce-terminal)
     ((string-match-p (regexp-quote "xfce") desktop-session) 'xfce-terminal)

     ;; We've failed, hopefully we're on a Debian-based OS so that we can use this
     ((executable-find "x-terminal-emulator") 'x-terminal-emulator))))

(defcustom terminal-here-linux-terminal-command
  (terminal-here--pick-linux-default)
  "Specification of the command to use to start a terminal on Linux.

If `terminal-here-terminal-command' is non-nil it overrides this
setting.

Common settings:
    gnome-terminal
    konsole
    xfce4-terminal
    terminator
    xterm
    urxvt
    st
    alacritty
    kitty
    tilix
    foot

Usually this variable should be one of the symbols listed above.

Alternatively to use a terminal which is not yet supported this
should be a list of strings representing the command line to run,
which will be passed to `start-process'.

For advanced use cases it can be a function which accepts a
launch directory and returns a list of strings to pass to
`start-process'."
  :group 'terminal-here
  :type '(choice (symbol)
                 (repeat string)
                 (function)))

(defcustom terminal-here-mac-terminal-command
  'terminal-app
  "Specification of the command to use to start a terminal on Mac OS X.

If `terminal-here-terminal-command' is non-nil it overrides this
setting.

Common settings:
    terminal-app
    iterm2
    alacritty
    kitty

Usually this variable should be one of the symbols listed above.

Alternatively to use a terminal which is not yet supported this
should be a list of strings representing the command line to run,
which will be passed to `start-process'.

For advanced use cases it can be a function which accepts a
launch directory and returns a list of strings to pass to
`start-process'."
  :group 'terminal-here
  :type '(choice (symbol)
                 (repeat string)
                 (function)))

(defcustom terminal-here-windows-terminal-command
  'cmd
  "Specification of the command to use to start a terminal on Windows.

If `terminal-here-terminal-command' is non-nil it overrides this
setting.

Common settings:
    cmd

Usually this variable should be one of the symbols listed above.

Alternatively to use a terminal which is not yet supported this
should be a list of strings representing the command line to run,
which will be passed to `start-process'.

For advanced use cases it can be a function which accepts a
launch directory and returns a list of strings to pass to
`start-process'."
  :group 'terminal-here
  :type '(choice (symbol)
                 (repeat string)
                 (function)))

(defcustom terminal-here-terminal-command
  nil
  "Specification of the command to use to start a terminal on all platforms.

If you use Emacs on multiple platforms with the same
configuration files you should normally use
`terminal-here-linux-terminal-command',
`terminal-here-mac-terminal-command', or
`terminal-here-windows-terminal-command' to configure this
instead in a platform specific way.

If non-nil this value overrides the platform-specific settings.



Usually this variable should be the symbol for a terminal, the
options are the keys of `terminal-here-terminal-command-table'.

Alternatively to use a terminal which is not in the table this
should be a list of strings representing the command line to run,
which will be passed to `start-process'.

For advanced use cases it can be a function which accepts a
launch directory and returns a list of strings to pass to
`start-process'."
  :group 'terminal-here
  :type '(choice (symbol)
                 (repeat string)
                 (function)))

(defcustom terminal-here-command-flag
  nil
  "The flag to tell your terminal to treat the rest of the line as a command to run.

You should not normally need to set this variable.

If this is nil then terminal-here will try to automatically look
up the flag for your terminal in
`terminal-here-command-flag-table'."
  :group 'terminal-here
  :type 'string)

(defcustom terminal-here-project-root-function
  nil
  "Function called to find the current project root directory.

If nil falls back to `projectile-project-root', (which requires
you install the `projectile' package), or `vc-root-dir' which is
available in Emacs >= 25.1.

The function should return nil or signal an error if the current
buffer is not in a project."
  :group 'terminal-here
  :type '(choice (const nil) function))


(defcustom terminal-here-terminal-command-table
  (list
   ;; Linux
   (cons 'urxvt               (list "urxvt"))
   (cons 'gnome-terminal      (list "gnome-terminal"))
   (cons 'alacritty           (list "alacritty"))
   (cons 'st                  #'terminal-here--find-and-run-st)
   (cons 'konsole             (list "konsole"))
   (cons 'xterm               (list "xterm"))
   (cons 'xfce4-terminal      (list "xfce4-terminal"))
   (cons 'terminator          (list "terminator"))
   (cons 'tilix               (list "tilix"))
   (cons 'kitty               (list "kitty"))
   (cons 'foot                (list "foot"))

   ;; A default which picks a terminal based on the system configuration on
   ;; Debian-based OSes (but doesn't work for other Linux OSes)
   (cons 'x-terminal-emulator (list "x-terminal-emulator"))

   ;; Mac OS
   (cons 'terminal-app        (list "Terminal.app"))
   (cons 'iterm2              (list "iTerm.app"))

   ;; Windows
   ;; From http://stackoverflow.com/a/13509208/874671
   (cons 'cmd                 (list "cmd.exe" "/C" "start" "cmd.exe")))
  "A table of terminal commands.

The keys should be symbols, the values should be either a list of
strings: (terminal-binary arg1 arg2 ...); or a function taking a
directory and returning such a list.

When you add a new entry here you should also add an entry to
`terminal-here-command-flag-table' if you want to use
terminal-here with tramp files to create ssh connections."
  :group 'terminal-here
  :type '(repeat (cons symbol
                       (choice (repeat string)
                               (function)))))

(defcustom terminal-here-command-flag-table
  (list
   (cons 'urxvt          "-e")
   (cons 'gnome-terminal "-x")
   (cons 'alacritty      "-e")
   (cons 'st             "-e")
   (cons 'konsole        "-e") ;; ssh seems to immediately exit with konsole
   (cons 'xterm          "-e")
   (cons 'xfce4-terminal "-x")
   (cons 'terminator     "-x")
   (cons 'tilix          "-e")
   (cons 'kitty          "--") ; kitty and foot don't need a special
   (cons 'foot           "--") ; flag for this, but we have to specify something.
   (cons 'x-terminal-emulator "-e") ; Actually this could be anything, but -e is
                                        ; the most common option.

   ;; I don't know how to do this on any Mac or Windows terminals! PRs please!
   )
  "A table of flags to tell terminals to use the rest of the line as a command to run.

If `terminal-here-command-flag' is set then it will be used
instead of this table."
  :group 'terminal-here
  :type '(repeat (cons symbol
                       (choice (repeat string)
                               (function)))))

(defvar terminal-here--verbose nil
  "Print commands before they are run.")



;;; Terminal command configuration

(defun terminal-here--non-function-symbol-p (x)
  (and (symbolp x) (not (functionp x))))

(defun terminal-here--per-os-command-table-p (x)
  (and (listp x)
       (consp (car x))
       (terminal-here--non-function-symbol-p (caar x))))

(defun terminal-here--os-terminal-command ()
  (or
   terminal-here-terminal-command
   (when (equal system-type 'gnu/linux) terminal-here-linux-terminal-command)
   (when (equal system-type 'darwin) terminal-here-mac-terminal-command)
   (when (or (equal system-type 'ms-dos)
             (equal system-type 'windows-nt)
             (equal system-type 'cygwin))
     terminal-here-windows-terminal-command)
   (user-error "No terminal configuration found for OS %s" system-type)))

(defun terminal-here--maybe-lookup-in-command-table (term-spec)
  (if (not (terminal-here--non-function-symbol-p term-spec))
      term-spec
    (let ((terminal-command (alist-get term-spec terminal-here-terminal-command-table)))
      (unless terminal-command
        (user-error "No settings found for terminal %s in `terminal-here-terminal-command-table'" term-spec))
      terminal-command)))

(defun terminal-here--maybe-funcall (dir x)
  (if (not (functionp x))
      x
    (funcall x dir)))

(defun terminal-here--maybe-add-mac-os-open (command)
  "On Mac OS we use the open command to run the terminal in `default-directory'."
  (if (and (equal system-type 'darwin)
           (not (equal (car command) "open")))
      (append (list "open" "-a" (car command) "." "--args") (cdr command))
    command))

(defun terminal-here--get-terminal-command (dir)
  (thread-last (terminal-here--os-terminal-command)
    (terminal-here--maybe-lookup-in-command-table)
    (terminal-here--maybe-funcall dir)
    (terminal-here--maybe-add-mac-os-open)))

(defun terminal-here--get-command-flag ()
  (or
   terminal-here-command-flag
   (let ((term-spec (terminal-here--os-terminal-command)))
     (when (terminal-here--non-function-symbol-p term-spec)
       (let ((flag (alist-get term-spec terminal-here-command-flag-table)))
         (unless flag
           (user-error "No flag settings found for terminal %s in `terminal-here-command-flag-table'" term-spec))
         flag)))
   (user-error "Couldn't work out how to run an ssh command in your terminal, customize `terminal-here-command-flag' or set `terminal-here-terminal-command' to specify your terminal by symbol")))

(defun terminal-here--term-command (dir)
  (let ((ssh-data (terminal-here--parse-ssh-dir dir)))
    (if ssh-data
        (terminal-here--ssh-command (car ssh-data) (cadr ssh-data))
      (terminal-here--get-terminal-command dir))))



;;; Individual terminals

(defun terminal-here--find-and-run-st (_)
  "Suckless term can either be called st or stterm depending on how it was installed."
  (if (executable-find "stterm") '("stterm") '("st")))



;;; Tramp/ssh support

(defun terminal-here--parse-ssh-dir (dir)
  (when (string-prefix-p "/ssh:" dir)
    (with-parsed-tramp-file-name dir nil
      (list (if user (concat user "@" host) host) localname))))

(defun terminal-here--ssh-command (remote dir)
  (append (terminal-here--term-command "") (list (terminal-here--get-command-flag) "ssh" "-t" remote
                                    "cd" (shell-quote-argument dir) "&&" "exec" "$SHELL" "-")))

(defun terminal-here-maybe-tramp-path-to-directory (dir)
  "Extract the local part of a local tramp path.

Given a tramp path returns the local part, otherwise returns
nil."
  (when (tramp-tramp-file-p dir)
    (let ((file-name-struct (tramp-dissect-file-name dir)))
      (cond
       ;; sudo: just strip the extra tramp stuff
       ((equal (tramp-file-name-method file-name-struct) "sudo")
        (tramp-file-name-localname file-name-struct))
       ;; ssh: run with a custom command handled later
       ((equal (tramp-file-name-method file-name-struct) "ssh") dir)
       (t (user-error "Terminal here cannot currently handle tramp files other than sudo and ssh"))))))




;;; Launching

(defun terminal-here-launch-in-directory (dir)
  "Launch a terminal in directory DIR.

Handles tramp paths sensibly."
  (terminal-here--run-command (terminal-here--term-command dir)
                 (or (terminal-here-maybe-tramp-path-to-directory dir) dir)))

(defun terminal-here--run-command (command dir)
  (when terminal-here--verbose
    (message "Running %s with default-directory %s" command dir))
  (let* ((default-directory dir)
         (process-name (car command))
         (proc (apply #'start-process process-name nil command)))
    (set-process-sentinel
     proc
     (lambda (proc _)
       (when (and (eq (process-status proc) 'exit) (/= (process-exit-status proc) 0))
         (message "Error: in terminal here, command `%s` exited with error code %d"
                  (mapconcat #'identity command " ")
                  (process-exit-status proc)))))
    ;; Don't close when emacs closes, seems to only be necessary on Windows.
    (set-process-query-on-exit-flag proc nil)))

;;;###autoload
(defun terminal-here-launch ()
  "Launch a terminal in the current working directory.

This is the directory of the current buffer unless you have
changed it by running `cd'."
  (interactive)
  (terminal-here-launch-in-directory default-directory))

;;;###autoload
(defalias 'terminal-here 'terminal-here-launch)

;;;###autoload
(defun terminal-here-project-launch ()
  "Launch a terminal in the current project root.

Uses `terminal-here-project-root-function' to determine the
project root."
  (interactive)
  (let* ((real-project-root-function
          (or terminal-here-project-root-function
              (cl-find-if #'fboundp (list 'projectile-project-root 'vc-root-dir))
              (user-error "No `terminal-here-project-root-function' is set and no default could be picked")))
         (root (funcall real-project-root-function)))
    (when (not root)
      (user-error "Not in any project according to `terminal-here-project-root-function'"))
    (terminal-here-launch-in-directory root)))



(provide 'terminal-here)

;;; terminal-here.el ends here


;; Handy code for re-evaluating configuration after adding a new terminal

;; (validate-setq terminal-here-terminal-command nil)
;; (validate-setq terminal-here-linux-terminal-command 'kitty)

;; (defun ds/custom-reset-var (symbl)
;;   "Reset SYMBL to its standard value."
;;   (set symbl (eval (car (get symbl 'standard-value)))))
;; (ds/custom-reset-var 'terminal-here-terminal-command-table)
;; (ds/custom-reset-var 'terminal-here-command-flag-table)
