
Ollama Buddy is an Emacs package that provides a friendly AI assistant
for various tasks such as code refactoring, generating commit messages,
dictionary lookups, and more.  It interacts with the Ollama server to
perform these tasks.

; Quick Start

(use-package ollama-buddy
   :load-path "path/to/ollama-buddy"
   :bind ("C-c o" . ollama-buddy-menu)
   :custom ollama-buddy-default-model "llama:latest")

OR

(add-to-list 'load-path "path/to/ollama-buddy")
(require 'ollama-buddy)
(global-set-key (kbd "C-c o") #'ollama-buddy-menu)
(setq ollama-buddy-default-model "llama:latest")

OR (when added to MELPA)

(use-package ollama-buddy
   :ensure t
   :bind ("C-c o" . ollama-buddy-menu)
   :custom ollama-buddy-default-model "llama:latest")

; Usage

M-x ollama-buddy-menu

OR

C-c o
