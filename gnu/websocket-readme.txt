1 Description
═════════════

  This is a elisp library for websocket clients to talk to websocket
  servers, and for websocket servers to accept connections from
  websocket clients. This library is designed to be used by other
  library writers, to write apps that use websockets, and is not useful
  by itself.

  An example of how to use the library is in the
  [websocket-functional-test.el] file.

  This library is compatible with emacs 23 and 24, although only emacs
  24 support secure websockets.


[websocket-functional-test.el]
<https://github.com/ahyatt/emacs-websocket/blob/master/websocket-functional-test.el>


2 Version release checklist
═══════════════════════════

  Each version that is released should be checked with this checklist:

  • ☐ All ert test passing
  • ☐ Functional test passing on emacs 23 and 24
  • ☐ websocket.el byte compiling cleanly.


3 Existing clients:
═══════════════════

  • [Emacs IPython Notebook]
  • [Emacs Realtime Markdown Viewer]
  • [Kite]

  If you are using this module for your own emacs package, please let me
  know by editing this file, adding your project, and sending a pull
  request to this repository.


[Emacs IPython Notebook] <https://github.com/tkf/emacs-ipython-notebook>

[Emacs Realtime Markdown Viewer]
<https://github.com/syohex/emacs-realtime-markdown-viewer>

[Kite] <https://github.com/jscheid/kite>
