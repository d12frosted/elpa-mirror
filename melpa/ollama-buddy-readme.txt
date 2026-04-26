
Ollama Buddy is an Emacs package that provides a friendly AI assistant
for various tasks such as code refactoring, generating commit messages,
dictionary lookups, and more.  It interacts with local LLMs via Ollama
and supports remote providers including OpenAI, Claude, Gemini, Grok,
GitHub Copilot, Codestral, DeepSeek, and OpenRouter.

; Quick Start

(use-package ollama-buddy
  :ensure t
  :bind
  ("C-c o" . ollama-buddy-role-transient-menu)
  ("C-c O" . ollama-buddy-transient-menu))

; Usage

C-c o  Role-based transient menu (main entry point)
C-c O  Main transient menu (all settings and actions)

From the chat buffer:

  C-c C-c / C-c RET  Send prompt
  C-c C-k            Cancel request
  C-c m              Change model

; Remote Providers (optional)

Register any OpenAI/Claude/Gemini-compatible provider with a single call:

  (require 'ollama-buddy-provider)
  (ollama-buddy-provider-create
   :name "OpenAI" :prefix "a:"
   :api-key (lambda () (auth-source-pick-first-password
                        :host "ollama-buddy-openai" :user "apikey"))
   :endpoint "https://api.openai.com/v1/chat/completions"
   :models-endpoint "https://api.openai.com/v1/models"
   :models-filter (lambda (id) (string-match-p "gpt" id)))

Supported :api-type values: openai (default), claude, gemini.
See CHANGELOG.org for migration examples from the legacy require system.

Legacy per-provider require files still work but are deprecated:
  (require 'ollama-buddy-openai)        ; a: OpenAI
  (require 'ollama-buddy-claude)        ; c: Anthropic Claude
  (require 'ollama-buddy-gemini)        ; g: Google Gemini
  (require 'ollama-buddy-grok)          ; k: xAI Grok
  (require 'ollama-buddy-copilot)       ; p: GitHub Copilot
  (require 'ollama-buddy-codestral)     ; s: Mistral Codestral
  (require 'ollama-buddy-deepseek)      ; d: DeepSeek
  (require 'ollama-buddy-openrouter)    ; r: OpenRouter (400+ models)
  (require 'ollama-buddy-opencode)      ; n: OpenCode Go subscription
  (require 'ollama-buddy-openai-compat) ; l: any OpenAI-compatible server

Each provider needs an API key (see PROVIDERS.org for setup details).

; Presets and User Prompts

On first launch, install the bundled presets and user prompts:

  C-c O → I   (or M-x ollama-buddy-install-extras)

This copies role presets and system prompt templates into your Emacs
configuration directory.  The chat welcome screen will remind you if
they are not yet installed.
