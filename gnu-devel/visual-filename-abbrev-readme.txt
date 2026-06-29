This minor mode abbreviates the directory part of filenames by using
overlays.  For example, a longish filename like

   /home/myuser/Documents/Letters/Personal-Family/Letter-to-John.tex

will be displayed like this:

  /h…/m…/D…/L…/P…-F…/Letter-to-John.tex

By default, the abbreviate display is disabled when point enters the overlay
so that you can edit the file name normally.  Also, abbreviated file names
are only shown if the abbreviation as actually shorter as the original one
(which depends on what you add as replacement).

There's stuff to customize, just check `M-x customize-group RET
visual-filename-abbrev RET'.