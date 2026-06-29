Overview
--------
XELB (X protocol Emacs Lisp Binding) is a pure Elisp implementation of X11
protocol based on the XML description files from XCB project.  It features
an object-oriented API and permits a certain degree of concurrency.  It
should enable you to implement some low-level X11 applications.

How it works
------------
As is well known, X11 is a network-transparent protocol.  All its messages,
including requests, replies, events, errors, etc are transported over
network.  Considering that Emacs is powerful enough to do network
communication, it is also possible to use Emacs to send / receive those X11
messages.  Here we fully exploit the asynchronous feature of network
connections in Emacs, making XELB concurrent in a sense.

X11 protocol is somewhat complicated, especially when extension protocols
are also concerned.  Fortunately, XCB project has managed to describe these
protocols as XML files, which are language-neutral and can be used to
generate language-specific bindings.  In XELB, X messages are represented as
'classes', and their 'methodes' are provided to translate them to / from raw
byte arrays conveniently.

Usage
-----
Interfaces are mainly defined in 'xcb.el'.  Please refer to that file on how
to use them.  Most of other files are either X11 core / extension protocol
libraries (e.g. xcb-randr.el) or utility libraries (e.g. xcb-keysyms.el).
Please check the corresponding files for more details.