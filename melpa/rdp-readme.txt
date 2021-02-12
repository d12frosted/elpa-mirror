This library provides a recursive descent parser for parsing
languages in buffers. Some support is provided for implementing
automatic indentation based on the parser.

In general, the only two functions you need to worry about are:

* `rdp-parse'        -- parse the current buffer
* `rdp-parse-string' -- parse a string (in a temp buffer)

A grammar is provided to the parser as an alist of patterns.
Patterns are named by symbols, which can reference other
patterns. The lisp object type indicates the type of the pattern:

* string -- an Emacs regular expression
* list   -- "and" relationship, each pattern must match in order
* vector -- "or" relationship, one of the patterns must match
* symbol -- recursive reference to another pattern in the alist

The global variable `rdp-best' indicates the furthest point reached
in the buffer by the parser. If parsing failed (i.e. `rdp-best' is
not at the end of the buffer), this is likely to be the position of
the syntax error.

For example, this grammar parses simple arithmetic with operator
precedence and grouping.

    (defvar arith-tokens
      '((sum       prod  [([+ -] sum)  no-sum])
        (prod      value [([* /] prod) no-prod])
        (num     . "-?[0-9]+\\(\\.[0-9]*\\)?")
        (+       . "\\+")
        (-       . "-")
        (*       . "\\*")
        (/       . "/")
        (pexpr     "(" [sum prod num pexpr] ")")
        (value   . [pexpr num])
        (no-prod . "")
        (no-sum  . "")))

Given just this grammar to `rdp-parse' it will return an
s-expression of the input where each token match is `cons'ed with
the token name. To make this more useful, the s-expression can be
manipulated as it is read using an alist of token names and
functions. This could be used to simplify the s-expression, build
an interpreter that interprets during parsing, or even build a
compiler.

For example, this function alist evaluates the arithmetic as it is
parsed:

    (defun arith-op (expr)
      (destructuring-bind (a (op b)) expr
        (funcall op a b)))

    (defvar arith-funcs
      `((sum     . ,#'arith-op)
        (prod    . ,#'arith-op)
        (num     . ,#'string-to-number)
        (+       . ,#'intern)
        (-       . ,#'intern)
        (*       . ,#'intern)
        (/       . ,#'intern)
        (pexpr   . ,#'cadr)
        (value   . ,#'identity)
        (no-prod . ,(lambda (e) '(* 1)))
        (no-sum  . ,(lambda (e) '(+ 0)))))

Putting this all together:

(defun arith (string)
  (rdp-parse-string string arith-tokens arith-funcs))

(arith "(1 + 2 + 3 + 4 + 5) * -3/4.0")

Tips:

Recursive descent parsers *cannot* be left-recursive. It is
important that a pattern does not recurse without first consuming
some input. Any grammar can be made non-left-recursive but not
necessarily simplistically.

The parser requires a lot of stack! Consider increasing
`max-lisp-eval-depth' by some factor before calling
`rdp-parse'. After increasing it, running out of stack space is
likely an indication of left-recursion somewhere in the grammar.

Token functions should not have side effects. Due to the
backtracking of the parser, just because the function was called
doesn't mean there was actually a successful match. Also, these
functions are free to return nil or the empty list as such a return
is *not* an indication of failure.

By default, whitespace is automatically consumed between matches
using the function `rdp-skip-whitespace'. If some kinds of
whitespace are important or if there are other characters that need
to be skipped, temporarily override this function with your own
definition using `flet' when calling `rdp-parse'.

In general don't try to parse comments in the grammar. Strip them
from the buffer before calling the parser.

Indentation facilities:

To find out where in the parse tree a point lies, set `rdp-start'
to the desired point before starting parsing. After parsing, either
successfully or not,`rdp-point-stack' will contain a stack of
tokens indicating roughly where in the parse tree the point
lies.

To use this for rudimentary indentation, set `rdp-start' to the
`beginning-of-line' of the current point and count how many
indent-worthy tokens are in the stack once parsing is complete.

See also:

* http://emacswiki.org/emacs/peg.el
* http://www.gnu.org/software/emacs/manual/html_node/elisp/SMIE.html
* http://cedet.sourceforge.net/semantic.shtml
* http://en.wikipedia.org/wiki/Recursive_descent_parser
* http://en.wikipedia.org/wiki/Parsing_expression_grammar
