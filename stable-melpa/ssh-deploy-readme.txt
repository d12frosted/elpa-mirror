ssh-deploy enables automatic deploys on explicit-save actions, manual uploads, renaming,
deleting, downloads, file and directory differences, launching remote terminals (eshell, shell),
detection of remote changes, remote directory browsing, remote SQL database sessions and
running custom deployment scripts via Tramp.

For asynchronous operations it uses package '`make-thread' or if not available '`async.el'.

By setting the variables (globally, per directory or per file):
ssh-deploy-root-local,ssh-deploy-root-remote
you can setup a directory for Tramp deployment.

For asynchronous transfers you need to setup ~/.authinfo.gpg or key-based authorization or equivalent for automatic authentication.

Example contents of ~/.authinfo.gpg for password-based interaction-free authentication:
machine myserver.com login myuser port ftp password mypassword
machine myserver2.com login myuser2 port ssh password mypassword2
machine myserver3.com login myuser3 port sftp password mypassword3

Set permissions to this file to 600 with your user as the owner.

If your not using ~/.netrc for FTP information you need to specify what file your using with:
(setq ange-ftp-netrc-filename "~/.authinfo.gpg")

- To setup a upload hook on save do this:
Add to init-script: (ssh-deploy-add-after-save-hook)

- To setup automatic storing of base revisions and detection of remote changes do this:
Add to init-script: (ssh-deploy-add-find-file-hook)

- To enable mode-line feature do this:
(ssh-deploy-line-mode)

- To enable menu-bar feature do this:
(ssh-deploy-add-menu)

- To set global key-bindings do something like this:
    (global-set-key (kbd "C-c C-z") 'ssh-deploy-prefix-map)

- To set global key-bindings for the pre-defined hydra do something like this:
    (ssh-deploy-hydra "C-c C-z")

- To install and set-up using use-package and hydra do this:
  (use-package ssh-deploy
    :ensure t
    :after hydra
    :demand
    :hook ((after-save . ssh-deploy-after-save)
           (find-file . ssh-deploy-find-file))
    :config
    (ssh-deploy-line-mode) ;; If you want mode-line feature
    (ssh-deploy-add-menu) ;; If you want menu-bar feature
    (ssh-deploy-hydra "C-c C-z") ;; If you the hydra feature
   )


Here is an example for SSH deployment, /Users/Chris/Web/Site1/.dir-locals.el, with forced explicit uploads:
((nil . (
  (ssh-deploy-root-local . "/Users/Chris/Web/Site1/")
  (ssh-deploy-root-remote . "/ssh:myuser@myserver.com:/var/www/site1/")
  (ssh-deploy-on-explicit-save . 1)
  (ssh-deploy-force-on-explicit-save . 1)
  (ssh-deploy-async . 1)
)))

Here is an example for SFTP deployment, /Users/Chris/Web/Site2/.dir-locals.el:
((nil . (
  (ssh-deploy-root-local . "/Users/Chris/Web/Site2/")
  (ssh-deploy-root-remote . "/sftp:myuser@myserver.com:/var/www/site2/")
  (ssh-deploy-on-explicit-save . 0)
  (ssh-deploy-async . 0)
  (ssh-deploy-script . (lambda() (let ((default-directory ssh-deploy-root-remote))(shell-command "bash compile.sh"))))
)))

Here is an example for FTP deployment, /Users/Chris/Web/Site3/.dir-locals.el:
((nil . (
  (ssh-deploy-root-local . "/Users/Chris/Web/Site3/")
  (ssh-deploy-root-remote . "/ftp:myuser@myserver.com:/var/www/site3/")
)))


Here is a list of other variables you can set globally or per directory:

* `ssh-deploy-root-local' - The local root that should be under deployment *(string)*
* `ssh-deploy-root-remote' - The remote Tramp root that is used for deployment *(string)*
* `ssh-deploy-debug' - Enables debugging messages *(integer)*
* `ssh-deploy-revision-folder' - The folder used for storing local revisions *(string)*
* `ssh-deploy-automatically-detect-remote-changes' - Enables automatic detection of remote changes *(integer)*
* `ssh-deploy-on-explicit-save' - Enabled automatic uploads on save *(integer)*
* `ssh-deploy-exclude-list' - A list defining what file names to exclude from deployment *(list)*
* `ssh-deploy-async' - Enables asynchronous transfers (you need to have `(make-thread)` or `async.el` available as well) *(integer)*
* `ssh-deploy-remote-sql-database' - Default database when connecting to remote SQL database *(string)*
* `ssh-deploy-remote-sql-password' - Default password when connecting to remote SQL database *(string)*
* `ssh-deploy-remote-sql-port' - Default port when connecting to remote SQL database *(integer)*
* `ssh-deploy-remote-sql-server' - Default server when connecting to remote SQL database *(string)*
* `ssh-deploy-remote-sql-user' - Default user when connecting to remote SQL database *(string)*
* `ssh-deploy-remote-shell-executable' - Default shell executable when launching shell on remote host *(string)*
* `ssh-deploy-verbose' - Show messages in message buffer when starting and ending actions *(integer)*
* `ssh-deploy-script' - Our custom lambda function that will be called using (funcall) when running deploy script *(function)*
* `ssh-deploy-async-with-threads' - Whether to use threads (make threads) instead of processes (async-start) for asynchronous operations *(integer)*

When integers are used as booleans, above zero means true, zero means false and nil means unset and indicates to fallback to global settings.

Please see README.md from the same repository for more extended documentation.

FIXME: This uses "path" in lots of places to mean "a complete file name
starting from /", whereas the GNU convention is to only "file name" instead
and keep "path" for lists of directories like load-path, exec-path.
