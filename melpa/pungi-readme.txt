If not using ELPA (i.e list-packages), then add the following to
your init.el/.emacs:

(add-to-list 'load-path 'path-to-this-file)

Using ELPA (When installed from `list-packages'):
(require 'pungi)
(add-hook #'python-mode-hook
          '(lambda ()
             (pungi:setup-jedi)))

Verification that everything is setup correctly:
When visiting a python buffer, move the cursor over a symbol
and check that invoking M-x `jedi:goto-definition' opens a
new buffer showing the source of that python symbol.
