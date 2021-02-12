This makes elscreen can manage buffer list for each screen.

To use this, add the following line somewhere in your init file:

     (require 'elscreen-separate-buffer-list)
     (elscreen-separate-buffer-list-mode)

This apply to ido-mode or something that uses ido-make-buffer-list such as helm.
