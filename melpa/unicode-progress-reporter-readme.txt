
Quickstart

    (require 'unicode-progress-reporter)

    (unicode-progress-reporter-setup)

    ;; to see a demo
    (unicode-progress-reporter-test)

Explanation

This is a trivial modification to Emacs' built-in progress
reporter to display spinners using Unicode characters.

To use unicode-progress-reporter, place the
unicode-progress-reporter.el library somewhere Emacs can
find it, and add the following to your ~/.emacs file:

    (require 'unicode-progress-reporter)
    (unicode-progress-reporter-setup)

See Also

    M-x customize-group RET unicode-progress-reporter RET

Notes

    redefines `progress-reporter-do-update'

    alters private variable `progress-reporter--pulse-characters'

Compatibility and Requirements

    GNU Emacs version 24.4-devel     : yes, at the time of writing
    GNU Emacs version 24.3           : yes
    GNU Emacs version 23.3 and lower : no

    Requires ucs-utils.el

Bugs

TODO

; License

This library is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
