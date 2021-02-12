Emacs minor mode to highlight mark(s).

Allows setting the number of marks to display, and the faces to display them.

A good blog post was written introducing this package:
http://pragmaticemacs.com/emacs/regions-marks-and-visual-mark/

Example installation:

1. Put this file in Emacs's load-path

2. add custom faces to init file
(require 'visible-mark)
(global-visible-mark-mode 1) ;; or add (visible-mark-mode) to specific hooks

3. Add customizations. The defaults are very minimal. They could also be set
via customize.

(defface visible-mark-active ;; put this before (require 'visible-mark)
  '((((type tty) (class mono)))
    (t (:background "magenta"))) "")
(setq visible-mark-max 2)
(setq visible-mark-faces `(visible-mark-face1 visible-mark-face2))


Additional useful functions like unpoping the mark are at
http://www.emacswiki.org/emacs/MarkCommands
and http://www.emacswiki.org/emacs/VisibleMark

Known bugs

Observed in circe, when the buffer has a right margin, and there
is a mark at the beginning of a line, any text in the margin on that line
gets styled with the mark's face. May also happen for left margins, but
haven't tested yet.

Patches / pull requests / feedback welcome.
