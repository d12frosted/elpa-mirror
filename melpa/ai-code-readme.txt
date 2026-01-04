This package provides a uniform Emacs interface for various AI-assisted software
development CLI tools. Its purpose is to offer a consistent user experience
across different AI backends while integrating seamlessly with AI-driven
agile development workflows.

URL: https://github.com/tninja/ai-code-interface.el

Supported AI coding CLIs include:
  - Claude Code (claude-code.el)
  - Gemini CLI (gemini-cli.el)
  - OpenAI Codex
  - GitHub Copilot CLI
  - Opencode
  - Grok CLI

Dependency: claude-code.el (https://github.com/stevemolitor/claude-code.el) are
used as infrastructure (eat / vterm integration) for OpenAI Codex,
GitHub Copilot CLI, Opencode, and Grok CLI backends. So it is
required to install claude-code.el when using those backends.

Many features are ported from aider.el, making it a powerful alternative for
developers who wish to switch between modern AI coding CLIs while keeping
the same interface and agile tools.

Basic configuration example:

(use-package ai-code
  :straight (:host github :repo "tninja/ai-code-interface.el")
  :config
  (ai-code-set-backend 'claude-code-ide) ;; set your preferred backend
  (global-set-key (kbd "C-c a") #'ai-code-menu)
  (global-auto-revert-mode 1))

Key features:
  - Transient-driven Hub (C-c a) for all AI capabilities.
  - One key switching to different AI backend (C-c a s).
  - Context-aware code actions (change code, implement TODOs, explain code).
  - Agile development workflows (TDD cycle, refactoring navigator, review helper).
  - Seamless prompt management using Org-mode.
  - AI-assisted bash commands and productivity utilities.
