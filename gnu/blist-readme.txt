               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                BLIST: LIST BOOKMARKS IN AN IBUFFER WAY
               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


                         <2021-09-16 Thu 12:26>





1 About
═══════

  The built-in library "bookmark" is useful for storing information that
  can be retrieved later.  But I find the built-in mechanism to display
  the list of bookmarks not so satisfactory, so I wrote this little
  package to display the list of bookmarks in an Ibuffer way.


2 Dependency
════════════

  This package is driven by another package: [ilist].  So make sure to
  install that before using this package.  In fact, the package "ilist"
  was written as an abstraction of the mechanisms of this package.


[ilist] <https://gitlab.com/mmemmew/ilist.git>


3 Usage
═══════

  After installing, one can call the function `blist-list-bookmarks' to
  display the list of bookmarks.  Of course, one can bind a key to that
  function for easier invocations.


3.1 Screenshot
──────────────

  A picture says more about the package than a thousand words.  Below is
  how the list of bookmarks looks like on my end:


3.2 Example configuration
─────────────────────────

  Some examples of configurations are included so that it is easier to
  begin configuring the package.


3.2.1 Example of manual grouping
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (setq blist-filter-groups
  │       (list
  │        (cons "Eshell" #'blist-eshell-p)
  │        (cons "ELisp" #'blist-elisp-p)
  │        (cons "PDF" #'blist-pdf-p)
  │        (cons "Info" #'blist-info-p)
  │        (cons "Default" #'blist-default-p)))
  │ 
  │ ;; Whether one wants to use the header line or not
  │ (setq blist-use-header-p nil)
  │ 
  │ ;; Just use manual filter groups for this example
  │ (setq blist-filter-features (list 'manual))
  │ 
  │ ;; Eshell and Default are defined in the package by default
  │ 
  │ (blist-define-criterion "elisp" "ELisp"
  │   (string-match-p
  │    "\\.el$"
  │    (bookmark-get-filename bookmark)))
  │ 
  │ (blist-define-criterion "pdf" "PDF"
  │   (eq (bookmark-get-handler bookmark)
  │       #'pdf-view-bookmark-jump))
  │ 
  │ (blist-define-criterion "info" "Info"
  │   (eq (bookmark-get-handler bookmark)
  │       #'Info-bookmark-jump))
  └────


3.2.2 Example of automatic grouping
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (setq blist-filter-features (list 'auto))
  │ 
  │ ;; Either this
  │ (setq blist-automatic-filter-groups
  │       #'ilist-automatic-group-blist-default)
  │ 
  │ ;; Or this
  │ (setq blist-automatic-filter-groups
  │       #'ilist-automatic-group-blist-type-only)
  │ 
  │ ;; Or define ones own grouping function
  └────


3.2.3 Example of combining the two groupings
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ ;; The order matters not.
  │ (setq blist-filter-features (list 'manual 'auto))
  │ 
  │ ;; We can use manual groups to place certain important categories of
  │ ;; bookmarks at the top of the list.
  │ ;;
  │ ;; Make sure not to include a default group, otherwise tha automatic
  │ ;; grouping functions would have no chance of being run.
  │ (setq blist-filter-groups
  │       (list
  │        (cons "Eshell" #'blist-eshell-p)
  │        (cons "ELisp" #'blist-elisp-p)
  │        (cons "PDF" #'blist-pdf-p)
  │        (cons "Info" #'blist-info-p)))
  │ 
  │ ;; Either this
  │ (setq blist-automatic-filter-groups
  │       #'ilist-automatic-group-blist-default)
  │ 
  │ ;; Or this
  │ (setq blist-automatic-filter-groups
  │       #'ilist-automatic-group-blist-type-only)
  │ 
  │ ;; Or define ones own grouping function
  └────

  See the following subsections for more details.


3.3 Header
──────────

  Some users prefer to display the names of columns in the /header
  line/.  It has the advantage that it will always be visible, even
  though the user scrolls the buffer.  This package has an option
  `blist-use-header-p' for this purpose.  If that customizable variable
  is non-nil, then blist will display the names of columns in the header
  line.


3.4 Columns
───────────

  As one can see, the display has two columns: a name column and a
  location column.  The name column shows the names of the bookmarks,
  while the location column shows the /locations/, which are either the
  *filename* or the *location* attributes of the bookmarks.

  The variable `blist-display-location-p' controls whether to display
  the locations or not.  Also, one can toggle the display of the
  locations interactively by `blist-toggle-location'.

  The variable `blist-maximal-name-len' determines the maximal length of
  the name column.  And the variable `blist-elide-string' determines how
  to elide the name, when it gets too long.

  If one feels like so, then one can play with the function
  `blist-name-column' to control the name column.


3.5 Groups
──────────

  An important feature of this package is the /filter groups/.  They are
  criteria that group bookmarks together under various sections.  So one
  can find all bookmarks of, say, "Eshell buffers" in one section.

  There are two types of filter groups: the fixed filter groups and the
  automatic filter groups.


3.5.1 Fixed filter groups
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The groups are stored in the variable `blist-filter-groups'.  One can
  add or remove filter groups to that variable.  That variable is a list
  of filter groups, while each filter group is a cons cell of the form
  `(NAME . FUN)', where `NAME' is a string which will be displayed as
  the section header, and `FUN' is a function that accepts a bookmark as
  its argument, and returns non-nil when and only when that bookmark
  belongs to the group.

  Since defining the group functions might be tedious, the package also
  provides a convenient macro `blist-define-criterion' for the users to
  define filter groups easily.  See the documentation string of that
  macro for details.

  Also, the order of the filter groups matters: the filter groups that
  occur earlier on the list have higher priority.  So if an item belongs
  to multiple groups, it will be classified under the group that is the
  earliest on the list.

  Note that the default filter group, which always returns `t' for every
  bookmark, is not needed.  If a bookmark does not belong to any filter
  group, it will be grouped into a default group, whose name is given by
  `blist-filter-default-label'.

  Note that this is a feature of "blist", and not of "ilist": you can
  display a list without default groups.


3.5.2 Automatic filter groups
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  An automatic filter group is a function that can give labels to
  elements in a list.  These labels will be used to group elements
  automatically: the elements with the same label will be grouped
  together.  Besides, an automatic filter group is also responsible for
  sorting group labels, and for giving a default label, if no default
  labels are specified.

  To be precise, an automatic filter group is a function with the
  signature: `(ELEMENT &optional TYPE)'.  The optional argument `TYPE'
  says what the caller wants from the function:

  • `nil': If it is omitted or nil, the function should just return the
    label for `ELEMENT'.

  • `default': If it is the symbol `default', the function should return
    a default label.

  • `sorter': If it is the symbol `sorter', the function should return a
    function with two arguments, `X' and `Y'.  This returned function
    should return a non-nil value if and only if group `X' should be
    placed earlier than group `Y'.

  The automatic filter group to use is stored in the variable
  `blist-automatic-filter-groups'.  Its default value is
  `blist-automatic-filter-groups-default'.

  If you want to define your own automatic filter group, then the macro
  `ilist-define-automatic-group', or `ilist-dag', defined in "ilist",
  might come in handy.  The default automatic filter group is defined by
  that macro, for your information.


3.5.3 Two default automatic groups
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  There are two pre-defined automatic groups in the package: the default
  one and the /type-only/ one.


◊ 3.5.3.1 Default group

  In Emacs 29 or later, if a bookmark handler function symbol has a
  property called `bookmark-handler-type', it will be recognized as the
  type of the bookmark, which can be retrieved by the function
  `bookmark-type-from-full-record'.

  The default group will use the type of a bookmark as the group header,
  if the type is available, otherwise it falls back to use file name
  extensions.


◊ 3.5.3.2 Type-only group

  This automatic group only uses the type of a bookmark as the group
  header.  If the type is not available, it always uses the default
  group.


3.5.4 Combine fixed and automatic filter groups
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  What if one wants to use both the fixed filter groups and the
  automatic filter group to group elements?  Then one can set the
  variable `blist-filter-features'.  This variable should be a list of
  /featuers/ to use.  Currently there are two features: `manual' and
  `auto'.  If one adds `manual' to the list of features, then the fixed
  filter groups will be used; if one adds `auto' to the list of
  features, then the automatic filter groups will be used.

  Further, if one adds both `manual' and `auto' to the list of features,
  then both filter groups will be used.  The elements will first go
  through the fixed filter groups to see if it belongs to some fixed
  filter group.  If an element belongs to none of the fixed filter
  groups, then the automatic filter group will be used to find the label
  for the element.  If a poor element is given no labels, then the
  default label `blist-filter-default-label' will be used.

  Wait, one asks, what if the list contains no features?  Don't worry,
  it is not the end of blist.  In this case all elements will be
  considered as belonging to the default group
  `blist-filter-default-label'.


3.6 Calling convention(s)
─────────────────────────

  For the ease and brevity of writing, let's establish a convention for
  describing the interactive arguments of functions.

  In this document, the phrase "XYZ-convention" should be understood as
  a specification of how the arguments to a function are supposed to be
  obtained when called interactively.  Here the letters "XYZ" have
  special meanings:

  *Note:* It is implied that the bookmarks in the folded groups are not
  operated upon by user commands.

  • "M": marked bookmarks
  • "R": the bookmarks in the region, if the region is active
  • "G": the bookmarks of a group, if the point is at the heading of
    that group
  • "0": the 0-th bookmark, that is, the bookmark at point, if any
  • "C": use `completing-read' to let the user choose a bookmark
  • "P": the ARG next bookmarks, where ARG is the prefix argument


3.7 Navigations
───────────────

  The following is a list of default key-bindings to navigate in the
  list of bookmarks.  Except for the two /jump/ commands, they all
  follow the P-convention.

  • `n', `p': go to next/previous line.  Whether it treats the top of
    the buffer as identified with the bottom of the buffer is controlled
    by the variable `blist-movement-cycle'.
  • `N', `P': go to next/previous line that is not a group heading.
  • `M-n', `M-p': go to next/previous group heading.
  • `j', `M-g': jump to a bookmark, using the C-convention
  • `J', `M-j', `M-G': jump to a group heading, using the C-convention
  • `M-{' and `)': go to the previous marked bookmark.
  • `)' and `M-}': go to the next marked bookmark.


3.8 Marking
───────────

  The following is a list of default key-bindings to mark bookmarks and
  to operate on the bookmarks.

  Unless stated otherwise, they all follow the *P-convention*.

  • `m': Mark the bookmark with the default mark (`blist-default-mark')
    and advance.
  • `d', `k': Mark for deletion and advance.
  • `C-d': Mark for deletion and go backwards.
  • `x': Delete all bookmarks that are marked for deletion.
  • `D': Delete the bookmark immediately (the MRG0-convention).
  • `u': Unmark the bookmark and advance.
  • `DEL': Unmark the bookmark and go backwards.
  • `U': Unmark all bookmarks.
  • `M-DEL', `* *': prompt for a mark and unmark all boomarks that are
    marked with the entered mark (using `read-char').
  • `% n': Mark bookmarks whose name matches a regular expression.
  • `% l': Mark bookmarks whose location matches a regular expression.
  • `* c': Change the marks from OLD to NEW (using `read-char')
  • `t': Toggle marks: an item is going to be marked if and only if it
    is currently not marked.


3.9 Jump to bookmarks
─────────────────────

  The following lists the default key-bindings for jumping to, or
  opening bookmarks.  Except for `v', they operate on the bookmark (or
  group) at point.

  • `RET': Either open the bookmark in this window or toggle the group
    at point.
  • `o': Open the bookmark in another window.
  • `v': Select the bookmarks (the MG0-convention).  How multiple
    bookmarks are opened is controlled by the variable
    `blist-select-manner'.  See its documentation for details.


3.10 Annotations
────────────────

  The following lists the default key-bindings for operating on the
  annotations of bookmarks.

  • `a': View the annotations of bookmarks (the MGC-convention).
  • `A': View the annotations of all bookmarks.
  • `e': edit the annotation of the bookmark at point.  If called with
    `universal-argument', prompt for the bookmark to edit with
    completion.


3.11 Others
───────────

  • `R': Relocate the bookmark.
  • `r': Rename the bookmark.
  • `l': Load bookmarks from a file, and prepend these bookmarks to the
    front of the bookmarks list.
  • `S-RET': Toggle all other groups than the group at which the cursor
    sits.  This creates a kind of narrowing effect, and is fun to apply
    on different groups successively.

  Some functions are too minor to record here.  Use `describe-mode' in
  the list of bookmarks to see all available key-bindings.
