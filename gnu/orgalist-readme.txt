This library provides Org mode's plain lists in non-Org buffers, as
a minor mode.

More specifically, it supports syntax for numbered, unnumbered,
description items, checkboxes, and counter cookies.  Examples of
such constructs include:

    - item 1
    - item 2
      - [ ] checkbox sub-item

or

    1. item 1
    2. item 2
       1. sub-item 1
       8. [@8] sub-item 8

and

    - term :: definition
    - term 2 :: definition 2

To start a list, type "- <SPC>" or "1 . <SPC>", then write the
contents of the item.  To create a new item, use M-<RET>.  If it
should be a child of the previous item, use <TAB> (this is
a shortcut for M-<RIGHT> and M-<LEFT> only on empty items), or
M-<RIGHT>.

For example, "- <SPC> i t e m M-<RET> <TAB> c h i l d" produces:

    - item
      - child

See (info "(org) Plain Lists") and (info "(org) Checkboxes") for
more details about the syntax of such constructs.

The following features are supported:

- Item insertion (M-<RET>)
- Navigation (M-<UP>, M-<DOWN>)
- Indentation (M-<LEFT>, M-<RIGHT>, M-S-<LEFT>, M-S-<RIGHT>, <TAB>)
- Re-ordering (M-S-<UP>, M-S-<DOWN>)
- Toggling checkboxes (C-c C-c)
- Cycling bullets (C-c -)
- Sorting items (C-c ^)

The minor mode also supports filling and auto filling, when Auto
Fill mode is enabled.

Note that the bindings above are only available when point is in an
item (for M-<RET>, M-<UP>, M-<DOWN>) or exactly at an item.

The library also implements radio lists:

Call the `orgalist-insert-radio-list' function to insert a radio list
template in HTML, LaTeX, and Texinfo mode documents.  Sending and
receiving radio lists works is the same as for radio tables (see
Org manual for details) except for these differences:

- Orgalist minor mode must be active;
- Use the "ORGLST" keyword instead of "ORGTBL";
- `M-x orgalist-send-list' works only on the first list item.

Built-in translator functions are: `org-list-to-latex',
`org-list-to-html' and `org-list-to-texinfo'.  They use the
`org-list-to-generic' translator function.  See its documentation for
parameters for accurate customizations of lists.  Here is a LaTeX
example:

  % BEGIN RECEIVE ORGLST to-buy
  % END RECEIVE ORGLST to-buy
  \begin{comment}

  #+ORGLST: SEND to-buy org-list-to-latex
  - a new house
  - a new computer
    + a new keyboard
    + a new mouse
  - a new life
  \end{comment}

`M-x orgalist-send-list' on "a new house" inserts the translated
LaTeX list in-between the "BEGIN RECEIVE" and "END RECEIVE" marker
lines.

There is a known incompatibility between Yasnippet and Orgalist,
appearing as the following message:

    (error "Variable binding depth exceeds max-specpdl-size")

To avoid this situation, you must activate Orgalist *before*
Yasnippet.  You can add the following snippet in major mode hooks
where you want both:

    (yas-minor-mode -1)
    (orgalist-mode 1)
    (yas-minor-mode)