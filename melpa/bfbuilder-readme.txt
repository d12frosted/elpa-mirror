Require this script and setup `auto-mode-alist'

  (require 'bfbuilder)
  (add-to-list 'auto-mode-alist '("\\.bf$" . bfbuilder-mode))

then `bfbuilder-mode' is activated when opening ".bf" files.

For more informations, see "Readme".
