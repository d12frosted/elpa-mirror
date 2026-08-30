magent.el is an Emacs Lisp AI coding agent built on gptel.
It provides intelligent code assistance by integrating with LLMs
via gptel's multi-provider backend system.

Features:
- LLM integration via gptel (Anthropic, OpenAI, Ollama, Gemini, etc.)
- File operations (read, write, edit, grep, glob)
- Shell command execution
- Streaming responses
- Session management with conversation history
- agent-shell frontend through an in-process ACP adapter
- Agent system with specialized agents and permission control

Agent System:
- Built-in agents: build (default), plan, explore, general, compaction,
  title, summary
- Permission-based tool access control per agent
- Custom agent support via .magent/agent/*.md files
- Agent selection per session

Configuration:
LLM provider, model, and API key are managed by gptel.
Magent-specific settings are in the `magent' customize group.

  M-x customize-group RET magent RET

Usage:
  M-x magent-start                    - Start the Magent frontend
  M-x agent-shell                     - Select a registered agent backend

Once inside Magent, use agent-shell's native commands and slash menu for
prompt submission, region/context transfer, Actions, skills, and interrupts.

Setup:
1. Configure gptel with your provider and API key:
   (setq gptel-backend
         (gptel-make-anthropic
          "Claude" :key 'gptel-api-key-from-auth-source))
   or set the ANTHROPIC_API_KEY / OPENAI_API_KEY environment variable.
