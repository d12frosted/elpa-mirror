This makes elscreen can manage multi term buffer each screen.

To use this, add the following line somewhere in your init file:
;; When you use this with elscreen-separate-buffer-list, you need to
;; add this before (require 'elscreen-separate-buffer-list)

     (require 'elscreen-multi-term)

Function: emt-multi-term
  Create multi-term buffer related to screen.
  When the multi-term  buffer already exists, switch to the buffer.

Function: emt-toggle-multi-term
  Toggle between current buffer and the multi-term buffer.

Function: emt-pop-multi-term
  Pop to the multi-term buffer.
