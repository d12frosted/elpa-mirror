This library provides common desirable features using the Org interface for
blocks and links:

0. A unified interface, the `org-defblock' macro, for making new block and link types.

1. Colours: Regions of text and inline text can be coloured using 19 colours;
 easily extendable; below is an example.

            #+begin_red org
            /This/
                  *text*
                         _is_
                              red!
            #+end_red

2. Multiple columns: Regions of text are exported into multiple side-by-side
columns

3. Remarks: First-class visible editor comments

4. Details: Regions of text can be folded away in HTML

5. Badges: SVG badges have the pleasant syntax
badge:key|value|colour|url|logo; only the first two are necessary.

6. Tooltips: Full access to Lisp documentation as tooltips, or any other
documentation-backend, including user-defined entries; e.g., doc:thread-first
retrives the documentation for thread-first and attachs it as a tooltip to
the text in the HTML export and as a glossary entry in the LaTeX export

7. Various other blocks: Solution, spoiler (“fill in the blanks”).

The .el files are the source of truth; org-special-block-extras.org is the
manual, with further examples demonstrating these blocks.

Full documentation can be found at
https://alhassy.com/org-special-block-extras

; Design: Implementation strategy, trade-offs, and constraints

The purpose of this section is to add rigour to what are otherwise vague
intuitions regarding the overall structure of this system. (Which I will
forget in a month's time.)


1. [Motivating Observation] People export Org to HTML and LaTeX complex
environments, such as folding text away in <details> blocks or enclosing
prose in \begin{theorem} environments.

2. [Observation of Burden] This requires users to learn about HTML/LaTeX, but
often there are common “blocks” that users would like to have, for which
there is no `cl-defun' like mechanism to define them.

3. [Insight] We propose to provide what we think are common blocks ---such as
details, box, parallel, kbd, tooltips, Lisp docs--- and to provide a
`cl-defun' like macro named `org-defblock' to allow users to provide support
for how new special blocks should be implemented, with respect to any
backend. Moreover, we want this to be “extensible” by end-users and so borrow
the existing “#+begin_src ⟨language⟩ :arg value” syntax to also work with our
special blocks. That is, each special block may now have an optional “main
argument” (such as ⟨language⟩) and may have optional additional keyword-value
pair arguments.

4. [Additional Problems] However, sometimes it is awkward to use a verbose
special block when you only want to invoke it on a single word. As such, we
propose that `org-defblock' also incorporates the support of Org links; so
that users may write “doc:thread-last” instead of “#+begin_doc \n thread-last
\n #+end_doc”. That is, we will provide a `org-deflink' and
`org-defblock-only' methods and, for the convenience of users, also provide
their combination in the method `org-defblock'.

5. [Improvement] Converse to ♯4, users may have swashes of text and it can be
awkward to phrase them in a large special block. As such, `org-deftag' lets
users write “* my section :my_block: \n contents” instead of
“#+begin_my_block \n contents \n #+end_block”; `org-defblock' declares such a
tag for each block, unless given “:tag nil”.  For instance, tagging a section
“:details:” exports it to HTML folded away in a <details> element.

6. [Implementation Overview] Special blocks “#+begin_foo ⟨args⟩ \n ⟨contents⟩
\n #+end_foo” are captured by the structure `org-special-block', which is
parsed by `org-special-block-after-point'.  Then methods that rewrite a
special block by its implementation (for a backend) are called to rewrite
such blocks as a pre-processing step before export actually occurs. This is
handled by `org--rewrite-special-blocks-by-handlers'.  To figure out what
should be rewritten and what should not be re-written, the global variable
`org--supported-blocks' maintains all names introduced by `org-defblock'.

7. [Code Organisation] `org-defblock', `org-deflink', and `org-deftag' each live in a file of their name, as do
`org-thread-blockcall' and, in org-block-header-args.el, the blocks' header-args; the :demo
switch lives in org-demo.el.  The blocks and links built atop
them live in org-links.el, org-color-links.el, org-details-block.el, org-box-block.el, org-callout-blocks.el,
org-parallel-block.el, org-proof-block.el, org-margin-blocks.el, org-quote-block.el, org-solution-block.el,
org-spoiler-block.el, org-remark-block.el, org-substitution-blocks.el, and
org-math-block.el, whose parts are org-math-markup.el, org-math-structure.el, org-math-hints.el, and org-math-refs.el
---one file per family of blocks; this file requires them all and defines the mode.  The graph block, org-graph-block.el,
needs Graphviz and so is opt-in: (require 'org-graph-block); see graphs-README.org.


🤔 Did you think “That was all straightforward, why even bother writing it down?”
If so, then I've succeeded in communicating my thoughts to you and my future-self.
If not, please reach out with feedback.

; TODO: Declare `indent' for org-defblock, org-defblock-only, and org-deflink

(declare (indent indent-spec))

Indent calls to this function or macro according to indent-spec. This is typically used for macros, though it works for functions too. See Indenting Macros.

; TODO: Declare which arg of org-defblock, org-defblock-only, and org-deflink are intended as docstrings
  (declare (doc-string 4) (indent defun))
This is used when defining a function or macro which itself will be used to define entities like functions, macros, or variables. It indicates that the nth argument, if any, should be considered as a documentation string.

See https://www.gnu.org/software/emacs/manual/html_node/elisp/Declare-Form.html

MA: Perhaps this changes indentation? Or gives linting support?
TODO: Write a poor docstring for a `cl-defun' so that I see flycheck errors (eg extra dots, spaces, etc);
then, change it to be a `org-defblock-only' and see if I still get the errors.
THEN, register the declaration (doc-string …) and check if I get an errors now.

; Declareing type info: (ftype type)

Declare “type” to be the type of this function. This type is used by
describe-function for documentation, and by the native compiler (see
Compilation of Lisp to Native Code) for optimizing code generation and
inferring types. Incorrect type declarations may cause crashes in natively
compiled code (see below). Functions with type declarations are shown by C-h
C-f as having a “declared type”.

(defun my/positive-p (x)
  (declare (ftype (function (number) boolean)))
  (when (> x 0)
    t))

HAS DOCS:

    (my/positive-p X)

    Declared type: (function (number) boolean)

    Not documented.


“type” is a type specifier (see Type Specifiers) of the form (function
(arg-1-type … arg-n-type) RETURN-TYPE). Argument types can be interleaved
with &optional and &rest to reflect the function’s calling convention (see
Features of Argument Lists).

For more details, see https://www.gnu.org/software/emacs/manual/html_node/elisp/Declare-Form.html.
Note: Function type /specifications/ can be sophisticated.
; TODO: Declare defuns as pure + side-effect-free, when approriate

Evaluating a form may also make changes that persist; these changes are
called “side effects”. An example of a form that produces a side effect is
(setq foo 1). The computation can also have side effects, such as lasting
changes in the values of variables or the contents of data structures.

A “pure function” is a function which, in addition to having no side effects,
always returns the same value for the same combination of arguments,
regardless of external factors such as machine type or system state.

;; (pure val)
If the value is non-nil, the named function is considered to be pure (see
What Is a Function?). Calls with constant arguments can be evaluated at
compile time.

;; (side-effect-free val)
If val is non-nil, this function is free of side effects, so the byte compiler can ignore calls whose value is ignored.

A non-nil value indicates that the named function is free of side effects
(see What Is a Function?), so the byte compiler may ignore a call whose value
is unused. If the property’s value is error-free, the byte compiler may even
delete such unused calls.
;; (important-return-value val)
If val is non-nil, the byte compiler will warn about calls to this function that do not use the returned value.

A non-nil value makes the byte compiler warn about code that calls the named
function without using its returned value. This is useful for functions where
doing so is likely to be a mistake.
;; > When it comes to marking, what would be the practical benefit?

You will know that this function is 'pure' & 'side-effect-free', it's easier
to comprehend such a code. If such a 'marker' would exist it would also
encourage others to make such a functions.

Also, users (i.e., future-me) would get helpful warnings:
;;;;; Warn about more ignored function return values.
;;;;; The compiler now warns when the return value from certain functions is
;;;;; implicitly ignored.  Example:
;;;;;
;;;;; (progn (nreverse my-list) my-list)
;;;;;
;;;;; will elicit a warning because it is usually pointless to call
;;;;; 'nreverse' on a list without using the returned value.
;;;;;
;;;;; To silence the warning, make use of the value in some way, such as
;;;;; assigning it to a variable.  You can also wrap the function call in
;;;;; '(ignore ...)', or use 'with-suppressed-warnings' with the warning
;;;;; name 'ignored-return-value'.
;;;;;
;;;;; The warning will only be issued for calls to functions declared
;;;;; 'important-return-value' or 'side-effect-free' (but not 'error-free').
;;;;;
;;;;; See also: https://emacs.stackexchange.com/a/28341

If a pure, side-effect-free function is given constant arguments, the result
of the computation can be determined at compile time, as it's guaranteed not
to change. e.g. https://www.reddit.com/r/emacs/comments/134j38g/comment/jigs0ba/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button

