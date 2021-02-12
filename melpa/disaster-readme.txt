![Screenshot](http://i.imgur.com/kMoN1m6.png)

Disaster lets you press `C-c d` to see the compiled assembly code for the
C/C++ file you're currently editing. It even jumps to and highlights the
line of assembly corresponding to the line beneath your cursor.

It works by creating a `.o` file using make (if you have a Makefile) or the
default system compiler. It then runs that file through objdump to generate
the human-readable assembly.

; Installation:

Make sure to place `disaster.el` somewhere in the load-path and add the
following lines to your `.emacs` file to enable the `C-c d` shortcut to
invoke `disaster':

    (add-to-list 'load-path "/PATH/TO/DISASTER")
    (require 'disaster)
    (define-key c-mode-base-map (kbd "C-c d") 'disaster)
