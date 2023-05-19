Copyright (C) 2023  Free Software Foundation, Inc.
See the end of the file for license conditions.

Calibre.el is a package for interacting with Calibre
(https://calibre-ebook.com/) libraries from Emacs. It's primary features
include:
- Easily switch between multiple libraries
- List the contents of your library
- Filter the contents of your library based on various metadata
- Create Virtual Libraries by giving names to sets of filters
- Add and remove books from your library
- Modify the metadata of your books
- Read your books in Emacs

Calibre.el can use either the calibredb command line interface, or
Emacs 29's SQLite support to retrive the contents of the Calibre
library.  The SQLite based interface is significantly faster, and
enables the viewing of existing libraries without a working Calibre
installation.  A working Calibre installation is always required for
modifying the library.


This file is part of calibre.el.

calibre.el is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

calibre.el is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with calibre.el.  If not, see <http://www.gnu.org/licenses/>.
