Inspired by Robert Krahn's org-ai package <https://github.com/rksm/org-ai>

OAI extend Org mode with "ai block" that allows you to interact
with the OpenAI-compatible REST APIs.  Fork of "org-ai".

It allows you to:
- Use #+begin_ai..#+end_ai blocks for org-mode
- Call multiple requests from multiple block and buffers in parallel.
- Use tags `@Backtrace` @Bt and Org links to insert target in query.
- Highlighting for major elements.
- Autofilling, hooks, powerful debugging
- Customization for engineering, there is :chain for sequence of
  calls out-of-the-box.

For the Internet connection used built-in libs: url.el and url-http.el.

See see https://github.com/Anoncheg1/oai for the full set
of features and setup instructions.

Configuration:
(add-to-list 'load-path "path/to/oai")
(require 'oai)
(add-hook 'org-mode-hook #'oai-mode) ; oai.el
(setq oai-restapi-con-token "xxx") ; oai-restapi.el
(setopt help-window-select t) ; for `oai-expand-block' function (optional)

You will need an OpenAI API key.  It can be stored in the format
  machine api.openai.com login oai password <your-api-key>
in your ~/.authinfo.gpg file (or other auth-source) and will be picked up
when the package is loaded.

Available commands (TODO to refine):

- Inside org-mode / #+begin_ai..#+end_ai blocks:
    - C-c C-c to send the text to the OpenAI API and insert a response (org-ai.el)
    - Press C-c <backspace> (oai-kill-region-at-point) to remove the chat
      part under point.  (oai-block.el)
    - oai-mark-region-at-point will mark the region at point.  (oai-block.el)
    - oai-mark-last-region will mark the last chat part.  (oai-block.el)

Architecture:
  (raw info) Interface -> (structured Org info + raw Org body) Agent ->
  API to LLM + Callback (may be part of Agent or API)

Callback write result to ORG

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

Touch: Pain, water and warm.
