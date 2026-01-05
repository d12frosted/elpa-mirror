pass-coffin.el provides a small Emacs interface to the external
`pass-coffin' ("pass coffin") command-line utility (an extension
around `password-store' ("pass").

The commands in this package are thin wrappers that call the `pass`
executable (e.g., `pass open`, `pass close`, `pass timer`) and show
the resulting output in the echo area.  ANSI escape sequences are
stripped before display.

Provided interactive commands:
- `pass-coffin-open'       - Run "pass open"
                             (optionally with -t TIME).
- `pass-coffin-open-timer' - Prompt for a duration, then run "pass
                             open".
- `pass-coffin-close'      - Run "pass close".
- `pass-coffin-timer'      - Run "pass timer".
- `pass-coffin-timer-stop' - Run "pass timer stop".

Requirements:
- The `pass' program must be installed and available in PATH.
- The underlying `pass-coffin' utility is available at:
  https://codeberg.org/rch/pass-coffin

Note: These commands invoke the external `pass` program.
