
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
  ("C-c O" . ollama-buddy-transient-menu-wrapper))

; Usage

C-c o  Role-based transient menu (main entry point)
C-c O  Advanced transient menu (all settings and actions)

From the chat buffer:

  C-c C-c / C-c RET  Send prompt
  C-c C-k            Cancel request
  C-c m              Change model

; Remote Providers (optional)

Load any provider module to access its models alongside Ollama:

  (require 'ollama-buddy-openai)      ; a: OpenAI
  (require 'ollama-buddy-claude)      ; c: Anthropic Claude
  (require 'ollama-buddy-gemini)      ; g: Google Gemini
  (require 'ollama-buddy-grok)        ; k: xAI Grok
  (require 'ollama-buddy-copilot)     ; p: GitHub Copilot
  (require 'ollama-buddy-codestral)   ; s: Mistral Codestral
  (require 'ollama-buddy-deepseek)    ; d: DeepSeek
  (require 'ollama-buddy-openrouter)  ; r: OpenRouter (400+ models)
  (require 'ollama-buddy-openai-compat) ; l: any OpenAI-compatible server (LM Studio, llama.cpp, vLLM…)

Each provider needs an API key (see PROVIDERS.org for setup details).
