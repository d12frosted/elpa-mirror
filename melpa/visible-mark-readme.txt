Minor mode to highlight mark(s).

Allows setting the number of marks to display, and the faces to display them.

A good blog post was written introducing this package:
https://pragmaticemacs.com/emacs/regions-marks-and-visual-mark/

Example installation:

1. Put this file in Emacs's load-path

2. Add to your init file
(require 'visible-mark)
(global-visible-mark-mode 1) ;; or add (visible-mark-mode) to specific hooks

3. Add customizations.  The defaults are very minimal.
These can also be set via customize.

(defface visible-mark-active ;; put this before (require 'visible-mark)
  '((((type tty) (class mono)) (:inverse-video t))
    (t (:background "magenta")))
  "Custom face for the active mark.")
(setq visible-mark-max 2)
(setq visible-mark-faces '(visible-mark-face1 visible-mark-face2))

Additional useful functions like unpopping the mark are at
https://www.emacswiki.org/emacs/MarkCommands
and https://www.emacswiki.org/emacs/VisibleMark

; Known Bugs

Observed in Circe, when the buffer has a right margin, and there
is a mark at the beginning of a line, any text in the margin on that line
gets styled with the mark's face.  This may also occur with left margins,
though this has not been verified.

Patches/pull requests/feedback welcome.
