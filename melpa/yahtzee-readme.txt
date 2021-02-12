Package tested on:
GNU Emacs 25.2.1 (x86_64-apple-darwin16.5.0)

A simple implementation of the yahtzee game.

Quick start:

add (require 'yahtzee) in your .emacs
M-x yahtzee  start a game (in a new buffer)
C-c n        start a new game (in the same buffer)
C-c p        add players
C-c P        reset players
SPC          throw dice
{1,2,3,4,5}  hold outcome of {1,2,3,4,5}-th dice
UP/DOWN      select score to register
ENTER        register selected score
w            save the game (in json format)

The score of a saved game can be loaded using `M-x yahtzee-load-game-score`.

Configuration variables:

The user might want to set the following variables
(see associated docstrings)
  - `yahtzee-output-file-base'
  - `yahtzee-fields-alist'      for adding extra fields
  - `yahtzee-players-names'     set names of players
                                use (setq-default yahtzee-players-names ...)

Note:
   personally I don't enjoy playing with "Yahtzee bonuses" and "Joker rules"
   so they are not implemented (even thought they are simple to include).
   Only the "63 bonus" is available (see `yahtzee-compute-bonus').
   Furthermore, some scores differ from the official ones.  Changing all
   this can be done by simply modifying the corresponding functions in the
   definition of `yahtzee-fields-alist'.
