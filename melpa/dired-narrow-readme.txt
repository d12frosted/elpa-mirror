This package provides live filtering of files in dired buffers.  In
general, after calling the respective narrowing function you type a
filter string into the minibuffer.  After each change the changes
automatically reflect in the buffer.  Typing C-g will cancel the
narrowing and restore the original view, typing RET will exit the
live filtering mode and leave the dired buffer in the narrowed
state.  To bring it back to the original view, you can call
`revert-buffer' (usually bound to `g').

During the filtering process, several special functions are
available.  You can customize the binding by changing
`dired-narrow-map'.

* `dired-narrow-next-file' (<down> or C-n) - move the point to the
  next file
* `dired-narrow-previous-file' (<up> or C-p) - move the point to the
  previous file
* `dired-narrow-enter-directory' (<right> or C-j) - descend into the
  directory under point and immediately go back to narrowing mode

You can customize what happens after exiting the live filtering
mode by customizing `dired-narrow-exit-action'.

These narrowing functions are provided:

* `dired-narrow'
* `dired-narrow-regexp'
* `dired-narrow-fuzzy'

You can also create your own narrowing functions quite easily.  To
define new narrowing function, use `dired-narrow--internal' and
pass it an apropriate filter.  The filter should take one argument
which is the filter string from the minibuffer.  It is then called
at each line that describes a file with point at the beginning of
the file name.  If the filter returns nil, the file is removed from
the view.  As an inspiration, look at the built-in functions
mentioned above.

See https://github.com/Fuco1/dired-hacks for the entire collection.
