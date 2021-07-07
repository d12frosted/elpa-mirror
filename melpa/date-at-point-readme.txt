This file provides an additional `date' thing for `thing-at-point'
function.

Using:

1. Add (require 'date-at-point) to your elisp code.
2. Use (thing-at-point 'date).

By default, a date in "2013-03-09"-like format is matched.  This can
be changed with `date-at-point-regexp' variable.
