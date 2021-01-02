
This package adds tag and filtering capabilities to
`package-menu-mode'.

To activate this package, add this to your .emacs:

(add-hook 'package-menu-mode-hook (lambda () (list-packages-ext-mode 1)))

The user can tag the packages with `lpe:tag', filter by regular
expression with `lpe:filter-with-regexp', filter with by tag with
`lpe:filter-by-tag-expr'.

The tags hidden and starred have special meanings: If a package is
tagged as hidden, it is not shown in the package list, unless
viewing hidden packages is activated, see `lpe:show-hidden-toggle'.
When a package is tagged as "starred", an indicator is shown in the
fringe on the left side.
The commands `lpe:hide-package' and `lpe:star' toggle the "hidden"
and "starred" tags.
All these commands can be used on the active region.

This library also offers an annotation subsystem.  Notes can be set
for a package using `lpe:edit-package-notes': this function brings
up a buffer where the user can edit the notes, and save them with
C-c C-c.

See the help of the minor mode for an overview of the keys.
