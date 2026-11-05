`helm-taskswitch' switches between desktop windows (X11, or KDE
Plasma on Wayland), browser tabs and Emacs buffers with helm.

Installation:

Install wmctrl and helm.  On KDE Plasma under Wayland, wmctrl only
sees XWayland windows, so set `helm-taskswitch-backend' to `kwin'
(the default when XDG_SESSION_TYPE is wayland) to list windows
through KWin's D-Bus interface instead.

Browser tabs: the extension in browser-extension/ sends every tab to
Emacs.  Install websocket.el, run M-x helm-taskswitch-browser-install
and follow its steps.  Tabs then show in their own section, most
recently used first, with actions to switch to, close, reload,
duplicate or mute them, or copy their URL.  Emacs starts listening
for the extension the first time you run `helm-taskswitch'.

Usage:

To activate use `M-x helm-taskswitch'.

Issues / bugs:

If you discover an issue or bug in `helm-taskswitch' not already noted:

* as a TODO item, or

please create a new issue with as much detail as possible, including:

* which version of Emacs you're running on which operating system, and

* how you installed `helm-taskswitch', wmctrl and helm.

TODOs:

* handle desktops: Switch to WM desktop withEmacs, bring Emacs to fore on
activating, In most cases this already works.

* Track or get with focus history and use it to order candidates.
There is a start on this commented out at the bottom.  The current
order is arbitrary.

Interesting blog post about alt-tab, suggests Markov model
http://www.azarask.in/blog/post/solving-the-alt-tab-problem/
Ideas from that: other hot key for "go back to most recent window"

* Dedup WMCLASS
WMCLASS is often program.Program, transform theses to just Program

* Strip WMCLASS from end of title
Title often ends with WMCLASS or something like that.  Try to strip these off.

License:

GNU General Public License version 3
(http://www.gnu.org/licenses/gpl.html), or (at your option) any
later version.  Code from https://github.com/flexibeast/ewmctrl is
used under GNU 3.
