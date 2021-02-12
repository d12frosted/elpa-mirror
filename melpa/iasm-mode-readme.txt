Inspired by Justine Tunney's disaster.el (http://github.com/jart/disaster‎).

iasm provides a simple interactive interface objdump and ldd which
facilitates assembly exploration. It also provides tools to speed up the
edit-compile-disasm loop.

This mode currently only supports Linux because it relies rather heavily on
objdump and ldd. It also hasn't been tested for other CPU architectures or
other unixes so expect some of the regexes to spaz out in colourful ways.

Note that this is my first foray into elisp so monstrosities abound. Go forth
at your own peril. If you wish to slay the beasts that lurk within or simply
add a few functionalities, contributions are more then welcome. See the todo
section for ideas.


; Installation:

Make sure to place `iasm-mode.el` somewhere in the load-path and add the
following lines to your `.emacs` to enable iasm:

    (require 'iasm-mode)

    (global-set-key (kbd "C-c C-d") 'iasm-disasm)
    (global-set-key (kbd "C-c C-l") 'iasm-ldd)

    (add-hook 'c-mode-common-hook
              (lambda ()
               (local-set-key (kbd "C-c d") 'iasm-goto-disasm-buffer)
               (local-set-key (kbd "C-c l") 'iasm-disasm-link-buffer)))
