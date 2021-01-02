MMM Mode is a minor mode that allows multiple major modes to
coexist in a single buffer. Refer to the documentation of the
function `mmm-mode' for more detailed information. This file
contains mode on/off functions and the mode keymap, but mostly
just loads all the subsidiary files.

;{{{ Parameter Naming

Since version 0.3.7, I've tried to use a uniform scheme for naming
parameters. Here's a brief summary.

BEG and END refer to the beginning and end of a region.
FRONT and BACK refer to the respective delimiters of a region.
FRONT- and BACK-OFFSET are the offsets from delimiter matches.
FRONT-BEG through BACK-END are the endings of the delimiters.
START and STOP bound actions, like searching, fontification, etc.

;}}}
;{{{ CL and Parameters

Keyword parameters can be nice because it makes it easier to see
what's getting passed as what. But I try not to use them in user
functions, because CL doesn't make good documentation strings.
Similarly, any hook or callback function can't take keywords,
since Emacs as a whole doesn't use them. And for small parameter
lists, they are overkill. So I use them only for a large number of
optional parameters, such as `mmm-make-region'.

An exception is the various submode class application functions,
which all take all their arguments as keywords, for consistency
and so the classes alist looks nice.

When using keyword arguments, defaults should *always* be supplied
in all arglists. (This pertains mostly to :start and :stop
arguments, usually defaulting to (point-min) and (point-max)
respectively.) `mmm-save-keywords' should only be used for lists
with more than four arguments, such as in `mmm-ify-by-regexp'.

In general, while I have no qualms about using things from CL like
`cl-mapl', `cl-loop' and `cl-destructuring-bind', I try not to use `cl-defun'
more than I have to. For one, it sometimes makes bad documentation
strings. Furthermore, to a `defun'ned function, a nil argument is
the same as no argument, so it will use its (manual) default, but
to a `cl-defun'ned function, a nil argument *is* the argument, so
any default specified in the arglist will be ignored. Confusion of
this type should be avoided when at all possible.

}}}
