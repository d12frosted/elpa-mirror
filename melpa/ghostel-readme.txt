Ghostel is an Emacs terminal emulator powered by libghostty-vt, the
terminal emulation library extracted from the Ghostty project.  A
native Zig dynamic module handles VT parsing, terminal state, and
rendering, while this Elisp layer manages the shell process, keymap,
buffer, and user-facing commands.

Usage:

  M-x ghostel          Open a new terminal
  M-x ghostel-other    Switch to next terminal or create one

Key bindings in the terminal buffer:

  Most keys are sent directly to the shell.  Keys in
  `ghostel-keymap-exceptions' (C-c, C-x, M-x, etc.) pass through
  to Emacs.  Terminal control keys use a C-c prefix:

  C-c C-c   Interrupt        C-c C-z   Suspend
  C-c C-d   EOF              C-c C-\   Quit
  C-c C-t   Copy mode        C-c C-y   Paste
  C-c C-l   Clear scrollback C-c C-q   Send next key literally
  C-y       Yank             M-y       Yank-pop

Copy mode (C-c C-t) freezes the display and enables standard Emacs
navigation.  Set mark with C-SPC, select text, then M-w to copy.
Soft-wrapped newlines and trailing whitespace are stripped
automatically.

Shell integration:

  For directory tracking (OSC 7), source the appropriate script
  from etc/ in your shell configuration:

    # bash (~/.bashrc)
    [[ "$INSIDE_EMACS" = 'ghostel' ]] && \
      source "$EMACS_GHOSTEL_PATH/etc/ghostel.bash"

    # zsh (~/.zshrc)
    [[ "$INSIDE_EMACS" = 'ghostel' ]] && \
      source "$EMACS_GHOSTEL_PATH/etc/ghostel.zsh"

Building the native module:

  Run ./build.sh from the project root, or M-x ghostel-module-compile
  from within Emacs.  Requires Zig 0.14+ and the vendored ghostty
  submodule.
