This packaage provides ghq interface using Consult.

Its main entry points are the commands `consult-ghq-find' and
`consult-ghq-grep`.  Default find-function is affe-find, if it's
installed, otherwise consult-find.  If you want to use consult-find
despite having affe installed, you can change like below:

(setq consult-ghq-find-function #'consult-find)
