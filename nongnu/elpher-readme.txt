Elpher
======

Elpher aims to provide a full-featured combination gopher and gemini
client for GNU Emacs.

It supports:
- intuitive keyboard and mouse-driven browsing,
- out-of-the-box compatibility with evil-mode,
- clickable web and gopher links **in plain text**,
- caching of visited sites,
- pleasant and configurable visualization of gopher directories and
  gemini pages,
- direct visualisation of image files,
- jumping directly to links by name (with autocompletion),
- a simple bookmark management system,
- gopher connections using TLS encryption,
- the Finger protocol.

The official home of elpher is gopher://thelambdalab.xyz/1/projects/elpher/.
Please visit that page for development news and to leave feedback.

Elpher is under active development.
Any suggestions for improvements are welcome!

Installation
------------

Elpher is available on the non-GNU ELPA package archive.  If you are
using Emacs 28 or later, this archive should be available on your system
by default.  For Emacs 27, you'll need to follow the instructions at
https://elpa.nongnu.org to make the archive accessible.

Alternatively, Elpher is available from MELPA (https://melpa.org).  If
you have never installed packages from this repository before, you'll
need to follow the instructions at https://melpa.org/#/getting-started.

Once one of these package archives is installed, enter the following to
install Elpher:

    M-x package-install RET elpher RET

To uninstall, use

    M-x package-delete RET elpher RET

Quick Start
-----------

Once installed, use "M-x elpher" to launch the browser.  This will
open a start page which documents the main key bindings and provides
some links to help kick start your exploration of gopher space and
gemini space.

From here you can move point between links (which may be menu items or
inline URLs in text files) by using TAB and Shift-TAB,
as in Info.  You can also jump directly to a menu item using "m", or
use the standard Emacs or Evil motion and search commands to find your
way around.  To open a link, press enter.  (Where a mouse is
available, Clicking on a link with the mouse cursor has the same
effect.)

To return to the page you just followed the link from, press "u".

Elpher caches (for the duration of an Emacs session) both page
contents and the position of point on each of the pages (gopher menus,
gemini pages, query results, or text pages) you visit, restoring these
when you next visit the same page.  Thus, pressing "u" displays the
previous page in exactly the same state as when you left, meaning that
you can quickly and visually explore the different documents in a menu
without having to wait for anything to reload.

Of course, sometimes you'll _want_ to reload the current page
rather than stick with the cached version.  To do this use "R".
(This is particularly useful for search query results, where this
allows you to perform a different search.)

To customize the various faces Elpher uses, the start page
and a few other odds and ends, use the following:

    M-x customize-group RET elpher RET

Full Documentation
------------------

The full documentation for Elpher can be found in the Info manual,
which should become automatically available if you install Elpher
using "M-x package-install".  To access it, select it from the root
Info directory which can be displayed using "C-h i".

Contributors
------------

Elpher was originally written and is currently maintained by Tim Vaughan
<plugd@thelambdalab.xyz>.  Significant improvements and
maintenance have also been contributed by and with the help of Alex
Schroeder <alex@gnu.org>.  In addition, the following people have
all generously provided assistance and/or patches over the years:

* Jens Östlund <jostlund@gmail.com>
* F. Jason Park <jp@neverwas.me>
* Christopher Brannon <chris@the-brannons.com>
* Omar Polo <op@omarpolo.com>
* Noodles! <nnoodle@chiru.no>
* Abhiseck Paira <abhiseckpaira@disroot.org>
* Zhiwei Chen <chenzhiwei03@kuaishou.com>
* condy0919 <condy0919@gmail.com>
* Alexis <flexibeast@gmail.com>
* Étienne Deparis <etienne@depar.is>
* Simon Nicolussi <sinic@sinic.name>
* Michel Alexandre Salim <michel@michel-slm.name>
* Koushk Roy <kroy@twilio.com>
* Vee <vee@vnsf.xyz>
* Simon South <simon@simonsouth.net>
* Daniel Semyonov <daniel@dsemy.com>
* Bradley Thornton <bradley@northtech.us>

License
-------

Elpher is free software and is distributed under the terms of version
3 the GNU General Public License, which can be found in the file named
COPYING.
