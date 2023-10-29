gptel is a simple Large Language Model chat client, with support for multiple models/backends.

gptel supports ChatGPT, Azure, and local models using Ollama and GPT4All.

 Features:
 - It’s async and fast, streams responses.
 - Interact with LLMs from anywhere in Emacs (any buffer, shell, minibuffer,
   wherever)
 - LLM responses are in Markdown or Org markup.
 - Supports conversations and multiple independent sessions.
 - Save chats as regular Markdown/Org/Text files and resume them later.
 - You can go back and edit your previous prompts or LLM responses when
   continuing a conversation. These will be fed back to the model.

Requirements for ChatGPT/Azure:

- You need an OpenAI API key. Set the variable `gptel-api-key' to the key or
  to a function of no arguments that returns the key. (It tries to use
  `auth-source' by default)

- For Azure: define a gptel-backend with `gptel-make-azure', which see.

For local models using Ollama or GPT4All:

- The model has to be running on an accessible address (or localhost)
- Define a gptel-backend with `gptel-make-ollama' or `gptel-make-gpt4all',
  which see.

Usage:

gptel can be used in any buffer or in a dedicated chat buffer. The
interaction model is simple: Type in a query and the response will be
inserted below. You can continue the conversation by typing below the
response.

To use this in a dedicated buffer:
- M-x gptel: Start a ChatGPT session
- C-u M-x gptel: Start another session or multiple independent ChatGPT sessions

- In the chat session: Press `C-c RET' (`gptel-send') to send your prompt.
  Use a prefix argument (`C-u C-c RET') to access a menu. In this menu you
  can set chat parameters like the system directives, active backend or
  model, or choose to redirect the input or output elsewhere (such as to the
  kill ring).

- If using `org-mode': You can save this buffer to a file. When opening this
  file, turning on `gptel-mode' will allow resuming the conversation.

To use this in any buffer:

- Select a region of text and call `gptel-send'. Call with a prefix argument
  to access the menu. The contents of the buffer up to (point) are used
  if no region is selected.
- You can select previous prompts and responses to continue the conversation.

Finally, gptel offers a general purpose API for writing LLM ineractions
that suit how you work, see `gptel-request'.
