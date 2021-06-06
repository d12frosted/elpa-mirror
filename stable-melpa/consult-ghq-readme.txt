This packaage provides qhq interface using Consult.

Its main entry points are the commands `consult-ghq-find' and
`consult-ghq-grep`.  Default find-function is affe-find.  If you
want to use consult-find instead, you can change like bellow:

(setq consult-ghq-find-function #'consult-find)
