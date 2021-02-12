For speed reading, or just more enjoyable reading. Narrows the buffer to show
one word at a time. Adjust speed / pause as needed.

Download from Melpa or put this script into a "load-path"ed directory, and
load it in your init file:

  (require 'spray)

Then you may run spray with "M-x spray-mode". Binding some keys may
also be useful.

  (global-set-key (kbd "<f6>") 'spray-mode)

In spray-mode buffers, following commands are available.

- =spray-start/stop= (SPC) ::
pause or resume spraying

- =spray-backward-word= (h, <left>) ::
pause and back to the last word

- =spray-forward-word= (l, <right>) ::
inverse of =spray-backward-word=

- =spray-faster= (f) ::
increases speed

- =spray-slower= (s) ::
decreases speed

- =spray-quit= (q, <return>) ::
quit =spray-mode=

You may customize spray by modifying following items:

- [Variable] spray-wpm
- [Variable] spray-height
- [Variable] spray-margin-top
- [Variable] spray-margin-left
- [Variable] spray-ramp
- [Keymap] spray-mode-map
- [Face] spray-base-face
- [Face] spray-accent-face

Readme.org from the package repository has some additional information:
A gif screencast.
Algorithm specification.
Comparison with similar projects.
