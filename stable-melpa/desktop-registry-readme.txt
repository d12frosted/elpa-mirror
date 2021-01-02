This module provides functions and a global minor mode that lets
you track a central registry of desktop files.  This is useful when
you use desktop files as project files and want to be able to
easily switch between them.

; Installation

This module is available both on Marmalade and MELPA, so if you
have either of those set-up it should be as easy as `M-x
install-package RET desktop-registry RET'.

; Usage

To start using it you need to have a desktop loaded in Emacs, you
can then use `desktop-registry-add-current-desktop' to register
it.  If you don't have a desktop loaded, you can use
`desktop-registry-add-directory' to add a directory containing an
Emacs desktop.  It is also possible to use
`desktop-registry-auto-register' to have desktops registered
automatically upon saving them.

After some desktops have been registered you can switch between
them by using `desktop-registry-change-desktop'.  This will close
the current desktop (without saving) and open the selected one.

If it happens that you have accumulated quite a few desktops and
you would like to have an overview of them and perform some
management tasks, `desktop-registry-list-desktops' will show a list
of the registered desktops, along with an indicator if they still
exist on the filesystem.

; Configuration

Apart from the functions to add, remove and rename desktops, and
the desktop list, it is also possible to use Emacs' customize
interface to change, remove or add desktops in/from/to the registry
with the `desktop-registry-registry' user option.

There is also the `desktop-registry-list-switch-buffer-function'
user option that lets you choose which function to use to show the
buffer when calling `desktop-registry-list-desktops'.  By default
this is `switch-to-buffer-other-window'.
