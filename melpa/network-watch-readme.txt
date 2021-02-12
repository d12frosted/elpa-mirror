Global minor mode for handling intermitent network access.  It provides
two hooks `network-watch-up-hook' and `network-watch-down-hook' every
`network-watch-time-interval' the network status is checked if
nothing changed since the previous time no hooks are invoked.  If
access to a network is possible then the `network-watch-up-hook' is run.
Conversely when network connectivity is lost the `network-watch-down-hook'
is run.

Install via elpa then enable `network-watch-mode'.  You can also
adapt the `network-watch-update-time-interval' to your liking.

Besides the two hooks the library also provides a `network-watch-active-p'
function which returns not nil when a listed interface is up.

In this example `gmail-notifier' is configured with the help of
network-watch - it is automatically started and stopped when the network
is up or down respectively:

	(require 'network-watch)
	(require 'gmail-notifier)

	(setq gmail-notifier-username "jamiguet")
	(setq gmail-notifier-password ja-password)

     (add-hook 'network-watch-up-hook 'gmail-notifier-start)
	(add-hook 'network-watch-down-hook 'gmail-notifier-stop)
