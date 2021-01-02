Major mode for editing systemd units.

Similar to `conf-mode' but with enhanced highlighting; e.g. for
specifiers and booleans.  Employs strict regex for whitespace.
Features a facility for browsing documentation: use C-c C-o to open
links to documentation in a unit (cf. systemctl help).

Supports completion of directives and sections in either units or
network configuration.  Both a completer for
`completion-at-point-functions' and a company backend are provided.
The latter can be enabled by adding `company-mode' to
`systemd-mode-hook'.
