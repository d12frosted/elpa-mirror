Inspired by Robert Krahn's org-ai package <https://github.com/rksm/org-ai>

OAI extend Org mode with "ai block" that allows you to interact
with the OpenAI-compatible REST APIs.

It allows you to:
- Use #+begin_ai..#+end_ai blocks for org-mode
- Call multiple requests from multiple block and buffers in parallel.
- Use tags `@Backtrace` @Bt and Org links to insert target in query.
- Highlighting for major elements.
- Autofilling, hooks, powerful debugging
- Customization for engineering, there is :chain for sequence of
  calls out-of-the-box.

For the Internet connection used built-in libs: url.el and url-http.el.

See see https://github.com/Anoncheg1/emacs-oai for the full set
of features and setup instructions.
