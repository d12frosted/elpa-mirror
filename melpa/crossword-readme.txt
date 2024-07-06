* Download and play crossword puzzles in Emacs.

* Includes a browser to view puzzles' detailed metadata, including
  progress of partially played puzzles.

* Optionally, play against the clock, with the built-in timer.




; Dependencies: (all already part of core Emacs)

seq            - for `seq--into-vector'
tabulated-list - for `tabulated-list-mode', etal.
hl-line        - for `hl-line-mode'
calendar       - for `calendar-read' etal.


; Dependencies: (external to Emacs)

The package uses either `wget' or `curl' to download packages from
the network. These are both long-established standard programs and
at least one is probably already installed on your computer.



