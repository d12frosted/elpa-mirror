Translation framework on Emacs, with high configurability and extensibility.

 - Support multiple translation engines, such as Google, Bing, DeepL...
 - Also support LLMs engines such as ChatGPT, DeepSeek and so on.
 - With variety of output styles, such as Buffer, Overlay, Childframe and so on.
 - With a flexible taker for easy retrieval of translated content and targets.
 - Support multiple paragraphs/parts and multi-language translation.
 - Support different http backends, such as url.el, curl. Async and non-blocking.
 - Support caches, proxy and more.

Notice, it is not limited to just being a translation framework. It can fulfill
any text transformation tasks, such as ChatGPT and more.

Custom it as you need, extend it using your creativity.

You can install it via MELPA or from github. Make sure it is on your `load-path'.

For the most basic use, add the following configuration:

  (require 'go-translate)

  (setq gt-default-translator
       (gt-translator
        :taker (gt-taker :langs '(en zh))
        :engines (list (gt-google-engine) (gt-bing-engine))
        :render (gt-buffer-render)))

Then start your translate with command `gt-translate'.

See README.org for details.
