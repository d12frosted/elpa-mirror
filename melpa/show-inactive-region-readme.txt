Minor mode to highlight the inactive region (between point and mark).

Example installation:

1. Put this file in Emacs's load-path

2. Add to your init file
(require 'show-inactive-region)
(add-hook 'prog-mode-hook #'show-inactive-region-mode)
