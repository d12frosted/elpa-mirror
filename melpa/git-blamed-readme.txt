
Here is an Emacs implementation of incremental git-blame.  When you
turn it on while viewing a file, the editor buffer will be updated by
setting the background of individual lines to a color that reflects
which commit it comes from.  And when you move around the buffer, a
one-line summary will be shown in the echo area.
