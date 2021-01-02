;
This is package makes an Emacs bridge between Kindle (other ereaders
supports could work in theoretically) and Org Mode.
In theatrically, this package should work for non-kindle ereaders too. User can
set device path in variables. But becaused not tested, so I can't guarantee that
package will work correctly. But PR welcome to improve it. I appreciate it.

This packages use a command `ebook-convert' which comes from
[[https://calibre-ebook.com/][Calibre]]. So if you want to use auto convert
functionality, you need to install it manuall.

- It support send Org Mode file: link file to Kindle or other ereaders like Nook.
