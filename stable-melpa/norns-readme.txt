
This package provides an interactive development for monome norns.

This package allows to spawn REPLs that bind to remote maiden and
SuperCollider REPLs (via commands `norns-maiden-repl', `norns-sc-repl')
and associated commands to interact with them from Lua and SuperCollider
source files.

All commands (unless specified otherwise) will analyze if currently
visited file is on a norns.  If it's the case, this particular norns is
targeted by the command execution.  Otherwise the default norns instance
(configurable w/ `norns-host' / `norns-mdns-domain' is targeted
instead).  This behaviors can be changed by setting value of
`norns-access-policy' to ":current" or ":default".


To connect to a REPL, use commands `norns-maiden-repl' and
`norns-sc-repl'.  Those REPL provide prompts but one can send text
through the minibuffer with `norns-maiden-send' and `norns-sc-send'.

Commands that send input to any of the REPL will automatically make the
REPL pop in a window if not already visible.  This can be turned off by
setting `norns-repl-switch-on-cmd' to nil.

Additionally, to send a selected region to the appropriate REPL, use
`norns-maiden-send-selection'.

The currently visited script can be loaded with
`norns-load-current-script'.  If current script has several
"sub-scripts", you'll get prompted to select one.

`norns-load-script' will list all the scripts on current norns instance
and will load the one you would select.

For detailed instructions, please look at the README.md at https://github.com/p3r7/norns.el/blob/master/README.md
