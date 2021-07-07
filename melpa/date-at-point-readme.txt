This file provides an additional `date' thing for `thing-at-point'
function.

Using:

1. Add (require 'date-at-point) to your elisp code.
2. Use (thing-at-point 'date).

A default regexp (`date-at-point-regexp') is trying to match any
possible date style, e.g.: "2014-12-31", "31.12.2014", "12/31/14",
etc.  If you find problems with the current regexp, please contact
the maintainer.
