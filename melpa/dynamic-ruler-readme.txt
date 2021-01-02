Displays a dynamic ruler at point that can be freely moved around
the buffer, for measuring and positioning text.

(load "dynamic-ruler") and see the help strings for
`dynamic-ruler' and `dynamic-ruler-vertical'

This ruler is based on the popup-ruler by Rick Bielawski, which in
turn was inspired by the one in fortran-mode but code-wise bears no
resemblance.

; Installation:

Put dynamic-ruler.el on your load path, add a load command to .emacs and
map the main routines to convenient keystrokes. For example:

(require 'dynamic-ruler)
(global-set-key [f9]    'dynamic-ruler)
(global-set-key [S-f9]  'dynamic-ruler-vertical)

Please report any bugs!
