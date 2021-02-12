This file is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This file is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

For a full copy of the GNU General Public License
see <http://www.gnu.org/licenses/>.

backspace like intellij idea

set keybindings for smart-backspace
example
  (global-set-key [?\C-?] 'smart-backspace)
for evil user
  (define-key evil-insert-state-map [?\C-?] 'smart-backspace)
