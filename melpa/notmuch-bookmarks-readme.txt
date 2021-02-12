This package adds a global minor mode which allows you to bookmark
notmuch buffers via the standard Emacs bookmark functionality. A
`notmuch buffer' denotes either a notmuch tree view, a notmuch
search view or a notmuch show buffer (message view). With this
minor mode active, you can add these buffers to the standard
bookmark list and visit them, e.g. by using `bookmark-jump'.

To activate the minor mode, add something like the following to
your init file:

(use-package notmuch-bookmarks
  :after notmuch
  :config
  (notmuch-bookmarks-mode))

This package is NOT part of the official notmuch Emacs suite.
