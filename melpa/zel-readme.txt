zel tracks the most used files, based on 'frecency'.  Zel is
basically a port of z[1] in Emacs Lisp.

The list of 'frecent' files underlies two concepts:

1. The files are not only ranked on how recent they have been
visited, but also how frequent they have been visited.  A file that
has been visited multiple times last week gets a higher score as
file visited once yesterday.  Outliers should not compromise the
'frecent' list.

2. Entries in the 'frecent' list undergo aging.  If the age of a
entry falls under a threshold it gets removed from the 'frecent'
list.

[1] https://github.com/rupa/z

;; Installation

;;; MELPA

If you installed from MELPA, you're done.

;;; use-package

(use-package zel
  :ensure t
  :demand t
  :bind (("C-x C-r" . zel-find-file-frecent))
  :config (zel-install))

;;; Manual

Install these required packages:

- frecency

Then put this file in your load-path, and put this in your init
file:

(require 'zel)

;; Usage

1. Run (zel-install)
2. Bind `zel-find-file-frecent' to a key,
   e.g. (global-set-key (kbd "C-x C-r") #'zel-find-file-frecent)
3. Visit some files to build up the database
4. Profit.

As default the 'frecent' history is saved to `zel-history-file'.
Run 'M-x customize-group RET zel' for more customization options.

Besides `zel-find-file-frecent', that lets you select a file with
`completing-read' and switches to it, there is also the command
`zel-diplay-rankings' that shows all entries of the 'frecent' list
along with their score.

If you'd like to stop building up the 'frecent' list then run
`zel-uninstall' to deregister `zel' from all hooks.

;; Credits

- https://github.com/rupa/z
- https://github.com/alphapapa/frecency.el

; License

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
