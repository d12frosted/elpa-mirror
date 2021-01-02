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

; Installation:

There is no one "right" way to install this package, because it
does not provide any user level commands. I find that it works
particularly well with shell-mode and auto-complete.el, so I'll
describe how my setup works.

First, let us setup shell-mode. shell-mode, by default, does not
create a tty (terminal) and does not echo input, both of which are
required for proper operation. To fix this, adjust the arguments to
your shell:

(setq explicit-shell-file-name "bash")
(setq explicit-bash-args '("-c" "export EMACS=; stty echo; bash"))
(setq comint-process-echoes t)

ASIDE: if you call ssh from shell directly, add "-t" to explicit-ssh-args to enable terminal.

The simplest way is to install from melpa, and add to your init file:
(require 'readline-complete)
This package also supports lazy loading via a loaddefs file.

Two completion frameworks are supported, you only need to pick one.

Auto-Complete setup:

Go ahead and get auto-complete.el from
http://cx4a.org/software/auto-complete/, and follow the
instructions for setup.

Then enable it in your init file.

(add-to-list 'ac-modes 'shell-mode)
(add-hook 'shell-mode-hook 'ac-rlc-setup-sources)

Company setup:

See installation instructions at http://company-mode.github.io/.

Set up completion back-end:

(push 'company-readline company-backends)
(add-hook 'rlc-no-readline-hook (lambda () (company-mode -1)))

Finally, M-x shell, and start typing!

For customization, see the docstrings of `rlc-timeout`,
`rlc-attempts`, and `ac-rlc-prompts`.
