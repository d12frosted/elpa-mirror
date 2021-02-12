Add following expression in your init file :

  (require 'phi-search)

and bind command "phi-search"

  (global-set-key (kbd "C-s") 'phi-search)
  (global-set-key (kbd "C-r") 'phi-search-backward)

In *phi-search* buffer, following commands are available.

- phi-search-again-or-next (replaces "phi-search")

  Move to the next matching item. If query is blank, use the last
  query.

- phi-search-again-or-previous (replaces "phi-search-backward")

  Similar to phi-search-again-or-next, but move to the previous item.

- [M-v] phi-search-scroll-up

  Scroll the target window up, to check candidates.

- [C-v] phi-search-scroll-down

  Scroll the target window down.

- [C-l] phi-search-recenter

  Recenter the target window.

- [C-w] phi-search-yank-word

  Expand query by yanking one word from the target buffer.

- [RET] phi-search-complete

  Finish searching.

- [C-RET] phi-search-complete-at-beginning

  Finish searching at the beginning of the match.

- [C-c C-c] phi-search-unlimit

  Force update results regardless of "phi-search-limit"

- [C-g] phi-search-abort

  Finish searching, and move back to the original position.

For more details, see "Readme".
