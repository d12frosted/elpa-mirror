xah-fly-keys is a efficient keybinding for emacs. It is modal like
vi, but key choices are based on statistics of command call
frequency.

HOW TO USE

M-x xah-fly-keys to toggle the mode on/off.

Important command/insert mode switch keys:

xah-fly-command-mode-activate (press <home> or F8 or Alt+Space or Ctrl+Space or menu key)

xah-fly-insert-mode-activate (when in command mode, press qwerty letter key f.)

When in command mode:

"f" calls `xah-fly-insert-mode-activate'.

Space is a leader key. For example, "SPC r" calls `query-replace'.
Press "SPC C-h" to see the full list.

"SPC SPC" also activates insertion mode.

"SPC RET" calls `execute-extended-command'.

"a" calls `execute-extended-command'.

The leader key sequence basically supplant ALL emacs commands that
starts with C-x key.

When using xah-fly-keys, you don't need to press Control or Meta,
with the following exceptions:

"C-c" for major mode commands.
"C-g" for cancel.
"C-q" for quoted-insert.
"C-h" for getting a list of keys following a prefix/leader key.

Leader key

You NEVER need to press "C-x"

Any emacs command that has a keybinding starting with C-x, has also
a key sequence binding in xah-fly-keys. For example,

"C-x b" for `switch-to-buffer' is "SPC f"
"C-x C-f" for `find-file' is "SPC i e"
"C-x n n" for `narrow-to-region' is "SPC l l"

The first key we call it leader key. In the above examples, the SPC
is the leader key.

When in command mode, the "SPC" is a leader key.

the following standard keys with Control are supported:

"C-TAB" `xah-next-user-buffer'
"C-S-TAB" `xah-previous-user-buffer'
"C-v" paste
"C-w" close
"C-z" undo
"C-n" new
"C-o" open
"C-s" save
"C-S-s" save as
"C-S-t" open last closed
"C-+" `text-scale-increase'
"C--" `text-scale-decrease'

To disable both Control and Meta shortcut keys, add the following
lines to you init.el BEFORE loading xah-fly-keys:

(setq xah-fly-use-control-key nil)
(setq xah-fly-use-meta-key nil)

If you have a bug, post on github.

For detail about design and other info, see home page at
http://xahlee.info/emacs/misc/xah-fly-keys.html

If you like this project, Buy Xah Emacs Tutorial
http://xahlee.info/emacs/emacs/buy_xah_emacs_tutorial.html or make
a donation. Thanks.