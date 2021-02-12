There are several dir-tree widget implements, but I need these features:
 1. display many directory in one buffer to reduce buffer numbers
 2. reuse directory tree when already there is one
 3. use my favarite key binding

So I wrote this one use `tree-mode'.

See also:
http://www.splode.com/~friedman/software/emacs-lisp/src/dirtree.el
http://svn.halogen.kharkov.ua/svn/repos/alex-emacs-settings/emhacks/dir-tree.el

Put this file into your load-path and the following into your ~/.emacs:
  (autoload 'dirtree "dirtree" "Add directory to tree view" t)
