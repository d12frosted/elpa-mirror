Provides LSP-mode related commands for consult

The commands are autoloaded so you don't need to require anything to make them
available. Just use M-x and go!

;; Diagnostics
M-x consult-lsp-diagnostics provides a view of all diagnostics in the current
workspace (or all workspaces if passed a prefix argument).

You can use prefixes to filter diagnostics per severity, and
previewing/selecting a candidate will go to it directly.

;; Symbols
M-x consult-lsp-symbols provides a selection/narrowing command to search
and go to any arbitrary symbol in the workspace (or all workspaces if
passed a prefix argument).

You can use prefixes as well to filter candidates per type, and
previewing/selecting a candidate will go to it.

;; File symbols
M-x consult-lsp-file-symbols provides a selection/narrowing command to search
and go to any arbitrary symbol in the selected buffer (like imenu)

;; Contributions
Possible contributions for ameliorations include:
- using a custom format for the propertized candidates
  This should be done with :type 'function custom variables probably.
- checking the properties in LSP to see how diagnostic-sources should be used
- checking the properties in LSP to see how symbol-sources should be used
