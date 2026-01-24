This package provides a uniform Emacs interface for various AI-assisted software
development CLI tools. Its purpose is to offer a consistent user experience
across different AI backends while integrating seamlessly with AI-driven
agile development workflows.

URL: https://github.com/tninja/ai-code-interface.el

Supported AI coding CLIs include:
  - Claude Code (claude-code.el)
  - Gemini CLI
  - OpenAI Codex
  - GitHub Copilot CLI
  - Opencode
  - Grok CLI
  - Cursor CLI
  - Kiro CLI

Basic configuration example:

(use-package ai-code
  :config
  ;; use codex as backend, other options are 'gemini, 'github-copilot-cli, 'opencode, 'grok, 'claude-code-ide, 'claude-code, 'cursor, 'kiro
  (ai-code-set-backend 'codex) ;; set your preferred backend
  (global-set-key (kbd "C-c a") #'ai-code-menu)
  (global-auto-revert-mode 1)
  (setq auto-revert-interval 1)) ;; set to 1 second for faster update

Key features:
  - Transient-driven Hub (C-c a) for all AI capabilities.
  - One key switching to different AI backend (C-c a s).
  - Context-aware code actions (change code, implement TODOs, explain code).
  - Agile development workflows (TDD cycle, refactoring navigator, review helper).
  - Seamless prompt management using Org-mode.
  - AI-assisted bash commands and productivity utilities.

Many features are ported from aider.el, making it a powerful alternative for
developers who wish to switch between modern AI coding CLIs while keeping
the same interface and agile tools.
