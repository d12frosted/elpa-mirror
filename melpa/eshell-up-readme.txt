Package for quickly navigating to a specific parent directory in
eshell without having to repeatedly typing 'cd ..'.  This is
achieved using the 'eshell-up' function, which can be bound to an
eshell alias such as 'up'.  As an example, assume that the current
working directory is:

/home/user/first/second/third/fourth/fifth $

Now, in order to quickly go to (say) the directory named 'first' one
simply executes:

/home/user/first/second/third/fourth/fifth $ up fir
/home/user/first $

This command searches the current working directory from right to
left for a directory that matches the user's input ('fir' in this
case).  If a match is found then eshell changes to that directory,
otherwise it does nothing.

Other uses:

It is also possible to compute the matching parent directory
without changing to it.  This is achieved using the 'eshell-up-peek'
function, which can be bound to an alias such as 'pk'.  When this
function is used in combination with subshells the matching parent
directory can be passed as an argument to other
functions.  Returning to the previous example one can (for example)
list the contents of 'first' by executing:

/home/user/first/second/third/fourth/fifth $ ls {pk fir}
<directory contents>
...

It is recommended to invoke 'eshell-up' or 'eshell-up-peek' using
aliases as done in the examples above.  To do that, add the
following to your .eshell.aliases file:

alias up eshell-up $1
alias pk eshell-up-peek $1

This package is inspired by 'bd', which uses bash to implement
similar functionality.
See: https://github.com/vigneshwaranr/bd
