
    ____ ____ _____  _    ___       _
   / ___|  _ \_   _|/ \  |_ _|  ___| |
  | |  _| |_) || | / _ \  | |  / _ \ |
  | |_| |  __/ | |/ ___ \ | | |  __/ |
   \____|_|    |_/_/   \_\___(_)___|_|

This is intended to allow for development and programming queries into the
OpenAI API.  This allows for sending queries straight from Emacs directly into
various models of OpenAI's platform.  It is a barebones implementation of a
    wrapper around the API focused on achieving extensibility.

Configurations that are required are listed as follows:

- Define the desired model to use (available models can be found by running
  gptai-list-models which will populate the gptai-models variable with the
  list of all available models, it will also display this list in the gptai
  buffer).

- Define your OpenAI API key.

- Optionally define keybindings for sending various queries easily.

An example of these configurations after installing from MELPA is shown
below:

  (require 'gptai)
  ;; set standard configurations
  (setq gptai-model "<MODEL-HERE>")
  (setq gptai-api-key "<API-KEY-HERE>")
  ;; set keybindings optionally
  (global-set-key (kbd "C-c o") 'gptai-send-query)
