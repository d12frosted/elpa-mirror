This lib defines the commands `mqr-replace',
`mqr-replace-regexp', `mqr-query-replace' and
`mqr-query-replace-regexp' to match and replace several regexps
in the region.

Interactively, prompt the user for the regexps and their replacements.
If the region is active, then the commands act on the active region.
Otherwise, they act on the entire buffer.

To use this library, save this file in a directory included in
your `load-path'.  Then, add the following line into your .emacs:

(require 'mqr)

You might want to bind `mqr-query-replace', `mqr-query-replace-regexp'
to some easy to remember keys.  If you have the Hyper key, then the
following combos are analogs to those for the Vanila Emacs commands:

(define-key global-map (kbd "H-%") 'mqr-query-replace)
(define-key global-map (kbd "C-H-%") 'mqr-query-replace-regexp)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

This file is NOT part of GNU Emacs.

This file is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This file is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this file.  If not, see <http://www.gnu.org/licenses/>.
