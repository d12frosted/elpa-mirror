
This package offers an alternate view to `mu4e' e-mail display.  It shows all
e-mails of a thread in a single view, where each correspondant has their own
face.  Threads can be displayed linearly (in which case e-mails are displayed
in chronological order) or as an Org document where the node tree maps the
thread tree.

* Setup

mu4e 1.0 or above is required.

To fully replace `mu4e-view' with `mu4e-conversation' from any other command
(e.g. `mu4e-headers-next', `helm-mu'), call

  (global-mu4e-conversation-mode)

* Features

Call `mu4e-conversation-toggle-view' (bound to "V" by default) to switch between
linear and tree view.

The last section is writable.

Call `mu4e-conversation-send' ("C-c C-c" by default) to send the message.

When the region is active anywhere in the thread, `mu4e-conversation-cite'
("<return>" by default) will append the selected text as citation to the
message being composed.  With prefix argument, the author name will be
prepended.

Each conversation gets its own buffer.
