Desktop notification integration in Gnus!? Ohh goody!

``gnus-desktop-notify.el`` provides a simple mechanism to notify the user
when new messages are received. For basic usage, to be used in conjunction
with `gnus-daemon', put the following:

(require 'gnus-desktop-notify)
(gnus-desktop-notify-mode)
(gnus-demon-add-scanmail)

into your ``.gnus`` file. The default is to use `alert' if available, which
works on every operating system and allows the user to customize the
notification through Emacs. See https://github.com/jwiegley/alert#for-users
for further info. If not available, the `notifications' library (part of
Emacs >= 24) is used, so no external dependencies are required. With Emacs
<= 23 instead the generic ``notify-send`` program is used, which (in Debian
or Ubuntu) is available in the ``libnotify-bin`` package.

You can also call any program directly by changing the
`gnus-desktop-notify-exec-program' variable, or change the behavior entirely
by setting a different `gnus-desktop-notify-function' function.

By default, all groups are notified when new messages are received. You can
exclude a single group by setting the `group-notify' group parameter to `t'.
You can also selectively monitor groups instead by changing the
`gnus-desktop-notify-groups' variable to `gnus-desktop-notify-explicit' and
then manually selecting which groups to include. Press 'G c' in the group
buffer to customize group parameters interactively.

The behavior of the notification can be tuned by changing the
`gnus-desktop-notify-behavior' variable.

See the `gnus-desktop-notify' customization group for more details.

Feel free to send suggestions and patches to wavexx AT thregr.org
