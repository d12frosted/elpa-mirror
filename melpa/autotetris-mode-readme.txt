This package provides two commands:

 * `autotetris' starts `tetris' with autotetris-mode enabled. This
   is the command you probably want to run.

 * `autotetris-mode' a minor mode for tetris-mode that
   automatically plays the game. Can be turned on or off at any
   time to allow a human to step in or out of control.

The AI is straightforward. It has a game state evaluator that
computes a single metric for a game state based on the following:

* Number of holes
* Maximum block height
* Mean block height
* Largest block height disparity
* Surface roughness

Lower is better. When a new piece is to be placed it virtually
attempts to place it in every possible position and rotation,
choosing the lowest evaluation score. It's all loosely based on
this algorithm:

http://www.cs.cornell.edu/boom/1999sp/projects/tetris/

Current shortcomings:

The weights could using some tweaking because the priorities are
obviously wrong at times. It does not account for the next piece,
which sometimes has tragic consequences. It does not attempt to
"slide" pieces into place. It does not try to maximize score (the
score is not part of the evaluation algorithm). The evaluation
function is kind of slow, so you should byte-compile this file.
