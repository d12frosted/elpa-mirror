This package provides a helm source for repository (git, hg, etc) based
file selection.  The emphasis is on fast file-name completion.  The concept
of a "respository" is configurable through `helm-cmd-t-repo-types'.

Each repository is cached for fast access (see
`helm-cmd-t-cache-threshhold'), and in the future, options will be
available to interact with the repository (i.e. grep, etc).

`helm-cmd-t' is the simple predefined command that opens a file in the
current repository, however, it's highly recommended that you add a helm
source like recentf that keeps track of recent files you've worked with.
This way, you don't have to worry about your respository cache being out of
sync.  See "helm-C-x-b.el" for an example of a custom drop-in
replacement for `switch-to-buffer' or "C-x b".


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
