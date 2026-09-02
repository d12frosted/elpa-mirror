Emacs frontend for the pi coding agent (https://pi.dev).
Provides a two-window interface for AI-assisted coding: chat history
with rendered markdown, and a separate prompt composition buffer.

Requirements:
  - Emacs 29.1 or later (tree-sitter support required)
  - pi coding agent @earendil-works/pi-coding-agent 0.84.2 or later,
    installed and in PATH on the host where Pi runs
  - tree-sitter grammars for markdown and markdown-inline

pi-coding-agent uses `md-ts-mode` for its own chat and input buffers;
loading it does not change global Markdown file associations.

Usage:
  M-x pi-coding-agent                    Start or focus session in current project
  C-u M-x pi-coding-agent                Start a named session
  M-x pi-coding-agent-open-session-file  Open a JSONL session file as live session
  M-x pi-coding-agent-toggle             Hide/show session windows in current frame
  M-x pi-coding-agent-session-browser    Browse sessions (filter, switch)
  M-x pi-coding-agent-tree-browser       Browse conversation tree (navigate, label)

Many users define an alias: (defalias 'pi 'pi-coding-agent)

Key Bindings:
  Input buffer:
    C-c C-c        Send prompt (queues text as follow-up if busy)
    C-c C-a        Attach/replace one prompt image (C-u clears)
    C-c C-s        Queue steering (interrupts after current tool; busy only)
    C-c C-k        Abort current operation
    C-c C-p        Open menu
    C-c C-r        Browse sessions
    M-p / M-n      History navigation
    C-r            Incremental history search (like readline)
    TAB            Path/file completion
    @              File reference (search project files)

  Chat buffer:
    n / p          Navigate messages
    TAB            Toggle completed thinking/tool section or fold turn
    !              Run a Dired-inspired shell command on a strict file target
                   (command + dash-options appends it; otherwise use *)
    RET            Visit strict file target at point (tool content,
                   plain path, or local Markdown label)
    C-c C-k        Abort current operation
    C-c C-n        New session
    C-c C-r        Browse sessions
    C-c C-e        Export HTML
    C-c C-c        Compact context
    C-c C-m        Select model
    C-c C-t        Cycle thinking level
    C-c C-y        Copy last message
    C-c C-p        Open menu

Editor Features:
  - File reference (@): Type @ to search project files (respects .gitignore)
  - Path completion (Tab): Complete relative paths, ../, ~/, etc.
  - Prompt image: Attach one content-sniffed raster image to a direct,
    idle, non-slash prompt; the input header shows its name and size.
  - Message queuing: Submit text messages while agent is working:
      C-c C-c  queues follow-up (delivered after agent completes)
      C-c C-s  queues steering (interrupts after current tool)
    Image-bearing drafts refuse these busy paths and remain intact.

Press C-c C-p for the full transient menu with model selection,
thinking level, completed-thinking controls, session management,
and custom commands.  Its Session r entry opens the disk-backed
session browser, and Context w opens the conversation-tree browser;
press ? in either browser to discover switching/navigation, search,
filters, renaming, and labels.

See README.org for more documentation.
