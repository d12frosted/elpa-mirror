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

Configuration:
(add-to-list 'load-path "path/to/oai") ; (optional)
(require 'oai)
(add-hook 'org-mode-hook #'oai-mode) ; oai.el
(setq oai-restapi-con-token "xxx") ; oai-restapi.el (optional)

You will need an OpenAI API key-token.
It can be stored in the format:
 "machine api.openai.com login oai password <your-api-key>"
in your ~/.authinfo.gpg file (or other auth-source) and will be picked up
when the package is loaded.

Keys binded by default:

- In block #+begin_ai..#+end_ai blocks:
    - C-c C-c - to send the text to the OpenAI API and insert a response
    - C-c . - to inspect raw data (and C-u C-c .)
    - C-c C-.  - to see url.el raw HTTP data (working only during request)
    - M-h - mark element in ai block (C-u M-h - mark chat message)
    - C-c C-t - set :max-tokens
- in buffer with oai-mode enabled:
    - C-g - to stop all requsts.

Customization:
M-x customize-group RET oai
M-x customize-group RET oai-faces

Terms:
- chat roles or prefixes - [AI]: [ME:]
- parts or messages - major parts of chat with prefixes of roles


Other packages:
- Modern navigation in major modes https://github.com/Anoncheg1/firstly-search
- Search with Chinese	https://github.com/Anoncheg1/pinyin-isearch
- Ediff no 3-th window	https://github.com/Anoncheg1/ediffnw
- Dired history		https://github.com/Anoncheg1/dired-hist
- Selected window contrast	https://github.com/Anoncheg1/selected-window-contrast
- Copy link to clipboard	https://github.com/Anoncheg1/emacs-org-links
- Solution for "callback hell"	https://github.com/Anoncheg1/emacs-async1
- Restore buffer state	https://github.com/Anoncheg1/emacs-unmodified-buffer1
- outline.el usage		https://github.com/Anoncheg1/emacs-outline-it

Donate:
- BTC (Bitcoin) address: 1CcDWSQ2vgqv5LxZuWaHGW52B9fkT5io25
- USDT (Tether) address: TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN
- TON (Telegram) address: UQC8rjJFCHQkfdp7KmCkTZCb5dGzLFYe2TzsiZpfsnyTFt9D
