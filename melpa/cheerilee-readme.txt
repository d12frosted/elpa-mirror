cheerilee.el is a graphical toolkit library for the X Window System,
written entirely in Emacs Lisp.

The library allows the creation of an 'application tree', in which
each element to be displayed is declared, similar to markup languages
such as HTML.
This tree is then appropriately inserted in a structure shared with
the system, so that it can be properly displayed and operated on.

Quick Start:

First thing first, you need to load the library: (require 'cheerilee)

After that, the application needs to connect with the X server,
before doing any operation: (cheerilee-connect)

At this point, a tree can be defined by calling appropriate macros.
These macros begin all with the 'cheerilee-def' prefix, followed
by the element's name.
For example, (cheerilee-defframe ARGS) define a frame with argument ARGS.

A frame is required to have a working application, as that is the window
actually mapped to the screen, containing the other elements.
The 'window' element is a rectangular area with no purpose but to contain
other elements inside, and eventually handle events.

The tree defined this way must then added to the system's tree, by calling
(cheerilee-add-tree TREE), where TREE is your application.

Event handling can be added with funcions whose name begin with
'cheerilee-add-' and ends in '-event'. Anything inside describes
the handled event.

The function `cheerilee-close-absolutely-everything' disconnects Emacs
from the X server, meaning that every application using this library
will be closed.

There is currently a bug in which certain window managers still close the
connection when the application's frame is closed, leaving Emacs without
a socket, but with the variable 'cheerilee-connection' non-nil, breaking
the whole library.

Until that bug is fixed, it's a good idea to call
`cheerilee-process-alive-p' and `cheerilee-close-absolutely-everything'
if the former returns t.
