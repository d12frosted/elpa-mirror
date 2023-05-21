This package lets you show the scope info of blocks like function
definitions, loops, conditions etc.  It does this by adding the
first line of these blocks at the end of the last char of that
block.  It makes use of `tree-sitter' to figure out block start and
end.

The package exposes a single minor mode `scopeline-mode' which you
can use to enable or disable the functionality.

Here is a sample `use-package' configuration

(use-package scopeline
  :config (add-hook 'prog-mode-hook #'scopeline-mode))

You can find more info in the README for the project at
https://github.com/meain/scopeline.el
