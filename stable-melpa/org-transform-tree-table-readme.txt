
Transform an org-mode outline and its properties to a table format
(org-table, CSV).

This makes it possible to have an outline with properties and work
with it in column view. Then you can transform the outline to a table
to share with others (export to CSV and open in Excel).

More about column view:

* http://orgmode.org/worg/org-tutorials/org-column-view-tutorial.html
* http://orgmode.org/manual/Column-view.html


; Usage
-----

### From org tree to table

    ;; Org outline to an org table
    M-x org-transform-tree/org-table-buffer-from-outline

    ;; Org outline to CSV (or rather, tab-separated value)
    M-x org-transform-tree/csv-table-buffer-from-outline

If the region is active, convert that part of the
tree. Otherwise, if point is on an org heading, convert that
heading and its subtree. Otherwise convert the buffer.

In the resulting table, row one is the column titles. The rest of
the rows are property values.

Column one is the outline heading, and the rest are the
properties in the order they first appear in the buffer.

However, all special properties (e.g. 'COLUMNS', '*_ALL') are
placed after all the user properties (i.e. whatever properties
the user has added to capture information).

Special values that can't be represented in an org table are escaped:

    |                   ==> \vert{}
    first leading space ==> non-breaking space (C-x 8 SPC)


### From table to org tree

    ;; From an org table to an org outline
    M-x org-transform-table/org-tree-buffer-from-org-table

    ;; From CSV (tab separated) to an org outline
    M-x org-transform-table/org-tree-buffer-from-csv

When converting from an org table, point must be on a table.

When converting CSV, convert the buffer.

Values escaped from any tree->table transformation are unescaped (see above)



Tiny example
------------

This outline:

    * Pages
      :PROPERTIES:
      :COLUMNS:  %30ITEM %10Access %10Cost
      :END:
    ** Products
       :PROPERTIES:
       :Access:   All
       :END:
    *** Free Widget
        :PROPERTIES:
        :Access:   All
        :END:
    *** Paid Thingy
        :PROPERTIES:
        :Access:   Paid
        :Cost:     30
        :END:

Transforms into:

    | Heading         | Access | Cost | COLUMNS                   |
    | * Pages         |        |      | %30ITEM %10Access %10Cost |
    | ** Products     | All    |      |                           |
    | *** Free Widget | All    |      |                           |
    | *** Paid Thingy | Paid   |   30 |                           |

Note that the special property COLUMNS are out on the right, to be out
of the way when the table is being edited in e.g. Excel or Open
Office.

This also means the transformation is only 99% round-trip safe and the
first time you go back to a tree representation, you'll get more diffs
than subsequent ones.


; Installation
------------

Install org-transform-tree-table using MELPA.

Or clone the repo into somewhere in the load-path.

    git clone https://github.com/jplindstrom/emacs-org-transform-tree-table.git

and initialize with:

   (require 'org-transform-tree-table)


; Changes
-------

2014-12-28 - 0.1.3

* Transform text below headings


2014-12-26 - 0.1.2

* Bug fixes, doc fixes
* Toggle between tree and table


2014-12-23 - 0.1.1

* Initial release


; Contributors
------------

* Syohei YOSHIDA - https://github.com/syohex
