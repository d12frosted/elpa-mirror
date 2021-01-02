
This is a program for testing hand-written HTTP requests. You write
your request in an Emacs buffer (using http-twiddle-mode) and then
press `C-c C-c' each time you want to try sending it to the server.
This way you can interactively debug the requests. To change port or
destination do `C-u C-c C-c'.

The program is particularly intended for the POST-"500 internal
server error"-edit-POST loop of integration with SOAP programs.

The mode is activated by `M-x http-twiddle-mode' or automatically
when opening a filename ending with .http-twiddle.

The request can either be written from scratch or you can paste it
from a snoop/tcpdump and then twiddle from there.

See the documentation for the `http-twiddle-mode' and
`http-twiddle-mode-send' functions below for more details and try
`M-x http-twiddle-mode-demo' for a simple get-started example.

Tested with GNU Emacs 21.4.1 and not tested/ported on XEmacs yet.

Example buffer:

POST / HTTP/1.0
Connection: close
Content-Length: $Content-Length

<The request body goes here>
