mu4e-llm provides AI-powered email assistance for mu4e using LLM providers
via the llm.el library.

Features:
- Thread summarization (standard and executive)
- Smart reply drafting with iterative refinement
- Email translation

Quick start:
  (require 'mu4e-llm)
  (mu4e-llm-setup)

Then in mu4e, use C-c a e prefix for AI commands:
  C-c a e s - Summarize thread
  C-c a e r - Generate smart reply
  C-c a e t - Translate message
