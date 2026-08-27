Autonomous coding-agent harness for gptel-agent.

This file is the package entry point: it defines the global
`gptel-agent-harness-mode' minor mode and wires up the feature
modules, each in its own file:

- gptel-agent-harness-config.el      — user options and prompt files
- gptel-agent-harness-compact.el     — automatic context compaction
- gptel-agent-harness-display.el     — mode-line display, token calibration, context rules
- gptel-agent-harness-supervisor.el  — FSM supervisor, build/plan mode
- gptel-agent-harness-tools.el       — enhanced tools
- gptel-agent-harness-agent.el       — OpenCode-like agent
- gptel-agent-harness-session.el     — session persistence and restore
- gptel-agent-harness-commands.el    — built-in and custom commands
- gptel-agent-harness-fsm.el         — FSM hardening advice
