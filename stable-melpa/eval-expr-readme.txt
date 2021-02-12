Updates of this program may be available via the URL
http://www.splode.com/~friedman/software/emacs-lisp/

To use this package, put this in your .emacs:

   (require 'eval-expr)
   (eval-expr-install)

Highlights:

  * When reading the Lisp object interactively from the minibuffer, the
    minibuffer uses the Emacs Lisp Mode syntax table.  (Emacs 19.18 or
    later only.)

  * If you type an incomplete or otherwise syntactically invalid
    expression (e.g. you forget a closing paren), you can fix your
    mistake without having to type it all over again.

  * Can display the result in a buffer if it is too big to fit in the
    echo area.  This buffer is placed in Emacs Lisp Mode.
    (If you give a prefix arg, the result is placed in the current
    buffer instead of the echo area or a separate temporary buffer.)

  * The variables `eval-expr-print-level' and `eval-expr-print-length'
    can be used to constrain the attempt to print recursive data
    structures.  These variables are independent of the global
    `print-level' and `print-length' variables so that eval-expression
    can be used more easily for debugging.

  * Pretty-printing complex results via `pp' function is possible.

This program is loosely based on an earlier implemention written by Joe
Wells <jbw@cs.bu.edu> called eval-expression-fix.el (last revised
1991-10-12).  That version was originally written for Emacs 18 and,
while it worked with some quirky side effects in Emacs 19, created even
more problems in Emacs 20 and didn't work in XEmacs at all.

This rewrite should work in Emacs 19.18 or later and any version of
XEmacs.  However it will not work in Emacs 18.
