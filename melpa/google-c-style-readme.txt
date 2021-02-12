Provides the google C/C++ coding style. You may wish to add
`google-set-c-style' to your `c-mode-common-hook' after requiring this
file. For example:

   (add-hook 'c-mode-common-hook 'google-set-c-style)

If you want the RETURN key to go to the next line and space over
to the right place, add this to your .emacs right after the load-file:

   (add-hook 'c-mode-common-hook 'google-make-newline-indent)
