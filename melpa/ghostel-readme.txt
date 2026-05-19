Ghostel is an Emacs terminal emulator powered by libghostty-vt, the
terminal emulation library extracted from the Ghostty project.  A
native Zig dynamic module handles VT parsing, terminal state, and
rendering, while this Elisp layer manages the shell process, keymap,
buffer, and user-facing commands.

Usage:

  M-x ghostel               Open a new terminal
  M-x ghostel-project       Open a terminal in the current project root
  M-x ghostel-other         Switch to next terminal or create one
  M-x ghostel-next / ghostel-previous
                            Cycle through all ghostel buffers
  M-x ghostel-list-buffers  Pick a ghostel buffer to switch to
  M-x ghostel-project-next / ghostel-project-previous /
      ghostel-project-list-buffers
                            Same, scoped to the current project

Key bindings in the terminal buffer:

  Most keys are sent directly to the shell.  Keys in
  `ghostel-keymap-exceptions' (C-c, C-x, M-x, etc.) pass through
  to Emacs.  Terminal control and navigation use a C-c prefix:

  C-c C-c   Interrupt          C-c C-z   Suspend
  C-c C-d   EOF                C-c C-\   Quit
  C-c C-t   Copy mode          C-c C-y   Paste
  C-c C-l   Clear scrollback   C-c C-q   Send next key literally
  C-c M-w   Copy scrollback    C-y / M-y Yank / yank-pop
  C-c C-n / C-c C-p            Next/previous hyperlink
  C-c M-n / C-c M-p            Next/previous prompt (OSC 133)

Copy mode (C-c C-t) freezes the display and enables standard Emacs
navigation.  Set mark with C-SPC, select text, then M-w to copy.

Shell integration:

  Directory tracking (OSC 7), prompt navigation (OSC 133), and the
  `ghostel_cmd' helper are auto-injected for bash, zsh, and fish —
  no shell rc changes needed.  Controlled by `ghostel-shell-integration'
  (default t); set it to nil to source etc/shell/ghostel.{bash,zsh,fish}
  manually instead.

Native module:

  A pre-built binary is downloaded automatically on first use.  To
  build from source instead (requires Zig 0.15.2+), run zig build
  from the project root, or M-x ghostel-module-compile.  M-x
  ghostel-download-module re-fetches the pre-built binary.

See also: evil-ghostel.el (evil-mode integration), ghostel-compile.el
(TTY-backed M-x compile replacement), ghostel-eshell.el (eshell
visual-command integration).  TRAMP paths as `default-directory'
spawn remote shells; see README.md for details.
