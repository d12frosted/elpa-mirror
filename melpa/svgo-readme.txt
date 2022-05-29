This package uses the Node utility SVGO to optimize SVG files.  It
provides a command to reduce the size of the SVG contents in the
current Emacs buffer.

To install this package you should use `use-package', like so:

(use-package svgo
  :hook
  (nxml-mode . (lambda () (bind-key "M-o" 'svgo nxml-mode-map)))
  (image-mode . (lambda () (bind-key "M-o" 'svgo image-mode-map))))

Also make sure you have Node/NPM installed on your machine.
