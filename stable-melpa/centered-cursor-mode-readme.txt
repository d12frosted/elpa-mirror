Makes the cursor stay vertically in a defined position (usually
centered). The vertical position can be altered, see key definition
below.

To load put that in .emacs:
    (require 'centered-cursor-mode)
To activate do:
    M-x centered-cursor-mode
for buffer local or
    M-x global-centered-cursor-mode
for global minor mode.
Also possible: put that in .emacs
    (and
     (require 'centered-cursor-mode)
     (global-centered-cursor-mode +1))
to always have centered-cursor-mode on in all buffers.
