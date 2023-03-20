A simple ChatGPT client for Emacs.

Requirements:
- You need an OpenAI API key. Set the variable `gptel-api-key' to the key or to
  a function of no arguments that returns the key.

- Not required but recommended: Install `markdown-mode'.

Usage:
gptel can be used in any buffer or in a dedicated chat buffer.

To use this in a dedicated buffer:
- M-x gptel: Start a ChatGPT session
- C-u M-x gptel: Start another session or multiple independent ChatGPT sessions

- In the chat session: Press `C-c RET' (`gptel-send') to send
  your prompt. Use a prefix argument (`C-u C-c RET') to set chat parameters.

To use this in any buffer:

- Select a region of text and call `gptel-send'. Call with a prefix argument
  to set chat parameters.
- You can select previous prompts and responses to continue the conversation.
