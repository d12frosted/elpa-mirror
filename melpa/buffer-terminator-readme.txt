The buffer-terminator package automatically kills buffers to help maintain a
clean and efficient workspace, while also improving Emacs' performance by
reducing the number of open buffers, thereby decreasing the number of active
modes, timers, and other processes associated with those buffers.

Activating `(buffer-terminator-mode)` terminates all buffers that have been
inactive for longer than the duration specified by
`buffer-terminator-inactivity-timeout` (default: 30 minutes). It checks every
`buffer-terminator-interval` (default: 10 minutes) to determine if a buffer
should be terminated.

The following buffers are not terminated by default:
- Special buffers (buffers whose names start with a space, start and end with
  `*`, or whose major mode is derived from `special-mode`).
- Modified file-visiting buffers that have not been saved; the user must save
- them first.
- Buffers currently displayed in any visible window.
- Buffers associated with running processes.

(The default rules above are fully customizable. Users can define specific
rules for keeping or terminating certain buffers by specifying a set of rules
using `buffer-terminator-rules-alist`. These rules can include buffer name
patterns or regular expressions, major-modes, buffer properties, etc.)

Installation from MELPA:
------------------------
(use-package buffer-terminator
  :ensure t
  :custom
  (buffer-terminator-verbose nil)
  :config
  (buffer-terminator-mode 1))

Links:
------
- buffer-terminator.el @GitHub (Frequently Asked Questions, usage...):
  https://github.com/jamescherti/buffer-terminator.el
