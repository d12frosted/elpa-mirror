
forge-llm provides LLM integration for Magit's Forge, allowing you to generate
high-quality Pull Request descriptions automatically using an LLM (Language
Learning Model) like OpenAI's GPT models or other compatible providers.

**Important:** This package requires the `forge` package to be installed and
configured. Its primary functionality is designed to work within Forge's
pull request creation buffer (`forge-post-mode`).

Features:
- Automatically detect and use repository PR templates
- Generate PR descriptions based on git diffs between branches
- Insert generated descriptions at point or view them in a separate buffer
- Customize prompt templates and LLM parameters

Usage:

1. Set up an LLM provider by customizing `forge-llm-llm-provider` (this depends
   on the `llm` package, see its documentation for details).

2. Call `forge-llm-setup` to integrate with Forge's PR creation buffers.

3. When creating a PR using Forge (e.g., via `forge-create-pullreq`), you can:
   - Use C-c C-l g to generate a PR description in a separate buffer
   - Use C-c C-l p to generate and insert a PR description at point
   - Use C-c C-l t to insert the PR template at point

Example configuration:

(use-package forge-llm
  :after forge
  :config
  (setq forge-llm-llm-provider
        (llm-openai-make-provider :key "your-api-key"))
  (forge-llm-setup))
