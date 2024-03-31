To try this, just type: M-x landmark-test-run

Landmark is a relatively non-participatory game in which a robot
attempts to maneuver towards a tree at the center of the window
based on unique olfactory cues from each of the 4 directions. If
the smell of the tree increases, then the weights in the robot's
brain are adjusted to encourage this odor-driven behavior in the
future. If the smell of the tree decreases, the robots weights are
adjusted to discourage a correct move.

In laymen's terms, the search space is initially flat. The point
of training is to "turn up the edges of the search space" so that
the robot rolls toward the center.

Further, do not become alarmed if the robot appears to oscillate
back and forth between two or a few positions. This simply means
it is currently caught in a local minimum and is doing its best to
work its way out.

The version of this program as described has a small problem. a
move in a net direction can produce gross credit assignment. for
example, if moving south will produce positive payoff, then, if in
a single move, one moves east,west and south, then both east and
west will be improved when they shouldn't

Many thanks to Yuri Pryadkin <yuri@rana.usc.edu> for this
concise problem description.