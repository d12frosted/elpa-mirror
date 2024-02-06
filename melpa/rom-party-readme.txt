The main entry point to the package is the command `rom-party' which
will start a new game.  The objective of the game is, given a two or
three letter prompt, to find any word containing that prompt as a
substring in the given time limit (as in https://jklm.fun/).

The difficulty of the game can be configured by the user custom
variable `rom-party-prompt-filter', see the docstring for more
information.

Note by default on first invocation, `rom-party' will download a
remote index file asynchronously and so may not start straight away.
