1 Git Config Modes
══════════════════

  Emacs major modes for various Git configuration files.

  The list of contributors can be found [here].

  The following libraries are part of the `git-modes' package, which is
  available from NonGNU ELPA as well as from Melpa.


[here] <https://github.com/magit/git-modes/graphs/contributors>

1.1 `gitattributes-mode'
────────────────────────

  Auto-/loading the library `gitattributes-mode' enabled the mode for
  `.gitattributes', `.git/info/attributes', and `git/attributes' files.


1.2 `gitconfig-mode'
────────────────────

  Auto-/loading the library `gitconfig-mode' enables the mode for
  `.gitconfig', `.git/config', `git/config', and `.gitmodules' files.

  `gitconfig-mode' derives from `conf-unix-mode'.


1.3 `gitignore-mode'
────────────────────

  Auto-/loading the library `gitignore-mode' enables the mode for
  `.gitignore', `.git/info/exclude', and `git/ignore' files.

  `gitignore-mode' derives from `conf-unix-mode'.

  This mode may be of use in other files that don't have anything to do
  with Git, for example:

  ┌────
  │ (add-to-list 'auto-mode-alist
  │ 	     (cons "/.dockerignore\\'" 'gitignore-mode))
  └────
