remoto.el lets you browse any GitHub or Codeberg repository in Emacs as
if it were cloned locally - without cloning it.  It registers a virtual
filesystem via `file-name-handler-alist' that translates Emacs file
operations into requests to a forge.  A forge is a `remoto-forge' that
answers the generic functions of the forge contract with plain data;
GitHub's answers live in remoto-github.el and use the `ghub' library.

Loading this file defines things and changes nothing.  `global-remoto-mode'
is the switch: it installs the file-name handler, the `find-file' and
`dired' URL rewriting, the completion metadata, and the auto-enabling of
`remoto-mode' in remoto buffers, and removes all of them when turned off.

Usage:
  C-x C-f /github:torvalds/linux RET
  C-x C-f /cb:forgejo/forgejo RET
  M-x remoto-browse RET https://github.com/torvalds/linux RET

Each turns the mode on when it is off: `remoto-browse' itself, and the
path through `remoto-autoload-file-name-handler', which the package
autoloads register for the prefixes of the forges that come with
remoto, the way TRAMP autoloads on a remote path.
`(global-remoto-mode 1)' in the init file turns it on ahead of time.
`remoto-browse' supports pasting any GitHub URL, git remote URL, or
owner/repo shorthand.
