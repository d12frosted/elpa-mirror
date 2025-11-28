When composing an email with mu4e, mu4e-walk allows for moving
around email addresses in the header with just one key stroke:

- Move email address "vertically" between address fields
- Move email address "horizontally" within an address field
- Also works with regions
- Moreover one can "vertically" and "horizontally" switch between email addresses.
- Moreover one can delete an email address at point.

The most important functions and default keybindings are:

| Function                                | Keybinding  |
|-----------------------------------------+-----------------------|
| mu4e-walk-up                            | M-<up>                |
| mu4e-walk-down                          | M-<down>              |
| mu4e-walk-left                          | M-<left>              |
| mu4e-walk-right                         | M-<right>             |
| mu4e-walk-switch-up                     | C-<up>                |
| mu4e-walk-switch-down                   | C-<down>              |
| mu4e-walk-switch-left                   | C-<left>              |
| mu4e-walk-switch-right                  | C-<right>             |
| mu4e-walk-delete-email-address-at-point | M-<delete> M-<delete> |

Installation note: This package depends on mu4e which must be installed
separately from package.el.
