There's a fairly common pitfall when Emacs libraries run background
processes on behalf of a user: the library should honour any
environment variables set buffer-locally, but many such libraries run
processes in temporary buffers that do not inherit the calling
buffer's environment.

An example is the Emacs built-in command
`shell-command-to-string'.  Whatever buffer-local `process-environment'
(or `exec-path') the user has set, that command will always use the
Emacs-wide default.  This is *specified* behaviour, but not *expected*
or *helpful*, particularly if one uses a library like
`envrc' with "direnv".

`inheritenv' provides a couple of tools for dealing with this
issue:

1. Library authors can wrap code that plans to execute processes in
   temporary buffers with the `inheritenv' macro.
2. End users can modify commands like `shell-command-to-string' using
   the `inheritenv-add-advice' macro.
