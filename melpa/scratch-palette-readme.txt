Require this script and set a directory to save scratches in.

  (require 'scratch-palette)
  (setq scratch-palette-directory "~/.emacs.d/palette/")

Then the command =M-x scratch-palette-popup= is available. This
command displays the scratch buffer for the file. When called with
region, the region is yanked to the scratch buffer.

You may close note with one of =C-g=, =C-x C-x=, or =C-x C-k=. Its
contents are automatically saved.
