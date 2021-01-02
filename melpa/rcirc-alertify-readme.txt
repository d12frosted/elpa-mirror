This is a notification system for rcirc that uses jwiegley's
`alert' for sending notifications transparently across platforms.
It was born out of the frustrations caused by the rcirc-notify.el
non-maintenance plus the need of tight integration with rcirc
existing mechanisms such as `rcirc-keywords' and
`rcirc-ignore-list'.

Three types of notifications are provided: keywords, nickname
mentions and private messages.  Each have a severity setting called
`rcirc-alertify-keywords-severity' `rcirc-alertify-me-severity' and
`rcirc-alertify-privmsg-severity' respectively.

Event flooding is prevented with the
`rcirc-alertify-nickname-timeout' variable which is the time in
seconds for which notifications will be ignored in case same events
are happening for a given user.

If keywords notifications are not desired, they can be easily
deactivated by toggling `rcirc-alertify-keywords-p'.

Finally, if you are a new user of alert.el, you might need to set
your preferred notifier, here is an example config for libnotify:

(setq alert-default-style 'libnotify)

; Installation:

The recommended installation method is using `package-install'.
After that's done, just add this to your .emacs:

(rcirc-alertify-enable)

If you go the hard way, you need a copy of alert.el and add both
files to your `load-path' and require rcirc-alertify.
