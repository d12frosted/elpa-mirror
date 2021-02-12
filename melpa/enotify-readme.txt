Enotify provides some sort of system tray for Emacs.

It is born as a vehicle for TDD notifications, as the writer does
not like annoying popups floating around his tiled workspace.

An application can connect to enotify and send a notification
message, that will discreetly appear in the Emacs mode-line.

The source code is available at https://github.com/laynor/enotify

INSTALLATION
------------

Get the code, add the enotify directory to your Emacs load-path and require enotify:

    (add-to-list 'load-path "path/to/enotify")
    (require 'enotify)
    (enotify-minor-mode t)

If you customized the port number related variables (namely
`enotify-port', `enotify-use-next-available-port',
`enotify-fallback-ports'), ensure that the form

    (enotify-minor-mode t)

gets evaluated AFTER your customizations, or else your changes
won't affect enotify's startup.

USAGE
-----

Enotify uses the TCP port 5000 by default. You can customize
`enotify-default-port' if you want.  The variable
`enotify-use-next-available-port' contains a list of ports to be used
as a fallback when binding `enotify-default-port' fails.

It is also possible to instruct enotify to try increasing port numbers
(starting from `enotify-default-port' or the last port specified in
`enotify-fallback-ports' if this s available) for a fixed number of
times or indefinately until port 65535.  This is done throug the
custom variable `enotify-use-next-available-port'.

The command `enotify-port' displays what port enotify is currently
running on in the message area.

Messages are sent as strings and have this format:

    "|<message size>|<message body>"


Message bodies have the form of a keyword argument list, like

	(:register "MySlotID")

Example Message Sent through the network: "|22|(:register \"MySlotID\")"

The message size is intended as the length in characters of the message body.

Enotify slots
.............

An application that wants to send notifications should register a
`slot', - the equivalent of an icon in a system tray - before
sending any notification message.

The message used to register a slot has this form:

	(:register <slot-name> :handler-fn <message-data-processing-funcion>)

The function passed as :handler-fn is of the form
	(handler-fn slot-id data)
The purpose of the :handler-fn parameter will be clarified in the
following section.

Notifications
.............

The message used to send a notification has the form

	(:id <slot-name>
	 :notification (:text <slot text>
	                :face <slot face>
			:help <tooltip text>
			:mouse-1 <mouse-1 handler>)
	 :data <additional-data>)

- data: it will be passed to the handler function specified in the
        slot registration message
- text: the text to be displayed in the notification area
- face: the face used to display the text in the notification area
- help: tooltip text on mouse-over
- mouse-1: an (iteractive "e") handler function of the form

        (m1-handler event)

     that will be called when the user presses the left mouse button
     on the notification text.
     Inside the handler function it's possible to retrieve the slot id with
        (enotify-event->slot-id event)

esend.sh
--------
The esend.sh script can be found in Enotify's git repository.
It's a small shell script that will send a message to enotify,
automatically calculating the message length.
It can be used to send simple notifications to emacs from shell scripts,
and provides a simple example of how enotify can be used.
