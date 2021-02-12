
This is an attempt to implement a variant of `lispy-mode'
(https://github.com/abo-abo/lispy) for Python.  Unfortunately,
Python isn't nearly as well-structured as LISP.  But Python is
ubiquitous, and the less powerful `lpy-mode' is better than nothing
at all.

The basic idea of `lpy-mode' is to increase the editing efficiency
by binding useful navigation, refactoring and evaluation commands
to unprefixed keys, e.g. "j" or "e".  But only in certain point
positions, so that you are still able to use uprefixed keys to
insert themselves.

Example, here "|" represents the point position:

   print |("2+2=%d" % (2 + 2))

Here, if you press the key "e", the whole line will be evaluated
and "2+2=4" will be printed in the Echo Area.  Note that if
`lpy-mode' was off, pressing "e" would instead result in:

   print e|("2+2=%d" % (2 + 2))

So inserting any key isn't actually useful with that point position
and e.g. the "e" can be used for evaluating the current statement.

But, for instance, if you wanted to edit "print" into "printe", you
could do that in a straightforward way, just like you would with
`lpy-mode' off : with "C-b e".
