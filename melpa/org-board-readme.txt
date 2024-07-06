
org-board uses `org-attach' and `wget' to provide a bookmarking and
web archival system  directly from an Org file.   Any `wget' switch
can be used  in `org-board', and presets (like user  agents) can be
set for easier  control.  Every snapshot is logged and  saved to an
automatically generated folder, and snapshots for the same link can
be compared using the `ztree' package (optional dependency; `ediff'
used if `zdiff' is not available).  Arbitrary functions can also be
run after an archive, allowing for extensive user customization.

Commands defined here:

  `org-board-archive', `org-board-archive-dry-run',
  `org-board-cancel', `org-board-delete-all', `org-board-diff',
  `org-board-diff3', `org-board-new', `org-board-open',
  `org-board-run-after-archive-function'.

Functions defined here:

  `org-board-expand-regexp-alist', `org-board-extend-default-path',
  `org-board-make-timestamp', `org-board-open-with',
  `org-board-options-handler',
  `org-board-test-after-archive-function',
  `org-board-thing-at-point', `org-board-wget-call',
  `org-board-wget-process-sentinel-function'.

Variables defined here:

  `org-board-after-archive-functions',
  `org-board-agent-header-alist', `org-board-archive-date-format',
  `org-board-default-browser', `org-board-domain-regexp-alist',
  `org-board-log-wget-invocation', `org-board-wget-program',
  `org-board-wget-show-buffer', `org-board-wget-switches',
  `org-board-make-relative'.

Keymap defined here:

  `org-board-keymap'.

Functions advised here:

  `org-thing-at-point', with `org-board-thing-at-point'.
