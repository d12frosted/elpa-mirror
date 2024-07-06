I find it particularly annoying that Emacs *shell* buffers do not
offer satisfactory completions, but xterm does. I even used
ansi-term for a while because of this (oh god). What I really
wanted was for Emacs to show completions via auto-complete.el, like
every other mode I use often. This package hopes to deliver on that
promise.

xterm and friends get their completions from readline, a GNU
library that is aware of your context and monitors your keystrokes
for TABs and what not so you can be shown a list of
completions. readline-complete.el gives you a process filter that
tries to parse readline completion menus and give Emacs a list of
strings that are valid for completion in the current context.
