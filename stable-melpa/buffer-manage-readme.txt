Provides support to manage buffers of any kind.  This is helpful for using
multiple inferior shells, multiple SQL session buffers or any other piped
process that requires multiple buffers.

The library includes support for:

* A major mode and buffer for listing, switching, and organizing multiple
  Emacs buffers.
* Fast switching with customized key bindings through the customize framework.
* Switch between managers providing the same key bindings for buffer entries
  with the same key bindings for creation, switching and managing.
* Create your own trivial implementations in minimal set of Emacs Lisp code.
* Interact with buffer entries and manager as objects with a straight forward
  API.
