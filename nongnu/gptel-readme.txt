gptel is a simple Large Language Model chat client, with support for multiple
models and backends.

It works in the spirit of Emacs, available at any time and in any buffer.

gptel supports

- The services ChatGPT, Azure, Gemini, Anthropic AI, Anyscale, Together.ai,
  Perplexity, Anyscale, OpenRouter, Groq, PrivateGPT, DeepSeek, Cerebras,
  Github Models, xAI and Kagi (FastGPT & Summarizer)
- Local models via Ollama, Llama.cpp, Llamafiles or GPT4All

 Additionally, any LLM service (local or remote) that provides an
 OpenAI-compatible API is supported.

Features:
- It’s async and fast, streams responses.
- Interact with LLMs from anywhere in Emacs (any buffer, shell, minibuffer,
  wherever)
- LLM responses are in Markdown or Org markup.
- Supports conversations and multiple independent sessions.
- Supports multi-modal models (send images, documents).
- Save chats as regular Markdown/Org/Text files and resume them later.
- You can go back and edit your previous prompts or LLM responses when
  continuing a conversation.  These will be fed back to the model.
- Redirect prompts and responses easily
- Rewrite, refactor or fill in regions in buffers
- Write your own commands for custom tasks with a simple API.

Requirements for ChatGPT, Azure, Gemini or Kagi:

- You need an appropriate API key.  Set the variable `gptel-api-key' to the
  key or to a function of no arguments that returns the key.  (It tries to
  use `auth-source' by default)

  ChatGPT is configured out of the box.  For the other sources:

- For Azure: define a gptel-backend with `gptel-make-azure', which see.
- For Gemini: define a gptel-backend with `gptel-make-gemini', which see.
- For Anthropic (Claude): define a gptel-backend with `gptel-make-anthropic',
  which see
- For Together.ai, Anyscale, Perplexity, Groq, OpenRouter, DeepSeek, Cerebras or
  Github Models: define a gptel-backend with `gptel-make-openai', which see.
- For PrivateGPT: define a backend with `gptel-make-privategpt', which see.
- For Kagi: define a gptel-backend with `gptel-make-kagi', which see.

For local models using Ollama, Llama.cpp or GPT4All:

- The model has to be running on an accessible address (or localhost)
- Define a gptel-backend with `gptel-make-ollama' or `gptel-make-gpt4all',
  which see.
- Llama.cpp or Llamafiles: Define a gptel-backend with `gptel-make-openai',

Consult the package README for examples and more help with configuring
backends.

Usage:

gptel can be used in any buffer or in a dedicated chat buffer.  The
interaction model is simple: Type in a query and the response will be
inserted below.  You can continue the conversation by typing below the
response.

To use this in any buffer:

- Call `gptel-send' to send the buffer's text up to the cursor.  Select a
  region to send only the region.

- You can select previous prompts and responses to continue the conversation.

- Call `gptel-send' with a prefix argument to access a menu where you can set
  your backend, model and other parameters, or to redirect the
  prompt/response.

To use this in a dedicated buffer:

- M-x gptel: Start a chat session

- In the chat session: Press `C-c RET' (`gptel-send') to send your prompt.
  Use a prefix argument (`C-u C-c RET') to access a menu.  In this menu you
  can set chat parameters like the system directives, active backend or
  model, or choose to redirect the input or output elsewhere (such as to the
  kill ring or the echo area).

- You can save this buffer to a file.  When opening this file, turn on
  `gptel-mode' before editing it to restore the conversation state and
  continue chatting.

- To include media files with your request, you can add them to the context
  (described next), or include them as links in Org or Markdown mode chat
  buffers.  Sending media is disabled by default, you can turn it on globally
  via `gptel-track-media', or locally in a chat buffer via the header line.

Include more context with requests:

If you want to provide the LLM with more context, you can add arbitrary
regions, buffers or files to the query with `gptel-add'.  To add text or
media files, call `gptel-add' in Dired or use the dedicated `gptel-add-file'.

You can also add context from gptel's menu instead (gptel-send with a prefix
arg), as well as examine or modify context.

When context is available, gptel will include it with each LLM query.

Rewrite/refactor interface

In any buffer: with a region selected, you can rewrite prose, refactor code
or fill in the region.  This is accessible via `gptel-rewrite', and also from
the `gptel-send' menu.

gptel in Org mode:

gptel offers a few extra conveniences in Org mode.
- You can limit the conversation context to an Org heading with
  `gptel-org-set-topic'.
  
- You can have branching conversations in Org mode, where each hierarchical
  outline path through the document is a separate conversation branch.
  See the variable `gptel-org-branching-context'.
  
- You can declare the gptel model, backend, temperature, system message and
  other parameters as Org properties with the command
  `gptel-org-set-properties'.  gptel queries under the corresponding heading
  will always use these settings, allowing you to create mostly reproducible
  LLM chat notebooks.

Finally, gptel offers a general purpose API for writing LLM ineractions
that suit your workflow, see `gptel-request'.