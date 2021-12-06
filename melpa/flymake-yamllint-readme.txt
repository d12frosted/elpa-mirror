This package adds YAML syntax checker yamllint.
Make sure 'yamllint' binary is on your path.
Installation instructions https://github.com/adrienverge/yamllint#installation

flymake-yamllint expect `yamllint' to produce stdout like:
test.yml:2:4: [error] wrong indentation: expected 2 but found 3 (indentation)

Example above should be matched by regex used in code like this:
0: stdin:79:81: [warning] line too long (117 > 80 characters) (line-length)
1: 79
2: 81
3: [warning]
4: line too long (117 > 80 characters) (line-length)

SPDX-License-Identifier: GPL-3.0-or-later

flymake-yamllint is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

flymake-yamllint is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License
along with flymake-yamllint.  If not, see http://www.gnu.org/licenses.
