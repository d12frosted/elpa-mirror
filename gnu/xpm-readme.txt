This package makes editing XPM images easy (and maybe fun).
Editing is done directly on the (textual) image format,
for maximal cohesion w/ the Emacs Way.

Coordinates have the form (X . Y), with X from 0 to (width-1),
and Y from 0 to (height-1), inclusive, in the 4th quadrant;
i.e., X grows left to right, Y top to bottom, origin top-left.

  (0,0)        … (width-1,0)
    ⋮                    ⋮
  (0,height-1) … (width-1,height-1)

In xpm.el (et al), "px" stands for "pixel", a non-empty string
in the external representation of the image.  The px length is
the image's "cpp" (characters per pixel).  The "palette" is a
set of associations between a px and its "color", which is an
alist with symbolic TYPE and and string CVALUE.  TYPE is one of:

  c  -- color (most common)
  s  -- symbolic
  g  -- grayscale
  g4 -- four-level grayscale
  m  -- monochrome

and CVALUE is a string, e.g., "blue" or "#0000FF".  Two images
are "congruent" if their width, height and cpp are identical.

This package was originally conceived for non-interactive use,
so its design is spartan at the core.  However, we plan to add
a XPM mode in a future release; monitor the homepage for updates.

For now, the features (w/ correspondingly-named files) are:
- xpm          -- edit XPM images
- xpm-m2z      -- ellipse/circle w/ fractional center

Some things are autoloaded.  Which ones?  Use the source, Luke!
(Alternatively, just ask on help-gnu-emacs (at gnu dot org).)