This package provides an interface to instruction-following language models
like GPT-4, Claude 3.5 Sonnet, and Gemini Pro.  It allows you to interact
with these models directly from Emacs using natural language commands.

Key features:
- Multi-provider support (OpenAI, Anthropic, Google)
- Streaming responses with real-time output
- Flexible context modes (all buffers, current buffer, or no context)
- Interactive conversations with follow-up commands
- Command history with persistence
- Named buffers for organizing conversations

To get started:
1. Install required Python packages: pip install openai anthropic google-genai jsonlines
2. Set your API key(s): (setq gpt-openai-key "your-key-here")
3. Start chatting: M-x gpt-chat

Main commands:
- `gpt-chat' - Interactive prompt with context mode selection
- `gpt-chat-all-buffers' - Use all visible buffers as context
- `gpt-chat-current-buffer' - Use current buffer as context
- `gpt-chat-no-context' - Use no buffer context
