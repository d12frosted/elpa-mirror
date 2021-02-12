
This package currently provides the following function:

* `query-replace-with-inflections'

Tis is an inflection aware version of `query-replace'.  For
example, replacing "foo_bar" with "baz_quux" will also replace
"foo_bars" with "baz_quuxes", "FooBar" with "BazQuux", "FOO_BAR"
with "BAZ_QUUX", and so on.

Read the docstring for details.

For the term "inflection", refer to the following packages which this
library depends on:

* inflections: URL `https://github.com/eschulte/jump.el'
* string-inflection: URL `https://github.com/akicho8/string-inflection'

Here's my suggested settings:

  (define-key search-map "n" 'query-replace-with-inflections)
