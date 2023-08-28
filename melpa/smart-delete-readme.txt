Handle backspace/delete like IntelliJ IDEs.

When `smart-delete-mode' is enabled, do a smart delete, unless:
* Called with an argument
* Inside a string literal
* Have non-spacing characters before/after point (for
backward/forward deletes, respectively)

Deletes region when region is active and delete-active-region
is non-nil.

A smart delete consists of:

When smart deleting backward:
If after indentation level, go back to indentation
If at or before indentation level, delete to end of previous
line

When smart deleting forward:
Delete spaces after point
Smart delete backward at next line

Usage:

(smart-delete-mode 1)

Some ideas taken from https://github.com/itome/smart-backspace
