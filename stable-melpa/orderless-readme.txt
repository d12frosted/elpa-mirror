This package provides an `orderless' completion style that divides
the pattern into components (space-separated by default), and
matches candidates that match all of the components in any order.

Completion styles are used as entries in the variables
`completion-styles' and `completion-category-overrides', see their
documentation.

To use this completion style you can use the following minimal
configuration:

(setq completion-styles '(orderless))

You can customize the `orderless-component-separator' to decide how
the input pattern is split into component regexps.  The default
splits on spaces.  You might want to add hyphens and slashes, for
example, to ease completion of symbols and file paths,
respectively.

Each component can match in any one of several matching styles:
literally, as a regexp, as an initialism, in the flex style, or as
word prefixes.  It is easy to add new styles: they are functions
from strings to strings that map a component to a regexp to match
against.  The variable `orderless-matching-styles' lists the
matching styles to be used for components, by default it allows
literal and regexp matching.
