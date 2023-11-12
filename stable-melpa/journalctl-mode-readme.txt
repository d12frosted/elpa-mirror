This is a major-mode for Emacs to view systemd's journalctl output in Emacs.
The output is split into chunks for performance reasons.
Fontification is provided and may be customized.
Please give feedback on any problems that occur.

Version: 1.1 New features:
Much improved performance.
transient menu
asynchronous process
No pre-run of journalctl to determin number of output lines.

Put journalctl-mode.el in your load-path and add   ( require 'journalctl-mode)  to your .emacs file.
