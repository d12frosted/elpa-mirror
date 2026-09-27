Provides translation and grammar analysis for Sanskrit/Pāli/Tibetan/Chinese
texts using the public dharmamitra.org API.  No API key is required.

Two endpoints are used:
  - Grammar:     POST /api-tagging/tagging-parsed/
  - Translation: POST /api-search/cat-translate/v1/translate

Both requests are sent asynchronously through curl and rendered into the
`*Dharmamitra*' buffer as they arrive.  The buffer uses
`dharmamitra-text-mode', which offers keys to re-run the analysis, toggle
translation, expand full dictionary entries, move between words, switch
languages and copy results.  See `dharmamitra-text-mode' for the bindings.

The package does not bind any global keys.  A typical setup is:

  (require 'dharmamitra)
  (global-set-key (kbd "C-c g") #'dharmamitra-text-analyze-grammar)
  (global-set-key (kbd "C-c t") #'dharmamitra-text-translate)
