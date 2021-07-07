If you ever dreamed about creating and switching buffer groups at will
in Emacs, Torus is the tool you want.

In short, this plugin let you organize your buffers by creating as
many buffer groups as you need, add the files you want to it and
quickly navigate between :

  - Buffers of the same group
  - Buffer groups
  - Workspaces, ie sets of buffer groups

Note that :

  - A location is a pair (buffer (or filename) . position)
  - A buffer group, in fact a location group, is called a circle
  - A set of buffer groups is called a torus (a circle of circles)

Original idea by Stefan Kamphausen, see https://www.skamphausen.de/cgi-bin/ska/mtorus

See https://github.com/chimay/torus/blob/master/README.org for more details

Important note for version 1 users

The version 2 of Torus is built using the Duo library of inplace list
operations. It means a cleaner code, easier to maintain and extend,
but also a drastic change in the data structure.

In particular, the format of torus files has changed, so it is
recommended to backup your version 1 torus files, just in case
something would go wrong with the conversion.
