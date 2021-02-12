This package is a client end library to the wonderful music playing daemon by
name mpd. Hence, an obvious prerequisite for this package is mpd itself,
which you can get at http://www.musicpd.org. For those who haven't heard of
mpd, all I can say is that it is definitely worth a try, and is surely
different from the rest. This package is aimed at developers, and though
there are some interactive functions, much of the power of the library lies
away from the user.

This package started off to implement libmpdclient.c, which came with mpd, in
elisp. But as it stands of now, this package is not an exact translation.
Notable amongst the deviations are -

     - This package contains quite a bit of higher level functionality as
     compared with the original. An action or a query needs only a single
     call and the library user can choose to get either the raw response, the
     formatted response, or hook on a callback for each logical token of the
     response. However, dig deeper, and you will find the lower level
     functionality available as well.
     - The error throwing scheme consistent with what is expected of elisp
     programs.
     - Command list mode is transparent in most cases, as wherever
     appropriate, functions taking arguments can accept either a single item
     or a list of it for each argument.
     - Apart from this, command list functionality is limited to actions
     rather than queries, as it is anyway not that easy to parse out the
     individual responses from command-list queries (it is firstly possible
     only from 0.11, which allows for a list_OK to be added at the end of
     response for each command in the list).
     - command_list_ok_begin isn't implemented. It is still possible to
     explicitly use "command_list_(ok)begin\n..\ncommand_list_end" for
     `mpd-execute-command' and get the response tokens for queries. A better
     interface may be available in the future.
     - There is a small interactive interface as well, but this is
     intentionally incomplete. The point is that this exists only to the
     extent of adding an interactive part to the functions, without modifying
     the functions per se.

Most of the functions below require a connection object as an argument, which
you can create by a call to `mpd-conn-new'. The recommended way to use
customization to choose parameters for mpd connections is to use the widget
`mpd-connection'.

As this package caters to developers, it should be helpful to browse the file
in order for atleast the functions and the documentation. The file is well
structured and documented, so go for it. The impatient could do a selective
display to 3 (C-u 3 C-x $) before proceeding.

; Installation:

Put this file somewhere on your load-path. Then, you could use
(require 'libmpdee) whenever the services of this package are needed.

Parameters used for the interactive calls can be customized in the group mpd
Use:
        M-x customize-group mpd
to change the values to your liking.


; History: (See the SVN logs/ChangeLog for the list of all changes)

v2.1
Introducing automatic mode with hooking, for connections.
See `mpd-set-automatic-mode'.

v2.0
The interface has changed since version 1 of this library and there is no
backward compatibility. This change applies to functions which returned
vector whose descriptions were given `*-data' variables. Such functions have
been modified to return property lists, whose keys now describe the values
returned. This should hopefully be a much more scalable representation.
