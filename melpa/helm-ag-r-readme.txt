Usage
set below configuration to your .emacs
(add-to-list 'load-path "path/to/this-package-directory")
(require 'helm-ag-r)
You can change ag's option by pushing C-o from below variable on minibuffer
See ag --help about available options
(setq helm-ag-r-option-list
      '("-S -U --hidden"
        "-S -U -l"))
To use helm-ag-r-google-contacts-list command, specify your google
mail address to helm-ag-r-google-contacts-user variable.(If you
specified gmail-address to user-mail-address, then you don't need
below configuration.)
(setq helm-ag-r-google-contacts-user "")
And if you are Japanese, to use Japanese language set below configuration.
this variable set $LANG environment variable by default.
(setq helm-ag-r-google-contacts-lang "ja_JP.UTF-8")

Commands
helm-ag-r-current-file -- search from current file
helm-ag-r-from-git-repo -- search from git repository
helm-ag-r-shell-history -- search shell history
helm-ag-r-git-logs -- search git logs
helm-ag-r-google-contacts-list -- show your google-contacts
