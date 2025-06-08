ob-llm provides integration between Org-mode and Simon Willison's LLM
command-line tool (further referred to simply as `llm'), enabling interaction
with large language models directly from Org documents. If you don't have
`llm' installed or configured, please see https://llm.datasette.io to follow
setup instructions and orient yourself first.

The main idea:

- interface with Simon Willison's `llm' tool via Emacs through Org mode
  - code block header arguments pass through to `llm' as flags, so you can
    specify model, file, website, "continue", conversation id, database, etc.
- execute prompts in Babel code blocks with `C-c C-c'
  - results stream back into #+RESULTS
  - completed response is converted to Org mode syntax or prettified JSON
