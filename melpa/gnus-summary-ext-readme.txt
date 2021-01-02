
Bitcoin donations gratefully accepted: 16mhw12vvtzCwQyvvLAqCSBvf8i41CfKhK

This library provides extra commands for filtering and applying process marks to
articles in the gnus summary buffer, some commands for performing actions on MIME
parts in articles, and some general functions for evaluating elisp code in marked articles.

You can apply complex filters for filtering the messages displayed in the *Summary* buffer
using `gnus-summary-ext-limit-filter', or apply the process mark to such articles with
`gnus-summary-ext-uu-mark-filter'.
You can save these filters in `gnus-summary-ext-saved-filters'.

To add new keybindings for these new filter commands add `gnus-summary-ext-hook' to `gnus-summary-mode-hook'.

See the documentation of the individual commands & functions for more
details.
;;
