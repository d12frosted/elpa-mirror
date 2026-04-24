
Adds completion-at-point (CAPF) support for Python's \N{UNICODE NAME}
string escape syntax.  Works with company-mode (via company-capf),
corfu, and built-in M-TAB / C-M-i completion.

Usage:
  (require 'python-unicode-escape)
  (add-hook 'python-mode-hook #'python-unicode-escape-mode)

The first completion triggers a one-time Python call to populate the
cache (~140k names, takes ~1-2s).  All subsequent completions are instant.
