Usage:

Start the REPL:

M-x firefox-javascript-repl RET

To stop the REPL, kill the *firefox-javascript-debugger* buffer:

C-x k RET yes RET

or quit Firefox from within Firefox.

Description:

REPL into a new Firefox instance's JavaScript engine.  A new
throwaway Firefox profile directory is created before each run, so
you won't need to modify your existing profiles.  This mode takes
care of starting the new Firefox process in debugging mode, which
may be tedious to do by hand.

This `comint' mode is barebones and unstructured, meant for quick
JavaScript experiments.  On newer versions of Emacs with
`comint-indirect-buffer' support, syntax highlighting happens on
the current statement.

Paste each statement from `example.js' into the REPL to try it out.

For projects you should probably use `dap-mode' and `lsp-mode'
instead.

Only Firefox and Firefox-derivative browsers will ever be supported
(unless someone sends a really convincing patch).  I promise to
attempt to stive to keep this working with at least the
greenest-of-evergreen Firefox and Firefox ESR versions (see
Compatibility).  My sense is that the Firefox Remote Debugging
Protocol is less of a moving target than it used to be.  Emacs
versions back to 26.1 (or earlier if anyone can test on Emacs <
26.1) will be supported.

Wouldn't it be great (for other people) to turn this into a full
SLIME analog for JavaScript (patches accepted)?  I tried `jsSlime'
(https://github.com/segv/jss) but its most recent update is ten
years old and the Firefox Remote Debugging Protocol has changed too
much.

The function `fjrepl--extract-result' could do a way better job of
getting results but I find it OK for little experiments.  If I need
more information I submit a more precise JavaScript statement.
Syntax errors currently fail silently.

Installation:

M-x package-install RET firefox-javascript-repl RET

Compatibility:

╔════════════╦══════════╦══════════════════════╗
║  Test Date ║ Browser  ║ Version              ║
╠════════════╬══════════╬══════════════════════╣
║ 2023-05-26 ║ Firefox  ║ 102.11.0esr (64-bit) ║
║ 2023-05-26 ║ Firefox  ║ 113.0.2 (64-bit)     ║
║ 2023-05-26 ║ Abrowser ║ 111.0.1 (64-bit)     ║
╙────────────╨──────────╨──────────────────────╜

Acronyms:

FRDP: Firefox Remote Debugging Protocol
      https://firefox-source-docs.mozilla.org/devtools/backend/protocol.html