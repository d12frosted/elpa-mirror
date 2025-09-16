# sxhkdrc-mode for GNU Emacs

This is a major mode for editing `sxhkdrc` files. SXHKD is the Simple
X Hot Key Daemon which is commonly used in minimalist desktop sessions
on Xorg (I use it with bspwm, herbstluftwm, and i3wm). The `sxhkdrc`
file configures key chords, binding them to commands. For the
technicalities, read the manpage `sxhkd(1)`.

+ Package name (GNU ELPA): `sxhkdrc-mode`
+ Git repositories:
  + GitHub: <https://github.com/protesilaos/sxhkdrc-mode>
  + GitLab: <https://gitlab.com/protesilaos/sxhkdrc-mode>
+ Backronym: Such Xenotropic Hot Keys Demonstrate Robustness and
  Configurability ... mode.

## Usage

Install the mode and use with any `sxhkdrc` file:

```elisp
(use-package sxhkdrc-mode
  :ensure t
  :mode "sxhkdrc.*")
```

Restart the sxhkd daemon on demand with the command
`sxhkdrc-mode-restart`. Or make it happen automatically each time you
save a buffer that uses the `sxhkdrc-mode` by setting up the
`sxhkdrc-mode-auto-restart` like this:

```elisp
;; automatically reload the daemon after saving the file
(add-hook 'sxhkdrc-mode-hook #'sxhkdrc-mode-auto-restart)
```

Putting it all together:

```elisp
(use-package sxhkdrc-mode
  :ensure t
  :mode "sxhkdrc.*" ; if you want more than just "sxhkdrc"
  :commands (sxhkdrc-mode-restart)
  :hook (sxhkdrc-mode . sxhkdrc-mode-auto-restart))
```
