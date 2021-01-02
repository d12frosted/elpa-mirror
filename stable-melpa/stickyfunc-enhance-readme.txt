
When enable, `semantic-stickyfunc-mode' shows the function point is
currently in at the first line of the current buffer. This is
useful when you have a very long function that spreads more than a
screen, and you don't have to scroll up to read the function name
and then scroll down to original position.

However, one of the problem with current semantic-stickyfunc-mode
is that it does not display all parameters that are scattered on
multiple lines. To solve this problem, we need to redefine
`semantic-stickyfunc-fetch-stickyline' function.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
