Emacs has *scratch* buffer for temporary elisp scripting.  However, sometimes
you may want to get a temporary buffer with some other specific configuration
to do something immediately.  That is not something difficult to do but
dispersed across various packages and sometimes there is no such support,
which can be really annoying.  Therefore oboe.el be.

The idea of oboe.el is just as simple as following steps:
1. prompt for a buffer configuration to load
2. create a buffer and load selected configuration
3. display it according to configuration

The idea looks like a trivial version of org-capture, but they have different
target.  oboe is designed as a temporary buffer management framework.  It
will track created oboe buffers in queues, assigning each new buffer with a
unique ID.  You can manage all these buffers in a menu.  It also provides a
plist-based framework for creating customized configurations.
