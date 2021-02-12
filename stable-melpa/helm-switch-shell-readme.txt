This package offers a helm-source for switching between shells via
helm, sorting them by how their working directory is to your
current active directory.

It’s especially convienent to make a key binding for this, e.g.
(global-set-key (kbd "<f3>") #'helm-switch-shell)

It show a list of the shell-mode and eshell-mode shells you have
open by their current directory, sorted by how close they are to
the directory you’re currently in.

You can switch to one of those buffers, or type the name of a new
directory to create a shell there (defaulting to your current
directory).

By default, new shells are created with eshell. You can customize
this by setting helm-switch-shell-new-shell-type to be shell, in
which case new shells will be created with shell, or vterm, in
which case they will be created with vterm (if the emacs-libvterm
package is installed).

It provides the following keybindings by default:
C-s: open the indicated shell in horizontal split (split-window-below)
C-v: open the indicated shell in a vertical split (split-window-right)

Other options for customization:

  helm-switch-shell-truncate-lines: set to non-nil to truncate candidates
  helm-switch-shell-show-shell-indicator: set to non-nil to show an
  indicator of what kind of shell the candidate is in the list
  (e.g. [V] for vterm, [E] for eshell, etc)

Faces:

  helm-switch-shell-buffer-name-face: Face for the candidate buffer name
  helm-switch-shell-indicator-face: Face for the candidate indicator type
  helm-switch-shell-path-face: Face for the candidate path name
  helm-switch-shell-new-shell-face: Face for the [+] new shell indicator
