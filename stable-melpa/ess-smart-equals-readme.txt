
 Assignment in R is syntactically complicated by a few features:
 1. the historical role of '_' (underscore) as an assignment
 character in the S language; 2. the somewhat
 inconvenient-to-type, if conceptually pure, '<-' operator as the
 preferred assignment operator; 3. the ability to use either an
 '=', '<-', and a variety of other operators for assignment; and
 4. the multiple roles that '=' can play, including for setting
 named arguments in a function call.

 This package offers a flexible, context-sensitive assignment key
 for R and S that is, by default, tied to the '=' key. This key
 inserts or completes relevant, properly spaced operators
 (assignment, comparison, etc.) based on the syntactic context in
 the code. It allows very easy cycling through the possible
 operators in that context. The contexts, the operators, and
 their cycling order in each context are customizable.

 The package defines a minor mode `ess-smart-equals-mode',
 intended for S-language modes (e.g., ess-r-mode,
 inferior-ess-r-mode, and ess-r-transcript-mode), that when
 enabled in a buffer activates the '=' key to to handle
 context-sensitive completion and cycling of relevant operators.
 When the mode is active and an '=' is pressed:

  1. With a prefix argument or in specified contexts (which for
     most major modes means in strings or comments), just
     insert '='.

  2. If an operator relevant to the context lies before point
     (with optional whitespace), it is replaced, cyclically, by the
     next operator in the configured list for that context.

  3. Otherwise, if a prefix of an operator relevant to the
     context lies before point, that operator is completed.

  4. Otherwise, the highest priority relevant operator is inserted
     with surrounding whitespace (see `ess-smart-equals-no-spaces').

 Consecutive presses of '=' cycle through the relevant operators.
 After an '=', a backspace (or other configurable keys) removes
 the last operator and tab offers a choice of operators by completion.
 (Shift-backspace will delete one character only and restore the
 usual maning of backspace.) See `ess-smart-equals-cancel-keys'.

 By default, the minor mode activates the '=' key, but this can
 be customized by setting the option `ess-smart-equals-key' before
 this package is loaded.

 The function `ess-smart-equals-activate' arranges for the minor mode
 to be activated by mode hooks for any given list of major modes,
 defaulting to ESS major modes associated with R (ess-r-mode,
 inferior-ess-r-mode, ess-r-transcript-mode, ess-roxy-mode).

 Examples
 --------
 In the left column below, ^ marks the location at which an '='
 key is pressed, the remaining columns show the result of
 consecutive presses of '=' using the package's default settings.
 position of point.

    Before '='         Press '='      Another '='       Another '='
    ----------         ---------      -----------       -----------
    foo^               foo <- ^       foo <<- ^         foo = ^
    foo  ^             foo  <- ^      foo  <<- ^        foo  = ^
    foo<^              foo <- ^       foo <<- ^         foo = ^
    foo=^              foo = ^        foo -> ^          foo ->> ^
    foo(a^             foo(a = ^      foo( a == ^       foo( a != ^
    if( foo=^          if( foo == ^   if( foo != ^      if( foo <= ^
    if( foo<^          if( foo < ^    if( foo > ^       if( foo >= ^
    "foo ^             "foo =^        "foo ==^          "foo ===^
    #...foo ^          #...foo =^     #...foo ==^       #...foo ===^


  As a bonus, the value of the variable
  `ess-smart-equals-extra-ops' when this package is loaded,
  determines some other smart operators that may prove useful.
  Currently, only `brace', `paren', and `percent' are supported,
  causing `ess-smart-equals-open-brace',
  `ess-smart-equals-open-paren', and `ess-smart-equals-percent'
  to be bound to '{', '(', and '%', respectively. The first two
  of these configurably places a properly indented and spaced
  matching pair at point or around the region if active. The
  paren pair also includes a magic space with a convenient keymap
  for managing parens. See the readme. See the customizable
  variable `ess-smart-equals-brace-newlines' for configuring the
  newlines in braces. The third operator
  (`ess-smart-equals-percent') performs matching of %-operators.

  Finally, the primary user facing functions are named with a
  prefix `ess-smart-equals-' to avoid conflicts with other
  packages. Because this is long, the internal functions and
  objects use a shorter (but still distinctive) prefix `essmeq-'.


 Installation and Initialization
 -------------------------------
 The package can be loaded from MELPA using `package-install' or another
 Emacs package manager. Alternatively, you can clone or download the source
 directly from the github repository and put the file `ess-smart-equals.el'
 in your Emacs load path.

 A variety of activation options is described below, but tl;dr:
 the recommended way to activate the mode (e.g., in your init
 file) is either directly with

   (setq ess-smart-equals-extra-ops '(brace paren percent))
   (with-eval-after-load 'ess-r-mode
     (require 'ess-smart-equals)
     (ess-smart-equals-activate))

 or with use-package:

   (use-package ess-smart-equals
     :init   (setq ess-smart-equals-extra-ops '(brace paren percent))
     :after  (:any ess-r-mode inferior-ess-r-mode ess-r-transcript-mode)
     :config (ess-smart-equals-activate))

 A more detailed description follows, if you want to see variations.

 To activate, you need only do

     (with-eval-after-load 'ess-r-mode
       (require 'ess-smart-equals)
       (ess-smart-equals-activate))

 somewhere in your init file, which will add `ess-smart-equals-mode' to
 a prespecified (but customizable) list of mode hooks.

 For those who use the outstanding `use-package', you can do

     (use-package ess-smart-equals
       :after (:any ess-r-mode inferior-ess-r-mode ess-r-transcript-mode)
       :config (ess-smart-equals-activate))

 somewhere in your init file. An equivalent but less concise version
 of this is

     (use-package ess-smart-equals
       :after (:any ess-r-mode inferior-ess-r-mode ess-r-transcript-mode)
       :hook ((ess-r-mode . ess-smart-equals-mode)
              (inferior-ess-r-mode . ess-smart-equals-mode)
              (ess-r-transcript-mode . ess-smart-equals-mode)
              (ess-roxy-mode . ess-smart-equals-mode))

 To also activate the extra smart operators and bind them automatically,
 you can replace this with

     (use-package ess-smart-equals
       :init   (setq ess-smart-equals-extra-ops '(brace paren percent))
       :after  (:any ess-r-mode inferior-ess-r-mode ess-r-transcript-mode)
       :config (ess-smart-equals-activate))

 Details on customization are provided in the README file.

 Testing
 -------
 To run the tests, install cask and do `cask install' in the
 ess-smart-equals project directory. Then, at the command line,
 from the project root directory do

     cask exec ert-runner
     cask exec ecukes --reporter magnars

 and if manual testing is desired do

     cask emacs -Q -l test/manual-init.el --eval '(cd "~/")' &

 Additional test cases are welcome in pull requests.
