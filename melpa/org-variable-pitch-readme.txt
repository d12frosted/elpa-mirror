Variable-pitch support for org-mode.  This minor mode enables
‘variable-pitch-mode’ in the current Org-mode buffer, and sets some
particular faces up so that they are are rendered in fixed-width
font.  Also, indentation, list bullets and checkboxes are displayed
in monospace, in order to keep the shape of the outline.

; Installation:

Have this file somewhere in the load path, then:

  (require 'org-variable-pitch)
  (add-hook 'org-mode-hook 'org-variable-pitch-minor-mode)
