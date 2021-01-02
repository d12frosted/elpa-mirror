Usage: with point in the body of some test, run M-x `pytest-pdb-break-here'

This command can only handle the "console script"/entry-point invocation
style (as opposed to "python -m pytest").  If a pytest executable isn't
visible in the environment prepared by the various python-shell-calculate-
functions, `pytest-pdb-break-pytest-executable' must be set.

Note: at present, the pytest plugin requires Python 3.6+, which means so
does the main command.  However, the minor mode along with the helpers in
the "extras" file should support 3.5.

TODO:
- Smarten up test-items prompter
- Option-name completions (would require external helper)
- Tramp
