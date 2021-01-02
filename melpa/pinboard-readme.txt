
pinboard.el provides an Emacs client for pinboard.in.

To get started, visit your password settings page
(https://pinboard.in/settings/password) on Pinboard and get the API token
that's displayed there. Then edit ~/.authinfo and add a line like this:

machine api.pinboard.in password foo:8ar8a5w188l3

Once done, you can M-x pinboard RET and browse your pins. A number of
commands are available when viewing the pin list, press "?" or see the
"Pinboard" menu for more information.

Commands available that aren't part of the pin list, and that you might
want to bind to keys, include:

| Command                | Description                           |
| ---------------------- | ------------------------------------- |
| pinboard               | Open the Pinboard pin list            |
| pinboard-add           | Add a new pin to Pinboard             |
| pinboard-add-for-later | Prompt for a URL and add it for later |
