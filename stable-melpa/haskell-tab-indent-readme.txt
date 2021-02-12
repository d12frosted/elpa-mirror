This file provides `haskell-tab-indent-mode', a simple indentation
mode for Haskell projects which require tabs for indentation and do
not permit spaces (except for where clauses, as a special case).

The user may use TAB to cycle between possible indentations.

Installation:

If you set `indent-tabs-mode' in the .dir-locals.el file for a
project requiring tabs, you can use something like this in your
init file to enable this mode for such projects:

   (add-hook 'haskell-mode-hook
               (lambda ()
                 (add-hook 'hack-local-variables-hook
                           (lambda ()
                             (if indent-tabs-mode
                                 (haskell-tab-indent-mode 1)
                               (haskell-indentation-mode 1)))
                           nil t))) ; local hook
