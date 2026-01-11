This package provides an interface to instruction-following language models
like GPT-5, Claude 4.5, and Gemini 3 Pro.  It allows you to interact
with these models directly from Emacs using natural language commands.

This is the pure Elisp version - no Python dependencies required.

Key features:
- Multi-provider support (OpenAI, Anthropic, Google)
- Streaming responses with real-time output
- Extended thinking mode for Claude models
- Web search integration for Claude models
- Flexible context modes (all buffers, current buffer, or no context)
- Interactive conversations with follow-up commands
- Command history with persistence
- Named buffers for organizing conversations

To get started:
1. Set your API key(s): (setq gpt-anthropic-key "your-key-here")
2. Start chatting: M-x gpt-chat

Main commands:
- `gpt-chat' - Interactive prompt with context mode selection
- `gpt-chat-all-buffers' - Use all visible buffers as context
- `gpt-chat-current-buffer' - Use current buffer as context
- `gpt-chat-no-context' - Use no buffer context
- `gpt-chat-multi-models' - Compare responses from multiple models
- `gpt-edit-current-buffer' - Edit buffer content with GPT
