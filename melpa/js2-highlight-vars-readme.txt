
This is a minor mode on top of js2-mode which highlights all
occurrences of the variable under the cursor within its defining
scope.

; Installation:

Install this package from MELPA using `M-x install-package` and put
the following in your ~/.emacs.d/init.el:
(eval-after-load "js2-highlight-vars-autoloads"
  '(add-hook 'js2-mode-hook (lambda () (js2-highlight-vars-mode))))

If you aren't already using MELPA, see:
http://melpa.milkbox.net/#/getting-started

GNU Emacs is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
