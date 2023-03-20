A ChatGPT client for Emacs.

Requirements:
- You need an OpenAI API key. Set the variable `gptel-api-key' to the key or to
  a function of no arguments that returns the key.

- Not required but recommended: Install `markdown-mode'.

Usage:
- M-x gptel: Start a ChatGPT session
- C-u M-x gptel: Start another or multiple independent ChatGPT sessions

- In the GPT session: Press `C-c RET' (control + c, followed by return) to send
  your prompt.
- To jump between prompts, use `C-c C-n' and `C-c C-p'.
