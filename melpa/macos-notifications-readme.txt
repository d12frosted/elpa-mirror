Posts macOS notifications from inside the Emacs process through a
dynamic module and delivers clicks on them back to Lisp.  The API
mirrors `notifications-notify' where macOS allows.

Requires a GUI Emacs.app (NS build) running from an app bundle that
LaunchServices knows about.
