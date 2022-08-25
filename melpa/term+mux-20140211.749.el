;;; term+mux.el --- term+ terminal multiplexer and session management

;; Author: INA Lintaro <tarao.gnn at gmail.com>
;; URL: http://github.com/tarao/term+-el
;; Package-Version: 20140211.749
;; Package-Commit: 81b60e80cf008472bfd7fad9233af2ef722c208a
;; Version: 0.1
;; Keywords: terminal, emulation
;; Package-Requires: ((term+ "0.1") (tab-group "0.1"))

;; This file is NOT part of GNU Emacs.

;;; License:
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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'term+)
(require 'tab-group)
(require 'tramp)
(eval-when-compile (require 'cl))


;;; protocols

(term+new-protocol "mux")
(term+new-control-command "\033k" term+-st 'term+mux-set-title)
(term+new-control-command "\033]2;" term+-st 'term+mux-set-title)
(term+new-control-command "\033]0;" term+-bel 'term+mux-set-title)
(term+new-control-command (term+osc-emacs "cdd") term+-st 'term+mux-cdd)


;;; customization

(defgroup term+mux nil
  "Terminal multiplexer for `term' command."
  :prefix "term+mux-"
  :group 'term+)

(defcustom term+mux-char-prefix "C-t"
  "Prefix for the tab related keymap in `term-char-mode'.
This variable must be set before loading term+mux.el."
  :type '(choice string vector)
  :group 'term+mux)

(defcustom term+mux-line-prefix "C-x t"
  "Prefix for the tab related keymap activated in `term-line-mode'.
This variable must be set before loading term+mux.el."
  :type '(choice string vector)
  :group 'term+mux)

(defcustom term+mux-session-buffer t
  "List session names in the buffer list rather than session
tabs."
  :type 'boolean
  :group 'term+mux)

(defcustom term+mux-mode-line-tabbar t
  "Show tabbar at mode line.
If the terminal is in `term-line-mode', the tabbar will appear
just after the ordinary mode line."
  :type 'boolean
  :group 'term+mux)

(defcustom term+mux-local-shell-command nil
  "Command and arguments in a list to run shell at localhost.
The value can be either nil or a list whose element is either a
string, a symbol, or a list of constant `quote' and a string or a
symbol.

nil means to use either one of the value of `shell-filename',
environment variable \"SHELL\" or \"ESHELL\", or to ask user for
the command path if none of these has value.

If an element of the list is a string, it is used as a command or
an argument.

If an element of the list is a symbol, either the symbol's value,
a return value of the symbol's function, or name of the symbol is
used as a command or an argument.  Possible builtin symbol names
and their values are:

user          user name of the current session
host          host name of the current session
user-at-host  user name and host name in \"user@host\" form
              (possibly \"user@\" is dropped if it is omitted)
command       command specified by the user

If an element is a pair of `quote' and another string or symbol,
an command or an argument described by the string or symbol is
quoted by `shell-quote-argument'."
  :type '(list (choice string symbol
                       (cons (const quote) (list (choice string symbol)))))
  :group 'term+mux)

(defcustom term+mux-local-command '(command)
  "Command and arguments in a list to run command at localhost.
The value can be a list whose element is either a string, a
symbol, or a list of constant `quote' and a string or a symbol.
See `term+mux-local-shell-command' for the meaning of the
elements of the list.  The list should include builtin symbol
name `command' to get command name specified by the user."
  :type '(list (choice string symbol
                       (cons (const quote) (list (choice string symbol)))))
  :group 'term+mux)

(defcustom term+mux-remote-shell-command '(term+mux-ssh-shell-command)
  "Command and arguments in a list to run shell at remote host.
The value can be a list whose element is either a string, a
symbol, or a list of constant `quote' and a string or a symbol.
See `term+mux-local-shell-command' for the meaning of the
elements of the list.

The default value is a list containing
`term+mux-ssh-shell-command', which is a function to make
appropriate ssh command for remote access with `term+mux-ssh-*'
customization variables.  To specify your own ssh options and
ignore `term+mux-ssh-*' ones, use '(ssh \"your\" \"options\"
user-at-host) form."
  :type '(list (choice string symbol
                       (cons (const quote) (list (choice string symbol)))))
  :group 'term+mux)
(defcustom term+mux-remote-command '(term+mux-ssh-command)
  "Command and arguments in a list to run command at remote host.
The value can be a list whose element is either a string, a
symbol, or a list of constant `quote' and a string or a symbol.
See `term+mux-local-shell-command' for the meaning of the
elements of the list.

The default value is a list containing `term+mux-ssh-command',
which is a function to make appropriate ssh command for remote
access with `term+mux-ssh-*' customization variables.  To specify
your own ssh options and ignore `term+mux-ssh-*' ones, use '(ssh
\"your\" \"options\" user-at-host command) form."
  :type '(list (choice string symbol
                       (cons (const quote) (list (choice string symbol)))))
  :group 'term+mux)

(defcustom term+mux-su-shell-command '(term+mux-sudo-shell-command)
  "Command and arguments in a list to run shell as another user.
The value can be a list whose element is either a string, a
symbol, or a list of constant `quote' and a string or a symbol.
See `term+mux-local-shell-command' for the meaning of the
elements of the list.

The default value is a list containing
`term+mux-sudo-shell-command', which is a function to make
appropriate sudo command for the user with
`term+mux-sudo-options' customization variables.  To specify your
own sudo options and ignore `term+mux-sudo-options' ones, use
'(sudo \"-u\" user \"your\" \"options\" command) form."
  :type '(list (choice string symbol
                       (cons (const quote) (list (choice string symbol)))))
  :group 'term+mux)

(defcustom term+mux-su-command '(term+mux-sudo-command)
  "Command and arguments in a list to run command as another user.
The value can be a list whose element is either a string, a
symbol, or a list of constant `quote' and a string or a symbol.
See `term+mux-local-shell-command' for the meaning of the
elements of the list.  The list should include builtin symbol
name `command' to get command name specified by the user.

The default value is a list containing `term+mux-sudo-command',
which is a function to make appropriate sudo command for the user
with `term+mux-sudo-options' customization variables.  To specify
your own sudo options and ignore `term+mux-sudo-options' ones,
use '(sudo \"-u\" user \"your\" \"options\" command) form."
  :type '(list (choice string symbol
                       (cons (const quote) (list (choice string symbol)))))
  :group 'term+mux)

(defcustom term+mux-user-complete-method 'term+mux-su-shell-command
  "Method name used for completing user names.
The value can be either a string or a symbol.  If the value is a
string, then it is the method name.  If the value is a symbol,
then its value is first treated in the same way as
`term+mux-local-shell-command' then the first element of the
resulting value is the method name.

The method name is passed to `tramp-get-completion-function' to
retrieve completion functions."
  :type '(choice symbol string)
  :group 'term+mux)

(defcustom term+mux-host-complete-method 'term+mux-remote-shell-command
  "Method name used for completing host names.
See `term+mux-user-complete-method' for the detail."
  :type '(choice symbol string)
  :group 'term+mux)

(defcustom term+mux-ssh-options '("-t")
  "Option passed to ssh command made by
`term+mux-ssh-shell-command' or `term+mux-ssh-command'"
  :type '(list (choice string symbol))
  :group 'term+mux)

(defcustom term+mux-ssh-forward-x 'auto
  "t means to enable ssh X forwarding.  `auto' means to enable
ssh X forwarding only when the current environment has valid X
connection.  Other values mean to disable ssh X forwarding."
  :type '(choice boolean (const auto))
  :group 'term+mux)

(defcustom term+mux-ssh-control-master nil
  "t means to enable ControlMaster, ControlPath and
ControlPersist options for ssh connections.  These options are
enabled only when the ssh client supports ControlPersist option."
  :type 'boolean
  :group 'term+mux)

(defcustom term+mux-ssh-control-path "~/.ssh/emacs-term+mux-%r@%h:%p"
  "Path passed to ControlPath option for ssh connections."
  :type 'string
  :group 'term+mux)

(defcustom term+mux-ssh-control-persist 10
  "Value passed to ControlPersist option for ssh connections."
  :type '(choice boolean number)
  :group 'term+mux)

(defcustom term+mux-sudo-options '()
  "Option passed to sudo command made by
`term+mux-sudo-shell-command' or `term+mux-sudo-command'"
  :type '(list (choice string symbol))
  :group 'term+mux)

(defconst term+mux-command-template
  (list "/bin/sh" "-c"
        (mapconcat #'identity
                   `(,(format "INSIDE_EMACS=%s,term:%s"
                              emacs-version term-protocol-version)
                     "export INSIDE_EMACS" "%s")
                   "; "))
  "Template for shell/command dealing with environment passing.")

(defcustom term+mux-shell-exec
  (mapconcat
   #'identity
   `("uid=`id -run`"
     ;; find login shell for the user
     "shell=`grep \"^$uid:\" /etc/passwd | cut -f 7 -d :`"
     ,(concat
       ;; we need to call `getpwnam' system call (via perl builtin function)
       ;; since the user's passwd entry is specified by NIS or LDAP
       "[ -z \"$shell\" ] && type perl >/dev/null && "
       "shell=`perl -le\"@_=getpwnam(\\\"$uid\\\");print\\\\$_[8]\"`")
     ;; use /bin/sh if no login shell is found
     "[ -z \"$shell\" ] && shell=/bin/sh"
     ;; the shell should accept -l option -- run shell as login shell
     "exec \"$shell\" -l")
   "; ")
  "Shell script to run the login shell.
This variable is used in `term+mux-ssh-shell-command' and
`term+mux-sudo-shell-command' as a part of an sh script, where we
need to exec the login shell binary in the script.  Thus, we need
to find user's login shell from an user account database for
example /etc/passwd.  Since the database may be stored in such as
NIS servers or LDAP servers, we need to call getpwnam(3).  By
default, perl interpreter interfaces between the sh script and
getpwnam(3)."
  :type '(choice string (list (choice string symbol)))
  :group 'term+mux)

(defcustom term+mux-command-exec '("exec" command)
  "Shell script to run a command.
This variable is used in `term+mux-ssh-command' and
`term+mux-sudo-command' as a part of an sh script."
  :type '(choice string (list (choice string symbol)))
  :group 'term+mux)


;;; keymap

(defvar term+mux-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tab-group:keymap)
    (define-key map (kbd "N") #'term+mux-new)
    (define-key map (kbd "c") #'term+mux-new)
    (define-key map (kbd "o") #'term+mux-other-window)
    (define-key map (kbd "O") #'term+mux-new-other-window)
    (define-key map (kbd "C") #'term+mux-new-command)
    (define-key map (kbd "S") #'term+mux-new-session)
    (define-key map (kbd "R") #'term+mux-remote-session)
    (define-key map (kbd "r") #'term+mux-set-title)
    (define-key map (kbd "t") #'term+mux-set-title)
    (define-key map (kbd "u") #'term+mux-unset-title)
    map))

(defmacro term+mux-with-prefix (bind &rest body)
  (declare (indent 1))
  (let ((var (nth 0 bind)) (pref (nth 1 bind)))
    `(let* ((,var ,pref) (,var (if (stringp ,var) (read-kbd-macro ,var) ,var)))
       ,@body)))
(when term+mux-char-prefix
  (term+mux-with-prefix (prefix term+mux-char-prefix)
    (define-key term+char-map prefix term+mux-map)))
(when term+mux-line-prefix
  (term+mux-with-prefix (prefix term+mux-line-prefix)
    (define-key term+line-map prefix term+mux-map)))


;;; internals

(defvar term+mux-sessions nil)
(defvar term+mux-default-session)
(defvar term+mux-default-user nil)
(defvar term+mux-default-host (term+system-name))
(defvar term+mux-default-name nil)
(defvar term+mux-default-command nil)
(defvar term+mux-read-user-history nil)
(defvar term+mux-read-host-history nil)
(defvar term+mux-read-name-history nil)
(defvar term+mux-read-command-history nil)
(defvar term+mux-session-name-function 'term+mux-session-name)
(defvar term+mux-ssh-control-persist-enabled nil)
(defvar term+mux-cdd-overlay nil)

(defvar term+mux-original-mode-line-format nil)
(make-variable-buffer-local 'term+mux-original-mode-line-format)
(defvar term+mux-tabbar-width nil)
(make-variable-buffer-local 'term+mux-tabbar-width)
(defvar term+mux-saved-auto-title nil)
(make-variable-buffer-local 'term+mux-saved-auto-title)

(defstruct (term+mux-session (:constructor term+mux-make-session))
  group user host)
(defsubst term+mux-session (s)
  (if (term+mux-session-p s) s (cdr (assoc s term+mux-sessions))))
(defsubst term+mux-current-session ()
  (let* ((group (tab-group:current-group))
         (name (and group (tab-group:group-name group))))
    (and name (term+mux-session name))))
(defmacro term+mux-session-as-group (session &optional method)
  (let* ((method (if (listp method) method (list method)))
         (fun (mapconcat #'symbol-name (list* 'tab-group:group method) "-")))
    `(let ((session (or ,session (term+mux-current-session))))
       (,(intern fun) (term+mux-session-group (term+mux-session session))))))
(defsubst term+mux-session-buffers (&optional session)
  (mapcar #'tab-group:tab-buffer (term+mux-session-as-group session tabs)))
(defsubst term+mux-session-local-p (session)
  (let ((host (term+mux-session-host session)))
    (term+local-host-p host)))

(defsubst term+mux-prefix-arg-twice-p ()
  (or (and (natnump (car-safe current-prefix-arg))
           (< 4 (car current-prefix-arg)))
      (and (natnump current-prefix-arg)
           (< 1 current-prefix-arg))))

(defun term+mux-read-string (what)
  (let* ((what (symbol-name what))
         (default (symbol-value (intern (concat "term+mux-default-" what))))
         (history (intern (concat "term+mux-read-" what "-history")))
         (prompt (if default
                     (format "%s (default: %s): " (capitalize what) default)
                   (format "%s: " (capitalize what))))
         (completer (intern (concat "term+mux-complete-" what)))
         (collection (and (fboundp completer) (funcall completer)))
         (args (list prompt collection nil nil nil history (or default 'null)))
         (reply (if collection
                    (apply 'completing-read args)
                  (read-string prompt nil history (or default 'null)))))
    (and (not (eq reply 'null)) reply)))

(defun term+mux-session-name (user host)
  (cond
   ((term+local-user-p user) (term+shorten-hostname host))
   ((term+mux-session-local-p (term+mux-make-session :user user :host host))
    user)
   (t (format "%s@%s" user (term+shorten-hostname host)))))


;;; command to start

(defsubst term+mux-shell-command ()
  (or term+mux-local-shell-command
      (split-string-and-unquote
       (or
        shell-file-name
        (getenv "SHELL")
        (getenv "ESHELL")
        (read-string "Shell: " "/bin/sh")))))

(defun term+mux-resolve-arg (session command arg)
  (let* ((user (term+mux-session-user session))
         (host (term+mux-session-host session))
         (user-at-host (or (and (term+local-user-p user) host)
                           (format "%s@%s" user host)))
         (user (or user (user-real-login-name))))
  (cond
   ((and (symbolp arg) (boundp arg)) (symbol-value arg))
   ((and (symbolp arg) (fboundp arg))
    (let ((args (funcall arg session command)))
      (term+mux-resolve-args session command args)))
   ((symbolp arg) (symbol-name arg))
   ((and (listp arg) (eq (car arg) 'quote))
    (let ((arg (term+mux-resolve-arg session command (cadr arg))))
      (shell-quote-argument (if (listp arg) (mapconcat #'identity arg " ")))))
   (t arg))))

(defun term+mux-resolve-args (session command args)
  (let (result)
    (while args
      (let ((arg (term+mux-resolve-arg session command (car args))))
        (setq result (append result (if (listp arg) arg (list arg)))))
      (setq args (cdr args)))
    result))

(defun term+mux-resolve-command (session command)
  (let* ((cmd command)
         (shell (eq cmd 'shell))
         (term+mux-local-shell-command
          (or term+mux-local-shell-command (term+mux-shell-command)))
         (local (term+mux-session-local-p session))
         (user (term+mux-session-user session))
         (dispatch
          (cond ((and local (term+local-user-p user)) 'local)
                (local 'su)
                (t 'remote)))
         args)
    (setq dispatch (concat "term+mux-" (symbol-name dispatch))
          dispatch (concat dispatch (if shell "-shell" "") "-command")
          args (symbol-value (intern dispatch))
          args (if (listp args) args (list args))
          command nil
          cmd (if shell nil (split-string-and-unquote cmd)))
    (term+mux-resolve-args session cmd args)))


;;; ssh

(defun term+mux-x-available-p ()
  (condition-case nil
      (let ((display (or x-display-name (getenv "DISPLAY"))))
        (and (stringp display) (> (length display) 0)
             (or (x-open-connection display) (x-close-connection display) t)))
    (error nil)))

(defun term+mux-ssh-control-persist-enabled-p ()
  (unless term+mux-ssh-control-persist-enabled ; cache
    (setq term+mux-ssh-control-persist-enabled
          (if (ignore-errors
                (with-temp-buffer
                  (call-process "ssh" nil t nil "-o" "ControlPersist")
                  (goto-char (point-min))
                  (search-forward-regexp
                   "Missing ControlPersist argument" nil t)))
              1 0)))
  (= term+mux-ssh-control-persist-enabled 1))

(defun term+mux-ssh-make-command (session command exec)
  (let* ((ssh (copy-sequence (list* "ssh" term+mux-ssh-options)))
         (exec (if (listp exec)
                   (mapconcat #'shell-quote-argument
                              (term+mux-resolve-args session command exec)
                              " ")
                 exec))
         (cmd (mapconcat #'(lambda (x) (shell-quote-argument (format x exec)))
                         term+mux-command-template " "))
         (args (list 'user-at-host cmd))
         (persist term+mux-ssh-control-persist))
    (if (or (eq term+mux-ssh-forward-x t)
            (and (eq term+mux-ssh-forward-x 'auto)
                 (term+mux-x-available-p)))
        (nconc ssh (copy-sequence '("-X"))))
    (if (and term+mux-ssh-control-master
             (term+mux-ssh-control-persist-enabled-p))
        (nconc ssh
               (list* "-o" "ControlMaster auto"
                      "-o" (concat "ControlPath " term+mux-ssh-control-path)
                      "-o" (concat "ControlPersist "
                                   (if (numberp persist)
                                       (number-to-string persist)
                                     (if persist "yes" "no")))
                      args))
      (nconc ssh args))))

(defun term+mux-ssh-shell-command (session command)
  "Make ssh command line to open shell in a host specified in SESSION.
The argument COMMAND is ignored.

This function considers four things than just making a command as
\"ssh user@host\":
- it sets \"INSIDE_EMACS\" environment variable in the remote shell,
- it passes options specified by `term+mux-ssh-options' to the ssh command,
- it passes \"-X\" option according to `term+mux-ssh-forward-x', and,
- it passes Control* options according to
  `term+mux-ssh-control-master', `term+mux-ssh-control-path' and
  `term+mux-ssh-control-persist'.

To set \"INSIDE_EMACS\" environment variable in the remote shell
regardless of AcceptEnv and PermitUserEnvironment in sshd_config
and SendEnv in ssh_config, we run an sh script instead of the
remote login shell, which sets the environment variable and runs
login shell.  The sh script is specified as
`term+mux-command-template', which has a place holder \"%s\" to
specify an execution of the login shell or a non-shell program.
The value of `term+mux-shell-exec' is used for the execution code
of the login shell."
  (term+mux-ssh-make-command session command term+mux-shell-exec))

(defun term+mux-ssh-command (session command)
  "Make ssh command line to run COMMAND in a host specified in
SESSION.

Like `term+mux-ssh-shell-command', this function considers some
other things than just making a command as \"ssh user@host
COMMAND\".  See `term+mux-ssh-shell-command' for the detail.
This function passes `term+mux-command-exec' to
`term+mux-command-template'."
  (term+mux-ssh-make-command session command term+mux-command-exec))


;;; sudo

(defun term+mux-sudo-make-command (session command exec)
  (let* ((sudo (copy-sequence (list* "sudo" term+mux-sudo-options)))
         (exec (if (listp exec)
                   (mapconcat #'shell-quote-argument
                              (term+mux-resolve-args session command exec)
                              " ")
                 exec))
         (cmd (mapcar #'(lambda (x) (format x exec)) term+mux-command-template))
         (args (list* "-u" 'user cmd)))
      (nconc sudo args)))

(defun term+mux-sudo-shell-command (session command)
  "Make sudo command line to open shell as another user specified in SESSION.
The argument COMMAND is ignored.

This function considers two things than just making a command as
\"sudo -u user -s\":
- it sets \"INSIDE_EMACS\" environment variable in the remote shell, and,
- it passes options specified by `term+mux-sudo-options' to the ssh command.

The sh script is specified as `term+mux-command-template', which
has a place holder \"%s\" to specify an execution of the login
shell or a non-shell program.  The value of `term+mux-shell-exec'
is used for the execution code of the login shell."
  (term+mux-sudo-make-command session command term+mux-shell-exec))

(defun term+mux-sudo-command (session command)
  "Make sudo command line to run COMMAND as another user specified in SESSION.

Like `term+mux-sudo-shell-command', this function considers some
other things than just making a command as \"sudo -u user
COMMAND\".  See `term+mux-sudo-shell-command' for the detail.
This function passes `term+mux-command-exec' to
`term+mux-command-template'."
  (term+mux-sudo-make-command session command term+mux-command-exec))


;;; user and host completion

(defun term+mux-complete-method (method)
  (if (stringp method)
      method
    (let* ((args (symbol-value method))
           (args (if (listp args) args (list args)))
           (command (term+mux-resolve-args (term+mux-make-session) "" args)))
      (if (listp command) (car command) command))))

(defun term+mux-tramp-complete (method)
  (let* ((method (term+mux-complete-method method))
         (completers (tramp-get-completion-function method))
         collection)
    (dolist (elt completers)
      (setq collection (append collection (apply (car elt) (cdr elt)))))
    collection))

(defun term+mux-complete-user ()
  (let* ((method term+mux-user-complete-method)
         (tramp-current-user ".") ; for tramp-parse-passwd to list all users
         (users (mapcar #'car-safe (term+mux-tramp-complete method))))
    (append (list (user-real-login-name)) (remove nil users))))

(defun term+mux-complete-host ()
  (let* ((method term+mux-host-complete-method)
         (hosts (mapcar #'cdr (term+mux-tramp-complete method))))
    (append (list (term+system-name)) (remove nil (mapcar #'car-safe hosts)))))


;;; buffer and session

(defun term+mux-make-term-buffer (session name command)
  (let ((buffer (generate-new-buffer name))
        (program (car command)) (args (cdr command))
        (user (term+mux-session-user session))
        (host (term+mux-session-host session)))
    (with-current-buffer buffer
      (term-mode)
      (setq term-ansi-at-user user)
      (setq term-ansi-at-host host))
    (term-exec buffer name program nil args)
    (with-current-buffer buffer (term-char-mode))
    buffer))

(defun term+mux-remove-session (session)
  (let* ((group (term+mux-session-group session))
         (elt (assoc (tab-group:group-name group) term+mux-sessions)))
    (setq term+mux-sessions (delq elt term+mux-sessions))
    (when (eq (tab-group:get 'term+mux-session group) session)
      (tab-group:remove group))))

(defun term+mux-maybe-remove-session (&optional session)
  (let* ((session (or session (term+mux-current-session)))
         (buffers (and session (term+mux-session-buffers session))))
    (when (and session (not (eq session term+mux-default-session))
               (= (length buffers) 1) (eq (car buffers) (current-buffer)))
      (term+mux-remove-session session))))


;;; tabbar at mode line

(defun term+mux-mode-line-tabbar-edit ()
  (tab-group:restore-tabbar)
  (if term+edit-mode
      (progn
        (set (make-local-variable 'tab-group:tabbar-width)
             term+mux-tabbar-width)
        (set (make-local-variable 'tab-group:show-tabbar) 'manual))
    (kill-local-variable 'tab-group:tabbar-width)
    (set (make-local-variable 'tab-group:show-tabbar) 'mode-line))
  (when tab-group:current-tab
    (setq tab-group:last-scroll-pos nil)
    (tab-group:show-tabbar)
    (tab-group:select tab-group:current-tab)))

(defun term+mux-mode-line-tabbar-indirect-buffer-setup ()
  (let ((base-buffer (buffer-base-buffer)))
    (when (and term+input-mode base-buffer)
      (let (mlf hlf tabbar tabbar-width tab-sym tab-label current-tab)
        (with-current-buffer base-buffer
          (setq mlf mode-line-format
                hlf header-line-format
                tabbar tab-group:tabbar
                tabbar-width tab-group:tabbar-width)
          (when tab-group:current-tab
            (setq current-tab tab-group:current-tab
                  tab-sym (tab-group:tab-tab tab-group:current-tab)
                  tab-label (symbol-value tab-sym))))
        (setq mode-line-format mlf
              header-line-format hlf
              tab-group:tabbar tabbar)
        (set (make-local-variable 'tab-group:tabbar-width) tabbar-width)
        (when current-tab
          (setq tab-group:current-tab current-tab)
          (set (make-local-variable tab-sym) tab-label))))))
(add-hook 'term+input-mode-hook
          #'term+mux-mode-line-tabbar-indirect-buffer-setup)

(define-minor-mode term+mux-mode-line-tabbar-mode
  "Show tabbar at mode line."
  :group 'term+mux
  (if term+mux-mode-line-tabbar-mode
      ;; on
      (progn
        (setq term+mux-original-mode-line-format
              mode-line-format)
        (setq term+mux-tabbar-width
              (max (- (tab-group:window-total-width)
                      (tab-group:format-width (butlast mode-line-format))) 1))
        (setq mode-line-format
              (append (butlast mode-line-format)
                      (list 'tab-group:tabbar)
                      (last mode-line-format)))
        (set (make-local-variable 'tab-group:show-tabbar) 'mode-line)
        (add-hook 'term+edit-mode-hook
                  #'term+mux-mode-line-tabbar-edit nil t)
        (when tab-group:current-tab (tab-group:show-tabbar)))
    ;;off
    (tab-group:restore-tabbar)
    (setq mode-line-format term+mux-original-mode-line-format)
    (remove-hook 'term+edit-mode-hook 'term+mux-mode-line-tabbar-edit t)))


;;; commands

(defun term+mux-noselect (&optional session name command)
  "Open a new terminal as a new tab without selecting the tab.
See `term+mux-new' for the detail."
  (interactive
   (let* ((session
           (or (and (or (not current-prefix-arg)
                        (not (term+mux-prefix-arg-twice-p)))
                    (or (term+mux-current-session)
                        (and (= (length term+mux-sessions) 1)
                             term+mux-default-session)))
               (completing-read "Session: " term+mux-sessions
                                nil nil nil nil term+mux-default-session)))
          (term+mux-default-command 'shell)
          (command (and current-prefix-arg (term+mux-read-string 'command)))
          (term+mux-default-name (or term+mux-default-name command))
          (name (and current-prefix-arg (term+mux-read-string 'name))))
     (list session name command)))
  (when (and (stringp session) (not (term+mux-session session)))
    (error (format "No session `%s' is found" session)))
  (setq session (term+mux-session (or session term+mux-default-session)))
  (let* ((group (term+mux-session-group session))
         (command (or command 'shell))
         (name (format "%s" (or name command "term")))
         (command (term+mux-resolve-command session command))
         (buffer (term+mux-make-term-buffer session name command)))
    (tab-group:select
     (with-current-buffer buffer
       (when term+mux-mode-line-tabbar (term+mux-mode-line-tabbar-mode 1))
       (add-hook 'tab-group:local-mode-exit-hook
                 #'term+mux-maybe-remove-session nil t)
       (tab-group:new-tab name buffer group))
     t)))

(defun term+mux-new (&optional session name command)
  "Open a new terminal in SESSION as a new tab, optionaly
specifying NAME as a name of the tab and running COMMAND.

If SESSION is omitted, a default local session (a session with
the local user and the local host) is used.  If NAME is omitted,
the name of COMMAND is used.  If COMMAND is omitted, it runs a
shell.

When called interactively, ask only SESSION with no prefix
argument, or ask SESSION, COMMAND, NAME with some prefix
arguments."
  (interactive)
  (tab-group:select (if (called-interactively-p 'any)
                        (call-interactively 'term+mux-noselect)
                      (term+mux-noselect session name command))))

(defun term+mux-new-other-window (&optional session name command)
  "Open a new terminal as a new tab in the other window.
See `term+mux-new' for the detail."
  (interactive)
  (let ((tab (if (called-interactively-p 'any)
                 (call-interactively 'term+mux-noselect)
               (term+mux-noselect session name command))))
    (switch-to-buffer-other-window (tab-group:tab-buffer tab))))

(defun term+mux-other-window (&optional session)
  "Open a terminal of SESSION in an other window.
If there is no terminal in the session, create a new one."
  (interactive)
  (let* ((session (or session term+mux-default-session))
         (tabs (term+mux-session-as-group session tabs))
         term-tab selected-tab)
    (while tabs
      (let ((tab (car tabs)))
        (with-current-buffer (tab-group:tab-buffer tab)
          (when (eq major-mode 'term-mode)
            (setq term-tab (or term-tab tab))
            (when (and (eq (car tabs) tab-group:current-tab)
                       (not (string-match-p "^ " (buffer-name))))
              (setq selected-tab tab tabs nil)))))
      (setq tabs (cdr tabs)))
    (let ((tab (or selected-tab term-tab)))
      (if tab
          (progn
            (switch-to-buffer-other-window (tab-group:tab-buffer tab))
            (tab-group:select tab))
        (term+mux-new-other-window session)))))

(defun term+mux-new-command ()
  "Open a new terminal as a new tab with always asking what
command to run.  See `term+mux-new' for the detail."
  (interactive)
  (let ((current-prefix-arg 1))
    (call-interactively 'term+mux-new)))

(defun term+mux-new-session (&optional name user host)
  "Make a new session of USER at HOST whose name is NAME.

If USER or HOST is omitted, the local user and the local host are
used.  If NAME is omitted, it defaults to the following values
with their conditions:

HOST         USER is the local user
USER         USER is not the local user and HOST is the local host
USER@HOST    none of the above

The default name can be changed by specifying
`term+mux-session-name-function'.

When called interactively, also make a new terminal for the
session and only ask NAME with no prefix argument, or ask USER,
HOST and NAME with at least one prefix argument, or ask USER,
HOST and NAME with at least two prefix arguments."
  (interactive
   (let* ((user (or (and current-prefix-arg (term+mux-read-string 'user))
                    term+default-user))
          (host (or (and current-prefix-arg (term+mux-read-string 'host))
                    term+mux-default-host))
          (initial (funcall term+mux-session-name-function
                            (or user (user-real-login-name)) host))
          (name (and (or current-prefix-arg (term+mux-session initial))
                     (read-string "Name: " initial))))
     (list name user host)))
  (let* ((user (or user term+default-user))
         (host (or host term+mux-default-host))
         (name (or name
                   (funcall term+mux-session-name-function
                            (or user (user-real-login-name)) host)))
         (group-defined (tab-group:group name))
         (group (tab-group:new name))
         (defined (term+mux-session name))
         (args (list :group group :user user :host host))
         (session (or defined (apply #'term+mux-make-session args))))
    (unless group-defined
      (when term+mux-session-buffer
        (tab-group:set 'group-buffer-mode 1 group)
        (tab-group:set 'group-buffer-prefix "term:" group))
      (tab-group:set 'term+mux-session session group))
    (unless defined
      (push (cons name session) term+mux-sessions)
      (run-hook-with-args
       'term+mux-new-session-hook session (not group-defined)))
    (when (called-interactively-p 'any)
      (with-temp-buffer ; prevent the current buffer from being unselected
        (term+mux-new session)))
    session))
(setq term+mux-default-session (term+mux-new-session))

(defun term+mux-remote-session ()
  "Make a new session with asking the user name ans the host name
and the session name.  See `term+mux-new-session' for the
detail."
  (interactive)
  (let ((current-prefix-arg 1))
    (call-interactively 'term+mux-new-session)))

(defun term+mux-set-title (&optional title)
  "Set the title of the tab of the current terminal to TITLE.
When called interactively, TITLE becomes unchangeable by
non-interactive calls until `term+mux-unset-title' is called."
  (interactive
   (let ((tab tab-group:current-tab))
     (list (read-string "Title: " (and tab (tab-group:tab-name tab))))))
  (let ((tabs tab-group:buffer-tabs) (saved term+mux-saved-auto-title)
        (group (tab-group:current-group)))
    (when (and tabs group)
      (when (or (called-interactively-p 'any) (not title) (not saved))
        (dolist (tab tabs)
          (when (and (not term+mux-saved-auto-title)
                     (called-interactively-p 'any))
            (setq term+mux-saved-auto-title (tab-group:tab-name tab)))
          (tab-group:rename tab (or title saved))))
      (tab-group:update-tabbar group)
      (setq term+mux-saved-auto-title
            (cond
             ((and saved (not (called-interactively-p 'any))) title)
             ((not saved) term+mux-saved-auto-title)
             ((not title) nil)
             (t term+mux-saved-auto-title))))))

(defun term+mux-unset-title ()
  "Reset the title of the tab of the current terminal to the
value before interactive calls of `term+mux-set-title'."
  (interactive)
  (term+mux-set-title))


;;; cdd

(defsubst term+mux-cdd-tab-dir (tab)
  (and tab (with-current-buffer (tab-group:tab-buffer tab) default-directory)))

(defsubst term+mux-cdd-tab-info (label)
  (let* ((tab (tab-group:search-result-1 label))
         (name (format-mode-line label))
         (name (substring name (or (string-match-p "[^ \t\r\n]" name) 0))))
    (and tab (concat name ":" (term+mux-cdd-tab-dir tab)))))

(defun term+mux-cdd-put-overlay ()
  (with-current-buffer tab-group:search-current-buffer
    (let* ((tab (car-safe (tab-group:search-result)))
           (dir (or (term+mux-cdd-tab-dir tab) "")))
      (term+mux-cdd-delete-overlay)
      (setq term+mux-cdd-overlay (make-overlay (point) (point)))
      (overlay-put term+mux-cdd-overlay 'after-string dir))))

(defun term+mux-cdd-delete-overlay ()
  (when term+mux-cdd-overlay
    (delete-overlay term+mux-cdd-overlay)
    (setq term+mux-cdd-overlay nil)))

(defun term+mux-cdd-update-search (beg end len)
  (tab-group:update-search beg end len)
  (term+mux-cdd-put-overlay))

(defun term+mux-cdd-end-search ()
  (term+mux-cdd-delete-overlay)
  (tab-group:end-search))

(defun term+mux-cdd-select (tabs)
  (term-send-raw-string
   (concat (mapconcat #'term+mux-cdd-tab-info tabs "\t") "\n")))

(defun term+mux-cdd-search (prompt)
  (let ((group (tab-group:current-group))
        (tab-group:update-search-function 'term+mux-cdd-update-search)
        (tab-group:end-search-function 'term+mux-cdd-end-search))
    (and group (tab-group:search group (format "%s: " prompt))
         tab-group:search-result)))

(defun term+mux-cdd-find (pattern)
  (tab-group:find pattern)
  tab-group:search-result)

(defun term+mux-cdd (pattern)
  "Make a list of default directories of terminals of the current
session and send it to the current terminal as a string.  If
PATTERN starts with \":\", then the rest of string in PATTERN is
a pattern to filter the result by a name (and an index) of a
terminal. Otherwise, PATTERN specifies a prompt to ask user for
the pattern to filter out the result.  The resulting directories
are separated by \"\\t\" and terminated by \"\\n\"."
  (if (string-match-p "^:" pattern)
      (term+mux-cdd-select (term+mux-cdd-find (substring pattern 1)))
    (let* ((prompt (if (= (length pattern) 0) "cdd" pattern)))
      (term+mux-cdd-select (list (car-safe (term+mux-cdd-search prompt)))))))


;;; session color

(defvar term+mux-session-user-color-alist '(("root" . "#fc391f")))
(defvar term+mux-session-host-color-alist '())
(defvar term+mux-session-local-color "#8c8ce8")
(defvar term+mux-session-remote-color "DarkKhaki")

(defun term+mux-session-color (session)
  (when session
    (let* ((user (term+mux-session-user session))
           (host (term+mux-session-host session))
           (user-color (cdr (assoc user term+mux-session-user-color-alist)))
           (host-color (cdr (assoc host term+mux-session-host-color-alist)))
           (host (term+shorten-hostname host))
           (hst-color (cdr (assoc host term+mux-session-host-color-alist))))
      (or user-color host-color hst-color
          (if (term+mux-session-local-p session)
              term+mux-session-local-color
            term+mux-session-remote-color)))))

(defun term+mux-colored-group-label (group)
  (let* ((label (tab-group:group-button-label group))
         (color (tab-group:get 'group-color group))
         (face `(:inherit tab-group:group :foreground ,color)))
    (propertize label 'face face)))

(defun term+mux-set-group-color-function (session own-group)
  (when own-group
    (let ((group (term+mux-session-group session))
          (color (term+mux-session-color session)))
      (tab-group:set 'group-color color group)
      (tab-group:set 'group-label 'term+mux-colored-group-label group))))
(add-hook 'term+mux-new-session-hook 'term+mux-set-group-color-function)

(provide 'term+mux)
;;; term+mux.el ends here
