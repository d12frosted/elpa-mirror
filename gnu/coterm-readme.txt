If the global `coterm-mode' is enabled, proper terminal emulation will be
supported for all newly spawned comint processes.  This allows you to use
more complex console programs such as "less" and "mpv" and full-screen TUI
programs such as "vi", "top", "htop" or even "emacs -nw".

In addition to that, the following two local minor modes may be used:

`coterm-char-mode': if enabled, most characters you type are sent directly
to the subprocess, which is useful for interacting with full-screen TUI
programs.

`coterm-auto-char-mode': if enabled, coterm will enter and leave
`coterm-char-mode' automatically as appropriate.  For example, if you
execute "less" in a shell buffer, coterm will detect that "less" is running
and automatically enable char mode so that you can interact with less
normally.  Once you leave the "less" program, coterm will disable char mode
so that you can interact with your shell in the normal comint way.  This
mode is enabled by default in all coterm comint buffers.

Automatic entrance into char mode is indicated by "AChar" in the modeline.
Non-automatic entrance into char mode is indicated by "Char".
Automatic exit of char mode is indicated by no text in the modeline.
Non-automatic exit of char mode is indicated by "Line".

The command `coterm-char-mode-cycle' is a handy command to cycle between
automatic char-mode, char-mode enabled and char-mode disabled.


Installation:

To install coterm, type M-x package-install RET coterm RET

It is best to add the following elisp snippet to your Emacs init file, to
enable `coterm-mode' automatically on startup:

  (coterm-mode)

  ;; Optional: bind `coterm-char-mode-cycle' to C-; in comint
  (with-eval-after-load 'comint
    (define-key comint-mode-map (kbd "C-;") #'coterm-char-mode-cycle))

  ;; If your process repeats what you have already typed, try customizing
  ;; `comint-process-echoes':
  ;;   (setq-default comint-process-echoes t)


Differences from M-x term:

coterm is written as an upgrade to comint.  For existing comint users, the
behaviour of comint doesn't change with coterm enabled except for the added
functionality that we can now use TUI programs.  It is therefore good for
users who generally prefer comint to term.el but sometimes miss the superior
terminal emulation that term.el provides.

Coterm also provides `coterm-auto-char-mode' which aims to eliminate the
need to manually enable and disable char mode.


Some common probles:

If some TUI programs misbehave, try checking your TERM environment variable
with 'echo $TERM' in your coterm enabled M-x shell.  It should normally be
set to "coterm-color".  If if isn't, it might be that one of your shell
initialization files (~/.bashrc) changes it, so check for that and remove
the change.

The default "less" prompt, when invoked as 'less ~/some/file', is too
generic and isn't recognized by `coterm-auto-char-mode', so char mode isn't
entered automatically.  It is recommended to make your "less" prompt more
complete and recognizable by adding the character "m" or "M" to your LESS
environment variable.  For example, in your ~/.bashrc, add this line:

  export LESS="FRXim"

The "FRX" options make "less" more compatible with "git", and the "i" option
enables case insensitive search in less.  See man page less(1) for more
information.  Automatic char mode detection also usually fails if
"--incsearch" is enabled in "less".  It is advised to either turn this
option off or to use manual char mode.


Bugs, suggestions and patches can be sent to

   bugs-doseganje (at) groups.io

and can be viewed at https://groups.io/g/bugs-doseganje/topics.  As this
package is stored in GNU ELPA, non-trivial patches require copyright
assignment to the FSF, see info node "(emacs) Copyright Assignment".

Some useful information you can send in your bug reports:

After enabling `coterm-mode', open up an M-x shell and copy the output of
the following shell command:

  export | cat -v | grep 'LESS\|TERM'; stty;

You can also set the variable `coterm--t-log-buffer' to "coterm-log",
reproduce the issue and attach the contents of the buffer named
"coterm-log", which now contains all process output that was sent to coterm.