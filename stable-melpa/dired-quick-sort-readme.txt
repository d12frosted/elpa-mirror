
This package provides ways to quickly sort dired buffers in various ways.
With `savehist-mode' enabled (strongly recommended), the last used sorting
criteria are automatically used when sorting, even after restarting Emacs.  A
hydra is defined to conveniently change sorting criteria.

For a quick setup, Add the following configuration to your "~/.emacs" or
"~/.emacs.d/init.el":

    (require 'dired-quick-sort)
    (dired-quick-sort-setup)

This will bind "S" in dired-mode to invoke the quick sort hydra and new Dired
buffers are automatically sorted according to the setup in this package.  See
the document of `dired-quick-sort-setup` if you need a different setup.  It
is recommended that at least "-l" should be put into
`dired-listing-switches'.  If used with dired+, you may want to set
`diredp-hide-details-initially-flag' to nil.

To make full use of this extensions, please make sure that the variable
`insert-directory-program' points to the GNU version of ls.

To comment, ask questions, report bugs or make feature requests, please open
a new ticket at the issue tracker
<https://gitlab.com/xuhdev/dired-quick-sort/issues>. To contribute, please
create a merge request at
<https://gitlab.com/xuhdev/dired-quick-sort/merge_requests>.
