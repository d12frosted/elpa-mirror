Help keeping ~/.config/emacs clean.

The default paths used to store configuration files and persistent
data are not consistent across Emacs packages.  This isn't just a
problem with third-party packages but even with built-in packages.

Some packages put these files directly in `user-emacs-directory'
or $HOME or in a subdirectory of either of the two or elsewhere.
Furthermore sometimes file names are used that don't provide any
insight into what package might have created them.

This package sets out to fix this by changing the values of path
variables to put configuration files in `no-littering-etc-directory'
(defaulting to "etc/" under `user-emacs-directory', thus usually
"~/.config/emacs/etc/") and persistent data files in
`no-littering-var-directory' (defaulting to "var/" under
`user-emacs-directory', thus usually "~/.emacs.d/var/"), and
by using descriptive file names and subdirectories when appropriate.
This is similar to a color-theme; a "path-theme" if you will.

We still have a long way to go until most built-in and many third-
party path variables are properly "themed".  Like a color-theme,
this package depends on user contributions to accomplish decent
coverage.  Pull requests are highly welcome (but please follow the
conventions described below and in the pull request template).

This package does not automatically migrate existing files to their
new locations, but unless you want to, you also do not have to do
it completely by hand.  The contributed "migrate.org" provides some
guidance and tools to help with the migration.

;; Usage

Load the feature `no-littering' as early as possible in your init
file.  Make sure you load it at least before you change any path
variables using some other method.

  (require 'no-littering)

If you would like to use base directories different from what
`no-littering' uses by default, then you have to set the respective
variables before loading the feature.

  (eval-and-compile ; Ensure values don't differ at compile time.
    (setq no-littering-etc-directory
          (expand-file-name "config/" user-emacs-directory))
    (setq no-littering-var-directory
          (expand-file-name "data/" user-emacs-directory))
    (require 'no-littering)

For additional optional settings see "README.org".

;; Conventions

Please see the "README.org" file in this repository or the exported
version at https://emacsmirror.net/manual/no-littering.html.
