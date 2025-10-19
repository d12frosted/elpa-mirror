This package enhances eldoc' by displaying documentation in a child frame
when the mouse hovers over a symbol in eglot'-managed buffers.  It integrates
with posframe' for popup documentation and provides a debounced mouse hover
mechanism to avoid spamming the LSP server.  Enable it in prog-mode' buffers
to show documentation for the symbol under the mouse cursor.

To use, ensure posframe is installed, then add:
(require 'eldoc-mouse)
to your Emacs configuration.
