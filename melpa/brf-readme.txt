Brf-mode adds functionality from the legendary programmer's editor `Brief' to Emacs.

It is not an emulation of `Brief' (there are plenty of those already), but rather
provides an accurate implementation in Emacs of specific features that I miss
from `Brief'.

The emphasis is on *accurately* implementing these features in Emacs rather than doing
what Brief emulations tend to do, which is mapping the Brief key-sequences to somewhat
similar functions in Emacs.

The provided features are:

* Line-mode cut and paste.
* Column-mode cut and paste.
* Fully reversible paging and scrolling.
* Temporary bookmarks.
* Cursor motion undo.
* Easy window management.

They have been implemented in an Emacs-style. This means the functions respond to prefix
args and where they override Emacs functions, they live on the Emacs key bindings as well
as the original Brief keys.

Moreover, functionality has been extended to those parts of Emacs that were never part of Brief.
For example, text cut/copied in line or column-mode can be saved/recalled in registers.

See the website, Info manual or README.org for further details.
