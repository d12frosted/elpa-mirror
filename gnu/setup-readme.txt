The `setup` macro simplifies repetitive configuration patterns, by
providing context-sensitive local macros in `setup' bodies.  These
macros can be mixed with regular elisp code without any issues,
allowing for flexible and terse configurations.  The list of local
macros can be extended by the user via `setup-define'.  A list of
currently known local macros are documented in the docstring for `setup'.

Examples and extended documentation can be found on Emacs wiki:
https://www.emacswiki.org/emacs/SetupEl.  Please feel free to
contribute your own local macros or ideas.