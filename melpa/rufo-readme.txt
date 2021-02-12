This package provides the rufo-minor-mode minor mode, which will use rufo
(https://github.com/ruby-formatter/rufo) to automatically fix ruby code
when it is saved.

To use it, require it, make sure `rufo' is in your path and add it to
your favorite ruby mode:

   (add-hook 'ruby-mode-hook #'rufo-minor-mode)
