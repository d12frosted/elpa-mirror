
Introduces a margin formatter for Corfu which adds icons. The icons are
configurable, but should be text icons provided by the icons fonts in
`nerd-icons'.

To use, install the package and add the following to your init:

(add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)
