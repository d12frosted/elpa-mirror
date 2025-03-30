This package adds a table formatter for calculating invoices for project
based todo items. You may use it with the `:formatter' keyword in the
#+BEGIN: clocktable option.

The formatter will also generate columns for effort estimates & comments if
they are specified and applicable. Use the `:properties' keyword and provide
a list containing property you would like as a column. For example:
:properties ("Effort" "Comments").

You may also override the billable rate for the table with the `:rate'
property.
