`pulseaudio-control' controls PulseAudio volumes from Emacs, via `pactl`.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Issues](#issues)
- [License](#license)

## Installation

Install [pulseaudio-control from
MELPA](http://melpa.org/#/pulseaudio-control), or put
`pulseaudio-control.el` in your load-path and do a `(require
'pulseaudio-control)'.

## Usage

Initially, the `pulseaudio-control' keymap is not bound to any
prefix.  You can call the command
`pulseaudio-control-default-keybindings' to use the prefix `C-x /'
to access the `pulseaudio-control' keymap globally; if you wish to
use this prefix by default, add the line:

    (pulseaudio-control-default-keybindings)

to your init file.

The default keybindings in the `pulseaudio-control' keymap are:

* `+` : Increase the volume of the currently-selected sink by
  `pulseaudio-control-volume-step'
  (`pulseaudio-control-increase-sink-volume').

* `=` : Increase the volume of the currently-selected source by
  `pulseaudio-control-volume-step'
  (`pulseaudio-control-increase-source-volume').

* `-` : Decrease the volume of the currently-selected sink by
  `pulseaudio-control-volume-step'
  (`pulseaudio-control-decrease-sink-volume').

* `_` : Decrease the volume of the currently-selected source by
  `pulseaudio-control-volume-step'
  (`pulseaudio-control-decrease-source-volume').

* `v` : Directly specify the volume of the currently-selected sink
  (`pulseaudio-control-set-sink-volume').  The value can be:

  * a percentage, e.g. '10%';
  * in decibels, e.g. '2dB';
  * a linear factor, e.g. '0.9' or '1.1'.

* `V` : Directly specify the volume of the currently-selected source
  (`pulseaudio-control-set-source-volume').  The value can be:

  * a percentage, e.g. '10%';
  * in decibels, e.g. '2dB';
  * a linear factor, e.g. '0.9' or '1.1'.

* `m` : Toggle muting of the currently-selected sink
  (`pulseaudio-control-toggle-current-sink-mute').

* `M` : Toggle muting of the currently-selected source
  (`pulseaudio-control-toggle-current-source-mute').

* `x` : Toggle muting of a sink, specified by index
  (`pulseaudio-control-toggle-sink-mute-by-index').

* `X` : Toggle muting of a source, specified by index
  (`pulseaudio-control-toggle-source-mute-by-index').

* `e` : Toggle muting of a sink, specified by name
  (`pulseaudio-control-toggle-sink-mute-by-name').

* `E` : Toggle muting of a source, specified by name
  (`pulseaudio-control-toggle-source-mute-by-name').

* `i` : Select a sink to be the current sink, specified by index
  (`pulseaudio-control-select-sink-by-index').

* `I` : Select a source to be the current sink, specified by index
  (`pulseaudio-control-select-source-by-index').

* `n` : Select a sink to be the current sink, specified by name
  (`pulseaudio-control-select-sink-by-name').

* `N` : Select a source to be the current source, specified by name
  (`pulseaudio-control-select-source-by-name').

* `d` : Display volume of the currently-selected sink
  (`pulseaudio-control-display-volume').

* `]` : Toggle use of @DEFAULT_SINK@ for volume operations
  (`pulseaudio-control-default-sink-mode').

* `[` : Toggle use of @DEFAULT_SOURCE@ for volume operations
  (`pulseaudio-control-default-source-mode').

Customisation options, including `pulseaudio-control-volume-step',
are available via the `pulseaudio-control' customize-group.

## Issues / bugs

If you discover an issue or bug in `pulseaudio-control' not already noted:

* as a TODO item, or

* in [the project's "Issues" section on
  GitHub](https://github.com/flexibeast/pulseaudio-control/issues),

please create a new issue with as much detail as possible, including:

* which version of Emacs you're running on which operating system, and

* how you installed `pulseaudio-control'.

## License

[GNU General Public License version
3](http://www.gnu.org/licenses/gpl.html), or (at your option) any
later version.
