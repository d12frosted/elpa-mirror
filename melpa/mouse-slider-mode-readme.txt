With this minor mode enabled in a buffer, right-clicking and
dragging horizontally with the mouse on any number will
increase/decrease it. It's works like this (video is not actually
about this minor mode):

  http://youtu.be/FpxIfCHKGpQ

If an evaluation function is defined for the current major mode in
`mouse-slider-mode-eval-funcs', the local expression will also be
evaluated as the number is updated. For example, to add support for
[Skewer](https://github.com/skeeto/skewer-mode) in
[js2-mode](https://github.com/mooz/js2-mode),

  (add-to-list 'mouse-slider-mode-eval-funcs
               '(js2-mode . skewer-eval-defun))

The variable `mouse-slider-eval' enables/disables this evaluation
step.
