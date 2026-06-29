This implements the jump cursor feature found in vim.

A jump is added every time you insert a character on a different
line.

Jumps are remembered in a jump list.  With the C-o and C-i
command you can go to cursor positions before older jumps, and back
again.  Thus you can move up and down the list.

Jumps are read and saved in the same configuration file as vim so
you can switch back and forth between the two editors

THANKS:

Bram Moolenaar for writing a fine editor and helping needy children
in Uganda

Stefan Monnier for telling me how to add C-i binding

Ted Zlatanov for suggesting to use less aggressive key bindings

BUGS:

INSTALLATION:

put this file somewhere in your load path then put the put the
following in your .emacs:

(require 'jumpc)
(jumpc)

Then either:

(jumpc-bind-vim-key)

Or:

(global-set-key (kbd "<f8>") 'jumpc-jump-backward)
(global-set-key (kbd "<f9>") 'jumpc-jump-forward)

The first will bind C-i and C-o just like vim.  The second bind
function keys 8 and 9. Of course you can pick any keys you like.  If
you use Emacs on a console you will have to pick the second form as
C-i and TAB are the same thing.

If you use autoload you don't need to require the file

TODO

search for TODO within the file

Add rotate jump list feature in vim
  defined as JUMPLIST_ROTATE in mark.c
    "If last used entry is not at the top, put it at the top by
    rotating the stack until it is (the newer entries will be at
    the bottom). Keep one entry (the last used one) at the top."

Add a bit of looseness.  For example do not add jump points within
three lines of the last one.

Add jump list displaying each jump with the file and line in the
file.  Clicking on a line takes you to the jump location.

Add more commands that will insert jump.  Vim does: "'", "`", "G",
"/", "?", "n", "N", "%", "(", ")", "[[", "]]", "{", "}", ":s",
":tag", "L", "M", "H"

Remove files that do not exist when reading and writing from
configuration file

VERSION

version 1

version 2
 - don't force vim key bindings
 - remove debugging message
 - insert a jump moves the index back to top of list
 - insert jumps goes back to top of list

version 3
 - remove deleted files