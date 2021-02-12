Commands defined here operate on frames, windows and buffers and
make it easier and faster to access certain functionality that
is already available using the builtin commands.

 ***** NOTE: The following EMACS PRIMITIVES have been REDEFINED HERE:
 `delete-window' If there is only one window in frame, then
                 delete whole frame using `delete-frame'.

 ***** NOTE: The symbols defined here do not have a proper package
             prefix.

Inspired by Drew Adams' `frame-cmds.el', `misc-cmds.el' and
`find-func+.el'.
