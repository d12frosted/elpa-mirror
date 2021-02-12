This package manages multiple search results buffers:
- the search results of grep, lgrep, rgrep, and find-grep are sent
  to separate buffers instead of overwriting the contents of a single
  buffer (buffers are named *grep*<N> where N is a number)
- several navigation functions are provided to allow the user to treat
  the search results buffers as a stack and/or ring, and to easily reset
  the state of each search buffer after navigating through the results

Installation:

1. Put this file in a directory that is a member of load-path, and
   byte-compile it (e.g. with `M-x byte-compile-file') for better
   performance.
2. Add the following to your ~/.emacs:
   (require 'grep-a-lot)
   (grep-a-lot-setup-keys)
3. If you're using igrep.el you may want to add:
   (grep-a-lot-advise igrep)

Currently, there are no customization options.

Default Key Bindings:

Ring navigation:
M-g ]         Go to next search results buffer, restore its current search context
M-g [         Ditto, but selects previous buffer.
              Navigation is cyclic.

Stack navigation:
M-g -         Pop to previous search results buffer (kills top search results buffer)
M-g _         Clear the search results stack (kills all grep-a-lot buffers!)

Other:
M-g =         Restore buffer and position where current search started
