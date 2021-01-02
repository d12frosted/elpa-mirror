cc-mode implements hungry deletion for its programming modes.  This
package borrows its implementation in a minor mode, so that hungry
deletion can be used in all modes.

; Installation

To use this mode, put the following in your init.el:
(require 'hungry-delete)

You then need to enable hungry-delete-mode, either in
relevant hooks, with turn-on-hungry-delete-mode, or with
global-hungry-delete-mode.
