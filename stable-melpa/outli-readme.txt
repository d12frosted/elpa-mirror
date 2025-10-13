outli-mode is a simple minor-mode using outline-minor-mode to
support configurable special comment lines as level-aware outline
headings.  As in org-mode, headings can be collapsed, navigated,
moved, etc.  outli styles headings for easy level recognition and
provides a org-mode-like header navigation and editing
capabilities, including "speed keys" which are activated at the
start of headings.

Customize `outli-heading-config' to set the "stem" and "repeat"
character for comment-based headings and to influence how the
headings are styled.  Customize `outli-speed-commands' to alter or
disable speed keys, which work at the beginning of heading lines
only.  Outli inherits heading colors from the `outline-*' faces.
