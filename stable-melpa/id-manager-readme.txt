ID-password management utility.
This utility manages ID-password list and generates passwords.

The ID-password DB is saved in the tab-separated file.  The default
file name of the DB `idm-database-file' is "~/.idm-db.gpg".
The file format is following:
  (name)^t(ID)^t(password)^t(Update date "YYYY/MM/DD")[^t(memo)]
. One can prepare an initial data or modify the data by hand or
the Excel.

Implicitly, this elisp program expects that the DB file is
encrypted by the some GPG encryption elisp, such as EasyPG or
alpaca.

Excuting the command `idm-open-list-command', you can open the
ID-password list buffer. Check the function `describe-bindings'.

; Installation:

To use this program, locate this file to load-path directory,
and add the following code to your .emacs.
------------------------------
(require 'id-manager)
------------------------------
If you have helm.el, bind `id-manager' to key,
like (global-set-key (kbd "M-7") 'id-manager).

; Setting example:

For EasyPG users:

(autoload 'id-manager "id-manager" nil t)
(global-set-key (kbd "M-7") 'id-manager)                     ; helm UI
(setq epa-file-cache-passphrase-for-symmetric-encryption t)  ; saving password
(setenv "GPG_AGENT_INFO" nil)                                ; non-GUI password dialog.

For alpaca users:

(autoload 'id-manager "id-manager" nil t)
(global-set-key (kbd "M-7") 'id-manager) ; helm UI
(setq idm-db-buffer-save-function ; adjustment for alpaca.el
      (lambda (file)
        (set-visited-file-name file)
        (alpaca-save-buffer))
      idm-db-buffer-password-var  ; if you are using `alpaca-cache-passphrase'.
        'alpaca-passphrase)

; Current implementation:

This program generates passwords by using external command:
`idm-gen-password-cmd'. If you have some better idea, please let me
know.

I think that this program makes lazy password management more
securely.  But I'm not sure that this program is secure enough.
I'd like many people to check and advice me.

; Integrating with OS launchers (Alfred, QuickSilver, Launchbar, etc.)

Invoke id-manager with an input string.

An example script to use for Alfred:

INPUT="{query}"
osascript -e 'tell app "Emacs" to activate'
emacsclient -e "(id-manager \"$INPUT\"))"
