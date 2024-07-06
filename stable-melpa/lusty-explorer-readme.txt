 -----------

To install, copy this file somewhere in your load-path and add this line to
your .emacs:

   (require 'lusty-explorer)

To launch the explorer, run or bind the following commands:

   M-x lusty-file-explorer
   M-x lusty-buffer-explorer

And then use as you would `find-file' or `switch-to-buffer'. A split window
shows the *Lusty-Matches* buffer, which updates dynamically as you type
using a fuzzy matching algorithm.  One match is highlighted; you can move
the highlight using C-n / C-p (next, previous) and C-f / C-b (next column,
previous column).  Pressing TAB or RET will select the highlighted match
(with slightly different semantics).

To create a new buffer with the given name, press C-x e.  To open dired at
the current viewed directory, press C-x d.
