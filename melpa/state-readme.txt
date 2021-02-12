This library allows you to switch back and forth between predefined
workspaces. See the README file for more information.

; Installation:

(require 'state)
(state-global-mode 1)

There is no predefined workspaces to switch to. To switch back and
forth to the *Messages* buffer by pressing C-c s m:

(state-define-state
 message
 :key "m"
 :switch "*Messages*")

See full documentation on https://github.com/thisirs/state#state
