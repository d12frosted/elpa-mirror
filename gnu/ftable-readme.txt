#+TITLE: ftable.el

This package provides some convenient commands for filling a table, i.e., adjusting the layout of the table so it can fit in n columns.

[[./ftable.gif]]

Commands provided:

- ftable-fill :: Fill the table at point
- ftable-reformat :: Change the style of the table. For example, from
#+begin_example
                    ASCII +--+--+ to Unicode ┌──┬──┐
                          |  |  |            │  │  │
                          +--+--+            └──┴──┘
#+end_example

- ftable-edit-cell :: Edit the cell at point

There are some limitations. Currently ftable doesn’t support tables with compound cells (cells that span multiple rows/columns) because they are more complicated to handle. If the need arises in the future (unlikely), I might improve ftable to handle more complex tables. Also, after filling, any manual line-break in a cell is discarded.

* Customization

- ftable-fill-column :: ~fill-column~ for ftable.
