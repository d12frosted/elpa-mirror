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

Comparing to its forked peer (aidermacs), Aider.el has brought in lots of application-level features and tools to enhance daily programming. These include:
  - AI-assisted agile development methodologies (like TDD, refactoring and legacy code handling based on established software engineering books)
  - Diff extraction and AI code review tools
  - Advanced code / module reading assistant
  - Project software planning discussion capabilities
  - Let aider to fix the errors reported by flycheck
  - Code / repo evolution analysis with git blame and git log
  - Utilities for bootstrapping new files and projects.
  - Organize project with repo specific Aider prompt file
  - Snippets from community and aider use experience and pattern
Besides of that, aider.el focus on simplicity. It has much less configurations (transparent to aider config), simplified menu.
