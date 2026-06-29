indent-bars highlights indentation with configurable vertical
graphical bars, using stipples.  The color and appearance (weight,
pattern, position within the character, zigzag, etc.) are all
configurable.  Options include depth-varying colors and
highlighting the indentation depth of the current line.  Bars span
blank lines, by default.  indent-bars works in any mode using fixed
tab or space-based indentation.  In the terminal (or on request) it
uses vertical bar characters instead of stipple patterns.  Optional
treesitter support is also available; see indent-bars-ts.el.

For Developers:

To efficiently accommodate simultaneous alternative bar styling, we
do two things:

 1. Collect all the style related information (color, stipple
    pattern, etc.) into a single struct, operating on one such
    "current" style struct at a time.

 2. Provide convenience functions for duplicate "alternative"
    custom style variables the user can configure; see
    `indent-bars--style'.  These variables can "inherit" nil or
    omitted plist variables from their parent var.

Note the shorthand substitution for style related slots;
see file-local-variables at the end:

   ibs/  => indent-bars-style-