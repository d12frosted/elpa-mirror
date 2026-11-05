           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              READLINE-COMPLETION.EL — COMPLETION IN EMACS
                           FROM GNU READLINE
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This package provides completions from GNU Readline.  It can be used

• in a comint buffer, to get completions from the underlying process, as
  you normally would in a regular terminal, or
• anywhere else to get completions from Bash.

This relies on a new feature from GNU Readline 8.3, released in July
2025, so please ensure you have that version installed.  Note also that
this package is not compatible with programs that use alternative
line-editing libraries.

Compared to related packages such as [bash-completion] or the "native
completion" mode from the built-in Python shell, this package requires
far fewer tricks and guesswork in order to trigger a completion and
parse the subprocess output.  In particular, it is compatible with any
program that uses GNU Readline.


[bash-completion] <https://elpa.nongnu.org/nongnu/bash-completion.html>


1 Setup
═══════

  To enable the package in `shell-mode' as well as when reading a shell
  command from the minibuffer (`M-&', `M-x compile', etc.), add the
  following to your configuration:

  ┌────
  │ (with-eval-after-load 'shell
  │   (add-hook 'shell-dynamic-complete-functions #'readline-completion-at-point))
  └────

  To enable it in any other comint-mode *which you know to be
  compatible*, add `readline-completion-at-point' to
  `completion-at-point-functions' in a relevant mode hook.  For example,
  for the PostgreSQL and SQLite shells:

  ┌────
  │ (add-hook 'sql-interactive-mode-hook
  │           (lambda ()
  │             (when (memq sql-product '(postgres sqlite))
  │               (add-hook 'completion-at-point-functions
  │                         #'readline-completion-at-point
  │                         nil t))))
  └────

  For testing, or if you prefer a dedicated keybinding for this
  completion source, you can call `readline-completion-at-point'
  interactively.


2 Contributing
══════════════

  Discussions, suggestions and code contributions are welcome!  Since
  this package is part of GNU ELPA, contributions require a copyright
  assignment to the FSF.
