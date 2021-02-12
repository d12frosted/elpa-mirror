This package provides a simple text template engine.
A template is a simple text containing $[variable-name] blocks.

Literal $ symbols can be inserted normally unless they are followed by
an open square bracket, in which case they must be doubled.

Example:
'$$[foo]' will be rendered as '$[foo]' after template substitution.

Two functions are provided, `$:fill-template' and
`$:fill-template-from-file', that operate respectively on strings
and on files. The template variable values are passed as alists.

To use these functions, just
 (require 'dollaro)

Example Usage:
($:fill-template "First Name: $[first-name], Last Name: $[last-name]"
                 '((first-name . "Giovanni") (last-name . "Cane")))

($:fill-template-from-file "/path/to/template/file" "/path/to/destination/file"
                           '((some-var . "some value") (another-var . "another value")))
