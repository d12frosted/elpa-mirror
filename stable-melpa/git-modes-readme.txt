This package provides several major modes for editing Git
configuration files.  The modes are:

   `gitattributes-mode'
   `gitconfig-mode', and
   `gitignore-mode'

Each mode is defined in its own library by the same name.
All additions to `auto-mode-alist' are autoloaded, so it is
not necessary load `git-modes' or the individual libraries.
