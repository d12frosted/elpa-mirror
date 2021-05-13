Excorporate provides Exchange integration for Emacs.

Most Recent Improvements
------------------------

New in Excorporate 0.9.6, released 2021-04-26:

** Fix Emacs < 24.4 incompatibility in time zone support

** Require cl-lib package explicitly

Quick Start
-----------

To create a connection to a web service:

M-x excorporate

Excorporate will prompt for an email address that it will use to
automatically discover settings.  Then it will prompt you for your
credentials two or three times depending on the server configuration.

You should see a message indicating that the connection is ready
either in the minibuffer or in the *Messages* buffer.

Finally, run M-x calendar, and press 'e' to show today's meetings.

If autodiscovery fails, customize `excorporate-configuration' to skip
autodiscovery.

For further information including connection troubleshooting, see the
Excorporate Info node at C-h i d m Excorporate.
