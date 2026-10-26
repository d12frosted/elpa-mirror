elark provides an Emacs interface to the Lark/Feishu platform by
wrapping the lark-cli command-line tool.  It covers 11 business
domains including Calendar, Messenger, Docs, Drive, Base, Sheets,
Tasks, Mail, Contacts, Wiki, and Meetings.

The package uses transient menus for command dispatch.
All CLI interactions are async by default to keep Emacs responsive.

Quick start:
  M-x elark-dispatch

Key bindings:
  elark does not bind any global keys on load.  To get the
  `elark-prefix-map' commands under a prefix key, add this to your
  init file:

    (elark-setup-prefix-key)          ; binds C-c l
    (elark-setup-prefix-key "C-c L")  ; or any other prefix

  after which `C-c l l' opens the main menu.

Prerequisites:
  - lark-cli installed and on PATH (https://github.com/larksuite/cli)
  - Emacs 29.1+

Dependencies:
  - org-lark (https://github.com/bbw9n/org-lark) — Org rendering and
    export of fetched documents.
  - shell-maker (https://github.com/xenodium/shell-maker) — the AI
    shell interface, including markdown-overlays rendering.
