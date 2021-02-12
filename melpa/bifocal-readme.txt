In bifocal-mode, paging up causes a comint-mode buffer to be split into two
windows with a larger window on top (the head) and a smaller input window
preserved on the bottom (the tail):

+--------------+
| -------      |
| -------      |
| -------      |
|    [head]    |
|(show history)|
+--------------+
|    [tail]    |
|(show context)|
+--------------+

This helps with monitoring new output and entering text at the prompt (in the
tail window), while reviewing previous output (in the head window).  Paging
down all the way causes the split to disappear.

Note if you're not on the last line of a buffer, no split will appear.

This version tested with Emacs 25.2.1

See README.org for more details.

; Installation:

1. Move this file to a directory in your load-path or add
   this to your .emacs:
   (add-to-list 'load-path "~/path/to/this-file/")
2. Next add this line to your .emacs:
   (require 'bifocal)
