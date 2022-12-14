This package provides convenience functions to insert dummy Latin
text into a buffer.

To install manually, add this file to your `load-path'.  Use the
default keybindings by adding the following to your init file:

(lorem-ipsum-use-default-bindings)

This will setup the following keybindings:

C-c l p: lorem-ipsum-insert-paragraphs
C-c l s: lorem-ipsum-insert-sentences
C-c l l: lorem-ipsum-insert-list

If you want a different keybinding, say you want the prefix C-c C-l, use a
variation of the following:

(global-set-key (kbd "C-c C-l s") 'lorem-ipsum-insert-sentences)
(global-set-key (kbd "C-c C-l p") 'lorem-ipsum-insert-paragraphs)
(global-set-key (kbd "C-c C-l l") 'lorem-ipsum-insert-list)
