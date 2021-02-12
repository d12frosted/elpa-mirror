`copy-file-on-save-mode' is a minor mode to copy the file to another path on
`after-save-hook'.  This not only saves the backup in the project specific
path, it also you can realize the deployment to the remote server over TRAMP.

## Setup

Put the following into your .emacs file (~/.emacs.d/init.el)

   (global-copy-file-on-save-mode)


## Config

Put the following into your .dir-locals.el in project root directory.

    ((nil . ((copy-file-on-save-dest-dir . "/scp:dest-server:/home/your/path/to/proj")
             (copy-file-on-save-ignore-patterns . ("/cache")))))

See TRAMP User Manual to learn file name syntax.  Do `M-x info' and search TRAMP.
https://www.gnu.org/software/emacs/manual/html_node/tramp/Configuration.html#Configuration
