Magnus is a Magit-inspired interface for hands-on management of Claude Code
and Codex agents in Emacs.  Interactive agents retain their native terminal
UIs while Magnus supplies durable identities, shared onboarding, lifecycle
management, attention and health monitoring, and a shared coordination
journal.
Committed work can be sent to a headless reviewer from either provider and
read as a structured, folding Git diff.

Main entry point: M-x magnus
Installation diagnostics: M-x magnus-doctor

Key bindings in magnus buffer:
  RET - Visit instance or review
  c   - Create a Claude Code instance
  k   - Archive instance
  r   - Rename instance
  v   - Request an independent review
  g   - Refresh status
  ?   - Show help menu
