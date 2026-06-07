CUI as a minor mode extend Org major mode with "cui block" that
  allows you to interact with the OpenAI-compatible REST APIs.

CUI was inspired by org-ai package of Robert Krahn <https://github.com/rksm/org-ai>

It allows you to:
- Use #+begin_cui..#+end_cui blocks for org-mode
- Call multiple requests from multiple block and buffers in parallel.
- Use tags `@Backtrace` @Bt and Org links to insert target in query.
- Highlighting for major elements.
- Autofilling, hooks, powerful debugging
- Noweb and tangling
- Customization for engineering, there is :chain for sequence of
  calls out-of-the-box.

The Internet connection uses the built-in libraries url.el and url-http.el.

See see https://github.com/Anoncheg1/emacs-cui for the full set
of features and setup instructions.
