opener.el is a small package that provides the user with the ability to open
files from http-like sources directly inside an Emacs buffer.  This means that
if the URL in question gives string hints to be a plaintext file, that isn't
automatically being rendered into a pleasant representation, like for example
html files are, it will be opened inside an Emacs buffer.

The current main example for this is opening URLs that yield XML or JSON
responses, which are potentially even gzipped (think sitemaps for example).

This package allows one to hook opener into evil.
It defines an :opener ex-state command as well as a remapping of gf (normal
state) to opener.

Full documentation is available as an Info manual.
