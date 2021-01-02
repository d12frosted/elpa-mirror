What's the point in an Emacs theme if the rest of Linux looks different?

Just call `theme-magic-from-emacs' and your Emacs theme will be applied
to your entire Linux session. Now all your colors match!

`theme-magic' uses pywal to set its themes. Pywal must be installed
separately. When you log out, the theme will be reset to normal. To restore
your theme, call "wal -R" in a shell. To reload it whenever you log in, add
"pywal -R" to your .xprofile (or whatever file you use to initialise programs
when logging in graphically).

See the documentation of Pywal for more information:
https://github.com/dylanaraps/pywal

Please note that pywal version 1.0.0 or greater is required.
