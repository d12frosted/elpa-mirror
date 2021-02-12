A minor mode that guesses the indentation offset and
`indent-tabs-mode' originally used for creating source code files and
transparently adjusts the corresponding settings in Emacs, making it
more convenient to edit others' files.

This hooks into many major modes - c-mode, java-mode and ruby-mode, to
name but a few - and makes an educated guess on which offset is
appropriate by analyzing indentation levels in the file.  Modes that have
their own indentation offset guessing, such as python-mode, are not dealt
with.  In modes based on SMIE, dtrt-indent delegates to smie-config-guess.

Heuristics are used to estimate the proper indentation offset and
therefore this system is not infallible, however adjustments will
only be made if the guess is considered reliable.  This way it
should leave you off no worse than before.

To install, M-x customize-variable dtrt-indent-mode, and turn it on.

The default settings have been carefully chosen and tested to work
reliably on a wide range of source files.  However, if it doesn't work
for you they can be fine tuned using M-x customize-group dtrt-indent.
You can use `dtrt-indent-diagnosis' to see dtrt-indent's
measurements, `dtrt-indent-highlight' to show indentation that was
considered,and `dtrt-indent-undo' to undo any changes it makes.


Heuristics

We now describe the inner workings of dtrt-indent and how it arrives
at a conclusion on whether or not to change the indentation settings,
and to which value.

Lines Analyzed

In order to limit performance degradation due to the analysis, only a
fixed number of lines will be analyzed.  If the size of the file is
less than this number of lines, the whole file will be analyzed;
otherwise, the given number of lines at the beginning of the file are
analyzed.

Certain lines are ignored during analysis:

* Empty lines.
* Lines that are not indented (indentation offset 0).
* Lines that are the continuation of a multi-line comment or a
  multi-line statement or expression.
* Lines that only contain a single character can be ignored; by
  default, however, they are included.

If, after ignoring any lines that are not eligible, the number of
relevant lines is smaller than a given threshold then the file is
treated as not fit for analysis and no guess will be made.

Configuration settings used at this stage:
`dtrt-indent-min-relevant-lines', `dtrt-indent-max-lines',
`dtrt-indent-ignore-single-chars-flag'

Histogram Generation

For the remaining lines - those eligible within the fixed range - a
histogram is generated.  The histogram informs dtrt-indent about how
many lines are indented with one space, how many with two spaces, how
many with three spaces, etc.

Offset Assessment

Using the histogram, dtrt-indent determines for each of the potential
indentation offsets (by default, 2 through 8) how many lines are
indented with a multiple of that offset.

Offsets for which the histogram doesn't contain enough distinct
indentations might be ignored; by default, however, a single
indentation per offset is accepted.

After this step, dtrt-indent has a map of probabilities for each of
the potential offsets.

Configuration settings used at this stage: `dtrt-indent-min-offset',
`dtrt-indent-max-offset', `dtrt-indent-min-matching-indentations'

Offset Merging

As a next step, offsets that are a factor of another offset with
similar probability are discarded; this is necessary because in a file
that has been indented with, say, 4 spaces per level, 2 spaces per
level could otherwise be wrongly guessed.

Configuration settings used at this stage:
`dtrt-indent-max-merge-deviation'
;
Final Evaluation

Finally, dtrt-indent looks at the highest probability of all
potential offsets; if that probablity is below a given threshold, the
guess is deemed unreliable and no settings are changed.

If the analysis yielded a best guess that exceeds the absolute
threshold, that guess is deemed reliable and the indentation setting
will be modified.

Configuration settings used at this stage: `dtrt-indent-min-quality'.

`indent-tabs-mode' Setting

For determining hard vs. soft tabs, dtrt-indent counts the number of
lines out of the eligible lines in the fixed segment that are
indented using hard tabs, and the number of lines indented using
spaces.  If either count is significantly higher than the other count,
`indent-tabs-mode' will be modified.

Configuration settings used at this stage:
`dtrt-indent-min-soft-tab-superiority',
`dtrt-indent-min-hard-tab-superiority'

Files not touched by dtrt-indent:

- Files that specify the corresponding variable
  (e.g. c-basic-offset) as a File Variable.

- Files that specify dtrt-indent-mode: 0 as a File Variable.

- Files with a major mode that dtrt-indent doesn't hook into.

- Files for which the indentation offset cannot be guessed
  reliably.

- Files for which `dtrt-indent-explicit-offset' is true; this can be
- used in `.dir-locals.el' files, for example.

Limitations:

- dtrt-indent can't deal well with files that use variable
  indentation offsets, e.g. files that use varying indentation
  based on the outer construct.

- dtrt-indent currently only supports a limited number of languages
  (major-modes).

- dtrt-indent only guesses the indendation offset, not the
  indentation style.  For instance, it does not detect whether a
  C-like file uses hanging braces or not.

- dtrt-indent can't deal well with files that mix hard tabs with
- spaces for indentation.

TODO:

- verbose and diagnostics messages
- make sure variable documentation match their function
- make sure defaults are sensible
- bulk (real world) tests
- functional tests
- unit tests
