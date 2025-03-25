Elcute is a library defining the minor mode `elcute-mode' for
marking and killing lines electrically in the spirit of Paredit.
Lines are marked and killed rounding up to whole expressions,
without escaping any containing expression.

Supported major modes are Lisp Data mode, Inferior Lisp mode, nXML
mode, SML mode and Inferior SML mode.  The library is scarcely
useful in other modes; in particular, the commands do not work in C
mode.
