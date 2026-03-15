This package provides functions to perform REPL-driven development
for Scala programming language.

Currently it supports the following features:

1. Automatically detect project root, trigger a REPL session and
   attach to it.

2. Evaluate source code in the REPL session that the current buffer
   is attached to.

3. Customize commands to run for SBT/Mill projects or non-project
   files.

4. Run ad-hoc REPL sessions with custom commands and manually
   attach to/detach from it.

5. Support multiple REPL sessions for different projects/ad-hoc
   files.

6. Provide a minor mode that contains some default key bindings.

Note that the evaluation functionality is restricted by
corresponding Scala REPL.

Also note that this package *might* work on Emacs < 29.1, but it is
not guaranteed.  You are welcome to open an issue on the GitHub page
and let know if it does.
