To use this program, put this file in your `load-path',
and put the following autoload in your ~/.emacs:

  (autoload 'volume "volume"
    "Tweak your sound card volume." t)

Then type `M-x volume <RET>' to run the program.  Of course,
use `M-x customize-group <RET> volume <RET>' to customize it.

Tweaking the volume of my music used to be one of the
few things I constantly went outside of Emacs to do.
I just decided I've had enough of that, and so I wrote
this simple mixer frontend.

It comes with backend glue for aumix and amixer, but the
latter is pretty slow, so I have to recommend the former.
If you can't use either, writing your own glue should be
straightforward.  And if you do, please consider sending
the code to me, so I can integrate it into this file.
