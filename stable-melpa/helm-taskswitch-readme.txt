`helm-taskswitch' provides an X window and buffer switching with helm.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Issues](#issues)
- [License](#license)
- [TODOs](#TODOs)

## Installation

Install wmctrl and helm.

## Usage

To activate use `M-x helm-task-switcher'.

## Issues / bugs

If you discover an issue or bug in `helm-taskswitch' not already noted:

* as a TODO item, or

please create a new issue with as much detail as possible, including:

* which version of Emacs you're running on which operating system, and

* how you installed `helm-task-switcher', wmctrl and helm.

## TODOs

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

## License

[GNU General Public License version 3]
(http://www.gnu.org/licenses/gpl.html), or (at your option) any
later version;; Code from https://github.com/flexibeast/ewmctrl is
used under GNU 3.
