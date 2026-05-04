tmux-csi-u installs explicit `input-decode-map' entries so terminal
Emacs can decode tmux CSI-u key sequences (ESC [ keycode ; modifier u)
that neither Emacs native tmux/xterm input translation nor `xterm.el'
handle on the tmux TTY path.

Scope: the delta over the native decode, not a replacement.  Pi users
keep tmux on `extended-keys-format csi-u' and rely on this package to
recover shifted space, modified backspace, modified escape, the
`M-<return>' / `M-<tab>' gap, and the shifted punctuation family
captured in `test/fixture/punctuation.json'.

Usage:

  (require 'tmux-csi-u)
  (tmux-csi-u-mode 1)

The package loads pure: nothing happens until `tmux-csi-u-mode' is
enabled.  The mode adds a `tty-setup-hook' entry and immediately
enables every already-live supported tmux TTY frame.  `M-x
tmux-csi-u-describe' renders the latest enable report for debugging.
`M-x tmux-csi-u-disable' undoes the install on a single frame's
terminal; `(tmux-csi-u-mode -1)' fully disables the mode and
un-installs package-owned entries from every live terminal.

Collision policy is warn-and-preserve: conflicting external bindings
stay in place and are surfaced via `display-warning' and the report
buffer.  User-local mappings applied after package defaults go in
`tmux-csi-u-local-overrides'.

See the project homepage (URL above) for the full install,
migration, and verification matrix, and `doc/ref/protocol.md'
on the homepage for the tmux CSI-u wire shape.
