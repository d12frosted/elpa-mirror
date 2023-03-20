feline is a fast, low-frills modeline replacement for Emacs.

feline saves space by displaying only a few things:
  • evil state
    (state name and customizable colour)
  • file-edited state
    (a * if edited)
  • the major mode
    (or a customizable shorthand/symbol alias)
  • buffer ID
    (e.g. filename)
  • the current project.el project name
    (if active)
  • line and column number
    (like L18C40)
  • `mode-line-misc-info'
    (a place that modes put useful info sometimes)

Each segment has its own customizable face.  You'll notice that list does not
mention minor modes.  feline doesn't show minor modes.  The information it
chooses to show is very useful, and being limited like this lets it be very
fast and nimble.
