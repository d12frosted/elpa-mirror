
This code implements a notification (alert) library on top of emacs rcirc IRC client.

This code integrates part of the original sources. It departs from the original in two ways

- alerts are considered as a trigger action; any trigger action executes one script file (or anything else)

- five different types of alerts are considered here, three of them may be disabled

  "message" - someone talks to the user by classical "user_nick: ... " (always enabled)
  "keyword" - keyword detected
  "private" - private message (always enabled)
  "nick"    - given nicks changes status (join, ...)
  "always"  - alert of any message

As long as this code only triggers an action, an example a bash script ('rcirc-alert.sh') is necessary
the alerts. This script will create a notification or whatever the user needs. It accepts four input
arguments, being the first argument the alert type. Refer to the example provided script file for more details.
This scripts provides an example configuration file showing a setup and how to use this library.

Useful variables to customize alerts are described in the *Variables section of this file.

** Messages
** Enables
** Action script
** Lists of alert triggers

These may be used in a per-buffer basis to specify individual needs on given chats (notify anything on twitter channel, alert when
given nick appears online at #emacs, keywords on #archlinux, etc.)

; TODO
