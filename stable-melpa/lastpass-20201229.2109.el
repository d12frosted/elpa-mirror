;;; lastpass.el --- LastPass command wrapper -*- lexical-binding: t -*-

;; Copyright © 2017

;; Author: Petter Storvik
;; URL: https://github.com/storvik/emacs-lastpass
;; Package-Version: 20201229.2109
;; Package-Commit: 2366de7824b6c5f8e9ec6811d219dc06794e8630
;; Version: 0.2.0
;; Created: 2017-02-17
;; Package-Requires: ((emacs "24.4") (seq "1.9") (cl-lib "0.5"))
;; Keywords: extensions processes lpass lastpass

;; This file is NOT part of GNU Emacs.

;;; License:

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
;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package contains a wrapper for the LastPass command line utility
;; lpass and a custom auth-source.
;;
;; Auth-source functionality relies on an adviced function, `auth-source-backend-parse'.
;; Can for example be used to get smtpmail to use LastPass instead of authinfo file.
;; To use this auth-source, LastPass account name must be set to match the host.
;; One way to achieve this is to keep a separate group in LastPass called auth-source
;; where all hosts are stored.  To enable LastPass auth-source, run
;; `lastpass-auth-source-enable'.
;;
;; Several functions used for interacting with lpass in Emacs are
;; made available to the user through the "M-x" interface.
;; Such functions are:
;; - `lastpass-login'
;; - `lastpass-logout'
;; - `lastpass-status'
;; - `lastpass-getpass'
;; - `lastpass-addpass'
;; - `lastpass-version'
;; - `lastpass-visit-url'
;; These functions can also be used in elisp when configuring Emacs.
;;
;; A hook, `lastpass-logged-in-hook' is run on successful login.
;;
;; A lpass manager is available by running `lastpass-list-all'.
;; This function will list all passwords and a major mode takes care of
;; setting som neat keybindings to some neat functions.  All these functions
;; are shown in the lpass buffer, and is self-explanatory.
;;
;; For more information, see the readme at https://github.com/storvik/emacs-lastpass

;;; Code:

(require 'seq)
(require 'cl-lib)
(require 'auth-source)
(require 'tree-widget)

(defgroup lastpass nil
  "LastPass functions and settings."
  :group 'external
  :tag "lastpass"
  :prefix "lastpass-")

(defcustom lastpass-user ""
  "LastPass user e-mail."
  :type 'string
  :group 'lastpass)

(defcustom lastpass-shell "/bin/bash"
  "Shell to be used when running LastPass commands."
  :type 'string
  :group 'lastpass)

(defcustom lastpass-multifactor-use-passcode nil
  "Use passcode when doing multifactor authentication."
  :type 'boolean
  :group 'lastpass)

(defcustom lastpass-trust-login nil
  "Log in with the trust option, causing subsequent logins to not require MFA."
  :type 'boolean
  :group 'lastpass)

(defcustom lastpass-pass-length 12
  "Default password length when generating passwords."
  :type 'integer
  :group 'lastpass)

(defcustom lastpass-pass-no-symbols nil
  "Use symbols when generating passwords."
  :type 'boolean
  :group 'lastpass)

(defcustom lastpass-agent-timeout nil
  "LastPass agent timeout in seconds.
Set to 0 to never quit and nil to not use."
  :type 'integer
  :group 'lastpass)

(defcustom lastpass-logged-in-hook nil
  "Hook called on login."
  :type 'hook
  :group 'lastpass)

(defcustom lastpass-list-all-delimiter ","
  "Delimiter used to distinguish between id, account name, group and username.
Use a character not present in such fields.  Most of the time comma should be usable."
  :type 'string
  :group 'lastpass)

(defcustom lastpass-browser "eww"
  "Variable describing which browser to be used when opening urls.
Can be set to eww or generic, where generic means open in external browser."
  :type '(choice
          (const :tag "Emacs Browser (EWW)" "eww")
          (const :tag "External Browser" "generic")
          string)
  :group 'lastpass)

(defcustom lastpass-min-version "1.1.0"
  "Variable describing minimal lpass command line interface version."
  :type 'string
  :group 'lastpass)

(defvar lastpass-group-completion '()
  "List containing groups.  Gets updated on `lastpass-list-all'.")

(defun lastpass-runcmd (cmd &rest args)
  "Run lpass command CMD with ARGS."
  (with-temp-buffer
    (list (apply 'call-process "lpass" nil (current-buffer) nil (cons cmd args))
          (replace-regexp-in-string "\n$" ""
                                    (buffer-string)))))

(defun lastpass-pipe-to-cmd (cmd prepend &rest args)
  "Run lpass command CMD, piping PREPEND and appending ARGS.
Can for example be used with lpass add and the following prepended string:
Username: testuser\nPassword: testpassword.  Returns a list with status code
and returned string from lpass command."
  (with-temp-buffer
    (let ((command (concat "printf \""
                           prepend
                           "\"" " | lpass "
                           (mapconcat 'identity (cons cmd args) " ")
                           " --non-interactive")))
      (list (apply 'call-process-shell-command command nil (current-buffer) nil)
            (replace-regexp-in-string "\n$" "" (buffer-string))))))

(defun lastpass-list-all-reload ()
  "Reload `lastpass-list-all' by killing *lastpass-list* and reopening."
  (interactive)
  (when (string-match (buffer-name) "*lastpass-list*")
    (kill-buffer "*lastpass-list*")
    (lastpass-list-all)))

;;;###autoload
(defun lastpass-version (&optional print-message)
  "Show lastpass command line interface version.
If run interactively PRINT-MESSAGE gets set and version is printed to minibuffer."
  (interactive "p")
  (let ((ret (lastpass-runcmd "--version")))
    (when print-message
      (message "%s" (nth 1 ret)))
    (nth 1 ret)))

;;;###autoload
(defun lastpass-login ()
  "Prompts user for password if not logged in."
  (interactive)
  (unless (equal (nth 0 (lastpass-runcmd "status")) 1)
    (error "LastPass: Already logged in"))
  (when (get-process "lastpass")
    (delete-process "lastpass"))
  (let ((process (start-process-shell-command
                  "lastpass"
                  nil
                  (concat (when lastpass-agent-timeout
                            (concat "LPASS_AGENT_TIMEOUT=" (shell-quote-argument lastpass-agent-timeout) (shell-quote-argument " ")))
                          "LPASS_DISABLE_PINENTRY=1 "
                          lastpass-shell
                          " -c '"
                          "lpass login "
                          (when lastpass-trust-login
                            "--trust ")
                          lastpass-user
                          "'"))))
    (set-process-filter
     process
     (lambda (proc string)
       ;; Multifactor stuff
       (if lastpass-multifactor-use-passcode
           (progn
             (when (string-match "approval" string)
               (interrupt-process proc))
             (when (and (string-match "code" string)
                        (not (string-match "passcode" string)))
               (process-send-string
                proc
                (if (string-match "invalid" string)
                    (concat (read-passwd "Wrong authentication code. LastPass multifactor authentication code: ") "\n")
                  (concat (read-passwd "LastPass multifactor authentication code: ") "\n")))))
         (when (string-match "approval" string)
           (message "LastPass: Waiting for multifactor authentication.")))
       ;; No multifactor stuff
       (when (string-match "password" string)
         (process-send-string
          proc
          (if (string-match "invalid" string)
              (concat (read-passwd "Wrong password. LastPass master password: ") "\n")
            (concat (read-passwd "LastPass master password: ") "\n"))))
       (when (string-match "success" string)
         (message (concat "LastPass: Successfully logged in as " lastpass-user))
         (run-hooks 'lastpass-logged-in-hook))))))

;;;###autoload
(defun lastpass-status ()
  "Check LastPass status, if user is logged in or not."
  (interactive)
  (let ((ret (lastpass-runcmd "status")))
    (message "LastPass status: %s" (nth 1 ret))))

(defun lastpass-logged-in-p ()
  "Check if `lastpass-user' is logged in to LastPass.
Returns nil if not logged in."
  (let ((ret (lastpass-runcmd "status")))
    (and (equal (nth 0 ret) 0)
         (string-match lastpass-user (nth 1 ret)))))

;;;###autoload
(defun lastpass-logout ()
  "Log out lpass.  Does not ask for confirmation."
  (interactive)
  (unless (equal (nth 0 (lastpass-runcmd "status")) 0)
    (error "LastPass: Not logged in, no need to log out"))
  (unless  (equal (nth 0 (lastpass-runcmd "logout" "--force")) 0)
    (error "LastPass: Something went wrong, could not log out"))
  (message "LastPass: Successfully logged out."))

;;;###autoload
(defun lastpass-getuser (account &optional print-message)
  "Get username associated with ACCOUNT.
If run interactively PRINT-MESSAGE gets set and username is printed to minibuffer."
  (interactive "MLastPass account name: \np")
  (unless (equal (nth 0 (lastpass-runcmd "status")) 0)
    (error "LastPass: Not logged in"))
  (let ((ret (lastpass-runcmd "show" "--username" account)))
    (if (equal (nth 0 ret) 0)
        (progn
          (when print-message
            (message "LastPass: Username for account %s is: %s" account (nth 1 ret)))
          (nth 1 ret))
      (message "LastPass: Something went wrong, could not get username."))))

;;;###autoload
(defun lastpass-getpass (account &optional print-message)
  "Get password associated with ACCOUNT.
If run interactively PRINT-MESSAGE gets set and password is printed to minibuffer."
  (interactive "MLastPass account name: \np")
  (unless (equal (nth 0 (lastpass-runcmd "status")) 0)
    (error "LastPass: Not logged in"))
  (let ((ret (lastpass-runcmd "show" "--password" account)))
    (if (equal (nth 0 ret) 0)
        (progn
          (when print-message
            (message "LastPass: Password for account %s is: %s" account (nth 1 ret)))
          (nth 1 ret))
      (message "LastPass: Something went wrong, could not get password."))))

;;;###autoload
(defun lastpass-getfield (field account &optional print-message)
  "Get custom FIELD associated with ACCOUNT.
If run interactively PRINT-MESSAGE gets set and custom field is printed to minibuffer."
  (interactive "MLastPass account name: \np")
  (unless (equal (nth 0 (lastpass-runcmd "status")) 0)
    (error "LastPass: Not logged in"))
  (let ((ret (lastpass-runcmd "show" (concat "--field=" field) account)))
    (if (equal (nth 0 ret) 0)
        (progn
          (when print-message
            (message "LastPass: %s for account %s is: %s" field account (nth 1 ret)))
          (nth 1 ret))
      (message "LastPass: Something went wrong, could not get %s." field))))

;;;###autoload
(defun lastpass-visit-url (account)
  "Visit url associated with ACCOUNT, which can be account name of unique id."
  (interactive "MLastPass account: ")
  (unless (lastpass-logged-in-p)
    (error "LastPass: Not logged in"))
  (let ((url (nth 1 (lastpass-runcmd "show" "--url" account))))
    (unless url
      (error "LastPass: No URL for given account / Account does not exist"))
    (if (string-equal lastpass-browser "generic")
        (browse-url-generic url)
      (browse-web url))))

;;;###autoload
(defun lastpass-create-auth-source-account (account hostname)
  "Copy ACCOUNT, change name to HOSTNAME and move to auth-source group.
Simplyfies the process of creating a valid auth-source entry from lastpass account."
  (interactive "MLastPass account: \nMHostname: ")
  (unless (lastpass-logged-in-p)
    (error "LastPass: Not logged in"))
  (let ((ret (lastpass-runcmd "show" account)))
    (unless (equal (nth 0 ret) 0)
      (error "LastPass: Account not found"))
    (with-temp-buffer
      (insert (nth 1 ret))
      (goto-char (point-min))
      (kill-line)
      (let ((auth-account (concat "auth-source" "/" hostname)))
        (unless (equal (nth 0 (lastpass-pipe-to-cmd "add" (buffer-string) auth-account)) 0)
          (error "LastPass: Could not add account"))
        (message "LastPass: Added account %s as auth %s" account auth-account)))))

;;;###autoload
(defun lastpass-addpass (account user password url group)
  "Add account ACCOUNT with USER and PASSWORD to LastPass.
Optionally URL and GROUP can be set to nil."
  (interactive
   (list
    (read-string "Account name:")
    (read-string "User:")
    (read-string "Password(leave blank to generate):")
    (read-string "URL:")
    (completing-read "Group:" lastpass-group-completion nil nil)))
  (unless (equal (nth 0 (lastpass-runcmd "status")) 0)
    (error "LastPass: Not logged in"))
  (if (and password
           (> (length password) 0))
      ;; Add account without generating password
      (let ((inputstr (concat "Username: " user
                              "\nPassword: " password)))
        (when (and url
                   (> (length url) 0))
          (setq inputstr (concat inputstr "\nURL: " url)))
        (when (and group
                   (> (length group) 0))
          (setq account (concat group "/" account))
          (setq account (shell-quote-argument account)))
        (unless (equal (nth 0 (lastpass-pipe-to-cmd "add" inputstr account)) 0)
          (error "LastPass: Could not add account")))
    ;; Add account and generate password
    (let ((arguments (list (number-to-string lastpass-pass-length))))
      (when (and group
                 (> (length group) 0))
        (setq account (concat group "/" account)))
      (when (and url
                 (push account arguments)
                 (> (length url) 0))
        (push (concat "--url=" url) arguments))
      (push (concat "--username=" user) arguments)
      (when lastpass-pass-no-symbols
        (push "--no-symbols" arguments))
      (push "generate" arguments)
      (apply 'lastpass-runcmd arguments)))
  (message "LastPass: Account \"%s\" added" account)
  (lastpass-list-all-reload))

(defun lastpass-getid (account)
  "Get id associated with ACCOUNT."
  (let ((ret (lastpass-runcmd "show" "--id" account)))
    (when (equal (nth 0 ret) 0)
      (nth 1 ret))))

;; lastpass-list-dialog-mode
(defvar lastpass-list-dialog-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map widget-keymap)
    (define-key map "n" 'next-line)
    (define-key map "p" 'previous-line)
    (define-key map "r" 'lastpass-list-all-reload)
    (define-key map "a" 'lastpass-addpass)
    (define-key map "s" 'lastpass-list-all-getpass)
    (define-key map "w" 'lastpass-list-all-kill-ring-save)
    (define-key map "m" 'lastpass-list-all-movepass)
    (define-key map "c" 'lastpass-list-all-create-auth-source-account)
    (define-key map "d" 'lastpass-list-all-deletepass)
    (define-key map "q" 'lastpass-list-cancel-dialog)
    map)
  "Keymap used in recentf dialogs.")

(define-derived-mode lastpass-list-dialog-mode nil "lastpass-list-dialog"
  "Major mode of recentf dialogs.

\\{lastpass-list-dialog-mode-map}"
  :syntax-table nil
  :abbrev-table nil
  (setq truncate-lines t))

(defmacro lastpass-list-dialog (name &rest forms)
  "Show a dialog buffer with NAME, setup with FORMS."
  (declare (indent 1) (debug t))
  `(with-current-buffer (get-buffer-create ,name)
     ;; Cleanup buffer
     (let ((inhibit-read-only t)
           (ol (overlay-lists)))
       (mapc 'delete-overlay (car ol))
       (mapc 'delete-overlay (cdr ol))
       (erase-buffer))
     (lastpass-list-dialog-mode)
     ,@forms
     (widget-setup)
     (switch-to-buffer (current-buffer))))

;; Dialog settings and actions
(defun lastpass-list-cancel-dialog (&rest _ignore)
  "Cancel the current dialog.
IGNORE arguments."
  (interactive)
  (kill-buffer (current-buffer))
  (message "Dialog canceled"))

(defun lastpass-list-all-item-action (widget &rest _ignore)
  "Do action to element associated with WIDGET's value.
IGNORE other arguments."
  ;;(kill-buffer (current-buffer))
  (funcall 'lastpass-visit-url (widget-value widget)))

(defsubst lastpass-list-all-get-element-id ()
  "Get id from line in dialog widget."
  (let ((line (thing-at-point 'line t)))
    (with-temp-buffer
      (insert line)
      (goto-char (point-min))
      (thing-at-point 'word))))

(defun lastpass-list-all-getpass ()
  "Display current items password in minibuffer.
As it uses message to print the password, it will be visible in the *Messages* buffer."
  (interactive)
  (message "Password: %s" (lastpass-getpass (lastpass-list-all-get-element-id))))

(defun lastpass-list-all-kill-ring-save ()
  "LastPass `kill-ring-save', insert password to kill ring."
  (interactive)
  (kill-new (lastpass-getpass (lastpass-list-all-get-element-id)))
  (message "Password added to kill ring"))

(defun lastpass-list-all-deletepass ()
  "Delete account from LastPass."
  (interactive)
  (let ((id (lastpass-list-all-get-element-id)))
    (when (y-or-n-p (concat "LastPass: Delete "
                            id
                            "? "))
      (unless  (equal (nth 0 (lastpass-runcmd "rm" id)) 0)
        (error "LastPass: Something went wrong, could not delete account"))
      (message "LastPass: Successfully deleted account, updating list."))))

(defun lastpass-list-all-movepass ()
  "Move password to group."
  (interactive)
  (let ((id (lastpass-list-all-get-element-id)))
    (let ((group (completing-read (concat "Move item " id " to group: ") lastpass-group-completion nil nil)))
      (unless  (equal (nth 0 (lastpass-runcmd "mv" id group)) 0)
        (error "LastPass: Something went wrong, could not move account to group"))
      (message "LastPass: Successfully moved account, updating list.")))
  (lastpass-list-all-reload))

(defun lastpass-list-all-create-auth-source-account ()
  "Create auth-source entry from password."
  (interactive)
  (let ((id (lastpass-list-all-get-element-id)))
    (lastpass-create-auth-source-account id (read-string "LastPass: Enter hostname for auth-source: "))))

(defsubst lastpass-list-all-make-spaces (spaces)
  "Create a string with SPACES number of whitespaces."
  (mapconcat 'identity (make-list spaces " ") ""))

(defsubst lastpass-pad-to-width (item width)
  "Create a string with ITEM padded to WIDTH."
  (if (= (length item) width)
      item
    (if (>= (length item) width)
        (concat (substring item 0 (- width 1)) "…")
      (concat item (lastpass-list-all-make-spaces (- width (length item)))))))

(defsubst lastpass-list-all-make-element (item)
  "Create a new widget element from ITEM.
Also update the `lastpass-group-completion' variable by adding groups to list."
  (let ((fields (split-string item lastpass-list-all-delimiter)))
    (add-to-list 'lastpass-group-completion (nth 2 fields))
    (cons (concat
           (lastpass-pad-to-width (nth 0 fields) 24)
           (lastpass-pad-to-width
            (if (string-prefix-p "Generated Password for " (nth 1 fields))
                (concat "…" (substring (nth 1 fields) 23))
              (nth 1 fields))
            24)
           (lastpass-pad-to-width (nth 2 fields) 24)
           (nth 3 fields))
          (nth 0 fields))))

(defun lastpass-list-all-item (pass-element)
  "Return a widget to display PASS-ELEMENT in a dialog buffer."
  (if (consp (cdr pass-element))
      ;; Represent a sub-menu with a tree widget
      `(tree-widget
        :open t
        :match ignore
        :node (item :tag ,(car pass-element)
                    :sample-face bold
                    :format "%{%t%}:\n")
        ,@(mapcar 'lastpass-list-all-item
                  (cdr pass-element)))
    ;; Represent a single file with a link widget
    `(link :tag ,(car pass-element)
           :button-prefix ""
           :button-suffix ""
           :button-face default
           :format "%[%t\n%]"
           :help-echo ,(concat "Viewing item " (cdr pass-element))
           :action lastpass-list-all-item-action
           ;; Override the (problematic) follow-link property of the
           ;; `link' widget (bug#22434).
           :follow-link nil
           ,(cdr pass-element))))

(defun lastpass-list-all-items (items)
  "Return a list of widgets to display ITEMS in a dialog buffer."
  (mapcar 'lastpass-list-all-item
          ;;TODO: Add headers over list. Think append and concat should be used for this.
          (mapcar 'lastpass-list-all-make-element
                  items)))

;;;###autoload
(defun lastpass-list-all (&optional group)
  "Show a dialog, listing all entries associated with `lastpass-user'.
If optional argument GROUP is given, only entries in GROUP will be listed."
  (interactive)
  (unless (equal (nth 0 (lastpass-runcmd "status")) 0)
    (error "LastPass: Not logged in.  Log in with lastpass-login to continue"))
  (mapc
   (lambda (x)
     (delete x lastpass-group-completion))
   lastpass-group-completion)
  (lastpass-list-dialog "*lastpass-list*"
    (widget-insert (concat "LastPass list mode.\n"
                           "Usage:\n"
                           "\t<enter> open URL\n"
                           "\tn next line\n"
                           "\tp previous line\n"
                           "\tr reload accounts\n"
                           "\ta add password\n"
                           "\ts show password\n"
                           "\tw add password to kill ring\n"
                           "\tm move account to group\n"
                           "\tc create auth-source from account\n"
                           "\td delete account\n"
                           "\tq quit\n"))
    ;; Use a L&F that looks like the recentf menu.
    (tree-widget-set-theme "folder")
    (let ((formatstr (concat "--format=%ai"
                             lastpass-list-all-delimiter "%an"
                             lastpass-list-all-delimiter "%ag"
                             lastpass-list-all-delimiter "%au")))
      (apply 'widget-create
             `(group
               :indent 0
               :format "\n%v\n"
               ,@(lastpass-list-all-items (split-string (nth 1 (if (not group)
                                                                   (lastpass-runcmd "ls" formatstr)
                                                                 (lastpass-runcmd "ls" formatstr group)))
                                                        "\\(\r\n\\|[\n\r]\\)")))))
    (widget-create
     'push-button
     :notify 'lastpass-list-cancel-dialog
     "Cancel")
    (goto-char (point-min))))

;; Auth-source functions
(cl-defun lastpass-auth-source-search (&rest spec
                                             &key backend type host user port
                                             &allow-other-keys)
  "Given a property list SPEC, return search matches from the BACKEND.
See `auth-source-search' for details on SPEC."
  (cl-assert (or (null type) (eq type (oref backend type)))
             t "Invalid search: %s %s")
  (when (listp host)
    ;; Take the first non-nil item of the list of hosts
    (setq host (seq-find #'identity host)))
  (list (lastpass-auth-source--build-result host port user)))

(defun lastpass-auth-source--build-result (host port user)
  "Get id of the account matchin HOST and build auth-source with HOST, PORT and USER."
  (let ((id (lastpass-getid host)))
    (when id
      (list
       :host host
       :port port
       :user (or user (nth 1 (lastpass-runcmd "show" "--user" id)))
       :secret (lastpass-getpass id)))))

;;;###autoload
(defun lastpass-auth-source-enable ()
  "Enable lastpass auth-source by adding it to `auth-sources'."
  (interactive)
  (add-to-list 'auth-sources 'lastpass)
  (auth-source-forget-all-cached)
  (message "LastPass: auth-source enabled"))

(defvar lastpass-auth-source-backend
  (auth-source-backend "lastpass"
                       :source "." ;; not used
                       :type 'lastpass
                       :search-function #'lastpass-auth-source-search)
  "Auth-source backend variable for lastpass.")

(defun lastpass-auth-source-backend-parse (entry)
  "Create auth-source backend from ENTRY."
  (when (eq entry 'lastpass)
    (auth-source-backend-parse-parameters entry lastpass-auth-source-backend)))

;; Advice to add custom auth-source function
(if (boundp 'auth-source-backend-parser-functions)
    (add-hook 'auth-source-backend-parser-functions #'lastpass-auth-source-backend-parse)
  (advice-add 'auth-source-backend-parse :before-until #'lastpass-auth-source-backend-parse))

(provide 'lastpass)
;;; lastpass.el ends here
