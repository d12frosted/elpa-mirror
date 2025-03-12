
Ollama Buddy is an Emacs package that provides a friendly AI assistant
for various tasks such as code refactoring, generating commit messages,
dictionary lookups, and more.  It interacts with the Ollama server to
perform these tasks.

; Quick Start

(use-package ollama-buddy
   :ensure t
   :bind ("C-c o" . ollama-buddy-menu))

OR (to select the default model)

(use-package ollama-buddy
   :ensure t
   :bind ("C-c o" . ollama-buddy-menu)
   :custom ollama-buddy-default-model "llama:latest")

OR (use-package local)

(use-package ollama-buddy
   :load-path "path/to/ollama-buddy"
   :bind ("C-c o" . ollama-buddy-menu)
   :custom ollama-buddy-default-model "llama:latest")

OR (the old way)

(add-to-list 'load-path "path/to/ollama-buddy")
(require 'ollama-buddy)
(global-set-key (kbd "C-c o") #'ollama-buddy-menu)
(setq ollama-buddy-default-model "llama:latest")

; Usage

M-x ollama-buddy-menu / C-c o

and the chat assistant buffer is presented and off you go!
