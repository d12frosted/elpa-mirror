                             ━━━━━━━━━━━━━━
                              EMACS-HERMES
                             ━━━━━━━━━━━━━━


An Emacs front-end for Hermes Agent, driven over the dashboard/TUI
gateway.

⁃ `M-x hermes' dashboard with `keymap-popup' actions
⁃ ERC/emacs-jabber-style chat buffer with streaming replies
⁃ Slash commands, approvals, clarify/sudo/secret prompts, interrupts,
  and steering
⁃ Markdown-rendered replies; diffs open as `[View Diff]' in `diff-mode'
⁃ *Kanban*, sessions, profiles, MCP, cron, inventory, and rollback
   browsers
⁃ Configurable desktop notifications with click-to-open actions
⁃ Provider onboarding (API keys) from Emacs
⁃ /Optional/ local eval endpoint (`hermes-exec') for the Hermes Emacs
  MCP bridge


1 Installation
══════════════

1.1 use-package
───────────────

  ┌────
  │ (use-package hermes
  │   :vc (:url "https://git.thanosapollo.org/emacs-hermes" :lisp-dir "lisp")
  │   :custom (hermes-dashboard-transport-url "http://127.0.0.1:9119"))
  └────


2 Usage
═══════

  `M-x hermes' opens the dashboard and `M-x hermes-chat' opens a chat
  buffer:
  • `RET' to send.
  • `/' for slash commands.
  • `C-c C-o' for the actions menu.
  • `M-x hermes-close' closes local connections and Hermes buffers for
    restart.

  Point `hermes-dashboard-transport-url' at your running dashboard:

  ┌────
  │ hermes dashboard --no-open --tui --host 127.0.0.1 --port 9119
  └────

  Desktop notifications default to completed chat replies, terminal chat
  errors, input requests, background-task results, and Kanban states
  that need attention.  Cron failures use the same policy when cron
  failure monitoring is enabled.  They are suppressed when the target
  buffer is already visible on the focused frame. Customize the event
  set, or set it to `nil' to disable notifications:

  ┌────
  │ (setq hermes-notifications-events
  │       '(chat-reply chat-error prompt background
  │         kanban-attention cron-failure kanban-done))
  └────
