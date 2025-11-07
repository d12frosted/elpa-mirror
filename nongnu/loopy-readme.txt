                 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  LOOPY: A LOOPING AND ITERATION MACRO
                 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


[file:https://elpa.nongnu.org/nongnu/loopy.svg]
[file:https://elpa.nongnu.org/nongnu-devel/loopy.svg]
[file:https://melpa.org/packages/loopy-badge.svg]
[file:https://stable.melpa.org/packages/loopy-badge.svg]

――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

`loopy' is a macro meant for iterating and looping.  It is similar in
usage to [`cl-loop'] but uses symbolic expressions rather than keywords.

For most use cases, `loopy' should be a nice substitute for `cl-loop'
and complementary to the features provided by the [Seq] and [CL]
libraries and Emacs's regular looping and mapping features.

For detailed information, see [the documentation file].  This README is
just an overview.

See also the extension package [Loopy Dash], which provides
destructuring using the library `dash.el' and is described in more
detail below.

――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*	   NOTE*: Loopy is still in its latter middle stages.
Constructive criticism is welcome.  If you see a place for improvement,
			  please let me know.
――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

_Recent breaking changes:_
• Version 0.15.0:
  • Loopy now requires at least Emacs version 28.1, increased from
    version 27.1.
  • `set' now warns when it is not given a value.  In the future, it
    will signal an error.
  • `loopy-command-parsers' and `loopy-aliases' are deprecated in favor
    of a single hash table in the new user option `loopy-parsers'.  This
    simplified the code and will make adding local overrides easier.
  • `loopy-iter-bare-special-macro-arguments' and
    `loopy-iter-bare-commands' are deprecated in favor of the single
    variable `loopy-iter-bare-names'.
  • `when' and `unless' are now implemented separately, fixing when the
    commands are aliased.
  • Modifications to an implied `loopy-result' in `finally-do' will now
    be included in the implied return value of the macro.
  • `loopy-default-flags' is made obsolete to avoid conflicts between
    libraries.  Using a wrapping macro instead, such as the one given in
    Changelog or the Org/Info documentation.
• See the [change log] for less recent changes.


[file:https://elpa.nongnu.org/nongnu/loopy.svg]
<https://elpa.nongnu.org/nongnu/loopy.html>

[file:https://elpa.nongnu.org/nongnu-devel/loopy.svg]
<https://elpa.nongnu.org/nongnu-devel/loopy.html>

[file:https://melpa.org/packages/loopy-badge.svg]
<https://melpa.org/#/loopy>

[file:https://stable.melpa.org/packages/loopy-badge.svg]
<https://stable.melpa.org/#/loopy>

[`cl-loop']
<https://www.gnu.org/software/emacs/manual/html_node/cl/Loop-Facility.html#Loop-Facility>

[Seq]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Sequences-Arrays-Vectors.html>

[CL] <https://www.gnu.org/software/emacs/manual/html_node/cl/index.html>

[the documentation file] <file:doc/loopy-doc.org>

[Loopy Dash] <https://github.com/okamsn/loopy-dash>

[change log] <https://github.com/okamsn/loopy/blob/master/CHANGELOG.md>


1 Introduction
══════════════

  The `loopy' macro is used to generate code for a loop, similar to
  `cl-loop'.  Unlike `cl-loop', `loopy' uses parenthetical expressions
  instead of "clauses".

  ┌────
  │ ;; A simple usage of `cl-loop':
  │ (cl-loop for i from 1 to 10
  │ 	 if (cl-evenp i) collect i into evens
  │ 	 else collect i into odds
  │ 	 end ; This `end' keyword is optional here.
  │ 	 finally return (list odds evens))
  │ 
  │ ;; How it could be done using `loopy':
  │ (loopy (numbers i :from 1 :to 10)
  │        (if (cl-evenp i)
  │ 	   (collect evens i)
  │ 	 (collect odds i))
  │        (finally-return odds evens))
  └────

  `loopy' supports destructuring for iteration commands like `list' and
  accumulation commands like `sum' or `collect'.

  ┌────
  │ ;; Summing the nth elements of sub-arrays:
  │ ;; => (8 10 12 14 16 18)
  │ (loopy (list list-elem '(([1 2 3] [4 5 6])
  │ 			 ([7 8 9] [10 11 12])))
  │        (sum ([sum1 sum2 sum3] [sum4 sum5 sum6])
  │ 	    list-elem)
  │        (finally-return sum1 sum2 sum3 sum4 sum5 sum6))
  │ 
  │ ;; Separate the elements of sub-list:
  │ ;; => ((1 3) (2 4))
  │ (loopy (list i '((1 2) (3 4)))
  │        (collect (elem1 elem2) i)
  │        (finally-return elem1 elem2))
  └────

  The `loopy' macro is configurable and extensible.  In addition to
  writing one's own "loop commands" (such as `list' in the example
  above), by using "flags", one can choose whether to instead use
  `pcase-let', `seq-let', or even the Dash library for destructuring.

  ┌────
  │ ;; Use `pcase' to destructure array elements:
  │ ;; => ((1 2 3 4) (10 12 14) (11 13 15))
  │ (loopy (flag pcase)
  │        (array (or `(,car . ,cdr) digit)
  │ 	      [1 (10 . 11) 2 (12 . 13) 3 4 (14 . 15)])
  │        (if digit
  │ 	   (collect digits digit)
  │ 	 (collect cars car)
  │ 	 (collect cdrs cdr))
  │        (finally-return digits cars cdrs))
  │ 
  │ ;; Using the default destructuring:
  │ ;; => ((1 2 3 4) (10 12 14) (11 13 15))
  │ (loopy (array elem [1 (10 . 11) 2 (12 . 13) 3 4 (14 . 15)])
  │        (if (numberp elem)
  │ 	   (collect digits elem)
  │ 	 (collect (cars . cdrs) elem))
  │        (finally-return digits cars cdrs))
  └────

  Variables like `cars', `cdrs', and `digits' in the example above are
  automatically `let'-bound so as to not affect code outside of the
  loop.

  `loopy' has arguments for binding (or not binding) variables,
  executing code before or after the loop, executing code only if the
  loop completes, and for setting the macro's return value (default:
  `nil').  This is in addition to the looping features themselves.

  All of this makes `loopy' a useful and convenient choice for looping
  and iteration.


2 Similar Libraries
═══════════════════

  Loopy is not the only Lisp library that uses parenthetical expressions
  instead of keyword clauses (as in `cl-loop').  [Iterate] and [For] are
  two examples from Common Lisp.

  ┌────
  │ ;; Collecting 10 random numbers:
  │ 
  │ ;; cl-loop (Emacs Lisp)
  │ (cl-loop repeat 10 collect (random 10))
  │ 
  │ ;; loopy (Loopy)
  │ (loopy (repeat 10) (collect (random 10)))
  │ 
  │ ;; iterate (Common Lisp)
  │ (iterate (repeat 10) (collect (random 10)))
  │ 
  │ ;; for (Common Lisp)
  │ (for:for ((i repeat 10) (randoms collecting (random 10))))
  │ 
  └────

  Generally, all of the packages handle basic use cases in similar ways.
  One large difference is that `iterate' can embed its looping
  constructs in arbitrary code.  Loopy currently provides this feature
  as a separate macro, `loopy-iter', which expands looping constructs
  using `macroexpand' (see [Loop Commands in Arbitrary Code] in this
  README).

  Loopy is not yet feature complete.  Please request features or report
  problems in this project’s [issues tracker].  While basic uses are
  covered, some of the more niche features of `cl-loop' and `iterate'
  are still being added.


[Iterate] <https://common-lisp.net/project/iterate/>

[For] <https://github.com/Shinmera/for/>

[Loop Commands in Arbitrary Code] See section 5

[issues tracker] <https://github.com/okamsn/loopy/issues>


3 How to Install
════════════════

  Loopy can be installed from [Non-GNU ELPA] and [MELPA] as the package
  `loopy'.  The optional package `loopy-dash' can be installed to enable
  using the Dash library for destructuring (instead of other methods).

  ┌────
  │ (use-package loopy)
  │ 
  │ ;; Optional support for destructuring with Dash.
  │ (use-package loopy-dash
  │   :after (loopy)
  │   :demand t)
  └────

  To load all of the alternative destructuring libraries (see section
  [Multiple Kinds of Destructuring]) and the alternative macro form (see
  section [Loop Commands in Arbitrary Code]), use

  ┌────
  │ (use-package loopy
  │   :config
  │   (require 'loopy-iter)
  │   (require 'loopy-pcase)
  │   (require 'loopy-seq))
  │ 
  │ (use-package loopy-dash
  │   :after (loopy)
  │   :demand t)
  └────


[Non-GNU ELPA] <https://elpa.nongnu.org/nongnu/loopy.html>

[MELPA] <https://melpa.org/#/loopy>

[Multiple Kinds of Destructuring] See section 4

[Loop Commands in Arbitrary Code] See section 5


4 Multiple Kinds of Destructuring
═════════════════════════════════

  The default destructuring system is a super-set of what `cl-lib'
  provides and is described in the section [Basic Destructuring] in the
  documentation.

  In addition to the built-in destructuring style, `loopy' can
  optionally use destructuring provided by `pcase-let', `seq-let', and
  the `dash' library.  This provides greater flexibility and allows you
  to use destructuring patterns that you're already familiar with.

  These features can be enabled with "flags", described in the section
  [Using Flags] in the documentation.

  Here are a few examples that demonstrate how `loopy' can use
  destructuring with accumulation commands.

  ┌────
  │ (require 'loopy-dash)
  │ ;; => (((1 (2 3)) (4 (5 6))) ; whole
  │ ;;     (1 4)                 ; i
  │ ;;     (3 6))                ; k
  │ (loopy (flag dash)
  │        (list elem '((1 (2 3)) (4 (5 6))))
  │        (collect (whole &as i (_ k)) elem)
  │        (finally-return whole i k))
  │ 
  │ ;; = > ((3 5) (4 6))
  │ (loopy (flag dash)
  │        (list (&plist :a a  :b b)
  │ 	     '((:a 3  :b 4 :c 7) (:g 8 :a 5 :b 6)))
  │        (collect a-vals a)
  │        (collect b-vals b)
  │        (finally-return a-vals b-vals))
  │ 
  │ (require 'loopy-pcase)
  │ ;; => ((1 4) (3 6))
  │ (loopy (flag pcase)
  │        (list elem '((1 (2 3)) (4 (5 6))))
  │        (collect `(,a (,_ ,b)) elem)
  │        (finally-return a b))
  │ 
  │ ;; => ((1 6) (3 8) ([4 5] [9 10]))
  │ (require 'loopy-seq)
  │ (loopy (flag seq)
  │        (list elem '([1 2 3 4 5] [6 7 8 9 10]))
  │        (collect [a _ b &rest c] elem)
  │        (finally-return a b c))
  └────

  For more on how `dash' does destructuring, see their documentation on
  the [-let] expression.


[Basic Destructuring]
<https://github.com/okamsn/loopy/blob/master/doc/loopy-doc.org#basic-destructuring>

[Using Flags]
<https://github.com/okamsn/loopy/blob/master/doc/loopy-doc.org#using-flags>

[-let] <https://github.com/magnars/dash.el#-let-varlist-rest-body>


5 Loop Commands in Arbitrary Code
═════════════════════════════════

  The macro `loopy-iter' can be used to embed loop commands in arbitrary
  code.  It is similar in use to Common Lisp's Iterate macro, but it is
  not a port of Iterate to Emacs Lisp.

  ┌────
  │ (require 'loopy-iter)
  │ 
  │ ;; => ((1 2 3) (-3 -2 -1) (0))
  │ ;; Things to node:
  │ ;; - `accum-opt' produces more efficient accumulations for names variables
  │ ;; - `cycling' is another name for `repeat'
  │ ;; => ((-9 -8 -7 -6 -5 -4 -3 -2 -1)
  │ ;;     (0)
  │ ;;     (1 2 3 4 5 6 7 8 9 10 11))
  │ (loopy-iter (accum-opt positives negatives zeroes)
  │ 	    (numbering i :from -10 :to 10)
  │ 	    ;; Normal `let' and `pcase', not Loopy constructs:
  │ 	    (let ((var (1+ i)))
  │ 	      (pcase var
  │ 		((pred cl-plusp)  (collecting positives var))
  │ 		((pred cl-minusp) (collecting negatives var))
  │ 		((pred zerop)     (collecting zeroes var))))
  │ 	    (finally-return negatives zeroes positives))
  │ 
  │ ;; => 6
  │ (loopy-iter (listing elem '(1 2 3))
  │ 	    (funcall #'(lambda (x) (summing x))
  │ 		     elem))
  └────

  For more on this, [see the documentation].


[see the documentation]
<https://github.com/okamsn/loopy/blob/master/doc/loopy-doc.org#the-loopy-iter-macro>


6 Adding Custom Commands
════════════════════════

  It is easy to create custom commands for Loopy.  To see how, see the
  section [Custom Commands] in the documentation.


[Custom Commands]
<https://github.com/okamsn/loopy/blob/master/doc/loopy-doc.org#custom-commands>


7 Comparing to `cl-loop'
════════════════════════

  See the documentation page [Comparing to `cl-loop'].  See also the
  wiki page [Speed Comparisons].


[Comparing to `cl-loop']
<https://github.com/okamsn/loopy/blob/master/doc/loopy-doc.org#comparing-to-cl-loop>

[Speed Comparisons]
<https://github.com/okamsn/loopy/wiki/speed-comparisons>


8 Real-World Examples
═════════════════════

  See the wiki page [Examples].


[Examples] <https://github.com/okamsn/loopy/wiki/Examples>
