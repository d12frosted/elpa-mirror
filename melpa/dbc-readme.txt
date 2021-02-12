See README at https://gitlab.com/matsievskiysv/display-buffer-control for
detailed description of package functions.

Display-buffer-control (dbc) package is an interface to Emacs's powerful
`display-buffer' function.  It allows to specify how the buffers should be
opened: should the new buffer be opened in a new frame or the current frame
(Emacs frame is a window in terms of window managers) how to position a new
window relative to the current one etc.

dbc uses rules and ruleset to describe how the new buffers should be opened.
Rulesets have a `display-buffer` action associated with them.  Actions describe
how the new window will be displayed (see `display-buffer` help page for
details).

In order to apply these actions to buffers, rules must be added.  Rules specify
matching conditions for the ruleset.

Examples:

Open Lua, Python, R, Julia and shell inferior buffers in new frames, enable
`dbc-verbose` flag:

(use-package dbc
  :custom
  (dbc-verbose t)
  :config
  (dbc-add-ruleset "pop-up-frame" dbc-right-side-action)
  (dbc-add-rule "pop-up-frame" "shell" :oldmajor "sh-mode" :newname "\\*shell\\*")
  (dbc-add-rule "pop-up-frame" "python" :newmajor "inferior-python-mode")
  (dbc-add-rule "pop-up-frame" "ess" :newmajor "inferior-ess-.+-mode")
  (dbc-add-rule "pop-up-frame" "lua repl" :newmajor "comint-mode" :oldmajor "lua-mode" :newname "\\*lua\\*"))

Display help in right side window:

(require 'dbc)

(dbc-add-ruleset "rightside" '((display-buffer-in-side-window) . ((side . right) (window-width . 0.4))))
(dbc-add-rule "rightside" "help" :newname "\\*help\\*")
