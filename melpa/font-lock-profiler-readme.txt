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

Usage:

Use the following functions:

- `font-lock-profiler-buffer' -- Fontify the entire buffer and
  present the profiling result.

- `font-lock-profiler-region' -- Fontify the region and present the
  profiling result.

- `font-lock-profiler-start' -- Enable "live" profiling.  Do
  whatever you want to do measure (like editing or scrolling).  When
  done, run `font-lock-profiler-stop-and-report'.

The result buffer:

Once the profiling has been performed, the reporter buffer,
`*FontLockProfiler*' is displayed.  It contains a list of all
font-lock keywords, the number of times they matched and the total
time that was spent running them.

By pressing `x', the view is expanded into displaying the
corresponding information for each highlight rule, including
anchored highlights.

Additional features:

- The variable `font-lock-profiler-remaining-matches', when set to
  an integer, the instrumented keywords will fake a match failure
  after this many matches.  This is useful, for example, when
  working with keywords where a search would never terminate
  (without this, Emacs would hang).

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


Face Explorer:

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
