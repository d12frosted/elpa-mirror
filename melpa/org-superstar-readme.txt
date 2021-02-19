 Prettify headings and plain lists in org-mode.  This package is a
 direct descendant of ‘org-bullets’, with most of the code base
 completely rewritten (See https://github.com/sabof/org-bullets).
 Currently, this package supports:

* Prettifying org heading lines by:
  + replacing trailing bullets by UTF-8 bullets
  + hiding leading stars, customizing their look or removing them
    from vision
  + applying a custom face to the header bullet
  + applying a custom face to the leading bullets
  + making inline tasks (see org-inlinetask.el) more fancy by:
    - using double-bullets for inline tasks
    - applying a custom face to the marker star of inline tasks
    - using a special bullet for the marker star
    - introducing an independent face for marker stars
  + (optional) using special bullets for TODO keywords
* Prettifying org plain list bullets by:
  + replacing each bullet type (*, + and -) with UTF-8 bullets
  + applying a custom face to item bullets
* Gracefully degrading features when viewed from terminal

This package is heavily influenced by (and uses snippets from) the
popular package "org-bullets", created by sabof.  It was made with
the goal of inheriting features the author liked about org-bullets
while being able to introduce compatibility-breaking changes to it.
It is largely rewritten, to the point of almost no function being
identical to its org-bullets counterpart.

Here are some Unicode blocks which are generally nifty resources
for this package:

General Punctuation (U+2000-U+206F): Bullets, leaders, asterisms.
Dingbats (U+2700-U+27BF)
Miscellaneous Symbols and Arrows (U+2B00-U+2BFF):
    Further stars and arrowheads.
Miscellaneous Symbols (U+2600–U+26FF): Smileys and card suits.
Supplemental Arrows-C (U+1F800-U+1F8FF)
Geometric Shapes (U+25A0-U+25FF): Circles, shapes within shapes.
Geometric Shapes Extended (U+1F780-U+1F7FF):
    More of the above, and stars.
