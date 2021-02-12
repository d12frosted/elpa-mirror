org-listcruncher is a planning tool that allows the conversion of
an Org mode list to an Org table (a list of lists).  The table can
be used by other Org tables or Org code blocks for further
calculations.

Example:

  #+NAME: lstTest
  - item: item X modified by replacing values (amount: 15, recurrence: 1, end-year: 2020)
    - modification of item X (amount: 20)
    - another modification of item X (other: 500)
      - modification of the modification (other: 299)
  - illustrating inheritance (recurrence: 2, end-year: 2024)
    - item: item A. Some longer explanation that may run over
      multiple lines (amount: 10)
    - item: item B (amount: 20)
    - item: item C (amount: 30)
      - a modification to item C (amount: 25, recurrence: 3)
  - item: item Y modified by operations (amount: 50, recurrence: 4, end-year: 2026)
    - modification by an operation (amount: +50)
    - modification by an operation (amount: *1.5)
  - item: item Z entered in scientific format (amount: 1e3, recurrence: 3, end-year: 2025)
    - modification by an operation (amount: -1e2)

  We can use org-listcruncher to convert this list into a table

  #+NAME: src-example1
  #+BEGIN_SRC elisp :results value :var listname="lstTest" :exports both
    (org-listcruncher-to-table listname)
  #+END_SRC

  #+RESULTS: src-example1
  | description                         | other | amount | recurrence | end-year |
  |-------------------------------------+-------+--------+------------+----------|
  | item X modified by replacing values |   299 |     20 |          1 |     2020 |
  | item A                              |       |     10 |          2 |     2024 |
  | item B                              |       |     20 |          2 |     2024 |
  | item C                              |       |     25 |          3 |     2024 |
  | item Y modified by operations       |       |  150.0 |          4 |     2026 |
  | item Z entered in scientific format |       |  900.0 |          3 |     2025 |

 The parsing and consolidation functions for producing the table can be modified by
 the user.  Please refer to the README and to the documentation strings of the
 functions.
