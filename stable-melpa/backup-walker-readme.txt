I never delete backups.  They are versioned in their own directory, happy
and safe.  My fingers skip to C-x C-s whenever I pause to think about
anything.  Even when I'm working with VCS, I save far more often than I
commit.

This package helps me traverse those backups if I'm looking for something.

The typical workflow is:

  1) I'm in a buffer and realize I need to check some backups.

       M-x backup-walker-start

  2) I press <p> to go backwards in history until I see something
     interesting.  Then I press <enter> to bring it up.  OOPs this isn't
     it, I go back to the backup-walker window and find the right file.

  3) I get what I need from the backup, go back to backup-walker, and press
     <q> and kill all open backups.

  4) the end.

Additionally, note that all the diff-mode facilities are available in the
`backup-walker' buffer.


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
