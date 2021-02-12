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

; License
; ------------------------------

This file is not part of Emacs.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING. If not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.
