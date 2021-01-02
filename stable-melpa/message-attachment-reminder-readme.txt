Scans outgoing messages via `message-send-hook' to look for phrases
which indicate that an attachment is expected to be present but for
which no attachment has been inserted.

The phrases to look for can be customized via
`message-attachment-reminder-regexp', whilst the warning message shown
to the user can be changed via
`message-attachment-reminder-warning'.

Finally, by default quoted lines are not checked however this can be
changed by setting `message-attachment-reminder-exclude-quoted' to
`nil'.

;; Setup

(require 'message-attachment-reminder)
