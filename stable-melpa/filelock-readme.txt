Emacs has the ability to create lock files to prevent two Emacs
processes from editing the same file at the same time. However, the
internal functions to programmatically lock and unlock files are
not exposed in Emacs Lisp. Emacs simply locks a file when the
buffer visiting it becomes modified, and unlocks it after the
buffer is saved or reverted. Furthermore, when Emacs encounters
another process's lock file, by default it prompts interactively
for what to do.

This package provides a simple interface for manually locking and
unlocking files using the standard Emacs locks, suitable for use in
programming. The basic functions are `filelock-acquire-lock' and
`filelock-release-lock', and a macro called `with-file-lock' is also
provided.

Note that locking a file using these functions does not prevent
Emacs from unlocking it under the usual circumstances. For example,
if you call `filelock-acquire-lock' on a file and then save a buffer
visiting the same file, the lock will still be released as usual
when the buffer is saved. It is probably not practical to fix this
without modifying the C code of Emacs.

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
