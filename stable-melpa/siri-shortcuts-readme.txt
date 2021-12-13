This package allows you to interact with Siri Shortcuts in macOS.
It includes both user-facing interactive commands, as well as a
generic API wrapper around the Shortcuts URL scheme API.
More info in the official Apple docs: https://support.apple.com/en-gb/guide/shortcuts-mac/apd621a1ad7a/mac

;; Installation

;;; MELPA

If you installed from MELPA, you're done.

;;; Manual

Make sure you are running at least macOS Monterey!

Put this file in your load-path, and put this in your init
file:

(require 'siri-shortcuts)

;; Usage

Run one of these commands:

`siri-shortcuts-run': Run a Siri Shortcut.

;; Tips

+ You can customize settings in the `siri-shortcuts' group.
