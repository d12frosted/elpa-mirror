		 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		  SWEEP: SWI-PROLOG EMBEDDED IN EMACS

			      Eshel Yaron
			   me@eshelyaron.com
		 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual describes the Emacs package Sweep (or `sweeprolog.el'),
which provides an embedded SWI-Prolog runtime inside of Emacs.

Table of Contents
─────────────────

Overview
.. Architecture
Installation
Getting Started
Discovering Sweep
Initialization
Querying Prolog
.. Elisp to Prolog
.. Prolog to Elisp
.. Example Query
.. Call Back to Elisp
Editing Prolog Code
.. Indentation
..... Indentation Rules
.. Highlighting
..... Available Styles
..... Highlight Variables
..... Quasi-Quotation
.. Hover for Help
.. Code Layout
..... Aligning Spaces
..... Electric Layout mode
.. Term-based Editing
.. Holes
..... Terms with Holes
..... Jumping to Holes
..... Filling Holes
..... Highlighting Holes
.. Cross References
.. Predicate Boundaries
.. File Specifications
.. Loading Buffers
.. Setting Breakpoints
..... Breakpoint Menu
.. Creating New Modules
.. Documenting Code
.. Usage Comments
.. Showing Prolog Docs
.. Showing Errors
.. Exporting Predicates
.. Code Completion
.. Insert Term DWIM
.. Writing Tests
.. Code Dependencies
.. Term Search
.. Context Menu
.. Renaming Variables
.. Numbered Variables
.. Macro Expansion
Prolog Help
The Prolog Top-Level
.. Multiple Top-Levels
.. Top-level Menu
.. Top-Level Signaling
.. Top-level History
.. Top-level Completion
.. Follow Messages
.. Send to Top-level
Async Queries
Finding Prolog Code
.. File Spec Expansion
.. Native Predicates
Quick Access Keymap
Prolog Messages
Prolog Flags
Prolog Packages
Contributing
.. Developing Sweep
.. Submitting Patches
Things To Do
.. Editing Improvements
.. Running Improvements
.. General Improvements
Indices
.. Function Index
.. Variable Index
.. Keystroke Index
.. Concept Index


Overview
════════

  Sweep is an embedding of SWI-Prolog in Emacs.  It provides an
  interface for executing Prolog queries and consuming their results
  from Emacs Lisp (see Querying Prolog).  Sweep further builds on top of
  this interface and on top of the standard Emacs facilities to provide
  advanced features for developing SWI-Prolog programs in Emacs.


High-level Architecture
───────────────────────

  Sweep uses the C interfaces of both SWI-Prolog and Emacs Lisp to
  create a dynamically loaded Emacs module that contains the SWI-Prolog
  runtime.  As such, Sweep has parts written in C, in Prolog and in
  Emacs Lisp.

  The different parts of Sweep are structured as follows:

  • `sweep.c' defines a dynamic Emacs module which is referred to from
    Elisp as `sweep-module'. This module is linked against the
    SWI-Prolog runtime library (`libswipl') and exposes a subset of the
    SWI-Prolog C interface to Emacs in the form of Elisp functions (see
    Querying Prolog). Notably, `sweep-module' is responsible for
    translating Elisp objects to Prolog terms and vice versa.

  • `sweeprolog.el' defines an Elisp library (named simply
    `sweeprolog'), which builds on top of `sweep-module' to provide
    user-facing commands and functionality. It is also responsible for
    loading `sweep-module'.

  • `sweep.pl' defines a Prolog module (named, unsurprisingly, Sweep)
    which is by default arranged by `sweeprolog.el' to be loaded when
    the embedded Prolog runtime is initialized. It contains predicates
    that `sweeprolog.el' invoke through `sweep-module' to facilitate its
    different commands (see Finding Prolog code).


Installation
════════════

  The dynamic Emacs module `sweep-module' is included with SWI-Prolog
  versions 8.5.18 and later.  For instructions on how to build and
  install SWI-Prolog, see <https://www.swi-prolog.org/build/>.

  The `sweeprolog' Elisp package is available on NonGNU ELPA, to install
  `sweeprolog' simply type `M-x package-install RET sweeprolog RET'.

  An alternative to installing from ELPA is to get the Elisp library
  from the Sweep Git repository:

  1. Clone the Sweep repository:
     ┌────
     │ git clone https://git.sr.ht/~eshel/sweep
     └────

     Or:

     ┌────
     │ git clone https://github.com/SWI-Prolog/packages-sweep sweep
     └────

  2. Add Sweep to Emacs’s `load-path':
     ┌────
     │ (add-to-list 'load-path "/path/to/sweep")
     └────


Getting Started
═══════════════

  After installing the `sweeprolog' Elisp library, load it into Emacs:

  ┌────
  │ (require 'sweeprolog)
  └────

  Sweep tries to find SWI-Prolog by looking for the `swipl' executable
  in the directories listed in the Emacs variable `exec-path'.  When
  Emacs is started from a shell, `exec-path' is initialized from the
  shell’s `PATH' environment variable which normally includes the
  location of `swipl' in common SWI-Prolog installations.  If the
  `swipl' executable cannot be found via `exec-path', you can tell Sweep
  where to find it by setting the variable `sweeprolog-swipl-path' to
  point to it:

  ┌────
  │ (setq sweeprolog-swipl-path "/path/to/swipl")
  └────

  All set!  `sweeprolog' automatically loads `sweep-module' and
  initializes the embedded SWI-Prolog runtime.  For a description of the
  different features of Sweep, see the following sections of this
  manual.

  _Important note for Linux users_: prior to version 29, Emacs would
  load dynamic modules in a way that is not fully compatible with the
  way the SWI-Prolog native library, `libswipl', loads its own native
  extensions.  This may lead to Sweep failing after loading
  `sweep-module'.  To work around this issue, users running Emacs 28 or
  earlier on Linux can start Emacs with `libswipl' loaded upfront via
  `LD_PRELOAD', for example:

  ┌────
  │ LD_PRELOAD=/usr/local/lib/libswipl.so emacs
  └────


Discovering Sweep
═════════════════

  Sweep comes with many useful commands and features for working with
  SWI-Prolog.  This section lists suggested ways for you to get to know
  the provided commands and make the most out of Sweep.

  The main documentation resource for Sweep is this very manual.  It
  describes almost every command and customization option that Sweep
  provides.  Since Sweep includes many features, describing all them
  makes this manual longer then you’d probably want to read upfront.
  Instead it’s recommended that you skim this manual to get an idea of
  the available features, and then return to it as a reference during
  your work with Sweep.

  To open this manual from within Emacs, type `C-h i' (`info') to open
  the Info reader, followed by `d m sweep RET' to go to the top Info
  directory and select the Sweep manual.  Sweep also provides a
  convenient command for opening the manual:

  Command: sweeprolog-info-manual
        Display the Sweep manual in Info.

  To open the relevant part of the manual for a specific command that
  you want to learn more about, type `C-h F' followed by the name of
  that command.  For example, typing `C-h F sweeprolog-info-manual RET'
  brings up this manual section in Info.  If the command you’re
  interested in is bound to a key sequence, you can go to its Info node
  by typing `C-h K' followed by the key sequence that invokes it.

  Other than the text in this manual, Sweep commands and user options
  have Elisp documentation strings that describe them individually.  The
  various Emacs Help commands (`C-h k', `C-h f', `C-h v', etc.) display
  these documentation strings in a dedicated Help buffer (see [Help] in
  the Emacs manual).  From the Help buffer, you can jump to the relevant
  Info node typing `i' (`help-goto-info') to read more about related
  commands and customization options.

  You can also view an HTML version of this manual online at
  <https://eshelyaron.com/sweep.html>.


[Help] <info:emacs#Help>


Prolog Initialization and Cleanup
═════════════════════════════════

  The embedded SWI-Prolog runtime must be initialized before it can
  start executing queries.  Initializing Prolog is usually taken care of
  by Sweep when you first use a command that requires running some
  Prolog code.  This section elaborates about Prolog initialization and
  its customization options in Sweep:

  Function: sweeprolog-initialize prog &rest args
        Initialize the embedded Prolog runtime.  PROG should be the path
        to the `swipl' executable, and ARGS should be a list of strings
        denoting command line arguments for `swipl'.  They are used to
        initialize Prolog as if it was started from the command line as
        `PROG ARGS'.
  Function: sweeprolog-handle-command-line-args
        Enable support for the Sweep specific `--swipl-args' Emacs
        command line flag.  This flag can be used to specify additional
        Prolog initialization arguments for Sweep to use when
        initializing Prolog on-demand, directly from Emacs’s command
        line invocation.
  User Option: sweeprolog-init-args
        List of strings used as initialization arguments for Prolog.
        Sweep uses these as the ARGS argument of `sweeprolog-initialize'
        when it initializes Prolog on-demand.
  Command: sweeprolog-restart
        Restart the embedded Prolog runtime.

  In Sweep, Prolog initialization is done via the C-implemented
  `sweeprolog-initialize' Elisp function defined in `sweep-module'.
  `sweeprolog-initialize' takes one or more arguments, which must all be
  strings, and initializes the embedded Prolog as if it were invoked
  externally in a command line with the given strings as command line
  arguments, where the first argument to `sweeprolog-initialize'
  corresponds to `argv[0]'.

  Sweep loads and initializes Prolog on-demand at the first invocation
  of a command that requires the embedded Prolog.  The arguments used to
  initialize Prolog are then determined by the value of the user-option
  `sweeprolog-init-args' which the user is free to extend with e.g.:

  ┌────
  │ (add-to-list 'sweeprolog-init-args "--stack-limit=512m")
  └────

  The default value of `sweeprolog-init-args' is set to load the Prolog
  helper library `sweep.pl' and to create a boolean Prolog flag Sweep,
  set to `true', which indicates to SWI-Prolog that it is running under
  Sweep.

  It is also possible to specify initialization arguments to SWI-Prolog
  by passing them as command line arguments to Emacs, which can be
  convenient when using Emacs and Sweep as an alternative for the common
  shell-based interaction with SWI-Prolog.  This is achieved by adding
  the flag `--swipl-args' followed by any number of arguments intended
  for SWI-Prolog, with a single semicolon (“;”) argument marking the end
  of the SWI-Prolog arguments, after which further arguments are
  processed by Emacs as usual (see [Emacs Invocation] for more
  information about Emacs’s command line options), for example:

  ┌────
  │ emacs --some-emacs-option --swipl-args -l foobar.pl \; --more-emacs-options
  └────

  In order for Sweep to be able to handle Emacs’s command line
  arguments, the function `sweeprolog-handle-command-line-args' must be
  called before Emacs processes the `--swipl-args' argument.  This can
  be ensured by calling it from the command line as well:

  ┌────
  │ emacs -f sweeprolog-handle-command-line-args --swipl-args -l foobar.pl \;
  └────

  The embedded Prolog runtime can be reset using the command
  `sweeprolog-restart'.  This command cleans up the the Prolog state and
  resources, and starts it anew.  When called with a prefix argument
  (`C-u M-x sweeprolog-restart'), this command prompts the user for
  additional initialization arguments to pass to the embedded Prolog
  runtime on startup.


[Emacs Invocation] <info:emacs#Emacs Invocation>


Querying Prolog
═══════════════

  This section describes a set of Elisp functions that let you invoke
  Prolog queries and interact with the embedded Prolog runtime:

  Function: sweeprolog-open-query context module functor input reverse 
        Query the Prolog predicate MODULE:FUNCTOR/2 in the context of
        the module CONTEXT.  Converts INPUT to a Prolog term and uses it
        as the first argument, unless REVERSE is non-nil, in which can
        it uses INPUT as the second argument.  The other argument is
        called the output argument of the query, it is expected to be
        unified with some output that the query wants to return to
        Elisp.  The output argument can be retrieved with
        `sweeprolog-next-solution'.  Always returns `t' if called with
        valid arguments, otherwise returns `nil'.
  Function: sweeprolog-next-solution
        Return the next solution of the last Prolog query.  Returns a
        cons cell `(DET . OUTPUT)' if the query succeed, where `DET' is
        the symbol `!' if no choice points remain and `t' otherwise, and
        `OUTPUT' is the output argument of the query converted to an
        Elisp sexp.  If there are no more solutions, return `nil'
        instead.  If a Prolog exception was thrown, return a cons cell
        `(exception . EXP)' where `EXP' is the exception term converted
        to Elisp.
  Function: sweeprolog-cut-query
        Cut the last Prolog query.  This releases any resources reserved
        for it and makes further calls to `sweeprolog-next-solution'
        invalid until you open a new query.
  Function: sweeprolog-close-query
        Close the last Prolog query.  Similar to `sweeprolog-cut-query'
        expect that any unifications created by the last query are
        dropped.

  Sweep provides the Elisp function `sweeprolog-open-query' for invoking
  Prolog predicates.  The invoked predicate must be of arity two and
  will be called in mode `p(+In, -Out)' i.e. the predicate should treat
  the first argument as input and expect a variable for the second
  argument which should be unified with some output.  This restriction
  is placed in order to facilitate a natural calling convention between
  Elisp, a functional language, and Prolog, a logical one.

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

  Sweep only executes one Prolog query at a given time, thus queries
  opened with `sweeprolog-open-query' need to be closed before other
  queries can be opened.  When no more solutions are available for the
  current query (i.e. after `sweeprolog-next-solution' returned `nil'),
  or when otherwise further solutions are not of interest, the query
  must be closed with either `sweeprolog-cut-query' or
  `sweeprolog-close-query'. Both of these functions close the current
  query, but `sweeprolog-close-query' also destroys any Prolog bindings
  created by the query.


Conversion of Elisp objects to Prolog terms
───────────────────────────────────────────

  Sweep converts Elisp objects into Prolog terms to allow the Elisp
  programmers to specify arguments for Prolog predicates invocations
  (see `sweeprolog-open-query').  Seeing as some Elisp objects, like
  Elisp compiled functions, wouldn’t be as useful for a passing to
  Prolog as others, Sweep only converts Elisp objects of certain types
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

  Sweep converts Prolog terms into Elisp object to allow efficient
  processing of Prolog query results in Elisp (see
  `sweeprolog-next-solution').

  • Prolog strings are converted to equivalent Elisp strings.
  • Prolog integers are converted to equivalent Elisp integers.
  • Prolog floats are converted to equivalent Elisp floats.
  • A Prolog atom `foo' is converted to a cons cell `(atom . "foo")'.
  • The Prolog empty list `[]' is converted to the Elisp `nil' object.
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

  As an example of using the Sweep interface for executing Prolog
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

  Sweep includes a dedicated major mode for reading and editing Prolog
  code, called `sweeprolog-mode':

  Command: sweeprolog-mode
        Enable Sweep major mode for reading and editing SWI-Prolog code
        in the current buffer.
  Variable: sweeprolog-mode-hook
        Hook run after entering `sweeprolog-mode'.  For more information
        about major mode hooks in Emacs see [Hooks] in the Emacs manual.

  To activate this mode in a buffer, type `M-x sweeprolog-mode'.  To
  instruct Emacs to always open Prolog files in `sweeprolog-mode',
  modify the Emacs variable `auto-mode-alist' accordingly:

  ┌────
  │ (add-to-list 'auto-mode-alist '("\\.plt?\\'"  . sweeprolog-mode))
  └────

  For more information about how Emacs chooses a major mode to use when
  you visit a file, see [Choosing Modes] in the Emacs manual.

  To list all of the commands available in a `sweeprolog-mode' buffer,
  type `C-h m' (`describe-mode').  When Menu Bar mode is enabled, you
  can run many of these commands via the Sweep menu.  For more
  information about Menu Bar mode, see [Menu Bars] in the Emacs manual.


[Hooks] <info:emacs#Hooks>

[Choosing Modes] <info:emacs#Choosing Modes>

[Menu Bars] <info:emacs#Menu Bars>

Indentation
───────────

  In `sweeprolog-mode' buffers, the appropriate indentation for each
  line is determined by a bespoke /indentation engine/.  The indentation
  engine analyses the syntactic context of a given line and determines
  the appropriate indentation to apply based on a set of rules.

  Key: TAB (indent-for-tab-command)
        Indent the current line.  If the region is active, indent all
        the lines within it.  Calls the mode-dependent function
        specified by the variable `indent-line-function' to do the work.
  Function: sweeprolog-indent-line
        Indent the current line according to SWI-Prolog conventions.
        This function is used as an `indent-line-function' in
        `sweeprolog-mode' buffers.
  Command: sweeprolog-infer-indent-style
        Infer indentation style for the current buffer from its
        contents.

  The entry point of the indentation engine is the function
  `sweeprolog-indent-line' which takes no arguments and indents that
  line at point.  `sweeprolog-mode' supports the standard Emacs
  interface for indentation by arranging for `sweeprolog-indent-line' to
  be called whenever a line should be indented, notably after pressing
  `TAB'.  For a full description of the available commands and options
  that pertain to indentation, see [Indentation] in the Emacs manual.

  The user option `sweeprolog-indent-offset' specifies how many columns
  lines are indented with.  The standard Emacs variable
  `indent-tabs-mode' determines if indentation can use tabs or only
  spaces.  You may sometimes want to adjust these options to match the
  indentation style used in an existing Prolog codebase, the command
  `sweeprolog-infer-indent-style' can do that for you by analyzing the
  contents of the current buffer and updating the buffer-local values of
  `sweeprolog-indent-offset' and `indent-tabs-mode' accordingly.
  Consider adding `sweeprolog-infer-indent-style' to
  `sweeprolog-mode-hook' to have it set up the indentation style
  automatically in all `sweeprolog-mode' buffers:

  ┌────
  │ (add-hook 'sweeprolog-mode-hook #'sweeprolog-infer-indent-style)
  └────


[Indentation] <info:emacs#Indentation>

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

  4. If the current line is the first non-comment line of a clause body,
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

  5. If the current line starts with the right hand side operand of an
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

  6. If the last non-comment line ends with a functor and its opening
     parenthesis, indent to the starting column of the functor plus
     `sweeprolog-indent-offset'.

     This rule yields the following layout:

     ┌────
     │ some_functor(
     │     arg1, ...
     └────

  7. If the last non-comment line ends with a prefix operator, indent to
     starting column of the operator plus `sweeprolog-indent-offset'.

     This rule yields the following layout:

     ┌────
     │ :- multifile
     │        predicate/3.
     └────


Semantic Highlighting
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

  Key: C-c C-c (sweeprolog-analyze-buffer)
        Analyze the current buffer and update cross-references.
  User Option: sweeprolog-analyze-buffer-on-idle
        If non-nil, analyze `sweeprolog-mode' buffers on idle.  Defaults
        to `t'.
  User Option: sweeprolog-analyze-buffer-max-size
        Maximum number characters in a `sweeprolog-mode' buffer to
        analyze on idle.  Larger buffers are not analyzed on idle.
        Defaults to 100,000 characters.
  User Option: sweeprolog-analyze-buffer-min-interval
        Minimum number of idle seconds to wait before analyzing a
        `sweeprolog-mode' buffer.  Defaults to 1.5.

  At any point in a `sweeprolog-mode' buffer, the command `C-c C-c' (or
  `M-x sweeprolog-analyze-buffer') can be used to update the cross
  reference cache and highlight the buffer accordingly.  When Flymake
  integration is enabled, this command also updates the diagnostics for
  the current buffer (see [Examining Diagnostics]).  This may be useful
  e.g. after defining a new predicate.

  If the user option `sweeprolog-analyze-buffer-on-idle' is set to
  non-nil (as it is by default), `sweeprolog-mode' also updates semantic
  highlighting in the buffer whenever Emacs is idle for a reasonable
  amount of time, unless the buffer is larger than the value of the
  `sweeprolog-analyze-buffer-max-size' user option ( 100,000 by
  default).  The minimum idle time to wait before automatically updating
  semantic highlighting can be set via the user option
  `sweeprolog-analyze-buffer-min-interval'.

  Sweep defines three highlighting /styles/, each containing more than
  60 different faces (named sets of properties that determine the
  appearance of a specific text in Emacs buffers, see also [Faces in the
  Emacs manual]) to signify the specific semantics of each token in a
  Prolog code buffer.

  To view and customize all of the faces defined and used in Sweep, type
  `M-x customize-group RET sweeprolog-faces RET'.


[Font Lock in the Emacs manual] <info:emacs#Font Lock>

[Examining Diagnostics] See section Examining Diagnostics

[Faces in the Emacs manual] <info:emacs#Faces>

Available Styles
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Sweep comes with three highlighting styles:

  1. The default style includes faces that mostly inherit from standard
     Emacs faces commonly used in programming modes.
  2. The `light' style mimics the colors used in the SWI-Prolog built-in
     editor.
  3. The `dark' style mimics the colors used in the SWI-Prolog built-in
     editor in dark mode.

  User Option: sweeprolog-faces-style
        Style of faces to use for semantic highlighting in
        `sweeprolog-mode' buffers.  Defaults to `nil'.

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
  cursor is moved into a variable.  To achieve this, Sweep uses the
  Emacs minor mode `cursor-sensor-mode' which allows for running hooks
  when the cursor enters or leaves certain text regions (see also
  [Special Properties in the Elisp manual]).

  Command: sweeprolog-highlight-variable
        Highlight occurrences of a Prolog variable in the clause at
        point.  With a prefix argument, clear variable highlighting in
        the clause at point instead.

  User Option: sweeprolog-enable-cursor-sensor
        If non-nil, use `cursor-sensor-mode' to highlight Prolog
        variables sharing with the variable at point in
        `sweeprolog-mode' buffers.  Defaults to `t'.

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

  User Option: sweeprolog-qq-mode-alist
        Alist of (TYPE . MODE) pairs, where TYPE is a Prolog
        quasi-quotation type, and MODE is a symbol specifying a major
        mode to use for highlighting the quasi-quoted text.

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


Hover for Help
──────────────

  In the [Semantic Highlighting] section we talked about how Sweep
  performs semantic analysis to determine the meaning of different terms
  in different contexts and highlight them accordingly.  Beyond
  highlighting, Sweep can also tell you explicitly what different tokens
  in Prolog code mean by annotating them with a textual description
  that’s displayed when you hover over them with the mouse.

  User Option: sweeprolog-enable-help-echo
        If non-nil, annotate Prolog tokens with help text via the
        `help-echo' text property. Defaults to `t'.
  Key: C-h . (display-local-help)
        Display the `help-echo' text of the token at point in the echo
        area.

  If the user option `sweeprolog-enable-help-echo' is non-nil, as it is
  by default, `sweeprolog-mode' annotates tokens with a short
  description of their meaning in that specific context.  This is done
  by adding the `help-echo' text property to different parts of the
  buffer based on semantic analysis.  The `help-echo' text is
  automatically displayed at the mouse tooltip when you hover over
  different tokens in the buffer.

  Alternatively, you can display the `help-echo' text for the token at
  point in the echo area by typing `C-h .' (`C-h' followed by dot).

  The `help-echo' description of file specification in import directives
  is especially useful as it tells you which predicates that the current
  buffer uses actually come from the imported file.  For example, if we
  have a Prolog file with the following contents:

  ┌────
  │ :- use_module(library(lists)).
  │ 
  │ foo(Foo, Bar) :- flatten(Bar, Baz), member(Foo, Baz).
  └────

  Then hovering over `library(lists)' shows:

        Dependency on /usr/local/lib/swipl/library/lists.pl,
        resolves calls to flatten/2, member/2


[Semantic Highlighting] See section Semantic Highlighting


Maintaining Code Layout
───────────────────────

  Some Prolog constructs, such as if-then-else constructs, have a
  conventional /layout/, where each goal starts at the fourth column
  after the /start/ of the opening parenthesis or operator, as follows:

  ┌────
  │ (   if
  │ ->  then
  │ ;   else
  │ *-> elif
  │ ;   true
  │ )
  └────

  To simplify maintaining the desired layout without manually counting
  spaces, Sweep provides a command `sweeprolog-align-spaces' that
  updates the whitespace around point such that the next token is
  aligned to a (multiple of) four columns from the start of the previous
  token, as well as a dedicated minor mode
  `sweeprolog-electric-layout-mode' that adjusts whitespace around point
  automatically as you type ([Electric Layout mode]).


[Electric Layout mode] See section Electric Layout mode

Inserting the Right Number of Spaces
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Command: sweeprolog-align-spaces
        Insert or remove spaces around point to such that the next
        Prolog token starts at a column distanced from the beginning of
        the previous token by a multiple of four columns.
  User Option: sweeprolog-enable-cycle-spacing
        If non-nil, add `sweeprolog-align-spaces' as the first element
        of `cycle-spacing-actions' in `sweeprolog-mode' buffers.
        Defaults to `t'.

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

  In Emacs 29, the command `M-x cycle-spacing' is extensible via a list
  of callback functions stored in the variable `cycle-spacing-actions'.
  Sweep leverages this facility and adds `sweeprolog-align-spaces' as
  the first action of `cycle-spacing'.  To inhibit `sweeprolog-mode'
  from doing so, set the user option `sweeprolog-enable-cycle-spacing'
  to nil.

  Moreover, in Emacs 29 `cycle-spacing' is bound by default to `M-SPC',
  thus aligning if-then-else and similar constructs only requires typing
  `M-SPC' after the first token.

  In Emacs prior to version 29, users are advised to bind
  `sweeprolog-align-spaces' to `M-SPC' directly by adding the following
  lines to Emacs’s initialization file (see [The Emacs Initialization
  File]).

  ┌────
  │ (eval-after-load 'sweeprolog
  │   '(define-key sweeprolog-mode-map (kbd "M-SPC") #'sweeprolog-align-spaces))
  └────


[The Emacs Initialization File] <info:emacs#Init File>


Electric Layout mode
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The minor mode `sweeprolog-electric-layout-mode' adjusts whitespace
  around point automatically as you type:

  Command: sweeprolog-electric-layout-mode
        Toggle automatic whitespace adjustment according to SWI-Prolog
        conventions.

  It works by examining the context of point whenever a character is
  inserted in the current buffer, and applying the following layout
  rules:

  `PlDoc' Comments
        Insert two consecutive spaces after the `%!' or `%%' starting a
        `PlDoc' predicate documentation structured comment.
  If-Then-Else
        Insert spaces after a part of an if-then-else constructs such
        that point is positioned four columns after its beginning.  The
        specific tokens that trigger this rule are the opening
        parenthesis `(' and the operators `;', `->' and `*->', and only
        if they are inserted in a callable context, where an
        if-then-else construct would normally appear.

  To enable this mode in a `sweeprolog-mode' buffer, type `M-x
  sweeprolog-electric-layout-mode'.  This step can be automated by
  adding `sweeprolog-electric-layout-mode' to `sweeprolog-mode-hook':

  ┌────
  │ (add-hook 'sweeprolog-mode-hook #'sweeprolog-electric-layout-mode)
  └────


Term-based editing and motion commands
──────────────────────────────────────

  Emacs includes many useful features for operating on syntactic units
  in source code buffer, such as marking, transposing and moving over
  expressions.  By default, these features are geared towards working
  with Lisp expressions, or “sexps”.  `sweeprolog-mode' extends the
  Emacs’s notion of syntactic expressions to accommodate for Prolog
  terms, which allows the standard sexp-based commands to operate on
  them seamlessly.

  The [Expressions] section in the Emacs manual covers the most
  important commands that operate on sexps, and by extension on Prolog
  terms.  Another useful command for Prolog programmers is `M-x
  kill-backward-up-list', bound by default to `C-M-^' in
  `sweeprolog-mode' buffers.

  Key: C-M-^ (kill-backward-up-list)
        Kill the Prolog term containing the current term, leaving the
        current term itself.

  This command replaces the parent term containing the term at point
  with the term itself.  To illustrate the utility of this command,
  consider the following clause:

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


[Expressions] <info:emacs#Expressions>


Holes
─────

  /Holes/ are Prolog variables that some Sweep commands use as
  placeholder for other terms.

  When writing Prolog code in the usual way of typing in one character
  at a time, the buffer text is often found in a syntactically incorrect
  state while you edit it.  This happens for example right after you
  insert an infix operator, before typing its expected right-hand side
  argument.  Sweep provides an alternative method for inserting Prolog
  terms in a way that maintains the syntactic correctness of the buffer
  text while allowing the user to incrementally refine it by using
  placeholder terms, called simply “holes”.  Holes indicate the location
  of missing terms that the user can later fill in, essentially they
  represent source-level unknown terms and their presence satisfies the
  Prolog parser.  Holes are written in the buffer as regular Prolog
  variables, but they are annotated with a special text property that
  allows Sweep to recognize them as holes needed to be filled.

  See [Inserting Terms with Holes] for a command that uses holes to let
  you write syntactically correct Prolog terms incrementally.  Several
  other Sweep commands insert holes in place of unknown terms, including
  `C-M-i' (see [Code Completion]), `C-M-m' (see [Context-Based Term
  Insertion]) and `M-x sweeprolog-plunit-testset-skeleton' (see [Writing
  Tests]).


[Inserting Terms with Holes] See section Inserting Terms with Holes

[Code Completion] See section Code Completion

[Context-Based Term Insertion] See section Context-Based Term Insertion

[Writing Tests] See section Writing Tests

Inserting Terms with Holes
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Use the command `C-c RET' to add a term to the buffer at point while
  keeping it syntactically correct.  You don’t need to give the entire
  term at once, only its functor and arity.  Sweep automatically inserts
  holes for the arguments (if any), which you can incrementally fill one
  after the other.

  Key: C-c RET (sweeprolog-insert-term-with-holes)
        Insert a Prolog term with a given functor and arity at point,
        using holes for arguments.

  The main command for inserting terms with holes is `M-x
  sweeprolog-insert-term-with-holes'.  This command, bound by default to
  `C-c C-m' (or `C-c RET') in `sweeprolog-mode' buffers, prompts for a
  functor and an arity and inserts a corresponding term with holes in
  place of the term’s arguments.  It leaves point right after the first
  hole, sets the mark to its start and activates the region such that
  the hole is marked.  Call `sweeprolog-insert-term-with-holes' again to
  replace the active region, which now covers the first hole, with
  another term, that may again contain further holes.  That way you can
  incrementally write a Prolog term, including whole clauses, by working
  down the syntactic structure of the term and maintaining its
  correctness all the while.  Without a prefix argument,
  `sweeprolog-insert-term-with-holes' prompts for the functor and the
  arity to use.  A non-negative prefix argument, such as `C-2 C-c C-m'
  or `C-u C-c C-m', is taken to be the inserted term’s arity and in this
  case `sweeprolog-insert-term-with-holes' only prompts for the functor
  to insert.  A negative prefix argument, `C-- C-c C-m', inserts only a
  single hole without prompting for a functor.  To further help with
  keeping the buffer syntactically correct, this command adds a comma
  (`,') before or after the inserted term when needed according to the
  surrounding tokens.  If you call it at the end of a term that doesn’t
  have a closing fullstop, it adds the fullstop after the inserted term.


Jumping to Holes
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Use these commands to move between holes in the current Prolog buffer:

  Key: C-c TAB (sweeprolog-forward-hole)
        Move point to the next hole in the buffer and select it as the
        region.  With numeric prefix argument /n/, move forward over /n/
        - 1 holes and select the next one.
  Key: C-c S-TAB (sweeprolog-backward-hole)
        Move point to the previous hole in the buffer and select it as
        the region.  With numeric prefix argument /n/, move backward
        over /n/ - 1 holes and select the next one.
  Key: C-0 C-c TAB (sweeprolog-count-holes)
        Display the number of holes that are present in the buffer.
  Command: sweeprolog-forward-hole-on-tab-mode
        Toggle moving to the next hole in the buffer with `TAB' if the
        current line is already properly indented.

  To jump to the next hole in a `sweeprolog-mode' buffer, use the
  command `M-x sweeprolog-forward-hole', bound by default to `C-c TAB'
  (or `C-c C-i').  This command sets up the region to cover the next
  hole after point leaving the cursor at right after the hole.  To jump
  to the previous hole use `C-c S-TAB' (`sweeprolog-backward-hole'), or
  call `sweeprolog-forward-hole' with a negative prefix argument (`C--
  C-c TAB').

  You can also call `sweeprolog-forward-hole' and
  `sweeprolog-backward-hole' with a numeric prefix argument to jump over
  the specified number of holes.  For example, typing `C-3 C-c TAB'
  skips the next two holes in the buffer and selects the third as the
  region.  As a special case, if you call these commands with a zero
  prefix argument (`C-0 C-c TAB'), they invoke the command
  `sweeprolog-count-holes' instead of jumping.  This command counts how
  many holes are left in the current buffer and reports its finding via
  a message in the echo area.

  When the minor mode `sweeprolog-forward-hole-on-tab-mode' is enabled,
  the `TAB' key is bound to a command moves to the next hole when called
  in a properly indented line (otherwise it indents the line).  This
  makes moving between holes in the buffer easier since `TAB' can be
  used instead of `C-c TAB' in most cases.  To enable this mode in a
  Prolog buffer, type `M-x sweeprolog-forward-hole-on-tab-mode-map'.
  This step can be automated by adding
  `sweeprolog-forward-hole-on-tab-mode' to `sweeprolog-mode-hook':

  ┌────
  │ (add-hook 'sweeprolog-mode-hook #'sweeprolog-forward-hole-on-tab-mode)
  └────


Filling Holes
╌╌╌╌╌╌╌╌╌╌╌╌╌

  Filling a hole means replacing it in the buffer with a Prolog term.
  The simplest way to fill a hole is how you would replace any other
  piece of text in Emacs–select it as the region, kill it (for example,
  with `C-w') and insert another Prolog term in its place.  For more
  information about the region, see [Mark] in the Emacs manual.

  Yanking a hole with `C-y' (`yank') after you kill it removes the
  special hole property and inserts it as a plain variable.  This is can
  be useful if you want to keep the variable name that Sweep chose for
  the hole–simply press `C-w C-y' with the hole marked.

  As an alternative to manually killing the region with `C-w', if you
  enable Delete Selection mode (`M-x delete-selection-mode'), the hole
  is automatically removed as soon as you start typing while its marked.
  For more information about Delete Selection mode, see [Using Region]
  in the Emacs manual.

  Most Sweep commands that insert holes also move to the first hole they
  insert and select it as the region for you to fill it.  Similarly,
  jumping to the next hole in the buffer with `C-c TAB' also selects it.
  The command `C-c RET', described in [Inserting Terms with Holes], is
  specifically intended for filling holes by deleting the selected hole
  and inserting a Prolog term at once.


[Mark] <info:emacs#Mark>

[Using Region] <info:emacs#Using Region>

[Inserting Terms with Holes] See section Inserting Terms with Holes


Highlighting Holes
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Sweep highlights holes in Prolog buffer by default so you can easily
  identify missing terms.

  User Option: sweeprolog-highlight-holes
        If non-nil, highlight holes in `sweeprolog-mode' buffers with a
        dedicated face.  By default, this is set to `t'.

  When the user option `sweeprolog-highlight-holes' is set to non-nil,
  holes in Prolog buffers are highlighted with a dedicated face, making
  them easily distinguishable from regular Prolog variables.  Hole
  highlighting is enabled by default, to disable it customize
  `sweeprolog-highlight-holes' to nil.


Definitions and References
──────────────────────────

  `sweeprolog-mode' integrates with the Emacs `xref' API to facilitate
  quick access to predicate definitions and references in Prolog code
  buffers.  This enables the many commands that the `xref' interface
  provides, like `M-.' (`xref-find-definitions') for jumping to the
  definition of the predicate at point.  Refer to [Find Identifiers] in
  the Emacs manual for an overview of the available commands.

  `sweeprolog-mode' also integrates with Emacs’s `imenu', which provides
  a simple facility for looking up and jumping to definitions in the
  current buffer.  To jump to a definition in the current buffer, type
  `M-x imenu' (bound by default to `M-g i' in Emacs version 29).  For
  information about customizing `imenu', see [Imenu] in the Emacs
  manual.

  The command `M-x sweeprolog-xref-project-source-files' can be used to
  update Sweep’s cross reference data for all Prolog source files in the
  current project, as determined by the function `project-current' (see
  [Projects] in the Emacs manual).  When searching for references to
  Prolog predicates with `M-?' (`xref-find-references'), this command is
  invoked implicitly to ensure up to date references are found
  throughout the current project.


[Find Identifiers] <info:emacs#Find Identifiers>

[Imenu] <info:emacs#Imenu>

[Projects] <info:emacs#Projects>


Predicate Definition Boundaries
───────────────────────────────

  The following commands act on entire Prolog predicate definitions as a
  single unit:

  Key: M-n (sweeprolog-forward-predicate)
        Move forward from point to the next predicate definition in the
        current buffer.
  Key: M-p (sweeprolog-backward-predicate)
        Move backward from point to the previous predicate definition.
  Key: M-h (sweeprolog-mark-predicate)
        Select the current predicate as the active region, put point at
        the its beginning, and the mark at the end.

  In `sweeprolog-mode', the commands `M-n'
  (`sweeprolog-forward-predicate') and `M-p'
  (`sweeprolog-backward-predicate') are available for quickly jumping to
  the first line of the next or previous predicate definition in the
  current buffer.

  The command `M-h' (`sweeprolog-mark-predicate') marks the entire
  predicate definition at point, along with its `PlDoc' comments if
  there are any.  This can be followed, for example, with killing the
  marked region to relocate the defined predicate by typing `M-h C-w'.


Following File Specifications
─────────────────────────────

  In SWI-Prolog, one often refers to source file paths using /file
  specifications/, special Prolog terms that act as path aliases, such
  as `library(lists)' which refers to a file `lists.pl' in any of the
  Prolog library directories.

  Key: C-c C-o (sweeprolog-find-file-at-point)
        Resolve file specification at point and visit the specified
        file.
  Function: sweeprolog-file-at-point &optional point
        Return the file name specified by the Prolog file specification
        at POINT.

  You can follow file specifications that occur in `sweeprolog-mode'
  buffers with `C-c C-o' (or `M-x sweeprolog-find-file-at-point')
  whenever point is over a valid file specification.  For example,
  consider a Prolog file buffer with the common directive
  `use_module/1':

  ┌────
  │ :- use_module(library(lists)).
  └────

  With point in any position inside `library(lists)', typing `C-c C-o'
  will open the `lists.pl' file in the Prolog library.

  Sweep also extends Emacs’s `file-name-at-point-functions' hook with
  the function `sweeprolog-file-at-point' that returns the resolved
  Prolog file specification at point, if any.  Emacs uses this hook to
  populate the “future history” of minibuffer prompts that read file
  names, such as the one you get when you type `C-x C-f' (`find-file').
  In particular this means that if point is in a Prolog file
  specification, you can type `M-n' after `C-x C-f' to populate the
  minibuffer with the corresponding file name.  You can then go ahead
  and visit the file by typing `RET', or you can edit the minibuffer
  contents and visit a nearby file instead.

  For more information about file specifications in SWI-Prolog, see
  [absolute_file_name/3] in the SWI-Prolog manual.


[absolute_file_name/3]
<https://www.swi-prolog.org/pldoc/doc_for?object=absolute_file_name/3>


Loading Buffers
───────────────

  You can load a buffer of SWI-Prolog code with the following command:

  Key: C-c C-l (sweeprolog-load-buffer)
        Load the current buffer into the embedded SWI-Prolog runtime.

  Use the command `M-x sweeprolog-load-buffer' to load the contents of a
  `sweeprolog-mode' buffer into the embedded SWI-Prolog runtime.  After
  a buffer is loaded, the predicates it defines can be queried from
  Elisp (see Querying Prolog) and from the Sweep top-level (see The
  Prolog Top-Level).  In `sweeprolog-mode' buffers,
  `sweeprolog-load-buffer' is bound to `C-c C-l'.  By default this
  command loads the current buffer if its major mode is
  `sweeprolog-mode', and prompts for an appropriate buffer otherwise.
  To choose a different buffer to load while visiting a
  `sweeprolog-mode' buffer, invoke `sweeprolog-load-buffer' with a
  prefix argument (`C-u C-c C-l').

  The mode line displays the work “Loaded” next to the “Sweep” major
  mode indicator if the current buffer has is loaded and it hasn’t been
  modified since.  See [Mode Line] in the Emacs manual for more
  information about the mode line.

  More relevant information about loading code in SWI-Prolog can be
  found in [Loading Prolog source files] in the SWI-Prolog manual.


[Mode Line] <info:emacs#Mode Line>

[Loading Prolog source files]
<https://www.swi-prolog.org/pldoc/man?section=consulting>


Setting Breakpoints
───────────────────

  You can set /breakpoints/ in `sweeprolog-mode' buffers to have
  SWI-Prolog break before specific goals in the code (see [Breakpoints]
  in the SWI-Prolog manual).

  Key: C-c C-b (sweeprolog-set-breakpoint)
        Set a breakpoint.
  User Option: sweeprolog-highlight-breakpoints
        If non-nil, highlight breakpoints in `sweeprolog-mode' buffers.
        Defaults to `t'.

  The command `sweeprolog-set-breakpoint', bound to `C-c C-b', sets a
  breakpoint at the position of the cursor.  If you call it with a
  positive prefix argument (e.g. `C-u C-c C-b'), it creates a
  conditional breakpoint with a condition goal that you insert in the
  minibuffer.  If you call it with a non-positive prefix argument
  (e.g. `C-0 C-c C-b'), it deletes the breakpoint at point instead.

  When Context Menu mode is enabled, you can also create and delete
  breakpoints in `sweeprolog-mode' buffers through right-click context
  menus (see [Context Menu]).

  By default, Sweep highlights terms with active breakpoints in
  `sweeprolog-mode' buffers.  To inhibit breakpoint highlighting,
  customize the user option `sweeprolog-highlight-breakpoints' to `nil'.


[Breakpoints]
<https://www.swi-prolog.org/pldoc/man?section=trace-breakpoints>

[Context Menu] See section Context Menu

Breakpoint Menu
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Sweep provides a /breakpoint menu/ that lets you manage breakpoints
  across your codebase.

  Command: sweeprolog-list-breakpoints
        Display a list of active breakpoints.

  To open the breakpoint menu, type `M-x sweeprolog-list-breakpoints'.
  This command opens the breakpoint menu in the `*Sweep Breakpoints*'
  buffer.  The major mode of this buffer is Sweep Breakpoint Menu, which
  is a special mode that includes useful commands for managing Prolog
  breakpoints:

  Key: RET (sweeprolog-breakpoint-menu-find)
        Go to the position of the breakpoint corresponding to the
        breakpoint menu entry at point.
  Key: o (sweeprolog-breakpoint-menu-find-other-window)
        Show the position of the breakpoint corresponding to the
        breakpoint menu entry at point, in another window.
  Key: c (sweeprolog-breakpoint-menu-set-condition)
        Set the condition goal for the breakpoint corresponding to the
        breakpoint menu entry at point.


Creating New Modules
────────────────────

  Sweep integrates with the Emacs `auto-insert' facility to simplify
  creation of new SWI-Prolog modules.  `auto-insert' allows for
  populating newly created files with templates defined by the relevant
  major mode.

  User Option: sweeprolog-module-header-comment-skeleton
        Additional content to put in the topmost comment in Prolog
        module headers.

  Sweep associates a Prolog module skeleton with `sweeprolog-mode', the
  skeleton begins with a “file header” multi-line comment which includes
  the name and email address of the user based on the values of
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
  │ /** <module>
  │ 
  │ */
  │ 
  └────

  The multi-line comment included above the `module/2' directive can be
  extended by customizing the user option
  `sweeprolog-module-header-comment-skeleton', which see.  This can be
  useful for including e.g. copyright text in the file header.

  To open a new Prolog file, use the standard `C-x C-f' (`find-file')
  command and select a location for the new file.  In the new
  `sweeprolog-mode' buffer, type `M-x auto-insert' to insert the Prolog
  module skeleton.

  To automatically insert the module skeleton when opening new files in
  `sweeprolog-mode', enable the minor mode `auto-insert-mode'.  For
  detailed information about `auto-insert' and its customization
  options, see [Autoinserting in the Autotyping manual].


[File comments in the SWI-Prolog manual]
<https://www.swi-prolog.org/pldoc/man?section=sectioncomments>

[Autoinserting in the Autotyping manual] <info:autotype#Autoinserting>


Documenting Predicates
──────────────────────

  SWI-Prolog predicates can be documented with specially structured
  comments placed above the predicate definition, which are processed by
  the `PlDoc' source documentation system.  Emacs comes with many useful
  commands specifically intended for working with comments in
  programming languages, which apply also to writing `PlDoc' comments
  for Prolog predicates.  For an overview of the relevant standard Emacs
  commands, see [Comment Commands in the Emacs manual].

  Key: C-c C-d (sweeprolog-document-predicate-at-point)
        Insert `PlDoc' documentation comment for the predicate at or
        above point.
  User Option: sweeprolog-read-predicate-documentation-function
        Function to use for determining the initial contents of
        documentation comments inserted with
        `sweeprolog-document-predicate-at-point'.
  Function: sweeprolog-read-predicate-documentation-default-function functor arity
        Prompt and read from the minibuffer the arguments modes,
        determinism specification and initial summary for the
        documentation of the predicate FUNCTOR/ARITY.
  Function: sweeprolog-read-predicate-documentation-with-holes functor arity
        Use holes for the initial documentation of the predicate
        FUNCTOR/ARITY.

  Sweep also includes a dedicated command called
  `sweeprolog-document-predicate-at-point' for interactively creating
  `PlDoc' comments for predicates in `sweeprolog-mode' buffers.  This
  command, bound by default to `C-c C-d', finds the beginning of the
  predicate definition under or right above the current cursor location,
  and inserts a formatted `PlDoc' comment.  This command fills in
  initial argument modes, determinism specification, and optionally a
  summary line for the documented predicate.  There are different ways
  in which `sweeprolog-document-predicate-at-point' can obtain the
  needed initial documentation information, depending on the value of
  the user option `sweeprolog-read-predicate-documentation-function'
  which specifies a function to retrieve this information.  The default
  function prompts you to insert the parameters one by one via the
  minibuffer.  Alternatively, you can use holes (see [Holes]) for the
  predicate’s argument modes and determinism specifiers by setting this
  option to `sweeprolog-read-predicate-documentation-with-holes', as
  follows:

  ┌────
  │ (setq sweeprolog-read-predicate-documentation-function
  │       #'sweeprolog-read-predicate-documentation-with-holes)
  └────

  `sweeprolog-document-predicate-at-point' leaves the cursor at the end
  of the newly inserted documentation comment for the user to extend or
  edit it if needed.  To add another comment line, use `M-j'
  (`default-indent-new-line') which starts a new line with the comment
  prefix filled in.  Emacs also has other powerful built-in features for
  working with comments in code buffers that you can leverage to edit
  `PlDoc' comments.  For full details, see [Manipulating Comments].
  Furthermore you can make use of the rich support Emacs provides for
  editing natural language text when working on `PlDoc' comments.  For
  example, to nicely format a paragraph of text, use `M-q'
  (`fill-paragraph').  Many useful commands for editing text are
  documented in [Commands for Human Languages], which see.

  For more information about `PlDoc' and source documentation in
  SWI-Prolog, see [the PlDoc manual].


[Comment Commands in the Emacs manual] <info:emacs#Comment Commands>

[Holes] See section Holes

[Manipulating Comments] <info:emacs#Comments>

[Commands for Human Languages] <info:emacs#Text>

[the PlDoc manual]
<https://www.swi-prolog.org/pldoc/doc_for?object=section(%27packages/pldoc.html%27)>


Example Usage Comments
──────────────────────

  Beyond documenting your code with `PlDoc' comments as described in
  [Documenting Predicates], you might want to have comments in your
  source code that shows example usage of some predicate.  Creating such
  comments usually involves posting queries in a Prolog top-level,
  copying the queries and their results into the relevant source code
  buffer, and formatting them as comments.  Sweep provides the following
  command to streamline this process:

  Key: C-c C-% (sweeprolog-make-example-usage-comment)
        Start a new top-level for recording example usage.  When you
        finish interacting with the top-level its contents are formatted
        as a comment in the buffer and position where you invoked this
        command.

  The command `sweeprolog-make-example-usage-comment', bound to `C-c
  C-%' in `sweeprolog-mode' buffers, creates and switches to a new
  top-level buffer for recording example usage that you want to
  demonstrate.  The /example usage top-level/ is a regular top-level
  buffer (see [The Prolog Top-Level]), except that it’s tied to the
  specific position in the source buffer where you invoke this command.
  You can post queries in the example usage top-level and edit it
  freely, then type `C-c C-q' in to quit the top-level buffer and format
  its contents as a comment in the source buffer.

  You can have multiple example usage top-levels for different parts of
  your code at the same time.  To display the source position where you
  created a certain usage example top-level buffer by, type `C-c C-b' in
  that buffer.


[Documenting Predicates] See section Documenting Predicates

[The Prolog Top-Level] See section The Prolog Top-Level


Displaying Predicate Documentation
──────────────────────────────────

  Sweep integrates with the Emacs minor mode ElDoc, which automatically
  displays documentation for the predicate at point.  Whenever the
  cursor enters a predicate definition or invocation, the signature and
  summary of that predicate are displayed in the echo area at the bottom
  of the frame.

  User Option: sweeprolog-enable-eldoc
        If non-nil, enable ElDoc support in `sweeprolog-mode' buffers.
        Defaults to `t'.

  To disable the ElDoc integration in `sweeprolog-mode' buffers,
  customize the user option `sweeprolog-enable-eldoc' to `nil'.

  For more information about ElDoc and its customization options, see
  [Programming Language Doc] in the Emacs manual.


[Programming Language Doc] <info:emacs#Programming Language Doc>


Examining Diagnostics
─────────────────────

  `sweeprolog-mode' can diagnose problems in Prolog code and report them
  to the user by integrating with Flymake, a powerful interface for
  on-the-fly diagnostics built into Emacs.

  User Option: sweeprolog-enable-flymake
        If non-nil, enable Flymake support in `sweeprolog-mode' buffers.
        Defaults to `t'.
  Key: C-c C-` (sweeprolog-show-diagnostics)
        List diagnostics for the current buffer or project in a
        dedicated buffer.

  Flymake integration is enabled by default, to disable it customize the
  user option `sweeprolog-enable-flymake' to nil.

  When this integration is enabled, several Flymake commands are
  available for listing and jumping between found errors.  For a full
  description of these commands, see [Finding diagnostics] in the
  Flymake manual.  Additionally, `sweeprolog-mode' configures the
  standard command `M-x next-error' to operate on Flymake diagnostics.
  This allows for moving to the next (or previous) error location with
  the common `M-g n' (or `M-g p') keybinding.  For more information
  about these commands, see [Compilation Mode] in the Emacs manual.

  The command `sweeprolog-show-diagnostics' shows a list of Flymake
  diagnostics for the current buffer.  It is bound by default to `C-c
  C-`' in `sweeprolog-mode' buffers with Flymake integration enabled.
  When called with a prefix argument (`C-u C-c C-`'), shows a list of
  diagnostics for all buffers in the current project.


[Finding diagnostics] <info:flymake#Finding diagnostics>

[Compilation Mode] <info:emacs#Compilation Mode>


Exporting Predicates
────────────────────

  By default, a predicate defined in Prolog module is not visible to
  dependent modules unless they it is /exported/, by including it in the
  export list of the defining module (i.e. the second argument of the
  `module/2' directive).

  Key: C-c C-e (sweeprolog-export-predicate)
        Add the predicate predicate at point to the export list of the
        current Prolog module.

  Sweep provides a convenient command for exporting predicates defined
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


Code Completion
───────────────

  `sweeprolog-mode' empowers Emacs’s standard `completion-at-point'
  command, bound by default to `C-M-i' and `M-TAB', with context-aware
  completion for Prolog terms.  For background about completion-at-point
  in Emacs, see [Symbol Completion] in the Emacs manual.

  Sweep provides the following Prolog-specific completion facilities:

  Variable name completion
        If the text before point can be completed to one or more
        variable names that appear elsewhere in the current clause,
        `completion-at-point' suggests matching variable names as
        completion candidates.
  Predicate completion
        If point is at a callable position, `completion-at-point'
        suggests matching predicates as completion candidates.
        Predicate calls are inserted as complete term.  If the chosen
        predicate takes arguments, holes are inserted in their places
        (see [Holes]).
  Atom completion
        If point is at a non-callable position, `completion-at-point'
        suggests matching atoms as completion candidates.


[Symbol Completion] <info:emacs#Symbol Completion>

[Holes] See section Holes


Context-Based Term Insertion
────────────────────────────

  As a means of automating common Prolog code editing tasks, such as
  adding new clauses to an existing predicate, `sweeprolog-mode'
  provides the “do what I mean” command `M-x
  sweeprolog-insert-term-dwim', bound by default to `C-M-m' (or
  equivalently, `M-RET').  This command inserts a new term at or after
  point according to the context in which `sweeprolog-insert-term-dwim'
  is invoked.

  Key: M-RET (sweeprolog-insert-term-dwim)
        Insert an appropriate Prolog term in the current buffer, based
        on the context at point.
  Variable: sweeprolog-insert-term-functions
        List of functions for `sweeprolog-insert-term-dwim' to try for
        inserting a Prolog term based on the current context.

  To determine which term to insert and exactly where, this command
  calls the functions in the list held by the variable
  `sweeprolog-insert-term-functions' one after the other until one of
  the functions signal success by returning non-nil.

  By default, `sweeprolog-insert-term-dwim' tries the following
  insertion functions, in order:

  Function: sweeprolog-maybe-insert-next-clause
        If the last token before point is a fullstop ending a predicate
        clause, insert a new clause below it.
  Function: sweeprolog-maybe-define-predicate
        If point is over a call to an undefined predicate, insert a
        definition for that predicate.  By default, the new predicate
        definition is inserted right below the last clause of the
        current predicate definition.  The user option
        `sweeprolog-new-predicate-location-function' can be customized
        to control where this function inserts new predicate
        definitions.

  This command inserts holes as placeholders for the body term and the
  head’s arguments, if any.  See also [Holes].


[Holes] See section Holes


Writing Tests
─────────────

  SWI-Prolog includes the `PlUnit' unit testing framework[1], in which
  unit tests are written in special blocks of Prolog code enclosed
  within the directives `begin_tests/1' and `end_tests/1'.  To insert a
  new block of unit tests (also known as a /test-set/) in a Prolog
  buffer, use the command `M-x sweeprolog-plunit-testset-skeleton'.

  Command: sweeprolog-plunit-testset-skeleton
        Insert a `PlUnit' test-set skeleton at point.

  This command prompts for a name to give the new test-set and inserts a
  template such as the following:

  ┌────
  │ :- begin_tests(foo_regression_tests).
  │ 
  │ test() :- TestBody.
  │ 
  │ :- end_tests(foo_regression_tests).
  └────

  The cursor is left between the parentheses of the `test()' head term,
  and the `TestBody' variable is marked as a hole (see [Holes]).  To
  insert another unit test, place point after a complete test case and
  type `C-M-m' or `M-RET' to invoke `sweeprolog-insert-term-dwim' (see
  [Context-Based Term Insertion]).


[Holes] See section Holes

[Context-Based Term Insertion] See section Context-Based Term Insertion


Managing Dependencies
─────────────────────

  It is considered good practice for SWI-Prolog source files to
  explicitly list their dependencies on predicates defined in other
  files by using `autoload/2' and `use_module/2' directives.  To find
  all implicitly autoloaded predicates in the current `sweeprolog-mode'
  buffer and make the dependencies on them explicit, use the command
  `M-x sweeprolog-update-dependencies' bound to `C-c C-u'.

  Key: C-c C-u (sweeprolog-update-dependencies)
        Add explicit dependencies for implicitly autoloaded predicates
        in the current buffer.
  User Option: sweeprolog-dependency-directive
        Determines which Prolog directive to use in
        `sweeprolog-update-dependencies' when adding new directives.
        The value of this user option is one of the symbols
        `use-module', `autoload' or `infer'.  If it is `use-module',
        `sweeprolog-update-dependencies' adds `use_module/2' directives,
        `autoload' means to add `autoload/2' directives, and `infer'
        says to infer which directive to use based on the existing
        dependency directives in the buffer, if any.  Defaults to
        `infer'.
  User Option: sweeprolog-note-implicit-autoloads
        If non-nil, have Flymake complain about implicitly autoloaded
        predicates in `sweeprolog-mode' buffers.

  The command `sweeprolog-update-dependencies', bound to `C-c C-u',
  analyzes the current buffer and adds or updates `autoload/2' and
  `use_module/2' as needed.

  When this command adds a new directive, rather than updating an
  existing one, it can use either `autoload/2' or `use_module/2' to
  declare the new dependency based on the value of the user option
  `sweeprolog-dependency-directive'.  If you set this option is to
  `use-module', new dependencies use the `use_module/2' directive.  If
  it’s `autoload', new dependencies use `autoload/2'.  If it’s `infer',
  as it is by default, new dependencies use `autoload/2' unless the
  buffer already contains dependency directives and they are all
  `use_module/2' directives, in which case they also use `use_module/2'.

  By default, when Flymake integration is enabled (see [Examining
  diagnostics]), calls to implicitly autoloaded predicates are marked
  and reported as Flymake diagnostics.  To inhibit Flymake from
  diagnosing implicit autoloads, customize the user option
  `sweeprolog-note-implicit-autoloads' to nil.


[Examining diagnostics] See section Examining Diagnostics


Term Search
───────────

  You can search for Prolog terms matching a given search term with the
  command `M-x sweeprolog-term-search'.

  Key: C-c C-s (sweeprolog-term-search)
        Search for Prolog terms matching a given search term in the
        current buffer.
  Command: sweeprolog-term-search-repeat-forward
        Repeat the last Term Search, searching forward from point.
  Command: sweeprolog-term-search-repeat-backward
        Repeat the last Term Search, searching backward from point.

  This command, bound by default to `C-c C-s' in `sweeprolog-mode'
  buffers, prompts for a Prolog term to search for and finds terms in
  the current buffer that the search term subsumes.  It highlights all
  matching terms in the buffer and moves the cursor to the beginning of
  the next match after point.  For example, to find if-then-else
  constructs in the current buffer do `C-c C-s _ -> _ ; _ RET'.

  While prompting for a search term in the minibuffer, this command
  populates the “future history” with the Prolog terms at point, with
  the most nested term at point on top.  Typing `M-n' once in the
  minibuffer fills in the innermost term at point, typing `M-n' again
  cycles up the syntax tree at point filling the minibuffer with larger
  terms, up until the top-term at point.  For more information about
  minibuffer history commands, see [Minibuffer History] in the Emacs
  manual.

  If you invoke `sweeprolog-term-search' with a prefix argument, e.g. by
  typing `C-u C-c C-c', you can further refine the search with an
  arbitrary Prolog goal for filtering out search results that fail it.
  The given goal runs for each matching term, it may use variables from
  the search term to refer to subterms of the matching term.

  Typing `C-s' immediately after a successful search invokes the command
  `sweeprolog-term-search-repeat-forward' which moves forward to the
  next match.  Likewise, typing `C-r' after a successful term search
  invokes the command `sweeprolog-term-search-repeat-backward' which
  moves backward to the previous match.


[Minibuffer History] <info:emacs#Minibuffer History>


Context Menu
────────────

  In addition to the keybindings that Sweep provides for invoking its
  commands, it integrates with Emacs’s standard Context Menu minor mode
  to provide contextual menus that you interact with using the mouse.

  Command: context-menu-mode
        Toggle Context Menu mode.  When enabled, clicking the mouse
        button `down-mouse-3' (i.e. right-click) activates a menu whose
        contents depend on its surrounding context.
  Variable: sweeprolog-context-menu-functions
        List of functions that create Context Menu entries for Prolog
        tokens.  Each function should receive as its arguments the menu
        that is being created, the Prolog token’s description, its start
        position, its end position, and the position of the mouse click.
        It should alter the menu according to that context.

  To enable Context Menu, type `M-x context-menu-mode' or add a call to
  `(context-menu-mode)' in your Emacs initialization file to enable it
  in all future sessions.  You access the context menu by right-clicking
  anywhere in Emacs.  If you do it in a `sweeprolog-mode' buffer, you
  can invoke several Prolog-specific commands based on where you click
  in the buffer.

  If you right-click on a Prolog file specification or module name,
  Sweep suggests visiting it either in the current window or in another.
  If you right-click on a predicate, it lets you view its documentation
  in a dedicated buffer (see also [Prolog Help]).  For variables, it
  enables the `Rename Variable' menu entry that you can use to rename
  the variable you click on across its containing clause (see [Renaming
  Variables]).

  You can further extend and customize the context menu that
  `sweeprolog-mode' provides by adding functions to the variable
  `sweeprolog-context-menu-functions'.  Each function on this list
  receives the menu that is being created and a description of the
  clicked Prolog token, and it can extend the menu with entries before
  it’s displayed.


[Prolog Help] See section Prolog Help

[Renaming Variables] See section Renaming Variables


Renaming Variables
──────────────────

  You can rename a Prolog variable across the current top-term with the
  following command:

  Key: C-c C-r (sweeprolog-rename-variable)
        Rename a variable across the topmost Prolog term at point.
  User Option: sweeprolog-rename-variable-allow-existing
        If non-nil, allow selecting an existing variable name as the new
        name of a variable being renamed with
        `sweeprolog-rename-variable'.  If it is the symbol `confirm',
        allow but ask for confirmation first.  Defaults to `confirm'.

  The command `sweeprolog-rename-variable', bound to `C-c C-r', prompts
  for two variable names and replaces all occurrences of the first
  variable in the term at point with the second.  The prompt for the
  first (old) variable name provides completion based on the existing
  variable names in the current term, and it uses the variable at point
  as its default.

  The user option `sweeprolog-rename-variable-allow-existing' controls
  what happens if the second (new) variable name that you insert in the
  minibuffer already occurs in the current clause.  By default it is set
  to `confirm', which says to ask for confirmation before selecting an
  existing variable name as the new name.  This is because renaming a
  variable to another existing variable name potentially alters the
  semantics of the term by merging the two variables.  Other
  alternatives for this user option are `t' for allowing such merges
  without confirmation, and `nil' for refusing them altogether.

  If Context Menu mode is enabled, you can also rename variables by
  right-clicking on them with the mouse and selecting `Rename Variable'
  from the top of the context menu.  See [Context Menu] for more
  information about context menus in Sweep.


[Context Menu] See section Context Menu


Numbered Variables
──────────────────

  A widespread convention in Prolog is using a common prefix with a
  numeric suffix to name related variables, such as `Foo0', `Foo1',
  etc..  Sweep provides convenient commands for managing such /numbered
  variable/ sequences consistently:

  Key: C-c C-+ (sweeprolog-increment-numbered-variables)
        Prompt for a numbered variable and increment it and all numbered
        variables with the same base name and a greater number in the
        current clause.
  Key: C-c C– (sweeprolog-decrement-numbered-variables)
        Prompt for a numbered variable and decrement it and all numbered
        variables with the same base name and a greater number in the
        current clause.

  Numbering variables is often used to convey the order in which they
  are bound.  For example:

  ┌────
  │ %!  process(+State0, -State) is det.
  │ 
  │ process(State0, State) :-
  │     foo(State0, State1),
  │     bar(State2, State1),
  │     baz(State2, State).
  └────

  Here `State0' and `State' are respectively the input and output
  arguments of `process/2', and `State1' and `State2' represent
  intermediary stages between them.

  The command `C-c C-+' (`sweeprolog-increment-numbered-variables')
  prompts you for a numbered variable in the current clause, and
  increments the number of that variable along with all other numbered
  variables with the same base name and a greater number.  You can use
  it to “make room” for another intermediary variable between two
  sequentially numbered variables.  If you call this command with point
  on a numeric variable, it suggests that variable as the default
  choice.  If you call this command with a prefix argument, it
  increments by the numeric value of the prefix argument, otherwise it
  increments by one.

  For instance, typing `C-c C-+ State1 RET' with point anywhere in the
  definition of `process/2' from the above example results in the
  following code:

  ┌────
  │ process(State0, State) :-
  │     foo(State0, State2),
  │     bar(State3, State2),
  │     baz(State3, State).
  └────

  Note how all occurrences of `State1' are replaced with `State2', while
  occurrences of `State2' are replaced with `State3'.  The overall
  semantics of the clause doesn’t change, but we can now replace the
  call to `foo/2' with two goals and reintroduce `State1' as an
  intermediary result between them while keeping our numbering
  consistent, e.g.:

  ┌────
  │ process(State0, State) :-
  │     one(State0, State1), two(State1, State2),
  │     bar(State3, State2),
  │     baz(State3, State).
  └────

  If Context Menu mode is enabled, you can also invoke
  `sweeprolog-increment-numbered-variables' by right-clicking on a
  numbered variables and selecting `Increment Variable Numbers' from the
  context menu.  See [Context Menu].

  The command `C-c C--' (`sweeprolog-decrement-numbered-variables') is
  similar to `C-c C-+' except it decrements all numbered variables
  starting with a given numbered variable rather than incrementing them.
  You can use this function after you delete a numbered variable,
  leaving you with a gap in the variable numbering sequence, to
  decrement the following numbered variables accordingly.

  After invoking either `C-c C--' or `C-c C-+', you can continue to
  decrement or increment the same set of numbered variables by repeating
  with `-' and `+'.


[Context Menu] See section Context Menu


Macro Expansion
───────────────

  Recent versions of SWI-Prolog include a pre-processing mechanism
  called /Prolog macros/, implemented in `library(macros)'.  It provides
  a convenient way for computing terms at compile time and using them in
  code.

  Macros are defined using special rules with `#define(Macro,
  Replacement)' head terms.  Then, when SWI-Prolog reads a term of the
  form `#(Macro)' during compilation, it invokes the macro replacement
  rule and uses the expanded term instead.

  Sweep can replace macro invocations with their expansions.  To expand
  a macro in your source code, use the following command:

  Command: sweeprolog-expand-macro-at-point
        Replace the Prolog macro invocation starting at point with its
        expansion.

  You can call this command with point on the `#' macro indicator to
  expand the macro inline.  To undo the expansion, use `C-/' (`undo').

  With Context Menu mode enabled, you can also expand macros by
  right-clicking on the `#' and selecting `Expand Macro' from the
  context menu.  See also [Context Menu].


[Context Menu] See section Context Menu


Prolog Help
═══════════

  Sweep provides a way to read SWI-Prolog documentation via the standard
  Emacs `help' user interface, akin to Emacs’s built-in
  `describe-function' (`C-h f') and `describe-variable' (`C-h v').  For
  more information about Emacs `help' and its special major mode,
  `help-mode', see [Help Mode in the Emacs manual].

  Command: sweeprolog-describe-module
        Prompt for a Prolog module and display its full documentation in
        a help buffer.
  Command: sweeprolog-describe-predicate
        Prompt for a Prolog predicate and display its full documentation
        in a help buffer.

  The command `M-x sweeprolog-describe-module' prompts for the name of a
  Prolog module and displays its documentation in the `*Help*' buffer.
  To jump to the source code from the documentation, press `s'
  (`help-view-source').

  Similarly, `M-x sweeprolog-describe-predicate' can be used to display
  the documentation of a Prolog predicate.  This commands prompts for a
  predicate with completion.  When the cursor is over a predicate
  definition or invocation in a `sweeprolog-mode', that predicate is set
  as the default selection and can be described by simply typing `RET'
  in response to the prompt.


[Help Mode in the Emacs manual] <info:emacs#Help Mode>


The Prolog Top-Level
════════════════════

  Sweep provides a classic Prolog top-level interface for interacting
  with the embedded Prolog runtime.  To start the top-level, use `M-x
  sweeprolog-top-level'.  This command opens a buffer called
  `*sweeprolog-top-level*' which hosts the live Prolog top-level.

  The top-level buffer uses a major mode named
  `sweeprolog-top-level-mode'. This mode derives from `comint-mode',
  which is the common mode used in Emacs REPL interfaces.  As a result,
  the top-level buffer inherits the features present in other
  `comint-mode' derivatives, most of which are described in [the Emacs
  manual].

  Each top-level buffer is connected to distinct Prolog thread running
  in the same process as Emacs and the main Prolog runtime.  In the
  current implementation, top-level buffers communicate with their
  corresponding threads via local TCP connections.  On the first
  invocation of `sweeprolog-top-level', Sweep creates a TCP server
  socket bound to a random port to accept incoming connections from
  top-level buffers.  The TCP server only accepts connections from the
  local machine, but note that _other users on the same host_ may be
  able to connect to the TCP server socket and _get a Prolog top-level_.
  This may pose a security problem when sharing a host with untrusted
  users, hence `sweeprolog-top-level' _should not be used on shared
  machines_.  This is the only Sweep feature that should be avoided in
  such cases.


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

  Sweep provides a convenient interface for listing the active Prolog
  top-levels and operating on them, called the Top-level Menu buffer.
  This buffer shows the list of active Sweep top-level buffers in a
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
  Sweep top-level that it should stop executing the current query and do
  something else instead, use the command
  `sweeprolog-top-level-signal'. This command prompts for an active
  Sweep top-level buffer followed by a Prolog goal, and interrupts the
  top-level causing it to run the specified goal.

  In `sweeprolog-top-level-mode' buffers, the command
  `sweeprolog-top-level-signal-current' is available for signaling the
  current top-level.  It is bound by default to `C-c C-c'.  Normally,
  this command signals the goal specified by the user option
  `sweeprolog-top-level-signal-default-goal', which is set by default to
  a predicate that interrupts the top-level thread returns control of
  the top-level to the user.  When `sweeprolog-top-level-signal-current'
  is called with a prefix argument (`C-u C-c C-c'), it prompts for the
  goal.

  It is also possible to signal top-levels from the Sweep Top-level Menu
  buffer with the command `sweeprolog-top-level-menu-signal' with point
  at the entry corresponding to the wanted top-level (see The Top-level
  Menu buffer).

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

  The Sweep top-level history only records inputs whose length is at
  least `sweeprolog-top-level-min-history-length'.  This user option is
  set to 3 by default, and should generally be set to at least 2 to keep
  the history from being clobbered with single-character inputs, which
  are common in the top-level interaction, e.g. `;' as used to invoke
  backtracking.


[Shell History in the Emacs manual] <info:emacs#Shell History>


Completion in the top-level
───────────────────────────

  The `sweeprolog-top-level-mode', enabled in the Sweep top-level
  buffer, integrates with the standard Emacs symbol completion mechanism
  to provide completion for predicate names.  To complete a partial
  predicate name in the top-level prompt, use `C-M-i' (or `M-TAB').  For
  more information see [Symbol Completion in the Emacs manual].


[Symbol Completion in the Emacs manual] <info:emacs#Symbol Completion>


Following Error Messages
────────────────────────

  Many standard SWI-Prolog facilities generate messages that refer to
  specific source code locations.  For example, loading a Prolog file
  that contains singleton variables into the top-level will produce
  warning messages pointing to the starting line of the clauses where
  the singleton variables occur.  If you enable
  `compilation-shell-minor-mode' in the top-level buffer, Emacs
  recognizes the Prolog messages that refer to source locations and
  provides convenient commands for visiting such source locations from
  the top-level buffer.  For more information about
  `compilation-shell-minor-mode', see [Compilation Mode] in the Emacs
  manual.

  To use `compilation-shell-minor-mode' automatically in all top-level
  buffers, you can arrange for it to be enabled as part of the
  `sweeprolog-top-level-mode' hook, as follows:

  ┌────
  │ (add-hook 'sweeprolog-top-level-mode-hook
  │ 	  #'compilation-shell-minor-mode)
  │ 
  └────


[Compilation Mode] <info:emacs#Compilation Mode>


Sending Goals to the Top-level
──────────────────────────────

  You can send a goal to execute in a Prolog top-level from any buffer
  with the command `M-x sweeprolog-top-level-send-goal'.  This command
  prompts for a Prolog goal in the minibuffer, executes it in a
  top-level buffer and displays that buffer if it’s not already visible.
  While inserting the goal in the minibuffer, you can use `TAB' (or
  `C-i') to get completion suggestions.

  In `sweeprolog-mode' buffers, you can invoke
  `sweeprolog-top-level-send-goal' by typing `C-c C-q'.  It also uses
  the goal at point (if any) as the “future history” for the goal
  prompt, which you can access with `M-n' in the minibuffer.


Executing Prolog Asynchronously
═══════════════════════════════

  Sweep provides a facility for executing Prolog goals in separate
  threads and capturing their output in Emacs buffers as it is produced.
  You can use this for running queries without blocking Emacs.

  Key: C-c C-& (sweeprolog-async-goal)
        Execute a Prolog goal asynchronously and display its output in a
        dedicated buffer.

  The command `M-x sweeprolog-async-goal', bound to `C-c C-&' in
  `sweeprolog-mode' buffers, prompts for a Prolog goal and executes it
  in a new Prolog thread, redirecting its output and error streams to an
  Emacs buffer that gets updated asynchronously.

  This is similar in nature to running asynchronous shell commands with
  the standard `M-&' (`async-shell-command') or `M-x compile', expect
  that `sweeprolog-async-goal' runs a Prolog goal instead of a shell
  command.  For more information about these commands see [Single Shell]
  and [Compilation] in the Emacs manual.

  The output buffer that `sweeprolog-async-goal' creates uses a
  dedicated mode called /Sweep Async Output mode/.  This mode is derived
  from the standard Compilation mode, it provides all of the usual
  commands documented in [Compilation Mode].  Notably, you can run the
  same query again by typing `g' (`sweeprolog-async-goal-restart') in
  the output buffer.  To interrupt the goal running in the current
  output buffer, press `C-c C-k' (`kill-compilation').

  _Compatibility note_: asynchronous queries use pipe processes that
  require Emacs 28 or later and SWI-Prolog 9.1.4 or later.


[Single Shell] <info:emacs#Single Shell>

[Compilation] <info:emacs#Compilation>

[Compilation Mode] <info:emacs#Compilation Mode>


Finding Prolog code
═══════════════════

  Sweep provides the command `M-x sweeprolog-find-module' for selecting
  and jumping to the source code of a loaded or auto-loadable Prolog
  module.  Sweep integrates with Emacs’s standard completion API to
  annotate candidate modules in the completion UI with their `PLDoc'
  description when available.

  Along with `M-x sweeprolog-find-module', Sweep provides the command
  `M-x sweeprolog-find-predicate' jumping to the definition a loaded or
  auto-loadable Prolog predicate.


Prolog file specification expansion
───────────────────────────────────

  Sweep defines a handler for the Emacs function `expand-file-name' that
  recognizes Prolog file specifications, such as `library(lists)', and
  expands them to their corresponding absolute paths.  This means that
  one can use Prolog file specifications with Emacs’s standard
  `find-file' (`C-x C-f') to locate Prolog resources directly.

  For example, typing `C-x C-f library(pldoc/doc_man)' will open the
  source of the `pldoc_man' module from the Prolog library, and likewise
  `C-x C-f pack(.)' will open the Prolog packages directory.


Built-in Native Predicates
──────────────────────────

  Some of the built-in predicates provided by SWI-Prolog, such as
  `is/2', are implemented in C and included as native functions in the
  SWI-Prolog runtime.  It is sometimes useful to examine the
  implementation of such native built-in predicates by reading its
  definition in the SWI-Prolog C sources.  Sweep knows about SWI-Prolog
  native built-ins, and can find and jump to their definitions in C when
  the user has the SWI-Prolog sources checked out locally.

  The way Sweep locates the SWI-Prolog sources depends on the user
  option `sweeprolog-swipl-sources'.  When customized to a string, it is
  taken to be the path to the root directory of the SWI-Prolog source
  code.  If instead `sweeprolog-swipl-sources' is set to `t' (the
  default), Sweep will try to locate a local checkout of the SWI-Prolog
  sources automatically among known project root directories provided by
  Emacs’s built-in `project-known-project-roots' from `project.el' (see
  [Projects in the Emacs manual] for more information about `project.el'
  projects).  Lastly, setting `sweeprolog-swipl-sources' to `nil'
  disables searching for definitions of native built-ins.

  With `sweeprolog-swipl-sources' set, the provided commands for finding
  predicate definitions operate seamlessly on native built-ins to
  display their C definitions in `c-mode' buffers (see [the Emacs CC
  Mode manual] for information about working with C code in Emacs).
  These commands include:
  • `M-x sweeprolog-find-predicate',
  • `M-.' (`xref-find-definitions') in `sweeprolog-mode' buffers (see
    [Definitions and References]), and
  • `s' (`help-view-source') in the `*Help*' buffer produced by `M-x
      sweeprolog-describe-predicate' (see [Prolog Help]).


[Projects in the Emacs manual] <info:emacs#Projects>

[the Emacs CC Mode manual] <info:ccmode#Top>

[Definitions and References] See section Definitions and References

[Prolog Help] See section Prolog Help


Quick access to sweep commands
══════════════════════════════

  Sweep defines a keymap called `sweeprolog-prefix-map' which provides
  keybinding for several useful Sweep commands.  By default,
  `sweeprolog-prefix-map' itself is not bound to any key.  To bind it
  globally to a prefix key, e.g. `C-c p', use:

  ┌────
  │ (keymap-global-set "C-c p" sweeprolog-prefix-map)
  └────

  As an example, with the above binding the Sweep top-level can be
  accessed from anywhere with `C-c p t', which invokes the command
  `sweeprolog-top-level'.

  The full list of keybindings in `sweeprolog-prefix-map' is given
  below:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Key    Command                                 Documentation                       
  ────────────────────────────────────────────────────────────────────────────────────
   `B'    `sweeprolog-list-breakpoints'           [Breakpoint Menu]                   
   `F'    `sweeprolog-set-prolog-flag'            [Setting Prolog Flags]              
   `P'    `sweeprolog-pack-install'               [Installing Prolog packages]        
   `R'    `sweeprolog-restart'                    [Prolog Initialization and Cleanup] 
   `T'    `sweeprolog-list-top-levels'            [The Top-level Menu Buffer]         
   `X'    `sweeprolog-xref-project-source-files'  [Definitions and References]        
   `e'    `sweeprolog-view-messages'              [Examining Prolog Messages]         
   `h p'  `sweeprolog-describe-predicate'         [Prolog Help]                       
   `h m'  `sweeprolog-describe-module'            [Prolog Help]                       
   `l'    `sweeprolog-load-buffer'                [Loading Buffers]                   
   `m'    `sweeprolog-find-module'                [Finding Prolog Code]               
   `p'    `sweeprolog-find-predicate'             [Finding Prolog Code]               
   `q'    `sweeprolog-top-level-send-goal'        [Sending Goals to the Top-level]    
   `t'    `sweeprolog-top-level'                  [The Prolog Top-level]              
   `&'    `sweeprolog-async-goal'                 [Executing Prolog Asynchronously]   
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


[Breakpoint Menu] See section Breakpoint Menu

[Setting Prolog Flags] See section Setting Prolog flags

[Installing Prolog packages] See section Installing Prolog packages

[Prolog Initialization and Cleanup] See section Prolog Initialization
and Cleanup

[The Top-level Menu Buffer] See section The Top-level Menu buffer

[Definitions and References] See section Definitions and References

[Examining Prolog Messages] See section Examining Prolog messages

[Prolog Help] See section Prolog Help

[Prolog Help] See section Prolog Help

[Loading Buffers] See section Loading Buffers

[Finding Prolog Code] See section Finding Prolog code

[Finding Prolog Code] See section Finding Prolog code

[Sending Goals to the Top-level] See section Sending Goals to the
Top-level

[The Prolog Top-level] See section The Prolog Top-Level

[Executing Prolog Asynchronously] See section Executing Prolog
Asynchronously


Examining Prolog messages
═════════════════════════

  Messages emitted by the embedded Prolog are redirected by Sweep to a
  dedicated Emacs buffer.  By default, the Sweep messages buffer is
  named `*sweep Messages*'.  To instruct Sweep to use another buffer
  name instead, type `M-x customize-option RET
  sweeprolog-messages-buffer-name RET' and set the option to a suitable
  value.

  The Sweep messages buffer uses the minor mode
  `compilation-minor-mode', which allows for jumping to source locations
  indicated in errors and warning directly from the corresponding
  message in the Sweep messages buffer.  For more information about the
  features enabled by `compilation-minor-mode', see [Compilation Mode in
  the Emacs manual].

  Sweep includes the command `sweeprolog-view-messages' for quickly
  switching to the Sweep messages buffer.  This command is bound by
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
  SWI-Prolog string as we can easily validate in the Sweep top-level:

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

  For a list of known desired improvements in Sweep, see [Things to do].


[Things to do] See section Things to do

Setting up sweep for local development
──────────────────────────────────────

  Since the Prolog and C parts of Sweep are intended to be distributed
  and installed along with SWI-Prolog (see [Installation]), the easiest
  way to set up Sweep for development is to start with a SWI-Prolog
  development setup.  Clone the `swipl-devel' Git repository, and update
  the included Sweep submodule from its master branch:

  ┌────
  │ $ git clone --recursive https://github.com/SWI-Prolog/swipl-devel.git
  │ $ cd swipl-devel/packages/sweep
  │ $ git checkout master
  │ $ git pull
  └────

  The directory `swipl-devel/packages/sweep' now contains the
  development version of Sweep, you can make changes to source files and
  they will apply when you (re)build SWI-Prolog.  See [Building
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

  The best way to get in touch with the Sweep maintainers is via [the
  sweep mailing list].

  The command `M-x sweeprolog-submit-bug-report' can be used to easily
  contact the Sweep maintainers from within Emacs.  This command opens a
  new buffer with a message template ready to be sent to the Sweep
  mailing list.


[the sweep mailing list] <https://lists.sr.ht/~eshel/dev>


Things to do
════════════

  While Sweep is ready to be used for effective editing of Prolog code,
  some improvements remain to be pursued:


Improvements around editing Prolog
──────────────────────────────────

  Inherit user customizations from `prolog-mode'
        Sweep should inherit user customizations from the standard
        `prolog.el' built into Emacs to accommodate users updating their
        configs to work with Sweep.  Ideally, `sweeprolog-mode' should
        be derived from `prolog-mode' instead of the generic `prog-mode'
        to inherit user-set hooks and modifications, but careful
        consideration is required to make sure `sweeprolog-mode'
        overrides all conflicting `prolog-mode' features.

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


Improvements around running Prolog
──────────────────────────────────

  Persist top-level history across sessions
        Sweep should persist Prolog top-level histories across
        invocations of `sweeprolog-top-level', ideally also across
        different Emacs sessions.


General improvements
────────────────────

  Facilitate interactive debugging
        Sweep should facilitate interactive debugging of SWI-Prolog
        code.  This is a big topic that we don’t currently address.
        Perhaps this should handled through some Debug Adapter Protocol
        integration similar to what was done in `dap-swi-prolog' (see
        [Debug Adapter Protocol for SWI-Prolog]).

  Integrate with `project.el' adding support for SWI-Prolog packs
        It would be nice if Sweep would “teach” `project.el' to detect
        directories containing SWI-Prolog `pack.pl' package definitions
        as root project directories.

  Extend the provided Elisp-Prolog interface
        Currently, the Elisp interface that Sweep provides for querying
        Prolog only allows calling directly to predicates of arity 2
        (see [Querying Prolog]), ideally we should provide a
        (backward-compatible) way for executing arbitrary Prolog
        queries.


[Debug Adapter Protocol for SWI-Prolog]
<https://github.com/eshelyaron/debug_adapter/blob/main/README.md>

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



Footnotes
─────────

[1] See [Prolog Unit Tests in the SWI-Prolog manual]
(<https://www.swi-prolog.org/pldoc/doc_for?object=section(%27packages/plunit.html%27)>).
