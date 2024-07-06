
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
