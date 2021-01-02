
Semantic is a package that provides a framework for writing
parsers. Parsing is a process of analyzing source code based on
programming language syntax. This package relies on Semantic for
analyzing source code and uses its results to perform smart code
refactoring that based on code structure of the analyzed language,
instead of plain text structure.

To use this package, user only needs to use this single command:
`srefactor-refactor-at-point'

This package includes the following features:

- Context-sensitive menu: when user runs the command, a menu
appears and offer refactoring choices based on current scope of
semantic tag. For example, if the cursor is inside a class, the
menu lists choices such as generate function implementations for
the class, generate class getters/setters... Each menu item also
includes its own set of options, such as perform a refactoring
option in current file or other file.

- Generate class implementation: From the header file, all function
prototypes of a class can be generated into corresponding empty
function implementation in a source file. The generated function
implementations also include all of their (nested) parents as
prefix in the names, if any. If the class is a template, then the
generated functions also includes all templates declarations and in
the parent prefix properly.

- Generate function implementation: Since all function
implementations can be generated a class, this feature should be
present.

- Generate function prototype: When the cursor is in a function
implementation, a function prototype can be generated and placed in
a selected file. When the prototype is moved into, its prefix is
stripped.

- Convert function to function pointer: Any function can be
converted to a function pointer with typedef. The converted
function pointer can also be placed as a parameter of a function.
In this case, all the parameter names of the function pointer is
stripped.

- Move semantic units: any meaningful tags recognized by Semantic
(class, function, variable, namespace...) can be moved relative to
other tags in current file or any other file.

- Extract function: select a region and turn it into a function,
with relevant variables turned into function parameters and
preserve full type information.

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
