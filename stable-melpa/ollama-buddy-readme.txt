
Ollama Buddy is an Emacs package that provides a friendly AI assistant
for various tasks such as code refactoring, generating commit messages,
dictionary lookups, and more.  It interacts with the Ollama server to
perform these tasks.

; Quick Start

(use-package ollama-buddy
   :ensure t
   :bind
   ("C-c o" . ollama-buddy-menu)
   ("C-c O" . ollama-buddy-transient-menu-wrapper))

OR (to select the default model)

(use-package ollama-buddy
   :ensure t
   :bind
   ("C-c o" . ollama-buddy-menu)
   ("C-c O" . ollama-buddy-transient-menu-wrapper)
   :custom
   ollama-buddy-default-model "tinyllama:latest")

OR (use-package local)

(use-package ollama-buddy
   :load-path "path/to/ollama-buddy"
   :bind
   ("C-c o" . ollama-buddy-menu)
   ("C-c O" . ollama-buddy-transient-menu-wrapper)
   :custom ollama-buddy-default-model "tinyllama:latest")

OR (the old way)

(add-to-list 'load-path "path/to/ollama-buddy")
(require 'ollama-buddy)
(global-set-key (kbd "C-c o") #'ollama-buddy-menu)
(global-set-key (kbd "C-c O") #'ollama-buddy-transient-menu-wrapper)
(setq ollama-buddy-default-model "tinyllama:latest")

; Usage

M-x ollama-buddy-menu / C-c o

OR

M-x ollama-buddy-transient-menu-wrapper / C-c O

and the chat assistant buffer is presented and off you go!
