Evil-mode integration for the ghostel terminal emulator, modeled on
`evil-collection-vterm'.

Like vterm's, the surface area is tiny.  Basic motions (h l w b e $ 0)
stay vanilla Evil, so point moves freely over the rendered row.  Only
the commands that drive the shell's line editor are customized:
operators (d c x s r and line variants) clamp their range to
[input-start, input-end] and apply it over the PTY (arrows, backspaces,
bracketed paste); i a I A drive the shell cursor to point; ^ jumps past
the prompt; j / G stay on the live prompt; p / P paste; u sends
readline undo.

Outside semi-char input mode (`line' / `copy' / `emacs' / `char' modes,
or an alt-screen TUI) every command falls through to `evil-*'.

In alt-screen apps (vim, less, fullscreen TUIs like Claude Code)
insert-state ESC is by default routed to the app instead of switching
to normal state, so the app keeps its ESC key.  `C-c C-r'
(`evil-ghostel-toggle-send-escape') toggles the routing per buffer;
the `evil-ghostel-escape' option sets the default.  `C-c <escape>'
switches to normal state once without changing the routing (GUI
frames; on a tty it needs the kitty keyboard protocol via kkp.el).

Enable by adding to your init:

  (use-package evil-ghostel
    :after (ghostel evil)
    :hook (ghostel-mode . evil-ghostel-mode))
