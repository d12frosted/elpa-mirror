Org-babel backend that sends source blocks to an existing agent-shell
buffer and captures the response as the block result.  Reuses your
configured agent-shell client rather than requiring a separate AI setup.

Usage:

  #+begin_src agent-shell
  What is the capital of France?
  #+end_src

  #+RESULTS:
  : Paris.

Setup:

  (require 'ob-agent-shell)
  (add-to-list 'org-babel-load-languages '(agent-shell . t))

Header args:

  :buffer BUFFER-NAME  Use a specific agent-shell buffer by name.
                       Takes priority over :session.

  :session NAME        Route all blocks sharing NAME to the same
                       agent-shell buffer.  On first use, binds NAME
                       to the currently active buffer; subsequent
                       blocks reuse it.  Set this file-wide via
                       #+PROPERTY: header-args:agent-shell :session ID
                       to give every block in a file its own shell.

  :timeout N           Override `ob-agent-shell-timeout' for this block.
                       N is a number of seconds.  Useful for long-running
                       prompts (e.g. reading a full PDF) without raising
                       the global default.

  :results raw         Omit the leading ": " prefix on each result line.
