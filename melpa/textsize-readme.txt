
This package automatically calculates and adjusts the default text size for
the size and pixel pitch of the display.

Hooks to perform the adjustment automatically are set up by enabling
`textsize-mode' on initialization.  e.g.:

    (use-package textsize
      :custom
      (textsize-default-points 18)
      (textsize-monitor-size-thresholds '((0 . -3) (280 . 0) (500 . 3) (1000 . 6) (1500 . 9)))
      (textsize-pixel-pitch-thresholds '((0 . 3) (0.12 . 0) (0.18 . -3) (0.22 . -6) (0.40 . 12)))
      :init (textsize-mode))

Alternatively, the adjustment may be manually triggered by calling
`textsize-fix-frame'.

You will first want to adjust `textsize-default-points' if the default size
does not match your preferences.

The calculation is very simplistic but should be adaptable to many scenarios
and may be modified using the `-thresholds' customizations below.

You may wish to bind keys for transient manual adjustment of the current
frame with `textsize-increment', `textsize-decrement', and `textsize-reset'
