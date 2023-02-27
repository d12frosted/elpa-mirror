This is intended to allow for development and programming queries into the
OpenAI API.  This allows for sending queries straight from Emacs directly into
various models of OpenAI's platform.

Configurations that are required are listed as follows:

- Define the desired model to use (available models can be found by running
  gptai-list-models which will populate the gptai-models variable with the
  list of all available models, it will also display this list in the gptai
  buffer).

- Define your OpenAI API key.

- Optionally define keybindings for sending various queries easily.

An example of these configurations:

(setq gptai-model "<MODEL-HERE>") ;; this is only relevant for text models
(setq gptai-username "<USERNAME-HERE>")
(setq gptai-api-key "<API-KEY-HERE>")
(global-set-key (kbd "C-c o") 'gptai-send-query) ;; or some other query fn
