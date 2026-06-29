1 Fortran editing helpers for Emacs
═══════════════════════════════════

1.1 Overview
────────────

  You write (or work on) large, modern fortran code bases.  These make
  heavy use of function overloading and generic interfaces.  Your brain
  is too small to remember what all the specialisers are called.
  Therefore, your editor should help you.  This is an attempt to do this
  for Emacs.

  f90-interface-browser.el is a (simple-minded) parser of fortran that
  understands a little about generic interfaces and derived types.


1.2 External functions
──────────────────────

  `f90-parse-interfaces-in-dir'
        Parse all the fortran files in a directory
  `f90-parse-all-interfaces'
        Parse all the fortran files in a directory and recursively in
        its subdirectories
  `f90-browse-interface-specialisers'
        Pop up a buffer showing all the specialisers for a particular
        generic interface (prompted for with completion)
  `f90-find-tag-interface'
        On a procedure call, show a list of the interfaces that match
        the (possibly typed) argument list.  If no interface is found,
        this falls back to `find-tag'.
  `f90-list-in-scope-vars'
        List all variables in local scope.  This just goes to the top of
        the current procedure and collects named variables, so it
        doesn't work with module or global scope variables or local
        procedures.
  `f90-show-type-definition'
        Pop up a buffer showing a derived type definition.


1.3 Customisable variables
──────────────────────────

  `f90-file-extensions'
        A list of extensions that the parser will use to decide if a
        file is a fortran file.


1.4 Details and caveats
───────────────────────

  The parser assumes you write fortran in the style espoused in Metcalf,
  Reid and Cohen.  Particularly, variable declarations use a double
  colon to separate the type from the name list.

  Here's an example of a derived type definition:
  ┌────
  │ type foo
  │    real, allocatable, dimension(:) :: a
  │    integer, pointer :: b, c(:)
  │    type(bar) :: d
  │ end type foo
  └────

  Here's a subroutine declaration:
  ┌────
  │ subroutine foo(a, b)
  │    integer, intent(in) :: a
  │    real, intent(inout), dimension(:,:) :: b
  │    ...
  │ end subroutine foo
  └────

  Local procedures whose names conflict with global ones will likely
  confuse the parser.  For example:
  ┌────
  │ subroutine foo(a, b)
  │    ...
  │ end subroutine foo
  │ 
  │ subroutine bar(a, b)
  │    ...
  │    call subroutine foo
  │    ...
  │  contains
  │    subroutine foo
  │       ...
  │    end subroutine foo
  │ end subroutine bar
  └────

  Also not handled are overloaded operators, scalar precision modifiers,
  like `integer(kind=c_int)', for which the precision is just ignored,
  and many other of the hairier aspects of the fortran language.
