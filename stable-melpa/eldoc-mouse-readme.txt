This package enhances eldoc' by displaying documentation in a child frame
when the mouse hovers over a symbol.  It integrates with posframe' for popup
documentation. Enable it in buffers that you want to show documentation using
eldoc for the symbol under the mouse cursor.

To use, ensure posframe is installed, then add:
(require 'eldoc-mouse)
to your Emacs configuration.
