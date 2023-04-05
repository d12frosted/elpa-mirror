Functions for moving, marking and killing by clause.

A clause is delimited by , ; : ( ) and en or em dashes. You can add extra
delimiters by customizing `clause-extra-delimiters'.

We do our best to imitate `forward-sentence'/`backward-sentence'
functionity, rather than rolling with our own preferences, even though with
clauses it can only be approximated. So moving forward should leave point
after the (last) clause character, before any space, while moving backward
should leave point after any clause character and after any space.

If sentex is installed <https://codeberg.org/martianh/sentex>, set
`clause-use-sentex' to t and clause.el will use its complex sentence-ending
rules.
