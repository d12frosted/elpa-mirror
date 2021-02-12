Shadchen: A pattern matching library
====================================

    shadchen: Noun
      matchmaker
    from Yiddish

(note: there is an emacs lisp port of this library
 [here][shadchen-el])
(note: if you are reading this README for the emacs version of the
 library, keep in mind that emacs symbols are case sensitive.  Symbols
 are all lowercase in this library.)


I love pattern-matching, which I find to be a great way to combine
destructuring data with type-checking when used in dynamic languages.
If you aren't familiar with how pattern matching works, here is an
example:

    (defun second (lst)
     (match lst
      ((cons _ (cons x rest)) x)))

`MATCH` introduces a pattern matching expression, which takes a value,
in this case `LST` and a series of lists, whose first elements are
descriptions of a data structure and whose subsequent elements are
code to execute if the match succeeds.  Pattern matching takes the
description of the data and binds the variables that appear therein to
the parts of the data structure they indicate.  Above, we match `_` to
the `car` of a list, `x` to the `car` of that list's `cdr`, and `rest`
to the `cdr` of that list.

If we don't pass in a list, the match fails.  (Because of the behavior
of CL's `car` and `cdr`, which return `NIL` on `NIL`, the form `cons`
doesn't enforce a length requirement on the input list, and will
return `NIL` for an empty list.  This corresponds with the fact that
in Common Lisp `(car nil)` is `nil` and `(cdr nil)` is `nil`.)

We might instead write:

    (defun second-of-two (lst)
      (match lst
        ((list _ x) x)))

Which returns the second element of a list _only_ when a two element
list is passed in.  `MATCH` can take multiple pattern/body sets, in
which case patterns are tried in order until one pattern matches, and
the result of evaluating the associated forms is returned.  If no
patterns match, an error is raised.

Built-in Patterns
-----------------

Shadchen supports the following built-in patterns.

    <SYMBOL>

Matches anything, binding <SYMBOL> to that value in the body
expressions.

    <KEYWORD-LITERAL>

Matches only when the value is the same keyword.

    <NUMBER-LITERAL>

Matches only when the value is the same number.

    <STRING-LITERAL>

Matches only when the value is `string=` is the same string.

    (CONS <PATTERN1> <PATTERN2>)

Matches any `CONS` cell, or `NIL`, then matches `<PATTERN1>` and
`<PATTERN2>`, executing the body in a context where their matches are
bound.  If the match value is NIL, then each `PATTERN` matches against
NIL.

    (LIST <P1> ... <PN>)

Matches a list of length N, then matches each pattern `<PN>` to the
elements of that list.

    (LIST-REST <P1> ... <PN> <REST-PATTERN>)

Matches <P1> - <PN> to elements in at list, as in the `LIST` pattern.
The final `<REST-PATTERN>` is matched against the rest of the list.

    (LIST* <P1> ... <PN> <REST-PATTERN>)

LIST* is an alias for LIST-REST.

    (PLIST key <pattern> ...)

Matches a plist by matching each <pattern> against the key it is paired with.

    (ALIST key <pattern> ...)

Matches an alist by matching each <pattern> against the key it is paired with.

    (QUOTE DATUM)

Only succeeds when `DATUM` is `EQUALP` to the match-value.  Binds no
values.

     (AND <P1> .. <PN>)

Tests all `<PN>` against the same value, succeeding only when all
patterns match, and binding all variables in all patterns.

     (OR <P1> .. <PN>)

Tries each `<PN>` in turn, and succeeds if any `<PN>` succeeds.  The
body of the matched expression is then executed with that `<PN>'s`
bindings.  It is up to the user to ensure that the bindings are
relevant to the body.

     (? PREDICATE <PATTERN>)

Succeeds when `(FUNCALL PREDICATE MATCH-VALUE)` is true and when
`<PATTERN>` matches the value.  Body has the bindings of `<PATTERN>`.

     (FUNCALL FUN <PATTERN>)

Applies `FUN` to the match value, then matches `<PATTERN>` against _the
result_.

     (BQ EXPR)

Matches as if by `BACKQUOTE`.  If `EXPR` is an atom, then this is
equivalent to `QUOTE`.  If `EXPR` is a list, each element is matches
as in `QUOTE`, unless it is an `(UQ <PATTERN>)` form, in which case it
is matched as a pattern.  Eg:

    (match (list 1 2 3)
      ((BQ (1 (UQ x) 2)) x))

Will succeed, binding `X` to 2.

    (match (list 10 2 20)
       ((BQ (1 (UQ x) 2)) x))

Will fail, since `10` and `1` don't match.

    (values <P1> ... <PN>)

Will match multiple values produced by a `(values ...)` form.

    (let (n1 v1) (n2 v2) ... (nn vn))

Not a pattern matching pattern, per se.  `let` always succeeds and
produces a context where the bindings are active.  This can be used to
provide default alternatives, as in:

    (defun not-nil (x) x)

    (match (list 1)
     ((cons hd (or (? #'non-nil tl)
                   (let (tl '(2 3)))))
      (list hd tl)))

Will result in `(1 (2 3))` but

    (match (list 1 4)
     ((cons hd (or (? #'non-nil tl)
                   (let (tl '(2 3)))))
      (list hd tl)))

Will produce `(1 (4))`.  Note that a similar functionality can be
provided with `funcall`.

    (concat P1 ... PN)

Concat is a powerful string matching pattern.  If each pattern is a
string, its behavior is simple: it simply matches the string that is
the concatenation of the pattern strings.

If any of the patterns are a more complex pattern, then, starting from
the left-most pattern, the shortest substring matching the first
pattern is matched, ad then matching proceeds on the subsequent
patterns and the unmatched part of the string.  Eg:

    (match "bobcatdog"
     ((concat
       (and (or "bobcat" "cat") which)
       "dog") which))

will produce "bobcat", but the pattern will also match "catdog",
returning "cat".

This is a handy pattern for simple parsers.

    (append P1 ... PN)

Like `concat` except for lists rather than strings:

    (match
       (number-sequence 1 10)
     ((append (list 1) _ (list y)) y))  => 10

the interveening numbers are matched away.

Match-let
---------

Match let is a form which behaves identically to a let expression
with two extra features: first, the each variable can be an arbitrary
shadchen pattern and secondly, one can invoke `recur` in any tail
position of the body to induce a trampolined re-entry into the let
expression, so that self-recursive loops can be implemented without
blowing the stack.

eg:

    (match-let
     (((list x y) (list 0 0)))
     (if (< (+ x y) 100)
         (recur (list (+ x 1) (+ y x)))
       (list x y)))

Will result in `(14 91)`.

If you like this feature, please let me know if you would like it to
check that `recur` is in tail position.  This is an expensive step
which requires walking the body after macro-expansion, which may also
introduce subtle bugs.  The upside of doing this is that you avoid the
possibly strange bugs encountered when `recur` is invoked in a
non-tail position.

User feedback will vary how I approach this.

defun-match
-----------

This special form allows the definition of functions using pattern
matching where bodies can be specified over multiple `defun-match`
invokations:


    (defun-match- product (nil)
       "The empty product."
       1)

    (defun-match product (nil acc)
       "Recursion termination."
       acc)

    (defun-match product
        ((cons (p #'numberp n)
               (p #'listp rest))
         (p #'numberp acc))
       "Main body of the product function."
       (recur rest (* n acc)))

    (defun-match product (lst)
       "Calculate the product of the numbers in LST."
       (recur lst 1))

Note that different bodies can `recur` to eachother without growing
the stack.  Documentation for each body is accumulated, along with the
pattern associated with the body, into the function's complete
documentation.



Extending shadchen
------------------

Users can define their own patterns using the `defpattern` form.  For
instance, the behavior of `CONS`, which matches the empty list, may
not be desired.  We can define a match which doesn't have this
behavior as:

    (defun non-nil (x) x)
    (defpattern cons* (car cdr)
     `(? #'non-nil (cons ,car ,cdr)))

A pattern is a function which takes the arguments passed into the
custom pattern, and expands them into a new pattern in the language of
the built-in pattern-matching.

We can now say:

    (match (cons 10 11)
     ((cons* a b) a))

Which will produce 10, but:

    (match nil
     ((cons* a b) a))

Will raise a no-match error.

Judicious application of the matchers `AND`, `FUNCALL`, and `?` allow
the definition of arbitrary matchers without exposing the guts of the
matching system.

* * *

    Copyright 2012, Vincent Toups
    This program is distributed under the terms of the GNU Lesser
    General Public License (see license.txt).

[shadchen-el]:https://github.com/VincentToups/emacs-utils/blob/master/shadchen.el
