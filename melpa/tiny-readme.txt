
To set it up, just bind e.g.:

    (global-set-key (kbd "C-;") #'tiny-expand)

Usage:
This extension's main command is `tiny-expand'.
It's meant to quickly generate linear ranges, e.g. 5, 6, 7, 8.
Some elisp proficiency is an advantage, since you can transform
your numeric range with an elisp expression.

There's also some emphasis on the brevity of the expression to be
expanded: e.g. instead of typing (+ x 2), you can do +x2.
You can still do the full thing, but +x2 would save you some
key strokes.

You can test out the following snippets by positioning the point at
the end of the expression and calling `tiny-expand':

  m10
  m5 10
  m5,10
  m5 10*xx
  m5 10*xx%x
  m5 10*xx|0x%x
  m25+x?a%c
  m25+x?A%c
  m97,122(string x)
  m97,122stringxx
  m97,120stringxupcasex
  m97,120stringxupcasex)x
  m\n;; 10|%(+ x x) and %(* x x) and %s
  m10*2+3x
  m\n;; 10expx
  m5\n;; 20expx%014.2f
  m7|%(expt 2 x)
  m, 7|0x%02x
  m10|%0.2f
  m1\n14|*** TODO http://emacsrocks.com/e%02d.html
  m1\n10|convert img%s.jpg -monochrome -resize 50%% -rotate 180 img%s_mono.pdf
  (setq foo-list '(m1 11+x96|?%c))
  m1\n10listx+x96|convert img%s.jpg -monochrome -resize 50%% -rotate 180 img%c_mono.pdf
  m1\n10listxnthxfoo-list|convert img%s.jpg -monochrome -resize 50%% -rotate 180 img%c_mono.pdf
  m\n;; 16list*xxx)*xx%s:%s:%s
  m\n8|**** TODO Learning from Data Week %(+ x 2) \nSCHEDULED: <%(date "Oct 7" (* x 7))> DEADLINE: <%(date "Oct 14" (* x 7))>

As you might have guessed, the syntax is as follows:

  m[<range start:=0>][<separator:= >]<range end>[Lisp expr]|[format expr]

    x is the default var in the elisp expression.  It will take one by one
    the value of all numbers in the range.

    | means that elisp expr has ended and format expr has begun.
    It can be omitted if the format expr starts with %.
    The keys are the same as for format.
    In addition %(sexp) forms are allowed.  The sexp can depend on x.

  Note that multiple % can be used in the format expression.
  In that case:
  - if the Lisp expression returns a list, the members of this list
    are used in the appropriate place.
  - otherwise, it's just the result of the expression repeated as
    many times as necessary.

Alternatively, if user does not want to type in the "tiny
expressions", they can call the `tiny-helper' command that helps
construct the "tiny expression", and then expands that.

For example, the below two are equivalent:

 - Type "m2_9+1*x2"
 - M-x tiny-expand

OR

 - M-x tiny-helper
 - 9 RET 2 RET _ RET +1*x2 RET RET (user entry in the interactive prompts)
