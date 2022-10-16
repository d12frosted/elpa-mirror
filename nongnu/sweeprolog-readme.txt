		 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		  SWEEP: SWI-PROLOG EMBEDDED IN EMACS

			      Eshel Yaron
			   me@eshelyaron.com
		 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual describes the Emacs package `sweep' (or `sweeprolog'), which
provides an embedded SWI-Prolog runtime inside of Emacs.

Table of Contents
─────────────────

Overview
.. High-level architecture
Installation
Getting started
Prolog initialization and cleanup
Querying Prolog
.. Conversion of Elisp objects to Prolog terms
.. Conversion of Prolog terms to Elisp objects
.. Example - counting solutions for a Prolog predicate in Elisp
.. Calling Elisp function inside Prolog queries
Editing Prolog code
.. Indentation
..... Indentation rules
.. Semantic highlighting
..... Available styles
..... Highlighting occurrences of a variable
..... Quasi-quotation highlighting
.. Aligning with multiple spaces
.. Term-based editing and motion commands
.. Definitions and references
.. Following file specifications
.. Loading buffers
.. Using templates for creating new modules
.. Documenting predicates
.. Displaying predicate documentation
.. Examining diagnostics
.. Exporting predicates
The Prolog top-level
.. Multiple top-levels
.. The Top-level Menu buffer
.. Sending signals to running top-levels
.. Top-level history
.. Completion in the top-level
Finding Prolog code
.. Prolog file specification expansion
Quick access to sweep commands
Examining Prolog messages
Setting Prolog flags
Installing Prolog packages
Contributing
.. Setting up sweep for local development
.. Submitting patches and bug reports
Things to do
.. Improvements around editing Prolog
.. Improvements around running Prolog
.. General improvements
Indices
.. Function index
.. Variable index
.. Keystroke index
.. Concept index


Overview
════════

  `sweep' is an embedding of SWI-Prolog in Emacs.  It provides an
  interface for executing Prolog queries and consuming their results
  from Emacs Lisp (see Querying Prolog).  `sweep' further builds on top
  of this interface and on top of the standard Emacs facilities to
  provide advanced features for developing SWI-Prolog programs in Emacs.


High-level architecture
───────────────────────

  `sweep' uses the C interfaces of both SWI-Prolog and Emacs Lisp to
  create a dynamically loaded Emacs module that contains the SWI-Prolog
  runtime.  As such, `sweep' has parts written in C, in Prolog and in
  Emacs Lisp.

  The different parts of `sweep' are structured as follows:

  • `sweep.c' defines a dynamic Emacs module which is referred to from
    Elisp as `sweep-module'. This module is linked against the
    SWI-Prolog runtime library (`libswipl') and exposes a subset of the
    SWI-Prolog C interface to Emacs in the form of Elisp functions (see
    Querying Prolog). Notably, `sweep-module' is responsible for
    translating Elisp objects to Prolog terms and vice versa.

  • `sweeprolog.el' defines an Elisp library (named simply
    `sweeprolog'), which builds on top of `sweep-module' to provide
    user-facing commands and functionality. It is also responsible for
    loading and compiling the dynamically loaded `sweep-module'.

  • `sweep.pl' defines a Prolog module (named, unsurprisingly, `sweep')
    which is by default arranged by `sweeprolog.el' to be loaded when
    the embedded Prolog runtime is initialized. It contains predicates
    that `sweeprolog.el' invoke through `sweep-module' to facilitate its
    different commands (see Finding Prolog code).


Installation
════════════

  The dynamic Emacs module `sweep-module' is included in the SWI-Prolog
  distribution from version 8.5.18.  For instructions on how to build
  and install SWI-Prolog, see <https://www.swi-prolog.org/build/>.

  The `sweeprolog' Elisp package is available on NonGNU ELPA, to install
  `sweeprolog' simply type `M-x package-install RET sweeprolog RET'.

  An alternative to installing from ELPA is to get the Elisp library
  from the `sweep' Git repository:

  1. Clone the `sweep' repository:
     ┌────
     │ git clone https://git.sr.ht/~eshel/sweep
     └────

     Or:

     ┌────
     │ git clone https://github.com/SWI-Prolog/packages-sweep sweep
     └────

  2. Add `sweep' to Emacs’ `load-path':
     ┌────
     │ (add-to-list 'load-path "/path/to/sweep")
     └────


Getting started
═══════════════

  After installing the `sweeprolog' Elisp library, load it into Emacs:

  ┌────
  │ (require 'sweeprolog)
  └────

  All set!  `sweeprolog' automatically loads `sweep-module' and
  initializes the embedded SWI-Prolog runtime.  For a description of the
  different features of `sweep', see the following sections of this
  manual.

  _Important note for Linux users_: prior to version 29, Emacs would
  load dynamic modules in a way that is not fully compatible with the
  way the SWI-Prolog native library, `libswipl', loads its own native
  extensions.  This may lead to `sweep' failing after loading
  `sweep-module'.  To work around this issue, users running Emacs 28 or
  earlier on Linux can start Emacs with `libswipl' loaded upfront via
  `LD_PRELOAD', for example:

  ┌────
  │ LD_PRELOAD=/usr/local/lib/libswipl.so emacs
  └────


Prolog initialization and cleanup
═════════════════════════════════

  The embedded SWI-Prolog runtime must be initialized before it can
  start executing queries.  In `sweep', Prolog initialization is done
  via the C-implemented `sweeprolog-initialize' Elisp function defined
  in `sweep-module'.  `sweeprolog-initialize' takes one or more
  arguments, which must all be strings, and initializes the embedded
  Prolog as if it were invoked externally in a command line with the
  given strings as command line arguments, where the first argument to
  `sweeprolog-initialize' corresponds to `argv[0]'.

  By default, `sweeprolog.el' will initialize Prolog automatically when
  it is loaded into Emacs.  The arguments used to initialize Prolog in
  that case are determined by the value of the user-option
  `sweeprolog-init-args' which the user is free to extend with e.g.:

  ┌────
  │ (add-to-list 'sweeprolog-init-args "--stack-limit=512m")
  └────

  The default value of `sweeprolog-init-args' is set to load the Prolog
  helper library `sweep.pl' and to create a boolean Prolog flag `sweep',
  set to `true', which indicates to SWI-Prolog that it is running under
  `sweep'.

  To inhibit `sweeprolog' from initializing Prolog on load, set the
  user-option `sweeprolog-init-on-load' to nil.

  The embedded Prolog runtime can be reset using the command
  `sweeprolog-restart'.  This command cleans up the the Prolog state and
  resources, and starts it anew.  When called with a prefix argument
  (`C-u M-x sweeprolog-restart'), this command prompts the user for
  additional initialization arguments to pass to the embedded Prolog
  runtime on startup.


Querying Prolog
═══════════════

  `sweep' provides the Elisp function `sweeprolog-open-query' for
  invoking Prolog predicates.  The invoked predicate must be of arity
  two and will be called in mode `p(+In, -Out)' i.e. the predicate
  should treat the first argument as input and expect a variable for the
  second argument which should be unified with some output.  This
  restriction is placed in order to facilitate a natural calling
  convention between Elisp, a functional language, and Prolog, a logical
  one.

  The `sweeprolog-open-query' function takes five arguments, the first
  three are strings which denote:
  • The name of the Prolog context module from which to execute the
    query,
  • The name of the module in which the invoked predicate is defined,
    and
  • The name of the predicate to call.

  The fourth argument to `sweeprolog-open-query' is converted into a
  Prolog term and used as the first argument of the predicate (see
  Conversion of Elisp objects to Prolog terms).  The fifth argument is
  an optional “reverse” flag, when this flag is set to non-nil, the
  order of the arguments is reversed such that the predicate is called
  in mode `p(-Out, +In)' rather than `p(+In, -Out)'.

  The function `sweeprolog-next-solution' can be used to examine the
  results of a query.  If the query succeeded,
  `sweeprolog-next-solution' returns a cons cell whose `car' is either
  the symbol `!' when the success was deterministic or `t' otherwise,
  and the `cdr' is the current value of the second (output) Prolog
  argument converted to an Elisp object (see Conversion of Prolog terms
  to Elisp objects).  If the query failed, `sweeprolog-next-solution'
  returns nil.

  `sweep' only executes one Prolog query at a given time, thus queries
  opened with `sweeprolog-open-query' need to be closed before other
  queries can be opened.  When no more solutions are available for the
  current query (i.e. after `sweeprolog-next-solution' returned nil), or
  when otherwise further solutions are not of interest, the query must
  be closed with either `sweeprolog-cut-query' or
  `sweeprolog-close-query'. Both of these functions close the current
  query, but `sweeprolog-close-query' also destroys any Prolog bindings
  created by the query.


Conversion of Elisp objects to Prolog terms
───────────────────────────────────────────

  `sweep' converts Elisp objects into Prolog terms to allow the Elisp
  programmers to specify arguments for Prolog predicates invocations
  (see `sweeprolog-open-query').  Seeing as some Elisp objects, like
  Elisp compiled functions, wouldn’t be as useful for a passing to
  Prolog as others, `sweep' only converts Elisp objects of certain types
  to Prolog, namely we convert /trees of strings and numbers/:

  • Elisp strings are converted to equivalent Prolog strings.
  • Elisp integers are converted to equivalent Prolog integers.
  • Elisp floats are converted to equivalent Prolog floats.
  • The Elisp nil object is converted to the Prolog empty list `[]'.
  • Elisp cons cells are converted to Prolog lists whose head and tail
    are the Prolog representations of the `car' and the `cdr' of the
    cons.


Conversion of Prolog terms to Elisp objects
───────────────────────────────────────────

  `sweep' converts Prolog terms into Elisp object to allow efficient
  processing of Prolog query results in Elisp (see
  `sweeprolog-next-solution').

  • Prolog strings are converted to equivalent Elisp strings.
  • Prolog integers are converted to equivalent Elisp integers.
  • Prolog floats are converted to equivalent Elisp floats.
  • A Prolog atom `foo' is converted to a cons cell `(atom . "foo")'.
  • The Prolog empty list `[]' is converted to the Elisp nil object.
  • Prolog lists are converted to Elisp cons cells whose `car' and `cdr'
    are the representations of the head and the tail of the list.
  • Prolog compounds are converted to list whose first element is the
    symbol `compound'. The second element is a string denoting the
    functor name of the compound, and the rest of the elements are the
    arguments of the compound in their Elisp representation.
  • All other Prolog terms (variables, blobs and dicts) are currently
    represented in Elisp only by their type:
    ⁃ Prolog variables are converted to the symbol `variable',
    ⁃ Prolog blobs are converted to the symbol `blob', and
    ⁃ Prolog dicts are converted to the symbol `dict'.


Example - counting solutions for a Prolog predicate in Elisp
────────────────────────────────────────────────────────────

  As an example of using the `sweep' interface for executing Prolog
  queries, we show an invocation of the non-deterministic predicate
  `lists:permutation/2' from Elisp where we count the number of
  different permutations of the list `(1 2 3 4 5)':

  ┌────
  │ (sweeprolog-open-query "user" "lists" "permutation" '(1 2 3 4 5))
  │ (let ((num 0)
  │       (sol (sweeprolog-next-solution)))
  │   (while sol
  │     (setq num (1+ num))
  │     (setq sol (sweeprolog-next-solution)))
  │   (sweeprolog-close-query)
  │   num)
  └────


Calling Elisp function inside Prolog queries
────────────────────────────────────────────

  The `sweep-module' defines the foreign Prolog predicates
  `sweep_funcall/2' and `sweep_funcall/3', which allow for calling Elisp
  functions from Prolog code.  These predicates may only be called in
  the context of a Prolog query initiated by `sweeprolog-open-query',
  i.e. only in the Prolog thread controlled by Emacs.  The first
  argument to these predicates is a Prolog string holding the name of
  the Elisp function to call.  The last argument to these predicates is
  unified with the return value of the Elisp function, represented as a
  Prolog term (see Conversion of Elisp objects to Prolog terms).  The
  second argument of `sweep_funcall/3' is converted to an Elisp object
  (see Conversion of Prolog terms to Elisp objects) and passed as a sole
  argument to the invoked Elisp function.  The `sweep_funcall/2' variant
  invokes the Elisp function without any arguments.


Editing Prolog code
═══════════════════

  `sweep' includes a dedicated major mode for reading and editing Prolog
  code, called `sweeprolog-mode'.  To activate this mode in a buffer,
  type `M-x sweeprolog-mode'.  To instruct Emacs to always open Prolog
  files in `sweeprolog-mode', modify the Emacs variable
  `auto-mode-alist' like so:

  ┌────
  │ (add-to-list 'auto-mode-alist '("\\.pl\\'"   . sweeprolog-mode))
  │ (add-to-list 'auto-mode-alist '("\\.plt\\'"  . sweeprolog-mode))
  └────


Indentation
───────────

  In `sweeprolog-mode' buffers, the appropriate indentation for each
  line is determined by a bespoke /indentation engine/.  The indentation
  engine analyses the syntactic context of a given line and determines
  the appropriate indentation to apply based on a set of rules.

  The entry point of the indentation engine is the function
  `sweeprolog-indent-line' which takes no arguments and indents that
  line at point.  `sweeprolog-mode' supports the standard Emacs
  interface for indentation by arranging for `sweeprolog-indent-line' to
  be called whenever a line should be indented, notably after pressing
  `TAB'.  For more a full description of the available commands and
  options that pertain to indentation, see [Indentation in the Emacs
  manual].


[Indentation in the Emacs manual] <info:emacs#Indentation>

Indentation rules
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Lines in `sweeprolog-mode' buffers are indented according to the
  following rules:

  1. If the current line starts inside a string or a multi-line comment,
     do not indent.
  2. If the current line starts with a top term, do not indent.
  3. If the current line starts with a closing parenthesis and the
     matching opening parenthesis is part of a functor, indent to the
     column of the opening parenthesis if any arguments appear on the
     same line as the functor, otherwise indent to the start of the
     functor.

     This rule yields the following layouts:

     ┌────
     │ some_functor(
     │     some_arg
     │ ).
     │ 
     │ some_functor( some_arg
     │ 	    ).
     └────

  1. If the current line is the first non-comment line of a clause body,
     indent to the starting column of the head term plus the value of
     the user option `sweeprolog-indent-offset' (by default, four extra
     columns).

     As an example, this rule yields the following layouts when
     `sweeprolog-indent-offset' is set to the default value of four
     columns:

     ┌────
     │ some_functor(arg1, arg2) :-
     │     body_term.
     │ 
     │ asserta( some_functor(arg1, arg2) :-
     │ 	     body_term
     │        ).
     └────

  2. If the current line starts with the right hand side operand of an
     infix operator, indent to the starting column of the first operand
     in the chain of infix operators of the same precedence.

     This rule yields the following layouts:

     ┌────
     │ head :- body1, body2, body3,
     │ 	body4, body5.
     │ 
     │ A is 1 * 2 ^ 3 * 4 *
     │      5.
     │ 
     │ A is 1 * 2 + 3 * 4 *
     │ 	     5.
     └────

  3. If the last non-comment line ends with a functor and its opening
     parenthesis, indent to the starting column of the functor plus
     `sweeprolog-indent-offset'.

     This rule yields the following layout:

     ┌────
     │ some_functor(
     │     arg1, ...
     └────

  4. If the last non-comment line ends with a prefix operator, indent to
     starting column of the operator plus `sweeprolog-indent-offset'.

     This rule yields the following layout:

     ┌────
     │ :- multifile
     │        predicate/3.
     └────


Semantic highlighting
─────────────────────

  `sweeprolog-mode' integrates with the standard Emacs `font-lock'
  system which is used for highlighting text in buffers (see [Font Lock
  in the Emacs manual]).  `sweeprolog-mode' highlights different tokens
  in Prolog code according to their semantics, determined through static
  analysis which is performed on demand.  When a buffer is first opened
  in `sweeprolog-mode', its entire contents are analyzed to collect and
  cache cross reference data, and the buffer is highlighted accordingly.
  In contrast, when editing and moving around the buffer, a faster,
  local analysis is invoked to updated the semantic highlighting in
  response to changes in the buffer.

  At any point in a `sweeprolog-mode' buffer, the command `C-c C-c' (or
  `M-x sweeprolog-colourise-buffer') can be used to update the cross
  reference cache and highlight the buffer accordingly.  When `flymake'
  integration is enabled, this command also updates the diagnostics for
  the current buffer (see [Examining diagnostics]).  This may be useful
  e.g. after defining a new predicate.

  If the user option `sweeprolog-colourise-buffer-on-idle' is set to
  non-nil (as it is by default), `sweeprolog-mode' also updates semantic
  highlighting in the buffer whenever Emacs is idle for a reasonable
  amount of time, unless the buffer is larger than the value of the
  `sweeprolog-colourise-buffer-max-size' user option ( 100,000 by
  default).  The minimum idle time to wait before automatically updating
  semantic highlighting can be set via the user option
  `sweeprolog-colourise-buffer-min-interval'.

  `sweep' defines three highlighting /styles/, each containing more than
  60 different faces (named sets of properties that determine the
  appearance of a specific text in Emacs buffers, see also [Faces in the
  Emacs manual]) to signify the specific semantics of each token in a
  Prolog code buffer.

  To view and customize all of the faces defined and used in `sweep',
  type `M-x customize-group RET sweeprolog-faces RET'.


[Font Lock in the Emacs manual] <info:emacs#Font Lock>

[Examining diagnostics] See section Examining diagnostics

[Faces in the Emacs manual] <info:emacs#Faces>

Available styles
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `sweep' comes with three highlighting styles:

  • The `default' style includes faces that mostly inherit from standard
    Emacs faces commonly used in programming modes.
  • The `light' style mimics the colors used in the SWI-Prolog built-in
    editor.
  • The `dark' style mimics the colors used in the SWI-Prolog built-in
    editor in dark mode.

  To choose a style, customize the user option `sweeprolog-faces-style'
  with `M-x customize-option RET sweeprolog-faces-style RET'.  The new
  style will apply to all new `sweeprolog-mode' buffers.  To apply the
  new style to an existing buffer, use `C-x x f' (`font-lock-update') in
  that buffer.


Highlighting occurrences of a variable
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `sweeprolog-mode' can highlight all occurrences of a given Prolog
  variable in the clause in which it appears.  By default, occurrences
  of the variable at point are highlighted automatically whenever the
  cursor is moved into a variable.  To achieve this, `sweep' uses the
  Emacs minor mode `cursor-sensor-mode' which allows for running hooks
  when the cursor enters or leaves certain text regions (see also
  [Special Properties in the Elisp manual]).

  To disable automatic variable highlighting based on the variable at
  point, customize the variable `sweeprolog-enable-cursor-sensor' to
  nil.

  To manually highlight occurrences of a variable in the clause
  surrounding point, `sweeprolog-mode' provides the command `M-x
  sweeprolog-highlight-variable'.  This command prompts for variable to
  highlight, defaulting to the variable at point, if any.  If called
  with a prefix argument (`C-u M-x sweeprolog-highlight-variable'), it
  clears all variable highlighting in the current clause instead.


[Special Properties in the Elisp manual] <info:elisp#Special Properties>


Quasi-quotation highlighting
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Quasi-quotations in `sweeprolog-mode' buffer are highlighted according
  to the Emacs mode corresponding to the quoted language by default.

  The association between SWI-Prolog quasi-quotation types and Emacs
  major modes is determined by the user option
  `sweeprolog-qq-mode-alist'.  To modify the default associations
  provided by `sweeprolog-mode', type `M-x customize-option RET
  sweeprolog-qq-mode-alist RET'.

  If a quasi-quotation type does not have a matching mode in
  `sweeprolog-qq-mode-alist', the function `sweeprolog-qq-content-face'
  is used to determine a default face for quoted content.

  For more information about quasi-quotations in SWI-Prolog, see
  [library(quasi_quotations) in the SWI-Prolog manual].


[library(quasi_quotations) in the SWI-Prolog manual]
<https://www.swi-prolog.org/pldoc/man?section=quasiquotations>


Aligning with multiple spaces
─────────────────────────────

  By convention, if-then-else constructs are aligned such that each goal
  starts at the fourth column after the /start/ of the opening
  parenthesis or operator, as follows:

  ┌────
  │ (   if
  │ ->  then
  │ ;   else
  │ *-> elif
  │ ;   true
  │ )
  └────

  To simplify maintaining the desired layout without manually counting
  spaces, `sweep' provides a command that updates the whitespace around
  point such that the next token is aligned to a (multiple of) four
  columns from the start of the previous token.

  To insert or update whitespace around point, use the command `M-x
  sweeprolog-align-spaces'.  For example, consider a `sweeprolog-mode'
  buffer with the following contents, where `^' designates the location
  of the cursor:

  ┌────
  │ foo :-
  │     (   if
  │     ;
  │      ^
  └────

  Calling `M-x sweeprolog-align-spaces' will insert three spaces, to
  yield the expected layout:

  ┌────
  │ foo :-
  │     (   if
  │     ;
  │ 	^
  └────

  In Emacs 29, the command `M-x cycle-spacing' is extensible through a
  list of callback functions stored in the variable
  `cycle-spacing-actions'.  `sweep' leverages this facility and adds
  `sweeprolog-align-spaces' as the first action of `cycle-spacing'.  To
  inhibit `sweeprolog-mode' from doing so, set the user option
  `sweeprolog-enable-cycle-spacing' to nil.

  Moreover, in Emacs 29 `cycle-spacing' is bound by default to `M-SPC',
  thus aligning if-then-else and similar constructs only requires typing
  `M-SPC' after the first token.

  In Emacs prior to version 29, users are advised to bind
  `sweeprolog-align-spaces' to `M-SPC' directly by adding the following
  lines to Emacs’ initialization file (see [The Emacs Initialization
  File]).

  ┌────
  │ (eval-after-load 'sweeprolog
  │   '(define-key sweeprolog-mode-map (kbd "M-SPC") #'sweeprolog-align-spaces))
  └────


[The Emacs Initialization File] <info:emacs#Init File>


Term-based editing and motion commands
──────────────────────────────────────

  Emacs includes many useful features for operating on syntactic units
  in source code buffer, such as marking, transposing and moving over
  expressions.  By default, these features are geared towards working
  with Lisp expressions, or “sexps”.  `sweeprolog-mode' extends the
  Emacs’ notion of syntactic expressions to accommodate for Prolog
  terms, which allows the standard sexp-based commands to operate on
  them seamlessly.

  [Expressions in the Emacs manual] covers the most important commands
  that operate on sexps, and by extension on Prolog terms.  Another
  useful command for Prolog programmers is `M-x kill-backward-up-list',
  bound by default to `C-M-^' in `sweeprolog-mode' buffers.  This
  command replaces the parent term containing the term at point with the
  term itself.  To illustrate the utility of this command, consider the
  following clause:

  ┌────
  │ head :-
  │     goal1,
  │     setup_call_cleanup(setup,
  │ 		       goal2,
  │ 		       cleanup).
  └────

  Now with point anywhere inside `goal2', calling
  `kill-backward-up-list' removes the `setup_call_cleanup/3' term
  leaving `goal2' to be called directly:

  ┌────
  │ head :-
  │     goal1,
  │     goal2.
  └────


[Expressions in the Emacs manual] <info:emacs#Expressions>


Definitions and references
──────────────────────────

  `sweeprolog-mode' integrates with the Emacs `xref' API to facilitate
  quick access to predicate definitions and references in Prolog code
  buffers.  This enables the many commands that the `xref' interface
  provides, like `M-.' for jumping to the definition of the predicate at
  point.  Refer to [Find Identifiers in the Emacs manual] for an
  overview of the available commands.

  `sweeprolog-mode' also integrates with Emacs’ `imenu', which provides
  a simple facility for looking up and jumping to definitions in the
  current buffer.  To jump to a definition in the current buffer, type
  `M-x imenu' (bound by default to `M-g i' in Emacs version 29).  For
  information about customizing `imenu', see [Imenu in the Emacs
  manual].


[Find Identifiers in the Emacs manual] <info:emacs#Find Identifiers>

[Imenu in the Emacs manual] <info:emacs#Imenu>


Following file specifications
─────────────────────────────

  File specifications that occur in `sweeprolog-mode' buffers can be
  followed with `C-c C-o' (or `M-x sweeprolog-find-file-at-point')
  whenever point is over a valid file specification.  For example,
  consider a Prolog file buffer with the common directive
  `use_module/1':

  ┌────
  │ :- use_module(library(lists)).
  └────

  With point in any position inside `library(lists)', typing `C-c C-o'
  will open the `lists.pl' file in the Prolog library.

  For more information about file specifications in SWI-Prolog, see
  [absolute_file_name/3] in the SWI-Prolog manual.


[absolute_file_name/3]
<https://www.swi-prolog.org/pldoc/doc_for?object=absolute_file_name/3>


Loading buffers
───────────────

  The command `M-x sweeprolog-load-buffer' can be used to load the
  contents of a `sweeprolog-mode' buffer into the embedded SWI-Prolog
  runtime.  After a buffer is loaded, the predicates it defines can be
  queried from Elisp (see Querying Prolog) and from the `sweep'
  top-level (see The Prolog top-level).  In `sweeprolog-mode' buffers,
  `sweeprolog-load-buffer' is bound by default to `C-c C-l'.  By default
  this command loads the current buffer if its major mode is
  `sweeprolog-mode', and prompts for an appropriate buffer otherwise.
  To choose a different buffer to load while visiting a
  `sweeprolog-mode' buffer, invoke `sweeprolog-load-buffer' with a
  prefix argument (`C-u C-c C-l').

  More relevant information about loading code in SWI-Prolog can be
  found in [Loading Prolog source files] in the SWI-Prolog manual.


[Loading Prolog source files]
<https://www.swi-prolog.org/pldoc/man?section=consulting>


Using templates for creating new modules
────────────────────────────────────────

  `sweep' integrates with the Emacs `auto-insert' facility to simplify
  creation of new SWI-Prolog modules.  `auto-insert' allows for
  populating newly created files with templates defined by the relevant
  major mode.

  `sweep' associates a Prolog module skeleton with `sweeprolog-mode',
  the skeleton begins with a “file header” multi-line comment which
  includes the name and email address of the user based on the values of
  `user-full-name' and `user-mail-address' respectively.  A `module/2'
  directive is placed after the file header, with the module name set to
  the base name of the file.  Lastly the skeleton inserts a `PlDoc'
  module comment to be filled with the module’s documentation (see [File
  comments in the SWI-Prolog manual]).

  As an example, after inserting the module skeleton, a new Prolog file
  `foo.pl' will have the following contents:

  ┌────
  │ /*
  │     Author:        John Doe
  │     Email:         john.doe@example.com
  │ 
  │ */
  │ 
  │ :- module(foo, []).
  │ 
  │ /** <module> foo
  │ 
  │ */
  │ 
  └────

  The multi-line comment included above the `module/2' directive can be
  extended by customizing the user option
  `sweeprolog-module-header-comment-skeleton', which see.  This can be
  useful for including e.g. copyright text in the file header.

  To open a new Prolog file, use the standard `C-x C-f' (`find-file')
  and select a location for the new file.  In the new `sweeprolog-mode'
  buffer, type `M-x auto-insert' to insert the Prolog module skeleton.

  To automatically insert the module skeleton when opening new files in
  `sweeprolog-mode', enable the minor mode `auto-insert-mode'.  For
  detailed information about `auto-insert' and its customization
  options, see [Autoinserting in the Autotyping manual].


[File comments in the SWI-Prolog manual]
<https://www.swi-prolog.org/pldoc/man?section=sectioncomments>

[Autoinserting in the Autotyping manual] <info:autotype#Autoinserting>


Documenting predicates
──────────────────────

  SWI-Prolog predicates can be documented with specially structured
  comments placed above the predicate definition, which are processed by
  the `PlDoc' source documentation system.  Emacs comes with many useful
  commands specifically intended for working with comments in
  programming languages, which apply also to writing `PlDoc' comments
  for Prolog predicates.  For an overview of the relevant standard Emacs
  commands, see [Comment Commands in the Emacs manual].

  `sweep' also includes a dedicated command called
  `sweeprolog-document-predicate-at-point' for interactively creating
  `PlDoc' comments for predicates in `sweeprolog-mode' buffers.  This
  command, bound by default to `C-c C-d', finds the beginning of the
  predicate definition under or right above the current cursor location,
  and inserts formatted `PlDoc' comments while prompting the user to
  interactively fill in the argument modes, determinism specification,
  and initial contents of the predicate documentation.
  `sweeprolog-document-predicate-at-point' leaves the cursor at the end
  of the newly inserted documentation comment for the user to extend or
  edit it if needed.  To add another comment line, use `M-j'
  (`comment-indent-new-line') which starts a new line with the comment
  prefix filled in.  To reformat the current paragraph of `PlDoc'
  comments, use `M-q' (`fill-paragraph').

  For more information about `PlDoc' and source documentation in
  SWI-Prolog, see [the PlDoc manual].


[Comment Commands in the Emacs manual] <info:emacs#Comment Commands>

[the PlDoc manual]
<https://www.swi-prolog.org/pldoc/doc_for?object=section(%27packages/pldoc.html%27)>


Displaying predicate documentation
──────────────────────────────────

  `sweep' integrates with the Emacs minor mode `ElDoc', which
  automatically displays documentation for the predicate at point.
  Whenever the cursor enters a predicate definition or invocation, the
  signature and summary of that predicate are displayed in the echo area
  at the bottom of the frame.

  To disable the `ElDoc' integration in `sweeprolog-mode' buffers,
  customize the user option `sweeprolog-enable-eldoc' to nil.


Examining diagnostics
─────────────────────

  `sweeprolog-mode' can diagnose problems in Prolog code and report them
  to the user by integrating with `flymake', a powerful interface for
  on-the-fly diagnostics built into Emacs.

  `flymake' integration is enabled by default, to disable it customize
  the user option `sweeprolog-enable-flymake' to nil.

  When this integration is enabled, several `flymake' commands are
  available for listing and jumping between found errors.  For a full
  description of these commands, see [Finding diagnostics in the Flymake
  manual].  Additionally, `sweeprolog-mode' configures the standard
  command `M-x next-error' to operate on `flymake' diagnostics.  This
  allows for moving to the next (or previous) error location with the
  common `M-g n' (or `M-g p') keybinding.  For more information about
  these commands, see [Compilation Mode in the Emacs manual].

  The command `sweeprolog-show-diagnostics' shows a list of `flymake'
  diagnostics for the current buffer.  It is bound by default to `C-c
  C-`' in `sweeprolog-mode' buffers with `flymake' integration enabled.
  When called with a prefix argument (`C-u C-c C-`'), shows a list of
  diagnostics for all buffers in the current project.


[Finding diagnostics in the Flymake manual] <info:flymake#Finding
diagnostics>

[Compilation Mode in the Emacs manual] <info:emacs#Compilation Mode>


Exporting predicates
────────────────────

  By default, a predicate defined in Prolog module is not visible to
  dependent modules unless they it is /exported/, by including it in the
  export list of the defining module (i.e. the second argument of the
  `module/2' directive).

  `sweep' provides a convenient command for exporting predicates defined
  in `sweeprolog-mode' buffer.  To add the predicate near point to the
  export list of the current module, use the command `C-c C-e'
  (`sweeprolog-export-predicate').  If the current predicate is
  documented with a `PlDoc' comment, a comment with the predicate’s mode
  is added after the predicate name in the export list.  If point is not
  near a predicate definition, calling `sweeprolog-export-predicate'
  will prompt for a predicate to export, providing completion candidates
  based on the non-exported predicates defined in the current buffer.
  To force prompting for a predicate, invoke
  `sweeprolog-export-predicate' with a prefix argument (`C-u C-c C-e').


The Prolog top-level
════════════════════

  `sweep' provides a classic Prolog top-level interface for interacting
  with the embedded Prolog runtime.  To start the top-level, use `M-x
  sweeprolog-top-level'.  This command opens a buffer called
  `*sweeprolog-top-level*' which hosts the live Prolog top-level.

  The top-level buffer uses a major mode named
  `sweeprolog-top-level-mode'. This mode derives from `comint-mode',
  which is the common mode used in Emacs REPL interfaces.  As a result,
  the top-level buffer inherits the features present in other
  `comint-mode' derivatives, most of which are described in [the Emacs
  manual].


[the Emacs manual] <info:emacs#Shell Mode>

Multiple top-levels
───────────────────

  Any number of top-levels can be created and used concurrently, each in
  its own buffer.  If a top-level buffer already exists,
  `sweeprolog-top-level' will simply open it by default.  To create
  another one or more top-level buffers, run `sweeprolog-top-level' with
  a prefix argument (i.e. `C-u M-x sweeprolog-top-level-mode') to choose
  a different buffer name.  Alternatively, run the command `C-x x u' (or
  `M-x rename-uniquely') in the buffer called `*sweeprolog-top-level*'
  and then run `M-x sweeprolog-top-level' again.  This will change the
  name of the original top-level buffer to something like
  `*sweeprolog-top-level*<2>' and allow the new top-level to claim the
  buffer name `*sweeprolog-top-level*'.


The Top-level Menu buffer
─────────────────────────

  `sweep' provides a convenient interface for listing the active Prolog
  top-levels and operating on them, called the Top-level Menu buffer.
  This buffer shows the list of active `sweep' top-level buffers in a
  table that includes information and statistics for each top-level.

  To open the Top-level Menu buffer, use the command `M-x
  sweeprolog-list-top-levels'.  By default, the buffer is will be named
  `*sweep Top-levels*'.

  The Top-level Menu buffer uses a special major mode named
  `sweeprolog-top-level-menu-mode'.  This mode provides several commands
  that operate on the top-level corresponding to the table row at point.
  The available commands are:

  `RET' (`sweeprolog-top-level-menu-go-to')
        Open the specified top-level buffer.

  `k' (`sweeprolog-top-level-menu-kill')
        Kill the specified top-level buffer.

  `s' (`sweeprolog-top-level-menu-signal')
        Signal the specified top-level buffer (see [Sending signals to
        running top-levels]).

  `t' (`sweeprolog-top-level-menu-new')
        Create a new top-level buffer.

  `g' (`revert-buffer')
        Update the Top-level Menu contents.


[Sending signals to running top-levels] See section Sending signals to
running top-levels


Sending signals to running top-levels
─────────────────────────────────────

  When executing long running Prolog queries in the top-level, there may
  arise a need to interrupt the query, either to inspect the state of
  the top-level or to free it for running other queries.  To signal a
  `sweep' top-level that it should stop executing the current query and
  do something else instead, use the command `M-x
  sweeprolog-top-level-signal'.  This command prompts for an active
  `sweep' top-level buffer followed by a Prolog goal, and interrupts the
  top-level causing it to run the specified goal.

  In `sweeprolog-top-level-mode' buffers, the command
  `sweeprolog-top-level-signal-current' is available for signaling the
  current top-level.  It is bound by default to `C-c C-c'.

  It is also possible to signal top-levels from the `sweep' Top-level
  Menu buffer with the command `sweeprolog-top-level-menu-signal' with
  point at the entry corresponding to the wanted top-level (see The
  Top-level Menu buffer).

  For more information about interrupting threads in SWI-Prolog, see
  [Signaling threads in the SWI-Prolog manual].


[Signaling threads in the SWI-Prolog manual]
<https://www.swi-prolog.org/pldoc/man?section=thread-signal>


Top-level history
─────────────────

  `sweeprolog-top-level-mode' buffers provide a history of previously
  user inputs, similarly to other `comint-mode' derivatives such as
  `shell-mode'.  To insert the last input from the history at the
  prompt, use `M-p' (`comint-previous-input').  For a full description
  of history related commands, see [Shell History in the Emacs manual].

  The `sweep' top-level history only records inputs whose length is at
  least `sweeprolog-top-level-min-history-length'.  This user option is
  set to 3 by default, and should generally be set to at least 2 to keep
  the history from being clobbered with single-character inputs, which
  are common in the top-level interaction, e.g. `;' as used to invoke
  backtracking.


[Shell History in the Emacs manual] <info:emacs#Shell History>


Completion in the top-level
───────────────────────────

  The `sweeprolog-top-level-mode', enabled in the `sweep' top-level
  buffer, integrates with the standard Emacs symbol completion mechanism
  to provide completion for predicate names.  To complete a partial
  predicate name in the top-level prompt, use `C-M-i' (or `M-<TAB>').
  For more information see [Symbol Completion in the Emacs manual].


[Symbol Completion in the Emacs manual] <info:emacs#Symbol Completion>


Finding Prolog code
═══════════════════

  `sweep' provides the command `M-x sweeprolog-find-module' for
  selecting and jumping to the source code of a loaded or auto-loadable
  Prolog module.  `sweep' integrates with Emacs’ standard completion API
  to annotate candidate modules in the completion UI with their `PLDoc'
  description when available.

  Along with `M-x sweeprolog-find-module', `sweep' provides the command
  `M-x sweeprolog-find-predicate' jumping to the definition a loaded or
  auto-loadable Prolog predicate.


Prolog file specification expansion
───────────────────────────────────

  `sweep' defines a handler for the Emacs function `expand-file-file'
  that recognizes Prolog file specifications, such as `library(lists)',
  and expands them to their corresponding absolute paths.  This means
  that one can use Prolog file specifications with Emacs’ standard
  `find-file' (`C-x C-f') to locate Prolog resources directly.

  For example, typing `C-x C-f library(pldoc/doc_man)' will open the
  source of the `pldoc_man' module from the Prolog library, and likewise
  `C-x C-f pack(.)' will open the Prolog packages directory.


Quick access to sweep commands
══════════════════════════════

  `sweep' defines a keymap called `sweeprolog-prefix-map' which provides
  keybinding for several useful `sweep' commands.  By default,
  `sweeprolog-prefix-map' itself is not bound to any key.  To bind it
  globally to a prefix key, e.g. `C-c p', use:

  ┌────
  │ (keymap-global-set "C-c p" sweeprolog-prefix-map)
  └────

  As an example, with the above binding the `sweep' top-level can be
  accessed from anywhere with `C-c p t', which invokes the command
  `sweeprolog-top-level'.


Examining Prolog messages
═════════════════════════

  Messages emitted by the embedded Prolog are redirected by `sweep' to a
  dedicated Emacs buffer.  By default, the `sweep' messages buffer is
  named `*sweep Messages*'.  To instruct `sweep' to use another buffer
  name instead, type `M-x customize-option RET
  sweeprolog-messages-buffer-name RET' and set the option to a suitable
  value.

  The `sweep' messages buffer uses the minor mode
  `compilation-minor-mode', which allows for jumping to source locations
  indicated in errors and warning directly from the corresponding
  message in the `sweep' messages buffer.  For more information about
  the features enabled by `compilation-minor-mode', see [Compilation
  Mode in the Emacs manual].

  `sweep' includes the command `sweeprolog-view-messages' for quickly
  switching to the `sweep' messages buffer.  This command is bound by
  default in `sweeprolog-prefix-map' to the `e' key (see Quick access to
  sweep commands).


[Compilation Mode in the Emacs manual] <info:emacs#Compilation Mode>


Setting Prolog flags
════════════════════

  The command `M-x sweeprolog-set-prolog-flag' can be used to
  interactively configure the embedded Prolog execution environment by
  changing the values of Prolog flags.  This command first prompts the
  user for a Prolog flag to set, with completion candidates annotated
  with their current values as Prolog flags, and then prompts for a
  string that will be read as a Prolog term and set as the value of the
  chosen flag.  For more information on Prolog flags in SWI-Prolog see
  [Environment Control in the SWI-Prolog manual].

  As an example, the Prolog flag `double_quotes' controls the
  interpretation of double quotes in Prolog code.  By default,
  `double_quotes' is set to `string', so e.g. `"foo"' is read as a
  SWI-Prolog string as we can easily validate in the `sweep' top-level:

  ┌────
  │ ?- A = "foo".
  │ A = "foo".
  └────

  We can change the interpretation of double quotes to denote lists of
  character codes, by setting the value the `double_quotes' flag to
  `codes' with `M-x sweeprolog-set-prolog-flag RET double_quotes RET
  codes RET'.  Evaluating `A = "foo"' again exhibits the different
  interpretation:

  ┌────
  │ ?- A = "foo".
  │ A = [102, 111, 111].
  └────


[Environment Control in the SWI-Prolog manual]
<https://www.swi-prolog.org/pldoc/man?section=flags>


Installing Prolog packages
══════════════════════════

  The command `M-x sweeprolog-pack-install' can be used to install or
  upgrade a SWI-Prolog `pack'. When selecting a `pack' to install, the
  completion candidates are annotated with description and the version
  of each package.


Contributing
════════════

  We highly appreciate all contributions, including bug reports,
  patches, improvement suggestions, and general feedback.

  For a list of known desired improvements in `sweep', see [Things to
  do].


[Things to do] See section Things to do

Setting up sweep for local development
──────────────────────────────────────

  Since the Prolog and C parts of `sweep' are intended to be distributed
  and installed along with SWI-Prolog (see [Installation]), the easiest
  way to set up `sweep' for development is to start with a SWI-Prolog
  development setup.  Clone the `swipl-devel' Git repository, and update
  the included `sweep' submodule from its master branch:

  ┌────
  │ $ git clone --recursive https://github.com/SWI-Prolog/swipl-devel.git
  │ $ cd swipl-devel/packages/sweep
  │ $ git checkout master
  │ $ git pull
  └────

  The directory `swipl-devel/packages/sweep' now contains the
  development version of `sweep', you can make changes to source files
  and they will apply when you (re)build SWI-Prolog.  See [Building
  SWI-Prolog using cmake] for instructions on how to build SWI-Prolog
  from source.

  Changes in the Elisp library `sweeprolog.el' do not require rebuilding
  SWI-Prolog, and can be applied and tested directly inside Emacs (see
  [Evaluating Elisp in the Emacs manual]).

  Most often rebuilding SWI-Prolog after changing `sweep.c' can be
  achieved with the following command executed in
  `swipl-devel/packages/sweep':

  ┌────
  │ $ ninja -C ../../build
  └────


[Installation] See section Installation

[Building SWI-Prolog using cmake]
<https://github.com/SWI-Prolog/swipl-devel/blob/master/CMAKE.md#building-from-source>

[Evaluating Elisp in the Emacs manual] <info:emacs#Lisp Eval>


Submitting patches and bug reports
──────────────────────────────────

  The best way to get in touch with the `sweep' maintainers is via [the
  sweep mailing list].

  The command `M-x sweeprolog-submit-bug-report' can be used to easily
  contact the `sweep' maintainers from within Emacs.  This command opens
  a new buffer with a message template ready to be sent to the `sweep'
  mailing list.


[the sweep mailing list] <https://lists.sr.ht/~eshel/dev>


Things to do
════════════

  While `sweep' is ready to be used for effective editing of Prolog
  code, there some further improvements that we want to pursue:


Improvements around editing Prolog
──────────────────────────────────

  Inherit user customizations from `prolog-mode'
        `sweep' should inherit user customizations from the standard
        `prolog.el' built into Emacs to accommodate users updating their
        configs to work with `sweep'.  Ideally, `sweeprolog-mode' should
        be derived from `prolog-mode' instead of the generic `prog-mode'
        to inherit user-set hooks and modifications, but careful
        consideration is required to make sure `sweeprolog-mode'
        overrides all conflicting `prolog-mode' features.

  Reflect buffer status in the mode line
        It may be useful to indicate in the mode line whether the
        current `sweeprolog-mode' buffer has been loaded into the Prolog
        runtime and/or if its cross-reference data is up to date.

  Provide right-click (`mouse-3') menus with `context-menu-mode'
        To accommodate users who prefer a mouse-based workflow,
        `sweeprolog-mode' should provide right-click context-aware menus
        by integrating with `context-menu-mode'.

  Provide descriptions for tokens by setting their `help-echo' propety
        We should annotate tokens in Prolog code with a short text in
        their `help-echo' property that says what kind of token this is,
        to expose the precise semantics of each token to the user.

  Add a command for exporting the current predicate
        `sweeprolog-mode' should provide a command for adding a
        predicate to the export list of the module defined in the
        current buffer, defaulting to the predicate at point.

  Add a command for updating the dependencies for the current module
        `sweeprolog-mode' should provide a command for adding and/or
        updating `use_module/2' and `autoload/2' directives as needed
        according to the predicates that the current buffer depends
        on. The directives should be inserted in the appropriate
        position, i.e. before the first predicate definition in the
        buffer.

  Add a command for inserting a new clause, similar to `C-M-m' in `prolog-mode'
        `sweeprolog-mode' should provide a command for inserting a new
        clause for the predicate at or above point.

  Add a command for interactively inserting a new predicate
        `sweeprolog-mode' should provide a command for interactively
        inserting a new predicate definition, ideally with optional
        `PlDoc' comments (see [Documenting predicates]).

  Add commands for narrowing and moving by predicate definitions
        `sweeprolog-mode' should include commands moving point to the
        next/previous predicate definition.  We already have commands
        for clause-based motion (`C-M-a', `C-M-e') but it would be
        useful to have predicate-based variants as well.  These commands
        could then be bound to `C-c C-n' for moving to the next
        predicate definition and `C-c C-p' for moving to the previous.

  Improve the information provided for predicate completion candidates
        predicate completion with `C-M-i' should annotate each
        completion candidate with the names and modes of its arguments,
        when available.  E.g. say `foo(+Bar, -Baz)' instead of `foo/2'.

  Improve the behavior of predicate completion in the middle of a functor
        When invoking predicate completion in the middle of a functor,
        e.g. `foo<|>bar(' (where `<|>' designates the location of the
        cursor), we should take into account the part that comes after
        the cursor and either restrict completion to candidates that
        match it as a suffix, or delete it after completion.

  Make predicate completion aware of module-qualification
        predicate completion should detect when the prefix it’s trying
        to complete starts with a module-qualification `foo:ba<|>' and
        restrict completion to matching candidates in the specified
        module.

  Respect `font-lock-maximum-decoration'
        We should take into account the value of
        `font-lock-maximum-decoration' while highlighting
        `sweeprolog-mode' buffers.  This variable conveys the user’s
        preferred degree of highlighting.  A possible approach would be
        changing `sweeprolog--colour-term-to-faces' such that each color
        fragment in returned list states its target decoration level
        (i.e. 1, 2 or 3).  `sweeprolog--colourise' would then compare
        this target to the value of

        ┌────
        │ (font-lock-value-in-major-mode font-lock-maximum-decoration)
        └────

        And decide whether or not to apply the fragment.


[Documenting predicates] See section Documenting predicates


Improvements around running Prolog
──────────────────────────────────

  Persist top-level history across sessions
        `sweep' should persist Prolog top-level histories across
        invocations of `sweeprolog-top-level', ideally also across
        different Emacs sessions.


General improvements
────────────────────

  Facilitate interactive debugging
        `sweep' should facilitate interactive debugging of SWI-Prolog
        code.  This is a big topic that we don’t currently address.
        Perhaps this should handled through some Debug Adapter Protocol
        integration similar to what was done in `dap-swi-prolog' (see
        [Debug Adapter Protocol for SWI-Prolog]).

  Provide predicate documentation in a `help-mode' buffer
        `sweep' should include a command `sweeprolog-describe-predicate'
        that works similarly to the built-in `describe-function' by
        opening a `help-mode' buffer and populating it with the full
        cross-referenced documentation of a given Prolog predicate.

  Integrate with `project.el' adding support for SWI-Prolog packs
        It would be nice if `sweep' would “teach” `project.el' to detect
        directories containing SWI-Prolog `pack.pl' package definitions
        as root project directories.

  Add command line arguments handling for Prolog flags
        `sweep' should make it easy to specify Prolog initialization
        arguments (see [Prolog initialization and cleanup]) already in
        the Emacs command line invocation.  One way to achieve that
        would be to extend `command-line-functions' with a custom
        command line arguments handler.

  Extend the provided Elisp-Prolog interface
        Currently, the Elisp interface that `sweep' provides for
        querying Prolog only allows calling directly to predicates of
        arity 2 (see [Querying Prolog]), ideally we should provide a
        (backward-compatible) way for executing arbitrary Prolog
        queries.


[Debug Adapter Protocol for SWI-Prolog]
<https://github.com/eshelyaron/debug_adapter/blob/main/README.md>

[Prolog initialization and cleanup] See section Prolog initialization
and cleanup

[Querying Prolog] See section Querying Prolog


Indices
═══════

Function index
──────────────


Variable index
──────────────


Keystroke index
───────────────


Concept index
─────────────
