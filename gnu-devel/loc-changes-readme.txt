[![Build Status](https://travis-ci.org/rocky/emacs-loc-changes.png)](https://travis-ci.org/rocky/emacs-loc-changes)

Keeps track of important buffer positions after buffer changes.

Sometimes it is useful to make note of certain locations in program
code. For example these might be error locations reported in a
compilation. Or you could be inside a debugger and change the source
code but want to continue debugging.

Without this, the positions that a compilation error report or that a
debugger refers to may be a little off from the modified source.

This package tries to ameliorate that by allowing a user or program
(e.g. a debugger front-end) to set marks to track the original
locations.
