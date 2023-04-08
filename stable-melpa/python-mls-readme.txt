Python-MLS provides multi-line shell capatibilities for (i)Python
run in an inferior shell, building on the Emacs-bundled python.el's
python-mode.

Features:
- Works with both python and ipython.
- Accepts arbitrary multi-line command lengths.
- Auto-detects and handles native continuation prompts.
- Auto-indents multi-line commands.
- Replaces buffer-based code fontifications with in-buffer
  python-mode fontification for dramatic speedup.
- Up/Down arrow history browsing with and without movement within
  block (try shift arrow).
- Saves and restore (multi-line) command history, separated per
  shell buffer name.
- Directly kill/yank multi-line code blocks to & from Python
  buffers.

Python-MLS is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Python-MLS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
