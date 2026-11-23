efzf brings Emacs' completion UI (Vertico, Orderless, Marginalia,
etc.) to the terminal as an fzf-like selector.  The companion shell
script `efzf' calls `efzf-run-action' through emacsclient, which
shows a full-screen completion UI in the terminal and writes the
selected item to a file.

When installed as a package, run `M-x efzf-install-scripts' to copy
the shell scripts `efzf' and `efzf.zsh' to your shell environment.

See README.org for installation and shell integration.
