This package provides utilities and macros to redirect Emacs package files
to XDG Base Directory specification paths (~/.local/share, ~/.cache, etc.).

Usage:

Obtain paths in XDG directories:
  (xdg-redirect-locate-cache-file "pkg-name/cache")

Redirect variable values to XDG paths:
  (xdg-redirect-to-emacs-data some-package-data-file)
