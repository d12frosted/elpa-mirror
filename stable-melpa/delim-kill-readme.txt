Kill text between two delimiters, preserving structure.

delim-kill.el contains a single convenience function for editing
structured data: delim-kill. Given two characters FROM and TO, it
kills the text between the first occurence of FROM before point and
the first occurence of TO after point. FROM and TO may be
identical.

If FROM and TO are not identical, the function preserves the
balance between the two characters: For each FROM that is
encountered while looking for TO, one additional TO is required;
and vice versa. For example, in "{ foo X{bar} baz }", with X being
point and "{" and "}" as delimiters, the text "{ foo {bar} baz }"
will be killed, not "{ foo {bar}".

delim-kill is useful in programming and in editing other files with
structure, such as CSV or JSON. In C-style langiuages, for
instance, you can use it to easily kill the {}-delimited block you
are currently in. In a CSV file you might kill the current field,
regardless of where point is.

delim-kill was inspired by Damian Conway's course "The productive
programmer". Thanks!

; Dependencies: none.

; Installation:
Put the file anywhere in your load path, (require 'delim-kill), and
bind the function to a key.
