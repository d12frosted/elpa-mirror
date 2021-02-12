
This adds support for the Emacs25 xref API (`xref-find-definitions' and
friends) to rtags.  Just `require' it and the default Emacs keybindings
(M-., M-,, M-? etc.) use rtags.

There is just one caveat: `xref-backend-apropos' (`C-M-.' by default) only
supports a very limited regex subset: `.' and `.*', plus `^'/`$'.  This is
because rtags only supports wildcard searches right now.

Apart from that, these bindings expose the full power of rtags.

Enable like this:

  (require 'rtags-xref)
  (add-hook 'c-mode-common-hook #'rtags-xref-enable)
