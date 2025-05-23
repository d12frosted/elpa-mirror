Boost your programming efficiency! This package + Aider (https://aider.chat/)
brings AI-assisted programming capabilities *inside* Emacs! Aider works seamlessly
with both *new* and *existing* codebases in your local Git repo,
using AI models (Claude, ChatGPT, Gemini, even local ones!) to assist you. It
can suggest improvements, squash bugs, or even write whole new
sections of code. Enhance your coding with AI without ever leaving
your Emacs comfort zone. The package also supports AI-assisted Agile
development workflows and AI-assisted code reading to help you understand
complex codebases faster and more thoroughly.

To use aider.el, you need to install the Aider command line tool: https://aider.chat/#getting-started
After that, configure it with (use sonnet as example):

(use-package aider
  :config
  ;; For latest claude sonnet model
  (setq aider-args '("--model" "sonnet" "--no-auto-accept-architect"))
  (setenv "ANTHROPIC_API_KEY" anthropic-api-key)
  (global-set-key (kbd "C-c a") 'aider-transient-menu))

For more details, see https://github.com/tninja/aider.el

Comparison of aider.el to aidermacs (a fork version of aider.el):
- More Focus on build prompts using your code (buffer/selection).
- Less configurations (transparent to aider config), simplified menu.
- Reuse prompts easily, fuzzy search with helm.
- Agile development and Code reading tools from classic books.
- Diff extract and code review tools
- Organize project with repo specific Aider prompt file, with snippets from community.
- More Focus on stability and long term maintainability (e.g. pure comint, do not parse aider output)
