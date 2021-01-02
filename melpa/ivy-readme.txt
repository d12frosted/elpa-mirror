This package provides `ivy-read' as an alternative to
`completing-read' and similar functions.

There's no intricate code to determine the best candidate.
Instead, the user can navigate to it with `ivy-next-line' and
`ivy-previous-line'.

The matching is done by splitting the input text by spaces and
re-building it into a regex.
So "for example" is transformed into "\\(for\\).*\\(example\\)".
