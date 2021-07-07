Package for quickly navigating to a specific parent directory in
eshell without having to repeatedly typing 'cd ..'.  This is
achieved using the 'eshell-up' function, which can be bound to an
eshell alias such as 'up'.  As an example, assume that the current
working directory is:

/home/user/first/second/third/fourth/fifth $

Now, in order to quickly go to (say) the directory named 'first' one
simply executes:

/home/user/first/second/third/fourth/fifth $ up fi
/home/user/first $

This command searches the current working directory from right to
left (while skipping the current directory, 'fifth') for a
directory that matches the user's input ('fi' in this case).  If a
match is found then eshell changes to that directory, otherwise it
does nothing.

It is recommended to invoke 'eshell-up' using an alias as done in
the example above.  To do that, add the following to your
.eshell.aliases file:

alias up eshell-up $1

The complete description of eshell-up, including other features, is
available at: https://github.com/peterwvj/eshell-up

This package is inspired by 'bd', which uses bash to implement
similar functionality.

See: https://github.com/vigneshwaranr/bd
