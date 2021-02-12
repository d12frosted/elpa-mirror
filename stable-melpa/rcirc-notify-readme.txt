
This code is inspired in part by erc-page-me.el and offers
the same functionality as it, but for rcirc.

* `rcirc-notify-message` contains the message contents for
   the notification

* `rcirc-notify-message-private` contains the message
   contents for a private message notification

* `rcirc-notify-nick-alist` is a list containing the last
   folks who notified you, and what times they did it at

* `rcirc-notify-timeout` controls the number of seconds
   in between notifications from the same nick.

Grow For Windows
Run something like this from eshell before you use rcirc-notify:
/Programme/Growl\ for\ Windows/growlnotify.com /t:IRC \
/ai:http://www.emacswiki.org/pics/static/CarbonEmacsPackageIcon.png \
/a:Emacs /r:IRC /n:IRC foo
