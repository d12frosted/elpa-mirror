Environment variables in Emacs can be set buffer-locally, like many
Emacs preferences, which allows users to have different buffer-local
paths for executables in different projects, specified by a
".dir-locals.el" file or via a "direnv" integration like
envrc (see https://github.com/purcell/envrc).

However, there's a fairly common pitfall when Emacs libraries run
background processes on behalf of a user: many such libraries run
processes in temporary buffers that do not inherit the calling
buffer's environment.  This can result in executables not being found,
or the wrong versions of executables being picked up.

An example is the Emacs built-in command
`shell-command-to-string'.  Whatever buffer-local `process-environment'
(or `exec-path') the user has set, that command will always use the
Emacs-wide default.  This is *specified* behaviour, but not *expected*
or *helpful*.

`inheritenv' provides a couple of tools for dealing with this
issue:

1. Library authors can wrap code that plans to execute processes in
   temporary buffers with the `inheritenv' macro.
2. End users can modify commands like `shell-command-to-string' using
   the `inheritenv-add-advice' macro.
