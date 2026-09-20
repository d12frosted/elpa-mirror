Nightpanel is a dark theme modelled on a Saab instrument cluster seen
at night: a pure black canvas, instrument-scale green for body text,
and amber reserved for the things that would be a needle or a warning
lamp on a real dashboard.

The palette is deliberately narrow.  Green carries ordinary text and
structure; amber marks anything that wants your eye (search matches,
strings, constants, TODO keywords); red appears only for genuine
errors.  Comments and inactive chrome recede to a dim green so the
code itself is the brightest thing on screen.

Usage:

    (load-theme 'nightpanel t)

Or interactively with `M-x load-theme'.

Nightpanel targets true-colour displays.  It sets 24-bit hex values
without terminal fallbacks, so on a low-colour tty Emacs will
approximate them and the result will not match a GUI frame.
