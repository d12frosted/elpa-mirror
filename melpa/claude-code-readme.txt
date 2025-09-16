This package provides integration with Claude Code CLI tool within Emacs.
It allows you to run Claude Code sessions in vterm buffers with project isolation.

Main features:
- Project-specific Claude Code sessions
- Transient menu for common operations
- File path completion with @ syntax
- Custom commands support
- MCP server integration with real-time event notifications

Optional dependencies:
- lsp-mode (9.0.0): For LSP diagnostic fixing and MCP tools
- websocket (1.15): For MCP server WebSocket communication

These are only required if you want to use MCP features or LSP diagnostics.

Quick start:

  (require 'claude-code)
  (global-set-key (kbd "C-c c") 'claude-code-transient)

Basic usage:

  M-x claude-code-run      ; Start Claude Code session
  C-c c                          ; Open transient menu
  C-u M-x claude-code-run  ; Start with options (model, resume, etc.)

In prompt buffer (.claude-code.prompt.md):
  @ TAB                          ; Complete file paths
  C-c C-s                        ; Send section at point
  C-c C-b                        ; Send entire buffer

MCP integration (optional):

  M-x claude-code-install-mcp-server  ; Install MCP server
  ;; Then configure Claude Code as instructed

For more information, see README.md
