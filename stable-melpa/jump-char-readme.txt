Navigate by char.  The best way to "get" it is to try it.

Interface (while jumping):

  <char>   :: move to the next match in the current direction.
  ;        :: next match forward (towards end of buffer)
  ,        :: next match backward (towards beginning of buffer)
  C-c C-c  :: invoke ace-jump-mode if available (also <M-/>)

Any other key stops jump-char and edits as normal.

The behaviour is strongly modeled after `iy-go-to-char' with the following
differences:

  * point always stays before match

  * point during search is same as after exiting

  * lazy highlighting courtesy of isearch


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 3, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 51 Franklin Street, Fifth
Floor, Boston, MA 02110-1301, USA.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
