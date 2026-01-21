Emacs frontend for the pi coding agent (https://shittycodingagent.ai/).
Provides a two-window interface for AI-assisted coding: chat history
with rendered markdown, and a separate prompt composition buffer.

Requirements:
  - pi coding agent installed and in PATH

Usage:
  M-x pi           Start a session in current project
  C-u M-x pi       Start a named session

Key Bindings:
  Input buffer:
    C-c C-c        Send prompt (queues as follow-up if busy)
    C-c C-s        Queue steering (interrupts after current tool; busy only)
    C-c C-k        Abort streaming
    C-c C-p        Open menu
    C-c C-r        Resume session
    M-p / M-n      History navigation
    C-r            Search history
    TAB            Path/file completion
    @              File reference (search project files)

  Chat buffer:
    n / p          Navigate messages
    TAB            Toggle tool output
    C-c C-p        Open menu

Editor Features:
  - File reference (@): Type @ to search project files (respects .gitignore)
  - Path completion (Tab): Complete relative paths, ../, ~/, etc.
  - Message queuing: Submit messages while agent is working:
      C-c C-c  queues follow-up (delivered after agent completes)
      C-c C-s  queues steering (interrupts after current tool)

Press C-c C-p for the full transient menu with model selection,
thinking level, session management, and custom commands.

See README.org for more documentation.
