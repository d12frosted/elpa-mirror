Library and tools for faces and text properties.

This library is useful for packages that convert syntax highlighted
buffers to other formats.  The functions can be used to determine
how a face or a face text property looks, in terms of primitive
face attributes (e.g. foreground and background colors).  Two sets
of functions are provided, one for existing frames and one for
fictitious displays, like 8 color tty.

In addition, the following tools are provided:

- `face-explorer-list-faces' -- list all available faces.  Like
  `list-faces-display' but with information on how a face is
  defined.  In addition, a sample for the selected frame and for a
  fictitious display is shown.

- `face-explorer-describe-face' -- Print detailed information on
  how a face is defined, and list all underlying definitions.

- `face-explorer-describe-face-prop' -- Describe the `face' text
  property at the point in terms of primitive face attributes.
  Also show how it would look on a fictitious display.

- `face-explorer-list-display-features' -- Show which features a
  display supports.  Most graphical displays support all, or most,
  features.  However, many tty:s don't support, for example,
  strike-through.  Using specially constructed faces, the resulting
  buffer will render differently in different displays, e.g. a
  graphical frame and a tty connected using `emacsclient -nw'.

- `face-explorer-list-face-prop-examples' -- Show a buffer with an
  assortment of `face' text properties.  A sample text is shown in
  four variants: Native, a manually maintained reference vector,
  the result of `face-explorer-face-prop-attributes' and
  `face-explorer-face-prop-attributes-for-fictitious-display'.  Any
  package that convert a buffer to another format (like HTML, ANSI,
  or LaTeX) could use this buffer to ensure that everything work as
  intended.

- `face-explorer-list-overlay-examples' -- Show a buffer with a
  number of examples of overlays, some are mixed with `face' text
  properties.  Any package that convert a buffer to another format
  (like HTML, ANSI, or LaTeX) could use this buffer to ensure that
  everything work as intended.

- `face-explorer-tooltip-mode' -- Minor mode that shows tooltips
  containing text properties and overlays at the mouse pointer.

- `face-explorer-simulate-display-mode' -- Minor mode for make a
  buffer look like it would on a fictitious display.  Using this
  you can, for example, see how a theme would look in using dark or
  light background, a 8 color tty, or on a grayscale graphical
  monitor.

Fictitious displays:

Emacs supports a variety of displays, from graphical frames to
terminals with 8 colors.  Emacs itself provides query functions for
existing displays.  This library provides query functions for any
kind of display, allowing you to play the "what if" game.  (For
example, how would a face look on a grayscale graphical display or
an 8 color tty.)

It is possible to use the query functions for fictitious displays
in batch mode, when the normal face and colors system are severely
restricted.

Library functions:

Function for existing frames:

- `face-explorer-face-attributes' -- The face attributes
  of a face, after expanding all inherited faces.

- `face-explorer-face-prop-attributes' -- The primitive face
  attributes of a face specification, as used by the `face' text
  property.  Effectively, this can tell how a piece of text look to
  the user, expressed in terms of foreground color, background
  color, underline etc.  Face remappings performed by
  `face-remapping-alist' are handled.

- `face-explorer-face-attributes-at' -- The primitive face
  attributes at a specific position in a buffer.

Support for a fictitious display:

The following variables defines a fictitious display.  The
face-explorer tools use the global variants of these variables.
However, when calling the functions in the library, it's possible
to dynamically bind them using `let'.

- `face-explorer-number-of-colors' -- Number of colors.

- `face-explorer-background-mode' -- The background mode, either
  `light' or `dark'.

- `face-explorer-color-class' -- The color class: `color',
  `grayscale', or `mono'.

- `face-explorer-window-system-type' -- The window system type,
  either a symbol like `tty' or a list like `(graphic ns)'.

- `face-explorer-match-supports-function' -- A function to call to
  determine the features a display supports.  By default, a
  graphical display supports everything and a tty supports things
  like underline and inverse video.

The following functions can be used to query face-related
information for fictitious displays:

- `face-explorer-face-attributes-for-fictitious-display'
  -- The face attributes of a face, after expanding all inherited
  faces, for a fictitious display.

- `face-explorer-face-prop-attributes-for-fictitious-display' --
  The primitive face attributes of a face specification, as used by
  the `face' text property, for a fictitious display.  Effectively,
  this can tell how a piece of text look to the user, expressed in
  terms of foreground color, background color, underline etc.

- `face-explorer-face-attributes-for-fictitious-display-at' -- The
  primitive face attributes at a specific position in a buffer, for
  a fictitious display.

Face-related tools:

This package provide a number of face-related tools.  Most of them
display information about a face both in the selected frame and as
it would look on a fictitious display.

Key bindings:

In the tool buffers, you can use the following keys to change the
settings:

- `-', `+', and `#' -- Decrease, increase, and set the number of
  colors of the fictitious display.  The increase and decrease
  commands use 8, 16, 256, and "infinite" colors.

- `b' -- Toggle between light and dark background mode.

- `c' -- Step to the next color class.

- `r' -- Reset the fictitious display to match the selected frame.

- `g' -- Toggle the window system between that of the selected frame
  and a terminal.

Face verifiers:

The `face-explorer-list-faces' and `face-explorer-describe-face'
tools warn about inappropriately defined faces.  You can use the
following keys to handle these warnings:

   - `wd' -- Disable verifier

   - `we' -- Enable verifier

   - `wa' -- Enable all verifiers

   - `wn' -- Disable all verifiers

   - `wx' -- Describe verifier.

The `face-explorer-list-faces' tool:

List all available faces.  Like `list-faces-display' but with
information on how a face is defined.  In addition, a sample for
the both the selected frame and for the current fictitious display
is shown.

Additional keys:

- `RET' -- Open the `face-explorer-describe-face' tool for the face
  on the line of the cursor.

The `face-explorer-describe-face' tool:

Display information about a face.  This includes:

- The documentation

- The face attributes in the selected frame

- Ditto, but with inheritances resolved

- Primitive face attributes and samples for the current fictitious display

- Samples for a number of typical fictitious displays

- The face specifications used to define the face, originating from
  `defface', `custom-theme-set-faces' etc.

The `face-explorer-describe-face-prop' tool:

Display information about a `face' text property.  This includes:

- The value of the property

- The corresponding primitive face attributes in the selected frame,
  with samples.

- Ditto for the current fictitious display

- Samples how the `face' text property would look in a number of
  typical fictitious displays.

The `face-explorer-list-display-features' tool:

Display a buffer contains text using specially constructed faces
that will look differently depending on available display features.
For example, if you run `emacsclient -nw' from a terminal, this
buffer will look differently than it does in a graphical frame.

The `face-explorer-list-face-prop-examples' tool:

List sample text with face text properties in various variants.

This is useful for two reasons:

- It can be used to investigate how Emacs, rally, displays various
  faces and text properties.

- It can be used to test packages that convert text with text
  properties to various other format, like PostScript, HTML, ANSI,
  LaTeX etc.

The `face-explorer-list-overlay-examples' tool:

List sample text with overlays in various variants.

The `face-explorer-tooltip-mode' tool:

A minor mode that shows information about text
properties and overlays in a tooltip.

This is enabled in all buffers displayed by the tools in this
module.

`face-explorer-tooltip-global-mode' can be used to enable this mode
for all buffers.

The `face-explorer-simulate-display-mode' tool:

A minor mode used to show how the current buffer would look in a
fictitious display.  This can be used, for example, to check if a
face theme would look good in a 8 color tty or in a grayscale
graphical display.

The key bindings describe above above are available after the
prefix `C-c !'.

Note: The mode will not restrict colors to the fictitious display.
For example, if a face is defined as "red" it will be shown in red
even when the fictitious display is set to `mono' or `grayscale'.

`face-explorer-simulate-display-global-mode' can be used to enable
this mode for all buffers.

Vocabulary:

Primitive face attributes:

Normally, a face or face specification can be quite complex, for
example a face can inherit from other faces and a face
specification can contain several faces.  "Primitive face
attributes" corresponds to how the face or face specification will
look to the user, the foreground and background color it has,
whether it is bold or italic etc.  Unspecified properties are not
included.  Properties like :height could be relative (like 1.2) or
absolute (like 10).  Primitive face attributes never contain the
`:inherit' attribute.

Technical background:

Face definitions:

The attributes associated with a face can originate from the
following locations:

- `defface' -- This construct defines a customizable face.  The
  information is stored in the property `face-default-spec' in the
  face symbol.  Normally it is accessed using the function
  `face-default-spec'.

- Customize -- A user can customize a face using
  `custom-theme-set-faces'.  The `theme-face' property of the face
  symbol contains an alist from active themes to display
  requirements face specifications.

- Overrides -- Face attributes can be overridden using the function
  `face-spec-set'.  This information is stored in the
  `face-override-spec' property in the face symbol.

- Future frames -- The function `set-face-attribute' can specify
  that an attribute should be set for future frames, by passing nil
  or `t' as FRAME.  This information can be accessed using
  `face-attribute' by passing `t' as the FRAME.

- Existing frames -- A face attribute can be changed in existing
  frames by `set-face-attribute' by passing a frame or nil as
  FRAME.  This information can be accessed using `face-attribute'.

Face aliases:

The `face-alias' property of the face symbol can contain another
symbol which the face is aliased to.

Distant foreground:

A "distant foreground" is an alternative color used to render the
foreground when the normal foreground color would be too close to
the background.  Unfortunately, there is no clear definition of
what "too close" really means, so it is hard to simulate it.
Currently, this package return both the `:foreground' and
`:distant-foreground' attributes.  Hopefully, in the future, it
might be possible to deduce the color that is shown and use
`:foreground' to represent that color.

Other Font Lock Tools:

This package is part of a suite of font-lock tools.  The other
tools in the suite are:


Font Lock Studio:

Interactive debugger for font-lock keywords (Emacs syntax
highlighting rules).

Font Lock Studio lets you *single-step* Font Lock keywords --
matchers, highlights, and anchored rules, so that you can see what
happens when a buffer is fontified.  You can set *breakpoints* on
or inside rules and *run* until one has been hit.  When inside a
rule, matches are *visualized* using a palette of background
colors.  The *explainer* can describe a rule in plain-text English.
Tight integration with *Edebug* allows you to step into Lisp
expressions that are part of the Font Lock keywords.


Font Lock Profiler:

A profiler for font-lock keywords.  This package measures time and
counts the number of times each part of a font-lock keyword is
used.  For matchers, it counts the total number and the number of
successful matches.

The result is presented in table that can be sorted by count or
time.  The table can be expanded to include each part of the
font-lock keyword.

In addition, this package can generate a log of all font-lock
events.  This can be used to verify font-lock implementations,
concretely, this is used for back-to-back tests of the real
font-lock engine and Font Lock Studio, an interactive debugger for
font-lock keywords.


Highlight Refontification:

Minor mode that visualizes how font-lock refontifies a buffer.
This is useful when developing or debugging font-lock keywords,
especially for keywords that span multiple lines.

The background of the buffer is painted in a rainbow of colors,
where each band in the rainbow represent a region of the buffer
that has been refontified.  When the buffer is modified, the
rainbow is updated.


Faceup:

Emacs is capable of highlighting buffers based on language-specific
`font-lock' rules.  This package makes it possible to perform
regression test for packages that provide font-lock rules.

The underlying idea is to convert text with highlights ("faces")
into a plain text representation using the Faceup markup
language.  This language is semi-human readable, for example:

    «k:this» is a keyword

By comparing the current highlight with a highlight performed with
stable versions of a package, it's possible to automatically find
problems that otherwise would have been hard to spot.

This package is designed to be used in conjunction with Ert, the
standard Emacs regression test system.

The Faceup markup language is a generic markup language, regression
testing is merely one way to use it.


Font Lock Regression Suite:

A collection of example source files for a large number of
programming languages, with ERT tests to ensure that syntax
highlighting does not accidentally change.

For each source file, font-lock reference files are provided for
various Emacs versions.  The reference files contains a plain-text
representation of source file with syntax highlighting, using the
format "faceup".

Of course, the collection source file can be used for other kinds
of testing, not limited to font-lock regression testing.

History:

Part of the code of this package was originally published as part
of the package `e2ansi', a package that can emit highlighted text
to a terminal using ANSI sequences.  `e2ansi' can be configured to
be used with the command line command `more' and `less' to syntax
highlight anything viewed using those command.
