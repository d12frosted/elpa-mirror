Summarize elfeed articles using an LLM via gptel.

Setup:
  (add-hook 'elfeed-search-mode-hook #'elfeed-ai-mode)

Usage:
  1. In the elfeed search buffer, mark entries with m (unmark with u)
  2. Press S to open the summarization menu
  3. Optionally press g to configure gptel (model, temperature, etc.)
  4. Press s to summarize
  5. Summaries appear asynchronously in the *elfeed-ai* Org buffer
