    `desktop+' extends `desktop' by providing more features related to
    sessions persistance.

Centralized directory storing all desktop sessions:

    Instead of relying on Emacs' starting directory to choose the session
    Emacs restarts, two functions are provided to manipulate sessions by
    name.

    `desktop+-create': create a new session and give it a name.

    `desktop+-load': change the current session; the new session to be loaded
         is identified by its name, as given during session creation using
         `desktop-create'.

    The currently active session is identified in the title bar.  You can
    customize `desktop+-frame-title-function' to change the way the active
    session is displayed.

    All sessions managed this way are stored in the directory given by
    `desktop+-base-dir'.

Handling of special buffers:

    Desktop sessions by default save only buffers associated to "real" files.
    Desktop+ extends this by handling also "special buffers", such as those
    in `compilation-mode' or `term-mode', or indirect buffers (aka clones).
