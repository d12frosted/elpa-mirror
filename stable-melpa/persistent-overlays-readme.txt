persistent-overlays is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

persistent-overlays is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

About

Bugs should be reported on the github issues page:
  https://github.com/mneilly/Emacs-Persistent-Overlays/issues

The goal for persistent-overlays is to maintain persistent overlays
between Emacs sessions.  It has been tested with hideshow and
outline modes on Linux, Mac OS X and Windows.  However, this version
should be considered beta software and it has not been previously
released.

Overlays are stored in ~/.emacs-pov by default.  There are several
customizable variables which allow a user to change the file naming
convention and the storage location of the overlay files.

Please use describe-mode for a full description.

To enable this mode add the following to your ~/.emacs or
~/emacs.d/init.el file.  This assumes that you have placed
persistent-overlays.el somewhere in your load-path.

(load-library "persistent-overlays")

Enjoy
