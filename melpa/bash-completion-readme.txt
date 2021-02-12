
This file defines dynamic completion hooks for shell-mode and
shell-command prompts that are based on bash completion.

Bash completion for emacs:
- is aware of bash builtins, aliases and functions
- does file expansion inside of colon-separated variables
  and after redirections (> or <)
- escapes special characters when expanding file names
- is configurable through programmable bash completion

When the first completion is requested in shell model or a shell
command, bash-completion.el starts a separate bash
process.  Bash-completion.el then uses this process to do the actual
completion and includes it into Emacs completion suggestions.

A simpler and more complete alternative to bash-completion.el is to
run a bash shell in a buffer in term mode(M-x `ansi-term').
Unfortunately, many Emacs editing features are not available when
running in term mode.  Also, term mode is not available in
shell-command prompts.

Bash completion can also be run programmatically, outside of a
shell-mode command, by calling
`bash-completion-dynamic-complete-nocomint'

INSTALLATION

1. copy bash-completion.el into a directory that's on Emacs load-path
2. add this into your .emacs file:
  (autoload 'bash-completion-dynamic-complete \"bash-completion\"
    \"BASH completion hook\")
  (add-hook 'shell-dynamic-complete-functions
     'bash-completion-dynamic-complete)

  or simpler, but forces you to load this file at startup:

  (require 'bash-completion)
  (bash-completion-setup)

3. reload your .emacs (M-x `eval-buffer') or restart

Once this is done, use <TAB> as usual to do dynamic completion from
shell mode or a shell command minibuffer, such as the one started
for M-x `compile'. Note that the first completion is slow, as emacs
launches a new bash process.

Naturally, you'll get better results if you turn on programmable
bash completion in your shell. Depending on how your system is set
up, this might requires calling:
  . /etc/bash_completion
from your ~/.bashrc.

When called from a bash shell buffer,
`bash-completion-dynamic-complete' communicates with the current shell
to reproduce, as closely as possible the normal bash auto-completion,
available on full terminals.

When called from non-shell buffers, such as the prompt of M-x
compile, `bash-completion-dynamic-complete' creates a separate bash
process just for doing completion. Such processes have the
environment variable EMACS_BASH_COMPLETE set to t, to help
distinguish them from normal shell processes.

See the documentation of the function
`bash-completion-dynamic-complete-nocomint' to do bash completion
from other buffers or completion engines.

COMPATIBILITY

bash-completion.el is known to work with Bash 3, 4 and 5, on Emacs,
starting with version 24.3, under Linux and OSX. It does not work
on XEmacs.
