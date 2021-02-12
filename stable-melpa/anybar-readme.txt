AnyBar is an application that puts an indicator in the menubar in
OS X. This package lets you interact with that indicator from
Emacs. See: https://github.com/tonsky/AnyBar

Basic usage:

  (require 'anybar)

Start AnyBar:

  (anybar-start)

Set indicator to a color:

  (anybar-set "red")

Quit AnyBar:

  (anybar-quit)

Those functions also take an optional argument to specify a port
number, if you want to run multiple instances or use a different
port than AnyBar's default, 1738.

`anybar-set' will complain if you try to set the indicator to an
invalid style, which is anything outside of the default styles (see
`anybar-styles') or any custom images set in "~/.AnyBar". To
refresh the list of images anybar.el knows about, call
`anybar-images-reset'.

These functions may be called interactively.

If you have installed AnyBar to a location other than
/Applications/AnyBar.app, you'll need to customize
`anybar-executable-location' so that `anybar-start' may succeed.

Enjoy!
