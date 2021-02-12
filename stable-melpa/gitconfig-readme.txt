
  Manual Installation:

   (add-to-list 'load-path "~/path/to/gitconfig.el/")
   (require 'gitconfig)

  Interesting variables are:

      `gitconfig-git-command'

           The shell command for <git>

      `gitconfig-buffer-name'

           Name of the <git> output buffer.

  Interactive functions are:

       M-x gitconfig-execute-command

           Run <git config> with custom ARGUMENTS and display it in `gitconfig-buffer-name'

  Non-Interactive functions are:

       `gitconfig-current-inside-git-repository-p'

           Return t if `default-directory' is a git repository

       `gitconfig-path-to-git-repository'

           Return the absolute path of the current git repository

       `gitconfig-get-variables'

           Get all variables for the given LOCATION
           and return it as a hash table

       `gitconfig-set-variable'

           Set a specific LOCATION variable with a given NAME and VALUE

       `gitconfig-get-variable'

           Return a specific LOCATION variable for the given NAME

       `gitconfig-delete-variable'

           Delete a specific LOCATION variable for the given NAME

       `gitconfig-get-local-variables'

           Return all <git config --local --list> variables as hash table

       `gitconfig-get-global-variables'

           Return all <git config --global --list> variables as hash table

       `gitconfig-get-system-variables'

           Return all <git config --system --list> variables as hash table

       `gitconfig-get-local-variable'

           Return a specific <git config --local --list> variable by the given NAME

       `gitconfig-get-global-variable'

           Return a specific <git config --global --list> variable by the given NAME

       `gitconfig-get-system-variable'

           Return a specific <git config --system --list> variable by the given NAME
