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

Regression test examples:

This section describes the two typical ways regression testing with
this package is performed.


Full source file highlighting:

The most straight-forward way to perform regression testing is to
collect a number of representative source files.  From each source
file, say `alpha.mylang', you can use `M-x faceup-write-file RET'
to generate a Faceup file named `alpha.mylang.faceup', this file
use the Faceup markup language to represent the text with
highlights and is used as a reference in future tests.

An Ert test case can be defined as follows:

   (require 'faceup)

   (defvar mylang-font-lock-test-dir (faceup-this-file-directory))

   (defun mylang-font-lock-test-apps (file)
     "Test that the mylang FILE is fontifies as the .faceup file describes."
     (faceup-test-font-lock-file 'mylang-mode
                                 (concat mylang-font-lock-test-dir file)))
   (faceup-defexplainer mylang-font-lock-test-apps)

   (ert-deftest mylang-font-lock-file-test ()
     (should (mylang-font-lock-test-apps "apps/FirstApp/alpha.mylang"))
     ;; ... Add more test files here ...
     )

To execute the tests, run something like `M-x ert RET t RET'.


Source snippets:

To test smaller snippets of code, you can use the
`faceup-test-font-lock-string'.  It takes a major mode and a string
written using the Faceup markup language.  The functions strips away
the Faceup markup, inserts the plain text into a temporary buffer,
highlights it, converts the result back into the Faceup markup
language, and finally compares the result with the original Faceup
string.

For example:

   (defun mylang-font-lock-test (faceup)
     (faceup-test-font-lock-string 'mylang-mode faceup))
   (faceup-defexplainer mylang-font-lock-test)

   (ert-deftest mylang-font-lock-test-simple ()
     "Simple MyLang font-lock tests."
     (should (mylang-font-lock-test "«k:this» is a keyword"))
     (should (mylang-font-lock-test "«k:function» «f:myfunc» («v:var»)")))


Executing the tests:

Once the tests have been defined, you can use `M-x ert RET t RET'
to execute them.  Hopefully, you will be given the "all clear".
However, if there is a problem, you will be presented with
something like:

    F mylang-font-lock-file-test
        (ert-test-failed
         ((should
           (mylang-font-lock-test-apps "apps/FirstApp/alpha.mylang"))
          :form
          (mylang-font-lock-test-apps "apps/FirstApp/alpha.mylang")
          :value nil :explanation
          ((on-line 2
    		("but_«k:this»_is_not_a_keyword")
    		("but_this_is_not_a_keyword")))))

You should read this that on line 2, the old font-lock rules
highlighted `this' inside `but_this_is_not_a_keyword' (which is
clearly wrong), whereas the new doesn't.  Of course, if this is the
desired result (for example, the result of a recent change) you can
simply regenerate the .faceup file and store it as the reference
file for the future.

The Faceup markup language:

The Faceup markup language is designed to be human-readable and
minimalistic.

The two special characters `«' and `»' marks the start and end of a
range of a face.


Compact format for special faces:

The compact format `«<LETTER>:text»' is used for a number of common
faces.  For example, `«U:abc»' means that the text `abc' is
underlined.

See `faceup-face-short-alist' for the known faces and the
corresponding letter.


Full format:

The format `«:<NAME OF FACE>:text»' is used use to encode other
faces.

For example `«:my-special-face:abc»' meanst that `abc' has the face
`my-special-face'.


Anonymous faces:

An "anonymous face" is when the `face' property contains a property
list (plist) on the form `(:key value)'.  This is represented using
a variant of the full format: `«:(:key value):text»'.

For example, `«:(:background "red"):abc»' represent the text `abc'
with a red background.


Multiple properties:

In case a text contains more than one face property, they are
represented using nested sections.

For example:

* `«B:abc«U:def»»' represent the text `abcdef' that is both *bold*
  and *underlined*.

* `«W:abc«U:def»ghi»' represent the text `abcdefghi' where the
  entire text is in *warning* face and `def' is *underlined*.

In case two faces partially overlap, the ranges will be split when
represented in Faceup.  For example:

* `«B:abc«U:def»»«U:ghi»' represent the text `abcdefghi' where
  `abcdef' is bold and `defghi' is underlined.


Escaping start and end markers:

Any occurrence of the start or end markers in the original text
will be escaped using the start marker in the Faceup
representation.  In other words, the sequences `««' and `«»'
represent a start and end marker, respectively.


Other properties:

In addition to representing the `face' property (or, more
correctly, the value of `faceup-default-property') other properties
can be encoded.  The variable `faceup-properties' contains a list of
properties to track.  If a property behaves like the `face'
property, it is encoded as described above, with the addition of
the property name placed in parentheses, for example:
`«(my-face)U:abd»'.

The variable `faceup-face-like-properties' contains a list of
properties considered face-like.

Properties that are not considered face-like are always encoded
using the full format and the don't nest.  For example:
`«(my-fibonacci-property):(1 1 2 3 5 8):abd»'.

Examples of properties that could be tracked are:

* `font-lock-face' -- an alias to `face' when `font-lock-mode' is
  enabled.

* `syntax-table' -- used by a custom `syntax-propertize' to
  override the default syntax table.

* `help-echo' -- provides tooltip text displayed when the mouse is
  held over a text.

Reference section:

Faceup commands and functions:

`M-x faceup-write-file RET' - generate a Faceup file based on the
current buffer.

`M-x faceup-view-file RET' - view the current buffer converted to
Faceup.

`faceup-markup-{string,buffer}' - convert text with properties to
the Faceup markup language.

`faceup-render-view-buffer' - convert buffer with Faceup markup to
a buffer with real text properties and display it.

`faceup-render-string' - return string with real text properties
from a string with Faceup markup.

`faceup-render-to-{buffer,string}' - convert buffer with Faceup
markup to a buffer/string with real text properties.

`faceup-clean-{buffer,string}' - remove Faceup markup from buffer
or string.


Regression test support:

The following functions can be used as Ert test functions, or can
be used to implement new Ert test functions.

`faceup-test-equal' - Test function, work like Ert:s `equal', but
more ergonomically when reporting multi-line string errors.
Concretely, it breaks down multi-line strings into lines and
reports which line number the error occurred on and the content of
that line.

`faceup-test-font-lock-buffer' - Test that a buffer is highlighted
according to a reference Faceup text, for a specific major mode.

`faceup-test-font-lock-string' - Test that a text with Faceup
markup is refontified to match the original Faceup markup.

`faceup-test-font-lock-file' - Test that a file is highlighted
according to a reference .faceup file.

`faceup-defexplainer' - Macro, define an explainer function and set
the `ert-explainer' property on the original function, for
functions based on the above test functions.

`faceup-this-file-directory' - Macro, the directory of the current
file.

Real-world examples:

The following are examples of real-world package that use faceup to
test their font-lock keywords.

* [cmake-font-lock](https://github.com/Lindydancer/cmake-font-lock)
  an advanced set of font-lock keywords for the CMake language

* [objc-font-lock](https://github.com/Lindydancer/objc-font-lock)
  highlight Objective-C function calls.


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
