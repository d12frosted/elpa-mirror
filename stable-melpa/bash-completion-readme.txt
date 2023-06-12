
This file defines dynamic completion hooks for `shell-mode' and
`shell-command' prompts that are based on Bash completion.  You can
enable it by invoking `bash-completion-setup' or by adding

   (bash-completion-setup)

to your initialisation file.

You can also use bash completion as an additional completion
function in any buffer that contains bash commands. To do that, add
`bash-completion-capf-nonexclusive' to the buffer-local
`completion-at-point-functions'. For example, you can setup bash
completion in `eshell-mode' by invoking

(add-hook 'eshell-mode-hook
          (lambda ()
            (add-hook 'completion-at-point-functions
                      'bash-completion-capf-nonexclusive nil t)))

The completion will be aware of bash builtins, alii and functions.
It does file expansion does file expansion inside of
colon-separated variables and after redirections (> or <), and
escapes special characters when expanding file names.  Just like
"regular" Bash, it is configurable through programmable bash
completion.

When the first completion is requested in shell model or a shell
command, bash-completion.el starts a separate Bash
process.  Bash-completion.el then uses this process to do the actual
completion and includes it into Emacs completion suggestions.

A simpler and more complete alternative to bash-completion.el is to
run a Bash shell in a buffer in term mode (M-x `ansi-term').
Unfortunately, many Emacs editing features are not available when
running in term mode.  Also, term mode is not available in
shell-command prompts.

Bash completion can also be run programmatically, outside of a
shell-mode command, by calling
`bash-completion-dynamic-complete-nocomint'

; Installation:

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
launches a new Bash process.

Naturally, you'll get better results if you turn on programmable
Bash completion in your shell. Depending on how your system is set
up, this might requires calling:
  . /etc/bash_completion
from your ~/.bashrc.

When called from a Bash shell buffer,
`bash-completion-dynamic-complete' communicates with the current shell
to reproduce, as closely as possible the normal Bash auto-completion,
available on full terminals.

When called from non-shell buffers, such as the prompt of M-x
compile, `bash-completion-dynamic-complete' creates a separate Bash
process just for doing completion. Such processes have the
environment variable EMACS_BASH_COMPLETE set to t, to help
distinguish them from normal shell processes.

See the documentation of the function
`bash-completion-dynamic-complete-nocomint' to do Bash completion
from other buffers or completion engines.

; Compatibility:

bash-completion.el is known to work with Bash 4.2 and later and
Bash 5, on Emacs, starting with version 25.3, under Linux and OSX.
