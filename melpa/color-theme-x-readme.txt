Given the name of a color theme, write out the .Xresources
equivalent of the theme.  You would want to do this if you want to
make Emacs start much faster than loading the theme from Lisp.

The approach taken here is to `read' the color-themes function out
of the color-themes source and then descend that stucture to print
out the .Xresource lines.

For those puzzling over the code:

The code makes a slight distiction between face settings and
"basic" settings.  Basic settings are: background-color,
foreground-color, cursor-color -- these attributes do not have same
possibilities that Emacs face attributes have.

Example usage:

    M-x color-theme-x RET classic RET ~/elisp/color-theme.el RET

Then if necessary, adjust the output in the
*color-theme-xresources* to taste, copy it to your ~/.Xresources
(don't use .Xdefaults -- it is obsolete) and run:

    xrdb -load ~/.Xresources
or
    xrdb -merge ~/.Xresources

(Depending on what is desired).  Then restart Emacs.
