This file contains the code for running Immutant and collecting the
console output.  It contains some utility functions to make it
easier to browse the output.

To use add the following to your init.el
(require 'immutant-server)
and then run
M-x immutant-server-start

History

1.2.1

- Marked the immutant-server-start arg as optional

- Added immutant-server-default-directory to control where Immutant
  starts

1.2.0

- Added additional notice regexes to
  `immutant-server-notice-regexp-alist'. Thanks, tcrawley.

- Added thingatpt require.  Thanks, syohex.

- Added ability to modify server command in `immutant-server-start'
  with C-u prefix.  Thanks, tcrawley.

- Added docs for the 'C-c C-s' binding for `immutant-server-start'

- Tweaked one of the notice regexes so it wouldn't override the
  ERROR face when there is an error while starting Immutant.

1.1.2

- Require ansi-color

1.1.1

- Added highlighting for various specific log messages. Initially,
  these are all about when the server is up or services deployed.
  See `immutant-server-notice-regexp-alist' for details.

- Fixed a bug with the Immutant Stopped message appearing
  off-screen.

- Tweaked faces (removed bold on inherited faces), change info
  color

- Fix bug in error navigation

- Add C-c C-s keybinding to start Immutant

1.0.1

- Fixed some byte compile warnings

- Added an autoload to immutant-server-start

1.0.0

- Initial release
