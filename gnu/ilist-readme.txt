                                ━━━━━━━
                                 ILIST
                                ━━━━━━━


                         <2021-09-12 Sun 11:00>





1 About
═══════

  This is a little library package that can "display a list in an
  ibuffer fashion".  The core functionality it provides is a function
  that can accept a list, and produce a string showing the contents of
  the list according to the specifications of columns and groups.


2 Entry point
═════════════

  The one main function this package provides is `ilist-string'.  It is
  called as follows.

  ┌────
  │ (ilist-string LIST COLUMNS GROUPS
  │     &optional DISCARD-EMPTY-P SORTER NO-TRAILING-SPACE)
  └────

  • LIST is the list that the user wants to display
  • COLUMNS and GROUPS are described in the following sections
  • DISCARD-EMPTY-P determines whether to display empty groups or not
  • SORTER is either nil, or a function with two arguments which returns
    non-nil if and only if the first argument should be sorted before
    the second argument.  This is used to sort the elements in the list,
    before grouping happens.  To sort groups, see the section on groups.
  • NO-TRAILING-SPACE is non-nil if there should be no trailing
    whitespaces in the resulting string.


2.1 Columns
───────────

  Like in Ibuffer, the user can specify columns to display.  Each column
  comprises the following specifications:

  • NAME: The name to display in the header.
  • FUN: A function that will be given the elements of the list (one at
    a time) that should return a string as the representation of that
    element in this column.
  • MIN, MAX: The minimal (resp. maximal) width this column takes.
  • ALIGN: Either :left, :right, or :center.  How the contents of the
    column are aligned.
  • ELIDE: If the content of an element takes more space than the MAX,
    whether to substitute the last few characters of that content by a
    fixed "eliding string".  If this ELIDE is not a string, then it
    means not to elide, but to truncate the contents.


2.2 Groups
──────────

2.2.1 Fixed groups
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Like in Ibuffer, we can group elements together in the display.  One
  difference with Ibuffer is that elements that are not in any group are
  ignored.  If one wants a "default" group, specify that explicitly.
  The specifications of GROUPS are as follows.

  • NAME: The name of the group.  This will be enclosed in square
    brackets and displayed on a separate line.
  • FUN: A function with one argument.  If the function returns non-nil,
    then that element is considered to pertain to the group.

  So a default group just uses a function that always returns t, and is
  put at the end of the list GROUPS.

  Empty groups might or might not be displayed, depending on the value
  of DISCARD-EMPTY-P.


2.2.2 Automatic groups
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  An automatic filter group is a function that can give labels to
  elements in a list.  These labels will be used to group elements
  automatically: the elements with the same label will be grouped
  together, automagically.  Besides, an automatic filter group is also
  responsible for sorting group labels, and for giving a default label,
  if no labels are specified for some element.

  To be precise, an automatic filter group is a function with the
  signature: `(ELEMENT &optional TYPE)'.  The optional argument `TYPE'
  says what the caller wants from the function:

  • nil: If it is omitted or nil, the function should just return the
    label for `ELEMENT'.
  • default: If it is the symbol `default', the function should return a
    default label.
  • sorter: If it is the symbol `sorter', the function should return a
    function with two arguments, `X' and `Y'.  This returned function
    should return a non-nil value if and only if group `X' should be
    placed earlier than group `Y'.

  So, for example, the call `(FUN t 'default)' should produce the
  default label, `(FUN t 'sorter)' should return the function used to
  sort groups, and `(FUN ELEMENT)' should return the label for
  `ELEMENT', where `FUN' is an automatic filter group.


2.2.3 Define automatic filter groups
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If one wants to define ones own automatic filter group, then the macro
  `ilist-define-automatic-group', or the shorter alias `ilist-dag',
  might come in handy.

  In case you wonder, this /dag/ has nothing to do with an /directed
  acyclic graph/; it is just an abbreviation to save some typing.  The
  coincidence of the names is a misfortune.

  This macro is called as follows.

  ┌────
  │ (ilist-dag NAME DEFAULT SORTER &rest BODY)
  └────

  • NAME: This is a string.  The resulting function defined by this
    macro will be named as `ilist-automatic-group-NAME'.
  • DEFAULT: This is also a string.  It is used to label elements for
    which this automatic group returns nil as its label.

    Why not just let the automatic group function give the default label
    instead of nil, then?  Well, people make mistakes all the time, at
    least I do.  So I think this mechanism can help people to remember
    give a default label for elements.
  • SORTER: This should be a function, or the symbol of a function.

    This will be used as the sorting function of the group labels.  The
    sorter function should accept two arguments, and should return a
    non-nil value if and only if the group labelled by the first
    argument should be displayed before the group labelled by the second
    argument.


3 Pixel precision
═════════════════

  Emacs is old, and its age shows from time to time.

  As an example, Emacs usually measures lengths of strings by the
  numbers of characters contained in the strings.  In most situations
  this is not a problem, but in some cases, for example when the string
  contains Chinese characters, this measurement is insufficient for the
  correct alignment inside tables.

  In the beginning, I used the function `string-width' to measure the
  widths of strings, but as its documentation says, this function only
  returns an approximation to the actual width.  This is changed in the
  version /0.2/ of the package.

  Now the package uses the function `string-pixel-width' to measure the
  widths of strings in pixels.  Since working with actual pixels
  requires more computation, and as it does not improve the user
  experience for users who are fine with the approximation provided by
  `string-width', I decide to let the users control whether or not to
  work with pixels by the variable: `ilist-pixel-precision'.  If this
  variable is not `nil', the package works with pixels rather than
  characters, and should provide better alignment and truncation.

  Moreover, if the value of this variable is the symbol `precise', then
  the paddings will use display properties to produce pixel-exact spaces
  so that the alignment is precise and perfect.  See the Info node
  "(elisp) Display Property" for more details.

  However, on text terminals, this may not work as expected, as Emacs
  has no control over exact pixels on a text terminal (my guess).


4 Mapping over lines
════════════════════

  For the convenience of package-users, this package also provides some
  auxiliary functions to operate on the displayed list.  One is
  `ilist-map-lines'.  It is called as follows.

  ┌────
  │ (ilist-map-lines FUN PREDICATE START END NO-SKIP-INVISIBLE)
  └────

  • FUN: The function to execute on each matching line.
  • PREDICATE: This should be a function with no arguments.  It will be
    executed on each line.  If it returns non-nil, that line is
    considered to be matched.
  • START and END limit the range of the mapping.
  • If NO-SKIP-INVISIBLE is non-nil, then we don’t skip invisible lines.


5 Moving
════════

  It might be desired to move between the displayed list items in a
  /cyclic/ manner, that is, assuming the top of the buffer is identified
  with the bottom of the buffer.  So the package provides four functions
  for moving.  These functions all have an argument `NO-SKIP-INVISIBLE';
  if that argument is non-nil, then invisible lines won't skipped.

  • `ilist-backward-line'
  • `ilist-forward-line': Move between lines.  One can control whether
    to skip group headers or to move cyclicly, through the function
    parameters.
  • `ilist-backward-group-header'
  • `ilist-forward-group-header': Move between group headers.


6 Packages using IList
══════════════════════

  The packages that use this library IList, which I know of, are listed
  here:

  • 

  If you know about other packages that use IList, or if you write a
  package using IList, it is welcomed to suggest to list those packages
  here.
