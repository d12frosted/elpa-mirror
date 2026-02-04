This package provides a uniform Emacs interface for various AI-assisted software
development CLI tools. Its purpose is to offer a consistent user experience
across different AI backends, providing context-aware code actions, and integrating
seamlessly with AI-driven agile development workflows.

URL: https://github.com/tninja/ai-code-interface.el

Supported AI coding CLIs include:
  - Claude Code
  - Gemini CLI
  - OpenAI Codex
  - GitHub Copilot CLI
  - Opencode
  - Grok CLI
  - Cursor CLI
  - Kiro CLI
  - CodeBuddy Code CLI

Basic configuration example:

(use-package ai-code
  :config
  ;; use codex as backend, other options are 'gemini, 'github-copilot-cli, 'opencode, 'grok, 'claude-code-ide, 'claude-code-el, 'claude-code, 'cursor, 'kiro, 'codebuddy
  (ai-code-set-backend 'codex) ;; set your preferred backend
  (global-set-key (kbd "C-c a") #'ai-code-menu)
  ;; Optional: Enable @ file completion in comments and AI sessions
  (ai-code-prompt-filepath-completion-mode 1)
  ;; Optional: In the AI session buffer (Evil normal state), SPC triggers the prompt entry UI
  (with-eval-after-load 'evil (ai-code-backends-infra-evil-setup))
  (global-auto-revert-mode 1)
  (setq auto-revert-interval 1) ;; set to 1 second for faster update
  )

Key features:
  - Transient-driven Hub (C-c a) for all AI capabilities.
  - One key switching to different AI backend (C-c a s).
  - Context-aware code actions (change code, implement TODOs, explain code, @ completion).
  - Agile development workflows (TDD cycle, refactoring navigator, review helper).
  - Seamless prompt management using Org-mode.
  - AI-assisted bash commands and productivity utilities.
  - Multiple AI coding sessions management.

Many features are ported from aider.el, making it a powerful alternative for
developers who wish to switch between modern AI coding CLIs while keeping
the same interface and agile tools.
