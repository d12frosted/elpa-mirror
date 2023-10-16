Org-NewTab is a browser extension which sets the org-agenda task you should
be working on as your new tab page. It's comprised of two parts: a browser
extension and an Emacs package. The Emacs package runs a WebSocket server
which the browser extension talks to.

The Emacs side is invoked with `org-newtab-mode'. This starts a WebSocket
server which listens on `org-newtab-ws-port'. The browser extension connects
in and will send an org-agenda match query which is then used by Emacs to
find the top task to work on. On connection, the Emacs side will send in
data for `org-tag-faces' used to color the task background in the browser
extension. The Emacs side will send data over when it's either requested
by the browser extension (when it first connects) or when a task is changed
(clocked in/out, marked as done, etc).
