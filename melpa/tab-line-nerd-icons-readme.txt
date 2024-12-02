This package applies icons from nerd-icons to to tab-line tabs.

The minor mode `tab-line-nerd-icons-global-mode' adds an :around advice
to the default function `tab-line-tab-name-format-default' for
tab-name-formatting.  If you use a custom function for tab-name generation,
you need to add the advice manually.

This should work in GUI mode and terminal, as long as `nerd-icons' is
properly installed.
